# SCR Semantic Library — 802 Stream

**Document:** `lib/802_Stream/101_definition.md`
**Version:** `0.2.0`
**Status:** Draft — normative semantic definition
**Domain:** Stream
**Parent:** None
**Authority:** Semantic Computational Runtime (SCR)

---

# 1. Definition

A **Stream** is a semantic structure describing the ordered, partially ordered, causal, continuous, or discrete evolution and/or availability of information, state, occurrences, observations, operations, transformations, or other semantic elements across a domain.

A Stream is therefore concerned with **how semantic elements become available, evolve, relate, and may be consumed over a temporal, causal, spatial, computational, or other ordered domain**.

A Stream is **not inherently**:

* a transport;
* a network connection;
* a message broker;
* a queue;
* a buffer;
* a pipeline;
* a file;
* a protocol;
* a thread;
* a process;
* a scheduler;
* a rendering mechanism;
* a storage mechanism;
* a particular execution framework.

A Stream may be realized by any of these mechanisms, but none defines the semantic concept of Stream.

A Stream may exist as a historical, replayable, materialized, latent, inactive, or otherwise non-flowing semantic structure. Therefore, **physical flow is not a necessary condition for Stream existence**.

---

# 2. Fundamental Distinction

The fundamental distinction is:

> **A Stream represents semantic elements together with their evolution, occurrence, availability, and relationships across an ordered or causal domain.**

The minimum conceptual structure is:

```text
Element
   │
   ├── Occurrence
   │
   ├── Availability
   │
   ├── Temporal relationship
   │
   ├── Ordering relationship
   │
   └── Causal relationship
```

A Stream therefore cannot be reduced to a collection of elements.

A collection answers:

> What elements exist?

A Stream additionally answers:

> How do those elements become available, evolve, relate, or succeed one another?

---

# 3. Stream Primacy

Stream is a semantic domain concerned with **evolution and availability**.

It is therefore orthogonal to the Data domain.

```text
Data
  = what information exists

Stream
  = how information/state evolves or becomes available
```

The same semantic data may participate in:

* a static structure;
* a state stream;
* an event stream;
* a delta stream;
* an observation stream;
* an operation stream;
* a spatial stream;
* a temporal stream;
* a distributed stream.

Stream does not own the underlying meaning of the streamed entity.

---

# 4. Stream Model

A Stream may be represented conceptually as:

```text
S = (
    Identity,
    Elements,
    Occurrences,
    Availability,
    TemporalSemantics,
    Ordering,
    Causality,
    Continuity,
    State,
    Transformation,
    Composition,
    Lifecycle,
    Provenance,
    Completeness,
    Loss,
    Equivalence
)
```

This is a semantic model rather than a required implementation representation.

Execution concerns such as transport, buffering, scheduling, partitioning, delivery mechanisms, and resource allocation belong to the realization of the Stream.

---

# 5. Element

A **Stream Element** is a semantic entity participating in a Stream.

Examples include:

* data;
* state;
* state transition;
* event;
* observation;
* action;
* operation;
* transformation;
* message;
* measurement;
* field state;
* graph mutation;
* simulation state;
* rendering observation.

An element retains its semantic identity independently of the mechanism used to transport or store it.

---

# 6. Occurrence

An **Occurrence** represents the fact that some semantic phenomenon, transition, operation, or other event has occurred.

Occurrence is distinct from:

* observation;
* publication;
* processing;
* consumption.

For example:

```text
Phenomenon occurs       t₁
        │
        ▼
Observation obtained   t₂
        │
        ▼
Published              t₃
        │
        ▼
Processed              t₄
        │
        ▼
Consumed               t₅
```

These are potentially distinct semantic facts.

A Stream may contain representations of one or more of these stages, but they must not be conflated.

---

# 7. Availability

**Availability** describes when and under what conditions a semantic element can be obtained by an observer, consumer, process, or computational entity.

Availability is relative to a participant or execution context.

Therefore:

```text
Occurred ≠ Observed
Observed ≠ Available
Available ≠ Published
Published ≠ Consumed
Consumed ≠ Semantically Applied
```

An element may exist without currently being available.

Absence of availability does not establish absence of the underlying phenomenon.

---

# 8. Temporal Semantics

Streams may possess one or more temporal dimensions.

Examples include:

* occurrence time;
* observation time;
* publication time;
* processing time;
* consumption time;
* logical time;
* simulation time;
* physical time;
* execution time.

A Stream MUST NOT assume that one temporal coordinate is universally authoritative.

Multiple clocks may coexist.

Where temporal ordering is defined, the Stream MUST specify which temporal relation is authoritative for the relevant operation.

---

# 9. Ordering

A Stream may define:

* total ordering;
* partial ordering;
* causal ordering;
* logical ordering;
* temporal ordering;
* spatial ordering;
* deterministic ordering;
* implementation-defined ordering;
* unordered availability.

Ordering is a semantic property and MUST NOT be inferred solely from transport arrival order.

For example:

```text
A → B
```

may indicate:

* temporal precedence;
* causal precedence;
* dependency;
* sequence position;

and these meanings MUST NOT be conflated.

---

# 10. Causality

Causality describes dependency between semantic occurrences or state transitions.

Causal precedence is distinct from temporal precedence.

It is possible for:

```text
A occurs before B
```

without:

```text
A causes B
```

Conversely, a causal relationship may exist across different physical or logical clocks.

Distributed Streams SHOULD preserve causal information where required by the semantic contract.

---

# 11. Continuity and Discreteness

Streams may be:

* continuous;
* discrete;
* sampled;
* event-driven;
* state-driven;
* hybrid.

A continuous Stream may be represented discretely without becoming semantically discrete.

Similarly, a discrete Stream may be embedded within a continuous domain.

Representation frequency MUST NOT be confused with semantic continuity.

---

# 12. State Streams

A **State Stream** represents successive semantic states.

For example:

```text
F₀ → F₁ → F₂ → F₃
```

Each element represents a state or state snapshot.

A State Stream MUST define whether successive states are:

* complete;
* partial;
* incremental;
* independently interpretable;
* dependent upon previous states.

---

# 13. Event Streams

An **Event Stream** represents occurrences.

```text
E₁ → E₂ → E₃
```

An Event represents an occurrence rather than a persistent state.

An event does not inherently imply:

* persistence;
* replayability;
* causality;
* ordering;
* successful processing.

These properties require explicit semantic definition.

---

# 14. Delta Streams

A **Delta Stream** represents changes or transformations relative to another semantic state.

```text
Δ₁ → Δ₂ → Δ₃
```

A Delta Stream MUST define the state against which each delta is interpreted.

A Delta Stream is not automatically equivalent to a State Stream.

Equivalence requires a valid state-transition reconstruction contract:

```text
Fₙ₊₁ = Apply(Fₙ, Δₙ)
```

---

# 15. Observation Streams

An **Observation Stream** represents information acquired or made available by an observing entity.

Observation is distinct from the phenomenon being observed.

Therefore:

```text
Phenomenon ≠ Observation
```

An Observation Stream may contain:

* measurements;
* sensor observations;
* perceptual results;
* telemetry;
* sampled fields;
* inferred observations.

Observation semantics MUST preserve provenance and uncertainty where relevant.

---

# 16. Operation Streams

An **Operation Stream** represents semantic operations or invocations.

Examples include:

* function invocation;
* command execution;
* transformation;
* workflow operation;
* agent action.

Operation occurrence MUST be distinguished from operation completion and operation effect.

```text
Invocation
   ↓
Execution
   ↓
Completion
   ↓
Effect
```

These are distinct semantic states.

---

# 17. Stream Lifecycle

A Stream has a semantic lifecycle.

Possible lifecycle states include:

```text
Created
Inactive
Active
Suspended
Resumed
Completed
Closed
Invalidated
```

The exact lifecycle is determined by the Stream contract.

The following distinctions MUST remain meaningful:

```text
Empty
≠
Inactive
≠
Temporarily silent
≠
Unavailable
≠
Completed
≠
Closed
```

An empty Stream contains no elements.

An inactive Stream may contain no currently available elements while remaining capable of future activation.

A completed Stream cannot produce further valid elements under its contract.

---

# 18. Sources and Consumers

A **Source** is a semantic participant that makes Stream elements available.

A **Consumer** is a semantic participant that obtains or processes Stream elements.

A source does not necessarily imply:

* a network connection;
* a thread;
* a device;
* a process.

A consumer does not necessarily imply:

* destruction of the element;
* acknowledgement;
* successful processing;
* semantic application.

