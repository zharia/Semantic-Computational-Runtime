# Canonical Algebra — Formal Definitions

**Status:** CLOSED — all definitions implemented in `SCRFormal/SCR/Algebra.lean`.

---

## Semantic Field

```
SCR Algebra = (SemanticState, Context, Transformation, Outcome, Observation)
```

Reconciled from: Semantic Field `(E, R, T, C, S, K, M)`, SMM `(C_space, State, Transition, Outcome)`, STC `(C, ρ, ω, δ, ℐ)`.

All six fields collapse into five canonical types: `M` (manifestation) is derived, not foundational.

## Definitions

### Identity (ALG-001)

```
abbrev Identity := EntityId
```

Identity is a string wrapper type. Identity persistence is invariant under value transformation: `node_identity_invariant` proves `{ n with value := v }.id = n.id`.

### SemanticState (ALG-006)

```
abbrev SemanticState := Hypergraph = { nodes : List Entity, edges : List Hyperedge, logical_step : Nat }
```

Well-formedness invariant: `IncidenceWellFormed s` — every edge's role targets must be present in `s.NodeIds`.

### Context (ALG-007)

```
structure Context where
  logical_step : Nat
  label : String
```

Context is ambient, not modified by step failures.

### Transformation (ALG-011)

```
inductive Transformation where
  | graphOp (op : HyperOp)
  | noOp
  | atomicTx (t1 t2 : Transformation)
```

`HyperOp` = `addNode | removeNode | addEdge | removeEdge | updateNodeValue`.

### Outcome (ALG-013, ALG-014)

```
inductive Outcome where
  | ok (state : SemanticState) (ctx : Context)
  | fail (state : SemanticState) (ctx : Context) (reason : String)
```

Two constructors only. `Rejected`, `Inapplicable`, `Undefined` from spec candidate are all subsumed by `.fail` with distinct reason strings.

### Observation (ALG-015)

```
def observeNode (s : SemanticState) (id : EntityId) : Option Value :=
  s.nodes.find? (fun n => n.id = id) |>.map Entity.value
```

Observation is pure: `observation_purity` proves `observeNode s id = observeNode s id`.

## Computational Flow

```
Applicability → Admissibility → Transformation attempt → Outcome → Observation
```

The pipeline is strictly ordered. Admissibility subsumes applicability (conjunction). Outcome always returns a state (success or rollback). Observation is stateless.
