# Semantic Computational Runtime

# Library Specification and Validation Program

**Document:** LIBRARY_SPECIFICATION_PROGRAM.md
**Version:** 1.0.0
**Date:** 2026-09-05
**Status:** Authoritative Development Directive
**Applies to:** `lib/` and all descendants
**Audience:** AI development agents, human architects, implementers, reviewers

---

# 1. Purpose

The purpose of this programme is to establish a complete, traceable and formally specified semantic library beneath:

```text
lib/
```

The library is the foundational semantic layer of the Semantic Computational Runtime (SCR).

Before substantial implementation proceeds, every directory and subdirectory beneath `lib/` must have an explicit architectural contract describing:

1. What the domain represents.
2. Why the domain exists.
3. What belongs within the domain.
4. What does not belong within the domain.
5. What abstractions the domain exposes.
6. What abstractions it consumes.
7. Its relationship to its parent domain.
8. Its relationship to every immediate child domain.
9. Its relationship to sibling domains where relevant.
10. Its expected MLIR representation.
11. Its expected runtime representation.
12. Its expected implementation mechanisms.
13. Its testing requirements.
14. Its validation criteria.
15. Its dependencies and permitted dependencies.
16. Its invariants.
17. Its extensibility requirements.
18. Its status and implementation maturity.

This is not optional documentation.

**The specification is the architectural contract.**

Implementation must conform to the specification rather than the specification being retroactively written to describe whatever implementation happens to exist.

---

# 2. Governing Principle

The library shall be developed according to the following progression:

```text
              DESCRIBE
                  │
                  ▼
               SPECIFY
                  │
                  ▼
                TEST
                  │
                  ▼
               IMPLEMENT
                  │
                  ▼
               VALIDATE
                  │
                  ▼
             INTEGRATE
```

Where appropriate, implementation may occur between TEST and VALIDATE, but the conceptual contract must exist before implementation begins.

The agent shall never use existing implementation as the sole authority for determining what a domain *should* mean.

Existing code is evidence.

The specification is authority.

---

# 3. Recursive Scope

The agent MUST recursively traverse:

```text
lib/
lib/*
lib/*/*
lib/*/*/*
...
```

to arbitrary depth.

Every directory representing a semantic, architectural, computational, domain, infrastructure, adapter or abstraction namespace must be considered.

Do not assume that a directory is insignificant because it currently contains:

* no source files;
* only placeholder files;
* only tests;
* only generated files;
* only subdirectories;
* only C/C++ adapters;
* only Rust;
* only MLIR;
* only metadata.

The directory hierarchy itself is architectural information.

---

# 4. Mandatory `101_spec.md`

Every applicable directory MUST contain:

```text
101_spec.md
```

Example:

```text
lib/
├── 101_spec.md
├── information/
│   ├── 101_spec.md
│   ├── fields/
│   │   └── 101_spec.md
│   ├── topology/
│   │   └── 101_spec.md
│   └── encoding/
│       └── 101_spec.md
│
├── dynamics/
│   ├── 101_spec.md
│   ├── temporal/
│   │   └── 101_spec.md
│   └── ...
│
└── morphology/
    ├── 101_spec.md
    └── ...
```

If a directory does not yet have a clear semantic purpose, the agent MUST NOT silently invent one.

Instead:

1. analyse its contents;
2. determine whether it represents an intended domain;
3. record uncertainty;
4. identify its relationship to the parent;
5. create a provisional specification if architectural intent can reasonably be established;
6. mark unresolved architectural questions explicitly.

---

# 5. What `101_spec.md` Means

`101_spec.md` is the **entry-level domain specification** for a directory.

It is not intended to document every implementation detail.

It answers:

> "What is this domain, what does it mean, what is allowed within it, and how does it participate in the larger semantic system?"

The specification should allow a new agent to enter the directory cold and understand its architectural purpose without reverse-engineering the source tree.

---

# 6. Mandatory Specification Metadata

Every `101_spec.md` MUST begin with versioned metadata.

Minimum:

```yaml
---
document: 101_spec
spec_id: SCR-LIB-<DOMAIN>
title: <Domain Name>
version: 1.0.0
status: draft
created: 2026-09-05
updated: 2026-09-05
parent: <parent domain>
owner: SCR
authority: semantic-library
---
```

Where applicable:

```yaml
supersedes: <previous specification>
superseded_by: <future specification>
implementation_status: unspecified
test_status: unspecified
validation_status: unspecified
```

