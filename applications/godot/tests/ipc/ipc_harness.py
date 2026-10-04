#!/usr/bin/env python3
"""IPC frame harness for milestone 0008 (0008 AP-15..18).

Pure-Python SCRT frame client + in-process FFI driver. No Godot required.

Legs:
  * socket  — spawn/connect to build/scr_sim_server, HELLO handshake,
              INPUT/CMD_TICK uplink, SNAPSHOT capture (per tick, round-trip).
  * in-process — ctypes drive of build/libscr_sim.so exactly like
              tests/abi_smoke.py (scr_sim_init/step/snapshot_write).

Both legs run the same scripted input sequence over the same seed and tick
count, so their concatenated snapshot streams must be byte-identical
(0008 §3.4 / AP-16: framing wraps bytes it never alters). That comparison is
the heart of tests/ipc/test_ipc_determinism.sh; `--self-test` runs the same
comparison at N = 1 as the standalone-server gate (0008 §7).

Modes (exit 0 = pass, 1 = loud failure):
    python3 applications/godot/tests/ipc/ipc_harness.py --self-test
    python3 applications/godot/tests/ipc/ipc_harness.py --restart-check
    python3 applications/godot/tests/ipc/ipc_harness.py \
        --socket /tmp/x.sock --ticks 600 --out /tmp/socket.bin
    python3 applications/godot/tests/ipc/ipc_harness.py \
        --in-process --ticks 600 --out /tmp/inproc.bin
    python3 applications/godot/tests/ipc/ipc_harness.py \
        --socket /tmp/x.sock --wrong-schema 99   # expects ERROR + close

The harness never invents semantics: any protocol violation it observes
(missing HELLO_OK, ERROR frame, snapshot before handshake, seq going
backwards) is reported loudly and fails the run.
"""

from __future__ import annotations

import argparse
import ctypes
import os
import struct
import subprocess
import sys
import tempfile
import time

# --- protocol constants (mirror src/mojo/transport/framing.mojo) ------------

FRAME_MAGIC = 0x54524353
FRAME_HEADER_BYTES = 16
PROTO_VER = 1
ABI_VER = 2
SCHEMA_VER = 7
FIXED_DT = 1.0 / 60.0

FT_HELLO = 1
FT_HELLO_OK = 2
FT_ERROR = 3
FT_SNAPSHOT = 4
FT_INPUT = 5
FT_EDIT = 6
FT_ACK = 7
FT_BYE = 8
FT_CMD_TICK = 9

FLAG_MANUAL_PACE = 0x1
FLAG_EDIT_CAP = 0x2

ERR_PROTOCOL = 1
ERR_VERSION = 2
ERR_MALFORMED = 3
ERR_BUSY = 4
ERR_CAPABILITY = 5
ERR_PACE = 6
ERR_INTERNAL = 7

# Same scripted input as tests/abi_smoke.py + tests/mojo/gen_golden_fixture.mojo
# for tick 0; the rest is a deterministic integer formula (no wall clock, no
# RNG) so both transport legs observe byte-identical batches.
GOLDEN_INPUT = (0.5, 1.0, 0.25, -0.1, 1, 0, 0, 0)

FAILURES: list[str] = []


def check(cond: bool, msg: str) -> None:
    tag = "PASS" if cond else "FAIL"
    print(f"  {tag}  {msg}")
    if not cond:
        FAILURES.append(msg)


def repo_root() -> str:
    env = os.environ.get("SCR_REPO_ROOT")
    if env:
        return env
    cur = os.path.abspath(os.path.dirname(__file__))
    while True:
        if os.path.isfile(
            os.path.join(cur, "lib", "A01_Render", "Material", "materials_catalog.json")
        ):
            return cur
        parent = os.path.dirname(cur)
        if parent == cur:
            raise SystemExit("repo root not found (marker: materials_catalog.json)")
        cur = parent


