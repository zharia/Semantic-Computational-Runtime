# Spec test — Shoreline foam (milestone_0005 §7 "Foam formula conformance"):
#   - the library formula of SCR-LIB-RENDER-WATER §3 evaluated VERBATIM at
#     committed (Δy, t) sample points with EXACT agreement (AP-19: sim/shore.mojo
#     is the single home of the formula),
#   - F ∈ [0,1]; F = 0 for Δy ≥ FOAM_DEPTH_M (1.8 m) and for land above the
#     max wave reach (§3.3 zone gates),
#   - grid alignment: cell (ix, iz) ↔ world (cell_center_x, cell_center_z),
#   - purity: the projection reads the foam field without mutating it, and the
#     world fingerprint folds foam state (a mutated field is detected).
# Headless: runs without Godot.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified: `assert False` does not stop execution). Every check below uses
# `_check`, which raises Error ⇒ TestSuite reports FAIL and exits non-zero.

from std.collections import List
from std.testing import TestSuite
from std.math import abs, sin

from sim.world import world_init, step_world, world_fingerprint
from sim.input import InputBatch
from sim.shore import (
    shore_foam,
    shore_foam_cell,
    compute_foam_field,
    foam_nonzero_count,
    FOAM_DEPTH_M,
    MAX_WAVE_REACH,
)
from sim.parameters import GRID_N, CELL_SIZE, SEA_LEVEL, WAVE_AMPLITUDE
from ocean.gerstner import wave_height, make_ocean
from synthesis.heightfield import cell_center_x, cell_center_z
from synthesis.noise import NoiseContext
from snapshot.encode import encode_snapshot
from snapshot.decode import decode_envelope, decode_sections, find_section, read_shore_foam
from snapshot.types import SEC_SHORE_FOAM, SHORE_FOAM_HEADER_BYTES

# Committed sample points (§7 exit criterion: evaluated at committed (Δy, t)
# sample points). dy in world units (m), t in seconds of simulation time.
comptime SAMPLE_COUNT: Int = 11
comptime TIME_COUNT: Int = 6


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _sample_dy(k: Int) -> Float64:
    """Committed Δy sample points: dry land, surf band, deep water, boundary."""
    if k == 0:
        return -0.75
    if k == 1:
        return -0.2
    if k == 2:
        return 0.0
    if k == 3:
        return 0.1
    if k == 4:
        return 0.35
    if k == 5:
        return 0.8
    if k == 6:
        return 1.25
    if k == 7:
        return 1.7999
    if k == 8:
        return 1.8  # FOAM_DEPTH_M: deep-water gate ⇒ 0
    if k == 9:
        return 2.5
    return 8.0


def _sample_t(k: Int) -> Float64:
    """Committed time sample points (simulation_time seconds)."""
    if k == 0:
        return 0.0
    if k == 1:
        return 1.0 / 60.0
    if k == 2:
        return 0.5
    if k == 3:
        return 3.7
    if k == 4:
        return 12.25
    return 60.0


def _library_formula(dy: Float64, t: Float64) -> Float64:
    """SCR-LIB-RENDER-WATER §3 written out exactly as the library states it:

        Foam_shore = clamp(1 − Δy/d_foam, 0, 1)² · (0.6 + 0.4·sin(6Δy − 4t))

    Independent of sim/shore.mojo — same operation order as the normative
    text (clamp first, then square, then multiply) so the comparison is an
    exact conformance check, not a tolerance match."""
    var c = 1.0 - dy / 1.8
    if c < 0.0:
        c = 0.0
    if c > 1.0:
        c = 1.0
    return c * c * (0.6 + 0.4 * sin(6.0 * dy - 4.0 * t))


def test_formula_conformance_exact_at_sample_points() raises:
    """§7: EXACT agreement with the library formula at committed (Δy, t)."""
    _check(FOAM_DEPTH_M == 1.8, "FOAM_DEPTH_M is the library value 1.8 m")
    for di in range(SAMPLE_COUNT):
        var dy = _sample_dy(di)
        for ti in range(TIME_COUNT):
            var t = _sample_t(ti)
            var expected = _library_formula(dy, t)
            var got = shore_foam(dy, t)
            # Bit-exact: sim/shore.mojo implements the same expression with
            # the same operation order (AP-19 — no re-derivation, no drift).
            _check(
                expected == got,
                "formula mismatch at Δy=" + String(dy) + " t=" + String(t)
                + ": library " + String(expected) + " vs sim " + String(got),
            )


