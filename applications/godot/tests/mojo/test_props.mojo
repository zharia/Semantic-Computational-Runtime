# Spec test — rigid props (milestone_0007 §3.5 / §7, invariant 7): spawn
# count and anchors, catalog material ids, ground contact (never penetrates
# the terrain after a tick), slot-order determinism, and the N <= PROP_N_MAX
# cap. Headless (no Godot).
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op.
# Every check below uses `_check`, which raises Error => TestSuite FAIL.

from std.testing import TestSuite

from sim.island import build_island, IslandSubject
from sim.props import (
    props_from_island,
    props_tick,
    PhysicsSubject,
)
from materials.catalog import load_catalog, MaterialCatalog
from sim.parameters import (
    PROP_N_INIT,
    PROP_N_MAX,
    PROP_BOX_HALF_U,
    PROP_SHAPE_BOX,
    PROP_TANGENTIAL_DAMPING,
    FIXED_DT,
    GRID_N,
    CELL_SIZE,
    SPAWN_BEACH_OFFSET,
    SPAWN_SEARCH_RADIUS_MIN,
    SPAWN_SEARCH_RADIUS_MAX,
)
from std.math import sqrt


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _catalog_ids_valid(catalog: MaterialCatalog, id: UInt32) -> Bool:
    for i in range(catalog.count()):
        if catalog.defs[i].catalog_index == id:
            return True
    return False


def test_spawn_count_anchors_and_materials() raises:
    """PROP_N_INIT bodies at deterministic beach anchors: count cap holds,
    anchors sit in the spawn beach band/annulus, bodies rest on the surface,
    material ids resolve to the catalog."""
    var island = build_island(1)
    var catalog = load_catalog()
    var props = props_from_island(island, catalog)
    _check(props.count == PROP_N_INIT, "count == PROP_N_INIT at init")
    _check(props.count <= PROP_N_MAX, "count <= PROP_N_MAX (inv.7)")
    for i in range(props.count):
        var b = props.bodies[i]
        _check(
            b.shape == PROP_SHAPE_BOX,
            "spawn shape is a box",
        )
        _check(b.size == PROP_BOX_HALF_U, "size == PROP_BOX_HALF_U")
        _check(
            _catalog_ids_valid(catalog, b.material_id),
            "material id resolves to catalog",
        )
        # Anchor cell: recover from world xz and check the beach band.
        var ix = Int((b.x / CELL_SIZE) + Float64(GRID_N) / 2.0)
        var iz = Int((b.z / CELL_SIZE) + Float64(GRID_N) / 2.0)
        _check(
            ix >= 0 and ix < GRID_N and iz >= 0 and iz < GRID_N,
            "anchor inside the grid",
        )
        var h = island.heights[iz * GRID_N + ix]
        _check(
            h >= SPAWN_BEACH_OFFSET - 1.0 and h <= SPAWN_BEACH_OFFSET + 1.0,
            "anchor in the beach band (h = " + String(h) + ")",
        )
        var r = sqrt(b.x * b.x + b.z * b.z)
        _check(
            r >= SPAWN_SEARCH_RADIUS_MIN and r <= SPAWN_SEARCH_RADIUS_MAX,
            "anchor inside the spawn annulus",
        )
        # Resting on the surface: center == ground + half extent.
        _check(
            abs(b.y - (h + PROP_BOX_HALF_U)) < 1.0e-9,
            "spawn rests on the surface",
        )
        # Surface material of the anchor cell maps to the emitted id.
        var surf = island.surface_materials[iz * GRID_N + ix]
        _check(
            b.material_id == catalog.defs[Int(surf)].catalog_index,
            "material id == anchor surface catalog id",
        )


def test_ground_contact_never_penetrates() raises:
    """300 fixed ticks: every prop stays at/above the terrain surface
    (non-penetration) with zero restitution (no bounce below contact)."""
    var island = build_island(1)
    var catalog = load_catalog()
    var props = props_from_island(island, catalog)
    for tick in range(300):
        props_tick(props, island, FIXED_DT)
        for i in range(props.count):
            var b = props.bodies[i]
            var ground = island.height_at(b.x, b.z)
            _check(
                b.y - b.size >= ground - 1.0e-9,
                "tick "
                + String(tick)
                + " prop "
                + String(i)
                + " penetrates terrain",
            )


def test_same_inputs_same_trajectory() raises:
    """Determinism (0007 §3.5 slot order): two identical states ticked with
    identical dt end byte-identical (position + velocity)."""
    var island = build_island(1)
    var catalog = load_catalog()
    var a = props_from_island(island, catalog)
    var b = props_from_island(island, catalog)
    for _ in range(120):
        props_tick(a, island, FIXED_DT)
        props_tick(b, island, FIXED_DT)
    _check(a.count == b.count, "counts equal")
    for i in range(a.count):
        var pa = a.bodies[i]
        var pb = b.bodies[i]
        _check(pa.x == pb.x and pa.y == pb.y and pa.z == pb.z, "positions equal")
        _check(
            pa.vx == pb.vx and pa.vy == pb.vy and pa.vz == pb.vz,
            "velocities equal",
        )
        _check(pa.material_id == pb.material_id, "material ids equal")
        _check(pa.shape == pb.shape and pa.size == pb.size, "shape equal")


def test_tangential_damping_applies_on_contact() raises:
    """After 120 ticks the spawn bodies have settled: tangential speed
    decayed (damping) and vy never accumulates a downward sink."""
    var island = build_island(1)
    var catalog = load_catalog()
    var props = props_from_island(island, catalog)
    # Give every prop a tangential kick so damping has something to decay.
    for i in range(props.count):
        var b = props.bodies[i]
        b.vx = 4.0
        b.vz = -4.0
        props.bodies[i] = b
    for _ in range(120):
        props_tick(props, island, FIXED_DT)
    for i in range(props.count):
        var b = props.bodies[i]
        var hspeed = sqrt(b.vx * b.vx + b.vz * b.vz)
        var kick = sqrt(32.0)  # |(4, -4)| applied above
        _check(
            hspeed <= kick + 1.0e-9,
            "tangential speed never grows (no energy source)",
        )
        # In contact most ticks: damping repeatedly applied => below kick.
        var ground = island.height_at(b.x, b.z)
        if b.y - b.size <= ground + 1.0e-9:
            _check(
                hspeed < kick * PROP_TANGENTIAL_DAMPING + 1.0e-9,
                "contact decays tangential speed",
            )


def main() raises:
    TestSuite.discover_tests[
        (
            test_spawn_count_anchors_and_materials,
            test_ground_contact_never_penetrates,
            test_same_inputs_same_trajectory,
            test_tangential_damping_applies_on_contact,
        )
    ]().run()
