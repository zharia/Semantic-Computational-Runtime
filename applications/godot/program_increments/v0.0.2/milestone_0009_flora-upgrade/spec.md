# Milestone 0009: Flora Upgrade — Field, Growth, Selection

**Program Increment:** v0.0.2
**Milestone:** 0009 — Flora Upgrade (field + morphogenesis + selection)
**Project:** Godot Simulation (applications/godot)
**Parent System:** Semantic Computational Runtime (SCR)
**Status:** Complete
**Primary Language:** Mojo
**Initial Engine Provider:** Godot 4.7.2
**Binding Architecture:** Definition-first (`lib/705_Ecology/Flora` + control-plane backfill) + layout-neutral contract change (FLORA emission rule; schema 6 / ABI 2 preserved)
**Scene Scope:** Living flora — establishment field, per-instance growth, selection+variation, regrowth after edits
**Predecessor:** [milestone 0008](../../v0.0.1/milestone_0008_ipc-transport/spec.md) (Complete) — executes after 0008 on the stabilized contract

---

## 1. Scope & Objective

Upgrade the flora system from **static scatter at init** (milestone 0006: pure hash + band table, one-shot instance list) to a **living flora system**:

1. **Flora field** — normative per-cell establishment suitability over the terrain domain (the concept "flora field" exists nowhere in the repository today; it is defined in Sprint 00 before any code).
2. **Morphogenetic growth** — every plant has an age and a deterministic growth trajectory (age → scale); growth integrates on the fixed timestep and is visible in-scene.
3. **Selection + variation** — per-instance trait variation (volcano-ash / drought tolerance) filtered by local environment at establishment and survival: differential persistence without reproduction.
4. **Regrowth after edits** — flora re-evaluates when `world_version` increments (0007 voxel edits): dug-out plants die, freed cells may establish. Closes the 0006 §9 honest gap "flora regrowth after 0007 edits `TBD`".

**Definition-first (Rule 10):** missing/stub semantic definitions are extended in Sprint 00 and gated before any implementation code exists. Implementation sprints 01–04 are hard-blocked on the Sprint 00 gate.

- **Mojo simulation core** owns all flora meaning: field, growth, traits, selection, regrowth, counts.
- **Godot** remains strictly presentation: it materializes the FLORA section (same 24-byte records) into `MultiMeshInstance3D`; growth is read from the wire, never animated from `TIME` (sway stays display-only).
- **Contract** stays layout-neutral: no schema bump, no ABI bump, fixture regenerated for content only (0008 precedent).

### 1.1 Decisions Locked (confirmed with stakeholder before drafting)

| Decision | Choice | Rationale |
|---|---|---|
| Evolution depth | **Selection + variation only** — per-instance heritable trait vector, establishment/survival filter, differential persistence. **No reproduction, no generational inheritance** | Bounded vertical slice of `704_Evolution`; `503_Simulation/Reproduction` and `601_Agent/Population` stubs stay untouched (Rule 15); full generations = successor |
| Growth model | **Age/scale growth, dynamic FLORA** — per-instance `age` + species growth curve → `scale(age)`; FLORA emission becomes change-driven (was world_version-gated) | Stakeholder decision; growth visible in-scene; ~154 records ≈ 3.7 KB/tick ≈ 220 KB/s at 60 Hz — within budget |
| Wire layout | **FLORA record stays 24 B** (`position, yaw, scale, species_id`); `SCR_SIM_SCHEMA_VER` stays **6**, `SCR_SIM_ABI_VERSION` stays **2**; only the emission rule in `104_contract.md` §10 is rewritten | Layout-neutral precedent (0008). Renderer already consumes `scale` — growth needs no new field |
| Definition placement | **New `lib/705_Ecology/Flora/`** (101 + 102 + 103) + **backfill missing control plane** for `lib/704_Evolution/` and `lib/705_Ecology/` (both lack `102_status.yaml` / `103_library.graph.json` today) | Stakeholder decision; both 101 definitions are complete and authoritative — only control plane is absent |
| Voxel/lattice flora (Synthesis §3) | **Out of scope** — instance/MultiMesh realization retained; recorded deviation stays open | Stakeholder decision; Rule 15 minimal complete slice |
| Trait stress model | Establishment/survival stress = **volcano proximity (ash)** ∧ **local wetness (drought)** — both already exist in sim (0003 volcano subject, 0004 weather wetness) | No invented inputs; stress is a pure function of existing world state |
| Field definition | Flora field = pure per-cell function `establishment_suitability(x, z, biome, slope, height, wetness, stress, seed)` — no RNG stream, order-independent | Extends 0006 placement discipline (pure hashes, `test_flora_placement` oracle) |
| Emission quantization | FLORA emits when `count` changes or any instance `scale` delta ≥ `FLORA_EMIT_EPS` (relative) since last emission; otherwise holds | AP-22: prevents pointless per-tick section spam after maturity |
| Sibling rebase | None needed — 0009 is the first v0.0.2 milestone; carries then-current schema/ABI through unchanged | Same rule as 0008 §1.1 |

