# Real-socket transport behavior (audit §9).

# Exercises the EXISTING flare-backed TCP/UDS transport + AMQPFrameCodec over
# real loopback sockets (127.0.0.1 ephemeral port, plus a Unix-domain socket).
# Single-process, single-threaded bind -> connect -> accept ping-pong, so no
# read or accept can block forever:
#   - a read is only issued after the matching bytes are already in flight
#     (loopback kernel buffer) or the peer has closed (read returns EOF/0);
#   - every read loop is bounded by a fixed byte count or a small max-iteration
#     guard;
#   - every test closes its sockets and stops its listener.

# Cases:
#   1  connect -> open -> send -> recv round-trip (TCP + UDS), bytes integrity
#      across multiple write calls.
#   2  partial frame: two write calls with a gap; codec yields no frame until
#      the trailing 0xCE byte arrives.
#   3  one frame split across many 1-byte reads; parses exactly once.
#   4  multiple frames delivered in ONE read; codec yields them in order.
#   5  zero-length payload (heartbeat) parses off the wire.
#   6  abrupt disconnect: partial frame then close -> clean EOF, no crash/hang.
#   7  peer termination after a full exchange is observed as EOF.

# Success prints SOCKET_BEHAVIOR_PASS; any failure raises (non-zero exit).

from std.collections import List, Optional

from hyrx.transport.transport import TransportConfig
from hyrx.transport.tcp import TCPListener, TCPConnection
from hyrx.transport.uds import UDSListener, UDSConnection
from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec

from hyrx.testing import check


# ---------- byte helpers ----------

def bytes_of(s: String) -> List[UInt8]:
    var out = List[UInt8]()
    var b = s.as_bytes()
    for i in range(len(b)):
        out.append(b[i])
    return out^


def check_bytes(got: List[UInt8], want: List[UInt8], msg: String) raises:
    if len(got) != len(want):
        raise "FAIL: " + msg + " (len " + String(len(got)) + " != " + String(len(want)) + ")"
    for i in range(len(want)):
        if got[i] != want[i]:
            raise "FAIL: " + msg + " (byte " + String(i) + ")"


def slice_bytes(var src: List[UInt8], lo: Int, hi: Int) -> List[UInt8]:
    var out = List[UInt8]()
    for i in range(lo, hi):
        out.append(src[i])
    return out^


def append_all(mut dst: List[UInt8], var src: List[UInt8]):
    for i in range(len(src)):
        dst.append(src[i])


# ---------- codec-over-socket step ----------

def recv_one_frame(
    mut conn: Optional[TCPConnection], mut codec: AMQPFrameCodec
) raises -> AMQPFrame:
    """Advance one complete frame off a real socket (bounded, 64 reads max)."""
    var i = 0
    while i < 64:
        var f = codec.try_parse_frame()
        if f.__bool__():
            return AMQPFrame(
                f.value().frame_type,
                f.value().channel,
                f.value().payload_copy(),
            )
        var chunk = conn.value().recv_bytes(4096)
        if len(chunk) == 0:
            raise "recv_one_frame: peer closed before a complete frame"
        codec.feed_bytes(chunk^)
        i += 1
    raise "recv_one_frame: no complete frame after 64 reads (deadlock guard)"


# A small, distinctive body frame used by several cases.
def sample_body_frame() -> List[UInt8]:
    var body = List[UInt8]()
    for i in range(5):
        body.append(UInt8(0x41 + i))
    return AMQPFrameCodec.encode_body_frame(UInt16(7), body^)


# ---------- case 1a: TCP round-trip ----------

def test_tcp_roundtrip() raises:
    var listener = TCPListener("127.0.0.1", 0, TransportConfig()^)
    check(listener.start(), "tcp listener start")
    var port = listener.port()
    check(port > 0, "tcp ephemeral port assigned")

    var client = TCPConnection.connect("127.0.0.1", port)
    var server = listener.accept_connection()
    check(server.__bool__(), "tcp server accepted")

    # open handshake: client sends a connection.open method frame, server
    # decodes it, replies open-ok, client decodes the reply.
    var scodec = AMQPFrameCodec()
    var ccodec = AMQPFrameCodec()
    var open = AMQPFrameCodec.encode_method_frame(
        UInt16(0), UInt16(10), UInt16(40), bytes_of("vhost")^
    )
    check(client.send_bytes(open.copy()) == len(open), "send open frame")
    var oof = recv_one_frame(server, scodec)
    check(oof.frame_type == 1, "server saw a method frame")
    check(oof.channel == 0, "open is on channel 0")
    var ok = AMQPFrameCodec.encode_method_frame(
        UInt16(0), UInt16(10), UInt16(41), bytes_of("ok")^
    )
    check(server.value().send_bytes(ok.copy()) == len(ok), "server wrote open-ok")
    var okr = client.recv_bytes(4096)
    check(len(okr) > 0, "open-ok arrived")
    ccodec.feed_bytes(okr^)
    var cf = ccodec.try_parse_frame()
    check(cf.__bool__() and cf.value().frame_type == 1, "client decoded open-ok")

    # multi-buffer data echo: three separate writes, server reassembles.
    check(client.send_bytes(bytes_of("HELLO-")^) == 6, "write part 1")
    check(client.send_bytes(bytes_of("SOCKET-")^) == 7, "write part 2")
    check(client.send_bytes(bytes_of("WORLD")^) == 5, "write part 3")

    var acc = List[UInt8]()
    var reads = 0
    while len(acc) < 18:
        var chunk = server.value().recv_bytes(64)
        if len(chunk) == 0:
            raise "tcp data echo: EOF before all bytes"
        append_all(acc, chunk^)
        reads += 1
        if reads > 32:
            raise "tcp data echo: too many reads (deadlock guard)"
    check_bytes(acc, bytes_of("HELLO-SOCKET-WORLD"), "server reassembled")
    check(server.value().send_bytes(acc^) == 18, "server echoed all bytes")
    check_bytes(
        client.recv_exact(18), bytes_of("HELLO-SOCKET-WORLD"), "client read echo back"
    )

    server.value().close()
    client.close()
    listener.stop()


