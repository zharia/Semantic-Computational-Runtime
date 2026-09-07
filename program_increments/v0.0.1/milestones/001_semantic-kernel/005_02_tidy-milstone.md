# SCR DEVELOPMENT AGENT — MILESTONE 005

## Representation Preservation and Executable Equivalence

**Repository:** `https://github.com/zharia/Semantic-Computational-Runtime`

**Working area:** `program_increments/v0.0.1/`

**Primary objective:** Resolve every outstanding architectural, semantic, representation, verification, and documentation issue identified in Milestone 004 and establish a **fully verified semantic-to-executable representation path**.

---

# 0. EXECUTION DIRECTIVE

You are operating as the implementation and verification agent for the Semantic Computational Runtime (SCR).

This is **not** an exploratory milestone.

Do not merely analyse problems.

Do not document unresolved problems as future work.

Do not mark partial implementations as PASS.

Do not create “provisional” architectural decisions and leave their consequences unresolved.

Do not add speculative abstractions.

Do not introduce a custom SCR MLIR dialect unless the acceptance criteria below prove that it is unavoidable.

Your responsibility is to take the repository from the current Milestone 004 state to a state in which **all issues identified below are resolved, implemented, tested, verified, and documented**.

The milestone is not complete until the complete acceptance suite passes.

If an approach fails, change the implementation.

If a representation assumption is invalid, replace it.

If documentation contradicts implementation, reconcile it.

If an existing test is insufficient to prove a required property, add the necessary test.

If a semantic distinction is required by the contract, implement that distinction rather than collapsing it into a convenient machine representation.

---

# 1. FIRST: INSPECT THE ACTUAL REPOSITORY

Before modifying anything:

1. Inspect the complete repository structure.

2. Read:

   * `README.md`
   * `program_increments/v0.0.1/104_golden-path.md`
   * `program_increments/v0.0.1/105_gp_implementation_contract.md`
   * `program_increments/v0.0.1/106_semantic_kernel_contract.md`
   * all relevant files under `seed/`
   * all relevant Lean sources
   * all relevant Mojo sources under `lib/`
   * the Reference Executor
   * all relevant tests
   * every file under `program_increments/v0.0.1/reports/003/`
   * every file under `program_increments/v0.0.1/reports/004/`
   * the canonical MLIR artifact created by 004.

3. Establish the actual current build/test baseline.

Run at minimum:

```text
lake build SCRFormal
```

and the complete existing test suite.

Record actual results.

Do not rely on the text of previous milestone reports when the repository provides executable evidence.

---

# 2. AUTHORITATIVE ARCHITECTURAL ORDER

Preserve this authority hierarchy:

```text
Semantic Field
        ↓
Semantic Contract
        ↓
Semantic Model
        ↓
Lean Formalisation
        ↓
Mojo Semantic Implementation
        ↓
Reference Executor
        ↓
Semantic Equivalence
        ↓
Canonical Representation
        ↓
MLIR
        ↓
Lowering
        ↓
Executable Representation
        ↓
Observation
```

The meaning of a computation originates in the semantic layer.

MLIR is a representation.

LLVM is a representation/lowering target.

Memory addresses are representations.

Storage locations are representations.

Function symbols are representations.

`index`, `i32`, `i64`, `f32`, `f64`, `memref`, pointers, SSA values, symbols, etc. are representations.

None of these may silently become semantic definitions.

---

# 3. REQUIRED OUTCOMES

Milestone 005 must establish all of the following:

1. Constraint failure has explicit semantic meaning.
2. Constraint failure is distinguishable from successful no-op.
3. SemanticTime is not defined by MLIR `index`.
4. State is not defined as `memref`.
5. Identity is independent of function symbols or physical representation.
6. Transformation semantics are distinguished from physical mutation.
7. Entity definition, entity type, entity instance, and representation metadata are clearly distinguished.
8. Semantic metadata and semantic meaning are not conflated.
9. Provenance is represented sufficiently to establish semantic-to-representation traceability.
10. Relationships have a tested semantic representation.
11. Multiple entities can coexist without identity/state ambiguity.
12. The canonical representation can actually be lowered.
13. The lowered representation can actually execute.
14. Executed representation can be compared against the Reference Executor.
15. Representation equivalence is demonstrated rather than inferred from parsing.
16. Existing MLIR mechanisms remain the default unless an explicit semantic requirement proves otherwise.
17. No speculative SCR dialect is introduced.
18. All documentation accurately reflects what is actually proven.
19. No known milestone-scoped issue remains unresolved.
20. The milestone has a reproducible end-to-end verification procedure.

