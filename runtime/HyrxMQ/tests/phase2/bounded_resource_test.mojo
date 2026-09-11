# Bounded-resource / backpressure matrix (audit §7).
#
# Asserts the ACTUAL exhaustion behaviour of every currently-bounded core
# resource, and the fate of the message in each case. The prose matrix lives
# in docs/MEMORY_MODEL.md ("Bounded-resource matrix"); this file is its
# executable form. Silent drops are asserted AS silent drops and marked
# DESIGN GAP — they are reported, not endorsed (audit §7: exhaustion must
# never be implicit).

from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.queue import Queue, QueueConfig
from hyrx.core.exchange import ExchangeType, Exchange, Binding, HeaderArgs
from hyrx.core.router import Router

from hyrx.testing import check

def _msg(val: UInt8) raises -> Message:
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(UInt64(val)), "k", headers^)
    var buf = Buffer(8)
    buf.resize(1)
    buf[0] = val
    return Message(env^, buf^)

def _msg_sized(size: Int, val: UInt8) raises -> Message:
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(UInt64(val)), "k", headers^)
    var buf = Buffer(size)
    buf.resize(size)
    buf[0] = val
    return Message(env^, buf^)

# ---- resource 1: queue depth (capacity) -------------------------------

def test_queue_capacity_is_message_count_not_bytes() raises:
    """Capacity counts MESSAGES, not bytes: a 100 KB message occupies 1 slot."""
    var q = Queue("big-one", QueueConfig(2))
    check(q.capacity() == 2, "capacity is 2 messages")
    check(q.enqueue(_msg_sized(100000, 0x01)^), "100 KB message accepted")
    check(q.enqueue(_msg(0x02)^), "second message accepted")
    check(q.depth() == 2, "two messages pending")
    check(q.enqueue(_msg(0x03)^) == False, "third message rejected: capacity is message-count")

def test_queue_exhaustion_returns_false_and_destroys_the_message() raises:
    """DESIGN GAP (audit §7): enqueue() at capacity returns False AND the
    message is consumed by the call — the producer cannot recover the payload.
    No raise, no backpressure, no blocking."""
    var q = Queue("full", QueueConfig(1))
    check(q.enqueue(_msg(0x0A)^), "first message accepted")
    var rejected = False
    var raised = False
    try:
        rejected = q.enqueue(_msg(0x0B)^)
    except:
        raised = True
    check(not raised, "enqueue at capacity does NOT raise")
    check(rejected == False, "enqueue at capacity returns False (only signal)")
    check(q.depth() == 1, "the rejected message is gone: depth unchanged")

def test_capacity_accounts_unacked_messages() raises:
    """Capacity is enforced against pending + unacked, not pending alone."""
    var q = Queue("total", QueueConfig(2))
    check(q.enqueue(_msg(1)^), "m1 accepted")
    check(q.enqueue(_msg(2)^), "m2 accepted")
    var d = q.dequeue()
    check(d.__bool__(), "m1 delivered")
    check(q.depth() == 1, "one pending")
    check(q.unacked_count() == 1, "one unacked")
    check(q.enqueue(_msg(3)^) == False, "pending+unacked == capacity: enqueue refused")
    check(q.acknowledge(d.value().delivery_tag()), "ack frees capacity")
    check(q.enqueue(_msg(3)^), "enqueue succeeds after ack (recovery path)")

def test_reject_requeues_without_growing_total_count() raises:
    """Reject MOVES the message back to pending: total occupancy unchanged."""
    var q = Queue("rq", QueueConfig(2))
    check(q.enqueue(_msg(0x11)^), "m1")
    check(q.enqueue(_msg(0x12)^), "m2")
    var d1 = q.dequeue()
    check(q.reject(d1.value().delivery_tag()), "reject returns True")
    check(q.unacked_count() == 0, "nothing unacked after reject")
    check(q.depth() == 2, "both messages pending again")
    check(q.enqueue(_msg(0x13)^) == False, "still at capacity (no slot created)")

# ---- resource 2: message size -----------------------------------------

