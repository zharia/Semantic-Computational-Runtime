# Phase 7 — HyrxMQ AMQP service tests.
#
# Feeds encoded AMQP method frames through the broker's handler and checks the
# encoded responses. No sockets: this is feed-bytes / get-bytes.

from std.collections import List

from hyrxmq.config import HyrxMQConfig
from hyrxmq.amqp_service import AMQPService, write_short_string
from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec


def check(cond: Bool, var msg: String) raises:
    if not cond:
        raise "FAIL: " + msg


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


def test_queue_declare_produces_ok() raises:
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()

    var args = reserved()
    write_short_string(args, "orders")
    var frame = build_frame(UInt16(1), UInt16(50), UInt16(10), args^)
    var resp = svc.handle_frame(UInt64(1), frame^)

    check(resp.__bool__(), "queue.declare must produce a response")
    check((len(resp.value()) > 7), "response has frame header")
    check((resp.value()[0] == 1), "response frame_type is METHOD (1)")
    # method payload: class_id at bytes [7:9], method_id at [9:11]
    var class_id = (UInt16(resp.value()[7]) << 8) | UInt16(resp.value()[8])
    var method_id = (UInt16(resp.value()[9]) << 8) | UInt16(resp.value()[10])
    check((class_id == 50), "declare-ok class is 50 (queue)")
    check((method_id == 11), "declare-ok method is 11")
    check(
        (resp.value()[len(resp.value()) - 1] == 0xCE),
        "response ends with frame-end byte",
    )


def test_connection_and_channel_open() raises:
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()

    # connection.open (10,5) on channel 0 -> open-ok (10,6)
    var oargs = List[UInt8]()
    write_short_string(oargs, "/")
    oargs.append(0)
    oargs.append(0)
    oargs.append(0)
    oargs.append(0)
    var oframe = build_frame(UInt16(0), UInt16(10), UInt16(5), oargs^)
    var oresp = svc.handle_frame(UInt64(3), oframe^)
    check(oresp.__bool__(), "connection.open -> open-ok")
    check(svc.connection_is_open(UInt64(3)), "connection marked open")

    # channel.open (20,1) on channel 1 -> open-ok (20,2)
    var cargs = List[UInt8]()
    cargs.append(0)
    cargs.append(0)
    cargs.append(0)
    cargs.append(0)
    var cframe = build_frame(UInt16(1), UInt16(20), UInt16(1), cargs^)
    var cresp = svc.handle_frame(UInt64(3), cframe^)
    check(cresp.__bool__(), "channel.open -> open-ok")
    check(
        ((UInt16(cresp.value()[7]) << 8 | UInt16(cresp.value()[8])) == 20),
        "channel-open-ok class 20",
    )
    check(
        ((UInt16(cresp.value()[9]) << 8 | UInt16(cresp.value()[10])) == 2),
        "channel-open-ok method 2",
    )


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


def main() raises:
    test_queue_declare_produces_ok()
    test_connection_and_channel_open()
    test_publish_reaches_broker()
    print("PHASE7_AMQP_SERVICE_TEST=PASS")
