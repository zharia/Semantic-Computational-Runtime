# Admin-HTTP transport (0023 T3): the OPTIONAL k8s-observable admin plane.
#
# A tiny read-only HTTP surface on ITS OWN port (plan.md 0023: default
# 25673, default OFF). It exists for k8s liveness/readiness probes
# (/health) and a minimal identity/stats row (/stats). It carries NO
# AMQP semantics: no frames, no queues, no routing, no state changes,
# no fs. Every non-matching request is a plain HTTP 404.
#
# ADR-0005 containment: flare is confined to the transport layer — this
# file carries ALL of the flare http-server wiring (the broker's
# listener/product files never import flare directly).
#
# HONEST stat surface (0023 receipt, T3): the broker's live counters
# (messages/queues/consumers — HyrxStats/queue/pool rows on the embedded
# api, BrokerStatus on hyrxmq.status) live inside the PRIMARY serving
# loop's AMQPService. This build serves ONE loop per process, so a
# concurrent cross-loop read does not exist yet (see the main_listen
# NOT-YET declaration and the T3 receipt). /stats therefore serves the
# minimal honest row: broker identity (node_name, vhost) + this tier's
# own state. Wiring the live counters needs the thread model
# (needs-probe, recorded in the receipt) — never faked here.

from std.collections import Optional

from flare.http.handler import Handler
from flare.http.request import Request
from flare.http.response import Response
from flare.http.server import HttpServer, not_found, ok, ok_json
from flare.net import IpAddr, SocketAddr


def ADMIN_HTTP_TRANSPORT_KIND() -> String:
    """Discriminator for callers/tests (the admin tier's transport_kind)."""
    return "admin-http"


def ADMIN_HTTP_HEALTH_PATH() -> String:
    """The liveness/readiness probe path (exact match, no trailing slash)."""
    return "/health"


def ADMIN_HTTP_STATS_PATH() -> String:
    """The stats row path (exact match, no trailing slash)."""
    return "/stats"


def ADMIN_HTTP_DEFAULT_PORT() -> Int:
    """The 0023 plan default admin-HTTP port."""
    return 25673


def _json_escape(var s: String) -> String:
    """Minimal JSON string escaping (deterministic byte-for-byte).

    Covers the byte class a JSON body cannot carry raw: backslash,
    double quote, and control bytes (< 0x20; the named \\n \\r \\t forms,
    everything else as \\u00xx). Bytes >= 0x80 pass through unchanged —
    the config surfaces feeding this are UTF-8 text, and JSON bodies are
    UTF-8 by definition. Hex digits are lowercase, fixed order.
    """
    var digits = "0123456789abcdef"
    var out = String()
    for b in s.as_bytes():
        if b == 0x22:  # '"'
            out += "\\\""
        elif b == 0x5C:  # '\\'
            out += "\\\\"
        elif b == 0x0A:
            out += "\\n"
        elif b == 0x0D:
            out += "\\r"
        elif b == 0x09:
            out += "\\t"
        elif b < 0x20:
            var hi = Int(b) >> 4
            var lo = Int(b) & 15
            out += "\\u00"
            out += String(digits[byte=hi : hi + 1])
            out += String(digits[byte=lo : lo + 1])
        else:
            out += chr(Int(b))
    return out^


def _request_path(var url: String) -> String:
    """The request target's path component (query string stripped).

    flare hands the handler the raw request target (`path + optional
    query`); matching is on the PATH only, exact — `/health/` and
    `/health?probe=k8s` behave as `/health`, any other path is 404.
    """
    var q = url.find("?")
    if q < 0:
        return url
    return String(url[byte=0:q])


struct AdminHttpHandler(Handler):
    """The read-only admin request surface (flare Handler contract).

    State is fixed at construction (identity + bound port) and serve()
    NEVER mutates: the flare Handler.serve takes its self by borrow, so
    a live per-request counter is not expressible here without interior
    mutability (needs-probe, T3 receipt). Every response is one of the
    three rows below; nothing else exists on this plane.

    Endpoint rows (0023 plan.md, locked):
      GET /health -> 200 "ok"           (text/plain; k8s probes)
      GET /stats  -> 200 minimal JSON   (application/json; identity row)
      any other   -> 404 "Not Found"    (text/plain; no AMQP semantics)
    """

    var node_name: String
    var vhost: String
    var port: Int

    def __init__(out self, var node_name: String, var vhost: String, port: Int):
        self.node_name = node_name^
        self.vhost = vhost^
        self.port = port

    def serve(self, req: Request) raises -> Response:
        var path = _request_path(req.url)
        if req.method == "GET":
            if path == ADMIN_HTTP_HEALTH_PATH():
                return ok("ok")
            if path == ADMIN_HTTP_STATS_PATH():
                # The minimal honest row (0023 T3 receipt): static broker
                # identity + this tier's own endpoint state. Key order is
                # fixed (deterministic body); live broker counters are the
                # recorded NOT-YET (see file header).
                var body = (
                    "{\"status\":\"ok\""
                    + ",\"node\":\""
                    + _json_escape(self.node_name)
                    + "\""
                    + ",\"vhost\":\""
                    + _json_escape(self.vhost)
                    + "\""
                    + ",\"transport\":\""
                    + ADMIN_HTTP_TRANSPORT_KIND()
                    + "\""
                    + ",\"port\":"
                    + String(self.port)
                    + "}"
                )
                return ok_json(body^)
        return not_found("")