def scripted_input(tick: int) -> tuple[float, float, float, float, int, int, int, int]:
    """Deterministic per-tick input batch (20 bytes on the wire)."""
    if tick == 0:
        return GOLDEN_INPUT
    move_x = ((tick * 7) % 11 - 5) / 10.0
    move_y = ((tick * 5) % 9 - 4) / 10.0
    look_dx = ((tick * 3) % 13 - 6) / 20.0
    look_dy = ((tick * 11) % 7 - 3) / 20.0
    jump = 1 if tick % 17 == 0 else 0
    sprint = 1 if tick % 5 == 0 else 0
    primary = 1 if tick % 11 == 0 else 0
    secondary = 0
    return (move_x, move_y, look_dx, look_dy, jump, sprint, primary, secondary)


def pack_input(batch: tuple[float, float, float, float, int, int, int, int]) -> bytes:
    return struct.pack("<ffffBBBB", *batch)


# --- SCRT frame codec -------------------------------------------------------


def encode_frame(ftype: int, seq: int, payload: bytes = b"") -> bytes:
    return struct.pack("<IIII", FRAME_MAGIC, ftype, seq, len(payload)) + payload


def recv_exact(sock, n: int) -> bytes:
    buf = bytearray()
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            raise EOFError(f"peer closed after {len(buf)}/{n} bytes")
        buf += chunk
    return bytes(buf)


def recv_frame(sock, max_payload: int = 16 * 1024 * 1024) -> tuple[int, int, bytes]:
    hdr = recv_exact(sock, FRAME_HEADER_BYTES)
    magic, ftype, seq, length = struct.unpack("<IIII", hdr)
    if magic != FRAME_MAGIC:
        raise ValueError(f"bad frame magic 0x{magic:08x}")
    if length > max_payload:
        raise ValueError(f"absurd frame payload {length}")
    payload = recv_exact(sock, length) if length else b""
    return ftype, seq, payload


# --- in-process leg (ctypes, mirrors tests/abi_smoke.py) --------------------


class ScrInputBatch(ctypes.Structure):
    _fields_ = [
        ("move_x", ctypes.c_float),
        ("move_y", ctypes.c_float),
        ("look_dx", ctypes.c_float),
        ("look_dy", ctypes.c_float),
        ("jump", ctypes.c_uint8),
        ("sprint", ctypes.c_uint8),
        ("action_primary", ctypes.c_uint8),
        ("action_secondary", ctypes.c_uint8),
    ]


class ScrFfi:
    def __init__(self, so_path: str):
        self.lib = ctypes.CDLL(so_path)
        self.lib.scr_sim_init.argtypes = [ctypes.c_uint32]
        self.lib.scr_sim_init.restype = ctypes.c_int32
        self.lib.scr_sim_shutdown.argtypes = []
        self.lib.scr_sim_shutdown.restype = None
        self.lib.scr_sim_step.argtypes = [
            ctypes.c_double,
            ctypes.POINTER(ScrInputBatch),
        ]
        self.lib.scr_sim_step.restype = ctypes.c_int32
        self.lib.scr_sim_snapshot_size.argtypes = []
        self.lib.scr_sim_snapshot_size.restype = ctypes.c_uint32
        self.lib.scr_sim_snapshot_write.argtypes = [
            ctypes.POINTER(ctypes.c_uint8),
            ctypes.c_uint32,
        ]
        self.lib.scr_sim_snapshot_write.restype = ctypes.c_int32

    def init(self, seed: int) -> int:
        return int(self.lib.scr_sim_init(seed))

    def shutdown(self) -> None:
        self.lib.scr_sim_shutdown()

    def step(self, batch) -> int:
        return int(self.lib.scr_sim_step(FIXED_DT, ctypes.byref(batch)))

    def snapshot(self) -> bytes:
        size = int(self.lib.scr_sim_snapshot_size())
        if size <= 0:
            raise RuntimeError(f"snapshot size {size} before/without a step")
        buf = (ctypes.c_uint8 * size)()
        written = int(self.lib.scr_sim_snapshot_write(buf, size))
        if written != size:
            raise RuntimeError(f"snapshot_write {written} != size {size}")
        return bytes(buf)