# ---------- case 1b: UDS round-trip ----------

def test_uds_roundtrip() raises:
    var path = String("/tmp/hyrx_sock_behavior_uds.sock")
    var listener = UDSListener(path.copy(), TransportConfig()^)
    check(listener.start(), "uds listener start")
    var client = UDSConnection.connect(path^)
    var server = listener.accept_connection()
    check(server.__bool__(), "uds server accepted")

    var frame = sample_body_frame()
    check(client.send_bytes(frame.copy()) == len(frame), "uds send frame")
    var got = server.value().recv_exact(len(frame))
    check_bytes(got, frame, "uds delivered exact bytes")

    var body = bytes_of("uds-round-trip")
    check(client.send_bytes(body.copy()) == len(body), "uds send body")
    var echoed = server.value().recv_exact(len(body))
    check(server.value().send_bytes(echoed^) == len(body), "uds echo")
    check_bytes(client.recv_exact(len(body)), body, "uds client read echo")

    server.value().close()
    client.close()
    listener.stop()


# ---------- case 2: partial frame in two writes with a gap ----------

def test_partial_frame_gap() raises:
    var listener = TCPListener("127.0.0.1", 0, TransportConfig()^)
    check(listener.start(), "listener start")
    var client = TCPConnection.connect("127.0.0.1", listener.port())
    var server = listener.accept_connection()
    check(server.__bool__(), "accepted")

    var frame = AMQPFrameCodec.encode_method_frame(
        UInt16(3), UInt16(50), UInt16(10), bytes_of("q")^
    )
    var half = 5
    var codec = AMQPFrameCodec()

    check(client.send_bytes(slice_bytes(frame.copy(), 0, half)^) == half, "write head")
    var r1 = server.value().recv_bytes(64)
    check(len(r1) == half, "only the head arrived")
    codec.feed_bytes(r1^)
    check(not codec.try_parse_frame().__bool__(), "no frame after partial head")

    var rest = slice_bytes(frame.copy(), half, len(frame))
    check(client.send_bytes(rest.copy()) == len(rest), "write tail (incl 0xCE)")
    var r2 = server.value().recv_bytes(64)
    codec.feed_bytes(r2^)
    var f = codec.try_parse_frame()
    check(f.__bool__(), "frame parses once tail (0xCE) arrives")
    check(f.value().frame_type == 1, "type intact")
    check(f.value().channel == 3, "channel intact")
    check(f.value().payload_size() == 4 + 1, "payload intact")

    server.value().close()
    client.close()
    listener.stop()


# ---------- case 3: one frame split across many 1-byte reads ----------

def test_frame_over_byte_reads() raises:
    var listener = TCPListener("127.0.0.1", 0, TransportConfig()^)
    check(listener.start(), "listener start")
    var client = TCPConnection.connect("127.0.0.1", listener.port())
    var server = listener.accept_connection()
    check(server.__bool__(), "accepted")

    var frame = sample_body_frame()
    check(client.send_bytes(frame.copy()) == len(frame), "wrote whole frame")
    var total = len(frame)
    var codec = AMQPFrameCodec()
    var parsed = 0
    for i in range(total):
        var one = server.value().recv_bytes(1)
        check(len(one) == 1, "one byte per read")
        codec.feed_bytes(one^)
        var f = codec.try_parse_frame()
        if f.__bool__():
            parsed += 1
            check(i == total - 1, "frame appears only on the final byte")
    check(parsed == 1, "exactly one frame parsed across the reads")
    check(not codec.try_parse_frame().__bool__(), "buffer empty after parse")

    server.value().close()
    client.close()
    listener.stop()


# ---------- case 4: multiple frames in one read ----------

