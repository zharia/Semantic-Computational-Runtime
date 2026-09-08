# P1b P4: measure pooled vs direct buffer allocation under a steady
# publish -> consume -> ack cycle (so pooled buffers are actually recycled).
# The existing fan-out bench never consumes, so it cannot show reuse.
#
# For each payload size: run N cycles fanning out to D queues, consuming and
# acking each so every cycle returns its buffers to the pool. Compare mean
# ns/cycle with the pool OFF (direct alloc/free) vs ON (size-classed reuse).
#
# Run:  pixi run mojo run -I src -I vendor/flare benchmarks/pool_ab.mojo

from std.time import perf_counter_ns
from std.collections import List, Dict

from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import ExchangeType
from hyrx.core.router import Router


def _mk(seq: Int, n: Int) raises -> Message:
    var h = Dict[String, String]()
    var env = Envelope(MessageID(UInt64(seq)), "k", h^)
    var b = Buffer(n)
    b.resize(n)
    for i in range(n):
        b[i] = UInt8((seq + i) & 0xFF)
    return Message(env^, b^)


def _run(pool_enabled: Bool, dests: Int, payload: Int, cycles: Int) raises -> Float64:
    var router = Router(65536, 4096, pool_enabled)
    router.declare_exchange("f", ExchangeType.fanout())
    var cids = List[UInt64]()
    for q in range(dests):
        var nm = "q" + String(q)
        router.declare_queue(nm, 4096)
        router.bind_queue(nm, "f", "")
        cids.append(router.register_consumer(nm, 0))

    # warm-up: fill free lists (pooled) / prime allocator (direct)
    for w in range(300):
        var mw = _mk(w, payload)
        _ = router.publish(mw^, "f")
        for c in range(len(cids)):
            var dw = router.consume(cids[c])
            if dw.__bool__():
                _ = router.acknowledge(cids[c], dw.value().delivery_tag())

    var t0 = perf_counter_ns()
    for i in range(cycles):
        var m = _mk(i, payload)
        _ = router.publish(m^, "f")
        for c in range(len(cids)):
            var d = router.consume(cids[c])
            if d.__bool__():
                _ = router.acknowledge(cids[c], d.value().delivery_tag())
    var t1 = perf_counter_ns()
    _ = router.pool_stats().in_use  # must be 0 (steady state)
    return Float64(t1 - t0) / Float64(cycles)


def main() raises:
    var dests = 8
    var cycles = 3000
    var payloads = List[Int]()
    payloads.append(64)
    payloads.append(256)
    payloads.append(4096)
    payloads.append(16384)

    print("P1b pooled-vs-direct  (dests=" + String(dests) + ", cycles=" + String(cycles)
          + ", publish+consume+ack each cycle)")
    print("payload  |  direct ns/cycle  |  pooled ns/cycle  |  speedup")
    for pi in range(len(payloads)):
        var p = payloads[pi]
        var off = _run(False, dests, p, cycles)
        var on = _run(True, dests, p, cycles)
        print(String(p) + "B", off, on, off / on)
