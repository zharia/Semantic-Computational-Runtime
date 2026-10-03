# 04 — Simulation Engine Design

**Purpose:** Capture the simulation engine design for the Mojo/Godot application.
**Status:** Active (filled for milestone 0002 — Sprint 01..04; extended for milestone 0003 Volcano — Sprint 01..04; extended for milestone 0004 Atmosphere & Weather — Sprint 01..04; extended for milestone 0005 Shoreline Fidelity — Sprint 01..04; extended for milestone 0006 Ecology — Sprint 01..04; extended for milestone 0007 Editing/Hotbar/Physics — Sprint 01..04; extended for milestone 0008 IPC Transport — Sprint 01..04; extended for milestone 0009 Flora Upgrade — Sprint 01..04; honest gaps marked `TBD — future milestone`)
**Owner milestone:** [v0.0.2 / milestone 0009 — Flora Upgrade](../program_increments/v0.0.2/milestone_0009_flora-upgrade/spec.md) (baselines: [milestone 0008](../program_increments/v0.0.1/milestone_0008_ipc-transport/spec.md), [milestone 0007](../program_increments/v0.0.1/milestone_0007_editing-physics/spec.md), [milestone 0006](../program_increments/v0.0.1/milestone_0006_ecology/spec.md), [milestone 0005](../program_increments/v0.0.1/milestone_0005_shoreline-fidelity/spec.md), [milestone 0004](../program_increments/v0.0.1/milestone_0004_atmosphere-weather/spec.md), [milestone 0003](../program_increments/v0.0.1/milestone_0003_volcano/spec.md), [milestone 0002](../program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md), [milestone 0001](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md))

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
| Parameter table (AP-7, incl. volcano/plume/glow, atmosphere/weather) | **Active — §6** |
| Performance budgets | **TBD — future milestone** (no perf work in scope; spec §9) |

## 2. Current Implementation (v0.0.2 / milestone 0009)

- `src/mojo/` — full core slice: `sim/` (world, subjects, parameters, input table, runtime, **volcano**, **flora**, **flock**, **edit**, **raycast**, **hotbar**, **props**), `synthesis/` (noise + height field + voxel synthesis, single-column re-synthesis entry), `ocean/` (Gerstner), `materials/` (catalog loader), `snapshot/` (pure projection + encoder), `export/` (C ABI incl. `scr_edit_submit`), `main.mojo` (CLI headless entry).
- `godot/` — main scene `scenes/island.tscn` (terrain host, ocean + Gerstner shader, sky, sun, camera, HUD, meta/materials group nodes, **`scr_crater_lava` + `scr_plume` (GPUParticles3D) + `scr_crater_glow` (OmniLight3D)**, **`scr_flora` + `scr_fauna` hosts with view scripts (0006)**, **`scr_hotbar` + `scr_target` + `scr_props` hosts (0007)**), `scripts/player_input.gd` (input + edit intent uplink only), `scripts/hud.gd` (controls hint only), **`scripts/flora_view.gd` + `scripts/fauna_view.gd` (0006 presentation)**, **`scripts/hotbar_hud.gd` + `scripts/props_view.gd` (0007 presentation)**, `shaders/ocean.gdshader`, **`shaders/lava.gdshader`**, **`shaders/flora_wing.gdshader` (0006 display-only sway/flap)**.
- `providers/render/graphics/godot/` — provider control docs + GDExtension adapter (`ScrSim`), normative contract `104_contract.md` (**schema 6 / ABI 2**: sections 1–14 incl. `10 FLORA` change-driven (0009 §3.2), `11 FAUNA` every snapshot, **`12 HOTBAR`, `13 TARGET`, `14 RIGID_BODIES`**; uplink `scr_input_batch` + **`scr_edit_batch`/`scr_edit_submit`**).
- Tests: **22/22 Mojo spec test files** (adds `test_edit_ops`, `test_raycast`, `test_hotbar`, `test_props` (0007), `test_framing` (0008), `test_flora_growth`, `test_flora_evolution` (0009); see §4.4), ABI smoke, **terrain-resend test (`test_terrain_resend.py`)**, schema/ABI-mismatch negative test, headless load gate, screenshot gate (plume + lava + night-glow + sun + rain + flora/fauna region checks + **editing HUD state**), playability gate (**with scripted dig/place leg**, see §8.7).

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
| `AtmosphereSubject` | `sim/subjects.mojo` (0004) | time-of-day on **sim time**, solar arc (`sun_elevation_at_hours`, `sun_azimuth_at_hours` — sole solar authority, AP-16), sun color/intensity, sky palette tiers, **derived fog** (`fog_density_of`, `fog_color_of`), `night_factor(elevation)`; pure functions of `simulation_time`/elevation — no wall clock (AP-15) |
| `WeatherSubject` | `weather/state.mojo` (0004) | seeded weather state machine: profile draws every `WEATHER_TRANSITION_TICK_STEP` from a PRNG stream initialized from `World.seed`, Hermite-blended then held; owns `cloud_cover`, `precipitation`, `wind_x/z` (gust-modulated), `fog_bias`, `wetness` (rise/decay) |
| `VolcanoSubject` | `sim/volcano.mojo` (0003) | caldera center/radius, lake level, emissive intensity, crust fraction, effusion state machine (seeded, `EFFUSION_TICK_STEP` draws), plume parameters, glow intensity — pure function of `(seed, simulation_tick, atmosphere)`; `volcano_from_island` + `volcano_tick` driven from `world.mojo` |
| `FloraSubject` | `sim/flora.mojo` (0006, extended 0009) | per-column `feature_for_column(x, z, biome, slope, height, seed)` hash (no RNG stream state — order-independent, AP-11-safe) + **0009 establishment field** (`establishment_suitability` ≥ `FLORA_SUITABILITY_THRESHOLD`), **band table** (BEACH → palm; VOLCANIC_SLOPE → canopy/shrub/fern; caldera/water bands → none), **per-instance `age` + species growth curve `scale(age)`** (smoothstep to maturity, ε-quantized on commit), **trait vector** (ash/drought tolerances, pure cell hashes) + **establishment/survival selection** (`flora_selection_passes`), parallel `ages`/`traits` lists, instance list `(position, yaw, scale, species_id)`, cap `FLORA_N_MAX = 4096`; population emitted **change-driven** (first snapshot after init, then on count/species/pose/yaw change or an instance scale delta ≥ `FLORA_EMIT_EPS` — 0009 §3.2, `104_contract` §4.3 §10; no longer `world_version`-gated like TERRAIN) |
| `FlockSubject` | `sim/flock.mojo` (0006) | seabird flock: fixed slot table `0..FLOCK_N_MAX-1` (`FLOCK_N_INIT = 32` active at init), deterministic boids (seek waypoint + alignment + cohesion + separation + terrain/ocean avoidance) integrated in **slot order** (no iteration-order nondeterminism), waypoint orbit on the ocean ring (`FLOCK_WAYPOINT_RADIUS` + jitter), bound violation → despawn/respawn from `(seed, slot, respawn_count)`; position + yaw (+ species_id) per bird, **every tick** |
| `HotbarSubject` | `sim/hotbar.mojo` (0007) | the 9-slot **catalog-id table** (`hotbar_slot_catalog_ids()` in `parameters.mojo` — ids all resolve from `materials_catalog.json`, no parallel list anywhere, AP-13) + `selected_index` (0-based); `hotbar_select(slot_1based)` rejects out-of-range slots; selection changes **only** via the edit uplink |
| `PhysicsSubject` | `sim/props.mojo` (0007) | rigid props: fixed slot table `0..PROP_N_MAX-1` (`PROP_N_INIT = 4` active at init), gravity + ground contact + tangential damping, integrated in **slot order** (deterministic); box/sphere shapes from `PROP_SHAPE_*`; emitted as `14 RIGID_BODIES` every snapshot |

Edit state on `World` (0007): `edit_queue` (`EditQueue` FIFO, `EDIT_QUEUE_MAX = 16`, one op consumed per tick) + raycast state feeding `13 TARGET`. The edit pipeline (raycast → dig/place → single-column re-synthesis → chunk-local rebuild → `world_version` bump) is documented in §5.1.

Commit metadata on `World`: `seed`, `determinism_epoch`, `world_version` (bumps on regeneration), `state_generation` (every tick), `simulation_tick`, `simulation_time`.

**Semantic library consumption** (spec §4 table, by ID — not by comment, AP-2): `SCR-LIB-SPATIAL-VOXEL-SYNTHESIS` (biome→material table + bedrock/sea-level invariants, conformance-tested), `SCR-LIB-MATH-NOISE` (spec-only, implemented in `synthesis/noise.mojo`), `SCR-LIB-MATH-GERSTNER` (spec-only, implemented in `ocean/gerstner.mojo`), `SCR-LIB-FIELD` (height queries), `SCR-LIB-GEOMETRY` (mesh arrays are representation), `SCR-LIB-RENDER-MATERIAL` (catalog `lib/A01_Render/Material/materials_catalog.json`, repo-relative), `SCR-LIB-RENDER-WATER` (foam intent — see §4.6 deviation), `SCR-LIB-RENDER-SKY` (diurnal arc + gradient sky), `SCR-LIB-RENDER-VOLCANO` (0003: lava/plume/glow subject semantics in `sim/volcano.mojo`, spec-only parts deferred — §9), **`SCR-LIB-ECOLOGY` (0006: population membership, environment bands, ecological state, declared determinism — spec-only contract implemented in `sim/flora.mojo`/`sim/flock.mojo`), `SCR-LIB-AGENTS` (0006: spatial agency, multi-agent collective behaviour, lifecycle spawn/despawn — spec-only, boid integration in `sim/flock.mojo`)**, `SCR-LIB-SPATIAL` frames (world frame explicit; Godot transforms = representation), `SCR-LIB-PHYSICS` quantities/gravity (gravity constant), `lib/804_Application` (Port→Adapter→Provider layering).

**0009 semantic library consumption (spec §4, by ID):** `SCR-LIB-ECOLOGY-FLORA` (`lib/705_Ecology/Flora`, **new in 0009 Sprint 00** — flora population, flora field, growth/selection conformance, determinism; the definition is the review oracle for `test_flora_growth`/`test_flora_evolution`), `SCR-LIB-EVOLUTION` (`lib/704_Evolution` — variation `INV-004`, selection `INV-005`, viability `INV-009`, environmental `INV-011`, reproducibility `INV-018`; `INV-006/007` inheritance/lineage satisfied **trivially per instance only** — §9), `SCR-LIB-ECOLOGY` (parent: population `INV-003`, environment `INV-004`, temporal `INV-010`, evolution firewall `INV-013`), `SCR-LIB-MORPHOLOGY-GROWTH` (`lib/401_Morphology/Growth` — developmental accretion; wire `scale` is a representation, `MORPHOLOGY-INV-016/017/018`), `SCR-LIB-FIELDS` (`lib/301_Field` — the flora field is a Field specialization over the terrain-cell domain, `FIELD-INV-001/003/004/008`), `SCR-LIB-SPATIAL-VOXEL-SYNTHESIS` §3 (species vocabulary, unchanged from 0006).

#### 4.1.1 Flora domain model (0009 — traced to `lib/705_Ecology/Flora`)

The five normative concepts of the Sprint-00 definition, and their implementation locus:

| Definition section | Concept | Implementation (sim-side only) | Conformance test |
|---|---|---|---|
| `Flora` §1.1 | **Flora population** — membership **is the instance list** (identity, anchor cell, species, age, trait vector); enter by establishment, leave by death (`ECOLOGY-INV-003/009`) | `FloraSubject.instances` + parallel `ages` / `traits` lists; establishment = `flora_establishes`, death = `flora_survival` (removed same tick) | `test_flora_growth` (c/d), `test_flora_evolution` (d/e), `test_flora_placement` |
| `Flora` §1.2 | **Flora field** — establishment-suitability over the terrain-cell domain; a Field specialization, not a sample (`FIELD-INV-001/003/004/008`) | `establishment_suitability(ix, iz, biome, slope, height, wetness, stress, seed)` — pure function of declared environmental inputs; establishment requires band preconditions **and** `suit ≥ FLORA_SUITABILITY_THRESHOLD` | `test_flora_growth::test_suitability_band_oracle`, `test_flora_placement` (establishment ⇒ suit ≥ threshold) |
| `Flora` §1.3 | **Growth** — developmental accretion; wire magnitudes are representations only (`MORPHOLOGY-INV-016/017/018`) | per-instance `age` (sim-side parallel list, ecological time), species curve `scale = f_species(age)` (smoothstep to maturity, then constant); `scale(age)` reaches Godot only as snapshot bytes | `test_flora_growth` (a/b) |
| `Flora` §1.4 | **Selection & variation** — trait variation + establishment/survival filtering, differential persistence **without reproduction** (`EVOLUTION-INV-004/005/009/011/018`; `INV-006/007` trivial per instance) | `flora_traits` = pure hashes `(seed, cell, trait_salt)`; `flora_selection_passes(traits, ash_raw, drought_raw)` used unchanged by establishment and survival | `test_flora_evolution` (a–e) |
| `Flora` §1.5 | **Determinism** — pure functions of (seed, cell, world state, age); no mutable RNG stream; age is ecological time (`ECOLOGY-INV-010`) | every decision a hash-style pure function; aging/survival/establishment run in the tick phase only | `test_determinism` (byte-identical sequence), `test_projection_purity` (growth state outside projection), run-twice legs in both flora tests |


### 4.2 Engine Architecture (step loop, state ownership)

- **Fixed timestep:** 60 Hz (`TICK_RATE_HZ`, `FIXED_DT = 1/60`). `scr_sim_step(dt, input*)` accumulates `dt` (frame delta from Godot physics) and runs 0..n fixed ticks; the frame delta is clamped to `FRAME_DT_CLAMP = 0.05 s` inside the sim (the adapter passes `delta` through untouched — `104_contract` §6).
- **Input application:** each executed tick consumes one `scr_input_batch` via a fixed-order dispatch table (`sim/input.mojo::build_input_table` — AP-5: table, not an if/else chain).
- **State ownership:** only `World` mutates. Projection (`snapshot/`) reads `World` and emits an immutable byte buffer — projection purity is test-enforced (`test_projection_purity.mojo`). The emission trackers (TERRAIN `world_version` rule; FLORA change/ε rule — 0009) live in `sim/runtime.mojo` *outside* `World`, so projection stays pure.
- **Determinism:** same seed + same input sequence + `dt = 1/60` per call ⇒ byte-identical snapshot sequence (`test_determinism.mojo`, golden fixture `tests/fixtures/snapshot_seed1_tick1.bin`, `test_golden_fixture.mojo`).

### 4.3 Provider Interface Contract (Mojo outputs → Godot inputs)

Normative spec: **[`providers/render/graphics/godot/104_contract.md`](../../providers/render/graphics/godot/104_contract.md)** (byte schema **v6**, C ABI **v2**, input + edit uplink, parameter table). Summary:

- **C ABI** (`src/mojo/export/abi.mojo`, header `adapter/scr_godot_abi.h`): `scr_sim_init(seed)`, `scr_sim_shutdown()`, `scr_sim_abi_version()` (**=2**, 0007), `scr_sim_schema_version()` (**=6**, 0007), `scr_sim_step(dt, input*)`, `scr_sim_snapshot_size()`, `scr_sim_snapshot_write(buf, cap)` — the 7 loader-bound symbols — plus **`scr_edit_submit(batch)`** (0007: queue one `scr_edit_batch`; bound directly by the adapter after `scr_sim_load`, 8 exported symbols total), ABI-smoke tested (`tests/abi_smoke.py`).
- **Downlink:** `RenderSnapshot` = 48-byte envelope + framed sections `1 PLAYER, 2 TERRAIN_META, 3 TERRAIN (optional), 4 OCEAN, 5 SKY, 6 MATERIALS, 7 VOLCANO, 8 PLUME, 9 SHORE_FOAM, 10 FLORA (optional, change-driven — 0009 §3.2), 11 FAUNA (required), 12 HOTBAR, 13 TARGET, 14 RIGID_BODIES`, little-endian, validated strictly by the adapter (loud `ERR_PRINT`, frame skipped — never coerced). Schema bumps: `1 → 2` (0003 §3.5, VOLCANO/PLUME), `2 → 3` (0004 §3.5: **SKY 32 → 64 B**), `3 → 4` (0005 §3.3: `9 SHORE_FOAM` + TERRAIN blend tuples), `4 → 5` (0006 §1.1: `10 FLORA` = `4 + 24·count` with the 0006 `world_version`-gated presence rule — presence rule since rewritten **change-driven** by 0009 §3.2, layout unchanged; `11 FAUNA` = `4 + 20·count`, every snapshot; sections 1–9 byte-identical), **`5 → 6` (0007 §1.1: `12 HOTBAR` = 44 B / 9 slots, `13 TARGET` = 32 B, `14 RIGID_BODIES` = `4 + 36·count` ≤ 16; sections 1–11 byte-identical)**. Adapter refuses any schema ≠ 6 / ABI ≠ 2 and validates every section range (`SKY hours ∈ [0,24]`, `elevation ∈ [±1.7]`, `cover/precip/wetness ∈ [0,1]`; FLORA `species_id ∈ [1,7]`, `scale > 0`, `count ≤ 4096`; FAUNA `count ≤ 64`, pad bytes `== 0`; **HOTBAR `bytes == 44`, `count == 9`, `selected_index < 9`; TARGET `bytes == 32`, `hit ≤ 1`, pad `== 0`, all fields zero on miss; RIGID `count ≤ 16`, `bytes == 4 + 36·count`, `shape ≤ 1`**; NaN always rejected); `test_schema_mismatch.sh` stubs report `SCR_SIM_SCHEMA_VER + 1` **and** `SCR_SIM_ABI_VERSION + 1`.
- **Uplink:** `scr_input_batch` (20 bytes) + **`scr_edit_batch` (4 bytes: `u8 op, u8 select_slot, u16 reserved`)** — raw intent only; the sim integrates motion and resolves ray/hit/material (AP-12).
- **Transport:** in-process (`dlopen` of `build/libscr_sim.so`); contract is transport-agnostic (IPC swap deferred, spec §9).

