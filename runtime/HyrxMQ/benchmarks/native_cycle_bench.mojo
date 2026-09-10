# Native closed-loop throughput bench — publish -> basic.get over real AMQP 0-9-1.

# Measures the broker's message-path ceiling from a compiled Mojo client, so
# the ~450us/msg pika/python client cost (benchmarks/perf/harness.py) is out
# of the measurement. One process, one fresh connection per payload size; the
# broker serves one connection at a time, so the previous connection is closed
# before the next size opens its own.

# Every byte layout here is copied from the proven integration tests:
# - tests/integration/broker_tcp_e2e.mojo  (handshake args, method-arg encoding,
#   the frame-consuming client wrapper, expect_body §2.3.5 reassembly+compare)
# - tests/integration/amqp_over_tcp.mojo::client_wire  (publish: METHOD + one
#   HEADER + BODY frames; bodies here split at 131064 = frame_max(131072) - 8)

# The broker must already be listening, e.g.:
#   mojo run -I src -I vendor/flare src/hyrxmq/main_listen.mojo 5673 &
#   HYRXMQ_UDS_PATH=@hyrxmq_bench_abstract mojo run -I src -I vendor/flare \
#     src/hyrxmq/main_listen.mojo &
# Run — TCP mode (<port> required, byte-identical to the original):
#   mojo run -I src -I vendor/flare benchmarks/native_cycle_bench.mojo <port> \
#     [--sizes 64,256,1024,4096,16384,65536,131072] [--count N] [--no-echo] \
#     [--batch K]
# Run — UDS mode (--uds present, <port> optional and ignored):
#   mojo run -I src -I vendor/flare benchmarks/native_cycle_bench.mojo \
#     --uds @hyrxmq_bench_abstract [--sizes ...] [--count N] [--no-echo] \
#     [--batch K]
# --batch K: each closed-loop cycle publishes K messages (K method+header+body
# frame groups, then K basic_get frames, one send — same wire bytes as K=1
# repeated, so batch=1 is byte-identical to the original behavior). --count
# stays MESSAGE-count: cycles = max(1, count / batch); a get-empty reply
# counts 0 delivered for that get.
# --uds accepts a filesystem socket path (/tmp/hyrxmq.sock) or a Linux
# abstract-namespace name (@name). Both transports drive the SAME measured
# pipeline: the client wrapper is parameterized on the AMQPConn trait, exactly
# like the broker's AMQPConnServing, so nothing in the loop is transport code.
# --no-echo: skip consuming/asserting the 8-octet header echo. HyrxMQ echoes
# it over BOTH transports (broker_tcp_e2e, broker_uds_e2e); RabbitMQ does not,
# so against RabbitMQ the default fails at "server echoed the 8-octet header".

from std.time import perf_counter_ns
from std.collections import List
from std.sys import argv

from hyrx.transport.tcp import TCPConnection
from hyrx.transport.uds import UDSConnection
from hyrx.transport.transport import AMQPConn

from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec
from hyrx.amqp.constants import (
    BASIC_GET,
    BASIC_GET_OK,
    BASIC_PUBLISH,
    CHANNEL_OPEN,
    CHANNEL_OPEN_OK,
    CONNECTION_START,
    CONNECTION_START_OK,
    CONNECTION_TUNE,
    CONNECTION_TUNE_OK,
    CONNECTION_OPEN,
    CONNECTION_OPEN_OK,
    EXCHANGE_DECLARE,
    EXCHANGE_DECLARE_OK,
    MethodID,
    QUEUE_BIND,
    QUEUE_BIND_OK,
    QUEUE_DECLARE,
    QUEUE_DECLARE_OK,
)
from hyrx.amqp.field_table import FieldTable

from hyrxmq.amqp_service import (
    write_short_string,
    write_table,
    write_u16,
    write_u32,
)

from hyrx.testing import check


