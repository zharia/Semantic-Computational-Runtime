#!/usr/bin/env python3
"""TERRAIN resend gate (104_contract §4.3 presence rule, 0007 §4 edit path).

TERRAIN is emitted when `world_version != last_terrain_resend` tracker value.
An APPLIED edit bumps world_version exactly once, so the NEXT snapshot must
carry TERRAIN exactly once, then suppress it again until the next mutation.

Flow (ctypes, like the GDExtension adapter):
  1. init + idle step            -> snapshot 1 carries TERRAIN (first send)
  2. look down hard (look_dy>0), step -> no version bump, TERRAIN absent
  3. scr_edit_submit(DIG) + step -> applied edit bumps world_version
     -> snapshot carries TERRAIN again (resent exactly once)
  4. idle step                   -> TERRAIN suppressed again

Usage (from repo root):
    python3 applications/godot/tests/test_terrain_resend.py [path/to/libscr_sim.so]
Exit 0 = pass, 1 = fail.
"""

from __future__ import annotations

import ctypes
import os
import struct
import sys

DEFAULT_SO = "applications/godot/build/libscr_sim.so"
SEED = 1
FIXED_DT = 1.0 / 60.0
SCR_SEC_TERRAIN = 3
SCR_ERR_NOT_INIT = -1

# Big enough to slam pitch to the -1.45 clamp in one tick
# (MOUSE_SENSITIVITY = 0.0025 rad/unit → 600 * 0.0025 = 1.5 > 1.45).
LOOK_DOWN_DY = 600.0

_failures: list[str] = []


def check(cond: bool, msg: str) -> None:
    if cond:
        print(f"  PASS  {msg}")
    else:
        print(f"  FAIL  {msg}")
        _failures.append(msg)


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


class ScrEditBatch(ctypes.Structure):
    _fields_ = [
        ("op", ctypes.c_uint8),
        ("select_slot", ctypes.c_uint8),
        ("reserved", ctypes.c_uint16),
    ]


def idle_input() -> ScrInputBatch:
    return ScrInputBatch()


def look_down_input() -> ScrInputBatch:
    b = ScrInputBatch()
    b.look_dy = LOOK_DOWN_DY
    return b


def step(lib: ctypes.CDLL, inp: ScrInputBatch | None) -> int:
    arg = ctypes.byref(inp) if inp is not None else None
    ticks = lib.scr_sim_step(FIXED_DT, arg)
    if ticks < 0:
        raise SystemExit(f"scr_sim_step failed: {ticks}")
    return ticks


def write_snapshot(lib: ctypes.CDLL) -> bytes:
    size = lib.scr_sim_snapshot_size()
    if size <= 0:
        raise SystemExit("snapshot_size == 0")
    buf = (ctypes.c_uint8 * size)()
    written = lib.scr_sim_snapshot_write(buf, size)
    if written != size:
        raise SystemExit(f"snapshot_write {written} != {size}")
    return bytes(buf)


def has_terrain(snapshot: bytes) -> bool:
    section_count = struct.unpack_from("<I", snapshot, 8)[0]
    off = 48
    for _ in range(section_count):
        sid, slen = struct.unpack_from("<II", snapshot, off)
        if sid == SCR_SEC_TERRAIN:
            return True
        off += 8 + slen
    if off != len(snapshot):
        raise SystemExit("section framing does not consume the payload")
    return False


def world_version(snapshot: bytes) -> int:
    return struct.unpack_from("<I", snapshot, 12)[0]


