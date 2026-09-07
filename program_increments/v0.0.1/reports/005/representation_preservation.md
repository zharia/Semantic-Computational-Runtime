# Representation Preservation — Milestone 005

**Date:** 2026-09-06
**Milestone:** Representation Preservation and Executable Equivalence

---

## Representation Contract

> A representation is correct when it preserves every semantic property
> required by the source contract at the boundary being verified.

---

## Concept-by-Concept Representation Analysis

### Identity

| Aspect | Detail |
|--------|--------|
| **Semantic concept** | Persistent unique identifier for an entity |
| **Required properties** | Uniqueness, persistence, independence from representation |
| **Chosen representation** | `scr.entity` string attribute on function |
| **Representation invariant** | Attribute value equals semantic entity_id |
| **Verification method** | Attribute inspection + test `test_identity_is_independent_of_representation` |
| **Survives lowering** | Yes — LLVM module retains metadata |

### Entity

| Aspect | Detail |
|--------|--------|
| **Semantic concept** | Identifiable participant with state |
| **Required properties** | Identity, type, state structure |
| **Chosen representation** | Function + memref + attributes |
| **Representation invariant** | Function encapsulates entity computation |
| **Verification method** | Execution produces correct semantic result |
| **Survives lowering** | Yes — function and allocations lower to LLVM |

### Entity Definition

| Aspect | Detail |
|--------|--------|
| **Semantic concept** | Schema describing admissible structure |
| **Required properties** | type_id, value_schema |
| **Chosen representation** | `scr.entity_definition` module attribute |
| **Representation invariant** | Attribute contains type_id and value_schema |
| **Verification method** | Attribute inspection |
| **Survives lowering** | Yes — module attributes retained |

### Entity Instance

| Aspect | Detail |
|--------|--------|
| **Semantic concept** | Concrete entity with identity and state |
| **Required properties** | entity_id, definition_type, initial values |
| **Chosen representation** | `scr.entity_instance` module attribute + memref initialization |
| **Representation invariant** | Attribute matches initial memref contents |
| **Verification method** | Attribute inspection + execution result |
| **Survives lowering** | Yes — both attribute and code lower |

### Value

| Aspect | Detail |
|--------|--------|
| **Semantic concept** | Typed semantic value |
| **Required properties** | Type correctness, value preservation |
| **Chosen representation** | `i32` (for integer values) |
| **Representation invariant** | i32 value equals semantic integer value |
| **Verification method** | Execution produces correct result |
| **Survives lowering** | Yes — i32 is native LLVM type |

### State

| Aspect | Detail |
|--------|--------|
| **Semantic concept** | Authoritative entity → property → value mapping |
| **Required properties** | Mutability, independence between entities |
| **Chosen representation** | `memref<1xi32>` per entity property |
| **Representation invariant** | memref contents equal semantic state values |
| **Verification method** | Execution + observation |
| **Survives lowering** | Yes — memref lowers to LLVM alloca |

**IMPORTANT:** memref is a physical manifestation, not semantic state.
The same semantic state could be represented by:
- `i32` (single value)
- `tensor<1xi32>` (functional)
- `memref<1xi32>` (mutable)
- Array on stack
- Heap allocation

The semantic contract is independent of the representation choice.

### Transformation

| Aspect | Detail |
|--------|--------|
| **Semantic concept** | State transition: Context × State → State |
| **Required properties** | Determinism, constraint preservation |
| **Chosen representation** | `arith.addi` + `memref.store` |
| **Representation invariant** | Arithmetic result equals semantic transformation result |
| **Verification method** | Execution produces correct state |
| **Survives lowering** | Yes — arith lowers to LLVM instructions |

**IMPORTANT:** The semantic transformation is a mathematical mapping:
```
T : State → State'
```
The physical `memref.store` is an implementation of this mapping,
not the transformation itself.

### Constraint

| Aspect | Detail |
|--------|--------|
| **Semantic concept** | State predicate that must hold |
| **Required properties** | Violation is observable, distinct from no-op |
| **Chosen representation** | `scf.if` with `arith.cmpi sge` |
| **Representation invariant** | Guard prevents store when constraint fails |
| **Verification method** | `test_constraint_violation_is_not_noop` |
| **Survives lowering** | Yes — scf lowers to LLVM branch |

### Constraint Failure

| Aspect | Detail |
|--------|--------|
| **Semantic concept** | Observable failure when constraint violated |
| **Required properties** | State unchanged, time unchanged, failure observable |
| **Chosen representation** | scf.if else branch (no store on failure) |
| **Representation invariant** | Failed transform does not write to memref |
| **Verification method** | `test_constraint_violation_is_not_noop` |
| **Survives lowering** | Yes — else branch compiles to no-op |