---

# 4. FIX CONSTRAINT SEMANTICS

## 4.1 Establish the semantic distinction

SCR must explicitly distinguish:

```text
successful transformation
successful transformation producing unchanged state
constraint violation
```

In particular:

```text
ConstraintViolation ≠ NoOp
```

A constraint violation must not silently become “do nothing”.

The semantic contract must specify:

```text
input state
        ↓
attempt transformation
        ↓
constraint evaluation
        ↓
either:
    success → resulting state
or:
    failure → ConstraintViolation
```

On constraint failure:

* authoritative state must remain unchanged;
* semantic time/logical step must remain unchanged unless the contract explicitly requires otherwise;
* the failure must remain observable to the caller;
* the failure must be represented in the executable path;
* the Reference Executor, Mojo implementation, Lean model, and MLIR execution must agree.

## 4.2 Formalise

Add Lean definitions/theorems sufficient to prove:

```text
constraint_failure_preserves_state
constraint_failure_preserves_time
constraint_failure_is_observable
successful_noop_is_distinct_from_failure
```

Use the actual existing SCR abstractions where possible.

Do not create parallel semantic models merely to satisfy these theorem names.

## 4.3 Mojo

Implement the same distinction.

Do not implement:

```text
if invalid:
    do nothing
```

if that loses the failure semantics.

## 4.4 Reference Executor

Implement exactly the same semantic contract.

## 4.5 MLIR

Represent failure explicitly.

The representation may use existing MLIR mechanisms.

Possible mechanisms include explicit status/result values, structured control flow, or another standard mechanism.

Choose the smallest representation that preserves:

* success/failure;
* state;
* time;
* observation;
* control flow semantics.

Do not invent `scr.constraint_fail` merely because it is convenient.

## 4.6 Required test

Demonstrate:

```text
initial state = 5

increment(-10)

semantic result = ConstraintViolation
state = 5
logical_step unchanged
```

and separately:

```text
initial state = 5

successful transformation producing 5

semantic result = success
state = 5
```

The two outcomes must be observably distinguishable.

---

# 5. FIX SEMANTIC TIME REPRESENTATION

The previous report incorrectly treated MLIR `index` as if it were inherently SemanticTime.

Correct this throughout the implementation and documentation.

## 5.1 Semantic contract

SemanticTime must remain a semantic type/concept.

Its contract must specify its actual semantic properties independently of machine representation.

At minimum determine:

* ordering;
* equality;
* advancement;
* admissible values;
* determinism;
* relationship to logical steps.

## 5.2 Representation

An integer-like MLIR representation may be used for the current witness **only as a representation choice**.

Do not define:

```text
SemanticTime = index
```

Instead establish:

```text
SemanticTime
    ↓
representation mapping
    ↓
machine representation
```

with the mapping explicitly documented.

The representation must be replaceable without changing semantic identity.

## 5.3 Verification

Add representation tests demonstrating that SemanticTime's semantics are preserved independently of the selected machine type.

Do not claim `index` itself is semantic time.

---

# 6. FIX STATE REPRESENTATION

Correct the assertion:

```text
memref = semantic state
```

to the proper model:

```text
Semantic State
        ↓
physical manifestation
        ↓
memref / storage / other representation
```

For the Counter witness, a `memref<1xi32>` may remain the chosen physical manifestation.

But the semantic state must remain independently defined.

## Required property

Demonstrate:

```text
semantic state identity
        ≠
physical storage identity
```

and:

```text
same semantic state
        can
different physical representation
```

without changing semantic meaning.

---

# 7. FIX IDENTITY INDEPENDENCE

This is mandatory.

Do not treat:

```text
MLIR function symbol
```

as the semantic identity.

The semantic entity must possess an identity independent of:

* function name;
* SSA value;
* memory address;
* storage location;
* process;
* device;
* representation.

## Required witness

Create a test in which the same semantic entity is represented through two distinct physical manifestations.

For example:

```text
semantic entity:
    identity = "c1"

representation A:
    symbol/storage A

representation B:
    symbol/storage B
```

Both must resolve to:

```text
Identity("c1")
```

