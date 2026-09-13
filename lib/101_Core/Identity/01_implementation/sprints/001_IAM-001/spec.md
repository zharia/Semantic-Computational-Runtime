# SCR Development Agent Instruction

## IAM-001 Identity Address Space Model + IAM-RM-001 Reference Machine

You are working in the existing **Semantic Computational Runtime (SCR)** repository.

Your task is to implement and formally verify the first executable reference model of the SCR Identity Address Space architecture.

This is **not yet a production Semantic Identifier implementation**.

Do not prematurely select or lock the final SID bit layout, textual encoding, or production allocator.

The immediate objective is to establish whether the IAM architecture is internally coherent under exhaustive and adversarial testing.

---

# 1. Mission

Implement the following development milestone:

> **IAM-001 — SCR Identity Address Space Model**
>
> **IAM-RM-001 — Identity Address Space Reference Machine**

The implementation must provide a small, deterministic, executable model of:

```text
Genesis
  ↓
Root Authority
  ↓
Identity Address Space
  ↓
Allocation Domain
  ↓
Authority
  ↓
Allocation
  ↓
SID / Coordinate
  ↓
Semantic Binding
  ↓
Manifestation
```

The implementation must test the correctness of:

```text
Topology       → uniqueness
Allocation     → local injectivity
Authority      → permission
Cryptography   → provenance
History        → non-reuse
Context        → resolution
Semantic Graph → meaning
Manifestation  → physical/runtime identity
```

The reference model must deliberately be much smaller and simpler than a production implementation.

---

# 2. First Rule — Inspect Before Modifying

Before writing code:

1. Inspect the current repository structure.
2. Identify existing SCR identity/semantic/type infrastructure.
3. Identify existing specification conventions.
4. Identify the current domain/library structure.
5. Identify existing test infrastructure.
6. Identify existing formal verification/model-checking infrastructure.
7. Identify whether any existing identity implementation already exists.
8. Identify existing cryptographic abstractions that should be reused.
9. Identify existing graph/domain primitives that should be reused.
10. Identify the correct location for IAM documentation and implementation.

Do not invent a parallel architecture if an appropriate SCR primitive already exists.

The SCR architectural principle remains:

> **Reuse and extend semantic primitives; do not create unnecessary parallel abstractions.**

Before implementation, produce a short repository assessment internally and then record the relevant findings in the first progress report.

---

# 3. Important Architectural Constraints

The following decisions are already established.

## 3.1 SID is not the identity system

Do not implement SID as if it were simply another UUID/ULID replacement.

The architecture is:

```text
Identity System
    ├── Identity Space
    ├── Domains
    ├── Authorities
    ├── Allocation
    ├── Provenance
    ├── History
    ├── Resolution
    └── Binding
            ↓
           SID
```

SID is a coordinate inside this system.

---

## 3.2 Do not adopt ULID

ULID may be used as comparative background only.

Do not implement ULID.

Do not assume timestamp encoding belongs in SID.

Do not assume lexical ordering, temporal ordering and semantic ordering are identical.

---

## 3.3 Do not lock the final SID width

128-bit is currently a candidate, not a decision.

Do not make the reference machine depend upon a 128-bit production representation.

The first model should use:

```text
N = 8
```

giving:

```text
0 ... 255
```

This makes exhaustive state exploration practical.

The architecture must remain capable of later supporting:

```text
96
128
160
192
256
```

or another width if simulation demonstrates that it is preferable.

---

# 4. Formal State Model

Implement the reference state approximately as:

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

Use the existing SCR type/semantic conventions wherever possible.

Do not create unnecessary duplication of concepts already represented elsewhere in SCR.

---

# 5. Identity Space

The reference identity space should support:

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

```text
coordinate_space = [0, 256)
```

The representation may be a simple integer.

This is a reference coordinate, not the final SID encoding.

---

# 6. Domain Model

Implement domains approximately as:

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

```text
[l, h)
```

with:

```text
l < h
```

A committed domain's region is immutable.

Do not silently resize a committed domain.

Expansion must be represented as a new allocation/delegation operation.

---

# 7. Domain Lifecycle

Implement the domain lifecycle:

```text
FREE
  ↓
RESERVED
  ↓
DELEGATED
  ↓
ACTIVE
  ↓
REVOKED
  ↓
RETIRED
```

Do not permit:

```text
RETIRED → FREE
```

for durable identity domains.

Likewise, historical domain information must not be erased merely because the domain is retired or revoked.

---

# 8. Authority Model

Implement an authority abstraction approximately equivalent to:

```text
Authority {
    id
    generation
    state
    credential_reference
}
```

Generation is a fencing mechanism.

For example:

```text
Authority A generation 4
```

becomes:

```text
Authority A generation 5
```

after rotation.

An old process operating with generation 4 must not be permitted to allocate under generation 5.

Do not encode generation into the SID.

---

# 9. Partitioning

Implement partitioning independently from authority delegation.

A parent domain may be partitioned into disjoint child domains.

Required properties:

```text
child ⊆ parent
```

and:

```text
child_i ∩ child_j = ∅
```

for sibling domains.

Do not confuse:

```text
partition
delegation
allocation
```

They are separate operations.

---

# 10. Delegation

Implement hierarchical delegation.

Example:

```text
Root
 ├── Domain A
 │    ├── Authority A
 │    └── Domain A1
 │         └── Authority A1
 │
 └── Domain B
      └── Authority B
```

Arbitrary delegation depth should be supported by the model.

The essential rule is:

```text
child_domain ⊆ parent_domain
```

and sibling domains must remain disjoint.

---

# 11. Allocation

Implement local allocation inside a delegated domain.

The allocator must satisfy:

```text
SID ∈ delegated_domain
```

and local injectivity:

```text
allocate(x1) == allocate(x2)
    ⇒
x1 == x2
```

For durable identity:

```text
SID ∉ historical_allocation_set
```

must hold for a new allocation.

---

# 12. Historical State

Implement an explicit historical allocation structure.

At minimum:

```text
historical_sids
```

must support:

```text
has_ever_been_allocated(sid)
```

The historical set is monotonic:

```text
H(t) ⊆ H(t+1)
```

Retirement does not remove an SID from historical state.

The reference implementation may use a simple set initially.

Do not prematurely optimise it.

Historical compression is a later experiment.

---

# 13. Transaction Model

Implement transaction identity independently from SID identity.

For example:

```text
TransactionId
SID
```

are different concepts.

Transactions must be idempotent.

If:

```text
Commit(T1, SID42)
```

has succeeded, retrying:

```text
Commit(T1, SID42)
```

must not create a second allocation.

Test lost acknowledgement scenarios explicitly.

---

# 14. Reservation Model

Support reservation before durable commit.

Conceptually:

```text
REQUEST
  ↓
VALIDATE
  ↓
RESERVE
  ↓
COMMIT
```

A reservation is not historical allocation.

Therefore:

```text
reserved SID ∉ H
```

until commit.

The model must distinguish:

```text
reservation failure
commit failure
committed allocation
```

---

# 15. Atomicity

Model state transitions as:

```text
T : Σ × Event → Σ | Error
```

If an operation fails:

```text
T(Σ, event) = Error
```

then:

```text
Σ' == Σ
```

No partially applied state is permitted.

This must be explicitly tested.

---

# 16. Crash and Recovery

Implement reference crash/recovery semantics.

At minimum test:

### Case A

Crash during reservation.

Expected:

```text
reservation may disappear
historical allocation unchanged
```

### Case B

Crash after durable commit.

Expected:

```text
allocation remains historical
```

### Case C

Crash after acknowledgement is lost.

Expected:

```text
retry is idempotent
```

### Case D

Restore stale snapshot.

Expected:

```text
historical SID allocations cannot be resurrected
```

---

# 17. Snapshot Safety

Snapshots must not allow the historical allocation set to move backwards.

If:

```text
H2 ⊇ H1
```

then restoring H1 must not permit SIDs from H2 to be allocated again.

Design the smallest mechanism necessary to demonstrate this property.

Do not over-engineer snapshot storage yet.

The reference model is primarily intended to prove semantics.

---

# 18. Provenance

Implement a reference cryptographic provenance abstraction.

The first implementation does not need production cryptographic infrastructure if the repository already has a suitable abstraction.

