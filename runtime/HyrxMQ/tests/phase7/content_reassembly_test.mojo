# Phase 7 — AMQP 0-9-1 CONTENT-FRAME reassembly tests (no sockets).

# Drives AMQPService with REAL §2.3.5 framing: a basic.publish is a METHOD
# frame followed by exactly one content HEADER frame (class 60, declared
# body-size) and N BODY frames; outbound deliveries are METHOD+HEADER+BODY.
# Feed frames in, decode frames out — the whole content path is proven without
# a socket (the socket leg is tests/integration/broker_tcp_e2e.mojo).

# Proves:
#   (a) a 5-byte body split across TWO body frames (2+3) reassembles, routes
#       and comes back through basic.consume as deliver+header+body;
#   (b) body-size 0 routes immediately with NO body frames;
#   (c) basic.get on an empty queue answers get-empty, and after a publish
#       answers get-ok+header+body whose bytes match; basic.ack then settles it;
#   (d) fail-closed: a body frame with no pending publish grows nothing and the
#       service keeps working; a body OVERFLOWING its declared size is dropped,
#       never published; a second header for one publish is refused;
#   (e) a body larger than one frame-max chunk splits into several BODY frames
#       inbound AND outbound and reassembles byte-exactly.

from std.collections import List

from hyrxmq.config import HyrxMQConfig
from hyrxmq.amqp_service import (
    AMQPService,
    ByteReader,
    write_short_string,
    write_u64,
)
from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec, parse_header_frame_payload
from hyrx.amqp.constants import (
    BASIC_CONSUME_OK,
    BASIC_DELIVER,
    BASIC_GET_EMPTY,
    BASIC_GET_OK,
    MethodID,
)

from hyrx.testing import check


def bytes_of(s: String) -> List[UInt8]:
    var out = List[UInt8]()
    var b = s.as_bytes()
    for i in range(len(b)):
        out.append(b[i])
    return out^


def check_bytes(got: List[UInt8], want: List[UInt8], msg: String) raises:
    if len(got) != len(want):
        raise (
            "FAIL: " + msg
            + " (len " + String(len(got)) + " != " + String(len(want)) + ")"
        )
    for i in range(len(want)):
        if got[i] != want[i]:
            raise "FAIL: " + msg + " (byte " + String(i) + ")"


def method_frame(
    chan: UInt16, class_id: UInt16, method_id: UInt16, var args: List[UInt8]
) -> AMQPFrame:
    """A METHOD frame built directly from its arguments (ids + args payload)."""
    var payload = List[UInt8]()
    payload.append(UInt8((class_id >> 8) & 0xFF))
    payload.append(UInt8(class_id & 0xFF))
    payload.append(UInt8((method_id >> 8) & 0xFF))
    payload.append(UInt8(method_id & 0xFF))
    for i in range(len(args)):
        payload.append(args[i])
    return AMQPFrame(1, chan, payload^)


def header_payload(body_size: UInt64) -> List[UInt8]:
    """§2.3.5.2: class(2) weight(2) body-size(8) property-flags(2), no props."""
    var p = List[UInt8]()
    p.append(0)
    p.append(60)  # class-id = basic
    p.append(0)
    p.append(0)  # weight = 0
    var shift = UInt64(56)
    while True:
        p.append(UInt8((body_size >> shift) & 0xFF))
        if shift == 0:
            break
        shift -= UInt64(8)
    p.append(0)
    p.append(0)  # property-flags = 0 (all properties absent)
    return p^


def publish_method_args(var ex: String, var rk: String) -> List[UInt8]:
    var a = List[UInt8]()
    a.append(0)
    a.append(0)  # reserved-1
    write_short_string(a, ex^)
    write_short_string(a, rk^)
    a.append(0)  # bits: mandatory / immediate
    return a^


def consume_frame_args(var queue: String, var ctag: String) -> List[UInt8]:
    var a = List[UInt8]()
    a.append(0)
    a.append(0)  # reserved-1
    write_short_string(a, queue^)
    write_short_string(a, ctag^)
    a.append(0)  # bits: no-local/no-ack/exclusive/no-wait
    a.append(0)
    a.append(0)
    a.append(0)
    a.append(0)  # arguments: empty field table
    return a^


def get_args(var queue: String, no_ack: UInt8) -> List[UInt8]:
    var a = List[UInt8]()
    a.append(0)
    a.append(0)  # reserved-1
    write_short_string(a, queue^)
    a.append(no_ack)  # bits: no-ack
    return a^


