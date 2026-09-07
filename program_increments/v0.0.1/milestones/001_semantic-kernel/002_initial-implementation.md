# SCR Development Instruction — Semantic Kernel Milestone Completion

Repository:

`https://github.com/zharia/Semantic-Computational-Runtime`

## Mission

Continue development of the Semantic Computational Runtime (SCR) from the current repository state.

The immediate objective is **not yet MLIR, lowering, CPU execution, rendering, or a custom SCR dialect**.

The objective is to complete the current **Semantic Kernel Milestone** and establish the first coherent, reusable, verified SCR entity definitions.

The intended progression is:

```text
Existing Semantic Specifications
        ↓
104 — Golden Path
        ↓
105 — Golden Path Implementation & Verification Contract
        ↓
106 — Semantic Kernel Contract
        ↓
Specification Reconciliation
        ↓
Lean Formal Semantic Kernel
        ↓
Mojo Semantic Kernel
        ↓
Reference Executor
        ↓
Semantic Equivalence
        ↓
First Canonical Entity Definitions
        ↓
ONLY THEN
        ↓
SCR Representation / MLIR
        ↓
Lowering
        ↓
Provider
        ↓
Runtime
        ↓
Golden Path E2E
```

The governing principle remains:

> **Engineer outward from the Semantic Field.**

And the implementation rule is:

> **Do not implement what has not been semantically defined. Do not formalise what has not been reconciled. Do not represent what does not yet need representation.**

---

# 1. Start by inspecting the repository

Do not assume the repository matches previous instructions.

Inspect the current `master` branch thoroughly, especially:

```text
seed/
docs/
lib/
formal/
runtime/
program_increments/v0.0.1/
```

Also inspect:

```text
lakefile*
formal/
runtime/Reference_Executor/
tests/
examples/
```

Identify the current authoritative definitions and actual implementation state.

In particular, inspect:

* `104_golden-path.md`
* `105_gp_implementation_contract.md`
* `106_semantic_kernel_contract.md`
* the current verification report
* existing `lib/101_Core/...`
* existing Lean definitions
* existing Mojo source
* Reference Executor implementation
* existing tests
* numeric semantics
* identity semantics
* state semantics
* relationship semantics
* transformation semantics
* semantic field definitions
* seed material

Do not trust filenames or previous reports as evidence of implementation.

Inspect the actual source.

---

# 2. Correct the current verification report's Gate 2 and Gate 3 interpretation

The current verification report records:

```text
Gate 2 — Mojo Semantic Kernel — PASS
Gate 3 — Reference Equivalence — PASS
```

while simultaneously stating that:

* the Reference Executor is the only executable implementation;
* there is no separate Mojo semantic implementation in `lib/`;
* there is no Mojo-library-vs-Reference-Executor comparison test.

Therefore the current gate classification is semantically too generous.

Correct this.

The proper distinction is:

```text
Lean formal model
        ↓
Reference Executor
        ↓
PASS
```

versus:

```text
Lean formal model
        ↓
Mojo semantic implementation
        ↓
Reference Executor
        ↓
semantic equivalence
```

The second has not yet been demonstrated.

Do not artificially preserve the existing PASS labels merely because they already appear in the report.

Verification status must describe what has actually been demonstrated.

Update the report when appropriate.

---

# 3. Close Gate 0 — Specification Reconciliation

Before expanding implementation, complete the semantic reconciliation that the current report identifies as partial.

Construct an explicit reconciliation matrix.

At minimum:

| Kernel Concept | Existing Normative Definition | Seed Definition | Lean Definition | Mojo Definition | Reference Executor Definition | Tests | Conflicts | Required Action |
| -------------- | ----------------------------- | --------------- | --------------- | --------------- | ----------------------------- | ----- | --------- | --------------- |
| Identity       |                               |                 |                 |                 |                               |       |           |                 |
| Entity         |                               |                 |                 |                 |                               |       |           |                 |
| Value          |                               |                 |                 |                 |                               |       |           |                 |
| Relationship   |                               |                 |                 |                 |                               |       |           |                 |
| State          |                               |                 |                 |                 |                               |       |           |                 |
| Transformation |                               |                 |                 |                 |                               |       |           |                 |
| Constraint     |                               |                 |                 |                 |                               |       |           |                 |
| Context        |                               |                 |                 |                 |                               |       |           |                 |
| Time           |                               |                 |                 |                 |                               |       |           |                 |
| Observation    |                               |                 |                 |                 |                               |       |           |                 |
| Semantic Field |                               |                 |                 |                 |                               |       |           |                 |

The purpose is not documentation for its own sake.

The purpose is to establish:

1. what each concept means;
2. where that meaning is authoritative;
3. whether the Lean model faithfully captures it;
4. whether the executable implementation faithfully captures it;
5. whether any existing implementation has accidentally invented semantics.

