# Tests for Buffer ownership semantics.
#
# Covers: allocation, ownership transfer (move), snapshot copying, resize,
# and the empirical claim that BufferSnapshot is a COPY, not a borrowed view.

from hyrx.core.buffer import Buffer
from hyrx.core.buffer_snapshot import BufferSnapshot

from hyrx.testing import check

def test_allocate_and_size() raises:
    """Buffer allocates correct capacity, starts at size 0."""
    var buf = Buffer(256)
    check(buf.capacity() == 256, "L11 expect: buf.capacity() == 256")
    check(buf.size() == 0, "L12 expect: buf.size() == 0")

def test_ownership_transfer() raises:
    """Move (^) transfers ownership; source is consumed."""
    var original = Buffer(128)
    check(original.capacity() == 128, "L17 expect: original.capacity() == 128")

    # Move-construct: ownership transfers to `moved`.
    var moved = original^
    check(moved.capacity() == 128, "L21 expect: moved.capacity() == 128")
    check(moved.size() == 0, "L22 expect: moved.size() == 0")
    # `original` is consumed — compiler prevents reuse.

def test_snapshot() raises:
    """Return value of snapshot(): an independent copy of the buffer data."""
    var buf = Buffer(64)
    buf.resize(4)
    buf[0] = 0x01
    buf[1] = 0x02
    buf[2] = 0x03
    buf[3] = 0x04
    var view = buf.snapshot()
    check(view.size() == 4, "L34 expect: view.size() == 4")
    check(view[0] == 0x01, "L35 expect: view[0] == 0x01")
    check(view[3] == 0x04, "L36 expect: view[3] == 0x04")

def _consume_buffer(var b: Buffer) -> Int:
    """Take ownership of `b`; it is destroyed when this function returns."""
    return b.size()

def test_snapshot_survives_origin_mutation() raises:
    """Audit §5/§22 probe, encoded: mutating the Buffer does NOT change the snapshot."""
    var buf = Buffer(8)
    buf.resize(4)
    for i in range(4):
        buf[i] = UInt8(0x10 + i)
    var snap = buf.snapshot()
    for i in range(4):
        buf[i] = 0xFF
    check(snap[0] == 0x10, "snapshot byte 0 must be frozen at copy time")
    check(snap[3] == 0x13, "snapshot byte 3 must be frozen at copy time")
    check(buf[3] == 0xFF, "origin mutation must be visible on the origin")

def test_snapshot_survives_origin_destruction() raises:
    """Audit §5/§22 probe, encoded: the snapshot is readable after the origin is moved away."""
    var buf = Buffer(8)
    buf.resize(2)
    buf[0] = 0xAA
    buf[1] = 0xBB
    var snap = buf.snapshot()
    var size_before = _consume_buffer(buf^)
    check(size_before == 2, "origin must have carried 2 bytes at move time")
    # `buf` is consumed here — no live Buffer backs `snap` any more.
    check(snap.size() == 2, "snapshot must still hold its own 2 bytes")
    check(snap[0] == 0xAA, "snapshot byte 0 must be independently owned")
    check(snap[1] == 0xBB, "snapshot byte 1 must be independently owned")

def test_to_bytes_is_second_copy() raises:
    """Copied again: to_bytes() returns a list independent of the snapshot."""
    var buf = Buffer(8)
    buf.resize(2)
    buf[0] = 0x01
    buf[1] = 0x02
    var snap = buf.snapshot()
    var copy = snap.to_bytes()
    copy[0] = 0x7F
    check(snap[0] == 0x01, "mutating to_bytes() result must not affect the snapshot")

def test_resize_within_capacity() raises:
    """Resize succeeds when new_size <= capacity."""
    var buf = Buffer(100)
    buf.resize(50)
    check(buf.size() == 50, "L42 expect: buf.size() == 50")
    buf.resize(100)
    check(buf.size() == 100, "L44 expect: buf.size() == 100")

def test_resize_exceeds_capacity() raises:
    """Resize raises when new_size > capacity."""
    var buf = Buffer(64)
    var caught = False
    try:
        buf.resize(128)
    except:
        caught = True
    check(caught, "L54 expect: caught")

def test_to_bytes_copy() raises:
    """BufferSnapshot.to_bytes produces an independent owned copy."""
    var buf = Buffer(16)
    buf.resize(4)
    buf[0] = 0xDE
    buf[1] = 0xAD
    buf[2] = 0xBE
    buf[3] = 0xEF
    var view = buf.snapshot()
    var copied = view.to_bytes()
    check(len(copied) == 4, "L66 expect: len(copied) == 4")
    check(copied[0] == 0xDE, "L67 expect: copied[0] == 0xDE")
    check(copied[1] == 0xAD, "L68 expect: copied[1] == 0xAD")
    check(copied[2] == 0xBE, "L69 expect: copied[2] == 0xBE")
    check(copied[3] == 0xEF, "L70 expect: copied[3] == 0xEF")

def main() raises:
    test_allocate_and_size()
    test_ownership_transfer()
    test_snapshot()
    test_snapshot_survives_origin_mutation()
    test_snapshot_survives_origin_destruction()
    test_to_bytes_is_second_copy()
    test_resize_within_capacity()
    test_resize_exceeds_capacity()
    test_to_bytes_copy()
    print("BUFFER_TEST=PASS")
