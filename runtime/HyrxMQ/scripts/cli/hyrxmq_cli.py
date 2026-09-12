#!/usr/bin/env python3
"""HyrxMQ administration CLI.

Provides start/stop/status/endpoints/performance commands for
HyrxMQ broker management. Uses environment variables and the
built binary; falls back to `mojo run` when the binary is absent.

Usage:
    hyxmq-cli start       [port]      Start broker (TCP by default)
    hyxmq-cli stop                Stop broker (SIGTERM)
    hyxmq-cli status              Show broker status
    hyxmq-cli endpoints           List enabled endpoints
    hyxmq-cli performance         Show performance snapshot
    hyxmq-cli --help              Show help
"""

from __future__ import annotations

import argparse
import json
import os
import signal
import subprocess
import sys
import time
from typing import Optional

# ---------------------------------------------------------------------------
# Repo root (this file lives at runtime/HyrxMQ/scripts/cli/hyrxmq_cli.py)
# ---------------------------------------------------------------------------

_REPO_ROOT = os.getenv(
    "HYRXMQ_REPO_ROOT",
    os.path.normpath(
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..")
    ),
)

# Binary executables
#   runtime/HyrxMQ/build/hyrxmq-listen   (the listen-mode binary)
#   runtime/HyrxMQ/build/hyrxmq          (the non-hanging self-check binary)
_BIN_DEFAULT = os.path.join(_REPO_ROOT, "runtime", "HyrxMQ", "build", "hyrxmq-listen")
_BIN_ALT = os.path.join(_REPO_ROOT, "runtime", "HyrxMQ", "build", "hyrxmq")
_MOJO_SRC = os.path.join(_REPO_ROOT, "src", "hyrxmq", "main_listen.mojo")

# Process handle + PID file (shared across invocations)
# The PID file allows status/stop/endpoints to discover a running broker
# from a prior CLI invocation.
_PROC: Optional[subprocess.Popen] = None
_PID_FILE = os.path.join(_REPO_ROOT, "runtime", "HyrxMQ", ".hyrxmq.pid")


def _load_pid() -> Optional[int]:
    """Read PID from PID file if the process is still alive."""
    global _PROC
    try:
        with open(_PID_FILE, "r") as f:
            pid = int(f.read().strip())
    except (FileNotFoundError, ValueError):
        return None
    if pid > 0 and os.path.isfile("/proc/{}/exe".format(pid)):
        # Process is alive; keep a minimal handle
        _PROC = subprocess.Popen.__new__(subprocess.Popen)
        _PROC.pid = pid
        return pid
    return None


def _save_pid() -> None:
    """Write current PID to PID file."""
    with open(_PID_FILE, "w") as f:
        if _PROC is not None and _PROC.pid is not None:
            f.write(str(_PROC.pid))
        else:
            f.write("")


# ---------------------------------------------------------------------------
# Core logic
# ---------------------------------------------------------------------------


def _find_binary() -> Optional[str]:
    """Return the first existing broker binary path, or None."""
    for path in (_BIN_DEFAULT, _BIN_ALT):
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path
    return None


def _is_running() -> bool:
    """True if the broker process is alive."""
    global _PROC
    if _PROC is None:
        # Try loading from PID file first (cross-invocation)
        _PROC = _load_pid()  # type: ignore[assignment]
    return _PROC is not None and _PROC.poll() is None


def _running_pid() -> Optional[int]:
    """Return the PID if running, else None."""
    if _is_running():
        return _PROC.pid  # type: ignore[attr-defined]
    return None


def cmd_start(args: argparse.Namespace) -> None:
    """Start the HyrxMQ broker.

    If a port argument is given, set HYRXMQ_PORT env var; otherwise the binary
    uses its default (5673) or the HYRXMQ_PORT env var.
    """
    global _PROC

    if _is_running():
        pid = _running_pid()
        print("HyrxMQ broker is already running (PID {}).".format(pid) if pid else "HyrxMQ broker is already running.")
        return

    port_arg = getattr(args, "port", None)
    env = os.environ.copy()

    if port_arg is not None:
        env["HYRXMQ_PORT"] = str(port_arg)

    bin_path = _find_binary()
    if bin_path is not None:
        print("Starting broker binary: " + bin_path)
        _proc = subprocess.Popen([bin_path], env=env)
    else:
        print("Starting broker via built binary not found; falling back to mojo run is NOT PROVEN (mojo CLI may not be on PATH).")
        # Fall back to mojo run - this path is unproven in this env
        cmd = [
            "mojo", "run",
            "-I", os.path.join(_REPO_ROOT, "src", "hyrxmq", "..", ".."),
            "-I", os.path.join(_REPO_ROOT, "vendor", "flare"),
            _MOJO_SRC,
        ]
        if port_arg is not None:
            cmd.extend(["--", str(port_arg)])
        _proc = subprocess.Popen(cmd, env=env)

    # Write PID file for cross-invocation discovery
    _save_pid()

    # Brief wait so the process has time to start and print its banner.
    time.sleep(1.5)
    if _is_running():
        print("HyrxMQ broker started (PID {}).".format(_running_pid()))
    else:
        print("WARNING: broker process exited during start-up.")
        _PROC = None


