# Tests for AMQP adapter.
#
# Verifies translation between AMQP operations and Hyrx core operations.

from hyrx.amqp.adapter import AMQPAdapter


def check(cond: Bool, var msg: String) raises:
    if not cond:
        raise "FAIL: " + msg


def test_declare_exchange_direct() raises:
    """Declare a direct exchange via adapter."""
    var adapter = AMQPAdapter()
    check((adapter.declare_exchange("amq.direct", "direct", durable=True)), "L11")

    # Duplicate returns False
    check((adapter.declare_exchange("amq.direct", "direct", durable=True) == False), "L14")


def test_declare_exchange_fanout() raises:
    """Declare a fanout exchange via adapter."""
    var adapter = AMQPAdapter()
    check((adapter.declare_exchange("logs", "fanout", durable=False)), "L20")


def test_declare_exchange_topic() raises:
    """Declare a topic exchange via adapter."""
    var adapter = AMQPAdapter()
    check((adapter.declare_exchange("events", "topic", durable=True)), "L26")


def test_declare_queue() raises:
    """Declare a queue via adapter."""
    var adapter = AMQPAdapter()
    check((adapter.declare_queue("orders", durable=True)), "L32")

    # Duplicate returns False
    check((adapter.declare_queue("orders", durable=True) == False), "L35")


def test_bind_queue() raises:
    """Bind queue to exchange via adapter."""
    var adapter = AMQPAdapter()
    check(adapter.declare_exchange("amq.direct", "direct", durable=True), "setupL46")
    check(adapter.declare_queue("orders", durable=True), "setupL47")
    check((adapter.bind_queue("orders", "amq.direct", "orders.new")), "L43")

    # Bind to missing exchange returns False
    check((adapter.bind_queue("orders", "nonexistent", "key") == False), "L46")

    # Bind missing queue returns False
    check((adapter.bind_queue("nonexistent", "amq.direct", "key") == False), "L49")


def test_publish_and_consume() raises:
    """Publish message and consume via adapter."""
    var adapter = AMQPAdapter()
    check(adapter.declare_exchange("ex", "direct", durable=False), "setupL60")
    check(adapter.declare_queue("q", durable=False), "setupL61")
    check(adapter.bind_queue("q", "ex", "test.key"), "setupL62")

    # Publish
    var body = List[UInt8]()
    body.append(0x48)  # 'H'
    body.append(0x69)  # 'i'
    var routed = adapter.publish("test.key", body^, "ex")
    check((routed == 1), "L64")

    # Consume
    var cid = adapter.consume("q")
    var delivery = adapter.deliver_next(cid)
    check((delivery.__bool__()), "L69")


def test_acknowledge() raises:
    """Acknowledge a delivery via adapter."""
    var adapter = AMQPAdapter()
    check(adapter.declare_exchange("ex", "direct", durable=False), "setupL80")
    check(adapter.declare_queue("q", durable=False), "setupL81")
    check(adapter.bind_queue("q", "ex", "key"), "setupL82")

    var body = List[UInt8]()
    body.append(0x01)
    _ = adapter.publish("key", body^, "ex")

    var cid = adapter.consume("q")
    var delivery = adapter.deliver_next(cid)
    check((delivery.__bool__()), "L85")

    var tag = delivery.value().delivery_tag()
    check((adapter.acknowledge(cid, tag)), "L88")

    # Second consume returns None (empty queue)
    var empty = adapter.deliver_next(cid)
    check(not (empty.__bool__()), "L92")


def test_reject_redeliver() raises:
    """Reject then redeliver via adapter."""
    var adapter = AMQPAdapter()
    check(adapter.declare_exchange("ex", "direct", durable=False), "setupL103")
    check(adapter.declare_queue("q", durable=False), "setupL104")
    check(adapter.bind_queue("q", "ex", "key"), "setupL105")

    var body = List[UInt8]()
    body.append(0xAA)
    _ = adapter.publish("key", body^, "ex")

    var cid = adapter.consume("q")

    # First delivery
    var d1 = adapter.deliver_next(cid)
    check((d1.__bool__()), "L110")
    check((adapter.reject(cid, d1.value().delivery_tag())), "L111")

    # Redeliver
    var d2 = adapter.deliver_next(cid)
    check((d2.__bool__()), "L115")
    check((adapter.acknowledge(cid, d2.value().delivery_tag())), "L116")


def test_fanout_publish() raises:
    """Fanout delivers to all bound queues."""
    var adapter = AMQPAdapter()
    check(adapter.declare_exchange("fan", "fanout", durable=False), "setupL127")
    check(adapter.declare_queue("q1", durable=False), "setupL128")
    check(adapter.declare_queue("q2", durable=False), "setupL129")
    check(adapter.bind_queue("q1", "fan", ""), "setupL130")
    check(adapter.bind_queue("q2", "fan", ""), "setupL131")

    var body = List[UInt8]()
    body.append(0xFF)
    var routed = adapter.publish("anything", body^, "fan")
    check((routed == 2), "L131")

    var c1 = adapter.consume("q1")
    var c2 = adapter.consume("q2")

    var d1 = adapter.deliver_next(c1)
    var d2 = adapter.deliver_next(c2)
    check((d1.__bool__()), "L138")
    check((d2.__bool__()), "L139")


def test_topic_publish() raises:
    """Topic exchange routes by pattern."""
    var adapter = AMQPAdapter()
    check(adapter.declare_exchange("topic", "topic", durable=False), "setupL150")
    check(adapter.declare_queue("orders", durable=False), "setupL151")
    check(adapter.declare_queue("logs", durable=False), "setupL152")
    check(adapter.bind_queue("orders", "topic", "orders.*"), "setupL153")
    check(adapter.bind_queue("logs", "topic", "logs.#"), "setupL154")

    var body1 = List[UInt8]()
    body1.append(1)
    var body2 = List[UInt8]()
    body2.append(2)
    var body3 = List[UInt8]()
    body3.append(3)

    _ = adapter.publish("orders.new", body1^, "topic")
    _ = adapter.publish("logs.error", body2^, "topic")
    _ = adapter.publish("orders.old", body3^, "topic")

    var oc = adapter.consume("orders")
    var lc = adapter.consume("logs")

    # orders queue gets orders.new and orders.old
    var d1 = adapter.deliver_next(oc)
    var d2 = adapter.deliver_next(oc)
    check((d1.__bool__()), "L168")
    check((d2.__bool__()), "L169")
    var empty = adapter.deliver_next(oc)
    check(not (empty.__bool__()), "L171")

    # logs queue gets logs.error
    var d3 = adapter.deliver_next(lc)
    check((d3.__bool__()), "L175")
    empty = adapter.deliver_next(lc)
    check(not (empty.__bool__()), "L177")


def main() raises:
    test_declare_exchange_direct()
    test_declare_exchange_fanout()
    test_declare_exchange_topic()
    test_declare_queue()
    test_bind_queue()
    test_publish_and_consume()
    test_acknowledge()
    test_reject_redeliver()
    test_fanout_publish()
    test_topic_publish()
    print("PHASE6_ADAPTER_TEST=PASS")
