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

from std.ffi import OwnedDLHandle, c_int
from std.collections import List, Optional

from flare.tcp import TcpListener, TcpStream
from flare.net import IpAddr, SocketAddr, _find_flare_lib
from flare.runtime._libc_time import libc_nanosleep_ms
from flare.tls._server_ffi import (
    ServerCtx,
    server_ssl_new_accept,
    server_ssl_do_handshake,
    server_ssl_free,
)
from flare.utils.dylib import dl_sym

from hyrx.transport.transport import TransportConfig, TransportConnection, AMQPConn


def _socket_addr(host: String, port: Int) raises -> SocketAddr:
    """Build a flare SocketAddr from a dotted-quad host and a port."""
    return SocketAddr(IpAddr.parse(host), UInt16(port))


# ── blocking OpenSSL I/O (server-side, same seam as wss.mojo) ───────────

def _ssl_read_block(
    read lib: OwnedDLHandle,
    ssl: Int,
    buf: UnsafePointer[UInt8, _],
    want: Int,
) raises -> Int:
    var f = dl_sym[def(Int, Int, c_int) thin abi("C") -> c_int](
        lib, "flare_ssl_read"
    )
    return Int(f(ssl, Int(buf), c_int(want)))


def _ssl_write_block(
    read lib: OwnedDLHandle,
    ssl: Int,
    buf: UnsafePointer[UInt8, _],
    want: Int,
) raises -> Int:
    var f = dl_sym[def(Int, Int, c_int) thin abi("C") -> c_int](
        lib, "flare_ssl_write"
    )
    return Int(f(ssl, Int(buf), c_int(want)))


def _ssl_shutdown_block(read lib: OwnedDLHandle, ssl: Int) raises -> Int:
    var f = dl_sym[def(Int) thin abi("C") -> c_int](lib, "flare_ssl_shutdown")
    return Int(f(ssl))


def _ssl_free_block(read lib: OwnedDLHandle, ssl: Int) raises:
    var f = dl_sym[def(Int) thin abi("C") -> None](lib, "flare_ssl_free")
    f(ssl)


