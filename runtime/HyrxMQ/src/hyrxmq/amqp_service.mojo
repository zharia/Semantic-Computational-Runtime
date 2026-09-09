# HyrxMQ AMQP service (Phase 7).
#
# Bridges AMQP frames to the broker. This module performs NO socket I/O: it
# takes an already-decoded AMQPFrame and returns already-encoded response
# bytes, so the whole protocol path is unit-testable feed-bytes/get-bytes.
#
# Layering: this file does WIRE work only — decode a method frame's arguments,
# hand semantic values to the broker, encode the reply. It contains no
# AMQP→Hyrx translation and no routing: the mapping from AMQP concepts onto Hyrx
# concepts lives in src/hyrx/amqp/adapter.mojo (the single translation surface),
# and the single routing authority is the broker's HyrxEngine core Router.
# Path: frame → AMQPService → HyrxMQBroker → AMQPAdapter → HyrxEngine (Router).
#
# The real network acceptance path is PROVEN: the flare-backed transport
# contract (src/hyrx/transport/tcp.mojo) drives this service through
# src/hyrxmq/listener.mojo; see tests/integration/broker_tcp_e2e.mojo.
#
# Vertical-slice simplification REMOVED: content frames are now real. A
# basic.publish is reassembled from its METHOD frame + exactly one HEADER frame
# + N BODY frames (amqp0-9-1.xml §2.3.5); outbound basic.deliver / basic.get-ok
# are emitted as METHOD + HEADER + BODY frames (see emit_message_frames).
# Pending messages are still flushed as basic.deliver frames appended to the
# basic.consume reply (pull-on-subscribe) instead of pushed asynchronously at
# publish time — async push-after-subscribe is NOT IMPLEMENTED.
#
# NOT IMPLEMENTED (wire-level gaps, honest list):
# - connection close: the close (10,50) / close-ok (10,51) and channel.close
#   (20,40) / close-ok (20,41) handshake, and secure (10,20) / secure-ok
#   (10,21). The header/start/start-ok/tune/tune-ok/open/open-ok negotiation is
#   now IMPLEMENTED (see connection_start_frame / _reply_tune / handle_frame and
#   src/hyrxmq/listener.mojo's pre-frame header stage); credentials are parsed
#   but NOT validated (no auth backend).
# - frame_max / heartbeat renegotiation and heartbeat timers (tune advertises
#   heartbeat=0; non-zero heartbeats are NOT IMPLEMENTED).
# - INBOUND content properties: the HEADER frame's body-size is read for
#   reassembly, but the property-list bytes are NOT decoded (field tables are
#   not serialized on the wire; see src/hyrx/amqp/field_table.mojo). OUTBOUND
#   properties are sent as property-flags=0 + empty property-list, so a real
#   client sees every property as None: delivery_mode/content_type/etc.
#   fidelity is NOT PROVEN.
# - the `arguments` field tables of queue/exchange declare and basic.consume
#   are skipped by length (read_table_skip), not interpreted.
# - basic.ack multiple=true (ack up to and including) is parsed but NOT
#   honoured: only the addressed tag is acknowledged.
# - basic.cancel is answered with cancel-ok, but the engine consumer is NOT
#   unregistered (the connection's consumer stays live until EOF).
# - connection state enforcement: methods are served even when no connection is
#   open (the AMQPConnectionState record is written by connection.open but never
#   gates dispatch).
# - get-ok message-count is always 0: the engine exposes no queue-depth read-back
#   (the field is wire-correct in length, not accurate in value).
# - basic.nack (60,120) and channel.flow (20,20) have no required reply or
#   handler yet; unhandled synchronous methods get no reply at all.

from std.collections import Dict, List, Optional
from std.memory import unsafe_memcpy

from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec, parse_header_frame_payload
from hyrx.amqp.field_table import FieldTable
from hyrx.amqp.constants import (
    FRAME_METHOD,
    FRAME_HEADER,
    FRAME_BODY,
    BASIC_CLASS_ID,
    CONNECTION_START,
    CONNECTION_START_OK,
    CONNECTION_TUNE,
    CONNECTION_TUNE_OK,
    CONNECTION_OPEN,
    CONNECTION_OPEN_OK,
    CHANNEL_OPEN,
    CHANNEL_OPEN_OK,
    EXCHANGE_DECLARE,
    EXCHANGE_DECLARE_OK,
    QUEUE_DECLARE,
    QUEUE_DECLARE_OK,
    QUEUE_BIND,
    QUEUE_BIND_OK,
    BASIC_QOS,
    BASIC_QOS_OK,
    BASIC_PUBLISH,
    BASIC_CANCEL,
    BASIC_CANCEL_OK,
    BASIC_CONSUME,
    BASIC_CONSUME_OK,
    BASIC_ACK,
    BASIC_REJECT,
    BASIC_GET,
    BASIC_GET_OK,
    BASIC_GET_EMPTY,
    BASIC_DELIVER,
    MethodID,
)
from hyrx.amqp.connection_state import (
    AMQPConnectionState,
    CONN_STATE_TUNE_SENT,
    CONN_STATE_TUNE_RECEIVED,
    CONN_STATE_OPEN,
)

from hyrx.core.queue import Delivery
from hyrxmq.broker import HyrxMQBroker
from hyrxmq.config import HyrxMQConfig
from hyrxmq.status import BrokerStatus


