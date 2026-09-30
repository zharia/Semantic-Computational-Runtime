# Spec test — edit ops (milestone_0007 §3.2 / AP-11 / AP-12 / AP-14,
# invariant 4): FIFO consume (one per call), dig/place height steps, pipeline
# re-run authority, hotbar place override, blend identity on the edited cell,
# chunk-local rebuild, bedrock guard, miss/no-op paths, queue bound with
# atomic rejection, and the world-level world_version bump per applied edit.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op.
# Every check below uses `_check`, which raises Error => TestSuite FAIL.

from std.collections import List
from std.testing import TestSuite

from sim.island import build_island, IslandSubject, TerrainChunk
from sim.hotbar import hotbar_init, hotbar_select, hotbar_selected_voxel_code
from sim.edit import (
    edit_queue_init,
    edit_apply_batch,
    consume_one_edit,
)
from sim.world import world_init, step_world
from sim.input import idle_input
from sim.parameters import (
    GRID_N,
    CELL_SIZE,
    EDIT_QUEUE_MAX,
    EDIT_CELL_STEP_U,
    EDIT_OP_DIG,
    EDIT_OP_PLACE,
    EDIT_OP_NONE,
    LATTICE_Y_OFFSET,
    TERRAIN_CHUNK_CELLS,
)
from materials.catalog import load_catalog, MAT_BEDROCK
from synthesis.heightfield import world_to_cell


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _lattice(h: Float64) -> Int:
    return Int(h + LATTICE_Y_OFFSET + 0.5)


