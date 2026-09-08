# AMQP 0-9-1 frame codec.
#
# Parses wire bytes into AMQP frames and serializes frames to bytes.
# Frame format: type(1) + channel(2) + size(4) + payload(N) + end(1)
#
# Untrusted-input policy (audit §9/§13/§18/§29): every reject below is a
# catchable `AMQP frame error:` raise; the codec never allocates on a DECLARED
# size and never retains more than one maximum-size frame.

from std.collections import List

from hyrx.amqp.constants import (
    FRAME_BODY,
    FRAME_END,
    FRAME_HEADER,
    FRAME_HEARTBEAT,
    FRAME_METHOD,
)


def DEFAULT_MAX_FRAME_SIZE() -> Int:
    """Provisional fixed payload ceiling (bytes) for every codec instance."""
    return 131072


def _FRAME_OVERHEAD() -> Int:
    """Octets framing a payload: type(1) + channel(2) + size(4) + end(1)."""
    return 8


def _frame_error(var reason: String) raises:
    """Raise the dedicated AMQP frame error.

    Type: `Error` carrying the stable prefix `AMQP frame error:` — Mojo 1.0's
    `Error` is a builtin struct, not a trait, so it cannot be subclassed; the
    prefixed message is the discriminator. It is always catchable (`try/except`)
    and never leaves the process: callers on the network path must catch it and
    fail the connection closed.
    """
    raise Error("AMQP frame error: " + reason)


struct AMQPFrame:
    """Parsed AMQP frame."""
    var frame_type: UInt8
    var channel: UInt16
    var payload: List[UInt8]

    def __init__(out self, frame_type: UInt8, channel: UInt16, var payload: List[UInt8]):
        self.frame_type = frame_type
        self.channel = channel
        self.payload = payload^

    def payload_size(ref self) -> Int:
        return len(self.payload)

    def payload_copy(ref self) -> List[UInt8]:
        var result = List[UInt8]()
        for i in range(len(self.payload)):
            result.append(self.payload[i])
        return result^


struct MethodFrame:
    """Parsed AMQP method frame."""
    var class_id: UInt16
    var method_id: UInt16
    var args: List[UInt8]

    def __init__(out self, class_id: UInt16, method_id: UInt16, var args: List[UInt8]):
        self.class_id = class_id
        self.method_id = method_id
        self.args = args^


struct HeaderFrame:
    """Parsed AMQP content header frame.

    Wire layout (amqp0-9-1 §2.3.5.2):
      class-id(2) weight(2, MUST be 0) body-size(8) property-flags(2) property-list
    `properties` holds the property-list bytes that follow the flags.
    """
    var class_id: UInt16
    var weight: UInt16
    var body_size: UInt64
    var property_flags: UInt16
    var properties: List[UInt8]

    def __init__(
        out self,
        class_id: UInt16,
        weight: UInt16,
        body_size: UInt64,
        property_flags: UInt16,
        var properties: List[UInt8],
    ):
        self.class_id = class_id
        self.weight = weight
        self.body_size = body_size
        self.property_flags = property_flags
        self.properties = properties^


# NOT IMPLEMENTED: per-connection frame_max NEGOTIATION (connection.tune /
# connection.tune-ok, amqp0-9-1 §2.3.5.3). The broker advertises no tune frame,
# so AMQPFrameCodec.max_frame_size is a provisional FIXED ceiling taken from
# HyrxMQConfig.frame_max — never describe it as negotiated.

