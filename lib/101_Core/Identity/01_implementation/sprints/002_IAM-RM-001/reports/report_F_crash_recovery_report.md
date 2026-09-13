# Report F — Crash / Recovery Report

**Milestone:** IAM-RM-001  
**Suite:** `src/iam_rm_001/scenarios.py::crash_recovery_suite`, `snapshot_safety_suite`  
**Result:** All cases pass; 0 invariant violations.

## Crash cases (spec §16)

| Case | Scenario | Expected | Observed | Status |
|------|----------|----------|----------|--------|
| A | Crash during reservation | reservation may disappear; historical allocation unchanged | reservation dropped; SID ∉ H | PASS |
| B | Crash after durable commit | allocation remains historical | SID ∈ H after recover | PASS |
| C | Crash after acknowledgement lost | retry is idempotent | single allocation, single historical identity | PASS |
| D | Restore stale snapshot | historical SID allocations cannot be resurrected | re-allocation rejected; H = live ∪ snapshot | PASS |

## Snapshot safety (spec §17)

```text
allocate SID 1
snapshot S1           H(S1) = {1}
allocate SID 2
snapshot S2           H(S2) = {1,2}
restore S1
attempt to allocate SID 2
```

| Property | Observed |
|---|---|
| H(S1) ⊆ H(S2) | true |
| H after restore (live before restore {1,2}) | {1,2} |
| No backwards movement of H | true |
| SID 2 re-allocation after restore | rejected |
| Invariants after restore | none violated |

## Authority recovery

- `rotate_authority` increments generation without mutating existing SIDs.
- Existing SIDs allocated under the previous generation remain historically valid and verifiable.
- Stale-generation allocation after rotation is rejected (see Report G / generation fencing).

## Stale authority recovery

- A process presenting a stale generation is fenced (rejected); its previously committed SIDs are unaffected.

## Architectural note

Snapshot recovery required an implementation correction (Report E, Counterexample 1): H monotonicity alone is insufficient — provenance/binding/manifestation and domain membership for live-only SIDs must also be carried forward, or IAM-I007/IAM-I005 break. This is recorded as a required explicit recovery rule for IAM-001 (Report H).

---
*Report F per IAM-RM-001 §20.*