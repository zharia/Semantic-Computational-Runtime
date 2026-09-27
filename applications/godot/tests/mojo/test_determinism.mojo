# Spec test — Determinism invariant (milestone_0002 §6.8, 104_contract §3):
# same seed + same input sequence ⇒ byte-identical snapshot sequence.
# Headless: runs without Godot.

from std.collections import List
from std.testing import TestSuite

from sim.world import world_init, step_world, world_fingerprint
from sim.input import InputBatch
from snapshot.encode import encode_snapshot

comptime SCRIPTED_MOVE_X: Float32 = 0.5
comptime SCRIPTED_MOVE_Y: Float32 = 1.0
comptime SCRIPTED_LOOK_DX: Float32 = 0.25
comptime SCRIPTED_LOOK_DY: Float32 = -0.1
comptime SCRIPTED_JUMP: UInt8 = 1
comptime SCRIPTED_SPRINT: UInt8 = 0
comptime SEQ_TICKS: Int = 5


def scripted_input() -> InputBatch:
    var b = InputBatch()
    b.move_x = SCRIPTED_MOVE_X
    b.move_y = SCRIPTED_MOVE_Y
    b.look_dx = SCRIPTED_LOOK_DX
    b.look_dy = SCRIPTED_LOOK_DY
    b.jump = SCRIPTED_JUMP
    b.sprint = SCRIPTED_SPRINT
    return b


def run_sequence(seed: UInt32, input: InputBatch) raises -> List[List[UInt8]]:
    """SEQ_TICKS steps of dt=1/60; snapshot after each step (include terrain
    on every capture here — callers compare full byte streams)."""
    var world = world_init(seed)
    var out = List[List[UInt8]]()
    for _ in range(SEQ_TICKS):
        var ran = step_world(world, 1.0 / 60.0, input)
        assert ran == 1, "dt=1/60 must run exactly one tick"
        out.append(encode_snapshot(world, True))
    return out^


def bytes_equal(a: List[UInt8], b: List[UInt8]) -> Bool:
    if len(a) != len(b):
        return False
    for i in range(len(a)):
        if a[i] != b[i]:
            return False
    return True


def test_same_seed_same_sequence_is_byte_identical() raises:
    var a = run_sequence(1, scripted_input())
    var b = run_sequence(1, scripted_input())
    assert len(a) == SEQ_TICKS and len(b) == SEQ_TICKS
    for i in range(SEQ_TICKS):
        assert bytes_equal(a[i], b[i]), "snapshot " + String(i) + " differs"


def test_different_seed_changes_snapshot() raises:
    var a = run_sequence(1, scripted_input())
    var b = run_sequence(2, scripted_input())
    assert not bytes_equal(a[0], b[0]), "seed must change the snapshot"
    assert not bytes_equal(a[SEQ_TICKS - 1], b[SEQ_TICKS - 1])


def test_sequence_is_progressive_not_stuck() raises:
    var a = run_sequence(1, scripted_input())
    # tick counter and state generation advance every snapshot.
    for i in range(1, SEQ_TICKS):
        assert not bytes_equal(a[i - 1], a[i]), "consecutive snapshots equal"
    # state_generation (u32 LE at envelope offset 16) counts committed ticks:
    # first snapshot is post-step, so it is already 1.
    assert a[0][16] == 1 and a[0][17] == 0
    assert a[SEQ_TICKS - 1][16] == UInt8(SEQ_TICKS)


def test_world_fingerprint_tracks_step() raises:
    var world = world_init(1)
    var fp0 = world_fingerprint(world)
    _ = step_world(world, 1.0 / 60.0, scripted_input())
    var fp1 = world_fingerprint(world)
    assert fp0 != fp1, "fingerprint must change after a tick"
    var world2 = world_init(1)
    _ = step_world(world2, 1.0 / 60.0, scripted_input())
    assert world_fingerprint(world2) == fp1, "fingerprint must be deterministic"


def test_fixed_timestep_accumulator() raises:
    var world = world_init(1)
    var idle = InputBatch()
    # Two half-ticks accumulate to one tick.
    assert step_world(world, 1.0 / 120.0, idle) == 0
    assert step_world(world, 1.0 / 120.0, idle) == 1
    # Zero dt runs nothing.
    assert step_world(world, 0.0, idle) == 0
    # Frame clamp: 10 s frame runs at most 0.05 s = 3 ticks.
    assert step_world(world, 10.0, idle) == 3


def main() raises:
    TestSuite.discover_tests[
        (
            test_same_seed_same_sequence_is_byte_identical,
            test_different_seed_changes_snapshot,
            test_sequence_is_progressive_not_stuck,
            test_world_fingerprint_tracks_step,
            test_fixed_timestep_accumulator,
        )
    ]().run()
