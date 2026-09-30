# Spec test — sim-owned raycast (milestone_0007 §1.1 / AP-12 / §3.3):
# eye-height ray-march over the height field — geometry (yaw 0 faces -Z,
# pitch negative looks down), hit binding (cell + catalog material id),
# range cap (RAY_RANGE), miss (all-zero record), determinism (pure fn).
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op.
# Every check below uses `_check`, which raises Error => TestSuite FAIL.

from std.testing import TestSuite
from std.math import sqrt

from sim.island import build_island
from materials.catalog import load_catalog
from sim.raycast import (
    ray_miss,
    look_forward,
    raycast_heightfield,
    raycast_look,
)
from sim.parameters import (
    GRID_N,
    CELL_SIZE,
    RAY_RANGE,
    RAY_STEP,
)


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _cell_center(ix: Int, iz: Int) -> Tuple[Float64, Float64]:
    var wx = (Float64(ix) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
    var wz = (Float64(iz) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
    return (wx, wz)


def test_look_forward_geometry() raises:
    """Yaw 0 faces -Z; pitch 0 is horizontal; direction is unit length."""
    var d = look_forward(0.0, 0.0)
    _check(abs(d[0]) < 1.0e-12, "yaw 0: dir.x == 0")
    _check(abs(d[1]) < 1.0e-12, "pitch 0: dir.y == 0")
    _check(abs(d[2] + 1.0) < 1.0e-12, "yaw 0: dir.z == -1")
    var dn = look_forward(1.234, -0.5)
    var len_d = sqrt(dn[0] * dn[0] + dn[1] * dn[1] + dn[2] * dn[2])
    _check(abs(len_d - 1.0) < 1.0e-12, "look direction is unit length")
    var down = look_forward(0.0, -1.45)
    _check(down[1] < -0.99, "pitch -1.45 points (nearly) straight down")


def test_miss_record_is_all_zero() raises:
    """HUD contract: a miss carries hit=0 and zeroed fields (§3.3)."""
    var m = ray_miss()
    _check(not m.hit, "miss flag false")
    _check(m.material_id == 0, "material id 0")
    _check(m.hit_x == 0.0 and m.hit_y == 0.0 and m.hit_z == 0.0, "position 0")
    _check(m.cell_x == 0 and m.cell_lattice_y == 0 and m.cell_z == 0, "cell 0")


def test_downward_hit_binds_cell_and_material() raises:
    """Eye-height ray looking down from above a column hits THAT column and
    reports its surface catalog id; hit y sits on the height field."""
    var island = build_island(1)
    var catalog = load_catalog()
    var ix = GRID_N // 2
    var iz = GRID_N // 2
    var centers = _cell_center(ix, iz)
    var wx = centers[0]
    var wz = centers[1]
    var h = island.heights[iz * GRID_N + ix]
    # Feet 5 u above the surface. world_to_cell floors, so the cell span
    # starts at the centre: yaw = pi drifts +z (0.81 u < 4 u cell) and
    # stays inside the targeted column.
    var hit = raycast_look(
        island, catalog, wx, h + 5.0, wz, 3.141592653589793, -1.45
    )
    _check(hit.hit, "downward ray hits terrain")
    _check(hit.cell_x == ix, "hit cell_x == targeted column")
    _check(hit.cell_z == iz, "hit cell_z == targeted column")
    var surf_code = island.surface_materials[iz * GRID_N + ix]
    _check(
        hit.material_id == catalog.defs[Int(surf_code)].catalog_index,
        "material id == surface catalog id",
    )
    var ground = island.height_at(hit.hit_x, hit.hit_z)
    _check(
        abs(hit.hit_y - ground) <= RAY_STEP,
        "hit y on height field (within one march step)",
    )
    _check(hit.cell_lattice_y >= 1, "surface lattice cell >= 1")


def test_miss_when_looking_up_or_out_of_range() raises:
    """Pitch up from high above => miss; straight down from > RAY_RANGE
    above the surface => miss (range cap, 0007 §1.1 RAY_RANGE = 32)."""
    var island = build_island(1)
    var catalog = load_catalog()
    var centers = _cell_center(GRID_N // 2, GRID_N // 2)
    var up = raycast_look(island, catalog, centers[0], 400.0, centers[1], 0.0, 1.4)
    _check(not up.hit, "looking up misses")
    var far = raycast_look(
        island, catalog, centers[0], 400.0, centers[1], 0.0, -1.45
    )
    _check(not far.hit, "origin beyond RAY_RANGE misses")
    # Just inside the range still hits (cap boundary sanity): 20 u above.
    var near = raycast_look(
        island, catalog, centers[0], 20.0, centers[1], 0.0, -1.45
    )
    _check(near.hit, "origin within RAY_RANGE still hits")


def test_raycast_is_deterministic() raises:
    """Pure function of (island, pose, catalog): identical calls are equal."""
    var island = build_island(1)
    var catalog = load_catalog()
    var centers = _cell_center(GRID_N // 3, GRID_N // 3)
    var h = island.heights[(GRID_N // 3) * GRID_N + (GRID_N // 3)]
    var a = raycast_look(
        island, catalog, centers[0], h + 5.0, centers[1], 0.7, -1.45
    )
    var b = raycast_look(
        island, catalog, centers[0], h + 5.0, centers[1], 0.7, -1.45
    )
    _check(a.hit == b.hit, "hit flag identical")
    _check(a.material_id == b.material_id, "material id identical")
    _check(a.hit_x == b.hit_x and a.hit_y == b.hit_y, "hit position identical")
    _check(a.cell_x == b.cell_x and a.cell_z == b.cell_z, "cell identical")
    _check(
        a.cell_lattice_y == b.cell_lattice_y,
        "lattice cell identical",
    )


def main() raises:
    TestSuite.discover_tests[
        (
            test_look_forward_geometry,
            test_miss_record_is_all_zero,
            test_downward_hit_binds_cell_and_material,
            test_miss_when_looking_up_or_out_of_range,
            test_raycast_is_deterministic,
        )
    ]().run()
