---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-CORE
name: Core

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: null

authority: SCR
domain: semantic-library
---

# SCR Core

## 1. Definition

SCR Core is the foundational semantic domain of the Semantic Computational Runtime.

Core defines the fundamental concepts through which computational meaning is represented, related, identified, transformed, observed, constrained, and evolved independently of any particular application domain, programming language, implementation technology, storage mechanism, serialization format, transport protocol, execution runtime, operating system, or hardware substrate.

Core is the semantic foundation upon which all other SCR domains are constructed.

Core defines the minimum semantic machinery required for a computational object to:

* exist;
* have identity;
* have type;
* possess values or state;
* participate in relationships;
* form higher-order relationships;
* belong to semantic regions;
* be referenced;
* be represented;
* be transformed;
* participate in operations;
* evolve through state transitions;
* produce or consume events;
* participate in streams;
* carry provenance;
* possess temporal and causal context;
* expose capabilities;
* satisfy contracts;
* participate in queries and patterns;
* be observed;
* produce errors;
* consume resources;
* be compared for semantic equivalence.

Core does **not** define the domain-specific meaning of mathematics, fields, geometry, topology, physics, simulation, agents, neural computation, rendering, or other higher-level domains.

Those domains specialize the semantic machinery defined here.

---

# 2. Purpose

The purpose of Core is to provide a stable semantic substrate upon which the remainder of the SCR Semantic Library can be defined.

Core establishes:

1. semantic identity;
2. semantic types;
3. values;
4. entities;
5. objects;
6. attributes;
7. relationships;
8. roles;
9. hyperrelationships;
10. semantic regions;
11. references;
12. representations;
13. patterns;
14. transformations;
15. operations;
16. state;
17. state transitions;
18. deltas;
19. events;
20. streams;
21. temporal semantics;
22. causal semantics;
23. provenance;
24. constraints;
25. capabilities;
26. contracts;
27. composition;
28. equivalence;
29. queries;
30. observations;
31. resources;
32. errors.

These concepts MUST be sufficiently general to support all semantic domains built above Core.

---

# 3. Semantic Position

Core occupies the root of the SCR semantic library.

```text
SCR
│
└── Core
    │
    ├── Identity
    ├── Type
    ├── Value
    ├── Entity
    ├── Object
    ├── Attribute
    ├── Relationship
    ├── Role
    ├── Hypergraph
    ├── Region
    ├── Reference
    ├── Representation
    ├── Pattern
    ├── Transformation
    ├── Operation
    ├── State
    ├── Delta
    ├── Event
    ├── Stream
    ├── Temporal
    ├── Causal
    ├── Provenance
    ├── Capability
    ├── Contract
    ├── Equivalence
    ├── Query
    ├── Observation
    ├── Resource
    └── Error
```

All other semantic domains MAY depend on Core.

Core MUST NOT depend semantically on a higher-level domain.

---

# 4. Foundational Principle

> **Core defines the semantic substrate through which computational meaning exists, relates, transforms, and evolves.**

Core is therefore concerned with **what constitutes a meaningful computational object and how meaningful computational objects relate and change**.

It is not concerned with how those objects are stored or executed.

---

# 5. Scope

Core includes the semantics of:

* identity;
* type;
* value;
* entity;
* object;
* attribute;
* relationship;
* role;
* hyperrelationship;
* graph;
* semantic region;
* reference;
* representation;
* pattern;
* transformation;
* operation;
* state;
* state transition;
* delta;
* event;
* stream;
* temporal context;
* causal context;
* provenance;
* constraint;
* capability;
* contract;
* composition;
* equivalence;
* query;
* observation;
* resource;
* error.

Core MAY define generic mechanisms that higher-level domains specialize.

Core MUST NOT define domain-specific laws where those laws belong to a specialized domain.

---

# 6. Semantic Model

Core can be conceptually represented as:

```text
C = (
    I,
    T,
    V,
    E,
    R,
    G,
    Q,
    X,
    O,
    S,
    Δ,
    Ev,
    St,
    τ,
    K,
    P,
    Cn,
    Cp,
    Eq,
    Obs,
    Res,
    Err
)
```

where:

* `I` = identity;
* `T` = type;
* `V` = value;
* `E` = entity/object;
* `R` = relationships and roles;
* `G` = semantic graph/hypergraph structures;
* `Q` = queries and patterns;
* `X` = transformations;
* `O` = operations;
* `S` = state;
* `Δ` = state deltas;
* `Ev` = events;
* `St` = streams;
* `τ` = temporal semantics;
* `K` = causal context;
* `P` = provenance;
* `Cn` = constraints/contracts;
* `Cp` = capabilities;
* `Eq` = equivalence;
* `Obs` = observations;
* `Res` = resources;
* `Err` = errors.

This equation is a conceptual semantic model and does not prescribe an implementation structure.

---

# 7. Identity

Identity is a foundational Core concept.

Every semantically addressable object MUST have a distinguishable identity where identity is required by its semantic contract.

SCR MUST distinguish different forms of identity.

At minimum:

```text
Semantic Identity
Content Identity
Operation Identity
Region Identity
```

These identities MUST NOT be conflated.

## 7.1 Semantic Identity

Semantic identity identifies a meaningful computational entity independent of a particular representation.

A semantic identity MAY be represented using established identity mechanisms such as URI/IRI.

The representation mechanism does not itself define the semantic identity.

## 7.2 Content Identity

Content identity identifies a representation or immutable content according to its content.

Content identity MAY use content-addressing mechanisms such as cryptographic hashes or multihash/CID systems.

Content identity MUST NOT automatically become semantic identity.

## 7.3 Operation Identity

Operation identity identifies a particular semantic operation or occurrence.

Operation identity is distinct from the operation's type.

## 7.4 Region Identity

A semantic region MAY itself be addressable.

A region identity identifies a semantic subgraph or other semantically bounded portion of a larger structure.

---

# 8. Types

Types classify semantic objects according to declared meaning and constraints.

A type MAY specify:

* allowed values;
* structural properties;
* operations;
* constraints;
* capabilities;
* relationships;
* equivalence rules;
* lifecycle properties.

A type MUST NOT be reduced to a programming-language type.

The following are distinct:

```text
Semantic Type
Programming Type
Storage Type
MLIR Type
Serialization Type
```

A semantic type MAY have multiple implementation representations.

---

# 9. Values

A value is semantically meaningful information associated with an object, operation, state, attribute, or other computational construct.

Values MAY be:

* scalar;
* composite;
* symbolic;
* structured;
* referenced;
* opaque;
* exact;
* approximate;
* probabilistic;
* uncertain;
* mutable through state;
* immutable.

Value semantics MUST be independent of their physical encoding.

---

# 10. Entities and Objects

An entity is a semantically identifiable object participating in a computational system.

Objects MAY possess:

* identity;
* type;
* attributes;
* state;
* relationships;
* capabilities;
* provenance;
* temporal context;
* causal context.

An object MAY represent:

* an abstract concept;
* a physical entity;
* a computational process;
* a data structure;
* a mathematical object;
* a field;
* a graph;
* a geometry;
* an agent;
* a simulation;
* a rendering resource;
* a transformation;
* another semantic object.

Core does not prescribe what kinds of entities exist within specialized domains.

---

# 11. Attributes

Attributes provide semantically associated properties of an object, relationship, operation, region, or other construct.

Attributes MAY themselves possess:

* types;
* values;
* provenance;
* temporal validity;
* uncertainty;
* constraints.

An attribute MUST NOT automatically be interpreted as mutable state.

The semantic contract determines whether an attribute is:

* intrinsic;
* derived;
* configurable;
* mutable;
* observational;
* contextual;
* implementation-specific.

---

# 12. Relationships

A relationship expresses a semantic connection between two or more computational entities.

Relationships MAY be:

* directed;
* undirected;
* typed;
* attributed;
* temporal;
* causal;
* conditional;
* weighted;
* ordered;
* contextual.

Relationships are first-class semantic objects where their identity or properties are semantically relevant.

---

# 13. Roles

A role describes the semantic participation of an entity in a relationship or operation.

For example:

```text
Relationship:
    interaction

Roles:
    source
    target
    mediator
    observer
```

Roles MUST be represented explicitly where replacing them with anonymous positional arguments would lose semantic meaning.

Roles are particularly important for hyperrelationships.

---

# 14. Semantic Hypergraph

The foundational relational structure of Core is a typed, attributed, role-labelled semantic hypergraph.

A hyperedge MAY connect an arbitrary number of participants through explicitly defined roles.

Conceptually:

```text
             ┌──────────────┐
             │  Hyperedge   │
             │  interaction │
             └──────┬───────┘
                    │
       ┌────────────┼────────────┐
       │            │            │
    source       target       context
       │            │            │
       ▼            ▼            ▼
   Entity A      Entity B      Entity C
```

A hyperedge MUST NOT be reduced to pairwise relationships when that reduction loses semantic information.

The Semantic Hypergraph is a Core abstraction.

Specialized graph domains MAY add graph-specific semantics without replacing the Core model.

---

# 15. Semantic Regions

A semantic region is an addressable, bounded portion of semantic structure.

A region MAY contain:

* entities;
* relationships;
* hyperedges;
* values;
* operations;
* transformations;
* state;
* provenance;
* nested regions.

Regions MAY overlap.

Regions MAY be nested.

Regions MAY be selected through semantic patterns.

A region MUST NOT be assumed to correspond to:

* a file;
* a database;
* a directory;
* a memory allocation;
* a network message;
* a process.

These may be representations or implementations of regions.

---

# 16. References

Core defines semantic references as indirections between semantic objects.

References MAY target:

* semantic identities;
* content identities;
* regions;
* patterns;
* operations;
* representations.

References SHOULD be resolvable through a runtime or environment abstraction.

Reference resolution MUST NOT require the Core semantic model to prescribe:

* filesystem layout;
* database technology;
* network protocol;
* storage engine;
* cloud service.

---