### SemanticTime

| Aspect | Detail |
|--------|--------|
| **Semantic concept** | Non-decreasing logical step counter |
| **Required properties** | Ordering, advancement, representation independence |
| **Chosen representation** | `index` type (step constant) |
| **Representation invariant** | index value equals logical_step |
| **Verification method** | `test_semantic_time_is_representation_independent` |
| **Survives lowering** | Yes — index lowers to i64 |

**IMPORTANT:** `index` is a representation choice, not SemanticTime itself.
The semantic contract (non-decreasing, deterministic) is independent of
the representation type.

### Context

| Aspect | Detail |
|--------|--------|
| **Semantic concept** | Transformation environment (time, label) |
| **Required properties** | Advancement, label preservation |
| **Chosen representation** | `scr.context` module attribute |
| **Representation invariant** | Attribute contains initial_step and label |
| **Verification method** | Attribute inspection + test |
| **Survives lowering** | Yes — module attributes retained |

### Observation

| Aspect | Detail |
|--------|--------|
| **Semantic concept** | Non-mutating read of state |
| **Required properties** | State unchanged, result correct |
| **Chosen representation** | `memref.load` + `return` |
| **Representation invariant** | Return value equals observed state value |
| **Verification method** | `test_canonical_observation_noninterference` |
| **Survives lowering** | Yes — load + return lower to LLVM |

### Relationship

| Aspect | Detail |
|--------|--------|
| **Semantic concept** | Typed connection between entities |
| **Required properties** | Source/target identity, type, direction |
| **Chosen representation** | `scr.relationship` module attribute |
| **Representation invariant** | Attribute contains rel_id, kind, source, target |
| **Verification method** | `test_relationship_semantics` |
| **Survives lowering** | Yes — module attributes retained |

### Provenance

| Aspect | Detail |
|--------|--------|
| **Semantic concept** | Traceability from representation to source |
| **Required properties** | Source identification, definition linkage |
| **Chosen representation** | `scr.provenance` module attribute |
| **Representation invariant** | Attribute contains source, definition, milestone |
| **Verification method** | Attribute inspection |
| **Survives lowering** | Yes — module attributes retained |

---

## Information Preservation Summary

| Concept | Preserved in MLIR | Preserved through Lowering | Preserved in Execution |
|---------|-------------------|---------------------------|------------------------|
| Identity | ✓ (attribute) | ✓ | ✓ |
| Entity Definition | ✓ (attribute) | ✓ | N/A (metadata) |
| Entity Instance | ✓ (attribute + code) | ✓ | ✓ |
| Value | ✓ (i32) | ✓ | ✓ |
| State | ✓ (memref) | ✓ | ✓ |
| Transformation | ✓ (arith + memref) | ✓ | ✓ |
| Constraint | ✓ (scf.if) | ✓ | ✓ |
| Constraint Failure | ✓ (else branch) | ✓ | ✓ |
| SemanticTime | ✓ (index) | ✓ | ✓ |
| Context | ✓ (attribute) | ✓ | N/A (metadata) |
| Observation | ✓ (load + return) | ✓ | ✓ |
| Relationship | ✓ (attribute) | ✓ | N/A (metadata) |
| Provenance | ✓ (attribute) | ✓ | N/A (metadata) |

---

## Representation vs Semantics Distinction

| Layer | What it defines |
|-------|-----------------|
| **Semantic Contract** | What the computation MEANS |
| **Lean Formalization** | What is PROVEN about the meaning |
| **Mojo Implementation** | How the meaning is REALIZED |
| **Reference Executor** | What the CORRECT result is |
| **MLIR Representation** | How the computation is ENCODED |
| **LLVM Lowering** | How the encoding is COMPILED |
| **Execution** | What the compiled code PRODUCES |

The authority flows downward:
```
Semantic Contract → Representation → Execution
```

Not upward:
```
Execution ≠ Semantic Contract
```

---

## Custom Dialect Decision

**No custom SCR dialect required.**

Evidence:
- All 13 semantic concepts are representable with standard MLIR
- Provenance is carried through unregistered attributes
- Constraint failure is representable with scf.if/else
- Multiple entities use separate memref allocations
- Relationships use module attributes

The 6 conditions for introducing a custom dialect (section 18 of milestone)
are not met:
1. ✓ Existing MLIR can express all required properties
2. ✓ No missing genuinely semantic property
3. ✓ All properties preserved through attributes/operations
4. ✗ No failing concrete witness requiring custom extension
5. ✗ No custom extension needed
6. ✗ No custom extension specified
