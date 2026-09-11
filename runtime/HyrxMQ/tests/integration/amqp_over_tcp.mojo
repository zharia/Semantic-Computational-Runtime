# AMQP 0-9-1 frames over a REAL TCP socket — network data-path proof.
#
# Proves the leg that unit tests could not: socket bytes -> AMQPFrameCodec ->
# AMQPAdapter -> HyrxEngine (the single Router) -> delivery, and the delivered
# payload back out over the same socket. The listener is a flare TCP listener bound in-process on an
# ephemeral port (port 0, real port read back from the OS).
#
# Single-threaded bind -> connect -> accept, so nothing can block forever:
# the kernel backlog holds the connect until accept() runs, and the whole
# encoded frame sequence is far below the socket buffer size.
#
# basic.publish is framed for real (amqp0-9-1.xml §2.3.5): the METHOD frame is
# followed by one content HEADER frame (class 60, declared body size) and BODY
# frames whose payloads sum to it. This test drives the ADAPTER directly (not
# AMQPService), so the reassembly below is the test's own mini-copy of that
# §2.3.5 state machine.
#
# Success prints AMQP_OVER_TCP_PASS; every other outcome raises.

from std.collections import List, Optional

from hyrx.transport.transport import TransportConfig
from hyrx.transport.tcp import TCPListener, TCPConnection

from hyrx.amqp.frame_codec import (
    AMQPFrame,
    AMQPFrameCodec,
    parse_method_args,
)
from hyrx.amqp.constants import (
    BASIC_PUBLISH,
    EXCHANGE_DECLARE,
    FRAME_METHOD,
    MethodID,
    QUEUE_BIND,
    QUEUE_DECLARE,
)
from hyrx.amqp.adapter import AMQPAdapter
from hyrx.embedded.api import HyrxEngine, HyrxConfig
from hyrxmq.amqp_service import ByteReader, write_short_string


from hyrx.testing import check
from hyrx.core.exchange import HeaderArgs

def bytes_of(s: String) -> List[UInt8]:
    """UTF-8 bytes of a short ASCII string."""
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
    """AMQP reserved-1 (short) field."""
    out.append(UInt8(0))
    out.append(UInt8(0))


def append_all(mut dst: List[UInt8], var src: List[UInt8]):
    """Concatenate an encoded frame onto the outgoing wire buffer."""
    for i in range(len(src)):
        dst.append(src[i])


def client_wire(var body: List[UInt8]) -> List[UInt8]:
    """Encode exchange.declare + queue.declare + queue.bind + basic.publish."""
    var wire = List[UInt8]()

    var ex_args = List[UInt8]()
    reserved_short(ex_args)
    write_short_string(ex_args, "tcp.ex")
    write_short_string(ex_args, "direct")
    append_all(
        wire,
        AMQPFrameCodec.encode_method_frame(
            channel=1,
            class_id=EXCHANGE_DECLARE().class_id,
            method_id=EXCHANGE_DECLARE().method_id,
            args=ex_args^,
        ),
    )

    var q_args = List[UInt8]()
    reserved_short(q_args)
    write_short_string(q_args, "tcp.q")
    append_all(
        wire,
        AMQPFrameCodec.encode_method_frame(
            channel=1,
            class_id=QUEUE_DECLARE().class_id,
            method_id=QUEUE_DECLARE().method_id,
            args=q_args^,
        ),
    )

    var bind_args = List[UInt8]()
    reserved_short(bind_args)
    write_short_string(bind_args, "tcp.q")
    write_short_string(bind_args, "tcp.ex")
    write_short_string(bind_args, "orders")
    append_all(
        wire,
        AMQPFrameCodec.encode_method_frame(
            channel=1,
            class_id=QUEUE_BIND().class_id,
            method_id=QUEUE_BIND().method_id,
            args=bind_args^,
        ),
    )

    var pub_args = List[UInt8]()
    reserved_short(pub_args)
    write_short_string(pub_args, "tcp.ex")
    write_short_string(pub_args, "orders")
    pub_args.append(0)  # bits: mandatory / immediate
    append_all(
        wire,
        AMQPFrameCodec.encode_method_frame(
            channel=1,
            class_id=BASIC_PUBLISH().class_id,
            method_id=BASIC_PUBLISH().method_id,
            args=pub_args^,
        ),
    )

    # Content: exactly one HEADER frame declaring the body size, then BODY
    # frames. The body is deliberately split 8 + rest to prove multi-frame
    # reassembly over a real socket.
    append_all(
        wire,
        AMQPFrameCodec.encode_header_frame(
            UInt16(1), UInt16(60), UInt64(len(body)), UInt16(0), List[UInt8]()
        ),
    )
    var first = List[UInt8]()
    for i in range(8):
        first.append(body[i])
    append_all(wire, AMQPFrameCodec.encode_body_frame(UInt16(1), first^))
    var rest = List[UInt8]()
    for i in range(8, len(body)):
        rest.append(body[i])
    append_all(wire, AMQPFrameCodec.encode_body_frame(UInt16(1), rest^))

    return wire^