---

# 19. Composition

Streams may be composed.

Composition may include:

* concatenation;
* merging;
* branching;
* joining;
* filtering;
* mapping;
* projection;
* correlation;
* synchronization;
* temporal alignment;
* causal alignment;
* feedback.

Composition MUST preserve the semantic identity and provenance of participating elements where required.

---

# 20. Transformation

A Stream transformation maps one semantic Stream representation to another.

Conceptually:

```text
S₁ ──T──> S₂
```

A transformation MUST define:

* inputs;
* outputs;
* semantic preconditions;
* semantic postconditions;
* ordering effects;
* temporal effects;
* state effects;
* provenance;
* failure semantics.

Transformations may be:

* stateless;
* stateful;
* deterministic;
* nondeterministic;
* approximate;
* learned;
* adaptive.

---

# 21. Stateful Transformation

A stateful transformation maintains semantic state across multiple Stream elements.

For example:

```text
(Sₙ, Eₙ) → (Sₙ₊₁, Oₙ)
```

The transformation MUST define:

* state identity;
* state lifetime;
* initialization;
* transition semantics;
* persistence requirements;
* checkpoint requirements;
* recovery semantics.

Execution memory MUST NOT automatically be interpreted as semantic state.

---

# 22. Feedback

A Stream may participate in a feedback relationship.

```text
S₁ → Transformation → S₂
       ↑             │
       └─────────────┘
```

Feedback may be:

* control feedback;
* state feedback;
* observation feedback;
* adaptive feedback;
* physical feedback;
* simulation feedback.

Feedback relationships MUST preserve causal semantics.

---

# 23. Windows

A **Window** defines a semantic subset of a Stream over some criterion.

Window criteria may include:

* temporal interval;
* element count;
* spatial region;
* causal boundary;
* state condition;
* semantic predicate.

A window is not inherently a buffer.

A runtime may implement a semantic window using a buffer, cache, index, or other mechanism.

---

# 24. Sampling

Sampling maps a Stream into a representation with reduced or altered observation frequency.

Sampling MUST distinguish:

```text
Semantic phenomenon
        ↓
Sampling
        ↓
Observed representation
```

Sampling may introduce:

* aliasing;
* omission;
* delay;
* approximation;
* uncertainty.

A sampled Stream MUST NOT automatically be treated as semantically complete.

---

# 25. Loss and Completeness

A Stream may be:

* complete;
* incomplete;
* lossy;
* lossless;
* selectively lossy;
* best effort;
* approximate.

The Stream contract MUST define what constitutes completeness where completeness is required.

Absence of an element MUST NOT automatically mean:

```text
element did not exist
```

It may instead mean:

* not observed;
* not available;
* filtered;
* dropped;
* superseded;
* withdrawn;
* unavailable;
* not yet received.

---

# 26. Delivery Semantics

Delivery semantics concern realization of Stream elements to consumers.

Possible properties include:

* at-most-once delivery;
* at-least-once delivery;
* duplicate delivery;
* ordered delivery;
* unordered delivery;
* replayable delivery.

These are not themselves the fundamental semantics of Stream.

In particular:

```text
Delivered once
≠
Executed once
≠
Effect applied once
```

A system may provide duplicate delivery while maintaining exactly-once semantic effect through idempotence or identity-aware application.

---

# 27. Idempotence

An operation is semantically idempotent when repeated application under the relevant contract produces an equivalent semantic result.

Idempotence may therefore compensate for duplicate delivery without requiring the transport itself to provide exactly-once delivery.

Exactly-once semantics MUST specify which layer guarantees exactly-once behavior.

---

# 28. Replay

A Stream MAY be replayable.

Replay requires semantic identity and ordering sufficient to reconstruct the intended Stream history.

Replay MUST distinguish:

```text
Historical occurrence
```

from:

```text
New occurrence caused by replay
```

Replay of an operation Stream MUST NOT automatically imply repetition of externally observable side effects.

Side-effect replay requires an explicit execution contract.

---

# 29. Checkpointing

Checkpointing captures sufficient semantic or execution state to resume Stream processing.

A checkpoint MAY include:

* Stream position;
* causal position;
* temporal position;
* transformation state;
* semantic state;
* provider execution state;
* resource state.

Checkpoint identity MUST be distinguishable from Stream element identity.

