# Spec test — Flora variation + selection (milestone_0009 Sprint 02 §5):
#   (a) trait distribution: pure-hash draws sane over host cells AND over
#       the selected population (fixed thresholds); traits parallel to the
#       population and constant over instance life (trivial inheritance)
#   (b) establishment rate in the high-stress band (crater-adjacent,
#       dist < 48 u) is significantly lower than in the low-stress band
#       (dist > 72 u = ash falloff radius); every emitted instance
#       satisfies the field threshold + selection predicate at the
#       DECLARED environment (spec §6 invariant 4, EVOLUTION-INV-011)
#   (c) synthetic stress raise (wetness forced to 0) kills a deterministic
#       SUPerset of the baseline death set — same set across runs
#       (R6 / EVOLUTION-INV-018), and the wave leaves 0 < count ≤ N_MAX
#   (d) run-twice identical population sequences over ≥ 600 ticks
#       (counts, poses, ages, scales, traits every tick)
#   (e) count ≤ FLORA_N_MAX held after death waves; count > 0 still —
#       selection must not sterilize the seed-1 world
# Stress model under test (milestone §1.2 decision, parameters.mojo block):
#   local_stress = W_ASH·ash_raw(crater_dist) + W_DROUGHT·drought_raw(w),
#   selection fails a candidate iff either WEIGHTED term exceeds its trait
#   tolerance. Headless: runs without Godot.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op.
# Every check below uses `_check`, which raises Error ⇒ TestSuite FAIL.

from std.collections import List
from std.testing import TestSuite
from std.math import sqrt

from sim.island import build_island, IslandSubject
from sim.world import world_init, step_world
from sim.volcano import volcano_from_island
from sim.flora import (
    FloraSubject,
    flora_from_island,
    flora_re_evaluate,
    flora_tick,
    flora_survival,
    flora_traits,
    flora_ash_stress,
    flora_drought_stress,
    flora_selection_passes,
    establishment_suitability,
    feature_for_column,
    cell_slope,
    anchor_cell_of,
    cell_world_x,
    cell_world_z,
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
    FLORA_SUITABILITY_THRESHOLD,
    FLORA_ASH_FALLOFF_RADIUS,
    FLORA_STRESS_W_ASH,
    FLORA_STRESS_W_DROUGHT,
    FLORA_DROUGHT_WETNESS_REF,
)
from materials.catalog import SPECIES_NONE
from synthesis.voxel import BIOME_BEACH, BIOME_VOLCANIC_SLOPE

comptime SEED: UInt32 = 1
# Band radii for the establishment-rate comparison (b): R_HIGH is inside the
# ash falloff (ash_raw > 0 for every cell), R_LOW equals the falloff radius
# (ash_raw = 0 beyond it — drought is common to both bands, so the ash term
# is the only difference between the bands).
comptime R_HIGH: Float64 = 48.0
comptime R_LOW: Float64 = 72.0
comptime TICKS: Int = 600  # (d)/(e) — well past 0009's 420-tick growth probe
comptime INIT_WETNESS: Float64 = 0.0  # committed weather at world_init (dt = 0)
comptime WET_WETNESS: Float64 = 1.0  # saturated wetness for the synthetic wave


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _crater(island: IslandSubject) raises -> Tuple[Float64, Float64]:
    var v = volcano_from_island(island)
    return (v.center_x, v.center_z)


def _dist_to_crater(x: Float64, z: Float64, cx: Float64, cz: Float64) -> Float64:
    var dx = x - cx
    var dz = z - cz
    return sqrt(dx * dx + dz * dz)


def _cell_index(x: Float32, z: Float32) -> Int:
    var c = anchor_cell_of(x, z)
    return c[1] * GRID_N + c[0]