def test_message_size_is_unbounded_in_core() raises:
    """NOT BOUNDED: the core accepts an arbitrarily large payload.

    The only ceiling in the product is the AMQP codec's frame_max at the
    transport boundary; the core has no byte-level limit and no per-queue
    byte budget (audit §7).
    """
    var q = Queue("sizes", QueueConfig(10))
    check(q.enqueue(_msg_sized(1000000, 0x7E)^), "1 MB payload accepted by the core queue")
    check(q.depth() == 1, "1 MB message counts as one slot")
    var d = q.dequeue()
    var snap = q.read_payload(d.value().delivery_tag())
    check(snap.size() == 1000000, "payload length preserved byte-for-byte")
    check(snap[0] == 0x7E, "first byte preserved")

def test_publish_path_has_no_size_ceiling() raises:
    """Router.publish copies a large payload per destination without limit."""
    var router = Router()
    router.declare_exchange("f", ExchangeType.fanout())
    router.declare_queue("a", 5)
    router.declare_queue("b", 5)
    router.bind_queue("a", "f", "", HeaderArgs())
    router.bind_queue("b", "f", "", HeaderArgs())
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(1), "k", headers^)
    var buf = Buffer(262144)
    buf.resize(262144)
    buf[0] = 0x42
    var msg = Message(env^, buf^)
    check(router.publish(msg^, "f") == 2, "256 KB published to both queues")
    var ca = router.register_consumer("a", 0)
    var d = router.consume(ca)
    check(router.read_payload(ca, d.value().delivery_tag()).size() == 262144,
          "each destination owns a full 256 KB copy (2x memory amplification)")

# ---- resource 3: unacked count ----------------------------------------

def test_unacked_count_is_unbounded() raises:
    """No global unacked ceiling: prefetch=0 lets one consumer park any
    number of messages in the unacked pool (queue memory grows with it)."""
    var router = Router()
    router.declare_exchange("f", ExchangeType.fanout())
    router.declare_queue("q", 500)
    router.bind_queue("q", "f", "", HeaderArgs())
    for i in range(500):
        router.publish(_msg(UInt8(i % 251))^, "f")
    check(router.messages_routed() == 500, "500 messages published")
    var cid = router.register_consumer("q", 0)
    for i in range(500):
        check(router.consume(cid).__bool__(), "unbounded: delivery " + String(i) + " allowed")
    # Every slot moved pending -> unacked with no limit of its own; the queue
    # is now "full" only because capacity counts unacked too:
    check(router.publish(_msg(0x99)^, "f") == 0,
          "nothing new accepted while 500 sit unacked at capacity 500")

def test_prefetch_is_the_only_per_consumer_bound() raises:
    """Prefetch > 0 is enforced; prefetch = 0 means unlimited (by design)."""
    var router = Router()
    router.declare_exchange("f", ExchangeType.fanout())
    router.declare_queue("q", 100)
    router.bind_queue("q", "f", "", HeaderArgs())
    for i in range(10):
        router.publish(_msg(UInt8(0xC0 + i))^, "f")
    var capped = router.register_consumer("q", 3)
    var uncapped = router.register_consumer("q", 0)
    for i in range(3):
        check(router.consume(capped).__bool__(), "prefetch=3 allows exactly 3")
    check(not router.consume(capped).__bool__(), "prefetch=3 blocks the 4th")
    for i in range(7):
        check(router.consume(uncapped).__bool__(), "prefetch=0 allows all remaining")
    check(not router.consume(uncapped).__bool__(), "then the queue is genuinely empty")

# ---- resources 4-7: consumers, queues, exchanges, bindings -------------

def test_consumer_count_is_unbounded() raises:
    """NO LIMIT on registered consumers (audit §7: declared-but-enforced? no)."""
    var router = Router()
    router.declare_queue("q", 10)
    for i in range(300):
        router.register_consumer("q", 1)
    check(router.consumer_count() == 300, "300 consumers registered without refusal")

def test_queue_and_exchange_counts_are_unbounded() raises:
    """NO LIMIT on queues or exchanges."""
    var router = Router()
    for i in range(300):
        router.declare_queue("q" + String(i), 1)
        router.declare_exchange("e" + String(i), ExchangeType.direct())
    check(router.queue_count() == 300, "300 queues")
    check(router.exchange_count() == 300, "300 exchanges")