### 1.2 Open decision — confirm before drafting final

- **Stress model detail:** ash stress from volcano plume distance vs. crater distance (plume is wind-advected in shader only — sim has volcano state + quench/lava fields, not a sim-side plume mask). Recommend **crater-distance + local wetness** (both pure sim state). Confirm before Sprint 02 (Rule 19).

### 1.3 Governing Principle

> Never allow implementation convenience to silently redefine computational semantics.

```text
Semantic Meaning → Contract → Representation → Transformation → Lowering → Provider → Runtime → Execution Substrate
```

Flora meaning lives in `lib/705_Ecology/Flora` (new), `lib/705_Ecology`, `lib/704_Evolution`, and `lib/401_Morphology/Growth` — defined **before** code. The FLORA section is contract, not meaning. Growth, selection and death are sim state; Godot only renders poses. If any implementation decision (growth curve shape, trait semantics, emission timing) is not traceable to a definition or this spec, it is wrong.

---

## 2. Lessons & Anti-pattern Constraints (Normative)

### 2.1 Continuing normative constraints — linked, not re-tabled

- [Milestone 0002 §2.1 AP-1 … AP-10](../../v0.0.1/milestone_0002_scene-initiation/spec.md) (engine isolation, executable conformance, single material vocabulary, no absolute paths, no monolith dispatch, typed contracts, tunables in parameters, one-way state channel, no render-thread stalls, provider control docs).
- [Milestone 0006 §2.2 AP-11 … AP-14](../../v0.0.1/milestone_0006_ecology/spec.md) (presentation-owned ecology, display animation leaks into semantics, unbounded instance growth, parallel species vocabulary).
- Milestone 0007 AP-11 … AP-14 (edit/physics lessons) and [milestone 0008 §2.2 AP-15 … AP-18](../../v0.0.1/milestone_0008_ipc-transport/spec.md) (worker-thread I/O, transport-aware payload, silent version drift, orphan servers) — 0008 transport gates re-run as part of §7.

Their §7 gate commands are re-run as this milestone's final gate set (§7).

### 2.2 New milestone-specific anti-patterns (this milestone only)

