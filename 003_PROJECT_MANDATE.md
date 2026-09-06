# Semantic Computational Runtime

## Project Mandate

**Project:** Semantic Computational Runtime
**Acronym:** SCR
**Repository:** `zharia/Semantic-Computational-Runtime`
**Project Type:** Open-source computational architecture and research/engineering project
**Primary Foundation:** MLIR
**Mandate Status:** Foundational
**Version:** 1.0.0
**Date:** 2026-09-05

---

# 1. Mandate

The Semantic Computational Runtime (SCR) exists to investigate, design, and progressively implement a computational environment in which **semantic meaning is separated from implementation technology and retained as an active part of the compilation and execution process**.

The project shall establish an architecture in which applications can express computational meaning without being required to prematurely commit that meaning to a particular:

* programming language;
* data representation;
* algorithm;
* library;
* runtime;
* execution model;
* hardware platform;
* storage mechanism;
* communication mechanism;
* rendering system.

The central proposition of SCR is:

> **Computational semantics can become a portable compilation substrate.**

SCR therefore seeks to establish a common semantic environment in which heterogeneous computational domains can be represented as formally specified, composable semantics and progressively transformed into concrete implementations across heterogeneous execution substrates.

The project is not merely an abstraction layer.

It is an attempt to make **meaning itself computationally actionable**.

---

# 2. The Problem

Modern computational systems are fragmented across specialized libraries, frameworks, programming languages, APIs, runtimes, execution models, and hardware targets.

A single computational system may simultaneously require:

* mathematics;
* numerical computation;
* fields;
* geometry;
* topology;
* graphs;
* spatial structures;
* physics;
* dynamics;
* simulation;
* agents;
* neural computation;
* perception;
* control;
* optimization;
* learning;
* messaging;
* streams;
* rendering;
* distributed execution.

Each subsystem commonly establishes its own:

* data model;
* type system;
* API;
* execution model;
* lifecycle;
* memory assumptions;
* scheduling assumptions;
* error semantics;
* optimization mechanisms;
* hardware integration.

The result is semantic fragmentation.

Applications become coupled not only to **what they compute**, but to the technologies used to compute it.

Changing a numerical solver, geometry engine, rendering system, accelerator, storage mechanism, or execution strategy can consequently require changes far above the implementation boundary.

SCR exists to investigate whether a common semantic layer can reduce this coupling without eliminating the ability to exploit specialized implementations.

---

# 3. Central Architectural Proposition

SCR establishes the following conceptual separation:

```text
Semantic Meaning
       ↓
Semantic Contract
       ↓
Representation
       ↓
Transformation
       ↓
Implementation
       ↓
Execution
       ↓
Observation
```

The semantic definition establishes what a computation means.

The implementation establishes how that meaning is realized.

The execution substrate determines where and through which concrete machinery it executes.

These layers must not be silently conflated.

---

# 4. Semantic Primacy

The fundamental architectural principle of SCR is:

> **The implementation does not define the semantics.**

A semantic object is not identical to any particular implementation of that object.

For example:

```text
Semantic Position
       ≠
Rust Position Struct
       ≠
MLIR Value
       ≠
Memory Buffer
       ≠
GPU Buffer
       ≠
Vulkan Resource
```

These may represent or realize the same semantic concept at different levels, but they are not the same architectural entity.

A core test of semantic primacy is:

> Would this property remain true if the implementation changed?

If not, the property is probably implementation-specific rather than semantic.

---

# 5. SCR and MLIR

SCR shall be built **on top of MLIR**, not beside it.

MLIR provides the compiler infrastructure required for:

* intermediate representation;
* operations;
* values;
* types;
* attributes;
* regions;
* dialects;
* interfaces;
* traits;
* verification;
* rewriting;
* canonicalization;
* transformation;
* analysis;
* dialect conversion;
* lowering;
* target-specific compilation.

SCR provides the semantic architecture that determines:

* what computations mean;
* what semantic contracts require;
* how semantic domains relate;
* what capabilities exist;
* what transformations preserve meaning;
* how providers relate to semantics;
* how execution can remain independent of semantic identity.

SCR shall not attempt to become a competing general-purpose compiler infrastructure.

The intended relationship is:

```text
SCR Semantic Model
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
Execution Substrate
```

---

# 5a. MLIR-First Representation Policy

### Architectural law

> SCR is built on MLIR, not beside it.

### Representation law

> There is one compiler representation substrate: MLIR.

### Semantic law

> SCR contributes semantics, contracts, interfaces, domain meaning, verification requirements, transformations, provider contracts, and execution independence.

### Anti-duplication law

> SCR shall not reproduce MLIR's IR, type, SSA, region, operation, interface, pass, transformation, or lowering mechanisms where MLIR already provides suitable facilities.

### Extension law

> New SCR compiler abstractions should first be expressed using existing MLIR mechanisms. New SCR dialects/interfaces/passes are preferred over independent representation systems.

---

# 6. The Semantic Computational Model

SCR shall treat computation as more than source code operating on passive data.

The semantic model may include:

* values;
* types;
* entities;
* relationships;
* operations;
* state;
* events;
* fields;
* graphs;
* hypergraphs;
* streams;
* patterns;
* morphology;
* geometry;
* topology;
* capabilities;
* constraints;
* resources;
* observations;
* transformations;
* temporal relationships;
* causal relationships;
* provenance.

The resulting model is closer to:

```text
Information
    ↕
Structure
    ↕
Relationships
    ↕
State
    ↕
Transformation
    ↕
Dynamics
    ↕
Observation
```

than to a strict program/data distinction.

---

# 7. Semantic Domains

SCR shall support a growing ecosystem of interoperable semantic domains.

Initial and intended domains include:

```text
Core
Data
Mathematics
Graphs
Fields
Geometry
Topology
Morphology
Physics
Dynamics
Simulation
Agents
Neural Computation
Perception
Control
Optimization
Learning
Adaptation
Evolution
Ecology
Spatial Computing
Stream Processing
Messaging
Rendering
Analysis
Interfaces
Transforms
Lowering
Providers
```

These domains shall not be treated as isolated silos.

The semantic architecture is a graph.

A domain may:

* contain another domain;
* refine another domain;
* specialize another domain;
* compose with another domain;
* consume another domain;
* produce values used by another domain;
* constrain another domain;
* transform another domain;
* lower through a provider;
* interact with multiple execution substrates.

Therefore:

```text
Filesystem Tree
      ≠
Semantic Architecture
```

The filesystem organizes the implementation.

The semantic graph describes computational meaning.

---

# 8. Domain Requirements

Every semantic domain shall progressively establish:

1. a defined semantic boundary;
2. semantic primitives;
3. types;
4. values;
5. operations;
6. invariants;
7. relationships to other domains;
8. state and transitions where applicable;
9. capability requirements;
10. implementation boundaries;
11. provider boundaries;
12. testing requirements;
13. validation requirements;
14. extensibility rules;
15. versioning expectations.

Domains must not become arbitrary collections of implementation APIs.

---

# 9. Semantic Library Control Plane

Every significant semantic domain shall progressively adopt a common control-plane structure:

```text
<domain>/
├── 101_definition.md
├── 102_status.yaml
└── 103_library.graph.json
```

Their authority is deliberately different.

### `101_definition.md`

Normative semantic authority.

Defines:

* meaning;
* domain boundaries;
* primitives;
* entities;
* values;
* operations;
* invariants;
* composition;
* relationships;
* state;
* transitions;
* errors;
* observability;
* representations;
* provider boundaries;
* testing requirements.

### `102_status.yaml`

Mutable engineering state.

Records:

* implementation status;
* test status;
* validation status;
* MLIR status;
* provider status;
* backend status;
* known gaps;
* blockers;
* risks;
* open questions;
* files;
* functions;
* traceability;
* development history.

