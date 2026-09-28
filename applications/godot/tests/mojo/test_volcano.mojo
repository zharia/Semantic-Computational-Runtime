# Spec test — VolcanoSubject (milestone_0003 Sprint 01): seeded effusion,
# VOLCANO/PLUME byte determinism, glow/night-factor semantics (§7 exit
# criteria "glow semantics test"), value ranges, and plume origin geometry.
# Headless: runs without Godot.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified: `assert False` does not stop execution). Every check below uses
# `_check`, which raises Error ⇒ TestSuite reports FAIL and exits non-zero.

from std.collections import List
from std.testing import TestSuite
from std.math import sqrt

from sim.world import world_init, step_world
from sim.input import InputBatch
from sim.subjects import AtmosphereSubject, atmosphere_from_time, night_factor
from sim.volcano import VolcanoSubject, effusion_draw, volcano_tick
from sim.parameters import (
    EFFUSION_TICK_STEP,
    LAVA_CRUST_DORMANT,
    LAVA_CRUST_EFFUSING,
    PLUME_RATE_DORMANT,
    PLUME_RATE_EFFUSING,
    PLUME_VELOCITY,
    PLUME_SPREAD,
    PLUME_TURBULENCE,
    PLUME_LIFETIME,
    GLOW_NIGHT_MAX_FACTOR,
    SEA_LEVEL,
    ISLAND_RADIUS,
)
from snapshot.encode import encode_snapshot
from snapshot.decode import (
    decode_envelope,
    decode_sections,
    find_section,
    read_volcano,
    read_plume,
)
from snapshot.types import SEC_VOLCANO, SEC_PLUME

# Byte-identity horizon: 1800 ticks = 6 effusion draws (0, 300, …, 1500),
# covering both dormant and effusing states for seed 1 (draw 5 turns on).
comptime SEQ_TICKS: Int = 1800


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _sequence(seed: UInt32, ticks: Int) raises -> List[List[UInt8]]:
    """Run `ticks` fixed ticks (idle input) from a fresh world; snapshot after
    each tick WITHOUT the TERRAIN section (VOLCANO/PLUME framing is what we
    compare). O(ticks) — one world stepped forward, not restarted."""
    var world = world_init(seed)
    var out = List[List[UInt8]]()
    for _ in range(ticks):
        _ = step_world(world, 1.0 / 60.0, InputBatch())
        out.append(encode_snapshot(world, False))
    return out^


def _section_bytes(data: List[UInt8], sid: UInt32) raises -> List[UInt8]:
    var env = decode_envelope(data)
    var secs = decode_sections(data, env)
    var i = find_section(secs, sid)
    _check(i >= 0, "missing section " + String(sid))
    var out = List[UInt8]()
    for k in range(secs[i].length):
        out.append(data[secs[i].offset + k])
    return out^


def _bytes_equal(a: List[UInt8], b: List[UInt8]) -> Bool:
    if len(a) != len(b):
        return False
    for i in range(len(a)):
        if a[i] != b[i]:
            return False
    return True


def _volcano_plume_bytes(snapshot: List[UInt8]) raises -> List[UInt8]:
    """VOLCANO payload ‖ PLUME payload as the adapter would read them."""
    var v = _section_bytes(snapshot, SEC_VOLCANO)
    var p = _section_bytes(snapshot, SEC_PLUME)
    var out = List[UInt8]()
    for i in range(len(v)):
        out.append(v[i])
    for i in range(len(p)):
        out.append(p[i])
    return out^


def _seed1_draws() -> List[UInt8]:
    """GOLDEN effusion sequence for seed 1, draw indices 0..19
    (draw i is taken at tick i·EFFUSION_TICK_STEP; record regenerated with
    effusion_draw(1, i) — integer splitmix64, machine-independent):
       i:   0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19
       st:  0 0 0 0 0 1 1 0 0 0  0  1  1  0  1  1  0  0  0  1"""
    var s = List[UInt8]()
    var pattern = List[UInt8]()
    pattern.append(0)
    pattern.append(0)
    pattern.append(0)
    pattern.append(0)
    pattern.append(0)
    pattern.append(1)
    pattern.append(1)
    pattern.append(0)
    pattern.append(0)
    pattern.append(0)
    pattern.append(0)
    pattern.append(1)
    pattern.append(1)
    pattern.append(0)
    pattern.append(1)
    pattern.append(1)
    pattern.append(0)
    pattern.append(0)
    pattern.append(0)
    pattern.append(1)
    for i in range(len(pattern)):
        s.append(pattern[i])
    return s^


