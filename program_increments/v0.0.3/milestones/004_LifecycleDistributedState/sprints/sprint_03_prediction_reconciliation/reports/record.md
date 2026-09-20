# Sprint 003 Record: Prediction & Reconciliation Semantics

## 1. Objective

Define the SCR prediction/reconciliation semantic family: PredictedState, Reconciliation, Rollback, Replay, PredictionInput, AuthorityUpdate. Each definition derives from O3DE Multiplayer prediction/reconciliation research and GGPO-style rollback netcode, generalised beyond games to robotics, distributed-simulation, and digital-twins. Mechanism (rollback + resimulate) is explicitly separated from semantic meaning (speculative state advancement and correction).

## 2. Scope & Boundaries

### 2.1 What This Sprint Covers

Six core prediction/reconciliation semantic concepts:

| Concept | Purpose |
|---------|---------|
| **PredictedState** | Client-side speculative state advancement before authority confirmation |
| **Reconciliation** | Process of correcting predicted state when authority diverges |
| **Rollback** | Reverting to last known authoritative state and resimulating |
| **Replay** | Re-executing recorded inputs to reconstruct state |
| **PredictionInput** | Input used for local prediction |
| **AuthorityUpdate** | State correction from authority |

### 2.2 What This Sprint Does NOT Cover

- Authority and ownership semantics (Sprint 02 — foundational)
- Temporal identity and state ownership model (Sprint 04)
- Transport-layer protocols (explicitly separated)
- Provider-specific implementations (GGPO, O3DE NetworkPrediction are provider-specific, not SCR semantic)
- Determinism requirements for specific providers (provider concern)

### 2.3 Relationship to M004 Invariants

All definitions must satisfy M004's four formal invariants:

1. Authority transitions are explicit
2. **Prediction does not silently overwrite authoritative state**
3. Replicated state has defined ownership
4. **Time ordering is preserved across distributed observations**

### 2.4 Relationship to Sprint 02

Sprint 02 defined Authority, Ownership, Replication, Observation, RemoteOperation. Sprint 03 builds on Authority and Replication:
- Prediction requires understanding Authority (who is the source of truth)
- Reconciliation requires understanding Replication (how authoritative state arrives)
- AuthorityUpdate is a specific form of Replication (authority → replica with correction semantics)

## 3. Research Sources

### 3.1 O3DE Multiplayer Prediction & Reconciliation

O3DE Multiplayer Gem provides:
- **Local prediction and backwards reconciliation ("rollback")** as first-class features
- `IsPredictable` flag on NetworkProperties: Autonomous role can predict locally even if ReplicateFrom=Authority
- `IsRewindable` flag on NetworkProperties: historic values recorded per network tick for rollback/reconciliation
- Network Input: frame-stamped input from Autonomous to Authority. Authority rewinds before processing to maintain consistency.
- **Server-authoritative asynchronous multiplayer** — server is authoritative, clients predict

**Key O3DE insight:** Prediction/reconciliation is a *strategy*, not a semantic primitive. O3DE conflates "can predict" (a permission) with "is predicting" (an action) with "reconciling" (a correction). SCR separates these into distinct semantic concepts: PredictionInput (permission + data), PredictedState (speculative advancement), Reconciliation (correction process), Rollback (mechanism).

### 3.2 GGPO-Style Rollback Netcode

GGPO (Good Game, Peace Out, 2006) established the foundational rollback algorithm:

- **Core pattern:** Each peer predicts the remote player will repeat their last input and simulates immediately. When the real input arrives later, the simulation rolls back to the predicted frame, applies the corrected input, and fast-forwards to the present.
- **Deterministic requirement:** Same inputs in, same state out — every single time. If determinism breaks for one entity on one frame, every peer's prediction silently diverges.
- **State capture:** Every frame, the entire game state is recorded in a buffer. Buffer depth is typically 8–12 frames.
- **Deterministic core + visual shell:** Visuals (meshes, animation, VFX, audio, cameras) are not rolled back. They follow the corrected state after rollback.
- **Cost:** CPU (resimulating up to ~8 frames per tick). For 300ms connection, expect ~22 frames of re-simulation.
- **Input redundancy:** Inputs are sent with redundancy (typically 3–8 frames) so packet loss doesn't cause desync.

