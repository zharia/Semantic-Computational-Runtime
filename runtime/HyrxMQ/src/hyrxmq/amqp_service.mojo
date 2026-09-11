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
#   remains NOT implemented.
# - 0017 T4 AUTH: credentials ARE validated now. The SASL PLAIN response
#   (authcid/passwd, RFC 4616) is checked against HyrxMQConfig.users
#   (default admin/password); a mismatch — or a non-PLAIN mechanism — is the
#   normative SERVER-initiated connection.close (10,50) reply-code 403
#   ACCESS_REFUSED with the reference close text ("...using authentication
#   mechanism PLAIN. For details see the broker logfile.", failing method =
#   connection.start_ok 10,11), emitted BEFORE any further serving.
# - 0017 T4 publisher confirms (confirm class 85, RabbitMQ extension):
#   confirm.select (85,10) → confirm.select-ok (85,11) arms per-channel
#   confirm mode; every completed basic.publish on that channel is then
#   acknowledged to the publisher with basic.ack (60,80)
#   delivery-tag = 1-based per-channel confirm counter, multiple=0 — AFTER
#   the route (the router's publish returned), so a fan-out to ZERO queues
#   STILL acks (empty fanout is handled), and a mandatory=1 unroutable
#   publish emits the basic.return content sequence FIRST and the confirm
#   ack AFTER it (the wire ordering rabbit uses). No broker-internal
#   confirm timeout exists (the ack always follows the completed publish;
#   multi_ack opt-in is NOT IMPLEMENTED — every ack is multiple=0 single-tag).
# - 0017 T4 transactions (tx class 90): tx.select (90,10) → select-ok arms
#   per-channel tx mode: basic.publish bodies are STAGED (never pushed to the
#   router) until tx.commit (90,20), which pushes them into the router's
#   queue storage exactly in publish order (each gets the same route +
#   unknown-exchange 404 + basic.return + confirm-ack treatment it would
#   have gotten immediately) → commit-ok (90,21). tx.rollback (90,30) drops
#   the staging → rollback-ok (90,31). get/deliver semantics are NOT changed
#   in tx mode (consumers see only committed messages — standard flow).
# - 0017 T4 heartbeats (PARTIAL, honest scope): tune (10,30) now advertises
#   heartbeat=60 (HyrmMQConfig.heartbeat_secs); the negotiated value is
#   min(advertised, the client's tune-ok heartbeat) and is recorded on the
#   connection state. The MINIMAL client-heartbeat protocol is implemented
#   INSIDE the serving loop (listener.mojo): a received heartbeat frame
#   (type 8) is answered IMMEDIATELY with our own heartbeat frame (cheap
#   ping-pong that keeps client liveness timers satisfied). NOT IMPLEMENTED:
#   server CYCLIC heartbeats (no timer subsystem exists per-platform) and
#   the 2x-missed-heartbeat connection close — every conformance-matrix row
#   records this honestly as PARTIAL.
# - 0017 T3 (declare-bit semantics + queue arguments): the declare `arguments`
#   field tables ARE DECODED now (ByteReader.read_table → FieldTable; the
#   read_table_skip calls below that remain are non-queue-class tables).
#   passive/durable/exclusive/auto-delete bits are parsed AND enforced:
#   passive declare replays the REAL counts (message_count = ready depth,
#   consumer_count = live consumers; declare of a MISSING queue/exchange or a
#   type/flag-inequivalent redeclare gets the normative 404 / 405 / 406
#   channel-error close with failing cls/mid). durable is a metadata FLAG only
#   (no disk persistence — milestone 0018), exclusive queues are owned by the
#   declaring client connection (auto-delete on close, 405 for foreign
#   consume/get/ddeclare), auto_delete deletes on the last-consumer/unbind
#   event (basic.cancel now unregisters the engine consumer — the old
#   no-op-cancel slice behavior is retired). The queue arguments
#   x-message-ttl (delivery-time expiry; expired messages dead-letter FIRST
#   when x-dead-letter-exchange is set, else drop), x-expires (LAZY deletion —
#   last-activity evaluated on next declare/get/consume; NO timer subsystem
#   exists, recorded as PARTIAL), x-max-length (drop-head trimming at the cap,
#   or overflow='reject-publish' capacity refusal) and x-dead-letter
#   exchange/routing-key (basic.reject/nack requeue=false + TTL expiry route
#   into the DLX through the Router) are all honored. The DEFAULT exchange ""
#   now publishes DIRECT into the queue named by the routing key (the
#   exchange's normative pre-bound direct binding; needs-probe resolved).
# - 0017 T4 heartbeats: see the T4 block above — tune advertises 60, the
#   ping-pong reply is implemented in the serving loop; server cyclic
#   heartbeats + 2x-miss close remain NOT IMPLEMENTED (no timer subsystem).
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
# - the declare `arguments` field tables of exchange.declare/queue.declare/
#   basic.consume are DECODED since 0017 T3 (see the not-implemented list
#   above for what remains out of scope: connection-close state enforcement,
#   secure, heartbeats).
# - basic.cancel is answered with cancel-ok AND the engine consumer is now
#   unregistered (0017 T3 auto-delete semantics; deliveries requeue through
#   the Router).
# - connection state enforcement: business methods are not gated on the
#   connection=open state (AMQPConnectionState is written but never gates
#   dispatch; only the listener's handshake phases gate frames).
# - get-ok message-count is always 0: the engine exposes no queue-depth read-back
#   (the field is wire-correct in length, not accurate in value).
# - channel.flow (20,20) has no handler; publish `immediate=1` is parsed and
#   ignored (unroutable-immediate has no return in this broker).

from std.collections import Dict, List, Optional
from std.memory import unsafe_memcpy
from std.time import monotonic

from hyrx.amqp.frame_codec import (
    AMQPFrame,
    AMQPFrameCodec,
    parse_header_frame_payload,
)
from hyrx.amqp.field_table import FieldTable
from hyrx.core.exchange import HeaderArgs
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
    FRAME_HEARTBEAT,
    CONFIRM_SELECT,
    CONFIRM_SELECT_OK,
    TX_SELECT,
    TX_SELECT_OK,
    TX_COMMIT,
    TX_COMMIT_OK,
    TX_ROLLBACK,
    TX_ROLLBACK_OK,
    REPLY_ACCESS_REFUSED,
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
from hyrx.core.storage import MessageJournal
from hyrxmq.config import HyrxMQConfig, UserRecord
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


def QUEUE_DECLARE_BIT_PASSIVE() -> UInt8:
    return 1


def QUEUE_DECLARE_BIT_DURABLE() -> UInt8:
    return 2


def QUEUE_DECLARE_BIT_EXCLUSIVE() -> UInt8:
    return 4


def QUEUE_DECLARE_BIT_AUTO_DELETE() -> UInt8:
    return 8


# exchange.declare bit-packed flags (same octet layout): passive=1,
# durable=2, reserved=4, auto-delete=8, no-wait=16 (Rabbit extension layout).
def EXCHANGE_DECLARE_BIT_PASSIVE() -> UInt8:
    return 1


def EXCHANGE_DECLARE_BIT_DURABLE() -> UInt8:
    return 2


def EXCHANGE_DECLARE_BIT_AUTO_DELETE() -> UInt8:
    return 8


def EXCHANGE_DECLARE_BIT_NO_WAIT() -> UInt8:
    return 16


# 0017 T3: RESOURCE_LOCKED reply-code (exclusive-queue access table).
def REPLY_RESOURCE_LOCKED() -> UInt16:
    return 405


# 0017 T3 field-table type tag of AMQP long-int 'I' (see field_table.mojo).
def FT_TYPE_INT() -> Int:
    return 73


def FT_TYPE_STRING() -> Int:
    return 83


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
    authcid is the segment between the first and second NUL. Validated against
    HyrxMQConfig.users (0017 T4) and echoed in the handshake log line.
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


def _sasl_plain_passwd(var response: String) -> String:
    """Recover the passwd from a SASL PLAIN response: the segment after the
    SECOND NUL (RFC 4616: authzid NUL authcid NUL passwd). Validated against
    HyrxMQConfig.users (0017 T4); never logged."""
    var b = response.as_bytes()
    var n = len(b)
    var nuls = 0
    var i = 0
    while i < n:
        if b[i] == 0:
            nuls += 1
            if nuls == 2:
                i += 1
                break
        i += 1
    var out = String()
    while i < n and b[i] != 0:
        out.append(Codepoint(b[i]))
        i += 1
    return out^


