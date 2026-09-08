# Fixed-size slab allocator for Buffer reuse.
#
# The pool manages a bounded number of slabs. Each slab holds buffers
# of a uniform size. Releasing a buffer returns it to the pool for
# reuse, avoiding repeated allocation/deallocation overhead.
#
# Ownership model:
#   - acquire() returns an owned Buffer to the caller.
#   - release() takes ownership back into the pool.
#   - Pool slabs own their buffers; the pool owns the slabs.
#
# Implementation note: List[Buffer] requires move-only access.
# All element extraction uses pop() to get owned values.

from hyrx.core.buffer import Buffer
from hyrx.core.pool_stats import PoolStats

struct BufferPool:
    """Bounded slab allocator for fixed-size Buffers."""

    var _slabs: List[List[Buffer]]
    var _slab_size: Int
    var _max_slabs: Int
    var _alloc_count: Int
    var _reuse_count: Int
    var _in_use: Int

    def __init__(out self, slab_size: Int, max_slabs: Int):
        """Initialise an empty pool.

        Arguments:
            slab_size: capacity of each buffer in bytes.
            max_slabs: upper bound on total slab count (resource limit).
        """
        self._slabs = List[List[Buffer]]()
        self._slab_size = slab_size
        self._max_slabs = max_slabs
        self._alloc_count = 0
        self._reuse_count = 0
        self._in_use = 0

    # ---- lifecycle ---------------------------------------------------

    def acquire(mut self) raises -> Buffer:
        """Return an owned Buffer, reusing a released one if available.

        Ownership: the returned Buffer is fully owned by the caller.
        Raises when the pool is exhausted (all slabs full, max reached).
        """
        # Try to pop from the most recent slab first.
        if len(self._slabs) > 0:
            var last_idx = len(self._slabs) - 1
            if len(self._slabs[last_idx]) > 0:
                var buf = self._slabs[last_idx].pop()
                self._reuse_count += 1
                self._in_use += 1
                return buf^

        # No recycled buffers — allocate a new slab if permitted.
        if len(self._slabs) >= self._max_slabs:
            raise "BufferPool: exhausted — max slabs reached"

        var new_slab = List[Buffer]()
        # Pre-allocate 16 buffers for batch allocation.
        for _ in range(16):
            new_slab.append(Buffer(self._slab_size))
        self._slabs.append(new_slab^)

        # Pop one from the newly created slab.
        var slab_len = len(self._slabs) - 1
        var buf = self._slabs[slab_len].pop()
        self._alloc_count += 1
        self._in_use += 1
        return buf^

    def release(mut self, var buf: Buffer):
        """Return a Buffer to the pool for reuse.

        Ownership: the pool takes ownership of the buffer's memory.
        The caller must not use the buffer after release.
        """
        self._in_use -= 1
        # Return to the most recent slab.
        if len(self._slabs) > 0:
            self._slabs[len(self._slabs) - 1].append(buf^)
        else:
            var slab = List[Buffer]()
            slab.append(buf^)
            self._slabs.append(slab^)

    def stats(self) -> PoolStats:
        """Snapshot of pool allocation statistics."""
        var total_capacity = len(self._slabs) * 16 * self._slab_size
        return PoolStats(
            allocations=self._alloc_count,
            reuses=self._reuse_count,
            capacity=total_capacity,
            in_use=self._in_use,
        )
