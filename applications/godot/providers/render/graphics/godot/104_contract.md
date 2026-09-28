# 104 — Contract: SCR Simulation ⇄ Godot Adapter Boundary

**Provider:** `providers/render/graphics/godot`
**Status:** Normative
**Owner milestone:** [applications/godot v0.0.1 / milestone 0003](../../../../applications/godot/program_increments/v0.0.1/milestone_0003_volcano/spec.md) (baseline: [milestone 0002](../../../../applications/godot/program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md))
**C ABI header:** [`adapter/scr_godot_abi.h`](adapter/scr_godot_abi.h) (single source of truth for symbol names, struct layouts, error codes)
**Schema version:** `2` (1 → 2 in [milestone_0003](../../../../applications/godot/program_increments/v0.0.1/milestone_0003_volcano/spec.md) §3.5: additive sections `7 VOLCANO`, `8 PLUME`; symbol set unchanged)

---

## 1. Purpose

Define the only state channels between the Mojo simulation core (semantic consumer) and the Godot GDExtension adapter (presentation provider):

- **Downlink:** `RenderSnapshot` — immutable projection of world state, serialized to a byte buffer.
- **Uplink:** `scr_input_batch` — raw player intent; the sim integrates it.

Invariant: projection MUST NOT mutate world state; the adapter MUST NOT make semantic decisions (`milestone_0002` spec §6).

## 2. Transport

In-process for this milestone: GDExtension adapter `dlopen`s the Mojo shared library (`libscr_sim.so`) and calls the C ABI functions directly. The contract is transport-agnostic; a later IPC transport must carry the same byte stream (`milestone_0002` spec §9).

## 3. C ABI summary

| Symbol | Semantics |
|---|---|
| `scr_sim_init(seed)` | First call; initializes Mojo runtime + world; 0 = ok |
| `scr_sim_shutdown()` | Tear down; safe after init |
| `scr_sim_abi_version()` | must equal `SCR_SIM_ABI_VERSION` (1) |
| `scr_sim_schema_version()` | must equal `SCR_SIM_SCHEMA_VER` (3) |
| `scr_sim_step(dt, input*)` | Accumulate `dt`; run 0..n fixed ticks @ 60 Hz; input applied per executed tick; returns ticks run (≥0) or `SCR_ERR_*` |
| `scr_sim_snapshot_size()` | Size of snapshot from most recent successful step |
| `scr_sim_snapshot_write(buf, cap)` | Serialize; returns bytes written or `SCR_ERR_BUF_SMALL` etc. |

**Fixed tick:** `1/60 s`. **Determinism:** seed + input sequence + `dt = 1/60` per call ⇒ byte-identical snapshot sequence.

**Adapter startup rejection:** refuse to run when `scr_sim_abi_version() != SCR_SIM_ABI_VERSION || scr_sim_schema_version() != SCR_SIM_SCHEMA_VER` (negative test required by exit criteria).

## 4. Snapshot binary schema (version 3)

All fields **little-endian**. `f32`/`u32`/`u8` natural alignment; no implicit padding (all offsets documented). Offsets are bytes from snapshot start.

**Schema 1 → 2 migration (milestone_0003 §3.5):** the envelope `schema_version` field is now `2`; sections **1–6 are byte-identical to schema 1** (tables below unchanged); sections `7 VOLCANO` and `8 PLUME` are added; `section_count` for a full snapshot is `8` (was `6`). Schema-1 readers MUST refuse schema-2 bytes via the startup gate (§3/§7) — they must never guess unknown layouts.

**Schema 2 → 3 migration (milestone_0004 §1.1):** the envelope `schema_version` field is now `3`; sections 1–4 and 6–8 are byte-identical to schema 2 (tables below unchanged); **section 5 SKY grows from 32 bytes (8×f32) to 64 bytes (16×f32)** — its first 8 fields keep their schema-2 offsets (0..31), fields 8..15 append the sun-color triple, weather inputs and wetness (§4.3). `section_count` for a full snapshot stays `8`. Schema-1 and schema-2 readers MUST refuse schema-3 bytes via the startup gate (§3/§7).

### 4.1 Envelope (48 bytes, always present)