def ack_args(tag: UInt64) -> List[UInt8]:
    var a = List[UInt8]()
    write_u64(a, tag)
    a.append(0)  # multiple = false
    return a^


def mid_of(var payload: List[UInt8]) -> MethodID:
    return MethodID(
        (UInt16(payload[0]) << 8) | UInt16(payload[1]),
        (UInt16(payload[2]) << 8) | UInt16(payload[3]),
    )


def decode_reply(var wire: List[UInt8]) raises -> List[AMQPFrame]:
    """Decode every concatenated frame of a service reply."""
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


def body_of(frames: List[AMQPFrame], start: Int, want: Int) raises -> List[UInt8]:
    """Concatenate BODY frames from index `start` (up to want bytes)."""
    var got = List[UInt8]()
    var i = start
    while i < len(frames) and len(got) < want:
        if frames[i].frame_type != 3:
            raise "FAIL: expected a BODY frame"
        var p = frames[i].payload_copy()
        for j in range(len(p)):
            got.append(p[j])
        i += 1
    return got^


# ---------- harness steps over the frame API ----------

def declare_topo(
    var svc: AMQPService,
    conn: UInt64,
    var ex: String,
    var q: String,
    var rk: String,
) raises -> AMQPService:
    """exchange.declare + queue.declare + queue.bind."""
    var eargs = List[UInt8]()
    eargs.append(0)
    eargs.append(0)
    write_short_string(eargs, ex.copy())
    write_short_string(eargs, "direct")
    eargs.append(0)  # bits: passive/durable/auto-delete/no-wait = 0
    eargs.append(0)  # arguments: empty field table (u32 length 0)
    eargs.append(0)
    eargs.append(0)
    eargs.append(0)
    var f1 = method_frame(UInt16(1), 40, 10, eargs^)
    _ = svc.handle_frame(conn, f1)

    var qargs = List[UInt8]()
    qargs.append(0)
    qargs.append(0)
    write_short_string(qargs, q.copy())
    qargs.append(0)  # bits
    qargs.append(0)  # arguments: empty field table (u32 length 0)
    qargs.append(0)
    qargs.append(0)
    qargs.append(0)
    var f2 = method_frame(UInt16(1), 50, 10, qargs^)
    _ = svc.handle_frame(conn, f2)

    var bargs = List[UInt8]()
    bargs.append(0)
    bargs.append(0)
    write_short_string(bargs, q.copy())
    write_short_string(bargs, ex.copy())
    write_short_string(bargs, rk^)
    var f3 = method_frame(UInt16(1), 50, 20, bargs^)
    _ = svc.handle_frame(conn, f3)
    return svc^


def send_publish_method(
    var svc: AMQPService, conn: UInt64, var ex: String, var rk: String
) raises -> AMQPService:
    var f = method_frame(UInt16(1), 60, 40, publish_method_args(ex^, rk^))
    _ = svc.handle_frame(conn, f)
    return svc^


def send_header(var svc: AMQPService, conn: UInt64, size: UInt64) raises -> AMQPService:
    var hdr = AMQPFrameCodec.encode_header_frame(
        UInt16(1), UInt16(60), size, UInt16(0), List[UInt8]()
    )
    var codec = AMQPFrameCodec()
    codec.feed_bytes(hdr^)
    var fr = codec.try_parse_frame()
    if not fr.__bool__():
        raise "send_header: header frame did not decode"
    var t = fr.value().frame_type
    var c = fr.value().channel
    var p = fr.value().payload_copy()
    var f = AMQPFrame(t, c, p^)
    _ = svc.handle_frame(conn, f)
    return svc^


def send_body(var svc: AMQPService, conn: UInt64, var body: List[UInt8]) raises -> AMQPService:
    var bw = AMQPFrameCodec.encode_body_frame(UInt16(1), body^)
    var codec = AMQPFrameCodec()
    codec.feed_bytes(bw^)
    var fr = codec.try_parse_frame()
    if not fr.__bool__():
        raise "send_body: body frame did not decode"
    var t = fr.value().frame_type
    var c = fr.value().channel
    var p = fr.value().payload_copy()
    var f = AMQPFrame(t, c, p^)
    _ = svc.handle_frame(conn, f)
    return svc^


