# Semantic Computational Runtime

# Architecture

**Document:** `004_ARCHITECTURE.md`
**Version:** 1.0.0
**Status:** Foundational
**Authority:** Architectural
**Date:** 2026-09-06

---

# 1. Purpose

This document defines the architecture of the **Semantic Computational Runtime (SCR)**.

It establishes the structural relationship between:

* semantic meaning;
* semantic models;
* MLIR;
* SCR dialects;
* interfaces and capabilities;
* analysis;
* transformation;
* lowering;
* representations;
* providers;
* runtime execution;
* hardware;
* observation.

This document exists to eliminate architectural ambiguity and to provide a stable reference for implementation agents and human contributors.

The architecture defined here is normative unless superseded by an explicitly versioned architectural decision.

---

# 2. Architectural Proposition

SCR is an **MLIR-based semantic computational environment**.

Its fundamental proposition is:

> **Applications should be expressed in terms of computational meaning rather than implementation technology.**

SCR provides the semantic architecture necessary to make computational meaning formally representable, composable, analyzable, transformable, and executable.

MLIR provides the compiler and intermediate-representation infrastructure through which those semantics become computationally actionable.

SCR therefore sits **on top of and within the MLIR ecosystem**, not beside it as a competing compiler infrastructure.

The architectural relationship is:

```text
Semantic Architecture
        +
MLIR Infrastructure
        =
Semantic Computational Runtime
```

SCR contributes semantic meaning.

MLIR provides the representation and compiler substrate.

Providers provide concrete implementations.

The runtime coordinates execution.

---

# 3. The Fundamental Representation Rule

## 3.1 There Is No Separate SCR IR

SCR does **not** define:

* a Domain IR;
* a Semantic IR;
* an SCR IR;
* a proprietary compiler IR;
* a second SSA representation;
* a parallel type system;
* a parallel operation graph;
* a custom compiler representation that is subsequently translated into MLIR.

The following architecture is explicitly prohibited:

```text
Application
    ↓
Semantic Model
    ↓
Domain IR
    ↓
MLIR
    ↓
Lowering
```

The following is also prohibited:

```text
Application
    ↓
Semantic Model
    ↓
Semantic IR
    ↓
MLIR
```

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
```

---

# 4. Semantic Model vs Semantic MLIR

This distinction is fundamental.

## 4.1 Semantic Model

The **Semantic Model** describes what a computation means.

It defines concepts such as:

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

The Semantic Model defines:

* ontology;
* vocabulary;
* meaning;
* contracts;
* invariants;
* relationships;
* capabilities;
* constraints;
* composition;
* transformations;
* domain semantics;
* provider semantics.

The Semantic Model is a **conceptual and normative specification**.

It is not a compiler IR.

---

## 4.2 Semantic MLIR

**Semantic MLIR** is MLIR containing SCR semantics.

It consists of ordinary MLIR mechanisms extended with SCR semantic constructs where required:

```text
MLIR
├── SCR Dialects
├── SCR Types
├── SCR Operations
├── SCR Attributes
├── SCR Interfaces
├── SCR Traits
├── SCR Verification
├── SCR Analyses
├── SCR Transformations
└── SCR Lowering
```

Therefore:

```text
Semantic Model
    =
meaning
```

while:

```text
Semantic MLIR
    =
MLIR representation of that meaning
```

Semantic MLIR is **not another IR**.

The term exists to distinguish MLIR carrying SCR semantics from lower-level or progressively lowered MLIR.

---

# 5. Canonical Architecture

The complete SCR architecture is:

```text
┌───────────────────────────────────────────────────────────┐
│                       APPLICATION                          │
│                                                           │
│ Domain intent / semantic program / user computation       │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────┐
│                     SEMANTIC MODEL                        │
│                                                           │
│ Meaning                                                   │
│ Ontology                                                  │
│ Contracts                                                 │
│ Invariants                                                │
│ Capabilities                                              │
│ Constraints                                               │
│ Composition                                               │
│ Domain semantics                                          │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────┐
│                    SCR SEMANTIC MLIR                      │
│                                                           │
│ MLIR + SCR dialects + types + operations + attributes     │
│ + interfaces + traits + semantic verification            │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────┐
│                    MLIR INFRASTRUCTURE                    │
│                                                           │
│ Verification                                               │
│ Analysis                                                   │
│ Canonicalization                                           │
│ Pattern Rewriting                                          │
│ Transformation                                             │
│ Dialect Conversion                                         │
│ Bufferization                                              │
│ Tiling                                                     │
│ Vectorization                                              │
│ Parallelization                                            │
│ Async                                                       │
│ GPU                                                         │
│ Lowering                                                    │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────┐
│                         LOWERING                           │
│                                                           │
│ Progressive refinement toward concrete execution          │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────┐
│                        PROVIDER                            │
│                                                           │
│ Concrete implementation satisfying semantic contracts    │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────┐
│                         RUNTIME                            │
│                                                           │
│ Scheduling / resources / lifecycle / execution            │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────┐
│                    EXECUTION SUBSTRATE                    │
│                                                           │
│ CPU / GPU / accelerator / distributed infrastructure     │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
                         OBSERVATION
