---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-INTERFACES
name: Interfaces

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-CORE

authority: SCR
domain: semantic-library
------------------------

# SCR Interfaces

## Definition

Interfaces is the cross-cutting semantic domain concerned with defining the boundaries through which computational entities expose, consume, compose, constrain, observe, and negotiate capabilities and behaviour.

An Interface defines a **semantic interaction contract** between a provider and one or more consumers.

An interface specifies what may be relied upon at the interaction boundary without requiring consumers to depend upon the provider's internal implementation.

The fundamental distinction is:

```text
Interface
    =
what may be relied upon

Implementation
    =
how it is realized
```

An SCR interface may therefore describe:

* operations
* inputs
* outputs
* types
* capabilities
* behaviour
* state
* effects
* errors
* constraints
* preconditions
* postconditions
* invariants
* resource requirements
* temporal properties
* ordering guarantees
* determinism
* composability
* compatibility
* versioning.

An interface is therefore more than a function signature.

---

# Semantic Model

An interface can be represented conceptually as:

```text
I = (N, O, T, C, B, S, E, R, K, V, P)
```

where:

* `N` = interface identity and namespace
* `O` = operations
* `T` = type and value contracts
* `C` = capabilities
* `B` = behavioural contract
* `S` = state semantics
* `E` = effects and errors
* `R` = resource and execution requirements
* `K` = compatibility constraints
* `V` = versioning semantics
* `P` = provenance.

These elements describe semantic interaction and do not prescribe a particular API technology, programming language, ABI, transport, or deployment architecture.

---

# Interface Primacy

Interfaces provide stable semantic boundaries between otherwise independent implementations.

Conceptually:

```text
              INTERFACE
             /    |     \
            /     |      \
           ▼      ▼       ▼
     Implementation A
     Implementation B
     Implementation C
```

Multiple implementations MAY satisfy the same interface.

Likewise, a single implementation MAY expose multiple interfaces.

An implementation MUST NOT redefine the semantic meaning of an interface.

---

# Scope

SCR Interfaces encompasses:

* interfaces
* operations
* functions
* methods
* signatures
* parameters
* results
* types
* capabilities
* contracts
* preconditions
* postconditions
* invariants
* behavioural semantics
* state semantics
* effect semantics
* error semantics
* resource requirements
* temporal requirements
* spatial requirements
* streaming semantics
* determinism
* stochasticity
* composability
* observability
* controllability
* differentiability
* learnability
* optimizability
* serializability
* distributability
* renderability
* versioning
* compatibility
* refinement
* substitution
* negotiation
* discovery
* adaptation
* providers
* consumers
* adapters
* bindings
* projections.

---

# 1. Interface Identity

Every normative interface MUST have a stable semantic identity.

Identity SHOULD be represented independently of:

* source file
* programming language
* library
* ABI
* runtime
* deployment
* provider.

Interface identity MAY use URI/IRI-based identity.

---

# 2. Interface Boundary

An interface establishes a boundary between:

```text
Provider
   │
   │
   ▼
INTERFACE
   │
   │
   ▼
Consumer
```

The boundary defines which aspects of the provider are observable or relied upon.

Internal implementation details remain outside the interface unless explicitly exposed as semantic guarantees.

---

# 3. Operations

An interface MAY expose one or more operations.

An operation defines an interaction that may:

* consume inputs
* produce outputs
* modify state
* observe state
* emit events
* consume streams
* produce streams
* invoke other operations.

An operation MUST have defined invocation semantics.

---

# 4. Function Signature

An operation MAY define:

* parameters
* parameter types
* parameter cardinality
* optionality
* defaults
* return values
* return types
* errors
* effects
* invocation mode.

A function signature is necessary for many interfaces but is not by itself a complete semantic contract.

---

# 5. Input Contracts

Inputs MAY specify:

* type
* shape
* dimensionality
* units
* domain
* topology
* coordinate system
* constraints
* validity conditions
* ownership
* mutability
* temporal requirements
* precision
* uncertainty.

Input contracts MUST identify conditions under which the operation is valid.

