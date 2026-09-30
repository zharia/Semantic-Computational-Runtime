# SCR-LIB-SPATIAL-VOXEL-SYNTHESIS (lib/801_Spatial/Voxel/Synthesis/101_definition.md)
# implemented in Mojo — pure pipeline (§1, §4 invariant 1):
#
#   (x, z, biome, feature, height, noise_context) → MaterialColumn
#
# Normative §2 biome → material table (row order = biome code order).
# §4 semantic invariants enforced and test-asserted:
#   3. bedrock (lattice y = 0) is always MAT_BEDROCK, never overridable
#   4. water fills every cell from surface+1 up to sea level where submerged
#   2. feature segments sit strictly above the terrain surface
#   5. write-once: the pipeline never reads the column it is writing
#
# DEVIATIONS / recorded choices:
#   - Lattice y = world y + LATTICE_Y_OFFSET (parameters.mojo): world y = 0 is
#     sea level; the contract's "bedrock (y = 0)" is lattice space.
#   - "sub-surface" band = SUBSURFACE_BAND_CELLS below the surface; "deep" is
#     everything from 1 to surface-1-band (the §2 table's granularity).
#   - Vegetation features (PALM/BAMBOO/CANOPY/SHRUB/FERN) are rejected:
#     vegetation is out of milestone scope (spec §9) and their materials are
#     not in the core-slice catalog vocabulary (honesty invariant 9).

from std.collections import List
from std.math import sqrt
from synthesis.noise import NoiseContext, gradient_noise
from synthesis.heightfield import cell_center_x, cell_center_z
from sim.parameters import (
    SEA_LEVEL,
    LATTICE_Y_OFFSET,
    SUBSURFACE_BAND_CELLS,
    NOISE_BASE_FREQUENCY,
)
from materials.catalog import (
    MAT_BEDROCK,
    MAT_BASALT,
    MAT_SAND,
    MAT_ASH,
    MAT_SULFUR,
    MAT_OBSIDIAN,
    MAT_LAVA,
    MAT_WATER,
    MAT_DIRT,
    MAT_PUMICE,
)

# --- BiomeTile codes (§2 table order; jungle rows kept for table fidelity) -
comptime BIOME_DEEP_OCEAN: Int = 0
comptime BIOME_SHALLOW_WATER: Int = 1
comptime BIOME_BEACH: Int = 2
comptime BIOME_COASTAL_JUNGLE: Int = 3
comptime BIOME_DENSE_RAINFOREST: Int = 4
comptime BIOME_VOLCANIC_SLOPE: Int = 5
comptime BIOME_CALDERA_RIM: Int = 6
comptime BIOME_CALDERA_LAKE: Int = 7
comptime BIOME_LAVA_RIVER: Int = 8
comptime BIOME_COUNT: Int = 9

# --- FeatureTile codes (§3 table order) ------------------------------------
comptime FEATURE_NONE: Int = 0
comptime FEATURE_PALM_CLUSTER: Int = 1
comptime FEATURE_PALM_SOLO: Int = 2
comptime FEATURE_BAMBOO_GROVE: Int = 3
comptime FEATURE_CANOPY_TREE: Int = 4
comptime FEATURE_CANOPY_CLUSTER: Int = 5
comptime FEATURE_SHRUB: Int = 6
comptime FEATURE_FERN_CARPET: Int = 7
comptime FEATURE_BASALT_BOULDER: Int = 8
comptime FEATURE_PUMICE_BOULDER: Int = 9
comptime FEATURE_OBSIDIAN_SHARD: Int = 10
comptime FEATURE_SULFUR_VENT: Int = 11
comptime FEATURE_ASH_FLAT: Int = 12
comptime FEATURE_LAVA_POOL: Int = 13
comptime FEATURE_COUNT: Int = 14

comptime FEATURE_HEIGHT_CELLS: Int = 3  # nominal object height (cells) above surface


struct ColumnSegment(Copyable, Movable, Deinitable):
    var y_start: Int  # inclusive lattice y
    var y_end: Int  # inclusive lattice y
    var material: UInt32  # voxel code (materials/catalog.mojo)

    def __init__(out self, y_start: Int, y_end: Int, material: UInt32):
        self.y_start = y_start
        self.y_end = y_end
        self.material = material

    def __deinit__(deinit self):
        pass


struct MaterialColumn(Copyable, Movable, Deinitable):
    var segments: List[ColumnSegment]

    def __init__(out self, var segments: List[ColumnSegment]):
        self.segments = segments^

    def __deinit__(deinit self):
        pass

    def covers(self, y: Int) -> Bool:
        for i in range(len(self.segments)):
            var s = self.segments[i].copy()
            if y >= s.y_start and y <= s.y_end:
                return True
        return False

    def material_at(self, y: Int) raises -> UInt32:
        for i in range(len(self.segments)):
            var s = self.segments[i].copy()
            if y >= s.y_start and y <= s.y_end:
                return s.material
        raise Error("no segment covers lattice y=" + String(y))


