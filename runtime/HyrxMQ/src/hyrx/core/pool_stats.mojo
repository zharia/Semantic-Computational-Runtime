# Allocation statistics for a BufferPool.
#
# Pure data, no ownership semantics. Used for diagnostics only.

struct PoolStats:
    """Snapshot of pool allocation activity."""

    var allocations: Int
    var reuses: Int
    var capacity: Int
    var in_use: Int

    def __init__(
        out self,
        allocations: Int,
        reuses: Int,
        capacity: Int,
        in_use: Int,
    ):
        self.allocations = allocations
        self.reuses = reuses
        self.capacity = capacity
        self.in_use = in_use
