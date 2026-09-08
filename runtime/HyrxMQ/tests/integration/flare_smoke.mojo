# Flare vendored-dependency smoke test (ADR-0005).
#
# Proves that the pinned flare submodule (v0.10.0) compiles and performs a
# real TCP loopback echo and a real Unix-domain-socket echo inside this
# project, using only `-I src -I vendor/flare` and no build backend.
#
# Strategy (from spike): single-threaded bind -> connect -> accept. The
# kernel's pending-connection backlog holds the connect until accept(), so
# no threads are required for the loopback round-trips.

from std.testing import assert_equal
from flare.tcp import TcpListener, TcpStream
from flare.net import SocketAddr
from flare.uds import UnixListener, UnixStream


def zero_buf(n: Int) -> List[UInt8]:
    var b = List[UInt8]()
    b.resize(n, 0)
    return b^


def tcp_echo() raises:
    var listener = TcpListener.bind(SocketAddr.localhost(0))
    var port = listener.local_addr().port
    assert_equal(UInt16(0) != port, True)

    var client = TcpStream.connect(SocketAddr.localhost(port))
    var server = listener.accept()

    var msg = String("hyrx-flare-tcp-echo")
    client.write_all(Span[UInt8](msg.as_bytes()))

    var buf = zero_buf(64)
    var n = server.read(buf.unsafe_ptr(), len(buf))
    var received = String(unsafe_from_utf8=buf[:n])
    assert_equal(received, msg)

    server.write_all(Span[UInt8](buf[:n]))
    var echo_buf = zero_buf(64)
    var n2 = client.read(echo_buf.unsafe_ptr(), len(echo_buf))
    var echoed = String(unsafe_from_utf8=echo_buf[:n2])
    assert_equal(echoed, msg)

    client.close()
    server.close()
    listener.close()


def uds_echo() raises:
    var path = String("/tmp/hyrx_flare_smoke.sock")
    var listener = UnixListener.bind(path)

    var client = UnixStream.connect(path)
    var server = listener.accept()

    var msg = String("hyrx-flare-uds-echo")
    client.write_all(Span[UInt8](msg.as_bytes()))

    var buf = zero_buf(64)
    var n = server.read(buf.unsafe_ptr(), len(buf))
    var received = String(unsafe_from_utf8=buf[:n])
    assert_equal(received, msg)

    server.write_all(Span[UInt8](buf[:n]))
    var echo_buf = zero_buf(64)
    var n2 = client.read(echo_buf.unsafe_ptr(), len(echo_buf))
    var echoed = String(unsafe_from_utf8=echo_buf[:n2])
    assert_equal(echoed, msg)

    client.close()
    server.close()
    listener.close()


def main() raises:
    tcp_echo()
    uds_echo()
    print("FLARE_SMOKE_PASS")
