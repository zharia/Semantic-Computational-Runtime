# Phase 10 — Network failure resilience tests.
#
# Proves the broker survives hostile / malformed / truncated network input
# without crashing and keeps serving new connections. One AMQPListener is
# started on an ephemeral port (port=0); each scenario drives it over a REAL
# TCPConnection with raw bytes, then a fresh connection proves the listener is
# still alive (broker-alive invariant).
#
# Mojo 1.0.0: assert is inert, so every assertion goes through
# `hyrx.testing.check` (raises on failure). No sleeps/retries: each scenario is
# a bounded step sequence that completes well under 3 s.

from std.collections import List

from hyrx.transport.tcp import TCPConnection
from hyrx.amqp.frame_codec import AMQPFrameCodec
from hyrx.amqp.constants import (
    CONNECTION_START,
    CONNECTION_START_OK,
    CONNECTION_TUNE,
    CONNECTION_TUNE_OK,
    CONNECTION_OPEN,
    CONNECTION_OPEN_OK,
    CONNECTION_CLOSE,
    CONNECTION_CLOSE_OK,
    CHANNEL_OPEN,
    CHANNEL_OPEN_OK,
    CHANNEL_CLOSE,
    CHANNEL_CLOSE_OK,
    QUEUE_DECLARE,
    MethodID,
)

from hyrxmq.amqp_service import write_short_string, write_u16, write_u32
from hyrxmq.config import HyrxMQConfig
from hyrxmq.listener import (
    AMQPListener,
    SERVE_CLOSED,
    SERVE_DISPATCHED,
    SERVE_FAILED,
    SERVE_PARTIAL,
)

from hyrx.testing import check


# ── wire helpers (AMQP 0-9-1) ─────────────────────────────────────────────

def _protocol_header() -> List[UInt8]:
    """The 8-octet AMQP 0-9-1 protocol header 41 4D 51 50 00 00 09 01."""
    var h = List[UInt8]()
    h.append(0x41)  # A
    h.append(0x4D)  # M
    h.append(0x51)  # Q
    h.append(0x50)  # P
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
    """Packed class*1000+method discriminator, as `_read_method_code` returns."""
    return Int(mid.class_id) * 1000 + Int(mid.method_id)


def _start_ok_wire() -> List[UInt8]:
    """connection.start-ok with SASL PLAIN admin/password."""
    var args = List[UInt8]()
    write_u32(args, 0)  # empty client-properties table
    write_short_string(args, "PLAIN")
    var resp = List[UInt8]()
    resp.append(0)  # authzid
    for b in "admin".as_bytes():
        resp.append(b)
    resp.append(0)  # NUL separator
    for b in "password".as_bytes():
        resp.append(b)
    write_u32(args, UInt32(len(resp)))  # response longstr
    for b in resp:
        args.append(b)
    write_short_string(args, "en_US")
    return _method_wire(UInt16(0), CONNECTION_START_OK(), args^)


def _tune_ok_wire() -> List[UInt8]:
    var args = List[UInt8]()
    write_u16(args, 2047)  # channel-max
    write_u32(args, UInt32(131072))  # frame-max
    write_u16(args, 0)  # heartbeat
    return _method_wire(UInt16(0), CONNECTION_TUNE_OK(), args^)


def _open_wire() -> List[UInt8]:
    var args = List[UInt8]()
    write_short_string(args, "/")  # virtual-host
    write_short_string(args, "")  # capabilities (reserved)
    args.append(0)  # insist bit
    return _method_wire(UInt16(0), CONNECTION_OPEN(), args^)


def _read_method_code(
    mut conn: TCPConnection, mut codec: AMQPFrameCodec
) raises -> Int:
    """Read the next method frame's class*1000+method code, or -1 on EOF."""
    var i = 0
    while i < 32:
        var f = codec.try_parse_frame()
        if f.__bool__():
            var p = f.value().payload_copy()
            if len(p) < 4:
                return -1
            var cid = (UInt32(p[0]) << 8) | UInt32(p[1])
            var mid = (UInt32(p[2]) << 8) | UInt32(p[3])
            return Int(cid) * 1000 + Int(mid)
        var chunk = conn.recv_bytes(4096)
        if len(chunk) == 0:
            return -1
        codec.feed_bytes(chunk^)
        i += 1
    return -1


