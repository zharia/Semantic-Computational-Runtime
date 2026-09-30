# Edit FIFO — sim-owned apply authority for milestone_0007 (§3.2 / AP-12).
#
# Client submits ONLY {op, select_slot} (scr_edit_batch, 0007 §3.2); every
# semantic decision — cell, material, terrain mutation — resolves here:
#
#   scr_edit_submit → edit_apply_batch (select row + op row, input.mojo
#   table) → FIFO → tick_world pops ONE op per fixed tick → consume_one_edit:
#     raycast_look (current player pose, sim-owned — AP-12) →
#     DIG:    h −= 1 u (bedrock guard rejects digging onto lattice ≤ 1);
#     PLACE:  h += 1 u, pipeline re-run, THEN surface cell overridden with
#             the selected hotbar voxel code (0007 §3.2 + inv.5);
#   on apply: blends masked to the edited cell, only that chunk rebuilt
#   (AP-14), peak/materials re-derived, caller bumps world_version + flora.
#
# Miss raycasts and guard rejects are CONSUMED but never mutate (no
# world_version bump). Determinism: queue order = submit order; one consume
# per tick; cell/material from (island, pose, hotbar) only — never client
# values (0007 invariant 4 / AP-12).

from std.collections import List

from sim.input import (
    build_edit_table,
    ACT_EDIT_SELECT,
    ACT_EDIT_OP,
)
from sim.island import (
    IslandSubject,
    rebuild_chunk_containing,
    refresh_peak_and_materials,
)
from sim.hotbar import HotbarSubject, hotbar_select, hotbar_selected_voxel_code
from sim.raycast import raycast_look
from sim.parameters import (
    EDIT_OP_NONE,
    EDIT_OP_DIG,
    EDIT_OP_PLACE,
    EDIT_QUEUE_MAX,
    EDIT_CELL_STEP_U,
    GRID_N,
    LATTICE_Y_OFFSET,
)
from materials.catalog import MaterialCatalog
from synthesis.noise import NoiseContext
from synthesis.voxel import resynthesize_column
from synthesis.blend import compute_blends_masked