If contradictions exist, resolve them according to the established authority hierarchy.

Do **not** resolve semantic contradictions by simply choosing whatever the current code happens to do.

---

# 4. Establish the first canonical SCR entity definitions

This is the primary development objective of this milestone.

The repository should emerge with the first coherent, reusable semantic definitions for the SCR kernel.

At minimum, establish the canonical semantic concepts:

```text
Entity
Identity
Value
Relationship
State
Transformation
Constraint
Context
Time
Observation
SemanticField
```

However:

**Do not automatically implement these as one large class hierarchy or OO object model.**

The semantic definitions must follow the SCR architecture.

In particular:

* Entity is not synonymous with a Mojo struct.
* Identity is not a memory address.
* Relationship is not a pointer.
* Value is not synonymous with a machine scalar.
* State is not synonymous with runtime memory.
* Transformation is not synonymous with a function pointer.
* Context is not synonymous with process/global environment.
* Observation is not renderer state.
* Semantic Field is not simply a graph container.

The implementation representation is subordinate to the semantic definition.

---

# 5. Use the Semantic Field as the architectural root

The semantic kernel must remain derivable from the Semantic Field.

Use the established conceptual structure:

```text
F = (E, R, T, C, S, K, M)
```

where:

```text
E = entities
R = relationships
T = transformations
C = context
S = state
K = constraints
M = physical manifestations
```

For this milestone, concentrate on:

```text
E
R
T
C
S
K
```

and only establish the abstraction boundary for `M`.

Do not prematurely implement physical manifestation machinery.

The goal is to demonstrate that the kernel can represent meaningful computation *before* physical representation is selected.

---

# 6. Lean remains the semantic verification boundary

Lean must remain concerned with semantic properties rather than becoming a second runtime.

Inspect the existing formalisation before adding anything.

Extend it only where necessary.

At minimum establish appropriate formal definitions/properties for:

* identity persistence;
* entity validity;
* value validity;
* relationship validity;
* state validity;
* transformation validity;
* constraint preservation;
* contextual validity;
* temporal consistency;
* observation non-interference;
* determinism where the semantic contract requires it;
* semantic equivalence where appropriate.

Do not invent arbitrary theorem statements simply to increase the theorem count.

Every theorem should correspond to a meaningful semantic claim in the specifications.

Run:

```bash
lake build SCRFormal
```

after the changes.

A successful Lean build is necessary but not sufficient.

Report:

* what was formalised;
* what was proven;
* what remains axiomatic;
* what remains unformalised;
* what semantic claims still lack verification.

---

# 7. Build the actual Mojo semantic kernel

The current repository reports that the Reference Executor is the only executable implementation.

Now create the smallest proper **Mojo semantic implementation** necessary to instantiate the canonical kernel.

This is not a request to build the SCR runtime.

Do not create a large framework.

Implement only what is justified by the reconciled semantic contracts.

The Mojo layer should provide the executable manifestation of the semantic kernel.

At minimum, establish the smallest coherent representations necessary for:

```text
Identity
Entity
Value
Relationship
State
Transformation
Constraint
Context
Observation
SemanticField
```

Do not duplicate semantic definitions unnecessarily.

Where a concept already exists in Lean, Mojo should implement its executable contract rather than independently redefine its meaning.

Where the Reference Executor already provides useful behaviour, reuse it where architecturally appropriate, but do not mistake Reference Executor implementation details for semantic authority.

---

# 8. Preserve numeric semantic independence

Do not introduce machine numeric types as semantic definitions without justification.

Remember the established numeric-semantics rule:

> Numeric meaning precedes machine representation.

For example, do not define semantic time merely as:

```text
f32
```

or:

```text
f64
```

unless the normative semantic contract explicitly requires that representation.

Instead distinguish:

```text
semantic quantity
        ↓
numeric contract
        ↓
representation
```

Representation may subsequently be selected by the implementation/provider.

The same rule applies to:

* positions;
* velocities;
* durations;
* counters;
* scalar values;
* tolerances;
* thresholds.

---

# 9. Establish real Mojo ↔ Reference Executor equivalence

Once the Mojo semantic kernel exists, create actual comparison tests.

Do not call the Reference Executor itself "equivalence."

Equivalence requires two independently identifiable executable paths whose semantic results can be compared.

Establish tests of the form:

```text
Semantic input
      │
      ├──────────────→ Reference Executor
      │
      └──────────────→ Mojo Semantic Kernel
                         │
                         ▼
                 Semantic Result
      │
      └──────────────→ Compare
```

The comparison must occur at the semantic level.

Do not require identical:

* memory layouts;
* structs;
* object representations;
* execution traces;
* machine types;
* internal data structures.