Dates MUST use ISO-8601:

```text
YYYY-MM-DD
```

Versions MUST use semantic versioning:

```text
MAJOR.MINOR.PATCH
```

---

# 7. Specification Versioning

Specifications are first-class artefacts and MUST be versioned independently from implementation where necessary.

A semantic change requires a specification version change.

Examples:

### PATCH

Clarification with no semantic change:

```text
1.0.0 → 1.0.1
```

### MINOR

Backward-compatible addition:

```text
1.0.0 → 1.1.0
```

### MAJOR

Breaking semantic change:

```text
1.0.0 → 2.0.0
```

The agent MUST NOT silently modify the meaning of an existing specification while retaining its version.

---

# 8. Historical Traceability

Specifications MUST preserve traceability.

Where a specification evolves, retain sufficient history to establish:

```text
Spec v1.0.0
     │
     ├── implementation
     │
     ├── tests
     │
     └── validation
            │
            ▼
Spec v1.1.0
```

A recommended structure is:

```text
specs/
├── 2026/
│   └── 09/
│       └── 05/
│           ├── SCR-LIB-001-v1.0.0.md
│           └── ...
```

The current `101_spec.md` remains the canonical current specification.

Historical specifications MUST NOT be overwritten.

If the repository's existing specification-storage convention differs, preserve the existing convention while retaining the same properties:

* immutable historical records;
* date;
* version;
* identifier;
* relationship to successor;
* relationship to implementation.

---

# 9. Required Contents of Every `101_spec.md`

Every specification MUST contain the following sections.

```markdown
# <Domain>

## 1. Identity

## 2. Purpose

## 3. Domain Definition

## 4. Scope

## 5. Non-Goals

## 6. Parent Relationship

## 7. Child Domains

## 8. Sibling Relationships

## 9. Semantic Model

## 10. Core Abstractions

## 11. Inputs

## 12. Outputs

## 13. Operations

## 14. Invariants

## 15. Composition

## 16. MLIR Representation

## 17. Runtime Representation

## 18. External Implementations and Adapters

## 19. Dependencies

## 20. Error Semantics

## 21. Determinism and Reproducibility

## 22. Testing Requirements

## 23. Validation Requirements

## 24. Security and Isolation Considerations

## 25. Performance Considerations

## 26. Extensibility

## 27. Open Questions

## 28. Implementation Status

## 29. Specification History
```

Sections may be marked:

```text
N/A
```

when genuinely irrelevant, but they must not simply be omitted.

---

# 10. Domain Definition

The agent MUST define the domain semantically rather than merely describing the files.

Bad:

> "This directory contains classes for physics."

Good:

> "This domain represents continuous and discrete physical state transitions governed by explicitly declared physical laws. It provides composable abstractions for expressing state variables, constraints, forces, interactions and integration schemes independently of their eventual CPU, GPU or external-library implementation."

The specification must describe **meaning**, not merely implementation.

---

# 11. Parent/Child Relationships

This is one of the most important requirements.

For every directory:

```text
A/
├── B/
├── C/
└── D/
```

the specification for `A` MUST explain:

```text
A → B
A → C
A → D
```

and each child MUST explain:

```text
B → A
C → A
D → A
```

These relationships should establish:

* containment;
* abstraction;
* refinement;
* specialization;
* composition;
* dependency;
* transformation;
* representation;
* implementation;
* execution.

Do not use the word "relationship" without specifying its semantic type.

---

# 12. Relationship Taxonomy

Use the following vocabulary where applicable.

### CONTAINS

The parent semantically contains the child domain.

### REFINES

The child provides greater semantic precision.

```text
physical-system
      ↓ refines
rigid-body
```

### SPECIALIZES

The child represents a constrained form of the parent.

### COMPOSES

The parent combines independent domains.

### DEPENDS_ON

The domain cannot operate without another domain.

### REPRESENTS

A domain provides a representation of another semantic object.

### LOWERS_TO

A higher-level semantic abstraction is transformed into a lower-level representation.

### IMPLEMENTED_BY

A semantic abstraction is implemented by another subsystem/library/backend.

### EXECUTES_ON

An abstraction is ultimately executed on a substrate.

### ADAPTS

A domain provides an interface between semantic contracts and external implementations.

### PRODUCES

The domain produces an artefact consumed elsewhere.

### CONSUMES

The domain consumes an artefact produced elsewhere.

---

# 13. Relationship Graph

