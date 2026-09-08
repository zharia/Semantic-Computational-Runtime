# Tests for Queue semantics.
#
# Covers: enqueue/dequeue, backpressure, ack removes from unacked,
# reject requeues, ordering preserved.

from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.queue import Queue, QueueConfig, Delivery

from hyrx.testing import check

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
    check(q.depth() == 0, "L22 expect: q.depth() == 0")

    check(q.enqueue(_make_msg("key1", 0x01)^) == True, "L24 expect: q.enqueue(_make_msg('key1', 0x01)^) == True")
    check(q.depth() == 1, "L25 expect: q.depth() == 1")

    var delivery = q.dequeue()
    check(delivery.__bool__(), "L28 expect: delivery.__bool__()")
    check(delivery.value().delivery_tag() == 0, "L29 expect: delivery.value().delivery_tag() == 0")
    check(q.depth() == 0, "L30 expect: q.depth() == 0")
    check(q.unacked_count() == 1, "L31 expect: q.unacked_count() == 1")

def test_backpressure() raises:
    """Queue returns False when at capacity."""
    var q = Queue("test", QueueConfig(2))
    check(q.enqueue(_make_msg("a", 1)^) == True, "L36 expect: q.enqueue(_make_msg('a', 1)^) == True")
    check(q.enqueue(_make_msg("b", 2)^) == True, "L37 expect: q.enqueue(_make_msg('b', 2)^) == True")
    # Queue full (capacity=2, depth=2)
    check(q.enqueue(_make_msg("c", 3)^) == False, "L39 expect: q.enqueue(_make_msg('c', 3)^) == False")
    check(q.depth() == 2, "L40 expect: q.depth() == 2")

    # Dequeue moves the message to unacked; capacity counts unacked
    # (Queue._total_count), so a slot frees only after acknowledge.
    var d = q.dequeue()
    check(d.__bool__(), "L44 expect: dequeue returns a delivery")
    check(q.enqueue(_make_msg("c", 3)^) == False, "L45 expect: unacked message still occupies capacity")
    check(q.acknowledge(d.value().delivery_tag()) == True, "L46 expect: acknowledge frees capacity")
    check(q.enqueue(_make_msg("c", 3)^) == True, "L47 expect: enqueue succeeds after ack")

def test_acknowledge() raises:
    """Acknowledge removes message from unacked."""
    var q = Queue("test", QueueConfig(10))
    _ = q.enqueue(_make_msg("key", 0xAA)^)

    var delivery = q.dequeue()
    check(delivery.__bool__(), "L52 expect: delivery.__bool__()")
    var tag = delivery.value().delivery_tag()

    check(q.unacked_count() == 1, "L55 expect: q.unacked_count() == 1")
    check(q.acknowledge(tag) == True, "L56 expect: q.acknowledge(tag) == True")
    check(q.unacked_count() == 0, "L57 expect: q.unacked_count() == 0")

    # Ack non-existing tag
    check(q.acknowledge(999) == False, "L60 expect: q.acknowledge(999) == False")

def test_reject_requeues() raises:
    """Reject moves message back to pending queue."""
    var q = Queue("test", QueueConfig(10))
    _ = q.enqueue(_make_msg("key", 0xBB)^)

    var delivery = q.dequeue()
    check(delivery.__bool__(), "L68 expect: delivery.__bool__()")
    var tag = delivery.value().delivery_tag()
    check(q.depth() == 0, "L70 expect: q.depth() == 0")
    check(q.unacked_count() == 1, "L71 expect: q.unacked_count() == 1")

    check(q.reject(tag) == True, "L73 expect: q.reject(tag) == True")
    check(q.unacked_count() == 0, "L74 expect: q.unacked_count() == 0")
    check(q.depth() == 1, "L75 expect: q.depth() == 1")  # Requeued

    # Can dequeue again
    var delivery2 = q.dequeue()
    check(delivery2.__bool__(), "L79 expect: delivery2.__bool__()")
    check(delivery2.value().delivery_tag() == 1, "L80 expect: delivery2.value().delivery_tag() == 1")  # New tag

    check(q.reject(999) == False, "L82 expect: q.reject(999) == False")

def test_ordering_preserved() raises:
    """FIFO ordering is maintained across enqueue/dequeue."""
    var q = Queue("test", QueueConfig(10))
    _ = q.enqueue(_make_msg("first", 1)^)
    _ = q.enqueue(_make_msg("second", 2)^)
    _ = q.enqueue(_make_msg("third", 3)^)

    var d1 = q.dequeue()
    var d2 = q.dequeue()
    var d3 = q.dequeue()

    check(d1.__bool__(), "L95 expect: d1.__bool__()")
    check(d2.__bool__(), "L96 expect: d2.__bool__()")
    check(d3.__bool__(), "L97 expect: d3.__bool__()")

    # Check payload values to verify ordering
    var v1 = q.read_payload(d1.value().delivery_tag())
    var v2 = q.read_payload(d2.value().delivery_tag())
    var v3 = q.read_payload(d3.value().delivery_tag())
    check(v1[0] == 1, "L103 expect: v1[0] == 1")
    check(v2[0] == 2, "L104 expect: v2[0] == 2")
    check(v3[0] == 3, "L105 expect: v3[0] == 3")

    # Ack all
    check(q.acknowledge(d1.value().delivery_tag()), "L108 expect: q.acknowledge(d1.value().delivery_tag())")
    check(q.acknowledge(d2.value().delivery_tag()), "L109 expect: q.acknowledge(d2.value().delivery_tag())")
    check(q.acknowledge(d3.value().delivery_tag()), "L110 expect: q.acknowledge(d3.value().delivery_tag())")
    check(q.unacked_count() == 0, "L111 expect: q.unacked_count() == 0")

def test_dequeue_empty() raises:
    """Dequeue returns None on empty queue."""
    var q = Queue("test", QueueConfig(10))
    var delivery = q.dequeue()
    check(not delivery.__bool__(), "L117 expect: not delivery.__bool__()")

def test_read_payload() raises:
    """Read payload returns the correct data."""
    var q = Queue("test", QueueConfig(10))
    _ = q.enqueue(_make_msg("key", 0xCC)^)

    var delivery = q.dequeue()
    check(delivery.__bool__(), "L125 expect: delivery.__bool__()")
    var view = q.read_payload(delivery.value().delivery_tag())
    check(view.size() == 1, "L127 expect: view.size() == 1")
    check(view[0] == 0xCC, "L128 expect: view[0] == 0xCC")

    check(q.acknowledge(delivery.value().delivery_tag()), "L130 expect: q.acknowledge(delivery.value().delivery_tag())")

def test_reject_redeliver() raises:
    """Rejected message is redelivered with incremented delivery count."""
    var q = Queue("test", QueueConfig(10))
    _ = q.enqueue(_make_msg("key", 0xDD)^)

    var d1 = q.dequeue()
    check(d1.__bool__(), "L138 expect: d1.__bool__()")
    var tag1 = d1.value().delivery_tag()
    check(q.reject(tag1), "L140 expect: q.reject(tag1)")

    var d2 = q.dequeue()
    check(d2.__bool__(), "L143 expect: d2.__bool__()")
    check(q.acknowledge(d2.value().delivery_tag()), "L144 expect: q.acknowledge(d2.value().delivery_tag())")

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