```

There is intentionally **no independent IR between Semantic Model and MLIR**.

---

# 6. Architectural Boundaries

SCR maintains explicit boundaries between:

```text
Meaning
    ≠
Representation
    ≠
Transformation
    ≠
Lowering
    ≠
Provider
    ≠
Runtime
    ≠
Hardware
```

These boundaries are related but not interchangeable.

---

# 7. Meaning

Meaning answers:

> What does this computation represent?

Meaning includes:

* semantic identity;
* properties;
* relationships;
* state;
* behavior;
* constraints;
* capabilities;
* effects;
* temporal meaning;
* spatial meaning;
* topology;
* morphology;
* information;
* domain semantics.

Meaning is defined by SCR's semantic architecture.

Implementation details must not redefine semantic meaning accidentally.

---

# 8. Representation

Representation answers:

> How is semantic information encoded?

Representations may include:

* Semantic MLIR;
* MLIR tensors;
* MLIR memrefs;
* sparse structures;
* dense structures;
* graphs;
* meshes;
* voxels;
* fields;
* particles;
* implicit surfaces;
* parametric forms;
* buffers;
* provider-specific structures;
* render resources.

Representation is subordinate to semantic meaning.

A semantic object may have multiple valid representations.

---

# 9. Representation Independence

SCR must preserve semantic meaning across valid representation changes.

For example:

```text
Morphological Structure
        │
        ├── Mesh
        ├── Voxel
        ├── Implicit Surface
        ├── Particle Representation
        ├── Parametric Representation
        └── Field Representation
```

These are different representations of semantic content.

They are not different meanings.

Representation selection may be determined by:

* consumer requirements;
* capabilities;
* topology;
* geometry;
* locality;
* numerical requirements;
* hardware;
* memory;
* performance;
* provider availability;
* rendering requirements.

---

# 10. Transformation

Transformation answers:

> How can the represented computation be changed while preserving or explicitly changing its semantics?

Examples include:

* canonicalization;
* composition;
* decomposition;
* fusion;
* tiling;
* vectorization;
* parallelization;
* distribution;
* differentiation;
* specialization;
* representation change;
* scheduling;
* memory transformation.

Transformations operate on Semantic MLIR and/or its associated semantic structures.

Transformations must obey SCR's semantic invariants.

---

# 11. Lowering

Lowering answers:

> How can a semantic computation be progressively transformed into a form suitable for concrete execution?

Lowering may move from higher-level SCR dialects toward:

```text
SCR dialects
    ↓
standard MLIR dialects
    ↓
hardware-oriented MLIR dialects
    ↓
LLVM / GPU / SPIR-V / external ABI
    ↓
machine execution
```

Lowering is not inherently a change of meaning.

It is a representation and execution refinement.

Any semantic change introduced by lowering must be explicit and governed by an appropriate contract.

---

# 12. Provider

A provider is a concrete implementation of a semantic contract.

Providers may use:

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

or other technologies.

Providers are implementation resources.

They are not semantic authorities.

The semantic layer must not become dependent on the API model of a particular provider.

---

# 13. Runtime

The runtime coordinates execution of compiled semantic programs.

Runtime responsibilities may include:

* provider selection;
* resource management;
* scheduling;
* execution lifecycle;
* state management;
* memory management;
* device management;
* synchronization;
* messaging;
* telemetry;
* observability;
* adaptation;
* failure handling;
* checkpointing;
* distributed execution.

The runtime does not redefine semantic meaning.

---

# 14. Hardware

Hardware is treated as an execution capability/resource domain.

SCR may reason about:

* CPU;
* GPU;
* accelerators;
* vector width;
* cache;
* NUMA;
* memory bandwidth;
* occupancy;
* latency;
* throughput;
* interconnect;
* power;
* thermal constraints;
* memory pressure.

Hardware awareness does not require a hardware-specific semantic IR.

Hardware specialization should occur through MLIR analysis, transformation, lowering, provider selection, and runtime scheduling.

---

# 15. SCR Dialects

SCR may define MLIR dialects where domain-specific semantics require them.

Examples include conceptual domains such as:

```text
Core
Math
Data
Field
Graph
Geometry
Topology
Spatial
Morphology
Physics
Dynamics
Simulation
Agent
Neural
Learning
Optimization
Control
Perception
Render
Stream
```

A semantic domain does **not** automatically require a distinct dialect.

Dialect boundaries must be justified by semantic or representational requirements.

The correct relationship is:

```text
Semantic Domain
       ↓
