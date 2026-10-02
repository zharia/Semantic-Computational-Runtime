# Spec test — Determinism invariant (milestone_0002 §6.8, 104_contract §3):
# same seed + same input sequence ⇒ byte-identical snapshot sequence.
# Milestone_0003 §7 amendment: byte identity MUST cover sections 7 VOLCANO
# and 8 PLUME. Milestone_0005: byte identity MUST also cover section 9
# SHORE_FOAM (schema 4, section_count == 9 with TERRAIN).
# Milestone_0007: byte identity MUST also cover sections 12 HOTBAR /
# 13 TARGET / 14 RIGID_BODIES (schema 6), and a scripted edit sequence
# (select + DIG/PLACE each tick) must be byte-identical between equal runs.
# Headless: runs without Godot.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified: `assert False` does not stop execution). Every check below uses
# `_check`, which raises Error ⇒ TestSuite reports FAIL and exits non-zero.

from std.collections import List
from std.testing import TestSuite

from sim.world import world_init, step_world, world_fingerprint
from sim.input import InputBatch
from sim.parameters import (
    SCHEMA_VERSION,
    FLOCK_N_MAX,
    EDIT_OP_DIG,
    EDIT_OP_PLACE,
    HOTBAR_SLOT_COUNT,
)
from sim.edit import edit_apply_batch
from snapshot.encode import encode_snapshot
from snapshot.decode import (
    decode_envelope,
    decode_sections,
    find_section,
    read_flora,
    read_fauna,
)
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
    VOLCANO_BYTES,
    PLUME_BYTES,
    SHORE_FOAM_HEADER_BYTES,
    FLORA_HEADER_BYTES,
    FAUNA_HEADER_BYTES,
    HOTBAR_BYTES,
    TARGET_BYTES,
    RIGID_HEADER_BYTES,
    RIGID_RECORD_BYTES,
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


