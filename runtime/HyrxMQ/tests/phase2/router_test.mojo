# Integration tests for the Router.
#
# Covers: declare exchange+queue+bind, publish→route→deliver→ack,
# publish→route→deliver→reject→redeliver, consumer register/unregister,
# backpressure when queue full.

from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import ExchangeType
from hyrx.core.router import Router

from hyrx.testing import check

def _make_msg(key: String, val: UInt8) raises -> Message:
    """Helper: create a message with a single-byte payload."""
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(UInt64(val)), key, headers^)
    var buf = Buffer(8)
    buf.resize(1)
    buf[0] = val
    return Message(env^, buf^)

def test_declare_and_bind() raises:
    """Declare exchange, queue, and bind them."""
    var router = Router()
    check(router.declare_exchange("amq.direct", ExchangeType.direct()), "L24 expect: router.declare_exchange('amq.direct', ExchangeType.direct())")
    check(router.declare_queue("orders", 100), "L25 expect: router.declare_queue('orders', 100)")
    check(router.bind_queue("orders", "amq.direct", "orders.new"), "L26 expect: router.bind_queue('orders', 'amq.direct', 'orders.new')")
    check(router.exchange_count() == 1, "L27 expect: router.exchange_count() == 1")
    check(router.queue_count() == 1, "L28 expect: router.queue_count() == 1")

    # Duplicate declarations return False
    check(router.declare_exchange("amq.direct", ExchangeType.direct()) == False, "L31 expect: router.declare_exchange('amq.direct', ExchangeType.direct()) == False")
    check(router.declare_queue("orders", 100) == False, "L32 expect: router.declare_queue('orders', 100) == False")

def test_publish_route_deliver_ack() raises:
    """Full flow: publish → route → deliver → ack."""
    var router = Router()
    router.declare_exchange("ex", ExchangeType.direct())
    router.declare_queue("q", 100)
    router.bind_queue("q", "ex", "test.key")

    var msg = _make_msg("test.key", 0x01)
    var routed = router.publish(msg^, "ex")
    check(routed == 1, "L43 expect: routed == 1")
    check(router.messages_routed() == 1, "L44 expect: router.messages_routed() == 1")

    # Register consumer and consume
    var cid = router.register_consumer("q", 0)
    var delivery = router.consume(cid)
    check(delivery.__bool__(), "L49 expect: delivery.__bool__()")

    # Read payload
    var view = router.read_payload(cid, delivery.value().delivery_tag())
    check(view.size() == 1, "L53 expect: view.size() == 1")
    check(view[0] == 0x01, "L54 expect: view[0] == 0x01")

    # Acknowledge
    check(router.acknowledge(cid, delivery.value().delivery_tag()), "L57 expect: router.acknowledge(cid, delivery.value().delivery_tag())")

    # Queue should be empty now
    var empty = router.consume(cid)
    check(not empty.__bool__(), "L61 expect: not empty.__bool__()")

def test_publish_route_reject_redeliver() raises:
    """Publish → deliver → reject → redeliver."""
    var router = Router()
    router.declare_exchange("ex", ExchangeType.direct())
    router.declare_queue("q", 100)
    router.bind_queue("q", "ex", "key")

    var msg = _make_msg("key", 0xAA)
    router.publish(msg^, "ex")

    var cid = router.register_consumer("q", 0)

    # First delivery
    var d1 = router.consume(cid)
    check(d1.__bool__(), "L77 expect: d1.__bool__()")
    var tag1 = d1.value().delivery_tag()
    check(router.reject(cid, tag1), "L79 expect: router.reject(cid, tag1)")

    # Redeliver
    var d2 = router.consume(cid)
    check(d2.__bool__(), "L83 expect: d2.__bool__()")
    var view = router.read_payload(cid, d2.value().delivery_tag())
    check(view[0] == 0xAA, "L85 expect: view[0] == 0xAA")
    check(router.acknowledge(cid, d2.value().delivery_tag()), "L86 expect: router.acknowledge(cid, d2.value().delivery_tag())")

def test_consumer_unregister() raises:
    """Register and unregister consumer."""
    var router = Router()
    router.declare_exchange("ex", ExchangeType.fanout())
    router.declare_queue("q", 100)
    router.bind_queue("q", "ex", "")

    var cid = router.register_consumer("q", 0)
    check(router.consumer_count() == 1, "L96 expect: router.consumer_count() == 1")

    check(router.unregister_consumer(cid), "L98 expect: router.unregister_consumer(cid)")
    check(router.consumer_count() == 0, "L99 expect: router.consumer_count() == 0")

    # Unregister non-existing
    check(router.unregister_consumer(999) == False, "L102 expect: router.unregister_consumer(999) == False")

    # Consume from non-existing consumer returns None
    var delivery = router.consume(999)
    check(not delivery.__bool__(), "L106 expect: not delivery.__bool__()")