# confirm.select (85,10) bit-packed flags: the single (low) nowait bit.
def CONFIRM_SELECT_BIT_NO_WAIT() -> UInt8:
    return 1


def write_u32(mut out: List[UInt8], value: UInt32):
    """Append a big-endian u32."""
    out.append(UInt8((value >> 24) & 0xFF))
    out.append(UInt8((value >> 16) & 0xFF))
    out.append(UInt8((value >> 8) & 0xFF))
    out.append(UInt8(value & 0xFF))


def _concat(mut out: List[UInt8], var src: List[UInt8]):
    """Append one encoded frame/list onto `out` in one memcpy (0017 T4:
    multi-frame responses — basic.return + confirm-ack, tx.commit batches)."""
    var n = len(src)
    if n == 0:
        return
    var old_len = len(out)
    out.resize(unsafe_uninit_length=old_len + n)
    unsafe_memcpy(dest=out.unsafe_ptr() + old_len, src=src.unsafe_ptr(), count=n)


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


def write_string_field(mut out: List[UInt8], var key: String, var value: String):
    """Append one field-table entry with a long-string ('S') value:
    short-str key + type octet 'S' + u32 len + bytes (the encoding
    FieldTable.to_bytes uses for its string values)."""
    write_short_string(out, key^)
    out.append(UInt8(83))  # 'S' = long string
    write_long_string(out, value^)


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

    def read_table(mut self) raises -> FieldTable:
        """DECODE a field table (0017 T3): length-bounded slice → FieldTable.

        The 4-byte declared length is trusted only within the remaining
        bytes (bounded parse — a truncated table decodes as far as its
        bytes reach, never past the frame)."""
        var n = Int(self.read_long())
        if self.pos + n > len(self.data):
            raise (
                "ByteReader.read_table: declared table of "
                + String(n)
                + " bytes exceeds "
                + String(len(self.data) - self.pos)
                + " remaining"
            )
        var slice = List[UInt8]()
        slice.append(UInt8((n >> 24) & 0xFF))
        slice.append(UInt8((n >> 16) & 0xFF))
        slice.append(UInt8((n >> 8) & 0xFF))
        slice.append(UInt8(n & 0xFF))
        for i in range(n):
            slice.append(self.data[self.pos])
            self.pos += 1
        return FieldTable.from_bytes(slice^)

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


# 0017 T4: per-channel PUBLISHER-CONFIRM state. Confirms use their OWN
# 1-based per-channel ack-id namespace (RabbitMQ semantics), independent of
# the delivery-tag namespace above: `mode` arms confirm delivery
# (confirm.select 85,10) and `next_tag` is the ack-id issued for the NEXT
# completed publish on the channel (starts at 1).
struct _ChanConfirm:
    """Per-(connection, channel) publisher-confirm state. Copyable."""

    var mode: Bool
    var next_tag: UInt64

    def __init__(out self):
        self.mode = False
        self.next_tag = 1


# 0017 T4: ONE staged transactional publish (tx mode). Copyable on purpose (
# same dict-of-struct pattern as PendingPublish): the staged BODY + property
# slice bytes are carried on the struct (they are ValueCopyable) until the
# commit pushes them through the router exactly as an immediate publish was.
struct _TxStaged:
    """One queued (tx-mode) publish awaiting tx.commit/tx.rollback."""

    var exchange: String
    var routing_key: String
    var mandatory: Int
    var prop_flags: UInt16
    var body: List[UInt8]
    var props: List[UInt8]

    def __init__(
        out self,
        var ex: String,
        var rk: String,
        mand: Int,
        flags: UInt16,
        var body_bytes: List[UInt8],
        var prop_bytes: List[UInt8],
    ):
        self.exchange = ex^
        self.routing_key = rk^
        self.mandatory = mand
        self.prop_flags = flags
        self.body = body_bytes^
        self.props = prop_bytes^


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


# ---- 0017 T3: declare-flag metadata (service-owned lifecycle) ----


struct _QueueMeta:
    """AMQP declare-flag metadata for one queue.

    exclusive/owner: a CLIENT-connection-owned queue (one-connection
    lifetime) — `owner` = the declaring connection id (0 = shared). The
    queue auto-deletes on that connection's close and denies consume/get
    from other connections. persist_expire: x-expires LAZY expiry window
    (ms; 0 = off) evaluated on the next access (get/declare/consume) —
    the service has no timer subsystem, so expiry is NOT proactive (the
    honest PARTIAL framing per receipt)."""

    var durable: Bool
    var exclusive: Bool
    var auto_delete: Bool
    var owner: UInt64
    var expires_ms: Int
    var last_ms: Int

    def __init__(
        out self,
        durable: Bool,
        exclusive: Bool,
        auto_delete: Bool,
        owner: UInt64,
        expires_ms: Int,
        last_ms: Int,
    ):
        self.durable = durable
        self.exclusive = exclusive
        self.auto_delete = auto_delete
        self.owner = owner
        self.expires_ms = expires_ms
        self.last_ms = last_ms

    def touch(mut self, now_ms: Int):
        """Record one access of the queue (lazy x-expires basis)."""
        self.last_ms = now_ms


struct _ExchangeMeta:
    """AMQP declare-flag metadata for one exchange (durable flag + the
    auto-delete bit: delete on the LAST unbind)."""

    var durable: Bool
    var auto_delete: Bool
    var last_ms: Int

    def __init__(out self, durable: Bool, auto_delete: Bool, last_ms: Int):
        self.durable = durable
        self.auto_delete = auto_delete
        self.last_ms = last_ms

    def touch(mut self, now_ms: Int):
        self.last_ms = now_ms


