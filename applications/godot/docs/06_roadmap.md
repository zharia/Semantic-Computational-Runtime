# 06 — Roadmap

**Purpose:** Record forward milestones beyond v0.0.1 for the Godot application.
**Status:** Draft
**Owner milestone:** [v0.0.1 / milestone 0001 — Project Initiation](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)

---

> Honesty invariant: successor milestone contents are **not specified yet**. Sequencing deferred to future program-increment specs (spec §7; AGENTS.md Rule 10: specify before implementing when semantic behavior is new). No fabricated scope below.

## Completed

| Increment | Milestone | State |
|-----------|-----------|-------|
| v0.0.1 | 0001 — Project Initiation (workspace baseline) | This document's owner milestone — see [spec](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md) |

## Planned Intent (from spec §7 — not yet specified)

Future increments (v0.0.2+) will build on this workspace toward the simulation engine vertical slice: Mojo simulation core, Godot presentation binding, provider-boundary tests. **Exact content, exit criteria, and sequencing: TBD — future milestone.**

| Increment | Milestone scope | Spec |
|-----------|----------------|------|
| v0.0.2+ | TBD — future milestone | TBD — future milestone |
| — | Simulation vertical slice (intent only, per spec §7) | TBD — future milestone |
| — | Main scene / Godot scenes | TBD — future milestone |
| — | Provider binding protocol | TBD — future milestone |
| — | CI beyond local `scripts/check_layout.sh` (out of scope for 0001) | TBD — future milestone |

## Explicit Non-Goals Carried Forward

Out of scope for v0.0.1 per [spec §6](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md): simulation algorithms/physics semantics, Godot scene content, MLIR dialect/lowering work, CI pipeline expansion, performance optimization, provider qualification/conformance suites. Re-entry into scope requires a normative spec.

## References

- [Documentation index](README.md)
- [spec — milestone 0001](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)
- [program_increments/](../program_increments/)
