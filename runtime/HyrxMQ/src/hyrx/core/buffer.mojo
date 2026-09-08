# Contiguous byte buffer with explicit ownership tracking.
#
# Ownership model:
#   - A Buffer always owns its memory (list allocation).
#   - Move transfers ownership: source is consumed, cannot be reused.
#   - Buffer.snapshot() COPIES the bytes; the returned snapshot is owned
#     by the caller and is unaffected by later mutation or destruction
#     of this Buffer.
#   - There is no borrowed view type in this module.
#
# Mojo move semantics (^) handle ownership transfer automatically:
#   var b = a^  →  a is consumed, b owns the memory, a.__deinit__ not called.
#
# Allocation is bounded by the caller-provided capacity.
# No implicit growth — resize is explicit and can fail.
#
# Implementation: uses List[UInt8] as backing store for portable
# Mojo 1.0 compatibility. The List manages element count directly.

from std.collections import List

from hyrx.core.buffer_snapshot import BufferSnapshot

struct Buffer:
    """A contiguous byte region with ownership semantics."""

    var _data: List[UInt8]

    def __init__(out self, capacity: Int):
        """Allocate a new owned buffer of `capacity` bytes.

        Ownership: memory is allocated and owned by this Buffer.
        """
        self._data = List[UInt8](capacity=capacity)

    def __deinit__(deinit self):
        """Release memory. Called only when this Buffer is consumed/destroyed.

        Ownership: after a move (var b = a^), the source's __deinit__
        is NOT called, so no double-free occurs.
        """
        pass

    # ---- accessors ---------------------------------------------------

    def size(self) -> Int:
        """Current logical size in bytes."""
        return len(self._data)

    def capacity(self) -> Int:
        """Total allocated capacity in bytes."""
        return self._data.capacity()

    def __getitem__(self, idx: Int) -> UInt8:
        """Read a single byte by index."""
        return self._data[idx]

    def __setitem__(mut self, idx: Int, val: UInt8):
        """Write a single byte by index."""
        self._data[idx] = val

    # ---- copy + mutations ------------------------------------------------

    def snapshot(ref self) -> BufferSnapshot:
        """Return an owned COPY of the current contents.

        Ownership: every byte is copied into the returned snapshot.
        The snapshot stays valid (and frozen at this moment's values)
        even if this Buffer is later mutated, moved or destroyed.
        This is not a borrowed view — see `BufferSnapshot`.
        """
        var snapshot = List[UInt8](capacity=len(self._data))
        for i in range(len(self._data)):
            snapshot.append(self._data[i])
        return BufferSnapshot(snapshot^)

    def resize(mut self, new_size: Int) raises:
        """Set the logical size. Fails if new_size > capacity.

        Ownership: no change — this Buffer still owns its memory.
        When growing, new bytes are zero-initialized.
        """
        if new_size > self._data.capacity():
            raise "resize: new_size exceeds capacity"
        # Grow: append zero bytes to reach new_size.
        while len(self._data) < new_size:
            self._data.append(0)
        # Shrink: remove trailing bytes.
        while len(self._data) > new_size:
            _ = self._data.pop()
