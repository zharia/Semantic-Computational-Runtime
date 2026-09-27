# tests/godot — Godot Integration Tests

**Purpose:** Godot scene/integration tests (provider-side) for the Godot application.
**Status:** Active (milestone 0002 Sprint 04).
**Owner milestone:** [v0.0.1 / milestone 0002 — Scene Initiation](../../program_increments/v0.0.1/milestone_0002_scene-initiation/spec.md) §7 exit criteria 1–3.

## Harness

Runners are bash (repo-root relative paths inside; invoke from anywhere):

| Script | Exit criterion | What it proves |
|---|---|---|
| `godot_load_test.sh` | §7.1 | headless load of `res://scenes/island.tscn` (`--quit-after 120`), GDExtension registration, **zero** `ERROR:` lines |
| `godot_screenshot.sh` → `godot_screenshot.gd` + `check_luminance.py` | §7.2 | RENDERED capture (never `--headless`), in-script luminance (mean>10, stddev>5) + independent `check_luminance.py` re-check + content assertions (terrain chunks, `scr_meta`, HUD text) |
| `godot_playability_test.sh` → `godot_playability_test.gd` | §7.3 | scripted input via `Input.parse_input_event` through `player_input.gd` → `ScrSim.submit_input`: A1 terrain chunks, A2 meta, A3 HUD, A4 camera pitch clamp, A5 yaw follows look, B horizontal move + sprint, C no fall-through, D jump, E pause-free ticks |

Conventions:

- Exit codes: `0` PASS; non-zero = failed gate (runners print which check failed).
- No display ⇒ screenshot runner exits 2 and prints the **documented manual capture procedure** (spec §7 fallback); playability runs `--headless` and needs no display.
- Godot scripts (`*.gd`) run via `godot --path <project> -s <abs path> -- [args]`; they use `quit(N)` → shell exit code `N`.
- Artifacts: `applications/godot/build/island.png` (screenshot), logs in `mktemp` (cleaned on exit).

See also: [docs/02_development_environment.md §3.4](../../docs/02_development_environment.md) (invocation), [docs/04_simulation_engine.md §8](../../docs/04_simulation_engine.md) (verification record + current blocker).
