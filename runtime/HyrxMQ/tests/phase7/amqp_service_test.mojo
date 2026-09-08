# Phase 7 — HyrxMQ AMQP service tests.
#
# Feeds encoded AMQP method frames through the broker's handler and checks the
# encoded responses. No sockets: this is feed-bytes / get-bytes.
#
# Every class-id/method-id written on the wire here or expected back is the
# normative amqp0-9-1.xml index (see src/hyrx/amqp/constants.mojo), asserted
# both through the constants and as literals.

from std.collections import List

from hyrxmq.config import HyrxMQConfig
from hyrxmq.amqp_service import (
    AMQPService,
    QUEUE_DECLARE_BIT_NO_WAIT,
    write_short_string,
    write_u64,
)
from hyrx.amqp.constants import (
    CHANNEL_OPEN,
    CHANNEL_OPEN_OK,
    CONNECTION_OPEN,
    CONNECTION_OPEN_OK,
    MethodID,
    QUEUE_DECLARE,
    QUEUE_DECLARE_OK,
)
from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec


from hyrx.testing import check

def build_frame(
    chan: UInt16, class_id: UInt16, method_id: UInt16, var args: List[UInt8]
) raises -> AMQPFrame:
    """Encode a method frame to wire bytes, then decode back to an AMQPFrame."""
    var wire = AMQPFrameCodec.encode_method_frame(
        chan, class_id, method_id, args^
    )
    var codec = AMQPFrameCodec()
    codec.feed_bytes(wire^)
    var fr = codec.try_parse_frame()
    if not fr.__bool__():
        raise "build_frame: could not decode"
    return AMQPFrame(
        fr.value().frame_type, fr.value().channel, fr.value().payload_copy()
    )


def reserved() -> List[UInt8]:
    var a = List[UInt8]()
    a.append(0)
    a.append(0)
    return a^


def reply_method_id(var resp: List[UInt8]) raises -> MethodID:
    """Return the (class_id, method_id) pair of an encoded method frame.

    The ids live at bytes [7:9] and [9:11]: 7 is the frame header length.
    """
    if len(resp) < 11:
        raise "reply too short to carry class+method ids"
    return MethodID(
        (UInt16(resp[7]) << 8) | UInt16(resp[8]),
        (UInt16(resp[9]) << 8) | UInt16(resp[10]),
    )


def test_queue_declare_produces_ok() raises:
    """Queue.declare (50,10) -> queue.declare-ok (50,11), routed in the engine."""
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()

    # Spec id sanity before using it on the wire.
    check((QUEUE_DECLARE() == MethodID(50, 10)), "queue.declare spec id")
    check((QUEUE_DECLARE_OK() == MethodID(50, 11)), "queue.declare-ok spec id")

    var args = reserved()
    write_short_string(args, "orders")
    args.append(0)  # bits: passive/durable/exclusive/auto-delete/no-wait all 0
    var frame = build_frame(
        UInt16(1), QUEUE_DECLARE().class_id, QUEUE_DECLARE().method_id, args^
    )
    var resp = svc.handle_frame(UInt64(1), frame^)

    check(resp.__bool__(), "queue.declare must produce a response")
    check((len(resp.value()) > 7), "response has frame header")
    check((resp.value()[0] == 1), "response frame_type is METHOD (1)")
    check(
        (reply_method_id(resp.value().copy()) == MethodID(50, 11)),
        "declare-ok is (50,11) per amqp0-9-1.xml",
    )
    check(
        (resp.value()[len(resp.value()) - 1] == 0xCE),
        "response ends with frame-end byte",
    )

    # Single routing authority: the queue exists in the broker's engine, which
    # is the only place a queue can exist (no shadow routing table).
    var st = svc.status()
    check((st.queues == 1), "declared queue is visible in engine status")


