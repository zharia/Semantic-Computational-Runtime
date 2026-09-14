# Phase 10 — AMQP protocol state-machine edge-case test.
#
# Feeds WRONG-METHOD-IN-WRONG-STATE frame sequences directly into AMQPService
# (no sockets) and asserts that every sequence is handled WITHOUT an uncaught
# exception: the service either returns the normative protocol error reply or
# tolerates the frame gracefully. The service intentionally does not gate
# business methods on the connection=open state (see the module header of
# amqp_service.mojo), so "tolerates gracefully" is the expected outcome for the
# ordering violations; unknown-exchange publish and missing-queue consume are
# the normative 404 channel.close cases.
#
# A segfault or an uncaught raise aborts Mojo, so the final
# PROTOCOL_STATE_TEST=PASS line itself proves every sequence was survivable.

from std.collections import List, Optional

from hyrxmq.config import HyrxMQConfig
from hyrxmq.amqp_service import (
    AMQPService,
    write_short_string,
    write_long_string,
    write_u16,
    write_u32,
    write_u64,
)
from hyrx.amqp.constants import (
    CONNECTION_START_OK,
    CONNECTION_TUNE,
    CONNECTION_TUNE_OK,
    CONNECTION_CLOSE,
    CONNECTION_CLOSE_OK,
    CONNECTION_OPEN,
    CONNECTION_OPEN_OK,
    CHANNEL_OPEN,
    CHANNEL_OPEN_OK,
    CHANNEL_CLOSE,
    CHANNEL_CLOSE_OK,
    QUEUE_DECLARE,
    QUEUE_DECLARE_OK,
    BASIC_PUBLISH,
    BASIC_CONSUME,
    BASIC_ACK,
    MethodID,
)
from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec
from hyrx.testing import check


# ---- outcome of feeding one frame ----

struct Outcome:
    """Whether handle_frame returned (never raised) and what it replied."""
    var reached: Bool
    var has_resp: Bool
    var mid: MethodID
    var error: String

    def __init__(out self):
        self.reached = False
        self.has_resp = False
        self.mid = MethodID(0, 0)
        self.error = String()


def feed(mut svc: AMQPService, conn_id: UInt64, frame: AMQPFrame) -> Outcome:
    """Feed one decoded frame; never let a raise abort the harness."""
    var o = Outcome()
    try:
        var resp = svc.handle_frame(conn_id, frame)
        o.reached = True
        if resp.__bool__():
            o.has_resp = True
            var b = resp.value().copy()
            if len(b) >= 11:
                o.mid = MethodID(
                    (UInt16(b[7]) << 8) | UInt16(b[8]),
                    (UInt16(b[9]) << 8) | UInt16(b[10]),
                )
    except e:
        o.reached = False
        o.error = String(e)
    return o^


# ---- frame builders ----

def build_frame(
    chan: UInt16, class_id: UInt16, method_id: UInt16, var args: List[UInt8]
) raises -> AMQPFrame:
    """Encode a method frame to wire bytes, then decode back to an AMQPFrame."""
    var wire = AMQPFrameCodec.encode_method_frame(chan, class_id, method_id, args^)
    var codec = AMQPFrameCodec()
    codec.feed_bytes(wire^)
    var fr = codec.try_parse_frame()
    if not fr.__bool__():
        raise "build_frame: could not decode"
    return AMQPFrame(
        fr.value().frame_type, fr.value().channel, fr.value().payload_copy()
    )^


def build_header_frame(
    chan: UInt16, class_id: UInt16, size: UInt64, flags: UInt16
) raises -> AMQPFrame:
    var hdr = AMQPFrameCodec.encode_header_frame(chan, class_id, size, flags, List[UInt8]())
    var codec = AMQPFrameCodec()
    codec.feed_bytes(hdr^)
    var fr = codec.try_parse_frame()
    if not fr.__bool__():
        raise "build_header_frame: could not decode"
    return AMQPFrame(
        fr.value().frame_type, fr.value().channel, fr.value().payload_copy()
    )^


def build_body_frame(chan: UInt16, var body: List[UInt8]) raises -> AMQPFrame:
    var wire = AMQPFrameCodec.encode_body_frame(chan, body^)
    var codec = AMQPFrameCodec()
    codec.feed_bytes(wire^)
    var fr = codec.try_parse_frame()
    if not fr.__bool__():
        raise "build_body_frame: could not decode"
    return AMQPFrame(
        fr.value().frame_type, fr.value().channel, fr.value().payload_copy()
    )^