Semantic Boundary
       ↓
Representation Requirements
       ↓
MLIR Dialect where justified
```

not:

```text
Filesystem Directory
       ↓
Domain IR
       ↓
MLIR Dialect
```

---

# 16. SCR Interfaces

Interfaces express capabilities and semantic contracts shared across domains.

Examples include:

```text
Composable
Transformable
Stateful
Stateless
Spatial
Temporal
Spatiotemporal
CoordinateAware
Dynamical
Integrable
Differentiable
Evolvable
Parallelizable
Vectorizable
Tileable
Reducible
Distributable
Streamable
Renderable
Projectable
Observable
Learnable
Optimizable
Trainable
Controllable
Feedback
Deterministic
Stochastic
Seedable
Serializable
Persistable
Morphological
Representable
Deformable
```

Where these concepts correspond to MLIR interfaces or traits, SCR should use the MLIR mechanism rather than creating a parallel abstraction system.

---

# 17. Interfaces Before Specialization

Shared semantic capabilities should be defined independently of individual domain implementations.

For example:

```text
Dynamics
Agent
Control
Simulation
Physics
```

may share:

```text
Stateful
Temporal
Dynamical
Observable
Controllable
```

These relationships should be expressed through common semantic interfaces where appropriate.

The objective is a composable semantic ecosystem rather than isolated domain silos.

---

# 18. Semantic Composition

Composition is fundamental to SCR.

Semantic operations may compose:

```text
field.sample
      ↓
interaction
      ↓
dynamics.integrate
      ↓
state.transition
```

into:

```text
agent.propagate
```

which may participate in:

```text
population.evolve
```

This is semantic composition represented through MLIR.

SCR must support:

* operation composition;
* higher-order composition;
* semantic equivalence;
* refinement;
* specialization;
* decomposition;
* fusion;
* substitution.

---

# 19. Higher-Order Semantics

Higher-order operations are first-class.

A semantic operation may itself operate on:

* operations;
* processes;
* fields;
* transformations;
* models;
* programs;
* agents;
* populations;
* representations.

Higher-order composition must remain within the MLIR semantic representation architecture.

It must not require a second composition IR.

---

# 20. Semantic Equivalence

Two representations or implementations may be considered semantically equivalent where they satisfy the same declared semantic contract and observable behavior.

Conceptually:

```text
Semantic Program A
        ≡
Semantic Program B
```

may permit:

```text
Provider A
        ↔
Provider B
```

provided the required semantic contract is preserved.

Equivalence must be defined semantically rather than by implementation identity.

---

# 21. Semantic Refinement

SCR supports progressive refinement:

```text
Abstract Meaning
      ↓
Semantic Contract
      ↓
Semantic MLIR
      ↓
More Concrete MLIR
      ↓
Provider Representation
      ↓
Execution
```

Refinement may add:

* representation detail;
* numerical detail;
* scheduling detail;
* hardware detail;
* memory detail;
* communication detail;
* provider detail.

Refinement must not silently change the semantic contract.

---

# 22. Semantic Abstraction Levels

SCR may organize semantics into progressive levels:

```text
L0 — Mathematical primitives
L1 — Computational primitives
L2 — Structural semantics
L3 — Domain capabilities
L4 — Composite domain models
L5 — System semantics
```

These are **semantic abstraction levels**.

They are not separate IRs.

All appropriate levels may be represented within MLIR.

---

# 23. Information as a Computational Substrate

SCR treats information itself as computationally meaningful.

Relevant structures include:

* fields;
* graphs;
* hypergraphs;
* patterns;
* morphology;
* geometry;
* topology;
* streams;
* semantic state;
* events;
* relationships;
* spatial structures.

These structures may participate directly in computation.

They do not imply separate representations.

---

# 24. Semantic Graph

The Computational Semantic Graph represents relationships among:

* entities;
* properties;
* operations;
* constraints;
* types;
* capabilities;
* state;
* events;
* dataflow;
* control flow;
* spatial relationships;
* temporal relationships;
* execution requirements.

The semantic graph is a conceptual semantic structure.

It is not a second compiler IR.

Where executable graph semantics are required, they should be represented using MLIR constructs.

---

# 25. Library Architecture Graph

SCR also maintains a Library Architecture Graph.

This graph describes relationships among:

* domains;
* definitions;
* implementations;
* interfaces;
* tests;
* providers;
* documentation;
* dependencies.

It is **control-plane metadata**.

It is not:

* the canonical execution representation;
* a compiler IR;
* a Domain IR;
* a Semantic IR.

---

# 26. Morphology

Morphology is a first-class semantic domain.

SCR treats morphology as the study and representation of structure, form, shape, organization, transformation, and emergence.

The relationship is bidirectional:

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

Morphology therefore connects:

```text
Information
    ↕
