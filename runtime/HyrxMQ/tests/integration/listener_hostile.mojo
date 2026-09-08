# Listener containment of hostile connections (audit §13/§29), post-negotiation.

# Drives the PRODUCTION path — socket bytes -> protocol-header gate ->
# AMQPFrameCodec -> AMQPListener — with input that used to be able to kill the
# broker. Every hostile case now FIRST completes the real handshake
# (header/start/start-ok/tune/tune-ok/open/open-ok) so the offending payload is
# a genuine post-open frame, then asserts:
#   A  an invalid frame-type octet (codec raise),
#   B  basic.consume on an UNDECLARED queue (router raise: the reachable crash),
#   C  a header declaring a ~4 GiB frame (oversized-frame raise),
#   D  more connections than the configured `max_connections`,
#   E  a LEGAL frame still flows through a small configured frame_max,
#   F  a WRONG protocol header fails the connection closed (not the broker).
# Every case asserts: the failing step RETURNS control (SERVE_FAILED), the
# offending connection is closed, the process is alive, and the SAME listener
# goes on serving a well-behaved client.

# Single-threaded step API (as in broker_tcp_e2e.mojo): no unbounded blocking.
# Success prints LISTENER_HOSTILE_PASS.

from std.collections import List

from hyrx.transport.tcp import TCPConnection

from hyrx.amqp.frame_codec import AMQPFrameCodec, DEFAULT_MAX_FRAME_SIZE
from hyrx.amqp.constants import (
    BASIC_CONSUME,
    CONNECTION_OPEN,
    CONNECTION_OPEN_OK,
    CONNECTION_START,
    CONNECTION_START_OK,
    CONNECTION_TUNE,
    CONNECTION_TUNE_OK,
    MethodID,
)

from hyrxmq.amqp_service import write_short_string, write_u16, write_u32
from hyrxmq.config import HyrxMQConfig
from hyrxmq.listener import (
    AMQPListener,
    SERVE_CLOSED,
    SERVE_DISPATCHED,
    SERVE_FAILED,
)

from hyrx.testing import check


def method_code(mid: MethodID) -> Int:
    """A MethodID as a single comparable Int (class*1000 + method)."""
    return Int(mid.class_id) * 1000 + Int(mid.method_id)


def bytes_of(s: String) -> List[UInt8]:
    var out = List[UInt8]()
    var b = s.as_bytes()
    for i in range(len(b)):
        out.append(b[i])
    return out^


def hdr(mut b: List[UInt8], t: UInt8, ch: UInt16, size: UInt32):
    """Append a 7-byte AMQP frame header."""
    b.append(t)
    b.append(UInt8((ch >> 8) & 0xFF))
    b.append(UInt8(ch & 0xFF))
    b.append(UInt8((size >> 24) & 0xFF))
    b.append(UInt8((size >> 16) & 0xFF))
    b.append(UInt8((size >> 8) & 0xFF))
    b.append(UInt8(size & 0xFF))


def method_wire(
    chan: UInt16, mid: MethodID, var args: List[UInt8]
) -> List[UInt8]:
    return AMQPFrameCodec.encode_method_frame(
        chan, mid.class_id, mid.method_id, args^
    )


# ---- handshake client payloads (exact amqp0-9-1 field layouts) ----

def protocol_header() -> List[UInt8]:
    var h = List[UInt8]()
    for b in bytes_of("AMQP"):
        h.append(b)
    h.append(0)
    h.append(0)
    h.append(0x09)
    h.append(0x01)
    return h^


def start_ok_wire() -> List[UInt8]:
    """connection.start-ok: empty client table + PLAIN + SASL response + locale."""
    var args = List[UInt8]()
    write_u32(args, 0)  # client-properties: empty table
    write_short_string(args, "PLAIN")  # mechanism (shortstr)
    var resp = List[UInt8]()  # SASL PLAIN: authzid NUL authcid NUL passwd
    resp.append(0)
    for b in bytes_of("admin"):
        resp.append(b)
    resp.append(0)
    for b in bytes_of("password"):
        resp.append(b)
    write_u32(args, UInt32(len(resp)))  # response (longstr) length
    for b in resp:
        args.append(b)
    write_short_string(args, "en_US")  # locale (shortstr)
    return method_wire(UInt16(0), CONNECTION_START_OK(), args^)


def tune_ok_wire() -> List[UInt8]:
    var args = List[UInt8]()
    write_u16(args, 2047)
    write_u32(args, UInt32(131072))
    write_u16(args, 0)
    return method_wire(UInt16(0), CONNECTION_TUNE_OK(), args^)


