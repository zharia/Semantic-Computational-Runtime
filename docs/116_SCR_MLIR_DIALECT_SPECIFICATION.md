# SCR MLIR Dialect Specification

**Dialect:** `scr`  
**Status:** Normative — derived from closed semantic algebra  
**Version:** 0.2.0  
**Date:** 2026-09-12  
**Authority:** `SCRFormal/SCR/Algebra.lean` (canonical source)


```text
101_Core.md (normative semantic definition, lib/101_Core/)

## -1. Derivation Chain



The SCR semantic library development process flows through four sequential layers:



```text
101_Core.md (normative semantic definition)  
    │
    ▼ defines meaning
Lean-Lang definitions (formal verification, lib/203_Graph/Hypergraph/201_LeanLang/)  
    │
    ▼ proves correctness
MLIR scr dialect (machine-readable semantic definition,  
  lib/203_Graph/IR/mlir/)  
    │
    ▼ represents meaning
Mojo scr_kernel (executable semantic kernel,  
  lib/scr_kernel/)
```

**Derivation Details**:

- **101_Core.md** defines the normative semantic meaning through 24+ conceptual functions (§70-82). This is the authoritative source of truth.
- **Lean-Lang definitions** (`lib/203_Graph/Hypergraph/201_LeanLang/`) encode these definitions as precise Lean types and prove core invariants and well-formedness conditions. This provides machine-checked verification that implementations satisfy the semantic contract.
- **MLIR scr dialect** (`lib/203_Graph/IR/mlir/`) machine-represents the semantic library. 21 operations, 7 opaque types, per-op type verifiers, and the `--scr-verify` cross-op verification pass. This is the canonical machine-readable representation.
- **Mojo scr_kernel** (`lib/scr_kernel/`) provides the executable semantic kernel. 11 `.mojo` files implement the kernel contract with 303 test functions, operating on types defined by the MLIR dialect. This is the runtime execution layer.

**Derivation Flow**:
- Semantic meaning flows **downward** from 101_Core.md through Lean verification, MLIR representation, and Moji execution.
- Each layer adds implementation detail without changing semantic meaning.
- The MLIR dialect is the machine-readable intermediate; Moji is the executable runtime.

**Maintenance**: Changes to any layer require corresponding updates to downstream layers to preserve semantic consistency.

## -1. Function Coverage Matrix
    │
    ▼ defines meaning
MLIR scr dialect (machine-readable semantic definition, 
  lib/203_Graph/IR/mlir/)
    │
    ▼ represents meaning
Mojo scr_kernel (executable semantic kernel, 
  lib/scr_kernel/)
```

## -1. Document Hierarchy

The SCR semantic library follows a four-layer architecture:

```text
101_Core.md (normative semantic definition, lib/101_Core/)
    │
    ▼ defines meaning
Lean-Lang definitions (formal verification, lib/203_Graph/Hypergraph/201_LeanLang/)
    │
    ▼ proves correctness
MLIR scr dialect (machine-readable semantic definition, 
  lib/203_Graph/IR/mlir/)
    │
    ▼ represents meaning
Mojo scr_kernel (executable semantic kernel, 
  lib/scr_kernel/)
```

## -1. Function Coverage Matrix

