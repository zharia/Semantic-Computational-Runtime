# Message = envelope + payload with ownership tracking.
#
# Ownership model:
#   - Message owns its Envelope (value semantics).
#   - Message owns its Buffer payload; ownership transfers on move.
#   - payload() COPIES the bytes into an owned BufferSnapshot; the
#     Message keeps owning its payload and is unchanged by the call.
#
# Mojo 1.0 requires explicit move semantics for non-trivial types.
# All constructors accept owned (var) parameters and transfer with ^.

from std.collections import List

from hyrx.core.buffer import Buffer
from hyrx.core.buffer_snapshot import BufferSnapshot
from hyrx.core.feature_flags import contiguous_batch_enabled
from std.memory import unsafe_memcpy


# 0017 T2: byte-faithful AMQP content properties.
#
# A publisher's content HEADER frame is stored AS RECEIVED: the property-flag
# word plus the RAW property-list bytes that follow it. Per amqp0-9-1 §2.3.5.2
# the flag-list bits encode WHICH properties follow, and the bytes after the
# flags are exactly the per-property values in spec order. Transmitting
# (flag word, slice) verbatim reproduces the publisher's attributes
# byte-identically; no re-serialization happens anywhere (the only transmitted
# parts that are re-written are the frame envelope fields, which the codec
# owns). Individual property values are DERIVED at parse time (decode plane),
# never stored: storing them would double-represent the same semantics.
struct ContentProps:
    """Byte-faithful AMQP content properties (raw + flag word)."""

    var flags: UInt16
    var bytes: List[UInt8]

    def __init__(out self):
        self.flags = 0
        self.bytes = List[UInt8]()

    def __init__(out self, prop_flags: UInt16, var prop_bytes: List[UInt8]):
        self.flags = prop_flags
        self.bytes = prop_bytes^

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

    def message_id(ref self) -> MessageID:
        """Return an independent value of this envelope's identifier."""
        return MessageID(self._message_id.to_uint64())

    def routing_key(self) -> String:
        return self._routing_key

    def headers(ref self) -> Dict[String, String]:
        """Return an independent owned copy of this envelope's header map."""
        return self._headers.copy()

struct Message:
    """A complete message: envelope (metadata) + payload (bytes).

    Ownership: Message owns both its Envelope and its Buffer payload.
    """

    var _envelope: Envelope
    var _payload: Buffer
    var _delivery_count: Int
    # 0017 T2: byte-faithful inbound content properties (AMQP flag word +
    # raw property-list slice). Empty (flags 0) for engine-internal messages.
    var _props: ContentProps

    def __init__(out self, var envelope: Envelope, var payload: Buffer):
        """Construct a message, taking ownership of the payload buffer.

        Ownership: `payload` is moved into this Message.
        """
        self._envelope = envelope^
        self._payload = payload^
        self._delivery_count = 0
        self._props = ContentProps()

    # 0017 T2 additive constructor: same message but carrying content props.
    def __init__(
        out self,
        var envelope: Envelope,
        var payload: Buffer,
        prop_flags: UInt16,
        var prop_bytes: List[UInt8],
    ):
        self._envelope = envelope^
        self._payload = payload^
        self._delivery_count = 0
        self._props = ContentProps(prop_flags, prop_bytes^)

    def content_prop_flags(ref self) -> UInt16:
        """The raw AMQP property-flag word the publisher sent."""
        return self._props.flags

    def content_prop_bytes_copy(ref self) -> List[UInt8]:
        """An owned copy of the raw AMQP property-list bytes."""
        return self._props.bytes.copy()

    def has_content_props(ref self) -> Bool:
        return self._props.flags != 0 or len(self._props.bytes) != 0

    def envelope(self) -> Envelope:
        """Return a copy of the envelope metadata."""
        return self._envelope^

    def routing_key(self) -> String:
        """Shortcut: envelope routing key."""
        return self._envelope._routing_key

    def message_id(ref self) -> MessageID:
        """Return the published message identifier."""
        return self._envelope.message_id()

    def headers(ref self) -> Dict[String, String]:
        """Return an owned copy of the published header map."""
        return self._envelope.headers()

    def payload_copy(ref self) -> Buffer:
        """Return one owned, exact-length copy of the payload bytes."""
        return Buffer.from_buffer_copy(self._payload)

    def payload(ref self) -> BufferSnapshot:
        """Return an owned COPY of the payload bytes.

        Ownership: every byte is copied. The Message retains its own
        payload; the snapshot is independent of it.
        """
        return self._payload.snapshot()

    def payload_into(ref self, var dst: Buffer) -> Buffer:
        """Append the payload bytes into `dst` in ONE pass and return it.

        P1b pooled-copy primitive: the caller supplies a length-0 buffer
        (typically from `BufferPool.acquire(payload_size)`) and receives it
        back filled. This lets a fan-out copy reuse a pooled buffer WITHOUT a
        second (allocate-zero-then-overwrite) pass, preserving the WP-B win.
        Ownership: `dst` moves in and out; the Message keeps its own payload.
        """
        var n = self._payload.size()
        if contiguous_batch_enabled():
            dst.resize_uninit(n)
            unsafe_memcpy(
                dest=dst._data.unsafe_ptr(),
                src=self._payload._data.unsafe_ptr(),
                count=n,
            )
        else:
            for i in range(n):
                dst.append(self._payload[i])
        return dst^

    def payload_size(ref self) -> Int:
        """Logical payload length (no copy)."""
        return self._payload.size()

    def take_payload(mut self) -> Buffer:
        """Detach and return the payload Buffer; leave this Message's payload empty.

        Pool-reclaim primitive (p1b): the Router hands the returned Buffer to
        BufferPool.release (a no-op if it was never pooled). The Message keeps an
        empty buffer and drops harmlessly.
        """
        return self._payload.take_data()

    def increment_delivery_count(mut self):
        """Record one more delivery attempt."""
        self._delivery_count += 1

    def delivery_count(self) -> Int:
        return self._delivery_count