def run_in_process(root: str, seed: int, ticks: int) -> list[bytes]:
    so_path = os.path.join(root, "applications/godot/build/libscr_sim.so")
    if not os.path.isfile(so_path):
        raise SystemExit(f"missing {so_path} — run scripts/build_sim_server.sh first")
    ffi = ScrFfi(so_path)
    rc = ffi.init(seed)
    if rc != 0:
        raise RuntimeError(f"scr_sim_init({seed}) -> {rc}")
    out: list[bytes] = []
    try:
        for t in range(ticks):
            b = ScrInputBatch(*scripted_input(t))
            rc = ffi.step(b)
            if rc < 0:
                raise RuntimeError(f"scr_sim_step tick {t} -> {rc}")
            if rc != 1:
                raise RuntimeError(f"scr_sim_step tick {t} ran {rc} ticks, expected 1")
            out.append(ffi.snapshot())
    finally:
        ffi.shutdown()
    return out


# --- server management ------------------------------------------------------


def server_binary(root: str) -> str:
    return os.path.join(root, "applications/godot/build/scr_sim_server")


def spawn_server(
    root: str,
    sock_path: str,
    seed: int,
    pace: str = "manual",
    bin_path: str | None = None,
) -> subprocess.Popen:
    bin_path = bin_path or server_binary(root)
    if not os.path.isfile(bin_path):
        raise SystemExit(f"missing {bin_path} — run scripts/build_sim_server.sh first")
    if os.path.exists(sock_path):
        os.unlink(sock_path)
    env = dict(os.environ)
    env["SCR_REPO_ROOT"] = root  # catalog lookup must not depend on cwd
    return subprocess.Popen(
        [bin_path, "--socket", sock_path, "--seed", str(seed), "--pace", pace],
        cwd=root,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )


def wait_for_socket(path: str, proc: subprocess.Popen, timeout: float = 10.0) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        if os.path.exists(path):
            return
        rc = proc.poll()
        if rc is not None:
            out = proc.stdout.read() if proc.stdout else ""
            raise RuntimeError(f"server exited {rc} before bind:\n{out}")
        time.sleep(0.02)
    raise TimeoutError(f"socket {path} never appeared")


def finish_server(proc: subprocess.Popen, timeout: float = 15.0) -> tuple[int, str]:
    try:
        rc = proc.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        proc.kill()
        rc = proc.wait(timeout=5)
        out = proc.stdout.read() if proc.stdout else ""
        raise TimeoutError(f"server did not exit (killed):\n{out}")
    out = proc.stdout.read() if proc.stdout else ""
    return rc, out


# --- socket session ---------------------------------------------------------


class SessionResult:
    def __init__(self) -> None:
        self.snapshots: list[bytes] = []
        self.acks: list[int] = []
        self.hello_ok: tuple[int, int, int] | None = None
        self.error: tuple[int, str] | None = None
        self.last_seq = 0


def handshake(
    sock,
    flags: int = FLAG_MANUAL_PACE,
    proto: int = PROTO_VER,
    abi: int = ABI_VER,
    schema: int = SCHEMA_VER,
) -> SessionResult:
    """Send HELLO and require HELLO_OK (or an ERROR we were expecting)."""
    res = SessionResult()
    sock.sendall(encode_frame(FT_HELLO, 1, struct.pack("<IIII", proto, abi, schema, flags)))
    ftype, seq, payload = recv_frame(sock)
    if ftype == FT_HELLO_OK:
        if len(payload) != 12:
            raise ValueError(f"HELLO_OK payload {len(payload)} != 12")
        res.hello_ok = struct.unpack("<III", payload[:12])
        res.last_seq = seq
    elif ftype == FT_ERROR:
        if len(payload) < 8:
            raise ValueError("ERROR payload truncated")
        code, mlen = struct.unpack("<II", payload[:8])
        res.error = (code, payload[8 : 8 + mlen].decode("utf-8", "replace"))
    else:
        raise ValueError(f"expected HELLO_OK/ERROR after HELLO, got type {ftype}")
    return res