---

# 6. Output Contracts

Outputs MAY specify:

* type
* shape
* dimensionality
* units
* semantics
* domain
* topology
* coordinate system
* precision
* uncertainty
* ordering
* temporal semantics
* provenance.

An output contract MUST define what the consumer is entitled to assume about the result.

---

# 7. Preconditions

A precondition specifies what MUST be true before an operation is invoked.

Examples include:

```text
Input dimensions are compatible.
Required capability is available.
State is initialized.
Coordinate systems are compatible.
Required resource is available.
```

Preconditions constrain valid invocation.

---

# 8. Postconditions

A postcondition specifies what MUST be true after successful completion.

Postconditions may concern:

* output values
* state changes
* invariants
* emitted events
* resource ownership
* provenance
* observable effects.

---

# 9. Invariants

An interface MAY declare invariants that MUST remain true across interactions.

Examples include:

* conservation
* identity persistence
* topology preservation
* ordering
* state consistency
* monotonicity
* resource ownership.

Interface invariants constrain implementations.

---

# 10. Behavioural Semantics

Interfaces MUST be able to describe observable behaviour beyond input/output types.

Behaviour may include:

* sequencing
* state transitions
* side effects
* timing
* ordering
* concurrency
* retries
* cancellation
* idempotence
* persistence
* failure behaviour.

This distinction is important because interfaces that expose only syntactic signatures cannot fully capture semantic interoperability.

---

# 11. State Semantics

An interface MAY be:

* stateless
* stateful
* externally stateful
* internally stateful
* session-oriented
* transactional
* streaming.

State semantics MUST define which state is observable or relied upon.

---

# 12. Effects

An operation MAY produce effects beyond its explicit return value.

Effects may include:

* state mutation
* I/O
* messaging
* stream emission
* rendering
* resource allocation
* resource release
* randomness
* external interaction
* logging
* telemetry.

Effects MUST be explicit when they materially affect composition or correctness.

---

# 13. Error Semantics

Interfaces MUST distinguish expected semantic outcomes from failures.

Errors MAY include:

* invalid input
* violated precondition
* unsupported capability
* resource exhaustion
* timeout
* cancellation
* provider failure
* transport failure
* state conflict
* numerical failure
* semantic inconsistency.

An error contract SHOULD identify:

* error identity
* conditions
* recoverability
* effects
* retry semantics.

---

# 14. Capability Interfaces

An interface MAY describe a capability rather than a specific implementation.

Examples include:

```text
Dynamical
Spatial
Temporal
Differentiable
Parallelizable
Vectorizable
Tileable
Streamable
Renderable
Distributable
Deterministic
Stochastic
Invertible
Composable
Interpolatable
Queryable
Controllable
Learnable
Optimizable
Observable
Transformable
```

Capabilities SHOULD be expressed independently of implementation technology.

---

# 15. Capability Requirements

An interface consumer MAY declare required capabilities.

For example:

```text
Operation:
    integrate(field)

Requirements:
    Spatial
    Temporal
    Deterministic
    Parallelizable
```

Capability requirements may be evaluated by SCR Analysis and used by provider selection.

---

# 16. Compatibility

Interface compatibility determines whether a provider can satisfy a consumer's expectations.

Compatibility may include:

* type compatibility
* semantic compatibility
* behavioural compatibility
* capability compatibility
* state compatibility
* temporal compatibility
* resource compatibility
* version compatibility.

Syntactic compatibility alone is insufficient.

Semantic interoperability requires that interacting systems agree on what exchanged information means.

---

# 17. Refinement

An interface MAY refine another interface.

Refinement may:

* add guarantees
* narrow permitted inputs
* strengthen outputs
* add capabilities
* specialize behaviour
* constrain execution.

Refinement MUST preserve the substitutability guarantees of the parent interface.

---

# 18. Substitutability

An implementation may substitute for another implementation when it satisfies the same interface contract under the relevant equivalence and compatibility conditions.

Substitutability MUST NOT be inferred merely from:

* matching function signatures
* matching types
* matching names
* matching APIs.

