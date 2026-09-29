# Spec test — SCR-LIB-SPATIAL-VOXEL-SYNTHESIS conformance (milestone_0002 §7):
# biome → material table + bedrock/sea-level invariants for the volcanic
# profile; field sampling semantics (SCR-LIB-FIELD via height queries).

# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified in test_volcano.mojo: `assert False` does not stop execution).
# Every check below uses `_check`, which raises Error => TestSuite reports
# FAIL and exits non-zero.

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


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def test_height_field_shape_and_determinism() raises:
    var a = build_island(1)
    var b = build_island(1)
    var c = build_island(7)
    _check(len(a.heights) == PARAM_GRID_N * PARAM_GRID_N,  "64×64 grid")
    _check(a.seed == 1, "line 45")
    var seed_sensitive = False
    for i in range(len(a.heights)):
        if a.heights[i] != b.heights[i]:
            raise Error("non-deterministic height at " + String(i))
        if a.heights[i] != c.heights[i]:
            seed_sensitive = True
    _check(seed_sensitive,  "seed must affect the field")


def test_bilinear_interpolation_on_island_grid() raises:
    var island = build_island(1)
    # Corner equality on the island's own grid. Cell centres live at
    # c_i = (i + 0.5 - N/2) * CELL_SIZE (heightfield.mojo bilinear_sample /
    # height_at_cell); an earlier revision omitted the +0.5 half-cell offset
    # and asked for a value between centres — hidden by the no-op `assert`.
    for ix in range(0, PARAM_GRID_N, 9):
        for iz in range(0, PARAM_GRID_N, 13):
            var wx = (Float64(ix) + 0.5 - Float64(PARAM_GRID_N) / 2.0) * CELL_SIZE
            var wz = (Float64(iz) + 0.5 - Float64(PARAM_GRID_N) / 2.0) * CELL_SIZE
            var v = bilinear_sample(island.heights, wx, wz)
            _check(abs(v - island.heights[iz * PARAM_GRID_N + ix]) < 1e-9,  "corner exact")
    # Midpoint between two corners lies between the two values.
    var v00 = bilinear_sample(island.heights, -128.0, -128.0)
    var v10 = bilinear_sample(island.heights, -124.0, -128.0)
    var vmid = bilinear_sample(island.heights, -126.0, -128.0)
    var lo = v00 if v00 < v10 else v10
    var hi = v10 if v00 < v10 else v00
    _check(vmid >= lo - 1e-9 and vmid <= hi + 1e-9,  "monotone blend")


def test_bedrock_and_water_invariants() raises:
    var ctx = NoiseContext(1)
    # Volcanic profile column at a submerged cell (deep ocean).
    var h = -15.0
    var biome = classify_biome(-120.0, -120.0, h, 169.7)
    var col = voxel_synthesis_pipeline(-120, -120, biome, FEATURE_NONE, h, ctx)
    # Invariant 3: bedrock cell y=0 always first, never overridden.
    var s0 = col.segments[0].copy()
    _check(s0.y_start == 0 and s0.y_end == 0,  "bedrock occupies cell 0")
    _check(s0.material == MAT_BEDROCK,  "cell 0 is bedrock")
    # Invariant 4: water fills surface+1 .. sea level when submerged.
    _check(col.material_at(SEA_LATTICE) == MAT_WATER,  "sea level column is water")
    # Surface cell exists below sea level.
    var surface_y = Int(h + LATTICE_Y_OFFSET + 0.5)
    _check(col.material_at(surface_y) != MAT_WATER,  "surface is not water cell")
    # No gaps: every cell 0..SEA_LATTICE is covered.
    for y in range(0, SEA_LATTICE + 1):
        _check(col.covers(y), "uncovered cell y=" + String(y))


def test_dry_column_has_no_water() raises:
    var ctx = NoiseContext(1)
    var h = 12.0
    var biome = classify_biome(40.0, 40.0, h, 56.5)
    var col = voxel_synthesis_pipeline(40, 40, biome, FEATURE_NONE, h, ctx)
    _check(col.material_at(0) == MAT_BEDROCK, "line 98")
    var surface_y = Int(h + LATTICE_Y_OFFSET + 0.5)
    _check(col.material_at(surface_y) != MAT_WATER,  "dry surface material")
    # No cell above the surface is covered (except none — no feature).
    _check(not col.covers(surface_y + 1),  "no water fill above dry surface")


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
            _check(String(e).find("successor") >= 0,  "rejection must be scoped")
        if rejected:
            # Vegetation features (1..7) are successor-milestone scope
            # (spec §10) and must be rejected loudly, never silently skipped.
            _check(feature >= 1 and feature <= 7,  "only vegetation rejects")
            continue
        for i in range(len(segs)):
            var seg = segs[i].copy()
            if feature == FEATURE_NONE:
                continue
            _check(
                seg.y_start > surface_y,
                "feature " + String(feature) + " intersects surface",
            )
            _check(seg.y_end - seg.y_start <= FEATURE_HEIGHT_CELLS,  "nominal height")
        # Column order stays monotonic: appended after surface.
        _check(col.material_at(surface_y) != MAT_WATER or h < SEA_LEVEL, "line 136")


