# Milestone 0002: Scene Initiation — Volcanic Island

**Program Increment:** v0.0.1
**Milestone:** 0002 — Scene Initiation (Volcanic Island)
**Project:** Godot Simulation (applications/godot)
**Parent System:** Semantic Computational Runtime (SCR)
**Status:** Complete
**Primary Language:** Mojo
**Initial Engine Provider:** Godot 4.7.2
**Binding Architecture:** RenderSnapshot contract + in-process GDExtension (godot-cpp)
**Scene Scope:** Core slice — terrain + ocean + sky + player (playable)
**Predecessor:** [milestone_0001_project-initiation/spec.md](../milestone_0001_project-initiation/spec.md)

---

## 1. Scope & Objective

Convert the milestone 0001 template workspace into a **fully rendered and playable volcanic island scene** running in Godot, where:

- **Mojo simulation core** owns all scene semantics: world state, terrain synthesis, ocean state, player locomotion, time — consuming SCR semantic library contracts (`lib/`).
- **Godot** is strictly the presentation provider: it captures input, materializes snapshot state into scene nodes, and renders.
- **Providers/adapters** connect the semantic library to the Godot engine through a normative **RenderSnapshot contract** delivered in-process via **GDExtension** (godot-cpp) over a **Mojo C ABI**.

This milestone establishes the first complete semantic → contract → adapter → provider → manifestation vertical slice of the Godot application.

### 1.1 Decisions Locked (architectural, confirmed before drafting)

| Decision | Choice |
|---|---|
| Binding mechanism | RenderSnapshot/projection contract (finishes `applications/cave/program_increments/v0.0.3_IsolatedSimulation` intent) + in-process GDExtension adapter loading Mojo C-ABI `.so` |
| Scene feature set | Core slice: procedural volcanic terrain, Gerstner ocean, sky, playable first-person player. Atmosphere/weather, lava/plume, vegetation, fauna, partitions = successor milestones |

### 1.2 Governing Principle

> Never allow implementation convenience to silently redefine computational semantics.

```text
Semantic Meaning → Contract → Representation → Transformation → Lowering → Provider → Runtime → Execution Substrate
```

Godot is a provider and manifestation surface (`docs/05_provider_boundary.md`). The snapshot is a contract. The semantic library (`lib/`) is authoritative for meaning; the Mojo core is its executable consumer; GDScript/Godot nodes hold no semantic authority.

---

## 2. Lessons from the Reference Implementation (Normative "MUST NOT")

`applications/cave/src/simulation_main.cpp` (971 lines) is the reference for **scene content** and the reference for **anti-patterns**. This milestone treats its failures as normative prohibitions.

### 2.1 Anti-patterns inherited from the reference — MUST NOT reproduce

| # | Anti-pattern | Evidence in reference | Required correction |
|---|---|---|---|
| AP-1 | Engine types leak into simulation layer | `lib/simulation/simulation_systems.hpp:7` includes OGRE subsystems; sim code uses `Ogre::Vector3/Ray` | Semantic layer (`src/mojo/`) imports zero Godot/GDScript/engine types; enforced by grep gate (§7) |
| AP-2 | Semantic library bypassed | No `lib/<domain>` code included anywhere; conformance = comment strings only (`island_hud.hpp:4` etc.); `semantic_contract` field set but never validated (`simulation_framework.hpp:28`) | Every `SCR-LIB-*` claim backed by an executable test; domains consumed by ID, not by comment |
| AP-3 | Dual material vocabularies | OGRE `SCR/*` materials hand-authored (`simulation_main.cpp:209-303`) diverge from `Material::MAT_*` catalog | Single material source: `lib/A01_Render/Material/materials_catalog.json`; shading parameters derived, never re-invented |
| AP-4 | Absolute hardcoded paths | `/home/kobus/...` in `lib/simulation/semantic_materials.hpp:312,427` | Repo-relative resolution only; test asserts no absolute path in sources |
| AP-5 | Monolith frame loop + giant dispatch | `frameRenderingQueued` = 461 lines; 392-line if/else IPC chain | Separated modules: sim tick / projection / adapter / presentation; input dispatch table |
| AP-6 | Abstraction pierced by `dynamic_cast` | 12× `dynamic_cast<VolcanicIslandScene*>` | Typed contracts only; no scene-type downcasts across layer boundary |
| AP-7 | Magic constants inline | Mouse sens `0.0028f`, speeds `4.25/8.0/5.8`, spawn coords, dt clamp `0.05f` scattered in code | All tunables in one declared parameter table (documented in `docs/04_simulation_engine.md`) |
| AP-8 | Presentation mutates sim state / sim draws directly | Hub and scene write OGRE `ManualObject` buffers directly | One-way state channel: sim → snapshot → adapter → nodes. Sim never touches nodes; nodes never touch world |
| AP-9 | Render-thread work stalls | IPC dispatch runs on render thread (`simulation_main.cpp:370-371`) | Adapter consumption of snapshot is O(snapshot); input capture non-blocking; no socket I/O on render thread |
| AP-10 | Shell-script-selected providers with no contract | `run_simulation_hub.sh:42-48` hardcodes `-I` dirs + adapter `.cpp` | Provider realized under repo convention with control docs (`101_definition.md`, `102_status.yaml`, `104_contract.md`) |

