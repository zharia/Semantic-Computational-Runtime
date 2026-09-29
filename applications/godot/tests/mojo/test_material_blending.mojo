# Spec test — Boundary material blending (milestone_0005 §7 "Blending
# conformance"):
#   - feather band width within FEATHER_WIDTH_CELLS ± 1 at a synthetic
#     BASALT ↔ SULFUR boundary, weight ramp strictly monotonic toward the
#     boundary, deterministic noise dither (bit-identical across two
#     same-seed runs),
#   - no cross-biome material in ANY seed-1 column (Synthesis §2: fine detail
#     must not override the biome surface with another biome's material) and
#     blend partners restricted to the adjacent biomes' permitted sets
#     (§6 invariant 4), blend tuples never change the dominant material
#     (write-once / single-material-authority, AP-20),
#   - lava columns are never blended (0003 CALDERA_LAKE → LAVA, §3.6),
#   - crater-rim evidence: the VOLCANIC_SLOPE(BASALT) ↔ CALDERA_RIM
#     boundary of the seed-1 island carries a feather band.
# Headless: runs without Godot.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified: `assert False` does not stop execution). Every check below uses
# `_check`, which raises Error ⇒ TestSuite reports FAIL and exits non-zero.

from std.collections import List
from std.testing import TestSuite
from std.math import abs

from synthesis.blend import BlendTuple, compute_blends
from synthesis.voxel import (
    biome_surface_materials,
    BIOME_VOLCANIC_SLOPE,
    BIOME_CALDERA_RIM,
    BIOME_CALDERA_LAKE,
)
from synthesis.noise import NoiseContext
from sim.island import build_island
from sim.parameters import GRID_N, FEATHER_WIDTH_CELLS
from materials.catalog import (
    MAT_BASALT,
    MAT_SULFUR,
    MAT_LAVA,
    MAT_VOCAB_COUNT,
)


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _in_row(code: UInt32, biome: Int) raises -> Bool:
    var row = biome_surface_materials(biome)
    for i in range(len(row)):
        if row[i] == code:
            return True
    return False


def _half() -> Int:
    return GRID_N // 2


struct SyntheticGrid(Movable, Deinitable):
    """GRID_N² (materials, biomes) pair for boundary-blend fixtures."""

    var materials: List[UInt32]
    var biomes: List[Int]

    def __init__(out self):
        self.materials = List[UInt32]()
        self.biomes = List[Int]()

    def __deinit__(deinit self):
        pass


def _synthetic_boundary() raises -> SyntheticGrid:
    """GRID_N² BASALT (x < N/2) | SULFUR (x >= N/2) with the matching
    §2 biomes — the spec's synthetic BASALT↔SULFUR boundary (slope ↔ rim)."""
    var g = SyntheticGrid()
    for iz in range(GRID_N):
        for ix in range(GRID_N):
            if ix < _half():
                g.materials.append(MAT_BASALT)
                g.biomes.append(BIOME_VOLCANIC_SLOPE)
            else:
                g.materials.append(MAT_SULFUR)
                g.biomes.append(BIOME_CALDERA_RIM)
    return g^


def _synthetic_lava_edge() raises -> SyntheticGrid:
    """BASALT | LAVA edge (slope ↔ caldera lake): lava must never feather."""
    var g = SyntheticGrid()
    for iz in range(GRID_N):
        for ix in range(GRID_N):
            if ix < _half():
                g.materials.append(MAT_BASALT)
                g.biomes.append(BIOME_VOLCANIC_SLOPE)
            else:
                g.materials.append(MAT_LAVA)
                g.biomes.append(BIOME_CALDERA_LAKE)
    return g^