def open_args() -> List[UInt8]:
    var args = List[UInt8]()
    write_short_string(args, "/")
    args.append(0)
    args.append(0)
    args.append(0)
    args.append(0)
    return args^


# ---- socket frame reader ----

def sees_eof(mut conn: TCPConnection) -> Bool:
    """True when the peer is gone: a 0-byte read, or a read that errors out."""
    try:
        return len(conn.recv_bytes(64)) == 0
    except:
        return True


def read_method_code(
    mut conn: TCPConnection, mut codec: AMQPFrameCodec
) raises -> Int:
    """Next method frame off the socket as method_code(), or -1 on EOF."""
    var i = 0
    while i < 16:
        var f = codec.try_parse_frame()
        if f.__bool__():
            var p = f.value().payload_copy()
            if len(p) < 4:
                raise "expected a method frame payload"
            var cid = (UInt32(p[0]) << 8) | UInt32(p[1])
            var mid = (UInt32(p[2]) << 8) | UInt32(p[3])
            return Int(cid) * 1000 + Int(mid)
        var chunk = conn.recv_bytes(4096)
        if len(chunk) == 0:
            return -1
        codec.feed_bytes(chunk^)
        i += 1
    raise "read_method_code: no frame after 16 reads (deadlock guard)"


# ---- the real handshake, performed before every hostile payload ----

def do_handshake(
    mut conn: TCPConnection,
    mut codec: AMQPFrameCodec,
    mut listener: AMQPListener,
    slot: Int,
) raises:
    """header -> start -> start-ok -> tune -> tune-ok -> open -> open-ok."""
    conn.send_bytes(protocol_header()^)
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "protocol header accepted (start sent)",
    )
    _ = conn.recv_exact(8)  # server echoes the same 8 octets (not a frame)
    check(
        read_method_code(conn, codec) == method_code(CONNECTION_START()),
        "connection.start (10,10) received",
    )

    conn.send_bytes(start_ok_wire()^)
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "start-ok dispatched",
    )
    check(
        read_method_code(conn, codec) == method_code(CONNECTION_TUNE()),
        "connection.tune (10,30) received",
    )

    conn.send_bytes(tune_ok_wire()^)
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "tune-ok dispatched (no reply)",
    )
    conn.send_bytes(
        method_wire(UInt16(0), CONNECTION_OPEN(), open_args()^)
    )
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "connection.open dispatched",
    )
    check(
        read_method_code(conn, codec) == method_code(CONNECTION_OPEN_OK()),
        "connection.open-ok (10,41) received",
    )


def make_listener(
    max_conns: Int, frame_max: Int = DEFAULT_MAX_FRAME_SIZE()
) -> AMQPListener:
    var cfg = HyrxMQConfig()
    cfg.listen_host = "127.0.0.1"
    cfg.port = 0
    cfg.max_connections = max_conns
    cfg.frame_max = frame_max
    return AMQPListener(cfg^)


# ---- the containment proof, shared by every case ---------------------
# Reaching the line AFTER serve_one_frame() is the assertion that the broker
# survived: serve_one_frame() has no `raises`, so any codec/handler/socket
# error on that connection is absorbed and returned as SERVE_FAILED.

def probe_good_client(mut listener: AMQPListener) raises:
    """A well-behaved client still completes a full handshake on this listener."""
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    check(slot >= 0, "a fresh client is accepted after a hostile one")
    var codec = AMQPFrameCodec()
    do_handshake(conn, codec, listener, slot)
    conn.close()
    check(listener.serve_one_frame(slot) == SERVE_CLOSED(), "EOF observed")


# ---- F: a WRONG protocol header fails closed -------------------------

def case_bad_protocol_header() raises:
    var listener = make_listener(1024)
    check(listener.start(), "listener F started")
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()

    var bad = List[UInt8]()
    for b in bytes_of("AMQP"):
        bad.append(b)
    bad.append(0)
    bad.append(0)
    bad.append(0x09)
    bad.append(0x02)  # wrong revision octet
    conn.send_bytes(bad^)
    check(
        listener.serve_one_frame(slot) == SERVE_FAILED(),
        "a bad protocol header fails the connection, not the broker",
    )
    check(sees_eof(conn), "the bad-header client sees EOF")
    probe_good_client(listener)
    listener.stop()


# ---- E: a LEGAL frame still flows through a small configured frame_max ----