def run_sequence_with_edits(seed: UInt32, input: InputBatch) raises -> List[List[UInt8]]:
    """Like run_sequence, but before every tick the scripted edit batch is
    submitted (cycling hotbar selection; DIG early, PLACE at the last tick).
    Determinism must survive the edit pipeline's column recompute."""
    var world = world_init(seed)
    var out = List[List[UInt8]]()
    for i in range(SEQ_TICKS):
        var select = UInt8(i % HOTBAR_SLOT_COUNT + 1)
        var op = EDIT_OP_DIG
        if i == SEQ_TICKS - 1:
            op = EDIT_OP_PLACE
        _check(
            edit_apply_batch(world.edit_queue, world.hotbar, op, select),
            "scripted batch accepted at tick " + String(i),
        )
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
    """Byte identity covers sections 7/8, 9 SHORE_FOAM, 10 FLORA / 11 FAUNA
    and (schema 6) 12 HOTBAR / 13 TARGET / 14 RIGID_BODIES."""
    var a = run_sequence(1, scripted_input())
    var b = run_sequence(1, scripted_input())
    var snap = a[SEQ_TICKS - 1].copy()
    # Envelope: schema 6, fourteen sections (1..14 with TERRAIN + FLORA).
    _check(SCHEMA_VERSION == 6, "sim parameters SCHEMA_VERSION == 6")
    _check(
        Int(get_u32(snap, 4)) == Int(SCHEMA_VERSION),
        "envelope schema_version == 6",
    )
    var env = decode_envelope(snap)
    _check(Int(env.section_count) == 14, "section_count == 14 (schema 6)")
    # VOLCANO / PLUME / SHORE_FOAM / FLORA / FAUNA / HOTBAR / TARGET /
    # RIGID_BODIES framing.
    var secs = decode_sections(snap, env)
    var vi = find_section(secs, SEC_VOLCANO)
    var pi = find_section(secs, SEC_PLUME)
    var fi = find_section(secs, SEC_SHORE_FOAM)
    var fli = find_section(secs, SEC_FLORA)
    var fai = find_section(secs, SEC_FAUNA)
    var hi = find_section(secs, SEC_HOTBAR)
    var tgti = find_section(secs, SEC_TARGET)
    var rgi = find_section(secs, SEC_RIGID_BODIES)
    _check(vi >= 0, "section 7 VOLCANO present")
    _check(pi >= 0, "section 8 PLUME present")
    _check(fi >= 0, "section 9 SHORE_FOAM present")
    _check(fli >= 0, "section 10 FLORA present")
    _check(fai >= 0, "section 11 FAUNA present")
    _check(hi >= 0, "section 12 HOTBAR present")
    _check(tgti >= 0, "section 13 TARGET present")
    _check(rgi >= 0, "section 14 RIGID_BODIES present")
    _check(secs[hi].length == HOTBAR_BYTES, "HOTBAR is 44 bytes")
    _check(secs[tgti].length == TARGET_BYTES, "TARGET is 32 bytes")
    _check(
        secs[rgi].length >= RIGID_HEADER_BYTES + RIGID_RECORD_BYTES,
        "RIGID_BODIES framing ≥ header + one record",
    )
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
    # FLORA / FAUNA byte identity across equal runs (0006 §6 exit criterion).
    var fla = section_payload(a[SEQ_TICKS - 1], SEC_FLORA)
    var flb = section_payload(b[SEQ_TICKS - 1], SEC_FLORA)
    var fna = section_payload(a[SEQ_TICKS - 1], SEC_FAUNA)
    var fnb = section_payload(b[SEQ_TICKS - 1], SEC_FAUNA)
    _check(bytes_equal(fla, flb), "FLORA payload differs between equal runs")
    _check(bytes_equal(fna, fnb), "FAUNA payload differs between equal runs")
    # The flock advances: consecutive FAUNA payloads differ.
    var fna0 = section_payload(a[0], SEC_FAUNA)
    _check(
        not bytes_equal(fna0, fna), "FAUNA payload must advance with the flock"
    )
    # HOTBAR / TARGET / RIGID_BODIES byte identity (0007 §6 exit criterion).
    var ha = section_payload(a[SEQ_TICKS - 1], SEC_HOTBAR)
    var hb = section_payload(b[SEQ_TICKS - 1], SEC_HOTBAR)
    var tga = section_payload(a[SEQ_TICKS - 1], SEC_TARGET)
    var tgb = section_payload(b[SEQ_TICKS - 1], SEC_TARGET)
    var ra = section_payload(a[SEQ_TICKS - 1], SEC_RIGID_BODIES)
    var rb = section_payload(b[SEQ_TICKS - 1], SEC_RIGID_BODIES)
    _check(bytes_equal(ha, hb), "HOTBAR payload differs between equal runs")
    _check(bytes_equal(tga, tgb), "TARGET payload differs between equal runs")
    _check(bytes_equal(ra, rb), "RIGID_BODIES payload differs between equal runs")
    _check(len(ha) == HOTBAR_BYTES, "HOTBAR payload size 44")
    _check(len(tga) == TARGET_BYTES, "TARGET payload size 32")


def test_scripted_edits_are_byte_deterministic() raises:
    """Same seed + same scripted edit batches ⇒ byte-identical snapshot
    sequences (edit pipeline included: column recompute, blends, chunks)."""
    var a = run_sequence_with_edits(1, scripted_input())
    var b = run_sequence_with_edits(1, scripted_input())
    _check(len(a) == SEQ_TICKS and len(b) == SEQ_TICKS, "sequence length")
    for i in range(SEQ_TICKS):
        _check(
            bytes_equal(a[i], b[i]),
            "edit-run snapshot " + String(i) + " differs",
        )
    # The edit script must be distinguishable from the idle script: at least
    # one snapshot differs (selection/queue state changes every tick).
    var idle = run_sequence(1, scripted_input())
    _check(
        not bytes_equal(a[0], idle[0]),
        "edit script changes tick-0 snapshot (hotbar selection + queue)",
    )


def test_flora_species_diversity_seed1() raises:
    """Seed 1's FLORA payload carries ≥ 2 distinct species ids
    (0006 §7 exit criterion: distinct species rendered for seed 1)."""
    var world = world_init(1)
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    var data = encode_snapshot(world, True)
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var fli = find_section(secs, SEC_FLORA)
    _check(fli >= 0, "FLORA present")
    var flora = read_flora(data, secs[fli])
    _check(len(flora) > 0, "flora instances emitted for seed 1")
    var seen_palm = False
    var seen_slope = False
    for i in range(len(flora)):
        var sid = Int(flora[i].species_id)
        if sid == 1 or sid == 2:
            seen_palm = True
        elif sid == 4 or sid == 5 or sid == 6 or sid == 7:
            seen_slope = True
    _check(seen_palm, "palm species present for seed 1 (BEACH band)")
    _check(seen_slope, "slope species present for seed 1 (VOLCANIC_SLOPE band)")
    # Count distinct ids directly.
    var distinct = 0
    for sid in range(1, 8):
        var found = False
        for i in range(len(flora)):
            if Int(flora[i].species_id) == sid:
                found = True
        if found:
            distinct += 1
    _check(distinct >= 2, "≥ 2 distinct species for seed 1")