def test_backpressure() raises:
    """Queue rejects when full, router returns 0."""
    var router = Router()
    router.declare_exchange("ex", ExchangeType.direct())
    router.declare_queue("q", 2)  # Capacity 2
    router.bind_queue("q", "ex", "key")

    router.publish(_make_msg("key", 1)^, "ex")
    router.publish(_make_msg("key", 2)^, "ex")
    var result = router.publish(_make_msg("key", 3)^, "ex")
    check(result == 0, "L118 expect: result == 0")  # Rejected due to backpressure

    check(router.messages_routed() == 2, "L120 expect: router.messages_routed() == 2")

def test_fanout_routing() raises:
    """Fanout delivers to all bound queues."""
    var router = Router()
    router.declare_exchange("fan", ExchangeType.fanout())
    router.declare_queue("q1", 10)
    router.declare_queue("q2", 10)
    router.declare_queue("q3", 10)
    router.bind_queue("q1", "fan", "")
    router.bind_queue("q2", "fan", "")
    router.bind_queue("q3", "fan", "")

    var msg = _make_msg("anything", 0xFF)
    var routed = router.publish(msg^, "fan")
    check(routed == 3, "L135 expect: routed == 3")

    # Each queue should have one message
    var c1 = router.register_consumer("q1", 0)
    var c2 = router.register_consumer("q2", 0)
    var c3 = router.register_consumer("q3", 0)

    var d1 = router.consume(c1)
    var d2 = router.consume(c2)
    var d3 = router.consume(c3)
    check(d1.__bool__(), "L145 expect: d1.__bool__()")
    check(d2.__bool__(), "L146 expect: d2.__bool__()")
    check(d3.__bool__(), "L147 expect: d3.__bool__()")

def test_topic_routing() raises:
    """Topic exchange routes by pattern."""
    var router = Router()
    router.declare_exchange("topic", ExchangeType.topic())
    router.declare_queue("orders", 10)
    router.declare_queue("logs", 10)
    router.bind_queue("orders", "topic", "orders.*")
    router.bind_queue("logs", "topic", "logs.#")

    router.publish(_make_msg("orders.new", 1)^, "topic")
    router.publish(_make_msg("logs.error", 2)^, "topic")
    router.publish(_make_msg("orders.old", 3)^, "topic")

    var oc = router.register_consumer("orders", 0)
    var lc = router.register_consumer("logs", 0)

    # orders queue gets orders.new and orders.old
    var d1 = router.consume(oc)
    var d2 = router.consume(oc)
    check(d1.__bool__(), "L168 expect: d1.__bool__()")
    check(d2.__bool__(), "L169 expect: d2.__bool__()")
    var empty = router.consume(oc)
    check(not empty.__bool__(), "L171 expect: not empty.__bool__()")

    # logs queue gets logs.error
    var d3 = router.consume(lc)
    check(d3.__bool__(), "L175 expect: d3.__bool__()")
    empty = router.consume(lc)
    check(not empty.__bool__(), "L177 expect: not empty.__bool__()")

def test_prefetch_limit() raises:
    """Consumer respects prefetch limit."""
    var router = Router()
    router.declare_exchange("ex", ExchangeType.direct())
    router.declare_queue("q", 10)
    router.bind_queue("q", "ex", "key")

    router.publish(_make_msg("key", 1)^, "ex")
    router.publish(_make_msg("key", 2)^, "ex")
    router.publish(_make_msg("key", 3)^, "ex")

    var cid = router.register_consumer("q", 2)  # Prefetch 2

    var d1 = router.consume(cid)
    var d2 = router.consume(cid)
    check(d1.__bool__(), "L194 expect: d1.__bool__()")
    check(d2.__bool__(), "L195 expect: d2.__bool__()")

    # At prefetch limit
    var d3 = router.consume(cid)
    check(not d3.__bool__(), "L199 expect: not d3.__bool__()")

    # Ack one, can consume again
    router.acknowledge(cid, d1.value().delivery_tag())
    d3 = router.consume(cid)
    check(d3.__bool__(), "L204 expect: d3.__bool__()")

def test_delete_exchange() raises:
    """Delete exchange removes it."""
    var router = Router()
    router.declare_exchange("del", ExchangeType.direct())
    check(router.exchange_count() == 1, "L210 expect: router.exchange_count() == 1")
    check(router.delete_exchange("del"), "L211 expect: router.delete_exchange('del')")
    check(router.exchange_count() == 0, "L212 expect: router.exchange_count() == 0")
    check(router.delete_exchange("del") == False, "L213 expect: router.delete_exchange('del') == False")

def test_delete_queue() raises:
    """Delete queue removes it."""
    var router = Router()
    router.declare_queue("del", 10)
    check(router.queue_count() == 1, "L219 expect: router.queue_count() == 1")
    _ = router.delete_queue("del")
    check(router.queue_count() == 0, "L221 expect: router.queue_count() == 0")

def main() raises:
    test_declare_and_bind()
    test_publish_route_deliver_ack()
    test_publish_route_reject_redeliver()
    test_consumer_unregister()
    test_backpressure()
    test_fanout_routing()
    test_topic_routing()
    test_prefetch_limit()
    test_delete_exchange()
    test_delete_queue()
    print("ROUTER_TEST=PASS")