def test_feather_band_width_and_monotonic_ramp() raises:
    """§7: band width FEATHER_WIDTH_CELLS ± 1 per side; weight strictly
    increases toward the boundary on both sides; no weight outside."""
    var grid = _synthetic_boundary()
    var materials = grid.materials.copy()
    var biomes = grid.biomes.copy()
    var blends = compute_blends(materials, biomes, NoiseContext(1))
    _check(len(blends) == GRID_N * GRID_N, "tuple grid is GRID_N²")
    var h = _half()

    # Full rows: measure the band on each side of the vertical boundary.
    for iz in range(GRID_N):
        var left = 0
        var right = 0
        for ix in range(GRID_N):
            var w = blends[iz * GRID_N + ix].weight
            if ix < h and w > 0:
                left += 1
            if ix >= h and w > 0:
                right += 1
            # Dominant material is never reassigned (write-once, AP-20).
            _check(
                blends[iz * GRID_N + ix].material
                == materials[iz * GRID_N + ix],
                "tuple dominant must equal the column surface",
            )
        _check(
            abs(left - FEATHER_WIDTH_CELLS) <= 1,
            "left band width " + String(left) + " outside FEATHER ± 1 at row "
            + String(iz),
        )
        _check(
            abs(right - FEATHER_WIDTH_CELLS) <= 1,
            "right band width " + String(right) + " outside FEATHER ± 1 at row "
            + String(iz),
        )

        # Monotonic toward the boundary: strictly increasing as d decreases
        # (left side: h-4 … h-1; right side: h … h+3), and zero outside.
        for k in range(FEATHER_WIDTH_CELLS):
            var wl = blends[iz * GRID_N + (h - 1 - k)].weight
            var wr = blends[iz * GRID_N + (h + k)].weight
            if k + 1 < FEATHER_WIDTH_CELLS:
                var wl_next = blends[iz * GRID_N + (h - 2 - k)].weight
                _check(
                    wl > wl_next,
                    "left ramp not monotonic toward boundary at row "
                    + String(iz) + " step " + String(k),
                )
                var wr_next = blends[iz * GRID_N + (h + 1 + k)].weight
                _check(
                    wr > wr_next,
                    "right ramp not monotonic toward boundary at row "
                    + String(iz) + " step " + String(k),
                )
            _check(wl > 0, "inside left band must be nonzero")
            _check(wr > 0, "inside right band must be nonzero")
        _check(
            blends[iz * GRID_N + (h - 1 - FEATHER_WIDTH_CELLS)].weight == 0,
            "left of band is weight 0",
        )
        if h + FEATHER_WIDTH_CELLS < GRID_N:
            _check(
                blends[iz * GRID_N + (h + FEATHER_WIDTH_CELLS)].weight == 0,
                "right of band is weight 0",
            )

        # Boundary-adjacent cells (distance 0) carry the clamped top of the
        # ramp (base 1.0 ± dither ⇒ quantised ∈ [230, 255]).
        var wl0 = blends[iz * GRID_N + (h - 1)].weight
        var wr0 = blends[iz * GRID_N + h].weight
        _check(wl0 >= 230, "left boundary cell near the ramp top")
        _check(wr0 >= 230, "right boundary cell near the ramp top")


def test_blend_pairs_restricted_to_adjacent_biome_sets() raises:
    """§6 invariant 4 / Synthesis §2: on each side the partner is exactly the
    other adjacent biome's surface material — never a material from a biome
    that is not across the boundary."""
    var grid = _synthetic_boundary()
    var materials = grid.materials.copy()
    var biomes = grid.biomes.copy()
    var blends = compute_blends(materials, biomes, NoiseContext(1))
    var h = _half()
    for i in range(GRID_N * GRID_N):
        var t = blends[i]
        var biome = biomes[i]
        _check(_in_row(t.material, biome), "dominant outside its biome row")
        if t.weight == 0:
            _check(
                t.blend == t.material, "no-blend tuple must be identity"
            )
            continue
        # Blended: partner must sit in the OTHER adjacent biome's row.
        _check(t.blend != t.material, "blended tuple partner differs")
        var partner_biome = BIOME_CALDERA_RIM if biome == BIOME_VOLCANIC_SLOPE else BIOME_VOLCANIC_SLOPE
        _check(
            _in_row(t.blend, partner_biome),
            "partner outside the adjacent biome's permitted set",
        )
        if biome == BIOME_VOLCANIC_SLOPE:
            _check(t.blend == MAT_SULFUR, "slope side blends toward SULFUR")
        else:
            _check(t.blend == MAT_BASALT, "rim side blends toward BASALT")


