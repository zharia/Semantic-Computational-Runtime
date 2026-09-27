# Milestone 0003: Volcano — Lava + Plume

**Program Increment:** v0.0.1
**Milestone:** 0003 — Volcano (lava lake + convective plume)
**Project:** Godot Simulation (applications/godot)
**Parent System:** Semantic Computational Runtime (SCR)
**Status:** Planned
**Primary Language:** Mojo
**Initial Engine Provider:** Godot 4.7.2
**Binding Architecture:** RenderSnapshot contract + in-process GDExtension (godot-cpp)
**Scene Scope:** Core slice — caldera lava lake (emissive), convective plume, crater glow
**Predecessor:** [milestone_0002_scene-initiation/spec.md](../milestone_0002_scene-initiation/spec.md) (Complete)

---

## 1. Scope & Objective

Add the **volcano semantic slice** to the playable volcanic island: a sim-owned
caldera lava lake (level, emissive intensity, effusion state — deterministic,
seeded) and a convective smoke/ash plume (buoyant vertical motion + noise
turbulence), delivered through the RenderSnapshot contract to a Godot scene with
an emissive lava material, a GPU particle plume, and a crater glow light.

- **Mojo simulation core** gains `VolcanoSubject` and plume emission parameters,
  consuming `lib/A01_Render/Volcano`, `lib/202_Math/Noise`, and the material
  catalog (lava entries + reactions).
- **Godot** remains strictly the presentation provider: it materializes the new
  `VOLCANO` / `PLUME` snapshot sections into nodes/materials and renders.
- **Contract** grows two sections; `SCR_SIM_SCHEMA_VER` **1 → 2** (§3.5).

This milestone fulfills the milestone 0002 §10 successor row
*"Volcano: lava + plume — `A01_Render/Volcano`, material catalog reactions
(`lava_water_quench`)"*.

### 1.1 Decisions Locked (architectural, confirmed before drafting)

| Decision | Choice | Rationale / rejected alternative |
|---|---|---|
| Plume particle system | **`GPUParticles3D`** (locked) | Sim supplies *emission parameters only* (rate, initial velocity, spread, turbulence, lifetime); the GPU integrates particles for display — same authority split as Gerstner (sim physics / shader display). Rejected: `CPUParticles3D` — per-particle CPU integration on the render thread buys no semantics and risks AP-9-class stalls |
| Plume motion composition | **Buoyant vertical + noise turbulence only; no wind advection** (locked) | Wind vector arrives in [milestone 0004](../milestone_0004_atmosphere-weather/spec.md); plume wind-drift is a successor hook (§10). Keeps 0003 deterministic without a wind input |
| Lava lake authority | **Sim-owned `VolcanoSubject`**: lake level, emissive intensity, crust fraction, effusion state — all derived from seed + sim time (locked) | Display must never derive lava state (AP-11). Shader adds spatial crust *pattern* only (display, analogous to display-only ocean harmonics) |
| Crater glow light | **Sim computes `glow_intensity`** (emissive × night factor from sun elevation); adapter applies to `OmniLight3D` group `scr_crater_glow` (locked) | Adapter must not compute "night" itself (no semantic decisions). Rejected: adapter-side time-of-day scaling — duplicates sim atmosphere semantics |
| `lava_water_quench` | **Documented partial** in this milestone; reaction evaluator completes in [milestone 0005](../milestone_0005_shoreline-fidelity/spec.md) (locked) | No lava↔water face adjacency exists in the current island (crater above sea level, no flows); inventing quench thresholds now would violate Rule 9 |
| Schema evolution | `SCR_SIM_SCHEMA_VER` **1 → 2**; new sections `7 VOLCANO`, `8 PLUME`; golden fixture regenerated (locked) | §7 of `104_contract.md`: additive changes require a bump; adapter MUST NOT guess |

### 1.2 Governing Principle

> Never allow implementation convenience to silently redefine computational semantics.

```text
Semantic Meaning → Contract → Representation → Transformation → Lowering → Provider → Runtime → Execution Substrate
```

Godot is a provider and manifestation surface. The snapshot is a contract. The
semantic library (`lib/`) is authoritative for meaning; the Mojo core is its
executable consumer; GDScript/Godot nodes hold no semantic authority.


### 1.3 Open decisions (confirm before drafting final)

Everything above is locked as recommended default. Two items seek explicit
confirmation before the contract is finalized:

