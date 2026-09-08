# INTERLEAVED (steady-state) in-process benchmark for Hyrx messaging.
#
# Audit §19: a publish-all-then-consume-all loop is NOT steady-state evidence —
# it lets the queue grow without bound and batches the consume, hiding the
# per-message route/deliver/ack cost profile of a real producer/consumer.
#
# This benchmark runs the correct cycle: each iteration performs
#     publish -> route -> consume -> ack
# on the SAME in-process engine before the next publish. Queue depth therefore
# stays ~0-1 (bounded), which is the steady-state regime.
#
# The timed region per iteration is the engine cycle
# (publish + next_message + acknowledge); message construction happens outside
# the timed window so the reported latency is the engine, not the fixture.
#
# Reports msgs/sec, bytes/sec and p50/p95/p99/p99.9 of the per-iteration cycle,
# across payload sizes 64 B / 256 B / 1 KiB / 4 KiB / 64 KiB.
#
# Reuses LatencyResult / BenchmarkResult / compute_percentiles / format_ns from
# direct_benchmark.mojo (importable because Mojo adds the main file's directory
# to the search path) rather than duplicating them.
#
# Run:  pixi run mojo run -I src -I vendor/flare benchmarks/interleaved_direct.mojo

from std.time import perf_counter_ns
from std.collections import List, Dict

from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import ExchangeType
from hyrx.embedded.api import HyrxEngine, HyrxConfig

from direct_benchmark import (
    BenchmarkResult,
    LatencyResult,
    compute_percentiles,
    format_ns,
)


def _make_message(seq: Int, payload_size: Int) raises -> Message:
    """Build one owned message with a payload of `payload_size` bytes."""
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(UInt64(seq)), "bench.key", headers^)
    var buf = Buffer(payload_size)
    buf.resize(payload_size)
    for b in range(payload_size):
        buf[b] = UInt8((seq + b) & 0xFF)
    return Message(env^, buf^)


def benchmark_interleaved(
    message_count: Int, payload_size: Int
) raises -> BenchmarkResult:
    """Run `message_count` interleaved publish->consume->ack cycles."""
    var label = (
        String(message_count)
        + " interleaved, "
        + String(payload_size)
        + " B"
    )
    var config = HyrxConfig(1_000_000, 4096, 64)
    var engine = HyrxEngine(config^)
    _ = engine.declare_exchange("bench", ExchangeType.direct())
    _ = engine.declare_queue("bench_q")
    _ = engine.bind_queue("bench_q", "bench", "bench.key")

    var cid = engine.consume("bench_q", 0)

    # Warm-up: same cycle, excluded from the samples.
    var warmup = min(2000, message_count)
    for i in range(warmup):
        var wm = _make_message(i, payload_size)
        _ = engine.publish(wm^, "bench")
        var wd = engine.next_message(cid)
        if wd:
            _ = engine.acknowledge(cid, wd.value().delivery_tag())

    # Steady-state timed loop.
    var cycles = message_count - warmup
    var latencies = List[Float64]()
    var start_time = perf_counter_ns()
    for i in range(cycles):
        var m = _make_message(warmup + i, payload_size)
        var t0 = perf_counter_ns()
        _ = engine.publish(m^, "bench")
        var d = engine.next_message(cid)
        if d:
            _ = engine.acknowledge(cid, d.value().delivery_tag())
        var t1 = perf_counter_ns()
        latencies.append(Float64(t1 - t0))
    var end_time = perf_counter_ns()

    var total_ns = Float64(end_time - start_time)
    var total_ms = total_ns / 1000000.0
    var secs = total_ns / 1000000000.0
    var msgs_per_sec = Float64(cycles) / secs
    var bytes_per_sec = Float64(cycles * payload_size) / secs
    var latency_stats = compute_percentiles(latencies^)
    return BenchmarkResult(
        label^, cycles, payload_size, total_ms, msgs_per_sec, bytes_per_sec,
        latency_stats^,
    )


def _pad(var s: String, width: Int) -> String:
    while s.byte_length() < width:
        s = s + " "
    return s


def _r(x: Float64, digits: Int) -> String:
    var m = 1.0
    for _ in range(digits):
        m *= 10.0
    return String(Float64(Int(x * m)) / m)


def _fmt_mib(ps: Float64) -> String:
    return _r(ps / 1048576.0, 2) + " MiB/s"


def print_result(var result: BenchmarkResult):
    print("---")
    print("  Workload:   " + result.label)
    print("  Cycles:     " + String(result.message_count))
    print("  Payload:    " + String(result.payload_size) + " bytes")
    print("  Total:      " + String(result.total_time_ms) + " ms")
    print("  Throughput: " + String(result.messages_per_sec) + " msgs/sec")
    print("  Bandwidth:  " + String(result.bytes_per_sec) + " B/s ("
          + _fmt_mib(result.bytes_per_sec) + ")")
    print("  Cycle latency (publish+consume+ack per iteration):")
    print("    p50:   " + format_ns(result.latency.p50))
    print("    p95:   " + format_ns(result.latency.p95))
    print("    p99:   " + format_ns(result.latency.p99))
    print("    p99.9: " + format_ns(result.latency.p999))
    print("    min:   " + format_ns(result.latency.min_ns))
    print("    max:   " + format_ns(result.latency.max_ns))
    print("    mean:  " + format_ns(result.latency.mean_ns))


def _emit(
    mut payloads: List[Int], mut cycles_l: List[Int], mut mps: List[Float64],
    mut bps: List[Float64], mut p50s: List[Float64], mut p999s: List[Float64],
    var result: BenchmarkResult,
):
    payloads.append(result.payload_size)
    cycles_l.append(result.message_count)
    mps.append(result.messages_per_sec)
    bps.append(result.bytes_per_sec)
    p50s.append(result.latency.p50)
    p999s.append(result.latency.p999)
    print_result(result^)


def main() raises:
    print("Hyrx INTERLEAVED (steady-state) Benchmark — audit §19")
    print("=" * 72)
    var t0 = perf_counter_ns()
    var payloads = List[Int]()
    var cycles_l = List[Int]()
    var mps = List[Float64]()
    var bps = List[Float64]()
    var p50s = List[Float64]()
    var p999s = List[Float64]()
    var r0 = benchmark_interleaved(100_000, 64)
    _emit(payloads, cycles_l, mps, bps, p50s, p999s, r0^)
    var r1 = benchmark_interleaved(100_000, 256)
    _emit(payloads, cycles_l, mps, bps, p50s, p999s, r1^)
    var r2 = benchmark_interleaved(100_000, 1024)
    _emit(payloads, cycles_l, mps, bps, p50s, p999s, r2^)
    var r3 = benchmark_interleaved(50_000, 4096)
    _emit(payloads, cycles_l, mps, bps, p50s, p999s, r3^)
    var r4 = benchmark_interleaved(10_000, 65536)
    _emit(payloads, cycles_l, mps, bps, p50s, p999s, r4^)
    var wall = Float64(perf_counter_ns() - t0) / 1000000.0
    print("=" * 72)
    print("payload(B)  cycles   msgs/s       MiB/s      p50        p99.9")
    for i in range(len(payloads)):
        print(
            _pad(String(payloads[i]), 11)
            + _pad(String(cycles_l[i]), 9)
            + _pad(String(Int(mps[i])), 11)
            + _pad(_r(bps[i] / 1048576.0, 2), 11)
            + _pad(format_ns(p50s[i]), 11)
            + format_ns(p999s[i])
        )
    print("=" * 72)
    print("TOTAL wall time: " + String(wall) + " ms")
    print("DONE")
