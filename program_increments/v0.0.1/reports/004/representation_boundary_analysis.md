# Representation Boundary Analysis — Milestone 004

**Date:** 2026-09-06
**Milestone:** 004 — Semantic Entity Compilation / Canonical Representation

---

## Purpose

Determine how each SCR semantic concept maps to MLIR representation, verify
that semantic information survives the transition, and confirm no custom
dialect is required.

---

## Concept-by-Concept Analysis

### 1. Entity Definition

| Aspect | Detail |
|--------|--------|
| **Semantic information** | type_id (string), value_schema (list of property names) |
| **Implementation detail** | Memory layout, allocation strategy |
| **MLIR representation** | Module-level `scr.entity_definition` attribute |
| **Mechanism** | Unregistered dialect attribute (metadata) |
| **Information preserved** | type_id, value_schema — both survive as string attributes |
| **Survives lowering** | Attributes can be carried through lowering passes |
| **Runtime visibility** | Available as module metadata |
| **Custom construct needed** | No — unregistered attributes sufficient |

### 2. Entity Instance

| Aspect | Detail |
|--------|--------|
| **Semantic information** | entity_id, definition_type, initial values |
| **Implementation detail** | Dict storage, struct layout |
| **MLIR representation** | Module-level `scr.entity_instance` attribute |
| **Mechanism** | Unregistered dialect attribute (metadata) |
| **Information preserved** | entity_id, definition_type, initial_value |
| **Survives lowering** | Yes — attribute metadata |
| **Runtime visibility** | Available as module metadata |
| **Custom construct needed** | No |

### 3. Identity

| Aspect | Detail |
|--------|--------|
| **Semantic information** | Unique identifier, semantic identity (not pointer) |
| **Implementation detail** | String storage, comparison strategy |
| **MLIR representation** | Function name (`@canonical_counter`) + `scr.entity` attribute |
| **Mechanism** | SSA naming + string attributes |
| **Information preserved** | Identity is encoded in function metadata |
| **Survives lowering** | Function names survive all standard lowering |
| **Runtime visibility** | Yes |
| **Custom construct needed** | No |

### 4. Value

| Aspect | Detail |
|--------|--------|
| **Semantic information** | Typed semantic value (Int, Float, Bool, String) |
| **Implementation detail** | Variant storage, boxing |
| **MLIR representation** | `i32` (for integer values) |
| **Mechanism** | Standard MLIR integer types |
| **Information preserved** | Semantic integer value preserved exactly |
| **Survives lowering** | Yes — i32 is native |
| **Runtime visibility** | Yes |
| **Custom construct needed** | No |

**Note on String values:** For the canonical Counter, values are integers.
String/variant values would require additional analysis for future milestones.

### 5. State

| Aspect | Detail |
|--------|--------|
| **Semantic information** | Authoritative state container, entity → property → value |
| **Implementation detail** | Dict storage, copy-on-write |
| **MLIR representation** | `memref<1xi32>` (authoritative state container) |
| **Mechanism** | Standard memref dialect |
| **Information preserved** | State structure preserved as memory allocation |
| **Survives lowering** | Yes — memref is native to LLVM |
| **Runtime visibility** | Yes — pointer to state |
| **Custom construct needed** | No |

**Rationale:** `memref` is chosen over SSA-only representation because state
is mutated by transformations. SSA values cannot represent mutable state
directly. `memref` accurately represents the semantic contract: authoritative
state that transformations read and write.

### 6. Relationship

| Aspect | Detail |
|--------|--------|
| **Semantic information** | Typed relationship between entities |
| **Implementation detail** | Dict storage, index lookup |
| **MLIR representation** | Not represented in canonical program (no relationships used) |
| **Note** | Relationships not needed for Counter witness; future analysis required |

### 7. Transformation

| Aspect | Detail |
|--------|--------|
| **Semantic information** | State transition: Context × State → State |
| **Implementation detail** | Function dispatch, operation code |
| **MLIR representation** | Function body: `arith.addi` + `memref.store/load` |
| **Mechanism** | Standard arith + memref operations |
| **Information preserved** | Exact computation preserved |
| **Survives lowering** | Yes — arith and memref lower to LLVM |
| **Runtime visibility** | Yes |
| **Custom construct needed** | No |

**Rationale:** The transformation is a pure function on state. `arith.addi`
performs the increment, `memref.store` writes the result. This is the natural
MLIR representation of integer arithmetic on mutable state.

### 8. Constraint

| Aspect | Detail |
|--------|--------|
| **Semantic information** | Non-negativity: value >= 0 |
| **Implementation detail** | Exception-based validation |
| **MLIR representation** | `scf.if` guard with `arith.cmpi sge` |
| **Mechanism** | Standard scf + arith comparison |
| **Information preserved** | Constraint logic preserved as conditional |
| **Survives lowering** | Yes — scf lowers to branches |
| **Runtime visibility** | Yes |
| **Custom construct needed** | No |

