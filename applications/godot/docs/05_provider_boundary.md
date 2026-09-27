# 05 — Provider Boundary: Godot as Provider

**Purpose:** State the contract boundary between Godot (provider/manifestation surface) and SCR/Mojo (semantic authority) for this application.
**Status:** Active
**Owner milestone:** [v0.0.1 / milestone 0001 — Project Initiation](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md) (§5 specified by milestone 0002 Sprint 03/04)

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

## 5. Current State (v0.0.1 / milestone 0002)

Binding protocol implemented as the normative **[`104_contract.md`](../../providers/render/graphics/godot/104_contract.md)** (byte schema v1 + C ABI + input uplink). Summary (full spec there; flow detail in [04 §4.3/§5](04_simulation_engine.md)):

- **Transport:** in-process `dlopen` of `build/libscr_sim.so` by the GDExtension adapter (`providers/.../adapter/scr_sim_loader.h`), negotiated via `scr_sim_abi_version()` (=1) and `scr_sim_schema_version()` (=1). Schema mismatch is refused loudly (`tests/test_schema_mismatch.sh`). IPC transport swap deferred (stabilized contract = trigger, §6).
- **Downlink (sim → provider):** `RenderSnapshot` — 48-byte envelope + framed sections `1 PLAYER, 2 TERRAIN_META, 3 TERRAIN, 4 OCEAN, 5 SKY, 6 MATERIALS`. Provider validates strictly and skips invalid frames; it never coerces or invents values (Rule 6).
- **Uplink (provider → sim):** `scr_input_batch` — raw input intent only (20 bytes). The adapter clamps movement to the unit circle and accumulates look deltas; **the sim integrates all motion** (AP-8, Rule 1: `ScrSim` never moves nodes itself beyond applying the decoded snapshot).
- **Presentation application:** adapter maps snapshot sections onto group nodes (`scr_terrain, scr_meta, scr_ocean, scr_sun, scr_env, scr_camera, scr_hud, scr_materials`) per [04 §5](04_simulation_engine.md). Absent groups ⇒ presentation absent; provider code may not redefine what a section *means* (Rules 2, 6).
- **Status:** implemented and gated (Sprint 03/04); decode path currently blocked by the MATERIALS framing inconsistency documented in [04 §8](04_simulation_engine.md) — escalated, not worked around here.

## References

- [Documentation index](README.md)
- [01_architecture.md](01_architecture.md)
- [spec — authority invariant (§3.2)](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)
