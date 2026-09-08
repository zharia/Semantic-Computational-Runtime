# Phase 7 — Broker status + health tests.

from hyrxmq.config import HyrxMQConfig, KeyValuePair
from hyrxmq.status import BrokerStatus
from hyrxmq.broker import HyrxMQBroker

from std.collections import List


def check(cond: Bool, var msg: String) raises:
    if not cond:
        raise "FAIL: " + msg


def test_status_defaults() raises:
    var s = BrokerStatus()
    check((s.queues == 0), "status default queues")
    check((s.consumers == 0), "status default consumers")
    check((s.messages_published == 0), "status default published")
    check((s.messages_delivered == 0), "status default delivered")
    check((s.messages_acked == 0), "status default acked")
    check((s.ready == False), "status default not ready")
    check((s.uptime == False), "status default uptime false")
    check((s.listening == False), "status default not listening")


def test_health_transitions() raises:
    var cfg = HyrxMQConfig()
    var broker = HyrxMQBroker(cfg^)
    check((broker.health() == "starting"), "health starting before start")
    var pre = broker.status()
    check((pre.ready == False), "not ready before start")
    check((pre.uptime == False), "no uptime before start")

    broker.start()
    check((broker.health() == "ok"), "health ok after start")
    var mid = broker.status()
    check((mid.ready == True), "ready after start")
    check((mid.uptime == True), "uptime set after start")
    check((mid.node_name == "hyrxmq@localhost"), "node name in status")
    check((mid.listening == False), "listening stays False (NOT PROVEN)")

    broker.shutdown()
    check((broker.health() == "degraded"), "health degraded after shutdown")
    var post = broker.status()
    check((post.ready == False), "not ready after shutdown")
    check((post.uptime == True), "uptime preserved after shutdown")


def test_status_counts_track_engine() raises:
    var cfg = HyrxMQConfig()
    var broker = HyrxMQBroker(cfg^)
    broker.start()
    _ = broker.declare_exchange("ex", "fanout")
    _ = broker.declare_queue("a")
    _ = broker.declare_queue("b")
    _ = broker.bind_queue("a", "ex", "")
    _ = broker.bind_queue("b", "ex", "")

    var body = List[UInt8]()
    body.append(7)
    var routed = broker.publish("ex", "anything", body^)
    check((routed == 2), "fanout routes to two queues")

    var st = broker.status()
    check((st.queues == 2), "two queues in status")
    check((st.messages_published == 1), "one publish counted")


def test_start_validates_config() raises:
    var entries = List[KeyValuePair]()
    entries.append(KeyValuePair("port", "99999"))
    var cfg = HyrxMQConfig.from_key_values(entries^)
    var broker = HyrxMQBroker(cfg^)
    var raised = False
    try:
        broker.start()
    except:
        raised = True
    check(raised, "start() must reject invalid config")
    check(
        (broker.health() == "starting"), "invalid start leaves health starting"
    )


def main() raises:
    test_status_defaults()
    test_health_transitions()
    test_status_counts_track_engine()
    test_start_validates_config()
    print("PHASE7_STATUS_HEALTH_TEST=PASS")
