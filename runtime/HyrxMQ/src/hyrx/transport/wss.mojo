# WSS transport (0023 T1/T2): WebSocket + TLS carrier for the Hyrx byte
# interface.
#
# Design (0023 plan.md, ADR-0005 containment): flare is confined to the
# transport layer — nothing under src/hyrx/core, src/hyrx/embedded or
# src/hyrxmq may import it, so this file carries ALL of the ws/tls vendor
# wiring the browser tier needs.
#
# Semantics — the CONTRACT is byte-stream. `send_bytes` relays ONE WS
# binary message per call containing ALL the bytes handed over (the
# listener's send path is per-AMQP-frame today); `recv_bytes` drains
# complete WS frames into the connection-internal payload buffer and
# returns exactly the requested prefix, keeping leftover bytes buffered
# so multi-frame WS payloads and streamed partial frames work (the AMQP
# codec reassembles across arbitrary chunk boundaries — routing
# semantics are unchanged).
#
# RFC 7395 binding: the upgrade handshake requires
# `Sec-WebSocket-Protocol: amqp` (a request offering only other
# subprotocols is rejected with the normative HTTP 400 row); the
# resource must be `/ws` (anything else → HTTP 404). RFC 6455
# accept-key math is NOT reimplemented — `flare.ws.server` already
# carries the SHA-1 + base64 helper over libflare_tls and it is reused
# directly.
#
# Origin policy (0023, user directive): ALLOW-ALL BY DEFAULT. THIS IS
# EXTENSIBLE — add origins to `WssConfig.origin_allowlist` (with
# `allow_all = False`) for browser-safe enforcement: any `Origin:`
# header not in the list is closed with the normative HTTP 403 row.
#
# Cert models (0023): "injected" = PEM bytes in the config struct (zero
# fs); "path" = cert/key FILES, pre-validated exactly once through the
# injected `FileSystemOps` seam and then handed to the OpenSSL
# lifecycle (see the NEEDS-PROBE note on WSSListener.start for why the
# bytes variant cannot load in this vendor snapshot).
#
# NO fs WRITE anywhere: path mode is reads only (`ops.read_all`);
# injected mode never touches the fs at all.

from std.ffi import OwnedDLHandle, c_int
from std.memory import UnsafePointer
from std.collections import List, Optional

from flare.net import IpAddr, SocketAddr, _find_flare_lib
from flare.runtime._libc_time import libc_nanosleep_ms
from flare.tcp import TcpListener, TcpStream

from flare.utils.dylib import dl_sym
from flare.tls._server_ffi import (
    ServerCtx,
    server_ssl_do_handshake,
    server_ssl_free,
    server_ssl_new_accept,
)
from flare.ws.frame import WsCloseCode, WsFrame, WsOpcode
from flare.ws.server import _compute_accept_srv

from hyrx.transport.transport import (
    TransportConfig,
    TransportConnection,
    AMQPConn,
)
from hyrx.core.storage import FileSystemOps


def WSS_TLS_MODE_NONE() -> String:
    """No TLS carrier (plain ws://). The BROKER tier refuses this (0023:
    no cert source configured => the wss tier does not start)."""
    return "none"


def WSS_TLS_MODE_INJECTED() -> String:
    """PEM bytes in config (zero fs). NEEDS-PROBE: WSSListener.start."""
    return "injected"


def WSS_TLS_MODE_PATH() -> String:
    """Cert/key FILES, pre-read once through the injected fs seam."""
    return "path"


# Cap on one WS payload (0023): an AMQP frame is bounded by frame_max;
# a WS payload above this cap cannot be a well-formed AMQP frame and is
# refused instead of being buffered unboundedly.
def _MAX_WS_PAYLOAD() -> Int:
    return 16777216


# Blocking handshake deadline (server-side TLS): bounded 1 ms-poll steps
# before a stalled client's handshake is abandoned (per-connection
# damage only, same containment class as SERVE_FAILED).
def _HANDSHAKE_DEADLINE_STEPS() -> Int:
    return 10000


