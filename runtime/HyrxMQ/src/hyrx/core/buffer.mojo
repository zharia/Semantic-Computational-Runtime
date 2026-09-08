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
    var _pooled: Bool
    var _pool_class: Int

    def __init__(out self, capacity: Int):
        """Allocate a new owned buffer of `capacity` bytes.

        Ownership: memory is allocated and owned by this Buffer.
        A directly-constructed Buffer is NOT pool-owned (`_pooled=false`);
        only `BufferPool.acquire` marks a buffer pooled (see `mark_pooled`).
        """
        self._data = List[UInt8](capacity=capacity)
        self._pooled = False
        self._pool_class = -1

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

    def append(mut self, val: UInt8):
        """Append one byte (grows logical length by 1).

        Used by the pooled copy path (`Message.payload_into`) to fill a
        length-0 pooled buffer in a single pass. The caller sizes the buffer
        to the payload first, so this never exceeds the intended length.
        """
        self._data.append(val)

    # ---- copy + mutations ------------------------------------------------

    @staticmethod
    def from_buffer_copy(ref source: Buffer) -> Buffer:
        """Return one owned, exact-length copy of ``source``.

        The destination is allocated at the source's logical size and filled by
        one append pass.  It deliberately does not call ``resize()`` first, so
        the copy path does not zero-fill then overwrite the same bytes.
        """
        var result = Buffer(source.size())
        for i in range(source.size()):
            result._data.append(source[i])
        return result^

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

    # ---- pool origin tag (used by BufferPool; see buffer_pool.mojo) ----

    def clear(mut self):
        """Reset logical length to 0, keeping allocated capacity. Never raises.

        Uses List.clear() (O(1), retains capacity) — NOT a pop-loop, which would
        make every acquire/release an O(payload) scan and erase the pool's benefit.
        """
        self._data.clear()

    def is_pooled(self) -> Bool:
        """Whether this buffer was acquired from a BufferPool (else direct)."""
        return self._pooled

    def pool_class(self) -> Int:
        """The pool size-class index this buffer belongs to, or -1 if not pooled."""
        return self._pool_class

    def mark_pooled(mut self, cls: Int):
        """Pool-internal: record that this buffer belongs to size-class `cls`.

        Called only by BufferPool.acquire. Sets the origin tag so that release
        at a message-death site returns exactly this buffer to its own class and
        never pools a directly-allocated (non-pooled) buffer.
        """
        self._pooled = True
        self._pool_class = cls

    def take_data(mut self) -> Buffer:
        """Detach this buffer's contents into a fresh owned Buffer; leave self empty.

        Mojo forbids moving a field out of a struct that will be dropped, so the
        contents are SWAPPED into the returned buffer and self is left as an empty,
        non-pooled buffer that drops harmlessly. Used by the pool-reclaim path
        (Message.take_payload -> BufferPool.release). The returned buffer carries
        this buffer's origin tag, so release recycles it iff it was pooled.
        """
        var out = Buffer(0)
        swap(out._data, self._data)
        swap(out._pooled, self._pooled)
        swap(out._pool_class, self._pool_class)
        return out^
