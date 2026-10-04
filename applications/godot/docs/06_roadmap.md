# 06 — Roadmap

**Purpose:** Record milestone status and forward milestones beyond v0.0.1 for the Godot application.
**Status:** Active (updated by milestone 0010 Sprint 04)
**Owner milestone:** [v0.0.1 / milestone 0001 — Project Initiation](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)

---

> Honesty invariant: successor milestone contents are **not specified yet**. Sequencing deferred to future program-increment specs (AGENTS.md Rule 10: specify before implementing when semantic behavior is new). No fabricated scope below.

## Completed

| Increment | Milestone | State |
|-----------|-----------|-------|
| v0.0.1 | 0001 — Project Initiation (workspace baseline) | Complete — see [spec](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md) |
| v0.0.1 | 0002 — Scene Initiation (volcanic island) | Complete — all 14 exit criteria verified; see [spec](../program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md) + [04 §8](04_simulation_engine.md) |
| v0.0.1 | 0003 — Volcano (lava lake, plume, glow) | Complete — all §7 exit criteria verified (schema 2, 8/8 mojo suites 47/47, 9 gates incl. night-glow procedure); see [spec](../program_increments/v0.0.1/milestone_0003_volcano/spec.md) + [04 §8.3](04_simulation_engine.md) |
| v0.0.1 | 0004 — Atmosphere & Weather (diurnal sky, clouds, rain, wind) | Complete — 9 gates PASS (schema 3, 10 mojo suites, sun sub-capture + rain window, night re-derivation); see [spec](../program_increments/v0.0.1/milestone_0004_atmosphere-weather/spec.md) + [04 §8.4](04_simulation_engine.md) |
| v0.0.1 | 0005 — Shoreline Fidelity (shore foam, crater material blending, quench evaluator) | Complete — all §7 exit criteria verified (schema 4, 13 mojo suites, foam-only-at-shoreline gate, crater-rim capture); see [spec](../program_increments/v0.0.1/milestone_0005_shoreline-fidelity/spec.md) + [04 §8.5](04_simulation_engine.md) |
| v0.0.1 | 0006 — Ecology (flora scatter, seabird flock) | Complete — all §7 exit criteria verified (schema 5, 15 mojo suites, flora/fauna region checks, foam gate kept green); see [spec](../program_increments/v0.0.1/milestone_0006_ecology/spec.md) + [04 §8.6](04_simulation_engine.md) |
| v0.0.1 | 0007 — Editing, Hotbar & Physics (dig/place, hotbar, rigid props) | Complete — all §7 exit criteria verified (schema 6 / ABI 2, 19 mojo suites, terrain-resend + ABI/schema negative tests, dig/place playability leg, editing-HUD screenshot assertions); see [spec](../program_increments/v0.0.1/milestone_0007_editing-physics/spec.md) + [04 §8.7](04_simulation_engine.md) |
| v0.0.1 | 0008 — IPC Transport Swap (out-of-process sim over UDS) | Complete — all §7 exit criteria verified (schema 6 / ABI 2 / proto 1 unchanged, 20 mojo suites, 600-tick byte-identity, dual-direction refusal, crash/restart + cap, AP-15 stall, docs/104 §2 rewrite); see [spec](../program_increments/v0.0.1/milestone_0008_ipc-transport/spec.md) + [04 §8.8](04_simulation_engine.md) |
| v0.0.2 | 0009 — Flora Upgrade (establishment field, growth, selection) | Complete — all §7 exit criteria verified (schema 6 / ABI 2 unchanged, layout-neutral; fixture content-only 248 264 B sha256 `f76b6ccd…7d9cfe`, FLORA 154 → 95; 22 mojo suites `MOJO_FAILS=0`; rendered growth evidence + AP-1..22 PASS); see [spec](../program_increments/v0.0.2/milestone_0009_flora-upgrade/spec.md) + [04 §8.9](04_simulation_engine.md) |
| v0.0.2 | 0010 — Flora Phenome (L-system morphology, genotype→phenotype, LOD) | Complete — all §7 exit criteria verified (schema 7 / ABI 2, FLORA record 24 → 32 B; fixture 249 024 B sha256 `ca9e7080…225b43`, FLORA 3044 = 4+32·95; 23 mojo suites `MOJO_FAILS=0`; conformance 84/84 discrete rows, cache 112/evict 0, expand ≈69 ms; AP-1..26 PASS); see [spec](../program_increments/v0.0.2/milestone_0010_flora-phenome/spec.md) + [04 §8.10/§8.11](04_simulation_engine.md) |

