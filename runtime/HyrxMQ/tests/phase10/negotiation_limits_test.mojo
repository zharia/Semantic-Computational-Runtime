# Phase 10 — frame_max / channel_max NEGOTIATION enforcement test.
#
# Two seams, proven end-to-end over a REAL TCP listener plus one direct codec
# assertion:
#   (a) AMQPFrameCodec.set_frame_limit re-limits a codec and a frame whose
#       DECLARED size exceeds the (smaller) limit is rejected;
#   (b) after a client tune-ok requesting frame_max=4096, the listener
#       re-limits the connection's codec: a raw frame declaring 8192 bytes is
#       failed closed even though the SERVER ceiling is 131072;
#   (c) after a client tune-ok requesting channel_max=2, channel.open on
#       channel 3 gets the normative channel error 504 CHANNEL_ERROR with text
#       "channel_max exceeded", while channel 1 still opens;
#   (d) connection.tune still ADVERTISES the unchanged server ceilings
#       (channel-max 2047, frame-max = configured 131072).
#
# Mojo 1.0.0: assert is inert, so every assertion goes through
# hyrx.testing.check (raises on failure).

from std.collections import List

from hyrx.transport.tcp import TCPConnection
from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec
from hyrx.amqp.constants import (
    CONNECTION_START,
    CONNECTION_START_OK,
    CONNECTION_TUNE,
    CONNECTION_TUNE_OK,
    CONNECTION_OPEN,
    CONNECTION_OPEN_OK,
    CHANNEL_OPEN,
    CHANNEL_OPEN_OK,
    CHANNEL_CLOSE,
    MethodID,
)

from hyrxmq.amqp_service import write_short_string, write_u16, write_u32
from hyrxmq.config import HyrxMQConfig
from hyrxmq.listener import (
    AMQPListener,
    SERVE_DISPATCHED,
    SERVE_FAILED,
)

from hyrx.testing import check


def _protocol_header() -> List[UInt8]:
    var h = List[UInt8]()
    h.append(0x41)
    h.append(0x4D)
    h.append(0x51)
    h.append(0x50)
    h.append(0x00)
    h.append(0x00)
    h.append(0x09)
    h.append(0x01)
    return h^


def _method_wire(
    chan: UInt16, mid: MethodID, var args: List[UInt8]
) -> List[UInt8]:
    return AMQPFrameCodec.encode_method_frame(
        chan, mid.class_id, mid.method_id, args^
    )


def _method_code(mid: MethodID) -> Int:
    return Int(mid.class_id) * 1000 + Int(mid.method_id)


def _start_ok_wire() -> List[UInt8]:
    var args = List[UInt8]()
    write_u32(args, 0)
    write_short_string(args, "PLAIN")
    var resp = List[UInt8]()
    resp.append(0)
    for b in "admin".as_bytes():
        resp.append(b)
    resp.append(0)
    for b in "password".as_bytes():
        resp.append(b)
    write_u32(args, UInt32(len(resp)))
    for b in resp:
        args.append(b)
    write_short_string(args, "en_US")
    return _method_wire(UInt16(0), CONNECTION_START_OK(), args^)


def _tune_ok_wire(cm: UInt16, fm: UInt32) -> List[UInt8]:
    var args = List[UInt8]()
    write_u16(args, cm)
    write_u32(args, fm)
    write_u16(args, 0)  # heartbeat disabled
    return _method_wire(UInt16(0), CONNECTION_TUNE_OK(), args^)


def _open_wire() -> List[UInt8]:
    var args = List[UInt8]()
    write_short_string(args, "/")
    write_short_string(args, "")
    args.append(0)
    return _method_wire(UInt16(0), CONNECTION_OPEN(), args^)


def _mid_of(var p: List[UInt8]) -> MethodID:
    return MethodID(
        (UInt16(p[0]) << 8) | UInt16(p[1]),
        (UInt16(p[2]) << 8) | UInt16(p[3]),
    )


def _read_method_payload(
    mut conn: TCPConnection, mut codec: AMQPFrameCodec
) raises -> List[UInt8]:
    """Read the next METHOD frame's payload bytes (class+method+args)."""
    var i = 0
    while i < 32:
        var f = codec.try_parse_frame()
        if f.__bool__():
            return f.value().payload_copy()
        var chunk = conn.recv_bytes(4096)
        if len(chunk) == 0:
            raise "connection closed while awaiting a method frame"
        codec.feed_bytes(chunk^)
        i += 1
    raise "no method frame within 32 reads"