# 17. Representations

A representation is a concrete encoding or realization of semantic information.

Examples include:

* in-memory structures;
* MLIR;
* JSON;
* JSON-LD;
* CBOR;
* RDF;
* Arrow;
* Parquet;
* glTF;
* ONNX;
* binary encodings;
* GPU buffers.

The relationship is:

```text
Semantic Object
      │
      ├── Representation A
      ├── Representation B
      └── Representation C
```

A representation MUST NOT silently redefine the semantics of the object it represents.

---

# 18. Patterns

A pattern describes a semantic structure, condition, or arrangement that may be matched against computational state.

Patterns MAY describe:

* objects;
* attributes;
* relationships;
* hypergraphs;
* fields;
* geometry;
* morphology;
* operations;
* states;
* events;
* streams.

Patterns MAY be:

* exact;
* partial;
* approximate;
* structural;
* relational;
* temporal;
* spatial;
* probabilistic.

Patterns are first-class semantic constructs.

---

# 19. Transformations

A transformation maps one semantic representation or state into another.

Conceptually:

```text
Pattern / State / Representation
              │
              ▼
        Transformation
              │
              ▼
       Pattern / State / Representation
```

A transformation MAY:

* preserve identity;
* create identity;
* modify structure;
* modify state;
* change representation;
* change abstraction level;
* compose structures;
* decompose structures;
* specialize structures;
* canonicalize structures.

Transformations MUST declare or make inferable the semantic conditions under which they are valid.

---

# 20. Operations

An operation is a semantically defined computational action.

An operation MAY:

* consume values;
* produce values;
* inspect state;
* modify state;
* produce events;
* consume events;
* invoke transformations;
* interact with resources.

An operation MUST have defined:

* inputs;
* outputs;
* effects;
* constraints;
* error semantics;
* determinism semantics where applicable;
* temporal semantics where applicable;
* provenance requirements where applicable.

Operations are semantic constructs before they are implementation functions.

---

# 21. State

State is the semantically relevant condition of a computational system at a particular point or context.

State MAY include:

* values;
* relationships;
* structure;
* configuration;
* environmental conditions;
* resource state;
* temporal context;
* causal context.

State MUST be distinguished from representation.

A state MAY have many representations.

---

# 22. State Transition

A state transition describes semantic change from one state to another.

Conceptually:

```text
S₀
 │
 │ operation / event / transformation
 ▼
S₁
```

A transition MAY be:

* deterministic;
* stochastic;
* continuous;
* discrete;
* event-driven;
* externally induced;
* internally generated.

A state transition MUST preserve sufficient information to determine the semantics of the transition where required by the domain contract.

---

# 23. Deltas

A delta describes semantic change between states.

Conceptually:

```text
S₁ = S₀ ⊕ Δ
```

where `Δ` is a semantic change rather than necessarily a physical patch.

A delta MAY describe:

* creation;
* deletion;
* modification;
* relationship change;
* topology change;
* attribute change;
* structural change;
* temporal change.

Core MUST distinguish:

```text
Semantic Delta
Graph Delta
Representation Delta
Storage Delta
```

These MAY correspond to one another, but MUST NOT be assumed equivalent.

---

# 24. Events

An event represents a semantically significant occurrence.

Events MAY:

* describe state changes;
* trigger operations;
* represent observations;
* represent external interactions;
* represent lifecycle transitions.

An event MAY carry:

* identity;
* type;
* timestamp;
* causal predecessor;
* origin;
* payload;
* provenance;
* affected entities;
* affected regions.

Events MUST NOT be equated automatically with messages.

A message is a transport or communication construct.

An event is a semantic occurrence.

---

# 25. Streams

A stream is an ordered or partially ordered flow of semantic items over time.

Stream items MAY include:

* values;
* events;
* operations;
* deltas;
* observations;
* states;
* messages;
* transformations.

Stream semantics MAY include:

* ordering;
* timestamps;
* causality;
* windows;
* backpressure;
* completion;
* failure;
* replay;
* branching.

Transport mechanisms are implementation concerns.

---

# 26. Temporal Semantics

Core defines generic temporal concepts without imposing a single universal clock.

Relevant temporal dimensions MAY include:

* valid time;
* event time;
* observation time;
* processing time;
* simulation time;
* execution time;
* wall-clock time;
* evolutionary time.

These concepts MUST remain distinguishable where their meanings differ.

For example:

```text
Event Time
     ≠
Processing Time
     ≠
Simulation Time
     ≠
Wall Time
```

Specialized domains MAY introduce additional temporal semantics.

---

# 27. Causality

Causal context describes meaningful dependency or ordering between computational occurrences.

Causal information MAY include:

* predecessor relationships;
* dependency relationships;
* causal chains;
* operation ancestry;
* event ancestry;
* logical clocks;
* vector clocks;
* simulation causality.

Core does not prescribe a particular distributed-consistency model.

CRDT semantics, consensus mechanisms, and distributed transaction models belong to higher-level systems or implementation domains unless explicitly promoted into Core.

---

# 28. Provenance

