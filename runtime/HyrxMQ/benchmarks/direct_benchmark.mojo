# Direct in-process benchmark for Hyrx messaging.
#
# Measures: publish → route → deliver → consume cycle.
# No network, no disk, no persistence.
#
# Workload: N messages, varying payload sizes, 1 producer, 1 consumer.
# Records: latency (p50/p95/p99/p99.9), throughput, bytes/sec.

from std.time import perf_counter_ns
from std.collections import List, Dict
from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import ExchangeType
from hyrx.embedded.api import HyrxEngine, HyrxConfig

struct LatencyResult:
    var p50: Float64
    var p95: Float64
    var p99: Float64
    var p999: Float64
    var min_ns: Float64
    var max_ns: Float64
    var mean_ns: Float64
    var total_count: Int

    def __init__(
        out self, p50: Float64, p95: Float64, p99: Float64, p999: Float64,
        min_ns: Float64, max_ns: Float64, mean_ns: Float64, total_count: Int,
    ):
        self.p50 = p50
        self.p95 = p95
        self.p99 = p99
        self.p999 = p999
        self.min_ns = min_ns
        self.max_ns = max_ns
        self.mean_ns = mean_ns
        self.total_count = total_count

struct BenchmarkResult:
    var label: String
    var message_count: Int
    var payload_size: Int
    var total_time_ms: Float64
    var messages_per_sec: Float64
    var bytes_per_sec: Float64
    var latency: LatencyResult

    def __init__(
        out self, var label: String, message_count: Int, payload_size: Int,
        total_time_ms: Float64, messages_per_sec: Float64, bytes_per_sec: Float64,
        var latency: LatencyResult,
    ):
        self.label = label^
        self.message_count = message_count
        self.payload_size = payload_size
        self.total_time_ms = total_time_ms
        self.messages_per_sec = messages_per_sec
        self.bytes_per_sec = bytes_per_sec
        self.latency = latency^

def _sort_f64(mut lst: List[Float64]):
    var n = len(lst)
    for i in range(1, n):
        var key = lst[i]
        var j = i - 1
        while j >= 0 and lst[j] > key:
            lst[j + 1] = lst[j]
            j -= 1
        lst[j + 1] = key