### `103_library.graph.json`

Derived machine-readable relationship graph.

It shall describe how the semantic library relates as a whole.

It must not become an independent source of truth.

The governing rule is:

> **Definition is normative. Status is descriptive. Graph is derived.**

---

# 10. Semantic Relationships

SCR shall distinguish semantic relationships from implementation dependencies.

The semantic architecture should support a controlled vocabulary including:

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

For example:

```text
MORPHOLOGY REFINES GEOMETRY
```

is a semantic relationship.

Whereas:

```text
morphology → Rust crate
```

is an implementation dependency.

These must not be conflated.

---

# 11. Progressive Abstraction

SCR shall retain semantic information for as long as practical before committing to implementation-specific details.

The intended progression is:

```text
Concept
   ↓
Semantic Contract
   ↓
SCR Semantic MLIR
   ↓
MLIR Infrastructure
   ↓
Generic Implementation
   ↓
Provider
   ↓
Backend Adapter
   ↓
Hardware / External Runtime
```

The same semantic concept may therefore have multiple representations and implementations.

This is a foundational mechanism for portability, specialization, optimization, and provider substitution.

---

# 12. Capabilities

Operations shall not be characterized solely by their semantic domain.

They may also expose capabilities such as:

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
Invertible
Composable
Interpolatable
Queryable
Mutable
Immutable
```

Capabilities provide a bridge between semantic meaning and compiler/runtime decisions.

For example:

```text
Dynamical
   +
Parallelizable
   +
Vectorizable
```

may allow a compiler or runtime to consider:

* SIMD execution;
* GPU execution;
* parallel scheduling;
* kernel fusion.

Capabilities must therefore remain semantically meaningful rather than becoming arbitrary optimization hints.

---

# 13. Higher-Order Composition

SCR shall support semantic composition across abstraction levels.

Primitive operations may compose into higher-order concepts:

```text
field.sample
      ↓
interaction
      ↓
dynamics.integrate
      ↓
state.transition
```

which may form:

```text
agent.propagate
```

which may compose into:

```text
population.evolve
```

which may compose into:

```text
ecosystem.simulate
```

Semantic identity must remain traceable as abstraction increases.

The architecture should therefore support:

```text
Mathematics
    ↓
Computation
    ↓
Domain Model
    ↓
System Model
    ↓
Application
```

without requiring each level to discard the semantic information established by the previous level.

---

# 14. Provider Architecture

A provider is an implementation mechanism capable of satisfying a semantic contract.

Potential provider categories include:

* CPU;
* GPU;
* accelerator;
* numerical;
* physics;
* geometry;
* rendering;
* neural;
* spatial;
* storage;
* messaging;
* distributed;
* external runtimes.

A provider is not the semantic authority.

Provider selection may consider:

* capabilities;
* hardware;
* resources;
* locality;
* performance;
* determinism;
* precision;
* compatibility;
* scheduling;
* cost.

The architecture must distinguish:

```text
API Compatibility
        ≠
Semantic Equivalence
```

---

# 15. Adaptive Execution

The long-term runtime architecture shall support adaptive execution in which realization decisions can be made from semantic requirements and current execution conditions.

The conceptual loop is:

```text
Semantics
    ↓
Capability Analysis
    ↓
Resource Analysis
    ↓
Provider Selection
    ↓
Scheduling
    ↓
Compilation / Specialization
    ↓
Execution
    ↓
Observation / Telemetry
    ↓
Re-analysis
    ↺