struct WirePublisher:
    """The test's own copy of the §2.3.5 inbound reassembly state machine.

    start() arms a publish (METHOD frame seen); feed() consumes one content
    frame and returns the number of queues the completed publish routed to
    (0 while still in flight or when the frame is dropped fail-closed)."""

    var exchange: String
    var routing_key: String
    var body_size: Int  # -1 = awaiting the header frame
    var body: List[UInt8]
    var active: Bool

    def __init__(out self):
        self.exchange = String()
        self.routing_key = String()
        self.body_size = -1
        self.body = List[UInt8]()
        self.active = False

    def start(mut self, var ex: String, var rk: String):
        self.exchange = ex^
        self.routing_key = rk^
        self.body_size = -1
        while len(self.body) > 0:
            _ = self.body.pop()
        self.active = True

    def is_active(ref self) -> Bool:
        return self.active

    def feed(mut self, frame: AMQPFrame) raises -> Int:
        if not self.active:
            return 0  # content with no pending publish: dropped fail-closed
        if frame.frame_type == 2:
            if self.body_size >= 0:
                return 0  # second header for one publish: dropped
            var hp = frame.payload_copy()
            var size = UInt64(0)
            for i in range(4, 12):
                size = (size << 8) | UInt64(hp[i])
            self.body_size = Int(size)
            if self.body_size == 0:
                return self.complete()
            return 0
        if frame.frame_type == 3:
            if self.body_size < 0:
                return 0  # body before header: dropped
            for i in range(frame.payload_size()):
                if len(self.body) < self.body_size:
                    self.body.append(frame.payload[i])
            if len(self.body) == self.body_size:
                return self.complete()
            return 0
        return 0

    def complete(mut self) -> Int:
        """Deactivate the state; the caller publishes the collected bytes."""
        self.active = False
        self.body_size = -1
        return 1

    def take_body(mut self) -> List[UInt8]:
        """Move the collected bytes out (the state keeps ex/rkey for the
        publish call itself)."""
        var out = self.body^
        self.body = List[UInt8]()
        return out^