# ── the shared full-handshake helper (header → start-ok → tune-ok → open) ──

def _do_handshake(
    mut conn: TCPConnection, mut listener: AMQPListener, slot: Int
) raises:
    """Complete AMQP 0-9-1 negotiation up to connection.open-ok."""
    var codec = AMQPFrameCodec()

    _ = conn.send_bytes(_protocol_header())
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "handshake: protocol header accepted",
    )
    # amqp0-9-1.xml §1.4.2.2: no header echo; the server's first bytes are
    # the connection.start METHOD frame (type 0x01).
    var first = conn.recv_exact(1)
    check(
        first[0] == UInt8(0x01),
        "handshake: server's first byte is a METHOD frame (no echo)",
    )
    codec.feed_bytes(first^)
    check(
        _read_method_code(conn, codec) == _method_code(CONNECTION_START()),
        "handshake: connection.start received",
    )

    _ = conn.send_bytes(_start_ok_wire())
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "handshake: start-ok dispatched",
    )
    check(
        _read_method_code(conn, codec) == _method_code(CONNECTION_TUNE()),
        "handshake: connection.tune received",
    )

    _ = conn.send_bytes(_tune_ok_wire())
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "handshake: tune-ok dispatched",
    )
    _ = conn.send_bytes(_open_wire())
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "handshake: connection.open dispatched",
    )
    check(
        _read_method_code(conn, codec) == _method_code(CONNECTION_OPEN_OK()),
        "handshake: connection.open-ok received",
    )


def _make_listener() -> AMQPListener:
    var cfg = HyrxMQConfig()
    cfg.listen_host = "127.0.0.1"
    cfg.port = 0
    return AMQPListener(cfg^)


def _probe_alive(mut listener: AMQPListener) raises:
    """Broker-alive invariant: a brand-new connection still handshakes."""
    var c = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    check(slot >= 0, "broker alive: fresh accept succeeds")
    _do_handshake(c, listener, slot)
    c.close()
    check(
        listener.serve_one_frame(slot) == SERVE_CLOSED(),
        "broker alive: clean EOF observed after close",
    )


# ── 1. malformed frame (garbage bytes after the protocol header) ──────────

def test_malformed_frame(mut listener: AMQPListener) raises:
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    var codec = AMQPFrameCodec()

    _ = conn.send_bytes(_protocol_header())
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "malformed: header served",
    )
    # No header echo: the first server byte is the connection.start METHOD
    # frame type, then the start frame is drained.
    var first = conn.recv_exact(1)
    check(
        first[0] == UInt8(0x01),
        "malformed: server's first byte is a METHOD frame (no echo)",
    )
    codec.feed_bytes(first^)
    _ = _read_method_code(conn, codec)  # connection.start

    # Garbage that is not a legal frame_type (0xDE) — the codec rejects the
    # first octet, the listener fails this connection closed.
    var garbage = List[UInt8]()
    garbage.append(0xDE)
    garbage.append(0xAD)
    garbage.append(0xBE)
    garbage.append(0xEF)
    _ = conn.send_bytes(garbage^)
    var rc = listener.serve_one_frame(slot)
    check(
        rc == SERVE_FAILED(),
        "malformed frame rejected gracefully (rc=" + String(rc) + ")",
    )
    conn.close()
    _probe_alive(listener)
    print("scenario 1 PASS: malformed frame")


# ── 2. oversized frame (declared body size far beyond the ceiling) ─────────

def test_oversized_frame(mut listener: AMQPListener) raises:
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    _do_handshake(conn, listener, slot)

    # type=3 BODY, channel=1, declared size=0x40000000 (1 GiB) > frame_max.
    var big = List[UInt8]()
    big.append(3)  # FRAME_BODY
    big.append(0)  # channel hi
    big.append(1)  # channel lo
    big.append(0x40)
    big.append(0x00)
    big.append(0x00)
    big.append(0x00)
    _ = conn.send_bytes(big^)
    var rc = listener.serve_one_frame(slot)
    check(
        rc == SERVE_FAILED(),
        "oversized declared frame rejected (rc=" + String(rc) + ")",
    )
    conn.close()
    _probe_alive(listener)
    print("scenario 2 PASS: oversized frame")


