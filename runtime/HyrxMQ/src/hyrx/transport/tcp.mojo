# TCP transport for Hyrx networking.
#
# Baseline external transport over TCP/IP, backed by the vendored flare
# library (vendor/flare, ADR-0005). Real sockets: bind/accept/connect/
# read/write_all all reach the kernel.
#
# flare is confined to the transport layer by design — nothing under
# src/hyrx/core, src/hyrx/embedded or src/hyrxmq may import it. The unsafe
# buffer construction needed by flare's read/write API lives only in this file
# and in uds.mojo.

from std.collections import List, Optional

from flare.tcp import TcpListener, TcpStream
from flare.net import IpAddr, SocketAddr

from hyrx.transport.transport import TransportConfig, TransportConnection


def _zeroed(n: Int) -> List[UInt8]:
    """Zero-filled byte storage used as a read target."""
    var b = List[UInt8]()
    b.resize(n, 0)
    return b^


def _socket_addr(host: String, port: Int) raises -> SocketAddr:
    """Build a flare SocketAddr from a dotted-quad host and a port."""
    return SocketAddr(IpAddr.parse(host), UInt16(port))


struct TCPListener:
    """Binds to host:port and accepts TCP connections."""

    var _host: String
    var _port: Int
    var _listening: Bool
    var _config: TransportConfig
    var _next_conn_id: UInt64
    var _listener: Optional[TcpListener]

    def __init__(out self, host: String, port: Int, var config: TransportConfig):
        self._host = host
        self._port = port
        self._listening = False
        self._config = config^
        self._next_conn_id = 1
        self._listener = Optional[TcpListener]()

    def start(mut self) raises -> Bool:
        """Bind and listen. Returns True on success.

        ``port == 0`` asks the kernel for an ephemeral port; read it back
        with :meth:`port`."""
        var addr = _socket_addr(self._host, self._port)
        var bound = TcpListener.bind(addr)
        self._listener = bound^
        self._listening = True
        return True

    def stop(mut self):
        """Stop listening and close the socket."""
        self._listening = False
        if self._listener.__bool__():
            self._listener.value().close()
        self._listener = Optional[TcpListener]()

    def is_listening(ref self) -> Bool:
        return self._listening

    def host(ref self) -> String:
        return self._host

    def config(ref self) -> TransportConfig:
        return self._config

    def port(mut self) raises -> Int:
        """The actual bound port (reflects the ephemeral port when bound
        with ``port == 0``)."""
        if not self._listener.__bool__():
            raise "TCPListener.port: listener not started"
        return Int(self._listener.value().local_addr().port)

    def accept_connection(mut self) raises -> Optional[TCPConnection]:
        """Accept the next pending connection.

        Blocks until a client connects, so call it only after a client has
        connected (bind -> connect -> accept)."""
        if not self._listener.__bool__():
            raise "TCPListener.accept_connection: listener not started"
        var stream = self._listener.value().accept()
        var id = self._next_conn_id
        self._next_conn_id += 1
        var conn = TCPConnection(stream^, id)
        return Optional[TCPConnection](conn^)


struct TCPConnection(Movable):
    """A TCP connection carrying Hyrx messages."""

    var _base: TransportConnection
    var _stream: TcpStream

    def __init__(out self, var stream: TcpStream, conn_id: UInt64):
        """Adopt an already-open stream (connected or accepted)."""
        self._base = TransportConnection(conn_id)
        self._stream = stream^

    @staticmethod
    def connect(host: String, port: Int) raises -> TCPConnection:
        """Connect to a remote TCP endpoint."""
        var addr = _socket_addr(host, port)
        var stream = TcpStream.connect(addr)
        return TCPConnection(stream^, 0)

    def conn_id(ref self) -> UInt64:
        return self._base.id()

    def send_bytes(mut self, var data: List[UInt8]) raises -> Int:
        """Write every byte of ``data``. Returns bytes sent."""
        var n = len(data)
        if n == 0:
            return 0
        self._stream.write_all(Span[UInt8, _](data))
        return n

    def recv_bytes(mut self, max_bytes: Int) raises -> List[UInt8]:
        """One read of up to ``max_bytes`` bytes.

        May return fewer bytes than requested; an empty result means EOF."""
        if max_bytes <= 0:
            return List[UInt8]()
        var buf = _zeroed(max_bytes)
        var got = self._stream.read(buf.unsafe_ptr(), max_bytes)
        var out = List[UInt8]()
        for i in range(got):
            out.append(buf[i])
        return out^

    def recv_exact(mut self, n: Int) raises -> List[UInt8]:
        """Read until exactly ``n`` bytes are collected. Raises on EOF."""
        var out = List[UInt8]()
        while len(out) < n:
            var chunk = self.recv_bytes(n - len(out))
            if len(chunk) == 0:
                raise (
                    "TCPConnection.recv_exact: EOF after "
                    + String(len(out))
                    + " of "
                    + String(n)
                    + " bytes"
                )
            for i in range(len(chunk)):
                out.append(chunk[i])
        return out^

    def close(mut self):
        """Close the connection."""
        self._stream.close()
        self._base.disconnect()

    def is_connected(ref self) -> Bool:
        return self._base.is_connected()
