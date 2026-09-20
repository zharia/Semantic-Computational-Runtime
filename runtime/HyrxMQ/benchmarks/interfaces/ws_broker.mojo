# ws_broker.mojo — benchmark-only plaintext ws:// broker launcher.
#
# The shipped `hyrxmq-listen` cannot serve the WSS tier in this build:
#   1. HYRXMQ_WSS_TLS_MODE=none is refused by WSSAMQPListener.start, and
#   2. with a cert (path/injected) WSSAMQPListener.serve_forever raises because
#      the default event_driven_serving()=True loop reads the raw fd and cannot
#      de-frame WebSocket bytes.
#
# This launcher composes the SAME two objects the broker's WSS wrapper uses —
# WSSListener[SystemFileSystemOps] (plaintext, tls_mode "none") and
# AMQPConnServing[WSSConnection] — and drives them with the legacy
# one-connection-at-a-time loop that WSSAMQPListener would use if
# event_driven_serving() were False. It modifies NOTHING under src/; it only
# supplies the serving loop the broker wrapper refuses to run.
#
# Build:
#   mojo build -I src -I vendor/flare benchmarks/interfaces/ws_broker.mojo \
#       -o build/hyrxmq-ws-bench

from std.os import getenv
from std.collections import List

from hyrx.core.storage import SystemFileSystemOps
from hyrxmq.config import HyrxMQConfig
from hyrx.transport.wss import WSSListener, WSSConnection, WssConfig
from hyrxmq.listener import AMQPConnServing


def main() raises:
    var host = getenv("HYRXMQ_HOST", "127.0.0.1")
    var port = Int(getenv("HYRXMQ_WSS_LISTEN", "0"))

    var cfg = HyrxMQConfig()
    cfg.listen_host = host.copy()
    var fm = getenv("HYRXMQ_FRAME_MAX", "")
    if len(fm.bytes()) > 0:
        var frame_max = Int(fm)
        if frame_max < 4096:
            raise "ws_broker: HYRXMQ_FRAME_MAX below the AMQP frame_min 4096"
        cfg.frame_max = frame_max

    # Plaintext ws:// tier: the exact WssConfig the transport test uses.
    var wcfg = WssConfig()
    wcfg.host = host.copy()
    wcfg.port = port
    wcfg.tls_mode = "none"
    wcfg.allow_all = True
    wcfg.origin_allowlist = List[String]()

    var ops = SystemFileSystemOps()
    var listener = WSSListener[SystemFileSystemOps](wcfg^, ops^)
    var srv = AMQPConnServing[WSSConnection](cfg^)
    srv.start_service()
    if not listener.start():
        raise "ws_broker: bind failed"
    print(
        "HyrxMQ ws_broker (plaintext ws://, legacy WSS loop) listening on ws://"
        + host
        + ":"
        + String(listener.port())
    )
    while True:
        var conn = listener.accept_connection()
        if conn.__bool__():
            var slot = srv.register(conn^)
            if slot >= 0:
                while True:
                    var rc = srv.serve_one_frame(slot)
                    if rc < 0:
                        break
                    _ = srv.drain_and_send(slot)