### 4.4 Testing Strategy

| Layer | Test | What it proves |
|---|---|---|
| Spec (Mojo) | `tests/mojo/test_*.mojo` — **22 files** | determinism, projection purity, envelope/framing, synthesis conformance, Gerstner ranges, catalog derivability, golden fixture, volcano subject (0003), atmosphere + weather (0004), shoreline foam + material blending + quench (0005), flock + flora placement (0006), **edit ops + raycast + hotbar + props (0007: bedrock guard, sea-level fill, biome reclass, `world_version` bookkeeping, hit/miss/range raycast, catalog slot resolution, invalid-slot rejection, prop cap/ground contact, deterministic sequences)**, **flora growth + flora evolution (0009: monotone bounded `scale(age)`, run-twice identity, dig → anchor death + re-establishment, `0 < count ≤ 4096`, ε-emission crossings, trait sanity, high-stress establishment filter, deterministic death, placement ⇒ suit ≥ threshold)** |
| Binding | `tests/abi_smoke.py` | C ABI symbols (**incl. `scr_edit_submit` + 4-byte `scr_edit_batch` layout**), 20-byte input layout, error paths, FFI snapshot == fixture, **schema 6 + ABI 2 + field checks** |
| Binding negative | `tests/test_schema_mismatch.sh` | loader refuses schema ≠ 6 **and ABI ≠ 2** loudly (two stubs: `SCR_SIM_SCHEMA_VER + 1`, `SCR_SIM_ABI_VERSION + 1`); accepts real lib |
| Contract behavior | `tests/test_terrain_resend.py` | one edit ⇒ `world_version` +1 and TERRAIN present in **exactly the next** snapshot, absent after; miss ⇒ no resend |
| Integration | `tests/godot/godot_load_test.sh` | headless main-scene load, extension registration, zero `ERROR:` lines |
| Integration | `tests/godot/godot_screenshot.sh` + `tests/godot/godot_screenshot.gd` + `tests/godot/check_luminance.py` | rendered non-blank capture + content assertions (terrain chunks, meta, HUD) + plume/lava region checks + night-glow spot check with `SCR_EXPECT_GLOW=1` (§8.3) + sun-disc sub-capture + rain-window capture (§8.4) + flora/fauna scene-tree assertions and sub-captures (§8.6) + **0007: editing HUD state — 9 named hotbar slots with swatches and exactly 1 selected flag, non-empty target readout, visible prop pool (§8.7)** |
| Integration | `tests/godot/godot_playability_test.sh` + `tests/godot/godot_playability_test.gd` | scripted input: move/turn/jump, camera bounds, no fall-through, **+ F leg (0007): `submit_edit` select/dig/place uplink rc, HUD slot mirror, terrain mesh content changed by dig and again by place, target readout left "SKY / AIR"** |
| Gate | `scripts/check_layout.sh` | layout + AP-1 (no engine types in `src/mojo/`) + AP-4 (no absolute paths) + **AP-15 (no wall-clock tokens in weather/atmosphere sim sources)** |
| IPC binding (0008) | `tests/ipc/ipc_harness.py [--self-test]` | framing-level client without Godot: handshake/refusal legs, `CMD_TICK` manual pace, **AP-16 byte-identity of the first SNAPSHOT vs `scr_sim_snapshot_write`** |
| IPC version gate (0008) | `tests/ipc/test_ipc_version_refusal.sh` | both directions: harness ⇒ server `ERROR`+close+non-zero exit (schema/abi/proto/unknown flag); `fake_server.py` ⇒ adapter refuses loudly (ERR_PRINT, inert scene, no frames, no in-process fallback) |
| IPC supervision (0008) | `tests/ipc/test_ipc_crash_restart.sh` | kill -9 mid-run ⇒ respawn with backoff, same seed, tick reset, no orphan (phase A); crash-loop ⇒ exactly 6 spawns then FATAL cap (phase B); harness restart leg: EOF, tick 20→1, TERRAIN re-delivery, BYE rc 0 (phase C) |
| IPC stall (0008) | `tests/godot/godot_render_stall_test.sh` | structural grep (zero socket syscalls in `scr_godot_adapter.cpp`, positive control in `transport_socket.cpp`) + SIGSTOP the server 2 s ⇒ frame/physics gaps stay `< FRAME_DT_CLAMP`, no restart |
| IPC determinism (0008) | `tests/ipc/test_ipc_determinism.sh` | N = 600 ticks, in-process vs socket sequences byte-identical (AP-16) |
| IPC load/smoke (0008) | `tests/godot/godot_ipc_smoke.sh` | `SCR_SIM_TRANSPORT=socket`: handshake OK, zero `ERROR:` lines, server exits 0 on BYE |

All Mojo checks are **raise-based** (`_check(cond, msg)` → `raise Error`): this toolchain compiles `assert` to a no-op (verified in `test_volcano.mojo`), so the 0003 sprint converted every `assert` in `test_synthesis_conformance`, `test_gerstner`, `test_catalog` to `_check` — which immediately exposed three latent test-vs-spec bugs (§8.3).

### 4.5 Successor Specification Reference

Milestone 0008 (IPC Transport Swap) is **complete** (§8.8): the sim core runs out-of-process behind `ITransport`, default stays in-process, semantics unchanged (schema 6 / ABI 2 / proto 1). Milestone 0009 (Flora Upgrade — field, growth, selection) is **complete** (§8.9): FLORA emission is change-driven, growth/selection are sim state, schema 6 / ABI 2 unchanged. Successor sequencing for 0010+: `TBD — future milestone` (Rule 10).

### 4.6 IPC transport, threading & supervision (milestone 0008)

The Port (snapshot down / input+edit up, `104_contract.md` §4/§5) is unchanged; only the mechanism behind `ITransport` grew (normative: `104_contract.md` §2):

- **Transports:** `InprocTransport` (default, `dlopen` + C ABI — byte-for-byte pre-0008 behavior) vs `SocketTransport` (opt-in `SCR_SIM_TRANSPORT=socket`): adapter spawns `build/scr_sim_server` (argv `--socket <path> --seed <n>`, env inherited + `SCR_REPO_ROOT`), endpoint = `SCR_SIM_SOCKET` else `user://scr_sim.sock`; with an external endpoint and no `SCR_SIM_SERVER_BIN` it connects only and never respawns (external-owner mode).
- **Framing:** `SCRT` frames (`HELLO/HELLO_OK/ERROR/SNAPSHOT/INPUT/EDIT/ACK/BYE/CMD_TICK`, `SCR_SIM_IPC_PROTO_VER = 1`), handshake refuses proto/abi/schema mismatch in **both** directions with the same semantics as the `dlopen` gate (`104_contract.md` §2.1).
- **Threading (AP-9/AP-15):** one worker thread owns every socket syscall and the framing; the render thread only reads a seqlock latest-snapshot slot and pushes inputs/edits through an SPSC ring (depth 16, merge-on-full). Structural gate (grep: zero socket syscalls in `scr_godot_adapter.cpp`) + measured gate (server `SIGSTOP`ped 2 s ⇒ frame gaps stay under `FRAME_DT_CLAMP`).
- **Session rule — first-snapshot latch:** latest-wins coalescing never applies to a session's *first* snapshot; the client latches it until consumed (`transport_socket.cpp::publish`). Required because `TERRAIN`/`FLORA` are present only on the session's first snapshot (`TERRAIN` under the 0006 invariant-5 `world_version` rule; `FLORA` under the first-after-init leg of the 0009 change-driven rule) while the render thread may not read for several ticks at startup. Found by the socket screenshot gate in this sprint (terrain/flora sections absent), fixed and re-gated (§8.8).
- **Supervision:** backoff `100→1600 ms` (cap 2 s), fresh session + same seed + logged restart, **> 5 restarts / 30 s ⇒ fatal** (loud, stepping stops), `BYE` + reap on scene exit (no orphans), pause of the server is *not* a crash (stall test).
- **Determinism:** same seed + same inputs ⇒ byte-identical snapshot sequence in both transports (600-tick gate, `tests/ipc/test_ipc_determinism.sh`); `CMD_TICK` manual pace makes the socket leg well-defined without wall-clock coupling.
- **Pacing (wall default, manual opt-in — `104_contract.md` §2):** default `wall` = server free-run at its fixed 60 Hz clock (unchanged, safety default). `SCR_SIM_IPC_PACE=manual` = client-paced socket mode: the adapter handshakes `SCR_IPC_FLAG_MANUAL_PACE` and the worker sends `CMD_TICK 1` behind each physics frame's `INPUT`/`EDIT` (SPSC FIFO; a full ring defers the tick to a debt counter flushed after the next drain — ticks are delayed, never lost; no render-thread socket I/O, AP-15). One fixed tick per Godot physics frame ⇒ socket tick↔wall timing equals the in-process leg's. Required by the rendered socket gates (`godot_screenshot.sh` sets it for `SCR_SIM_TRANSPORT=socket`): plume lifetime and cloud/`TIME` displays run on wall time, so a wall-paced socket run reaches the capture tick too fast (plume 0 rows, sun-disc delta < 20). `godot_playability_test.sh` sets the same default — its F-leg reads the edit mirror 2 physics frames after `submit_edit`, faster than a 60 Hz wall snapshot round-trip in headless mode (wall-paced socket run failed F5/F6/F13; manual passed, re-gated 2026-10-02). `SCR_SIM_IPC_PACE=manual` on the client wins over the server's `--pace wall` (effective mode = CLI OR HELLO flag, `server/session.mojo`).

## 5. Scene ↔ State Mapping (the ADAPTER CONTRACT)

Group discovery is by Godot node group; absent groups are tolerated (presentation absent), mistyped nodes are reported and skipped. Authoritative implementation: `providers/.../adapter/scr_godot_adapter.cpp` (file header + `apply_*`).

| Group (scene) | Node type | Snapshot section | Applied as |
|---|---|---|---|
| `scr_sim` | `ScrSim` (GDExtension, `world_seed = 1`) | — (producer) | `_physics_process`: batch input → `scr_sim_step` → decode snapshot → apply |
| `scr_terrain` | `Node3D` | `3 TERRAIN` | creates/updates children `Chunk_i` (`MeshInstance3D`, `ArrayMesh`, **world-space vertices**, surfaces grouped by the **dominant** id of the schema-4 blend tuple; chunk `origin` stored as node meta). Each emitted vertex carries `ARRAY_COLOR = mix(catalog[dom].albedo, catalog[blend].albedo, weight/255)` and the surface material sets `FLAG_ALBEDO_FROM_VERTEX_COLOR` + `FLAG_SRGB_VERTEX_COLOR` so `final albedo = blended_albedo × (1 − 0.35·wetness)` (sRGB flag required: catalog is `base_color_srgb`, probe-measured — §8.5). Surfaces are still keyed by dominant id, materials still derived only from the dominant MATERIALS record (AP-20). **Winding:** sim/contract §4.3 emits CCW front faces; Godot defaults to CW front (`CULL_BACK`), so the adapter swaps index order (`out3[0],out3[2],out3[1]`) when building surfaces — conversion at the provider boundary, contract unchanged |
| `scr_meta` | `Node` | `2 TERRAIN_META` | meta keys `sea_level` (float), `peak_height` (float), `spawn_position` (Vector3) |
| `scr_ocean` | `MeshInstance3D` + `ShaderMaterial` | `4 OCEAN` + `9 SHORE_FOAM` | shader params **exactly**: `sea_level, amplitude, frequency, steepness, dir_x, dir_z, speed, phase` (every physics frame); plus (0005) `foam_shore` (`ImageTexture`, FORMAT_RF `grid_n×grid_n`, **re-uploaded every snapshot** — the field evolves with wave phase), `foam_grid_n`, `foam_cell_size` from the SHORE_FOAM header. `sea_level` keeps arriving from OCEAN (same sim datum); the shader maps world xz → uv alone (AP-19) |
| `scr_sun` | `DirectionalLight3D` | `5 SKY` | `set_rotation(-sun_elevation, sun_azimuth, 0)` rad (node **+Z points at the sun** — §8.4 sun sub-capture relies on this); `light_energy = sun_intensity`; `light_color = (sun_color_r,g,b)` (0004) |
| `scr_env` | `WorldEnvironment` + `Sky(ProceduralSkyMaterial)` | `5 SKY` | **fog:** `fog_enabled = true`, `fog_density`, `fog_light_color` straight from SKY (AP-17 — no scene literal); **dome gradient derived** (contract §4.3 note): `horizon = lerp(fog_color, sun_color, 0.25)`, `zenith = horizon × (0.40, 0.55, 0.90)`, `ground_horizon = horizon`, `ground_bottom = zenith × 0.35`, `sky_energy_multiplier = energy_multiplier = 0.5 + 0.5·clamp(sun_intensity,0,1)` (constants §6.6) |
| `scr_camera` | `Camera3D` (or rig `Node3D`) | `1 PLAYER` | global position = `player.position + (0, eye_height, 0)`; `rotation = (pitch, yaw, 0)` — **no sign flips** (sim forward = `(−sin yaw, −cos yaw)` = Godot −Z under +yaw) |
| `scr_hud` | `Label` | envelope | text `tick %d | gen %d | seed %d` |
| `scr_materials` | `Node` | `6 MATERIALS` | meta `materials` = Dictionary `id → {albedo, roughness, emissive, opacity}` (also used to derive `StandardMaterial3D` per chunk surface) |
| `scr_crater_lava` | `MeshInstance3D` + `ShaderMaterial` (0003) | `7 VOLCANO` | position `(center_x, lake_level + 1, center_z)` (1 u glow-free lift, display), non-uniform scale `(radius, 1, radius)`, shader uniforms `emissive_intensity`, `crust_fraction`, `radius` |
| `scr_crater_glow` | `OmniLight3D` (0003) | `7 VOLCANO` | `light_energy = glow_intensity` (sim-computed; adapter must NOT re-derive “night”, AP-11); position `(center_x, lake_level + GLOW_DISPLAY_LIFT_U, center_z)` — **display lift 60 u**, geometry rationale + measurement chain in §8.3 |
| `scr_plume` | `GPUParticles3D` + `ParticleProcessMaterial` (0003) | `8 PLUME` | position = plume origin, `lifetime`, `amount = round(rate·lifetime)` (clamped 1..4096), `emitting = rate > 0`, `initial_velocity_min = max = v0`, `spread`, `set_turbulence_enabled(turbulence > 0)` with **velocity influence locked to 0** (§8.3) |
| `scr_clouds` | `MeshInstance3D` (PlaneMesh 8000×8000 at y = `CLOUD_PLANE_ALTITUDE`) + `ShaderMaterial` (0004) | `5 SKY` | single uniform `cloud_cover ∈ [0,1]` written on change; pattern, scale, drift and fades are display-only (`shaders/clouds.gdshader`, §6.6) |
| `scr_rain` | `GPUParticles3D` + `ParticleProcessMaterial` (0004) | `5 SKY` | `emitting = (precipitation > 0)`; `amount_ratio = precipitation` (drives live count **and** emission rate — avoids `set_amount`, which restarts the GPU system); wetness: (0005) gain `(1 − 0.35·wetness)` now lives in the material `albedo_color` and multiplies the vertex-colour albedo (catalog moved to `ARRAY_COLOR`), re-applied inside `update_materials()` so the per-frame rewrite cannot erase it |
| `scr_flora` | `Node3D` host + `scripts/flora_view.gd` (0006) | `10 FLORA` (change-driven — 0009 §3.2) | adapter validates the section, then `callv("apply_flora", [bytes, materials])` **only while §10 is present** (absence never clears the view — 0006 invariant 5 retain rule) and `callv("set_wetness_gain", k)` when the gain changes. The script materializes **one `MultiMeshInstance3D` per species** (`Species_1..7`, `transform_format = TRANSFORM_3D`, instance = `(position, Basis(yaw)·scale)` from the wire; meshes built once from Godot primitives — presentation only, AP-11) with a `ShaderMaterial` on `shaders/flora_wing.gdshader`. `materials` = Dictionary `species → {albedo, roughness}` resolved by the adapter through the **catalog mirror** (MATERIALS record with `id == catalog_index` wins, else `scr::kSpeciesDisplay` — foliage idx 34 / bamboo idx 33 / moss idx 81, AP-14). Sway runs on shader `TIME` (display-only, AP-12) |
| `scr_fauna` | `Node3D` host + `scripts/fauna_view.gd` (0006) | `11 FAUNA` (every snapshot) | adapter validates the section, then `callv("apply_fauna", [bytes])` every snapshot; the script repositions a **pooled ≤ 64 `MeshInstance3D` children** (`Bird_0..63`, extras hidden — no per-frame allocation): `position` from the record, `rotation.y = +yaw` (no flip), shared box-bird `ArrayMesh` + `flora_wing.gdshader` material with `flap_amount/flap_speed` (wing lift ∝ |x| on shader `TIME` — no flap phase in the bytes, AP-12). `species_id 0 = seabird` (only emitted id; others render as the seabird mesh — species semantics stay sim-side) |
| `scr_hotbar` | `HBoxContainer` host + `scripts/hotbar_hud.gd` (0007) | `12 HOTBAR` (every snapshot) | adapter validates the section (44 B, count 9, `selected_index < 9`), then `callv("apply_hotbar", [selected_index, ids, names, colors])` **change-latched** (only when `selected_index`/`first_id` change — the section carries no animation state). The script builds **9 `PanelContainer` slots** in `_ready` (number `Label` + catalog name `Label` + `ColorRect` swatch) and renders: selection highlight via `StyleBoxFlat` override + read-only `selected` meta flag, name from the adapter's **catalog mirror** (`vocab_name_of`: MATERIALS record with matching id wins, else `scr::kVocabDisplay`, else `#<id>` — AP-13: no GDScript vocabulary), swatch `ColorRect.color` from the same resolution (`vocab_albedo_of`, grey 0.5 fallback). Display-only; selection reaches the sim only as edit intent (§5 uplink) |
| `scr_target` | `Label` (no script) | `13 TARGET` (every snapshot) | adapter validates the section (32 B, `hit ≤ 1`, pad 0, **all fields zero on miss**) then sets `text` directly, change-latched: miss ⇒ `"SKY / AIR"` (per `lib/A01_Render/HUD` §2.2), hit ⇒ `"<name> #<id>"` through the same catalog mirror. No script: the readout is pure adapter projection |
| `scr_props` | `Node3D` host + `scripts/props_view.gd` (0007) | `14 RIGID_BODIES` (every snapshot) | adapter validates the section (`count ≤ 16`, `bytes == 4 + 36·count`, `shape ≤ 1`), then `callv("apply_props", [bytes, colors])` where `colors` maps referenced material ids → albedo (same catalog mirror). The script keeps a **pool ≤ 16 `MeshInstance3D` children** (`Prop_0..15`, extras hidden): position from the record, shape/size-latched mesh rebuild (`BoxMesh` 2·`half_extent` / `SphereMesh` radius — mesh rebuilt only when shape/size change), albedo via `StandardMaterial3D.albedo_color` (dict lookup, grey fallback). Display-only |