**Key GGPO insight:** Rollback is a *mechanism* (restore state + replay forward). The *semantic* concept is Reconciliation — the process of correcting predicted state. Rollback is one implementation strategy for Reconciliation. SCR captures the semantic meaning, not the mechanism.

### 3.3 Unity Netcode for Entities Prediction

Unity's approach provides additional insight:
- Client runs the same simulation code as the server for predicted entities
- On receiving server snapshot: apply authoritative state, then resimulate from oldest applied tick to current tick ("rollback")
- `PredictedSimulationSystemGroup` runs fixed-step deterministic simulation on both client and server
- `GhostPredictionSmoothingSystem` reconciles and reduces errors over time
- Prediction is entity-scoped: only predicted entities (local player) are resimulated

**Key Unity insight:** Prediction is entity-scoped, not world-scoped. SCR PredictedState captures this: prediction applies to specific entities, not the entire world state.

### 3.4 Client-Side Prediction & Server Reconciliation (General)

The canonical pattern across networked game engines:

1. **Client-side prediction:** Client doesn't wait for server. Immediately simulates result locally using same game logic as server.
2. **Server reconciliation:** When server sends authoritative state, client compares to prediction. If diverged: correct to server's version and replay inputs since divergence.
3. **Input validation:** Server validates every input. Never trust the client.
4. **Dead reckoning:** For other players' characters, extrapolate from last known velocity/direction.

**Key general insight:** The semantic distinction is between *speculative state* (what the client thinks is true) and *authoritative state* (what the server says is true). Reconciliation is the semantic operation of resolving this distinction.

## 4. SCR Semantic Definitions

### 4.1 PredictedState

```yaml
concept: PredictedState
source: O3DE Multiplayer, GGPO rollback netcode, Unity Netcode for Entities
source_terminology: >
  O3DE: IsPredictable NetworkProperty + Autonomous role prediction;
  GGPO: predicted frame state; Unity: PredictedSimulationGroup state
scr_interpretation: >
  PredictedState is the client-side speculative state advancement before
  authority confirmation. A PredictedState represents the client's best
  estimate of what the authoritative state will become, based on local
  input application and simulation. PredictedState is always provisional —
  it MAY be confirmed, corrected, or discarded when authoritative state
  arrives. PredictedState does NOT modify authoritative state; it exists
  only on the predicting host. PredictedState applies to specific entities
  and properties, not the entire world state.
differences: >
  O3DE conflates prediction permission (IsPredictable flag) with prediction
  action (Autonomous role modifying properties locally). O3DE Predictable
  properties are defined at compile time per component; SCR PredictedState
  is a runtime semantic relationship between client, entity, and authority.
  GGPO captures entire frame state for rollback; SCR PredictedState is
  scoped to specific entities and properties — world-level state capture
  is a provider optimization, not a semantic requirement. Unity scopes
  prediction to PredictedSimulationSystemGroup; SCR scopes prediction to
  entity-property pairs with declared prediction scope. O3DE "Autonomous"
  implies prediction permission; SCR PredictedState requires explicit
  declaration of which entities are prediction-eligible.
invariants:
  - PRED-INV-001: Prediction MUST NOT modify authoritative state. PredictedState exists only on the predicting host.
  - PRED-INV-004: PredictedState MUST declare its prediction scope: which entities, which properties, which host.
  - PRED-INV-005: PredictedState MUST be provisional. All PredictedStates are subject to correction or discard.
  - PRED-INV-006: PredictedState MUST record provenance: predicting host, entity, properties, input that produced it, timestamp.
  - PRED-INV-007: Multiple PredictedStates MAY exist for the same entity on different hosts. They are independent.
```

### 4.2 Reconciliation

