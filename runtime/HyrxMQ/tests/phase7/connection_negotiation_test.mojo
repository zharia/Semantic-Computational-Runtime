# Phase 7/11 — connection negotiation (start-ok -> tune -> tune-ok -> open ->
# open-ok) driven through AMQPService.handle_frame, feed-bytes / get-bytes only
# (no sockets): the listener drives the header + ordering, the service owns the
# frame semantics. Field layouts are transcribed verbatim from amqp0-9-1.xml.
#
# Proves:
#   - connection.start-ok (10,11) parses (table-skip + mechanism + SASL PLAIN
#     response + locale) and answers connection.tune (10,30) with channel-max
#     2047, frame-max and heartbeat=60 (0017 T4: the configured value is
#     ADVERTISED; the negotiated min is recorded at tune-ok).
#   - connection.tune-ok (10,31) is recorded with no reply and NEGOTIATES the
#     heartbeat (0017 T4: min(advertised, client's value) on the state).
#   - connection.open (10,40) answers open-ok (10,41) with EXACTLY one reserved
#     short-string and the correct frame length (regression: the old reply wrote
#     an extra long-string that desynchronized real clients).

from std.collections import List

from hyrxmq.config import HyrxMQConfig
from hyrxmq.amqp_service import (
    AMQPService,
    write_short_string,
    write_u16,
    write_u32,
)
from hyrx.amqp.constants import (
    CONNECTION_START_OK,
    CONNECTION_TUNE,
    CONNECTION_TUNE_OK,
    CONNECTION_OPEN,
    CONNECTION_OPEN_OK,
    MethodID,
)
from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec
from hyrx.amqp.connection_state import (
    CONN_STATE_TUNE_SENT,
    CONN_STATE_TUNE_RECEIVED,
    CONN_STATE_OPEN,
)

from hyrx.testing import check


def bytes_of(s: String) -> List[UInt8]:
    var out = List[UInt8]()
    var b = s.as_bytes()
    for i in range(len(b)):
        out.append(b[i])
    return out^


def build_frame(
    chan: UInt16, class_id: UInt16, method_id: UInt16, var args: List[UInt8]
) raises -> AMQPFrame:
    """Encode a method frame to wire bytes, then decode it back to an AMQPFrame."""
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


def reply_method_id(ref resp: List[UInt8]) raises -> MethodID:
    """The (class_id, method_id) pair of an encoded method frame (bytes [7:11])."""
    if len(resp) < 11:
        raise "reply too short to carry class+method ids"
    return MethodID(
        (UInt16(resp[7]) << 8) | UInt16(resp[8]),
        (UInt16(resp[9]) << 8) | UInt16(resp[10]),
    )


def write_longstr_bytes(mut out: List[UInt8], var data: List[UInt8]):
    """Append a long-string given as raw bytes (4-byte BE length + payload)."""
    write_u32(out, UInt32(len(data)))
    for i in range(len(data)):
        out.append(data[i])


def start_ok_args() -> List[UInt8]:
    """connection.start-ok args: client-properties(table=empty) +
    mechanism(shortstr="PLAIN") + response(longstr=SASL PLAIN) + locale."""
    var args = List[UInt8]()
    write_u32(args, 0)  # client-properties: empty field table
    write_short_string(args, "PLAIN")  # mechanism
    # SASL PLAIN response = authzid NUL authcid NUL passwd  (RFC 4616).
    var resp = List[UInt8]()
    resp.append(0)  # empty authzid
    for b in bytes_of("admin"):
        resp.append(b)
    resp.append(0)
    for b in bytes_of("password"):
        resp.append(b)
    write_longstr_bytes(args, resp^)  # response (longstr)
    write_short_string(args, "en_US")  # locale
    return args^