Behavioural and semantic contracts matter.

---

# 19. Composition

Interfaces SHOULD compose.

For example:

```text
Interface A
     │
     ▼
Interface B
     │
     ▼
Interface C
```

Composition may involve:

* sequential operations
* parallel operations
* pipelines
* feedback
* streams
* graph composition
* higher-order operations.

Composition MUST preserve the contracts of participating interfaces.

---

# 20. Higher-Order Interfaces

An interface MAY consume or produce:

* functions
* operations
* interfaces
* capabilities
* transformations
* streams
* semantic graphs.

This permits higher-order computational composition.

---

# 21. Generic Interfaces

Interfaces MAY be parameterized over:

* types
* domains
* dimensions
* units
* precision
* topology
* geometry
* execution target
* capabilities.

Generic interfaces MUST retain semantic meaning independent of their instantiation.

---

# 22. Data Interfaces

Data interfaces describe semantic information exchanged between components.

They may specify:

* values
* structures
* schemas
* units
* nullability
* uncertainty
* provenance
* ownership
* mutability.

A serialization format is not automatically a data interface.

---

# 23. Stream Interfaces

Stream interfaces define interactions involving ongoing information flow.

They may specify:

* stream element semantics
* temporal semantics
* ordering
* delivery
* backpressure
* state
* windows
* errors
* replay.

Stream transport remains a realization concern.

---

# 24. Spatial Interfaces

Spatial interfaces may specify:

* coordinate systems
* reference frames
* dimensions
* topology
* locality
* spatial domains
* transformations.

Spatial interfaces MUST preserve the distinction between spatial semantics and representation.

---

# 25. Differentiable Interfaces

A differentiable interface MAY declare:

* differentiable inputs
* differentiable outputs
* derivative semantics
* gradient semantics
* differentiation domain
* discontinuities.

Differentiability MUST be a semantic property rather than merely an implementation feature.

---

# 26. Stateful Interfaces

A stateful interface MUST define relevant state transitions.

Conceptually:

```text
State₀
  │
  │ operation
  ▼
State₁
```

The state transition MAY itself be a semantic object.

---

# 27. Stateless Interfaces

A stateless interface does not expose persistent semantic state between independent interactions unless explicitly declared.

Statelessness facilitates:

* parallel execution
* distribution
* caching
* replay
* substitution.

---

# 28. Deterministic Interfaces

A deterministic interface guarantees semantically equivalent results for equivalent inputs under declared conditions.

The conditions MUST identify relevant:

* state
* ordering
* environment
* randomness
* provider assumptions.

---

# 29. Stochastic Interfaces

A stochastic interface explicitly permits probabilistic behaviour.

It SHOULD define:

* random variables
* distributions
* random sources
* reproducibility requirements
* seed semantics where applicable
* statistical guarantees.

Stochasticity MUST NOT be conflated with nondeterministic implementation behaviour.

---

# 30. Observable Interfaces

An observable interface permits consumers to inspect declared aspects of execution or state.

Observability MAY include:

* telemetry
* state
* events
* metrics
* provenance
* traces
* intermediate results.

Observable information is itself subject to semantic contracts.

---

# 31. Controllable Interfaces

A controllable interface exposes mechanisms through which an external entity can influence the system.

Control semantics MAY include:

* commands
* inputs
* interventions
* targets
* constraints
* state transitions.

The existence of a controllable interface does not imply that the underlying system is fully controllable.

---

# 32. Learnable Interfaces

A learnable interface exposes semantics suitable for learning or adaptation.

This may include:

* observations
* feedback
* parameters
* state
* policies
* objectives
* training operations.

Learnability MUST describe semantic opportunity, not guarantee successful learning.

---

# 33. Optimizable Interfaces

An optimizable interface exposes declared objectives, parameters, constraints, or decision variables suitable for optimization.

Optimization semantics MUST remain distinct from the interface itself.

---

# 34. Renderable Interfaces

A renderable interface exposes semantics that can be transformed into a visual or other perceptual manifestation.

