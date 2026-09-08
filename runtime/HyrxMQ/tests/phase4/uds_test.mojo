# Tests for UDS transport lifecycle over a real loopback socket.
#
# The socket is flare-backed (vendor/flare). Single-threaded ordering is
# bind -> connect -> accept: the kernel backlog holds the client's connect()
# until accept() runs, so no thread is needed and nothing can block forever.
# Messages stay small so writes never wait on a full socket buffer.

from std.collections import List, Optional

from hyrx.transport.transport import TransportConfig
from hyrx.transport.uds import UDSListener, UDSConnection


def check(cond: Bool, var msg: String) raises:
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
        raise "FAIL: " + msg + " (len " + String(len(got)) + " != " + String(len(want)) + ")"
    for i in range(len(want)):
        if got[i] != want[i]:
            raise "FAIL: " + msg + " (byte " + String(i) + ")"


def test_listener_lifecycle() raises:
    var config = TransportConfig()
    var path = String("/tmp/hyrx_uds_lifecycle.sock")
    var listener = UDSListener(path, config^)
    check(not listener.is_listening(), "L20 not listening before start")

    var ok = listener.start()
    check(ok, "L23 start")
    check(listener.is_listening(), "L24 listening after start")
    check(listener.path() == path, "L25 path preserved")

    listener.stop()
    check(not listener.is_listening(), "L28 not listening after stop")
    print("  listener lifecycle: OK")


def test_loopback_roundtrip() raises:
    var config = TransportConfig()
    var path = String("/tmp/hyrx_uds_loopback.sock")
    var listener = UDSListener(path, config^)
    check(listener.start(), "L37 start")

    var client = UDSConnection.connect(path^)
    check(client.is_connected(), "L39 client connected")

    var pending = listener.accept_connection()
    check(pending.__bool__(), "L42 accept returned a connection")
    check(pending.value().is_connected(), "L43 accepted connection is live")

    var payload = bytes_of("hello")
    var sent = client.send_bytes(payload.copy())
    check(sent == 5, "L47 client send count")

    var got = pending.value().recv_exact(5)
    check_bytes(got, payload, "L50 server received")

    # Echo back over the same accepted connection.
    var echoed = pending.value().send_bytes(got.copy())
    check(echoed == 5, "L55 server echo count")
    var back = client.recv_exact(5)
    check_bytes(back, bytes_of("hello"), "L57 client received echo")

    client.close()
    check(not client.is_connected(), "L60 client closed")
    pending.value().close()
    check(not pending.value().is_connected(), "L62 server closed")

    listener.stop()
    print("  loopback roundtrip: OK")


def test_short_read_then_remainder() raises:
    var config = TransportConfig()
    var path = String("/tmp/hyrx_uds_shortread.sock")
    var listener = UDSListener(path, config^)
    check(listener.start(), "L72 start")

    var client = UDSConnection.connect(path^)
    var pending = listener.accept_connection()
    check(pending.__bool__(), "L76 accept")

    var sent = client.send_bytes(bytes_of("abcdefg"))
    check(sent == 7, "L79 send")
    var first = pending.value().recv_bytes(3)
    check(len(first) > 0, "L81 first read non-empty")
    var rest = pending.value().recv_exact(7 - len(first))
    check(len(first) + len(rest) == 7, "L83 reassembled full message")

    pending.value().close()
    client.close()
    listener.stop()
    print("  short read + reassembly: OK")


def main() raises:
    print("UDS_TEST")
    test_listener_lifecycle()
    test_loopback_roundtrip()
    test_short_read_then_remainder()
    print("UDS_TEST=PASS")
