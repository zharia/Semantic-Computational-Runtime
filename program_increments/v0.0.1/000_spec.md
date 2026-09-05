# Semantic Computational Runtime

## Program Increment v0.0.1 — AI Agent Instructions

**Version:** 1.0.0
**Program Increment:** v0.0.1
**Date:** 2026-09-05
**Project:** Semantic Computational Runtime (SCR)

---

# 1. Mission

Your task is to systematically inspect, define, specify, implement, test, and validate the SCR semantic library.

The objective of this Program Increment is **not** simply to make the existing code compile.

The objective is to establish a formally traceable semantic foundation in which:

```text
Domain
   ↓
Definition
   ↓
Semantic Contract
   ↓
Implementation
   ↓
Tests
   ↓
Validation
   ↓
MLIR
   ↓
Runtime
   ↓
Execution Substrate
```

can be followed for every meaningful module, abstraction, operation, and function.

The SCR library is a **semantic computational library built upon MLIR**.

The filesystem is only one projection of the underlying semantic architecture.

---

# 2. Fundamental Principle

The following principle governs all work in this Program Increment:

> **Do not define semantics from implementation. Define the semantics first, then make the implementation conform to them.**

The implementation is evidence.

It is not automatically the specification.

Existing code, APIs, data structures, dependencies, tests, and external libraries MUST NOT be assumed to represent the intended semantic architecture without examination.

---

# 3. Program Increment Control Plane

Every domain directory MUST use the following three control-plane files:

```text
101_definition.md
102_status.yaml
103_library.graph.json
```

Their responsibilities are strictly separated.

## 3.1 101_definition.md

The normative semantic definition.

It defines:

* what the domain is;
* why it exists;
* its semantic model;
* its primitives;
* its entities;
* its values;
* its operations;
* its invariants;
* its composition;
* its relationships;
* its inputs and outputs;
* its state model;
* its errors;
* its observability;
* its MLIR representation;
* its runtime semantics;
* its dependencies;
* its testing requirements;
* its validation requirements.

`101_definition.md` answers:

> **What SHOULD this domain mean and do?**

---

## 3.2 102_status.yaml

The current engineering state.

It records:

* implementation state;
* test state;
* validation state;
* completeness;
* coverage;
* dependencies;
* functions;
* source files;
* MLIR artifacts;
* backend implementations;
* agents;
* blockers;
* risks;
* open questions;
* traceability;
* engineering history.

`102_status.yaml` answers:

> **What IS the current state of this domain?**

It MUST NOT redefine the semantic contract.

---

## 3.3 103_library.graph.json

The machine-readable aggregate semantic graph.

It represents relationships between domains, modules, implementations, tests, specifications, and other entities.

It SHOULD be generated from the authoritative `101_definition.md` and `102_status.yaml` files.

Agents MUST NOT manually edit it unless explicitly instructed to do so.

---

# 4. Scope

The scope of this Program Increment is the entire:

```text
lib/
```

tree.

The agent MUST recursively inspect:

```bash
find lib -type d | sort
find lib -type f | sort
```

No directory may be silently skipped because it appears:

* trivial;
* internal;
* technical;
* utility-oriented;
* generated;
* incomplete;
* empty;
* experimental;
* poorly named;
* unrelated at first inspection.

Directories such as:

```text
common/
util/
support/
detail/
internal/
core/
types/
runtime/
```

MUST receive explicit architectural treatment.

If a directory should not represent an independent semantic domain, document that conclusion and propose the appropriate restructuring rather than silently ignoring it.

---

# 5. Phase 0 — Inventory

Before modifying implementation code, recursively inventory the entire library.

Record at minimum:

```text
path
depth
directory
files
child directories
existing definitions
existing status files
existing tests
source files
MLIR files
bindings
adapters
generated files
apparent domain
apparent parent
apparent dependencies
apparent relationships
implementation status
test status
validation status
uncertainties
```

The first deliverable is a complete library inventory.

---

# 6. Phase 1 — Establish the Domain Hierarchy

Determine the semantic hierarchy represented by `lib/`.

For each directory determine:

1. What domain does this directory represent?
2. Why does that domain exist?
3. Is it a genuine semantic boundary?
4. What is its parent?
5. What are its children?
6. What are its siblings?
7. What domains does it depend upon?
8. What domains depend upon it?
9. What domains does it represent or lower into?
10. Is the filesystem hierarchy consistent with the semantic hierarchy?