struct TCPListener:
    """Binds to host:port and accepts TCP connections.

    Optional TLS: when a ``TlsServerConfig`` is supplied via
    ``set_tls_config()``, every accepted connection is wrapped with
    OpenSSL TLS before being returned. Plaintext remains the default
    when no TLS config is set (byte-identical to pre-TLS behavior)."""

    var _host: String
    var _port: Int
    var _listening: Bool
    var _config: TransportConfig
    var _next_conn_id: UInt64
    var _listener: Optional[TcpListener]
    var _tls_ctx: Optional[ServerCtx]

    def __init__(out self, host: String, port: Int, var config: TransportConfig):
        self._host = host
        self._port = port
        self._listening = False
        self._config = config^
        self._next_conn_id = 1
        self._listener = Optional[TcpListener]()
        self._tls_ctx = Optional[ServerCtx]()

    def set_tls_config(mut self, cert_path: String, key_path: String) raises:
        """Configure TLS for accepted connections. Must be called before
        start(). The cert and key are loaded into an OpenSSL SSL_CTX here
        so the per-accept handshake is cheap."""
        self._tls_ctx = ServerCtx.new(cert_path, key_path)^

    def has_tls(ref self) -> Bool:
        """True when TLS is configured (accepted connections will be wrapped)."""
        return self._tls_ctx.__bool__()

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
        connected (bind -> connect -> accept).

        When TLS is configured, the accepted fd is wrapped with OpenSSL
        before returning (the TLS handshake completes here, blocking)."""
        if not self._listener.__bool__():
            raise "TCPListener.accept_connection: listener not started"
        var stream = self._listener.value().accept()
        var id = self._next_conn_id
        self._next_conn_id += 1
        var ssl_addr = Int(0)
        if self._tls_ctx.__bool__():
            ssl_addr = server_ssl_new_accept(
                self._tls_ctx.value(), Int(stream.as_raw_fd())
            )
            if ssl_addr == 0:
                stream.close()
                return Optional[TCPConnection]()
            var steps = Int(0)
            while True:
                var rc = server_ssl_do_handshake(
                    self._tls_ctx.value(), ssl_addr
                )
                if rc == 0:
                    break
                if rc < 0:
                    try:
                        _ = server_ssl_free(self._tls_ctx.value(), ssl_addr)
                    except:
                        pass
                    stream.close()
                    return Optional[TCPConnection]()
                steps += 1
                if steps >= 10000:
                    try:
                        _ = server_ssl_free(self._tls_ctx.value(), ssl_addr)
                    except:
                        pass
                    stream.close()
                    return Optional[TCPConnection]()
                _ = libc_nanosleep_ms(1)
        var conn = TCPConnection(stream^, id, ssl_addr)
        return Optional[TCPConnection](conn^)

    def accept_fd(ref self) raises -> Int:
        """The underlying listening socket fd (event-driven serving).

        Borrowed fd: TcpListener owns the close. Only valid once
        ``start()`` succeeded."""
        if not self._listener.__bool__():
            raise "TCPListener.accept_fd: listener not started"
        return Int(self._listener.value().as_raw_fd())


struct TCPConnection(Movable, AMQPConn):
    """A TCP connection carrying Hyrx messages.

    Optional TLS: when ``_ssl != 0``, every I/O operation is routed
    through OpenSSL. Plaintext (``_ssl == 0``) is the default —
    byte-identical to the pre-TLS path."""

    var _base: TransportConnection
    var _stream: TcpStream
    var _ssl: Int  # flare_ssl_t server handle; 0 = plain TCP
    var _lib: OwnedDLHandle  # FFI handle for TLS I/O (valid when _ssl != 0)

    def __init__(
        out self,
        var stream: TcpStream,
        conn_id: UInt64,
        ssl_addr: Int = 0,
        lib_handle: Int = 0,
    ) raises:
        """Adopt an already-open stream (connected or accepted).

        ``ssl_addr != 0`` means TLS is active; ``lib_handle`` is the
        raw pointer to ``libflare_tls.so`` (ignored when ssl_addr == 0)."""
        self._base = TransportConnection(conn_id)
        self._stream = stream^
        self._ssl = ssl_addr
        if lib_handle != 0:
            self._lib = OwnedDLHandle(lib_handle)
        else:
            self._lib = OwnedDLHandle(_find_flare_lib())

    @staticmethod
    def connect(host: String, port: Int) raises -> TCPConnection:
        """Connect to a remote TCP endpoint (plaintext only)."""
        var addr = _socket_addr(host, port)
        var stream = TcpStream.connect(addr)
        return TCPConnection(stream^, 0)

    def conn_id(ref self) -> UInt64:
        return self._base.id()

    def poll_fd(ref self) -> Int:
        """Raw stream fd for the readiness registry (event-driven serving).

        Borrowed: TcpStream owns the close. Reuses flare's own accessor —
        no duplicate fd plumbing.

        NOTE: on a TLS connection this yields the plaintext fd; the
        event-driven dose reads raw bytes (ciphertext on a TLS carrier).
        The TLS tier therefore refuses the event-driven loop (the WSS
        pattern — legacy blocking reads through send_bytes/recv_bytes
        are the correct seam)."""
        return Int(self._stream.as_raw_fd())

    def send_bytes(mut self, var data: List[UInt8]) raises -> Int:
        """Write every byte of ``data``. Returns bytes sent.

        Routes through OpenSSL when TLS is active."""
        var n = len(data)
        if n == 0:
            return 0
        if self._ssl != 0:
            var sent = 0
            while sent < n:
                var chunk = Span[UInt8, _](
                    unsafe_ptr=data.unsafe_ptr() + sent, length=n - sent
                )
                var wrote = _ssl_write_block(self._lib, self._ssl, data.unsafe_ptr() + sent, n - sent)
                if wrote <= 0:
                    raise "TCPConnection.send_bytes: TLS write failed"
                sent += wrote
            return n
        self._stream.write_all(Span[UInt8, _](data))
        return n

    def recv_bytes(mut self, max_bytes: Int) raises -> List[UInt8]:
        """One read of up to ``max_bytes`` bytes.

        May return fewer bytes than requested; an empty result means EOF.
        Routes through OpenSSL when TLS is active."""
        if max_bytes <= 0:
            return List[UInt8]()
        var buf = List[UInt8](unsafe_uninit_length=max_bytes)
        var got: Int
        if self._ssl != 0:
            got = _ssl_read_block(self._lib, self._ssl, buf.unsafe_ptr(), max_bytes)
            if got == 0:
                return List[UInt8]()
            if got < 0:
                raise "TCPConnection.recv_bytes: TLS read failed"
        else:
            got = self._stream.read(buf.unsafe_ptr(), max_bytes)
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
        """Close the connection.

        Sends TLS close_notify when TLS is active, then closes the
        underlying TCP stream."""
        if self._ssl != 0:
            try:
                _ = _ssl_shutdown_block(self._lib, self._ssl)
            except:
                pass
            try:
                _ssl_free_block(self._lib, self._ssl)
            except:
                pass
            self._ssl = 0
        self._stream.close()
        self._base.disconnect()

    def is_connected(ref self) -> Bool:
        return self._base.is_connected()