| P0 Essential Function | MLIR Op | Moji Function | Coverage |
|---|---|---|---|
| `identity.create` | `make_entity_id` | `Entity.__init__` | ✅ Both |
| `identity.resolve` | `make_entity_id` value extraction | `Entity.id` access | ✅ Both |
| `identity.compare` | `!scr.entity_id` string comparison | `Entity.id` comparison | ✅ Both |
| `type.define` | Type system via opaque types | `Value.Variant` definition | ✅ Both |
| `type.validate` | Op verifiers on 9 ops | `NonNegativeConstraint.validate()` | ✅ Both |
| `value.create` | `value_unit`/`value_int`/`value_bool`/`value_real`/`value_text` | `Value.Variant(...)` constructor | ✅ Both |
| `entity.create` | `make_entity` | `Entity.__init__` + `Field.add_entity` | ✅ Both |
| `entity.identify` | `make_entity_id` from entity | `Entity.id` access | ✅ Both |
| `entity.attribute` | *New MLIR op needed* | `Entity.get(property_name)` | ⚠️ Map needed |
| `relationship.create` | `make_hyperedge` | `Field.add_definition` / `Field.add_constraint` | ✅ Both |
| `relationship.connect` | *New MLIR op needed* | `Field.add_relationship` | ⚠️ Map needed |
| `relationship.disconnect` | `remove_edge` op exists | `SemanticField.remove_relationship` | ✅ |
| `relationship.role` | *Via `make_role_binding`* | `SemanticField` role handling | ✅ |
| `hyperedge.create` | `make_hyperedge` op exists | `Field.add_constraint` | ✅ |
| `hyperedge.participant` | *Via `make_role_binding`* | N/A | ✅ MLIR |
| `hyperedge.role` | *Via `make_role_binding`* | N/A | ✅ MLIR |
| `region.create` | `empty` / `make_context` / `step` / `atomic_tx` | `SemanticField.__init__` | ✅ Both |
| `region.select` | *New MLIR op needed* | N/A | ⚠️ Map needed |
| `region.contains` | *New MLIR op needed* | N/A | ⚠️ Map needed |
| `reference.create` | *New MLIR op needed* | N/A | ⚠️ Map needed |
| `reference.resolve` | *New MLIR op needed* | N/A | ⚠️ Map needed |
| `representation.create` | Deferred | N/A | Deferred |
| `representation.convert` | Deferred | N/A | Deferred |
| `pattern.create` | Deferred | N/A | Deferred |
| `pattern.match` | Deferred | N/A | Deferred |
| `transformation.create` | `Transformation` struct in MLIR | `Transformation.__init__` | ✅ Both |
| `transformation.apply` | `step`/`atomic_tx` lowering | `Field.execute(INC/EMIT/SET_INT)` | ✅ Both |
| `operation.define` | 21 ops defined in `SCR.td` | N/A (IR-level) | ✅ MLIR |
| `operation.execute` | `scr-opt` / `--scr-verify` | N/A (runtime) | ✅ MLIR tool |
| `operation.validate` | Op `verify()` methods (9 ops) | N/A (compile-time) | ✅ MLIR |
| `state.create` | `empty` op | `SemanticField.__init__` | ✅ Both |
| `state.observe` | `observe_node` op | `Field.validate()` | ✅ Both |
| `state.transition` | `step`/`atomic_tx` ops | `Field.execute(INC/EMIT)` | ✅ Both |
| `delta.compute` | Deferred | N/A | Deferred |
| `delta.apply` | Deferred | N/A | Deferred |
| `delta.compose` | Deferred | N/A | Deferred |
| `event.create` | *New MLIR op or trace mechanism* | N/A | ⚠️ Map needed |
| `event.emit` | *New MLIR pass or trace* | N/A | ⚠️ Map needed |
| `stream.create` | Deferred | N/A | Deferred |
| `stream.subscribe` | Deferred | N/A | Deferred |
| `stream.transform` | Deferred | N/A | Deferred |
| `temporal.compare` | Context `logical_step` comparison | N/A | ✅ MLIR |
| `temporal.order` | Context `logical_step` ordering | N/A | ✅ MLIR |
| `causal.link` | Deferred | N/A | Deferred |
| `causal.predecessors` | Deferred | N/A | Deferred |
| `provenance.record` | Deferred | N/A | Deferred |
| `provenance.trace` | Deferred | N/A | Deferred |
| `constraint.validate` | Op verifiers | `NonNegativeConstraint.validate()` | ✅ Both |
| `capability.query` | Deferred | N/A | Deferred |
| `capability.require` | Deferred | N/A | Deferred |
| `contract.validate` | Deferred | N/A | Deferred |
| `contract.compose` | Deferred | N/A | Deferred |
| `equivalence.compare` | Deferred | N/A | Deferred (CX-EQV open) |
| `query.select` | Deferred | N/A | Deferred |
| `query.evaluate` | Deferred | N/A | Deferred |
| `observation.record` | `observe_node` + value ops | N/A | ✅ MLIR |
| `resource.require` | Deferred | N/A | Deferred |
| `resource.release` | Deferred | N/A | Deferred |
| `error.create` | Deferred | N/A | Deferred |
| `error.classify` | Deferred | N/A | Deferred |