def _dead_cells(
    before: FloraSubject, after: FloraSubject
) -> List[Int]:
    """Cells that held a plant in `before` but none in `after` (deaths)."""
    var alive = List[Int]()
    for _ in range(GRID_N * GRID_N):
        alive.append(0)
    for i in range(after.count):
        alive[_cell_index(after.instances[i].x, after.instances[i].z)] = 1
    var dead = List[Int]()
    for i in range(before.count):
        var ci = _cell_index(before.instances[i].x, before.instances[i].z)
        if alive[ci] == 0:
            dead.append(ci)
    return dead^


def _contains(cells: List[Int], v: Int) -> Bool:
    for i in range(len(cells)):
        if cells[i] == v:
            return True
    return False


def _all_in(haystack: List[Int], needles: List[Int]) -> Bool:
    for i in range(len(needles)):
        if not _contains(haystack, needles[i]):
            return False
    return True


# --- (a) trait distribution + trivial inheritance ----------------------------

def test_a_trait_distribution_and_invariance() raises:
    var island = build_island(SEED)
    var e = _crater(island)
    var cx = e[0]
    var cz = e[1]

    # a1: raw hash draws over every HOST cell (before selection) look like
    # hash01: mean ≈ 0.5, var ≈ 1/12, n ≈ 150 ⇒ fixed bounds with ~4σ slack.
    var n = 0
    var s_ash = 0.0
    var s_dry = 0.0
    var q_ash = 0.0
    var q_dry = 0.0
    for iz in range(GRID_N):
        for ix in range(GRID_N):
            var ci = iz * GRID_N + ix
            var slope = cell_slope(island.heights, ix, iz)
            if (
                feature_for_column(
                    ix, iz, island.biomes[ci], slope, island.heights[ci], SEED
                ) == SPECIES_NONE
            ):
                continue
            var t = flora_traits(SEED, ix, iz)
            _check(
                t.ash >= 0.0 and t.ash < 1.0 and t.drought >= 0.0
                and t.drought < 1.0,
                "raw trait draw inside [0, 1)",
            )
            n += 1
            s_ash += t.ash
            s_dry += t.drought
            q_ash += t.ash * t.ash
            q_dry += t.drought * t.drought
    _check(n >= 100, "seed 1 has ≥ 100 host cells")
    var m_ash = s_ash / Float64(n)
    var m_dry = s_dry / Float64(n)
    var v_ash = q_ash / Float64(n) - m_ash * m_ash
    var v_dry = q_dry / Float64(n) - m_dry * m_dry
    _check(
        m_ash >= 0.40 and m_ash <= 0.60,
        "host-cell ash tolerance mean ∈ [0.40, 0.60] (hash sanity)",
    )
    _check(
        m_dry >= 0.40 and m_dry <= 0.60,
        "host-cell drought tolerance mean ∈ [0.40, 0.60] (hash sanity)",
    )
    _check(
        v_ash >= 0.03 and v_ash <= 0.14,
        "host-cell ash tolerance variance ∈ [0.03, 0.14] (1/12 ± slack)",
    )
    _check(
        v_dry >= 0.03 and v_dry <= 0.14,
        "host-cell drought tolerance variance ∈ [0.03, 0.14] (1/12 ± slack)",
    )

    # a2: the SELECTED population is a left-truncated draw (establishment
    # kept tolerance ≥ local stress), so its mean sits above 0.5 and its
    # variance below 1/12 — still bounded, fixed thresholds.
    var pop = flora_from_island(island, SEED, cx, cz, INIT_WETNESS)
    _check(pop.count > 0, "seed 1 population non-empty (not sterilized)")
    _check(
        pop.count == len(pop.traits) and pop.count == len(pop.ages),
        "traits/ages parallel to instances (SIM-side lists)",
    )
    var p_ash = 0.0
    var p_dry = 0.0
    var p_ash2 = 0.0
    var p_dry2 = 0.0
    for i in range(pop.count):
        var t = pop.traits[i]
        _check(
            t.ash >= 0.0 and t.ash < 1.0 and t.drought >= 0.0
            and t.drought < 1.0,
            "population trait inside [0, 1)",
        )
        p_ash += t.ash
        p_dry += t.drought
        p_ash2 += t.ash * t.ash
        p_dry2 += t.drought * t.drought
    var pm_ash = p_ash / Float64(pop.count)
    var pm_dry = p_dry / Float64(pop.count)
    var pv_ash = p_ash2 / Float64(pop.count) - pm_ash * pm_ash
    var pv_dry = p_dry2 / Float64(pop.count) - pm_dry * pm_dry
    _check(
        pm_ash >= 0.50 and pm_ash <= 0.90,
        "population ash tolerance mean ∈ [0.50, 0.90]",
    )
    _check(
        pm_dry >= 0.55 and pm_dry <= 0.90,
        "population drought tolerance mean ∈ [0.55, 0.90]",
    )
    _check(
        pv_ash >= 0.01 and pv_ash <= 0.20,
        "population ash tolerance variance ∈ [0.01, 0.20]",
    )
    _check(
        pv_dry >= 0.005 and pv_dry <= 0.15,
        "population drought tolerance variance ∈ [0.005, 0.15]",
    )

    # a3: trivial inheritance — traits constant over instance life (they are
    # a pure cell hash; growth ticks must not move them).
    var frozen = List[Float64]()
    for i in range(pop.count):
        frozen.append(pop.traits[i].ash)
        frozen.append(pop.traits[i].drought)
    for _ in range(5):
        flora_tick(pop)
    for i in range(pop.count):
        _check(
            pop.traits[i].ash == frozen[2 * i]
            and pop.traits[i].drought == frozen[2 * i + 1],
            "traits constant over instance life (INV-006 trivial)",
        )
    # Same cell ⇒ same traits (trivial lineage, INV-007).
    var first = pop.instances[0]
    var c0 = anchor_cell_of(first.x, first.z)
    var t0 = flora_traits(SEED, c0[0], c0[1])
    _check(
        pop.traits[0].ash == t0.ash and pop.traits[0].drought == t0.drought,
        "stored trait equals the pure cell hash (no hidden state)",
    )


