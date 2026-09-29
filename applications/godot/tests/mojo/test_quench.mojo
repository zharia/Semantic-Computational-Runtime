# Spec test — Quench evaluator (milestone_0005 §7 "Quench conformance"):
# reaction.lava_water_quench implemented VERBATIM from
# lib/A01_Render/Material/material_reactions.json:
#   - primary fluid.lava adjacent to fluid.water (face_sharing_6_neighborhood),
#   - source lava → rock.obsidian (15000 J), non-source → rock.cobblestone
#     (8000 J), byproduct fluid.steam recorded in the evaluator output,
#   - no adjacency ⇒ no-op,
#   - seed-1 island triggers ZERO quenches (no lava↔water adjacency in the
#     current world-gen geometry) — asserted.
# Headless: runs without Godot.
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified: `assert False` does not stop execution). Every check below uses
# `_check`, which raises Error ⇒ TestSuite reports FAIL and exits non-zero.

from std.collections import List
from std.testing import TestSuite

from synthesis.quench import (
    quench_events,
    quench_outcome,
    QUENCH_ENERGY_SOURCE_J,
    QUENCH_ENERGY_NONSOURCE_J,
    QUENCH_BYPRODUCT,
    QUENCH_PRIMARY,
    QUENCH_ADJACENCY,
    QUENCH_REACTION_ID,
)
from synthesis.voxel import ColumnSegment, MaterialColumn
from materials.catalog import (
    MAT_BEDROCK,
    MAT_LAVA,
    MAT_WATER,
    MAT_OBSIDIAN,
    MAT_COBBLESTONE,
    vocab_catalog_id_string,
)
from materials.json import parse_json
from util.files import find_repo_root, join_path, read_file_text
from sim.island import build_island
from sim.parameters import GRID_N

comptime REACTIONS_REL = "lib/A01_Render/Material/material_reactions.json"


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def _column(var segs: List[ColumnSegment]) -> MaterialColumn:
    return MaterialColumn(segs^)


def _empty_column() -> MaterialColumn:
    return MaterialColumn(List[ColumnSegment]())


def _bedrock_lava(y_start: Int, y_end: Int) -> MaterialColumn:
    var segs = List[ColumnSegment]()
    segs.append(ColumnSegment(0, 0, MAT_BEDROCK))
    segs.append(ColumnSegment(y_start, y_end, MAT_LAVA))
    return _column(segs^)


def _water(y_start: Int, y_end: Int) -> MaterialColumn:
    var segs = List[ColumnSegment]()
    segs.append(ColumnSegment(y_start, y_end, MAT_WATER))
    return _column(segs^)