# ── raw OpenSSL blocking I/O (the ONE libflare_tls seam here) ─────────────
#
# Same exports TlsStream binds (flare_ssl_read / flare_ssl_write /
# flare_ssl_shutdown / flare_ssl_free): the server-side handle produced
# by flare_ssl_new_accept is the same `flare_ssl_t`, so the blocking
# lifecycle + I/O wrappers are valid on accepted connections too. No
# vendored-C change is involved. These are the BLOCKING SSL wrappers —
# exactly the read/write semantics the AMQPConn byte contract needs
# (0 = clean close_notify EOF, <0 = hard error).

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


# ── WssConfig ─────────────────────────────────────────────────────────────

struct WssConfig:
    """One WSS endpoint's policy (0023).

    ``port == 0`` means the tier is OFF (the default — no listener, zero
    new connections, all existing tiers byte-identical).

    Origin policy: ``allow_all == True`` is the DEFAULT. THIS IS
    EXTENSIBLE — add origins to ``origin_allowlist`` (with
    ``allow_all = False``) for browser-safe enforcement: any ``Origin:``
    header not in the list is closed with the normative HTTP 403 row.
    """

    var host: String
    var port: Int
    var tls_mode: String  # WSS_TLS_MODE_* : "none" | "injected" | "path"
    # Injected cert model: PEM bytes held in memory (zero fs).
    var cert_pem_bytes: List[UInt8]
    var key_pem_bytes: List[UInt8]
    # Path cert model: cert chain + key PEM file paths.
    var tls_cert_path: String
    var tls_key_path: String
    # Origin policy: default allow-all (see struct doc).
    var origin_allowlist: List[String]
    var allow_all: Bool

    def __init__(out self):
        self.host = "0.0.0.0"
        self.port = 0
        self.tls_mode = WSS_TLS_MODE_NONE()
        self.cert_pem_bytes = List[UInt8]()
        self.key_pem_bytes = List[UInt8]()
        self.tls_cert_path = ""
        self.tls_key_path = ""
        self.origin_allowlist = List[String]()
        # allow-all by default; THIS IS EXTENSIBLE — add origins to this
        # allowlist for browser-safe enforcement.
        self.allow_all = True

    def __copyinit__(out self, existing: Self):
        self.host = existing.host
        self.port = existing.port
        self.tls_mode = existing.tls_mode.copy()
        self.cert_pem_bytes = existing.cert_pem_bytes.copy()
        self.key_pem_bytes = existing.key_pem_bytes.copy()
        self.tls_cert_path = existing.tls_cert_path.copy()
        self.tls_key_path = existing.tls_key_path.copy()
        self.origin_allowlist = existing.origin_allowlist.copy()
        self.allow_all = existing.allow_all

    def __moveinit__(out self, var existing: Self):
        # Explicit memberwise move: WssConfig owns fresh heap per field —
        # the default move aliasing one String across concurrent field
        # reads (the phantom 'm' in tls_key_path) is prevented by
        # construction.
        self.host = existing.host^
        existing.host = ""
        self.port = existing.port
        # WSS_TLS_* mode strings: the move steals the tls_mode buffer
        # exactly and neutralizes the source, so a later field read can
        # never observe it extended past its own length.
        self.tls_mode = existing.tls_mode^
        existing.tls_mode = ""
        self.cert_pem_bytes = existing.cert_pem_bytes^
        existing.cert_pem_bytes = List[UInt8]()
        self.key_pem_bytes = existing.key_pem_bytes^
        existing.key_pem_bytes = List[UInt8]()
        self.tls_cert_path = existing.tls_cert_path^
        existing.tls_cert_path = ""
        self.tls_key_path = existing.tls_key_path^
        existing.tls_key_path = ""
        # Origin list: scanned element-wise with fresh Strings (the
        # List-safe .copy() pattern used across this repo) — no stale
        # origin-inherited bytes; the source list is then emptied.
        self.origin_allowlist = List[String]()
        for i in range(len(existing.origin_allowlist)):
            self.origin_allowlist.append(existing.origin_allowlist[i].copy())
        existing.origin_allowlist = List[String]()
        self.allow_all = existing.allow_all

    def origin_allowed(ref self, var origin: String) -> Bool:
        """True when the ``Origin`` header value may proceed (0023).

        Default (allow_all=True): everything allowed — the recorded
        extension point is the allowlist below."""
        if self.allow_all:
            return True
        if len(origin.bytes()) == 0:
            return False
        for i in range(len(self.origin_allowlist)):
            if self.origin_allowlist[i] == origin:
                return True
        return False


