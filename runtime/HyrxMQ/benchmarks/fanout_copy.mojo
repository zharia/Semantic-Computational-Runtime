# Message-copy / fan-out investigation (audit §21) — MEASURE, do not refactor.
#
# Router.publish() (src/hyrx/core/router.mojo:161-183) copies the payload PER
# destination queue. Reading the code, each destination performs TWO full
# payload copies:
#     copy #1  msg.payload()            -> BufferSnapshot   (router.mojo:170)
#     copy #2  per-byte rebuild loop     -> owned Buffer     (router.mojo:177-180)
# so bytes written per publish ~= 2 * destinations * payload_size.
#
# This benchmark MEASURES that scaling (it does NOT change behavior):
#   * engine publish() latency / throughput across a FANOUT exchange bound to
#     D = {1, 2, 10, 100} queues, payload {64, 256, 4096, 65536} B;
#   * an isolated copy-throughput model (snapshot + rebuild, the same two loops
#     the router runs) so publish time can be attributed to the copy path;
#   * a bytes-copied counter (derived analytically as 2*D*payload per publish,
#     the exact work the router does — no engine field is mutated).
#
# Queues are declared at a SMALL capacity and never consumed, so retained
# memory stays bounded (<= capacity * D messages) while every destination still
# performs its two copies (the copy precedes enqueue()). This isolates fan-out
# copy cost without unbounded growth. publish() returns the accepted count; we
# ignore drops — the copy cost is paid either way.
#
# NO Candidate A-D refactor is attempted here. Output is evidence + a
# recommendation keyed to the measured slope.
#
# Run:  pixi run mojo run -I src -I vendor/flare benchmarks/fanout_copy.mojo

from std.time import perf_counter_ns
from std.collections import List, Dict

from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import ExchangeType
from hyrx.embedded.api import HyrxEngine, HyrxConfig

from direct_benchmark import compute_percentiles, format_ns


def _make_message(seq: Int, payload_size: Int) raises -> Message:
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(UInt64(seq)), "bench.key", headers^)
    var buf = Buffer(payload_size)
    buf.resize(payload_size)
    for b in range(payload_size):
        buf[b] = UInt8((seq + b) & 0xFF)
    return Message(env^, buf^)


def _build_fanout(dests: Int) raises -> HyrxEngine:
    """Engine with a fanout exchange bound to `dests` bounded queues."""
    var engine = HyrxEngine(HyrxConfig(8, 4096, 64)^)  # small capacity: bounded mem
    _ = engine.declare_exchange("bench", ExchangeType.fanout())
    for q in range(dests):
        _ = engine.declare_queue("q" + String(q))
        _ = engine.bind_queue("q" + String(q), "bench", "bench.key")
    return engine^


def bench_fanout(dests: Int, payload: Int) raises -> Float64:
    """Return p50 publish-cycle ns for one message fanned out to `dests`."""
    var work = dests * payload
    # iterations chosen for ~2.4 MB of copy work, clamped for stable percentiles
    var cycles = max(40, min(6000, 2_400_000 // (work + 1)))
    var engine = _build_fanout(dests)

    # warm-up
    var warm = min(cycles, 200)
    for i in range(warm):
        var mw = _make_message(i, payload)
        _ = engine.publish(mw^, "bench")

    var lat = List[Float64]()
    for i in range(cycles):
        var m = _make_message(warm + i, payload)
        var t0 = perf_counter_ns()
        _ = engine.publish(m^, "bench")  # fan-out copies happen here
        var t1 = perf_counter_ns()
        lat.append(Float64(t1 - t0))
    var lr = compute_percentiles(lat^)
    _ = lr
    return lr.p50


# ---- isolated copy model: exactly the two loops router.publish runs per dest ----

def _copy_model_once(payload_size: Int) raises -> Int:
    """One snapshot + rebuild (2 * payload bytes written). Returns bytes copied."""
    var src = Buffer(payload_size)
    src.resize(payload_size)
    for b in range(payload_size):
        src[b] = UInt8(b & 0xFF)
    var snap = src.snapshot()  # copy #1
    var dst = Buffer(snap.size())
    dst.resize(snap.size())
    for j in range(snap.size()):
        dst[j] = snap[j]  # copy #2
    var n = snap.size() + dst.size()
    return n


def bench_copy_model(payload_size: Int) raises:
    """Print bytes/sec for one snapshot+rebuild (2 * payload bytes written)."""
    var reps = max(50, min(20000, 2_400_000 // (payload_size + 1)))
    _ = _copy_model_once(payload_size)  # warm
    var t0 = perf_counter_ns()
    for _ in range(reps):
        _ = _copy_model_once(payload_size)
    var t1 = perf_counter_ns()
    var total_ns = Float64(t1 - t0)
    var ns_per = total_ns / Float64(reps)
    var bytes_per_sec = (Float64(reps) * Float64(2 * payload_size)) / (
        total_ns / 1000000000.0
    )
    print("  payload " + _p(String(payload_size) + " B", 10) + ": "
          + _p(format_ns(ns_per), 14) + "per copy   "
          + String(bytes_per_sec / 1048576.0) + " MiB/s")


def main() raises:
    print("Hyrx FAN-OUT / MESSAGE-COPY investigation (audit §21)")
    print("=" * 72)
    var t_all = perf_counter_ns()

    var dests = List[Int]()
    dests.append(1)
    dests.append(2)
    dests.append(10)
    dests.append(100)
    var payloads = List[Int]()
    payloads.append(64)
    payloads.append(256)
    payloads.append(4096)
    payloads.append(65536)

    print("engine publish() p50 by (destinations x payload)")
    print("dest  " + _p("64B", 12) + _p("256B", 12) + _p("4KiB", 12) + _p("64KiB", 12))
    for di in range(len(dests)):
        var d = dests[di]
        var row = _p(String(d), 5)
        for pi in range(len(payloads)):
            var p = payloads[pi]
            var p50 = bench_fanout(d, p)
            row = row + _p(format_ns(p50), 12)
        print(row)

    print("-" * 72)
    print("isolated copy model (snapshot+rebuild = 2 copies/dest), bytes/sec:")
    for pi in range(len(payloads)):
        bench_copy_model(payloads[pi])

    print("-" * 72)
    print("marginal cost of the LAST 90 destinations over 1 (copy slope evidence):")
    for mi in range(len(payloads)):
        var p2 = payloads[mi]
        var p1 = bench_fanout(1, p2)
        var p100 = bench_fanout(100, p2)
        var per_dest = (p100 - p1) / 99.0
        print("  payload " + _p(String(p2) + " B", 10)
              + ": p50 D=1 " + _p(format_ns(p1), 12)
              + " D=100 " + _p(format_ns(p100), 12)
              + "  per-dest +" + format_ns(per_dest))

    var wall = Float64(perf_counter_ns() - t_all) / 1000000.0
    print("=" * 72)
    print("TOTAL wall time: " + String(wall) + " ms")
    print("copies/publish = 2*destinations payload copies (router.mojo:170,177)")
    print("DONE")


def _p(var s: String, width: Int) -> String:
    while s.byte_length() < width:
        s = s + " "
    return s
