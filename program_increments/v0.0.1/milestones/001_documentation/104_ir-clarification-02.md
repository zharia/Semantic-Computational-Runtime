# SCR — Repository-Wide MLIR-First Architecture Alignment and Domain-IR Elimination

## Mission

Perform a **repository-wide architectural correction and consistency pass** on the Semantic Computational Runtime (SCR).

The architectural decision has already been made:

> **SCR does not have a separate Domain IR, Semantic IR, or SCR IR between the Semantic Model and MLIR.**

SCR is an **MLIR-based semantic computational environment**.

The semantic architecture, ontology, contracts, invariants, capabilities, domain semantics, transformations, provider model, and runtime semantics are SCR's intellectual and architectural contribution.

**MLIR is the canonical compiler representation and infrastructure substrate through which those semantics are represented, analyzed, transformed, verified, lowered, and executed.**

The task is therefore **not to redesign this architecture**.

The task is to bring the entire repository into unambiguous conformance with it.

---

# 1. Constitutional Architectural Rule

Establish the following as a repository-wide architectural law:

> **There is no separate SCR IR.**
>
> **There is no Domain IR.**
>
> **There is no Semantic IR preceding MLIR.**
>
> **There is no proprietary SCR compiler representation that is subsequently translated into MLIR.**
>
> **MLIR is the canonical representation and compiler substrate of SCR.**

The canonical architecture is:

```text
Application
    ↓
Semantic Model
    ↓
SCR Semantic MLIR
    ↓
MLIR Infrastructure
    ↓
Analysis / Verification / Transformation
    ↓
Lowering
    ↓
Provider
    ↓
Runtime
    ↓
Execution
    ↓
Observation
```

Where:

```text
SCR Semantic MLIR
=
MLIR
+
SCR Dialects
+
SCR Types
+
SCR Operations
+
SCR Attributes
+
SCR Interfaces
+
SCR Traits
+
SCR Semantics
+
SCR Verification
+
SCR Analyses
+
SCR Transformations
+
SCR Lowering
```

**SCR Semantic MLIR is not a second IR.**

It means:

> MLIR carrying SCR semantics.

---

# 2. Do Not Redesign SCR

Do not reinterpret this task as an invitation to reconsider:

* the semantic model;
* semantic domains;
* the provider architecture;
* the runtime architecture;
* the progressive abstraction model;
* the semantic graph;
* morphology;
* information-as-computation;
* hardware independence;
* adaptive execution;
* rendering;
* stream processing;
* messaging;
* the Golden Path;
* the role of MLIR.

These architectural decisions remain intact unless a direct contradiction is discovered.

The purpose of this task is **alignment and clarification**.

Do not introduce new architecture merely to solve terminology problems.

---

# 3. Existing Correct Direction

The repository already contains corrected terminology in parts of the current architecture, including the Golden Path's use of:

```text
Semantic Program
    ↓
SCR Semantic MLIR
    ↓
MLIR
```

Treat this as evidence of the intended direction.

The task is to propagate that model consistently throughout the repository.

Do not revert corrected terminology back toward:

```text
Semantic IR
Domain IR
SCR IR
```

---

# 4. Critical Distinction: Semantic Model vs Semantic MLIR

This distinction must be made explicit and consistent.

## Semantic Model

The Semantic Model defines **what SCR means**.

It contains concepts such as:

```text
Entity
Property
Value
Relationship
Context
State
Operation
Transformation
Capability
Constraint
Effect
Observation
Event
Process
Representation
Provider
Execution
```

It defines:

* ontology;
* semantics;
* relationships;
* contracts;
* invariants;
* capabilities;
* composition;
* transformations;
* domain meaning.

The Semantic Model is a **conceptual and normative specification**.

It is not an IR.

## Semantic MLIR

Semantic MLIR is the **MLIR representation of those semantics**.

It uses:

* MLIR dialects;
* MLIR operations;
* MLIR types;
* MLIR attributes;
* MLIR values;
* MLIR regions;
* MLIR blocks;
* MLIR symbols;
* MLIR interfaces;
* MLIR traits;
* MLIR verification;
* MLIR analysis;
* MLIR transformations;
* MLIR lowering.

