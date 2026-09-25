# 01 — Architecture: Mojo/Godot Layer Separation

**Purpose:** Define the architectural relationship between Mojo (simulation semantics) and Godot (engine host/provider) for the Godot application.
**Status:** Draft
**Owner milestone:** [v0.0.1 / milestone 0001 — Project Initiation](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)

---

## 1. Governing Principle

> **Never allow implementation convenience to silently redefine computational semantics.**
> (SCR `AGENTS.md`, Governing Principle)

Layer separation preserved in all work under `applications/godot/`:

```text
Semantic Meaning → Contract → Representation → Transformation → Lowering → Provider → Runtime → Execution Substrate
```

## 2. Layer Assignment

| Layer | Owner in this application |
|-------|---------------------------|
| Semantic Meaning, Contract | SCR control plane / semantic domains (repository `lib/`, `docs/`) |
| Representation, Transformation, Lowering | Mojo user-facing API; MLIR remains sole canonical compiler IR (MLIR-first policy) |
| Provider | **Godot** — scenes, rendering, input, asset pipeline, windowing |
| Runtime, Execution Substrate | Godot runtime hosting Mojo-produced artifacts; substrates CPU/GPU/etc. |

## 3. Role Statements

- **Mojo:** implements simulation semantics, computational kernels, and SCR-facing logic. User-facing API for simulation semantics; not a shadow IR (see [120_SCR_Core_MLIR_Mojo_Relationship.md](../../docs/120_SCR_Core_MLIR_Mojo_Relationship.md)).
- **Godot:** presentation/simulation host provider. Provider ≠ Semantic Authority (AGENTS.md Rules 1, 2, 6). Detailed contract: [05_provider_boundary.md](05_provider_boundary.md).

## 4. Not-Equals Invariants (application scope)

```text
Specification ≠ Implementation
Provider ≠ Semantic Authority
Backend ≠ Semantic Meaning
Godot scene state ≠ Simulation semantic state
```

## 5. Current Implementation State (v0.0.1)

Workspace scaffold only. No simulation behavior, no scenes, no simulation code beyond tooling placeholders.

- Mojo placeholder: `src/mojo/main.mojo` (version constant only).
- Godot placeholder: `godot/project.godot` (name + pinned feature tags; no main scene — deferred, `TBD — future milestone`).

## 6. Open Design Questions

TBD — future milestone (simulation vertical slice specification).

## References

- [AGENTS.md](../../AGENTS.md)
- [docs/102_ARCHITECTURE.md](../../docs/102_ARCHITECTURE.md)
- [docs/103_SEMANTIC_MODEL.md](../../docs/103_SEMANTIC_MODEL.md)
- [docs/104_SEMANTIC_INVARIANTS.md](../../docs/104_SEMANTIC_INVARIANTS.md)
- [docs/120_SCR_Core_MLIR_Mojo_Relationship.md](../../docs/120_SCR_Core_MLIR_Mojo_Relationship.md)
- [Documentation index](README.md)
