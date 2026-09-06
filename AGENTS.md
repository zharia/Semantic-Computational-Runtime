# AGENTS.md

# Semantic Computational Runtime — Agent Instructions

**Project:** Semantic Computational Runtime (SCR)
**Document:** `AGENTS.md`
**Version:** `2.0.0`
**Date:** 2026-09-05
**Authority:** Project-level agent operating policy

---

## 1. Purpose

This document defines how AI coding agents must operate within the Semantic Computational Runtime (SCR) repository.

It is an **agent control-plane document**.

It defines:

* how agents discover the architecture;
* how agents determine authority;
* how agents scope work;
* how agents modify semantic definitions and implementations;
* how agents validate changes;
* when agents must stop and escalate ambiguity.

It does **not** attempt to define every SCR semantic domain.

Normative semantic definitions belong in the semantic library and associated specifications.

> **AGENTS.md defines how an agent works on SCR. It does not define what SCR's domains mean.**

---

# 2. SCR Identity

SCR is an:

> **MLIR-based Language Runtime for Computational Semantics.**

Its purpose is to provide a common semantic environment in which heterogeneous computational domains can be represented through explicit semantic contracts and compiled into implementations across heterogeneous execution substrates.

The conceptual execution architecture is:

```text
Application
    ↓
Semantic API / Frontend
    ↓
Semantic Library
    ↓
Semantic Model
    ↓
SCR Semantic MLIR
    ↓
MLIR Infrastructure
    ↓
Analysis / Transformation
    ↓
Provider Selection
    ↓
Lowering
    ↓
Runtime
    ↓
Execution Substrate
```

Execution substrates may include:

```text
CPU
GPU
Accelerator
External Library
Distributed System
Specialized Hardware
```

The implementation substrate may change.

The semantic contract must not silently change with it.

---

# 3. Governing Principle

SCR separates:

```text
Semantic Meaning
      ↓
Semantic Contract
      ↓
Representation
      ↓
Transformation
      ↓
Lowering
      ↓
Provider
      ↓
Runtime
      ↓
Execution Substrate
```

These are different architectural layers.

Do not collapse them.

In particular:

```text
Specification ≠ Implementation
Status ≠ Specification
Graph ≠ Source of Truth
Representation ≠ Concept
Provider ≠ Semantic Authority
Backend ≠ Semantic Meaning
Filesystem ≠ Semantic Architecture
```

The governing rule is:

> **Never allow implementation convenience to silently redefine computational semantics.**

---

# 4. Agent Authority Model

Agents must distinguish three classes of information.

## 4.1 Normative

Defines what SCR means.

Examples:

* semantic definitions;
* explicit contracts;
* invariants;
* formally specified operations;
* architecture specifications;
* approved interface contracts.

Normative material has authority over implementation.

## 4.2 Descriptive

Describes current engineering reality.

Examples:

* implementation status;
* known limitations;
* blockers;
* current provider availability;
* build state;
* test state.

Descriptive material must not redefine semantics.

## 4.3 Derived

Generated from authoritative information.

Examples:

* relationship graphs;
* indexes;
* generated manifests;
* derived metadata;
* dependency views.

Derived artifacts must not silently become independent authorities.

---

# 5. Source-of-Truth Hierarchy

When sources conflict, resolve them in this order:

```text
1. Normative project architecture/specification
2. Parent semantic domain definition
3. Child semantic domain definition
4. Explicit interface/contract specification
5. Specification tests
6. Current implementation
7. Comments
8. Documentation/examples
9. Agent assumptions
```

For semantic-library control-plane files:

```text
101_definition.md
    ↓
normative meaning

102_status.yaml
    ↓
current engineering state

103_library.graph.json
    ↓
derived relationships
```

Therefore:

> `101_definition.md` may invalidate an implementation.

> `102_status.yaml` may describe an incomplete implementation.

> `103_library.graph.json` may expose relationships but does not establish semantic authority.

Never reverse these relationships.

---

# 6. Semantic Definitions Are Authoritative

A semantic definition describes what a domain means.

It may specify:

* purpose;
* scope;
* primitives;
* entities;
* values;
* operations;
* state;
* transitions;
* invariants;
* relationships;
* constraints;
* errors;
* composition;
* interfaces;
* representation requirements;
* runtime semantics;
* provider contracts;
* validation requirements.

