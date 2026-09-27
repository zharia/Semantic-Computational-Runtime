# Milestone 0006: Ecology — Flora + Fauna

**Program Increment:** v0.0.1
**Milestone:** 0006 — Ecology (Flora + Fauna)
**Project:** Godot Simulation (applications/godot)
**Parent System:** Semantic Computational Runtime (SCR)
**Status:** Planned
**Primary Language:** Mojo
**Initial Engine Provider:** Godot 4.7.2
**Binding Architecture:** RenderSnapshot contract (schema bump + new FLORA/FAUNA sections) + in-process GDExtension adapter (transport untouched)
**Scene Scope:** Core slice — deterministic flora scatter + bounded seabird flock
**Predecessor:** [milestone 0002](../milestone_0002_scene-initiation/spec.md) (sibling — execute **after 0005** recommended, so biome/material state is mature; independent of 0007/0008)

---

## 1. Scope & Objective

Add **ecology** to the playable volcanic island: flora scattered deterministically over valid terrain bands, and a bounded flock of seabirds driven by sim-owned boids. This fulfils the "Ecology: flora + fauna" row of [milestone 0002 spec §10](../milestone_0002_scene-initiation/spec.md).

- **Mojo simulation core** owns all ecology semantics: where flora may stand (elevation/slope/biome bands), how many instances exist, boid integration, spawn/despawn — consuming `lib/705_Ecology` and `lib/601_Agent` definitions.
- **Godot** remains strictly presentation: it materializes two new snapshot sections into `MultiMeshInstance3D` (flora) and lightweight per-node meshes (birds). Wing flap is **display-only** (shader/`TIME`) — never sim state.
- **Contract** gains sections **FLORA** (instance transforms + species id, emission-gated like TERRAIN) and **FAUNA** (per-tick boid transforms, hard-capped). Additive ⇒ `SCR_SIM_SCHEMA_VER` bump + fixture regen + adapter version gate.

### 1.1 Decisions Locked (architectural, confirmed before drafting)

| Decision | Choice | Rationale / recommended default |
|---|---|---|
| Flora placement locus | **`FloraSubject` in sim** (instance list emitted as FLORA section); lattice columns keep `FEATURE_NONE` | Instance transforms are exactly what a FLORA section + `MultiMeshInstance3D` render; voxel-column vegetation would force TERRAIN rebuild coupling and was explicitly rejected out of scope in `src/mojo/synthesis/voxel.mojo` header. Recorded deviation from Synthesis §3 "Voxel Objects Placed" (see §4) — never silent |
| Feature vocabulary | Reuse `lib/801_Spatial/Voxel/Synthesis` §3 FeatureTile → flora-object table as the **species vocabulary** (PALM/CANOPY/SHRUB/FERN/BAMBOO …) | Contract already defines the flora species set normatively; no invented species list |
| Feature assignment | Pure deterministic function `feature_for_column(x, z, biome, slope, height, seed)` — integer hash over `(seed, x, z)` gated by band rules | Seeded, order-independent, testable; no RNG stream state (determinism invariant) |
| Species identity | `species_id` = sim species enum; species → catalog material table (e.g. crowns → `botanical.foliage`, trunks → `wood.hardwood`, bamboo → `botanical.bamboo`, ground cover → `botanical.moss`); **test asserts every species resolves from `materials_catalog.json`** | Catalog has real foliage/wood/botanical entries (verified); AP-3 discipline: display color derives from catalog, no parallel vocabulary |
| Flora bands (defaults) | Only `classify_biome` bands: `BEACH` (palm), `VOLCANIC_SLOPE` (canopy/shrub/fern) above sea level + slope cap; `CALDERA_RIM`/`CALDERA_LAKE`/`SHALLOW_WATER`/`DEEP_OCEAN` → **no flora**; params in `parameters.mojo` | Volcanic profile has only these six biome codes today (`sim/island.mojo`); band table = test oracle |
| Flora cap | `FLORA_N_MAX = 4096` instances (count asserted in tests) | MultiMesh-cheap; bounded section size |
| Fauna model | `FlockSubject`: boids (seek waypoint + alignment + cohesion + separation + terrain/ocean avoidance), fixed-order integration over slot-indexed birds | Classic deterministic boids; slot order removes iteration-order nondeterminism |
| Fauna cap & spawn/despawn | `FLOCK_N_MAX = 64`, initial `FLOCK_N_INIT = 32`; a bird leaving the ocean/beach bound is despawned and its slot respawned at a waypoint derived from `(seed, slot, respawn_count)`; count never exceeds cap | Prompt requirement: bounded, capped, with explicit spawn/despawn rules |
| FAUNA emission | FAUNA section **every snapshot** (state changes per tick); FLORA **first snapshot after init + whenever `world_version` increments** (same tracker as TERRAIN) | Flora is generation-bound; flock is tick-bound |
| Rendering | Flora = `MultiMeshInstance3D` per species (group `scr_flora`); birds = per-node `MeshInstance3D` (≤64 nodes, easy orientation), group `scr_fauna` | Simple, debuggable; wing flap via shader on `TIME` (display-only) |
| Schema | Additive sections ⇒ `SCR_SIM_SCHEMA_VER` **bump by exactly 1 from then-current value**, golden fixture regenerated, adapter version gate unchanged in behavior (refuse mismatch) | `104_contract.md` §7: additive changes require a bump; adapters must not guess layouts |
| Sibling rebasing (stated once) | Siblings 0003–0005 (atmosphere/volcano/scene) and 0007/0008 may also bump schema if executed; a later-executed sibling **rebases on then-current schema**, takes the **next free section ids**, and regenerates the fixture | Prevents parallel-milestone version collisions; section ids 7/8 below are **provisional** pending execution order |

