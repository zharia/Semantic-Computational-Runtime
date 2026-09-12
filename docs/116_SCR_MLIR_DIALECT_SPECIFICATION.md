# SCR MLIR Dialect Specification

**Dialect:** `scr`  
**Status:** Normative — derived from closed semantic algebra  
**Version:** 0.1.0  
**Date:** 2026-09-12  
**Authority:** `SCRFormal/SCR/Algebra.lean` (canonical source)

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

## 3. Type System

### 3.1 `!scr.entity_id`

Opaque semantic identity. String-compared. Not a pointer.

```mlir
// Usage
%id = scr.entity_id "node_42" : !scr.entity_id
```

**Verification:** None (structural equality via string).

### 3.2 `!scr.value`

Variant sum type. Exactly one active variant.

| Variant | Payload | MLIR Storage |
|---------|---------|-------------|
| `unit` | none | `None` |
| `bool` | `i1` | `IntegerAttr<i1>` |
| `int` | `i64` (arbitrary-precision in semantics) | `IntegerAttr<i64>` |
| `real` | `f64` | `FloatAttr<f64>` |
| `text` | `String` | `StringAttr` |
| `sequence` | `ArrayAttr<!scr.value>` | recursive |

```mlir
%v_unit = scr.value.unit : !scr.value
%v_bool = scr.value.bool true : !scr.value
%v_int = scr.value.int 42 : !scr.value
%v_text = scr.value.text "hello" : !scr.value
%v_seq = scr.value.sequence (%v_int, %v_text) : !scr.value
```

**Verification:** Exactly one variant active (enforced by ODS).

### 3.3 `!scr.entity`

Semantic entity with persistent identity.

```mlir
!scr.entity = !scr.struct<{
  id: !scr.entity_id,
  typeName: String,
  value: !scr.value,
  properties: !scr.dictionary
}>
```

```mlir
%entity = scr.make_entity %id, %typeName, %value, %props
    : (!scr.entity_id, String, !scr.value, !scr.dictionary) -> !scr.entity
```

**Verification:** `id` is non-empty.

### 3.4 `!scr.role_binding`

Named role pointing to an entity.

```mlir
!scr.role_binding = !scr.struct<{
  role: String,
  target: !scr.entity_id
}>
```

### 3.5 `!scr.hyperedge`

Typed semantic relationship.

```mlir
!scr.hyperedge = !scr.struct<{
  id: String,
  edgeType: String,
  roles: ArrayAttr<!scr.role_binding>,
  properties: !scr.dictionary
}>
```

**Verification:** At least one role. Role targets are checked at insertion time.

### 3.6 `!scr.hypergraph` — The Core State

Authoritative semantic state. This is the primary data type flowing through SCR operations.

```mlir
!scr.hypergraph = !scr.struct<{
  nodes: ArrayAttr<!scr.entity>,
  edges: ArrayAttr<!scr.hyperedge>,
  logicalStep: Index
}>
```

**Verification (IncidenceWellFormed):** Every hyperedge's role targets must reference entities present in `nodes`. Checked on every operation that modifies the hypergraph.

### 3.7 `!scr.context`

Ambient transition metadata.

```mlir
!scr.context = !scr.struct<{
  logicalStep: Index,
  label: String
}>
```

---

## 4. Operations

### 4.1 Hypergraph Operations (ALG-011 → HyperOp)

Each maps 1:1 to a `HyperOp` constructor.

#### `scr.add_node`

```mlir
scr.add_node %graph, %entity : !scr.hypergraph, !scr.entity
    -> !scr.hypergraph
    attrs { /* optional: allow_overwrite = false */ }
```

**Preconditions (ALG-009):** Entity id must not exist in `graph.nodes`.  
**Postconditions:** New entity present in result. All existing edges preserved.  
**Time:** Advances `logicalStep` by 1.  
**Failure:** Returns original `%graph` unchanged (rollback, ALG-014).  
**Formal:** `step (.graphOp (.addNode e)) s c = .ok s' c'` iff `e.id ∉ s.NodeIds`

#### `scr.remove_node`

```mlir
scr.remove_node %graph, %id : !scr.hypergraph, !scr.entity_id
    -> !scr.hypergraph
```

