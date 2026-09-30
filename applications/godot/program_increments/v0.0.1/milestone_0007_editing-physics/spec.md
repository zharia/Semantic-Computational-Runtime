# Milestone 0007: Editing, Hotbar & Physics

**Program Increment:** v0.0.1
**Milestone:** 0007 — Editing, Hotbar & Physics
**Project:** Godot Simulation (applications/godot)
**Parent System:** Semantic Computational Runtime (SCR)
**Status:** Complete
**Primary Language:** Mojo
**Initial Engine Provider:** Godot 4.7.2
**Binding Architecture:** RenderSnapshot contract (schema bump + HOTBAR/TARGET/RIGID_BODIES sections) + new `scr_edit_batch` uplink (ABI bump) + in-process GDExtension adapter
**Scene Scope:** Core slice — dig/place voxel edits, catalog hotbar, sim raycast, minimal rigid props
**Predecessor:** [milestone 0002](../milestone_0002_scene-initiation/spec.md) (sibling — terrain-regen path already supported: `world_version` → TERRAIN resend; independent of 0006/0008)

---

## 1. Scope & Objective

Make the island **editable and physically inhabited**:

- **Mojo core** owns: voxel edit operations (dig/place), column re-synthesis, heightfield/chunk recompute, world_version bumps, ray/hit-test results, hotbar selection state, and a minimal rigid-prop subject — consuming `lib/501_Physics`, `lib/A01_Render/{Material,HUD}`, `lib/801_Spatial/Voxel/Synthesis`.
- **Godot** captures input (mouse click while captured, keys 1–9 / scroll), forwards **intent only**, and renders: terrain mesh updates (existing TERRAIN path), hotbar HUD (catalog names/ids), prop meshes.
- **Contract** adds downlink sections **HOTBAR** (selected slot + catalog ids), **TARGET** (sim-owned ray hit), **RIGID_BODIES** (≤16 props) and a new **uplink struct `scr_edit_batch`** with its own ABI function (input batch unchanged).

This fulfils the "Editing, hotbar, physics" row of [milestone 0002 spec §10](../milestone_0002_scene-initiation/spec.md).

### 1.1 Decisions Locked (architectural, confirmed before drafting)