### 1.2 Open decision — confirm before drafting final

- **Execution order:** recommended *after 0005* and *independent of 0007/0008*. If 0006 executes after a sibling that already bumped schema/took section ids, the rebase rule in §1.1 applies automatically. Confirm ordering before finalizing (Rule 19).

### 1.3 Governing Principle

> Never allow implementation convenience to silently redefine computational semantics.

```text
Semantic Meaning → Contract → Representation → Transformation → Lowering → Provider → Runtime → Execution Substrate
```

Ecology meaning lives in `lib/705_Ecology` + `lib/601_Agent` (definitions) and is consumed by the Mojo core. The FLORA/FAUNA sections are contract, not meaning. Godot nodes render instances; they never decide placement, count, or motion.

---

## 2. Lessons & Anti-pattern Constraints (Normative)

### 2.1 Continuing normative constraints — milestone 0002 §2

[Milestone 0002 §2.1 AP-1 … AP-10](../milestone_0002_scene-initiation/spec.md) remain fully normative for this milestone — engine isolation (AP-1), executable conformance (AP-2), single material vocabulary (AP-3), no absolute paths (AP-4), no monolith dispatch (AP-5), typed contracts (AP-6), tunables in the parameter table (AP-7), one-way state channel (AP-8), no render-thread stalls (AP-9), provider control docs (AP-10). **Linked, not re-tabled.** Their §7 gate commands are re-run as this milestone's final gate set (§7).

### 2.2 New milestone-specific anti-patterns (this milestone only)

| # | Anti-pattern | Required correction |
|---|---|---|
| AP-11 | **Presentation-owned ecology** — Godot scatters meshes or flocks birds in GDScript/particles | Placement, counts, spawn/despawn and boid integration are sim-owned, deterministic, and test-asserted; adapter only applies FLORA/FAUNA to nodes (AP-8 sibling) |
| AP-12 | **Display animation leaks into semantics** — wing-flap phase written back into snapshot/sim | Flora/birds carry pose only (position + yaw [+ scale]); flap runs on shader `TIME`, display-only (§3.4) |
| AP-13 | **Unbounded instance growth** — scatter/flock counts grow ad hoc with world size or frame rate | Hard caps `FLORA_N_MAX`/`FLOCK_N_MAX` in `parameters.mojo`; tests assert `count ≤ cap` every tick and `flora_count > 0` for seed 1 |
| AP-14 | **Parallel species vocabulary** — hand-picked colors/meshes for "trees" diverging from the material catalog | Species → catalog material table is sim-side, single-sourced, and conformance-tested against `materials_catalog.json` (AP-3 extension) |