The agent MUST think of `lib/` as a graph rather than merely a filesystem tree.

For example:

```text
                 SEMANTIC ROOT
                       │
       ┌───────────────┼────────────────┐
       │               │                │
 Information       Dynamics         Morphology
       │               │                │
       ├───────┐       │         ┌──────┴──────┐
       │       │       │         │             │
    Fields  Topology  Time    Geometry     Appearance
       │               │         │
       └───────────────┴─────────┘
                    │
             Semantic State
                    │
              SCR Semantic MLIR
                    │
              Lowering/Dispatch
                    │
          ┌─────────┼─────────┐
          CPU      GPU      External
```

The filesystem is therefore only one projection of the architecture.

---

# 14. Semantic Model

Every domain MUST define its semantic primitives.

For example:

```text
Entity
State
Relation
Transformation
Constraint
Observation
Signal
Event
Field
Operator
Kernel
Topology
Geometry
```

Only primitives actually relevant to that domain should be specified.

The agent MUST distinguish:

```text
semantic concept
        ≠
data structure
        ≠
API
        ≠
implementation
        ≠
hardware representation
```

---

# 15. Core Abstractions

For every abstraction identify:

```text
Name
Meaning
Inputs
Outputs
State
Invariants
Composition rules
Failure modes
MLIR representation
Runtime representation
Implementation candidates
Tests
```

Example:

```text
Abstraction:
    SemanticField

Meaning:
    A spatially or abstractly indexed information-bearing domain.

Inputs:
    topology
    values
    coordinates

Outputs:
    observations
    transformations

Invariants:
    identity persistence
    coordinate consistency
    declared dimensionality
```

---

# 16. External Libraries

Many SCR semantic primitives will ultimately be implemented through adapters over existing C, C++, Rust, GPU or scientific libraries.

This is expected.

However:

> External libraries are implementations, not semantic authorities.

The semantic contract MUST be defined above the external library.

For example:

```text
SCR Semantic Physics
        │
        ▼
MLIR Semantic Dialect
        │
        ▼
Physics Lowering
        │
        ├── Chrono
        ├── Bullet
        ├── PhysX
        └── custom solver
```

The semantic API must not become a thin wrapper around whichever library happens to be selected first.

The adapter conforms to SCR.

SCR does not conform to the adapter.

---

# 17. MLIR Requirements

Each domain specification MUST describe how its abstractions are expected to participate in MLIR.

At minimum identify:

* dialect;
* operations;
* types;
* attributes;
* regions;
* interfaces;
* traits;
* verification;
* canonicalization;
* transformation;
* lowering;
* execution requirements.

Where implementation has not yet begun, explicitly state:

```text
MLIR representation: TO BE SPECIFIED
```

rather than inventing implementation details.

The long-term model is:

```text
Application
    │
    ▼
Semantic Library
    │
    ▼
Semantic MLIR
    │
    ▼
MLIR
    │
    ├── CPU lowering
    ├── GPU lowering
    ├── accelerator lowering
    ├── external library lowering
    └── distributed execution
```

---

# 18. Runtime Requirements

Every domain must explain what happens after compilation.

The agent should identify whether its abstractions become:

* static data;
* runtime state;
* executable kernels;
* scheduling constraints;
* messages;
* streams;
* GPU resources;
* CPU operations;
* external library calls;
* rendering commands;
* persistent state;
* dynamically generated computation.

The semantic library exists to make these distinctions explicit while hiding unnecessary substrate-specific complexity from application developers.

---

# 19. Composition Requirements

SCR is explicitly intended to support **high-order, composable and chainable abstractions**.

Therefore every domain specification MUST consider composition.

Describe:

```text
What can compose with this domain?

What may consume its outputs?

What can it consume?

Can operations be chained?

Can operations be fused?

Can operations be reordered?

Can operations be parallelized?

Can operations be lowered independently?

Can operations execute asynchronously?

Can operations execute on different substrates?
```

Where mathematically meaningful, specify algebraic properties:

* associativity;
* commutativity;
* identity;
* inverse;
* idempotence;
* monotonicity;
* distributivity;
* conservation;
* continuity;
* locality.

Do not assert an algebraic property merely because it would be convenient.

---

# 20. Invariants

Every domain MUST explicitly identify its invariants.

An invariant is something that must remain true regardless of implementation.

Examples:

```text
INV-XXX-001
Semantic identity is preserved through lowering.

INV-XXX-002
A transformation may not alter undeclared semantic state.

INV-XXX-003
Units must remain dimensionally valid.

INV-XXX-004
An operation declared deterministic must produce
equivalent observable results across supported substrates.
```