# --- (b) establishment rate: high-stress band vs low-stress band ------------

def test_b_high_stress_band_establishes_less() raises:
    var island = build_island(SEED)
    var e = _crater(island)
    var cx = e[0]
    var cz = e[1]

    # Candidates = host cells (band preconditions + density propensity pass,
    # feature_for_column ≠ NONE) — the same population the field gates over.
    var hosts_high = 0
    var hosts_low = 0
    for iz in range(GRID_N):
        for ix in range(GRID_N):
            var ci = iz * GRID_N + ix
            var slope = cell_slope(island.heights, ix, iz)
            if (
                feature_for_column(
                    ix, iz, island.biomes[ci], slope, island.heights[ci], SEED
                ) == SPECIES_NONE
            ):
                continue
            var d = _dist_to_crater(
                cell_world_x(ix), cell_world_z(iz), cx, cz
            )
            if d < R_HIGH:
                hosts_high += 1
            if d > R_LOW:
                hosts_low += 1
    _check(hosts_high >= 10, "high-stress band has ≥ 10 candidate hosts")
    _check(hosts_low >= 10, "low-stress band has ≥ 10 candidate hosts")

    var pop = flora_from_island(island, SEED, cx, cz, INIT_WETNESS)
    var est_high = 0
    var est_low = 0
    var drought_raw = flora_drought_stress(INIT_WETNESS)
    for i in range(pop.count):
        var inst = pop.instances[i]
        var c = anchor_cell_of(inst.x, inst.z)
        var d = _dist_to_crater(
            Float64(inst.x), Float64(inst.z), cx, cz
        )
        if d < R_HIGH:
            est_high += 1
        if d > R_LOW:
            est_low += 1
        # Spec §6 invariant 4 at the DECLARED inputs: every emitted
        # instance passes the field threshold and the selection predicate.
        var slope = cell_slope(island.heights, c[0], c[1])
        var ci = c[1] * GRID_N + c[0]
        var ash_raw = flora_ash_stress(d)
        var suit = establishment_suitability(
            c[0],
            c[1],
            island.biomes[ci],
            slope,
            island.heights[ci],
            INIT_WETNESS,
            ash_raw,
            SEED,
        )
        _check(
            suit >= FLORA_SUITABILITY_THRESHOLD,
            "emitted instance has suitability ≥ threshold (invariant 4)",
        )
        _check(
            flora_selection_passes(pop.traits[i], ash_raw, drought_raw),
            "emitted instance passes selection at declared environment",
        )

    var rate_high = Float64(est_high) / Float64(hosts_high)
    var rate_low = Float64(est_low) / Float64(hosts_low)
    # Fixed thresholds (0009 §5 "significantly lower"): the crater-adjacent
    # band must establish at least 20 % relatively and 10 points absolutely
    # BELOW the ash-free band. Measured on seed 1: 0.41 vs 0.73 (ratio
    # 0.56) — thresholds carry ≥ 2× the observed gap as margin.
    _check(
        rate_high <= 0.80 * rate_low,
        "high-stress establishment rate ≤ 80% of low-stress rate",
    )
    _check(
        rate_low - rate_high >= 0.10,
        "high-stress rate ≥ 10 points below low-stress rate",
    )
    # Neither band is sterilized (selection must not nuke a band).
    _check(rate_high > 0.0, "high-stress band still establishes (not sterile)")
    _check(rate_low >= 0.50, "low-stress band establishes at ≥ 50%")


