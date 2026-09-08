# Tests for AMQP adapter.
#
# Verifies translation between AMQP operations and Hyrx core operations.
#
# Ownership contract under test: the adapter owns NO routing substrate. Every
# operation is applied to the HyrxEngine passed in, so the engine's own views
# (stats, delivery) must observe the adapter's effects, and a different engine
# must not.

from std.collections import List

from hyrx.amqp.adapter import AMQPAdapter, exchange_type_from_name
from hyrx.core.exchange import ExchangeType
from hyrx.embedded.api import HyrxEngine, HyrxConfig


from hyrx.testing import check

def new_engine() -> HyrxEngine:
    return HyrxEngine(HyrxConfig(1024, 4096, 64))


def test_declare_exchange_direct() raises:
    """Declare a direct exchange via adapter."""
    var engine = new_engine()
    var adapter = AMQPAdapter()
    check((adapter.declare_exchange(engine, "amq.direct", "direct", durable=True)), "L11")

    # Duplicate returns False
    check(
        (adapter.declare_exchange(engine, "amq.direct", "direct", durable=True) == False),
        "L14",
    )


def test_declare_exchange_fanout() raises:
    """Declare a fanout exchange via adapter."""
    var engine = new_engine()
    var adapter = AMQPAdapter()
    check((adapter.declare_exchange(engine, "logs", "fanout", durable=False)), "L20")


def test_declare_exchange_topic() raises:
    """Declare a topic exchange via adapter."""
    var engine = new_engine()
    var adapter = AMQPAdapter()
    check((adapter.declare_exchange(engine, "events", "topic", durable=True)), "L26")


def test_exchange_type_mapping_is_single_and_headers_is_the_stub() raises:
    """One mapping table: "headers" maps to the core headers stub, not direct."""
    check((exchange_type_from_name("direct") == ExchangeType.direct()), "direct")
    check((exchange_type_from_name("fanout") == ExchangeType.fanout()), "fanout")
    check((exchange_type_from_name("topic") == ExchangeType.topic()), "topic")
    check(
        (exchange_type_from_name("headers") == ExchangeType.headers()),
        "headers must map to ExchangeType.headers() everywhere (core stub)",
    )
    check(
        not (exchange_type_from_name("headers") == ExchangeType.direct()),
        "headers must NOT be silently re-typed as direct",
    )
    check(
        (exchange_type_from_name("unknown") == ExchangeType.direct()),
        "unknown type falls back to direct",
    )


def test_declare_queue() raises:
    """Declare a queue via adapter."""
    var engine = new_engine()
    var adapter = AMQPAdapter()
    check((adapter.declare_queue(engine, "orders", durable=True)), "L32")

    # Duplicate returns False
    check((adapter.declare_queue(engine, "orders", durable=True) == False), "L35")


def test_bind_queue() raises:
    """Bind queue to exchange via adapter."""
    var engine = new_engine()
    var adapter = AMQPAdapter()
    check(adapter.declare_exchange(engine, "amq.direct", "direct", durable=True), "setupL46")
    check(adapter.declare_queue(engine, "orders", durable=True), "setupL47")
    check((adapter.bind_queue(engine, "orders", "amq.direct", "orders.new")), "L43")

    # Bind to missing exchange returns False
    check(
        (adapter.bind_queue(engine, "orders", "nonexistent", "key") == False), "L46"
    )

    # Bind missing queue returns False (the engine authority rejects unknown queues)
    check(
        (adapter.bind_queue(engine, "nonexistent", "amq.direct", "key") == False),
        "L49",
    )


def test_publish_and_consume() raises:
    """Publish message and consume via adapter."""
    var engine = new_engine()
    var adapter = AMQPAdapter()
    check(adapter.declare_exchange(engine, "ex", "direct", durable=False), "setupL60")
    check(adapter.declare_queue(engine, "q", durable=False), "setupL61")
    check(adapter.bind_queue(engine, "q", "ex", "test.key"), "setupL62")

    # Publish
    var body = List[UInt8]()
    body.append(0x48)  # 'H'
    body.append(0x69)  # 'i'
    var routed = adapter.publish(engine, "test.key", body^, "ex")
    check((routed == 1), "L64")

    # Consume
    var cid = adapter.consume(engine, "q")
    var delivery = adapter.deliver_next(engine, cid)
    check((delivery.__bool__()), "L69")


def test_acknowledge() raises:
    """Acknowledge a delivery via adapter."""
    var engine = new_engine()
    var adapter = AMQPAdapter()
    check(adapter.declare_exchange(engine, "ex", "direct", durable=False), "setupL80")
    check(adapter.declare_queue(engine, "q", durable=False), "setupL81")
    check(adapter.bind_queue(engine, "q", "ex", "key"), "setupL82")

    var body = List[UInt8]()
    body.append(0x01)
    _ = adapter.publish(engine, "key", body^, "ex")

    var cid = adapter.consume(engine, "q")
    var delivery = adapter.deliver_next(engine, cid)
    check((delivery.__bool__()), "L85")

    var tag = delivery.value().delivery_tag()
    check((adapter.acknowledge(engine, cid, tag)), "L88")

    # Second consume returns None (empty queue)
    var empty = adapter.deliver_next(engine, cid)
    check(not (empty.__bool__()), "L92")