## -1. Abstraction Levels

| Level | Description | Artifact |
|---|---|---|
| **Semantic Definition** | Core meaning (authoritative) | `101_Core.md` |
| **MLIR Representation** | Machine-readable semantic library | `MLIR scr dialect` |
| **Mojo Implementation** | Executable semantic kernel | `Mojo scr_kernel` |
| **Developer Code** | Application-level semantic functions | User code |

---

---

## 1. Purpose

The `scr` dialect is the MLIR representation of the closed SCR semantic algebra. It is the **sole canonical compiler IR** for SCR semantic operations. All downstream lowering, optimization, and code generation proceeds through this dialect.

The dialect is derived directly from the formal algebra — every type, operation, and verification rule traces to a Lean theorem or definition.

---

## 2. Derivation Source

```
Algebra (Lean 4)          →  MLIR Dialect (scr)
─────────────────────────────────────────────────
Identity (ALG-001)        →  !scr.entity_id
Entity (ALG-002)          →  !scr.entity
Value (ALG-004)           →  !scr.value
Hyperedge (ALG-005)       →  !scr.hyperedge
Hypergraph (ALG-006)      →  !scr.hypergraph
Context (ALG-007)         →  !scr.context
Constraint (ALG-008)      →  verifier passes
Applicability (ALG-009)   →  op verifier (preconditions)
Admissibility (ALG-010)   →  op verifier (preconditions + IncidenceWellFormed)
Transformation (ALG-011)  →  operations (scr.add_node, etc.)
Transition (ALG-012)      →  scr.step
Outcome (ALG-013)         →  result types + error handling
Failure (ALG-014)         →  scr.fail / cf.br on failure successor
Observation (ALG-015)     →  scr.observe_node
Time (ALG-017)            →  !scr.context.logical_step (verified monotonic)
```

---

## 3. Implementation Status

**This section records the gap between normative spec (sections 4–8) and current v0.1.0 build.**

### 3.1 Build Artifacts

| Artifact | Path | Status |
|----------|------|--------|
| TableGen definition | `lib/203_Graph/IR/mlir/SCR.td` | Complete |
| C++ dialect library | `lib/203_Graph/IR/mlir/build/lib/libSCRdialect.a` (9.7 MB) | Compiles clean |
| `scr-opt` tool | `lib/203_Graph/IR/mlir/build/tools/scr-opt` (232 MB) | Functional |
| Lit tests | `lib/203_Graph/IR/mlir/test/basic.mlir` | 6/6 passing (P0 essential functions: state/create/transition/observe, identity/create, entity/create, value/create, relationship/create, constraint/validate) |

### 3.2 Type System — v0.1.0

All 7 types are registered as MLIR **opaque types** (`mlir::OpaqueType` with dialect namespace `"scr"`). They are **not** struct-typed in this build. The opaque representation preserves the type name for verification and lowering while deferring internal layout to a future version.

| Type | Mnemonic | v0.1.0 Representation | Target Representation |
|------|----------|----------------------|----------------------|
| `!scr.entity_id` | `entity_id` | Opaque | Struct (string identity) |
| `!scr.value` | `value` | Opaque | Sum type (unit/bool/int/real/text/seq) |
| `!scr.entity` | `entity` | Opaque | Struct (id, typeName, value, properties) |
| `!scr.role_binding` | `role_binding` | Opaque | Struct (role, target) |
| `!scr.hyperedge` | `hyperedge` | Opaque | Struct (id, edgeType, roles, properties) |
| `!scr.hypergraph` | `hypergraph` | Opaque | Struct (nodes, edges, logicalStep) |
| `!scr.context` | `context` | Opaque | Struct (logicalStep, label) |