Pattern
    ↕
Field
    ↕
Graph
    ↕
Topology
    ↕
Geometry
    ↕
Morphology
    ↕
Dynamics
    ↕
Rendering
```

Morphology must remain representation-independent.

It is not equivalent to mesh generation.

---

# 27. Rendering

Rendering is a first-class computational domain.

A conceptual execution path is:

```text
SCR Semantic MLIR
      ↓
Render Semantics
      ↓
MLIR Transformation / Lowering
      ↓
Render Provider
      ↓
Renderer API
      ↓
VulkanSceneGraph
      ↓
Vulkan
      ↓
GPU
```

A render representation is not a separate SCR Render IR.

---

# 28. Stream Processing

Stream processing is a first-class semantic domain.

Core concepts include:

```text
Source
Sink
Channel
Message
Event
Signal
Flow
Pipeline
Operator
Transform
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
Scheduling
Temporal State
```

Stream semantics may be represented using SCR MLIR constructs and appropriate MLIR mechanisms.

---

# 29. Messaging

Messaging is a first-class semantic domain.

SCR adopts an AMQP-oriented semantic model while remaining conceptually independent of any specific broker.

Relevant semantics include:

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

Broker implementations remain providers.

AMQP semantics do not require a separate messaging IR.

---

# 30. Simulation

Simulation is an important reference workload but is not the architectural boundary of SCR.

Simulation composes many semantic domains:

```text
Fields
Graphs
Geometry
Topology
Morphology
Physics
Dynamics
Agents
Control
Perception
Neural Computation
Optimization
Learning
Rendering
Streams
Messaging
```

The v0.0.1 particle simulation is therefore a **vertical architectural proof**.

It demonstrates that the semantic architecture can travel through:

```text
Semantic Model
    ↓
Semantic MLIR
    ↓
MLIR
    ↓
Provider
    ↓
Execution
    ↓
Observation
```

It does not define SCR's ultimate scope.

---

# 31. Golden Path

The initial Golden Path is:

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
MLIR Verification
  ↓
MLIR Analysis
  ↓
MLIR Transformation
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
VulkanSceneGraph / Vulkan
  ↓
Visible Result
```

The Golden Path exists to prove the architecture vertically.

It must not introduce a custom intermediate representation.

---

# 32. Provider Selection

Provider selection is driven by semantic requirements and execution capabilities.

Conceptually:

```text
Semantic Requirements
        +
Capability Requirements
        +
Resource Constraints
        +
Hardware Characteristics
        +
Provider Capabilities
        ↓
Provider Selection
```

The application should not need to know which concrete provider is selected where semantic contracts permit substitution.

---

# 33. Adaptive Execution

SCR may dynamically optimize execution through:

```text
Capability Analysis
        ↓
Resource Analysis
        ↓
Hardware Analysis
        ↓
Provider Selection
        ↓
Scheduling
        ↓
Compilation / Specialization
        ↓
Execution
        ↓
Telemetry
        ↓
Re-analysis
```

This feedback loop is a runtime/compiler concern.

It does not require a second IR.

---

# 34. Hardware-Aware Compilation

SCR should exploit available hardware intelligently.

The objective is not blindly maximizing utilization.

The objective is maximizing:

> **useful semantic computation subject to correctness, resource, latency, throughput, determinism, numerical, and operational constraints.**

The compiler/runtime may consider:

```text
Vectorization
Tiling
Parallelization
GPU Offload
Memory Locality
NUMA
Data Movement
Kernel Fusion
Scheduling
Device Placement
Communication
Latency
Throughput
Power
Thermal Constraints
```

These optimizations operate within the MLIR/SCR architecture.

---

# 35. Semantic Contracts

Every meaningful SCR computational abstraction should have an explicit semantic contract.

A contract may specify:

* inputs;
* outputs;
* types;
* units;
* dimensions;
* invariants;
* preconditions;
* postconditions;
* state requirements;
* effects;
* capabilities;
* determinism;
* stochasticity;
* numerical guarantees;
* temporal behavior;
* spatial behavior;
* resource requirements;
* failure semantics;
* observational behavior.

Providers implement contracts.

Contracts are not provider APIs.

---

# 36. Semantic Invariants

SCR architecture is governed by its semantic invariants.

The fundamental invariant is:

> Any valid change in representation, implementation, provider, optimization, compilation strategy, or execution resource must preserve the semantic contract unless explicitly defined as a semantic transformation under a declared contract.

Important architectural invariants include:

```text
Semantic Primacy
Meaning Independence
Identity Preservation
Type Meaning Preservation
Dimensional Consistency
Constraint Preservation
Contract Preservation
Information Semantics
Relationship Integrity
State Integrity
Context Integrity
Spatial Integrity
Temporal Integrity
Topological Integrity
Morphological Integrity
Compositionality
Composition Closure
Higher-Order Closure
Capability Compatibility
Representation Independence
Representation Substitutability
Provider Independence
Provider Substitutability
Hardware Independence
Execution Strategy Independence
Observable Equivalence
Determinism Preservation
Stochastic Semantics
Failure Semantics
Observability
Explicit Side Effects
Provenance Preservation
Uncertainty Preservation
Precision Awareness
Semantic Locality
Domain Integrity
Interface Stability
No Duplicate Semantics
Semantic Generalization
Semantic Specialization
No Implementation Leakage
MLIR Consistency
Single Semantic Representation
Lowering Is Not Meaning Change
Information Preservation Until Necessary
Compilation Must Be Semantics-Preserving
Provider Claims Must Be Verifiable
Semantic Errors Are First-Class
Error Preservation
Consumer-Driven Representation
Semantic Single Source of Truth
```

The complete invariant set is maintained in the authoritative semantic invariants documentation.

---

# 37. Single Semantic Representation

The phrase **Single Semantic Representation** has a precise meaning.

It means:

> SCR must not maintain competing canonical computational representations of the same semantic program.

The canonical compiler representation is MLIR.

SCR may have:

* semantic specifications;
* metadata;
* runtime state;
* analysis results;
* concrete provider representations;
* materialized data;
* external representations.

These do not constitute competing compiler IRs.

---

# 38. No Shadow IR

The following are prohibited as canonical SCR compiler representations:

```text
Custom SSA IR
Custom Operation Graph
Custom Type IR
Custom Semantic IR
Custom Domain IR
Custom Execution IR
Custom Graph IR
Custom Stream IR
Custom Render IR
Custom Physics IR
Custom Simulation IR
```

A Rust object model may exist for API or runtime purposes.

It becomes architecturally problematic when it becomes:

```text
Rust Semantic Model
        ↓
Rust IR
        ↓
MLIR
```

That architecture is prohibited.

---

# 39. Rust and Host-Language Structures

Rust structures may be used for:

* configuration;
* handles;
* ownership;
* lifecycle;
* API builders;
* diagnostics;
* analysis results;
* runtime state;
* provider configuration;
* transient objects;
* interoperability;
* resource management.

They must not silently become the canonical compiler representation.

Where MLIR already represents a concept, SCR should prefer MLIR-backed representations or explicit handles/views rather than duplicate compiler state.

---

# 40. JSON and YAML

Structured files may represent:

* configuration;
* semantic definitions;
* status;
* metadata;
* control-plane relationships;
* generated documentation.

They must not become the canonical executable representation of SCR programs.

In particular:

```text
101_definition.md
```

is normative semantic documentation.

```text
102_status.yaml
```

is engineering state.

```text
103_library.graph.json
```

is derived library/control-plane graph information.

None is an SCR execution IR.

---

# 41. MLIR-First Extension Rule

Whenever SCR requires new compiler functionality, use the following decision order:

```text
1. Can existing MLIR represent it?
        ↓
2. Can an existing MLIR dialect represent it?
        ↓
3. Can an MLIR type represent it?
        ↓
4. Can an MLIR attribute represent it?
        ↓
5. Can an MLIR interface or trait represent it?
        ↓
6. Can an MLIR analysis represent it?
        ↓
7. Can an MLIR transformation/pass represent it?
        ↓
8. Can MLIR dialect conversion/lowering represent it?
        ↓
9. If genuinely semantic and missing:
       create/extend an SCR MLIR dialect or interface
```

The creation of a new independent IR is **not part of this sequence**.

---

# 42. New Dialect Rule

A new SCR dialect should be introduced only when there is a coherent semantic domain or representation boundary that justifies it.

A new dialect must:

* be an MLIR dialect;
* define explicit semantics;
* define its operations/types/attributes as appropriate;
* define verification requirements;
* define interfaces/capabilities;
* define relationships to other dialects;
* define legal transformations;
* define lowering paths where applicable;
* avoid duplicating existing MLIR semantics.

---

# 43. Domain Independence

Semantic domains should remain independently understandable and implementable where possible.

Dependency direction should generally follow:

```text
Core
 ↓
Foundational Semantics
 ↓
Structural Domains
 ↓
Domain Capabilities
 ↓
Composite Domains
 ↓
System Semantics
 ↓
Providers / Execution
```

Higher domains may compose lower semantics.

Lower domains must not depend unnecessarily on implementation details of higher domains.

---

# 44. Cross-Domain Composition

SCR is intentionally designed to permit composition across domains.

Examples include:

```text
Field
  +
Dynamics
```

```text
Geometry
  +
Topology
  +
Morphology
```

```text
Agent
  +
Perception
  +
Neural
  +
Learning
  +
Control
```