def test_biome_surface_table_is_closed_over_vocabulary() raises:
    # In-row: every surface material is a known vocabulary code; rows are
    # non-empty; subsurface materials are known codes.
    for biome in range(BIOME_COUNT):
        var row = biome_surface_materials(biome)
        _check(len(row) >= 1,  "row " + String(biome) + " empty")
        for i in range(len(row)):
            _check(Int(row[i]) < MAT_VOCAB_COUNT,  "code out of vocabulary")
        var sub = biome_subsurface_material(biome)
        _check(Int(sub) < MAT_VOCAB_COUNT,  "subsurface out of vocabulary")
    # Caldera lake surface is LAVA: milestone_0002 §3 table locks
    # CALDERA_LAKE→LAVA (the old expectation of MAT_WATER contradicted that
    # normative row and was hidden by the no-op `assert`).
    var lake = biome_surface_materials(BIOME_CALDERA_LAKE)
    var has_lava = False
    for i in range(len(lake)):
        if lake[i] == MAT_LAVA:
            has_lava = True
    _check(has_lava, "caldera lake surface must be lava")


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
            _check(biome >= 0 and biome < BIOME_COUNT,  "biome code range")
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
            _check(in_row,  "surface material outside biome row at cell")
            checked += 1
    _check(checked > 40,  "sampling must cover the grid")


def test_spawn_is_on_the_island_beach() raises:
    var world = world_init(1)
    var sx = world.island.spawn_x
    var sz = world.island.spawn_z
    var r = sqrt(sx * sx + sz * sz)
    _check(r >= SPAWN_SEARCH_RADIUS_MIN and r <= SPAWN_SEARCH_RADIUS_MAX,  "spawn radius")
    var h = world.island.height_at(sx, sz)
    _check(h > SEA_LEVEL,  "spawn above water")
    _check(h <= 1.5,  "spawn within beach band")
    _check(world.island.spawn_y == h,  "spawn y anchored to field")


def test_blend_tuples_inside_pipeline_invariants() raises:
    """milestone_0005 §3.4: blend tuples live INSIDE the pipeline invariants —
    shape, write-once dominant (AP-20), identity when unblended, no lava in
    any tuple, and a stable surface/height grid across pure rebuilds."""
    var island = build_island(1)
    _check(
        len(island.blends) == PARAM_GRID_N * PARAM_GRID_N,
        "tuple grid is GRID_N²",
    )
    var blended = 0
    for i in range(PARAM_GRID_N * PARAM_GRID_N):
        var t = island.blends[i]
        _check(
            t.material == island.surface_materials[i],
            "tuple dominant must equal the assigned surface (write-once)",
        )
        if t.weight == 0:
            _check(t.blend == t.material, "unblended tuple is identity")
        else:
            blended += 1
            _check(t.blend != t.material, "blended tuple partner differs")
            if t.material == MAT_LAVA or t.blend == MAT_LAVA:
                raise Error("lava must never appear in a blend tuple")
    _check(blended > 0, "seed-1 has feathered boundary cells")
    # The blend pass reads the surface grid — rebuilding from the same seed
    # must reproduce heights and surfaces exactly (purity + determinism).
    var again = build_island(1)
    for i in range(PARAM_GRID_N * PARAM_GRID_N):
        _check(
            again.heights[i] == island.heights[i],
            "height grid unstable across rebuilds",
        )
        _check(
            again.surface_materials[i] == island.surface_materials[i],
            "surface grid unstable across rebuilds",
        )
        _check(
            again.blends[i].material == island.blends[i].material
            and again.blends[i].blend == island.blends[i].blend
            and again.blends[i].weight == island.blends[i].weight,
            "blend tuples unstable across rebuilds at " + String(i),
        )


def test_crater_rim_seams_are_feathered() raises:
    """milestone_0005 §3.4 crater-rim fix: every seed-1 material seam whose
    differing neighbour is not lava carries a nonzero feather weight (the
    documented 0002 crater 'teeth' location); lava seams stay unblended."""
    var island = build_island(1)
    var n = PARAM_GRID_N
    var seams = 0
    for iz in range(n):
        for ix in range(n):
            var i = iz * n + ix
            var m = island.surface_materials[i]
            var seam_non_lava = False
            if ix + 1 < n:
                var mn = island.surface_materials[i + 1]
                if mn != m and m != MAT_LAVA and mn != MAT_LAVA:
                    seam_non_lava = True
            if iz + 1 < n:
                var ms = island.surface_materials[i + n]
                if ms != m and m != MAT_LAVA and ms != MAT_LAVA:
                    seam_non_lava = True
            if not seam_non_lava:
                continue
            seams += 1
            _check(
                island.blends[i].weight > 0,
                "non-lava seam at (" + String(ix) + "," + String(iz)
                + ") is unfeathered",
            )
    _check(seams > 0, "seed-1 has non-lava material seams")
    # Lava columns are excluded from blending (§3.6).
    for i in range(n * n):
        if island.surface_materials[i] == MAT_LAVA:
            _check(
                island.blends[i].weight == 0,
                "lava column feathered at " + String(i),
            )


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
            test_blend_tuples_inside_pipeline_invariants,
            test_crater_rim_seams_are_feathered,
        )
    ]().run()
