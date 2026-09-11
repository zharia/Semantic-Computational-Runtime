# Phase 10 — BrokerStatus metrics export tests.
#
# Exercises the read-only projections BrokerStatus.to_prometheus() and
# BrokerStatus.to_json(): Prometheus exposition text, single-line JSON, and
# JSON string escaping of the node name / vhost. No broker engine involved.

from hyrxmq.status import BrokerStatus

from hyrx.testing import check


def expect_contains(haystack: String, needle: String, message: String) raises:
    check(haystack.find(needle) >= 0, message + " :: missing " + needle)


def known_status() -> BrokerStatus:
    var s = BrokerStatus()
    s.node_name = "hyrxmq@localhost"
    s.vhost = "/"
    s.uptime = True
    s.ready = True
    s.listening = False
    s.queues = 2
    s.consumers = 1
    s.messages_published = 42
    s.messages_delivered = 42
    s.messages_acked = 42
    return s^


def test_prometheus_lines() raises:
    var s = known_status()
    var text = s.to_prometheus()

    check(text.find("hyrxmq_queues 2") >= 0, "queues gauge value")
    check(text.find("hyrxmq_consumers 1") >= 0, "consumers gauge value")
    check(
        text.find("hyrxmq_messages_published 42") >= 0,
        "published counter value",
    )
    check(
        text.find("hyrxmq_messages_delivered 42") >= 0,
        "delivered counter value",
    )
    check(
        text.find("hyrxmq_messages_acked 42") >= 0, "acked counter value"
    )
    check(text.find("hyrxmq_up 1") >= 0, "up gauge reflects ready")
    check(text.find("hyrxmq_uptime 1") >= 0, "uptime gauge true -> 1")
    check(text.find("hyrxmq_ready 1") >= 0, "ready gauge true -> 1")
    check(text.find("hyrxmq_listening 0") >= 0, "listening gauge false -> 0")

    check(
        text.find("# TYPE hyrxmq_queues gauge") >= 0, "queues declared gauge"
    )
    check(
        text.find("# TYPE hyrxmq_consumers gauge") >= 0,
        "consumers declared gauge",
    )
    check(
        text.find("# TYPE hyrxmq_messages_published counter") >= 0,
        "published declared counter",
    )
    check(
        text.find("# TYPE hyrxmq_messages_delivered counter") >= 0,
        "delivered declared counter",
    )
    check(
        text.find("# TYPE hyrxmq_messages_acked counter") >= 0,
        "acked declared counter",
    )
    check(text.find("# TYPE hyrxmq_up gauge") >= 0, "up declared gauge")

    check(text.find("# HELP hyrxmq_queues") >= 0, "queues HELP line")


def test_json_fields() raises:
    var s = known_status()
    var json = s.to_json()
    var want = "{\"node_name\":\"hyrxmq@localhost\",\"vhost\":\"/\","
    want += "\"uptime\":true,\"ready\":true,\"listening\":false,"
    want += "\"queues\":2,\"consumers\":1,\"messages_published\":42,"
    want += "\"messages_delivered\":42,\"messages_acked\":42}"
    check(json == want, "json exact serialization")

    expect_contains(json, "\"node_name\":\"hyrxmq@localhost\"", "node name")
    expect_contains(json, "\"vhost\":\"/\"", "vhost")
    expect_contains(json, "\"listening\":false", "listening false")
    expect_contains(json, "\"messages_published\":42", "published number")
    expect_contains(json, "\"messages_delivered\":42", "delivered number")
    expect_contains(json, "\"messages_acked\":42", "acked number")
    check(json.find("\n") < 0, "json must be a single line")


def test_json_escaping() raises:
    var s = BrokerStatus()
    s.node_name = "a\"b\\c"
    s.vhost = "v\\\"x"
    s.uptime = True
    s.ready = False
    s.listening = True
    s.queues = 0
    s.consumers = 0
    s.messages_published = 0
    s.messages_delivered = 0
    s.messages_acked = 0
    var json = s.to_json()
    expect_contains(json, "\"node_name\":\"a\\\"b\\\\c\"", "quote/backslash escape")
    expect_contains(json, "\"vhost\":\"v\\\\\\\"x\"", "vhost escape")
    expect_contains(json, "\"uptime\":true", "escaping keeps bools")
    expect_contains(json, "\"listening\":true", "escaping keeps listening bool")


def test_boolean_values() raises:
    var s = BrokerStatus()
    s.uptime = True
    s.ready = False
    s.listening = True
    var text = s.to_prometheus()
    check(text.find("hyrxmq_up 0") >= 0, "up 0 when not ready")
    check(text.find("hyrxmq_ready 0") >= 0, "ready 0 when not ready")
    check(text.find("hyrxmq_uptime 1") >= 0, "uptime 1")
    check(text.find("hyrxmq_listening 1") >= 0, "listening 1")
    var json = s.to_json()
    expect_contains(json, "\"uptime\":true", "json uptime true")
    expect_contains(json, "\"ready\":false", "json ready false")


def main() raises:
    test_prometheus_lines()
    test_json_fields()
    test_json_escaping()
    test_boolean_values()
    print("PHASE10_METRICS_EXPORT_TEST=PASS")