The semantic identity must remain unchanged.

Also demonstrate that changing the representation identifier does not create a new semantic entity.

## Lean

Formalise the identity-independence property.

## Mojo

Ensure the semantic API does not derive identity from physical storage.

## Reference Executor

Ensure the same.

## MLIR

Carry the semantic identity as representation metadata or another appropriate representation mechanism.

Do not make the symbol itself the authority.

---

# 8. FIX TRANSFORMATION SEMANTICS

Explicitly separate:

```text
semantic transformation
```

from:

```text
physical mutation
```

The semantic model may define:

```text
T : State → State'
```

as a mathematical mapping.

The Mojo implementation may mutate physical storage.

These are not contradictory.

Document this distinction clearly.

The representation analysis must no longer describe the physical `memref.store` itself as the semantic transformation.

Instead:

```text
Semantic Transformation
        ↓
implementation
        ↓
physical mutation
```

The implementation must be shown to realise the semantic mapping.

---

# 9. RESOLVE ENTITY DEFINITION / TYPE / INSTANCE TERMINOLOGY

Review all current usage of:

* Entity Definition
* Entity Type
* Entity Instance
* entity metadata
* semantic entity
* physical representation

Establish precise terminology.

At minimum:

```text
Entity
    = semantic identifiable participant

Identity
    = persistent semantic reference

Entity Definition
    = semantic description of admissible structure/type-level requirements

Entity Instance
    = concrete semantic entity possessing identity and state/value structure

Representation
    = physical/compiler manifestation of the semantic entity
```

Do not introduce unnecessary ontology.

Do not expand the entity system beyond what is necessary for this milestone.

But the terminology must be internally consistent across:

* seed;
* specs;
* Lean;
* Mojo;
* Reference Executor;
* tests;
* reports.

---

# 10. REPRESENTATION CONTRACT

Create or update the representation contract so that it explicitly states:

> A representation is correct when it preserves every semantic property required by the source contract at the boundary being verified.

For every semantic component used in the witness, document:

```text
semantic concept
↓
required semantic properties
↓
chosen representation
↓
representation invariants
↓
verification method
```

At minimum cover:

* Identity
* Entity
* Entity Definition
* Entity Instance
* Value
* State
* Transformation
* Constraint
* Context
* SemanticTime
* Observation
* Relationship
* Provenance

Do not confuse:

```text
“encoded in the artifact”
```

with:

```text
“semantically preserved through compilation”
```

---

# 11. ADD PROVENANCE

SCR's representation path must be traceable.

Establish sufficient provenance to answer:

```text
Which semantic definition produced this representation?

Which entity does this representation correspond to?

Which transformation does this operation realise?

Which semantic contract governs it?

Which representation decision was made?

Which verification evidence supports the representation?
```

Use standard MLIR mechanisms wherever possible.

Provenance may be represented through attributes, symbol references, metadata, or another standard mechanism.

Do not invent a custom dialect solely for provenance.

The representation must allow an auditor/developer to trace the canonical artifact back to the semantic witness.

---

# 12. ADD MULTIPLE-ENTITY WITNESS

Extend the Counter witness from:

```text
Counter c1
```

to:

```text
Counter c1
Counter c2
```

with independent identities and state.

For example:

```text
c1 = 5
c2 = 10
```

Apply transformations independently.

Demonstrate:

```text
transform(c1)
```

does not mutate:

```text
c2
```

and vice versa.

Verify:

* identity;
* state ownership;
* transformation targeting;
* observation;
* logical time;
* constraints;
* determinism.

Do this consistently in:

* Lean;
* Mojo;
* Reference Executor;
* MLIR;
* executable representation.

---

# 13. ADD RELATIONSHIP WITNESS

Introduce the smallest meaningful relationship.

Example:

```text
c1 --relates_to--> c2
```

Do not create a custom MLIR relationship operation unless necessary.

First determine the minimum semantic information required to preserve:

* source identity;
* target identity;
* relationship identity/type;
* relationship validity;
* relationship direction if applicable;
* observation.

The representation must allow the relationship to be reconstructed or observed semantically.

This is a representation-preservation test, not an excuse to design a graph dialect.

---

# 14. ACTUAL MLIR LOWERING

The previous milestone stopped at:

```text
parse
verify
```

That is insufficient.

The canonical MLIR witness must now be taken through an actual lowering pipeline.

At minimum:

```text
canonical MLIR
        ↓
MLIR verification
        ↓
lowering
        ↓
executable representation
```

Use standard MLIR/LLVM facilities wherever possible.

Determine the exact available toolchain in the repository/environment rather than assuming commands exist.

Document the actual commands used.

---

# 15. ACTUAL EXECUTION

The lowered representation must execute.

The execution must produce observable results.

At minimum demonstrate:

```text
initial semantic state
        ↓
represented computation
        ↓
execution
        ↓
observable state/result
```

The output must be captured in a machine-checkable form.

Do not rely on visual inspection of console output.

---

# 16. DIFFERENTIAL EXECUTION VERIFICATION

This is the critical acceptance test.

Run the same semantic workload through:

```text
Lean semantic model
Mojo semantic implementation
Reference Executor
MLIR representation
lowered executable representation
```

Compare semantic results, not raw physical representations.

The comparison must cover at minimum:

* identity;
* state;
* transformation result;
* constraint outcome;
* logical time;
* context;
* observation;
* relationships;
* determinism.

Physical differences are acceptable.

Semantic differences are not.

---

# 17. CANONICAL REPRESENTATION MUST NOT BE THE SOURCE OF MEANING

The implementation must preserve the authority ordering:

```text
Semantic Contract
        ↓
Semantic Model
        ↓
Representation
```

not:

```text
MLIR
        ↓
infer semantics
```

The canonical MLIR artifact must therefore be derivable from the semantic witness.

Where practical, establish a reproducible generation process.

Do not hand-author a canonical MLIR artifact and then call it canonical merely because it parses.

---

# 18. CUSTOM DIALECT PROHIBITION

Do not create a custom SCR MLIR dialect during this milestone unless all of the following are demonstrated:

1. Existing MLIR mechanisms cannot express a required semantic property.
2. The missing property is genuinely semantic rather than an implementation convenience.
3. The property cannot be preserved through attributes, symbols, standard operations, types, regions, or another existing mechanism.
4. The limitation is demonstrated with a failing concrete witness.
5. The smallest custom extension is clearly specified.
6. The extension has a semantic contract independent of implementation.

If these conditions are not met:

**DO NOT CREATE A CUSTOM DIALECT.**

The current default remains:

```text
standard MLIR
+
explicit semantic metadata/provenance
```

---

# 19. REMOVE INCORRECT OR OVERSTATED CLAIMS

Search the repository for claims equivalent to:

```text
memref is semantic state
index is semantic time
function symbol is semantic identity
constraint guard is equivalent to constraint failure
MLIR parsing proves semantic preservation
MLIR verification proves semantic preservation
semantic information survives lowering
```

Correct every occurrence.

The documentation must distinguish:

```text
parsed
verified
represented
lowered
executed
semantically equivalent
```

These are different verification claims.

---

# 20. RECONCILE THEOREM / TEST COUNTS

Review Milestone 004's inconsistent theorem count.

The final report must provide an unambiguous accounting of:

* Lean theorem count;
* Mojo test count;
* Reference Executor test count;
* equivalence test count;
* MLIR verification tests;
* executable representation tests;
* end-to-end tests.

Do not mix build-job counts with test counts.

Every number must be reproducible.

---

# 21. REQUIRED VERIFICATION MATRIX

Create a machine-readable or clearly structured verification matrix:

| Semantic Property  | Lean | Mojo | Reference Executor | MLIR Representation | Lowered Execution | Differential Equivalence |
| ------------------ | ---- | ---- | ------------------ | ------------------- | ----------------- | ------------------------ |
| Identity           | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |
| Entity Definition  | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |
| Entity Instance    | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |
| Value              | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |
| State              | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |
| Transformation     | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |
| Constraint         | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |
| Constraint Failure | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |
| SemanticTime       | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |
| Context            | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |
| Observation        | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |
| Multiple Entities  | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |
| Relationship       | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |
| Provenance         | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |
| Determinism        | PASS | PASS | PASS               | PASS                | PASS              | PASS                     |

**Every cell must be PASS before the milestone can be declared complete.**

If a row is not applicable, modify the witness so that it becomes applicable.

Do not leave cells as:

```text
N/A
Deferred
Partial
Provisional
Future
Not yet
```

for the required scope.

---

# 22. REQUIRED END-TO-END WITNESS

The final canonical witness must contain at least:

```text
CounterDefinition
        ↓
Counter c1
Counter c2
        ↓
initial state
        ↓
relationship(c1,c2)
        ↓
valid transformation
        ↓
constraint-failure transformation
        ↓
observation
        ↓
logical time advancement
        ↓
canonical representation
        ↓
MLIR
        ↓
lowering
        ↓
execution
        ↓
semantic observation
```

The same semantic scenario must be executable through:

```text
Reference Executor
Mojo
MLIR-derived executable
```

and produce semantically equivalent results.

---

# 23. REFERENCE EXECUTOR ROLE

The Reference Executor remains the semantic oracle.

Do not make MLIR the oracle.

Do not modify the semantic contract to match an incorrect MLIR representation.

If MLIR execution disagrees with the Reference Executor:

1. determine which implementation is incorrect;
2. use the semantic specification and Lean model as authority;
3. correct the incorrect implementation;
4. add a regression test.

Never weaken the semantic contract simply to make representations agree.

---

# 24. LEAN ROLE

Lean is the formal semantic verification boundary.

Use Lean to prove the semantic properties that matter.

Do not turn Lean into a second runtime.

Do not implement a duplicate runtime architecture in Lean merely to increase theorem counts.

The objective is **semantic assurance**, not theorem-count maximisation.

---

# 25. MOJO ROLE

Mojo remains the primary implementation language.

The Mojo semantic kernel must implement the semantic contracts.

Do not make Mojo dependent on the Reference Executor.

Do not make Mojo derive semantics from MLIR.

The direction is:

```text
semantic contract
        ↓
Mojo implementation
```

not:

```text
MLIR
        ↓
Mojo
```

---

# 26. MLIR ROLE

MLIR is the computational representation/lowering substrate.

Do not promote it to semantic authority.

The canonical representation must be:

* inspectable;
* reproducible;
* semantically traceable;
* executable;
* verifiable.

---

# 27. TESTING REQUIREMENTS

After implementation, run:

```text
lake build SCRFormal
```

Run the entire test suite.

Run every Reference Executor test.

Run every Mojo test.

Run every equivalence test.

Run every MLIR verification test.

Run every lowering test.

Run every executable representation test.

Run the complete end-to-end differential test.

No known failing tests are acceptable.

No ignored tests are acceptable.

No expected-failure tests are acceptable unless they are testing explicit semantic failure behaviour.

---

# 28. REPORT 005

Create:

```text
program_increments/v0.0.1/reports/005/
```

At minimum include:

```text
verification_report_milestone.md
representation_preservation.md
```

The report must contain:

1. Objective.
2. Starting repository state.
3. Changes made.
4. Semantic contract changes.
5. Lean changes.
6. Mojo changes.
7. Reference Executor changes.
8. Representation changes.
9. MLIR changes.
10. Lowering pipeline.
11. Executable path.
12. Differential verification.
13. Complete verification matrix.
14. Exact test/build commands.
15. Exact results.
16. Provenance mechanism.
17. Identity-independence evidence.
18. Constraint-failure evidence.
19. SemanticTime representation evidence.
20. State representation evidence.
21. Relationship evidence.
22. Multiple-entity evidence.
23. Final architectural conclusions.

Do not include a “Future Work” section containing unresolved items from this milestone.

Do not use “known limitation”, “deferred”, “provisional”, or “outstanding issue” to avoid completing a required item.

If something genuinely lies outside this milestone's scope, explicitly explain why it is outside the defined acceptance contract rather than using that language for a failed requirement.

---

# 29. DOCUMENTATION QUALITY GATE

Before completion:

Search all SCR documentation touched by the milestone for contradictions.

Ensure terminology is consistent.

Ensure every claim of:

```text
verified
proven
equivalent
preserved
canonical
executable
```

has corresponding executable or formal evidence.

Do not use these terms rhetorically.

---

# 30. FINAL ACCEPTANCE GATE

Milestone 005 may be declared:

```text
COMPLETE / PASS
```

only if all of the following are true:

### Semantic

* [ ] Constraint failure has explicit semantics.
* [ ] Constraint failure ≠ successful no-op.
* [ ] State preservation on failure is verified.
* [ ] Time preservation on failure is verified.
* [ ] Failure is observable.
* [ ] SemanticTime is representation-independent.
* [ ] State is representation-independent.
* [ ] Identity is representation-independent.
* [ ] Transformation semantics are distinct from physical mutation.
* [ ] Entity terminology is consistent.
* [ ] Relationships are semantically represented.
* [ ] Multiple entities are supported.
* [ ] Provenance is represented.

