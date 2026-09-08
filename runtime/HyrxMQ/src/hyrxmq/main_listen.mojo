# HyrxMQ listen-mode entry point (Phase 7 unblock).

# SEPARATE entry point from main.mojo so the network-serving binary and the
# non-hanging self-check binary are distinct build targets:
#   mojo build -I src -I vendor/flare src/hyrxmq/main.mojo        -o build/hyrxmq
#   mojo build -I src -I vendor/flare src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen
# The systemd ExecStart path uses the listen binary (packaging/systemd);
# no test ever runs this main().

# The socket comes from AMQPListener -> hyrx.transport.tcp (flare-backed
# transport contract, ADR-0005); this file must not import flare directly.
# std.os / std.sys are Mojo stdlib (getenv / argv), not flare.

# Listen endpoint override (interop audit §11/§12/§17): the reference
# RabbitMQ owns TCP 5672, so this binary must be able to bind elsewhere
# WITHOUT editing config.mojo. Precedence:
#   port: $HYRXMQ_PORT  ->  argv[1] int  ->  5673 (hardcoded fallback)
#   host: $HYRXMQ_HOST  ->  127.0.0.1    (loopback default; config.mojo's
#                                          0.0.0.0 default is intentionally
#                                          narrowed here so the probe client
#                                          reaches it on 127.0.0.1)
# This env override also serves §17 (environment-driven configuration).

from std.os import getenv
from std.sys import argv

from hyrxmq.config import HyrxMQConfig
from hyrxmq.listener import AMQPListener


# _resolve_port: env HYRXMQ_PORT, else argv[1] (when present and non-empty),
# else 5673. Malformed numeric input raises (fail loud, never silently bind
# the wrong port).
def _resolve_port() raises -> Int:
    var env = getenv("HYRXMQ_PORT", "")
    if len(env.bytes()) > 0:
        return Int(env)
    var args = argv()
    if len(args) > 1 and len(args[1].bytes()) > 0:
        return Int(args[1])
    return 5673


def main() raises:
    var cfg = HyrxMQConfig()
    cfg.listen_host = getenv("HYRXMQ_HOST", "127.0.0.1")
    cfg.port = _resolve_port()
    cfg.validate()
    var node = cfg.node_name
    var host = cfg.listen_host
    var listener = AMQPListener(cfg^)
    if not listener.start():
        raise "main_listen: listener failed to start"
    print(
        "HyrxMQ "
        + node
        + " listening on "
        + host
        + ":"
        + String(listener.port())
    )
    listener.serve_forever()
