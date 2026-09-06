# Semantic Computational Runtime (SCR)

> **An open, extensible, MLIR-based semantic computational environment for expressing heterogeneous computation in terms of computational meaning rather than implementation technology.**

Semantic Computational Runtime (SCR) is an experimental computational framework built on **[MLIR](https://mlir.llvm.org/)**.

SCR provides a semantic architecture for representing, composing, analysing, transforming, specialising, and executing computational concepts across heterogeneous domains and execution substrates.

It is designed around a simple principle:

> **Applications should be expressed in terms of computational meaning rather than implementation technology.**

SCR is not a simulator, physics engine, rendering engine, compiler replacement, or wrapper library. Simulation is an important reference workload, but SCR is deliberately general enough to support computational systems spanning mathematics, data, fields, graphs, geometry, morphology, physics, dynamics, simulation, agents, neural computation, optimisation, control, perception, rendering, streaming, messaging, and other domains.

---

## 1. The Core Idea

Modern computational systems are often constructed directly from implementation technologies:

```text
Application
    ↓
Library APIs
    ↓
Runtime APIs
    ↓
Hardware / Platform
```

This makes application semantics tightly coupled to particular libraries, runtimes, programming languages, accelerators, or execution environments.

SCR introduces a semantic architecture between application intent and implementation:

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

The important distinction is that **SCR does not introduce another intermediate representation between the Semantic Model and MLIR**.

### There is no separate SCR IR.

SCR does not define:

* a Domain IR;
* a Semantic IR;
* an SCR IR;
* a parallel SSA representation;
* a second type system;
* a proprietary operation graph;
* a shadow compiler representation.

**MLIR is the canonical compiler representation and infrastructure.**

SCR expresses its semantic architecture through MLIR's extensibility mechanisms:

* dialects;
* operations;
* types;
* attributes;
* interfaces;
* traits;
* regions;
* symbols;
* SSA values;
* analyses;
* transformations;
* passes;
* canonicalisation;
* pattern rewriting;
* verification;
* lowering.

Where existing MLIR mechanisms are sufficient, SCR uses them directly.

Where domain-specific semantics are required, SCR extends MLIR through appropriate dialects, interfaces, types, attributes, operations, analyses, and transformations.

---

## 2. What SCR Provides

SCR separates **what a computation means** from **how that computation is ultimately realised**.

The framework therefore provides a semantic architecture for:

### Semantic representation

Represent computational meaning using MLIR while preserving:

* identity;
* relationships;
* constraints;
* capabilities;
* state;
* temporal semantics;
* spatial semantics;
* transformations;
* execution requirements;
* observable behaviour.

### Semantic composition

Compose computational concepts across domains without requiring applications to know which implementation technology will ultimately execute them.

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

can form a larger semantic construct such as:

```text
agent.propagate
```

which can itself participate in:

```text
population.evolve
```

Composition is therefore based on **semantic compatibility**, not merely API compatibility.

### Capability-driven execution

Computational constructs can expose capabilities such as:

* composable;
* transformable;
* decomposable;
* stateful;
* observable;
* spatial;
* temporal;
* spatiotemporal;
* dynamical;
* differentiable;
* parallelisable;
* vectorisable;
* tileable;
* reducible;
* distributable;
* streamable;
* renderable;
* projectable;
* learnable;
* optimisable;
* controllable;
* morphological;
* deformable;
* deterministic;
* stochastic.

These capabilities allow the compiler and runtime to reason about how computational semantics can be composed and realised.

---

## 3. Representation Independence

SCR separates semantic identity from physical representation.

A semantic object may be realised as:

* a mesh;
* a voxel field;
* an implicit surface;
* a particle system;
* a finite-element structure;
* a graph;
* a tensor;
* a sparse structure;
* a spatial index;
* a stream;
* a distributed representation;
* a GPU-native structure;
* another provider-specific representation.

The representation is selected according to the requirements of the computation and execution environment.

For example, semantic morphology should not inherently mean "mesh".

The same morphological semantics may be materialised differently for:

```text
Simulation
Collision
Physics
Rendering
Analysis
Spatial indexing
Manufacturing
Visualisation
```

The semantic layer therefore describes **what exists and how it behaves**, while providers determine appropriate concrete realisations.

---

## 4. Morphology Is First-Class

SCR treats morphology as a computational semantic domain rather than merely a rendering or geometry concern.

Morphology can emerge from patterns, while patterns can be inferred from morphology:

```text
Patterns
   ↕
Morphology
   ↕
Structure
   ↕
Representation
```

This bidirectional relationship allows SCR to reason about structure at multiple scales.

Morphological semantics may describe:

* form;
* structure;
* topology;
* spatial organisation;
* boundaries;
* deformation;
* emergence;
* composition;
* fragmentation;
* aggregation;
* growth;
* transformation;
* scale-dependent structure.

The resulting representation can then be specialised for the consumer without changing the underlying semantic identity.

---

## 5. Heterogeneous Computational Domains

SCR is deliberately not organised around a single computational domain.

Potential semantic domains include:

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
Control
Neural
Learning
Optimisation
Perception
Rendering
Stream
Messaging
Adaptation
Evolution
Ecology
```

These are not independent silos.

Their semantics can be composed through shared capabilities, interfaces, types, operations, and transformations.

For example:

```text
Field
  ↓
Interaction
  ↓
Dynamics
  ↓
Agent
  ↓
Population
  ↓
Evolution
```

The resulting architecture is therefore a **computational semantic system**, rather than a collection of unrelated domain libraries.

---

## 6. MLIR as the Foundation

SCR is built on MLIR rather than attempting to replace it.

MLIR provides the canonical infrastructure for:

* intermediate representation;
* SSA;
* types;
* attributes;
* regions;
* symbols;
* dialects;
* interfaces;
* verification;
* pattern rewriting;
* canonicalisation;
* analyses;
* transformations;
* pass management;
* lowering;
* multi-level compilation.

SCR adds domain semantics and execution architecture using those mechanisms.

The architectural decision rule is:

```text
Can MLIR express it?
        ↓
Use MLIR directly.

Does an existing MLIR dialect express it?
        ↓
Use the existing dialect.

Does SCR require domain-specific semantics?
        ↓
Create an SCR dialect or extension.

Is the requirement behavioural/capability-oriented?
        ↓
Use an MLIR interface, trait, or attribute where appropriate.

Is the requirement transformational?
        ↓
Use an MLIR analysis, pattern, pass, or transformation.

Does a proposal still require another representation?
        ↓
Stop and review the architecture.
```

SCR should exhaust the capabilities of MLIR before introducing new architectural mechanisms.

---

## 7. Semantic MLIR

The term **Semantic MLIR** refers to MLIR carrying SCR semantic constructs.

It is not a second representation.

Conceptually:

```text
Semantic Model
      ↓
MLIR
+ SCR dialects
+ SCR types
+ SCR attributes
+ SCR interfaces
+ SCR operations
+ SCR transformations
      ↓
Semantic MLIR
```

"Semantic MLIR" is therefore descriptive terminology, not the name of a separate IR.

The canonical compiler representation remains **MLIR**.

---

## 8. Providers

SCR separates semantic contracts from implementation providers.

A provider may implement a semantic capability using:

* CPU code;
* GPU code;
* SIMD/vector execution;
* distributed execution;
* specialised accelerators;
* external numerical libraries;
* geometry libraries;
* spatial libraries;
* physics engines;
* rendering systems;
* stream processors;
* messaging systems;
* other execution technologies.

Conceptually:

```text
Semantic Contract
       ↓
Provider Interface
       ↓
Provider
       ↓
Native Implementation
       ↓
Execution
```

External technologies are therefore **implementation resources rather than semantic authorities**.

A provider may use a particular library internally without forcing applications to depend upon that library's semantic model.

---

## 9. Hardware Awareness Without Hardware Dependence

Hardware independence does not mean hardware ignorance.

SCR may reason about:

* CPU architecture;
* vector width;
* cache topology;
* NUMA;
* memory bandwidth;
* accelerator availability;
* GPU occupancy;
* transfer cost;
* interconnect topology;
* latency;
* throughput;
* memory pressure;
* power;
* thermal constraints;
* execution locality.

This information can influence provider selection, scheduling, specialisation, representation, and transformation.

The objective is not to maximise raw hardware utilisation.

The objective is to maximise **useful computation subject to semantic, resource, latency, throughput, and correctness constraints**.

---

## 10. Adaptive Execution

SCR is intended to support adaptive execution.

A conceptual execution cycle is:

```text
Semantic Program
      ↓
Capability Analysis
      ↓
Resource / Hardware Analysis
      ↓
Provider Selection
      ↓
Scheduling
      ↓
Compilation / Specialisation
      ↓
Execution
      ↓
Telemetry
      ↓
Re-analysis
      ↺
```

This permits computational systems to adapt to:

* workload;
* topology;
* available hardware;
* execution history;
* resource constraints;
* changing representations;
* changing computational requirements.

The runtime therefore need not treat execution topology as permanently fixed.

---

## 11. Information as a Computational Substrate

SCR is designed to support computational systems in which information itself may form a fundamental substrate.

This includes the possibility of computational structures where:

* information has locality;
* relationships determine accessibility;
* topology affects computation;
* computation modifies topology;
* representations can be transformed according to context;
* references can exist as semantic relationships;
* data and computation can coexist within a common semantic space.

This does not require a single physical representation.

The semantic architecture defines the meaning; MLIR and providers determine how that meaning is represented and executed.

---

## 12. Messaging and Streaming

Communication is a first-class computational concern.

SCR treats messaging and streaming as semantic capabilities rather than implementation-specific APIs.

Messaging semantics are intended to follow the **AMQP model** while remaining independent of any particular broker implementation.

This permits computational components to communicate through semantic contracts such as:

```text
Producer
   ↓
Message
   ↓
Exchange / Routing
   ↓
Queue
   ↓
Consumer
```

while allowing different providers to realise those semantics using different messaging infrastructure.

Streaming and rendering are likewise treated as computational domains rather than external afterthoughts.

---

## 13. Rendering

Rendering is a first-class consumer of semantic state.

A conceptual rendering path is:

```text
Semantic State
      ↓
Render Projection
      ↓
Render State
      ↓
Rendering Provider
      ↓
Vulkan / VSG / Other Backend
      ↓
Visible Result
```

Rendering therefore does not define the semantic model.

It consumes a semantic projection appropriate for visualisation.

This preserves the distinction between:

```text
What exists
```

and:

```text
How it is displayed.
```

---

## 14. Simulation as the Reference Workload

Simulation is an important development workload for SCR because it exercises many independent computational domains simultaneously.

A minimal reference path is:

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
Vulkan / VSG
  ↓
Visible Result
```

The simulation is a **vertical architectural proof**, not the boundary of the project.

If SCR succeeds only as a simulation framework, it has failed its broader architectural objective.

---

## 15. Repository Architecture

The repository separates architectural authority from implementation state.

### `003_PROJECT_MANDATE.md`

Defines:

* why SCR exists;
* project purpose;
* foundational constraints;
* architectural objectives;
* project boundaries.

### `004_ARCHITECTURE.md`

Defines:

* how SCR's architectural components relate;
* representation architecture;
* MLIR integration;
* semantic domains;
* capabilities;
* providers;
* execution;
* architectural invariants.

### `AGENTS.md`

Defines:

* implementation governance;
* agent behaviour;
* architectural constraints;
* repository conventions;
* development rules.

### `docs/`

Contains detailed semantic, architectural, invariant, and technical documentation.

### `lib/`

Contains the semantic library and domain definitions.

The `lib/` hierarchy is an organisational structure. It is **not itself an execution representation or IR hierarchy**.

### `program_increments/`

Contains implementation planning and vertical delivery specifications.

### `public-documentation/`

Contains documentation intended for external users and contributors.

---

## 16. Architectural Authority

SCR maintains an explicit hierarchy of authority:

```text
Project Mandate
      ↓
Architecture
      ↓
Semantic Model
      ↓
Semantic Invariants
      ↓
Implementation Governance
      ↓
Implementation
      ↓
Derived Metadata
```

The architecture documents are normative.

Generated graphs, indexes, status files, implementation details, and provider-specific structures must not silently redefine the architectural model.

Where implementation and architecture disagree, the discrepancy must be resolved explicitly rather than allowing implementation details to become accidental architecture.

---

## 17. Fundamental Architectural Principles

SCR is governed by the following principles.

### Semantic Primacy

Computational meaning comes before implementation mechanism.

### MLIR Foundation

MLIR is the foundational compiler and representation infrastructure.

### Single Compiler Representation

SCR does not maintain a second compiler IR.

### No Shadow IR

Rust structures, JSON/YAML structures, graphs, registries, or provider objects must not silently become alternative execution representations.

### Representation Independence

Semantic identity must not depend on a particular physical representation.

### Provider Independence

Semantic contracts must not be defined by implementation providers.

### Hardware Independence

Applications should not require knowledge of the hardware on which their semantics will execute.

### Capability-Driven Composition

Composition should be based on semantic capabilities and contracts.

### Explicit Transformation

Changes in representation or computational form must be explicit and semantically justified.

### Verification

Semantic correctness and architectural invariants must be verifiable.

### Information Preservation

Transformations should preserve required semantic information unless information loss is explicit and justified.

### No Implementation Leakage

Provider and hardware details must not leak into higher semantic layers without an explicit architectural reason.

### MLIR Before Reinvention

Existing MLIR mechanisms must be considered and exhausted before creating SCR-specific mechanisms.

### Meaning Before Mechanism

The framework describes what a computation means before deciding how it is executed.

---

## 18. Current Status

SCR is currently in an **architectural and foundational implementation phase**.

The project is establishing:

* the semantic architecture;
* MLIR integration;
* semantic dialect boundaries;
* semantic contracts;
* capability interfaces;
* provider architecture;
* execution architecture;
* library definitions;
* vertical implementation increments;
* the minimal deterministic simulation path.

The initial implementation is deliberately small.

The objective is to prove the architecture through complete vertical slices rather than build a large collection of disconnected infrastructure.

---

## 19. v0.0.1 Golden Path

The first implementation milestone is a minimal deterministic particle simulation.

Its purpose is to prove that a semantic computation can travel through the complete SCR architecture:

```text
Semantic Definition
        ↓
Semantic Model
        ↓
SCR Semantic MLIR
        ↓
MLIR Infrastructure
        ↓
Verification
        ↓
Analysis
        ↓
Transformation
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
Vulkan / VSG
        ↓
Visible Result
```

The milestone is successful when the complete path can be demonstrated while preserving semantic identity across the transformations and execution stages.

---

## 20. Development Philosophy

SCR follows a **vertical-slice-first** development strategy.

A feature is not considered architecturally proven merely because its data structures or APIs exist.

A meaningful vertical slice should demonstrate:

```text
Semantic Definition
        ↓
Representation
        ↓
Verification
        ↓
Transformation
        ↓
Provider Selection
        ↓
Execution
        ↓
Observable Result
```

This keeps the project grounded in executable semantics rather than accumulating disconnected abstractions.

---

## 21. What SCR Is Not

SCR is not:

* a replacement for MLIR;
* a replacement for LLVM;
* a general-purpose programming language;
* a conventional application framework;
* a simulation-only engine;
* a physics-only framework;
* a rendering engine;
* a message broker;
* a GPU programming framework;
* a wrapper around a collection of external libraries;
* a proprietary intermediate representation;
* a second compiler infrastructure.

SCR instead provides the **semantic architecture that allows these technologies to participate in a common computational environment without becoming the semantic definition of the application**.

---

## 22. Long-Term Objective

The long-term objective is a computational environment in which an application can express:

```text
What it means
```

without prematurely specifying:

```text
Where it runs
How it is represented
Which library implements it
Which accelerator executes it
Which runtime schedules it
Which renderer displays it
Which broker transports it
```

Those decisions can instead be derived, specialised, transformed, and adapted according to semantic requirements and execution conditions.

The intended result is a computational architecture in which heterogeneous technologies become **providers of capability rather than competing semantic worlds**.

---

## 23. Repository

**Semantic Computational Runtime**

[GitHub Repository](https://github.com/zharia/Semantic-Computational-Runtime)

The repository contains the authoritative architecture, semantic specifications, implementation governance, program increments, and evolving semantic library.

For architectural questions, begin with:

1. `003_PROJECT_MANDATE.md`
2. `004_ARCHITECTURE.md`
3. `AGENTS.md`
4. `docs/`
5. the relevant program increment

---

## 24. Final Definition

> **Semantic Computational Runtime (SCR) is an open, extensible, MLIR-based semantic computational environment in which heterogeneous computational domains are expressed through formal semantic constructs and realised across heterogeneous execution substrates.**

SCR's central architectural commitment is simple:

> **There is no separate SCR IR. MLIR is the canonical compiler representation. SCR extends and uses MLIR to express computational semantics rather than creating another representation system beside it.**
