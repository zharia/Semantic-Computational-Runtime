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
from hyrxmq.listener import AMQPListener, UDSAMQPListener, WSSAMQPListener
from hyrx.core.storage import FileSystemOps


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


def _attach_storage_journal_wss(
    mut listener: WSSAMQPListener[SystemFileSystemOps], mode: Int
) raises:
    """WSS twin of _attach_storage_journal (the SAME knobs/semantics)."""
    if mode == STORAGE_MODE_DISABLED():
        return
    if mode == STORAGE_MODE_MEMORY():
        listener.attach_journal(MessageJournal.memory())
        return
    var ops = SystemFileSystemOps()
    var path = getenv("HYRXMQ_STORAGE_PATH", "")
    listener.attach_journal(MessageJournal.file(path^, ops^))
    _ = listener.recover_journal()


def _resolve_tls_config(mut cfg: HyrxMQConfig) raises:
    """The TCP-tier TLS env overrides (additive, OFF by default).

    - HYRXMQ_TLS_ENABLED : true|false|1|0 (default absent = OFF, so an
      unconfigured boot is byte-identical to before);
    - HYRXMQ_TLS_CERT    : path to the server certificate chain PEM;
    - HYRXMQ_TLS_KEY     : path to the server private key PEM.
    Enabling TLS requires both paths; validate() enforces the invariant.
    """
    var enabled = getenv("HYRXMQ_TLS_ENABLED", "")
    if len(enabled.bytes()) > 0:
        if enabled == "true" or enabled == "1":
            cfg.tls_enabled = True
        elif enabled == "false" or enabled == "0":
            cfg.tls_enabled = False
        else:
            raise "main_listen: invalid HYRXMQ_TLS_ENABLED '" + enabled + "' (true|false|1|0)"
    cfg.tls_cert_path = getenv("HYRXMQ_TLS_CERT", "")
    cfg.tls_key_path = getenv("HYRXMQ_TLS_KEY", "")


def _resolve_wss_config(mut cfg: HyrxMQConfig) raises:
    """The 0023 WSS env overrides (additive to the storage bootstrap).

    - HYRXMQ_WSS_LISTEN  : port; 0/absent = tier OFF (byte-identical
                           boot with it unset);
    - HYRXMQ_WSS_TLS_MODE: none|injected|path (default none = no cert
      source => the tier refuses to start when the port is open);
    - HYRXMQ_WSS_TLS_PATH  / HYRXMQ_WSS_TLS_KEY : the path-model cert
      chain + key PEM paths (injected mode carries bytes in the tier
      config directly — no env for bytes);
    - HYRXMQ_WSS_ORIGIN  : comma-separated allowlist (0023: EXTENSIBLE
      origin policy — absent = allow-all DEFAULT, an active list
      restricts to it).
    Malformed numbers / unknown modes raise (fail loud).
    """
    var wssl = getenv("HYRXMQ_WSS_LISTEN", "")
    if len(wssl.bytes()) > 0:
        cfg.wss_listen = Int(wssl)
    cfg.wss_tls_mode = getenv("HYRXMQ_WSS_TLS_MODE", "none")
    if (
        cfg.wss_tls_mode != "none"
        and cfg.wss_tls_mode != "injected"
        and cfg.wss_tls_mode != "path"
    ):
        raise (
            "main_listen: invalid HYRXMQ_WSS_TLS_MODE '"
            + cfg.wss_tls_mode
            + "' (none|injected|path)"
        )
    cfg.wss_tls_path = getenv("HYRXMQ_WSS_TLS_PATH", "")
    cfg.wss_tls_key_path = getenv("HYRXMQ_WSS_TLS_KEY", "")
    var origins = getenv("HYRXMQ_WSS_ORIGIN", "")
    if len(origins.bytes()) > 0:
        var items = origins.split(",")
        for i in range(len(items)):
            var t = String(items[i].strip())
            if len(t.bytes()) != 0:
                cfg.wss_origin_allowlist.append(t)


def _resolve_admin_http(mut cfg: HyrxMQConfig) raises:
    """The 0023 T3 admin-HTTP env override (additive to the WSS one).

    - HYRXMQ_ADMIN_HTTP: port; 0/absent = tier OFF (byte-identical boot
      with it unset; the plan default port 25673 must be written
      EXPLICITLY to turn the tier on).
    Malformed numbers raise (fail loud, never silently bind elsewhere).
    The config-file key (admin_http_port) is the T1/T2 surface; this env
    var is the entry-point override, the same pairing as HYRXMQ_WSS_LISTEN.
    """
    var admin = getenv("HYRXMQ_ADMIN_HTTP", "")
    if len(admin.bytes()) > 0:
        cfg.admin_http_port = Int(admin)


