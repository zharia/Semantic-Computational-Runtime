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
# NOT IMPLEMENTED (wire-level gaps, honest list — 0017 T1 update):
# - connection close / channel close handshake: NOW IMPLEMENTED. connection.close
#   (10,50) is replied with close-ok (10,51) from ANY state and tolerated
#   everywhere (the listener then closes the socket AFTER the reply); channel.close
#   (20,40) is replied with close-ok (20,41) on the SAME channel number and the
#   number becomes CLOSED: any later business method on it gets the normative
#   server-side channel.close error reply (404 NOT_FOUND / 406
#   PRECONDITION_FAILED + failing class/method ids), content frames are
#   tolerated silently, channel.open re-opens the number. secure (10,20/21)
#   remains NOT implemented; credentials are parsed but NOT validated.
# - frame_max / heartbeat renegotiation and heartbeat timers (tune advertises
#   heartbeat=0; non-zero heartbeats are NOT IMPLEMENTED).
# - INBOUND content properties (0017 T2): NOW IMPLEMENTED byte-faithfully —
#   the publisher's property-flag word + RAW property-list bytes are stored
#   (PendingPublish.prop_flags + _pending_prop_bytes) and re-emitted verbatim
#   on basic.deliver / basic.get-ok / basic.return (no re-serialization; the
#   flag word is transmitted as part of the same decode plane). Per-property
#   VALUES are decoded only at the client (pika) — the service derives,
#   never stores, them.
# - delivery-tags are now PER-CHANNEL (0017 T2): get-consumer and
#   push-consumer deliveries share one namespace per (connection, channel);
#   ack/nack resolve through the service map, ON TOP of unchanged engine tags.
#   Legacy engine-tag fallback kept for compatibility.
# - unknown-exchange publish → channel.close 404 NOT_FOUND (normative); 312
#   NO_ROUTE basic.return stays for a REAL exchange whose ROUTE misses with
#   mandatory=1. The default exchange "" is treated as present (normative) :
#   it routes to zero queues in this engine slice (needs-probe: direct
#   queue-name routing onto the default exchange).
# - the declare `arguments` field tables are read by length (read_table_skip),
#   not interpreted (T3); x-dead-letter-exchange requeue-false routing lands in
#   T3 (requeue=false currently DROPS, which is the normative T1 behavior).
# - basic.cancel is answered with cancel-ok, but the engine consumer is NOT
#   unregistered (the connection's consumer stays live until EOF/close).
# - connection state enforcement: business methods are not gated on the
#   connection=open state (AMQPConnectionState is written but never gates
#   dispatch; only the listener's handshake phases gate frames).
# - get-ok message-count is always 0: the engine exposes no queue-depth read-back
#   (the field is wire-correct in length, not accurate in value).
# - channel.flow (20,20) has no handler; publish `immediate=1` is parsed and
#   ignored (unroutable-immediate has no return in this broker).

from std.collections import Dict, List, Optional
from std.memory import unsafe_memcpy

from hyrx.amqp.frame_codec import (
    AMQPFrame,
    AMQPFrameCodec,
    parse_header_frame_payload,
)
from hyrx.amqp.field_table import FieldTable
from hyrx.core.feature_flags import contiguous_batch_enabled
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
    CONNECTION_CLOSE,
    CONNECTION_CLOSE_OK,
    CHANNEL_OPEN,
    CHANNEL_OPEN_OK,
    CHANNEL_CLOSE,
    CHANNEL_CLOSE_OK,
    EXCHANGE_DECLARE,
    EXCHANGE_DECLARE_OK,
    EXCHANGE_DELETE,
    EXCHANGE_DELETE_OK,
    EXCHANGE_BIND,
    EXCHANGE_BIND_OK,
    EXCHANGE_UNBIND,
    EXCHANGE_UNBIND_OK,
    QUEUE_DECLARE,
    QUEUE_DECLARE_OK,
    QUEUE_BIND,
    QUEUE_BIND_OK,
    QUEUE_PURGE,
    QUEUE_PURGE_OK,
    QUEUE_DELETE,
    QUEUE_DELETE_OK,
    QUEUE_UNBIND,
    QUEUE_UNBIND_OK,
    BASIC_QOS,
    BASIC_QOS_OK,
    BASIC_PUBLISH,
    BASIC_RETURN,
    BASIC_CANCEL,
    BASIC_CANCEL_OK,
    BASIC_CONSUME,
    BASIC_CONSUME_OK,
    BASIC_NACK,
    BASIC_ACK,
    BASIC_REJECT,
    BASIC_GET,
    BASIC_GET_OK,
    BASIC_GET_EMPTY,
    BASIC_DELIVER,
    REPLY_NOT_FOUND,
    REPLY_PRECONDITION_FAILED,
    REPLY_NO_ROUTE,
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


# basic.nack (60,120) bit-packed flags, low-first in spec order:
# multiple=1, requeue=2.
def BASIC_NACK_BIT_MULTIPLE() -> UInt8:
    return 1


def BASIC_NACK_BIT_REQUEUE() -> UInt8:
    return 2


# basic.publish bits (one octet), low-first in spec order:
# mandatory=1, immediate=2.
def BASIC_PUBLISH_BIT_MANDATORY() -> UInt8:
    return 1


# queue.delete bit-packed flags (one octet), low-first in spec order:
# if-empty=1, if-unused=2, no-wait=4.
def QUEUE_DELETE_BIT_EMPTY() -> UInt8:
    return 1


def QUEUE_DELETE_BIT_UNUSED() -> UInt8:
    return 2


def QUEUE_DELETE_BIT_NO_WAIT() -> UInt8:
    return 4


# queue.purge bit-packed flags: single no-wait bit.
def QUEUE_PURGE_BIT_NO_WAIT() -> UInt8:
    return 1


# exchange.delete bit-packed flags (one octet), low-first in spec order:
# if-unused=1, no-wait=2.
def EXCHANGE_DELETE_BIT_UNUSED() -> UInt8:
    return 1


def EXCHANGE_DELETE_BIT_NO_WAIT() -> UInt8:
    return 2


