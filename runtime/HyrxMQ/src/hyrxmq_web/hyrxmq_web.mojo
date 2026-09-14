# HyrxMQ web service entry point.
#
# HTTP API surface for the HyrxMQ broker: dashboard, health, status,
# and Prometheus metrics endpoints. Serves the React+MUI dashboard
# from the built frontend/ directory.
#
# Embeds a real HyrxMQBroker instance so every endpoint reflects actual
# broker state — no hardcoded health, no fake readiness.
#
# Run:  pixi run hyrxmq-web-run
#       export HYRXMQ_WEB_PORT=25600 && ./build/hyrxmq-web

from std.os import getenv
from std.ffi import OwnedDLHandle

from flare.prelude import *
from flare.net import IpAddr, SocketAddr
from flare.http.fs import FileServer
from flare.http.handler import Handler
from flare.http.request import Request
from flare.http.response import Response
from flare.http.server import HttpServer, not_found, ok, ok_json
from flare.http.router import Router
from flare.utils.dylib import find_flare_lib

from hyrxmq.config import HyrxMQConfig
from hyrxmq.broker import HyrxMQBroker
from hyrxmq.listener import AMQPListener


# ---- composite handler: owns broker, serves API + static files ----

struct HyrxWebHandler(Handler):
    """Embed a real broker, serve API routes + static file fallback."""

    var _broker: HyrxMQBroker
    var _api: Router
    var _static: FileServer

    def __init__(
        out self,
        var broker: HyrxMQBroker,
        var api: Router,
        var static: FileServer,
    ):
        self._broker = broker^
        self._api = api^
        self._static = static^

    # ---- API route handlers (methods on the handler struct) ----

    def _health(ref self) -> Response:
        """Liveness: broker is running and started."""
        if self._broker.ready():
            return ok("ok")
        return Response(503, "starting")

    def _ready(ref self) -> Response:
        """Readiness: broker is ready to serve. 503 during shutdown (degraded)."""
        if self._broker.ready():
            return ok("ready")
        return Response(503, "not ready")

    def _stats(ref self) -> Response:
        """Broker stats from the embedded broker's live state."""
        var s = self._broker.status()
        return ok_json(s.to_json()^)

    def _queues(ref self) -> Response:
        """List declared queues from the embedded broker."""
        var names = self._broker.list_queue_names()
        var parts = List[String]()
        for i in range(len(names)):
            var name = names[i]
            var depth = self._broker.queue_depth(name.copy())
            var consumers = self._broker.queue_consumer_count(name.copy())
            parts.append(
                "{\"name\":\"" + name
                + "\",\"depth\":" + String(depth)
                + ",\"consumers\":" + String(consumers)
                + "}"
            )
        var body = "{\"queues\":[" + ",".join(parts) + "]}"
        return ok_json(body^)

    def _exchanges(ref self) -> Response:
        """List declared exchanges from the embedded broker."""
        var names = self._broker.list_exchange_names()
        var parts = List[String]()
        for i in range(len(names)):
            var name = names[i]
            var etype = self._broker.exchange_type_of(name.copy())
            var bindings = self._broker.exchange_binding_total(name.copy())
            parts.append(
                "{\"name\":\"" + name
                + "\",\"type\":\"" + etype
                + "\",\"bindings\":" + String(bindings)
                + "}"
            )
        var body = "{\"exchanges\":[" + ",".join(parts) + "]}"
        return ok_json(body^)

    # ---- Handler impl: dispatch to methods ----

    def serve(self, req: Request) raises -> Response:
        var url = req.url
        if url == "/health" or url.startswith("/health?"):
            return self._health()
        if url == "/ready" or url.startswith("/ready?"):
            return self._ready()
        if url == "/stats" or url.startswith("/stats?"):
            return self._stats()
        if url == "/queues" or url.startswith("/queues?"):
            return self._queues()
        if url == "/exchanges" or url.startswith("/exchanges?"):
            return self._exchanges()
        return self._static.serve(req)