Domain invariants should inherit from higher-level SCR invariants where applicable.

---

# 21. Testing Model

Testing occurs at multiple levels.

```text
                 Specification
                      │
                      ▼
                Unit Tests
                      │
                      ▼
             Domain Tests
                      │
                      ▼
             Composition Tests
                      │
                      ▼
               MLIR Tests
                      │
                      ▼
              Lowering Tests
                      │
                      ▼
             Runtime Tests
                      │
                      ▼
          Cross-substrate Tests
```

Every module MUST eventually have tests at the appropriate levels.

---

# 22. Function-Level Process

Every public function, operation, type or semantic primitive MUST eventually pass through:

## Stage 1 — Describe

Determine:

```text
What does it do?

Why does it exist?

What semantic concept does it represent?

What are its inputs?

What are its outputs?

What assumptions does it make?
```

## Stage 2 — Specify

Define:

```text
signature
semantics
preconditions
postconditions
invariants
error behaviour
determinism
complexity
composition behaviour
```

## Stage 3 — Test

Create tests for:

```text
normal operation
boundary conditions
invalid input
degenerate cases
composition
determinism
error behaviour
```

## Stage 4 — Implement

Only now should implementation be treated as authoritative engineering work.

## Stage 5 — Validate

Verify that implementation actually satisfies the specification.

A passing test suite does not automatically constitute semantic validation.

---

# 23. Testability Requirement

Every abstraction MUST be designed so that its behaviour can be observed and tested.

Avoid abstractions whose correctness depends exclusively upon:

* visual inspection;
* global state;
* nondeterministic timing;
* external services;
* unavailable hardware;
* implicit environment state.

Where nondeterminism is intrinsic, specify:

```text
source of nondeterminism
control mechanism
seed/state representation
acceptable equivalence criteria
```

---

# 24. Validation

Validation must answer:

> "Does the implementation satisfy the semantic contract?"

Not merely:

> "Does the program run?"

Validation should include, where relevant:

* structural validation;
* type validation;
* semantic validation;
* dimensional validation;
* numerical validation;
* invariant validation;
* performance validation;
* concurrency validation;
* determinism validation;
* lowering validation;
* hardware validation.

---

# 25. Progressive Abstraction

The agent MUST preserve abstraction boundaries.

A domain should progress approximately as:

```text
Concept
  ↓
Semantic Contract
  ↓
MLIR Representation
  ↓
Generic Implementation
  ↓
Backend Adapter
  ↓
Hardware/Library Implementation
```

Do not prematurely collapse these layers.

For example:

```text
semantic.physics.force
```

should not immediately become:

```text
chrono::Force
```

The latter is merely one possible implementation.

---

# 26. Dependency Discipline

Each specification MUST declare:

### Required semantic dependencies

Dependencies required by meaning.

### Optional implementation dependencies

Dependencies useful for implementing the domain.

### Backend dependencies

Specific libraries or hardware targets.

### Forbidden dependencies

Dependencies that would violate architectural boundaries.

Example:

```text
Semantic domain:
    physics

Required:
    units
    state
    dynamics

Optional:
    numerical

Backend:
    Project Chrono

Forbidden:
    renderer-specific types
```

This distinction is essential to prevent architectural contamination.

---

# 27. Directory Inventory

Before modifying implementation, the agent MUST generate an inventory of `lib/`.

The inventory should record:

```text
path
depth
type
current files
child directories
existing specification
existing tests
existing implementation
apparent domain
parent domain
dependencies
implementation status
specification status
test status
validation status
uncertainties
```

The inventory becomes the master worklist.

---

# 28. Do Not Skip Directories

The agent MUST NOT conclude:

> "This directory is obvious."

If it is obvious, specifying it should be trivial.

Likewise, do not omit:

```text
internal/
common/
core/
util/
support/
runtime/
adapter/
backend/
detail/
```

These directories often contain the most dangerous architectural ambiguity.

If a directory genuinely should not exist as an architectural boundary, document that finding and propose restructuring rather than silently ignoring it.

---

# 29. Existing Specifications

If a directory already contains documentation describing its intended semantics:

1. inspect it;
2. determine whether it is authoritative;
3. reconcile it with the current architecture;
4. preserve useful material;
5. migrate it into `101_spec.md` where appropriate;
6. retain historical provenance;
7. do not silently discard contradictory specifications.

