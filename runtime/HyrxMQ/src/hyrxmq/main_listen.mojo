# HyrxMQ listen-mode entry point (Phase 7 unblock).

# SEPARATE entry point from main.mojo so the network-serving binary and the
# non-hanging self-check binary are distinct build targets:
#   mojo build -I src -I vendor/flare src/hyrxmq/main.mojo        -o build/hyrxmq
#   mojo build -I src -I vendor/flare src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen
# The systemd ExecStart path uses the listen binary (packaging/systemd);
# no test ever runs this main().

# The socket comes from AMQPListener -> hyrx.transport.tcp (flare-backed
# transport contract, ADR-0005); this file must not import flare directly.

from hyrxmq.config import HyrxMQConfig
from hyrxmq.listener import AMQPListener


def main() raises:
    var cfg = HyrxMQConfig()
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
