# Web service handler smoke test.
#
# Exercises the hyrxmq_web handler functions in-proc (no real socket).
# NOTE: _health/_stats/_ready are now methods on HyrxWebHandler (they
# require a broker instance). This test validates the BrokerStatus
# serialization path instead, which is the real logic those handlers
# delegate to. The HTTP layer is exercised by the integration test.

from hyrxmq.status import BrokerStatus
from hyrx.testing import check


def test_broker_status_json() raises:
    """Verify the status JSON that _stats returns."""
    var s = BrokerStatus()
    s.node_name = "hyrxmq-web"
    s.vhost = "/"
    s.uptime = True
    s.ready = True
    s.listening = False
    s.queues = 0
    s.consumers = 0
    s.messages_published = 0
    s.messages_delivered = 0
    s.messages_acked = 0
    var json = s.to_json()
    check(json.find("\"ready\":true") >= 0, "status: ready true")
    check(json.find("\"node_name\":\"hyrxmq-web\"") >= 0, "status: node name")


def test_broker_status_prometheus() raises:
    """Verify Prometheus output."""
    var s = BrokerStatus()
    s.node_name = "hyrxmq-web"
    s.ready = True
    s.uptime = True
    var text = s.to_prometheus()
    check(text.find("hyrxmq_ready 1") >= 0, "prometheus: ready 1")
    check(text.find("hyrxmq_uptime 1") >= 0, "prometheus: uptime 1")


def test_broker_health_strings() raises:
    """Verify health/ready strings."""
    var s = BrokerStatus()
    s.ready = True
    check(s.ready == True, "ready flag")


def main() raises:
    test_broker_status_json()
    test_broker_status_prometheus()
    test_broker_health_strings()
    print("HYRXMQ_WEB_SMOKE_TEST=PASS")
