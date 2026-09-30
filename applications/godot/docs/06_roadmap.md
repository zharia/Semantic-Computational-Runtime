# 06 — Roadmap

**Purpose:** Record milestone status and forward milestones beyond v0.0.1 for the Godot application.
**Status:** Active (updated by milestone 0006 Sprint 04)
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

### Milestone 0004 status detail (verified)

Sprints 01–04 delivered: `AtmosphereSubject` expansion + `WeatherSubject` (seeded profile state machine, Hermite blend, wetness), schema **3** (SKY 32 → 64 B = 16×f32, fixture 228668 B), adapter SKY decode/range validation + derived dome gradient/fog/wetness, atmosphere/weather mojo suites, `island.tscn` `scr_clouds`/`scr_rain` nodes + `clouds.gdshader`, extended gates (sun sub-capture, rain streak window, night re-derivation).

Final gates: 10/10 mojo spec-test files (61 tests), abi_smoke (schema 3), schema-mismatch PASS, layout PASS (incl. AP-15 grep), build OK, load PASS, playability PASS, screenshot day PASS (`sun delta=24.19 / bright=434`, `rain ratio=1.665`, spawn mean 131.67), screenshot night PASS (`light_energy=0.663`, `dome warm10=649 max R−B=95 lum=30.9 vs flank 0.2`, spawn mean 7.10).

Resolved during verification: static skybox → dome derived from SKY each frame (AP-16, single solar authority), engine fog erasing the cloud deck (`fog_disabled` + shader-local fades, recorded), wetness tint erased by the per-frame catalog rewrite (applied inside `update_materials()`), rain invisible over white overcast (colour/alpha retune), sun-disc geometry conflict (recorded deviation — sun-aimed sub-capture, [04 §8.4](04_simulation_engine.md)).

Honest gaps: sun disc not in the *spawn* view (recorded deviation), cloud pattern/scale display-only, no volumetric scattering — [04 §9](04_simulation_engine.md).

Anti-pattern review (spec §7 final item): **PASS** — AP-15..AP-18 checked item-by-item, evidence in [04 §8.4](04_simulation_engine.md).

### Milestone 0006 status detail (verified)

Sprints 01–04 delivered: sim-side `flora.mojo` (seeded band placement, species from `catalog.mojo`, cap 4096) + `flock.mojo` (64-slot boids, deterministic slot-order integration, waypoint orbit, bound-respawn), schema **5** (`10 FLORA` = `4 + 24·count` emission-gated, `11 FAUNA` = `4 + 20·count` every snapshot; fixture 249432 B, 11 sections), adapter decode/validate/dispatch (`apply_flora`/`apply_fauna`/`set_wetness_gain` latch, catalog mirror `scr::kSpeciesDisplay`), `island.tscn` hosts + `flora_view.gd`/`fauna_view.gd` + `flora_wing.gdshader` (display-only sway/flap), extended gates (flora/fauna region checks + sub-captures `island_flora.png`/`island_fauna.png`).

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

## Planned Milestones (specs drafted, Status: Planned)

Future increments build on the stabilized snapshot contract. Each has a normative spec (Rule 10: specify before implementing); sequencing subject to user confirmation.

| Milestone | Spec | Intent | Triggering contracts |
|-----------|------|--------|----------------------|
| 0007 | [Editing, hotbar, physics](../program_increments/v0.0.1/milestone_0007_editing-physics/spec.md) | Voxel dig/place, catalog hotbar, minimal rigid bodies | `501_Physics`, `A01_Render/Material` |
| 0008 | [IPC transport](../program_increments/v0.0.1/milestone_0008_ipc-transport/spec.md) | Out-of-process sim over socket, byte-identical semantics | `804_Application`, `503_Simulation/Snapshot` |

Sequencing note: 0003 completed 2026-09-28; 0004 completed 2026-09-28; 0005 completed 2026-09-29; 0006 completed 2026-09-30; 0007–0008 remain Planned.

Still unspecified (no spec yet — Rule 10): second scene (ocean/atmosphere lab parity) — `503_Simulation` scenarios; CI beyond local gates. Exact sequencing of 0007–0008: TBD — user decision. Sibling schema-bump rebase rules are stated inside each spec §3.

## Explicit Non-Goals Carried Forward

- From v0.0.1 [spec §6](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md): MLIR dialect/lowering work, CI pipeline expansion, performance optimization, provider qualification/conformance suites. Re-entry requires a normative spec.
- From [milestone 0002 spec §9](../program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md): IPC transport, custom sky shader, shoreline foam fidelity, swim/`MAP_BOUND` parameter consolidation — deferred with honest notes in [04 §9](04_simulation_engine.md).

## References

- [Documentation index](README.md)
- [spec — milestone 0001](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)
- [spec — milestone 0002](../program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md)
- [program_increments/](../program_increments/)
