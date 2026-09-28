# 04 — Simulation Engine Design

**Purpose:** Capture the simulation engine design for the Mojo/Godot application.
**Status:** Active (filled for milestone 0002 — Sprint 01..04; extended for milestone 0003 Volcano — Sprint 01..04; honest gaps marked `TBD — future milestone`)
**Owner milestone:** [v0.0.1 / milestone 0003 — Volcano](../program_increments/v0.0.1/milestone_0003_volcano/spec.md) (baseline: [milestone 0002](../program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md), [milestone 0001](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md))

---

## 1. Scope of This Document

| Topic | State |
|-------|-------|
| Workspace intent (Mojo = simulation semantics + kernels; Godot = host/provider) | Active — see [01_architecture.md](01_architecture.md) |
| Simulation domain model | **Active — §4.1** |
| Timestep / determinism model | **Active — §4.2** |
| Physics / field / agent semantics (core slice) | **Active — §4.1/§4.6; successors TBD** |
| State representation & serialization | **Active — §4.3 (104_contract.md)** |
| Mojo ↔ Godot data flow (binding protocol) | **Active — §4.3** |
| Headless execution mode | **Active — §7** |
| Scene graph ↔ semantic state mapping | **Active — §5** |
| Parameter table (AP-7, incl. volcano/plume/glow) | **Active — §6** |
| Performance budgets | **TBD — future milestone** (no perf work in scope; spec §9) |

## 2. Current Implementation (v0.0.1 / milestone 0003)

- `src/mojo/` — full core slice: `sim/` (world, subjects, parameters, input table, runtime, **volcano**), `synthesis/` (noise + height field + voxel synthesis), `ocean/` (Gerstner), `materials/` (catalog loader), `snapshot/` (pure projection + encoder), `export/` (C ABI), `main.mojo` (CLI headless entry).
- `godot/` — main scene `scenes/island.tscn` (terrain host, ocean + Gerstner shader, sky, sun, camera, HUD, meta/materials group nodes, **`scr_crater_lava` + `scr_plume` (GPUParticles3D) + `scr_crater_glow` (OmniLight3D)**), `scripts/player_input.gd` (input uplink only), `scripts/hud.gd` (controls hint only), `shaders/ocean.gdshader`, **`shaders/lava.gdshader`**.
- `providers/render/graphics/godot/` — provider control docs + GDExtension adapter (`ScrSim`), normative contract `104_contract.md` (**schema 2**).
- Tests: 8/8 Mojo spec test files, 47 tests (0003 adds `test_volcano.mojo`; see §4.4), ABI smoke, schema-mismatch negative test, headless load gate, screenshot gate (plume + lava + night-glow region checks), playability gate (see §8).

## 3. Constraints Carried Forward (normative, from governing docs)

1. Implementation convenience must not silently redefine computational semantics.
2. Godot is a provider; it does not own semantics ([05_provider_boundary.md](05_provider_boundary.md)).
3. MLIR is the sole canonical compiler IR; Mojo is the user-facing semantic API ([120](../../docs/120_SCR_Core_MLIR_Mojo_Relationship.md)).
4. Rule 9: do not invent missing foundational semantics. Rule 10: specify before implementing.

## 4. Design Sections

### 4.1 Domain Model

`World` (`src/mojo/sim/world.mojo`) owns commit metadata and four subjects:

| Subject | File | Owns |
|---|---|---|
| `IslandSubject` | `sim/island.mojo` | synthesized terrain (height field `grid_n × grid_n`, cell size, chunks), biome/material column assignment, spawn (beach band), peak height, `used_materials` |
| `PlayerSubject` | `sim/subjects.mojo` | feet position, velocity, yaw/pitch, `on_ground`, `in_water` — **all locomotion integration lives here** |
| `HydrologySubject` | `sim/subjects.mojo` + `ocean/gerstner.mojo` | Gerstner wave state (sea level, amplitude, wavenumber, steepness, direction, phase speed, phase offset) |
| `AtmosphereSubject` (lite) | `sim/subjects.mojo` | `atmosphere_from_time`: time-of-day hours, sun azimuth/elevation, sun intensity — pure projection of `simulation_time`; `night_factor(sun_elevation)` (0003 §3.3: glow = emissive × night_factor) |
| `VolcanoSubject` | `sim/volcano.mojo` (0003) | caldera center/radius, lake level, emissive intensity, crust fraction, effusion state machine (seeded, `EFFUSION_TICK_STEP` draws), plume parameters, glow intensity — pure function of `(seed, simulation_tick, atmosphere)`; `volcano_from_island` + `volcano_tick` driven from `world.mojo` |

Commit metadata on `World`: `seed`, `determinism_epoch`, `world_version` (bumps on regeneration), `state_generation` (every tick), `simulation_tick`, `simulation_time`.

**Semantic library consumption** (spec §4 table, by ID — not by comment, AP-2): `SCR-LIB-SPATIAL-VOXEL-SYNTHESIS` (biome→material table + bedrock/sea-level invariants, conformance-tested), `SCR-LIB-MATH-NOISE` (spec-only, implemented in `synthesis/noise.mojo`), `SCR-LIB-MATH-GERSTNER` (spec-only, implemented in `ocean/gerstner.mojo`), `SCR-LIB-FIELD` (height queries), `SCR-LIB-GEOMETRY` (mesh arrays are representation), `SCR-LIB-RENDER-MATERIAL` (catalog `lib/A01_Render/Material/materials_catalog.json`, repo-relative), `SCR-LIB-RENDER-WATER` (foam intent — see §4.6 deviation), `SCR-LIB-RENDER-SKY` (diurnal arc + gradient sky), `SCR-LIB-RENDER-VOLCANO` (0003: lava/plume/glow subject semantics in `sim/volcano.mojo`, spec-only parts deferred — §9), `SCR-LIB-SPATIAL` frames (world frame explicit; Godot transforms = representation), `SCR-LIB-PHYSICS` quantities/gravity (gravity constant), `lib/804_Application` (Port→Adapter→Provider layering).

### 4.2 Engine Architecture (step loop, state ownership)

