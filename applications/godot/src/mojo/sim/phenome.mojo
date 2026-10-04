# Phenome core (milestone_0010 Sprint 01) — SIM-SIDE, PURE functions only:
# stage quantization, variant_seed hash, trait → grammar-parameter map.
#
# Meaning sources (Rule 10 / AP-23 — this file implements, never defines):
#   lib/401_Morphology/Procedural  — grammar/stage derivation semantics
#   lib/704_Evolution/Phenotype    — genotype → phenotype map (INV-004/011)
#   lib/705_Ecology/Flora §1.6     — stage is developmental, from age
#   milestone_0010 spec §1.1/§6    — stage model, modulation exactness
# Single-source grammar data lives in godot/data/phenome_grammars.json; the
# PHENOME_* constants in sim/parameters.mojo are MIRRORS conformance-tested
# against that file (R3, AP-3). Nothing here expands grammars per tick
# (reference expander lives in phenome/expand.mojo and runs in tests only).
#
# Determinism: every function is a pure function of its arguments — integer
# hashes only, no mutable RNG stream (AP-20), order-independent (INV-018).
# Stage advances once per fixed tick in the tick phase (world.mojo calls
# flora_tick; R4); projection reads the state read-only (fingerprint folded).

from std.math import floor

from sim.parameters import (
    STAGE_MAX,
    PHENOME_STAGE_COUNT,
    PHENOME_TRAIT_QUANT,
    PHENOME_VARIANT_SALT,
    FLORA_MATURITY_PALM_CLUSTER,
    FLORA_MATURITY_PALM_SOLO,
    FLORA_MATURITY_BAMBOO_GROVE,
    FLORA_MATURITY_CANOPY_TREE,
    FLORA_MATURITY_CANOPY_CLUSTER,
    FLORA_MATURITY_SHRUB,
    FLORA_MATURITY_FERN_CARPET,
    PHENOME_PARAM_CROWN_PALM_CLUSTER,
    PHENOME_PARAM_CROWN_PALM_SOLO,
    PHENOME_PARAM_CROWN_BAMBOO_GROVE,
    PHENOME_PARAM_CROWN_CANOPY_TREE,
    PHENOME_PARAM_CROWN_CANOPY_CLUSTER,
    PHENOME_PARAM_CROWN_SHRUB,
    PHENOME_PARAM_CROWN_FERN_CARPET,
    PHENOME_PARAM_LEAF_PALM_CLUSTER,
    PHENOME_PARAM_LEAF_PALM_SOLO,
    PHENOME_PARAM_LEAF_BAMBOO_GROVE,
    PHENOME_PARAM_LEAF_CANOPY_TREE,
    PHENOME_PARAM_LEAF_CANOPY_CLUSTER,
    PHENOME_PARAM_LEAF_SHRUB,
    PHENOME_PARAM_LEAF_FERN_CARPET,
    PHENOME_MOD_DELTA_ASH_CROWN_PALM_CLUSTER,
    PHENOME_MOD_DELTA_ASH_CROWN_PALM_SOLO,
    PHENOME_MOD_DELTA_ASH_CROWN_BAMBOO_GROVE,
    PHENOME_MOD_DELTA_ASH_CROWN_CANOPY_TREE,
    PHENOME_MOD_DELTA_ASH_CROWN_CANOPY_CLUSTER,
    PHENOME_MOD_DELTA_ASH_CROWN_SHRUB,
    PHENOME_MOD_DELTA_ASH_CROWN_FERN_CARPET,
    PHENOME_MOD_DELTA_DROUGHT_LEAF_PALM_CLUSTER,
    PHENOME_MOD_DELTA_DROUGHT_LEAF_PALM_SOLO,
    PHENOME_MOD_DELTA_DROUGHT_LEAF_BAMBOO_GROVE,
    PHENOME_MOD_DELTA_DROUGHT_LEAF_CANOPY_TREE,
    PHENOME_MOD_DELTA_DROUGHT_LEAF_CANOPY_CLUSTER,
    PHENOME_MOD_DELTA_DROUGHT_LEAF_SHRUB,
    PHENOME_MOD_DELTA_DROUGHT_LEAF_FERN_CARPET,
)
from materials.catalog import (
    SPECIES_PALM_CLUSTER,
    SPECIES_PALM_SOLO,
    SPECIES_BAMBOO_GROVE,
    SPECIES_CANOPY_TREE,
    SPECIES_CANOPY_CLUSTER,
    SPECIES_SHRUB,
    SPECIES_FERN_CARPET,
)
from synthesis.noise import hash64_cells

# Trait-vector indices consumed by the modulation map (0009 trait order;
# slots 2..3 reserved — unused until those traits exist).
comptime PHENOME_TRAIT_INDEX_ASH: Int = 0
comptime PHENOME_TRAIT_INDEX_DROUGHT: Int = 1


