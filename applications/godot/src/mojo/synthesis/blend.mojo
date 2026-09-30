# Boundary material blending — milestone_0005 §3.4, inside the SCR-LIB-
# SPATIAL-VOXEL-SYNTHESIS pipeline (AP-20: material assignment — including
# blended boundary weights — originates HERE, never in the adapter/shader).
#
# Contract (§1.1 locked decision (b) + §3.4):
#   - boundary detection: adjacent columns whose surface materials differ;
#   - within FEATHER_WIDTH_CELLS of a boundary each column carries a tuple
#     (dominant, blend partner, weight 0..255 ⇒ 0..1) on a base ramp
#     (FEATHER − d)/FEATHER plus deterministic noise dither from the seeded
#     noise_context (same family as 0002 synthesis);
#   - blend pairs are restricted to the two adjacent biomes' permitted
#     surface sets (Synthesis §2 cross-biome rule) — enforced here, at the
#     boundary edge, before any weight is assigned;
#   - lava never blends (0003: CALDERA_LAKE → LAVA; §3.6 — quench/obsidian
#     rules govern lava adjacency, feathering must not touch it);
#   - bedrock / sea-level / write-once / purity invariants of §4 are
#     untouched: this pass only reads the (materials, biomes) grids and
#     writes a separate tuple grid.
#
# Vertex carrying: sim/island.mojo copies the owning cell's tuple onto every
# mesh vertex (dominant id groups surfaces exactly as schema 3 did); the
# encoder maps voxel codes → stable catalog ids (104_contract §4.3 §3).

from std.collections import List

from synthesis.noise import NoiseContext, gradient_noise
from synthesis.heightfield import cell_center_x, cell_center_z
from synthesis.voxel import biome_surface_materials
from materials.catalog import MAT_LAVA
from sim.parameters import (
    GRID_N,
    FEATHER_WIDTH_CELLS,
    BLEND_DITHER_AMP,
    BLEND_DITHER_FREQUENCY,
)

# Noise-domain channel for the dither (distinct from surface_material_for's
# channel 7.0 so the two seeded draws are independent).
comptime DITHER_NOISE_CHANNEL: Float64 = 13.0