# Upper bound on deliveries flushed by one basic.consume reply.
def _CONSUME_FLUSH_MAX() -> Int:
    return 128


# Bounded accumulation for ONE in-flight publish. The codec already refuses any
# single frame over frame_max; this ceiling bounds the TOTAL reassembled body so
# a hostile client cannot dribble legal BODY frames toward unbounded memory
# (audit §13/§18). 8 MiB is far above any slice use and is a documented cap.
def MAX_PENDING_BODY() -> Int:
    return 8 * 1024 * 1024


# Smallest outbound body chunk (frame_max is validated >= 4096, so the real
# chunk is normally frame_max - 8; this floor keeps tiny configs legal).
def _MIN_BODY_CHUNK() -> Int:
    return 4096 - 8


# queue.declare bit-packed flags, packed low bit first in the order the spec
# lists them (amqp0-9-1.xml): passive=1, durable=2, exclusive=4,
# auto-delete=8, no-wait=16.
def QUEUE_DECLARE_BIT_NO_WAIT() -> UInt8:
    return 16


# basic.ack bit-packed flags: `multiple` is the single (low) bit.
def BASIC_ACK_BIT_MULTIPLE() -> UInt8:
    return 1


def _sasl_plain_authcid(var response: String) -> String:
    """Recover the authcid from a SASL PLAIN response.

    SASL PLAIN message = `authzid NUL authcid NUL passwd` (RFC 4616), so the
    authcid is the segment between the first and second NUL. Used for logging
    only — credentials are NOT validated (see handle_frame).
    """
    var b = response.as_bytes()
    var n = len(b)
    var i = 0
    while i < n and b[i] != 0:
        i += 1
    i += 1  # step over the first NUL (authzid terminator)
    var out = String()
    while i < n and b[i] != 0:
        out.append(Codepoint(b[i]))
        i += 1
    return out^


def write_u32(mut out: List[UInt8], value: UInt32):
    """Append a big-endian u32."""
    out.append(UInt8((value >> 24) & 0xFF))
    out.append(UInt8((value >> 16) & 0xFF))
    out.append(UInt8((value >> 8) & 0xFF))
    out.append(UInt8(value & 0xFF))


def write_u64(mut out: List[UInt8], value: UInt64):
    """Append a big-endian u64."""
    write_u32(out, UInt32(value >> 32))
    write_u32(out, UInt32(value & 0xFFFFFFFF))


def write_u16(mut out: List[UInt8], value: UInt16):
    """Append a big-endian u16 (AMQP `short`)."""
    out.append(UInt8((value >> 8) & 0xFF))
    out.append(UInt8(value & 0xFF))


def write_short_string(mut out: List[UInt8], var s: String):
    """Append an AMQP short-string (1-byte length + bytes) to `out`."""
    var b = s.as_bytes()
    out.append(UInt8(len(b)))
    var old_len = len(out)
    out.resize(unsafe_uninit_length=old_len + len(b))
    unsafe_memcpy(dest=out.unsafe_ptr() + old_len, src=b.unsafe_ptr(), count=len(b))


def write_long_string(mut out: List[UInt8], var s: String):
    """Append an AMQP long-string (4-byte big-endian length + bytes) to `out`."""
    var b = s.as_bytes()
    write_u32(out, UInt32(len(b)))
    var old_len = len(out)
    out.resize(unsafe_uninit_length=old_len + len(b))
    unsafe_memcpy(dest=out.unsafe_ptr() + old_len, src=b.unsafe_ptr(), count=len(b))


def write_long_str_empty(mut out: List[UInt8]):
    """Append an empty AMQP long-string (4-byte length = 0)."""
    write_u32(out, 0)


def write_table(mut out: List[UInt8], ref ft: FieldTable) raises:
    """Append an AMQP field table (4-byte length prefix + body) to `out`.

    Delegates to FieldTable.to_bytes(), which already emits the length prefix.
    An empty table is a bare write_u32(0) (see FieldTable.to_bytes).
    """
    var body = ft.to_bytes()
    for i in range(len(body)):
        out.append(body[i])