A semantic definition is not an implementation plan.

Do not introduce implementation details into a semantic definition merely because they are convenient.

For example:

```text
Physics
    ≠
Chrono
```

```text
Field
    ≠
Tensor
```

```text
Position
    ≠
Rust struct
```

```text
Rendering
    ≠
Vulkan
```

Implementation technologies may realize semantic contracts. They do not define them.

---

# 7. Status Is Not Semantics

`102_status.yaml` describes the current state of implementation.

It may record:

* planned;
* specified;
* designed;
* partially implemented;
* implemented;
* tested;
* validated;
* blocked;
* deprecated.

Agents must not mark something as implemented merely because:

* a directory exists;
* a type exists;
* a stub compiles;
* an interface exists;
* documentation describes it;
* a test fixture exists;
* an external dependency provides equivalent functionality.

Implementation status requires evidence.

When status and implementation disagree, investigate the discrepancy rather than silently changing the status.

---

# 8. The Repository Is a Graph

The filesystem is an organization mechanism.

The semantic architecture is a graph.

Do not infer semantic relationships from directory placement.

Distinguish:

```text
Filesystem Relationship
        ≠
Semantic Relationship
        ≠
Implementation Dependency
```

For example:

```text
Morphology REFINES Geometry
```

is a semantic relationship.

Whereas:

```text
morphology.rs DEPENDS_ON geometry.rs
```

is an implementation dependency.

Likewise:

```text
Physics IMPLEMENTED_BY Provider
```

does not mean:

```text
Physics IS Provider
```

---

# 9. Controlled Relationship Vocabulary

Prefer explicit relationship types.

Use existing vocabulary where possible:

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
DERIVES_FROM
REFERENCES
EQUIVALENT_TO
```

Do not invent a new relationship when an existing relationship expresses the intended meaning.

If the distinction between two relationships is semantically important, document the distinction before encoding it.

---

# 10. Architecture Navigation

Before modifying a semantic domain, determine:

```text
Where am I?
What domain does this represent?
What is its parent?
What are its children?
What concepts does it define?
What interfaces does it implement?
What interfaces does it consume?
What semantic relationships does it have?
What implementations exist?
What providers exist?
What tests exist?
What MLIR representation exists?
What lowering exists?
What runtime path exists?
What status is recorded?
```

At minimum inspect:

```text
101_definition.md
102_status.yaml
```

and relevant:

```text
103_library.graph.json
interfaces
IR definitions
implementations
providers
transforms
lowering
tests
```

Do not begin implementation from a filename alone.

---

# 11. Task Scoping

Before changing anything, establish the scope of the task.

Use:

```text
Task
 ↓
Program Increment
 ↓
Domain
 ↓
Module
 ↓
Capability
 ↓
Function / Operation
```

Determine:

1. What has explicitly been requested?
2. What semantic unit is affected?
3. What contracts are upstream?
4. What contracts are downstream?
5. What implementation is currently responsible?
6. What tests establish current behavior?
7. What is explicitly outside scope?

Do not expand a task merely because an adjacent architectural improvement is visible.

Record or report discovered issues separately when they are outside scope.

---

# 12. Discovery Is Not Permission to Change

Do not assume:

```text
I discovered a problem
        ↓
I should fix it
```

Instead:

```text
DISCOVER
   ↓
CLASSIFY
   ↓
ASSESS
   ↓
DECIDE
   ↓
