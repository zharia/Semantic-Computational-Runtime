# 03 — Coding Standards

**Purpose:** Establish naming and structural conventions for Mojo and GDScript/C# sources in the Godot application.
**Status:** Draft
**Owner milestone:** [v0.0.1 / milestone 0001 — Project Initiation](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)

---

> Scope note: v0.0.1 introduces no simulation code and no GDScript/C# beyond open-verification placeholders (none required). These standards are forward-looking drafts; unknowns marked `TBD — future milestone`.

## 1. General Rules

- Semantics are authoritative; implementation convenience must not redefine them (AGENTS.md Rules 1–2).
- Comments/documentation written in normal professional prose; no semantic claims without specification (Rule 10: specify before implementing).
- Files declare purpose; draft docs state Status + Owner milestone header.

## 2. Mojo Conventions

| Item | Convention | Status |
|------|-----------|--------|
| File layout | Sources under `src/mojo/`, tests under `tests/mojo/` | Active |
| Naming | `snake_case` files; types `PascalCase`; functions/variables `snake_case` (Mojo standard) | Draft |
| Package root | Version constant only at v0.0.1; no simulation API | Active |
| Module docs | File-level comment stating purpose + non-semantic placeholder note when applicable | Draft |
| MLIR relationship | Mojo = user-facing API; MLIR = sole canonical IR; no "SCR IR" / shadow IR | Active ([120](../../docs/120_SCR_Core_MLIR_Mojo_Relationship.md)) |
| Simulation naming (types, kernels, contracts) | TBD — future milestone | TBD |

## 3. GDScript Conventions

| Item | Convention | Status |
|------|-----------|--------|
| File placement | Under `godot/` project tree only | Active |
| Naming | Godot style guide defaults (snake_case files/functions, PascalCase classes) | Draft |
| Scripts at v0.0.1 | None — no simulation content, no custom GDScript required for open-verification | Active ([spec §2.5](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)) |
| Scene/script binding rules | TBD — future milestone (must respect provider boundary, [05](05_provider_boundary.md)) | TBD |

## 4. C# Conventions

Not adopted at v0.0.1. If enabled later: TBD — future milestone (must not conflict with repo-wide conventions; spec §2.4.4).

## 5. Review Checklist (draft)

- [ ] No simulation semantics introduced without a normative spec (Rule 10).
- [ ] Godot code treats engine state as provider state, not semantic truth ([05](05_provider_boundary.md)).
- [ ] Build artifacts ignored (`.gitignore`).
- [ ] Docs honesty invariant: unknowns = `TBD — future milestone`.

## References

- [Documentation index](README.md)
- [AGENTS.md](../../AGENTS.md)
- [02_development_environment.md](02_development_environment.md)