def test_bindings_per_exchange_are_unbounded() raises:
    """NO LIMIT on bindings held by an exchange."""
    var ex = Exchange("wide", ExchangeType.direct())
    for i in range(500):
        ex.add_binding(Binding("q" + String(i), "k" + String(i), HeaderArgs()))
    check(ex.binding_count() == 500, "500 bindings stored")

# ---- resource 8: unknown handles (error surface) ----------------------

def test_unknown_delivery_tag_reads_as_empty_snapshot() raises:
    """DESIGN GAP (audit §7): reading an unknown tag yields an EMPTY snapshot
    instead of raising — indistinguishable from a legitimately empty payload."""
    var q = Queue("tags", QueueConfig(4))
    check(q.enqueue(_msg(0x01)^), "enqueue")
    var d = q.dequeue()
    var known = q.read_payload(d.value().delivery_tag())
    check(known.size() == 1, "known tag returns the copied payload")
    var unknown_raised = False
    var got = 0
    try:
        var snap = q.read_payload(4242)
        got = snap.size()
    except:
        unknown_raised = True
    check(not unknown_raised, "unknown tag does NOT raise")
    check(got == 0, "unknown tag silently reads as 0 bytes")
    check(q.read_routing_key(4242) == "", "unknown tag also reads routing key as empty string")
    check(q.acknowledge(4242) == False, "ack of unknown tag returns False")
    check(q.reject(4242) == False, "reject of unknown tag returns False")

def test_handle_error_shapes_are_inconsistent() raises:
    """REPORTED: unknown consumer id fails differently per operation.

    consume/acknowledge/reject return None/False, but read_payload raises
    (DictKeyError) — one API surface, three failure shapes (audit §7).
    """
    var router = Router()
    router.declare_queue("q", 4)
    check(not router.consume(999).__bool__(), "consume: unknown id -> None")
    check(router.acknowledge(999, 0) == False, "acknowledge: unknown id -> False")
    check(router.reject(999, 0) == False, "reject: unknown id -> False")
    var raised = False
    try:
        var snap = router.read_payload(999, 0)
        _ = snap.size()
    except:
        raised = True
    check(raised, "read_payload: unknown id RAISES (inconsistent with the rest)")
    check(router.unregister_consumer(999) == False, "unregister unknown id -> False")

def test_delete_queue_destroys_messages_and_returns_none_of_them() raises:
    """BUG (audit §5/§7): delete_queue()'s docstring promises the unacked
    messages for cleanup; it returns an EMPTY list and the queue's pending
    and unacked Messages are destroyed with the Queue object."""
    var router = Router()
    router.declare_queue("doomed", 10)
    router.declare_exchange("f", ExchangeType.fanout())
    router.bind_queue("doomed", "f", "", HeaderArgs())
    check(router.publish(_msg(0x01)^, "f") == 1, "one message queued")
    var leftover = router.delete_queue("doomed")
    check(len(leftover) == 0, "returned list is EMPTY (docstring says otherwise)")
    check(router.queue_count() == 0, "queue is gone")

def main() raises:
    test_queue_capacity_is_message_count_not_bytes()
    test_queue_exhaustion_returns_false_and_destroys_the_message()
    test_capacity_accounts_unacked_messages()
    test_reject_requeues_without_growing_total_count()
    test_message_size_is_unbounded_in_core()
    test_publish_path_has_no_size_ceiling()
    test_unacked_count_is_unbounded()
    test_prefetch_is_the_only_per_consumer_bound()
    test_consumer_count_is_unbounded()
    test_queue_and_exchange_counts_are_unbounded()
    test_bindings_per_exchange_are_unbounded()
    test_unknown_delivery_tag_reads_as_empty_snapshot()
    test_handle_error_shapes_are_inconsistent()
    test_delete_queue_destroys_messages_and_returns_none_of_them()
    print("BOUNDED_RESOURCE_TEST=PASS")
