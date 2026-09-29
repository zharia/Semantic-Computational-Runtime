# Quench evaluator — `reaction.lava_water_quench` implemented VERBATIM from
# lib/A01_Render/Material/material_reactions.json (milestone_0005 §1.1 (c)).
#
#   preconditions : primary `fluid.lava`, adjacent `fluid.water`,
#                   adjacency_type `face_sharing_6_neighborhood`
#   transformations: primary.is_source_block == True  → `rock.obsidian`
#                    primary.is_source_block == False → `rock.cobblestone`
#                    byproduct `fluid.steam` (15000 J source / 8000 J non-source)
#   conservations : mass_conservation, enthalpy_dissipation
#
# Evaluation point (locked decision (c)): the world-gen lattice, as a
# synthesis adjacency pass — no live lava-flow activation (that needs
# eruption/flow semantics, §9 OOS). No adjacency ⇒ no-op.
#
# Source-block definition at world-gen (no flow state exists yet — §9):
# the TOPMOST lava cell of a column is the pool surface ⇒ source; every lava
# cell below it is non-source. This matches world-gen reality (CALDERA_LAKE
# writes one surface lava cell per column) and exercises both catalog
# branches.
#
# Byproduct handling (recorded deviation, sprint 04 documents it): steam is
# RECORDED in the evaluator output (`steam_units`, `QUENCH_BYPRODUCT`) but is
# NOT manifested — the lattice has no steam field and the snapshot carries no
# steam section. Energy is accounted, not rendered (AP-14: never implied).

from std.collections import List

from synthesis.noise import NoiseContext
from synthesis.voxel import (
    MaterialColumn,
    voxel_synthesis_pipeline,
    BIOME_CALDERA_LAKE,
    BIOME_LAVA_RIVER,
    FEATURE_NONE,
)
from materials.catalog import MAT_LAVA, MAT_WATER, MAT_OBSIDIAN, MAT_COBBLESTONE
from sim.parameters import GRID_N

comptime QUENCH_REACTION_ID: String = "reaction.lava_water_quench"
comptime QUENCH_BYPRODUCT: String = "fluid.steam"
comptime QUENCH_PRIMARY: String = "fluid.lava"
comptime QUENCH_ADJACENCY: String = "face_sharing_6_neighborhood"
comptime QUENCH_ENERGY_SOURCE_J: Float64 = 15000.0
comptime QUENCH_ENERGY_NONSOURCE_J: Float64 = 8000.0