Therefore:

```text
Semantic Model
    =
meaning/specification
```

while:

```text
Semantic MLIR
    =
MLIR representation of that meaning
```

They must never be described as:

```text
Semantic Model
    ↓
Semantic IR
    ↓
MLIR
```

---

# 5. Prohibited Architecture

The following architecture is explicitly prohibited:

```text
Application
    ↓
Semantic Model
    ↓
Domain IR
    ↓
MLIR
```

Also prohibited:

```text
Application
    ↓
Semantic Model
    ↓
Semantic IR
    ↓
MLIR
```

Also prohibited:

```text
Application
    ↓
SCR IR
    ↓
MLIR
```

Also prohibited:

```text
Semantic Graph
    ↓
Graph IR
    ↓
MLIR
```

Also prohibited:

```text
Domain Model
    ↓
Domain IR
    ↓
MLIR
```

unless the term is being explicitly discussed as a **historical or external architecture** rather than the SCR architecture.

---

# 6. MLIR-First Decision Rule

Add and enforce this rule:

> **Before creating any SCR-specific compiler representation or compiler abstraction, determine whether MLIR already provides the required mechanism.**

The decision order is:

```text
1. Existing MLIR construct?
        ↓
2. Existing MLIR dialect?
        ↓
3. Existing MLIR interface / trait / attribute?
        ↓
4. SCR MLIR dialect?
        ↓
5. SCR MLIR interface / trait / attribute?
        ↓
6. MLIR analysis / transformation / pass?
        ↓
7. MLIR dialect conversion / lowering?
        ↓
8. Only then consider whether a genuinely new mechanism is required.
```

A new independent representation is **not** an ordinary implementation option.

If an agent believes one is required, it must stop and document:

1. why existing MLIR constructs are insufficient;
2. which MLIR facilities were evaluated;
3. why an SCR dialect cannot solve the problem;
4. why an MLIR interface cannot solve the problem;
5. why an MLIR analysis/transformation/pass cannot solve the problem;
6. why dialect conversion/lowering cannot solve the problem;
7. why the proposed mechanism does not duplicate MLIR;
8. what explicit architectural authority permits it.

Absent such justification, the proposal must be rejected.

---

# 7. README Alignment

Review `README.md` completely.

Remove or rewrite every architectural statement that implies:

```text
Semantic Model
    ↓
Semantic IR
    ↓
MLIR
```

or:

```text
Domain / Semantic IR
    ↓
MLIR
```

The canonical README architecture must instead express:

```text
Application
    ↓
Semantic Model
    ↓
SCR Semantic MLIR
    ↓
MLIR Analysis / Verification / Transformation
    ↓
Lowering
    ↓
Provider
    ↓
Runtime
    ↓
Execution
```

Add an explicit statement equivalent to:

> SCR does not define a second intermediate representation alongside MLIR. SCR semantics are represented directly in MLIR through SCR dialects, types, operations, attributes, interfaces, traits, verification, analyses, transformations, and lowering infrastructure.

Make the distinction between:

```text
Semantic Model
```

and:

```text
Semantic MLIR
```

unambiguous.

---

# 8. Project Mandate Alignment

Review `003_PROJECT_MANDATE.md` in its entirety.

This document is foundational and must not contain an architectural model inconsistent with the final architecture.

Remove/rewrite all occurrences where the architecture implies:

```text
Domain IR
```

is a representation between semantic meaning and MLIR.

For example, statements conceptually equivalent to:

```text
Semantic Position
    ≠
Rust Position Struct
    ≠
Domain IR Value
    ≠
MLIR Value
    ≠
Memory Buffer
```

must be corrected.

A semantic object can be distinguished from:

```text
Rust implementation object
MLIR representation
memory representation
provider representation
```

but **Domain IR must not be inserted as an additional canonical representation**.

The correct conceptual distinction is:

```text
Semantic Meaning
    ≠
Implementation Object
    ≠
MLIR Representation
    ≠
Concrete Memory Representation
    ≠
Provider Representation
```