1. **VOLCANO/PLUME byte layouts + section IDs** (§3.2: 32 B each, IDs 7/8) —
   **Open decision — confirm before drafting final** (recommend: as tabled; stride-symmetric, mirrors existing 8×f32 style).
2. **Night-glow evidence path** (§7 manual procedure = temporary `TIME_OF_DAY_START_HOURS` edit + fixture regen) —
   **Open decision — confirm before drafting final** (recommend: manual procedure; rejected alternative: init-time ABI parameter, which forces a `SCR_SIM_ABI_VERSION` bump).

---

## 2. Lessons & Continuing Anti-Pattern Constraints

`AP-1 … AP-10` from
[milestone 0002 §2.1](../milestone_0002_scene-initiation/spec.md) **remain
normative for this milestone** (not restated here): no engine types in
`src/mojo/`, no comment-only conformance, single material catalog, no absolute
paths, module separation, no downcast pierce, all tunables in
`parameters.mojo`, one-way state channel, no render-thread stalls, provider
under repo control docs.

### 2.1 New anti-patterns (this milestone)

| # | Anti-pattern | Evidence / rationale | Required correction |
|---|---|---|---|
| AP-11 | Display-derived lava/plume state | 0002 lava read salmon/mauve because emission *appearance* was left to adapter defaults (`docs/04_simulation_engine.md` §8.1) — presentation inferred semantics instead of contract carrying them | All lava/plume *state* (level, emissive intensity, crust fraction, effusion, glow) comes from `VOLCANO`/`PLUME` sections; shader/node side holds representation only |
| AP-12 | Unseeded randomness in sim state | Plume/effusion introduce stochastic-looking behavior; unseeded RNG breaks the determinism invariant (0002 §6.8) | Effusion state machine seeded from `World.seed` (deterministic PRNG stream, test-locked). Display-only particle jitter is permitted but MUST be documented display-only and never feed back into sim |
| AP-13 | Schema growth without bump / adapter guessing | 0002 MATERIALS blocker (contract header vs field table) showed silent framing drift costs a whole sprint | Bump to schema 2, regenerate fixture, extend `abi_smoke.py` + `test_envelope.mojo`, keep `test_schema_mismatch.sh` green (stub updated to report `SCR_SIM_SCHEMA_VER + 1`) |
| AP-14 | Inventing reaction semantics | `reaction.lava_water_quench` is normative (`material_reactions.json`); a partial hand-rolled quench with invented thresholds would redefine it | Quench = documented partial here (consumption table + `04` §9 gap); evaluator implemented against the catalog reaction verbatim in milestone 0005 |

---

## 3. Architecture & Binding Contract