# Largest BODY-frame payload we emit: frame_max (131072, as in broker_tcp_e2e's
# tune-ok and HyrxMQConfig.frame_max) minus the 8-octet frame overhead. A
# 131072-byte body therefore splits into 131064 + 8 (two frames), matching the
# server-side outbound chunking in emit_message_frames.
def MAX_BODY_CHUNK() -> Int:
    return 131064


# ---- byte helpers copied from broker_tcp_e2e / amqp_over_tcp ----

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


def reserved_short(mut out: List[UInt8]):
    out.append(UInt8(0))
    out.append(UInt8(0))


def append_all(mut dst: List[UInt8], var src: List[UInt8]):
    for i in range(len(src)):
        dst.append(src[i])


def request(
    chan: UInt16, mid: MethodID, var args: List[UInt8]
) -> List[UInt8]:
    return AMQPFrameCodec.encode_method_frame(
        chan, mid.class_id, mid.method_id, args^
    )


def protocol_header() -> List[UInt8]:
    """The 8-octet AMQP 0-9-1 header (41 4D 51 50 00 00 09 01)."""
    var h = List[UInt8]()
    for b in bytes_of("AMQP"):
        h.append(b)
    h.append(0)
    h.append(0)
    h.append(0x09)
    h.append(0x01)
    return h^


def start_ok_args() -> List[UInt8]:
    """client-properties(empty) + mechanism(PLAIN) + response(SASL PLAIN) + locale."""
    var args = List[UInt8]()
    write_u32(args, 0)  # empty client-properties table
    write_short_string(args, "PLAIN")
    var resp = List[UInt8]()
    resp.append(0)  # authzid NUL
    for b in bytes_of("admin"):
        resp.append(b)
    resp.append(0)  # authcid/passwd separator
    for b in bytes_of("password"):
        resp.append(b)
    write_u32(args, UInt32(len(resp)))  # response is a longstr
    for b in resp:
        args.append(b)
    write_short_string(args, "en_US")
    return args^


def tune_ok_args() -> List[UInt8]:
    """tune-ok: channel-max(short) + frame-max(long) + heartbeat(short)."""
    var args = List[UInt8]()
    write_u16(args, 2047)
    write_u32(args, UInt32(131072))
    write_u16(args, 0)
    return args^


def open_args() -> List[UInt8]:
    var args = List[UInt8]()
    write_short_string(args, "/")
    write_short_string(args, "")
    args.append(0)  # reserved-2 bit
    return args^


# ---- connection wrapper (ClientStream from broker_tcp_e2e, AMQPConn-typed) ----