struct EditIntent(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Queued op (select_slot already applied at submit time)."""

    var op: UInt8  # EDIT_OP_DIG | EDIT_OP_PLACE (NONE never enqueues)

    def __init__(out self, op: UInt8):
        self.op = op

    def __deinit__(deinit self):
        pass


struct EditQueue(Movable, Deinitable):
    """Bounded FIFO (0007 §3.2): ≤ EDIT_QUEUE_MAX pending ops, head index
    so submit cost is O(1); reset when drained."""

    var entries: List[EditIntent]
    var head: Int

    def __init__(out self):
        self.entries = List[EditIntent]()
        self.head = 0

    def __deinit__(deinit self):
        pass

    def pending(self) -> Int:
        return len(self.entries) - self.head


struct EditOutcome(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Result of one consume: consumed = popped; applied = world mutated."""

    var consumed: Bool
    var applied: Bool
    var cell_ix: Int
    var cell_iz: Int

    def __init__(out self):
        self.consumed = False
        self.applied = False
        self.cell_ix = -1
        self.cell_iz = -1

    def __deinit__(deinit self):
        pass


def edit_queue_init() -> EditQueue:
    return EditQueue()


def edit_push(mut queue: EditQueue, intent: EditIntent) -> Bool:
    """Append if room; False ⇒ SCR_ERR_QUEUE_FULL (caller reports)."""
    if queue.pending() >= EDIT_QUEUE_MAX:
        return False
    if queue.head >= len(queue.entries):
        # Fully drained: recycle the backing list (bounded memory).
        queue.entries = List[EditIntent]()
        queue.head = 0
    queue.entries.append(intent)
    return True


def edit_pop(mut queue: EditQueue) -> EditIntent:
    """FIFO pop (caller guarantees pending > 0)."""
    var intent = queue.entries[queue.head]
    queue.head += 1
    return intent^


def edit_apply_batch(
    mut queue: EditQueue, mut hotbar: HotbarSubject, op: UInt8, select_slot: UInt8
) raises -> Bool:
    """Apply one scr_edit_batch (0007 §3.2): select applies IMMEDIATELY
    (hotbar is sim state, intent-derived — AP-13), op is queued. Returns
    False ⇒ queue full (select not applied — atomic batch rejection)."""
    if op != EDIT_OP_NONE and queue.pending() >= EDIT_QUEUE_MAX:
        return False
    var table = build_edit_table(op, select_slot)
    for row in table:
        if row.action == ACT_EDIT_SELECT:
            _ = hotbar_select(hotbar, Int(row.select_slot))  # 0/invalid = no change
        elif row.action == ACT_EDIT_OP:
            if row.op == EDIT_OP_NONE:
                continue
            if not edit_push(queue, EditIntent(row.op)):
                return False
    return True


def _surface_lattice(h: Float64) -> Int:
    """Lattice y of the column's surface cell (same rounding as generation)."""
    var y = Int(h + LATTICE_Y_OFFSET + 0.5)
    if y < 1:
        y = 1
    return y


def consume_one_edit(
    mut island: IslandSubject,
    mut queue: EditQueue,
    mut hotbar: HotbarSubject,
    catalog: MaterialCatalog,
    feet_x: Float64,
    feet_y: Float64,
    feet_z: Float64,
    yaw: Float64,
    pitch: Float64,
) raises -> EditOutcome:
    """Pop and apply at most one queued op (one per fixed tick, §3.2).

    Cell/material derive solely from the sim raycast + hotbar state
    (AP-12). Returns outcome; caller bumps world_version + flora when
    `applied`."""
    if queue.pending() <= 0:
        return EditOutcome()
    var intent = edit_pop(queue)
    var out = EditOutcome()
    out.consumed = True

    # Sim-owned raycast over THIS tick's player pose (0007 §3.2).
    var hit = raycast_look(island, catalog, feet_x, feet_y, feet_z, yaw, pitch)
    if not hit.hit:
        return out^  # miss: consumed, no mutation, no version bump

    var ix = hit.cell_x
    var iz = hit.cell_z
    var cell = iz * GRID_N + ix
    var h = island.heights[cell]
    if intent.op != EDIT_OP_DIG and intent.op != EDIT_OP_PLACE:
        return out^  # invalid op: consumed, no mutation
    var dig = intent.op == EDIT_OP_DIG
    var new_h = h + EDIT_CELL_STEP_U
    if dig:
        new_h = h - EDIT_CELL_STEP_U
        # Bedrock guard: never let the surface cell fall onto lattice ≤ 1
        # (lattice 0/1 is the bedrock row — unreachable by digging).
        if _surface_lattice(new_h) <= 1:
            return out^  # rejected: consumed, no mutation

    # Pipeline re-run for the edited column (AP-11): biome + column authority,
    # then dig keeps the row material / place overrides the surface cell with
    # the selected hotbar code (0007 §3.2, inv.5).
    var ctx = NoiseContext(island.seed)
    var res = resynthesize_column(ix, iz, new_h, ctx)
    var surface_y = _surface_lattice(new_h)
    var surf_code = res.column.material_at(surface_y)
    if not dig:
        surf_code = hotbar_selected_voxel_code(hotbar)

    island.heights[cell] = new_h
    island.biomes[cell] = res.biome
    island.surface_materials[cell] = surf_code

    # Boundary feathering: the edited cell gets an identity tuple and never
    # seeds/receives a blend (its material may sit outside the biome row —
    # 0007 §3.2 place), so §6.4 pair checks stay satisfied.
    var mask = List[UInt8]()
    for i in range(GRID_N * GRID_N):
        mask.append(UInt8(1 if i == cell else 0))
    island.blends = compute_blends_masked(
        island.surface_materials, island.biomes, ctx, mask
    )

    # AP-14: rebuild ONLY the chunk containing the edited cell.
    rebuild_chunk_containing(island, ix, iz)
    # Re-derive generation-owned scalars (TERRAIN_META + MATERIALS).
    refresh_peak_and_materials(island)

    out.applied = True
    out.cell_ix = ix
    out.cell_iz = iz
    return out^
