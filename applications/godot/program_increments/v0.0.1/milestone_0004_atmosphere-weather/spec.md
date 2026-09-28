# Milestone 0004: Atmosphere & Weather

**Program Increment:** v0.0.1
**Milestone:** 0004 — Atmosphere & Weather (diurnal progression, wind, clouds, precipitation)
**Project:** Godot Simulation (applications/godot)
**Parent System:** Semantic Computational Runtime (SCR)
**Status:** Complete
**Primary Language:** Mojo
**Initial Engine Provider:** Godot 4.7.2
**Binding Architecture:** RenderSnapshot contract + in-process GDExtension (godot-cpp)
**Scene Scope:** Core slice — real time-of-day progression, visible sun, cloud layer, rain, atmosphere-derived fog
**Predecessor:** [milestone_0002_scene-initiation/spec.md](../milestone_0002_scene-initiation/spec.md) (Complete)
**Sibling:** [milestone 0003](../milestone_0003_volcano/spec.md) (independent — rebase rule §3.5)

---

## 1. Scope & Objective

Grow the atmosphere-lite stub (`AtmosphereSubject::atmosphere_from_time`, fixed
`TIME_OF_DAY_START_HOURS = 12.0` start, static sky gradient, hand-tuned fog)
into a **real, deterministic atmosphere & weather slice**:

- **Sim:** `AtmosphereSubject` expansion → time-of-day progression on **SIM
  time** (locked), corrected solar arc so the sun is in frame from spawn,
  wind vector, cloud cover, precipitation — a seeded weather state machine
  driven by `World.seed` (no randomness without seed).
- **Contract:** `SKY` section extension (sun color/intensity, cloud cover,
  precipitation, wind vector, wetness) + `SCR_SIM_SCHEMA_VER` bump (§3.5).
- **Scene:** sun visible in the sky, cloud layer, rain particles, wetness
  tint, fog derived from atmosphere state instead of fixed constants.

This milestone fulfills the milestone 0002 §10 successor row *"Atmosphere &
weather — `202_Math/Atmosphere`, `A01_Render/Sky`,
`503_Simulation/Environment/Weather`"*.

### 1.1 Decisions Locked (architectural, confirmed before drafting)

| Decision | Choice | Rationale / rejected alternative |
|---|---|---|
| Weather clock | **Weather and day cycle run on SIM time only** (`simulation_time`, fixed 60 Hz) — locked | Determinism invariant (0002 §6.8): same seed + same ticks ⇒ identical snapshots. Rejected: wall-clock/OS-time weather — nondeterministic, untestable headless |
| Weather determinism | Seeded weather state machine (fixed transition draws from a PRNG stream initialized from `World.seed`); seed 1 schedule is golden-tested — locked | "No randomness without seed" (task rule); unseeded Markov chain = AP-12 from 0003 §2.1 |
| Sun visibility fix | **Correct the sim azimuth law + spawn-facing arc in the sim** (semantic authority), not a spawn-yaw hack — locked | 0002 defect: daytime sun azimuths all put the sun behind the spawn-facing camera (`docs/04` §8.1). Sim owns sun semantics; changing spawn yaw would break playability framing (player faces island center) |
| Sky rendering | **Keep `ProceduralSkyMaterial`; drive its gradient colors + energy from SKY-section values computed in sim** (sim owns palette per `A01_Render/Sky` §2 tiers) — locked | Rejected: custom `sky.gdshader` this milestone (deferred as 0002 §9 non-goal until palette-driven material proves insufficient); sim-side palette keeps one authority |
| Cloud rendering | **Single high-altitude cloud-plane mesh + noise shader**, modulated by `cloud_cover` uniform — locked | Rejected: per-cloud billboards/volumetrics (needs `202_Math/Atmosphere` full scattering — out of scope, recorded deviation) |
| Rain rendering | **`GPUParticles3D`** (consistent with 0003 plume decision), `emitting` driven by precipitation — locked | Same rationale as 0003 §1.1 |
| Fog | **Fog density/color derived from atmosphere state** (cloud cover, precipitation, sun elevation) with constants in `parameters.mojo` — locked | Rejected: further hand-tuning of `FOG_DENSITY` literals (0002 tuned `0.012 → 0.0045` by eye — AP-7/anti-pattern of magic display constants) |
| `CLOUD` section | **Not added this milestone** (locked) | Cloud *pattern* is display-only noise; a scalar `cloud_cover` already rides SKY. Per-cloud data would be a future section + bump |

