# Semantic Computational Runtime — Semantic Library

## 1. Purpose

`lib/` contains the **semantic library of the Semantic Computational Runtime (SCR)**.

The semantic library defines what computational concepts mean, how those concepts relate, what invariants they obey, and what contracts implementations must satisfy.

It does **not** define a particular implementation, provider, hardware architecture, storage mechanism, programming language, renderer, messaging system, or execution engine.

The governing principle is:

> **Semantic meaning is authoritative; representation, implementation, execution substrate, storage mechanism, and provider are realizations of that meaning.**

An implementation that works but violates the semantic contract is incorrect.

An incomplete implementation that accurately preserves the semantic contract is preferable to an implementation that silently changes the contract.

---

# 2. Governing Principle

The architecture is not defined by the current source code.

The semantic architecture is defined by:

* semantic definitions
* contracts
* invariants
* interfaces
* explicit architectural decisions
* validated relationships
* declared execution semantics

Agents MUST preserve the following distinctions:

```text
Specification       ≠ Implementation
Semantic Meaning    ≠ Representation
Semantic Identity   ≠ Content Identity
Domain              ≠ Provider
Provider            ≠ Adapter
Provider            ≠ Runtime
Provider            ≠ Semantic Authority
Service             ≠ Provider
Message             ≠ Stream
Stream              ≠ Transport
Transport           ≠ Messaging Semantics
Graph               ≠ Hypergraph
Filesystem          ≠ Semantic Hierarchy
Library Graph       ≠ Semantic Authority
Status              ≠ Specification
Transformation      ≠ Lowering
Rendering           ≠ Semantic Truth
Observation         ≠ Perception
Event               ≠ Observation
Action              ≠ Operation
State               ≠ Representation of State
Deletion            ≠ Erasure of History
Absence             ≠ Nonexistence
```

Agents MUST NOT collapse these distinctions merely because an implementation makes them convenient to combine.

---

# 3. Repository Boundary

The repository is divided into architectural responsibilities.

```text
lib/
    Semantic meaning and contracts

docs/
    Architectural rules and design decisions

providers/
    Concrete provider integrations

runtime/
    Executable runtime systems and infrastructure

apps/
    Applications and application-specific composition

001_agents/
    Development-agent governance and working procedures
```

The fundamental boundary is:

```text
                    SCR
                     │
          ┌──────────┴──────────┐
          │                     │
      Semantic Layer       Realization Layer
          │                     │
        lib/             providers/runtime/apps
```

`lib/` MUST NOT become a repository for arbitrary implementation code merely because that code implements a semantic concept.

---

# 4. Semantic Authority

The semantic library establishes the meaning of SCR concepts.

The general authority hierarchy is:

```text
1. Explicit project architectural decisions
2. Normative parent semantic definition
3. Normative child semantic definition
4. Explicit semantic/interface contract
5. Validated semantic tests
6. Implementation
7. Status information
8. Derived graphs
9. Examples
10. Agent assumptions
```

An agent MUST resolve ambiguity by inspecting authoritative semantic definitions before modifying implementation.

---

# 5. Library Control Documents

Each major semantic domain normally contains:

```text
<domain>/
├── 101_definition.md
├── 102_status.yaml
└── 103_library.graph.json
```

These have different purposes.

### `101_definition.md`

Defines:

* semantic meaning
* scope
* ontology
* relationships
* invariants
* contracts
* state
* transformations
* composition
* errors
* observability
* representation independence
* implementation requirements
* validation requirements

This is normative.

### `102_status.yaml`

Records engineering reality:

* implementation status
* tests
* known gaps
* blockers
* validation state
* dependencies
* provider availability
* unresolved questions

It MUST NOT redefine semantics.

### `103_library.graph.json`

Represents derived relationships between library concepts and implementation state.

It is **not** an independent source of semantic truth.

It SHOULD be generated or validated from authoritative definitions wherever practical.

---

# 6. Canonical Semantic Hypergraph

SCR's foundational computational representation is a:

> **typed, attributed, role-labelled semantic hypergraph**

The semantic hypergraph is the canonical representation of relationships between semantic entities.

At minimum it must be capable of representing:

```text
Entities
Types
Properties
Attributes
Roles
Relations
Hyperrelations
Regions
References
Representations
Patterns
Operations
Transformations
State
Deltas
Events
Streams
Provenance
Constraints
Capabilities
Contracts
Identity
```

Relationships are themselves semantic information.

A relationship involving three or more participants MUST NOT automatically be decomposed into binary edges if doing so loses semantic meaning.

---

# 7. Hypergraph Before Graph

A conventional graph is a useful semantic structure, but it is not the fundamental SCR relational model.

```text
Semantic Hypergraph
        │
        ├── Graph projection
        ├── Binary relation projection
        ├── Spatial projection
        ├── Dependency projection
        ├── Execution projection
        └── Visualization projection
```

A graph is therefore a possible representation or restriction of the canonical hypergraph.