### Milestone 0007 status detail (verified)

Sprints 01–04 delivered: sim-side `edit.mojo` (FIFO ≤ 16, dig/place guards, single-column re-synthesis via `classify_biome` + `voxel_synthesis_pipeline`, chunk-local rebuild, `world_version` +1), `raycast.mojo` (sim-owned ray-march + bisection refine), `hotbar.mojo` (9-slot catalog table + selection), `props.mojo` (`PhysicsSubject`, N ≤ 16, gravity + ground contact, slot-order), schema **6** (`12 HOTBAR` 44 B, `13 TARGET` 32 B, `14 RIGID_BODIES` `4+36·count` ≤ 16; sections 1–11 byte-identical; fixture 249680 B, 14 sections), ABI **2** (`scr_edit_submit` + 4-byte `scr_edit_batch`), adapter decode/validate/dispatch (`apply_hotbar`/`apply_target`/`apply_props`, catalog mirror `scr::kVocabDisplay`, edit-intent uplink), `island.tscn` hosts + `hotbar_hud.gd`/`props_view.gd` + full edit mapping in `player_input.gd`, extended gates (terrain-resend test, ABI/schema dual-negative, playability dig/place leg F1–F13, screenshot editing-HUD assertions).

Final gates: 19/19 mojo spec-test files PASS (incl. `test_edit_ops`, `test_raycast`, `test_hotbar`, `test_props`), abi_smoke (schema 6, ABI 2, `scr_edit_submit`) PASS, `test_terrain_resend` PASS (exactly-one TERRAIN resend per edit), schema+ABI mismatch PASS (8 checks), layout PASS, build OK, load PASS (0 `ERROR:`, 0 WARNING), playability PASS (incl. dig/place mesh-content assertions), screenshot day PASS (hotbar 9/9/1, target `Sand #3`, props 4) + aerial/foam PASS (`in-band=1246 out-of-band=0`).

Resolved during verification: foam gate schema whitelist for schema 6 (byte-identity justified), foam gate counting the new bottom hotbar/target HUD as offshore foam (bottom `--bottom-hud-rows` mask, same class as the existing top HUD mask), `scr_edit_submit` outside the loader set (adapter `dlsym` binding documented).

Honest gaps: interactive manual dig/place session not executed (automated companion recorded — [04 §9.15](04_simulation_engine.md)); Material Inspector / advanced prop physics / edit undo `TBD` — [04 §9](04_simulation_engine.md).

Anti-pattern review (spec §7 final item): **PASS** — AP-1..10 re-run via layout/load/playability gates, AP-11..14 checked item-by-item, evidence in [04 §8.7](04_simulation_engine.md).

### Milestone 0004 status detail (verified)

Sprints 01–04 delivered: `AtmosphereSubject` expansion + `WeatherSubject` (seeded profile state machine, Hermite blend, wetness), schema **3** (SKY 32 → 64 B = 16×f32, fixture 228668 B), adapter SKY decode/range validation + derived dome gradient/fog/wetness, atmosphere/weather mojo suites, `island.tscn` `scr_clouds`/`scr_rain` nodes + `clouds.gdshader`, extended gates (sun sub-capture, rain streak window, night re-derivation).

Final gates: 10/10 mojo spec-test files (61 tests), abi_smoke (schema 3), schema-mismatch PASS, layout PASS (incl. AP-15 grep), build OK, load PASS, playability PASS, screenshot day PASS (`sun delta=24.19 / bright=434`, `rain ratio=1.665`, spawn mean 131.67), screenshot night PASS (`light_energy=0.663`, `dome warm10=649 max R−B=95 lum=30.9 vs flank 0.2`, spawn mean 7.10).

