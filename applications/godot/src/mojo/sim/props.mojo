# PhysicsSubject — minimal rigid props (milestone_0007 §3.5, LOCK in §1.1).
#
# Model (spec-faithful, deliberately small — Rule 14 vertical slice):
#   - terrain = STATIC body (height field, non-penetration);
#   - props = DYNAMIC bodies, mass-independent kinematics: uniform GRAVITY,
#     semi-implicit Euler at the fixed tick, NO inertia tensor ⇒ no
#     angular dynamics (euler stays 0; recorded deviation vs a full
#     RigidBody, subordinate to PHYSICS-INV-003 law ≠ discretization);
#   - ground contact only: penetration ⇒ clamp to surface + kill downward
#     velocity (restitution 0) + tangential damping;
#   - NO inter-body collision, stacking, joints or friction cones
#     (0007 §9 out of scope — successors).
# Determinism: bodies processed in ascending slot order (§3.5).
#
# Spawn: PROP_N_INIT boxes at deterministic beach anchors — the first
# PROP_N_INIT cells, in row-major scan order, whose height sits in the same
# beach band as the spawn point (seed-independent scan; the island itself
# is the seed's function, so anchors are (seed, spawn)-derived).

from std.collections import List
from std.math import sqrt

from sim.island import IslandSubject
from materials.catalog import MaterialCatalog
from sim.parameters import (
    PROP_N_MAX,
    PROP_N_INIT,
    PROP_BOX_HALF_U,
    PROP_SHAPE_BOX,
    PROP_TANGENTIAL_DAMPING,
    GRAVITY,
    GRID_N,
    CELL_SIZE,
    SPAWN_BEACH_OFFSET,
    SPAWN_SEARCH_RADIUS_MIN,
    SPAWN_SEARCH_RADIUS_MAX,
)


struct RigidProp(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """One RIGID_BODIES record's sim state (world frame, SI-ish units)."""

    var x: Float64
    var y: Float64
    var z: Float64
    var vx: Float64
    var vy: Float64
    var vz: Float64
    var shape: UInt32  # 0 box, 1 sphere (0007 §3.3)
    var size: Float64  # box: uniform half-extent; sphere: radius
    var material_id: UInt32  # stable catalog id (0007 inv.5)

    def __init__(out self):
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0
        self.vx = 0.0
        self.vy = 0.0
        self.vz = 0.0
        self.shape = PROP_SHAPE_BOX
        self.size = PROP_BOX_HALF_U
        self.material_id = 0

    def __deinit__(deinit self):
        pass


struct PhysicsSubject(Movable, Deinitable):
    """World-owned rigid-prop set; count ≤ PROP_N_MAX (inv.7)."""

    var count: Int
    var bodies: List[RigidProp]

    def __init__(out self):
        self.count = 0
        self.bodies = List[RigidProp]()

    def __deinit__(deinit self):
        pass


def props_from_island(
    island: IslandSubject, catalog: MaterialCatalog
) raises -> PhysicsSubject:
    """Deterministic PROP_N_INIT beach anchors (§1.1). Loud if the anchor
    band yields nothing — generation guarantees the spawn cell qualifies."""
    var anchors = List[Int]()
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
            anchors.append(iz * GRID_N + ix)
    if len(anchors) == 0:
        raise Error("prop anchors: no beach-band cell in the spawn annulus")

    var props = PhysicsSubject()
    for k in range(PROP_N_INIT):
        # Cycle if the band ever yields fewer cells than PROP_N_INIT —
        # still deterministic, still exactly PROP_N_INIT bodies.
        var cell = anchors[k % len(anchors)]
        var ix = cell % GRID_N
        var iz = cell // GRID_N
        var b = RigidProp()
        b.x = (Float64(ix) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
        b.z = (Float64(iz) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
        b.y = island.heights[cell] + PROP_BOX_HALF_U  # resting on the surface
        b.shape = PROP_SHAPE_BOX
        b.size = PROP_BOX_HALF_U
        b.material_id = catalog.defs[Int(island.surface_materials[cell])].catalog_index
        props.bodies.append(b^)
    props.count = len(props.bodies)
    if props.count > PROP_N_MAX:
        raise Error("rigid_body_count exceeds PROP_N_MAX")
    return props^


def props_tick(mut props: PhysicsSubject, island: IslandSubject, dt: Float64):
    """One fixed tick: gravity + semi-implicit Euler + ground contact, in
    ascending slot order (0007 §3.5 determinism rule)."""
    for i in range(props.count):
        var b = props.bodies[i]
        # Semi-implicit: velocity first, then position.
        b.vy += GRAVITY * dt
        b.x += b.vx * dt
        b.y += b.vy * dt
        b.z += b.vz * dt
        # Ground contact vs the static terrain body (non-penetration,
        # zero restitution, tangential damping).
        var ground = island.height_at(b.x, b.z)
        if b.y - b.size < ground:
            b.y = ground + b.size
            if b.vy < 0.0:
                b.vy = 0.0
            b.vx *= PROP_TANGENTIAL_DAMPING
            b.vz *= PROP_TANGENTIAL_DAMPING
        props.bodies[i] = b