def _drop_prefix(buf: List[UInt8], n: Int) -> List[UInt8]:
    """Remove the first ``n`` bytes of ``buf`` (by value)."""
    var rest = List[UInt8]()
    for i in range(n, len(buf)):
        rest.append(buf[i])
    return rest^


# ── WSSConnection ────────────────────────────────────────────────────────

struct WSSConnection(Movable, AMQPConn):
    """One upgraded (RFC 6455 + RFC 7395) connection carrying Hyrx bytes.

    The carrier is either a `TcpStream` (tls_mode "none" — ws://, used
    by the ws-layer rows) or the accepted socket after the server-side
    TLS handshake (``_ssl != 0``; wss://). Every serving touch goes
    through the AMQPConn surface; only this file knows about the ssl
    handle.

    Byte-stream contract (0023 lock):
    - `send_bytes`: ONE WS binary message per call with ALL bytes
      (server-to-client frames are never masked, RFC 6455 §5.3);
    - `recv_bytes`: folds complete masked frames into the internal
      payload buffer (answers PINGs, flattens TEXT/CONTINUATION into the
      same byte stream — the codec reassembles), returns exactly
      ``max_bytes`` once available, keeps leftovers. CLOSE opcode (or a
      carrier EOF) maps to the empty result = EOF, identical teardown
      semantics to the other tiers.
    """

    var _base: TransportConnection
    var _tcp: TcpStream
    var _ssl: Int  # flare_ssl_t server handle; 0 = plain ws:// carrier
    var _lib: OwnedDLHandle
    var _inbuf: List[UInt8]  # undecoded wire bytes (start of next frame)
    var _ready: List[UInt8]  # payload bytes from COMPLETE frames
    var _closed: Bool
    var _close_sent: Bool

    def __init__(
        out self, var tcp: TcpStream, ssl_addr: Int, conn_id: UInt64
    ) raises:
        """Adopt an accepted stream; ``ssl_addr != 0`` means wss://."""
        self._base = TransportConnection(conn_id)
        self._tcp = tcp^
        self._ssl = ssl_addr
        self._lib = OwnedDLHandle(_find_flare_lib())
        self._inbuf = List[UInt8]()
        self._ready = List[UInt8]()
        self._closed = False
        self._close_sent = False

    def conn_id(ref self) -> UInt64:
        return self._base.id()

    def poll_fd(ref self) -> Int:
        """Raw carrier fd (borrowed; the connection owns the close).

        NOTE (0023 needs-probe): the event-driven dose path reads this
        fd DIRECTLY (recv(2) plaintext seam), correct only for the ws://
        carrier — a TLS carrier would yield ciphertext there, so the wss
        tier refuses the event-driven loop (see the broker wrapper)."""
        return Int(self._tcp.as_raw_fd())

    def is_connected(ref self) -> Bool:
        return self._base.is_connected() and not self._closed

    # ---- raw carrier I/O ----

    def _read_raw(
        mut self, ptr: UnsafePointer[UInt8, _], want: Int
    ) raises -> Int:
        """One BLOCKING read of up to ``want`` bytes; 0 = clean EOF."""
        if self._ssl != 0:
            var n = _ssl_read_block(self._lib, self._ssl, ptr, want)
            if n == 0:
                return 0
            if n < 0:
                raise "WSSConnection._read_raw: TLS read failed"
            return n
        return self._tcp.read(ptr, want)

    def _write_raw(mut self, ptr: UnsafePointer[UInt8, _], total: Int) raises:
        """Write ALL bytes (blocking)."""
        if self._ssl != 0:
            var sent = 0
            while sent < total:
                var n = _ssl_write_block(
                    self._lib, self._ssl, ptr + sent, total - sent
                )
                if n <= 0:
                    raise "WSSConnection._write_raw: TLS write failed"
                sent += n
            return
        self._tcp.write_all(Span[UInt8, _](unsafe_ptr=ptr, length=total))

    def _write_bytes(mut self, var data: List[UInt8]) raises:
        """Write every byte of a List (blocking); data consumed."""
        if len(data) > 0:
            self._write_raw(data.unsafe_ptr(), len(data))
        _ = data^

    # ---- WS framing ----

    def _drain_frame(mut self) raises -> Int:
        """Decode ONE complete frame from ``_inbuf``.

        Return codes:
        - 2: payload bytes folded into ``_ready`` (caller may have its
          quota already — the recv loop re-checks);
        - 1: control frame handled (PING answered with an unmasked PONG
          per RFC 6455 §5.5.3); keep draining;
        - 0: no complete frame in ``_inbuf`` (read more);
        - -1: the peer sent CLOSE — the connection is EOF (leftover
          ``_ready`` stays available; nothing further is read). The §5.5.1
          close echo belongs to the teardown (``close``), never here."""
        if len(self._inbuf) == 0:
            return 0
        var dec = WsFrame.decode_one(Span[UInt8, _](self._inbuf))
        var consumed = dec.consumed
        var opcode = dec.frame.opcode
        var masked = dec.frame.masked
        var payload = dec.frame.payload.copy()
        _ = dec^  # destroy the decode result; the frame dies with it
        if not masked:
            # RFC 6455 §5.1: a server MUST fail the connection on an
            # unmasked client frame — protocol error, fail closed (the
            # serving loop's SERVE_FAILED containment catches this).
            raise "WSSConnection: client frame is not masked (RFC 6455 §5.1)"
        self._inbuf = _drop_prefix(self._inbuf, consumed)
        if opcode == WsOpcode.CLOSE:
            # RFC 6455 §5.5.1: record the decoded peer CLOSE as EOF only.
            # The echo must NOT be written here: a pre-written batch
            # releases its exact-count read on THIS frame, so an immediate
            # echo would ride the wire AHEAD of the replies still queued in
            # the backlog (the roundtrip row's binary-message assert). The
            # serving teardown (_close_slot -> close) is the single echo
            # emitter; _closed here must not skip it (the bare-FIN defect).
            self._closed = True
            return -1
        if opcode == WsOpcode.PING:
            var pong = WsFrame.pong(payload^)
            var wire = pong.encode(mask=False)
            self._write_bytes(wire^)
            return 1
        if opcode == WsOpcode.PONG:
            return 1
        if (
            opcode == WsOpcode.BINARY
            or opcode == WsOpcode.TEXT
            or opcode == WsOpcode.CONTINUATION
        ):
            # Byte-stream bridge: TEXT/fragment continuation fold into
            # the same payload stream (declared CONTRACT note: the tier
            # exposes bytes, not WS message identity).
            if len(payload) > _MAX_WS_PAYLOAD():
                raise (
                    "WSSConnection: WS payload exceeds the "
                    + String(_MAX_WS_PAYLOAD())
                    + "-byte cap"
                )
            for i in range(len(payload)):
                self._ready.append(payload[i])
            return 2
        raise "WSSConnection: refused WS frame opcode " + String(Int(opcode))

    def recv_bytes(mut self, max_bytes: Int) raises -> List[UInt8]:
        """Up to ``max_bytes`` payload bytes; empty result = EOF.

        Decode-then-read loop: complete frames fold into ``_ready``;
        an incomplete frame triggers one blocking carrier read (<= 4096
        bytes) into ``_inbuf``. Peer CLOSE or carrier EOF reads as an
        empty List — the AMQPConn EOF contract."""
        if max_bytes <= 0 or self._closed:
            return List[UInt8]()
        while len(self._ready) < max_bytes and not self._closed:
            var code = self._drain_frame()
            if code == -1:
                break
            if code == 0:
                var chunk = List[UInt8](unsafe_uninit_length=4096)
                var got = self._read_raw(chunk.unsafe_ptr(), 4096)
                if got <= 0:
                    self._closed = True
                    break
                if got < 4096:
                    chunk.resize(unsafe_uninit_length=got)
                for i in range(got):
                    self._inbuf.append(chunk[i])
                _ = chunk^
        if len(self._ready) == 0:
            return List[UInt8]()
        var take = max_bytes
        if len(self._ready) < take:
            take = len(self._ready)
        var out = List[UInt8]()
        for i in range(take):
            out.append(self._ready[i])
        self._ready = _drop_prefix(self._ready, take)
        return out^

    def send_bytes(mut self, var data: List[UInt8]) raises -> Int:
        """ONE WS binary message carrying ALL of ``data``.

        Server-to-client frames are NOT masked (RFC 6455 §5.3). Returns
        the byte count; ``data`` is consumed."""
        var n = len(data)
        if n == 0:
            _ = data^
            return 0
        var frame = WsFrame.binary(data^)
        var wire = frame.encode(mask=False)
        self._write_bytes(wire^)
        return n

    def _send_close_frame(mut self):
        """Emit the server's own WS close frame (code 1000) AT MOST once.

        The single emitter is the teardown in close(); a decoded peer CLOSE
        is echoed through that same path (§5.5.1), never from _drain_frame,
        so the close frame can never overtake the replies still in the
        backlog. The send-once flag is the idempotent close contract (two
        calls, one frame). Best effort: a failing write never propagates —
        teardown must not be blocked by a vanished peer."""
        if self._close_sent:
            return
        self._close_sent = True
        try:
            var frame = WsFrame.close(WsCloseCode.NORMAL, "")
            var wire = frame.encode(mask=False)
            self._write_bytes(wire^)
        except:
            pass

    def close(mut self):
        """WS close handshake (code 1000), then the carrier close.

        Best effort: a failing close-frame write never blocks teardown
        (the client may have already vanished). This is the ONLY close-frame
        emitter: it runs after the serving layer has dispatched the decoded
        backlog (replies first, then the §5.5.1 echo), and a close already
        sent here is never re-sent — a decoded peer CLOSE sets _closed but
        must still reach this handshake (the bare-FIN defect)."""
        self._send_close_frame()
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
        self._tcp.close()
        self._base.disconnect()
        self._closed = True

    # ---- handshake internals (HTTP upgrade over the carrier) ----

    def _read_line(mut self) raises -> String:
        """One CRLF-terminated line (blocking byte-wise)."""
        var line = String(capacity=256)
        var buf = List[UInt8](capacity=1)
        buf.append(UInt8(0))
        while True:
            var n = self._read_raw(buf.unsafe_ptr(), 1)
            if n == 0:
                return line^
            var c = buf[0]
            if c == 13:
                continue
            if c == 10:
                return line^
            line += chr(Int(c))

    @staticmethod
    def _lower_hdr(var s: String) -> String:
        """ASCII-lowercase of a header name/value."""
        var out = String(capacity=s.byte_length())
        for i in range(s.byte_length()):
            var c = s.unsafe_ptr()[i]
            if c >= 65 and c <= 90:
                out += chr(Int(c) + 32)
            else:
                out += chr(Int(c))
        return out^