def test_subject_determinism_same_seed_bytes_identical() raises:
    """(a) Two runs, same seed, SEQ_TICKS ticks → identical VOLCANO/PLUME
    payload bytes at every tick (including sections 7/8 framing)."""
    var a = _sequence(1, SEQ_TICKS)
    var b = _sequence(1, SEQ_TICKS)
    _check(len(a) == SEQ_TICKS and len(b) == SEQ_TICKS, "sequence lengths")
    var compared_v = 0
    var compared_p = 0
    for t in range(SEQ_TICKS):
        _check(
            _bytes_equal(a[t], b[t]),
            "snapshot bytes differ at tick " + String(t + 1),
        )
        # Explicit section-level identity for 7 VOLCANO / 8 PLUME.
        var va = _volcano_plume_bytes(a[t])
        var vb = _volcano_plume_bytes(b[t])
        _check(_bytes_equal(va, vb), "VOLCANO/PLUME differ at tick " + String(t + 1))
        _check(len(va) == 64, "VOLCANO(32) ‖ PLUME(32) = 64 bytes")
        compared_v += 32
        compared_p += 32
    _check(compared_v == SEQ_TICKS * 32, "compared VOLCANO bytes every tick")
    _check(compared_p == SEQ_TICKS * 32, "compared PLUME bytes every tick")
    # The sequence must actually be exercised across an effusion transition:
    # draw 5 at tick 1500 flips seed 1 from dormant to effusing. Sequence is
    # 0-indexed by capture, so a[i] is the snapshot AFTER tick i+1 — the flip
    # lands between a[1498] (tick 1499, dormant) and a[1499] (tick 1500).
    var vp_prev = _volcano_plume_bytes(a[1498])
    var vp_next = _volcano_plume_bytes(a[1499])
    _check(
        not _bytes_equal(vp_prev, vp_next),
        "effusion transition not visible in VOLCANO/PLUME bytes",
    )


def test_different_seed_differs_eventually() raises:
    """(a) Different seed ⇒ different effusion sequence eventually
    (seed 2 draw 0 is effusing while seed 1 draw 0 is dormant)."""
    var found = False
    for i in range(20):
        if effusion_draw(1, UInt32(i)) != effusion_draw(2, UInt32(i)):
            found = True
            break
    _check(found, "seed must change the effusion draw sequence eventually")
    # Snapshot level: VOLCANO/PLUME payloads differ somewhere within horizon.
    var a = _sequence(1, SEQ_TICKS)
    var b = _sequence(2, SEQ_TICKS)
    found = False
    for t in range(SEQ_TICKS):
        if not _bytes_equal(_volcano_plume_bytes(a[t]), _volcano_plume_bytes(b[t])):
            found = True
            break
    _check(found, "seed must change the VOLCANO/PLUME bytes eventually")


def test_effusion_golden_seed1() raises:
    """(b) Golden effusion schedule for seed 1: one draw per
    EFFUSION_TICK_STEP ticks; draw index = tick // EFFUSION_TICK_STEP."""
    var golden = _seed1_draws()
    for i in range(len(golden)):
        _check(
            effusion_draw(1, UInt32(i)) == golden[i],
            "seed 1 draw " + String(i) + " expected " + String(golden[i]),
        )
    # Subject-level: state observed by the world at the documented schedule.
    var world = world_init(1)
    _check(world.volcano.effusion_state == golden[0], "tick 0 = draw 0")
    # Walk the documented transition ticks: dormant through draw 4,
    # effusing at draws 5..6, dormant again at draw 7.
    var transitions = List[Int]()
    transitions.append(1500)  # draw 5 → 1
    transitions.append(1800)  # draw 6 → 1 (held)
    transitions.append(2100)  # draw 7 → 0
    for k in range(len(transitions)):
        var target = transitions[k]
        while world.simulation_tick < UInt32(target):
            _ = step_world(world, 1.0 / 60.0, InputBatch())
        var draw = world.simulation_tick // UInt32(EFFUSION_TICK_STEP)
        _check(
            world.simulation_tick % UInt32(EFFUSION_TICK_STEP) == 0,
            "schedule: transitions land on multiples of EFFUSION_TICK_STEP",
        )
        _check(
            world.volcano.effusion_state == golden[Int(draw)],
            "state at tick " + String(world.simulation_tick),
        )
    # Between draws the state is held (pure recompute from draw index).
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    _check(world.volcano.effusion_state == golden[7], "state held between draws")


def test_glow_semantics_sun_up_zero_night_positive() raises:
    """(c) glow_intensity == 0 with the sun above the horizon, > 0 below
    (locked decision §1.1 / exit criterion §7)."""
    # Day: world starts at 12:00 — sun above horizon, glow must be exactly 0.
    var world = world_init(1)
    _check(world.atmosphere.sun_elevation > 0.0, "noon sun above horizon")
    _check(world.volcano.glow_intensity == 0.0, "day glow must be exactly 0")
    var snap = encode_snapshot(world, False)
    var env = decode_envelope(snap)
    var secs = decode_sections(snap, env)
    var volc = read_volcano(snap, secs[find_section(secs, SEC_VOLCANO)])
    _check(volc.glow_intensity == 0.0, "VOLCANO.glow_intensity == 0 by day")

    # Night: feed the subject an atmosphere state with the sun below the
    # horizon (pure derivation of sim time → sky state, no wall clock).
    var night = atmosphere_from_time(700.0)  # 12:00 + 7 h = 19:00
    _check(night.sun_elevation < 0.0, "19:00 sun below horizon")
    volcano_tick(world.volcano, world.seed, world.simulation_tick, night)
    _check(world.volcano.glow_intensity > 0.0, "night glow must be positive")
    _check(
        world.volcano.glow_intensity
        == world.volcano.emissive_intensity * night_factor(night.sun_elevation),
        "glow = emissive × night_factor (§3.3)",
    )
    _check(
        world.volcano.glow_intensity <= world.volcano.emissive_intensity,
        "night factor capped at 1",
    )

    # Feeding a day state back must zero it again (pure function of input).
    var day = atmosphere_from_time(0.0)
    volcano_tick(world.volcano, world.seed, world.simulation_tick, day)
    _check(world.volcano.glow_intensity == 0.0, "day state ⇒ glow 0 again")