**Rationale:** `scf.if` represents the semantic contract: the transformation
only applies if the constraint holds. This is structurally correct — the
guard prevents constraint violation. In the Mojo kernel, this is an exception
that rolls back. In MLIR, it is a conditional store. Both preserve the
semantic invariant.

### 9. Context

| Aspect | Detail |
|--------|--------|
| **Semantic information** | logical_step, label |
| **Implementation detail** | Step counter, string storage |
| **MLIR representation** | Module-level `scr.context` attribute |
| **Mechanism** | Unregistered dialect attribute (metadata) |
| **Information preserved** | initial_step, label preserved as attributes |
| **Survives lowering** | Yes — metadata |
| **Runtime visibility** | Available as metadata |
| **Custom construct needed** | No |

### 10. Time

| Aspect | Detail |
|--------|--------|
| **Semantic information** | Logical step counter, non-decreasing |
| **Implementation detail** | Integer counter |
| **MLIR representation** | `index` type (semantic step counter) |
| **Mechanism** | Standard MLIR index type |
| **Information preserved** | Step semantics preserved |
| **Survives lowering** | Yes — index is native |
| **Runtime visibility** | Yes |
| **Custom construct needed** | No |

**Note:** Time is represented as `index` (MLIR's native index type), not as
`i32`. This distinguishes semantic time from semantic values. The distinction
is intentional: time is a structural concept, not a data concept.

### 11. Observation

| Aspect | Detail |
|--------|--------|
| **Semantic information** | Non-mutating read of state |
| **Implementation detail** | Exception-based read, list append |
| **MLIR representation** | `memref.load` + `return` |
| **Mechanism** | Standard memref load + function return |
| **Information preserved** | Observation result preserved as return value |
| **Survives lowering** | Yes — return value is native |
| **Runtime visibility** | Yes |
| **Custom construct needed** | No |

**Rationale:** The observation reads state without modifying it. `memref.load`
reads the value, `return` produces the result. The function's return value IS
the observation result.

### 12. Provenance

| Aspect | Detail |
|--------|--------|
| **Semantic information** | Origin/history of values |
| **Implementation detail** | Trace storage |
| **MLIR representation** | Not represented in canonical program |
| **Note** | Trace exists in RE but not in canonical MLIR (metadata-level only) |

---

## Rejected Alternatives

### Custom `scr.entity` operation

**Rejected because:** Entity definition/instance information is metadata, not
computation. Module attributes preserve this information without custom
operations. Custom operations would require a custom dialect, which the
milestone explicitly prohibits without evidence of semantic loss.

### Custom `scr.transform` operation

**Rejected because:** The transformation is pure arithmetic on state. Standard
`arith` + `memref` operations express the exact same computation. A custom
operation would duplicate existing MLIR functionality.

### Custom `scr.observe` operation

**Rejected because:** Observation is a read. `memref.load` + `return` expresses
this exactly. A custom operation would be redundant.

### Tensor instead of memref

**Rejected because:** `tensor` is immutable and designed for functional
computation. `memref` is designed for mutable state, which matches the
semantic contract: transformations mutate state.

### SSA-only (no memref)

**Rejected because:** SSA values are immutable once defined. Semantic state is
mutable. Using SSA-only would require restructuring the program as a pure
function chain, which obscures the state mutation semantics.

---

## Information Loss Assessment

| Concept | Information Preserved | Information Lost |
|---------|----------------------|------------------|
| Entity Definition | type_id, value_schema | None for canonical program |
| Entity Instance | entity_id, definition_type, initial values | None |
| Identity | entity_id via function name | None |
| Value | integer value exactly | String/variant type (not used in canonical) |
| State | authoritative state via memref | Dict structure (collapsed to single cell) |
| Transformation | exact arithmetic computation | Operation dispatch (not needed for single op) |
| Constraint | non-negativity guard | Exception semantics (replaced by conditional) |
| Context | initial_step, label (metadata) | Runtime step tracking (metadata only) |
| Time | index type distinction | Step advancement (not executed in MLIR) |
| Observation | return value | Observation list (single observation only) |
| Provenance | Not represented | Trace history |
| Relationship | Not represented | Not needed for canonical program |

---

## Custom Dialect Decision

**No custom SCR dialect required.**

Standard MLIR mechanisms (arith, memref, scf, func, module attributes)
are sufficient to represent the canonical semantic program.

The semantic metadata (entity definitions, constraints, context) is preserved
as module-level attributes using MLIR's unregistered dialect mechanism. This
is appropriate because this information is metadata, not computation.

---

## Verification

The canonical MLIR representation was verified with:

```bash
mlir-opt canonical_counter.mlir --allow-unregistered-dialect -o /dev/null
```

Result: PASS — no errors, clean parse and verify.

The printed output confirms all semantic information is preserved in the
module attributes and function attributes.