def test_start_ok_yields_tune() raises:
    var cfg = HyrxMQConfig()
    cfg.frame_max = 131072
    var svc = AMQPService(cfg^)
    svc.start()

    check(CONNECTION_START_OK() == MethodID(10, 11), "start-ok spec id")
    check(CONNECTION_TUNE() == MethodID(10, 30), "tune spec id")

    var frame = build_frame(
        UInt16(0),
        CONNECTION_START_OK().class_id,
        CONNECTION_START_OK().method_id,
        start_ok_args()^,
    )
    var resp = svc.handle_frame(UInt64(100), frame^)
    check(resp.__bool__(), "start-ok must answer with a tune frame")
    var wire = resp.value().copy()
    check(wire[0] == 1, "tune is a METHOD frame")
    check(wire[1] == 0 and wire[2] == 0, "tune frame channel is 0")
    check(
        reply_method_id(wire) == MethodID(10, 30),
        "tune is (10,30) per amqp0-9-1.xml",
    )
    # tune args: channel-max(short) frame-max(long) heartbeat(short) = 8 bytes.
    # frame = 7 header + 4 (class+method) + 8 args + 1 end = 20 bytes.
    check(len(wire) == 20, "tune frame has the exact spec length")
    # channel-max = 2047 = 0x07FF
    check(wire[11] == 0x07 and wire[12] == 0xFF, "tune channel-max is 2047")
    # frame-max = 131072 = 0x00020000
    check(
        wire[13] == 0x00
        and wire[14] == 0x02
        and wire[15] == 0x00
        and wire[16] == 0x00,
        "tune frame-max is 131072 (big-endian)",
    )
    # heartbeat = 60 = 0x003C (0017 T4: the advertised configured value; the
    # negotiated min is recorded at tune-ok, no timer subsystem exists).
    check(wire[17] == 0x00 and wire[18] == 60, "tune heartbeat is 60")
    check(wire[len(wire) - 1] == 0xCE, "tune ends with frame-end")

    # State advanced to TUNE_SENT (open-ok not yet reached).
    check(svc._conns[UInt64(100)].state() == CONN_STATE_TUNE_SENT(), "state=TUNE_SENT")
    check(not svc.connection_is_open(UInt64(100)), "connection not yet open")


def test_tune_ok_records_no_reply() raises:
    var cfg = HyrxMQConfig()
    var fm = cfg.frame_max
    var svc = AMQPService(cfg^)
    svc.start()
    var a = List[UInt8]()
    write_u16(a, 2047)
    write_u32(a, UInt32(fm))
    write_u16(a, 0)
    var frame = build_frame(
        UInt16(0),
        CONNECTION_TUNE_OK().class_id,
        CONNECTION_TUNE_OK().method_id,
        a^,
    )
    var resp = svc.handle_frame(UInt64(101), frame^)
    check(not resp.__bool__(), "tune-ok produces no reply")
    check(
        svc._conns[UInt64(101)].state() == CONN_STATE_TUNE_RECEIVED(),
        "tune-ok recorded (state=TUNE_RECEIVED)",
    )
    # 0017 T4: the heartbeat NEGOTIATES = min(advertised 60, client's 0) = 0.
    check(svc.negotiated_heartbeat(UInt64(101)) == 0, "negotiated hb = 0")
    # A NON-ZERO client value negotiates to min(60, client).
    var svc2 = AMQPService(HyrxMQConfig()^)
    svc2.start()
    var a2 = List[UInt8]()
    write_u16(a2, 2047)
    write_u32(a2, UInt32(fm))
    write_u16(a2, 30)
    var frame2 = build_frame(
        UInt16(0),
        CONNECTION_TUNE_OK().class_id,
        CONNECTION_TUNE_OK().method_id,
        a2^,
    )
    _ = svc2.handle_frame(UInt64(102), frame2^)
    check(svc2.negotiated_heartbeat(UInt64(102)) == 30, "negotiated min(60,30)")


def test_open_answers_single_shortstr_open_ok() raises:
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()

    # connection.open args: virtual-host + reserved-1 + reserved-2(bit).
    var oargs = List[UInt8]()
    write_short_string(oargs, "/")
    write_short_string(oargs, "")
    oargs.append(0)  # reserved-2 bit packed into one octet
    var frame = build_frame(
        UInt16(0),
        CONNECTION_OPEN().class_id,
        CONNECTION_OPEN().method_id,
        oargs^,
    )
    var resp = svc.handle_frame(UInt64(102), frame^)
    check(resp.__bool__(), "connection.open must answer open-ok")
    var wire = resp.value().copy()
    check(
        reply_method_id(wire) == MethodID(10, 41),
        "open-ok is (10,41) per amqp0-9-1.xml",
    )
    # open-ok args are a SINGLE reserved-1 short-string (empty). A real client
    # desynchronizes if the old extra long-string reappears, so pin the EXACT
    # frame length: 7 header + 4 (class+method) + 1 (empty shortstr) + 1 end = 13.
    check(
        len(wire) == 13,
        "open-ok carries EXACTLY one reserved short-string (no stray longstr)",
    )
    check(wire[11] == 0, "the single open-ok arg is an empty short-string")
    check(wire[len(wire) - 1] == 0xCE, "open-ok ends with frame-end")

    check(svc.connection_is_open(UInt64(102)), "connection marked OPEN")
    check(svc._conns[UInt64(102)].state() == CONN_STATE_OPEN(), "state=OPEN")


def main() raises:
    test_start_ok_yields_tune()
    test_tune_ok_records_no_reply()
    test_open_answers_single_shortstr_open_ok()
    print("PHASE7_CONNECTION_NEGOTIATION_TEST=PASS")