def feed_publish(
    var svc: AMQPService,
    conn: UInt64,
    var ex: String,
    var rk: String,
    var chunks: List[List[UInt8]],
    declared: Int,
) raises -> AMQPService:
    """METHOD + HEADER(declared) + one BODY frame per chunk."""
    svc = send_publish_method(svc^, conn, ex^, rk^)
    svc = send_header(svc^, conn, UInt64(declared))
    for i in range(len(chunks)):
        svc = send_body(svc^, conn, chunks[i].copy())
    while len(chunks) > 0:
        _ = chunks.pop()
    return svc^


# ---------- (a) split body -> consume flush ----------

def test_split_body_reassembles_and_delivers() raises:
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()
    svc = declare_topo(svc^, UInt64(1), "ex", "q", "k")

    # METHOD + HEADER(body-size 5) + BODY(2) + BODY(3)
    var c1 = List[UInt8]()
    c1.append(0x48)
    c1.append(0x69)
    var c2 = bytes_of("!AB")
    var chunks = List[List[UInt8]]()
    chunks.append(c1^)
    chunks.append(c2^)
    svc = feed_publish(svc^, UInt64(1), "ex", "k", chunks^, 5)

    # The publish only happened once the declared size was complete.
    check((svc.status().messages_published == 1), "one publish routed")
    check((svc.pending_body_len(UInt64(1)) == 0), "pending state released")
    check((svc.content_errors() == 0), "no content errors")

    # basic.consume flushes it as deliver + header + body.
    var cargs = consume_frame_args("q", "ct-1")
    var cf = method_frame(UInt16(1), 60, 20, cargs^)
    var cresp = svc.handle_frame(UInt64(1), cf)
    check(cresp.__bool__(), "consume-ok + deliver frames returned")
    var frames = decode_reply(cresp.value().copy())
    check((len(frames) == 4), "consume-ok + deliver + header + body")
    check(frames[0].frame_type == 1, "first reply frame is the consume-ok")
    var ok_p = frames[0].payload_copy()
    check(mid_of(ok_p.copy()) == BASIC_CONSUME_OK(), "consume-ok id")
    var okr = ByteReader(ok_p^)
    _ = okr.read_short()
    _ = okr.read_short()
    var okt = okr.read_short_string()
    check((okt == "ct-1"), "consume-ok echoes the client's consumer-tag")
    var d_p = frames[1].payload_copy()
    check(mid_of(d_p.copy()) == BASIC_DELIVER(), "second frame is basic.deliver")
    var dr = ByteReader(d_p^)
    _ = dr.read_short()
    _ = dr.read_short()
    var ctag = dr.read_short_string()
    check((ctag == "ct-1"), "deliver carries the echoed consumer-tag")
    var dtag = dr.read_long_long()
    _ = dr.read_octet()  # redelivered
    _ = dr.read_short_string()  # exchange
    _ = dr.read_short_string()  # routing key
    check(dr.remaining() == 0, "deliver method args end exactly at the fields")

    # §2.3.5 trailer: one HEADER frame with class 60 and body-size 5, then BODY.
    check(frames[2].frame_type == 2, "third frame is the content header")
    var hdr_payload = frames[2].payload_copy()
    var hdr = parse_header_frame_payload(hdr_payload^)
    check(hdr.class_id == 60, "header class-id is basic")
    check(hdr.body_size == 5, "header declares the 5-byte body")
    check(frames[3].frame_type == 3, "fourth frame is the content body")
    var got = body_of(frames, 3, 5)
    check_bytes(got, bytes_of("Hi!AB"), "two body frames reassembled exactly")

    # And the delivery can be acked with the tag the deliver frame carried.
    check((Int(dtag) == 1), "first wire delivery tag is 1 (1-based per channel)")
    var af = method_frame(UInt16(1), 60, 80, ack_args(dtag))
    _ = svc.handle_frame(UInt64(1), af)
    check((svc.status().messages_acked == 1), "consume-path delivery acked")


# ---------- (b) zero-size body ----------