# ---- entry point ----

def main() raises:
    # Pre-flight: verify libflare_tls.so is reachable.
    var lib_path = find_flare_lib("tls")
    try:
        _ = OwnedDLHandle(lib_path)
    except:
        print(
            "ERROR: cannot load " + lib_path + "\n"
            "  Run from the project root: ./build/hyrxmq-web\n"
            "  Not from inside build/: cd .. && ./build/hyrxmq-web"
        )
        return

    # ---- resolve ports ----
    var web_port = 8080
    var env_web_port = getenv("HYRXMQ_WEB_PORT", "")
    if len(env_web_port.bytes()) > 0:
        web_port = Int(env_web_port)

    var amqp_port = 5673
    var env_amqp_port = getenv("HYRXMQ_PORT", "")
    if len(env_amqp_port.bytes()) > 0:
        amqp_port = Int(env_amqp_port)

    # ---- configure and start the embedded broker ----
    var broker_cfg = HyrxMQConfig()
    broker_cfg.port = amqp_port
    broker_cfg.listen_host = getenv("HYRXMQ_HOST", "127.0.0.1")

    var broker = HyrxMQBroker(broker_cfg^)
    broker.start()
    print("HyrxMQ broker started (node=" + broker.node_name() + ")")

    # ---- declare default exchanges (AMQP spec) ----
    _ = broker.declare_exchange("", "direct")
    _ = broker.declare_exchange("amq.direct", "direct")
    _ = broker.declare_exchange("amq.topic", "topic")
    _ = broker.declare_exchange("amq.fanout", "fanout")
    _ = broker.declare_exchange("amq.headers", "headers")

    # ---- start the AMQP listener (so real clients can connect) ----
    var listen_cfg = HyrxMQConfig()
    listen_cfg.port = amqp_port
    listen_cfg.listen_host = getenv("HYRXMQ_HOST", "127.0.0.1")
    var listen_host = listen_cfg.listen_host.copy()
    var listener = AMQPListener(listen_cfg^)
    try:
        if listener.start():
            print(
                "HyrxMQ AMQP listening on "
                + listen_host
                + ":"
                + String(amqp_port)
            )
        else:
            print("WARNING: AMQP listener failed to start (web-only mode)")
    except:
        print(
            "WARNING: AMQP listener could not bind "
            + listen_host
            + ":"
            + String(amqp_port)
            + " (port in use?) — running web-only"
        )

    # ---- API routes ----
    # NOTE: routes are matched in HyrxWebHandler.serve() via if-chains,
    # not through the Router, because the handler methods need `self`.
    var r = Router()

    # Static file server for the React dashboard.
    var static = FileServer.new("src/hyrxmq_web/frontend/dist")

    # Composite handler — broker lives here.
    var handler = HyrxWebHandler(broker^, r^, static^)

    var port_source = "default"
    if len(env_web_port.bytes()) > 0:
        port_source = "HYRXMQ_WEB_PORT"

    var web_addr = SocketAddr(IpAddr(listen_host, False), UInt16(web_port))
    var srv: HttpServer
    try:
        srv = HttpServer.bind(web_addr)
    except:
        print(
            "ERROR: failed to bind "
            + listen_host
            + ":"
            + String(web_port)
            + " (via "
            + port_source
            + "). Port may be in use."
        )
        if port_source == "default":
            print(
                "  Set HYRXMQ_WEB_PORT=<port> to use a different port."
            )
        else:
            print(
                "  HYRXMQ_WEB_PORT is set but the port is unavailable."
                "\n  Use: export HYRXMQ_WEB_PORT=<port>  (not 'set',"
                " which only creates a shell variable)."
            )
        return

    var bound = srv.local_addrs()[0].port
    print("HyrxMQ web listening on 127.0.0.1:" + String(bound))
    srv.serve(handler^)