```

This is an architectural direction rather than a claim that the complete loop is already implemented.

The runtime should ultimately answer two different questions:

> What does this computation mean?

and:

> What is the best valid way to execute that meaning here?

---

# 16. Semantic Equivalence

Semantic equivalence is a foundational research and engineering objective.

Given semantic contract `C`, SCR may ultimately reason about:

```text
A ≡C B
```

meaning that implementations `A` and `B` satisfy the same relevant semantic contract under the applicable conditions.

Equivalence must be stronger than API compatibility.

It may require consideration of:

* observable state;
* invariants;
* constraints;
* numerical tolerances;
* temporal semantics;
* ordering;
* nondeterminism;
* precision;
* side effects;
* approximation;
* resource behavior.

Semantic equivalence is necessary if provider substitution, specialization, optimization, and alternate implementations are to become principled rather than heuristic.

The project shall treat equivalence as an explicit research problem rather than assuming arbitrary implementations are interchangeable.

---

# 17. Information as a Computational Substrate

SCR shall treat information structures as potentially computational rather than merely representational.

Relevant structures include:

* fields;
* graphs;
* hypergraphs;
* streams;
* tensors;
* spatial structures;
* semantic state;
* topology;
* patterns;
* observations.

These structures should be capable of participating in composition and transformation across domains.

For example:

```text
field
   ↓
pattern
   ↓
morphology
   ↓
geometry
   ↓
rendering
```

while another computation may perform:

```text
geometry
   ↓
field
   ↓
neural inference
   ↓
agent decision
   ↓
dynamics
```

The boundaries between domains are therefore compositional rather than absolute architectural walls.

---

# 18. Morphology

Morphology shall be treated as a first-class computational concern.

It must not be reduced to:

* mesh generation;
* rendering;
* geometry serialization.

Morphology concerns computational form, structure, organization, arrangement, and structural transformation.

The intended relationship is bidirectional:

```text
Pattern
   ↕
Morphology
   ↕
Geometry
   ↕
Topology
```

Morphology may derive from:

* patterns;
* fields;
* constraints;
* topology;
* geometry;
* dynamics;
* semantic relationships.

It may produce multiple representations:

* meshes;
* voxel structures;
* implicit surfaces;
* point clouds;
* particle structures;
* collision representations;
* render representations.

The project shall investigate morphology as a possible bridge between abstract information and concrete spatial form.

---

# 19. Graphs and Hypergraphs

SCR shall support graph-based semantic computation and investigate hypergraph representations where relationships involve more than two participants.

The semantic graph may include:

* entities;
* relationships;
* roles;
* operations;
* regions;
* references;
* events;
* state;
* provenance;
* temporal information;
* causal information.

Identity must be distinguished across levels, potentially including:

```text
Semantic Identity
Graph-Region Identity
Content Identity
Operation Identity
```

Storage and transport mechanisms remain implementation concerns.

The semantic graph must not be reduced to a particular graph database, file format, or messaging protocol.

---

# 20. Streams and Messaging

Communication is a computational concern.

SCR shall therefore treat stream processing and messaging as first-class semantic and execution concerns where appropriate.

The project shall standardize around an AMQP-oriented messaging model where applicable while keeping semantic messaging concepts independent from any particular broker.

Potential semantic concerns include:

* exchange;
* queue;
* routing;
* publication;
* subscription;
* delivery;
* acknowledgement;
* ordering;
* durability;
* backpressure;
* stream transformation.

Transport implementation must remain replaceable beneath the semantic model.

---

# 21. Rendering and Observation

Rendering shall be treated as a computational domain and observation mechanism rather than merely a final output API.

A possible computational path is:

```text
Simulation
    ↓
Field
    ↓
Morphology
    ↓
Render
    ↓
Stream
```

A renderer may therefore be one observer of computation rather than the definition of the computation.

A reference implementation may eventually use:

```text
Rust Semantic Runtime
        ↓
Render State
        ↓
Render Commands
        ↓
Rust Renderer API
        ↓
C++ Adapter
        ↓
VulkanSceneGraph
        ↓
Vulkan
        ↓
