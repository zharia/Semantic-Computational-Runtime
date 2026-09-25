# Milestone 0001: Project Initiation — Godot Simulation Workspace

**Program Increment:** v0.0.1
**Milestone:** 0001 — Project Initiation
**Project:** Godot Simulation (applications/godot)
**Parent System:** Semantic Computational Runtime (SCR)
**Status:** Complete — all exit criteria verified (§4)
**Primary Language:** Mojo
**Initial Engine Provider:** Godot
**Target:** Professional project workspace baseline for simulation engine development

---

## 1. Scope & Objective

Establish the project workspace for `applications/godot` as a professional Mojo/Godot simulation development environment.

Objective: create the directory structure, documentation skeleton, and tooling conventions required to begin implementing a simulation engine where:

- **Mojo** implements simulation semantics, computational kernels, and SCR-facing logic.
- **Godot** acts as the presentation/simulation host provider (scenes, rendering, input, asset pipeline).

This milestone delivers workspace setup only. It delivers no simulation behavior, no Godot scenes, and no Mojo simulation code beyond tooling placeholders required to prove the workspace is buildable and navigable.

### Governing Principle

> Implementation convenience must not silently redefine computational semantics.

Layer separation preserved in all subsequent work:

```text
Semantic Meaning → Contract → Representation → Transformation → Lowering → Provider → Runtime → Execution Substrate
```

Godot is a provider and manifestation surface. It is not the semantic authority. Mojo is the user-facing API for simulation semantics; MLIR remains the sole canonical compiler IR (per SCR MLIR-first policy).

---

## 2. Deliverables

### 2.1 README

Professional root `README.md` at `applications/godot/README.md` containing:

1. Project title and one-sentence mission statement.
2. Architecture summary: Mojo (simulation engine) + Godot (engine host/provider).
3. Repository layout overview (directory map).
4. Prerequisites (Mojo toolchain, Godot version, platform notes).
5. Getting started / build-and-run quickstart.
6. Link to `docs/`.
7. Program increment status pointer to `program_increments/`.
8. License / contribution pointers as applicable.

### 2.2 docs/ Directory

Professional documentation tree at `applications/godot/docs/` with entrypoint index:

```text
docs/
├── README.md                      # Documentation index / navigation
├── 01_architecture.md             # Mojo/Godot architecture, layer separation
├── 02_development_environment.md  # Toolchain setup, versions, workflows
├── 03_coding_standards.md         # Mojo + GDScript/C# conventions, naming
├── 04_simulation_engine.md        # Simulation engine design (initial draft, TBD sections explicit)
├── 05_provider_boundary.md        # Godot-as-provider contract; semantic vs provider state
└── 06_roadmap.md                  # Forward milestones beyond v0.0.1
```

Every doc file must state purpose, status (Draft/Active), and owner milestone. Unknown content is marked explicitly `TBD — future milestone`; no fabricated semantics.

### 2.3 Workspace Layout

```text
applications/godot/
├── README.md
├── docs/
│   └── ...
├── src/
│   └── mojo/                      # Mojo simulation engine sources
├── godot/                         # Godot project root (project.godot lives here)
├── tests/
│   ├── mojo/                      # Mojo unit/property tests
│   └── godot/                     # Godot integration tests (later milestones)
├── scripts/                       # Build, run, lint, CI helper scripts
├── program_increments/
│   └── v0.0.1/
│       └── milestone_0001_project-initiation/
│           └── spec.md            # This document
├── .gitignore                     # Mojo build artifacts, Godot .godot/ cache
└── LICENSE (or LICENSE pointer)
```

Directories without required content receive a `.gitkeep` or a minimal `README.md` stating intended purpose.

### 2.4 Tooling & Hygiene

1. `.gitignore` covering Godot import cache (`.godot/`), Mojo/`__pycache__`-style artifacts, and local editor state.
2. `scripts/` with at minimum:
   - `check_layout.sh` — verifies required directories and files exist.
3. Version pinning documented in `docs/02_development_environment.md` (Mojo version, Godot version, target OS).
4. Editor/tooling config files (e.g., `.editorconfig`) optional but, if present, must not conflict with repo-wide conventions.