def run_socket_session(
    sock,
    ticks: int,
    flags: int = FLAG_MANUAL_PACE,
    send_bye: bool = True,
) -> SessionResult:
    """Handshake + per-tick INPUT/CMD_TICK round-trips, SNAPSHOT capture.

    Waits for each snapshot before sending the next INPUT, so the server's
    persistent input state can never race the uplink (both legs then see the
    exact same batch per tick).
    """
    res = handshake(sock, flags=flags)
    if res.error is not None:
        raise RuntimeError(f"handshake refused: {res.error}")
    assert res.hello_ok is not None
    if res.hello_ok != (PROTO_VER, ABI_VER, SCHEMA_VER):
        raise ValueError(f"HELLO_OK versions {res.hello_ok} != expected")
    if not (flags & FLAG_MANUAL_PACE):
        # wall pace: snapshots arrive unsolicited — fall back to collect mode
        deadline = time.time() + 10.0
        while len(res.snapshots) < ticks and time.time() < deadline:
            _absorb(sock, res, expect=None)
        return res

    seq = 2  # HELLO used seq 1
    for t in range(ticks):
        sock.sendall(encode_frame(FT_INPUT, seq, pack_input(scripted_input(t))))
        seq += 1
        sock.sendall(encode_frame(FT_CMD_TICK, seq, struct.pack("<I", 1)))
        seq += 1
        before = len(res.snapshots)
        guard = time.time() + 15.0
        while len(res.snapshots) == before:
            if time.time() > guard:
                raise TimeoutError(f"no SNAPSHOT for tick {t}")
            _absorb(sock, res, expect=FT_SNAPSHOT)
    if send_bye:
        sock.sendall(encode_frame(FT_BYE, seq, b""))
    return res


def _absorb(sock, res: SessionResult, expect: int | None) -> None:
    """Read one frame; classify it; enforce protocol sanity."""
    ftype, seq, payload = recv_frame(sock)
    if seq <= res.last_seq and ftype != FT_ACK:
        raise ValueError(f"seq not monotonic: {seq} after {res.last_seq}")
    res.last_seq = max(res.last_seq, seq)
    if ftype == FT_SNAPSHOT:
        res.snapshots.append(payload)
    elif ftype == FT_ACK:
        if len(payload) != 4:
            raise ValueError(f"ACK payload {len(payload)} != 4")
        res.acks.append(struct.unpack("<I", payload)[0])
    elif ftype == FT_ERROR:
        code, mlen = struct.unpack("<II", payload[:8])
        res.error = (code, payload[8 : 8 + mlen].decode("utf-8", "replace"))
    elif ftype == FT_HELLO_OK:
        res.hello_ok = struct.unpack("<III", payload[:12])
    else:
        raise ValueError(f"unexpected server frame type {ftype}")


