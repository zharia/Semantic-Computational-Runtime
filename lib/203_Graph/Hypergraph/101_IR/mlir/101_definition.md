# mlir

> SCR MLIR Dialect Definitions

**Path:** `lib/203_Graph/Hypergraph/101_IR/mlir`

**Documentation role:** Dialect specification and implementation

## Purpose

MLIR dialect definitions for the SCR Semantic Hypergraph. Contains TableGen dialect, type, operation, and verification definitions derived from the closed semantic algebra (`SCRFormal/SCR/Algebra.lean`).

## Current Contents

| File | Purpose |
|------|---------|
| `SCRDialect.td` | Dialect registration and type declarations |
| `SCRTypes.td` | Type definitions (entity_id, value, entity, role_binding, hyperedge, hypergraph, context) |
| `SCROperations.td` | Operation definitions (add_node, remove_node, add_edge, remove_edge, update_node_value, no_op, atomic_tx, observe_node, + constructors) |
| `SCRVerification.td` | Verification passes (IncidenceWellFormed, TimeMonotonicity, IdentityPreservation, DanglingReference) |
| `101_definition.md` | This file |

## Relationship to Parent

Parent is `lib/203_Graph/Hypergraph/101_IR`. This directory contains the MLIR-specific dialect definitions.

## Derivation Chain

```
SCRFormal/SCR/Algebra.lean (canonical)
    ↓
docs/116_SCR_MLIR_DIALECT_SPECIFICATION.md (normative spec)
    ↓
SCRDialect.td / SCRTypes.td / SCROperations.td / SCRVerification.td (implementation)
```

## Implementation Status

- [x] Dialect design specification
- [x] TableGen type definitions
- [x] TableGen operation definitions
- [x] TableGen verification pass definitions
- [ ] C++ dialect registration
- [ ] C++ operation implementations
- [ ] C++ verification pass implementations
- [ ] CMake build system
- [ ] lit tests
- [ ] Integration with Lean formal model

## Scope Boundary

Should contain:
- `.td` dialect definitions (types, operations, verification)
- C++ dialect registration and operation implementations
- CMakeLists.txt
- lit test files

Should NOT contain:
- Semantic meaning definitions (upstream in SCRFormal/)
- Runtime code (downstream in runtime/)