Provenance describes the origin, derivation, transformation history, or authority associated with semantic information.

Provenance MAY identify:

* source;
* creator;
* operation;
* transformation;
* provider;
* representation;
* timestamp;
* environment;
* version;
* causal predecessor.

Provenance MUST be preservable across transformations where required by the semantic contract.

---

# 29. Constraints

A constraint defines a condition that must, may, or should hold.

Constraints MAY be:

* structural;
* semantic;
* temporal;
* spatial;
* numerical;
* relational;
* resource-related;
* safety-related;
* implementation-specific.

Core distinguishes:

```text
Constraint
    ≠
Objective
    ≠
Preference
    ≠
Optimization Criterion
```

Specialized domains MAY introduce domain-specific constraints.

---

# 30. Capabilities

A capability describes something that a semantic object, operation, provider, representation, or execution environment can do or support.

Examples include:

```text
Composable
Controllable
Deterministic
Differentiable
Distributable
Dynamical
Integrable
Learnable
Morphological
Observable
Optimizable
Parallelizable
Persistable
Reducible
Renderable
Serializable
Spatial
Stateful
Stateless
Stochastic
Streamable
Temporal
Tileable
Transformable
Vectorizable
```

Capabilities describe supported behavior.

They MUST NOT automatically define the complete semantics of an object.

---

# 31. Contracts

A contract defines the conditions under which a semantic object, operation, provider, or transformation is valid.

A contract MAY specify:

* inputs;
* outputs;
* invariants;
* preconditions;
* postconditions;
* effects;
* errors;
* capabilities;
* equivalence requirements;
* resource requirements;
* determinism;
* precision;
* temporal behavior.

Contracts are normative semantic boundaries.

---

# 32. Composition

Core defines composition as the construction of a larger semantic object or computation from smaller semantic components.

Composition MAY occur across:

* operations;
* transformations;
* graphs;
* hypergraphs;
* fields;
* streams;
* states;
* agents;
* domains.

Composition MUST preserve declared semantic contracts.

A composed object MAY acquire additional capabilities or constraints.

---

# 33. Equivalence

Core defines semantic equivalence as equivalence under a declared semantic relation.

Two implementations MUST NOT be considered equivalent merely because:

* they produce similar outputs in one example;
* they expose similar APIs;
* they use the same algorithm;
* they use the same representation;
* they have the same performance characteristics.

Equivalence MAY be:

* exact;
* observational;
* structural;
* behavioral;
* numerical within tolerance;
* representational;
* temporal;
* probabilistic;
* domain-specific.

The equivalence relation MUST be explicit or derivable from the applicable contract.

---

# 34. Queries

A query identifies, selects, evaluates, or compares semantic information.

Queries MAY operate over:

* objects;
* relationships;
* hypergraphs;
* regions;
* patterns;
* state;
* events;
* streams.

Core defines query semantics but does not prescribe a query language.

External query languages such as GQL, SPARQL, SQL, or domain-specific query languages MAY provide projections onto Core semantics.

---

# 35. Observations

An observation represents information obtained about a computational system, environment, state, or phenomenon.

Core MUST distinguish:

```text
State
    ≠
Observation
```

An observation may be:

* complete;
* partial;
* noisy;
* uncertain;
* delayed;
* sampled;
* derived.

The absence of an observation MUST NOT automatically imply the absence of the underlying phenomenon.

---

# 36. Resources

A resource is a constrained computational or physical capability required by an operation or execution.

Resources MAY include:

* memory;
* compute;
* storage;
* bandwidth;
* accelerator capacity;
* execution slots;
* energy;
* time.

Resource requirements SHOULD be expressed semantically where they affect provider selection or execution.

Core does not prescribe a specific scheduler.

---

# 37. Errors

Errors are semantically meaningful failures or exceptional conditions.

An error SHOULD identify:

* type;
* cause;
* affected operation;
* affected object or region;
* recoverability;
* provenance;
* temporal context where relevant.

Errors MAY be:

* validation failures;
* contract violations;
* unavailable resources;
* unsupported capabilities;
* invalid references;
* invalid state transitions;
* provider failures;
* representation failures.

An implementation-specific exception MUST NOT automatically become an SCR semantic error without an explicit mapping.

---

# 38. Determinism

Core defines determinism as a property of a semantic computation under explicitly declared conditions.

A computation MAY be:

* deterministic;
* nondeterministic;
* stochastic;
* conditionally deterministic;
* implementation-dependent.

Determinism MUST NOT be inferred solely from the implementation language or execution hardware.

---

# 39. Semantic Hypergraph Integration

All Core concepts MAY participate in the Semantic Hypergraph.

For example:

```text
          ┌────────────────────┐
          │ Transformation     │
          │ T                  │
          └─────────┬──────────┘
                    │
              transforms
                    │
          ┌─────────▼──────────┐
          │ Semantic Region    │
          │ R₁                 │
          └─────────┬──────────┘
                    │
                contains
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
     Entity A    Entity B    Entity C
        │           │           │
        └──────┬────┴────┬──────┘
               │         │
               ▼         ▼
          Relationship  Attribute
```