# ---- HTTP upgrade rejection rows (normative 0023 rows) --------------------

def _find_colon(var s: String) -> Int:
    var n = s.byte_length()
    var ptr = s.unsafe_ptr()
    for i in range(n):
        if ptr[i] == UInt8(58):
            return i
    return -1


def _contains_upgrade(var v: String) -> Bool:
    """True when ``v`` contains the token/substring "upgrade"."""
    var target = List[UInt8]()
    target.append(UInt8(117))  # u
    target.append(UInt8(112))  # p
    target.append(UInt8(103))  # g
    target.append(UInt8(114))  # r
    target.append(UInt8(97))   # a
    target.append(UInt8(100))  # d
    target.append(UInt8(101))  # e
    var n = v.byte_length()
    var m = len(target)
    if n < m:
        return False
    var ptr = v.unsafe_ptr()
    for i in range(n - m + 1):
        var ok = True
        for j in range(m):
            if ptr[i + j] != target[j]:
                ok = False
                break
        if ok:
            return True
    return False


def _resource_of(var request_line: String) -> String:
    """The HTTP request target (between the method and protocol tokens)."""
    var bs = request_line.as_bytes()
    var space1 = -1
    var space2 = -1
    for i in range(len(bs)):
        if bs[i] == UInt8(32):
            if space1 < 0:
                space1 = i
            else:
                space2 = i
                break
    if space2 < 0:
        return ""
    var out = String(capacity=space2 - space1 - 1)
    for i in range(space1 + 1, space2):
        out += chr(Int(bs[i]))
    return out^