struct QuenchOutcome(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """One transformation row of reaction.lava_water_quench."""

    var reacted: Bool  # False ⇒ no-op (no water adjacency / not lava)
    var outcome: UInt32  # voxel code the lava cell becomes
    var energy_j: Float64  # energy_released_j (accounted, not manifested)

    def __init__(out self, reacted: Bool, outcome: UInt32, energy_j: Float64):
        self.reacted = reacted
        self.outcome = outcome
        self.energy_j = energy_j

    def __deinit__(deinit self):
        pass


struct QuenchEvent(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    var ix: Int  # grid column
    var iz: Int
    var y: Int  # lattice y of the quenched lava cell
    var was_source: Bool
    var outcome: UInt32  # MAT_OBSIDIAN (source) / MAT_COBBLESTONE (non-source)
    var energy_j: Float64

    def __init__(
        out self,
        ix: Int,
        iz: Int,
        y: Int,
        was_source: Bool,
        outcome: UInt32,
        energy_j: Float64,
    ):
        self.ix = ix
        self.iz = iz
        self.y = y
        self.was_source = was_source
        self.outcome = outcome
        self.energy_j = energy_j

    def __deinit__(deinit self):
        pass


struct QuenchReport(Movable, Deinitable):
    """Evaluator output (world-gen metadata; not a wire section)."""

    var events: List[QuenchEvent]
    var steam_units: Int  # byproduct fluid.steam per reacted cell
    var energy_j: Float64  # Σ energy_released_j

    def __init__(out self):
        self.events = List[QuenchEvent]()
        self.steam_units = 0
        self.energy_j = 0.0

    def __deinit__(deinit self):
        pass

    def count(self) -> Int:
        return len(self.events)


def quench_outcome(lava_is_source: Bool) -> QuenchOutcome:
    """Catalog-verbatim transformation (values from material_reactions.json)."""
    if lava_is_source:
        return QuenchOutcome(True, MAT_OBSIDIAN, QUENCH_ENERGY_SOURCE_J)
    return QuenchOutcome(True, MAT_COBBLESTONE, QUENCH_ENERGY_NONSOURCE_J)


def _material_at(col: MaterialColumn, y: Int) raises -> Int:
    """Material at lattice y, or −1 when the column does not cover y."""
    if y < 0:
        return -1
    if not col.covers(y):
        return -1
    return Int(col.material_at(y))


def _topmost_lava(col: MaterialColumn) -> Int:
    """Highest lava cell of the column (−1 if none) — the source block."""
    var top = -1
    for i in range(len(col.segments)):
        var s = col.segments[i].copy()
        if s.material == MAT_LAVA and s.y_end > top:
            top = s.y_end
    return top


def _has_water_adjacency(
    columns: List[MaterialColumn],
    ix: Int,
    iz: Int,
    grid_n: Int,
    col: MaterialColumn,
    y: Int,
) raises -> Bool:
    """Face-sharing 6-neighborhood: ±y inside col, ±x/±z in sibling columns."""
    var w = Int(MAT_WATER)
    if _material_at(col, y - 1) == w:
        return True
    if _material_at(col, y + 1) == w:
        return True
    if ix > 0 and _material_at(columns[iz * grid_n + (ix - 1)], y) == w:
        return True
    if ix + 1 < grid_n and _material_at(columns[iz * grid_n + (ix + 1)], y) == w:
        return True
    if iz > 0 and _material_at(columns[(iz - 1) * grid_n + ix], y) == w:
        return True
    if iz + 1 < grid_n and _material_at(columns[(iz + 1) * grid_n + ix], y) == w:
        return True
    return False


def quench_events(
    columns: List[MaterialColumn], grid_n: Int
) raises -> QuenchReport:
    """Face-sharing 6-neighborhood scan of a full column grid.

    columns[i] with i = iz · grid_n + ix. Every lava cell with at least one
    water face-neighbour produces one event with the catalog outcome.
    Cells without adjacency produce nothing (no-op)."""
    if len(columns) != grid_n * grid_n:
        raise Error(
            "quench_events expects " + String(grid_n * grid_n)
            + " columns, got " + String(len(columns))
        )
    var report = QuenchReport()
    for iz in range(grid_n):
        for ix in range(grid_n):
            var idx = iz * grid_n + ix
            var top_lava = _topmost_lava(columns[idx])
            if top_lava < 0:
                continue
            var segments = columns[idx].segments.copy()
            for i in range(len(segments)):
                var s = segments[i].copy()
                if s.material != MAT_LAVA:
                    continue
                for y in range(s.y_start, s.y_end + 1):
                    if not _has_water_adjacency(
                        columns, ix, iz, grid_n, columns[idx], y
                    ):
                        continue
                    var is_source = y == top_lava
                    var out = quench_outcome(is_source)
                    report.events.append(
                        QuenchEvent(
                            ix, iz, y, is_source, out.outcome, out.energy_j
                        )
                    )
                    report.steam_units += 1
                    report.energy_j += out.energy_j
    return report^


def build_quench_columns(
    biomes: List[Int], heights: List[Float64], grid_n: Int, ctx: NoiseContext
) raises -> List[MaterialColumn]:
    """Rebuild the world-gen columns (pure pipeline, same inputs as
    sim/island.mojo) for the adjacency pass."""
    if len(biomes) != grid_n * grid_n or len(heights) != grid_n * grid_n:
        raise Error("build_quench_columns: grid size mismatch")
    var columns = List[MaterialColumn]()
    for iz in range(grid_n):
        for ix in range(grid_n):
            var i = iz * grid_n + ix
            columns.append(
                voxel_synthesis_pipeline(
                    ix, iz, biomes[i], FEATURE_NONE, heights[i], ctx
                )
            )
    return columns^


def run_quench_pass(
    biomes: List[Int], heights: List[Float64], grid_n: Int, ctx: NoiseContext
) raises -> QuenchReport:
    """World-gen quench evaluation (synthesis adjacency pass)."""
    var columns = build_quench_columns(biomes, heights, grid_n, ctx)
    return quench_events(columns, grid_n)


def lava_biome(biome: Int) -> Bool:
    """Biomes whose §2 surface row is LAVA (caldera lake / lava river)."""
    return biome == BIOME_CALDERA_LAKE or biome == BIOME_LAVA_RIVER