- **Fixed timestep:** 60 Hz (`TICK_RATE_HZ`, `FIXED_DT = 1/60`). `scr_sim_step(dt, input*)` accumulates `dt` (frame delta from Godot physics) and runs 0..n fixed ticks; the frame delta is clamped to `FRAME_DT_CLAMP = 0.05 s` inside the sim (the adapter passes `delta` through untouched — `104_contract` §6).
- **Input application:** each executed tick consumes one `scr_input_batch` via a fixed-order dispatch table (`sim/input.mojo::build_input_table` — AP-5: table, not an if/else chain).
- **State ownership:** only `World` mutates. Projection (`snapshot/`) reads `World` and emits an immutable byte buffer — projection purity is test-enforced (`test_projection_purity.mojo`). The TERRAIN-emission tracker lives in `sim/runtime.mojo` *outside* `World`, so projection stays pure.
- **Determinism:** same seed + same input sequence + `dt = 1/60` per call ⇒ byte-identical snapshot sequence (`test_determinism.mojo`, golden fixture `tests/fixtures/snapshot_seed1_tick1.bin`, `test_golden_fixture.mojo`).

### 4.3 Provider Interface Contract (Mojo outputs → Godot inputs)

Normative spec: **[`providers/render/graphics/godot/104_contract.md`](../../providers/render/graphics/godot/104_contract.md)** (byte schema **v2**, C ABI, input batch, parameter table). Summary:

- **C ABI** (`src/mojo/export/abi.mojo`, header `adapter/scr_godot_abi.h`): `scr_sim_init(seed)`, `scr_sim_shutdown()`, `scr_sim_abi_version()` (=1), `scr_sim_schema_version()` (**=2**), `scr_sim_step(dt, input*)`, `scr_sim_snapshot_size()`, `scr_sim_snapshot_write(buf, cap)` — 7 symbols, ABI-smoke tested (`tests/abi_smoke.py`).
- **Downlink:** `RenderSnapshot` = 48-byte envelope + framed sections `1 PLAYER, 2 TERRAIN_META, 3 TERRAIN (optional), 4 OCEAN, 5 SKY, 6 MATERIALS, 7 VOLCANO, 8 PLUME` (0003 additive), little-endian, validated strictly by the adapter (loud `ERR_PRINT`, frame skipped — never coerced). Schema bump `1 → 2` (0003 §3.5): adapter refuses any schema ≠ 2; `test_schema_mismatch.sh` stub reports `SCR_SIM_SCHEMA_VER + 1`.
- **Uplink:** `scr_input_batch` (20 bytes) — raw intent only; the sim integrates.
- **Transport:** in-process (`dlopen` of `build/libscr_sim.so`); contract is transport-agnostic (IPC swap deferred, spec §9).

### 4.4 Testing Strategy

| Layer | Test | What it proves |
|---|---|---|
| Spec (Mojo) | `tests/mojo/test_*.mojo` — 8 files, 47 tests | determinism, projection purity, envelope/framing, synthesis conformance, Gerstner ranges, catalog derivability, golden fixture, **volcano subject (0003: effusion sequence, ranges, glow semantics)** |
| Binding | `tests/abi_smoke.py` (49 checks) | C ABI symbols, 20-byte input layout, error paths, FFI snapshot == fixture, **schema 2 + VOLCANO/PLUME field checks** |
| Binding negative | `tests/test_schema_mismatch.sh` | loader refuses schema ≠ 2 loudly (stub reports `SCR_SIM_SCHEMA_VER + 1`); accepts real lib |
| Integration | `tests/godot/godot_load_test.sh` | headless main-scene load, extension registration, zero `ERROR:` lines |
| Integration | `tests/godot/godot_screenshot.sh` + `tests/godot/godot_screenshot.gd` + `tests/godot/check_luminance.py` | rendered non-blank capture + content assertions (terrain chunks, meta, HUD) + **plume/lava region checks and, with `SCR_EXPECT_GLOW=1`, the night-glow spot check (§8.3)** |
| Integration | `tests/godot/godot_playability_test.sh` + `tests/godot/godot_playability_test.gd` | scripted input: move/turn/jump, camera bounds, no fall-through |
| Gate | `scripts/check_layout.sh` | layout + AP-1 (no engine types in `src/mojo/`) + AP-4 (no absolute paths) |

All Mojo checks are **raise-based** (`_check(cond, msg)` → `raise Error`): this toolchain compiles `assert` to a no-op (verified in `test_volcano.mojo`), so the 0003 sprint converted every `assert` in `test_synthesis_conformance`, `test_gerstner`, `test_catalog` to `_check` — which immediately exposed three latent test-vs-spec bugs (§8.3).

### 4.5 Successor Specification Reference

Exact successor sequencing: `TBD — future milestone` (spec §10 table; Rule 10).

## 5. Scene ↔ State Mapping (the ADAPTER CONTRACT)

Group discovery is by Godot node group; absent groups are tolerated (presentation absent), mistyped nodes are reported and skipped. Authoritative implementation: `providers/.../adapter/scr_godot_adapter.cpp` (file header + `apply_*`).

| Group (scene) | Node type | Snapshot section | Applied as |
|---|---|---|---|
| `scr_sim` | `ScrSim` (GDExtension, `world_seed = 1`) | — (producer) | `_physics_process`: batch input → `scr_sim_step` → decode snapshot → apply |
| `scr_terrain` | `Node3D` | `3 TERRAIN` | creates/updates children `Chunk_i` (`MeshInstance3D`, `ArrayMesh`, **world-space vertices**, per-material-id surfaces from MATERIALS; chunk `origin` stored as node meta). **Winding:** sim/contract §4.3 emits CCW front faces; Godot defaults to CW front (`CULL_BACK`), so the adapter swaps index order (`out3[0],out3[2],out3[1]`) when building surfaces — conversion at the provider boundary, contract unchanged |
| `scr_meta` | `Node` | `2 TERRAIN_META` | meta keys `sea_level` (float), `peak_height` (float), `spawn_position` (Vector3) |
| `scr_ocean` | `MeshInstance3D` + `ShaderMaterial` | `4 OCEAN` | shader params **exactly**: `sea_level, amplitude, frequency, steepness, dir_x, dir_z, speed, phase` (every physics frame) |
| `scr_sun` | `DirectionalLight3D` | `5 SKY` | `set_rotation(-sun_elevation, sun_azimuth, 0)` rad; `light_energy = sun_intensity` |
| `scr_env` | `WorldEnvironment` | `5 SKY` | `environment.fog_enabled = true`, `fog_density`, `fog_light_color` |
| `scr_camera` | `Camera3D` (or rig `Node3D`) | `1 PLAYER` | global position = `player.position + (0, eye_height, 0)`; `rotation = (pitch, yaw, 0)` — **no sign flips** (sim forward = `(−sin yaw, −cos yaw)` = Godot −Z under +yaw) |
| `scr_hud` | `Label` | envelope | text `tick %d | gen %d | seed %d` |
| `scr_materials` | `Node` | `6 MATERIALS` | meta `materials` = Dictionary `id → {albedo, roughness, emissive, opacity}` (also used to derive `StandardMaterial3D` per chunk surface) |
| `scr_crater_lava` | `MeshInstance3D` + `ShaderMaterial` (0003) | `7 VOLCANO` | position `(center_x, lake_level + 1, center_z)` (1 u glow-free lift, display), non-uniform scale `(radius, 1, radius)`, shader uniforms `emissive_intensity`, `crust_fraction`, `radius` |
| `scr_crater_glow` | `OmniLight3D` (0003) | `7 VOLCANO` | `light_energy = glow_intensity` (sim-computed; adapter must NOT re-derive “night”, AP-11); position `(center_x, lake_level + GLOW_DISPLAY_LIFT_U, center_z)` — **display lift 60 u**, geometry rationale + measurement chain in §8.3 |
| `scr_plume` | `GPUParticles3D` + `ParticleProcessMaterial` (0003) | `8 PLUME` | position = plume origin, `lifetime`, `amount = round(rate·lifetime)` (clamped 1..4096), `emitting = rate > 0`, `initial_velocity_min = max = v0`, `spread`, `set_turbulence_enabled(turbulence > 0)` with **velocity influence locked to 0** (§8.3) |