CHANGE
```

Discovery may reveal:

* ambiguity;
* inconsistency;
* missing specification;
* stale implementation;
* missing tests;
* architectural debt;
* incorrect status;
* dependency problems.

The discovery itself does not authorize changing the architecture.

---

# 13. Development Lifecycle

Substantive work should follow:

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
DESIGN TESTS
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

Not every task requires every stage.

However, semantic ambiguity must be resolved before implementation is allowed to define the missing behavior.

---

# 14. Inspect Before Editing

Before modifying code:

```text
1. Inspect the target.
2. Inspect its semantic definition.
3. Inspect its status.
4. Search for related concepts.
5. Search for existing implementations.
6. Search for interfaces.
7. Search for tests.
8. Inspect callers and consumers.
9. Inspect providers and adapters.
10. Inspect relevant MLIR representation.
```

Useful commands include:

```bash
find . -maxdepth 2 -type f | sort
find lib -type d | sort
find lib -type f | sort
rg "ConceptName" .
rg "operation_name|type_name|interface_name" .
find . -type f \( -name '*test*' -o -name '*lit*' \) | sort
```

Use the repository's actual build and test configuration.

Do not invent commands or workflows when the repository already defines them.

---

# 15. Do Not Implement Around Missing Semantics

If the semantic contract is incomplete, do not silently fill the gap with implementation assumptions.

Classify the problem:

```text
Specified
Partially specified
Ambiguous
Contradictory
Missing
```

For:

```text
Ambiguous
Contradictory
Missing
```

either:

1. resolve it from an authoritative source; or
2. stop and escalate if the decision is architectural.

Do not encode an architectural assumption merely because it makes the code compile.

---

# 16. Implementation Independence

SCR semantics must remain independent of implementation technology.

External technologies may be:

```text
Provider
Adapter
Lowering Target
Execution Substrate
Storage Mechanism
Transport
Rendering Backend
Numerical Backend
```

They are not automatically semantic authorities.

This applies to technologies including:

```text
Rust
C++
Python
LLVM
CUDA
ROCm
Vulkan
VulkanSceneGraph
Chrono
Eigen
CGAL
H3
OpenVDB
BLAS
AMQP implementations
```

and any future dependency.

The correct direction is:

```text
SCR Semantic Contract
        ↓
SCR Interface / Provider Contract
        ↓
Adapter
        ↓
External Technology
```

Never:

```text
External API
        ↓
SCR semantic definition
```

---

# 17. Semantic vs Physical Representation

Always distinguish:

```text
Semantic Object
      ≠
Language Representation
      ≠
IR Representation
      ≠
Memory Representation
      ≠
Device Representation
```

For example:

```text
Semantic Position
      ≠
Rust Position Struct
      ≠
MLIR Value
      ≠
GPU Buffer
      ≠
