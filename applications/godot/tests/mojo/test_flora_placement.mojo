# Spec test — Flora placement (milestone_0006 §1.1 / §5 / §7, AP-13):
# band invariants (biome/elevation/slope), banned columns empty, cap,
# pure-construction determinism. Headless: runs without Godot.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op.
# Every check below uses `_check`, which raises Error ⇒ TestSuite FAIL.

from std.collections import List
from std.testing import TestSuite
from std.math import floor, abs

from sim.island import build_island, IslandSubject
from sim.flora import (
    flora_from_island,
    cell_slope,
    feature_for_column,
    instance_for_column,
    establishment_suitability,
    FloraSubject,
)
from sim.volcano import volcano_from_island
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
    FLORA_SUITABILITY_THRESHOLD,
    FLORA_WETNESS_NEUTRAL,
    FLORA_CRATER_STRESS_NEUTRAL,
)
from materials.catalog import (
    SPECIES_NONE,
    SPECIES_PALM_CLUSTER,
    SPECIES_PALM_SOLO,
    SPECIES_BAMBOO_GROVE,
    SPECIES_CANOPY_TREE,
    SPECIES_CANOPY_CLUSTER,
    SPECIES_SHRUB,
    SPECIES_FERN_CARPET,
    species_catalog_id_string,
)
from synthesis.voxel import (
    BIOME_BEACH,
    BIOME_VOLCANIC_SLOPE,
    BIOME_COASTAL_JUNGLE,
    BIOME_DENSE_RAINFOREST,
    BIOME_CALDERA_RIM,
    BIOME_CALDERA_LAKE,
    BIOME_LAVA_RIVER,
    BIOME_SHALLOW_WATER,
    BIOME_DEEP_OCEAN,
)
from snapshot.types import FloraInstance


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _env(island: IslandSubject) raises -> Tuple[Float64, Float64, Float64]:
    """Declared environmental inputs for flora_from_island (0009 Sprint 02 /
    EVOLUTION-INV-011): the island's crater (volcano subject centroid) and
    wetness 0.0 — the committed initial weather state (world_init commits
    weather with dt = 0, so wetness starts at 0 and this test never ticks)."""
    var v = volcano_from_island(island)
    return (v.center_x, v.center_z, 0.0)


def _pop(island: IslandSubject, seed: UInt32) raises -> FloraSubject:
    """flora_from_island with the declared environment bound by _env."""
    var e = _env(island)
    return flora_from_island(island, seed, e[0], e[1], e[2])