Do not assume:

```text
directory nesting = semantic containment
```

Instead treat the library as a graph:

```text
                 ┌──────────────┐
                 │   Domain A   │
                 └──────┬───────┘
                        │
             ┌──────────┼──────────┐
             ▼          ▼          ▼
          Domain B   Domain C   Domain D
             │          │
             └────┬─────┘
                  ▼
              Domain E
```

The graph may contain relationships that do not correspond to filesystem paths.

---

# 7. Phase 2 — Create or Correct 101 Definitions

Every semantic directory MUST have:

```text
101_definition.md
```

If one does not exist, create it.

If one exists, inspect it for correctness.

Do not blindly preserve an existing specification merely because it exists.

Existing documentation is evidence, not authority.

Each definition MUST address at least:

1. Definition
2. Purpose
3. Scope
4. Non-goals
5. Semantic model
6. Primitives
7. Entities
8. Values
9. Abstractions
10. Operations
11. Invariants
12. Composition
13. Parent relationship
14. Child domains
15. Sibling relationships
16. Cross-domain relationships
17. Inputs
18. Outputs
19. State model
20. Errors
21. Observability
22. MLIR representation
23. Runtime semantics
24. Implementation independence
25. External adapters
26. Dependencies
27. Performance semantics
28. Security/isolation
29. Extensibility
30. Versioning
31. Traceability
32. Testing requirements
33. Validation requirements
34. Function-level requirements
35. Architectural rules
36. Open semantic questions
37. Definition history

---

# 8. Phase 3 — Define Relationships

Use explicit typed relationships.

Preferred relationship vocabulary:

```text
CONTAINS
REFINES
SPECIALIZES
COMPOSES
DEPENDS_ON
REPRESENTS
LOWERS_TO
IMPLEMENTED_BY
EXECUTES_ON
ADAPTS
PRODUCES
CONSUMES
INTERACTS_WITH
CONSTRAINS
OBSERVES
TRANSFORMS
```

Relationships MUST describe semantic relationships wherever possible.

For example:

```text
MORPHOLOGY
    REFINES
SEMANTIC_STRUCTURE
```

is preferable to:

```text
morphology
    imports
some_rust_module
```

The latter may be an implementation dependency.

The former is an architectural relationship.

Both may exist, but they represent different layers of the system.

---

# 9. Phase 4 — Populate 102 Status

Every domain MUST have:

```text
102_status.yaml
```

The status file MUST reflect reality.

Do not mark something:

```yaml
status: complete
```

merely because source code exists.

Status must distinguish at minimum:

```text
specified
implemented
tested
validated
```

A useful progression is:

```text
not_started
discovered
specified
partially_implemented
implemented
tested
validated
deprecated
blocked
```

Where appropriate, use more granular status fields rather than collapsing everything into one overall status.

---

# 10. Status Must Be Evidence-Based

An agent MUST NOT claim:

```text
implemented
tested
validated
complete
```

without evidence.

Examples:

### Implemented

There must be identifiable implementation artifacts.

### Tested

There must be executable tests demonstrating required behaviour.

### Validated

There must be evidence that implementation conforms to the normative semantic definition.

### Complete

All required semantic, implementation, testing, and validation criteria must be satisfied.

Compilation alone does not constitute correctness.

Passing tests alone does not constitute semantic validation.

---

# 11. Phase 5 — Function-Level Process

Every semantically meaningful function MUST follow:

```text
DESCRIBE
   ↓
SPECIFY
   ↓
TEST
   ↓
IMPLEMENT
   ↓
VALIDATE
```

## 11.1 Describe

Explain what the function means.

## 11.2 Specify

Define:

* inputs;
* outputs;
* preconditions;
* postconditions;
* invariants;
* errors;
* determinism;
* side effects;
* composition;
* ownership;
* lifecycle.

## 11.3 Test

Tests MUST cover appropriate:

* normal cases;
* boundary cases;
* invalid inputs;
* degenerate cases;
* error cases;
* composition;
* deterministic behaviour;
* invariant preservation.

## 11.4 Implement

Implement against the semantic contract.

Do not modify the contract merely to make the implementation easier.

## 11.5 Validate

Demonstrate that implementation behaviour corresponds to the specification.

---