where appropriate.

Similarly, replace conceptual sequences such as:

```text
Concept
   ↓
Semantic Contract
   ↓
Domain IR
   ↓
MLIR Representation
```

with:

```text
Concept
   ↓
Semantic Contract
   ↓
Semantic MLIR
```

or:

```text
Concept
   ↓
Semantic Contract
   ↓
MLIR representation
```

---

# 9. AGENTS.md Alignment — Highest Priority

Review `AGENTS.md` particularly carefully.

This is a critical requirement because future autonomous agents will use this document as development authority.

Remove any instruction that teaches agents to construct:

```text
Domain IR
```

between semantic models and MLIR.

Replace the old Domain IR policy with an explicit:

# MLIR-First Representation Policy

The policy must state:

1. MLIR is SCR's canonical compiler representation.
2. SCR does not define a separate IR.
3. Domain IR is not an SCR architectural layer.
4. Semantic IR is not an SCR architectural layer.
5. SCR Semantic MLIR means MLIR carrying SCR semantics.
6. Semantic Model and Semantic MLIR are distinct concepts.
7. SCR dialects are MLIR dialects.
8. SCR interfaces are MLIR interfaces.
9. SCR transformations operate on MLIR.
10. SCR lowering operates through MLIR.
11. Rust structures must not become a shadow IR.
12. JSON/YAML artifacts must not become execution IR.
13. Existing MLIR mechanisms must be evaluated before introducing new SCR compiler mechanisms.
14. A proposed second IR requires explicit architectural approval.
15. Agents must not infer an IR architecture from directory structure.

The policy should be strong enough that a future coding agent cannot reasonably infer that it is supposed to implement:

```text
Domain IR → MLIR
```

---

# 10. Semantic Model Documentation

Review:

```text
docs/103_SEMANTIC_MODEL.md
```

Preserve the existing authoritative statement:

> There is no separate SCR IR. The semantic representation is MLIR + SCR dialects + SCR interfaces + SCR attributes + SCR semantics.

Strengthen it if necessary.

Make it one of the most prominent architectural rules in the document.

Explicitly define:

```text
Semantic Model
    ↓
specification of meaning

Semantic MLIR
    ↓
MLIR representation of meaning
```

Do not introduce any intermediate representation between them.

---

# 11. Architecture Documentation

Review:

```text
docs/102_ARCHITECTURE.md
```

Ensure the architecture expresses:

```text
Semantic Meaning
      ↓
Semantic Model
      ↓
SCR Semantic MLIR
      ↓
MLIR Infrastructure
      ↓
Analysis / Transformation
      ↓
Lowering
      ↓
Provider
      ↓
Runtime
      ↓
Execution
```

The document must clearly separate:

```text
Meaning
Representation
Transformation
Lowering
Provider
Runtime
Hardware
```

while recognizing that the compiler representation is MLIR.

Use the principle:

> **Meaning ≠ Representation ≠ Transformation ≠ Lowering ≠ Provider ≠ Runtime ≠ Hardware**

but clarify that the SCR compiler representation is MLIR-based.

---

# 12. Golden Path Alignment

Review:

```text
program_increments/v0.0.1/104_golden-path.md
```

Preserve the already-correct:

```text
Semantic Program
    ↓
SCR Semantic MLIR
    ↓
MLIR
```

terminology.

Search the entire Golden Path specification for any residual language suggesting:

```text
Domain IR
Semantic IR
SCR IR
```

Remove the ambiguity.

The conceptual Golden Path should be:

```text
Core
 ↓
Dynamics
 ↓
Simulation
 ↓
Semantic Program
 ↓
SCR Semantic MLIR
 ↓
MLIR verification / analysis / transformation
 ↓
Lowering
 ↓
CPU Provider
 ↓
Simulation State
 ↓
Render Projection
 ↓
Render State
 ↓
Rendering Provider
 ↓
VSG / Vulkan
 ↓
Visible Result
```

The Golden Path must demonstrate the MLIR-native architecture rather than introduce an intermediate SCR representation.

---

