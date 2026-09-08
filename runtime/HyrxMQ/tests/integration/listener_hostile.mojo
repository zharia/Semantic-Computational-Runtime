# Listener containment of hostile connections (audit §13/§29).

# Drives the PRODUCTION path — socket bytes -> AMQPFrameCodec -> AMQPListener —
# with input that used to be able to kill the broker:
#   A  an invalid frame-type octet (codec raise),
#   B  basic.consume on an UNDECLARED queue (router raise: the reachable crash),
#   C  a header declaring a ~4 GiB frame (oversized-frame raise),
#   D  more connections than the configured `max_connections`.
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
    MethodID,
)

from hyrxmq.amqp_service import write_short_string
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


def open_args() -> List[UInt8]:
    var args = List[UInt8]()
    write_short_string(args, "/")
    args.append(0)
    args.append(0)
    args.append(0)
    args.append(0)
    return args^


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
    """A well-behaved client still completes a handshake on this listener."""
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()
    check(slot >= 0, "a fresh client is accepted after a hostile one")
    conn.send_bytes(method_wire(UInt16(0), CONNECTION_OPEN(), open_args()^))
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "good client frame dispatched (broker still serving)"
    )
    var codec = AMQPFrameCodec()
    check(
        read_method_code(conn, codec) == method_code(CONNECTION_OPEN_OK()),
        "broker answered connection.open-ok"
    )
    conn.close()
    check(listener.serve_one_frame(slot) == SERVE_CLOSED(), "EOF observed")


# ---- E: a LEGAL frame still flows through a small configured frame_max ----
# The ceiling is enforced, not the read path: the listener must read in pieces
# the codec can hold, so a 1 KiB frame_max still serves a 900-byte body frame.

def case_small_frame_max_still_serves() raises:
    var listener = make_listener(1024, 1024)
    check(listener.start(), "listener E started with frame_max=1024")
    var conn = TCPConnection.connect("127.0.0.1", listener.port())
    var slot = listener.accept_one()

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

    c1.send_bytes(method_wire(UInt16(0), CONNECTION_OPEN(), open_args()^))
    check(
        listener.serve_one_frame(slot) == SERVE_DISPATCHED(),
        "the connection inside the limit is served normally"
    )
    c1.close()
    listener.stop()


def main() raises:
    case_invalid_frame_type()
    case_undeclared_queue_consume()
    case_oversized_declared()
    case_max_connections_enforced()
    case_small_frame_max_still_serves()
    print("LISTENER_HOSTILE_PASS")