def _admin_http_requested(ref cfg: HyrxMQConfig) -> Bool:
    """True when the admin-HTTP tier is configured (port != 0). Called
    BEFORE any bind so the legacy tiers keep their byte path."""
    return cfg.admin_http_port != 0


def _refuse_admin_http(ref cfg: HyrxMQConfig) raises:
    """The 0023 T3 HONEST NOT-YET boot state: fail loud, bind nothing.

    Why the configured admin tier cannot start in this build (the SAME
    single-loop reality the WSS tier declared): the binary serves ONE
    blocking serving loop per process (TCP OR UDS OR WSS), and the
    broker's live counters (messages/queues/consumers) live inside that
    loop's AMQPService with no synchronized cross-loop read. Serving the
    admin reactor concurrently needs the thread model + a synchronized
    snapshot handoff — a needs-probe item, recorded in the T3 receipt,
    never faked here (no bound-but-unserved port, no multi-listener
    passthrough). The AdminHttpListener surface
    (src/hyrx/transport/http_admin.mojo) is complete and is exercised
    standalone by the T4 conformance rows."""
    raise (
        "main_listen: admin-HTTP tier configured (port "
        + String(cfg.admin_http_port)
        + ") but the serving loop is single-tier in this build; "
        "concurrent admin-HTTP + primary serving is NOT-YET (0023 T3 "
        "receipt). Nothing was bound."
    )


def _wss_requested(ref cfg: HyrxMQConfig) -> Bool:
    """True when the WSS tier is configured (port != 0). Called BEFORE
    any ownership transfer so the legacy tiers keep their byte path."""
    return cfg.wss_listen != 0


def _run_wss_maybe(var cfg: HyrxMQConfig) raises -> Bool:
    """Start + serve the WSS tier when _wss_requested(cfg) held. Returns
    whether the tier took over the serving loop.

    Boot shape (0023, HONEST): today's binary serves ONE transport loop
    at a time (UDS OR TCP); multi-tier concurrency needs a thread model
    that does not exist on the serving path, so when WSS is configured
    it becomes the primary (the frontend loop is over WSS, not the TCP
    default). NOT-YET: running TCP -AND- WSS concurrently — declared in
    the 0023 receipt, never faked."""
    var node = cfg.node_name
    var host = cfg.listen_host
    var ops = SystemFileSystemOps()
    var wlistener = WSSAMQPListener[SystemFileSystemOps](cfg^, ops^)
    _attach_storage_journal_wss(wlistener, _resolve_storage_mode())
    if not wlistener.start():
        raise "main_listen: wss listener failed to start"
    print(
        "HyrxMQ "
        + node
        + " listening on wss://"
        + host
        + ":"
        + String(wlistener.port())
    )
    wlistener.serve_forever()
    return True


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
    # TCP-tier TLS (env overrides; additive, OFF by default).
    _resolve_tls_config(cfg)
    # 0023: the WSS tier configuration (env overrides; additive).
    _resolve_wss_config(cfg)
    # 0023 T3: the admin-HTTP tier configuration (env override; additive).
    _resolve_admin_http(cfg)
    cfg.validate()
    var node = cfg.node_name
    # 0023 T3: the admin-HTTP tier, when configured, FAILS LOUD here —
    # before ANY bind (including the WSS tier's) — because the serving
    # loop is single-tier in this build (see _refuse_admin_http and the
    # T3 receipt). Unconfigured => the tiers below behave byte-identically
    # to before.
    if _admin_http_requested(cfg):
        _refuse_admin_http(cfg)
    # 0023: the WSS tier, when configured, takes the serving loop (the
    # ONE serving loop per process; see _run_wss_if_configured and the
    # NOT-YET multi-tier declaration there). Unconfigured => the tiers
    # below behave byte-identically to before.
    if _wss_requested(cfg):
        _ = _run_wss_maybe(cfg^)
        return
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
    # Read the TLS settings BEFORE cfg is consumed by the listener ctor.
    var tls_on = cfg.tls_enabled
    var tls_cert = cfg.tls_cert_path.copy()
    var tls_key = cfg.tls_key_path.copy()
    var listener = AMQPListener(cfg^)
    _attach_storage_journal(listener, _resolve_storage_mode())
    # TCP-tier TLS (optional): enabled via config tls_enabled + cert/key
    # paths. Plaintext remains the default (unconfigured => byte-identical).
    if tls_on:
        listener.configure_tls(tls_cert, tls_key)
        print("HyrxMQ " + node + " TCP TLS enabled")
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
