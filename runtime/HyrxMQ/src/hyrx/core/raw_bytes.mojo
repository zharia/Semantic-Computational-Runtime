# DEPRECATED (0006): RawBytes is superseded by direct unsafe_memcpy between
# List[UInt8].unsafe_ptr() pointers. This module is retained for reference
# only and should not be imported by new code.

from std.collections import List


struct RawBytes:
    """Contiguous byte buffer with batch-copy primitives."""

    var _data: List[UInt8]

    def __init__(out self, capacity: Int):
        """Allocate a new buffer with `capacity` bytes of storage."""
        self._data = List[UInt8](capacity=capacity)

    def __init__(out self, var data: List[UInt8]):
        """Take ownership of an existing list."""
        self._data = data^

    # ---- capacity / size ------------------------------------------------

    def size(self) -> Int:
        return len(self._data)

    def capacity(self) -> Int:
        return self._data.capacity()

    # ---- element access (kept for compatibility) -------------------------

    def __getitem__(self, idx: Int) -> UInt8:
        return self._data[idx]

    def __setitem__(mut self, idx: Int, val: UInt8):
        self._data[idx] = val

    def append(mut self, val: UInt8):
        self._data.append(val)

    # ---- batch operations ------------------------------------------------

    def batch_copy_from_list(mut self, src: List[UInt8]):
        """Fill this buffer from `src` in a single pass.

        Replaces: for i in range(n): result.append(src[i])
        The compiler can elide bounds checks in the tight loop.
        """
        var n = len(src)
        self._data.clear()
        for i in range(n):
            self._data.append(src[i])

    def batch_copy_from_list_at(mut self, src: List[UInt8], offset: Int, count: Int):
        """Copy `count` bytes from `src` starting at `offset` into this buffer."""
        for i in range(count):
            self._data.append(src[offset + i])

    def batch_copy_to_list(self) -> List[UInt8]:
        """Return a new list with all bytes from this buffer."""
        var result = List[UInt8](capacity=len(self._data))
        for i in range(len(self._data)):
            result.append(self._data[i])
        return result^

    def batch_copy_to_list_slice(self, start: Int, count: Int) -> List[UInt8]:
        """Return a new list with `count` bytes from this buffer starting at `start`."""
        var result = List[UInt8](capacity=count)
        for i in range(count):
            result.append(self._data[start + i])
        return result^

    def batch_fill(mut self, val: UInt8, count: Int):
        """Fill with `count` copies of `val`."""
        self._data.clear()
        for _ in range(count):
            self._data.append(val)

    def extend_from(mut self, var other: List[UInt8]):
        """Append all bytes from `other` to this buffer."""
        for i in range(len(other)):
            self._data.append(other[i])

    # ---- O(1) clear / resize --------------------------------------------

    def clear(mut self):
        """Reset logical length to 0, keeping allocated capacity. O(1)."""
        self._data.clear()

    def resize(mut self, new_size: Int) raises:
        """Set the logical size. Fails if new_size > capacity."""
        if new_size > self._data.capacity():
            raise "RawBytes.resize: new_size exceeds capacity"
        # Grow: append zeros
        while len(self._data) < new_size:
            self._data.append(0)
        # Shrink: pop
        while len(self._data) > new_size:
            _ = self._data.pop()

    # ---- take ownership --------------------------------------------------

    def take_list(mut self) -> List[UInt8]:
        """Detach and return the backing list; leave self empty."""
        var out = List[UInt8](capacity=0)
        swap(out, self._data)
        return out^

    def swap_lists(mut self, mut other: RawBytes):
        """Swap backing stores with another RawBytes."""
        swap(self._data, other._data)
