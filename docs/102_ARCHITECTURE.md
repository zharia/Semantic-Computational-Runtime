# Semantic Computational Runtime

## Architecture

**Document:** SCR-ARCHITECTURE  
**Version:** 2.0  
**Status:** Foundational Architecture Specification

---

## 1. Architectural Principle

The Semantic Computational Runtime is organised around one foundational rule:

> **The Semantic Field is the architectural substrate of SCR.**

All computational structures, execution mechanisms, representations, providers, and physical mappings MUST be derivable from, or explicitly mapped to, semantic structures in the field.

The implementation stack therefore grows outward rather than downward from an arbitrary machine abstraction.

```text
SEMANTIC FIELD
      ↓
SEMANTIC STRUCTURE
      ↓
SEMANTIC TRANSFORMATION
      ↓
SEMANTIC EXECUTION
      ↓
REPRESENTATION
      ↓
PROVIDER
      ↓
RUNTIME RESOURCE
      ↓
PHYSICAL EXECUTION
```

---

## 2. System Model

The Semantic Field contains a potentially evolving set of semantic structures.

A useful abstract model is:

\[
\mathcal{F} = (E,R,T,C,S,K,O,P)
\]

where:

- \(E\) = entities;
- \(R\) = relationships;
- \(T\) = transformations;
- \(C\) = context and constraints;
- \(S\) = semantic state;
- \(K\) = capabilities;
- \(O\) = observations/events;
- \(P\) = projections/representations.

This is a conceptual model, not a mandatory physical data structure.

A conforming implementation may represent these components using graphs, hypergraphs, tables, IR nodes, objects, distributed structures, spatial indexes, or other mechanisms.

---

## 3. Architectural Domains

SCR consists of several architectural concerns, but they are not peers at the semantic foundation.

```text
                    Semantic Field
                         │
        ┌────────────────┼─────────────────┐
        │                │                 │
     Ontology         Topology        Transformation
        │                │                 │
        └────────────────┼─────────────────┘
                         ↓
                    Context/State
                         ↓
                 Semantic Program
                         ↓
              Semantic Compilation
                         ↓
        Representation / Provider Selection
                         ↓
                  Runtime Execution
                         ↓
                 Physical Resources
```

The architecture therefore distinguishes:

1. semantic definition;
2. semantic structure;
3. semantic transformation;
4. semantic execution;
5. representation;
6. provider realisation;
7. physical runtime;
8. hardware.

---

## 4. Semantic Field

The Semantic Field is the highest architectural authority.

It defines the universe in which SCR semantics exist.

The field is not synonymous with:

- a graph;
- a database;
- MLIR;
- a runtime heap;
- an address space;
- a process;
- a distributed cluster;
- physical memory.

Those are manifestations or execution structures.

The field may be partitioned into semantic regions, contexts, scopes, domains, or subfields without changing its foundational status.

---

## 5. Semantic Entities

An entity is a persistent semantic referent.

An entity has semantic identity independent of its physical manifestation.

An implementation MAY assign:

- object IDs;
- handles;
- addresses;
- pointers;
- UUIDs;
- offsets;
- database keys;
- device identifiers;

but none of these is inherently the semantic identity unless explicitly defined by the semantic contract.

---

## 6. Relationships

Relationships are first-class semantic structures.

A relationship may encode:

- direction;
- cardinality;
- weight;
- type;
- temporal validity;
- spatial validity;
- provenance;
- constraints;
- causality;
- dependency;
- correspondence;
- ownership or reference semantics.

A pointer may implement a relationship. It does not define the relationship.

This distinction is essential for relocation, distribution, persistence, serialisation, optimisation, and heterogeneous execution.

---

## 7. Transformations

A transformation is a semantic rule that changes field structure or state.

Examples include:

```text
create
remove
compose
map
reduce
sample
integrate
differentiate
propagate
evolve
observe
optimise
control
render
stream
allocate
communicate
```

Transformations are themselves semantic entities where their identity, provenance, constraints, or composition requires it.

A machine instruction sequence is one possible realisation of a transformation.

---

## 8. Topology

SCR treats semantic topology as a first-class architectural concern.

Topology includes not only adjacency but the organisation of semantic relationships and transformation pathways.

Topology may change during execution.

Examples:

- graph edge creation/removal;
- agent migration;
- mesh refinement;
- morphology changes;
- stream routing;
- task creation;
- provider substitution;
- dynamic resource placement.

Consequently, SCR must not assume that the computational graph is static merely because a compiled representation exists.

---

## 9. Semantic Program

A semantic program is a bounded, executable semantic substructure of the field.

\[
P \subseteq \mathcal{F}
\]

A program contains the entities, relationships, transformations, context, constraints, and capabilities necessary to define a computation.

A program MAY be:

- constructed dynamically;
- transformed before execution;
- specialised during execution;
- distributed;
- partially materialised;
- incrementally compiled;
- reconfigured as topology changes.

---

## 10. Semantic Execution

Execution is the controlled realisation of valid semantic transformations.

A useful abstract model is:

\[
\mathcal{E}: (P,S,R,Q) \rightarrow (P',S',O)
\]

where:

- \(P\) = semantic program structure;
- \(S\) = semantic state;
- \(R\) = available representations/resources;
- \(Q\) = execution constraints/policies;
- \(P'\) = resulting program topology;
- \(S'\) = resulting semantic state;
- \(O\) = observations/events.

Execution therefore need not be understood as merely “running instructions”.

It is semantic evolution under constraints.

---

## 11. Semantic Compilation

Compilation transforms semantic structure while preserving the required semantics.

The conceptual pipeline is:

```text
Semantic Field
      ↓
Semantic Program
      ↓
Analysis
      ↓
Canonicalisation
      ↓
Transformation / Optimisation
      ↓
Representation Selection
      ↓
Provider Selection
      ↓
Hardware Mapping
      ↓
Lowering
      ↓
Executable Manifestation
```

Optimisations may include:

- fusion;
- decomposition;
- common-subexpression elimination;
- specialisation;
- tiling;
- vectorisation;
- parallelisation;
- distribution;
- provider substitution;
- representation conversion;
- memory-layout optimisation;
- precision/quantisation selection.

Every such transformation is subordinate to semantic invariants.

---

## 12. MLIR Position

MLIR is SCR's primary compiler infrastructure and semantic representation technology.

However:

\[
\boxed{\text{Semantic Field} \neq \text{MLIR}}
\]

MLIR represents and transforms semantic structures. It does not define the complete semantic universe.

SCR should therefore use:

```text
Semantic Field
   ↓
Semantic Model
   ↓
Semantic MLIR Dialects
   ↓
MLIR Infrastructure
   ↓
MLIR Lowering
```

rather than:

```text
MLIR
   ↓
meaning
```

This distinction prevents accidental coupling between semantic identity and a compiler implementation detail.

---

## 13. Capabilities

Capabilities describe valid semantic participation.

Examples:

```text
Composable
Transformable
Stateful
Observable
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

Capabilities are contracts, not merely tags.

A capability MUST define the semantic obligations necessary for another component to rely on it.

---

## 14. Representation Layer

A semantic object may have zero, one, or many physical representations.

Representations include:

```text
scalar
vector
array
tensor
sparse tensor
mesh
voxel grid
implicit surface
particle set
graph
tree
spatial index
GPU buffer
distributed shard
stream
message buffer
persistent record
```

Representation selection may depend on:

- access pattern;
- precision;
- sparsity;
- locality;
- topology;
- hardware;
- memory pressure;
- downstream operations;
- provider availability;
- latency constraints.

The representation layer MUST NOT become the semantic authority.

---

## 15. Provider Layer

A provider implements a semantic contract.

Providers may be:

- native runtime components;
- external libraries;
- generated kernels;
- GPU implementations;
- CPU implementations;
- accelerator implementations;
- distributed services;
- storage engines;
- messaging systems.

Provider substitution is valid only where semantic contracts and required invariants remain satisfied.

---

## 16. Runtime Architecture

The runtime provides physical realisation of semantic execution.

Responsibilities include:

```text
resource discovery
allocation
representation management
provider lifecycle
scheduling
execution
messaging
synchronisation
data movement
memory management
telemetry
fault handling
persistence
dynamic specialisation
```

The runtime may adapt execution without changing semantic meaning.

---

## 17. Memory and Allocation

Memory is a manifestation substrate, not the definition of semantic value.

The conceptual chain is:

```text
Semantic Value
      ↓
Runtime Object
      ↓
Storage Representation
      ↓
Physical Allocation
```

Allocation strategies may include:

- inline;
- heap;
- size-class;
- pool;
- arena;
- region;
- slab;
- segmented;
- external/device memory.

Ownership, lifetime, identity, and allocation are separate concerns.

---

## 18. Messaging and Communication

Communication is treated as semantic transformation and relationship transport rather than merely byte movement.

A message has semantic identity, payload semantics, context, provenance, delivery constraints, and potentially temporal validity.

AMQP-style messaging may provide an implementation model for queues, exchanges, routing, delivery, acknowledgements, and flow control, but the semantic message contract remains above the transport implementation.

---

## 19. Rendering and Stream Processing

Rendering is a semantic projection of field state into a perceptual or visual manifestation.

Streaming is semantic evolution exposed through temporal sequences of observations or transformations.

Neither should be treated as an afterthought attached to a simulation loop.

Both participate directly in semantic execution.

---

## 20. Distributed Execution

The Semantic Field may span processes, devices, nodes, or geographic locations.

Distribution is therefore a representation and execution decision, not necessarily a semantic partition.

A semantic relationship may be manifested as:

```text
pointer
handle
local reference
message
RPC
shared memory mapping
RDMA operation
persistent reference
```

The semantic relationship remains independent of the mechanism.

---

## 21. Architectural Dependency Rule

The following dependency direction is normative:

```text
Semantic Field
    ↓
Semantic Model
    ↓
Semantic Contracts / Invariants
    ↓
Semantic Dialects and Transformations
    ↓
Compiler / MLIR
    ↓
Representation / Provider Selection
    ↓
Runtime
    ↓
Physical Resources
```

Lower layers may constrain implementation choices, but MUST NOT redefine higher-layer semantics.

---

## 22. Architecture Decision Test

Every significant architectural decision should answer:

1. What semantic construct does this introduce or realise?
2. Which field relationships does it create or consume?
3. Which transformations does it enable?
4. Which invariants constrain it?
5. Which representations can manifest it?
6. Which providers can implement it?
7. What runtime resources are required?
8. What happens when topology changes?
9. Can the semantic construct survive relocation, serialisation, distribution, or representation change?
10. Is the implementation accidentally becoming the semantic definition?

If the last answer is yes, the abstraction boundary is wrong.
