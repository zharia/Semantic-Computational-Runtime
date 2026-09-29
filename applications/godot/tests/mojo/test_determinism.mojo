# Spec test — Determinism invariant (milestone_0002 §6.8, 104_contract §3):
# same seed + same input sequence ⇒ byte-identical snapshot sequence.
# Milestone_0003 §7 amendment: byte identity MUST cover sections 7 VOLCANO
# and 8 PLUME. Milestone_0005: byte identity MUST also cover section 9
# SHORE_FOAM (schema 4, section_count == 9 with TERRAIN).
# Headless: runs without Godot.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified: `assert False` does not stop execution). Every check below uses
# `_check`, which raises Error ⇒ TestSuite reports FAIL and exits non-zero.

from std.collections import List
from std.testing import TestSuite

from sim.world import world_init, step_world, world_fingerprint
from sim.input import InputBatch
from sim.parameters import SCHEMA_VERSION
from snapshot.encode import encode_snapshot
from snapshot.decode import decode_envelope, decode_sections, find_section
from snapshot.types import (
    SEC_TERRAIN,
    SEC_VOLCANO,
    SEC_PLUME,
    SEC_SHORE_FOAM,
    VOLCANO_BYTES,
    PLUME_BYTES,
    SHORE_FOAM_HEADER_BYTES,
    get_u32,
)

comptime SCRIPTED_MOVE_X: Float32 = 0.5
comptime SCRIPTED_MOVE_Y: Float32 = 1.0
comptime SCRIPTED_LOOK_DX: Float32 = 0.25
comptime SCRIPTED_LOOK_DY: Float32 = -0.1
comptime SCRIPTED_JUMP: UInt8 = 1
comptime SCRIPTED_SPRINT: UInt8 = 0
comptime SEQ_TICKS: Int = 5


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


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
        _check(ran == 1, "dt=1/60 must run exactly one tick")
        out.append(encode_snapshot(world, True))
    return out^


def bytes_equal(a: List[UInt8], b: List[UInt8]) -> Bool:
    if len(a) != len(b):
        return False
    for i in range(len(a)):
        if a[i] != b[i]:
            return False
    return True


def section_payload(data: List[UInt8], sid: UInt32) raises -> List[UInt8]:
    """Raw payload bytes of one section (adapter-style read)."""
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var i = find_section(secs, sid)
    _check(i >= 0, "missing section " + String(sid))
    var out = List[UInt8]()
    for k in range(secs[i].length):
        out.append(data[secs[i].offset + k])
    return out^


def test_same_seed_same_sequence_is_byte_identical() raises:
    var a = run_sequence(1, scripted_input())
    var b = run_sequence(1, scripted_input())
    _check(len(a) == SEQ_TICKS and len(b) == SEQ_TICKS, "sequence length")
    for i in range(SEQ_TICKS):
        _check(bytes_equal(a[i], b[i]), "snapshot " + String(i) + " differs")


def test_different_seed_changes_snapshot() raises:
    var a = run_sequence(1, scripted_input())
    var b = run_sequence(2, scripted_input())
    _check(not bytes_equal(a[0], b[0]), "seed must change the snapshot")
    _check(
        not bytes_equal(a[SEQ_TICKS - 1], b[SEQ_TICKS - 1]),
        "seed must change the last snapshot",
    )


def test_sequence_is_progressive_not_stuck() raises:
    var a = run_sequence(1, scripted_input())
    # tick counter and state generation advance every snapshot.
    for i in range(1, SEQ_TICKS):
        _check(
            not bytes_equal(a[i - 1], a[i]),
            "consecutive snapshots equal",
        )
    # state_generation (u32 LE at envelope offset 16) counts committed ticks:
    # first snapshot is post-step, so it is already 1.
    _check(a[0][16] == 1 and a[0][17] == 0, "first snapshot state_generation == 1")
    _check(
        a[SEQ_TICKS - 1][16] == UInt8(SEQ_TICKS),
        "last snapshot state_generation == SEQ_TICKS",
    )


