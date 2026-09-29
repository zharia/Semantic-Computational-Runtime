# Shoreline foam field — SCR-LIB-RENDER-WATER §3 implemented VERBATIM
# (milestone_0005 §3.3). Sim owns the field (§1.1 locked decision (a)):
#
#   Δy = y_water(x, z, t) − y_terrain(x, z)
#   Foam_shore = clamp(1 − Δy / d_foam, 0, 1)² · (0.6 + 0.4·sin(6.0·Δy − 4.0·t))
#   d_foam = FOAM_DEPTH_M = 1.8 u   (sim/parameters.mojo, AP-7)
#
# Zone gates (§3.3):
#   - deep water: Δy ≥ FOAM_DEPTH_M ⇒ 0 (the clamp already yields 0),
#   - land above the max wave reach (y_t ≥ sea_level + wave amplitude) ⇒ 0
#     (the formula alone would light up dry beach cells: Δy < 0 ⇒ clamp = 1).
#
# AP-19: this file is the ONLY place the shore formula lives; the adapter /
# shader shades the delivered field and never re-derives terrain-vs-water
# depth. AP-22: crest whitecaps remain the separate display path
# (ocean/gerstner.mofo `foam_factor`, Jacobian/height thresholds) — disjoint
# zones, two authorities by definition.
#
# Purity: `compute_foam_field` is a pure function of (height grid, ocean
# state, t = simulation_time). The world recomputes it once per fixed tick;
# the snapshot projection only reads it.

from std.collections import List
from std.math import sin

from ocean.gerstner import OceanState, wave_height
from synthesis.heightfield import cell_center_x, cell_center_z
from sim.parameters import (
    GRID_N,
    SEA_LEVEL,
    WAVE_AMPLITUDE,
    FOAM_DEPTH_M,
)

# Max vertical wave displacement above sea level (y = sea + A·cosθ): cells
# whose surface sits at or above this can never be reached by the water.
comptime MAX_WAVE_REACH: Float64 = SEA_LEVEL + WAVE_AMPLITUDE


def shore_foam(dy: Float64, t: Float64) -> Float64:
    """Library shore-foam formula (SCR-LIB-RENDER-WATER §3) at one (Δy, t).

    Exact operation order — clamp c = clamp(1 − Δy/d_foam, 0, 1), then
    c² · (0.6 + 0.4·sin(6.0·Δy − 4.0·t)) — so conformance tests compare
    bit-for-bit against the same expression. Returns a value in [0, 1]."""
    if dy >= FOAM_DEPTH_M:
        return 0.0  # deep water: clamp term is 0 (identical to the formula)
    var c = 1.0 - dy / FOAM_DEPTH_M
    if c < 0.0:
        c = 0.0
    if c > 1.0:
        c = 1.0
    return c * c * (0.6 + 0.4 * sin(6.0 * dy - 4.0 * t))


def shore_foam_cell(y_terrain: Float64, y_water: Float64, t: Float64) -> Float64:
    """Shore foam at one grid cell: library formula + the §3.3 zone gates."""
    if y_terrain >= MAX_WAVE_REACH:
        return 0.0  # land above the max wave reach: no shore contact possible
    return shore_foam(y_water - y_terrain, t)


def compute_foam_field(
    heights: List[Float64], ocean: OceanState, t: Float64
) raises -> List[Float32]:
    """FOAM field over the full terrain grid: GRID_N² f32 ∈ [0,1],
    row-major (iz · GRID_N + ix) at cell centers aligned with the terrain
    grid (104_contract §4.3 §9). Pure function of world state."""
    if len(heights) != GRID_N * GRID_N:
        raise Error(
            "foam field expects " + String(GRID_N * GRID_N) + " heights, got "
            + String(len(heights))
        )
    var out = List[Float32]()
    for iz in range(GRID_N):
        for ix in range(GRID_N):
            var wx = cell_center_x(ix)
            var wz = cell_center_z(iz)
            var y_t = heights[iz * GRID_N + ix]
            var y_w = wave_height(ocean, wx, wz, t)
            out.append(Float32(shore_foam_cell(y_t, y_w, t)))
    return out^


def foam_nonzero_count(field: List[Float32]) -> Int:
    """Cells carrying any shore foam (diagnostics / tests)."""
    var n = 0
    for i in range(len(field)):
        if field[i] > 0.0:
            n += 1
    return n