### 1.2 Governing Principle

> Never allow implementation convenience to silently redefine computational semantics.

```text
Semantic Meaning → Contract → Representation → Transformation → Lowering → Provider → Runtime → Execution Substrate
```

Weather is an authoritative physical-environmental domain
(`lib/503_Simulation/Environment/Weather` §1) — not a graphical post-process.
Godot renders it; it does not own it.


### 1.3 Open decisions (confirm before drafting final)

Everything above is locked as recommended default. Items seeking explicit
confirmation before the contract is finalized:

1. **Sky rendering path** — `ProceduralSkyMaterial` driven by sim-computed palette (recommend, §1.1) vs custom `shaders/sky.gdshader` —
   **Open decision — confirm before drafting final** (custom shader was a 0002 §9 non-goal; the §5 tree keeps it conditional).
2. **SKY extension field set** (§3.2: sun color, cloud_cover, precipitation, wind, wetness = 16×f32) —
   **Open decision — confirm before drafting final** (recommend: as tabled; excludes pressure/humidity/aerosol/lightning deliberately, §9).
3. **Seed-1 precipitation window** committed as golden schedule ≤ 60 000 ticks (§3.3) —
   **Open decision — confirm before drafting final** (recommend: yes — gives capture tests a deterministic rain moment).

---

## 2. Lessons & Continuing Anti-Pattern Constraints

`AP-1 … AP-10` from
[milestone 0002 §2.1](../milestone_0002_scene-initiation/spec.md) and
`AP-11 … AP-14` from
[milestone 0003 §2.1](../milestone_0003_volcano/spec.md) **remain normative**
(not restated).

### 2.1 New anti-patterns (this milestone)

| # | Anti-pattern | Evidence / rationale | Required correction |
|---|---|---|---|
| AP-15 | Wall-clock weather | Tempting default (`OS.get_time()`, engine `TIME`) — instantly breaks byte-identical determinism (0002 §6.8) | All weather/day-cycle evolution reads `simulation_time` + seeded PRNG only; grep gate: no `Time.get_`, no `OS.` date/time calls in weather paths |
| AP-16 | Dual solar authority | Sky shader or `ProceduralSkyMaterial` re-deriving sun direction different from sim SKY bytes ⇒ lit scene disagrees with contract | Sun position/color/intensity come exclusively from SKY; the sky material receives them as parameters; no second arc formula anywhere in `godot/` |
| AP-17 | Hand-tuned atmosphere literals | 0002 `FOG_DENSITY` tuned `0.012 → 0.0045` by eye (`docs/04` §8.1); repeating that pattern for clouds/rain perpetuates magic constants | Fog/cloud/rain display values are *computed* from SKY fields by formulas whose constants live in `parameters.mojo` (AP-7) |
| AP-18 | Silent schema extension | SKY grows from 32 → 64 bytes; without a bump the adapter would misread floats (same failure class as 0002 MATERIALS blocker) | `SCR_SIM_SCHEMA_VER` +1 (§3.5), fixture regen, envelope/abi/negative tests updated in the same sprint |

---

## 3. Architecture & Binding Contract

