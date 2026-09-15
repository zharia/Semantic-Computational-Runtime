# AMQP 0-9-1 frame codec.
#
# Parses wire bytes into AMQP frames and serializes frames to bytes.
# Frame format: type(1) + channel(2) + size(4) + payload(N) + end(1)
#
# Untrusted-input policy (audit §9/§13/§18/§29): every reject below is a
# catchable `AMQP frame error:` raise; the codec never allocates on a DECLARED
# size and never retains more than one maximum-size frame.

from std.collections import List
from std.memory import unsafe_memcpy, UnsafePointer

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

    def payload_byte(ref self, i: Int) -> UInt8:
        """Borrow one payload octet (bounds-checked, NO copy).

        Used by byte-glue that inspects only a frame's leading method ids
        (class/method): ``payload_copy()`` there copied the ENTIRE payload,
        so a 256 KB body frame paid a 256 KB copy just to read 4 bytes —
        the dominant cost in the large-payload publish path.
        """
        return self.payload[i]

    def payload_copy(ref self) -> List[UInt8]:
        """Return an owned copy of the payload bytes."""
        if contiguous_batch_enabled():
            return self.payload.copy()
        else:
            var result = List[UInt8](capacity=len(self.payload))
            for i in range(len(self.payload)):
                result.append(self.payload[i])
            return result^

    def copy(self) -> AMQPFrame:
        """Return an independent owned copy of this frame.

        Used only by the borrowed-frame test entry point (AMQPService's
        handle_frame); the network path MOVES the parsed frame into the
        owned dispatch instead, so no payload restage happens there.
        """
        return AMQPFrame(self.frame_type, self.channel, self.payload.copy())


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


# frame_max NEGOTIATION (connection.tune / connection.tune-ok, amqp0-9-1
# §2.3.5.3): a codec is constructed with the SERVER ceiling from
# HyrxMQConfig.frame_max, and `set_frame_limit` re-limits it to the NEGOTIATED
# min(server, client) after the client's tune-ok arrives. A client `0` means
# "no limit" and is resolved to the server value by the service before the
# setter is called; the setter never raises the ceiling above the configured
# one.