**Preconditions:** Entity exists. No incident hyperedges (`checkNodeFreeOfEdges`).  
**Postconditions:** Entity removed. All edges referencing it would be dangling — rejected.  
**Time:** Advances `logicalStep` by 1.  
**Failure:** Returns original `%graph`.  
**Formal:** `step (.graphOp (.removeNode id)) s c = .fail s c reason` iff ∃ edge with target `id`.  
**Counterexample:** `CX_03_incident_node_removal_rejected`

#### `scr.add_edge`

```mlir
scr.add_edge %graph, %edge : !scr.hypergraph, !scr.hyperedge
    -> !scr.hypergraph
```

**Preconditions:** Edge id must not exist. All role targets must exist in `graph.nodes` (`checkRolesIncident`).  
**Postconditions:** New edge present. IncidenceWellFormed preserved.  
**Time:** Advances `logicalStep` by 1.  
**Failure:** Returns original `%graph`.  
**Formal:** `step (.graphOp (.addEdge e)) s c = .fail s c reason` iff ∃ role target ∉ `s.NodeIds`.  
**Counterexample:** `CX_02_dangling_edge_rejected`

#### `scr.remove_edge`

```mlir
scr.remove_edge %graph, %edge_id : !scr.hypergraph, String
    -> !scr.hypergraph
```

**Preconditions:** Edge exists.  
**Postconditions:** Edge removed. Entities preserved.  
**Time:** Advances `logicalStep` by 1.

#### `scr.update_node_value`

```mlir
scr.update_node_value %graph, %id, %value
    : !scr.hypergraph, !scr.entity_id, !scr.value
    -> !scr.hypergraph
```

**Preconditions:** Entity exists.  
**Postconditions:** Entity value updated. Identity preserved (`node_identity_invariant`).  
**Time:** Advances `logicalStep` by 1.  
**Formal:** `{ n with value := v }.id = n.id`  
**Counterexample:** `CX_04_conflicting_writes_do_not_commute` — ordering matters.

### 4.2 Composition Operations (ALG-020, ALG-021)

#### `scr.no_op`

```mlir
scr.no_op %graph, %ctx : !scr.hypergraph, !scr.context
    -> !scr.hypergraph, !scr.context
```

**Semantics:** Identity transformation. Returns input unchanged. Advances `logicalStep` by 1.  
**Formal:** `step .noOp s c = .ok s { c with logical_step := c.logical_step + 1 }`

#### `scr.atomic_tx`

```mlir
scr.atomic_tx %graph, %ctx {
    scr.add_node %g1, %entity ...
    scr.update_node_value %g2, %id, %value ...
} : !scr.hypergraph, !scr.context
    -> !scr.hypergraph, !scr.context
```

**Semantics:** Transactional atomic composition. Executes region sequentially. On failure anywhere in the region, entire transaction rolls back to pre-tx state (`step_rollback_on_failure`).  
**Formal:** `step (.atomicTx t1 t2) s c` — if `step t1 s c = .ok s1 c1` then `step t2 s1 c1`, else `.fail s c reason`.

### 4.3 Observation (ALG-015)

#### `scr.observe_node`

```mlir
%value = scr.observe_node %graph, %id
    : !scr.hypergraph, !scr.entity_id -> !scr.value
```

**Semantics:** Pure state query. No side effects. No time advancement.  
**Formal:** `observeNode s id` — `observation_purity` proven.  
**Memory effect:** `Pure` (no read/write on `!scr.hypergraph`).

### 4.4 Transition (ALG-012)

#### `scr.step`

The canonical transition operator. Wraps any transformation with context update.

```mlir
%new_graph, %new_ctx = scr.step %graph, %ctx {
    // any scr operation or atomic_tx
} : !scr.hypergraph, !scr.context
    -> !scr.hypergraph, !scr.context
```

**Invariants:**
- `step_deterministic`: Same inputs always produce same outputs.
- `step_advances_time`: On success, `new_ctx.logicalStep ≥ ctx.logicalStep + 1`.
- `step_preserves_time_on_failure`: On failure, `new_ctx.logicalStep = ctx.logicalStep`.
- `step_rollback_on_failure`: On failure, `new_graph = graph` and `new_ctx = ctx`.

---