The graph itself is semantic structure.

Its physical storage is not part of Core.

---

# 40. Relationship to Data

Data specializes Core's concepts for meaningful information structures.

```text
Core
  ↓
Data
  ↓
Collections / Records / Datasets / Queries
```

Core defines:

* values;
* identity;
* relationships;
* state;
* regions;
* transformations.

Data defines how meaningful information is structured and manipulated as datasets and information structures.

---

# 41. Relationship to Mathematics

Mathematics specializes Core's concepts for mathematical objects and computation.

```text
Core
  ↓
Mathematics
  ↓
Numbers / Functions / Spaces / Operators / Equations
```

Mathematical semantics MUST NOT be reduced to numerical library implementations.

---

# 42. Relationship to Graphs

Graphs specializes Core's relational structures.

```text
Core Semantic Hypergraph
          ↓
       Graphs
          ↓
Graph-specific algorithms and semantics
```

The Graph domain MUST NOT replace Core's Semantic Hypergraph.

---

# 43. Relationship to Fields

Fields specializes Core's information and state structures into information distributed over domains.

```text
Core
  ↓
Data
  ↓
Fields
```

Fields MAY use:

* values;
* regions;
* relationships;
* temporal state;
* transformations;
* streams.

---

# 44. Relationship to Geometry and Topology

Geometry and Topology specialize Core structures for spatial form and structural continuity.

```text
Core
 ├── Geometry
 └── Topology
```

Geometry and topology are related but MUST remain semantically distinct.

---

# 45. Relationship to Morphology

Morphology specializes Core's concepts of structure, organization, pattern, transformation, and relationships.

Morphology may operate across:

* graphs;
* fields;
* topology;
* geometry;
* patterns.

Core provides the semantic substrate; Morphology defines the domain-specific meaning of structured form.

---

# 46. Relationship to Dynamics and Physics

Physics defines physical laws and physical quantities.

Dynamics defines general state evolution.

Core provides:

* state;
* transitions;
* operations;
* temporal semantics;
* causality;
* provenance.

Conceptually:

```text
Core
  │
  ├── Physics
  │
  └── Dynamics
          │
          ▼
      Simulation
```

---

# 47. Relationship to Agents

Agents specialize Core's concepts of:

* identity;
* state;
* observation;
* action;
* capability;
* interaction;
* adaptation.

Core does not require an agent to be biological, intelligent, neural, conscious, or autonomous.

---

# 48. Relationship to Neural Computation

Neural computation specializes:

* computation;
* state;
* relationships;
* transformations;
* learning;
* adaptation.

A neural network is one possible semantic structure within Core.

Core does not define neural computation.

---

# 49. Relationship to Rendering

Rendering specializes Core representations and transformations into visual or other perceptual manifestations.

Rendering MUST NOT redefine the semantic object being rendered.

Conceptually:

```text
Semantic State
      ↓
Rendering Representation
      ↓
Render Computation
      ↓
Physical / Visual Output
```

---

# 50. MLIR Representation

SCR Core semantics MUST be representable through MLIR where computational representation is required.

MLIR provides extensible operations, types, attributes, regions, and dialects, allowing domain-specific abstractions to coexist and be progressively lowered.

SCR SHOULD use MLIR mechanisms where they provide the required representation and transformation capabilities.

The relationship is:

```text
SCR Core Semantics
        ↓
SCR Core IR
        ↓
MLIR Representation
        ↓
MLIR Transformations
        ↓
Lowering
```

MLIR is an implementation substrate.

It is not the normative semantic definition of SCR Core.

---

# 51. Core IR

The Core domain SHOULD expose an intermediate representation for the fundamental semantic concepts defined here.

The Core IR MAY represent:

* identities;
* types;
* values;
* entities;
* relationships;
* roles;
* hyperedges;
* regions;
* references;
* representations;
* patterns;
* transformations;
* operations;
* state;
* deltas;
* events;
* streams;
* temporal information;
* causal information;
* provenance;
* capabilities;
* contracts.

The Core SCR Semantic MLIR SHOULD be sufficiently expressive to act as the semantic foundation for higher-level domain-specific MLIR dialects.

---

# 52. Core IR and MLIR Dialects

The Core IR may be realized as one or more MLIR dialects.

A dialect may define domain-specific:

* operations;
* types;
* attributes;
* interfaces;
* traits;
* verification rules.

MLIR explicitly supports application-specific semantics through extensible dialects, types, attributes, and operations.

Core SHOULD avoid duplicating mechanisms already provided by MLIR unless the duplication serves an explicit semantic purpose.

---

# 53. Interfaces

Core capabilities MAY be represented through interfaces.

MLIR interfaces provide an established mechanism for allowing transformations and analyses to operate against generic capabilities rather than hard-coding knowledge of specific operations or dialects.

SCR SHOULD therefore distinguish:

```text
Semantic Capability
        ↓
SCR Interface
        ↓
MLIR Interface
        ↓
Concrete Implementation
```