def test_zero_body_publish_has_no_body_frames() raises:
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()
    svc = declare_topo(svc^, UInt64(2), "z", "zq", "zk")
    svc = send_publish_method(svc^, UInt64(2), "z", "zk")
    svc = send_header(svc^, UInt64(2), UInt64(0))
    check((svc.status().messages_published == 1), "empty publish routed at header time")

    # basic.get sees it: get-ok + header(body-size 0) + NO body frames.
    var gf = method_frame(UInt16(1), 60, 70, get_args("zq", 1))
    var gresp = svc.handle_frame(UInt64(2), gf)
    var gframes = decode_reply(gresp.value().copy())
    check((len(gframes) == 2), "get-ok + header: zero-size body has NO body frames")
    var hpay = gframes[1].payload_copy()
    var h = parse_header_frame_payload(hpay^)
    check(h.body_size == 0, "empty body declared")
    check(mid_of(gframes[0].payload_copy()) == BASIC_GET_OK(), "reply is get-ok")

    # A stray BODY frame after the completed zero-size publish is fail-closed.
    var before = svc.status().messages_published
    var stray = bytes_of("x")
    svc = send_body(svc^, UInt64(2), stray^)
    check((svc.status().messages_published == before), "stray body published nothing")
    check((svc.content_errors() == 1), "stray body counted as a content error")


# ---------- (c) basic.get: empty, hit, ack, empty ----------

def test_basic_get_empty_then_hit_then_ack() raises:
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()
    svc = declare_topo(svc^, UInt64(3), "gx", "gq", "gk")

    # Empty queue -> get-empty (60,72) with an empty reserved-1 short-string.
    var ef = method_frame(UInt16(1), 60, 70, get_args("gq", 0))
    var ereq = svc.handle_frame(UInt64(3), ef)
    check(ereq.__bool__(), "basic.get answered synchronously")
    var eframes = decode_reply(ereq.value().copy())
    check((len(eframes) == 1), "get-empty is exactly one frame (no content)")
    var ep = eframes[0].payload_copy()
    check(mid_of(ep.copy()) == BASIC_GET_EMPTY(), "reply is basic.get-empty (60,72)")
    check(Int(ep[4]) == 0, "get-empty reserved-1 is an empty short-string")

    # Publish 7 bytes as three body frames, then get them back.
    var chunks = List[List[UInt8]]()
    chunks.append(bytes_of("AB")^)
    chunks.append(bytes_of("CD")^)
    chunks.append(bytes_of("EFG")^)
    svc = feed_publish(svc^, UInt64(3), "gx", "gk", chunks^, 7)

    var hf = method_frame(UInt16(1), 60, 70, get_args("gq", 0))
    var hreq = svc.handle_frame(UInt64(3), hf)
    check(hreq.__bool__(), "basic.get with a message answered")
    var hframes = decode_reply(hreq.value().copy())
    check((len(hframes) == 3), "get-ok + header + body")
    var gp = hframes[0].payload_copy()
    check(mid_of(gp.copy()) == BASIC_GET_OK(), "reply is basic.get-ok (60,71)")
    var gr = ByteReader(gp^)
    _ = gr.read_short()
    _ = gr.read_short()
    var gtag = gr.read_long_long()
    _ = gr.read_octet()  # redelivered
    _ = gr.read_short_string()  # exchange
    _ = gr.read_short_string()  # routing key
    _ = gr.read_long()  # message-count
    check(gr.remaining() == 0, "get-ok args are exactly the spec fields")
    var hpay = hframes[1].payload_copy()
    var h = parse_header_frame_payload(hpay^)
    check(h.body_size == 7, "header declares the 7-byte body")
    var got = body_of(hframes, 2, 7)
    check_bytes(got, bytes_of("ABCDEFG"), "get body bytes match")

    # Unacked now; basic.ack with the get's tag settles it.
    var af = method_frame(UInt16(1), 60, 80, ack_args(gtag))
    _ = svc.handle_frame(UInt64(3), af)
    check((svc.status().messages_acked == 1), "get delivery acked by tag")

    # Queue is empty again -> get-empty.
    var qf = method_frame(UInt16(1), 60, 70, get_args("gq", 0))
    var qreq = svc.handle_frame(UInt64(3), qf)
    var qp = decode_reply(qreq.value().copy())[0].payload_copy()
    check(mid_of(qp.copy()) == BASIC_GET_EMPTY(), "drained queue answers get-empty again")


# ---------- (d) fail-closed negatives ----------