# 12. Phase 6 — Testing

Testing MUST proceed progressively:

```text
Specification Tests
        ↓
Unit Tests
        ↓
Domain Tests
        ↓
Composition Tests
        ↓
MLIR Tests
        ↓
Lowering Tests
        ↓
Runtime Tests
        ↓
Cross-Substrate Tests
```

Where applicable, tests must establish:

* correctness;
* boundary behaviour;
* error semantics;
* invariant preservation;
* determinism;
* serialization;
* composition;
* MLIR verification;
* lowering correctness;
* runtime correctness;
* backend equivalence.

---

# 13. Phase 7 — MLIR

SCR is fundamentally an MLIR-based semantic runtime.

Every domain MUST explicitly determine whether it requires:

* MLIR dialects;
* operations;
* types;
* attributes;
* regions;
* interfaces;
* traits;
* verification;
* canonicalization;
* transformation passes;
* lowering;
* runtime integration.

Do not create MLIR artifacts merely because MLIR is available.

First establish the semantic requirement.

Then determine the appropriate MLIR representation.

The conceptual progression is:

```text
Semantic Concept
      ↓
Semantic Contract
      ↓
MLIR Representation
      ↓
Transformation
      ↓
Lowering
      ↓
Runtime Execution
```

---

# 14. Phase 8 — Backend Independence

SCR semantic definitions MUST remain independent of:

* Rust;
* C++;
* Python;
* Vulkan;
* CUDA;
* ROCm;
* LLVM;
* external scientific libraries;
* rendering engines;
* operating systems;
* specific hardware.

External technologies are implementation substrates.

They are not semantic authorities.

For example:

```text
SCR Morphology
      ↓
Semantic Contract
      ↓
MLIR
      ↓
Rust implementation
      ↓
C++ adapter
      ↓
VulkanSceneGraph
      ↓
Vulkan
      ↓
GPU
```

The semantic contract must remain valid even if the backend changes.

---

# 15. Phase 9 — External Libraries

When an external library is used:

```text
SCR Semantic Domain
        ↓
SCR Adapter
        ↓
External Library
```

The adapter MUST translate between the external implementation and the SCR semantic model.

Do not allow:

```text
External API
      ↓
SCR semantics
```

to become the architectural authority.

External library limitations MUST be documented.

This includes:

* precision;
* supported operations;
* determinism;
* performance;
* error semantics;
* resource ownership;
* lifecycle;
* threading;
* platform restrictions.

---

# 16. Phase 10 — Generate 103_library.graph.json

After definitions and status records have been established, generate:

```text
103_library.graph.json
```

The graph MUST represent, where applicable:

```text
domains
modules
functions
operations
types
relationships
dependencies
implementations
tests
validation
MLIR artifacts
backends
external adapters
```

Each graph entity SHOULD have stable identity.

Each relationship SHOULD have:

```text
source
target
relationship type
provenance
```

Example:

```json
{
  "source": "SCR-LIB-MORPHOLOGY",
  "target": "SCR-LIB-GEOMETRY",
  "relation": "REFINES",
  "provenance": {
    "file": "lib/morphology/101_definition.md",
    "version": "0.1.0"
  }
}
```

The graph is a derived representation.

---

# 17. Versioning and Dates

All normative and engineering artifacts MUST be dated and versioned.

Use:

```text
YYYY-MM-DD
```

for dates.

Use Semantic Versioning:

```text
MAJOR.MINOR.PATCH
```

for specifications and other versioned artifacts.

Every modification to a normative definition MUST update its:

```text
version
updated
history
```

Do not silently overwrite historical semantic definitions.

Historical versions MUST remain traceable.

---

# 18. Specification Authority

When resolving conflicts:

```text
101_definition.md
        >
implementation
```

The semantic definition has authority over implementation.

If the implementation conflicts with the definition:

1. identify the conflict;
2. determine whether the implementation or definition is wrong;
3. do not silently resolve the discrepancy;
4. document the decision;
5. update the appropriate artifact;
6. preserve traceability.

If the conflict is architectural, escalate it to the parent/root semantic definition.

---

# 19. Agent Isolation

Agents MUST work within explicitly assigned scope.

An agent MUST:

* inspect the parent definition;
* inspect relevant child definitions;
* inspect relevant sibling definitions;
* inspect dependency definitions;
* declare its scope;
* avoid unrelated modifications;
* preserve existing work;
* update status;
* update definitions when normative interfaces change;
* record significant decisions.

