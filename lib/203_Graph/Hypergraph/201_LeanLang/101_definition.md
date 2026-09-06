# 201_LeanLang

> Directory documentation for the current SCR library tree.

**Path:** `lib/203_Graph/Hypergraph/201_LeanLang`

**Documentation role:** Repository inventory

## Purpose

Lean 4 formalization of the Semantic Hypergraph. Intended to encode normative semantic definitions as precise Lean types, structures, and predicates, and to state and prove core invariants and well-formedness conditions.

## Current Contents

| Entry | Type | Notes |
|-------|------|-------|
| `000_meta.md` | file | 33 lines; describes directory purpose, role, and relationships |

No Lean source files (`.lean`) exist yet.

## Current Role

Placeholder for future formal verification work. The `000_meta.md` describes the intended scope but no formalization has begun.

## Relationship to Parent

Parent is `lib/203_Graph/Hypergraph`. This directory provides the formal/machine-checked reference against which implementations (Rust, MLIR) can be measured. Authority flows: `101_definition.md` (semantic truth) → `201_LeanLang` (formal model) → `301_Implementation` (executable realization).

## Implementation Evidence

- No `.lean` files.
- No Lean project files (`lakefile.lean`, `lean-toolchain`).
- Only `000_meta.md` describing intent.

## Documentation Status

- [minimally populated] — only `000_meta.md` exists

## Scope Boundary

Should contain when populated:
- Lean 4 project structure
- Formal type definitions mirroring the hypergraph semantic model
- Invariant proofs (identity uniqueness, role constraints, delta application properties)
- Well-formedness predicates

Should NOT contain:
- Runtime implementation (belongs in `301_Implementation/`)
- MLIR dialect definitions (belongs in `101_IR/`)
- Domain-specific semantic authority (upstream in `101_definition.md`)

## Notes

Per the `000_meta.md`, work should begin only after the Minimal Viable Core of the hypergraph has been specified and a first executable implementation exists, so that the formalization targets a stable contract. Status recorded in `000_meta.md`: "formalization status: not started, proof coverage: 0%".
