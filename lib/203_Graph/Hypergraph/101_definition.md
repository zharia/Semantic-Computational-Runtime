# SCR Semantic Hypergraph Foundation

**Project:** Semantic Computational Runtime (SCR)
**Location:** `lib/`
**Status:** Foundational implementation
**Priority:** Very High
**Implementation scope:** Semantic model only; no physical container/file format

---

## 1. Objective

Implement the foundational **Semantic Hypergraph** library for SCR.

This library is intended to become one of the lowest-level semantic substrates of the runtime.

It must provide a general computational representation for:

* entities
* concepts
* relationships
* higher-order relationships
* semantic references
* graph regions
* representations
* transformations
* provenance
* temporal state
* semantic operations
* deltas
* streams of semantic state evolution

The implementation MUST remain independent of:

* any particular persistence engine
* filesystem layout
* database technology
* network transport
* message broker
* serialization format
* rendering engine
* external graph database
* particular programming-language frontend
* particular hardware backend

This is a **semantic model**, not a file format.

---

# 2. Architectural Position

The intended architecture is:

```text
                    SCR Semantic Runtime
                           │
                  ┌────────▼────────┐
                  │ Semantic Library │
                  └────────┬────────┘
                           │
                  ┌────────▼────────┐
                  │ Semantic Model   │
                  │                  │
                  │ Hypergraph       │
                  │ Identity         │
                  │ Regions          │
                  │ Operations       │
                  │ Deltas           │
                  │ Streams          │
                  │ References       │
                  │ Transformations  │
                  │ Provenance       │
                  └────────┬────────┘
                           │
                     MLIR / Runtime
```

The Semantic Hypergraph MUST NOT depend on MLIR internally.

MLIR may later represent, transform, compile, or execute operations over the semantic model.

The semantic model is therefore upstream of MLIR.

---

# 3. Core Design Principle

The fundamental object is:

> A typed, attributed, role-labelled semantic hypergraph whose state evolves through explicit semantic operations.

Conceptually:

```text
Semantic Hypergraph
│
├── Nodes
├── Hyperedges
├── Graph Regions
├── Identities
├── References
├── Representations
├── Transformations
└── Provenance
        │
        ▼
   Semantic Operations
        │
        ▼
     Deltas
        │
        ▼
     Streams
        │
        ▼
 Materialized Graph State
```

Do not reduce this model to an ordinary property graph.

---

# 4. What This Library Is NOT

Do not implement:

* a database
* a filesystem
* a graph database adapter
* a GQL engine
* an RDF database
* a TerminusDB clone
* a persistence layer
* a message broker
* an AMQP implementation
* a serialization format
* a distributed consensus system
* CRDTs
* a rendering system
* an MLIR dialect for the entire model

Adapters for such systems may exist later.

The library defines the semantic abstraction that such systems can implement or consume.

---

# 5. Semantic Hypergraph

The fundamental graph is a **hypergraph**.

A hyperedge may connect an arbitrary number of participants.

For example:

```text
        ┌─────────────┐
        │ Experiment  │
        └──────┬──────┘
               │
       ┌───────┴────────┐
       │ Hyperedge      │
       │ OBSERVATION    │
       └──┬────┬────┬───┘
          │    │    │
          ▼    ▼    ▼
       Agent  Field  Time
```

The relationship itself is a semantic object.

It MUST be possible for a hyperedge to have:

* identity
* type
* attributes
* metadata
* provenance
* temporal information
* participants
* participant roles

---

# 6. Nodes

A node represents a semantic entity.

A node SHOULD support:

```text
identity
type
attributes
metadata
references
representations
provenance
temporal validity
```

Examples:

```text
Agent
Planet
Field
Observation
Simulation
Geometry
Morphology
Algorithm
Dataset
Transformation
Sensor
Event
Material
Concept
```

The node abstraction must remain domain-neutral.

---

# 7. Hyperedges

Hyperedges are first-class semantic entities.

A hyperedge contains a set of role-labelled participants.

For example:

```text
TRANSFER
    source      → Field_A
    destination → Field_B
    operator    → Diffusion
    medium      → Environment
    time        → T42
```

Do not model this internally as a collection of binary edges unless there is an explicit projection layer.

The native model must preserve the higher-order relationship.

---

# 8. Roles

Relationship participation is role-sensitive.

This is insufficient:

```text
A -- TRANSFER --> B
```

The semantic model should support:

```text
TRANSFER
    source      = A
    destination = B
    mechanism   = M
    observer    = O
```

Roles MUST be first-class.

A role SHOULD have:

* semantic identity
* type
* optional cardinality constraints
* optional semantic constraints

---

# 9. Types

Nodes, hyperedges, roles, operations, representations and other semantic objects must support explicit typing.

Types themselves should be representable within the semantic graph.

Avoid hard-coding domain ontologies into the core library.

The core library should permit:

```text
type: Agent
type: Field
type: Morphology
type: Observation
```

without knowing what those types mean.

Domain packages define the semantics.

---

# 10. Attributes

Semantic objects may carry typed attributes.

Attributes MUST support values beyond simple strings.

The abstraction should accommodate:

```text
scalar
boolean
integer
floating point
string
binary/reference values
structured values
semantic references
collections
```

Do not prematurely impose a JSON-only value model.

The semantic value abstraction should be extensible.

---

# 11. Identity Model

Identity is foundational and MUST be separated into different concepts.

At minimum distinguish:

### Semantic identity

Identifies what an object means.

Conceptually:

```text
IRI / URI
```

Example:

```text
scr://domain/physics/velocity
```

Do not hard-code the `scr://` scheme.

The library should support URI/IRI-like identifiers abstractly.

---

### Content identity

Identifies particular content.

Conceptually:

```text
CID / multihash
```

The core library should expose a content-identity abstraction without assuming a particular hashing algorithm.

---

### Operation identity

Identifies a semantic operation/event.

Operations require their own identity.

---

### Graph-region identity

A semantic asset may be an entire subgraph rather than a single node.

Therefore support addressable graph regions.

---

# 12. Graph Regions

A **graph region** is an addressable semantic subset of a graph.

Examples:

```text
all objects belonging to experiment X

the morphology of organism Y

the dependency graph of transformation Z

all observations associated with sensor S

the topology surrounding spatial region R
```

A region may be defined by:

* explicit membership
* semantic pattern
* query
* type
* relationship
* predicate
* temporal scope
* combination of these

A region SHOULD be addressable independently of the entire graph.

This is important for:

* partial loading
* streaming
* distributed execution
* transformations
* references
* incremental updates

---

# 13. References

References must be semantic rather than physical.

The core abstraction should support at least:

```text
SemanticReference
ContentReference
RegionReference
PatternReference
```

A reference should not inherently mean:

```text
/path/to/file
database/table/row
network endpoint
memory address
```

Those are resolution mechanisms.

The semantic graph declares what is being referenced.

A runtime/environment later determines how that reference is resolved.

---

# 14. Runtime Resolution

References may require contextual resolution.

Conceptually:

```text
Semantic Reference
        │
        ▼
Runtime Environment
        │
        ├── local graph
        ├── remote graph
        ├── content store
        ├── provider
        ├── generated object
        └── external resource
```

The core library should therefore define a resolution abstraction but MUST NOT implement a particular resolver backend.

---

# 15. Representations

A semantic object may have multiple representations.

For example:

```text
Geometry
 ├── conceptual geometry
 ├── WKT
 ├── WKB
 ├── glTF
 └── GPU representation
```

The semantic object is not equivalent to any representation.

Representations should therefore be modeled explicitly.

A representation may have:

```text
media type
content identity
semantic compatibility
version
provenance
parameters
```

Use IANA media types where applicable.

Do not create a proprietary MIME-type system.

---

# 16. Transformations

Transformations are first-class semantic objects.

A transformation should describe:

```text
input semantic pattern
output semantic pattern
parameters
constraints
provenance
implementation/provider information
```

Conceptually:

```text
Graph Pattern
      │
      ▼
 Transformation
      │
      ▼
Graph Pattern
```

Example:

```text
TemperatureField
       │
       ▼
 gradient()
       │
       ▼
VelocityField
```

The transformation itself should be addressable and inspectable.

The core model must distinguish:

```text
what transformation means
```

from:

```text
which implementation performs it
```

---

# 17. Provenance

Provenance should be first-class.

Where practical, align with established standards such as W3C PROV rather than inventing incompatible terminology.

Provenance should be able to describe:

```text
who/what produced an object
which operation produced it
which inputs were used
when it occurred
which transformation was applied
which representation was produced
```

Do not make the core library dependent on PROV-O.

Provide semantic abstractions that can later project to it.

---

# 18. Temporal Semantics

Time must not be reduced to a single timestamp.

The model should permit multiple temporal dimensions, including:

```text
event time
valid time
observation time
processing time
simulation time
```

The exact semantics are domain-specific.

Use established representations such as ISO 8601 / RFC 3339 where applicable.

The semantic model should distinguish:

```text
time of occurrence
```

from:

```text
time at which the runtime learned about occurrence
```

---

# 19. Semantic Operations

Operations are first-class.

Examples:

```text
CreateNode
DeleteNode
CreateHyperedge
DeleteHyperedge
SetAttribute
RemoveAttribute
AttachRepresentation
DetachRepresentation
CreateReference
TransformRegion
MergeRegion
SplitRegion
```

However, do not assume this exact list is final.

Define a general operation abstraction capable of extension.

Each operation should have:

```text
operation_id
operation_type
target
inputs
parameters
causal metadata
temporal metadata
origin
provenance
```

---

# 20. Deltas

A delta describes a change in graph state.

Conceptually:

```text
G₀
 │
 │ Δ₁
 ▼
G₁
 │
 │ Δ₂
 ▼
G₂
```

Important distinction:

```text
Semantic Operation
        ↓
Graph Delta
        ↓
Materialized State
```

An operation is an intentional semantic action.

A delta is the resulting state difference.

Do not conflate the two.

A single operation may produce multiple graph changes.

Multiple operations may potentially be represented by one optimized delta.

---

# 21. State Evolution

The conceptual state model is:

```text
Gₙ = G₀ ⊕ Δ₁ ⊕ Δ₂ ... ⊕ Δₙ
```

where `⊕` means semantic application of a valid delta.

This is a conceptual algebra, NOT a requirement to implement the graph as an append-only log.

The implementation may materialize state for performance.

The semantic model must nevertheless preserve the distinction between:

```text
state
history
operation
delta
```

---

# 22. Streams

Streaming is a first-class concern.

A stream should conceptually be:

```text
Stream<SemanticEvent>
```

or:

```text
Stream<SemanticOperation>
```

Examples:

```text
sensor observations
simulation events
agent actions
graph mutations
field updates
render updates
telemetry
distributed state changes
```

A graph may therefore be treated as a stateful fold over a stream:

```text
events
   │
   ▼
apply
   │
   ▼
graph state
```

The core library should define semantic stream abstractions.

It MUST NOT depend on RabbitMQ, AMQP, Kafka, NATS, TCP, WebSockets, etc.

AMQP can later be implemented as a provider/transport.

---

# 23. Subscriptions

The model should eventually support subscriptions to semantic regions.

Conceptually:

```text
Semantic Query / Region
          │
          ▼
     Subscription
          │
          ▼
   Stream of changes
```

For example:

```text
subscribe(
    "all agents within region R"
)
```

The result could be a stream of semantic deltas.

Do not implement a full query engine as part of this first increment unless required by the architecture.

Define interfaces that allow one later.

---

# 24. Causality

Operations and events should have optional causal metadata.

Support concepts such as:

```text
operation ID
parent/predecessor operations
logical sequence
origin
simulation time
event time
```

This is preparation for distributed execution.

Do NOT implement CRDT semantics yet.

Do NOT assume a particular consistency model.

The model should preserve enough information for future consistency implementations.

---

# 25. Conflict Semantics