Rendering MUST NOT redefine the semantic object.

---

# 35. Serializable Interfaces

A serializable interface permits semantic state or objects to be represented externally.

Serialization MUST preserve all semantics required by the declared contract.

A format that loses essential semantics is not a semantics-preserving serialization.

---

# 36. Persistable Interfaces

A persistable interface permits semantic state to survive beyond a particular execution context.

Persistence MAY be implemented using:

* databases
* files
* object stores
* graph stores
* logs
* checkpoints.

Storage mechanisms remain implementation concerns.

---

# 37. Distributable Interfaces

A distributable interface can be realized across execution boundaries.

These may include:

* processes
* machines
* clusters
* accelerators
* remote systems.

Distribution MUST preserve declared semantic guarantees.

---

# 38. Temporal Interfaces

Temporal interfaces expose temporal semantics.

These may include:

* event time
* valid time
* simulation time
* deadlines
* periodicity
* ordering
* temporal constraints.

---

# 39. Resource Contracts

Interfaces MAY declare resource requirements or guarantees.

Resources include:

* memory
* compute
* bandwidth
* storage
* latency
* energy
* accelerator capacity.

Resource contracts MAY be:

* hard constraints
* soft constraints
* preferred conditions
* upper bounds
* lower bounds.

---

# 40. Performance Contracts

An interface MAY expose performance semantics such as:

* latency
* throughput
* capacity
* complexity
* memory bounds
* precision
* scalability.

Performance guarantees MUST distinguish:

* semantic guarantee
* expected performance
* measured performance
* implementation-specific observation.

---

# 41. Security Contracts

Interfaces MAY declare:

* permissions
* authority
* isolation
* trust requirements
* confidentiality
* integrity
* allowed effects
* resource limits.

Security contracts constrain interaction but MUST NOT silently become implementation-specific policy.

---

# 42. Versioning

Interfaces MUST support explicit versioning.

Version changes SHOULD distinguish:

* compatible extension
* compatible refinement
* behavioural change
* breaking change
* deprecated capability
* removed capability.

Versioning MUST describe semantic compatibility rather than only API syntax.

---

# 43. Interface Evolution

An interface MAY evolve through:

```text
Interface v1
     │
     ▼
Compatible refinement
     │
     ▼
Interface v2
```

Evolution MUST preserve compatibility where compatibility is claimed.

Breaking changes MUST be identifiable.

---

# 44. Discovery

Interfaces MAY be discoverable through semantic metadata.

Discovery may identify:

* interface identity
* capabilities
* operations
* versions
* constraints
* providers
* availability
* resource characteristics.

Discovery SHOULD be compatible with the Semantic Hypergraph.

---

# 45. Negotiation

Interfaces MAY support negotiation where multiple valid contracts or execution strategies exist.

Negotiation may concern:

* capabilities
* precision
* representation
* transport
* performance
* resource constraints
* version
* optional features.

Negotiation MUST NOT silently weaken mandatory semantic guarantees.

---

# 46. Adapters

Adapters translate between compatible but structurally different interfaces.

Conceptually:

```text
Interface A
     │
     ▼
  Adapter
     │
     ▼
Interface B
```

Adapters MAY transform:

* types
* representations
* units
* coordinate systems
* protocols
* calling conventions.

An adapter MUST preserve declared semantics where it claims semantic compatibility.

---

# 47. Interface Projections

A semantic interface may have multiple projections.

For example:

```text
             Semantic Interface
                    │
       ┌────────────┼────────────┐
       ▼            ▼            ▼
      Rust          C            HTTP
       │            │            │
       ▼            ▼            ▼
     Native         ABI         API
```

Other projections may include:

* Python
* CLI
* gRPC
* AMQP
* WebSocket
* WASM
* FFI.

The projection is not the semantic interface.

---

# 48. MLIR Relationship

SCR Interfaces MAY be represented through MLIR types, operations, interfaces, attributes, traits, and dialect constructs.

MLIR provides mechanisms for compiler representation and transformation.

It does not define the semantic contract of an SCR interface.

