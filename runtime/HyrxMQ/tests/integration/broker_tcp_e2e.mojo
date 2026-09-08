# Phase 7 unblock — end-to-end broker over a REAL TCP socket.

# Drives the production path strictly over the Hyrx transport contract:
# socket bytes -> AMQPFrameCodec -> AMQPListener -> AMQPService -> HyrxMQBroker
# -> engine, and responses back out over the same socket.
# provider containment: the server side uses AMQPListener (hyrx.transport.tcp),
# never flare directly; the client side here uses our TCPConnection.connect.

# Single-thread strategy (documented choice): the STEP API, not threads.
# accept_one()/serve_one_frame() advance the server by at most one frame, so
# the test interleaves client-send / server-step / client-recv deterministically
# with zero unbounded blocking (mojo 1.0 threading over non-copyable socket
# state is not proven in this repo; a bounded ping-pong is).

# Frame layout is the documented Phase 7 vertical slice (inline body on
# basic.publish and basic.deliver; redelivered bit as one octet; consumer id as
# a short-string) — see src/hyrxmq/amqp_service.mojo.

from std.collections import List, Optional

from hyrx.transport.tcp import TCPConnection

from hyrx.amqp.frame_codec import AMQPFrameCodec
from hyrx.amqp.constants import (
    BASIC_ACK,
    BASIC_CONSUME,
    BASIC_CONSUME_OK,
    BASIC_DELIVER,
    BASIC_PUBLISH,
    CONNECTION_OPEN,
    CONNECTION_OPEN_OK,
    EXCHANGE_DECLARE,
    EXCHANGE_DECLARE_OK,
    MethodID,
    QUEUE_BIND,
    QUEUE_BIND_OK,
    QUEUE_DECLARE,
    QUEUE_DECLARE_OK,
)

from hyrxmq.config import HyrxMQConfig
from hyrxmq.listener import AMQPListener
from hyrxmq.amqp_service import ByteReader, write_short_string, write_u64


from hyrx.testing import check

def bytes_of(s: String) -> List[UInt8]:
    var out = List[UInt8]()
    var b = s.as_bytes()
    for i in range(len(b)):
        out.append(b[i])
    return out^


def check_bytes(got: List[UInt8], want: List[UInt8], msg: String) raises:
    if len(got) != len(want):
        raise (
            "FAIL: " + msg
            + " (len " + String(len(got)) + " != " + String(len(want)) + ")"
        )
    for i in range(len(want)):
        if got[i] != want[i]:
            raise "FAIL: " + msg + " (byte " + String(i) + ")"


def reserved_short(mut out: List[UInt8]):
    out.append(UInt8(0))
    out.append(UInt8(0))


struct ClientStream:
    """Socket client with an incremental frame decoder (bounded reads)."""

    var conn: TCPConnection
    var codec: AMQPFrameCodec
    var last_payload: List[UInt8]

    def __init__(out self, var c: TCPConnection):
        self.conn = c^
        self.codec = AMQPFrameCodec()
        self.last_payload = List[UInt8]()

    def send(mut self, var wire: List[UInt8]) raises:
        var n = len(wire)
        var sent = self.conn.send_bytes(wire^)
        check(sent == n, "all client bytes written")

    def next_method(mut self) raises -> MethodID:
        """Parse the next method frame; bounded (32 socket reads max)."""
        var i = 0
        while i < 32:
            var f = self.codec.try_parse_frame()
            if f.__bool__():
                var p = f.value().payload_copy()
                check(len(p) >= 4, "method frame carries class+method")
                var mid = MethodID(
                    (UInt16(p[0]) << 8) | UInt16(p[1]),
                    (UInt16(p[2]) << 8) | UInt16(p[3]),
                )
                self.last_payload = p^
                return mid^
            var chunk = self.conn.recv_bytes(4096)
            if len(chunk) == 0:
                raise "client: server closed before a frame arrived"
            self.codec.feed_bytes(chunk^)
            i += 1
        raise "client: no complete frame after 32 reads (deadlock guard)"

    def close(mut self):
        self.conn.close()


def request(
    chan: UInt16, mid: MethodID, var args: List[UInt8]
) -> List[UInt8]:
    return AMQPFrameCodec.encode_method_frame(
        chan, mid.class_id, mid.method_id, args^
    )


