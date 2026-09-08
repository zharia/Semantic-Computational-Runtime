# Tests for Buffer ownership semantics.
#
# Covers: allocation, ownership transfer (move), view creation, resize.

from hyrx.core.buffer import Buffer
from hyrx.core.buffer_view import BufferView

def test_allocate_and_size() raises:
    """Buffer allocates correct capacity, starts at size 0."""
    var buf = Buffer(256)
    assert buf.capacity() == 256
    assert buf.size() == 0

def test_ownership_transfer() raises:
    """Move (^) transfers ownership; source is consumed."""
    var original = Buffer(128)
    assert original.capacity() == 128

    # Move-construct: ownership transfers to `moved`.
    var moved = original^
    assert moved.capacity() == 128
    assert moved.size() == 0
    # `original` is consumed — compiler prevents reuse.

def test_as_view() raises:
    """View contains a copy of the buffer data."""
    var buf = Buffer(64)
    buf.resize(4)
    buf[0] = 0x01
    buf[1] = 0x02
    buf[2] = 0x03
    buf[3] = 0x04
    var view = buf.as_view()
    assert view.size() == 4
    assert view[0] == 0x01
    assert view[3] == 0x04

def test_resize_within_capacity() raises:
    """Resize succeeds when new_size <= capacity."""
    var buf = Buffer(100)
    buf.resize(50)
    assert buf.size() == 50
    buf.resize(100)
    assert buf.size() == 100

def test_resize_exceeds_capacity() raises:
    """Resize raises when new_size > capacity."""
    var buf = Buffer(64)
    var caught = False
    try:
        buf.resize(128)
    except:
        caught = True
    assert caught

def test_to_bytes_copy() raises:
    """BufferView.to_bytes produces an independent owned copy."""
    var buf = Buffer(16)
    buf.resize(4)
    buf[0] = 0xDE
    buf[1] = 0xAD
    buf[2] = 0xBE
    buf[3] = 0xEF
    var view = buf.as_view()
    var copied = view.to_bytes()
    assert len(copied) == 4
    assert copied[0] == 0xDE
    assert copied[1] == 0xAD
    assert copied[2] == 0xBE
    assert copied[3] == 0xEF

def main() raises:
    test_allocate_and_size()
    test_ownership_transfer()
    test_as_view()
    test_resize_within_capacity()
    test_resize_exceeds_capacity()
    test_to_bytes_copy()
    print("BUFFER_TEST=PASS")
