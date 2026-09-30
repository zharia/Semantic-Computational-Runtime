# FloraSubject — deterministic flora scatter (milestone_0006 Sprint 01;
# SCR-LIB-ECOLOGY §1/§3/§9/§43 and 601_Agent are spec-only contracts —
# implemented here in Mojo per definition: explicit population membership,
# explicit environment (band conditions), declared + test-verified determinism).
#
# Placement locus (0006 §1.1 locked decision): FloraSubject in the SIM. The
# lattice columns keep FEATURE_NONE (voxel-object realization stays disabled —
# recorded deviation from Synthesis §3, 0006 §4); instances are emitted as the
# §10 FLORA section and rendered as MultiMesh transforms. Godot never places,
# counts or scales ecology (0006 AP-11).
#
# feature_for_column is a PURE function: an integer hash over (seed, x, z)
# gated by the band table — no mutable RNG stream, order-independent
# (0006 §1.1 / §6 invariant 4). Band table + all tunables live in
# sim/parameters.mojo (AP-7); species → catalog material lives in
# materials/catalog.mojo (0006 AP-14).
#
# Species vocabulary = Synthesis §3 FeatureTile flora rows (PALM/BAMBOO/
# CANOPY/SHRUB/FERN); the enum values live in materials/catalog.mojo so the
# species → catalog table and the enum stay single-sourced.
#
# Subject state mutation is confined to world_init (construction); the
# snapshot projection reads it read-only (projection purity, 0006 §6.8).

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

comptime TWO_PI: Float64 = 6.283185307179586
comptime _SALT_DENSITY: UInt64 = 0x100000001B3
comptime _SALT_SPECIES: UInt64 = 0x200000001B3
comptime _SALT_YAW: UInt64 = 0x300000001B3
comptime _SALT_SCALE: UInt64 = 0x400000001B3


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
    var su = hash01_cells(seed, x, z, _SALT_SCALE)
    inst.x = Float32(wx)
    inst.y = Float32(height)
    inst.z = Float32(wz)
    inst.yaw = Float32(yaw)
    inst.scale = Float32(FLORA_SCALE_MIN + su * (FLORA_SCALE_MAX - FLORA_SCALE_MIN))
    return inst^


struct FloraSubject(Movable, Deinitable):
    """Explicit flora population (ECOLOGY-INV-003): membership = the instance
    list; construction is a pure function of (seed, island). Count is capped
    at FLORA_N_MAX (0006 AP-13)."""

    var seed: UInt32
    var count: Int  # == len(instances), kept explicit for the cap oracle
    var instances: List[FloraInstance]

    def __init__(out self):
        self.seed = 0
        self.count = 0
        self.instances = List[FloraInstance]()

    def __deinit__(deinit self):
        pass


def flora_from_island(island: IslandSubject, seed: UInt32) raises -> FloraSubject:
    """Scan every column in deterministic row-major order (iz, ix) and keep
    the instances whose feature_for_column is a species. No world mutation
    beyond subject state (0006 Sprint 01)."""
    var flora = FloraSubject()
    flora.seed = seed
    for iz in range(GRID_N):
        for ix in range(GRID_N):
            if flora.count >= FLORA_N_MAX:
                return flora^
            var i = iz * GRID_N + ix
            var slope = cell_slope(island.heights, ix, iz)
            var inst = instance_for_column(
                ix, iz, island.biomes[i], slope, island.heights[i], seed
            )
            if inst.species_id == SPECIES_NONE:
                continue
            flora.instances.append(inst)
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