def expect_refusal(
    root: str,
    seed: int,
    proto: int = PROTO_VER,
    abi: int = ABI_VER,
    schema: int = SCHEMA_VER,
    flags: int = FLAG_MANUAL_PACE,
    bin_path: str | None = None,
) -> tuple[int, int, str, str]:
    """Spawn a server, send a mismatched HELLO, require ERROR + close +
    non-zero server exit, and require that no SNAPSHOT ever arrives.

    Returns (error_code, server_rc, message, server_log)."""
    import socket as socket_mod

    tmp = tempfile.mkdtemp(prefix="scr-ipc-refuse-")
    sock_path = os.path.join(tmp, "s.sock")
    proc = spawn_server(root, sock_path, seed, pace="manual", bin_path=bin_path)
    wait_for_socket(sock_path, proc)
    s = socket_mod.socket(socket_mod.AF_UNIX, socket_mod.SOCK_STREAM)
    s.settimeout(10.0)
    try:
        s.connect(sock_path)
        res = handshake(s, flags=flags, proto=proto, abi=abi, schema=schema)
        if res.error is None:
            raise AssertionError(
                f"mismatched HELLO (proto={proto} abi={abi} schema={schema}) accepted"
            )
        # Nothing else must follow: the server must close without snapshots.
        try:
            while True:
                ftype, _, _ = recv_frame(s)
                if ftype == FT_SNAPSHOT:
                    raise AssertionError("SNAPSHOT sent before/during refusal")
        except EOFError:
            pass  # expected: server closed the connection
    finally:
        s.close()
    rc, log = finish_server(proc)
    if os.path.exists(sock_path):
        os.unlink(sock_path)
    os.rmdir(tmp)
    return res.error[0], rc, res.error[1], log



# --- snapshot envelope decoding (104_contract §4.1/§4.2) --------------------

SECTION_TERRAIN = 3


def envelope_sections(payload: bytes) -> dict:
    """Decode the 48-byte envelope + section framing (read-only, no guessing).

    Returns schema_version, section_count, world_version, simulation_tick,
    seed and the list of section ids actually present in this snapshot.
    """
    if len(payload) < 48:
        raise ValueError(f"snapshot {len(payload)} bytes < 48-byte envelope")
    magic, schema, count = struct.unpack_from("<III", payload, 0)
    # Envelope magic is 0x53524353 ("SCRS" bytes, 104_contract §4.1) — the
    # frame header magic (0x54524353, "SCRT") is a different constant.
    if magic != 0x53524353:
        raise ValueError(f"snapshot magic 0x{magic:08x} != 0x53524353")
    world_version = struct.unpack_from("<I", payload, 12)[0]
    tick = struct.unpack_from("<I", payload, 20)[0]
    seed = struct.unpack_from("<I", payload, 28)[0]
    payload_bytes = struct.unpack_from("<I", payload, 40)[0]
    if 48 + payload_bytes > len(payload):
        raise ValueError("envelope payload_bytes exceeds the frame")
    ids: list[int] = []
    off = 48
    for _ in range(count):
        if off + 8 > len(payload):
            raise ValueError("truncated section header")
        sid, sb = struct.unpack_from("<II", payload, off)
        off += 8
        if off + sb > len(payload):
            raise ValueError("truncated section payload")
        ids.append(sid)
        off += sb
    if off != 48 + payload_bytes:
        raise ValueError(f"section walk ended at {off}, payload_bytes {payload_bytes}")
    return {
        "schema_version": schema,
        "section_count": count,
        "world_version": world_version,
        "simulation_tick": tick,
        "seed": seed,
        "section_ids": ids,
    }


