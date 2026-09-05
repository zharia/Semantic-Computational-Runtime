# Program Increment v0.0.1

## AI Agent Instructions

This document defines the operating rules for AI coding agents working on **Program Increment v0.0.1** of the Semantic Computational Runtime (SCR).

The purpose of this document is not merely to tell an agent where files are located. It defines how an agent must reason about the semantic library, how it must distinguish specification from implementation, and how it must avoid accidentally changing the architecture while attempting to implement it.

---

# 1. Purpose

SCR is being developed as a semantic computational runtime built on MLIR.

The central architectural principle is:

> **Semantic meaning is authoritative; representation, implementation, execution substrate, and storage mechanism are not.**

AI agents must therefore treat the repository as a semantic system first and a software repository second.

An implementation that works but violates the semantic contract is incorrect.

An implementation that is incomplete but accurately reflects the semantic contract is preferable to an implementation that silently changes the contract.

---

# 2. Governing Principle

The most important rule for all agents is:

> **The code is not the architecture.**

The architecture is expressed through semantic definitions, contracts, interfaces, invariants, and explicitly accepted design decisions.

The following distinctions MUST remain intact:

```text
Specification ≠ Implementation
Status ≠ Specification
Graph ≠ Source of Truth
Provider ≠ Semantic Authority
Backend ≠ Semantic Meaning
Representation ≠ Concept
Transformation ≠ Lowering
Domain ≠ Implementation
Filesystem Hierarchy ≠ Semantic Hierarchy
```

---

# 3. Source-of-Truth Hierarchy

When sources disagree, agents MUST resolve the conflict using the following order:

```text
1. Project-level architectural decisions
2. Normative parent semantic definition
3. Normative child semantic definition
4. Explicit interface / contract specification
5. Tests expressing normative behaviour
6. Current implementation
7. Comments
8. Examples and documentation
9. Agent assumptions
```

`102_status.yaml` is **not** a semantic authority.

It records engineering state and evidence about implementation.

`103_library.graph.json` is **not** a semantic authority.

It is a derived representation of relationships between definitions and implementation state.

Therefore:

```text
101_definition.md
        │
        ▼
 Semantic Contract
        │
        ├───────────────┐
        ▼               ▼
 Implementation      Tests
        │               │
        └───────┬───────┘
                ▼
            Validation
                │
                ▼
        102_status.yaml
        (records evidence)
                │
                ▼
      103_library.graph.json
          (derived graph)
```

The graph MUST NOT become a second source of architectural truth.

---

# 4. Program Increment Control Plane

The Program Increment control plane consists of three complementary artifacts.

```text
101_definition.md
    = what the domain means

102_status.yaml
    = where implementation currently stands

103_library.graph.json
    = how the library relates as a whole
```

## 4.1 `101_definition.md`

A normative semantic definition.

It defines:

* domain meaning
* scope
* semantic model
* invariants
* composition
* relationships
* interfaces
* inputs and outputs
* state
* transformations
* errors
* observability
* implementation independence
* MLIR representation
* runtime semantics
* validation requirements
* testing requirements
* completeness criteria

The definition MUST describe what the domain means independently of its current implementation.

---

## 4.2 `102_status.yaml`

A mutable engineering-state document.

It records facts such as:

* implementation status
* completed components
* missing components
* tests
* known gaps
* blockers
* validation state
* provider availability
* lowering availability
* implementation notes
* dependencies
* outstanding semantic questions

Status MUST describe reality.

It MUST NOT redefine the semantic contract.

---

## 4.3 `103_library.graph.json`

The library graph is a **derived aggregate representation** of the semantic library.

It should describe relationships such as:

```text
Core
  ↓
Data
  ↓
Fields / Graphs / Geometry / Topology
  ↓
Morphology / Physics / Dynamics
  ↓
Simulation / Agents / Perception / Control
  ↓
Optimization / Learning / Adaptation / Evolution / Ecology
```

and cross-cutting relationships such as:

```text
Analysis
Interfaces
Lowering
Providers
Transforms
Spatial
Stream
Render
```

The graph SHOULD be generated from authoritative definitions and status information wherever practical.

Agents MUST NOT manually modify the aggregate graph merely to make it agree with an implementation.

---

# 5. Current Library Structure

The current `lib/` hierarchy contains **700 directories and 33 files**.

The top-level organization is:

```text
lib/
├── 000_meta
├── 101_Core
├── 201_Data
├── 202_Math
├── 203_Graph
├── 301_Field
├── 302_Geometry
├── 303_Topology
├── 401_Morphology
├── 501_Physics
├── 502_Dynamics
├── 503_Simulation
├── 601_Agent
├── 602_Neural
├── 603_Perception
├── 604_Control
├── 701_Optimization
├── 702_Learning
├── 703_Adaptation
├── 704_Evolution
├── 705_Ecology
├── 801_Spatial
├── 802_Stream
├── 901_Analysis
├── 902_Interfaces
├── 903_Lowering
├── 904_Providers
├── 905_Transforms
├── A01_Render
├── lib.txt
└── README.md
```

This hierarchy is intentional.

It should not be interpreted as a simple linear inheritance hierarchy.

---

# 6. Library Taxonomy

The library currently contains several different kinds of semantic organization.

## 6.1 Foundational semantic domains

```text
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
701_Optimization
702_Learning
703_Adaptation
704_Evolution
705_Ecology
```

These define major semantic computational domains.

They are not necessarily a strict inheritance chain.

A domain may depend on, compose with, constrain, specialize, or interact with another domain without being a subtype of it.

---

## 6.2 Cross-cutting computational domains

```text
801_Spatial
802_Stream
901_Analysis
902_Interfaces
903_Lowering
904_Providers
905_Transforms
A01_Render
```

These are intentionally different from the primary semantic-domain sequence.

They describe capabilities, computational mechanisms, execution relationships, or cross-domain concerns that apply across multiple semantic domains.

For example:

```text
Fields ───────────────┐
Geometry ─────────────┤
Graphs ───────────────┤
Morphology ───────────┤
Physics ──────────────┤
Simulation ───────────┤
Agents ───────────────┤
                       ▼
                    Analysis
```

Similarly:

```text
Semantic Domain
      │
      ▼
   Interface
      │
      ▼
   Analysis
      │
      ▼
 Transformation
      │
      ├── specialization
      ├── optimization
      ├── distribution
      ├── vectorization
      ├── tiling
      ├── scheduling
      └── lowering
```

---

# 7. `000_meta`

`000_meta` contains metadata, governance, or explanatory material associated with a scope.

It is **not itself a semantic computational domain**.

Metadata MAY occur at different scopes.

For example:

```text
lib/
└── 000_meta/

203_Graph/
└── Hypergraph/
    └── 000_meta/
```

Agents MUST therefore not assume that every `000_meta` directory represents the same semantic level.

The meaning of metadata is determined by the scope in which it occurs.

---

# 8. Domain Definitions

A directory containing a major semantic domain SHOULD contain:

```text
<domain>/
├── 101_definition.md
└── <semantic subdomains>/
```

The `101_definition.md` defines the domain as a whole.

Subdirectories represent semantic subdivisions, not necessarily independent top-level library domains.

For example:

```text
202_Math/
├── 101_definition.md
├── Algebra/
├── Calculus/
├── Differential/
├── Optimization/
├── Probability/
├── Statistics/
├── Symbolic/
└── ...
```

The presence of:

```text
202_Math/Optimization
```

does not conflict with:

```text
701_Optimization
```

These represent different semantic scopes.

The former concerns optimization as a mathematical concept.

The latter defines optimization as a first-class SCR computational domain.

The same principle applies throughout the library.

---

# 9. Local Concepts vs First-Class Domains

Agents MUST distinguish between:

### Domain-local concept

A concept needed to express another domain.

Example:

```text
502_Dynamics/Evolution
```

This concerns evolution as a property or concept of dynamical systems.

### First-class semantic domain

A domain with its own independent semantic contract.

Example:

```text
704_Evolution
```

This defines evolutionary computation/change across populations, lineages, generations, variation, inheritance, selection, and differential persistence.

Therefore:

```text
Dynamics/Evolution
        ≠
Evolution
```

Likewise:

```text
Agent/Adaptation
Learning/Adaptation
Control/Adaptive
        ≠
703_Adaptation
```

The specialized forms are domain-local manifestations.

`703_Adaptation` defines adaptation as a general semantic computational domain.

---

# 10. Core Semantic Model

SCR's foundational relational structure is a typed, attributed, role-labelled semantic hypergraph.

At minimum, the model supports:

```text
Nodes
Hyperedges
Roles
Attributes
Types
Properties
Relations
Regions
References
Representations
Patterns
Transformations
Operations
State
Deltas
Events
Streams
Provenance
Constraints
Capabilities
Contracts
```

Relationships themselves are semantic information.

A higher-order relationship MUST NOT be reduced to pairwise relationships when doing so loses meaning.

---

# 11. Semantic Identity

Agents MUST distinguish:

```text
Semantic Identity
Content Identity
Graph/Region Identity
Operation Identity
```

These identities have different purposes.

A content identifier identifies content.

A semantic identifier identifies what something means.

A graph-region identity identifies a semantic region.

An operation identity identifies an operation or state transition.

These MUST NOT be conflated.

---

# 12. Representation Independence

A semantic object may have multiple representations.

For example:

```text
Semantic Geometry
    ├── analytic representation
    ├── polygonal representation
    ├── mesh representation
    ├── voxel representation
    ├── implicit representation
    └── procedural representation
```

None of these representations automatically becomes the semantic authority.

The same principle applies to:

* fields
* graphs
* morphology
* neural models
* simulations
* rendering
* streams
* data
* physical models

---

# 13. Fields

A field is not merely an array.

A field is meaningful information distributed over a defined domain.

Its semantics may include:

```text
Domain
Value Space
Coordinates
Topology
Sampling
Interpolation
Resolution
Boundary Conditions
Temporal Semantics
Uncertainty
Provenance
```

Therefore:

```text
Field ≠ Tensor
Field ≠ Buffer
Field ≠ Texture
Field ≠ Grid
```

Those may be representations or implementations of a field.

---

# 14. Graphs and Hypergraphs

Graphs are semantic computational structures.

The graph domain includes:

```text
Nodes
Edges
Hyperedges
Paths
Connectivity
Topology
Traversal
Matching
Query
Transformation
Embedding
Algorithms
Dynamic State
Streams
Deltas
```

The foundational hypergraph model belongs to Core.

`203_Graph` develops graph semantics as a computational domain.

The two MUST NOT be collapsed.

---

# 15. Morphology

Morphology is a first-class semantic domain.

It concerns:

* form
* structure
* organization
* differentiation
* composition
* parts and wholes
* pattern
* shape
* growth
* deformation
* emergence
* structural transformation

A key architectural principle is the bidirectional relationship:

```text
Pattern
   │
   ▼
Morphological Interpretation
   │
   ▼
Morphological Structure
   │
   ▼
Structural Analysis
   │
   ▼
Pattern
```

Morphology is therefore not merely mesh generation or rendering.

It connects:

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
Fields
   ↕
Dynamics
```

---

# 16. Spatial Semantics

`801_Spatial` is a cross-cutting spatial computational domain.

It includes concepts such as:

```text
Coordinates
Coordinate Systems
Reference Frames
Position
Direction
Orientation
Distance
Proximity
Neighbourhood
Regions
Spatial Indexing
Navigation
Pathfinding
Geofencing
H3
BVH
R-tree
KD-tree
Octree
Voxel
```

Spatial semantics MUST remain distinct from geometry.

Geometry concerns spatial form and geometric relationships.

Spatial computation also includes locality, indexing, navigation, reference frames, spatial queries, and organization of computational space.

---

# 17. Streams

`802_Stream` defines stream-oriented computation.

Streams are not merely transport mechanisms.

They may represent:

```text
Events
Signals
Messages
State Changes
Deltas
Observations
Fields
Graph Changes
Simulation Updates
Render Data
Telemetry
```

The distinction between:

```text
Semantic Stream
Transport
Messaging Provider
Storage
```

MUST be maintained.

AMQP or another messaging technology may provide an implementation or transport mechanism.

It does not define the semantic meaning of the stream.

---

# 18. Analysis

`901_Analysis` provides cross-domain analytical capabilities.

Analysis may determine:

```text
Capabilities
Compatibility
Complexity
Cost
Dataflow
Dependencies
Determinism
Differentiability
Equivalence
Geometry
Locality
Memory
Parallelism
Representation
Resources
Scheduling
Semantics
Topology
```

Analysis informs transformation and execution decisions.

It MUST NOT silently redefine semantics.

---

# 19. Interfaces

`902_Interfaces` defines reusable semantic capabilities and contracts.

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

Interfaces MUST express semantic capability or contract.

They are not merely language-level interfaces or C++/Rust traits.

Implementation interfaces may realize semantic interfaces, but the semantic contract remains authoritative.

---

# 20. Transformations

`905_Transforms` defines cross-cutting transformations.

A transformation changes some aspect of a computational object while preserving or intentionally modifying explicitly declared semantic properties.

Transformations include:

```text
Canonicalization
Composition
Decomposition
Differentiation
Distribution
Fusion
Hardware Adaptation
Memory Transformation
Parallelization
Representation Transformation
Scheduling
Specialization
Tiling
Vectorization
Lowering
```

A transformation MUST declare what semantic properties it preserves, modifies, introduces, or invalidates.

---

# 21. Transformation vs Lowering

Transformation is the broader concept.

```text
Transformation
├── Representation
├── Canonicalization
├── Composition
├── Decomposition
├── Differentiation
├── Distribution
├── Fusion
├── Memory
├── Parallelization
├── Scheduling
├── Specialization
├── Tiling
├── Vectorization
└── Lowering
```

Lowering is a specialized transformation concerned with moving a computation toward a lower-level representation, abstraction, or execution target.

Therefore:

```text
Transformation ⊃ Lowering
```

but:

```text
Transformation ≠ Lowering
```

This distinction is especially important in the MLIR integration.

MLIR's Transform dialect provides infrastructure for controlling and orchestrating transformations over payload IR, while MLIR Dialect Conversion provides mechanisms for converting operations toward declared legal targets. SCR's semantic definition of transformation remains above these implementation mechanisms.

---

# 22. Lowering

`903_Lowering` concerns transformations toward lower-level computational representations.

Examples include:

```text
High-level semantic IR
        ↓