---

# 30. Provenance

Stream elements SHOULD preserve provenance sufficient to establish:

* origin;
* transformation history;
* temporal context;
* causal context;
* observation context;
* provider involvement;
* semantic authority;
* identity.

Provenance MUST NOT be replaced by transport metadata when transport metadata is insufficient to establish semantic origin.

---

# 31. Identity and References

Stream elements participate in SCR identity and reference semantics.

An element reference MUST remain distinguishable from the element itself.

A reference may remain meaningful when:

* the element is unavailable;
* the element has moved;
* the element has been superseded;
* the element has been deleted.

Reference validity and element availability are separate properties.

---

# 32. Deletion, Withdrawal and Supersession

The following states MUST remain semantically distinguishable where applicable:

```text
Never existed
Unavailable
Withdrawn
Deleted
Invalidated
Superseded
Expired
Temporarily unavailable
```

A deletion event does not necessarily erase the historical fact that an element previously existed.

Historical Streams MAY retain references and provenance to deleted semantic entities.

---

# 33. Nullary Relations

A Stream MUST support semantic elements or occurrences involving nullary relations where defined by the Core relational model.

A nullary relation has zero participants but remains a valid semantic relation.

Stream implementations MUST NOT assume that every streamed relation has one or more explicit endpoints.

This is particularly important for:

* facts;
* assertions;
* global state transitions;
* system conditions;
* existence predicates;
* events without explicit participants.

---

# 34. Distributed Streams

A distributed Stream may span:

* processes;
* machines;
* computational Spaces;
* networks;
* accelerators;
* providers;
* geographic locations.

Distribution MUST NOT alter the semantic identity of the Stream.

Physical partitioning is an implementation concern unless explicitly promoted into semantic meaning.

---

# 35. Spatial Streams

A Stream may evolve across spatial domains.

Examples include:

* particle movement;
* spatial field updates;
* voxel changes;
* geographic observations;
* simulation state;
* distributed spatial computation.

Spatial ordering MUST remain distinct from temporal ordering unless the semantic contract explicitly relates them.

---

# 36. Temporal Streams

A Temporal Stream explicitly represents evolution across a temporal domain.

Temporal semantics may be:

* physical;
* simulated;
* logical;
* computational;
* relative;
* discrete;
* continuous.

A simulation-time Stream MUST NOT be assumed to represent physical time.

---

# 37. Field Streams

A Field may be observed or evolved through a Stream.

For example:

```text
Field₀
  ↓
Field₁
  ↓
Field₂
```

or:

```text
ΔField₁
ΔField₂
ΔField₃
```

Field Streams MUST preserve the semantic distinction between:

* field state;
* field observation;
* field transformation;
* field rendering.

---

# 38. Graph and Hypergraph Streams

A Stream may represent evolution of graph or hypergraph state.

Examples include:

```text
Node creation
Relation creation
Relation deletion
Attribute mutation
State transition
```

Stream topology MUST NOT become a competing authoritative graph representation.

The canonical SCR semantic hypergraph remains authoritative.

A Stream is a semantic projection, evolution, or realization of that hypergraph where applicable.

---

# 39. Interaction and Perception Integration

Stream integrates naturally with Interaction and Perception.

For example:

```text
Input
  ↓
Observation
  ↓
Perception
  ↓
Gesture / Interpretation
  ↓
Intent
  ↓
Action
  ↓
Semantic Field
  ↓
Observation
```

Each stage remains semantically distinct.

A Stream may represent any of these transitions, but Stream does not own their underlying semantics.

---

# 40. Semantic Hypergraph Integration

Every Stream MUST be representable within the canonical SCR semantic hypergraph.

Stream relationships are therefore semantic relationships, not merely implementation topology.

The semantic hypergraph may represent:

* Stream identity;
* element membership;
* ordering;
* causal relationships;
* transformation;
* provenance;
* state;
* lifecycle;
* references;
* composition.

Stream-specific indexing or execution structures MUST NOT supersede the canonical semantic representation.

---

# 41. Execution Realization

A semantic Stream may be realized through:

* memory;
* files;
* shared memory;
* queues;
* brokers;
* sockets;
* network protocols;
* GPU memory;
* RDMA;
* IPC;
* distributed storage;
* event logs;
* database change feeds;
* simulation engines;
* runtime channels.

