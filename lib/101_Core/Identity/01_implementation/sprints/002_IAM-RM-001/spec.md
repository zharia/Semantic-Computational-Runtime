# SCR Development Agent — IAM-RM-001 Implementation & Verification Phase

## Context

Feedback Report 2 — Formal Model Report has now been produced.

The report establishes the intended reference state:

```text
Σ = (I, D, A, H, P, B, M, Q)
```

and documents the intended IAM model, invariants, assumptions and limitations.

The report also explicitly states that the IAM invariants have **not yet been fully formally validated**.

The next phase is therefore **implementation and falsification**.

Do not produce another conceptual specification unless an implementation discovery requires a change to the model.

The immediate objective is:

> **Turn IAM-001 from a documented model into an executable reference machine whose invariants can be attacked, exhaustively explored where practical, and supported by reproducible evidence.**

---

# 1. Required Change of Mode

The project is now moving from:

```text
Architecture
    ↓
Formal Model
```

to:

```text
Formal Model
    ↓
Reference Machine
    ↓
Executable Invariants
    ↓
Exhaustive Exploration
    ↓
Adversarial Testing
    ↓
Counterexamples
    ↓
Model Refinement
```

Do not interpret "all invariants are documented" as "all invariants are implemented."

Do not report an invariant as implemented merely because a test exists that exercises an ordinary success case.

For each invariant, establish whether it is:

```text
FORMALLY ENFORCED
PROPERTY TESTED
EXHAUSTIVELY VERIFIED
PARTIALLY TESTED
UNTESTED
```

These states must be reported separately.

---

# 2. First Task — Inspect Current Implementation

Inspect the repository and determine exactly what has already been implemented since Feedback Report 1.

Report:

```text
Existing IAM implementation
Existing tests
Existing test framework
Existing model-checking/property-testing facilities
Existing cryptographic abstractions
Existing persistence/snapshot abstractions
Existing SCR identity primitives
Existing documentation
```

Do not recreate components that already exist.

If the current implementation differs from Feedback Report 2, document the difference and determine whether the model or implementation is authoritative.

---

# 3. Implement IAM-RM-001

Create the smallest executable reference machine consistent with IAM-001.

The reference state remains:

```text
Σ = (I, D, A, H, P, B, M, Q)
```

The implementation must support at least:

```text
CreateRoot
CreateSpace

ReserveDomain
CommitDomain
DelegateDomain

ActivateAuthority
RotateAuthority
SuspendAuthority
RevokeAuthority

ReserveSID
CommitSID
AllocateSID

BindSID
RetireSID

Snapshot
Recover

Verify
```

Use existing SCR abstractions wherever possible.

---

# 4. Keep the Reference Model Intentionally Small

Use:

```text
N = 8
coordinate space = [0,256)
```

Do not implement the production SID width.

Do not implement ULID.

Do not implement UUID compatibility.

Do not prematurely implement the final cryptographic wire format.

Do not optimise historical storage.

Do not implement the production distributed allocator.

The objective is correctness, not performance.

---

# 5. Executable Invariants

Every IAM invariant must become an executable property where technically possible.

The current invariant set is:

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

For every invariant, create a corresponding implementation/property such as:

```text
assert_IAM_I002(state)
assert_IAM_I003(state)
...
```

or an equivalent architecture appropriate to the language/framework.

The exact implementation mechanism is flexible.

The requirement is not.

The invariant must be executable.

---

# 6. Invariant Matrix

Create a machine-readable or clearly structured verification matrix:

| ID   | Property            | Enforcement | Test | Exhaustive | Status |
| ---- | ------------------- | ----------- | ---- | ---------- | ------ |
| I001 | Root uniqueness     | ...         | ...  | ...        | ...    |
| I002 | Domain disjointness | ...         | ...  | ...        | ...    |
| ...  | ...                 | ...         | ...  | ...        | ...    |

Do not mark an invariant "verified" merely because ordinary unit tests pass.

---

# 7. Exhaustive N=8 Exploration

Implement a deterministic state explorer.

The objective is to explore the reachable state space of the reference machine for sufficiently small traces and configurations.

Where complete state-space exploration is computationally practical, perform it.

Where complete exploration is not practical because the event/state space explodes, report:

```text
exploration boundary
number of states
number of transitions
maximum trace depth
pruning rules
symmetry reductions
assumptions
```

Do not call bounded exploration "complete exhaustive verification" unless it actually is complete over the claimed state space.

This distinction is important.

---

# 8. State Exploration Strategy

Use a transition model conceptually equivalent to:

```text
T : Σ × Event → Σ | Error
```

For each generated state:

```text
1. execute event
2. obtain new state or Error
3. verify all invariants
4. record new state
5. continue exploration
```

