# Spec test — Golden fixture (deterministic byte stream across code changes).
# Fixture: tests/fixtures/snapshot_seed1_tick1.bin
#   seed 1 → one step dt = 1/60 → scripted input → all fourteen sections
#   (schema 6, milestone_0007: 1..9 unchanged framing from schema 4,
#   + 10 FLORA + 11 FAUNA + 12 HOTBAR + 13 TARGET + 14 RIGID_BODIES;
#   TERRAIN vertex payload is the 4-byte blend tuple — same byte count).
# Scripted input must stay identical to gen_golden_fixture.mojo and
# tests/abi_smoke.py (all three document the same batch).
#
# A failure here means snapshot bytes changed: if the change is intentional,
# regenerate via gen_golden_fixture.mojo and review the diff.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified: `assert False` does not stop execution). Every check below uses
# `_check`, which raises Error ⇒ TestSuite reports FAIL and exits non-zero.

from std.collections import List
from std.testing import TestSuite

from sim.world import world_init, step_world
from sim.input import InputBatch
from sim.parameters import SCHEMA_VERSION
from snapshot.encode import encode_snapshot
from snapshot.decode import decode_envelope, decode_sections, find_section
from snapshot.types import (
    SEC_TERRAIN,
    SEC_VOLCANO,
    SEC_PLUME,
    SEC_SHORE_FOAM,
    SEC_FLORA,
    SEC_FAUNA,
    SEC_HOTBAR,
    SEC_TARGET,
    SEC_RIGID_BODIES,
    ENVELOPE_BYTES,
    SHORE_FOAM_HEADER_BYTES,
    FLORA_HEADER_BYTES,
    FLORA_RECORD_BYTES,
    FAUNA_HEADER_BYTES,
    FAUNA_RECORD_BYTES,
    HOTBAR_BYTES,
    TARGET_BYTES,
    RIGID_HEADER_BYTES,
    RIGID_RECORD_BYTES,
    get_u32,
)
from sim.parameters import FLORA_N_MAX, FLOCK_N_MAX
from util.files import find_repo_root, join_path, read_file_bytes

comptime FIXTURE_REL = "applications/godot/tests/fixtures/snapshot_seed1_tick1.bin"

comptime SEED: UInt32 = 1
comptime MOVE_X: Float32 = 0.5
comptime MOVE_Y: Float32 = 1.0
comptime LOOK_DX: Float32 = 0.25
comptime LOOK_DY: Float32 = -0.1
comptime JUMP: UInt8 = 1
comptime SPRINT: UInt8 = 0


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def scripted_input() -> InputBatch:
    var b = InputBatch()
    b.move_x = MOVE_X
    b.move_y = MOVE_Y
    b.look_dx = LOOK_DX
    b.look_dy = LOOK_DY
    b.jump = JUMP
    b.sprint = SPRINT
    return b


def regenerate() raises -> List[UInt8]:
    var world = world_init(SEED)
    var ran = step_world(world, 1.0 / 60.0, scripted_input())
    _check(ran == 1, "trajectory must be exactly one tick")
    return encode_snapshot(world, True)


