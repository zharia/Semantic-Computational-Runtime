# FloraSubject — deterministic flora scatter + field-gated growth +
# variation/selection (milestone_0006 Sprint 01; milestone_0009 Sprints
# 01+02; SCR-LIB-ECOLOGY §1/§3/§9/§43, SCR-LIB-EVOLUTION §1.4/§1.5 and
# 601_Agent are spec-only contracts — implemented here in Mojo per
# definition: explicit population membership, explicit environment (band
# conditions + establishment field + stress inputs), per-instance age and
# species growth curve, per-instance trait variation + selection,
# declared + test-verified determinism).
#
# Placement locus (0006 §1.1 locked decision): FloraSubject in the SIM. The
# lattice columns keep FEATURE_NONE (voxel-object realization stays disabled —
# recorded deviation from Synthesis §3, 0006 §4); instances are emitted as the
# §10 FLORA section and rendered as MultiMesh transforms. Godot never places,
# counts or scales ecology (0006 AP-11).
#
# feature_for_column / establishment_suitability / growth / traits / stress /
# selection are PURE functions: integer hashes over (seed, x, z) + declared
# world state — no mutable RNG stream, order-independent (0006 §1.1 / §6
# invariant 4; 0009 R1/R8, AP-20, EVOLUTION-INV-018). Band table + all
# tunables live in sim/parameters.mojo (AP-7); species → catalog material
# lives in materials/catalog.mojo (0006 AP-14).
#
# Growth (0009 Sprint 01, Flora §1.3): every instance carries an `age`
# (ecological time; FloraSubject.ages is SIM-SIDE ONLY — the 24 B wire
# record in snapshot/types.mojo is untouched, layout neutrality invariant).
# scale = f_species(age) is anchored at the establishment scale s0 (pure
# hash of the anchor cell) and accretes toward the species target, monotone
# to maturity then stable; stored scale is ε-quantized (FLORA_EMIT_EPS) so
# emission stays change-driven (AP-22). Establishment/death/aging mutate
# state ONLY in the tick phase (world.mojo) — the projection reads it
# read-only (projection purity, 0006 §6.8 / 0009 invariant 7).
#
# Variation + selection (0009 Sprint 02, Flora §1.4 / SCR-LIB-EVOLUTION
# §1.4, milestone §1.1 stress row — §1.2 open decision RESOLVED):
#   STRESS MODEL (exact; params in sim/parameters.mojo):
#     ash_raw(dist)  = clamp(1 − dist / FLORA_ASH_FALLOFF_RADIUS, 0, 1)
#     drought_raw(w) = clamp((FLORA_DROUGHT_WETNESS_REF − w)
#                            / FLORA_DROUGHT_WETNESS_REF, 0, 1)
#     local_stress   = clamp(W_ASH·ash_raw + W_DROUGHT·drought_raw, 0, 1)
#   ash uses the crater (volcano subject) distance; drought uses the weather
#   wetness — both pure sim state, both EXPLICIT function inputs (the crater
#   center and wetness are passed in by world.mojo at every call — no hidden
#   side channel, EVOLUTION-INV-011). No sim-side plume mask: plume advection
#   is shader-TIME only and none is invented (Rule 9).
#   TRAITS (EVOLUTION-INV-004 variation): per-instance FloraTraits vector,
#   FLORA_TRAIT_COUNT = 4 × f32 (ash tolerance, drought tolerance, 2
#   reserved), each from a PURE hash (seed, cell, trait_salt) — AP-20.
#   Storage: SIM-SIDE parallel list `traits` (traits[i] ↔ instances[i]),
#   exactly like `ages`: NOT on the 24 B wire (layout neutrality), folded
#   into the world fingerprint instead. Constant over the instance's life —
#   trivial inheritance/lineage per instance (EVOLUTION-INV-006/007:
#   traits are a pure function of the anchor cell, so a re-establishment at
#   the same cell yields the same trait vector; CROSS-generational
#   inheritance/lineage are OUT OF SCOPE — no reproduction in this domain).
#   SELECTION (EVOLUTION-INV-005, distinct from variation): a candidate
#   FAILS establishment and a plant DIES under survival iff
#   W_ASH·ash_raw > traits.ash OR W_DROUGHT·drought_raw > traits.drought
#   (componentwise ⇒ both traits are load-bearing; viability decision, no
#   scalar fitness — EVOLUTION-INV-009; no adaptation/learning: traits never
#   update from experience — ECOLOGY-INV-013 firewall).
#   Viability ≠ fitness: this file only ever compares one instance's
#   tolerance against its own local stress; instances are never ranked.
#
# Species vocabulary = Synthesis §3 FeatureTile flora rows (PALM/BAMBOO/
# CANOPY/SHRUB/FERN); the enum values live in materials/catalog.mojo so the
# species → catalog table and the enum stay single-sourced.
#
# Phenome (milestone_0010 Sprint 01): instances additionally carry SIM-side
# `stages` (developmental stage, advanced once per tick inside flora_tick)
# and `variant_seeds` (generative identity) — parallel lists exactly like
# `ages`/`traits`, never on the 24 B wire (layout neutrality until Sprint
# 02), folded into the world fingerprint and into the emission-dirty rule.
# Pure maps live in sim/phenome.mojo; grammar data in
# godot/data/phenome_grammars.json.
#
# Honest limitation (recorded here per R5; docs/04 is Sprint 04's):
# EVOLUTION-INV-006/007 are satisfied trivially per instance only.

from std.collections import List
from std.math import sqrt, atan2, floor

