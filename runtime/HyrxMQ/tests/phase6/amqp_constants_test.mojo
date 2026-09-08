# Tests for AMQP 0-9-1 constants.
#
# Verifies all method IDs, frame types, and reply codes have correct values.

from hyrx.amqp.constants import *


def check(cond: Bool, var msg: String) raises:
    if not cond:
        raise "FAIL: " + msg


def test_frame_types() raises:
    """Frame type constants have correct values."""
    check((FRAME_METHOD() == 1), "L10")
    check((FRAME_HEADER() == 2), "L11")
    check((FRAME_BODY() == 3), "L12")
    check((FRAME_HEARTBEAT() == 8), "L13")
    check((FRAME_END() == 0xCE), "L14")


def test_connection_class() raises:
    """Connection class method IDs (class=10)."""
    check((CONNECTION_START() == MethodID(10, 1)), "L19")
    check((CONNECTION_START_OK() == MethodID(10, 2)), "L20")
    check((CONNECTION_TUNE() == MethodID(10, 3)), "L21")
    check((CONNECTION_TUNE_OK() == MethodID(10, 4)), "L22")
    check((CONNECTION_OPEN() == MethodID(10, 5)), "L23")
    check((CONNECTION_OPEN_OK() == MethodID(10, 6)), "L24")
    check((CONNECTION_CLOSE() == MethodID(10, 10)), "L25")
    check((CONNECTION_CLOSE_OK() == MethodID(10, 11)), "L26")


def test_channel_class() raises:
    """Channel class method IDs (class=20)."""
    check((CHANNEL_OPEN() == MethodID(20, 1)), "L31")
    check((CHANNEL_OPEN_OK() == MethodID(20, 2)), "L32")
    check((CHANNEL_CLOSE() == MethodID(20, 40)), "L33")
    check((CHANNEL_CLOSE_OK() == MethodID(20, 41)), "L34")


def test_exchange_class() raises:
    """Exchange class method IDs (class=40)."""
    check((EXCHANGE_DECLARE() == MethodID(40, 10)), "L39")
    check((EXCHANGE_DECLARE_OK() == MethodID(40, 11)), "L40")


def test_queue_class() raises:
    """Queue class method IDs (class=50)."""
    check((QUEUE_DECLARE() == MethodID(50, 10)), "L45")
    check((QUEUE_DECLARE_OK() == MethodID(50, 11)), "L46")
    check((QUEUE_BIND() == MethodID(50, 20)), "L47")
    check((QUEUE_BIND_OK() == MethodID(50, 21)), "L48")


def test_basic_class() raises:
    """Basic class method IDs (class=60)."""
    check((BASIC_PUBLISH() == MethodID(60, 40)), "L53")
    check((BASIC_DELIVER() == MethodID(60, 60)), "L54")
    check((BASIC_ACK() == MethodID(60, 80)), "L55")
    check((BASIC_NACK() == MethodID(60, 120)), "L56")
    check((BASIC_CONSUME() == MethodID(60, 20)), "L57")
    check((BASIC_CONSUME_OK() == MethodID(60, 21)), "L58")
    check((BASIC_CANCEL() == MethodID(60, 30)), "L59")
    check((BASIC_CANCEL_OK() == MethodID(60, 31)), "L60")


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
    test_reply_codes()
    test_method_id_struct()
    print("PHASE6_AMQP_CONSTANTS_TEST=PASS")