Agents MUST NOT redesign the semantic model around graph limitations merely because a particular graph library is convenient.

---

# 8. Nullary Relations

Nullary relations are semantically meaningful where a relation has no participating object references but represents a proposition, assertion, fact, condition, or existence-bearing statement.

Agents MUST NOT assume:

```text
relation with zero participants = invalid relation
```

unless the owning semantic domain explicitly requires participants.

Nullary relation semantics MUST be defined consistently with identity, provenance, deletion, and reference semantics.

---

# 9. Identity

SCR distinguishes at least:

```text
Semantic Identity
Content Identity
Region Identity
Operation Identity
Execution Identity
Provider Identity
Artifact Identity
```

These MUST NOT be conflated.

A content identifier answers:

> What exact content is this?

A semantic identifier answers:

> What semantic entity is this?

A provider identifier answers:

> Which implementation source is this?

An execution identity answers:

> Which runtime manifestation or execution instance is this?

---

# 10. Semantic Identifiers

A Semantic Identifier (SID) does not need to be self-describing.

SID structure may be domain-specific and selected according to:

* locality
* hierarchy
* allocation
* routing
* performance
* namespace requirements
* domain semantics

The universal requirement is **root-authority verifiability**.

An SID MUST be attributable through a cryptographically verifiable delegation or allocation chain anchored in the SCR root authority.

The following are distinct:

```text
Identity
Namespace Metadata
Delegation
Allocation
Authority
Provenance
```

Self-description is optional.

Root-anchored provenance is mandatory.

---

# 11. References

A reference is not the referenced entity itself.

References MUST preserve sufficient identity and provenance to distinguish:

```text
reference to existing entity
reference to deleted entity
reference to withdrawn entity
reference to superseded entity
reference to unavailable entity
invalid reference
unresolved reference
```

Agents MUST NOT silently replace semantic references with copies of referenced data.

---

# 12. Deletion and Absence

Deletion is a semantic operation, not necessarily erasure of historical information.

SCR MUST distinguish where relevant:

```text
Never existed
Unknown
Unavailable
Not observed
Not yet available
Deleted
Withdrawn
Superseded
Invalidated
Destroyed
Hidden
Inaccessible
```

These states MUST NOT be collapsed into `null`, missing data, or an empty collection unless the owning contract explicitly defines that equivalence.

Historical provenance MAY remain valid after deletion of the current entity.

---

# 13. Semantic Field

The Semantic Field is foundational to SCR.

A Semantic Field is the computational context in which semantic entities, relationships, state, transformations, observations, and operations exist and interact.

A field is NOT synonymous with:

```text
Tensor
Array
Buffer
Texture
Grid
Database
Memory region
GPU allocation
```

Those may be representations or implementations of field state.

A semantic field may have:

```text
Identity
Domain
Topology
State
Entities
Relationships
Constraints
Capabilities
Temporal properties
Spatial properties
Provenance
Observers
Actors
Operations
Transformations
```

The semantic field is the authoritative semantic context.

---

# 14. Data

Data concerns meaningful information and its representation.

Data MUST remain distinct from:

```text
Storage
Transport
Memory
Serialization
Message
Stream
File
Buffer
```

Those are possible realizations or containers of data.

---

# 15. State

State represents the semantic condition of an entity, field, system, process, or computational space.

State MUST be distinguished from its representation.

A state transition may be represented as:

```text
S₀ → S₁
```

and may produce:

```text
ΔS
```

The delta is not automatically equivalent to the resulting state.

---

# 16. Event

An Event represents an occurrence.

An event is not necessarily:

```text
a message
an observation
a state
a stream element
a command
a transport packet
```

An occurrence may subsequently be:

```text
observed
represented
published
streamed
processed
acted upon
```

These stages MUST NOT be conflated.

---

# 17. Observation

An Observation represents information acquired or made available about something.

The absence of an observation MUST NOT automatically imply absence of the underlying phenomenon.

Observation is therefore distinct from:

```text
Event
State
Perception
Inference
Interpretation
```

---

# 18. Perception

Perception transforms available observations or information into meaningful representations or interpretations relative to an observer or computational entity.

Conceptually:

```text
Observation
    ↓
Perception
    ↓
Meaningful Representation
    ↓
Interpretation / Inference
```

Perception is observer-relative.

The semantic model MUST preserve uncertainty, ambiguity, provenance, confidence, correspondence, and competing interpretations where applicable.

---

# 19. Interaction

`605_Interaction` defines semantic interaction between actors, observers, agents, devices, computational entities, and semantic fields.

Interaction includes:

```text
Input
Observation
Gesture
Intent
Action
Control
Feedback
Interaction Session
Commitment
Cancellation
Accessibility
Multimodal Composition
```

The fundamental interaction pipeline is:

```text
Actor / Observer
        ↓
Input
        ↓
Observation
        ↓
Recognition
        ↓
Gesture
        ↓
Intent
        ↓
Action
        ↓
Transformation
        ↓
Semantic Field
        ↓
Feedback
```