def test_queue_declare_no_wait_suppresses_ok() raises:
    """No-wait (bit 4 of the queue.declare bits) suppresses declare-ok."""
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()
    check((QUEUE_DECLARE_BIT_NO_WAIT() == 16), "no-wait is the 5th packed bit")

    var args = reserved()
    write_short_string(args, "quiet")
    args.append(QUEUE_DECLARE_BIT_NO_WAIT())
    var frame = build_frame(
        UInt16(1), QUEUE_DECLARE().class_id, QUEUE_DECLARE().method_id, args^
    )
    var resp = svc.handle_frame(UInt64(2), frame^)
    check(not resp.__bool__(), "no-wait must not produce a declare-ok")

    # The declaration itself still reached the engine.
    check((svc.status().queues == 1), "no-wait queue.declare still routes")

    # And a later declare with no-wait clear does get its reply.
    var args2 = reserved()
    write_short_string(args2, "loud")
    args2.append(0)
    var frame2 = build_frame(
        UInt16(1), QUEUE_DECLARE().class_id, QUEUE_DECLARE().method_id, args2^
    )
    var resp2 = svc.handle_frame(UInt64(2), frame2^)
    check(resp2.__bool__(), "declare without no-wait replies")
    check(
        (reply_method_id(resp2.value().copy()) == MethodID(50, 11)),
        "reply id is declare-ok (50,11)",
    )


def test_connection_and_channel_open() raises:
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()

    # Spec ids first: connection.open (10,40)/open-ok (10,41);
    # channel.open (20,10)/open-ok (20,11).
    check((CONNECTION_OPEN() == MethodID(10, 40)), "connection.open spec id")
    check((CONNECTION_OPEN_OK() == MethodID(10, 41)), "connection.open-ok spec id")
    check((CHANNEL_OPEN() == MethodID(20, 10)), "channel.open spec id")
    check((CHANNEL_OPEN_OK() == MethodID(20, 11)), "channel.open-ok spec id")

    # connection.open on channel 0 -> open-ok
    var oargs = List[UInt8]()
    write_short_string(oargs, "/")
    oargs.append(0)
    oargs.append(0)
    oargs.append(0)
    oargs.append(0)
    var oframe = build_frame(
        UInt16(0), CONNECTION_OPEN().class_id, CONNECTION_OPEN().method_id, oargs^
    )
    var oresp = svc.handle_frame(UInt64(3), oframe^)
    check(oresp.__bool__(), "connection.open -> open-ok")
    check(
        (reply_method_id(oresp.value().copy()) == MethodID(10, 41)),
        "open-ok payload carries (10,41)",
    )
    check(svc.connection_is_open(UInt64(3)), "connection marked open")

    # channel.open on channel 1 -> open-ok
    var cargs = List[UInt8]()
    cargs.append(0)
    cargs.append(0)
    cargs.append(0)
    cargs.append(0)
    var cframe = build_frame(
        UInt16(1), CHANNEL_OPEN().class_id, CHANNEL_OPEN().method_id, cargs^
    )
    var cresp = svc.handle_frame(UInt64(3), cframe^)
    check(cresp.__bool__(), "channel.open -> open-ok")
    check(
        (reply_method_id(cresp.value().copy()) == MethodID(20, 11)),
        "channel.open-ok is (20,11) per amqp0-9-1.xml",
    )

    # A stale (pre-spec) id must NOT be routed as connection.open.
    var stale = List[UInt8]()
    write_short_string(stale, "/")
    var stale_frame = build_frame(UInt16(0), UInt16(10), UInt16(5), stale^)
    var stale_resp = svc.handle_frame(UInt64(9), stale_frame^)
    check(not stale_resp.__bool__(), "(10,5) is not connection.open — no reply")
    check(not svc.connection_is_open(UInt64(9)), "stale id does not open a conn")


