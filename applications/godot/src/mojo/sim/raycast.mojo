# Sim-owned ray-march hit test over the height field (milestone_0007 §1.1,
# AP-12): the CELL and MATERIAL of any edit derive solely from here — the
# client submits `op` + `select_slot` only.
#
# Model (SCR-LIB-FIELD sampling, world frame explicit):
#   origin  = player eye (feet + EYE_HEIGHT)
#   dir     = look forward from (yaw, pitch) — yaw 0 faces −Z, pitch +up
#   march   = fixed RAY_STEP samples along the ray up to RAY_RANGE
#   hit     = first sample whose ray y ≤ terrain height at (x, z)
#   refine  = bisection inside the last (outside, inside] bracket
# The height field is the authoritative surface (water is a column SEGMENT
# above it, not stored in the grid) — so the ray sees the terrain surface,
# which is exactly what a dig/place targets. A miss returns all zeros
# (HUD shows "SKY / AIR").
#
# Determinism: pure function of (island, pose, catalog) — no RNG, no clock.

from std.math import sin, cos, sqrt

from sim.island import IslandSubject
from materials.catalog import MaterialCatalog
from synthesis.heightfield import world_to_cell
from sim.parameters import (
    GRID_N,
    RAY_RANGE,
    RAY_STEP,
    RAY_REFINE_ITERS,
    LATTICE_Y_OFFSET,
    EYE_HEIGHT,
)


struct RayHit(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """TARGET section source (0007 §3.3): hit flag, catalog material id,
    world-frame hit position, and the targeted column in lattice space."""

    var hit: Bool
    var material_id: UInt32  # stable catalog id (0 on miss)
    var hit_x: Float64
    var hit_y: Float64
    var hit_z: Float64
    var cell_x: Int
    var cell_lattice_y: Int  # lattice y of the column's surface cell
    var cell_z: Int

    def __init__(out self):
        self.hit = False
        self.material_id = 0
        self.hit_x = 0.0
        self.hit_y = 0.0
        self.hit_z = 0.0
        self.cell_x = 0
        self.cell_lattice_y = 0
        self.cell_z = 0

    def __deinit__(deinit self):
        pass


def ray_miss() -> RayHit:
    """All-zero miss record (HUD reads "SKY / AIR")."""
    return RayHit()


def look_forward(yaw: Float64, pitch: Float64) -> Tuple[Float64, Float64, Float64]:
    """Unit look direction: yaw 0 faces −Z (sim/subjects.mojo convention),
    pitch positive looks up, pitch = −π/2 looks straight down."""
    var cp = cos(pitch)
    return (-sin(yaw) * cp, sin(pitch), -cos(yaw) * cp)


def _terrain_clearance(
    island: IslandSubject, ox: Float64, oy: Float64, oz: Float64,
    dx: Float64, dy: Float64, dz: Float64, t: Float64,
) -> Float64:
    """ray_y(t) − terrain_height(x(t), z(t)). ≤ 0 ⇒ inside/below terrain."""
    var px = ox + dx * t
    var py = oy + dy * t
    var pz = oz + dz * t
    return py - island.height_at(px, pz)


def _clamp_cell(v: Int) -> Int:
    if v < 0:
        return 0
    if v > GRID_N - 1:
        return GRID_N - 1
    return v


def raycast_heightfield(
    island: IslandSubject,
    origin_x: Float64,
    origin_y: Float64,
    origin_z: Float64,
    dir_x: Float64,
    dir_y: Float64,
    dir_z: Float64,
    catalog: MaterialCatalog,
) raises -> RayHit:
    """March the ray over the height field; return the first surface hit
    within RAY_RANGE, or an all-zero miss record."""
    var len_d = sqrt(dir_x * dir_x + dir_y * dir_y + dir_z * dir_z)
    if len_d <= 0.0:
        return ray_miss()
    var dx = dir_x / len_d
    var dy = dir_y / len_d
    var dz = dir_z / len_d

    var t_prev = 0.0
    var f_prev = _terrain_clearance(island, origin_x, origin_y, origin_z, dx, dy, dz, 0.0)
    if f_prev <= 0.0:
        # Eye already at/below the surface: target the column under the eye.
        return _hit_record(
            island, origin_x, origin_y, origin_z, catalog
        )

    var t = RAY_STEP
    while t <= RAY_RANGE:
        var f = _terrain_clearance(island, origin_x, origin_y, origin_z, dx, dy, dz, t)
        if f <= 0.0:
            # Bisect (t_prev, t] — f_prev > 0, f ≤ 0 preserved every step.
            var lo = t_prev
            var hi = t
            for _ in range(RAY_REFINE_ITERS):
                var mid = (lo + hi) * 0.5
                var fm = _terrain_clearance(
                    island, origin_x, origin_y, origin_z, dx, dy, dz, mid
                )
                if fm <= 0.0:
                    hi = mid
                else:
                    lo = mid
            return _hit_record(
                island,
                origin_x + dx * hi,
                origin_y + dy * hi,
                origin_z + dz * hi,
                catalog,
            )
        t_prev = t
        t += RAY_STEP
    return ray_miss()


def _hit_record(
    island: IslandSubject, hx: Float64, hy: Float64, hz: Float64,
    catalog: MaterialCatalog,
) raises -> RayHit:
    """Bind a hit position to its column: cell + lattice surface cell +
    catalog material id (loud if the code leaves the vocabulary)."""
    var cells = world_to_cell(hx, hz)
    var ix = _clamp_cell(cells[0])
    var iz = _clamp_cell(cells[1])
    var h = island.heights[iz * GRID_N + ix]
    var surface_y = Int(h + LATTICE_Y_OFFSET + 0.5)
    if surface_y < 1:
        surface_y = 1
    var code = island.surface_materials[iz * GRID_N + ix]
    var out = RayHit()
    out.hit = True
    out.material_id = catalog.defs[Int(code)].catalog_index
    out.hit_x = hx
    out.hit_y = hy
    out.hit_z = hz
    out.cell_x = ix
    out.cell_lattice_y = surface_y
    out.cell_z = iz
    return out^


def raycast_look(
    island: IslandSubject,
    catalog: MaterialCatalog,
    feet_x: Float64,
    feet_y: Float64,
    feet_z: Float64,
    yaw: Float64,
    pitch: Float64,
) raises -> RayHit:
    """Eye-height raycast along the look direction (the every-tick TARGET
    source: origin = feet + EYE_HEIGHT)."""
    var eye_y = feet_y + EYE_HEIGHT
    var dirs = look_forward(yaw, pitch)
    return raycast_heightfield(
        island, feet_x, eye_y, feet_z, dirs[0], dirs[1], dirs[2], catalog
    )
