# 05 — Provider Boundary: Godot as Provider

**Purpose:** State the contract boundary between Godot (provider/manifestation surface) and SCR/Mojo (semantic authority) for this application.
**Status:** Active
**Owner milestone:** [v0.0.1 / milestone 0001 — Project Initiation](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)

---

## 1. Authority Statement

> **Godot is a provider and manifestation surface. It is not the semantic authority.**

Normative basis:

- [AGENTS.md](../../AGENTS.md) — Governing Principle; Rules **1** (semantics are authoritative), **2** (implementation does not define meaning), **6** (providers implement contracts; they do not own them), **7** (representations preserve semantics), **12** (semantic vs numerical vs bitwise equivalence).
- [docs/102_ARCHITECTURE.md](../../docs/102_ARCHITECTURE.md) — semantic structure primary; physical execution is manifestation; physical mechanisms MUST NOT redefine semantics.
- [docs/103_SEMANTIC_MODEL.md](../../docs/103_SEMANTIC_MODEL.md) — semantic model authority.
- [docs/104_SEMANTIC_INVARIANTS.md](../../docs/104_SEMANTIC_INVARIANTS.md) — invariants that provider behavior must not violate.
- [docs/120_SCR_Core_MLIR_Mojo_Relationship.md](../../docs/120_SCR_Core_MLIR_Mojo_Relationship.md) — Mojo = user-facing semantic API; MLIR = sole canonical IR.

## 2. Boundary Diagram

```text
┌──────────────────────────────────────┐        ┌──────────────────────────────────────┐
│  SEMANTIC SIDE (authority)           │        │  PROVIDER SIDE (subordinate)         │
│  SCR control plane / Mojo            │        │  Godot engine host                   │
│  - contracts, semantics, kernels     │  ───►  │  - scenes, rendering, input          │
│  - owns meaning                      │ binds  │  - asset pipeline, windowing         │
│  - defines equivalence classes       │        │  - implements presentation contract  │
└──────────────────────────────────────┘        └──────────────────────────────────────┘
   Provider ≠ Semantic Authority. Backend ≠ Semantic Meaning.
```

## 3. Semantic State vs Provider State

| | Semantic state | Provider state |
|---|----------------|----------------|
| Owner | SCR/Mojo layer | Godot runtime |
| Examples | Simulation values, contracts, equivalence classes | Scene tree nodes, draw state, input buffers, import cache |
| Authority | Authoritative for meaning | Never authoritative for meaning |
| Mutation rule | Per semantic contract specs (`TBD — future milestone`) | May lag/drop/reorder presentation without redefining semantics |

**Invariant:** Godot scene state is a projection of semantic state, not its definition. Rendering/display differences never alter semantic equivalence classes (Rule 12).

## 4. Contract Rules (binding on all future work)

1. Godot-side code implements presentation/simulation-host contracts; it never invents or overrides domain semantics (Rules 6, 9).
2. Any new provider capability requires a semantic contract first (Rule 10: specify before implementing).
3. Provider limitations MUST NOT weaken semantic contracts — escalate instead (AGENTS.md "When to Escalate").
4. No shadow IR: Rust/JSON/YAML/Godot resources are handles/metadata only, not parallel IRs (MLIR-first policy).

## 5. Current State (v0.0.1)

Workspace scaffold only. No provider binding protocol implemented yet.

Binding protocol / RPC / snapshot exchange: **TBD — future milestone** (see [04_simulation_engine.md](04_simulation_engine.md)).

## References

- [Documentation index](README.md)
- [01_architecture.md](01_architecture.md)
- [spec — authority invariant (§3.2)](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)