```yaml
concept: Reconciliation
source: O3DE Multiplayer, GGPO rollback netcode, Unity Netcode for Entities
source_terminology: >
  O3DE: backwards reconciliation ("rollback"); GGPO: rollback + resimulate;
  Unity: prediction correction + GhostPredictionSmoothingSystem
scr_interpretation: >
  Reconciliation is the semantic process of correcting predicted state when
  authority diverges. Reconciliation occurs when a host receives authoritative
  state that conflicts with its PredictedState. The reconciliation process:
  (1) identifies the divergence point, (2) applies authoritative state at
  divergence point, (3) re-executes simulation from divergence point to
  present using recorded inputs. Reconciliation preserves causal ordering —
  the corrected state must be causally consistent with the authoritative
  timeline. Reconciliation is a defined semantic operation, not an ad-hoc
  correction.
differences: >
  O3DE uses "backwards reconciliation" as a single term covering the entire
  correction process. SCR separates Reconciliation (semantic process) from
  Rollback (mechanism) and Replay (re-execution). O3DE reconciliation is
  triggered by authority update arriving; SCR Reconciliation MAY also be
  triggered by prediction timeout, confidence threshold, or explicit
  correction request. GGPO treats rollback as the primary operation;
  SCR treats rollback as one possible mechanism for Reconciliation.
  Unity's GhostPredictionSmoothingSystem blends corrections over time;
  SCR Reconciliation is discrete — the semantic operation completes or
  does not. Smoothing is a presentation concern.
invariants:
  - PRED-INV-002: Reconciliation MUST preserve causal ordering. The corrected state must be causally consistent with the authoritative timeline.
  - PRED-INV-008: Reconciliation MUST identify the divergence point — the last state where prediction and authority agreed.
  - PRED-INV-009: Reconciliation MUST apply authoritative state at the divergence point before re-executing simulation.
  - PRED-INV-010: Reconciliation MUST record provenance: divergence point, authoritative state applied, inputs replayed, host, timestamp.
  - PRED-INV-011: Reconciliation MAY be triggered by: authority update arrival, prediction timeout, confidence threshold, explicit correction request.
  - PRED-INV-012: Reconciliation completion MUST produce a state that is causally consistent with the authoritative timeline up to the reconciliation point.
```

### 4.3 Rollback

```yaml
concept: Rollback
source: GGPO rollback netcode, O3DE Multiplayer, Unity Netcode for Entities
source_terminology: >
  GGPO: rollback; O3DE: backwards reconciliation ("rollback");
  Unity: rollback in PredictedSimulationSystemGroup
scr_interpretation: >
  Rollback is the provider mechanism of reverting to a last known
  authoritative state and resimulating forward. Rollback is one
  implementation strategy for Reconciliation — the semantic process.
  Rollback requires: (1) a recorded history of authoritative states,
  (2) deterministic simulation (same inputs → same state), (3) a
  buffer of recorded inputs since the rollback point. Rollback is a
  mechanical operation: restore state snapshot, replay inputs forward.
  The semantic meaning is Reconciliation; Rollback is how it is achieved.
differences: >
  GGPO treats rollback as the foundational concept — "rollback netcode."
  SCR treats Rollback as a provider mechanism, subordinate to the
  semantic concept of Reconciliation. O3DE uses "rollback" as shorthand
  for "backwards reconciliation"; SCR distinguishes the mechanism
  (Rollback) from the process (Reconciliation) from the result
  (corrected PredictedState). GGPO requires deterministic simulation
  as a hard constraint; SCR acknowledges determinism as a provider
  requirement for Rollback but separates it from the semantic contract.
  A provider MAY implement Reconciliation without rollback (e.g., by
  discarding PredictedState and waiting for fresh authoritative state).
  Rollback is the most common mechanism but not the only one.
invariants:
  - PRED-INV-003: Rollback MUST restore to a valid historical state. The rollback point MUST be a state that was previously confirmed as authoritative.
  - PRED-INV-013: Rollback requires recorded state history. A host MUST NOT rollback to a state it has not previously confirmed.
  - PRED-INV-014: Rollback is a provider mechanism, not a semantic concept. Reconciliation is the semantic operation; Rollback is one implementation.
  - PRED-INV-015: Rollback MAY be scoped to specific entities (entity-level rollback) or to entire world state (world-level rollback). Scope is a provider choice.
  - PRED-INV-016: Rollback MUST NOT discard unsimulated inputs. All inputs received after the rollback point MUST be preserved for re-simulation.
```