GPU
```

This is an implementation path.

It must never become the semantic definition of rendering.

---

# 22. Hardware Independence Without Hardware Ignorance

SCR shall maintain a strict distinction between:

```text
Semantic Independence
```

and:

```text
Hardware Ignorance
```

Applications should not have to define their semantics in terms of specific hardware.

The compiler and runtime should nevertheless be able to exploit:

* CPU topology;
* SIMD;
* GPU capabilities;
* accelerators;
* memory hierarchy;
* locality;
* parallelism;
* bandwidth;
* distributed resources;
* specialized execution units.

The goal is therefore:

> **Hardware-independent semantics with hardware-aware realization.**

---

# 23. Documentation as a First-Class Engineering Layer

SCR shall maintain a public documentation architecture that mirrors the project's semantic principles.

The public documentation shall distinguish:

```text
Orientation
Concepts
Architecture
Domains
Mental Models
Examples
Guides
Comparisons
Research
Status
```

It shall maintain an explicit documentation graph linking:

```text
Concept
   ↕
Normative Definition
   ↕
Library Component
   ↕
Implementation
   ↕
Test
   ↕
Example
```

The documentation must never imply implementation merely because a concept has been documented.

Documentation status and architectural status shall remain separate.

---

# 24. Repository Traceability

The project shall progressively establish bidirectional traceability.

From documentation:

```text
Public Concept
    ↓
Normative Definition
    ↓
Library Domain
    ↓
Implementation
    ↓
Test
```

From implementation:

```text
Library Component
    ↓
Semantic Concept
    ↓
Normative Contract
    ↓
Public Documentation
```

Stable semantic identifiers should be preferred over fragile source-line references.

This will allow the project to eventually validate documentation coverage automatically.

---

# 25. Engineering Principles

All implementation work shall follow these principles.

### 25.1 Semantic Primacy

Semantics are normative.

### 25.2 Implementation Independence

Semantic definitions must not depend on a particular implementation language, library, operating system, or hardware target.

### 25.3 Explicit Relationships

Architectural relationships must be represented explicitly.

### 25.4 Progressive Abstraction

Preserve semantic information for as long as practical.

### 25.5 Provider Independence

Providers realize contracts; they do not redefine them.

### 25.6 Evidence Over Assertion

Implementation claims must be supported by implementation and/or test evidence.

### 25.7 Vertical Slices Over Empty Breadth

The project should prefer executable end-to-end semantic paths over large numbers of empty abstractions.

### 25.8 Explicit Uncertainty

Research and proposals must remain visibly distinct from established behavior.

### 25.9 Replaceable Mechanisms

Libraries, storage mechanisms, transport mechanisms, renderers, providers, and execution substrates should remain replaceable where semantic contracts permit.

### 25.10 No Architectural Theater

A directory, interface, diagram, placeholder, or specification does not constitute an implemented capability.

---

# 26. Development Strategy

SCR shall progress through demonstrable vertical slices.

The preferred development path is:

```text
Semantic Definition
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
Execution
        ↓
Observation
```

Each vertical slice should demonstrate progressively more of the central proposition.

A successful slice should establish not merely that code executes, but that:

1. the semantic meaning is explicit;
2. the representation is distinguishable from the meaning;
3. the implementation realizes the semantic contract;
4. the execution substrate can be identified;
5. the result can be observed;
6. the relationship between all layers is traceable.

---

# 27. Golden Path

The project's primary integration target shall be a minimal end-to-end semantic computation.

The intended Golden Path is:

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
Observable Result
```

This path is intentionally small.

Its purpose is to validate the architecture, not to maximize feature count.

Once established, alternate providers and execution substrates can be introduced without changing the semantic foundation.

---

# 28. Definition of Success

SCR succeeds if it can demonstrate, through executable and independently inspectable evidence, that:

### A. Meaning can be represented explicitly

A computational operation can be defined independently of its final implementation.

### B. Meaning survives representation changes

Semantic identity can be maintained through domain IR, MLIR, lowering, and execution.

### C. Implementations can be substituted

At least some alternative implementations can be demonstrated to satisfy the same semantic contract.

### D. Domains can compose

At least several distinct semantic domains can participate in a common computational graph.

### E. Providers can be separated

A semantic operation can be realized by an implementation provider without making the provider the semantic authority.

