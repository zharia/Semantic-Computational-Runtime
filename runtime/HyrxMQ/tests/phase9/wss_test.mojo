# 0023 WSS + admin-HTTP transport tests.
#
# Direct-flow suite rows (NO background process, NO threads — the SAME
# single-process strategy as tests/integration/broker_uds_e2e, adapted to
# the WSS carrier's read contract: WSSConnection.recv_bytes blocks until
# EXACTLY max_bytes OR the peer CLOSE / carrier EOF releases it (the short
# -read escape the TCP/UDS tiers enjoy does NOT exist here). So the client
# PRE-WRITES its WHOLE session before the first server step; the CLOSE marker
# is what makes each exact-count read return its backlog, and the serve side
# then advances by exactly one frame per bounded serve_one_frame dose (tune-ok
# is a silent dispatch) — never a driveless blocking step, and never
# serve_forever). The (e) close-code row is the one exception: it releases
# its read with a FILLER PAD instead of the marker, because a decoded marker
# suppresses the server's own WS CLOSE that the row must observe.
#
# Rows (0023 plan.md verification program):
#   (a) wss_boot        listener + serving-composition boot shape, in-proc
#                       (the broker's own composition: WSSListener +
#                       AMQPConnServing[WSSConnection]) — NO subprocess.
#     wssamqp_refusal  the broker wrapper's normative "no cert source
#                       configured" refusal (exact message shape).
#   (b) subprotocol    RFC 7395: the 'amqp' subprotocol is REQUIRED (absent
#                       header / a wrong protocol list = HTTP 400).
#   (c) roundtrip      publish + basic.get round trip through wss per the
#                       listen-serve loop (byte-exact body; the broker's
#                       own counters advance).
#   (d) origin         origin rows: allow-list enforcement (a listed origin
#                       upgrades; an unlisted origin = HTTP 403; the default
#                       allow-all shape is the same binding with an empty
#                       list — exercised in the roundtrip row).
#   (e) close_codes    close-code mapping: the AMQP connection.close flow
#                       answers close-ok FIRST, then maps to the WS close
#                       handshake with code 1000.
#   (f) injected_refusal  the injected-PEM cert mode's normative refusal
#                       (vendor FFI pending) — exact message shape, with
#                       ZERO ops-seam calls before it (counted).
#   path_mode_counts   (path tier): path mode pre-validates cert/key with
#                       EXACTLY TWO ops.read_all calls in the load-bearing
#                       key-first order, and OUR code never calls open(2):
#                       the REAL OpenSSL ctx opens the REAL files itself.
#   (g) admin_http     /health + /stats + exact-path + method + 404 rows on
#                       the admin plane.
#
# NO-fs honesty (0023 receipt): the ONLY fs touch HyrxMQ code makes in the
# wss tier is ops.read_all through the INJECTED FileSystemOps seam (the
# counted fake in the counter rows, SystemFileSystemOps for the real-file
# row) — libflare_tls then opens the PEM files ITSELF (path-only vendor
# API; the dual-read shape is documented in wss.mojo). The wss tier
# performs NO fs WRITE anywhere (the fixture PEM files here are written
# by the TEST's own fixture plumbing).

from std.os import unlink

