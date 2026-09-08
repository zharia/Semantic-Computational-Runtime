# Tests for AMQP 0-9-1 constants.
#
# Verifies all method IDs, frame types, and reply codes have correct values.
#
# Expected values are transcribed from the normative class/method `index`
# attributes in amqp0-9-1.xml
# (https://www.rabbitmq.com/resources/specs/amqp0-9-1.xml). They are NOT
# copied from src/hyrx/amqp/constants.mojo: a regression here means the code
# drifted from the spec.

from hyrx.amqp.constants import *


from hyrx.testing import check

def test_frame_types() raises:
    """Frame type constants have correct values (amqp0-9-1.xml <constant>)."""
    check((FRAME_METHOD() == 1), "L10")
    check((FRAME_HEADER() == 2), "L11")
    check((FRAME_BODY() == 3), "L12")
    check((FRAME_HEARTBEAT() == 8), "L13")
    check((FRAME_END() == 0xCE), "L14")


def test_connection_class() raises:
    """Connection class method IDs (class index=10)."""
    check((CONNECTION_START() == MethodID(10, 10)), "L19")
    check((CONNECTION_START_OK() == MethodID(10, 11)), "L20")
    check((CONNECTION_SECURE() == MethodID(10, 20)), "L21")
    check((CONNECTION_SECURE_OK() == MethodID(10, 21)), "L22")
    check((CONNECTION_TUNE() == MethodID(10, 30)), "L23")
    check((CONNECTION_TUNE_OK() == MethodID(10, 31)), "L24")
    check((CONNECTION_OPEN() == MethodID(10, 40)), "L25")
    check((CONNECTION_OPEN_OK() == MethodID(10, 41)), "L26")
    check((CONNECTION_CLOSE() == MethodID(10, 50)), "L27")
    check((CONNECTION_CLOSE_OK() == MethodID(10, 51)), "L28")


def test_channel_class() raises:
    """Channel class method IDs (class index=20)."""
    check((CHANNEL_OPEN() == MethodID(20, 10)), "L31")
    check((CHANNEL_OPEN_OK() == MethodID(20, 11)), "L32")
    check((CHANNEL_FLOW() == MethodID(20, 20)), "L33")
    check((CHANNEL_FLOW_OK() == MethodID(20, 21)), "L34")
    check((CHANNEL_CLOSE() == MethodID(20, 40)), "L35")
    check((CHANNEL_CLOSE_OK() == MethodID(20, 41)), "L36")


def test_exchange_class() raises:
    """Exchange class method IDs (class index=40)."""
    check((EXCHANGE_DECLARE() == MethodID(40, 10)), "L39")
    check((EXCHANGE_DECLARE_OK() == MethodID(40, 11)), "L40")
    check((EXCHANGE_DELETE() == MethodID(40, 20)), "L41")
    check((EXCHANGE_DELETE_OK() == MethodID(40, 21)), "L42")
    check((EXCHANGE_BIND() == MethodID(40, 30)), "L43")
    check((EXCHANGE_BIND_OK() == MethodID(40, 31)), "L44")
    check((EXCHANGE_UNBIND() == MethodID(40, 40)), "L45")
    check((EXCHANGE_UNBIND_OK() == MethodID(40, 51)), "L46")


def test_queue_class() raises:
    """Queue class method IDs (class index=50)."""
    check((QUEUE_DECLARE() == MethodID(50, 10)), "L45")
    check((QUEUE_DECLARE_OK() == MethodID(50, 11)), "L46")
    check((QUEUE_BIND() == MethodID(50, 20)), "L47")
    check((QUEUE_BIND_OK() == MethodID(50, 21)), "L48")
    check((QUEUE_PURGE() == MethodID(50, 30)), "L49")
    check((QUEUE_PURGE_OK() == MethodID(50, 31)), "L50")
    check((QUEUE_DELETE() == MethodID(50, 40)), "L51")
    check((QUEUE_DELETE_OK() == MethodID(50, 41)), "L52")
    check((QUEUE_UNBIND() == MethodID(50, 50)), "L53")
    check((QUEUE_UNBIND_OK() == MethodID(50, 51)), "L54")


