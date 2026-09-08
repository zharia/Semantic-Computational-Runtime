# Tests for Queue semantics.
#
# Covers: enqueue/dequeue, backpressure, ack removes from unacked,
# reject requeues, ordering preserved.

from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.queue import Queue, QueueConfig, Delivery

def _make_msg(key: String, val: UInt8) raises -> Message:
    """Helper: create a message with a single-byte payload."""
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(UInt64(val)), key, headers^)
    var buf = Buffer(8)
    buf.resize(1)
    buf[0] = val
    return Message(env^, buf^)

def test_enqueue_dequeue() raises:
    """Basic enqueue and dequeue flow."""
    var q = Queue("test", QueueConfig(10))
    assert q.depth() == 0

    assert q.enqueue(_make_msg("key1", 0x01)^) == True
    assert q.depth() == 1

    var delivery = q.dequeue()
    assert delivery.__bool__()
    assert delivery.value().delivery_tag() == 0
    assert q.depth() == 0
    assert q.unacked_count() == 1

def test_backpressure() raises:
    """Queue returns False when at capacity."""
    var q = Queue("test", QueueConfig(2))
    assert q.enqueue(_make_msg("a", 1)^) == True
    assert q.enqueue(_make_msg("b", 2)^) == True
    # Queue full (capacity=2, depth=2)
    assert q.enqueue(_make_msg("c", 3)^) == False
    assert q.depth() == 2

    # After dequeue, one slot opens
    _ = q.dequeue()
    assert q.enqueue(_make_msg("c", 3)^) == True

def test_acknowledge() raises:
    """Acknowledge removes message from unacked."""
    var q = Queue("test", QueueConfig(10))
    _ = q.enqueue(_make_msg("key", 0xAA)^)

    var delivery = q.dequeue()
    assert delivery.__bool__()
    var tag = delivery.value().delivery_tag()

    assert q.unacked_count() == 1
    assert q.acknowledge(tag) == True
    assert q.unacked_count() == 0

    # Ack non-existing tag
    assert q.acknowledge(999) == False

def test_reject_requeues() raises:
    """Reject moves message back to pending queue."""
    var q = Queue("test", QueueConfig(10))
    _ = q.enqueue(_make_msg("key", 0xBB)^)

    var delivery = q.dequeue()
    assert delivery.__bool__()
    var tag = delivery.value().delivery_tag()
    assert q.depth() == 0
    assert q.unacked_count() == 1

    assert q.reject(tag) == True
    assert q.unacked_count() == 0
    assert q.depth() == 1  # Requeued

    # Can dequeue again
    var delivery2 = q.dequeue()
    assert delivery2.__bool__()
    assert delivery2.value().delivery_tag() == 1  # New tag

    assert q.reject(999) == False

def test_ordering_preserved() raises:
    """FIFO ordering is maintained across enqueue/dequeue."""
    var q = Queue("test", QueueConfig(10))
    _ = q.enqueue(_make_msg("first", 1)^)
    _ = q.enqueue(_make_msg("second", 2)^)
    _ = q.enqueue(_make_msg("third", 3)^)

    var d1 = q.dequeue()
    var d2 = q.dequeue()
    var d3 = q.dequeue()

    assert d1.__bool__()
    assert d2.__bool__()
    assert d3.__bool__()

    # Check payload values to verify ordering
    var v1 = q.read_payload(d1.value().delivery_tag())
    var v2 = q.read_payload(d2.value().delivery_tag())
    var v3 = q.read_payload(d3.value().delivery_tag())
    assert v1[0] == 1
    assert v2[0] == 2
    assert v3[0] == 3

    # Ack all
    assert q.acknowledge(d1.value().delivery_tag())
    assert q.acknowledge(d2.value().delivery_tag())
    assert q.acknowledge(d3.value().delivery_tag())
    assert q.unacked_count() == 0

def test_dequeue_empty() raises:
    """Dequeue returns None on empty queue."""
    var q = Queue("test", QueueConfig(10))
    var delivery = q.dequeue()
    assert not delivery.__bool__()

def test_read_payload() raises:
    """Read payload returns the correct data."""
    var q = Queue("test", QueueConfig(10))
    _ = q.enqueue(_make_msg("key", 0xCC)^)

    var delivery = q.dequeue()
    assert delivery.__bool__()
    var view = q.read_payload(delivery.value().delivery_tag())
    assert view.size() == 1
    assert view[0] == 0xCC

    assert q.acknowledge(delivery.value().delivery_tag())

def test_reject_redeliver() raises:
    """Rejected message is redelivered with incremented delivery count."""
    var q = Queue("test", QueueConfig(10))
    _ = q.enqueue(_make_msg("key", 0xDD)^)

    var d1 = q.dequeue()
    assert d1.__bool__()
    var tag1 = d1.value().delivery_tag()
    assert q.reject(tag1)

    var d2 = q.dequeue()
    assert d2.__bool__()
    assert q.acknowledge(d2.value().delivery_tag())

def main() raises:
    test_enqueue_dequeue()
    test_backpressure()
    test_acknowledge()
    test_reject_requeues()
    test_ordering_preserved()
    test_dequeue_empty()
    test_read_payload()
    test_reject_redeliver()
    print("QUEUE_TEST=PASS")