### 2.2 Scene content worth porting (from the reference)

Terrain with beach spawn and height query; spatial partitions (successor); Gerstner ocean w/ sea level; sky + time-of-day; player locomotion (walk/sprint/jump/gravity, mouse-look); semantic material hotbar semantics (successor); HUD (successor). **Core slice takes:** terrain, ocean, sky, player locomotion, materials. 

---

## 3. Architecture & Binding Contract

### 3.1 Layer diagram

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ SCR semantic library (lib/) — meaning, authoritative                    │
│   801_Spatial/Voxel/Synthesis · 202_Math/Noise · 202_Math/Gerstner      │
│   301_Field · 302_Geometry · A01_Render/{Material,Water,Sky}            │
│   501_Physics (quantities/gravity) · 101_Core (identity/state)          │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │ contracts consumed by semantic ID
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Mojo simulation core — src/mojo/ (semantic consumer, authority-free)    │
│   world + fixed-timestep loop + subjects (Island, Player, Hydrology,    │
│   Atmosphere-lite) + voxel synthesis + Gerstner state + material load   │
│   owns: world_version / state_generation / simulation_tick / time       │
│   output: RenderSnapshot (immutable projection — MUST NOT mutate world) │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │ C ABI (.so) — snapshot down, input up
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Provider: providers/render/graphics/godot/adapter/ (godot-cpp GDExt.)   │
│   decode snapshot → update Godot nodes/shaders                          │
│   capture input events → input batch to sim                             │
│   NO semantic decisions; representation conversion only                 │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Godot application — godot/ (manifestation)                              │
│   island.tscn: terrain MeshInstance3D, ocean plane + shader, sky,       │
│   camera rig, HUD stub. Rendering/presentation only.                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 RenderSnapshot contract (normative minimum)

Modeled on `applications/cave/lib/simulation/projection/101_spec.md` (Projection MUST NOT mutate World) and `applications/cave/lib/simulation/state/101_spec.md` (commit metadata). The Godot contract is defined fresh in `docs/` + provider `104_contract.md`; deviations from the cave specs recorded explicitly.

**Envelope (required fields):**

```text
schema_version        # contract compat; adapter rejects mismatch
world_version         # commit metadata (state spec)
state_generation
simulation_tick
simulation_time
determinism_epoch
seed
```

**Payload sections:**

| Section | Content | Consumed by |
|---|---|---|
| `player` | position, velocity, yaw, pitch, eye_height, on_ground, in_water | camera rig / player node |
| `terrain` | extent, chunk list: vertices, normals, material-ids (per-face or per-vertex) | terrain MeshInstance3D(s) |
| `terrain_meta` | seed, sea_level, peak_height, spawn_position | spawn, HUD |
| `ocean` | sea_level, Gerstner params (amplitude, frequency, steepness, direction, speed), phase | ocean shader uniforms |
| `sky` | time_of_day_hours, sun azimuth/elevation, fog density/color | sky shader, DirectionalLight3D |
| `materials` | entries for materials present: semantic id, albedo, roughness, opacity, emissive — sourced from catalog | material overrides |

**Input uplink (Godot → sim, per tick batch):**

```text
InputEventBatch { move: Vector2, look_delta: Vector2, jump, sprint, action_primary, action_secondary }
```

The sim owns all locomotion integration; Godot captures and forwards raw intent only.

### 3.3 Data flow rules

1. **Down:** sim tick → project → encode snapshot → GDExtension decode → node update. Read-only w.r.t. world.
2. **Up:** Godot input → C ABI input call → sim input queue → consumed at next fixed tick.
3. **One channel:** the snapshot is the *only* state channel. No shared memory mutation, no direct node access from `src/mojo/`, no world access from GDScript.
4. **Single process:** GDExtension in-process binding; transport implementation detail (in-proc function calls) is swappable to IPC later without contract change.

### 3.4 Timestep model

