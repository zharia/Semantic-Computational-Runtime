# Profiling baseline via SELF-INSTRUMENTATION only (audit §20).
#
# No perf / valgrind / strace is available in this toolchain (confirmed), so we
# do NOT guess a bottleneck from a profiler we don't have. We decompose the
# in-process publish cycle into named phases with wall-clock timers and report
# the fraction of the cycle each phase takes. This is timing-based attribution,
# not sampling-profiling: results are phrased "strongly indicated".
#
# Phase decomposition of one steady-state cycle (single destination):
#   alloc   : build payload Buffer + fill (producer-side allocation)
#   route   : engine.publish (exchange match + per-dest 2x payload copy + enqueue)
#   deliver : engine.next_message (queue dequeue -> unacked + delivery token)
#   ack     : engine.acknowledge (destroy message)
#
# It also reports an ALLOCATION / COPY byte counter that is DERIVED from the
# workload sizes (it mutates no engine state), so bytes-copied/publish and
# approximate allocations/publish are substantiated for the report.
#
# CPU time and context switches are measured EXTERNALLY by sampling
# /proc/<pid>/stat and /proc/<pid>/status around a built binary of this program
# (see the report). They cannot be read from inside Mojo (this build exposes no
# `sys`/`os` file API).
#
# Run:  pixi run mojo run -I src -I vendor/flare benchmarks/profiling_probe.mojo

from std.time import perf_counter_ns
from std.collections import List, Dict

from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import ExchangeType
from hyrx.embedded.api import HyrxEngine, HyrxConfig

from direct_benchmark import format_ns


def _sum_ns(x: Float64) -> String:
    return format_ns(x)


def phase_probe(payload: Int, cycles: Int, warmup: Int) raises:
    print("---- payload = " + String(payload) + " B  (cycles="
          + String(cycles) + ") ----")
    var engine = HyrxEngine(HyrxConfig(1_000_000, 4096, 64)^)
    _ = engine.declare_exchange("bench", ExchangeType.direct())
    _ = engine.declare_queue("bench_q")
    _ = engine.bind_queue("bench_q", "bench", "bench.key")
    var cid = engine.consume("bench_q", 0)

    var a_alloc = 0.0
    var a_route = 0.0
    var a_deliver = 0.0
    var a_ack = 0.0
    var n = cycles + warmup
    for i in range(n):
        var headers = Dict[String, String]()
        var env = Envelope(MessageID(UInt64(i)), "bench.key", headers^)
        var t0 = perf_counter_ns()
        var buf = Buffer(payload)
        buf.resize(payload)
        for b in range(payload):
            buf[b] = UInt8((i + b) & 0xFF)
        var m = Message(env^, buf^)
        var t1 = perf_counter_ns()
        _ = engine.publish(m^, "bench")
        var t2 = perf_counter_ns()
        var d = engine.next_message(cid)
        var t3 = perf_counter_ns()
        if d:
            _ = engine.acknowledge(cid, d.value().delivery_tag())
        var t4 = perf_counter_ns()
        if i >= warmup:
            a_alloc += Float64(t1 - t0)
            a_route += Float64(t2 - t1)
            a_deliver += Float64(t3 - t2)
            a_ack += Float64(t4 - t3)

    var f = Float64(cycles)
    var m_alloc = a_alloc / f
    var m_route = a_route / f
    var m_deliver = a_deliver / f
    var m_ack = a_ack / f
    var total = m_alloc + m_route + m_deliver + m_ack
    print("  alloc   (producer Buffer+fill): " + _sum_ns(m_alloc)
          + "   (" + String(m_alloc / total * 100.0) + "%)")
    print("  route   (publish: match+copy): " + _sum_ns(m_route)
          + "   (" + String(m_route / total * 100.0) + "%)")
    print("  deliver (next_message)        : " + _sum_ns(m_deliver)
          + "   (" + String(m_deliver / total * 100.0) + "%)")
    print("  ack     (destroy)             : " + _sum_ns(m_ack)
          + "   (" + String(m_ack / total * 100.0) + "%)")
    print("  cycle total                   : " + _sum_ns(total))
    # Derived counters (no engine mutation): route copies payload twice per dest.
    var copies_bytes = Float64(2 * payload)  # snapshot + rebuild, 1 destination
    print("  derived bytes-copied/publish (route): " + String(Int(copies_bytes))
          + " B  (~" + String(copies_bytes / (m_route / 1000000000.0) / 1048576.0)
          + " MiB/s effective copy rate)")
    print("  derived allocations/publish : >=3  (1 src Buffer + 1 snapshot"
          + " + 1 owned Buffer per dest)")


def main() raises:
    print("Hyrx PROFILING PROBE — phase decomposition, self-instrumentation (§20)")
    print("=" * 68)
    var t0 = perf_counter_ns()
    phase_probe(64, 20000, 2000)
    phase_probe(256, 20000, 2000)
    phase_probe(4096, 20000, 2000)
    var wall = Float64(perf_counter_ns() - t0) / 1000000.0
    print("=" * 68)
    print("NOT PROVEN (no sampling profiler in toolchain): syscalls/msg, cache"
          + " misses, off-CPU wakeup/scheduler overhead.")
    print("CPU time & context switches: measured externally via /proc (see report).")
    print("TOTAL wall time: " + String(wall) + " ms")
    print("DONE")