The core graph should distinguish:

```text
invalid operation
```

from:

```text
concurrent operations whose combination requires a conflict policy
```

Conflict resolution is a runtime/domain concern unless the semantic type explicitly defines a resolution law.

Do not silently overwrite semantic state.

---

# 26. Queries and GQL

The native model is NOT GQL.

GQL should be treated as a query/projection interface.

Conceptually:

```text
Semantic Hypergraph
       │
       ▼
 GQL / query projection
       │
       ▼
Selected graph region
```

The library should therefore avoid designing its internal representation around property-graph assumptions merely to make GQL convenient.

Where possible, expose a query abstraction that can later support:

* ISO GQL
* semantic pattern matching
* domain-specific queries
* graph traversal
* subscriptions
* transformation selection

---

# 27. Open Standards

The implementation should follow this rule:

> Reuse an established open standard whenever an applicable standard exists and can represent the required semantics without loss of essential information.

Potential standards include:

```text
URI / IRI
CID / multihash
IANA media types
JSON / JSON-LD
CBOR
RDF / RDF-star
RDFS / OWL
SHACL
ISO GQL
ISO 8601
RFC 3339
UCUM
OGC / EPSG
W3C PROV
COSE / JOSE
```

These are interoperability mechanisms.

They do not become the semantic authority of SCR.

---

# 28. Domain Independence

The library MUST NOT know the semantics of:

```text
physics
biology
morphology
agents
neural networks
geometry
rendering
messaging
simulation
```

Those belong in higher semantic domains.

For example:

```text
lib/
  semantic/
    hypergraph/

  physics/
  geometry/
  morphology/
  fields/
```

A physics package may define:

```text
Force
Mass
Acceleration
Particle
```

using the semantic hypergraph substrate.

The hypergraph library itself should not know what Force means.

---

# 29. Morphology Compatibility

The model must be capable of representing the future SCR morphology model.

For example:

```text
Pattern
   │
   ▼
Morphology
   │
   ▼
Geometry / Structure
```

and:

```text
Morphology
   │
   ▼
Pattern
```

Morphology may therefore appear as:

* a node
* a graph region
* a structured relation
* a derived object
* a transformation result
* a stream of structural changes

Do not implement morphology semantics here.

Ensure the substrate can represent them.

---

# 30. Fields Compatibility

The graph must be capable of referencing and describing fields without requiring field values to be stored directly inside graph nodes.

For example:

```text
Field
 ├── semantic identity
 ├── domain
 ├── topology
 ├── coordinate system
 ├── sampling
 ├── representation
 └── data reference
```

A field may therefore refer to a potentially enormous external or distributed computational object.

The graph describes the semantic object.

The runtime determines how its data is accessed.

---

# 31. Distributed Data

The design must permit a graph region to be:

```text
local
remote
partitioned
replicated
generated
streamed
materialized
virtual
```

Do not require the entire graph to exist in one process.

This is a semantic requirement, not a distributed-storage implementation requirement.

---

# 32. Immutability and Materialization

Prefer immutable semantic identities and content-addressed representations.

However, do not force all runtime graph state to be immutable.

The conceptual distinction should be:

```text
Immutable semantic artifacts
        +
Semantic operations
        +
Materialized runtime state
```

Materialized state is an optimization/view.

It must not become the sole definition of semantic history.

---

# 33. Canonicalization

Do not prematurely specify graph canonicalization.

Content-addressing arbitrary hypergraphs requires a canonical representation.

That problem should be explicitly isolated behind an abstraction.

For example:

```text
Graph
  │
  ▼
Canonicalizer
  │
  ▼
Canonical representation
  │
  ▼
Content identity
```

Do not invent a canonical hashing scheme merely to get the first implementation working.

---

# 34. API Design

The API should be strongly typed and composable.

Prefer abstractions resembling:

```text
SemanticObject
SemanticNode
SemanticHyperedge
SemanticRole
SemanticType
SemanticValue
SemanticReference
GraphRegion
Representation
Transformation
Provenance
Operation
Delta
SemanticStream
```