# 13. Semantic Library Audit

Audit all directories under:

```text
lib/
```

Do not assume:

```text
directory = dialect
```

and do not assume:

```text
directory = IR
```

The library is the semantic architecture and knowledge organization.

A semantic domain can contain:

* definitions;
* concepts;
* contracts;
* invariants;
* interfaces;
* operations;
* implementation specifications;
* tests;
* provider mappings;
* documentation.

Only the appropriate executable semantic constructs become MLIR dialect constructs.

Do not create a separate domain representation merely because the filesystem is organized by semantic domains.

---

# 14. Directory-to-Dialect Rule

Explicitly document:

> A semantic library domain does not automatically imply a separate MLIR dialect.

The correct decision process is:

```text
Semantic Domain
      ↓
Identify semantic boundary
      ↓
Determine representation requirements
      ↓
Can existing MLIR dialects express it?
      ↓
Can existing SCR dialects express it?
      ↓
Is a distinct dialect semantically justified?
      ↓
If yes → define an MLIR dialect
```

Do not mechanically generate:

```text
lib/401_Morphology
        ↓
Morphology IR
        ↓
Morphology MLIR
```

Instead:

```text
lib/401_Morphology
        ↓
Morphology semantics
        ↓
SCR Morphology MLIR dialect
```

where a dialect is actually required.

---

# 15. Rust Implementation Audit

Inspect the actual Rust implementation.

Search for potential shadow-IR structures such as:

```text
SemanticOperation
SemanticValue
SemanticType
SemanticModule
SemanticRegion
SemanticBlock
SemanticGraph
IROperation
IRValue
IRNode
IRModule
```

Do not automatically delete them.

Classify each structure as one of:

* MLIR wrapper;
* MLIR handle;
* API object;
* runtime state;
* configuration;
* analysis result;
* diagnostic;
* provider state;
* transient builder;
* metadata;
* actual duplicate IR.

If it is an actual duplicate compiler representation, refactor it toward MLIR.

If it is a legitimate host-language API abstraction, document why it is not an IR.

The key question is:

> **Does this structure become the canonical representation that must be translated into MLIR?**

If yes, it is a shadow IR and must be corrected.

---

# 16. JSON/YAML Audit

Review all structured metadata.

In particular:

```text
101_definition.md
102_status.yaml
103_library.graph.json
```

Ensure:

### Definition

Defines normative semantics.

### Status

Defines engineering state.

### Library graph

Defines derived control-plane relationships.

None may become a hidden execution IR.

Likewise, no generated JSON/YAML schema may become a canonical compiler representation.

---

# 17. Semantic Graph Audit

SCR's Semantic Graph remains valid.

Do not remove it.

But distinguish:

```text
Semantic Graph
```

from:

```text
Compiler IR
```

The semantic graph describes:

* entities;
* relationships;
* dependencies;
* state;
* capabilities;
* constraints;
* transformations;
* provenance;
* observations;
* execution requirements.

It must not silently become:

```text
Semantic Graph
    ↓
Custom Graph IR
    ↓
MLIR
```

Where graph semantics are executable, represent them using appropriate MLIR constructs.

---

# 18. Progressive Abstraction Audit

Preserve the semantic abstraction levels:

```text
L0 — Mathematical primitives
L1 — Computational primitives
L2 — Structural semantics
L3 — Domain capabilities
L4 — Composite domain models
L5 — System semantics
```

These are **semantic abstraction levels**, not IR levels.

Do not implement:

```text
L0 IR
L1 IR
L2 IR
L3 IR
L4 IR
L5 IR
```

as separate representations.

They may all be represented within the MLIR ecosystem.

---

# 19. Higher-Order Semantics

Preserve the composition model.

For example:

```text
field.sample
    ↓
interaction
    ↓
dynamics.integrate
    ↓
state.transition
```

may compose into:

```text
agent.propagate
```

and eventually:

```text
population.evolve
```

These are semantic compositions.

Represent them through MLIR operations, regions, SSA values, interfaces, attributes and transformations.

Do not introduce a composition IR.

---

# 20. Morphology

