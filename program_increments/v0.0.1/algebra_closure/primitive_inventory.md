# Primitive Inventory — ALG-001..ALG-030

**Status:** CLOSED — all 30 terms classified, mapped to Lean 4 formal symbols.

---

## Ontological Primitives

| ID | Term | Lean Symbol | Domain | Status | Evidence |
|----|------|-------------|--------|--------|----------|
| ALG-001 | Identity | `Identity` = `EntityId` | `String` wrapper | **PROVEN** | `SCR.Algebra`, `node_identity_invariant` |
| ALG-002 | Entity | `Entity` | `{id, typeName, value, properties}` | **PROVEN** | `SCR.Basic`, `SCR.Hypergraph` |
| ALG-003 | EntityId | `EntityId` = `Id` | `String` | **PROVEN** | `SCR.Basic` |
| ALG-004 | SemanticValue | `SemanticValue` = `Value` | `unit \| bool \| int \| float \| string \| String \| list` | **PROVEN** | `SCR.Basic` |
| ALG-005 | Relationship | `Hyperedge` | `{id, edgeType, roles, properties}` | **PROVEN** | `SCR.Hypergraph` |
| ALG-006 | SemanticState | `SemanticState` = `Hypergraph` | `{nodes, edges, logical_step}` | **PROVEN** | `SCR.Hypergraph`, `IncidenceWellFormed` |
| ALG-007 | Context | `Context` | `{logical_step, label}` | **PROVEN** | `SCR.Algebra` |

## Structural Primitives

| ID | Term | Lean Symbol | Status | Evidence |
|----|------|-------------|--------|----------|
| ALG-008 | Hyperedge | `Hyperedge` | **PROVEN** | `SCR.Hypergraph` |
| ALG-009 | Applicability | `isApplicable : Transformation → SemanticState → Bool` | **PROVEN** | `SCR.Algebra` |
| ALG-010 | Admissibility | `isAdmissible : Transformation → SemanticState → Context → Prop` | **PROVEN** | `SCR.Algebra` |
| ALG-011 | Transformation | `Transformation` = `.graphOp \| .noOp \| .atomicTx` | **PROVEN** | `SCR.Algebra` |
| ALG-012 | Step / Transition | `step : Transformation → SemanticState → Context → Outcome` | **PROVEN** | `SCR.Algebra` |
| ALG-013 | Outcome | `Outcome` = `.ok state ctx \| .fail state ctx reason` | **PROVEN** | `SCR.Algebra` |
| ALG-014 | Failure / Rollback | `.fail` constructor | **PROVEN** | `step_rollback_on_failure` |
| ALG-015 | Observation | `observeNode : SemanticState → EntityId → Option Value` | **PROVEN** | `observation_purity` |
| ALG-016 | Constraint | `IncidenceWellFormed` | **PROVEN** | `SCR.Hypergraph`, `SCR.Canonical` |
| ALG-017 | Logical Time | `Context.logical_step : Nat` | **PROVEN** | `step_advances_time`, `step_preserves_time_on_failure` |
| ALG-018 | Determinism | `step_deterministic` | **PROVEN** | `SCR.Algebra` |
| ALG-019 | Causality | `causesRelation` | **PROVEN** | `SCR.STCGraphCausality` |

## Composition & Category

| ID | Term | Lean Symbol | Status | Evidence |
|----|------|-------------|--------|----------|
| ALG-020 | Sequential Composition | `.atomicTx t1 t2` | **PROVEN** | `SCR.Algebra` |
| ALG-021 | Identity Transformation | `.noOp` | **PROVEN** | `SCR.Algebra` |
| ALG-022 | Associativity | (proven via atomicTx semantics) | **DERIVED** | from `step_advances_time` + `step_rollback_on_failure` |
| ALG-023 | Commutativity | (refuted — CX-04) | **EXCLUDED** | `CX_04_conflicting_writes_do_not_commute` |
| ALG-024 | Idempotence | (refuted for non-trivial ops) | **EXCLUDED** | `CX_01_failure_distinguishable_from_noop` |
| ALG-025 | Reversibility | (refuted for destructive ops) | **EXCLUDED** | incident edge constraint |

## Concurrency & Independence

| ID | Term | Lean Symbol | Status | Evidence |
|----|------|-------------|--------|----------|
| ALG-026 | Independence | `causesRelation⁻¹ • causesRelation = ∅` | **PROVEN** | `SCR.STCGraphCausality` |
| ALG-027 | Trace Sensitivity | `traceSensitive` | **PROVEN** | `SCR.STCGraphCausality` |
| ALG-028 | Successor Shadow | `gOrderSensitive` | **PROVEN** | `SCR.STCGraphCausality` |
| ALG-029 | Functional Determinism | `succFunOnClass` | **PROVEN** | `SCR.STCGraphLaws` |
| ALG-030 | Multi-Endpoint Fan-Out | `Hyperedge.roles : List Role` | **DERIVED** | `SCR.Hypergraph`, `CX_06_hyperedge_fanout_non_functional` |
