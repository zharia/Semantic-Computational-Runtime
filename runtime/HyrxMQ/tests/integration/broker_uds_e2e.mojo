# UDS front-end end-to-end broker over a REAL Unix domain socket.

# Mirrors broker_tcp_e2e exactly, but every byte crosses a UDSConnection
# instead of a TCPConnection. The server side is the SAME production path:
# socket bytes -> AMQPFrameCodec -> UDSAMQPListener -> AMQPConnServing[UDSConnection]
# -> AMQPService -> HyrxMQBroker -> engine, responses back out over the socket.
# This is what makes a UDS benchmark cell comparable to the TCP cell: identical
# connection-negotiation + content-frame serving, different transport.

# Single-thread strategy (same as the TCP test): the STEP API, not threads.
# accept_one()/serve_one_frame() advance the server by at most one frame, so the
# test interleaves client-send / server-step / client-recv deterministically
# with zero unbounded blocking.

from std.collections import List, Optional
from std.os import unlink
from std.time import monotonic

from hyrx.transport.uds import UDSConnection

from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec
from hyrx.amqp.constants import (
    BASIC_ACK,
    BASIC_CONSUME,
    BASIC_CONSUME_OK,
    BASIC_DELIVER,
    BASIC_PUBLISH,
    CONNECTION_START,
    CONNECTION_START_OK,
    CONNECTION_TUNE,
    CONNECTION_TUNE_OK,
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
from hyrxmq.listener import UDSAMQPListener
from hyrxmq.amqp_service import (
    ByteReader,
    write_short_string,
    write_u16,
    write_u32,
    write_u64,
)


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
    """UDS socket client with an incremental frame decoder (bounded reads)."""

    var conn: UDSConnection
    var codec: AMQPFrameCodec
    var last_payload: List[UInt8]

    def __init__(out self, var c: UDSConnection):
        self.conn = c^
        self.codec = AMQPFrameCodec()
        self.last_payload = List[UInt8]()

    def send(mut self, var wire: List[UInt8]) raises:
        var n = len(wire)
        var sent = self.conn.send_bytes(wire^)
        check(sent == n, "all client bytes written")

    def next_frame(mut self) raises -> AMQPFrame:
        """Parse the next frame of ANY type; bounded (32 socket reads max)."""
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
        raise "client: no complete frame after 32 reads (deadlock guard)"

    def next_method(mut self) raises -> MethodID:
        """Parse the next frame and require it to be a METHOD frame."""
        var f = self.next_frame()
        check(f.frame_type == 1, "expected a METHOD frame")
        var p = f.payload_copy()
        check(len(p) >= 4, "method frame carries class+method")
        var mid = MethodID(
            (UInt16(p[0]) << 8) | UInt16(p[1]),
            (UInt16(p[2]) << 8) | UInt16(p[3]),
        )
        self.last_payload = p^
        return mid^

    def expect_body(mut self, want: List[UInt8]) raises:
        """Read the HEADER (+BODY frames) following a content method frame and
        assert the reassembled body equals `want` (§2.3.5 layout check)."""
        var hf = self.next_frame()
        check(hf.frame_type == 2, "a content HEADER frame follows the method")
        var hp = hf.payload_copy()
        var hclass = (UInt16(hp[0]) << 8) | UInt16(hp[1])
        check(hclass == 60, "content header class-id is basic (60)")
        var w = (UInt16(hp[2]) << 8) | UInt16(hp[3])
        check(w == 0, "content header weight is reserved zero")
        var size = UInt64(0)
        for i in range(4, 12):
            size = (size << 8) | UInt64(hp[i])
        check(Int(size) == len(want), "declared body-size matches the payload")
        var got = List[UInt8]()
        while len(got) < Int(size):
            var bf = self.next_frame()
            check(bf.frame_type == 3, "a content BODY frame follows the header")
            var bp = bf.payload_copy()
            for i in range(len(bp)):
                got.append(bp[i])
        check_bytes(got, want, "delivered body bytes match the published body")

    def read_exact(mut self, n: Int) raises -> List[UInt8]:
        return self.conn.recv_exact(n)

    def close(mut self):
        self.conn.close()


def append_all(mut dst: List[UInt8], var src: List[UInt8]):
    for i in range(len(src)):
        dst.append(src[i])


def request(
    chan: UInt16, mid: MethodID, var args: List[UInt8]
) -> List[UInt8]:
    return AMQPFrameCodec.encode_method_frame(
        chan, mid.class_id, mid.method_id, args^
    )


def protocol_header() -> List[UInt8]:
    """The 8-octet AMQP 0-9-1 header (41 4D 51 50 00 00 09 01)."""
    var h = List[UInt8]()
    for b in bytes_of("AMQP"):
        h.append(b)
    h.append(0)
    h.append(0)
    h.append(0x09)
    h.append(0x01)
    return h^


def start_ok_args() -> List[UInt8]:
    """client-properties(empty) + mechanism(PLAIN) + response(SASL PLAIN) + locale."""
    var args = List[UInt8]()
    write_u32(args, 0)  # empty client-properties table
    write_short_string(args, "PLAIN")
    var resp = List[UInt8]()
    resp.append(0)  # authzid NUL
    for b in bytes_of("admin"):
        resp.append(b)
    resp.append(0)  # authcid/passwd separator
    for b in bytes_of("password"):
        resp.append(b)
    write_u32(args, UInt32(len(resp)))  # response is a longstr
    for b in resp:
        args.append(b)
    write_short_string(args, "en_US")
    return args^


def tune_ok_args() -> List[UInt8]:
    """tune-ok: channel-max(short) + frame-max(long) + heartbeat(short)."""
    var args = List[UInt8]()
    write_u16(args, 2047)
    write_u32(args, UInt32(131072))
    write_u16(args, 0)
    return args^


def open_args() -> List[UInt8]:
    var args = List[UInt8]()
    write_short_string(args, "/")
    write_short_string(args, "")
    args.append(0)  # reserved-2 bit
    return args^


def do_handshake(
    mut client: ClientStream, mut listener: UDSAMQPListener, var slot: Int
) raises:
    """Drive the header -> start -> start-ok -> tune -> tune-ok -> open ->
    open-ok negotiation over the real socket, asserting each frame's ids."""
    # 1. protocol header, server echoes it then sends connection.start.
    var hdr = protocol_header()
    client.send(hdr.copy())
    check(
        listener.serve_one_frame(slot) == 1, "protocol header served (start sent)"
    )
    var magic = client.read_exact(8)
    check_bytes(magic, hdr, "server echoed the 8-octet header")
    check(client.next_method() == CONNECTION_START(), "connection.start received")

    # 2. start-ok -> tune.
    client.send(
        request(UInt16(0), CONNECTION_START_OK(), start_ok_args()^)
    )
    check(listener.serve_one_frame(slot) == 1, "start-ok served")
    check(client.next_method() == CONNECTION_TUNE(), "connection.tune received")

    # 3. tune-ok (no reply) then open -> open-ok.
    client.send(request(UInt16(0), CONNECTION_TUNE_OK(), tune_ok_args()^))
    check(listener.serve_one_frame(slot) == 1, "tune-ok served")
    client.send(request(UInt16(0), CONNECTION_OPEN(), open_args()^))
    check(listener.serve_one_frame(slot) == 1, "connection.open served")
    check(
        client.next_method() == CONNECTION_OPEN_OK(),
        "connection.open-ok received (handshake complete)",
    )


def main() raises:
    # ---- unique socket path so concurrent/stale files cannot collide ----
    var path = "/tmp/hyrx_broker_uds_e2e_" + String(monotonic()) + ".sock"

    # ---- server: broker listener on the Unix domain socket ----
    var cfg = HyrxMQConfig()
    cfg.listen_host = "127.0.0.1"  # unused by the UDS front end; keeps config valid
    cfg.port = 0
    var listener = UDSAMQPListener(path.copy(), cfg^)
    check(listener.start(), "uds listener started")
    check(listener.transport_kind() == "uds", "transport_kind is uds")
    check(listener.path() == path, "listener reports its bound socket path")

    # ---- client connects (fills backlog), then server accepts ----
    var conn = UDSConnection.connect(path.copy())
    var client = ClientStream(conn^)
    var slot = listener.accept_one()
    check(slot >= 0, "server accepted the UDS connection")

    # ---- connection negotiation: header -> start -> start-ok -> tune ->
    # tune-ok -> open -> open-ok (real handshake, same path as TCP). ----
    do_handshake(client, listener, slot)

    # ---- exchange.declare -> declare-ok ----
    var eargs = List[UInt8]()
    reserved_short(eargs)
    write_short_string(eargs, "e2e.ex")
    write_short_string(eargs, "direct")
    eargs.append(0)  # bits: passive/durable/auto-delete/no-wait = 0
    write_u32(eargs, 0)  # arguments: empty field table (u32 length 0)
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
    write_u32(qargs, 0)  # arguments: empty field table (u32 length 0)
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

    # ---- basic.publish: METHOD + HEADER + BODY -> fire-and-forget ----
    var body = bytes_of("amqp-over-uds-e2e-payload")
    var pargs = List[UInt8]()
    reserved_short(pargs)
    write_short_string(pargs, "e2e.ex")
    write_short_string(pargs, "e2e.key")
    pargs.append(0)  # bits: mandatory / immediate
    client.send(request(UInt16(1), BASIC_PUBLISH(), pargs^))
    check(listener.serve_one_frame(slot) == 1, "basic.publish method served")
    var hdr = AMQPFrameCodec.encode_header_frame(
        UInt16(1), UInt16(60), UInt64(len(body)), UInt16(0), List[UInt8]()
    )
    client.send(hdr^)
    check(listener.serve_one_frame(slot) == 1, "content header served")
    var bwire = List[UInt8]()
    var b1 = List[UInt8]()
    for i in range(5):
        b1.append(body[i])
    append_all(bwire, AMQPFrameCodec.encode_body_frame(UInt16(1), b1^))
    var b2 = List[UInt8]()
    for i in range(5, len(body)):
        b2.append(body[i])
    append_all(bwire, AMQPFrameCodec.encode_body_frame(UInt16(1), b2^))
    client.send(bwire^)
    check(listener.serve_one_frame(slot) == 1, "first body frame served")
    check(listener.serve_one_frame(slot) == 1, "second body frame served")

    # ---- basic.consume -> consume-ok + basic.deliver(+header+body) ----
    var cargs = List[UInt8]()
    reserved_short(cargs)
    write_short_string(cargs, "e2e.q")
    write_short_string(cargs, "ctag-e2e")
    cargs.append(0)  # bits: no-local/no-ack/exclusive/no-wait
    cargs.append(0)  # arguments: empty table
    cargs.append(0)
    cargs.append(0)
    cargs.append(0)
    client.send(request(UInt16(1), BASIC_CONSUME(), cargs^))
    check(listener.serve_one_frame(slot) == 1, "basic.consume served")

    var ok_mid = client.next_method()
    check(ok_mid == BASIC_CONSUME_OK(), "basic.consume-ok received")
    # consume-ok echoes the client's consumer-tag (real clients route by it).
    var ordr = ByteReader(client.last_payload.copy())
    _ = ordr.read_short()  # class
    _ = ordr.read_short()  # method
    check(
        ordr.read_short_string() == "ctag-e2e",
        "consume-ok echoes the requested consumer-tag",
    )

    var d_mid = client.next_method()
    check(d_mid == BASIC_DELIVER(), "basic.deliver received over UDS")
    var dr = ByteReader(client.last_payload.copy())
    _ = dr.read_short()  # class
    _ = dr.read_short()  # method
    var ctag = dr.read_short_string()
    check(ctag == "ctag-e2e", "deliver carries the registered consumer-tag")
    var dtag = dr.read_long_long()
    _ = dr.read_octet()  # redelivered bit
    _ = dr.read_short_string()  # exchange (not carried by Delivery)
    _ = dr.read_short_string()  # routing key (same)
    client.expect_body(body^)

    # ---- basic.ack -> broker counters advance ----
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

    # ---- teardown: after the handshake + 6 business frames the client closes,
    # the server observes EOF on the next step. ----
    client.close()
    check(
        listener.serve_one_frame(slot) == -1,
        "server observes EOF after client close",
    )
    listener.stop()
    # stop() drops the UnixListener (unlinking the path); best-effort sweep for
    # any leftover socket file so the run leaves no artifacts.
    try:
        unlink(path)
    except:
        pass
    print("BROKER_UDS_E2E_PASS")