def main() -> int:
    so_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SO
    if not os.path.isfile(so_path):
        print(f"library not found: {so_path}")
        print("build it first: mojo build export/abi.mojo -I src/mojo "
              "--emit shared-lib -o ../../build/libscr_sim.so")
        return 1

    print(f"loading {so_path}")
    lib = ctypes.CDLL(os.path.abspath(so_path))
    lib.scr_sim_init.argtypes = [ctypes.c_uint32]
    lib.scr_sim_init.restype = ctypes.c_int32
    lib.scr_sim_shutdown.argtypes = []
    lib.scr_sim_shutdown.restype = None
    lib.scr_sim_step.argtypes = [ctypes.c_double, ctypes.POINTER(ScrInputBatch)]
    lib.scr_sim_step.restype = ctypes.c_int32
    lib.scr_sim_snapshot_size.argtypes = []
    lib.scr_sim_snapshot_size.restype = ctypes.c_uint32
    lib.scr_sim_snapshot_write.argtypes = [
        ctypes.POINTER(ctypes.c_uint8),
        ctypes.c_uint32,
    ]
    lib.scr_sim_snapshot_write.restype = ctypes.c_int32
    lib.scr_edit_submit.argtypes = [ctypes.POINTER(ScrEditBatch)]
    lib.scr_edit_submit.restype = ctypes.c_int32

    print("[1] init + first step carries TERRAIN")
    rc = lib.scr_sim_init(SEED)
    if rc != 0:
        print(f"  FAIL  scr_sim_init({SEED}) == 0 (got {rc})")
        return 1
    step(lib, idle_input())
    snap1 = write_snapshot(lib)
    check(has_terrain(snap1), "snapshot 1 carries TERRAIN (first send)")
    v1 = world_version(snap1)
    check(v1 == 1, f"world_version == 1 after first tick (got {v1})")

    print("[2] aim straight down, step: no mutation, TERRAIN suppressed")
    step(lib, look_down_input())
    snap2 = write_snapshot(lib)
    check(
        not has_terrain(snap2),
        "snapshot 2 suppresses TERRAIN (world_version unchanged)",
    )
    v2 = world_version(snap2)
    check(v2 == v1, f"world_version unchanged by looking (got {v2})")

    print("[3] scr_edit_submit(DIG) + step: applied edit resends TERRAIN once")
    batch = ScrEditBatch(op=1, select_slot=1, reserved=0)  # 1 = DIG
    rc_edit = lib.scr_edit_submit(ctypes.byref(batch))
    check(rc_edit == 0, f"edit_submit(DIG) == 0 (got {rc_edit})")
    step(lib, None)
    snap3 = write_snapshot(lib)
    check(
        has_terrain(snap3),
        "snapshot 3 re-emits TERRAIN after the applied edit",
    )
    v3 = world_version(snap3)
    check(
        v3 == v1 + 1,
        f"applied edit bumps world_version exactly once (got {v3})",
    )

    print("[4] idle step: TERRAIN suppressed again (resent exactly once)")
    step(lib, None)
    snap4 = write_snapshot(lib)
    check(
        not has_terrain(snap4),
        "snapshot 4 suppresses TERRAIN again",
    )
    v4 = world_version(snap4)
    check(v4 == v3, f"world_version unchanged by idle tick (got {v4})")

    print("[5] miss edit: consumed without a version bump / resend")
    # Look at empty sky: ray from the eye never hits the heightfield.
    sky = ScrInputBatch()
    # Current pitch is -1.45 (clamped down); one 2000-unit up-look adds
    # +5 rad and clamps at +1.45 (skyward) in a single tick.
    sky.look_dy = -2000.0
    step(lib, sky)
    rc_miss = lib.scr_edit_submit(ctypes.byref(batch))
    check(rc_miss == 0, f"edit_submit on empty queue == 0 (got {rc_miss})")
    step(lib, None)
    snap5 = write_snapshot(lib)
    v5 = world_version(snap5)
    check(
        not has_terrain(snap5),
        "missed ray: no TERRAIN resend",
    )
    check(v5 == v3, f"missed ray bumps no version (got {v5})")

    lib.scr_sim_shutdown()

    print()
    if _failures:
        print(f"TERRAIN RESEND FAILED: {len(_failures)} check(s)")
        for msg in _failures:
            print(f"  - {msg}")
        return 1
    print("TERRAIN RESEND PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