Fixed-timestep simulation loop in Mojo (default **60 Hz**, dt clamp on frame delta), interpolable presentation state — port the intent of cave's `FixedTimestepSimulationLoop` (`applications/cave/include/simulation_engine.hpp:55-155`). Determinism: same seed + same input sequence ⇒ byte-identical snapshot sequence (headless test).

---

## 4. Semantic Library Consumption

Consumption is **by semantic ID** per `lib/README.md` conventions, with relations recorded in docs (not invented semantics).

| Domain / ID | Concept consumed | Consumption mode |
|---|---|---|
| `SCR-LIB-SPATIAL-VOXEL-SYNTHESIS` (`lib/801_Spatial/Voxel/Synthesis`) | VoxelSynthesisPipeline `(x,z,biome,feature,height,noise_context) → MaterialColumn`; biome→material table (VOLCANIC_SLOPE→BASALT, CALDERA_RIM→ASH/SULFUR/OBSIDIAN, CALDERA_LAKE→LAVA…); bedrock + sea-level fill invariants | Implement pipeline as specified; conformance test asserts table + invariants |
| `SCR-LIB-MATH-NOISE` (`lib/202_Math/Noise`) | Deterministic fBm/Perlin/ridged height signal; invariants (deterministic, seed-dependent) | **Spec-only contract — implement in Mojo** per definition |
| `SCR-LIB-MATH-GERSTNER` (`lib/202_Math/Gerstner`) | Trochoidal waves, analytic normals, Jacobian crest/foam factor | **Spec-only — implement** as sim state; shader displaces for display |
| `SCR-LIB-FIELD` (`lib/301_Field`) | Terrain height as scalar field over spatial domain; sampling/interpolation semantics | Height queries via field semantics; no ad-hoc height API |
| `SCR-LIB-GEOMETRY` (`lib/302_Geometry`) | Mesh/surface semantics; coordinate explicitness (RULE-003); rendering separation (RULE-012) | Snapshot mesh arrays are representation; semantics = field + frames |
| `SCR-LIB-RENDER-MATERIAL` (`lib/A01_Render/Material`) | `materials_catalog.json` (96 materials: `rock.basalt`, `fluid.lava`, `water`, `mineral.ash`…) + reactions | Catalog loaded repo-relative; shading params derived from catalog only |
| `SCR-LIB-RENDER-WATER` (`lib/A01_Render/Water`) | Shoreline foam from `y_terrain(x,z)` vs `y_water(x,z,t)`; Fresnel/palette intent | Foam factor computed in sim or shader from snapshot fields (recorded choice) |
| `SCR-LIB-RENDER-SKY` (`lib/A01_Render/Sky`) | Diurnal solar arc, sky gradient tiers | Minimal: sun position from time_of_day + gradient sky |
| `SCR-LIB-SPATIAL` frames (`lib/801_Spatial`) | Position = value + reference frame; `SPATIAL-INV-002` | World frame explicit; Godot node transforms = representation of snapshot transforms |
| `SCR-LIB-PHYSICS` quantities/gravity (`lib/501_Physics`) | Gravity, quantities | Locomotion gravity constant; units documented |
| `lib/804_Application` | Port → Adapter → Provider layering | Binding architecture conforms (§3) |

**Known spec-only gaps** (contract exists, no lib code — implement the contract, record deviations, never silently redefine): Noise, Gerstner, Atmosphere (successor), `A01_Render/Volcano` (successor), Weather (successor), WFC (successor).

**Not consumed this milestone:** `lib/simulation/*.hpp` (C++/OGRE-legacy — reference only; its material-catalog loader logic may be *ported* to Mojo, fixing AP-4), `lib/scr_kernel/*.mojo` (prototype — evaluate reuse in sprint 01, do not assume).

---

## 5. Deliverables & Sprint Breakdown