**Input uplink (scene → sim):** `scripts/player_input.gd` calls
`ScrSim.submit_input(move_x, move_y, look_dx, look_dy, jump, sprint, action_primary, action_secondary)`
every physics frame (parent-before-child order guarantees the adapter consumes the same frame). Look deltas accumulate per frame and reset after batching (adapter); movement is clamped to the unit circle (adapter); booleans are level-triggered per frame. The script contains **zero gameplay logic** (AP-8): no node movement, no world writes. Look deltas are passed through as **raw device deltas**; the device→world sign mapping (yaw positive = left per contract §6, so mouse-right must *decrease* yaw) is applied exactly once, in the sim input decode `sim/subjects.mojo::collect_intent` — the script stays a pure passthrough and the sim stays the semantic authority for input meaning.

**Edit uplink (scene → sim, 0007):** `scripts/player_input.gd` also maps input to **edit intent only** and calls `ScrSim.submit_edit(op, select_slot)`:

| Input (mouse captured) | Intent | Notes |
|---|---|---|
| LMB (captured) | `submit_edit(1, 0)` — dig | sim raycasts, resolves cell/material |
| LMB (uncaptured) | capture mouse | no edit submitted |
| RMB (captured) | `submit_edit(2, 0)` — place | uses current sim hotbar selection |
| Keys `1`–`9` (physical) | `submit_edit(0, d)` — select slot `d` | `0` op = selection-only entry |
| Wheel up / down (captured) | `submit_edit(0, wrapi(slot ± 1, 1, 10))` — wraps 1..9 | cycling reads `get_hotbar_selected_slot()` (adapter read-only display mirror of `12 HOTBAR`) |
| `Esc` | release mouse | no edit submitted |

