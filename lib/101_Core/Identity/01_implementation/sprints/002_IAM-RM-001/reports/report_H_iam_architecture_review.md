# Report H — IAM Architecture Review

**Milestone:** IAM-RM-001  
**Basis:** executable reference machine, exhaustive bounded exploration, 25 adversarial scenarios, crash/recovery, concurrency model checking.

## Questions (spec §20)

### Is the algebra internally consistent?

**Yes, within the tested bound.** All 16 invariants held across 155/155 explored states. Two inconsistencies were exposed during adversarial testing, both traced to implementation defects (not algebraic inconsistency) and corrected: snapshot recovery consistency (Report E #1) and transaction-id divergence (Report E #2).

### Is root-scoped uniqueness structurally guaranteed?

**Yes.** A SID can be committed only if it is absent from the historical set H and lies within exactly one delegated domain region. Domain disjointness (IAM-I002) plus containment (IAM-I003) plus allocation containment (IAM-I004) make collision structurally impossible within a single root. Uniqueness is structural, not probabilistic — no UUID/ULID-style collision probability is involved.

### Is delegation non-overlapping?

**Yes.** `reserve_domain` rejects any region overlapping an existing sibling; `assert_IAM_I002` verifies the maintained condition. Sibling disjointness plus parent containment yields non-overlapping delegation at arbitrary depth (tested to depth 3).

### Is authority rotation safe?

**Yes.** Rotation increments generation and invalidates stale-generation allocation (IAM-I008). Existing SIDs remain historically valid and independently verifiable. Generation fencing ≠ identity mutation (verified explicitly).

### Is stale authority fenced?

**Yes.** A transaction presenting generation < current generation is rejected at reserve and commit.

### Is historical allocation monotonic?

**Yes.** H only grows. IAM-I009 checked on every explored transition; crash (IAM-I011) and snapshot (IAM-I012) preserve monotonicity.

### Is snapshot recovery safe?

**Yes, after correction.** A naive H-only union produced an H/P inconsistency (Report E #1). Recovery now unions H *and* carries forward provenance, bindings, manifestations, and domain membership for live-only SIDs. No SID can be resurrected.

### Are transactions idempotent?

**Yes, after correction.** Same `(tx, sid)` replay yields one allocation. Reusing a transaction id for a different SID is now rejected (Report E #2).

### Can independent domains allocate without coordination?

**Yes.** Disjoint-domain interleavings all succeed with no coordination; shared-domain same-SID allocation requires coordination, which the machine enforces.

### Is SID correctly separated from semantics?

**Yes.** SID is a coordinate; semantic meaning lives in binding B (SID → entity). Allocation without binding leaves the SID historically consumed but semantically unbound (verified).

### Is SID correctly separated from manifestation?

**Yes.** Multiple manifestation handles can succeed one another for the same SID; the SID is unchanged (verified).

### Are there hidden assumptions?

Yes — see below. None currently invalidate the model, but they bound its scope.

### Which assumptions remain unverified?

1. Unbounded-trace soundness (only bounded N=8 exploration performed).
2. Single-root: no test of two independent roots coexisting (out of scope for reference machine).
3. Reference cryptographic provenance is logical, not cryptographic.
4. Liveness not proven.
5. Deterministic/derived allocation not implemented.

### What must change before SID-001?

1. Adopt an explicit IAM-001 recovery rule: snapshot restore must reconstruct a state consistent with the unioned history (provenance/binding/domain membership included).
2. Specify transaction-vs-SID conflict semantics formally (reject reuse of tx id for another SID).
3. Decide whether multi-root identity spaces are in scope and specify their interactions.
4. Specify the relationship between a future derived/deterministic allocator and domain policy authorisation.
5. Extend exhaustive exploration (larger N / deeper traces) or add a formal proof for the core uniqueness theorem.

## Hidden-assumption register

| Assumption | Risk | Status |
|---|---|---|
| H-only monotonicity suffices for snapshot safety | HIGH — already falsified; corrected | Resolved, must be codified |
| Transaction id always identifies one SID | MEDIUM — falsified; corrected | Resolved, must be codified |
| Bounded exploration adequate | MEDIUM | Open |
| Single root sufficient | LOW for v0 | Open |
| Logical provenance adequate | LOW for v0 | Accepted limitation |

---
*Report H per IAM-RM-001 §20.*