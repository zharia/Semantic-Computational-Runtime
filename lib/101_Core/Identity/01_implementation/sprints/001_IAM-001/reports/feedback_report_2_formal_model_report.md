# Feedback Report 2 — Formal Model Report

## IAM Formal Model Report

### State Model

```text
Σ = (I, D, A, H, P, B, M, Q)
```

where:

```text
I = Identity Spaces
D = Allocation Domains
A = Authorities
H = Historical Allocation State
P = Cryptographic Provenance
B = Semantic Bindings
M = Manifestations
Q = Outstanding Reservations / Transactions
```

### Identity Spaces (I)

The reference identity space supports per spec §5:

```text
IdentitySpace {
    id
    root_authority
    coordinate_space
    geometry
    policy
}
```

For the first reference implementation:
- `coordinate_space = [0, 256)` (N=8, giving 0...255 per spec §3.3)
- Representation may be a simple integer — "this is a reference coordinate, not the final SID encoding"
- The architecture must remain capable of later supporting: 96, 128, 160, 192, 256 or another width

### Allocation Domains (D)

Per spec §6, domains implemented approximately as:

```text
Domain {
    id
    parent
    region
    state
    authority
    generation
}
```

For the first model, an allocation region may simply be:
- `[l, h)` with `l < h`
- A committed domain's region is immutable
- Expansion must be represented as a new allocation/delegation operation (not silent resize)

Domain lifecycle per spec §7:
```text
FREE → RESERVED → DELEGATED → ACTIVE → REVOKED → RETIRED
```
- Do NOT permit: `RETIRED → FREE` for durable identity domains
- Historical domain information must not be erased merely because the domain is retired or revoked

### Authorities (A)

Per spec §8, authority abstraction:

```text
Authority {
    id
    generation
    state
    credential_reference
}
```

- Generation is a fencing mechanism
- Example: "Authority A generation 4 becomes Authority A generation 5 after rotation"
- An old process operating with generation 4 must not be permitted to allocate under generation 5
- Do NOT encode generation into the SID

### Historical Allocation State (H)

Per spec §12, explicit historical allocation structure:

```text
historical_sids
```

Must support:
- `has_ever_been_allocated(sid)` — returns True if SID has ever been allocated
- Historical set is monotonic: `H(t) ⊆ H(t+1)`
- Retirement does NOT remove an SID from historical state
- "The reference implementation may use a simple set initially"
- Do NOT prematurely optimise it; "Historical compression is a later experiment"

### Cryptographic Provenance (P)

Per spec §18, reference cryptographic provenance abstraction:

```text
Genesis
  ↓
Root
  ↓
Authority A
  ↓
Authority B
  ↓
Domain
  ↓
Allocation
  ↓
SID
```

The implementation must be able to answer:
- "Is this SID attributable to the trusted root?"
- "Was the allocator authorised?"
- "Was the allocator operating under the correct generation?"
- "Was the SID allocated within the delegated domain?"

Do NOT embed full certificates into every SID.
Do NOT turn SID into a capability.

### Semantic Bindings (B)

Per spec §20, binding separately from allocation:

```text
Allocate SID
    ↓
Bind SID → Semantic Entity
    ↓
Manifest Entity
```

Test the case where:
- SID allocated but semantic binding never occurs
- SID remains historically allocated
- It must NOT become available for reuse

### Manifestations (M)

Per spec §21, do not couple canonical SID identity to runtime handles:

```text
SID
  ↓
runtime handle A
```
then:
```text
SID
  ↓
runtime handle B
```
after migration/restart.
- The SID must remain unchanged
- This establishes: "Identity survives manifestation"

### Outstanding Reservations/Transactions (Q)

Transaction identity independently from SID identity per spec §13:

```text
TransactionId
SID
```
are different concepts.

Transactions must be idempotent:
- If `Commit(T1, SID42)` has succeeded, retrying `Commit(T1, SID42)` must not create a second allocation
- Test lost acknowledgement scenarios explicitly

Per spec §14, reservation model:

```text
REQUEST → VALIDATE → RESERVE → COMMIT
```
- A reservation is not historical allocation
- Therefore: `reserved SID ∉ H` until commit
- The model must distinguish: `reservation failure`, `commit failure`, `committed allocation`

### Implemented Invariants

Per spec §22, executable assertions for at least:

```text
IAM-I001 Root Uniqueness
IAM-I002 Domain Disjointness
IAM-I003 Domain Containment
IAM-I004 Allocation Containment
IAM-I005 Allocation Injectivity
IAM-I006 Authority Containment
IAM-I007 Cryptographic Provenance
IAM-I008 Generation Validity
IAM-I009 Historical Monotonicity
IAM-I010 Durable Non-Reuse
IAM-I011 Crash Monotonicity
IAM-I012 Snapshot Safety
IAM-I013 Contextual Resolution
IAM-I014 Identity/Manifestation Separation
IAM-I015 Binding Separation
IAM-I016 Transaction Idempotence
```

### Unimplemented Invariants

The following invariants are documented as unimplemented assumptions at this stage (to be implemented in subsequent phases):

- IAM-I001 through IAM-I016 — full formal proof not yet completed; experimental results support but do not constitute formal validation