Instead compare semantic results.

Where appropriate, establish:

```text
semantic equality
≠
representation equality
≠
execution equality
```

The purpose is to demonstrate that different implementations preserve the same semantic contract.

---

# 10. Expand invariant/property testing

The current report identifies property testing as partial.

Improve this.

At minimum add meaningful tests around:

### Identity

* identity persistence;
* duplicate identity rejection;
* representation change does not alter identity.

### Entity

* valid entity creation;
* entity identity validity;
* invalid entity references rejected.

### Relationship

* relationship endpoints must exist;
* invalid relationships rejected;
* relationships remain semantically identifiable.

### State

* valid state construction;
* state invariants;
* invalid states rejected.

### Transformation

* valid transformation changes state according to contract;
* invalid transformation is rejected;
* failed transformation does not partially mutate authoritative state.

### Constraint

* constraints are checked;
* constraint failure preserves prior valid state.

### Observation

* observation does not mutate authoritative state;
* observation does not advance semantic time unless explicitly specified.

### Determinism

Where determinism is part of the contract:

```text
same semantic input
+
same semantic context
+
same semantic configuration
=
same semantic result
```

Do not introduce stronger determinism claims than the specifications require.

---

# 11. Establish the first genuinely useful entity model

The milestone should end with something more substantial than a counter increment.

The first canonical entity model should demonstrate that SCR can define and manipulate actual semantic entities.

Use the simplest possible domain witness.

A suitable progression is:

```text
Entity
 ├── Identity
 └── State
```

then:

```text
Entity A
Entity B
     │
     └── Relationship
```

then:

```text
Entity
 ├── Identity
 ├── Values
 └── State
```

then:

```text
SemanticField
 ├── Entities
 ├── Relationships
 ├── State
 ├── Transformations
 ├── Constraints
 └── Context
```

The existing particle simulation may remain a future witness.

Do not introduce unnecessary domain complexity merely to make the example look impressive.

The purpose is to prove the **kernel**, not the domain.

---

# 12. Do NOT start custom MLIR yet

This is an explicit constraint.

Do not create:

* a custom SCR MLIR dialect;
* `scr.create_particle`;
* `scr.create_state`;
* `scr.step`;
* SCR-specific TableGen definitions;
* custom C++ dialect infrastructure;
* lowering passes;
* CPU providers;
* runtime lifecycle machinery;

unless the current milestone produces a concrete, documented semantic requirement that cannot be represented adequately otherwise.

The 105 implementation contract exists specifically to prevent premature dialect construction.

The next question after this milestone is:

> What verified semantic information must survive into representation?

Only answer that question after the semantic kernel and executable equivalence are established.

If existing MLIR infrastructure is sufficient, use it.

If it is not sufficient, document precisely why.

---

# 13. Do not expand into simulation, spatial, rendering, or distributed semantics

Do not use this milestone to implement:

* advanced dynamics;
* particle simulation;
* spatial indexing;
* H3;
* BVH;
* KD trees;
* rendering;
* Vulkan;
* WebGPU;
* distributed execution;
* AMQP;
* persistence;
* CRDTs;
* databases;
* GQL;
* neural computation;
* learning/adaptation;
* automatic provider selection.

Those are downstream capabilities.

The present milestone is the semantic kernel.

---

# 14. Maintain the architecture

All implementation decisions must preserve these principles:

### Semantic Primacy

Semantic meaning is authoritative.

### Representation Independence

A semantic entity may have multiple physical representations.

### Identity Persistence

Identity survives representation and location changes.

### Relationship Primacy

Relationships are semantic structures, not implementation pointers.

### Transformation Primacy

Computation is semantic transformation.

### State Authority

Authoritative semantic state is distinct from incidental runtime state.

### Constraint Preservation

Valid transformations preserve their stated contracts.

### Context Dependence

Semantic interpretation occurs within semantic context.

### Observation Independence

Observation does not mutate authoritative state unless explicitly specified.

### Temporal Explicitness

Semantic time is distinct from wall-clock and processing time.

### Implementation Derivation

Implementation follows semantics.

### Formal Verification Boundary

Lean verifies semantic properties; it does not become the runtime.

---

# 15. Update documentation and status honestly

At completion, update the relevant verification/status documents.

Do not report a gate as PASS unless its actual acceptance criteria have been demonstrated.

The report should distinguish at least:

```text
SPECIFIED
FORMALISED
FORMALLY VERIFIED
IMPLEMENTED
UNIT TESTED
PROPERTY TESTED
REFERENCE TESTED
SEMANTICALLY EQUIVALENT
EXECUTED
OBSERVED
```

Do not collapse these states into one "PASS."

In particular, distinguish:

```text
Reference Executor works
```

from:

```text
Mojo implementation is equivalent to Reference Executor
```

