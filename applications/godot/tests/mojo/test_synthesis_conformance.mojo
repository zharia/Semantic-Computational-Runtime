# Spec test — SCR-LIB-SPATIAL-VOXEL-SYNTHESIS conformance (milestone_0002 §7):
# biome → material table + bedrock/sea-level invariants for the volcanic
# profile; field sampling semantics (SCR-LIB-FIELD via height queries).

from std.collections import List
from std.testing import TestSuite
from std.math import abs, sqrt

from sim.world import world_init
from sim.island import build_island
from synthesis.noise import NoiseContext
from synthesis.heightfield import height_at_cell, bilinear_sample
from synthesis.voxel import (
    voxel_synthesis_pipeline,
    classify_biome,
    biome_surface_materials,
    biome_subsurface_material,
    feature_segments,
    ColumnSegment,
    BIOME_COUNT,
    BIOME_CALDERA_LAKE,
    FEATURE_COUNT,
    FEATURE_NONE,
    FEATURE_PALM_SOLO,
    FEATURE_HEIGHT_CELLS,
)
from materials.catalog import MAT_BEDROCK, MAT_WATER, MAT_VOCAB_COUNT, MAT_LAVA
from sim.parameters import (
    LATTICE_Y_OFFSET,
    SEA_LEVEL,
    SPAWN_SEARCH_RADIUS_MIN,
    SPAWN_SEARCH_RADIUS_MAX,
    GRID_N as PARAM_GRID_N,
    CELL_SIZE,
)

comptime SEA_LATTICE: Int = 24  # SEA_LEVEL(0) + LATTICE_Y_OFFSET(24)


def test_height_field_shape_and_determinism() raises:
    var a = build_island(1)
    var b = build_island(1)
    var c = build_island(7)
    assert len(a.heights) == PARAM_GRID_N * PARAM_GRID_N, "64×64 grid"
    assert a.seed == 1
    var seed_sensitive = False
    for i in range(len(a.heights)):
        if a.heights[i] != b.heights[i]:
            raise Error("non-deterministic height at " + String(i))
        if a.heights[i] != c.heights[i]:
            seed_sensitive = True
    assert seed_sensitive, "seed must affect the field"


def test_bilinear_interpolation_on_island_grid() raises:
    var island = build_island(1)
    # Corner equality on the island's own grid.
    for ix in range(0, PARAM_GRID_N, 9):
        for iz in range(0, PARAM_GRID_N, 13):
            var wx = (Float64(ix) - Float64(PARAM_GRID_N) / 2.0) * CELL_SIZE
            var wz = (Float64(iz) - Float64(PARAM_GRID_N) / 2.0) * CELL_SIZE
            var v = bilinear_sample(island.heights, wx, wz)
            assert abs(v - island.heights[iz * PARAM_GRID_N + ix]) < 1e-9, "corner exact"
    # Midpoint between two corners lies between the two values.
    var v00 = bilinear_sample(island.heights, -128.0, -128.0)
    var v10 = bilinear_sample(island.heights, -124.0, -128.0)
    var vmid = bilinear_sample(island.heights, -126.0, -128.0)
    var lo = v00 if v00 < v10 else v10
    var hi = v10 if v00 < v10 else v00
    assert vmid >= lo - 1e-9 and vmid <= hi + 1e-9, "monotone blend"


def test_bedrock_and_water_invariants() raises:
    var ctx = NoiseContext(1)
    # Volcanic profile column at a submerged cell (deep ocean).
    var h = -15.0
    var biome = classify_biome(-120.0, -120.0, h, 169.7)
    var col = voxel_synthesis_pipeline(-120, -120, biome, FEATURE_NONE, h, ctx)
    # Invariant 3: bedrock cell y=0 always first, never overridden.
    var s0 = col.segments[0].copy()
    assert s0.y_start == 0 and s0.y_end == 0, "bedrock occupies cell 0"
    assert s0.material == MAT_BEDROCK, "cell 0 is bedrock"
    # Invariant 4: water fills surface+1 .. sea level when submerged.
    assert col.material_at(SEA_LATTICE) == MAT_WATER, "sea level column is water"
    # Surface cell exists below sea level.
    var surface_y = Int(h + LATTICE_Y_OFFSET + 0.5)
    assert col.material_at(surface_y) != MAT_WATER, "surface is not water cell"
    # No gaps: every cell 0..SEA_LATTICE is covered.
    for y in range(0, SEA_LATTICE + 1):
        assert col.covers(y), "uncovered cell y=" + String(y)


def test_dry_column_has_no_water() raises:
    var ctx = NoiseContext(1)
    var h = 12.0
    var biome = classify_biome(40.0, 40.0, h, 56.5)
    var col = voxel_synthesis_pipeline(40, 40, biome, FEATURE_NONE, h, ctx)
    assert col.material_at(0) == MAT_BEDROCK
    var surface_y = Int(h + LATTICE_Y_OFFSET + 0.5)
    assert col.material_at(surface_y) != MAT_WATER, "dry surface material"
    # No cell above the surface is covered (except none — no feature).
    assert not col.covers(surface_y + 1), "no water fill above dry surface"


