# Sprint 01: Deep Temporal State Trace Exploration

**Parent Milestone:** [Milestone 003: Deep Targeted Verification](../spec.md)  
**Derived from:** [spec.md](../../../spec.md) (Section 8)  
**Deliverable:** `reports/report_L_deep_targeted_exploration.md`  
**Status:** Planned  

---

## 1. Mission

Construct and execute a targeted temporal verification suite to explore deep sequential traces through the reference machine's lifecycle, exercising non-trivial compositions of partitions, reservations, commits, delegations, rotations, bindings, snapshots, and recoveries.

---

## 2. Canonical Target Event Pipeline

The exploration suite must trace long semantic paths:

```text
Partition
    ↓
Reserve
    ↓
Commit
    ↓
Delegate
    ↓
Activate
    ↓
Allocate
    ↓
Rotate
    ↓
Allocate
    ↓
Bind
    ↓
Manifest
    ↓
Snapshot
    ↓
Allocate
    ↓
Recover
    ↓
Revoke
    ↓
Retry
    ↓
Retire
```

---

## 3. Targeted Permutation Matrix

The test suite must systematically explore variations including:
* Reservation before crash vs reservation after crash.
* Commit before crash with lost acknowledgment.
* Snapshot taken before allocation vs snapshot taken after allocation.
* Restoration of a stale snapshot.
* Authority rotation before allocation vs after allocation.
* Authority revocation followed by reallocation attempts.
* Authority replacement followed by recovery.
* Repeated retries of committed transactions.
* Allocation attempted after entity retirement.
* Binding restoration after recovery.
* Manifestation changes post-recovery.
* Domain revocation with active sub-delegations.
* Nested delegation across 3+ domain tiers.
* Multiple concurrent sibling domains.
* Domain address space exhaustion.

---

## 4. Exploration Control & Symmetry Reduction

- Apply symmetry reduction on identical entity values and equivalent domain addresses to prevent combinatorial explosion.
- Bounded depth must be explicitly recorded for each trace sequence.
- All intermediate states must be evaluated against all active invariants (including `IAM-I017`).

---

## 5. Deliverable Requirements

Author:
```text
lib/101_Core/Identity/01_implementation/sprints/003_SID-001/reports/report_L_deep_targeted_exploration.md
```
Include:
- Exact sequence diagrams of explored traces.
- Total transitions attempted, legal, and rejected per trace family.
- Counterexamples exposed (or zero violations observed).
- Precise bounds and execution times.