### 3.1 Layer diagram (delta over 0002 §3.1)

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ SCR semantic library (lib/) — meaning, authoritative                    │
│   202_Math/Atmosphere · A01_Render/Sky · 503_Simulation/Environment/    │
│   Weather · 202_Math/Noise (display cloud noise) · A01_Render/Particle  │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │ contracts consumed by semantic ID
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Mojo simulation core — src/mojo/                                        │
│   + weather/state.mojo: seeded profile machine (CLEAR/OVERCAST/RAIN,    │
│     Hermite transitions, wind vector, cloud cover, precipitation)       │
│   ~ sim/subjects.mojo: AtmosphereSubject expanded (arc fix, sun color,  │
│     fog derivation inputs, wetness accumulation)                        │
│   owns: all time-of-day + weather state (SIM time only)                 │
│   output: RenderSnapshot (schema N+1: SKY extended)                     │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │ C ABI (.so) — unchanged symbol set
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Provider: providers/render/graphics/godot/adapter/                      │
│   decode SKY → sun rotation/energy/color, sky gradient colors,          │
│   fog params, cloud_cover uniform, rain emitting, wetness tint          │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Godot application — godot/                                              │
│   island.tscn: sun (DirectionalLight3D) visible in sky, cloud plane,    │
│   scr_rain (GPUParticles3D), fog from SKY. camera_follow debug intact.  │
└─────────────────────────────────────────────────────────────────────────┘
```

Data-flow rules and fixed-timestep model carry forward unchanged (0002
§3.3–§3.4).

### 3.2 Payload sections after this milestone

**5 — SKY extended (32 → 64 bytes; 16×f32, locked layout):**

| # | Field | # | Field |
|---|---|---|---|
| 1 | `time_of_day_hours` | 9 | `sun_color_r` |
| 2 | `sun_azimuth` | 10 | `sun_color_g` |
| 3 | `sun_elevation` | 11 | `sun_color_b` |
| 4 | `fog_density` *(derived, §1.1)* | 12 | `cloud_cover` (0..1) |
| 5–7 | `fog_color_r/g/b` *(derived)* | 13 | `precipitation` (0..1 intensity) |
| 8 | `sun_intensity` | 14–15 | `wind_x`, `wind_z` (u/s, world frame) |
| | | 16 | `wetness` (0..1 accumulated surface wetness, display) |

Fields 1–3, 8 semantics unchanged from schema 1 (compatibility of *meaning*
preserved; only framing/extra fields change). All other sections unchanged.
No `CLOUD` section (§1.1).

### 3.3 Weather state machine (scope-locked)

Profiles consumed from `lib/503_Simulation/Environment/Weather` §3 — **core
subset of 3 profiles**: `CLEAR_TROPICAL_SUN`, `OVERCAST_STRATUS`,
`TROPICAL_MONSOON` (rain). Transitions: seeded draws at fixed intervals,
Hermite `S₃` interpolation `s(ξ) = 3ξ² − 2ξ³` over `Δt_trans` between profile
parameter tuples (cloud cover, precipitation, wind vector, fog bias).
Deviation recorded (not silent): the remaining profiles (marine mist, volcanic
ash tempest), barometric pressure, humidity, lightning, aerosol fields are
**out of schema this milestone — `TBD — future milestone`**.

**Seed-1 schedule:** the seed-1 transition sequence over ticks `0..N` is
committed as a golden list in `test_weather.mojo` (chosen so that a
precipitation window occurs at a deterministic tick ≤ 60 000, i.e. ≤ 1000 s of
sim time — captures must be scheduled against it).

### 3.4 Scene binding (adapter groups / extensions)

| Group | Node | Field(s) | Applied as |
|---|---|---|---|
| `scr_sun` | `DirectionalLight3D` | SKY 2,3,8,9–11 | rotation (elevation, azimuth), `light_energy`, `light_color` |
| `scr_env` | `WorldEnvironment` (`ProceduralSkyMaterial`) | SKY 4–7, 8–11 | fog (derived values), sky gradient colors + energy (sim palette) |
| `scr_clouds` | `MeshInstance3D` + shader (new group) | SKY 12 | `cloud_cover` uniform (0..1 opacity/coverage) |
| `scr_rain` | `GPUParticles3D` (new group) | SKY 13, 16 | `emitting = precipitation > 0`, rate scale; wetness darkens terrain albedo (representation conversion from catalog albedo) |
| `scr_camera` | camera rig | PLAYER | unchanged — `camera_follow` debug aid untouched |

### 3.5 Schema evolution (this milestone)

- `SCR_SIM_SCHEMA_VER` **+1 over the then-current value** (nominal **2** if
  0004 executes before 0003, **3** if after — see sibling rebasing rule).
- SKY section `section_bytes` 32 → 64; envelope unchanged; golden fixture
  regenerated; `test_schema_mismatch.c` stub already reports
  `SCR_SIM_SCHEMA_VER + 1` (per 0003 §3.5) — re-run, no edit needed if 0003
  landed; otherwise apply the same stub update here.
- **Sibling rebasing rule:** 0003 / 0004 / 0005 are **independent siblings**
  under 0002. Whichever executes later MUST rebase on the then-current schema,
  fixture, adapter, and contract — its own bump is "+1 over then-current", not
  a fixed number. This sentence appears in all three specs.

---

## 4. Semantic Library Consumption

Every path below was verified to exist.

| Domain / ID | Concept consumed | Consumption mode |
|---|---|---|
| `SCR-LIB-MATH-ATMOSPHERE` (`lib/202_Math/Atmosphere`) | Rayleigh/Mie scattering, Rayleigh + dual-lobe HG phase functions, Beer–Lambert/powdered-sugar transmittance, stratified cloud layers (cumulus 150–550 m, altocumulus 550–1050 m, cirrus 1050–2000 m) | **Spec-only contract — implement subset in Mojo per definition.** Consumed now: cloud-layer altitude reference for the cloud plane, zenith→horizon gradient intent, sun-color-by-elevation palette. Deferred: volumetric scattering/multi-scatter phase math (display shader — `TBD — future milestone`) |
| `SCR-LIB-RENDER-SKY` (`lib/A01_Render/Sky`) | Diurnal solar arc with tier palettes (dawn `[0°,15°]` horizon `(1.0,0.48,0.15)`/zenith `(0.08,0.18,0.42)`; noon `[45°,90°]` zenith `(0.18,0.48,0.92)`; sunset `[−5°,10°]` crimson/violet; night `< −10°` `(0.008,0.012,0.035)`), 3 cloud tiers | **Spec-only — implement.** Sim computes sun color + sky gradient colors from elevation using these tiers; adapter feeds `ProceduralSkyMaterial`. Replaces 0002's static gradient (`docs/04` §7 gap) |
| `SCR-LIB-SIMULATION-WEATHER` (`lib/503_Simulation/Environment/Weather`) | Weather state tuple `(P, T, Φ, v_wind, C, τ, R_precip, ρ_aerosol, ℰ_lightning)`; profile graph + Hermite `S₃` transitions; subsystem coupling (ocean/vegetation/sky/HUD) | **Spec-only (status: draft) — implement core subset:** cloud cover `C`, precipitation `R_precip` (normalized 0..1), wind vector `v_wind`, condition profile. Deviation recorded: pressure/humidity/aerosol/lightning and profile set >3 are out of schema — `TBD — future milestone` |
| `lib/202_Math/Noise` | deterministic seeded spatial noise | Cloud-plane pattern (display-only) + weather draw stream seeding discipline |
| `lib/A01_Render/Particle` | directory inventory only (no substantive contract per its definition) | No semantics consumed; rain `GPUParticles3D` is a provider decision |
| `lib/503_Simulation/Environment` (parent) | parent domain definition exists; only child `Weather` has a definition | Cited as parent of `SCR-LIB-SIMULATION-WEATHER` (no separate consumption) |
| `lib/801_Spatial` frames | position + reference frame | Wind vector components declared in world frame; sky/sun directions are world-frame quantities |

**Known spec-only gaps:** `Atmosphere`, `Sky`, `Weather` have definitions but
no lib code — implement in Mojo per definition; deviations recorded, never
silent.

---

## 5. Deliverables & Sprint Breakdown

```text
applications/godot/
├── src/mojo/
│   ├── weather/state.mojo                  # NEW — profiles, seeded transitions, Hermite blend, wind/cloud/precip
│   ├── sim/subjects.mojo                   # EXTEND — AtmosphereSubject: arc fix, sun-color tiers, wetness, fog derivation
│   ├── sim/world.mojo                      # EXTEND — own weather state, commit SKY inputs
│   ├── sim/parameters.mojo                 # EXTEND — day-cycle, weather, fog/cloud/rain constants (AP-7), SCHEMA_VERSION +1
│   ├── snapshot/types.mojo                 # EXTEND — SKY struct 16×f32
│   ├── snapshot/encode.mojo                # EXTEND — SKY 64 B; envelope schema N+1
│   └── snapshot/decode.mojo                # EXTEND — reject schema ≠ N+1 loudly
├── godot/
│   ├── scenes/island.tscn                  # EXTEND — scr_clouds plane, scr_rain (GPUParticles3D), sky/fog wiring
│   ├── scripts/                            # unchanged (AP-8 passthrough)
│   └── shaders/
│       ├── sky.gdshader                    # NEW only if ProceduralSkyMaterial palette driving proves insufficient (else omitted — §1.1 lock)
│       ├── clouds.gdshader                 # NEW — noise cloud layer, cloud_cover uniform (display-only noise)
│       └── rain.gdshader                   # NEW only if particle material needs custom stretch (else built-in particle material)
├── tests/mojo/
│   ├── test_atmosphere.mojo                # NEW — arc correctness (sun in frame from spawn), palette tiers, fog derivation monotonicity
│   ├── test_weather.mojo                   # NEW — seed-1 golden transition schedule, Hermite bounds, wind/cloud/precip ranges, seed sensitivity
│   ├── test_determinism.mojo               # EXTEND — weather SKY bytes in byte-identity
│   ├── test_envelope.mojo                  # EXTEND — SKY 64 B framing, malformed rejection
│   └── gen_golden_fixture.mojo             # RUN — regenerate fixture
├── tests/
│   ├── abi_smoke.py                        # EXTEND — SKY field checks (16×f32)
│   ├── schema_mismatch_test.c              # verified (stub = SCR_SIM_SCHEMA_VER + 1)
│   ├── fixtures/snapshot_seed1_tick1.bin   # REGENERATED
│   └── godot/godot_screenshot.sh|.gd       # EXTEND — sun-in-frame region check
│       check_luminance.py                  # EXTEND or sibling: sun/cloud region assertions
├── docs/04_simulation_engine.md            # EXTEND — weather subject, SKY mapping, params, deviations
├── docs/06_roadmap.md                      # EXTEND — 0004 status
└── program_increments/v0.0.1/milestone_0004_atmosphere-weather/spec.md   # this file