```text
Simulation
  +
Physics
  +
Dynamics
  +
Rendering
  +
Streaming
```

Cross-domain composition must be mediated by semantic contracts and interfaces rather than provider-specific APIs.

---

# 45. Semantic Generalization

SCR should identify semantic structures common across apparently unrelated domains.

Examples include:

```text
Identity
State
Property
Relationship
Transformation
Observation
Composition
```

and:

```text
State
   ↓
Transition
   ↓
State
```

These recurring structures should become reusable semantic abstractions where justified.

The purpose is not to force unrelated domains into a single abstraction.

The purpose is to expose genuine common semantics.

---

# 46. Semantic Specialization

A general semantic operation may be specialized when additional domain knowledge is available.

For example:

```text
General State Transition
        ↓
Dynamical Transition
        ↓
Physical Evolution
        ↓
Rigid Body Integration
```

Specialization must preserve the general semantic contract unless the specialization explicitly refines or changes it under a declared transformation.

---

# 47. Compiler Architecture

The SCR compiler architecture is fundamentally an MLIR architecture.

Conceptually:

```text
Semantic Model
      ↓
SCR Semantic MLIR
      ↓
Verification
      ↓
Analysis
      ↓
Canonicalization
      ↓
Optimization
      ↓
Specialization
      ↓
Representation Transformation
      ↓
Lowering
      ↓
Provider Integration
```

SCR should reuse MLIR infrastructure wherever possible.

SCR is not intended to become a competing general-purpose compiler framework.

---

# 48. Runtime Architecture

The runtime operates after and alongside compilation.

Conceptually:

```text
Compiled Semantic Program
        ↓
Execution Plan
        ↓
Resource / Provider Selection
        ↓
Scheduling
        ↓
Execution
        ↓
Observation / Telemetry
        ↓
Adaptation
```

The runtime may maintain state that is not compiler IR.

Runtime state must nevertheless remain semantically accountable.

---

# 49. Execution Independence

A semantic program should, where its contracts permit, benefit from:

* different algorithms;
* different representations;
* different providers;
* different hardware;
* different execution strategies;
* different memory layouts;
* different parallelization strategies;
* different scheduling strategies.

without requiring application-level semantic rewrites.

This is a central SCR objective.

---

# 50. Observability

Execution should expose sufficient information to determine whether semantic contracts remain satisfied.

Observability may include:

* execution telemetry;
* timing;
* resource consumption;
* numerical diagnostics;
* state transitions;
* failures;
* provenance;
* provider identity;
* hardware information;
* transformation provenance;
* approximation information.

Observability must not alter semantics unless explicitly defined as an effect.

---

# 51. Failure Semantics

Failures are semantic events where they affect observable computational behavior.

SCR should distinguish:

```text
Semantic Error
Compilation Error
Transformation Error
Lowering Error
Provider Error
Resource Error
Runtime Error
Hardware Error
```

Errors must not be silently converted into successful computation.

Where error substitution is allowed, it must be contractually explicit.

---

# 52. Approximation

Approximation is permitted where explicitly represented and semantically declared.

For example:

```text
Exact
    ↓
Approximate
```

must not occur invisibly.

The approximation should expose appropriate:

* error bounds;
* uncertainty;
* precision;
* provenance;
* contract changes;
* validity domain.

---

# 53. Determinism and Stochasticity

Deterministic and stochastic semantics are distinct.

SCR must preserve declared stochastic semantics including:

* random sources;
* seeds;
* distributions;
* reproducibility;
* statistical guarantees.

A provider may use a different implementation strategy provided the declared stochastic contract remains satisfied.

---

# 54. Temporal and Spatial Semantics

Time and space are first-class semantic dimensions.

SCR must preserve where applicable:

```text
Temporal Ordering
Duration
Timescale
Causality
Spatial Position
Orientation
Distance
Direction
Reference Frames
Topology
Geometry
```

Representation and execution strategy must not silently alter these semantics.

---

# 55. Information Preservation

Information should be preserved for as long as practical during compilation and execution.

Lossy transformations must be explicit.

Examples include:

```text
Precision Reduction
Quantization
Sampling
Compression
Simplification
Decimation
Approximation
Projection
Aggregation
```

The semantic impact of information loss must be represented and verifiable.

---

# 56. Consumer-Driven Representation

Representation should be selected according to the requirements of the consuming computation.

Conceptually:

```text
Semantic Object
      ↓
Consumer Requirements
      +
Capabilities
      +
Constraints
      +
Hardware
      ↓
Representation Selection
```

This prevents the semantic model from being prematurely constrained by one implementation representation.

---

# 57. Provider Substitutability

Two providers may substitute for one another where they satisfy the same semantic contract.

For example:

```text
Provider A
     ≡
Provider B
```

does not require implementation identity.