**Input uplink (scene → sim):** `scripts/player_input.gd` calls
`ScrSim.submit_input(move_x, move_y, look_dx, look_dy, jump, sprint, action_primary, action_secondary)`
every physics frame (parent-before-child order guarantees the adapter consumes the same frame). Look deltas accumulate per frame and reset after batching (adapter); movement is clamped to the unit circle (adapter); booleans are level-triggered per frame. The script contains **zero gameplay logic** (AP-8): no node movement, no world writes. Look deltas are passed through as **raw device deltas**; the device→world sign mapping (yaw positive = left per contract §6, so mouse-right must *decrease* yaw) is applied exactly once, in the sim input decode `sim/subjects.mojo::collect_intent` — the script stays a pure passthrough and the sim stays the semantic authority for input meaning.

**Ocean node contract:** transform kept identity (position 0,0,0) so the shader's local space equals the world frame (documented in `shaders/ocean.gdshader` header).

## 6. Parameter Table (AP-7)

Source of truth: **`src/mojo/sim/parameters.mojo`** (single home for tunables; nothing else may hard-code gameplay values). Normative defaults mirrored by `104_contract.md` §6. Units as cited there.

### 6.1 Timestep & locomotion

| Parameter | Value | Unit | Where used |
|---|---|---|---|
| `TICK_RATE_HZ` / `FIXED_DT` | 60 / 1⁄60 | Hz / s | `sim/world.mojo` accumulator |
| `FRAME_DT_CLAMP` | 0.05 | s | sim-side frame delta clamp |
| `WALK_SPEED` | 4.25 | u/s | `sim/subjects.mojo` |
| `SPRINT_SPEED` | 8.0 | u/s | `sim/subjects.mojo` |
| `JUMP_VELOCITY` | 5.8 | u/s | `sim/subjects.mojo` |
| `GRAVITY` | −10.0 | u/s² | `sim/subjects.mojo` |
| `PITCH_CLAMP` | ±1.45 | rad | `sim/subjects.mojo` |
| `EYE_HEIGHT` | 1.7 | u | camera offset (adapter applies from PLAYER) |
| `SWIM_SPEED_FACTOR` | 0.65 | × | swim locomotion |
| `MOUSE_SENSITIVITY` | 0.0025 | rad/input-unit | `look_dx/dy × 0.0025` in `subjects.mojo::collect_intent` (device sign flip applied there — §5) |

Local comptime helpers outside `parameters.mojo` (flagged honestly — sim-side, not scene): `SWIM_GRAVITY_FACTOR = 0.3`, `SWIM_JUMP_FACTOR = 0.5`, `SWIM_VERTICAL_DAMP = 0.9`, `MAP_BOUND = 126.0` in `sim/subjects.mojo`. Moving them into `parameters.mojo` is a sim-side cleanup — `TBD — future milestone` (src/mojo out of Sprint-04 edit scope).

### 6.2 Scene generation (Sprint 01, same file)

`SEA_LEVEL = 0.0` u · `GRID_N = 64` cells · `CELL_SIZE = 4.0` u · `ISLAND_RADIUS = 96.0` u · `PEAK_HEIGHT = 44.0` u · `TERRAIN_CHUNK_CELLS = 16` · noise octaves/lacunarity/gain `5 / 2.0 / 0.5` at `NOISE_BASE_FREQUENCY = 0.012` cycles/u (ridged `4` octaves) · spawn search band 56..94 u, beach target `SPAWN_BEACH_OFFSET = 1.25` u.

### 6.3 Ocean / sky / foam (same file)

| Parameter | Value | Unit |
|---|---|---|
| `WAVE_AMPLITUDE` | 0.55 | u |
| `WAVE_WAVELENGTH` → `k = 2π/λ` | 8.0 | u (k ≈ 0.785398 rad/u) |
| `WAVE_STEEPNESS` (Q) | 0.9 | — |
| `WAVE_DIRECTION` | (0.8, 0.6) | unit (normalized defensively) |
| phase speed `c = sqrt(\|g\|/k)` | ≈ 3.568248 | u/s (derived, not free) |
| `FOAM_JACOBIAN_THRESHOLD` | 0.65 | J (§2.3) |
| `FOAM_HEIGHT_THRESHOLD` | 0.7 | normalized height |
| `TIME_OF_DAY_START_HOURS` | 12.0 | h |
| `SECONDS_PER_SIM_HOUR` | 100.0 | s |
| `FOG_DENSITY` | 0.0045 | — |
| `FOG_COLOR` | (0.58, 0.66, 0.78) | RGB |
| `SUN_INTENSITY_NOON` / `SUN_ELEVATION_MAX` | 1.0 / 1.2 | — / rad |

(`FOG_*` and `TIME_OF_DAY_START_HOURS` are atmosphere-lite display inputs:
they change the SKY section bytes, so a change here requires re-running
`tests/mojo/gen_golden_fixture.mojo`.)

### 6.4 Scene-side display mirrors (island.tscn shader params — display only)

The adapter overwrites **only the 8 contract uniforms** from the OCEAN
section (`sea_level, amplitude, frequency, steepness, dir_x, dir_z, speed,
phase`); the initial values exist so frame 0 is not degenerate and mirror
§6.3 (AP-7: they live in the scene file + this table, never inline in the
shader). Foam/fresnel/palette values are **scene-only display tuning** —
the adapter never writes them, so they may diverge from the sim thresholds:

`sea_level 0.0 · amplitude 0.55 · frequency 0.785398 · steepness 0.9 · dir_x 0.8 · dir_z 0.6 · speed 3.568248 · phase 0.0 · foam_jacobian_threshold 0.58 · foam_height_threshold 0.998 · fresnel_power 4.0 · specular_gain 1.0` plus display-only palette colors (shallow `(0.14,0.36,0.44)`, deep `(0.02,0.09,0.17)`, sky tint `(0.5,0.64,0.8)`, foam `(0.6,0.68,0.76)`).

Display-foam tuning (2026-09-26): sim `FOAM_JACOBIAN_THRESHOLD = 0.65`
would whitecap 13% of every wavelength (with `J_min = 0.611`), and an
uncapped `fwidth()` AA ramp saturated at grazing angles and foamed the whole
far ocean white. Display now uses `foam_jacobian_threshold 0.58` (below
`J_min` ⇒ Jacobian whitecaps off for display), `foam_height_threshold 0.998`
with AA half-width clamped to `0.006` in `ocean.gdshader` (crest duty ≈ 4%),
and foam emission gain `0.01` — subtle white crests; sim thresholds in §6.3
remain the physics authority.

Ocean environment: `tonemap_mode = 3` (ACES), `tonemap_exposure = 1.0`,
`ambient_light_source = 3` (sky) with `ambient_light_energy = 0.55`,
`fog_density = 0.0045` / `fog_light_color (0.58,0.66,0.78)` /
`fog_sky_affect = 0.3`. Sun (`scr_sun`): `shadow_enabled = false`
(terrain self-shadow acne at cell scale) and `light_specular = 0.0`
(rock specular streaks); rotation/energy still overwritten from SKY each
frame.

Ocean mesh: `PlaneMesh` 768×768 u, `subdivide_width/depth = 512` (≈1.5 u
cells ⇒ >5 samples per 8 u wavelength; size chosen so the plane edge sits
beyond the visible horizon band — display resolution choice, not a gameplay
value).

### 6.5 Volcano / plume / glow (0003, `parameters.mojo` + scene display)

Sim-side tunables (`src/mojo/sim/parameters.mojo`, AP-7):

| Parameter | Value | Unit |
|---|---|---|
| `LAVA_EMISSIVE_CORE` / `LAVA_EMISSIVE_CRUST` | 1.0 / 0.12 | × E_core, × E_crust |
| `LAVA_CRUST_DORMANT` / `LAVA_CRUST_EFFUSING` | 0.85 / 0.15 | crust fraction C |
| `EFFUSION_TICK_STEP` | 300 | ticks between draws (5 s @ 60 Hz) |
| `EFFUSION_ACTIVE_PROBABILITY` | 0.35 | P(effusing) per draw (seeded, AP-12) |
| `PLUME_RATE_DORMANT` / `PLUME_RATE_EFFUSING` | 0.0 / 60.0 | 1/s |
| `PLUME_VELOCITY` (w0) | 8.5 | u/s |
| `PLUME_SPREAD` | 15.0 | deg (cone half-angle) |
| `PLUME_TURBULENCE` | 0.35 | turbulence amount (drives `set_turbulence_enabled`, influence locked 0 — §8.3) |
| `PLUME_LIFETIME` | 6.0 | s |
| `GLOW_NIGHT_MAX_FACTOR` / `GLOW_NIGHT_ELEVATION_REF` | 1.0 / 1.2 | night_factor cap / elevation ref (rad) |
| `VOLCANO_LAKE_RADIUS_FALLBACK` | `CALDERA_LAKE_RADIUS` | no-lake fallback |

Scene/adapter **display constants** (representation only, never semantics):

- `GLOW_DISPLAY_LIFT_U = 60.0` (adapter, `scr_godot_adapter.cpp`) + `omni_range = 90.0`, `omni_attenuation = 0.4`, `light_color (1, 0.6, 0.25)` (`island.tscn`) — glow light geometry; rationale + measurement chain §8.3.
- Lava display lift `+1 u` above `lake_level`; `lava.gdshader` `albedo_scale = 0.35` (anti-overexposure display uniform).
- Plume display: `QuadMesh size 2.0`, `billboard_mode = 3` (BILLBOARD_PARTICLES — quads are back-face culled otherwise), material `albedo (0.78,0.77,0.75)`, `transparency = 1`, process material `gravity (0,0,0)`, turbulence noise = engine defaults (`strength 1.0`, `scale 9.0`, `speed (0,0,0)`), `amount` cached from `round(rate·lifetime)` cap 4096.
- Screenshot gate region constants (verification only): plume window rows `[0.02H, 0.12H]` × cols `[0.40W, 0.60W]`, per-channel margin-median sky reference, dev > 60, row hits ≥ 10, need ≥ 5 rows; lava warm `(R≥120, R≥G+25, R≥B+60)` within 90 px of projected centre, need ≥ 400; night glow dome box rows `[85,130]` × cols `[560,780]`, warm10 (`R≥70, R−B≥10, R≥G−10`) ≥ 50 **and** max `R−B` ≥ 25 **and** dome luminance printed vs flank background.

## 7. Gerstner: sim vs display authority · water-foam deviation