struct AMQPFrameCodec:
    """Encodes and decodes AMQP 0-9-1 frames.

    Memory bound (audit §9/§18): no allocation here is driven by untrusted
    input. The declared `size` is validated against `frame_limit()` BEFORE any
    payload is copied out, and `feed_bytes` refuses to grow the internal buffer
    beyond `frame_limit() + 8` (one whole frame, worst case). Violations raise
    the catchable `AMQP frame error:` rather than allocating.

    NOTE: `max_frame_size` is a PROVISIONAL FIXED ceiling, NOT a negotiated
    one — see the NOT IMPLEMENTED marker above this struct.
    """

    var _buffer: List[UInt8]
    var _max_frame_size: Int

    def __init__(out self, max_frame_size: Int = DEFAULT_MAX_FRAME_SIZE()):
        """Create a codec with a payload ceiling of `max_frame_size` bytes.

        The ceiling must be positive; callers pass a validated configuration
        value (see HyrxMQConfig.frame_max / validate()).
        """
        self._buffer = List[UInt8]()
        self._max_frame_size = max_frame_size

    def frame_limit(ref self) -> Int:
        """Maximum legal payload size for one frame (bytes)."""
        return self._max_frame_size

    def buffered_bytes(ref self) -> Int:
        """Bytes currently retained in the internal buffer.

        Invariant enforced by feed_bytes/try_parse_frame: this never exceeds
        `frame_limit() + _FRAME_OVERHEAD()`.
        """
        return len(self._buffer)

    def feed_bytes(mut self, var data: List[UInt8]) raises:
        """Feed incoming bytes into the codec buffer.

        Raises when the accumulation would exceed the ceiling — a client that
        dribbles bytes toward a never-complete oversized frame is rejected
        instead of being buffered.

        The bound counts UNPARSED backlog, so a caller that feeds must drain
        complete frames with try_parse_frame() between reads: a backlog larger
        than one maximum-size frame is failed closed. The listener satisfies
        this (it parses every step and reads at most 64 KiB per step).
        """
        var limit = self._max_frame_size + _FRAME_OVERHEAD()
        if len(data) > limit - len(self._buffer):
            _ = _frame_error(
                "buffer accumulation "
                + String(len(self._buffer) + len(data))
                + " bytes exceeds the buffered-frame limit "
                + String(limit)
                + " bytes"
            )
        for i in range(len(data)):
            self._buffer.append(data[i])

    def try_parse_frame(mut self) raises -> Optional[AMQPFrame]:
        """Try to parse a complete frame from the buffer.
        Returns None if not enough data.

        Raises the catchable `AMQP frame error:` when the frame is provably
        malformed: an illegal frame_type octet, a declared payload larger
        than frame_limit(), or a wrong frame-end byte.
        """
        # Reject an illegal frame type as soon as the first octet arrives, so
        # garbage cannot be buffered at all.
        if len(self._buffer) >= 1:
            var t = self._buffer[0]
            if (
                t != FRAME_METHOD()
                and t != FRAME_HEADER()
                and t != FRAME_BODY()
                and t != FRAME_HEARTBEAT()
            ):
                _ = _frame_error(
                    "bad frame_type "
                    + String(Int(t))
                    + " (valid: 1=METHOD, 2=HEADER, 3=BODY, 8=HEARTBEAT)"
                )

        # Need at least 7 bytes: type(1) + channel(2) + size(4)
        if len(self._buffer) < 7:
            return Optional[AMQPFrame]()

        var frame_type = self._buffer[0]
        var channel = (UInt16(self._buffer[1]) << 8) | UInt16(self._buffer[2])
        var size = (
            (UInt32(self._buffer[3]) << 24) |
            (UInt32(self._buffer[4]) << 16) |
            (UInt32(self._buffer[5]) << 8) |
            UInt32(self._buffer[6])
        )

        # Validate the DECLARED size before touching payload bytes: an oversized
        # frame is malformed now, no matter how many bytes have arrived.
        if Int(size) > self._max_frame_size:
            _ = _frame_error(
                "declared frame size "
                + String(Int(size))
                + " exceeds the frame ceiling "
                + String(self._max_frame_size)
            )

        # Check if we have the full frame (7 + size + 1 for end byte)
        var total = 7 + Int(size) + 1
        if len(self._buffer) < total:
            return Optional[AMQPFrame]()

        # Extract payload
        var payload = List[UInt8]()
        for i in range(7, 7 + Int(size)):
            payload.append(self._buffer[i])

        # Verify frame end byte
        var end_byte = self._buffer[7 + Int(size)]
        if end_byte != FRAME_END():
            _ = _frame_error(
                "frame end byte "
                + String(Int(end_byte))
                + " is not 0xCE"
            )

        # Remove consumed bytes from buffer
        var remaining = List[UInt8]()
        for i in range(total, len(self._buffer)):
            remaining.append(self._buffer[i])
        self._buffer = remaining^

        return AMQPFrame(frame_type, channel, payload^)

    @staticmethod
    def encode_method_frame(
        channel: UInt16,
        class_id: UInt16,
        method_id: UInt16,
        var args: List[UInt8],
    ) -> List[UInt8]:
        """Encode a method frame."""
        var result = List[UInt8]()
        # type
        result.append(1)
        # channel (2 bytes big-endian)
        result.append(UInt8((channel >> 8) & 0xFF))
        result.append(UInt8(channel & 0xFF))
        # payload size = 4 (class+method) + args_len
        var payload_size = 4 + len(args)
        result.append(UInt8((payload_size >> 24) & 0xFF))
        result.append(UInt8((payload_size >> 16) & 0xFF))
        result.append(UInt8((payload_size >> 8) & 0xFF))
        result.append(UInt8(payload_size & 0xFF))
        # class_id + method_id
        result.append(UInt8((class_id >> 8) & 0xFF))
        result.append(UInt8(class_id & 0xFF))
        result.append(UInt8((method_id >> 8) & 0xFF))
        result.append(UInt8(method_id & 0xFF))
        # args
        for i in range(len(args)):
            result.append(args[i])
        # frame end
        result.append(0xCE)
        return result^

    @staticmethod
    def encode_header_frame(
        channel: UInt16,
        class_id: UInt16,
        body_size: UInt64,
        property_flags: UInt16,
        var properties: List[UInt8],
    ) -> List[UInt8]:
        """Encode a content header frame.

        Emits the §2.3.5.2 layout: class-id(2) weight(2) body-size(8)
        property-flags(2) property-list. `properties` is the property-list
        (the bytes AFTER the 2 flag octets). The weight field is reserved and
        MUST be zero (§2.3.5.2), so it is always written as 0.
        """
        var result = List[UInt8]()
        # type = HEADER (2)
        result.append(2)
        # channel
        result.append(UInt8((channel >> 8) & 0xFF))
        result.append(UInt8(channel & 0xFF))
        # payload size = 2 (class_id) + 2 (weight) + 8 (body_size)
        #                + 2 (property_flags) + properties_len
        var payload_size = 14 + len(properties)
        result.append(UInt8((payload_size >> 24) & 0xFF))
        result.append(UInt8((payload_size >> 16) & 0xFF))
        result.append(UInt8((payload_size >> 8) & 0xFF))
        result.append(UInt8(payload_size & 0xFF))
        # class_id
        result.append(UInt8((class_id >> 8) & 0xFF))
        result.append(UInt8(class_id & 0xFF))
        # weight (reserved, MUST be 0)
        result.append(UInt8(0))
        result.append(UInt8(0))
        # body_size (8 bytes, big-endian)
        result.append(UInt8((body_size >> 56) & 0xFF))
        result.append(UInt8((body_size >> 48) & 0xFF))
        result.append(UInt8((body_size >> 40) & 0xFF))
        result.append(UInt8((body_size >> 32) & 0xFF))
        result.append(UInt8((body_size >> 24) & 0xFF))
        result.append(UInt8((body_size >> 16) & 0xFF))
        result.append(UInt8((body_size >> 8) & 0xFF))
        result.append(UInt8(body_size & 0xFF))
        # property_flags
        result.append(UInt8((property_flags >> 8) & 0xFF))
        result.append(UInt8(property_flags & 0xFF))
        # properties
        for i in range(len(properties)):
            result.append(properties[i])
        # frame end
        result.append(0xCE)
        return result^

    @staticmethod
    def encode_body_frame(
        channel: UInt16, var body: List[UInt8]
    ) -> List[UInt8]:
        """Encode a content body frame."""
        var result = List[UInt8]()
        # type = BODY (3)
        result.append(3)
        # channel
        result.append(UInt8((channel >> 8) & 0xFF))
        result.append(UInt8(channel & 0xFF))
        # payload size
        var payload_size = len(body)
        result.append(UInt8((payload_size >> 24) & 0xFF))
        result.append(UInt8((payload_size >> 16) & 0xFF))
        result.append(UInt8((payload_size >> 8) & 0xFF))
        result.append(UInt8(payload_size & 0xFF))
        # body bytes
        for i in range(len(body)):
            result.append(body[i])
        # frame end
        result.append(0xCE)
        return result^

    @staticmethod
    def encode_heartbeat(channel: UInt16) -> List[UInt8]:
        """Encode a heartbeat frame."""
        var result = List[UInt8]()
        result.append(8)  # HEARTBEAT
        result.append(UInt8((channel >> 8) & 0xFF))
        result.append(UInt8(channel & 0xFF))
        result.append(0)
        result.append(0)
        result.append(0)
        result.append(0)  # size 0
        result.append(0xCE)
        return result^


