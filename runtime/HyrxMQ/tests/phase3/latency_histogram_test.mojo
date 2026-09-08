# Tests for latency histogram percentile computation.
#
# Unit tests for the benchmark helper logic.

from std.collections import List

from hyrx.testing import check

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

    Sorts samples in-place.
    """
    if len(samples) == 0:
        return LatencyStats(0, 0, 0, 0, 0, 0, 0)

    _sort(samples)

    var count = len(samples)
    var p50_idx = count * 50 // 100
    var p95_idx = count * 95 // 100
    var p99_idx = count * 99 // 100
    var p999_idx = count * 999 // 1000

    # Clamp indices.
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

# ---- tests ----

def test_empty_samples() raises:
    """Empty list returns zero stats."""
    var samples = List[Int]()
    var stats = compute_latency_stats(samples^)
    check(stats.count == 0, "L89 expect: stats.count == 0")
    check(stats.p50 == 0, "L90 expect: stats.p50 == 0")

def test_single_sample() raises:
    """Single sample: all percentiles equal to that value."""
    var samples = List[Int]()
    samples.append(42)
    var stats = compute_latency_stats(samples^)
    check(stats.count == 1, "L97 expect: stats.count == 1")
    check(stats.p50 == 42, "L98 expect: stats.p50 == 42")
    check(stats.p95 == 42, "L99 expect: stats.p95 == 42")
    check(stats.p99 == 42, "L100 expect: stats.p99 == 42")
    check(stats.p999 == 42, "L101 expect: stats.p999 == 42")
    check(stats.min_val == 42, "L102 expect: stats.min_val == 42")
    check(stats.max_val == 42, "L103 expect: stats.max_val == 42")

def test_uniform_samples() raises:
    """100 uniform samples [1..100]: percentiles at expected positions."""
    var samples = List[Int]()
    for i in range(1, 101):
        samples.append(i)
    var stats = compute_latency_stats(samples^)
    check(stats.count == 100, "L111 expect: stats.count == 100")
    check(stats.min_val == 1, "L112 expect: stats.min_val == 1")
    check(stats.max_val == 100, "L113 expect: stats.max_val == 100")
    # p50 ≈ 50, p95 ≈ 95, p99 ≈ 99, p99.9 ≈ 99
    check(stats.p50 == 51, "L117 expect: stats.p50 == 51 (samples[count*50//100])")
    check(stats.p95 == 96, "L118 expect: stats.p95 == 96 (samples[count*95//100])")
    check(stats.p99 == 100, "L119 expect: stats.p99 == 100 (samples[count*99//100])")

def test_sorted_input() raises:
    """Already-sorted input produces same result."""
    var samples = List[Int]()
    for i in range(1, 51):
        samples.append(i * 10)
    var stats = compute_latency_stats(samples^)
    check(stats.p50 == 260, "L127 expect: stats.p50 == 260 (samples[25])")
    check(stats.min_val == 10, "L126 expect: stats.min_val == 10")
    check(stats.max_val == 500, "L127 expect: stats.max_val == 500")

def test_reverse_sorted_input() raises:
    """Reverse-sorted input is correctly sorted internally."""
    var samples = List[Int]()
    for i in range(50, 0, -1):
        samples.append(i)
    var stats = compute_latency_stats(samples^)
    check(stats.p50 == 26, "L137 expect: stats.p50 == 26 (samples[25])")
    check(stats.min_val == 1, "L136 expect: stats.min_val == 1")
    check(stats.max_val == 50, "L137 expect: stats.max_val == 50")

def test_two_samples() raises:
    """Two samples: p50 picks the lower."""
    var samples = List[Int]()
    samples.append(10)
    samples.append(20)
    var stats = compute_latency_stats(samples^)
    check(stats.p50 == 20, "L147 expect: stats.p50 == 20 (samples[1])")
    check(stats.max_val == 20, "L146 expect: stats.max_val == 20")

def main() raises:
    print("LATENCY_HISTOGRAM_TEST")
    test_empty_samples()
    test_single_sample()
    test_uniform_samples()
    test_sorted_input()
    test_reverse_sorted_input()
    test_two_samples()
    print("LATENCY_HISTOGRAM_TEST=PASS")