### F. Hardware can be exploited without becoming semantic

The same semantic computation can be specialized for different execution substrates.

### G. Observation can remain separate from computation

A computation can be executed, observed, rendered, recorded, or analyzed without making any one observation the semantic definition.

### H. The architecture remains extensible

New domains can be added without redesigning the semantic foundation.

---

# 29. Non-Goals

SCR is not mandated to:

* replace every existing framework;
* replace MLIR;
* provide every computational domain;
* implement every proposed provider;
* create a universal database;
* create a universal message broker;
* become a general-purpose operating system;
* solve semantic equivalence completely before implementation begins;
* force all computations into one representation;
* eliminate specialized libraries;
* eliminate domain-specific algorithms;
* make hardware-specific optimization impossible.

The project is instead concerned with establishing the semantic architecture that allows these mechanisms to coexist without making them the definition of computation.

---

# 30. Research Mandate

SCR is both an engineering project and an architectural research programme.

The project shall explicitly investigate:

* semantic equivalence;
* semantic contracts;
* semantic compilation;
* provider substitution;
* computational morphology;
* information fields;
* semantic graphs and hypergraphs;
* adaptive execution;
* semantic capabilities;
* representation independence;
* hardware specialization;
* cross-domain composition;
* observation semantics;
* temporal and causal semantics;
* computational identity;
* provenance.

Research results must distinguish:

```text
Established
Implemented
Experimental
Specified
Proposed
Research
Illustrative
```

A research hypothesis must not become an architectural fact merely because it appears in documentation.

---

# 31. Governance of Architectural Meaning

The project shall maintain a strict distinction between:

```text
Normative Meaning
```

and:

```text
Engineering State
```

The normative semantic definition establishes what a domain means.

The status record establishes what currently exists.

The implementation provides concrete realization.

The public documentation explains the system.

The semantic graph describes relationships.

Therefore:

```text
Definition
    = normative

Status
    = descriptive

Implementation
    = executable evidence

Graph
    = derived relationship model

Public Documentation
    = explanatory projection
```

No one of these artifacts should silently assume the authority of another.

---

# 32. Long-Term Vision

The long-term vision is a **Common Language Runtime for Computational Semantics**.

The intended progression is:

```text
Application Meaning
        ↓
Semantic Model
        ↓
Domain Composition
        ↓
Semantic Analysis
        ↓
Semantic Transformation
        ↓
Provider Selection
        ↓
Specialization
        ↓
Execution
        ↓
Observation
        ↓
Feedback
        ↺
```

The runtime should eventually be capable of determining not merely how to execute instructions, but how to realize **semantic computations**.

The resulting environment could span:

* scientific computing;
* simulation;
* physics;
* spatial computing;
* geometry;
* morphology;
* AI;
* neural computation;
* perception;
* control;
* optimization;
* distributed systems;
* stream processing;
* messaging;
* rendering;
* computational media.

The unifying abstraction is not the application domain.

It is **computational meaning**.

---

# 33. Ultimate Project Thesis

SCR ultimately investigates one proposition:

> **If computational meaning can be made explicit, formally represented, composed, transformed, verified, and preserved through compilation, then the implementation of computation can become substantially more replaceable than it is in conventional software architectures.**

The project therefore seeks to move the fundamental boundary of software architecture:

```text
Traditional:

Application
    ↓
Implementation

SCR:

Application
    ↓
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

The purpose of this additional semantic layer is not abstraction for its own sake.

It is to make **meaning itself a computational object**.

---

# 34. Mandate in One Sentence

> **Build an MLIR-based computational runtime in which semantic meaning is a first-class, composable, inspectable, and transformable computational object, allowing heterogeneous implementations and execution substrates to realize that meaning without becoming its definition.**

---

# 35. Final Principle

SCR should continuously ask:

> **What does this computation mean?**

before asking:

> **How should we implement it?**

and:

> **Where should it execute?**

The project is successful when those questions can remain distinct while still forming one executable computational system.