def test_values_come_verbatim_from_catalog_json() raises:
    """The evaluator's constants ARE the material_reactions.json values —
    parsed from the normative file, not mirrored literals."""
    var path = join_path(find_repo_root(), REACTIONS_REL)
    var doc = parse_json(read_file_text(path))
    _check(doc.has("reactions"), "material_reactions.json: reactions[]")
    var reactions = doc.get("reactions")
    var found = -1
    for i in range(reactions.len()):
        if reactions.at(i).get("id").as_string() == String(QUENCH_REACTION_ID):
            found = i
    _check(found >= 0, "reaction.lava_water_quench present in the catalog")
    var r = reactions.at(found)

    # Preconditions (face-sharing 6-neighborhood lava + water).
    var pre = r.get("preconditions")
    _check(
        pre.get("primary").as_string() == QUENCH_PRIMARY,
        "primary is fluid.lava",
    )
    _check(
        pre.get("adjacent").as_string() == "fluid.water",
        "adjacent is fluid.water",
    )
    _check(
        pre.get("adjacency_type").as_string() == QUENCH_ADJACENCY,
        "adjacency_type is face_sharing_6_neighborhood",
    )

    # Transformations: source → obsidian, non-source → cobblestone.
    var tr = r.get("transformations")
    _check(tr.len() == 2, "exactly two transformations")
    var t_src = tr.at(0)
    _check(
        t_src.get("condition").as_string().find("is_source_block == True") >= 0,
        "source condition",
    )
    _check(
        t_src.get("outcome").as_string() == vocab_catalog_id_string(MAT_OBSIDIAN),
        "source outcome maps to rock.obsidian",
    )
    _check(
        t_src.get("byproduct").as_string() == QUENCH_BYPRODUCT,
        "source byproduct is fluid.steam",
    )
    _check(
        t_src.get("energy_released_j").as_float() == 15000.0,
        "source energy_released_j == 15000.0",
    )
    var t_non = tr.at(1)
    _check(
        t_non.get("condition").as_string().find("is_source_block == False") >= 0,
        "non-source condition",
    )
    _check(
        t_non.get("outcome").as_string()
        == vocab_catalog_id_string(MAT_COBBLESTONE),
        "non-source outcome maps to rock.cobblestone",
    )
    _check(
        t_non.get("energy_released_j").as_float() == 8000.0,
        "non-source energy_released_j == 8000.0",
    )

    # Evaluator constants agree with the parsed catalog.
    _check(QUENCH_ENERGY_SOURCE_J == 15000.0, "QUENCH_ENERGY_SOURCE_J")
    _check(QUENCH_ENERGY_NONSOURCE_J == 8000.0, "QUENCH_ENERGY_NONSOURCE_J")
    var src = quench_outcome(True)
    _check(src.reacted, "source lava reacts")
    _check(src.outcome == MAT_OBSIDIAN, "source lava → rock.obsidian")
    _check(src.energy_j == 15000.0, "source energy 15000 J")
    var non = quench_outcome(False)
    _check(non.reacted, "non-source lava reacts")
    _check(non.outcome == MAT_COBBLESTONE, "non-source lava → rock.cobblestone")
    _check(non.energy_j == 8000.0, "non-source energy 8000 J")


def test_side_face_source_and_non_source_quench() raises:
    """Lava column with a face-sharing water neighbour across ±x: the top
    lava cell (source) → obsidian, the cells below (non-source) → cobblestone.
    2×2 lattice with the lava at (0,0) and the water at (1,0)."""
    var columns = List[MaterialColumn]()
    columns.append(_bedrock_lava(5, 7))  # (0,0): top y=7 is the source
    columns.append(_water(5, 7))  # (1,0): face-sharing water at every y
    columns.append(_empty_column())  # (0,1)
    columns.append(_empty_column())  # (1,1)
    var report = quench_events(columns, 2)
    _check(report.count() == 3, "three quenched cells (y=5,6,7)")
    var e0 = report.events[0]
    var e1 = report.events[1]
    var e2 = report.events[2]
    _check(e0.y == 5 and not e0.was_source, "y=5 is non-source")
    _check(e0.outcome == MAT_COBBLESTONE, "non-source → cobblestone")
    _check(e0.energy_j == 8000.0, "non-source energy")
    _check(e1.y == 6 and not e1.was_source, "y=6 is non-source")
    _check(e1.outcome == MAT_COBBLESTONE, "non-source → cobblestone")
    _check(e2.y == 7 and e2.was_source, "y=7 is the source block")
    _check(e2.outcome == MAT_OBSIDIAN, "source → obsidian")
    _check(e2.energy_j == 15000.0, "source energy")
    _check(report.energy_j == 8000.0 + 8000.0 + 15000.0, "Σ energy 31000 J")
    # Byproduct fluid.steam recorded per reacted cell (not manifested — §9).
    _check(report.steam_units == 3, "steam byproduct recorded per quench")
    _check(
        report.steam_units == report.count(),
        "one steam byproduct unit per reaction",
    )