---

# 49. Analysis Relationship

SCR Analysis evaluates interfaces for:

* compatibility
* capability satisfaction
* equivalence
* resource requirements
* determinism
* parallelism
* legality
* provider suitability.

Analysis results MAY influence interface resolution.

---

# 50. Runtime Relationship

The runtime MAY use interfaces to:

1. discover capabilities;
2. validate inputs;
3. select providers;
4. establish execution plans;
5. negotiate representations;
6. allocate resources;
7. enforce contracts;
8. monitor execution;
9. detect violations;
10. adapt execution.

---

# 51. Semantic Hypergraph Integration

Interfaces SHOULD be first-class semantic objects in the Semantic Hypergraph.

For example:

```text
Interface
   │
   ├── exposes ──────► Operation
   ├── requires ─────► Capability
   ├── accepts ──────► Type
   ├── produces ─────► Type
   ├── constrains ───► Contract
   ├── implemented-by ► Provider
   └── compatible-with► Interface
```

This permits interface discovery, composition, compatibility analysis, and provider resolution to operate over the same semantic substrate.

---

# 52. Provider Relationship

A provider realizes an interface.

```text
Interface
    │
    ├── Provider A
    ├── Provider B
    └── Provider C
```

Providers MAY differ in:

* algorithm
* representation
* performance
* hardware
* numerical method
* resource requirements.

They MUST preserve the interface semantics they claim to implement.

---

# 53. Consumer Relationship

A consumer depends upon an interface rather than necessarily depending upon a provider.

This enables:

```text
Consumer
    │
    ▼
Interface
    │
    ├── Provider A
    ├── Provider B
    └── Provider C
```

Provider selection therefore becomes a runtime/compiler concern rather than an application semantic dependency.

---

# 54. Interface Composition and Contracts

Interface contracts MAY be composed.

When interfaces compose, the resulting contract MUST account for:

* combined preconditions
* combined postconditions
* effects
* state
* errors
* resource requirements
* ordering
* temporal constraints.

Composition MUST NOT produce an interface whose declared guarantees exceed those established by its components.

---

# 55. Interface Refinement and Contracts

Refinement MAY strengthen guarantees while preserving substitutability.

A refinement that changes fundamental semantics MUST be represented as a distinct incompatible interface.

---

# 56. Standards and Interoperability

SCR Interfaces SHOULD reuse established standards wherever applicable.

Potential standards and mechanisms include:

* URI / IRI
* JSON / JSON-LD
* RDF / RDF-star
* SHACL
* ISO GQL
* OpenAPI
* AsyncAPI
* gRPC / Protocol Buffers
* AMQP
* WebAssembly interfaces
* C ABI
* language FFI mechanisms.

These are interface projections or interoperability mechanisms.

They are not the normative SCR interface model.

---

# 57. Representation Independence

Interface semantics MUST remain independent of:

* programming language
* ABI
* API framework
* serialization format
* network protocol
* operating system
* hardware
* deployment topology.

---

# 58. Implementation Independence

An interface MUST NOT require a particular:

* algorithm
* data structure
* library
* provider
* compiler
* runtime
* hardware target.

An implementation may satisfy an interface through any valid mechanism.

---

# 59. Semantic Equivalence

Two interfaces MAY be semantically equivalent when their observable contracts are equivalent under a declared equivalence relation.

Matching signatures alone do not establish equivalence.

---

# 60. Interface Lifecycle

Interfaces may progress through:

```text
Defined
   ↓
Specified
   ↓
Validated
   ↓
Published
   ↓
Implemented
   ↓
Observed
   ↓
Refined
   ↓
Deprecated
```

Lifecycle state MUST remain distinguishable from interface semantics.

---

# Expected Subdomains