- **Sim is authoritative.** `ocean/gerstner.mojo` computes `y(x,z,t) = sea + A·cos θ` (grounding: `player.in_water`, shoreline), Jacobian `J = 1 − Q·k·A·cos θ`, foam thresholds, all per `SCR-LIB-MATH-GERSTNER`.
- **Shader is display.** `shaders/ocean.gdshader` re-derives §2.1 displacement from the OCEAN uniforms. **Time evolution comes only from the `phase` uniform** (the encoder folds `−ω·t + φ` into it, `snapshot/encode.mojo::_encode_ocean`); the shader deliberately does **not** use built-in `TIME` — doing both would double-count. Horizontal shoaling (`Q·A·d·sin θ`) is display-only (gerstner.mojo header note). The `speed` field is carried per contract but unused by the shader (temporal term arrives in `phase`).
- **Display wave spectrum (defect fix, 2026-09-27).** The single contract harmonic rendered as perfectly parallel periodic stripes ("corduroy"). The vertex stage now sums **6 display-only harmonics** derived from the *same* contract uniforms (no new uniform names, no sim change): direction_i = contract dir rotated ≤ ±40° (`W_OFF`), k_i = `frequency·W_KS[i]` with `W_KS ∈ [0.75,1.60]`, amplitude shares `A_i = amplitude·W_RAW[i]/2.30` **normalised so ΣA_i == `amplitude`** (crest envelope unchanged — beaches never more submerged than the authoritative single wave), temporal term `sqrt(W_KS[i])·phase + W_PH[i]` (deep-water dispersion ω = √(g·k) ⇒ ω_i/ω = √(k_i/k)). Constants live in the shader header (display-only, not gameplay tunables). Sim `gerstner.mojo` single-harmonic physics (grounding, in-water, foam) unchanged and still authoritative.
- **Foam:** snapshot carries no foam field; the shader recomputes the *same closed form* `J = 1 − Q·k·A·cos θ`. Sim thresholds (§6.3) stay authoritative for physics; the display thresholds + clamped `fwidth` AA half-widths (§6.4) are tuned for subtle crests and diverge deliberately.
- **Deviation from `SCR-LIB-RENDER-WATER` (recorded, not silent):** the library intent is *shoreline* foam from `y_terrain(x,z)` vs `y_water(x,z,t)`. The display side has no terrain-height texture; the shader approximates foam as **crest foam only** (Jacobian + normalized-height surges). Terrain-vs-water shoreline foam = `TBD — future milestone`.
- **Sun specular:** the shader applies Fresnel toward a sky tint; it has no access to the sun node's direction, so there is no sun-aligned specular lobe. Display simplification, recorded here.
- **Sky:** `ProceduralSkyMaterial` gradient (static palette) in `island.tscn`; time-of-day lighting arrives via the `scr_sun` rotation/energy each frame. The sky *gradient* itself does not re-tint per time-of-day (static gradient — honest note). Custom `shaders/sky.gdshader` = `TBD — future milestone`.

## 8. Verification Record (procedures + Sprint-04 run)

Procedures (all runnable from repo root):

```bash
bash applications/godot/scripts/build_godot_provider.sh     # build
bash applications/godot/scripts/check_layout.sh             # layout + AP-1 + AP-4
bash applications/godot/tests/godot/godot_load_test.sh            # headless load, no errors
bash applications/godot/tests/godot/godot_screenshot.sh           # rendered capture + luminance (needs display)
bash applications/godot/tests/godot/godot_playability_test.sh     # scripted input (headless)
python3 applications/godot/tests/abi_smoke.py               # C ABI
bash applications/godot/tests/test_schema_mismatch.sh       # negative: schema refusal
```

**Sprint-04 results (2026-09-26):**

| Gate | Result |
|---|---|
| `build_godot_provider.sh` | PASS (`OK — provider built`, 7 `scr_sim_*` symbols, 1 `gdextension_init`) |
| `check_layout.sh` | PASS (AP-1 + AP-4 clean) |
| `godot_load_test.sh` | **FAIL** — 57× `ERROR: SCR: snapshot rejected … MATERIALS: section_bytes != 12 + 36*count` (see blocker below) |
| `godot_screenshot.sh` | rendered capture OK: **mean luminance 192.09, stddev 18.19** (thresholds 10 / 5, both in-script and `tests/godot/check_luminance.py`); PNG `build/island.png`. **Content assertions FAIL** (0 terrain chunks) — blocked by same blocker |
| `godot_playability_test.sh` | **FAIL** (6 checks) — chunks 0, meta absent, HUD empty, camera never moves; root cause = same blocker |
| `abi_smoke.py` | PASS (26/26) |
| `test_schema_mismatch.sh` | PASS (5 checks) |
| `/home/` grep (sources) | PASS (0 matches; only compiled binaries `.so/.os/.sconsign` embed build paths) |
| Mojo spec tests | PASS **36/36** (7 files) |

**Anti-pattern review (spec §2.1, item-by-item — exit criterion: Review pass):**

| # | Verdict | Evidence in this implementation |
|---|---|---|
| AP-1 engine types in sim | PASS | `check_layout.sh` AP-1 gate: 0 matches in `src/mojo/` (comments stripped) |
| AP-2 semantic library bypassed | PASS (direct) / partial (indirect) | Direct executable tests: `SCR-LIB-SPATIAL-VOXEL-SYNTHESIS` + `FIELD` (`test_synthesis_conformance.mojo`), `MATH-GERSTNER` (`test_gerstner.mojo`), `RENDER-MATERIAL` (`test_catalog.mojo`). **Indirect only:** `MATH-NOISE` (exercised via synthesis conformance — no standalone noise-conformance test), `RENDER-WATER` (sim-side Jacobian ranges in test_gerstner; display foam = §7), `RENDER-SKY` (`atmosphere_from_time` exercised inside determinism/envelope runs, no dedicated unit test), `SPATIAL` (world frame explicit in snapshot; no frame-algebra test), `PHYSICS` (gravity constant consumed, no standalone test), `804` layering (structural — layout + AP-1/AP-8 gates). Gaps recorded in §9. |
| AP-3 dual material vocabularies | PASS | single source `lib/A01_Render/Material/materials_catalog.json`; adapter derives `StandardMaterial3D` from MATERIALS section only (`test_catalog.mojo` PASS) |
| AP-4 absolute paths | PASS | `check_layout.sh` AP-4 + grep gate: 0 `/home/` matches in `src/`, `godot/`, `providers/` sources |
| AP-5 monolith frame loop / if-else dispatch | PASS | modules split (`sim` / `snapshot` / `adapter` / presentation); input dispatch = table (`sim/input.mojo::build_input_table`, AP-5 test) |
| AP-6 `dynamic_cast` pierces layers | PASS | 0 `dynamic_cast` occurrences in adapter sources (grep) |
| AP-7 magic constants | PASS | all tunables in `src/mojo/sim/parameters.mojo` + mirrored table §6 (4 helpers still local in `subjects.mojo` — §6.1) |
| AP-8 presentation mutates sim | PASS | `player_input.gd`/`hud.gd` contain zero position/velocity/transform writes (grep); only `submit_input`; sim never touches nodes (adapter applies snapshot, sim has no node access) |
| AP-9 render-thread stalls | PASS (structure, no benchmark) | adapter frame path does apply-sections only; no socket/file I/O (`grep socket|fopen|ifstream` = 0); dlopen + init at load time; perf budgets out of scope (§1) |
| AP-10 shell-selected providers | PASS | provider tree + `101/102/103/104` control docs; build via `scripts/build_godot_provider.sh` (contract-checked `104_contract.md`) |