Vulkan Resource
```

Representation transformations must preserve the applicable semantic contract.

---

# 18. MLIR Policy

SCR is built on MLIR.

Use MLIR's mechanisms wherever they appropriately express the required semantics:

```text
Dialect
Operation
Type
Attribute
Region
Block
Interface
Trait
Verification
Rewrite
Canonicalization
Dialect Conversion
Analysis
Transform
Lowering
```

Before creating SCR-specific compiler infrastructure, ask:

```text
Can MLIR express this directly?
Can an existing MLIR mechanism express this?
Does SCR require additional semantics?
Would a new abstraction duplicate existing MLIR functionality?
```

Do not build a parallel compiler framework merely because a custom abstraction is convenient.

---

# 19. MLIR-First Representation Policy

SCR is built on MLIR, not beside it. MLIR is the canonical compiler representation substrate.

### Core rules

1. MLIR is the canonical compiler IR. SCR does not maintain a parallel IR.
2. Semantic concepts are represented through MLIR dialects, types, operations, attributes, interfaces, traits, verification, analyses, transformations, and lowering.
3. New abstractions must first be evaluated against MLIR before creating SCR-specific infrastructure.
4. New SCR dialects/interfaces/passes are preferred over new independent representation systems.
5. Rust structures must not become a shadow IR. They are permitted for configuration, APIs, handles, builder state, analysis results, diagnostics, metadata, provider configuration, runtime state, and interoperability.
6. JSON/YAML artifacts (101_definition.md, 102_status.yaml, 103_library.graph.json) must not become a canonical execution IR. They remain control-plane metadata.
7. Agents must stop and request architectural review if a second IR appears necessary.
8. Documentation terminology must never imply a second IR (e.g. "Semantic IR", "Domain IR", "SCR IR").
9. Any proposed deviation from MLIR as the sole representation substrate requires explicit architectural approval.

### Decision procedure for new abstractions

Before creating any SCR-specific infrastructure, ask:

1. Is it already an MLIR concept? → Use MLIR directly.
2. Can it be expressed using an existing MLIR dialect? → Use or compose existing MLIR dialects.
3. Can an SCR dialect express it? → Create/extend an SCR dialect.
4. Can an MLIR interface/trait/attribute express it? → Use MLIR interface/trait/attribute.
5. Can an MLIR analysis/pass/transformation express it? → Implement as MLIR compiler infrastructure.
6. Is the requirement genuinely semantic and missing from MLIR? → Extend SCR's MLIR dialect/interface ecosystem.
7. Is an entirely new representation still being proposed? → Stop. Document why MLIR is insufficient and obtain explicit architectural approval.

### Terminology

Use these terms consistently:

| Term | Meaning |
|------|---------|
| Semantic Model | Conceptual specification of computational meaning |
| Semantic MLIR | MLIR representation of SCR semantics |
| SCR Dialect | MLIR dialect defining SCR/domain semantics |
| SCR Interface | MLIR interface expressing a semantic capability/contract |
| Operation | MLIR operation carrying semantic computation |
| Type | MLIR/SCR semantic type |
| Attribute | MLIR/SCR semantic metadata |
| Analysis | Analysis over MLIR/SCR semantics |
| Transformation | Semantics-preserving or explicitly semantic MLIR transformation |
| Lowering | Progressive transformation toward concrete execution |
| Provider | Concrete implementation of a semantic contract |
| Runtime | Execution orchestration and resource management |
| Representation | Concrete or MLIR representation of semantic information |
| Semantic Graph | Conceptual relationship structure; not a second IR |
| Library Architecture Graph | Control-plane metadata graph; not an execution IR |

Avoid: "SCR IR", "Semantic IR", "Domain IR", "Custom IR", "Intermediate Representation" (when referring to anything other than MLIR itself).

---

# 20. Interfaces and Capabilities

Reusable computational capabilities should be represented through explicit interfaces where appropriate.

Examples include:

```text
Dynamical
Spatial
Temporal
Differentiable
Parallelizable
Vectorizable
Tileable
Reducible
Integrable
Stateful
Stateless
Streamable
Renderable
Distributable
Deterministic
Stochastic
Composable
Serializable
Persistable
Observable
Controllable
Optimizable
Learnable
Morphological
```

Interfaces should enable generic reasoning across domains.

Do not duplicate domain-specific implementations of capabilities that are already represented by an appropriate shared interface.

Conversely, do not force unrelated concepts into a shared interface merely because their names appear similar.

---

# 21. Functions and Operations

Every meaningful function or operation should have an explainable semantic contract.

Consider:

```text
Purpose
Inputs
Outputs
Preconditions
Postconditions
Invariants
Errors
Determinism
Side Effects
State Changes
Ownership
Lifecycle
Composition
Performance Characteristics
```

For MLIR operations additionally consider:

```text
Operands
Results
Attributes
Regions
Types
Traits
Interfaces
Verification
Canonicalization
Lowering
Effects
```

If behavior cannot be explained semantically, stop and investigate.

---

# 22. Determinism

Every meaningful computational operation must explicitly consider determinism.

Classify behavior as:

```text
Deterministic
Conditionally Deterministic
Stochastic
Nondeterministic
```

Where relevant, document:

```text
Source of nondeterminism
Seed/control mechanism
Reproducibility expectations
Equivalence criteria
Parallelism effects
Hardware-dependent behavior
```

Do not assume:

```text
Mathematical equivalence
        =
Numerical equivalence
        =
Bitwise equivalence
```

They are distinct guarantees.

---

# 23. Semantic Equivalence

Do not equate:

```text
same output on one test
```

with:

```text
semantic equivalence
```

Possible equivalence levels include:

```text
Exact
Numerical
Approximate
Distributional
Behavioral
Contractual
```

When replacing one implementation with another, determine which level the contract requires.

An optimization or provider substitution is valid only if the applicable semantic guarantees remain satisfied.

---

# 24. Invariants

Semantic correctness is defined by invariants, not merely plausible output.

Consider where applicable:

```text
Domain Invariants
Identity Invariants
Type Invariants
State Invariants
Temporal Invariants
Causal Invariants
Geometric Invariants
Topological Invariants
Physical Invariants
Conservation Laws
Ordering Invariants
Determinism Invariants
Lifecycle Invariants
Resource Invariants
```

When implementing a transformation, explicitly identify which invariants it must preserve.

---

# 25. Testing Philosophy

Tests should validate semantic contracts rather than merely implementation details.

The preferred hierarchy is:

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

Where applicable, test:

```text
Normal behavior
Boundary cases
Invalid inputs
Degenerate cases
Error behavior
Composition
Determinism
Invariant preservation
Serialization
MLIR verification
Canonicalization
Lowering
Runtime behavior
Provider behavior
Backend equivalence
```

A test that only demonstrates that an implementation runs is not necessarily a semantic test.

---

# 26. Specification Tests

Prefer:

```text
Semantic Contract
       ↓
