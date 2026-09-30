# Spec test — Hotbar (milestone_0007 §1.1 / §3.3 / AP-13, invariant 5):
# the 9-slot table resolves against materials_catalog.json at init (every
# slot a real catalog id, no bedrock placeable code), selection applies only
# for valid 1..9 slots, and selected id/code pairs match the parameter table.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op.
# Every check below uses `_check`, which raises Error => TestSuite FAIL.

from std.testing import TestSuite

from materials.catalog import load_catalog, MAT_BEDROCK, MAT_VOCAB_COUNT
from sim.hotbar import (
    hotbar_init,
    hotbar_select,
    hotbar_selected_catalog_id,
    hotbar_selected_voxel_code,
    voxel_code_for_catalog_id,
)
from sim.parameters import (
    HOTBAR_SLOT_COUNT,
    hotbar_slot_catalog_ids,
)


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def test_slot_table_resolves_against_catalog() raises:
    """AP-13/inv.5: all 9 parameter ids resolve to stable catalog ids and
    placeable voxel codes at init; the wire table equals the parameter."""
    var catalog = load_catalog()
    var h = hotbar_init(catalog)
    _check(
        len(h.slot_ids) == HOTBAR_SLOT_COUNT,
        "9 slots resolved (got " + String(len(h.slot_ids)) + ")",
    )
    _check(len(h.slot_codes) == HOTBAR_SLOT_COUNT, "9 placeable codes")
    var want = hotbar_slot_catalog_ids()
    _check(len(want) == HOTBAR_SLOT_COUNT, "parameter table has 9 entries")
    for i in range(HOTBAR_SLOT_COUNT):
        # Slot i's id == parameter table id i (single-sourced, no parallel list).
        var found = False
        for code in range(MAT_VOCAB_COUNT):
            if catalog.defs[code].catalog_id == want[i]:
                found = True
                break
        _check(found, "slot " + String(i) + " id in catalog: " + want[i])
        _check(
            h.slot_ids[i] == catalog.defs[
                Int(voxel_code_for_catalog_id(catalog, h.slot_ids[i]))
            ].catalog_index,
            "slot " + String(i) + " id/code pair consistent",
        )
    # Spec-locked slot order (0007 §1.1 table) at stable catalog positions
    # (materials_catalog.json array order).
    _check(h.slot_ids[0] == 10, "slot1 rock.basalt catalog_index == 10")
    _check(h.slot_ids[1] == 3, "slot2 soil.sand catalog_index == 3")
    _check(h.slot_ids[2] == 11, "slot3 rock.obsidian catalog_index == 11")
    _check(h.slot_ids[3] == 58, "slot4 mineral.sulfur catalog_index == 58")
    _check(h.slot_ids[4] == 60, "slot5 mineral.ash catalog_index == 60")
    _check(h.slot_ids[5] == 38, "slot6 fluid.lava catalog_index == 38")
    _check(h.slot_ids[6] == 37, "slot7 fluid.water catalog_index == 37")
    _check(h.slot_ids[7] == 0, "slot8 soil.dirt catalog_index == 0")
    _check(h.slot_ids[8] == 54, "slot9 rock.pumice catalog_index == 54")


def test_no_bedrock_placeable_code() raises:
    """Bedrock is never placeable: every slot's code skips MAT_BEDROCK even
    where the catalog id is shared (rock.basalt -> code 1, not 0)."""
    var catalog = load_catalog()
    var h = hotbar_init(catalog)
    for i in range(HOTBAR_SLOT_COUNT):
        _check(
            h.slot_codes[i] != MAT_BEDROCK,
            "slot " + String(i) + " must not resolve to MAT_BEDROCK",
        )
    _check(
        voxel_code_for_catalog_id(catalog, h.slot_ids[0]) == 1,
        "rock.basalt resolves to MAT_BASALT (code 1)",
    )


def test_selection_valid_and_invalid_slots() raises:
    """Select_slot 1..9 selects; 0 and 10+ are rejected with no change."""
    var catalog = load_catalog()
    var h = hotbar_init(catalog)
    _check(h.selected_index == 0, "selection starts at slot 0")
    _check(hotbar_select(h, 5), "valid slot 5 selects")
    _check(h.selected_index == 4, "1-based 5 => 0-based 4")
    _check(
        hotbar_selected_catalog_id(h) == 60,
        "selected id is mineral.ash (60)",
    )
    _check(not hotbar_select(h, 0), "slot 0 (no change) rejected")
    _check(h.selected_index == 4, "selection unchanged after slot 0")
    _check(not hotbar_select(h, 10), "slot 10 rejected")
    _check(h.selected_index == 4, "selection unchanged after slot 10")
    _check(not hotbar_select(h, 5), "re-select same slot reports no change")
    _check(hotbar_select(h, 1), "valid slot 1 selects")
    _check(h.selected_index == 0, "back to slot 0")
    _check(
        hotbar_selected_voxel_code(h) == 1,
        "slot 1 place code is MAT_BASALT (1)",
    )
    _check(
        voxel_code_for_catalog_id(catalog, 0) == 8,
        "soil.dirt resolves to MAT_DIRT (code 8)",
    )


def main() raises:
    TestSuite.discover_tests[
        (
            test_slot_table_resolves_against_catalog,
            test_no_bedrock_placeable_code,
            test_selection_valid_and_invalid_slots,
        )
    ]().run()
