# 101_IR

> Directory documentation for the current SCR library tree.

**Path:** `lib/203_Graph/Hypergraph/101_IR`

**Documentation role:** Repository inventory

## Purpose

Intermediate representation directory for the Semantic Hypergraph domain. Intended to hold MLIR dialect definitions, IR types, operations, and verification rules specific to hypergraph semantics.

## Current Contents

| Entry | Type | Notes |
|-------|------|-------|
| `mlir/` | subdirectory | Empty; placeholder for MLIR dialect definitions |

## Current Role

Structural placeholder. No IR definitions, MLIR dialect files, or verification rules exist yet.

## Relationship to Parent

Parent is `lib/203_Graph/Hypergraph`. This directory represents the MLIR/IR layer of the hypergraph domain, sitting between the semantic definition and concrete implementation/lowering.

## Implementation Evidence

- No `.td` files, no MLIR dialect definitions, no operation definitions, no type definitions.
- Only content is an empty `mlir/` subdirectory.

## Documentation Status

- [populated] — this file

## Scope Boundary

Should contain:
- Hypergraph MLIR dialect definitions (operations, types, attributes)
- Verification passes
- Canonicalization patterns

Should NOT contain:
- Semantic definitions (belong in `101_definition.md` at Hypergraph root)
- Rust implementation (belongs in `301_Implementation/`)
- Lean formalization (belongs in `201_LeanLang/`)

## Notes

The `mlir/` subdirectory exists but is empty, indicating MLIR work has not begun for this domain.