def test_fixture_exists_and_is_well_formed() raises:
    var path = join_path(find_repo_root(), FIXTURE_REL)
    var fixture = read_file_bytes(path)
    _check(len(fixture) > ENVELOPE_BYTES, "fixture must contain envelope")
    _check(get_u32(fixture, 0) == 0x53524353, "magic SCRS")
    _check(SCHEMA_VERSION == 6, "sim parameters SCHEMA_VERSION == 6")
    _check(get_u32(fixture, 4) == 6, "schema v6")
    _check(get_u32(fixture, 8) == 14, "fourteen sections (first snapshot)")
    _check(get_u32(fixture, 20) == 1, "simulation_tick = 1")
    _check(get_u32(fixture, 28) == 1, "seed = 1")
    var env = decode_envelope(fixture)
    var secs = decode_sections(fixture, env)
    _check(find_section(secs, SEC_TERRAIN) >= 0, "first snapshot carries TERRAIN")
    _check(find_section(secs, SEC_VOLCANO) >= 0, "fixture carries VOLCANO (7)")
    _check(find_section(secs, SEC_PLUME) >= 0, "fixture carries PLUME (8)")
    var fi = find_section(secs, SEC_SHORE_FOAM)
    _check(fi >= 0, "fixture carries SHORE_FOAM (9)")
    _check(
        secs[fi].length == SHORE_FOAM_HEADER_BYTES + 4 * 64 * 64,
        "SHORE_FOAM = 12 + 4·64² bytes",
    )
    var fli = find_section(secs, SEC_FLORA)
    _check(fli >= 0, "fixture carries FLORA (10)")
    var flora_count = Int(get_u32(fixture, secs[fli].offset))
    _check(flora_count > 0 and flora_count <= FLORA_N_MAX, "FLORA count in cap")
    _check(
        secs[fli].length == FLORA_HEADER_BYTES + FLORA_RECORD_BYTES * flora_count,
        "FLORA = 4 + 24·count bytes",
    )
    var fai = find_section(secs, SEC_FAUNA)
    _check(fai >= 0, "fixture carries FAUNA (11)")
    var fauna_count = Int(get_u32(fixture, secs[fai].offset))
    _check(fauna_count > 0 and fauna_count <= FLOCK_N_MAX, "FAUNA count in cap")
    _check(
        secs[fai].length == FAUNA_HEADER_BYTES + FAUNA_RECORD_BYTES * fauna_count,
        "FAUNA = 4 + 20·count bytes",
    )
    var hi = find_section(secs, SEC_HOTBAR)
    _check(hi >= 0, "fixture carries HOTBAR (12)")
    _check(secs[hi].length == HOTBAR_BYTES, "HOTBAR = 44 bytes")
    _check(get_u32(fixture, secs[hi].offset) == 9, "HOTBAR count = 9")
    var tgti = find_section(secs, SEC_TARGET)
    _check(tgti >= 0, "fixture carries TARGET (13)")
    _check(secs[tgti].length == TARGET_BYTES, "TARGET = 32 bytes")
    var rgi = find_section(secs, SEC_RIGID_BODIES)
    _check(rgi >= 0, "fixture carries RIGID_BODIES (14)")
    var rigid_count = Int(get_u32(fixture, secs[rgi].offset))
    _check(rigid_count > 0, "RIGID_BODIES count > 0")
    _check(
        secs[rgi].length == RIGID_HEADER_BYTES + RIGID_RECORD_BYTES * rigid_count,
        "RIGID_BODIES = 4 + 36·count bytes",
    )
    _check(
        Int(env.payload_bytes) == len(fixture) - ENVELOPE_BYTES,
        "payload_bytes == len - 48",
    )


def test_regenerated_snapshot_matches_fixture() raises:
    var path = join_path(find_repo_root(), FIXTURE_REL)
    var fixture = read_file_bytes(path)
    var fresh = regenerate()
    _check(
        len(fresh) == len(fixture),
        "size drift: fixture "
        + String(len(fixture))
        + " vs fresh "
        + String(len(fresh)),
    )
    for i in range(len(fixture)):
        _check(fresh[i] == fixture[i], "byte drift at offset " + String(i))


def test_regeneration_is_idempotent() raises:
    var a = regenerate()
    var b = regenerate()
    _check(len(a) == len(b), "generator size must be stable")
    for i in range(len(a)):
        _check(a[i] == b[i], "generator nondeterministic at " + String(i))


def main() raises:
    TestSuite.discover_tests[
        (
            test_fixture_exists_and_is_well_formed,
            test_regenerated_snapshot_matches_fixture,
            test_regeneration_is_idempotent,
        )
    ]().run()