Preserve the bidirectional morphology relationship:

```text
Pattern
   ↓
Morphological Interpretation
   ↓
Morphological Structure
   ↓
Structural Analysis
   ↓
Pattern
```

Morphology is a semantic domain.

It is not itself:

* a mesh IR;
* a voxel IR;
* a geometry IR;
* a rendering IR;
* a custom morphological IR.

Morphological semantics should remain representation-independent.

Possible materializations include:

```text
Mesh
Voxel
Implicit Surface
Particle
Parametric Form
Procedural Form
Field
Graph
```

Those are representations/materializations, not a separate semantic compiler IR.

---

# 21. Provider Architecture Audit

Ensure provider architecture remains:

```text
SCR Semantic MLIR
        ↓
Analysis
        ↓
Transformation
        ↓
Lowering
        ↓
Provider Contract
        ↓
Provider
        ↓
External Technology
```

External technologies such as:

```text
LLVM
Eigen
CGAL
H3
OpenVDB
Chrono
VulkanSceneGraph
CUDA
ROCm
```

remain implementation resources/providers.

They are not semantic authorities.

Do not allow their APIs to become semantic architecture.

---

# 22. Rendering Audit

Preserve rendering as a first-class semantic/computational domain.

The architecture may ultimately resemble:

```text
SCR Semantic MLIR
       ↓
Render semantics
       ↓
MLIR transformation/lowering
       ↓
Render provider
       ↓
Rust renderer interface
       ↓
C++ adapter
       ↓
VulkanSceneGraph
       ↓
Vulkan
       ↓
GPU
```

Do not introduce an independent SCR Render IR.

If a render dialect is required, it is an **MLIR dialect**.

---

# 23. Stream and Messaging Audit

Preserve first-class stream and messaging semantics.

Examples include:

```text
Source
Sink
Channel
Message
Event
Signal
Flow
Pipeline
Map
Filter
Reduce
Join
Merge
Split
Window
Buffer
Queue
Backpressure
```

and AMQP-oriented concepts:

```text
Exchange
Queue
Routing
Publication
Subscription
Delivery
Acknowledgement
Ordering
Durability
Backpressure
```

These are semantic concepts.

If executable representations are required, they should be represented using MLIR/SCR MLIR constructs.

Do not introduce:

```text
Stream IR
Messaging IR
AMQP IR
```

as separate compiler representations.

---

# 24. Hardware Independence

Do not let this correction weaken SCR's hardware-aware execution architecture.

SCR may reason about:

```text
CPU
GPU
Accelerator
Vector Width
Cache
NUMA
Memory Bandwidth
Occupancy
Latency
Throughput
Interconnect
Power
Thermal Constraints
Memory Pressure
```

These remain execution capabilities/resources.

Hardware-aware compilation should use MLIR's analysis, transformation and lowering infrastructure wherever appropriate.

Do not create a hardware IR simply to encode hardware characteristics.

---

# 25. Terminology Authority

Create or update a canonical terminology section.

Use:

| Term                       | Definition                                                                       |
| -------------------------- | -------------------------------------------------------------------------------- |
| Semantic Model             | Normative conceptual specification of computational meaning                      |
| Semantic MLIR              | MLIR representation of SCR semantics                                             |
| SCR Dialect                | MLIR dialect defining SCR semantic constructs                                    |
| SCR Operation              | MLIR operation carrying SCR semantics                                            |
| SCR Type                   | MLIR/SCR semantic type                                                           |
| SCR Attribute              | MLIR/SCR semantic metadata                                                       |
| SCR Interface              | MLIR interface expressing a semantic capability or contract                      |
| Semantic Graph             | Conceptual relationship structure describing semantic entities and relationships |
| Representation             | A computational or materialized encoding of semantic information                 |
| Analysis                   | Analysis over semantic MLIR                                                      |
| Transformation             | MLIR/SCR transformation over semantic representation                             |
| Lowering                   | Progressive transformation toward concrete execution                             |
| Provider                   | Concrete implementation satisfying a semantic contract                           |
| Runtime                    | Execution orchestration and resource management                                  |
| Library Architecture Graph | Derived control-plane metadata                                                   |
| Semantic IR                | **Not an SCR architectural term**                                                |
| Domain IR                  | **Not an SCR architectural term**                                                |
| SCR IR                     | **Not an SCR architectural term**                                                |