| # | Anti-pattern | Required correction |
|---|---|---|
| AP-19 | **Presentation-owned growth/evolution** — Godot grows instances via shader/`TIME` counters, or GDScript ages plants | `age`, `scale(age)`, trait values, survival and death are sim state on the wire; shader `TIME` remains display-only sway (0006 AP-12 unchanged). Gate: growth sequence asserted in `test_flora_growth`; removing shader TIME changes no snapshot byte |
| AP-20 | **Mutable RNG stream in field/growth/traits** — `rand()` seeded once and consumed in call order (breaks run-twice determinism and order-independence) | Every decision (establishment, trait, yaw, scale curve jitter) is a pure hash of `(seed, cell, age, trait-salt)` — same discipline as 0006 `feature_for_column`. Gate: run-twice byte-identical tests |
| AP-21 | **Implementation-before-definition** — flora field/growth/evolution semantics decided in Mojo first, docs backfilled later | Sprint 00 definition gate (`scr-domain-validator` + section checklist) must be green **before** sprints 01–04 start; no `src/mojo` edits in the Sprint 00 commit (Rule 10) |
| AP-22 | **Unbounded FLORA emission** — full section re-sent every tick regardless of change, or growth accumulates past `FLORA_N_MAX` | Change-driven emission with `FLORA_EMIT_EPS` quantization; `count ≤ FLORA_N_MAX` asserted every tick; dead plants removed in the same tick they die (cap never exceeded) |

---

## 3. Architecture & Binding Contract

### 3.1 Layer diagram (delta over milestone 0006 §3.1)

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ SCR semantic library (lib/) — meaning, authoritative                    │
│   705_Ecology/Flora (NEW: flora population, flora field, growth,        │
│                      selection conformance)                             │
│   705_Ecology (population/environment/state; 102+103 backfilled)        │
│   704_Evolution (variation/selection/differential persistence;          │
│                   102+103 backfilled)                                   │
│   401_Morphology/Growth (constructive morphogenesis)                    │
│   301_Field (field = semantic structure over a domain)                  │
│   801_Spatial/Voxel/Synthesis §3 (species vocabulary, unchanged)        │
│   A01_Render/Material (catalog, unchanged)                              │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Mojo simulation core — src/mojo/ (semantic consumer)                    │
│   + sim/flora.mojo  : flora_field (suitability), growth curve,          │
│                       traits + selection, regrowth on world_version     │
│   + sim/world.mojo  : flora ages each fixed tick; edit hook → re-scan   │
│   owns: establishment/survival/death, age/scale, counts                 │
│   output: RenderSnapshot (FLORA now change-driven emission)             │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │ C ABI (.so) — unchanged symbols; schema 6
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Provider adapter — providers/render/graphics/godot/adapter/             │
│   apply_flora unchanged (24-B records) — called on every FLORA present  │
│   NO growth/selection decisions; representation conversion only         │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Godot scene — godot/scenes/island.tscn                                  │
│   flora_view.gd: instances carry wire scale (growth is sim-owned);      │
│   flora_wing.gdshader: sway stays display-only on TIME (AP-19)          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Contract change — emission rule only (normative draft for `104_contract.md` §10)

**No layout change.** Section `10 — FLORA` stays `4 + 24·count` bytes, records unchanged, `SCR_SIM_SCHEMA_VER` stays `6`, `SCR_SIM_ABI_VERSION` stays `2`, golden fixture regenerates for **content only** (initial ages make tick-1 scales differ).

Emission rule, replacing 0006's "first snapshot after init + whenever `world_version` increments":

> **FLORA is change-driven:** present on (a) the first snapshot after init, (b) any snapshot where `count` differs from the last emission, or (c) any snapshot where at least one instance's `scale` changed by ≥ `FLORA_EMIT_EPS` (relative) or its `species_id` changed vs. the last emission. Position/yaw changes alone (none expected this milestone) also trigger. When absent, the adapter **retains cached instances** (0006 invariant 5 wording preserved).

`FAUNA`, `TERRAIN`, and all other sections unchanged. Adapter validation ranges unchanged (`species_id ∈ [1,7]`, `scale > 0`, `count ≤ 4096`).

### 3.3 Data flow rules (inherited, unchanged)

Down: sim tick → project (pure) → encode → adapter decode → node update. Up: input/edit batch only — **no new uplink**. One channel: snapshot is the only state channel. Transport: in-process default; socket mode (`SCR_SIM_TRANSPORT=socket`, `SCR_SIM_IPC_PACE=manual` for rendered gates) passes the same bytes through untouched (0008).

### 3.4 Timestep & display animation