**BLOCKER (Sprint-04, open):** the adapter rejects **every** snapshot because it
validates the `MATERIALS` section as `section_bytes == 12 + 36·N`
(`scr_godot_adapter.cpp`, consistent with the `(12 + 36·N bytes)` header in
`104_contract.md` §4.3), while the encoder emits `4 + 36·N`
(`snapshot/encode.mojo::_encode_materials` — consistent with the same §4.3
*field table* `|0| u32| count|`, the golden fixture (220 = 4+36·6), and all
sim-side tests). Contract-internal inconsistency: header vs field table.
Consequence: no section is ever applied (no terrain, no camera move, no HUD),
so exit criteria 1–3 fail. Fix options require editing **either** the adapter
constant (`12u` → `4u`, plus `sbytes < 12` → `< 4`) **or** the encoder +
fixture + tests (8 reserved bytes) — or first amending the contract header.
Adapter/`src/mojo`/fixture are outside Sprint-04 edit scope by instruction:
**escalated to the orchestrator, not fixed here.**

**Manual capture fallback** (if no display): printed by
`tests/godot/godot_screenshot.sh` on display-probe failure; procedure also embedded in
`tests/godot/godot_playability_test.sh` header. On this machine `$DISPLAY=:1` and
`/dev/dri` exist, so the automated path ran.

### 8.1 Visual-tuning run (2026-09-26) — all 8 gates PASS

Atmosphere-lite changes (`FOG_DENSITY 0.012 → 0.0045`, `FOG_COLOR →
(0.58,0.66,0.78)`, `TIME_OF_DAY_START_HOURS 9.0 → 12.0`) alter SKY-section
bytes, so `gen_golden_fixture.mojo` was re-run (**fixture regen: yes**,
`snapshot_seed1_tick1.bin` = 228556 B) before the gates.

| Gate | Result |
|---|---|
| 7 mojo spec tests (determinism, projection_purity, envelope, synthesis_conformance, gerstner, catalog, golden_fixture) | PASS 7/7 |
| `build_godot_provider.sh` | PASS |
| `abi_smoke.py` | PASS |
| `test_schema_mismatch.sh` | PASS |
| `check_layout.sh` | PASS |
| `godot_load_test.sh` | PASS (0 ERROR lines) |
| `godot_screenshot.sh` | PASS — `mean = 126.65`, `stddev = 51.66` (thresholds 10 / 5), PNG `build/island.png` |
| `godot_playability_test.sh` | PASS (`horizontal=24.00 jump_gain=1.73 y=[2.31,12.57] fails=0`) |

Root causes found and fixed during this run:

1. **White wedge / solid white far ocean** — foam AA used uncapped
   `fwidth(crest|jacobian)`; at grazing angles one pixel spans a large θ
   range, the smoothstep saturated, and the whole far ocean foamed white.
   Fix: clamp AA half-widths (`wh ≤ 0.006`, `wj ≤ 0.04`) in
   `ocean.gdshader` (§6.4).
2. **Broad white wave stripes** — display `foam_jacobian_threshold 0.65`
   whitecaps 13% of every wavelength (`J_min = 0.611`) and
   `foam_height_threshold 0.7` is wider still. Fix: display thresholds
   `0.58` / `0.998` + darker `foam_color` (§6.4) — bright-pixel count
   40525 → 10491, crest duty ≈ 4%.
3. **Dark flat terrain / rim contrast** — 09:00 sun (side-lit) left
   camera-facing slopes ambient-only. Fix: `TIME_OF_DAY_START_HOURS 12.0`
   (south sun, energy `sin(1.2) = 0.932`), `ambient_light_energy 0.4 → 0.55`,
   fog lifted to `0.0045`.

Known limitations recorded (not fixed — out of display scope or physical):

- **Crater-rim "comb/teeth"**: alternating sulfur (albedo 0.92) / basalt
  (0.25) cells across the rim band (r ≈ 28–39, first-vertex material
  grouping) viewed at a glancing angle become thin radial slivers. Mesh
  geometry verified clean (unit normals, no degenerate triangles);
  shadows and specular ruled out (`shadow_enabled=false`,
  `light_specular=0`). Full fix = sim-side material blending at biome
  boundaries — synthesis change, out of scope here; display mitigations
  (fog + ambient) only reduce the contrast.
- **Lava reads salmon/mauve**: `fluid.lava` albedo `(1,0.4,0.05)` under
  white sun + sky-blue ambient + ACES; adapter sets the emission *color*
  but `emission_enabled` stays false (StandardMaterial3D default), so the
  lake is diffuse-lit only. Emission-enable would be an adapter change
  beyond the allowed normals-bug scope — escalated, not done.
- **Sun disk not in frame**: with the spawn facing +z and the diurnal
  azimuth law (§6.3, east→south→west), the sun is above the horizon only
  for azimuths with a −z component — it is physically behind the camera
  for every daytime hour. Sun *lighting* is visible; a disk would need a
  spawn-yaw or azimuth-law change (sim semantics — escalated, not done).


### 8.2 Defect-fix run (2026-09-27) — 3 user-reported defects, all gates PASS

User reports: (1) inverted horizontal mouse-look, (2) "half the island
missing" though collision ground exists, (3) fake/repetitive corduroy water.

**Root causes:**

1. **Mouse-look inverted** — device→world sign for yaw was never applied.
   Contract §6: yaw positive = left; `player_input.gd` passed raw
   `event.relative.x` (positive = mouse right) into `look_dx`, and
   `subjects.mojo::collect_intent` did `yaw_delta = +look_dx·SENS`, so
   mouse-right turned left. Fix: sign flip in the sim input decode
   (`intent.yaw_delta = -Float64(e.value_x)` in `collect_intent`) — the sim
   owns input semantics, the script stays a pure passthrough (AP-8), adapter
   camera mapping (`rotation = (pitch, yaw, 0)`, no sign flips) unchanged.
   Golden fixture regenerated (PLAYER yaw −3.0259 → −3.0265, same order as
   spawn facing island center).
2. **Island invisible (culled, not missing)** — adapter diagnostic proved all
   16 chunks / 8192 tris present with correct world AABBs, but with
   `--cull=0` the island appeared and under default `CULL_BACK` it did not.
   Root cause: contract §4.3 emits **CCW** front faces; Godot's default front
   is **clockwise** (verified by probe triangle), so every outward face was
   back-face-culled. Fog/AABB/chunk grouping were ruled out (measurements:
   fog attenuates distant terrain ~18–40% but never hides it). Fix: index
   swap `out3[0],out3[2],out3[1]` when building ArrayMesh surfaces in the
   adapter (conversion at the provider boundary; contract + fixture unchanged).
   Evidence: `build/aerial.png` (before, island 100% invisible),
   `build/aerial_nocull.png` (before, cull-off shows island),
   `build/aerial.png`/`aerial_nofog.png`/`aerial_noocean.png` (after).
