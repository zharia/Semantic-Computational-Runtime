# Terminology Reconciliation

**Status:** CLOSED — all historical collisions resolved.

---

## Resolved Collisions

| Term | Legacy Meanings | Canonical Resolution |
|------|----------------|---------------------|
| State | SMM state, STC state, Hypergraph state | `SemanticState` = `Hypergraph` |
| Context | SMM context, STC context | `Context` = `{logical_step, label}` |
| Transformation | STC transformation, SMM transition | `Transformation` (STC syntax) / `step` (SMM semantics) |
| Outcome | SMM outcome, STC outcome | `Outcome` = `.ok \| .fail` |
| Constraint | SMM constraint, STC incidence well-formedness | `isAdmissible` combines applicability + `IncidenceWellFormed` |
| Observation | SMM observation | `observeNode` (pure function) |
| Time | STC logical_step, SMM step counter | `Context.logical_step : Nat` |
| Causality | STC causesRelation, SMM causal ordering | `causesRelation` (from STC) |
| Equivalence | Semantic equivalence, observational equivalence | Not collapsed — distinct concepts |
| Identity | Entity identity, identifier | `Identity` = `EntityId` (string wrapper) |
| Manifestation | SMM manifestation, derived projection | Derived — not a foundational type |

## Not-Equals (Maintained)

```
Specification ≠ Implementation
Status ≠ Specification
Representation ≠ Concept
Provider ≠ Semantic Authority
Backend ≠ Semantic Meaning
Filesystem ≠ Semantic Architecture
```

## Canonical Usage

In all subsequent SCR documentation and code:
- Use `SemanticState` for the authoritative state (not "state space", not "graph state").
- Use `Context` for ambient metadata (not "execution context", not "environment").
- Use `Transformation` for intentional transformations (not "operation", not "action").
- Use `Outcome` for transition results (not "result", not "response").
- Use `step` for the canonical transition function (not "apply", not "execute").
- Use `observeNode` for state queries (not "read", not "get").