# exchange.bind / exchange.unbind bit-packed flags: single no-wait bit.
def EXCHANGE_BIND_BIT_NO_WAIT() -> UInt8:
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
#     body-size = len(body); the property-flags word + property-list bytes are
#     the message's OWN stored content header (0017 T2): the publisher's
#     property slice is re-emitted byte-identically (flag word + slice are
#     stored as received and handed back verbatim). Zero flags + empty list is
#     the exact `flags=0` empty header (a publish through the engine with no
#     properties).
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
    prop_flags: UInt16,
    var prop_list: List[UInt8],
) raises -> List[UInt8]:
    var out = AMQPFrameCodec.encode_method_frame(
        chan, mid.class_id, mid.method_id, args^
    )
    var body_len = len(body)
    var hdr = AMQPFrameCodec.encode_header_frame(
        chan, mid.class_id, UInt64(body_len), prop_flags, prop_list^
    )
    var old_len = len(out)
    out.resize(unsafe_uninit_length=old_len + len(hdr))
    unsafe_memcpy(dest=out.unsafe_ptr() + old_len, src=hdr.unsafe_ptr(), count=len(hdr))
    if body_len == 0:
        return out^
    var chunk = frame_max - 8
    if chunk < _MIN_BODY_CHUNK():
        chunk = _MIN_BODY_CHUNK()
    if contiguous_batch_enabled():
        # Contiguous path: no intermediate `part`/`wf` lists — body chunks are
        # read DIRECTLY from the `body` list via unsafe_ptr (count-based
        # pointer reads); `body` is not moved and stays valid through all
        # appends. Per chunk, append_body_frame applies its single resize and
        # memcpy onto `out`.
        var pos = 0
        while pos < body_len:
            var n = chunk
            if pos + n > body_len:
                n = body_len - pos
            AMQPFrameCodec.append_body_frame(out, chan, body.unsafe_ptr() + pos, n)
            pos += n
        return out^
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


# Per-channel delivery-tag namespace (0017 T2).
#
# ONE tag counter + outstanding-tag map per (connection, channel) NAMESPACE —
# STANDARD amqp scope. get-consumer AND push-consumer deliveries live there
# together; the service maps its own delivery-tags ON TOP of the engine's tags:
# the engine keeps its own per-queue ascending tags (single authority — NEVER
# altered here); the wire tag the client sees is THIS map's tag. basic.ack /
# basic.nack tags resolve THROUGH this map (service tag -> consumer id +
# ENGINE tag), so forged/foreign engine tags do not resolve to a channel that
# never saw them.
#
# The counter starts at 1 (Rabbit numbering) and is monotonic for the whole
# life of the channel: it is NOT rewound when the last outstanding tag is
# resolved, so every delivery event gets a fresh tag (a redelivery must not
# reuse the tag the client already saw).
#
# channel_ids = conn_id * 65536 + channel; collision-safe for any single
# broker's conn ids and channel numbers < 65536.
struct _ChanTagMapMember:
    """Consumer id + ENGINE delivery tag a service tag maps to. Copyable."""
    var consumer_id: UInt64
    var engine_tag: UInt64

    def __init__(out self, cid: UInt64, etag: UInt64):
        self.consumer_id = cid
        self.engine_tag = etag


def _chan_key(conn_id: UInt64, chan: UInt16) -> UInt64:
    """One interning key per (connection, channel) tag namespace."""
    return conn_id * 65536 + UInt64(chan)