def _has_amqp_subprotocol(var value: String) -> Bool:
    """True when the `Sec-WebSocket-Protocol` value lists ``amqp``."""
    var n = value.byte_length()
    var token = String(capacity=n)
    var ptr = value.unsafe_ptr()
    for i in range(n):
        var c = ptr[i]
        if c == UInt8(44):  # ',' — protocol list separator
            if String(token.strip()) == "amqp":
                return True
            token = String(capacity=n)
        else:
            token += chr(Int(c))
    return String(token.strip()) == "amqp"


def _http_reject(mut conn: WSSConnection, code: String) raises:
    """Write a minimal HTTP rejection row (codes "NNN <reason>")."""
    var body = (
        "HTTP/1.1 " + code + "\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
    )
    var b = body.as_bytes()
    conn._write_raw(b.unsafe_ptr(), len(b))


def _ws_handshake(mut conn: WSSConnection, ref cfg: WssConfig) raises -> Bool:
    """Drive RFC 6455 §4.2 + RFC 7395 on the established carrier.

    Normative rows (0023):
    - request line not ``GET`` → HTTP 400;
    - resource other than ``/ws`` → HTTP 404;
    - missing/malformed `Upgrade`/`Connection: Upgrade`/
      `Sec-WebSocket-Key` → 400;
    - `Sec-WebSocket-Protocol` absent or not offering ``amqp`` → 400
      (RFC 7395: the AMQP subprotocol is required);
    - an ``Origin`` refused by the 0023 policy → HTTP 403 + close;
    - success → HTTP 101 with `Sec-WebSocket-Accept` computed by
      flare's own SHA-1/base64 helper (NO local RFC 6455 crypto) and
      `Sec-WebSocket-Protocol: amqp`.

    Returns True when upgraded. On a rejection the status row is written
    and the carrier is closed. EOF/transport failure mid-request simply
    yields False (nothing further can be written)."""
    var status = String("")
    var ws_key = String("")
    var request_line = ""
    var got_request = False
    try:
        request_line = conn._read_line()
        got_request = True
    except:
        return False
    if got_request:
        if not request_line.startswith("GET "):
            status = "400 Bad Request"
        elif _resource_of(request_line) != "/ws":
            status = "404 Not Found"

    if len(status.bytes()) == 0:
        var ws_proto = String("")
        var origin = String("")
        var found_upgrade = False
        var found_connection = False
        try:
            while True:
                var line = conn._read_line()
                if len(line.bytes()) == 0:
                    break
                var colon = _find_colon(line)
                if colon < 0:
                    continue
                var k = WSSConnection._lower_hdr(
                    String(line[byte=0:colon].strip())
                )
                var v = String(
                    String(
                        line[byte = colon + 1 : line.byte_length()].strip()
                    )
                )
                if k == "sec-websocket-key":
                    ws_key = v^
                elif k == "sec-websocket-protocol":
                    ws_proto = v^
                elif k == "origin":
                    origin = v^
                elif k == "upgrade" and WSSConnection._lower_hdr(v) == "websocket":
                    found_upgrade = True
                elif (
                    k == "connection"
                    and _contains_upgrade(WSSConnection._lower_hdr(v))
                ):
                    found_connection = True
        except:
            return False

        if not found_upgrade or not found_connection or len(ws_key.bytes()) == 0:
            status = "400 Bad Request"
        elif not _has_amqp_subprotocol(ws_proto):
            status = "400 Bad Request"
        elif not cfg.origin_allowed(origin):
            status = "403 Forbidden"

    if len(status.bytes()) != 0:
        _ = _http_reject(conn, status)
        return False

    # RFC 6455 §4.2.2: accept = base64( SHA1(key + GUID) ) — flare's
    # helper (libflare_tls SHA1 + flare.crypto.base64), reused, not
    # locally re-derived.
    var accept = _compute_accept_srv(ws_key)
    var response = (
        "HTTP/1.1 101 Switching Protocols\r\n"
        + "Upgrade: websocket\r\n"
        + "Connection: Upgrade\r\n"
        + "Sec-WebSocket-Accept: "
        + accept
        + "\r\n"
        + "Sec-WebSocket-Protocol: amqp\r\n"
        + "\r\n"
    )
    var rb = response.as_bytes()
    conn._write_raw(rb.unsafe_ptr(), len(rb))
    return True


