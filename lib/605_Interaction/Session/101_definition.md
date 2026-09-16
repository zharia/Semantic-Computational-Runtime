# Session — Subdomain Definition

**Path:** `lib/605_Interaction/Session/101_definition.md`  
**Version:** `0.0.1`  
**Status:** Normative Definition  
**Parent Domain:** `605_Interaction`  
**Parent Specification:** `lib/605_Interaction/101_definition.md`  

---

## 1. Purpose

The `Session` subdomain defines the lifecycle, state transitions, capture boundaries, commitment, and cancellation semantics of active interactions.

## 2. Core Concepts

### 2.1 Interaction Session (`INT-014`)
An **Interaction Session** models an ongoing bounded interaction between an Actor and the computational runtime. Examples:
- A drag-and-drop session;
- A 3D spatial transformation session;
- A voice conversation turn;
- A multi-touch gesture session.

### 2.2 Lifecycle State Machine
An Interaction Session follows strict state transitions:
```text
  [Idle / Created]
         │
         ▼
     [Active]  <─── (Continuous updates / trajectory)
      │      │
      │      ▼
      │   [Cancelled]  (Explicit abort, no state mutation)
      ▼
  [Committed]  (Atomic commit, triggers action)
```

### 2.3 Commitment & Cancellation (`INT-015`, `INT-016`)
- **Commitment**: The explicit transition indicating the Actor finalized the interaction. The proposed action is applied.
- **Cancellation**: The explicit transition aborting the interaction without mutating semantic state.

### 2.4 Deletion Semantics (`INT-023`)
Deleting an interaction session record does not reverse committed transformations. Reversal requires an explicit compensating action.

## 3. Invariants
- `INT-014` (Session Integrity): Sessions maintain bounded continuity.
- `INT-015` (Cancellation): Cancellation guarantees no state modification.
- `INT-016` (Commitment): State modification occurs only upon explicit commitment.
- `INT-023` (Deletion Integrity): Session deletion != action reversal.
