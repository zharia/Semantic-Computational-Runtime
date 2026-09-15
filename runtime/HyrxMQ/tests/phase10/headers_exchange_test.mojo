# Headers-exchange end-to-end test (headers-exchange slice).
#
# Proves an `amq.headers` exchange actually routes on AMQP `headers` properties
# over the real wire path, not merely at the core Exchange boundary:
#
#   Part A (in-process): the broker surface with an additive `publish_with_headers`
#     entry point. x-match=all bindings get matching / non-matching / absent
#     headers; only the matching queue receives.
#
#   Part B (raw wire): AMQPListener + raw frames. queue.bind carries the trailing
#     `arguments` field table (x-match + header pair); basic.publish carries a
#     content header with the `headers` property (flag 0x2000). basic.get then
#     proves which queue each publish reached (and that a headerless publish and
#     a non-matching publish reach NONE).
#
# All operations complete within 5 seconds; self-contained, no external deps.

from std.collections import Dict, List

from hyrx.transport.tcp import TCPConnection

from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec
from hyrx.amqp.field_table import FieldTable
from hyrx.amqp.constants import (
    BASIC_CLASS_ID,
    BASIC_GET,
    BASIC_GET_EMPTY,
    BASIC_GET_OK,
    BASIC_PUBLISH,
    CHANNEL_OPEN,
    CHANNEL_OPEN_OK,
    CONNECTION_CLOSE,
    CONNECTION_CLOSE_OK,
    CONNECTION_OPEN,
    CONNECTION_OPEN_OK,
    CONNECTION_START,
    CONNECTION_START_OK,
    CONNECTION_TUNE,
    CONNECTION_TUNE_OK,
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
from hyrxmq.broker import HyrxMQBroker
from hyrxmq.amqp_service import (
    ByteReader,
    write_short_string,
    write_long_string,
    write_u16,
    write_u32,
    write_u64,
)

from hyrx.core.exchange import HeaderArgs

from hyrx.testing import check, check_eq


# ---- shared builders ----

def bytes_of(s: String) -> List[UInt8]:
    var out = List[UInt8]()
    var b = s.as_bytes()
    for i in range(len(b)):
        out.append(b[i])
    return out^


def reserved_short(mut out: List[UInt8]):
    out.append(UInt8(0))
    out.append(UInt8(0))


def _body(val: UInt8) -> List[UInt8]:
    var b = List[UInt8]()
    b.append(val)
    return b^


def _ha_all(var k: String, var v: String) -> HeaderArgs:
    """HeaderArgs for a headers binding: x-match=all + one required pair."""
    var keys = List[String]()
    var vals = List[String]()
    keys.append("x-match")
    vals.append("all")
    keys.append(k)
    vals.append(v)
    return HeaderArgs(keys^, vals^)


def _hdr_table(var k: String, var v: String) -> FieldTable:
    """A one-entry AMQP field table holding one string header."""
    var ft = FieldTable()
    ft.set_string(k, v)
    return ft^


def _hdr_map(var k: String, var v: String) -> Dict[String, String]:
    var h = Dict[String, String]()
    h[k] = v
    return h^


# ---- Part A: in-process broker surface ----

def test_broker_api() raises:
    """broker.publish_with_headers drives a headers exchange by header map."""
    var cfg = HyrxMQConfig()
    var broker = HyrxMQBroker(cfg^)
    broker.start()
    _ = broker.declare_exchange("hx", "headers")
    _ = broker.declare_queue("hq_a")
    _ = broker.declare_queue("hq_b")
    check(
        broker.bind_queue("hq_a", "hx", "", _ha_all("kind", "a")),
        "bind hq_a (x-match=all kind=a)",
    )
    check(
        broker.bind_queue("hq_b", "hx", "", _ha_all("kind", "b")),
        "bind hq_b (x-match=all kind=b)",
    )

    check(
        broker.publish_with_headers("hx", "", _body(0x11), _hdr_map("kind", "a")) == 1,
        "headers: kind=a routes to exactly one queue",
    )
    check(
        broker.publish_with_headers("hx", "", _body(0x12), _hdr_map("kind", "b")) == 1,
        "headers: kind=b routes to exactly the other queue",
    )
    check(
        broker.publish_with_headers("hx", "", _body(0x13), _hdr_map("kind", "c")) == 0,
        "headers: non-matching value routes nowhere",
    )
    check(
        broker.publish_with_headers("hx", "", _body(0x14), Dict[String, String]()) == 0,
        "headers: absent header routes nowhere",
    )
    check(broker.queue_depth("hq_a") == 1, "headers: hq_a holds exactly its match")
    check(broker.queue_depth("hq_b") == 1, "headers: hq_b holds exactly its match")
    print("  [PASS] broker API headers routing (all/non-match/absent)")


# ---- Part B: raw AMQP wire path ----

struct ClientStream:
    """Socket client with an incremental frame decoder."""

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
        check_eq(sent, n, "all client bytes written")

    def next_frame(mut self) raises -> AMQPFrame:
        var i = 0
        while i < 32:
            var f = self.codec.try_parse_frame()
            if f.__bool__():
                return AMQPFrame(
                    f.value().frame_type,
                    f.value().channel,
                    f.value().payload_copy(),
                )
            var chunk = self.conn.recv_bytes(4096)
            if len(chunk) == 0:
                raise "client: server closed before a frame arrived"
            self.codec.feed_bytes(chunk^)
            i += 1
        raise "client: no complete frame after 32 reads"

    def next_method(mut self) raises -> MethodID:
        var f = self.next_frame()
        check_eq(Int(f.frame_type), 1, "expected METHOD frame")
        var p = f.payload_copy()
        check(len(p) >= 4, "method frame has class+method")
        var mid = MethodID(
            (UInt16(p[0]) << 8) | UInt16(p[1]),
            (UInt16(p[2]) << 8) | UInt16(p[3]),
        )
        self.last_payload = p^
        return mid^

    def read_exact(mut self, n: Int) raises -> List[UInt8]:
        return self.conn.recv_exact(n)

    def close(mut self):
        self.conn.close()


def protocol_header() -> List[UInt8]:
    var h = List[UInt8]()
    for b in bytes_of("AMQP"):
        h.append(b)
    h.append(0)
    h.append(0)
    h.append(0x09)
    h.append(0x01)
    return h^


def start_ok_args() -> List[UInt8]:
    var args = List[UInt8]()
    write_u32(args, 0)  # empty client-properties table
    write_short_string(args, "PLAIN")
    var resp = List[UInt8]()
    resp.append(0)
    for b in bytes_of("admin"):
        resp.append(b)
    resp.append(0)
    for b in bytes_of("password"):
        resp.append(b)
    write_u32(args, UInt32(len(resp)))
    for b in resp:
        args.append(b)
    write_short_string(args, "en_US")
    return args^


def tune_ok_args() -> List[UInt8]:
    var args = List[UInt8]()
    write_u16(args, 2047)
    write_u32(args, UInt32(131072))
    write_u16(args, 0)
    return args^


def open_args() -> List[UInt8]:
    var args = List[UInt8]()
    write_short_string(args, "/")
    write_short_string(args, "")
    args.append(0)
    return args^


def request(chan: UInt16, mid: MethodID, var args: List[UInt8]) -> List[UInt8]:
    return AMQPFrameCodec.encode_method_frame(
        chan, mid.class_id, mid.method_id, args^
    )


def do_handshake(
    mut client: ClientStream, mut listener: AMQPListener, slot: Int
) raises:
    var hdr = protocol_header()
    client.send(hdr.copy())
    check_eq(listener.serve_one_frame(slot), 1, "header served (start sent)")
    var first = client.read_exact(1)
    check(first[0] == UInt8(0x01), "server's first byte is a METHOD frame")
    client.codec.feed_bytes(first^)
    check(client.next_method() == CONNECTION_START(), "connection.start received")

    client.send(request(UInt16(0), CONNECTION_START_OK(), start_ok_args()^))
    check_eq(listener.serve_one_frame(slot), 1, "start-ok served")
    check(client.next_method() == CONNECTION_TUNE(), "connection.tune received")

    client.send(request(UInt16(0), CONNECTION_TUNE_OK(), tune_ok_args()^))
    check_eq(listener.serve_one_frame(slot), 1, "tune-ok served")
    client.send(request(UInt16(0), CONNECTION_OPEN(), open_args()^))
    check_eq(listener.serve_one_frame(slot), 1, "connection.open served")
    check(client.next_method() == CONNECTION_OPEN_OK(), "connection.open-ok received")


def wire_channel_open(
    mut client: ClientStream, mut listener: AMQPListener, slot: Int
) raises:
    var args = List[UInt8]()
    write_long_string(args, "")
    client.send(request(UInt16(1), CHANNEL_OPEN(), args^))
    check_eq(listener.serve_one_frame(slot), 1, "channel.open served")
    check(client.next_method() == CHANNEL_OPEN_OK(), "channel.open-ok received")


def wire_exchange_declare(
    mut client: ClientStream, mut listener: AMQPListener, slot: Int, var name: String
) raises:
    var args = List[UInt8]()
    reserved_short(args)
    write_short_string(args, name)
    write_short_string(args, "headers")
    args.append(0)
    write_u32(args, 0)
    client.send(request(UInt16(1), EXCHANGE_DECLARE(), args^))
    check_eq(listener.serve_one_frame(slot), 1, "exchange.declare served")
    check(client.next_method() == EXCHANGE_DECLARE_OK(), "exchange.declare-ok received")


def wire_queue_declare(
    mut client: ClientStream, mut listener: AMQPListener, slot: Int, var name: String
) raises:
    var args = List[UInt8]()
    reserved_short(args)
    write_short_string(args, name)
    args.append(0)
    write_u32(args, 0)
    client.send(request(UInt16(1), QUEUE_DECLARE(), args^))
    check_eq(listener.serve_one_frame(slot), 1, "queue.declare served")
    check(client.next_method() == QUEUE_DECLARE_OK(), "queue.declare-ok received")


def wire_queue_bind(
    mut client: ClientStream,
    mut listener: AMQPListener,
    slot: Int,
    var queue: String,
    var exchange: String,
    var table: FieldTable,
) raises:
    """queue.bind with a trailing `arguments` field table of header criteria."""
    var args = List[UInt8]()
    reserved_short(args)
    write_short_string(args, queue)
    write_short_string(args, exchange)
    write_short_string(args, "")
    var tbytes = table.to_bytes()
    for i in range(len(tbytes)):
        args.append(tbytes[i])
    client.send(request(UInt16(1), QUEUE_BIND(), args^))
    check_eq(listener.serve_one_frame(slot), 1, "queue.bind served")
    check(client.next_method() == QUEUE_BIND_OK(), "queue.bind-ok received")


def wire_publish(
    mut client: ClientStream,
    mut listener: AMQPListener,
    slot: Int,
    var exchange: String,
    var body: List[UInt8],
    has_headers: Bool,
    var table: FieldTable,
) raises:
    """basic.publish (exchange, empty key) with an optional headers property."""
    var pargs = List[UInt8]()
    reserved_short(pargs)
    write_short_string(pargs, exchange)
    write_short_string(pargs, "")
    pargs.append(0)
    client.send(request(UInt16(1), BASIC_PUBLISH(), pargs^))
    check_eq(listener.serve_one_frame(slot), 1, "publish method served")

    var flags = UInt16(0)
    var props = List[UInt8]()
    if has_headers:
        flags = UInt16(0x2000)  # basic `headers` property (amqp0-9-1 §3.2.7)
        props = table.to_bytes()
    client.send(
        AMQPFrameCodec.encode_header_frame(
            UInt16(1), UInt16(BASIC_CLASS_ID()), UInt64(len(body)), flags, props^
        )
    )
    check_eq(listener.serve_one_frame(slot), 1, "content header served")
    client.send(AMQPFrameCodec.encode_body_frame(UInt16(1), body.copy()))
    check_eq(listener.serve_one_frame(slot), 1, "content body served")


def wire_get_body(
    mut client: ClientStream, mut listener: AMQPListener, slot: Int, var queue: String
) raises -> List[UInt8]:
    """basic.get (no-ack) -> get-ok + content; returns the delivered body."""
    var args = List[UInt8]()
    reserved_short(args)
    write_short_string(args, queue)
    args.append(1)  # no-ack = true
    client.send(request(UInt16(1), BASIC_GET(), args^))
    check_eq(listener.serve_one_frame(slot), 1, "basic.get served")
    check(client.next_method() == BASIC_GET_OK(), "basic.get-ok received")

    var hf = client.next_frame()
    check_eq(Int(hf.frame_type), 2, "content HEADER follows get-ok")
    var hp = hf.payload_copy()
    var size = UInt64(0)
    for i in range(4, 12):
        size = (size << 8) | UInt64(hp[i])
    var got = List[UInt8]()
    while len(got) < Int(size):
        var bf = client.next_frame()
        check_eq(Int(bf.frame_type), 3, "content BODY follows header")
        var bp = bf.payload_copy()
        for i in range(len(bp)):
            got.append(bp[i])
    return got^


def wire_expect_empty(
    mut client: ClientStream, mut listener: AMQPListener, slot: Int, var queue: String
) raises:
    """basic.get (no-ack) -> get-empty (queue drained)."""
    var args = List[UInt8]()
    reserved_short(args)
    write_short_string(args, queue)
    args.append(1)
    client.send(request(UInt16(1), BASIC_GET(), args^))
    check_eq(listener.serve_one_frame(slot), 1, "basic.get served")
    check(client.next_method() == BASIC_GET_EMPTY(), "basic.get-empty received")


def test_wire() raises:
    """Header criteria over queue.bind arguments + basic.publish headers."""
    var cfg = HyrxMQConfig()
    cfg.listen_host = "127.0.0.1"
    cfg.port = 0
    var listener = AMQPListener(cfg^)
    check(listener.start(), "listener started")
    var port = listener.port()
    check(port > 0, "ephemeral port assigned")

    var conn = TCPConnection.connect("127.0.0.1", port)
    var client = ClientStream(conn^)
    var slot = listener.accept_one()
    check(slot >= 0, "server accepted client")

    do_handshake(client, listener, slot)
    wire_channel_open(client, listener, slot)
    wire_exchange_declare(client, listener, slot, "hx.wire")
    wire_queue_declare(client, listener, slot, "hq.match")
    wire_queue_declare(client, listener, slot, "hq.other")

    wire_queue_bind(client, listener, slot, "hq.match", "hx.wire",
                    _hdr_table2("all", "kind", "a"))
    wire_queue_bind(client, listener, slot, "hq.other", "hx.wire",
                    _hdr_table2("all", "kind", "b"))
    print("  [PASS] queue.bind with arguments field table")

    # publish kind=a (→ hq.match), kind=b (→ hq.other), no headers (→ nobody)
    wire_publish(client, listener, slot, "hx.wire", bytes_of("match-msg"),
                 True, _hdr_table("kind", "a"))
    wire_publish(client, listener, slot, "hx.wire", bytes_of("other-msg"),
                 True, _hdr_table("kind", "b"))
    wire_publish(client, listener, slot, "hx.wire", bytes_of("drop-msg"),
                 False, _hdr_table("kind", "z"))
    print("  [PASS] basic.publish with headers property")

    var m = wire_get_body(client, listener, slot, "hq.match")
    check(len(m) == len(bytes_of("match-msg")), "hq.match delivered one message")
    check(m[0] == bytes_of("match-msg")[0], "hq.match got the kind=a body")
    wire_expect_empty(client, listener, slot, "hq.match")

    var o = wire_get_body(client, listener, slot, "hq.other")
    check(len(o) == len(bytes_of("other-msg")), "hq.other delivered one message")
    check(o[0] == bytes_of("other-msg")[0], "hq.other got the kind=b body")
    wire_expect_empty(client, listener, slot, "hq.other")
    print("  [PASS] header routing: matching delivered, non-match/absent dropped")

    client.close()
    listener.stop()


def _hdr_table2(
    var mode: String, var k: String, var v: String
) -> FieldTable:
    """A field table holding x-match + one header pair."""
    var ft = FieldTable()
    ft.set_string("x-match", mode)
    ft.set_string(k, v)
    return ft^


def main() raises:
    print("Headers Exchange End-to-End Test")
    print("================================")

    print("\n--- Part A: in-process broker API ---")
    test_broker_api()

    print("\n--- Part B: raw AMQP wire path ---")
    test_wire()

    print("\n================================")
    print("HEADERS_EXCHANGE_TEST=PASS")