def phenome_maturity_ticks(species: UInt32) -> Int:
    """Per-species maturity (ticks) — mirror of the FLORA_MATURITY_* family,
    duplicated as a dependency-free lookup so sim/phenome.mojo does not
    import sim/flora.mojo (flora imports this module; no cycles). Value ==
    JSON `maturity[STAGE_MAX]` for the species (conformance-tested)."""
    if species == SPECIES_PALM_CLUSTER:
        return FLORA_MATURITY_PALM_CLUSTER
    if species == SPECIES_PALM_SOLO:
        return FLORA_MATURITY_PALM_SOLO
    if species == SPECIES_BAMBOO_GROVE:
        return FLORA_MATURITY_BAMBOO_GROVE
    if species == SPECIES_CANOPY_TREE:
        return FLORA_MATURITY_CANOPY_TREE
    if species == SPECIES_CANOPY_CLUSTER:
        return FLORA_MATURITY_CANOPY_CLUSTER
    if species == SPECIES_SHRUB:
        return FLORA_MATURITY_SHRUB
    if species == SPECIES_FERN_CARPET:
        return FLORA_MATURITY_FERN_CARPET
    return FLORA_MATURITY_FERN_CARPET


def stage_for_age(species: UInt32, age: Int) -> Int:
    """Developmental stage quantized from age (spec §1.1 stage model; R1):
      stage = min(STAGE_MAX, floor(age * STAGE_MAX / maturity(species)))
    Properties (invariant 5, conformance-tested in test_phenome_grammar):
      pure; 0 ≤ stage ≤ STAGE_MAX; monotone non-decreasing in age;
      stage == 0 at age ≤ 0; stage == STAGE_MAX at age ≥ maturity;
      equals max{ s : json.maturity[s] ≤ age } — the JSON stage table
      (every maturity is STAGE_MAX-divisible, so the quantization
      boundaries are exactly the table rows)."""
    var m = phenome_maturity_ticks(species)
    if m <= 0 or age <= 0:
        return 0
    var s = (age * STAGE_MAX) // m
    if s < 0:
        s = 0
    if s > STAGE_MAX:
        s = STAGE_MAX
    return s


def variant_seed(seed: UInt32, x: Int, z: Int) -> UInt32:
    """Explicit generative identity of one plant (R2 / invariant 2): a pure
    hash of (world seed, anchor cell) salted with PHENOME_VARIANT_SALT —
    order-independent, no RNG stream (AP-20), stable over the instance's
    life (re-establishment at the same cell re-derives the same value).
    Distinct cells ⇒ distinct draws (collision behavior is the hash's;
    test_phenome_grammar measures distinctness over the full 64×64 grid)."""
    var h = hash64_cells(seed, x, z, PHENOME_VARIANT_SALT)
    return UInt32(h & 0xFFFFFFFF)


def trait_quantize(value: Float64) -> Int:
    """Trait → integer milli-value (JSON `trait_quant`, AP-24 exactness):
      trait_milli = clamp(floor(value * PHENOME_TRAIT_QUANT), 0, QUANT).
    Negative or ≥ 1.0 draws clamp to the [0, 1000] band; pure."""
    var q = Int(floor(value * Float64(PHENOME_TRAIT_QUANT)))
    if q < 0:
        q = 0
    if q > PHENOME_TRAIT_QUANT:
        q = PHENOME_TRAIT_QUANT
    return q


def phenome_param_crown(species: UInt32) -> Int:
    """Base crown_density (JSON `params.crown_density`) — mirror."""
    if species == SPECIES_PALM_CLUSTER:
        return PHENOME_PARAM_CROWN_PALM_CLUSTER
    if species == SPECIES_PALM_SOLO:
        return PHENOME_PARAM_CROWN_PALM_SOLO
    if species == SPECIES_BAMBOO_GROVE:
        return PHENOME_PARAM_CROWN_BAMBOO_GROVE
    if species == SPECIES_CANOPY_TREE:
        return PHENOME_PARAM_CROWN_CANOPY_TREE
    if species == SPECIES_CANOPY_CLUSTER:
        return PHENOME_PARAM_CROWN_CANOPY_CLUSTER
    if species == SPECIES_SHRUB:
        return PHENOME_PARAM_CROWN_SHRUB
    if species == SPECIES_FERN_CARPET:
        return PHENOME_PARAM_CROWN_FERN_CARPET
    return PHENOME_PARAM_CROWN_FERN_CARPET


def phenome_param_leaf(species: UInt32) -> Int:
    """Base leaf_count (JSON `params.leaf_count`) — mirror."""
    if species == SPECIES_PALM_CLUSTER:
        return PHENOME_PARAM_LEAF_PALM_CLUSTER
    if species == SPECIES_PALM_SOLO:
        return PHENOME_PARAM_LEAF_PALM_SOLO
    if species == SPECIES_BAMBOO_GROVE:
        return PHENOME_PARAM_LEAF_BAMBOO_GROVE
    if species == SPECIES_CANOPY_TREE:
        return PHENOME_PARAM_LEAF_CANOPY_TREE
    if species == SPECIES_CANOPY_CLUSTER:
        return PHENOME_PARAM_LEAF_CANOPY_CLUSTER
    if species == SPECIES_SHRUB:
        return PHENOME_PARAM_LEAF_SHRUB
    if species == SPECIES_FERN_CARPET:
        return PHENOME_PARAM_LEAF_FERN_CARPET
    return PHENOME_PARAM_LEAF_FERN_CARPET