The MLIR interface is an implementation representation of the SCR capability, not necessarily the complete semantic contract.

---

# 54. Storage Independence

Core MUST NOT prescribe:

* filesystem storage;
* relational databases;
* graph databases;
* document databases;
* object stores;
* memory layouts;
* block storage;
* content-addressed storage;
* cloud storage.

Core MAY define semantic regions and references that storage systems subsequently realize.

---

# 55. Serialization Independence

Core MUST NOT prescribe:

* JSON;
* JSON-LD;
* CBOR;
* MessagePack;
* Protocol Buffers;
* FlatBuffers;
* Cap'n Proto;
* MLIR bytecode;
* custom binary formats.

These MAY represent Core structures.

---

# 56. Transport Independence

Core MUST NOT prescribe:

* HTTP;
* AMQP;
* Kafka;
* NATS;
* TCP;
* QUIC;
* WebSockets.

Messaging and transport systems belong to implementation or higher-level domains.

---

# 57. Execution Independence

Core semantics MUST remain independent of:

* CPU;
* GPU;
* NPU;
* FPGA;
* distributed clusters;
* WebAssembly;
* operating system;
* programming language;
* runtime;
* external library.

Execution environments MAY provide capabilities that influence provider selection.

---

# 58. Standards

SCR SHOULD reuse established open standards where an applicable standard exists and can represent the required semantics without unacceptable information loss.

Potential standards include:

* URI / IRI;
* JSON;
* JSON-LD;
* RDF;
* RDF-star;
* SHACL;
* ISO GQL;
* ISO 8601;
* RFC 3339;
* UCUM;
* OGC standards;
* EPSG references;
* established cryptographic and signature standards.

Standards provide interoperability mechanisms.

They do not automatically become SCR's semantic authority.

---

# 59. Capabilities

Core SHOULD expose generic capability concepts including, where applicable:

* composability;
* determinism;
* stochasticity;
* statefulness;
* statelessness;
* transformability;
* observability;
* streamability;
* temporal behavior;
* spatial behavior;
* differentiability;
* parallelizability;
* vectorizability;
* tileability;
* distributability;
* persistence;
* serialization;
* renderability.

Capabilities MAY be combined.

A capability does not imply a specific implementation.

---

# 60. Performance Semantics

Core semantics MUST distinguish correctness from performance.

Performance characteristics MAY include:

* complexity;
* latency;
* throughput;
* memory consumption;
* parallelism;
* locality;
* precision;
* numerical stability;
* accelerator suitability.

Performance MAY influence provider selection and transformation.

Performance MUST NOT silently change semantic meaning.

---

# 61. Numerical Semantics

Where Core concepts involve numerical values, the semantic contract SHOULD distinguish:

* exactness;
* approximation;
* precision;
* rounding;
* tolerance;
* overflow;
* underflow;
* undefined values;
* NaN semantics;
* stochastic error.

Numerical behavior MUST be explicit where it affects semantic equivalence.

---

# 62. Concurrency

Core operations MAY execute concurrently when their semantic dependencies permit.

Concurrency MUST NOT change semantic meaning unless nondeterminism is explicitly part of the contract.

Core MAY represent:

* independence;
* dependency;
* ordering;
* synchronization requirements;
* causal relationships.

The scheduler is an implementation concern.

---

# 63. Memory and Ownership

Core MUST NOT define programming-language ownership semantics as semantic meaning.

However, Core MAY define:

* lifetime;
* mutability;
* aliasing constraints;
* resource ownership;
* uniqueness requirements;
* transfer semantics.

These MAY subsequently map to Rust ownership, reference counting, borrowing, memory regions, or other implementation mechanisms.

---

# 64. Security and Isolation

Core MAY define semantic security properties such as:

* authorization requirements;
* provenance requirements;
* confidentiality classification;
* integrity requirements;
* isolation constraints.

Concrete mechanisms such as:

* capabilities;
* sandboxing;
* cryptographic signatures;
* process isolation;
* containers;
* WebAssembly;

belong to implementation layers unless explicitly elevated into a semantic contract.

---

# 65. Extensibility

Core MUST be extensible without requiring changes to every higher-level domain.

New semantic domains SHOULD be able to introduce:

* new types;
* new operations;
* new relationships;
* new capabilities;
* new constraints;
* new transformations.

Core SHOULD therefore define stable primitives rather than attempting to enumerate all possible computational concepts.

---

# 66. Versioning

Core semantic changes MUST be versioned.

Changes SHOULD distinguish:

### Additive

Adds new concepts without changing existing semantics.

### Compatible refinement

Clarifies or strengthens semantics without invalidating existing valid uses.

### Breaking

Changes the meaning, invariants, contracts, or compatibility requirements of an existing concept.

### Deprecated

Retains an existing concept while directing implementations toward a replacement.

Semantic versioning SHOULD be used for released Core contracts unless a more specific SCR versioning policy supersedes it.

---

# 67. Traceability

Every significant Core concept SHOULD be traceable through:

```text
Definition
    ↓
Semantic Contract
    ↓
IR Representation
    ↓
Tests
    ↓
Implementation
    ↓
Lowering
    ↓
Provider
```

No implementation SHOULD be treated as the sole evidence of semantic correctness.

---

# 68. Testing Requirements

Core MUST be tested at multiple levels.

## 68.1 Semantic Tests

Verify that the definition is internally coherent.

## 68.2 Invariant Tests

Verify Core invariants.

## 68.3 Unit Tests

Verify individual implementation components.

## 68.4 Composition Tests

Verify that Core primitives compose correctly.

## 68.5 IR Tests

Verify Core IR construction, verification, parsing, printing, and transformation.

## 68.6 Lowering Tests

Verify that Core IR can lower into appropriate MLIR representations without semantic loss.

## 68.7 Provider Tests

Verify provider implementations against Core contracts.

## 68.8 Equivalence Tests

Verify that alternative implementations satisfy declared equivalence relationships.

---

# 69. Core Invariants

## CORE-INV-001 — Semantic Primacy

Semantic definitions are authoritative over implementations.

## CORE-INV-002 — Identity Separation

Semantic identity, content identity, operation identity, and region identity MUST remain distinguishable.

## CORE-INV-003 — Representation Independence

Semantic meaning MUST NOT depend on a particular representation.

## CORE-INV-004 — Implementation Independence

Core semantics MUST NOT depend on a particular implementation language, library, runtime, or hardware substrate.

## CORE-INV-005 — Relationship Integrity

Relationships MUST preserve their declared participants, roles, direction, and semantics.

## CORE-INV-006 — Hyperedge Integrity

A semantically higher-order relationship MUST NOT be reduced to pairwise relationships when doing so loses meaning.

## CORE-INV-007 — Role Integrity

Semantic roles MUST remain explicit wherever role information contributes to meaning.

## CORE-INV-008 — Region Integrity

Semantic regions MUST remain distinguishable from physical storage boundaries.

## CORE-INV-009 — Reference Indirection

References MUST NOT require the Core model to prescribe a physical storage or transport mechanism.

## CORE-INV-010 — Operation Semantics

Operations MUST have explicit semantic contracts.

## CORE-INV-011 — State Distinction

State MUST remain distinct from its representation.

## CORE-INV-012 — Delta Distinction

Semantic deltas MUST remain distinguishable from representation or storage patches.

## CORE-INV-013 — Event Distinction

Events MUST remain distinct from transport messages.

## CORE-INV-014 — Temporal Explicitness

Distinct temporal meanings MUST NOT be silently conflated.

## CORE-INV-015 — Causal Explicitness

Causal relationships MUST remain distinguishable from simple temporal ordering.

## CORE-INV-016 — Provenance Preservation

Required provenance MUST survive semantic transformations.

## CORE-INV-017 — Contract Preservation

Composition and transformation MUST preserve applicable semantic contracts.

## CORE-INV-018 — Equivalence Discipline

Semantic equivalence MUST be established under an explicit relation.

## CORE-INV-019 — Provider Independence

Providers MUST NOT silently redefine Core semantics.

## CORE-INV-020 — Domain Independence

Core MUST remain independent of specialized semantic domains.

---

# 70. Function-Level Requirements

Core functionality SHOULD be decomposed into functions such as:

```text
identity.create
identity.resolve
identity.compare

type.define
type.validate
type.compatible

value.create
value.validate
value.compare

entity.create
entity.identify
entity.attribute

relationship.create
relationship.connect
relationship.disconnect
relationship.role

hyperedge.create
hyperedge.participant
hyperedge.role

region.create
region.select
region.contains

reference.create
reference.resolve

representation.create
representation.convert

pattern.create
pattern.match

transformation.create
transformation.apply

operation.define
operation.execute
operation.validate

state.create
state.observe
state.transition

delta.compute
delta.apply
delta.compose

event.create
event.emit

stream.create
stream.subscribe
stream.transform

temporal.compare
temporal.order

causal.link
causal.predecessors

provenance.record
provenance.trace

constraint.validate

capability.query
capability.require

contract.validate
contract.compose

equivalence.compare

query.select
query.evaluate

observation.record

resource.require
resource.release

error.create
error.classify
```

These names are conceptual requirements and are not necessarily final API names.

---

# 71. Completeness Criteria

The Core definition is incomplete unless it establishes:

* semantic identity;
* type semantics;
* value semantics;
* entity semantics;
* relationship semantics;
* role semantics;
* hypergraph semantics;
* region semantics;
* reference semantics;
* representation independence;
* pattern semantics;
* transformation semantics;
* operation semantics;
* state semantics;
* delta semantics;
* event semantics;
* stream semantics;
* temporal semantics;
* causal semantics;
* provenance;
* constraints;
* capabilities;
* contracts;
* composition;
* equivalence;
* queries;
* observations;
* resources;
* errors;
* extensibility;
* versioning;
* testing;
* implementation independence;
* MLIR representation;
* provider independence.

---

# 72. Architectural Rules

### Rule 1 — Core Is Foundational

