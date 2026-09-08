# Tests for Message ownership and envelope semantics.
#
# Covers: construction, delivery count, payload view.

from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope

def test_create_message() raises:
    """Message stores envelope and owns the payload buffer."""
    var headers = Dict[String, String]()
    headers["content-type"] = "application/octet-stream"
    var env = Envelope(MessageID(42), "orders.new", headers^)
    var payload = Buffer(64)
    payload.resize(8)
    payload[0] = 0xCA
    payload[1] = 0xFE

    var msg = Message(env^, payload^)
    assert msg.routing_key() == "orders.new"
    assert msg.delivery_count() == 0

def test_delivery_count() raises:
    """Increment delivery count monotonically increases."""
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(1), "test", headers^)
    var msg = Message(env^, Buffer(16))

    msg.increment_delivery_count()
    msg.increment_delivery_count()
    msg.increment_delivery_count()
    assert msg.delivery_count() == 3

def test_payload_view() raises:
    """Payload view returns data matching the buffer."""
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(7), "data", headers^)
    var buf = Buffer(32)
    buf.resize(5)
    buf[0] = 0x01
    buf[1] = 0x02
    buf[2] = 0x03
    buf[3] = 0x04
    buf[4] = 0x05

    var msg = Message(env^, buf^)
    var view = msg.payload()
    assert view.size() == 5
    assert view[0] == 0x01
    assert view[4] == 0x05

def test_message_id_equality() raises:
    """MessageID equality compares underlying value."""
    var a = MessageID(100)
    var b = MessageID(100)
    var c = MessageID(200)
    assert a == b
    assert not (a == c)

def main() raises:
    test_create_message()
    test_delivery_count()
    test_payload_view()
    test_message_id_equality()
    print("MESSAGE_TEST=PASS")