def test_vertical_face_adjacency_within_one_column() raises:
    """Face-sharing includes ±y inside the same column: water above and
    below a lava stack quenches both the source (top) and a non-source cell.
    1×1 lattice, segments: water 3, lava 4..6, water 7."""
    var segs = List[ColumnSegment]()
    segs.append(ColumnSegment(0, 0, MAT_BEDROCK))
    segs.append(ColumnSegment(3, 3, MAT_WATER))
    segs.append(ColumnSegment(4, 6, MAT_LAVA))
    segs.append(ColumnSegment(7, 7, MAT_WATER))
    var columns = List[MaterialColumn]()
    columns.append(_column(segs^))
    var report = quench_events(columns, 1)
    _check(report.count() == 2, "y=4 (non-source) and y=6 (source) quench")
    var e0 = report.events[0]
    var e1 = report.events[1]
    _check(e0.y == 4 and not e0.was_source, "y=4 is non-source (water below)")
    _check(e0.outcome == MAT_COBBLESTONE, "y=4 → cobblestone")
    _check(e1.y == 6 and e1.was_source, "y=6 is the source (water above)")
    _check(e1.outcome == MAT_OBSIDIAN, "y=6 → obsidian")
    _check(report.energy_j == 23000.0, "8000 + 15000 J")
    _check(report.steam_units == 2, "steam recorded for both cells")


def test_no_adjacency_is_a_no_op() raises:
    """Lava without any face-sharing water: no events, no steam, no energy."""
    var columns = List[MaterialColumn]()
    columns.append(_bedrock_lava(5, 6))  # 1×1: no neighbours at all
    var report = quench_events(columns, 1)
    _check(report.count() == 0, "isolated lava must not quench")
    _check(report.steam_units == 0, "no steam without adjacency")
    _check(report.energy_j == 0.0, "no energy without adjacency")

    # Water at the DIAGONAL (corner) is not face-sharing → still a no-op.
    var diag = List[MaterialColumn]()
    diag.append(_bedrock_lava(5, 5))  # (0,0)
    diag.append(_empty_column())  # (1,0)
    diag.append(_empty_column())  # (0,1)
    diag.append(_water(5, 5))  # (1,1): shares only an edge/corner
    var diag_report = quench_events(diag, 2)
    _check(
        diag_report.count() == 0,
        "corner-only contact must not quench (face-sharing only)",
    )
    _check(diag_report.steam_units == 0, "corner-only: no steam")


def test_steam_byproduct_recorded_but_energy_accounted() raises:
    """§6 invariant 6: byproduct + energy are recorded in the evaluator
    output (metadata), never implied as manifested effects."""
    var columns = List[MaterialColumn]()
    columns.append(_bedrock_lava(5, 5))
    columns.append(_water(5, 5))
    columns.append(_empty_column())
    columns.append(_empty_column())
    var report = quench_events(columns, 2)
    _check(report.count() == 1, "single quench")
    _check(
        QUENCH_BYPRODUCT == "fluid.steam", "byproduct identity is fluid.steam"
    )
    _check(report.steam_units == 1, "steam recorded in the report")
    var e = report.events[0]
    _check(e.was_source, "single top cell is the source")
    _check(e.outcome == MAT_OBSIDIAN, "obsidian outcome")
    # Energy is accounted (Σ), not rendered — no manifestation this milestone.
    _check(report.energy_j == 15000.0, "energy accounted in the report")


def test_seed1_island_has_zero_quenches() raises:
    """§7: the current seed-1 world-gen geometry has NO lava↔water adjacency
    — asserted (live activation needs eruption/flow semantics, §9 OOS)."""
    var island = build_island(1)
    _check(
        island.quench_count == 0,
        "seed-1 must quench zero cells, got " + String(island.quench_count),
    )
    _check(island.quench_steam_units == 0, "seed-1 steam units == 0")
    _check(island.quench_energy_j == 0.0, "seed-1 quench energy == 0")


def main() raises:
    TestSuite.discover_tests[
        (
            test_values_come_verbatim_from_catalog_json,
            test_side_face_source_and_non_source_quench,
            test_vertical_face_adjacency_within_one_column,
            test_no_adjacency_is_a_no_op,
            test_steam_byproduct_recorded_but_energy_accounted,
            test_seed1_island_has_zero_quenches,
        )
    ]().run()