```text
interfaces/
├── interface-core
├── identity
├── operation
├── function
├── signature
├── parameter
├── input
├── output
├── type
├── capability
├── contract
├── precondition
├── postcondition
├── invariant
├── behaviour
├── state
├── effect
├── error
├── deterministic
├── stochastic
├── composable
├── observable
├── controllable
├── learnable
├── optimizable
├── differentiable
├── distributable
├── serializable
├── persistable
├── streamable
├── spatial
├── temporal
├── renderable
├── resource
├── performance
├── security
├── compatibility
├── refinement
├── substitution
├── composition
├── generic
├── higher-order
├── discovery
├── negotiation
├── adapter
├── projection
├── provider
├── consumer
├── version
├── lifecycle
└── equivalence
```

---

# Invariants

### INTERFACE-INV-001 — Semantic Primacy

Interface semantics are normative and MUST NOT be silently redefined by implementation.

### INTERFACE-INV-002 — Implementation Independence

Interfaces MUST NOT depend upon a particular implementation.

### INTERFACE-INV-003 — Stable Identity

Interfaces MUST possess stable semantic identity.

### INTERFACE-INV-004 — Contract Completeness

Material behavioural guarantees MUST be represented in the interface contract.

### INTERFACE-INV-005 — Type Insufficiency

Matching input/output types alone MUST NOT establish semantic compatibility.

### INTERFACE-INV-006 — Preconditions

Declared preconditions MUST be satisfied before successful operation.

### INTERFACE-INV-007 — Postconditions

Declared postconditions MUST hold after successful operation.

### INTERFACE-INV-008 — Effect Transparency

Material externally observable effects MUST be declared.

### INTERFACE-INV-009 — Error Transparency

Material failure modes MUST be represented in the error contract.

### INTERFACE-INV-010 — Capability Integrity

Declared capabilities MUST correspond to actual semantic guarantees.

### INTERFACE-INV-011 — Substitutability

Substitution MUST preserve the relevant interface contract.

### INTERFACE-INV-012 — Refinement Integrity

Refinement MUST preserve declared compatibility guarantees.

### INTERFACE-INV-013 — Composition Integrity

Interface composition MUST preserve component guarantees.

### INTERFACE-INV-014 — Representation Independence

Interface semantics MUST remain independent of representation.

### INTERFACE-INV-015 — Provider Independence

Providers MUST NOT become semantic authorities.

### INTERFACE-INV-016 — Version Transparency

Semantic changes MUST be reflected in interface versioning.

### INTERFACE-INV-017 — Projection Integrity

Interface projections MUST preserve the semantics they claim to expose.

### INTERFACE-INV-018 — Contract Traceability

Interface guarantees MUST be traceable to their normative semantic definitions.

---

# Architectural Rules

1. Interfaces MUST compose with Core.
2. Interfaces MUST compose with Data.
3. Interfaces MUST compose with Mathematics.
4. Interfaces MUST compose with Graphs.
5. Interfaces MUST compose with Fields.
6. Interfaces MUST compose with Geometry.
7. Interfaces MUST compose with Topology.
8. Interfaces MUST compose with Morphology.
9. Interfaces MUST compose with Physics.
10. Interfaces MUST compose with Dynamics.
11. Interfaces MUST compose with Simulation.
12. Interfaces MUST compose with Agents.
13. Interfaces MUST compose with Neural.
14. Interfaces MUST compose with Perception.
15. Interfaces MUST compose with Control.
16. Interfaces MUST compose with Optimization.
17. Interfaces MUST compose with Learning.
18. Interfaces MUST compose with Adaptation.
19. Interfaces MUST compose with Evolution.
20. Interfaces MUST compose with Ecology.
21. Interfaces MUST compose with Stream.
22. Interfaces MUST compose with Analysis.
23. Interfaces MUST support semantic contracts.
24. Interfaces MUST support capabilities.
25. Interfaces MUST support compatibility analysis.
26. Interfaces MUST support provider independence.
27. Interfaces MUST support implementation substitution where equivalence permits.
28. Interfaces MUST support multiple projections.
29. Interfaces MUST support versioning.
30. Interfaces MUST support semantic refinement.
31. Interfaces MUST support stateful and stateless interaction.
32. Interfaces MUST support explicit error semantics.
33. Interfaces MUST support explicit effects.
34. Interfaces MUST remain independent of transport.
35. Interfaces MUST remain independent of storage.
36. Interfaces MUST remain independent of programming language.
37. Interfaces SHOULD integrate with the Semantic Hypergraph.
38. Interfaces SHOULD be analyzable by SCR Analysis.
39. Interfaces MUST be usable by compiler and runtime provider selection.