struct ByteReader:
    """Bounds-safe cursor over an AMQP method-arguments byte list."""

    var data: List[UInt8]
    var pos: Int

    def __init__(out self, var d: List[UInt8]):
        self.data = d^
        self.pos = 0

    def remaining(ref self) -> Int:
        return len(self.data) - self.pos

    def read_octet(mut self) -> UInt8:
        var v = UInt8(0)
        if self.pos < len(self.data):
            v = self.data[self.pos]
        self.pos += 1
        return v

    def read_short(mut self) -> UInt16:
        var hi = UInt16(0)
        var lo = UInt16(0)
        if self.pos < len(self.data):
            hi = UInt16(self.data[self.pos])
        self.pos += 1
        if self.pos < len(self.data):
            lo = UInt16(self.data[self.pos])
        self.pos += 1
        return (hi << 8) | lo

    def read_long(mut self) -> UInt32:
        var acc = UInt32(0)
        var i = 0
        while i < 4:
            acc = (acc << 8) | UInt32(self.read_octet())
            i += 1
        return acc

    def read_long_long(mut self) -> UInt64:
        var hi = UInt64(self.read_long())
        var lo = UInt64(self.read_long())
        return (hi << 32) | lo

    def read_short_string(mut self) -> String:
        var n = Int(self.read_octet())
        var s = String()
        var i = 0
        while i < n:
            if self.pos < len(self.data):
                s.append(Codepoint(self.data[self.pos]))
            self.pos += 1
            i += 1
        return s^

    def read_long_string(mut self) raises -> String:
        """Read an AMQP long-string (4-byte BE length + bytes). Raises if truncated."""
        var n = Int(self.read_long())
        if self.pos + n > len(self.data):
            raise (
                "ByteReader.read_long_string: declared "
                + String(n)
                + " bytes with only "
                + String(len(self.data) - self.pos)
                + " remaining"
            )
        var s = String()
        var i = 0
        while i < n:
            s.append(Codepoint(self.data[self.pos]))
            self.pos += 1
            i += 1
        return s^

    def read_table_skip(mut self) raises:
        """Skip a field table: read the 4-byte length and advance past its body.

        Raises if the declared body exceeds the remaining bytes (bounded parse —
        never trust an untrusted length).
        """
        var n = Int(self.read_long())
        if self.pos + n > len(self.data):
            raise (
                "ByteReader.read_table_skip: declared table of "
                + String(n)
                + " bytes exceeds "
                + String(len(self.data) - self.pos)
                + " remaining"
            )
        self.pos += n

    def read_remaining(mut self) -> List[UInt8]:
        var out = List[UInt8]()
        while self.pos < len(self.data):
            out.append(self.data[self.pos])
            self.pos += 1
        return out^


# basic.consume bit-packed flags, packed low-first in spec order:
# no-local=1, no-ack=2, exclusive=4, no-wait=8.
def BASIC_CONSUME_BIT_NO_ACK() -> UInt8:
    return 2


# basic.get bits: the single (low) no-ack bit.
def BASIC_GET_BIT_NO_ACK() -> UInt8:
    return 1


# Encode one complete content delivery: METHOD frame + one HEADER frame + zero
# or more BODY frames, all concatenated into a single byte list (the listener
# writes the returned list in one send). Wire rules (amqp0-9-1.xml §2.3.5):
#   - the HEADER frame carries class-id 60, weight 0 (inside encode_header_frame)
#     body-size = len(body), property-flags = 0 + EMPTY property-list: a real
#     client then reads every content property as None (property fidelity is
#     NOT PROVEN, see the module header).
#   - BODY frames carry at most `frame_max - 8` payload octets each (the 8 is
#     the frame overhead: type(1) channel(2) size(4) end(1)); a larger body is
#     split across several frames whose payload lengths sum to body-size.
#   - body-size == 0 -> NO body frames at all.
def emit_message_frames(
    chan: UInt16,
    mid: MethodID,
    var args: List[UInt8],
    var body: List[UInt8],
    frame_max: Int,
) -> List[UInt8]:
    var out = AMQPFrameCodec.encode_method_frame(
        chan, mid.class_id, mid.method_id, args^
    )
    var body_len = len(body)
    var hdr = AMQPFrameCodec.encode_header_frame(
        chan, mid.class_id, UInt64(body_len), UInt16(0), List[UInt8]()
    )
    var old_len = len(out)
    out.resize(unsafe_uninit_length=old_len + len(hdr))
    unsafe_memcpy(dest=out.unsafe_ptr() + old_len, src=hdr.unsafe_ptr(), count=len(hdr))
    if body_len == 0:
        return out^
    var chunk = frame_max - 8
    if chunk < _MIN_BODY_CHUNK():
        chunk = _MIN_BODY_CHUNK()
    var pos = 0
    while pos < body_len:
        var n = chunk
        if pos + n > body_len:
            n = body_len - pos
        var part = List[UInt8](capacity=n)
        part.resize(unsafe_uninit_length=n)
        unsafe_memcpy(dest=part.unsafe_ptr(), src=body.unsafe_ptr() + pos, count=n)
        var wf = AMQPFrameCodec.encode_body_frame(chan, part^)
        var out_len = len(out)
        out.resize(unsafe_uninit_length=out_len + len(wf))
        unsafe_memcpy(dest=out.unsafe_ptr() + out_len, src=wf.unsafe_ptr(), count=len(wf))
        pos += n
    return out^


struct PendingPublish:
    """In-flight inbound content for ONE connection (method -> header -> body).

    Copyable on purpose: every field is Copyable (String, Int), which lets the
    service read a value out of its Dict, mutate the copy and reinsert it —
    the pattern Mojo 1.0 accepts for dict-of-struct state here. The body bytes
    themselves are accumulated in the service's parallel `_pending_bodies`
    map (List[UInt8] is not Copyable, so it cannot live in this struct).
    """

    var exchange: String
    var routing_key: String
    var channel: UInt16
    # -1 = METHOD seen, HEADER not yet arrived; >= 0 = declared body size.
    var body_size: Int


    def __init__(out self, var ex: String, var rk: String, chan: UInt16):
        self.exchange = ex^
        self.routing_key = rk^
        self.channel = chan
        self.body_size = -1

    # Mojo 1.0: mutate the stored value through a chained call on the Dict
    # (`self._pending[conn].set_body_size(n)`) — an implicit struct copy out of
    # the Dict is rejected, so in-place mutator methods are the pattern.
    def set_body_size(mut self, size: Int):
        self.body_size = size