def test_multiple_frames_one_read() raises:
    var listener = TCPListener("127.0.0.1", 0, TransportConfig()^)
    check(listener.start(), "listener start")
    var client = TCPConnection.connect("127.0.0.1", listener.port())
    var server = listener.accept_connection()
    check(server.__bool__(), "accepted")

    var wire = List[UInt8]()
    append_all(
        wire,
        AMQPFrameCodec.encode_method_frame(
            UInt16(1), UInt16(60), UInt16(40), bytes_of("m")^
        ),
    )
    append_all(wire, AMQPFrameCodec.encode_heartbeat(UInt16(0)))
    append_all(wire, sample_body_frame())

    check(client.send_bytes(wire.copy()) == len(wire), "single write, three frames")
    var codec = AMQPFrameCodec()
    var chunk = server.value().recv_bytes(4096)
    check(len(chunk) == len(wire), "all three frames arrived in one read")
    codec.feed_bytes(chunk^)

    var f1 = codec.try_parse_frame()
    var f2 = codec.try_parse_frame()
    var f3 = codec.try_parse_frame()
    check(f1.__bool__() and f2.__bool__() and f3.__bool__(), "three frames yielded")
    check(f1.value().frame_type == 1, "frame 1 is METHOD")
    check(f1.value().channel == 1, "frame 1 channel")
    check(f2.value().frame_type == 8, "frame 2 is HEARTBEAT (in order)")
    check(f3.value().frame_type == 3, "frame 3 is BODY (in order)")
    check(not codec.try_parse_frame().__bool__(), "no extra frame")

    server.value().close()
    client.close()
    listener.stop()


# ---------- case 5: zero-length payload (heartbeat) ----------

def test_zero_length_payload() raises:
    var listener = TCPListener("127.0.0.1", 0, TransportConfig()^)
    check(listener.start(), "listener start")
    var client = TCPConnection.connect("127.0.0.1", listener.port())
    var server = listener.accept_connection()
    check(server.__bool__(), "accepted")

    var hb = AMQPFrameCodec.encode_heartbeat(UInt16(0))
    check(len(hb) == 8, "heartbeat is 8 bytes (size 0)")
    check(client.send_bytes(hb^) == 8, "sent heartbeat")
    var codec = AMQPFrameCodec()
    codec.feed_bytes(server.value().recv_exact(8)^)
    var f = codec.try_parse_frame()
    check(f.__bool__(), "zero-length frame parses")
    check(f.value().frame_type == 8, "type is HEARTBEAT")
    check(f.value().payload_size() == 0, "payload is zero-length")

    server.value().close()
    client.close()
    listener.stop()


# ---------- case 6: abrupt disconnect (partial frame then close) ----------

def test_abrupt_disconnect() raises:
    var listener = TCPListener("127.0.0.1", 0, TransportConfig()^)
    check(listener.start(), "listener start")
    var client = TCPConnection.connect("127.0.0.1", listener.port())
    var server = listener.accept_connection()
    check(server.__bool__(), "accepted")

    var frame = sample_body_frame()
    check(client.send_bytes(slice_bytes(frame.copy(), 0, 4)^) == 4, "sent partial frame")
    client.close()  # abrupt: partial frame, then FIN

    var codec = AMQPFrameCodec()
    var head = server.value().recv_bytes(64)
    check(len(head) == 4, "partial bytes delivered before EOF")
    codec.feed_bytes(head^)
    check(not codec.try_parse_frame().__bool__(), "partial frame yields no frame (no crash)")
    var after = server.value().recv_bytes(64)
    check(len(after) == 0, "read after peer close returns EOF (0 bytes), clean")
    check(not codec.try_parse_frame().__bool__(), "still no frame; no hang, no crash")

    server.value().close()
    listener.stop()


# ---------- case 7: peer termination after full exchange ----------

def test_termination_after_exchange() raises:
    var listener = TCPListener("127.0.0.1", 0, TransportConfig()^)
    check(listener.start(), "listener start")
    var client = TCPConnection.connect("127.0.0.1", listener.port())
    var server = listener.accept_connection()
    check(server.__bool__(), "accepted")

    var frame = sample_body_frame()
    check(client.send_bytes(frame.copy()) == len(frame), "sent a full frame")
    var codec = AMQPFrameCodec()
    var f = recv_one_frame(server, codec)
    check(f.frame_type == 3, "full frame decoded before termination")

    client.close()  # graceful: after full exchange
    var eof = server.value().recv_bytes(64)
    check(len(eof) == 0, "peer termination observed as EOF")

    server.value().close()
    listener.stop()


def main() raises:
    test_tcp_roundtrip()
    test_uds_roundtrip()
    test_partial_frame_gap()
    test_frame_over_byte_reads()
    test_multiple_frames_one_read()
    test_zero_length_payload()
    test_abrupt_disconnect()
    test_termination_after_exchange()
    print("SOCKET_BEHAVIOR_PASS")
