# Tests for Message ownership and envelope semantics.
#
# Covers: construction, delivery count, payload snapshot (owned copy).

from hyrx.core.buffer import Buffer
from hyrx.core.message import Message, MessageID, Envelope

from hyrx.testing import check

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
    check(msg.routing_key() == "orders.new", "L19 expect: msg.routing_key() == 'orders.new'")
    check(msg.delivery_count() == 0, "L20 expect: msg.delivery_count() == 0")

def test_delivery_count() raises:
    """Increment delivery count monotonically increases."""
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(1), "test", headers^)
    var msg = Message(env^, Buffer(16))

    msg.increment_delivery_count()
    msg.increment_delivery_count()
    msg.increment_delivery_count()
    check(msg.delivery_count() == 3, "L31 expect: msg.delivery_count() == 3")

def test_payload_view() raises:
    """An owned copy returned by payload() matching the buffer."""
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
    check(view.size() == 5, "L47 expect: view.size() == 5")
    check(view[0] == 0x01, "L48 expect: view[0] == 0x01")
    check(view[4] == 0x05, "L49 expect: view[4] == 0x05")

def test_message_id_equality() raises:
    """MessageID equality compares underlying value."""
    var a = MessageID(100)
    var b = MessageID(100)
    var c = MessageID(200)
    check(a == b, "L56 expect: a == b")
    check(not (a == c), "L57 expect: not (a == c)")

def test_payload_into() raises:
    """payload_into fills a length-0 dst in one pass; bytes match the payload."""
    var payload = Buffer(8)
    _ = payload.resize(5)
    for i in range(5):
        payload[i] = UInt8(i + 1)
    var snap = payload.snapshot()
    var headers = Dict[String, String]()
    var env = Envelope(MessageID(42), "rk", headers^)
    var msg = Message(env^, payload^)
    var dst = Buffer(16)
    check(dst.size() == 0, "L: dst starts empty")
    var filled = msg.payload_into(dst^)
    check(filled.size() == 5, "L: filled length equals payload length")
    var same = True
    for i in range(5):
        if filled[i] != snap[i]:
            same = False
    check(same, "L: filled bytes identical to payload")
    check(msg.payload().size() == 5, "L: message still owns its 5-byte payload")

def main() raises:
    test_create_message()
    test_delivery_count()
    test_payload_view()
    test_message_id_equality()
    test_payload_into()
    print("MESSAGE_TEST=PASS")