def main() raises:
    # ---- server: broker listener on an ephemeral port ----
    var cfg = HyrxMQConfig()
    cfg.listen_host = "127.0.0.1"
    cfg.port = 0
    var listener = AMQPListener(cfg^)
    check(listener.start(), "listener started")
    var port = listener.port()
    check(port > 0, "kernel assigned an ephemeral port")

    # ---- client connects (fills backlog), then server accepts ----
    var conn = TCPConnection.connect("127.0.0.1", port)
    var client = ClientStream(conn^)
    var slot = listener.accept_one()

    # ---- connection.open -> open-ok ----
    var oargs = List[UInt8]()
    write_short_string(oargs, "/")
    reserved_short(oargs)
    reserved_short(oargs)
    client.send(request(UInt16(0), CONNECTION_OPEN(), oargs^))
    check(listener.serve_one_frame(slot) == 1, "open served")
    check(
        client.next_method() == CONNECTION_OPEN_OK(),
        "connection.open-ok received over TCP",
    )

    # ---- exchange.declare -> declare-ok ----
    var eargs = List[UInt8]()
    reserved_short(eargs)
    write_short_string(eargs, "e2e.ex")
    write_short_string(eargs, "direct")
    client.send(request(UInt16(1), EXCHANGE_DECLARE(), eargs^))
    check(listener.serve_one_frame(slot) == 1, "exchange.declare served")
    check(
        client.next_method() == EXCHANGE_DECLARE_OK(),
        "exchange.declare-ok received",
    )

    # ---- queue.declare -> declare-ok ----
    var qargs = List[UInt8]()
    reserved_short(qargs)
    write_short_string(qargs, "e2e.q")
    qargs.append(0)  # bits: passive/durable/exclusive/auto-delete/no-wait = 0
    client.send(request(UInt16(1), QUEUE_DECLARE(), qargs^))
    check(listener.serve_one_frame(slot) == 1, "queue.declare served")
    check(
        client.next_method() == QUEUE_DECLARE_OK(), "queue.declare-ok received"
    )

    # ---- queue.bind -> bind-ok ----
    var bargs = List[UInt8]()
    reserved_short(bargs)
    write_short_string(bargs, "e2e.q")
    write_short_string(bargs, "e2e.ex")
    write_short_string(bargs, "e2e.key")
    client.send(request(UInt16(1), QUEUE_BIND(), bargs^))
    check(listener.serve_one_frame(slot) == 1, "queue.bind served")
    check(client.next_method() == QUEUE_BIND_OK(), "queue.bind-ok received")

    # ---- basic.publish (inline body) -> fire-and-forget ----
    var body = bytes_of("amqp-over-tcp-e2e-payload")
    var pargs = List[UInt8]()
    reserved_short(pargs)
    write_short_string(pargs, "e2e.ex")
    write_short_string(pargs, "e2e.key")
    for i in range(len(body)):
        pargs.append(body[i])
    client.send(request(UInt16(1), BASIC_PUBLISH(), pargs^))
    check(listener.serve_one_frame(slot) == 1, "basic.publish served")

    # ---- basic.consume -> consume-ok + basic.deliver(payload) ----
    var cargs = List[UInt8]()
    write_short_string(cargs, "e2e.q")
    cargs.append(0)  # no-local bit (octet-packed, slice convention)
    client.send(request(UInt16(1), BASIC_CONSUME(), cargs^))
    check(listener.serve_one_frame(slot) == 1, "basic.consume served")

    var ok_mid = client.next_method()
    check(ok_mid == BASIC_CONSUME_OK(), "basic.consume-ok received")
    var d_mid = client.next_method()
    check(d_mid == BASIC_DELIVER(), "basic.deliver received over TCP")

    # parse the delivered frame (slice layout documented in the header)
    var dr = ByteReader(client.last_payload.copy())
    _ = dr.read_short()  # class
    _ = dr.read_short()  # method
    var ctag = dr.read_short_string()
    var cid = Int(ctag)
    var dtag = dr.read_long_long()
    _ = dr.read_octet()  # redelivered
    _ = dr.read_short_string()  # exchange (empty in this slice)
    _ = dr.read_short_string()  # routing key (empty in this slice)
    var got_body = dr.read_remaining()
    check_bytes(got_body, body, "delivered payload matches published payload")

    # ---- basic.ack -> broker counters advance ----
    # Spec arguments: delivery-tag(long-long) + multiple(bit). The consumer is
    # resolved from this connection's earlier basic.consume, NOT from a wire
    # octet (an octet here used to be mis-read as a consumer id).
    var aargs = List[UInt8]()
    write_u64(aargs, dtag)
    aargs.append(UInt8(0))  # multiple = false (single addressed delivery)
    client.send(request(UInt16(1), BASIC_ACK(), aargs^))
    check(listener.serve_one_frame(slot) == 1, "basic.ack served")

    var st = listener.status()
    check(st.messages_published >= 1, "status: published")
    check(st.messages_delivered >= 1, "status: delivered")
    check(st.messages_acked == 1, "status: exactly the addressed delivery acked")
    check(st.messages_acked <= st.messages_delivered, "status: ack <= deliver")
    check(listener.health() == "ok", "health ok after full round-trip")

    # ---- teardown: frames served this session = 8 ----
    client.close()
    check(
        listener.serve_one_frame(slot) == -1,
        "server observes EOF after client close",
    )
    listener.stop()
    print("BROKER_TCP_E2E_PASS")
