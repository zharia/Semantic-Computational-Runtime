# Development Agent — SCR Semantic Alignment, AzFramework Incorporation, O3DE Provider Assessment and Validation

## 0. Mission

Perform a targeted architectural and semantic assessment of the Semantic Computational Runtime (SCR) repository to:

1. Establish and document SCR's semantic-alignment philosophy.
2. Assess **AzFramework and its adjacent O3DE runtime frameworks as sources of industry-aligned semantic concepts**.
3. Identify which AzFramework/AzCore/AzNetworking/Multiplayer/AzPhysics/SceneAPI concepts should become or refine SCR semantic-library definitions.
4. Distinguish semantic concepts from O3DE implementation details.
5. Assess O3DE as an SCR execution provider.
6. Formalize the relationship between:

   * semantic definitions,
   * semantic functions and transformations,
   * representations,
   * projections,
   * materialization,
   * adapters,
   * providers,
   * execution,
   * distributed state.
7. Incorporate the authoring → materialization → deployment → simulation → distributed-observation lifecycle where justified by the existing SCR architecture.
8. Produce the minimum required repository documentation/specification changes.
9. Define and, where practical, perform minimal validation of the resulting architecture.

This is **not** a request to redesign SCR around O3DE or AzFramework.

The objective is:

> **Align → integrate → project → adapt → execute**

rather than:

> **Invent → replace → centralize**

---

# 1. Foundational Architectural Principle

SCR semantic definitions, functions, relationships, transformations, identities, state models, and composition rules are primary.

External technologies are representations, standards, implementations, or execution providers according to their actual role.

The architecture must preserve this distinction:

```text
                         SCR
          Semantic Computational Runtime
                         │
          ┌──────────────┴──────────────┐
          │                             │
     SEMANTIC DOMAIN                SEMANTIC OPERATIONS
          │                             │
   definitions/functions          transformations
   relationships                  composition
   identity                       constraints
   state                          computation
   space                          dynamics
   time                           etc.
          │
          ▼
   Semantic → Representation Projection
          │
     ┌────┼────────┬─────────┬─────────┬─────────┐
     ▼    ▼        ▼         ▼         ▼         ▼
    USD  ROS 2    MLIR    OpenVDB      H3    O3DE/Az*
     │    │        │         │          │         │
     └────┴────────┴─────────┴──────────┴─────────┘
                         │
                         ▼
                    Adapters
                         │
                         ▼
                  Execution Providers
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
         O3DE          CPU/GPU      specialist
                                      providers
```

Do not invert this architecture.

O3DE does not define SCR semantics.

AzFramework does not define SCR semantics.

USD does not define SCR semantics outside the domain semantics that USD itself legitimately owns.

ROS 2 does not define SCR semantics outside its own domain.

MLIR does not define SCR semantic meaning.

OpenVDB and H3 remain domain technologies with their own legitimate semantics.

SCR integrates these systems.

---

# 2. Semantic Alignment Principle

SCR is a **unifying semantic integration layer**, not an attempt to redefine existing industries.

Before defining a new SCR concept:

1. Identify the concept.
2. Identify established terminology.
3. Identify relevant industry standards.
4. Identify relevant mathematical/domain definitions.
5. Identify existing implementations and established practice.
6. Determine whether SCR already contains an equivalent concept.
7. Determine whether competing concepts are actually different semantics or merely different representations.
8. Align with established terminology where appropriate.
9. Define an SCR-specific abstraction only where required for:

   * composition,
   * integration,
   * execution,
   * interoperability,
   * formalisation,
   * or a genuine semantic gap.
10. Record provenance and mappings.

Do not invent terminology merely because an external framework uses different names.

Do not mechanically copy external framework terminology into SCR.

Do not assume that an API type represents a semantic primitive.

---

# 3. Semantic Authority Model

For every important concept classify its authority.

Use:

```text
SCR-authoritative
External-standard-authoritative
Implementation-specific
Provider-specific
Representation-specific
```

Examples:

```text
SCR Identity
    → SCR-authoritative

USD Prim semantics
    → USD-authoritative within USD

ROS 2 node semantics
    → ROS 2-authoritative within ROS 2

O3DE EntityId
    → O3DE implementation/provider concept

AzFramework EntityContext
    → O3DE framework concept whose underlying semantics may map to SCR

PhysX rigid body implementation
    → provider implementation

SCR Entity
    → SCR semantic concept
```