def cmd_restart_check(args: argparse.Namespace) -> int:
    """Supervision leg: kill a running server mid-session, restart it the way
    the adapter does (backoff -> fresh spawn -> handshake) and require that

      * the client observes EOF (nothing pretends the session continued),
      * the second session's first snapshot has a RESET tick (< session 1),
      * TERRAIN is re-delivered in that first snapshot (presence rule: first
        snapshot after init — a restart is an init),
      * snapshots keep flowing in the new session.

    This is the harness half of 0008 §1.1 ("adapter/harness"); the adapter
    half is tests/ipc/test_ipc_crash_restart.sh phase A.
    """
    import shutil
    import socket as socket_mod

    root = repo_root()
    tmp = tempfile.mkdtemp(prefix="scr-ipc-restart-")
    sock_path = os.path.join(tmp, "s.sock")
    ok = True

    def note(cond: bool, msg: str) -> None:
        nonlocal ok
        print(f"  {'PASS' if cond else 'FAIL'}  {msg}")
        if not cond:
            ok = False

    # --- session 1 ---------------------------------------------------------
    proc = spawn_server(root, sock_path, args.seed, pace="manual")
    wait_for_socket(sock_path, proc)
    s = socket_mod.socket(socket_mod.AF_UNIX, socket_mod.SOCK_STREAM)
    s.settimeout(15.0)
    try:
        s.connect(sock_path)
        res1 = run_socket_session(s, ticks=20, send_bye=False)
        first1 = envelope_sections(res1.snapshots[0])
        last1 = envelope_sections(res1.snapshots[-1])
        note(
            SECTION_TERRAIN in first1["section_ids"],
            f"session 1 first snapshot carries TERRAIN ({first1['section_count']} sections)",
        )
        note(
            last1["simulation_tick"] > first1["simulation_tick"],
            f"session 1 tick advanced {first1['simulation_tick']} -> {last1['simulation_tick']}",
        )

        # --- crash: SIGKILL, then require a real EOF -----------------------
        proc.kill()
        proc.wait(timeout=10)
        eof_seen = False
        try:
            while True:
                recv_frame(s)
        except EOFError:
            eof_seen = True
        except ValueError as exc:
            note(False, f"post-kill traffic was a protocol violation: {exc}")
        note(eof_seen, "EOF observed after the server was killed")
    finally:
        s.close()

    # --- restart (the adapter's backoff is 100 ms for the first attempt) ----
    time.sleep(0.1)
    try:
        proc2 = spawn_server(root, sock_path, args.seed, pace="manual")
        wait_for_socket(sock_path, proc2)
        s2 = socket_mod.socket(socket_mod.AF_UNIX, socket_mod.SOCK_STREAM)
        s2.settimeout(15.0)
        try:
            s2.connect(sock_path)
            res2 = run_socket_session(s2, ticks=20, send_bye=True)
            first2 = envelope_sections(res2.snapshots[0])
            last2 = envelope_sections(res2.snapshots[-1])
            note(
                first2["simulation_tick"] == 1,
                f"session 2 first snapshot starts at tick 1 (got {first2['simulation_tick']})",
            )
            note(
                first2["simulation_tick"] < last1["simulation_tick"],
                f"tick reset: session 1 ended at {last1['simulation_tick']}, "
                f"session 2 began at {first2['simulation_tick']}",
            )
            note(
                SECTION_TERRAIN in first2["section_ids"],
                "TERRAIN re-delivered in session 2's first snapshot (presence rule)",
            )
            note(
                last2["simulation_tick"] > first2["simulation_tick"],
                f"session 2 kept ticking {first2['simulation_tick']} -> {last2['simulation_tick']}",
            )
            note(
                first2["seed"] == first1["seed"],
                f"fresh session used the same seed ({first2['seed']})",
            )
        finally:
            s2.close()
        rc2, log2 = finish_server(proc2)
        note(rc2 == 0, f"session 2 exited 0 after BYE (got {rc2})")
    except Exception as exc:  # noqa: BLE001 - any exception is a loud failure
        note(False, f"restart leg raised: {exc}")
        ok = False

    shutil.rmtree(tmp, ignore_errors=True)
    return 0 if ok else 1


# --- self-test --------------------------------------------------------------


