# 104 — Contract: SCR Simulation ⇄ Godot Adapter Boundary

**Provider:** `providers/render/graphics/godot`
**Status:** Normative
**Owner milestone:** [applications/godot v0.0.1 / milestone 0003](../../../../applications/godot/program_increments/v0.0.1/milestone_0003_volcano/spec.md) (baseline: [milestone 0002](../../../../applications/godot/program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md))
**C ABI header:** [`adapter/scr_godot_abi.h`](adapter/scr_godot_abi.h) (single source of truth for symbol names, struct layouts, error codes)
**Schema version:** `6` — 1 → 2 in [milestone_0003](../../../../applications/godot/program_increments/v0.0.1/milestone_0003_volcano/spec.md) §3.5 (additive sections `7 VOLCANO`, `8 PLUME`); 2 → 3 in [milestone_0004](../../../../applications/godot/program_increments/v0.0.1/milestone_0004_atmosphere-weather/spec.md) §1.1 (SKY 32 → 64 B); 3 → 4 in [milestone_0005](../../../../applications/godot/program_increments/v0.0.1/milestone_0005_shoreline-fidelity/spec.md) §3.6 (new section `9 SHORE_FOAM` + TERRAIN vertex payload semantic reframe); 4 → 5 in [milestone_0006](../../../../applications/godot/program_increments/v0.0.1/milestone_0006_ecology/spec.md) §1.1 (new sections `10 FLORA` emission-gated + `11 FAUNA` every snapshot; sections 1–9 byte-identical); 5 → 6 in [milestone_0007](../../../../applications/godot/program_increments/v0.0.1/milestone_0007_editing-physics/spec.md) §1.1 (new sections `12 HOTBAR`, `13 TARGET`, `14 RIGID_BODIES`, all every snapshot; sections 1–11 byte-identical; **C ABI 1 → 2** — new symbol `scr_edit_submit`)
**C ABI version:** `SCR_SIM_ABI_VERSION = 2` (1 → 2 in milestone_0007: symbol set grows by `scr_edit_submit`; the eight v1 semantics unchanged)

---

## 1. Purpose

Define the only state channels between the Mojo simulation core (semantic consumer) and the Godot GDExtension adapter (presentation provider):

- **Downlink:** `RenderSnapshot` — immutable projection of world state, serialized to a byte buffer.
- **Uplink:** `scr_input_batch` — raw player intent; the sim integrates it.
- **Uplink:** `scr_edit_batch` via `scr_edit_submit` — edit/hotbar intent only (`{op, select_slot}`); the sim resolves cell and material (milestone_0007 §3.2).

Invariant: projection MUST NOT mutate world state; the adapter MUST NOT make semantic decisions (`milestone_0002` spec §6).

## 2. Transport

In-process for this milestone: GDExtension adapter `dlopen`s the Mojo shared library (`libscr_sim.so`) and calls the C ABI functions directly. The contract is transport-agnostic; a later IPC transport must carry the same byte stream (`milestone_0002` spec §9).

## 3. C ABI summary

| Symbol | Semantics |
|---|---|
| `scr_sim_init(seed)` | First call; initializes Mojo runtime + world; 0 = ok |
| `scr_sim_shutdown()` | Tear down; safe after init |
| `scr_sim_abi_version()` | must equal `SCR_SIM_ABI_VERSION` (2) |
| `scr_sim_schema_version()` | must equal `SCR_SIM_SCHEMA_VER` (6) |
| `scr_sim_step(dt, input*)` | Accumulate `dt`; run 0..n fixed ticks @ 60 Hz; input applied per executed tick; returns ticks run (≥0) or `SCR_ERR_*` |
| `scr_sim_snapshot_size()` | Size of snapshot from most recent successful step |
| `scr_sim_snapshot_write(buf, cap)` | Serialize; returns bytes written or `SCR_ERR_BUF_SMALL` etc. |
| `scr_edit_submit(batch*)` | Queue one `scr_edit_batch` (ABI 2); select applies immediately, op enqueued (≤ 1 consumed per fixed tick); returns 0 / `SCR_ERR_NOT_INIT` / `SCR_ERR_BAD_STATE` / `SCR_ERR_QUEUE_FULL` |