### 3.3 Operations — v0.2.0

All 21 operations (including `scr.step`, `scr.return`) compile and roundtrip:
- All operands use `AnyType` (no typed constraints yet).
- No `assemblyFormat` — ops use generic ` "scr.op_name"(...) : (types) -> types ` syntax.
- Mutation ops (`add_node`, `remove_node`, etc.) do NOT have `Pure` trait — MLIR defaults to unknown effects (correct).
- Pure ops (`observe_node`, constructors) retain `[Pure]` trait.
- `scr.step` op added — canonical transition wrapper with region body.
- `scr.return` terminator op added — terminates region bodies.
- ODS-level verifier syntax not supported in MLIR 22.1.8 with custom dialect class — type correctness deferred to future version.

| Operation | Signature | v0.2.0 Notes |
|-----------|-----------|-------------|
| `scr.empty` | `() -> !scr.hypergraph` | Creates empty hypergraph |
| `scr.add_node` | `(!scr.hypergraph, !scr.entity) -> !scr.hypergraph` | Add entity (no Pure) |
| `scr.remove_node` | `(!scr.hypergraph, !scr.entity_id) -> !scr.hypergraph` | Remove entity (no Pure) |
| `scr.add_edge` | `(!scr.hypergraph, !scr.hyperedge) -> !scr.hypergraph` | Add hyperedge (no Pure) |
| `scr.remove_edge` | `(!scr.hypergraph, !scr.entity_id) -> !scr.hypergraph` | Remove hyperedge (no Pure) |
| `scr.update_node_value` | `(!scr.hypergraph, !scr.entity_id, !scr.value) -> !scr.hypergraph` | Update entity value (no Pure) |
| `scr.no_op` | `(!scr.hypergraph, !scr.context) -> (!scr.hypergraph, !scr.context)` | Identity transform (no Pure) |
| `scr.atomic_tx` | `(!scr.hypergraph, !scr.context) -> (!scr.hypergraph, !scr.context)` with region | Transactional composition |
| `scr.step` | `(!scr.hypergraph, !scr.context) -> (!scr.hypergraph, !scr.context)` with region | Canonical transition |
| `scr.observe_node` | `(!scr.hypergraph, !scr.entity_id) -> !scr.value` | Pure observation |
| `scr.make_context` | `(AnyType, AnyType) -> !scr.context` | Create context (Pure) |
| `scr.make_entity` | `(AnyType, AnyType, AnyType, AnyType) -> !scr.entity` | Construct entity (Pure) |
| `scr.make_entity_id` | `(AnyType) -> !scr.entity_id` | Construct identity (Pure) |
| `scr.make_hyperedge` | `(AnyType, AnyType, AnyType, AnyType) -> !scr.hyperedge` | Construct hyperedge (Pure) |
| `scr.make_role_binding` | `(AnyType, AnyType) -> !scr.role_binding` | Construct role binding (Pure) |
| `scr.value_unit` | `() -> !scr.value` | Unit value (Pure) |
| `scr.value_bool` | `(AnyType) -> !scr.value` | Boolean value (Pure) |
| `scr.value_int` | `(AnyType) -> !scr.value` | Integer value (Pure) |
| `scr.value_real` | `(AnyType) -> !scr.value` | Real value (Pure) |
| `scr.value_text` | `(AnyType) -> !scr.value` | Text value (Pure) |
| `scr.return` | `(Variadic<AnyType>) -> ()` | Region terminator |

### 3.4 Known Limitations (v0.2.0)

1. **Opaque types** — no internal layout, no field access ops, no per-variant constructors for `!scr.value`.
2. **No typed operand constraints** — all operands are `AnyType`; ODS verifier syntax not supported in MLIR 22.1.8 with custom dialect class.
3. **No assemblyFormat** — generic syntax only; human-unfriendly.
4. **No verifier passes** — IncidenceWellFormed, TimeMonotonicity, etc. are documented but not enforced.
5. **No canonicalization** — fold patterns from spec not implemented.
6. **No memory effects** — mutation ops have no explicit effect annotations (MLIR defaults to unknown effects, which is correct but imprecise).

