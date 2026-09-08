# Tests for Hyrx embedded API end-to-end.

from std.collections import Dict
from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope
from hyrx.core.exchange import ExchangeType
from hyrx.embedded.api import HyrxEngine, HyrxConfig

def test_engine_creation() raises:
    var config = HyrxConfig()
    var engine = HyrxEngine(config^)
    var stats = engine.stats()
    assert stats.messages_published == 0
    assert stats.messages_delivered == 0
    assert stats.messages_acknowledged == 0
    assert stats.messages_rejected == 0
    print("  engine creation: OK")

def test_topology() raises:
    var config = HyrxConfig()
    var engine = HyrxEngine(config^)
    var ok = engine.declare_exchange("orders", ExchangeType.direct())
    assert ok
    ok = engine.declare_queue("order_queue")
    assert ok
    ok = engine.bind_queue("order_queue", "orders", "order.new")
    assert ok
    print("  topology: OK")

def test_publish_consume() raises:
    var config = HyrxConfig()
    var engine = HyrxEngine(config^)
    _ = engine.declare_exchange("ex", ExchangeType.direct())
    _ = engine.declare_queue("q1")
    _ = engine.bind_queue("q1", "ex", "key.a")

    var headers = Dict[String, String]()
    headers["content-type"] = "text/plain"
    var env = Envelope(MessageID(1), "key.a", headers^)
    var buf = Buffer(64)
    buf.resize(4)
    buf[0] = 0xDE
    buf[1] = 0xAD
    buf[2] = 0xBE
    buf[3] = 0xEF
    var msg = Message(env^, buf^)

    var count = engine.publish(msg^, "ex")
    assert count == 1

    var cid = engine.consume("q1", 1)
    var delivery = engine.next_message(cid)
    assert delivery.__bool__()
    var tag = delivery.value().delivery_tag()
    var ok = engine.acknowledge(cid, tag)
    assert ok
    print("  publish/consume: OK")

def test_ack_reject() raises:
    var config = HyrxConfig()
    var engine = HyrxEngine(config^)
    _ = engine.declare_exchange("ex", ExchangeType.direct())
    _ = engine.declare_queue("q1")
    _ = engine.bind_queue("q1", "ex", "k")

    var headers = Dict[String, String]()
    var env = Envelope(MessageID(1), "k", headers^)
    var msg = Message(env^, Buffer(16))
    _ = engine.publish(msg^, "ex")

    var cid = engine.consume("q1", 1)
    var delivery = engine.next_message(cid)
    assert delivery.__bool__()
    var tag = delivery.value().delivery_tag()
    var ok = engine.acknowledge(cid, tag)
    assert ok
    print("  ack: OK")

    var headers2 = Dict[String, String]()
    var env2 = Envelope(MessageID(2), "k", headers2^)
    var msg2 = Message(env2^, Buffer(16))
    _ = engine.publish(msg2^, "ex")
    var delivery2 = engine.next_message(cid)
    assert delivery2.__bool__()
    var tag2 = delivery2.value().delivery_tag()
    ok = engine.reject(cid, tag2)
    assert ok
    print("  reject: OK")

def test_stats_tracking() raises:
    var config = HyrxConfig()
    var engine = HyrxEngine(config^)
    _ = engine.declare_exchange("ex", ExchangeType.direct())
    _ = engine.declare_queue("q1")
    _ = engine.bind_queue("q1", "ex", "k")

    for i in range(5):
        var headers = Dict[String, String]()
        var env = Envelope(MessageID(UInt64(i)), "k", headers^)
        var msg = Message(env^, Buffer(32))
        _ = engine.publish(msg^, "ex")

    var stats = engine.stats()
    assert stats.messages_published == 5
    assert stats.active_queues == 1
    print("  stats: OK")

def test_fanout_exchange() raises:
    var config = HyrxConfig()
    var engine = HyrxEngine(config^)
    _ = engine.declare_exchange("fan", ExchangeType.fanout())
    _ = engine.declare_queue("q1")
    _ = engine.declare_queue("q2")
    _ = engine.bind_queue("q1", "fan", "")
    _ = engine.bind_queue("q2", "fan", "")

    var headers = Dict[String, String]()
    var env = Envelope(MessageID(1), "", headers^)
    var msg = Message(env^, Buffer(16))
    var count = engine.publish(msg^, "fan")
    assert count == 2

    var stats = engine.stats()
    assert stats.messages_published == 1
    print("  fanout: OK")

def test_exchange_not_found() raises:
    var config = HyrxConfig()
    var engine = HyrxEngine(config^)
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(1), "k", headers^)
    var msg = Message(env^, Buffer(16))
    var count = engine.publish(msg^, "nonexistent")
    assert count == 0
    print("  exchange not found: OK (returned 0)")

def test_queue_empty() raises:
    var config = HyrxConfig()
    var engine = HyrxEngine(config^)
    _ = engine.declare_exchange("ex", ExchangeType.direct())
    _ = engine.declare_queue("q1")
    _ = engine.bind_queue("q1", "ex", "k")

    var cid = engine.consume("q1", 1)
    var delivery = engine.next_message(cid)
    assert not delivery.__bool__()
    print("  queue empty: OK (returned None)")

def test_multiple_messages() raises:
    var config = HyrxConfig()
    var engine = HyrxEngine(config^)
    _ = engine.declare_exchange("ex", ExchangeType.direct())
    _ = engine.declare_queue("q1")
    _ = engine.bind_queue("q1", "ex", "k")

    for i in range(10):
        var headers = Dict[String, String]()
        var env = Envelope(MessageID(UInt64(i)), "k", headers^)
        var buf = Buffer(8)
        buf.resize(1)
        buf[0] = UInt8(i)
        var msg = Message(env^, buf^)
        _ = engine.publish(msg^, "ex")

    var cid = engine.consume("q1", 10)
    for i in range(10):
        var delivery = engine.next_message(cid)
        assert delivery.__bool__()
        var tag = delivery.value().delivery_tag()
        _ = engine.acknowledge(cid, tag)

    var stats = engine.stats()
    assert stats.messages_acknowledged == 10
    print("  multiple messages: OK")

def main() raises:
    print("EMBEDDED_API_TEST")
    test_engine_creation()
    test_topology()
    test_publish_consume()
    test_ack_reject()
    test_stats_tracking()
    test_fanout_exchange()
    test_exchange_not_found()
    test_queue_empty()
    test_multiple_messages()
    print("EMBEDDED_API_TEST=PASS")