struct Conn[C: AMQPConn]:
    """Socket client with an incremental frame decoder (bounded reads).

    The connection is held through the transport contract (`C: AMQPConn`), the
    same bound the broker's `AMQPConnServing[Conn: AMQPConn]` uses, so
    TCPConnection and UDSConnection instantiate this wrapper with identical
    measured code (static dispatch, no virtual call in the timed loop)."""

    var conn: Self.C
    var codec: AMQPFrameCodec
    var last_payload: List[UInt8]

    def __init__(out self, var c: Self.C):
        self.conn = c^
        self.codec = AMQPFrameCodec()
        self.last_payload = List[UInt8]()

    def send(mut self, var wire: List[UInt8]) raises:
        var n = len(wire)
        var sent = self.conn.send_bytes(wire^)
        check(sent == n, "all client bytes written")

    def next_frame(mut self) raises -> AMQPFrame:
        """Parse the next frame of ANY type.

        Mirrors listener.mojo::_serve_step: `try_parse_frame()` runs on every
        iteration (complete frames drain out of the backlog BEFORE any read),
        and each read is clamped to the room the codec can still hold, so a
        coalesced deliver + HEADER + BODY burst cannot push the backlog past
        the buffered-frame limit. The 64-iteration bound is only wall-clock
        deadlock protection; zero bytes read is EOF."""
        var i = 0
        while i < 64:
            var f = self.codec.try_parse_frame()
            if f.__bool__():
                return AMQPFrame(
                    f.value().frame_type,
                    f.value().channel,
                    f.value().payload_copy(),
                )
            # Read no more than the codec can still hold (listener.mojo:277-285):
            # an oversized read would reject a well-behaved peer.
            var want = 65536
            var room = (
                self.codec.frame_limit()
                + 8
                - self.codec.buffered_bytes()
            )
            if want > room:
                want = room
            var chunk = self.conn.recv_bytes(want)
            if len(chunk) == 0:
                raise "client: server closed before a frame arrived"
            self.codec.feed_bytes(chunk^)
            i += 1
        raise "client: no complete frame after 64 reads (deadlock guard)"

    def next_method(mut self) raises -> MethodID:
        """Parse the next frame and require it to be a METHOD frame."""
        var f = self.next_frame()
        check(f.frame_type == 1, "expected a METHOD frame")
        var p = f.payload_copy()
        check(len(p) >= 4, "method frame carries class+method")
        var mid = MethodID(
            (UInt16(p[0]) << 8) | UInt16(p[1]),
            (UInt16(p[2]) << 8) | UInt16(p[3]),
        )
        self.last_payload = p^
        return mid^

    def expect_body(mut self, want: List[UInt8], verify: Bool) raises:
        """Read the HEADER (+BODY frames) following a content method frame and
        assert the reassembled body length equals `want` (§2.3.5 layout check);
        `verify` additionally byte-compares the reassembled body."""
        var hf = self.next_frame()
        check(hf.frame_type == 2, "a content HEADER frame follows the method")
        var hp = hf.payload_copy()
        var hclass = (UInt16(hp[0]) << 8) | UInt16(hp[1])
        check(hclass == 60, "content header class-id is basic (60)")
        var w = (UInt16(hp[2]) << 8) | UInt16(hp[3])
        check(w == 0, "content header weight is reserved zero")
        var size = UInt64(0)
        for i in range(4, 12):
            size = (size << 8) | UInt64(hp[i])
        check(Int(size) == len(want), "declared body-size matches the payload")
        var got = List[UInt8]()
        while len(got) < Int(size):
            var bf = self.next_frame()
            check(bf.frame_type == 3, "a content BODY frame follows the header")
            var bp = bf.payload_copy()
            for i in range(len(bp)):
                got.append(bp[i])
        if verify:
            check_bytes(got, want, "delivered body bytes match the published body")

    def read_exact(mut self, n: Int) raises -> List[UInt8]:
        """Local copy of TCPConnection.recv_exact (tcp.mojo:135-150).

        `recv_exact` is NOT on the AMQPConn trait (only conn_id/recv_bytes/
        send_bytes/close are), so the exact-read loop lives here and goes
        through `recv_bytes` — identical semantics for both transports."""
        var out = List[UInt8]()
        while len(out) < n:
            var chunk = self.conn.recv_bytes(n - len(out))
            if len(chunk) == 0:
                raise (
                    "client: recv_exact EOF after "
                    + String(len(out))
                    + " of "
                    + String(n)
                    + " bytes"
                )
            for i in range(len(chunk)):
                out.append(chunk[i])
        return out^

    def close(mut self):
        self.conn.close()


# ---- per-connection setup ----