3. **Corduroy water** — single sim harmonic along one direction = perfectly
   periodic parallel stripes (§7 display-spectrum fix, display-only).

**Verification (10 gates):**

| # | Gate | Result |
|---|---|---|
| 1 | 7 mojo spec tests (determinism, projection_purity, envelope, synthesis_conformance, gerstner, catalog, golden_fixture) | PASS 7/7 (fixture regenerated post-yaw-flip: 228556 B) |
| 2 | `build_godot_provider.sh` | PASS (up to date, `camera_follow` property present) |
| 3 | `abi_smoke.py` | PASS (35 checks; FFI snapshot byte-identical to fixture) |
| 4 | `test_schema_mismatch.sh` | PASS (5 checks; loader refuses schema-2) |
| 5 | `check_layout.sh` | PASS (AP-1 + AP-4 gates) |
| 6 | `godot_load_test.sh` | PASS (0 ERROR lines) |
| 7 | `godot_screenshot.sh` | PASS (mean 158.41 / stddev 67.00; island rendered: beach + flank + sulfur cap) |
| 8 | `godot_playability_test.sh` | PASS (`horizontal=24.00 jump_gain=1.73 y=[2.31,10.49] fails=0`; yaw leg now asserts **sign**: `look_dx=+5.0` → yaw −0.750 rad) |
| 9 | scripted mouse-sign | PASS via playability E leg (60 frames `look_dx=+5.0` → yaw decreases by exactly 60×5.0×0.0025 = 0.750 rad) |
| 10 | aerial before/after captures | PASS — `build/aerial.png` (after: island fully visible from above), `aerial_noocean.png` (land footprint + complete beach ring), `aerial_sea.png` (irregular crossing swells) vs before captures (`aerial_nocull.png` cull diagnostic, `water_before.png` corduroy) |

Playability caveat: headless display server delivers no mouse motion, so the
E leg fell back to `TURN-MODE=direct` (`submit_input(look_dx,…)`); the sign
path through `collect_intent` is exercised either way.

**Residuals (honest):** spawn faces inland — no water in the default first
view (water shown via aerial/oblique captures instead); fog washes distant
terrain ~18–40% (was never the defect); `camera_follow` default `true` is a
debug aid, not gameplay; motion-mode mouse path unexercised headless.


### 8.3 Milestone 0003 (Volcano) — Sprint-04 verification record (2026-09-28)

**Evidence-driven findings (measurement chains, not guesses):**

1. **Plume invisible → root cause: turbulence velocity influence (display
   measurement campaign).** Godot 4.7 `ParticleProcessMaterial` turbulence
   with `PARAM_TURB_VEL_INFLUENCE > 0` relaxes each particle's velocity toward
   the noise field, cancelling the buoyant initial velocity: measured plume
   height `≈26 u` at influence `0.005` vs `≈54 u` ballistic (`v0·lifetime`),
   collapsing further as influence rose; stall height ≈ `v0 /
   (influence × fixed_fps 30)`. Influence-over-life curves, strength, scale,
   speed, displacement and randomness sweeps either failed or were no-ops
   (`turbulence_initial_displacement` is unreliable in 4.7 — never claimed).
   **Locked mapping (adapter):** `set_turbulence_enabled(turbulence > 0)`
   (semantic gate from the contract value) with velocity influence min/max
   **locked to 0.0** — noise field available for future display use, column
   physics stays ballistic. Probe scripts + full numbers: `/tmp/opencode/
   turbmatrix*.gd`, `growth*.gd` (session artifacts; conclusions restated
   here). Gate regression guard asserts `turbulence_enabled == true` AND
   `influence == 0`.
2. **Renderer kept Forward+/Vulkan.** Spec locks `GPUParticles3D` (0003
   §1.1); `gl_compatibility` cannot run it. `project.godot` features now
   `"4.7", "Forward Plus"` with a justification comment. Environment:
   Godot 4.7.2, GTX 1650, Vulkan 1.4.351.
3. **Particle-API gotchas (verified):** `GPUParticles3D.get_aabb()` always
   returns zero — use `capture_aabb()`; `-s` SceneTree mode does simulate
   particles; QuadMesh draw passes are back-face culled unless
   `billboard_mode = 3`; default gravity `(0,−9.8,0)` must be zeroed.
4. **Latent test-vs-spec bugs exposed by the `assert` → `_check`
   conversion** (0003 sprint; this toolchain compiles `assert` to a no-op):
   - `test_gerstner` “unit normal”: spec §2.2 defines `N = B × T`
     **unnormalized**; test now checks non-degenerate + upward-facing.
   - `test_synthesis_conformance` “corner exact”: test omitted the half-cell
     offset — cell centres are `c_i = (i + 0.5 − N/2)·CELL_SIZE`.
   - `test_synthesis_conformance` “caldera lake surface must be water”:
     0002 §3 table locks `CALDERA_LAKE → LAVA`; expectation corrected.
   Product code unchanged in all three — the test expectations were wrong.
5. **`runtime.mojo` env-handle fix (0003):** `String.from_utf8` env-buffer
   handle carried a trailing NUL into `SCR_SIM_*` reads (aborted the CLI
   headless path); fixed by trimming at the C boundary — verified 5/5 clean
   CLI runs + 4/4 abi-smoke.
6. **Night glow evidence path (spec §7 manual procedure).** Command chain
   (from repo root):

   ```bash
   # set comptime TIME_OF_DAY_START_HOURS = 21.0 in src/mojo/sim/parameters.mojo
   .venv/bin/mojo run -I applications/godot/src/mojo applications/godot/tests/mojo/gen_golden_fixture.mojo
   bash applications/godot/scripts/build_godot_provider.sh
   SCR_EXPECT_GLOW=1 bash applications/godot/tests/godot/godot_screenshot.sh
   # then revert to 12.0, regenerate fixture, rebuild, day capture re-verified
   ```

   Result: `crater glow light_energy = 0.663` (> 0 only at night — sim
   `night_factor`, AP-11), glow spot on the dome **dome warm10 = 301,
   max R−B = 30, dome luminance 140.2 vs dark-flank background 36.9**
   (glow-OFF baseline: warm10 = 0, max R−B = −20). PNG
   `build/island.png` read and confirmed visually (warm spot above the
   sulfur cap). Day revert re-confirmed: `light_energy = 0.000`.
   Measurement chain for the display lift (why 60 u): +1 u → light buried
   in the crater bowl, every visible outer slope has `NdotL < 0`,
   warm px = 0; +30 u (y≈40) → still behind the visible slope normals,
   warm px = 0; +60 u (y≈70) → light above the visible silhouette, slopes
   get `dot > 0`, spot appears (light centre projects just above the frame
   top, y = −8; its lit pool lands on the dome). Honest note: the night
   **skybox stays bright** (static `ProceduralSkyMaterial`, §7) — terrain
   darkens via `sun_intensity = 0`, ambient stays sky-sourced.