60 Hz fixed timestep unchanged. Growth (`age += 1` per tick, recompute `scale(age)`), establishment and death integrate **once per fixed tick, in the tick phase** (world mutation), never in the projection. Display animation stays display-only: frond sway / wing flap run on shader `TIME` — no growth phase in the shader (AP-19). Optional renderer-side interpolation between wire scales is presentation-only and must be disabled for screenshot gates (screenshots assert the wire values).

---

## 4. Semantic Library Consumption

Consumption **by semantic ID**, consistent with `lib/README.md` conventions and milestone 0002 §4.

| Domain / ID | Concept consumed (verified on disk) | Consumption mode |
|---|---|---|
| `SCR-LIB-ECOLOGY-FLORA` (`lib/705_Ecology/Flora` — **NEW, defined in Sprint 00**) | Flora population (membership = instance list), **flora field** (establishment suitability over terrain cells), growth conformance, selection conformance, determinism statement | **Spec-first:** Sprint 00 writes the definition; sprints 01–02 implement exactly what it normatively states. The definition is the review oracle for `test_flora_growth` / `test_flora_evolution` |
| `SCR-LIB-ECOLOGY` (`lib/705_Ecology` — 101 complete; **102 + 103 missing → backfilled in Sprint 00**) | §1 Population, §3 Environment, §9 Ecological State (composition/abundance/distribution), §17 Ecological Fields ("fields may influence populations, while populations may modify fields"), §43 Determinism; `ECOLOGY-INV-003/004/009/010`, `ECOLOGY-INV-012` (adaptation distinction), `ECOLOGY-INV-013` (evolution distinction — ecology must not redefine evolution) | Spec-only contract — implement in Mojo per definition. INV-013 is the firewall: trait/selection semantics belong to `704_Evolution`, population/environment to Ecology |
| `SCR-LIB-EVOLUTION` (`lib/704_Evolution` — 101 complete, draft; **102 + 103 missing → backfilled in Sprint 00**) | Definition: persistent change via **variation, inheritance, selection, transformation, differential persistence**; `EVOLUTION-INV-004` (Variation), `INV-005` (Selection), `INV-009` (Viability), `INV-011` (Environmental), `INV-018` (Reproducibility); explicitly ≠ adaptation/learning/optimization | Spec-only — implement variation (trait vector from pure hash) + selection (establishment/survival filter) + differential persistence (some cells fail / some plants die). **Honest limitation:** `INV-006 Inheritance` / `INV-007 Lineage` are satisfied trivially (trait constant over instance life); cross-generational inheritance needs reproduction — out of scope, recorded in §9 and `docs/04` |
| `SCR-LIB-MORPHOLOGY-GROWTH` (`lib/401_Morphology/Growth`) | "Constructive morphogenesis, developmental accretion, and volumetric expansion over time"; `MORPHOLOGY-INV-016/017/018` (representation/provider/rendering independence) | Spec-only — growth curve = developmental accretion; wire `scale` is a **representation** of growth state, never its definition (INV-018: visual appearance ≠ meaning) |
| `SCR-LIB-FIELDS` (`lib/301_Field`) | "A Field … assigns, relates, or evolves meaningful information over a defined domain" — not merely an array/grid of samples | Spec-only — the flora field is a Field specialization over the terrain-cell domain: suitability is meaningful (establishment), not a sampled texture |
| `SCR-LIB-SPATIAL-VOXEL-SYNTHESIS` (`lib/801_Spatial/Voxel/Synthesis` §3) | Feature → flora-object species vocabulary (PALM/CANOPY/SHRUB/FERN/BAMBOO rows) | Unchanged from 0006 — species vocabulary and recorded voxel-object deviation carry over verbatim |
| `SCR-LIB-RENDER-MATERIAL` (`lib/A01_Render/Material`) | `materials_catalog.json` species → material ids | Unchanged from 0006 (AP-3/AP-14) |
| `SCR-LIB-SPATIAL` (`lib/801_Spatial`) | Position = value + explicit world frame | Unchanged from 0006 |