### 4.4 Replay

```yaml
concept: Replay
source: GGPO rollback netcode, O3DE Multiplayer
source_terminology: >
  GGPO: resimulate / fast-forward; O3DE: rewind + resimulate;
  Unity: PredictedSimulationSystemGroup re-execution
scr_interpretation: >
  Replay is the semantic operation of re-executing recorded inputs to
  reconstruct state. Replay follows Rollback (or any state restoration)
  to advance from the restored state to the present. Replay requires
  deterministic simulation — the same inputs applied to the same state
  MUST produce the same output. Replay is distinct from initial
  simulation: initial simulation applies inputs for the first time;
  Replay re-applies previously executed inputs. Replay preserves
  temporal ordering — inputs are re-executed in the same sequence as
  original execution.
differences: >
  GGPO calls this "resimulate" or "fast-forward." O3DE calls it
  "resimulate" after rewind. SCR Replay captures the semantic meaning:
  re-executing recorded inputs to reconstruct state. The term "replay"
  is chosen over "resimulate" to emphasise that this is re-execution
  of known inputs, not a new simulation. Replay is the mechanism by
  which Reconciliation achieves temporal advancement after state
  restoration. A provider MAY implement Reconciliation without explicit
  Replay if it can directly compute the corrected state (e.g., by
  discarding all predicted state and accepting current authoritative
  state). Replay is the most common mechanism for temporal advancement.
invariants:
  - PRED-INV-017: Replay MUST preserve temporal ordering. Inputs are re-executed in the same sequence as original execution.
  - PRED-INV-018: Replay requires deterministic simulation. Same inputs applied to same state MUST produce same output.
  - PRED-INV-019: Replay MUST NOT invent inputs. Only previously recorded inputs MAY be replayed.
  - PRED-INV-020: Replay MUST record provenance: replay start state, inputs replayed, replay end state, host, timestamp.
  - PRED-INV-021: Replay MAY be scoped to specific entities or to entire world state. Scope matches the Rollback scope.
```

### 4.5 PredictionInput

```yaml
concept: PredictionInput
source: O3DE Multiplayer, GGPO rollback netcode, Unity Netcode for Entities
source_terminology: >
  O3DE: Network Input (frame-stamped input from Autonomous to Authority);
  GGPO: local + predicted remote input per frame;
  Unity: input data in PredictedSimulationGroup
scr_interpretation: >
  PredictionInput is the input used for local prediction. PredictionInput
  carries two distinct semantic roles: (1) the input that produced a
  PredictedState on the predicting host, and (2) the input transmitted
  to the authoritative host for validation and execution. PredictionInput
  is always timestamped — it belongs to a specific simulation tick.
  PredictionInput MAY be confirmed (authority executed it), rejected
  (authority discarded it), or pending (authority has not yet received
  it). The semantic meaning of PredictionInput is "this input, at this
  time, produced this predicted result" — independent of whether the
  authority agrees.
differences: >
  O3DE Network Input is frame-stamped and sent from Autonomous to
  Authority. O3DE Authority rewinds before processing network input
  to maintain consistency. SCR PredictionInput captures the semantic
  meaning: input for prediction, not the transport mechanism. GGPO
  sends input with redundancy (3–8 frames) to handle packet loss;
  SCR PredictionInput is the semantic input, not the redundant
  transport copies. Unity PredictionInput is scoped to
  PredictedSimulationSystemGroup; SCR PredictionInput is scoped to
  entity-property prediction. O3DE conflates input-for-prediction with
  input-for-authority; SCR separates: PredictionInput is the semantic
  concept, while transport of input to authority is a provider concern.
invariants:
  - PRED-INV-022: PredictionInput MUST be timestamped. Each input belongs to a specific simulation tick.
  - PRED-INV-023: PredictionInput MUST declare which entity and properties it targets.
  - PRED-INV-024: PredictionInput MAY be in one of three states: confirmed, rejected, or pending.
  - PRED-INV-025: PredictionInput MUST record provenance: source host, entity, tick, input data, timestamp.
  - PRED-INV-026: PredictionInput used for local prediction MUST be the same input transmitted to authority. No semantic divergence permitted.
```