These are implementation mechanisms.

The semantic Stream MUST remain independent of any particular realization.

---

# 42. Transport

Transport provides a mechanism for moving or exposing Stream representations between computational entities.

Transport is therefore downstream of Stream semantics.

```text
Semantic Stream
      ↓
Semantic Contract
      ↓
Transport Realization
```

A transport MUST NOT define the semantic ontology of Stream.

---

# 43. Buffering

Buffering is an execution mechanism for temporarily retaining Stream elements.

A buffer may support:

* latency management;
* burst absorption;
* ordering;
* replay;
* flow control;
* resource management.

A buffer is not itself a Stream.

---

# 44. Flow Control and Backpressure

Flow control governs the rate or quantity at which Stream elements are processed or transferred.

Backpressure is an execution strategy for communicating downstream capacity constraints upstream.

Backpressure therefore belongs to Stream realization rather than fundamental Stream semantics.

Where resource limitations alter semantic behavior, those effects MUST be explicitly represented in the relevant execution contract.

---

# 45. Partitioning and Scheduling

A Stream MAY be partitioned for execution.

Partitioning may occur by:

* identity;
* key;
* spatial region;
* temporal interval;
* topology;
* resource;
* processor;
* accelerator.

Scheduling determines when execution occurs.

Neither partitioning nor scheduling changes semantic Stream identity unless explicitly defined by the semantic contract.

---

# 46. AMQP Relationship

AMQP is a messaging protocol and execution/transport mechanism.

It may realize Stream semantics but does not define them.

The relationship is therefore:

```text
                 SCR Stream
                      │
              Semantic Contract
                      │
             ┌────────┴────────┐
             │                 │
          HyrxMQ            RabbitMQ
          Provider           Provider
             │                 │
            AMQP              AMQP
```

HyrxMQ-specific capabilities such as:

* GPU-resident messages;
* GPU-to-GPU transfer;
* neural-network messaging;
* accelerator-aware routing;

are implementation capabilities.

They MUST NOT be incorporated into the fundamental definition of Stream.

---

# 47. Provider Boundary

Providers are outside the semantic library.

Providers implement or expose capabilities satisfying semantic contracts.

Therefore:

```text
lib/
    semantic meaning

providers/
    concrete implementations

runtime/
    executable infrastructure
```

A provider MAY implement:

* transport;
* buffering;
* serialization;
* distributed execution;
* stream processing;
* persistence;
* accelerator transfer.

The semantic Stream remains provider-independent.

Provider-specific concepts MUST NOT leak into the Stream ontology unless explicitly promoted through the semantic promotion process.

---

# 48. Representation Independence

The same semantic Stream MAY be represented as:

* MLIR;
* Mojo structures;
* in-memory objects;
* serialized records;
* AMQP messages;
* GPU-resident buffers;
* database records;
* event logs;
* files;
* network traffic;
* provider-specific structures.

Representation equivalence MUST be established semantically rather than assumed from structural similarity.

---

# 49. MLIR Representation

MLIR may represent Stream semantics through appropriate operations, types, attributes, regions, effects, or dialect constructs.

MLIR is an implementation and compilation substrate.

The Stream semantic definition MUST remain independent of the syntax of any particular MLIR dialect.

---

# 50. Runtime Semantics

Runtime systems MAY provide:

* scheduling;
* execution;
* buffering;
* transport;
* persistence;
* checkpointing;
* replay;
* resource management;
* provider resolution;
* failure recovery.

Runtime behavior MUST conform to the semantic contract associated with the Stream.

---

# 51. Failure Semantics

Stream failure MUST distinguish among relevant conditions including:

* source failure;
* transport failure;
* consumer failure;
* provider failure;
* timeout;
* unavailable element;
* lost element;
* malformed element;
* semantic invalidity;
* transformation failure;
* resource exhaustion;
* cancellation;
* termination.

Failure MUST NOT silently become semantic absence.

For example:

```text
Element lost
≠
Element never existed
```

unless the Stream contract explicitly defines such equivalence.

---

# 52. Semantic Equivalence

Two Stream realizations are semantically equivalent only when they preserve the properties required by their semantic contract.

Equivalence may require preservation of:

* element identity;
* ordering;
* causal relationships;
* temporal semantics;
* state transitions;
* provenance;
* completeness;
* lifecycle;
* effects.

