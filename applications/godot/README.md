# SCR — Godot Simulation Workspace

**Mission:** Provide a professional Mojo/Godot development workspace where Mojo implements simulation semantics and computational kernels while Godot serves strictly as the presentation and simulation host provider — never as the semantic authority.

Part of the [Semantic Computational Runtime (SCR)](../../README.md).

---

## Architecture Summary

```text
Semantic Meaning → Contract → Representation → Transformation → Lowering → Provider → Runtime → Execution Substrate
```

| Layer | Technology | Role |
|-------|-----------|------|
| Simulation semantics, computational kernels, SCR-facing logic | **Mojo** (user-facing API; MLIR remains sole canonical compiler IR) | Semantic owner |
| Scenes, rendering, input, asset pipeline, windowing | **Godot** (engine host) | Provider / manifestation surface — **Provider ≠ Semantic Authority** |

Governing principle (SCR `AGENTS.md`): *Never allow implementation convenience to silently redefine computational semantics.*

Full architecture: [`docs/01_architecture.md`](docs/01_architecture.md), [`docs/05_provider_boundary.md`](docs/05_provider_boundary.md).

---

## Repository Layout

```text
applications/godot/
├── README.md                 # This file
├── docs/                     # Documentation tree (index: docs/README.md)
├── src/
│   └── mojo/                 # Mojo simulation engine sources (placeholder only at v0.0.1)
├── godot/                    # Godot project root (project.godot lives here)
├── tests/
│   ├── mojo/                 # Mojo unit/property tests (future milestones)
│   └── godot/                # Godot integration tests (future milestones)
├── scripts/                  # Build, run, lint, CI helper scripts
├── program_increments/       # Normative milestone specifications
│   └── v0.0.1/
│       └── milestone_0001_project-initiation/
│           └── spec.md       # Current milestone spec
├── .gitignore
└── LICENSE                   # License pointer (SCR repository license)
```

---

## Prerequisites

| Tool | Pinned Version | Notes |
|------|---------------|-------|
| Mojo toolchain | **1.0.0** | Not on default `PATH`. Invoke via repository-root `.venv/bin/mojo` (see `docs/02_development_environment.md`). |
| Godot editor | **4.7.2.stable** | Linux build; `godot` on `PATH` (verified: `/usr/bin/godot`). |
| Platform | **Linux** (x86_64) | Target OS for v0.0.1 workspace. |
| SCR repository root | Required | Docs (`docs/`), `AGENTS.md`, control-plane files. |

---

## Getting Started

### 1. Layout check (workspace hygiene)

```bash
bash applications/godot/scripts/check_layout.sh
```

Expected: `PASS — all required paths present.`

### 2. Mojo placeholder build (proves toolchain loads)

```bash
./.venv/bin/mojo build applications/godot/src/mojo/main.mojo -o /tmp/godot_mojo_placeholder
/tmp/godot_mojo_placeholder
```

Expected: prints `godot-app version 0.0.1` (trivial placeholder; no simulation semantics).

### 3. Godot headless open validation

```bash
godot --headless --path applications/godot/godot --quit
```

Expected: exits cleanly with no errors. Main scene is an empty verification scaffold (`godot/main.tscn` — root Node + comment-only script, no simulation content); scene design `TBD — future milestone` (`docs/04_simulation_engine.md`). Opening the editor: `godot --path applications/godot/godot`.

---

## Documentation

- Documentation index: [`docs/README.md`](docs/README.md)
  - [`01_architecture.md`](docs/01_architecture.md) — Mojo/Godot architecture, layer separation
  - [`02_development_environment.md`](docs/02_development_environment.md) — Toolchain, versions, workflows
  - [`03_coding_standards.md`](docs/03_coding_standards.md) — Mojo + GDScript conventions
  - [`04_simulation_engine.md`](docs/04_simulation_engine.md) — Simulation engine design (draft, TBD)
  - [`05_provider_boundary.md`](docs/05_provider_boundary.md) — Godot-as-provider contract
  - [`06_roadmap.md`](docs/06_roadmap.md) — Forward milestones beyond v0.0.1

SCR governing documents:

- [`docs/102_ARCHITECTURE.md`](../../docs/102_ARCHITECTURE.md)
- [`docs/103_SEMANTIC_MODEL.md`](../../docs/103_SEMANTIC_MODEL.md)
- [`docs/104_SEMANTIC_INVARIANTS.md`](../../docs/104_SEMANTIC_INVARIANTS.md)
- [`docs/120_SCR_Core_MLIR_Mojo_Relationship.md`](../../docs/120_SCR_Core_MLIR_Mojo_Relationship.md)
- [`AGENTS.md`](../../AGENTS.md)

---

## Program Increment Status

Normative milestone specifications live under [`program_increments/`](program_increments/).

- **Current:** [v0.0.1 / milestone 0001 — Project Initiation](program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)

Successor milestones (simulation engine vertical slice): `TBD — future milestone`.

---

## License

This application inherits the SCR repository license — **Apache License 2.0**. See [`LICENSE`](LICENSE) (pointer) and the repository root [`README.md`](../../README.md) License section.