def phenome_mod_delta(species: UInt32, trait_index: Int) -> Int:
    """Modulation delta for (species, trait) — mirror of the JSON
    `modulation` map (R3):
      trait_index 0 = ash_tolerance    → crown_density (delta …_ASH_CROWN_…)
      trait_index 1 = drought_tolerance → leaf_count   (delta …_DROUGHT_LEAF_…)
    Reserved trait slots have no map entry (return 0 = no effect)."""
    if trait_index == PHENOME_TRAIT_INDEX_ASH:
        if species == SPECIES_PALM_CLUSTER:
            return PHENOME_MOD_DELTA_ASH_CROWN_PALM_CLUSTER
        if species == SPECIES_PALM_SOLO:
            return PHENOME_MOD_DELTA_ASH_CROWN_PALM_SOLO
        if species == SPECIES_BAMBOO_GROVE:
            return PHENOME_MOD_DELTA_ASH_CROWN_BAMBOO_GROVE
        if species == SPECIES_CANOPY_TREE:
            return PHENOME_MOD_DELTA_ASH_CROWN_CANOPY_TREE
        if species == SPECIES_CANOPY_CLUSTER:
            return PHENOME_MOD_DELTA_ASH_CROWN_CANOPY_CLUSTER
        if species == SPECIES_SHRUB:
            return PHENOME_MOD_DELTA_ASH_CROWN_SHRUB
        if species == SPECIES_FERN_CARPET:
            return PHENOME_MOD_DELTA_ASH_CROWN_FERN_CARPET
        return 0
    if trait_index == PHENOME_TRAIT_INDEX_DROUGHT:
        if species == SPECIES_PALM_CLUSTER:
            return PHENOME_MOD_DELTA_DROUGHT_LEAF_PALM_CLUSTER
        if species == SPECIES_PALM_SOLO:
            return PHENOME_MOD_DELTA_DROUGHT_LEAF_PALM_SOLO
        if species == SPECIES_BAMBOO_GROVE:
            return PHENOME_MOD_DELTA_DROUGHT_LEAF_BAMBOO_GROVE
        if species == SPECIES_CANOPY_TREE:
            return PHENOME_MOD_DELTA_DROUGHT_LEAF_CANOPY_TREE
        if species == SPECIES_CANOPY_CLUSTER:
            return PHENOME_MOD_DELTA_DROUGHT_LEAF_CANOPY_CLUSTER
        if species == SPECIES_SHRUB:
            return PHENOME_MOD_DELTA_DROUGHT_LEAF_SHRUB
        if species == SPECIES_FERN_CARPET:
            return PHENOME_MOD_DELTA_DROUGHT_LEAF_FERN_CARPET
        return 0
    return 0


struct PhenomeParams(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Modulated grammar parameters in MILLI-units (value × 1000) so the
    map is integer-exact (AP-24 — no float in the conformance axis).
    value = milli / 1000. SIM-side only this sprint (never on the wire)."""

    var crown_density_milli: Int
    var leaf_count_milli: Int

    def __init__(out self, crown_milli: Int, leaf_milli: Int):
        self.crown_density_milli = crown_milli
        self.leaf_count_milli = leaf_milli

    def __deinit__(deinit self):
        pass


def phenome_modulate(
    species: UInt32, ash_tolerance: Float64, drought_tolerance: Float64
) -> PhenomeParams:
    """Genotype → phenotype map (R3 / invariant 4; lib/704_Evolution/
    Phenotype): trait → declared grammar-parameter shift, exact:

      ash_milli     = clamp(floor(ash · 1000), 0, 1000)
      drought_milli = clamp(floor(drought · 1000), 0, 1000)
      crown_milli   = crown_base·1000 + delta(ash)·ash_milli
      leaf_milli    = leaf_base·1000  + delta(drought)·drought_milli

    Pure, deterministic (AP-20/INV-018); tolerant traits push the declared
    parameter UP for crown density and DOWN for leaf count (drought deltas
    are negative — see parameters.mojo). Selection (704) and growth
    (Morphology) meanings unchanged — this maps FORM only (INV-013)."""
    var ash_milli = trait_quantize(ash_tolerance)
    var dry_milli = trait_quantize(drought_tolerance)
    var crown = phenome_param_crown(species) * PHENOME_TRAIT_QUANT
    crown += phenome_mod_delta(species, PHENOME_TRAIT_INDEX_ASH) * ash_milli
    var leaf = phenome_param_leaf(species) * PHENOME_TRAIT_QUANT
    leaf += phenome_mod_delta(species, PHENOME_TRAIT_INDEX_DROUGHT) * dry_milli
    return PhenomeParams(crown, leaf)
