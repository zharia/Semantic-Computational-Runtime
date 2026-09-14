# M9 — In-process performance soak test for HyrxMQ.
#
# MEMORY-CONSCIOUS: bounded capacity (1000), max 5000 messages, 32-byte payloads.
# In-process broker only (no TCP). Completes within 10 seconds.

from std.collections import List
from std.time import monotonic

from hyrxmq.config import HyrxMQConfig
from hyrxmq.broker import HyrxMQBroker
from hyrx.core.exchange import HeaderArgs


# ---- latency stats (copied from phase3 to avoid cross-module import) ----

struct LatencyStats:
    """Percentile statistics from a sorted latency sample list."""

    var p50: Int
    var p95: Int
    var p99: Int
    var p999: Int
    var min_val: Int
    var max_val: Int
    var count: Int

    def __init__(
        out self,
        p50: Int,
        p95: Int,
        p99: Int,
        p999: Int,
        min_val: Int,
        max_val: Int,
        count: Int,
    ):
        self.p50 = p50
        self.p95 = p95
        self.p99 = p99
        self.p999 = p999
        self.min_val = min_val
        self.max_val = max_val
        self.count = count


def _sort(mut lst: List[Int]):
    """Insertion sort — sufficient for benchmark sample sizes."""
    var n = len(lst)
    for i in range(1, n):
        var key = lst[i]
        var j = i - 1
        while j >= 0 and lst[j] > key:
            lst[j + 1] = lst[j]
            j -= 1
        lst[j + 1] = key


def compute_latency_stats(var samples: List[Int]) -> LatencyStats:
    """Compute percentiles from a list of latency samples (nanoseconds).
    Sorts samples in-place."""
    if len(samples) == 0:
        return LatencyStats(0, 0, 0, 0, 0, 0, 0)

    _sort(samples)

    var count = len(samples)
    var p50_idx = count * 50 // 100
    var p95_idx = count * 95 // 100
    var p99_idx = count * 99 // 100
    var p999_idx = count * 999 // 1000

    if p50_idx >= count:
        p50_idx = count - 1
    if p95_idx >= count:
        p95_idx = count - 1
    if p99_idx >= count:
        p99_idx = count - 1
    if p999_idx >= count:
        p999_idx = count - 1

    return LatencyStats(
        samples[p50_idx],
        samples[p95_idx],
        samples[p99_idx],
        samples[p999_idx],
        samples[0],
        samples[count - 1],
        count,
    )


# ---- soak test ----

def main() raises:
    print("SOAK_TEST")

    # ---- config: small bounded capacity (1000) ----
    var cfg = HyrxMQConfig()
    cfg.default_queue_capacity = 1000
    var broker = HyrxMQBroker(cfg^)
    broker.start()

    # ---- topology ----
    _ = broker.declare_exchange("soak-ex", "direct")
    _ = broker.declare_queue("soak-q")
    _ = broker.bind_queue("soak-q", "soak-ex", "soak", HeaderArgs())

    var cid = broker.consume_register("soak-q")

    # ---- soak loop: max 5000 messages or 10 seconds ----
    var soak_limit_ns: Int = 10_000_000_000  # 10 seconds
    var max_messages: Int = 5000
    var msgs_published: Int = 0
    var msgs_delivered: Int = 0

    var publish_latencies = List[Int]()
    var deliver_latencies = List[Int]()

    var t_start = monotonic()

    while msgs_published < max_messages:
        # Time check
        if monotonic() - t_start >= soak_limit_ns:
            break

        # 32-byte body (tiny payloads per spec)
        var body = List[UInt8]()
        for i in range(32):
            body.append(0xAA)

        # Publish with latency recording
        var t0 = monotonic()
        _ = broker.publish("soak-ex", "soak", body^)
        var pub_us = Int((monotonic() - t0) // 1000)
        publish_latencies.append(pub_us)
        msgs_published += 1

        # Deliver with latency recording
        var t1 = monotonic()
        var d = broker.deliver(cid)
        var del_us = Int((monotonic() - t1) // 1000)

        if d.__bool__():
            var tag = d.value().delivery_tag()
            _ = broker.ack(cid, tag)
            deliver_latencies.append(del_us)
            msgs_delivered += 1

    # ---- compute stats ----
    var t_end = monotonic()
    var soak_duration_ms = Int((t_end - t_start) // 1_000_000)

    var pub_stats = compute_latency_stats(publish_latencies^)
    var del_stats = compute_latency_stats(deliver_latencies^)

    var throughput: Float64 = 0.0
    if soak_duration_ms > 0:
        throughput = Float64(msgs_published) * 1000.0 / Float64(soak_duration_ms)

    # ---- print summary ----
    print("SOAK_DURATION_MS=" + String(soak_duration_ms))
    print("MSGS_PUBLISHED=" + String(msgs_published))
    print("MSGS_DELIVERED=" + String(msgs_delivered))
    print("THROUGHPUT_MSGS_PER_SEC=" + String(Int(throughput)))
    print("PUB_LATENCY_P50_US=" + String(pub_stats.p50))
    print("PUB_LATENCY_P95_US=" + String(pub_stats.p95))
    print("PUB_LATENCY_P99_US=" + String(pub_stats.p99))
    print("PUB_LATENCY_P999_US=" + String(pub_stats.p999))
    print("PUB_LATENCY_MIN_US=" + String(pub_stats.min_val))
    print("PUB_LATENCY_MAX_US=" + String(pub_stats.max_val))
    print("DEL_LATENCY_P50_US=" + String(del_stats.p50))
    print("DEL_LATENCY_P95_US=" + String(del_stats.p95))
    print("DEL_LATENCY_P99_US=" + String(del_stats.p99))

    # ---- pass criteria ----
    var soak_pass = True

    if throughput < 5000.0:
        print("FAIL: throughput " + String(Int(throughput)) + " < 5000 msgs/sec")
        soak_pass = False

    broker.shutdown()

    if soak_pass:
        print("SOAK_TEST=PASS")
    else:
        print("SOAK_TEST=FAIL")
        raise "SOAK_TEST=FAIL"
