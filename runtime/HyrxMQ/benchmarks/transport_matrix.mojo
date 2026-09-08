# Transport matrix benchmark — same workload, four transports (audit §19).
#
# The audit (spec §19, docs/TRANSPORTS.md) requires that we stop comparing
# "direct" against nothing and instead quantify the PER-TRANSPORT overhead of
# UDS / Hyrx TCP / AMQP-over-TCP relative to the in-process direct baseline.
#
# Uniform workload (publish -> route -> consume -> ack equivalent):
#   direct : build msg + engine.publish + engine.next_message + engine.ack   (0 hops)
#   uds    : client.send(payload) -> server.recv -> engine cycle
#            -> server.send(ack) -> client.recv                              (2 raw hops)
#   tcp    : same as uds over a 127.0.0.1 socket                             (2 raw hops)
#   amqp   : encode publish frame -> client.send -> server codec/adapter ->
#            engine cycle -> encode ack frame -> server.send -> client
#            recv -> client codec                                            (2 hops + codec)
#
# The DELTA between a socket transport and direct is the transport overhead
# (kernel copies + syscalls + protocol machinery). AMQP's delta over TCP/UDS is
# the codec/adapter overhead. That is the number the report cites.
#
# Single-process, single-thread loopback (bind -> connect -> accept, strict
# ping-pong). Payload stays tiny (64 B / 256 B) so every write drains into the
# loopback kernel buffer before the next write — no read or write can block.
#
# Run:  pixi run mojo run -I src -I vendor/flare benchmarks/transport_matrix.mojo

from std.time import perf_counter_ns
from std.collections import List, Dict

from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import ExchangeType
from hyrx.embedded.api import HyrxEngine, HyrxConfig

from hyrx.transport.transport import TransportConfig
from hyrx.transport.tcp import TCPListener, TCPConnection
from hyrx.transport.uds import UDSListener, UDSConnection

from hyrx.amqp.frame_codec import (
    AMQPFrame,
    AMQPFrameCodec,
    parse_method_args,
)
from hyrx.amqp.adapter import AMQPAdapter
from hyrxmq.amqp_service import write_short_string

from direct_benchmark import LatencyResult, compute_percentiles, format_ns


# ---- shared workload helpers ----

def _engine_cycle(
    mut engine: HyrxEngine, cid: UInt64, var rk: String, payload_size: Int, seq: Int
) raises:
    """build -> publish -> next_message -> acknowledge on the injected engine."""
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(UInt64(seq)), rk^, headers^)
    var buf = Buffer(payload_size)
    buf.resize(payload_size)
    for b in range(payload_size):
        buf[b] = UInt8((seq + b) & 0xFF)
    var m = Message(env^, buf^)
    _ = engine.publish(m^, "bench")
    var d = engine.next_message(cid)
    if d:
        _ = engine.acknowledge(cid, d.value().delivery_tag())


def _setup_engine() raises -> HyrxEngine:
    var config = HyrxConfig(1_000_000, 4096, 64)
    var engine = HyrxEngine(config^)
    _ = engine.declare_exchange("bench", ExchangeType.direct())
    _ = engine.declare_queue("bench_q")
    _ = engine.bind_queue("bench_q", "bench", "bench.key")
    return engine^


def _payload(n: Int, seq: Int) -> List[UInt8]:
    var out = List[UInt8]()
    for i in range(n):
        out.append(UInt8((seq + i) & 0xFF))
    return out^


def _summary(name: String, payload: Int, cycles: Int, ref lr: LatencyResult):
    # Strict ping-pong (one message in flight), so steady-state throughput is
    # 1 / mean cycle time. Wire bytes differ per transport; B/s is the payload.
    var secs_per_cycle = lr.mean_ns / 1000000000.0
    var mps = 1.0 / secs_per_cycle
    print("[" + name + "]  payload=" + String(payload)
          + " B  cycles=" + String(cycles))
    print("   throughput: " + String(Int(mps))
          + " msgs/s   " + String(Int(mps * Float64(payload)))
          + " B/s(payload)")
    print("   cycle  p50=" + format_ns(lr.p50)
          + "  p95=" + format_ns(lr.p95)
          + "  p99=" + format_ns(lr.p99)
          + "  p99.9=" + format_ns(lr.p999)
          + "  mean=" + format_ns(lr.mean_ns)
          + "  max=" + format_ns(lr.max_ns))