7. **Screenshot-gate fixes:** plume reference rebuilt as **per-channel
   margin-median** (the old sum-of-channels/3 form false-passed on a
   chromatic sky); crater camera moved **inside** the crater
   (`lava + (16, 24, 16)` — the old `(24,26,24)` was rim-occluded, warm
   px = 0); settle is **tick-based** (`tick_min + 40`) because the render
   loop runs ~4 physics ticks/frame and a frame-based settle raced past
   the effusion window.

**Final gate results (2026-09-28, fresh run):**

| # | Gate | Result |
|---|---|---|
| 1 | 8 mojo spec-test files (`catalog, determinism, envelope, gerstner, golden_fixture, projection_purity, synthesis_conformance, volcano`) | PASS 8/8 files — 47/47 tests |
| 2 | `build_godot_provider.sh` | PASS (7 `scr_sim_*` symbols) |
| 3 | `abi_smoke.py` | PASS (49 checks incl. schema 2 + VOLCANO/PLUME fields) |
| 4 | `test_schema_mismatch.sh` | PASS (5 checks; stub refuses `SCR_SIM_SCHEMA_VER + 1`) |
| 5 | `check_layout.sh` | PASS (AP-1 + AP-4; leftover probe scripts removed) |
| 6 | `godot_load_test.sh` | PASS (0 ERROR lines) |
| 7 | `godot_screenshot.sh` (day) | PASS — mean 156.35 / stddev 67.64; plume rows 22/72; `light_energy = 0.000`; PNGs read (plume above sulfur cap; crater lava disc) |
| 8 | `godot_screenshot.sh` (`SCR_EXPECT_GLOW=1`, night) | PASS — `light_energy = 0.663`, dome warm10 = 301, max R−B = 30, dome lum 140.2 vs flank 36.9; day revert re-confirmed |
| 9 | `godot_playability_test.sh` | PASS (`horizontal=24.00 jump_gain=1.73 yaw_delta=-0.750 fails=0`) |

**Anti-pattern review (0003 §2.1 AP-11..AP-14 + 0002 §2.1 AP-1..AP-10):**

| # | Verdict | Evidence |
|---|---|---|
| AP-11 display-derived lava/plume/glow state | PASS | all state (level, emissive, crust, effusion, glow, rate/velocity/spread/turbulence/lifetime) arrives in `7 VOLCANO`/`8 PLUME`; adapter only mirrors (§5 rows); `albedo_scale`, lifts, quad size, light colour = documented display (§6.5) |
| AP-12 unseeded randomness | PASS | effusion draws seeded from `World.seed` (`EFFUSION_TICK_STEP`, `EFFUSION_ACTIVE_PROBABILITY`); golden sequence locked in `test_volcano.mojo`; particle jitter display-only, no feedback |
| AP-13 schema growth without bump | PASS | `SCHEMA_VERSION 2`, fixture regenerated (228636 B), abi_smoke VOLCANO/PLUME checks, envelope schema==2, mismatch negative green |
| AP-14 inventing quench semantics | PASS | `lava_water_quench` consumed only via catalog vocabulary; quench = documented partial (§9) |
| AP-1..AP-10 | PASS | unchanged review in §8 (layout AP-1/AP-4, no dynamic_cast, table dispatch, no presentation→sim writes, provider docs) |

## 9. Honest Gaps (open)

1. MATERIALS framing blocker (§8) — **RESOLVED** (contract header amended to `4 + 36·N` per field table/fixture, adapter aligned; decode verified end-to-end: load test materializes 16 chunks, abi smoke byte-identical).
2. Godot-cpp from-scratch bootstrap recipe not re-run clean-room ([02 §1.1](02_development_environment.md)).
3. Sky gradient is static (§7); shoreline foam approximated (§7); sun specular simplified (§7); **night skybox stays bright** (§8.3 — only sun energy drops at night; a time-tinted sky = 0004 sky work).
4. Performance budgets — `TBD — future milestone`.
5. Swim/`MAP_BOUND` comptime helpers live outside `parameters.mojo` (§6.1) — sim-side cleanup deferred.
6. Interactive (non-headless) manual play session not recorded this sprint — scripted run is the evidence; manual fallback documented.
7. AP-2 indirect-only semantic-library coverage (§8 review): no standalone conformance tests for `MATH-NOISE`, `RENDER-SKY`, `SPATIAL` frame algebra, `PHYSICS` constants — currently exercised indirectly. `TBD — future milestone`.
8. **Turbulence velocity-influence display semantics (0003):** Godot's velocity-influence mode cancels buoyant columns (§8.3); the noise field is exposed with influence locked at 0. Display-side turbulence that preserves column physics (curl-noise advection in-shader / successor particle integrator) = `TBD — future milestone`.
9. **`lava_water_quench` is a documented partial (0003 AP-14):** consumed only to the extent implemented (catalog vocabulary + reaction name); voxel reaction evaluator completes in milestone 0005 — never implied as working.
10. **Glow light geometry is a display hack (0003 §6.5):** `GLOW_DISPLAY_LIFT_U = 60` + `omni_range 90` exist because a light physically inside the crater bowl cannot light the visible outer slopes (`NdotL < 0`); energy stays the sim contract value. If 0004/0005 add a real crater-interior camera default or volumetric scattering, the lift should be revisited.

## References

- [Documentation index](README.md)
- [spec — milestone 0003 (Volcano)](../program_increments/v0.0.1/milestone_0003_volcano/spec.md)
- [spec — milestone 0002](../program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md)
- [104_contract.md (normative)](../../providers/render/graphics/godot/104_contract.md)
- [src/mojo/sim/parameters.mojo](../src/mojo/sim/parameters.mojo) (parameter source of truth)
- [AGENTS.md](../../AGENTS.md)