The last three entries should be explicitly marked as prohibited/obsolete architectural terminology.

---

# 26. Search Strategy

Perform repository-wide searches for all variants of:

```text
Domain IR
DomainIR
domain IR
domain_ir
domain-ir

Semantic IR
SemanticIR
semantic IR
semantic_ir
semantic-ir

SCR IR
SCRIR
scr IR
scr_ir
scr-ir

Intermediate Representation
intermediate representation
```

Also search for architectural sequences such as:

```text
Semantic Model → IR
Semantic Model -> IR
Semantic Model → MLIR
Semantic Model -> MLIR
Domain → IR
Domain → MLIR
Model → IR → MLIR
Concept → Contract → IR
```

Review every match manually.

Do **not** perform blind search-and-replace.

Some occurrences may correctly describe:

* MLIR;
* external technologies;
* historical architectures;
* comparative architecture;
* compiler theory.

Only SCR's architecture must be corrected.

---

# 27. Documentation Consistency

After corrections, every authoritative document must describe the same architecture.

At minimum synchronize:

```text
README.md
AGENTS.md
001_INTRODUCTION.md
002_GETTING_STARTED.md
003_PROJECT_MANDATE.md

docs/101_BACKGROUND.md
docs/102_ARCHITECTURE.md
docs/103_SEMANTIC_MODEL.md
docs/104_SEMANTIC_INVARIANTS.md

program_increments/v0.0.1/000_spec.md
program_increments/v0.0.1/101_definition.md
program_increments/v0.0.1/102_status.yaml
program_increments/v0.0.1/103_library.graph.json
program_increments/v0.0.1/104_golden-path.md

public-documentation/
lib/
```

Do not assume the list is exhaustive.

Search the complete repository.

---

# 28. Architectural Invariants

Add or update architectural invariants to capture this decision.

At minimum establish:

### Representation Invariant

> SCR has one canonical compiler representation substrate: MLIR.

### No Shadow IR Invariant

> SCR must not maintain a second compiler IR that duplicates or precedes MLIR.

### Semantic Representation Invariant

> SCR semantic constructs requiring executable representation are represented using MLIR mechanisms.

### MLIR-First Invariant

> Existing MLIR facilities must be preferred before SCR-specific compiler mechanisms are introduced.

### Dialect Extension Invariant

> When MLIR lacks domain-specific semantics, SCR extends MLIR through dialects, interfaces, types, attributes, operations, verification, analyses, transformations and lowering rather than introducing a parallel IR.

### Semantic Model Invariant

> The Semantic Model specifies meaning; it is not a compiler IR.

---

# 29. Relationship to Existing Semantic Invariants

Ensure the correction remains consistent with:

```text
SI-001 Semantic Primacy
SI-002 Meaning Independence
SI-004 Type Meaning Preservation
SI-007 Contract Preservation
SI-019 Compositionality
SI-020 Composition Closure
SI-028 Representation Independence
SI-038 Provider Independence
SI-040 Hardware Independence
SI-068 MLIR Consistency
SI-069 Single Semantic Representation
SI-073 Compilation Must Be Semantics-Preserving
SI-080 Semantic Single Source of Truth
```

In particular, make sure:

```text
SI-069 Single Semantic Representation
```

cannot be interpreted as permitting a separate SCR IR.

Its intended meaning must be explicit:

> The semantic computational representation is singular and MLIR-based; SCR does not maintain a parallel compiler representation.

---

# 30. Testing and Verification

Add practical checks where useful.

The repository should have a mechanism capable of detecting future architectural regressions.

For example, a documentation consistency check can flag phrases such as:

```text
Domain IR
Semantic IR
SCR IR
```

when used as SCR architecture.

Do not prohibit legitimate references to:

```text
MLIR IR
MLIR's IR
IR operation
IR type
IR infrastructure
```

