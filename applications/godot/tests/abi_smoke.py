#!/usr/bin/env python3
"""ABI smoke test for libscr_sim.so (104_contract.md §3).

Loads the shared library through ctypes exactly like the Godot GDExtension
adapter will (dlopen + C calls), exercises every exported symbol, every
SCR_ERR_* path, and asserts the first-step snapshot is byte-identical to the
golden fixture (tests/fixtures/snapshot_seed1_tick1.bin).

Usage (from repo root):
    python3 applications/godot/tests/abi_smoke.py [path/to/libscr_sim.so]

Default library path: applications/godot/build/libscr_sim.so
Exit code 0 = all checks passed; 1 = failure (loud, never silently coerced).
"""

from __future__ import annotations

import ctypes
import os
import sys

# Scripted input — must stay identical to tests/mojo/gen_golden_fixture.mojo
# and tests/mojo/test_golden_fixture.mojo.
SEED = 1
MOVE_X = 0.5
MOVE_Y = 1.0
LOOK_DX = 0.25
LOOK_DY = -0.1
JUMP = 1
SPRINT = 0

FIXTURE_REL = "applications/godot/tests/fixtures/snapshot_seed1_tick1.bin"
DEFAULT_SO = "applications/godot/build/libscr_sim.so"

SCR_ERR_NOT_INIT = -1
SCR_ERR_BUF_SMALL = -3
SCR_ERR_BAD_STATE = -4

SCR_SEC_PLAYER = 1
SCR_SEC_TERRAIN_META = 2
SCR_SEC_TERRAIN = 3
SCR_SEC_OCEAN = 4
SCR_SEC_SKY = 5
SCR_SEC_MATERIALS = 6

FIXED_DT = 1.0 / 60.0

_failures: list[str] = []


def check(cond: bool, msg: str) -> None:
    if cond:
        print(f"  PASS  {msg}")
    else:
        print(f"  FAIL  {msg}")
        _failures.append(msg)


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


class ScrInputBatch(ctypes.Structure):
    """Must match adapter/scr_godot_abi.h `scr_input_batch` (20 bytes packed)."""

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


def scripted_input() -> ScrInputBatch:
    b = ScrInputBatch()
    b.move_x = MOVE_X
    b.move_y = MOVE_Y
    b.look_dx = LOOK_DX
    b.look_dy = LOOK_DY
    b.jump = JUMP
    b.sprint = SPRINT
    return b


