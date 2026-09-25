# 02 — Development Environment

**Purpose:** Pin toolchain versions and document build/test/verification entry conventions for the Godot application workspace.
**Status:** Active
**Owner milestone:** [v0.0.1 / milestone 0001 — Project Initiation](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)

---

## 1. Pinned Versions

| Tool | Version | Location / invocation |
|------|---------|----------------------|
| Mojo toolchain | **1.0.0** | Repository root `.venv/bin/mojo` (NOT on default `PATH`; Modular conda-channel toolchain per root `pixi.lock` / `pyproject.toml`) |
| Godot editor | **4.7.2.stable** | `/usr/bin/godot` (`godot` on `PATH`); verified build `4.7.2.stable.arch_linux` |
| Target OS | **Linux** (x86_64) | v0.0.1 workspace target |

Version drift is a deviation: update this document and the milestone spec together.

## 2. Directory Conventions

Per [spec §2.3](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md):

- Mojo sources: `src/mojo/`
- Godot project root: `godot/` (`project.godot` lives here)
- Mojo tests: `tests/mojo/`
- Godot integration tests: `tests/godot/` (later milestones)
- Helper scripts: `scripts/`

No ad-hoc top-level source dumps (layout invariant).

## 3. Build / Run Entry Conventions

### 3.1 Mojo placeholder build

```bash
./.venv/bin/mojo build applications/godot/src/mojo/main.mojo -o /tmp/godot_mojo_placeholder
/tmp/godot_mojo_placeholder
# expected output: godot-app version 0.0.1
```

Future Mojo test entry (test framework placement): `TBD — future milestone` (tests land in `tests/mojo/`).

### 3.2 Godot open / headless validation

```bash
# Headless open-and-quit validation (CI-friendly):
godot --headless --path applications/godot/godot --quit

# Interactive editor open:
godot --path applications/godot/godot
```

At v0.0.1 the declared main scene is an **empty verification scaffold** (`godot/main.tscn`, root Node + comment-only script) — required for clean headless run; no simulation content. Main scene design: `TBD — future milestone` (see [04_simulation_engine.md](04_simulation_engine.md)).

### 3.3 Layout check

```bash
bash applications/godot/scripts/check_layout.sh
```

Verifies required directories/files per spec §2.3; exits non-zero with `MISSING:` lines on failure, prints `PASS` when green.

### 3.4 Godot test entry

`TBD — future milestone` (integration tests under `tests/godot/`).

## 4. Hygiene

- Build outputs and caches git-ignored via [`../.gitignore`](../.gitignore) (`.godot/`, `.mojo/`, `__pycache__`, editor state).
- Derived artifacts never committed (derived-artifact invariant).

## References

- [Documentation index](README.md)
- [spec §2.4–2.6](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)
- [AGENTS.md](../../AGENTS.md)