Reference Behavior
       ↓
Implementation
       ↓
Conformance Test
```

Where practical, multiple providers should be capable of being tested against the same semantic expectations.

This is especially important for:

```text
CPU / GPU
Provider substitution
Numerical implementations
Parallel implementations
Distributed implementations
External-library providers
```

---

# 27. Provider Requirements

A provider implementing an SCR contract should document, where applicable:

```text
Semantic Coverage
Supported Types
Supported Operations
Precision
Determinism
Equivalence Guarantees
Performance Characteristics
Memory Behavior
Ownership
Lifecycle
Threading
Platform Restrictions
Failure Behavior
```

Provider limitations must not silently become semantic limitations.

If a provider supports only a subset of a semantic domain, represent that explicitly.

---

# 28. Fields, Streams, Messaging, Morphology and Rendering

These are computational concerns, not merely implementation plumbing.

Agents must preserve the following architectural distinctions.

### Fields

A field is a semantic computational structure.

Do not automatically equate:

```text
Field = Tensor
Field = Grid
Field = Buffer
Field = Texture
```

Those may be representations or providers.

### Streams

A semantic stream describes computational flow.

Do not equate:

```text
Stream = Transport
```

or:

```text
Stream = Broker
```

### Messaging

SCR may use an AMQP-oriented messaging model where appropriate.

AMQP is a messaging/protocol model or provider concern, not the semantic definition of every SCR message.

### Morphology

Morphology is a first-class computational domain.

Preserve both directions:

```text
Pattern
   ↕
Morphological Interpretation
   ↕
Morphological Structure
```

Do not reduce morphology to mesh generation or rendering.

### Rendering

Rendering is a computational domain and observation pathway.

Do not treat rendering as merely the final output stage.

A rendering backend is subordinate to the rendering contract.

---

# 29. Simulation and Dynamics

Keep these concepts distinct:

```text
Dynamics
    =
meaning of system evolution

Simulation
    =
computational realization of a model
```

Do not collapse simulation semantics into a particular numerical engine.

Likewise:

```text
Physics
    ≠
Dynamics
    ≠
Simulation
```

They may interact strongly without becoming interchangeable.

---

# 30. Semantic Graph vs Library Architecture Graph

SCR contains multiple graph concepts.

Do not conflate:

### Computational Semantic Graph

Represents computational meaning:

```text
Entities
Relationships
Operations
Constraints
Types
Capabilities
State
Events
Dataflow
Control Flow
Spatial Relations
Temporal Relations
Execution Requirements
```

### Library Architecture Graph

Represents project organization:

```text
Domains
Definitions
Modules
Interfaces
Implementations
Providers
Tests
Relationships
Status
```

The second is derived from project artifacts.

The first represents semantic computational structure.

They may correspond, but they are not the same graph.

---

# 31. Control-Plane Files

Where a semantic library directory uses the SCR control-plane model:

```text
101_definition.md
102_status.yaml
103_library.graph.json
```

agents must preserve their roles.

A future executable or golden-path specification may additionally exist, for example:

```text
104_golden-path.md
```

where applicable.

Do not put mutable implementation status into normative definitions.

Do not put normative semantics into status records.

Do not manually edit generated graph artifacts unless the repository explicitly requires it.

---

# 32. Generated and Derived Artifacts

Before modifying a generated artifact, determine:

```text
What generates it?
What is its source?
Is it committed?
Is it reproducible?
What validation checks it?
```

Prefer changing the authoritative source and regenerating the derived artifact.

Do not manually repair a generated artifact while leaving its source inconsistent.

---

# 33. Dependency Discipline

Before adding a dependency:

1. Determine whether the functionality already exists.
2. Determine whether MLIR or an existing SCR component provides the required capability.
3. Determine whether the dependency belongs at the semantic, compiler, provider, runtime, or tooling layer.
4. Determine whether it introduces semantic coupling.
5. Determine its platform and licensing implications.
6. Determine whether the dependency is required for the current milestone.

A dependency must not become part of semantic meaning merely because it provides a convenient implementation.

---

# 34. Performance

Correctness precedes optimization.

Use:

```text
Correctness
    ↓
