# Tests for BufferPool slab allocator.
#
# Covers: acquire/release cycle, reuse tracking, exhaustion.

from hyrx.core.buffer import Buffer
from hyrx.core.buffer_pool import BufferPool

def test_acquire_release() raises:
    """Acquire returns a buffer; release returns it to pool."""
    var pool = BufferPool(slab_size=1024, max_slabs=2)
    var buf = pool.acquire()
    assert buf.capacity() == 1024
    pool.release(buf^)
    var stats = pool.stats()
    assert stats.in_use == 0

def test_reuse_tracking() raises:
    """Released buffers are reused; reuse counter increments."""
    var pool = BufferPool(slab_size=512, max_slabs=1)
    var buf1 = pool.acquire()
    pool.release(buf1^)
    var buf2 = pool.acquire()
    assert buf2.capacity() == 512
    var stats = pool.stats()
    assert stats.reuses == 1
    pool.release(buf2^)

def test_exhaustion() raises:
    """Pool raises when max_slabs is reached and all buffers in use."""
    var pool = BufferPool(slab_size=256, max_slabs=1)
    # Fill the single slab (16 buffers per slab).
    var count = 0
    for _ in range(16):
        var buf = pool.acquire()
        count += 1
        _ = buf^  # keep alive
    # Next acquire should fail — no more slabs allowed.
    var caught = False
    try:
        var extra = pool.acquire()
        pool.release(extra^)
    except:
        caught = True
    assert caught

def test_stats_after_activity() raises:
    """Stats reflect cumulative allocations and reuses."""
    var pool = BufferPool(slab_size=128, max_slabs=2)
    var a = pool.acquire()
    var b = pool.acquire()
    pool.release(a^)
    var c = pool.acquire()  # reuse from a
    var stats = pool.stats()
    assert stats.allocations >= 1
    assert stats.reuses >= 1
    assert stats.in_use == 2
    pool.release(b^)
    pool.release(c^)

def main() raises:
    test_acquire_release()
    test_reuse_tracking()
    test_exhaustion()
    test_stats_after_activity()
    print("BUFFER_POOL_TEST=PASS")