An O3DE concept may therefore provide evidence for an SCR semantic without becoming the SCR definition.

---

# 4. Definitions: Semantic Concept vs Representation vs Adapter vs Provider

The repository must explicitly distinguish:

## Semantic Definition

What something means.

Example:

```text
Entity
Component
Authority
SimulationStep
Transform
PhysicsBody
Replication
Prediction
```

## Semantic Function

A transformation or operation over semantic structures.

Examples:

```text
instantiate(entity)
attach(component, entity)
transform(entity, transform)
simulate(world, Δt)
replicate(state)
reconcile(prediction, authority)
materialize(world)
```

## Representation

A concrete encoding of semantic information.

Examples:

```text
USD
MLIR
OpenVDB
H3
ROS 2 messages
O3DE serialized assets
network packets
```

## Projection

Mapping semantic information into or from a representation.

Projection may be:

```text
lossless
partially lossless
lossy
unidirectional
bidirectional
implementation-specific
```

Never assume representation equality implies semantic equality.

## Adapter

A mechanism translating SCR contracts into a provider or external-system interface.

Example:

```text
SCR Entity
    ↓
O3DE adapter
    ↓
AzFramework Entity
```

## Execution Provider

A system that executes semantic operations.

Examples:

```text
O3DE
Bullet
PhysX
CPU
GPU
specialist simulation engines
```

---

# 5. AzFramework Assessment

Perform a systematic assessment of AzFramework.

Do not limit the investigation to a single API namespace.

Investigate, as applicable:

```text
AzCore
AzFramework
AzNetworking
Multiplayer
AzPhysics
SceneAPI
Asset systems
Entity systems
Input systems
Application/runtime systems
Relevant Gems
```

Determine the actual boundaries between these systems.

Do not assume the boundaries from their names.

---

# 6. AzFramework Semantic Archaeology

For every potentially reusable concept, determine:

```text
Concept
Established definition
Industry terminology
O3DE terminology
Underlying semantic meaning
SCR equivalent
Existing SCR definition
Candidate SCR location
Authority
Representation
Projection
Adapter
Provider dependency
State implications
Temporal implications
Identity implications
Validation requirements
```

Use the following assessment table structure:

| External Concept | Domain | Underlying Semantic | Existing SCR Concept | Candidate SCR Concept | Authority | Provider-Specific? | Action |
| ---------------- | ------ | ------------------- | -------------------- | --------------------- | --------- | ------------------ | ------ |

Actions:

```text
retain-existing
extend-existing
define-new
map-only
provider-only
representation-only
reject-as-nonsemantic
requires-further-research
```

---

# 7. Entity and Component Semantics

Pay particular attention to the O3DE entity/component model.

Investigate concepts including:

```text
Entity
EntityId
Component
Component composition
Component lifecycle
Entity lifecycle
Parent/child relationships
Entity context
Instantiation
Spawnable
Prefab
```

Determine which underlying semantics belong in:

```text
lib/core
lib/graph
lib/hypergraph
lib/spatial
lib/system
lib/simulation
lib/resource
```

Do not replace SCR identity with `AZ::EntityId`.

SCR identity remains authoritative.

Model O3DE identity as a provider mapping:

```text
SCR SID
   │
   ▼
O3DE identity mapping
   │
   ▼
AZ::EntityId
```

The mapping must define lifecycle and collision/uniqueness assumptions.

---

# 8. Component Semantics

Determine whether the O3DE component model provides evidence for first-class SCR concepts around:

```text
Component
Capability
Composition
Attachment
Lifecycle
Dependency
Execution participation
State ownership
```

Do not assume every O3DE component corresponds to an SCR semantic component.

Distinguish:

```text
semantic capability
```

from:

```text
implementation component
```

---

# 9. Context Semantics

Investigate O3DE/AzFramework entity-context concepts.

Assess whether SCR should formalize a general:

```text
Context
```

concept.

Candidate contexts include:

```text
AuthoringContext
ExecutionContext
SimulationContext
PhysicsContext
NetworkContext
RenderingContext
ObservationContext
```

Do not create these merely because they sound useful.

Establish whether the underlying concept is genuinely required by existing SCR architecture.

A context must not silently become an ownership model.

An entity represented in multiple contexts remains one semantic entity unless the semantic model explicitly states otherwise.

---

# 10. Spatial Semantics

Assess O3DE spatial concepts:

