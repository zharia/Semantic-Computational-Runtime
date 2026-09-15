# Phase 10 — basic.qos (60,10) prefetch-count enforcement test.
#
# Drives AMQPService directly (no sockets) with REAL §2.3.5 framing:
#   publish N messages -> basic.qos prefetch-count=1 -> basic.consume.
#
# Proves:
#   (a) basic.qos is answered with a well-formed basic.qos-ok (60,11) carrying
#       no arguments;
#   (b) with prefetch-count=1 exactly ONE delivery is outstanding in the
#       consume reply, and drain_pushes stays empty until that delivery is ack'd;
#   (c) after the ack the next delivery arrives (the window slides);
#   (d) with no qos the engine default (_max_unacked) governs (regression:
#       a plain consume still flushes every pending message).

from std.collections import List

from hyrxmq.config import HyrxMQConfig
from hyrxmq.amqp_service import (
    AMQPService,
    ByteReader,
    write_short_string,
    write_u16,
    write_u32,
    write_u64,
)
from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec
from hyrx.amqp.constants import (
    BASIC_CONSUME_OK,
    BASIC_DELIVER,
    BASIC_QOS_OK,
    MethodID,
)

from hyrx.testing import check


def bytes_of(s: String) -> List[UInt8]:
    var out = List[UInt8]()
    var b = s.as_bytes()
    for i in range(len(b)):
        out.append(b[i])
    return out^


def method_frame(
    chan: UInt16, class_id: UInt16, method_id: UInt16, var args: List[UInt8]
) -> AMQPFrame:
    var payload = List[UInt8]()
    payload.append(UInt8((class_id >> 8) & 0xFF))
    payload.append(UInt8(class_id & 0xFF))
    payload.append(UInt8((method_id >> 8) & 0xFF))
    payload.append(UInt8(method_id & 0xFF))
    for i in range(len(args)):
        payload.append(args[i])
    return AMQPFrame(1, chan, payload^)


def mid_of(var payload: List[UInt8]) -> MethodID:
    return MethodID(
        (UInt16(payload[0]) << 8) | UInt16(payload[1]),
        (UInt16(payload[2]) << 8) | UInt16(payload[3]),
    )


def decode_reply(var wire: List[UInt8]) raises -> List[AMQPFrame]:
    var out = List[AMQPFrame]()
    var codec = AMQPFrameCodec()
    codec.feed_bytes(wire^)
    var f = codec.try_parse_frame()
    while f.__bool__():
        var ft = f.value().frame_type
        var ch = f.value().channel
        var pl = f.value().payload_copy()
        out.append(AMQPFrame(ft, ch, pl^))
        f = codec.try_parse_frame()
    return out^


def count_delivers(frames: List[AMQPFrame]) -> Int:
    var n = 0
    for i in range(len(frames)):
        if frames[i].frame_type != 1:
            continue
        var p = frames[i].payload_copy()
        if len(p) >= 4 and mid_of(p.copy()) == BASIC_DELIVER():
            n += 1
    return n


def first_deliver_tag(frames: List[AMQPFrame]) raises -> UInt64:
    for i in range(len(frames)):
        if frames[i].frame_type != 1:
            continue
        var p = frames[i].payload_copy()
        if len(p) >= 4 and mid_of(p.copy()) == BASIC_DELIVER():
            var r = ByteReader(p^)
            _ = r.read_short()
            _ = r.read_short()
            _ = r.read_short_string()  # consumer-tag
            return r.read_long_long()
    raise "no deliver frame found"


def introspect_run(
    var svc: AMQPService, conn: UInt64, var queue: String
) raises -> AMQPService:
    """exchange.declare + queue.declare + queue.bind on channel 1."""
    var eargs = List[UInt8]()
    eargs.append(0)
    eargs.append(0)
    write_short_string(eargs, "qex")
    write_short_string(eargs, "direct")
    eargs.append(0)
    eargs.append(0)
    eargs.append(0)
    eargs.append(0)
    eargs.append(0)
    _ = svc.handle_frame(conn, method_frame(UInt16(1), 40, 10, eargs^))

    var qargs = List[UInt8]()
    qargs.append(0)
    qargs.append(0)
    write_short_string(qargs, queue.copy())
    qargs.append(0)
    qargs.append(0)
    qargs.append(0)
    qargs.append(0)
    qargs.append(0)
    _ = svc.handle_frame(conn, method_frame(UInt16(1), 50, 10, qargs^))

    var bargs = List[UInt8]()
    bargs.append(0)
    bargs.append(0)
    write_short_string(bargs, queue.copy())
    write_short_string(bargs, "qex")
    write_short_string(bargs, "qk")
    _ = svc.handle_frame(conn, method_frame(UInt16(1), 50, 20, bargs^))
    return svc^


def publish_message(
    var svc: AMQPService, conn: UInt64, var body: String
) raises -> AMQPService:
    var pargs = List[UInt8]()
    pargs.append(0)
    pargs.append(0)
    write_short_string(pargs, "qex")
    write_short_string(pargs, "qk")
    pargs.append(0)
    _ = svc.handle_frame(conn, method_frame(UInt16(1), 60, 40, pargs^))

    var b = bytes_of(body)
    var hdr = AMQPFrameCodec.encode_header_frame(
        UInt16(1), UInt16(60), UInt64(len(b)), UInt16(0), List[UInt8]()
    )
    var hcodec = AMQPFrameCodec()
    hcodec.feed_bytes(hdr^)
    var hf = hcodec.try_parse_frame()
    _ = svc.handle_frame(
        conn,
        AMQPFrame(hf.value().frame_type, hf.value().channel, hf.value().payload_copy()),
    )

    var bw = AMQPFrameCodec.encode_body_frame(UInt16(1), b^)
    var bcodec = AMQPFrameCodec()
    bcodec.feed_bytes(bw^)
    var bf = bcodec.try_parse_frame()
    _ = svc.handle_frame(
        conn,
        AMQPFrame(bf.value().frame_type, bf.value().channel, bf.value().payload_copy()),
    )
    return svc^