Resolved during verification: static skybox → dome derived from SKY each frame (AP-16, single solar authority), engine fog erasing the cloud deck (`fog_disabled` + shader-local fades, recorded), wetness tint erased by the per-frame catalog rewrite (applied inside `update_materials()`), rain invisible over white overcast (colour/alpha retune), sun-disc geometry conflict (recorded deviation — sun-aimed sub-capture, [04 §8.4](04_simulation_engine.md)).

Honest gaps: sun disc not in the *spawn* view (recorded deviation), cloud pattern/scale display-only, no volumetric scattering — [04 §9](04_simulation_engine.md).

Anti-pattern review (spec §7 final item): **PASS** — AP-15..AP-18 checked item-by-item, evidence in [04 §8.4](04_simulation_engine.md).

### Milestone 0006 status detail (verified)

Sprints 01–04 delivered: sim-side `flora.mojo` (seeded band placement, species from `catalog.mojo`, cap 4096) + `flock.mojo` (64-slot boids, deterministic slot-order integration, waypoint orbit, bound-respawn), schema **5** (`10 FLORA` = `4 + 24·count` with the 0006 `world_version`-gated presence rule (rewritten change-driven by 0009 §3.2, layout unchanged), `11 FAUNA` = `4 + 20·count` every snapshot; fixture 249432 B, 11 sections), adapter decode/validate/dispatch (`apply_flora`/`apply_fauna`/`set_wetness_gain` latch, catalog mirror `scr::kSpeciesDisplay`), `island.tscn` hosts + `flora_view.gd`/`fauna_view.gd` + `flora_wing.gdshader` (display-only sway/flap), extended gates (flora/fauna region checks + sub-captures `island_flora.png`/`island_fauna.png`).

Final gates: 15/15 mojo spec-test files PASS (incl. `test_flora_placement`, `test_flock`), abi_smoke (schema 5) PASS, schema-mismatch PASS, layout PASS, build OK, load PASS (0 `ERROR:` lines), screenshot day PASS (flora/fauna assertions + green/near-white px), aerial + shoreline-foam PASS (`in-band=1269 out-of-band=0`, fauna hidden from foam frame — birds read as offshore foam), night-glow PASS, playability PASS.

Resolved during verification: waypoint period collapse (tangential speed 15.7 u/s > cruise 9 → flock spiraled inward; `FLOCK_WAYPOINT_PERIOD_TICKS` 2400 → 14400 ⇒ ≈2.8 u/s), foam gate false-positive (flock orbit r=98–112 u rendered as foam-colored pixels → hide `scr_fauna` in aerial diagnostic), scene header `load_steps` drift after node append.

Honest gaps: flora regrowth after 0007 voxel edits `TBD` (voxel-flora still disabled); wind sway tie-in `TBD`; species semantics stay sim-side (bird species_id 0 = seabird, only emitted id) — [04 §9](04_simulation_engine.md).

Anti-pattern review (spec §7 final item): **PASS** — AP-11..AP-14 checked item-by-item, evidence in [04 §8.6](04_simulation_engine.md).

### Milestone 0005 status detail (verified)

Sprints 01–04 delivered: sim-side `shore.mojo` foam field (library-formula exact), feather+dither material blending (`blend.mojo`, `FEATHER_WIDTH_CELLS=4`), quench evaluator (`quench.mojo`, zero seed-1 triggers asserted), schema **4** (`9 SHORE_FOAM` = 12 B header + `grid_n²·f32` = 16396 B at `grid_n=64`, TERRAIN per-vertex `(dominant, blend, weight, pad)` tuples, fixture regenerated), adapter decode/validate/upload (foam texture refreshed every snapshot, per-vertex blended vertex albedo), `ocean.gdshader` shore band sampled from world xz (AP-19), extended gates (`check_shoreline_foam.py`).