It requires semantic compatibility.

Provider claims must be verifiable.

---

# 58. External Technologies

External technologies should be treated as implementation resources.

SCR may integrate with:

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

and other technologies.

The dependency direction is:

```text
SCR Semantics
      ↓
Provider Contract
      ↓
External Technology
```

not:

```text
External Technology
      ↓
SCR Semantics
```

---

# 59. Dependency Direction

Semantic dependencies should point toward abstractions.

Implementation dependencies should point toward providers.

A semantic domain must not acquire accidental dependence on:

* renderer-specific APIs;
* physics-library object models;
* GPU-specific memory models;
* database-specific schemas;
* broker-specific APIs;
* vendor-specific hardware;
* host-language implementation structures.

Such dependencies belong below semantic contracts.

---

# 60. Documentation Authority

SCR documentation has distinct roles.

## Normative semantic definitions

Define what SCR means.

## Architecture

Defines how SCR's semantic architecture relates to MLIR, transformations, providers, runtime, and execution.

## Project mandate

Defines why SCR exists and the architectural constraints governing development.

## Agent governance

Defines how implementation agents must work within those constraints.

## Status

Describes what is implemented.

## Library graph

Describes derived relationships.

These documents must not contradict the architecture defined here.

---

# 61. Terminology

The following terminology is normative.

| Term                       | Meaning                                                     |
| -------------------------- | ----------------------------------------------------------- |
| Semantic Model             | Conceptual specification of computational meaning           |
| Semantic MLIR              | MLIR representation of SCR semantics                        |
| SCR Dialect                | MLIR dialect defining SCR semantic constructs               |
| SCR Operation              | MLIR operation carrying SCR semantics                       |
| SCR Type                   | MLIR/SCR semantic type                                      |
| SCR Attribute              | MLIR/SCR semantic metadata                                  |
| SCR Interface              | MLIR interface expressing a semantic capability or contract |
| Semantic Graph             | Conceptual graph of semantic entities and relationships     |
| Representation             | Encoding or materialization of semantic information         |
| Transformation             | Change to representation/computation under semantic rules   |
| Lowering                   | Progressive refinement toward concrete execution            |
| Provider                   | Concrete implementation satisfying a semantic contract      |
| Runtime                    | Execution orchestration and resource management             |
| Execution Substrate        | Concrete hardware/software environment                      |
| Library Architecture Graph | Derived control-plane relationship graph                    |

The following are **not valid SCR architectural layers**:

```text
Domain IR
Semantic IR
SCR IR
```

If these terms appear in historical or comparative material, they must be explicitly identified as external or historical concepts.

---

# 62. Directory Structure Is Not Architecture

The filesystem organization of SCR is not itself the semantic architecture.

For example:

```text
lib/401_Morphology
```

does not imply:

```text
Morphology IR
```

Likewise:

```text
lib/502_Dynamics
```

does not imply:

```text
Dynamics IR
```

Directories organize semantic knowledge and implementation artifacts.

Architectural meaning is defined by semantic contracts, MLIR dialects/interfaces, and documented boundaries.

---

# 63. Architecture and Implementation

The architecture intentionally separates:

```text
What
```

from:

```text
How
```

and:

```text
Where
```

A developer should be able to express:

```text
what computation means
```

without necessarily deciding:

```text
which algorithm
which library
which provider
which hardware
which memory layout
which scheduling strategy
which execution device
```

where semantic contracts permit that independence.

---

# 64. Architectural Anti-Patterns

The following are architectural anti-patterns:

### 64.1 Shadow IR

Creating a second compiler representation and translating it into MLIR.

### 64.2 Provider Leakage

Allowing provider APIs to define semantic concepts.

### 64.3 Domain Silos

Duplicating shared semantics independently across domains.

### 64.4 Representation Leakage

Allowing a concrete representation to become semantic meaning.

### 64.5 Hardware Leakage

Making semantic definitions depend on a particular hardware target.

### 64.6 Accidental State

Maintaining semantic state outside explicitly defined state mechanisms.

### 64.7 Duplicate Semantics

Defining the same semantic concept independently in multiple locations.

### 64.8 Directory-Driven Architecture

Assuming filesystem organization automatically determines semantic or dialect boundaries.

### 64.9 Implementation-First Semantics

Defining semantic abstractions from the API of an existing external library.

### 64.10 Premature Specialization

Choosing a concrete representation before the semantic requirements are understood.

---

# 65. MLIR Before Reinvention

Before implementing a new compiler abstraction, ask:

```text
Does MLIR already provide this?
```

Then:

```text
Does an existing MLIR dialect provide this?
```

Then:

```text
Can an MLIR type, attribute, interface, trait, operation,
analysis, transformation, or lowering provide this?
```

Only after exhausting these mechanisms should SCR extend MLIR.