Semantic Validation
    ↓
Measurement
    ↓
Optimization
    ↓
Equivalence Validation
```

Do not optimize based on assumptions.

Do not introduce representation-specific optimizations that alter semantic behavior without an explicit contract permitting the change.

Performance characteristics may themselves be part of a provider contract where required.

---

# 35. Concurrency and Parallelism

Concurrency must be explicit.

Consider:

```text
Ordering
Synchronization
Ownership
Mutability
Race behavior
Determinism
Memory visibility
Atomicity
Failure propagation
Cancellation
```

Do not assume that a sequential semantic definition automatically permits arbitrary parallelization.

A transformation must establish that required semantic guarantees remain valid.

---

# 36. Error Semantics

Errors are part of computational semantics where they affect observable behavior.

Distinguish:

```text
Invalid Input
Contract Violation
Unsupported Capability
Provider Limitation
Resource Exhaustion
Execution Failure
Numerical Failure
Environmental Failure
```

Do not convert semantic errors into arbitrary implementation exceptions without preserving their meaning.

---

# 37. Serialization, Persistence and References

Do not confuse:

```text
Semantic Identity
Representation Identity
Content Identity
Storage Location
```

A semantic reference must remain meaningful independently of where its representation happens to be stored.

Persistence mechanisms must not silently redefine semantic identity.

---

# 38. Security and Isolation

When modifying runtime, provider, messaging, storage, or external-library integration, consider:

```text
Trust Boundary
Capability Boundary
Resource Limits
Input Validation
Isolation
Credential Handling
Data Exposure
Provider Permissions
Failure Containment
```

Do not introduce hidden execution or network behavior merely for convenience.

---

# 39. Repository Conventions

Follow existing repository conventions before introducing new ones.

Prefer:

```text
Existing scripts
Existing build configuration
Existing test infrastructure
Existing naming conventions
Existing metadata schemas
Existing control-plane artifacts
Existing MLIR conventions
```

Do not introduce a competing convention without architectural justification.

For environment and build setup, use the repository's documented scripts.

Do not make bootstrap tooling:

* launch an interactive shell unexpectedly;
* silently modify shell startup files;
* silently install unrelated dependencies;
* implicitly modify the parent shell;
* mix incompatible LLVM/MLIR installations.

---

# 40. Current Development Environment

The preferred development environment for SCR is:

> **Arch Linux**

Other Linux distributions may be supported, but they are compatibility environments unless explicitly designated otherwise.

The canonical environment should use a coherent LLVM/MLIR toolchain.

Do not mix incompatible LLVM/MLIR installations.

When environment configuration is required, prefer the repository's separation between:

```text
Bootstrap
    ↓
Environment Activation
    ↓
Environment Check
    ↓
Build
    ↓
Test
```

A bootstrap script must not unexpectedly turn into an interactive development shell.

---

# 41. Vertical Slices Over Broad Stubs

Do not attempt to implement the entire SCR library because the directory tree contains many domains.

Prefer an executable vertical slice.

The current architectural direction is:

```text
Semantic Definition
       ↓
Semantic Model
       ↓
SCR Semantic MLIR
       ↓
MLIR Infrastructure
       ↓
Transformation / Lowering
       ↓
CPU Execution
       ↓
Simulation State
       ↓
Render State
       ↓
Rendering
       ↓
Visible Result
```

The v0.0.1 Golden Path is authoritative for the current vertical milestone.

Do not treat the existence of hundreds of semantic directories as a requirement to implement them all.

---

# 42. Minimal Implementation Principle

When implementing a new capability:

> **Implement the smallest semantically complete vertical slice that proves the contract.**

Do not begin with:

* speculative abstractions;
* generalized frameworks;
* unused providers;
* premature optimization;
* comprehensive backend support;
* complete domain coverage.

First establish:

```text
Meaning
 ↓