def _handshake_with_limits(
    mut conn: TCPConnection,
    mut listener: AMQPListener,
    slot: Int,
    cm: UInt16,
    fm: UInt32,
) raises -> AMQPFrameCodec:
    """Full handshake with a client tune-ok carrying (cm, fm).

    Also asserts the server's tune still advertises the unchanged ceilings
    (channel-max 2047, frame-max 131072).
    """
    var codec = AMQPFrameCodec()

    _ = conn.send_bytes(_protocol_header())
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "limits handshake: header accepted",
    )
    var first = conn.recv_exact(1)
    codec.feed_bytes(first^)
    var start_p = _read_method_payload(conn, codec)
    check(_mid_of(start_p.copy()) == CONNECTION_START(), "limits handshake: connection.start")

    _ = conn.send_bytes(_start_ok_wire())
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "limits handshake: start-ok dispatched",
    )
    var tune_p = _read_method_payload(conn, codec)
    check(_mid_of(tune_p.copy()) == CONNECTION_TUNE(), "limits handshake: connection.tune")
    # tune args: channel-max(short) + frame-max(long) + heartbeat(short).
    var advertised_cm = (UInt16(tune_p[4]) << 8) | UInt16(tune_p[5])
    var advertised_fm = (
        (UInt32(tune_p[6]) << 24)
        | (UInt32(tune_p[7]) << 16)
        | (UInt32(tune_p[8]) << 8)
        | UInt32(tune_p[9])
    )
    check((advertised_cm == UInt16(2047)), "tune advertises server channel-max 2047")
    check((advertised_fm == UInt32(131072)), "tune advertises server frame-max 131072")

    _ = conn.send_bytes(_tune_ok_wire(cm, fm))
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "limits handshake: tune-ok dispatched (codec re-limited)",
    )
    _ = conn.send_bytes(_open_wire())
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "limits handshake: connection.open dispatched",
    )
    check(
        _mid_of(_read_method_payload(conn, codec)) == CONNECTION_OPEN_OK(),
        "limits handshake: open-ok",
    )
    return codec^


def _make_listener() -> AMQPListener:
    var cfg = HyrxMQConfig()
    cfg.listen_host = "127.0.0.1"
    cfg.port = 0
    return AMQPListener(cfg^)


# ---- (a) direct codec re-limit ----

def test_codec_set_frame_limit_rejects_oversized() raises:
    var codec = AMQPFrameCodec(131072)
    check((codec.frame_limit() == 131072), "codec starts at the server ceiling")
    codec.set_frame_limit(4096)
    check((codec.frame_limit() == 4096), "codec re-limited to the negotiated value")
    # A BODY frame declaring 8192 bytes must be rejected on the declared size,
    # even though only the 7-octet prefix has arrived.
    var big = List[UInt8]()
    big.append(3)  # FRAME_BODY
    big.append(0)
    big.append(1)
    big.append(0x00)
    big.append(0x00)
    big.append(0x20)
    big.append(0x00)  # size = 8192
    codec.feed_bytes(big^)
    var rejected = False
    try:
        _ = codec.try_parse_frame()
    except:
        rejected = True
    check(rejected, "oversized declared frame rejected after re-limit")
    # A non-positive limit never removes/raises the ceiling.
    codec.set_frame_limit(0)
    check((codec.frame_limit() == 4096), "set_frame_limit(0) is ignored")


# ---- (b) listener re-limits the connection codec on tune-ok ----

def test_frame_max_renegotiation_enforced() raises:
    var listener = _make_listener()
    check(listener.start(), "listener started")
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    check(slot >= 0, "accepted")
    _ = _handshake_with_limits(conn, listener, slot, UInt16(2047), UInt32(4096))

    # Server ceiling is 131072, but the negotiated one is 4096: declare 8192.
    var big = List[UInt8]()
    big.append(3)  # FRAME_BODY
    big.append(0)
    big.append(1)
    big.append(0x00)
    big.append(0x00)
    big.append(0x20)
    big.append(0x00)  # size = 8192 > 4096
    _ = conn.send_bytes(big^)
    var rc = listener.serve_one_frame(slot)
    check(
        rc == SERVE_FAILED(),
        "negotiated frame_max=4096 rejects an 8192-byte frame (rc=" + String(rc) + ")",
    )
    conn.close()
    listener.stop()


# ---- (c) negotiated channel_max enforced on channel.open ----

def test_channel_max_renegotiation_enforced() raises:
    var listener = _make_listener()
    check(listener.start(), "listener started")
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    check(slot >= 0, "accepted")
    var codec = _handshake_with_limits(
        conn, listener, slot, UInt16(2), UInt32(131072)
    )

    # channel 1 (< negotiated channel_max 2) still opens.
    _ = conn.send_bytes(_method_wire(UInt16(1), CHANNEL_OPEN(), List[UInt8]()))
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "channel 1 open dispatched",
    )
    check(
        _mid_of(_read_method_payload(conn, codec)) == CHANNEL_OPEN_OK(),
        "channel 1 under channel_max=2 opens normally",
    )

    # channel 3 (>= negotiated channel_max 2) => 504 CHANNEL_ERROR.
    _ = conn.send_bytes(_method_wire(UInt16(3), CHANNEL_OPEN(), List[UInt8]()))
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "channel 3 open dispatched",
    )
    var err_p = _read_method_payload(conn, codec)
    check(
        _mid_of(err_p.copy()) == CHANNEL_CLOSE(),
        "channel 3 gets a channel.close (channel error)",
    )
    var reply_code = (UInt16(err_p[4]) << 8) | UInt16(err_p[5])
    check((reply_code == UInt16(504)), "reply-code is 504 CHANNEL_ERROR")
    var tlen = Int(err_p[6])
    var text = String()
    for i in range(7, 7 + tlen):
        text += String(chr(Int(err_p[i])))
    check((text == "channel_max exceeded"), "reply-text is 'channel_max exceeded'")

    conn.close()
    listener.stop()


def main() raises:
    test_codec_set_frame_limit_rejects_oversized()
    test_frame_max_renegotiation_enforced()
    test_channel_max_renegotiation_enforced()
    print("NEGOTIATION_LIMITS_TEST=PASS")