---

## 3. Architecture & Binding Contract

### 3.1 Layer diagram (delta over milestone 0002 §3.1)

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ SCR semantic library (lib/) — meaning, authoritative                    │
│   705_Ecology (population/environment/state/determinism, definition)     │
│   601_Agent (action/interaction/multi-agent/population/lifecycle)        │
│   801_Spatial/Voxel/Synthesis §3 (FeatureTile → flora species vocab.)   │
│   A01_Render/Material (catalog: botanical.*/wood.* species colors)      │
│   801_Spatial frames (instance transforms are world-frame values)       │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Mojo simulation core — src/mojo/ (semantic consumer)                    │
│   + sim/flora.mojo  : FloraSubject — feature_for_column + band rules    │
│   + sim/flock.mojo  : FlockSubject — boids, slots, spawn/despawn        │
│   owns: all placement/counts/motion; deterministic w.r.t. seed+inputs   │
│   output: RenderSnapshot (+ FLORA, FAUNA) — projection stays pure       │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │ C ABI (.so) — unchanged symbols; schema N→N+1
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Provider adapter — providers/render/graphics/godot/adapter/             │
│   decode FLORA → MultiMeshInstance3D per species (group scr_flora)      │
│   decode FAUNA → per-node transforms (group scr_fauna)                  │
│   NO placement/motion decisions; representation conversion only         │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Godot scene — godot/scenes/island.tscn                                  │
│   + scr_flora host Node3D, + scr_fauna host Node3D, bird/flora meshes   │
│   + shaders/flora_wing.gdshader (display-only flap on TIME)             │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Snapshot contract additions (normative draft for `104_contract.md`)

All fields little-endian; section framing per `104_contract.md` §4.2 (u32 `section_id`, u32 `section_bytes`, payload). **Schema version bumps by exactly 1** from the then-current `SCR_SIM_SCHEMA_VER` (currently `1`); envelope layout, section ids 1–6, and input uplink §5 are unchanged.

**7 — FLORA** (emission-gated: first snapshot after init + whenever `world_version` increments — identical presence rule to TERRAIN, §4.3 of the contract; adapter keeps existing instances when absent; `FLORA`-related counts are *not* carried in `TERRAIN_META`)

| Off | Type | Field |
|---|---|---|
| 0 | u32 | `count` (≤ `FLORA_N_MAX = 4096`) |
| then `count` records, each **24 bytes**: | | |
| 0 | f32×3 | `position` (world; y = surface height at anchor cell) |
| 12 | f32 | `yaw` (rad) |
| 16 | f32 | `scale` (uniform, > 0) |
| 20 | u32 | `species_id` (sim species enum; species → catalog material table in `docs/04_simulation_engine.md`) |

Section bytes = `4 + 24·count` (max 98,308 B ≈ 96 KiB, emitted only on generation change).

**8 — FAUNA** (emitted **every** snapshot)

| Off | Type | Field |
|---|---|---|
| 0 | u32 | `count` (≤ `FLOCK_N_MAX = 64`) |
| then `count` records, each **20 bytes**: | | |
| 0 | f32×3 | `position` (world) |
| 12 | f32 | `yaw` (heading, rad) |
| 16 | u8 | `species_id` (0 = seabird; reserved for future fauna) |
| 17 | u8×3 | `pad` = 0 |

Section bytes = `4 + 20·count` (max 1,284 B/tick ⇒ ≈ 77 KB/s added downlink at 60 Hz — **bandwidth budget noted; cap is the budget control**).

### 3.3 Data flow rules (inherited, unchanged)

Down: sim tick → project (pure) → encode → adapter decode → node update. Up: input batch only — **no new uplink** this milestone (flora/fauna are sim-owned; no player op needed). One channel: snapshot is the only state channel. Transport stays in-process.

### 3.4 Timestep & display animation