def test_range_and_zone_gates() raises:
    """§3.3: F ∈ [0,1]; deep water (Δy ≥ 1.8) ⇒ 0; land above the max wave
    reach ⇒ 0 (the formula alone would light dry cells below the clamp)."""
    for di in range(SAMPLE_COUNT):
        var dy = _sample_dy(di)
        for ti in range(TIME_COUNT):
            var t = _sample_t(ti)
            var f = shore_foam(dy, t)
            _check(f >= 0.0 and f <= 1.0, "F out of [0,1] at Δy=" + String(dy))
    # Deep-water gate: every Δy ≥ FOAM_DEPTH_M is exactly 0.
    var deep = List[Float64]()
    deep.append(FOAM_DEPTH_M)
    deep.append(1.8001)
    deep.append(2.0)
    deep.append(9.5)
    for i in range(len(deep)):
        for ti in range(TIME_COUNT):
            var t = _sample_t(ti)
            _check(
                shore_foam(deep[i], t) == 0.0,
                "deep water Δy=" + String(deep[i]) + " must be 0",
            )
    # Land above the max wave reach ⇒ 0 even when Δy would be very negative.
    _check(
        shore_foam_cell(MAX_WAVE_REACH, MAX_WAVE_REACH - 5.0, 2.0) == 0.0,
        "cell at exactly MAX_WAVE_REACH is 0",
    )
    _check(
        shore_foam_cell(MAX_WAVE_REACH + 10.0, SEA_LEVEL, 2.0) == 0.0,
        "high dry land is 0",
    )
    # Zone gate is about the terrain cell, not about Δy: a cell slightly
    # below reach evaluates the library formula (surf wash band).
    var y_t = MAX_WAVE_REACH - 0.05
    var wash = shore_foam_cell(y_t, y_t - 0.4, 1.25)
    _check(
        wash == _library_formula(-0.4, 1.25),
        "wash-band cell equals the library formula",
    )
    # Land above reach never foams regardless of wave phase.
    _check(
        shore_foam_cell(MAX_WAVE_REACH + 1.0, y_t + 3.0, 1.25) == 0.0,
        "dry land stays 0 under any wave height",
    )


def test_field_shape_and_grid_alignment() raises:
    """§3.3: GRID_N² field at cell centers; recomputation from world state
    agrees cell-by-cell (row-major iz·GRID_N + ix)."""
    var world = world_init(1)
    _check(len(world.foam) == GRID_N * GRID_N, "foam field is GRID_N²")
    var nz = 0
    for i in range(GRID_N * GRID_N):
        var f = world.foam[i]
        _check(f >= 0.0 and f <= 1.0, "field value out of [0,1] at " + String(i))
        if f > 0.0:
            nz += 1
    _check(nz > 0, "shore foam exists on the seed-1 island")

    # Grid alignment: cell (ix, iz) samples the height field and the Gerstner
    # authority at that cell's center (same helpers the field used).
    for iz in range(0, GRID_N, 7):
        for ix in range(0, GRID_N, 9):
            var wx = cell_center_x(ix)
            var wz = cell_center_z(iz)
            var y_t = world.island.heights[iz * GRID_N + ix]
            var y_w = wave_height(world.hydro.ocean, wx, wz, world.simulation_time)
            var expected = Float32(shore_foam_cell(y_t, y_w, world.simulation_time))
            var got = world.foam[iz * GRID_N + ix]
            _check(
                abs(got - expected) < 1e-6,
                "cell (" + String(ix) + "," + String(iz) + ") misaligned: "
                + String(got) + " vs " + String(expected),
            )

    # Zone-gate evidence on real geometry: a deep cell is 0 and a high-land
    # cell is 0.
    var found_deep = False
    var found_land = False
    for iz in range(0, GRID_N, 3):
        for ix in range(0, GRID_N, 3):
            var i = iz * GRID_N + ix
            var y_t = world.island.heights[i]
            var y_w = wave_height(
                world.hydro.ocean, cell_center_x(ix), cell_center_z(iz),
                world.simulation_time,
            )
            if y_w - y_t >= FOAM_DEPTH_M:
                _check(world.foam[i] == 0.0, "deep cell must be 0")
                found_deep = True
            if y_t >= MAX_WAVE_REACH:
                _check(world.foam[i] == 0.0, "high-land cell must be 0")
                found_land = True
    _check(found_deep, "seed-1 has sampled deep-water cells")
    _check(found_land, "seed-1 has sampled high-land cells")