def test_basic_class() raises:
    """Basic class method IDs (class index=60)."""
    check((BASIC_QOS() == MethodID(60, 10)), "L57")
    check((BASIC_QOS_OK() == MethodID(60, 11)), "L58")
    check((BASIC_CONSUME() == MethodID(60, 20)), "L57")
    check((BASIC_CONSUME_OK() == MethodID(60, 21)), "L58")
    check((BASIC_CANCEL() == MethodID(60, 30)), "L59")
    check((BASIC_CANCEL_OK() == MethodID(60, 31)), "L60")
    check((BASIC_PUBLISH() == MethodID(60, 40)), "L53")
    check((BASIC_RETURN() == MethodID(60, 50)), "L61")
    check((BASIC_DELIVER() == MethodID(60, 60)), "L54")
    check((BASIC_ACK() == MethodID(60, 80)), "L55")
    check((BASIC_REJECT() == MethodID(60, 90)), "L62")
    check((BASIC_NACK() == MethodID(60, 120)), "L56")


def test_confirm_and_tx_classes() raises:
    """Confirm (85, RabbitMQ extension) and tx (index=90) method IDs."""
    check((CONFIRM_SELECT() == MethodID(85, 10)), "L66")
    check((CONFIRM_SELECT_OK() == MethodID(85, 11)), "L67")
    check((TX_SELECT() == MethodID(90, 10)), "L68")
    check((TX_SELECT_OK() == MethodID(90, 11)), "L69")
    check((TX_COMMIT() == MethodID(90, 20)), "L70")
    check((TX_COMMIT_OK() == MethodID(90, 21)), "L71")
    check((TX_ROLLBACK() == MethodID(90, 30)), "L72")
    check((TX_ROLLBACK_OK() == MethodID(90, 31)), "L73")


def test_spec_anchor_ids() raises:
    """Spot checks the audit called out, as literals (spec transcriptions)."""
    check((CONNECTION_OPEN().class_id == 10), "anchor class")
    check((CONNECTION_OPEN().method_id == 40), "connection.open index=40")
    check((BASIC_PUBLISH().class_id == 60), "basic class")
    check((BASIC_PUBLISH().method_id == 40), "basic.publish index=40")
    check((QUEUE_DECLARE().class_id == 50), "queue class")
    check((QUEUE_DECLARE().method_id == 10), "queue.declare index=10")
    check((BASIC_ACK().class_id == 60), "basic class for ack")
    check((BASIC_ACK().method_id == 80), "basic.ack index=80")


def test_reply_codes() raises:
    """Reply code constants."""
    check((REPLY_SUCCESS() == 200), "L65")
    check((REPLY_PROTOCOL_ERROR() == 502), "L66")
    check((REPLY_NOT_IMPLEMENTED() == 540), "L67")
    check((REPLY_RESOURCE_ERROR() == 541), "L68")


def test_method_id_struct() raises:
    """MethodID struct stores and compares correctly."""
    var m1 = MethodID(10, 1)
    var m2 = MethodID(10, 1)
    var m3 = MethodID(20, 1)
    check((m1 == m2), "L76")
    check(not ((m1 == m3)), "L77")
    check((m1.class_id == 10), "L78")
    check((m1.method_id == 1), "L79")


def main() raises:
    test_frame_types()
    test_connection_class()
    test_channel_class()
    test_exchange_class()
    test_queue_class()
    test_basic_class()
    test_confirm_and_tx_classes()
    test_spec_anchor_ids()
    test_reply_codes()
    test_method_id_struct()
    print("PHASE6_AMQP_CONSTANTS_TEST=PASS")