def test_lava_columns_never_blend() raises:
    """§3.6 (0003 interaction): CALDERA_LAKE → LAVA never feathers into
    neighbors — quench/obsidian rules govern lava adjacency."""
    var grid = _synthetic_lava_edge()
    var materials = grid.materials.copy()
    var biomes = grid.biomes.copy()
    var blends = compute_blends(materials, biomes, NoiseContext(1))
    var h = _half()
    for iz in range(GRID_N):
        for ix in range(GRID_N):
            var t = blends[iz * GRID_N + ix]
            if materials[iz * GRID_N + ix] == MAT_LAVA:
                _check(
                    t.weight == 0 and t.blend == t.material,
                    "lava column was blended at (" + String(ix) + ","
                    + String(iz) + ")",
                )
            else:
                # The land side must not feather toward lava either: the
                # whole BASALT|LAVA edge is excluded from boundary seeding.
                _check(
                    t.weight == 0,
                    "basalt column feathered into lava at (" + String(ix)
                    + "," + String(iz) + ")",
                )


def test_dither_bit_identical_across_same_seed_runs() raises:
    """§7: deterministic dither — two runs with the same seed are bit-
    identical; a different seed changes the weights."""
    var grid = _synthetic_boundary()
    var materials = grid.materials.copy()
    var biomes = grid.biomes.copy()
    var a = compute_blends(materials, biomes, NoiseContext(1))
    var b = compute_blends(materials, biomes, NoiseContext(1))
    var differ = 0
    for i in range(len(a)):
        _check(
            a[i].material == b[i].material
            and a[i].blend == b[i].blend
            and a[i].weight == b[i].weight,
            "same-seed dither drifted at cell " + String(i),
        )
        if a[i].weight != 0:
            differ += 1
    _check(differ > 0, "band must exist for the comparison to matter")
    # Seed sensitivity: the dither noise is seeded, so another seed moves
    # weights (boundary detection itself stays material-determined).
    var c = compute_blends(materials, biomes, NoiseContext(2))
    var moved = 0
    for i in range(len(a)):
        if a[i].weight != c[i].weight:
            moved += 1
    _check(moved > 0, "dither must depend on noise_context seed")


def test_seed1_no_cross_biome_material_anywhere() raises:
    """§7: scan ALL seed-1 columns — every surface material sits in its own
    biome's §2 row; every blend tuple preserves the dominant and hands out a
    partner that physically exists within the feather locality of an adjacent
    column (no cross-biome override, Synthesis §2)."""
    var island = build_island(1)
    var n = GRID_N
    _check(len(island.blends) == n * n, "blend grid is GRID_N²")
    var blended = 0
    var lava_cells = 0
    var box = 2 * FEATHER_WIDTH_CELLS + 1  # partner locality bound
    for iz in range(n):
        for ix in range(n):
            var i = iz * n + ix
            var surf = island.surface_materials[i]
            var biome = island.biomes[i]
            var t = island.blends[i]
            # 1) no cross-biome surface material in ANY column (full scan).
            _check(
                _in_row(surf, biome),
                "surface material outside biome row at (" + String(ix) + ","
                + String(iz) + ")",
            )
            # 2) tuple dominant mirrors the surface (write-once, AP-20).
            _check(t.material == surf, "tuple dominant drifted from surface")
            if t.weight == 0:
                _check(t.blend == t.material, "identity tuple partner")
                continue
            blended += 1
            # 3) partner came from a real neighbouring column's surface within
            #    the feather locality — it belongs to the biome that owns it.
            var found = False
            for dz in range(-box, box + 1):
                var jz = iz + dz
                if jz < 0 or jz >= n:
                    continue
                for dx in range(-box, box + 1):
                    var jx = ix + dx
                    if jx < 0 or jx >= n:
                        continue
                    if island.surface_materials[jz * n + jx] == t.blend:
                        found = True
                if found:
                    break
            _check(
                found,
                "blend partner not present in the locality at (" + String(ix)
                + "," + String(iz) + ")",
            )
            # partner material is inside the vocabulary (catalog mapping).
            _check(Int(t.blend) < MAT_VOCAB_COUNT, "partner out of vocabulary")
            if t.blend == MAT_LAVA:
                raise Error("lava must never appear as a blend partner")
    _check(blended > 0, "seed-1 island has feathered boundary cells")