Domain-specific MLIR dialect
        ↓
Tensor / Linalg / SCF / Vector
        ↓
MemRef / GPU / SPIR-V / LLVM
        ↓
Target representation
        ↓
Hardware / Runtime
```

Lowering MUST preserve declared semantic meaning unless the transformation explicitly declares an approximation, relaxation, specialization, or other semantic change.

MLIR itself supports progressive lowering through multiple dialects, reinforcing the distinction between semantic abstraction levels and target representations.

---

# 23. Providers

`904_Providers` defines implementation-provider relationships.

Providers may include:

```text
CPU
GPU
Accelerator
Distributed
External
Geometry
Messaging
Neural
Numerical
Physics
Rendering
Spatial
Storage
```

A provider answers:

> How can this semantic capability be realized?

It does not answer:

> What does this semantic capability mean?

Therefore:

```text
Semantic Contract
        │
        ▼
Capability Analysis
        │
        ▼
Provider Selection
        │
        ▼
Implementation
        │
        ▼
Execution
```

Multiple providers may implement the same semantic capability.

---

# 24. Rendering

`A01_Render` is a semantic rendering domain.

Rendering is not merely an output side effect.

It may involve:

```text
Scene
Geometry
Morphology
Camera
Lighting
Materials
Visibility
Projection
Rasterization
Ray Tracing
Path Tracing
Particles
Volumes
Textures
Render Targets
Render Passes
Frames
Streams
GPU Computation
```

Rendering remains downstream from semantic truth.

A renderer MUST NOT silently redefine simulation, geometry, morphology, field, or physical semantics.

An implementation may use a path such as:

```text
Semantic Runtime
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

This is an implementation path, not a semantic dependency.

---

# 25. MLIR

SCR is built **on top of MLIR**.

MLIR provides compiler infrastructure for:

* intermediate representation
* dialects
* operations
* types
* attributes
* interfaces
* transformations
* analyses
* conversion
* lowering
* target translation

SCR provides the semantic computational model that determines what those representations mean.

Therefore:

```text
SCR Semantic Model
        ↓
SCR Semantic IR
        ↓
MLIR
        ↓
MLIR Transformations / Lowering
        ↓
Target IR
        ↓
Execution
```

MLIR infrastructure MUST NOT silently become the semantic authority for SCR.

Conversely, SCR SHOULD reuse MLIR mechanisms wherever those mechanisms provide an appropriate realization of an SCR concept.

---

# 26. Semantic Graph vs Filesystem

The filesystem is an organizational mechanism.

The semantic architecture is a graph.

For example:

```text
Filesystem:

201_Data/
203_Graph/
301_Field/
302_Geometry/
401_Morphology/


Semantic relationships:

Fields ────────────────┐
                       │
Graphs ────────────────┤
                       ▼
                   Morphology
                       │
             ┌─────────┼─────────┐
             ▼         ▼         ▼
          Geometry  Topology   Fields
             │         │         │
             └─────────┼─────────┘
                       ▼
                    Dynamics
```

Agents MUST NOT infer semantic relationships solely from filesystem adjacency.

The filesystem organizes definitions.

The semantic graph expresses relationships.

---

# 27. Function Development Lifecycle

Every substantive function or capability SHOULD progress through:

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

## Describe

Identify the semantic concept.

## Specify

Define:

* inputs
* outputs
* state
* invariants
* constraints
* errors
* determinism
* side effects
* capabilities
* relationships

## Test

Write tests that express expected semantics.

## Implement

Implement the specified behaviour.

## Validate

Verify implementation against the semantic contract.

---

# 28. Testing Hierarchy

Testing SHOULD progress through multiple semantic levels:

```text
Specification Tests
        ↓
Unit Tests
        ↓
Domain Tests
        ↓
Composition Tests
        ↓
MLIR Tests
        ↓
Lowering Tests
        ↓
Runtime Tests
        ↓
Cross-Provider Tests
        ↓
Cross-Substrate Tests
```

A passing unit test does not establish semantic correctness by itself.

---

# 29. Progressive Abstraction

SCR development follows:

```text
Concept
   ↓
Semantic Contract
   ↓
Semantic IR
   ↓
Generic Implementation
   ↓
Transformation
   ↓
Lowering
   ↓
Provider
   ↓
Execution Substrate
```

These layers MUST remain distinguishable.

An optimization must not become a semantic definition.

A provider must not become an API contract.

A hardware limitation must not silently become a domain invariant.

---

# 30. Semantic Equivalence

Two implementations MAY be treated as interchangeable only when the relevant semantic equivalence has been established.

Equivalence may concern:

```text
Exact Semantics
Approximate Semantics
Numerical Tolerance
Structural Equivalence
Observational Equivalence
Behavioural Equivalence
Representation Equivalence
Performance Equivalence
```

Agents MUST NOT assume:

```text
same output
```

means:

```text
same semantics
```

unless the relevant domain contract establishes that equivalence.

---

# 31. Determinism and Nondeterminism

Where a domain declares deterministic behaviour, implementations MUST preserve it unless explicitly authorized otherwise.

Sources of nondeterminism may include:

* parallel execution
* floating-point reduction ordering
* scheduling
* distributed execution
* stochastic algorithms
* provider-specific behaviour
* hardware differences

Nondeterminism MUST be explicit.

---

# 32. Errors and Failure Semantics

Errors are semantic outputs where appropriate.

Agents MUST distinguish:

```text
Invalid Input
Constraint Violation
Unsupported Capability
Unavailable Provider
Failed Transformation
Failed Lowering
Runtime Failure
Numerical Failure
Resource Exhaustion
Semantic Inconsistency
```

Do not collapse semantically distinct failure modes merely because the implementation language makes that convenient.

---

# 33. Performance Semantics

Performance MUST NOT silently redefine semantic behaviour.

Optimization may alter:

```text
Execution Order
Memory Layout
Parallelism
Scheduling
Representation
Provider
Hardware Target
```

provided the declared semantic contract is preserved.

Performance requirements that affect semantic correctness MUST be explicitly documented.

---

# 34. External Libraries

External libraries are providers or implementation mechanisms.

They are not semantic authorities.

Examples may include:

```text
Numerical Libraries
Physics Engines
Geometry Libraries
Graph Libraries
Neural Frameworks
Rendering Engines
Messaging Systems
Storage Systems
Spatial Libraries
```

The architecture is:

```text
SCR Semantic Contract
        ↓
Provider Interface
        ↓
External Implementation
```

Never:

```text
External Library
        ↓
SCR Semantic Definition
```

An external dependency MUST NOT dictate the SCR semantic model merely because it is convenient to integrate.

---

# 35. Standards Reuse

SCR SHOULD reuse established open standards wherever an applicable standard exists and can express the required semantics without unacceptable semantic loss.

Potential standards include:

```text
URI / IRI
JSON / JSON-LD
CBOR
RDF / RDF-star
SHACL
OWL / RDFS
ISO GQL
ISO 8601
RFC 3339
UCUM
OGC standards
EPSG spatial references
glTF
GeoJSON
WKT / WKB
Parquet
ONNX
WASM
COSE / JOSE
```

Standards provide interoperability mechanisms.

They do not automatically become SCR's semantic authority.

---

# 36. Repository Inspection Rules

Before modifying an unfamiliar area, an agent MUST inspect:

1. the relevant `101_definition.md`
2. parent domain definition
3. relevant sibling definitions
4. relevant interfaces
5. existing implementation
6. tests
7. status information
8. transformation/lowering/provider relationships

Agents MUST NOT modify a file based solely on its filename.

---

# 37. No Silent Architecture Changes

Agents MUST NOT:

* rename semantic domains without justification
* merge domains because they appear similar
* split domains merely because implementation is large
* move concepts between domains without updating definitions
* redefine terminology locally
* introduce implementation-specific semantics into normative definitions
* replace semantic relationships with filesystem relationships
* make a provider authoritative
* introduce a new serialization format merely for convenience
* introduce persistence assumptions into the semantic model
* introduce hardware-specific assumptions into domain semantics

Architectural changes require explicit documentation.

---

# 38. Current Structural Ambiguities

The following situations require care rather than automatic cleanup.

## 38.1 Dynamics Evolution vs Evolution

```text
502_Dynamics/Evolution
704_Evolution
```

These are intentionally distinguishable.

`502_Dynamics/Evolution` concerns evolution of dynamical state.

`704_Evolution` concerns population, lineage, inheritance, variation, selection, and evolutionary change.

Do not merge them.

---

## 38.2 Local Optimization vs Optimization Domain

```text
202_Math/Optimization
701_Optimization
```

The first concerns mathematical optimization.

The second defines optimization as an SCR computational domain.

---

## 38.3 Specialized Adaptation vs General Adaptation

```text
601_Agent/Adaptation
702_Learning/Adaptation
604_Control/Adaptive
703_Adaptation
```

The first three are specialized manifestations.

`703_Adaptation` is the general semantic domain.

---

## 38.4 Transform vs Lowering

```text
905_Transforms
903_Lowering
```

Lowering is a specialized transformation class.

The two MUST remain architecturally distinct.

---

## 38.5 Domain-local Transformations

Many domains contain their own transformation concepts:

```text
101_Core/Transforms
202_Math/Transforms
302_Geometry/Transform
303_Topology/Transformation
401_Morphology/Transformation
801_Spatial/Transformations
802_Stream/Transform
A01_Render/Transform
```

These are domain-specific transformation semantics.

`905_Transforms` defines cross-domain transformation mechanisms and classifications.

---

# 39. Required Agent Behaviour

Agents SHOULD:

* inspect before modifying
* prefer small coherent changes
* preserve existing semantics
* update definitions when semantics change
* update tests when behaviour changes
* update status when implementation state changes
* preserve provenance
* distinguish normative and descriptive information
* use existing abstractions before introducing new ones
* reuse established standards
* favour semantic composition over duplication
* document unresolved questions rather than inventing answers

Agents MUST NOT:

* guess missing architecture
* silently invent semantics
* treat TODOs as specifications
* treat implementation convenience as architectural authority
* duplicate an existing concept without checking its semantic scope
* collapse distinct abstractions merely because they have similar names

---

# 40. Status Discipline

Implementation status MUST be evidence-based.

Preferred status progression:

```text
concept
  ↓
specified
  ↓
tested
  ↓
implemented
  ↓
validated
  ↓
integrated
  ↓
production-ready
```

A domain being present in the filesystem does not imply that it is implemented.

A `101_definition.md` proves specification exists.

It does not prove implementation exists.

---

# 41. Completeness Criteria

A semantic domain is not considered complete merely because its directory exists.

A mature domain SHOULD have:

```text
101_definition.md
102_status.yaml
Semantic Model
Invariants
Interfaces
Composition Rules
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

Not every domain will require every item immediately.

Status MUST explicitly identify what is missing.

---

# 42. Definition of Done

For a new semantic capability:

```text
[ ] Semantic concept identified
[ ] Parent domain identified
[ ] 101_definition.md updated
[ ] Semantic model defined
[ ] Invariants defined
[ ] Relationships defined
[ ] Interfaces identified
[ ] Inputs/outputs defined
[ ] Error semantics defined
[ ] Tests specified
[ ] Implementation completed
[ ] MLIR representation considered
[ ] Transformations considered
[ ] Lowering considered
[ ] Provider strategy considered
[ ] Validation completed
[ ] 102_status.yaml updated
[ ] Library graph regenerated
```

---

# 43. Program Increment Workflow

The recommended workflow is:

```text
                    ┌──────────────────────┐
                    │ Semantic Definition  │
                    │ 101_definition.md    │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Semantic Contract    │
                    └──────────┬───────────┘
                               │
                ┌──────────────┼──────────────┐
                ▼              ▼              ▼
          Implementation     Tests        MLIR Model
                │              │              │
                └──────────────┼──────────────┘
                               ▼
                         Validation
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Engineering Status   │
                    │ 102_status.yaml      │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Derived Library Graph│
                    │ 103_library.graph    │
                    └──────────────────────┘
```

This is a control-plane workflow, not a runtime execution pipeline.

---

# 44. Runtime Architecture

At runtime, the conceptual flow is different:

```text
Application
     ↓
Semantic Model
     ↓
Semantic IR
     ↓
Analysis
     ↓
Transformation
     ↓
Lowering
     ↓
Provider Selection
     ↓
Scheduling
     ↓
Execution
     ↓
Observation / Telemetry
     ↓
Re-analysis
```

The runtime MAY dynamically revisit transformation, provider, scheduling, or execution decisions.

---

# 45. Adaptive Execution

SCR is intended to support execution decisions based on:

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

This means execution is not necessarily a fixed compilation pipeline.

It may become:

```text
Analyze
   ↓
Transform
   ↓
Lower
   ↓
Select Provider
   ↓
Execute
   ↓
Observe
   ↓
Re-analyze
   ↓
Reconfigure
```

This is particularly important for adaptive, distributed, streaming, simulation, neural, and heterogeneous workloads.

---

# 46. Reference Computational Workload

A useful integration workload should exercise several domains simultaneously.

For example:

```text
Spatial Environment
       ↓
Fields
       ↓
Topology / Geometry
       ↓
Morphology
       ↓
Physics
       ↓
Dynamics
       ↓
Agents
       ↓
Perception
       ↓
Neural Computation
       ↓
Control
       ↓
Learning / Adaptation
       ↓
Evolution / Ecology
       ↓
Simulation
       ↓
Rendering
       ↓
Stream / Messaging
```

The important property is not the example itself.

The important property is that each domain retains its semantic identity while composing with the others.

---

# 47. AI Agent Decision Rule

When uncertain about an implementation, an agent should ask:

### 1. What semantic concept am I implementing?

If the answer is unclear, stop and inspect the relevant definition.

### 2. Which domain owns the concept?

Do not introduce a new abstraction before determining whether the concept already exists elsewhere.

### 3. What does the semantic contract require?

Read the parent and child definitions.

### 4. What invariants must remain true?

Identify them before modifying code.

### 5. Is this semantic, representational, transformational, or implementation-specific?

Classify it explicitly.

### 6. Is this a transformation or a lowering?

Do not conflate them.

### 7. Is this a capability or a provider?

Capabilities describe what is possible.

Providers describe how it is realized.

### 8. Does the change alter meaning or merely realization?

If meaning changes, the semantic definition must be reviewed.

### 9. What evidence supports the implementation status?

Do not claim completion without tests or validation.

---

# 48. Final Architectural Principle

SCR is intended to provide a computational environment in which meaning can remain stable while representation, transformation, implementation, provider, execution strategy, and hardware can change.

The architecture therefore depends upon maintaining the following separation:

```text
                 SEMANTIC MEANING
                        │
                        ▼
                 Semantic Contract
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
       Analysis     Transformation  Composition
          │             │             │
          └─────────────┼─────────────┘
                        ▼
                     Lowering
                        │
                        ▼
                    Provider
                        │
                        ▼
                    Execution
                        │
              ┌─────────┴─────────┐
              ▼                   ▼
           Hardware            Runtime
```

The implementation may change.

The provider may change.

The representation may change.

The hardware may change.

The execution strategy may change.

The semantic contract must not change accidentally.

> **SCR exists to make computational meaning explicit, composable, transformable, analyzable, and executable across heterogeneous implementations without making any particular implementation the definition of the computation.**