from sim.island import IslandSubject
from sim.parameters import (
    GRID_N,
    CELL_SIZE,
    SEA_LEVEL,
    FLORA_N_MAX,
    FLORA_HEIGHT_EPS,
    FLORA_SLOPE_CAP,
    FLORA_BEACH_SLOPE_CAP,
    FLORA_DENSITY_BEACH,
    FLORA_DENSITY_SLOPE,
    FLORA_WEIGHT_PALM_CLUSTER,
    FLORA_WEIGHT_CANOPY_TREE,
    FLORA_WEIGHT_CANOPY_CLUSTER,
    FLORA_WEIGHT_SHRUB,
    FLORA_WEIGHT_FERN_CARPET,
    FLORA_SCALE_MIN,
    FLORA_SCALE_MAX,
    FLORA_SUITABILITY_THRESHOLD,
    FLORA_WETNESS_NEUTRAL,
    FLORA_CRATER_STRESS_NEUTRAL,
    FLORA_EMIT_EPS,
    FLORA_GROWTH_SHAPE,
    FLORA_MATURITY_PALM_CLUSTER,
    FLORA_MATURITY_PALM_SOLO,
    FLORA_MATURITY_BAMBOO_GROVE,
    FLORA_MATURITY_CANOPY_TREE,
    FLORA_MATURITY_CANOPY_CLUSTER,
    FLORA_MATURITY_SHRUB,
    FLORA_MATURITY_FERN_CARPET,
    FLORA_TARGET_SCALE_PALM_CLUSTER,
    FLORA_TARGET_SCALE_PALM_SOLO,
    FLORA_TARGET_SCALE_BAMBOO_GROVE,
    FLORA_TARGET_SCALE_CANOPY_TREE,
    FLORA_TARGET_SCALE_CANOPY_CLUSTER,
    FLORA_TARGET_SCALE_SHRUB,
    FLORA_TARGET_SCALE_FERN_CARPET,
    FLORA_TRAIT_SALT_ASH,
    FLORA_TRAIT_SALT_DROUGHT,
    FLORA_ASH_FALLOFF_RADIUS,
    FLORA_STRESS_W_ASH,
    FLORA_STRESS_W_DROUGHT,
    FLORA_DROUGHT_WETNESS_REF,
)
from materials.catalog import (
    SPECIES_NONE,
    SPECIES_PALM_CLUSTER,
    SPECIES_PALM_SOLO,
    SPECIES_CANOPY_TREE,
    SPECIES_CANOPY_CLUSTER,
    SPECIES_SHRUB,
    SPECIES_FERN_CARPET,
)
from synthesis.voxel import (
    BIOME_BEACH,
    BIOME_VOLCANIC_SLOPE,
)
from synthesis.noise import hash01_cells
from snapshot.types import FloraInstance
from sim.phenome import stage_for_age, variant_seed

comptime TWO_PI: Float64 = 6.283185307179586
comptime _SALT_DENSITY: UInt64 = 0x100000001B3
comptime _SALT_SPECIES: UInt64 = 0x200000001B3
comptime _SALT_YAW: UInt64 = 0x300000001B3
comptime _SALT_SCALE: UInt64 = 0x400000001B3
comptime _SALT_AGE: UInt64 = 0x500000001B3  # initial-age hash (0009 R2)


