# Tests for the size-classed BufferPool.
#
# Covers: class selection, reset-on-reuse, in_use balance, oversize direct
# fallback, exhaustion direct fallback, reuse counting and release no-op.

from std.collections import List

from hyrx.core.buffer import Buffer
from hyrx.core.buffer_pool import BufferPool
from hyrx.testing import check

def test_class_selection_pooled() raises:
    """acquire(200) on a 4096 pool lands in the 256 class, pooled, length 0."""
    var pool = BufferPool(max_class_bytes=4096, max_pooled=64)
    var b = pool.acquire(200)
    check(b.is_pooled(), "expect: b.is_pooled()")
    check(b.size() == 0, "expect: b.size() == 0")
    check(b.capacity() >= 256, "expect: b.capacity() >= 256 (256 class)")
    check(b.capacity() < 512, "expect: b.capacity() < 512 (not 512 class)")
    pool.release(b^)

def test_reset_no_stale() raises:
    """A reused buffer is reset: stale logical length must not survive."""
    var pool = BufferPool(2048, 16)
    var b1 = pool.acquire(1024)
    b1.resize(600)
    check(b1.size() == 600, "expect: b1.size() == 600 after resize")
    pool.release(b1^)
    var b2 = pool.acquire(1024)
    check(b2.size() == 0, "expect: b2.size() == 0 (reuse resets length)")
    check(b2.is_pooled(), "expect: b2.is_pooled()")
    pool.release(b2^)

def test_balance_in_use_zero() raises:
    """in_use tracks live pooled buffers; drains back to 0."""
    var pool = BufferPool(1024, 32)
    var held = List[Buffer]()
    for _ in range(10):
        held.append(pool.acquire(100)^)
    check(pool.stats().in_use == 10, "expect: in_use == 10 while held")
    while len(held) > 0:
        var x = held.pop()
        pool.release(x^)
    check(pool.stats().in_use == 0, "expect: in_use == 0 after drain")

def test_oversize_direct() raises:
    """min_bytes above the largest class yields a direct, non-pooled buffer."""
    var pool = BufferPool(1024, 8)
    var b = pool.acquire(4096)
    check(not b.is_pooled(), "expect: oversize b is not pooled")
    check(b.capacity() >= 4096, "expect: b.capacity() >= 4096")
    pool.release(b^)
    check(pool.stats().in_use == 0, "expect: release of direct buffer is a no-op")

def test_exhaustion_direct() raises:
    """Exhausted pool yields a direct buffer, never raises; freed slot reuses."""
    var pool = BufferPool(512, 2)
    var a1 = pool.acquire(100)
    var a2 = pool.acquire(100)
    check(a1.is_pooled(), "expect: a1.is_pooled()")
    check(a2.is_pooled(), "expect: a2.is_pooled()")
    var a3 = pool.acquire(100)
    check(not a3.is_pooled(), "expect: exhausted a3 is direct")
    check(pool.stats().in_use == 2, "expect: in_use == 2 (a3 not counted)")
    pool.release(a1^)
    var a4 = pool.acquire(100)
    check(a4.is_pooled(), "expect: a4 reuses freed a1 slot")
    pool.release(a2^)
    pool.release(a3^)
    pool.release(a4^)

def test_reuse_and_release_nop() raises:
    """Reuse counter increments; releasing a foreign Buffer is bookkeeping-safe."""
    var pool = BufferPool(256, 4)
    var r1 = pool.acquire(128)
    pool.release(r1^)
    var r2 = pool.acquire(128)
    check(pool.stats().reuses >= 1, "expect: reuses >= 1")
    pool.release(r2^)
    var direct = Buffer(100)
    check(not direct.is_pooled(), "expect: Buffer(100) is not pooled")
    pool.release(direct^)
    check(pool.stats().in_use == 0, "expect: in_use == 0 after direct release")

def main() raises:
    test_class_selection_pooled()
    test_reset_no_stale()
    test_balance_in_use_zero()
    test_oversize_direct()
    test_exhaustion_direct()
    test_reuse_and_release_nop()
    print("BUFFER_POOL_TEST=PASS")
