# Tests for TCP transport lifecycle over a real loopback socket.
#
# The socket is flare-backed (vendor/flare). Single-threaded ordering is
# bind -> connect -> accept: the kernel backlog holds the client's connect()
# until accept() runs, so no thread is needed and nothing can block forever.
# Messages stay small so writes never wait on a full socket buffer.
#
# TCPClient was dropped with the flare rewrite: TCPConnection.connect is the
# client entry point.

from std.collections import List, Optional

from hyrx.transport.transport import TransportConfig
from hyrx.transport.tcp import TCPListener, TCPConnection


from hyrx.testing import check

def bytes_of(s: String) -> List[UInt8]:
    """UTF-8 bytes of a short ASCII string."""
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


def test_listener_lifecycle() raises:
    var config = TransportConfig()
    var listener = TCPListener("127.0.0.1", 0, config^)
    check(not listener.is_listening(), "L36 not listening before start")

    check(listener.start(), "L38 start")
    check(listener.is_listening(), "L39 listening after start")
    check(listener.host() == "127.0.0.1", "L40 host")

    # Port 0 asked the kernel for an ephemeral port; port() reports the real one.
    var actual = listener.port()
    check(actual > 0, "L44 ephemeral port assigned")
    check(actual <= 65535, "L45 port in range")

    listener.stop()
    check(not listener.is_listening(), "L48 not listening after stop")
    print("  listener lifecycle: OK")


def test_loopback_roundtrip() raises:
    var config = TransportConfig()
    var listener = TCPListener("127.0.0.1", 0, config^)
    check(listener.start(), "L56 start")
    var port = listener.port()

    var client = TCPConnection.connect("127.0.0.1", port)
    check(client.is_connected(), "L60 client connected")

    var pending = listener.accept_connection()
    check(pending.__bool__(), "L63 accept returned a connection")
    check(pending.value().conn_id() > 0, "L64 accepted connection has an id")

    var payload = bytes_of("hello")
    check(client.send_bytes(payload.copy()) == 5, "L67 client send count")

    var got = pending.value().recv_exact(5)
    check_bytes(got, payload, "L70 server received")

    # Echo back over the same accepted connection.
    check(pending.value().send_bytes(got.copy()) == 5, "L74 server echo count")
    check_bytes(client.recv_exact(5), bytes_of("hello"), "L75 client received echo")

    client.close()
    check(not client.is_connected(), "L78 client closed")
    pending.value().close()
    check(not pending.value().is_connected(), "L80 server closed")

    listener.stop()
    print("  loopback roundtrip: OK")


def test_short_read_then_remainder() raises:
    var config = TransportConfig()
    var listener = TCPListener("127.0.0.1", 0, config^)
    check(listener.start(), "L89 start")
    var port = listener.port()

    var client = TCPConnection.connect("127.0.0.1", port)
    var pending = listener.accept_connection()
    check(pending.__bool__(), "L93 accept")

    check(client.send_bytes(bytes_of("abcdefg")) == 7, "L95 send")
    var first = pending.value().recv_bytes(3)
    check(len(first) > 0, "L97 first read non-empty")
    var rest = pending.value().recv_exact(7 - len(first))
    check(len(first) + len(rest) == 7, "L99 reassembled full message")

    pending.value().close()
    client.close()
    listener.stop()
    print("  short read + reassembly: OK")


def test_multiple_connections() raises:
    var config = TransportConfig()
    var listener = TCPListener("127.0.0.1", 0, config^)
    check(listener.start(), "L108 start")
    var port = listener.port()

    var c1 = TCPConnection.connect("127.0.0.1", port)
    var s1 = listener.accept_connection()
    var c2 = TCPConnection.connect("127.0.0.1", port)
    var s2 = listener.accept_connection()
    check(s1.__bool__() and s2.__bool__(), "L114 both accepted")
    check(s1.value().conn_id() != s2.value().conn_id(), "L115 distinct ids")

    check(c1.send_bytes(bytes_of("one")) == 3, "L117 c1 send")
    check(c2.send_bytes(bytes_of("two")) == 3, "L118 c2 send")
    check_bytes(s1.value().recv_exact(3), bytes_of("one"), "L119 s1 received")
    check_bytes(s2.value().recv_exact(3), bytes_of("two"), "L120 s2 received")

    s1.value().close()
    c1.close()
    check(not c1.is_connected(), "L123 c1 closed")
    check(s2.value().is_connected(), "L124 s2 still open")
    s2.value().close()
    c2.close()
    check(not c2.is_connected(), "L126 c2 closed")

    listener.stop()
    print("  multiple connections: OK")


def main() raises:
    print("TCP_TEST")
    test_listener_lifecycle()
    test_loopback_roundtrip()
    test_short_read_then_remainder()
    test_multiple_connections()
    print("TCP_TEST=PASS")