def parse_method_args(var args: List[UInt8]) raises -> MethodFrame:
    """Parse method frame payload into MethodFrame."""
    if len(args) < 4:
        raise "method frame payload too short"
    var class_id = (UInt16(args[0]) << 8) | UInt16(args[1])
    var method_id = (UInt16(args[2]) << 8) | UInt16(args[3])
    var rest = List[UInt8]()
    for i in range(4, len(args)):
        rest.append(args[i])
    return MethodFrame(class_id, method_id, rest^)


def parse_header_frame_payload(
    var payload: List[UInt8]
) raises -> HeaderFrame:
    """Parse header frame payload into HeaderFrame.

    Layout (amqp0-9-1 §2.3.5.2):
      [0:2]   class-id
      [2:4]   weight (reserved, MUST be 0)
      [4:12]  body-size
      [12:14] property-flags
      [14:]   property-list
    """
    if len(payload) < 14:
        raise "header frame payload too short"
    var class_id = (UInt16(payload[0]) << 8) | UInt16(payload[1])
    var weight = (UInt16(payload[2]) << 8) | UInt16(payload[3])
    if weight != 0:
        raise "AMQP content header frame weight must be zero"
    var body_size = (
        (UInt64(payload[4]) << 56) |
        (UInt64(payload[5]) << 48) |
        (UInt64(payload[6]) << 40) |
        (UInt64(payload[7]) << 32) |
        (UInt64(payload[8]) << 24) |
        (UInt64(payload[9]) << 16) |
        (UInt64(payload[10]) << 8) |
        UInt64(payload[11])
    )
    var property_flags = (UInt16(payload[12]) << 8) | UInt16(payload[13])
    var props = List[UInt8]()
    for i in range(14, len(payload)):
        props.append(payload[i])
    return HeaderFrame(class_id, weight, body_size, property_flags, props^)