---

## 4. Type System (Normative Target)

### 4.1 `!scr.entity_id`

Opaque semantic identity. String-compared. Not a pointer.

**Verification:** None (structural equality via string).

### 4.2 `!scr.value`

Variant sum type. Exactly one active variant.

| Variant | Payload | MLIR Storage |
|---------|---------|-------------|
| `unit` | none | `None` |
| `bool` | `i1` | `IntegerAttr<i1>` |
| `int` | `i64` | `IntegerAttr<i64>` |
| `real` | `f64` | `FloatAttr<f64>` |
| `text` | `String` | `StringAttr` |
| `sequence` | `ArrayAttr<!scr.value>` | recursive |

**Verification:** Exactly one variant active (enforced by ODS).

### 4.3 `!scr.entity`

Semantic entity with persistent identity. Fields: `id`, `typeName`, `value`, `properties`.

**Verification:** `id` is non-empty.

### 4.4 `!scr.role_binding`

Named role pointing to an entity. Fields: `role`, `target`.

### 4.5 `!scr.hyperedge`

Typed semantic relationship. Fields: `id`, `edgeType`, `roles`, `properties`.

**Verification:** At least one role. Role targets are checked at insertion time.

### 4.6 `!scr.hypergraph` — The Core State

Authoritative semantic state. Fields: `nodes`, `edges`, `logicalStep`.

**Verification (IncidenceWellFormed):** Every hyperedge's role targets must reference entities present in `nodes`.

### 4.7 `!scr.context`

Ambient transition metadata. Fields: `logicalStep`, `label`.

---

## 5. Operations (Normative Target)

### 5.1 Hypergraph Operations

#### `scr.add_node`

**Preconditions:** Entity id must not exist in graph.nodes.  
**Postconditions:** New entity present. All existing edges preserved.  
**Time:** Advances logicalStep by 1.  
**Failure:** Returns original graph unchanged (rollback).  
**Formal:** `step (.graphOp (.addNode e)) s c = .ok s' c'` iff `e.id ∉ s.NodeIds`

#### `scr.remove_node`

**Preconditions:** Entity exists. No incident hyperedges.  
**Postconditions:** Entity removed.  
**Time:** Advances logicalStep by 1.  
**Failure:** Returns original graph.  
**Formal:** `step (.graphOp (.removeNode id)) s c = .fail s c reason` iff ∃ edge with target `id`.  
**Counterexample:** `CX_03_incident_node_removal_rejected`

#### `scr.add_edge`

**Preconditions:** Edge id must not exist. All role targets must exist in graph.nodes.  
**Postconditions:** New edge present. IncidenceWellFormed preserved.  
**Time:** Advances logicalStep by 1.  
**Failure:** Returns original graph.  
**Formal:** `step (.graphOp (.addEdge e)) s c = .fail s c reason` iff ∃ role target ∉ `s.NodeIds`.  
**Counterexample:** `CX_02_dangling_edge_rejected`

#### `scr.remove_edge`

**Preconditions:** Edge exists.  
**Postconditions:** Edge removed. Entities preserved.  
**Time:** Advances logicalStep by 1.

#### `scr.update_node_value`

**Preconditions:** Entity exists.  
**Postconditions:** Entity value updated. Identity preserved.  
**Time:** Advances logicalStep by 1.  
**Formal:** `{ n with value := v }.id = n.id`  
**Counterexample:** `CX_04_conflicting_writes_do_not_commute`

### 5.2 Composition Operations

#### `scr.no_op`

**Semantics:** Identity transformation. Advances logicalStep by 1.  
**Formal:** `step .noOp s c = .ok s { c with logical_step := c.logical_step + 1 }`

#### `scr.atomic_tx`