def reserved() -> List[UInt8]:
    var a = List[UInt8]()
    a.append(0)
    a.append(0)
    return a^


def append_empty_table(mut a: List[UInt8]):
    a.append(0)
    a.append(0)
    a.append(0)
    a.append(0)


def new_service() raises -> AMQPService:
    var cfg = HyrxMQConfig()
    cfg.validate()
    var svc = AMQPService(cfg^)
    svc.start()
    return svc^


# ---- scenario 1: connection.start-ok before connection.start ----

def test_start_ok_before_start() raises:
    var svc = new_service()

    # valid SASL PLAIN admin/password -> the service emits connection.tune.
    var a = List[UInt8]()
    append_empty_table(a)
    write_short_string(a, "PLAIN")
    write_long_string(a, "\0admin\0password")
    write_short_string(a, "en_US")
    var o = feed(svc, UInt64(101), build_frame(UInt16(0), UInt16(10), UInt16(11), a^)^)
    check(o.reached, "start-ok (valid) must not raise: " + o.error)
    check(o.has_resp, "start-ok (valid) produces a reply")
    check(o.mid == CONNECTION_TUNE(), "start-ok (valid) -> connection.tune (10,30)")

    # bad SASL PLAIN credentials -> normative connection.close 403.
    var svc2 = new_service()
    var b = List[UInt8]()
    append_empty_table(b)
    write_short_string(b, "PLAIN")
    write_long_string(b, "\0admin\0wrong")
    write_short_string(b, "en_US")
    var o2 = feed(svc2, UInt64(102), build_frame(UInt16(0), UInt16(10), UInt16(11), b^)^)
    check(o2.reached, "start-ok (bad creds) must not raise: " + o2.error)
    check(o2.has_resp, "start-ok (bad creds) produces a reply")
    check(o2.mid == CONNECTION_CLOSE(), "bad creds -> server connection.close (10,50)")


# ---- scenario 2: channel.open before connection.open ----

def test_channel_open_before_connection_open() raises:
    var svc = new_service()
    var args = List[UInt8]()
    write_short_string(args, "")
    var o = feed(svc, UInt64(103), build_frame(UInt16(1), UInt16(20), UInt16(10), args^)^)
    check(o.reached, "channel.open before connection.open must not raise: " + o.error)
    check(o.mid == CHANNEL_OPEN_OK(), "channel.open still -> channel.open-ok (20,11)")


# ---- scenario 3: basic.publish before channel.open ----

def test_publish_before_channel_open() raises:
    var svc = new_service()

    # METHOD: reserved + exchange "nope" (unknown) + routing-key "x" + bits 0.
    var args = reserved()
    write_short_string(args, "nope")
    write_short_string(args, "x")
    args.append(0)
    var om = feed(svc, UInt64(104), build_frame(UInt16(1), UInt16(60), UInt16(40), args^)^)
    check(om.reached, "publish METHOD before channel.open must not raise: " + om.error)

    # HEADER: class 60, body-size 3, no properties.
    var oh = feed(svc, UInt64(104), build_header_frame(UInt16(1), UInt16(60), UInt64(3), UInt16(0))^)
    check(oh.reached, "publish HEADER before channel.open must not raise: " + oh.error)

    # BODY: completes reassembly -> unknown exchange -> 404 channel.close.
    var body = List[UInt8]()
    body.append(0x41)
    body.append(0x42)
    body.append(0x43)
    var ob = feed(svc, UInt64(104), build_body_frame(UInt16(1), body^)^)
    check(ob.reached, "publish BODY before channel.open must not raise: " + ob.error)
    check(ob.has_resp, "unknown-exchange publish yields an error reply")
    check(ob.mid == CHANNEL_CLOSE(), "unknown exchange -> channel.close 404 (20,40)")


# ---- scenario 4: queue.declare before channel.open ----

def test_queue_declare_before_channel_open() raises:
    var svc = new_service()
    var args = reserved()
    write_short_string(args, "q-early")
    args.append(0)
    append_empty_table(args)
    var o = feed(svc, UInt64(105), build_frame(UInt16(1), UInt16(50), UInt16(10), args^)^)
    check(o.reached, "queue.declare before channel.open must not raise: " + o.error)
    check(o.mid == QUEUE_DECLARE_OK(), "queue.declare still -> declare-ok (50,11)")