Agents MUST NOT rewrite unrelated modules merely because they discover opportunities for improvement.

---

# 20. Existing Code

Do not assume existing implementation is correct.

For every existing module determine:

```text
What does the code actually do?
What should the domain mean?
Do these agree?
```

If they disagree:

```text
semantic discrepancy
```

must be recorded.

Do not hide discrepancies by changing status to make the repository appear healthier.

---

# 21. Empty or Incomplete Domains

An empty directory may still represent an intentional future semantic domain.

Determine whether it is:

```text
intentional domain
placeholder
obsolete
misplaced
duplicate
implementation artifact
candidate for removal
candidate for restructuring
```

Record the determination.

Do not automatically delete empty or apparently unused directories.

---

# 22. Dependency Discipline

Dependencies MUST be classified as:

```text
semantic
implementation
optional
backend
external
```

Avoid introducing dependencies merely because they make implementation convenient.

Particular attention MUST be paid to circular semantic dependencies.

If:

```text
A DEPENDS_ON B
B DEPENDS_ON A
```

exists, determine whether this is:

* a legitimate mutual relationship;
* a composition relationship incorrectly represented as dependency;
* an abstraction boundary failure;
* a cyclic implementation dependency;
* a graph relationship that needs different modelling.

---

# 23. Determinism

Every domain must explicitly state whether deterministic behaviour is required.

If nondeterminism exists, document:

```text
source
control mechanism
seed/state
reproducibility requirements
equivalence criteria
```

Do not describe an operation as deterministic merely because it normally produces the same output.

---

# 24. Semantic vs Physical Representation

Agents MUST continuously distinguish:

```text
semantic concept
semantic value
data structure
API
implementation
runtime object
MLIR representation
backend representation
hardware resource
```

These are different layers.

For example:

```text
Semantic Position
      ≠
Rust Position Struct
      ≠
MLIR Position Type
      ≠
GPU Buffer
      ≠
Vulkan Resource
```

An implementation MAY correspond to a semantic concept without being identical to it.

---

# 25. Quality Gates

A module MUST NOT advance simply because code has been written.

## Gate 1 — Defined

The domain has a valid `101_definition.md`.

## Gate 2 — Specified

Semantic primitives, operations, invariants, relationships, inputs, outputs, and errors are defined.

## Gate 3 — Implemented

The implementation satisfies the semantic contract.

## Gate 4 — Tested

Required behaviour has executable tests.

## Gate 5 — Validated

Implementation has been explicitly checked against the semantic definition.

## Gate 6 — Integrated

MLIR, runtime, and applicable backend integration has been verified.

---

# 26. Required Deliverables

At the end of the initial discovery phase, produce:

1. Complete recursive `lib/` inventory.
2. Domain hierarchy.
3. Semantic relationship graph.
4. Specification coverage report.
5. Missing `101_definition.md` report.
6. Missing `102_status.yaml` report.
7. Existing implementation inventory.
8. Existing test inventory.
9. MLIR inventory.
10. Backend/adaptor inventory.
11. Cross-domain dependency map.
12. Architectural ambiguity report.
13. Semantic discrepancy report.
14. Proposed work breakdown.
15. Parallelisation opportunities.
16. Blocked dependencies.
17. Initial `103_library.graph.json`.

---

# 27. Work Ordering

Do NOT attempt to implement everything simultaneously.

Use this order:

```text
DISCOVER
   ↓
CLASSIFY
   ↓
DEFINE
   ↓
RELATE
   ↓
SPECIFY
   ↓
TEST DESIGN
   ↓
IMPLEMENT
   ↓
TEST
   ↓
VALIDATE
   ↓
INTEGRATE
   ↓
OPTIMIZE
```

Optimization comes last.

Correctness and semantic coherence come first.

---

# 28. Parallelisation

The work may be parallelised once semantic boundaries have been established.

Suitable independent work units include:

```text
Domain definition
Function specification
Test design
Implementation
MLIR dialect work
Backend adapter work
Validation
Documentation
```

However, agents MUST NOT independently redefine shared foundational concepts.

Foundational domains must be established first.

---

# 29. Conflict Resolution

When agents encounter conflicting definitions:

1. identify the conflict;
2. identify affected domains;
3. identify the relevant parent domain;
4. determine whether the conflict is semantic or implementation-level;
5. record it;
6. avoid silently selecting the implementation-convenient option;
7. resolve against the highest applicable semantic authority.

Architectural disagreements MUST remain visible until resolved.

---

# 30. Forbidden Behaviour

Agents MUST NOT:

* silently redefine semantics;
* treat existing code as authoritative;
* mark incomplete work as complete;
* claim tests exist when they do not;
* claim validation without evidence;
* delete unexplained architecture;
* introduce arbitrary dependencies;
* allow backend APIs to dictate semantics;
* conflate implementation with semantic identity;
* manually fabricate graph relationships;
* overwrite historical normative specifications;
* modify unrelated domains;
* optimize before correctness is established;
* suppress architectural inconsistencies to make status appear healthier.

---

# 31. Definition of Done — Directory

A directory is complete only when:

* `101_definition.md` exists;
* the semantic domain is defined;
* parent relationship is defined;
* child relationships are defined;
* relevant sibling relationships are defined;
* semantic primitives are defined;
* abstractions are defined;
* operations are defined;
* invariants are defined;
* inputs and outputs are defined;
* errors are defined;
* composition is defined;
* MLIR requirements are defined;
* runtime requirements are defined;
* dependencies are classified;
* external implementations are identified;
* testing requirements are defined;
* validation requirements are defined;
* `102_status.yaml` reflects reality;
* relevant graph relationships can be derived.

---

# 32. Definition of Done — Function

A function is complete only when:

```text
[ ] Described
[ ] Semantically specified
[ ] Inputs specified
[ ] Outputs specified
[ ] Preconditions specified
[ ] Postconditions specified
[ ] Errors specified
[ ] Invariants specified
[ ] Determinism specified
[ ] Implementation exists
[ ] Unit tests exist
[ ] Boundary tests exist
[ ] Error tests exist
[ ] Composition tests exist where applicable
[ ] Implementation validated
```

---

# 33. Definition of Done — Module

A module is complete only when:

```text
[ ] Domain defined
[ ] Semantic contract complete
[ ] Relationships established
[ ] Implementation complete
[ ] Tests complete
[ ] MLIR representation validated where applicable
[ ] Lowering validated where applicable
[ ] Runtime behaviour validated
[ ] Backend behaviour validated where applicable
[ ] External adapters validated where applicable
[ ] Determinism validated
[ ] Traceability complete
[ ] Status updated
[ ] Graph regenerated
```

---

# 34. Program Increment Completion

Program Increment v0.0.1 is complete when the library has transitioned from:

```text
Unknown / inferred architecture
```

to:

```text
Explicit semantic architecture
```

and every applicable directory has:

```text
101_definition.md
102_status.yaml
```

with the aggregate:

```text
103_library.graph.json
```

generated from those authoritative records.

The resulting system should make it possible to answer mechanically:

```text
What is this domain?

Why does it exist?

What does it depend on?

What depends on it?

What does it mean?

What operations does it provide?

What invariants must hold?

How is it represented in MLIR?

How is it executed?

How is it implemented?

How is it tested?

How is it validated?

What remains incomplete?

What changed?

Which specification does this implementation correspond to?

Which tests demonstrate correctness?

Which validation demonstrates semantic conformance?
```

If those questions cannot be answered, the domain is not yet adequately specified.

---

# 35. Final Agent Directive

Treat this repository as a **semantic system under construction**, not merely as a software repository.

Your responsibility is therefore not simply to modify files.

Your responsibility is to establish and preserve the correspondence:

```text
                 SEMANTIC UNIVERSE
                       │
                       ▼
                101_definition
                       │
                       ▼
                 Semantic Contract
                       │
                       ▼
                  102_status
                       │
                       ▼
                  Implementation
                       │
                       ▼
                     Tests
                       │
                       ▼
                  Validation
                       │
                       ▼
                  MLIR / Runtime
                       │
                       ▼
               Execution Substrate
                       │
                       ▼
                103_library.graph
```

The purpose of Program Increment v0.0.1 is to make that correspondence **explicit, inspectable, versioned, testable, and machine-traceable**.

> **The code is not the architecture.
> The specification is not the implementation.
> The status is not the specification.
> The graph is not the source of truth.
> The semantic model is the authority from which the rest of the system is derived.**