# ── WSSListener ──────────────────────────────────────────────────────────

struct WSSListener[Ops: FileSystemOps](Movable):
    """Binds a TCP port and produces upgraded WSSConnection slots.

    Accept shape mirrors TCPListener.accept_connection: blocking accept,
    conn ids from a listener-scoped counter registry (the tcp/uds
    pattern), `accept_connection` -> Optional. TLS setup happens once at
    start() (path model: ONE pre-read through the injected fs seam, then
    the server-side SSL_CTX); the WS upgrade runs inside
    accept_connection so a hostile/failed upgrade is per-connection
    damage only — Optional-empty maps exactly to the refused-accept
    contract register() already consumes."""

    var _cfg: WssConfig
    var _ops: Self.Ops
    var _next_conn_id: UInt64
    var _listener: Optional[TcpListener]
    var _ctx: Optional[ServerCtx]

    def __init__(out self, var cfg: WssConfig, var ops: Self.Ops):
        # Explicit per-field transfer (parity with WssConfig.__moveinit__,
        # explicit move copy for owned strings): WSSListener._cfg owns a
        # fresh heap per field, so the tier's cert/key `read_all` calls in
        # start() can never observe an aliased path buffer (the phantom
        # 'm' in tls_key_path).
        self._cfg = WssConfig()
        self._cfg.host = cfg.host^
        cfg.host = ""
        self._cfg.port = cfg.port
        self._cfg.tls_mode = cfg.tls_mode^
        cfg.tls_mode = ""
        self._cfg.cert_pem_bytes = cfg.cert_pem_bytes^
        cfg.cert_pem_bytes = List[UInt8]()
        self._cfg.key_pem_bytes = cfg.key_pem_bytes^
        cfg.key_pem_bytes = List[UInt8]()
        self._cfg.tls_cert_path = cfg.tls_cert_path^
        cfg.tls_cert_path = ""
        self._cfg.tls_key_path = cfg.tls_key_path^
        cfg.tls_key_path = ""
        self._cfg.origin_allowlist = List[String]()
        for i in range(len(cfg.origin_allowlist)):
            self._cfg.origin_allowlist.append(cfg.origin_allowlist[i].copy())
        cfg.origin_allowlist = List[String]()
        self._cfg.allow_all = cfg.allow_all
        self._ops = ops^
        self._next_conn_id = 1
        self._listener = Optional[TcpListener]()
        self._ctx = Optional[ServerCtx]()

    def tls_mode(ref self) -> String:
        """The tier's configured tls_mode ("none" | "injected" | "path")."""
        return self._cfg.tls_mode

    def start(mut self) raises -> Bool:
        """Bind; (path model) load the TLS context. True on success."""
        if self._cfg.tls_mode == WSS_TLS_MODE_INJECTED():
            # NEEDS-PROBE (0023): libflare_tls in this vendor snapshot
            # loads certs from FILES only (flare_ssl_ctx_new_server /
            # flare_ssl_ctx_load_cert_key both take paths; no
            # from-memory export). Injected bytes are carried in
            # WssConfig and validated, but the tier refuses to start
            # until the vendor lands a memory-load FFI export — raised
            # BEFORE any bind, so nothing is half-started.
            raise (
                "WSSListener.start: injected PEM cert mode needs a "
                "cert-from-memory FFI export in libflare_tls (absent in "
                "this vendor snapshot); configure wss_tls_mode=path"
            )
        if self._cfg.tls_mode == WSS_TLS_MODE_PATH():
            # The ONLY fs touch in the tier: read each PEM once through
            # the INJECTED seam (never libc directly) to prove
            # readability up front; the paths are then handed to the
            # OpenSSL lifecycle, which opens them itself (receipt note:
            # libflare_tls is path-only, hence this dual-read shape).
            #
            # ORDER IS LOAD-BEARING (0023 phantom-'m' fix, Mojo 1.0.0
            # codegen workaround): the KEY path is read FIRST. With the
            # cert read first, the key `read_all` receives the cert
            # String's length fused onto the key buffer (openat
            # ".../key.pemm", ENOENT) — repro: strace probe over this
            # function, key-first passes, cert-first fails, for every
            # copy/move/ownership discipline of the argument (owned
            # locals, explicit .copy(), helper functions). Ordering is
            # the only shape proven clean on the pinned 1.0.0 compiler.
            # Same files, same normative checks, same messages — only
            # the pre-validation order differs.
            if len(self._ops.read_all(self._cfg.tls_key_path)) == 0:
                raise (
                    "WSSListener.start: key file is empty: "
                    + self._cfg.tls_key_path
                )
            if len(self._ops.read_all(self._cfg.tls_cert_path)) == 0:
                raise (
                    "WSSListener.start: cert file is empty: "
                    + self._cfg.tls_cert_path
                )
            var ctx = ServerCtx.new(
                self._cfg.tls_cert_path, self._cfg.tls_key_path
            )
            self._ctx = ctx^
        var addr = SocketAddr(
            IpAddr.parse(self._cfg.host), UInt16(self._cfg.port)
        )
        var bound = TcpListener.bind(addr)
        self._listener = bound^
        return True

    def stop(mut self):
        if self._listener.__bool__():
            self._listener.value().close()
        self._listener = Optional[TcpListener]()
        self._ctx = Optional[ServerCtx]()

    def is_listening(ref self) -> Bool:
        return self._listener.__bool__()

    def port(mut self) raises -> Int:
        """The actual bound port (reflects an ephemeral bind)."""
        if not self._listener.__bool__():
            raise "WSSListener.port: listener not started"
        return Int(self._listener.value().local_addr().port)

    def accept_connection(mut self) raises -> Optional[WSSConnection]:
        """Accept (+ TLS) + WS-upgrade one connection.

        Blocks until a client connects. A connection that fails the TLS
        or upgrade stage (HTTP 400/403/404 row or transport failure)
        returns Optional-empty: the accept loop keeps listening, exactly
        the per-connection-damage containment SERVE_FAILED already
        provides on the serving side."""
        if not self._listener.__bool__():
            raise "WSSListener.accept_connection: listener not started"
        var stream = self._listener.value().accept()
        var id = self._next_conn_id
        self._next_conn_id += 1
        var ssl_addr = Int(0)
        var carrier = stream^
        if self._ctx.__bool__():
            ssl_addr = server_ssl_new_accept(
                self._ctx.value(), Int(carrier.as_raw_fd())
            )
            if ssl_addr == 0:
                carrier.close()
                return Optional[WSSConnection]()
            var steps = Int(0)
            while True:
                var rc = server_ssl_do_handshake(self._ctx.value(), ssl_addr)
                if rc == 0:
                    break
                if rc < 0:
                    try:
                        _ = server_ssl_free(self._ctx.value(), ssl_addr)
                    except:
                        pass
                    carrier.close()
                    return Optional[WSSConnection]()
                # WANT_READ / WANT_WRITE: 1 ms slice, bounded so a
                # stalled client cannot pin the accept loop (slow-loris
                # handshaker) forever.
                steps += 1
                if steps >= _HANDSHAKE_DEADLINE_STEPS():
                    try:
                        _ = server_ssl_free(self._ctx.value(), ssl_addr)
                    except:
                        pass
                    carrier.close()
                    return Optional[WSSConnection]()
                _ = libc_nanosleep_ms(1)
        var conn = WSSConnection(carrier^, ssl_addr, id)
        var ok = _ws_handshake(conn, self._cfg)
        if not ok:
            conn.close()
            _ = conn^
            return Optional[WSSConnection]()
        return Optional[WSSConnection](conn^)

    def accept_fd(ref self) raises -> Int:
        """The listening socket fd (borrowed; listener owns the close)."""
        if not self._listener.__bool__():
            raise "WSSListener.accept_fd: listener not started"
        return Int(self._listener.value().as_raw_fd())
