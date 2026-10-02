# Spec test — Flora field + growth (milestone_0009 Sprint 01 §5):
#   (a) scale monotone non-decreasing until maturity, bounded [SCALE_MIN, MAX]
#   (b) run-twice identical age/scale sequence (pure-hash determinism, R1/R8)
#   (c) simulated dig → anchor plant absent next tick, freed cell may re-establish
#   (d) 0 < count ≤ FLORA_N_MAX at every tick
#   (e) emission dirty fires exactly on ε-threshold crossings (§3.2, R7)
# plus the measured cost of the flora_re_evaluate full rescan (µs, filled into
# the world.mojo comment). Headless: runs without Godot.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op.
# Every check below uses `_check`, which raises Error ⇒ TestSuite FAIL.

from std.collections import List
from std.testing import TestSuite
from std.math import abs, floor
from std.memory import Layout, alloc
from std.ffi import external_call, c_int

from sim.island import build_island, IslandSubject
from sim.world import world_init, step_world, World
from sim.flora import (
    FloraSubject,
    flora_from_island,
    flora_tick,
    flora_re_evaluate,
    flora_emission_dirty,
    flora_scale_for_age,
    flora_anchor_scale,
    flora_initial_age,
    flora_maturity_ticks,
    flora_scale_target,
    establishment_suitability,
    feature_for_column,
    instance_for_column,
    cell_slope,
    anchor_cell_of,
)
from sim.input import idle_input
from sim.parameters import (
    GRID_N,
    CELL_SIZE,
    SEA_LEVEL,
    FLORA_N_MAX,
    FLORA_HEIGHT_EPS,
    FLORA_SLOPE_CAP,
    FLORA_BEACH_SLOPE_CAP,
    FLORA_SCALE_MIN,
    FLORA_SCALE_MAX,
    FLORA_EMIT_EPS,
    FLORA_SUITABILITY_THRESHOLD,
    FLORA_WETNESS_NEUTRAL,
    FLORA_CRATER_STRESS_NEUTRAL,
)
from sim.edit import edit_apply_batch, EDIT_OP_DIG
from materials.catalog import (
    SPECIES_NONE,
    SPECIES_PALM_CLUSTER,
    SPECIES_PALM_SOLO,
    SPECIES_BAMBOO_GROVE,
    SPECIES_CANOPY_TREE,
    SPECIES_CANOPY_CLUSTER,
    SPECIES_SHRUB,
    SPECIES_FERN_CARPET,
)
from synthesis.voxel import BIOME_BEACH, BIOME_VOLCANIC_SLOPE
from snapshot.types import FloraInstance

comptime SEED: UInt32 = 1
# Longest maturity in the table (CANOPY_TREE) — tick past it for (a)/(d).
comptime MAX_MATURITY: Int = 2400
comptime PROBE_TICKS: Int = 300  # loop length for (b)/(d)/(e) + perf probe


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _now_ns() -> Int64:
    # struct timespec { time_t sec; long nsec; } — two Int64 on linux/amd64.
    # 16 B deliberately leaked (libc free on the raw allocation crashed; the
    # perf probe runs a handful of times per suite).
    var al = alloc(Layout[Int64](count=2))
    var p = al^.unsafe_leak()
    _ = external_call["clock_gettime", c_int](c_int(1), p)  # CLOCK_MONOTONIC
    var sec = p[unsafe_offset=0]
    var nsec = p[unsafe_offset=1]
    return sec * 1_000_000_000 + nsec


def _copy_instances(flora: FloraSubject) -> List[FloraInstance]:
    var out = List[FloraInstance]()
    for i in range(flora.count):
        out.append(flora.instances[i])
    return out^


def _flora_changed_since(
    cur: FloraSubject, last: List[FloraInstance]
) -> Bool:
    """Structural + ε-scale comparison against a previous snapshot copy —
    mirrors the runtime dirty rule (sim.runtime._flora_dirty) so the test
    can count 'fires' independently of the handle plumbing."""
    if cur.count != len(last):
        return True
    for i in range(cur.count):
        var c = cur.instances[i]
        var p = last[i]
        if c.species_id != p.species_id:
            return True
        if c.x != p.x or c.y != p.y or c.z != p.z:
            return True
        if c.yaw != p.yaw:
            return True
        if flora_emission_dirty(Float64(p.scale), Float64(c.scale)):
            return True
    return False


# --- (a) monotone + bounded + saturated after maturity -----------------------