Higher-level semantic domains MAY depend on Core.

Core MUST NOT semantically depend on them.

### Rule 2 — Semantics Before Representation

A representation MUST derive from semantic meaning.

### Rule 3 — Meaning Before Implementation

An implementation MUST realize an established semantic contract.

### Rule 4 — Providers Are Replaceable

Providers SHOULD be replaceable when semantic equivalence permits.

### Rule 5 — Standards Are Interoperability Mechanisms

Standards SHOULD be reused where appropriate without surrendering semantic authority.

### Rule 6 — MLIR Is the Compiler Substrate

SCR SHOULD use MLIR rather than recreate equivalent compiler infrastructure.

### Rule 7 — Storage Is Not Semantics

Core MUST NOT prescribe storage.

### Rule 8 — Transport Is Not Semantics

Core MUST NOT prescribe transport.

### Rule 9 — Hardware Is Not Semantics

Hardware characteristics MAY affect execution but MUST NOT redefine semantic meaning.

### Rule 10 — Graph Structure Is Semantic

Relationships and higher-order relationships MAY themselves carry computational meaning.

### Rule 11 — History Is Semantic When Declared

Operations, events, deltas, temporal relationships, and provenance MAY constitute semantic information.

### Rule 12 — Implementation Does Not Prove Semantics

Passing implementation tests does not, by itself, prove that the implementation satisfies the semantic definition.

---

# 73. Relationship Vocabulary

Core SHOULD use the controlled semantic relationship vocabulary:

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

The distinction between semantic relationships and implementation dependencies MUST be preserved.

---

# 74. Expected Core Subdomains

The Core implementation MAY eventually contain:

```text
Core/
├── identity
├── type
├── value
├── entity
├── object
├── relationship
├── hypergraph
├── role
├── attribute
├── region
├── reference
├── representation
├── pattern
├── transformation
├── operation
├── state
├── delta
├── event
├── stream
├── temporal
├── causal
├── provenance
├── constraint
├── capability
├── contract
├── equivalence
├── query
├── observation
├── resource
└── error
```

This list is architectural guidance rather than a requirement that every item immediately exist as a filesystem directory.

---

# 75. Core and the Semantic Library Control Plane

The Core definition is normative.

Its engineering status belongs in:

```text
102_status.yaml
```

Its relationships to other library domains belong in the derived:

```text
103_library.graph.json
```

The roles are therefore:

```text
101_definition.md
    = What Core means

102_status.yaml
    = Where Core implementation stands

103_library.graph.json
    = How Core relates to the rest of SCR
```

The graph MUST NOT override the definition.

The implementation MUST NOT override the definition.

---

# 76. Open Semantic Questions

The following questions remain subject to explicit future decisions:

1. What is the canonical SCR representation of semantic identity?
2. How should identity persistence across transformations be formally expressed?
3. What is the minimal canonical representation of a semantic hyperedge?
4. How should semantic regions be formally addressed?
5. What is the canonical operation model?
6. What is the canonical delta algebra?
7. How should causal metadata be represented?
8. What level of temporal semantics belongs in Core?
9. Which capabilities should be Core interfaces versus domain interfaces?
10. What constitutes semantic equivalence across heterogeneous providers?
11. What parts of the Core IR should become MLIR dialects?
12. Which Core concepts require custom MLIR types?
13. Which Core concepts are better represented using MLIR attributes?
14. Which Core operations require custom verification?
15. Which semantics require custom MLIR interfaces?
16. How should semantic references be resolved by the runtime?
17. How should semantic provenance survive lowering?
18. What is the minimum Core IR required before domain-specific IRs are introduced?
19. Which Core concepts should be executable versus descriptive?
20. How should Core support distributed semantic state without prematurely selecting a consistency model?

These questions MUST be resolved through explicit semantic design rather than implementation convenience.

---

# 77. Definition Authority

This document is the normative semantic definition of:

```text
SCR-LIB-CORE
```

Where implementation behavior conflicts with this document, the implementation is incorrect unless this definition is explicitly revised.

Where a child domain conflicts with Core, the conflict MUST be resolved through explicit refinement or correction.

Where an external implementation conflicts with Core, the external implementation MUST NOT be treated as authoritative.

---

# 78. Definition Principle

> **The code is not the architecture.**

For Core specifically:

```text
Specification ≠ Implementation
Status ≠ Specification
Graph ≠ Source of Truth
Provider ≠ Semantic Authority
Backend ≠ Semantic Meaning
Representation ≠ Concept
Storage ≠ State
Transport ≠ Event
Hardware ≠ Semantics
```

Core exists to establish the semantic foundation from which these distinctions remain possible.

---

# 79. Final Principle

> **SCR Core defines the semantic substrate through which computational meaning can exist, be identified, related, represented, transformed, observed, constrained, and evolved.**

It defines neither the storage mechanism nor the execution mechanism by which that meaning is realized.

Every higher-level SCR domain MUST be expressible in terms of this substrate without requiring Core to know the domain-specific laws that it introduces.

That is the fundamental purpose of Core.