Contract
 ↓
Representation
 ↓
Execution
 ↓
Validation
```

Then generalize when evidence requires it.

---

# 43. Documentation Policy

Documentation should describe the architecture at the appropriate level.

Use:

```text
README.md
```

for repository-level orientation.

Use:

```text
GETTING_STARTED.md
```

for practical development setup and entry into the repository.

Use:

```text
AGENTS.md
```

for agent operating policy.

Use semantic library definitions for domain meaning.

Use status records for engineering state.

Use implementation documentation for implementation-specific behavior.

Do not duplicate normative domain definitions across documents.

---

# 44. When to Escalate

An agent must stop and request clarification or architectural direction when:

* two normative specifications conflict;
* a required semantic distinction is undefined;
* an implementation requires inventing domain semantics;
* a proposed change alters a foundational invariant;
* a provider limitation would require weakening the semantic contract;
* two architectural interpretations are materially incompatible;
* a change affects multiple foundational domains without an established relationship;
* a task requires changing the source of truth outside the assigned scope;
* security, persistence, identity, or execution semantics are unclear;
* the correct behavior cannot be established from authoritative project material.

Do not guess foundational architecture.

---

# 45. Definition of Done

A substantive change is complete only when the applicable requirements have evidence.

Consider:

```text
Semantic Contract
    ✓

Implementation
    ✓

Tests
    ✓

Validation
    ✓

Documentation
    ✓

Status
    ✓

Derived Artifacts
    ✓
```

Additional requirements may apply:

```text
MLIR Integration
Lowering
Provider
Runtime
Serialization
Cross-Substrate Validation
Performance
Security
```

These are conditional.

Do not mark a requirement complete merely because an artifact exists.

Completion means the requirement has been demonstrated.

---

# 46. Change Classification

Before finalizing a change, classify it.

### Semantic Change

Changes what a concept means.

Requires:

* specification review;
* invariant review;
* contract review;
* affected relationship review;
* tests;
* status update.

### Representational Change

Changes how meaning is represented.

Requires:

* representation correctness;
* preservation of semantics;
* transformation tests.

### Implementation Change

Changes how a contract is realized.

Requires:

* implementation tests;
* conformance validation;
* equivalence analysis where applicable.

### Provider Change

Changes an external implementation path.

Requires:

* provider capability review;
* contract coverage;
* provider-specific validation.

### Optimization

Changes execution characteristics while preserving the applicable semantic contract.

Requires:

* measurement;
* equivalence validation;
* regression testing.

### Documentation Change

Changes explanation without changing normative meaning.

Must not accidentally introduce semantic changes.

---

# 47. Review Questions

Before completing substantive work, ask:

### Semantics

```text
What does this mean?
What contract does it implement?
What invariants must hold?
```

### Architecture

```text
Where does this belong?
What relationships does it have?
What layer owns it?
```

### Representation

```text
What is semantic?
What is representational?
What is implementation-specific?
```

### Execution

```text
How does this reach MLIR?
How does it lower?
Which provider executes it?
What substrate runs it?
```

### Correctness

```text
What proves it works?
What proves invariants are preserved?
What proves equivalence?
```

### Scope

```text
Was this actually required?
Did the change expand beyond the assigned task?
```

---

# 48. Common Agent Failure Modes

Avoid these patterns.

## Coding from filenames

```text
directory exists
    ↓
therefore capability exists
```

False.

## Coding from documentation alone

Documentation may be stale.

Check definitions, status, tests and implementation.

## Treating implementation as specification

```text
current behavior
    ↓
therefore intended semantics
```

False.

## Treating external libraries as semantic authorities

```text
library API
    ↓