struct BlendTuple(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Per-column boundary blend tuple (§3.4); stride-neutral on the wire
    (u8 dominant, u8 partner, u8 weight, u8 pad)."""

    var material: UInt32  # dominant voxel code (this column's surface)
    var blend: UInt32  # partner voxel code (== material when weight == 0)
    var weight: UInt8  # 0..255 ⇒ mix toward `blend`

    def __init__(out self, material: UInt32, blend: UInt32, weight: UInt8):
        self.material = material
        self.blend = blend
        self.weight = weight

    def __deinit__(deinit self):
        pass


def _in_row(code: UInt32, biome: Int) raises -> Bool:
    """code ∈ permitted surface set of biome (Synthesis §2)."""
    var row = biome_surface_materials(biome)
    for i in range(len(row)):
        if row[i] == code:
            return True
    return False


def _check_edge_pair(
    mat_u: UInt32, biome_u: Int, mat_v: UInt32, biome_v: Int
) raises:
    """Blend-pair invariant (milestone_0005 §6.4), enforced at the single
    point where a pair is born: the two materials must each sit in their own
    biome's §2 row, so every partner later handed out belongs to the
    adjacent biome's permitted set — never e.g. sand inside CALDERA_RIM."""
    if not _in_row(mat_u, biome_u):
        raise Error(
            "blend edge: dominant material " + String(Int(mat_u))
            + " outside biome " + String(biome_u) + " surface set"
        )
    if not _in_row(mat_v, biome_v):
        raise Error(
            "blend edge: partner material " + String(Int(mat_v))
            + " outside biome " + String(biome_v) + " surface set"
        )


def compute_blends(
    materials: List[UInt32], biomes: List[Int], ctx: NoiseContext
) raises -> List[BlendTuple]:
    """Boundary detection + feather band + dither over the surface grid.

    materials/biomes are GRID_N² row-major (iz · GRID_N + ix). Returns a
    GRID_N² tuple grid. Pure function of its inputs + the seeded noise
    context (Synthesis §4 invariant 1)."""
    var mask = List[UInt8]()
    for _i in range(GRID_N * GRID_N):
        mask.append(0)
    return compute_blends_masked(materials, biomes, ctx, mask)


def compute_blends_masked(
    materials: List[UInt32],
    biomes: List[Int],
    ctx: NoiseContext,
    unblendable: List[UInt8],
) raises -> List[BlendTuple]:
    """compute_blends with cells marked unblendable (0007 edit path).

    An EDITED column carries an identity tuple and never seeds, receives or
    propagates a blend edge: the placed material may sit outside the biome's
    §2 row (0007 §3.2 hotbar place), so the §6.4 pair invariant is preserved
    by keeping feathering off edited columns entirely — the edge is simply
    never born, never checked, never weighted. Non-edited cells behave
    exactly like compute_blends (all-zero mask ⇒ identical bytes)."""
    var n = GRID_N
    if len(materials) != n * n or len(biomes) != n * n:
        raise Error(
            "compute_blends expects " + String(n * n) + " cells, got "
            + String(len(materials)) + "/" + String(len(biomes))
        )
    if len(unblendable) != n * n:
        raise Error(
            "compute_blends_masked expects " + String(n * n) + " mask cells, got "
            + String(len(unblendable))
        )

    # Identity tuples: no blend unless a boundary band reaches the cell.
    var out = List[BlendTuple]()
    for i in range(n * n):
        out.append(BlendTuple(materials[i], materials[i], 0))

    var dist = List[Int]()
    for _i in range(n * n):
        dist.append(-1)

    var partner = List[UInt32]()
    for _i in range(n * n):
        partner.append(materials[_i])

    # --- Seed pass: cells adjacent to a differing material (dist 0). -------
    # Fixed neighbour order (−x, +x, −z, +z) keeps partner choice and the
    # later BFS expansion order deterministic for a given seed.
    var queue = List[Int]()
    for iz in range(n):
        for ix in range(n):
            var i = iz * n + ix
            if unblendable[i] != 0:
                continue  # edited column: identity tuple, edges never born
            var m = materials[i]
            if m == MAT_LAVA:
                continue  # lava columns never blend (§3.6)
            var seeds = False
            for k in range(4):
                var nx = ix + _dx(k)
                var nz = iz + _dz(k)
                if nx < 0 or nx >= n or nz < 0 or nz >= n:
                    continue
                var j = nz * n + nx
                if unblendable[j] != 0:
                    continue  # never feather across an edited column
                var mn = materials[j]
                if mn == m:
                    continue
                if mn == MAT_LAVA:
                    continue  # lava edge: quench rules, not feathering
                _check_edge_pair(m, biomes[i], mn, biomes[j])
                dist[i] = 0
                partner[i] = mn
                seeds = True
                break
            if seeds:
                queue.append(i)

    # --- BFS: distance-to-boundary + partner carried inside the material --
    # (a partner only propagates across cells of the SAME material, so it
    # can never leak in from an unrelated boundary).
    var head = 0
    while head < len(queue):
        var c = queue[head]
        head += 1
        var ic = c % n
        var jc = c // n
        var d = dist[c]
        for k in range(4):
            var nx = ic + _dx(k)
            var nz = jc + _dz(k)
            if nx < 0 or nx >= n or nz < 0 or nz >= n:
                continue
            var j = nz * n + nx
            if unblendable[j] != 0:
                continue  # edited columns stay unfeathered
            if dist[j] >= 0:
                continue  # already seeded/visited
            if materials[j] != materials[c]:
                continue  # stay inside the material region
            if materials[j] == MAT_LAVA:
                continue
            dist[j] = d + 1
            partner[j] = partner[c]
            queue.append(j)

    # --- Weight ramp + deterministic dither --------------------------------
    for iz in range(n):
        for ix in range(n):
            var i = iz * n + ix
            if unblendable[i] != 0:
                continue  # identity tuple (material, material, 0)
            var d = dist[i]
            if d < 0 or d >= FEATHER_WIDTH_CELLS:
                continue
            var base = Float64(FEATHER_WIDTH_CELLS - d) / Float64(
                FEATHER_WIDTH_CELLS
            )
            var wx = cell_center_x(ix)
            var wz = cell_center_z(iz)
            var nz = Float64(
                gradient_noise(
                    ctx,
                    wx * BLEND_DITHER_FREQUENCY,
                    DITHER_NOISE_CHANNEL,
                    wz * BLEND_DITHER_FREQUENCY,
                )
            )
            var w = base + BLEND_DITHER_AMP * nz
            if w < 0.0:
                w = 0.0
            if w > 1.0:
                w = 1.0
            var q = Int(w * 255.0 + 0.5)  # round-to-nearest ⇒ 0..255
            if q > 255:
                q = 255
            out[i] = BlendTuple(materials[i], partner[i], UInt8(q))
    return out^


def _dx(k: Int) -> Int:
    if k == 0:
        return -1
    if k == 1:
        return 1
    return 0


def _dz(k: Int) -> Int:
    if k == 2:
        return -1
    if k == 3:
        return 1
    return 0