struct _ChanTagMap:
    """Per (connection, channel) delivery-tag namespace:

    - next_tag: the next wire delivery-tag issued for this channel;
    - consumer_by_tag / engine_tag_by_tag: outstanding service tag →
      (engine consumer id, engine tag);
    - tags: outstanding service tags in allocation order (bulk resolution
      walks this prefix in tag order — Dict has no key-iteration here).
    """

    var next_tag: UInt64
    var consumer_by_tag: Dict[UInt64, UInt64]
    var engine_tag_by_tag: Dict[UInt64, UInt64]
    var tags: List[UInt64]

    def __init__(out self):
        self.next_tag = 1
        self.consumer_by_tag = Dict[UInt64, UInt64]()
        self.engine_tag_by_tag = Dict[UInt64, UInt64]()
        self.tags = List[UInt64]()


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
    # basic.publish mandatory bit (60,40): when set and the message routed to
    # ZERO queues, the service emits basic.return (60,50) with reply-code 312.
    # -1 = METHOD seen, HEADER not yet arrived; >= 0 = declared body size.
    var mandatory: Int
    var body_size: Int
    # 0017 T2: the publisher's AMQP property-flag word. The raw property-list
    # slice travels in the service's parallel `_pending_prop_bytes` map
    # (List[UInt8] is not Copyable so it cannot live in this struct).
    var prop_flags: UInt16

    def __init__(out self, var ex: String, var rk: String, chan: UInt16, mandatory: Int):
        self.exchange = ex^
        self.routing_key = rk^
        self.channel = chan
        self.mandatory = mandatory
        self.body_size = -1
        self.prop_flags = 0

    # Mojo 1.0: mutate the stored value through a chained call on the Dict
    # (`self._pending[conn].set_body_size(n)`) — an implicit struct copy out of
    # the Dict is rejected, so in-place mutator methods are the pattern.
    def set_body_size(mut self, size: Int):
        self.body_size = size

    def set_prop_flags(mut self, flags: UInt16):
        self.prop_flags = flags


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
    # 0017 T2: the in-flight publish's raw property-list bytes (parallel to
    # `_pending`, which can only carry the Copyable flag word).
    var _pending_prop_bytes: Dict[UInt64, List[UInt8]]
    # 0017 T2: per-(connection, channel) delivery-tag namespaces (the WIRE tag
    # layer, superimposed on the engine's own per-queue tags — see
    # _ChanTagMap above).
    var _chan_maps: Dict[UInt64, _ChanTagMap]
    # Issued channel keys (conn*65536+channel), so per-connection teardown can
    # find the connection's tag namespaces without a key-iterating Dict walk.
    var _chan_key_list: List[UInt64]
    # Per-connection basic.get bookkeeping: the engine consumer registered for
    # gets (and the queue it was registered on) plus the last get delivery tag,
    # so a subsequent basic.ack can address it.
    var _get_cids: Dict[UInt64, UInt64]
    var _get_queues: Dict[UInt64, String]
    var _get_tags: Dict[UInt64, UInt64]
    # Last consumer-tag per registered consumer id (echoed in consume-ok and
    # carried in every deliver frame; AMQP routes deliveries by this string).
    var _ctags: Dict[UInt64, String]
    # Per-connection CLOSED channel numbers (0017 T1: channel.close 20,40).
    # A channel the client has closed (or the server closed with the 404/406
    # error reply) lives here: any method frame on such a channel is answered
    # with the normative channel-level error close; content frames are
    # tolerated silently. channel.open on the number re-opens it (removed).
    var _closed_channels: Dict[UInt64, List[UInt16]]
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
        self._pending_prop_bytes = Dict[UInt64, List[UInt8]]()
        self._chan_maps = Dict[UInt64, _ChanTagMap]()
        self._chan_key_list = List[UInt64]()
        self._get_cids = Dict[UInt64, UInt64]()
        self._get_queues = Dict[UInt64, String]()
        self._get_tags = Dict[UInt64, UInt64]()
        self._ctags = Dict[UInt64, String]()
        self._closed_channels = Dict[UInt64, List[UInt16]]()
        self._content_errors = 0
        # Value advertised in connection.tune and enforced as the per-connection
        # codec ceiling by the listener. config.frame_max is validated >= 4096
        # (see HyrxMQConfig.frame_max / validate).
        self._frame_max = fm

    # ---- 0017 T2: per-channel delivery-tag namespaces ----

    def _chan_alloc_tag(
        mut self, conn_id: UInt64, chan: UInt16, cid: UInt64, etag: UInt64
    ) raises -> UInt64:
        """Issue ONE wire delivery-tag from the channel's own namespace.

        Records the mapping service_tag -> (consumer id, ENGINE tag) so a
        later basic.ack/nack resolves THROUGH this map. The ENGINE tag stays
        queued side but the wire carries the service tag.

        THE TAG IS ALLOCATED PER DELIVERY EVENT, never per queued message: a
        redelivery (engine-tag reuse) gets a FRESH wire tag, the old binding
        is left alone. Overlap immunity comes from the channel's monotonic
        counter — this never looks up, and never reissues, a tag already in
        `tags`.
        """
        var key = _chan_key(conn_id, chan)
        var st = _ChanTagMap()
        if key in self._chan_maps:
            st = self._chan_maps.pop(key)
        else:
            self._chan_key_list.append(key)
        var t = st.next_tag
        st.next_tag += 1
        st.consumer_by_tag[t] = cid
        st.engine_tag_by_tag[t] = etag
        st.tags.append(t)
        self._chan_maps[key] = st^
        return t

    def _chan_take(
        mut self, conn_id: UInt64, chan: UInt16, stag: UInt64
    ) raises -> Optional[_ChanTagMapMember]:
        """Resolve + remove ONE outstanding service tag (single-tag ack/nack)."""
        var key = _chan_key(conn_id, chan)
        if key not in self._chan_maps:
            return Optional[_ChanTagMapMember]()
        var st = self._chan_maps.pop(key)
        if (stag not in st.consumer_by_tag) or (stag not in st.engine_tag_by_tag):
            self._chan_maps[key] = st^
            return Optional[_ChanTagMapMember]()
        var cid = st.consumer_by_tag[stag]
        var etag = st.engine_tag_by_tag[stag]
        _ = st.consumer_by_tag.pop(stag)
        _ = st.engine_tag_by_tag.pop(stag)
        var i = 0
        while i < len(st.tags):
            if st.tags[i] == stag:
                _ = st.tags.pop(i)
                break
            i += 1
        # The NAMESPACE outlives its last outstanding tag: the counter stays
        # monotonic for the channel's life, so the next delivery — a redelivery
        # reuses the ENGINE tag — allocates a FRESH wire tag instead of
        # restarting the numbering and recycling the earlier wire tag.
        self._chan_maps[key] = st^
        return Optional[_ChanTagMapMember](_ChanTagMapMember(cid, etag))

    def _chan_take_through(
        mut self, conn_id: UInt64, chan: UInt16, upper: UInt64
    ) raises -> List[_ChanTagMapMember]:
        """Resolve + remove EVERY outstanding service tag <= `upper` in tag
        order (`upper == 0` = all outstanding, per AMQP multiple semantics)."""
        var key = _chan_key(conn_id, chan)
        var out = List[_ChanTagMapMember]()
        if key not in self._chan_maps:
            return out^
        var st = self._chan_maps.pop(key)
        var i = 0
        while i < len(st.tags):
            var t = st.tags[i]
            if t > upper:
                break
            if (t in st.consumer_by_tag) and (t in st.engine_tag_by_tag):
                out.append(_ChanTagMapMember(st.consumer_by_tag[t], st.engine_tag_by_tag[t]))
                _ = st.consumer_by_tag.pop(t)
                _ = st.engine_tag_by_tag.pop(t)
            _ = st.tags.pop(i)
        # Keep the (possibly emptied) namespace: see _chan_take — the counter
        # must not restart, or a later delivery reissues an already-used tag.
        self._chan_maps[key] = st^
        return out^

    def _chan_drop(mut self, conn_id: UInt64, chan: UInt16) raises:
        """Drop a channel's whole tag namespace (channel close)."""
        var key = _chan_key(conn_id, chan)
        if key in self._chan_maps:
            _ = self._chan_maps.pop(key)

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
            # 0017 T1: the handler may now emit a basic.return (60,50) content
            # sequence (mandatory=1 publish completed with a zero-size body).
            return self._on_content_header(conn_id, frame)
        if frame.frame_type == FRAME_BODY():
            return self._on_content_body(conn_id, frame)
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

        # ---- 0017 T1: CLOSED-channel guard (normative error table) ----
        # After channel.close (20,40) the channel number counts closed. Any
        # subsequent business method (class not in {10 connection, 20 channel})
        # on it is answered with a SERVER-side channel.close carrying
        # reply-code 404 NOT_FOUND ("channel ... already closed") and the
        # failing method's class/method ids; no *_ok is produced for it.
        # Content frames on a closed channel are tolerated silently (guard in
        # _on_content_header/_on_content_body); heartbeat frames never reach
        # dispatch. Channel-class methods stay allowed so the client's
        # close-ok (acknowledgment of the server error close) or a
        # channel.open re-opening the number still parse; connection-class
        # methods on channel 0 are unaffected by per-channel state.
        if (
            self._channel_is_closed(conn_id, chan)
            and chan != 0
            and class_id != 10
            and class_id != 20
        ):
            return self._channel_error(
                chan,
                REPLY_NOT_FOUND(),
                "NOT_FOUND - channel is already closed",
                mid,
            )

        # ---- connection close (10,50): tolerated from ANY state ----
        # (spec: connection.close may be issued during any handshake phase
        # and in face of errors; the reply is always close-ok then teardown.)
        if mid == CONNECTION_CLOSE():
            # Client args: reply-code(short) + reply-text(shortstr) +
            # failing class-id(short) + method-id(short) — read, then ignored:
            # the connection ends regardless of the reason.
            _ = reader.read_short()
            _ = reader.read_short_string()
            _ = reader.read_short()
            _ = reader.read_short()
            # Engine consumers deregistered BEFORE the close-ok goes out so
            # their unacked deliveries requeue cleanly (unregister_consumer's
            # D8 reclaim).
            self._cleanup_connection(conn_id)
            # Reply vs teardown ORDER (normative, amqp0-9-1.xml connection
            # class): close-ok is written on the wire FIRST; the listener
            # (listener.mojo) then closes the slot — the is-CONNECTION_CLOSE
            # byte-glue there sends any response for the frame BEFORE it
            # closes the slot, so this order holds by construction for both
            # the fair-dose and event-driven loops.
            return self._reply(
                chan,
                CONNECTION_CLOSE_OK().class_id,
                CONNECTION_CLOSE_OK().method_id,
                List[UInt8](),
            )

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
            # 0017 T1: channel.open on a PREVIOUSLY CLOSED channel number
            # re-opens it (the closed-channel guard above then no longer
            # fails its methods).
            self._reopen_channel(conn_id, chan)
            var okargs = List[UInt8]()
            write_long_str_empty(okargs)
            return self._reply(
                chan,
                CHANNEL_OPEN_OK().class_id,
                CHANNEL_OPEN_OK().method_id,
                okargs^,
            )

        # ---- channel close (20,40): close-ok on the SAME channel number ----
        # Client args: reply-code(short) + reply-text(shortstr) + failing
        # class-id(short) + method-id(short) — read and ignored. The channel
        # number is marked CLOSED (per-connection `_closed_channels`), so any
        # later method on it gets the 404 channel-error reply above. No
        # in-flight state for this channel survives (a half-reassembled
        # publish on it is dropped fail-closed).
        if mid == CHANNEL_CLOSE():
            _ = reader.read_short()
            _ = reader.read_short_string()
            _ = reader.read_short()
            _ = reader.read_short()
            self._mark_channel_closed(conn_id, chan)
            # 0017 T2: the channel's whole delivery-tag namespace dies with it.
            self._chan_drop(conn_id, chan)
            # close-ok (20,41) carries NO arguments per amqp0-9-1.xml.
            return self._reply(
                chan,
                CHANNEL_CLOSE_OK().class_id,
                CHANNEL_CLOSE_OK().method_id,
                List[UInt8](),
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
            # 0017 T1: mandatory=1 is now CARRIED: a publish routed to ZERO
            # queues gets basic.return (60,50) + content on this channel
            # (see _publish_pending). immediate=1 is NOT honoured (flagged).
            _ = reader.read_short()  # reserved-1
            var pex = reader.read_short_string()
            var prk = reader.read_short_string()
            var pbits = reader.read_octet()
            var mandatory = 0
            if (pbits & BASIC_PUBLISH_BIT_MANDATORY()) != 0:
                mandatory = 1
            # A new METHOD frame re-arms the per-connection state: any previous
            # half-reassembled publish is dropped (bounded, never published).
            self._clear_pending(conn_id)
            self._pending[conn_id] = PendingPublish(pex^, prk^, chan, mandatory)
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
            reply = self._flush_deliveries(conn_id, chan, cid, reply^, no_ack)
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
            # 0017 T2: resolve through the per-channel tag map first.
            var rentry = self._chan_take(conn_id, chan, rtag)
            if rentry.__bool__():
                var r_cid = rentry.value().consumer_id
                var r_tag = rentry.value().engine_tag
                _ = self._broker.reject(r_cid, r_tag)
            elif conn_id in self._consumers:
                _ = self._broker.reject(self._consumers[conn_id], rtag)
            return Optional[List[UInt8]]()

        # ---- basic ack ----
        if mid == BASIC_ACK():
            # Spec arguments: delivery-tag(long-long) + multiple(bit).
            # 0017 T1: multiple=true is now HONOURED — with Router.bulk_ack
            # every unacked tag ≤ this tag on the consumer's queue is
            # acknowledged in tag order (tag 0 = all outstanding, per AMQP).
            # A tag produced by a basic.get delivery is addressed through the
            # get-registered consumer too (the engine resolves a tag through
            # the consumer's queue; tags are idempotent, so a second pass on
            # the same queue is a no-op).
            var tag = reader.read_long_long()
            var ack_bits = reader.read_octet()
            var multiple = (ack_bits & BASIC_ACK_BIT_MULTIPLE()) != 0
            if multiple:
                # 0017 T2: resolve per-channel prefix first (tag order; tag 0
                # = every outstanding tag in this channel's namespace).
                var bulk = self._chan_take_through(conn_id, chan, tag)
                if len(bulk) > 0:
                    for i in range(len(bulk)):
                        var b_cid = bulk[i].consumer_id
                        var b_tag = bulk[i].engine_tag
                        _ = self._broker.ack(b_cid, b_tag)
                    return Optional[List[UInt8]]()
                if conn_id in self._consumers:
                    _ = self._broker.bulk_ack(self._consumers[conn_id], tag)
                if conn_id in self._get_cids:
                    _ = self._broker.bulk_ack(self._get_cids[conn_id], tag)
                return Optional[List[UInt8]]()
            # multiple=false: exactly one tag. The consumer is the one this
            # connection registered via basic.consume; its id is issued by
            # the engine (single authority). A tag produced by basic.get is
            # addressed to the get-registered consumer instead (the engine
            # resolves a tag through the consumer's queue, so the right
            # consumer id matters).
            var done = False
            # 0017 T2: resolve THROUGH the per-channel tag map first.
            var entry = self._chan_take(conn_id, chan, tag)
            if entry.__bool__():
                var e_cid = entry.value().consumer_id
                var e_tag = entry.value().engine_tag
                done = self._broker.ack(e_cid, e_tag)
            # Legacy engine-tag fallback (tags issued before the map, or
            # engine tags addressed via the old bookkeeping):
            if not done and conn_id in self._consumers:
                done = self._broker.ack(self._consumers[conn_id], tag)
            if (
                not done
                and conn_id in self._get_tags
                and conn_id in self._get_cids
                and self._get_tags[conn_id] == tag
            ):
                done = self._broker.ack(self._get_cids[conn_id], tag)
            return Optional[List[UInt8]]()

        # ---- basic nack (60,120) — NO reply (fire-and-forget, like nack's
        # reject sibling; there is no nack-ok in 0-9-1) ----
        if mid == BASIC_NACK():
            # Spec args: delivery-tag(long-long) + bits[multiple=1, requeue=2].
            # 0017 T1 semantics:
            #   requeue=true  → Router.nack* (requeue; the message's delivery
            #                   counter increments on its next dequeue).
            #   requeue=false → the message is DROPPED (x-dead-letter-exchange
            #                   requeue-false routing lands in T3; until then
            #                   drop is the normative-visible behavior).
            #   multiple=true → every unacked tag ≤ this one resolves in tag
            #                   order; tag 0 = all outstanding.
            # NO basic.return is composed for the dropped message (the task
            # states the mandatory-basic.return of a nacked message is NONE
            # here).
            var ntag = reader.read_long_long()
            var nbits = reader.read_octet()
            var n_multiple = (nbits & BASIC_NACK_BIT_MULTIPLE()) != 0
            var n_requeue = (nbits & BASIC_NACK_BIT_REQUEUE()) != 0
            if n_multiple:
                # 0017 T2: per-channel prefix first (tag order; tag 0 = all).
                var nbulk = self._chan_take_through(conn_id, chan, ntag)
                if len(nbulk) > 0:
                    for i in range(len(nbulk)):
                        var b_cid = nbulk[i].consumer_id
                        var b_tag = nbulk[i].engine_tag
                        _ = self._broker.nack(b_cid, b_tag, n_requeue)
                    return Optional[List[UInt8]]()
                if conn_id in self._consumers:
                    _ = self._broker.nack_through(
                        self._consumers[conn_id], ntag, n_requeue
                    )
                if conn_id in self._get_cids:
                    _ = self._broker.nack_through(
                        self._get_cids[conn_id], ntag, n_requeue
                    )
            else:
                var resolved = False
                # 0017 T2: resolve THROUGH the per-channel tag map first.
                var nentry = self._chan_take(conn_id, chan, ntag)
                if nentry.__bool__():
                    var n_cid = nentry.value().consumer_id
                    var n_tag = nentry.value().engine_tag
                    resolved = self._broker.nack(n_cid, n_tag, n_requeue)
                if not resolved and conn_id in self._consumers:
                    resolved = self._broker.nack(self._consumers[conn_id], ntag, n_requeue)
                if (
                    not resolved
                    and conn_id in self._get_tags
                    and conn_id in self._get_cids
                    and self._get_tags[conn_id] == ntag
                ):
                    resolved = self._broker.nack(self._get_cids[conn_id], ntag, n_requeue)
            return Optional[List[UInt8]]()

        # ---- queue.purge (50,30) ----
        if mid == QUEUE_PURGE():
            # Spec args: reserved-1(short) + queue(shortstr) + bits
            # [no-wait=1]. queue.purge-ok (50,31): message-count (long) =
            # number of READY messages dropped. UNACKED deliveries are
            # NEVER touched by purge (normative). Missing queue → the
            # normative channel-level error close with reply-code 404
            # NOT_FOUND (implemented via _channel_error below), then this
            # channel number is closed for further methods per
            # _mark_channel_closed (recorded by the guard's rename of the
            # channel state — see _channel_error).
            _ = reader.read_short()  # reserved-1 (deprecated ticket)
            var pq = reader.read_short_string()
            var pbits = reader.read_octet()
            var purged = self._broker.purge_queue(pq.copy())
            if purged < 0:
                var emsg = "NOT_FOUND - no queue " + pq.copy()
                return self._channel_error(
                    chan,
                    REPLY_NOT_FOUND(),
                    emsg^,
                    mid,
                )
            if (pbits & QUEUE_PURGE_BIT_NO_WAIT()) != 0:
                return Optional[List[UInt8]]()
            var pargs = List[UInt8]()
            write_u32(pargs, UInt32(purged))
            return self._reply(
                chan,
                QUEUE_PURGE_OK().class_id,
                QUEUE_PURGE_OK().method_id,
                pargs^,
            )

        # ---- queue.delete (50,40) ----
        if mid == QUEUE_DELETE():
            # Spec args: reserved-1(short) + queue(shortstr) + bits
            # [if-empty=1, if-unused=2, no-wait=4]. queue.delete-ok (50,41):
            # message-count (long) = REMOVED messages (ready + unacked).
            # Consumers registered on the queue are unregistered by
            # the router (their unacked are deleted with the queue; there is
            # no per-consumer wire callback per 0017 T1 item 11). Refusals:
            # missing queue -> 404 NOT_FOUND channel error;
            # if_empty violated (queue not empty) -> 406 PRECONDITION_FAILED;
            # if_unused violated (active consumers) -> 406 PRECONDITION_FAILED.
            _ = reader.read_short()  # reserved-1
            var dq = reader.read_short_string()
            var dbits = reader.read_octet()
            var dcount = self._broker.delete_queue_checked(
                dq.copy(),
                (dbits & QUEUE_DELETE_BIT_EMPTY()) != 0,
                (dbits & QUEUE_DELETE_BIT_UNUSED()) != 0,
            )
            if dcount == -1:
                var emsg = "NOT_FOUND - no queue " + dq.copy()
                return self._channel_error(
                    chan,
                    REPLY_NOT_FOUND(),
                    emsg^,
                    mid,
                )
            if dcount == -2:
                return self._channel_error(
                    chan,
                    REPLY_PRECONDITION_FAILED(),
                    "PRECONDITION_FAILED - if_empty (queue not empty)",
                    mid,
                )
            if dcount == -3:
                return self._channel_error(
                    chan,
                    REPLY_PRECONDITION_FAILED(),
                    "PRECONDITION_FAILED - if_unused (queue in use)",
                    mid,
                )
            if (dbits & QUEUE_DELETE_BIT_NO_WAIT()) != 0:
                return Optional[List[UInt8]]()
            var delargs = List[UInt8]()
            write_u32(delargs, UInt32(dcount))
            return self._reply(
                chan,
                QUEUE_DELETE_OK().class_id,
                QUEUE_DELETE_OK().method_id,
                delargs^,
            )

        # ---- queue.unbind (50,50) ----
        if mid == QUEUE_UNBIND():
            # Spec args: reserved-1(short) + queue(shortstr) + exchange
            # (shortstr) + routing-key(shortstr) + arguments(table).
            # queue.unbind-ok (50,51): NO arguments. A missing queue,
            # exchange or binding is answered with the 404 NOT_FOUND
            # channel error (normative error table; flagged: rabbit returns
            # 404 also for unbind of a non-existent binding).
            _ = reader.read_short()  # reserved-1
            var uq = reader.read_short_string()
            var ue = reader.read_short_string()
            var urk = reader.read_short_string()
            reader.read_table_skip()  # arguments (not interpreted)
            var unbound = self._broker.unbind_queue(uq.copy(), ue.copy(), urk.copy())
            if not unbound:
                var emsg = "NOT_FOUND - no binding " + uq.copy()
                var emsg2 = emsg + " via " + ue.copy()
                return self._channel_error(
                    chan,
                    REPLY_NOT_FOUND(),
                    emsg2^,
                    mid,
                )
            return self._reply(
                chan,
                QUEUE_UNBIND_OK().class_id,
                QUEUE_UNBIND_OK().method_id,
                List[UInt8](),
            )

        # ---- exchange.delete (40,20) ----
        if mid == EXCHANGE_DELETE():
            # Spec args: reserved-1(short) + exchange(shortstr) + bits
            # [if-unused=1, no-wait=2]. exchange.delete-ok (40,21): NO
            # arguments. Deleting an exchange also unbinds every
            # exchange→exchange binding pointing at it (router-side normative
            # reachability). Missing → 404 channel error; if_unused
            # violated (any binding exists) → 406 channel error.
            _ = reader.read_short()  # reserved-1
            var dex = reader.read_short_string()
            var dbits = reader.read_octet()
            var dcode = self._broker.delete_exchange_checked(
                dex.copy(), (dbits & EXCHANGE_DELETE_BIT_UNUSED()) != 0
            )
            if dcode == -1:
                var emsg = "NOT_FOUND - no exchange " + dex.copy()
                return self._channel_error(
                    chan,
                    REPLY_NOT_FOUND(),
                    emsg^,
                    mid,
                )
            if dcode == -2:
                return self._channel_error(
                    chan,
                    REPLY_PRECONDITION_FAILED(),
                    "PRECONDITION_FAILED - exchange in use (if_unused)",
                    mid,
                )
            if (dbits & EXCHANGE_DELETE_BIT_NO_WAIT()) != 0:
                return Optional[List[UInt8]]()
            return self._reply(
                chan,
                EXCHANGE_DELETE_OK().class_id,
                EXCHANGE_DELETE_OK().method_id,
                List[UInt8](),
            )

        # ---- exchange.bind (40,30): exchange→exchange binding ----
        if mid == EXCHANGE_BIND():
            # Spec args: reserved-1(short) + destination(shortstr) +
            # source(shortstr) + routing-key(shortstr) + bits[no-wait] +
            # arguments(table). Messages published to SOURCE under the
            # routing key route INTO destination (destination bound to
            # source). Missing source or destination → 404 channel error
            # (normative); bind-ok (40,31) carries no arguments.
            _ = reader.read_short()  # reserved-1
            var bdest = reader.read_short_string()
            var bsrc = reader.read_short_string()
            var brk = reader.read_short_string()
            var bbits = reader.read_octet()
            reader.read_table_skip()  # arguments
            var bound = self._broker.bind_exchange(bsrc.copy(), bdest.copy(), brk.copy())
            if not bound:
                var emsg = "NOT_FOUND - no exchange " + bsrc.copy()
                var emsg2 = emsg + " / " + bdest.copy()
                return self._channel_error(
                    chan,
                    REPLY_NOT_FOUND(),
                    emsg2^,
                    mid,
                )
            if (bbits & EXCHANGE_BIND_BIT_NO_WAIT()) != 0:
                return Optional[List[UInt8]]()
            return self._reply(
                chan,
                EXCHANGE_BIND_OK().class_id,
                EXCHANGE_BIND_OK().method_id,
                List[UInt8](),
            )

        # ---- exchange.unbind (40,40) ----
        if mid == EXCHANGE_UNBIND():
            # Spec args: reserved-1(short) + destination(shortstr) +
            # source(shortstr) + routing-key(shortstr) + bits[no-wait] +
            # arguments(table). exchange.unbind-ok carries NO arguments and
            # its index is 51 (40,51) per amqp0-9-1.xml (see constants.mojo).
            # Missing source exchange → 404 channel error; a missing exact
            # binding also errors (404) per normative table (flagged).
            _ = reader.read_short()  # reserved-1
            var xdest = reader.read_short_string()
            var xsrc = reader.read_short_string()
            var xrk = reader.read_short_string()
            var xbits = reader.read_octet()
            reader.read_table_skip()  # arguments
            var unbound = self._broker.unbind_exchange(xsrc.copy(), xdest.copy(), xrk.copy())
            if not unbound:
                var emsg = "NOT_FOUND - no binding " + xdest.copy()
                return self._channel_error(
                    chan,
                    REPLY_NOT_FOUND(),
                    emsg^,
                    mid,
                )
            if (xbits & EXCHANGE_BIND_BIT_NO_WAIT()) != 0:
                return Optional[List[UInt8]]()
            return self._reply(
                chan,
                EXCHANGE_UNBIND_OK().class_id,
                EXCHANGE_UNBIND_OK().method_id,
                List[UInt8](),
            )

        # ---- unhandled method: no reply ----
        # NOT IMPLEMENTED (0017 residual): channel.flow (20,20) [*_ok is the
        # client's own flow-ok — the server must only RESUME/PAUSE], tx.* and
        # confirm.* (T4), secure (10,20/21); unhandled synchronous methods
        # still get no reply (peers would block).
        return Optional[List[UInt8]]()

    # ---- inbound content reassembly (amqp0-9-1.xml §2.3.5) ----

    def _clear_pending(mut self, conn_id: UInt64) raises:
        """Drop the in-flight publish state for a connection (fail closed)."""
        if conn_id in self._pending:
            _ = self._pending.pop(conn_id)
        if conn_id in self._pending_bodies:
            _ = self._pending_bodies.pop(conn_id)
        # 0017 T2: the stored property slice dies with the publish state.
        if conn_id in self._pending_prop_bytes:
            _ = self._pending_prop_bytes.pop(conn_id)

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

    # ---- per-channel closed-state (0017 T1: channel.close 20,40) ----

    def _channel_is_closed(ref self, conn_id: UInt64, chan: UInt16) raises -> Bool:
        """Whether `chan` is in the connection's closed-channel record."""
        if conn_id not in self._closed_channels:
            return False
        var chans = self._closed_channels[conn_id].copy()
        for i in range(len(chans)):
            if chans[i] == chan:
                return True
        return False

    def _mark_channel_closed(mut self, conn_id: UInt64, chan: UInt16) raises:
        """Record `chan` as closed for this connection (channel.close 20,40).

        Deduplicated. Any half-reassembled publish whose METHOD frame ran on
        the closed channel is dropped fail-closed (it can never complete
        legally — content frames on the closed channel are swallowed).
        """
        var chans = List[UInt16]()
        if conn_id in self._closed_channels:
            chans = self._closed_channels[conn_id].copy()
        for i in range(len(chans)):
            if chans[i] == chan:
                return
        chans.append(chan.copy())
        self._closed_channels[conn_id] = chans^
        if conn_id in self._pending:
            if self._pending[conn_id].channel == chan:
                self._clear_pending(conn_id)

    def _reopen_channel(mut self, conn_id: UInt64, chan: UInt16) raises:
        """channel.open (20,10) on a previously closed number re-opens it."""
        if conn_id not in self._closed_channels:
            return
        var kept = List[UInt16]()
        var old = self._closed_channels.pop(conn_id)
        for i in range(len(old)):
            if old[i] != chan:
                kept.append(old[i])
        if len(kept) > 0:
            self._closed_channels[conn_id] = kept^

    def _cleanup_connection(mut self, conn_id: UInt64) raises:
        """Release the connection's engine consumers and per-conn state.

        Called on connection.close (10,50) from ANY state BEFORE the close-ok
        reply is encoded: both consumers (basic.consume slice and the
        basic.get consumer) requeue their unacked deliveries via
        Router.unregister_consumer (single routing authority).
        """
        if conn_id in self._consumers:
            var cid = self._consumers.pop(conn_id)
            _ = self._broker.unregister_consumer(cid)
        if conn_id in self._get_cids:
            var gcid = self._get_cids.pop(conn_id)
            _ = self._broker.unregister_consumer(gcid)
        if conn_id in self._get_tags:
            _ = self._get_tags.pop(conn_id)
        if conn_id in self._get_queues:
            _ = self._get_queues.pop(conn_id)
        self._clear_pending(conn_id)
        # 0017 T2: drop the connection's per-channel delivery-tag namespaces.
        var i = 0
        while i < len(self._chan_key_list):
            var key = self._chan_key_list[i]
            if key // 65536 == conn_id:
                if key in self._chan_maps:
                    _ = self._chan_maps.pop(key)
                _ = self._chan_key_list.pop(i)
            else:
                i += 1
        if conn_id in self._closed_channels:
            _ = self._closed_channels.pop(conn_id)

    def _channel_error(
        ref self,
        chan: UInt16,
        code: UInt16,
        var text: String,
        failing: MethodID,
    ) raises -> Optional[List[UInt8]]:
        """Encode the normative SERVER-side channel-level error: a channel.close
        (20,40) frame carrying reply-code + reply-text + the failing method's
        class/method ids (amqp0-9-1.xml error tables; §1.4.2 channel.close).

        This reply itself CLOSES the channel: the closed-channel state is
        recorded here too (the client answers with channel.close-ok, which
        this service tolerates on the closed number through the channel-class
        guard carve-out).
        """
        _ = self  # ref-only helper (no state writes on the borrow-ref here)
        var eargs = List[UInt8]()
        write_u16(eargs, code)
        write_short_string(eargs, text^)
        write_u16(eargs, failing.class_id)
        write_u16(eargs, failing.method_id)
        var bytes = AMQPFrameCodec.encode_method_frame(
            chan, CHANNEL_CLOSE().class_id, CHANNEL_CLOSE().method_id, eargs^
        )
        return Optional[List[UInt8]](bytes^)

    def _on_content_header(mut self, conn_id: UInt64, frame: AMQPFrame) raises -> Optional[List[UInt8]]:
        """A content HEADER frame: it must follow a basic.publish METHOD frame.

        Only the class-id (must be basic=60) and body-size (§2.3.5.2 offsets
        0:2 / 4:12) are read; the property-list is deliberately NOT decoded
        (property fidelity is NOT PROVEN — see module header).

        0017 T1: a content frame on a CLOSED channel is tolerated silently
        (returns None without touching any state); a completed zero-size
        publish on a mandatory=1 channel can emit a full basic.return content
        sequence as the response.
        """
        if self._channel_is_closed(conn_id, frame.channel):
            return Optional[List[UInt8]]()
        if conn_id not in self._pending:
            self._fail_content(conn_id, "header frame with no pending publish")
            return Optional[List[UInt8]]()
        var hdr = parse_header_frame_payload(frame.payload_copy())
        if hdr.class_id != BASIC_CLASS_ID():
            self._fail_content(
                conn_id,
                "content header class-id "
                + String(hdr.class_id)
                + " is not basic (60)",
            )
            return Optional[List[UInt8]]()
        if self._pending[conn_id].body_size >= 0:
            self._fail_content(conn_id, "second content header for one publish")
            return Optional[List[UInt8]]()
        var size = Int(hdr.body_size)
        if size > MAX_PENDING_BODY():
            self._fail_content(
                conn_id,
                "declared body size " + String(size) + " exceeds the "
                + String(MAX_PENDING_BODY()) + "-byte reassembly ceiling",
            )
            return Optional[List[UInt8]]()
        self._pending[conn_id].set_body_size(size)
        # 0017 T2: STORE the byte-faithful content header as received — the
        # property-flag word goes onto the pending record; the RAW property
        # LIST bytes go into the parallel slice map. Outbound transmit uses
        # both verbatim (see _publish_pending / emit_message_frames): the
        # per-property field values are never re-encoded in this service.
        self._pending[conn_id].set_prop_flags(hdr.property_flags)
        self._pending_prop_bytes[conn_id] = hdr.properties.copy()
        if size == 0:
            # Zero-length body: exactly ZERO body frames follow (§2.3.5.3).
            return self._publish_pending(conn_id)
        return Optional[List[UInt8]]()

    def _on_content_body(mut self, conn_id: UInt64, frame: AMQPFrame) raises -> Optional[List[UInt8]]:
        """A content BODY frame: append, complete, or fail closed.

        Bounds (audit §13/§18): a body frame with no pending publish is dropped
        without allocating; an arrival that would push the accumulated length
        PAST the declared body-size is a protocol error — the whole message is
        dropped, never published, and no further bytes are retained.

        0017 T1: content frames on a CLOSED channel are tolerated silently.
        """
        if self._channel_is_closed(conn_id, frame.channel):
            return Optional[List[UInt8]]()
        if conn_id not in self._pending or conn_id not in self._pending_bodies:
            self._fail_content(conn_id, "body frame with no pending publish")
            return Optional[List[UInt8]]()
        var want = self._pending[conn_id].body_size
        if want <= 0:
            # Either no header yet (body before header, -1) or a zero-size body
            # that already completed: in both cases this frame is out of order.
            self._fail_content(conn_id, "body frame before/after its header")
            return Optional[List[UInt8]]()
        var have = len(self._pending_bodies[conn_id])
        if have + frame.payload_size() > want:
            self._fail_content(
                conn_id,
                "body overflow: "
                + String(have + frame.payload_size())
                + " bytes against a declared "
                + String(want),
            )
            return Optional[List[UInt8]]()
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
            return self._publish_pending(conn_id)
        return Optional[List[UInt8]]()

    def _publish_pending(mut self, conn_id: UInt64) raises -> Optional[List[UInt8]]:
        """Hand the fully reassembled body to the broker (the single publish
        point for inbound content) and clear the per-connection state.

        0017 T1 basic.return (60,50): when the publish carried mandatory=1
        and routed to ZERO queues, the response is the normative unroutable
        signal: a basic.return method (reply-code 312 NO_ROUTE, reply-text
        NO_ROUTE) followed by the message's OWN content (HEADER + BODY)
        frames, emitted on the PUBLISHER's channel. Because dispatch is
        one-frame-in/one-reply-out, this return IS "before any other pending
        reply" for that channel. mandatory=0: silently unrouted (current
        behavior stands)."""
        if conn_id not in self._pending or conn_id not in self._pending_bodies:
            return Optional[List[UInt8]]()
        var p = self._pending.pop(conn_id)
        var body = self._pending_bodies.pop(conn_id)
        # 0017 T2: the raw property-list slice rides beside the flag word.
        var props = List[UInt8]()
        if conn_id in self._pending_prop_bytes:
            props = self._pending_prop_bytes.pop(conn_id)
        # 0017 T2: unknown-exchange publish → channel.close 404 NOT_FOUND
        # (Rabbit normative) — replacing the old 312-no-route path. The
        # default exchange "" is NOT unknown (normative; always present):
        # it routes to nothing in this engine slice (needs-probe: direct
        # queue-name routing), so a mandatory=1 "" publish behaves per the
        # route-miss path below. Unknown exchange WITH mandatory=0 also gets
        # the 404.
        if len(p.exchange.bytes()) != 0 and not self._broker.has_exchange(p.exchange.copy()):
            self._mark_channel_closed(conn_id, p.channel)
            var emsg = "NOT_FOUND - no exchange '" + p.exchange.copy() + "' in vhost '/'"
            return self._channel_error(
                p.channel,
                REPLY_NOT_FOUND(),
                emsg^,
                BASIC_PUBLISH(),
            )
        var routed = self._broker.publish_with_props(
            p.exchange.copy(), p.routing_key.copy(), body.copy(),
            p.prop_flags, props.copy(),
        )
        if p.mandatory == 1 and routed <= 0:
            # basic.return (60,50) args: reply-code(short)=312 + reply-text
            # (shortstr)="NO_ROUTE" + exchange(shortstr) + routing-key
            # (shortstr) — followed by the message content (HEADER+BODY).
            # The content echoes the publisher's OWN stored header (flag
            # word + raw slice) byte-identically.
            var rargs = List[UInt8]()
            write_u16(rargs, REPLY_NO_ROUTE())
            write_short_string(rargs, "NO_ROUTE")
            write_short_string(rargs, p.exchange)
            write_short_string(rargs, p.routing_key)
            return Optional[List[UInt8]](
                emit_message_frames(
                    p.channel, BASIC_RETURN(), rargs^, body^, self._frame_max,
                    p.prop_flags, props.copy(),
                )^
            )
        return Optional[List[UInt8]]()

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
        var etag = d.value().delivery_tag()
        var payload = self._broker.read_payload(cid, etag)
        var routing_key = self._broker.queue_routing_key(cid, etag)
        var message_count = self._broker.queue_message_count(cid)
        # 0017 T2: redelivered bit (engine delivery counter > 1) + the stored
        # content header (flag word + raw slice).
        var redelivered = self._broker.redelivered(cid, etag)
        var prop_flags = self._broker.content_prop_flags(cid, etag)
        var prop_bytes = self._broker.content_prop_bytes_copy(cid, etag)
        # 0017 T2: the WIRE delivery-tag comes from the channel's namespace
        # (get-consumer and push-consumer tags live in ONE namespace). The
        # engine tag is kept only inside the resolution map; queue basis for
        # the message-count stays engine-side.
        var tag = self._chan_alloc_tag(conn_id, chan, cid, etag)
        # get-ok args: delivery-tag long-long + redelivered bit + exchange
        # shortstr + routing-key shortstr + message-count long.
        var gargs = List[UInt8]()
        write_u64(gargs, tag)
        if redelivered:
            gargs.append(1)  # redelivered bit
        else:
            gargs.append(0)  # redelivered bit
        write_short_string(gargs, "")  # exchange (Delivery carries none)
        write_short_string(gargs, routing_key^)
        write_u32(gargs, UInt32(message_count))
        self._get_tags[conn_id] = etag
        if (bits & BASIC_GET_BIT_NO_ACK()) != 0:
            _ = self._broker.ack(cid, etag)
        return Optional[List[UInt8]](
            emit_message_frames(
                chan, BASIC_GET_OK(), gargs^, payload^, self._frame_max,
                prop_flags, prop_bytes^,
            )^
        )

    # ---- reply encoders ----

    def _flush_deliveries(
        mut self,
        conn_id: UInt64,
        chan: UInt16,
        cid: UInt64,
        var dst: List[UInt8],
        auto_ack: Bool,
    ) raises -> List[UInt8]:
        """Append full basic.deliver content for messages queued for cid.

        Each message becomes METHOD + HEADER + BODY frames via
        emit_message_frames. 0017 T2: the wire delivery-tag comes from the
        channel's OWN namespace (mapped on top of the engine's tags, see
        _chan_alloc_tag); the redelivered bit + the stored content header
        (flag word + raw slice) ride per message. Bounded by
        _CONSUME_FLUSH_MAX per reply; `dst` round-trips (ownership: consumed
        in, returned).
        """
        var ctag = String(cid)
        if cid in self._ctags:
            ctag = self._ctags[cid]
        var n = 0
        while n < _CONSUME_FLUSH_MAX():
            var d = self._broker.deliver(cid)
            if not d.__bool__():
                return dst^
            var etag = d.value().delivery_tag()
            var payload = self._broker.read_payload(cid, etag)
            var routing_key = self._broker.queue_routing_key(cid, etag)
            # 0017 T2: redelivered = the engine's delivery counter > 1; the
            # content header is the stored publisher slice, re-emitted
            # byte-identically.
            var redelivered = self._broker.redelivered(cid, etag)
            var prop_flags = self._broker.content_prop_flags(cid, etag)
            var prop_bytes = self._broker.content_prop_bytes_copy(cid, etag)
            var tag = self._chan_alloc_tag(conn_id, chan, cid, etag)
            # deliver args: consumer-tag shortstr + delivery-tag long-long +
            # redelivered bit + exchange shortstr + routing-key shortstr.
            var args = List[UInt8]()
            write_short_string(args, ctag.copy())
            write_u64(args, tag)
            if redelivered:
                args.append(1)  # redelivered bit
            else:
                args.append(0)  # redelivered bit
            write_short_string(args, "")  # exchange (Delivery carries none)
            write_short_string(args, routing_key^)
            var wire = emit_message_frames(
                chan, BASIC_DELIVER(), args^, payload^, self._frame_max,
                prop_flags, prop_bytes^,
            )
            var dst_old_len = len(dst)
            dst.resize(unsafe_uninit_length=dst_old_len + len(wire))
            unsafe_memcpy(
                dest=dst.unsafe_ptr() + dst_old_len,
                src=wire.unsafe_ptr(),
                count=len(wire),
            )
            if auto_ack:
                _ = self._broker.ack(cid, etag)
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