def test_publish_reaches_broker() raises:
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()

    # exchange.declare "ex" type direct (40,10)
    var eargs = reserved()
    write_short_string(eargs, "ex")
    write_short_string(eargs, "direct")
    var eframe = build_frame(UInt16(1), UInt16(40), UInt16(10), eargs^)
    _ = svc.handle_frame(UInt64(5), eframe^)

    # queue.declare "q" (50,10)
    var qargs = reserved()
    write_short_string(qargs, "q")
    qargs.append(0)  # bits
    var qframe = build_frame(UInt16(1), UInt16(50), UInt16(10), qargs^)
    _ = svc.handle_frame(UInt64(5), qframe^)

    # queue.bind q/ex/k (50,20)
    var bargs = reserved()
    write_short_string(bargs, "q")
    write_short_string(bargs, "ex")
    write_short_string(bargs, "k")
    var bframe = build_frame(UInt16(1), UInt16(50), UInt16(20), bargs^)
    _ = svc.handle_frame(UInt64(5), bframe^)

    # basic.publish ex/k with inline body (60,40)
    var pargs = reserved()
    write_short_string(pargs, "ex")
    write_short_string(pargs, "k")
    pargs.append(0x48)
    pargs.append(0x69)
    pargs.append(0x21)
    var pframe = build_frame(UInt16(1), UInt16(60), UInt16(40), pargs^)
    var presp = svc.handle_frame(UInt64(5), pframe^)
    check(not presp.__bool__(), "basic.publish returns no sync response")

    # broker received it: deliver + payload bytes match
    var cid = svc.consume_register("q")
    var d = svc.deliver(cid)
    check(d.__bool__(), "message delivered after frame publish")
    var tag = d.value().delivery_tag()
    var payload = svc.read_payload(cid, tag)
    check((len(payload) == 3), "payload length matches")
    check((payload[0] == 0x48), "payload byte 0")
    check((payload[1] == 0x69), "payload byte 1")
    check((payload[2] == 0x21), "payload byte 2")
    check(svc.ack(cid, tag), "ack ok")


def test_basic_ack_uses_the_addressed_delivery_tag() raises:
    """Basic.ack (60,80) args are delivery-tag + multiple bit, not a consumer id.

    The consumer is resolved from the connection's basic.consume registration,
    so the trailing bits octet is never reinterpreted as an identifier.
    """
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()

    var eargs = reserved()
    write_short_string(eargs, "ax")
    write_short_string(eargs, "direct")
    var eframe = build_frame(UInt16(1), UInt16(40), UInt16(10), eargs^)
    _ = svc.handle_frame(UInt64(7), eframe^)

    var qargs = reserved()
    write_short_string(qargs, "aq")
    qargs.append(0)
    var qframe = build_frame(UInt16(1), UInt16(50), UInt16(10), qargs^)
    _ = svc.handle_frame(UInt64(7), qframe^)

    var bargs = reserved()
    write_short_string(bargs, "aq")
    write_short_string(bargs, "ax")
    write_short_string(bargs, "ak")
    var bframe = build_frame(UInt16(1), UInt16(50), UInt16(20), bargs^)
    _ = svc.handle_frame(UInt64(7), bframe^)

    var pargs = reserved()
    write_short_string(pargs, "ax")
    write_short_string(pargs, "ak")
    pargs.append(0x5A)
    var pframe = build_frame(UInt16(1), UInt16(60), UInt16(40), pargs^)
    _ = svc.handle_frame(UInt64(7), pframe^)

    # basic.consume (60,20) registers the connection's consumer and flushes the
    # queued message as a basic.deliver frame.
    var cargs = List[UInt8]()
    write_short_string(cargs, "aq")
    cargs.append(0)  # bits
    var cframe = build_frame(UInt16(1), UInt16(60), UInt16(20), cargs^)
    var cresp = svc.handle_frame(UInt64(7), cframe^)
    check(cresp.__bool__(), "consume-ok returned")
    check(
        (reply_method_id(cresp.value().copy()) == MethodID(60, 21)),
        "consume-ok is (60,21)",
    )
    var tag = _tag_from_consume_reply(cresp.value().copy())
    check((tag == 0), "first delivery tag is 0 (engine tag counter)")

    # basic.ack: delivery-tag(long-long) + bits octet (multiple = low bit).
    var aargs = List[UInt8]()
    write_u64(aargs, UInt64(tag))
    aargs.append(0)  # multiple = false
    var aframe = build_frame(UInt16(1), UInt16(60), UInt16(80), aargs^)
    _ = svc.handle_frame(UInt64(7), aframe^)
    check((svc.status().messages_acked == 1), "addressed delivery tag was acked")
    check(
        (svc.status().messages_delivered == 1),
        "exactly one delivery was in flight",
    )

    # The queue is drained: the frame-path ack removed the message. A direct
    # consumer registration on the same queue sees nothing left.
    var cid = svc.consume_register("aq")
    var d = svc.deliver(cid)
    check(not d.__bool__(), "queue drained by the frame-path ack")


