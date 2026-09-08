# AMQP 0-9-1 frame codec.
#
# Parses wire bytes into AMQP frames and serializes frames to bytes.
# Frame format: type(1) + channel(2) + size(4) + payload(N) + end(1)

from std.collections import List

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
    """Parsed AMQP content header frame."""
    var class_id: UInt16
    var body_size: UInt64
    var properties: List[UInt8]

    def __init__(out self, class_id: UInt16, body_size: UInt64, var properties: List[UInt8]):
        self.class_id = class_id
        self.body_size = body_size
        self.properties = properties^


struct AMQPFrameCodec:
    """Encodes and decodes AMQP 0-9-1 frames."""

    var _buffer: List[UInt8]

    def __init__(out self):
        self._buffer = List[UInt8]()

    def feed_bytes(mut self, var data: List[UInt8]):
        """Feed incoming bytes into the codec buffer."""
        for i in range(len(data)):
            self._buffer.append(data[i])

    def try_parse_frame(mut self) raises -> Optional[AMQPFrame]:
        """Try to parse a complete frame from the buffer.
        Returns None if not enough data.
        """
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
        if end_byte != 0xCE:
            raise "AMQP frame end byte mismatch"

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
        var properties: List[UInt8],
    ) -> List[UInt8]:
        """Encode a content header frame."""
        var result = List[UInt8]()
        # type = HEADER (2)
        result.append(2)
        # channel
        result.append(UInt8((channel >> 8) & 0xFF))
        result.append(UInt8(channel & 0xFF))
        # payload size = 2 (class_id) + 8 (body_size) + properties_len
        var payload_size = 10 + len(properties)
        result.append(UInt8((payload_size >> 24) & 0xFF))
        result.append(UInt8((payload_size >> 16) & 0xFF))
        result.append(UInt8((payload_size >> 8) & 0xFF))
        result.append(UInt8(payload_size & 0xFF))
        # class_id
        result.append(UInt8((class_id >> 8) & 0xFF))
        result.append(UInt8(class_id & 0xFF))
        # body_size (8 bytes, big-endian)
        result.append(UInt8((body_size >> 56) & 0xFF))
        result.append(UInt8((body_size >> 48) & 0xFF))
        result.append(UInt8((body_size >> 40) & 0xFF))
        result.append(UInt8((body_size >> 32) & 0xFF))
        result.append(UInt8((body_size >> 24) & 0xFF))
        result.append(UInt8((body_size >> 16) & 0xFF))
        result.append(UInt8((body_size >> 8) & 0xFF))
        result.append(UInt8(body_size & 0xFF))
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
    """Parse header frame payload into HeaderFrame."""
    if len(payload) < 10:
        raise "header frame payload too short"
    var class_id = (UInt16(payload[0]) << 8) | UInt16(payload[1])
    var body_size = (
        (UInt64(payload[2]) << 56) |
        (UInt64(payload[3]) << 48) |
        (UInt64(payload[4]) << 40) |
        (UInt64(payload[5]) << 32) |
        (UInt64(payload[6]) << 24) |
        (UInt64(payload[7]) << 16) |
        (UInt64(payload[8]) << 8) |
        UInt64(payload[9])
    )
    var props = List[UInt8]()
    for i in range(10, len(payload)):
        props.append(payload[i])
    return HeaderFrame(class_id, body_size, props^)