A mouse, touchscreen, VR controller, camera, microphone, API, robot sensor, or physical actuator is a modality or implementation mechanism.

The semantic model is modality-independent.

---

# 20. Gesture

A Gesture is a semantic interpretation of an interaction trajectory or composition of observations.

A pointer path is not inherently a command.

Gesture recognition MAY produce:

```text
Gesture Candidate
Confidence
Trajectory
Temporal Characteristics
Spatial Characteristics
Context
Constraints
```

Gestures may compose using:

```text
A ; B       sequence
A & B       concurrent chord
A | B       alternative
A ?         optional
A *         repetition
```

Recognition and interpretation MUST remain distinguishable.

---

# 21. Action and Operation

An Action represents a semantic consequence intended or caused by interaction or agency.

An Operation represents an executable semantic capability or state transformation.

They may relate as:

```text
Intent
  ↓
Action
  ↓
Operation
  ↓
State Transformation
```

An Action is not necessarily an implementation call.

An Operation is not merely a programming-language function.

---

# 22. Stream

`802_Stream` defines the semantic organization of information, state, occurrences, or transformations as they become available or evolve through temporal, causal, ordered, partially ordered, continuous, or discrete relationships.

A Stream is NOT fundamentally:

```text
Transport
Queue
Broker
Pipeline
Socket
Message bus
File
Buffer
```

A stream may contain:

```text
Events
State Changes
Deltas
Observations
Operations
Messages
Signals
Graph Changes
Field Updates
Simulation Updates
Render Data
Telemetry
```

The semantic distinction is:

```text
Stream
    = semantic organization/evolution/availability

Message
    = representation/container of information

Messaging
    = exchange activity

Transport
    = mechanism for movement

Provider
    = implementation capability
```

A stream may exist historically or conceptually even when no current transport is active.

---

# 23. Availability

Stream semantics MUST distinguish:

```text
Occurrence
Observation
Availability
Publication
Processing
Consumption
```

For example:

```text
Occurrence      t10
Observed        t12
Processed       t13
Published       t15
Consumed        t18
```

These are different semantic events.

No element currently available to a consumer does not necessarily imply:

```text
nothing occurred
```

---

# 24. Messaging

Messaging concerns the exchange of messages between computational entities.

Messaging is distinct from Stream semantics.

```text
Semantic Stream
      ↓
Message representation
      ↓
Messaging
      ↓
Transport
      ↓
Provider / Runtime
```

AMQP may provide a realization of messaging semantics.

It does not define the semantic meaning of all SCR messages.

---

# 25. AMQP

AMQP is an implementation/protocol concern within SCR's messaging architecture.

AMQP MUST NOT become the semantic definition of:

```text
Stream
Event
Operation
Action
State
Field
Application
Service
```

SCR may use AMQP as its canonical internal messaging model where appropriate.

---

# 26. HyrxMQ

HyrxMQ is an implementation/provider system.

Its capabilities, including GPU-resident message data and GPU-oriented transport/execution mechanisms, MUST NOT become assumptions in the semantic definitions of Stream or Messaging.

The architecture remains:

```text
SCR Semantic Contract
        ↓
Messaging / Stream Semantics
        ↓
Provider Contract
        ↓
HyrxMQ
```

HyrxMQ is therefore a realization of SCR semantics, not their source.

---

# 27. Physics, Dynamics and Simulation

These concepts MUST remain distinct.

### Physics

Defines physical laws, quantities, constraints, and physical relationships.

### Dynamics

Defines how state evolves according to declared relationships and transformations.

### Simulation

Computationally realizes a model of a system or process.

Therefore:

```text
Physics ≠ Dynamics ≠ Simulation
```

A simulation MAY implement physics.

It is not itself the definition of physics.

---

# 28. Morphology

`401_Morphology` is a first-class semantic domain concerned with:

```text
Form
Structure
Organization
Pattern
Shape
Composition
Differentiation
Growth
Deformation
Emergence
Structural Transformation
```

Morphology is not merely:

```text
Image Processing
Mesh Generation
Rendering
Computer Vision
```

Its relationships include:

```text
Information
   ↕
Pattern
   ↕
Morphology
   ↕
Topology
   ↕
Geometry
   ↕
Field
   ↕
Dynamics
```

---

# 29. Spatial Semantics

`801_Spatial` defines cross-domain spatial computation.

Spatial semantics include:

```text
Coordinates
Reference Frames
Position
Direction
Orientation
Distance
Proximity
Neighbourhood
Regions
Locality
Spatial Indexing
Navigation
Spatial Queries
Computational Space
```

Geometry and Spatial semantics overlap but are not identical.

Geometry concerns spatial form and geometric relationships.

Spatial computation additionally concerns locality, organization, navigation, indexing, reference frames, and computational location.

---

# 30. Computational Space

A computational Space is a semantic object representing a bounded or structured computational environment.

A Space may expose dimensions such as:

```text
Identity
Location
Meaning
ISA
Memory
Storage
Network
Processing
Security
Capabilities
Resources
Lifecycle
```

Examples may include:

```text
Machine
Node
VM
Container
Process Space
Namespace
Device Space
Storage Space
Remote Space
```

A Space is semantic before it is an operating-system abstraction.

---

# 31. Computational Field

A Computational Field is a field containing executable or computationally active semantic structures.

It may contain:

```text
Processes
Operations
Executable Hypergraphs
State
Resources
Observers
Actors
Transformations
Messages
Streams
```

Computational Fields may exist within Computational Spaces.

Space and Field are related but distinct:

```text
Space = where computational existence is situated
Field = what semantic computational activity exists there
```

---

# 32. Rendering

`A01_Render` defines rendering as a semantic computation that produces a representation suitable for observation.

Rendering is downstream from semantic truth.

A renderer MUST NOT silently redefine:

```text
Field
Geometry
Morphology
Physics
Dynamics
Simulation
State
```

The semantic loop may be:

```text
Semantic Field
      ↓
Rendering
      ↓
Observation
      ↓
Perception
      ↓
Interaction
      ↓
Action
      ↓
Semantic Field
```

Rendering is therefore part of a broader observation/interaction loop, not merely a terminal display operation.

---

# 33. Analysis

`901_Analysis` defines cross-domain analysis.

Analysis may determine:

```text
Capabilities
Compatibility
Complexity
Cost
Dependencies
Dataflow
Determinism
Differentiability
Equivalence
Locality
Memory
Parallelism
Resources
Scheduling
Semantics
Topology
```

Analysis informs execution and transformation decisions.

It MUST NOT silently redefine semantic meaning.

---

# 34. Interfaces

`902_Interfaces` defines reusable semantic capabilities and contracts.

An interface may express:

```text
Composable
Controllable
Deterministic
Differentiable
Distributable
Dynamical
Integrable
Learnable
Observable
Optimizable
Parallelizable
Persistable
Renderable
Spatial
Stateful
Stateless
Stochastic
Streamable
Temporal
Transformable
Vectorizable
```

These are semantic contracts.

They are not merely programming-language interfaces or traits.

---

# 35. Transformations

`905_Transforms` defines cross-domain transformation semantics.

A transformation changes a computational object while declaring which semantic properties are:

```text
Preserved
Modified
Introduced
Invalidated
Approximated
Relaxed
Specialized
```

Examples include:

```text
Canonicalization
Composition
Decomposition
Differentiation
Distribution
Fusion
Parallelization
Scheduling
Specialization
Tiling
Vectorization
Representation Transformation
```

---

# 36. Lowering

`903_Lowering` concerns movement toward a lower-level representation, abstraction, or execution target.

Conceptually:

```text
SCR Semantic Model
        ↓
SCR Semantic MLIR
        ↓
Domain MLIR
        ↓
MLIR Lowering
        ↓
Target Representation
        ↓
Execution
```

Lowering is a specialized transformation.

```text
Transformation
      ⊃
   Lowering
```

Lowering MUST preserve declared semantic meaning unless an explicit approximation, relaxation, specialization, or semantic change is declared.

---

# 37. Providers

Providers are **not part of the semantic library ontology**.

They live under:

```text
providers/
```

A Provider is a concrete implementation or external capability source satisfying a semantic contract.

The canonical relationship is:

```text
Semantic Capability
        ↓
Semantic Contract
        ↓
Implementation Binding
        ↓
Executable / Adapter
        ↓
Provider
        ↓
Execution Runtime
        ↓
Computational Resource
```

A Provider answers:

> How can this semantic capability be realized?

It does not answer:

> What does this semantic capability mean?

---

# 38. Provider, Adapter, Implementation and Runtime

These concepts MUST remain distinct.

```text
Provider
    concrete capability source

Adapter
    translator between semantic contract and implementation/provider

Implementation
    executable realization of a semantic concept

Executable Artifact
    versioned executable representation

Execution Contract
    machine-interpretable execution obligations

Entry Point
    invocation target

Runtime
    system that executes artifacts

EGS
    system that resolves and orchestrates executable semantic graph requirements
```

Providers may be:

```text
Libraries
Frameworks
Engines
Databases
Services
Devices
Compilers
Accelerators
Remote Systems
Executables
WASM runtimes
SCR-native implementations
MLIR provider boundaries
```

The classification is semantic, not based solely on packaging.

---

# 39. Provider Independence

Multiple Providers may satisfy the same semantic capability.

Provider substitution requires preservation of the relevant semantic contract.

Provider substitution does NOT imply:

```text
identical implementation
identical numerical representation
identical performance
identical internal state
```

It means that the declared semantic obligations remain satisfied.

---

# 40. Provider Leakage

Provider-specific concepts MUST NOT enter normative semantic definitions merely because an implementation exposes them.

Examples of concepts that may belong to providers rather than SCR semantics include:

```text
RabbitMQ Channel
OGRE SceneNode
PhysX Actor
OpenVDB Grid Handle
CUDA Stream
GPU Buffer
CouchDB Document
Vulkan Command Buffer
```

They may be represented through adapters or implementation bindings.

They must not silently become SCR ontology.

---

# 41. Application Architecture

Applications compose semantic capabilities.

The preferred architecture is:

```text
Application
    ↓
Module
    ↓
Service
    ↓
Operation
    ↓
Implementation Binding
```

Inbound boundaries may use:

```text
Controller
    ↓
Port
    ↓
Service / Operation
```

External realization may use:

```text
Port
    ↓
Adapter
    ↓
Provider
```

This architecture is compatible with hexagonal architecture while preserving SCR semantic authority.

---

# 42. Service

A Service is a semantic computational component providing a coherent set of capabilities.

A Service is not synonymous with:

```text
HTTP service
Microservice
OS process
Provider
Class
Library
```

Its implementation may use any of these mechanisms.

---

# 43. Controller

A Controller is an inbound semantic boundary.

It receives or interprets:

```text
Observation
Event
Command
Action
Request
```

and dispatches them toward appropriate semantic operations.

A Controller is not inherently a GUI component.

---

# 44. Port

A Port defines a semantic contract between an application and an external or replaceable capability.

Ports may be:

```text
Inbound
Outbound
Execution
Observation
Interaction
Persistence
Messaging
Provider
```

The semantic contract remains independent of the concrete implementation.

---

# 45. User Interface

A User Interface is not a separate fundamental ontology.

It is a manifestation of semantic interaction.

Examples:

```text
Button
    → Action

Camera
    → Observation

Microphone
    → Observation

Robot Sensor
    → Observation

API Request
    → Observation / Command

AI Tool Invocation
    → Action

Actuator
    → Action
```

The same semantic application may therefore be manifested through:

```text
Desktop UI
Web UI
CLI
3D Interface
VR
AR
Agent Interface
API
Physical Interface
```

---

# 46. Semantic Graphs and Repository Graphs

SCR must distinguish at least:

### Semantic Hypergraph

The canonical computational semantic structure.

### Graph Projection

A graph representation derived from or restricted from semantic hypergraph structure.

### Library Architecture Graph

A representation of relationships between definitions and implementation artifacts.

### Repository/Filesystem Structure

An organizational mechanism for storing project artifacts.

These MUST NOT be treated as equivalent.

```text
Semantic Hypergraph
        │
        ├── Graph projections
        │
        └── Semantic views

Library Architecture Graph
        │
        └── Derived from repository definitions/status

Filesystem
        │
        └── Stores artifacts
```

Filesystem adjacency MUST NOT be interpreted as semantic dependency.

---

# 47. Representation Independence

A semantic object may have multiple representations.

For example:

```text
Semantic Geometry
    ├── Analytic
    ├── Polygonal
    ├── Mesh
    ├── Voxel
    ├── Implicit
    └── Procedural
```

None becomes semantic authority merely because it is currently implemented.

The same principle applies to:

```text
Fields
Graphs
Streams
Neural Models
Simulation
Rendering
Storage
Messages
Executable Artifacts
```

---

# 48. Semantic API vs Implementation API

SCR semantic APIs describe semantic capabilities.

Implementation APIs describe how those capabilities are realized.

For example:

```text
Semantic Operation
        ↓
Semantic Contract
        ↓
Implementation Binding
        ↓
Mojo / MLIR / WASM / Native / Provider API
```

An implementation API MUST NOT redefine the semantic contract.

---

# 49. MLIR

SCR is an **MLIR extension ecosystem**.

MLIR provides infrastructure for:

```text
IR
Dialects
Operations
Types
Attributes
Interfaces
Analyses
Transformations
Conversion
Lowering
Target Translation
```

SCR defines the semantic computational model represented through that infrastructure.

Therefore:

```text
SCR Semantics
      ↓
SCR Semantic MLIR
      ↓
MLIR Infrastructure
      ↓
Transform / Analysis / Lowering
      ↓
Executable Representation
```

MLIR is the canonical representation and compilation substrate.

It is not the semantic authority.

SCR SHOULD reuse established MLIR mechanisms whenever they provide an appropriate realization of SCR semantics.

---

# 50. Mojo

Mojo is the primary implementation language for SCR's native implementation.

This does not make Mojo the semantic definition language.

The distinction is:

```text
Semantic Definition
        ↓
Semantic MLIR
        ↓
Mojo Implementation
```

Where appropriate, semantic executable capabilities SHOULD be exposed through MLIR contracts and callable runtime interfaces.

---

# 51. Execution Semantics

Execution is semantic only where execution behaviour affects meaning.

Agents MUST distinguish:

```text
Semantic Ordering
Execution Ordering

Semantic Concurrency
Implementation Parallelism

Semantic State
Machine State

Semantic Locality
Memory Locality

Semantic Failure
Implementation Failure
```

An implementation detail becomes semantic only when the domain contract declares it meaningful.

---