def _cell_center(ix: Int, iz: Int) -> Tuple[Float64, Float64]:
    var wx = (Float64(ix) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
    var wz = (Float64(iz) + 0.5 - Float64(GRID_N) / 2.0) * CELL_SIZE
    return (wx, wz)


def _spawn_cell(island: IslandSubject) -> Tuple[Int, Int]:
    var cells = world_to_cell(island.spawn_x, island.spawn_z)
    return (cells[0], cells[1])


def _aim_down(island: IslandSubject, ix: Int, iz: Int) -> List[Float64]:
    """Pose that raycasts the cell under the eye: [feet_x, feet_y, feet_z,
    yaw, pitch] — yaw 0 (drift 0.81 u < half-cell), pitch -1.45 (down)."""
    var centers = _cell_center(ix, iz)
    var h = island.heights[iz * GRID_N + ix]
    # world_to_cell floors, so the cell span starts at the centre: yaw = pi
    # drifts +z (0.81 u < 4 u cell) and the ray lands in the target column.
    var out = List[Float64]()
    out.append(centers[0])
    out.append(h + 5.0)
    out.append(centers[1])
    out.append(3.141592653589793)
    out.append(-1.45)
    return out^


def _chunks_equal(a: TerrainChunk, b: TerrainChunk) -> Bool:
    if a.origin_x != b.origin_x or a.origin_y != b.origin_y:
        return False
    if a.origin_z != b.origin_z:
        return False
    if len(a.vertices) != len(b.vertices):
        return False
    for i in range(len(a.vertices)):
        if a.vertices[i] != b.vertices[i]:
            return False
    if len(a.normals) != len(b.normals):
        return False
    for i in range(len(a.normals)):
        if a.normals[i] != b.normals[i]:
            return False
    if len(a.material_ids) != len(b.material_ids):
        return False
    for i in range(len(a.material_ids)):
        if a.material_ids[i] != b.material_ids[i]:
            return False
    if len(a.blends) != len(b.blends):
        return False
    for i in range(len(a.blends)):
        if a.blends[i].material != b.blends[i].material:
            return False
        if a.blends[i].blend != b.blends[i].blend:
            return False
        if a.blends[i].weight != b.blends[i].weight:
            return False
    if len(a.indices) != len(b.indices):
        return False
    for i in range(len(a.indices)):
        if a.indices[i] != b.indices[i]:
            return False
    return True


def _snapshot_chunks(island: IslandSubject) -> List[TerrainChunk]:
    var out = List[TerrainChunk]()
    for i in range(island.chunk_count):
        out.append(island.chunks[i].copy())
    return out^


def test_dig_lowers_cell_and_rebuilds_only_its_chunk() raises:
    """AP-11 (pipeline re-run) + AP-14 (chunk-local rebuild): dig steps the
    height down 1 u, re-derives biome/surface, gives the edited cell an
    identity blend tuple, and touches exactly the owning chunk."""
    var island = build_island(1)
    var catalog = load_catalog()
    var hotbar = hotbar_init(catalog)
    var queue = edit_queue_init()
    var spawn = _spawn_cell(island)
    var ix = spawn[0]
    var iz = spawn[1]
    var cell = iz * GRID_N + ix
    var h0 = island.heights[cell]
    var before = _snapshot_chunks(island)

    var aim = _aim_down(island, ix, iz)
    var out = consume_one_edit(
        island, queue, hotbar, catalog, aim[0], aim[1], aim[2], aim[3], aim[4]
    )
    # Queue was empty: nothing consumed, nothing mutated.
    _check(not out.consumed, "empty queue: nothing consumed")
    _check(island.heights[cell] == h0, "empty queue: height unchanged")

    _check(edit_apply_batch(queue, hotbar, EDIT_OP_DIG, 0), "dig enqueued")
    _check(queue.pending() == 1, "pending == 1")
    out = consume_one_edit(
        island, queue, hotbar, catalog, aim[0], aim[1], aim[2], aim[3], aim[4]
    )
    _check(out.consumed, "op consumed")
    _check(out.applied, "dig applied")
    _check(out.cell_ix == ix, "outcome cell_x == targeted")
    _check(out.cell_iz == iz, "outcome cell_z == targeted")
    _check(
        island.heights[cell] == h0 - EDIT_CELL_STEP_U,
        "dig lowered height by 1 u",
    )
    # Pipeline re-run: surface cell re-derived from the edited column.
    _check(
        island.surface_materials[cell] != MAT_BEDROCK,
        "surface cell never bedrock",
    )
    _check(_lattice(island.heights[cell]) >= 2, "surface lattice >= 2")
    # Blend identity on the edited cell (never seeds/receives feathering).
    var bt = island.blends[cell]
    _check(bt.weight == 0, "edited cell blend weight == 0")
    _check(
        bt.material == island.surface_materials[cell],
        "edited cell blend material == surface code",
    )
    _check(
        bt.blend == island.surface_materials[cell],
        "edited cell blend partner == surface code (identity)",
    )
    # Chunk-local rebuild: exactly the owning chunk differs.
    var after = _snapshot_chunks(island)
    var chunk_cx = ix // TERRAIN_CHUNK_CELLS
    var chunk_cz = iz // TERRAIN_CHUNK_CELLS
    var per_side = GRID_N // TERRAIN_CHUNK_CELLS
    var changed = 0
    for c in range(island.chunk_count):
        var equal = _chunks_equal(before[c], after[c])
        if equal:
            continue
        changed += 1
        _check(
            c == chunk_cz * per_side + chunk_cx,
            "only the owning chunk rebuilt (chunk " + String(c) + ")",
        )
    _check(changed == 1, "exactly one chunk changed (got " + String(changed) + ")")
    # Materials/peak re-derived (used_materials still contains the surface).
    var found = False
    for i in range(len(island.used_materials)):
        if island.used_materials[i] == island.surface_materials[cell]:
            found = True
    _check(found, "used_materials contains the surface code")
    _check(
        island.used_materials[0] == MAT_BEDROCK,
        "bedrock still first in used_materials",
    )
    _check(queue.pending() == 0, "queue drained")


def test_place_uses_selected_hotbar_material() raises:
    """§3.2/inv.5: place steps the height up 1 u and overrides the surface
    cell with the SELECTED slot's voxel code (pipeline still re-runs)."""
    var island = build_island(1)
    var catalog = load_catalog()
    var hotbar = hotbar_init(catalog)
    var queue = edit_queue_init()
    var spawn = _spawn_cell(island)
    var ix = spawn[0]
    var iz = spawn[1]
    var cell = iz * GRID_N + ix
    var h0 = island.heights[cell]
    # Slot 9 = rock.obsidian (selected via the table, never by material).
    _check(hotbar_select(hotbar, 9), "select slot 9")
    var want_code = hotbar_selected_voxel_code(hotbar)
    _check(edit_apply_batch(queue, hotbar, EDIT_OP_PLACE, 0), "place enqueued")
    var aim = _aim_down(island, ix, iz)
    var out = consume_one_edit(
        island, queue, hotbar, catalog, aim[0], aim[1], aim[2], aim[3], aim[4]
    )
    _check(out.applied, "place applied")
    _check(
        island.heights[cell] == h0 + EDIT_CELL_STEP_U,
        "place raised height by 1 u",
    )
    _check(
        island.surface_materials[cell] == want_code,
        "surface cell == selected slot's voxel code",
    )


def test_miss_ray_is_consumed_without_mutation() raises:
    """Miss => consumed, NOT applied: no height change, no queue residue."""
    var island = build_island(1)
    var catalog = load_catalog()
    var hotbar = hotbar_init(catalog)
    var queue = edit_queue_init()
    var spawn = _spawn_cell(island)
    var cell = spawn[1] * GRID_N + spawn[0]
    var h0 = island.heights[cell]
    _check(edit_apply_batch(queue, hotbar, EDIT_OP_DIG, 0), "dig enqueued")
    # Looking up: ray never reaches terrain within RAY_RANGE.
    var out = consume_one_edit(
        island, queue, hotbar, catalog, island.spawn_x, island.spawn_y, island.spawn_z, 0.0, 1.4
    )
    _check(out.consumed, "miss consume pops the op")
    _check(not out.applied, "miss never applies")
    _check(island.heights[cell] == h0, "height unchanged on miss")
    _check(queue.pending() == 0, "queue drained on miss")


def test_bedrock_guard_rejects_deep_digs() raises:
    """Guard: the surface cell can never fall onto lattice <= 1 (bedrock
    row). The rejecting dig is consumed but mutates nothing; the surface
    material never becomes MAT_BEDROCK."""
    var island = build_island(1)
    var catalog = load_catalog()
    var hotbar = hotbar_init(catalog)
    var queue = edit_queue_init()
    var spawn = _spawn_cell(island)
    var ix = spawn[0]
    var iz = spawn[1]
    var cell = iz * GRID_N + ix
    var aim = _aim_down(island, ix, iz)
    var applied = 0
    var rejected = False
    for _ in range(64):
        _check(edit_apply_batch(queue, hotbar, EDIT_OP_DIG, 0), "dig enqueued")
        var out = consume_one_edit(
            island, queue, hotbar, catalog, aim[0], aim[1], aim[2], aim[3], aim[4]
        )
        _check(out.consumed, "dig consumed")
        if not out.applied:
            rejected = True
            break
        applied += 1
        _check(_lattice(island.heights[cell]) >= 2, "surface lattice >= 2")
        _check(
            island.surface_materials[cell] != MAT_BEDROCK,
            "surface never bedrock during digs",
        )
    _check(rejected, "bedrock guard eventually rejects (applied " + String(applied) + ")")
    _check(applied >= 1, "at least one dig applied before rejection")
    _check(_lattice(island.heights[cell]) >= 2, "final surface lattice >= 2")


def test_queue_bound_and_atomic_rejection() raises:
    """FIFO bound (EDIT_QUEUE_MAX): full queue rejects the WHOLE batch —
    neither its select_slot nor its op is applied."""
    var catalog = load_catalog()
    var hotbar = hotbar_init(catalog)
    var queue = edit_queue_init()
    for i in range(EDIT_QUEUE_MAX):
        _check(
            edit_apply_batch(queue, hotbar, EDIT_OP_DIG, 0),
            "enqueue " + String(i + 1) + " succeeds",
        )
    _check(queue.pending() == EDIT_QUEUE_MAX, "queue at capacity")
    _check(
        not edit_apply_batch(queue, hotbar, EDIT_OP_DIG, 5),
        "over-capacity batch rejected",
    )
    _check(queue.pending() == EDIT_QUEUE_MAX, "pending unchanged after reject")
    _check(
        hotbar.selected_index == 0,
        "rejected batch's select_slot NOT applied (atomic)",
    )
    # A select-only batch grows nothing, so it is accepted even when the
    # FIFO is full (FULL is reported only for batches that would enqueue).
    _check(
        edit_apply_batch(queue, hotbar, EDIT_OP_NONE, 5),
        "select-only batch accepted even when full",
    )
    _check(
        hotbar.selected_index == 4,
        "select-only selection applied (slot 5)",
    )
    _check(
        queue.pending() == EDIT_QUEUE_MAX,
        "select-only leaves the FIFO untouched",
    )
    # Drain order: FIFO (submit order == consume order).
    var island = build_island(1)
    var spawn = _spawn_cell(island)
    var aim = _aim_down(island, spawn[0], spawn[1])
    var pops = 0
    while queue.pending() > 0:
        var out = consume_one_edit(
            island, queue, hotbar, catalog, aim[0], aim[1], aim[2], aim[3], aim[4]
        )
        _check(out.consumed, "pop " + String(pops + 1))
        pops += 1
        _check(pops <= EDIT_QUEUE_MAX, "no extra pops")
    _check(pops == EDIT_QUEUE_MAX, "drained exactly EDIT_QUEUE_MAX ops")

    # Invalid values: op 99 queues but never mutates; select 99 never moves.
    var q2 = edit_queue_init()
    var hb2 = hotbar_init(catalog)
    _check(edit_apply_batch(q2, hb2, 99, 0), "unknown op queues (validated at consume)")
    var out2 = consume_one_edit(
        island, q2, hb2, catalog, aim[0], aim[1], aim[2], aim[3], aim[4]
    )
    _check(out2.consumed, "unknown op consumed")
    _check(not out2.applied, "unknown op never applies")
    _check(edit_apply_batch(q2, hb2, EDIT_OP_NONE, 99), "select-only batch accepted")
    _check(hb2.selected_index == 0, "invalid slot leaves selection unchanged")
    _check(q2.pending() == 0, "NONE op enqueues nothing")


def test_applied_edit_bumps_world_version_once() raises:
    """World level (0007 §3.2): exactly one world_version increment per
    applied edit, carried by the next fixed tick; no further bumps while the
    queue stays empty (FLORA/TERRAIN resends ride the same tracker)."""
    var world = world_init(1)
    var cells = world_to_cell(world.island.spawn_x, world.island.spawn_z)
    var ix = cells[0]
    var iz = cells[1]
    var cell = iz * GRID_N + ix
    var h0 = world.island.heights[cell]
    var v0 = world.world_version
    _check(v0 == 1, "world_version starts at 1")

    _check(
        edit_apply_batch(world.edit_queue, world.hotbar, EDIT_OP_DIG, 0),
        "dig enqueued on the world queue",
    )
    _ = step_world(world, 1.0 / 60.0, idle_input())
    _check(world.world_version == v0 + 1, "applied edit bumps world_version by 1")
    _check(
        world.island.heights[cell] == h0 - EDIT_CELL_STEP_U,
        "tick consumed and applied the dig",
    )
    _check(world.edit_queue.pending() == 0, "queue drained by the tick")

    _ = step_world(world, 1.0 / 60.0, idle_input())
    _check(
        world.world_version == v0 + 1,
        "no further bump with an empty queue",
    )


def main() raises:
    TestSuite.discover_tests[
        (
            test_dig_lowers_cell_and_rebuilds_only_its_chunk,
            test_place_uses_selected_hotbar_material,
            test_miss_ray_is_consumed_without_mutation,
            test_bedrock_guard_rejects_deep_digs,
            test_queue_bound_and_atomic_rejection,
            test_applied_edit_bumps_world_version_once,
        )
    ]().run()