def server_apply(
    mut adapter: AMQPAdapter,
    mut engine: HyrxEngine,
    mut inflight: WirePublisher,
    frame: AMQPFrame,
) raises -> Int:
    """Apply one decoded frame; returns the number of queues a completed
    publish routed to (0 for everything else).

    The adapter holds no routing substrate: every operation is executed on the
    injected engine, which owns the one Router (§2.3.5 content reassembly for a
    publish lives in `inflight`, the test's own copy of the service state
    machine)."""
    if frame.frame_type != FRAME_METHOD():
        var done = inflight.feed(frame)
        if done == 0:
            return 0
        var ex = inflight.exchange.copy()
        var rk = inflight.routing_key.copy()
        var body = inflight.take_body()
        return adapter.publish(engine, rk^, body^, ex^)
    var method = parse_method_args(frame.payload_copy())
    var mid = MethodID(method.class_id, method.method_id)
    var reader = ByteReader(method.args.copy())

    if mid == QUEUE_DECLARE():
        _ = reader.read_short()
        var queue_name = reader.read_short_string()
        check(
            adapter.declare_queue(engine, queue_name^, durable=False),
            "queue.declare",
        )
    elif mid == EXCHANGE_DECLARE():
        _ = reader.read_short()
        var exchange_name = reader.read_short_string()
        var exchange_type = reader.read_short_string()
        check(
            adapter.declare_exchange(
                engine, exchange_name^, exchange_type^, durable=False
            ),
            "exchange.declare",
        )
    elif mid == QUEUE_BIND():
        _ = reader.read_short()
        var bind_queue = reader.read_short_string()
        var bind_exchange = reader.read_short_string()
        var bind_key = reader.read_short_string()
        check(
            adapter.bind_queue(
                engine, bind_queue^, bind_exchange^, bind_key^, HeaderArgs()
            ),
            "queue.bind",
        )
    else:
        # basic.publish is the only remaining method in this slice: envelope
        # only — the body arrives later as content frames (§2.3.5).
        check(mid == BASIC_PUBLISH(), "unexpected method on the wire")
        _ = reader.read_short()
        var publish_exchange = reader.read_short_string()
        var publish_key = reader.read_short_string()
        _ = reader.read_octet()  # bits: mandatory / immediate
        inflight.start(publish_exchange^, publish_key^)
    return 0


def main() raises:
    var expected = bytes_of("amqp-over-real-tcp-payload")

    var listener = TCPListener("127.0.0.1", 0, TransportConfig()^)
    check(listener.start(), "listener started")
    var port = listener.port()
    check(port > 0, "ephemeral port assigned")

    var client = TCPConnection.connect("127.0.0.1", port)
    var server = listener.accept_connection()
    check(server.__bool__(), "server accepted the client")

    # ---- client -> socket: raw AMQP frame bytes ----
    var wire = client_wire(expected.copy())
    check(client.send_bytes(wire.copy()) == len(wire), "all frame bytes written")

    # ---- socket -> server: 64-byte reads force codec reassembly ----
    var codec = AMQPFrameCodec()
    var adapter = AMQPAdapter()
    var engine = HyrxEngine(HyrxConfig(1024, 4096, 64))
    # 4 method frames + 1 header + 2 body = 7 frames off the socket.
    var frames_seen = 0
    var routed = 0
    var inflight = WirePublisher()
    while frames_seen < 7:
        var chunk = server.value().recv_bytes(64)
        if len(chunk) == 0:
            raise "peer closed before all frames arrived"
        codec.feed_bytes(chunk^)
        var next_frame = codec.try_parse_frame()
        while next_frame.__bool__():
            frames_seen += 1
            routed += server_apply(adapter, engine, inflight, next_frame.value())
            next_frame = codec.try_parse_frame()
    check(frames_seen == 7, "seven frames parsed off the socket")
    check(routed == 1, "publish routed to exactly one queue")
    check(not inflight.is_active(), "reassembly completed and cleared")

    # ---- adapter delivery + payload identity ----
    var consumer_id = adapter.consume(engine, "tcp.q")
    var delivery = adapter.deliver_next(engine, consumer_id)
    check(delivery.__bool__(), "message delivered to the consumer")
    var payload = adapter.read_payload(
        engine, consumer_id, delivery.value().delivery_tag()
    )
    # The publish/consume ran on the injected engine: the single authority saw
    # them (the adapter keeps no routing state for itself).
    check(engine.stats().active_queues == 1, "engine holds the declared queue")
    check(engine.stats().messages_published == 1, "engine counted the publish")
    check_bytes(payload, expected, "delivered payload matches published payload")

    # ---- server -> socket -> client: payload returns over the real wire ----
    check(
        server.value().send_bytes(payload.copy()) == len(expected),
        "server wrote the payload back",
    )
    check_bytes(client.recv_exact(len(expected)), expected, "client read it back")

    server.value().close()
    client.close()
    listener.stop()
    print("AMQP_OVER_TCP_PASS")