### 2.5 Godot Project Placeholder

Minimal Godot project scaffold under `godot/` sufficient to open in the Godot editor without errors:

- `project.godot` with project name and pinned feature tags (e.g., renderer selection).
- Empty default main scene declared or explicitly deferred with `TBD` note in docs.
- No simulation content; no custom GDScript/C# beyond placeholder if needed for open-verification.

### 2.6 Mojo Project Placeholder

Minimal Mojo package scaffold under `src/mojo/`:

- Package/module root file with a trivial, non-semantic placeholder (e.g., version constant or empty module docstring).
- Build/test entry convention documented in `docs/02_development_environment.md`.
- No simulation semantics defined at this milestone (Rule 9: do not invent missing foundational semantics).

---

## 3. Formal Invariants

1. **Workspace invariant:** `README.md` and `docs/` exist at `applications/godot/` upon milestone completion.
2. **Authority invariant:** Documentation describes Godot strictly as a provider/manifestation; semantic ownership remains with SCR/Mojo layer. Provider ≠ Semantic Authority.
3. **Honesty invariant:** Unknown design content is labeled `TBD`; documentation never asserts nonexistent implementation or fabricated semantics.
4. **Scope invariant:** No simulation algorithms, physics semantics, or engine runtime behavior are introduced in this milestone.
5. **Layout invariant:** All future source lives under the declared layout (`src/mojo/`, `godot/`, `tests/`, `scripts/`); no ad-hoc top-level source dumps.
6. **Derived-artifact invariant:** Godot import caches and build outputs are git-ignored, never committed.
7. **Traceability invariant:** This spec is the single normative source for milestone 0001 exit criteria; README/docs link back to `program_increments/`.

---

## 4. Exit Criteria

- [x] `applications/godot/README.md` exists and satisfies §2.1 contents.
- [x] `applications/godot/docs/` exists with index `README.md` and files `01`–`06` per §2.2 (draft quality acceptable; TBDs marked).
- [x] Workspace layout per §2.3 created (empty dirs preserved via `.gitkeep`/placeholder README).
- [x] `.gitignore` excludes Godot/Mojo build and cache artifacts.
- [x] `scripts/check_layout.sh` passes: verifies required paths exist.
- [x] Godot project opens without errors (or scaffold is documented as intentionally deferred with explicit TBD).
- [x] Mojo package root compiles/loads under documented toolchain version (trivial placeholder only).
- [x] No simulation behavior, scene content, or invented semantics introduced.
- [x] `docs/` and README cross-link to this spec and to SCR governing docs as applicable.
- [x] Review pass: README + docs reviewed for provider/semantic conformance (invariant 2).

**Verification record (2026-09-25):**

| Check | Result |
|---|---|
| `bash scripts/check_layout.sh` | PASS (exit 0) |
| `godot --headless --path godot --quit` | PASS (v4.7.2, exit 0, no errors) |
| `./.venv/bin/mojo build src/mojo/main.mojo` | PASS (Mojo 1.0.0, runs, prints version placeholder) |
| Sim semantics introduced | None (scope invariant honored; TBD markers present throughout docs) |

---

## 5. Dependencies

- **None (foundational milestone).** No prior Godot-application milestones exist.
- **External toolchains (runtime environment, not prior milestones):**
  - Mojo toolchain installed and version recorded.
  - Godot editor installed and version recorded.
  - SCR repository root accessible (`docs/`, `AGENTS.md`, control-plane files).

---

## 6. Out of Scope

- Simulation engine algorithms, physics models, or domain semantics.
- Godot scenes, scripts (beyond open-verification placeholder), or asset content.
- MLIR dialect work or lowering pipelines.
- CI pipeline beyond local `scripts/check_layout.sh`.
- Performance optimization, provider qualification, or conformance testing suites.

---

## 7. Successor Milestones

Future increments (v0.0.2+) will build on this workspace to implement the simulation engine vertical slice: Mojo simulation core, Godot presentation binding, and provider-boundary tests. Exact sequencing deferred to a future program-increment spec (Rule 10: specify before implementing when semantic behavior is new).