The objective is to prevent **architectural ambiguity**, not the use of the word "IR."

---

# 31. Build and Test

After making changes:

1. run formatting;
2. run static analysis;
3. run the existing test suite;
4. run documentation checks if present;
5. run MLIR-related tests;
6. verify no broken references were introduced;
7. verify generated metadata remains valid;
8. verify the Golden Path remains internally coherent.

Do not weaken tests to make the task pass.

---

# 32. Final Autonomous-Agent Test

Before completing the task, perform this thought experiment:

> Imagine a new coding agent has never seen SCR before and is given only this repository.

Ask:

> Would that agent conclude that SCR contains a proprietary Semantic IR or Domain IR that is eventually translated into MLIR?

If the answer is anything other than an unequivocal **no**, continue correcting the repository.

The intended conclusion must be:

> **SCR is an MLIR-based semantic computational environment.**
>
> **SCR defines computational semantics and contracts.**
>
> **Those semantics are represented directly in MLIR through SCR dialects and MLIR mechanisms.**
>
> **There is no intermediate Domain IR.**
>
> **There is no separate Semantic IR.**
>
> **MLIR is the canonical compiler representation substrate.**
>
> **Providers supply concrete implementations.**
>
> **The runtime determines how, where, and with which implementation the semantics execute.**

---

# 33. Required Final Report

At completion provide:

## 33.1 Repository Audit

List:

* files inspected;
* searches performed;
* architectural contradictions discovered.

## 33.2 Corrections

For each significant correction provide:

```text
File
Section
Old architectural meaning
New architectural meaning
```

## 33.3 Shadow-IR Audit

Explicitly state whether any custom IR remains.

For every remaining representation-like structure, classify it as:

```text
MLIR representation
MLIR wrapper
API abstraction
Runtime state
Analysis result
Provider representation
Metadata
Configuration
Other
```

and explain why it is not a compiler IR.

## 33.4 MLIR Usage

List the MLIR mechanisms SCR currently uses or intends to use.

## 33.5 Documentation Alignment

Confirm that:

```text
README
AGENTS
Project Mandate
Architecture
Semantic Model
Golden Path
Public Documentation
Library Documentation
```

all describe the same representation architecture.

## 33.6 Verification

Report:

```text
Formatting:
Static analysis:
Tests:
MLIR integration:
Documentation consistency:
Architectural terminology search:
Golden Path consistency:
```

## 33.7 Remaining Issues

There should be **no known unresolved architectural ambiguity**.

If one genuinely remains, identify it explicitly rather than silently accepting it.

---

# 34. Final Constitutional Statement

The repository should converge on this exact architectural understanding:

```text
                         SCR
                          │
          ┌───────────────┴────────────────┐
          │                                │
 Semantic Architecture               MLIR Infrastructure
          │                                │
  Ontology                         Dialects
  Semantics                        Operations
  Contracts                        Types
  Invariants                       Attributes
  Capabilities                     Interfaces
  Composition                      Traits
  Domain Meaning                   Verification
  Provider Contracts               Analysis
          │                         Transformation
          │                         Lowering
          └───────────────┬────────────────┘
                          │
                         MLIR
                          │
                       Provider
                          │
                    Execution Runtime
                          │
                  CPU / GPU / Accelerator
```

There is deliberately **no `Domain IR` box**.

There is deliberately **no `Semantic IR` box**.

There is deliberately **no `SCR IR` box**.

The semantic model is not another compiler representation.

MLIR is not merely a backend target.

**MLIR is the substrate on which SCR's semantic computational architecture becomes executable.**

---

# 35. Governing Principle

Preserve the project's fundamental principle:

> **Never confuse what a computation means with how a computation happens to be implemented.**

For this specific architectural issue, enforce the stronger formulation:

> **Never introduce a second compiler representation merely because SCR has not yet fully exploited MLIR.**

And:

> **When SCR needs additional expressive power, extend MLIR before inventing another representation.**

The burden of proof is on any proposed independent representation.

**MLIR is the substrate. SCR is the semantic architecture built upon it.**