If no suitable abstraction exists, create a clearly isolated reference interface.

Conceptually:

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

```text
Is this SID attributable to the trusted root?
Was the allocator authorised?
Was the allocator operating under the correct generation?
Was the SID allocated within the delegated domain?
```

Do not embed full certificates into every SID.

Do not turn SID into a capability.

---

# 19. Contextual Verification

Implement verification as conceptually:

```text
verify(context, sid)
```

not:

```text
verify(sid)
```

The context should provide whatever is necessary to interpret the coordinate.

At minimum the reference context should contain:

```text
root
identity_space
geometry
verification policy
history view
```

The SID itself does not have to contain all this information.

---

# 20. Semantic Binding

Implement binding separately from allocation.

Conceptually:

```text
Allocate SID
    ↓
Bind SID → Semantic Entity
    ↓
Manifest Entity
```

Test the case where:

```text
SID allocated
but
semantic binding never occurs
```

The SID remains historically allocated.

It must not become available for reuse.

---

# 21. Manifestation

Do not couple canonical SID identity to runtime handles.

The reference model should demonstrate:

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

The SID must remain unchanged.

This establishes:

```text
Identity survives manifestation.
```

---

# 22. Required Invariants

Implement executable assertions for at least:

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

The invariants should be executable wherever practical.

Avoid documentation-only claims.

---

# 23. Exhaustive Testing

The 8-bit model must support exhaustive exploration of small state spaces.

Where practical, enumerate legal and illegal transition sequences.

The objective is not merely:

```text
unit tests pass
```

but:

```text
no reachable valid state violates the invariants
```

Use the strongest existing testing/model-checking facilities already present in the SCR repository.

If no appropriate framework exists, implement a small deterministic state explorer rather than introducing a large external dependency unnecessarily.

---

# 24. Adversarial Testing

The implementation MUST test at least:

1. normal allocation;
2. overlapping domain;
3. nested domain;
4. out-of-domain allocation;
5. stale authority;
6. authority rotation;
7. revoked authority;
8. duplicate commit;
9. SID reuse after retirement;
10. snapshot rollback;
11. crash during reservation;
12. crash after commit;
13. lost acknowledgement;
14. retry after commit;
15. concurrent sibling delegation;
16. concurrent allocation;
17. malicious allocation outside domain;
18. stale process after key rotation;
19. abandoned domain;
20. exhausted domain;
21. fragmented domain;
22. deep delegation;
23. invalid provenance;
24. corrupted provenance;
25. conflicting deterministic allocation.

---

# 25. Concurrency

The model must explicitly distinguish:

```text
disjoint domains
```

from:

```text
shared domain
```

Expected property:

```text
disjoint domains
    → allocation can proceed independently
```

while:

```text
shared domain
    → coordination is required
```

Do not fake concurrency by simply serialising everything and then claiming decentralised safety.

The model should demonstrate why domain partitioning removes the need for coordination between independent allocators.

---

# 26. Failure Classification

Distinguish:

### Invalid request

Example:

```text
authority attempts allocation outside its domain
```

Expected:

```text
reject
```

This is successful system behaviour.

### Protocol failure

Example:

```text
two honest authorities are permitted to commit overlapping domains
```

Expected:

```text
invariant violation
```

This is a real failure.

The reports MUST distinguish these categories.

---

# 27. Formal Counterexample Reporting

Whenever an invariant fails, report the shortest useful trace.

Example:

```text
Invariant:
    IAM-I002 Domain Disjointness

Initial State:
    Root [0,256)

Trace:
    1. ReserveDomain A [0,128)
    2. CommitDomain A
    3. ReserveDomain B [64,192)
    4. CommitDomain B

Failure:
    [0,128) ∩ [64,192) ≠ ∅
```

Do not simply report:

```text
test failed
```

A counterexample trace is required.

---

# 28. Property-Based Testing

Where the language/tooling permits, add property-based testing.

Generate:

* domain partitions;
* authorities;
* allocation requests;
* authority rotations;
* crashes;
* retries;
* snapshot operations;
* revocations;
* random allocation patterns.

Check all invariants after every transition.

Prefer deterministic seeds for reproducibility.

Record failing seeds.

---

# 29. Reference Model Simplicity

