# Report E — Failure / Counterexample Report

**Milestone:** IAM-RM-001  
**Discovered defects:** 2 (both corrected; both were implementation defects, not model defects)

A counterexample is a valuable output of this milestone. Both failures below were discovered by adversarial testing and are reported in full rather than suppressed.

---

## Counterexample 1 — Snapshot restore produced H/P inconsistency

```text
Invariant:
    IAM-I007 Cryptographic Provenance
    (observed jointly with IAM-I012 Snapshot Safety and IAM-I005 Allocation Injectivity)

Initial State:
    Root [0,256); DOM_A [0,128) ACTIVE under AUTH_A generation 1

Trace:
    1. AllocateSID(DOM_A, AUTH_A, gen=1, sid=1, TX8)      -> H={1}
    2. Snapshot S1                                        -> H(S1)={1}
    3. AllocateSID(DOM_A, AUTH_A, gen=1, sid=2, TX9)      -> H={1,2}
    4. Recover(S1)                                        -> H={1,2} (union enforced)
    5. Attempt AllocateSID(..., sid=2, TX10)

Expected:
    SID 2 resurrection rejected AND all invariants hold after recover.

Observed:
    SID 2 resurrection rejected (correct), BUT after step 4 H={1,2}
    while P (provenance) lacked SID 2 -> IAM-I007 violated.
    Snapshot H = {1}; live H = {1,2}; the union H={1,2} retained no
    provenance record for SID 2 because P was restored from the snapshot.

Root Cause:
    The recover() implementation enforced H monotonicity (IAM-I012) but did
    not carry forward the consistency structures (P, B, M, and domain
    allocated_sids) for SIDs that survive only through the live H.
    Model gap: IAM-001 states H must be monotonic on snapshot restore but
    does not explicitly state that provenance for live-only SIDs must also
    be retained. Without that, H and P become inconsistent.

Classification:
    Implementation defect (recover() incomplete). Model intent is sound:
    IAM-I012 requires no resurrection; retention of provenance is a necessary
    consequence, not a model change.

Proposed Correction:
    On recover, carry forward P/B/M for every SID in live H, and union
    domain.allocated_sids. (Implemented.)

Reproduction:
    run_verification.py adversarial #10; deterministic seed 0.
```

**Model amendment required?** No semantic amendment to IAM-001. The model already requires historical non-resurrection. The correction is an implementation obligation: *snapshot recovery must restore a state consistent with the unioned history*. This should be recorded as an explicit IAM-001 recovery rule in the next revision (see Report H, "Required IAM-001 Changes").

---

## Counterexample 2 — Transaction ID reused for a different SID

```text
Invariant:
    IAM-I016 Transaction Idempotence

Initial State:
    Root [0,256); DOM_A [0,128) ACTIVE under AUTH_A generation 1

Trace:
    1. AllocateSID(DOM_A, AUTH_A, gen=1, sid=5, TX25)   -> H={5}, Q[TX25]=(5, COMMITTED)
    2. AllocateSID(DOM_A, AUTH_A, gen=1, sid=6, TX25)   -> expected reject

Expected:
    Reject: transaction TX25 already bound to SID 5.

Observed:
    No error. reserve_sid() overwrote Q[TX25] with (sid=6, RESERVED),
    then commit_sid() allocated SID 6 under the same transaction id.
    One transaction id ended up associated with two allocations.

Root Cause:
    reserve_sid() handled idempotent replays (same tx, same sid) but did not
    reject a transaction id presented with a *different* SID. The Q-table was
    silently overwritten.

Classification:
    Implementation defect. Model already distinguishes Transaction identity
    from SID identity (spec §13) and requires idempotence, not divergence.

Proposed Correction:
    In reserve_sid(), if tx_id already exists with a different SID -> reject.
    (Implemented.)

Reproduction:
    run_verification.py adversarial #25; deterministic seed 0.
```

---

## Summary

| # | Invariant | Classification | Corrected | Model amendment needed? |
|---|-----------|----------------|-----------|--------------------------|
| 1 | IAM-I007/I012 | Implementation defect | Yes | No (record recovery rule) |
| 2 | IAM-I016 | Implementation defect | Yes | No |

After correction, the full suite passes (25/25 adversarial, 0 invariant violations across exploration). No unresolved critical invariant violations remain.

Per spec §21, neither defect was concealed by merely editing tests; each was traced to root cause and classified.

---
*Report E per IAM-RM-001 §20.*