def anchor_cell(inst: FloraInstance) raises -> Tuple[Int, Int]:
    """Inverse of instance_for_column's world→cell mapping (exact lattice)."""
    var fx = Float64(inst.x) / CELL_SIZE + Float64(GRID_N) / 2.0 - 0.5
    var fz = Float64(inst.z) / CELL_SIZE + Float64(GRID_N) / 2.0 - 0.5
    var ix = Int(floor(fx + 0.5))
    var iz = Int(floor(fz + 0.5))
    # Round-trip: the instance must sit at the anchor cell centre.
    var cx = (Float64(ix) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
    var cz = (Float64(iz) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
    _check(
        abs(cx - Float64(inst.x)) < 1.0e-3,
        "instance x not on cell lattice",
    )
    _check(
        abs(cz - Float64(inst.z)) < 1.0e-3,
        "instance z not on cell lattice",
    )
    _check(ix >= 0 and ix < GRID_N and iz >= 0 and iz < GRID_N, "anchor in grid")
    return (ix, iz)


def test_band_invariants_seed1() raises:
    """0006 §1.1: every instance sits on BEACH or VOLCANIC_SLOPE, above the
    elevation threshold, within its band's slope cap, in the band's species
    set, at the anchor cell height, with scale in [SCALE_MIN, SCALE_MAX]."""
    var island = build_island(1)
    var flora = _pop(island, 1)
    _check(flora.count > 0, "flora instances for seed 1")
    _check(flora.count == len(flora.instances), "count == len(instances)")
    _check(flora.count <= FLORA_N_MAX, "cap: count ≤ FLORA_N_MAX")
    for i in range(flora.count):
        var inst = flora.instances[i]
        var c = anchor_cell(inst)
        var ix = c[0]
        var iz = c[1]
        var gi = iz * GRID_N + ix
        var biome = island.biomes[gi]
        var height = island.heights[gi]
        var slope = cell_slope(island.heights, ix, iz)
        var sid = Int(inst.species_id)
        _check(sid != Int(SPECIES_NONE), "SPECIES_NONE never emitted")
        _check(
            height >= SEA_LEVEL + FLORA_HEIGHT_EPS,
            "elevation band: height ≥ SEA_LEVEL + eps",
        )
        _check(
            abs(Float64(inst.y) - height) < 1.0e-3,
            "y == anchor cell surface height",
        )
        _check(
            Float64(inst.scale) >= FLORA_SCALE_MIN - 1.0e-6
            and Float64(inst.scale) <= FLORA_SCALE_MAX + 1.0e-6,
            "scale within [SCALE_MIN, SCALE_MAX]",
        )
        if biome == BIOME_BEACH:
            _check(
                slope <= FLORA_BEACH_SLOPE_CAP,
                "BEACH slope ≤ band cap",
            )
            _check(
                sid == Int(SPECIES_PALM_CLUSTER) or sid == Int(SPECIES_PALM_SOLO),
                "BEACH band hosts palms only",
            )
        elif biome == BIOME_VOLCANIC_SLOPE:
            _check(
                slope <= FLORA_SLOPE_CAP,
                "VOLCANIC_SLOPE slope ≤ band cap",
            )
            _check(
                sid == Int(SPECIES_CANOPY_TREE)
                or sid == Int(SPECIES_CANOPY_CLUSTER)
                or sid == Int(SPECIES_SHRUB)
                or sid == Int(SPECIES_FERN_CARPET),
                "VOLCANIC_SLOPE band hosts canopy/shrub/fern only",
            )
        else:
            _check(False, "instance on banned biome")


def test_banned_columns_have_no_flora() raises:
    """Band table is total: every column failing the band gates
    (wrong biome, low elevation, over-cap slope) yields SPECIES_NONE."""
    var island = build_island(1)
    for iz in range(GRID_N):
        for ix in range(GRID_N):
            var gi = iz * GRID_N + ix
            var biome = island.biomes[gi]
            var height = island.heights[gi]
            var slope = cell_slope(island.heights, ix, iz)
            var f = feature_for_column(ix, iz, biome, slope, height, 1)
            var banned = (
                biome != BIOME_BEACH and biome != BIOME_VOLCANIC_SLOPE
            )
            if height < SEA_LEVEL + FLORA_HEIGHT_EPS:
                _check(f == SPECIES_NONE, "low elevation hosts no flora")
            elif biome == BIOME_BEACH:
                if slope > FLORA_BEACH_SLOPE_CAP:
                    _check(f == SPECIES_NONE, "BEACH over slope cap → NONE")
            elif biome == BIOME_VOLCANIC_SLOPE:
                if slope > FLORA_SLOPE_CAP:
                    _check(f == SPECIES_NONE, "SLOPE over slope cap → NONE")
            else:
                _check(
                    banned and f == SPECIES_NONE,
                    "banned biome hosts no flora",
                )


def test_flora_construction_is_deterministic() raises:
    """Two constructions from the same (island, seed) are field-identical
    (0006 §6 invariant 4 / §7 determinism exit criterion)."""
    var island = build_island(1)
    var a = _pop(island, 1)
    var b = _pop(island, 1)
    _check(a.count == b.count, "count differs between equal constructions")
    for i in range(a.count):
        var ia = a.instances[i]
        var ib = b.instances[i]
        _check(ia.species_id == ib.species_id, "species mismatch")
        _check(ia.x == ib.x and ia.y == ib.y and ia.z == ib.z, "position mismatch")
        _check(ia.yaw == ib.yaw and ia.scale == ib.scale, "pose mismatch")


def test_different_seed_changes_population() raises:
    """Seed is part of the placement function (0006 §1.1)."""
    var island = build_island(1)
    var a = _pop(island, 1)
    var b = _pop(island, 2)
    var differs = a.count != b.count
    if not differs:
        for i in range(a.count):
            if a.instances[i].species_id != b.instances[i].species_id:
                differs = True
                break
    _check(differs, "seed must change the flora population")


def test_species_enum_total_and_bounded() raises:
    """Emitting species ids stay inside 1..SPECIES_COUNT-1 and map through
    instance_for_column as the single source (AP-14 companion)."""
    var island = build_island(1)
    var flora = _pop(island, 1)
    for i in range(flora.count):
        var sid = Int(flora.instances[i].species_id)
        _check(sid >= 1 and sid <= 7, "species id in 1..7")
        # Bamboo (3) is not placed by this profile's band table — if it ever
        # appears, the band table changed and this test must be revisited.
        _check(sid != Int(SPECIES_BAMBOO_GROVE), "bamboo not in band table")
    # Recompute one column end-to-end as the oracle.
    var checked = False
    for iz in range(GRID_N):
        if checked:
            break
        for ix in range(GRID_N):
            var gi = iz * GRID_N + ix
            var slope = cell_slope(island.heights, ix, iz)
            var inst = instance_for_column(
                ix, iz, island.biomes[gi], slope, island.heights[gi], 1
            )
            if inst.species_id != SPECIES_NONE:
                _check(
                    Int(inst.species_id) >= 1 and Int(inst.species_id) <= 7,
                    "instance_for_column emits 1..7",
                )
                checked = True
                break
    _check(checked, "seed 1 has at least one host column")


def test_field_suitability_oracle_seed1() raises:
    """0009 R1/§5 (Sprint 01 gate): every establishment implies the band
    preconditions AND `establishment_suitability ≥ FLORA_SUITABILITY_THRESHOLD`;
    suitability ∈ [0, 1] everywhere; emitted species resolve through
    species_catalog_id_string (0006 AP-14 catalog resolution retained)."""
    var island = build_island(1)
    var checked = False
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
                1,
            )
            _check(suit >= 0.0 and suit <= 1.0, "suitability ∈ [0, 1]")
            var species = feature_for_column(
                ix, iz, island.biomes[ci], slope, height, 1
            )
            if species == SPECIES_NONE:
                continue
            # Establishment ⇒ band + suit ≥ threshold.
            _check(
                height >= SEA_LEVEL + FLORA_HEIGHT_EPS,
                "establishment implies height band",
            )
            if island.biomes[ci] == BIOME_BEACH:
                _check(slope <= FLORA_BEACH_SLOPE_CAP, "beach slope ≤ cap")
                _check(
                    species == SPECIES_PALM_CLUSTER
                    or species == SPECIES_PALM_SOLO,
                    "beach band hosts palms only",
                )
            elif island.biomes[ci] == BIOME_VOLCANIC_SLOPE:
                _check(slope <= FLORA_SLOPE_CAP, "slope ≤ cap")
                _check(
                    species == SPECIES_CANOPY_TREE
                    or species == SPECIES_CANOPY_CLUSTER
                    or species == SPECIES_SHRUB
                    or species == SPECIES_FERN_CARPET,
                    "slope band hosts canopy/shrub/fern only",
                )
            else:
                _check(False, "establishment on banned biome")
            _check(
                suit >= FLORA_SUITABILITY_THRESHOLD,
                "establishment implies suitability ≥ threshold",
            )
            # Catalog resolution retained (0006 AP-14): species → catalog id
            # must yield exactly one non-empty id, no raise for 1..7.
            var cid = species_catalog_id_string(species)
            _check(cid.byte_length() > 0, "species resolves to a catalog id")
            checked = True
    _check(checked, "seed 1 has at least one establishment to oracle")


def main() raises:
    TestSuite.discover_tests[
        (
            test_band_invariants_seed1,
            test_banned_columns_have_no_flora,
            test_flora_construction_is_deterministic,
            test_different_seed_changes_population,
            test_species_enum_total_and_bounded,
            test_field_suitability_oracle_seed1,
        )
    ]().run()
