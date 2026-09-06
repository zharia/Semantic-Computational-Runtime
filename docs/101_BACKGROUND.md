# Semantic Computational Runtime

## Project Background, Origin and Rationale

**Document:** SCR-BACKGROUND  
**Version:** 2.0  
**Status:** Foundational Project Documentation  
**Audience:** Developers, researchers, architects, AI agents, contributors

---

## 1. Executive Summary

The Semantic Computational Runtime (SCR) emerged from attempts to construct computational environments capable of representing and executing complex simulations, information systems, physical models, spatial structures, morphology, neural computation, rendering, streaming, and interacting agents.

The original problem appeared to be simulation engineering. It became clear that the deeper problem was architectural:

> **Modern computational systems are fragmented by implementation technology rather than organised around computational meaning.**

SCR therefore seeks to establish a common semantic computational substrate in which computational entities, relationships, transformations, constraints, state, and topology can be represented independently of the physical mechanisms ultimately used to execute them.

The foundational architectural conclusion is:

> **The Semantic Field is the substrate of SCR.**

The Semantic Field is not an IR, programming language, database, graph library, runtime heap, or physical memory space. It is the semantic universe in which computational meaning is defined.

Everything else in SCR is derived from, mapped to, or used to manifest that field.

The governing engineering principle is:

> **Engineer outward from the Semantic Field.**

First determine what exists, how it relates, how it may transform, and what constraints govern it. Only then determine how those semantics should be represented, compiled, scheduled, allocated, transmitted, rendered, or executed on physical resources.

---

## 2. The Original Problem

A sufficiently ambitious computational system is not a single algorithm. It is a composition of computational domains:

```text
information
fields
spatial relationships
geometry
topology
morphology
physics
dynamics
agents
perception
neural computation
control
rendering
streaming
distributed execution
```

A simulated agent, for example, may occupy a spatial region, observe a field, perceive geometry, maintain state, perform inference, select an action, invoke control, alter physical state, change morphology, produce a rendering, and emit telemetry.

Traditional architectures divide these activities into separate software universes. Each universe introduces its own representation, API, lifecycle, memory model, and execution assumptions.

The resulting integration burden grows with the number of domains and representations that must be connected.

SCR addresses the problem by moving the primary abstraction boundary from implementation APIs to computational semantics.

---

## 3. The Deeper Observation

Many apparently unrelated computational systems share common semantic structures.

Objects from physics, graphics, neural computation, agents, storage, and simulation may all possess:

```text
identity
state
properties
relationships
constraints
transformations
observations
```

Likewise, dynamics, recurrence, control, simulation steps, stream processing, and state machines all involve transitions:

```text
state → transformation → new state
```

Fields, graphs, geometry, topology, and morphology all describe structured relationships over some domain.

The missing abstraction was therefore not another domain-specific library. It was a semantic substrate beneath the domains.

---

## 4. From APIs to a Semantic Field

The earlier SCR model was approximately:

```text
Application
    ↓
Semantic abstraction
    ↓
Semantic interfaces
    ↓
Semantic composition
    ↓
Compiler transformations
    ↓
Provider selection
    ↓
Hardware implementation
```

The model is now refined to:

```text
                    SEMANTIC FIELD
                         │
          ┌──────────────┼──────────────┐
          │              │              │
       Entities     Relationships   Transformations
          │              │              │
          └──────────────┼──────────────┘
                         ↓
                Context / Constraints
                         ↓
                    State / Topology
                         ↓
                  Semantic Program
                         ↓
                 Semantic Execution
                         ↓
             Representation / Provider
                         ↓
                  Runtime Resources
                         ↓
                    Hardware
```

This is not merely a revised diagram. It changes how architectural decisions are made.

A representation is not the thing represented. A provider is not the semantic operation it implements. An address is not semantic identity. A message buffer is not the semantic relationship it transports. A machine instruction is not the semantic transformation it realizes.

The physical system is a manifestation of semantic structure.

---

## 5. What the Semantic Field Means

The Semantic Field is the total semantic context in which SCR computational structures exist and evolve.

It provides the domain in which the following are meaningful:

- entities and identity;
- values and properties;
- relationships;
- transformations and operations;
- context;
- state;
- constraints;
- capabilities;
- observations and events;
- semantic topology;
- temporal evolution;
- spatial or other domain structure;
- representations;
- execution commitments;
- provenance and correspondence.

The field may be manifested as a graph, hypergraph, IR, object structure, relational representation, distributed structure, spatial field, or other physical representation. None of those manifestations defines the field itself.

A hypergraph is therefore a possible structural manifestation of semantic topology, not the semantic definition of SCR.

---

## 6. Programs as Semantic Structures

A program in SCR is not fundamentally a sequence of machine instructions.

It is a semantic substructure of the field:

\[
P \subseteq \mathcal{F}
\]

where \(\mathcal{F}\) is the Semantic Field and \(P\) is a computationally meaningful substructure containing relevant entities, relationships, transformations, context, and constraints.

Execution is consequently the controlled evolution of that structure:

\[
P_t \xrightarrow{\mathcal{T}} P_{t+1}
\]

where \(\mathcal{T}\) is a valid semantic transformation subject to declared invariants and constraints.

This permits SCR to reason about computation independently of whether the eventual implementation is a CPU loop, GPU kernel, distributed task, message exchange, storage operation, rendering pass, or specialised accelerator instruction sequence.

---

## 7. Why MLIR Became Central

SCR deliberately does not create a second general-purpose compiler IR.

MLIR provides mature infrastructure for:

- types;
- operations;
- regions;
- attributes;
- interfaces;
- verification;
- rewriting;
- canonicalisation;
- dialect conversion;
- analysis;
- progressive lowering;
- hardware-oriented transformations.

The architectural refinement is important, however:

> **MLIR is not the Semantic Field.**

MLIR is the principal representation and transformation infrastructure through which portions of the Semantic Field can be represented and compiled.

The relationship is therefore:

```text
Semantic Field
      ↓
Semantic Model
      ↓
Semantic MLIR representation
      ↓
MLIR transformation infrastructure
      ↓
Lowered representations
      ↓
Executable manifestations
```

This preserves the original decision — **do not build a second IR; extend MLIR** — while preventing MLIR from becoming the accidental definition of semantic meaning.

---

## 8. The Semantic Library

The Semantic Library defines the vocabulary, contracts, capabilities, transformations, and domain models that inhabit the Semantic Field.

Initial domains include:

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
Neural
Learning
Optimization
Agent
Control
Perception
Render
Stream
```

These domains are not isolated libraries. They are semantic regions of one computational system.

---

## 9. Progressive Abstraction

SCR continues to use progressive abstraction:

```text
L0  Mathematical semantics
 ↓
L1  Computational semantics
 ↓
L2  Structural semantics
 ↓
L3  Domain semantics
 ↓
L4  Composite semantics
 ↓
L5  System semantics
```

But the levels are understood as increasingly rich structures within the same Semantic Field, rather than as independent abstraction universes.

For example:

```text
value
 ↓
vector
 ↓
field
 ↓
physical field
 ↓
dynamical system
 ↓
simulation
 ↓
agent-environment system
```

Higher-level concepts must remain grounded in lower-level semantic contracts.

---

## 10. Capabilities and Interfaces

SCR uses semantic capability rather than inheritance as its primary cross-domain composition mechanism.

Examples include:

```text
Composable
Transformable
Observable
Stateful
Spatial
Temporal
Spatiotemporal
Dynamical
Differentiable
Parallelizable
Vectorizable
Tileable
Reducible
Distributable
Streamable
Renderable
Projectable
Learnable
Optimizable
Controllable
Deterministic
Stochastic
Seedable
Serializable
Persistable
Morphological
Representable
Deformable
```

Capabilities describe valid participation in the Semantic Field. They do not imply that two entities are instances of one class hierarchy.

---

## 11. Morphology as a Semantic Case Study

Morphology demonstrates why semantics must be separated from representation.

Morphology concerns form, structure, boundary, feature, composition, deformation, growth, fracture, generation, and correspondence.

A single semantic morphology may be manifested as:

```text
mesh
voxel field
implicit surface
particle system
parametric structure
collision geometry
finite-element structure
render geometry
```

The semantic morphology remains the same class of meaning even though its manifestations differ.

This principle generalises across SCR.

---

## 12. Representation Independence

A semantic field must not silently become a memory layout.

Examples:

```text
field       ≠ dense CPU array
geometry    ≠ triangle mesh
tensor      ≠ contiguous host allocation
identity    ≠ memory address
relationship ≠ pointer
message     ≠ byte buffer
program     ≠ instruction sequence
```

Representations are selected under semantic, performance, resource, and execution constraints.

The same semantic structure may legitimately possess multiple simultaneous representations.

---

## 13. Providers and the Existing Ecosystem

SCR does not replace mature computational technologies.

Existing libraries and platforms become providers of semantic capabilities.

Conceptually:

```text
Semantic contract
       ↓
Provider capability
       ↓
Implementation
       ↓
Physical resources
```

A physics provider may use a specialised solver. A geometry provider may use a mesh library. A renderer may target GPU APIs. A storage provider may use a database. A messaging provider may use an AMQP implementation.

The provider satisfies the semantic contract; it does not redefine it.

---

## 14. The Runtime

MLIR provides representation and transformation infrastructure. SCR still requires a runtime capable of realising semantic computation.

Runtime responsibilities may include:

- resource discovery;
- representation management;
- allocation;
- provider selection;
- scheduling;
- execution;
- messaging;
- data movement;
- synchronisation;
- telemetry;
- dynamic specialisation;
- JIT or recompilation;
- device management;
- persistence;
- failure handling.

The runtime is therefore the mechanism through which semantic execution is coupled to physical resources.

---

## 15. Why Simulation Remains Important

Simulation remains an important reference workload because it exercises almost every difficult part of the semantic architecture:

```text
mathematics
fields
graphs
geometry
topology
spatial computation
morphology
physics
dynamics
agents
neural computation
control
rendering
streaming
distributed execution
```

However, simulation is a proving ground, not the architectural boundary.

The same semantic substrate should support scientific computing, robotics, neural computation, procedural systems, digital twins, spatial analytics, visualisation, and other computational domains.

---

## 16. Engineering Principle

All SCR engineering should proceed outward from the Semantic Field.

Before introducing an abstraction, ask:

1. What exists in the field?
2. What identity does it have?
3. What relationships exist?
4. What transformations are valid?
5. What context and constraints govern them?
6. How may topology evolve?
7. What observations and events expose that evolution?
8. What representation is appropriate?
9. What provider can realise the semantics?
10. What physical resources should execute it?

This ordering is normative.

> **Lower layers MUST NOT silently redefine semantics established by higher layers.**

---

## 17. Closing Position

SCR is therefore best understood not as a simulation engine, compiler, graph runtime, or collection of semantic dialects.

It is an attempt to construct a computational environment in which meaning is the primary architectural object and implementation is a derived concern.

The central idea is simple:

> **Engineer outward from the Semantic Field.**

Everything else follows from this principle.