# ---- direct (in-process baseline) ----

def bench_direct(payload: Int, cycles: Int, warmup: Int) raises -> LatencyResult:
    var engine = _setup_engine()
    var cid = engine.consume("bench_q", 0)
    for i in range(warmup):
        _engine_cycle(engine, cid, "bench.key", payload, i)
    var lat = List[Float64]()
    for i in range(cycles):
        var t0 = perf_counter_ns()
        _engine_cycle(engine, cid, "bench.key", payload, warmup + i)
        var t1 = perf_counter_ns()
        lat.append(Float64(t1 - t0))
    return compute_percentiles(lat^)


# ---- raw socket (UDS / TCP) with an engine cycle on the server side ----

def bench_tcp(payload: Int, cycles: Int, warmup: Int) raises -> LatencyResult:
    var listener = TCPListener("127.0.0.1", 0, TransportConfig()^)
    _ = listener.start()
    var port = listener.port()
    var client = TCPConnection.connect("127.0.0.1", port)
    var server = listener.accept_connection()
    var engine = _setup_engine()
    var cid = engine.consume("bench_q", 0)
    var lat = List[Float64]()
    for i in range(warmup + cycles):
        var body = _payload(payload, i)
        var t0 = perf_counter_ns()
        _ = client.send_bytes(body.copy())
        _ = server.value().recv_exact(payload)
        _engine_cycle(engine, cid, "bench.key", payload, i)
        _ = server.value().send_bytes(_payload(1, i))
        _ = client.recv_exact(1)
        var t1 = perf_counter_ns()
        if i >= warmup:
            lat.append(Float64(t1 - t0))
    server.value().close()
    client.close()
    listener.stop()
    return compute_percentiles(lat^)


def bench_uds(payload: Int, cycles: Int, warmup: Int) raises -> LatencyResult:
    var path = String("/tmp/hyrx_transport_matrix_uds.sock")
    var listener = UDSListener(path.copy(), TransportConfig()^)
    _ = listener.start()
    var client = UDSConnection.connect(path^)
    var server = listener.accept_connection()
    var engine = _setup_engine()
    var cid = engine.consume("bench_q", 0)
    var lat = List[Float64]()
    for i in range(warmup + cycles):
        var body = _payload(payload, i)
        var t0 = perf_counter_ns()
        _ = client.send_bytes(body.copy())
        _ = server.value().recv_exact(payload)
        _engine_cycle(engine, cid, "bench.key", payload, i)
        _ = server.value().send_bytes(_payload(1, i))
        _ = client.recv_exact(1)
        var t1 = perf_counter_ns()
        if i >= warmup:
            lat.append(Float64(t1 - t0))
    server.value().close()
    client.close()
    listener.stop()
    return compute_percentiles(lat^)


# ---- AMQP over TCP: codec encode -> socket -> decode/adapter -> engine
#      -> ack frame -> socket -> client decode ----

def _encode_publish(var body: List[UInt8]) -> List[UInt8]:
    """basic.publish frame with body inline (Phase 7 representation choice)."""
    var args = List[UInt8]()
    args.append(UInt8(0))
    args.append(UInt8(0))
    write_short_string(args, "bench")
    write_short_string(args, "bench.key")
    for i in range(len(body)):
        args.append(body[i])
    # BASIC class=60, publish method=40
    return AMQPFrameCodec.encode_method_frame(UInt16(1), UInt16(60), UInt16(40), args^)


def _encode_ack(tag: UInt64) -> List[UInt8]:
    """basic.ack frame (class 60 method 80), 8-byte delivery tag + multiple=0."""
    var args = List[UInt8]()
    for s in range(56, -1, -8):
        args.append(UInt8((tag >> UInt64(s)) & 0xFF))
    args.append(UInt8(0))  # multiple
    return AMQPFrameCodec.encode_method_frame(UInt16(1), UInt16(60), UInt16(80), args^)