def compute_percentiles(var samples: List[Float64]) -> LatencyResult:
    if len(samples) == 0:
        return LatencyResult(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0)
    _sort_f64(samples)
    var count = len(samples)
    var p50_idx = min(count * 50 // 100, count - 1)
    var p95_idx = min(count * 95 // 100, count - 1)
    var p99_idx = min(count * 99 // 100, count - 1)
    var p999_idx = min(count * 999 // 1000, count - 1)
    var total: Float64 = 0.0
    for i in range(count):
        total += samples[i]
    var mean = total / Float64(count)
    return LatencyResult(
        samples[p50_idx], samples[p95_idx], samples[p99_idx], samples[p999_idx],
        samples[0], samples[count - 1], mean, count,
    )

def format_ns(ns: Float64) -> String:
    if ns < 1000.0:
        return String(ns) + " ns"
    elif ns < 1000000.0:
        return String(ns / 1000.0) + " us"
    else:
        return String(ns / 1000000.0) + " ms"

def benchmark_direct_throughput(
    message_count: Int, payload_size: Int
) raises -> BenchmarkResult:
    var label = String(message_count) + " msgs, " + String(payload_size) + " B payload"
    var config = HyrxConfig(1_000_000, 4096, 64)
    var engine = HyrxEngine(config^)
    _ = engine.declare_exchange("bench", ExchangeType.direct())
    _ = engine.declare_queue("bench_q")
    _ = engine.bind_queue("bench_q", "bench", "bench.key")

    var messages = List[Message]()
    for i in range(message_count):
        var headers = Dict[String, String]()
        var env = Envelope(MessageID(UInt64(i)), "bench.key", headers^)
        var buf = Buffer(payload_size)
        buf.resize(payload_size)
        for b in range(payload_size):
            buf[b] = UInt8(i & 0xFF)
        messages.append(Message(env^, buf^))

    # Register consumer
    var cid = engine.consume("bench_q", 0)

    # Warm up
    var warmup_count = min(100, message_count)
    for _ in range(warmup_count):
        _ = engine.publish(messages.pop(0), "bench")
    for _ in range(warmup_count):
        var d = engine.next_message(cid)
        if d:
            _ = engine.acknowledge(cid, d.value().delivery_tag())
    var remaining = message_count - warmup_count

    # Benchmark: publish all, then consume all
    var latencies = List[Float64]()
    var start_time = perf_counter_ns()
    for _ in range(remaining):
        var t0 = perf_counter_ns()
        _ = engine.publish(messages.pop(0), "bench")
        var t1 = perf_counter_ns()
        latencies.append(Float64(t1 - t0))

    for _ in range(remaining):
        var d = engine.next_message(cid)
        if d:
            _ = engine.acknowledge(cid, d.value().delivery_tag())

    var end_time = perf_counter_ns()
    var total_ns = Float64(end_time - start_time)
    var total_ms = total_ns / 1000000.0
    var msgs_per_sec = Float64(remaining) / (total_ns / 1000000000.0)
    var bytes_per_sec = Float64(remaining * payload_size) / (total_ns / 1000000000.0)
    var latency_stats = compute_percentiles(latencies^)
    return BenchmarkResult(
        label^, remaining, payload_size, total_ms, msgs_per_sec, bytes_per_sec, latency_stats^,
    )

def benchmark_sustained_throughput(
    message_count: Int, payload_size: Int, duration_ms: Int
) raises -> BenchmarkResult:
    var label = "sustained " + String(duration_ms) + "ms, " + String(payload_size) + " B"
    var config = HyrxConfig(1_000_000, 4096, 64)
    var engine = HyrxEngine(config^)
    _ = engine.declare_exchange("bench", ExchangeType.direct())
    _ = engine.declare_queue("bench_q")
    _ = engine.bind_queue("bench_q", "bench", "bench.key")

    var messages = List[Message]()
    for i in range(message_count):
        var headers = Dict[String, String]()
        var env = Envelope(MessageID(UInt64(i)), "bench.key", headers^)
        var buf = Buffer(payload_size)
        buf.resize(payload_size)
        for b in range(payload_size):
            buf[b] = UInt8(i & 0xFF)
        messages.append(Message(env^, buf^))

    var cid = engine.consume("bench_q", 0)
    var start_time = perf_counter_ns()
    var duration_ns = Float64(duration_ms) * 1000000.0
    var published = 0
    var latencies = List[Float64]()

    for _ in range(message_count):
        var elapsed = Float64(perf_counter_ns() - start_time)
        if elapsed >= duration_ns:
            break
        var t0 = perf_counter_ns()
        _ = engine.publish(messages.pop(0), "bench")
        var t1 = perf_counter_ns()
        latencies.append(Float64(t1 - t0))
        published += 1

    for _ in range(published):
        var d = engine.next_message(cid)
        if d:
            _ = engine.acknowledge(cid, d.value().delivery_tag())

    var end_time = perf_counter_ns()
    var total_ns = Float64(end_time - start_time)
    var total_ms = total_ns / 1000000.0
    var msgs_per_sec = Float64(published) / (total_ns / 1000000000.0)
    var bytes_per_sec = Float64(published * payload_size) / (total_ns / 1000000000.0)
    var latency_stats = compute_percentiles(latencies^)
    return BenchmarkResult(
        label^, published, payload_size, total_ms, msgs_per_sec, bytes_per_sec, latency_stats^,
    )

def print_result(var result: BenchmarkResult):
    print("---")
    print("  Workload: " + result.label)
    print("  Messages: " + String(result.message_count))
    print("  Payload:  " + String(result.payload_size) + " bytes")
    print("  Total:    " + String(result.total_time_ms) + " ms")
    print("  Throughput: " + String(result.messages_per_sec) + " msgs/sec")
    print("  Bandwidth:  " + String(result.bytes_per_sec) + " bytes/sec")
    print("  Latency (per publish):")
    print("    p50:   " + format_ns(result.latency.p50))
    print("    p95:   " + format_ns(result.latency.p95))
    print("    p99:   " + format_ns(result.latency.p99))
    print("    p99.9: " + format_ns(result.latency.p999))
    print("    min:   " + format_ns(result.latency.min_ns))
    print("    max:   " + format_ns(result.latency.max_ns))
    print("    mean:  " + format_ns(result.latency.mean_ns))

def main() raises:
    print("Hyrx Direct Benchmark")
    print("=" * 60)
    print_result(benchmark_direct_throughput(100_000, 64)^)
    print_result(benchmark_direct_throughput(100_000, 256)^)
    print_result(benchmark_direct_throughput(100_000, 1024)^)
    print_result(benchmark_direct_throughput(10_000, 65536)^)
    print_result(benchmark_sustained_throughput(1_000_000, 256, 5000)^)
    print("=" * 60)
    print("DONE")