---

# Completeness Criteria

An implementation of SCR Interfaces is semantically complete only when it can represent:

* interface identity
* interface boundaries
* operations
* signatures
* inputs
* outputs
* types
* preconditions
* postconditions
* invariants
* behaviour
* state
* effects
* errors
* capabilities
* compatibility
* refinement
* substitutability
* composition
* generic interfaces
* higher-order interfaces
* data interfaces
* stream interfaces
* spatial interfaces
* differentiable interfaces
* stateful interfaces
* stateless interfaces
* deterministic interfaces
* stochastic interfaces
* observable interfaces
* controllable interfaces
* learnable interfaces
* optimizable interfaces
* renderable interfaces
* serializable interfaces
* persistable interfaces
* distributable interfaces
* temporal interfaces
* resource contracts
* performance contracts
* security contracts
* versioning
* lifecycle
* discovery
* negotiation
* adapters
* projections
* providers
* consumers
* semantic equivalence.

---

# Testing Requirements

SCR Interface implementations SHOULD include:

### Specification Tests

Tests validating interface semantics against this definition.

### Contract Tests

Tests validating preconditions, postconditions, invariants, effects, and errors.

### Compatibility Tests

Tests determining whether implementations satisfy declared interfaces.

### Substitution Tests

Tests verifying interchangeable implementations.

### Refinement Tests

Tests verifying compatible interface evolution.

### Composition Tests

Tests validating composition of multiple interfaces.

### Capability Tests

Tests validating declared capabilities.

### Projection Tests

Tests ensuring Rust, C, HTTP, AMQP, gRPC, WASM, or other projections preserve semantics where applicable.

### State Tests

Tests validating stateful interaction contracts.

### Error Tests

Tests validating declared failure semantics.

### Provider Tests

Tests validating provider implementations against interface contracts.

### Version Tests

Tests validating compatibility across interface versions.

### Analysis Tests

Tests validating interface compatibility through SCR Analysis.

### Runtime Tests

Tests validating interface-driven provider selection and execution.

---

# Open Semantic Questions

1. What is the minimal universal interface contract required by SCR?
2. How should assumptions and guarantees be represented formally?
3. How should behavioural contracts be encoded in MLIR?
4. How should interface refinement be formally defined?
5. What equivalence relation is required for provider substitution?
6. How should optional capabilities interact with compatibility?
7. How should negotiated interfaces be represented in the Semantic Hypergraph?
8. How should interface contracts interact with security policies?
9. How should resource contracts interact with runtime scheduling?
10. How should temporal contracts be expressed?
11. How should distributed stateful interfaces expose consistency guarantees?
12. How should semantic interface versioning relate to semantic library versioning?
13. How should interface adapters prove semantic preservation?
14. How should dynamic interface adaptation interact with the compiler?
15. How should interfaces expose approximate or probabilistic guarantees?
16. How should interface contracts interact with formal verification?

These questions MUST NOT be resolved implicitly by implementation.

---

# Definition History

## 0.1.0

Initial normative semantic definition.

Establishes Interfaces as the semantic boundary through which computational capabilities, operations, state, behaviour, effects, constraints, and guarantees are exposed and composed independently of implementation technology.

---

# Definition Authority

This document is the normative semantic authority for `SCR-LIB-INTERFACES`.

Programming-language APIs, ABI definitions, network protocols, serialization formats, provider implementations, adapters, and runtime mechanisms MUST conform to the semantic interface definition rather than redefine it.

---

# Definition Principle

> **An interface defines the semantic contract through which computational capabilities and behaviour may be exposed, consumed, composed, constrained, and substituted, independently of the implementation, representation, programming language, transport mechanism, or execution substrate used to realize it.**
> :::writing_end::