### 3.1 Layer diagram (delta over 0002 §3.1)

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ SCR semantic library (lib/) — meaning, authoritative                    │
│   A01_Render/Volcano · A01_Render/{Material,Particle,Light}              │
│   202_Math/Noise · 801_Spatial (frames) · 804_Application                │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │ contracts consumed by semantic ID
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Mojo simulation core — src/mojo/                                        │
│   + sim/volcano.mojo: VolcanoSubject (lake level, emissive, crust,       │
│     effusion state, seeded) + plume emission params                     │
│   owns: night-factor glow derivation (from AtmosphereSubject)           │
│   output: RenderSnapshot (schema 2: + VOLCANO, + PLUME)                 │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │ C ABI (.so) — unchanged symbol set
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Provider: providers/render/graphics/godot/adapter/                      │
│   decode sections 7/8 → update lava material emission,                  │
│   GPUParticles3D emitter params, OmniLight3D energy                     │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Godot application — godot/                                              │
│   island.tscn + scr_plume (GPUParticles3D), scr_crater_glow,            │
│   shaders/lava.gdshader (emissive crust pattern — display only)         │
└─────────────────────────────────────────────────────────────────────────┘
```

Data-flow rules (down/up/single channel/single process) and the fixed-timestep
model carry forward unchanged from 0002 §3.3–§3.4 (60 Hz, dt clamp, headless
byte-identical determinism).

### 3.2 Payload sections after this milestone

| Section | Content | Consumed by |
|---|---|---|
| 1–6 | unchanged (PLAYER, TERRAIN_META, TERRAIN, OCEAN, SKY, MATERIALS) | as 0002 §3.2 |
| **7 VOLCANO** (32 bytes, locked layout) | `center_x, center_z, radius, lake_level, emissive_intensity, crust_fraction, glow_intensity` (7×f32) + `effusion_state` (u8: 0 dormant, 1 effusing) + 3 pad bytes | lava material (emission energy), crater glow light |
| **8 PLUME** (32 bytes, locked layout) | `origin_x, origin_y, origin_z, rate, initial_velocity, spread, turbulence, lifetime` (8×f32 — if `rate == 0` the emitter is idle) | `scr_plume` GPUParticles3D emitter parameters |

MATERIALS already carries `fluid.lava` (emissive) — catalog derivation
unchanged (AP-3).

### 3.3 Determinism additions

- `VolcanoSubject` effusion transitions draw from a PRNG stream initialized
  from `World.seed` at init (fixed draw schedule: once per `EFFUSION_TICK_STEP`
  ticks). Same seed + same inputs ⇒ identical `VOLCANO`/`PLUME` bytes.
- `glow_intensity = emissive_intensity · night_factor(sun_elevation)` with
  `night_factor` a pure function of the existing `AtmosphereSubject`
  (deterministic projection, no wall clock).

### 3.4 Scene binding (adapter groups added)

| Group | Node | Section | Applied as |
|---|---|---|---|
| `scr_crater_lava` | `MeshInstance3D` + `ShaderMaterial` | `7 VOLCANO` | lake surface transform (center/radius), emission energy = `emissive_intensity`, crust fraction uniform |
| `scr_plume` | `GPUParticles3D` | `8 PLUME` | emitter position, `amount`/`emitting` from rate, initial velocity magnitude, spread, turbulence amount, lifetime |
| `scr_crater_glow` | `OmniLight3D` | `7 VOLCANO` | `light_energy = glow_intensity` |

Absent groups tolerated (presentation absent), mistyped nodes reported and
skipped — same policy as 0002 §5.

### 3.5 Schema evolution (this milestone)

- `SCR_SIM_SCHEMA_VER`: **1 → 2** (sim `parameters.mojo::SCHEMA_VERSION`,
  envelope byte, `scr_godot_abi.h` `SCR_SIM_SCHEMA_VER`, adapter check).
- Golden fixture `tests/fixtures/snapshot_seed1_tick1.bin` regenerated via
  `tests/mojo/gen_golden_fixture.mojo`.
- `tests/schema_mismatch_test.c` stub updated to report
  `SCR_SIM_SCHEMA_VER + 1` (so future bumps do not silently break the
  negative test — the 0002 stub hard-codes `2`).
- **Sibling rebasing rule (applies to all three specs):** milestones 0003 /
  0004 / 0005 are **independent siblings** under 0002. Whichever executes
  later MUST rebase on the then-current schema, fixture, adapter, and contract
  state (its own "+1 over then-current" bump), not on the layouts written here.

---

## 4. Semantic Library Consumption

Consumption is **by semantic ID** per `lib/README.md`; every path below was
verified to exist.

| Domain / ID | Concept consumed | Consumption mode |
|---|---|---|
| `SCR-LIB-RENDER-VOLCANO` (`lib/A01_Render/Volcano`) | Two scopes: (1) lava radiance = crust-factor blend of core `(1.0,0.72,0.12)` and crust `(0.12,0.04,0.02)` emission colors, `C(u,v,t)∈[0,1]`; (2) plume kinematics `w(z) = w0·((z−z0)/H_ref)^(−1/3)`, `R(z) = R0 + α(z−z0) + β·sin(ωt+kz)`, `w0 ≈ 8.5 m/s`, `α ≈ 0.28`, billow extinction `ρ ∝ exp(−‖x⊥−c‖²/2R²)·FBM(x − v_wind·t)` | **Spec-only contract — implement in Mojo per definition** (core subset: crater lake scalars + plume emission parameters). Out of scope here: Bingham flow/rivers, crust tearing field, vortex-curl advection, wind-advected ash dispersion |
| `lib/A01_Render/Particle` | Directory inventory only — its own definition states "no substantive implementation" and "no additional semantic contract is inferred from the directory's existence" | **No semantics consumed.** `GPUParticles3D` choice (§1.1) is a provider implementation decision, recorded as such |
| `lib/A01_Render/Light` | Directory inventory only (same honesty note as Particle) | **No semantics consumed.** Crater glow light is a presentation node fed by the sim-computed `glow_intensity` |
| `SCR-LIB-RENDER-MATERIAL` (`lib/A01_Render/Material`) | Catalog entries `fluid.lava`, `rock.obsidian`, `mineral.sulfur`, `mineral.ash`; reactions doc `material_reactions.json` → `reaction.lava_water_quench` (`thermal_phase_change`: primary `fluid.lava` + adjacent `fluid.water`, `face_sharing_6_neighborhood`; source block → `rock.obsidian` / non-source → `rock.cobblestone`, byproduct `fluid.steam`, 15000/8000 J, conservations `mass_conservation`, `enthalpy_dissipation`) | Catalog loaded repo-relative (AP-3). Quench: **documented partial** — reaction recorded as consumed; voxel evaluator lands in milestone 0005 (AP-14). No lava↔water adjacency exists in the current island, so no quench fires this milestone |
| `SCR-LIB-MATH-NOISE` (`lib/202_Math/Noise`) | Deterministic, seed-dependent, spatially coherent noise (spec-only) | Plume turbulence parameter evolution in sim (deterministic); crust tearing *pattern* + particle jitter = display-only noise (documented) |
| `lib/801_Spatial` frames | Position = value + reference frame; `SPATIAL-INV-002` | Plume emitter origin is an explicit world-frame position from the CALDERA_LAKE terrain columns; Godot node transforms = representation |
| `lib/804_Application` | Port → Adapter → Provider layering | Binding architecture conforms (§3); adapter decodes only |

**Known spec-only gaps:** `A01_Render/Volcano`, `A01_Render/Particle`,
`A01_Render/Light` have definitions/inventories but no lib code — implement the
contract in Mojo per definition, record deviations, never silently redefine.

---

## 5. Deliverables & Sprint Breakdown

```text
applications/godot/
├── src/mojo/
│   ├── sim/volcano.mojo                    # NEW — VolcanoSubject, seeded effusion, plume params, glow
│   ├── sim/subjects.mojo                   # EXTEND — night-factor helper over AtmosphereSubject
│   ├── sim/parameters.mojo                 # EXTEND — volcano/plume/glow tunables (AP-7), SCHEMA_VERSION → 2
│   ├── sim/world.mojo                      # EXTEND — own VolcanoSubject, commit it
│   ├── snapshot/types.mojo                 # EXTEND — VOLCANO, PLUME section structs
│   ├── snapshot/encode.mojo                # EXTEND — encode sections 7/8; envelope schema 2
│   └── snapshot/decode.mojo                # EXTEND — decode; reject schema ≠ 2 loudly
├── godot/
│   ├── scenes/island.tscn                  # EXTEND — scr_crater_lava, scr_plume (GPUParticles3D), scr_crater_glow (OmniLight3D)
│   ├── scripts/                            # unchanged (input passthrough only, AP-8)
│   └── shaders/lava.gdshader               # NEW — emissive lava surface; crust spatial pattern display-only
├── tests/mojo/
│   ├── test_volcano.mojo                   # NEW — subject determinism, effusion sequence, ranges, glow semantics
│   ├── test_determinism.mojo               # EXTEND — VOLCANO/PLUME bytes in byte-identity check
│   ├── test_envelope.mojo                  # EXTEND — section 7/8 framing + malformed rejection
│   └── gen_golden_fixture.mojo             # RUN — regenerate fixture (schema 2)
├── tests/
│   ├── abi_smoke.py                        # EXTEND — VOLCANO/PLUME decode checks
│   ├── schema_mismatch_test.c              # EXTEND — stub reports SCR_SIM_SCHEMA_VER + 1
│   ├── fixtures/snapshot_seed1_tick1.bin   # REGENERATED (schema 2)
│   └── godot/godot_screenshot.sh|.gd       # EXTEND — plume/crater capture assertions
├── docs/04_simulation_engine.md            # EXTEND — volcano subject, groups, parameters, gaps
├── docs/06_roadmap.md                      # EXTEND — 0003 status
└── program_increments/v0.0.1/milestone_0003_volcano/spec.md   # this file

