# mlir

> Directory documentation for the current SCR library tree.

**Path:** `lib/203_Graph/Hypergraph/101_IR/mlir`

**Documentation role:** Repository inventory

## Purpose

MLIR dialect definitions for the Semantic Hypergraph. Intended to hold `.td` tablegen files, dialect registration, operation definitions, type definitions, and verification infrastructure.

## Current Contents

Empty directory. No files or subdirectories present.

## Current Role

Structural placeholder. No MLIR dialect has been defined for hypergraph semantics yet.

## Relationship to Parent

Parent is `lib/203_Graph/Hypergraph/101_IR`. This is the leaf directory where MLIR-specific definitions would live.

## Implementation Evidence

- Empty directory.
- No `.td` files, no `.cpp` files, no dialect registration code.

## Documentation Status

- [populated] — this file

## Scope Boundary

Should contain when populated:
- `HypergraphOps.td` — operation definitions
- `HypergraphTypes.td` — type definitions
- `HypergraphDialect.td` — dialect definition
- Verification passes
- Canonicalization patterns
- Dialect registration code

Should NOT contain:
- Semantic meaning definitions (upstream)
- Rust runtime code (downstream)

## Notes

This is the lowest-level IR directory for the hypergraph domain. MLIR work should begin only after the semantic definition and minimal Rust implementation are stable, per the implementation plan in `301_Implementation/000_meta.md`.