def cmd_self_test(args: argparse.Namespace) -> int:
    root = repo_root()
    print(f"[scr-ipc-harness] self-test root={root}")

    tmp = tempfile.mkdtemp(prefix="scr-ipc-self-")
    sock_path = os.path.join(tmp, "s.sock")
    proc = spawn_server(root, sock_path, args.seed, pace="manual")
    try:
        wait_for_socket(sock_path, proc)
        import socket as socket_mod

        s = socket_mod.socket(socket_mod.AF_UNIX, socket_mod.SOCK_STREAM)
        s.settimeout(15.0)
        s.connect(sock_path)
        res = run_socket_session(s, ticks=1, flags=FLAG_MANUAL_PACE, send_bye=True)
        s.close()
        check(res.hello_ok is not None, "handshake completed (HELLO_OK)")
        check(
            res.hello_ok == (PROTO_VER, ABI_VER, SCHEMA_VER),
            f"HELLO_OK versions {(PROTO_VER, ABI_VER, SCHEMA_VER)}, got {res.hello_ok}",
        )
        check(len(res.snapshots) == 1, f"exactly 1 SNAPSHOT for CMD_TICK 1 (got {len(res.snapshots)})")
        check(len(res.snapshots[0]) > 0, f"snapshot payload {len(res.snapshots[0])} bytes")
        check(res.error is None, "no ERROR frame observed")
    except Exception as exc:  # noqa: BLE001 - any exception is a loud failure
        check(False, f"socket round-trip raised: {exc}")
        try:
            proc.kill()
        except Exception:  # noqa: BLE001
            pass
        _dump_tail(proc)
        return 1

    rc, log = finish_server(proc)
    check(rc == 0, f"server exit code 0 after BYE (got {rc})")
    check(
        "handshake OK" in log and "session end" in log,
        "server log shows handshake OK + session end",
    )
    if not os.path.exists(os.path.join(root, "applications/godot/build/libscr_sim.so")):
        check(False, "libscr_sim.so missing — in-process comparison unavailable")
    else:
        try:
            inproc = run_in_process(root, args.seed, 1)
            check(
                inproc[0] == res.snapshots[0],
                "AP-16: socket SNAPSHOT == in-process snapshot (tick 1, "
                f"{len(inproc[0])} bytes)",
            )
        except Exception as exc:  # noqa: BLE001
            check(False, f"in-process comparison raised: {exc}")

    # Refusals are part of the standalone-server gate too (0008 §7 AP-17).
    def _refuse_check(label: str, code: int, src: int, msg: str) -> None:
        check(
            code == ERR_VERSION and src != 0 and "mismatch" in msg,
            f"{label} refused: ERROR code={code} server_rc={src} msg={msg!r}",
        )

    try:
        c, r, m, _l = expect_refusal(root, args.seed, schema=99)
        _refuse_check("wrong schema", c, r, m)
    except Exception as exc:  # noqa: BLE001
        check(False, f"wrong schema refusal raised: {exc}")
    try:
        c, r, m, _l = expect_refusal(root, args.seed, abi=99)
        _refuse_check("wrong abi", c, r, m)
    except Exception as exc:  # noqa: BLE001
        check(False, f"wrong abi refusal raised: {exc}")
    try:
        c, r, m, _l = expect_refusal(root, args.seed, proto=99)
        _refuse_check("wrong proto", c, r, m)
    except Exception as exc:  # noqa: BLE001
        check(False, f"wrong proto refusal raised: {exc}")

    try:
        code, src, msg, _log = expect_refusal(root, args.seed, flags=0x4)
        check(
            code == ERR_CAPABILITY and src != 0,
            f"unknown HELLO flag refused: ERROR code={code} server_rc={src}",
        )
    except Exception as exc:  # noqa: BLE001
        check(False, f"unknown-flag refusal raised: {exc}")

    _rmtree(tmp)
    return 1 if FAILURES else 0