def qos_args(size: UInt32, count: UInt16, global_bit: UInt8) -> List[UInt8]:
    var a = List[UInt8]()
    write_u32(a, size)
    write_u16(a, count)
    a.append(global_bit)
    return a^


def consume_args(var queue: String, var ctag: String, no_ack: UInt8) -> List[UInt8]:
    var a = List[UInt8]()
    a.append(0)
    a.append(0)
    write_short_string(a, queue^)
    write_short_string(a, ctag^)
    a.append(no_ack)
    a.append(0)
    a.append(0)
    a.append(0)
    a.append(0)
    return a^


def ack_args(tag: UInt64) -> List[UInt8]:
    var a = List[UInt8]()
    write_u64(a, tag)
    a.append(0)
    return a^


def new_service() raises -> AMQPService:
    var cfg = HyrxMQConfig()
    cfg.validate()
    var svc = AMQPService(cfg^)
    svc.start()
    return svc^


# ---- basic.qos-ok shape ----

def test_qos_ok_shape() raises:
    var svc = new_service()
    var qf = method_frame(UInt16(1), 60, 10, qos_args(UInt32(0), UInt16(1), UInt8(0)))
    var resp = svc.handle_frame(UInt64(1), qf)
    check(resp.__bool__(), "basic.qos produces a reply")
    var frames = decode_reply(resp.value().copy())
    check((len(frames) == 1), "qos-ok is exactly one frame")
    check(frames[0].frame_type == 1, "qos-ok is a METHOD frame")
    var p = frames[0].payload_copy()
    check(mid_of(p.copy()) == BASIC_QOS_OK(), "reply method is basic.qos-ok (60,11)")
    check((len(p) == 4), "qos-ok carries no arguments (class+method only)")


# ---- prefetch-count = 1 window slides on ack ----

def test_prefetch_one_window() raises:
    var svc = new_service()
    var conn = UInt64(7)
    svc = introspect_run(svc^, conn, "qq")
    svc = publish_message(svc^, conn, "m1")
    svc = publish_message(svc^, conn, "m2")
    svc = publish_message(svc^, conn, "m3")
    check((svc.status().messages_published == 3), "three messages queued")

    # prefetch-count = 1, global = 0 (channel-scoped).
    var qf = method_frame(UInt16(1), 60, 10, qos_args(UInt32(0), UInt16(1), UInt8(0)))
    var qresp = svc.handle_frame(conn, qf)
    check(qresp.__bool__(), "basic.qos answered")
    check(
        mid_of(decode_reply(qresp.value().copy())[0].payload_copy()) == BASIC_QOS_OK(),
        "qos-ok before the consume",
    )

    # consume (manual ack): at most ONE delivery outstanding.
    var cf = method_frame(UInt16(1), 60, 20, consume_args("qq", "ct-1", UInt8(0)))
    var cresp = svc.handle_frame(conn, cf)
    check(cresp.__bool__(), "consume answered")
    var cframes = decode_reply(cresp.value().copy())
    check(cframes[0].frame_type == 1, "first consume frame is consume-ok")
    check(
        mid_of(cframes[0].payload_copy()) == BASIC_CONSUME_OK(),
        "consume-ok (60,21)",
    )
    check((count_delivers(cframes) == 1), "prefetch=1: exactly one delivery outstanding")

    var tag1 = first_deliver_tag(cframes)

    # The window is full: no async push may drain a second delivery.
    var push1 = svc.drain_pushes(conn)
    check((count_delivers(decode_reply(push1.copy())) == 0), "prefetch=1: push blocked until ack")

    # Ack frees the slot -> the next delivery arrives.
    _ = svc.handle_frame(conn, method_frame(UInt16(1), 60, 80, ack_args(tag1)))
    check((svc.status().messages_acked == 1), "first delivery acked")
    var push2 = svc.drain_pushes(conn)
    var pf2 = decode_reply(push2.copy())
    check((count_delivers(pf2) == 1), "after ack the next delivery arrives")

    # Ack it too -> the third (and last) arrives, then the queue is dry.
    var tag2 = first_deliver_tag(pf2)
    _ = svc.handle_frame(conn, method_frame(UInt16(1), 60, 80, ack_args(tag2)))
    var push3 = svc.drain_pushes(conn)
    check((count_delivers(decode_reply(push3.copy())) == 1), "third delivery arrives")


# ---- no qos: engine default still flushes all messages ----

def test_default_without_qos_flushes_all() raises:
    var svc = new_service()
    var conn = UInt64(8)
    svc = introspect_run(svc^, conn, "nq")
    svc = publish_message(svc^, conn, "a")
    svc = publish_message(svc^, conn, "b")
    svc = publish_message(svc^, conn, "c")

    var cf = method_frame(UInt16(1), 60, 20, consume_args("nq", "ct-2", UInt8(0)))
    var cresp = svc.handle_frame(conn, cf)
    var cframes = decode_reply(cresp.value().copy())
    check((count_delivers(cframes) == 3), "no qos: default flushes all three pending")


def main() raises:
    test_qos_ok_shape()
    test_prefetch_one_window()
    test_default_without_qos_flushes_all()
    print("QOS_PREFETCH_TEST=PASS")
