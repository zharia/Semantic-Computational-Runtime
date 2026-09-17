---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-WFC
name: Wave Function Collapse — Constraint-Propagating Tile Synthesis

version: 0.1.0
status: operational

created: 2026-09-16
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: Wave Function Collapse

## Summary

A constraint-satisfaction algorithm that synthesises spatially coherent tile
assignments by collapsing superposed states via entropy-guided selection and
propagating adjacency constraints (Arc Consistency 3 / AC-3).

WFC is a first-class topological operation on a cell complex: each cell holds
a superposition of tile states; constraint propagation preserves the adjacency
contract between adjacent cells.

---

## 1. Semantic Definition

**Wave Function Collapse** (WFC) maps a grid of unconstrained cells to a grid
of collapsed single-tile cells such that every adjacent cell pair satisfies the
`AdjacencyConstraintTable`.

WFC is **NOT**:
- a noise function (WFC is combinatorial, not continuous)
- a random assignment (adjacency semantics are enforced)
- a Markov random field in general (may be deterministic given seed and constraints)
- an implementation detail (tile adjacency semantics are normative)

### Formal Model

Let G = (V, E) be a grid graph. Each v ∈ V holds:
- `superposition(v)`: set of possible tile states T_v ⊆ T
- `entropy(v)`: Shannon entropy H = -Σ p(t)·log₂(p(t)) over T_v

The **AdjacencyConstraintTable** A ⊆ T×T×Direction defines which ordered
(tile, tile, direction) triples are permitted.

**Collapse** operation on vertex v:
1. Sample one tile t from T_v (weighted by tile frequency priors)
2. Set T_v = {t}  (entropy → 0)
3. Enqueue all neighbours of v for propagation

**Propagate** (AC-3):
1. For each queued (v, neighbour n, direction d):
   - Remove from T_n any tile t' where no tile t ∈ T_v permits (t, t', d)
   - If T_n changed, enqueue n's neighbours
2. If any T_v = ∅ → **contradiction**: backtrack or restart with new seed

**Termination**: all cells collapsed (|T_v| = 1 for all v).

---

## 2. Hierarchical WFC

A **HierarchicalWFCSolver** runs WFC at N spatial scales:

| Scale | Resolution | Tile Vocabulary | Purpose |
|---|---|---|---|
| 0 (coarse) | dim/6 × dim/6 | BiomeTile | Biome region assignment |
| 1 (fine) | dim × dim | FeatureTile | Per-column flora/feature |

**Hierarchy invariant**: a Scale-1 cell constrained by a Scale-0 biome tile
may only hold FeatureTile states that are valid within that biome.
This is a **semantic contract**, not an implementation hint.

---

## 3. Biome Tile Vocabulary

| Tile | Code | Description |
|---|---|---|
| `DEEP_OCEAN` | 0 | Deep seafloor; basalt substrate |
| `SHALLOW_WATER` | 1 | Reef zone; sandy/basalt floor |
| `BEACH` | 2 | Silica sand, black sand shoreline |
| `COASTAL_JUNGLE` | 3 | Palm groves, coastal shrubs |
| `DENSE_RAINFOREST` | 4 | Hardwood canopy, bamboo, ferns |
| `VOLCANIC_SLOPE` | 5 | Basalt cliffs, pumice, sparse trees |
| `CALDERA_RIM` | 6 | Obsidian shards, sulfur vents, ash |
| `CALDERA_LAKE` | 7 | Active lava lake |
| `LAVA_RIVER` | 8 | Active lava channel crossing slopes |

---

## 4. Feature Tile Vocabulary

| Tile | Code | Valid Biomes |
|---|---|---|
| `NONE` | 0 | (all — bare ground) |
| `PALM_CLUSTER` | 1 | BEACH, COASTAL_JUNGLE |
| `PALM_SOLO` | 2 | BEACH, COASTAL_JUNGLE |
| `BAMBOO_GROVE` | 3 | COASTAL_JUNGLE, DENSE_RAINFOREST |
| `CANOPY_TREE` | 4 | DENSE_RAINFOREST, COASTAL_JUNGLE |
| `CANOPY_CLUSTER` | 5 | DENSE_RAINFOREST |
| `SHRUB` | 6 | BEACH, COASTAL_JUNGLE, DENSE_RAINFOREST |
| `FERN_CARPET` | 7 | COASTAL_JUNGLE, DENSE_RAINFOREST |
| `BASALT_BOULDER` | 8 | VOLCANIC_SLOPE, CALDERA_RIM |
| `PUMICE_BOULDER` | 9 | VOLCANIC_SLOPE |
| `OBSIDIAN_SHARD` | 10 | CALDERA_RIM |
| `SULFUR_VENT` | 11 | CALDERA_RIM |
| `ASH_FLAT` | 12 | CALDERA_RIM, VOLCANIC_SLOPE |
| `LAVA_POOL` | 13 | CALDERA_LAKE, LAVA_RIVER |

---

## 5. AdjacencyConstraintTable (Normative)

The table encodes the directed permissible adjacency relation A(t₁, t₂, direction).
Since biome tiles form geographic zones the table is symmetric and direction-independent
at scale 0 (the island has no preferred orientation). Direction is preserved for
feature tiles to allow asymmetric natural patterns (e.g., ferns grow on north-facing slopes).

**Biome-Biome Adjacency (normative):**

```
DEEP_OCEAN      ↔ SHALLOW_WATER
SHALLOW_WATER   ↔ DEEP_OCEAN, BEACH
BEACH           ↔ SHALLOW_WATER, COASTAL_JUNGLE
COASTAL_JUNGLE  ↔ BEACH, DENSE_RAINFOREST
DENSE_RAINFOREST↔ COASTAL_JUNGLE, VOLCANIC_SLOPE
VOLCANIC_SLOPE  ↔ DENSE_RAINFOREST, CALDERA_RIM, LAVA_RIVER
CALDERA_RIM     ↔ VOLCANIC_SLOPE, CALDERA_LAKE
CALDERA_LAKE    ↔ CALDERA_RIM
LAVA_RIVER      ↔ VOLCANIC_SLOPE, CALDERA_RIM (directional: downhill)
```

This table is the **authoritative semantic contract**. An implementation that
violates it produces a result that does not conform to this specification.

---

## 6. Semantic Invariants

1. **Completeness**: every cell is collapsed to exactly one tile on successful termination
2. **Consistency**: all adjacent cell pairs satisfy the AdjacencyConstraintTable
3. **Determinism**: identical (seed, grid size, constraints) → identical output
4. **Hierarchy**: Scale-1 feature assignment never contradicts Scale-0 biome
5. **No contradiction tolerance in production**: a contradiction state invalidates the solve;
   the solver MUST restart with a modified seed or report failure

---

## 7. Provider Contract

An implementation MUST:
- Accept `uint32_t seed` and produce deterministic output
- Enforce the AdjacencyConstraintTable without exception
- Report contradiction state as an observable error (not silently recover by ignoring constraints)
- Run to completion in O(n log n) expected time for acyclic grids

---

## 8. Relationships

| Relation | Target | Kind |
|---|---|---|
| depends-on | SCR-LIB-TOPOLOGY-ADJACENCY | adjacency contract |
| depends-on | SCR-LIB-MATH-PROBABILITY | tile frequency priors |
| depends-on | SCR-LIB-MATH-RANDOM | entropy-guided selection |
| consumed-by | SCR-LIB-SPATIAL-VOXEL-SYNTHESIS | biome → voxel material |
| consumed-by | SCR-APP-CAVE-ISLAND | island environment synthesis |