```text
applications/godot/
├── src/mojo/
│   ├── main.mojo                       # existing placeholder → becomes CLI entry (headless sim run)
│   ├── sim/                            # world, fixed timestep, subjects (Island, Player, Hydrology, Atmosphere-lite)
│   ├── synthesis/                      # noise + voxel synthesis per SCR-LIB-MATH-NOISE + VOXEL-SYNTHESIS
│   ├── materials/                      # catalog loader (repo-relative JSON)
│   ├── ocean/                          # Gerstner state per SCR-LIB-MATH-GERSTNER
│   ├── snapshot/                       # RenderSnapshot types, projection (pure), encode
│   └── export/                         # C ABI exports (init/step/get_snapshot/input/shutdown)
├── godot/
│   ├── scenes/island.tscn              # island scene (replaces empty main.tscn as default)
│   ├── scripts/                        # snapshot consumer, input capture, camera rig (presentation only)
│   ├── shaders/                        # ocean (Gerstner displacement), sky
│   └── addons/scr_godot/               # .gdextension descriptor + loader glue
├── tests/mojo/                         # determinism, projection purity, catalog, synthesis, Gerstner
├── tests/godot/                        # headless scene load + smoke script
├── scripts/                            # + build_godot_provider.sh, run_island.sh; check_layout.sh updated
├── docs/                               # 04/05/06 updated (fill TBDs), 02 (+godot-cpp dep), snapshot contract doc
└── program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md   # this file

providers/render/graphics/godot/        # repo provider convention (lib/README.md:1857-1859)
├── 101_definition.md                   # what the Godot render provider is
├── 102_status.yaml                     # status/capabilities/providers blocks
├── 103_provider.graph.json             # derived relationships
├── 104_contract.md                     # RenderSnapshot + InputEventBatch contract (normative)
└── adapter/                            # godot-cpp GDExtension adapter sources (C ABI header consumer)
```

**Layout amendment:** milestone 0001 invariant 5 (`spec.md` §3) restricted future source to the declared workspace layout. This milestone amends it: repo-level `providers/render/graphics/godot/` is required by the source-of-truth hierarchy (provider convention outranks app layout); `scripts/check_layout.sh` is updated to verify the provider tree as part of §7.

### Sprint 01 — Semantic core (Mojo)

- Fixed-timestep world, subjects (`IslandSubject`, `PlayerSubject`, `HydrologySubject`, `AtmosphereSubject`-lite), commit metadata.
- Noise + voxel synthesis implementing `SCR-LIB-MATH-NOISE` + `SCR-LIB-SPATIAL-VOXEL-SYNTHESIS` (volcanic biome profile, single island, no voyage).
- Material catalog loader (repo-relative, no absolute paths).
- Terrain height field access per `SCR-LIB-FIELD`; spawn = beach position.
- Headless determinism test: seed + scripted input ⇒ identical snapshot sequence.

### Sprint 02 — Snapshot & projection

- `RenderSnapshot` types + pure projection (world → snapshot; MUST NOT mutate world — test-enforced).
- Encode/decode schema with `schema_version`; `104_contract.md` draft promoted to normative.
- Input uplink queue and dispatch (table-driven, no if/else chain).
- Tests: projection purity, envelope metadata, schema round-trip.

### Sprint 03 — Godot provider & adapter

- Provider control docs (`101/102/103/104`).
- godot-cpp GDExtension for Godot 4.7.2; C ABI header + Mojo `.so` build (`scripts/build_godot_provider.sh`; dependency pinning recorded in `docs/02_development_environment.md`).
- Adapter: snapshot decode → node/shader updates; input capture → sim.
- AP-1 gate: grep proves zero engine types in `src/mojo/`.

### Sprint 04 — Scene & playability

- `island.tscn`: terrain mesh from snapshot chunks, ocean plane + Gerstner shader, sky + DirectionalLight3D from time_of_day, camera rig bound to `player` section.
- Player: WASD/arrows move, Shift sprint, Space jump, mouse-look (capture); locomotion semantics live in sim (defaults: walk 4.25, sprint 8.0, jump 5.8, gravity −10, dt clamp 0.05 — parameter table in `docs/04_simulation_engine.md`, AP-7).
- Minimal HUD stub (tick/seed readout only; full HUD successor).
- Docs: fill `04_simulation_engine.md` TBDs (domain model, timestep, binding protocol, scene↔state mapping), `05_provider_boundary.md` §5 (binding protocol now specified), `06_roadmap.md` (0002 status + successors).

---

## 6. Formal Invariants

1. **Authority invariant:** semantic library defines meaning; Mojo core consumes it; GDScript/nodes never define scene semantics (`Provider ≠ Semantic Authority`).
2. **Single-channel invariant:** RenderSnapshot (down) + InputEventBatch (up) are the only state channels across the sim↔Godot boundary.
3. **Projection purity invariant:** projection produces snapshots without mutating world state.
4. **Engine isolation invariant:** `src/mojo/` contains no Godot/GDScript/engine types or imports (grep-enforced).
5. **Catalog invariant:** every material rendered derives from `lib/A01_Render/Material/materials_catalog.json`; no hand-authored parallel vocabulary (AP-3).
6. **Path invariant:** zero absolute filesystem paths in sources/tests (AP-4).
7. **Conformance invariant:** every `SCR-LIB-*` claim in code/docs maps to an executable test; comment-only conformance forbidden (AP-2).
8. **Determinism invariant:** fixed timestep; same seed + same inputs ⇒ identical snapshot sequence; verified headless without Godot.
9. **Honesty invariant:** unimplemented contract details marked `TBD — future milestone`; deviations from source contracts recorded, never silent.
10. **Scope invariant:** no weather, lava/plume, vegetation, fauna, multi-biome, or external IPC transport introduced (§9).