**Not consumed this milestone:** `601_Agent` (plants are not agents — flock only), `503_Simulation/Reproduction` and `601_Agent/Population` (stubs stay untouched, §9), `501_Physics`, MLIR work (Rule 15).

---

## 5. Deliverables & Sprint Breakdown

```text
lib/                                             # Sprint 00 — definitions BEFORE code
├── 705_Ecology/Flora/
│   ├── 101_definition.md                        # NEW: flora population, flora field, growth + selection conformance, determinism
│   ├── 102_status.yaml                          # NEW
│   └── 103_library.graph.json                   # NEW: CONTAINS (from Ecology), REFINES (Field), INTERACTS_WITH (Morphology/Growth, Evolution)
├── 705_Ecology/
│   ├── 102_status.yaml                          # NEW (backfill — 101 exists)
│   └── 103_library.graph.json                   # NEW (backfill)
└── 704_Evolution/
    ├── 102_status.yaml                          # NEW (backfill — 101 exists)
    └── 103_library.graph.json                   # NEW (backfill)

applications/godot/
├── src/mojo/
│   ├── sim/flora.mojo                           # EXT: flora_field, growth curve, traits, selection, death, regrowth re-scan
│   ├── sim/world.mojo                           # EXT: per-tick flora aging; edit hook → flora re-evaluation
│   ├── sim/runtime.mojo                         # EXT: FLORA change-dirty tracking (emission rule §3.2)
│   └── sim/parameters.mojo                      # + growth curves, trait/stress params, FLORA_EMIT_EPS
├── providers/render/graphics/godot/
│   ├── 104_contract.md                          # §10 emission rule rewrite; schema/ABI unchanged
│   ├── 102_status.yaml                          # capability note (if applicable)
│   └── 103_provider.graph.json                  # relationship backfill if the Flora domain edge changes
├── godot/scripts/flora_view.gd                  # EXT: consume wire scale per snapshot (growth visible; sway untouched)
├── tests/mojo/
│   ├── test_flora_growth.mojo                   # NEW: growth/determinism/regrowth/cap gates
│   ├── test_flora_evolution.mojo                # NEW: variation/selection/differential persistence gates
│   ├── test_flora_placement.mojo                # EXT: field-suitability oracle (establishment implies suitability > threshold)
│   ├── test_determinism.mojo                    # EXT: growth + selection in the byte-identical sequence
│   ├── test_projection_purity.mojo              # EXT: growth fingerprint outside projection
│   ├── test_envelope.mojo                       # EXT: change-driven FLORA framing round-trip
│   └── gen_golden_fixture.mojo                  # RUN: fixture regen (content; schema stays 6)
├── tests/fixtures/snapshot_seed1_tick1.bin      # REGENERATED (content only)
├── tests/godot/
│   ├── godot_screenshot.gd / .sh                # EXT: growth evidence (scale distribution changes across ticks)
│   └── godot_load_test.sh                       # re-run gate
├── docs/04_simulation_engine.md                 # + flora field/growth/selection model, params, evidence table, AP-19..22 review
├── docs/06_roadmap.md                           # + v0.0.2 section, 0009 row
└── program_increments/v0.0.2/milestone_0009_flora-upgrade/spec.md    # this file
```

### Sprint 00 — Definitions (Rule 10 gate; no `src/mojo` changes)

