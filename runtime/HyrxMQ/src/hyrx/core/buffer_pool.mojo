# Bounded, size-classed allocator for Buffer reuse.
#
# The pool keeps per-size-class free lists. `acquire(min_bytes)` returns a usable,
# owned Buffer whose logical length is 0; on reuse it is RESET (stale bytes cleared)
# and tagged with its class. `release(buf)` returns a POOL-OWNED buffer to its own
# class; a non-pooled (directly-allocated) buffer is simply dropped.
#
# Design contracts (see p1b_design.md §3/§8):
#   - acquire NEVER raises and NEVER rejects. Oversize (> largest class) or pool
#     exhaustion => it returns a plain, non-pooled Buffer (caller direct path), so
#     publish semantics are unchanged by allocation state (decision D2).
#   - release is origin-tagged: only buffers this pool handed out are recycled
#     (R3), and each returns to its own size class.
#   - Total pooled buffers is bounded by max_pooled; total pooled bytes by
#     sum(class_bytes). Neither is affected by the direct-alloc fallback.
#
# Ownership model:
#   - acquire() returns an owned Buffer (pooled or direct).
#   - release() takes ownership back into the pool (only if it was pooled).
#
# Implementation note: List[Buffer] is move-only; extraction uses pop() for owned
# values. The origin tag lives on Buffer (`is_pooled`/`pool_class`/`mark_pooled`).

from hyrx.core.buffer import Buffer
from hyrx.core.pool_stats import PoolStats

# Smallest size class (bytes). Payloads below this still get a 128-byte buffer.
def _MIN_CLASS() -> Int:
    return 128

struct BufferPool:
    """Bounded, size-classed allocator for fixed-capacity Buffers."""

    var _class_bytes: List[Int]       # capacity per class (ascending powers of two)
    var _free: List[List[Buffer]]     # per-class free list
    var _max_pooled: Int              # cap on total pooled buffers created
    var _created: Int                 # pooled buffers created so far
    var _in_use: Int                  # pooled buffers currently checked out
    var _alloc_count: Int             # cumulative new creations
    var _reuse_count: Int             # cumulative reuses from a free list
    var _pooled_bytes: Int            # total bytes across pooled buffers (capacity)

    def __init__(out self, max_class_bytes: Int, max_pooled: Int):
        """Initialise an empty, bounded, size-classed pool.

        Arguments:
            max_class_bytes: largest size class; bigger requests get a direct
                (non-pooled) buffer instead.
            max_pooled: upper bound on the number of pooled buffers (resource limit).
        """
        self._class_bytes = List[Int]()
        var cap = _MIN_CLASS()
        while cap < max_class_bytes:
            self._class_bytes.append(cap)
            cap = cap * 2
        self._class_bytes.append(cap)  # largest class >= max_class_bytes

        self._free = List[List[Buffer]]()
        for _ in range(len(self._class_bytes)):
            self._free.append(List[Buffer]())

        self._max_pooled = max_pooled
        self._created = 0
        self._in_use = 0
        self._alloc_count = 0
        self._reuse_count = 0
        self._pooled_bytes = 0

    def _class_index(self, min_bytes: Int) -> Int:
        """Smallest class index with capacity >= min_bytes, or -1 if oversize."""
        if min_bytes <= 0:
            return 0
        for i in range(len(self._class_bytes)):
            if self._class_bytes[i] >= min_bytes:
                return i
        return -1

    # ---- lifecycle ---------------------------------------------------

    def acquire(mut self, min_bytes: Int) -> Buffer:
        """Return an owned, length-0 Buffer sized to hold at least `min_bytes`.

        Reuses a pooled buffer when one of an adequate class is free; otherwise
        creates a pooled buffer while under `max_pooled`; otherwise (oversize or
        exhausted) returns a plain NON-pooled buffer. Never raises.
        """
        var idx = self._class_index(min_bytes)
        if idx >= 0:
            if len(self._free[idx]) > 0:
                var buf = self._free[idx].pop()
                buf.clear()                 # reset logical length -> no stale bytes
                buf.mark_pooled(idx)
                self._in_use = self._in_use + 1
                self._reuse_count = self._reuse_count + 1
                return buf^
            if self._created < self._max_pooled:
                var fresh = Buffer(self._class_bytes[idx])
                fresh.mark_pooled(idx)
                self._created = self._created + 1
                self._pooled_bytes = self._pooled_bytes + self._class_bytes[idx]
                self._in_use = self._in_use + 1
                self._alloc_count = self._alloc_count + 1
                return fresh^
        # Oversize or pool-exhausted: direct allocation, NOT pool-owned.
        var direct = Buffer(min_bytes)
        return direct^

    def release(mut self, var buf: Buffer):
        """Return a Buffer to the pool for reuse if it is pool-owned.

        A non-pooled (direct) buffer is dropped here (freed by its destructor);
        it is never added to a free list. `in_use` only decrements for pooled
        buffers, so it can never underflow via a stray release.
        """
        if not buf.is_pooled():
            return
        var idx = buf.pool_class()
        if idx < 0 or idx >= len(self._class_bytes):
            return  # defensive: a bogus tag must not corrupt bookkeeping
        buf.clear()
        self._in_use = self._in_use - 1
        self._free[idx].append(buf^)

    def stats(self) -> PoolStats:
        """Snapshot of pool allocation statistics (capacity = pooled bytes)."""
        return PoolStats(
            allocations=self._alloc_count,
            reuses=self._reuse_count,
            capacity=self._pooled_bytes,
            in_use=self._in_use,
        )