def test_night_factor_pure_function() raises:
    """Night factor: 0 at/above horizon, > 0 below, monotone, capped."""
    _check(night_factor(1.2) == 0.0, "sun high ⇒ 0")
    _check(night_factor(0.0) == 0.0, "on the horizon ⇒ 0")
    _check(night_factor(-1e-6) > 0.0, "just below horizon ⇒ > 0")
    var a = night_factor(-0.2)
    var b = night_factor(-0.6)
    _check(b > a, "deeper night ⇒ larger factor")
    _check(b <= GLOW_NIGHT_MAX_FACTOR, "capped")
    _check(night_factor(-100.0) == GLOW_NIGHT_MAX_FACTOR, "saturation")


def test_ranges_over_sequence() raises:
    """(d) Ranges over SEQ_TICKS: rate ≥ 0, lifetime > 0, crust ∈ [0,1],
    emissive > 0, radius > 0."""
    var world = world_init(1)
    var saw_effusing = False
    for t in range(SEQ_TICKS):
        _ = step_world(world, 1.0 / 60.0, InputBatch())
        if t % 100 != 0:
            continue
        var v = world.volcano
        _check(v.plume_rate >= 0.0, "rate ≥ 0 at tick " + String(t))
        _check(v.plume_lifetime > 0.0, "lifetime > 0")
        _check(
            v.crust_fraction >= 0.0 and v.crust_fraction <= 1.0,
            "crust ∈ [0,1]",
        )
        _check(v.emissive_intensity > 0.0, "emissive > 0")
        _check(v.radius > 0.0, "radius > 0")
        _check(v.effusion_state <= 1, "effusion_state ∈ {0,1}")
        _check(v.glow_intensity >= 0.0, "glow ≥ 0")
        if v.effusion_state == 1:
            saw_effusing = True
            _check(v.plume_rate == PLUME_RATE_EFFUSING, "rate while effusing")
            _check(v.crust_fraction == LAVA_CRUST_EFFUSING, "crust while effusing")
        else:
            _check(v.plume_rate == PLUME_RATE_DORMANT, "dormant ⇒ rate 0")
            _check(v.crust_fraction == LAVA_CRUST_DORMANT, "dormant crust")
        _check(v.plume_initial_velocity == PLUME_VELOCITY, "w0 constant")
        _check(v.plume_spread == PLUME_SPREAD, "spread constant")
        _check(v.plume_turbulence == PLUME_TURBULENCE, "turbulence constant")
        _check(v.plume_lifetime == PLUME_LIFETIME, "lifetime constant")
    _check(saw_effusing, "seed 1 must reach an effusing state by tick 1800")


def test_plume_origin_over_caldera() raises:
    """(e) Plume origin: world-frame position over the caldera — within the
    lake radius of the island center and above sea level."""
    var world = world_init(1)
    var v = world.volcano
    var dx = v.plume_origin_x - 0.0
    var dz = v.plume_origin_z - 0.0
    var dist = sqrt(dx * dx + dz * dz)
    _check(v.radius > 0.0, "lake radius > 0")
    _check(dist <= v.radius, "origin within lake radius of island center")
    _check(v.radius < ISLAND_RADIUS, "lake inside the island")
    _check(v.plume_origin_y > SEA_LEVEL, "origin above sea level")
    _check(
        v.plume_origin_x == v.center_x and v.plume_origin_z == v.center_z,
        "origin is the caldera center",
    )
    # VOLCANO section carries the same geometry the PLUME origin sits on.
    var snap = encode_snapshot(world, False)
    var env = decode_envelope(snap)
    var secs = decode_sections(snap, env)
    var volc = read_volcano(snap, secs[find_section(secs, SEC_VOLCANO)])
    _check(volc.radius > 0.0, "section radius > 0")
    _check(volc.lake_level > Float32(SEA_LEVEL), "lake above sea level")
    var plume = read_plume(snap, secs[find_section(secs, SEC_PLUME)])
    _check(plume.rate >= 0.0, "section rate ≥ 0")
    _check(plume.lifetime > 0.0, "section lifetime > 0")


def main() raises:
    TestSuite.discover_tests[
        (
            test_subject_determinism_same_seed_bytes_identical,
            test_different_seed_differs_eventually,
            test_effusion_golden_seed1,
            test_glow_semantics_sun_up_zero_night_positive,
            test_night_factor_pure_function,
            test_ranges_over_sequence,
            test_plume_origin_over_caldera,
        )
    ]().run()