SCR semantics
```

Incorrect direction.

## Inventing semantics to make code compile

Compilation is not semantic validation.

## Creating abstractions prematurely

Do not build generalized infrastructure before a real semantic requirement establishes the need.

## Confusing representations with concepts

```text
Tensor ≠ Field
Mesh ≠ Morphology
GPU Buffer ≠ Data
Vulkan Resource ≠ Render Object
```

## Treating status as proof

A status label is evidence about reported state, not proof of correctness.

## Treating one passing test as equivalence

One output is not semantic equivalence.

## Expanding task scope

Do not refactor unrelated architecture merely because you discover an opportunity.

## Fixing generated artifacts directly

Change the authoritative source and regenerate.

---

# 49. Preferred Agent Mental Model

An SCR agent should reason in this order:

```text
                    ┌─────────────────────┐
                    │  What does it mean? │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ What is the contract?│
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ What relates to it? │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ How is it represented?│
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ How is it transformed?│
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ How is it lowered?  │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Which provider?     │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Where does it run?  │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ How is it validated?│
                    └─────────────────────┘
```

Never reverse this process merely because implementation details are easier to see.

---

# 50. The Three Questions

Before changing SCR, an agent should be able to answer:

### 1. What does this mean?

The semantic definition.

### 2. What currently exists?

The implementation and status.

### 3. How do I prove the change is correct?

The contract, tests and validation.

If any of these cannot be answered, investigate before implementing.

---

# 51. Final Rules

The following rules are mandatory:

1. **Semantics are authoritative.**
2. **Implementation does not define meaning.**
3. **Status does not define meaning.**
4. **The filesystem is not the semantic architecture.**
5. **Relationships must be explicit.**
6. **Providers implement contracts; they do not own them.**
7. **Representations must preserve semantics.**
8. **Use MLIR rather than unnecessarily duplicating MLIR infrastructure.**
9. **Do not invent missing foundational semantics.**
10. **Specify before implementing when semantic behavior is new.**
11. **Test contracts, not merely implementations.**
12. **Distinguish semantic, numerical and bitwise equivalence.**
13. **Validate invariants explicitly.**
14. **Prefer minimal complete vertical slices.**
15. **Do not expand task scope without justification.**
16. **Derived artifacts must remain derived.**
17. **Optimization follows correctness and measurement.**
18. **External technologies remain subordinate to SCR contracts.**
19. **When architecture is genuinely ambiguous, stop and escalate.**
20. **The code is not the architecture.**

---

# 52. Governing Principle

SCR exists to make computational meaning portable across representations, implementations and execution substrates.

Therefore:

```text
Meaning
  ↓
Contract
  ↓
Representation
  ↓
Transformation
  ↓
Implementation
  ↓
Execution
```

must remain traceable.

The agent's job is not merely to make the code work.

The agent's job is to make the implementation **faithfully realize the computational semantics of SCR**.

> **Do not let the implementation become the architecture.**

---

# 53. Subagent Delegation Policy

The primary agent must preserve main-context budget for architectural reasoning, verification, and coordination.

## Core Rule

> **Delegate bulk mechanical work to subagents. Never pollute main context with bulk task outputs.**

## When to Deploy Subagents

Deploy subagents for:

```text
Multi-file search-and-replace
Repository-wide grep/audit passes
Bulk file editing (3+ files)
Code review across multiple files
Repetitive mechanical fixes
Validation sweeps across many files
Any task producing output that would exceed ~200 lines in main context
```

## When to Work Inline

Work inline only for:

```text
Single-file surgical edits (1-2 changes)
Reading a file to understand context
Quick verification of a specific line
Coordination decisions
Architecture reasoning
User-facing responses
```

## Subagent Selection

Use the most appropriate subagent type:

```text
cavecrew-investigator    → read-only code location, grep, audit
cavecrew-builder         → 1-2 file surgical edit
cavecrew-reviewer        → diff/branch/file review
explore                  → codebase exploration, pattern search
general                  → complex multi-step tasks
```

## Output Discipline

When a subagent returns results:

1. Summarize findings in ≤5 lines in main context.
2. Do not paste full file contents or full grep output into main context.
3. If the subagent found violations, deploy fixers rather than fixing inline.
4. Track completion via todo list, not by displaying every edit.

## Parallelism

When multiple independent subtasks exist, deploy subagents in parallel within a single message. Do not serialize work that has no dependency.

## Context Budget Awareness

Main context is a finite resource. Every line of tool output consumed is a line unavailable for later reasoning. Treat main context as a budget:

```text
Subagent output summary:  ~5 lines per subtask
Main context remaining:   preserved for verification and coordination
```

If a task would require reading 5+ files to understand, delegate exploration to a subagent and consume only its summary.