Do not optimise the first implementation prematurely.

The reference implementation should prefer:

```text
clarity
determinism
verifiability
```

over:

```text
throughput
memory optimisation
production cryptography
```

The model is an executable specification.

Production optimisation comes later.

---

# 30. Do Not Implement Yet

Do NOT yet implement:

* final 128-bit SID;
* production SID textual syntax;
* ULID compatibility;
* UUID compatibility;
* distributed production allocator;
* production certificate protocol;
* production persistence engine;
* production cryptographic key-management infrastructure;
* prefix-compressed production index;
* final historical compression;
* production network protocol.

Those are downstream work.

---

# 31. Documentation Required

Create/update the appropriate SCR documentation following the repository's existing conventions.

At minimum document:

```text
IAM-001
IAM-RM-001
```

The documentation must distinguish:

```text
Definition
Invariant
Implementation
Experiment
Result
Open Question
```

Do not present experimental observations as architectural facts.

Do not present implementation choices as universal requirements.

---

# 32. Repository Integration

Integrate IAM with the existing SCR architecture rather than creating an isolated project.

Determine the appropriate existing domain/module/library for:

```text
identity
semantic identity
graph
cryptography
runtime
formalisation
```

If an appropriate location does not exist, document the proposed location before introducing it.

Every new SCR library/directory must follow the repository's existing documentation conventions, including the appropriate specification/status/graph files where required.

Do not create arbitrary top-level structure.

---

# 33. Tests Must Be First-Class

The implementation is not complete when the model exists.

It is complete only when:

```text
implementation
+
invariants
+
exhaustive tests
+
adversarial tests
+
counterexample reporting
+
documentation
```

are present.

---

# 34. Feedback Report 1 — Initial Repository Assessment

Before substantial implementation, produce:

## IAM Development Assessment

Include:

### Existing SCR infrastructure

What already exists that IAM can reuse?

### Proposed integration point

Where will IAM-RM-001 live?

### Existing gaps

What does SCR currently lack?

### Risks

Identify architectural risks before implementation.

### Plan

Give the concrete implementation sequence.

Do not make architectural changes merely to satisfy this report.

---

# 35. Feedback Report 2 — Formal Model Report

After implementing the initial model, produce:

## IAM Formal Model Report

Include:

```text
State model
Event model
Transition model
Domain model
Authority model
Allocation model
History model
Provenance model
Binding model
Manifestation model
```

Then explicitly list:

```text
implemented invariants
unimplemented invariants
assumptions
known limitations
```

---

# 36. Feedback Report 3 — Verification Report

After testing, produce:

## IAM Verification Report

Include:

```text
test count
property count
exhaustive state-space coverage
adversarial scenarios
successful invariants
failed invariants
counterexamples
deterministic seeds
```

For each failure include:

```text
Invariant
Trace
Expected
Observed
Root Cause
Proposed Correction
```

Do not hide failures.

A discovered architectural flaw is a successful result of this milestone if it is correctly identified.

---

# 37. Feedback Report 4 — Allocation Geometry Report

After the reference model is stable, perform preliminary experiments comparing:

```text
1. aligned binary intervals / buddy
2. prefix/radix
3. arbitrary aligned intervals
4. hybrid root structured allocation + domain allocator
```

Measure at minimum:

```text
capacity utilisation
fragmentation
stranded capacity
delegation depth
allocation throughput
coordination requirement
historical compression potential
index implications
```

Do not choose a production geometry based on intuition alone.

Report observed results.

---

# 38. Feedback Report 5 — Architecture Review

Produce a final milestone review:

## IAM-001 Architecture Review

Answer explicitly:

### A.

Does the identity-space algebra remain internally consistent?

### B.

Can uniqueness be demonstrated structurally rather than probabilistically?

### C.

Can authorities be delegated without overlapping allocation rights?

### D.

Does authority rotation preserve identity?

### E.

Does crash recovery preserve historical uniqueness?

### F.

Does snapshot restore preserve historical monotonicity?

### G.

Can independent domains allocate without coordination?

### H.

Can the SID remain non-self-describing?

### I.

Can semantic meaning remain outside the SID?

### J.

Can physical manifestation change without changing identity?

### K.