Numerical, structural, or transport-level similarity is insufficient to establish semantic equivalence.

---

# 53. Stream Capabilities

A Stream MAY declare capabilities such as:

* ordered;
* causally ordered;
* replayable;
* persistent;
* lossless;
* complete;
* deterministic;
* real-time;
* continuous;
* distributed;
* transactional;
* checkpointable;
* reversible;
* observable;
* append-only.

Capabilities are properties of a Stream contract and MUST NOT be inferred merely from implementation technology.

---

# 54. Determinism

A Stream may be:

* deterministic;
* nondeterministic;
* probabilistic;
* adaptive.

Determinism MUST be specified relative to the relevant inputs, state, temporal model, provider, and execution environment.

A deterministic transport does not imply deterministic Stream semantics.

---

# 55. Approximation

A Stream may contain approximate or inferred information.

Approximation MUST preserve sufficient provenance and uncertainty semantics where required.

Examples include:

* sampled streams;
* estimated measurements;
* learned predictions;
* reduced-order simulation;
* lossy compression;
* perceptual streams.

Approximation does not automatically invalidate Stream semantics.

---

# 56. Semantic Completeness

A Stream contract SHOULD state whether it is intended to represent:

* all relevant elements;
* a filtered subset;
* a sampled subset;
* an estimated subset;
* a best-effort subset;
* a causally complete history;
* a temporally complete history.

Consumers MUST NOT infer completeness from successful receipt alone.

---

# 57. Semantic Authority

The canonical semantic authority for Stream is the SCR semantic hypergraph and associated semantic contracts.

The following MUST NOT become competing authorities:

* message queues;
* broker topology;
* transport topology;
* execution graphs;
* framework pipelines;
* runtime object graphs;
* provider-specific graph structures.

These are realizations or projections.

---

# 58. Architectural Invariants

The following invariants are normative.

### STREAM-INV-001 — Semantic Independence

Stream semantics MUST NOT depend on a particular transport, broker, runtime, or provider.

### STREAM-INV-002 — Flow Independence

A Stream MUST NOT require physical movement or active flow to exist semantically.

### STREAM-INV-003 — Element Identity

Stream elements MUST retain semantic identity independent of representation.

### STREAM-INV-004 — Occurrence Distinction

Occurrence MUST remain distinguishable from observation, publication, processing, and consumption.

### STREAM-INV-005 — Availability Distinction

Availability MUST remain distinguishable from existence and occurrence.

### STREAM-INV-006 — Temporal Explicitness

Temporal semantics MUST identify the relevant temporal reference.

### STREAM-INV-007 — Ordering Explicitness

Ordering MUST NOT be inferred from transport order without semantic justification.

### STREAM-INV-008 — Causal Distinction

Causality MUST remain distinct from temporal ordering.

### STREAM-INV-009 — State/Delta Distinction

State Streams and Delta Streams MUST NOT be considered equivalent without a valid reconstruction contract.

### STREAM-INV-010 — Event/State Distinction

Events MUST NOT be treated as states without explicit semantic interpretation.

### STREAM-INV-011 — Observation Distinction

Observation MUST remain distinct from the phenomenon being observed.

### STREAM-INV-012 — Lifecycle Explicitness

Inactive, empty, unavailable, completed, and closed states MUST remain distinguishable where relevant.

### STREAM-INV-013 — Absence Semantics

Absence of an available element MUST NOT automatically imply absence of the underlying phenomenon.

### STREAM-INV-014 — Provenance

Required provenance MUST survive valid Stream transformations.

### STREAM-INV-015 — Identity/Reference Separation

References MUST remain distinguishable from referenced entities.

### STREAM-INV-016 — Deletion Semantics

Deletion, withdrawal, invalidation, supersession, and unavailability MUST remain distinguishable where required.

### STREAM-INV-017 — Nullary Relations

Stream semantics MUST support nullary semantic relations.

### STREAM-INV-018 — Hypergraph Authority

Stream topology MUST NOT supersede the canonical SCR semantic hypergraph.

### STREAM-INV-019 — Provider Independence

Providers MUST remain implementation mechanisms rather than semantic authorities.

### STREAM-INV-020 — Delivery Distinction

Delivery, execution, and semantic effect MUST remain distinguishable.