def test_seed1_crater_rim_has_feather_band() raises:
    """§3.4 crater-rim fix: the VOLCANIC_SLOPE(BASALT) ↔ CALDERA_RIM
    boundary carries a feather band (weight > 0 at every material seam)."""
    var island = build_island(1)
    var n = GRID_N
    var seams = 0
    var seamed = 0
    var rim_feathered = 0
    for iz in range(n):
        for ix in range(n):
            var i = iz * n + ix
            var biome = island.biomes[i]
            # seam: material differs from the +x or +z neighbour
            var has_seam = False
            if ix + 1 < n:
                if island.surface_materials[i + 1] != island.surface_materials[i]:
                    has_seam = True
            if iz + 1 < n:
                if island.surface_materials[i + n] != island.surface_materials[i]:
                    has_seam = True
            if not has_seam:
                continue
            seams += 1
            var t = island.blends[i]
            if t.weight > 0:
                seamed += 1
            # Crater-rim specific: slope↔rim seams must be feathered (the
            # documented 0002 "teeth" defect location).
            var rim_side = biome == BIOME_CALDERA_RIM
            var slope_neighbour = False
            if ix > 0 and island.biomes[i - 1] == BIOME_VOLCANIC_SLOPE:
                slope_neighbour = True
            if ix + 1 < n and island.biomes[i + 1] == BIOME_VOLCANIC_SLOPE:
                slope_neighbour = True
            if iz > 0 and island.biomes[i - n] == BIOME_VOLCANIC_SLOPE:
                slope_neighbour = True
            if iz + 1 < n and island.biomes[i + n] == BIOME_VOLCANIC_SLOPE:
                slope_neighbour = True
            if biome == BIOME_VOLCANIC_SLOPE and _rim_adjacent(island.biomes, ix, iz, n):
                if t.weight > 0:
                    rim_feathered += 1
                else:
                    raise Error(
                        "slope column at crater rim unfeathered ("
                        + String(ix) + "," + String(iz) + ")"
                    )
            if rim_side and slope_neighbour:
                _check(t.weight > 0, "rim seam column not feathered")
    _check(seams > 0, "seed-1 has material seams")
    _check(seamed > 0, "seed-1 seams carry feather weights")
    _check(rim_feathered > 0, "crater-rim (slope↔rim) feather band exists")


def _rim_adjacent(biomes: List[Int], ix: Int, iz: Int, n: Int) -> Bool:
    """True when any 4-neighbour of (ix, iz) is CALDERA_RIM."""
    if ix > 0 and biomes[iz * n + (ix - 1)] == BIOME_CALDERA_RIM:
        return True
    if ix + 1 < n and biomes[iz * n + (ix + 1)] == BIOME_CALDERA_RIM:
        return True
    if iz > 0 and biomes[(iz - 1) * n + ix] == BIOME_CALDERA_RIM:
        return True
    if iz + 1 < n and biomes[(iz + 1) * n + ix] == BIOME_CALDERA_RIM:
        return True
    return False


def main() raises:
    TestSuite.discover_tests[
        (
            test_feather_band_width_and_monotonic_ramp,
            test_blend_pairs_restricted_to_adjacent_biome_sets,
            test_lava_columns_never_blend,
            test_dither_bit_identical_across_same_seed_runs,
            test_seed1_no_cross_biome_material_anywhere,
            test_seed1_crater_rim_has_feather_band,
        )
    ]().run()