providers/render/graphics/godot/
├── 104_contract.md                         # EXTEND — schema 2, sections 7/8, parameter mirror
├── 102_status.yaml / 103_provider.graph.json  # EXTEND
└── adapter/scr_godot_adapter.cpp, scr_godot_abi.h  # EXTEND — SCR_SIM_SCHEMA_VER 2, apply_* for 7/8
```

### Sprint 01 — Volcano semantic core (Mojo)

- `VolcanoSubject` (lake level, emissive intensity, crust fraction, effusion
  state) + plume emission parameters; seeded effusion schedule; night-factor
  glow from `AtmosphereSubject`.
- Parameters table entries (`LAVA_EMISSIVE_*`, `PLUME_RATE_*`,
  `PLUME_VELOCITY`, `GLOW_NIGHT_*`, `EFFUSION_TICK_STEP`).
- Tests: `test_volcano.mojo` (determinism of subject across two seeded runs,
  effusion sequence golden for seed 1, glow = 0 with sun up / > 0 at night),
  existing 7 spec-test files still green.

### Sprint 02 — Snapshot & contract (schema 2)

- `VOLCANO`/`PLUME` types + pure projection (purity test extended) + encode.
- Envelope `schema_version = 2`; `104_contract.md` §4 gains sections 7/8.
- Golden fixture regenerated; `test_envelope.mojo`, `abi_smoke.py` extended;
  mismatch stub updated to `SCR_SIM_SCHEMA_VER + 1`.

### Sprint 03 — Adapter & scene

- Adapter: `SCR_SIM_SCHEMA_VER 2`, decode + apply groups `scr_crater_lava`,
  `scr_plume`, `scr_crater_glow`; emission enable via the existing
  `set_feature(FEATURE_EMISSION, ·)` path.
- `island.tscn`: crater lava mesh + `lava.gdshader`, `GPUParticles3D` plume
  (sim-driven emitter params; no engine-side wind), `OmniLight3D` crater glow.
- AP-1 gate + headless load + screenshot gates rerun.

### Sprint 04 — Docs & verification

- `docs/04` (subject table, scene↔state rows, parameter table, §9 quench gap),
  `docs/06` roadmap row, `104_contract.md` finalized normative for schema 2.
- Full gate run (§7), anti-pattern review item-by-item (0002 §2.1 + §2.1 here).

---

## 6. Formal Invariants

Carried from [0002 §6](../milestone_0002_scene-initiation/spec.md) (authority,
single-channel, projection purity, engine isolation, catalog, path,
conformance, determinism, honesty) — **unchanged and normative**.

1. **Scope amendment:** 0002 invariant 10 is lifted *only* for lava/plume/
   crater-glow features defined here. Weather, vegetation, fauna, multi-biome,
   IPC remain out of scope (§9).
2. **Seed invariant:** effusion state, plume parameters, and glow are pure
   functions of `(seed, simulation_tick, world state)` — no wall clock, no
   unseeded RNG (AP-12).
3. **Single-authority invariant:** no lava/plume *state* is derived in
   Godot/shader/adapter; display may add spatial patterns and particle
   integration only (AP-11).
4. **Schema invariant:** any change to snapshot byte layout bumps
   `SCR_SIM_SCHEMA_VER`, regenerates the golden fixture, and updates adapter +
   negative test in the same sprint (AP-13).
5. **Reaction honesty invariant:** `lava_water_quench` is consumed only to the
   extent implemented; partial status recorded in the consumption table and
   `docs/04` §9 — never implied as working (AP-14).

---

## 7. Exit Criteria

All commands run from repo root. Every criterion is an automated test or a
documented procedure with commands.

- [ ] **Spec tests green:** `.venv/bin/mojo run -I applications/godot/src/mojo applications/godot/tests/mojo/test_volcano.mojo` PASS, and the existing 7 spec-test files (determinism, projection_purity, envelope, synthesis_conformance, gerstner, catalog, golden_fixture) still PASS.
- [ ] **Schema bump verified:** `scr_sim_schema_version() == 2` (abi_smoke) and envelope `schema_version == 2`; `tests/fixtures/snapshot_seed1_tick1.bin` regenerated (`gen_golden_fixture.mojo`) and `test_golden_fixture.mojo` PASS.
- [ ] **Contract decode + negative:** `python3 applications/godot/tests/abi_smoke.py` PASS including VOLCANO/PLUME field checks; `bash applications/godot/tests/test_schema_mismatch.sh` PASS (stub refuses `SCR_SIM_SCHEMA_VER + 1`, accepts real lib).
- [ ] **Determinism incl. volcano:** headless N-tick run, seed 1, scripted inputs ⇒ byte-identical snapshot sequence including sections 7/8 (`test_determinism.mojo`).
- [ ] **Projection purity:** world fingerprint unchanged across projection (`test_projection_purity.mojo`).
- [ ] **Glow semantics test:** `test_volcano.mojo` asserts `glow_intensity == 0` for sun above horizon and `> 0` below (no manual check needed).
- [ ] **Headless load:** `bash applications/godot/tests/godot/godot_load_test.sh` PASS (0 `ERROR:` lines).
- [ ] **Plume + lava rendered:** `bash applications/godot/tests/godot/godot_screenshot.sh` PASS (luminance thresholds as in `04` §8) **plus** plume presence: documented extension of `godot_screenshot.gd` asserting non-sky pixels in the crater-above column (region check around the caldera center); fallback documented manual capture in the script header (same pattern as 0002).
- [ ] **Night crater glow (manual, documented):** procedure in `docs/04` — set `TIME_OF_DAY_START_HOURS = 21.0` in `src/mojo/sim/parameters.mojo`, regenerate fixture, `bash applications/godot/scripts/build_godot_provider.sh`, `bash applications/godot/tests/godot/godot_screenshot.sh`, capture `build/island.png`, confirm crater glow spot above terrain luminance background, then revert parameter and regenerate fixture. Exact commands recorded in `docs/04` §8.
- [ ] **Layout gates:** `bash applications/godot/scripts/check_layout.sh` PASS (AP-1 engine-free `src/mojo/`, AP-4 no absolute paths).
- [ ] **Catalog:** `test_catalog.mojo` PASS (lava/ash/sulfur/obsidian ids derivable from `materials_catalog.json`).
- [ ] **Docs:** `04` (subject/groups/params/gap), `06`, `104_contract.md` schema 2 updated.
- [ ] **Anti-pattern review:** 0002 §2.1 AP-1..AP-10 + this spec §2.1 AP-11..AP-14 checked item-by-item against the diff, evidence recorded in `docs/04` §8.

---

## 8. Dependencies

- **Predecessor:** [milestone 0002](../milestone_0002_scene-initiation/spec.md) (Complete) — snapshot schema 1, adapter, scene, gates.
- **Semantic contracts:** `lib/A01_Render/Volcano`, `lib/A01_Render/{Particle,Light,Material}`, `lib/202_Math/Noise`, `lib/801_Spatial`, `lib/804_Application`.
- **Normative reference:** `providers/render/graphics/godot/104_contract.md` (schema 1 → 2 in this milestone).
- **Sibling:** [milestone 0004](../milestone_0004_atmosphere-weather/spec.md), [milestone 0005](../milestone_0005_shoreline-fidelity/spec.md) — independent; rebase rule §3.5.
- **External toolchain:** unchanged from 0002 (Mojo 1.0.0, Godot 4.7.2, godot-cpp).

---

## 9. Out of Scope

- Wind-advected plume / ash dispersion — requires wind vector ([milestone 0004](../milestone_0004_atmosphere-weather/spec.md)); hook in §10.
- `lava_water_quench` voxel evaluator, lava flows reaching the sea, steam volume effects — [milestone 0005](../milestone_0005_shoreline-fidelity/spec.md) §sub-slice (c) + TBD.
- Ash-fall deposition on terrain/water, tephra accumulation — `TBD — future milestone`.
- Eruption events (explosive onset, column collapse, ejecta) — `TBD — future milestone` (Rule 10: no event semantics defined yet).
- Full Bingham-fluid lava rheology, crust tearing field dynamics, vortex-curl billow advection (`SCR-LIB-RENDER-VOLCANO` §2) — spec-only, deferred.
- Weather, atmosphere scattering, precipitation — milestone 0004.
- Vegetation/fauna/editing/IPC — unchanged successors (0002 §9).

---

## 10. Successor Milestones

| Intent | Triggering contracts | Fulfilled by |
|---|---|---|
| Shoreline foam + crater material blending + quench evaluator | `A01_Render/Water`, `801_Spatial/Voxel/Synthesis`, `material_reactions.json` (`lava_water_quench`) | [milestone 0005](../milestone_0005_shoreline-fidelity/spec.md) |
| Plume wind-drift, ash-fall display in weather | `503_Simulation/Environment/Weather` (wind vector), `202_Math/Atmosphere` | [milestone 0004](../milestone_0004_atmosphere-weather/spec.md) (wind) + plume drift hook post-0004 |
| Ash-fall deposition | `A01_Render/Volcano` (dispersion), `801_Spatial/Voxel/Synthesis` | `TBD — future milestone` |
| Eruption events | `A01_Render/Volcano` + event semantics (Rule 10) | `TBD — future milestone` |
| Ecology/vegetation reacting to ash | `705_Ecology`, `601_Agent` | `TBD — future milestone` |