```text
Transform
Local transform
World transform
Parent transform
Hierarchy
Entity frame
Coordinate system
Orientation
Scale
Spatial relationship
```

Map these against existing SCR:

```text
spatial
geometry
topology
field
graph
hypergraph
```

Explicitly distinguish:

```text
semantic transform
```

from:

```text
O3DE transform representation
```

Document coordinate-system and convention mappings.

Do not allow O3DE coordinate conventions to silently become SCR conventions.

---

# 11. Runtime and Lifecycle Semantics

Assess:

```text
Application lifecycle
Initialization
Activation
Deactivation
Shutdown
Tick
Update
Simulation step
Pause
Resume
Reset
World creation
World destruction
```

Determine whether SCR needs formal lifecycle/state-machine semantics.

Where appropriate, map these to:

```text
State
Transition
Lifecycle
SimulationStep
Execution
TemporalOrdering
```

Do not confuse a framework callback with a semantic transition.

---

# 12. Physics and Dynamics

Assess O3DE/AzPhysics semantics:

```text
Physics system
Physics scene
Rigid body
Static body
Dynamic body
Character/controller
Constraint
Joint
Collision
Contact
Simulation
Timestep
```

Compare against existing SCR:

```text
physics
dynamics
simulation
geometry
spatial
state
```

Identify missing concepts.

Preserve provider separation:

```text
SCR PhysicsBody
        │
        ▼
O3DE/AzPhysics adapter
        │
        ▼
PhysX / other backend
```

Do not make PhysX or AzPhysics the semantic authority.

---

# 13. Asset and Resource Semantics

Assess:

```text
Asset
AssetId
Asset reference
Asset lifecycle
Asset loading
Asset dependency
Product asset
Source asset
Prefab
Spawnable
Materialization
```

Distinguish:

```text
source representation
authoring representation
deployable representation
runtime representation
```

Determine whether existing SCR resource/representation/interchange semantics are sufficient.

---

# 14. Authoring → Materialization → Simulation

Explicitly assess the following lifecycle:

```text
AUTHORING
    │
    │ semantic editing
    ▼
AUTHORING STATE
    │
    │ validate / resolve / compile / bake / materialize
    ▼
DEPLOYABLE STATE
    │
    │ instantiate
    ▼
SIMULATION STATE
    │
    │ replicate / observe
    ▼
DISTRIBUTED STATE
```

Do not assume these are merely file-format conversions.

Investigate whether SCR requires a semantic operation such as:

```text
materialize()
```

or a more appropriate established term.

The operation may involve:

```text
resolution
validation
flattening
reference resolution
asset compilation
dependency closure
runtime optimisation
deterministic initialisation
```

Document which operations are semantic and which are provider implementation details.

---

# 15. OpenUSD Relationship

Maintain the established SCR principle:

> **OpenUSD is a projection/interchange representation of SCR semantics, not the semantic authority of SCR.**

Assess:

```text
SCR World
    ↓
USD projection
    ↓
USD Stage
    ↓
USD Layers
    ↓
O3DE import/materialization
```

Also assess observation in the opposite direction:

```text
O3DE runtime state
    ↓
semantic observation
    ↓
USD projection
```

Determine where this is lossless, partial, lossy, or undefined.

Do not make USD the default high-frequency multiplayer state transport.

---

# 16. Multiplayer and Distributed-State Semantics

This is a major assessment area.

Investigate O3DE Multiplayer/AzNetworking concepts including:

```text
Authority
Ownership
Network role
Replication
Replicated state
Network property
RPC
Remote operation
Prediction
Reconciliation
Rollback
Synchronization
Network entity
Client
Server
Host
Observation
```

Determine which underlying semantics should become SCR concepts.

Do not simply reproduce O3DE Multiplayer terminology.

Map the underlying semantics.

Potential SCR semantic family:

```text
distributed/
    authority/
    ownership/
    replication/
    observation/
    prediction/
    reconciliation/
    synchronization/
    remote_operation/
    network_role/
```

These semantics must remain general enough for:

```text
games
robotics
distributed simulation
digital twins
remote visualisation
multi-agent systems
collaborative environments
```

---

# 17. Networking Transport vs Distributed Semantics

Do not confuse:

```text
transport
```

with:

```text
distributed semantic state
```

For example:

```text
ReliableDelivery
UnreliableDelivery
Ordering
Packetisation
Serialization
Compression
Encryption
UDP
TCP
```