**Semantics:** Transactional atomic composition with region. On failure, entire transaction rolls back.  
**Formal:** `step (.atomicTx t1 t2) s c` — if `step t1 s c = .ok s1 c1` then `step t2 s1 c1`, else `.fail s c reason`.

### 5.3 Observation

#### `scr.observe_node`

**Semantics:** Pure state query. No side effects. No time advancement.  
**Formal:** `observeNode s id` — `observation_purity` proven.  
**Memory effect:** `Pure`.

### 5.4 Transition

#### `scr.step`

**Invariants:**
- `step_deterministic`: Same inputs always produce same outputs.
- `step_advances_time`: On success, `new_ctx.logicalStep ≥ ctx.logicalStep + 1`.
- `step_preserves_time_on_failure`: On failure, time unchanged.
- `step_rollback_on_failure`: On failure, state restored.

---

## 6. Verification Rules (Normative Target)

| Rule | Enforcement | Source |
|------|------------|--------|
| IncidenceWellFormed | Every op returning `!scr.hypergraph` | `SCR.Hypergraph.IncidenceWellFormed` |
| NoDanglingReferences | `scr.add_edge`, `scr.remove_node` | `CX_02`, `CX_03` |
| TimeMonotonicity | All ops returning `!scr.hypergraph` + `!scr.context` | `step_advances_time` |
| TimeInvarianceOnFailure | All ops with failure paths | `step_preserves_time_on_failure` |
| Rollback | `scr.atomic_tx` failure paths | `step_rollback_on_failure` |
| IdentityPreservation | `scr.update_node_value` | `node_identity_invariant` |

---

## 7. Memory Effects (Normative Target)

| Operation | Read | Write | Alloc | Free |
|-----------|------|-------|-------|------|
| `scr.add_node` | `!scr.hypergraph` | `!scr.hypergraph` | — | — |
| `scr.remove_node` | `!scr.hypergraph` | `!scr.hypergraph` | — | — |
| `scr.add_edge` | `!scr.hypergraph` | `!scr.hypergraph` | — | — |
| `scr.remove_edge` | `!scr.hypergraph` | `!scr.hypergraph` | — | — |
| `scr.update_node_value` | `!scr.hypergraph` | `!scr.hypergraph` | — | — |
| `scr.no_op` | `!scr.hypergraph` | `!scr.hypergraph` | — | — |
| `scr.observe_node` | — | — | — | — |

---

## 8. Canonicalization (Normative Target)

| Pattern | Result |
|---------|--------|
| `scr.no_op %g, %ctx` | `%g, %ctx` (with time advanced) |
| `scr.add_node %g, %e` where `%e ∈ %g.nodes` | fold to `scr.fail` |
| `scr.add_edge %g, %e` where `%e.id ∈ %g.edges.ids` | fold to `scr.fail` |
| `scr.update_node_value %g, %id, %old` then `scr.update_node_value %g, %id, %new` | fold to single update |

---

## 9. Example (Generic Syntax — v0.1.0)

```mlir
// Create initial state
%g = "scr.empty"() : () -> !scr.hypergraph

// Create context
%c0 = arith.constant 0 : i64
%id_init = "scr.make_entity_id"(%c0) : (i64) -> !scr.entity_id
%ctx = "scr.make_context"(%c0, %id_init) : (i64, !scr.entity_id) -> !scr.context

// Create entity
%val = "scr.value_int"(%c0) : (i64) -> !scr.value
%tname = "scr.value_text"(%c0) : (i64) -> !scr.value
%props = "scr.value_unit"() : () -> !scr.value
%entity = "scr.make_entity"(%id_init, %tname, %val, %props)
    : (!scr.entity_id, !scr.value, !scr.value, !scr.value) -> !scr.entity

// Add entity to hypergraph
%g1 = "scr.add_node"(%g, %entity)
    : (!scr.hypergraph, !scr.entity) -> !scr.hypergraph

// Observe (pure, no side effects)
%result = "scr.observe_node"(%g1, %id_init)
    : (!scr.hypergraph, !scr.entity_id) -> !scr.value
```