def main() -> int:
    so_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SO
    if not os.path.isfile(so_path):
        print(f"library not found: {so_path}")
        print("build it first: mojo build export/abi.mojo -I src/mojo "
              "--emit shared-lib -o ../../build/libscr_sim.so")
        return 1

    root = repo_root()
    fixture_path = os.path.join(root, FIXTURE_REL)
    with open(fixture_path, "rb") as fh:
        fixture = fh.read()

    print(f"loading {so_path}")
    lib = ctypes.CDLL(os.path.abspath(so_path))

    # Exact signatures (scr_godot_abi.h).
    lib.scr_sim_init.argtypes = [ctypes.c_uint32]
    lib.scr_sim_init.restype = ctypes.c_int32
    lib.scr_sim_shutdown.argtypes = []
    lib.scr_sim_shutdown.restype = None
    lib.scr_sim_abi_version.argtypes = []
    lib.scr_sim_abi_version.restype = ctypes.c_uint32
    lib.scr_sim_schema_version.argtypes = []
    lib.scr_sim_schema_version.restype = ctypes.c_uint32
    lib.scr_sim_step.argtypes = [ctypes.c_double, ctypes.POINTER(ScrInputBatch)]
    lib.scr_sim_step.restype = ctypes.c_int32
    lib.scr_sim_snapshot_size.argtypes = []
    lib.scr_sim_snapshot_size.restype = ctypes.c_uint32
    lib.scr_sim_snapshot_write.argtypes = [
        ctypes.POINTER(ctypes.c_uint8),
        ctypes.c_uint32,
    ]
    lib.scr_sim_snapshot_write.restype = ctypes.c_int32

    print("\n[1] layout + version gate (adapter startup rejection)")
    check(
        ctypes.sizeof(ScrInputBatch) == 20,
        f"scr_input_batch is 20 bytes packed (got {ctypes.sizeof(ScrInputBatch)})",
    )
    abi_v = lib.scr_sim_abi_version()
    schema_v = lib.scr_sim_schema_version()
    check(abi_v == 1, f"scr_sim_abi_version() == 1 (got {abi_v})")
    check(schema_v == 1, f"scr_sim_schema_version() == 1 (got {schema_v})")

    print("\n[2] pre-init error codes")
    check(
        lib.scr_sim_step(FIXED_DT, None) == SCR_ERR_NOT_INIT,
        "step before init returns SCR_ERR_NOT_INIT (-1)",
    )
    check(lib.scr_sim_snapshot_size() == 0, "snapshot_size before init is 0")
    buf16 = (ctypes.c_uint8 * 16)()
    check(
        lib.scr_sim_snapshot_write(buf16, 16) == SCR_ERR_NOT_INIT,
        "snapshot_write before init returns -1",
    )

    print("\n[3] init + first step (golden trajectory)")
    rc = lib.scr_sim_init(SEED)
    check(rc == 0, f"scr_sim_init({SEED}) == 0 (got {rc})")
    check(lib.scr_sim_snapshot_size() == 0, "snapshot_size before first step is 0")
    check(
        lib.scr_sim_snapshot_write(buf16, 16) == SCR_ERR_BAD_STATE,
        "snapshot_write before first step returns SCR_ERR_BAD_STATE (-4)",
    )

    inp = scripted_input()
    ticks = lib.scr_sim_step(FIXED_DT, ctypes.byref(inp))
    check(ticks == 1, f"dt=1/60 runs exactly one tick (got {ticks})")

    size = lib.scr_sim_snapshot_size()
    check(size == len(fixture), f"snapshot size {size} == fixture {len(fixture)}")

    buf = (ctypes.c_uint8 * size)()
    written = lib.scr_sim_snapshot_write(buf, size)
    check(written == size, f"snapshot_write returns {written} == {size}")
    snapshot = bytes(buf)
    check(snapshot == fixture, "FFI snapshot byte-identical to golden fixture")
    check(snapshot[:4] == b"SCRS", "magic bytes 'SCRS'")
    check(snapshot[4:8] == b"\x01\x00\x00\x00", "schema_version == 1 (LE)")

    # Section framing walk (§4.2).
    import struct as _st

    section_count = _st.unpack_from("<I", snapshot, 8)[0]
    payload_bytes = _st.unpack_from("<I", snapshot, 40)[0]
    check(section_count == 6, f"section_count == 6 (got {section_count})")
    check(
        payload_bytes == len(snapshot) - 48,
        f"payload_bytes {payload_bytes} == len-48",
    )
    off = 48
    ids = []
    for _ in range(section_count):
        sid, slen = _st.unpack_from("<II", snapshot, off)
        ids.append(sid)
        off += 8 + slen
    check(
        ids == [1, 2, 3, 4, 5, 6],
        f"section ids in contract order (got {ids})",
    )
    check(off == len(snapshot), "framing consumes the payload exactly")

    print("\n[4] buffer guard + terrain suppression")
    check(
        lib.scr_sim_snapshot_write(buf16, 16) == SCR_ERR_BUF_SMALL,
        "cap < size returns SCR_ERR_BUF_SMALL (-3)",
    )
    ticks2 = lib.scr_sim_step(FIXED_DT, ctypes.byref(inp))
    check(ticks2 == 1, f"second step runs one tick (got {ticks2})")
    size2 = lib.scr_sim_snapshot_size()
    check(size2 < size, f"TERRAIN suppressed on second snapshot ({size2} < {size})")

    print("\n[5] null input = idle batch")
    ticks3 = lib.scr_sim_step(FIXED_DT, None)
    check(ticks3 == 1, f"step with NULL input runs one tick (got {ticks3})")

    print("\n[6] shutdown + re-init")
    lib.scr_sim_shutdown()
    check(
        lib.scr_sim_step(FIXED_DT, None) == SCR_ERR_NOT_INIT,
        "step after shutdown returns -1",
    )
    check(lib.scr_sim_snapshot_size() == 0, "snapshot_size after shutdown is 0")
    rc2 = lib.scr_sim_init(SEED)
    check(rc2 == 0, f"re-init after shutdown == 0 (got {rc2})")
    ticks4 = lib.scr_sim_step(FIXED_DT, None)
    check(ticks4 == 1, f"step after re-init runs (got {ticks4})")
    size4 = lib.scr_sim_snapshot_size()
    check(size4 > 0, "snapshot after re-init non-empty")
    lib.scr_sim_shutdown()

    print()
    if _failures:
        print(f"ABI SMOKE FAILED: {len(_failures)} check(s)")
        for msg in _failures:
            print(f"  - {msg}")
        return 1
    print("ABI SMOKE PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