---

# 30. Existing Implementation

Existing implementation must be analysed but not blindly canonised.

The agent should classify each implementation as:

```text
CONFORMING
PARTIALLY_CONFORMING
UNSPECIFIED
CONTRADICTORY
OBSOLETE
ORPHANED
```

Contradictory implementation must be reported.

Do not rewrite substantial implementation merely to make the documentation appear correct.

---

# 31. Existing Tests

Existing tests must likewise be classified:

```text
SPECIFICATION-COVERED
IMPLEMENTATION-COVERED
INSUFFICIENT
INVALID
ORPHANED
MISSING
```

A test that merely exercises code without establishing a semantic property should not be considered sufficient domain validation.

---

# 32. Agent Work Phases

The entire project shall be executed in phases.

## Phase 0 — Inventory

Produce the complete recursive directory inventory.

No implementation changes.

---

## Phase 1 — Domain Discovery

For every directory:

```text
identify domain
identify parent
identify children
identify relationships
identify existing abstractions
identify uncertainties
```

No substantial implementation changes.

---

## Phase 2 — `101_spec.md`

Create or update the specification for every directory.

At the end of this phase:

```text
every applicable lib/ directory
        │
        ▼
     101_spec.md
```

must exist.

---

## Phase 3 — Semantic Reconciliation

Review neighbouring specifications for contradictions.

Check:

```text
parent ↔ child
sibling ↔ sibling
domain ↔ implementation
domain ↔ MLIR architecture
domain ↔ runtime architecture
```

Resolve inconsistencies before implementation proceeds.

---

## Phase 4 — Module Specification

For every source module:

```text
describe
    ↓
specify
    ↓
identify tests
```

Record module-level contracts.

---

## Phase 5 — Function Specification

For every public semantic operation/function:

```text
describe
    ↓
specify
    ↓
test design
```

Private helper functions may be treated according to their semantic significance.

---

## Phase 6 — Test Construction

Implement the tests defined by the specifications.

Tests must fail meaningfully when the contract is violated.

---

## Phase 7 — Implementation

Implement modules and functions against the established contracts.

---

## Phase 8 — Validation

Run:

```text
unit tests
domain tests
integration tests
MLIR verification
lowering tests
runtime tests
cross-domain composition tests
```

---

## Phase 9 — Cross-Domain Validation

Validate that domains compose correctly.

This phase is particularly important.

A collection of individually correct modules may still constitute an incorrect semantic system.

---

# 33. Parallel Agent Execution

This project is explicitly expected to be developed by multiple agents.

Therefore agents MUST operate against contracts, not assumptions.

Each agent MUST:

1. identify the domain it owns;
2. read the parent's `101_spec.md`;
3. read immediate children's specifications where available;
4. read relevant sibling specifications;
5. declare dependencies;
6. avoid changing unrelated specifications;
7. avoid changing public interfaces without updating the specification;
8. record architectural conflicts;
9. produce tests with implementation;
10. leave a traceable specification history.

---

# 34. Agent Ownership

Agents may own:

```text
domain
subdomain
module
backend
test suite
MLIR dialect
adapter
```

Ownership MUST be explicit.

A recommended work record:

```yaml
agent: <agent-id>
domain: <domain>
spec_version: 1.0.0
implementation_scope:
  - ...
dependencies:
  - ...
status: active
```

---

# 35. Conflict Resolution

If two agents discover conflicting semantic assumptions:

**Do not resolve the conflict by choosing whichever implementation is easier.**

Record:

```text
CONFLICT
Domain A:
Domain B:
Conflict:
Affected specifications:
Affected implementations:
Possible resolutions:
Recommended resolution:
```

Escalate architectural conflicts to the root semantic specification.

---

# 36. Definition of Done — Directory

A directory is not considered specified until:

* [ ] `101_spec.md` exists.
* [ ] Metadata is present.
* [ ] Version is present.
* [ ] Creation/update dates are present.
* [ ] Domain is defined.
* [ ] Purpose is defined.
* [ ] Scope is defined.
* [ ] Non-goals are defined.
* [ ] Parent relationship is defined.
* [ ] Child relationships are defined.
* [ ] Relevant sibling relationships are defined.
* [ ] Semantic abstractions are identified.
* [ ] Inputs/outputs are identified.
* [ ] Invariants are identified.
* [ ] Composition behaviour is described.
* [ ] MLIR relationship is described.
* [ ] Runtime relationship is described.
* [ ] Dependencies are classified.
* [ ] Testing requirements are defined.
* [ ] Validation requirements are defined.
* [ ] Open questions are recorded.
* [ ] Implementation status is recorded.