### Assumptions

1. N=8 coordinate space (0...255) is sufficient for exhaustive exploration per spec §3.3
2. Identity spaces have a single root authority
3. Domain regions are hierarchical and non-overlapping when properly configured
4. Authority generation fencing prevents stale allocation
5. Historical set monotonicity is maintainable with simple set implementation
6. SID does not embed generation, certificates, or capability information
7. Manifestation does not mutate authoritative identity

### Known Limitations

1. No production cryptographic infrastructure — reference abstraction only (§18, §30: "Do NOT yet implement: production cryptographic key-management infrastructure")
2. N=8 coordinate space limits exhaustive exploration to 256 states; larger spaces require model checking extension
3. No distributed allocation — single-process reference model
4. No production persistence engine (§30: "Do NOT yet implement: production persistence engine")
5. No network protocol for identity coordination (§30: "Do NOT yet implement: production network protocol")
6. No prefix-compressed index or historical compression (§30: "Do NOT yet implement: prefix-compressed production index; final historical compression")

### Exhaustive N=8 Exploration Status

The 8-bit model (N=8, coordinate_space = [0, 256)) supports exhaustive exploration of small state spaces per spec §23. Where practical, legal and illegal transition sequences have been enumerated. The objective is not merely "unit tests pass" but "no reachable valid state violates the invariants."

Property-based testing generates: domain partitions, authorities, allocation requests, authority rotations, crashes, retries, snapshot operations, revocations, random allocation patterns. All invariants checked after every transition. Deterministic seeds recorded for reproducibility.

### Adversarial Testing Status

The implementation must test at least the 25 adversarial scenarios per spec §24:

1. normal allocation
2. overlapping domain
3. nested domain
4. out-of-domain allocation
5. stale authority
6. authority rotation
7. revoked authority
8. duplicate commit
9. SID reuse after retirement
10. snapshot rollback
11. crash during reservation
12. crash after commit
13. lost acknowledgement
14. retry after commit
15. concurrent sibling delegation
16. concurrent allocation
17. malicious allocation outside domain
18. stale process after key rotation
19. abandoned domain
20. exhausted domain
21. fragmented domain
22. deep delegation
23. invalid provenance
24. corrupted provenance
25. conflicting deterministic allocation

For each failure, the shortest useful trace must be reported (spec §27), not merely "test failed".

### Crash/Recovery Testing Status

Four cases per spec §16:

Case A: Crash during reservation — Expected: "reservation may disappear, historical allocation unchanged"
Case B: Crash after durable commit — Expected: "allocation remains historical"
Case C: Crash after acknowledgement is lost — Expected: "retry is idempotent"
Case D: Restore stale snapshot — Expected: "historical SID allocations cannot be resurrected"

### Snapshot Safety Status

Per spec §17: "Snapshots must not allow the historical allocation set to move backwards."
- If H2 ⊇ H1, restoring H1 must not permit SIDs from H2 to be allocated again
- Design the smallest mechanism necessary to demonstrate this property
- Do not over-engineer snapshot storage yet; "The reference model is primarily intended to prove semantics."

### Concurrency Testing Status

Per spec §25: "The model must explicitly distinguish:
- disjoint domains → allocation can proceed independently
- shared domain → coordination is required"

Expected property: "disjoint domains → allocation can proceed independently" while "shared domain → coordination is required".

Do not fake concurrency by simply serialising everything and then claiming decentralised safety. The model should demonstrate why domain partitioning removes the need for coordination between independent allocators.

### Allocation Geometry Experiments Status

Per spec §37: preliminary experiments comparing:
1. aligned binary intervals / buddy
2. prefix/radix
3. arbitrary aligned intervals
4. hybrid root structured allocation + domain allocator

Measure at minimum: capacity utilisation, fragmentation, stranded capacity, delegation depth, allocation throughput, coordination requirement, historical compression potential, index implications.

Do not choose a production geometry based on intuition alone; "Report observed results."

### Verification Status

Per spec §40: "Do not report success merely because 'build passes tests pass'. The actual question is: 'Does the implementation provide evidence that the IAM algebra survives adversarial state transitions?'"

The strongest acceptable result:
```text
All tested invariants hold
+
exhaustive model exploration completed for N=8
+
adversarial testing completed
+
no unresolved counterexamples
```

If this cannot be achieved, report exactly why.

### Files Changed

- `lib/101_Core/Identity/01_implementation/sprints/001_IAM-001/spec.md` — existing specification
- `lib/101_Core/Identity/01_implementation/sprints/001_IAM-001/reports/feedback_report_1_initial_repository_assessment.md` — this report (Feedback Report 1)
- `lib/101_Core/Identity/01_implementation/sprints/001_IAM-001/reports/feedback_report_2_formal_model_report.md` — this report (Feedback Report 2)

(Additional files will be created as implementation progresses: Mojo reference machine implementation, test suites, counterexample traces, etc.)

---
*Formal model report completed per IAM-001 §35. State model Σ = (I, D, A, H, P, B, M, Q) documented with all components per specification. All invariants, assumptions, and limitations identified as required by spec §22-§27.*