# ---------------------------------------------------------------------------
# §2 normative table: biome → allowed surface materials / sub-surface / deep
# ---------------------------------------------------------------------------

def biome_surface_materials(biome: Int) raises -> List[UInt32]:
    """Allowed surface materials for a biome (§2; row order = biome codes)."""
    if biome < 0 or biome >= BIOME_COUNT:
        raise Error("unknown biome " + String(biome))
    var out = List[UInt32]()
    if biome == BIOME_DEEP_OCEAN:
        out.append(MAT_BASALT)
    elif biome == BIOME_SHALLOW_WATER:
        out.append(MAT_SAND)
    elif biome == BIOME_BEACH:
        out.append(MAT_SAND)
    elif biome == BIOME_COASTAL_JUNGLE:
        out.append(MAT_DIRT)
    elif biome == BIOME_DENSE_RAINFOREST:
        out.append(MAT_DIRT)
    elif biome == BIOME_VOLCANIC_SLOPE:
        out.append(MAT_BASALT)
    elif biome == BIOME_CALDERA_RIM:
        out.append(MAT_ASH)
        out.append(MAT_SULFUR)
        out.append(MAT_OBSIDIAN)
    elif biome == BIOME_CALDERA_LAKE:
        out.append(MAT_LAVA)
    elif biome == BIOME_LAVA_RIVER:
        out.append(MAT_LAVA)
    return out^


def biome_subsurface_material(biome: Int) raises -> UInt32:
    if biome == BIOME_BEACH:
        return MAT_SAND
    if biome == BIOME_COASTAL_JUNGLE or biome == BIOME_DENSE_RAINFOREST:
        return MAT_DIRT
    if biome == BIOME_CALDERA_LAKE or biome == BIOME_LAVA_RIVER:
        return MAT_OBSIDIAN
    # DEEP_OCEAN, SHALLOW_WATER, VOLCANIC_SLOPE, CALDERA_RIM → BASALT
    return MAT_BASALT


def biome_deep_material(_biome: Int) raises -> UInt32:
    # §2: every row's Deep column is BASALT.
    return MAT_BASALT


def surface_material_for(
    biome: Int, x: Int, z: Int, height: Float64, ctx: NoiseContext
) raises -> UInt32:
    """Pick the surface material for this column.

    Fine-detail modulation uses noise_context but MUST NOT leave the biome's
    §2 row (e.g. no sand in the caldera — §2 closing rule)."""
    var allowed = biome_surface_materials(biome)
    if len(allowed) == 1:
        return allowed[0]
    # CALDERA_RIM row: deterministic noise pick among ASH/SULFUR/OBSIDIAN.
    var f = NOISE_BASE_FREQUENCY * 3.0
    var n = Float64(gradient_noise(ctx, Float64(x) * f, 7.0, Float64(z) * f))
    var pick = Int((n + 1.0) * 0.5 * Float64(len(allowed)))
    if pick >= len(allowed):
        pick = len(allowed) - 1
    if pick < 0:
        pick = 0
    return allowed[pick]


# ---------------------------------------------------------------------------
# §3 feature → column segments (strictly above the surface, invariant 2)
# ---------------------------------------------------------------------------

def feature_segments(feature: Int, surface_y: Int) raises -> List[ColumnSegment]:
    """Feature object segments in lattice space; y_start > surface_y always."""
    var out = List[ColumnSegment]()
    if feature == FEATURE_NONE:
        return out^
    if feature == FEATURE_ASH_FLAT:
        # "Ash surface layer, no standing object" — the feature replaces the
        # surface cell (nothing above the surface; invariant 2 vacuous).
        return out^
    if feature == FEATURE_LAVA_POOL:
        # "Lava fill to surface" — surface material is LAVA, no overburden.
        return out^
    var top = surface_y + FEATURE_HEIGHT_CELLS
    if feature == FEATURE_BASALT_BOULDER:
        out.append(ColumnSegment(surface_y + 1, top, MAT_BASALT))
        return out^
    if feature == FEATURE_PUMICE_BOULDER:
        out.append(ColumnSegment(surface_y + 1, surface_y + 2, MAT_PUMICE))
        return out^
    if feature == FEATURE_OBSIDIAN_SHARD:
        out.append(ColumnSegment(surface_y + 1, surface_y + 4, MAT_OBSIDIAN))
        return out^
    if feature == FEATURE_SULFUR_VENT:
        out.append(ColumnSegment(surface_y + 1, surface_y + 2, MAT_SULFUR))
        out.append(ColumnSegment(surface_y + 3, top, MAT_ASH))
        return out^
    # Vegetation features (§3 rows 1–7): out of scope this milestone.
    raise Error("vegetation feature " + String(feature) + " is successor-milestone scope")


