# HyrxMQ AMQP service (Phase 7).
#
# Bridges AMQP frames to the broker. This module performs NO socket I/O: it
# takes an already-decoded AMQPFrame and returns already-encoded response
# bytes, so the whole protocol path is unit-testable feed-bytes/get-bytes.
#
# The real network acceptance path is PROVEN: the flare-backed transport
# contract (src/hyrx/transport/tcp.mojo) drives this service through
# src/hyrxmq/listener.mojo; see tests/integration/broker_tcp_e2e.mojo.
#
# Vertical-slice simplification: basic.publish carries its body inline in the
# method arguments (after the short-string fields). Real AMQP 0-9-1 splits
# content into separate header/body frames; that multi-frame reassembly is out
# of scope for the Phase 7 slice. This is a documented representation choice,
# not a change to publish/consume/ack semantics. Likewise, pending messages
# are flushed as basic.deliver frames appended to the basic.consume reply
# (pull-on-subscribe) instead of pushed asynchronously at publish time.

from std.collections import Dict, List, Optional

from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec
from hyrx.amqp.constants import (
    FRAME_METHOD,
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
    BASIC_PUBLISH,
    BASIC_CONSUME,
    BASIC_CONSUME_OK,
    BASIC_ACK,
    BASIC_DELIVER,
    MethodID,
)
from hyrx.amqp.connection_state import AMQPConnectionState, CONN_STATE_OPEN

from hyrx.core.queue import Delivery
from hyrxmq.broker import HyrxMQBroker
from hyrxmq.config import HyrxMQConfig
from hyrxmq.status import BrokerStatus


# Upper bound on deliveries flushed by one basic.consume reply.
def _CONSUME_FLUSH_MAX() -> Int:
    return 128


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


def write_short_string(mut out: List[UInt8], var s: String):
    """Append an AMQP short-string (1-byte length + bytes) to `out`."""
    var b = s.as_bytes()
    out.append(UInt8(len(b)))
    for i in range(len(b)):
        out.append(b[i])


def write_long_str_empty(mut out: List[UInt8]):
    """Append an empty AMQP long-string (4-byte length = 0)."""
    write_u32(out, 0)


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

    def read_remaining(mut self) -> List[UInt8]:
        var out = List[UInt8]()
        while self.pos < len(self.data):
            out.append(self.data[self.pos])
            self.pos += 1
        return out^


struct AMQPService:
    """Frame-level dispatch into the HyrxMQ broker (no sockets)."""

    var _broker: HyrxMQBroker
    var _conns: Dict[UInt64, AMQPConnectionState]
    var _consumers: Dict[UInt64, UInt64]

    def __init__(out self, var config: HyrxMQConfig):
        self._broker = HyrxMQBroker(config^)
        self._conns = Dict[UInt64, AMQPConnectionState]()
        self._consumers = Dict[UInt64, UInt64]()

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

    # ---- frame handling ----

    def handle_frame(
        mut self, conn_id: UInt64, frame: AMQPFrame
    ) raises -> Optional[List[UInt8]]:
        """Decode a method frame, dispatch to the broker, encode a reply.

        The frame is taken read-only (plain arg): this handler only reads the
        payload, so the network path can pass `optional.value()` without a
        copy or move.

        Returns response bytes for methods with a synchronous *_ok reply;
        returns None for fire-and-forget methods (publish/ack) and non-method
        frames.
        """
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

        # ---- connection ----
        if mid == CONNECTION_OPEN():
            if conn_id not in self._conns:
                self._conns[conn_id] = AMQPConnectionState()
            self._conns[conn_id].set_state(CONN_STATE_OPEN())
            return self._reply_open(chan)
        if mid == CONNECTION_TUNE_OK():
            return Optional[List[UInt8]]()

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
            _ = reader.read_short()  # reserved-1
            var ex_name = reader.read_short_string()
            var ex_type = reader.read_short_string()
            _ = self._broker.declare_exchange(ex_name^, ex_type^)
            return self._reply(
                chan,
                EXCHANGE_DECLARE_OK().class_id,
                EXCHANGE_DECLARE_OK().method_id,
                List[UInt8](),
            )

        # ---- queue declare ----
        if mid == QUEUE_DECLARE():
            _ = reader.read_short()  # reserved-1
            var q_name = reader.read_short_string()
            _ = self._broker.declare_queue(q_name)
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

        # ---- basic publish (inline body after routing key) ----
        if mid == BASIC_PUBLISH():
            _ = reader.read_short()  # reserved-1
            var pex = reader.read_short_string()
            var prk = reader.read_short_string()
            var pbody = reader.read_remaining()
            _ = self._broker.publish(pex^, prk^, pbody^)
            return Optional[List[UInt8]]()

        # ---- basic consume ----
        if mid == BASIC_CONSUME():
            var cq = reader.read_short_string()
            var cid = self._broker.consume_register(cq^)
            self._consumers[conn_id] = cid
            var cargs = List[UInt8]()
            write_short_string(cargs, String(cid))
            var reply = AMQPFrameCodec.encode_method_frame(
                chan,
                BASIC_CONSUME_OK().class_id,
                BASIC_CONSUME_OK().method_id,
                cargs^,
            )
            reply = self._flush_deliveries(chan, cid, reply^)
            return Optional[List[UInt8]](reply^)

        # ---- basic ack ----
        if mid == BASIC_ACK():
            var tag = reader.read_long_long()
            var ack_cid = UInt64(reader.read_octet())
            _ = self._broker.ack(ack_cid, tag)
            return Optional[List[UInt8]]()

        # ---- unhandled method: no reply ----
        return Optional[List[UInt8]]()

    # ---- reply encoders ----

    def _flush_deliveries(
        mut self, chan: UInt16, cid: UInt64, var dst: List[UInt8]
    ) raises -> List[UInt8]:
        """Append basic.deliver frames for messages already queued for cid.

        Bounded by design (pull-on-subscribe flush, inline-body slice
        convention: consumer-tag + delivery-tag + redelivered + exchange +
        routing-key + body bytes). Ownership: `dst` round-trips.
        """
        var n = 0
        while n < _CONSUME_FLUSH_MAX():
            var d = self._broker.deliver(cid)
            if not d.__bool__():
                return dst^
            var tag = d.value().delivery_tag()
            var payload = self._broker.read_payload(cid, tag)
            var args = List[UInt8]()
            write_short_string(args, String(cid))
            write_u64(args, tag)
            args.append(0)  # redelivered bit (octet-packed, slice convention)
            write_short_string(args, "")  # exchange (not carried by Delivery)
            write_short_string(args, "")  # routing key (same)
            for i in range(len(payload)):
                args.append(payload[i])
            var wire = AMQPFrameCodec.encode_method_frame(
                chan,
                BASIC_DELIVER().class_id,
                BASIC_DELIVER().method_id,
                args^,
            )
            for i in range(len(wire)):
                dst.append(wire[i])
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
        # open-ok: reserved-1 short-string + reserved-2 long-string.
        var args = List[UInt8]()
        write_short_string(args, "")
        write_long_str_empty(args)
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