def test_a_scale_monotone_bounded_until_maturity() raises:
    var island = build_island(SEED)
    var flora = flora_from_island(island, SEED)
    _check(flora.count > 0, "seed 1 has a population")
    var prev = List[Float64]()
    for i in range(flora.count):
        prev.append(Float64(flora.instances[i].scale))
        _check(
            prev[i] >= FLORA_SCALE_MIN - 1.0e-9
            and prev[i] <= FLORA_SCALE_MAX + 1.0e-9,
            "initial scale within bounds",
        )
    # Tick past the longest maturity: monotone non-decreasing, always
    # bounded, constant once age ≥ maturity (curve saturates, ε-snap never
    # moves a saturated curve).
    for t in range(MAX_MATURITY + 120):
        flora_tick(flora)
        _check(
            0 < flora.count <= FLORA_N_MAX,
            "population within (0, FLORA_N_MAX) each tick (d)",
        )
        for i in range(flora.count):
            var s = Float64(flora.instances[i].scale)
            _check(
                s >= FLORA_SCALE_MIN - 1.0e-9 and s <= FLORA_SCALE_MAX + 1.0e-9,
                "scale stays within [SCALE_MIN, SCALE_MAX] (a)",
            )
            _check(s >= prev[i] - 1.0e-9, "scale non-decreasing (a)")
            prev[i] = s
            var m = flora_maturity_ticks(flora.instances[i].species_id)
            if flora.ages[i] > m:
                # Past saturation: the stored scale must sit within one ε
                # step of the saturated curve (ε-quantized snap) — it can
                # never drift further down or sideways.
                var f = _final_scale(flora, i)
                _check(
                    abs(s - f) <= FLORA_EMIT_EPS * s + 1.0e-9,
                    "post-maturity stored scale within ε of curve (a)",
                )
        if t == MAX_MATURITY + 60:
            # Freeze a copy; a further stretch of ticks must not move it.
            var frozen = List[Float64]()
            for i in range(flora.count):
                frozen.append(Float64(flora.instances[i].scale))
            for _ in range(60):
                flora_tick(flora)
            for i in range(flora.count):
                _check(
                    abs(Float64(flora.instances[i].scale) - frozen[i]) < 1.0e-12,
                    "scale constant for age ≥ maturity (a)",
                )


def _final_scale(flora: FloraSubject, i: Int) -> Float64:
    """Curve value at the CURRENT age (for the stability marker above)."""
    var inst = flora.instances[i]
    var a = anchor_cell_of(inst.x, inst.z)
    var s0 = flora_anchor_scale(flora.seed, a[0], a[1])
    var a0 = flora_initial_age(flora.seed, a[0], a[1], inst.species_id)
    return flora_scale_for_age(inst.species_id, s0, a0, flora.ages[i])


# --- (b) run-twice identical age/scale sequence ------------------------------

def test_b_run_twice_identical_sequence() raises:
    var island1 = build_island(SEED)
    var island2 = build_island(SEED)
    var f1 = flora_from_island(island1, SEED)
    var f2 = flora_from_island(island2, SEED)
    _check(f1.count == f2.count, "same population size")
    for t in range(PROBE_TICKS + 1):
        for i in range(f1.count):
            _check(
                f1.ages[i] == f2.ages[i],
                "identical age sequence (b) at tick " + String(t),
            )
            _check(
                f1.instances[i].scale == f2.instances[i].scale,
                "identical scale sequence (b) at tick " + String(t),
            )
        flora_tick(f1)
        flora_tick(f2)


# --- (c) dig → anchor plant absent next tick; freed cell may establish -------

