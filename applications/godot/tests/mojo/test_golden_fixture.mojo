# Spec test — Golden fixture (deterministic byte stream across code changes).
# Fixture: tests/fixtures/snapshot_seed1_tick1.bin
#   seed 1 → one step dt = 1/60 → scripted input → all eight sections
#   (schema 2: 1..6 unchanged, + 7 VOLCANO, + 8 PLUME — 0003 §3.5).
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
    ENVELOPE_BYTES,
    get_u32,
)
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
    _check(SCHEMA_VERSION == 3, "sim parameters SCHEMA_VERSION == 3")
    _check(get_u32(fixture, 4) == 3, "schema v3")
    _check(get_u32(fixture, 8) == 8, "eight sections (first snapshot)")
    _check(get_u32(fixture, 20) == 1, "simulation_tick = 1")
    _check(get_u32(fixture, 28) == 1, "seed = 1")
    var env = decode_envelope(fixture)
    var secs = decode_sections(fixture, env)
    _check(find_section(secs, SEC_TERRAIN) >= 0, "first snapshot carries TERRAIN")
    _check(find_section(secs, SEC_VOLCANO) >= 0, "fixture carries VOLCANO (7)")
    _check(find_section(secs, SEC_PLUME) >= 0, "fixture carries PLUME (8)")
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