def test_field_evolves_with_wave_phase() raises:
    """Foam depends on t only via simulation_time: one committed tick changes
    the field (the surf band tracks the wave phase), still in [0,1]."""
    var world = world_init(1)
    var before = world.foam.copy()
    var t0 = world.simulation_time
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    _check(world.simulation_time > t0, "simulation_time advanced")
    var changed = False
    for i in range(len(before)):
        _check(
            world.foam[i] >= 0.0 and world.foam[i] <= 1.0,
            "post-tick value out of [0,1]",
        )
        if world.foam[i] != before[i]:
            changed = True
    _check(changed, "foam field must evolve with the wave phase")


def test_projection_reads_foam_without_mutating() raises:
    """Purity: encoding + adapter-style reads leave world.foam and the world
    fingerprint untouched (§3.3: projection reads, never mutates)."""
    var world = world_init(1)
    _ = step_world(world, 1.0 / 60.0, InputBatch())
    var snapshot = encode_snapshot(world, True)
    var before_fp = world_fingerprint(world)
    var before_foam = world.foam.copy()

    var env = decode_envelope(snapshot)
    var secs = decode_sections(snapshot, env)
    var fi = find_section(secs, SEC_SHORE_FOAM)
    _check(fi >= 0, "section 9 SHORE_FOAM present")
    var foam = read_shore_foam(snapshot, secs[fi])
    _check(
        Int(foam[0]) == GRID_N, "header grid_n matches the terrain grid",
    )
    _check(
        SHORE_FOAM_HEADER_BYTES + 4 * GRID_N * GRID_N == secs[fi].length,
        "section size = 12 + 4·GRID_N²",
    )
    for i in range(GRID_N * GRID_N):
        _check(
            abs(foam[3 + i] - before_foam[i]) < 1e-6,
            "decoded foam differs from world state at " + String(i),
        )
    _check(
        world_fingerprint(world) == before_fp,
        "projection mutated world state (foam fingerprint drift)",
    )
    # Repeat projection is byte-identical (foam included).
    var again = encode_snapshot(world, True)
    _check(len(again) == len(snapshot), "repeat projection size equal")
    for i in range(len(snapshot)):
        _check(again[i] == snapshot[i], "non-deterministic foam projection")

    # Fingerprint sensitivity: a perturbed foam field is detectable.
    var k = 0
    var saved = world.foam[k]
    world.foam[k] = 0.125 if saved != 0.125 else 0.25
    _check(
        world_fingerprint(world) != before_fp, "fingerprint misses foam state"
    )
    world.foam[k] = saved
    _check(world_fingerprint(world) == before_fp, "fingerprint not restored")


def test_field_is_pure_function_of_inputs() raises:
    """compute_foam_field(h, ocean, t) is deterministic and independent of
    call history: two draws on equal inputs agree cell-for-cell."""
    var ctx = NoiseContext(1)
    var h = List[Float64]()
    for i in range(GRID_N * GRID_N):
        h.append(Float64(i % 17) * 0.25 - 2.0)
    var ocean = make_ocean()
    var a = compute_foam_field(h, ocean, 1.5)
    var b = compute_foam_field(h, ocean, 1.5)
    _check(len(a) == GRID_N * GRID_N, "field size")
    for i in range(len(a)):
        _check(a[i] == b[i], "impure foam evaluation at " + String(i))
    # Nonzero helper agrees with the field.
    var nz_a = foam_nonzero_count(a)
    var nz_b = 0
    for i in range(len(a)):
        if a[i] > 0.0:
            nz_b += 1
    _check(nz_a == nz_b, "foam_nonzero_count agrees with the field")
    _ = ctx


def main() raises:
    TestSuite.discover_tests[
        (
            test_formula_conformance_exact_at_sample_points,
            test_range_and_zone_gates,
            test_field_shape_and_grid_alignment,
            test_field_evolves_with_wave_phase,
            test_projection_reads_foam_without_mutating,
            test_field_is_pure_function_of_inputs,
        )
    ]().run()
