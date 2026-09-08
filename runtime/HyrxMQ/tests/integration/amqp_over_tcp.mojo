# AMQP 0-9-1 frames over a REAL TCP socket — network data-path proof.
#
# Proves the leg that unit tests could not: socket bytes -> AMQPFrameCodec ->
# AMQPAdapter -> Router -> delivery, and the delivered payload back out over
# the same socket. The listener is a flare TCP listener bound in-process on an
# ephemeral port (port 0, real port read back from the OS).
#
# Single-threaded bind -> connect -> accept, so nothing can block forever:
# the kernel backlog holds the connect until accept() runs, and the whole
# encoded frame sequence is far below the socket buffer size.
#
# basic.publish carries its body inline after the routing-key field (the
# documented Phase 7 representation choice, see src/hyrxmq/amqp_service.mojo);
# the field layout and the ByteReader used here are the project's own.
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
from hyrxmq.amqp_service import ByteReader, write_short_string


def check(cond: Bool, msg: String) raises:
    if not cond:
        raise "FAIL: " + msg


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
    for i in range(len(body)):
        pub_args.append(body[i])
    append_all(
        wire,
        AMQPFrameCodec.encode_method_frame(
            channel=1,
            class_id=BASIC_PUBLISH().class_id,
            method_id=BASIC_PUBLISH().method_id,
            args=pub_args^,
        ),
    )

    return wire^


def server_apply(
    mut adapter: AMQPAdapter, frame: AMQPFrame
) raises -> Int:
    """Decode one method frame and apply it through the adapter.

    Returns the number of queues the frame's publish routed to (0 otherwise)."""
    check(frame.frame_type == FRAME_METHOD(), "frame is a method frame")
    var method = parse_method_args(frame.payload_copy())
    var mid = MethodID(method.class_id, method.method_id)
    var reader = ByteReader(method.args.copy())

    if mid == QUEUE_DECLARE():
        _ = reader.read_short()
        var queue_name = reader.read_short_string()
        check(adapter.declare_queue(queue_name^, durable=False), "queue.declare")
    elif mid == EXCHANGE_DECLARE():
        _ = reader.read_short()
        var exchange_name = reader.read_short_string()
        var exchange_type = reader.read_short_string()
        check(
            adapter.declare_exchange(
                exchange_name^, exchange_type^, durable=False
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
                bind_queue^, bind_exchange^, bind_key^
            ),
            "queue.bind",
        )
    else:
        # basic.publish is the only remaining method in this slice.
        check(mid == BASIC_PUBLISH(), "unexpected method on the wire")
        _ = reader.read_short()
        var publish_exchange = reader.read_short_string()
        var publish_key = reader.read_short_string()
        var publish_body = reader.read_remaining()
        return adapter.publish(
            publish_key^, publish_body^, publish_exchange^
        )
    return 0


def main() raises:
    var expected = bytes_of("amqp-over-real-tcp-payload")

    var listener = TCPListener("127.0.0.1", 0, TransportConfig()^)
    check(listener.start(), "listener started")
    var port = listener.port()
    check(port > 0, "ephemeral port assigned")

    var client = TCPConnection.connect("127.0.0.1", port)
    var pending = listener.accept_connection()
    check(pending.__bool__(), "server accepted the client")

    # ---- client -> socket: raw AMQP frame bytes ----
    var wire = client_wire(expected.copy())
    check(client.send_bytes(wire.copy()) == len(wire), "all frame bytes written")

    # ---- socket -> server: 64-byte reads force codec reassembly ----
    var codec = AMQPFrameCodec()
    var adapter = AMQPAdapter()
    var frames_seen = 0
    var routed = 0
    while frames_seen < 4:
        var chunk = pending.value().recv_bytes(64)
        if len(chunk) == 0:
            raise "peer closed before all frames arrived"
        codec.feed_bytes(chunk^)
        var next_frame = codec.try_parse_frame()
        while next_frame.__bool__():
            frames_seen += 1
            routed += server_apply(adapter, next_frame.value())
            next_frame = codec.try_parse_frame()
    check(frames_seen == 4, "four frames parsed off the socket")
    check(routed == 1, "publish routed to exactly one queue")

    # ---- adapter delivery + payload identity ----
    var consumer_id = adapter.consume("tcp.q")
    var delivery = adapter.deliver_next(consumer_id)
    check(delivery.__bool__(), "message delivered to the consumer")
    var payload = adapter.read_payload(consumer_id, delivery.value().delivery_tag())
    check_bytes(payload, expected, "delivered payload matches published payload")

    # ---- server -> socket -> client: payload returns over the real wire ----
    check(
        pending.value().send_bytes(payload.copy()) == len(expected),
        "server wrote the payload back",
    )
    check_bytes(client.recv_exact(len(expected)), expected, "client read it back")

    pending.value().close()
    client.close()
    listener.stop()
    print("AMQP_OVER_TCP_PASS")