def feature_replaces_surface(feature: Int) -> UInt32:
    """0 = no surface override; otherwise the material the feature writes on
    the surface cell itself (ASH_FLAT / LAVA_POOL §3 rows)."""
    if feature == FEATURE_ASH_FLAT:
        return MAT_ASH
    if feature == FEATURE_LAVA_POOL:
        return MAT_LAVA
    return 0


# ---------------------------------------------------------------------------
# The pipeline (§1)
# ---------------------------------------------------------------------------

def voxel_synthesis_pipeline(
    x: Int,
    z: Int,
    biome: Int,
    feature: Int,
    height: Float64,
    ctx: NoiseContext,
) raises -> MaterialColumn:
    """Pure function (x, z, biome, feature, height, noise_context) → column.

    Column order: bedrock (y=0) → deep → sub-surface → surface → water fill
    (only when height < sea level) → feature object (above surface only)."""
    # Lattice surface cell for this world-space height.
    var surface_y = Int(height + LATTICE_Y_OFFSET + 0.5)
    if surface_y < 1:
        surface_y = 1  # keep bedrock cell exclusive (invariant 3)

    var surface = surface_material_for(biome, x, z, height, ctx)
    var replacement = feature_replaces_surface(feature)
    if replacement != 0:
        surface = replacement
    var subsurface = biome_subsurface_material(biome)
    var deep = biome_deep_material(biome)

    var out = List[ColumnSegment]()
    # Invariant 3: bedrock cell, always first, never overridden.
    out.append(ColumnSegment(0, 0, MAT_BEDROCK))

    var sub_floor = surface_y - SUBSURFACE_BAND_CELLS
    if sub_floor < 1:
        sub_floor = 1
    # Deep: cells 1 .. min(sub_floor-1, surface_y-1).
    var deep_end = sub_floor - 1
    if deep_end >= 1:
        out.append(ColumnSegment(1, deep_end, deep))
    # Sub-surface: sub_floor .. surface_y-1 (may be empty when surface_y small).
    if surface_y - 1 >= sub_floor:
        out.append(ColumnSegment(sub_floor, surface_y - 1, subsurface))
    # Surface cell.
    out.append(ColumnSegment(surface_y, surface_y, surface))

    # Invariant 4: water fill from surface+1 up to sea level when submerged.
    var sea_y = Int(SEA_LEVEL + LATTICE_Y_OFFSET + 0.5)
    if height < SEA_LEVEL and sea_y > surface_y:
        out.append(ColumnSegment(surface_y + 1, sea_y, MAT_WATER))

    # Invariant 2: features strictly above the surface.
    var fsegs = feature_segments(feature, surface_y)
    for i in range(len(fsegs)):
        out.append(fsegs[i].copy())

    return MaterialColumn(out^)


def classify_biome(
    x: Float64, z: Float64, height: Float64, radius: Float64
) -> Int:
    """Volcanic-profile biome classification (geometry + height)."""
    from sim.parameters import (
        SEA_LEVEL as SL,
        SHALLOW_WATER_DEPTH,
        BEACH_BAND_HEIGHT,
        CALDERA_LAKE_RADIUS,
        CALDERA_RIM_OUTER_RADIUS,
    )

    # Caldera zones by radius (island interior only).
    if height > SL:
        if radius < CALDERA_LAKE_RADIUS:
            return BIOME_CALDERA_LAKE
        if radius < CALDERA_RIM_OUTER_RADIUS:
            return BIOME_CALDERA_RIM
        if height <= BEACH_BAND_HEIGHT:
            return BIOME_BEACH
        return BIOME_VOLCANIC_SLOPE
    # Submerged.
    if height >= SL - SHALLOW_WATER_DEPTH:
        return BIOME_SHALLOW_WATER
    return BIOME_DEEP_OCEAN


struct ColumnResynthesis(Copyable, Movable, Deinitable):
    """Result of the single-column re-synthesis entry (0007 §5 Sprint 01):
    the reclassified biome plus the pipeline column for the edited height."""

    var biome: Int
    var column: MaterialColumn

    def __init__(out self, biome: Int, var column: MaterialColumn):
        self.biome = biome
        self.column = column^

    def __deinit__(deinit self):
        pass


def resynthesize_column(
    x: Int, z: Int, height: Float64, ctx: NoiseContext
) raises -> ColumnResynthesis:
    """Re-run the NORMATIVE pipeline for one edited column (0007 AP-11).

    Same authority and same argument derivation as build_island's grid pass
    (sim/island.mojo): cell-centre world coordinates → radius →
    classify_biome → voxel_synthesis_pipeline with FEATURE_NONE. Never a
    direct grid poke — callers only copy the returned biome/surface out."""
    var wx = cell_center_x(x)
    var wz = cell_center_z(z)
    var r = sqrt(wx * wx + wz * wz)
    var biome = classify_biome(wx, wz, height, r)
    var col = voxel_synthesis_pipeline(x, z, biome, FEATURE_NONE, height, ctx)
    return ColumnResynthesis(biome, col^)