# 52. Semantic Equivalence

Two implementations are interchangeable only when the relevant semantic equivalence has been established.

Possible equivalence classes include:

```text
Exact
Approximate
Numerical
Structural
Observational
Behavioural
Temporal
Spatial
Representation
Performance
```

Agents MUST NOT infer semantic equivalence merely from identical outputs for a limited test case.

---

# 53. Determinism

Where deterministic semantics are declared, implementation nondeterminism MUST NOT silently alter semantic behaviour.

Possible sources include:

```text
Parallelism
Scheduling
Floating-point ordering
Distributed execution
Provider behaviour
Hardware differences
Randomness
Concurrency
```

If nondeterminism is semantically meaningful, it MUST be explicitly represented.

---

# 54. Failure Semantics

Semantic failures MUST remain distinguishable where their meaning differs.

Examples:

```text
Invalid Input
Constraint Violation
Unsupported Capability
Unavailable Provider
Invalid Reference
Failed Transformation
Failed Lowering
Runtime Failure
Numerical Failure
Resource Exhaustion
Authority Failure
Security Failure
Semantic Inconsistency
```

Implementation convenience MUST NOT collapse distinct semantic failures into a generic error.

---

# 55. Provenance

Semantic entities, transformations, observations, implementations, providers, and derived representations SHOULD preserve provenance where meaningful.

Provenance may identify:

```text
Origin
Authority
Source
Transformation
Provider
Version
Time
Execution
Observation
Delegation
Derivation
```

Derived information MUST NOT be presented as original semantic authority.

---

# 56. Domain Composition

Domains compose through semantic relationships rather than filesystem hierarchy.

For example:

```text
Spatial
   ↓
Field
   ↓
Geometry / Topology
   ↓
Morphology
   ↓
Physics
   ↓
Dynamics
   ↓
Simulation
   ↓
Agent
   ↓
Perception
   ↓
Neural
   ↓
Control
   ↓
Learning / Adaptation
```

This is an example of composition, not inheritance.

A domain may:

```text
Depend on
Compose with
Constrain
Observe
Transform
Provide input to
Consume output from
```

another domain without becoming its subtype.

---

# 57. Domain-Local Concepts vs First-Class Domains

Agents MUST distinguish a local concept from a first-class semantic domain.

For example:

```text
202_Math/Optimization
```

concerns optimization as a mathematical concept.

```text
701_Optimization
```

defines optimization as an independent computational domain.

Similarly:

```text
502_Dynamics/Evolution
        ≠
704_Evolution
```

and:

```text
601_Agent/Adaptation
702_Learning/Adaptation
604_Control/Adaptive
        ≠
703_Adaptation
```

Local concepts MUST NOT automatically be promoted to first-class domains.

Promotion requires explicit semantic justification.

---

# 58. Current Library Domains

The semantic library currently includes:

```text
000_meta

101_Core
201_Data
202_Math
203_Graph

301_Field
302_Geometry
303_Topology

401_Morphology

501_Physics
502_Dynamics
503_Simulation

601_Agent
602_Neural
603_Perception
604_Control
605_Interaction

701_Optimization
702_Learning
703_Adaptation
704_Evolution
705_Ecology

801_Spatial
802_Stream

901_Analysis
902_Interfaces
903_Lowering
905_Transforms

A01_Render
```

Providers are intentionally excluded from this semantic-domain list.

They belong under the repository-level `providers/` boundary.

---

# 59. Cross-Cutting Domains

Some library domains operate across many semantic domains.

Examples include:

```text
801_Spatial
802_Stream
901_Analysis
902_Interfaces
903_Lowering
905_Transforms
A01_Render
```

These are not necessarily higher or lower in semantic authority.

They provide cross-domain semantics and capabilities.

---

# 60. `000_meta`

`000_meta` contains metadata and governance material.

It is not itself a semantic domain.

Metadata may exist at different scopes:

```text
lib/000_meta/
203_Graph/000_meta/
203_Graph/Hypergraph/000_meta/
```

The meaning of metadata is determined by its enclosing scope.

---

# 61. Domain Definition Rule

Every major semantic domain SHOULD contain:

```text
<domain>/
├── 101_definition.md
├── 102_status.yaml
└── 103_library.graph.json
```

Semantic subdomains SHOULD be represented as directories beneath their owning domain.

The filesystem hierarchy is organizational.

The semantic hierarchy is expressed through definitions and relationships.

---

# 62. Function and Capability Development

Every substantive semantic capability SHOULD follow:

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

### Describe

Identify the semantic concept.

### Specify

Define:

```text
Inputs
Outputs
State
Invariants
Constraints
Relationships
Errors
Determinism
Side Effects
Capabilities
```

### Test

Define tests expressing the intended semantics.

### Implement

Implement the declared behaviour.

### Validate

Demonstrate that implementation satisfies the semantic contract.

---

# 63. Testing Hierarchy

Testing SHOULD operate across multiple levels:

```text
Semantic Specification Tests
        ↓
Unit Tests
        ↓
Domain Tests
        ↓
Composition Tests
        ↓
MLIR Tests
        ↓
Transformation Tests
        ↓
Lowering Tests
        ↓
Runtime Tests
        ↓
Provider Conformance Tests
        ↓
Cross-Provider Tests
        ↓
System Tests
```

A passing unit test does not establish semantic correctness by itself.

---

# 64. Provider Assessment

Before implementing a capability, agents SHOULD ask:

```text
1. Does the semantic capability already exist?
2. Is there a leading implementation?
3. Is that implementation mature?
4. Can its behaviour be expressed through a clean semantic contract?
5. Can it be integrated without leaking its ontology?
6. Does SCR gain meaningful advantage by implementing it itself?
```

The governing rule is:

> **Do not build a kernel when a good kernel already exists. Build the semantic bridge that allows it to participate in SCR.**

If no suitable kernel exists, SCR MAY implement the capability itself, but it MUST expose it through a semantic contract so that a future provider can replace it.

---

# 65. Provider Canonicality

A canonical provider is a preferred or reference implementation.

Canonical does not mean exclusive.

```text
Semantic Capability
        │
   ┌────┼────┐
   ▼    ▼    ▼
Provider A  Provider B  Provider C
```

All providers remain subordinate to the same semantic contract.

---

# 66. No Silent Architecture Changes

Agents MUST NOT:

* rename semantic domains without justification
* merge domains because their names appear similar
* split domains solely because implementation is large
* move concepts without updating semantic definitions
* redefine terminology locally
* make a provider semantically authoritative
* introduce provider-specific ontology into normative definitions
* infer semantics from filesystem structure
* create a second competing graph authority
* introduce persistence assumptions into semantic definitions
* introduce hardware-specific assumptions into semantic definitions
* silently change identity semantics
* collapse absence and deletion
* collapse references into copied values
* collapse observations into perceptions
* collapse streams into transports
* collapse messages into events
* collapse providers into services
* treat implementation convenience as semantic authority

Architectural changes MUST be explicitly documented.

---

# 67. Repository Inspection Rule

Before modifying an unfamiliar semantic area, an agent MUST inspect:

```text
1. Relevant 101_definition.md
2. Parent domain definition
3. Relevant sibling definitions
4. Relevant interfaces
5. Relevant contracts
6. Existing implementation
7. Tests
8. Status information
9. Transform relationships
10. Lowering relationships
11. Provider relationships
12. Runtime relationships
```

Agents MUST NOT modify a semantic definition based solely on its filename or current implementation.

---

# 68. Status Discipline

Implementation status MUST be evidence-based.

The preferred progression is:

```text
Concept
   ↓
Specified
   ↓
Tested
   ↓
Implemented
   ↓
Validated
   ↓
Integrated
   ↓
Production Ready
```

Presence in the filesystem does not imply implementation.

Presence of `101_definition.md` proves specification exists.

It does not prove implementation exists.

---

# 69. Completeness

A mature semantic domain SHOULD contain:

```text
101_definition.md
102_status.yaml
Semantic Model
Invariants
Identity Semantics
Reference Semantics
Composition Rules
Interfaces
Error Semantics
Implementation
Tests
MLIR Representation
Transformations
Lowerings
Provider Strategy
Validation
Provenance
Documentation
```

Not every domain requires every item immediately.

`102_status.yaml` MUST identify what remains incomplete.

---

# 70. Definition of Done

For a new semantic capability:

```text
[ ] Semantic concept identified
[ ] Owning domain identified
[ ] Existing concepts searched
[ ] Semantic definition updated
[ ] Identity semantics considered
[ ] Reference semantics considered
[ ] Nullary relation semantics considered
[ ] Deletion / absence semantics considered
[ ] Semantic relationships defined
[ ] Invariants defined
[ ] Interfaces identified
[ ] Inputs / outputs defined
[ ] State defined
[ ] Error semantics defined
[ ] Tests specified
[ ] Implementation completed
[ ] MLIR representation considered
[ ] Transformations considered
[ ] Lowering considered
[ ] Provider strategy assessed
[ ] Validation completed
[ ] Status updated
[ ] Derived library graph regenerated
```

---

# 71. Semantic Promotion Rule

A concept SHOULD become a first-class semantic-library concept only when it satisfies a meaningful semantic need.

Before introducing a new concept, an agent MUST ask:

```text
Does this already exist?

If yes:
    Can the existing concept express the requirement?

If no:
    Is the difference semantically fundamental?

If yes:
    Which domain owns it?

Does it require:
    identity?
    invariants?
    relationships?
    state?
    contracts?
    independent composition?
```

Implementation convenience alone is insufficient justification for semantic promotion.

---

# 72. Adaptive Execution

SCR is intended to support adaptive execution.

Execution decisions may depend on:

```text
Semantic Requirements
Capabilities
Data Characteristics
Topology
Locality
Memory
Parallelism
Hardware
Provider Availability
Runtime State
Resource Constraints
Performance
Telemetry
```