Final gates: 13/13 mojo spec-test files PASS (`test_shoreline_foam`, `test_material_blending` incl. `test_seed1_crater_rim_has_feather_band`, `test_quench`, `test_synthesis_conformance`, `test_envelope`, `test_golden_fixture`, `test_determinism`, `test_projection_purity`, `test_catalog`, `test_gerstner`, `test_atmosphere`, `test_weather`, `test_volcano`), abi_smoke (schema 4) PASS, schema-mismatch PASS, layout PASS, build OK, load PASS (0 `ERROR:` lines), screenshot + aerial + shoreline-foam gates PASS (`in-band=1082 out-of-band=0`), playability PASS.

Resolved during verification: vertex-colour albedo color-space (catalog is `base_color_srgb` — without `FLAG_SRGB_VERTEX_COLOR` the render washed out; rendered probe showed albedo-path 0.4 → 0.4 vs vertex-path 0.4 → 0.667, flag restores pixel-exact parity); godot-cpp binding names `vertex_color_use_as_albedo` → `FLAG_ALBEDO_FROM_VERTEX_COLOR`; foam texture row order (v=0 → image row 0, rendered probe, no flip); white-ring artifact replaced by the texture-driven shore band (crest path untouched, AP-22).

Honest gaps: roughness/emission/opacity stay the grouped surface's dominant material (spec §1.1 recorded limitation); foam texture resolution = sim grid (64², linear-filtered); quench steam/energy manifestation and live lava-to-sea quench remain `TBD` (spec §9) — [04 §9](04_simulation_engine.md).

Anti-pattern review (spec §7 final item): **PASS** — AP-19..AP-22 checked item-by-item, evidence in [04 §8.5](04_simulation_engine.md).

### Milestone 0002 status detail (verified)

Sprints 01–04 delivered: Mojo semantic core (7/7 spec-test files, 36 test cases), snapshot/contract/C ABI (ABI smoke 26/26, schema-mismatch negative PASS), GDExtension provider + adapter (build PASS, layout AP-1/AP-4 PASS), `island.tscn` + scripts/shaders + automated test scripts.

Final gate results (post-resolution): headless load PASS (0 errors), screenshot PASS (mean 126.65 / stddev 51.66; island + ocean + sky legible), playability PASS (jump gain 1.73 u, horizontal 16.63 u, yaw 0.75 rad), determinism/projection-purity/catalog/synthesis/Gerstner/fixture tests PASS.

Resolved during verification: MATERIALS framing inconsistency (contract header amended to `4 + 36·N` per field table/fixture — adapter aligned); TERRAIN chunk payload stride bug in adapter (`24V` → `28V`); spawn yaw now faces island center (fixture regenerated); atmospheric fog density tuned (`0.012 → 0.0045`); ocean foam/fresnel blowout fixed; lava emission enabled via `set_feature(FEATURE_EMISSION, ·)`.

Honest gaps (documented, deferred): crater rim material banding ("teeth") needs sim-side blending; sun disk not in frame during daytime from spawn (sky-arc successor); AP-2 indirect-coverage gaps in [04 §9](04_simulation_engine.md).

Anti-pattern review (spec §7 final item): **PASS** — §2.1 table checked item-by-item, evidence in [04 §8](04_simulation_engine.md); AP-2 indirect-coverage gaps recorded honestly in [04 §9](04_simulation_engine.md).

**Exit-criteria evidence table:** see [04 §8](04_simulation_engine.md) (per-gate PASS/FAIL).

### Milestone 0003 status detail (verified)

Sprints 01–04 delivered: `VolcanoSubject` + effusion/plume/glow semantics, schema 2 (`7 VOLCANO` + `8 PLUME`, fixture 228636 B), adapter decode/apply, `island.tscn` lava/plume/glow nodes + `lava.gdshader`, extended gates (plume/lava/night-glow region checks).

Final gates: 8/8 mojo spec-test files (47 tests — including three latent test-vs-spec bugs found by converting no-op `assert` → raise-based `_check`), abi_smoke 49, schema-mismatch PASS, layout PASS, load PASS, screenshot day PASS, screenshot night PASS (dome warm10=301, max R−B=30, luminance 140 vs flank 37), playability PASS.

