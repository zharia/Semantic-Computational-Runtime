# IslandSubject — the volcanic island world slice (Sprint 01).
#
# Owns: deterministic height grid (SCR-LIB-FIELD sampling via
# synthesis.heightfield.bilinear_sample), biome/surface-material grids
# (SCR-LIB-SPATIAL-VOXEL-SYNTHESIS pipeline), spawn point (beach band),
# chunked terrain meshes (104_contract §4.3 TERRAIN payload source), and the
# set of material codes present (MATERIALS section source).
#
# Build is a pure function of the seed: same seed ⇒ identical grids, spawn
# and meshes (SCR-LIB-MATH-NOISE §4).

from std.collections import List
from std.math import sqrt, abs

from synthesis.noise import NoiseContext
from synthesis.heightfield import height_at_cell, bilinear_sample
from synthesis.voxel import (
    voxel_synthesis_pipeline,
    classify_biome,
    BIOME_VOLCANIC_SLOPE,
    FEATURE_NONE,
)
from synthesis.blend import BlendTuple, compute_blends
from synthesis.quench import run_quench_pass
from materials.catalog import MAT_BEDROCK, MAT_WATER, MAT_VOCAB_COUNT, MAT_BASALT
from sim.parameters import (
    GRID_N,
    CELL_SIZE,
    TERRAIN_CHUNK_CELLS,
    SEA_LEVEL,
    SPAWN_BEACH_OFFSET,
    SPAWN_SEARCH_RADIUS_MIN,
    SPAWN_SEARCH_RADIUS_MAX,
    LATTICE_Y_OFFSET,
)


struct TerrainChunk(Copyable, Movable, Deinitable):
    """One chunk's indexed mesh (104_contract §4.3 TERRAIN record)."""
    var origin_x: Float64
    var origin_y: Float64
    var origin_z: Float64
    var vertices: List[Float32]  # 3·V, world units
    var normals: List[Float32]  # 3·V, unit length
    var material_ids: List[UInt32]  # V voxel codes (per vertex)
    var blends: List[BlendTuple]  # V boundary blend tuples (milestone_0005)
    var indices: List[UInt32]  # I, multiples of 3, CCW front faces

    def __init__(out self, origin_x: Float64, origin_y: Float64, origin_z: Float64):
        self.origin_x = origin_x
        self.origin_y = origin_y
        self.origin_z = origin_z
        self.vertices = List[Float32]()
        self.normals = List[Float32]()
        self.material_ids = List[UInt32]()
        self.blends = List[BlendTuple]()
        self.indices = List[UInt32]()

    def __deinit__(deinit self):
        pass

    def vert_count(self) -> Int:
        return len(self.vertices) // 3

    def idx_count(self) -> Int:
        return len(self.indices)


struct IslandSubject(Movable, Deinitable):
    var seed: UInt32
    var heights: List[Float64]  # GRID_N² cell-center heights (world y)
    var biomes: List[Int]  # GRID_N² biome codes (voxel.mojo)
    var surface_materials: List[UInt32]  # GRID_N² voxel codes
    var blends: List[BlendTuple]  # GRID_N² boundary blend tuples (§3.4)
    var chunks: List[TerrainChunk]
    var spawn_x: Float64
    var spawn_y: Float64
    var spawn_z: Float64
    var peak_height: Float64
    var used_materials: List[UInt32]  # distinct codes present, sorted asc
    var chunk_count: Int
    # World-gen quench accounting (synthesis/quench.mojo; not a wire section).
    var quench_count: Int
    var quench_steam_units: Int
    var quench_energy_j: Float64

    def __init__(out self, seed: UInt32):
        self.seed = seed
        self.heights = List[Float64]()
        self.biomes = List[Int]()
        self.surface_materials = List[UInt32]()
        self.blends = List[BlendTuple]()
        self.chunks = List[TerrainChunk]()
        self.spawn_x = 0.0
        self.spawn_y = 0.0
        self.spawn_z = 0.0
        self.peak_height = 0.0
        self.used_materials = List[UInt32]()
        self.chunk_count = 0
        self.quench_count = 0
        self.quench_steam_units = 0
        self.quench_energy_j = 0.0

    def __deinit__(deinit self):
        pass

    def height_at(self, x: Float64, z: Float64) -> Float64:
        """SCR-LIB-FIELD: terrain height by bilinear interpolation of the grid."""
        return bilinear_sample(self.heights, x, z)

    def cell_index(self, ix: Int, iz: Int) -> Int:
        return iz * GRID_N + ix


