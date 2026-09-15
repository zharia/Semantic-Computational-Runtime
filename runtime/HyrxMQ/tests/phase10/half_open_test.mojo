# Phase 10 — Half-open / wedged-connection resilience tests.
#
# Proves the broker's event-driven serving contract keeps serving new
# connections while a peer is HALF-OPEN: the socket stays established but the
# peer never completes (or never sends) the bytes an AMQP step is waiting for.
# A half-open peer must be per-connection damage only — it can never park the
# broker or starve another connection.
#
# One AMQPListener is started on an ephemeral port (port=0); each scenario
# drives it over a REAL TCPConnection with raw bytes. After every scenario a
# fresh connection completes a FULL handshake (protocol header -> start-ok ->
# tune-ok -> open) to prove the broker is still alive (broker-alive invariant).
#
# Mojo 1.0.0: `assert` is inert, so every assertion goes through
# `hyrx.testing.check` (raises on failure). Each scenario is a bounded step
# sequence; the only delay is a short busy-wait used to dribble header octets,
# so the whole test completes well under 30 s.

from std.collections import List
from std.ffi import c_int, c_uint, external_call
from std.sys.info import CompilationTarget
from std.time import monotonic

from hyrx.transport.tcp import TCPConnection
from hyrx.amqp.frame_codec import AMQPFrameCodec
from hyrx.amqp.constants import (
    CONNECTION_START,
    CONNECTION_START_OK,
    CONNECTION_TUNE,
    CONNECTION_TUNE_OK,
    CONNECTION_OPEN,
    CONNECTION_OPEN_OK,
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


# ── wire helpers (AMQP 0-9-1) ────────────────────────────────────────────

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


def _method_wire(chan: UInt16, mid: MethodID, var args: List[UInt8]) -> List[UInt8]:
    return AMQPFrameCodec.encode_method_frame(chan, mid.class_id, mid.method_id, args^)


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


def _read_method_code(mut conn: TCPConnection, mut codec: AMQPFrameCodec) raises -> Int:
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


# ── full handshake helpers (header → start-ok → tune-ok → open) ────────────

def _finish_after_header(
    mut conn: TCPConnection,
    mut listener: AMQPListener,
    slot: Int,
    mut codec: AMQPFrameCodec,
) raises:
    """Complete negotiation once connection.start has been consumed.

    The protocol header has already been served and the server's start frame
    read into ``codec`` by the caller."""
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
    _finish_after_header(conn, listener, slot, codec)


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


# ─ timing + socket-option plumbing ────────────────────────────────────────

def _sleep_ms(ms: Int):
    """Bounded busy-wait so a dribbled header arrives in separate segments."""
    var start = Int(monotonic() // 1_000_000)
    while Int(monotonic() // 1_000_000) - start < ms:
        _ = start


def _sol_socket() -> Int:
    if CompilationTarget.is_linux():
        return 1
    return 0xFFFF


def _so_linger() -> Int:
    if CompilationTarget.is_linux():
        return 13
    return 0x0080


def _set_so_linger_zero(fd: Int) raises:
    """SO_LINGER {l_onoff=1, l_linger=0}: close() sends RST, no FIN/drain.

    The 8-byte struct linger is two little-endian int32 fields; on a
    little-endian host bytes [0:4]=1 (onoff), [4:8]=0 (linger seconds)."""
    var linger = List[UInt8](unsafe_uninit_length=8)
    for i in range(8):
        linger[i] = 0
    linger[0] = 1
    var rc = external_call["setsockopt", c_int](
        c_int(fd),
        c_int(_sol_socket()),
        c_int(_so_linger()),
        linger.unsafe_ptr().unsafe_bitcast[NoneType](),
        c_uint(8),
    )
    check(rc == 0, "half-open: SO_LINGER setsockopt succeeded")


# ─ 1. header-then-silence ─────────────────────────────────────────────────

def test_header_then_silence(mut listener: AMQPListener) raises:
    # Conn A sends the protocol header and then goes silent — the socket is
    # fully open with a completed header stage on the broker side.
    var idle = TCPConnection.connect("127.0.0.1", listener.port())
    var idle_slot = listener.accept_one()
    check(idle_slot >= 0, "header-then-silence: idle accept succeeds")
    _ = idle.send_bytes(_protocol_header())
    check(
        listener.serve_one_frame(idle_slot) == SERVE_DISPATCHED(),
        "header-then-silence: header served (start sent)",
    )
    var idle_codec = AMQPFrameCodec()
    var first = idle.recv_exact(1)
    check(first[0] == UInt8(0x01), "header-then-silence: start is METHOD frame")
    idle_codec.feed_bytes(first^)
    check(
        _read_method_code(idle, idle_codec) == _method_code(CONNECTION_START()),
        "header-then-silence: connection.start received",
    )

    # While A is wedged, B must still complete a full handshake.
    var live = TCPConnection.connect("127.0.0.1", listener.port())
    var live_slot = listener.accept_one()
    check(live_slot >= 0, "header-then-silence: live accept succeeds")
    _do_handshake(live, listener, live_slot)
    live.close()
    check(
        listener.serve_one_frame(live_slot) == SERVE_CLOSED(),
        "header-then-silence: live connection closed cleanly",
    )
    check(listener.health() == "ok", "header-then-silence: broker health ok")

    idle.close()
    _probe_alive(listener)
    print("scenario 1 PASS: header-then-silence does not block others")


# ── 2. partial frame then silence ──────────────────────────────────────────

def test_partial_frame_then_silence(mut listener: AMQPListener) raises:
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    check(slot >= 0, "partial-frame: accept succeeds")
    _do_handshake(conn, listener, slot)

    # Declare a 64-byte METHOD payload but send only the 7-octet frame
    # header, then stop: the codec holds an incomplete frame.
    var f = List[UInt8]()
    f.append(1)  # FRAME_METHOD
    f.append(0)  # channel hi
    f.append(1)  # channel lo
    f.append(0)  # size byte 3
    f.append(0)  # size byte 2
    f.append(0)  # size byte 1
    f.append(64)  # size byte 0 → declares 64 body bytes
    _ = conn.send_bytes(f^)
    var rc = listener.serve_one_frame(slot)
    check(
        rc == SERVE_PARTIAL(),
        "partial-frame: codec awaits declared body (rc=" + String(rc) + ")",
    )

    # The wedged connection must not prevent a fresh handshake.
    var live = TCPConnection.connect("127.0.0.1", listener.port())
    var live_slot = listener.accept_one()
    check(live_slot >= 0, "partial-frame: live accept succeeds")
    _do_handshake(live, listener, live_slot)
    live.close()
    check(
        listener.serve_one_frame(live_slot) == SERVE_CLOSED(),
        "partial-frame: live connection closed cleanly",
    )

    conn.close()
    _probe_alive(listener)
    print("scenario 2 PASS: partial-frame-then-silence does not block others")


# ── 3. slow-drip protocol header ───────────────────────────────────────────

def test_slow_drip_header(mut listener: AMQPListener) raises:
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    check(slot >= 0, "slow-drip: accept succeeds")

    # Send the 8-octet header one byte at a time, pausing between writes so
    # the bytes arrive as separate segments. The broker's header stage must
    # accumulate them across reads and still complete the handshake.
    var hdr = _protocol_header()
    for i in range(8):
        var one = List[UInt8]()
        one.append(hdr[i])
        _ = conn.send_bytes(one^)
        _sleep_ms(5)
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "slow-drip: dribbled header accepted",
    )
    var codec = AMQPFrameCodec()
    var first = conn.recv_exact(1)
    check(first[0] == UInt8(0x01), "slow-drip: start is METHOD frame")
    codec.feed_bytes(first^)
    check(
        _read_method_code(conn, codec) == _method_code(CONNECTION_START()),
        "slow-drip: connection.start received",
    )
    _finish_after_header(conn, listener, slot, codec)
    conn.close()
    check(
        listener.serve_one_frame(slot) == SERVE_CLOSED(),
        "slow-drip: connection closed cleanly",
    )
    _probe_alive(listener)
    print("scenario 3 PASS: slow-drip header handshake completes")


# ─ 4. half-open via SO_LINGER / abort ─────────────────────────────────────

def test_abort_via_linger(mut listener: AMQPListener) raises:
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    check(slot >= 0, "abort: accept succeeds")
    _do_handshake(conn, listener, slot)

    # SO_LINGER(0): close() emits RST instead of a graceful FIN. The broker
    # must absorb the reset on this slot and keep serving.
    _set_so_linger_zero(conn.poll_fd())
    conn.close()
    var rc = listener.serve_one_frame(slot)
    check(
        rc == SERVE_CLOSED() or rc == SERVE_FAILED(),
        "abort: RST observed without crash (rc=" + String(rc) + ")",
    )
    check(listener.health() == "ok", "abort: broker health ok")
    _probe_alive(listener)
    print("scenario 4 PASS: half-open abort via SO_LINGER survives")


# ─ 5. no-data-after-accept flood ──────────────────────────────────────────

def test_no_data_flood(mut listener: AMQPListener) raises:
    # K clients connect and send NOTHING. The broker must accept them all and
    # remain responsive to a fresh, complete handshake.
    var k = 32
    var conns = List[TCPConnection]()
    for _ in range(k):
        conns.append(TCPConnection.connect("127.0.0.1", listener.port()))
    for i in range(k):
        var s = listener.accept_one()
        check(s >= 0, "no-data flood: accept #" + String(i) + " succeeds")
    check(
        listener.active_connections() >= k,
        "no-data flood: all K idle connections registered",
    )

    var live = TCPConnection.connect("127.0.0.1", listener.port())
    var live_slot = listener.accept_one()
    check(live_slot >= 0, "no-data flood: live accept succeeds")
    _do_handshake(live, listener, live_slot)
    check(listener.health() == "ok", "no-data flood: broker health ok")
    live.close()
    check(
        listener.serve_one_frame(live_slot) == SERVE_CLOSED(),
        "no-data flood: live connection closed cleanly",
    )

    for i in range(k):
        conns[i].close()
    print("scenario 5 PASS: K=32 silent connections do not wedge the broker")


# ── main ───────────────────────────────────────────────────────────────────

def main() raises:
    var listener = _make_listener()
    check(listener.start(), "listener started")
    check(listener.port() > 0, "kernel assigned an ephemeral port")

    test_header_then_silence(listener)
    test_partial_frame_then_silence(listener)
    test_slow_drip_header(listener)
    test_abort_via_linger(listener)
    test_no_data_flood(listener)

    # Final broker-alive proof after all hostile half-open input.
    _probe_alive(listener)
    check(listener.health() == "ok", "broker health ok after all scenarios")
    listener.stop()
    print("HALF_OPEN_TEST=PASS")