Resolved during verification: plume collapse (turbulence velocity influence — influence locked 0, §8.3), renderer Forward+/Vulkan locked (GPUParticles3D requirement), night-glow display lift (60 u measurement chain), plume region check false-pass (per-channel margin-median), rim-occluded crater camera, tick-based settle, `runtime.mojo` env NUL fix.

Honest gaps: turbulence noise exposed with influence 0 (display turbulence `TBD`), glow lift is a documented display hack, sun-in-frame deviation (sub-capture record) — all in [04 §9](04_simulation_engine.md).

### Milestone 0008 status detail (verified, 2026-10-01)

Sprints 01–04 delivered: `src/mojo/server/` (`main.mojo` + `session.mojo` — same sim core and encoder behind a new entry, wall/manual pace, `BYE` ⇒ exit 0, socket unlink), `src/mojo/transport/framing.mojo` (SCRT frames, `SCR_SIM_IPC_PROTO_VER = 1`), adapter `ITransport` split (`scr_transport.h`, `transport_inproc.cpp` default, `transport_socket.cpp` worker thread + seqlock latest slot + SPSC uplink ring + spawn/supervise/backoff/cap + **first-snapshot latch**), env selection (`$SCR_SIM_TRANSPORT`, `$SCR_SIM_SOCKET`, `$SCR_SIM_SERVER_BIN`, `SCR_REPO_ROOT` at spawn — AP-4 clean), new gates (`ipc_harness.py`, `test_ipc_determinism.sh`, `test_ipc_version_refusal.sh`, `test_ipc_crash_restart.sh`, `fake_server.py`, `godot_ipc_smoke.sh`, `godot_render_stall_test.*`, `godot_socket_supervision_test.gd`), docs (`104_contract.md` §2 rewrite, `docs/04` §4.6 + §8.8 + §9, `docs/05` §6, this row, `102`/`103` capability).

Final gates: determinism 600 ticks byte-identical (socket == in-process, 10950216 B), refusal both directions PASS, crash/restart + crash-loop cap + no orphans PASS, AP-15 stall PASS (structural grep + 2 s `SIGSTOP` ⇒ gaps 0.0223/0.0097 s < 0.05), default transport asserted `InprocTransport`, socket smoke/handshake PASS, `build_sim_server` + harness self-test PASS, layout-neutrality review clean (fixture 249680 B, no diff in `src/mojo/`, `lib/`, spec), 20/20 mojo suites, load/screenshot/playability PASS in **both** transports.

Resolved during verification: socket screenshot leg showed `terrain_chunks=0, flora_groups=0` — the latest-wins handoff dropped the session's first (and only session-start) snapshot; fixed with the per-session **first-snapshot latch** (`104_contract.md` §2.3), all gates re-run green.

### Milestone 0009 status detail (verified, 2026-10-03)

Sprints 01–04 delivered: Sprint 00 definitions first (`lib/705_Ecology/Flora/` 101+102+103 + control-plane backfill for `704_Evolution`/`705_Ecology`, commit `8c686ec` = `lib/` only), `sim/flora.mojo` (establishment field + `FLORA_SUITABILITY_THRESHOLD`, per-instance `age` + smoothstep species growth curve with `FLORA_EMIT_EPS` quantization, trait variation via pure cell hashes, `flora_selection_passes` establishment/survival predicate, absorbing death, `flora_re_evaluate` edit re-scan), `sim/world.mojo` tick-phase ordering (re-scan ⇒ survival ⇒ aging), `sim/runtime.mojo` `_flora_dirty` change-driven FLORA emission (replaces the 0006 `world_version` gate; `104_contract.md` §10 rewritten), `parameters.mojo` §6.8.1 tunables (growth curves, threshold, EPS, trait salts, `W_ASH 0.70`/`W_DROUGHT 0.30`, `FLORA_ASH_FALLOFF_RADIUS 72`, `FLORA_DROUGHT_WETNESS_REF 1.0`), fixture content-only regen (248 264 B, FLORA 95), `flora_view.gd` wire-scale consumption, `docs/04` §4.1.1 + §6.8.1 + §8.9 + §9.21–24 + §10.

