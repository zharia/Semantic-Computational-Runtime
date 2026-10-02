# Sprint 01 — Flora Field + Morphogenetic Growth (Mojo)

**Milestone:** [0009 — Flora Upgrade](../spec.md)
**Predecessor sprint:** [Sprint 00 (definitions gate green)](sprint_00_definitions.md)
**Scope:** `applications/godot/src/mojo/` sim core + new/extended mojo tests
**Language:** Mojo (Mojo 1.0.0, `.venv/bin/mojo`)

---

## 1. Objective

Replace the static 0006 one-shot scatter with a **field-gated, growing** flora population: per-cell establishment suitability, per-instance `age` + species growth curve, tick-phase aging, and regrowth/death on edit-driven `world_version` changes (closes the 0006 §9 gap). No selection/trait logic yet (Sprint 02); no contract/scene edits yet (Sprint 03).

## 2. Deliverables

```text
applications/godot/src/mojo/
├── sim/flora.mojo        # EXT: establishment_suitability, growth curve, age, regrowth re-scan
├── sim/world.mojo        # EXT: per-tick flora aging; edit hook → flora re-evaluation
├── sim/runtime.mojo      # EXT: FLORA change-dirty tracking (emission decision; §3.2 rule)
└── sim/parameters.mojo   # + growth-curve params, FLORA_EMIT_EPS, suitability threshold
applications/godot/tests/mojo/
├── test_flora_growth.mojo        # NEW
├── test_flora_placement.mojo     # EXT: field-suitability oracle
├── test_determinism.mojo         # EXT: growth in byte-identical sequence
├── test_projection_purity.mojo   # EXT: growth fingerprint outside projection
└── test_envelope.mojo            # EXT: change-driven FLORA round-trip (framing level)
```

Untouched this sprint: `lib/`, `104_contract.md` prose (rule is exercised in code/tests; documented Sprint 03), adapter, scene, fixture.

## 3. Normative requirements

| # | Requirement | Source |
|---|---|---|
| R1 | `establishment_suitability(cell)` is a **pure function** of `(biome, slope, height, wetness, crater_stress, seed)` — no mutable RNG stream, order-independent; 0006 band preconditions retained as hard gates (`height ≥ SEA_LEVEL + ε`, `slope ≤ band cap`, biome allowed) evaluated **before** suitability | milestone §1.1, AP-20, invariant 4 |
| R2 | Per-instance `age` (ticks since establishment); initial ages from pure hash `(seed, x, z)` so the seed-1 population starts mixed | milestone §5 Sprint 01 |
| R3 | Species growth curve `scale = f_species(age)` monotonic non-decreasing until maturity, then stable; bounded by `FLORA_SCALE_MIN`/`FLORA_SCALE_MAX`; curves + threshold + `FLORA_EMIT_EPS` live in `parameters.mojo` (AP-7) | milestone §5 Sprint 01, AP-22 |
| R4 | Aging (`age += 1`, recompute scale), establishment and death run **once per fixed tick in the tick phase** (`world.mojo`) — never in projection | milestone §3.4, invariant 7 |
| R5 | Regrowth: on edit-driven `world_version` increment, re-scan (affected columns or full row-major — measure, document choice); anchors whose voxel was removed die **same tick**; newly valid cells establish subject to suitability + band + cap | milestone §1, invariant 9 |
| R6 | `0 < count ≤ FLORA_N_MAX` every tick; dead plants removed in the tick they die (AP-22) | invariant 5 |
| R7 | Change-driven emission state: dirty when count changes, species changes, or any scale delta ≥ `FLORA_EMIT_EPS` (relative) since last emission; first snapshot after init always emits | milestone §3.2, invariant 6 |
| R8 | Growth/selection-free determinism: same seed + inputs ⇒ identical `(age, scale)` sequences; no `rand()` anywhere in the new paths (AP-20) | invariant 2 |
| R9 | Projection purity: `test_projection_purity` fingerprint covers flora age/scale state — projecting must not mutate it | invariant 7 |

## 4. Tasks

1. Read milestone §3.1/§3.2/§3.4, §4 rows (Flora/Ecology/Growth/Field), `sim/flora.mojo`, `sim/world.mojo`, `sim/runtime.mojo` (FLORA tracker), `sim/parameters.mojo` §6.8, `tests/mojo/test_flora_placement.mojo`.
2. Add parameters: growth curve constants (per-species maturity ticks + curve shape), `FLORA_SUITABILITY_THRESHOLD`, `FLORA_EMIT_EPS` — table goes to `docs/04` in Sprint 04.
3. Implement suitability + growth + age in `sim/flora.mojo`; extend `FloraInstance` state **sim-side only** (wire record unchanged — `snapshot/types.mojo` FLORA emission stays 24 B).
4. Tick-phase integration + edit hook in `sim/world.mojo`; dirty tracking in `sim/runtime.mojo`.
5. Write `test_flora_growth.mojo`; extend placement/determinism/purity/envelope tests.
6. Run this sprint's gate (§5); re-run full mojo suite (20 existing files) for regressions.

## 5. Acceptance criteria (this sprint's gate)

- [ ] `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_flora_growth.mojo` PASS — (a) scale monotonic non-decreasing until maturity, bounded by `FLORA_SCALE_MIN/MAX`; (b) run-twice identical age/scale sequence; (c) simulated dig → anchor plant absent next tick, freed cell may establish; (d) `0 < count ≤ 4096` at every tick; (e) emission dirty fires exactly on ε-threshold crossings.
- [ ] Extended `test_flora_placement.mojo` PASS — every establishment implies band + `suitability ≥ threshold`; species → catalog resolution retained.
- [ ] `test_determinism.mojo`, `test_projection_purity.mojo`, `test_envelope.mojo` PASS (extensions included).
- [ ] All 20 pre-existing mojo suites still PASS (no regressions).
- [ ] `bash applications/godot/scripts/check_layout.sh` PASS (AP-1).
- [ ] `rg -n "rand\(|random" applications/godot/src/mojo/sim/flora.mojo` → no mutable-stream hits (AP-20 spot check).

## 6. Constraints

- **AP-11/19:** Godot never grows anything — this sprint is sim-only; no scene files touched.
- **AP-20:** pure hashes only (`synthesis/noise.hash01_cells` discipline).
- **AP-7:** every new tunable in `parameters.mojo`, no magic literals.
- **Invariant 8 (layout neutrality):** no changes to `snapshot/encode.mojo` FLORA layout, no schema bump — if a test wants an `age` wire field, that is a spec change first (stop, Rule 19).