### 4.6 AuthorityUpdate

```yaml
concept: AuthorityUpdate
source: O3DE Multiplayer, GGPO rollback netcode, Unity Netcode for Entities
source_terminology: >
  O3DE: authoritative state replication (NetworkProperty delta);
  GGPO: remote input arrival triggering rollback;
  Unity: server snapshot applied to predicted entities
scr_interpretation: >
  AuthorityUpdate is the state correction from authority. An
  AuthorityUpdate carries authoritative state that MAY conflict with
  a host's PredictedState. AuthorityUpdate is a specific form of
  Replication (Sprint 02) with correction semantics: when the
  authoritative state differs from predicted state, the receiving
  host MUST invoke Reconciliation. AuthorityUpdate is always
  authoritative — it represents the source of truth, not an
  approximation. AuthorityUpdate MAY carry the full authoritative
  state (snapshot) or a delta from last acknowledged state.
  AuthorityUpdate triggers Reconciliation on the receiving host
  when it conflicts with PredictedState.
differences: >
  O3DE replicates NetworkProperty deltas from Authority to Autonomous.
  When an Autonomous host receives a delta that conflicts with its
  predicted properties, it rewinds and resimulates. SCR AuthorityUpdate
  captures the semantic meaning: authoritative state correction, not
  the delta-replication mechanism. GGPO triggers rollback on remote
  input arrival (not full state); SCR AuthorityUpdate MAY carry full
  state or delta — the semantic meaning is "authority says this is
  correct." Unity applies server snapshots to predicted entities and
  resimulates; SCR AuthorityUpdate is the semantic trigger for this
  process, independent of snapshot format. O3DE AuthorityUpdate is
  implicit in the replication system; SCR makes it an explicit semantic
  operation with defined contracts.
invariants:
  - PRED-INV-027: AuthorityUpdate MUST be authoritative. It represents the source of truth, not an approximation.
  - PRED-INV-028: AuthorityUpdate MUST declare the authoritative host that originated it.
  - PRED-INV-029: When AuthorityUpdate conflicts with PredictedState, the receiving host MUST invoke Reconciliation.
  - PRED-INV-030: AuthorityUpdate MUST record provenance: authoritative host, entity, state or delta, timestamp, tick.
  - PRED-INV-031: AuthorityUpdate MAY carry full state (snapshot) or delta. Format is a provider concern; semantic meaning is unchanged.
  - PRED-INV-032: AuthorityUpdate MUST NOT be modified in transit. The authoritative state must arrive unchanged.
```

## 5. Semantic Family: Cross-Cutting Properties