def test_basic_ack_bits_octet_is_not_a_consumer_id() raises:
    """Regression: 0xFF in the ack bits octet must not be read as consumer 255.

    Before the fix the service acked (consumer_id=octet, tag), so a bits octet
    of 0xFF acked nothing and the delivered message stayed unacknowledged.
    """
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()

    var eargs = reserved()
    write_short_string(eargs, "bx")
    write_short_string(eargs, "direct")
    var eframe = build_frame(UInt16(1), UInt16(40), UInt16(10), eargs^)
    _ = svc.handle_frame(UInt64(8), eframe^)
    var qargs = reserved()
    write_short_string(qargs, "bq")
    qargs.append(0)
    var qframe = build_frame(UInt16(1), UInt16(50), UInt16(10), qargs^)
    _ = svc.handle_frame(UInt64(8), qframe^)
    var bargs = reserved()
    write_short_string(bargs, "bq")
    write_short_string(bargs, "bx")
    write_short_string(bargs, "bk")
    var bframe = build_frame(UInt16(1), UInt16(50), UInt16(20), bargs^)
    _ = svc.handle_frame(UInt64(8), bframe^)
    var pargs = reserved()
    write_short_string(pargs, "bx")
    write_short_string(pargs, "bk")
    pargs.append(0x11)
    var pframe = build_frame(UInt16(1), UInt16(60), UInt16(40), pargs^)
    _ = svc.handle_frame(UInt64(8), pframe^)

    var cargs = List[UInt8]()
    write_short_string(cargs, "bq")
    cargs.append(0)
    var cframe = build_frame(UInt16(1), UInt16(60), UInt16(20), cargs^)
    var cresp = svc.handle_frame(UInt64(8), cframe^)
    var tag = _tag_from_consume_reply(cresp.value().copy())
    check((tag == 0), "delivery tag available from the flushed deliver")

    var aargs = List[UInt8]()
    write_u64(aargs, UInt64(tag))
    aargs.append(0xFF)  # bits octet full of ones: multiple set + unused bits
    var aframe = build_frame(UInt16(1), UInt16(60), UInt16(80), aargs^)
    _ = svc.handle_frame(UInt64(8), aframe^)
    check(
        (svc.status().messages_acked == 1),
        "ack targets the addressed tag regardless of the bits octet value",
    )


def _tag_from_consume_reply(var wire: List[UInt8]) raises -> Int:
    """Extract the delivery tag from the first flushed basic.deliver frame.

    Slice layout of the deliver frame payload
    (src/hyrxmq/amqp_service.mojo): class(2) method(2) consumer-tag
    short-string delivery-tag(8) redelivered(1) exchange short-string
    key short-string body.
    """
    var codec = AMQPFrameCodec()
    codec.feed_bytes(wire^)
    _ = codec.try_parse_frame()  # consume-ok
    var fr = codec.try_parse_frame()
    if not fr.__bool__():
        raise "no basic.deliver frame in the consume reply"
    var p = fr.value().payload_copy()
    var dm = MethodID(
        (UInt16(p[0]) << 8) | UInt16(p[1]), (UInt16(p[2]) << 8) | UInt16(p[3])
    )
    check(dm == MethodID(60, 60), "flushed frame is basic.deliver (60,60)")
    var ctlen = Int(p[4])  # consumer-tag short-string length, after class+method
    var off = 5 + ctlen
    var tag = 0
    for i in range(8):
        tag = (tag << 8) + Int(p[off + i])
    return tag


def main() raises:
    test_queue_declare_produces_ok()
    test_queue_declare_no_wait_suppresses_ok()
    test_connection_and_channel_open()
    test_publish_reaches_broker()
    test_basic_ack_uses_the_addressed_delivery_tag()
    test_basic_ack_bits_octet_is_not_a_consumer_id()
    print("PHASE7_AMQP_SERVICE_TEST=PASS")
