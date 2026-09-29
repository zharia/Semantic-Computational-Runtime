# Terrain height field — spectral synthesis over the volcanic island
# (SCR-LIB-MATH-NOISE §2.4 fBm + §2.3 ridged consumed through the
# SpectralSynthesizer contract; SCR-LIB-FIELD sampling via
# `height_at` bilinear interpolation of the stored grid).
#
# Profile (all tunables in sim/parameters.mojo, AP-7):
#   land(r)   = PEAK_HEIGHT * max(0, 1 - r/ISLAND_RADIUS)     (cone)
#   deep(r)   = -OCEAN_FLOOR_DEPTH * smoothstep(SHORE, HALF, r)
#   rim(r)    = CALDERA_RIM_BUMP * gauss(r; CALDERA_RIM_RADIUS, RIM_WIDTH)
#   detail    = HEIGHT_DETAIL_AMP * fbm + RIDGE_DETAIL_AMP * (ridged - 0.5)
#   crater    = inside r < 22u blend to CALDERA_FLOOR (+ small fbm)
# Pure function of (x, z, NoiseContext): deterministic, seed-sensitive
# (SCR-LIB-MATH-NOISE §4 invariants 1 and 3).

from std.math import sqrt, exp
from synthesis.noise import NoiseContext, fbm, ridged
from sim.parameters import (
    ISLAND_RADIUS,
    PEAK_HEIGHT,
    CALDERA_RIM_RADIUS,
    CALDERA_RIM_WIDTH,
    CALDERA_RIM_BUMP,
    CALDERA_FLOOR,
    OCEAN_FLOOR_DEPTH,
    HEIGHT_DETAIL_AMP,
    RIDGE_DETAIL_AMP,
    GRID_N,
    CELL_SIZE,
    NOISE_BASE_FREQUENCY,
    NOISE_OCTAVES,
    NOISE_LACUNARITY,
    NOISE_GAIN,
    RIDGE_OCTAVES,
    SEA_LEVEL,
)

# Map half-extent (u) — grid covers [-HALF, +HALF] in x and z.
comptime MAP_HALF_EXTENT: Float64 = 256.0 / 2.0  # GRID_N * CELL_SIZE / 2 = 128
comptime SHORE_FALLOFF_START: Float64 = 80.0  # land starts losing to seabed here
comptime CRATER_BLEND_INNER: Float64 = 14.0  # r ≤ this ⇒ pure crater floor
comptime CRATER_BLEND_OUTER: Float64 = 22.0  # r ≥ this ⇒ untouched profile


def _smoothstep(edge0: Float64, edge1: Float64, x: Float64) -> Float64:
    if x <= edge0:
        return 0.0
    if x >= edge1:
        return 1.0
    var t = (x - edge0) / (edge1 - edge0)
    return t * t * (3.0 - 2.0 * t)


def _clamp01(v: Float64) -> Float64:
    if v < 0.0:
        return 0.0
    if v > 1.0:
        return 1.0
    return v