| Decision | Choice | Rationale / recommended default |
|---|---|---|
| Edit granularity | One **column** per op: footprint `CELL_SIZE = 4 u × 4 u`, vertical step **1 u** (lattice cell = 1 world u; `LATTICE_Y_OFFSET = 24`) | Matches heightfield/lattice construction (`sim/island.mojo`, `synthesis/voxel.mojo`); smallest honest unit of the synthesis pipeline |
| Edit → recompute path | dig/place updates column height ⇒ re-run `classify_biome` + `voxel_synthesis_pipeline` for the edited column(s) ⇒ update heightfield + surface materials ⇒ rebuild **only the containing chunk** mesh ⇒ `world_version` bump ⇒ adapter naturally receives **new TERRAIN exactly once** | Reuses the generation-change emission tracker already in `sim/runtime.mojo` (verified); never bypasses the pipeline (new AP-11); chunk-local rebuild is the perf rule (`TERRAIN_CHUNK_CELLS = 16`) |
| Raycast / hit-test | **Sim-owned** DDA/ray-march over the heightfield from eye position along camera forward (`SCR-LIB-FIELD` sampling), range `RAY_RANGE = 32 u` (param); result emitted **every tick** in TARGET section; client sends only op intent | Deterministic (edits depend only on sim state); AP-8 discipline; avoids input-op ack round-trip complexity — the "expose via snapshot" option of the two offered by scope |
| Edit uplink | **NEW 4-byte struct `scr_edit_batch`** + **new ABI function `scr_edit_submit(const scr_edit_batch*)`**; `scr_input_batch` (20 B) untouched | Prompt-recommended option. Alternative (cramming into the 20-byte input batch) rejected: input batch is packed-stable and consumed per tick as *locomotion intent*; edits are a different verb class with its own queue/rate limit. `SCR_SIM_ABI_VERSION` **bump 1 → 2** (symbol set changed); `SCR_SIM_SCHEMA_VER` bumps separately for the downlink sections (§1.1 rebasing row) |
| `scr_edit_batch` layout | `{ u8 op (0 none, 1 dig, 2 place), u8 select_slot (0 = no change, 1..9 = select hotbar slot), u16 reserved = 0 }` — **client never names materials or cells** | Slot→material and ray→cell resolution are sim semantics (AP-12/AP-13); struct stays ABI-side, no downlink coupling |
| Edit queue semantics | FIFO queue; **at most one edit op consumed per fixed tick**; `select_slot` applies immediately at consume time; ops queued from the render/physics frame thread via the C ABI | Bounded work per tick; deterministic ordering (queue order = submit order) |
| Hotbar | Sim owns the **9-slot catalog table** in `parameters.mojo` (default: `rock.basalt, soil.sand, rock.obsidian, mineral.sulfur, mineral.ash, fluid.lava, fluid.water, soil.dirt, rock.pumice` — all resolve from `materials_catalog.json`, all already in the slice's MAT vocabulary); selection = sim state; HUD **displays** slots/names/ids | Catalog-driven vocabulary, **no parallel list in GDScript** (AP-3/AP-13). Cave reference used foliage/bamboo slots — those need 0006's species vocabulary, hence the verified in-vocabulary default set |
| Ray/hit invariant rules | **No digging the bedrock cell**: reject dig when resulting `surface_y ≤ 1` (bedrock lattice y=0 untouchable, Synthesis §4 inv.3); **sea-level fill**: dig below sea level ⇒ pipeline refills water to `SEA_LEVEL` (inv.4) and biome reclassifies (`h < SEA_LEVEL` ⇒ SHALLOW/DEEP water row) | Invariants enforced by re-running the normative pipeline, asserted in tests |
| Physics (minimal) | **LOCK: rigid props ship in this slice** — `PhysicsSubject`, `N ≤ 16` simple boxes/spheres, gravity (`GRAVITY = −10` param), semi-implicit Euler at fixed tick, **ground collision only vs heightfield** (terrain = static body, non-penetration/zero restitution, tangential damping), **no inter-body collision, no stacking, no joints** | Prompt-recommended default; keeps scope a vertical slice (Rule 14). Advanced physics (bodies contact/collision graph, stacking, raycast-vs-props) = successor milestone |
| Prop spawn | `PROP_N_INIT = 4` boxes at deterministic beach anchors derived from `(seed, spawn_position)`; cap asserted | Deterministic, testable, bounded |
| Rendering | Props = one `MeshInstance3D` per body (group `scr_props`, box/sphere mesh from section fields); hotbar = HUD node (group `scr_hotbar`) fed from HOTBAR section | Presentation only (AP-8) |
| Schema / ABI bump | Downlink sections ⇒ `SCR_SIM_SCHEMA_VER` **+1 from then-current** (fixture regen + adapter gate); `SCR_SIM_ABI_VERSION` **1 → 2** (new symbol/struct). Section ids below are **provisional** (assume 0006 ran first ⇒ FLORA 7 / FAUNA 8 ⇒ HOTBAR 9, TARGET 10, RIGID_BODIES 11); a later-executed sibling **rebases on then-current schema/ABI and takes the next free section ids** | Stated once per spec (sibling rebasing rule) |

### 1.2 Open decision — confirm before drafting final

- **HUD depth:** ship **hotbar only** (slot index, catalog `name` + `id`, albedo swatch — all derivable from `materials_catalog.json` + MATERIALS section), and **defer the full Material Inspector field set** (density/tensile strength/Young's modulus … per `lib/A01_Render/HUD` §2.2) because the catalog exposes `physical.*` partially and not all §2.2 fields exist (verified: `botanical.foliage` has `density_kg_m3`, `youngs_modulus_gpa`, `thermal_conductivity_w_mk`, but **no tensile_strength**). Recommend deferring the full inspector as `TBD — future milestone`; confirm before finalizing (Rule 19).

### 1.3 Governing Principle

> Never allow implementation convenience to silently redefine computational semantics.

```text
Semantic Meaning → Contract → Representation → Transformation → Lowering → Provider → Runtime → Execution Substrate
```

Edits change world meaning **only** through the synthesis pipeline. The raycast result, hotbar selection and body states are semantic (sim-owned); HUD and meshes are projections. Godot never resolves which cell is hit, which material is selected, or where a prop rests.

---

## 2. Lessons & Anti-pattern Constraints (Normative)

### 2.1 Continuing normative constraints — milestone 0002 §2

[Milestone 0002 §2.1 AP-1 … AP-10](../milestone_0002_scene-initiation/spec.md) remain fully normative — linked, not re-tabled (engine isolation, executable conformance, single material vocabulary, no absolute paths, no monolith dispatch, typed contracts, parameter table, one-way state channel, no render-thread stalls, provider control docs). Their §7 gate commands are re-run as this milestone's final gate set (§7).

### 2.2 New milestone-specific anti-patterns (this milestone only)

| # | Anti-pattern | Required correction |
|---|---|---|
| AP-11 | **Raw terrain poke** — editing mutates the heightfield/material grid directly, bypassing synthesis invariants (bedrock exposed, sea not refilled) | Every edit re-runs `classify_biome` + `voxel_synthesis_pipeline` for touched columns; bedrock/sea-level rules are test-asserted (Synthesis §4 inv.3/inv.4) |
| AP-12 | **Client-side hit authority** — Godot decides the edited cell/material from its own ray/mesh | Sim owns the raycast; client submits `op` + `select_slot` only; identical scripted edits ⇒ identical world (determinism test) |
| AP-13 | **Parallel hotbar vocabulary** — slot list / material names hard-coded in GDScript or HUD | Slots are a sim parameter table of catalog ids; HUD renders names/ids received from HOTBAR section (AP-3 extension) |
| AP-14 | **Full-world rebuild per edit** — regenerating all 16 chunks (or the whole island) on a single cell change | Chunk-local rebuild only (chunk containing the edited cell), `world_version` bump once per op; perf note recorded in `docs/04` |

---

## 3. Architecture & Binding Contract

### 3.1 Layer diagram (delta over milestone 0002 §3.1)

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ SCR semantic library (lib/) — meaning, authoritative                    │
│   501_Physics (Body taxonomy, RigidBody, Contact, Collision, Sensors,    │
│                Quantity; PHYSICS-INV-001/002/003/018)                    │
│   801_Spatial/Voxel/Synthesis (pipeline + inv.3 bedrock / inv.4 water)   │
│   A01_Render/Material (catalog = hotbar vocabulary)                      │
│   A01_Render/HUD (read-only derived projection; RayHit semantics)        │
│   801_Spatial / 301_Field (ray-march height sampling, world frame)       │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Mojo simulation core — src/mojo/ (semantic consumer)                    │
│   + sim/edit.mojo   : edit queue, dig/place, column re-synthesis,       │
│                       chunk rebuild, world_version bump                 │
│   + sim/raycast.mojo: sim-owned ray-march → RayHit (hit, cell, material,│
│                       position) — TARGET section source                │
│   + sim/hotbar.mojo : 9-slot catalog table + selected slot (sim state)  │
│   + sim/props.mojo  : PhysicsSubject — N≤16 box/sphere, gravity,        │
│                       ground contact vs heightfield (semi-implicit Euler)│
│   owns: world meaning changes ONLY via voxel synthesis pipeline         │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │ C ABI: existing 7 symbols + scr_edit_submit
                                │ (ABI 1→2); downlink schema +1
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Provider adapter — providers/render/graphics/godot/adapter/             │
│   mouse click (captured) → scr_edit_batch{op} ; keys 1-9 / wheel →      │
│   scr_edit_batch{select_slot} ; apply HOTBAR/TARGET/RIGID_BODIES        │
│   terrain chunk update rides existing TERRAIN path (no adapter change   │
│   beyond node refresh already present)                                 │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Godot scene — godot/scenes/island.tscn                                  │
│   + scr_hotbar (HUD panel: 9 slots, catalog names/ids, selector)        │
│   + scr_target (crosshair readout: material id / "SKY / AIR")           │
│   + scr_props  (≤16 MeshInstance3D)                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Uplink: `scr_edit_batch` (new, ABI-side — no input-batch change)

| Off | Type | Field |
|---|---|---|
| 0 | u8 | `op` — 0 none, 1 dig, 2 place |
| 1 | u8 | `select_slot` — 0 no change, 1..9 select hotbar slot |
| 2 | u16 | `reserved` = 0 |

New C ABI symbol: `scr_edit_submit(const scr_edit_batch*)` → appends to the edit FIFO (returns 0 or `SCR_ERR_QUEUE_FULL`). Consumed **one op per fixed tick** (FIFO), resolved entirely sim-side: `op=place` uses the **currently selected slot's** material id; cell = sim raycast of this tick's player pose (identical inputs ⇒ identical cell). **`SCR_SIM_ABI_VERSION` 1 → 2**; adapter refuses ABI ≠ 2 (negative test extended).

### 3.3 Snapshot contract additions (normative draft for `104_contract.md`)

Schema bump **+1 from then-current** (currently `1`); envelope + sections 1–6 unchanged; ids below provisional pending sibling execution order (§1.1).

**HOTBAR** (every snapshot) — `u32 count (=9)`, `u32 selected_index` (0-based), then `count × u32 material_id` (catalog ids). Section bytes = `8 + 4·count` (= 44).

**TARGET** (every snapshot, 32 bytes) — `u8 hit`; `u8 pad[3]`; `u32 material_id` (meaningful iff `hit`); `f32×3 hit_position` (world); `u32 cell_x, u32 cell_lattice_y, u32 cell_z` (edited/targeted column; valid iff `hit`). Miss ⇒ `hit = 0`, `material_id = 0`, positions/cells zero (HUD shows "SKY / AIR" per `A01_Render/HUD` §2.2 intent).

**RIGID_BODIES** (every snapshot; `count = 0` allowed) — `u32 count` (≤ 16), then `count × 36 bytes`: `f32×3 position`, `f32×3 euler_rad`, `u32 shape` (0 = box, 1 = sphere), `f32 size` (box: uniform half-extent; sphere: radius), `u32 material_id` (catalog). Section bytes = `4 + 36·count` (max 580 B).

**TERRAIN presence rule unchanged** — an edit bumps `world_version`, so the existing tracker (`sim/runtime.mojo`) emits TERRAIN **exactly once** in the next snapshot; subsequent snapshots omit it (adapter keeps meshes). FLORA (if 0006 landed) follows the same tracker; flora instances are recomputed by the sim on the same generation bump so cached instances never contradict new terrain (cross-milestone note).

### 3.4 Edit pipeline & performance note

```text
scr_edit_submit ─► edit FIFO ─► tick: pop 1 op
   │  dig:   h_new = h - 1 u (reject if surface_y would be ≤ 1 … bedrock inv.)
   │  place: h_new = h + 1 u
   ▼
classify_biome(x,z,h_new,r) ─► voxel_synthesis_pipeline(x,z,biome,FEATURE_NONE,h_new,ctx)
   ▼
heightfield[cell] = h_new ; surface_materials[cell] = pipeline surface
   ▼
rebuild ONLY chunk containing cell (TERRAIN_CHUNK_CELLS=16² vertices/normals/material_ids)
   ▼
world_version += 1 ─► next snapshot carries TERRAIN (+FLORA if 0006) once
```

**Performance note (recorded, not benchmarked):** a dig touches 1 column + 1 chunk mesh (≤ 17×17 verts) instead of the 64×64 heightfield; `docs/04` records this rule (AP-14). Full perf budgets remain `TBD — future milestone` (0002 §9 carried forward).

### 3.5 Minimal physics model (`PhysicsSubject`)

Terrain = **static body** (immobility constraint, `lib/501_Physics/Body`); props = **dynamic bodies** with mass-independent kinematics (uniform gravity, no inertia tensor): per fixed tick, semi-implicit Euler, then **contact resolution** vs heightfield sample under the prop's footprint — penetration ⇒ clamp to surface, kill downward velocity (restitution 0), tangential damping factor. **No inter-body collision/contact graph, no joints, no friction cones** (Contact/Collision subdomains consumed for *meaning* — non-penetration + impulsive-interaction separation — with the trivial solver recorded as a deviation subordinate to `PHYSICS-INV-003`: law ≠ discretization). Deterministic: bodies processed in slot order.

---

## 4. Semantic Library Consumption

| Domain / ID | Concept consumed (verified on disk) | Consumption mode |
|---|---|---|
| `SCR-LIB-PHYSICS` (`lib/501_Physics/101_definition.md` + children) | Parent: quantities/units (`§ Quantities and Units`), `PHYSICS-INV-001` semantic primacy, `PHYSICS-INV-002` quantity integrity, `PHYSICS-INV-003` law vs discretization, `PHYSICS-INV-018` runtime independence. Children (**all real definitions, verified**): `Body/` (static/kinematic/dynamic taxonomy — terrain static, props dynamic), `RigidBody/` (idealized body, invariant internal geometry), `Contact/` (non-penetration, normal force), `Collision/` (impulsive interaction), `Sensors/` (measurement interfaces extracting observational states — ray hit-test as observation), `Quantity/` (measurable property w/ value+unit) | **Spec-only — implement in Mojo per definition**: body taxonomy + contact/non-penetration semantics drive the minimal model (§3.5); ray hit-test = `Sensors` observation recorded as TARGET section. No external physics engine (Rule 18); solver subordinate to PHYSICS-INV-003, deviation recorded in `docs/04` |
| `SCR-LIB-RENDER-MATERIAL` (`lib/A01_Render/Material`) | `materials_catalog.json` (96 ids, verified): hotbar default set all present (`rock.basalt`, `soil.sand`, `rock.obsidian`, `mineral.sulfur`, `mineral.ash`, `fluid.lava`, `fluid.water`, `soil.dirt`, `rock.pumice`); catalog is authoritative for name/albedo/category | Hotbar vocabulary = catalog ids **only**; HUD labels derive from catalog/MATERIALS section; test asserts every slot id resolves (AP-3/AP-13) |
| `SCR-LIB-RENDER-HUD` (`lib/A01_Render/HUD/101_definition.md`, operational) | HUD is a **pure, read-only, derived, referentially transparent, non-authoritative projection**; explicitly **NOT** interactive world-state mutation; §2.2 **Material Inspector** uses `RayHit::material_code` + registry lookup, "SKY / AIR" when no surface targeted; provider MUST NOT expose controls that mutate semantic world state | Hotbar **selection is sim state**, delivered as input *intent* (`select_slot`) — HUD displays it, never mutates world (AP-8 compliant). TARGET drives the crosshair readout. **Full §2.2 inspector fields deferred** — §1.2 open decision (catalog lacks some fields) |
| `SCR-LIB-SPATIAL-VOXEL-SYNTHESIS` (`lib/801_Spatial/Voxel/Synthesis`) | Pure pipeline `(x,z,biome,feature,height,noise_context) → MaterialColumn`; §4 invariants: **bedrock (y=0) always MAT_BEDROCK, not overridable (inv.3)**, **water fills surface→sea_level where submerged (inv.4)**, write-once (inv.5), features above surface (inv.2); biome→material table §2 | Every edit re-runs `classify_biome` + pipeline for touched columns — the *sole* authority for new material assignment (§1.1); conformance tests extended to edited columns |
| `SCR-LIB-FIELD` / `SCR-LIB-SPATIAL` frames (`lib/301_Field`, `lib/801_Spatial`) | Height as scalar field w/ sampling semantics; position = value + explicit frame | Ray-march samples the height field (no ad-hoc height API); TARGET positions world-frame explicit |

**Not consumed this milestone:** `lib/705_Ecology`, `lib/601_Agent` (0006), `lib/503_Simulation/*` (children are structural stubs), `lib/804_Application` beyond unchanged Port→Adapter→Provider layering.

---

## 5. Deliverables & Sprint Breakdown

```text
applications/godot/
├── src/mojo/
│   ├── sim/
│   │   ├── edit.mojo                  # NEW: edit FIFO, dig/place, column re-synthesis, chunk rebuild, world_version bump
│   │   ├── raycast.mojo               # NEW: sim-owned ray-march → RayHit (TARGET source)
│   │   ├── hotbar.mojo                # NEW: 9-slot catalog table + selected slot (state machine)
│   │   ├── props.mojo                 # NEW: PhysicsSubject — N≤16 bodies, gravity, ground contact
│   │   ├── parameters.mojo            # + RAY_RANGE, PROP_*, hotbar slot table, chunk-rebuild params (AP-7)
│   │   ├── world.mojo                 # + edit/hotbar/props state owned by World
│   │   ├── input.mojo                 # + edit dispatch table rows (AP-5: table, not if/else)
│   │   └── runtime.mojo               # + per-tick edit consume; TARGET/HOTBAR/RIGID emission
│   ├── synthesis/voxel.mojo           # + re-synthesis entry for a single edited column (same pipeline, no fork)
│   └── snapshot/{types,encode,decode}.mojo  # + HOTBAR/TARGET/RIGID_BODIES (schema +1)
├── godot/
│   ├── scenes/island.tscn             # + scr_hotbar, scr_target, scr_props nodes
│   ├── scripts/player_input.gd        # + click → submit_edit(op); keys 1-9 / wheel → submit_edit(select_slot) (intent only)
│   ├── scripts/hotbar_hud.gd          # NEW: render HOTBAR section (catalog names/ids) — display only
│   └── scripts/props_view.gd          # NEW: RIGID_BODIES → node transforms (display only)
├── tests/mojo/
│   ├── test_edit_ops.mojo             # NEW: bedrock reject, sea-level fill, biome reclass, world_version, determinism after N edits
│   ├── test_raycast.mojo              # NEW: known-geometry hit/miss, cell/material correctness, range cap
│   ├── test_hotbar.mojo               # NEW: slot ids resolve from catalog, selection transitions, invalid slot rejected
│   ├── test_props.mojo                # NEW: bounded N, ground contact (no fall-through), deterministic sequence
│   ├── test_determinism.mojo          # EXT: scripted edit sequence ⇒ byte-identical sequence
│   ├── test_synthesis_conformance.mojo# EXT: pipeline invariants on edited columns
│   ├── test_envelope.mojo             # EXT: HOTBAR/TARGET/RIGID_BODIES framing round-trip
│   └── gen_golden_fixture.mojo        # RUN: fixture regen (schema +1)
├── tests/
│   ├── abi_smoke.py                   # EXT: scr_edit_submit symbol, 4-byte struct layout, ABI=2 gate
│   ├── test_terrain_resend.py         # NEW: after 1 edit ⇒ TERRAIN present in exactly the next snapshot, absent thereafter; world_version +1
│   ├── fixtures/snapshot_seed1_tick1.bin  # REGENERATED
│   └── godot/ …                       # EXT: godot_playability_test.{sh,gd} (one scripted dig/place leg), godot_screenshot (post-edit content assertions)
├── docs/04_simulation_engine.md       # + edit pipeline, raycast/hotbar/props model, params, chunk-rebuild perf note, evidence
├── docs/06_roadmap.md                 # + 0007 status row
└── program_increments/v0.0.1/milestone_0007_editing-physics/spec.md   # this file

providers/render/graphics/godot/
├── 104_contract.md                    # + §3.2 uplink, §4.3 HOTBAR/TARGET/RIGID_BODIES, ABI 2, schema +1
├── 102_status.yaml                    # + capability/status update
└── adapter/
    ├── scr_godot_abi.h                # + scr_edit_batch + scr_edit_submit, SCR_SIM_ABI_VERSION 2
    └── scr_godot_adapter.cpp          # + click/key/wheel → edit intent; apply_hotbar/apply_target/apply_props
```

### Sprint 01 — Edit ops + column recompute (Mojo)

- `edit.mojo`: FIFO + one-op-per-tick consume; dig/place with bedrock guard; single-column re-synthesis (`classify_biome` + pipeline); heightfield/surface update; chunk-local mesh rebuild; `world_version` bump.
- Tests: `test_edit_ops.mojo` — (a) bedrock invariant (dig rejected at `surface_y ≤ 1` precondition; lattice y=0 never overwritten), (b) sea-level fill (dig below `SEA_LEVEL` ⇒ water segment to sea level + biome reclassifies), (c) determinism after N scripted edits (identical snapshot sequence over 2 runs), (d) `world_version` +1 per applied op; `test_synthesis_conformance.mojo` extended for edited columns.

### Sprint 02 — Raycast + hotbar sim + minimal physics + contract

- `raycast.mojo` (sim-owned hit-test, range/epsilon params), `hotbar.mojo` (slot table + selection; invalid slot rejected), `props.mojo` (N≤16, gravity, ground contact, slot-order determinism), `scr_edit_submit` queue wired through `export/abi.mojo`.
- Contract: `104_contract.md` — uplink §3.2, downlink HOTBAR/TARGET/RIGID_BODIES, ABI 2, schema +1; encode/decode/round-trip; **fixture regeneration**.
- Tests: `test_raycast.mojo`, `test_hotbar.mojo`, `test_props.mojo`, `abi_smoke.py` extension (symbol + layout + ABI gate), `test_schema_mismatch.sh` re-run (ABI/schema refusal).

### Sprint 03 — Adapter / scene / HUD

- Adapter: click (captured mouse) → `op`; keys 1–9 + wheel → `select_slot`; `apply_hotbar` (labels from catalog/MATERIALS), `apply_target` (crosshair readout or "SKY / AIR"), `apply_props` (≤16 nodes); terrain refresh rides the existing TERRAIN path (chunk-local rebuild visible in-game).
- Scene: `scr_hotbar` panel, `scr_target` crosshair label, `scr_props` host; presentation scripts contain **zero gameplay logic** (AP-8 grep gate).
- AP-1/AP-4 gates re-run (`check_layout.sh`).

### Sprint 04 — Docs + verification

- `docs/04_simulation_engine.md`: edit pipeline diagram, raycast/hotbar/props semantics, parameter additions, chunk-rebuild perf note, verification evidence table (§7-style); `docs/05_provider_boundary.md` transport/binding note unchanged except uplink symbol list; `docs/06_roadmap.md` row.
- Full §7 gate run + item-by-item anti-pattern review (§2.1 AP-1..10 + §2.2 AP-11..14).

---

## 6. Formal Invariants

1. **Pipeline authority invariant:** world geometry/material changes happen only by re-running `classify_biome` + `voxel_synthesis_pipeline` on touched columns (AP-11); no direct grid pokes.
2. **Bedrock invariant:** lattice cell `y = 0` remains `MAT_BEDROCK` after any edit sequence; dig guard rejects ops that would expose/overwrite it (Synthesis §4 inv.3, test-asserted).
3. **Sea-level invariant:** any column whose height falls below `SEA_LEVEL` receives water fill to sea level and a water-row biome (Synthesis §4 inv.4, test-asserted).
4. **Hit authority invariant:** the edited cell/material derives solely from sim raycast + sim hotbar state; client submits `{op, select_slot}` only (AP-12).
5. **Catalog vocabulary invariant:** every hotbar slot id, placed material id and prop material id resolves from `materials_catalog.json`; no parallel list anywhere (AP-3/AP-13).
6. **Emission invariant:** each applied edit ⇒ exactly one `world_version` increment ⇒ TERRAIN present in **exactly the next snapshot**, absent afterwards until the next generation change (ABI test).
7. **Bounded physics invariant:** `rigid_body_count ≤ 16`; no prop below bedrock/inside terrain after contact resolution (test).
8. **Determinism invariant:** fixed timestep; same seed + same inputs + same edit sequence ⇒ byte-identical snapshot sequence (headless, no Godot).
9. **Version invariant:** `SCR_SIM_ABI_VERSION` 1→2 and `SCR_SIM_SCHEMA_VER` +1 (from then-current), fixture regenerated, adapter refuses mismatches (negative tests). Sibling rebasing rule §1.1.
10. **HUD non-authority invariant:** HUD/hotbar/target are read-only projections (`A01_Render/HUD` §1); selection reaches the sim only as input intent (AP-8).
11. **Honesty invariant:** deferred Material Inspector fields (§1.2), advanced physics, and any perf gap marked `TBD — future milestone` in `docs/04`.
12. **Scope invariant (0007 §9):** no flora/fauna, no transport swap, no weather — successors.

---

## 7. Exit Criteria

All commands from repo root; `M=.venv/bin/mojo`.

- [x] **Dig/place visibly changes terrain + regeneration correctness (automated ABI test):** `python3 applications/godot/tests/test_terrain_resend.py` — one edit ⇒ `world_version` +1 and TERRAIN present in **exactly the next** snapshot and absent in all following (until next edit); no-edit run ⇒ zero TERRAIN resends.
- [x] **Bedrock + sea-level invariants (automated):** `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_edit_ops.mojo` — dig rejected at bedrock guard; submerged dig ⇒ water fill + biome reclass; `world_version` bookkeeping.
- [x] **Determinism after scripted edit sequence (automated):** `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_determinism.mojo` — seed 1 + scripted N edits + inputs ⇒ byte-identical snapshot sequence (2 runs).
- [x] **Raycast correctness (automated):** `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_raycast.mojo` — known-geometry hit/miss, cell + material ids, range cap, miss ⇒ zeros.
- [x] **Hotbar ids resolve from catalog (automated):** `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_hotbar.mojo` — all 9 slot ids ∈ `materials_catalog.json`; selection transitions; invalid slot rejected.
- [x] **Props bounded + grounded (automated):** `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_props.mojo` — count ≤ 16, no fall-through, deterministic across runs.
- [x] **Contract/ABI gates (automated):** `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_envelope.mojo` (new sections round-trip), fixture regen + `test_golden_fixture.mojo`, `python3 applications/godot/tests/abi_smoke.py` (incl. `scr_edit_submit`, 4-byte layout, ABI=2), `bash applications/godot/tests/test_schema_mismatch.sh` (ABI/schema refusal), `bash applications/godot/scripts/build_godot_provider.sh`.
- [x] **Dig/place visible in game (precisely documented manual procedure):** (1) `bash applications/godot/tests/godot/godot_screenshot.sh` → baseline `build/island.png`; (2) interactive run `godot --path applications/godot/godot` (scene `res://scenes/island.tscn`), capture mouse, LMB = dig once on terrain ahead, keys `2`/`3` then place once, verify visibly changed contour + hotbar selection moved; (3) re-run step (1) → `build/island.png`; (4) record both captures + terrain-chunk content assertion in the `docs/04_simulation_engine.md` evidence table. Automated companion: `bash applications/godot/tests/godot/godot_load_test.sh` PASS (0 `ERROR:` lines) after edits are exercised in a scripted run (playability script extended with one dig/place leg).
- [x] **All milestone 0002 gates green (automated):** the seven §8 procedures of `docs/04_simulation_engine.md` PASS (incl. `check_layout.sh` AP-1/AP-4, `godot_load_test.sh`, `godot_playability_test.sh` — player must still walk on re-generated terrain without fall-through).
- [x] **Review pass:** §2.1 (AP-1..10) + §2.2 (AP-11..14) checked item-by-item; results appended to `docs/04`.

---

## 8. Dependencies

- **Predecessor:** [milestone 0002](../milestone_0002_scene-initiation/spec.md) (Complete) — world_version → TERRAIN resend path, input dispatch table, catalog loader, adapter decode.
- **Semantic contracts:** `lib/501_Physics` (+ `Body`, `RigidBody`, `Contact`, `Collision`, `Sensors`, `Quantity`), `lib/A01_Render/Material`, `lib/A01_Render/HUD`, `lib/801_Spatial/Voxel/Synthesis`, `lib/301_Field`, `lib/801_Spatial`.
- **Contract surface:** [`providers/render/graphics/godot/104_contract.md`](../../../providers/render/graphics/godot/104_contract.md) (§3.2/§4.3/§7), [`docs/04_simulation_engine.md`](../../../docs/04_simulation_engine.md), [`docs/05_provider_boundary.md`](../../../docs/05_provider_boundary.md), [`docs/06_roadmap.md`](../../../docs/06_roadmap.md).
- **Reference content (adapting, not normative):** cave hotbar/inspector UI intent (`applications/cave/include/island_hud.hpp`) — its 9-slot interaction pattern only; vocabulary stays catalog-driven (AP-3).
- **Toolchain:** unchanged (Mojo 1.0.0, Godot 4.7.2, godot-cpp per `docs/02_development_environment.md`).

---

## 9. Out of Scope

- Advanced physics: inter-body collision/contact graph, stacking, joints/constraints, friction cones, kinematic props, props-as-raycast-occluders, `SoftBody`/`Fluid` — successors (`501_Physics/{Collision,Contact,Constraints,Solvers}` full semantics).
- Full Material Inspector field set (§1.2 — catalog fields incomplete) — `TBD — future milestone`.
- Multi-cell brush edits, undo/redo, world save/regenerate UI, block inventory/counts — successors (Rule 10: specify first).
- Flora/fauna (0006), IPC transport (0008), weather/atmosphere, lava/plume — successors.
- Performance benchmarking beyond the chunk-local rule note; MLIR dialect/lowering work (Rule 15).

---

## 10. Successor Milestones

| Intent | Triggering contracts |
|---|---|
| IPC transport swap | [milestone 0008](../milestone_0008_ipc-transport/spec.md), stabilized `104_contract.md` §2 |
| Ecology: flora + fauna (incl. flora recompute interacting with edits) | [milestone 0006](../milestone_0006_ecology/spec.md), `705_Ecology`, `601_Agent` |
| Full physics (contact graph, stacking, raycast vs bodies) | `501_Physics/{Collision,Contact,Constraints,Solvers,SoftBody}` |
| Full HUD / Material Inspector | `A01_Render/HUD` §2.1–2.2 complete (catalog field extension) |

Exact sequencing of successors beyond 0006/0007/0008: `TBD — future milestone` (Rule 10).