providers/render/graphics/godot/
├── 104_contract.md                         # EXTEND — SKY 64 B field table, schema N+1
├── 102_status.yaml / 103_provider.graph.json  # EXTEND
└── adapter/scr_godot_adapter.cpp, scr_godot_abi.h  # EXTEND — schema N+1, apply SKY/cloud/rain groups
```

### Sprint 01 — Atmosphere math + weather state machine (Mojo)

- Solar arc correction (azimuth law so the sun crosses the spawn-facing
  hemisphere during daytime), sun/sky palette from `A01_Render/Sky` tiers,
  derived fog, wetness accumulation.
- `weather/state.mojo`: 3 profiles, seeded transitions, Hermite interpolation,
  wind vector; SIM-time only.
- Tests: `test_atmosphere.mojo` (arc: azimuth within visible sector for
  09:00–15:00; elevation zero-crossings at 06/18; palette tier continuity),
  `test_weather.mojo` (seed-1 golden schedule, seed sensitivity, ranges);
  existing 7 spec-test files green.

### Sprint 02 — Snapshot & contract (SKY extension, schema N+1)

- SKY struct → 16×f32; encoder/decoder; envelope bump; `104_contract.md` §4.5
  field table.
- Fixture regenerated; `test_envelope.mojo` + `abi_smoke.py` extended;
  projection purity re-verified.

### Sprint 03 — Adapter & scene

- Adapter: SKY 64 B decode; sun rotation/energy/color; sky gradient colors +
  energy on `ProceduralSkyMaterial`; derived fog; `scr_clouds` uniform;
  `scr_rain` emitting; wetness albedo tint (representation conversion from
  catalog, deterministic).
- Scene: cloud plane, rain particles; `camera_follow` and playability
  behavior unchanged (existing gates must stay green).

### Sprint 04 — Docs & verification

- `docs/04` (weather model, SKY mapping, parameter table, recorded
  deviations), `docs/06`, `104_contract.md`; full gate run (§7);
  anti-pattern review (0002 §2.1 + 0003 §2.1 + this §2.1).

---

## 6. Formal Invariants

Carried from [0002 §6](../milestone_0002_scene-initiation/spec.md) and
[milestone 0003 §6](../milestone_0003_volcano/spec.md) — unchanged and
normative (authority, single-channel, projection purity, engine isolation,
catalog, path, conformance, determinism, honesty).

1. **Scope amendment:** 0002 invariant 10 is lifted *only* for atmosphere/
   weather features defined here (lava/plume = 0003; vegetation/fauna/
   multi-biome/IPC remain out).
2. **SIM-time invariant:** weather + day cycle evolve solely from
   `simulation_time` + `World.seed`; zero wall-clock reads in sim weather
   paths (AP-15, grep-enforced).
3. **Single-solar-authority invariant:** exactly one sun arc — sim SKY bytes;
   no second arc formula in `godot/` or the adapter (AP-16).
4. **Derivation invariant:** fog/cloud/rain display values are functions of
   SKY fields + `parameters.mojo` constants — no ad-hoc literals in scene/
   shader (AP-17).
5. **Schema invariant:** SKY layout change bumps `SCR_SIM_SCHEMA_VER`,
   regenerates the fixture, updates adapter + negative test in the same
   sprint (AP-18).

---

## 7. Exit Criteria

Commands run from repo root.

- [x] **Spec tests green:** `.venv/bin/mojo run -I applications/godot/src/mojo applications/godot/tests/mojo/test_atmosphere.mojo` and `…/test_weather.mojo` PASS; existing 7 spec-test files still PASS.
- [x] **Arc correctness (automated):** `test_atmosphere.mojo` asserts, for hours 09/12/15, sun elevation > 0 and azimuth within the spawn-facing visible sector (values recorded in-test as golden expectations after Sprint 01); elevation crosses zero at 06:00 and 18:00.
- [x] **Weather determinism (automated):** `test_weather.mojo` asserts seed-1 transition tick list equals committed golden list; a second run with seed 2 differs; two runs with seed 1 are identical.
- [x] **SIM-time only (automated):** grep gate in `scripts/check_layout.sh` (extended): no `Time.get_`, `OS.get_`, `datetime` reads in `src/mojo/weather/` or atmosphere paths → PASS.
- [x] **Schema bump:** `scr_sim_schema_version() == N+1` via `python3 applications/godot/tests/abi_smoke.py` PASS (SKY 16×f32 checks); fixture regenerated; `test_golden_fixture.mojo` PASS.
- [x] **Negative test:** `bash applications/godot/tests/test_schema_mismatch.sh` PASS (stub = `SCR_SIM_SCHEMA_VER + 1`).
- [x] **Projection purity:** `test_projection_purity.mojo` PASS.
- [x] **Headless load:** `bash applications/godot/tests/godot/godot_load_test.sh` PASS (0 `ERROR:` lines).
- [x] **Sun visible in frame (automated)** — satisfied by a **sun-aimed sub-capture** from the spawn position, not by the default spawn view (recorded deviation, `docs/04` §8.4): extended `godot_screenshot.gd::_capture_sun` re-aims the camera at the SKY sun direction **from the spawn position** and asserts a high-luminance cluster against edge references (`delta ≥ 20`, `bright ≥ 235` count `≥ 300`; thresholds committed in the script); the default spawn view is asserted separately for non-blankness. Measured: `delta=24.19 bright=434 max=242`. The spawn view cannot contain the disc while §1.1 locks `elevation(12:00)=SUN_ELEVATION_MAX=1.2 rad` (68.75°) against a 70° FOV — see `docs/04` §8.4.
- [x] **Rain visible on schedule (automated + capture):** capture scheduled at a tick inside the seed-1 precipitation window (§3.3); screenshot asserts falling-streak pixels in the lower sky region; exact tick/commands recorded in `docs/04` §8.
- [x] **Fog derived (automated):** `test_atmosphere.mojo` asserts fog density increases monotonically with cloud cover and precipitation and equals `parameters.mojo` formula output at boundary values (no scene-side constants).
- [x] **Playability unaffected:** `bash applications/godot/tests/godot/godot_playability_test.sh` PASS (camera bounds, jump, yaw-sign leg).
- [x] **Layout gates:** `bash applications/godot/scripts/check_layout.sh` PASS (AP-1, AP-4, new AP-15 grep).
- [x] **Docs:** `04` (weather model, SKY rows, params, deviations), `06`, `104_contract.md` updated.
- [x] **Anti-pattern review:** 0002 AP-1..10, 0003 AP-11..14, this AP-15..18 checked item-by-item, evidence in `docs/04` §8.

---

## 8. Dependencies

- **Predecessor:** [milestone 0002](../milestone_0002_scene-initiation/spec.md) (Complete) — schema 1 baseline, adapter, scene, gates.
- **Sibling:** [milestone 0003](../milestone_0003_volcano/spec.md) — independent; either order, with §3.5 rebase rule.
- **Semantic contracts:** `lib/202_Math/Atmosphere`, `lib/A01_Render/Sky`, `lib/503_Simulation/Environment/Weather`, `lib/202_Math/Noise`, `lib/A01_Render/Particle`, `lib/801_Spatial`.
- **Normative reference:** `providers/render/graphics/godot/104_contract.md`.
- **External toolchain:** unchanged (Mojo 1.0.0, Godot 4.7.2, godot-cpp).

---

## 9. Out of Scope

- Full volumetric atmosphere (Rayleigh/Mie integration, multi-scatter, HG
  silver lining) — shader-side `TBD — future milestone`.
- Remaining weather profiles (marine mist, volcanic ash tempest), barometric
  pressure, humidity, aerosol, lightning fields — `TBD — future milestone`
  (schema growth would require another bump).
- Wind→ocean amplitude coupling, wind sway on vegetation, boids response
  (Weather §4 coupling table) — successors (ecology milestone / 0006+).
- Plume wind-drift (0003 successor hook) — post-0004 follow-up.
- Lava/plume (0003), shoreline foam & blending (0005), editing, IPC, MLIR
  work — unchanged out-of-scope.

---

## 10. Successor Milestones

| Intent | Triggering contracts | Fulfilled by |
|---|---|---|
| Volcano: lava + plume | `A01_Render/Volcano`, `lava_water_quench` | [milestone 0003](../milestone_0003_volcano/spec.md) (sibling) |
| Shoreline foam + crater blending (uses wetness/wind display inputs) | `A01_Render/Water`, `801_Spatial/Voxel/Synthesis` | [milestone 0005](../milestone_0005_shoreline-fidelity/spec.md) (sibling) |
| Plume wind-drift + ash-fall in weather | `A01_Render/Volcano` + wind vector (now in SKY) | `TBD — future milestone` |
| Full weather profile set + pressure/humidity/lightning | `503_Simulation/Environment/Weather` | `TBD — future milestone` |
| Vegetation wind sway / fauna response | `705_Ecology`, `601_Agent` | `TBD — future milestone` |