def terrain_height(ctx: NoiseContext, x: Float64, z: Float64) raises -> Float64:
    """Terrain surface height in world units (sea level = 0) at (x, z)."""
    var r = sqrt(x * x + z * z)
    var land = 0.0
    if r < ISLAND_RADIUS:
        land = PEAK_HEIGHT * (1.0 - r / ISLAND_RADIUS)
    var deep = -OCEAN_FLOOR_DEPTH * _smoothstep(SHORE_FALLOFF_START, MAP_HALF_EXTENT, r)
    var h = land + deep

    # Caldera rim lift (gaussian ring).
    var rim_t = (r - CALDERA_RIM_RADIUS) / CALDERA_RIM_WIDTH
    var rim = CALDERA_RIM_BUMP * exp(-(rim_t * rim_t))
    h += rim

    # Spectral detail: fBm + ridged (ridged centered at 0.5).
    var f = NOISE_BASE_FREQUENCY
    var detail = HEIGHT_DETAIL_AMP * Float64(
        fbm(ctx, x * f, 0.0, z * f, NOISE_OCTAVES, NOISE_LACUNARITY, NOISE_GAIN)
    )
    detail += RIDGE_DETAIL_AMP * (
        Float64(ridged(ctx, x * f, 0.0, z * f, RIDGE_OCTAVES, NOISE_LACUNARITY, NOISE_GAIN))
        - 0.5
    )
    h += detail

    # Crater interior blend to a near-sea-level lava floor.
    if r < CRATER_BLEND_OUTER:
        var floor_detail = 0.5 * Float64(
            fbm(
                ctx,
                x * f * 2.0,
                11.0,
                z * f * 2.0,
                NOISE_OCTAVES,
                NOISE_LACUNARITY,
                NOISE_GAIN,
            )
        )
        var target = CALDERA_FLOOR + floor_detail
        var t = _smoothstep(CRATER_BLEND_INNER, CRATER_BLEND_OUTER, r)
        h = target * (1.0 - t) + h * t
    return h


def height_at_cell(ctx: NoiseContext, ix: Int, iz: Int) raises -> Float64:
    """Height at grid cell (ix, iz) center, world coordinates."""
    var x = cell_center_x(ix)
    var z = cell_center_z(iz)
    return terrain_height(ctx, x, z)


def cell_center_x(ix: Int) -> Float64:
    """World x of grid column ix's cell center (row-major grid, §3.2)."""
    return (Float64(ix) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE


def cell_center_z(iz: Int) -> Float64:
    """World z of grid row iz's cell center (row-major grid, §3.2)."""
    return (Float64(iz) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE


def bilinear_sample(
    heights: List[Float64], x: Float64, z: Float64
) -> Float64:
    """SCR-LIB-FIELD sampling: bilinear interpolation over the stored grid.
    Cell i holds the height at its center; out-of-range coordinates clamp
    to the edge cells (field is defined only on the grid domain)."""
    # Cell-center coordinates: c_i = (i + 0.5 - N/2) * CELL.
    var fx = x / CELL_SIZE + Float64(GRID_N) / 2.0 - 0.5
    var fz = z / CELL_SIZE + Float64(GRID_N) / 2.0 - 0.5
    var x0 = Int(_floorf(fx))
    var z0 = _floorf_int(fz)
    var tx = fx - Float64(x0)
    var tz = fz - Float64(z0)
    var x1 = x0 + 1
    var z1 = z0 + 1
    if x0 < 0:
        x0 = 0
        x1 = 0
        tx = 0.0
    if z0 < 0:
        z0 = 0
        z1 = 0
        tz = 0.0
    if x1 > GRID_N - 1:
        x1 = GRID_N - 1
        x0 = x1
        tx = 0.0
    if z1 > GRID_N - 1:
        z1 = GRID_N - 1
        z0 = z1
        tz = 0.0
    var h00 = heights[_idx(x0, z0)]
    var h10 = heights[_idx(x1, z0)]
    var h01 = heights[_idx(x0, z1)]
    var h11 = heights[_idx(x1, z1)]
    var a = h00 * (1.0 - tx) + h10 * tx
    var b = h01 * (1.0 - tx) + h11 * tx
    return a * (1.0 - tz) + b * tz


def _idx(ix: Int, iz: Int) -> Int:
    return iz * GRID_N + ix


def _floorf(v: Float64) -> Float64:
    var i = v.__int__()
    if Float64(i) > v:
        return Float64(i - 1)
    return Float64(i)


def _floorf_int(v: Float64) -> Int:
    return Int(_floorf(v))


def world_to_cell(x: Float64, z: Float64) -> Tuple[Int, Int]:
    """Nearest cell indices for a world position (clamped by caller)."""
    var fx = x / CELL_SIZE + Float64(GRID_N) / 2.0 - 0.5
    var fz = z / CELL_SIZE + Float64(GRID_N) / 2.0 - 0.5
    return (_floorf_int(fx), _floorf_int(fz))