def do_handshake[C: AMQPConn](mut client: Conn[C], echo: Bool) raises:
    """header -> start -> start-ok -> tune -> tune-ok -> open -> open-ok.

    Same frame order as broker_tcp_e2e::do_handshake, but against the live
    broker process: every reply is consumed via next_method, no listener
    stepping. `echo` (the --no-echo flag, inverted) gates consuming and
    asserting the 8-octet header echo; RabbitMQ does not echo it."""
    var hdr = protocol_header()
    client.send(hdr.copy())
    if echo:
        var magic = client.read_exact(8)
        check_bytes(magic, hdr, "server echoed the 8-octet header")
    check(client.next_method() == CONNECTION_START(), "connection.start received")

    client.send(request(UInt16(0), CONNECTION_START_OK(), start_ok_args()^))
    check(client.next_method() == CONNECTION_TUNE(), "connection.tune received")

    client.send(request(UInt16(0), CONNECTION_TUNE_OK(), tune_ok_args()^))
    client.send(request(UInt16(0), CONNECTION_OPEN(), open_args()^))
    check(
        client.next_method() == CONNECTION_OPEN_OK(),
        "connection.open-ok received (handshake complete)",
    )


def open_channel[C: AMQPConn](mut client: Conn[C]) raises:
    """channel.open(1) -> channel.open-ok (args: reserved-1 shortstr)."""
    var cargs = List[UInt8]()
    write_short_string(cargs, "")
    client.send(request(UInt16(1), CHANNEL_OPEN(), cargs^))
    check(client.next_method() == CHANNEL_OPEN_OK(), "channel.open-ok received")


def setup_topology[C: AMQPConn](
    mut client: Conn[C], var ex: String, var q: String
) raises:
    """exchange.declare (direct, auto-delete) + queue.declare (auto-delete,
    x-expires 60000) + queue.bind, consuming every reply frame.

    Bit layout per amqp0-9-1.xml: exchange passive=1/durable=2/auto-delete=4/
    no-wait=8; queue passive=1/durable=2/exclusive=4/auto-delete=8/no-wait=16.
    """
    var eargs = List[UInt8]()
    reserved_short(eargs)
    write_short_string(eargs, ex.copy())
    write_short_string(eargs, "direct")
    eargs.append(4)  # bits: auto-delete
    var etab = FieldTable()
    write_table(eargs, etab)
    client.send(request(UInt16(1), EXCHANGE_DECLARE(), eargs^))
    check(
        client.next_method() == EXCHANGE_DECLARE_OK(),
        "exchange.declare-ok received",
    )

    var qargs = List[UInt8]()
    reserved_short(qargs)
    write_short_string(qargs, q.copy())
    qargs.append(8)  # bits: auto-delete
    var qtab = FieldTable()
    qtab.set_int("x-expires", 60000)
    write_table(qargs, qtab)
    client.send(request(UInt16(1), QUEUE_DECLARE(), qargs^))
    check(client.next_method() == QUEUE_DECLARE_OK(), "queue.declare-ok received")

    var bargs = List[UInt8]()
    reserved_short(bargs)
    write_short_string(bargs, q)
    write_short_string(bargs, ex)
    write_short_string(bargs, "bench.key")
    bargs.append(0)  # nowait (bind synchronously, expect bind-ok)
    var btab = FieldTable()
    write_table(bargs, btab)  # arguments: empty field table (u32 len 0)
    client.send(request(UInt16(1), QUEUE_BIND(), bargs^))
    check(client.next_method() == QUEUE_BIND_OK(), "queue.bind-ok received")


# ---- the measured cycle ----

