# 201_LeanLang

> Directory lean-lang implementation for the domain.

**Path:** `lib/<domain>>/<subdomain>/01_lean-lang`

## Purpose

Lean 4 formalization of the Semantic subdomain. Intended to encode semantic definitions as precise Lean types, structures, and predicates, and to state and prove core invariants and well-formedness conditions.

## Current Contents

| Entry | Type | Notes |
|-------|------|-------|
|  | file |  |

No Lean source files (`.lean`) exist yet.

## Current Role

Placeholder for future formal verification work. 

## Relationship to Parent

Parent is `lib/<domain>>/<subdomain>`. This directory provides the formal/machine-checked reference against which implementations (Rust, MLIR) can be measured. Authority flows: `101_definition.md` (semantic truth) → `01_lean-lang` (formal model) → `mlir` (executable realization).

## Implementation Evidence

- 

## Documentation Status

- 

## Scope Boundary

Should contain when populated:
- Lean 4 project structure
- Formal type definitions mirroring the subdomain semantic model
- Invariant proofs (identity uniqueness, role constraints, delta application properties)
- Well-formedness predicates

Should NOT contain:
- Runtime documentation (belongs in `mlir`)
- MLIR dialect definitions (belongs in `../IR/mlir`)
- Domain-specific semantic authority (upstream in `101_definition.md`)

## Notes