struct AMQPFrameCodec:
    """Encodes and decodes AMQP 0-9-1 frames.

    Memory bound (audit §9/§18): no allocation here is driven by untrusted
    input. The declared `size` is validated against `frame_limit()` BEFORE any
    payload is copied out, and `feed_bytes` refuses to grow the internal buffer
    beyond `frame_limit() + 8` (one whole frame, worst case). Violations raise
    the catchable `AMQP frame error:` rather than allocating.

    The ceiling starts at the SERVER value passed to __init__ and may be
    lowered once by `set_frame_limit` to the negotiated min(server, client)
    after connection.tune-ok (see the negotiation marker above this struct).

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

    def set_frame_limit(mut self, limit: Int):
        """Re-limit this codec to a NEGOTIATED payload ceiling.

        Called by the listener after a client's connection.tune-ok so the
        negotiated min(server frame_max, client frame_max) is enforced on the
        codec for the rest of the connection (the codec is constructed with
        the server ceiling at register time, BEFORE tune-ok arrives). A
        non-positive `limit` is ignored: a client value of 0 means "no limit"
        and the service resolves it to the server value before calling here,
        so the ceiling is never removed or raised by this setter.
        """
        if limit > 0:
            self._max_frame_size = limit

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
            # Zero-copy feed: when the codec holds NO unparsed backlog (cursor
            # is at the end of the buffer), ADOPT the incoming chunk as the new
            # buffer instead of memcpy-ing it in. The listener reads at most one
            # frame's worth per step and parses every step, so the buffer is
            # fully drained on the common path — this removes a whole recv-size
            # copy per read (dominant for large bodies).
            if self._cursor >= len(self._buffer):
                self._buffer = data^
                self._cursor = 0
                return
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

    # ---- direct-recv seam (event tier): recv straight into the codec tail ----
    #
    # Additive to feed_bytes, which stays byte-for-byte for the blocking tier,
    # the tests and every embedder. These three calls let the listener hand the
    # codec's own tail buffer to recv(2), so an incoming chunk is written ONCE
    # by the kernel instead of being copied into a temp List and then appended
    # into the buffer. The unparsed-backlog bound is unchanged: the caller must
    # clamp the requested size with buffered_bytes()/frame_limit() exactly as it
    # does for feed_bytes.

    def stream_reserve(mut self, want: Int) raises -> Int:
        """Make room for `want` writable bytes at the buffer tail; return the
        byte offset of that tail. Amortized compaction mirrors feed_bytes: the
        cursor is only collapsed once it passes half the buffer. The caller
        recvs into ``stream_ptr() + offset`` and then calls stream_commit."""
        if want <= 0:
            return len(self._buffer)
        var limit = self._max_frame_size + _FRAME_OVERHEAD()
        if want > limit - self.buffered_bytes():
            _ = _frame_error(
                "buffer accumulation "
                + String(self.buffered_bytes() + want)
                + " bytes exceeds the buffered-frame limit "
                + String(limit)
                + " bytes"
            )
        if self._cursor > 0 and self._cursor > len(self._buffer) // 2:
            self._compact()
        if self._cursor >= len(self._buffer):
            self._buffer.clear()
            self._cursor = 0
        var old = len(self._buffer)
        self._buffer.resize(unsafe_uninit_length=old + want)
        return old

    def stream_ptr(mut self) -> UnsafePointer[UInt8, MutUnsafeAnyOrigin]:
        """Writable base pointer of the codec buffer (see stream_reserve)."""
        return self._buffer.unsafe_ptr().as_unsafe_any_origin()

    def stream_commit(mut self, offset: Int, got: Int):
        """Commit `got` bytes recv'd at `offset` (or roll back with got == 0)."""
        self._buffer.resize(unsafe_uninit_length=offset + got)

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
        var payload_start = c + 7
        var payload_end = c + 7 + Int(size)
        # One allocation with the final length already set (no separate
        # capacity-reserve + resize pair).
        var payload = List[UInt8](unsafe_uninit_length=Int(size))
        if contiguous_batch_enabled():
            unsafe_memcpy(
                dest=payload.unsafe_ptr(),
                src=self._buffer.unsafe_ptr() + payload_start,
                count=Int(size),
            )
        else:
            for i in range(payload_start, payload_end):
                payload[i - payload_start] = self._buffer[i]

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
    def append_method_frame(
        mut out: List[UInt8],
        channel: UInt16,
        class_id: UInt16,
        method_id: UInt16,
        var args: List[UInt8],
    ):
        """Append ONE method frame directly onto `out` (byte-identical to
        encode_method_frame). Removes the intermediate frame list allocation
        and copy on the reply hot path."""
        var args_len = len(args)
        var payload_size = 4 + args_len
        var old_len = len(out)
        out.resize(unsafe_uninit_length=old_len + 12 + args_len)
        out[old_len] = 1
        out[old_len + 1] = UInt8((channel >> 8) & 0xFF)
        out[old_len + 2] = UInt8(channel & 0xFF)
        out[old_len + 3] = UInt8((payload_size >> 24) & 0xFF)
        out[old_len + 4] = UInt8((payload_size >> 16) & 0xFF)
        out[old_len + 5] = UInt8((payload_size >> 8) & 0xFF)
        out[old_len + 6] = UInt8(payload_size & 0xFF)
        out[old_len + 7] = UInt8((class_id >> 8) & 0xFF)
        out[old_len + 8] = UInt8(class_id & 0xFF)
        out[old_len + 9] = UInt8((method_id >> 8) & 0xFF)
        out[old_len + 10] = UInt8(method_id & 0xFF)
        if args_len > 0:
            unsafe_memcpy(
                dest=out.unsafe_ptr() + old_len + 11,
                src=args.unsafe_ptr(),
                count=args_len,
            )
        out[old_len + 11 + args_len] = 0xCE

    @staticmethod
    def append_header_frame(
        mut out: List[UInt8],
        channel: UInt16,
        class_id: UInt16,
        body_size: UInt64,
        property_flags: UInt16,
        var properties: List[UInt8],
    ):
        """Append ONE content header frame directly onto `out` (byte-identical
        to encode_header_frame). See append_method_frame."""
        var props_len = len(properties)
        var payload_size = 14 + props_len
        var old_len = len(out)
        out.resize(unsafe_uninit_length=old_len + 22 + props_len)
        out[old_len] = 2
        out[old_len + 1] = UInt8((channel >> 8) & 0xFF)
        out[old_len + 2] = UInt8(channel & 0xFF)
        out[old_len + 3] = UInt8((payload_size >> 24) & 0xFF)
        out[old_len + 4] = UInt8((payload_size >> 16) & 0xFF)
        out[old_len + 5] = UInt8((payload_size >> 8) & 0xFF)
        out[old_len + 6] = UInt8(payload_size & 0xFF)
        out[old_len + 7] = UInt8((class_id >> 8) & 0xFF)
        out[old_len + 8] = UInt8(class_id & 0xFF)
        out[old_len + 9] = 0  # weight (reserved, MUST be 0)
        out[old_len + 10] = 0
        out[old_len + 11] = UInt8((body_size >> 56) & 0xFF)
        out[old_len + 12] = UInt8((body_size >> 48) & 0xFF)
        out[old_len + 13] = UInt8((body_size >> 40) & 0xFF)
        out[old_len + 14] = UInt8((body_size >> 32) & 0xFF)
        out[old_len + 15] = UInt8((body_size >> 24) & 0xFF)
        out[old_len + 16] = UInt8((body_size >> 16) & 0xFF)
        out[old_len + 17] = UInt8((body_size >> 8) & 0xFF)
        out[old_len + 18] = UInt8(body_size & 0xFF)
        out[old_len + 19] = UInt8((property_flags >> 8) & 0xFF)
        out[old_len + 20] = UInt8(property_flags & 0xFF)
        if props_len > 0:
            unsafe_memcpy(
                dest=out.unsafe_ptr() + old_len + 21,
                src=properties.unsafe_ptr(),
                count=props_len,
            )
        out[old_len + 21 + props_len] = 0xCE

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
    def append_body_frame_header(mut out: List[UInt8], chan: UInt16, count: Int):
        """Append the 7-octet BODY frame prefix (type+channel+size).

        Used by the delivery path that streams queue-owned payload bytes
        directly into the reply: the caller then appends `count` payload octets
        (from the queue) and finally the frame-end octet. The bytes written
        here plus those payload octets plus the end octet are EXACTLY what
        append_body_frame writes for the same chan/count.
        """
        var old_len = len(out)
        out.resize(unsafe_uninit_length=old_len + 7)
        out[old_len] = 3
        out[old_len + 1] = UInt8((chan >> 8) & 0xFF)
        out[old_len + 2] = UInt8(chan & 0xFF)
        out[old_len + 3] = UInt8((count >> 24) & 0xFF)
        out[old_len + 4] = UInt8((count >> 16) & 0xFF)
        out[old_len + 5] = UInt8((count >> 8) & 0xFF)
        out[old_len + 6] = UInt8(count & 0xFF)

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
