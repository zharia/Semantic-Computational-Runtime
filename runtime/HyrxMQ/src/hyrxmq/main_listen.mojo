# HyrxMQ listen-mode entry point (Phase 7 unblock).

# SEPARATE entry point from main.mojo so the network-serving binary and the
# non-hanging self-check binary are distinct build targets:
#   mojo build -I src -I vendor/flare src/hyrxmq/main.mojo        -o build/hyrxmq
#   mojo build -I src -I vendor/flare src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen
# The systemd ExecStart path uses the listen binary (packaging/systemd);
# no test ever runs this main().

# The socket comes from AMQPListener (TCP) / UDSAMQPListener (UDS), both on
# hyrx.transport (flare-backed transport contract, ADR-0005); this file must not
# import flare directly.
# std.os / std.sys are Mojo stdlib (getenv / argv), not flare.

# Listen endpoint override (interop audit §11/§12/§17): the reference
# RabbitMQ owns TCP 5672, so this binary must be able to bind elsewhere
# WITHOUT editing config.mojo. Precedence:
#   transport: $HYRXMQ_UDS_PATH non-empty -> UDS front end; else TCP (default)
#   port: $HYRXMQ_PORT  ->  argv[1] int  ->  5673 (hardcoded fallback)
#   host: $HYRXMQ_HOST  ->  127.0.0.1    (loopback default; config.mojo's
#                                          0.0.0.0 default is intentionally
#                                          narrowed here so the probe client
#                                          reaches it on 127.0.0.1)
# This env override also serves §17 (environment-driven configuration).
#
# The UDS cell exists so a Unix-domain-socket connection can be benchmarked
# against TCP through the SAME connection-negotiation + content-frame serving
# path (both delegate to AMQPConnServing). The TCP default is unchanged.

from std.os import getenv
from std.sys import argv

from hyrx.core.storage import (
    MessageJournal,
    SystemFileSystemOps,
    STORAGE_MODE_DISABLED,
    STORAGE_MODE_FILE,
    STORAGE_MODE_MEMORY,
)
from hyrxmq.config import HyrxMQConfig
from hyrxmq.listener import AMQPListener, UDSAMQPListener


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


def _resolve_storage_mode() -> Int:
    """The configured storage mode (DISABLED by default — zero fs use)."""
    var getter = getenv("HYRXMQ_STORAGE_MODE", "disabled")
    if getter == "memory":
        return STORAGE_MODE_MEMORY()
    if getter == "file":
        return STORAGE_MODE_FILE()
    return STORAGE_MODE_DISABLED()


def _attach_storage_journal(mut listener: AMQPListener, mode: Int) raises:
    """Wire the storage journal into the TCP listener (the bootstrap wire).

    disabled = NO storage class at all (zero fs activity — the default tier
    is untouched); memory = the RAM WAL; file = the WAL through the supplied
    SystemFileSystemOps. Recovery replays ONLY in file mode (a memory-tier
    restart survives nothing by definition)."""
    if mode == STORAGE_MODE_DISABLED():
        return
    if mode == STORAGE_MODE_MEMORY():
        listener.attach_journal(MessageJournal.memory())
        return
    var ops = SystemFileSystemOps()
    var path = getenv("HYRXMQ_STORAGE_PATH", "")
    listener.attach_journal(MessageJournal.file(path^, ops^))
    _ = listener.recover_journal()


def _attach_storage_journal_uds(mut listener: UDSAMQPListener, mode: Int) raises:
    """UDS twin of _attach_storage_journal (the SAME knobs/semantics)."""
    if mode == STORAGE_MODE_DISABLED():
        return
    if mode == STORAGE_MODE_MEMORY():
        listener.attach_journal(MessageJournal.memory())
        return
    var ops = SystemFileSystemOps()
    var path = getenv("HYRXMQ_STORAGE_PATH", "")
    listener.attach_journal(MessageJournal.file(path^, ops^))
    _ = listener.recover_journal()


def main() raises:
    var cfg = HyrxMQConfig()
    cfg.listen_host = getenv("HYRXMQ_HOST", "127.0.0.1")
    cfg.port = _resolve_port()
    # frame_max override (interop content-frame gate): when HYRXMQ_FRAME_MAX is
    # set it becomes BOTH the advertised connection.tune frame-max AND the
    # per-connection codec ceiling, so a real client splits its publish into
    # multiple BODY frames and our outbound deliver/get-ok chunks the body
    # across multiple frames too — exercising the §2.3.5 reassembly/chunking in
    # BOTH directions over the socket. When unset, keep the config default. The
    # AMQP 0-9-1 frame_min is 4096, so a smaller override is rejected (fail
    # loud, never advertise an illegal frame-max a real client would refuse).
    var fm = getenv("HYRXMQ_FRAME_MAX", "")
    if len(fm.bytes()) > 0:
        var frame_max = Int(fm)
        if frame_max < 4096:
            raise "main_listen: HYRXMQ_FRAME_MAX below the AMQP frame_min 4096"
        cfg.frame_max = frame_max
    # 0018: pluggable storage bootstrap (the DEFAULT tier is disabled —
    # byte-identical serving with NO fs activity anywhere). HYRXMQ_STORAGE
    # _MODE in {disabled, memory, file}; a file mode REQUIRES a non-empty
    # $HYRXMQ_STORAGE_PATH and wires the WAL through the supplied
    # SystemFileSystemOps (the ONLY fs-seam impl used by the listen binary).
    var storage_mode = getenv("HYRXMQ_STORAGE_MODE", "disabled")
    if storage_mode == "disabled":
        cfg.storage_mode = "disabled"
    elif storage_mode == "memory":
        cfg.storage_mode = "memory"
    elif storage_mode == "file":
        cfg.storage_mode = "file"
        cfg.storage_path = getenv("HYRXMQ_STORAGE_PATH", "")
        if len(cfg.storage_path.strip().bytes()) == 0:
            raise "main_listen: HYRXMQ_STORAGE_MODE=file requires HYRXMQ_STORAGE_PATH"
    else:
        raise "main_listen: invalid HYRXMQ_STORAGE_MODE '" + storage_mode + "' (disabled|memory|file)"
    cfg.validate()
    var node = cfg.node_name
    # Storage journal (0018): wired ONLY when configured; disabled = no
    # storage class at ALL (both bootstrap branches stay byte-identical).
    # Transport selection (fair UDS benchmark cell): a non-empty
    # $HYRXMQ_UDS_PATH binds the UDS front end; otherwise TCP exactly as before.
    var uds_path = getenv("HYRXMQ_UDS_PATH", "")
    if len(uds_path.bytes()) > 0:
        var ulistener = UDSAMQPListener(uds_path^, cfg^)
        _attach_storage_journal_uds(ulistener, _resolve_storage_mode())
        if not ulistener.start():
            raise "main_listen: uds listener failed to start"
        print("HyrxMQ " + node + " listening on uds:" + ulistener.path())
        ulistener.serve_forever()
        return
    var host = cfg.listen_host
    var listener = AMQPListener(cfg^)
    _attach_storage_journal(listener, _resolve_storage_mode())
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
