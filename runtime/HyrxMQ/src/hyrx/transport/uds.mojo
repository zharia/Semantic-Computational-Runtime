# Unix domain socket transport for Hyrx.
#
# Provides same-host IPC via UDS, backed by the vendored flare library
# (vendor/flare, ADR-0005). Real sockets: bind/accept/connect/read/write_all
# all reach the kernel.
#
# flare is confined to the transport layer by design — nothing under
# src/hyrx/core, src/hyrx/embedded or src/hyrxmq may import it. The unsafe
# buffer construction needed by flare's read/write API lives only in this file
# and in tcp.mojo.

from std.collections import List, Optional

from flare.uds import UnixListener, UnixStream

from hyrx.transport.transport import TransportConfig, TransportConnection, AMQPConn


struct UDSListener:
    """Listens on a Unix domain socket path."""

    var _path: String
    var _listening: Bool
    var _config: TransportConfig
    var _next_conn_id: UInt64
    var _listener: Optional[UnixListener]

    def __init__(out self, var path: String, var config: TransportConfig):
        self._path = path^
        self._listening = False
        self._config = config^
        self._next_conn_id = 1
        self._listener = Optional[UnixListener]()

    def start(mut self) raises -> Bool:
        """Bind and start listening. Returns True on success.

        A stale socket file from a crashed run is removed by
        ``UnixListener.bind`` (``unlink_existing=True``), so rebinding the
        same path succeeds without extra cleanup here."""
        var bound = UnixListener.bind(self._path)
        self._listener = bound^
        self._listening = True
        return True

    def stop(mut self):
        """Stop listening, close the socket and unlink the path."""
        self._listening = False
        if self._listener.__bool__():
            self._listener.value().close()
        # Dropping the UnixListener runs its __deinit__, which unlinks the
        # socket path.
        self._listener = Optional[UnixListener]()

    def is_listening(ref self) -> Bool:
        return self._listening

    def path(ref self) -> String:
        return self._path

    def config(ref self) -> TransportConfig:
        return self._config

    def accept_connection(mut self) raises -> Optional[UDSConnection]:
        """Accept the next pending connection.

        Blocks until a client connects, so call it only after a client has
        connected (bind -> connect -> accept)."""
        if not self._listener.__bool__():
            raise "UDSListener.accept_connection: listener not started"
        var stream = self._listener.value().accept()
        var id = self._next_conn_id
        self._next_conn_id += 1
        var conn = UDSConnection(stream^, id)
        return Optional[UDSConnection](conn^)

    def accept_fd(ref self) raises -> Int:
        """The underlying listening socket fd (event-driven serving).

        Borrowed fd: UnixListener owns the close. Only valid once
        ``start()`` succeeded."""
        if not self._listener.__bool__():
            raise "UDSListener.accept_fd: listener not started"
        return Int(self._listener.value().as_raw_fd())


struct UDSConnection(Movable, AMQPConn):
    """A Unix domain socket connection carrying Hyrx bytes.

    Path conventions: a ``path`` that starts with ``@`` (e.g.
    ``@hyrxmq_bench_abstract``) binds/connects in the Linux
    *abstract namespace* — ``flare.uds._libc.fill_sockaddr_un``
    encodes ``sun_path[0] = 0`` plus the name octets, no socket
    file is created and ``unlink`` is a silent no-op there.
    Abstract sockets are a Linux-only kernel feature; flare raises
    ``Error`` for ``@name`` paths on macOS/BSD. Any other ``path``
    is a regular filesystem pathname socket and behaves exactly as
    before — nothing else about the UDS transport changes.
    """

    var _base: TransportConnection
    var _stream: UnixStream

    def __init__(out self, var stream: UnixStream, conn_id: UInt64):
        """Adopt an already-open stream (connected or accepted)."""
        self._base = TransportConnection(conn_id)
        self._stream = stream^

    @staticmethod
    def connect(var path: String) raises -> UDSConnection:
        """Connect to a UDS listener bound at ``path``."""
        var stream = UnixStream.connect(path^)
        return UDSConnection(stream^, 0)

    def conn_id(ref self) -> UInt64:
        return self._base.id()

    def poll_fd(ref self) -> Int:
        """Raw stream fd for the readiness registry (event-driven serving).

        Borrowed: UnixStream owns the close. Reuses flare's own accessor —
        no duplicate fd plumbing."""
        return Int(self._stream.as_raw_fd())

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
        var buf = List[UInt8](unsafe_uninit_length=max_bytes)
        var got = self._stream.read(buf.unsafe_ptr(), max_bytes)
        if got == max_bytes:
            return buf^
        if got <= 0:
            return List[UInt8]()
        buf.resize(unsafe_uninit_length=got)
        return buf^

    def recv_exact(mut self, n: Int) raises -> List[UInt8]:
        """Read until exactly ``n`` bytes are collected. Raises on EOF."""
        var out = List[UInt8]()
        while len(out) < n:
            var chunk = self.recv_bytes(n - len(out))
            if len(chunk) == 0:
                raise (
                    "UDSConnection.recv_exact: EOF after "
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
