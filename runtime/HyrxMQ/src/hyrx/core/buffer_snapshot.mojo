# Owned byte snapshot: a copy of a region of bytes taken at construction.
#
# BufferSnapshot is NOT a view. It owns the bytes it holds: the source
# bytes are copied in at construction time and the snapshot keeps them
# alive independently of the origin (Buffer, Message payload, ...).
# Dropping or mutating the origin after construction has NO effect on a
# BufferSnapshot — verified empirically (docs/MEMORY_MODEL.md §Probe).
#
# Ownership model:
#   - Construction from `List[UInt8]` takes ownership of that list (move).
#     Callers that build a snapshot from a live Buffer copy bytes out first
#     (see `Buffer.snapshot()`), so the snapshot owns its own allocation.
#   - `to_bytes()` returns a SECOND owned copy of the snapshot's bytes.
#   - The snapshot itself is freed when it goes out of scope.
#
# Rationale: Mojo 1.0 Pointer origin semantics make raw-pointer views
# awkward, so this type deliberately trades zero-copy for an honest,
# self-contained copy. The name says what it is: a snapshot, not a view.

from std.collections import List
from std.memory import unsafe_memcpy
from hyrx.core.feature_flags import contiguous_batch_enabled

struct BufferSnapshot:
    """An owned copy of a contiguous byte region.

    Stores a copy of the bytes at construction time. It is not a
    borrowed reference and imposes no lifetime constraint on the
    origin it came from. For a live, mutable reference, use Buffer
    directly.
    """

    var _data: List[UInt8]

    def __init__(out self, var data: List[UInt8]):
        """Construct by taking ownership of `data` (moved in).

        Ownership: the bytes are owned by this snapshot after the move.
        """
        self._data = data^

    def size(self) -> Int:
        """Number of bytes held in this snapshot."""
        return len(self._data)

    def __getitem__(self, idx: Int) -> UInt8:
        """Read a single byte by index."""
        return self._data[idx]

    def to_bytes(self) -> List[UInt8]:
        """Return an independent owned copy of the snapshot's bytes.

        Ownership: the returned list is a second copy; mutating or
        dropping it does not affect this snapshot (or vice versa).
        """
        if contiguous_batch_enabled():
            return self._data.copy()
        else:
            var result = List[UInt8](capacity=len(self._data))
            for i in range(len(self._data)):
                result.append(self._data[i])
            return result^

    def take_bytes(mut self) -> List[UInt8]:
        """Detach and return the snapshot's bytes; leave self empty.

        Ownership: the returned list IS the snapshot's backing storage.
        No copy — the snapshot is consumed. Use when the caller needs
        the bytes and the snapshot is no longer needed.
        """
        var out = List[UInt8](capacity=0)
        swap(out, self._data)
        return out^