### 5.1 Prediction Lifecycle

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PREDICTION LIFECYCLE                             │
│                                                                     │
│  1. PredictionInput    ──→ 2. PredictedState  ──→ (displayed)      │
│     (input at tick N)       (speculative state)                     │
│           │                       │                                 │
│           │                       │  4. Reconciliation              │
│           │                       │     (identify divergence)       │
│           │                       │         │                       │
│           │   3. AuthorityUpdate  │         ▼                       │
│           │   (authority says     │  5. Rollback                    │
│           │    state at tick M)   │     (restore to tick M)         │
│           │         │             │         │                       │
│           │         ▼             │         ▼                       │
│           │    6. Replay          │  6. Replay                      │
│           │    (re-execute        │     (re-execute inputs          │
│           │     inputs M..N)      │      M..N)                      │
│           │         │             │         │                       │
│           │         ▼             │         ▼                       │
│           └──→ corrected state    └──→ corrected state              │
│                (authoritative)          (authoritative)              │
└─────────────────────────────────────────────────────────────────────┘
```

### 5.2 Relationship Matrix

| | PredictedState | Reconciliation | Rollback | Replay | PredictionInput | AuthorityUpdate |
|---|----------------|----------------|----------|--------|-----------------|-----------------|
| **PredictedState** | — | Corrected by Reconciliation | Restored by Rollback | Reconstructed by Replay | Produced by PredictionInput | Corrected by AuthorityUpdate |
| **Reconciliation** | Corrects PredictedState | — | May trigger Rollback | May trigger Replay | Uses PredictionInput | Triggered by AuthorityUpdate |
| **Rollback** | Restores state for | Part of Reconciliation | — | Followed by Replay | — | — |
| **Replay** | Reconstructs state for | Part of Reconciliation | Follows Rollback | — | Uses PredictionInput | — |
| **PredictionInput** | Produces PredictedState | Used in Reconciliation | Used in Replay | Used in Replay | — | May be confirmed/rejected by AuthorityUpdate |
| **AuthorityUpdate** | Corrects PredictedState | Triggers Reconciliation | — | — | May confirm/reject PredictionInput | — |

### 5.3 Mechanism vs. Semantic Distinction

| Concept | Semantic (SCR) | Mechanism (Provider) |
|---------|----------------|---------------------|
| State correction | **Reconciliation** | Rollback + resimulate |
| Speculative advancement | **PredictedState** | Local simulation tick |
| Input for prediction | **PredictionInput** | Frame-stamped network input |
| Authority correction | **AuthorityUpdate** | Delta replication |
| State reconstruction | **Replay** | Fast-forward re-execution |
| State restoration | **Rollback** | Snapshot restore |

**Critical SCR principle:** Rollback is a provider mechanism, not a semantic concept. SCR defines Reconciliation as the semantic operation; Rollback is one implementation. A provider MAY implement Reconciliation by discarding PredictedState and accepting current authoritative state (no rollback needed). A provider MAY implement Reconciliation by snapshot-restore + replay (GGPO-style rollback). The semantic contract is satisfied either way.

### 5.4 Determinism as Provider Requirement

Determinism (same inputs → same state) is a **provider requirement** for Rollback/Replay, not a semantic property of SCR prediction concepts. SCR acknowledges determinism:
- PRED-INV-018 requires Replay to produce consistent output (semantic contract)
- PRED-INV-014 distinguishes Rollback (mechanism requiring determinism) from Reconciliation (semantic process)
- A provider MAY implement Reconciliation without determinism if it discards PredictedState rather than replaying

## 6. Invariant Registry

### 6.1 All Invariants Added This Sprint

| Invariant | Statement |
|-----------|-----------|
| **PRED-INV-001** | Prediction MUST NOT modify authoritative state. |
| **PRED-INV-002** | Reconciliation MUST preserve causal ordering. |
| **PRED-INV-003** | Rollback MUST restore to a valid historical state. |
| **PRED-INV-004** | PredictedState MUST declare its prediction scope. |
| **PRED-INV-005** | PredictedState MUST be provisional. |
| **PRED-INV-006** | PredictedState MUST record provenance. |
| **PRED-INV-007** | Multiple PredictedStates MAY exist for the same entity on different hosts. |
| **PRED-INV-008** | Reconciliation MUST identify the divergence point. |
| **PRED-INV-009** | Reconciliation MUST apply authoritative state at the divergence point. |
| **PRED-INV-010** | Reconciliation MUST record provenance. |
| **PRED-INV-011** | Reconciliation MAY be triggered by: authority update arrival, prediction timeout, confidence threshold, explicit correction request. |
| **PRED-INV-012** | Reconciliation completion MUST produce a causally consistent state. |
| **PRED-INV-013** | Rollback requires recorded state history. |
| **PRED-INV-014** | Rollback is a provider mechanism, not a semantic concept. |
| **PRED-INV-015** | Rollback MAY be scoped to specific entities or entire world state. |
| **PRED-INV-016** | Rollback MUST NOT discard unsimulated inputs. |
| **PRED-INV-017** | Replay MUST preserve temporal ordering. |
| **PRED-INV-018** | Replay requires deterministic simulation. |
| **PRED-INV-019** | Replay MUST NOT invent inputs. |
| **PRED-INV-020** | Replay MUST record provenance. |
| **PRED-INV-021** | Replay MAY be scoped to specific entities or entire world state. |
| **PRED-INV-022** | PredictionInput MUST be timestamped. |
| **PRED-INV-023** | PredictionInput MUST declare which entity and properties it targets. |
| **PRED-INV-024** | PredictionInput MAY be in one of three states: confirmed, rejected, or pending. |
| **PRED-INV-025** | PredictionInput MUST record provenance. |
| **PRED-INV-026** | PredictionInput used for local prediction MUST be the same input transmitted to authority. |
| **PRED-INV-027** | AuthorityUpdate MUST be authoritative. |
| **PRED-INV-028** | AuthorityUpdate MUST declare the authoritative host. |
| **PRED-INV-029** | When AuthorityUpdate conflicts with PredictedState, host MUST invoke Reconciliation. |
| **PRED-INV-030** | AuthorityUpdate MUST record provenance. |
| **PRED-INV-031** | AuthorityUpdate MAY carry full state or delta. |
| **PRED-INV-032** | AuthorityUpdate MUST NOT be modified in transit. |

### 6.2 Relationship to Sprint 02 Invariants

| Sprint 02 Invariant | Relationship to Sprint 03 |
|---------------------|--------------------------|
| **DIST-AUTH-001** | AuthorityUpdate requires exactly one authoritative host |
| **DIST-AUTH-003** | Prediction MUST NOT violate authority boundaries (PRED-INV-001 extends) |
| **DIST-REP-001** | AuthorityUpdate originates from authoritative host only |
| **DIST-REP-002** | AuthorityUpdate MUST preserve semantic meaning |
| **DIST-REP-006** | AuthorityUpdate MUST record provenance |

## 7. Exit Criteria Verification

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Each definition has provenance | ✓ | Each definition cites O3DE source_terminology and research source |
| Definitions general enough for games/robotics/distributed-simulation/digital-twins | ✓ | Cross-domain examples in differences sections; mechanism-agnostic |
| Prediction does not silently overwrite authoritative state | ✓ | PRED-INV-001 explicitly states this |
| Reconciliation is a defined semantic operation | ✓ | PRED-INV-008, 009, 010, 011, 012 define reconciliation process |
| Temporal ordering is preserved | ✓ | PRED-INV-002, PRED-INV-017 enforce causal/temporal ordering |
| Rollback distinguished as provider mechanism | ✓ | PRED-INV-014 explicitly separates mechanism from semantics |

## 8. M004 Invariant Coverage

| M004 Invariant | Coverage |
|----------------|----------|
| **Authority transitions are explicit** | Sprint 02 (DIST-AUTH-002) |
| **Prediction does not silently overwrite authoritative state** | Sprint 03 (PRED-INV-001) |
| **Replicated state has defined ownership** | Sprint 02 (DIST-OWN-001 through 006) |
| **Time ordering is preserved across distributed observations** | Sprint 02 (DIST-OBS-002) + Sprint 03 (PRED-INV-002, PRED-INV-017) |

## 9. Notes

- Temporal identity and state ownership model deferred to Sprint 04 as specified in the sprint plan.
- These six definitions build on Sprint 02's five distributed-state definitions (Authority, Ownership, Replication, Observation, RemoteOperation).
- All invariants follow the PRED- prefix convention for prediction/reconciliation semantics.
- The mechanism-vs-semantic distinction (Section 5.3) is the core architectural contribution of this sprint — it prevents SCR from being coupled to any specific rollback implementation.