Final gates: 22/22 mojo spec-test files PASS (`MOJO_FAILS=0`, incl. `test_flora_growth` 7/7 + `test_flora_evolution` 5/5), abi_smoke (schema 6, ABI 2) PASS, schema-mismatch PASS (8 checks), layout PASS (AP-1/4/15), build OK, terrain_resend PASS, load PASS (0 `ERROR:`, `InprocTransport`), screenshot day PASS (flora `groups=6 total=95`, `green_px=1625`, hotbar 9/9/1, foam `in-band=1247 out=0`, aerial PASS), playability PASS (`fails=0`), socket smoke PASS (manual pace), ipc determinism PASS (600 ticks, 11 446 164 B byte-identical), refusal/crash/stall gates PASS, definition gate 0 findings (0 non-lib paths in `8c686ec`).

Growth evidence (headless probe, same sim code): mean scale `1.074440` (init) → `1.120794` (tick 1944, ≈ capture tick) → `1.121073` (saturated ≥ 2400), +4.34 %; 355 ε-dirty ticks / 3000 (change-driven emission, AP-22). PNGs read: `island.png` (grown flora on the ridge, tick 1943) + `island_flora.png` (fern/shrub crown sub-capture) — [04 §8.9](04_simulation_engine.md).

Resolved during verification: stale `emission-gated`/`world_version` FLORA wording in `docs/04`/`docs/06`/`encode.mojo` comments (comment-only, TERRAIN rule untouched); fixture content change 154 → 95 explained (field + trait selection gate at init — [04 §9.24](04_simulation_engine.md)); screenshot flora assertions verified already `> 0` style (no exact-count hardcode).

Honest gaps: no reproduction / cross-generational `INV-006/007` (trivial per instance), stress = crater-distance ∧ wetness with plume mask rejected (no sim-side plume mask — Rule 9), voxel-flora deviation still open — [04 §9.21–23](04_simulation_engine.md).

Anti-pattern review (spec §7 final item): **PASS** — AP-1..22 item-by-item, evidence in [04 §10](04_simulation_engine.md).

### Milestone 0010 status detail (verified, 2026-10-04)

Sprints 01–04 delivered: Sprint 00 definitions first (`lib/401_Morphology/Procedural/101` stub → grammar semantics §1.1–1.8, new `lib/704_Evolution/Phenotype/` 101+102+103, `Flora` §1.6 phenome conformance, `704_Evolution/102` subdomain touch — validator findings 0, 6-path diff), `sim/phenome.mojo` (pure `stage_for_age` / `variant_seed` hash `PHENOME_VARIANT_SALT 0xA00000001B3` / trait→grammar modulation mirrors), `phenome/expand.mojo` (reference expander, tests only), `data/phenome_grammars.json` (7 single-source grammars: axiom + parametric productions + `stage_depths` + tropism + modulation map), `sim/world.mojo`/`runtime.mojo` (tick-phase stage advance; emission dirty on seed/stage change), schema **7** (`10 FLORA` record 24 → **32 B** = pose/species + `u32 variant_seed` @24 + `u8 stage` @28 + pad, ABI stays **2**; sections 1–9 and 11–14 byte-identical), fixture regen (249 024 B), adapter `SCR_SIM_SCHEMA_VER 7` + `stage ≤ 15`/`pad == 0`/`4+32·count` validation, `104_contract.md` §4.3 §10 + §17 Repetition (line 577) citation, `godot/scripts/phenome_expand.gd` (pure turtle expander → ArrayMesh + wind-weight `COLOR`), `flora_view.gd` (bucketed cache `K=16`, `CACHE_MAX=112`, LOD 30/60 m ± 2 m hysteresis), `flora_wing.gdshader` (sway × `COLOR.r`), gates (`godot_phenome_test` incl. conformance, screenshot structural asserts), `docs/04` §8.10/§8.11 + §9.25–29 + §10 AP-1..26.