| Off | Type | Field | Notes |
|---|---|---|---|
| 0 | u32 | `magic` | `0x53524353` (bytes `S C R S`) |
| 4 | u32 | `schema_version` | = 3 |
| 8 | u32 | `section_count` | number of sections that follow |
| 12 | u32 | `world_version` | increments on world regeneration |
| 16 | u32 | `state_generation` | increments every commit |
| 20 | u32 | `simulation_tick` | fixed-tick counter |
| 24 | u32 | `determinism_epoch` | fixed per init; changes only on reseed |
| 28 | u32 | `seed` | world seed |
| 32 | f64 | `simulation_time` | `tick * (1/60)` seconds |
| 40 | u32 | `payload_bytes` | total bytes of all sections (offsets 48…) |
| 44 | u32 | `reserved` | = 0 |

### 4.2 Section framing

Sections follow the envelope consecutively. Each section:

| Off (rel.) | Type | Field |
|---|---|---|
| 0 | u32 | `section_id` (§4.3) |
| 4 | u32 | `section_bytes` (bytes of `data`, excluding this 8-byte header) |
| 8 | u8[…] | `data` (section payload) |

`payload_bytes = Σ (8 + section_bytes)`.

Sections are emitted in id order 1,2,3,4,5,6,7,8. Sections 1, 2, 4, 5, 6, **7, 8** are emitted **every snapshot**; section 3 (TERRAIN) follows the presence rule in §4.3.

### 4.3 Section payloads

**1 — PLAYER** (44 bytes)

| Off | Type | Field |
|---|---|---|
| 0 | f32×3 | `position` (x,y,z) world units |
| 12 | f32×3 | `velocity` (x,y,z) |
| 24 | f32 | `yaw` (radians) |
| 28 | f32 | `pitch` (radians, clamp ±1.45) |
| 32 | f32 | `eye_height` |
| 36 | u8 | `on_ground` (0/1) |
| 37 | u8 | `in_water` (0/1) |
| 38 | u8×6 | `pad` = 0 (section is exactly 44 bytes; 40–43 zero-fill) |

**2 — TERRAIN_META** (32 bytes)

| Off | Type | Field |
|---|---|---|
| 0 | f32 | `sea_level` |
| 4 | f32 | `peak_height` |
| 8 | f32×3 | `spawn_position` |
| 20 | u32 | `grid_n` (cells per side; grid is `grid_n × grid_n`) |
| 24 | f32 | `cell_size` (world units per cell) |
| 28 | u32 | `chunk_count` (must match TERRAIN section) |

**3 — TERRAIN** (chunked indexed meshes)

| Off | Type | Field |
|---|---|---|
| 0 | u32 | `chunk_count` (= TERRAIN_META.chunk_count) |

then `chunk_count` records, each:

| Rel. | Type | Field |
|---|---|---|
| 0 | f32×3 | `origin` (chunk corner, world) |
| 12 | u32 | `vert_count` |
| 16 | u32 | `idx_count` (multiple of 3) |
| 20 | f32×(3·V) | `vertices` |
| … | f32×(3·V) | `normals` (unit length) |
| … | u32×V | `material_ids` (per vertex; catalog id, §6) |
| … | u32×I | `indices` (into this chunk's vertices, CCW front faces) |

Presence: TERRAIN sections are emitted **in the first snapshot after init and whenever `world_version` increments** (sim tracks generation state internally); in all other snapshots the section is absent ⇒ adapter keeps existing meshes. TERRAIN_META is emitted every snapshot and its `chunk_count` **persists** across suppressed-TERRAIN snapshots (describes the cached terrain; must not be zeroed). All other sections are emitted every snapshot.

**4 — OCEAN** (32 bytes, 8×f32)

`sea_level, amplitude, frequency, steepness, dir_x, dir_z, speed, phase`

Wave displacement contract: `SCR-LIB-MATH-GERSTNER` (`lib/202_Math/Gerstner/101_definition.md`). Godot displaces vertices for display only; sim-side heights are authoritative for player grounding.

**5 — SKY** (64 bytes, 16×f32; schema 3, [milestone_0004 §1.1](../../../../applications/godot/program_increments/v0.0.1/milestone_0004_atmosphere-weather/spec.md))

| Off | Type | Field |
|---|---|---|
| 0 | f32 | `time_of_day_hours` (0..24, simulation-time-derived) |
| 4 | f32 | `sun_azimuth` (rad; spawn-facing arc, §6) |
| 8 | f32 | `sun_elevation` (rad) |
| 12 | f32 | `fog_density` (derived, §6 — never a display literal) |
| 16 | f32 | `fog_color_r` |
| 20 | f32 | `fog_color_g` |
| 24 | f32 | `fog_color_b` |
| 28 | f32 | `sun_intensity` (≥ 0; 0 at night) |
| 32 | f32 | `sun_color_r` (palette tier, §6) |
| 36 | f32 | `sun_color_g` |
| 40 | f32 | `sun_color_b` |
| 44 | f32 | `cloud_cover` (0..1, weather subject) |
| 48 | f32 | `precipitation` (0..1, weather subject) |
| 52 | f32 | `wind_x` (u/s, world frame) |
| 56 | f32 | `wind_z` (u/s, world frame) |
| 60 | f32 | `wetness` (0..1, accumulated) |

The section is exactly 64 bytes; `fog_density`/`fog_color_*` are the atmosphere derivation over the weather inputs (§6), and `wind_x`/`wind_z`/`wetness` mirror the weather subject (gust multiplier included). Sky-dome zenith/horizon colors are sim-side palette authority (A01_Render/Sky §2) consumed by the adapter through the SKY fog/sun colors — they are NOT separate wire fields; the adapter derives the dome gradient from `fog_color_*` + `sun_color_*` (sprint-03 adapter work).

**6 — MATERIALS** (4 + 36·N bytes)

| Off | Type | Field |
|---|---|---|
| 0 | u32 | `count` |

then `count` records, each (36 bytes):

| Rel. | Type | Field |
|---|---|---|
| 0 | u32 | `material_id` (catalog semantic id) |
| 4 | f32×3 | `albedo` |
| 16 | f32 | `roughness` |
| 20 | f32×3 | `emissive` |
| 32 | f32 | `opacity` |

Material records MUST be derivable from `lib/A01_Render/Material/materials_catalog.json` (milestone spec invariant 5). IDs used by the core slice (from the catalog / voxel codes): basalt, sand, ash, obsidian, pumice, sulfur, lava (active since 0003), water; foliage (successor) — resolved to stable u32 ids defined in `src/mojo/materials/`.

**7 — VOLCANO** (32 bytes; schema 2, [milestone_0003 §3.2](../../../../applications/godot/program_increments/v0.0.1/milestone_0003_volcano/spec.md))

| Off | Type | Field |
|---|---|---|
| 0 | f32 | `center_x` (world-frame caldera/lake center) |
| 4 | f32 | `center_z` |
| 8 | f32 | `radius` (lava lake radius, u; > 0) |
| 12 | f32 | `lake_level` (lava surface height, world y) |
| 16 | f32 | `emissive_intensity` (crust-factor radiance scalar, > 0) |
| 20 | f32 | `crust_fraction` (C ∈ [0,1]; `SCR-LIB-RENDER-VOLCANO` §2.1) |
| 24 | f32 | `glow_intensity` (= `emissive_intensity · night_factor`; §6) |
| 28 | u8 | `effusion_state` (0 = dormant, 1 = effusing) |
| 29 | u8×3 | `pad` = 0 (section is exactly 32 bytes) |

All VOLCANO state is sim-owned (`VolcanoSubject`): level, emissive, crust, effusion, glow are pure functions of `(seed, simulation_tick, world state)`; display never derives them (AP-11). `effusion_state > 1` and nonzero pad MUST be rejected loudly on decode.

**8 — PLUME** (32 bytes, 8×f32; schema 2, milestone_0003 §3.2)

| Off | Type | Field |
|---|---|---|
| 0 | f32 | `origin_x` (world-frame emission origin) |
| 4 | f32 | `origin_y` |
| 8 | f32 | `origin_z` |
| 12 | f32 | `rate` (particles/s; `0` ⇒ emitter idle) |
| 16 | f32 | `initial_velocity` (u/s, `w0 ≈ 8.5`, `SCR-LIB-RENDER-VOLCANO` §2.2) |
| 20 | f32 | `spread` (deg, emission cone half-angle) |
| 24 | f32 | `turbulence` (turbulence amount, display-side noise) |
| 28 | f32 | `lifetime` (s; must be > 0) |

PLUME carries **emission parameters only** — the GPU integrates particles for display (locked decision, milestone_0003 §1.1). `rate < 0` and `lifetime <= 0` MUST be rejected loudly on decode.

## 5. Input uplink (`scr_input_batch`, 20 bytes packed)

| Off | Type | Field |
|---|---|---|
| 0 | f32 | `move_x` (−1..1 strafe) |
| 4 | f32 | `move_y` (−1..1 forward) |
| 8 | f32 | `look_dx` (yaw delta, rad) |
| 12 | f32 | `look_dy` (pitch delta, rad) |
| 16 | u8 | `jump` |
| 17 | u8 | `sprint` |
| 18 | u8 | `action_primary` |
| 19 | u8 | `action_secondary` |

Semantics: Godot accumulates look deltas per rendered frame and resets them; booleans are level-triggered for the frame. The sim applies the batch to every fixed tick executed within the `scr_sim_step` call that carries it.

## 6. Locomotion parameter table (normative defaults)

AP-7: tunables live here (and are mirrored in `applications/godot/docs/04_simulation_engine.md` §parameter table) — never as magic literals scattered in code.

| Parameter | Value | Unit |
|---|---|---|
| fixed tick rate | 60 | Hz |
| frame dt clamp | 0.05 | s |
| walk speed | 4.25 | u/s |
| sprint speed | 8.0 | u/s |
| jump velocity | 5.8 | u/s |
| gravity | −10.0 | u/s² |
| mouse-look pitch clamp | ±1.45 | rad |
| eye height (stand) | 1.7 | u |
| swim speed factor | 0.65 | × |

Volcano / plume / glow (schema 2; AP-7 — single home `applications/godot/src/mojo/sim/parameters.mojo`, mirrored here):

| Parameter | Value | Unit |
|---|---|---|
| `LAVA_EMISSIVE_CORE` (scalar of E_core = (1.0, 0.72, 0.12), bright channel) | 1.0 | — |
| `LAVA_EMISSIVE_CRUST` (scalar of E_crust = (0.12, 0.04, 0.02), bright channel) | 0.12 | — |
| `LAVA_CRUST_DORMANT` (crust fraction C, state 0) | 0.85 | — |
| `LAVA_CRUST_EFFUSING` (crust fraction C, state 1) | 0.15 | — |
| `EFFUSION_TICK_STEP` (seeded PRNG draw cadence; AP-12) | 300 | ticks (5 s @ 60 Hz) |
| `EFFUSION_ACTIVE_PROBABILITY` (P(state = 1) per draw) | 0.35 | — |
| `PLUME_RATE_DORMANT` (state 0 ⇒ idle emitter) | 0.0 | 1/s |
| `PLUME_RATE_EFFUSING` (state 1) | 60.0 | 1/s |
| `PLUME_VELOCITY` (`w0`, `SCR-LIB-RENDER-VOLCANO` §2.2) | 8.5 | u/s |
| `PLUME_SPREAD` (emission cone half-angle) | 15.0 | deg |
| `PLUME_TURBULENCE` (display-side noise amount) | 0.35 | — |
| `PLUME_LIFETIME` (particle lifetime; must be > 0) | 6.0 | s |
| `GLOW_NIGHT_MAX_FACTOR` (night_factor cap) | 1.0 | × |
| `GLOW_NIGHT_ELEVATION_REF` (elevation depth where night_factor saturates; = `SUN_ELEVATION_MAX`) | 1.2 | rad |
| `VOLCANO_LAKE_RADIUS_FALLBACK` (no CALDERA_LAKE columns; = `CALDERA_LAKE_RADIUS`) | 20.0 | u |

Glow derivation (milestone_0003 §3.3): `glow_intensity = emissive_intensity · night_factor(sun_elevation)`, `night_factor` a pure function of the existing `AtmosphereSubject`: 0 for elevation ≥ 0, else `min(−elevation / GLOW_NIGHT_ELEVATION_REF, GLOW_NIGHT_MAX_FACTOR)`.

Solar arc / palette / fog / weather (schema 3, milestone_0004; AP-7 — single home `applications/godot/src/mojo/sim/parameters.mojo`, mirrored here):

| Parameter | Value | Unit |
|---|---|---|
| `SUN_ELEVATION_MAX` | 1.2 | rad |
| `SUN_INTENSITY_NOON` | 1.0 | — |
| `SUN_ENERGY_HORIZON` (tier energy at the horizon) | 0.75 | × |
| `SUN_ELEVATION_NOON_DEG` (energy reaches 1.0 here) | 45.0 | deg |
| `SKY_ELEV_NIGHT_DEG` / `SKY_ELEV_SUNSET_DEG` / `SKY_ELEV_DAWN_LOW_DEG` | −10 / −5 / 0 | deg |
| `SKY_ELEV_GOLDEN_DEG` / `SKY_ELEV_DAWN_HIGH_DEG` / `SKY_ELEV_WARM_DEG` / `SKY_ELEV_NOON_DEG` | 10 / 15 / 25 / 45 | deg |
| `FOG_DENSITY_BASE` | 0.0030 | 1/u |
| `FOG_COEF_CLOUD` / `FOG_COEF_PRECIP` / `FOG_COEF_BIAS` / `FOG_COEF_NIGHT` | 0.0030 / 0.0040 / 0.0010 / 0.0015 | 1/u per unit |
| `FOG_COLOR_CLOUD_MIX` / `FOG_COLOR_PRECIP_MIX` / `FOG_COLOR_NIGHT_MIX` | 0.60 / 0.70 / 0.85 | × |
| `WEATHER_TRANSITION_TICK_STEP` (draw cadence; AP-12) | 1800 | ticks (30 s @ 60 Hz) |
| `WEATHER_BLEND_TICKS` (Hermite blend window) | 900 | ticks (15 s @ 60 Hz) |
| `WETNESS_RISE_RATE` (at precipitation = 1) | 0.15 | 1/s |
| `WETNESS_DECAY_RATE` (dry-out) | 0.01 | 1/s |
| `WIND_GUST_FRACTION` / `WIND_GUST_PERIOD_TICKS` / `WIND_MAX_SPEED` | 0.18 / 960 / 12.0 | × / ticks / u/s |
| `CLOUD_PLANE_ALTITUDE` (display cloud plane) | 400.0 | m |

Derivations (all pure functions of simulation state — AP-11/AP-15):

- **Solar arc (§4.3 SKY 0..8, single authority AP-16):** `elevation(h) = SUN_ELEVATION_MAX · sin(π(h − 6)/12)` (exact zeros at 06:00/18:00); `azimuth(h) = spawn_yaw + π + π(h − 12)/12` folded to `[−π, π)` with horizontal direction `(sin az, cos az)` — the daytime arc lies inside the spawn-facing hemisphere (06:00 = facing − π/2, noon = facing, 18:00 = facing + π/2). `sun_intensity = SUN_INTENSITY_NOON · sin(elevation) · energy(elevation)` for elevation > 0, else 0; `energy` interpolates `SUN_ENERGY_HORIZON → 1.0` over `0° → SUN_ELEVATION_NOON_DEG`.
- **Palette tiers:** zenith / horizon / sun colors are piecewise-linear blends of the §6 `SKY_*` / `SUN_*` knot constants over elevation (linear between knots ⇒ continuous at every tier boundary); `FOG_*` clear/storm/night knot constants give `fog_color = lerp(lerp(clear, storm, min(1, 0.60·C + 0.70·P)), night, 0.85·night_factor)`.
- **Fog density:** `fog_density = FOG_DENSITY_BASE + FOG_COEF_CLOUD·C + FOG_COEF_PRECIP·P + FOG_COEF_BIAS·fog_bias + FOG_COEF_NIGHT·night_factor` — strictly increasing in cloud cover and precipitation (every coefficient > 0), clamped ≥ 0.
- **Weather machine:** profile draw (CLEAR / OVERCAST / MONSOON) every `WEATHER_TRANSITION_TICK_STEP` ticks from the world seed (splitmix64; AP-12 — no wall clock), Hermite-blended over `WEATHER_BLEND_TICKS` at each draw change; wetness integrates `WETNESS_RISE_RATE·P·dt` up and `WETNESS_DECAY_RATE·dt` down in `[0, 1]`; wind = profile vector × `(1 + WIND_GUST_FRACTION·sin(2π·tick/WIND_GUST_PERIOD_TICKS + phase))`, clamped to `WIND_MAX_SPEED`. Weather feeds only the atmosphere derivation — never display (AP-11).

## 7. Versioning & compatibility

- `SCR_SIM_ABI_VERSION` — symbol/semantic contract of the C functions. Mismatch ⇒ adapter refuses to start.
- `SCR_SIM_SCHEMA_VER` — byte layout above. Mismatch ⇒ adapter refuses to start (negative test: `tests/test_schema_mismatch.sh`, stub reports `SCR_SIM_SCHEMA_VER + 1` derived from the header).
- Additive changes require a schema bump; adapters MUST NOT guess unknown layouts.
- **Sibling rebasing rule (milestone_0003 §3.5):** milestones 0003 / 0004 / 0005 are independent siblings under 0002. Whichever executes later MUST rebase on the then-current schema, fixture, adapter, and contract state — applying its own "+1 over then-current" bump — not on the layouts written in any one spec.

## 8. Provider conformance notes

- The adapter performs representation conversion only (decode → Godot nodes). No scene semantics, no world mutation, no gameplay decisions (`lib/804_Application` Port→Adapter→Provider; `docs/05_provider_boundary.md`).
- Decode errors MUST be reported loudly (log + refuse frame), never silently coerced.