# --- (c) synthetic stress raise kills a deterministic superset ---------------

def _wet_population(island: IslandSubject) raises -> FloraSubject:
    """Population established under SATURATED wetness (drought term = 0):
    only the ash tolerance was binding, so the drought-tolerance draw stays
    uniform — the drop to wetness 0 can then kill (this mirrors a real
    seed-1 trajectory: establish during rain, drought arrives later)."""
    var e = _crater(island)
    return flora_re_evaluate(
        island, FloraSubject(), SEED, e[0], e[1], WET_WETNESS
    )


def _wave(wetness: Float64) raises -> FloraSubject:
    """Establish under wetness 1, then run the survival pass at `wetness`;
    returns the post-wave population."""
    var island = build_island(SEED)
    var pop = _wet_population(island)
    var e = _crater(island)
    flora_survival(pop, e[0], e[1], wetness)
    return pop^


def _wave_deaths(wetness: Float64) raises -> List[Int]:
    """Same construction as _wave; returns the death-set cell indices."""
    var island = build_island(SEED)
    var before = _wet_population(island)
    var pop = _wet_population(island)
    var e = _crater(island)
    flora_survival(pop, e[0], e[1], wetness)
    return _dead_cells(before, pop)^


def test_c_stress_raise_kills_deterministic_superset() raises:
    # Baseline: survival with the SAME wetness the population established at
    # ⇒ nothing can die (establishment already proved the tolerances cover
    # the environment).
    var dead_base = _wave_deaths(WET_WETNESS)
    # Synthetic raise: wetness forced to 0 (maximum drought term), two runs.
    var dead_a = _wave_deaths(INIT_WETNESS)
    var dead_b = _wave_deaths(INIT_WETNESS)

    _check(
        len(dead_a) > 0,
        "forced wetness 0 kills at least one plant (wave non-vacuous)",
    )
    # Same set across runs (R6 / EVOLUTION-INV-018): identical length AND
    # identical cells in the same deterministic order.
    _check(
        len(dead_a) == len(dead_b),
        "death set length identical across runs",
    )
    for i in range(len(dead_a)):
        _check(dead_a[i] == dead_b[i], "death set cells identical (R6)")
    # Deterministic superset of the baseline deaths.
    _check(
        _all_in(dead_a, dead_base),
        "raised-stress deaths ⊇ baseline deaths (superset, R6)",
    )
    _check(
        len(dead_a) > len(dead_base),
        "raised-stress death set is a STRICT superset",
    )
    # Post-wave bounds: the survivors are the population now (e).
    var after = _wave(INIT_WETNESS)
    _check(
        0 < after.count and after.count <= FLORA_N_MAX,
        "count stays in (0, N_MAX] after the death wave",
    )
    _check(
        after.count == len(after.instances)
        and after.count == len(after.ages)
        and after.count == len(after.traits),
        "SIM-side lists stay parallel after the death wave",
    )