And:

> **SCR must extend MLIR before inventing a competing representation.**

---

# 66. Architectural Evolution

SCR is expected to evolve.

Future additions may include:

* new semantic domains;
* new MLIR dialects;
* new interfaces;
* new transformations;
* new providers;
* new execution substrates;
* new hardware targets;
* distributed execution;
* adaptive execution;
* richer rendering;
* richer messaging;
* richer learning;
* richer agent semantics.

Architectural evolution must preserve:

1. semantic primacy;
2. MLIR as canonical representation substrate;
3. provider independence;
4. representation independence;
5. compositionality;
6. explicit contracts;
7. semantic verification;
8. domain independence.

---

# 67. Architectural Change Control

Any proposed change that would alter one of the following requires explicit architectural review:

* canonical representation;
* MLIR dependency;
* semantic model;
* dialect boundaries;
* interface model;
* provider boundary;
* runtime boundary;
* execution model;
* semantic invariants;
* dependency direction.

In particular, a proposal to introduce a second compiler representation requires explicit architectural approval.

It must never arise implicitly from implementation convenience.

---

# 68. Final Architectural Model

The architecture can be summarized as:

```text
                         SCR
                          │
          ┌───────────────┴────────────────┐
          │                                │
 Semantic Architecture               MLIR Infrastructure
          │                                │
 Ontology                          Dialects
 Semantics                         Operations
 Contracts                         Types
 Invariants                        Attributes
 Capabilities                      Interfaces
 Composition                       Traits
 Domain Meaning                    Verification
 Provider Contracts                Analysis
          │                         Transformation
          │                         Lowering
          └───────────────┬────────────────┘
                          │
                         MLIR
                          │
                       Provider
                          │
                        Runtime
                          │
                    Execution Substrate
                          │
                 CPU / GPU / Accelerator
```

The critical architectural boundary is:

```text
Semantic Model
      ↓
SCR Semantic MLIR
      ↓
MLIR
```

not:

```text
Semantic Model
      ↓
Domain IR
      ↓
MLIR
```

---

# 69. Constitutional Principles

The SCR architecture is governed by the following principles.

## Principle 1 — Semantic Primacy

Meaning is primary.

## Principle 2 — MLIR Foundation

SCR is built on MLIR, not beside it.

## Principle 3 — Single Compiler Representation

MLIR is the canonical compiler representation substrate.

## Principle 4 — No Shadow IR

SCR must not introduce a parallel Domain IR, Semantic IR, or SCR IR.

## Principle 5 — Representation Independence

Meaning must not depend unnecessarily on representation.

## Principle 6 — Provider Independence

Meaning must not depend unnecessarily on implementation provider.

## Principle 7 — Hardware Independence

Semantic programs must not depend unnecessarily on hardware.

## Principle 8 — Capability-Driven Composition

Composition should be based on semantic compatibility and capabilities.

## Principle 9 — Explicit Transformation

Changes in semantics, representation, precision, approximation, or execution must be explicit.

## Principle 10 — Verification

Semantic contracts and invariants must be machine-verifiable wherever practical.

## Principle 11 — Information Preservation

Information must be preserved until loss is explicitly required or justified.

## Principle 12 — No Implementation Leakage

External implementation technology must not silently become semantic architecture.

## Principle 13 — MLIR Before Reinvention

Use existing MLIR mechanisms before creating SCR-specific compiler infrastructure.

## Principle 14 — Meaning Before Mechanism

Define what a computation means before deciding how it executes.

---

# 70. Final Definition

The Semantic Computational Runtime is:

> **An open, extensible, MLIR-based semantic computational environment in which heterogeneous computational domains are represented as formally specified, composable semantics and compiled and executed across heterogeneous providers and execution substrates.**

An SCR semantic object is:

> **An identifiable computational entity with formally describable properties, relationships, state, capabilities, constraints and transformations, represented computationally through MLIR and capable of being composed, analyzed, transformed, represented and executed independently of any particular implementation provider or hardware target.**

The fundamental architectural relationship is:

```text
Semantic Meaning
      ↓
Semantic Model
      ↓
SCR Semantic MLIR
      ↓
MLIR Infrastructure
      ↓
Transformation
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

There is no additional compiler IR between semantic meaning and MLIR.

---

# 71. Final Principle

> **Never confuse what a computation means with how a computation happens to be implemented.**

And, specifically:

> **Never create another compiler representation merely because MLIR has not yet been fully leveraged.**

SCR extends MLIR where semantic capability is missing.

SCR composes MLIR where existing capability is sufficient.

SCR uses providers where concrete implementation is required.

SCR uses the runtime where execution must be coordinated.

But the semantic computational representation remains grounded in one substrate:

# **MLIR**

**MLIR is the substrate. SCR is the semantic architecture built upon it.**