def build_cycle_wire(
    var ex: String, var q: String, ref body: List[UInt8], batch: Int
) -> List[UInt8]:
    """One closed-loop batch on the wire: `batch` basic.publish messages
    (METHOD + HEADER + 1-2 BODY frames each, split at MAX_BODY_CHUNK) followed
    by `batch` basic.get(auto_ack) frames. batch=1 reproduces the original
    publish+get bytes exactly, in one send.

    Publish/header/body encoding mirrors amqp_over_tcp.mojo::client_wire;
    the get args mirror amqp_service._handle_get (reserved-1, queue, bit)."""
    var wire = List[UInt8]()

    for _ in range(batch):
        var pargs = List[UInt8]()
        reserved_short(pargs)
        write_short_string(pargs, ex.copy())
        write_short_string(pargs, "bench.key")
        pargs.append(0)  # bits: mandatory / immediate
        append_all(wire, request(UInt16(1), BASIC_PUBLISH(), pargs^))

        append_all(
            wire,
            AMQPFrameCodec.encode_header_frame(
                UInt16(1), UInt16(60), UInt64(len(body)), UInt16(0),
                List[UInt8](),
            ),
        )
        var pos = 0
        var blen = len(body)
        while pos < blen:
            var n = MAX_BODY_CHUNK()
            if pos + n > blen:
                n = blen - pos
            var part = List[UInt8]()
            for i in range(pos, pos + n):
                part.append(body[i])
            append_all(wire, AMQPFrameCodec.encode_body_frame(UInt16(1), part^))
            pos += n

    var gargs = List[UInt8]()
    reserved_short(gargs)
    write_short_string(gargs, q)
    gargs.append(1)  # bits: auto-ack (the broker acks on delivery)
    for _ in range(batch):
        append_all(wire, request(UInt16(1), BASIC_GET(), gargs.copy()))
    return wire^


def run_batch_cycle[C: AMQPConn](
    mut client: Conn[C], ref wire: List[UInt8], ref body: List[UInt8],
    batch: Int,
) raises -> Int:
    """Send one batched publish+drain cycle and consume every get reply.

    Returns the number of delivered messages: a basic.get-ok counts 1, a
    basic.get-empty counts 0 for that get. The FIRST get-ok is byte-compared
    (the harness body check); later ones are length-checked only. Any size or
    byte mismatch inside expect_body raises through hyrx.testing.check — a
    wrong delivery fails the bench, loudly."""
    client.send(wire.copy())
    var consumed = 0
    var compared = False
    for _ in range(batch):
        var mid = client.next_method()
        if mid == BASIC_GET_OK():
            client.expect_body(body.copy(), not compared)
            compared = True
            consumed += 1
        else:
            check(
                mid == MethodID(60, 72),  # BASIC_GET_EMPTY()
                "basic.get-ok or basic.get-empty received",
            )
    return consumed


# ---- per-size driver ----

def run_size[C: AMQPConn](
    mut client: Conn[C], size: Int, count: Int, echo: Bool, batch: Int
) raises:
    """The measured run for one payload size on an ALREADY-CONNECTED client.

    Connection setup is the caller's (run_size_tcp / run_size_uds) because the
    two transports have different connect signatures; everything timed here is
    identical for both. `count` stays MESSAGE-count:
    cycles = max(1, count / batch)."""
    var body = List[UInt8]()
    for i in range(size):
        body.append(UInt8(i & 0xFF))

    # Unique names per size: the broker ignores the auto-delete/x-expires
    # fields (NOT IMPLEMENTED, amqp_service), so per-run leftovers from an
    # earlier size must never be get-able by a later one.
    var ex = "bench.ex." + String(size)
    var q = "bench.q." + String(size)

    do_handshake[C](client, echo)
    open_channel[C](client)
    setup_topology[C](client, ex.copy(), q.copy())

    # Floor at one cycle: --batch may exceed --count (e.g. --count 16 --batch
    # 32); never let count / batch truncate the measured window to zero.
    var cycles = count / batch
    if cycles < 1:
        cycles = 1

    var wire = build_cycle_wire(ex.copy(), q.copy(), body, batch)

    var warm = 50
    if cycles < warm:
        warm = cycles
    for _ in range(warm):
        run_batch_cycle[C](client, wire, body, batch)

    var t0 = perf_counter_ns()
    var consumed = 0
    for _ in range(cycles):
        consumed += run_batch_cycle[C](client, wire, body, batch)
    var elapsed = Int(perf_counter_ns() - t0)
    check(elapsed > 0, "timer advanced during the measured window")
    check(consumed > 0, "at least one message delivered in the measurement")

    var rate = (consumed * 1000000000) / elapsed
    var us = Float64(elapsed) / (Float64(consumed) * 1000.0)
    print(
        "NATIVE_BENCH size=" + String(size)
        + " count=" + String(consumed)
        + " rate=" + String(rate)
        + " us_per_msg=" + String(Float64(Int(us * 1000.0)) / 1000.0)
        + " batch=" + String(batch)
    )

    client.close()