- Write `lib/705_Ecology/Flora/101_definition.md` (front matter modeled on `lib/401_Morphology/Growth/101_definition.md`; required sections per `scr-new-domain` skill): Summary, Semantic Definition (population, **flora field**, growth, selection, determinism), invariants consumed + conformance statements, Relationships (Ecology CONTAINS, Field REFINES, Morphology/Growth INTERACTS_WITH, Evolution INTERACTS_WITH), Definition Authority footer.
- Backfill `102_status.yaml` + `103_library.graph.json` for `704_Evolution` and `705_Ecology` — **relationship types strictly from the controlled vocabulary** in `001_agents/02_graph_relationships.md` (`CONTAINS/REFINES/INTERACTS_WITH/CONSTRAINS/...`); no invented types; `103` stays derived (not authoritative).
- Stubs `503_Simulation/Reproduction`, `601_Agent/Population` untouched (§9).
- **Gate:** `scr-domain-validator` agent over `lib/705_Ecology` (incl. Flora) + `lib/704_Evolution` returns zero findings; checklist: required sections present, status values valid, graph edges use controlled vocabulary, directory naming conventions.

### Sprint 01 — Flora field + morphogenetic growth (Mojo)

- `flora_field` / `establishment_suitability(cell)` — pure function of `(biome, slope, height, wetness, crater_stress, seed)`; supersedes the bare density hash as the establishment gate (band rules from 0006 retained as hard preconditions: height ≥ `SEA_LEVEL + ε`, slope ≤ cap, allowed biome).
- Growth: per-instance `age` (ticks since establishment; initial ages from pure hash of `(seed, x, z)` so the population starts mixed); species growth curve `scale = f_species(age)` monotonic to maturity, then stable; curves + `FLORA_EMIT_EPS` in `parameters.mojo` (AP-7).
- Tick-phase integration in `world.mojo`: age +1 per fixed tick; recompute dirty scales.
- Regrowth: on edit-driven `world_version` increment, re-scan affected columns (or full deterministic row-major rescan — measure first): dead anchors (voxel removed) removed same tick; newly valid cells establish subject to field + cap; emitted via change-driven rule.
- Tests `test_flora_growth.mojo`: (a) scale monotonic non-decreasing until maturity, bounded by `FLORA_SCALE_MIN/MAX`; (b) run-twice identical age/scale sequence; (c) after a simulated dig (height → below band), anchor plant absent next tick; freed cell may establish; (d) `0 < count ≤ FLORA_N_MAX` every tick; (e) emission triggers exactly on ε-threshold crossings (dirty-flag unit checks).

### Sprint 02 — Selection + variation (Mojo)

- Trait vector per instance: fixed-size (≤ 4 traits, f32 each — ash tolerance, drought tolerance; salts reserved) from pure hash `(seed, cell, trait_salt)` — heritable in the trivial sense (constant over instance life), recorded against `704_Evolution INV-006/007` as the §9 limitation.
- Establishment selection: cell fails establishment if local stress exceeds the candidate's tolerance (crater-distance ash term ∧ wetness drought term — §1.2 open decision for the exact stress formula).
- Survival selection: mature/immature plants die when sustained local stress exceeds tolerance (death is deterministic given state; dead removed same tick).
- Tests `test_flora_evolution.mojo`: (a) trait distribution over the population matches the hash distribution (statistical sanity, fixed seed); (b) high-stress band (crater rim / dry cells) has significantly lower establishment rate than a comparable low-stress band; (c) raising stress (synthetic wetness drop) kills a deterministic superset of plants; (d) run-twice identical; (e) no cap violation after deaths.

### Sprint 03 — Contract + fixture + adapter + scene

- `104_contract.md` §10 emission rewrite (§3.2); explicit "schema/ABI unchanged" statement; adapter `apply_flora` dispatch condition updated (present-on-change, retain-on-absence unchanged).
- Fixture regen (`gen_golden_fixture.mojo`) + `test_golden_fixture` + `abi_smoke.py` (schema 6 asserts unchanged) + `test_schema_mismatch.sh` re-run (6 accepted, 5/7 refused).
- `flora_view.gd`: per-snapshot instance scale from wire (MultiMesh transform update path already exists — extend only where it currently assumes fixed scale); sway shader untouched.
- AP-1 gate (`check_layout.sh`) re-run: zero engine types in `src/mojo/`.

### Sprint 04 — Docs + verification

