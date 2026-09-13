# Report D — Adversarial Test Report

**Milestone:** IAM-RM-001  
**Suite:** `src/iam_rm_001/adversarial.py::run_all_adversarial`  
**Result:** 25 / 25 passed (after correcting 2 discovered implementation defects — see Report E)

| # | Scenario | Result | Invariants exercised | Reproduction |
|---|----------|--------|----------------------|--------------|
| 1 | normal allocation | PASS — SID 42 in H | I004, I005, I007 | `run_verification.py` / adversarial #1 |
| 2 | overlapping domain | PASS — rejected | I002 | #2 |
| 3 | nested domain | PASS — legal subset accepted | I003 | #3 |
| 4 | out-of-domain allocation | PASS — rejected | I004 | #4 |
| 5 | stale authority | PASS — rejected | I008 | #5 |
| 6 | authority rotation | PASS — gen 1→2 | I008 | #6 |
| 7 | revoked authority | PASS — rejected | I006 | #7 |
| 8 | duplicate commit | PASS — single allocation | I016 | #8 |
| 9 | SID reuse after retirement | PASS — rejected | I010 | #9 |
| 10 | snapshot rollback | PASS — resurrection rejected | I012 | #10 (defect fixed) |
| 11 | crash during reservation | PASS — reservation dropped, H unchanged | I011 | #11 |
| 12 | crash after commit | PASS — allocation retained | I011 | #12 |
| 13 | lost acknowledgement | PASS — retry idempotent | I016 | #13 |
| 14 | retry after commit | PASS — single allocation | I016 | #14 |
| 15 | concurrent sibling delegation | PASS — disjoint siblings accepted | I002 | #15 |
| 16 | concurrent allocation | PASS — both SIDs recorded | I005 | #16 |
| 17 | malicious allocation outside domain | PASS — rejected | I004 | #17 |
| 18 | stale process after key rotation | PASS — rejected | I008 | #18 |
| 19 | abandoned domain | PASS — rejected (not ACTIVE) | I006 | #19 |
| 20 | exhausted domain | PASS — rejected at capacity | I004 | #20 |
| 21 | fragmented domain | PASS — disjoint fragments accepted | I002 | #21 |
| 22 | deep delegation | PASS — depth 3 accepted | I003 | #22 |
| 23 | invalid provenance | PASS — wrong root rejected | I007 | #23 |
| 24 | corrupted provenance | PASS — IAM-I007 detected | I007 | #24 |
| 25 | conflicting deterministic allocation | PASS — rejected | I016 | #25 (defect fixed) |

## Failure classification discipline

No scenario conflates the two failure categories from spec §26:

- **Invalid request** (e.g. #2, #4, #17, #20): rejected correctly — this is *successful system behaviour*.
- **Protocol failure** (would be an invariant violation permitting two honest authorities to commit overlapping domains): none observed.

## Notes

- #24 deliberately corrupts state (`del P[5]`) to prove the invariant *detects* corruption; detection is the passing outcome.
- #10 and #25 initially failed and exposed real defects (Report E); after correction, both pass and the corresponding invariants hold.

---
*Report D per IAM-RM-001 §20.*