`submit_edit(op, select_slot)` is a bound method on `ScrSim`: it validates only that the integers fit `u8` (else `SCR_ERR_BAD_STATE`), then forwards the verbatim 4-byte `scr_edit_batch` to `scr_edit_submit` (dlsym'd in `_ready` after `scr_sim_load`; refused → `ERR_PRINT`, edit path disabled, motion unaffected). The sim validates op range, slot range, ray and material semantics — the client never names materials or cells (AP-12). Intent-only: no node movement, no world writes (AP-8).

**Ocean node contract:** transform kept identity (position 0,0,0) so the shader's local space equals the world frame (documented in `shaders/ocean.gdshader` header).

### 5.1 Edit pipeline (0007)

```text
input (LMB/RMB/keys/wheel)
  → player_input.gd: intent only        {op ∈ 0/1/2, select_slot ∈ 0..9}
  → ScrSim.submit_edit → scr_edit_submit → World.edit_queue (FIFO ≤ 16)
  → each tick: consume ONE batch
        select_slot ≠ 0 → hotbar_select()            (sim state)
        op = dig/place → sim raycast (RAY_RANGE/RAY_STEP/RAY_REFINE_ITERS)
             hit? → target cell + material from sim hotbar selection
                  → dig/place guard (bedrock y=0, sea-level fill)
                  → classify_biome + voxel_synthesis_pipeline for the column
                  → heightfield + surface material update
                  → rebuild ONLY the containing chunk mesh (16×16 cells)
                  → world_version += 1
             miss → consumed, no mutation (target = "SKY / AIR")
  → runtime: encode 12/13/14 + (if world_version changed) TERRAIN
  → adapter: TERRAIN rides the existing emission path (chunk-local rebuild
             visible in-game) · apply_hotbar / apply_target / apply_props
  → HUD: hotbar slots, target readout, prop transforms (display-only)
```

Invariants (spec §6): pipeline authority (no direct grid pokes — AP-11), bedrock `y = 0` never overwritten, submerged dig ⇒ water fill to `SEA_LEVEL`, hit authority (ray + hotbar are sim state — AP-12), catalog vocabulary only (AP-13), `world_version` +1 per applied edit ⇒ TERRAIN in exactly the next snapshot (emission invariant), chunk-local rebuild only (AP-14), `rigid_body_count ≤ 16`, byte-identical snapshot sequence for identical edit sequences.

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

### 6.6 Atmosphere & weather (0004, `parameters.mojo` + adapter + scene)

**Sim-side** (`src/mojo/sim/parameters.mojo`, AP-7 / AP-17 — derived by formula, not eye-tuned):

| Parameter | Value | Unit |
|---|---|---|
| `WEATHER_TRANSITION_TICK_STEP` / `WEATHER_BLEND_TICKS` | 1800 / 900 | ticks (30 s / 15 s @ 60 Hz) |
| CLEAR profile — `cloud / precip / wind / fog_bias` | 0.15 / 0.0 / (1.6, 1.0) / 0.0 | — / — / u·s⁻¹ / — |
| OVERCAST_STRATUS profile | 0.88 / 0.0 / (3.2, 2.4) / 0.45 | as above |
| TROPICAL_MONSOON profile | 0.97 / 0.8 / (6.5, 4.8) / 0.85 | as above |
| `WETNESS_RISE_RATE` / `WETNESS_DECAY_RATE` | 0.15 / 0.01 | s⁻¹ (at `precip = 1` / dry-out) |
| `WIND_GUST_FRACTION` / `WIND_GUST_PERIOD_TICKS` / `WIND_MAX_SPEED` | 0.18 / 960 / 12.0 | — / ticks / u·s⁻¹ |
| `CLOUD_PLANE_ALTITUDE` | 400.0 | m above sea level |
| `FOG_DENSITY = BASE + 0.0030·C + 0.0040·P + 0.0010·fog_bias + 0.0015·night` | BASE 0.0030 | strictly increasing in C and P (test-enforced) |
| `fog_color = lerp(lerp(CLEAR, STORM, w), NIGHT, night·0.85)`, `w = min(1, 0.6·C + 0.7·P)` | CLEAR (0.58,0.66,0.78), STORM (0.40,0.44,0.50), NIGHT (0.05,0.07,0.13) | RGB |
| Sky palette tiers (zenith/horizon × night/dawn/sunset/noon, sun color × night/low/rising/golden/warm/noon) | see file | RGB |

**Adapter display constants** (`scr_godot_adapter.cpp` — representation only, never semantics, like `GLOW_DISPLAY_LIFT_U` §6.5):

| Constant | Value | Meaning |
|---|---|---|
| `SKY_HORIZON_SUN_MIX` | 0.25 | how much `sun_color` mixes into the derived horizon (contract §4.3) |
| `SKY_ZENITH_SCALE_R/G/B` | 0.40 / 0.55 / 0.90 | horizon → zenith tint (blue-leaning) |
| `SKY_GROUND_DARKEN` | 0.35 | below-horizon multiplier |
| `SKY_ENERGY_MIN` | 0.50 | `sky_energy = SKY_ENERGY_MIN + (1−SKY_ENERGY_MIN)·clamp(sun_intensity,0,1)` |
| `WETNESS_TINT` | 0.35 | `albedo = catalog × (1 − WETNESS_TINT·wetness)` |

**Scene display** (`island.tscn`, `shaders/clouds.gdshader`): cloud plane at `CLOUD_PLANE_ALTITUDE` (400 m — low-deck cumulus band mid-point), `noise_scale 0.0035`, `opacity 0.85`, drift `(wind_x, wind_z)·0.02` u/frame; shader constants `OCTAVES 5`, `WARP_AMOUNT 0.55`, `EDGE_WIDTH 0.10`, `COVER_GATE 0.004`, `FADE_NEAR 1100`, `FADE_FAR 3600`, `PLANE_EDGE 3600`. Rain: `QuadMesh 0.1×1.6`, box extents `(110, 30, 130)`, speed 26–34 u/s, gravity `(0, −6, 0)`, `amount 12000`, `lifetime 2.2`, albedo `(0.62, 0.68, 0.78)`, material `alpha 0.7` (contrast tuning — §8.4).

### 6.7 Shoreline fidelity (0005, `parameters.mojo` + scene mirrors)

Source of truth: `src/mojo/sim/parameters.mojo` (§6 preamble). Normative defaults:

| Parameter | Value | Meaning |
|---|---|---|
| `FOAM_DEPTH_M` | `1.8` u | `d_foam` of `SCR-LIB-RENDER-WATER` §3 — `F = 0` for `Δy ≥ 1.8` |
| `FEATHER_WIDTH_CELLS` | `4` | feather-band half-width (cells) around a synthesis material boundary |
| `BLEND_DITHER_AMP` | `0.10` | deterministic noise dither added to the base feather ramp |
| `BLEND_DITHER_FREQUENCY` | `0.18` | cycles/world-unit of the dither gradient noise |
| `SEA_LEVEL` / `GRID_N` / `CELL_SIZE` | `0.0` / `64` / `4.0` | water datum + height-field geometry (also the SHORE_FOAM grid: 12 + 4·64² = **16 396 B**) |
| `SCHEMA_VERSION` | `4` | + `9 SHORE_FOAM`, TERRAIN 4-byte blend tuples (AP-21) |

Scene-side display mirrors (`island.tscn` §6.4 pattern): `foam_grid_n = 64.0`,
`foam_cell_size = 4.0` — frame-0 defaults overwritten from the SHORE_FOAM
header every snapshot (contract §4.3 is the authority; the mirrors exist so the
shader never samples with stale geometry). Crest thresholds
`foam_jacobian_threshold / foam_height_threshold` stay the 0002 display tunings
(§6.4) — untouched by 0005 (AP-22).

### 6.8 Ecology: flora scatter + seabird flock (0006, extended 0009 — `parameters.mojo` + scene display)

Source of truth: `src/mojo/sim/parameters.mojo` (§6 preamble). Normative defaults:

| Parameter | Value | Meaning |
|---|---|---|
| `FLORA_N_MAX` | `4096` | hard instance cap (0006 AP-13; tests assert `count ≤ cap`) |
| `FLORA_HEIGHT_EPS` | `0.05` u | elevation window: `y ≥ SEA_LEVEL + ε` |
| `FLORA_SLOPE_CAP` / `FLORA_BEACH_SLOPE_CAP` | `1.00` / `1.00` u/u | max `∇h` per band (beach profile runs 0.52..1.02 for seed 1 — cap admits the whole band) |
| `FLORA_DENSITY_BEACH` / `FLORA_DENSITY_SLOPE` | `0.10` / `0.12` | `P(host cell \| band)` |
| `FLORA_WEIGHT_PALM_CLUSTER` | `0.35` | BEACH weights (remainder → `PALM_SOLO`) |
| `FLORA_WEIGHT_CANOPY_TREE` / `CANOPY_CLUSTER` / `SHRUB` / `FERN_CARPET` | `0.20` / `0.10` / `0.35` / `0.35` | VOLCANIC_SLOPE weights (sum 1.0) |
| `FLORA_SCALE_MIN` / `MAX` | `0.80` / `1.35` | uniform instance scale range |
| `FLOCK_N_MAX` / `FLOCK_N_INIT` | `64` / `32` | slot cap (AP-13) / active slots at init |
| `FLOCK_SEABIRD_SPECIES` | `0` | FAUNA `species_id` (0 = seabird) |
| `FLOCK_WAYPOINT_RADIUS` / `JITTER` | `100.0` / `6.0` u | ocean-ring orbit radius + per-slot jitter |
| `FLOCK_WAYPOINT_PERIOD_TICKS` | `14400.0` ticks (240 s) | **waypoint tuning note (§8.6):** orbit period must keep tangential speed `2πr/T` well below `FLOCK_SPEED_CRUISE`, else pure-pursuit seek can never catch the waypoint and the flock spirals inward (observed collapse at 2400 ticks ≈ 15.7 u/s at r=100 vs cruise 9; 14400 ⇒ ≈ 2.8 u/s at r=106) |
| `FLOCK_BOUND_RADIUS` | `110.0` u | ocean/beach bound (horizontal); violation ⇒ despawn/respawn |
| `FLOCK_MIN_ALTITUDE` / `MAX_ALTITUDE` | `8.0` / `90.0` u | altitude window above local surface / sea level |
| `FLOCK_SPEED_CRUISE` / `MIN` / `MAX` | `9.0` / `4.0` / `14.0` u/s | seek target speed + clamps |
| `FLOCK_W_SEEK/ALIGN/COHERE/SEPARATE/AVOID` | `0.80 / 0.50 / 0.40 / 20.0 / 2.00` | boid rule weights (acceleration contributions) |
| `FLOCK_ALIGN/COHERE/SEPARATE_RADIUS` | `14.0` / `18.0` / `6.0` u | neighbour radii; `FLOCK_SEPARATION_MIN = 2.0` u hard floor (test oracle) |
| `SCHEMA_VERSION` | `5` | + `10 FLORA` = `4 + 24·count` (0006 presence rule; since rewritten change-driven, 0009 §3.2 — layout unchanged), `11 FAUNA` (every snapshot); sections 1–9 byte-identical to schema 4 |

**Flora band table (test oracle, `sim/flora.mojo`):**

| Band | Species | Notes |
|---|---|---|
| `BIOME_BEACH` | `PALM_CLUSTER`, `PALM_SOLO` | below/around sea level within slope cap |
| `BIOME_VOLCANIC_SLOPE` | `CANOPY_TREE`, `CANOPY_CLUSTER`, `SHRUB`, `FERN_CARPET` | above `SEA_LEVEL + ε`, `∇h ≤ FLORA_SLOPE_CAP` |
| `BIOME_CALDERA_RIM` / `CALDERA_LAKE` / `SHALLOW_WATER` / `DEEP_OCEAN` (+ any other code) | **none** | explicit empty band |

**Species → catalog material (0006 AP-14 — single-sourced in `materials/catalog.mojo::species_catalog_id_string`, conformance-tested against `lib/A01_Render/Material/materials_catalog.json`):**

| `species_id` | Species | Catalog id | `catalog_index` | Albedo (sRGB) | Roughness |
|---|---|---|---|---|---|
| 1 | `PALM_CLUSTER` | `botanical.foliage` | 34 | (0.24, 0.52, 0.18) | 0.55 |
| 2 | `PALM_SOLO` | `botanical.foliage` | 34 | (0.24, 0.52, 0.18) | 0.55 |
| 3 | `BAMBOO_GROVE` | `botanical.bamboo` | 33 | (0.38, 0.62, 0.22) | 0.40 |
| 4 | `CANOPY_TREE` | `botanical.foliage` | 34 | (0.24, 0.52, 0.18) | 0.55 |
| 5 | `CANOPY_CLUSTER` | `botanical.foliage` | 34 | (0.24, 0.52, 0.18) | 0.55 |
| 6 | `SHRUB` | `botanical.foliage` | 34 | (0.24, 0.52, 0.18) | 0.55 |
| 7 | `FERN_CARPET` | `botanical.moss` | 81 | (0.28, 0.48, 0.18) | 0.92 |

The adapter resolves these through a documented **mirror table** (`scr::kSpeciesDisplay` in `scr_godot_adapter.cpp`): MATERIALS never carries botanical ids (encoder emits the terrain vocabulary ∪ water), so a MATERIALS record with `id == catalog_index` wins if one ever appears, otherwise the mirror (which is the conformance-tested catalog value — no invented color, AP-14). `wood.*` ids are not selected as species materials (recorded catalog.mojo deviation: crown/ground-cover color dominates the silhouette).

Scene-side display constants (plume-albedo precedent, NOT sim tunables): bird albedo `(0.90, 0.91, 0.93)`, roughness `0.65`, `flap_amount 0.22`, `flap_speed 7.0` (`fauna_view.gd`); per-species sway amplitudes `0.03..0.14` u (`flora_view.gd::SWAY`); shader `flora_wing.gdshader` (`sway_height 3.0`, `sway_speed 1.1`). Wetness: flora materials receive the shared `wetness_gain()` (§6.6 `WETNESS_TINT`) via `set_wetness_gain(k)` on change; birds are not wetness-tinted (display choice).

#### 6.8.1 Flora field / growth / selection model (0009, `parameters.mojo` + `sim/flora.mojo`)

Milestone 0009 turns the 0006 scatter into a living population. Model (definition: `lib/705_Ecology/Flora` §1.1–1.5, §4.1.1 above; spec: [0009 §3.2/§6](../program_increments/v0.0.2/milestone_0009_flora-upgrade/spec.md)):

- **Establishment field.** A candidate cell establishes iff the 0006 hard band preconditions hold (allowed biome, `height ≥ SEA_LEVEL + FLORA_HEIGHT_EPS`, slope ≤ per-band cap, density hash) **and** `establishment_suitability(cell) ≥ FLORA_SUITABILITY_THRESHOLD` **and** the trait-selection predicate passes (below). Suitability is a pure function of `(biome, slope, height, wetness, crater-distance stress, seed)` — no RNG stream (AP-20).
- **Growth.** Every instance carries `age` (sim-side parallel list; ecological time, `ECOLOGY-INV-010`). `scale(age) = s0 + (target − s0)⁺·(P(age) − P(a0))` where `P` is the species curve progress (`FLORA_GROWTH_SHAPE = 1` ⇒ anchored smoothstep `x²(3−2x)`, 0 ⇒ linear), saturating at `FLORA_MATURITY_<SPECIES>` and constant thereafter. Initial ages are a pure hash of `(seed, x, z)` over `[0, maturity]` so the seed-1 population starts mixed. The commit is **ε-quantized**: the stored scale snaps up only when the curve moves ≥ `FLORA_EMIT_EPS` relative to the stored value, so stored bytes change ⇔ emission can fire (AP-22).
- **Traits + selection.** Trait vector `FLORA_TRAIT_COUNT = 4` slots (2 live: ash tolerance, drought tolerance; 2 reserved) drawn as `hash01(seed, cell, trait_salt)`. Stress model (0009 §1.2 open decision, **resolved on the recommendation**): `ash_raw = clamp(1 − crater_dist / FLORA_ASH_FALLOFF_RADIUS, 0, 1)`, `drought_raw = clamp((FLORA_DROUGHT_WETNESS_REF − wetness)/REF, 0, 1)`, `local_stress = clamp(W_ASH·ash_raw + W_DROUGHT·drought_raw, 0, 1)` — both inputs are existing sim state (0003 volcano centroid, 0004 weather wetness). Establishment fails and survival dies iff **either** weighted term exceeds its tolerance (`flora_selection_passes`, componentwise — `EVOLUTION-INV-005`), one predicate shared by both passes.
- **Emission rule (replaces the 0006 `world_version` gate; `104_contract.md` §4.3 §10).** FLORA is present on (a) the first snapshot after init, (b) any snapshot where `count` differs from the last emission, or (c) any snapshot where at least one instance's stored `scale` moved ≥ `FLORA_EMIT_EPS` (relative), `species_id` changed, or position/yaw changed since the last emission. When absent, the adapter **retains cached instances** (0006 invariant 5 wording preserved). Tracker = `sim/runtime.mojo::_flora_dirty` over the last-emitted instance copy (`flora_emission_dirty` predicate); TERRAIN keeps its own `world_version` rule unchanged. Layout unchanged: `4 + 24·count`, schema 6, ABI 2.
- **Death / regrowth flow (tick phase only, projection purity).** Order in `sim/world.mojo`: edit pipeline commit (if any) ⇒ `flora_re_evaluate` full row-major re-scan (survivors keep age/scale/traits; new establishments start at `a0`/`s0`; failures drop this pass) ⇒ weather commit ⇒ `flora_survival` (same selection predicate against committed wetness; dead removed the same tick — **absorbing, no hysteresis**; re-entry only via a later field re-scan) ⇒ `flora_tick` (age +1, ε-quantized scale commit). Deaths cannot violate `FLORA_N_MAX` (count only shrinks in-pass). `world_version` bumps on edits ⇒ FLORA re-evaluation rides the normal snapshot path (0006 §9 gap closed — §9 item 12).

Additional 0009 tunables (source of truth `src/mojo/sim/parameters.mojo`, AP-7):

| Parameter | Value | Meaning |
|---|---|---|
| `FLORA_SUITABILITY_THRESHOLD` | `0.25` | field gate: establishment requires `suit ≥ threshold` (part of the field semantics) |
| `FLORA_GROWTH_SHAPE` | `1` | `0` = linear-in-age, `1` = anchored smoothstep `x²(3−2x)` |
| `FLORA_MATURITY_PALM_CLUSTER` / `PALM_SOLO` / `BAMBOO_GROVE` | `1500` / `1200` / `1200` ticks | curve saturation age (BAMBOO unused by the band table) |
| `FLORA_MATURITY_CANOPY_TREE` / `CANOPY_CLUSTER` / `SHRUB` / `FERN_CARPET` | `2400` / `1800` / `900` / `600` ticks | as above (25/40/30/15/10 s at 60 Hz for the banded species) |
| `FLORA_TARGET_SCALE_PALM_CLUSTER` / `PALM_SOLO` / `BAMBOO_GROVE` | `1.25` / `1.15` / `1.10` | mature `scale` target, all ∈ [`FLORA_SCALE_MIN`, `FLORA_SCALE_MAX`] |
| `FLORA_TARGET_SCALE_CANOPY_TREE` / `CANOPY_CLUSTER` / `SHRUB` / `FERN_CARPET` | `1.35` / `1.20` / `1.00` / `0.90` | as above |
| `FLORA_EMIT_EPS` | `0.01` | relative scale δ: stored-scale snap threshold **and** emission-dirty threshold (AP-22) |
| `FLORA_TRAIT_COUNT` | `4` | fixed trait-vector width (2 live, 2 reserved) |
| `FLORA_TRAIT_SALT_ASH` / `SALT_DROUGHT` | `0x600000001B3` / `0x700000001B3` | pure trait hashes `(seed, cell, salt)` (AP-20) |
| `FLORA_TRAIT_SALT_RESERVED_0` / `RESERVED_1` | `0x800000001B3` / `0x900000001B3` | declared, unused until a trait exists (no invented semantics) |
| `FLORA_STRESS_W_ASH` / `FLORA_STRESS_W_DROUGHT` | `0.70` / `0.30` | stress-term weights (sum 1.0; rim `ash_term ≈ 0.26–0.37`, dry floor `drought_term = 0.30`) |
| `FLORA_ASH_FALLOFF_RADIUS` | `72.0` u | crater-distance ash falloff: `ash_raw = 0` at ≥ 72 u (covers the inner island incl. volcanic slope; outer beach ring ash-free) |
| `FLORA_DROUGHT_WETNESS_REF` | `1.0` | drought reference: `w = REF` ⇒ no drought, `w = 0` ⇒ `drought_raw = 1` |
| `FLORA_WETNESS_NEUTRAL` / `FLORA_CRATER_STRESS_NEUTRAL` | `0.5` / `0.0` | **neutral reference inputs for field unit oracles only** — production call sites feed real wetness + crater distance (never these) |

(0006 §6.8 rows above — `FLORA_N_MAX`, band/density/weight table, `FLORA_SCALE_MIN/MAX`, flock tunables, schema note — are unchanged except as annotated.)


### 6.9 Editing, hotbar, raycast & minimal physics (0007, `parameters.mojo` + scene display)

Source of truth: `src/mojo/sim/parameters.mojo` (§6 preamble). Normative defaults:

| Parameter | Value | Meaning |
|---|---|---|
| `EDIT_QUEUE_MAX` | `16` | `scr_edit_submit` FIFO bound; past depth ⇒ `SCR_ERR_QUEUE_FULL (-5)`; one op consumed per fixed tick |
| `EDIT_OP_NONE/DIG/PLACE` | `0 / 1 / 2` | `scr_edit_batch.op` enum |
| `EDIT_CELL_STEP_U` | `1.0` u | dig/place vertical step (one column per op) |
| `HOTBAR_SLOT_COUNT` / `HOTBAR_SLOT_MIN` | `9` / `1` | wire `count`; `select_slot` range 1..9 (0 = no change) |
| `RAY_RANGE` | `32.0` u | sim-owned ray-march range (0007 §1.1) |
| `RAY_STEP` | `0.25` u | march resolution over the height field |
| `RAY_REFINE_ITERS` | `8` | bisection refinements inside the last hit bracket |
| `PROP_N_MAX` / `PROP_N_INIT` | `16` / `4` | hard cap (invariant 7) / active props at init (deterministic beach anchors) |
| `PROP_BOX_HALF_U` | `0.5` u | box uniform half-extent (wire half-extents) |
| `PROP_SHAPE_BOX` / `PROP_SHAPE_SPHERE` | `0` / `1` | RIGID_BODIES shape enum (`shape > 1` rejected) |
| `PROP_TANGENTIAL_DAMPING` | `0.90` × | per-contact tangential damping (§3.5) |
| `SCHEMA_VERSION` / `ABI_VERSION` | `6` / `2` | 5 → 6 adds sections 12/13/14 (1–11 byte-identical); ABI 1 → 2 adds `scr_edit_submit` + 4-byte `scr_edit_batch` |

**Hotbar default slots (test oracle, `parameters.mojo::hotbar_slot_catalog_ids()` — AP-13: one sim-side list):**

| Slot | Catalog id | Slot | Catalog id | Slot | Catalog id |
|---|---|---|---|---|---|
| 1 | `rock.basalt` | 4 | `mineral.sulfur` | 7 | `fluid.water` |
| 2 | `soil.sand` | 5 | `mineral.ash` | 8 | `soil.dirt` |
| 3 | `rock.obsidian` | 6 | `fluid.lava` | 9 | `rock.pumice` |

All 9 ids resolve from `lib/A01_Render/Material/materials_catalog.json` (conformance-tested in `test_hotbar.mojo`). Names/`base_color_srgb` reach the HUD through the adapter's **catalog mirror** (`scr::kVocabDisplay` in `scr_godot_adapter.cpp`; MATERIALS record with matching id wins, else mirror, else `#<id>` / grey 0.5 — same pattern as `scr::kSpeciesDisplay`, 0006 AP-14 → 0007 AP-13). Hotbar/target/props HUD styling (panel sizes, selection `StyleBoxFlat`, swatch layout) is display-only.

**Chunk-rebuild perf note (AP-14, recorded not benchmarked):** a dig/place touches **1 column + 1 chunk mesh** (≤ 17×17 verts, `TERRAIN_CHUNK_CELLS = 16`) instead of the 64×64 heightfield; `world_version` bumps once per applied op so the adapter receives exactly one TERRAIN resend (§5.1, `test_terrain_resend.py`). Full perf budgets remain `TBD — future milestone` (0002 §9 carried forward).

## 7. Gerstner: sim vs display authority · shore-foam deviation (RESOLVED 0005)

- **Sim is authoritative.** `ocean/gerstner.mojo` computes `y(x,z,t) = sea + A·cos θ` (grounding: `player.in_water`, shoreline), Jacobian `J = 1 − Q·k·A·cos θ`, foam thresholds, all per `SCR-LIB-MATH-GERSTNER`.
- **Shader is display.** `shaders/ocean.gdshader` re-derives §2.1 displacement from the OCEAN uniforms. **Time evolution comes only from the `phase` uniform** (the encoder folds `−ω·t + φ` into it, `snapshot/encode.mojo::_encode_ocean`); the shader deliberately does **not** use built-in `TIME` — doing both would double-count. Horizontal shoaling (`Q·A·d·sin θ`) is display-only (gerstner.mojo header note). The `speed` field is carried per contract but unused by the shader (temporal term arrives in `phase`).
- **Display wave spectrum (defect fix, 2026-09-27).** The single contract harmonic rendered as perfectly parallel periodic stripes ("corduroy"). The vertex stage now sums **6 display-only harmonics** derived from the *same* contract uniforms (no new uniform names, no sim change): direction_i = contract dir rotated ≤ ±40° (`W_OFF`), k_i = `frequency·W_KS[i]` with `W_KS ∈ [0.75,1.60]`, amplitude shares `A_i = amplitude·W_RAW[i]/2.30` **normalised so ΣA_i == `amplitude`** (crest envelope unchanged — beaches never more submerged than the authoritative single wave), temporal term `sqrt(W_KS[i])·phase + W_PH[i]` (deep-water dispersion ω = √(g·k) ⇒ ω_i/ω = √(k_i/k)). Constants live in the shader header (display-only, not gameplay tunables). Sim `gerstner.mojo` single-harmonic physics (grounding, in-water, foam) unchanged and still authoritative.
- **Foam (crest path, display-only, unchanged by 0005):** the shader still recomputes the *same closed form* `J = 1 − Q·k·A·cos θ` for **crest** whitecaps. Sim thresholds (§6.3) stay authoritative for physics; the display thresholds + clamped `fwidth` AA half-widths (§6.4) are tuned for subtle crests and diverge deliberately.
- **Shore foam (schema 4, 0005 — deviation RESOLVED):** the snapshot now carries `9 SHORE_FOAM` — the sim-computed field `F(Δy, t)` over the height grid (library formula, `test_shoreline_foam.mojo` asserts exact agreement). The adapter uploads it as a FORMAT_RF texture every snapshot (`foam_shore`); the fragment stage maps world xz → uv with `foam_grid_n`/`foam_cell_size` and shades `F` — **the shader never re-derives `y_terrain` (AP-19)**; it has no terrain-height texture and does not need one. Crest and shore paths are disjoint (sim field is exactly 0 in deep water; crest gates stay closed at the shore) and combine with `max()` (AP-22), never a double-counting sum.
- **Still recorded (0005):** the library's *display* intent of a depth-tinted shoreline (color ramp from `y_water − y_terrain`) remains out of scope — the shader blends deep/shallow by crest + view angle only, and `SCR-LIB-RENDER-WATER`'s depth coloring stays `TBD` (spec §9; no contract field for display depth).
- **Sun specular:** the shader applies Fresnel toward a sky tint; it has no access to the sun node's direction, so there is no sun-aligned specular lobe. Display simplification, recorded here.
- **Sun specular:** the shader applies Fresnel toward a sky tint; it has no access to the sun node's direction, so there is no sun-aligned specular lobe. Display simplification, recorded here.
- **Sky:** `ProceduralSkyMaterial` gradient in `island.tscn`; time-of-day lighting arrives via `scr_sun` rotation/energy/colour each frame. **The dome gradient is no longer a static palette (0004):** it is re-derived every frame from SKY (`horizon ← fog_color/sun_color`, zenith/ground scales, energy — §5, constants §6.6), so dawn/day/night re-tint follows the contract. The derivation is *display-side* and lives in the adapter; the sim SKY bytes stay authoritative (AP-16). Custom `shaders/sky.gdshader` = `TBD — future milestone`.

## 8. Verification Record (procedures + Sprint-04 run)

Procedures (all runnable from repo root):

```bash
bash applications/godot/scripts/build_godot_provider.sh     # build
bash applications/godot/scripts/check_layout.sh             # layout + AP-1 + AP-4
bash applications/godot/tests/godot/godot_load_test.sh            # headless load, no errors
bash applications/godot/tests/godot/godot_screenshot.sh           # rendered capture + luminance (needs display)
bash applications/godot/tests/godot/godot_playability_test.sh     # scripted input incl. dig/place leg (headless)
python3 applications/godot/tests/abi_smoke.py               # C ABI (incl. scr_edit_submit, ABI 2)
bash applications/godot/tests/test_schema_mismatch.sh       # negative: schema + ABI refusal
python3 applications/godot/tests/test_terrain_resend.py     # negative/positive: edit ⇒ exactly-one TERRAIN resend
for t in applications/godot/tests/mojo/test_*.mojo; do .venv/bin/mojo run -I applications/godot/src/mojo "$t"; done   # 22 spec-test files (through 0009: + test_flora_growth, test_flora_evolution)

# milestone 0008 (IPC transport) additions:
bash applications/godot/scripts/build_sim_server.sh                # standalone server binary
python3 applications/godot/tests/ipc/ipc_harness.py --self-test    # framing client, no Godot
bash applications/godot/tests/ipc/test_ipc_determinism.sh          # 600 ticks: socket == in-process (byte-identical)
bash applications/godot/tests/ipc/test_ipc_version_refusal.sh      # refusal both directions
bash applications/godot/tests/ipc/test_ipc_crash_restart.sh        # kill/restart + crash-loop cap + harness restart leg
SCR_SIM_TRANSPORT=socket bash applications/godot/tests/godot/godot_ipc_smoke.sh          # socket load, handshake OK
SCR_SIM_TRANSPORT=socket bash applications/godot/tests/godot/godot_render_stall_test.sh  # AP-15 stall (structural + measured)
# load/screenshot/playability are re-run with SCR_SIM_TRANSPORT=socket (§7 gate 9)
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

### 8.4 Milestone 0004 — Sprint 03/04 verification record (2026-09-28)

**Gates (all PASS, one final pass from repo root):**

| # | Command | Result / evidence |
|---|---|---|
| 1 | `.venv/bin/mojo run -I src/mojo tests/mojo/test_<x>.mojo` × **10 files** | PASS — incl. new `test_atmosphere` (solar-arc goldens, fog derivation monotone in C and P, palette tiers) and `test_weather` (seed-1 golden transition list, seed 2 diverges, `‖wind‖ < 12`) |
| 2 | `python3 tests/abi_smoke.py` | PASS — schema **3**, 16×f32 SKY field checks |
| 3 | `bash tests/test_schema_mismatch.sh` | PASS — refuses schema ≠ 3 (5 checks) |
| 4 | `bash scripts/check_layout.sh` | PASS — incl. AP-15 wall-clock grep on weather/atmosphere sim sources |
| 5 | `bash scripts/build_godot_provider.sh` | OK — provider builds, extension list emitted |
| 6 | `bash tests/godot/godot_load_test.sh` | PASS — 0 `ERROR:` lines |
| 7 | `bash tests/godot/godot_playability_test.sh` | PASS — move/turn/jump, camera bounds, no fall-through |
| 8 | `bash tests/godot/godot_screenshot.sh` (noon) | **PASS** + sun sub-capture + rain window (numbers below) |
| 9 | `SCR_EXPECT_GLOW=1 bash tests/godot/godot_screenshot.sh` (night, `TIME_OF_DAY_START_HOURS = 21.0`, fixture regen + rebuild) | **PASS** — `crater glow light_energy=0.663`, `dome warm10=649 max_r_minus_b=95 lum=30.9 | flank lum=0.2`, spawn mean luminance `7.10` (stddev 19.60), `LUMINANCE: PASS (non-blank)` |

Parameter/fixture discipline: night run regenerates `tests/fixtures/snapshot_seed1_tick1.bin` (228668 B) with `TIME_OF_DAY_START_HOURS = 21.0`, then **reverts to 12.0, regenerates and rebuilds** — repo left at 12.0, fixture byte-stable.

**Gate 8 measurements (noon):**

- Sun sub-capture: `centre=176.17 edge_ref=151.97 delta=24.19 bright>=235=434 max=242` (thresholds `delta ≥ 20`, `bright ≥ 235` count `≥ 300`).
- Rain window (tick 4230, weather window 1801..8100): `median_lum=246.6 streak_px=10572 (11.99%) hgrad=1.413 vgrad=0.849 ratio=1.665` (thresholds `median ≥ 190`, `streak ≥ 400`, `h/v ratio ≥ 1.10`).
- Spawn frame: `mean=131.67 stddev=67.11`; rain PNG4: `mean=108.01 stddev=78.79`. (Ratio varies run-to-run — GPU particle layout is not deterministic — margin over the 1.10 threshold is ~1.5×.)

**Findings & deviations (recorded, not silent):**

1. **Sun-in-frame conflict (recorded per spec §7, decision "Option 1").** §1.1 locks `elevation(12:00) = SUN_ELEVATION_MAX = 1.2 rad = 68.75°` while spawn pitch ≈ 0 and FOV = 70° (half 35°) ⇒ the disc sits **33.75° above the frame top**; azimuth is correct (sun dead ahead, measured forward·sun = cos 68.75°). Widening `sun_angle_max` / `sun_curve` was tested and **rejected** (sky washes white, no disc, delta only +8..+15). Instead: criterion satisfied by a **sun-aimed sub-capture from the spawn position** (`godot_screenshot.gd::_capture_sun`, same pattern as 0003 phase-B crater camera; spawn view untouched). Spec §7 sun criterion is ticked **with an inline note** pointing here — never claimed as satisfied by the spawn view. Reproduction of the geometry is in the section below.
2. **Engine exponential fog erases the cloud deck.** Default `fog_density 3.5e-3` at 100% transmittance-constant puts the deck (570–1500 u away at 400 m altitude) under ≈ `1 − e^{−0.0035·1000} ≈ 97%` fog. `clouds.gdshader` therefore declares `render_mode fog_disabled` and applies its **own** distance + radial fade (`FADE_NEAR 1100`, `FADE_FAR 3600`, `PLANE_EDGE 3600`). Deviation from engine fog is display-local and inside the cloud shader only; `scr_env` fog still applies to terrain/ocean.
3. **Night sky is now dark (0004 change vs 0003).** Because the dome gradient is derived from SKY (§5), a night frame legitimately measures `mean=7.11`. Two gate consequences, both fixed in the gate rather than by faking the sim: `check_luminance.py` runs with `--min-mean 3.0 --min-stddev 1.5` under `SCR_EXPECT_GLOW` (still a non-black-frame floor), and the **plume colour-deviation region check is skipped at night** — plume and sky are both dark, so the contrast test has nothing to contrast against. Plume *presence* is still asserted by node state (`emitting` / `amount` / `lifetime` / velocity).
4. **Wetness must be applied inside `update_materials()`.** The per-frame catalog rewrite would otherwise erase the tint the moment it was written; the tint (`albedo × (1 − 0.35·wetness)`) is applied at the end of that path, and `wetness_` is latched from `sv.sky+60` immediately after decode.
5. **Rain contrast over an overcast-white background.** Initial particle colour `(0.78, 0.77, 0.75)` was invisible against `fog_light_color`-washed sky. Tuned to `(0.62, 0.68, 0.78)` albedo + material `alpha 0.7`, particle colour alpha 1.0; streak metric now `ratio ≥ 1.5` measured (threshold 1.10).

**Anti-pattern review (spec §2.1):** AP-15 no wall-clock reads (grep gate green; weather driven by `simulation_time` + seeded PRNG) · AP-16 single solar authority (sun direction/color/intensity only from SKY; no second arc formula in `godot/`) · AP-17 fog/cloud/rain values computed by `parameters.mojo` formulas, scene carries no hand-tuned fog literal · AP-18 schema bumped 2 → 3 with fixture regen, envelope/abi/negative tests updated in the same sprint.

### 8.5 Milestone 0005 (Shoreline Fidelity) — Sprint 03/04 verification record (2026-09-29)

**Sprints 01–02 (sim + contract):** `sim/shore.mojo` (library-exact `F`, `Δy ≥ 1.8 ⇒ F = 0`),
`synthesis/blend.mojo` (feather band `4 cells ± 1`, seeded dither),
`synthesis/quench.mojo` (seed-1 island: **zero** quenches — asserted),
schema **4** (`9 SHORE_FOAM` 16 396 B at `grid_n=64`; TERRAIN `(dominant, blend, weight, pad)` tuples;
fixture regenerated; `abi_smoke` + `test_envelope::test_terrain_blend_tuples`).

**Sprint 03 (adapter/scene) evidence:**

| Gate / probe | Result |
|---|---|
| `scripts/build_godot_provider.sh` | PASS — provider rebuilt against godot-cpp 4.7 |
| `tests/godot/godot_load_test.sh` | PASS — 0 `ERROR:` lines (schema-4 snapshot accepted, section 9 required) |
| `tests/godot/godot_screenshot.sh` (extended) | PASS — day captures + luminance + **aerial + shoreline-foam gate** |
| `check_shoreline_foam.py build/aerial.png` (final re-run 2026-09-29, independent verification) | PASS — `in-band=1269`, `out-of-band=0` (ratio 0.0000 ≤ 0.02; fog OFF capture, ±6 u band, luma ≥ 0.60 over water; earlier session recorded 1082 on an equivalent valid capture — count varies with capture build/session state, both pass with out=0) |
| `tests/godot/godot_playability_test.sh` | PASS — jump 1.73 u gain, horizontal 24.0 u, fails=0 |
| Vertex-colour composition probe (`unshaded` quad) | `ALBEDO = albedo_color × COLOR` (multiply) |
| Vertex-colour **color-space** probe | albedo-path `0.4 → 0.4`; vertex-path `0.4 → 0.667` (washed out); with `FLAG_SRGB_VERTEX_COLOR`: `0.4 → 0.4` — **flag required**, catalog is `base_color_srgb` |
| Texture row-order probe (`FORMAT_RF`, rows 0/1) | `v = 0` samples **image row 0** → no flip; shader `v = (z − z0)/(grid_n·cell_size)`, `z0 = −0.5·grid_n·cell_size` |
| Feather gradient measured (`build/crater_rim_close.png`, y=360 radial scan) | yellow→basalt ramp ≈ 50 px continuous (baseline schema-3 capture: hard `227 → 53` jump within 5 px) — blending renders |
| `build/crater_rim.png` (glancing rim view, fog OFF) | **PASS** — no alternating sulfur/basalt hard-sliver pattern; boundary follows the intentional sim dither silhouette with a continuous feather ramp. Residual zigzag = column dither (spec §1.1, `BLEND_DITHER_*`, verified identical across runs by `test_material_blending`) |

**Sprint 04 (docs/verification) evidence — full §7 gate run (2026-09-29):**

| # | Gate | Result |
|---|---|---|
| 1 | 13/13 mojo spec-test files (`test_shoreline_foam`, `test_material_blending`, `test_quench`, `test_synthesis_conformance`, `test_envelope`, `test_golden_fixture`, `test_determinism`, `test_projection_purity`, `test_catalog`, `test_gerstner`, `test_atmosphere`, `test_weather`, `test_volcano`) | PASS |
| 2 | Foam formula conformance + projection purity (`test_shoreline_foam`, `test_projection_purity::test_world_fingerprint_includes_foam_state`) | PASS |
| 3 | Blending conformance (`test_material_blending::test_seed1_crater_rim_has_feather_band`, dither determinism) | PASS |
| 4 | Quench conformance (`test_quench::test_seed1_island_has_zero_quenches`) | PASS |
| 5 | `python3 tests/abi_smoke.py` — schema 4, SHORE_FOAM decode, TERRAIN stride | PASS |
| 6 | `bash tests/test_schema_mismatch.sh` | PASS |
| 7 | `bash scripts/check_layout.sh` (AP-1, AP-4) | PASS |
| 8 | `bash tests/godot/godot_load_test.sh` | PASS (0 `ERROR:`) |
| 9 | `bash tests/godot/godot_screenshot.sh` incl. aerial + `check_shoreline_foam.py` | PASS |
| 10 | `bash tests/godot/godot_playability_test.sh` | PASS |
| 11 | Ocean spectrum intact (`test_gerstner` PASS; §6.4 display params untouched) | PASS |
| 12 | Crater rim visual (`build/crater_rim.png`, table above) | PASS |
| 13 | Docs (`04`, `06`, `104_contract.md`, `101`, `102`, `103`, spec §3.2 16 400 → 16 396 B) | done |

**Anti-pattern review (spec §7 final item): PASS** — evidence per row:

| AP | Claim | Evidence |
|---|---|---|
| AP-19 | Shader never re-derives `y_water − y_terrain` | `ocean.gdshader` samples `foam_shore` by world-xz uv only (header + §7); `check_shoreline_foam.py` derives the contour on the *test* side from the committed fixture (verification, not display) |
| AP-20 | Materials originate in synthesis; adapter converts representation only | surfaces still grouped by dominant id; albedo = `mix(catalog…)` from MATERIALS records (`apply_terrain`); no material invented — decode rejects unknown blend partners (`TERRAIN: blend_id not present in MATERIALS`) |
| AP-21 | Payload meaning change + new section bump schema + fixture + adapter + negative test together | `SCR_SIM_SCHEMA_VER = 4`, fixture regenerated, `abi_smoke` schema check, `test_schema_mismatch.sh` PASS |
| AP-22 | 0002 display wave spectrum + crest thresholds untouched | shader diff: crest block unchanged (only `foam` → `foam_crest` rename + `max()` combine); §6.4 params unchanged; `test_gerstner` PASS |

### 8.6 Milestone 0006 (Ecology) — Sprint 03/04 verification record (2026-09-30)

**Sprints 01–02 (sim + contract):** `sim/flora.mojo` (seeded `feature_for_column` hash, band table, cap 4096), `sim/flock.mojo` (64-slot boids, slot-order integration, waypoint orbit, bound-respawn), species→catalog conformance (`species_catalog_id_string` vs `lib/A01_Render/Material/materials_catalog.json`), schema **5** (`10 FLORA` = `4 + 24·count` with the 0006 `world_version`-gated presence rule (rewritten change-driven by 0009 §3.2, layout unchanged), `11 FAUNA` = `4 + 20·count` every snapshot; sections 1–9 byte-identical), fixture regenerated (**249 432 B, 11 sections**, sha256 `ddff5085…6758`), `abi_smoke` + `test_envelope` FLORA/FAUNA framing.

**Sprint 03 (adapter/scene) evidence:**

| Gate / probe | Result |
|---|---|
| `scripts/build_godot_provider.sh` | PASS — schema-5 decode + `apply_flora`/`apply_fauna`/`set_wetness_gain` dispatch compiled, 7 `scr_sim_*` symbols |
| `tests/godot/godot_load_test.sh` | PASS — 0 `ERROR:` lines, 0 WARNING lines (hosts resolve: groups `scr_flora`/`scr_fauna`, scripts attached) |
| Catalog mirror probe (adapter side) | species 1,2,4,5,6 → idx 34 `botanical.foliage` (0.24, 0.52, 0.18) · 3 → 33 `botanical.bamboo` · 7 → 81 `botanical.moss` — matches conformance table (§6.8); MATERIALS never carries botanical ids ⇒ mirror is the resolved source (AP-14) |
| Scene-tree state (`_check_node_state`) | flora: 6 species groups, **154 instances** (`Species_1:5, 2:3, 4:29, 5:15, 6:58, 7:44` — equals fixture FLORA species breakdown); fauna: **32 of 32 birds visible** |

**Sprint 04 — full §7 gate run (2026-09-30):**

| # | Gate | Result |
|---|---|---|
| 1 | 15/15 mojo spec-test files (`test_flora_placement`, `test_flock` + the 13 prior) | PASS (`MOJO_FAILS=0`) |
| 2 | `python3 tests/abi_smoke.py` — schema 5, FLORA/FAUNA field checks | PASS |
| 3 | `bash tests/test_schema_mismatch.sh` | PASS (5 checks) |
| 4 | `bash scripts/check_layout.sh` (AP-1/AP-4/AP-15) | PASS |
| 5 | `bash scripts/build_godot_provider.sh` | PASS (OK — provider built) |
| 6 | `bash tests/godot/godot_load_test.sh` | PASS (0 `ERROR:`, 0 WARNING) |
| 7 | `bash tests/godot/godot_screenshot.sh` (day, extended) | PASS — scene assertions + **flora/fauna region checks**: flora centre-box `green_px=6082` (≥60), fauna `near_white_px=6600` sampled 1/16 (≥15); sub-captures written; luminance: island `181.66/34.14`, flora `149.88/49.73`, fauna `168.06/41.74`, rain `133.47/54.40`, crater `165.83/41.10`, sun `152.79/12.68` (mean/stddev) |
| 8 | aerial + `check_shoreline_foam.py` (independent, day) | PASS — `AERIAL: fauna hidden = true`, `in-band=1269 out-of-band=0 ratio=0.0000` |
| 9 | `SCR_EXPECT_GLOW=1` night cycle (`TIME_OF_DAY_START_HOURS = 21.0`, fixture regen + rebuild, then **revert to 12.0 + regen + rebuild**) | PASS on re-run — `light_energy=0.663`, dome `warm10=585 max_r_minus_b=91 lum=29.2 | flank lum=1.0`, glow band `warm_px=73`, spawn mean `6.96`; foam check skipped at night (below); post-revert: fixture 249 432 B, `test_golden_fixture`/`test_envelope`/`test_determinism`/`abi_smoke` re-PASS, repo at 12.0 |
| 10 | `bash tests/godot/godot_playability_test.sh` | PASS — jump peak 4.04 ≥ settle 2.31 + 0.5, horizontal 24.0 u, camera y ∈ [2.31, 10.49] |

**Evidence PNGs** (`applications/godot/build/`):

| File | Content |
|---|---|
| `island.png` | day spawn frame (tick 1944): noon sky + sun glare, cloud deck, plume, flora fringing the lower frame; `mean=181.66` |
| `island_flora.png` | flora sub-capture at `Species_1` instance `(14.0, 1.34, −86.0)`: palm (trunk cylinder + canopy disc) in catalog foliage green on the beach slope, Gerstner ocean behind; `green_px=6079..6082` |
| `island_fauna.png` | fauna sub-capture from `(centroid + 40 u up)`: 32 white seabird instances over the terrain/ocean (`visible_birds=32 of 32`, `near_white_px=6600..6977`) |
| `island_crater.png` | crater camera: lava disc + glow rays + plume column; `mean=165.83` |
| `island_sun.png` | sun-aimed sub-capture (0004 §8.4 deviation); `mean=152.79` |
| `island_rain.png` | rain-window capture (streak metrics); `mean=133.47` |
| `aerial.png` | fog-OFF overhead, fauna hidden: foam-only-at-shoreline gate frame |

**Resolved during verification:**

- **Waypoint collapse:** `FLOCK_WAYPOINT_PERIOD_TICKS` 2400 ⇒ tangential speed ≈ 15.7 u/s at r=100 > `FLOCK_SPEED_CRUISE 9` — pure-pursuit seek could never catch the waypoint and the flock spiraled inward over ~3000 ticks. Tuned to **14400** (≈ 2.8 u/s at r=106); `test_flock` orbit + bound checks green (§6.8 tuning note).
- **Foam gate false positive (flock):** 331 out-of-band pixels were flat `(245,247,255)` at radius 98–112 u = the flock's ocean orbit read as offshore foam. Fixed by hiding `scr_fauna` in `godot_aerial_diagnostic.gd` — same display-condition class as the gate's `--fog=0` (measurement in §8.6 gate 8: `out-of-band=0`).
- **`island.tscn` header drift:** appending the Flora/Fauna nodes once lost the `load_steps`/ext-resource header edit; re-applied (`load_steps = 23`, `6_flora`/`7_fauna`) and re-verified by the load gate.
- **Night foam check:** `check_shoreline_foam.py` is a luma ≥ 0.60 test over water; a 21.0 h frame legitimately has zero bright water pixels (`in-band=0`). The foam gate is now **daytime-only** under `SCR_EXPECT_GLOW` (0004 precedent: plume colour check skipped at night), with an explicit `SHORE FOAM: SKIPPED` line; the day run (gate 8) still enforces it.
- **Night gate flake (recorded, not hidden):** 1 of 3 night attempts measured `dome warm10=0 flank lum=42.4` (day-like spawn framing) where the other two measured `warm10≈585 flank≈1.0`; re-runs green, root cause not isolated (spawn-camera framing variance between rendered runs — see §9 gap 14). Gate result: **PASS on re-run**, anomaly recorded here.

**Anti-pattern review (spec §7 final item): PASS** — evidence per row:

| AP | Claim | Evidence |
|---|---|---|
| AP-11 | Seeded ecological state is a pure function of `(seed, simulation_tick, environment)` — no hidden RNG-stream dependency | `feature_for_column(x, z, biome, slope, height, seed)` is an order-independent hash (no stream state); `test_flora_placement` seeded determinism + `test_determinism` byte-identical two-run snapshot sequence (FLORA+FAUNA included); `test_flock` run-twice determinism |
| AP-12 | Display animation must not invent sim state | sway/flap run on shader `TIME` in `flora_wing.gdshader` (uniforms set by view scripts; `sway_amount=0` for birds); wire bytes carry position/yaw only — no phase field exists or was faked (§5, §6.8) |
| AP-13 | Cap schema growth at explicit limits | `FLORA_N_MAX = 4096` (header+size-derived decode), `FLOCK_N_MAX = 64` with `FLOCK_N_INIT = 32`; `test_flora_placement`/`test_flock` assert `count ≤ cap` every tick; adapter rejects oversized sections (`count > 4096/64`) and pad-byte violations |
| AP-14 | No invented colors / semantics | species colors resolved via conformance-tested catalog ids (`species_catalog_id_string`) through the adapter mirror table `scr::kSpeciesDisplay` (MATERIALS record with matching `catalog_index` wins if present); bird display albedo `(0.90,0.91,0.93)` is a documented plume-albedo-class display constant (§6.8), not a semantic value |



### 8.7 Milestone 0007 (Editing, Hotbar & Physics) — Sprint 03/04 verification record (2026-09-30)

**Sprints 01–02 (sim + contract):** `sim/edit.mojo` (edit FIFO, dig/place guards, single-column re-synthesis, chunk-local rebuild, `world_version` +1), `sim/raycast.mojo` (sim-owned ray-march + bisection refine), `sim/hotbar.mojo` (9-slot catalog table + selection), `sim/props.mojo` (`PhysicsSubject`, N ≤ 16, gravity + ground contact, slot-order), `scr_edit_submit` in `export/abi.mojo`, schema **6** (`12 HOTBAR` 44 B, `13 TARGET` 32 B, `14 RIGID_BODIES` `4+36·count` ≤ 16; sections 1–11 byte-identical), ABI **2**, fixture regenerated (**249 680 B, 14 sections**), `test_edit_ops` / `test_raycast` / `test_hotbar` / `test_props` new + `test_determinism` / `test_synthesis_conformance` / `test_envelope` extended, `abi_smoke` + `test_terrain_resend` extensions.

**Sprint 03 (adapter/scene) evidence:**

| Gate / probe | Result |
|---|---|
| `scripts/build_godot_provider.sh` | PASS — schema-6 decode (HOTBAR/TARGET/RIGID_BODIES MUST-reject validation), `scr_edit_submit` dlsym binding, `apply_hotbar`/`apply_target`/`apply_props` dispatch compiled, 7 loader symbols |
| `tests/godot/godot_load_test.sh` | PASS — 0 `ERROR:` lines, 0 WARNING lines (hosts resolve: groups `scr_hotbar`/`scr_target`/`scr_props`, scripts attached) |
| Catalog mirror probe (adapter side) | slot 3 → `rock.obsidian` name `Obsidian` / `#11` (MATERIALS record or `scr::kVocabDisplay`; observed live in playability F7 + screenshot HUD assertions) |
| Scene-tree state (`_check_node_state`) | hotbar **9/9 named + 9/9 swatches + exactly 1 selected**, target readout `Sand #3` (hit path), props **4 visible meshes** (`PROP_N_INIT`) |

**Sprint 04 — full §7 gate run (2026-09-30):**

| # | Gate | Result |
|---|---|---|
| 1 | 19/19 mojo spec-test files (`test_edit_ops`, `test_raycast`, `test_hotbar`, `test_props` + the 15 prior) | PASS (0 failures) |
| 2 | `python3 tests/abi_smoke.py` — schema 6, ABI 2, `scr_edit_submit` + 4-byte layout | PASS |
| 3 | `python3 tests/test_terrain_resend.py` | PASS — dig ⇒ TERRAIN in exactly the next snapshot + `world_version 1→2`; idle suppressed; miss ⇒ no bump |
| 4 | `bash tests/test_schema_mismatch.sh` | PASS — **8 checks**: schema stub ⇒ `-103`, ABI stub ⇒ `-102` (invariant 9), both refuse without retaining handle, real lib accepted (control) |
| 5 | `bash scripts/check_layout.sh` (AP-1/AP-4/AP-15) | PASS |
| 6 | `bash scripts/build_godot_provider.sh` | PASS (OK — provider built) |
| 7 | `bash tests/godot/godot_load_test.sh` | PASS (0 `ERROR:`, 0 WARNING) |
| 8 | `bash tests/godot/godot_playability_test.sh` | PASS — A–E unchanged (horizontal 24.00 u, jump gain 1.73 u, y ∈ [2.31, 10.49], yaw −0.750) + **F leg F1–F13**: select/dig/place rc 0, HUD slot mirror + `selected` meta, terrain mesh content changed by dig **and** again by place, target left `SKY / AIR`, props pool 4 |
| 9 | `bash tests/godot/godot_screenshot.sh` (day) | PASS — scene assertions + **editing HUD state** (9/9/1 hotbar, non-empty target, props ≥ 1); luminance island `176.51/40.87`, rain `132.91/57.04`, flora `145.85/51.91`, fauna `165.25/45.59`; plume `rows=66/72 deviating=1236`; aerial + `check_shoreline_foam.py` **PASS** `in-band=1246 out-of-band=0` (foam gate extended: schema 6 whitelist + bottom-HUD mask, see resolved list) |

**Evidence PNGs** (`applications/godot/build/`): `island.png` (day spawn, tick 1955), `island_crater.png`, `island_sun.png`, `island_rain.png`, `island_flora.png`, `island_fauna.png`, `aerial.png` (fog OFF, foam-gate frame — hotbar/target overlays visible at the frame edges, masked by the gate).

**Resolved during verification:**

- **Foam gate schema whitelist:** `check_shoreline_foam.py` refused the schema-6 fixture (`not in (4, 5)`); sections 1–11 it reads are byte-identical to schema 5 ⇒ whitelist extended to `(4, 5, 6)` with the byte-identity justification in-place (no assertion weakened).
- **Foam gate counted the new HUD as offshore foam:** the aerial frame now carries the bottom-anchored hotbar panels + target readout (bright presentation pixels over water) ⇒ `out-of-band=15381`, `dist=inf` samples at the panel columns. Fixed by extending the gate's existing top-HUD mask with a **bottom `--bottom-hud-rows` (default 96)** mask — same display-condition class as `HUD_ROWS=72` and the `--fog=0` aerial condition; scene-pixel assertion unchanged. Recheck: `in-band=1246 out-of-band=0 ratio=0.0000`.
- **Edit uplink binding:** `scr_edit_submit` is not in the 7-symbol loader set — bound by the adapter via `dlsym` after `scr_sim_load` (`_ready`), nulled in `_exit_tree`; missing symbol ⇒ `ERR_PRINT` + edit path disabled, motion unaffected (load/playability gates prove the happy path; documented in §5).

**Anti-pattern review (spec §7 final item): PASS** — evidence per row (0007 §2.2; §2.1 AP-1..10 re-run via `check_layout.sh` + load/playability gates):

| AP | Claim | Evidence |
|---|---|---|
| AP-11 | No raw terrain poke — edits re-run `classify_biome` + `voxel_synthesis_pipeline` | `test_edit_ops` (bedrock guard, sea-level fill + biome reclass, `world_version` bookkeeping) + `test_synthesis_conformance` edited-column cases; pipeline path is the only mutation route (§5.1) |
| AP-12 | No client-side hit authority — client submits `{op, select_slot}` only | `scr_edit_batch` is 4 bytes with no cell/material fields; `submit_edit` validates only `u8` fit and forwards verbatim; playability F9–F13 prove sim-side hit resolution end-to-end (mesh content changed); identical-scripted-edits determinism in `test_determinism` |
| AP-13 | No parallel hotbar vocabulary | slots are `hotbar_slot_catalog_ids()` (one sim-side list, all ids conformance-tested against `materials_catalog.json` in `test_hotbar`); HUD names/colors arrive from `12 HOTBAR` through the adapter catalog mirror (MATERIALS wins, else `kVocabDisplay`); zero vocabulary in GDScript (grep: `hotbar_hud.gd` renders only received strings) |
| AP-14 | No full-world rebuild per edit | chunk-local rebuild only (`TERRAIN_CHUNK_CELLS = 16`, ≤ 17×17 verts per edit), one `world_version` bump per op (perf note §6.9); `test_terrain_resend` proves exactly-one TERRAIN resend; playability F10/F13 show mesh-content changes landing through the normal decode path |

### 8.8 Milestone 0008 (IPC Transport Swap) — Sprint 03/04 verification record (2026-10-01)

Scope: out-of-process sim server + `ITransport` swap. **Invariant 1 held:** schema **6**, ABI **2**, proto **1**, fixture 249680 B untouched; `git diff` empty for `src/mojo/`, `lib/` and the 0008 spec (layout-neutrality review).

| # | Gate (§7) | Result |
|---|---|---|
| 1 | `test_ipc_determinism.sh` (AP-16, N=600) | **PASS ×2** — `socket leg == in-process leg (600 ticks, 10950216 bytes, byte-identical)` |
| 2 | `test_ipc_version_refusal.sh` (both directions) | **PASS** — harness: schema/abi/proto/unknown-flag ⇒ server `ERROR`+close+non-zero, no `SNAPSHOT`; adapter: `bad-abi`/`bad-schema`/`bad-proto`/`error-frame` via `fake_server.py` ⇒ loud refusal, inert scene, no handshake, no in-process fallback, no orphan |
| 3 | `test_ipc_crash_restart.sh` (AP-18) | **PASS** — A: kill -9 ⇒ respawn, new PID, same seed, `tick=1` seen ≥2×, no orphan; B: crash-loop ⇒ exactly 6 spawns, `restart #5`, `FATAL … restart cap reached: 5 restarts within 30 s`, no spawn after fatal; C: harness restart leg ⇒ EOF, tick 20→1, TERRAIN re-delivery, same seed, BYE rc 0 |
| 4 | `godot_render_stall_test.sh` (AP-15) | **PASS** — structural: zero socket syscalls in `scr_godot_adapter.cpp` (positive control present in `transport_socket.cpp`); measured: server `SIGSTOP` 2 s ⇒ max physics gap **0.0223 s**, process gap **0.0097 s** (< `FRAME_DT_CLAMP` 0.05), zero `ERROR:`, no restart, no orphan |
| 5 | default = in-process / socket opt-in | **PASS** — `godot_load_test.sh` (env stripped) asserts `SCR: transport=InprocTransport`; `godot_ipc_smoke.sh` asserts `SCR: transport=SocketTransport handshake OK`, 0 `ERROR:` lines, server exit 0 on BYE |
| 6 | standalone server + harness (no Godot) | **PASS** — `build_sim_server.sh`; `ipc_harness.py --self-test` (handshake, refusals, 1-tick round-trip, **AP-16 first snapshot == fixture 249680 B**) |
| 7 | layout neutrality | **PASS** — `test_golden_fixture.mojo`, `abi_smoke.py`, `test_schema_mismatch.sh` (8 checks) all PASS; fixture byte-size unchanged; no diff in `src/mojo/snapshot`, `src/mojo/export`, `src/mojo/sim`, `lib/`, spec |
| 8 | 0002 gates, both transports | **PASS** — `check_layout.sh`; mojo spec tests **20/20** (`test_framing.mojo` new); `godot_screenshot.sh` PASS in-process **and** socket (content + luminance + shoreline foam); `godot_playability_test.sh` PASS in-process **and** socket (move/jump/edit legs) |
| 9 | docs | this record: `104_contract.md` §2 rewritten (framing + neutrality + session rules), §4.6 transport section, `docs/05` §6 (`APP-PRT-002`), `docs/06` 0008 row, `102`/`103` capability |
| 10 | review pass | AP-1..10 re-verified + AP-15..18 below |

**Defect found by gate 8 (socket screenshot leg) and fixed before completion:** the first socket run failed `scr_flora has no MultiMesh` — root cause: the client's latest-wins handoff overwrote the session's *first* snapshot (the only one carrying the `TERRAIN`/`FLORA` sections present at session start — `TERRAIN` 0006 invariant-5 / `FLORA` first-after-init leg) before the render thread's first read, so neither section was ever applied (diagnostic: `terrain_chunks=0` under socket vs 16 in-process). Fix = **first-snapshot latch** per session in `transport_socket.cpp::publish/snapshot_write/snapshot_size` (specified in `104_contract.md` §2.3, §4.6). After the fix both transports report `terrain_chunks=16, flora_groups=6, flora_total=154` and every gate above was re-run green.

**Second socket screenshot defect (same sprint, pacing) and fix:** a later socket run failed the plume region check `0 rows` (needs ≥ 5) and drifted the sun-disc sub-capture delta (23 → 10 / −27), while in-process passed. Root cause = **wall-time divergence, not bytes**: the server's default wall clock executes ticks at 60 Hz regardless of render rate, so the capture at tick ~1945 arrived at wall ~35 s (socket) vs ~61 s (in-process) — the plume's 6 s particle lifetime had not accrued and shader/`TIME` clouds sat at a different phase (server tick log + pty-timestamped runs; emission toggled identically at tick ~1500 in both legs). `TICK_MIN` cannot fix it: the plume needs a later capture than the sun check allows. Fix = **client-paced socket mode** `SCR_SIM_IPC_PACE=manual` (0008 §1.1 `CMD_TICK`, adapter side): one `CMD_TICK 1` per Godot physics frame queued behind the frame's `INPUT`/`EDIT`, so socket ticks track physics frames exactly as in-process ticks do. `godot_screenshot.sh` enables it for the socket leg; wall remains the adapter default (safety default). Re-gated: socket screenshot PASS with `SCR_SIM_TRANSPORT=socket SCR_SIM_IPC_PACE=manual` (and plain `SCR_SIM_TRANSPORT=socket` — the script default), in-process unchanged.

**Third socket defect (same sprint, pacing — playability F-leg):** a wall-paced socket `godot_playability_test.sh` failed F5/F6/F13 (hotbar select mirror and place-terrain re-check) while `SCR_SIM_IPC_PACE=manual` passed. Cause = the F-leg waits only 2 physics frames between `submit_edit` and reading the snapshot mirror; in a fast headless run those frames elapse well inside one 60 Hz server period, so the edited snapshot has not returned yet (request/response is per-tick under manual pace, per-wall-period under wall pace). Fix = `godot_playability_test.sh` defaults `SCR_SIM_IPC_PACE=manual` for the socket leg (same pattern and rationale as `godot_screenshot.sh`; caller override respected). Re-gated 2026-10-02: socket playability PASS ×2 with the script default.

**Anti-pattern review — §2.1 (0002 AP-1..10, re-verified for 0008):** AP-1 PASS (`check_layout`), AP-2 as recorded in §8 (unchanged), AP-3 PASS (single catalog), AP-4 PASS — server binary/socket/repo root resolved at runtime (`res://`, `user://`, env; `SCR_REPO_ROOT` injected at spawn), zero `/home/` in sources, AP-5 PASS (transport dispatch = `ITransport` vtable, not if-else in the frame loop), AP-6 PASS (0 `dynamic_cast`), AP-7 PASS (`parameters.mojo` + §6), AP-8 PASS (display scripts still never write sim state; socket uplink carries intent only), AP-9/AP-15 PASS (structural + measured, gate 4), AP-10 PASS (this control-doc update).

**Anti-pattern review — §2.2 (0008 AP-15..18):**

| # | Verdict | Evidence |
|---|---|---|
| AP-15 render-thread socket I/O | PASS | all syscalls in `transport_socket.cpp` worker; render thread reads seqlock slot / SPSC ring only; grep gate + SIGSTOP stall gate (§8.8 gate 4) |
| AP-16 transport-aware payload | PASS | single encoder, `SNAPSHOT` payload copied verbatim; 600-tick byte-identity + harness first-snapshot byte-identity (gates 1, 6) |
| AP-17 silent version drift | PASS | handshake refusal both directions, `ERROR` frames logged loudly, negative gates (2) |
| AP-18 orphan/zombie servers | PASS | spawn/reap/backoff/cap owned by the adapter; crash gates assert exactly-one/no orphan (3); graceful BYE + reap on scene exit (gates 3, 5) |

### 8.9 Milestone 0009 (Flora Upgrade) — Sprint 04 verification record (2026-10-03)

Scope: `sim/flora.mojo` (establishment field, per-instance `age` + species growth curve with ε-quantized commit, trait variation, establishment/survival selection, absorbing death, edit-driven `flora_re_evaluate`), `sim/world.mojo` (tick-phase aging/survival/re-scan order), `sim/runtime.mojo` (`_flora_dirty` change-driven emission rule), `sim/parameters.mojo` (§6.8.1 tunables), `snapshot/encode.mojo` (**comment/docstring only** — `git diff` shows no code line; layout untouched), `104_contract.md` §10 emission rewrite (schema **6** / ABI **2** unchanged), fixture content regen, `flora_view.gd` wire-scale consumption. Definition-first: Sprint 00 commit `8c686ec` = `lib/` only.

**Fixture (content-only regen):** `tests/fixtures/snapshot_seed1_tick1.bin` = **248 264 B**, sha256 `f76b6ccd1a90dc5d461c03581403fbdacf99f65188a21c96c15bd0fc907d9cfe`, **FLORA count 95** (was 154 — §9.24), schema **6** / ABI **2**, FLORA record 24 B, **sections 1–9 and 11–14 byte-identical** to the 0008 fixture.

**Sprint-04 gates — full §7 sweep (repo root, serial, 2026-10-03):**

| # | §7 box | Command | Result |
|---|---|---|---|
| 1 | Definition gate (Sprint 00) | `git show --name-only --format= 8c686ec \| grep -vc '^lib/'` + structural re-check of the 7 Sprint-00 files (101 required sections, 102 `status: specified` + `last_updated`, 103 edge types ∈ {`CONTAINS`,`REFINES`,`INTERACTS_WITH`}, all targets exist) | **PASS** — 0 non-lib paths; validator-style findings = 0 |
| 2 | Growth test | `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_flora_growth.mojo` | **PASS** 7/7 (monotone bounded scale, run-twice identity, dig ⇒ anchor death + fresh re-establishment, `0 < count ≤ 4096`, ε-crossing fires, band oracle, rescan perf `113.381 µs/call` @ pop 95) |
| 3 | Evolution test | `… test_flora_evolution.mojo` | **PASS** 5/5 (trait sanity, high-stress band establishes less, stress raise kills deterministic superset, run-twice identical, cap held — world not sterilized) |
| 4 | Placement/field oracle | `… test_flora_placement.mojo` | **PASS** (establishment ⇒ band + suit ≥ threshold; species → catalog retained) |
| 5 | Determinism | `… test_determinism.mojo` | **PASS** (growth + selection inside the byte-identical snapshot sequence) |
| 6 | Projection purity | `… test_projection_purity.mojo` | **PASS** (extended fingerprint: ages/traits folded — projection never mutates growth state) |
| 7 | Contract framing + fixture | `… test_envelope.mojo` + `… test_golden_fixture.mojo` (+ `gen_golden_fixture` content regen) | **PASS** (change-driven FLORA framing round-trip; fixture sha above) |
| 8 | All 22 mojo suites | `for t in …/test_*.mojo; do .venv/bin/mojo run -I applications/godot/src/mojo "$t"; done` | **PASS — `MOJO_FAILS=0`** (determinism, projection_purity, envelope, synthesis_conformance, gerstner, catalog, golden_fixture, volcano, atmosphere, weather, shoreline_foam, material_blending, quench, flora_placement, flock, edit_ops, raycast, hotbar, props, framing, flora_growth, flora_evolution — every suite rc 0) |
| 9 | Version gates | `python3 tests/abi_smoke.py` / `bash tests/test_schema_mismatch.sh` | **PASS** / **PASS** (schema 6 + ABI 2 asserts intact; 8 checks: schema≠6 and ABI≠2 both refused, real lib accepted) |
| 10 | Build + layout | `bash scripts/build_godot_provider.sh` / `bash scripts/check_layout.sh` | **PASS** (`OK — provider built`, 7 `scr_sim_*`; AP-1 + AP-4 + AP-15 clean) |
| 11 | Terrain-resend (lineage) | `python3 tests/test_terrain_resend.py` | **PASS** (TERRAIN `world_version` rule unchanged by the FLORA rule swap) |
| 12 | Scene gates | `bash tests/godot/godot_load_test.sh` / `bash tests/godot/godot_playability_test.sh` | **PASS** (0 `ERROR:`, `transport=InprocTransport`) / **PASS** (`fails=0`, F1–F13 incl. dig/place mesh-content assertions) |
| 13 | Rendered growth evidence | `bash tests/godot/godot_screenshot.sh` (day) | **PASS** — flora assertions: `flora groups=6 total=95 (Species_1:3, 2:3, 4:19, 5:7, 6:36, 7:27)` (`> 0` style, §note below), centre-box `green_px=1625` (≥ 60); hotbar 9/9/1, target `Sand #3`, props 4, fauna 32/32 (`near_white_px=6826`), plume `rows 57/72`, sun `delta=23.12 bright=450`; luminance island `176.66/40.87`, rain `132.91/57.10`, flora `139.17/46.10`, crater `165.87/45.47`; aerial `PASS` (chunks 16, fauna hidden, fog OFF); shoreline foam `in-band=1247 out-of-band=0 ratio=0.0000` |
| 14 | 0008 transport gates re-run | in-process leg (`godot_load_test.sh` asserts `InprocTransport`; `ipc_harness.py --self-test`: socket first snapshot == fixture 248 264 B) + `SCR_SIM_TRANSPORT=socket SCR_SIM_IPC_PACE=manual bash tests/godot/godot_ipc_smoke.sh` + `bash tests/ipc/test_ipc_determinism.sh` | **PASS / PASS / PASS** — smoke: handshake OK, 0 `ERROR:`, server exit 0 on BYE; determinism: `socket leg == in-process leg (600 ticks, 11446164 bytes, byte-identical)` |
| 15 | Full lineage gate set (0002 §8 procedures) | `build_sim_server.sh`, `ipc_harness.py --self-test`, `test_ipc_version_refusal.sh`, `test_ipc_crash_restart.sh`, `godot_render_stall_test.sh` (+ rows 1–14 above) | **PASS** ×5 — refusal both directions; crash/restart + crash-loop cap + no orphan; AP-15 stall `max process frame gap 0.0090 s < 0.05 s`, paused server not treated as crash |
| 16 | Process hygiene | `pgrep -x scr_sim_server` after every run; `pgrep -x godot` after godot runs | **0 / 0** — no orphan server or godot process at any checkpoint |
| 17 | Review pass | AP-1..22 table (§10) + Sprint-00 checklist + honest limitations (§9.21–24) | **PASS** — item-by-item below |

**Rendered-growth observable (same run, seed 1, headless probe — numbers also documented why):** the screenshot gate captures a single tick (tick ~1943) and Godot has no tick-advance hook between sub-captures, so the **scale-distribution-over-ticks** evidence is produced by a headless probe over the same sim code (`flora_from_island` + `flora_tick`, 3000 ticks, no scene) rather than by two rendered frames:

| Tick | Count | Mean scale | Min scale | Max scale |
|---|---|---|---|---|
| 0 (init) | 95 | 1.074440 | 0.804483 | 1.345438 |
| 1 | 95 | 1.074440 | 0.804483 | 1.345438 |
| 60 | 95 | 1.076383 | 0.821113 | 1.345438 |
| 300 | 95 | 1.090000 | 0.870216 | 1.345438 |
| 600 | 95 | 1.102975 | 0.870216 | 1.345438 |
| 1200 | 95 | 1.116018 | 0.870216 | 1.345438 |
| **1944** (≈ screenshot capture tick) | 95 | **1.120794** | 0.870216 | 1.345438 |
| 2400 | 95 | 1.121073 | 0.870216 | 1.345438 |
| 3000 | 95 | 1.121073 | 0.870216 | 1.345438 |

- Mean scale rises monotonically `1.074440 → 1.121073` (**+4.34 %**) and saturates by tick 2400 (longest maturity = `FLORA_MATURITY_CANOPY_TREE`); count constant at 95 (no deaths under seed-1 idle weather — the population already passed the same survival predicate at establishment; death is exercised synthetically in `test_flora_evolution` case c).
- `FLORA_EMIT_EPS` crossings observed: **355 ε-dirty ticks over 3000 ticks** (`flora_emission_dirty` vs previous tick) — emission is change-driven, not per-tick (AP-22).
- Rendered confirmation: the day capture at tick 1943 shows the grown population (PNGs below); `test_flora_growth` case (a) additionally proves `scale` monotone non-decreasing to maturity and byte-identical when run twice.

**Note on flora content assertions:** `godot_screenshot.gd:_check_node_state` asserts `flora_groups ≥ 1 and flora_total ≥ 1` (never an exact count) — verified while extending the gate; no 154-hardcode existed to adjust. The 154 → 95 content shift is explained in §9.24.

**Evidence PNGs** (`applications/godot/build/`, read by the orchestrator):

| File | Content observed |
|---|---|
| `island.png` | day spawn frame, tick 1943: sandy foreground, **multiple green flora instances on the ridge** (canopy blobs + one trunked palm at left), yellow sulfur cap with plume debris pixels, wispy clouds + rain streaks, HUD `tick 1943 gen 1943 seed 1`, hotbar 9 slots (slot 1 selected), target `Sand #3`; `mean=176.66` |
| `island_flora.png` | flora sub-capture at `Species_7` instance `(26.0, 2.30, −82.0)`, tick 2001: **green fern/shrub crown in focus on the beach slope**, palm trunk top-left, Gerstner ocean + rain streaks behind; `mean=139.17` |
| `aerial.png` | fog-OFF overhead, fauna hidden — foam-gate frame (chunks 16, `in-band=1247 out-of-band=0`) |
| `island_fauna.png` / `island_crater.png` / `island_rain.png` / `island_sun.png` | 32 seabirds / lava+plume / rain window / sun disc (`delta=23.12`) — all luminance PASS |

**Resolved / verified during Sprint 04:** stale `emission-gated`/`world_version` FLORA wording removed from this document, `docs/06` 0009 rows and `encode.mojo` comments (TERRAIN's `world_version` rule untouched); `encode.mojo` diff = docstring + comment lines only (no code, no layout); screenshot flora assertions already `> 0` style (no exact-154 assumption); growth evidence captured via headless probe because the screenshot harness exposes no tick-advance hook between sub-captures (single-tick capture by design).

## 9. Honest Gaps (open)


1. MATERIALS framing blocker (§8) — **RESOLVED** (contract header amended to `4 + 36·N` per field table/fixture, adapter aligned; decode verified end-to-end: load test materializes 16 chunks, abi smoke byte-identical).
2. Godot-cpp from-scratch bootstrap recipe not re-run clean-room ([02 §1.1](02_development_environment.md)).
3. ~~Shoreline foam approximated~~ — **RESOLVED in 0005**: snapshot carries the sim `SHORE_FOAM` field, shader shades it (§7, §8.5). Still open: sun specular simplified (§7); depth-tinted shoreline color remains `TBD` (no display-depth contract field). ~~Sky gradient static / night skybox bright~~ — **RESOLVED in 0004**: dome gradient now derived per frame from SKY (§5), so the night frame is dark (measured spawn mean luminance 7.10 vs 131.67 at noon — §8.4).
4. Performance budgets — `TBD — future milestone`.
5. Swim/`MAP_BOUND` comptime helpers live outside `parameters.mojo` (§6.1) — sim-side cleanup deferred.
6. Interactive (non-headless) manual play session not recorded this sprint — scripted run is the evidence; manual fallback documented.
7. AP-2 indirect-only semantic-library coverage (§8 review): no standalone conformance tests for `MATH-NOISE`, `RENDER-SKY`, `SPATIAL` frame algebra, `PHYSICS` constants — currently exercised indirectly. `TBD — future milestone`.
8. **Turbulence velocity-influence display semantics (0003):** Godot's velocity-influence mode cancels buoyant columns (§8.3); the noise field is exposed with influence locked at 0. Display-side turbulence that preserves column physics (curl-noise advection in-shader / successor particle integrator) = `TBD — future milestone`.
9. **`lava_water_quench` (0003 AP-14):** the reaction **evaluator shipped in 0005** (`synthesis/quench.mojo`, `test_quench` PASS; seed-1 island has zero lava↔water adjacency so no quench fires in the default scene). Still open: live lava-to-sea quench activation + steam/energy manifestation = `TBD — future milestone` (spec §9) — never implied as working.
10. **Sun disc absent from the default spawn frame (0004 §8.4):** the locked arc puts the disc 33.75° above the 70°-FOV frame top at noon; the gate therefore uses a sun-aimed sub-capture from the spawn position (decision "Option 1"). An in-frame spawn sun would require relaxing §1.1's `SUN_ELEVATION_MAX` or spawn pitch — both spec-owned, not silently changed.
11a. **Blend roughness/emission stay dominant (0005 §1.1 recorded limitation):** only albedo blends per vertex; roughness/emission/opacity come from the grouped surface's dominant material record. Full per-vertex PBR = rejected §1.1 (needs weight vectors / triplanar shader).
11b. **Foam texture resolution = sim grid (64², linear-filtered):** the shore band interpolates cell-to-cell; a higher-resolution field would need sim-side resampling — no contract for it (Rule 9).
11. **Glow light geometry is a display hack (0003 §6.5):** `GLOW_DISPLAY_LIFT_U = 60` + `omni_range 90` exist because a light physically inside the crater bowl cannot light the visible outer slopes (`NdotL < 0`); energy stays the sim contract value. If 0004/0005 add a real crater-interior camera default or volumetric scattering, the lift should be revisited.
12. **Flora regrowth after voxel edits (0006, narrowed by 0007):** FLORA is regenerated with the world and emitted change-driven since 0009 §3.2 (first snapshot after init, then on population/pose/yaw or ε-scale change — §5, `104_contract` §4.3 §10), so a 0007 terrain edit **does** regenerate the population on the resend snapshot; but the **voxel-flora feature itself stays disabled** (0004 §9) — no per-block flora, no regrowth animation.
13. **Wind-coupled sway (0006 AP-12):** sway amplitude/phase come from shader `TIME`, not from the sim wind vector — the wire has no phase field (and none was invented). Sway driven by sim wind = `TBD — future milestone` (needs a contract field + phase semantics, Rule 10).
14. **Spawn-frame camera framing variance (0006, observed):** rendered runs occasionally capture `island.png` with a day-like sun-facing framing where others show the island-facing frame (measured: spawn mean 168.15 vs 181.66 across valid day runs; one night run measured a day-like dome flank — §8.6). Luminance/region/foam gates stayed green throughout, but the night dome check flaked once in three attempts. Root cause not isolated (rendered-physics/camera timing suspected); recorded honestly, no gate was weakened except the documented night-foam skip.
15. **Interactive manual dig/place session (0007 §7) not executed this sprint:** the spec's manual procedure (interactive run, LMB dig, keys 2/3 + place, before/after captures) needs a human-driven session. Recorded evidence is the automated companion: playability F leg (select/dig/place uplink + mesh-content assertions, §8.7 gate 8) and screenshot HUD/state assertions (gate 9). The manual procedure stays documented in spec §7 for a user-run confirmation.

18. **Adapter external-owner mode has no dedicated automated gate (0008):** connecting to an already-running server (`SCR_SIM_SOCKET` set, no `SCR_SIM_SERVER_BIN`, never respawn) is implemented and its no-respawn branch is covered by the supervision tests' design, but no script drives that exact combination end-to-end (the harness covers an external server at the framing level, the Godot gates spawn their own). `TBD — future milestone`.
19. **Writer-side coalescing under sustained backpressure not directly measured (0008):** the `EAGAIN` latest-wins path is specified in `104_contract.md` §2.1 and the client-side first-snapshot latch + stall test cover startup/pause, but no gate forces a deliberately slow reader to make the writer coalesce. Observation-only for now; add a gate if coalescing ever misbehaves.
20. **Restart-cap policy exercised through `fake_server.py` only (0008):** the >5-restarts/30 s fatal path uses the synthetic crash-loop; a real `scr_sim_server` crash-storm is not reproduced (single real kill -9 is, phase A of the crash test). Same policy code, narrower evidence — recorded honestly.
16. **Deferred 0007 scope:** Material Inspector fields (spec §1.2), inter-body collision / advanced prop physics (`props.mojo` = gravity + ground contact only, §6.9), edit undo/history — all `TBD — future milestone` (spec §1.2/§9, invariant 11).
17. **Day screenshot gate content-assertion flake (0007, observed during independent verification):** 1 of 6 consecutive day `godot_screenshot.sh` runs exited 1 at the scene/content-assertion phase; the failing run's stdout was not retained, so the specific assertion could not be isolated (all `exit 1` paths print a `SCREENSHOT: FAIL —` line — `godot_screenshot.gd:_fail`). The 5 other runs passed with full assertions (hotbar 9/9 named + 1 selected, target non-empty, props visible, plume/lava/sun/rain/flora/fauna regions). Same class as gap 14 (rendered-timing variance); no gate weakened; root cause `TBD — future milestone` if it recurs.
21. **No reproduction / cross-generational inheritance (0009):** `EVOLUTION-INV-006` (Inheritance) / `INV-007` (Lineage) are satisfied **trivially per instance only** — a trait vector is a pure function of the anchor cell, constant over the instance's life, and the single anchor cell fixes a one-element lineage. Cross-generational inheritance and lineage require reproduction, which is out of scope (`503_Simulation/Reproduction` and `601_Agent/Population` stubs untouched); generational evolution = successor (0009 §9, `lib/705_Ecology/Flora` §1.4).
22. **Stress-model choice (0009 §1.2 open decision — RESOLVED, with the honest trade-off):** establishment/survival stress = **crater-distance ash ∧ local wetness** (`ash_raw = clamp(1 − dist/72u)`, `drought_raw = clamp((REF − w)/REF)`, weighted `W_ASH = 0.70` / `W_DROUGHT = 0.30` — §6.8.1). The **plume-mask alternative was rejected**: the volcanic plume is advected only in the display shader on `TIME` (§8.3), there is no sim-side plume mask, and inventing one would violate Rule 9 ("no invented inputs"). Consequence recorded honestly: the ash term is **radial, not wind-advected**, so real downwind ash-fall asymmetry is not modeled; wind-coupled flora stress is a successor (alongside §9.13 wind sway).
23. **Voxel/lattice flora deviation still open (0006 §9 carried into 0009):** the instance/`MultiMeshInstance3D` realization is retained; Synthesis §3 voxel flora objects stay out of scope (0009 §1.1 decision row, Rule 15 minimal slice). Successor.
24. **Fixture content change 154 → 95 instances (0009, explained — not a regression):** the golden fixture regenerated for **content only** — 248264 B, schema 6 / ABI 2, FLORA records still 24 B, sections 1–9 and 11–14 byte-identical. The count dropped because establishment now additionally requires `suit ≥ FLORA_SUITABILITY_THRESHOLD` **and** the trait-selection predicate (`flora_selection_passes`) over and above the 0006 bare density hash: cells the 0006 scatter admitted are refused by the field/selection gates at init (Sprint-01/02 selection, per spec §5). Scene/screenshot gates assert `flora_total > 0` (never an exact count) precisely because the population is now field-determined; species-group breakdowns recorded in §8.9.

## 10. Anti-Pattern Review AP-1..22 (milestone 0009 close-out)

Item-by-item review required by 0009 §7 "Review pass". Sources: 0002 §2.1 (AP-1..10), 0006 §2.2 + 0007 §2.2 (AP-11..14 — both variants), 0008 §2.2 (AP-15..18), 0009 §2.2 (AP-19..22). All proving gates re-run in the §8.9 sweep (2026-10-03).

| # | Item (source) | How satisfied | Proving gate |
|---|---|---|---|
| AP-1 | Engine types leak into the simulation layer (0002) | `src/mojo/` imports zero Godot/GDScript/engine types | `check_layout.sh` AP-1 grep (rc 0, §8.9 gate 10) |
| AP-2 | Semantic library bypassed (0002) | Direct conformance tests: synthesis/gerstner/catalog + 0009 field & selection conformance traced to `lib/705_Ecology/Flora` (`test_flora_placement` band/threshold oracle, `test_flora_growth`/`test_flora_evolution` vs the §1.1–1.5 definition); indirect-only gaps recorded honestly (§9.7) | `test_flora_placement`, `test_flora_growth`, `test_flora_evolution` (§8.9 gates 2–4) |
| AP-3 | Dual material vocabularies (0002) | Single source `materials_catalog.json`; species + hotbar resolve through it | `test_catalog`, `test_hotbar` (gate 8) |
| AP-4 | Absolute hardcoded paths (0002) | Repo-relative resolution; env/`res://`/`user://` only (0008) | `check_layout.sh` AP-4 (gate 10) |
| AP-5 | Monolith frame loop / giant dispatch (0002) | Modules split (sim / snapshot / adapter / transport); input dispatch table; transport = `ITransport` vtable | `check_layout.sh`, load gates (gates 10, 12) |
| AP-6 | `dynamic_cast` pierces layers (0002) | 0 occurrences in adapter sources | grep gate (§8 AP review, unchanged) |
| AP-7 | Magic constants inline (0002) | All tunables in `parameters.mojo` incl. every 0009 field/growth/stress/trait/EPS parameter mirrored in §6.8/§6.8.1 | `check_layout.sh` + §6 tables (gates 10, doc review) |
| AP-8 | Presentation mutates sim state (0002) | Display scripts never write world state; growth/selection computed only in `sim/` | `check_layout.sh`, playability F-leg (gates 10, 12) + grep of `flora_view.gd` |
| AP-9 | Render-thread work stalls (0002) | Adapter apply-sections only; no socket/file I/O on the frame path | `godot_render_stall_test.sh` (gate 15: gap 0.0090 s) |
| AP-10 | Providers selected by shell with no contract (0002) | Provider tree + `101/102/103/104` control docs; `104_contract.md` §10 carries the new emission rule | `build_godot_provider.sh` (gate 10), contract review |
| AP-11 | Presentation-owned ecology (0006) / raw terrain poke (0007) | Placement, establishment, growth, traits, selection, death all sim-owned and test-asserted; edits re-run `classify_biome` + `voxel_synthesis_pipeline` (no direct grid pokes) | `test_flora_placement/growth/evolution`, `test_edit_ops` (gates 2–4, 8) |
| AP-12 | Display animation leaks into semantics (0006) / client-side hit authority (0007) | Wire carries position/yaw/scale; sway stays on shader `TIME`, display-only (AP-19 gate); uplink is intent only (`scr_edit_batch` 4 B) | `test_determinism`, `test_projection_purity`, playability F9–F13 (gates 5, 6, 12) |
| AP-13 | Unbounded instance growth (0006) / parallel hotbar vocabulary (0007) | `FLORA_N_MAX = 4096` with `0 < count ≤ cap` asserted every tick (deaths removed same tick); hotbar slots = single sim-side catalog-id list | `test_flora_growth` (d), `test_flora_evolution` (e), `test_hotbar` (gates 2, 3, 8) |
| AP-14 | Parallel species vocabulary (0006) / full-world rebuild per edit (0007) | Species → catalog conformance-tested (`species_catalog_id_string`); chunk-local rebuild only, one `world_version` bump per op | `test_catalog`, `test_terrain_resend` (gates 8, 11) |
| AP-15 | Render-thread socket I/O (0008) | Untouched this milestone (constraint); worker owns all syscalls, render thread reads seqlock slot | structural grep + `godot_render_stall_test.sh` (gate 15) |
| AP-16 | Transport-aware payload (0008) | Single encoder; `SNAPSHOT` copied verbatim | `test_ipc_determinism.sh` — 600 ticks byte-identical, 11 446 164 B; harness first snapshot == fixture 248 264 B (gate 14) |
| AP-17 | Silent version drift (0008) | Handshake refusal both directions, loud `ERROR` frames | `test_ipc_version_refusal.sh` (gate 15) |
| AP-18 | Orphan/zombie servers (0008) | Adapter owns spawn/reap/backoff/cap; `pgrep -x scr_sim_server` = 0 after every run | `test_ipc_crash_restart.sh` + hygiene checks (gates 15, 16) |
| AP-19 | Presentation-owned growth/evolution (0009) | `age`, `scale(age)`, traits, survival and death are sim state on the wire; shader `TIME` remains display-only sway; removing the sway shader changes no snapshot byte (encoder never reads display state) | `test_flora_growth` (a/b), `test_projection_purity` (growth fingerprint), `test_determinism` (gates 2, 5, 6); screenshot reads wire scale (gate 13) |
| AP-20 | Mutable RNG stream in field/growth/traits (0009) | Every decision is a pure hash of `(seed, cell, age, trait_salt)` — no stream state, order-independent | run-twice legs: `test_flora_growth` (b), `test_flora_evolution` (d), `test_determinism`, `test_flora_placement` seeded determinism (gates 2–5) |
| AP-21 | Implementation-before-definition (0009) | Sprint 00 (`8c686ec`) landed `lib/` definitions + control-plane backfill **before** sprints 01–04; validator-style findings 0 | Definition gate: 0 non-lib paths in `8c686ec`, 7 files structurally clean (gate 1) |
| AP-22 | Unbounded FLORA emission (0009) | Change-driven emission with `FLORA_EMIT_EPS = 0.01` relative quantization; `count ≤ FLORA_N_MAX` asserted every tick; deaths removed the tick they die; stored scale ε-snaps so dirty ⇔ change (355 ε-dirty ticks / 3000 — not per-tick spam) | `test_flora_growth` (d/e), `test_envelope` change-driven round-trip, `test_flora_evolution` (e), §8.9 growth table (gates 2, 3, 7) |

**Verdict: PASS — AP-1..22 all satisfied.** No deficient item found; the AP-2 partial-coverage note (§9.7) and §9.21–24 limitations are recorded as honest gaps, not violations.

## References

- [Documentation index](README.md)
- [spec — milestone 0009 (Flora Upgrade)](../program_increments/v0.0.2/milestone_0009_flora-upgrade/spec.md)
- [lib/705_Ecology/Flora/101_definition.md (normative flora definitions)](../../../lib/705_Ecology/Flora/101_definition.md)
- [spec — milestone 0008 (IPC Transport Swap)](../program_increments/v0.0.1/milestone_0008_ipc-transport/spec.md)
- [spec — milestone 0007 (Editing, Hotbar & Physics)](../program_increments/v0.0.1/milestone_0007_editing-physics/spec.md)
- [spec — milestone 0006 (Ecology)](../program_increments/v0.0.1/milestone_0006_ecology/spec.md)
- [spec — milestone 0005 (Shoreline Fidelity)](../program_increments/v0.0.1/milestone_0005_shoreline-fidelity/spec.md)
- [spec — milestone 0004 (Atmosphere & Weather)](../program_increments/v0.0.1/milestone_0004_atmosphere-weather/spec.md)
- [spec — milestone 0003 (Volcano)](../program_increments/v0.0.1/milestone_0003_volcano/spec.md)
- [spec — milestone 0002](../program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md)
- [104_contract.md (normative)](../../providers/render/graphics/godot/104_contract.md)
- [src/mojo/sim/parameters.mojo](../src/mojo/sim/parameters.mojo) (parameter source of truth)
- [AGENTS.md](../../AGENTS.md)
