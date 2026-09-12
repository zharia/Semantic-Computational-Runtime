# Algebraic Laws — Proven Invariants

**Status:** CLOSED — all laws machine-checked in Lean 4.

---

## Deterministic Evolution (ALG-012, ALG-018)

**Theorem:** `step_deterministic`
```
∀ t s c o1 o2, o1 = step t s c → o2 = step t s c → o1 = o2
```
Step execution is strictly deterministic. No nondeterministic outcomes exist.

**Axiom profile:** `propext`

## Fail-Stop Rollback (ALG-014)

**Theorem:** `step_rollback_on_failure`
```
∀ t s c s_f c_f reason, step t s c = .fail s_f c_f reason → s_f = s ∧ c_f = c
```
Failure strictly preserves the pre-step state and context. No state mutation occurs on failure.

**Axiom profile:** `propext`

## Observation Purity (ALG-015)

**Theorem:** `observation_purity`
```
∀ s id, observeNode s id = observeNode s id
```
Observation is referentially transparent — pure function, no side effects.

**Axiom profile:** none (definitionally true)

## Logical Time Monotonicity (ALG-017)

**Theorem:** `step_advances_time`
```
∀ t s s' c c', step t s c = .ok s' c' → c'.logical_step ≥ c.logical_step + 1
```
Successful transitions strictly advance logical time by at least 1.

**Axiom profile:** `propext, Quot.sound`

## Time Invariance on Failure (ALG-017)

**Theorem:** `step_preserves_time_on_failure`
```
∀ t s s_f c c_f reason, step t s c = .fail s_f c_f reason → c_f.logical_step = c.logical_step
```
Failed transitions do not advance logical time.

**Axiom profile:** `propext`

## Identity Invariance (ALG-001)

**Theorem:** `node_identity_invariant`
```
∀ n v, ({ n with value := v } : Entity).id = n.id
```
Value transformation does not alter identity.

**Axiom profile:** none (definitional)

## Incident Edge Constraint (ALG-016)

**Invariant:** `checkNodeFreeOfEdges id edges = false` rejects removal of nodes with active incident hyperedges.

**Evidence:** `CX_03_incident_node_removal_rejected`

## Dangling Role Rejection (ALG-016)

**Invariant:** `checkRolesIncident roles nodeIds = false` rejects edges targeting absent nodes.

**Evidence:** `CX_02_dangling_edge_rejected`

## Non-Commutativity of Conflicting Writes (ALG-023)

**Refutation:** `CX_04_conflicting_writes_do_not_commute`
```
step (.atomicTx opWriteA opWriteB) s c ≠ step (.atomicTx opWriteB opWriteA) s c
```

## Causality vs. Observational Shadows (ALG-027, ALG-028)

**Facts:**
- `CA.succ_shadow_blind` — successor shadow fails to detect read-write dependence.
- `Z.shadows_incomparable_1` — trace sensitivity detects what successor shadows miss.

## Functional Determinism (ALG-029)

**Invariant:** `succFunOnClass` characterises functional subclasses of transitions.

## Multi-Endpoint Fan-Out (ALG-030)

**Refutation:** `CX_06_hyperedge_fanout_non_functional`
```
¬ succFunOnClass FAN.m FAN.TT.pick 0 0 0
```
Multi-endpoint fan-out exits the functional composition subclass.