- `docs/04_simulation_engine.md`: flora field/growth/selection domain model, parameter table (`§6.8` extension), emission rule, evidence table (growth across ticks), honest limitations (no reproduction, crater-vs-plume stress choice); `docs/06_roadmap.md`: v0.0.2 + 0009 row.
- Full §7 gate run; anti-pattern review AP-1..22 item-by-item, table appended to `docs/04` §9-style.

---

## 6. Formal Invariants

1. **Definition-authority invariant:** the Sprint 00 gate is green before any implementation commit; every flora behavior implemented is traceable to `lib/705_Ecology/Flora`, `704_Evolution`, `705_Ecology`, `401_Morphology/Growth`, `301_Field`, or this spec (Rule 10, AP-21).
2. **Growth determinism invariant:** same seed + same inputs + same tick sequence ⇒ identical `(age, scale)` per instance; growth is a pure function of `(seed, establishment cell, age, species curve)` — no mutable RNG stream (AP-20).
3. **Selection determinism invariant:** establishment, survival and death decisions are pure functions of world state + traits; run-twice identical (extends 0006 invariant 4).
4. **Band invariant (extended 0006 invariant 2):** every emitted instance satisfies `biome ∈ allowed(species) ∧ height ≥ SEA_LEVEL + ε ∧ slope ≤ slope_cap ∧ suitability ≥ threshold`; violations are test failures.
5. **Cap invariant (extends 0006 invariant 3):** `flora_count ≤ FLORA_N_MAX` every tick; dead plants are removed in the tick they die (AP-22).
6. **Emission invariant (replaces 0006 invariant 5):** FLORA present ⇔ first-after-init, or count/species/ε-quantized scale change since last emission; absence ⇒ adapter retains cached instances; fixture and adapter gates assert both directions.
7. **Projection purity invariant (extends 0002 §6.3):** aging, establishment, selection and death mutate `World` **in the tick phase only**; projecting FLORA never mutates `World` (extended fingerprint in `test_projection_purity`).
8. **Layout neutrality invariant:** `SCR_SIM_SCHEMA_VER == 6`, `SCR_SIM_ABI_VERSION == 2`, FLORA record = 24 B, all other sections byte-identical semantics; fixture regen is content-only; adapter version gate untouched (0008 discipline).
9. **Regrowth invariant:** after any edit, flora reflects post-edit terrain: no instance on an invalid anchor, freed valid cells re-evaluated by the same pure functions — closing the 0006 §9 gap.
10. **Display separation invariant (extends 0006 invariant 7):** growth/selection state reaches the screen only via snapshot bytes; shader `TIME` sway stays display-only (AP-19).
11. **Scope invariant:** no reproduction/generational inheritance, no voxel flora, no wind-coupled sway-as-semantics, no fauna changes — successors (§9).

---

## 7. Exit Criteria

All commands run from repo root; `M=.venv/bin/mojo`.

