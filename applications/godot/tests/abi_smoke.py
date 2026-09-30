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
SCR_SEC_VOLCANO = 7  # schema 2 (milestone_0003 §3.2)
SCR_SEC_PLUME = 8
SCR_SEC_SHORE_FOAM = 9  # schema 4 (milestone_0005 §3.3)
SCR_SEC_FLORA = 10  # schema 5 (milestone_0006 §3.2)
SCR_SEC_FAUNA = 11  # schema 5 (milestone_0006 §3.2)

SCHEMA_VERSION = 5  # must match sim/parameters.mojo + adapter/scr_godot_abi.h
SHORE_FOAM_BYTES = 12 + 4 * 64 * 64  # u32 grid_n + f32 cell_size + f32 sea_level + 64² f32
TERRAIN_BYTES_SEED1 = 228100  # schema-3 size: the 4-byte vertex tuple is stride-neutral
FLORA_N_MAX = 4096  # parameters.mojo FLORA_N_MAX (AP-13 cap)
FLOCK_N_MAX = 64  # parameters.mojo FLOCK_N_MAX (AP-13 cap)
FLORA_RECORD_BYTES = 24  # §10: 3xf32 pos + f32 yaw + f32 scale + u32 species_id
FAUNA_RECORD_BYTES = 20  # §11: 3xf32 pos + f32 yaw + u8 species + 3 pad

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
    check(schema_v == SCHEMA_VERSION, f"scr_sim_schema_version() == {SCHEMA_VERSION} (got {schema_v})")

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
    check(
        snapshot[4:8] == b"\x05\x00\x00\x00",
        "schema_version == 5 (LE)",
    )

    # Section framing walk (§4.2), schema 5: sections 1..11.
    import struct as _st

    section_count = _st.unpack_from("<I", snapshot, 8)[0]
    payload_bytes = _st.unpack_from("<I", snapshot, 40)[0]
    check(section_count == 11, f"section_count == 11 (got {section_count})")
    check(
        payload_bytes == len(snapshot) - 48,
        f"payload_bytes {payload_bytes} == len-48",
    )
    off = 48
    ids = []
    spans: dict[int, tuple[int, int]] = {}
    for _ in range(section_count):
        sid, slen = _st.unpack_from("<II", snapshot, off)
        ids.append(sid)
        spans[sid] = (off + 8, slen)
        off += 8 + slen
    check(
        ids == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
        f"section ids in contract order (got {ids})",
    )
    check(off == len(snapshot), "framing consumes the payload exactly")
    check(
        SCR_SEC_VOLCANO in spans and SCR_SEC_PLUME in spans,
        "sections 7 VOLCANO and 8 PLUME present",
    )
    check(SCR_SEC_SHORE_FOAM in spans, "section 9 SHORE_FOAM present")
    check(SCR_SEC_FLORA in spans, "section 10 FLORA present")
    check(SCR_SEC_FAUNA in spans, "section 11 FAUNA present")

    print("\n[3a] SKY field sanity (schema 3, 104_contract §4.3 §5)")
    k_off, k_len = spans[SCR_SEC_SKY]
    check(k_len == 64, f"SKY section is 64 bytes, 16xf32 (got {k_len})")
    (
        hours,
        azimuth,
        elevation,
        fog_density,
        fog_r,
        fog_g,
        fog_b,
        sun_intensity,
        sun_r,
        sun_g,
        sun_b,
        cloud_cover,
        precipitation,
        wind_x,
        wind_z,
        wetness,
    ) = _st.unpack_from("<16f", snapshot, k_off)
    check(0.0 <= hours <= 24.0, f"SKY.time_of_day_hours in [0,24] (got {hours})")
    check(-3.1416 <= azimuth < 3.1416, f"SKY.sun_azimuth folded (got {azimuth})")
    check(-1.3 <= elevation <= 1.3, f"SKY.sun_elevation in arc range (got {elevation})")
    check(fog_density >= 0.0, f"SKY.fog_density >= 0 (got {fog_density})")
    check(sun_intensity >= 0.0, f"SKY.sun_intensity >= 0 (got {sun_intensity})")
    check(0.0 <= cloud_cover <= 1.0, f"SKY.cloud_cover in [0,1] (got {cloud_cover})")
    check(
        0.0 <= precipitation <= 1.0,
        f"SKY.precipitation in [0,1] (got {precipitation})",
    )
    check(0.0 <= wetness <= 1.0, f"SKY.wetness in [0,1] (got {wetness})")
    check(all(0.0 <= c <= 1.0 for c in (fog_r, fog_g, fog_b)), "fog color in [0,1]")
    check(all(0.0 <= c <= 1.0 for c in (sun_r, sun_g, sun_b)), "sun color in [0,1]")

    print("\n[3c] SHORE_FOAM decode (104_contract §4.3 §9, schema 4)")
    f_off, f_len = spans[SCR_SEC_SHORE_FOAM]
    check(
        f_len == SHORE_FOAM_BYTES,
        f"SHORE_FOAM section is 12 + 4*64^2 = {SHORE_FOAM_BYTES} bytes (got {f_len})",
    )
    foam_grid_n, foam_cell_size, foam_sea_level = _st.unpack_from(
        "<Iff", snapshot, f_off
    )
    check(foam_grid_n == 64, f"SHORE_FOAM.grid_n == 64 (got {foam_grid_n})")
    check(
        abs(foam_cell_size - 4.0) < 1e-6,
        f"SHORE_FOAM.cell_size == 4.0 (got {foam_cell_size})",
    )
    check(
        abs(foam_sea_level - 0.0) < 1e-6,
        f"SHORE_FOAM.sea_level == 0.0 (got {foam_sea_level})",
    )
    foam = _st.unpack_from(f"<{64 * 64}f", snapshot, f_off + 12)
    check(
        all(0.0 <= v <= 1.0 for v in foam),
        f"all {len(foam)} foam values in [0,1] "
        f"(min {min(foam):.4f}, max {max(foam):.4f})",
    )
    foam_nz = sum(1 for v in foam if v > 0.0)
    check(
        foam_nz > 0,
        f"shore band carries foam (> 0 cells with F > 0: {foam_nz} near shore)",
    )
    check(max(foam) > 0.0, f"some cells exceed 0 near shore (max {max(foam):.4f})")

    print("\n[3d] TERRAIN vertex blend tuples (104_contract §4.3 §3, schema 4)")
    t_off, t_len = spans[SCR_SEC_TERRAIN]
    check(
        t_len == TERRAIN_BYTES_SEED1,
        f"TERRAIN section stride-neutral vs schema 3 "
        f"({TERRAIN_BYTES_SEED1} bytes, got {t_len})",
    )
    terrain_chunks = _st.unpack_from("<I", snapshot, t_off)[0]
    check(terrain_chunks == 16, f"TERRAIN chunk_count == 16 (got {terrain_chunks})")
    rec_off = t_off + 4
    tuple_count = 0
    blended_count = 0
    for _c in range(terrain_chunks):
        ox, oy, oz, vc, ic = _st.unpack_from("<3fII", snapshot, rec_off)
        payload = rec_off + 20
        tuples_off = payload + 4 * (3 * vc + 3 * vc)  # vertices + normals
        for j in range(vc):
            mat, blend, weight, pad = _st.unpack_from("<4B", snapshot, tuples_off + 4 * j)
            check_guard = (
                mat < 96 and blend < 96 and pad == 0 and weight <= 255
                and (weight > 0 or blend == mat)
            )
            if not check_guard:
                check(
                    False,
                    f"bad TERRAIN tuple at chunk {_c} vertex {j}: "
                    f"({mat}, {blend}, {weight}, {pad})",
                )
                break
            if weight > 0:
                blended_count += 1
            tuple_count += 1
        else:
            rec_off = tuples_off + 4 * vc + 4 * ic
            continue
        break
    check(
        tuple_count == terrain_chunks * 289,
        f"walked {tuple_count} vertex tuples ({terrain_chunks} x 289)",
    )
    check(
        blended_count > 0,
        f"seed-1 terrain carries blended boundary vertices ({blended_count})",
    )

    print("\n[3e] FLORA + FAUNA framing (104_contract §4.3 §10/§11, schema 5)")
    f_off, f_len = spans[SCR_SEC_FLORA]
    check(f_len >= 4, f"FLORA header present (got {f_len} bytes)")
    flora_count = _st.unpack_from("<I", snapshot, f_off)[0]
    check(
        1 <= flora_count <= FLORA_N_MAX,
        f"FLORA count in [1, {FLORA_N_MAX}] (got {flora_count})",
    )
    check(
        f_len == 4 + FLORA_RECORD_BYTES * flora_count,
        f"FLORA strict length 4 + 24*count "
        f"({4 + FLORA_RECORD_BYTES * flora_count}, got {f_len})",
    )
    flora_species = set()
    for i in range(flora_count):
        rec = _st.unpack_from("<5fI", snapshot, f_off + 4 + FLORA_RECORD_BYTES * i)
        sid = rec[5]
        flora_species.add(sid)
        if not (1 <= sid <= 7):
            check(False, f"FLORA[{i}].species_id in 1..7 (got {sid})")
            break
        if not (0.8 <= rec[4] <= 1.35):  # FLORA_SCALE_MIN/MAX
            check(False, f"FLORA[{i}].scale in [0.8, 1.35] (got {rec[4]})")
            break
    else:
        check(True, f"FLORA records well-formed ({flora_count} instances)")
    check(
        len(flora_species) >= 2,
        f"≥2 distinct species in seed-1 FLORA (got {sorted(flora_species)})",
    )

    a_off, a_len = spans[SCR_SEC_FAUNA]
    check(a_len >= 4, f"FAUNA header present (got {a_len} bytes)")
    fauna_count = _st.unpack_from("<I", snapshot, a_off)[0]
    check(
        1 <= fauna_count <= FLOCK_N_MAX,
        f"FAUNA count in [1, {FLOCK_N_MAX}] (got {fauna_count})",
    )
    check(
        a_len == 4 + FAUNA_RECORD_BYTES * fauna_count,
        f"FAUNA strict length 4 + 20*count "
        f"({4 + FAUNA_RECORD_BYTES * fauna_count}, got {a_len})",
    )
    fauna_ok = True
    for i in range(fauna_count):
        rec = _st.unpack_from("<4f4B", snapshot, a_off + 4 + FAUNA_RECORD_BYTES * i)
        species, p0, p1, p2 = rec[4], rec[5], rec[6], rec[7]
        if species != 0 or (p0, p1, p2) != (0, 0, 0):
            check(
                False,
                f"FAUNA[{i}] species==0 and pad==0 "
                f"(got species={species}, pad={(p0, p1, p2)})",
            )
            fauna_ok = False
            break
    if fauna_ok:
        check(True, f"FAUNA records well-formed ({fauna_count} birds)")

    print("\n[3b] VOLCANO + PLUME field sanity (104_contract §4.3 §7/§8)")
    v_off, v_len = spans[SCR_SEC_VOLCANO]
    check(v_len == 32, f"VOLCANO section is 32 bytes (got {v_len})")
    center_x, center_z, radius, lake_level, emissive, crust, glow = (
        _st.unpack_from("<7f", snapshot, v_off)
    )
    effusion_state = snapshot[v_off + 28]
    pad = bytes(snapshot[v_off + 29 : v_off + 32])
    check(radius > 0.0, f"VOLCANO.radius > 0 (got {radius})")
    check(lake_level > 0.0, f"VOLCANO.lake_level above sea level (got {lake_level})")
    check(emissive > 0.0, f"VOLCANO.emissive_intensity > 0 (got {emissive})")
    check(0.0 <= crust <= 1.0, f"VOLCANO.crust_fraction in [0,1] (got {crust})")
    check(glow >= 0.0 and glow <= emissive, f"0 <= glow <= emissive (got {glow})")
    check(glow == 0.0, "day (12:00 start): glow_intensity == 0")
    check(effusion_state in (0, 1), f"effusion_state in {{0,1}} (got {effusion_state})")
    check(pad == b"\x00\x00\x00", f"VOLCANO pad bytes 29..31 are zero (got {pad!r})")

    p_off, p_len = spans[SCR_SEC_PLUME]
    check(p_len == 32, f"PLUME section is 32 bytes (got {p_len})")
    origin_x, origin_y, origin_z, rate, velocity, spread, turbulence, lifetime = (
        _st.unpack_from("<8f", snapshot, p_off)
    )
    check(rate >= 0.0, f"PLUME.rate >= 0 (got {rate})")
    check(velocity > 0.0, f"PLUME.initial_velocity > 0 (got {velocity})")
    check(spread > 0.0, f"PLUME.spread > 0 (got {spread})")
    check(turbulence >= 0.0, f"PLUME.turbulence >= 0 (got {turbulence})")
    check(lifetime > 0.0, f"PLUME.lifetime > 0 (got {lifetime})")
    check(origin_y > 0.0, f"PLUME.origin above sea level (got {origin_y})")
    dist2 = (origin_x - center_x) ** 2 + (origin_z - center_z) ** 2
    check(
        dist2 <= radius * radius + 1e-6,
        f"PLUME.origin over the caldera (dist {dist2 ** 0.5:.3f} <= radius {radius:.3f})",
    )
    check(
        (effusion_state == 1 and rate > 0.0) or (effusion_state == 0 and rate == 0.0),
        f"effusion_state {effusion_state} maps to rate {rate} (0 ⇒ idle emitter)",
    )

    print("\n[4] buffer guard + terrain suppression")
    check(
        lib.scr_sim_snapshot_write(buf16, 16) == SCR_ERR_BUF_SMALL,
        "cap < size returns SCR_ERR_BUF_SMALL (-3)",
    )
    ticks2 = lib.scr_sim_step(FIXED_DT, ctypes.byref(inp))
    check(ticks2 == 1, f"second step runs one tick (got {ticks2})")
    size2 = lib.scr_sim_snapshot_size()
    check(size2 < size, f"TERRAIN suppressed on second snapshot ({size2} < {size})")
    buf2 = (ctypes.c_uint8 * size2)()
    check(
        lib.scr_sim_snapshot_write(buf2, size2) == size2,
        "second snapshot writes in full",
    )
    snap2 = bytes(buf2)
    ids2 = []
    off2 = 48
    for _ in range(_st.unpack_from("<I", snap2, 8)[0]):
        sid2, slen2 = _st.unpack_from("<II", snap2, off2)
        ids2.append(sid2)
        off2 += 8 + slen2
    check(
        ids2 == [1, 2, 4, 5, 6, 7, 8, 9, 11],
        f"TERRAIN/FLORA suppressed, VOLCANO/PLUME/SHORE_FOAM/FAUNA every "
        f"snapshot (got {ids2})",
    )

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