struct AMQPService:
    """Frame-level dispatch into the HyrxMQ broker (no sockets)."""

    var _broker: HyrxMQBroker
    var _conns: Dict[UInt64, AMQPConnectionState]
    var _consumers: Dict[UInt64, UInt64]
    var _frame_max: Int
    # Per-connection inbound content reassembly (single in-flight publish per
    # connection, matching the one-frame-in/one-reply-out dispatch contract).
    var _pending: Dict[UInt64, PendingPublish]
    var _pending_bodies: Dict[UInt64, List[UInt8]]
    # Per-connection basic.get bookkeeping: the engine consumer registered for
    # gets (and the queue it was registered on) plus the last get delivery tag,
    # so a subsequent basic.ack can address it.
    var _get_cids: Dict[UInt64, UInt64]
    var _get_queues: Dict[UInt64, String]
    var _get_tags: Dict[UInt64, UInt64]
    # Last consumer-tag per registered consumer id (echoed in consume-ok and
    # carried in every deliver frame; AMQP routes deliveries by this string).
    var _ctags: Dict[UInt64, String]
    # Count of dropped protocol-error content frames (fail-closed visibility
    # for tests/status without an async logging path).
    var _content_errors: Int

    def __init__(out self, var config: HyrxMQConfig):
        # Read frame_max BEFORE `config` is consumed by HyrxMQBroker(config^).
        var fm = config.frame_max
        self._broker = HyrxMQBroker(config^)
        self._conns = Dict[UInt64, AMQPConnectionState]()
        self._consumers = Dict[UInt64, UInt64]()
        self._pending = Dict[UInt64, PendingPublish]()
        self._pending_bodies = Dict[UInt64, List[UInt8]]()
        self._get_cids = Dict[UInt64, UInt64]()
        self._get_queues = Dict[UInt64, String]()
        self._get_tags = Dict[UInt64, UInt64]()
        self._ctags = Dict[UInt64, String]()
        self._content_errors = 0
        # Value advertised in connection.tune and enforced as the per-connection
        # codec ceiling by the listener. config.frame_max is validated >= 4096
        # (see HyrxMQConfig.frame_max / validate).
        self._frame_max = fm

    # ---- lifecycle / broker delegation ----

    def start(mut self) raises:
        self._broker.start()

    def shutdown(mut self):
        self._broker.shutdown()

    def health(mut self) -> String:
        return self._broker.health()

    def status(mut self) -> BrokerStatus:
        return self._broker.status()

    def node_name(mut self) -> String:
        return self._broker.node_name()

    def consume_register(mut self, var queue: String) raises -> UInt64:
        return self._broker.consume_register(queue^)

    def deliver(mut self, consumer_id: UInt64) raises -> Optional[Delivery]:
        return self._broker.deliver(consumer_id)

    def read_payload(
        mut self, consumer_id: UInt64, delivery_tag: UInt64
    ) raises -> List[UInt8]:
        return self._broker.read_payload(consumer_id, delivery_tag)

    def ack(mut self, consumer_id: UInt64, delivery_tag: UInt64) raises -> Bool:
        return self._broker.ack(consumer_id, delivery_tag)

    def connection_is_open(mut self, conn_id: UInt64) raises -> Bool:
        if conn_id not in self._conns:
            return False
        return self._conns[conn_id].is_open()

    # ---- content-reassembly observability (for tests / fail-closed audits) ----

    def content_errors(ref self) -> Int:
        """Dropped §2.3.5-violating content frames since service start."""
        return self._content_errors

    def pending_body_len(mut self, conn_id: UInt64) raises -> Int:
        """Bytes accumulated for the in-flight publish (0 when none)."""
        if conn_id not in self._pending_bodies:
            return 0
        return len(self._pending_bodies[conn_id])

    def frame_max(ref self) -> Int:
        """The outbound body chunk basis (frame_max - 8 per BODY frame)."""
        return self._frame_max

    # ---- connection negotiation (server→client frames the listener sends) ----

    def connection_start_frame(ref self) -> List[UInt8]:
        """Encode the connection.start (10,10) server frame (channel 0).

        Wire arguments, big-endian, exactly per amqp0-9-1.xml:
          version-major(octet)=0, version-minor(octet)=9,
          server-properties(table)=empty (U32 0),
          mechanisms(longstr)="PLAIN", locales(longstr)="en_US".

        The listener sends this as the first server frame after echoing the
        8-octet protocol header. A later revision may enrich server-properties
        with product/version/platform; the empty table is spec-legal and is what
        a synchronous client is unblocked by.
        """
        var args = List[UInt8]()
        args.append(UInt8(0))  # version-major
        args.append(UInt8(9))  # version-minor
        write_u32(args, 0)  # server-properties: empty field table
        write_long_string(args, "PLAIN")  # mechanisms (longstr)
        write_long_string(args, "en_US")  # locales (longstr)
        return AMQPFrameCodec.encode_method_frame(
            UInt16(0),
            CONNECTION_START().class_id,
            CONNECTION_START().method_id,
            args^,
        )

    def _reply_tune(ref self, chan: UInt16) -> Optional[List[UInt8]]:
        """connection.tune (10,30): channel-max(2047), frame-max, heartbeat(0).

        heartbeat=0 is REQUIRED for the synchronous path: this broker has no
        heartbeat timer, so any non-zero value would make a real client (pika)
        wait for heartbeats that never arrive. Non-zero heartbeats are NOT
        IMPLEMENTED.
        """
        var args = List[UInt8]()
        write_u16(args, 2047)  # channel-max (short)
        write_u32(args, UInt32(self._frame_max))  # frame-max (long)
        write_u16(args, 0)  # heartbeat (short) = none, see note above
        return self._reply(
            chan,
            CONNECTION_TUNE().class_id,
            CONNECTION_TUNE().method_id,
            args^,
        )

    # ---- frame handling ----

    def handle_frame(
        mut self, conn_id: UInt64, frame: AMQPFrame
    ) raises -> Optional[List[UInt8]]:
        """Decode one frame, dispatch to the broker, encode a reply.

        Frame-type aware (amqp0-9-1.xml §2.3.5): METHOD frames are dispatched by
        class/method id; a content HEADER or BODY frame feeds the per-connection
        publish reassembly state (`_pending` / `_pending_bodies`) and produces
        NO reply. A METHOD whose definition carries content (basic.publish) only
        records the pending envelope — the message reaches the broker when the
        declared body-size has been fully collected.

        The frame is taken read-only (plain arg): this handler only reads the
        payload, so the network path can pass `optional.value()` without a
        copy or move.

        Returns response bytes for methods with a synchronous *_ok reply;
        returns None for fire-and-forget methods (publish/ack) and content
        frames.
        """
        if frame.frame_type == FRAME_HEADER():
            self._on_content_header(conn_id, frame)
            return Optional[List[UInt8]]()
        if frame.frame_type == FRAME_BODY():
            self._on_content_body(conn_id, frame)
            return Optional[List[UInt8]]()
        if frame.frame_type != FRAME_METHOD():
            return Optional[List[UInt8]]()

        # Method payload layout: class_id(2) + method_id(2) + args(N).
        # Parse directly over an owned copy to avoid a partial move that would
        # leave the owning frame value undestroyable.
        var reader = ByteReader(frame.payload_copy())
        var chan = frame.channel
        var class_id = reader.read_short()
        var method_id = reader.read_short()
        var mid = MethodID(class_id, method_id)

        # ---- connection negotiation ----
        if mid == CONNECTION_START_OK():
            # connection.start-ok (10,11) client→server args:
            #   client-properties(table) + mechanism(shortstr)
            #   + response(longstr, SASL PLAIN) + locale(shortstr).
            reader.read_table_skip()
            var mechanism = reader.read_short_string()
            var response = reader.read_long_string()
            var locale = reader.read_short_string()
            # NOT IMPLEMENTED: credentials are parsed but NOT validated
            # (no auth backend). SASL PLAIN response is `\0 authcid \0 passwd`;
            # we recover the authcid for logging only.
            var authcid = _sasl_plain_authcid(response^)
            print(
                "hyrxmq: connection.start-ok mechanism="
                + mechanism
                + " authcid="
                + authcid
                + " locale="
                + locale
            )
            if conn_id not in self._conns:
                self._conns[conn_id] = AMQPConnectionState()
            self._conns[conn_id].set_state(CONN_STATE_TUNE_SENT())
            return self._reply_tune(chan)

        if mid == CONNECTION_TUNE_OK():
            # connection.tune-ok (10,31): record, do not re-enforce. No reply.
            if conn_id not in self._conns:
                self._conns[conn_id] = AMQPConnectionState()
            self._conns[conn_id].set_state(CONN_STATE_TUNE_RECEIVED())
            return Optional[List[UInt8]]()

        if mid == CONNECTION_OPEN():
            # connection.open (10,40): virtual-host(shortstr) + reserved-1
            # (shortstr) + reserved-2 (bit). Record, reply open-ok, mark OPEN.
            if conn_id not in self._conns:
                self._conns[conn_id] = AMQPConnectionState()
            self._conns[conn_id].set_state(CONN_STATE_OPEN())
            return self._reply_open(chan)

        # ---- channel ----
        if mid == CHANNEL_OPEN():
            var okargs = List[UInt8]()
            write_long_str_empty(okargs)
            return self._reply(
                chan,
                CHANNEL_OPEN_OK().class_id,
                CHANNEL_OPEN_OK().method_id,
                okargs^,
            )

        # ---- exchange ----
        if mid == EXCHANGE_DECLARE():
            _ = reader.read_short()  # reserved-1 (deprecated "ticket", must be 0)
            var ex_name = reader.read_short_string()
            var ex_type = reader.read_short_string()
            _ = reader.read_octet()  # bits: passive/durable/auto-delete/no-wait
            # NOT IMPLEMENTED: those bits (always declares synchronously, so
            # exchange.declare's no-wait is NOT honoured) and `arguments`.
            _ = self._broker.declare_exchange(ex_name^, ex_type^)
            return self._reply(
                chan,
                EXCHANGE_DECLARE_OK().class_id,
                EXCHANGE_DECLARE_OK().method_id,
                List[UInt8](),
            )

        # ---- queue declare ----
        if mid == QUEUE_DECLARE():
            _ = reader.read_short()  # reserved-1 (deprecated "ticket", must be 0)
            var q_name = reader.read_short_string()
            var q_bits = reader.read_octet()
            # NOT IMPLEMENTED: passive/durable/exclusive/auto-delete bits and
            # the trailing `arguments` field table (field tables are not
            # serialized on the wire).
            _ = self._broker.declare_queue(q_name.copy())
            if (q_bits & QUEUE_DECLARE_BIT_NO_WAIT()) != 0:
                # no-wait set → "the server will not respond to the method"
                return Optional[List[UInt8]]()
            return self._reply_queue_declare_ok(chan, q_name^)

        # ---- queue bind ----
        if mid == QUEUE_BIND():
            _ = reader.read_short()  # reserved-1
            var bq = reader.read_short_string()
            var be = reader.read_short_string()
            var brk = reader.read_short_string()
            _ = self._broker.bind_queue(bq^, be^, brk^)
            return self._reply(
                chan,
                QUEUE_BIND_OK().class_id,
                QUEUE_BIND_OK().method_id,
                List[UInt8](),
            )

        # ---- basic publish: envelope only; the body arrives as content frames
        if mid == BASIC_PUBLISH():
            # Spec args: reserved-1 short + exchange shortstr + routing-key
            # shortstr + bits[mandatory=1, immediate=2] in ONE octet. The
            # message is NOT published here: the METHOD frame is followed on
            # the same channel by exactly one HEADER frame and N BODY frames
            # (§2.3.5); reassembly completes in _on_content_body, which is the
            # only path that reaches broker.publish for this method.
            _ = reader.read_short()  # reserved-1
            var pex = reader.read_short_string()
            var prk = reader.read_short_string()
            _ = reader.read_octet()  # bits: mandatory / immediate (NOT honoured)
            # A new METHOD frame re-arms the per-connection state: any previous
            # half-reassembled publish is dropped (bounded, never published).
            self._clear_pending(conn_id)
            self._pending[conn_id] = PendingPublish(pex^, prk^, chan)
            self._pending_bodies[conn_id] = List[UInt8]()
            return Optional[List[UInt8]]()

        # ---- basic qos (60,10) — MUST be answered or real clients deadlock ----
        if mid == BASIC_QOS():
            # prefetch-size(long) + prefetch-count(short) + global bit. NOT
            # IMPLEMENTED: the flags/values are parsed and ignored (the engine
            # applies no prefetch window on this path).
            _ = reader.read_long()
            _ = reader.read_short()
            _ = reader.read_octet()
            return self._reply(
                chan,
                BASIC_QOS_OK().class_id,
                BASIC_QOS_OK().method_id,
                List[UInt8](),
            )

        # ---- basic cancel (60,30): answer cancel-ok (consumer NOT unregistered)
        if mid == BASIC_CANCEL():
            var xtag = reader.read_short_string()
            _ = reader.read_octet()  # bits: no-wait (always answered here)
            var xargs = List[UInt8]()
            write_short_string(xargs, xtag^)
            return self._reply(
                chan,
                BASIC_CANCEL_OK().class_id,
                BASIC_CANCEL_OK().method_id,
                xargs^,
            )

        # ---- basic consume ----
        if mid == BASIC_CONSUME():
            # Spec args: reserved-1 short + queue shortstr + consumer-tag
            # shortstr + bits[no-local=1,no-ack=2,exclusive=4,no-wait=8] +
            # arguments table.
            _ = reader.read_short()  # reserved-1
            var cq = reader.read_short_string()
            var ctag = reader.read_short_string()
            var cbits = reader.read_octet()
            reader.read_table_skip()  # arguments (NOT IMPLEMENTED: skipped)
            var cid = self._broker.consume_register(cq^)
            # Slice limitation: one consumer per connection (last consume wins).
            self._consumers[conn_id] = cid
            # The client's consumer-tag is echoed (a real client routes inbound
            # deliveries by this string); an empty tag gets a server-generated
            # one, as the spec requires.
            var tag_out = ctag
            if len(tag_out.bytes()) == 0:
                tag_out = "hyrxmq-ctag-" + String(cid)
            self._ctags[cid] = tag_out.copy()
            var cargs = List[UInt8]()
            write_short_string(cargs, tag_out^)
            var reply = AMQPFrameCodec.encode_method_frame(
                chan,
                BASIC_CONSUME_OK().class_id,
                BASIC_CONSUME_OK().method_id,
                cargs^,
            )
            var no_ack = (cbits & BASIC_CONSUME_BIT_NO_ACK()) != 0
            reply = self._flush_deliveries(chan, cid, reply^, no_ack)
            return Optional[List[UInt8]](reply^)

        # ---- basic get (60,70): synchronous — answer get-ok or get-empty ----
        if mid == BASIC_GET():
            # Spec args: reserved-1 short + queue shortstr + no-ack bit.
            _ = reader.read_short()
            var gq = reader.read_short_string()
            var gbits = reader.read_octet()
            return self._handle_get(conn_id, chan, gq^, gbits)

        # ---- basic reject (60,90): delivery-tag long-long + requeue bit ----
        if mid == BASIC_REJECT():
            var rtag = reader.read_long_long()
            _ = reader.read_octet()  # requeue (the engine always requeues)
            if conn_id in self._consumers:
                _ = self._broker.reject(self._consumers[conn_id], rtag)
            return Optional[List[UInt8]]()

        # ---- basic ack ----
        if mid == BASIC_ACK():
            # Spec arguments: delivery-tag(long-long) + multiple(bit).
            var tag = reader.read_long_long()
            var ack_bits = reader.read_octet()
            var multiple = (ack_bits & BASIC_ACK_BIT_MULTIPLE()) != 0
            # NOT IMPLEMENTED: multiple=true means "ack up to and including this
            # tag" (and, with tag 0, "all outstanding"). The engine acknowledges
            # one tag at a time, so only the addressed delivery_tag below is
            # honoured and the batch request is NOT. This octet used to be
            # mis-read as a consumer id, which acked nothing.
            _ = multiple
            # The consumer is the one this connection registered via
            # basic.consume; its id is issued by the engine (single authority).
            # A tag produced by basic.get is addressed to the get-registered
            # consumer instead (the engine resolves a tag through the consumer's
            # queue, so the right consumer id matters).
            var done = False
            if conn_id in self._consumers:
                done = self._broker.ack(self._consumers[conn_id], tag)
            if (
                not done
                and conn_id in self._get_tags
                and conn_id in self._get_cids
                and self._get_tags[conn_id] == tag
            ):
                done = self._broker.ack(self._get_cids[conn_id], tag)
            return Optional[List[UInt8]]()

        # ---- unhandled method: no reply ----
        # NOT IMPLEMENTED: a required *_ok is not sent for the remaining
        # unhandled synchronous methods (channel.flow, queue.purge, tx.*, ...);
        # peers will block waiting for those replies.
        return Optional[List[UInt8]]()

    # ---- inbound content reassembly (amqp0-9-1.xml §2.3.5) ----

    def _clear_pending(mut self, conn_id: UInt64) raises:
        """Drop the in-flight publish state for a connection (fail closed)."""
        if conn_id in self._pending:
            _ = self._pending.pop(conn_id)
        if conn_id in self._pending_bodies:
            _ = self._pending_bodies.pop(conn_id)

    def _fail_content(mut self, conn_id: UInt64, var why: String) raises:
        """A content frame violated §2.3.5 ordering/bounds.

        Fail-closed policy (audit §13/§18): the pending publish is discarded
        (never published, never grown) and the frame is dropped — the connection
        keeps serving. `why` only reaches the counter's debug print, never a
        client-visible reply (no connection.close is implemented).
        """
        self._content_errors += 1
        self._clear_pending(conn_id)
        print("hyrxmq: content frame dropped (conn " + String(conn_id) + "): " + why)

    def _on_content_header(mut self, conn_id: UInt64, frame: AMQPFrame) raises:
        """A content HEADER frame: it must follow a basic.publish METHOD frame.

        Only the class-id (must be basic=60) and body-size (§2.3.5.2 offsets
        0:2 / 4:12) are read; the property-list is deliberately NOT decoded
        (property fidelity is NOT PROVEN — see module header).
        """
        if conn_id not in self._pending:
            self._fail_content(conn_id, "header frame with no pending publish")
            return
        var hdr = parse_header_frame_payload(frame.payload_copy())
        if hdr.class_id != BASIC_CLASS_ID():
            self._fail_content(
                conn_id,
                "content header class-id "
                + String(hdr.class_id)
                + " is not basic (60)",
            )
            return
        if self._pending[conn_id].body_size >= 0:
            self._fail_content(conn_id, "second content header for one publish")
            return
        var size = Int(hdr.body_size)
        if size > MAX_PENDING_BODY():
            self._fail_content(
                conn_id,
                "declared body size " + String(size) + " exceeds the "
                + String(MAX_PENDING_BODY()) + "-byte reassembly ceiling",
            )
            return
        self._pending[conn_id].set_body_size(size)
        if size == 0:
            # Zero-length body: exactly ZERO body frames follow (§2.3.5.3).
            self._publish_pending(conn_id)

    def _on_content_body(mut self, conn_id: UInt64, frame: AMQPFrame) raises:
        """A content BODY frame: append, complete, or fail closed.

        Bounds (audit §13/§18): a body frame with no pending publish is dropped
        without allocating; an arrival that would push the accumulated length
        PAST the declared body-size is a protocol error — the whole message is
        dropped, never published, and no further bytes are retained.
        """
        if conn_id not in self._pending or conn_id not in self._pending_bodies:
            self._fail_content(conn_id, "body frame with no pending publish")
            return
        var want = self._pending[conn_id].body_size
        if want <= 0:
            # Either no header yet (body before header, -1) or a zero-size body
            # that already completed: in both cases this frame is out of order.
            self._fail_content(conn_id, "body frame before/after its header")
            return
        var have = len(self._pending_bodies[conn_id])
        if have + frame.payload_size() > want:
            self._fail_content(
                conn_id,
                "body overflow: "
                + String(have + frame.payload_size())
                + " bytes against a declared "
                + String(want),
            )
            return
        var pb = self._pending_bodies.pop(conn_id)
        var pb_old_len = len(pb)
        pb.resize(unsafe_uninit_length=pb_old_len + frame.payload_size())
        unsafe_memcpy(
            dest=pb.unsafe_ptr() + pb_old_len,
            src=frame.payload.unsafe_ptr(),
            count=frame.payload_size(),
        )
        self._pending_bodies[conn_id] = pb^
        if len(self._pending_bodies[conn_id]) == want:
            self._publish_pending(conn_id)

    def _publish_pending(mut self, conn_id: UInt64) raises:
        """Hand the fully reassembled body to the broker (the single publish
        point for inbound content) and clear the per-connection state."""
        if conn_id not in self._pending or conn_id not in self._pending_bodies:
            return
        var p = self._pending.pop(conn_id)
        var body = self._pending_bodies.pop(conn_id)
        _ = self._broker.publish(p.exchange.copy(), p.routing_key.copy(), body^)

    # ---- synchronous basic.get ----

    def _handle_get(
        mut self,
        conn_id: UInt64,
        chan: UInt16,
        var queue: String,
        bits: UInt8,
    ) raises -> Optional[List[UInt8]]:
        """Pop ONE message from `queue` and answer get-ok(+content) or get-empty.

        The engine delivers through a consumer, so the connection keeps a
        dedicated get-consumer per queue (registered on first use and reused);
        its id and the emitted delivery tag are remembered so the follow-up
        basic.ack addresses the same consumer. no-ack=1 acknowledges
        immediately.
        """
        var cid = self._get_cids[conn_id] if conn_id in self._get_cids else UInt64(0)
        if conn_id not in self._get_cids or self._get_queues[conn_id] != queue:
            cid = self._broker.consume_register(queue.copy())
            self._get_cids[conn_id] = cid
            self._get_queues[conn_id] = queue.copy()
        var d = self._broker.deliver(cid)
        if not d.__bool__():
            var eargs = List[UInt8]()
            write_short_string(eargs, "")  # reserved-1 short-string (empty)
            return self._reply(
                chan,
                BASIC_GET_EMPTY().class_id,
                BASIC_GET_EMPTY().method_id,
                eargs^,
            )
        var tag = d.value().delivery_tag()
        var payload = self._broker.read_payload(cid, tag)
        var routing_key = self._broker.queue_routing_key(cid, tag)
        var message_count = self._broker.queue_message_count(cid)
        # get-ok args: delivery-tag long-long + redelivered bit(0) + exchange
        # shortstr + routing-key shortstr + message-count long.
        var gargs = List[UInt8]()
        write_u64(gargs, tag)
        gargs.append(0)  # redelivered bit
        write_short_string(gargs, "")  # exchange (Delivery carries none)
        write_short_string(gargs, routing_key^)
        write_u32(gargs, UInt32(message_count))
        self._get_tags[conn_id] = tag
        if (bits & BASIC_GET_BIT_NO_ACK()) != 0:
            _ = self._broker.ack(cid, tag)
        return Optional[List[UInt8]](
            emit_message_frames(
                chan, BASIC_GET_OK(), gargs^, payload^, self._frame_max
            )^
        )

    # ---- reply encoders ----

    def _flush_deliveries(
        mut self, chan: UInt16, cid: UInt64, var dst: List[UInt8], auto_ack: Bool
    ) raises -> List[UInt8]:
        """Append full basic.deliver content for messages queued for cid.

        Each message becomes METHOD + HEADER + BODY frames via
        emit_message_frames (the real §2.3.5 layout, replacing the former
        inline-body hack). Bounded by _CONSUME_FLUSH_MAX per reply; `dst`
        round-trips (ownership: consumed in, returned).
        """
        var ctag = String(cid)
        if cid in self._ctags:
            ctag = self._ctags[cid]
        var n = 0
        while n < _CONSUME_FLUSH_MAX():
            var d = self._broker.deliver(cid)
            if not d.__bool__():
                return dst^
            var tag = d.value().delivery_tag()
            var payload = self._broker.read_payload(cid, tag)
            var routing_key = self._broker.queue_routing_key(cid, tag)
            # deliver args: consumer-tag shortstr + delivery-tag long-long +
            # redelivered bit + exchange shortstr + routing-key shortstr.
            var args = List[UInt8]()
            write_short_string(args, ctag.copy())
            write_u64(args, tag)
            args.append(0)  # redelivered bit
            write_short_string(args, "")  # exchange (Delivery carries none)
            write_short_string(args, routing_key^)
            var wire = emit_message_frames(
                chan, BASIC_DELIVER(), args^, payload^, self._frame_max
            )
            var dst_old_len = len(dst)
            dst.resize(unsafe_uninit_length=dst_old_len + len(wire))
            unsafe_memcpy(
                dest=dst.unsafe_ptr() + dst_old_len,
                src=wire.unsafe_ptr(),
                count=len(wire),
            )
            if auto_ack:
                _ = self._broker.ack(cid, tag)
            n += 1
        return dst^

    def _reply(
        ref self,
        chan: UInt16,
        class_id: UInt16,
        method_id: UInt16,
        var args: List[UInt8],
    ) -> Optional[List[UInt8]]:
        var bytes = AMQPFrameCodec.encode_method_frame(
            chan, class_id, method_id, args^
        )
        return Optional[List[UInt8]](bytes^)

    def _reply_open(ref self, chan: UInt16) -> Optional[List[UInt8]]:
        # open-ok (10,41): a SINGLE reserved-1 short-string (empty). The old code
        # also wrote an empty long-string, which is NOT in amqp0-9-1.xml and
        # desynchronizes a real client's frame parser — removed (audit §36).
        var args = List[UInt8]()
        write_short_string(args, "")
        return self._reply(
            chan,
            CONNECTION_OPEN_OK().class_id,
            CONNECTION_OPEN_OK().method_id,
            args^,
        )

    def _reply_queue_declare_ok(
        ref self, chan: UInt16, var q_name: String
    ) -> Optional[List[UInt8]]:
        # declare-ok: queue short-string + message-count long + consumer-count long.
        var args = List[UInt8]()
        write_short_string(args, q_name^)
        write_u32(args, 0)
        write_u32(args, 0)
        return self._reply(
            chan,
            QUEUE_DECLARE_OK().class_id,
            QUEUE_DECLARE_OK().method_id,
            args^,
        )