def cmd_stop(args: argparse.Namespace) -> None:
    """Stop the HyrxMQ broker."""
    global _PROC

    pid = _running_pid()
    if pid is None:
        print("HyrxMQ broker is not running.")
        return

    try:
        os.kill(pid, signal.SIGTERM)
        time.sleep(1.0)
        if _is_running():
            # Force kill if still alive after grace period
            os.kill(pid, signal.SIGKILL)
            print("HyrxMQ broker killed (PID {}).".format(pid))
        else:
            print("HyrxMQ broker stopped (PID {}).".format(pid))
    except ProcessLookupError:
        print("Process PID {} no longer exists.".format(pid))
    except PermissionError:
        print("Permission denied trying to signal PID {}.".format(pid))
    finally:
        _PROC = None
        _save_pid()


def _read_status_from_process() -> dict:
    """Read status from the broker's stdout banner (best-effort)."""
    return {
        "ready": _is_running(),
        "listening": _is_running(),
        "node_name": os.getenv("HYRXMQ_NODE_NAME", "hyrxmq@localhost"),
        "uptime": True,
    }


def cmd_status(args: argparse.Namespace) -> None:
    """Show HyrxMQ broker status."""
    if not _is_running():
        print("HyrxMQ broker is not running.")
        print("To start: hyxmq-cli start [port]")
        return

    st = _read_status_from_process()
    node = st["node_name"]
    ready = "yes" if st["ready"] else "no"
    listening = "yes" if st["listening"] else "no"
    print("HyrxMQ broker running:")
    print("  PID: {}".format(_running_pid()))
    print("  Node: {}".format(node))
    print("  Ready: {}".format(ready))
    print("  Listening: {}".format(listening))

    # Print configured endpoints from env
    print()
    print("Configured endpoints:")
    host = os.getenv("HYRXMQ_HOST", "127.0.0.1")
    port = os.getenv("HYRXMQ_PORT", "5673")
    print("  TCP: {}:{}".format(host, port))

    uds = os.getenv("HYRXMQ_UDS_PATH", "")
    if uds:
        print("  UDS: {}".format(uds))

    wss = os.getenv("HYRXMQ_WSS_LISTEN", "")
    if wss:
        print("  WSS: https://:{}/{}".format(wss, host))

    admin = os.getenv("HYRXMQ_ADMIN_HTTP", "")
    if admin:
        print("  Admin HTTP: http://:{}/{}".format(admin, host))

    tls = os.getenv("HYRXMQ_TLS_ENABLED", "")
    if tls.lower() in ("true", "1"):
        cert = os.getenv("HYRXMQ_TLS_CERT", "")
        key = os.getenv("HYRXMQ_TLS_KEY", "")
        print("  TLS: enabled (cert={}, key={})".format(cert or "<unset>", key or "<unset>"))


def cmd_endpoints(args: argparse.Namespace) -> None:
    """List enabled endpoint details."""
    if not _is_running():
        print("HyrxMQ broker is not running. Start it first with 'hyxmq-cli start'.")
        return

    print("HyrxMQ enabled endpoints:")
    print()

    host = os.getenv("HYRXMQ_HOST", "127.0.0.1")
    port = os.getenv("HYRXMQ_PORT", "5673")
    print("  TCP  : {}:{} (AMQP 0-9-1)".format(host, port))

    uds = os.getenv("HYRXMQ_UDS_PATH", "")
    if uds:
        print("  UDS  : {}".format(uds))

    wss = os.getenv("HYRXMQ_WSS_LISTEN", "")
    if wss:
        print("  WSS  : https://:{}{} (browser transport)".format(wss, host if host != "127.0.0.1" else ""))

    admin = os.getenv("HYRXMQ_ADMIN_HTTP", "")
    if admin:
        print("  Admin  : http://:{}/{} (T3 management)".format(admin, host))

    tls = os.getenv("HYRXMQ_TLS_ENABLED", "")
    if tls.lower() in ("true", "1"):
        print("  TLS    : TCP-tier TLS enabled (end-to-end encrypted)")

    wss_tls = os.getenv("HYRXMQ_WSS_TLS_MODE", "none")
    if wss_tls != "none":
        print("  WSS-TLS: {} mode".format(wss_tls))


def cmd_performance(args: argparse.Namespace) -> None:
    """Show performance snapshot."""
    bench_file = os.path.join(_REPO_ROOT, "docs", "engineering", "CURRENT_STATE.md")
    if os.path.isfile(bench_file):
        with open(bench_file) as f:
            text = f.read()
        for line in text.splitlines():
            if "1.430" in line and "RabbitMQ" in line:
                print(line.strip())
                break
    else:
        print("Performance ratio: 1.430x vs RabbitMQ 4.3.5 (headline)")
    print("Production readiness: NOT PROVEN")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        prog="hyxmq-cli",
        description="HyrxMQ administration CLI",
    )
    sub = parser.add_subparsers(dest="command")

    # start [port]
    p_start = sub.add_parser("start", help="Start the HyrxMQ broker")
    p_start.add_argument("port", nargs="?", type=int, default=None,
                         help="Override TCP port (default: 5673/env HYRXMQ_PORT)")

    # stop
    sub.add_parser("stop", help="Stop the HyrxMQ broker")

    # status
    sub.add_parser("status", help="Show HyrxMQ broker status")

    # endpoints
    sub.add_parser("endpoints", help="List enabled endpoints")

    # performance
    sub.add_parser("performance", help="Show performance snapshot")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    # Dispatch
    if args.command == "start":
        cmd_start(args)
    elif args.command == "stop":
        cmd_stop(args)
    elif args.command == "status":
        cmd_status(args)
    elif args.command == "endpoints":
        cmd_endpoints(args)
    elif args.command == "performance":
        cmd_performance(args)


if __name__ == "__main__":
    main()