are transport/network implementation concerns.

Whereas:

```text
Authority
Replication
Prediction
Reconciliation
Observation
RemoteOperation
```

are higher-level distributed semantics.

The SCR semantic library must remain independent of AzNetworking.

The architecture should permit:

```text
SCR Distributed Semantics
           │
           ▼
Network Projection
       ┌───┴────┐
       ▼        ▼
AzNetworking   ROS 2/DDS
```

and other providers.

---

# 18. Gameplay Runtime Model

Assess the proposed gameplay architecture:

```text
                 DEPLOYABLE WORLD
                        │
                        ▼
                  O3DE Runtime
                        │
              ┌─────────┴─────────┐
              │                   │
          Simulation           Networking
              │                   │
              │              Distributed State
              │                   │
              └─────────┬─────────┘
                        ▼
                    Clients
```

Do not encode the following as SCR invariants:

```text
UDP is always used
latency is sub-millisecond
all world data is downloaded before play
the server always sends only position/velocity
USD is never used at runtime
```

These are deployment/implementation choices.

Instead identify the semantic requirements:

```text
authoritative state
partial state projection
replication
state observation
prediction
reconciliation
bandwidth-aware representation
deterministic or controlled simulation
```

---

# 19. Prediction and Reconciliation

Investigate whether the SCR temporal/distributed semantic model needs explicit definitions for:

```text
AuthoritativeState
PredictedState
ObservedState
CorrectedState
PredictionInput
AuthorityUpdate
Reconciliation
Rollback
Replay
```

Do not assume O3DE's exact implementation is the canonical semantic model.

Extract the general semantics.

---

# 20. Identity

Preserve SCR identity architecture.

Investigate mappings among:

```text
SCR SID
O3DE EntityId
network entity identifier
USD prim path
asset identifier
ROS entity identifier
provider-local identifiers
```

Document:

```text
identity authority
identity scope
identity lifetime
identity stability
identity mapping
identity collision behaviour
```

Do not use UUID/EntityId/PrimPath/network ID interchangeably.

---

# 21. State Ownership

For every mapped state identify:

```text
Who owns the state?
Who may mutate it?
Who observes it?
Who replicates it?
Who predicts it?
Who reconciles it?
Which representation is authoritative?
```

This must be explicit.

A representation must never accidentally become authoritative merely because it is convenient.

---

# 22. Temporal Semantics

Assess O3DE timing concepts against SCR.

Distinguish:

```text
Wall-clock time
Execution time
Simulation time
World time
Event time
Observation time
Network time
Frame time
Physics timestep
```

Determine which already exist in SCR and which need clarification.

Do not equate:

```text
frame number
```

with:

```text
simulation time
```

unless formally justified.

---

# 23. O3DE Provider Assessment

After the semantic assessment, produce/update the canonical O3DE provider specification.

Likely location:

```text
providers/o3de/101_spec.md
```

Verify the actual repository structure first.

The provider specification must cover:

```text
Provider purpose
Provider scope
Supported SCR contracts
Semantic mappings
Identity mapping
Spatial mapping
Temporal mapping
Lifecycle
State ownership
Physics
Entities/components
Assets
USD
ROS 2
Networking
Multiplayer
Execution
Headless mode
Adapters
Dependencies
Known limitations
Unsupported capabilities
Validation
```

Use capability classifications:

```text
native
adapter-required
partial
unsupported
unverified
```

Do not claim a capability is implemented merely because O3DE appears capable of it.

---

# 24. Preserve Existing Provider Relationships

Explicitly assess the relationship between O3DE and:

```text
Bullet3
PhysX
OpenVDB
H3
Ogre3D
OpenUSD
ROS 2
Mojo
MLIR
```

Do not automatically replace any of them.

For each determine:

```text
semantic role
representation role
provider role
execution role
adapter role
interchange role
possible redundancy
complementarity
```

The objective is to establish a coherent provider ecosystem.

---

# 25. MLIR and Mojo

Maintain:

```text
SCR semantics
        ↓
semantic operation
        ↓
MLIR representation/lowering
        ↓
Mojo implementation where appropriate
        ↓
CPU/GPU/NPU/etc.
```

Do not make O3DE responsible for MLIR.

Do not make MLIR the semantic authority.

Do not make Mojo the semantic authority.

---

# 26. ROS 2

Treat ROS 2 as an external robotics interoperability ecosystem.