def test_reject_redeliver() raises:
    """Reject then redeliver via adapter."""
    var engine = new_engine()
    var adapter = AMQPAdapter()
    check(adapter.declare_exchange(engine, "ex", "direct", durable=False), "setupL103")
    check(adapter.declare_queue(engine, "q", durable=False), "setupL104")
    check(adapter.bind_queue(engine, "q", "ex", "key"), "setupL105")

    var body = List[UInt8]()
    body.append(0xAA)
    _ = adapter.publish(engine, "key", body^, "ex")

    var cid = adapter.consume(engine, "q")

    # First delivery
    var d1 = adapter.deliver_next(engine, cid)
    check((d1.__bool__()), "L110")
    check((adapter.reject(engine, cid, d1.value().delivery_tag())), "L111")

    # Redeliver
    var d2 = adapter.deliver_next(engine, cid)
    check((d2.__bool__()), "L115")
    check((adapter.acknowledge(engine, cid, d2.value().delivery_tag())), "L116")


def test_fanout_publish() raises:
    """Fanout delivers to all bound queues."""
    var engine = new_engine()
    var adapter = AMQPAdapter()
    check(adapter.declare_exchange(engine, "fan", "fanout", durable=False), "setupL127")
    check(adapter.declare_queue(engine, "q1", durable=False), "setupL128")
    check(adapter.declare_queue(engine, "q2", durable=False), "setupL129")
    check(adapter.bind_queue(engine, "q1", "fan", ""), "setupL130")
    check(adapter.bind_queue(engine, "q2", "fan", ""), "setupL131")

    var body = List[UInt8]()
    body.append(0xFF)
    var routed = adapter.publish(engine, "anything", body^, "fan")
    check((routed == 2), "L131")

    var c1 = adapter.consume(engine, "q1")
    var c2 = adapter.consume(engine, "q2")

    var d1 = adapter.deliver_next(engine, c1)
    var d2 = adapter.deliver_next(engine, c2)
    check((d1.__bool__()), "L138")
    check((d2.__bool__()), "L139")


def test_topic_publish() raises:
    """Topic exchange routes by pattern."""
    var engine = new_engine()
    var adapter = AMQPAdapter()
    check(adapter.declare_exchange(engine, "topic", "topic", durable=False), "setupL150")
    check(adapter.declare_queue(engine, "orders", durable=False), "setupL151")
    check(adapter.declare_queue(engine, "logs", durable=False), "setupL152")
    check(adapter.bind_queue(engine, "orders", "topic", "orders.*"), "setupL153")
    check(adapter.bind_queue(engine, "logs", "topic", "logs.#"), "setupL154")

    var body1 = List[UInt8]()
    body1.append(1)
    var body2 = List[UInt8]()
    body2.append(2)
    var body3 = List[UInt8]()
    body3.append(3)

    _ = adapter.publish(engine, "orders.new", body1^, "topic")
    _ = adapter.publish(engine, "logs.error", body2^, "topic")
    _ = adapter.publish(engine, "orders.old", body3^, "topic")

    var oc = adapter.consume(engine, "orders")
    var lc = adapter.consume(engine, "logs")

    # orders queue gets orders.new and orders.old
    var d1 = adapter.deliver_next(engine, oc)
    var d2 = adapter.deliver_next(engine, oc)
    check((d1.__bool__()), "L168")
    check((d2.__bool__()), "L169")
    var empty = adapter.deliver_next(engine, oc)
    check(not (empty.__bool__()), "L171")

    # logs queue gets logs.error
    var d3 = adapter.deliver_next(engine, lc)
    check((d3.__bool__()), "L175")
    empty = adapter.deliver_next(engine, lc)
    check(not (empty.__bool__()), "L177")


def test_adapter_writes_only_into_the_injected_engine() raises:
    """Single routing authority: adapter effects land in the engine it was given.

    A second engine must observe nothing, proving the adapter carries no private
    routing state of its own (the old AMQPAdapter owned a Router and could
    "succeed" while the broker's engine stayed empty).
    """
    var engine = new_engine()
    var other = new_engine()
    var adapter = AMQPAdapter()

    check(adapter.declare_exchange(engine, "one", "direct", durable=False), "declare ex")
    check(adapter.declare_queue(engine, "one-q", durable=False), "declare q")
    check(adapter.bind_queue(engine, "one-q", "one", "k"), "bind")
    var body = List[UInt8]()
    body.append(0x07)
    check((adapter.publish(engine, "k", body^, "one") == 1), "publish routed")

    # The injected engine sees all of it.
    var st = engine.stats()
    check((st.active_queues == 1), "engine queue count reflects adapter work")
    check((st.messages_published == 1), "engine publish count")

    # The unrelated engine sees none of it.
    var other_st = other.stats()
    check((other_st.active_queues == 0), "other engine untouched")
    check((other_st.messages_published == 0), "other engine has no publishes")

    # And a consumer id issued on `engine` is meaningless on `other`:
    # the adapter cannot deliver from an engine it was not given.
    var cid = adapter.consume(engine, "one-q")
    check(adapter.deliver_next(engine, cid).__bool__(), "delivery on the right engine")
    check(not (adapter.deliver_next(other, cid).__bool__()), "no shadow delivery source")


def main() raises:
    test_declare_exchange_direct()
    test_declare_exchange_fanout()
    test_declare_exchange_topic()
    test_exchange_type_mapping_is_single_and_headers_is_the_stub()
    test_declare_queue()
    test_bind_queue()
    test_publish_and_consume()
    test_acknowledge()
    test_reject_redeliver()
    test_fanout_publish()
    test_topic_publish()
    test_adapter_writes_only_into_the_injected_engine()
    print("PHASE6_ADAPTER_TEST=PASS")