### STREAM-INV-021 — Replay Safety

Replay MUST distinguish historical occurrences from newly generated side effects.

### STREAM-INV-022 — Failure Distinction

Execution failure MUST NOT silently become semantic absence.

### STREAM-INV-023 — Representation Independence

Equivalent semantic Streams MAY have different representations.

### STREAM-INV-024 — Transformation Contract

Stream transformations MUST define their semantic effects.

### STREAM-INV-025 — Causal Integrity

Transformations MUST NOT silently destroy required causal relationships.

### STREAM-INV-026 — Temporal Integrity

Transformations MUST NOT silently alter authoritative temporal semantics.

### STREAM-INV-027 — Completeness Explicitness

Completeness MUST be an explicit semantic property.

### STREAM-INV-028 — Loss Explicitness

Loss MUST be distinguishable from intentional filtering or semantic absence.

### STREAM-INV-029 — Semantic Equivalence

Provider substitution MUST preserve required Stream invariants rather than merely implementation behavior.

### STREAM-INV-030 — Runtime Subordination

Runtime execution mechanisms MUST conform to Stream semantics rather than redefine them.

---

# 59. Architectural Rules

1. Stream is a semantic domain.
2. Stream is not a transport abstraction.
3. Stream is not a queue abstraction.
4. Stream is not a broker abstraction.
5. Stream is not a pipeline framework.
6. Stream is not a scheduling abstraction.
7. Stream is not a buffering abstraction.
8. Stream is not a persistence abstraction.
9. Stream is not equivalent to Event.
10. Stream is not equivalent to Observation.
11. Stream is not equivalent to State.
12. Stream is not equivalent to Data.
13. Stream is not equivalent to Process.
14. Stream is not equivalent to Dynamics.
15. Stream may represent the evolution of any of these.
16. Occurrence, availability, publication, processing, and consumption remain distinct.
17. Temporal ordering and causal ordering remain distinct.
18. State and delta semantics remain distinct.
19. Historical and replay semantics remain distinct from new execution.
20. Absence MUST have explicit interpretation.
21. Identity MUST survive valid transformations.
22. Provenance MUST survive transformations where required.
23. References MUST remain distinct from entities.
24. Deletion MUST NOT automatically destroy historical provenance.
25. Nullary relations remain valid semantic relations.
26. Stream topology is subordinate to the canonical SCR hypergraph.
27. Providers remain outside `lib/`.
28. Transport mechanisms remain implementations.
29. Buffering and backpressure remain execution concerns.
30. Partitioning and scheduling remain execution concerns unless explicitly promoted.
31. AMQP is a possible realization mechanism, not Stream semantics.
32. HyrxMQ is a provider and MUST NOT define Stream ontology.
33. MLIR is a representation/compilation substrate.
34. Mojo is an implementation language, not Stream semantics.
35. Runtime behavior MUST conform to semantic contracts.
36. Provider substitution MUST preserve required semantic invariants.
37. Semantic equivalence MUST be defined by preserved meaning rather than implementation identity.
38. Stream semantics MUST remain independent of presentation.
39. Stream semantics MUST remain independent of UI.
40. Stream semantics MUST remain independent of hardware.
41. Stream semantics MUST remain independent of network topology.
42. Stream semantics MUST remain independent of execution framework.

---

# 60. Relationship to Other SCR Domains

Stream interacts with other semantic domains without subsuming them.

```text
Data
  │
  ├── may participate in ──► Stream
  │
Field
  │
  ├── may evolve through ──► Stream
  │
Event
  │
  ├── may be represented by ──► Stream Element
  │
Perception
  │
  ├── may produce ──► Observation Stream
  │
Interaction
  │
  ├── may produce ──► Input / Action Stream
  │
Dynamics
  │
  ├── may produce ──► State Transition Stream
  │
Simulation
  │
  ├── may produce ──► Simulation State Stream
  │
Graph / Hypergraph
  │
  ├── may evolve through ──► Graph Stream
```

These relationships are compositional rather than hierarchical ownership relationships.

---

# 61. Semantic Stream and Execution Stream

The architecture MUST distinguish:

```text
Semantic Stream
```

from:

```text
Stream Realization
```

A semantic Stream describes meaning.

A realization provides mechanisms such as:

```text
Transport
Buffer
Queue
Broker
Scheduler
Partition
Storage
Provider
Runtime
```

The realization MAY change while semantic Stream identity and meaning remain stable.

---

# 62. Minimal Semantic Contract

A minimally valid Stream definition MUST establish:

1. Stream identity;
2. element identity;
3. element semantics;
4. occurrence semantics where applicable;
5. availability semantics;
6. ordering semantics;
7. temporal semantics where applicable;
8. lifecycle;
9. provenance requirements;
10. completeness/loss semantics;
11. transformation semantics where applicable.

Additional execution guarantees MAY be layered above this contract.

---

# 63. Conformance

A Stream implementation conforms to this definition when it can demonstrate that:

* its semantic identity is explicit;
* its elements have defined semantic meaning;
* ordering semantics are explicit;
* temporal semantics are explicit where applicable;
* causal semantics are explicit where applicable;
* availability is not conflated with existence;
* lifecycle is defined;
* loss and completeness are defined;
* identity and provenance are preserved;
* deletion/reference semantics conform to SCR;
* nullary relations are supported where required;
* execution mechanisms do not redefine semantic meaning;
* provider-specific concepts do not leak into the semantic ontology;
* its representation remains replaceable without changing the semantic contract.

---

# 64. Validation Requirements

Validation SHOULD test at minimum:

### Identity

* stable Stream identity;
* stable element identity;
* reference preservation.

### Ordering

* total ordering;
* partial ordering;
* unordered semantics;
* causal ordering.

### Temporal Semantics

* multiple clocks;
* occurrence time;
* observation time;
* processing time;
* simulated time.

### Lifecycle

* creation;
* activation;
* suspension;
* resumption;
* completion;
* closure.

### State

* complete state;
* partial state;
* delta state;
* reconstruction.

### Availability

* delayed availability;
* unavailable elements;
* observation delay;
* publication delay.

### Loss

* dropped element;
* filtered element;
* withdrawn element;
* deleted element;
* superseded element.

### Replay

* deterministic replay;
* duplicate replay;
* side-effect protection.

### Provenance

* source preservation;
* transformation history;
* causal metadata.

### Distribution

* partitioning;
* reordering;
* duplication;
* causal propagation.

### Provider Independence

Equivalent Stream semantics MUST be demonstrable across more than one realization where practical.

---

# 65. Completeness Criteria

The Stream domain is considered semantically mature when it provides explicit definitions for:

* element;
* occurrence;
* availability;
* temporal semantics;
* ordering;
* causality;
* state;
* delta;
* event;
* observation;
* operation;
* lifecycle;
* composition;
* transformation;
* window;
* sampling;
* completeness;
* loss;
* delivery;
* replay;
* checkpoint;
* provenance;
* identity;
* references;
* deletion;
* withdrawal;
* supersession;
* nullary relations;
* distributed execution;
* hypergraph integration;
* provider boundary;
* semantic equivalence.

---

# 66. Open Semantic Questions

The following remain subjects for further formalisation:

1. What is the mathematically minimal definition of Stream?
2. Which ordering relations belong in Core versus Stream?
3. Whether Availability should become an independent semantic domain.
4. Formal relationship between Stream and Dynamics.
5. Formal relationship between Stream and Event.
6. Formal relationship between Stream and Process.
7. Formal treatment of multiple simultaneous clocks.
8. Formal causal algebra for distributed Streams.
9. Formal equivalence between state and delta representations.
10. Formal semantics of continuous Streams.
11. Formal semantics of infinite Streams.
12. Formal semantics of Stream termination.
13. Formal semantics of semantic absence.
14. Formal semantics of replayed side effects.
15. Formal checkpoint equivalence.
16. Formal treatment of lossy transformations.
17. Formal representation of Stream windows in the SCR hypergraph.
18. Formal relationship between Stream and temporal fields.
19. Formal representation of stream capabilities.
20. Formal conformance relation between semantic Streams and providers.

---

# 67. Final Semantic Principle

The fundamental principle of the SCR Stream domain is:

> **A Stream is not fundamentally something that carries information. It is the semantic structure by which information, state, occurrences, observations, operations, or transformations are related through evolution, ordering, causality, and availability.**

Transport, queues, brokers, buffers, schedulers, protocols, runtimes, and providers are mechanisms for realizing that structure.

They are not the structure itself.