Assess:

```text
robot entities
frames
topics
services
actions
messages
QoS
time
sensors
commands
controllers
```

Determine SCR mappings.

Do not make ROS 2 the SCR robotics ontology.

---

# 27. OpenVDB and H3

Preserve the established distinction:

```text
SCR semantic spatial model
        │
        ├── OpenVDB projection/provider
        │
        └── H3 indexing/locality/routing
```

H3 must not silently become the SCR coordinate system.

OpenVDB must not silently become the universal spatial ontology.

---

# 28. Semantic Fidelity Assessment

For major mappings assess:

```text
SCR → USD
SCR → ROS 2
SCR → MLIR
SCR → OpenVDB
SCR → H3
SCR → O3DE
SCR → AzFramework
SCR → Multiplayer
SCR → AzPhysics
```

Classify each:

```text
lossless
partially-lossless
lossy
implementation-specific
not-established
```

Explain what information is lost or transformed.

---

# 29. Repository Changes

First inspect the repository and identify the actual existing authoritative documentation structure.

Likely changes include:

```text
root 101_definition.md
root 101_spec.md

semantic library definitions
lib/*/101_definition.md
lib/*/101_spec.md

provider documentation
providers/o3de/101_spec.md

status / program increment documentation
program_increments/v0.0.1/*
```

Do not create duplicate authoritative documents.

Only introduce a dedicated semantic-alignment document if the existing hierarchy cannot express the required architectural rule cleanly.

---

# 30. Semantic Library Candidate Structure

Do not create every proposed directory automatically.

Determine which concepts are actually required.

Candidate areas include:

```text
lib/core/entity/
lib/core/component/
lib/core/context/
lib/core/lifecycle/

lib/spatial/transform/
lib/spatial/hierarchy/

lib/simulation/world/
lib/simulation/state/
lib/simulation/step/
lib/simulation/materialization/

lib/physics/body/
lib/physics/constraint/
lib/physics/collision/

lib/resource/asset/
lib/resource/reference/
lib/resource/lifecycle/

lib/interaction/input/
lib/interaction/control/

lib/distributed/authority/
lib/distributed/ownership/
lib/distributed/replication/
lib/distributed/observation/
lib/distributed/prediction/
lib/distributed/reconciliation/
lib/distributed/synchronization/
lib/distributed/remote_operation/
```

Every new semantic definition must follow existing SCR documentation conventions.

---

# 31. Provenance

Every semantic definition derived or informed by an external standard/framework must record provenance.

At minimum:

```text
Concept
Source
Source terminology
Source authority
SCR interpretation
Reason for alignment
Differences
Mapping
Provider implications
```

Do not present O3DE-derived concepts as if they originated independently inside SCR.

---

# 32. Formalisation

Where appropriate, identify concepts suitable for Lean formalisation.

Prioritise invariants such as:

```text
Entity identity uniqueness
Entity/component composition consistency
Parent/child preservation
Transform composition
Lifecycle validity
State transition validity
Authority invariants
Replication consistency
Prediction/reconciliation invariants
Temporal ordering
Materialization correctness
Projection consistency
```

Lean proofs are encouraged but are not mandatory for every semantic concept.

Do not delay practical semantic documentation merely because formal proof is incomplete.

---

# 33. Validation

Define and, where practical, execute a minimal end-to-end validation:

```text
SCR semantic definition
        ↓
SCR provider contract
        ↓
O3DE adapter
        ↓
O3DE execution
        ↓
observable state
        ↓
SCR-compatible semantic result
```

At minimum validate:

```text
provider initialization
identity mapping
entity creation
component association
spatial mapping
lifecycle
simulation step
state transition
shutdown
unsupported capability reporting
```

Where practical additionally validate:

```text
USD projection
ROS 2 projection
network/distributed-state projection
```

---

# 34. Test Semantic Invariants

Tests must not merely demonstrate that APIs can be called.

Test:

```text
identity remains stable
parent/child relationships are preserved
coordinate transformations are correct
state ownership remains explicit
time ordering is preserved
unsupported semantics are not silently discarded
projection loss is declared
provider-local identifiers do not become semantic identity
materialization preserves required semantics
authority transitions are explicit
replicated state has defined ownership
prediction does not silently overwrite authoritative state
```

---

# 35. Do Not Over-Implement

This phase is primarily:

```text
research
semantic analysis
architecture
specification
mapping
validation
```