**Fixed tick:** `1/60 s`. **Determinism:** seed + input sequence + `dt = 1/60` per call ⇒ byte-identical snapshot sequence.

**Adapter startup rejection:** refuse to run when `scr_sim_abi_version() != SCR_SIM_ABI_VERSION || scr_sim_schema_version() != SCR_SIM_SCHEMA_VER` (negative test required by exit criteria).

## 4. Snapshot binary schema (version 6)

All fields **little-endian**. `f32`/`u32`/`u8` natural alignment; no implicit padding (all offsets documented). Offsets are bytes from snapshot start.

**Schema 1 → 2 migration (milestone_0003 §3.5):** the envelope `schema_version` field is now `2`; sections **1–6 are byte-identical to schema 1** (tables below unchanged); sections `7 VOLCANO` and `8 PLUME` are added; `section_count` for a full snapshot is `8` (was `6`). Schema-1 readers MUST refuse schema-2 bytes via the startup gate (§3/§7) — they must never guess unknown layouts.

**Schema 2 → 3 migration (milestone_0004 §1.1):** the envelope `schema_version` field is now `3`; sections 1–4 and 6–8 are byte-identical to schema 2 (tables below unchanged); **section 5 SKY grows from 32 bytes (8×f32) to 64 bytes (16×f32)** — its first 8 fields keep their schema-2 offsets (0..31), fields 8..15 append the sun-color triple, weather inputs and wetness (§4.3). `section_count` for a full snapshot stays `8`. Schema-1 and schema-2 readers MUST refuse schema-3 bytes via the startup gate (§3/§7).

**Schema 3 → 4 migration (milestone_0005 §3.6):** the envelope `schema_version` field is now `4`. Two coordinated changes require this bump (AP-21): **(a) new section `9 SHORE_FOAM`** — `section_count` for a full snapshot grows from `8` to `9`, emitted **every snapshot** (the shore-foam field evolves with wave phase; suppressing it would freeze the surf line); **(b) TERRAIN per-vertex payload semantic reframe** — the per-vertex record keeps its exact 4-byte stride but its meaning changes from a single `u32 material id` to the tuple `(u8 material_id, u8 blend_id, u8 blend_weight, u8 pad)` (§4.3 §3). Sections 1–2 and 4–8 are byte-identical to schema 3; the TERRAIN section is *stride-neutral* (same byte count and offsets for every other field), which is precisely why it is a **silent-if-unversioned meaning change**: schema-3 and schema-4 TERRAIN bytes differ only in tuple interpretation. Schema-1/2/3 readers MUST refuse schema-4 bytes via the startup gate (§3/§7), and the adapter decode MUST switch on schema, never guess (AP-21).

**Schema 4 → 5 migration (milestone_0006 §1.1 sibling rebase):** the envelope `schema_version` field is now `5`. Two coordinated changes require this bump: **(a) new section `10 FLORA`** — `section_count` for a full snapshot grows accordingly, emitted under the **same presence rule as TERRAIN** (first snapshot after init, then whenever `world_version` increments — static population, no per-tick re-send; §4.3); **(b) new section `11 FAUNA`** — emitted **every snapshot** (the flock moves every tick; suppressing it would freeze the birds). A full snapshot therefore has `section_count = 11` (10 when TERRAIN and FLORA are both suppressed in the same non-regeneration snapshot). Sections 1–9 are byte-identical to schema 4. Symbol set unchanged. Schema-1/2/3/4 readers MUST refuse schema-5 bytes via the startup gate (§3/§7).