---

## 7. Exit Criteria

- [x] `godot --headless --path applications/godot/godot` loads the island scene with no errors.
- [x] Volcanic island visibly renders (terrain + ocean + sky + sun); verified by automated screenshot (non-blank/luminance check) or documented manual capture.
- [x] Playable: mouse-look, WASD movement, sprint, jump; player walks on terrain without falling through; verified by scripted input run or documented manual session.
- [x] Headless determinism test passes: N ticks, fixed seed, scripted inputs ⇒ byte-identical snapshot sequence (runs without Godot).
- [x] Projection purity test passes: world state hash unchanged across projection.
- [x] Material catalog test: all rendered material ids resolve from `materials_catalog.json`; repo-relative load; AP-4 grep gate clean.
- [x] AP-1 grep gate: no engine types/imports in `src/mojo/`.
- [x] `SCR-LIB-SPATIAL-VOXEL-SYNTHESIS` conformance test: biome→material table + bedrock/sea-level invariants for the volcanic profile.
- [x] Gerstner test: deterministic wave heights + Jacobian foam factor within contract ranges.
- [x] Provider tree exists with control docs; `104_contract.md` normative; `scripts/check_layout.sh` (updated) passes.
- [x] GDExtension builds via `scripts/build_godot_provider.sh`; `.so` loads in Godot (log-verified).
- [x] `schema_version` mismatch between adapter and sim is rejected loudly (negative test).
- [x] Docs updated: `04` TBDs filled, `05` §5 binding specified, `06` roadmap updated, `02` pins godot-cpp/Mojo/Godot versions.
- [x] Review pass: §2 anti-pattern table checked item-by-item against the implementation.

---

## 8. Dependencies

- **Predecessor:** [milestone 0001](../milestone_0001_project-initiation/spec.md) (Complete) — workspace, docs skeleton, toolchain pins (Mojo 1.0.0, Godot 4.7.2).
- **Semantic contracts:** `lib/801_Spatial/Voxel/Synthesis`, `lib/202_Math/{Noise,Gerstner}`, `lib/301_Field`, `lib/302_Geometry`, `lib/A01_Render/{Material,Water,Sky}`, `lib/501_Physics`, `lib/804_Application`.
- **Reference specs (adapt, record deviations):** `applications/cave/lib/simulation/{projection,state}/101_spec.md`; cave scene content (`scene_volcanic_island.hpp`) as content reference only.
- **External toolchain:** Mojo 1.0.0 (repo `.venv`), Godot 4.7.2, godot-cpp matching 4.7.2, C++ toolchain + build driver for GDExtension, pixi/uv per repo `pyproject.toml`.
- **Repo conventions:** `AGENTS.md`, `lib/README.md` provider realization rule (`providers/` at repo level).

---

## 9. Out of Scope

- Weather system, atmosphere scattering, precipitation (`A01_Render/Sky` full tiers, `503_Simulation/Weather`) — successors.
- Volcano lava flows, caldera glow, smoke/ash plume (`SCR-LIB-RENDER-VOLCANO`) — successor.
- Vegetation, boids/fauna, Bullet physics, voxel mine/place editing, material hotbar — successors.
- Multi-biome voyage, spatial partition teleports, world save/regenerate — successors.
- Full HUD, loading screen, scene selector — successors.
- Out-of-process IPC transport (socket/msgpack) — transport swap after contract stabilizes; contract designed to permit it.
- MLIR dialect/lowering work, performance optimization, provider qualification beyond this provider's control docs.

---

## 10. Successor Milestones

| Intent | Triggering contracts |
|---|---|
| Atmosphere & weather | `202_Math/Atmosphere`, `A01_Render/Sky`, `503_Simulation/Environment/Weather` |
| Volcano: lava + plume | `A01_Render/Volcano`, material catalog reactions (`lava_water_quench`) |
| Ecology: flora + fauna | `705_Ecology`, `601_Agent/Flocking` |
| Editing, hotbar, physics | `501_Physics` bodies, material hotbar semantics |
| IPC transport swap | stabilized snapshot contract (`104_contract.md`) |
| Second scene (ocean/atmosphere lab parity) | `503_Simulation` scenarios |

Exact sequencing and exit criteria: TBD — future milestone (Rule 10: specify before implementing).
