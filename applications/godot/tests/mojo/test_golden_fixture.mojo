# Spec test — Golden fixture (deterministic byte stream across code changes).
# Fixture: tests/fixtures/snapshot_seed1_tick1.bin
#   seed 1 → one step dt = 1/60 → scripted input → all six sections.
# Scripted input must stay identical to gen_golden_fixture.mojo and
# tests/abi_smoke.py (all three document the same batch).
#
# A failure here means snapshot bytes changed: if the change is intentional,
# regenerate via gen_golden_fixture.mojo and review the diff.

from std.collections import List
from std.testing import TestSuite

from sim.world import world_init, step_world
from sim.input import InputBatch
from snapshot.encode import encode_snapshot
from snapshot.decode import decode_envelope, decode_sections, find_section
from snapshot.types import SEC_TERRAIN, ENVELOPE_BYTES, get_u32
from util.files import find_repo_root, join_path, read_file_bytes

comptime FIXTURE_REL = "applications/godot/tests/fixtures/snapshot_seed1_tick1.bin"

comptime SEED: UInt32 = 1
comptime MOVE_X: Float32 = 0.5
comptime MOVE_Y: Float32 = 1.0
comptime LOOK_DX: Float32 = 0.25
comptime LOOK_DY: Float32 = -0.1
comptime JUMP: UInt8 = 1
comptime SPRINT: UInt8 = 0


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
    assert ran == 1, "trajectory must be exactly one tick"
    return encode_snapshot(world, True)^


def test_fixture_exists_and_is_well_formed() raises:
    var path = join_path(find_repo_root(), FIXTURE_REL)
    var fixture = read_file_bytes(path)
    assert len(fixture) > ENVELOPE_BYTES, "fixture must contain envelope"
    assert get_u32(fixture, 0) == 0x53524353, "magic SCRS"
    assert get_u32(fixture, 4) == 1, "schema v1"
    assert get_u32(fixture, 8) == 6, "six sections (first snapshot)"
    assert get_u32(fixture, 20) == 1, "simulation_tick = 1"
    assert get_u32(fixture, 28) == 1, "seed = 1"
    var env = decode_envelope(fixture)
    var secs = decode_sections(fixture, env)
    assert find_section(secs, SEC_TERRAIN) >= 0, "first snapshot carries TERRAIN"
    assert Int(env.payload_bytes) == len(fixture) - ENVELOPE_BYTES


def test_regenerated_snapshot_matches_fixture() raises:
    var path = join_path(find_repo_root(), FIXTURE_REL)
    var fixture = read_file_bytes(path)
    var fresh = regenerate()
    assert len(fresh) == len(fixture), (
        "size drift: fixture " + String(len(fixture)) + " vs fresh " + String(len(fresh))
    )
    for i in range(len(fixture)):
        assert fresh[i] == fixture[i], "byte drift at offset " + String(i)


def test_regeneration_is_idempotent() raises:
    var a = regenerate()
    var b = regenerate()
    assert len(a) == len(b)
    for i in range(len(a)):
        assert a[i] == b[i], "generator nondeterministic at " + String(i)


def main() raises:
    TestSuite.discover_tests[
        (
            test_fixture_exists_and_is_well_formed,
            test_regenerated_snapshot_matches_fixture,
            test_regeneration_is_idempotent,
        )
    ]().run()