**Schema 5 → 6 migration (milestone_0007 §1.1):** the envelope `schema_version` field is now `6`. Two coordinated changes require this bump: **(a) new section `12 HOTBAR`** (44 B fixed) and **new section `14 RIGID_BODIES`** (`4 + 36·count` B) — both emitted **every snapshot**; **(b) new section `13 TARGET`** (32 B fixed) — emitted **every snapshot** (the sim-owned raycast is recomputed per snapshot from the current player pose). A full snapshot therefore has `section_count = 14` (12 when TERRAIN and FLORA are both suppressed in the same non-regeneration snapshot). Sections 1–11 are byte-identical to schema 5. **C ABI bumps 1 → 2** (§3): new symbol `scr_edit_submit` + new 4-byte uplink struct `scr_edit_batch` (§5.1); the eight v1 symbols keep their signatures. Schema-1..5 readers MUST refuse schema-6 bytes via the startup gate (§3/§7).

### 4.1 Envelope (48 bytes, always present)

| Off | Type | Field | Notes |
|---|---|---|---|
| 0 | u32 | `magic` | `0x53524353` (bytes `S C R S`) |
| 4 | u32 | `schema_version` | = 6 |
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

Sections are emitted in id order 1,2,…,14 (ascending section id). Sections 1, 2, 4, 5, 6, **7, 8, 9, 11, 12, 13, 14** are emitted **every snapshot**; section 3 (TERRAIN) and section 10 (FLORA) follow the presence rule in §4.3 (identical tracker: first snapshot after init, then on `world_version` change).

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
| … | record×V | `blend_tuples` (per vertex, 4 bytes each — schema 4, below) |
| … | u32×I | `indices` (into this chunk's vertices, CCW front faces) |

**Schema 4 per-vertex tuple (stride-neutral reframe of the schema-3 `u32 material_ids`; milestone_0005 §3.6, AP-21):**

| Rel. | Type | Field | Notes |
|---|---|---|---|
| 0 | u8 | `material_id` | dominant material — stable catalog id (§6), same value the schema-3 `material_ids` slot carried |
| 1 | u8 | `blend_id` | blend partner catalog id; `== material_id` when `blend_weight == 0` (identity / no blend) |
| 2 | u8 | `blend_weight` | 0..255 ⇒ mix factor 0..1 toward `blend_id` (adapter `mix(albedo[dominant], albedo[blend], w/255)`) |
| 3 | u8 | `pad` | = 0; MUST be rejected loudly on decode |

Meaning change (documented even though the stride is identical — AP-21): schema 3 carried a lone `u32 material_id` per vertex; schema 4 interprets the same 4 bytes as the tuple above. The byte count of the TERRAIN section is unchanged (`20 + (3V + 3V + V + I)·4` per chunk), so byte-level size checks cannot distinguish the two schemas — only `schema_version` can. The **dominant** (`material_id`) still groups mesh surfaces by material exactly as schema 3 did; `blend_id`/`blend_weight` describe a synthesis-owned boundary feather band (blend pairs are restricted to the two adjacent biomes' permitted surface sets — Synthesis §2; lava columns are never blended).

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

**9 — SHORE_FOAM** (12 + 4·`grid_n²` bytes = 16 396 B at `grid_n = 64`; schema 4, [milestone_0005 §3.3](../../../../applications/godot/program_increments/v0.0.1/milestone_0005_shoreline-fidelity/spec.md))

| Off | Type | Field |
|---|---|---|
| 0 | u32 | `grid_n` (cells per side; == TERRAIN_META.grid_n, 64) |
| 4 | f32 | `cell_size` (world units per cell; == TERRAIN_META.cell_size) |
| 8 | f32 | `sea_level` (foam field datum, world y) |
| 12 | f32×(grid_n²) | `foam` — shore-foam field `F(x, z, t) ∈ [0, 1]`, row-major `iz · grid_n + ix`, cell centers, world xz aligned with the terrain grid |

Emitted **every snapshot** (foam evolves with wave phase — locked open decision, milestone_0005 §1.3.2). The field is computed sim-side, VERBATIM from the library formula `F = clamp(1 − Δy/d_foam, 0, 1)² · (0.6 + 0.4·sin(6Δy − 4t))` with `d_foam = 1.8 m` (`SCR-LIB-RENDER-WATER` §3, parameters in §6) over the terrain height field and the Gerstner authority (`src/mojo/sim/shore.mojo` is the formula's single home, AP-19). Deep water (`Δy ≥ 1.8`) and land above the max wave reach carry exactly 0. The adapter uploads the grid as an `ImageTexture`; the ocean shader **shades** this field for the shore band and never re-derives terrain-vs-water depth (AP-19). Crest whitecaps remain the disjoint 0002 display path (AP-22: `FOAM_JACOBIAN_THRESHOLD` / `FOAM_HEIGHT_THRESHOLD` in §6). Decode MUST reject: length ≠ `12 + 4·grid_n²`, `grid_n = 0` or `grid_n > 1024`, any value outside `[0, 1]` (§8 loud failure).

**10 — FLORA** (`4 + 24·count` bytes; schema 5, [milestone_0006 §1.1](../../../../applications/godot/program_increments/v0.0.1/milestone_0006_ecology/spec.md) sibling rebase of section 3's presence rule)

| Off (rel.) | Type | Field | Notes |
|---|---|---|---|
| 0 | u32 | `count` | instance count, `0 ≤ count ≤ 4096` (`FLORA_N_MAX`) |
| 4 | record×count | `instances` | 24 B per record, below |

Per record (24 bytes, exactly):

| Rel. | Type | Field |
|---|---|---|
| 0 | f32×3 | `position` (x,y,z); `y` = surface height at the anchor cell |
| 12 | f32 | `yaw` (radians) |
| 16 | f32 | `scale` (uniform, `> 0`) |
| 20 | u32 | `species_id` (1..7 — `materials/catalog.mojo` `SPECIES_*`, single-sourced to the Synthesis §3 feature vocabulary; `0` never emitted) |

Pose only: no per-instance animation phase (adapter runs display-side motion on `TIME` — AP-12). Species → display material resolves through the species → `materials_catalog.json` `id` table in `materials/catalog.mojo`; the adapter MUST NOT invent per-species colours (AP-14).

Presence: FLORA sections are emitted **in the first snapshot after init and whenever `world_version` increments**, tracked exactly like TERRAIN (§4.3 §3 presence rule); in all other snapshots the section is absent ⇒ adapter keeps the existing flora MultiMesh. A decoded `count` larger than `FLORA_N_MAX`, a section byte count other than `4 + 24·count`, an out-of-range `species_id`, or a non-positive `scale` MUST fail loudly (§8).

**11 — FAUNA** (`4 + 20·count` bytes; schema 5, milestone_0006 §1.1)

| Off (rel.) | Type | Field | Notes |
|---|---|---|---|
| 0 | u32 | `count` | active birds, `0 ≤ count ≤ 64` (`FLOCK_N_MAX`) |
| 4 | record×count | `birds` | 20 B per record, below |

Per record (20 bytes, exactly):

| Rel. | Type | Field |
|---|---|---|
| 0 | f32×3 | `position` (x,y,z) world units |
| 12 | f32 | `yaw` (radians, heading) |
| 16 | u8 | `species_id` (0 = seabird) |
| 17 | u8×3 | `pad` = 0; MUST be rejected loudly on decode |

Emitted **every snapshot** (flock state is tick-dependent). Records are emitted in ascending sim slot order (deterministic). A `count` larger than `FLOCK_N_MAX`, a byte count other than `4 + 20·count`, or nonzero pad MUST fail loudly (§8).

**12 — HOTBAR** (44 bytes fixed; schema 6, [milestone_0007 §3.3](../../../../applications/godot/program_increments/v0.0.1/milestone_0007_editing-physics/spec.md))

| Off | Type | Field | Notes |
|---|---|---|---|
| 0 | u32 | `count` | slot count, always `9` (`HOTBAR_SLOT_COUNT`) |
| 4 | u32 | `selected_index` | 0-based selected slot; `< count` |
| 8 | u32×9 | `material_ids[i]` | stable catalog id per slot (`materials_catalog.json` `catalog_index`; §6 vocabulary) |

Emitted **every snapshot**. The slot table is the sim's resolved parameter table (hotbar.mojo) — the client selects by slot only (§5.1); material identity reaches the client only through this section (AP-13). A `count ≠ 9`, a `selected_index ≥ count`, or a section byte count other than `44` MUST fail loudly (§8).

**13 — TARGET** (32 bytes fixed; schema 6, milestone_0007 §3.3)

| Off | Type | Field | Notes |
|---|---|---|---|
| 0 | u8 | `hit` | 1 = terrain hit, 0 = miss (all remaining fields MUST be 0) |
| 1 | u8×3 | `pad` = 0 | MUST be rejected loudly on decode |
| 4 | u32 | `material_id` | stable catalog id of the hit surface (0 on miss) |
| 8 | f32×3 | `hit_position` | world-frame ray hit point |
| 20 | u32 | `cell_x` | targeted column, grid x |
| 24 | u32 | `cell_lattice_y` | targeted column surface cell, lattice y |
| 28 | u32 | `cell_z` | targeted column, grid z |

The ray is owned by the sim: eye = player position + `EYE_HEIGHT`, direction from `(yaw, pitch)` (yaw 0 faces −Z), marched `RAY_RANGE = 32` u at `RAY_STEP = 0.25` u with 8 bisection refinements, against the height field (§6). Emitted **every snapshot** (recomputed from the current pose — pure projection, no stored ray). A miss drives the HUD "SKY / AIR" readout (`SCR-LIB-RENDER-HUD` §2.2). Decode MUST reject: length ≠ 32, `hit > 1`, nonzero pad, or any nonzero field on a miss (§8).

**14 — RIGID_BODIES** (`4 + 36·count` bytes; schema 6, milestone_0007 §3.3/§3.5)

| Off (rel.) | Type | Field | Notes |
|---|---|---|---|
| 0 | u32 | `count` | rigid props, `0 ≤ count ≤ 16` (`PROP_N_MAX`) |
| 4 | record×count | `bodies` | 36 B per record, below |

Per record (36 bytes, exactly):

| Rel. | Type | Field | Notes |
|---|---|---|---|
| 0 | f32×3 | `position` (x,y,z) | world frame |
| 12 | f32×3 | `euler` (rx,ry,rz) | always 0 — minimal model has no angular dynamics (0007 §3.5) |
| 24 | u32 | `shape` | 0 = box, 1 = sphere |
| 28 | f32 | `size` | box: uniform half-extent; sphere: radius |
| 32 | u32 | `material_id` | stable catalog id (§6) |

Emitted **every snapshot** (props integrate every tick). Records in ascending sim slot order (deterministic — 0007 §3.5). Terrain is the static body: contact is resolved sim-side (penetration ⇒ clamp + zero restitution). Decode MUST reject: `count > 16`, a byte count other than `4 + 36·count`, or `shape > 1` (§8).

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

Semantics: Godot accumulates look deltas per rendered frame and resets them; booleans are level-triggered for the frame. The sim applies the batch to every fixed tick executed within the `scr_sim_step` call that carries it. The input batch carries **locomotion intent only** — edits ride `scr_edit_batch` (§5.1).

### 5.1 Edit uplink (`scr_edit_batch`, 4 bytes packed; ABI 2, milestone_0007 §3.2)

| Off | Type | Field | Notes |
|---|---|---|---|
| 0 | u8 | `op` | 0 = none, 1 = dig, 2 = place |
| 1 | u8 | `select_slot` | 0 = no change, 1..9 = select hotbar slot (applied immediately); other values rejected |
| 2 | u16 | `reserved` | = 0; nonzero ⇒ `SCR_ERR_BAD_STATE` |

The client NEVER names materials or cells: `op=place` uses the currently selected slot's material, and the edited cell comes from the sim-owned raycast of the consuming tick's player pose (§4.3 §13, AP-12). Ops append to a FIFO (≤ `EDIT_QUEUE_MAX = 16` pending) and are consumed **at most one per fixed tick** in submit order; `scr_edit_submit` returns `SCR_ERR_QUEUE_FULL (−5)` — atomically, so a rejected batch applies neither its select nor its op. Determinism: identical `(seed, input, edit)` sequences ⇒ identical world (0007 invariant 4).

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

Shore foam + boundary blending (schema 4, milestone_0005; AP-7 — single home `applications/godot/src/mojo/sim/parameters.mojo`, mirrored here):

| Parameter | Value | Unit |
|---|---|---|
| `FOAM_DEPTH_M` (`d_foam` of `SCR-LIB-RENDER-WATER` §3; shore formula `clamp(1 − Δy/d_foam, 0, 1)² · (0.6 + 0.4·sin(6Δy − 4t))`) | 1.8 | m (u) |
| `FEATHER_WIDTH_CELLS` (blend band half-width around a synthesis material boundary; base ramp `(FEATHER − d)/FEATHER`) | 4 | cells |
| `BLEND_DITHER_AMP` (deterministic noise dither added to the ramp before clamping; `< ramp step / 2` keeps the quantised ramp strictly monotonic) | 0.10 | × |
| `BLEND_DITHER_FREQUENCY` (dither gradient-noise cycles per world unit; same seeded noise family as 0002 synthesis) | 0.18 | 1/u |

Flora placement + seabird flock (schema 5, milestone_0006; AP-7 — single home `applications/godot/src/mojo/sim/parameters.mojo`, mirrored here):

| Parameter | Value | Unit |
|---|---|---|
| `FLORA_N_MAX` (hard instance cap) | 4096 | instances |
| `FLORA_HEIGHT_EPS` (window: `height ≥ SEA_LEVEL + ε`) | 0.05 | u |
| `FLORA_BEACH_SLOPE_CAP` / `FLORA_SLOPE_CAP` (per-band max `‖∇h‖`; beach profile measures 0.52..1.02 so the cap admits the band) | 1.00 / 1.00 | u/u |
| `FLORA_DENSITY_BEACH` / `FLORA_DENSITY_SLOPE` (P(host) per cell) | 0.10 / 0.12 | — |
| `FLORA_WEIGHT_PALM_CLUSTER` (BEACH; remainder → PALM_SOLO) | 0.35 | — |
| `FLORA_WEIGHT_CANOPY_TREE` / `FLORA_WEIGHT_CANOPY_CLUSTER` / `FLORA_WEIGHT_SHRUB` / `FLORA_WEIGHT_FERN_CARPET` (VOLCANIC_SLOPE; rows sum to 1) | 0.20 / 0.10 / 0.35 / 0.35 | — |
| `FLORA_SCALE_MIN` / `FLORA_SCALE_MAX` (uniform instance scale range) | 0.80 / 1.35 | × |
| `FLOCK_N_MAX` / `FLOCK_N_INIT` (hard cap / slots active at init) | 64 / 32 | birds |
| `FLOCK_WAYPOINT_RADIUS` / `FLOCK_WAYPOINT_JITTER` / `FLOCK_WAYPOINT_PERIOD_TICKS` (orbit ring) | 100.0 / 6.0 / 14400.0 | u / u / ticks |
| `FLOCK_BOUND_RADIUS` (ocean/beach bound — despawn + respawn trigger) | 110.0 | u |
| `FLOCK_MIN_ALTITUDE` / `FLOCK_MAX_ALTITUDE` (avoidance window above surface) | 8.0 / 90.0 | u |
| `FLOCK_SPEED_CRUISE` / `FLOCK_SPEED_MIN` / `FLOCK_SPEED_MAX` (speed clamp) | 9.0 / 4.0 / 14.0 | u/s |
| `FLOCK_W_SEEK` / `FLOCK_W_ALIGN` / `FLOCK_W_COHERE` / `FLOCK_W_SEPARATE` / `FLOCK_W_AVOID` (rule weights) | 0.80 / 0.50 / 0.40 / 20.0 / 2.00 | — |
| `FLOCK_ALIGN_RADIUS` / `FLOCK_COHERE_RADIUS` / `FLOCK_SEPARATE_RADIUS` | 14.0 / 18.0 / 6.0 | u |
| `FLOCK_SEPARATION_MIN` (hard pairwise floor, test oracle) | 2.0 | u |

Flora placement band table (0006 §1.1; `feature_for_column` in `sim/flora.mojo`, pure integer hash over `(seed, x, z)` — no RNG stream): `BEACH → {PALM_CLUSTER, PALM_SOLO}`; `VOLCANIC_SLOPE → {CANOPY_TREE, CANOPY_CLUSTER, SHRUB, FERN_CARPET}`; `CALDERA_RIM / CALDERA_LAKE / SHALLOW_WATER / DEEP_OCEAN → none` — each gated by the elevation window and the per-band slope cap above. Flock rules (0006 §1.1): waypoint seek, alignment, cohesion, separation, terrain/ocean avoidance from the heightfield, speed clamp; fixed slots, bound violation ⇒ despawn + deterministic respawn from `(seed, slot, respawn_count)`, `count ≤ FLOCK_N_MAX` always.

Editing, raycast + rigid props (schema 6, milestone_0007; AP-7 — single home `applications/godot/src/mojo/sim/parameters.mojo`, mirrored here):

| Parameter | Value | Unit |
|---|---|---|
| `EDIT_QUEUE_MAX` (edit FIFO capacity; `SCR_ERR_QUEUE_FULL` when exceeded) | 16 | ops |
| `EDIT_CELL_STEP_U` (dig/place vertical step) | 1.0 | u |
| `HOTBAR_SLOT_COUNT` / `HOTBAR_SLOT_MIN` (wire `count` / `select_slot` range) | 9 / 1 | — |
| `RAY_RANGE` (sim ray-march range; TARGET §4.3 §13) | 32.0 | u |
| `RAY_STEP` (march resolution) | 0.25 | u |
| `RAY_REFINE_ITERS` (bisection refinements in the hit bracket) | 8 | — |
| `PROP_N_MAX` / `PROP_N_INIT` (hard cap / deterministic beach anchors) | 16 / 4 | bodies |
| `PROP_BOX_HALF_U` (box half-extent; spawn size) | 0.5 | u |
| `PROP_TANGENTIAL_DAMPING` (ground-contact tangential velocity factor) | 0.90 | × |

Display-only crest thresholds (schema 1, unchanged by milestone_0005 — AP-22: shore foam ≠ crest foam): `FOAM_JACOBIAN_THRESHOLD = 0.65` (J < 0.65 ⇒ whitecap), `FOAM_HEIGHT_THRESHOLD = 0.7` (normalized height > 0.7).

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

- `SCR_SIM_ABI_VERSION` — symbol/semantic contract of the C functions (now `2`: `scr_edit_submit` added, milestone_0007). Mismatch ⇒ adapter refuses to start.
- `SCR_SIM_SCHEMA_VER` — byte layout above. Mismatch ⇒ adapter refuses to start (negative test: `tests/test_schema_mismatch.sh`, stub reports `SCR_SIM_SCHEMA_VER + 1` derived from the header).
- Additive changes require a schema bump; adapters MUST NOT guess unknown layouts.
- **Sibling rebasing rule (milestone_0003 §3.5):** milestones 0003 / 0004 / 0005 / 0006 are independent siblings under 0002. Whichever executes later MUST rebase on the then-current schema, fixture, adapter, and contract state — applying its own "+1 over then-current" bump — not on the layouts written in any one spec.

## 8. Provider conformance notes

- The adapter performs representation conversion only (decode → Godot nodes). No scene semantics, no world mutation, no gameplay decisions (`lib/804_Application` Port→Adapter→Provider; `docs/05_provider_boundary.md`).
- Decode errors MUST be reported loudly (log + refuse frame), never silently coerced.