Are there any hidden assumptions that invalidate the model?

### L.

What must change before SID-001 can be specified?

---

# 39. Mandatory Final Report Structure

At completion, produce one consolidated report with:

```text
# IAM-001 Development Progress Report

## 1. Executive Summary

## 2. Repository Integration

## 3. Implemented Architecture

## 4. State Machine

## 5. Invariants

## 6. Exhaustive Verification

## 7. Adversarial Verification

## 8. Counterexamples

## 9. Crash / Recovery Results

## 10. Concurrency Results

## 11. Provenance Results

## 12. Historical Non-Reuse Results

## 13. Allocation Geometry Experiments

## 14. Performance / Complexity Observations

## 15. Architectural Problems Discovered

## 16. Architectural Decisions Required

## 17. Open Questions

## 18. Recommended Next Milestone

## 19. Files Changed

## 20. Tests Executed
```

---

# 40. Quality Standard

Do not report success merely because:

```text
build passes
tests pass
```

The actual question is:

> **Does the implementation provide evidence that the IAM algebra survives adversarial state transitions?**

The strongest acceptable result is:

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

---

# 41. Architectural Challenge

Actively attempt to falsify the IAM model.

Do not assume the architecture is correct.

Specifically investigate whether any of the following can occur:

```text
two valid authorities obtain overlapping domains

a stale authority allocates after rotation

a snapshot rollback resurrects an SID

a retry creates duplicate allocation

a crash creates ambiguous allocation state

a revoked authority creates apparently valid provenance

a derived allocator creates a collision

historical state becomes inconsistent with domain state

a domain can be silently enlarged

a child domain escapes its parent

semantic binding accidentally becomes identity allocation

manifestation changes accidentally mutate identity

two independent roots accidentally become ambiguous

```

If any are possible, stop and report the problem before proceeding to production design.

---

# 42. Critical Principle

Do not optimise for making the architecture appear correct.

Optimise for finding where it is wrong.

A counterexample is more valuable than a passing test.

The desired development loop is:

```text
Model
  ↓
Implement
  ↓
Attack
  ↓
Find Counterexample
  ↓
Refine Model
  ↓
Re-test
  ↓
Prove / Establish Invariants
  ↓
Only Then Optimise
```

---

# 43. Completion Criteria

IAM-RM-001 is considered complete only when:

* the repository has been inspected;
* the correct SCR integration point has been identified;
* IAM-001 documentation exists;
* the reference state machine exists;
* domains are hierarchical and non-overlapping;
* authorities are generation-fenced;
* allocations are contained and injective;
* historical allocation is monotonic;
* durable SIDs are non-reusable;
* transactions are idempotent;
* crash/recovery semantics are tested;
* snapshot safety is tested;
* provenance is testable;
* semantic binding is separate from allocation;
* manifestation is separate from identity;
* exhaustive N=8 exploration has been attempted;
* adversarial tests have been executed;
* failures have explicit counterexamples;
* allocation geometry experiments have begun;
* all unresolved architectural issues are documented.

Do not declare completion if any of these are merely described but not tested.

---

# 44. Final Instruction

Begin by inspecting the existing SCR repository.

Do not begin by creating a new SID implementation.

Do not begin by selecting 128 bits.

Do not begin by implementing ULID/UUID compatibility.

First establish:

```text
Where does IAM belong in SCR?
What existing primitives can IAM reuse?
What is already implemented?
What is missing?
```

Then implement the smallest possible IAM reference machine.

The intended sequence is:

```text
Repository Inspection
        ↓
Integration Assessment
        ↓
IAM-001 Formalisation
        ↓
IAM-RM-001 Reference Machine
        ↓
Executable Invariants
        ↓
Exhaustive N=8 Exploration
        ↓
Adversarial Testing
        ↓
Crash/Recovery Testing
        ↓
Concurrency Testing
        ↓
Provenance Testing
        ↓
Allocation Geometry Experiments
        ↓
Architecture Review
        ↓
SID-001 Design
```

**Do not skip directly to SID-001.**

The purpose of this milestone is to determine whether the identity-space algebra is actually sound before committing SCR to a concrete identifier representation.

At every stage, prefer falsifiable evidence over architectural assertion.