Invalid transitions should not mutate state.

Therefore verify:

```text
T(Σ,e) = Error
        ⇒
Σ' = Σ
```

---

# 9. Counterexample Requirement

When an invariant fails, produce the shortest reproducible transition trace.

Required format:

```text
Invariant:
    IAM-I00X

Initial State:
    ...

Trace:
    1. ...
    2. ...
    3. ...

Expected:
    ...

Observed:
    ...

Root Cause:
    ...

Classification:
    Implementation defect
    Model defect
    Test defect
    Undetermined

Reproduction:
    command / seed / test identifier
```

Never reduce a failure to:

```text
test failed
```

---

# 10. Adversarial Testing

Implement and execute the complete 25-case adversarial set:

```text
1.  normal allocation
2.  overlapping domain
3.  nested domain
4.  out-of-domain allocation
5.  stale authority
6.  authority rotation
7.  revoked authority
8.  duplicate commit
9.  SID reuse after retirement
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
```

The report currently records these as required scenarios; they now need executable evidence rather than merely a checklist.

---

# 11. Concurrency Must Be Real

Do not satisfy the concurrency requirement by serialising every operation.

The model must demonstrate the distinction:

```text
D_A ∩ D_B = ∅
    →
independent allocation is safe
```

versus:

```text
D_A ∩ D_B ≠ ∅
    →
coordination is required
```

At minimum, model concurrent attempts to:

```text
reserve overlapping domains
allocate from shared domains
allocate from independent domains
```

The report must state precisely what concurrency is modelled.

If the implementation is single-threaded but uses an explicit interleaving/state-exploration model, that is acceptable for the reference machine.

If so, explain that this is **concurrency model checking**, not physical concurrent execution.

---

# 12. Authority Generation Testing

Explicitly test:

```text
Authority A, generation 1
    ↓
rotate
    ↓
Authority A, generation 2
```

Then attempt allocation from:

```text
A,generation=1
```

after generation 2 becomes authoritative.

Expected:

```text
REJECT
```

Also verify that existing SIDs allocated under generation 1 remain historically valid.

The test must demonstrate:

```text
generation fencing
≠
identity mutation
```

---

# 13. Snapshot and Recovery

Implement the smallest mechanism needed to demonstrate:

```text
H_before ⊆ H_after
```

for durable history.

Test:

```text
allocate A
snapshot S1

allocate B
snapshot S2

restore S1

attempt allocate B again
```

The second allocation must be rejected if B's historical allocation was committed before the snapshot restore.

If the current implementation cannot guarantee this, do not patch around the test.

Report the architectural problem.

---

# 14. Transaction Idempotence

Test:

```text
Commit(T1,SID1)
Commit(T1,SID1)
Commit(T1,SID1)
```

Expected:

```text
one allocation
one historical identity
one semantic result
```

Then test:

```text
Commit(T1,SID1)
Commit(T2,SID1)
```

and determine the required behaviour.

Do not assume transaction identity and SID identity are interchangeable.

---

# 15. Historical Non-Reuse

Test all relevant lifecycle paths:

```text
ALLOCATED
    ↓
BOUND
    ↓
ACTIVE
    ↓
RETIRED
```

Then attempt to allocate the retired coordinate.

Expected:

```text
REJECT
```

Also test:

```text
allocated but never bound
```

The coordinate must remain historically consumed.

---

# 16. Provenance

The cryptographic implementation may remain a reference abstraction at this stage, consistent with the current report's stated limitation.

However, the reference machine must still verify the logical provenance rules:

```text
Genesis
 ↓
Root
 ↓
Authority
 ↓
Domain
 ↓
Allocation
 ↓
SID
```

Test:

```text
valid chain
broken chain
wrong parent
wrong domain
wrong authority
wrong generation
tampered allocation
```

The implementation must distinguish:

```text
cryptographically valid
```

from:

```text
semantically legitimate
```

Do not collapse these concepts.

---

# 17. Binding and Manifestation

Test:

```text
Allocate SID
```

without:

```text
Bind SID
```

The SID remains historically allocated.

Then test:

```text
SID → runtime handle A
SID → runtime handle B
```

after simulated migration/restart.

The canonical SID must remain unchanged.

---

# 18. Deterministic / Derived Allocation

If deterministic allocation has been implemented, attack it.

Test:

```text
same input → same SID
different inputs → different SIDs
derived SID outside domain
derived SID already historically allocated
```

A deterministic function is not automatically an allocation authority.

Verify that domain policy explicitly authorises the mechanism.

If this is not implemented yet, document it as deferred rather than inventing a partial implementation.

---

# 19. Safety / Liveness / Efficiency

The verification report must distinguish:

### Safety

Nothing invalid occurs.

### Liveness