def test_volcano_plume_sections_in_byte_identity() raises:
    """Byte identity covers sections 7/8 and 9 SHORE_FOAM (schema 4)."""
    var a = run_sequence(1, scripted_input())
    var b = run_sequence(1, scripted_input())
    var snap = a[SEQ_TICKS - 1].copy()
    # Envelope: schema 4, nine sections (1..9 with TERRAIN).
    _check(SCHEMA_VERSION == 4, "sim parameters SCHEMA_VERSION == 4")
    _check(
        Int(get_u32(snap, 4)) == Int(SCHEMA_VERSION),
        "envelope schema_version == 4",
    )
    var env = decode_envelope(snap)
    _check(Int(env.section_count) == 9, "section_count == 9 (schema 4)")
    # VOLCANO / PLUME / SHORE_FOAM framing.
    var secs = decode_sections(snap, env)
    var vi = find_section(secs, SEC_VOLCANO)
    var pi = find_section(secs, SEC_PLUME)
    var fi = find_section(secs, SEC_SHORE_FOAM)
    _check(vi >= 0, "section 7 VOLCANO present")
    _check(pi >= 0, "section 8 PLUME present")
    _check(fi >= 0, "section 9 SHORE_FOAM present")
    _check(secs[vi].length == VOLCANO_BYTES, "VOLCANO is 32 bytes")
    _check(secs[pi].length == PLUME_BYTES, "PLUME is 32 bytes")
    _check(
        secs[fi].length == SHORE_FOAM_HEADER_BYTES + 4 * 64 * 64,
        "SHORE_FOAM is 12 + 4·64² bytes",
    )
    # Explicit payload-level byte identity across the two runs, including the
    # VOLCANO state that changes with the seeded effusion schedule.
    var va = section_payload(a[SEQ_TICKS - 1], SEC_VOLCANO)
    var vb = section_payload(b[SEQ_TICKS - 1], SEC_VOLCANO)
    var pa = section_payload(a[SEQ_TICKS - 1], SEC_PLUME)
    var pb = section_payload(b[SEQ_TICKS - 1], SEC_PLUME)
    var fa = section_payload(a[SEQ_TICKS - 1], SEC_SHORE_FOAM)
    var fb = section_payload(b[SEQ_TICKS - 1], SEC_SHORE_FOAM)
    _check(bytes_equal(va, vb), "VOLCANO payload differs between equal runs")
    _check(bytes_equal(pa, pb), "PLUME payload differs between equal runs")
    _check(bytes_equal(fa, fb), "SHORE_FOAM payload differs between equal runs")
    _check(len(va) == 32 and len(pa) == 32, "payload sizes 32/32")
    # TERRAIN (schema 4 vertex blend tuples): byte identity MUST cover the
    # per-vertex (u8 material, u8 partner, u8 weight, u8 pad) records — the
    # full payload compare below is strictly stronger than a tuple-only one.
    var ta = section_payload(a[0], SEC_TERRAIN)
    var tb = section_payload(b[0], SEC_TERRAIN)
    _check(
        bytes_equal(ta, tb),
        "TERRAIN payload (vertex blend tuples) byte-identical between runs",
    )
    _check(len(ta) == len(tb), "TERRAIN stride-neutral across runs")


def test_world_fingerprint_tracks_step() raises:
    var world = world_init(1)
    var fp0 = world_fingerprint(world)
    _ = step_world(world, 1.0 / 60.0, scripted_input())
    var fp1 = world_fingerprint(world)
    _check(fp0 != fp1, "fingerprint must change after a tick")
    var world2 = world_init(1)
    _ = step_world(world2, 1.0 / 60.0, scripted_input())
    _check(world_fingerprint(world2) == fp1, "fingerprint must be deterministic")


def test_fixed_timestep_accumulator() raises:
    var world = world_init(1)
    var idle = InputBatch()
    # Two half-ticks accumulate to one tick.
    _check(step_world(world, 1.0 / 120.0, idle) == 0, "first half-tick commits 0")
    _check(step_world(world, 1.0 / 120.0, idle) == 1, "second half-tick commits 1")
    # Zero dt runs nothing.
    _check(step_world(world, 0.0, idle) == 0, "zero dt runs nothing")
    # Frame clamp: 10 s frame runs at most 0.05 s = 3 ticks.
    _check(step_world(world, 10.0, idle) == 3, "frame clamp caps at 3 ticks")


def main() raises:
    TestSuite.discover_tests[
        (
            test_same_seed_same_sequence_is_byte_identical,
            test_different_seed_changes_snapshot,
            test_sequence_is_progressive_not_stuck,
            test_volcano_plume_sections_in_byte_identity,
            test_world_fingerprint_tracks_step,
            test_fixed_timestep_accumulator,
        )
    ]().run()