def case_small_frame_max_still_serves() raises:
    var listener = make_listener(1024, 1024)
    check(listener.start(), "listener E started with frame_max=1024")
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    var codec = AMQPFrameCodec()
    do_handshake(conn, codec, listener, slot)

    var body = List[UInt8]()
    for _ in range(900):
        body.append(0x41)
    conn.send_bytes(AMQPFrameCodec.encode_body_frame(UInt16(1), body^))
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "a legal frame under a small ceiling is served, not rejected"
    )

    # And one byte over that ceiling is refused on the same listener.
    var over = List[UInt8]()
    hdr(over, UInt8(3), UInt16(1), UInt32(1025))
    over.resize(len(over) + 1025, 0x42)
    over.append(0xCE)
    conn.send_bytes(over^)
    check(
        listener.serve_one_frame(slot) == SERVE_FAILED(),
        "1025 > frame_max=1024 is refused on the wire path"
    )
    conn.close()
    probe_good_client(listener)
    listener.stop()


# ---- A: invalid frame type -------------------------------------------

def case_invalid_frame_type() raises:
    var listener = make_listener(1024)
    check(listener.start(), "listener A started")
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    var codec = AMQPFrameCodec()
    do_handshake(conn, codec, listener, slot)

    var bad = List[UInt8]()
    hdr(bad, UInt8(0xAA), UInt16(1), UInt32(4))
    bad.resize(len(bad) + 4, 0x41)
    bad.append(0xCE)
    conn.send_bytes(bad^)
    check(
        listener.serve_one_frame(slot) == SERVE_FAILED(),
        "invalid frame_type fails the connection, not the broker"
    )
    check(sees_eof(conn), "hostile client sees EOF after the rejection")
    probe_good_client(listener)
    listener.stop()


# ---- B: basic.consume on an undeclared queue -------------------------

def case_undeclared_queue_consume() raises:
    var listener = make_listener(1024)
    check(listener.start(), "listener B started")
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    var codec = AMQPFrameCodec()
    do_handshake(conn, codec, listener, slot)

    var cargs = List[UInt8]()
    write_short_string(cargs, "no.such.queue")
    cargs.append(0)
    conn.send_bytes(method_wire(UInt16(1), BASIC_CONSUME(), cargs^))
    check(
        listener.serve_one_frame(slot) == SERVE_FAILED(),
        "register_consumer raise fails the connection only"
    )
    check(sees_eof(conn), "the raising connection is closed")
    probe_good_client(listener)
    listener.stop()


# ---- C: header declaring a ~4 GiB frame ------------------------------

def case_oversized_declared() raises:
    var listener = make_listener(1024)
    check(listener.start(), "listener C started")
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    var codec = AMQPFrameCodec()
    do_handshake(conn, codec, listener, slot)

    var huge = List[UInt8]()
    hdr(huge, UInt8(3), UInt16(1), UInt32(0xFFFFFFFF))
    conn.send_bytes(huge^)
    check(
        listener.serve_one_frame(slot) == SERVE_FAILED(),
        "oversized declared size fails the connection; no huge allocation"
    )
    check(
        listener.serve_one_frame(slot) == SERVE_CLOSED(),
        "the failed slot is closed, not re-served"
    )
    check(sees_eof(conn), "the oversized-frame client is disconnected")
    probe_good_client(listener)
    listener.stop()


# ---- D: max_connections ceiling --------------------------------------

def case_max_connections_enforced() raises:
    var listener = make_listener(1, DEFAULT_MAX_FRAME_SIZE())
    check(listener.start(), "listener D started with max_connections=1")
    var c1 = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    check(slot >= 0, "first connection admitted")
    check(listener.active_connections() == 1, "one active connection")

    # A second client is accepted by the kernel and dropped by the listener.
    var c2 = TCPConnection.connect("127.0.0.1", listener.port())
    check(listener.accept_one() < 0, "second connection is refused at the ceiling")
    check(listener.refused_connections() == 1, "refusal is counted")
    check(sees_eof(c2), "refused client sees EOF immediately")
    check(listener.active_connections() == 1, "the admitted connection survives")

    # The admitted connection completes a full handshake.
    var codec = AMQPFrameCodec()
    do_handshake(c1, codec, listener, slot)
    c1.close()
    listener.stop()


def main() raises:
    case_bad_protocol_header()
    case_invalid_frame_type()
    case_undeclared_queue_consume()
    case_oversized_declared()
    case_max_connections_enforced()
    case_small_frame_max_still_serves()
    print("LISTENER_HOSTILE_PASS")