Valid operations eventually succeed when capacity and authority exist.

### Efficiency

The system performs acceptably.

Do not use performance measurements as evidence of correctness.

---

# 20. Required Development Reports

Produce the following reports as implementation proceeds.

## Report A — Implementation Status

Include:

```text
repository integration
files changed
reference machine components
implemented events
implemented invariants
test infrastructure
known gaps
```

---

## Report B — Verification Matrix

For I001–I016:

```text
implementation
test
property
coverage
status
```

---

## Report C — Exhaustive Exploration Report

Include:

```text
N
state count
transition count
trace depth
pruning
coverage
invariant results
execution time
memory
unexplored state classes
```

Be precise about what "exhaustive" means.

---

## Report D — Adversarial Test Report

For each of the 25 scenarios:

```text
scenario
result
invariants exercised
failure, if any
reproduction
```

---

## Report E — Failure / Counterexample Report

Every discovered defect gets a reproducible trace.

Do not suppress failures.

A counterexample is a valuable output of this milestone.

---

## Report F — Crash / Recovery Report

Include:

```text
reservation crash
post-commit crash
lost acknowledgement
snapshot rollback
authority recovery
stale authority recovery
```

---

## Report G — Concurrency Report

Explicitly demonstrate:

```text
disjoint domain concurrency
shared domain concurrency
overlapping delegation race
allocation race
```

and state what coordination is required in each case.

---

## Report H — IAM Architecture Review

At the end of the phase answer:

```text
Is the algebra internally consistent?

Is root-scoped uniqueness structurally guaranteed?

Is delegation non-overlapping?

Is authority rotation safe?

Is stale authority fenced?

Is historical allocation monotonic?

Is snapshot recovery safe?

Are transactions idempotent?

Can independent domains allocate without coordination?

Is SID correctly separated from semantics?

Is SID correctly separated from manifestation?

Are there hidden assumptions?

Which assumptions remain unverified?

What must change before SID-001?
```

---

# 21. Do Not Conceal Architectural Defects

If implementation exposes a flaw in IAM-001, do not merely modify the code until tests pass.

Determine whether the problem is:

```text
implementation error
formal-model error
invariant error
missing invariant
ambiguous specification
```

If IAM-001 itself is wrong, propose a precise amendment.

Do not silently change the model.

---

# 22. No Premature Optimisation

Do not yet optimise:

```text
historical storage
prefix compression
radix indexes
128-bit representation
production persistence
network protocol
distributed allocator
cryptographic wire format
```

These are downstream concerns.

The reference machine must first establish semantic correctness.

---

# 23. Exit Criteria

Do not declare IAM-RM-001 verified until the evidence supports the claim.

The desired result is:

```text
✓ executable reference machine
✓ executable invariants
✓ exhaustive N=8 exploration where claimed
✓ 25 adversarial scenarios executed
✓ crash/recovery tested
✓ snapshot safety tested
✓ transaction idempotence tested
✓ generation fencing tested
✓ concurrency semantics tested
✓ provenance tested
✓ binding/manifestation separation tested
✓ reproducible counterexamples for every failure
✓ no unresolved critical invariant violations
```

If this cannot be achieved, report:

```text
WHAT FAILED
WHY IT FAILED
WHETHER THE MODEL OR IMPLEMENTATION IS WRONG
WHAT EVIDENCE EXISTS
WHAT MUST CHANGE
```

Do not claim completion merely because the build and conventional tests pass.

---

# 24. Final Deliverable

At the end of this phase produce:

```text
IAM-RM-001 Implementation & Verification Report
```

containing:

1. Executive Summary
2. Repository Integration
3. Implementation
4. Formal State Machine
5. Invariant Matrix
6. Exhaustive Exploration
7. Adversarial Testing
8. Concurrency
9. Crash/Recovery
10. Snapshot Safety
11. Provenance
12. Historical Non-Reuse
13. Transaction Semantics
14. Binding / Manifestation
15. Counterexamples
16. Performance Observations
17. Architectural Findings
18. Required IAM-001 Changes
19. Open Questions
20. Recommendation on Readiness for SID-001
21. Files Changed
22. Commands Used to Reproduce Verification

---

# 25. Final Instruction to the Agent

The objective of this phase is **not to prove that the existing design is correct**.

The objective is to determine whether it is correct.

Actively try to break:

```text
domain disjointness
authority fencing
allocation containment
allocation injectivity
historical monotonicity
non-reuse
snapshot safety
transaction idempotence
provenance
contextual verification
identity/manifestation separation
```

If the architecture survives, we will have evidence for proceeding to SID-001.

If it does not survive, the counterexample becomes the input to the next architectural revision.

**Do not proceed to production SID encoding until this phase has produced sufficient evidence that IAM-001 is sound.**