Exact names may differ if the repository's conventions dictate otherwise.

Avoid leaking:

```text
database IDs
filesystem paths
JSON structures
network URLs
Rust implementation details
```

into the semantic API unless those are explicitly semantic concepts.

---

# 35. Rust Implementation

Use idiomatic Rust.

Prefer:

* ownership-safe structures
* explicit lifetimes only where genuinely useful
* immutable references where possible
* `Arc`/shared ownership where graph topology requires it
* strongly typed identifiers
* enums for closed semantic categories
* traits for extensibility
* explicit error types
* deterministic behavior where semantics require it

Do not over-engineer the first implementation.

The API should be small enough that higher-level semantic domains can actually use it.

---

# 36. Suggested Module Structure

Start with something conceptually similar to:

```text
lib/
  semantic/
    hypergraph/
      mod.rs

      identity.rs
      value.rs
      object.rs

      node.rs
      hyperedge.rs
      role.rs
      attribute.rs
      region.rs

      reference.rs
      representation.rs
      transformation.rs
      provenance.rs

      operation.rs
      delta.rs
      stream.rs
      temporal.rs
      causal.rs

      query.rs
      error.rs
```

Do not blindly create every file.

First inspect the existing repository architecture and consolidate with existing abstractions.

The repository's existing conventions take precedence over this illustrative structure.

---

# 37. Tests

Tests must be developed alongside the implementation.

At minimum provide:

### Identity tests

* semantic identity
* content identity abstraction
* operation identity
* region identity

### Graph tests

* node creation
* typed nodes
* attributes
* hyperedge creation
* arbitrary participant count
* role-labelled participants
* nested/higher-order structures

### Region tests

* explicit regions
* pattern-defined regions
* region membership
* region references

### Reference tests

* semantic references
* content references
* region references
* unresolved references
* resolution abstraction

### Operation tests

* operation identity
* operation application
* invalid operations
* operation provenance
* causal metadata

### Delta tests

* state transition
* delta application
* delta inversion where supported
* deterministic application

### Stream tests

* event sequencing
* operation streams
* graph materialization from streams
* temporal metadata
* causal metadata

### Transformation tests

* transformation identity
* input/output contracts
* provenance
* transformation over graph regions

### Invariant tests

Explicitly test the foundational invariants.

---

# 38. Foundational Invariants

At minimum establish:

**INV-SHG-001 — Semantic Primacy**

The semantic graph model is independent of implementation technology.

**INV-SHG-002 — Hyperedge Integrity**

Higher-order relationships MUST remain representable without reduction to binary edges.

**INV-SHG-003 — Role Integrity**

Participation in a relationship may carry semantic role information.

**INV-SHG-004 — Identity Separation**

Semantic identity, content identity, graph-region identity and operation identity are distinct concepts.

**INV-SHG-005 — Representation Independence**

A representation is not identical to the semantic object it represents.

**INV-SHG-006 — Operation/Delta Separation**

Semantic operations and graph deltas are distinct concepts.

**INV-SHG-007 — State/History Separation**

Materialized graph state is distinct from the sequence of operations that produced it.

**INV-SHG-008 — Reference Indirection**

Semantic references do not encode a mandatory physical storage mechanism.

**INV-SHG-009 — Domain Independence**

The core hypergraph library contains no domain-specific semantic authority.

**INV-SHG-010 — Stream Independence**

Semantic streams are independent of transport technology.

**INV-SHG-011 — Temporal Explicitness**

Where temporal semantics exist, event/valid/processing/simulation time must not be silently conflated.

**INV-SHG-012 — Provenance Preservation**

Transformations and state changes must be capable of retaining provenance.

**INV-SHG-013 — Deterministic Semantics**

Where an operation is declared deterministic, equivalent inputs must produce semantically equivalent outputs.

**INV-SHG-014 — No Physical Authority**

Filesystem, database, network, memory and hardware representations cannot redefine semantic meaning.

---

# 39. Error Model

Errors should distinguish at least:

```text
InvalidIdentity
InvalidType
InvalidRole
InvalidAttribute
InvalidHyperedge
InvalidReference
UnresolvedReference
InvalidOperation
InvalidDelta
TemporalError
CausalityError
ConstraintViolation
TransformationError
```

Use structured Rust error types.

Avoid generic string errors.

---

# 40. Serialization

Do NOT implement a proprietary serialization format in this increment.

Serialization traits/interfaces may be defined if genuinely useful, but implementations should remain separate.

Future representations might include:

```text
JSON-LD
CBOR
RDF
binary canonical representation
database representation
network representation
```

The semantic library must not assume one.

---

# 41. Persistence

Do NOT implement persistence.

Do NOT create:

```text
.sgc
.shg
.scr
```

or any other proposed SCR container format.

Persistence belongs to a later subsystem.

The current objective is to establish the semantic model that persistence implementations will consume.

---

# 42. Query Engine

Do not implement a complete GQL engine in this increment.

Define only the abstractions required to represent:

```text
semantic selection
graph region
pattern
query result
```

A later query subsystem can implement:

```text
ISO GQL
pattern matching
graph traversal
subscriptions
incremental queries
```

---

# 43. Runtime Integration

Do not tightly integrate this first implementation with the full SCR runtime.

Provide clean interfaces through which the runtime can eventually:

```text
resolve references
materialize regions
apply operations
execute transformations
consume streams
publish deltas
```

The semantic hypergraph should be usable independently in unit tests and small examples.

---

# 44. Example

The implementation should be capable of representing something conceptually equivalent to:

```text
Agent:A
Field:Temperature
Region:Environment
Time:T42

OBSERVATION
    observer     = Agent:A
    observed     = Field:Temperature
    region       = Region:Environment
    time         = Time:T42
```

Then:

```text
Agent:A
   │
   └──── observes ────► TemperatureField
                            │
                            └── located-in ──► Environment
```

while retaining the complete higher-order observation relationship.

An operation could then produce:

```text
OBSERVATION_CREATED
```

which produces a delta:

```text
+ Hyperedge OBSERVATION
```

which changes the materialized graph state.

---

# 45. Example of Streaming

The library should support the conceptual flow:

```text
Sensor
  │
  ▼
Semantic Event
  │
  ▼
Semantic Operation
  │
  ▼
Graph Delta
  │
  ▼
Materialized Graph
  │
  ├─────────────► Query
  │
  ├─────────────► Transformation
  │
  ├─────────────► Simulation
  │
  └─────────────► Rendering
```

Transport is intentionally outside this abstraction.

---

# 46. Example of Distributed Resolution

A semantic graph may contain:

```text
Field:temperature
```

with a semantic reference to a large field representation.

The graph need not know whether that representation lives:

```text
in RAM
on disk
in object storage
on another machine
inside a GPU
inside a simulation provider
inside a remote service
```

The runtime resolves it.

This distinction is essential.

---

# 47. Implementation Sequence

Follow the SCR development progression:

```text
DESCRIBE
   ↓
SPECIFY
   ↓
TEST
   ↓
IMPLEMENT
   ↓
VALIDATE
```

Recommended implementation order:

### Phase 1 — Core identity and values

Implement:

```text
SemanticType
SemanticValue
SemanticIdentity
ContentIdentity abstraction
OperationIdentity
```

### Phase 2 — Graph primitives

Implement:

```text
SemanticObject
Node
Role
Hyperedge
Attributes
```

### Phase 3 — Regions and references

Implement:

```text
GraphRegion
SemanticReference
ContentReference
RegionReference
```

### Phase 4 — Operations and state

Implement:

```text
Operation
Delta
State transition
```

### Phase 5 — Temporal/causal model

Implement:

```text
Temporal metadata
Causal metadata
Provenance
```

### Phase 6 — Streams

Implement:

```text
SemanticEvent
SemanticStream
stream → operation → delta → state
```

### Phase 7 — Transformations

Implement:

```text
Transformation
input/output semantic contracts
region transformation
```

### Phase 8 — Query abstractions

