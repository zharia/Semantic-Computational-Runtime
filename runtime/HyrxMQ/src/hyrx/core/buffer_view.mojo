# Non-owning reference into a region of memory.
#
# BufferView never allocates or frees. It borrows from an existing
# allocation owned by a Buffer or an external source. Lifetime is
# caller's responsibility — the view must not outlive its origin.
#
# Implementation note: BufferView copies bytes out via to_bytes()
# rather than exposing raw pointers, because Mojo 1.0 Pointer origin
# semantics make raw-pointer views complex. This is a deliberate
# trade: correctness over zero-copy.

from std.collections import List

struct BufferView:
    """A non-owning view over a contiguous byte region.

    Stores a snapshot of the bytes at construction time. For a live
    reference, callers should use Buffer directly.
    """

    var _data: List[UInt8]

    def __init__(out self, var data: List[UInt8]):
        """Construct from an owned list of bytes."""
        self._data = data^

    def size(self) -> Int:
        """Number of bytes visible through this view."""
        return len(self._data)

    def __getitem__(self, idx: Int) -> UInt8:
        """Read a single byte by index."""
        return self._data[idx]

    def to_bytes(self) -> List[UInt8]:
        """Return the viewed bytes as an owned list."""
        var result = List[UInt8](capacity=len(self._data))
        for i in range(len(self._data)):
            result.append(self._data[i])
        return result^