from hyrx.amqp.frame_codec import AMQPFrame, AMQPFrameCodec
from hyrx.amqp.constants import (
    BASIC_ACK,
    BASIC_GET,
    BASIC_GET_OK,
    BASIC_PUBLISH,
    CONNECTION_CLOSE,
    CONNECTION_CLOSE_OK,
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

from hyrx.transport.wss import WSSListener, WSSConnection, WssConfig
from hyrx.transport.tcp import TCPConnection
from hyrx.core.storage import FileSystemOps, SystemFileSystemOps

from hyrxmq.listener import AMQPConnServing, WSSAMQPListener
from hyrxmq.config import HyrxMQConfig
from hyrxmq.amqp_service import (
    ByteReader,
    write_short_string,
    write_u16,
    write_u32,
    write_u64,
)

from hyrx.transport.http_admin import AdminHttpListener, AdminHttpHandler

from flare.http.request import Request

from hyrx.testing import check


# ---- the self-signed PEM fixture (a REAL, matched Ed25519 pair) -------------
# The pair vendored in vendor/flare/tests/tls/fixtures/rustls-quic-cert —
# a production-shaped PKCS8 key + its leaf cert, embedded as bytes-in-test
# (the zero-fs fixture shape). Nothing is generated at test time.

def CERT_PEM() -> String:
    return (
        "-----BEGIN CERTIFICATE-----\n"
        "MIIBSjCB/aADAgECAhQU5dPIpdZVX73ra71gyVrhKiVd4TAFBgMrZXAwGjEYMBYG\n"
        "A1UEAwwPZmxhcmUtcXVpYy10ZXN0MCAXDTI2MDYwMjIwNDE1MFoYDzIxMjYwNTA5\n"
        "MjA0MTUwWjAaMRgwFgYDVQQDDA9mbGFyZS1xdWljLXRlc3QwKjAFBgMrZXADIQC6\n"
        "aLBjOZU47XCQ9XepGAA44ai5czFmGulWRsrgYe+HAqNTMFEwHQYDVR0OBBYEFKDR\n"
        "Mz19cbebmpSKUfhxtnrfzkS9MB8GA1UdIwQYMBaAFKDRMz19cbebmpSKUfhxtnrf\n"
        "zkS9MA8GA1UdEwEB/wQFMAMBAf8wBQYDK2VwA0EAziRJd60SGsie1TQgLJ124Tlu\n"
        "FqODqBToTmUdRCT38FLcsh/K3+ron7wCxbJW5+jamWSEG8iILdlzfD3kwi36Bw==\n"
        "-----END CERTIFICATE-----\n"
    )


def KEY_PEM() -> String:
    return (
        "-----BEGIN PRIVATE KEY-----\n"
        "MC4CAQAwBQYDK2VwBCIEIKG/imdw4hAoj/3vigGwPl8nyrZwOEsNAM60ZPVfr3Lx\n"
        "-----END PRIVATE KEY-----\n"
    )


# ---- shared helpers ---------------------------------------------------------

def bytes_of(s: String) -> List[UInt8]:
    var out = List[UInt8]()
    var b = s.as_bytes()
    for i in range(len(b)):
        out.append(b[i])
    return out^


def str_of(var b: List[UInt8]) -> String:
    var out = String()
    for i in range(len(b)):
        out += chr(Int(b[i]))
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


def amqp_request(
    chan: UInt16, mid: MethodID, var args: List[UInt8]
) -> List[UInt8]:
    return AMQPFrameCodec.encode_method_frame(
        chan, mid.class_id, mid.method_id, args^
    )


def amqp_header_frame(chan: UInt16, var body: List[UInt8]) -> List[UInt8]:
    return AMQPFrameCodec.encode_header_frame(
        chan, UInt16(60), UInt64(len(body)), UInt16(0), List[UInt8]()
    )


def amqp_body_frame(chan: UInt16, var payload: List[UInt8]) -> List[UInt8]:
    return AMQPFrameCodec.encode_body_frame(chan, payload^)


def amqp_protocol_header() -> List[UInt8]:
    """The 8-octet AMQP 0-9-1 header (41 4D 51 50 00 00 09 01)."""
    var h = bytes_of("AMQP")
    h.append(0)
    h.append(0)
    h.append(0x09)
    h.append(0x01)
    return h^


def append_all(mut dst: List[UInt8], var src: List[UInt8]):
    for i in range(len(src)):
        dst.append(src[i])


def wss_body() -> List[UInt8]:
    return bytes_of("amqp-over-wss-roundtrip-payload")


# The serving frame ceiling (see WsServer): 512 exceeds EVERY single client
# frame this fixture writes (the largest is ~70 B), so the server codec
# accepts them, and it is small enough that ONE pre-written batch of the
# whole client session satisfies a single `recv_bytes(frame_max+8)` read
# (the WS carrier has no short-read; the batch's trailing CLOSE marker is
# what releases the read even if the bytes fall a little short).
def WSS_TEST_FRAME_MAX() -> Int:
    return 512


# The WIRE delivery-tag of the FIRST message this fixture ever gets on
# channel 1 of a fresh connection: the per-(conn,chan) tag namespace opens
# at 1 (amqp_service._ChanTagMap.next_tag). The ack is pre-written against
# it; the verify step asserts the get-ok really carried this tag, so a
# broker-side renumber can never silently mis-address the ack.
def WSS_ACK_TAG() -> UInt64:
    return UInt64(1)


# ---- counted fake ops (the no-fs / call-count evidence) ----------------------

struct CountOps(Movable, Deinitable, FileSystemOps):
    """A counted FileSystemOps fake: every read_all is ONE explicit counted
    seam call. The counters ARE the tier's no-fs guarantee rows (path mode:
    EXACTLY two reads in the key-first order; injected mode: ZERO before
    the refusal)."""

    var reads: Int
    var order: List[String]
    var cert_path: String
    var key_path: String

    def __init__(out self):
        self.reads = 0
        self.order = List[String]()
        self.cert_path = ""
        self.key_path = ""

    def read_all(mut self, var path: String) raises -> List[UInt8]:
        self.reads += 1
        self.order.append(path.copy())
        if len(self.cert_path.bytes()) != 0 and path == self.cert_path:
            return bytes_of(CERT_PEM())
        if len(self.key_path.bytes()) != 0 and path == self.key_path:
            return bytes_of(KEY_PEM())
        return List[UInt8]()  # unknown path -> the empty-file refusal row

    def exists(mut self, var path: String) -> Bool:
        return True

    def open_append(mut self, var path: String) raises -> Int:
        return 7

    def append(mut self, handle: Int, var data: List[UInt8]) raises:
        pass

    def sync(mut self, handle: Int) raises:
        pass

    def truncate(mut self, handle: Int, length: Int) raises:
        pass

    def close(mut self, handle: Int):
        pass


# ---- the browser-side WS fixture (client half of the direct flow) ----------

def mask_byte(i: Int) -> UInt8:
    # the fixture mask key bytes: 11 22 33 44
    var v = 0x11
    if i == 1:
        v = 0x22
    if i == 2:
        v = 0x33
    if i == 3:
        v = 0x44
    return UInt8(v)


def client_ws_bin(var payload: List[UInt8]) -> List[UInt8]:
    """One MASKED binary WS message carrying ALL of `payload` (RFC 6455
    §5.3 client masking + §5.2 extended lengths)."""
    var out = List[UInt8]()
    out.append(UInt8(0x82))  # FIN + binary
    var n = len(payload)
    if n < 126:
        out.append(UInt8(n | 0x80))
    elif n < 65536:
        out.append(UInt8(126 | 0x80))
        out.append(UInt8((n >> 8) & 0xFF))
        out.append(UInt8(n & 0xFF))
    else:
        out.append(UInt8(127 | 0x80))
        for i in range(8):
            out.append(UInt8((n >> (56 - i * 8)) & 0xFF))
    for i in range(4):
        out.append(mask_byte(i))
    for i in range(n):
        out.append(payload[i] ^ mask_byte(i % 4))
    return out^


def client_ws_close(code: Int) -> List[UInt8]:
    """One MASKED close frame (RFC 6455 §5.5.1), two-byte code payload."""
    var out = List[UInt8]()
    out.append(UInt8(0x88))  # FIN + close
    out.append(UInt8(2 | 0x80))
    for i in range(4):
        out.append(mask_byte(i))
    var b0 = UInt8((code >> 8) & 0xFF) ^ mask_byte(0)
    var b1 = UInt8(code & 0xFF) ^ mask_byte(1)
    out.append(b0)
    out.append(b1)
    return out^


# The (e) row's read-release filler, in octets (see client_ws_pad). The row's
# real post-header payload is exactly 100 octets (start-ok + tune-ok + open +
# connection.close, measured); the server's next read wants at most
# WSS_TEST_FRAME_MAX+8 = 520, so 100 + 448 = 548 satisfies it from bytes that
# never reach frame dispatch — this row releases its reads WITHOUT a CLOSE
# marker at all (see client_ws_pad for why), and the 420 filler octets left in
# the codec's one-frame backlog ceiling (frame_limit+8 = 520) stay behind the
# connection.close frame that tears the slot down. If the row's pre-written
# session ever grows, raise this pad to keep the sum above the read quota.
def WSS_PAD_BYTES() -> Int:
    return 448


def client_ws_pad(n: Int) -> List[UInt8]:
    """One MASKED binary WS message carrying `n` filler octets.

    Why this exists (the WS carrier's read contract, wss.mojo recv_bytes):
    every server read wants EXACTLY its quota or a peer CLOSE/EOF marker. A
    row that must observe the SERVER's own WS CLOSE (the (e) close-code
    mapping) cannot use the marker as its release: decoding the marker sets
    the connection's closed flag, and `WSSConnection.close` then SKIPS its
    own close handshake (that guard) — so the client would read a bare
    carrier EOF where the normative code-1000 teardown belongs. The filler
    is the alternative release: it satisfies the quota from bytes that never
    reach frame dispatch."""
    var body = List[UInt8]()
    for i in range(n):
        body.append(UInt8(0x20))
    return client_ws_bin(body^)


def ws_upgrade_request(
    resource: String,
    var origin: String,
    protocol: String,
) -> List[UInt8]:
    """One RFC 6455 browser-shape upgrade request.

    `origin` empty = no Origin header; `protocol` empty = the
    Sec-WebSocket-Protocol header is ABSENT (the RFC 7395 negative row)."""
    var req = (
        "GET " + resource + " HTTP/1.1\r\n"
        + "Host: localhost\r\n"
        + "Upgrade: websocket\r\n"
        + "Connection: Upgrade\r\n"
        + "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
        + "Sec-WebSocket-Version: 13\r\n"
    )
    if protocol != "":
        req += "Sec-WebSocket-Protocol: " + protocol + "\r\n"
    if len(origin.bytes()) != 0:
        req += "Origin: " + origin + "\r\n"
    req += "\r\n"
    return bytes_of(req)


# ---- the client side (own struct; mirrors the uds-e2e ClientStream) --------


struct LiteWsMsg:
    """One parsed server-side WS message (opcode + unmasked payload)."""

    var opcode: UInt8
    var payload: List[UInt8]

    def __init__(out self, op: UInt8, var pl: List[UInt8]):
        self.opcode = op
        self.payload = pl^


struct WsClient:
    """The browser-side half: a TCP client speaking the upgrade + the
    one-WS-message-per-AMQP-frame dialect (the RFC 7395 row shape). Every
    reply the server writes is read back through real blocking reads."""

    var conn: TCPConnection
    var codec: AMQPFrameCodec
    var last_payload: List[UInt8]

    def __init__(out self, port: Int) raises:
        self.conn = TCPConnection.connect("127.0.0.1", port)
        self.codec = AMQPFrameCodec()
        self.last_payload = List[UInt8]()

    def raw_send(mut self, var wire: List[UInt8]) raises:
        var n = len(wire)
        var sent = self.conn.send_bytes(wire^)
        check(sent == n, "all client bytes written")

    def send_upgrade(
        mut self, resource: String, var origin: String, protocol: String
    ) raises:
        self.raw_send(ws_upgrade_request(resource, origin^, protocol))

    def send_ws_bin(mut self, var payload: List[UInt8]) raises:
        var sent = self.conn.send_bytes(client_ws_bin(payload^))
        check(sent > 0, "ws message fully written")

    def send_close(mut self, code: Int) raises:
        var sent = self.conn.send_bytes(client_ws_close(code))
        check(sent > 0, "ws close frame written")

    def send_pad(mut self, n: Int) raises:
        """The (e) row's read-release filler (see client_ws_pad): one binary
        WS message of `n` octets — fully written or the row must not run."""
        var wire = client_ws_pad(n)
        var want = len(wire)
        var sent = self.conn.send_bytes(wire^)
        check(sent == want, "ws padding fully written")

    def send_frame(mut self, var frame: List[UInt8]) raises:
        """ONE already-complete AMQP frame in ONE WS binary message (the
        RFC 7395 row): the codec encoders (encode_method/header/body_frame)
        already emit the full frame (type+channel+size+payload+0xCE), so the
        WS message payload IS the frame bytes — no re-wrapping."""
        self.send_ws_bin(frame^)

    def send_method(mut self, chan: UInt16, mid: MethodID, var args: List[UInt8]) raises:
        self.send_frame(amqp_request(chan, mid, args^))

    def read_exact(mut self, want: Int) raises -> List[UInt8]:
        var out = List[UInt8]()
        var left = want
        while left > 0:
            var chunk = self.conn.recv_bytes(left)
            var got = len(chunk)
            check(got > 0, "read_exact: carrier EOF")
            append_all(out, chunk^)
            left -= got
        return out^

    def read_http_row(mut self) raises -> String:
        """One HTTP response through its CRLF-CRLF terminator."""
        var sofar = List[UInt8]()
        while True:
            var one = self.read_exact(1)
            append_all(sofar, one^)
            var n = len(sofar)
            if n >= 4:
                if (
                    sofar[n - 4] == UInt8(13)
                    and sofar[n - 3] == UInt8(10)
                    and sofar[n - 2] == UInt8(13)
                    and sofar[n - 1] == UInt8(10)
                ):
                    return str_of(sofar^)

    def read_ws_message(mut self) raises -> LiteWsMsg:
        """One server-side WS message: opcode via header, unmasked payload
        (server-to-client frames are unmasked, §5.3)."""
        var head = self.read_exact(2)
        var opcode = UInt8(head[0] & 0x0F)
        var ln = Int(head[1] & 0x7F)
        if ln == 126:
            var ext = self.read_exact(2)
            ln = (Int(ext[0]) << 8) | Int(ext[1])
        elif ln == 127:
            var ext = self.read_exact(8)
            ln = 0
            for i in range(8):
                ln = (ln << 8) | Int(ext[i])
        var payload = self.read_exact(ln)
        return LiteWsMsg(opcode, payload^)

    def next_amqp_frame(mut self) raises -> AMQPFrame:
        """The streaming RFC 7395 reader: pull WS messages into the codec
        until ONE complete AMQP frame parses (bounded, 64 messages). The
        server writes ONE WS message per send_bytes call and a broker
        response may carry SEVERAL AMQP frames (get-ok + header + body), so
        the codec reassembles across message boundaries — the same shape the
        TCP/UDS e2e ClientStream readers use."""
        var i = 0
        while i < 64:
            var f = self.codec.try_parse_frame()
            if f.__bool__():
                return AMQPFrame(
                    f.value().frame_type,
                    f.value().channel,
                    f.value().payload_copy(),
                )
            var msg = self.read_ws_message()
            check(
                msg.opcode == UInt8(2),
                "server replies ride binary WS messages (opcode 2)",
            )
            self.codec.feed_bytes(msg.payload.copy())
            i += 1
        raise "client: no complete frame after 64 WS messages (deadlock guard)"

    def read_amqp_frame(mut self) raises -> AMQPFrame:
        return self.next_amqp_frame()

    def read_method(mut self) raises -> MethodID:
        var f = self.next_amqp_frame()
        check(f.frame_type == 1, "expected a METHOD frame")
        var p = f.payload_copy()
        check(len(p) >= 4, "method frame carries class+method")
        var mid = MethodID(
            (UInt16(p[0]) << 8) | UInt16(p[1]),
            (UInt16(p[2]) << 8) | UInt16(p[3]),
        )
        self.last_payload = p^
        return mid^

    def read_solo_method(mut self) raises -> MethodID:
        """RFC 7395 row: a single-frame reply rides EXACTLY ONE WS message
        with nothing left over inside it (the one-message-per-frame shape
        the handshake/declare rows require)."""
        var pending = self.codec.buffered_bytes()
        check(pending == 0, "a solo reply starts from an empty codec queue")
        var msg = self.read_ws_message()
        check(
            msg.opcode == UInt8(2),
            "server replies ride binary WS messages (opcode 2)",
        )
        self.codec.feed_bytes(msg.payload.copy())
        var mid = self.read_method()
        check(
            self.codec.buffered_bytes() == 0,
            "one WS message == one complete AMQP frame (RFC 7395)",
        )
        return mid^

    def read_close_code(mut self) raises -> Int:
        """Read WS messages until one CLOSE arrives; return the two-byte
        status code (the (e) close-code mapping row)."""
        var i = 0
        while i < 8:
            var msg = self.read_ws_message()
            if msg.opcode == UInt8(8):
                check(
                    len(msg.payload) >= 2,
                    "close frame carries a two-byte code",
                )
                return (Int(msg.payload[0]) << 8) | Int(msg.payload[1])
            check(
                msg.opcode == UInt8(2),
                "only binary replies precede the server's WS CLOSE",
            )
            self.codec.feed_bytes(msg.payload.copy())
            i += 1
        raise "client: no WS CLOSE frame within 8 messages"

    def expect_body(mut self, want: List[UInt8]) raises:
        """Read the HEADER (+BODY) frames after a content method; the
        reassembled body must equal `want` (§2.3.5 layout)."""
        var hf = self.read_amqp_frame()
        check(hf.frame_type == 2, "a content HEADER frame follows")
        var hp = hf.payload_copy()
        var hclass = (UInt16(hp[0]) << 8) | UInt16(hp[1])
        check(hclass == 60, "content header class-id is basic (60)")
        var size = UInt64(0)
        for i in range(4, 12):
            size = (size << 8) | UInt64(hp[i])
        check(Int(size) == len(want), "declared body-size matches payload")
        var got = List[UInt8]()
        while len(got) < Int(size):
            var bf = self.read_amqp_frame()
            check(bf.frame_type == 3, "a content BODY frame follows")
            var bp = bf.payload_copy()
            append_all(got, bp^)
        check_bytes(got, want, "delivered body bytes match")


# ---- the serve-side fixture (the composition, driven by STEPS) -------------

def NONE_REFUSAL() -> String:
    return (
        "WSSAMQPListener.start: no cert source configured "
        "(wss_tls_mode=none); the wss tier refuses to start. "
        "Set wss_tls_mode to injected or path."
    )


def INJECTED_REFUSAL() -> String:
    return (
        "WSSListener.start: injected PEM cert mode needs a "
        "cert-from-memory FFI export in libflare_tls (absent in "
        "this vendor snapshot); configure wss_tls_mode=path"
    )


struct WsServer:
    """The tier-level listen/serve composition (exactly what WSSAMQPListener
    composes: a WSSListener + the shared AMQPConnServing[WSSConnection]).
    Driven by STEPS from the test: no thread, no subprocess.

    frame_max is pinned SMALL (WSS_TEST_FRAME_MAX) because the serving
    state machine reads `recv_bytes(min(65536, frame_max+8-buffered))` and
    WSSConnection.recv_bytes blocks until it has EXACTLY that many decoded
    bytes OR the peer CLOSE / carrier EOF releases it (wss.mojo — the WS
    carrier has NO short-read). With the default 131072 every frame-step
    wants 65536 bytes and the ping-pong deadlocks on the first small reply
    (the original hang); a 512 ceiling both exceeds the largest single
    client frame here and lets one bounded batch of pre-written frames
    satisfy a read. The 0017 close-tests use the same in-proc bounded-dose
    shape over the short-read tiers; this is its WS-carrier equivalent."""

    var listener: WSSListener[SystemFileSystemOps]
    var serving: AMQPConnServing[WSSConnection]
    var served: Int

    def __init__(out self, port: Int) raises:
        var wcfg = WssConfig()
        wcfg.tls_mode = "none"
        wcfg.host = "127.0.0.1"
        wcfg.port = port
        wcfg.allow_all = True
        wcfg.origin_allowlist = List[String]()
        var ops = SystemFileSystemOps()
        self.listener = WSSListener[SystemFileSystemOps](wcfg^, ops^)
        var cfg = HyrxMQConfig()
        cfg.frame_max = WSS_TEST_FRAME_MAX()
        self.serving = AMQPConnServing[WSSConnection](cfg^)
        self.served = 0

    def bind(mut self) raises -> Int:
        check(self.listener.start(), "wss transport listener binds")
        check(self.listener.is_listening(), "wss listener is listening")
        var p = self.listener.port()
        check(p > 0, "wss listener reports its bound port")
        self.serving.start_service()  # the broker front-end comes up
        return p

    def accept(mut self) raises -> Int:
        """Accept + upgrade ONE connection and register it with the broker
        front-end. A hostile upgrade is per-connection damage: -1, the
        listening loop continues (the Optional-empty contract)."""
        var conn = self.listener.accept_connection()
        if not conn.__bool__():
            return -1
        return self.serving.register(conn^)

    def step(mut self, slot: Int) -> Int:
        var rc = self.serving.serve_one_frame(slot)
        if rc == 1:
            self.served += 1
        return rc

    # The bounded close-dose: drive serve_one_frame until the slot reports
    # EOF/CLOSE (rc < 0) or the frame budget runs out. NEVER serve_forever;
    # NEVER more than the expected frame count. Returns the number of frames
    # DISPATCHED (rc == 1); raises if the dose hits the cap without a close
    # (the client did not pre-write a CLOSE marker -> the read would hang).
    def drive(mut self, slot: Int, budget: Int) raises -> Int:
        var before = self.served
        var doses = 0
        while doses < budget:
            var rc = self.step(slot)
            doses += 1
            if rc < 0:
                return self.served - before
        raise "wss drive: " + String(budget) + " doses without a CLOSE"

    def published_count(mut self) -> Int:
        return self.serving.status().messages_published


def upgrade_check(mut client: WsClient, slot: Int) raises:
    """The 101 row: the upgrade's HTTP status, the RFC 6455 accept digest,
    and the negotiated RFC 7395 subprotocol."""
    check(slot >= 0, "the upgrade lands (a slot registers)")
    var row = client.read_http_row()
    check(row.find("HTTP/1.1 101") == 0, "upgrade answers with HTTP 101")
    check(
        row.find("Sec-WebSocket-Accept:") > 0,
        "the 101 carries the Sec-WebSocket-Accept digest",
    )
    check(
        row.find("Sec-WebSocket-Protocol: amqp") > 0,
        "the 101 negotiates the amqp subprotocol (RFC 7395)",
    )


# ---- the batched session: WRITE everything, DRIVE the doses, VERIFY ------
#
# The WS carrier's read contract (wss.mojo recv_bytes: no short read until
# the CLOSE marker) forbids the TCP/UDS ping-pong interleave. The flow
# therefore keeps the SAME semantics, only in three phases:
#   WRITE  the client pre-writes the whole request session (every request
#          in ONE WS binary message — the RFC 7395 client shape) plus the
#          release that makes the server's first exact-count read return:
#          the final masked WS CLOSE (every row but (e), which uses the
#          filler pad instead — see client_ws_pad);
#   DRIVE  the server advances by EXACTLY one frame per bounded
#          serve_one_frame dose (tune-ok is a silent dispatch: one dose,
#          no response bytes) until the close marker yields SERVE_CLOSED;
#   VERIFY the client then reads the accumulated replies (101 + the WS
#          message stream) and checks every row byte-exactly.
# No thread, no subprocess, no serve_forever — main() always returns.

def wss_start_ok_args() -> List[UInt8]:
    """client-properties(empty table) + mechanism(PLAIN) + response(SASL
    PLAIN) + locale — the same layout broker_tcp_e2e drives."""
    var args = List[UInt8]()
    write_u32(args, 0)
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


def wss_tune_ok_args() -> List[UInt8]:
    var targs = List[UInt8]()
    write_u16(targs, 2047)
    write_u32(targs, UInt32(131072))
    write_u16(targs, 0)
    return targs^


def wss_open_args() -> List[UInt8]:
    var oargs = List[UInt8]()
    write_short_string(oargs, "/")
    write_short_string(oargs, "")
    oargs.append(0)
    return oargs^


def wss_exchange_declare_args() -> List[UInt8]:
    var eargs = List[UInt8]()
    reserved_short(eargs)
    write_short_string(eargs, "wss.ex")
    write_short_string(eargs, "direct")
    eargs.append(0)
    write_u32(eargs, 0)
    return eargs^


def wss_queue_declare_args() -> List[UInt8]:
    var qargs = List[UInt8]()
    reserved_short(qargs)
    write_short_string(qargs, "wss.q")
    qargs.append(0)
    write_u32(qargs, 0)
    return qargs^


def wss_queue_bind_args() -> List[UInt8]:
    var bargs = List[UInt8]()
    reserved_short(bargs)
    write_short_string(bargs, "wss.q")
    write_short_string(bargs, "wss.ex")
    write_short_string(bargs, "wss.key")
    return bargs^


def wss_publish_args() -> List[UInt8]:
    var pargs = List[UInt8]()
    reserved_short(pargs)
    write_short_string(pargs, "wss.ex")
    write_short_string(pargs, "wss.key")
    pargs.append(0)
    return pargs^


def wss_get_args() -> List[UInt8]:
    var gargs = List[UInt8]()
    reserved_short(gargs)
    write_short_string(gargs, "wss.q")
    gargs.append(0)  # bits: no-ack = False
    return gargs^


def wss_ack_args(tag: UInt64) -> List[UInt8]:
    var aargs = List[UInt8]()
    write_u64(aargs, tag)
    aargs.append(UInt8(0))  # multiple = false
    return aargs^


def wss_close_args() -> List[UInt8]:
    """connection.close: reply-code(short) + reply-text(shortstr) +
    class-id(short) + method-id(short) — the 1000/"success" reply."""
    var clargs = List[UInt8]()
    write_u16(clargs, 1000)
    write_short_string(clargs, "")
    clargs.append(0)
    clargs.append(0)
    return clargs^


# The AMQP frames ONE FULL serving session pre-writes (the dose budget):
# start-ok, tune-ok, open, exchange.declare, queue.declare, queue.bind,
# publish method, publish header, publish body, basic.get, basic.ack.
def WSS_SESSION_FRAME_COUNT() -> Int:
    return 11


# The handshake-only batch: start-ok, tune-ok, open.
def WSS_HANDSHAKE_FRAME_COUNT() -> Int:
    return 3


def write_amqp_requests(mut client: WsClient, up_to_open: Bool) raises:
    """Pre-write the AMQP negotiation requests (ONE WS message per frame).
    The content is INDEPENDENT of the server's replies (the negotiation is
    fixed), which is exactly what makes the pre-write legal."""
    client.send_method(UInt16(0), CONNECTION_START_OK(), wss_start_ok_args())
    client.send_method(UInt16(0), CONNECTION_TUNE_OK(), wss_tune_ok_args())
    if up_to_open:
        client.send_method(UInt16(0), CONNECTION_OPEN(), wss_open_args())


def write_handshake_session(mut client: WsClient) raises:
    """Header + the full negotiation, pre-written before the first dose."""
    client.send_ws_bin(amqp_protocol_header())
    write_amqp_requests(client, True)


def write_declare_requests(mut client: WsClient) raises:
    client.send_method(UInt16(1), EXCHANGE_DECLARE(), wss_exchange_declare_args())
    client.send_method(UInt16(1), QUEUE_DECLARE(), wss_queue_declare_args())
    client.send_method(UInt16(1), QUEUE_BIND(), wss_queue_bind_args())


def write_publish_get_ack(mut client: WsClient) raises:
    """basic.publish (method+header+body, one WS message each), basic.get,
    then basic.ack PINNED to the deterministic first wire tag
    (WSS_ACK_TAG); the verify phase asserts the get-ok carried exactly it."""
    client.send_method(UInt16(1), BASIC_PUBLISH(), wss_publish_args())
    client.send_frame(amqp_header_frame(UInt16(1), wss_body()))
    client.send_frame(amqp_body_frame(UInt16(1), wss_body()))
    client.send_method(UInt16(1), BASIC_GET(), wss_get_args())
    client.send_method(UInt16(1), BASIC_ACK(), wss_ack_args(WSS_ACK_TAG()))


def verify_handshake_replies(mut client: WsClient) raises:
    """The negotiation replies as ONE WS message per single-frame reply:
    the byte-exact header echo, then start, tune, open-ok."""
    var echo = client.read_ws_message()
    check(
        echo.opcode == UInt8(2),
        "the protocol-header echo rides ONE binary WS message",
    )
    check_bytes(echo.payload, amqp_protocol_header(), "the echo is byte-exact")
    check(
        client.read_solo_method() == CONNECTION_START(),
        "connection.start received over ws",
    )
    check(
        client.read_solo_method() == CONNECTION_TUNE(),
        "connection.tune received over ws",
    )
    check(
        client.read_solo_method() == CONNECTION_OPEN_OK(),
        "connection.open-ok received (handshake complete over ws)",
    )


def verify_declare_replies(mut client: WsClient) raises:
    check(
        client.read_solo_method() == EXCHANGE_DECLARE_OK(),
        "exchange.declare-ok over wss",
    )
    check(
        client.read_solo_method() == QUEUE_DECLARE_OK(),
        "queue.declare-ok over wss",
    )
    check(
        client.read_solo_method() == QUEUE_BIND_OK(),
        "queue.bind-ok over wss",
    )


def verify_get_reply(mut client: WsClient) raises:
    """basic.get-ok (+header +body) — the content group may ride ONE WS
    message, so this leg uses the streaming reader."""
    check(
        client.read_method() == BASIC_GET_OK(),
        "basic.get-ok arrives through wss",
    )
    var gp = client.last_payload.copy()
    var r = ByteReader(gp^)
    _ = r.read_short()
    _ = r.read_short()
    var dtag = r.read_long_long()
    check(
        dtag == WSS_ACK_TAG(),
        "the get carried the tag the pre-written ack addressed "
        "(the fresh per-channel namespace opens at 1)",
    )
    _ = r.read_octet()  # the redelivered bit
    _ = r.read_short_string()  # exchange
    _ = r.read_short_string()  # routing key
    client.expect_body(wss_body())


def do_serving_flow(mut client: WsClient, mut server: WsServer, slot: Int) raises:
    """One complete up-and-serving session on the ws carrier, in the batched
    shape: the session is PRE-WRITTEN (with its CLOSE), the server advances
    by EXACTLY one frame per bounded dose (the STEP API — the same
    AMQPConnServing state machine the TCP/UDS front ends use), then every
    reply is verified byte-exactly. No step ever blocks on an empty peer."""
    upgrade_check(client, slot)

    # The protocol header + the whole AMQP session were pre-written by the
    # ROW before accept(); drive EXACTLY one header dose + the 11 session
    # frames, and the pre-written CLOSE must end the slot (rc < 0).
    check(server.step(slot) == 1, "the protocol-header dose dispatches")
    var dispatched = server.drive(slot, WSS_SESSION_FRAME_COUNT() + 1)
    check(
        dispatched == WSS_SESSION_FRAME_COUNT(),
        "the session dispatched exactly "
        + String(WSS_SESSION_FRAME_COUNT())
        + " frames (tune-ok rides as a silent dispatch)",
    )

    # VERIFY: the complete reply stream, in wire order.
    verify_handshake_replies(client)
    verify_declare_replies(client)
    verify_get_reply(client)

    check(
        server.published_count() == 1,
        "the broker's published counter advanced exactly once "
        "(the serving loop ran IN-PROC)",
    )


# ---- (a) the boot row -------------------------------------------------------

def test_wss_boot() raises:
    """(a) In-proc boot shape: NO subprocess drive, NO background process —
    the test constructs the listener + the serving composition itself (the
    phase8 pattern) and binds an EPHEMERAL wss port."""
    var server = WsServer(0)
    var p = server.bind()
    check(p > 0, "boot: the tier binds an ephemeral wss port")
    check(
        server.listener.tls_mode() == "none",
        "boot: the tier's tls_mode is the documented none default",
    )
    server.listener.stop()
    check(
        not server.listener.is_listening(),
        "boot: stop() unbinds the listening port",
    )


def test_wssamqp_refusal() raises:
    """The BROKER wrapper refuses a tier with no cert source configured:
    the normative reason is raised BEFORE any bind (die loud, half-bind
    nothing — 0023 plan.md)."""
    var cfg = HyrxMQConfig()
    cfg.wss_listen = 0
    cfg.wss_tls_mode = "none"
    cfg.wss_tls_path = ""
    cfg.wss_tls_key_path = ""
    var ops = SystemFileSystemOps()
    var wrapper = WSSAMQPListener[SystemFileSystemOps](cfg^, ops^)
    var msg = ""
    try:
        _ = wrapper.start()
    except e:
        msg = String(e)
    check(msg != "", "wssamqp_refusal: the wrapper refuses to start")
    check(
        msg == NONE_REFUSAL(),
        "wssamqp_refusal: the refusal carries the exact normative shape",
    )
    check(
        wrapper.active_connections() == 0,
        "wssamqp_refusal: the broker front-end stayed empty (nothing was "
        "half-bound)",
    )


# ---- (b) the RFC 7395 subprotocol rows --------------------------------------

def test_wss_subprotocol_negative() raises:
    """(b) RFC 7395: the upgrade MUST offer the amqp subprotocol. A request
    with NO Sec-WebSocket-Protocol and one offering ONLY other subprotocols
    are BOTH refused with the normative HTTP 400 row (the tier survives)."""
    var server = WsServer(0)
    var p = server.bind()

    var c1 = WsClient(p)
    c1.send_upgrade("/ws", "", "")
    check(
        server.accept() == -1,
        "subprotocol: an upgrade with NO subprotocol is refused (-1)",
    )
    var row1 = c1.read_http_row()
    check(
        row1.find("HTTP/1.1 400") == 0,
        "subprotocol: the no-protocol row is the normative HTTP 400",
    )
    c1.conn.close()

    var c2 = WsClient(p)
    c2.send_upgrade("/ws", "", "foo, bar")
    check(
        server.accept() == -1,
        "subprotocol: a wrong protocol list is refused (-1)",
    )
    var row2 = c2.read_http_row()
    check(
        row2.find("HTTP/1.1 400") == 0,
        "subprotocol: an upgrade offering only OTHER subprotocols is "
        "the normative HTTP 400 (RFC 7395)",
    )
    c2.conn.close()

    check(
        server.listener.is_listening(),
        "subprotocol: the tier keeps listening after refused upgrades",
    )
    server.listener.stop()


# ---- (c) the publish + basic.get round trip row ------------------------------

def test_wss_roundtrip() raises:
    """(a+b+c+d-default) on ONE live connection: the in-proc boot, the
    upgrade on the amqp subprotocol with an Origin NO allowlist contains
    (the allow-all default row), then publish + basic.get + ack served
    byte-exact through the bounded doses (NO subprocess anywhere).

    The CLOSE row (the (e) FIRST half): the client's own masked WS close
    (code 1000) is the LAST pre-written message; it is the marker that
    releases the carrier reads, and the serving loop reads it as the
    AMQPConn EOF: SERVE_CLOSED, per-connection teardown only."""
    var server = WsServer(0)
    var p = server.bind()
    var client = WsClient(p)
    # WRITE phase: the upgrade + the ENTIRE session (header, negotiation,
    # topology, publish, get, ack) + the final CLOSE, everything BEFORE the
    # blocking accept/doses — the pre-write batch (no threads, no short
    # read on this carrier until the CLOSE).
    client.send_upgrade("/ws", "http://hyrxmq-browser.local", "amqp")
    write_handshake_session(client)
    write_declare_requests(client)
    write_publish_get_ack(client)
    client.send_close(1000)
    var slot = server.accept()
    do_serving_flow(client, server, slot)
    check(
        server.step(slot) == -1,
        "close: the serving loop reads the client WS close as EOF",
    )
    client.conn.close()
    server.listener.stop()


# ---- (d) the origin rows ----------------------------------------------------

def test_wss_origin_rows() raises:
    """The (d) origin rows (allowlist + the normative HTTP 403 row).

    - THE ALLOWLIST TIER: a LISTED origin upgrades and registers;
    - AN UNLISTED ORIGIN: the normative HTTP 403 row (the tier keeps
      listening — per-connection damage only).
    (The allow-all DEFAULT row is the same binding with an EMPTY list:
    implicitly proven by test_wss_roundtrip upgrading with an Origin no
    list contains.)"""
    var wcfg = WssConfig()
    wcfg.tls_mode = "none"
    wcfg.host = "127.0.0.1"
    wcfg.port = 0
    wcfg.allow_all = False
    wcfg.origin_allowlist = List[String]()
    wcfg.origin_allowlist.append("http://listed.local")
    var ops = SystemFileSystemOps()
    var listener = WSSListener[SystemFileSystemOps](wcfg^, ops^)
    check(listener.start(), "origin: the allowlisted tier binds")
    var serving = AMQPConnServing[WSSConnection](HyrxMQConfig())
    serving.start_service()

    # Row: a LISTED origin upgrades.
    var good = WsClient(listener.port())
    good.send_upgrade("/ws", "http://listed.local", "amqp")
    good.send_ws_bin(amqp_protocol_header())
    var slot = listener.accept_connection()
    check(slot.__bool__(), "origin: the LISTED origin upgrades")
    var good_slot = serving.register(slot^)
    check(
        good_slot >= 0,
        "origin: a listed-origin connection registers with the broker",
    )
    good.conn.close()
    serving.close_slot(good_slot)

    # Row: an UNLISTED origin gets the normative HTTP 403 row.
    var bad = WsClient(listener.port())
    bad.send_upgrade("/ws", "http://unlisted.local", "amqp")
    check(
        serving_refuses_raises(listener),
        "origin: the unlisted origin is refused (the -1 contract)",
    )
    var row = bad.read_http_row()
    check(
        row.find("HTTP/1.1 403") == 0,
        "origin: an unlisted Origin gets the normative HTTP 403 row",
    )
    bad.conn.close()

    check(
        listener.is_listening(),
        "origin: the tier keeps listening after the refused origin",
    )
    listener.stop()


def serving_refuses_raises(mut listener: WSSListener[SystemFileSystemOps]) raises -> Bool:
    var c = listener.accept_connection()
    return not c.__bool__()


# ---- (e) the close-code mapping row ------------------------------------------

def test_wss_close_codes() raises:
    """(e) close-code mapping: the AMQP connection.close flow — the server
    answers close-ok FIRST (the normative ordering), then maps the
    connection teardown to the WS close handshake with the normative code
    1000: the client reads close-ok's WS message, then a CLOSE frame
    carrying 1000, then the carrier EOF.

    Bounded like every other serving row (STEP API only — no driveless
    blocking step, no serve_forever): the client pre-writes the header +
    negotiation + connection.close plus the FILLER PAD that releases the
    pending exact-count read, and the doses then run from that backlog, one
    frame per dose, until the connection.close dose tears the slot down
    after writing close-ok.

    The pad and NOT the client's CLOSE marker is the release here, and that
    is load-bearing for THIS row only: decoding the client marker would set
    the connection's closed flag, and `WSSConnection.close` skips its own
    close handshake when already closed (wss.mojo) — the code-1000 teardown
    the row must observe would never reach the wire, and the client would
    read a bare carrier EOF."""
    var server = WsServer(0)
    var p = server.bind()
    var client = WsClient(p)
    client.send_upgrade("/ws", "http://hyrxmq-browser.local", "amqp")
    write_handshake_session(client)
    # The AMQP connection.close, channel 0, reply code 1000, "" text, then
    # the filler pad so the doses never park on a short read.
    client.send_method(UInt16(0), CONNECTION_CLOSE(), wss_close_args())
    client.send_pad(WSS_PAD_BYTES())
    var slot = server.accept()
    check(slot >= 0, "close_codes: the upgrade proceeded")
    upgrade_check(client, slot)

    check(server.step(slot) == 1, "the protocol-header dose dispatches")
    var dispatched = server.drive(slot, WSS_HANDSHAKE_FRAME_COUNT() + 2)
    check(
        dispatched == WSS_HANDSHAKE_FRAME_COUNT() + 1,
        "close: start-ok, tune-ok, open AND connection.close each "
        "dispatch (the close dose is the last)",
    )
    check(
        server.step(slot) == -1,
        "close: the slot is down after the close dose (further doses are "
        "bounded EOF, never a read that could park)",
    )

    verify_handshake_replies(client)
    var mid = client.read_solo_method()
    check(
        mid == CONNECTION_CLOSE_OK(),
        "close: the server answers connection.close-ok FIRST",
    )
    var code = client.read_close_code()
    check(
        code == 1000,
        "close: the server's WS teardown carries the normative code 1000",
    )
    client.conn.close()
    server.listener.stop()


# ---- (f) the injected-mode refusal row ---------------------------------------

def test_wss_injected_refusal() raises:
    """(f) The injected-PEM cert mode refuses in this vendor snapshot
    (the vendor's TLS layer is path-only; no cert-from-memory FFI export
    exists). The refusal fires BEFORE any bind, carries the exact
    normative shape, and ZERO ops-seam calls happened before it — the
    counted no-fs guarantee for that mode."""
    var ops = CountOps()
    ops.cert_path = ""
    ops.key_path = ""
    var wcfg = WssConfig()
    wcfg.tls_mode = "injected"
    wcfg.cert_pem_bytes = bytes_of(CERT_PEM())
    wcfg.key_pem_bytes = bytes_of(KEY_PEM())
    var listener = WSSListener[CountOps](wcfg^, ops^)
    check(
        listener.tls_mode() == "injected",
        "injected_refusal: the tier carries the injected tls_mode",
    )
    var msg = ""
    try:
        _ = listener.start()
    except e:
        msg = String(e)
    check(msg != "", "injected_refusal: the refusal raises")
    check(
        msg == INJECTED_REFUSAL(),
        "injected_refusal: the refusal carries the exact normative shape",
    )
    check(
        listener._ops.reads == 0,
        "injected_refusal: ZERO ops.read_all calls before the refusal "
        "(the mode NEVER touches the fs seam)",
    )
    check(
        not listener.is_listening(),
        "injected_refusal: the refusal fires BEFORE any bind",
    )


# ---- the path tier: real files + the counted seam ----------------------------

# The two fixture names are EXACTLY EQUAL LENGTH and each comes from its own
# single-literal helper. Both shapes are load-bearing on the pinned Mojo 1.0
# compiler: within one elaboration group one String's length gets fused onto
# another String's buffer (the phantom-'m' defect WSSListener.start works
# around by reading the KEY first) — with unequal names the fixture file is
# created under a garbage name (a pointer tail appended to the path) and the
# REAL OpenSSL ctx then cannot open it. Equal lengths make any such fusion a
# no-op, and one literal per function keeps the fusion group empty.
def wss_cert_fixture_path() -> String:
    return "/tmp/hyrx_wss_cert1.pem"


def wss_key_fixture_path() -> String:
    return "/tmp/hyrx_wss_key00.pem"


def write_cert_fixture(mut ops: SystemFileSystemOps, var path: String) raises:
    """Write the CERT PEM through the INJECTED seam (O_APPEND open/create) —
    the TEST's own fixture plumbing, never the wss tier. One String argument
    per call: the path and the PEM must not share a call's argument group."""
    var pem = CERT_PEM()
    var fd = ops.open_append(path^)
    ops.append(fd, bytes_of(pem^))
    ops.close(fd)


def write_key_fixture(mut ops: SystemFileSystemOps, var path: String) raises:
    """Write the KEY PEM through the INJECTED seam (see write_cert_fixture)."""
    var pem = KEY_PEM()
    var fd = ops.open_append(path^)
    ops.append(fd, bytes_of(pem^))
    ops.close(fd)


def drop_wss_fixture(mut ops: SystemFileSystemOps, var path: String) raises:
    """Best-effort fixture removal (a crashed earlier run leaves the file)."""
    if ops.exists(path.copy()):
        _ = unlink(path.copy())


def test_wss_path_mode_counts() raises:
    """(path tier) The ONLY fs touch HyrxMQ code makes in path mode is
    through the INJECTED FileSystemOps seam: EXACTLY TWO read_all calls in
    the tier's load-bearing KEY-FIRST order, then the OpenSSL ctx opens
    the REAL files itself (the honest dual-read shape; our code never
    calls open(2))."""
    var writer = SystemFileSystemOps()
    drop_wss_fixture(writer, wss_key_fixture_path())
    drop_wss_fixture(writer, wss_cert_fixture_path())
    write_key_fixture(writer, wss_key_fixture_path())
    write_cert_fixture(writer, wss_cert_fixture_path())

    var ops = CountOps()
    ops.cert_path = wss_cert_fixture_path()
    ops.key_path = wss_key_fixture_path()
    var wcfg = WssConfig()
    wcfg.tls_mode = "path"
    wcfg.tls_cert_path = wss_cert_fixture_path()
    wcfg.tls_key_path = wss_key_fixture_path()
    wcfg.host = "127.0.0.1"
    wcfg.port = 0
    var listener = WSSListener[CountOps](wcfg^, ops^)
    check(
        wss_key_fixture_path().byte_length()
        == wss_cert_fixture_path().byte_length(),
        "path: the fixture names are equal length (the phantom-'m' shield)",
    )
    check(
        listener.start(),
        "path: the tier pre-validates through the seam and binds",
    )
    check(
        listener._ops.reads == 2,
        "path: EXACTLY two ops.read_all seam calls (no un-injected fs "
        "call comes from OUR code)",
    )
    check(
        listener._ops.order[0] == wss_key_fixture_path(),
        "path: the FIRST seam read is the KEY path (the load-bearing "
        "key-first order — the 0023 codegen workaround)",
    )
    check(
        listener._ops.order[1] == wss_cert_fixture_path(),
        "path: the SECOND seam read is the CERT path",
    )
    check(
        listener.port() > 0,
        "path: the REAL TLS context loaded (the OpenSSL ctx opened the "
        "REAL files itself, as documented)",
    )
    listener.stop()
    drop_wss_fixture(writer, wss_key_fixture_path())
    drop_wss_fixture(writer, wss_cert_fixture_path())


# ---- (g) the admin plane rows ------------------------------------------------

def test_admin_http() raises:
    """(g) The T3 admin plane: the listener binds its OWN port (an
    ephemeral bind here), and its three-row read-only surface is driven
    in-proc exactly as the AdminHttpListener owns it:
      GET /health       -> 200 "ok"         (k8s probes)
      GET /health?x=..  -> 200 "ok"         (query stripped)
      GET /stats        -> 200 identity JSON (node/vhost/transport/port)
      GET /health/      -> 404              (exact path only)
      POST /health      -> 404              (no mutating method)
      GET /amqp         -> 404              (no AMQP plane on this tier).
    All rows carry NO AMQP semantics (the honest static identity row only:
    the reactor serve loop + live counters are the recorded NOT-YET)."""
    var listener = AdminHttpListener(
        "127.0.0.1", 0, "hyrxmq@wss-bench", "/"
    )
    check(listener.start(), "admin: the listener binds")
    check(listener.is_listening(), "admin: the listener is up")
    var port = listener.port()
    check(port > 0, "admin: the listener reports its bound port")
    check(
        listener.transport_kind() == "admin-http",
        "admin: transport_kind is admin-http",
    )
    check(
        listener.node_name() == "hyrxmq@wss-bench",
        "admin: the static node identity row is served",
    )
    check(
        listener.vhost() == "/",
        "admin: the static vhost row is served",
    )

    # The handler surface (the exact handler the listener owns).
    var handler = AdminHttpHandler("hyrxmq@wss-bench", "/", port)

    var health = handler.serve(Request.test_get("/health"))
    check(health.status == 200, "admin: /health is the 200 row")
    check(
        health.text() == "ok",
        "admin: the /health body is exactly ok (k8s probes)",
    )

    var stats = handler.serve(Request.test_get("/stats"))
    check(stats.status == 200, "admin: /stats is the 200 row")
    var sbody = stats.text()
    check(
        sbody.find("{\"status\":\"ok\"") == 0,
        "admin: the /stats body opens with the identity row",
    )
    check(
        sbody.find("hyrxmq@wss-bench") > 0,
        "admin: the /stats body carries the node row",
    )
    check(
        sbody.find("admin-http") > 0,
        "admin: the /stats body carries the transport row",
    )
    check(
        sbody.find("\"port\":" + String(Int(port))) > 0,
        "admin: the /stats body carries the bound-port row",
    )

    var with_q = handler.serve(Request.test_get("/health?probe=k8s"))
    check(
        with_q.status == 200 and with_q.text() == "ok",
        "admin: a query string rides (exact-path matching)",
    )

    var trailing = handler.serve(Request.test_get("/health/"))
    check(
        trailing.status == 404,
        "admin: a trailing slash is a DIFFERENT path (404)",
    )

    var post = handler.serve(Request.test_post("/health", ""))
    check(
        post.status == 404,
        "admin: mutating methods are 404 (the plane is read-only)",
    )

    var unknown = handler.serve(Request.test_get("/amqp"))
    check(
        unknown.status == 404,
        "admin: no AMQP plane exists on this tier (404)",
    )

    listener.stop()
    check(
        not listener.is_listening(),
        "admin: stop() unbinds the admin port",
    )


# ---- main -------------------------------------------------------------------

def main() raises:
    test_wss_boot()
    test_wssamqp_refusal()
    test_wss_subprotocol_negative()
    test_wss_roundtrip()
    test_wss_origin_rows()
    test_wss_close_codes()
    test_wss_injected_refusal()
    test_wss_path_mode_counts()
    test_admin_http()
    print("WSS_TRANSPORT_TEST=PASS")
