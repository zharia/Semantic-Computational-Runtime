# Counterexample & Falsification Catalog

**Status:** CLOSED — 6 counterexamples formalized in Lean 4.

---

## CX-01: Failure ≠ Successful No-Op

**File:** `SCRFormal/SCR/AlgebraCounterexamples.lean`
**Theorem:** `CX_01_failure_distinguishable_from_noop`
**Axiom profile:** `propext`

Attempt to add a duplicate node produces `.fail`. Successful no-op produces `.ok`. These are distinct outcomes — failure is semantically meaningful and cannot be conflated with success.

**Regression guard:** Any proposal to collapse `.fail` into `.ok` must be rejected.

## CX-02: Dangling Edge Targets Rejected

**File:** `SCRFormal/SCR/AlgebraCounterexamples.lean`
**Theorem:** `CX_02_dangling_edge_rejected`
**Axiom profile:** `propext`

Adding a hyperedge with a role target referencing a nonexistent node is rejected. `checkRolesIncident` enforces referential integrity.

## CX-03: Incident Node Removal Rejected

**File:** `SCRFormal/SCR/AlgebraCounterexamples.lean`
**Theorem:** `CX_03_incident_node_removal_rejected`
**Axiom profile:** `propext`

Removing a node with active incident hyperedges is rejected. `checkNodeFreeOfEdges` enforces referential integrity.

## CX-04: Conflicting Writes Non-Commutative

**File:** `SCRFormal/SCR/AlgebraCounterexamples.lean`
**Theorem:** `CX_04_conflicting_writes_do_not_commute`
**Axiom profile:** `propext`

Ordering of concurrent writes to the same entity is observable. Final state depends on application order.

## CX-05: Trace ≠ Shadow Incomparability

**File:** `SCRFormal/SCR/AlgebraCounterexamples.lean`
**Theorem:** `CX_05_trace_shadow_incomparability`
**Axiom profile:** `propext`

Value-trace sensitivity detects read-write dependence that successor shadows miss. Causality analysis requires trace sensitivity, not just successor observation.

## CX-06: Fan-Out Breaks Functional Subclass

**File:** `SCRFormal/SCR/AlgebraCounterexamples.lean`
**Theorem:** `CX_06_hyperedge_fanout_non_functional`
**Axiom profile:** `propext, Quot.sound`

Multi-endpoint hyperedge fan-out exits the functional composition subclass. Non-functional semantics are required for relational multi-target operations.