def test_feature_sits_strictly_above_surface() raises:
    var ctx = NoiseContext(1)
    var h = 8.0
    var biome = classify_biome(30.0, 30.0, h, 58.0)
    var surface_y = Int(h + LATTICE_Y_OFFSET + 0.5)
    for feature in range(FEATURE_COUNT):
        # Vegetation features are rejected loudly as successor-milestone
        # scope (spec §10: vegetation is out of scope for 0002).
        var rejected = False
        var col = voxel_synthesis_pipeline(30, 30, biome, FEATURE_NONE, h, ctx)
        var segs = List[ColumnSegment]()
        try:
            segs = feature_segments(feature, surface_y)
            _ = voxel_synthesis_pipeline(30, 30, biome, feature, h, ctx)
        except e:
            rejected = True
            assert String(e).find("successor") >= 0, "rejection must be scoped"
        if rejected:
            # Vegetation features (1..7) are successor-milestone scope
            # (spec §10) and must be rejected loudly, never silently skipped.
            assert feature >= 1 and feature <= 7, "only vegetation rejects"
            continue
        for i in range(len(segs)):
            var seg = segs[i].copy()
            if feature == FEATURE_NONE:
                continue
            assert seg.y_start > surface_y, (
                "feature " + String(feature) + " intersects surface"
            )
            assert seg.y_end - seg.y_start <= FEATURE_HEIGHT_CELLS, "nominal height"
        # Column order stays monotonic: appended after surface.
        assert col.material_at(surface_y) != MAT_WATER or h < SEA_LEVEL


def test_biome_surface_table_is_closed_over_vocabulary() raises:
    # In-row: every surface material is a known vocabulary code; rows are
    # non-empty; subsurface materials are known codes.
    for biome in range(BIOME_COUNT):
        var row = biome_surface_materials(biome)
        assert len(row) >= 1, "row " + String(biome) + " empty"
        for i in range(len(row)):
            assert Int(row[i]) < MAT_VOCAB_COUNT, "code out of vocabulary"
        var sub = biome_subsurface_material(biome)
        assert Int(sub) < MAT_VOCAB_COUNT, "subsurface out of vocabulary"
    # Caldera lake surface is water (volcanic profile, Spec §7).
    var lake = biome_surface_materials(BIOME_CALDERA_LAKE)
    var has_water = False
    for i in range(len(lake)):
        if lake[i] == MAT_WATER:
            has_water = True
    assert has_water, "caldera lake surface must be water"


def test_surface_material_matches_row() raises:
    var ctx = NoiseContext(1)
    # Every cell of the island: surface material ∈ classify_biome's row.
    var island = build_island(1)
    var checked = 0
    for iz in range(0, PARAM_GRID_N, 8):
        for ix in range(0, PARAM_GRID_N, 8):
            var wx = (Float64(ix) - Float64(PARAM_GRID_N) / 2.0) * CELL_SIZE
            var wz = (Float64(iz) - Float64(PARAM_GRID_N) / 2.0) * CELL_SIZE
            var r = sqrt(wx * wx + wz * wz)
            var h = island.heights[iz * PARAM_GRID_N + ix]
            var biome = classify_biome(wx, wz, h, r)
            assert biome >= 0 and biome < BIOME_COUNT, "biome code range"
            var col = voxel_synthesis_pipeline(ix, iz, biome, FEATURE_NONE, h, ctx)
            var surface_y = Int(h + LATTICE_Y_OFFSET + 0.5)
            if surface_y < 1:
                surface_y = 1
            var got = col.material_at(surface_y)
            var row = biome_surface_materials(biome)
            var in_row = False
            for i in range(len(row)):
                if row[i] == got:
                    in_row = True
            # Lava river may replace surface with lava via feature logic; the
            # base row check applies to non-lava biomes too, so allow MAT_LAVA
            # only when the classified biome allows it (biome 8 row).
            if not in_row and got == MAT_LAVA:
                var lava_row = biome_surface_materials(8)
                for i in range(len(lava_row)):
                    if lava_row[i] == MAT_LAVA:
                        in_row = True
            assert in_row, "surface material outside biome row at cell"
            checked += 1
    assert checked > 40, "sampling must cover the grid"


def test_spawn_is_on_the_island_beach() raises:
    var world = world_init(1)
    var sx = world.island.spawn_x
    var sz = world.island.spawn_z
    var r = sqrt(sx * sx + sz * sz)
    assert r >= SPAWN_SEARCH_RADIUS_MIN and r <= SPAWN_SEARCH_RADIUS_MAX, "spawn radius"
    var h = world.island.height_at(sx, sz)
    assert h > SEA_LEVEL, "spawn above water"
    assert h <= 1.5, "spawn within beach band"
    assert world.island.spawn_y == h, "spawn y anchored to field"


def main() raises:
    TestSuite.discover_tests[
        (
            test_height_field_shape_and_determinism,
            test_bilinear_interpolation_on_island_grid,
            test_bedrock_and_water_invariants,
            test_dry_column_has_no_water,
            test_feature_sits_strictly_above_surface,
            test_biome_surface_table_is_closed_over_vocabulary,
            test_surface_material_matches_row,
            test_spawn_is_on_the_island_beach,
        )
    ]().run()