Do not undertake:

```text
full O3DE integration
full multiplayer implementation
full USD collaboration system
complete ROS 2 integration
replacement of existing providers
large-scale runtime rewrite
```

unless the existing repository explicitly requires it as part of the current implementation plan.

---

# 36. Required Deliverables

Produce:

### A. Semantic Alignment Update

Document:

```text
SCR semantic authority
industry alignment
external standards
projection
representation
adapter
provider
execution
```

### B. AzFramework Semantic Assessment

Provide a comprehensive table:

```text
AzCore
AzFramework
AzNetworking
Multiplayer
AzPhysics
SceneAPI
relevant Gems
```

mapped against SCR semantics.

### C. Semantic Gap Analysis

Identify:

```text
already-defined
needs clarification
needs extension
new semantic required
provider-only
representation-only
```

### D. O3DE Provider Specification

Create/update:

```text
providers/o3de/101_spec.md
```

at the actual appropriate repository location.

### E. Authoring/Materialization/Simulation Model

Document whether SCR should explicitly model:

```text
authoring
materialization
deployment
simulation
distributed observation
```

and define the semantics only where justified.

### F. Distributed-State Semantic Model

Document candidate semantics for:

```text
authority
ownership
replication
observation
prediction
reconciliation
remote operation
```

### G. Identity Mapping

Document:

```text
SID
O3DE EntityId
network IDs
USD paths
provider-local IDs
```

### H. Validation Plan and Results

Clearly distinguish:

```text
documented
implemented
tested
validated
unverified
```

---

# 37. Completion Criteria

The task is complete when:

* SCR semantic authority is explicit.
* Industry-standard alignment is documented.
* External standards are treated as domain authorities where appropriate.
* AzFramework has been assessed semantically rather than merely as an API.
* AzCore, AzFramework, AzNetworking, Multiplayer, AzPhysics and relevant SceneAPI concepts are distinguished.
* Entity/component semantics are mapped.
* Context semantics are assessed.
* Spatial semantics are mapped.
* Physics/dynamics semantics are mapped.
* Runtime/lifecycle semantics are mapped.
* Asset/materialization semantics are mapped.
* Distributed-state semantics are mapped.
* Authority/ownership/replication/prediction/reconciliation are assessed.
* Identity mappings are explicit.
* Temporal mappings are explicit.
* USD remains a projection/interchange representation.
* ROS 2 remains a robotics interoperability ecosystem.
* MLIR/Mojo remain computational representation/implementation infrastructure.
* O3DE remains an execution provider.
* AzFramework remains an O3DE framework/provider implementation rather than an SCR dependency.
* Bullet3/PhysX/OpenVDB/H3/Ogre3D relationships are documented rather than arbitrarily replaced.
* Authoring → materialization → deployment → simulation → distributed observation is evaluated as a semantic lifecycle.
* Semantic fidelity/loss characteristics are documented.
* New SCR definitions have provenance.
* Minimal validation exists where practical.
* Status files accurately distinguish documented, implemented, tested and validated work.
* No unnecessary architectural redesign has been introduced.

---

# 38. Final Architectural Invariant

The resulting repository must preserve this invariant:

```text
                    SEMANTIC MEANING
                           │
                           ▼
                  SCR semantic operation
                           │
                           ▼
                  projection / mapping
                           │
                           ▼
                    representation
                           │
                           ▼
                        adapter
                           │
                           ▼
                    provider execution
                           │
                           ▼
                       observation
                           │
                           ▼
                SCR-compatible semantic state
```

For the O3DE case:

```text
SCR Semantic World
        │
        ├───────────────┐
        │               │
        ▼               ▼
   USD Projection   O3DE Projection
        │               │
        ▼               ▼
   USD Stage       AzFramework/O3DE
                        │
                        ▼
                    O3DE Runtime
                        │
                ┌───────┴────────┐
                ▼                ▼
            Simulation       Multiplayer
                │                │
                └───────┬────────┘
                        ▼
                Distributed State
                        │
                        ▼
                  Observation
                        │
                        ▼
                   SCR semantics
```

The governing principle is:

> **SCR defines and composes semantic meaning. Established technologies provide aligned representations, interoperability mechanisms, and execution capabilities. AzFramework is valuable because it provides concrete, mature industry semantics from which SCR can learn, align, map, and compose — not because SCR should become an abstraction over AzFramework.**
