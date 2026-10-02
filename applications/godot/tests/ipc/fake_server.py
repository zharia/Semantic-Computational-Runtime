#!/usr/bin/env python3
"""fake_server.py — adversarial SCRT server for milestone 0008 Sprint 03.

A stand-in for ``applications/godot/build/scr_sim_server`` that behaves badly
on purpose, so the ADAPTER side of the protocol can be tested (0008 §7 exit
criteria: direction (b) of the version refusal, and the restart cap).

It accepts exactly ONE client, reads the HELLO frame, answers according to
``--mode``, closes, and exits. The adapter supervises it exactly like the real
server, which is the point: the restart/backoff/cap path must not depend on
the peer being well-behaved.

Modes
-----
error-frame   ERROR{code=ERR_VERSION} + close        -> loud refusal (b.1)
bad-abi       HELLO_OK with abi + 1                  -> version mismatch (b.2)
bad-schema    HELLO_OK with schema + 1               -> version mismatch
bad-proto     HELLO_OK with proto + 1                -> version mismatch
crash-loop    HELLO_OK (correct versions), then close-> dies right after the
              handshake: every session ends in EOF, which is what drives the
              adapter's supervised restart + restart cap
              (default mode)

Options
-------
--socket PATH   filesystem UDS to bind (the adapter passes this, as it does
                for the real server)
--seed N        accepted and ignored (adapter always passes --seed)
--mode MODE     see above
--exit-code N   process exit status (default: 0 for refusal modes, 1 for
                crash-loop — a crashing server is not a clean exit)

Environment
-----------
SCR_FAKE_SPAWN_LOG   if set, every start appends ``<pid> <mode>`` to it.
                     The crash-restart test counts these lines to prove that
                     the cap stopped the restart loop (0008 §1.1: > 5
                     restarts / 30 s => fatal, stop stepping).
SCR_FAKE_MODE        default --mode. The adapter spawns its server with a
                     fixed argv (``--socket PATH --seed N``), so a test that
                     wants a specific misbehaviour selects it here.

The socket is unlinked before bind (a stale file from a killed predecessor
must not shadow our bind), and unlinked on the way out for the same reason.

Usage:
    python3 applications/godot/tests/ipc/fake_server.py --socket /tmp/f.sock
    SCR_SIM_SERVER_BIN=.../fake_server.py  # adapter spawns it

Exit: 0 on a clean run, 1 for crash-loop (or --exit-code).
"""

from __future__ import annotations

import argparse
import os
import socket
import struct
import sys

# --- SCRT framing (mirror src/mojo/transport/framing.mojo) -----------------

FRAME_MAGIC = 0x54524353
FRAME_HEADER_BYTES = 16

FT_HELLO = 1
FT_HELLO_OK = 2
FT_ERROR = 3

ERR_VERSION = 2

PROTO_VER = 1
ABI_VER = 2
SCHEMA_VER = 6

MODES = ("crash-loop", "error-frame", "bad-abi", "bad-schema", "bad-proto")


def log(msg: str) -> None:
    print(f"[scr-fake-server pid={os.getpid()}] {msg}", flush=True)


def recv_exact(conn: socket.socket, n: int) -> bytes:
    buf = bytearray()
    while len(buf) < n:
        chunk = conn.recv(n - len(buf))
        if not chunk:
            raise EOFError(f"client closed after {len(buf)}/{n} bytes")
        buf += chunk
    return bytes(buf)


def recv_frame(conn: socket.socket) -> tuple[int, int, bytes]:
    hdr = recv_exact(conn, FRAME_HEADER_BYTES)
    magic, ftype, seq, length = struct.unpack("<IIII", hdr)
    if magic != FRAME_MAGIC:
        raise ValueError(f"bad frame magic 0x{magic:08x}")
    if length > 16 * 1024 * 1024:
        raise ValueError(f"absurd frame payload {length}")
    return ftype, seq, recv_exact(conn, length) if length else b""


def send_frame(conn: socket.socket, ftype: int, seq: int, payload: bytes = b"") -> None:
    conn.sendall(struct.pack("<IIII", FRAME_MAGIC, ftype, seq, len(payload)) + payload)


def main() -> int:
    ap = argparse.ArgumentParser(description="SCR adversarial IPC server (0008 Sprint 03)")
    ap.add_argument("--socket", required=True, help="filesystem UDS path to bind")
    ap.add_argument("--seed", type=int, default=1, help="accepted, ignored")
    ap.add_argument("--mode", choices=MODES, default=None)
    ap.add_argument("--exit-code", type=int, default=None)
    args = ap.parse_args()
    mode = args.mode or os.environ.get("SCR_FAKE_MODE") or "crash-loop"
    if mode not in MODES:
        print(f"[scr-fake-server] unknown mode {mode!r}", file=sys.stderr)
        return 2
    args.mode = mode

    log_path = os.environ.get("SCR_FAKE_SPAWN_LOG")
    if log_path:
        with open(log_path, "a", encoding="utf-8") as fh:
            fh.write(f"{os.getpid()} {args.mode}\n")

    exit_code = args.exit_code
    if exit_code is None:
        exit_code = 1 if args.mode == "crash-loop" else 0

    if os.path.exists(args.socket):
        os.unlink(args.socket)

    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(args.socket)
    srv.listen(1)
    log(f"mode={args.mode} seed={args.seed} socket={args.socket}")

    conn, _ = srv.accept()
    conn.settimeout(10.0)
    try:
        ftype, _seq, _payload = recv_frame(conn)
        if ftype != FT_HELLO:
            log(f"unexpected first frame type {ftype} — closing")
            return 1
        log("HELLO received")

        if args.mode == "error-frame":
            msg = b"server refused the handshake: fake version skew"
            payload = struct.pack("<II", ERR_VERSION, len(msg)) + msg
            send_frame(conn, FT_ERROR, 1, payload)
            log("replied ERROR code=%d and closing" % ERR_VERSION)
        else:
            proto, abi, schema = PROTO_VER, ABI_VER, SCHEMA_VER
            if args.mode == "bad-abi":
                abi = ABI_VER + 1
            elif args.mode == "bad-schema":
                schema = SCHEMA_VER + 1
            elif args.mode == "bad-proto":
                proto = PROTO_VER + 1
            send_frame(conn, FT_HELLO_OK, 1, struct.pack("<III", proto, abi, schema))
            log(f"replied HELLO_OK proto={proto} abi={abi} schema={schema}")
    except Exception as exc:  # noqa: BLE001 - a fake peer failing is data, not a crash
        log(f"error while serving: {exc}")
        return 1
    finally:
        try:
            conn.shutdown(socket.SHUT_RDWR)
        except OSError:
            pass
        conn.close()
        srv.close()
        if os.path.exists(args.socket):
            os.unlink(args.socket)

    log(f"closing after handshake (exit={exit_code})")
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
