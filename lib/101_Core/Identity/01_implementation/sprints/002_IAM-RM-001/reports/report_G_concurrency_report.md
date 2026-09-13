# Report G — Concurrency Report

**Milestone:** IAM-RM-001  
**Suite:** `src/iam_rm_001/concurrency.py::run_concurrency_suite`

## What concurrency is modelled

> **This is concurrency *model checking by explicit interleaving*, not physical concurrent execution.**

The reference machine is single-threaded. Concurrency is modelled by enumerating interleavings (permutations) of event sequences across independent actors and checking all invariants after each transition. This is explicitly not "serialise everything and claim decentralised safety" (spec §25).

## 1. Disjoint domain concurrency

```text
D_A = DOM_A = [0,128)      owner AUTH_A
D_B = DOM_B = [128,256)    owner AUTH_B
D_A ∩ D_B = ∅
```

All interleavings of `AllocateSID(DOM_A, sid=10)` and `AllocateSID(DOM_B, sid=200)`:

| Property | Result |
|---|---|
| Interleavings tested | 2 |
| All succeeded | true |
| Invariant violations | none |
| Coordination required | **no** |

**Conclusion:** `D_A ∩ D_B = ∅ → independent allocation is safe`. No coordination is needed between independent allocators because their regions cannot collide.

## 2. Shared domain concurrency

```text
D_A = DOM_B = DOM_A (shared, owner AUTH_A)
```

| Case | Result |
|---|---|
| Distinct SIDs (1 and 2), all interleavings | all safe |
| Same SID (1) from two transactions T1/T2 | second rejected |
| Coordination required | **yes** (enforced via reservation/commit + historical set) |

**Conclusion:** `D_A ∩ D_B ≠ ∅ → coordination is required`. The machine enforces coordination by rejecting an SID already reserved/committed.

## 3. Overlapping delegation race

Two authorities race to reserve overlapping domains `[0,128)` and `[64,192)`:

| Property | Result |
|---|---|
| Overlap rejected | true |
| Invariant violations | none |

## 4. Allocation race

Two transactions race to commit the same SID:

| Property | Result |
|---|---|
| Duplicate SID rejected | true |
| H after race | single SID |
| Invariant violations | none |

## Coordination summary

| Scenario | Coordination required |
|---|---|
| Disjoint domains | none |
| Shared domain, distinct SIDs | none (no overlap) |
| Shared domain, same SID | yes — reservation/commit serialisation |
| Overlapping delegation | yes — disjointness enforced at reserve time |
| Allocation race on same SID | yes — historical-set guard |

## Reproduction

`run_verification.py` → key `concurrency` in `reports/verification_evidence.json`.

---
*Report G per IAM-RM-001 §20.*