# ---- scenario 5: basic.consume before queue.declare ----

def test_consume_before_queue_declare() raises:
    var svc = new_service()
    var args = reserved()
    write_short_string(args, "no-such-queue")
    write_short_string(args, "")
    args.append(0)
    append_empty_table(args)
    var o = feed(svc, UInt64(106), build_frame(UInt16(1), UInt16(60), UInt16(20), args^)^)
    check(o.reached, "basic.consume before queue.declare must not raise: " + o.error)
    check(o.has_resp, "consume of a missing queue yields an error reply")
    check(o.mid == CHANNEL_CLOSE(), "missing queue -> 404 channel.close (20,40)")


# ---- scenario 6: basic.ack with no deliveries ----

def test_ack_with_no_deliveries() raises:
    var svc = new_service()
    var args = List[UInt8]()
    write_u64(args, UInt64(1))
    args.append(0)  # multiple = false
    var o = feed(svc, UInt64(107), build_frame(UInt16(1), UInt16(60), UInt16(80), args^)^)
    check(o.reached, "basic.ack with no deliveries must not raise: " + o.error)
    check(not o.has_resp, "basic.ack is fire-and-forget (no reply)")


# ---- scenario 7: connection.close already closed (double close) ----

def test_double_connection_close() raises:
    var svc = new_service()
    var args = reserved()
    write_u16(args, UInt16(200))
    write_short_string(args, "bye")
    write_u16(args, UInt16(0))
    write_u16(args, UInt16(0))
    var o1 = feed(svc, UInt64(108), build_frame(UInt16(0), UInt16(10), UInt16(50), args.copy())^)
    check(o1.reached, "first connection.close must not raise: " + o1.error)
    check(o1.mid == CONNECTION_CLOSE_OK(), "first connection.close -> close-ok (10,51)")

    var o2 = feed(svc, UInt64(108), build_frame(UInt16(0), UInt16(10), UInt16(50), args^)^)
    check(o2.reached, "second connection.close must not raise: " + o2.error)
    check(o2.mid == CONNECTION_CLOSE_OK(), "double close -> close-ok tolerated (10,51)")


# ---- scenario 8: channel.close on an unopened channel ----

def test_channel_close_on_unopened_channel() raises:
    var svc = new_service()
    var cargs = reserved()
    write_u16(cargs, UInt16(200))
    write_short_string(cargs, "bye")
    write_u16(cargs, UInt16(0))
    write_u16(cargs, UInt16(0))
    var o1 = feed(svc, UInt64(109), build_frame(UInt16(5), UInt16(20), UInt16(40), cargs^)^)
    check(o1.reached, "channel.close on unopened channel must not raise: " + o1.error)
    check(o1.mid == CHANNEL_CLOSE_OK(), "channel.close -> close-ok (20,41)")

    # the number now counts closed: a business method gets the 404 channel.close.
    var qargs = reserved()
    write_short_string(qargs, "q-after-close")
    qargs.append(0)
    append_empty_table(qargs)
    var o2 = feed(svc, UInt64(109), build_frame(UInt16(5), UInt16(50), UInt16(10), qargs^)^)
    check(o2.reached, "method on closed channel must not raise: " + o2.error)
    check(o2.mid == CHANNEL_CLOSE(), "business method on closed channel -> channel.close 404")


# ---- scenario 9: connection.tune-ok with wrong values ----

def test_tune_ok_with_wrong_values() raises:
    var svc = new_service()
    var args = List[UInt8]()
    write_u16(args, UInt16(0))  # channel-max = 0 (nonsensical)
    write_u32(args, UInt32(0))  # frame-max = 0 (below the 4096 floor)
    write_u16(args, UInt16(9999))  # heartbeat far above the advertised 60
    var o = feed(svc, UInt64(110), build_frame(UInt16(0), UInt16(10), UInt16(31), args^)^)
    check(o.reached, "connection.tune-ok with wrong values must not raise: " + o.error)
    check(not o.has_resp, "connection.tune-ok is fire-and-forget (no reply)")


def main() raises:
    test_start_ok_before_start()
    test_channel_open_before_connection_open()
    test_publish_before_channel_open()
    test_queue_declare_before_channel_open()
    test_consume_before_queue_declare()
    test_ack_with_no_deliveries()
    test_double_connection_close()
    test_channel_close_on_unopened_channel()
    test_tune_ok_with_wrong_values()
    print("PROTOCOL_STATE_TEST=PASS")