def cmd_session(args: argparse.Namespace) -> int:
    """Run one socket or in-process capture; write concatenated bytes."""
    root = repo_root()
    if args.in_process:
        snaps = run_in_process(root, args.seed, args.ticks)
        legs = [("in-process", snaps)]
    else:
        import socket as socket_mod

        if args.connect is None:
            raise SystemExit("--socket PATH or --connect PATH required")
        if args.spawn:
            proc = spawn_server(root, args.connect, args.seed, pace="manual")
            wait_for_socket(args.connect, proc)
        else:
            proc = None
        s = socket_mod.socket(socket_mod.AF_UNIX, socket_mod.SOCK_STREAM)
        s.settimeout(args.timeout)
        try:
            s.connect(args.connect)
            res = run_socket_session(s, args.ticks, send_bye=True)
            legs = [("socket", res.snapshots)]
            if res.error is not None:
                print(f"[scr-ipc-harness] ERROR frame: {res.error}", file=sys.stderr)
                return 1
        finally:
            s.close()
        if proc is not None:
            rc, log = finish_server(proc)
            if rc != 0:
                print(log, file=sys.stderr)
                print(f"[scr-ipc-harness] server exit {rc}", file=sys.stderr)
                return 1
        check(
            len(legs[0][1]) == args.ticks,
            f"captured {len(legs[0][1])} snapshots for {args.ticks} ticks",
        )

    blob = b"".join(legs[0][1])
    if args.out:
        with open(args.out, "wb") as fh:
            fh.write(blob)
        print(
            f"[scr-ipc-harness] wrote {len(blob)} bytes "
            f"({len(legs[0][1])} snapshots) -> {args.out}"
        )
    if args.compare:
        with open(args.compare, "rb") as fh:
            ref = fh.read()
        check(
            blob == ref,
            f"byte-identical to {args.compare} ({len(blob)} vs {len(ref)} bytes)",
        )
    return 1 if FAILURES else 0


def _dump_tail(proc: subprocess.Popen) -> None:
    try:
        if proc.stdout:
            out = proc.stdout.read()
            print(out[-4000:], file=sys.stderr)
    except Exception:  # noqa: BLE001
        pass


def _rmtree(path: str) -> None:
    import shutil

    shutil.rmtree(path, ignore_errors=True)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="SCR IPC frame harness (milestone 0008)")
    p.add_argument("--self-test", action="store_true", help="handshake + 1 tick + refusals")
    p.add_argument(
        "--restart-check",
        action="store_true",
        help="kill + restart a session (supervised-restart harness leg, 0008 §1.1)",
    )
    p.add_argument("--socket", dest="connect", metavar="PATH", help="UDS path to connect to")
    p.add_argument("--spawn", action="store_true", help="spawn the server on --socket first")
    p.add_argument("--in-process", action="store_true", help="drive libscr_sim.so instead")
    p.add_argument("--seed", type=int, default=1)
    p.add_argument("--ticks", type=int, default=1)
    p.add_argument("--out", metavar="FILE", help="write concatenated snapshot bytes")
    p.add_argument("--compare", metavar="FILE", help="assert output equals this file")
    p.add_argument("--timeout", type=float, default=30.0)
    p.add_argument("--wrong-proto", type=int, default=None)
    p.add_argument("--wrong-abi", type=int, default=None)
    p.add_argument("--wrong-schema", type=int, default=None)
    p.add_argument("--wrong-flags", type=int, default=None)
    return p


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        return cmd_self_test(args)
    if args.restart_check:
        return cmd_restart_check(args)
    if (
        args.wrong_proto is not None
        or args.wrong_abi is not None
        or args.wrong_schema is not None
        or args.wrong_flags is not None
    ):
        root = repo_root()
        code, src, msg, log = expect_refusal(
            root,
            args.seed,
            proto=args.wrong_proto if args.wrong_proto is not None else PROTO_VER,
            abi=args.wrong_abi if args.wrong_abi is not None else ABI_VER,
            schema=args.wrong_schema if args.wrong_schema is not None else SCHEMA_VER,
            flags=args.wrong_flags if args.wrong_flags is not None else FLAG_MANUAL_PACE,
        )
        check(code in (ERR_VERSION, ERR_CAPABILITY), f"ERROR code={code}: {msg}")
        check(src != 0, f"server exited non-zero ({src})")
        return 1 if FAILURES else 0
    return cmd_session(args)


if __name__ == "__main__":
    sys.exit(main())