Final gates: 23/23 mojo spec-test files PASS (`MOJO_FAILS=0`, incl. `test_phenome_grammar` 8/8), conformance **84/84** golden rows (0 mismatches, discrete axis), abi_smoke (schema 7, ABI 2) PASS, schema-mismatch PASS (11 checks: 6 and 8 refused, ABI 3 refused), layout PASS, build OK, terrain_resend PASS, load PASS (0 `ERROR:`, 0 WARNING, `InprocTransport`), phenome PASS (40 checks: cache 112 / evict 0, LOD hysteresis `far → near → far`, wind `[0.10,1.00]`, mesh ≥ 64 verts), screenshot PASS ×2 (structural `meshes=63 verts64=true`, centre-box `green_px=98`, foam `in-band=1273 out=0`), playability PASS (`fails=0`), socket smoke PASS (manual pace), ipc determinism PASS (600 ticks, 12 289 388 B byte-identical), refusal/crash/stall gates PASS (stall gaps 0.0225/0.0178 s), harness self-test PASS (first snapshot == fixture 249 024 B), definition gate 0 findings.

Rendered evidence: first-load expansion ≈69 ms, worst LOD pass ≈37 ms, stage distribution (tick 1, wire bytes) stages 0–14 present `{0:5,1:7,2:3,3:5,4:7,5:10,6:8,7:4,8:7,9:9,10:2,11:7,12:6,13:9,14:6}`, `variant_seed` distinct 95/95; PNGs read — `island.png` (day frame, spawn-framing variance §9.14), `island_flora.png` (structured plant, faceted layered crown — not a blob), `aerial.png` (flora distribution intact) — [04 §8.10](04_simulation_engine.md).

Resolved during verification: `flora_view.gd` `RECORD_BYTES` 24 → 32 carry-over fix (Sprint 03); real test paths vs spec prose (`tests/abi_smoke.py`, `tests/test_schema_mismatch.sh` — §9.25); abi-smoke snapshot-2 FLORA presence explained (§9.26); spec record-size drafting correction 28 → 32 B (§9.28).

Honest gaps: traits not on the wire (renderer uses median traits — in-test proof only), species 3 unexercised at seed 1, discrete-only conformance, no sim-side structure state, no reproduction, no MLIR/rewrite contract, voxel flora open — [04 §8.11](04_simulation_engine.md) + [04 §9.29](04_simulation_engine.md).

Anti-pattern review (spec §7 final item): **PASS** — AP-1..26 item-by-item, evidence in [04 §10](04_simulation_engine.md).

## Planned Milestones (specs drafted, Status: Planned)

Future increments build on the stabilized snapshot contract. Each has a normative spec (Rule 10: specify before implementing); sequencing subject to user confirmation.

| Milestone | Spec | Intent | Triggering contracts |
|-----------|------|--------|----------------------|
| — | (none drafted) | 0010 was the last spec so far; 0011+ = `TBD — future milestone` (Rule 10) | — |

Sequencing note: 0003 completed 2026-09-28; 0004 completed 2026-09-28; 0005 completed 2026-09-29; 0006 completed 2026-09-30; 0007 completed 2026-09-30; 0008 completed 2026-10-01; 0009 completed 2026-10-03; 0010 completed 2026-10-04 (v0.0.2).

Still unspecified (no spec yet — Rule 10): second scene (ocean/atmosphere lab parity) — `503_Simulation` scenarios; CI beyond local gates. Successor sequencing after 0010: `TBD — user decision` (candidate successors listed in [0010 §10](../program_increments/v0.0.2/milestone_0010_flora-phenome/spec.md)). Sibling schema-bump rebase rules are stated inside each spec §3.

## Explicit Non-Goals Carried Forward

- From v0.0.1 [spec §6](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md): MLIR dialect/lowering work, CI pipeline expansion, performance optimization, provider qualification/conformance suites. Re-entry requires a normative spec.
- From [milestone 0002 spec §9](../program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md): ~~IPC transport~~ **delivered by 0008**; custom sky shader, shoreline foam fidelity (partially delivered by 0005), swim/`MAP_BOUND` parameter consolidation remain deferred with honest notes in [04 §9](04_simulation_engine.md).

## References

- [Documentation index](README.md)
- [spec — milestone 0001](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)
- [spec — milestone 0002](../program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md)
- [program_increments/](../program_increments/)
