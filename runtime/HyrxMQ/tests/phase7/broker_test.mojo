# Phase 7 — HyrxMQ broker tests.
#
# Exercises the in-process broker surface WITHOUT sockets: topology assembly,
# publish/route/deliver/ack, status counters and health.

from std.collections import List

from hyrxmq.config import HyrxMQConfig
from hyrxmq.broker import HyrxMQBroker


def check(cond: Bool, var msg: String) raises:
    if not cond:
        raise "FAIL: " + msg


def test_health_transition() raises:
    var cfg = HyrxMQConfig()
    var broker = HyrxMQBroker(cfg^)
    check((broker.health() == "starting"), "pre-start health is starting")
    check(not broker.ready(), "pre-start not ready")
    broker.start()
    check((broker.health() == "ok"), "post-start health ok")
    check(broker.ready(), "post-start ready")
    broker.shutdown()
    check((broker.health() == "degraded"), "post-shutdown degraded")


def test_publish_routes_to_bound_queue() raises:
    var cfg = HyrxMQConfig()
    var broker = HyrxMQBroker(cfg^)
    broker.start()
    check(broker.declare_exchange("ex", "direct"), "declare exchange")
    check(broker.declare_queue("q"), "declare queue")
    check(broker.bind_queue("q", "ex", "key.a"), "bind queue")

    var body = List[UInt8]()
    body.append(1)
    body.append(2)
    body.append(3)
    var routed = broker.publish("ex", "key.a", body^)
    check((routed >= 1), "publish routed to bound queue")

    var st = broker.status()
    check((st.messages_published == 1), "published counter")
    check((st.queues == 1), "queue count")
    check((st.ready == True), "status ready")
    check((st.listening == False), "listening False (network NOT PROVEN)")


def test_deliver_and_ack() raises:
    var cfg = HyrxMQConfig()
    var broker = HyrxMQBroker(cfg^)
    broker.start()
    _ = broker.declare_exchange("ex", "direct")
    _ = broker.declare_queue("q")
    _ = broker.bind_queue("q", "ex", "k")

    var body = List[UInt8]()
    body.append(0xAA)
    _ = broker.publish("ex", "k", body^)

    var cid = broker.consume_register("q")
    var d = broker.deliver(cid)
    check(d.__bool__(), "delivery present")
    var tag = d.value().delivery_tag()
    var payload = broker.read_payload(cid, tag)
    check((len(payload) == 1 and payload[0] == 0xAA), "payload round-trip")
    check(broker.ack(cid, tag), "ack ok")

    var st = broker.status()
    check((st.messages_delivered == 1), "delivered counter")
    check((st.messages_acked == 1), "acked counter")
    check((st.consumers == 1), "consumer count")


def test_empty_queue_deliver_none() raises:
    var cfg = HyrxMQConfig()
    var broker = HyrxMQBroker(cfg^)
    broker.start()
    _ = broker.declare_exchange("ex", "direct")
    _ = broker.declare_queue("q")
    var cid = broker.consume_register("q")
    var d = broker.deliver(cid)
    check(not d.__bool__(), "empty queue deliver is None")


def test_duplicate_topology_returns_false() raises:
    var cfg = HyrxMQConfig()
    var broker = HyrxMQBroker(cfg^)
    broker.start()
    check(broker.declare_queue("dup"), "first declare")
    check(not broker.declare_queue("dup"), "duplicate declare returns False")


def test_protocol_path_composed() raises:
    var cfg = HyrxMQConfig()
    var broker = HyrxMQBroker(cfg^)
    broker.start()
    check(broker.protocol_selfcheck(), "AMQPAdapter protocol path round-trips")


def main() raises:
    test_health_transition()
    test_publish_routes_to_bound_queue()
    test_deliver_and_ack()
    test_empty_queue_deliver_none()
    test_duplicate_topology_returns_false()
    test_protocol_path_composed()
    print("PHASE7_BROKER_TEST=PASS")