# ── 3. wrong channel (business frame on a not-open channel) ────────────────

def test_wrong_channel(mut listener: AMQPListener) raises:
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    _do_handshake(conn, listener, slot)
    var codec = AMQPFrameCodec()

    # Put channel 7 into the closed state, then send a business method on it:
    # the server must answer with a channel.close (20,40) channel error.
    _ = conn.send_bytes(_method_wire(UInt16(7), CHANNEL_OPEN(), List[UInt8]()))
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "wrong channel: channel.open dispatched",
    )
    check(
        _read_method_code(conn, codec) == _method_code(CHANNEL_OPEN_OK()),
        "wrong channel: open-ok received",
    )

    var cargs = List[UInt8]()
    write_u16(cargs, 200)  # reply-code
    write_short_string(cargs, "normal")  # reply-text
    write_u16(cargs, 0)  # failing class-id
    write_u16(cargs, 0)  # failing method-id
    _ = conn.send_bytes(_method_wire(UInt16(7), CHANNEL_CLOSE(), cargs^))
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "wrong channel: channel.close dispatched",
    )
    check(
        _read_method_code(conn, codec) == _method_code(CHANNEL_CLOSE_OK()),
        "wrong channel: close-ok received",
    )

    # queue.declare on the now-closed channel 7 → server channel error.
    var qargs = List[UInt8]()
    qargs.append(0)  # reserved-1 hi
    qargs.append(0)  # reserved-1 lo
    write_short_string(qargs, "nf.wrong-channel")
    qargs.append(0)  # bits: passive/durable/exclusive/auto-delete/no-wait
    write_u32(qargs, 0)  # empty arguments table
    _ = conn.send_bytes(_method_wire(UInt16(7), QUEUE_DECLARE(), qargs^))
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "wrong channel: queue.declare dispatched",
    )
    check(
        _read_method_code(conn, codec) == _method_code(CHANNEL_CLOSE()),
        "wrong channel: server replies with channel error (channel.close)",
    )
    conn.close()
    _probe_alive(listener)
    print("scenario 3 PASS: wrong channel")


# ── 4. premature close (connection.close right after handshake) ────────────

def test_premature_close(mut listener: AMQPListener) raises:
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    _do_handshake(conn, listener, slot)
    var codec = AMQPFrameCodec()

    var cargs = List[UInt8]()
    write_u16(cargs, 200)  # reply-code
    write_short_string(cargs, "premature close")  # reply-text
    write_u16(cargs, 0)  # failing class-id
    write_u16(cargs, 0)  # failing method-id
    _ = conn.send_bytes(_method_wire(UInt16(0), CONNECTION_CLOSE(), cargs^))
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "premature close: connection.close dispatched",
    )
    check(
        _read_method_code(conn, codec) == _method_code(CONNECTION_CLOSE_OK()),
        "premature close: close-ok received",
    )
    conn.close()
    _probe_alive(listener)
    print("scenario 4 PASS: premature close")


# ── 5. empty frame (type=0, size=0) ────────────────────────────────────────

def test_empty_frame(mut listener: AMQPListener) raises:
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    _do_handshake(conn, listener, slot)

    # type=0 is not a legal AMQP frame type — the codec rejects it immediately.
    var empty = List[UInt8]()
    empty.append(0)  # type = 0 (illegal)
    empty.append(0)  # channel hi
    empty.append(0)  # channel lo
    empty.append(0)  # size byte 3
    empty.append(0)  # size byte 2
    empty.append(0)  # size byte 1
    empty.append(0)  # size byte 0
    empty.append(0xCE)  # frame-end
    _ = conn.send_bytes(empty^)
    var rc = listener.serve_one_frame(slot)
    check(
        rc == SERVE_FAILED() or rc == SERVE_CLOSED(),
        "empty/type-0 frame handled without crash (rc=" + String(rc) + ")",
    )
    conn.close()
    _probe_alive(listener)
    print("scenario 5 PASS: empty frame")


