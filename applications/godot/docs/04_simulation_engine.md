# 04 — Simulation Engine Design

**Purpose:** Capture the simulation engine design for the Mojo/Godot application.
**Status:** Draft (honest draft — no fabricated simulation design)
**Owner milestone:** [v0.0.1 / milestone 0001 — Project Initiation](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)

---

> **Honesty invariant:** This document intentionally defines **no** simulation algorithms, physics semantics, timestep models, or engine runtime behavior. Milestone 0001 is workspace setup only ([spec §6 Out of Scope](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)). All design content below is `TBD — future milestone`.

## 1. Scope of This Document

| Topic | State |
|-------|-------|
| Workspace intent (Mojo = simulation semantics + kernels; Godot = host/provider) | Active — see [01_architecture.md](01_architecture.md) |
| Simulation domain model | **TBD — future milestone** |
| Timestep / determinism model | **TBD — future milestone** |
| Physics / field / agent semantics | **TBD — future milestone** |
| State representation & serialization | **TBD — future milestone** |
| Mojo ↔ Godot data flow (binding protocol) | **TBD — future milestone** |
| Headless execution mode | **TBD — future milestone** |
| Scene graph ↔ semantic state mapping | **TBD — future milestone** |
| Performance budgets | **TBD — future milestone** |

## 2. Current Implementation (v0.0.1)

- `src/mojo/main.mojo` — trivial placeholder: `VERSION` constant + print. **No simulation code.**
- `godot/project.godot` + empty `godot/main.tscn` (root Node + comment-only script) — open-verification scaffold only; **no simulation scene content**. Main scene design beyond empty root: **TBD — future milestone**.
- No simulation behavior or invented semantics introduced (spec §4 exit criteria).

Main scene design (beyond empty verification root): **TBD — future milestone.**

## 3. Constraints Carried Forward (normative, from governing docs)

1. Implementation convenience must not silently redefine computational semantics.
2. Godot is a provider; it does not own semantics ([05_provider_boundary.md](05_provider_boundary.md)).
3. MLIR is the sole canonical compiler IR; Mojo is the user-facing semantic API ([120](../../docs/120_SCR_Core_MLIR_Mojo_Relationship.md)).
4. Rule 9: do not invent missing foundational semantics. Rule 10: specify before implementing.

## 4. Design Sections (all deferred)

### 4.1 Domain Semantics
TBD — future milestone.

### 4.2 Engine Architecture (step loop, state ownership)
TBD — future milestone.

### 4.3 Provider Interface Contract (Mojo outputs → Godot inputs)
TBD — future milestone.

### 4.4 Testing Strategy (unit/property/integration conformance)
TBD — future milestone.

### 4.5 Successor Specification Reference
Exact sequencing deferred to a future program-increment spec ([spec §7](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md); Rule 10).

## References

- [Documentation index](README.md)
- [spec — milestone 0001](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)
- [AGENTS.md](../../AGENTS.md)
- [docs/104_SEMANTIC_INVARIANTS.md](../../docs/104_SEMANTIC_INVARIANTS.md)