struct FloraTraits(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Per-instance trait vector (0009 R1 / EVOLUTION-INV-004): fixed
    FLORA_TRAIT_COUNT = 4 × f32 — index 0 = ash tolerance, 1 = drought
    tolerance, 2..3 reserved (salts declared in parameters.mojo, unused
    until those traits exist). SIM-SIDE ONLY, parallel to `instances`
    (layout neutrality — never serialized, never on the 24 B wire).
    Values are hash01 ∈ [0, 1); constant over the instance's life."""

    var ash: Float64
    var drought: Float64
    var reserved0: Float64
    var reserved1: Float64

    def __init__(out self):
        self.ash = 0.0
        self.drought = 0.0
        self.reserved0 = 0.0
        self.reserved1 = 0.0

    def __deinit__(deinit self):
        pass


def flora_ash_stress(crater_dist: Float64) -> Float64:
    """Raw ash stress ∈ [0, 1] (0009 §1.1 stress row, milestone §1.2
    decision): pure linear crater-distance falloff, 1 at the crater center,
    0 at ≥ FLORA_ASH_FALLOFF_RADIUS. Pure function of distance only."""
    if crater_dist <= 0.0:
        return 1.0
    var a = 1.0 - crater_dist / FLORA_ASH_FALLOFF_RADIUS
    if a < 0.0:
        return 0.0
    if a > 1.0:
        return 1.0
    return a


def flora_drought_stress(wetness: Float64) -> Float64:
    """Raw drought stress ∈ [0, 1]: (REF − w)/REF clamped — 1 at dry
    (wetness 0), 0 at wetness ≥ FLORA_DROUGHT_WETNESS_REF. Pure function
    of the declared weather wetness (EVOLUTION-INV-011 explicit input)."""
    var d = (FLORA_DROUGHT_WETNESS_REF - wetness) / FLORA_DROUGHT_WETNESS_REF
    if d < 0.0:
        return 0.0
    if d > 1.0:
        return 1.0
    return d


def flora_local_stress(crater_dist: Float64, wetness: Float64) -> Float64:
    """Combined local stress ∈ [0, 1] = clamp(W_ASH·ash_raw +
    W_DROUGHT·drought_raw, 0, 1) — the field's environment term (env =
    1 − local_stress) and the scalar the milestone spec's stress row names.
    Pure function of (crater distance, wetness); both are explicit inputs,
    never a side channel (EVOLUTION-INV-011, INV-018)."""
    var s = (
        FLORA_STRESS_W_ASH * flora_ash_stress(crater_dist)
        + FLORA_STRESS_W_DROUGHT * flora_drought_stress(wetness)
    )
    if s < 0.0:
        return 0.0
    if s > 1.0:
        return 1.0
    return s


def flora_traits(seed: UInt32, x: Int, z: Int) -> FloraTraits:
    """Pure trait-variation draw (0009 R1 / EVOLUTION-INV-004): each of the
    FLORA_TRAIT_COUNT slots is hash01(seed, cell, trait_salt) — no RNG
    stream (AP-20), order-independent, identical for every re-evaluation of
    the same cell (trivial inheritance/lineage, INV-006/007: traits are a
    function of the anchor cell, constant over the instance's life)."""
    var t = FloraTraits()
    t.ash = hash01_cells(seed, x, z, FLORA_TRAIT_SALT_ASH)
    t.drought = hash01_cells(seed, x, z, FLORA_TRAIT_SALT_DROUGHT)
    # Slots 2..3 reserved (parameters.mojo salts) — no traits assigned yet.
    return t^


def flora_selection_passes(
    traits: FloraTraits, ash_raw: Float64, drought_raw: Float64
) -> Bool:
    """Selection predicate (EVOLUTION-INV-005): True iff the candidate's
    tolerances cover BOTH weighted stress components —
      W_ASH·ash_raw ≤ traits.ash AND W_DROUGHT·drought_raw ≤ traits.drought.
    Componentwise so both traits are load-bearing; comparison is against the
    weighted terms (a saturated drought still admits tolerances in
    [W_DROUGHT, 1)). Used unchanged by establishment selection (candidate
    fails ⇒ no establishment) and survival selection (plant fails ⇒ dies
    same tick) — one threshold, one meaning (no hysteresis needed: death is
    absorbing, see parameters.mojo). Viability decision only — no ranking,
    no fitness scalar (EVOLUTION-INV-009); no adaptation (ECOLOGY-INV-013).
    Pure ⇒ deterministic deaths (R6 / INV-018)."""
    if FLORA_STRESS_W_ASH * ash_raw > traits.ash:
        return False
    if FLORA_STRESS_W_DROUGHT * drought_raw > traits.drought:
        return False
    return True


def cell_slope(heights: List[Float64], ix: Int, iz: Int) -> Float64:
    """|∇h| at a grid cell via central differences (one-sided at the edges)."""
    var il = ix - 1
    if il < 0:
        il = 0
    var ir = ix + 1
    if ir > GRID_N - 1:
        ir = GRID_N - 1
    var jd = iz - 1
    if jd < 0:
        jd = 0
    var ju = iz + 1
    if ju > GRID_N - 1:
        ju = GRID_N - 1
    var span_x = Float64(ir - il) * CELL_SIZE
    if span_x <= 0.0:
        span_x = CELL_SIZE
    var span_z = Float64(ju - jd) * CELL_SIZE
    if span_z <= 0.0:
        span_z = CELL_SIZE
    var dx = (heights[iz * GRID_N + ir] - heights[iz * GRID_N + il]) / span_x
    var dz = (heights[ju * GRID_N + ix] - heights[jd * GRID_N + ix]) / span_z
    return sqrt(dx * dx + dz * dz)


def establishment_suitability(
    x: Int,
    z: Int,
    biome: Int,
    slope: Float64,
    height: Float64,
    wetness: Float64,
    crater_stress: Float64,
    seed: UInt32,
) -> Float64:
    """PURE flora-field sample (0009 R1; lib/705_Ecology/Flora §1.2/§1.5;
    argument order is the milestone §1.1 locked field signature):
    a function of its declared arguments only — no RNG stream, so evaluation
    order does not matter (AP-20).

    Hard band preconditions first (0006 band table), evaluated BEFORE the
    field value: height ≥ SEA_LEVEL + FLORA_HEIGHT_EPS, per-band slope cap,
    allowed biome — any failure ⇒ 0.0. Surviving cells sample the field:
      propensity = seed host hash (the 0006 density gate folded into the
                 field — same _SALT_DENSITY hash, so feature_for_column's
                 internal gate and the field always agree);
      environment = 1 − local_stress, where local_stress combines the
                 weighted ash term (crater_stress = raw crater-distance ash
                 ∈ [0,1], supplied by the caller) and the weighted drought
                 term derived from wetness — see flora_local_stress and the
                 stress-model block in parameters.mojo (Sprint 02: real
                 stress model, milestone §1.2 decision; the neutral
                 reference inputs are for unit oracles only).
    Returns ∈ [0, 1]; establishment additionally requires ≥
    FLORA_SUITABILITY_THRESHOLD AND the flora_selection_passes tolerance
    predicate (suitability is the field; selection is the trait filter —
    kept distinct, EVOLUTION-INV-004/005)."""
    if height < SEA_LEVEL + FLORA_HEIGHT_EPS:
        return 0.0
    var density: Float64
    if biome == BIOME_BEACH:
        if slope > FLORA_BEACH_SLOPE_CAP:
            return 0.0
        density = FLORA_DENSITY_BEACH
    elif biome == BIOME_VOLCANIC_SLOPE:
        if slope > FLORA_SLOPE_CAP:
            return 0.0
        density = FLORA_DENSITY_SLOPE
    else:
        # CALDERA_RIM / CALDERA_LAKE / SHALLOW_WATER / DEEP_OCEAN / jungle
        # rows (unused by the volcanic profile) → no flora.
        return 0.0
    if hash01_cells(seed, x, z, _SALT_DENSITY) >= density:
        return 0.0  # seed says this cell is not a host this generation
    var ash = crater_stress
    if ash < 0.0:
        ash = 0.0
    if ash > 1.0:
        ash = 1.0
    var drought = flora_drought_stress(wetness)
    var env = 1.0 - (
        FLORA_STRESS_W_ASH * ash + FLORA_STRESS_W_DROUGHT * drought
    )
    if env < 0.0:
        env = 0.0
    if env > 1.0:
        env = 1.0
    return env


def flora_maturity_ticks(species: UInt32) -> Int:
    """Per-species maturity (0009 R3): age in ticks where the growth curve
    saturates. Table lives in sim/parameters.mojo (AP-7); keyed here by the
    materials/catalog enum so parameters.mojo stays dependency-free."""
    if species == SPECIES_PALM_CLUSTER:
        return FLORA_MATURITY_PALM_CLUSTER
    if species == SPECIES_PALM_SOLO:
        return FLORA_MATURITY_PALM_SOLO
    if species == SPECIES_CANOPY_TREE:
        return FLORA_MATURITY_CANOPY_TREE
    if species == SPECIES_CANOPY_CLUSTER:
        return FLORA_MATURITY_CANOPY_CLUSTER
    if species == SPECIES_SHRUB:
        return FLORA_MATURITY_SHRUB
    if species == SPECIES_FERN_CARPET:
        return FLORA_MATURITY_FERN_CARPET
    # SPECIES_NONE / SPECIES_BAMBOO_GROVE (never placed by the band table).
    return FLORA_MATURITY_BAMBOO_GROVE


def flora_scale_target(species: UInt32) -> Float64:
    """Per-species mature scale target ∈ [FLORA_SCALE_MIN, FLORA_SCALE_MAX]
    (0009 R3; table in sim/parameters.mojo)."""
    if species == SPECIES_PALM_CLUSTER:
        return FLORA_TARGET_SCALE_PALM_CLUSTER
    if species == SPECIES_PALM_SOLO:
        return FLORA_TARGET_SCALE_PALM_SOLO
    if species == SPECIES_CANOPY_TREE:
        return FLORA_TARGET_SCALE_CANOPY_TREE
    if species == SPECIES_CANOPY_CLUSTER:
        return FLORA_TARGET_SCALE_CANOPY_CLUSTER
    if species == SPECIES_SHRUB:
        return FLORA_TARGET_SCALE_SHRUB
    if species == SPECIES_FERN_CARPET:
        return FLORA_TARGET_SCALE_FERN_CARPET
    return FLORA_TARGET_SCALE_BAMBOO_GROVE


def flora_anchor_scale(seed: UInt32, x: Int, z: Int) -> Float64:
    """Establishment scale s0: pure hash (seed, x, z) ∈ [SCALE_MIN,
    SCALE_MAX] (0006 _SALT_SCALE) — the per-instance base the growth curve
    accretes from (0009 R3; identical expression to the 0006 scatter so the
    initial wire scale bytes are unchanged)."""
    var su = hash01_cells(seed, x, z, _SALT_SCALE)
    return FLORA_SCALE_MIN + su * (FLORA_SCALE_MAX - FLORA_SCALE_MIN)


def flora_initial_age(seed: UInt32, x: Int, z: Int, species: UInt32) -> Int:
    """Initial age for a newly established plant (0009 R2): pure hash
    (seed, x, z) salted, range [0, maturity] so the population starts with a
    mixed age structure (AP-20 — no mutable RNG stream)."""
    var m = flora_maturity_ticks(species)
    if m <= 0:
        return 0
    var a0 = Int(hash01_cells(seed, x, z, _SALT_AGE) * Float64(m + 1))
    if a0 < 0:
        a0 = 0
    if a0 > m:
        a0 = m
    return a0


def flora_curve_progress(age: Int, maturity: Int) -> Float64:
    """Normalized growth-curve progress ∈ [0, 1] (0009 R3): 0 at age 0,
    saturates at maturity, then constant. Shape from FLORA_GROWTH_SHAPE —
    0 = linear-in-age, 1 = smoothstep (both monotone non-decreasing).
    Blended arithmetically (no runtime branch) so the comptime flag folds:
    s = 1 ⇒ 0·x + smoothstep(x), s = 0 ⇒ x."""
    if maturity <= 0:
        return 1.0
    if age <= 0:
        return 0.0
    var x = Float64(age) / Float64(maturity)
    if x >= 1.0:
        return 1.0
    var s = Float64(FLORA_GROWTH_SHAPE)  # 0 = linear, 1 = smoothstep
    return (1.0 - s) * x + s * (x * x * (3.0 - 2.0 * x))


def flora_scale_for_age(species: UInt32, s0: Float64, a0: Int, age: Int) -> Float64:
    """Species growth curve evaluated for one instance (0009 R3):
    scale(age) = s0 + (target − s0)⁺ · (P(age) − P(a0)), where P is the
    species curve progress. Properties:
      - scale(a0) = s0 exactly (the establishment scale — initial wire bytes
        are the 0006 hash values, golden fixture stays byte-identical);
      - non-decreasing in age while age < maturity (P monotone, only upward
        accretion is committed when target < s0 ⇒ base 0 ⇒ constant);
      - constant for age ≥ maturity (P saturates at 1);
      - bounded: s0, target ∈ [FLORA_SCALE_MIN, FLORA_SCALE_MAX]."""
    var m = flora_maturity_ticks(species)
    var base = flora_scale_target(species) - s0
    if base < 0.0:
        base = 0.0
    var prog = flora_curve_progress(age, m) - flora_curve_progress(a0, m)
    if prog < 0.0:
        prog = 0.0
    if prog > 1.0:
        prog = 1.0
    return s0 + base * prog


def flora_emission_dirty(prev_scale: Float64, cur_scale: Float64) -> Bool:
    """0009 §3.2 ε-predicate (R7): True iff the relative scale delta
    |cur − prev| / prev ≥ FLORA_EMIT_EPS, where prev is the last EMITTED
    scale (always > 0 by the contract's scale > 0 validation). Pure — unit
    tested directly by test_flora_growth."""
    if prev_scale <= 0.0:
        return cur_scale != prev_scale
    var d = cur_scale - prev_scale
    if d < 0.0:
        d = -d
    return d >= FLORA_EMIT_EPS * prev_scale


def anchor_cell_of(x: Float32, z: Float32) -> Tuple[Int, Int]:
    """Inverse of instance_for_column's world→cell mapping (exact lattice,
    f32 rounding absorbed by the +0.5 floor)."""
    var ix = Int(floor(Float64(x) / CELL_SIZE + Float64(GRID_N) / 2.0 - 0.5 + 0.5))
    var iz = Int(floor(Float64(z) / CELL_SIZE + Float64(GRID_N) / 2.0 - 0.5 + 0.5))
    return (ix, iz)


def feature_for_column(
    x: Int, z: Int, biome: Int, slope: Float64, height: Float64, seed: UInt32
) -> UInt32:
    """Pure placement function: (x, z, biome, slope, height, seed) → species
    or SPECIES_NONE (0006 §1.1 locked decision — integer hash over
    (seed, x, z) gated by the band table; no RNG stream).

    Band table (parameters.mojo / 0006 §1.1):
      BEACH          → palm (cluster/solo),   density FLORA_DENSITY_BEACH
      VOLCANIC_SLOPE → canopy/shrub/fern,     density FLORA_DENSITY_SLOPE
      CALDERA_RIM / CALDERA_LAKE / SHALLOW_WATER / DEEP_OCEAN / any other
                     → NONE
    Elevation: height ≥ SEA_LEVEL + FLORA_HEIGHT_EPS; slope ≤ band cap."""
    if height < SEA_LEVEL + FLORA_HEIGHT_EPS:
        return SPECIES_NONE
    if biome == BIOME_BEACH:
        if slope > FLORA_BEACH_SLOPE_CAP:
            return SPECIES_NONE
        if hash01_cells(seed, x, z, _SALT_DENSITY) >= FLORA_DENSITY_BEACH:
            return SPECIES_NONE
        if hash01_cells(seed, x, z, _SALT_SPECIES) < FLORA_WEIGHT_PALM_CLUSTER:
            return SPECIES_PALM_CLUSTER
        return SPECIES_PALM_SOLO
    if biome == BIOME_VOLCANIC_SLOPE:
        if slope > FLORA_SLOPE_CAP:
            return SPECIES_NONE
        if hash01_cells(seed, x, z, _SALT_DENSITY) >= FLORA_DENSITY_SLOPE:
            return SPECIES_NONE
        var u = hash01_cells(seed, x, z, _SALT_SPECIES)
        if u < FLORA_WEIGHT_CANOPY_TREE:
            return SPECIES_CANOPY_TREE
        u -= FLORA_WEIGHT_CANOPY_TREE
        if u < FLORA_WEIGHT_CANOPY_CLUSTER:
            return SPECIES_CANOPY_CLUSTER
        u -= FLORA_WEIGHT_CANOPY_CLUSTER
        if u < FLORA_WEIGHT_SHRUB:
            return SPECIES_SHRUB
        return SPECIES_FERN_CARPET
    # CALDERA_RIM / CALDERA_LAKE / SHALLOW_WATER / DEEP_OCEAN / jungle rows
    # (unused by the volcanic profile) → no flora.
    return SPECIES_NONE


def instance_for_column(
    x: Int, z: Int, biome: Int, slope: Float64, height: Float64, seed: UInt32
) -> FloraInstance:
    """One anchor cell → one FloraInstance (position y = surface height at
    the anchor cell; yaw/scale from pure hashes), or the SPECIES_NONE marker
    (species_id == SPECIES_NONE, never emitted)."""
    var species = feature_for_column(x, z, biome, slope, height, seed)
    var inst = FloraInstance()
    inst.species_id = species
    if species == SPECIES_NONE:
        return inst^
    var wx = (Float64(x) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
    var wz = (Float64(z) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
    var yaw = hash01_cells(seed, x, z, _SALT_YAW) * TWO_PI
    inst.x = Float32(wx)
    inst.y = Float32(height)
    inst.z = Float32(wz)
    inst.yaw = Float32(yaw)
    # Initial scale = establishment scale s0 (0009 R3): growth curve at
    # age = a0 is exactly s0, so the seed-1 tick-1 wire bytes stay those of
    # the 0006 scatter (golden fixture byte-neutrality, Sprint 03 owns
    # regen). Same hash expression as the 0006 code path.
    var su = hash01_cells(seed, x, z, _SALT_SCALE)
    inst.scale = Float32(FLORA_SCALE_MIN + su * (FLORA_SCALE_MAX - FLORA_SCALE_MIN))
    return inst^


struct FloraSubject(Movable, Deinitable):
    """Explicit flora population (ECOLOGY-INV-003): membership = the instance
    list; construction is a pure function of (seed, island, environment).
    Count is capped at FLORA_N_MAX (0006 AP-13).

    `ages` is the SIM-SIDE per-instance ecological clock (0009 R2/R3),
    parallel to `instances` (ages[i] ↔ instances[i]; ages[i] ≤ 0 is the
    established-immediately sentinel, normal start value 0). It is NOT part
    of the 24 B wire record (snapshot/types.mojo untouched — layout
    neutrality invariant); it folds into the projection fingerprint hash
    instead (world.mojo). Rebuilt by flora_from_island / flora_re_evaluate,
    incremented by flora_tick.

    `traits` is the SIM-SIDE per-instance trait vector (0009 Sprint 02 /
    R1), parallel to `instances` (traits[i] ↔ instances[i]) — same layout-
    neutrality rule as `ages` (never serialized; folded into the world
    fingerprint). Written once at establishment (pure hash of the anchor
    cell), never mutated afterwards (trivial inheritance, INV-006/007),
    read by the survival pass each tick and copied by survivor re-scans.

    `stages` (0010 Sprint 01, R1/R4) is the SIM-SIDE developmental stage per
    instance — stage_for_age(species, ages[i]), recomputed once per fixed
    tick inside flora_tick (tick phase), 0..STAGE_MAX, monotone in age
    (invariant 5). `variant_seeds` (0010 R2) is the per-instance generative
    identity — pure hash of (seed, anchor cell), written at establishment,
    constant over the instance's life. BOTH are parallel to `instances`,
    SIM-SIDE ONLY, never on the 24 B wire (layout neutrality — the wire
    record gains them in Sprint 02, schema 7); folded into the world
    fingerprint instead, and both join the FLORA emission-dirty rule
    (runtime.mojo, R7)."""

    var seed: UInt32
    var count: Int  # == len(instances) == len(ages) == len(traits) == len(stages)
    #                              == len(variant_seeds) — cap oracle
    var instances: List[FloraInstance]
    var ages: List[Int]  # SIM-SIDE only (parallel to instances)
    var traits: List[FloraTraits]  # SIM-SIDE only (parallel to instances)
    var stages: List[Int]  # SIM-SIDE only (0010; parallel to instances)
    var variant_seeds: List[UInt32]  # SIM-SIDE only (0010; parallel)

    def __init__(out self):
        self.seed = 0
        self.count = 0
        self.instances = List[FloraInstance]()
        self.ages = List[Int]()
        self.traits = List[FloraTraits]()
        self.stages = List[Int]()
        self.variant_seeds = List[UInt32]()

    def __deinit__(deinit self):
        pass


def cell_world_x(ix: Int) -> Float64:
    """World-frame x of the cell centre (§801 lattice mapping)."""
    return (Float64(ix) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE


def cell_world_z(iz: Int) -> Float64:
    """World-frame z of the cell centre (§801 lattice mapping)."""
    return (Float64(iz) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE


def flora_establishes(
    x: Int,
    z: Int,
    biome: Int,
    slope: Float64,
    height: Float64,
    wetness: Float64,
    crater_x: Float64,
    crater_z: Float64,
    seed: UInt32,
) -> Bool:
    """Establishment decision for one candidate cell — the SINGLE predicate
    shared by flora_from_island and flora_re_evaluate (0009 R2; spec §6
    invariant 4), so a full re-scan from an empty subject reproduces the
    pristine population exactly:

      1. field gate: establishment_suitability(…) ≥ FLORA_SUITABILITY_THRESHOLD
         (band preconditions + density propensity + weighted-stress env);
      2. selection gate (EVOLUTION-INV-005): flora_selection_passes against
         the cell's traits and its local stress at the DECLARED environment
         inputs (wetness, crater position — explicit, EVOLUTION-INV-011).

    Pure: same inputs ⇒ same verdict (INV-018 / AP-20)."""
    var dist = sqrt(
        (cell_world_x(x) - crater_x) * (cell_world_x(x) - crater_x)
        + (cell_world_z(z) - crater_z) * (cell_world_z(z) - crater_z)
    )
    var ash_raw = flora_ash_stress(dist)
    var suit = establishment_suitability(
        x, z, biome, slope, height, wetness, ash_raw, seed
    )
    if suit < FLORA_SUITABILITY_THRESHOLD:
        return False
    return flora_selection_passes(
        flora_traits(seed, x, z), ash_raw, flora_drought_stress(wetness)
    )


def flora_from_island(
    island: IslandSubject,
    seed: UInt32,
    crater_x: Float64,
    crater_z: Float64,
    wetness: Float64,
) raises -> FloraSubject:
    """Scan every column in deterministic row-major order (iz, ix) and keep
    the instances that PASS full establishment (band + field threshold +
    trait selection — flora_establishes). No world mutation beyond subject
    state (0006 Sprint 01). Initial ages come from the pure (seed, x, z)
    hash over [0, maturity] (0009 R2 — mixed age structure at t=0, no
    mutable RNG stream); traits from the pure (seed, cell, trait_salt)
    hashes (0009 R1). crater_x/crater_z/wetness are the declared
    environmental inputs at establishment time (EVOLUTION-INV-011) — passed
    explicitly by world.mojo, never hidden state."""
    var flora = FloraSubject()
    flora.seed = seed
    for iz in range(GRID_N):
        for ix in range(GRID_N):
            if flora.count >= FLORA_N_MAX:
                return flora^
            var i = iz * GRID_N + ix
            var slope = cell_slope(island.heights, ix, iz)
            if not flora_establishes(
                ix,
                iz,
                island.biomes[i],
                slope,
                island.heights[i],
                wetness,
                crater_x,
                crater_z,
                seed,
            ):
                continue
            var inst = instance_for_column(
                ix, iz, island.biomes[i], slope, island.heights[i], seed
            )
            if inst.species_id == SPECIES_NONE:
                continue
            var age = flora_initial_age(seed, ix, iz, inst.species_id)
            flora.instances.append(inst)
            flora.ages.append(age)
            flora.traits.append(flora_traits(seed, ix, iz))
            # 0010 Sprint 01: developmental stage from the establishment age
            # (recomputed each tick in flora_tick); variant_seed from the
            # pure (seed, cell) hash — both SIM-side parallel lists.
            flora.stages.append(stage_for_age(inst.species_id, age))
            flora.variant_seeds.append(variant_seed(seed, ix, iz))
            flora.count += 1
    return flora^


def flora_species_counts(flora: FloraSubject) -> List[Int]:
    """Population composition (ECOLOGY §9): instance count per species id."""
    var out = List[Int]()
    for _ in range(8):
        out.append(0)
    for i in range(flora.count):
        var sid = Int(flora.instances[i].species_id)
        if sid >= 0 and sid < len(out):
            out[sid] = out[sid] + 1
    return out^


def flora_tick(mut flora: FloraSubject):
    """One per-tick growth commit (0009 R2/R3; called from sim/world.mojo
    tick phase only — projection purity). For every instance:
      1. ages[i] += 1 (never decreases; saturation lives in the curve);
      2. recompute s0 / a0 from their PURE (seed, anchor-cell) hashes
         (nothing to store — AP-20);
      3. snap the stored scale UP to the curve value only when the relative
         distance reaches FLORA_EMIT_EPS (ε-quantization: the stored scale
         changes ⇔ emission can fire, so dirty ⇔ change; never snap down).
    Pure function of current state + seed — deterministic, order-independent
    (0009 R1/R8)."""
    for i in range(flora.count):
        var inst = flora.instances[i]
        if inst.species_id == SPECIES_NONE:
            continue
        var age = flora.ages[i] + 1
        flora.ages[i] = age
        # 0010 R4/R5: stage advance happens HERE — once per fixed tick, tick
        # phase only (called from world.mojo). Monotone by stage_for_age
        # (age never decreases); variant_seed is constant over the life.
        if i < len(flora.stages):
            flora.stages[i] = stage_for_age(inst.species_id, age)
        var anchor = anchor_cell_of(inst.x, inst.z)
        var s0 = flora_anchor_scale(flora.seed, anchor[0], anchor[1])
        var a0 = flora_initial_age(
            flora.seed, anchor[0], anchor[1], inst.species_id
        )
        var f = flora_scale_for_age(inst.species_id, s0, a0, age)
        var cur = Float64(inst.scale)
        if f - cur >= FLORA_EMIT_EPS * cur:
            inst.scale = Float32(f)
            flora.instances[i] = inst


def flora_re_evaluate(
    island: IslandSubject,
    prev: FloraSubject,
    seed: UInt32,
    crater_x: Float64,
    crater_z: Float64,
    wetness: Float64,
) raises -> FloraSubject:
    """Full row-major re-scan after an edit pipeline commit (applies edits,
    not field scans — 0009 §2 edit hook; called ONLY in the tick phase).

    Establishment decision = flora_establishes (field threshold + trait
    selection) at the DECLARED environmental inputs crater_x/crater_z/
    wetness (EVOLUTION-INV-011 — world.mojo passes the committed volcano
    center and weather wetness; identical inputs ⇒ identical population as
    flora_from_island). Survivors (same anchor cell AND same species as
    `prev`) keep their age, grown scale and stored trait vector — no
    re-establishment restart; new establishments start at age a0 with scale
    s0 and fresh cell-hash traits; instances failing establishment drop this
    same pass (death in the tick phase, spec §6 invariant 7). Rescan
    strategy: 3 × GRID_N² index maps (cell → prev instance index / species /
    age) give O(N) survivor lookup; full rescan cost was measured in
    test_flora_growth (see runtime comment there).

    Deterministic: row-major scan, pure hashes only (0009 R1/R8 / INV-018).
    Note: the edit hook runs BEFORE this tick's weather commit (world.mojo
    tick order), so `wetness` is the previously committed weather state —
    still an explicit declared input, never derived inside this function."""
    comptime CELLS = GRID_N * GRID_N
    # Build the survivor lookup from prev (i + 1; 0 = absent).
    var prev_idx = List[Int]()
    for _ in range(CELLS):
        prev_idx.append(-1)
    for i in range(prev.count):
        var inst = prev.instances[i]
        if inst.species_id == SPECIES_NONE:
            continue
        var c = anchor_cell_of(inst.x, inst.z)
        if c[0] >= 0 and c[0] < GRID_N and c[1] >= 0 and c[1] < GRID_N:
            prev_idx[c[1] * GRID_N + c[0]] = i

    var out = FloraSubject()
    out.seed = seed
    for iz in range(GRID_N):
        for ix in range(GRID_N):
            if out.count >= FLORA_N_MAX:
                return out^
            var ci = iz * GRID_N + ix
            var slope = cell_slope(island.heights, ix, iz)
            var height = island.heights[ci]
            if not flora_establishes(
                ix,
                iz,
                island.biomes[ci],
                slope,
                height,
                wetness,
                crater_x,
                crater_z,
                seed,
            ):
                continue
            var species = feature_for_column(
                ix, iz, island.biomes[ci], slope, height, seed
            )
            if species == SPECIES_NONE:
                continue
            var pi = prev_idx[ci]
            if (
                pi >= 0
                and prev.instances[pi].species_id == species
                and height >= Float64(prev.instances[pi].y) - 1.0e-4
            ):
                # Survivor: same cell, same species, anchor voxel intact
                # (height not lowered below the establishment surface ⇒ no
                # voxel removed). Keep grown scale + accumulated age + the
                # stored trait vector (traits are cell-hash constant anyway);
                # pose y follows the current surface (edit may have raised it).
                var kept = prev.instances[pi]
                kept.y = Float32(height)
                out.instances.append(kept)
                out.ages.append(prev.ages[pi])
                if pi < len(prev.traits):
                    out.traits.append(prev.traits[pi])
                else:
                    out.traits.append(flora_traits(seed, ix, iz))
                # 0010: stage re-derived from the kept age (pure — same value
                # as the copied one, self-healing if the list were short);
                # variant_seed re-derived from the same (seed, cell) hash.
                out.stages.append(stage_for_age(species, prev.ages[pi]))
                out.variant_seeds.append(variant_seed(seed, ix, iz))
            else:
                # Anchor voxel removed ⇒ dies same tick (0009 R5); the freed
                # cell may establish fresh in this same scan (new plant:
                # scale s0, age a0). Also covers brand-new valid cells and
                # species changes.
                var new_age = flora_initial_age(seed, ix, iz, species)
                out.instances.append(
                    instance_for_column(
                        ix, iz, island.biomes[ci], slope, height, seed
                    )
                )
                out.ages.append(new_age)
                out.traits.append(flora_traits(seed, ix, iz))
                out.stages.append(stage_for_age(species, new_age))
                out.variant_seeds.append(variant_seed(seed, ix, iz))
            out.count += 1
    return out^


def flora_survival(
    mut flora: FloraSubject,
    crater_x: Float64,
    crater_z: Float64,
    wetness: Float64,
) raises:
    """Survival selection pass (0009 R3 / EVOLUTION-INV-005; called from
    sim/world.mojo TICK phase only — projection purity, spec §6 invariant 7).

    For every instance, recompute its local stress from the COMMITTED
    environment (crater position = static volcano geometry, wetness = this
    tick's weather state — both explicit inputs, EVOLUTION-INV-011) and its
    stored trait vector:
      dies iff NOT flora_selection_passes(traits, ash_raw, drought_raw)
    — the SAME predicate as establishment selection (one threshold, one
    meaning). Dead instances are removed in this same call, so the count
    can only shrink here: the FLORA_N_MAX cap can never be violated by a
    death wave (AP-22 / spec §6 invariant 5).

    Cost: one pass per tick over the population (≤ FLORA_N_MAX), O(count);
    no amortization needed at this scale (documented choice — full recompute
    every tick, measured against the 16.6 ms budget in the perf probe).

    Determinism: death is a pure function of (instances, traits, crater,
    wetness) — run-twice identical death sets (R6 / EVOLUTION-INV-018), no
    RNG (AP-20), no hidden inputs. Death is absorbing (no re-establishment
    inside the tick phase) ⇒ no hysteresis band required (see
    parameters.mojo). No adaptation: traits are never updated here
    (ECOLOGY-INV-013 firewall)."""
    var kept_i = List[FloraInstance]()
    var kept_a = List[Int]()
    var kept_t = List[FloraTraits]()
    var kept_s = List[Int]()
    var kept_v = List[UInt32]()
    for i in range(flora.count):
        var inst = flora.instances[i]
        var dx = Float64(inst.x) - crater_x
        var dz = Float64(inst.z) - crater_z
        var ash_raw = flora_ash_stress(sqrt(dx * dx + dz * dz))
        var drought_raw = flora_drought_stress(wetness)
        # Trait lookup: the stored SIM-side vector; if the parallel list is
        # short (should never happen — traits are written at establishment),
        # re-derive from the pure cell hash (same value by construction,
        # INV-018). The re-derivation is also the initializer, so the value
        # is used on every path.
        var c = anchor_cell_of(inst.x, inst.z)
        var t = flora_traits(flora.seed, c[0], c[1])
        if i < len(flora.traits):
            t = flora.traits[i]
        if flora_selection_passes(t, ash_raw, drought_raw):
            kept_i.append(inst)
            kept_a.append(flora.ages[i])
            kept_t.append(t)
            # 0010: parallel stage/seed lists survive the death filter —
            # short lists re-derive from the pure functions (INV-018).
            if i < len(flora.stages):
                kept_s.append(flora.stages[i])
            else:
                kept_s.append(stage_for_age(inst.species_id, flora.ages[i]))
            if i < len(flora.variant_seeds):
                kept_v.append(flora.variant_seeds[i])
            else:
                kept_v.append(variant_seed(flora.seed, c[0], c[1]))
    flora.instances = kept_i^
    flora.ages = kept_a^
    flora.traits = kept_t^
    flora.stages = kept_s^
    flora.variant_seeds = kept_v^
    flora.count = len(flora.instances)