Implement minimal:

```text
SemanticPattern
Query
QueryResult
Region selection
```

Do not implement full GQL yet.

---

# 48. Required Documentation

Create documentation explaining:

1. Why SCR needs a semantic hypergraph.
2. Why ordinary property graphs are insufficient.
3. Why hyperedges are first-class.
4. Identity versus representation.
5. Semantic references versus physical locations.
6. Operations versus deltas.
7. State versus history.
8. Streams as state evolution.
9. Graph regions.
10. Runtime-mediated reference resolution.
11. Relationship to future GQL support.
12. Relationship to MLIR.
13. Relationship to higher SCR semantic domains.

Include Mermaid diagrams where useful.

---

# 49. Integration Requirements

Before considering the increment complete:

* inspect existing `lib/` architecture
* identify existing ID/value/error abstractions
* reuse existing foundational abstractions where semantically compatible
* do not duplicate concepts already present
* update relevant module exports
* add unit tests
* add at least one end-to-end semantic graph example
* ensure the library builds independently
* ensure existing SCR tests remain passing
* document architectural decisions
* do not introduce unnecessary dependencies

---

# 50. Dependency Discipline

Prefer the Rust standard library initially.

Introduce external dependencies only when:

1. an established standard requires it,
2. the dependency provides substantial capability,
3. the dependency does not become semantic authority,
4. the dependency is compatible with SCR's architectural goals.

Do not pull in a graph database merely to implement the graph.

Do not pull in a serialization framework merely to define the model.

Do not pull in a messaging library merely to define streams.

---

# 51. Definition of Done

This increment is complete only when:

* [ ] semantic hypergraph exists as a usable library
* [ ] hyperedges are genuinely first-class
* [ ] role-labelled relationships work
* [ ] semantic types exist
* [ ] typed attributes exist
* [ ] identity classes are separated
* [ ] graph regions exist
* [ ] semantic references exist
* [ ] representation abstraction exists
* [ ] operations exist
* [ ] deltas exist
* [ ] state transitions work
* [ ] temporal metadata exists
* [ ] causal metadata exists
* [ ] provenance exists
* [ ] semantic streams exist
* [ ] transformations exist as first-class concepts
* [ ] query/selection abstraction exists without coupling to GQL
* [ ] physical persistence is absent
* [ ] transport dependencies are absent
* [ ] domain-specific semantics are absent
* [ ] foundational invariants have tests
* [ ] documentation exists
* [ ] existing project tests remain passing
* [ ] implementation is suitable as a substrate for future semantic domains

---

# 52. Critical Architectural Constraint

The implementation must preserve this distinction:

```text
                    MEANING
                       │
                       ▼
              Semantic Hypergraph
                       │
            ┌──────────┼──────────┐
            ▼          ▼          ▼
       Operations    Queries   Transformations
            │          │          │
            ▼          ▼          ▼
         Streams     Regions    Derived Graphs
                       │
                       ▼
                 Runtime Layer
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
       Storage      Network       Hardware
```

The lower layers MUST NOT leak upward and redefine the semantic model.

---

# 53. Final Instruction to the Agent

Treat this implementation as **foundational architecture**, not as a feature implementation.

Before writing code:

1. inspect the repository recursively;
2. inspect `AGENTS.md`;
3. inspect the relevant `program_increments/**/101_definition.md`;
4. inspect the relevant `102_status.yaml`;
5. inspect existing `lib/` abstractions;
6. identify duplication and architectural conflicts;
7. propose the final module/API structure;
8. implement specification tests first;
9. implement the minimum coherent semantic substrate;
10. validate against the repository's existing architecture.

Do not optimize prematurely.

Do not create a physical file/container format.

Do not build a database.

Do not build GQL.

Do not build AMQP.

Do not build CRDTs.

Do not build domain-specific semantics.

Build the **semantic substrate** on which those things can later be built.

The governing principle is:

> **The Semantic Hypergraph describes computational meaning and state. Everything else is a representation, transformation, transport, storage mechanism, or execution strategy operating upon that meaning.**