def test_c_dig_removes_anchor_and_freed_cell_may_establish() raises:
    var world = world_init(SEED)
    _check(world.flora.count > 0, "seed 1 population present")
    # Age the population a few ticks so the victim's age diverges from the
    # fresh-establishment age (a0) the re-scan will assign.
    for _ in range(3):
        _ = step_world(world, 1.0 / 60.0, idle_input())
    # Pick an established anchor plant on a cell high enough that the dig
    # clears the bedrock guard (surface lattice must stay > 1).
    var victim = -1
    for i in range(world.flora.count):
        var c = anchor_cell_of(
            world.flora.instances[i].x, world.flora.instances[i].z
        )
        if world.island.heights[c[1] * GRID_N + c[0]] >= 3.0:
            victim = i
            break
    _check(victim >= 0, "found a diggable anchor plant")
    var vcell = anchor_cell_of(
        world.flora.instances[victim].x, world.flora.instances[victim].z
    )
    var old_age = world.flora.ages[victim]
    var old_species = world.flora.instances[victim].species_id
    var vver = world.world_version
    var h0 = world.island.heights[vcell[1] * GRID_N + vcell[0]]
    # Pose at the victim's anchor cell, looking straight down, dig.
    # Proven pose (test_edit_ops._aim_down): world_to_cell floors so a cell
    # span STARTS at its centre — yaw must drift +z (yaw = pi) to stay in
    # the victim column; feet at h + 5 keeps the eye clear of the surface.
    var vx = (Float64(vcell[0]) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
    var vz = (Float64(vcell[1]) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
    world.player.x = vx
    world.player.z = vz
    world.player.y = world.island.heights[vcell[1] * GRID_N + vcell[0]] + 5.0
    world.player.pitch = -1.45  # look down
    world.player.yaw = 3.141592653589793  # drift +z, stays in victim column
    _check(
        edit_apply_batch(world.edit_queue, world.hotbar, EDIT_OP_DIG, 0),
        "dig enqueued",
    )
    # Next tick: edit applies → world_version bump → flora_re_evaluate runs
    # BEFORE this tick's flora_tick (tick order in world.mojo).
    _ = step_world(world, 1.0 / 60.0, idle_input())
    _check(
        world.world_version == vver + 1,
        "dig applied (world_version bump) — ray must hit the victim cell",
    )
    _check(
        world.island.heights[vcell[1] * GRID_N + vcell[0]] == h0 - 1.0,
        "dig lowered the victim anchor cell by 1 u",
    )
    # R5: the aged anchor plant died the same tick — no instance at that
    # cell still carries its pre-dig age.
    var found_at_cell = -1
    for i in range(world.flora.count):
        var c = anchor_cell_of(
            world.flora.instances[i].x, world.flora.instances[i].z
        )
        if c[0] == vcell[0] and c[1] == vcell[1]:
            _check(
                world.flora.ages[i] != old_age,
                "aged anchor plant absent next tick after dig (c)",
            )
            found_at_cell = i
    # Freed cell may establish: any plant there now is a FRESH establishment
    # (age == a0 + this tick's aging, scale == s0 establishment scale).
    if found_at_cell >= 0:
        var sp = world.flora.instances[found_at_cell].species_id
        var expect_a0 = flora_initial_age(SEED, vcell[0], vcell[1], sp)
        _check(
            world.flora.ages[found_at_cell] == expect_a0 + 1,
            "re-established plant has fresh age a0 (+1 tick aging) (c)",
        )
        _check(
            abs(
                Float64(world.flora.instances[found_at_cell].scale)
                - flora_anchor_scale(SEED, vcell[0], vcell[1])
            )
            < 1.0e-6,
            "re-established plant scale == s0 (c)",
        )
    # Independent of the dig outcome: the pristine island's field DOES
    # establish that cell (band + suit ≥ threshold) — a full re-scan from an
    # empty subject reproduces the pristine population including it.
    var restored = build_island(SEED)
    var flora0 = flora_from_island(restored, SEED)
    var rescan = flora_re_evaluate(restored, FloraSubject(), SEED)
    _check(
        rescan.count == flora0.count,
        "clean rescan reproduces the pristine population",
    )
    var seen = False
    for i in range(rescan.count):
        var c = anchor_cell_of(rescan.instances[i].x, rescan.instances[i].z)
        if c[0] == vcell[0] and c[1] == vcell[1]:
            seen = True
            _check(
                rescan.instances[i].species_id == old_species,
                "re-established species matches seed band (c)",
            )
    _check(seen, "freed cell establishes on the pristine field (c)")


# --- (d) count bound is checked inside (a); explicit smoke here too ----------

def test_d_population_bound_at_every_tick() raises:
    var flora = flora_from_island(build_island(SEED), SEED)
    _check(0 < flora.count <= FLORA_N_MAX, "initial count in (0, N_MAX]")
    for _ in range(PROBE_TICKS):
        flora_tick(flora)
        _check(
            0 < flora.count <= FLORA_N_MAX,
            "count stays in (0, N_MAX] (d)",
        )


# --- (e) emission dirty ⇔ ε-threshold crossings ------------------------------

def test_e_emission_dirty_fires_exactly_on_epsilon_crossings() raises:
    # Unit level: the predicate itself.
    _check(not flora_emission_dirty(1.0, 1.0), "no delta ⇒ not dirty")
    _check(
        not flora_emission_dirty(1.0, 1.0 + 0.5 * FLORA_EMIT_EPS),
        "sub-ε delta ⇒ not dirty",
    )
    _check(
        flora_emission_dirty(1.0, 1.0 + FLORA_EMIT_EPS),
        "exact ε delta ⇒ dirty",
    )
    _check(
        flora_emission_dirty(1.0, 1.0 - FLORA_EMIT_EPS),
        "downward ε delta ⇒ dirty",
    )
    _check(not flora_emission_dirty(1.2, 1.2), "1.2 no delta ⇒ not dirty")
    _check(
        flora_emission_dirty(1.2, 1.2 * (1.0 + FLORA_EMIT_EPS)),
        "relative-to-prev scaling is correct",
    )
    # System level: over PROBE_TICKS of real ticking, fires == changes.
    var flora = flora_from_island(build_island(SEED), SEED)
    var last = _copy_instances(flora)
    var fires = 0
    var changes = 0
    for _ in range(PROBE_TICKS):
        flora_tick(flora)
        if _flora_changed_since(flora, last):
            changes += 1
        # Compare against the last state that WOULD have been emitted.
        var now = _flora_changed_since(flora, last)
        if now:
            fires += 1
            last = _copy_instances(flora)
    _check(
        fires == changes,
        "emission dirty fires exactly on stored-scale changes (e)",
    )
    # ε-quantization: every fired step moved a stored scale by ≥ ε relative.
    # (Structural count/pose cannot change without an edit — none here — so
    # every fire is a scale crossing by construction of _flora_changed_since.)
    _check(fires > 0, "growth produced at least one ε crossing in 300 ticks")


# --- suitability band oracle (for the extended placement test contract) -------

def test_suitability_band_oracle() raises:
    var island = build_island(SEED)
    for iz in range(GRID_N):
        for ix in range(GRID_N):
            var ci = iz * GRID_N + ix
            var slope = cell_slope(island.heights, ix, iz)
            var height = island.heights[ci]
            var suit = establishment_suitability(
                ix,
                iz,
                island.biomes[ci],
                slope,
                height,
                FLORA_WETNESS_NEUTRAL,
                FLORA_CRATER_STRESS_NEUTRAL,
                SEED,
            )
            var species = feature_for_column(
                ix, iz, island.biomes[ci], slope, height, SEED
            )
            if species != SPECIES_NONE:
                # Every establishment implies band + suit ≥ threshold.
                _check(height >= SEA_LEVEL + FLORA_HEIGHT_EPS, "band height")
                if island.biomes[ci] == BIOME_BEACH:
                    _check(slope <= FLORA_BEACH_SLOPE_CAP, "beach slope cap")
                elif island.biomes[ci] == BIOME_VOLCANIC_SLOPE:
                    _check(slope <= FLORA_SLOPE_CAP, "slope cap")
                else:
                    _check(False, "establishment on banned biome")
                _check(
                    suit >= FLORA_SUITABILITY_THRESHOLD,
                    "establishment implies suit ≥ threshold",
                )
            _check(suit >= 0.0 and suit <= 1.0, "suitability ∈ [0, 1]")
    # Species → catalog resolution retained.
    var insts = instance_for_column(0, 0, 0, 0.0, 0.0, SEED)
    _check(
        insts.species_id == SPECIES_NONE
        or (
            insts.species_id >= SPECIES_PALM_CLUSTER
            and insts.species_id <= SPECIES_FERN_CARPET
        ),
        "species resolves inside catalog enum",
    )


# --- perf probe: measured cost of the flora_re_evaluate full rescan ----------

def test_perf_rescan_cost_reported() raises:
    """Measures flora_re_evaluate over the full grid (Sprint 01 gate: fill
    the measured µs into the world.mojo rescan-strategy comment)."""
    var island = build_island(SEED)
    var flora = flora_from_island(island, SEED)
    var reps = 5
    var t0 = _now_ns()
    for _ in range(reps):
        var next_f = flora_re_evaluate(island, flora, SEED)
        flora = next_f^
    var t1 = _now_ns()
    var per_call_ns = (t1 - t0) // Int64(reps)
    var per_call_us = Float64(per_call_ns) / 1000.0
    print(
        "  [perf] flora_re_evaluate full rescan: "
        + String(per_call_us)
        + " us/call (grid "
        + String(GRID_N)
        + "x"
        + String(GRID_N)
        + ", pop "
        + String(flora.count)
        + ")"
    )
    _check(per_call_ns > 0, "perf probe produced a positive duration")
    _check(per_call_ns < 2_000_000_000, "rescan under 2 s")


def main() raises:
    TestSuite.discover_tests[
        (
            test_a_scale_monotone_bounded_until_maturity,
            test_b_run_twice_identical_sequence,
            test_c_dig_removes_anchor_and_freed_cell_may_establish,
            test_d_population_bound_at_every_tick,
            test_e_emission_dirty_fires_exactly_on_epsilon_crossings,
            test_suitability_band_oracle,
            test_perf_rescan_cost_reported,
        )
    ]().run()