## 5. Verification Rules

### 5.1 IncidenceWellFormed (Invariant)

Every hypergraph state must satisfy:

```
∀ e ∈ edges, ∀ r ∈ e.roles, r.target ∈ nodes.id
```

**Enforced on:** Every operation that returns `!scr.hypergraph`.  
**Source:** `SCR.Hypergraph.IncidenceWellFormed`

### 5.2 NoDanglingReferences

No hyperedge may reference an entity that does not exist.

**Enforced on:** `scr.add_edge` (precondition), `scr.remove_node` (postcondition).  
**Source:** `CX_02_dangling_edge_rejected`, `CX_03_incident_node_removal_rejected`

### 5.3 TimeMonotonicity

On successful operations: `result.logicalStep > input.logicalStep`.

**Enforced on:** All operations returning `!scr.hypergraph` + `!scr.context`.  
**Source:** `step_advances_time`

### 5.4 TimeInvarianceOnFailure

On failed operations: `result.logicalStep = input.logicalStep`.

**Enforced on:** All operations with failure paths.  
**Source:** `step_preserves_time_on_failure`

### 5.5 Rollback

Failed operations return the pre-step state exactly.

**Enforced on:** `scr.atomic_tx` failure paths.  
**Source:** `step_rollback_on_failure`

### 5.6 IdentityPreservation

`scr.update_node_value` does not change entity id.

**Enforced on:** `scr.update_node_value` postcondition.  
**Source:** `node_identity_invariant`

---

## 6. Memory Effects

| Operation | Read | Write | Alloc | Free |
|-----------|------|-------|-------|------|
| `scr.add_node` | `!scr.hypergraph` | `!scr.hypergraph` | — | — |
| `scr.remove_node` | `!scr.hypergraph` | `!scr.hypergraph` | — | — |
| `scr.add_edge` | `!scr.hypergraph` | `!scr.hypergraph` | — | — |
| `scr.remove_edge` | `!scr.hypergraph` | `!scr.hypergraph` | — | — |
| `scr.update_node_value` | `!scr.hypergraph` | `!scr.hypergraph` | — | — |
| `scr.no_op` | `!scr.hypergraph` | `!scr.hypergraph` | — | — |
| `scr.observe_node` | — | — | — | — |

All mutation operations read+write `!scr.hypergraph`. `scr.observe_node` is `Pure`.

---

## 7. Canonicalization

| Pattern | Result |
|---------|--------|
| `scr.no_op %g, %ctx` | `%g, %ctx` (with time advanced) |
| `scr.add_node %g, %e` where `%e ∈ %g.nodes` | fold to `scr.fail` |
| `scr.add_edge %g, %e` where `%e.id ∈ %g.edges.ids` | fold to `scr.fail` |
| `scr.update_node_value %g, %id, %old_val` then `scr.update_node_value %g, %id, %new_val` | fold to single `scr.update_node_value %g, %id, %new_val` |

---

## 8. Example

```mlir
// Create initial state
%empty = scr.empty : !scr.hypergraph
%ctx = scr.context 0, "init" : !scr.context

// Add entities
%id_a = scr.entity_id "a" : !scr.entity_id
%val_a = scr.value.int 1 : !scr.value
%entity_a = scr.make_entity %id_a, "Counter", %val_a, {} : !scr.entity
%g1, %c1 = scr.step %empty, %ctx {
    %g1_inner = scr.add_node %empty, %entity_a : !scr.hypergraph, !scr.entity -> !scr.hypergraph
    scr.yield %g1_inner : !scr.hypergraph
} : !scr.hypergraph, !scr.context -> !scr.hypergraph, !scr.context

// Update value
%new_val = scr.value.int 2 : !scr.value
%g2, %c2 = scr.step %g1, %c1 {
    %g2_inner = scr.update_node_value %g1, %id_a, %new_val
        : !scr.hypergraph, !scr.entity_id, !scr.value -> !scr.hypergraph
    scr.yield %g2_inner : !scr.hypergraph
} : !scr.hypergraph, !scr.context -> !scr.hypergraph, !scr.context

// Observe (pure, no side effects)
%result = scr.observe_node %g2, %id_a
    : !scr.hypergraph, !scr.entity_id -> !scr.value
```
