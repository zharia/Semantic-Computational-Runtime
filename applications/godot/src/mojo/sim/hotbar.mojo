# Hotbar — 9-slot catalog table + selection as SIM state (milestone_0007
# §1.1 / AP-13).
#
# The slot vocabulary is the parameter table in sim/parameters.mojo
# (hotbar_slot_catalog_ids): 9 catalog-id strings, every one resolving
# against lib/A01_Render/Material/materials_catalog.json at init — no
# parallel list anywhere (AP-3/AP-13). Each slot resolves to BOTH:
#   - the stable catalog id (u32) carried on the wire (HOTBAR material_id),
#   - the voxel code the synthesis vocabulary stores, for `place` ops.
# The bedrock code is never a placeable slot: MAT_BEDROCK and MAT_BASALT
# share the `rock.basalt` catalog id, so the code resolution skips bedrock
# (0007 inv.5 + Synthesis §4 inv.3 — bedrock is not a material you place).
#
# Selection is intent-applied (scr_edit_batch.select_slot), never display-
# driven: the HUD only reads the HOTBAR section (HUD non-authority, inv.10).

from std.collections import List

from materials.catalog import MaterialCatalog, MAT_BEDROCK, MAT_VOCAB_COUNT
from sim.parameters import (
    hotbar_slot_catalog_ids,
    HOTBAR_SLOT_COUNT,
    HOTBAR_SLOT_MIN,
)


struct HotbarSubject(Movable, Deinitable):
    """Sim-owned hotbar: selected slot (0-based) + resolved slot tables."""

    var selected_index: Int  # 0-based; wire field selected_index
    var slot_ids: List[UInt32]  # stable catalog ids (HOTBAR material_id)
    var slot_codes: List[UInt32]  # voxel codes (place material source)

    def __init__(out self):
        self.selected_index = 0
        self.slot_ids = List[UInt32]()
        self.slot_codes = List[UInt32]()

    def __deinit__(deinit self):
        pass


def voxel_code_for_catalog_id(catalog: MaterialCatalog, cat_id: UInt32) raises -> UInt32:
    """Catalog id → placeable voxel code. Skips MAT_BEDROCK (shared `rock.
    basalt` id) so no sequence can ever place the bedrock cell."""
    for code in range(MAT_VOCAB_COUNT):
        var ucode = UInt32(code)
        if ucode == MAT_BEDROCK:
            continue
        if catalog.defs[code].catalog_index == cat_id:
            return ucode
    raise Error("catalog id " + String(cat_id) + " has no placeable voxel code")


def hotbar_init(catalog: MaterialCatalog) raises -> HotbarSubject:
    """Resolve the parameter slot table against the catalog (loud on any
    unresolved id — invariant 5 is a load-time guarantee, not a render-time
    fallback)."""
    var ids = hotbar_slot_catalog_ids()
    if len(ids) != HOTBAR_SLOT_COUNT:
        raise Error(
            "hotbar parameter table must have "
            + String(HOTBAR_SLOT_COUNT)
            + " slots, got "
            + String(len(ids))
        )
    var h = HotbarSubject()
    for i in range(len(ids)):
        var want = ids[i]
        var found = -1
        for code in range(MAT_VOCAB_COUNT):
            if catalog.defs[code].catalog_id == want:
                if UInt32(code) == MAT_BEDROCK:
                    continue  # rock.basalt also maps code 0 — take code 1
                found = code
                break
        if found < 0:
            raise Error("hotbar slot id not in catalog vocabulary: " + want)
        var cat_id = catalog.defs[found].catalog_index
        h.slot_ids.append(cat_id)
        h.slot_codes.append(voxel_code_for_catalog_id(catalog, cat_id))
    h.selected_index = 0
    return h^


def hotbar_select(mut h: HotbarSubject, slot_1based: Int) raises -> Bool:
    """Apply a select_slot intent. 1..9 selects; anything else (0 = no
    change, 10+ = invalid) is REJECTED — selection never moves on a bad
    slot. Returns True iff the selection changed."""
    if slot_1based < HOTBAR_SLOT_MIN or slot_1based > HOTBAR_SLOT_COUNT:
        return False
    var target = slot_1based - 1
    if target == h.selected_index:
        return False
    if target >= len(h.slot_ids):
        raise Error("hotbar selection out of resolved slot range")
    h.selected_index = target
    return True


def hotbar_selected_catalog_id(h: HotbarSubject) raises -> UInt32:
    if h.selected_index >= len(h.slot_ids):
        raise Error("hotbar selected_index out of range")
    return h.slot_ids[h.selected_index]


def hotbar_selected_voxel_code(h: HotbarSubject) raises -> UInt32:
    """Material code `place` writes (0007 §3.2: place uses the currently
    selected slot's material)."""
    if h.selected_index >= len(h.slot_codes):
        raise Error("hotbar selected_index out of range")
    return h.slot_codes[h.selected_index]