---

# 37. Definition of Done — Module

A module is complete only when:

* [ ] Its semantic purpose is specified.
* [ ] Its public interface is specified.
* [ ] Preconditions are specified.
* [ ] Postconditions are specified.
* [ ] Invariants are specified.
* [ ] Error semantics are specified.
* [ ] Composition behaviour is specified.
* [ ] Tests exist.
* [ ] Tests pass.
* [ ] Implementation has been reviewed against the specification.
* [ ] Validation has been performed.

---

# 38. Definition of Done — Function

A function/operation is complete only when:

```text
DESCRIPTION
    ↓
SPECIFICATION
    ↓
TEST
    ↓
IMPLEMENTATION
    ↓
VALIDATION
```

has been completed and recorded.

---

# 39. Specification Status

Use exactly one of:

```text
DRAFT
REVIEW
APPROVED
DEPRECATED
SUPERSEDED
```

Implementation status:

```text
UNIMPLEMENTED
PROTOTYPE
PARTIAL
IMPLEMENTED
VALIDATED
DEPRECATED
```

Test status:

```text
NONE
PARTIAL
UNIT
DOMAIN
INTEGRATION
COMPLETE
```

---

# 40. Traceability Matrix

As the project progresses, maintain a traceability relationship:

```text
Domain
  │
  ├── Specification
  │
  ├── Module
  │     │
  │     ├── Function
  │     │
  │     └── Tests
  │
  ├── MLIR representation
  │
  ├── Lowering
  │
  ├── Runtime implementation
  │
  └── Validation
```

A semantic capability should ultimately be traceable from:

```text
semantic concept
        ↓
101_spec.md
        ↓
MLIR operation/type/interface
        ↓
implementation
        ↓
test
        ↓
validated execution
```

---

# 41. Quality Standard

The agent must prefer:

```text
explicitness over assumption
contracts over convention
semantics over implementation
composition over coupling
verification over assertion
traceability over convenience
```

Do not create elaborate specifications merely to satisfy a checklist.

The objective is to create **useful architectural contracts**.

A specification that says nothing beyond the directory name is a failed specification.

---

# 42. First Execution Instruction

When beginning this programme, the agent MUST NOT immediately start writing specifications.

First execute:

```bash
find lib -type d | sort
```

Then inspect:

```bash
find lib -type f | sort
```

Then identify:

```text
existing 101_spec.md files
existing specifications
existing tests
source modules
MLIR definitions
bindings
adapters
generated code
```

Construct the complete inventory.

Only then begin Phase 1.

---

# 43. Initial Deliverables

The first agent pass MUST produce:

```text
1. Complete recursive lib/ inventory.

2. Domain hierarchy.

3. Relationship graph.

4. Specification coverage report.

5. Missing 101_spec.md report.

6. Existing implementation/test inventory.

7. Architectural ambiguities.

8. Cross-domain dependency map.

9. Proposed parallelisation/work allocation.

10. Phase 1 implementation plan.
```

Do not begin mass implementation until these artefacts exist.

---

# 44. Final Architectural Principle

The semantic library is not merely a collection of reusable source code.

It is the **semantic vocabulary from which computational systems are constructed**.

The intended relationship is:

```text
                 APPLICATION
                      │
          Python / Rust / C++ / etc.
                      │
                      ▼
              SEMANTIC LIBRARY
                      │
                      ▼
               SEMANTIC IR
                      │
                      ▼
                    MLIR
                      │
          ┌───────────┼────────────┐
          │           │            │
         CPU         GPU       ACCELERATOR
          │           │            │
          └───────────┼────────────┘
                      │
                      ▼
                 RUNTIME
                      │
                      ▼
                  HARDWARE
```

The purpose of this programme is therefore to ensure that every semantic capability entering that pipeline has a **precise, explicit, testable and traceable contract**.

The filesystem is the first visible manifestation of that ontology.

The specifications define its meaning.

MLIR defines its compilable representation.

The runtime defines its execution.

The hardware is merely where the computation eventually manifests.

**Do not optimise the implementation before the semantic contract is understood.**
**Do not define the contract by the implementation.**
**Do not allow backend APIs to dictate the semantic model.**

Build the semantic universe first.

Then teach the compiler how to manifest it.