def bench_amqp(payload: Int, cycles: Int, warmup: Int) raises -> LatencyResult:
    var listener = TCPListener("127.0.0.1", 0, TransportConfig()^)
    _ = listener.start()
    var port = listener.port()
    var client = TCPConnection.connect("127.0.0.1", port)
    var server = listener.accept_connection()

    var adapter = AMQPAdapter()
    var engine = _setup_engine()
    var cid = engine.consume("bench_q", 0)

    var scodec = AMQPFrameCodec()
    var ccodec = AMQPFrameCodec()
    var lat = List[Float64]()

    for i in range(warmup + cycles):
        var body = _payload(payload, i)
        var t0 = perf_counter_ns()

        # client: encode publish frame -> wire
        var frame = _encode_publish(body.copy())
        _ = client.send_bytes(frame.copy())

        # server: wire -> codec -> parse -> adapter.publish -> deliver -> ack
        var sf = scodec.try_parse_frame()
        while not sf.__bool__():
            var chunk = server.value().recv_bytes(8192)
            if len(chunk) == 0:
                raise "amqp: server EOF before publish frame"
            scodec.feed_bytes(chunk^)
            sf = scodec.try_parse_frame()
        var method = parse_method_args(sf.value().payload_copy())
        var reader_args = method.args.copy()
        # skip reserved short, exchange, routing key; remaining bytes = body
        var body_off = 2 + 1 + "bench".byte_length() + 1 + "bench.key".byte_length()
        var pub_body = List[UInt8]()
        for j in range(body_off, len(reader_args)):
            pub_body.append(reader_args[j])
        _ = adapter.publish(engine, "bench.key", pub_body.copy(), "bench")
        var deliv = adapter.deliver_next(engine, cid)
        var tag = UInt64(0)
        if deliv:
            tag = deliv.value().delivery_tag()
            _ = adapter.read_payload(engine, cid, tag)
            _ = adapter.acknowledge(engine, cid, tag)

        # server: ack frame -> wire
        var ack = _encode_ack(tag)
        _ = server.value().send_bytes(ack.copy())

        # client: wire -> codec -> ack frame
        var cf = ccodec.try_parse_frame()
        while not cf.__bool__():
            var cchunk = client.recv_bytes(8192)
            if len(cchunk) == 0:
                raise "amqp: client EOF before ack frame"
            ccodec.feed_bytes(cchunk^)
            cf = ccodec.try_parse_frame()

        var t1 = perf_counter_ns()
        if i >= warmup:
            lat.append(Float64(t1 - t0))

    server.value().close()
    client.close()
    listener.stop()
    return compute_percentiles(lat^)


def main() raises:
    print("Hyrx TRANSPORT MATRIX (audit §19) — same workload, 4 transports")
    print("=" * 72)
    var t_all = perf_counter_ns()
    var cycles = 20000
    var warmup = 2000

    var sizes = List[Int]()
    sizes.append(64)
    sizes.append(256)
    for si in range(len(sizes)):
        var payload = sizes[si]
        print("---- payload = " + String(payload) + " B ----")
        var d = bench_direct(payload, cycles, warmup)
        _summary("direct", payload, cycles, d)
        var u = bench_uds(payload, cycles, warmup)
        _summary("uds   ", payload, cycles, u)
        var tc = bench_tcp(payload, cycles, warmup)
        _summary("tcp   ", payload, cycles, tc)
        var am = bench_amqp(payload, cycles, warmup)
        _summary("amqp  ", payload, cycles, am)
        print("   overhead vs direct  (p50): uds +"
              + format_ns(u.p50 - d.p50)
              + "  tcp +" + format_ns(tc.p50 - d.p50)
              + "  amqp +" + format_ns(am.p50 - d.p50))
        print("   codec overhead vs tcp (p50): +" + format_ns(am.p50 - tc.p50))

    var wall = Float64(perf_counter_ns() - t_all) / 1000000.0
    print("=" * 72)
    print("TOTAL wall time: " + String(wall) + " ms")
    print("NOTE: throughput here is round-trip cycle rate; payload B/s is the")
    print("      application payload only (wire bytes differ per transport).")
    print("DONE")
