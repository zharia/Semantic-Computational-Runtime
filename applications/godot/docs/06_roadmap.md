# 06 — Roadmap

**Purpose:** Record milestone status and forward milestones beyond v0.0.1 for the Godot application.
**Status:** Active (updated by milestone 0003 Sprint 04)
**Owner milestone:** [v0.0.1 / milestone 0001 — Project Initiation](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)

---

> Honesty invariant: successor milestone contents are **not specified yet**. Sequencing deferred to future program-increment specs (AGENTS.md Rule 10: specify before implementing when semantic behavior is new). No fabricated scope below.

## Completed

| Increment | Milestone | State |
|-----------|-----------|-------|
| v0.0.1 | 0001 — Project Initiation (workspace baseline) | Complete — see [spec](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md) |
| v0.0.1 | 0002 — Scene Initiation (volcanic island) | Complete — all 14 exit criteria verified; see [spec](../program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md) + [04 §8](04_simulation_engine.md) |
| v0.0.1 | 0003 — Volcano (lava lake, plume, glow) | Complete — all §7 exit criteria verified (schema 2, 8/8 mojo suites 47/47, 9 gates incl. night-glow procedure); see [spec](../program_increments/v0.0.1/milestone_0003_volcano/spec.md) + [04 §8.3](04_simulation_engine.md) |

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

Honest gaps: turbulence noise exposed with influence 0 (display turbulence `TBD`), glow lift is a documented display hack, night skybox static — all in [04 §9](04_simulation_engine.md).

## Planned Milestones (specs drafted, Status: Planned)

Future increments build on the stabilized snapshot contract. Each has a normative spec (Rule 10: specify before implementing); sequencing subject to user confirmation.

| Milestone | Spec | Intent | Triggering contracts |
|-----------|------|--------|----------------------|
| 0004 | [Atmosphere & weather](../program_increments/v0.0.1/milestone_0004_atmosphere-weather/spec.md) | Diurnal sky, sun in frame, clouds, rain, wind | `202_Math/Atmosphere`, `A01_Render/Sky`, `503_Simulation/Environment/Weather` |
| 0005 | [Shoreline fidelity](../program_increments/v0.0.1/milestone_0005_shoreline-fidelity/spec.md) | Real shoreline foam + crater material blending (kills rim teeth) | `A01_Render/Water`, `801_Spatial/Voxel/Synthesis` |
| 0006 | [Ecology](../program_increments/v0.0.1/milestone_0006_ecology/spec.md) | Flora scatter + seabird flocking | `705_Ecology`, `601_Agent` (flocking: parent def — child absent, noted) |
| 0007 | [Editing, hotbar, physics](../program_increments/v0.0.1/milestone_0007_editing-physics/spec.md) | Voxel dig/place, catalog hotbar, minimal rigid bodies | `501_Physics`, `A01_Render/Material` |
| 0008 | [IPC transport](../program_increments/v0.0.1/milestone_0008_ipc-transport/spec.md) | Out-of-process sim over socket, byte-identical semantics | `804_Application`, `503_Simulation/Snapshot` |

Sequencing note: 0003 completed 2026-09-28; 0004–0008 remain Planned.

Still unspecified (no spec yet — Rule 10): second scene (ocean/atmosphere lab parity) — `503_Simulation` scenarios; CI beyond local gates. Exact sequencing of 0004–0008: TBD — user decision. Sibling schema-bump rebase rules are stated inside each spec §3.

## Explicit Non-Goals Carried Forward

- From v0.0.1 [spec §6](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md): MLIR dialect/lowering work, CI pipeline expansion, performance optimization, provider qualification/conformance suites. Re-entry requires a normative spec.
- From [milestone 0002 spec §9](../program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md): IPC transport, custom sky shader, shoreline foam fidelity, swim/`MAP_BOUND` parameter consolidation — deferred with honest notes in [04 §9](04_simulation_engine.md).

## References

- [Documentation index](README.md)
- [spec — milestone 0001](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)
- [spec — milestone 0002](../program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md)
- [program_increments/](../program_increments/)