def run_size_tcp(
    port: Int, size: Int, count: Int, echo: Bool, batch: Int
) raises:
    """Fresh TCP connection (127.0.0.1:<port>) -> the shared measured run."""
    var conn = TCPConnection.connect("127.0.0.1", port)
    var client = Conn[TCPConnection](conn^)
    run_size[TCPConnection](client, size, count, echo, batch)


def run_size_uds(
    path: String, size: Int, count: Int, echo: Bool, batch: Int
) raises:
    """Fresh UDS connection (pathname or @abstract) -> the shared run.

    Connect idiom copied from tests/integration/broker_uds_e2e.mojo:266 /
    uds_abstract.mojo:269: UDSConnection.connect(path.copy())."""
    var conn = UDSConnection.connect(path.copy())
    var client = Conn[UDSConnection](conn^)
    run_size[UDSConnection](client, size, count, echo, batch)


# ---- CLI (argv style from src/hyrxmq/main_listen.mojo) ----

def parse_sizes(var spec: String) raises -> List[Int]:
    var out = List[Int]()
    var parts = spec.split(",")
    for i in range(len(parts)):
        out.append(Int(String(parts[i])))
    check(len(out) > 0, "--sizes needs at least one size")
    return out^


def default_count(size: Int) -> Int:
    if size <= 4096:
        return 20000
    if size == 16384:
        return 8000
    if size == 65536:
        return 4000
    return 2000


def main() raises:
    var args = argv()
    check(
        len(args) > 1,
        "usage: native_cycle_bench [<port>] [--uds @name|/path.sock]"
        + " [--sizes s,s,...] [--count N] [--no-echo] [--batch K]",
    )
    var port = 0
    var have_port = False
    var uds_path = ""
    var sizes = List[Int]([64, 256, 1024, 4096, 16384, 65536, 131072])
    var forced = -1
    var batch = 1
    var echo = True
    var i = 1
    while i < len(args):
        if args[i] == "--uds":
            i += 1
            check(
                i < len(args),
                "--uds needs a socket path (/tmp/x.sock or @abstract)",
            )
            uds_path = args[i]
        elif args[i] == "--sizes":
            i += 1
            check(i < len(args), "--sizes needs a comma-separated list")
            sizes = parse_sizes(args[i])
        elif args[i] == "--count":
            i += 1
            check(i < len(args), "--count needs a value")
            forced = Int(args[i])
            check(forced > 0, "--count must be positive")
        elif args[i] == "--batch":
            i += 1
            check(i < len(args), "--batch needs a value")
            batch = Int(args[i])
            check(batch > 0, "--batch must be positive")
        elif args[i] == "--no-echo":
            echo = False
        elif not have_port:
            port = Int(args[i])
            have_port = True
        else:
            raise "native_cycle_bench: unknown argument " + args[i]
        i += 1

    # Mutually exclusive transports: --uds wins and the positional port (if any)
    # is ignored; without --uds the TCP path requires the port as before.
    var uds = len(uds_path.bytes()) > 0
    if not uds:
        check(
            have_port,
            "native_cycle_bench: <port> is required unless --uds is given",
        )

    for j in range(len(sizes)):
        var size = sizes[j]
        check(size > 0, "sizes must be positive")
        var count = default_count(size)
        if forced > 0:
            count = forced
        if uds:
            run_size_uds(uds_path.copy(), size, count, echo, batch)
        else:
            run_size_tcp(port, size, count, echo, batch)

    print("NATIVE_BENCH=PASS")