Execution is therefore not necessarily a fixed compilation pipeline.

A runtime may perform:

```text
Analyze
   ↓
Transform
   ↓
Lower
   ↓
Resolve Provider
   ↓
Execute
   ↓
Observe
   ↓
Re-analyze
   ↓
Reconfigure
```

These execution mechanisms MUST remain subordinate to semantic contracts.

---

# 73. EGS and the Semantic Library

The Executable Graph Server (EGS) operates on the executable semantic graph.

From the SCR perspective:

> **EGS sees hypergraphs and identifiers.**

Applications and providers may internally use:

```text
Mojo
MLIR
WASM
Native Code
GPU APIs
Libraries
Frameworks
Operating-System Facilities
Remote Services
```

These implementation details do not replace the canonical semantic graph.

EGS resolves semantic requirements into executable realizations.

---

# 74. Semantic Machine Model

The Semantic Machine Model provides semantic descriptions of computational environments.

A computational machine or space may expose:

```text
Identity
ISA
Processing
Memory
Storage
Network
Location
Capabilities
Resources
Security
Lifecycle
Meaning
```

This allows SCR to reason about:

```text
Machine
Node
VM
Container
Process
Namespace
Device
Storage
Remote Space
```

as semantic computational objects rather than merely infrastructure abstractions.

---

# 75. Runtime and Library Separation

The semantic library describes what runtime entities mean.

The runtime implements those meanings.

Therefore:

```text
lib/
    What it means

runtime/
    How it executes

providers/
    How specialized capabilities are supplied

apps/
    How capabilities are composed into applications
```

The runtime MUST NOT silently become the semantic definition of the library.

---

# 76. Reference Integration Pattern

A representative cross-domain computation may look like:

```text
Semantic Field
      ↓
Spatial / Geometry / Topology
      ↓
Morphology
      ↓
Physics
      ↓
Dynamics
      ↓
Simulation
      ↓
Agent
      ↓
Perception
      ↓
Neural
      ↓
Control
      ↓
Learning / Adaptation
      ↓
Interaction
      ↓
Action
      ↓
Semantic Field
```

Rendering and streaming may provide observation and communication pathways:

```text
Semantic Field
      │
      ├── Rendering → Observation → Perception
      │
      └── Stream → Messaging → External Computational Entity
```

The example is a composition pattern, not a mandatory execution sequence.

---

# 77. Architectural Invariants

The following principles are mandatory:

```text
LIB-001  Semantic meaning is authoritative.
LIB-002  The canonical semantic structure is a hypergraph.
LIB-003  Graphs are not automatically semantic authority.
LIB-004  Filesystem hierarchy does not define semantic hierarchy.
LIB-005  Providers are not semantic authorities.
LIB-006  Provider implementations live outside lib/.
LIB-007  Semantic definitions remain implementation-independent.
LIB-008  Representation does not define ontology.
LIB-009  Identity and content identity remain distinct.
LIB-010  References remain distinct from referenced entities.
LIB-011  Deletion does not imply historical erasure.
LIB-012  Absence does not imply nonexistence.
LIB-013  Nullary relations remain semantically representable.
LIB-014  Stream semantics remain distinct from transport.
LIB-015  Messaging remains distinct from stream semantics.
LIB-016  Observation remains distinct from perception.
LIB-017  Event remains distinct from observation.
LIB-018  Action remains distinct from operation.
LIB-019  Physics, dynamics and simulation remain distinct.
LIB-020  Rendering does not redefine semantic truth.
LIB-021  MLIR is a representation/compilation substrate, not semantic authority.
LIB-022  Transformations must declare semantic effects.
LIB-023  Lowering is a specialized transformation.
LIB-024  Provider substitution requires semantic conformance.
LIB-025  Status does not redefine specification.
LIB-026  Derived graphs do not redefine specification.
LIB-027  Semantic interfaces are not merely language interfaces.
LIB-028  Execution behaviour becomes semantic only where explicitly declared.
LIB-029  Nondeterminism must be explicit where semantics require determinism.
LIB-030  Provider-specific ontology must not leak into normative semantics.
LIB-031  Domain composition must be semantic rather than filesystem-derived.
LIB-032  New semantic concepts require explicit ownership and justification.
```

---

# 78. Final Agent Principle

When implementing SCR, an agent must continuously ask:

```text
What does this mean?
        ↓
Which semantic domain owns that meaning?
        ↓
What is the canonical semantic representation?
        ↓
What invariants must hold?
        ↓
What contract expresses those invariants?
        ↓
What representation expresses the contract?
        ↓
What implementation realizes it?
        ↓
What provider supplies specialized capability?
        ↓
What runtime executes it?
```

Never reverse that reasoning merely because an implementation already exists.

The governing principle of the SCR semantic library is:

> **Define meaning first. Define the contract second. Choose the realization third.**

And:

> **The semantic model is the architecture. The implementation is a realization of that architecture.**