- [x] **Definition gate (Sprint 00 — blocking):** `scr-domain-validator` findings = 0 for `lib/705_Ecology` (incl. new `Flora`), `lib/704_Evolution`; required sections present; all `103` edges from controlled vocabulary; Sprint 00 commit contains zero `src/mojo` changes.
- [x] **Growth test (automated):** `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_flora_growth.mojo` — monotonic bounded scale, run-twice identity, regrowth/death after dig, `0 < count ≤ 4096`, ε-emission triggers.
- [x] **Evolution test (automated):** `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_flora_evolution.mojo` — trait sanity, low establishment in high-stress band, deterministic death on stress, run-twice identity, cap held.
- [x] **Placement/field oracle (automated):** extended `test_flora_placement.mojo` — establishment implies band + suitability threshold; species → catalog resolution retained.
- [x] **Determinism (automated):** `test_determinism.mojo` — growth + selection in the byte-identical snapshot sequence across two runs.
- [x] **Projection purity (automated):** `test_projection_purity.mojo` — extended fingerprint (growth state never mutated by projection).
- [x] **Contract framing + fixture (automated):** `test_envelope.mojo` round-trips change-driven FLORA; `gen_golden_fixture.mojo` re-run; `test_golden_fixture.mojo` passes (content-only regen).
- [x] **Version gates (automated):** `python3 applications/godot/tests/abi_smoke.py` (schema 6 asserts intact) + `bash applications/godot/tests/test_schema_mismatch.sh` (6 accepted; 5 and 7 refused).
- [x] **Build + layout (automated):** `bash applications/godot/scripts/build_godot_provider.sh` + `bash applications/godot/scripts/check_layout.sh`.
- [x] **Scene gates (automated):** `godot_load_test.sh` (0 `ERROR:` lines) + `godot_playability_test.sh` PASS (player unaffected).
- [x] **Rendered growth evidence (automated screenshot w/ documented manual fallback):** `godot_screenshot.sh` with flora assertions extended: instance count > 0 **and** scale distribution at capture differs from init distribution (growth observable); PNG + numbers recorded in `docs/04` evidence table.
- [x] **0008 transport gates re-run:** in-process smoke + `SCR_SIM_TRANSPORT=socket SCR_SIM_IPC_PACE=manual` `godot_ipc_smoke.sh` + `test_ipc_determinism.sh` (growth bytes travel both transports byte-identically).
- [x] **Full lineage gate set (automated):** all milestone 0002 §8 procedures of `docs/04_simulation_engine.md` re-run PASS after the emission-rule change.
- [x] **Review pass:** AP-1..22 checked item-by-item; Sprint 00 checklist + honest limitations (no reproduction, stress-model choice) recorded in `docs/04`.

---

## 8. Dependencies

- **Predecessor:** [milestone 0008](../../v0.0.1/milestone_0008_ipc-transport/spec.md) (Complete) — stabilized contract + dual transport.
- **Semantic contracts:** `lib/705_Ecology/Flora` (new), `lib/705_Ecology`, `lib/704_Evolution`, `lib/401_Morphology/Growth`, `lib/301_Field`, `lib/801_Spatial/Voxel/Synthesis`, `lib/A01_Render/Material`.
- **Contract surface:** [`104_contract.md`](../../../providers/render/graphics/godot/104_contract.md) (§10 emission rule), [`docs/04_simulation_engine.md`](../../../docs/04_simulation_engine.md), [`docs/06_roadmap.md`](../../../docs/06_roadmap.md).
- **Toolchain:** unchanged (Mojo 1.0.0, Godot 4.7.2, godot-cpp — `docs/02_development_environment.md`).

---

## 9. Out of Scope

- **Reproduction / seed dispersal / cross-generational inheritance** — `503_Simulation/Reproduction` stub stays untouched; `704_Evolution INV-006/007` satisfied trivially per instance only; full generational evolution = successor (`704` + Ecology populations).
- **Voxel/lattice flora** (Synthesis §3 voxel objects) — recorded 0006 deviation stays open; successor.
- **Wind-driven sway as sim semantics**, weather coupling beyond wetness as a field input — successors (`705_Ecology` environment deepening).
- Fauna changes, physics props, transport changes, second scene — untouched.
- MLIR dialect/lowering work, performance optimization beyond the ε-emission budget (Rule 15).

---

## 10. Successor Milestones

| Intent | Triggering contracts |
|---|---|
| Generational evolution (reproduction + inheritance + lineage) | `704_Evolution INV-006/007`, `503_Simulation/Reproduction`, `601_Agent/Population` |
| Lattice vegetation (Synthesis §3 voxel objects) | `801_Spatial/Voxel/Synthesis` §3 realization |
| Wind/weather-driven flora semantics (sway, moisture transport as meaning) | `705_Ecology` §17 ecological fields, `501_Physics/Field` |
| Hardened remote transport / multi-client / second scene | successors per 0008 §10 |

Exact sequencing and exit criteria of successors: `TBD — future milestone` (Rule 10).
