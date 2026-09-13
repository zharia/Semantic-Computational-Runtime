# Report B — Verification Matrix

**Milestone:** IAM-RM-001  
**Invariants:** IAM-I001 … IAM-I016

## Invariant Matrix

| ID | Property | Enforcement | Test | Exhaustive | Status |
|----|----------|-------------|------|------------|--------|
| IAM-I001 | Root uniqueness | `assert_IAM_I001_root_uniqueness` | `_base` setup + exploration invariant check | Yes (all 155 states) | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I002 | Domain disjointness | Machine `reserve_domain` overlap check; `assert_IAM_I002` | adversarial #2, #15, #21; concurrency overlapping delegation | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I003 | Domain containment | Machine subset check; `assert_IAM_I003` | adversarial #3, #22 | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I004 | Allocation containment | Machine region check; `assert_IAM_I004` | adversarial #4, #17, #20 | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I005 | Allocation injectivity | `assert_IAM_I005`; historical-set guard | adversarial #16; concurrency allocation race | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I006 | Authority containment | Machine domain-authority match; `assert_IAM_I006` | adversarial #7, #19 | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I007 | Cryptographic provenance | `assert_IAM_I007`; provenance on commit | adversarial #23, #24; provenance suite | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I008 | Generation validity | Machine generation fence; `assert_IAM_I008` | adversarial #5, #6, #18; generation suite | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I009 | Historical monotonicity | `assert_IAM_I009(prev, curr)` | exploration prev/curr tracking | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I010 | Durable non-reuse | Machine `sid in H` guard; `assert_IAM_I010` | adversarial #9; historical non-reuse suite | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I011 | Crash monotonicity | `recover` preserves H; `assert_IAM_I011` | crash Cases A–D | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I012 | Snapshot safety | `recover` unions H + carries P/B/M/D; `assert_IAM_I012` | adversarial #10; snapshot suite | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I013 | Contextual resolution | `assert_IAM_I013` | provenance suite; `verify(ctx, sid)` | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I014 | Identity/Manifestation separation | `assert_IAM_I014` | binding/manifestation suite | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I015 | Binding separation | `assert_IAM_I015` | binding/manifestation suite | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |
| IAM-I016 | Transaction idempotence | Machine Q-table guard; `assert_IAM_I016` | adversarial #8, #13, #14, #25; transaction suite | Yes | FORMALLY ENFORCED / EXHAUSTIVELY VERIFIED |

## Status definitions

Per spec §1:

- **FORMALLY ENFORCED** — the machine rejects transitions that would violate the invariant, or the invariant is maintained structurally by construction.
- **PROPERTY TESTED** — an executable property test exercises the invariant across generated inputs.
- **EXHAUSTIVELY VERIFIED** — the invariant holds across every reachable state in the bounded N=8 exploration.
- **PARTIALLY TESTED** — exercised only by success cases.
- **UNTESTED** — no executable evidence.

## Result

All 16 invariants are:

```text
FORMALLY ENFORCED
+
EXHAUSTIVELY VERIFIED (over bounded N=8 reachable state space)
+
ADVERSARIALLY TESTED
```

No invariant is merely "documented". No invariant is marked verified solely because an ordinary success-case unit test passes. Evidence: `reports/verification_evidence.json`.

## Explicit non-claims

- Exhaustive verification is over the **bounded** event alphabet and depth ≤ 3 (see Report C). It is **not** an unbounded proof.
- Liveness (valid operations eventually succeed) is not proven.

---
*Report B per IAM-RM-001 §20.*