struct AdminHttpListener:
    """The admin-HTTP tier's own listener: bind, start, serve, stat rows.

    Thin front end over the flare HttpServer (the SAME containment rule
    as TCPListener/UDSListener/WSSListener: flare stays inside
    hyrx.transport). It owns exactly one bound port (the plan default is
    25673) and serves the AdminHttpHandler rows — NOTHING else.

    Boot-shape honesty (0023 receipt): this listener is a standalone
    surface. The listen binary serves ONE blocking loop per process, so
    the broker's primary serving loop and this tier's reactor loop
    cannot run concurrently in this build — main_listen FAILS LOUD
    (never half-binds) when the admin tier is configured, and this
    struct is exercised standalone (T4 conformance rows drive it in its
    own process). No thread model, no shared-counter reads, no faked
    multi-listener passthrough.
    """

    var _host: String
    var _port: Int
    var _node_name: String
    var _vhost: String
    var _server: Optional[HttpServer]
    var _handler: Optional[AdminHttpHandler]
    var _started: Bool

    def __init__(
        out self,
        var host: String,
        port: Int,
        var node_name: String,
        var vhost: String,
    ):
        self._host = host^
        self._port = port
        self._node_name = node_name^
        self._vhost = vhost^
        self._server = Optional[HttpServer]()
        self._handler = Optional[AdminHttpHandler]()
        self._started = False

    # ---- lifecycle ----

    def start(mut self) raises -> Bool:
        """Bind the admin port. Returns True; bind failures PROPAGATE
        (fail loud, the same shape as the TCP/UDS/WSS tiers: an unusable
        listener must never degrade into a silently-wrong boot).

        ``port == 0`` asks the kernel for an ephemeral port; the actual
        bound port is read back (and reflected by :meth:`port`) so tests
        can bind 0 safely."""
        if self._started:
            return True
        var addr = SocketAddr(IpAddr.parse(self._host), UInt16(self._port))
        var srv = HttpServer.bind(addr)
        var bound = Int(srv.local_addrs()[0].port)
        self._server = srv^
        self._handler = Optional[AdminHttpHandler](
            AdminHttpHandler(self._node_name.copy(), self._vhost.copy(), bound)
        )
        self._port = bound
        self._started = True
        return True

    def stop(mut self):
        """Stop serving and close the bound port (idempotent).

        Dropping the owned HttpServer runs its destructor, which closes
        the listener fd (flare's own lifecycle — no raw fd handling
        here)."""
        self._started = False
        if self._handler.__bool__():
            _ = self._handler.take()
        if self._server.__bool__():
            self._server = Optional[HttpServer]()

    # ---- endpoint + stat rows ----

    def port(self) raises -> Int:
        """The actual bound port (reflects an ephemeral bind with 0)."""
        if not self._started:
            raise "AdminHttpListener.port: listener not started"
        return self._port

    def host(ref self) -> String:
        """The bound host (as configured)."""
        return self._host

    def transport_kind(ref self) -> String:
        """Discriminator so callers/tests know which endpoint accessor is
        valid (the admin tier's analogue of tcp/uds/wss)."""
        return ADMIN_HTTP_TRANSPORT_KIND()

    def is_listening(ref self) -> Bool:
        """Whether the admin port is bound and serving."""
        return self._started

    def node_name(ref self) -> String:
        """The static broker identity row served on /stats."""
        return self._node_name

    def vhost(ref self) -> String:
        """The static broker vhost row served on /stats."""
        return self._vhost

    # ---- serving ----

    def serve_forever(mut self) raises:
        """Run the admin reactor loop (blocks; one tier, one loop).

        Ownership: the handler is MOVED into the flare reactor for the
        lifetime of the loop (flare's serve contract), so this tier's
        surface is frozen while serving — the documented shape, not a
        limitation added here. Returns only when the reactor exits
        (process teardown / server close)."""
        if not self._started or not self._server.__bool__():
            raise "AdminHttpListener.serve_forever: listener not started"
        if not self._handler.__bool__():
            raise "AdminHttpListener.serve_forever: handler missing"
        var handler = self._handler.take()
        self._server.value().serve[AdminHttpHandler](handler^)