# ── 6. truncated frame (partial frame, then close) ─────────────────────────

def test_truncated_frame(mut listener: AMQPListener) raises:
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    _do_handshake(conn, listener, slot)

    # Only the first 3 octets of a method frame, then abort.
    var partial = List[UInt8]()
    partial.append(1)  # FRAME_METHOD
    partial.append(0)  # channel hi
    partial.append(1)  # channel lo
    _ = conn.send_bytes(partial^)
    conn.close()

    var rc1 = listener.serve_one_frame(slot)
    check(
        rc1 == SERVE_PARTIAL() or rc1 == SERVE_CLOSED() or rc1 == SERVE_FAILED(),
        "truncated frame: partial tolerated (rc=" + String(rc1) + ")",
    )
    # Whatever the first step returned, a later step observes EOF/teardown.
    var rc2 = listener.serve_one_frame(slot)
    check(
        rc2 == SERVE_CLOSED() or rc2 == SERVE_FAILED(),
        "truncated frame: teardown without crash (rc=" + String(rc2) + ")",
    )
    _probe_alive(listener)
    print("scenario 6 PASS: truncated frame")


# ── 7. header-only then disconnect ─────────────────────────────────────────

def test_header_then_disconnect(mut listener: AMQPListener) raises:
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()

    # Send only the protocol header, then drop the socket with no frames.
    _ = conn.send_bytes(_protocol_header())
    conn.close()

    var rc1 = listener.serve_one_frame(slot)
    check(
        rc1 == SERVE_DISPATCHED() or rc1 == SERVE_CLOSED() or rc1 == SERVE_FAILED(),
        "header-only: first step handled (rc=" + String(rc1) + ")",
    )
    # Drain to teardown; serve_one_frame never raises.
    var rc2 = listener.serve_one_frame(slot)
    check(
        rc2 == SERVE_CLOSED() or rc2 == SERVE_FAILED() or rc2 == SERVE_DISPATCHED(),
        "header-only: teardown handled (rc=" + String(rc2) + ")",
    )
    _probe_alive(listener)
    print("scenario 7 PASS: header-only then disconnect")


# ── 8. reconnect after failure ─────────────────────────────────────────────

def test_reconnect_after_failure(mut listener: AMQPListener) raises:
    # Cause a failure on one connection...
    var bad = TCPConnection.connect("127.0.0.1", listener.port())
    var bad_slot = listener.accept_one()
    _ = bad.send_bytes(_protocol_header())
    check(
        listener.serve_one_frame(bad_slot) == SERVE_DISPATCHED(),
        "reconnect: header served",
    )
    var garbage = List[UInt8]()
    garbage.append(0xDE)
    garbage.append(0xAD)
    _ = bad.send_bytes(garbage^)
    check(
        listener.serve_one_frame(bad_slot) == SERVE_FAILED(),
        "reconnect: failure induced",
    )
    bad.close()

    # ...then a fresh connection must still complete a full handshake.
    var good = TCPConnection.connect("127.0.0.1", listener.port())
    var good_slot = listener.accept_one()
    check(good_slot >= 0, "reconnect: fresh accept succeeds")
    _do_handshake(good, listener, good_slot)
    good.close()
    check(
        listener.serve_one_frame(good_slot) == SERVE_CLOSED(),
        "reconnect: fresh connection works after failure",
    )
    print("scenario 8 PASS: reconnect after failure")


# ── main ───────────────────────────────────────────────────────────────────

def main() raises:
    var listener = _make_listener()
    check(listener.start(), "listener started")
    check(listener.port() > 0, "kernel assigned an ephemeral port")

    test_malformed_frame(listener)
    test_oversized_frame(listener)
    test_wrong_channel(listener)
    test_premature_close(listener)
    test_empty_frame(listener)
    test_truncated_frame(listener)
    test_header_then_disconnect(listener)
    test_reconnect_after_failure(listener)

    # Final broker-alive proof after all hostile input.
    _probe_alive(listener)
    check(listener.health() == "ok", "broker health ok after all scenarios")
    listener.stop()
    print("NETWORK_FAILURE_TEST=PASS")