### Formal

* [ ] Lean build passes.
* [ ] Required semantic properties are formally proved.
* [ ] No semantic property relies solely on a test.

### Mojo

* [ ] Mojo kernel implements the semantic contract.
* [ ] Mojo tests pass.
* [ ] Multiple entities work.
* [ ] Relationships work.
* [ ] Constraint failure works.
* [ ] Observation works.
* [ ] Time semantics work.

### Reference Executor

* [ ] Reference Executor implements the complete witness.
* [ ] Reference Executor is semantically aligned with Lean.
* [ ] All relevant tests pass.

### Representation

* [ ] Canonical representation is derived from semantic structure.
* [ ] Representation metadata is not confused with semantics.
* [ ] Identity does not depend on symbols/storage.
* [ ] State does not depend on `memref`.
* [ ] Time does not depend on `index`.
* [ ] Constraint failure is represented explicitly.
* [ ] Relationships are represented.
* [ ] Provenance is represented.
* [ ] Representation is inspectable.

### Compilation

* [ ] Canonical MLIR parses.
* [ ] Canonical MLIR verifies.
* [ ] Canonical MLIR lowers.
* [ ] Lowered representation executes.
* [ ] Execution produces machine-checkable observations.

### Equivalence

* [ ] Lean semantics agree with Reference Executor.
* [ ] Mojo agrees with Reference Executor.
* [ ] MLIR representation agrees with Reference Executor.
* [ ] Lowered executable agrees with Reference Executor.
* [ ] Constraint failure agrees.
* [ ] Multiple entities agree.
* [ ] Relationship semantics agree.
* [ ] Observation agrees.
* [ ] Time agrees.
* [ ] Determinism agrees.

### Architecture

* [ ] No speculative custom SCR dialect exists.
* [ ] Any custom representation mechanism, if introduced, is justified by a concrete semantic requirement.
* [ ] Semantic authority remains above representation.
* [ ] Reference Executor remains the semantic oracle.
* [ ] Mojo remains the primary implementation.
* [ ] Lean remains the formal verification boundary.
* [ ] MLIR remains a representation/lowering substrate.

### Documentation

* [ ] All Milestone 004 overstatements are corrected.
* [ ] The theorem/test count is internally consistent.
* [ ] Every PASS claim has evidence.
* [ ] The verification matrix is complete.
* [ ] No milestone-scoped issue remains unresolved.

---

# 31. STOP CONDITION

Do not stop after producing a report.

Do not stop after tests pass at the semantic-kernel level.

Do not stop after MLIR parses.

Do not stop after MLIR verifies.

Do not stop after producing a plausible representation.

Do not stop after proving Mojo ↔ Reference Executor equivalence.

The milestone ends only after:

```text
Semantic Definition
        ↓
Semantic Instance
        ↓
Semantic State
        ↓
Semantic Transformation
        ↓
Constraint / Failure
        ↓
Observation
        ↓
Lean Verification
        ↓
Mojo Implementation
        ↓
Reference Executor
        ↓
Semantic Equivalence
        ↓
Canonical Representation
        ↓
MLIR Verification
        ↓
MLIR Lowering
        ↓
Executable Representation
        ↓
Execution
        ↓
Observation
        ↓
Differential Semantic Equivalence
        ↓
COMPLETE
```

All required acceptance cells must be PASS.

---

# 32. FINAL RESPONSE FORMAT

When finished, provide:

```text
MILESTONE 005: COMPLETE

Repository:
<commit/hash>

Build:
<exact result>

Tests:
<exact result>

Lean:
<exact result>

Mojo:
<exact result>

Reference Executor:
<exact result>

MLIR:
<exact result>

Lowering:
<exact result>

Executable representation:
<exact result>

Differential equivalence:
<exact result>

Verification matrix:
100% PASS

Custom SCR dialect:
NOT REQUIRED
```

Then provide a concise list of the concrete files changed and the exact commands used to reproduce the verification.

Do not claim completion if any required acceptance criterion is not satisfied.

**The objective is not to produce another promising milestone. The objective is to close the representation boundary rigorously and leave the repository in a clean, internally consistent, fully verified state.**