def _now_ms() -> Int:
    """Monotonic milliseconds (steady clock; no timer infra — used lazily."""
    return Int(monotonic() // 1_000_000)


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
    # 0017 T3: declare-flag metadata (service-owned; single lifecycle
    # per queue/exchange, mirroring the field-table argument semantics).
    var _queue_meta: Dict[String, _QueueMeta]
    var _queue_meta_keys: List[String]
    var _exchange_meta: Dict[String, _ExchangeMeta]
    var _exchange_meta_keys: List[String]
    # 0017 T3: reverse ctag → engine consumer id (basic.cancel resolution +
    # auto-delete last-consumer bookkeeping) and cid → queue name.
    var _cids: Dict[UInt64, String]
    var _cid_by_ctag: Dict[String, UInt64]
    # 0017 T4: SASL PLAIN credentials table (copied from the config BEFORE
    # `config` is consumed by the broker).
    var _users: List[UserRecord]
    # 0017 T4: the heartbeat value ADVERTISED in connection.tune (10,30).
    var _heartbeat_secs: Int
    # 0017 T4: the NEGOTIATED heartbeat per connection = min(advertised,
    # the client's tune-ok value); recorded on tune-ok (10,31).
    var _heartbeat_negotiated: Dict[UInt64, UInt16]
    # 0017 T4: per-(connection, channel) publisher-confirm state (85).
    var _confirms: Dict[UInt64, _ChanConfirm]
    var _confirm_keys: List[UInt64]
    # 0017 T4: per-(connection, channel) tx staging (90).
    var _tx: Dict[UInt64, List[_TxStaged]]
    var _tx_keys: List[UInt64]

    def __init__(out self, var config: HyrxMQConfig):
        # Read frame_max + the T4 values (users table, heartbeat advertised)
        # BEFORE `config` is consumed by HyrxMQBroker(config^) — all three are
        # read from the still-owned config here, then it is moved.
        var fm = config.frame_max
        var hb = config.heartbeat_secs
        # Element-wise rebuild of the users table (an explicit __init__ chain
        # is used in place of List[UserRecord].copy() so the copy never
        # depends on a non-trivial struct list's CollectionElement conformance
        # — the same conservative pattern Mojo 1.0 dict-of-struct code here
        # uses: String copies only).
        var users = List[UserRecord]()
        for i in range(len(config.users)):
            users.append(
                UserRecord(
                    config.users[i].username.copy(),
                    config.users[i].password.copy(),
                )
            )
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
        self._queue_meta = Dict[String, _QueueMeta]()
        self._queue_meta_keys = List[String]()
        self._exchange_meta = Dict[String, _ExchangeMeta]()
        self._exchange_meta_keys = List[String]()
        self._cids = Dict[UInt64, String]()
        self._cid_by_ctag = Dict[String, UInt64]()
        # 0017 T4: users table + heartbeat advertised value (copied above,
        # before the config was consumed).
        self._users = users^
        self._heartbeat_secs = hb
        self._heartbeat_negotiated = Dict[UInt64, UInt16]()
        self._confirms = Dict[UInt64, _ChanConfirm]()
        self._confirm_keys = List[UInt64]()
        self._tx = Dict[UInt64, List[_TxStaged]]()
        self._tx_keys = List[UInt64]()
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
        """Drop a channel's whole per-connection namespace (channel close).

        0017 T4: the channel's CONFIRM state and TX STAGING die with it too
        (a rolled-back-by-close staging is dropped fail-closed, never
        published — matching the half-reassembled publish rule)."""
        var key = _chan_key(conn_id, chan)
        if key in self._chan_maps:
            _ = self._chan_maps.pop(key)
        # 0017 T4: confirms + tx staging are channel-scoped as well.
        if key in self._confirms:
            _ = self._confirms.pop(key)
        if key in self._tx:
            _ = self._tx.pop(key)

    # ---- 0017 T4: publisher-confirm state (confirm class 85) ----

    def _confirm_enable(mut self, conn_id: UInt64, chan: UInt16) raises:
        """Arm publisher-confirms for the channel (confirm.select 85,10)."""
        var key = _chan_key(conn_id, chan)
        var st = _ChanConfirm()
        if key in self._confirms:
            st = self._confirms.pop(key)
        else:
            self._confirm_keys.append(key)
        st.mode = True
        # next_tag stays where the channel's confirm counter is (the ack-id
        # namespace is per channel and monotonic over its life — rabbit
        # parity; it does not restart on re-select).
        self._confirms[key] = st^

    def _confirm_next_tag(
        mut self, conn_id: UInt64, chan: UInt16
    ) raises -> Optional[UInt64]:
        """Issue the NEXT confirm ack-id (1-based, per channel) when the
        channel is in confirm mode; None = not confirming."""
        var key = _chan_key(conn_id, chan)
        if key not in self._confirms:
            return Optional[UInt64]()
        var st = self._confirms.pop(key)
        var t = st.next_tag
        st.next_tag += 1
        self._confirms[key] = st^
        return Optional[UInt64](t)

    # ---- 0017 T4: tx staging (tx class 90) ----

    def _tx_enable(mut self, conn_id: UInt64, chan: UInt16) raises:
        """Arm tx mode for the channel (tx.select 90,10). The staging list
        starts empty; commit/rollback consume it."""
        var key = _chan_key(conn_id, chan)
        var lst = List[_TxStaged]()
        if key in self._tx:
            lst = self._tx.pop(key)
        else:
            self._tx_keys.append(key)
        self._tx[key] = lst^

    def _tx_active(ref self, conn_id: UInt64, chan: UInt16) -> Bool:
        """Whether the channel is in tx mode (staging publishes)."""
        return _chan_key(conn_id, chan) in self._tx

    def _tx_stage(mut self, conn_id: UInt64, chan: UInt16, var msg: _TxStaged) raises:
        """STAGE one completed publish in tx mode (in publish order)."""
        var key = _chan_key(conn_id, chan)
        var lst = List[_TxStaged]()
        if key in self._tx:
            lst = self._tx.pop(key)
        else:
            self._tx_keys.append(key)
        lst.append(msg^)
        self._tx[key] = lst^

    def _tx_take(mut self, conn_id: UInt64, chan: UInt16) raises -> List[_TxStaged]:
        """Take (and clear) the channel's whole staging in publish order.

        The key STAYS armed: commit/rollback END the current transaction but
        leave the channel in tx mode (rabbit parity), so a later publish on the
        same channel keeps staging. Popping the key here de-armed tx mode after
        the first commit — the next publish then bypassed staging and reached
        the router, surviving a subsequent rollback."""
        var key = _chan_key(conn_id, chan)
        if key not in self._tx:
            return List[_TxStaged]()
        var staged = self._tx.pop(key)
        self._tx[key] = List[_TxStaged]()
        return staged^

    # ---- lifecycle / broker delegation ----

    # ---- 0018: pluggable storage pass-throughs (additive) ----

    def attach_journal(mut self, var journal: MessageJournal):
        """Inject the storage journal into the broker's engine (the boot
        bootstrap wire; the service holds no fs logic of its own)."""
        self._broker.attach_journal(journal^)

    def recover_journal(mut self) raises -> Int:
        """Replay the injected journal into the engine (the durable
        recovery at the listener's service start)."""
        return self._broker.recover_journal()

    def flush_storage(mut self) raises:
        """Flush the injected journal through the broker (graceful-
        shutdown durability; a no-op for the disabled/memory tiers)."""
        self._broker.sync_storage()

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

    def connection_start_frame(ref self) raises -> List[UInt8]:
        """Encode the connection.start (10,10) server frame (channel 0).

        Wire arguments, big-endian, exactly per amqp0-9-1.xml:
          version-major(octet)=0, version-minor(octet)=9,
          server-properties(field table)=u32 len + entries,
          mechanisms(longstr)="PLAIN", locales(longstr)="en_US".

        server-properties mirrors rabbit 4.3.5's shape: `capabilities` is a
        NESTED field table (type 'F' = u32 len + body, per the hard-coded
        field types) carrying ONLY the optional classes this dispatch
        actually serves — publisher_confirms (confirm.select 85,10),
        exchange_exchange_bindings (exchange.bind 40,30), basic.nack
        (60,120), consumer_cancel_notify (basic.cancel 60,30) and
        authentication_failure_close (the 403 connection.close emitted on a
        refused login) — plus the app-label strings product/version/platform/
        cluster_name/copyright/information ('S'). The former empty table made
        pika reject confirm.select with
        MethodNotImplemented("Confirm.Select not Supported by Server"): the
        client gates the extension on the advertised capability, not on the
        broker's actual dispatch.

        The listener sends this as the first server frame after echoing the
        8-octet protocol header.
        """
        var args = List[UInt8]()
        args.append(UInt8(0))  # version-major
        args.append(UInt8(9))  # version-minor

        # capabilities: nested field table, bools per the FieldTable 't'
        # writer (set_bool → to_bytes emits u32 len + body = the 'F' value).
        var caps = FieldTable()
        caps.set_bool("publisher_confirms", True)
        caps.set_bool("exchange_exchange_bindings", True)
        caps.set_bool("basic.nack", True)
        caps.set_bool("consumer_cancel_notify", True)
        caps.set_bool("authentication_failure_close", True)

        # server-properties table body: built first (u32 len + body boundary
        # is written after the length is known — amqp0-9-1 §1.1.1.1.1).
        var props = List[UInt8]()
        write_short_string(props, "capabilities")
        props.append(UInt8(70))  # 'F' = nested field table
        write_table(props, caps)
        write_string_field(props, "cluster_name", self._broker.node_name())
        write_string_field(props, "product", "HyrxMQ")
        write_string_field(props, "version", "4.3.5")
        write_string_field(props, "platform", "Mojo")
        write_string_field(
            props, "copyright", "Copyright (C) 2026 HyrxMQ contributors."
        )
        write_string_field(
            props,
            "information",
            "HyrxMQ — SCR AMQP 0-9-1 broker (RabbitMQ-compatible wire dialect).",
        )
        write_u32(args, UInt32(len(props)))
        _concat(args, props^)

        write_long_string(args, "PLAIN")  # mechanisms (longstr)
        write_long_string(args, "en_US")  # locales (longstr)
        return AMQPFrameCodec.encode_method_frame(
            UInt16(0),
            CONNECTION_START().class_id,
            CONNECTION_START().method_id,
            args^,
        )

    def _reply_tune(ref self, chan: UInt16) -> Optional[List[UInt8]]:
        """connection.tune (10,30): channel-max(2047), frame-max, heartbeat.

        0017 T4: heartbeat now ADVERTISES the configured value
        (`HyrmMQConfig.heartbeat_secs`, default 60). The negotiated value is
        min(this, the client's tune-ok heartbeat) and is recorded at tune-ok
        (10,31). PARTIAL scope (no timer subsystem): the broker does NOT send
        cyclic heartbeats and does NOT close on 2 misses; the listener
        answers each RECEIVED heartbeat frame immediately (ping-pong).
        """
        var args = List[UInt8]()
        write_u16(args, 2047)  # channel-max (short)
        write_u32(args, UInt32(self._frame_max))  # frame-max (long)
        write_u16(args, UInt16(self._heartbeat_secs))  # heartbeat (short)
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
        if frame.frame_type == FRAME_HEARTBEAT():
            # 0017 T4 (minimal client-heartbeat protocol): a received
            # heartbeat frame (type 8, zero payload) gets an IMMEDIATE
            # heartbeat reply — the cheap ping-pong that keeps a client's
            # liveness timer satisfied. The SERVING LOOP also answers these
            # inline (listener.mojo); this branch keeps the direct
            # handle_frame path (unit tests) wire-correct too.
            return Optional[List[UInt8]](
                AMQPFrameCodec.encode_heartbeat(frame.channel)
            )
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
        # _on_content_header/_on_content_body); heartbeat frames are ANSWERED
        # (echo — 0017 T4 ping-pong) above, before this guard. Channel-class methods stay allowed so the client's
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
            # 0017 T4 AUTH: SASL PLAIN response = `authzid NUL authcid NUL
            # passwd` (RFC 4616). Validated against HyrxMQConfig.users; the
            # password is never logged.
            var authcid = _sasl_plain_authcid(response.copy())
            var passwd = _sasl_plain_passwd(response.copy())
            print(
                "hyrxmq: connection.start-ok mechanism="
                + mechanism
                + " authcid="
                + authcid
                + " locale="
                + locale
            )
            var auth_ok = False
            if len(mechanism.bytes()) != 0 and mechanism.copy() == "PLAIN":
                for i in range(len(self._users)):
                    if (
                        self._users[i].username.copy() == authcid.copy()
                        and self._users[i].password.copy() == passwd.copy()
                    ):
                        auth_ok = True
                        break
            if not auth_ok:
                # Normative SERVER-initiated close (rabbit ground truth):
                # reply-code 403 ACCESS_REFUSED + the reference close text,
                # failing method = connection.start_ok (10,11). Emitted BEFORE
                # any further serving (tune is never sent on a refused login).
                var msg_c1 = "ACCESS_REFUSED - Login was refused using authentication mechanism "
                var msg_c2 = msg_c1 + mechanism.copy()
                var msg_c3 = msg_c2 + ". For details see the broker logfile."
                var cargs = List[UInt8]()
                write_u16(cargs, REPLY_ACCESS_REFUSED())
                write_short_string(cargs, msg_c3^)
                write_u16(cargs, CONNECTION_START_OK().class_id)
                write_u16(cargs, CONNECTION_START_OK().method_id)
                return self._reply(
                    UInt16(0),
                    CONNECTION_CLOSE().class_id,
                    CONNECTION_CLOSE().method_id,
                    cargs^,
                )
            if conn_id not in self._conns:
                self._conns[conn_id] = AMQPConnectionState()
            self._conns[conn_id].set_state(CONN_STATE_TUNE_SENT())
            return self._reply_tune(chan)

        if mid == CONNECTION_TUNE_OK():
            # connection.tune-ok (10,31): channel-max(short) + frame-max(long)
            # + heartbeat(short). 0017 T4: the heartbeat is NEGOTIATED —
            # min(what we advertised in tune, the client's tune-ok value) —
            # and recorded on the connection state (0 = disabled). The value
            # is recorded only (not re-enforced: see the PARTIAL heartbeat
            # scope in the module header); record + state, no reply.
            if conn_id not in self._conns:
                self._conns[conn_id] = AMQPConnectionState()
            _ = reader.read_short()  # channel-max (recorded, not re-enforced)
            _ = reader.read_long()  # frame-max (recorded, not re-enforced)
            var client_hb = reader.read_short()
            var neg_hb = self._heartbeat_secs
            if UInt16(client_hb) < UInt16(neg_hb):
                neg_hb = Int(client_hb)
            self._conns[conn_id].negotiate(
                UInt16(2047), UInt32(self._frame_max), UInt16(neg_hb)
            )
            self._heartbeat_negotiated[conn_id] = UInt16(neg_hb)
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
        # exchange.declare (40,10). Bits: passive(1) durable(2)
        # reserved(4) auto-delete(8) no-wait(16); trailing `arguments`
        # field table (AMQP arguments semantics are queue-class only —
        # x-args on exchanges are not defined, so the table is parsed but
        # not reinterpreted). 0017 T3 declare-bit semantics:
        #   passive=1: queue EXISTS → the exchange is NOT mutated, reply
        #     declare-ok (the shape parity); a MISSING exchange → the
        #     normative server-side channel.close (reply-code=404,
        #     reply-text="NOT_FOUND - no exchange '<name>' in vhost '/'",
        #     failing cls/mid = (40,10)); a declared TYPE that differs from
        #     the existing exchange's type → 406 PRECONDITION_FAILED
        #     (inequivalent arg 'type').
        #   durable: FLAG ONLY (in-memory metadata; the report layer notes
        #     milestone 0018 persistence — NO disk persistence is claimed).
        #   auto_delete: delete on the LAST unbind (exchange.unbind and
        #     queue.unbind paths both count bindings before dropping).
        if mid == EXCHANGE_DECLARE():
            _ = reader.read_short()  # reserved-1 (deprecated "ticket")
            var ex_name = reader.read_short_string()
            var ex_type = reader.read_short_string()
            var ebits = reader.read_octet()
            var eargs_ft = reader.read_table()
            var e_passive = (ebits & EXCHANGE_DECLARE_BIT_PASSIVE()) != 0
            var e_durable = (ebits & EXCHANGE_DECLARE_BIT_DURABLE()) != 0
            var e_auto = (ebits & EXCHANGE_DECLARE_BIT_AUTO_DELETE()) != 0
            var e_no_wait = (ebits & EXCHANGE_DECLARE_BIT_NO_WAIT()) != 0
            _ = eargs_ft  # decoded, no queue-class semantics apply here
            var e_exists = self._broker.has_exchange(ex_name.copy())
            if e_passive:
                if not e_exists:
                    self._mark_channel_closed(conn_id, chan)
                    var emsg1 = "NOT_FOUND - no exchange '"
                    var emsg2 = emsg1 + ex_name.copy()
                    var emsg = emsg2 + "' in vhost '/'"
                    return self._channel_error(
                        chan,
                        REPLY_NOT_FOUND(),
                        emsg^,
                        mid,
                    )
                var at = self._broker.exchange_type_of(ex_name.copy())
                if at != ex_type:
                    self._mark_channel_closed(conn_id, chan)
                    var m1 = "PRECONDITION_FAILED - inequivalent arg 'type' for exchange '"
                    var m2 = m1 + ex_name.copy()
                    var m3 = m2 + "' in vhost '/'"
                    return self._channel_error(
                        chan,
                        REPLY_PRECONDITION_FAILED(),
                        m3^,
                        mid,
                    )
                # passive declare-ok: no mutation of the exchange.
            else:
                var created = True
                if len(ex_name.bytes()) != 0:
                    created = self._broker.declare_exchange(
                        ex_name.copy(), ex_type.copy()
                    )
                if not created:
                    var at = self._broker.exchange_type_of(ex_name.copy())
                    if at != ex_type:
                        self._mark_channel_closed(conn_id, chan)
                        var m1 = "PRECONDITION_FAILED - inequivalent arg 'type' for exchange '"
                        var m2 = m1 + ex_name.copy()
                        var m3 = m2 + "' in vhost '/'"
                        return self._channel_error(
                            chan,
                            REPLY_PRECONDITION_FAILED(),
                            m3^,
                            mid,
                        )
                # durable-flag + auto-delete metadata recorded (created OR
                # refreshed; declare equivalence is verified above). Insert
                # via pop-then-reinsert (Mojo dict-of-struct pattern).
                var had_em = ex_name.copy() in self._exchange_meta
                if had_em:
                    _ = self._exchange_meta.pop(ex_name.copy())
                self._exchange_meta[ex_name.copy()] = _ExchangeMeta(
                    e_durable, e_auto, _now_ms()
                )
                if not had_em:
                    self._exchange_meta_keys.append(ex_name.copy())
                if e_durable:
                    print(
                        "hyrxmq: exchange '"
                        + ex_name.copy()
                        + "' durable=1 (FLAG ONLY, in-memory; 0018 storage)"
                    )
            if e_no_wait:
                return Optional[List[UInt8]]()
            return self._reply(
                chan,
                EXCHANGE_DECLARE_OK().class_id,
                EXCHANGE_DECLARE_OK().method_id,
                List[UInt8](),
            )

        # ---- queue declare ----
        # queue.declare (50,10). Bits: passive(1) durable(2) exclusive(4)
        # auto-delete(8) no-wait(16); trailing `arguments` field table —
        # 0017 T3: DECODED and honored (read_table_skip dropped):
        #   x-message-ttl (I): per-message DELIVERY-TIME expiry (ms;
        #     dead-letter FIRST when the queue carries
        #     x-dead-letter-exchange, else drop).
        #   x-expires (I): LAZY queue deletion — last-activity window
        #     evaluated on next get/declare/consume (no timer subsystem:
        #     PARTIAL per receipt).
        #   x-max-length (I): cap; overflow drop-oldest (AMQP default) or
        #     reject-publish (capacity refusal).
        #   x-dead-letter-exchange (S) + x-dead-letter-routing-key (S):
        #     basic.reject/nack requeue=false messages and TTL-expired
        #     messages route into the DLX via the Router.
        #   Declare-flag semantics:
        #     passive=1: EXISTS → declare-ok with the REAL counts
        #       (message_count, consumer_count) and NO mutation; MISSING →
        #       the normative channel.close (reply-code=404, reply-text=
        #       "NOT_FOUND - no queue '<name>' in vhost '/'", failing
        #       cls/mid = (50,10)).
        #     durable: FLAG ONLY (in-memory; NO disk persistence claimed;
        #       milestone 0018 owns real storage).
        #     exclusive: CLIENT-connection-owned — declare from ANOTHER
        #       connection → 405 RESOURCE_LOCKED channel.close; the queue
        #       auto-deletes on the owning connection's close; other
        #       connections' consume/get denied 405.
        #     auto_delete: delete when the LAST consumer leaves (basic.cancel
        #       + connection-close paths).
        #   The declare-ok wire shape is EXACT (queue shortstr +
        #   message_count long + consumer_count long — nothing more).
        if mid == QUEUE_DECLARE():
            _ = reader.read_short()  # reserved-1 (deprecated "ticket", must be 0)
            var q_name = reader.read_short_string()
            var q_bits = reader.read_octet()
            var q_args = reader.read_table()
            var q_passive = (q_bits & QUEUE_DECLARE_BIT_PASSIVE()) != 0
            var q_durable = (q_bits & QUEUE_DECLARE_BIT_DURABLE()) != 0
            var q_excl = (q_bits & QUEUE_DECLARE_BIT_EXCLUSIVE()) != 0
            var q_auto = (q_bits & QUEUE_DECLARE_BIT_AUTO_DELETE()) != 0
            var q_no_wait = (q_bits & QUEUE_DECLARE_BIT_NO_WAIT()) != 0
            # LAZY x-expires evaluation (get/declare/consume trigger points).
            _ = self._queue_check_expires(q_name.copy())
            var q_exists = self._broker.has_queue(q_name.copy())
            if q_passive:
                if not q_exists:
                    self._mark_channel_closed(conn_id, chan)
                    var emsg1 = "NOT_FOUND - no queue '"
                    var emsg2 = emsg1 + q_name.copy()
                    var emsg = emsg2 + "' in vhost '/'"
                    return self._channel_error(
                        chan,
                        REPLY_NOT_FOUND(),
                        emsg^,
                        mid,
                    )
                # passive declare-ok with the REAL counts; NO mutation.
                var mdepth = self._broker.queue_depth(q_name.copy())
                var ccount = self._broker.queue_consumer_count(q_name.copy())
                if (q_bits & QUEUE_DECLARE_BIT_NO_WAIT()) != 0:
                    return Optional[List[UInt8]]()
                return self._reply_queue_declare_ok(
                    chan, q_name^, mdepth, ccount
                )
            if q_exists:
                # Equivalence + exclusive-ownership table (50,10/60,20 reply
                # codes per amqp0-9-1.xml normative error table). Reads are
                # chained primitive reads (NO struct copy); the refresh is
                # pop-then-reinsert.
                var has_meta = q_name.copy() in self._queue_meta
                var e_owner = UInt64(0)
                var e_durable_flag = False
                var e_auto_flag = False
                if has_meta:
                    e_owner = self._queue_meta[q_name.copy()].owner
                    e_durable_flag = self._queue_meta[q_name.copy()].durable
                    e_auto_flag = self._queue_meta[q_name.copy()].auto_delete
                    if e_owner != 0 and e_owner != conn_id:
                        self._mark_channel_closed(conn_id, chan)
                        var lmsg1 = "RESOURCE_LOCKED - cannot obtain exclusive access to locked queue '"
                        var lmsg2 = lmsg1 + q_name.copy()
                        var lmsg = lmsg2 + "' in vhost '/'. It could be originally declared on another connection."
                        return self._channel_error(
                            chan,
                            REPLY_RESOURCE_LOCKED(),
                            lmsg^,
                            mid,
                        )
                    if e_durable_flag != q_durable:
                        self._mark_channel_closed(conn_id, chan)
                        var fmsg1 = "PRECONDITION_FAILED - inequivalent arg 'durable' for queue '"
                        var fmsg2 = fmsg1 + q_name.copy()
                        var fmsg3 = fmsg2 + "' in vhost '/'"
                        return self._channel_error(
                            chan,
                            REPLY_PRECONDITION_FAILED(),
                            fmsg3^,
                            mid,
                        )
                    if e_auto_flag != q_auto:
                        self._mark_channel_closed(conn_id, chan)
                        var fmsg1 = "PRECONDITION_FAILED - inequivalent arg 'auto_delete' for queue '"
                        var fmsg2 = fmsg1 + q_name.copy()
                        var fmsg3 = fmsg2 + "' in vhost '/'"
                        return self._channel_error(
                            chan,
                            REPLY_PRECONDITION_FAILED(),
                            fmsg3^,
                            mid,
                        )
                    # matching redeclare: flags stay; LAZY-touch ONLY.
                    _ = self._queue_meta[q_name.copy()].touch(_now_ms())
                var mdepth = self._broker.queue_depth(q_name.copy())
                var ccount = self._broker.queue_consumer_count(q_name.copy())
                if (q_bits & QUEUE_DECLARE_BIT_NO_WAIT()) != 0:
                    return Optional[List[UInt8]]()
                return self._reply_queue_declare_ok(
                    chan, q_name^, mdepth, ccount
                )
            # NEW queue: parse the declare arguments NOW (single decode).
            var ttl_ms = 0
            var expires_ms = 0
            var max_len = 0
            var overflow_reject = False
            var dlx_name = String("")
            var dlrk_name = String("")
            if q_args.type_of("x-message-ttl") == FT_TYPE_INT():
                var v = q_args.get_int("x-message-ttl")
                if v.__bool__():
                    ttl_ms = v.value()
            # actually guard raises: get_int's Optional
            if q_args.type_of("x-expires") == FT_TYPE_INT():
                var v = q_args.get_int("x-expires")
                if v.__bool__():
                    expires_ms = v.value()
            if q_args.type_of("x-max-length") == FT_TYPE_INT():
                var v = q_args.get_int("x-max-length")
                if v.__bool__():
                    max_len = v.value()
            if q_args.type_of("x-dead-letter-exchange") == FT_TYPE_STRING():
                var v = q_args.get_string("x-dead-letter-exchange")
                if v.__bool__():
                    dlx_name = v.value()
            if q_args.type_of("x-dead-letter-routing-key") == FT_TYPE_STRING():
                var v = q_args.get_string("x-dead-letter-routing-key")
                if v.__bool__():
                    dlrk_name = v.value()
            var ov = q_args.get_string("x-overflow")
            if ov.__bool__():
                if ov.value() == "reject-publish":
                    overflow_reject = True
            _ = self._broker.declare_queue_full(
                q_name.copy(), q_durable, ttl_ms, expires_ms,
                max_len, overflow_reject, dlx_name.copy(), dlrk_name.copy(),
            )
            self._queue_meta[q_name.copy()] = _QueueMeta(
                q_durable, q_excl, q_auto, conn_id if q_excl else UInt64(0),
                expires_ms, _now_ms(),
            )
            if len(self._queue_meta_keys) == 0:
                self._queue_meta_keys.append(q_name.copy())
            else:
                var found_meta_key = False
                for i in range(len(self._queue_meta_keys)):
                    if self._queue_meta_keys[i] == q_name:
                        found_meta_key = True
                        break
                if not found_meta_key:
                    self._queue_meta_keys.append(q_name.copy())
            if q_durable:
                print(
                    "hyrxmq: queue '"
                    + q_name.copy()
                    + "' durable=1 (FLAG ONLY, in-memory; 0018 storage)"
                )
            if (q_bits & QUEUE_DECLARE_BIT_NO_WAIT()) != 0:
                return Optional[List[UInt8]]()
            var mdepth = self._broker.queue_depth(q_name.copy())
            var ccount = self._broker.queue_consumer_count(q_name.copy())
            return self._reply_queue_declare_ok(chan, q_name^, mdepth, ccount)

        # ---- queue bind ----
        if mid == QUEUE_BIND():
            _ = reader.read_short()  # reserved-1
            var bq = reader.read_short_string()
            var be = reader.read_short_string()
            var brk = reader.read_short_string()
            _ = self._broker.bind_queue(bq^, be^, brk^, HeaderArgs())
            return self._reply(
                chan,
                QUEUE_BIND_OK().class_id,
                QUEUE_BIND_OK().method_id,
                List[UInt8](),
            )

        # ---- 0017 T4: confirm.select (85,10) — RabbitMQ extension ----
        # Spec args (extension): nowait (bit). Arms confirm mode on the
        # channel: every subsequent completed basic.publish is acknowledged
        # with basic.ack (60,80) carrying a 1-based per-channel confirm
        # ack-id, multiple=0, AFTER the route (see _execute_publish).
        if mid == CONFIRM_SELECT():
            var csbits = reader.read_octet()
            self._confirm_enable(conn_id, chan)
            if (csbits & CONFIRM_SELECT_BIT_NO_WAIT()) != 0:
                return Optional[List[UInt8]]()
            return self._reply(
                chan,
                CONFIRM_SELECT_OK().class_id,
                CONFIRM_SELECT_OK().method_id,
                List[UInt8](),
            )

        # ---- 0017 T4: tx.select (90,10) — per-channel tx mode ----
        # Spec args: NONE. Publishes on this channel are STAGED from now on
        # (never pushed to the router immediately); commit/rollback below.
        # Idempotent per channel (rabbit parity).
        if mid == TX_SELECT():
            self._tx_enable(conn_id, chan)
            return self._reply(
                chan,
                TX_SELECT_OK().class_id,
                TX_SELECT_OK().method_id,
                List[UInt8](),
            )

        # ---- 0017 T4: tx.commit (90,20) — push the staging into the router ----
        # Every staged publish is executed NOW, exactly as an immediate
        # publish would have been (route, unknown-exchange 404, mandatory
        # basic.return FIRST then the confirm ack) in publish order; the
        # commit-ok (90,21) reply is appended LAST. A channel-error close
        # (404 impossible exchange) aborts the replay (channel dead).
        if mid == TX_COMMIT():
            var cstaged = self._tx_take(conn_id, chan)
            var out = List[UInt8]()
            # Replay in publish order (pop-front; owned moves, no copies).
            while len(cstaged) > 0:
                var s = cstaged.pop(0)
                var ok = self._execute_publish(
                    conn_id,
                    chan,
                    s.exchange.copy(),
                    s.routing_key.copy(),
                    s.mandatory,
                    s.prop_flags,
                    s.body.copy(),
                    s.props.copy(),
                    out,
                )
                if not ok:
                    return Optional[List[UInt8]](out^)
            var cokf = AMQPFrameCodec.encode_method_frame(
                chan,
                TX_COMMIT_OK().class_id,
                TX_COMMIT_OK().method_id,
                List[UInt8](),
            )
            _concat(out, cokf^)
            return Optional[List[UInt8]](out^)

        # ---- 0017 T4: tx.rollback (90,30) — DROP the staging ----
        if mid == TX_ROLLBACK():
            _ = self._tx_take(conn_id, chan)
            return self._reply(
                chan,
                TX_ROLLBACK_OK().class_id,
                TX_ROLLBACK_OK().method_id,
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

        # ---- basic cancel (60,30): answer cancel-ok; 0017 T3: the engine
        # consumer IS unregistered now (needed for the auto-delete
        # last-consumer-gone semantics; the OLD slice kept it live).
        if mid == BASIC_CANCEL():
            var xtag = reader.read_short_string()
            _ = reader.read_octet()  # bits: no-wait (always answered here)
            var xargs = List[UInt8]()
            write_short_string(xargs, xtag.copy())
            var xcid = self._take_consumer_by_ctag(xtag.copy())
            if xcid != 0:
                _ = self._broker.unregister_consumer(xcid)
                if conn_id in self._consumers and self._consumers[conn_id] == xcid:
                    _ = self._consumers.pop(conn_id)
                if xcid in self._ctags:
                    _ = self._ctags.pop(xcid)
                if xcid in self._cids:
                    var xq = self._cids.pop(xcid)
                    # auto_delete: last consumer gone → queue deleted.
                    self._maybe_auto_delete_queue(xq^)
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
            var cargs_ft = reader.read_table()
            _ = cargs_ft  # decoded; consumer-side x-args have no queue-class semantics here
            # 0017 T3: consume preflight (missing → 404 close; exclusive
            # owned by ANOTHER connection → 405 close; lazy x-expires).
            var cfail = self._queue_access_error(conn_id, chan, cq.copy(), mid)
            if len(cfail) > 0:
                return Optional[List[UInt8]](cfail^)
            var cid = self._broker.consume_register(cq.copy())
            # Slice limitation: one consumer per connection (last consume wins).
            self._consumers[conn_id] = cid
            # The client's consumer-tag is echoed (a real client routes inbound
            # deliveries by this string); an empty tag gets a server-generated
            # one, as the spec requires.
            var tag_out = ctag
            if len(tag_out.bytes()) == 0:
                tag_out = "hyrxmq-ctag-" + String(cid)
            self._ctags[cid] = tag_out.copy()
            self._register_consumer_tracking(cid, cq.copy(), tag_out.copy())
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
        # 0017 T3: requeue=false now DEAD-LETTERS through the queue's
        # x-dead-letter-exchange (Router.nack requeue=False; with no DLX the
        # message is dropped — the normative T1 visible behavior). requeue=1
        # stays the engine reject (requeue) path.
        if mid == BASIC_REJECT():
            var rtag = reader.read_long_long()
            var rbits = reader.read_octet()
            var r_requeue = (rbits & 1) != 0
            # 0017 T2: resolve through the per-channel tag map first.
            var rentry = self._chan_take(conn_id, chan, rtag)
            if rentry.__bool__():
                var r_cid = rentry.value().consumer_id
                var r_tag = rentry.value().engine_tag
                if r_requeue:
                    _ = self._broker.reject(r_cid, r_tag)
                else:
                    _ = self._broker.nack(r_cid, r_tag, False)
            elif conn_id in self._consumers:
                if r_requeue:
                    _ = self._broker.reject(self._consumers[conn_id], rtag)
                else:
                    _ = self._broker.nack(self._consumers[conn_id], rtag, False)
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
            # 0017 T3: exchange auto-delete (delete on the LAST unbind).
            self._maybe_auto_delete_exchange(ue.copy())
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
            # 0017 T3: exchange auto-delete (delete on the LAST unbind).
            self._maybe_auto_delete_exchange(xsrc.copy())
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
# client's own flow-ok — the server must only RESUME/PAUSE] and secure
# (10,20/21); unhandled synchronous methods still get no reply (peers
# would block). confirm.* and tx.* are IMPLEMENTED (0017 T4, see the
# module header).
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
        # 0017 T4: drop the connection's confirm + tx namespaces and the
        # negotiated-heartbeat record (same key-walk pattern).
        var i5 = 0
        while i5 < len(self._confirm_keys):
            var ckey = self._confirm_keys[i5]
            if ckey // 65536 == conn_id:
                if ckey in self._confirms:
                    _ = self._confirms.pop(ckey)
                _ = self._confirm_keys.pop(i5)
            else:
                i5 += 1
        var i6 = 0
        while i6 < len(self._tx_keys):
            var tkey = self._tx_keys[i6]
            if tkey // 65536 == conn_id:
                if tkey in self._tx:
                    _ = self._tx.pop(tkey)
                _ = self._tx_keys.pop(i6)
            else:
                i6 += 1
        if conn_id in self._heartbeat_negotiated:
            _ = self._heartbeat_negotiated.pop(conn_id)
        if conn_id in self._closed_channels:
            _ = self._closed_channels.pop(conn_id)
        # 0017 T3: exclusive CLIENT-connection-owned queues die with their
        # connection (one-connection lifetime): delete + drop metadata.
        var i2 = 0
        while i2 < len(self._queue_meta_keys):
            var qn = self._queue_meta_keys[i2]
            if qn.copy() in self._queue_meta:
                var m_excl = self._queue_meta[qn.copy()].exclusive
                var m_owner = self._queue_meta[qn.copy()].owner
                if m_excl and m_owner == conn_id:
                    _ = self._broker.delete_queue_checked(qn.copy(), False, False)
                    _ = self._queue_meta.pop(qn.copy())
                    _ = self._queue_meta_keys.pop(i2)
                    print("hyrxmq: exclusive queue '" + qn.copy() + "' deleted (owning connection closed)")
                else:
                    i2 += 1
            else:
                _ = self._queue_meta_keys.pop(i2)
        # The connection's consumers are gone; auto_delete queues with NO
        # remaining consumer delete too (auto_delete last-consumer semantics).
        i2 = 0
        while i2 < len(self._queue_meta_keys):
            var qn = self._queue_meta_keys[i2]
            _ = self._maybe_auto_delete_queue(qn.copy())
            if qn.copy() not in self._queue_meta:
                i2 = 0
                continue
            i2 += 1
        # Any ctag→cid entries pointing at dead consumers are unreachable:
        # the connection's consumer ids died with _consumers/_ctrack. The
        # dicts are per-connection-clean only by cid; stale ctag→cid entries
        # resolve to dead ids and are re-popped on the next cancel attempt
        # (bounded by one entry per consumer).

    # ---- 0017 T3: lazy x-expires + declare-flag metadata upkeep ----

    def _queue_check_expires(mut self, var q: String) raises -> Bool:
        """LAZY x-expires evaluation: delete the queue when it stayed
        untouched past its x-expires window.

        No timer subsystem exists (the receipt's honest PARTIAL): the check
        fires only when the queue is NEXT TOUCHED (declare with arguments
        semantics, basic.get, basic.consume). Returns True when the queue
        was JUST deleted (the caller proceeds as if it were missing)."""
        if q.copy() in self._queue_meta:
            var m_expires = self._queue_meta[q.copy()].expires_ms
            var m_last = self._queue_meta[q.copy()].last_ms
            if m_expires > 0 and (_now_ms() - m_last) > m_expires:
                _ = self._broker.delete_queue_checked(q.copy(), False, False)
                _ = self._queue_meta.pop(q.copy())
                var i = 0
                while i < len(self._queue_meta_keys):
                    if self._queue_meta_keys[i] == q:
                        _ = self._queue_meta_keys.pop(i)
                        break
                    i += 1
                print("hyrxmq: queue '" + q.copy() + "' expired (x-expires, lazy check)")
                return True
        return False

    def _queue_touch(mut self, var q: String) raises:
        """Record one live queue access (declare / get / consume start).

        Chained mutator call (NO struct copy out of the Dict)."""
        if q.copy() in self._queue_meta:
            _ = self._queue_meta[q.copy()].touch(_now_ms())

    # ---- 0017 T3: exclusive-ownership + auto-delete bookkeeping ----

    def _queue_access_error(
        mut self,
        conn_id: UInt64,
        chan: UInt16,
        var queue: String,
        failing: MethodID,
    ) raises -> List[UInt8]:
        """Preflight for basic.consume / basic.get on one queue.

        Returns the ERROR BYTES (a channel 404/405 close frame) when the
        access is DENIED; an EMPTY list = allowed: missing queue → 404
        NOT_FOUND channel.close; exclusive queue owned by ANOTHER connection
        → 405 RESOURCE_LOCKED. Otherwise the LAZY x-expires reaping runs
        and the access counts (last-activity basis)."""
        _ = self._queue_check_expires(queue.copy())
        if not self._broker.has_queue(queue.copy()):
            self._mark_channel_closed(conn_id, chan)
            var msg1 = "NOT_FOUND - no queue '"
            var msg2 = msg1 + queue.copy()
            var msg3 = msg2 + "' in vhost '/'"
            var err = self._channel_error(chan, REPLY_NOT_FOUND(), msg3^, failing)
            if err.__bool__():
                return err.value().copy()
            return List[UInt8]()
        if queue.copy() in self._queue_meta:
            var m_owner = self._queue_meta[queue.copy()].owner
            if m_owner != 0 and m_owner != conn_id:
                self._mark_channel_closed(conn_id, chan)
                var msg1 = "RESOURCE_LOCKED - cannot obtain exclusive access to locked queue '"
                var msg2 = msg1 + queue.copy()
                var msg3 = msg2 + "' in vhost '/'. It could be originally declared on another connection."
                var err = self._channel_error(chan, REPLY_RESOURCE_LOCKED(), msg3^, failing)
                if err.__bool__():
                    return err.value().copy()
        self._queue_touch(queue.copy())
        return List[UInt8]()

    # ---- 0017 T3: exchange auto-delete bookkeeping ----

    def _maybe_auto_delete_exchange(mut self, var name: String) raises:
        """auto_delete exchange semantic: when the LAST binding leaves
        (queue.unbind / exchange.unbind paths), the exchange goes away."""
        if name.copy() not in self._exchange_meta:
            return
        var m_auto = self._exchange_meta[name.copy()].auto_delete
        if not m_auto:
            return
        var total = self._broker.exchange_binding_total(name.copy())
        if total == 0:
            _ = self._broker.delete_exchange_checked(name.copy(), False)
            _ = self._exchange_meta.pop(name.copy())
            var i = 0
            while i < len(self._exchange_meta_keys):
                if self._exchange_meta_keys[i] == name:
                    _ = self._exchange_meta_keys.pop(i)
                    break
                i += 1
            print("hyrxmq: exchange '" + name.copy() + "' auto-deleted (last binding gone)")

    def _maybe_auto_delete_queue(mut self, var q: String) raises:
        """auto_delete=8 semantic: when the LAST consumer leaves, the queue
        goes away (basic.cancel path + connection-close cleanup)."""
        if q.copy() not in self._queue_meta:
            return
        var m_auto = self._queue_meta[q.copy()].auto_delete
        if not m_auto:
            return
        if self._broker.queue_consumer_count(q.copy()) == 0:
            _ = self._broker.delete_queue_checked(q.copy(), False, False)
            _ = self._queue_meta.pop(q.copy())
            var i = 0
            while i < len(self._queue_meta_keys):
                if self._queue_meta_keys[i] == q:
                    _ = self._queue_meta_keys.pop(i)
                    break
                i += 1
            print("hyrxmq: queue '" + q.copy() + "' auto-deleted (last consumer gone)")

    # ---- 0017 T3: ctag → consumer resolution (basic.cancel) ----

    def _register_consumer_tracking(
        mut self, cid: UInt64, var queue: String, var ctag: String
    ) raises:
        """Track one registered consumer: cid→queue + ctag→cid reverse."""
        self._cids[cid] = queue^
        if len(ctag.bytes()) != 0:
            self._cid_by_ctag[ctag^] = cid

    def _take_consumer_by_ctag(mut self, var ctag: String) raises -> UInt64:
        """basic.cancel: resolve + forget the engine consumer id a client
        consumer-tag addresses (0 = unknown tag)."""
        if ctag in self._cid_by_ctag:
            var cid = self._cid_by_ctag.pop(ctag.copy())
            return cid
        return UInt64(0)

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

    # ---- 0017 T4: the ONE publish execution point ----

    def _execute_publish(
        mut self,
        conn_id: UInt64,
        chan: UInt16,
        var exchange: String,
        var routing_key: String,
        mandatory: Int,
        prop_flags: UInt16,
        var body: List[UInt8],
        var props: List[UInt8],
        mut out: List[UInt8],
    ) raises -> Bool:
        """Execute ONE publish (immediate or replayed-from-tx) and append the
        response bytes for it onto `out`.

        0017 T4 shared by the immediate path (_publish_pending) and the
        tx.commit replay — the SINGLE point that:
          1. rejects an unknown exchange with the normative channel.close 404
             (immediate semantics kept: the exchange check happens at publish
             time, ALSO in tx mode — rabbit parity),
          2. routes the message (default exchange → direct queue by routing
             key; otherwise through the exchange),
          3. composes basic.return (60,50) 312 FIRST for a mandatory=1
             unroutable publish (echoing the publisher's own stored header),
          4. THEN issues the publisher-confirm ack (basic.ack 60,80,
             delivery-tag = 1-based per-channel confirm counter, multiple=0)
             AFTER the route — the router's publish returned — including for
             a fan-out to ZERO queues (empty fanout = handled → still acked)
             and after the basic.return of a mandatory unroutable publish
             (rabbit wire ordering). No broker-internal confirm timeout.
        Returns False when the channel was error-closed (404).
        """
        if len(exchange.bytes()) != 0 and not self._broker.has_exchange(exchange.copy()):
            self._mark_channel_closed(conn_id, chan)
            var emsg = "NOT_FOUND - no exchange '" + exchange.copy() + "' in vhost '/'"
            var err = self._channel_error(
                chan,
                REPLY_NOT_FOUND(),
                emsg^,
                BASIC_PUBLISH(),
            )
            if err.__bool__():
                _concat(out, err.value().copy())
            return False
        var routed = 0
        # The DEFAULT exchange ("") publishes DIRECT into the queue named by
        # the routing key (the exchange's normative pre-bound direct binding).
        if len(exchange.bytes()) == 0:
            routed = self._broker.publish_to_queue_with_props(
                routing_key.copy(), body.copy(),
                prop_flags, props.copy(),
            )
        else:
            routed = self._broker.publish_with_props(
                exchange.copy(), routing_key.copy(), body.copy(),
                prop_flags, props.copy(),
            )
        if mandatory == 1 and routed <= 0:
            # basic.return (60,50) args: reply-code(short)=312 + reply-text
            # (shortstr)="NO_ROUTE" + exchange(shortstr) + routing-key
            # (shortstr) — followed by the message content (HEADER+BODY).
            # The content echoes the publisher's OWN stored header (flag
            # word + raw slice) byte-identically.
            var rargs = List[UInt8]()
            write_u16(rargs, REPLY_NO_ROUTE())
            write_short_string(rargs, "NO_ROUTE")
            write_short_string(rargs, exchange.copy())
            write_short_string(rargs, routing_key.copy())
            var retf = emit_message_frames(
                chan, BASIC_RETURN(), rargs^, body.copy(), self._frame_max,
                prop_flags, props.copy(),
            )
            _concat(out, retf^)
        # Publisher-confirm ack (0017 T4): AFTER the route (routed >= 0 = the
        # router accepted the publish; empty fanout still acks). The ack-id
        # counter is per channel and 1-based.
        var ctag = self._confirm_next_tag(conn_id, chan)
        if ctag.__bool__():
            var cargs = List[UInt8]()
            write_u64(cargs, ctag.value())
            cargs.append(0)  # multiple=0: single-tag ack per publish
            var ackf = AMQPFrameCodec.encode_method_frame(
                chan,
                BASIC_ACK().class_id,
                BASIC_ACK().method_id,
                cargs^,
            )
            _concat(out, ackf^)
        return True

    def _publish_pending(mut self, conn_id: UInt64) raises -> Optional[List[UInt8]]:
        """Hand the fully reassembled body to the broker (the single publish
        point for inbound content) and clear the per-connection state.

        0017 T4: in tx mode the completed publish is STAGED instead (its
        execution happens at tx.commit through the same _execute_publish
        path); otherwise the publish runs IMMEDIATELY through
        _execute_publish (unknown-exchange 404, route, mandatory
        basic.return FIRST then the confirm ack).
        """
        if conn_id not in self._pending or conn_id not in self._pending_bodies:
            return Optional[List[UInt8]]()
        var p = self._pending.pop(conn_id)
        var body = self._pending_bodies.pop(conn_id)
        # 0017 T2: the raw property-list slice rides beside the flag word.
        var props = List[UInt8]()
        if conn_id in self._pending_prop_bytes:
            props = self._pending_prop_bytes.pop(conn_id)
        # 0017 T4 tx mode: STAGE (deferred until tx.commit; the exchange
        # existence check stays IMMEDIATE even in tx mode — rabbit checks
        # the exchange at publish time, not at commit; only a real (or the
        # default) exchange is allowed to stage).
        if self._tx_active(conn_id, p.channel):
            if len(p.exchange.bytes()) != 0 and not self._broker.has_exchange(p.exchange.copy()):
                self._mark_channel_closed(conn_id, p.channel)
                var temsg = "NOT_FOUND - no exchange '" + p.exchange.copy() + "' in vhost '/'"
                return self._channel_error(
                    p.channel,
                    REPLY_NOT_FOUND(),
                    temsg^,
                    BASIC_PUBLISH(),
                )
            self._tx_stage(
                conn_id,
                p.channel,
                _TxStaged(
                    p.exchange.copy(), p.routing_key.copy(), p.mandatory,
                    p.prop_flags, body.copy(), props.copy(),
                ),
            )
            return Optional[List[UInt8]]()
        var out = List[UInt8]()
        _ = self._execute_publish(
            conn_id,
            p.channel,
            p.exchange.copy(),
            p.routing_key.copy(),
            p.mandatory,
            p.prop_flags,
            body.copy(),
            props.copy(),
            out,
        )
        if len(out) == 0:
            return Optional[List[UInt8]]()
        return Optional[List[UInt8]](out^)

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
        # 0017 T3: get preflight (missing→404 close; exclusive other-conn
        # →405 close; lazy x-expires + last-activity).
        var gerr = self._queue_access_error(conn_id, chan, queue.copy(), BASIC_GET())
        if len(gerr) > 0:
            return Optional[List[UInt8]](gerr^)
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
        ref self, chan: UInt16, var q_name: String, mcount: Int, ccount: Int
    ) -> Optional[List[UInt8]]:
        # declare-ok: queue short-string + message-count long + consumer-count
        # long (EXACT shape; message_count = REAL ready depth, consumer_count
        # = REAL live consumer count — 0017 T3).
        var args = List[UInt8]()
        write_short_string(args, q_name^)
        write_u32(args, UInt32(mcount))
        write_u32(args, UInt32(ccount))
        return self._reply(
            chan,
            QUEUE_DECLARE_OK().class_id,
            QUEUE_DECLARE_OK().method_id,
            args^,
        )

    # ---- 0017 T4 observability (tests / fail-closed audits) ----

    def confirms_enabled(mut self, conn_id: UInt64, chan: UInt16) raises -> Bool:
        """Whether the channel is in publisher-confirm mode (85)."""
        return _chan_key(conn_id, chan) in self._confirms

    def tx_mode_enabled(mut self, conn_id: UInt64, chan: UInt16) raises -> Bool:
        """Whether the channel is in tx mode (90)."""
        return self._tx_active(conn_id, chan)

    def tx_staged_count(mut self, conn_id: UInt64, chan: UInt16) raises -> Int:
        """Messages currently STAGED on a tx-mode channel."""
        var key = _chan_key(conn_id, chan)
        if key not in self._tx:
            return 0
        return len(self._tx[key])

    def advertised_heartbeat(ref self) -> Int:
        """The heartbeat value the tune frame advertises."""
        return self._heartbeat_secs

    def negotiated_heartbeat(mut self, conn_id: UInt64) raises -> Int:
        """min(advertised, the client's tune-ok heartbeat); 0 = none."""
        if conn_id not in self._heartbeat_negotiated:
            return 0
        return Int(self._heartbeat_negotiated[conn_id])