# --- (d) run-twice identical population sequences over ≥ 600 ticks -----------

def test_d_run_twice_identical_population_sequence() raises:
    var w1 = world_init(SEED)
    var w2 = world_init(SEED)
    _check(
        w1.flora.count == w2.flora.count and w1.flora.count > 0,
        "identical non-empty population at init",
    )
    for k in range(TICKS):
        _ = step_world(w1, 1.0 / 60.0, idle_input())
        _ = step_world(w2, 1.0 / 60.0, idle_input())
        _check(
            w1.flora.count == w2.flora.count,
            "identical population count at tick " + String(k + 1),
        )
        _check(
            0 < w1.flora.count and w1.flora.count <= FLORA_N_MAX,
            "count in (0, N_MAX] during the run (e)",
        )
        for i in range(w1.flora.count):
            var a = w1.flora.instances[i]
            var b = w2.flora.instances[i]
            _check(
                a.x == b.x and a.y == b.y and a.z == b.z,
                "identical pose sequence at tick " + String(k + 1),
            )
            _check(
                a.yaw == b.yaw and a.scale == b.scale
                and a.species_id == b.species_id,
                "identical pose/species sequence at tick " + String(k + 1),
            )
            _check(
                w1.flora.ages[i] == w2.flora.ages[i],
                "identical age sequence at tick " + String(k + 1),
            )
            _check(
                w1.flora.traits[i].ash == w2.flora.traits[i].ash
                and w1.flora.traits[i].drought == w2.flora.traits[i].drought,
                "identical trait sequence at tick " + String(k + 1),
            )


# --- (e) cap + non-sterilization held through death waves --------------------

def test_e_cap_held_and_world_not_sterilized() raises:
    # Seed-1 world: selection must leave a population at init and after a
    # long run (weights are tuned in parameters.mojo, never by weakening
    # this check).
    var world = world_init(SEED)
    _check(
        world.flora.count > 0 and world.flora.count <= FLORA_N_MAX,
        "seed-1 init population in (0, N_MAX]",
    )
    # Short live smoke (test (d) already asserts these bounds every tick
    # across TICKS ticks — this keeps suite runtime sane while still
    # exercising the world-level death pass end-to-end).
    for _ in range(60):
        _ = step_world(world, 1.0 / 60.0, idle_input())
        _check(
            0 < world.flora.count and world.flora.count <= FLORA_N_MAX,
            "count in (0, N_MAX] every tick of the live run",
        )
    # Death wave: a full forced-drought pass over the wet-established
    # population must respect the same bounds and shrink, never grow.
    var island = build_island(SEED)
    var e = _crater(island)
    var before = _wet_population(island)
    _check(
        0 < before.count and before.count <= FLORA_N_MAX,
        "pre-wave population in (0, N_MAX]",
    )
    var wave = _wet_population(island)
    flora_survival(wave, e[0], e[1], INIT_WETNESS)
    _check(wave.count <= before.count, "death wave never grows the count")
    _check(
        0 < wave.count and wave.count <= FLORA_N_MAX,
        "count in (0, N_MAX] after the death wave (cap + not sterilized)",
    )
    _check(
        wave.count < before.count,
        "forced-drought wave actually kills (death path exercised)",
    )


def main() raises:
    TestSuite.discover_tests[
        (
            test_a_trait_distribution_and_invariance,
            test_b_high_stress_band_establishes_less,
            test_c_stress_raise_kills_deterministic_superset,
            test_d_run_twice_identical_population_sequence,
            test_e_cap_held_and_world_not_sterilized,
        )
    ]().run()
