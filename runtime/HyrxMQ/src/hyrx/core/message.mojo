# Message = envelope + payload with ownership tracking.
#
# Ownership model:
#   - Message owns its Envelope (value semantics).
#   - Message owns its Buffer payload; ownership transfers on move.
#   - payload_view() returns a snapshot; caller manages its lifetime.
#
# Mojo 1.0 requires explicit move semantics for non-trivial types.
# All constructors accept owned (var) parameters and transfer with ^.

from hyrx.core.buffer import Buffer
from hyrx.core.buffer_view import BufferView

struct MessageID:
    """Globally unique message identifier. Opaque 64-bit value."""

    var _value: UInt64

    def __init__(out self, val: UInt64):
        self._value = val

    def to_uint64(self) -> UInt64:
        return self._value

    def __eq__(self, other: MessageID) -> Bool:
        return self._value == other._value

struct Envelope:
    """Routing metadata for a message. Carries no payload data."""

    var _message_id: MessageID
    var _routing_key: String
    var _headers: Dict[String, String]

    def __init__(
        out self,
        var message_id: MessageID,
        var routing_key: String,
        var headers: Dict[String, String],
    ):
        self._message_id = message_id^
        self._routing_key = routing_key^
        self._headers = headers^

    def message_id(self) -> MessageID:
        return self._message_id^

    def routing_key(self) -> String:
        return self._routing_key

    def headers(self) -> Dict[String, String]:
        return self._headers^

struct Message:
    """A complete message: envelope (metadata) + payload (bytes).

    Ownership: Message owns both its Envelope and its Buffer payload.
    """

    var _envelope: Envelope
    var _payload: Buffer
    var _delivery_count: Int

    def __init__(out self, var envelope: Envelope, var payload: Buffer):
        """Construct a message, taking ownership of the payload buffer.

        Ownership: `payload` is moved into this Message.
        """
        self._envelope = envelope^
        self._payload = payload^
        self._delivery_count = 0

    def envelope(self) -> Envelope:
        """Return a copy of the envelope metadata."""
        return self._envelope^

    def routing_key(self) -> String:
        """Shortcut: envelope routing key."""
        return self._envelope._routing_key

    def payload(ref self) -> BufferView:
        """Return a snapshot view of the payload bytes."""
        return self._payload.as_view()

    def increment_delivery_count(mut self):
        """Record one more delivery attempt."""
        self._delivery_count += 1

    def delivery_count(self) -> Int:
        return self._delivery_count