def test_flock_present_and_capped() raises:
    """FAUNA: count == FLOCK_N_INIT at init, always ≤ FLOCK_N_MAX, records
    are active slots in order (0006 §1.1 / AP-13)."""
    var world = world_init(1)
    var data = encode_snapshot(world, True)
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var fai = find_section(secs, SEC_FAUNA)
    _check(fai >= 0, "FAUNA present at init")
    var fauna = read_fauna(data, secs[fai])
    _check(len(fauna) == world.flock.count, "count matches subject")
    _check(world.flock.count <= FLOCK_N_MAX, "count ≤ FLOCK_N_MAX")
    for i in range(len(fauna)):
        _check(world.flock.birds[i].active, "slot order == wire order")
        _check(fauna[i].y > 0.0, "bird above sea level")


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


def test_growth_age_scale_sequence_byte_identical() raises:
    """0009 R8: same seed + same (empty) input sequence ⇒ identical
    (age, scale) sequences across runs — growth is pure-hash + tick driven,
    no mutable RNG stream (AP-20). Also: FLORA wire bytes stay identical
    between the two runs at every sampled tick, and growth actually moves
    both age and (eventually) scale."""
    var w1 = world_init(1)
    var w2 = world_init(1)
    _check(w1.flora.count == w2.flora.count, "same population at init")
    _check(w1.flora.count > 0, "seed 1 population non-empty")
    var saw_scale_move = False
    var init_scales = List[Float64]()
    for i in range(w1.flora.count):
        init_scales.append(Float64(w1.flora.instances[i].scale))
    for k in range(420):
        _ = step_world(w1, 1.0 / 60.0, InputBatch())
        _ = step_world(w2, 1.0 / 60.0, InputBatch())
        _check(
            w1.flora.count == w2.flora.count,
            "identical population count through growth",
        )
        for i in range(w1.flora.count):
            _check(
                w1.flora.ages[i] == w2.flora.ages[i],
                "identical age sequence (R8) at tick " + String(k),
            )
            _check(
                w1.flora.instances[i].scale == w2.flora.instances[i].scale,
                "identical scale sequence (R8) at tick " + String(k),
            )
            if Float64(w1.flora.instances[i].scale) != init_scales[i]:
                saw_scale_move = True
        # FLORA wire bytes identical between runs at this tick (terrain off —
        # we only need section 10 framing here).
        var d1 = encode_snapshot(w1, False, True)
        var d2 = encode_snapshot(w2, False, True)
        var e1 = decode_envelope(d1)
        var e2 = decode_envelope(d2)
        var s1 = decode_sections(d1, e1)
        var s2 = decode_sections(d2, e2)
        var f1 = find_section(s1, SEC_FLORA)
        var f2 = find_section(s2, SEC_FLORA)
        _check(f1 >= 0 and f2 >= 0, "FLORA present both runs")
        _check(s1[f1].length == s2[f2].length, "FLORA frame length equal")
        for b in range(s1[f1].length):
            _check(
                d1[s1[f1].offset + b] == d2[s2[f2].offset + b],
                "FLORA wire bytes identical (R8) at tick " + String(k),
            )
    _check(saw_scale_move, "growth moved at least one stored scale in 420 ticks")
    # Ages really advanced past their mixed initial values.
    var advanced = 0
    for i in range(w1.flora.count):
        if w1.flora.ages[i] > 0:
            advanced += 1
    _check(advanced == w1.flora.count, "every instance aged past 0")


def main() raises:
    TestSuite.discover_tests[
        (
            test_same_seed_same_sequence_is_byte_identical,
            test_different_seed_changes_snapshot,
            test_sequence_is_progressive_not_stuck,
            test_volcano_plume_sections_in_byte_identity,
            test_world_fingerprint_tracks_step,
            test_fixed_timestep_accumulator,
            test_flora_species_diversity_seed1,
            test_flock_present_and_capped,
            test_scripted_edits_are_byte_deterministic,
            test_growth_age_scale_sequence_byte_identical,
        )
    ]().run()
