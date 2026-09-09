# AMQP 0-9-1 frame codec.
#
# Parses wire bytes into AMQP frames and serializes frames to bytes.
# Frame format: type(1) + channel(2) + size(4) + payload(N) + end(1)
#
# Untrusted-input policy (audit §9/§13/§18/§29): every reject below is a
# catchable `AMQP frame error:` raise; the codec never allocates on a DECLARED
# size and never retains more than one maximum-size frame.

from std.collections import List
from std.memory import unsafe_memcpy

from hyrx.amqp.constants import (
    FRAME_BODY,
    FRAME_END,
    FRAME_HEADER,
    FRAME_HEARTBEAT,
    FRAME_METHOD,
)
from hyrx.core.feature_flags import contiguous_batch_enabled


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
        """Return an owned copy of the payload bytes."""
        if contiguous_batch_enabled():
            return self.payload.copy()
        else:
            var result = List[UInt8](capacity=len(self.payload))
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

    P2 cursor design: `_cursor` tracks the current read position in `_buffer`.
    After parsing a frame, `_cursor` advances past it. Compaction (shifting
    unparsed bytes to index 0) happens only when the cursor passes half the
    buffer, not per-frame. This eliminates the O(n)-per-frame remaining rebuild.
    """

    var _buffer: List[UInt8]
    var _max_frame_size: Int
    var _cursor: Int

    def __init__(out self, max_frame_size: Int = DEFAULT_MAX_FRAME_SIZE()):
        """Create a codec with a payload ceiling of `max_frame_size` bytes.

        The ceiling must be positive; callers pass a validated configuration
        value (see HyrxMQConfig.frame_max / validate()).
        """
        self._buffer = List[UInt8]()
        self._max_frame_size = max_frame_size
        self._cursor = 0

    def frame_limit(ref self) -> Int:
        """Maximum legal payload size for one frame (bytes)."""
        return self._max_frame_size

    def buffered_bytes(ref self) -> Int:
        """Bytes currently retained in the internal buffer (unparsed backlog).

        Invariant enforced by feed_bytes/try_parse_frame: this never exceeds
        `frame_limit() + _FRAME_OVERHEAD()`.
        """
        return len(self._buffer) - self._cursor

    def _compact(mut self):
        """Shift unparsed bytes to index 0 when cursor is past halfway.

        Called by try_parse_frame after advancing the cursor. Amortized O(1):
        each byte is moved at most once across all compactions.

        Contiguous path: in-place left-shift, overlap-safe (plain memcpy OK)
        only under the precondition remaining <= cursor; enforced by an
        explicit branch guard, with a fresh-alloc copy as the fallback when
        the caller violates the precondition.
        """
        if self._cursor == 0:
            return
        var remaining = len(self._buffer) - self._cursor
        if remaining > 0:
            if contiguous_batch_enabled():
                if remaining <= self._cursor:
                    # In-place left-shift: precondition remaining <= cursor
                    # holds (feed_bytes compacts only once the cursor is past
                    # half the buffer), so the write region [0, remaining)
                    # never overlaps the read region [cursor,
                    # cursor+remaining) and plain memcpy is safe. The src
                    # origin is erased so the two pointers into one List pass
                    # the exclusivity check (same-buffer dest/src).
                    var src_ptr = (
                        (self._buffer.unsafe_ptr() + self._cursor)
                        .as_unsafe_any_origin()
                    )
                    unsafe_memcpy(
                        dest=self._buffer.unsafe_ptr(),
                        src=src_ptr,
                        count=remaining,
                    )
                    self._buffer.resize(unsafe_uninit_length=remaining)
                else:
                    # Precondition violated by the caller: fresh alloc, copy
                    # back (overlap-free).
                    var new_buf = List[UInt8](capacity=remaining)
                    new_buf.resize(unsafe_uninit_length=remaining)
                    unsafe_memcpy(
                        dest=new_buf.unsafe_ptr(),
                        src=self._buffer.unsafe_ptr() + self._cursor,
                        count=remaining,
                    )
                    self._buffer = new_buf^
            else:
                var new_buf = List[UInt8](capacity=remaining)
                for i in range(self._cursor, len(self._buffer)):
                    new_buf.append(self._buffer[i])
                self._buffer = new_buf^
        else:
            self._buffer.clear()
        self._cursor = 0

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
        # P2: compact before feed if cursor is past half the buffer
        if self._cursor > 0 and self._cursor > len(self._buffer) // 2:
            self._compact()
        var limit = self._max_frame_size + _FRAME_OVERHEAD()
        if len(data) > limit - self.buffered_bytes():
            _ = _frame_error(
                "buffer accumulation "
                + String(self.buffered_bytes() + len(data))
                + " bytes exceeds the buffered-frame limit "
                + String(limit)
                + " bytes"
            )
        if contiguous_batch_enabled():
            # block copy: grow buffer in-place, memcpy data
            var old_len = len(self._buffer)
            var new_len = old_len + len(data)
            self._buffer.resize(unsafe_uninit_length=new_len)
            unsafe_memcpy(
                dest=self._buffer.unsafe_ptr() + old_len,
                src=data.unsafe_ptr(),
                count=len(data),
            )
        else:
            for i in range(len(data)):
                self._buffer.append(data[i])

    def try_parse_frame(mut self) raises -> Optional[AMQPFrame]:
        """Try to parse a complete frame from the buffer.
        Returns None if not enough data.

        Raises the catchable `AMQP frame error:` when the frame is provably
        malformed: an illegal frame_type octet, a declared payload larger
        than frame_limit(), or a wrong frame-end byte.

        P2 cursor design: reads from self._cursor offset, advances cursor
        past the parsed frame. No remaining-rebuild copy.
        """
        # Reject an illegal frame type as soon as the first octet arrives, so
        # garbage cannot be buffered at all.
        if self.buffered_bytes() >= 1:
            var t = self._buffer[self._cursor]
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
        if self.buffered_bytes() < 7:
            return Optional[AMQPFrame]()

        var c = self._cursor
        var frame_type = self._buffer[c]
        var channel = (UInt16(self._buffer[c + 1]) << 8) | UInt16(self._buffer[c + 2])
        var size = (
            (UInt32(self._buffer[c + 3]) << 24) |
            (UInt32(self._buffer[c + 4]) << 16) |
            (UInt32(self._buffer[c + 5]) << 8) |
            UInt32(self._buffer[c + 6])
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
        if self.buffered_bytes() < total:
            return Optional[AMQPFrame]()

        # Extract payload — read from cursor offset
        var payload = List[UInt8](capacity=Int(size))
        var payload_start = c + 7
        var payload_end = c + 7 + Int(size)
        if contiguous_batch_enabled():
            payload.resize(unsafe_uninit_length=Int(size))
            unsafe_memcpy(
                dest=payload.unsafe_ptr(),
                src=self._buffer.unsafe_ptr() + payload_start,
                count=Int(size),
            )
        else:
            for i in range(payload_start, payload_end):
                payload.append(self._buffer[i])

        # Verify frame end byte
        var end_byte = self._buffer[payload_end]
        if end_byte != FRAME_END():
            _ = _frame_error(
                "frame end byte "
                + String(Int(end_byte))
                + " is not 0xCE"
            )

        # P2: advance cursor past this frame (no rebuild copy)
        self._cursor = c + total

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
        if contiguous_batch_enabled():
            for i in range(len(args)):
                result.append(args[i])
        else:
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
        if contiguous_batch_enabled():
            for i in range(len(properties)):
                result.append(properties[i])
        else:
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
        # body bytes (8 = type+channel+size = frame header before payload)
        var n = len(body)
        if contiguous_batch_enabled():
            # pre-size result: 7 header + n body + 1 end = n+8
            result.resize(unsafe_uninit_length=n + 8)
            unsafe_memcpy(
                dest=result.unsafe_ptr() + 7,
                src=body.unsafe_ptr(),
                count=n,
            )
            # write frame end at index 7+n (result already has length n+8)
            result[7 + n] = 0xCE
        else:
            for i in range(len(body)):
                result.append(body[i])
            # frame end
            result.append(0xCE)
        return result^

    @staticmethod
    def append_body_frame(
        mut out: List[UInt8],
        chan: UInt16,
        payload: UnsafePointer[UInt8, _],
        count: Int,
    ) raises:
        """Append ONE body frame in place, byte-identical to encode_body_frame.

        Wire-byte-identity contract: appends EXACTLY the octets
        encode_body_frame writes for the same channel/payload — type=3 (BODY),
        channel(2)=chan (big-endian), size(4)=count (big-endian) +
        payload(count) + frame-end(1), so the frame occupies 7 + count + 1 =
        count + 8 octets.

        Contiguous path (flag True): ONE resize(+count+8), the 7 header octets
        written in place, one unsafe_memcpy of the payload, one frame-end
        octet — no intermediate payload list. Flag False: the elementwise
        append/loop sequence encode_body_frame uses for its owned-list path —
        identical octets.
        """
        if contiguous_batch_enabled():
            var old_len = len(out)
            var total = 7 + count + 1
            out.resize(unsafe_uninit_length=old_len + total)
            out[old_len] = 3
            out[old_len + 1] = UInt8((chan >> 8) & 0xFF)
            out[old_len + 2] = UInt8(chan & 0xFF)
            out[old_len + 3] = UInt8((count >> 24) & 0xFF)
            out[old_len + 4] = UInt8((count >> 16) & 0xFF)
            out[old_len + 5] = UInt8((count >> 8) & 0xFF)
            out[old_len + 6] = UInt8(count & 0xFF)
            unsafe_memcpy(
                dest=out.unsafe_ptr() + old_len + 7, src=payload, count=count
            )
            out[old_len + 7 + count] = 0xCE
        else:
            # Elementwise fallback: mirror the encode_body_frame append
            # sequence exactly (same octets, elementwise).
            out.append(3)
            out.append(UInt8((chan >> 8) & 0xFF))
            out.append(UInt8(chan & 0xFF))
            out.append(UInt8((count >> 24) & 0xFF))
            out.append(UInt8((count >> 16) & 0xFF))
            out.append(UInt8((count >> 8) & 0xFF))
            out.append(UInt8(count & 0xFF))
            for i in range(count):
                out.append(payload[i])
            out.append(0xCE)

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
    var rest = List[UInt8](capacity=len(args) - 4)
    if contiguous_batch_enabled():
        for i in range(4, len(args)):
            rest.append(args[i])
    else:
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
    var props = List[UInt8](capacity=len(payload) - 14)
    if contiguous_batch_enabled():
        for i in range(14, len(payload)):
            props.append(payload[i])
    else:
        for i in range(14, len(payload)):
            props.append(payload[i])
    return HeaderFrame(class_id, weight, body_size, property_flags, props^)