def test_content_frames_without_publish_are_dropped() raises:
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()
    svc = declare_topo(svc^, UInt64(4), "nx", "nq", "nk")

    # A HEADER and two BODY frames arrive with NO pending publish.
    var big = List[UInt8]()
    for _ in range(4096):
        big.append(0x41)
    svc = send_header(svc^, UInt64(4), UInt64(100))
    svc = send_body(svc^, UInt64(4), big.copy())
    svc = send_body(svc^, UInt64(4), big.copy())
    check((svc.pending_body_len(UInt64(4)) == 0), "no accumulation without a publish")
    check((svc.status().messages_published == 0), "nothing was routed")
    check((svc.content_errors() == 3), "each stray frame recorded one content error")

    # The service still serves the next GOOD frame sequence.
    var chunks = List[List[UInt8]]()
    chunks.append(bytes_of("ok")^)
    svc = feed_publish(svc^, UInt64(4), "nx", "nk", chunks^, 2)
    check((svc.status().messages_published == 1), "next good publish reassembled")


def test_body_overflow_is_dropped_not_published() raises:
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()
    svc = declare_topo(svc^, UInt64(5), "ox", "oq", "ok")

    # Declare 3 bytes, then push a 10-byte body frame.
    svc = send_publish_method(svc^, UInt64(5), "ox", "ok")
    svc = send_header(svc^, UInt64(5), UInt64(3))
    var ten = List[UInt8]()
    for _ in range(10):
        ten.append(0x42)
    svc = send_body(svc^, UInt64(5), ten^)
    check((svc.status().messages_published == 0), "overflowing body NOT published")
    check((svc.pending_body_len(UInt64(5)) == 0), "overflow state released (no growth)")
    check((svc.content_errors() == 1), "overflow recorded as a content error")

    # A second header for the same publish is also refused.
    svc = send_publish_method(svc^, UInt64(5), "ox", "ok")
    svc = send_header(svc^, UInt64(5), UInt64(4))
    svc = send_header(svc^, UInt64(5), UInt64(4))
    check((svc.status().messages_published == 0), "double header publishes nothing")
    check((svc.content_errors() == 2), "double header recorded")

    # Still serving afterwards.
    var chunks = List[List[UInt8]]()
    chunks.append(bytes_of("Z")^)
    svc = feed_publish(svc^, UInt64(5), "ox", "ok", chunks^, 1)
    check((svc.status().messages_published == 1), "service recovers after errors")


# ---------- (e) one body across many chunk-sized frames ----------

def test_large_body_splits_across_frames() raises:
    # frame_max 4096 -> outbound chunk 4088; a 9000-byte body must arrive as
    # several BODY frames and be delivered as >1 of them, byte-exactly.
    var cfg = HyrxMQConfig()
    cfg.frame_max = 4096
    var svc = AMQPService(cfg^)
    svc.start()
    check((svc.frame_max() == 4096), "config frame ceiling read before move")
    svc = declare_topo(svc^, UInt64(6), "lx", "lq", "lk")

    var full = List[UInt8]()
    for i in range(9000):
        full.append(UInt8(i % 251))

    # Inbound: METHOD + HEADER(9000) + 2000-byte BODY frames (under ceiling).
    svc = send_publish_method(svc^, UInt64(6), "lx", "lk")
    svc = send_header(svc^, UInt64(6), UInt64(9000))
    var pos = 0
    while pos < len(full):
        var n = 2000
        if pos + n > len(full):
            n = len(full) - pos
        var part = List[UInt8]()
        for i in range(pos, pos + n):
            part.append(full[i])
        svc = send_body(svc^, UInt64(6), part^)
        pos += n
    check((svc.status().messages_published == 1), "multi-frame body routed once")
    check((svc.content_errors() == 0), "no content errors on the large body")

    # Outbound: basic.get emits more than one body frame, none oversized.
    var gf = method_frame(UInt16(1), 60, 70, get_args("lq", 0))
    var req = svc.handle_frame(UInt64(6), gf)
    var frames = decode_reply(req.value().copy())
    var body_frames = 0
    var i = 2
    while i < len(frames):
        check(frames[i].frame_type == 3, "trailer frames are BODY")
        check(frames[i].payload_size() <= 4088, "no BODY frame exceeds frame_max - 8")
        body_frames += 1
        i += 1
    check((body_frames == 3), "9000 bytes delivered as 3 body frames")
    var got = body_of(frames, 2, 9000)
    check_bytes(got, full, "large body reassembled byte-exactly outbound")


def main() raises:
    test_split_body_reassembles_and_delivers()
    test_zero_body_publish_has_no_body_frames()
    test_basic_get_empty_then_hit_then_ack()
    test_content_frames_without_publish_are_dropped()
    test_body_overflow_is_dropped_not_published()
    test_large_body_splits_across_frames()
    print("CONTENT_REASSEMBLY_TEST=PASS")