and:

```text
semantic kernel is verified
```

from:

```text
full Golden Path is verified
```

---

# 16. Define explicit milestone acceptance criteria

Do not declare this milestone complete until all of the following are true.

## Specification

* [ ] Gate 0 reconciliation is complete or every remaining discrepancy is explicitly documented and dispositioned.
* [ ] Authority hierarchy is unambiguous.
* [ ] Entity, Identity, Value, Relationship, State, Transformation, Constraint, Context, Time, Observation and SemanticField have coherent definitions.

## Lean

* [ ] Semantic kernel is represented in Lean.
* [ ] Relevant invariants are formalised.
* [ ] Relevant theorems are proved.
* [ ] `lake build SCRFormal` passes.
* [ ] No semantic theorem was invented merely to make the report look complete.

## Mojo

* [ ] Actual Mojo semantic-kernel implementation exists.
* [ ] Implementation derives from reconciled semantic contracts.
* [ ] Representation details do not become accidental semantic definitions.
* [ ] The implementation is minimal and coherent.

## Reference Executor

* [ ] Existing Reference Executor remains passing.
* [ ] Existing behaviour is preserved unless a specification reconciliation requires correction.
* [ ] Reference Executor remains the semantic execution oracle.

## Equivalence

* [ ] Mojo implementation and Reference Executor have explicit comparison tests.
* [ ] Comparisons are semantic rather than representation-based.
* [ ] Equivalent results are demonstrated for the canonical kernel operations.

## Entity Definitions

* [ ] First reusable canonical SCR entity definitions exist.
* [ ] They are represented in the semantic model.
* [ ] They exist in Lean where appropriate.
* [ ] They have executable Mojo manifestations.
* [ ] They are exercised by tests.
* [ ] They are not merely example structs with no semantic contract.

## Architecture

* [ ] No premature custom MLIR dialect has been introduced.
* [ ] No premature lowering/provider/runtime implementation has been introduced.
* [ ] Semantic/implementation/representation boundaries remain explicit.

---

# 17. Expected development sequence

Execute the work in this order:

```text
1. Inspect repository
        ↓
2. Reconcile specifications
        ↓
3. Correct verification status
        ↓
4. Identify canonical semantic definitions
        ↓
5. Complete Lean kernel where necessary
        ↓
6. Prove required semantic properties
        ↓
7. Implement minimal Mojo semantic kernel
        ↓
8. Expand executable kernel tests
        ↓
9. Build Mojo ↔ Reference Executor comparison
        ↓
10. Establish first canonical entity definitions
        ↓
11. Verify the complete milestone
        ↓
12. Update verification report
        ↓
13. Stop before MLIR unless a concrete representation
    requirement has been demonstrated
```

Do not reorder this sequence merely because MLIR or runtime work appears more immediately tangible.

---

# 18. Required final report

When finished, report back with:

### A. Repository findings

What actually existed when you started.

### B. Specification reconciliation

What definitions were reconciled and what conflicts were found.

### C. Canonical semantic kernel

List the authoritative definitions established.

### D. Lean

List:

* files changed;
* definitions added;
* theorems added;
* verification commands;
* results.

### E. Mojo

List:

* files created/changed;
* semantic kernel implementation;
* design decisions;
* tests.

### F. Reference Executor

List:

* tests retained;
* tests added;
* any semantic corrections.

### G. Equivalence

Show exactly how Mojo and Reference Executor are compared and the results.

### H. First entity definitions

Show the first canonical SCR entities now available and how they are represented across:

```text
Specification
Lean
Mojo
Reference Executor
Tests
```

### I. Verification matrix

Update the matrix accurately.

### J. Gate status

Explicitly report:

```text
Gate 0
Gate 1
Gate 2
Gate 3
Gate 4
Gate 5
...
```

with PASS / PARTIAL / NOT STARTED and evidence.

### K. Architectural assessment

Identify any architectural contradictions or unresolved semantic questions.

### L. Next step

Recommend the next development milestone **only after evaluating the completed work**.

Do not automatically recommend MLIR.

If the semantic kernel now demonstrates a genuine representation requirement, state that requirement precisely.

If it does not, say so.

---

# Final governing rule

The purpose of this milestone is not to make SCR look more complete.

It is to make the **semantic foundation more real**.

We want to reach the point where we can honestly say:

> SCR now has its first canonical semantic entities, formally defined, executable in Mojo, exercised by the Reference Executor, and demonstrated to preserve the same semantic contract across implementations.

Everything downstream should be derived from that foundation.

**Do not guess. Do not invent missing semantics. Do not paper over architectural gaps. Inspect the repository, reconcile the specifications, implement only what is justified, verify it, and leave the system in a demonstrably stronger semantic state than you found it.**