60 Hz fixed timestep unchanged (`docs/04_simulation_engine.md` §4.2). Boids integrate once per fixed tick. **Wing flap / frond sway are display-only**: bird/flora materials animate in the shader from `TIME` (same pattern as the ocean shader's display-only terms, `docs/04` §7) — no flap phase in FAUNA, no sway in FLORA (AP-12).

---

## 4. Semantic Library Consumption

Consumption **by semantic ID**, consistent with `lib/README.md` conventions and milestone 0002 §4.

| Domain / ID | Concept consumed (verified on disk) | Consumption mode |
|---|---|---|
| `SCR-LIB-ECOLOGY` (`lib/705_Ecology/101_definition.md` — **definition only; the domain has no child subdirectories**) | §1 Population (membership MUST be semantically defined), §3 Environment, §9 Ecological State (population composition, abundance, distribution), §14 Spatial Ecology (distance/gradient effects), §43 Determinism and Stochasticity (declared deterministic ⇒ must actually be deterministic); invariants `ECOLOGY-INV-003` (population explicitness), `ECOLOGY-INV-004` (environment explicitness) | **Spec-only contract — implement in Mojo per definition**: flora population + flock are explicit populations with defined membership; band conditions (elevation/slope/biome) are explicit environment; the model is declared deterministic and test-verified. Expected subdomains (population, species, …) are listed in the definition but not yet materialized as directories — no invented child paths |
| `SCR-LIB-AGENTS` (`lib/601_Agent/101_definition.md`) | Action / Action Space, Decision, Interaction, Multi-Agent Systems (collective behaviour emerges from local interactions; must not be attributed to an individual), Population (membership criterion), Spatial Agency (position/orientation/movement), Lifecycle (creation → active → termination; spawn/despawn) | **Spec-only — implement in Mojo per definition**: boid = agent with spatial state + local interaction rules; flock population membership = slot table; spawn/despawn follows lifecycle intent. **Honest note:** milestone 0002 §10 names `601_Agent/Flocking` — **no such directory exists on disk**; children `Behaviour/`, `Population/`, `MultiAgent/` are structural stubs ("No substantive semantic contract is inferred from the directory's existence alone"), so the **parent definition is authoritative** and no `Flocking` path is cited |
| `SCR-LIB-SPATIAL-VOXEL-SYNTHESIS` (`lib/801_Spatial/Voxel/Synthesis`) | §3 **Feature → Flora Object Mapping (normative)** — PALM_CLUSTER/PALM_SOLO/BAMBOO_GROVE/CANOPY_TREE/CANOPY_CLUSTER/SHRUB/FERN_CARPET species vocabulary + associated materials; §4 invariants (pure function, features above surface, bedrock, water fill, write-once); pipeline `feature` input already implemented (`src/mojo/synthesis/voxel.mojo` FEATURE_* codes) | Species vocabulary + band gating re-used verbatim; `feature_for_column` produces the same FeatureTile codes. **Recorded deviation:** §3's *voxel-object* realization stays disabled for flora this milestone (lattice columns keep `FEATURE_NONE`) — flora is realized as FLORA-section instances (decision §1.1); boulders/vents/ash features remain available unchanged. Deviation recorded here and in `docs/04_simulation_engine.md`, never silent |
| `SCR-LIB-RENDER-MATERIAL` (`lib/A01_Render/Material`) | `materials_catalog.json` (96 materials) incl. `botanical.foliage`, `botanical.bamboo`, `botanical.moss`, `wood.hardwood`, `wood.softwood`, `wood.birch` (verified present); `101_definition.md` (material semantics authoritative) | Species display colors/materials derive from catalog ids only; `test_catalog` extended to species table (AP-3/AP-14) |
| `SCR-LIB-SPATIAL` frames (`lib/801_Spatial`) | Position = value + explicit reference frame; world frame explicit (0002 §4) | FLORA/FAUNA positions are world-frame values; Godot node transforms = representation |

**Not consumed this milestone:** `lib/501_Physics` (fauna has no rigid-body dynamics here — boids are kinematic), `lib/A01_Render/HUD`, `lib/804_Application` (unchanged layering), `lib/503_Simulation/*` (children are structural stubs; nothing needed).

---

## 5. Deliverables & Sprint Breakdown

```text
applications/godot/
├── src/mojo/
│   ├── sim/
│   │   ├── flora.mojo                    # NEW: FloraSubject, feature_for_column, band rules
│   │   ├── flock.mojo                    # NEW: FlockSubject — boids, slots, spawn/despawn
│   │   ├── parameters.mojo               # + FLORA_*/FLOCK_* tunables, band table, species table
│   │   ├── world.mojo                    # + flora/flock subjects owned by World
│   │   └── runtime.mojo                  # + FLORA emission tracking (shares world_version tracker)
│   ├── materials/catalog.mojo            # + species material codes (botanical/wood ids)
│   └── snapshot/
│       ├── types.mojo                    # + FloraInstance, FlockBird
│       ├── encode.mojo                   # + _encode_flora / _encode_fauna (schema N+1)
│       └── decode.mojo                   # + section 7/8 decode (tests/round-trip)
├── godot/
│   ├── scenes/island.tscn                # + scr_flora / scr_fauna host nodes, display meshes
│   ├── scripts/flora_view.gd             # NEW: FLORA → MultiMeshInstance3D (presentation only)
│   ├── scripts/fauna_view.gd             # NEW: FAUNA → node transforms (presentation only)
│   └── shaders/flora_wing.gdshader       # NEW: display-only flap/sway on TIME
├── tests/mojo/
│   ├── test_flora_placement.mojo         # NEW: determinism + band invariants + cap
│   ├── test_flock.mojo                   # NEW: bounded, deterministic, spawn/despawn rules
│   ├── test_determinism.mojo             # EXT: 2 species present ⇒ byte-identical sequence
│   ├── test_catalog.mojo                 # EXT: species → catalog resolution
│   ├── test_envelope.mojo                # EXT: FLORA/FAUNA framing round-trip
│   └── gen_golden_fixture.mojo           # RUN: fixture regen (schema bump)
├── tests/godot/
│   ├── godot_screenshot.gd / .sh         # EXT: flora/birds content assertions + documented capture
│   └── godot_load_test.sh                # re-run gate (no errors with new groups)
├── tests/fixtures/snapshot_seed1_tick1.bin  # REGENERATED (schema N+1)
├── docs/04_simulation_engine.md          # + flora/flock model, species table, band params, new §parameters
├── docs/06_roadmap.md                    # + 0006 status row
└── program_increments/v0.0.1/milestone_0006_ecology/spec.md   # this file

providers/render/graphics/godot/
├── 104_contract.md                       # + §4.3 sections 7 FLORA / 8 FAUNA; schema version bump
├── 102_status.yaml                       # + capability/status update
└── adapter/scr_godot_adapter.cpp         # + apply_flora / apply_fauna (groups scr_flora/scr_fauna)
```

### Sprint 01 — Flora placement (Mojo)

- `FloraSubject`: `feature_for_column` (seeded integer hash + band gates) → instances (position, yaw, scale, species) derived from the existing heightfield/biome grids — **no world mutation beyond subject state**.
- Band defaults in `parameters.mojo` (AP-7): allowed biomes per species, slope cap, elevation window, densities, `FLORA_N_MAX`, species → catalog material table.
- Tests: `test_flora_placement.mojo` — (a) deterministic (same seed ⇒ identical instance list; different seed ⇒ different), (b) band invariants (every instance: biome allowed, `height ≥ SEA_LEVEL + ε`, `slope ≤ cap`, count ≤ cap, count > 0 for seed 1), (c) species table resolves to catalog.

### Sprint 02 — Boids (Mojo)

- `FlockSubject`: per-slot birds (position, velocity, yaw, respawn_count); integration order = slot index (deterministic); rules: waypoint seek (orbit target over ocean ring), alignment, cohesion, separation, terrain/ocean avoidance from heightfield, speed clamp.
- Spawn/despawn: init `FLOCK_N_INIT = 32`; bound violation ⇒ despawn + deterministic respawn from `(seed, slot, respawn_count)`; `count ≤ FLOCK_N_MAX` always.
- Tests: `test_flock.mojo` — (a) bounded (every tick: count ≤ cap, all positions inside ocean/beach bound, separation ≥ min distance), (b) deterministic (identical bird state sequence for same seed across two runs), (c) respawn rule fires without exceeding cap.

### Sprint 03 — Contract + fixture + adapter + scene

- `104_contract.md`: sections FLORA/FAUNA (§3.2 above), schema bump, emission rules; adapter constants + decode validation (`section_bytes == 4 + 24·count` / `4 + 20·count`, loud reject on violation).
- Encode/decode/round-trip tests; **fixture regeneration** (`gen_golden_fixture.mojo`) + `test_golden_fixture` + `abi_smoke.py` + `test_schema_mismatch.sh` re-run (schema N+1 now accepted, N refused).
- Adapter: `apply_flora` (build/refresh one `MultiMeshInstance3D` per species under `scr_flora`), `apply_fauna` (≤64 child nodes); scene hosts + meshes + display-only wing shader.
- AP-1 gate (`check_layout.sh`) re-run: zero engine types in `src/mojo/`.

### Sprint 04 — Docs + verification

- `docs/04_simulation_engine.md`: flora/flock domain model, species/band tables, parameter table additions, screenshot evidence; `docs/06_roadmap.md`: 0006 row + successors.
- Full §7 gate run (all milestone 0002 gates + new ecology gates); anti-pattern review item-by-item (§2.1 + §2.2).

---

## 6. Formal Invariants

1. **Ecology authority invariant:** population membership, placement bands and flock behaviour are defined by `lib/705_Ecology` / `lib/601_Agent` semantics consumed by the sim; Godot never places, counts, or moves ecology (AP-11).
2. **Band invariant:** every emitted flora instance satisfies `biome ∈ allowed(species) ∧ height ≥ SEA_LEVEL + ε ∧ slope ≤ slope_cap`; violations are test failures, not warnings.
3. **Cap invariant:** `flora_count ≤ FLORA_N_MAX` and `fauna_count ≤ FLOCK_N_MAX` in every snapshot (AP-13).
4. **Determinism invariant (ecology):** same seed + same inputs ⇒ identical FLORA (per generation) and FAUNA (per tick) bytes; placement uses no mutable RNG stream; boids integrate in fixed slot order.
5. **Emission invariant:** FLORA presence ⇔ first-after-init or `world_version` change (shared tracker semantics with TERRAIN); FAUNA present every snapshot; adapter retains cached instances when FLORA absent.
6. **Catalog invariant (species):** every species resolves to exactly one `materials_catalog.json` id; rendering derives from the MATERIALS/species table only (AP-3/AP-14).
7. **Display separation invariant:** animation (flap/sway) never appears in snapshot bytes; FLORA/FAUNA carry pose only (AP-12).
8. **Projection purity invariant:** projecting FLORA/FAUNA does not mutate `World` (extends 0002 §6.3; `test_projection_purity` covers the extended fingerprint).
9. **Contract version invariant:** schema bump by exactly +1 from then-current value, fixture regenerated, adapter refuses mismatch (negative test re-run).
10. **Honesty invariant:** the Synthesis §3 voxel-flora deviation (§4) and any gap (e.g. no flora regrowth after 0007 edits until recompute) recorded as `TBD — future milestone` in `docs/04`, never silent.
11. **Scope invariant (0006 §9):** no editing, no physics props, no transport swap, no weather — successors.

---

## 7. Exit Criteria

All commands run from repo root; `M=.venv/bin/mojo`.

- [ ] **Flora band test (automated):** `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_flora_placement.mojo` — asserts every instance on a valid band (count/band oracle), `0 < count ≤ 4096`, seeded determinism, species→catalog resolution.
- [ ] **Flock coherence + bound test (automated):** `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_flock.mojo` — over ≥ 600 ticks: `count ≤ 64`, all birds within the ocean/beach bound, separation floor holds, respawn rule respects cap, run-twice determinism.
- [ ] **Determinism with 2 species (automated):** `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_determinism.mojo` — seed 1 produces ≥ 2 distinct flora species and byte-identical snapshot sequence across two runs (FLORA+FAUNA included).
- [ ] **Projection purity (automated):** `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_projection_purity.mojo`.
- [ ] **Contract framing (automated):** `test_envelope.mojo` round-trips FLORA/FAUNA (incl. malformed `section_bytes` rejection); `gen_golden_fixture.mojo` re-run; `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_golden_fixture.mojo` passes against the regenerated fixture.
- [ ] **Schema gate (automated):** `bash applications/godot/tests/test_schema_mismatch.sh` — loader accepts new schema, refuses old/newer mismatch; `python3 applications/godot/tests/abi_smoke.py` PASS.
- [ ] **Build + layout gates (automated):** `bash applications/godot/scripts/build_godot_provider.sh`, `bash applications/godot/scripts/check_layout.sh` (AP-1/AP-4 clean).
- [ ] **Scene gates (automated):** `bash applications/godot/tests/godot/godot_load_test.sh` (0 `ERROR:` lines with new groups); `bash applications/godot/tests/godot/godot_playability_test.sh` PASS (player unaffected).
- [ ] **Flora + birds visibly render (automated screenshot w/ documented manual fallback):** `bash applications/godot/tests/godot/godot_screenshot.sh` with content assertions extended to `scr_flora` (≥1 MultiMesh with instance count > 0) and `scr_fauna` (node count > 0); PNG + luminance result recorded in `docs/04` §8-style evidence table. Manual fallback procedure = same script's documented display-probe path.
- [ ] **All milestone 0002 gates green (automated):** the seven §8 procedures of `docs/04_simulation_engine.md` re-run PASS after the schema bump.
- [ ] **Review pass:** §2.1 (AP-1..10) and §2.2 (AP-11..14) checked item-by-item; results table appended to `docs/04`.

---

## 8. Dependencies

- **Predecessor:** [milestone 0002](../milestone_0002_scene-initiation/spec.md) (Complete) — sim core, snapshot schema v1, adapter, `island.tscn`.
- **Recommended predecessor:** milestone 0005 (biome/material state mature) — see §1.1 ordering row; §1.2 open decision.
- **Semantic contracts:** `lib/705_Ecology`, `lib/601_Agent`, `lib/801_Spatial/Voxel/Synthesis`, `lib/A01_Render/Material`, `lib/801_Spatial`.
- **Contract surface:** [`providers/render/graphics/godot/104_contract.md`](../../../providers/render/graphics/godot/104_contract.md) (§4.3 + schema §7), [`docs/04_simulation_engine.md`](../../../docs/04_simulation_engine.md), [`docs/06_roadmap.md`](../../../docs/06_roadmap.md).
- **Toolchain:** unchanged from milestone 0002 (Mojo 1.0.0, Godot 4.7.2, godot-cpp — pinned in `docs/02_development_environment.md`).

---

## 9. Out of Scope

- Voxel-column (lattice) vegetation realization per Synthesis §3 — recorded deviation §4; successor may enable it.
- Fauna beyond one capped boid flock (predation, reproduction, migration, population dynamics beyond spawn/despawn) — successors (`705_Ecology` §§10–13).
- Rigid-body physics, editing/hotbar, raycast — milestone 0007.
- Out-of-process IPC transport — milestone 0008.
- Weather/atmosphere coupling to flora (wind sway driven by sim wind), lava/ash effects on flora, flora regrowth after edits — `TBD — future milestone`.
- MLIR dialect/lowering work, performance optimization beyond the stated bandwidth budget note (Rule 15).

---

## 10. Successor Milestones

| Intent | Triggering contracts |
|---|---|
| Editing, hotbar, physics | [milestone 0007](../milestone_0007_editing-physics/spec.md), `501_Physics` bodies, material hotbar |
| IPC transport swap | [milestone 0008](../milestone_0008_ipc-transport/spec.md), stabilized `104_contract.md` §2 |
| Richer ecology (population dynamics, more species, wind-coupled animation as semantics) | `705_Ecology` §§10–13, `601_Agent` children when substantive definitions land |
| Lattice vegetation (Synthesis §3 voxel objects) | `801_Spatial/Voxel/Synthesis` §3 realization |

Exact sequencing and exit criteria of successors beyond 0007/0008: `TBD — future milestone` (Rule 10).