def build_island(seed: UInt32) raises -> IslandSubject:
    var island = IslandSubject(seed)
    var ctx = NoiseContext(seed)

    # --- grids: height, biome, surface material ---------------------------
    var n_cells = GRID_N * GRID_N
    var peak = -1.0e9
    for iz in range(GRID_N):
        for ix in range(GRID_N):
            var wx = (Float64(ix) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
            var wz = (Float64(iz) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
            var h = height_at_cell(ctx, ix, iz)
            var r = sqrt(wx * wx + wz * wz)
            var biome = classify_biome(wx, wz, h, r)
            var col = voxel_synthesis_pipeline(ix, iz, biome, FEATURE_NONE, h, ctx)
            # Surface cell = the segment covering the lattice surface height.
            var surface_y = Int(h + LATTICE_Y_OFFSET + 0.5)
            if surface_y < 1:
                surface_y = 1
            var surf_mat = col.material_at(surface_y)
            island.heights.append(h)
            island.biomes.append(biome)
            island.surface_materials.append(surf_mat)
            if h > peak:
                peak = h
    island.peak_height = peak

    # --- boundary blend tuples (milestone_0005 §3.4, seeded, pure) --------
    island.blends = compute_blends(
        island.surface_materials, island.biomes, ctx
    )

    # --- world-gen quench evaluation (material_reactions.json verbatim) ---
    var quench = run_quench_pass(island.biomes, island.heights, GRID_N, ctx)
    island.quench_count = quench.count()
    island.quench_steam_units = quench.steam_units
    island.quench_energy_j = quench.energy_j

    # --- spawn: first beach-band cell in scan order (deterministic) -------
    var found = False
    var fx = 0.0
    var fz = 0.0
    var fh = 0.0
    for iz in range(GRID_N):
        for ix in range(GRID_N):
            var h = island.heights[iz * GRID_N + ix]
            if h < SPAWN_BEACH_OFFSET - 1.0 or h > SPAWN_BEACH_OFFSET + 1.0:
                continue
            var wx = (Float64(ix) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
            var wz = (Float64(iz) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
            var r = sqrt(wx * wx + wz * wz)
            if r < SPAWN_SEARCH_RADIUS_MIN or r > SPAWN_SEARCH_RADIUS_MAX:
                continue
            fx = wx
            fz = wz
            fh = h
            found = True
            break
        if found:
            break
    if not found:
        # Fallback: nearest-to-offset height inside the search annulus.
        var best = 1.0e9
        for iz in range(GRID_N):
            for ix in range(GRID_N):
                var h = island.heights[iz * GRID_N + ix]
                var wx = (Float64(ix) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
                var wz = (Float64(iz) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
                var r = sqrt(wx * wx + wz * wz)
                if r < SPAWN_SEARCH_RADIUS_MIN or r > SPAWN_SEARCH_RADIUS_MAX:
                    continue
                var d = abs(h - SPAWN_BEACH_OFFSET)
                if d < best:
                    best = d
                    fx = wx
                    fz = wz
                    fh = h
    island.spawn_x = fx
    island.spawn_z = fz
    island.spawn_y = fh  # feet on the beach surface (eye = +EYE_HEIGHT)

    # --- chunk meshes ------------------------------------------------------
    var chunk_cells = TERRAIN_CHUNK_CELLS
    var chunks_per_side = GRID_N // chunk_cells
    # Corner heights for normals: (N+1)² bilinear samples at corner coords.
    var corner_n = GRID_N + 1
    var corners = List[Float64]()
    for j in range(corner_n):
        for i in range(corner_n):
            var cx = (Float64(i) - Float64(GRID_N) / 2.0) * CELL_SIZE
            var cz = (Float64(j) - Float64(GRID_N) / 2.0) * CELL_SIZE
            corners.append(bilinear_sample(island.heights, cx, cz))

    var chunks = List[TerrainChunk]()
    for cz in range(chunks_per_side):
        for cx in range(chunks_per_side):
            var base_ix = cx * chunk_cells
            var base_iz = cz * chunk_cells
            var origin_x = (Float64(base_ix) - Float64(GRID_N) / 2.0) * CELL_SIZE
            var origin_z = (Float64(base_iz) - Float64(GRID_N) / 2.0) * CELL_SIZE
            var chunk = TerrainChunk(origin_x, 0.0, origin_z)
            # Vertices: (chunk_cells+1)² grid of corner samples.
            var vn = chunk_cells + 1
            for j in range(vn):
                for i in range(vn):
                    var gi = base_ix + i
                    var gj = base_iz + j
                    var wx = (Float64(gi) - Float64(GRID_N) / 2.0) * CELL_SIZE
                    var wz = (Float64(gj) - Float64(GRID_N) / 2.0) * CELL_SIZE
                    var hy = corners[gj * corner_n + gi]
                    chunk.vertices.append(Float32(wx))
                    chunk.vertices.append(Float32(hy))
                    chunk.vertices.append(Float32(wz))
                    # Normal from central differences over corner heights
                    # (one-sided at the map edges): n = normalize(-dx, 1, -dz).
                    var il = gi - 1
                    if il < 0:
                        il = 0
                    var ir = gi + 1
                    if ir > corner_n - 1:
                        ir = corner_n - 1
                    var jd = gj - 1
                    if jd < 0:
                        jd = 0
                    var ju = gj + 1
                    if ju > corner_n - 1:
                        ju = corner_n - 1
                    var span_x_l = Float64(gi - il)
                    if span_x_l == 0.0:
                        span_x_l = 1.0
                    var span_x_r = Float64(ir - gi)
                    if span_x_r == 0.0:
                        span_x_r = 1.0
                    var span_z_d = Float64(gj - jd)
                    if span_z_d == 0.0:
                        span_z_d = 1.0
                    var span_z_u = Float64(ju - gj)
                    if span_z_u == 0.0:
                        span_z_u = 1.0
                    var here = corners[gj * corner_n + gi]
                    var ddx_l = (here - corners[gj * corner_n + il]) / (CELL_SIZE * span_x_l)
                    var ddx_r = (corners[gj * corner_n + ir] - here) / (CELL_SIZE * span_x_r)
                    var ddx = (ddx_l + ddx_r) * 0.5
                    var ddz_d = (here - corners[jd * corner_n + gi]) / (CELL_SIZE * span_z_d)
                    var ddz_u = (corners[ju * corner_n + gi] - here) / (CELL_SIZE * span_z_u)
                    var ddz = (ddz_d + ddz_u) * 0.5
                    var nx = -ddx
                    var ny = 1.0
                    var nz = -ddz
                    var len_n = sqrt(nx * nx + ny * ny + nz * nz)
                    chunk.normals.append(Float32(nx / len_n))
                    chunk.normals.append(Float32(ny / len_n))
                    chunk.normals.append(Float32(nz / len_n))
                    # Per-vertex material: surface material of the owning cell
                    # (encoder maps the voxel code to the catalog id).
                    var cell_ix = gi
                    if cell_ix > GRID_N - 1:
                        cell_ix = GRID_N - 1
                    var cell_iz = gj
                    if cell_iz > GRID_N - 1:
                        cell_iz = GRID_N - 1
                    chunk.material_ids.append(
                        island.surface_materials[cell_iz * GRID_N + cell_ix]
                    )
                    chunk.blends.append(
                        island.blends[cell_iz * GRID_N + cell_ix]
                    )
            # Indices: two CCW triangles per cell quad (+y front faces):
            # (a, c, b) and (b, c, d) with a=(i,j), b=(i+1,j), c=(i,j+1).
            for j in range(chunk_cells):
                for i in range(chunk_cells):
                    var a = UInt32(j * vn + i)
                    var b = a + 1
                    var c = a + UInt32(vn)
                    var d = c + 1
                    chunk.indices.append(a)
                    chunk.indices.append(c)
                    chunk.indices.append(b)
                    chunk.indices.append(b)
                    chunk.indices.append(c)
                    chunk.indices.append(d)
            chunks.append(chunk^)
    island.chunks = chunks^
    island.chunk_count = len(island.chunks)

    # --- material vocabulary present ---------------------------------------
    var present = List[UInt32]()
    present.append(MAT_BEDROCK)
    var has_water = False
    for i in range(n_cells):
        var code = island.surface_materials[i]
        _insert_distinct(present, code)
        if island.heights[i] < SEA_LEVEL:
            has_water = True
    if has_water:
        _insert_distinct(present, MAT_WATER)
    island.used_materials = present^
    return island^


def _catalog_id_for_vertex(code: UInt32) -> UInt32:
    # Catalog id resolution happens at projection time (encoder owns the
    # catalog); islands store voxel codes. Mesh building only needs a
    # placeholder here — replaced in world construction? No: contract wants
    # catalog ids in the TERRAIN payload, so map via catalog at encode.
    # Kept as voxel code; encoder translates.
    return code


def _insert_distinct(mut sorted_list: List[UInt32], value: UInt32):
    for i in range(len(sorted_list)):
        if sorted_list[i] == value:
            return
    # insertion sort by value to keep ascending order
    var pos = len(sorted_list)
    for i in range(len(sorted_list)):
        if sorted_list[i] > value:
            pos = i
            break
    sorted_list.append(value)
    if pos < len(sorted_list) - 1:
        var last = sorted_list[len(sorted_list) - 1]
        for i in range(len(sorted_list) - 1, pos, -1):
            sorted_list[i] = sorted_list[i - 1]
        sorted_list[pos] = last
