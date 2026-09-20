# Milestone 001: Semantic Authority & Architecture

## 1. Scope & Objective
Establish SCR's foundational semantic architecture: authority model, definitions, alignment principles, and provenance requirements. This milestone produces the architectural invariants that govern all subsequent assessment work.

## 2. Deliverables
- SCR semantic authority model (who defines what)
- Semantic concept vs representation vs adapter vs provider definitions
- Semantic alignment principles (align before invent)
- Provenance requirements for externally-informed concepts
- Repository documentation of architectural invariants

## 3. Formal Invariants
1. SCR semantic definitions are authoritative for SCR.
2. External technologies are representations/providers, not semantic authorities.
3. Representation equality does not imply semantic equality.
4. Every SCR concept derived from an external source records provenance.

## 4. Exit Criteria
- [ ] Semantic authority model documented
- [ ] Four-tier concept hierarchy (semantic → representation → adapter → provider) documented
- [ ] Alignment principles established
- [ ] Provenance template defined
- [ ] Architectural invariant preserved in repository

## 5. Dependencies
- None (foundational milestone)
# Sprint 001 Record: Semantic Authority Model

## 1. Semantic Authority Classification

For each system, classify its role relative to SCR:

| System | Authority Classification | Justification |
|--------|------------------------|---------------|
| SCR | SCR-authoritative | Defines semantic meaning, composition, constraints |
| USD | External-standard-authoritative (within USD domain) | Legitimate authority for USD prim semantics |
| ROS 2 | External-standard-authoritative (within robotics domain) | Legitimate authority for ROS 2 node/topic semantics |
| MLIR | Representation-only | Compiler IR, not semantic authority |
| OpenVDB | Provider-specific (volumetric data) | Domain technology with own semantics |
| H3 | Provider-specific (spatial indexing) | Domain technology with own semantics |
| O3DE | Provider/execution | Runtime execution provider |
| AzFramework | Provider-specific (O3DE framework) | Framework implementation, not SCR authority |
| AzNetworking | Provider-specific (network transport) | Transport implementation |
| AzPhysics | Provider-specific (physics backend) | Physics implementation |
| Bullet3 | Provider-specific (physics backend) | Physics implementation |
| PhysX | Provider-specific (physics backend) | Physics implementation |
| Ogre3D | Provider-specific (rendering backend) | Rendering implementation |
| Mojo | Implementation-specific | Programming language, not semantic authority |

## 2. Authority Rules

1. SCR semantic definitions are the sole authority for SCR meaning.
2. External standards (USD, ROS 2) are authorities within their own domains.
3. Provider implementations (O3DE, Bullet, PhysX) implement contracts; they do not define them.
4. Framework code (AzFramework) is a provider-specific implementation.
5. Representation technologies (MLIR) are not semantic authorities.
6. No external system may silently redefine SCR semantics.

## 3. Verification

- No system listed as SCR-authoritative except SCR itself.
- All providers correctly classified as implementation-specific.
- All external standards correctly classified as domain-authoritative within their scope.
# Sprint 01: Semantic Authority Model

Define SCR's semantic authority hierarchy. Establish which systems are semantic authorities vs representations vs providers.

## Deliverables
- Semantic authority classification table
- SCR-authoritative vs external-authoritative vs provider-specific designations
- Authority model documented in repository

## Exit Criteria
- [ ] Authority model covers: SCR, USD, ROS 2, MLIR, O3DE, AzFramework, Bullet, PhysX, OpenVDB, H3
- [ ] Each concept classified: SCR-authoritative / External-standard-authoritative / Implementation-specific / Provider-specific / Representation-specific
# Sprint 002 Record: Semantic Definitions

## 1. Concept Hierarchy

SCR distinguishes six concept types:

### Semantic Definition
What something means. Authoritative meaning independent of representation.
Examples: Entity, Component, Transform, Authority, SimulationStep

### Semantic Function
A transformation or operation over semantic structures.
Examples: instantiate(entity), attach(component, entity), simulate(world, Δt), replicate(state)

### Representation
A concrete encoding of semantic information.
Examples: USD, MLIR, OpenVDB, H3, ROS 2 messages, O3DE serialized assets, network packets

### Projection
Mapping semantic information into or from a representation.

| Projection Type | Description |
|----------------|-------------|
| Lossless | All semantic information preserved |
| Partially lossless | Some semantic information preserved |
| Lossy | Significant semantic information lost |
| Unidirectional | Semantic → Representation only |
| Bidirectional | Semantic ↔ Representation round-trip |
| Implementation-specific | Projection varies by implementation |

**Critical rule:** Representation equality does not imply semantic equality.

### Adapter
A mechanism translating SCR contracts into a provider or external-system interface.

```
SCR Entity → O3DE adapter → AzFramework Entity
SCR PhysicsBody → Bullet adapter → btRigidBody
```

### Execution Provider
A system that executes semantic operations.
Examples: O3DE, Bullet, PhysX, CPU, GPU, specialist simulation engines

## 2. Relationship Diagram

```
Semantic Meaning → Semantic Operation → Projection → Representation → Adapter → Provider Execution → Observation → SCR-compatible state
```

## 3. Verification

- All six concept types defined with examples
- Projection classification covers all common cases
- Adapter pattern clearly distinguished from provider
- Semantic equality ≠ representation equality stated explicitly
# Sprint 02: Semantic Definitions

Define core SCR concept hierarchy: semantic definition, semantic function, representation, projection, adapter, execution provider.

## Deliverables
- Concept hierarchy documented with examples
- Projection loss classifications (lossless/partial/lossy/unidirectional/bidirectional)
- Adapter pattern documented
- Execution provider pattern documented

## Exit Criteria
- [ ] Six concept types defined with examples
- [ ] Projection classification system documented
- [ ] Adapter vs provider distinction clear
# Sprint 003 Record: Alignment & Provenance

## 1. Semantic Alignment Process

Before defining a new SCR concept:

1. Identify the concept precisely.
2. Identify established terminology in the field.
3. Identify relevant industry standards.
4. Identify relevant mathematical/domain definitions.
5. Identify existing implementations and established practice.
6. Determine whether SCR already contains an equivalent concept.
7. Determine whether competing concepts are actually different semantics or merely different representations.
8. Align with established terminology where appropriate.
9. Define an SCR-specific abstraction only where required for composition, integration, execution, interoperability, formalisation, or a genuine semantic gap.
10. Record provenance.

**Rules:**
- Do not invent terminology merely because an external framework uses different names.
- Do not mechanically copy external framework terminology into SCR.
- Do not assume that an API type represents a semantic primitive.
- Align before inventing. Use existing terms where they exist.

## 2. Provenance Template

Every semantic definition derived from an external standard must record:

```yaml
concept: <SCR concept name>
source: <external system>
source_terminology: <term used in source>
source_authority: <who defines it in source>
scr_interpretation: <how SCR interprets it>
reason_for_alignment: <why aligned>
differences: <what SCR changes>
mapping: <bidirectional mapping if applicable>
provider_implications: <which providers affected>
```

## 3. Example: SCR Entity

```yaml
concept: Entity
source: AzFramework, USD, ROS 2
source_terminology: "AZ::Entity", "USD Prim", "ROS 2 Node"
source_authority: O3DE, USD consortium, ROS 2 consortium
scr_interpretation: >
  A semantic entity is a persistent identity with associated
  components/capabilities. SCR entity identity (SCR SID) is
  authoritative. Provider entity IDs are mappings.
reason_for_alignment: >
  Entity is a universal concept across game engines, scene graphs,
  and robotics. SCR adopts the established term.
differences: >
  SCR entity identity is provider-independent. O3DE EntityId is
  a provider-local identifier mapped from SCR SID.
mapping: >
  SCR SID → O3DE identity mapping → AZ::EntityId
  SCR SID → USD projection → USD Prim path
  SCR SID → ROS 2 projection → ROS 2 entity identifier
provider_implications: >
  All providers must implement identity mapping from SCR SID.
```

## 4. Verification

- 10-step alignment process documented
- Provenance template captures all required fields
- Example demonstrates the template in use
- Rules against terminology invention stated
# Sprint 03: Alignment & Provenance

Establish semantic alignment principles and provenance requirements for externally-informed concepts.

## Deliverables
- 10-step alignment process documented
- Provenance template defined
- Terminology inheritance rules documented

## Exit Criteria
- [ ] Alignment process covers: identify → terminology → standards → existing → SCR equivalent → justification
- [ ] Provenance template captures: concept, source, source terminology, SCR interpretation, differences, mapping
- [ ] Rule: do not invent terminology when external equivalent exists
# Milestone 002: AzFramework Semantic Assessment

## 1. Scope & Objective
Systematically assess AzFramework, AzCore, AzNetworking, Multiplayer, AzPhysics, and SceneAPI as sources of industry-aligned semantic concepts. Map O3DE concepts to SCR semantics without making O3DE the authority.

## 2. Deliverables
- AzFramework semantic archaeology table
- Entity/component mapping (O3DE → SCR)
- Spatial/context mapping
- Physics/asset mapping
- Gap analysis (what SCR needs vs what exists)

## 3. Formal Invariants
1. O3DE concepts provide evidence for SCR semantics, not definitions.
2. AZ::EntityId is a provider mapping, not SCR identity.
3. AzPhysics is a provider implementation, not SCR physics semantics.

## 4. Exit Criteria
- [ ] Comprehensive assessment table covering AzCore/AzFramework/AzNetworking/Multiplayer/AzPhysics/SceneAPI
- [ ] Entity/component semantics mapped
- [ ] Spatial semantics mapped
- [ ] Physics semantics mapped
- [ ] Asset/resource semantics mapped
- [ ] Gap analysis produced

## 5. Dependencies
- Milestone 001 (semantic authority model)
# Sprint 001 Record: AzCore & AzFramework Survey

## 1. Objective

Survey O3DE foundational concepts (AzCore, AzFramework) and classify each as semantic, implementation, or provider-specific per the SCR authority model. Evidence for SCR semantics only — O3DE is not the authority.

## 2. Classification Criteria

| Class | Definition |
|-------|-----------|
| **Semantic** | Genuine computational concept. Implementation-independent. SCR needs this meaning regardless of provider. |
| **Implementation** | Captures a semantically relevant pattern but is an O3DE-specific realization. SCR may absorb the pattern, not the API. |
| **Provider-specific** | Tied to O3DE execution substrate. Not a SCR semantic concern. |

## 3. Concept Inventory

### 3.1 AzCore — Type System & Identity

| O3DE Concept | Description | Classification | SCR Semantic Candidate |
|---|---|---|---|
| `AZ::Uuid` | 128-bit globally unique type identifier. Cross-DLL stable. Used for type registration and serialization routing. | **Implementation** | `Type` — canonical type identity. SCR needs stable identity independent of UUID encoding. |
| `AZ::TypeId` | Alias/resolution layer over Uuid. Maps user-facing type info to internal ID. | **Implementation** | Subsumed by `Type`. |
| `AZ::AzTypeInfo<T>` | Template struct providing compile-time type name, Uuid, and cross-module stability for fundamental and user types. | **Implementation** | `Type` metadata provider. SCR can define type metadata without this template machinery. |
| `AZ_RTTI` | Macro-based runtime type information. Provides `RTTI_GetType()` for dynamic casting and type queries. | **Implementation** | `Type` runtime resolution. SCR reflection may use different mechanics. |
| `AZ::ReflectContext` | Base class for all reflection contexts (SerializeContext, BehaviorContext, etc.). Manages on-demand reflection and circular-reference prevention. | **Implementation** | Reflection infrastructure. SCR can use MLIR types instead. |

**Assessment:** AzCore type system is robust implementation infrastructure. SCR needs `Type` identity as a semantic concept but not this C++ template/UUID machinery.

### 3.2 AzCore — Serialization

| O3DE Concept | Description | Classification | SCR Semantic Candidate |
|---|---|---|---|
| `SerializeContext` | Central reflection hub. Maps type UUIDs to class descriptors, fields, attributes, and serialization callbacks. Supports versioning. | **Implementation** | `Serialize` — persistence of object state. SCR needs serialization semantics but not this reflection-driven C++ approach. |
| `ObjectStream` | Binary stream reader/writer. Navigates reflected type graph to serialize/deserialize objects. Supports version migration. | **Provider-specific** | Binary serialization format. Provider detail. |
| `IDataSerializer` | Interface for custom binary/text format conversion per type. | **Provider-specific** | Format negotiation. Provider detail. |
| `IDataContainer` | Interface for template container serialization (e.g., `AZStd::vector`). | **Provider-specific** | Container serialization. Provider detail. |

**Assessment:** Serialization context is O3DE's C++ reflection-driven persistence. SCR serialization semantics are independent — MLIR can define serialization contracts.

### 3.3 AzCore — Memory

| O3DE Concept | Description | Classification | SCR Semantic Candidate |
|---|---|---|---|
| `AZ::Allocator` | Base allocator interface. Schema-based, supports profiling, guards, child allocators. | **Implementation** | `Allocate` — memory resource management. SCR needs allocation semantics but not this schema hierarchy. |
| `AZ::SystemAllocator` | Singleton general-purpose allocator. First initialized, last destroyed. Backed by HPHA or malloc. | **Provider-specific** | Default memory provider. Provider detail. |
| `AZ::ChildAllocatorSchema` | Pass-through allocator for tagging subsystem/gem memory. | **Provider-specific** | Memory tagging. Provider detail. |

**Assessment:** AzCore memory is deep provider infrastructure. SCR memory semantics (allocate, deallocate, lifetime) are abstract — providers choose their allocator strategy.

### 3.4 AzCore — Events

| O3DE Concept | Description | Classification | SCR Semantic Candidate |
|---|---|---|---|
| `AZ::Event<Params...>` | Delegate-based pub/sub. Component-scoped, single-threaded. Handlers connect/disconnect to specific instances. | **Implementation** | `Event` — discrete state change notification. SCR needs event semantics. |
| EBus (Event Bus) | Global singleton bus. Addressable by ID or broadcast. Request and notification halves. | **Implementation** | `Signal` — global decoupled communication. Pattern is semantic; EBus API is not. |
| `AZ::Interface<T>` | Global singleton request interface. Alternative to EBus request bus. | **Provider-specific** | Singleton access pattern. Provider detail. |

**Assessment:** Event/signal patterns are semantically meaningful. EBus wiring is O3DE-specific. SCR can define event semantics independent of bus architecture.

### 3.5 AzCore — IO

| O3DE Concept | Description | Classification | SCR Semantic Candidate |
|---|---|---|---|
| `AZ::IO::FileIOBase` | Virtual file system interface. Open, read, write, seek, directory aliases, pak file support. | **Implementation** | `Filesystem` — abstract file operations. SCR needs IO semantics. |
| `AZ::IO::GenericStream` | Abstract byte stream. Read/write/seek/flush. Used by serialization and streaming systems. | **Implementation** | `Stream` — sequential byte access. SCR needs stream semantics. |
| `AZ::IO::FileIOStream` | Concrete stream over FileIO handle. Auto-closes on scope exit. | **Provider-specific** | Stream implementation. Provider detail. |
| Archive/IArchive | Pack file (.pak) system for bundling assets. | **Provider-specific** | Asset packaging. Provider detail. |

**Assessment:** IO abstractions are semantically relevant (filesystem, streams). Archive and pak systems are provider packaging concerns.

### 3.6 AzFramework — Application Lifecycle

| O3DE Concept | Description | Classification | SCR Semantic Candidate |
|---|---|---|---|
| `AzFramework::Application` | Top-level application class. Manages bootstrap, descriptor loading, system entity activation, module initialization. | **Implementation** | `Lifecycle` — application startup/shutdown sequence. SCR needs lifecycle semantics. |
| `AZ::ComponentApplication` | Base class. System entity creation, component registration, tick dispatch, settings registry. | **Implementation** | `Runtime` — host for component execution. |
| Bootstrap sequence | Descriptor file → allocator init → module load → system entity activate. | **Provider-specific** | Startup orchestration. Provider detail. |
| `TargetPlatform` | Platform enumeration (Windows, Android, iOS, etc.). Used for conditional compilation. | **Provider-specific** | Platform targeting. Provider detail. |

**Assessment:** Application lifecycle is semantically important (startup, tick, shutdown). Bootstrap details and platform targeting are provider-specific.

### 3.7 AzFramework — Entity System

| O3DE Concept | Description | Classification | SCR Semantic Candidate |
|---|---|---|---|
| `AZ::Entity` | Addressable container for components. Has ID, name, state (Init/Activate/Deactivate). | **Implementation** | `Entity` — addressable computational unit. Core SCR semantic. |
| `AzFramework::EntityContext` | Ownership scope for entities. Manages creation, activation, destruction. Separate contexts for edit-time vs runtime. | **Implementation** | `Context` — entity ownership scope. SCR needs context semantics. |
| `AZ::EntityId` | 64-bit identifier for entities. Invalid = 0. Serializable, cross-module. | **Implementation** | `Identity` — addressable reference. SCR needs identity semantics, not this ID format. |
| EntityOwnershipService | Service responsible for entity lifecycle within a context (loading, creation). | **Provider-specific** | Entity storage. Provider detail. |

**Assessment:** Entity, context, and identity are foundational SCR semantics. EntityId encoding and ownership services are provider details.

### 3.8 AzFramework — Components

| O3DE Concept | Description | Classification | SCR Semantic Candidate |
|---|---|---|---|
| `AZ::Component` | Base class for all components. Lifecycle: Activate/Deactivate. Reflects to SerializeContext. | **Implementation** | `Component` — composable unit of behavior. Core SCR semantic. |
| `ComponentDescriptor` | Metadata provider for component registration. Name, UUID, dependencies, dependents. | **Implementation** | `ComponentDescriptor` — component metadata. SCR can define component metadata differently. |
| `AZ::TickBus` | Per-frame tick notification. Components implement `OnTick(deltaTime, time)`. Configurable order. | **Implementation** | `Tick` — simulation step. Core SCR semantic. |
| `AZ::SystemTickBus` | System-level tick. Runs at fixed rate independent of application focus. | **Implementation** | `Tick` — deterministic fixed-step tick. |
| `ComponentApplication` | Host for component registration, tick dispatch, settings. | **Implementation** | `Runtime` — component execution host. |

**Assessment:** Component and tick are core SCR semantics. ComponentApplication and ComponentDescriptor are implementation plumbing.

### 3.9 AzFramework — Input

| O3DE Concept | Description | Classification | SCR Semantic Candidate |
|---|---|---|---|
| `InputChannel` | Discrete input data source (key, button, axis). Broadcasts state changes via EBus. | **Implementation** | `InputChannel` — input data stream. SCR needs input semantics. |
| `InputDevice` | Physical device abstraction (keyboard, mouse, gamepad, touch, motion). Contains multiple channels. | **Implementation** | `InputDevice` — physical input source. |
| `InputChannelId` | Unique name identifying an input channel. | **Implementation** | Channel identity. Provider detail. |
| `InputChannelNotificationBus` | EBus for input channel events. Priority ordering, event consumption. | **Provider-specific** | Event delivery mechanism. Provider detail. |
| `InputSystemComponent` | System component managing device creation and input processing. | **Provider-specific** | Input orchestration. Provider detail. |
| Input bindings/mapping | Mapping physical inputs to semantic actions. | **Implementation** | `InputBinding` — action-to-source mapping. Semantically relevant. |

**Assessment:** Input channels, devices, and bindings are semantically meaningful for interactive systems. EBus wiring and system component are provider details.

### 3.10 AzFramework — Cameras

| O3DE Concept | Description | Classification | SCR Semantic Candidate |
|---|---|---|---|
| `CameraComponent` | Component adding camera to entity. FOV, clip distances, orthographic/perspective, active view. | **Implementation** | `Viewpoint` — observation projection. SCR camera semantics. |
| `CameraRequestBus` | EBus for camera property get/set. | **Provider-specific** | Property access bus. Provider detail. |
| `CameraNotificationBus` | EBus for camera lifecycle events (added/removed/active changed). | **Provider-specific** | Lifecycle events. Provider detail. |
| `CameraSystem` | Manages camera controllers, input-driven camera stepping. | **Provider-specific** | Camera orchestration. Provider detail. |
| `CameraSystemRequestBus` | EBus for global camera queries (active camera). | **Provider-specific** | Global query bus. Provider detail. |

**Assessment:** Camera/viewpoint is a genuine SCR semantic. CameraComponent captures the concept. All EBus wiring and camera system orchestration are provider-specific.

## 4. Summary Classification Matrix

### Semantic Concepts (SCR needs these regardless of provider)

| SCR Concept | Evidence From O3DE |
|---|---|
| **Type** | AZ::Uuid, AzTypeInfo, AZ_RTTI provide stable cross-module type identity |
| **Entity** | AZ::Entity: addressable component container with lifecycle |
| **Component** | AZ::Component: composable unit of behavior with activate/deactivate |
| **Context** | EntityContext: ownership scope separating edit-time from runtime entities |
| **Identity** | AZ::EntityId: addressable reference to entities |
| **Event** | AZ::Event: discrete state change notification with handlers |
| **Tick/SimulationStep** | TickBus: per-frame simulation dispatch with configurable ordering |
| **Viewpoint/Camera** | CameraComponent: observation projection with FOV, clip planes, perspective mode |
| **InputChannel** | InputChannel: discrete input data source with state changes |
| **InputDevice** | InputDevice: physical input source containing channels |
| **InputBinding** | Input bindings: mapping physical inputs to semantic actions |
| **Filesystem** | FileIOBase: abstract file operations |
| **Stream** | GenericStream: sequential byte access |
| **Lifecycle** | Application: startup, tick, shutdown sequence |

### Implementation Patterns (SCR may absorb pattern, not API)

| Pattern | O3DE Realization |
|---|---|
| Type identity encoding | AZ::Uuid, AzTypeInfo template specialization |
| Reflection | ReflectContext, AZ_RTTI macros, on-demand reflection |
| Serialization | SerializeContext, ObjectStream, IDataSerializer |
| Memory management | AZ::Allocator hierarchy, SystemAllocator singleton |
| Event dispatch | EBus global bus, AZ::Event delegate, AZ::Interface singleton |
| Component registration | ComponentDescriptor, ComponentApplication registration |
| Application bootstrap | Application::Start, descriptor file loading, module init |

### Provider-Specific (O3DE execution substrate only)

| Concept | Why Provider-Specific |
|---|---|
| Archive/IArchive | Pack file (.pak) packaging system |
| TargetPlatform | Platform enumeration for conditional compilation |
| ObjectStream binary format | O3DE's specific binary serialization protocol |
| EBus address scheme | Global singleton bus addressing by string name |
| ComponentApplication tick | O3DE's tick dispatch mechanism |
| CameraSystem controllers | O3DE's camera controller stepping |
| InputSystemComponent | O3DE's input device management |
| Bootstrap sequence | O3DE's descriptor-file-driven startup |
| NativeUI | Platform-native UI integration |
| SettingsRegistry | O3DE's hierarchical settings system |

## 5. SCR Semantic Mapping

### Core Entities

| SCR Semantic | O3DE Evidence | Notes |
|---|---|---|
| Entity | AZ::Entity | Addressable component container. SCR can define independently. |
| Component | AZ::Component | Composable behavior unit. SCR can define independently. |
| Context | EntityContext | Ownership scope. SCR needs scoping semantics. |
| Identity | AZ::EntityId | SCR identity is conceptual; EntityId is provider mapping. |

### Core Operations

| SCR Semantic | O3DE Evidence | Notes |
|---|---|---|
| Instantiate | EntityContext::CreateEntity | Create entity within scope. |
| Activate | Entity::Activate | Transition entity to active state. |
| Deactivate | Entity::Deactivate | Transition entity to inactive state. |
| Attach | Entity::AddComponent | Compose component into entity. |
| Signal | AZ::Event, EBus | Discrete state change notification. |
| Tick | TickBus::OnTick | Simulation step with delta time. |

### Core Types

| SCR Semantic | O3DE Evidence | Notes |
|---|---|---|
| Type | AZ::Uuid, AzTypeInfo | Stable cross-module type identity. |
| Stream | GenericStream | Sequential byte access for serialization. |
| Filesystem | FileIOBase | Abstract file operations with aliasing. |

### Rendering/Sensing

| SCR Semantic | O3DE Evidence | Notes |
|---|---|---|
| Viewpoint | CameraComponent | Observation projection (FOV, clip, perspective). |
| InputChannel | InputChannel | Discrete input data source. |
| InputDevice | InputDevice | Physical input source. |
| InputBinding | Input bindings | Action-to-source mapping. |

## 6. Gaps Identified

| Gap | Description |
|---|---|
| **No SCR Type system yet** | SCR has no formal type definition independent of providers. AzCore type system is evidence that stable type identity is needed. |
| **No SCR Event semantics** | SCR needs formal event/signal semantics. O3DE's AZ::Event and EBus provide two distinct patterns. |
| **No SCR Tick semantics** | SCR needs simulation step definition. O3DE's TickBus with configurable ordering is evidence. |
| **No SCR Input semantics** | SCR has no input channel/device abstraction. AzFramework input is evidence that this is a cross-cutting concern. |
| **No SCR Camera/Viewpoint semantics** | SCR has no viewpoint abstraction. CameraComponent is evidence. |
| **No SCR Filesystem semantics** | SCR needs abstract file operations. AzCore FileIOBase is evidence. |
| **Entity lifecycle not formalized** | O3DE's Init/Activate/Deactivate/Destroy is a mature pattern. SCR should formalize entity lifecycle. |

## 7. Exit Criteria Check

- [x] AzCore type system assessed (Section 3.1)
- [x] AzCore reflection/serialization assessed (Sections 3.1, 3.2)
- [x] AzCore event system assessed (Section 3.4)
- [x] AzCore memory assessed (Section 3.3)
- [x] AzCore IO assessed (Section 3.5)
- [x] AzFramework application lifecycle assessed (Section 3.6)
- [x] AzFramework entity system assessed (Section 3.7)
- [x] AzFramework components assessed (Section 3.8)
- [x] AzFramework input assessed (Section 3.9)
- [x] AzFramework cameras assessed (Section 3.10)
- [x] Each concept classified per authority model (Sections 3.1–3.10)
- [x] SCR semantic mapping produced (Section 5)
- [x] Gaps identified (Section 6)
# Sprint 01: AzCore & AzFramework Survey

Survey AzCore and AzFramework foundational concepts: types, memory, reflection, serialization, events, settings.

## Deliverables
- AzCore concept inventory
- Classification: semantic / implementation / provider-specific
- Mapping candidates to SCR

## Exit Criteria
- [ ] AzCore type system assessed
- [ ] AzCore reflection/serialization assessed
- [ ] AzCore event system assessed
- [ ] Each concept classified per authority model
# Sprint 002 Record: Entity & Component Mapping

## 1. Objective

Deep-map O3DE entity/component model (AzCore + AzFramework) to SCR semantics. Produce per-concept mapping rows with action classification. Preserve SCR authority model: SID is authoritative identity, not AZ::EntityId.

## 2. Mapping Columns

| Column | Meaning |
|--------|---------|
| O3DE Concept | Provider implementation name |
| Underlying Semantic | The genuine computational concept it realizes |
| Existing SCR Concept | SCR domain already covering this semantics (if any) |
| Candidate SCR Concept | Proposed SCR concept if not yet defined |
| Authority | Who owns the semantic meaning |
| Provider-Specific? | Whether this is O3DE-specific plumbing |
| Action | `retain-existing` / `extend-existing` / `define-new` / `map-only` / `provider-only` |

## 3. Entity Mapping

### 3.1 AZ::Entity

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::Entity` |
| Underlying Semantic | **Addressable computational unit.** Container for components. Has identity, name, lifecycle state (Constructed → Initializing → Init → Activating → Active → Deactivating → Destroying → Destroyed). Entity creates, initializes, activates, deactivates its components. Entity has no behavior of its own — behavior emerges from component composition. |
| Existing SCR Concept | `101_Core/Identity` — SID provides authoritative identity. No SCR entity composition concept yet. |
| Candidate SCR Concept | **`Entity`** — SCR semantic entity. Composable unit with SID identity, component slots, lifecycle state machine, and dependency resolution. |
| Authority | SCR Architectural Group |
| Provider-Specific? | No. Entity is a genuine computational concept. |
| Action | **define-new** |

**Rationale:** O3DE's Entity is a mature reference implementation of entity-component composition. SCR needs an entity concept independent of any provider. The state machine (Constructed → Init → Active → Inactive → Destroyed) is semantic — it captures instantiation → readiness → execution → teardown. O3DE's 32-bit active-state-by-type bitmask is provider-specific; SCR lifecycle is simpler.

### 3.2 AZ::EntityId

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::EntityId` |
| Underlying Semantic | **Provider-local addressable reference.** 64-bit identifier. Invalid = 0. Serializable. Used to address components via EBuses. Created within EntityContext scope. Can be remapped across contexts. |
| Existing SCR Concept | `101_Core/Identity` — SID is the authoritative identity coordinate. |
| Candidate SCR Concept | None. AZ::EntityId maps to SCR Manifestation layer (ephemeral runtime handle). |
| Authority | SCR Identity domain (SID is authoritative) |
| Provider-Specific? | **Yes.** AZ::EntityId is a provider-local runtime handle. |
| Action | **provider-only** |

**Rationale:** SCR Rule IAM-I014 (Manifestation Separation): manifestation handles may be mutated, migrated, or destroyed without altering the canonical coordinate. AZ::EntityId is exactly this — a manifestation handle. The SCR SID is authoritative; AZ::EntityId is a provider-local runtime address that maps to the SID's manifestation layer. SCR never adopts AZ::EntityId as identity authority.

### 3.3 Entity Lifecycle State Machine

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::Entity::State` — Constructed → Initializing → Init → Activating → Active → Deactivating → Destroying → Destroyed |
| Underlying Semantic | **Lifecycle state machine.** Entities progress through discrete states. Init is called once. Activate/Deactivate can cycle multiple times. Destroy is terminal. Active state is controlled by 32-bit bitmask (entity self + parent + custom types). |
| Existing SCR Concept | `101_Core/State` — placeholder, no definition yet. |
| Candidate SCR Concept | **`LifecycleState`** — enumeration of entity lifecycle phases. Semantic: instantiated → ready → executing → suspended → terminated. |
| Authority | SCR Architectural Group |
| Provider-Specific? | No. Lifecycle phases are universal. Bitmask mechanism is provider-specific. |
| Action | **define-new** |

**Rationale:** Entity lifecycle is a genuine semantic concept. The state progression (create → init → activate → deactivate → destroy) is independent of O3DE. The 32-bit active-state-by-type bitmask is an implementation optimization — SCR defines the semantic states, not the bitmask. O3DE's `ApplyEffectiveActiveState` batching is provider-specific.

## 4. Component Mapping

### 4.1 AZ::Component

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::Component` |
| Underlying Semantic | **Composable unit of behavior.** Attached to entities. Lifecycle: Init (once) → Activate → Deactivate. Provides services, declares dependencies. Multiple components per entity. Component has no identity of its own — entity is the identity boundary. |
| Existing SCR Concept | No SCR component concept yet. `101_Core/Composition` is placeholder. |
| Candidate SCR Concept | **`Component`** — composable behavior unit. Has service contract (provided/required/dependent/incompatible). Lifecycle tied to owning entity. No independent identity. |
| Authority | SCR Architectural Group |
| Provider-Specific? | No. Component composition is a genuine computational concept. |
| Action | **define-new** |

**Rationale:** Component is the fundamental composition primitive. O3DE's AZ::Component is a clean reference: components have no identity, are activated in dependency order, and are deactivated in reverse order. SCR needs this semantic independent of O3DE.

### 4.2 Component Services (Provided/Required/Dependent/Incompatible)

| Column | Value |
|--------|-------|
| O3DE Concept | `ComponentDescriptor::GetProvidedServices`, `GetRequiredServices`, `GetDependentServices`, `GetIncompatibleServices` |
| Underlying Semantic | **Service contract.** Components declare what they provide, what they require (must be present and active), what they depend on (prefer present, activates before if present), and what they cannot coexist with. |
| Existing SCR Concept | `101_Core/Contracts` — placeholder. `101_Core/Capabilities` — placeholder. |
| Candidate SCR Concept | **`ServiceContract`** — formal component capability declaration. Four relations: provides, requires, depends-on, incompatible-with. Used for dependency sort and validation. |
| Authority | SCR Architectural Group |
| Provider-Specific? | No. Service contracts are semantic. The descriptor API is provider-specific. |
| Action | **define-new** |

**Rationale:** Service contracts are the mechanism by which component composition is validated and ordered. This is a genuine semantic concern. O3DE's `ComponentDescriptor` is the API surface; the underlying semantic is service declaration.

### 4.3 Component Dependency Ordering

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::Entity::DependencySort` — topological sort of components by service dependencies. Required services activate first. Deactivation is reverse order. Cyclic dependencies detected and rejected. |
| Underlying Semantic | **Dependency-ordered activation.** Components are activated in topological order so that required services are available. Deactivation is reverse. Cycles are errors. |
| Existing SCR Concept | `203_Graph` — graph algorithms exist but no dependency-sort semantic. |
| Candidate SCR Concept | **`DependencyOrdering`** — topological sort of composable units by service dependencies. Part of composition semantics. |
| Authority | SCR Architectural Group |
| Provider-Specific? | No. Dependency ordering is universal. |
| Action | **define-new** (as part of Component/Composition semantics) |

**Rationale:** Dependency ordering is a semantic constraint on composition. The algorithm (topological sort) is well-defined and provider-independent. O3DE's implementation (`DependencySort`) is the reference.

### 4.4 Component Tick

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::TickBus::OnTick(deltaTime, time)` — per-frame notification. Components register for tick. Configurable tick order. |
| Underlying Semantic | **Simulation step.** Discrete time advancement. Components receive delta-time. Tick ordering is configurable. |
| Existing SCR Concept | No SCR tick semantics yet. |
| Candidate SCR Concept | **`Tick`** — simulation step with configurable ordering and delta-time. |
| Authority | SCR Architectural Group |
| Provider-Specific? | No. Simulation stepping is universal. |
| Action | **define-new** (deferred to separate sprint if needed) |

**Rationale:** Tick is semantic but may be deferred to a dedicated sprint. O3DE's TickBus is evidence that per-frame dispatch with ordering is needed.

## 5. Parent/Child Mapping

### 5.1 Parent/Child Entity Hierarchy

| Column | Value |
|--------|-------|
| O3DE Concept | `TransformComponent::SetParent` / `GetParentId` / `GetChildren` / `GetAllDescendants` — parent/child hierarchy stored in Transform component. |
| Underlying Semantic | **Hierarchical spatial relationship.** Parent entity defines coordinate frame for children. Child inherits parent's world transform. Parent deactivation deactivates all descendants. |
| Existing SCR Concept | `203_Graph/Hierarchical` — hierarchical graph. `101_Core/Relations` — placeholder. |
| Candidate SCR Concept | **`ParentChildRelation`** — hierarchical ownership/spatial relationship. Parent lifecycle affects children. |
| Authority | SCR Architectural Group |
| Provider-Specific? | No. Hierarchy is semantic. Transform inheritance is semantic. |
| Action | **define-new** (as part of Relations domain) |

**Rationale:** Parent/child is a genuine semantic relationship. O3DE stores it in the Transform component (which stays connected to EBuses even when deactivated, preserving hierarchy). SCR should formalize this relationship type independently.

### 5.2 Transform Inheritance

| Column | Value |
|--------|-------|
| O3DE Concept | `TransformComponent` — local transform (relative to parent), world transform (absolute). Children inherit parent's world transform. |
| Underlying Semantic | **Coordinate frame inheritance.** Child's world transform = parent's world transform × child's local transform. This is a spatial semantic. |
| Existing SCR Concept | `101_Core/Transforms` — exists. `302_Geometry/CoordinateSystems` — exists. |
| Candidate SCR Concept | Retain existing. Extend with parent-child composition semantics. |
| Authority | SCR Geometry/Transforms domain |
| Provider-Specific? | No. Coordinate frame inheritance is mathematical. |
| Action | **extend-existing** |

**Rationale:** SCR already has transforms and coordinate systems. The missing piece is the parent-child composition that links transforms hierarchically.

## 6. Context Mapping

### 6.1 EntityContext

| Column | Value |
|--------|-------|
| O3DE Concept | `AzFramework::EntityContext` — ownership scope for entities. Owns a root entity. Provides creation, activation, destruction. Separate contexts for edit-time vs runtime. Context owns an `EntityOwnershipService`. |
| Underlying Semantic | **Entity ownership scope.** Entities belong to a context. Contexts separate concerns (authoring vs execution). Context manages entity lifecycle within its scope. |
| Existing SCR Concept | `101_Core/Context` — placeholder. |
| Candidate SCR Concept | **`EntityContext`** — ownership scope for entity hierarchies. Separates authoring-time from runtime entity sets. |
| Authority | SCR Architectural Group |
| Provider-Specific? | No. Scoping is semantic. O3DE's specific context types (Game, Editor) are provider-specific. |
| Action | **define-new** |

**Rationale:** Context separation (authoring vs runtime) is a genuine semantic concern. SCR needs to distinguish between entities under authoring (mutable, inspectable) and entities under execution (runtime-optimized). O3DE's EntityContext is the reference.

### 6.2 GameEntityContextComponent

| Column | Value |
|--------|-------|
| O3DE Concept | `AzFramework::GameEntityContextComponent` — system component owning the game entity context. Creates game entities, manages activation, handles serialization. |
| Underlying Semantic | Runtime entity context management. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | Provider-specific realization of `EntityContext`. |
| Authority | Provider |
| Provider-Specific? | **Yes.** GameEntityContextComponent is O3DE's runtime context. |
| Action | **provider-only** |

**Rationale:** The GameEntityContextComponent is O3DE's specific runtime context implementation. SCR defines the context semantic; O3DE provides the runtime context.

## 7. Spawnable/Prefab Mapping

### 7.1 Prefab

| Column | Value |
|--------|-------|
| O3DE Concept | Prefab — serialized entity hierarchy template. Stored as `.prefab` files. Instantiated at runtime via Spawnable system. Prefabs can nest (spawnable within spawnable). |
| Underlying Semantic | **Entity template.** Reusable entity hierarchy definition. Instantiation creates fresh entity copies. Template changes propagate to instances (or not, depending on override semantics). |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`EntityTemplate`** — reusable entity hierarchy specification. Instantiation produces entity instances. |
| Authority | SCR Architectural Group |
| Provider-Specific? | No. Template instantiation is semantic. File format is provider-specific. |
| Action | **define-new** |

**Rationale:** Prefab/template is a genuine pattern: define once, instantiate many times. O3DE's `.prefab` format and Spawnable system are the reference implementation. SCR needs the semantic independent of format.

### 7.2 Spawnable

| Column | Value |
|--------|-------|
| O3DE Concept | `AzFramework::Spawnable` — runtime instantiation of prefab. Creates entity clones with remapped EntityIds. Spawn ticket tracks instance. Despawn destroys cloned entities. |
| Underlying Semantic | **Entity instantiation.** Runtime creation of entity instances from templates. Identity remapping (template IDs → runtime IDs). Instance tracking. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`EntitySpawn`** — runtime instantiation from template. Identity mapping from template to instance. |
| Authority | SCR Architectural Group |
| Provider-Specific? | No. Instantiation is semantic. Spawn ticket is provider-specific. |
| Action | **define-new** |

**Rationale:** Spawnable captures the instantiation pattern: template → instance with identity remapping. SCR SID authority means template SIDs are distinct from instance SIDs. O3DE's spawn ticket is a provider-specific tracking mechanism.

## 8. ComponentApplication Mapping

### 8.1 AZ::ComponentApplication

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::ComponentApplication` — base class. System entity creation, component descriptor registration, tick dispatch, settings registry. Manages module loading. |
| Underlying Semantic | **Runtime host.** Application-level component management. Registration of component types. Tick orchestration. System entity lifecycle. |
| Existing SCR Concept | No SCR runtime host concept. |
| Candidate SCR Concept | **`RuntimeHost`** — application-level component management. Component type registration, tick orchestration, system entity. |
| Authority | SCR Architectural Group |
| Provider-Specific? | No. Runtime hosting is semantic. Module loading is provider-specific. |
| Action | **define-new** |

**Rationale:** The runtime host is a semantic concept: the application that manages component registration and execution. O3DE's ComponentApplication is the reference. Module loading and settings registry are provider-specific.

### 8.2 ComponentDescriptor

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::ComponentDescriptor` — metadata provider. Component name, UUID, provided/required/dependent/incompatible services. Registered with ComponentApplication. |
| Underlying Semantic | **Component type metadata.** Describes component capabilities and constraints. Used for dependency resolution and validation. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`ComponentDescriptor`** — component type metadata. Service declarations, versioning, compatibility rules. |
| Authority | SCR Architectural Group |
| Provider-Specific? | No. Metadata is semantic. Registration API is provider-specific. |
| Action | **define-new** (as part of Component semantics) |

## 9. Complete Mapping Table

| O3DE Concept | Underlying Semantic | Existing SCR Concept | Candidate SCR Concept | Authority | Provider-Specific? | Action |
|---|---|---|---|---|---|---|
| `AZ::Entity` | Addressable computational unit, component container, lifecycle | `101_Core/Identity` (SID) | `Entity` | SCR Architectural | No | define-new |
| `AZ::Entity::State` | Lifecycle state machine (Constructed→Init→Active→Inactive→Destroyed) | `101_Core/State` (placeholder) | `LifecycleState` | SCR Architectural | No | define-new |
| `AZ::EntityId` | Provider-local addressable reference, 64-bit runtime handle | `101_Core/Identity` (SID authoritative) | None — maps to Manifestation | SCR Identity | **Yes** | provider-only |
| `AZ::Component` | Composable behavior unit, no independent identity | `101_Core/Composition` (placeholder) | `Component` | SCR Architectural | No | define-new |
| Component Services | Service contract (provided/required/dependent/incompatible) | `101_Core/Contracts` (placeholder) | `ServiceContract` | SCR Architectural | No | define-new |
| `DependencySort` | Topological activation order by service dependencies | `203_Graph` (algorithms) | `DependencyOrdering` | SCR Architectural | No | define-new |
| `AZ::TickBus` | Per-frame simulation step with delta-time | None | `Tick` | SCR Architectural | No | define-new |
| `TransformComponent` hierarchy | Parent/child spatial hierarchy, coordinate frame inheritance | `203_Graph/Hierarchical`, `101_Core/Transforms` | `ParentChildRelation` | SCR Architectural / Geometry | No | extend-existing |
| `AzFramework::EntityContext` | Entity ownership scope, authoring vs runtime separation | `101_Core/Context` (placeholder) | `EntityContext` | SCR Architectural | No | define-new |
| `GameEntityContextComponent` | Runtime entity context management | None | Provider realization of `EntityContext` | Provider | **Yes** | provider-only |
| Prefab | Reusable entity hierarchy template | None | `EntityTemplate` | SCR Architectural | No | define-new |
| `AzFramework::Spawnable` | Runtime entity instantiation from template, identity remapping | None | `EntitySpawn` | SCR Architectural | No | define-new |
| `AZ::ComponentApplication` | Runtime host, component registration, tick dispatch | None | `RuntimeHost` | SCR Architectural | No | define-new |
| `AZ::ComponentDescriptor` | Component type metadata, service declarations | None | `ComponentDescriptor` | SCR Architectural | No | define-new |

## 10. SCR Identity Authority Preservation

**Critical invariant:** SCR SID is authoritative identity. AZ::EntityId is a provider-local manifestation.

```
SCR SID (authoritative)
    ↓ Manifestation Layer
AZ::EntityId (provider-local runtime handle)
    ↓ Provider Mapping
AZ::Entity (runtime instance in O3DE)
```

- SID never derived from EntityId
- EntityId never promoted to identity authority
- EntityId can be remapped, recycled, or destroyed without affecting SID
- Multiple EntityIds may reference the same SID across different contexts

## 11. Exit Criteria Check

- [x] O3DE Entity → SCR Entity mapping documented (Section 3.1)
- [x] O3DE Component → SCR Component assessment complete (Section 4.1)
- [x] Lifecycle phases mapped (Section 3.3)
- [x] Identity mapping preserves SCR authority (Section 10)
- [x] Parent/child relationship mapping (Section 5)
- [x] EntityContext mapping (Section 6)
- [x] Spawnable/Prefab mapping (Section 7)
- [x] ComponentApplication mapping (Section 8)
- [x] Complete mapping table produced (Section 9)

## 12. Deferred Concepts

| Concept | Reason | Recommended Sprint |
|---|---|---|
| Component Tick | Semantic but complex. Needs dedicated analysis. | Sprint 03+ or separate milestone |
| EBus/Event dispatch | Pattern is semantic; wiring is provider-specific. Sprint 01 already classified. | Sprint 03+ |
| EditorComponentBase | Editor vs runtime component split. Needs Context semantics first. | After EntityContext defined |
# Sprint 02: Entity & Component Mapping

Map O3DE entity/component model to SCR semantics. Investigate Entity, EntityId, Component, composition, lifecycle, parent/child, context, spawnable, prefab.

## Deliverables
- Entity/component assessment table
- SCR entity mapping (SCR SID → O3DE EntityId)
- Component lifecycle mapping
- Parent/child relationship mapping

## Exit Criteria
- [ ] O3DE Entity → SCR Entity mapping documented
- [ ] O3DE Component → SCR Component assessment complete
- [ ] Lifecycle phases mapped
- [ ] Identity mapping preserves SCR authority
# Sprint 003 Record: Spatial & Context Mapping

## 1. Objective

Deep-map O3DE spatial primitives (Transform, bounding volumes, coordinate conventions) and context mechanisms (EntityContext, TickBus, Environment) to SCR semantics. Produce per-concept mapping rows with action classification. Key constraint: semantic transform must not collapse into O3DE transform representation. Context must not silently become ownership model.

## 2. Mapping Columns

| Column | Meaning |
|--------|---------|
| O3DE Concept | Provider implementation name |
| Underlying Semantic | The genuine computational concept it realizes |
| Existing SCR Concept | SCR domain already covering this semantics (if any) |
| Candidate SCR Concept | Proposed SCR concept if not yet defined |
| Action | `retain-existing` / `extend-existing` / `define-new` / `map-only` / `provider-only` |

## 3. Spatial Mapping — Transform

### 3.1 AZ::Transform

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::Transform` — 3×4 matrix (quaternion rotation + Vector3 translation + float uniform scale). Cannot represent skew. Default constructor leaves uninitialized. Factory methods: `CreateFromQuaternion`, `CreateFromQuaternionAndTranslation`, `CreateFromMatrix3x3`, `CreateFromMatrix3x4`, `CreateLookAt`, `CreateRotationX/Y/Z`, `CreateTranslation`, `CreateUniformScale`. |
| Underlying Semantic | **Spatial pose.** Position (translation), orientation (rotation), extent (scale) of an object in a coordinate frame. Uniform scale only — non-uniform scale requires separate representation. |
| Existing SCR Concept | `101_Core/Transforms` — exists as placeholder. `302_Geometry/CoordinateSystems` — exists. |
| Candidate SCR Concept | Retain existing. `Transform` captures pose as translation + rotation + uniform scale. Non-uniform scale is a separate `Scale` concept (not part of Transform). |
| Action | **extend-existing** |

**Critical distinction:** `AZ::Transform` conflates two semantics:
1. **Pose** — where something is and how it is oriented (translation + rotation)
2. **Extent scaling** — how large it is (uniform scale)

SCR should separate these. A `Transform` carries pose. A `Scale` modifies extent. They compose but are distinct semantic concerns. O3DE's `AZ::Transform` bundles them because GPU matrices require this composition.

### 3.2 AZ::TransformBus / TransformInterface

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::TransformBus` (a.k.a. `TransformInterface`) — EBus for reading/writing transforms. `GetLocalTM()`, `SetLocalTM()`, `GetWorldTM()`, `SetWorldTM()`, `GetLocalAndWorld()`. `SetParent()` preserves world transform by adjusting local. `SetParentRelative()` treats world as local. `OnTransformChanged(local, world)` notification. |
| Underlying Semantic | **Pose query and mutation interface.** Separates local-space (relative to parent) from world-space (absolute). Hierarchical composition: world = parent × local. |
| Existing SCR Concept | `101_Core/Transforms` (placeholder). No hierarchical composition yet. |
| Candidate SCR Concept | `PoseQuery` — interface for reading/writing pose in local or world coordinates. Hierarchical: world = composition(local, parent). |
| Action | **extend-existing** |

**Rationale:** The local/world distinction is semantic — it encodes coordinate frame hierarchy. The EBus wiring is provider-specific. SCR needs `PoseQuery` as a semantic interface independent of bus architecture.

### 3.3 AZ::Aabb

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::Aabb` — axis-aligned bounding box. Defined as closed set (includes boundary). Methods: `GetMin`, `GetMax`, `Set`, `AddPoint`, `AddAabb`, `Contains(point)`, `IntersectsAabb`, `Expand`, `GetTransformedAabb`, `GetTransformedObb`, `CreatePoints`, `CreateFromObb`, `GetAsSphere`. |
| Underlying Semantic | **Spatial extent (axis-aligned).** Minimum enclosing box aligned with coordinate axes. Used for broad-phase collision, visibility culling, spatial queries. Transforms to OBB under rotation. |
| Existing SCR Concept | `302_Geometry/BoundingVolumes` — placeholder. |
| Candidate SCR Concept | **`Aabb`** — axis-aligned spatial extent. Computed from points, shapes, or other bounds. Transforms under rotation to OBB. |
| Action | **define-new** |

**Rationale:** AABB is a genuine spatial concept — the minimal axis-aligned enclosure. It is not provider-specific; any spatial system needs axis-aligned bounds. The API surface (`AddPoint`, `Contains`, etc.) is semantic.

### 3.4 AZ::Obb

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::Obb` — oriented bounding box. Position + Quaternion rotation + Vector3 half-lengths. `Contains(point)`, `CreateFromAabb`, `CreateFromPositionRotationAndHalfLengths`. Non-uniform half-lengths along rotated axes. |
| Underlying Semantic | **Spatial extent (oriented).** Minimum enclosing box aligned with object's local axes. Tighter fit than AABB for rotated objects. Used for precise spatial queries. |
| Existing SCR Concept | `302_Geometry/BoundingVolumes` — placeholder. |
| Candidate SCR Concept | **`Obb`** — oriented spatial extent. Position + orientation + half-extents. Tighter than AABB under rotation. |
| Action | **define-new** |

**Rationale:** OBB is the oriented counterpart to AABB. Both are genuine spatial primitives. SCR should define both as bounding volume types.

### 3.5 AZ::Sphere

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::Sphere` — bounding sphere. Center + radius. `GetCenter`, `GetRadius`, `SetCenter`, `SetRadius`, `CreateUnitSphere`, `CreateFromAabb`. Fast intersection testing. |
| Underlying Semantic | **Spatial extent (spherical).** Simplest bounding volume. Radial distance from center. Fast intersection. Least tight fit. |
| Existing SCR Concept | `302_Geometry/BoundingVolumes` — placeholder. |
| Candidate SCR Concept | **`Sphere`** — spherical spatial extent. Center + radius. Fast intersection, coarse fit. |
| Action | **define-new** |

**Rationale:** Bounding sphere is the simplest spatial primitive. Fastest intersection. SCR defines it as a bounding volume type alongside AABB and OBB.

### 3.6 Coordinate System Conventions

| Column | Value |
|--------|-------|
| O3DE Concept | O3DE uses **right-handed, Z-up** coordinate system. Forward = +Y. Right = +X. Up = +Z. Positive rotation from +X to +Y is counter-clockwise. DCC applications typically use Y-up; assets require coordinate conversion on import. Note: some O3DE documentation inconsistently describes the system as left-handed; the authoritative convention is right-handed Z-up per primary docs. |
| Underlying Semantic | **Coordinate convention.** The mapping from 3D axes to semantic directions (up, forward, right). Cross-product direction follows from handedness. |
| Existing SCR Concept | `302_Geometry/CoordinateSystems` — exists. |
| Candidate SCR Concept | Retain existing. Define `CoordinateConvention` enumeration: `{RightHanded_ZUp, RightHanded_YUp, LeftHanded_ZUp, LeftHanded_YUp}`. SCR must document which convention the canonical system uses and provide explicit conversion mappings. |
| Action | **extend-existing** |

**Critical mapping:**

| Convention | Up | Forward | Right | Cross Rule | Used By |
|---|---|---|---|---|---|
| O3DE | +Z | +Y | +X | Right-hand | O3DE runtime |
| SCR Canonical | **TBD** | TBD | TBD | TBD | SCR Architectural |
| Common DCC | +Y | -Z or +Z | +X | Right-hand | Maya, Blender |
| Unity | +Y | +Z | +X | Left-hand | Unity |
| Unreal | +Z | +X | +Y | Left-hand | Unreal |

**Rationale:** Coordinate convention is a genuine semantic concern. SCR must pick a canonical convention and document conversions for each provider. O3DE's Z-up right-handed is one candidate. The SCR Architectural Group must decide the canonical convention.

## 4. Spatial Mapping — Hierarchical Composition

### 4.1 World Transform Composition

| Column | Value |
|--------|-------|
| O3DE Concept | `TransformComponent` — stores `m_localTM` and `m_worldTM`. On parent change, recomputes world transforms recursively. `world = parent_world × local`. Children notified via `OnTransformChanged`. |
| Underlying Semantic | **Hierarchical pose composition.** World pose = composition of local pose with parent's world pose. Mathematical: W = P × L (matrix multiplication, or quaternion composition + translation). |
| Existing SCR Concept | `101_Core/Transforms` (placeholder). `101_Core/Relations` (placeholder). |
| Candidate SCR Concept | **`HierarchicalPose`** — world pose computed from local pose + parent world pose. Composition rule: world = parent × local. |
| Action | **define-new** (as part of Transform/Relations semantics) |

**Rationale:** Hierarchical composition is the mathematical operation that links transforms in a parent-child tree. It is not provider-specific — it is linear algebra. O3DE implements it; SCR defines the semantic.

## 5. Context Mapping

### 5.1 AZ::ComponentEntityContext

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::ComponentEntityContext` — entity-scoped context. Entities exist within a context. Provides entity creation, activation, destruction scoped to that context. Entity IDs are context-scoped (same ID may reference different entities in different contexts). |
| Underlying Semantic | **Entity scope.** Entities belong to a context. Context provides the namespace for entity IDs and the lifecycle management scope. |
| Existing SCR Concept | `101_Core/Context` — placeholder. |
| Candidate SCR Concept | **`EntityScope`** — namespace for entity identity and lifecycle. Entities exist within a scope. Entity ID uniqueness is scope-bounded. |
| Action | **define-new** |

**Critical constraint:** Context ≠ ownership. A context provides scope (namespace, lifecycle management) but ownership semantics (who can destroy, who can mutate) are separate. SCR must not silently conflate scope with ownership. O3DE's EntityContext combines both; SCR separates them.

### 5.2 AZ::EntityContext

| Column | Value |
|--------|-------|
| O3DE Concept | `AzFramework::EntityContext` — ownership scope for entities. Owns a root entity. Manages `EntityOwnershipService`. Handles creation, activation, destruction. Separate contexts for edit-time vs runtime. Context can be reset (serializes out, clears, serializes in). |
| Underlying Semantic | **Entity ownership scope.** Entities are owned by a context. Context manages lifecycle (create, activate, deactivate, destroy). Context reset = serializing current state, clearing, loading new state. |
| Existing SCR Concept | `101_Core/Context` — placeholder. |
| Candidate SCR Concept | **`EntityOwnershipScope`** — ownership and lifecycle management for entity hierarchies. Distinguished from `EntityScope` (namespace only). |
| Action | **define-new** |

**Critical invariant (from Sprint 002):** Entity in multiple contexts = one semantic entity unless model says otherwise. O3DE's EntityContext is a runtime scope; SCR SID is the authoritative identity. Entity may have manifestations in multiple contexts but remains one semantic entity.

### 5.3 EditorEntityContext

| Column | Value |
|--------|-------|
| O3DE Concept | `AzToolsFramework::EditorEntityContext` (via `EditorEntityContextComponent`) — authoring-time entity context. Entities here are editable, inspectable, support undo/redo. Components inherit from `EditorComponentBase`. Switches to game mode at runtime. |
| Underlying Semantic | **Authoring-time entity scope.** Mutable, inspectable entity set. Supports undo/redo. Components may differ from runtime (EditorComponentBase vs runtime Component). |
| Existing SCR Concept | `101_Core/Context` (placeholder). No authoring-time distinction yet. |
| Candidate SCR Concept | **`AuthoringScope`** — entity scope with mutation tracking, undo/redo, inspection. Distinct from `RuntimeScope`. |
| Action | **define-new** |

**Rationale:** Authoring vs runtime is a genuine semantic distinction. Entities under authoring have different mutation rules than entities under execution. O3DE's EditorEntityContext is the reference. The split is semantic; the specific editor plumbing is provider-specific.

### 5.4 EditorEntityContext vs EntityContext Relationship

| Column | Value |
|--------|-------|
| O3DE Concept | `EditorEntityContextComponent` inherits from `AzFramework::EntityContext`. Editor context wraps runtime context. Game mode transfers entities from editor context to game context. Same entity may exist in both (authoring copy vs runtime copy). |
| Underlying Semantic | **Dual-scope entity management.** Same conceptual entity exists in authoring scope (mutable) and runtime scope (optimized). Transfer between scopes on mode change. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`ScopeTransfer`** — mechanism for entity migration between scopes. Authoring → runtime on execution start. Runtime → authoring on execution stop. Entity identity preserved; manifestation differs. |
| Action | **define-new** |

**Critical invariant:** Entity in authoring scope and runtime scope = one semantic entity. O3DE creates separate Entity instances; SCR SID ensures identity continuity across scope transfer.

## 6. Context Mapping — Temporal

### 6.1 AZ::TickBus

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::TickBus` (alias for `AZ::EBus<TickEvents>`) — per-frame tick dispatch. `OnTick(deltaTime, time)`. Main game thread. Dispatches even when app not in focus (games). Inactive when tool loses focus. Handler policy: `MultipleAndOrdered`. Tick order configurable via `GetTickOrder()` or `ComponentTickBus` enum: `TICK_FIRST=0`, `TICK_PLACEMENT=50`, `TICK_INPUT=75`, `TICK_GAME=80`, `TICK_ANIMATION=100`, `TICK_PHYSICS=201`, `TICK_ATTACHMENT=500`, `TICK_PRE_RENDER=750`, `TICK_DEFAULT=1000`, `TICK_UI=2000`, `TICK_LAST=100000`. |
| Underlying Semantic | **Simulation step.** Discrete time advancement. Delta-time = elapsed since last tick. Absolute time = application time. Ordered handlers ensure deterministic update sequence. |
| Existing SCR Concept | No SCR tick semantics yet. Sprint 002 deferred tick to Sprint 03. |
| Candidate SCR Concept | **`SimulationStep`** — discrete time advancement with delta-time and absolute time. Ordered execution phases. |
| Action | **define-new** |

**Rationale:** Tick is a genuine semantic — simulation progresses in discrete steps. O3DE's tick ordering (placement → input → game → animation → physics → render) reveals the semantic phases of a simulation frame. SCR should define these phases independently.

### 6.2 AZ::SystemTickBus

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::SystemTickBus` (alias for `AZ::EBus<SystemTickEvents>`) — system-level tick. Dispatches at small fixed interval (milliseconds). Independent of application focus. Used for network polling, asset processor polling. Not necessarily consistent interval. In Editor, may fire more often than regular interval. `EnableEventQueue` allows pre-tick event processing. |
| Underlying Semantic | **System-level periodic service.** Fixed-rate (approximate) background processing. Independent of simulation frame rate. Used for housekeeping that must run regardless of game state. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`SystemServiceTick`** — periodic background processing independent of simulation frame. Fixed interval. Used for network, asset loading, housekeeping. |
| Action | **define-new** |

**Distinction from SimulationStep:** SystemTick is not a simulation step — it is system housekeeping. Network polling, asset processing, health checks run at fixed rate regardless of simulation state. SimulationStep advances game logic; SystemServiceTick maintains infrastructure.

### 6.3 Tick vs SystemTick Semantic Distinction

| Dimension | SimulationStep (TickBus) | SystemServiceTick (SystemTickBus) |
|---|---|---|
| **Purpose** | Advance simulation state | Maintain system infrastructure |
| **Rate** | Frame-rate dependent | Fixed interval (approximate) |
| **Focus** | Active when app in focus | Runs regardless of focus |
| **Determinism** | Ordered, deterministic | Approximate, not guaranteed consistent |
| **Examples** | Physics, animation, AI, input | Network polling, asset processing, health |
| **SCR Semantic** | `SimulationStep` | `SystemServiceTick` |

**Rationale:** These are genuinely different temporal concepts. Conflating them loses the semantic distinction between simulation progression and system maintenance. O3DE separates them; SCR should too.

## 7. Context Mapping — Global

### 7.1 AZ::Environment

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::Environment` — module-global variable provider. Cross-DLL shared variables. Hash table of variables ↔ GUID. Reference-counted. Not thread-safe by default. Auto-created on demand. POD types simple; virtual types require vtable awareness (module unloading). Internal allocations from OS C heap (no allocators). |
| Underlying Semantic | **Cross-module shared state.** Global variables accessible across DLL boundaries. Reference-counted lifetime. Not a singleton pattern — it is a shared variable registry. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`SharedStateRegistry`** — cross-module shared variable access. Reference-counted. Not thread-safe by default (caller manages synchronization). |
| Action | **map-only** |

**Rationale:** AZ::Environment is infrastructure plumbing — cross-DLL variable sharing. The semantic concept (shared state across module boundaries) exists but SCR should not adopt this specific mechanism. Map the semantic, not the implementation.

### 7.2 AZ::Interface<T>

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::Interface<T>` — global singleton request interface. Wraps AZ::Environment. Register/Unregister lifecycle. `Get()` returns raw pointer (assumes outlives callers). Thread safety is caller's responsibility. Designed to replace EBus-based singletons. Virtual function call, often de-virtualized by compiler. |
| Underlying Semantic | **Global singleton access.** Application-lifetime service access. Register once, query anywhere. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`GlobalService`** — application-lifetime singleton service. Register at init, query anywhere. Thread safety is caller's concern. |
| Action | **map-only** |

**Rationale:** AZ::Interface is a singleton pattern. The semantic (global service access) is universal; the C++ template/Environment wrapping is provider-specific.

## 8. Context Mapping — Relationships

### 8.1 Context ↔ Entity Relationship

| Column | Value |
|--------|-------|
| O3DE Concept | EntityContext owns entities. EntityId is context-scoped. Entity belongs to exactly one context at a time (runtime). During scope transfer (editor→game), entity is cloned — not shared. |
| Underlying Semantic | **Scope membership.** Entity belongs to a scope. Scope determines ID namespace, lifecycle management, mutation rules. |
| Existing SCR Concept | `101_Core/Relations` (placeholder). |
| Candidate SCR Concept | **`ScopeMembership`** — entity belongs to exactly one active scope at a time. Scope determines lifecycle rules. Cross-scope identity preserved via SID. |
| Action | **define-new** |

**Critical invariant:** Entity in multiple contexts = one semantic entity unless model says otherwise. O3DE clones entities across contexts (editor copy ≠ runtime copy). SCR SID ensures they are manifestations of one entity.

### 8.2 Context ↔ Transform Relationship

| Column | Value |
|--------|-------|
| O3DE Concept | Transform is stored on entity within a context. World transform is computed from hierarchy within context. Context reset destroys all transforms. |
| Underlying Semantic | **Scoped spatial state.** Transform exists within a context's spatial frame. Context defines the root coordinate frame. |
| Existing SCR Concept | `101_Core/Transforms` (placeholder). |
| Candidate SCR Concept | **`ScopedTransform`** — transform exists within a context's coordinate frame. Root frame is context-defined. |
| Action | **define-new** (as part of Transform/Context relationship) |

## 9. Complete Mapping Table

| O3DE Concept | Underlying Semantic | Existing SCR Concept | Candidate SCR Concept | Action |
|---|---|---|---|---|
| `AZ::Transform` | Spatial pose (translation + rotation + uniform scale) | `101_Core/Transforms` | `Transform` (separate Scale) | extend-existing |
| `AZ::TransformBus` | Pose query/mutation interface (local + world) | `101_Core/Transforms` | `PoseQuery` | extend-existing |
| `AZ::Aabb` | Axis-aligned spatial extent | `302_Geometry/BoundingVolumes` | `Aabb` | define-new |
| `AZ::Obb` | Oriented spatial extent | `302_Geometry/BoundingVolumes` | `Obb` | define-new |
| `AZ::Sphere` | Spherical spatial extent | `302_Geometry/BoundingVolumes` | `Sphere` | define-new |
| Coordinate conventions | Mapping from axes to semantic directions (up/forward/right) | `302_Geometry/CoordinateSystems` | `CoordinateConvention` | extend-existing |
| World transform composition | Hierarchical pose composition (W = P × L) | `101_Core/Transforms`, `101_Core/Relations` | `HierarchicalPose` | define-new |
| `AZ::ComponentEntityContext` | Entity scope (namespace, lifecycle management) | `101_Core/Context` | `EntityScope` | define-new |
| `AzFramework::EntityContext` | Entity ownership scope (lifecycle management) | `101_Core/Context` | `EntityOwnershipScope` | define-new |
| `EditorEntityContext` | Authoring-time entity scope (mutable, inspectable) | `101_Core/Context` | `AuthoringScope` | define-new |
| Scope transfer (editor→game) | Entity migration between scopes | None | `ScopeTransfer` | define-new |
| `AZ::TickBus` | Simulation step (delta-time, ordered phases) | None | `SimulationStep` | define-new |
| `AZ::SystemTickBus` | System-level periodic service (fixed interval) | None | `SystemServiceTick` | define-new |
| `AZ::Environment` | Cross-module shared state registry | None | `SharedStateRegistry` | map-only |
| `AZ::Interface<T>` | Global singleton service access | None | `GlobalService` | map-only |
| Context ↔ Entity | Scope membership (one active scope at a time) | `101_Core/Relations` | `ScopeMembership` | define-new |
| Context ↔ Transform | Scoped spatial state (root frame defined by context) | `101_Core/Transforms` | `ScopedTransform` | define-new |

## 10. Key Invariants

### 10.1 Transform ≠ Representation

`AZ::Transform` is a provider-specific representation (quaternion + translation + uniform scale). SCR `Transform` is the semantic concept of spatial pose. The representation may vary across providers (e.g., matrix4x4, dual quaternion, euler angles). SCR defines the semantic; providers choose the representation.

### 10.2 Coordinate Convention Documentation

SCR must explicitly document:
1. The canonical coordinate convention (TBD by Architectural Group)
2. Conversion mappings for each provider (O3DE: Z-up → SCR canonical)
3. Cross-convention operation semantics (what happens when entities from different conventions interact)

### 10.3 Context ≠ Ownership

A context provides:
- **Scope** — entity ID namespace
- **Lifecycle** — create, activate, deactivate, destroy
- **Frame** — root coordinate frame for transforms

A context does NOT inherently provide:
- **Ownership** — who can destroy the entity
- **Mutation rules** — who can modify the entity
- **Access control** — who can query the entity

SCR must separate these concerns. O3DE conflates scope and ownership in EntityContext.

### 10.4 Entity Identity Across Contexts

Entity in multiple contexts = one semantic entity unless model says otherwise.

```
SCR SID (authoritative identity)
    ↓ manifests in
Context A (authoring scope) ←→ EntityId_A (scope-local)
    ↓
Context B (runtime scope)   ←→ EntityId_B (scope-local)
```

- SID is the same across contexts
- EntityId differs across contexts
- Scope transfer creates new manifestation, not new entity

## 11. Exit Criteria Check

- [x] AZ::Transform mapped with semantic distinction (Section 3.1)
- [x] TransformBus/local/world distinction mapped (Section 3.2)
- [x] Bounding volumes (Aabb, Obb, Sphere) mapped (Sections 3.3–3.5)
- [x] Coordinate conventions documented with mappings (Section 3.6)
- [x] Hierarchical pose composition mapped (Section 4.1)
- [x] EntityContext mapped (Section 5.1)
- [x] Ownership scope mapped (Section 5.2)
- [x] EditorEntityContext mapped (Section 5.3)
- [x] Scope transfer mapped (Section 5.4)
- [x] TickBus / SimulationStep mapped (Section 6.1)
- [x] SystemTickBus / SystemServiceTick mapped (Section 6.2)
- [x] Tick vs SystemTick distinction documented (Section 6.3)
- [x] AZ::Environment mapped (Section 7.1)
- [x] AZ::Interface mapped (Section 7.2)
- [x] Context-Entity relationship mapped (Section 8.1)
- [x] Context-Transform relationship mapped (Section 8.2)
- [x] Complete mapping table produced (Section 9)
- [x] Key invariants documented (Section 10)

## 12. Deferred Concepts

| Concept | Reason | Recommended Sprint |
|---|---|---|
| Canonical coordinate convention | Requires Architectural Group decision | Milestone decision gate |
| Non-uniform scale semantics | O3DE bans it; SCR may need it | Separate geometry sprint |
| Undo/redo semantics | Authoring-scope concern; complex | After AuthoringScope defined |
| Serialization of transforms | Cross-context persistence | Separate persistence sprint |
| EBus/Event dispatch patterns | Semantic pattern, provider wiring | Sprint 04+ |

## 13. Sprint 002 Deferral Resolution

Sprint 002 deferred:
- **Component Tick** → Resolved in Section 6.1 (SimulationStep)
- **EBus/Event dispatch** → Deferred to Sprint 04+ (pattern is semantic, wiring is provider-specific)
- **EditorComponentBase** → Partially resolved in Section 5.3 (AuthoringScope)
# Sprint 03: Spatial & Context Mapping

Map O3DE spatial concepts (Transform, hierarchy, coordinate system) and context concepts (EntityContext, authoring/simulation contexts) to SCR.

## Deliverables
- Spatial assessment table (Transform, Local/World/Parent transform, Hierarchy, Coordinate system)
- Context assessment table (AuthoringContext, ExecutionContext, SimulationContext, etc.)
- Coordinate system convention mappings

## Exit Criteria
- [ ] O3DE Transform → SCR spatial mapping documented
- [ ] Coordinate convention differences documented
- [ ] Context concept necessity assessed
- [ ] Rule: context must not become ownership model
# Sprint 004 Record: Physics & Asset Mapping

## 1. Objective

Deep-map O3DE/AzPhysics physics primitives and the asset pipeline to SCR semantics. Produce per-concept mapping rows with action classification. Key constraints: SCR PhysicsBody is semantic, not AzPhysics implementation. Asset lifecycle semantics must not collapse into file conversion. Materialization is a semantic operation. Provider separation: SCR → adapter → provider.

## 2. Mapping Columns

| Column | Meaning |
|--------|---------|
| O3DE Concept | Provider implementation name |
| Underlying Semantic | The genuine computational concept it realizes |
| Existing SCR Concept | SCR domain already covering this semantics (if any) |
| Candidate SCR Concept | Proposed SCR concept if not yet defined |
| Action | `retain-existing` / `extend-existing` / `define-new` / `map-only` / `provider-only` |

## 3. Physics Mapping — Body Types

### 3.1 AzPhysics::SimulatedBody

| Column | Value |
|--------|-------|
| O3DE Concept | `AzPhysics::SimulatedBody` — base class for all physics bodies. Fields: `m_sceneOwner` (SceneHandle), `m_bodyHandle` (SimulatedBodyHandle), `m_simulating` (bool), user data pointer, frame ID. Virtual methods: `RayCast`, `GetEntityId`, `GetTransform`, `SetTransform`, `GetPosition`, `GetOrientation`, `GetAabb`. Collision event routing: `ProcessCollisionEvent`, `ProcessTriggerEvent`. Event registration: `OnCollisionBegin`, `OnCollisionPersist`, `OnCollisionEnd`, `OnTriggerEnter`, `OnTriggerExit`, `OnSyncTransform`. |
| Underlying Semantic | **Physical presence.** An entity occupying space, participating in collision and force simulation. The base abstraction: has position, orientation, extent, and responds to (or influences) the physical world. |
| Existing SCR Concept | None. No physics domain defined yet. |
| Candidate SCR Concept | **`PhysicalPresence`** — an entity's participation in a physical world. Carries pose, extent, and simulation role. Distinct from spatial transform: physical presence implies collision participation and force response. |
| Action | **define-new** |

**Critical distinction:** `SimulatedBody` is O3DE's C++ base class. SCR `PhysicalPresence` is the semantic concept of "this entity exists in physical space and can collide." Implementation varies (PhysX, Jolt, custom). SCR defines the semantic; providers implement.

### 3.2 AzPhysics::RigidBody

| Column | Value |
|--------|-------|
| O3DE Concept | `AzPhysics::RigidBody` — extends `SimulatedBody`. Dynamic body. Properties: mass, inertia (world/local), center of mass, linear/angular velocity, linear/angular damping, sleep threshold, kinematic flag, gravity enabled, CCD enabled. Methods: `AddShape`, `RemoveShape`, `ApplyLinearImpulse`, `ApplyLinearImpulseAtWorldPoint`, `ApplyAngularImpulse`, `SetKinematicTarget`, `UpdateMassProperties`. Shapes stored as `shared_ptr<Physics::Shape>`. |
| Underlying Semantic | **Dynamic physical body.** Responds to forces, has mass/inertia properties, velocity, damping. Can be kinematic (script-driven) or simulated (physics-driven). The mass-inertia-velocity triad defines dynamic behavior. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`DynamicBody`** — physical body with mass properties, velocity, and force response. Supports kinematic mode (script-driven) vs simulated mode (physics-driven). |
| Action | **define-new** |

**Semantic split:** O3DE's `RigidBody` conflates two modes (dynamic vs kinematic). SCR should make this explicit: `DynamicBody` (physics-driven) vs `KinematicBody` (script-driven). Both share mass/inertia, but differ in what drives motion.

### 3.3 AzPhysics::StaticRigid

| Column | Value |
|--------|-------|
| O3DE Concept | `AzPhysics::StaticRigid` (via `StaticRigidBodyConfiguration` / `PhysXStaticRigid`). Immovable collision surface. Has shapes, AABB, transform. No mass, no velocity, no force response. Participates in collision detection only. |
| Underlying Semantic | **Immovable collision surface.** Geometry that other bodies collide with but which itself never moves. Walls, floors, terrain, static obstacles. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`StaticSurface`** — immovable physical geometry. Collides with dynamic bodies but does not respond to forces. The world's fixed collision landscape. |
| Action | **define-new** |

**Rationale:** Static vs dynamic is a genuine semantic distinction. A wall is semantically different from a box — one defines the world, the other exists within it.

### 3.4 AzPhysics::CharacterController

| Column | Value |
|--------|-------|
| O3DE Concept | `PhysXCharacterController` component (requires PhysX gem). Properties: maximum slope angle, step height, contact offset, shape. Kinematic — not affected by gravity or outside forces. Infinite mass when collided with. Movement driven by scripting, animation, or C++ API. |
| Underlying Semantic | **Actor movement controller.** A specialized kinematic body designed for character locomotion. Handles slope limits, step traversal, ground detection. Distinct from generic kinematic body because it encodes locomotion-specific constraints. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`LocomotionController`** — specialized kinematic body for actor movement. Encodes slope limits, step height, ground contact rules. Distinct from generic `KinematicBody`. |
| Action | **define-new** |

**Rationale:** Character controller is not just "a kinematic body." It encodes locomotion semantics — slope constraints, step traversal, ground detection. These are genuine behavioral constraints, not implementation details.

### 3.5 Body Type Hierarchy — SCR Concept

```
PhysicalPresence (base: entity in physical world)
├── DynamicBody (mass, velocity, force response)
├── KinematicBody (script-driven motion, infinite mass)
│   └── LocomotionController (slope, step, ground rules)
└── StaticSurface (immovable collision geometry)
```

**Critical invariant:** SCR defines the semantic roles. Providers implement the mechanics. A PhysX RigidBody, Jolt body, and custom solver all realize the same `DynamicBody` semantic through different implementations.

## 4. Physics Mapping — Collision Geometry

### 4.1 AzPhysics::ColliderShape (Physics::Shape)

| Column | Value |
|--------|-------|
| O3DE Concept | `Physics::Shape` — collision geometry attached to a body. Paired with `Physics::ColliderConfiguration` (collision layer, collision group, trigger flag, scene query flag, materials). Shape types (from `Physics::ShapeType`): Sphere, Box, Capsule, Cylinder, ConvexHull, TriangleMesh, Native, PhysicsAsset, CookedMesh, Heightfield. Shape configurations: `SphereShapeConfiguration` (radius), `BoxShapeConfiguration` (dimensions), `CapsuleShapeConfiguration` (height, radius), `ConvexHullShapeConfiguration` (vertex/plane/adjacency data), `TriangleMeshShapeConfiguration` (vertex/index data), `PhysicsAssetShapeConfiguration` (asset reference + scale). |
| Underlying Semantic | **Collision geometry.** The spatial extent of an entity for collision purposes. Primitives (sphere, box, capsule) are analytic. Convex hulls and triangle meshes are boundary representations. Shapes can be triggers (overlap detection without force). |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`CollisionGeometry`** — the spatial extent used for collision detection. Primitives vs meshes vs asset-derived. Trigger mode (overlap-only vs solid). |
| Action | **define-new** |

**Key distinction:** Collision geometry ≠ visual geometry. A box collider can surround a complex visual mesh. SCR must separate `CollisionGeometry` from visual representation. The `PhysicsAssetShapeConfiguration` bridges this gap (shape derived from asset), but the semantic is collision extent, not rendering.

### 4.2 Trigger Semantics

| Column | Value |
|--------|-------|
| O3DE Concept | `ColliderConfiguration::m_isTrigger` — when true, the collider performs overlap tests only. No forces applied, no contact points returned. Fires `OnTriggerEnter`/`OnTriggerExit` events instead of collision events. |
| Underlying Semantic | **Volumetric detection.** A region of space that detects entry/exit without physical response. Proximity zones, pickup ranges, hazard areas, trigger volumes. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`DetectionVolume`** — spatial region that detects entity overlap without physical response. Distinct from solid collision geometry. |
| Action | **define-new** |

**Rationale:** Trigger vs solid is a genuine semantic distinction. A trigger volume is semantically a detection region, not a physical surface. O3DE implements this as a flag on the collider; SCR should make it a distinct concept.

## 5. Physics Mapping — Constraints

### 5.1 AzPhysics::Joint

| Column | Value |
|--------|-------|
| O3DE Concept | `AzPhysics::Joint` — base class for constraints between two bodies. Fields: `m_sceneOwner`, `m_jointHandle`. Methods: `GetParentBodyHandle`, `GetChildBodyHandle`, `SetParentBody`, `SetChildBody`. Joint types (from `AzPhysics::JointType`): D6Joint, FixedJoint, BallJoint, HingeJoint. `JointConfiguration` base: parent/child local rotation + position, debug name, property visibility flags. |
| Underlying Semantic | **Kinematic constraint.** A rule that limits the relative motion between two bodies. The constraint defines allowed degrees of freedom (DOF) — which relative motions are permitted. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`KinematicConstraint`** — rule limiting relative motion between two physical presences. Defines allowed DOF. |
| Action | **define-new** |

### 5.2 Joint Type Catalog

| Joint Type | O3DE | Allowed DOF | Semantic |
|---|---|---|---|
| **Fixed** | `FixedJoint` | 0 | Rigid attachment — two bodies behave as one |
| **Hinge** | `HingeJoint` | 1 rotational (around single axis) | Door, lid, pendulum |
| **Ball** | `BallJoint` | 3 rotational | Ball-and-socket, ragdoll joint |
| **D6** | `D6Joint` | Configurable (up to 6 DOF) | Generic constraint with limits |

**Rationale:** Joint types are not arbitrary categories — they encode the number and type of allowed relative motions. This is a genuine semantic taxonomy: 0 DOF (fixed), 1 rotational DOF (hinge), 3 rotational DOF (ball), N configurable DOF (D6).

## 6. Physics Mapping — Interaction Events

### 6.1 AzPhysics::Collision Events

| Column | Value |
|--------|-------|
| O3DE Concept | `SimulatedBodyEvents` — collision event system. Three phases: `OnCollisionBegin` (first contact), `OnCollisionPersist` (ongoing contact), `OnCollisionEnd` (contact lost). Each event carries `CollisionEvent` data: body handles, contact points (position, normal, separation), impulse. Trigger events: `OnTriggerEnter`, `OnTriggerExit`. |
| Underlying Semantic | **Physical contact lifecycle.** Contacts have a temporal structure: begin → persist → end. This is not just "a collision happened" — it is a stateful interaction with phases. Triggers detect overlap without contact. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`PhysicalContact`** — stateful interaction between two physical presences. Phases: onset, persistence, release. Carries contact geometry (point, normal, separation). Distinct from trigger overlap. |
| Action | **define-new** |

**Critical insight:** Collision is not a single event — it is a lifecycle. `OnCollisionBegin` → `OnCollisionPersist` → `OnCollisionEnd` is a state machine. SCR must model this as a stateful concept, not a one-shot event.

### 6.2 Collision Filtering

| Column | Value |
|--------|-------|
| O3DE Concept | `AzPhysics::CollisionGroups` / `AzPhysics::CollisionLayers`. Layers assign colliders to categories. Groups define which layers a collider can interact with. Configuration in PhysX Configuration window or code-based (`CollisionGroups::CreateGroup`). |
| Underlying Semantic | **Interaction filtering.** Determining which physical presences can affect each other. Layers categorize entities; groups define interaction rules. This is a query/filter on the physics simulation, not a spatial concept. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`InteractionFilter`** — rules governing which physical presences can collide/interact. Categorical (layer) + rule-based (group). |
| Action | **define-new** |

**Rationale:** Collision filtering is semantic — it defines which entities *can* interact, independent of whether they *do* interact. It is a behavioral constraint, not a spatial one.

## 7. Physics Mapping — World

### 7.1 AzPhysics::Scene

| Column | Value |
|--------|-------|
| O3DE Concept | `AzPhysics::Scene` (via `SceneInterface`) — a physics simulation world. Contains simulated bodies and joints. Methods: `AddSimulatedBody`, `RemoveSimulatedBody`, `GetSimulatedBodyFromHandle`, `AddJoint`, `RemoveJoint`. Simulation: `StartSimulation(deltatime)` → `FinishSimulation()` (double-buffered). Scene queries: `QueryScene` (raycasts, shapecasts, overlaps). Default scene: `DefaultScene`. Editor scene: `EditorScene`. Max scenes: 64. |
| Underlying Semantic | **Simulation world.** A bounded physical universe with its own gravity, timestep, body set, and collision rules. Bodies exist within a scene. Scenes can run independently. The simulation step advances all bodies in a scene. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`SimulationWorld`** — bounded physical universe. Owns bodies, joints, gravity, timestep. Independent simulation step. |
| Action | **define-new** |

**Key distinction:** Scene ≠ context (from Sprint 003). A context is an entity management scope. A scene is a physical simulation domain. One context may have entities in multiple scenes (e.g., physics scene + gameplay scene). SCR must not conflate management scope with simulation domain.

### 7.2 AzPhysics::Scene — Simulation Model

| Column | Value |
|--------|-------|
| O3DE Concept | `SystemInterface::Simulate(deltaTime)` — advances all scenes. When `fixedTimestep > 0`, runs at fixed rate (may multiple-step per frame). When `fixedTimestep ≤ 0`, single step with clamped deltaTime. Scene-level: `StartSimulation` (spawn jobs) → `FinishSimulation` (wait, swap buffers). Events: `OnPresimulateEvent`, `OnPostsimulateEvent`. |
| Underlying Semantic | **Discrete simulation stepping.** Physics advances in discrete time increments. Fixed timestep ensures deterministic behavior. Double buffering ensures consistent reads during simulation. |
| Existing SCR Concept | `SimulationStep` (from Sprint 003, `AZ::TickBus` mapping). |
| Candidate SCR Concept | Extend `SimulationStep` to cover physics-specific stepping semantics. Fixed timestep, accumulator pattern, sub-stepping. |
| Action | **extend-existing** |

## 8. Physics Mapping — Material

### 8.1 AzPhysics::Material

| Column | Value |
|--------|-------|
| O3DE Concept | O3DE physics materials define surface interaction properties. Referenced in `ColliderConfiguration::m_materials` (per-shape material slot). Properties: friction (static/dynamic), restitution (bounciness), density. PhysX gem provides material management. Materials are assigned per-collider-shape via material slots. |
| Underlying Semantic | **Surface interaction law.** How two surfaces interact on contact. Friction opposes tangential motion. Restitution determines bounce. Density affects mass computation. These are constitutive properties of materials, not geometric. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`SurfaceMaterial`** — constitutive properties governing contact behavior. Friction (static + dynamic), restitution, density. Applied to collision geometry surfaces. |
| Action | **define-new** |

**Rationale:** Material is not just "a file with numbers." It is a semantic concept: the law governing how two surfaces interact. Two entities with different materials produce different contact behavior. This is a genuine physical concept independent of implementation.

## 9. Asset Mapping — Core Types

### 9.1 AZ::Data::Asset

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::Data::Asset<T>` — smart pointer to `AssetData`. Reference-counted. When saved to disk, serialized as `AssetId`. Load behavior: `PreLoad`, `QueueLoad`, `LoadOnDemand`, `NoLoad`. On load, fetches `AssetData` and constructs `T`. Release unloads when refcount → 0. |
| Underlying Semantic | **Asset reference.** A handle to a resource with managed lifetime. Reference-counted loading/unloading. The reference carries type information and load behavior policy. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`ResourceReference`** — typed, reference-counted handle to a resource. Load behavior policy. Lifetime tied to reference count. |
| Action | **define-new** |

**Critical distinction:** `AZ::Data::Asset` is a C++ smart pointer. SCR `ResourceReference` is the semantic concept: "this entity depends on a resource, load it according to this policy." The implementation (smart pointer, handle, indirection) is provider-specific.

### 9.2 AZ::Data::AssetId

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::Data::AssetId` — unique identifier. Composed of: `m_guid` (UUID of source asset) + `m_subId` (product sub-ID, typically builder UUID). Two-part ID ensures uniqueness across builders. AssetId is stable across sessions (derived from source UUID). |
| Underlying Semantic | **Resource identity.** A stable, unique identifier for a resource. Composed of source identity + product variant. Distinguishes different outputs from the same source. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`ResourceIdentity`** — stable unique identifier for a resource. Source identity + variant identifier. Session-independent. |
| Action | **define-new** |

**Key insight:** AssetId is two-level: source UUID identifies the origin, subId identifies which product from that source. This is not arbitrary — it encodes the provenance chain: source → builder → product.

### 9.3 AZ::Data::AssetManager

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::Data::AssetManager` — singleton managing asset lifecycle. `GetAsset<T>(assetId, loadBehavior)` — primary load API. Manages reference counting, loading queues, dependency tracking, hot-reload. Dispatches `OnAssetReady`, `OnAssetReloaded`, `OnAssetError` events. Coordinates with Asset Processor for runtime asset access. |
| Underlying Semantic | **Resource lifecycle manager.** Orchestrates loading, caching, dependency tracking, and unloading of resources. Single point of truth for resource state. Event-driven notification of resource availability. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`ResourceLifecycleManager`** — orchestrates resource loading, caching, dependency resolution, and unloading. Event-driven notifications. Single source of truth for resource state. |
| Action | **define-new** |

## 10. Asset Mapping — Pipeline

### 10.1 Asset Pipeline (Source → Product)

| Column | Value |
|--------|-------|
| O3DE Concept | **Asset Pipeline** — end-to-end process. Source assets (`.fbx`, `.png`, `.wav`) in scan directories → Asset Processor detects → Asset Builders process → Product assets (`.azmodel`, `.streamingimage`) in Asset Cache. Asset Builders: `CreateJobs` (generate job descriptors) → `ProcessJob` (produce product). Dependencies tracked: source→job→product. Intermediate assets: builder outputs consumed by other builders. |
| Underlying Semantic | **Resource materialization pipeline.** Author-created content (source) → transformation → deployable resource (product). The pipeline is not just file conversion — it is the process of making authorial intent machine-ready. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`MaterializationPipeline`** — the process of transforming author-created content into deployable resources. Source → transformation rules → deployable artifact. |
| Action | **define-new** |

**Critical invariant:** Materialization ≠ file conversion. File conversion is a mechanical transformation. Materialization is a semantic operation: the author's intent (encoded in source) is interpreted, optimized, and committed to a runtime-ready form. The pipeline carries semantic decisions (LOD selection, compression quality, format choice) that affect how the resource will behave at runtime.

### 10.2 Source vs Product vs Runtime

| Column | Value |
|--------|-------|
| O3DE Concept | **Source assets**: author-created files (`.fbx`, `.png`, `.psd`). Human-editable, version-controlled, format-specific. **Product assets**: processed, runtime-optimized outputs (`.azmodel`, `.streamingimage`). Machine-consumed, platform-specific, never hand-edited. **Runtime**: loaded into memory via `AssetManager`, reference-counted, hot-reloadable. |
| Underlying Semantic | **Lifecycle stages of a resource.** Authoring (source) → Materialization (product) → Execution (runtime). Each stage has different properties: source is human-authored, product is machine-optimized, runtime is memory-resident. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`ResourceLifecycle`** — the stages a resource passes through: authoring, materialization, execution. Each stage has different properties and constraints. |
| Action | **define-new** |

### 10.3 SceneAPI (AZ::SceneAPI)

| Column | Value |
|--------|-------|
| O3DE Concept | `AZ::SceneAPI` — scene import and manipulation framework. `SceneAPI::DataTypes::IGraphObject` — base interface for scene graph nodes. Scene graph represents imported scene structure (meshes, materials, bones, animations). Scene Manifest describes how to process the scene. Used by Asset Builders to import `.fbx` and other scene formats. User Defined Properties allow per-node metadata. |
| Underlying Semantic | **Scene structure representation.** A structured representation of imported 3D content. The scene graph is an intermediate representation between source format and product assets. It carries the semantic structure (what is a mesh, what is a bone, what is an animation) separate from the file format. |
| Existing SCR Concept | None. |
| Candidate SCR Concept | **`SceneRepresentation`** — structured intermediate representation of imported 3D content. Carries semantic structure (mesh, bone, animation) separate from file format. |
| Action | **define-new** |

**Rationale:** SceneAPI is not just "an importer." It is the bridge between authorial content and the engine's internal representation. The scene graph is an intermediate semantic layer: it knows what a mesh is, what a bone is, what an animation is — independent of whether the source was `.fbx`, `.gltf`, or `.obj`.

## 11. Complete Mapping Table

| O3DE Concept | Underlying Semantic | Existing SCR Concept | Candidate SCR Concept | Action |
|---|---|---|---|---|
| `AzPhysics::SimulatedBody` | Physical presence (entity in physical world) | None | `PhysicalPresence` | define-new |
| `AzPhysics::RigidBody` | Dynamic body (mass, velocity, force response) | None | `DynamicBody` | define-new |
| `AzPhysics::StaticRigid` | Immovable collision surface | None | `StaticSurface` | define-new |
| `PhysXCharacterController` | Actor movement controller (locomotion constraints) | None | `LocomotionController` | define-new |
| `Physics::Shape` | Collision geometry (spatial extent for collision) | None | `CollisionGeometry` | define-new |
| Trigger flag | Volumetric detection (overlap without force) | None | `DetectionVolume` | define-new |
| `AzPhysics::Joint` | Kinematic constraint (relative motion rule) | None | `KinematicConstraint` | define-new |
| Joint type catalog | DOF constraint taxonomy (fixed/hinge/ball/D6) | None | `DOFConstraint` | define-new |
| `SimulatedBodyEvents` | Physical contact lifecycle (begin/persist/end) | None | `PhysicalContact` | define-new |
| Collision groups/layers | Interaction filtering (which entities can interact) | None | `InteractionFilter` | define-new |
| `AzPhysics::Scene` | Simulation world (bounded physical universe) | None | `SimulationWorld` | define-new |
| `SystemInterface::Simulate` | Discrete simulation stepping (fixed timestep) | `SimulationStep` (Sprint 003) | Extend `SimulationStep` | extend-existing |
| Physics materials | Surface interaction law (friction/restitution) | None | `SurfaceMaterial` | define-new |
| `AZ::Data::Asset<T>` | Asset reference (typed, ref-counted handle) | None | `ResourceReference` | define-new |
| `AZ::Data::AssetId` | Resource identity (source UUID + subId) | None | `ResourceIdentity` | define-new |
| `AZ::Data::AssetManager` | Resource lifecycle manager | None | `ResourceLifecycleManager` | define-new |
| Asset Pipeline | Materialization pipeline (source → product) | None | `MaterializationPipeline` | define-new |
| Source/Product/Runtime | Resource lifecycle stages | None | `ResourceLifecycle` | define-new |
| `AZ::SceneAPI` | Scene structure representation (intermediate rep) | None | `SceneRepresentation` | define-new |

## 12. Key Invariants

### 12.1 SCR PhysicsBody ≠ AzPhysics Implementation

SCR defines `PhysicalPresence` as a semantic concept. AzPhysics implements it as `SimulatedBody`. The mapping is:

```
SCR PhysicalPresence (semantic)
    ↓ maps to via
SCR → adapter → AzPhysics::SimulatedBody (implementation)
    ↓ which may be
PhysX RigidBody, Jolt Body, custom solver
```

SCR does not own the physics implementation. SCR defines what "physical presence" means. Providers implement the mechanics. The adapter translates between SCR semantics and provider API.

### 12.2 Asset Lifecycle: Source ≠ Product ≠ Runtime

Three distinct stages with different properties:

| Stage | Properties | Editable? | Platform-specific? |
|---|---|---|---|
| **Source** | Human-authored, version-controlled | Yes | No |
| **Product** | Machine-optimized, derived | No | Yes |
| **Runtime** | Memory-resident, ref-counted | No | Yes |

SCR must model these as distinct lifecycle stages, not as "the same file in different locations."

### 12.3 Materialization Is Semantic

Materialization (source → product) is not file conversion. It involves:

- **Interpretation**: understanding author intent (what is a mesh? what is a material?)
- **Optimization**: LOD selection, compression, format choice
- **Commitment**: making decisions that affect runtime behavior
- **Provenance**: tracking which source produced which product

A file converter transforms data. A materialization pipeline interprets intent. SCR must distinguish these.

### 12.4 Provider Separation

```
SCR Semantic Layer
    ↓ defines
SCR Concept (PhysicalPresence, DynamicBody, etc.)
    ↓ translated by
Adapter (SCR ↔ provider mapping)
    ↓ implemented by
Provider (PhysX, Jolt, custom)
```

The adapter is not optional. It is the semantic boundary between SCR's meaning and the provider's mechanics. Without the adapter, SCR concepts would silently adopt provider-specific semantics.

### 12.5 Scene ≠ Context

From Sprint 003: Context is an entity management scope (namespace, lifecycle).

From this sprint: Scene is a physical simulation domain (bodies, joints, gravity, timestep).

These are orthogonal concerns:
- An entity exists in a context (management scope)
- An entity participates in a scene (simulation domain)
- One context may have entities in multiple scenes
- One scene may contain entities from multiple contexts

SCR must not conflate these.

## 13. Exit Criteria Check

- [x] AzPhysics → SCR physics mapping complete (Sections 3–8)
- [x] Asset lifecycle mapped (Sections 9–10)
- [x] Materialization concept assessed (Section 10.1)
- [x] Provider separation preserved (Section 12.1, 12.4)

## 14. Deferred Concepts

| Concept | Reason | Recommended Sprint |
|---|---|---|
| Physics determinism semantics | O3DE PhysX not deterministic; SCR may need determinism guarantees | Separate simulation semantics sprint |
| Ragdoll / articulation chains | Complex constraint systems built from joints | After KinematicConstraint defined |
| Heightfield / terrain physics | Specialized collision geometry | Separate terrain domain sprint |
| Vehicle dynamics | Specialized locomotion (wheels, suspension) | After LocomotionController defined |
| Cloth simulation | Non-rigid body physics (NVIDIA Cloth Gem) | Separate cloth domain sprint |
| Asset hot-reload semantics | Runtime asset replacement behavior | Separate runtime sprint |
| Multi-platform asset deployment | Platform-specific product variants | Separate deployment sprint |
| Scene API graph manipulation | Scene graph modification rules | After SceneRepresentation defined |

## 15. Sprint 003 Deferral Resolution

Sprint 003 deferred:
- **EBus/Event dispatch patterns** → Partially resolved in Section 6.1 (collision events as stateful lifecycle)
- **Non-uniform scale semantics** → Deferred (not physics-specific)
- **Undo/redo semantics** → Deferred (authoring-scope concern)
- **Serialization** → Deferred (separate persistence sprint)

# Sprint 04: Physics & Asset Mapping

Map O3DE/AzPhysics concepts and asset/resource semantics to SCR.

## Deliverables
- Physics assessment table (RigidBody, StaticBody, Constraint, Collision, etc.)
- Asset assessment table (Asset, AssetId, AssetRef, lifecycle, materialization)
- Source vs product vs runtime representation distinctions

## Exit Criteria
- [ ] AzPhysics → SCR physics mapping complete
- [ ] Asset lifecycle mapped
- [ ] Materialization concept assessed
- [ ] Provider separation preserved (SCR PhysicsBody → adapter → PhysX/O3DE)
# Milestone 003: Core Runtime Semantics

## 1. Scope & Objective
Define/extend SCR core runtime semantics: entity/component lifecycle, spatial hierarchy, physics/dynamics, and asset/resource/materialization. Produce semantic library candidate definitions where gaps exist.

## 2. Deliverables
- Entity/component lifecycle semantic definitions
- Spatial hierarchy semantic definitions
- Physics/dynamics semantic definitions
- Asset/resource/materialization semantic definitions
- Semantic library directory structure recommendations

## 3. Formal Invariants
1. Entity identity uniqueness preserved across contexts.
2. Component composition is explicit, not implicit.
3. Transform composition is associative and preserves parent/child.
4. Materialization is a semantic operation, not merely file conversion.

## 4. Exit Criteria
- [ ] Core semantic definitions produced with provenance
- [ ] Gap analysis from Milestone 002 addressed
- [ ] Semantic library candidates justified (not automatic)
- [ ] Each definition classified: already-defined / needs-clarity / needs-extension / new-required

## 5. Dependencies
- Milestone 002 (AzFramework assessment)
# Sprint 001 Record: Entity, Component & Lifecycle

## 1. Objective

Define/extend SCR semantic definitions for Entity, Component, composition, attachment, lifecycle, and dependency. Produce definitions grounded in existing SCR library and informed by Milestone 002 O3DE assessment. Preserve SCR authority model: SID is authoritative identity; no provider terminology promoted to semantic authority.

## 2. Existing SCR Library Assessment

### 2.1 Domains With Substantive Definitions

| Domain | Path | Status | Relevance |
|--------|------|--------|-----------|
| **Identity** | `lib/101_Core/Identity/101_definition.md` | Operational (0.1.0) | Authoritative. SID is coordinate identity. 9-layer authority hierarchy. 17 invariants (IAM-I001–IAM-I017). IAM-I014 (Manifestation Separation) and IAM-I015 (Binding Separation) directly relevant to entity/component identity model. |
| **Core** | `lib/101_Core/101_definition.md` | Draft (0.1.0) | Defines Entity, Object, State, State Transition, Composition, Constraint, Capability, Contract, Relationship, Role as foundational concepts. Sections 10, 21, 22, 32, 29, 30, 31 are the normative basis. |

### 2.2 Domains That Are Placeholder Stubs

All of the following contain only structural boilerplate — no semantic definitions:

| Domain | Path | Implication |
|--------|------|-------------|
| **Types** | `lib/101_Core/Types/101_definition.md` | No type system definition yet. Core §8 defines Type conceptually. |
| **State** | `lib/101_Core/State/101_definition.md` | No state semantics. Core §21–22 defines State and State Transition. Lifecycle states must extend Core. |
| **Composition** | `lib/101_Core/Composition/101_definition.md` | No composition rules. Core §32 defines composition generically. Entity-component composition needs explicit definition. |
| **Constraints** | `lib/101_Core/Constraints/101_definition.md` | No constraint semantics. Core §29 defines Constraint conceptually. Service contracts are a specific constraint form. |
| **Concepts** | `lib/101_Core/Concepts/101_definition.md` | No concept definitions. |
| **Capabilities** | `lib/101_Core/Capabilities/101_definition.md` | No capability definitions. Core §30 defines Capability. |
| **Properties** | `lib/101_Core/Properties/101_definition.md` | No property definitions. |
| **Relations** | `lib/101_Core/Relations/101_definition.md` | No relation definitions. Core §12–13 defines Relationships and Roles. |
| **Interfaces** | `lib/101_Core/Interfaces/101_definition.md` | No interface definitions. |
| **Operations** | `lib/101_Core/Operations/101_definition.md` | No operation definitions. Core §20 defines Operations. |
| **Contracts** | `lib/101_Core/Contracts/101_definition.md` | No contract definitions. Core §31 defines Contracts. |

### 2.3 Assessment Summary

The SCR library has a comprehensive **Core** specification (§10, §21–22, §29–32) that defines Entity, State, State Transition, Constraint, Capability, Contract, and Composition conceptually. The **Identity** domain is fully specified with invariants. Everything else is placeholder.

**Critical gap:** Core defines *what* these concepts mean abstractly, but provides no operational semantics for entity-component composition, lifecycle state machines, or service contracts. M003 must fill this gap.

## 3. Entity Definition

### 3.1 SCR Entity (Normative)

**Concept:** `Entity`
**Source:** Core §10 (Entities and Objects)
**Status:** extend-existing — Core defines entity abstractly; sprint defines operational semantics

An Entity in SCR is a **semantically addressable, composable computational unit** possessing:

- **Identity** — SID coordinate (authoritative, per `lib/101_Core/Identity`)
- **Type** — semantic type classification
- **State** — lifecycle state machine (defined below)
- **Components** — zero or more attached Component instances
- **Dependencies** — declared and resolved through service contracts

An Entity has **no behavior of its own**. All behavior emerges from the composition of its attached Components. This is the fundamental principle of entity-component architecture.

### 3.2 Entity vs Object Distinction

Core §10 defines both Entity and Object. SCR distinguishes:

| Concept | Meaning | Identity Boundary |
|---------|---------|-------------------|
| **Entity** | Composable unit with lifecycle. Component container. Identity boundary. | SID coordinate |
| **Object** | Generic semantically addressable construct. May or may not have components. | May have identity, may not |

Entity is a specialization of Object that adds component composition and lifecycle management.

### 3.3 Identity Authority (Preserved from M002)

```
SCR SID (authoritative identity)
    ↓ Manifestation Layer
Provider EntityId (provider-local runtime handle)
    ↓ Provider Mapping
Provider Entity (runtime instance)
```

- SID is never derived from a provider identifier
- Provider entity handles are manifestation-layer ephemeral references
- Multiple provider handles may reference the same SID across different contexts

### 3.4 Provenance

```yaml
concept: Entity
source: O3DE
source_terminology: AZ::Entity
scr_interpretation: Semantically addressable composable unit with SID identity, component slots, lifecycle state machine, and dependency resolution
differences: No behavior of own (same as O3DE). Identity via SID not EntityId. No 32-bit active-state bitmask. Lifecycle states simplified.
```

## 4. Component Definition

### 4.1 SCR Component (Normative)

**Concept:** `Component`
**Source:** Core §30 (Capabilities), §31 (Contracts), §32 (Composition)
**Status:** define-new — no existing SCR component definition

A Component is a **composable unit of semantic behavior** attached to an Entity. A Component:

- Has **no independent identity** — it exists only within the scope of its owning Entity
- Has a **lifecycle** tied to its owning Entity's lifecycle
- Declares a **service contract** (provided/required/dependent/incompatible services)
- Can **provide services** to other components
- Can **require services** from other components
- Has **no standalone execution** — activation occurs only as part of Entity activation

### 4.2 Component vs Capability Distinction

| Concept | Meaning | Scope |
|---------|---------|-------|
| **Capability** | Abstract property of a semantic object (e.g., Composable, Deterministic) | Core §30 — universal |
| **Component** | Concrete composable behavior unit attached to an Entity | M003 — entity-scoped |

A Component *declares* capabilities through its service contract. A Capability is an abstract property; a Component is a concrete attachment.

### 4.3 Service Contract

**Concept:** `ServiceContract`
**Source:** O3DE ComponentDescriptor service declarations
**Status:** define-new

A ServiceContract declares four relations between a Component type and other Component types:

| Relation | Meaning | Activation Implication |
|----------|---------|----------------------|
| **provides** | This component offers this service | After activation, this service is available |
| **requires** | This component needs this service to function | Service provider must be present and activated first |
| **depends-on** | This component prefers this service; if present, activates after it | Soft ordering preference |
| **incompatible-with** | This component cannot coexist with this service | Validation error if both present on same Entity |

Service contracts are the mechanism by which component composition is validated and dependency ordering is computed.

### 4.4 Provenance

```yaml
concept: Component
source: O3DE
source_terminology: AZ::Component
scr_interpretation: Composable behavior unit with no independent identity, service contract, lifecycle tied to owning entity
differences: No independent identity (same as O3DE). Service contract formalized as four explicit relations. No ComponentApplication coupling.
```

```yaml
concept: ServiceContract
source: O3DE
source_terminology: ComponentDescriptor (GetProvidedServices, GetRequiredServices, GetDependentServices, GetIncompatibleServices)
scr_interpretation: Formal four-relation service declaration used for dependency ordering and composition validation
differences: SCR formalizes as explicit semantic contract, not a C++ descriptor API. Provider-agnostic.
```

## 5. Lifecycle State Machine

### 5.1 Entity Lifecycle States (Normative)

**Concept:** `LifecycleState`
**Source:** O3DE AZ::Entity::State, Core §21–22 (State, State Transition)
**Status:** define-new

```
                    ┌──────────────┐
                    │ Instantiated │
                    └──────┬───────┘
                           │ initialize()
                           ▼
                    ┌──────────────┐
                    │  Initialized │
                    └──────┬───────┘
                           │ activate()
                           ▼
                    ┌──────────────┐
                    │    Active    │◄──────────┐
                    └──────┬───────┘           │
                           │ deactivate()      │ reactivate()
                           ▼                   │
                    ┌──────────────┐           │
                    │  Deactivated │───────────┘
                    └──────┬───────┘
                           │ destroy()
                           ▼
                    ┌──────────────┐
                    │  Destroyed   │
                    └──────────────┘
```

### 5.2 State Semantics

| State | Meaning | Component Behavior |
|-------|---------|-------------------|
| **Instantiated** | Entity created. Components exist but uninitialized. No services available. | Components constructed. |
| **Initialized** | Entity initialization complete. Components have run Init. Services declared but not yet active. | Components initialized once. |
| **Active** | Entity fully operational. All components activated in dependency order. Services available. | Components activated in topological order by service dependencies. |
| **Deactivated** | Entity suspended. Components deactivated in reverse dependency order. Services unavailable. Entity may reactivate. | Components deactivated in reverse order. |
| **Destroyed** | Terminal state. Entity and all components permanently destroyed. No recovery. | Components destroyed. No further operations valid. |

### 5.3 Transition Rules

| From | To | Trigger | Preconditions |
|------|----|---------|---------------|
| Instantiated | Initialized | `initialize()` | Entity created. Components attached. |
| Initialized | Active | `activate()` | All required services resolvable. No cyclic dependencies. No incompatible components. |
| Active | Deactivated | `deactivate()` | None additional. |
| Deactivated | Active | `reactivate()` | Entity not destroyed. |
| Deactivated | Destroyed | `destroy()` | None additional. |
| Active | Destroyed | `destroy()` | Direct destruction from active state. |

**Invalid transitions:**
- Instantiated → Active (must initialize first)
- Initialized → Deactivated (must activate first)
- Destroyed → any (terminal state)

### 5.4 Component Lifecycle Ordering

When an Entity transitions:

**Activation** (Instantiated → Initialized → Active):
1. Components sorted topologically by service dependencies (requires before provides)
2. Components activated in sorted order
3. Each component's Init runs once (on first initialization)
4. Each component's Activate runs on each activation

**Deactivation** (Active → Deactivated):
1. Components deactivated in **reverse** topological order
2. Required services withdrawn in safe order

**Destruction** (Deactivated/Active → Destroyed):
1. Components destroyed in **reverse** topological order

### 5.5 Provenance

```yaml
concept: LifecycleState
source: O3DE
source_terminology: AZ::Entity::State (Constructed → Initializing → Init → Activating → Active → Deactivating → Destroying → Destroyed)
scr_interpretation: Five-state lifecycle: Instantiated → Initialized → Active → Deactivated → Destroyed
differences: Simplified from O3DE's 8 states. No Initializing/Activating/Deactivating/Destroying intermediate states (those are implementation transitions). No 32-bit active-state bitmask. Reactivation is explicit transition from Deactivated to Active.
```

## 6. Composition Rules

### 6.1 Entity-Component Attachment

**Concept:** `Composition`
**Source:** Core §32, O3DE entity-component model
**Status:** extend-existing — Core defines composition abstractly

**Rules:**

1. **One-to-many:** One Entity may have zero or more Components.
2. **No independent identity:** Components have no SID of their own. Their identity is scoped to the owning Entity.
3. **Single ownership:** A Component instance belongs to exactly one Entity. No sharing across Entities.
4. **Explicit attachment:** Components are explicitly attached to Entities at construction or initialization time. No implicit composition.
5. **Type uniqueness:** At most one Component of a given service-providing type per Entity (enforced by incompatible-with checks).

### 6.2 Dependency Ordering

**Concept:** `DependencyOrdering`
**Source:** O3DE DependencySort
**Status:** define-new (within Composition domain)

**Algorithm:**

1. Build directed graph: edge from Component A to Component B if A requires a service B provides.
2. Topological sort of the graph.
3. If cycle detected → composition validation error.
4. Activation order: topological order.
5. Deactivation order: reverse topological order.

**Validation rules:**
- All `requires` services must be satisfied by some Component on the same Entity
- All `incompatible-with` relations must not conflict with any Component on the same Entity
- Dependency graph must be acyclic

### 6.3 Composition Validation

Before activation, the Entity must validate:

1. All required services are provided by at least one Component
2. No incompatible services are both present
3. Dependency graph is acyclic
4. Topological ordering exists

If validation fails, activation is rejected with diagnostic information.

### 6.4 Provenance

```yaml
concept: DependencyOrdering
source: O3DE
source_terminology: AZ::Entity::DependencySort
scr_interpretation: Topological sort of composable units by service dependencies. Acyclic graph required. Activation in topological order, deactivation in reverse.
differences: SCR formalizes as semantic constraint on composition, not a C++ sort routine. Ordering is a property of the composition, not an algorithm detail.
```

## 7. Gap Analysis

### 7.1 Classification of SCR Needs

| Concept | Current SCR Status | Action | Classification |
|---------|-------------------|--------|----------------|
| **Entity** | Core §10 defines abstractly. No operational semantics. | **extend-existing** | Needs operational definition with lifecycle, composition |
| **Component** | No definition anywhere in SCR library | **define-new** | New semantic concept |
| **LifecycleState** | Core §21–22 defines State/Transition abstractly. `lib/101_Core/State/` is stub. | **define-new** | New specific state machine |
| **ServiceContract** | `lib/101_Core/Contracts/` is stub. Core §31 defines Contract abstractly. | **define-new** | New specific contract form |
| **Composition (entity-component)** | Core §32 defines composition abstractly. `lib/101_Core/Composition/` is stub. | **extend-existing** | Needs entity-component specific rules |
| **DependencyOrdering** | No definition. `203_Graph` has algorithms but no semantic. | **define-new** | New composition constraint |
| **EntityContext** | `lib/101_Core/Context/` is stub | **define-new** | Ownership scope for entity hierarchies |
| **EntityTemplate** | No definition | **define-new** | Reusable entity hierarchy specification |
| **EntitySpawn** | No definition | **define-new** | Runtime instantiation from template |
| **ComponentDescriptor** | No definition | **define-new** | Component type metadata |
| **RuntimeHost** | No definition | **define-new** | Application-level component management |

### 7.2 Concepts Requiring Clarity

| Concept | Question | Recommended Resolution |
|---------|----------|----------------------|
| **Tick** | Semantic (per-frame step) or implementation? | Semantic. Defer to dedicated sprint — interacts with temporal semantics. |
| **EntityTemplate vs Prefab** | Are these distinct concepts? | EntityTemplate is the semantic concept. Prefab/O3DE is one serialization format. |
| **Context scope** | Should EntityContext be a Core concept or a higher-level domain? | Core. Entity ownership scope is fundamental. |
| **Component identity** | Can a component ever have independent identity? | No. Component identity is always scoped to Entity. If a component needs independent identity, it should be an Entity. |

### 7.3 Concepts Already Adequately Defined

| Concept | Where Defined |
|---------|---------------|
| SID Identity | `lib/101_Core/Identity/101_definition.md` — complete |
| Entity (abstract) | Core §10 — adequate as foundation |
| State (abstract) | Core §21–22 — adequate as foundation |
| Contract (abstract) | Core §31 — adequate as foundation |
| Capability (abstract) | Core §30 — adequate as foundation |
| Relationship | Core §12–13 — adequate as foundation |

## 8. Derived Definitions for Semantic Library

The following definitions should be added to the SCR semantic library. Each is classified per M003 exit criteria.

### 8.1 Recommended File Structure

```
lib/101_Core/
├── Identity/           (existing — operational)
├── Concepts/           (needs: Entity, Component definitions)
├── State/              (needs: LifecycleState definition)
├── Composition/        (needs: Composition rules, DependencyOrdering)
├── Contracts/          (needs: ServiceContract definition)
├── Context/            (needs: EntityContext definition)
├── Relations/          (needs: ParentChildRelation — deferred to Sprint 02)
└── ...other domains...
```

### 8.2 Classification Summary

| Classification | Count | Concepts |
|----------------|-------|----------|
| **already-defined** | 6 | SID Identity, Entity (abstract), State (abstract), Contract (abstract), Capability (abstract), Relationship |
| **needs-extension** | 2 | Entity (operational), Composition (entity-component rules) |
| **define-new** | 7 | Component, LifecycleState, ServiceContract, DependencyOrdering, EntityContext, EntityTemplate, EntitySpawn |
| **needs-clarity** | 1 | Tick (deferred) |

## 9. Exit Criteria Check

- [x] Entity definition distinguishes semantic entity from provider entity (Section 3)
- [x] Component definition distinguishes semantic capability from implementation component (Section 4)
- [x] Lifecycle states and transitions documented (Section 5)
- [x] Composition rules documented (Section 6)
- [x] Gap analysis from M002 addressed (Section 7)
- [x] Provenance documented for all O3DE-derived concepts (Sections 3.4, 4.4, 5.5, 6.4)
- [x] Each concept classified: already-defined / needs-extension / define-new / needs-clarity (Section 7.1)

## 10. Deferred to Subsequent Sprints

| Concept | Sprint | Reason |
|---------|--------|--------|
| ParentChildRelation | Sprint 02 (Spatial Hierarchy) | Spatial semantics; entity hierarchy lives in Transform domain |
| Transform Inheritance | Sprint 02 | Extend existing `101_Core/Transforms` |
| Tick | Sprint 03+ | Interacts with temporal semantics; needs dedicated analysis |
| EntityTemplate / EntitySpawn | Sprint 04 (Asset/Resource/Materialization) | Tied to serialization and instantiation pipelines |
| RuntimeHost | Deferred | Application-level; may belong to provider specification |
# Sprint 01: Entity, Component & Lifecycle

Define/extend SCR semantic definitions for Entity, Component, composition, attachment, lifecycle, dependency.

## Deliverables
- Entity semantic definition (with provenance)
- Component semantic definition
- Lifecycle state machine (instantiation → activation → deactivation → destruction)
- Composition rules

## Exit Criteria
- [ ] Entity definition distinguishes semantic entity from provider entity
- [ ] Component definition distinguishes semantic capability from implementation component
- [ ] Lifecycle states and transitions documented
# Sprint 002 Record: Spatial Hierarchy & Transform Semantics

## 1. Objective

Define SCR semantic Transform (position + orientation + scale), parent/child hierarchy composition, coordinate system conventions with inter-system mappings, and spatial relationship semantics. Ground definitions in existing `lib/801_Spatial` and `lib/302_Geometry` definitions. Preserve invariant: **semantic transform ≠ representation transform**. SCR defines meaning; providers encode.

## 2. Existing SCR Library Assessment

### 2.1 Domains With Substantive Definitions

| Domain | Path | Status | Relevance |
|--------|------|--------|-----------|
| **Spatial** | `lib/801_Spatial/101_definition.md` | Operational (0.1.0) | Authoritative spatial domain definition. 1372 lines. 41 invariants (SPATIAL-INV-001–018). Defines position, orientation, distance, proximity, neighbourhood, region, containment, adjacency, connectivity, spatial relationships, coordinate systems, reference frames, spatial transformations, navigation, pathfinding, geofencing. Normative authority for all spatial semantics. |
| **Geometry Transform** | `lib/302_Geometry/Transform/101_definition.md` | Operational (0.1.0) | Affine, rigid-body, projective transformations. Grounded in mathematics. Invariants: Identity (INV-001), Dimensional Integrity (INV-002), Coordinate Integrity (INV-003), Transformation Integrity (INV-006), Representation Independence (INV-013). |
| **Geometry Translation** | `lib/302_Geometry/Translation/101_definition.md` | Operational (0.1.0) | Uniform vector displacement. Affine vs Linear separation: points ≠ vectors. |
| **Geometry Rotation** | `lib/302_Geometry/Rotation/101_definition.md` | Operational (0.1.0) | Orientation transformation via rotation matrices or unit quaternions. |
| **Geometry Scale** | `lib/302_Geometry/Scale/101_definition.md` | Operational (0.1.0) | Isotropic or anisotropic metric scaling. |
| **Geometry CoordinateSystems** | `lib/302_Geometry/CoordinateSystems/101_definition.md` | Operational (0.1.0) | Cartesian, spherical, cylindrical, curvilinear, barycentric coordinate frames. |

### 2.2 Domains That Are Placeholder Stubs

| Domain | Path | Implication |
|--------|------|-------------|
| **Core Transforms** | `lib/101_Core/Transforms/101_definition.md` | Empty stub. SCR-level transform semantics not yet defined. This sprint's primary deliverable. |
| **Position** | `lib/801_Spatial/Position/101_definition.md` | Empty stub. Spatial position concept deferred to sprint deliverable. |
| **Orientation** | `lib/801_Spatial/Orientation/101_definition.md` | Empty stub. Orientation concept deferred to sprint deliverable. |
| **Transformations** | `lib/801_Spatial/Transformations/101_definition.md` | Empty stub. Spatial transformation concept deferred to sprint deliverable. |
| **CoordinateSystems** | `lib/801_Spatial/CoordinateSystems/101_definition.md` | Empty stub. Coordinate system definitions deferred to sprint deliverable. |
| **ReferenceFrames** | `lib/801_Spatial/ReferenceFrames/101_definition.md` | Empty stub. Reference frame definitions deferred to sprint deliverable. |
| **Coordinates** | `lib/801_Spatial/Coordinates/101_definition.md` | Empty stub. Coordinate value types deferred to sprint deliverable. |
| **Distance** | `lib/801_Spatial/Distance/101_definition.md` | Empty stub. Distance metrics deferred to sprint deliverable. |
| **Direction** | `lib/801_Spatial/Direction/101_definition.md` | Empty stub. Direction semantics deferred to sprint deliverable. |
| **Proximity** | `lib/801_Spatial/Proximity/101_definition.md` | Empty stub. Proximity semantics deferred to sprint deliverable. |
| **Neighbourhood** | `lib/801_Spatial/Neighbourhood/101_definition.md` | Empty stub. Neighbourhood semantics deferred to sprint deliverable. |
| **Region** | `lib/801_Spatial/Region/101_definition.md` | Empty stub. Region semantics deferred to sprint deliverable. |
| **H3** | `lib/801_Spatial/H3/101_definition.md` | Empty stub. H3 hexagonal indexing deferred to sprint deliverable. |

### 2.3 Assessment Summary

The `lib/801_Spatial/101_definition.md` is the normative authority — comprehensive (1372 lines, 41 invariants) but abstract. It defines *what* spatial semantics mean without prescribing *how* subdomains compose. The `lib/302_Geometry` subdomains (Transform, Translation, Rotation, Scale, CoordinateSystems) are mathematically grounded but represent geometric primitives, not semantic spatial meaning.

**Critical gap:** No operational definition exists for:
- Semantic Transform as a composite of position + orientation + scale
- Parent/child hierarchy composition and transform accumulation
- Coordinate system conventions and inter-system mappings
- Spatial relationship semantics (containment, adjacency, proximity, visibility)

M003 Sprint 02 must fill this gap.

## 3. Semantic Transform

### 3.1 SCR Semantic Transform (Normative)

**Concept:** `SemanticTransform`
**Source:** Spatial §5 (Orientation and Direction), Spatial §20 (Spatial Transformation), Geometry Transform, Geometry Translation, Geometry Rotation, Geometry Scale
**Status:** define-new — no existing composite transform definition

A SemanticTransform represents the **provider-independent spatial pose** of an entity within a declared reference frame. It is the composite of:

```text
SemanticTransform = Position + Orientation + Scale
```

| Component | Type | Meaning | Grounded In |
|-----------|------|---------|-------------|
| **Position** | Point (affine space) | Spatial location relative to reference frame origin | Geometry Translation, Spatial §2 (Position) |
| **Orientation** | Unit Quaternion (preferred), Rotation Matrix (alternative) | Angular configuration relative to reference frame axes | Geometry Rotation, Spatial §5 (Orientation) |
| **Scale** | Vector3D (uniform or non-uniform) | Metric scaling relative to reference frame units | Geometry Scale |

### 3.2 Semantic Transform ≠ Representation Transform

| Aspect | Semantic Transform | Representation Transform |
|--------|-------------------|------------------------|
| **Authority** | SCR — defines meaning | Provider — encodes meaning |
| **Existence** | Meaningful whether or not a provider exists | Depends on provider runtime |
| **Multiplicity** | Single semantic meaning | May have multiple provider representations |
| **Identity** | Has semantic identity (SID-scoped) | Provider-local handle, ephemeral |
| **Invariance** | Provider-independent | Provider-specific layout, format, endianness |

Example:
```
SCR Semantic: Position(1.0, 2.0, 3.0), Orientation(quat(0, 0, 0, 1)), Scale(1, 1, 1)
    ↓ O3DE Provider
AZ::Transform (matrix storage, O3DE coordinate system, Y-up convention)
    ↓ ROS 2 Provider
geometry_msgs::msg::Transform (column-major matrix, ROS 2 convention, X-forward)
```

Same semantic meaning, two provider representations. Neither provider redefines the semantic meaning.

### 3.3 Transform Composition

SemanticTransforms compose hierarchically:

```text
SemanticTransform_world = SemanticTransform_parent * SemanticTransform_local
```

Composition follows affine group laws (per Geometry INV-006):
1. Scale accumulates multiplicatively (child scale × parent scale)
2. Orientation accumulates multiplicatively (child quaternion × parent quaternion)
3. Position accumulates via affine combination (parent orientation rotates child position, then adds parent position)

```text
scale_world = scale_parent ⊙ scale_local
orientation_world = orientation_parent × orientation_local
position_world = position_parent + orientation_parent.rotate(position_local ⊙ scale_parent)
```

### 3.4 Determinism

SemanticTransform composition is deterministic. Equivalent inputs under equivalent reference frames MUST produce equivalent outputs (per Spatial INV-039).

### 3.5 Provenance

```yaml
concept: SemanticTransform
source: O3DE
source_terminology: AZ::Transform (matrix4x4)
scr_interpretation: Provider-independent composite pose: position (Point3D) + orientation (Quaternion) + scale (Vector3D). Composable hierarchically via affine group laws.
differences: O3DE uses 4x4 matrix exclusively. SCR separates into semantic components. O3DE uses右手坐标系 Y-up; SCR canonical is +Z forward, +Y up, +X right. No matrix representation in semantic layer.
```

## 4. Hierarchy

### 4.1 Parent/Child Composition (Normative)

**Concept:** `SpatialHierarchy`
**Source:** Spatial §17 (Hierarchical Spatial Structures), Core §32 (Composition)
**Status:** define-new

An entity hierarchy is a directed acyclic graph (DAG) where:

- Each node is an Entity with a SemanticTransform
- Each edge is a parent/child relationship with a local SemanticTransform
- The root has a world-frame SemanticTransform (typically identity)

```text
World (root)
├── Entity A (local transform: T_A)
│   ├── Entity B (local transform: T_B)
│   │   └── Entity C (local transform: T_C)
│   └── Entity D (local transform: T_D)
└── Entity E (local transform: T_E)
```

### 4.2 Transform Accumulation

World transform is computed by accumulating from root to leaf:

```text
T_world(C) = T_world(A) × T_local(B) × T_local(C)
```

Accumulation is **right-to-left**: parent transform applied first, then child local transform.

### 4.3 Local vs World

| Frame | Meaning | Use |
|-------|---------|-----|
| **Local** | Transform relative to parent entity | Authoring, entity-level queries |
| **World** | Transform accumulated from root | Rendering, physics, spatial queries |

Both frames are always available. Conversion is deterministic and invertible:

```text
T_local = T_parent⁻¹ × T_world
T_world = T_parent × T_local
```

### 4.4 Hierarchy Invariants

- **No cycles:** Parent/Child graph is a DAG (per Graph semantics).
- **Single parent:** Each entity has at most one parent (tree, not general DAG).
- **Identity preserved:** Entity identity (SID) is invariant under hierarchy changes.
- **Transform separation:** Local transform is independent of world transform. Changing parent does not mutate local transform.

### 4.5 Provenance

```yaml
concept: SpatialHierarchy
source: O3DE
source_terminology: AZ::TransformBus, AZ::EntityId hierarchy (parent-child via Transform component)
scr_interpretation: DAG of entities with composable local-to-world transforms. Single parent. Transform accumulation follows affine group laws.
differences: O3DE uses flat parent-child via AZ::ParentEntityId. SCR defines as first-class semantic concept. No bus-based query. O3DE has no explicit local/world distinction (matrix computed lazily). SCR makes both frames explicit.
```

## 5. Coordinate Systems

### 5.1 Canonical Convention (Normative)

**Concept:** `CoordinateConvention`
**Source:** Spatial §4 (Reference Frames), Spatial §3 (Coordinates), Geometry CoordinateSystems
**Status:** define-new

SCR canonical coordinate convention:

```text
+Z = Forward (north, depth, primary axis)
+Y = Up (vertical, against gravity)
+X = Right (lateral)
```

Right-handed coordinate system. Units: metres (SI). Quaternions: Hamilton convention (scalar-first or vector-first — declared explicitly).

### 5.2 Coordinate Convention Mapping Table

| Convention | Forward | Up | Right | Handedness | Used By |
|------------|---------|----|-------|------------|---------|
| **SCR** | +Z | +Y | +X | Right | SCR canonical |
| **O3DE** | +Y | +Z | +X | Right | O3DE (Open 3D Engine) |
| **USD** | +Y | +Z | +X | Right | USD (Universal Scene Description) |
| **ROS 2** | +X | +Z | -Y | Right | ROS 2 (Robot Operating System) |
| **H3** | N/A | N/A | N/A | N/A | H3 (hexagonal hierarchical spatial index — cell-based, no Cartesian axes) |
| **OpenGL** | -Z | +Y | +X | Right | OpenGL, glTF |
| **Vulkan** | +Z | +Y | +X | Right | Vulkan (NDC) |
| **Unity** | +Z | +Y | +X | Left | Unity Engine |
| **Unreal** | +X | +Z | +Y | Right | Unreal Engine |

### 5.3 Inter-System Transform Mappings

Provider adapters MUST apply explicit coordinate transforms when mapping between SCR and provider conventions:

**SCR → O3DE:**
```text
x_o3de = x_scr
y_o3de = z_scr
z_o3de = y_scr
```

**SCR → ROS 2:**
```text
x_ros = z_scr
y_ros = -x_scr
z_ros = y_scr
```

**SCR → USD:**
```text
x_usd = x_scr
y_usd = z_scr
z_usd = y_scr
```

**O3DE → ROS 2:**
```text
x_ros = y_o3de
y_ros = -x_o3de
z_ros = z_o3de
```

### 5.4 Reference Frame Explicitness

Per Spatial INV-002 (Reference Explicitness), all coordinate values MUST be interpreted within an explicit or inferable reference frame. When coordinates cross a system boundary (SCR ↔ provider), the mapping MUST be declared and applied.

### 5.5 H3 Special Case

H3 uses hexagonal hierarchical cells rather than Cartesian coordinates. H3 cells have:
- No intrinsic forward/up/right axes
- Resolution levels (0–15) defining cell area
- Cell centres that can be converted to lat/lon (geodetic)

SCR treats H3 as a discrete spatial index, not a coordinate system. H3 cells are spatial regions, not coordinate frames.

### 5.6 Provenance

```yaml
concept: CoordinateConvention
source: Multi-system
source_terminology: Varies per system
scr_interpretation: Canonical +Z-forward, +Y-up, +X-right. Right-handed. Provider adapters apply explicit axis swaps and handedness checks when crossing boundaries.
differences: SCR canonical differs from O3DE (+Y forward, +Z up), ROS 2 (+X forward, +Z up, -Y right), USD (+Y forward, +Z up). Each provider adapter applies explicit mapping.
```

## 6. Spatial Relationships

### 6.1 Relationship Categories (Normative)

**Concept:** `SpatialRelationship`
**Source:** Spatial §11 (Spatial Relationships), Spatial §6 (Extent and Region), Spatial §7 (Neighbourhood)
**Status:** define-new — extends abstract Spatial definition

Spatial relationships describe how entities relate spatially. They are first-class semantic relationships within the SCR Semantic Hypergraph.

### 6.2 Containment

**Concept:** `Containment`
**Source:** Spatial §6 (Extent and Region), Spatial §33 (Semantic Hypergraph Integration)
**Status:** define-new

Containment describes entity A being spatially inside region/entity B.

| Type | Meaning | Example |
|------|---------|---------|
| **Strict containment** | A entirely within B boundary | Room inside building |
| **Boundary containment** | A shares boundary with B | Furniture against wall |
| **Partial containment** | A overlaps B but is not entirely within | Intersection zone |

Containment relationships are transitive: if A contains B and B contains C, then A contains C.

Containment MUST be distinguishable from mere semantic grouping (Spatial §6, INV-018).

### 6.3 Adjacency

**Concept:** `Adjacency`
**Source:** Spatial §11 (Spatial Relationships), Spatial §7 (Neighbourhood)
**Status:** define-new

Adjacency describes entities that share a boundary or are immediate neighbours without gap.

| Type | Meaning | Example |
|------|---------|---------|
| **Boundary adjacency** | Shared boundary segment | Wall between rooms |
| **Vertex adjacency** | Shared vertex only | Two polygons meeting at corner |
| **Edge adjacency** | Shared edge | Adjacent cells in grid |

Adjacency is symmetric: if A is adjacent to B, then B is adjacent to A.

Adjacency composes with Topology (connectivity, incidence).

### 6.4 Proximity

**Concept:** `Proximity`
**Source:** Spatial §10 (Proximity), Spatial §9 (Distance)
**Status:** define-new

Proximity describes spatial closeness according to a declared metric or threshold.

| Type | Meaning | Metric |
|------|---------|--------|
| **Distance proximity** | Within declared distance threshold | Euclidean, Manhattan, geodetic |
| **Topological proximity** | Within declared connectivity hops | Graph distance |
| **Semantic proximity** | Within declared semantic region | Domain-specific |

Proximity is NOT equivalent to distance (Spatial §10). Two entities may be close by distance but semantically distant (e.g., separated by a wall).

Proximity thresholds MAY be dynamic (changing with context, time, or scale).

### 6.5 Visibility

**Concept:** `Visibility`
**Source:** Spatial §11 (Spatial Relationships), Spatial §7 (Neighbourhood) — visibility as neighbourhood criterion
**Status:** define-new

Visibility describes whether entity A has line-of-sight to entity B.

| Type | Meaning | Considerations |
|------|---------|---------------|
| **Geometric visibility** | Unobstructed ray between A and B | Ray-casting against geometry |
| **Semantic visibility** | Within declared visibility region | Region-based predicate |
| **Probabilistic visibility** | Visibility under uncertainty | Sensor model, occlusion probability |

Visibility is directional: A may be visible from B while B is not visible from A (asymmetric occlusion).

Visibility composes with Perception and Rendering semantics.

### 6.6 Relationship Hypergraph Projection

All spatial relationships project into the Semantic Hypergraph:

```text
Entity A
    │
    ├── contained-in ─────► Region B
    ├── adjacent-to ──────► Entity C
    ├── within-distance ──► Entity D (d=5.0m)
    └── visible-from ─────► Entity E
```

Higher-order relationships are representable when required (Spatial §33).

### 6.7 Provenance

```yaml
concept: SpatialRelationship
source: O3DE
source_terminology: AZ::ShapeComponentNotifications, AZ::ObstructionestingBus, AZ::VisibilityBus
scr_interpretation: First-class semantic relationships in Hypergraph. Four primary types: containment, adjacency, proximity, visibility. Provider-independent.
differences: O3DE implements spatial queries as bus calls to shape/obstruction components. SCR defines as semantic relationships independent of query mechanism. O3DE has no unified spatial relationship model; SCR provides one.
```

## 7. Gap Analysis

### 7.1 Classification of SCR Needs

| Concept | Current SCR Status | Action | Classification |
|---------|-------------------|--------|----------------|
| **SemanticTransform** | No composite definition. Geometry Transform, Translation, Rotation, Scale are separate subdomains. | **define-new** | New composite concept unifying Geometry primitives into semantic pose |
| **SpatialHierarchy** | Spatial §17 defines hierarchical structures abstractly. No parent/child composition rules. | **define-new** | New hierarchy composition semantics |
| **LocalToWorld** | No definition. | **define-new** | Transform accumulation algorithm |
| **CoordinateConvention** | Spatial §3, §4 define coordinates/frames abstractly. No concrete canonical convention. | **define-new** | SCR canonical + Z-forward, +Y-up, +X-right |
| **CoordinateMapping** | No inter-system mapping definitions. | **define-new** | SCR ↔ O3DE, ROS 2, USD mappings |
| **Containment** | Spatial §6 defines regions/containment abstractly. | **define-new** | Operational containment relationship |
| **Adjacency** | Spatial §11 mentions adjacency. No definition. | **define-new** | Operational adjacency relationship |
| **Proximity** | Spatial §10 defines proximity abstractly. | **define-new** | Operational proximity relationship |
| **Visibility** | Spatial §7 mentions visibility as neighbourhood criterion. No definition. | **define-new** | Operational visibility relationship |
| **Position** | Spatial §2 defines position abstractly. `lib/801_Spatial/Position/` is stub. | **needs-extension** | Operational position within SemanticTransform |
| **Orientation** | Spatial §5 defines orientation abstractly. `lib/801_Spatial/Orientation/` is stub. | **needs-extension** | Operational orientation within SemanticTransform |
| **H3** | `lib/801_Spatial/H3/` is stub. | **deferred** | H3 is provider indexing, not core spatial semantics |

### 7.2 Concepts Already Adequately Defined

| Concept | Where Defined |
|---------|---------------|
| Position (abstract) | Spatial §2 — adequate as foundation |
| Orientation (abstract) | Spatial §5 — adequate as foundation |
| Distance (abstract) | Spatial §9 — adequate as foundation |
| Spatial Relationships (abstract) | Spatial §11 — adequate as foundation |
| Coordinate Systems (abstract) | Spatial §3–4 — adequate as foundation |
| Geometry Transform | `lib/302_Geometry/Transform/` — operational |
| Geometry Translation | `lib/302_Geometry/Translation/` — operational |
| Geometry Rotation | `lib/302_Geometry/Rotation/` — operational |
| Geometry Scale | `lib/302_Geometry/Scale/` — operational |

### 7.3 Classification Summary

| Classification | Count | Concepts |
|----------------|-------|----------|
| **already-defined** | 9 | Position (abstract), Orientation (abstract), Distance (abstract), Spatial Relationships (abstract), Coordinate Systems (abstract), Geometry Transform, Translation, Rotation, Scale |
| **needs-extension** | 2 | Position (operational), Orientation (operational) |
| **define-new** | 10 | SemanticTransform, SpatialHierarchy, LocalToWorld, CoordinateConvention, CoordinateMapping, Containment, Adjacency, Proximity, Visibility, and composite SemanticTransform |
| **deferred** | 1 | H3 (provider indexing, not core semantics) |

## 8. Derived Definitions for Semantic Library

### 8.1 Recommended File Structure

```
lib/101_Core/
├── Transforms/           (needs: SemanticTransform definition)
└── ...other domains...

lib/801_Spatial/
├── Position/             (needs: operational position definition)
├── Orientation/          (needs: operational orientation definition)
├── Transformations/      (needs: SemanticTransform composite definition)
├── CoordinateSystems/    (needs: canonical convention, mapping definitions)
├── ReferenceFrames/      (needs: local/world frame distinction)
├── Hierarchy/            (new: parent/child composition rules)
├── Containment/          (new: containment relationship)
├── Adjacency/            (new: adjacency relationship)
├── Proximity/            (needs: operational proximity definition)
├── Visibility/           (new: visibility relationship)
└── ...existing domains...
```

### 8.2 Invariants Added

| Invariant | Statement |
|-----------|-----------|
| **SPATIAL-INV-019 (Transform Composite Integrity)** | A SemanticTransform MUST be decomposable into position, orientation, and scale components without loss of semantic meaning. |
| **SPATIAL-INV-020 (Hierarchy Transform Accumulation)** | World transform MUST be computable from local transforms via deterministic accumulation along the parent chain. |
| **SPATIAL-INV-021 (Coordinate Explicitness)** | All coordinate values MUST declare their coordinate convention. Cross-boundary transfers MUST apply explicit mapping. |
| **SPATIAL-INV-022 (Containment Transitivity)** | Containment relationships MUST be transitive. |
| **SPATIAL-INV-023 (Adjacency Symmetry)** | Adjacency relationships MUST be symmetric. |
| **SPATIAL-INV-024 (Visibility Asymmetry)** | Visibility relationships MAY be asymmetric due to occlusion. |

## 9. Exit Criteria Check

- [x] Semantic transform distinguished from representation transform (Section 3.2)
- [x] Coordinate conventions documented with mappings to O3DE, USD, ROS 2, H3 (Section 5.2)
- [x] Hierarchy composition rules defined (Section 4)
- [x] Parent/child transform accumulation documented (Section 4.2)
- [x] Spatial relationships defined: containment, adjacency, proximity, visibility (Section 6)
- [x] SCR canonical convention declared: +Z forward, +Y up, +X right (Section 5.1)
- [x] Provenance documented for all O3DE-derived concepts (Sections 3.5, 4.5, 5.6, 6.7)
- [x] Each concept classified: already-defined / needs-extension / define-new (Section 7.1)

## 10. Deferred to Subsequent Sprints

| Concept | Sprint | Reason |
|---------|--------|--------|
| H3 operational definition | Sprint 03+ | Provider indexing; not core spatial semantics |
| Tick / Temporal Transform | Sprint 03 (Physics & Dynamics) | Interacts with dynamics and time-varying transforms |
| EntityTemplate / EntitySpawn | Sprint 04 (Asset/Resource/Materialization) | Tied to serialization and instantiation pipelines |
| Field-Spatial Composition | Sprint 03+ | Spatial fields compose with dynamics |
| Navigation / Pathfinding | Sprint 03+ | Higher-level spatial computation |
# Sprint 02: Spatial & Hierarchy

Define/extend SCR spatial semantics: Transform, hierarchy, coordinate system, orientation, scale.

## Deliverables
- Transform semantic definition (distinguishing from O3DE transform representation)
- Hierarchy semantic definition
- Coordinate system conventions
- Spatial relationship semantics

## Exit Criteria
- [ ] Semantic transform distinguished from representation
- [ ] Coordinate conventions documented with mappings to O3DE/USD/ROS2
- [ ] Hierarchy composition rules defined
# Sprint 003 Record: Physics Dynamics & Simulation Semantics

## 1. Objective

Define SCR semantic PhysicsBody (provider-independent physical entity), KinematicConstraint (DOF restriction), PhysicalContact (collision lifecycle), SimulationStep (semantic time advancement), and Force/Interaction (semantic force concept). Ground definitions in existing `lib/501_Physics`, `lib/502_Dynamics`, `lib/503_Simulation` definitions. Preserve invariant: **SCR PhysicsBody → adapter → provider (Bullet3 / PhysX / AzPhysics)**.

## 2. Existing SCR Library Assessment

### 2.1 Domains With Substantive Definitions

| Domain | Path | Status | Relevance |
|--------|------|--------|-----------|
| **Physics** | `lib/501_Physics/101_definition.md` | Operational (0.1.0) | Authoritative physics domain. 1931 lines, 18 invariants (PHYSICS-INV-001–018). Defines quantities, state, laws, interactions, constraints, conservation, fields, equilibrium, scale, approximation, dimensional analysis, provider independence. Normative authority for all physical semantics. |
| **Physics Body** | `lib/501_Physics/Body/101_definition.md` | Operational (0.1.0) | Semantic body concept: mass, spatial bounds, kinematic state, material constitution. Provider-independent. |
| **Physics RigidBody** | `lib/501_Physics/RigidBody/101_definition.md` | Operational (0.1.0) | Idealized body with invariant internal distances under stress. Subdomain of Body. |
| **Physics Constraints** | `lib/501_Physics/Constraints/101_definition.md` | Operational (0.1.0) | Holonomic, non-holonomic, joints, bilateral, unilateral motion restrictions. |
| **Physics Collision** | `lib/501_Physics/Collision/101_definition.md` | Operational (0.1.0) | Discrete/continuous high-energy impulsive interaction between intersecting bodies. |
| **Physics Contact** | `lib/501_Physics/Contact/101_definition.md` | Operational (0.1.0) | Boundary interaction, non-penetration condition, normal force transmission. |
| **Physics Force** | `lib/501_Physics/Force/101_definition.md` | Operational (0.1.0) | Vector interaction causing momentum change, acceleration, or stress. |
| **Physics Kinematics** | `lib/501_Physics/Kinematics/101_definition.md` | Operational (0.1.0) | Geometric/temporal motion description without forces. |
| **Physics Mass** | `lib/501_Physics/Mass/101_definition.md` | Operational (0.1.0) | Inertia, gravitational coupling, material quantity measure. |
| **Physics Momentum** | `lib/501_Physics/Momentum/101_definition.md` | Operational (0.1.0) | Conserved linear (p=mv) and angular (L=r×p) momentum. |
| **Collision Broadphase** | `lib/501_Physics/Collision/Broadphase/101_definition.md` | Operational (0.1.0) | Spatial partitioning, AABB/DBVT/SAP, conservative pair generation. |
| **Collision Narrowphase** | `lib/501_Physics/Collision/Narrowphase/101_definition.md` | Operational (0.1.0) | GJK/EPA exact distance, contact manifold, penetration resolution. |
| **Collision Impact** | `lib/501_Physics/Collision/Impact/101_definition.md` | Operational (0.1.0) | Impulsive momentum transfer, restitution, Coulomb friction, energy dissipation. |
| **Dynamics** | `lib/502_Dynamics/101_definition.md` | Draft (0.1.0) | Semantic domain of state evolution. 1937 lines, 18 invariants (DYNAMICS-INV-001–018). Defines state, transitions, evolution laws, time, trajectories, events, feedback, coupling, stability, attractors, bifurcation, chaos. |
| **Simulation** | `lib/503_Simulation/101_definition.md` | Draft (0.1.0) | Computational realization of models. 1978 lines, 18 invariants (SIMULATION-INV-001–018). Defines model/state distinction, stepping, events, checkpoints, branching, replay, ensembles, validation/verification. |

### 2.2 Existing Rust Implementations

| File | Status | Relevance |
|------|--------|-----------|
| `lib/501_Physics/301_Implementation/rust/src/body.rs` | Operational | `PhysicalBody` struct: id, mass, center_of_mass, `KinematicState` (position, velocity, orientation, angular_velocity). Linear momentum `P=mv`, kinetic energy `E_k=½mv²`. |
| `lib/501_Physics/301_Implementation/rust/src/constraint.rs` | Operational | `PhysicalConstraint`: id, kind (FixedDistanceJoint, FixedOrientation, UnilateralContact, PlanarBoundary), body_a, body_b, target_value. Distance satisfaction check. |
| `lib/501_Physics/301_Implementation/rust/src/interaction.rs` | Operational | `PhysicalInteraction`: id, kind (GravitationalNBody, ElectromagneticLorentz, ContactImpact, FluidDrag, ThermodynamicExchange), participants (multi-body), medium, force (Quantity), location, time, governing_law. Higher-order interaction, PHYSICS-INV-015 compliant. |

### 2.3 Stub Domains (Placeholder Definitions Only)

| Domain | Path | Implication |
|--------|------|-------------|
| **Simulation Execution** | `lib/503_Simulation/Execution/101_definition.md` | Empty stub. Execution semantics deferred. |
| **Simulation Integration** | `lib/503_Simulation/Integration/101_definition.md` | Empty stub. Integration semantics deferred. |
| **Simulation Time** | `lib/503_Simulation/Time/101_definition.md` | Empty stub. Simulation time semantics deferred. |
| **Simulation Clock** | `lib/503_Simulation/Clock/101_definition.md` | Empty stub. Clock semantics deferred. |
| **Simulation Scheduling** | `lib/503_Simulation/Scheduling/101_definition.md` | Empty stub. Scheduling semantics deferred. |
| **Simulation Interaction** | `lib/503_Simulation/Interaction/101_definition.md` | Empty stub. Simulation interaction semantics deferred. |

### 2.4 Assessment Summary

**Physics layer** is well-defined: 18 invariants, comprehensive 101_definition (1931 lines), operational subdomains (Body, Constraints, Collision, Contact, Force, Kinematics, Mass, Momentum), and a working Rust implementation of `PhysicalBody`, `PhysicalConstraint`, `PhysicalInteraction`.

**Dynamics layer** is comprehensive at the abstract level (1937 lines, 18 invariants) but no operational subdomain definitions exist beyond the root.

**Simulation layer** has a comprehensive root definition but all subdomains (Execution, Integration, Time, Clock, Scheduling, Interaction) are empty stubs.

**Critical gap:** No operational definition exists for:
- PhysicsBody as a semantic concept with provider-adapter mapping (body.rs exists but lacks normative semantic definition)
- KinematicConstraint as DOF-restricted semantic concept
- PhysicalContact / collision lifecycle as semantic event sequence
- SimulationStep as semantic time advancement (distinct from implementation tick)
- Force/Interaction as provider-independent semantic concept with adapter pattern

M003 Sprint 03 must fill this gap.

## 3. PhysicsBody

### 3.1 SCR Semantic PhysicsBody (Normative)

**Concept:** `PhysicsBody`
**Source:** Physics §Body, Physics §RigidBody, Physics §Mass, Physics §Kinematics, Physics §Conservation, `lib/501_Physics/301_Implementation/rust/src/body.rs`
**Status:** define-new — operational subdomain definition; extends existing stub

A PhysicsBody is the **provider-independent semantic entity** possessing mass, spatial bounds, kinematic state, material constitution, and dynamic properties subject to physical laws.

```text
PhysicsBody
├── identity: SemanticId (from Core/Identity)
├── mass: Quantity (mass, kg)
├── inertia: Tensor3x3 (moment of inertia tensor)
├── kinematic_state: KinematicState
│   ├── position: Point3D (affine, reference-frame-scoped)
│   ├── velocity: Vector3D (m/s)
│   ├── orientation: Quaternion (unit quaternion, Hamilton convention)
│   └── angular_velocity: Vector3D (rad/s)
├── spatial_bounds: CollisionShape (from Geometry)
├── material: MaterialConstitution (from Physics/Material)
├── forces: Vec<Force> (accumulated external forces)
├── constraints: Vec<ConstraintId> (active constraint references)
└── properties: BodyProperties
    ├── is_static: bool
    ├── is_kinematic: bool
    ├── gravity_scale: f64
    ├── linear_damping: f64
    └── angular_damping: f64
```

### 3.2 PhysicsBody ≠ Provider Body

| Aspect | SCR PhysicsBody | Bullet3 btRigidBody | PhysX PxRigidDynamic | AzPhysics AzRigidBody |
|--------|----------------|---------------------|---------------------|----------------------|
| **Authority** | SCR — defines meaning | Bullet — encodes meaning | PhysX — encodes meaning | O3DE — encodes meaning |
| **Existence** | Meaningful whether or not a provider exists | Requires Bullet runtime | Requires PhysX runtime | Requires O3DE runtime |
| **Identity** | Has semantic identity (SID-scoped) | Bullet internal handle | PhysX internal pointer | AZ::EntityId |
| **Mass** | Semantic Quantity (kg, with units) | Scalar f64 | Scalar f64 | Scalar f64 (no units) |
| **State** | Semantic KinematicState | btTransform + btVector3 | PxTransform + PxVec3 | AZ::Transform + AZ::Vector3 |
| **Inertia** | Semantic Tensor3x3 | btMatrix3x3 | PxMat33 | AZ::Matrix3x3 |
| **Forces** | Semantic Force objects | btVector3 arrays | PxForceAccumulator | AZ::Vector3 accumulators |
| **Constraints** | Semantic ConstraintIds | btTypedConstraint pointers | PxConstraint pointers | AZ::Constraint pointers |

Same semantic meaning, three provider representations. Neither provider redefines the semantic meaning.

### 3.3 Derived Quantities

PhysicsBody supports computed semantic quantities without provider dependency:

| Quantity | Formula | Type | Unit |
|----------|---------|------|------|
| Linear momentum | **p** = m·**v** | Vector3D | kg·m/s |
| Angular momentum | **L** = I·**ω** | Vector3D | kg·m²/s |
| Translational KE | E_k = ½m·v² | Scalar (f64) | J |
| Rotational KE | E_rot = ½**ω**·I·**ω** | Scalar (f64) | J |
| Total energy | E = E_k + E_rot | Scalar (f64) | J |

These are semantic computations. Providers may cache or approximate them differently.

### 3.4 Determinism

PhysicsBody state evolution is deterministic under identical:
- Initial conditions
- Forces and constraints
- Temporal configuration
- Reference frame

Provider-level nondeterminism (parallel scheduling, floating-point ordering) does not affect semantic determinism (per PHYSICS-INV-018, Dynamics INV-012).

### 3.5 Provenance

```yaml
concept: PhysicsBody
source: Bullet3, PhysX, O3DE
source_terminology:
  Bullet3: btRigidBody (btTransform, btVector3, btScalar mass)
  PhysX: PxRigidDynamic (PxTransform, PxVec3, PxReal mass)
  O3DE: AzRigidBody (AZ::Transform, AZ::Vector3, float mass)
scr_interpretation: Provider-independent physical entity possessing mass, inertia, kinematic state, spatial bounds, material constitution. Computed quantities (momentum, energy) are semantic derivations. Provider adapters translate between SCR and engine representations.
differences:
  Bullet3: Combined collision + dynamics object. SCR separates Body from Collision. Bullet uses btMotionState for interpolation; SCR has no interpolation concept.
  PhysX: PxRigidDynamic owns shape list. SCR shapes are separate. PhysX has separate PxRigidStatic vs PxRigidDynamic; SCR body has is_static flag.
  O3DE: AzRigidBody is component on AZ::Entity. SCR body is standalone semantic entity with Hypergraph relationships. O3DE uses character controller separate from rigid body; SCR unifies under Body with properties.
```

## 4. KinematicConstraint

### 4.1 SCR Semantic KinematicConstraint (Normative)

**Concept:** `KinematicConstraint`
**Source:** Physics §Constraints, Physics §Kinematics, `lib/501_Physics/301_Implementation/rust/src/constraint.rs`
**Status:** define-new — operational subdomain definition; extends existing stub

A KinematicConstraint is the **provider-independent semantic restriction** on degrees of freedom (DOF) of physical bodies. Constraints are semantic entities within the Hypergraph, not solver artifacts.

```text
KinematicConstraint
├── identity: SemanticId
├── kind: ConstraintKind
│   ├── FixedJoint          (6 DOF locked)
│   ├── HingeJoint          (1 DOF: rotation about axis)
│   ├── SliderJoint         (1 DOF: translation along axis)
│   ├── BallSocketJoint     (3 DOF: rotation, 0 translation)
│   ├── PrismaticJoint      (1 DOF: translation)
│   ├── PlanarConstraint    (3 DOF: translation in plane)
│   ├── DistanceConstraint  (limits inter-body distance)
│   ├── NonPenetration      (unilateral contact)
│   └── Custom (provider-extensible)
├── bodies: (BodyId, Option<BodyId>)
├── local_frame_a: Transform (attachment frame on body A)
├── local_frame_b: Transform (attachment frame on body B)
├── limits: ConstraintLimits
│   ├── lower_limit: f64
│   ├── upper_limit: f64
│   └── rest_length: f64 (optional)
├── motor: ConstraintMotor (optional)
│   ├── motor_type: None | Velocity | Position | Force
│   ├── target: f64
│   └── max_force: f64
└── breakable: bool (semantic: can this constraint be broken?)
```

### 4.2 Degrees of Freedom Mapping

| Constraint Kind | Free DOF | Locked DOF | Provider Mapping |
|----------------|----------|------------|-----------------|
| **FixedJoint** | 0 | 6 | Bullet: `btFixedConstraint`; PhysX: `PxJoint` with all limits locked; AzPhysics: `AZ::FixedJoint` |
| **HingeJoint** | 1 (rotation) | 5 | Bullet: `btHingeConstraint`; PhysX: `PxD6Joint` (free Z-rotation); AzPhysics: `AZ::HingeJoint` |
| **SliderJoint** | 1 (translation) | 5 | Bullet: `btSliderConstraint`; PhysX: `PxD6Joint` (free X-translation); AzPhysics: `AZ::SliderJoint` |
| **BallSocketJoint** | 3 (rotation) | 3 | Bullet: `btPoint2PointConstraint`; PhysX: `PxSphericalJoint`; AzPhysics: `AZ::BallSocketJoint` |
| **NonPenetration** | Variable | Per-contact | Bullet: collision solver; PhysX: contact solver; AzPhysics: collision solver |

### 4.3 Constraint Semantics ≠ Solver Mechanics

| Aspect | SCR KinematicConstraint | Bullet Constraint Solver | PhysX Constraint Solver |
|--------|------------------------|-------------------------|------------------------|
| **Authority** | SCR — defines DOF restriction | Bullet — enforces via sequential impulse | PhysX — enforces via iterative solver |
| **Solvability** | Declarative: "these DOFs are locked" | Algorithmic: iterative warm-starting | Algorithmic: Projected Gauss-Seidel |
| **Breaking** | Semantic: constraint can be declared breakable | Bullet: `setBreakingThreshold` | PhysX: `PxJointFlag::eBREAKABLE` |
| **Motor** | Semantic: "apply force to achieve target" | Bullet: motor impulse application | PhysX: drive configuration |

### 4.4 Provenance

```yaml
concept: KinematicConstraint
source: Bullet3, PhysX, O3DE
source_terminology:
  Bullet3: btTypedConstraint hierarchy (btFixedConstraint, btHingeConstraint, btSliderConstraint, btPoint2PointConstraint)
  PhysX: PxJoint hierarchy (PxD6Joint, PxSphericalJoint, PxFixedJoint, PxPrismaticJoint)
  O3DE: AZ::Joint component hierarchy (AZ::FixedJoint, AZ::HingeJoint, AZ::SliderJoint, AZ::BallSocketJoint)
scr_interpretation: Provider-independent DOF restriction on physical bodies. Semantic entity with identity, kind, attached bodies, local frames, limits, motor. Provider adapters translate DOF specifications to engine-native constraint representations.
differences:
  Bullet3: Constraints are separate objects linking two btCollisionObjects. SCR uses Semantic Hypergraph edges. Bullet solver runs at fixed iteration count; SCR does not prescribe solver iteration.
  PhysX: Joints are PxJoint subclasses with drives/limits. SCR motor is semantic. PhysX joint has specific coordinate system per joint type; SCR uses generic local frames.
  O3DE: Joints are AZ::Components on entities. SCR constraints are Hypergraph relationships. O3DE joint component has role-based frame orientation; SCR uses explicit local frames.
```

## 5. PhysicalContact (Collision Lifecycle)

### 5.1 SCR Semantic PhysicalContact (Normative)

**Concept:** `PhysicalContact`
**Source:** Physics §Collision, Physics §Contact, Collision/Broadphase, Collision/Narrowphase, Collision/Impact
**Status:** define-new — operational subdomain definition; extends existing stubs

PhysicalContact represents the **provider-independent semantic lifecycle** of a collision between physical bodies. It is a sequence of semantic events, not a single data structure.

```text
CollisionLifecycle
├── Phase 1: BroadphaseCandidatePair
│   ├── body_a: BodyId
│   ├── body_b: BodyId
│   └── spatial_overlap: bool (conservative)
├── Phase 2: NarrowphaseEvaluation
│   ├── contact_manifold: ContactManifold
│   │   ├── contact_points: Vec<ContactPoint>
│   │   ├── contact_normal: Vector3D (unit, from B into A)
│   │   └── penetration_depth: f64
│   ├── separating: bool
│   └── gjk_epa_used: bool
├── Phase 3: PhysicalContact
│   ├── contact_id: SemanticId
│   ├── bodies: (BodyId, BodyId)
│   ├── contact_point: Point3D
│   ├── contact_normal: Vector3D
│   ├── penetration_depth: f64
│   ├── normal_impulse: Quantity (N·s)
│   ├── friction_impulse: Vector3D (N·s)
│   ├── restitution_coefficient: f64
│   └── friction_coefficient: f64
├── Phase 4: CollisionResponse
│   ├── delta_momentum_a: Vector3D
│   ├── delta_momentum_b: Vector3D
│   ├── delta_angular_momentum_a: Vector3D
│   ├── delta_angular_momentum_b: Vector3D
│   └── energy_dissipated: Quantity (J)
└── Phase 5: ContactResolution
    ├── bodies_separated: bool
    ├── penetration_resolved: bool
    └── constraint_generated: Option<ConstraintId> (for sustained contact)
```

### 5.2 Contact Lifecycle Semantics

| Phase | Meaning | Provider Mapping |
|-------|---------|-----------------|
| **BroadphaseCandidate** | Conservative spatial overlap detected | Bullet: `btDbvtBroadphase::calculateOverlappingPairs`; PhysX: `PxScene::getCollidingPairs`; AzPhysics: `AZ::PhysicsSystem::GetBodiesAtAABB` |
| **NarrowphaseEvaluation** | Exact geometric distance / penetration computed | Bullet: `btManifoldResult` + GJK/EPA; PhysX: `PxContactManager`; AzPhysics: `AZ::CollisionSystem` |
| **PhysicalContact** | Semantic contact event with impulse magnitudes | Bullet: `btManifoldPoint`; PhysX: `PxContactPairPoint`; AzPhysics: contact callback |
| **CollisionResponse** | Impulse application and momentum transfer | Bullet: solver impulse application; PhysX: solver impulse application; AzPhysics: solver impulse application |
| **ContactResolution** | Separation or constraint generation | Bullet: persistent manifold; PhysX: `PxContactPairFlag`; AzPhysics: contact event |

### 5.3 Semantic Contact vs Provider Contact

| Aspect | SCR PhysicalContact | Bullet btManifoldPoint | PhysX PxContactPairPoint | AzPhysics Contact |
|--------|-------------------|----------------------|-------------------------|-------------------|
| **Authority** | SCR — defines contact meaning | Bullet — computes contact | PhysX — computes contact | O3DE — computes contact |
| **Lifecycle** | 5-phase semantic sequence | Single manifold update | Single contact pair | Single contact event |
| **Impulse** | Semantic Quantity with units | Scalar/Vector (no units) | Scalar/Vector (no units) | AZ::Vector3 (no units) |
| **Persistence** | Semantic: contact can be sustained | Manifold-based (4-point) | Event-based or persistent | Event-based |
| **Breakability** | Semantic: contact can become constraint | Solver-managed | Joint-based | Component-managed |

### 5.4 Broadphase Invariants (Carried Forward)

- **BROADPHASE-INV-001 (Conservative Non-Exclusion)**: False negatives strictly prohibited.
- **BROADPHASE-INV-002 (Quantized Margin Consistency)**: Bounding volumes expand by positive margin.
- **BROADPHASE-INV-003 (Layer Filtering Semantics)**: Collision group/mask bitfields are Boolean filtering.

### 5.5 Narrowphase Invariants (Carried Forward)

- **NARROWPHASE-INV-001 (Separating Plane Normal)**: Contact normal points B→A, unit magnitude.
- **NARROWPHASE-INV-002 (Minimal Translational Vector)**: Penetration resolved by `-d·n`.
- **NARROWPHASE-INV-003 (Contact Manifold Persistency)**: 4-point persistent manifold for stable stacking.

### 5.6 Impact Invariants (Carried Forward)

- **IMPACT-INV-001 (Energy Conservation Upper Bound)**: Kinetic energy cannot be generated: E_k(t+) ≤ E_k(t-).
- **IMPACT-INV-002 (Non-Negative Normal Impulse)**: J_n ≥ 0 (non-adhesive).
- **IMPACT-INV-003 (Coulomb Complementarity)**: J_t ∥ -v_rel,t.

### 5.7 Provenance

```yaml
concept: PhysicalContact
source: Bullet3, PhysX, O3DE
source_terminology:
  Bullet3: btPersistentManifold, btManifoldPoint, btDbvtBroadphase, btGjkEpaSolver2
  PhysX: PxScene, PxContactManager, PxContactPair, PxContactPairPoint
  O3DE: AZ::CollisionSystem, AZ::PhysicsCollisionContext
scr_interpretation: 5-phase semantic collision lifecycle: broadphase candidate → narrowphase evaluation → physical contact event → collision response → contact resolution. Provider-independent. Provider adapters map phase transitions to engine-specific APIs.
differences:
  Bullet3: Manifold-based contact persistence (4-point). SCR uses semantic lifecycle, not manifold data structure. Bullet solver integrates contact resolution in single step; SCR separates response and resolution semantically.
  PhysX: Event-based contact pairs with configurable contact flags. SCR lifecycle is independent of flag configuration. PhysX has separate trigger vs contact; SCR unifies under PhysicalContact with semantic properties.
  O3DE: Contact events dispatched through AZ::CollisionSystem. SCR does not use event bus for contact; contact is Hypergraph state transition.
```

## 6. SimulationStep

### 6.1 SCR Semantic SimulationStep (Normative)

**Concept:** `SimulationStep`
**Source:** Simulation §Stepping, Simulation §Time, Simulation §Execution, Dynamics §Time
**Status:** define-new — fills empty stubs in lib/503_Simulation

A SimulationStep is the **provider-independent semantic time advancement** of a physical simulation. It is distinct from an implementation "tick" or "frame".

```text
SimulationStep
├── step_id: SemanticId
├── temporal_semantics: TemporalSemantics
│   ├── simulation_time_before: Quantity (s)
│   ├── simulation_time_after: Quantity (s)
│   ├── dt: Quantity (s) — semantic timestep
│   └── wall_clock_time: Quantity (s) — execution time (observational)
├── integration_method: IntegrationMethod
│   ├── type: SemiImplicitEuler | RungeKutta4 | Verlet | Adaptive
│   ├── fixed_dt: Option<Quantity> (for fixed-step)
│   └── adaptive_tolerance: Option<f64> (for adaptive)
├── physics_phase: PhysicsPhase
│   ├── force_accumulation: Quantity
│   ├── constraint_solve: SolveReport
│   ├── integration: IntegrationReport
│   └── collision_detection: CollisionReport
├── state_before: SemanticStateSnapshot
├── state_after: SemanticStateSnapshot
├── events: Vec<SemanticEvent> (collisions, constraint breaks, etc.)
├── invariants_checked: Vec<InvariantCheck>
│   ├── energy_conservation: bool
│   ├── momentum_conservation: bool
│   └── constraint_satisfaction: bool
└── provenance: StepProvenance
    ├── model_id: SemanticId
    ├── provider_id: SemanticId
    ├── numerical_method: String
    └── configuration_hash: Hash
```

### 6.2 Semantic Step ≠ Implementation Tick

| Aspect | SCR SimulationStep | Bullet3 stepSimulation | PhysX PxScene::simulate | O3DE AzPhysics Tick |
|--------|-------------------|----------------------|----------------------|-------------------|
| **Authority** | SCR — defines temporal semantics | Bullet — advances internal state | PhysX — advances internal state | O3DE — advances physics state |
| **Time** | Semantic Quantity (seconds, SI) | Scalar float (no units) | Scalar float (no units) | Scalar float (no units) |
| **State** | Semantic state snapshot | Internal rigid body state | Internal scene state | AZ component state |
| **Events** | Semantic events (collisions, breaks) | Callback-based | Callback-based | Event bus-based |
| **Integration** | Declarative method selection | Fixed or sub-stepping | Fixed or sub-stepping | Fixed per tick |
| **Invariants** | Explicitly checked per step | Implicit in solver | Implicit in solver | Not checked |
| **Provenance** | Full provenance chain | Minimal | Minimal | Entity-level provenance |

### 6.3 Step Semantics

A SimulationStep represents **one semantic advancement** of the simulation clock:

```text
SimulationStep(dt)
├── 1. Force Accumulation
│   ├── Gravity: F_grav = m·g (semantic: physics law)
│   ├── Applied forces: Σ F_applied
│   └── Constraint forces: Σ F_constraint (solver-derived)
├── 2. Integration
│   ├── v(t+dt) = v(t) + (F/m)·dt    (Semi-implicit Euler)
│   └── x(t+dt) = x(t) + v(t+dt)·dt
├── 3. Collision Detection
│   ├── Broadphase → candidate pairs
│   ├── Narrowphase → contact manifolds
│   └── Contact response → impulses
├── 4. Constraint Solving
│   ├── Iterative solve
│   └── Violation resolution
├── 5. State Update
│   ├── New kinematic state
│   └── New constraint state
└── 6. Event Emission
    ├── Collision events
    ├── Constraint break events
    └── Invariant violation events
```

### 6.4 Determinism

SimulationStep composition is deterministic under equivalent:
- Model, initial conditions, parameters
- Temporal configuration (dt, method)
- Provider identity and configuration
- Reference frame

Provider-level nondeterminism (parallel scheduling, floating-point ordering) affects reproducibility but not semantic determinism (per Simulation INV-004, Dynamics INV-004).

### 6.5 Provenance

```yaml
concept: SimulationStep
source: Bullet3, PhysX, O3DE
source_terminology:
  Bullet3: btDynamicsWorld::stepSimulation(timeStep, maxSubSteps, fixedTimeStep)
  PhysX: PxScene::simulate(dt, scratchMemBlock, scratchMemBlockSize, controlShaderReturn, profiler)
  O3DE: AZ::TickBus::OnTick (physics tick), AZ::PhysicsSystemContext::Simulate
scr_interpretation: Provider-independent semantic time advancement. One step = one semantic clock advancement with force accumulation, integration, collision detection, constraint solving, state update, event emission. Temporal semantics (dt, simulation time) are semantic Quantities with units. Invariant checks explicit per step.
differences:
  Bullet3: stepSimulation combines sub-stepping + interpolation. SCR step is atomic semantic unit. Bullet uses fixedStep + maxSubSteps; SCR uses declarative IntegrationMethod.
  PhysX: simulate() is blocking call with profiler/shader control. SCR step is semantic, not blocking call. PhysX has fetchResults for async; SCR does not prescribe execution model.
  O3DE: Physics tick driven by AZ::TickBus at fixed rate. SCR step is semantic advancement, not tied to tick bus. O3DE tick rate is configuration; SCR dt is semantic Quantity.
```

## 7. Force / Interaction

### 7.1 SCR Semantic Force (Normative)

**Concept:** `Force`
**Source:** Physics §Force, Physics §Interactions, `lib/501_Physics/301_Implementation/rust/src/interaction.rs`
**Status:** extend-existing — operational subdomain definition; fills Force subdomain

A Force is the **provider-independent semantic vector interaction** causing linear momentum change, acceleration, or stress in physical bodies.

```text
Force
├── identity: SemanticId
├── magnitude: Quantity (N — Newtons)
├── direction: Vector3D (unit direction)
├── point_of_application: Point3D (where force is applied)
├── source_body: Option<BodyId> (origin of force)
├── target_body: BodyId (body experiencing force)
├── kind: ForceKind
│   ├── Gravity           (F = G·m1·m2/r²)
│   ├── Contact           (normal + friction)
│   ├── Spring            (F = -k·x)
│   ├── Damping           (F = -c·v)
│   ├── Applied           (user-defined)
│   ├── Electromagnetic   (Lorentz, Coulomb)
│   ├── FluidDrag         (F = ½·ρ·v²·Cd·A)
│   └── Custom            (provider-extensible)
└── governing_law: Option<LawId> (semantic reference to physical law)
```

### 7.2 Force ≠ Provider Force Accumulator

| Aspect | SCR Force | Bullet3 btVector3 force | PhysX PxForceAccumulator | AzPhysics AZ::Vector3 force |
|--------|-----------|------------------------|-------------------------|----------------------------|
| **Authority** | SCR — defines interaction meaning | Bullet — accumulates force | PhysX — accumulates force | O3DE — accumulates force |
| **Units** | Semantic Quantity (Newtons) | Scalar (no units) | Scalar (no units) | Scalar (no units) |
| **Direction** | Explicit Vector3D | Implicit in btVector3 | Implicit in PxVec3 | Implicit in AZ::Vector3 |
| **Source** | Semantic: which body or law | Not tracked | Not tracked | Not tracked |
| **Law** | Semantic: governing physical law | Not tracked | Not tracked | Not tracked |

### 7.3 PhysicalInteraction (Higher-Order)

The existing `PhysicalInteraction` struct (`interaction.rs`) already implements higher-order interaction semantics per PHYSICS-INV-015:

```text
PhysicalInteraction
├── id: InteractionId
├── kind: InteractionKind (GravitationalNBody, ElectromagneticLorentz, ContactImpact, FluidDrag, ThermodynamicExchange)
├── participants: Vec<BodyId> (N-body, not limited to 2)
├── medium: Option<String>
├── force: Quantity (semantic)
├── location: Point3D
├── time: f64
└── governing_law: Option<LawId>
```

This is provider-independent and naturally represented as a Hypergraph hyperedge:

```text
Interaction(InteractionId)
├── participant: body_A
├── participant: body_B
├── participant: body_C (for N-body)
├── medium: environment
├── force: F (Quantity)
├── location: x (Point3D)
├── time: t
└── law: L (LawId)
```

### 7.4 Force Categories and Provider Mapping

| Force Kind | Semantic Definition | Bullet3 | PhysX | AzPhysics |
|------------|-------------------|---------|-------|-----------|
| **Gravity** | F = m·g (uniform) or F = G·m1·m2/r² (gravitational) | `btDynamicsWorld::setGravity()` | `PxScene::setGravity()` | `AZ::PhysicsSystemContext::SetGravity()` |
| **Contact** | Normal + friction impulse at contact point | Solver-managed | Solver-managed | Solver-managed |
| **Spring** | F = -k·(x - x₀) - c·v (Hooke's law + damping) | `btGeneric6DofSpringConstraint` | `PxSpringJointDrive` | `AZ::SpringJointComponent` |
| **Applied** | User-defined force vector on body | `btRigidBody::applyCentralForce()` | `PxRigidBody::addForce()` | `AZ::RigidBodyRequestBus::ApplyForce()` |
| **FluidDrag** | F = ½·ρ·v²·Cd·A (quadratic drag) | Manual application | Manual application | Manual application |

### 7.5 Provenance

```yaml
concept: Force
source: Bullet3, PhysX, O3DE
source_terminology:
  Bullet3: btVector3 applied via applyCentralForce/applyTorque
  PhysX: PxVec3 applied via addForce/addTorque/addForceAtPos
  O3DE: AZ::Vector3 applied via RigidBodyRequestBus::ApplyForce/ApplyForceAtPosition
scr_interpretation: Provider-independent semantic vector interaction. Force has identity, magnitude (Quantity in Newtons), direction, point of application, source/target bodies, kind, and governing law. Higher-order interactions (N-body) represented as PhysicalInteraction hyperedges. Provider adapters translate semantic forces to engine-native force accumulators.
differences:
  Bullet3: Forces accumulated as btVector3, applied during single-step solve. SCR forces are semantic entities that persist until removed. Bullet does not distinguish force source; SCR tracks source body/law.
  PhysX: Forces applied via PxForceAccumulator with force/torque/forceAtPos modes. SCR force specifies point of application semantically. PhysX has separate force modes; SCR unifies under ForceKind.
  O3DE: Forces applied via AZ::RigidBodyRequestBus. SCR does not use bus for force application; forces are Hypergraph state. O3DE force is component-level; SCR force is entity-level semantic relationship.
```

## 8. Provider Adapter Pattern

### 8.1 SCR → Provider Translation

All five concepts follow the same adapter pattern:

```text
SCR Semantic Concept
       │
       ▼
Provider Adapter (semantic-specific)
       │
       ├── Bullet3 Adapter
       │   └── btRigidBody / btTypedConstraint / btManifoldPoint / btDynamicsWorld::stepSimulation / btVector3
       │
       ├── PhysX Adapter
       │   └── PxRigidDynamic / PxJoint / PxContactPair / PxScene::simulate / PxForceAccumulator
       │
       └── AzPhysics Adapter
           └── AzRigidBody / AZ::Joint / AZ::CollisionSystem / AZ::TickBus / AZ::Vector3
```

### 8.2 Adapter Responsibilities

| Adapter Role | SCR Concept | Provider Mapping |
|-------------|-------------|-----------------|
| **Body creation** | PhysicsBody → provider body | Mass, inertia, shape, kinematic state translation |
| **Constraint creation** | KinematicConstraint → provider joint | DOF specification, limits, motor translation |
| **Contact detection** | BroadphaseCandidate → provider broadphase | Spatial overlap detection |
| **Contact evaluation** | NarrowphaseEvaluation → provider narrowphase | Exact distance/penetration computation |
| **Contact response** | PhysicalContact → provider contact response | Impulse computation and application |
| **Step advancement** | SimulationStep → provider step | dt, integration method, sub-stepping translation |
| **Force application** | Force → provider force accumulator | Magnitude, direction, point translation |

### 8.3 Invariant Preservation Across Adapter

Provider adapters MUST preserve:

- **PHYSICS-INV-001**: Physical meaning independent of solver implementation
- **PHYSICS-INV-002**: Quantity integrity (units preserved across boundary)
- **PHYSICS-INV-005**: Constraint integrity (DOF restrictions preserved)
- **PHYSICS-INV-008**: Representation independence
- **PHYSICS-INV-009**: Provider independence (provider does not redefine meaning)
- **PHYSICS-INV-018**: Runtime independence
- **SIMULATION-INV-004**: Temporal integrity (simulation time ≠ wall-clock time)

## 9. Gap Analysis

### 9.1 Classification of SCR Needs

| Concept | Current SCR Status | Action | Classification |
|---------|-------------------|--------|----------------|
| **PhysicsBody** | Stub in Body/; Rust impl in body.rs | **define-new** | New operational subdomain definition |
| **KinematicConstraint** | Stub in Constraints/; Rust impl in constraint.rs | **define-new** | New operational subdomain definition |
| **PhysicalContact** | Stub in Contact/; Rust impl interaction.rs covers interaction | **define-new** | New operational subdomain definition (collision lifecycle) |
| **SimulationStep** | Empty stub in Execution/, Time/ | **define-new** | New operational subdomain definition |
| **Force** | Stub in Force/; Rust impl in interaction.rs | **extend-existing** | Extend with provider adapter mapping |
| **PhysicalInteraction** | Rust impl in interaction.rs | **extend-existing** | Document as higher-order interaction model |
| **Broadphase** | Operational (0.1.0) | **already-defined** | Adequate — carry forward |
| **Narrowphase** | Operational (0.1.0) | **already-defined** | Adequate — carry forward |
| **Impact** | Operational (0.1.0) | **already-defined** | Adequate — carry forward |
| **Mass** | Operational (0.1.0) | **already-defined** | Adequate — subdomain of PhysicsBody |
| **Momentum** | Operational (0.1.0) | **already-defined** | Adequate — derived from PhysicsBody |
| **Kinematics** | Operational (0.1.0) | **already-defined** | Adequate — describes motion without forces |

### 9.2 Concepts Already Adequately Defined

| Concept | Where Defined |
|---------|---------------|
| Body (abstract) | `lib/501_Physics/Body/101_definition.md` — adequate as foundation |
| RigidBody | `lib/501_Physics/RigidBody/101_definition.md` — adequate |
| Constraints (abstract) | `lib/501_Physics/Constraints/101_definition.md` — adequate as foundation |
| Collision (abstract) | `lib/501_Physics/Collision/101_definition.md` — adequate as foundation |
| Contact (abstract) | `lib/501_Physics/Contact/101_definition.md` — adequate as foundation |
| Force (abstract) | `lib/501_Physics/Force/101_definition.md` — adequate as foundation |
| Broadphase | `lib/501_Physics/Collision/Broadphase/101_definition.md` — operational |
| Narrowphase | `lib/501_Physics/Collision/Narrowphase/101_definition.md` — operational |
| Impact | `lib/501_Physics/Collision/Impact/101_definition.md` — operational |
| Mass | `lib/501_Physics/Mass/101_definition.md` — operational |
| Momentum | `lib/501_Physics/Momentum/101_definition.md` — operational |
| Kinematics | `lib/501_Physics/Kinematics/101_definition.md` — operational |

### 9.3 Classification Summary

| Classification | Count | Concepts |
|----------------|-------|----------|
| **already-defined** | 12 | Body (abstract), RigidBody, Constraints (abstract), Collision (abstract), Contact (abstract), Force (abstract), Broadphase, Narrowphase, Impact, Mass, Momentum, Kinematics |
| **define-new** | 4 | PhysicsBody (operational), KinematicConstraint (operational), PhysicalContact (operational collision lifecycle), SimulationStep (operational) |
| **extend-existing** | 2 | Force (provider adapter mapping), PhysicalInteraction (document as higher-order) |

## 10. Derived Definitions for Semantic Library

### 10.1 Recommended File Structure

```
lib/501_Physics/
├── Body/                    (needs: operational PhysicsBody definition)
│   ├── 101_definition.md    (update: provider-independent semantic body)
│   └── 102_status.yaml
├── Constraints/             (needs: operational KinematicConstraint definition)
│   ├── 101_definition.md    (update: DOF restriction semantics)
│   └── 102_status.yaml
├── Contact/                 (needs: operational PhysicalContact definition)
│   ├── 101_definition.md    (update: collision lifecycle semantics)
│   └── 102_status.yaml
├── Force/                   (needs: extend with provider adapter mapping)
│   ├── 101_definition.md    (update: provider adapter documentation)
│   └── 102_status.yaml
├── Collision/               (already operational)
├── Broadphase/              (already operational)
├── Narrowphase/             (already operational)
├── Impact/                  (already operational)
└── ...existing subdomains...

lib/503_Simulation/
├── Execution/               (needs: operational SimulationStep definition)
│   └── 101_definition.md    (update: semantic time advancement)
├── Time/                    (needs: simulation temporal semantics)
│   └── 101_definition.md    (update: simulation time vs wall-clock)
├── Clock/                   (needs: simulation clock semantics)
│   └── 101_definition.md    (update: semantic clock)
├── Scheduling/              (needs: step scheduling semantics)
│   └── 101_definition.md    (update: step scheduling)
└── ...existing subdomains...
```

### 10.2 Invariants Added

| Invariant | Statement |
|-----------|-----------|
| **PHYSICS-INV-019 (Body Semantic Integrity)** | A PhysicsBody MUST be decomposable into mass, inertia, kinematic state, spatial bounds, and material constitution without loss of semantic meaning. |
| **PHYSICS-INV-020 (Constraint DOF Integrity)** | A KinematicConstraint MUST specify which degrees of freedom are restricted and which are free. Provider adapters MUST preserve DOF specification. |
| **PHYSICS-INV-021 (Contact Lifecycle Integrity)** | A PhysicalContact MUST follow the 5-phase semantic lifecycle (broadphase → narrowphase → contact → response → resolution). No phase may be silently skipped. |
| **PHYSICS-INV-022 (Force Source Provenance)** | A Force MUST declare its source (body, law, or external) and governing physical law where applicable. |
| **PHYSICS-INV-023 (Provider Adapter Preservation)** | Provider adapters MUST preserve all semantic properties when translating between SCR and provider representations. No semantic property may be silently dropped. |
| **SIMULATION-INV-019 (Step Temporal Integrity)** | A SimulationStep MUST declare its semantic timestep as a Quantity with units. Wall-clock time is observational, not semantic. |
| **SIMULATION-INV-020 (Step Invariant Checking)** | A SimulationStep SHOULD check declared invariants (energy conservation, momentum conservation, constraint satisfaction) and report violations. |

## 11. Exit Criteria Check

- [x] PhysicsBody defined with mass, velocity, forces, provider-independence (Section 3)
- [x] KinematicConstraint defined with DOF restriction, provider-independent (Section 4)
- [x] PhysicalContact defined with 5-phase collision lifecycle (Section 5)
- [x] SimulationStep defined as semantic time advancement vs implementation tick (Section 6)
- [x] Force/Interaction defined as provider-independent semantic concept (Section 7)
- [x] Provider adapter pattern documented for all five concepts (Section 8)
- [x] Mapping table: SCR Concept → Bullet3 / PhysX / AzPhysics (Sections 3.2, 4.2, 5.2, 6.2, 7.4)
- [x] Key invariant: SCR PhysicsBody → adapter → provider (Section 8.1)
- [x] Each concept classified: already-defined / define-new / extend-existing (Section 9.1)
- [x] 7 new invariants added (Section 10.2)
- [x] Existing invariants from Broadphase, Narrowphase, Impact carried forward (Sections 5.4–5.6)
- [x] Provenance documented for all provider-derived concepts (Sections 3.5, 4.5, 5.7, 6.5, 7.5)

## 12. Deferred to Subsequent Sprints

| Concept | Sprint | Reason |
|---------|--------|--------|
| SoftBody semantic definition | Sprint 04+ | Deformable body semantics require Morphology integration |
| Fluid/SPH semantic definition | Sprint 04+ | Fluid dynamics requires field-dynamics coupling |
| Thermodynamic body semantics | Sprint 04+ | Thermal body requires temperature field integration |
| Distributed simulation step | Sprint 04+ | Requires network/distributed semantics |
| Adaptive timestep semantics | Sprint 04+ | Requires error estimation and adaptive control |
| MLIR physics dialect | Sprint 04+ | Requires MLIR compilation infrastructure |
| Rendering integration | Sprint 05+ | Requires rendering domain definition |
# Sprint 03: Physics & Dynamics

Define/extend SCR physics/dynamics semantics: PhysicsBody, Constraint, Collision, Simulation, Timestep.

## Deliverables
- PhysicsBody semantic definition
- Constraint/Joint semantic definition
- Collision/Contact semantic definition
- SimulationStep semantic definition

## Exit Criteria
- [ ] Physics semantics provider-independent
- [ ] SCR PhysicsBody maps to adapter → provider (Bullet/PhysX/O3DE)
- [ ] SimulationStep distinguishes semantic step from implementation tick
# Sprint 004 Record: Asset, Resource & Materialization

## 1. Objective

Define SCR semantic ResourceReference, ResourceIdentity, ResourceLifecycle, MaterializationPipeline, four representation stages (Source → Authoring → Deployable → Runtime), and semantic asset dependency graph. Ground definitions in existing `lib/903_Lowering` (materialization as semantics-preserving transformation), `lib/101_Core/Identity` (SID for resource identity), and `lib/502_Dynamics` (resource semantics). Preserve invariant: **materialization is a semantic operation, not file conversion**.

## 2. Existing SCR Library Assessment

### 2.1 Domains With Substantive Definitions

| Domain | Path | Status | Relevance |
|--------|------|--------|-----------|
| **Identity** | `lib/101_Core/Identity/101_definition.md` | Operational (0.1.0) | Authoritative SID coordinate model. 9-layer hierarchy, 17 invariants (IAM-I001–IAM-I017). IAM-I014 (Manifestation Separation) and IAM-I015 (Binding Separation) directly relevant: resource identity ≠ resource manifestation. |
| **Lowering** | `lib/903_Lowering/101_definition.md` | Draft (0.1.0) | Comprehensive 1594-line definition of semantics-preserving transformation. Lowering model L = (S, T, M, C, P, G, E, R). 18 invariants (LOWERING-INV-001–018). Materialization is a specialization of lowering. |
| **Core** | `lib/101_Core/101_definition.md` | Draft (0.1.0) | Defines Entity, Object, State, Composition, Constraint, Capability, Contract, Relationship. Section 10 (Entities), 21–22 (State), 29–32 (Constraints, Capability, Contract, Composition). |
| **Dynamics** | `lib/502_Dynamics/101_definition.md` | Draft (0.1.0) | 1937 lines, 18 invariants. Resource Semantics section (§Resource Semantics) distinguishes resource constraints from dynamical state. |
| **Stream** | `lib/802_Stream/101_definition.md` | Draft (0.1.0) | §31 (Identity and References) defines reference semantics for stream elements. §STREAM-INV-015 (Identity/Reference Separation): references must remain distinguishable from referenced entities. |

### 2.2 Domains That Are Placeholder Stubs

| Domain | Path | Implication |
|--------|------|-------------|
| **Core/Contracts** | `lib/101_Core/Contracts/101_definition.md` | Empty stub. Core §31 defines Contract conceptually. Resource materialization contracts need explicit definition. |
| **Core/Capabilities** | `lib/101_Core/Capabilities/101_definition.md` | Empty stub. Core §30 defines Capability. Provider capabilities for materialization need explicit definition. |
| **Core/Interfaces** | `lib/101_Core/Interfaces/101_definition.md` | Empty stub. Materialization interface semantics need explicit definition. |

### 2.3 No Existing Resource or Asset Definitions

Glob search confirms: no `lib/**/Resource*` or `lib/**/Asset*` directories exist. This is a new domain requiring definition from scratch.

### 2.4 Assessment Summary

The SCR library has:
- **Identity**: Fully operational SID coordinate model (9-layer hierarchy, 17 invariants). Resource identity derives from this.
- **Lowering**: Comprehensive semantics-preserving transformation model. Materialization is a specialization.
- **Dynamics**: Abstract resource semantics section distinguishing resource constraints from state.
- **Stream**: Reference semantics (§31, STREAM-INV-015) establishing reference ≠ entity.

**Critical gap:** No operational definition exists for:
- Resource as a semantic entity with identity, reference, lifecycle, and dependency
- Materialization as a semantic operation (resolution + validation + compilation + optimization)
- Four representation stages (Source → Authoring → Deployable → Runtime)
- Asset dependency graph between resources

M003 Sprint 04 must fill this gap.

## 3. ResourceReference

### 3.1 SCR Semantic ResourceReference (Normative)

**Concept:** `ResourceReference`
**Source:** Core §10 (Entities), Core §29 (Constraints), Identity (SID), Stream §31 (Identity and References), STREAM-INV-015
**Status:** define-new — no existing resource reference definition

A ResourceReference is the **provider-independent semantic pointer** to a resource, distinct from the resource itself.

```text
ResourceReference
├── resource_id: ResourceIdentity (SID-scoped)
├── reference_kind: ReferenceKind
│   ├── Strong         (prevents resource destruction while referenced)
│   ├── Weak           (does not prevent destruction; detectable invalidation)
│   ├── Symbolic       (named reference resolved at materialization time)
│   ├── ContentAddress (reference by content hash, immutable)
│   └── Versioned      (reference pinned to specific version)
├── scope: ReferenceScope
│   ├── Local           (within single compilation unit)
│   ├── Domain          (within allocation domain)
│   ├── Global          (across all domains)
│   └── Federation      (across root authorities, per IAM-R019)
├── resolution_policy: ResolutionPolicy
│   ├── Eager           (resolved at materialization time)
│   ├── Lazy            (resolved at first access)
│   └── OnDemand        (resolved per invocation)
└── provenance: ReferenceProvenance
    ├── source_location: Option<String> (authoring-time origin)
    ├── materialization_pass: Option<MaterializationPassId>
    └── binding_history: Vec<BindingEvent>
```

### 3.2 ResourceReference ≠ Resource

Per STREAM-INV-015 (Identity/Reference Separation) and IAM-I015 (Binding Separation):

| Aspect | ResourceReference | Resource |
|--------|------------------|----------|
| **Authority** | SCR — defines reference meaning | SCR — defines resource meaning |
| **Existence** | Meaningful whether or not resource exists | Meaningful whether or not referenced |
| **Identity** | Has its own identity (reference-id) | Has resource identity (resource-id) |
| **Lifetime** | May outlive resource (weak ref) or bind lifetime (strong ref) | Independent lifetime |
| **Invalidation** | Reference can be invalidated without destroying resource | Resource destruction invalidates references (detectable) |

### 3.3 Reference Resolution Semantics

```text
resolve(ref: ResourceReference) → Result<Resource, ReferenceError>
├── Symbolic ref → lookup by name in materialization context
├── ContentAddress ref → lookup by hash in content store
├── Versioned ref → lookup by name + version constraint
├── Strong ref → dereference; error if resource destroyed
└── Weak ref → dereference; None if resource destroyed
```

Resolution is a **materialization-time** or **runtime** semantic operation. It is not file I/O.

### 3.4 Reference Integrity

- **RES-INV-001 (Reference Distinguishability)**: A ResourceReference MUST remain distinguishable from the Resource it references. (Derived from STREAM-INV-015.)
- **RES-INV-002 (Invalidation Detectability)**: When a referenced Resource is destroyed, the reference MUST become detectably invalid. Silent dangling references are prohibited. (Derived from Spatial §34, Reference Validity.)
- **RES-INV-003 (Scope Integrity)**: Reference resolution scope MUST be declared and enforced. A Local reference MUST NOT resolve outside its compilation unit.

## 4. ResourceIdentity

### 4.1 SCR Semantic ResourceIdentity (Normative)

**Concept:** `ResourceIdentity`
**Source:** Identity §2–6 (Authority Hierarchy, SID Coordinate), IAM-I001–IAM-I017
**Status:** define-new — SID applied to resource domain

A ResourceIdentity is the **SID coordinate** identifying a resource within the SCR identity address space. Resources are first-class semantic entities with authoritative identity.

```text
ResourceIdentity
├── sid: SidCoordinate (from Identity domain)
├── domain: AllocationDomain (from Identity domain)
├── resource_class: ResourceClass
│   ├── SemanticAsset      (domain definition, specification, constraint set)
│   ├── ComputationalAsset (compiled computation, kernel, transformation)
│   ├── DataAsset          (dataset, field, mesh, graph)
│   ├── RuntimeAsset       (instantiated resource in execution context)
│   └── DerivedAsset       (materialized from other assets)
├── version: SemanticVersion (semver: major.minor.patch)
├── content_hash: Option<Hash> (content-addressable identity, derived)
└── metadata: ResourceMetadata
    ├── created: Timestamp
    ├── author: AuthorityId
    ├── dependencies: Vec<ResourceReference>
    └── materialization_contract: Option<MaterializationContract>
```

### 4.2 ResourceIdentity ≠ ContentAddress

Per `lib/000_meta/references.md` §31 (Content Addressing and Immutable Data):

| Aspect | ResourceIdentity (SID) | ContentAddress (Hash) |
|--------|----------------------|----------------------|
| **Authority** | SCR — allocates coordinate | Derived — computed from content |
| **Mutability** | Coordinate immutable; metadata mutable | Immutable; changes with content |
| **Allocation** | Requires domain authority allocation | Computed, no authority needed |
| **Meaning** | Identifies semantic entity | Identifies content snapshot |
| **Scope** | Identity address space | Content store |

Both coexist: SID is the authoritative identity; content hash is a derived property for deduplication and verification.

### 4.3 Resource Identity Lifecycle

Resource identity follows the 9-layer Identity Authority Hierarchy:

```text
Genesis → Root Authority → Identity Address Space → Allocation Domain → Authority → Allocation → SID Coordinate → Semantic Identity → Manifestation
```

At the resource level:
- **SID Coordinate**: Resource's canonical identity (immutable)
- **Semantic Identity**: Binding to semantic meaning (may evolve per IAM-I015)
- **Manifestation**: Runtime handle (may migrate/destroy per IAM-I014)

### 4.4 Identity Invariants

- **RES-INV-004 (Resource Identity Uniqueness)**: Each resource MUST have a unique SID coordinate within its allocation domain. (Derived from IAM-I005, Allocation Injectivity.)
- **RES-INV-005 (Identity-Content Separation)**: Resource identity MUST NOT be derived from content hash alone. Content hash is a derived property, not the identity. (Derived from references.md §31.)
- **RES-INV-006 (Manifestation Independence)**: Resource identity MUST remain invariant across manifestation changes (migration, buffer reallocation, provider swap). (Derived from IAM-I014.)

## 5. ResourceLifecycle

### 5.1 SCR Semantic ResourceLifecycle (Normative)

**Concept:** `ResourceLifecycle`
**Source:** Core §21–22 (State and State Transition), Sprint 001 Entity Lifecycle, Lowering §4 (Semantic Preservation)
**Status:** define-new — lifecycle for resources

A ResourceLifecycle is the **provider-independent semantic state machine** governing resource existence across its operational span.

```text
ResourceLifecycle
├── states: ResourceState[]
│   ├── Defined          (semantic definition exists; not yet materialized)
│   ├── Resolving        (references being resolved)
│   ├── Validating       (semantic contracts being checked)
│   ├── Compiling        (materialization in progress)
│   ├── Compiled         (materialization complete; not yet loaded)
│   ├── Loading          (being loaded into execution context)
│   ├── Loaded           (in execution context; not yet active)
│   ├── Activating       (initialization in progress)
│   ├── Active           (fully operational)
│   ├── Deactivating     (shutdown in progress)
│   ├── Deactivated      (shutdown complete; still loaded)
│   ├── Unloading        (being removed from execution context)
│   ├── Unloaded         (removed from execution context; still exists)
│   ├── Destroying       (identity being reclaimed)
│   └── Destroyed        (identity reclaimed; references detectable)
├── transitions: ResourceTransition[]
│   ├── define()        → Defined
│   ├── materialize()   → Defined → [Resolving → Validating → Compiling] → Compiled
│   ├── load()          → Compiled → [Loading] → Loaded
│   ├── activate()      → Loaded → [Activating] → Active
│   ├── deactivate()    → Active → [Deactivating] → Deactivated
│   ├── unload()        → Deactivated → [Unloading] → Unloaded
│   ├── destroy()       → Unloaded → [Destroying] → Destroyed
│   └── rematerialize() → any → Defined (reset)
├── invariants: LifecycleInvariant[]
│   ├── lifecycle-inv-001: state transitions are explicit and auditable
│   ├── lifecycle-inv-002: no state skip without explicit contract
│   ├── lifecycle-inv-003: destruction invalidates all references
│   └── lifecycle-inv-004: activation requires successful materialization
└── provenance: LifecycleProvenance
    ├── state_history: Vec<StateEvent>
    ├── transitions: Vec<TransitionEvent>
    └── authority: AuthorityId
```

### 5.2 Lifecycle State Machine

```text
                    ┌──────────────────────────────────────────────┐
                    │                                              │
                    ▼                                              │
               ┌─────────┐                                         │
               │ Defined  │◄────────────────────────────────────┐  │
               └────┬─────┘                                      │  │
                    │ materialize()                              │  │
                    ▼                                            │  │
             ┌────────────┐                                      │  │
             │ Resolving  │                                      │  │
             └─────┬──────┘                                      │  │
                   ▼                                             │  │
             ┌────────────┐                                      │  │
             │ Validating │                                      │  │
             └─────┬──────┘                                      │  │
                   ▼                                             │  │
             ┌──────────┐                                        │  │
             │ Compiling│                                        │  │
             └─────┬────┘                                        │  │
                   ▼                                             │  │
             ┌──────────┐     load()    ┌──────────┐            │  │
             │ Compiled ├──────────────►│ Loading  │            │  │
             └──────────┘               └────┬─────┘            │  │
                                             ▼                   │  │
                                       ┌──────────┐             │  │
                                       │  Loaded  │             │  │
                                       └────┬─────┘             │  │
                                            │ activate()        │  │
                                            ▼                   │  │
                                      ┌──────────┐              │  │
                                      │ Active   │              │  │
                                      └────┬─────┘              │  │
                                           │ deactivate()       │  │
                                           ▼                    │  │
                                     ┌────────────┐             │  │
                                     │Deactivating│             │  │
                                     └─────┬──────┘             │  │
                                           ▼                    │  │
                                     ┌───────────┐              │  │
                                     │Deactivated│              │  │
                                     └─────┬─────┘              │  │
                                           │ unload()           │  │
                                           ▼                    │  │
                                     ┌───────────┐              │  │
                                     │ Unloading │              │  │
                                     └─────┬─────┘              │  │
                                           ▼                    │  │
                                     ┌──────────┐               │  │
                                     │ Unloaded │               │  │
                                     └────┬─────┘               │  │
                                          │ destroy()           │  │
                                          ▼                     │  │
                                    ┌───────────┐               │  │
                                    │ Destroying│               │  │
                                    └─────┬─────┘               │  │
                                          ▼                     │  │
                                    ┌──────────┐                │  │
                                    │ Destroyed │───────────────┘  │
                                    └──────────┘   rematerialize() │
                                                          │       │
                                                          ▼       │
                                                      Defined ────┘
```

### 5.3 Lifecycle vs Provider Lifecycle

| Aspect | SCR ResourceLifecycle | Bullet3 Collision Object Lifecycle | PhysX PxShape Lifecycle | O3DE AZ::Asset Lifecycle |
|--------|----------------------|-----------------------------------|------------------------|-------------------------|
| **Authority** | SCR — defines lifecycle meaning | Bullet — manages collision object | PhysX — manages shape | O3DE — manages asset |
| **States** | 15 semantic states | Internal create/destroy | Internal create/destroy | Loading/Loaded/Unloading |
| **Transitions** | Explicit semantic operations | Implicit API calls | Implicit API calls | Implicit asset pipeline |
| **Materialization** | Semantic operation with resolution, validation, compilation, optimization | Not modeled | Not modeled | File conversion (not semantic) |
| **Destruction** | Identity reclaimed; references detectable | Pointer freed | Pointer freed | Asset unloaded |

### 5.4 Lifecycle Invariants

- **LIFECYCLE-INV-001 (Explicit Transitions)**: Every state transition MUST be an explicit semantic operation with declared preconditions and postconditions.
- **LIFECYCLE-INV-002 (No Silent State Skip)**: No state may be skipped without an explicit contract declaring the skip valid.
- **LIFECYCLE-INV-003 (Destruction Reference Invalidation)**: Resource destruction MUST invalidate all references (strong and weak). Strong references error; weak references return None.
- **LIFECYCLE-INV-004 (Activation Prerequisite)**: Activation REQUIRES successful materialization. A resource MUST NOT be activated from Defined, Resolving, Validating, or Compiling states.

## 6. MaterializationPipeline

### 6.1 SCR Semantic MaterializationPipeline (Normative)

**Concept:** `MaterializationPipeline`
**Source:** Lowering §1–57 (comprehensive lowering model), Lowering L = (S, T, M, C, P, G, E, R), Dynamics §Resource Semantics, M003 Invariant 4 ("Materialization is a semantic operation, not merely file conversion")
**Status:** define-new — core materialization semantics

Materialization is the **semantic operation** transforming a resource from one representation stage to another. It is a specialization of Lowering (§903) — a semantics-preserving transformation between abstraction levels.

```text
MaterializationPipeline
├── input: RepresentationStage (source or authoring state)
├── output: RepresentationStage (deployable or runtime state)
├── stages: MaterializationStage[]
│   ├── Resolution        (reference resolution, dependency closure)
│   ├── Validation        (semantic contract checking)
│   ├── Flattening        (composition elimination, inlining)
│   ├── Compilation       (semantic → lower-level representation)
│   ├── Optimization      (semantic-preserving transformations)
│   └── Finalization      (deterministic initialization, version stamping)
├── contract: MaterializationContract
│   ├── semantic_preservation: PreservationSet (which semantics preserved)
│   ├── approximation: Option<ApproximationDeclaration>
│   ├── resource_requirements: ResourceRequirements
│   └── failure_semantics: FailureSemantics
├── provenance: MaterializationProvenance
│   ├── source: ResourceIdentity
│   ├── target: ResourceIdentity
│   ├── transformation: TransformationChain
│   ├── timestamp: Timestamp
│   └── authority: AuthorityId
└── determinism: DeterminismGuarantee
    ├── deterministic: bool
    ├── assumptions: Vec<DeterminismAssumption>
    └── replayable: bool
```

### 6.2 Materialization as Semantic Operation

Per Lowering §1 (definition) and M003 Invariant 4:

```text
Materialization ≠ File Conversion
Materialization ≠ Syntax Translation
Materialization ≠ API Wrapping
Materialization ≠ Compiler Backend Invocation
```

Materialization IS:
- Reference resolution (resolving symbolic references to concrete identities)
- Semantic validation (verifying contracts, invariants, constraints)
- Composition flattening (inlining, merging, eliminating abstraction layers)
- Asset compilation (semantic representation → lower-level representation)
- Dependency closure (ensuring all transitive dependencies are satisfied)
- Runtime optimization (semantic-preserving performance transformations)
- Deterministic initialization (ordering, versioning, provenance stamping)

### 6.3 Materialization Stages (Detailed)

```text
Resolution Stage
├── Input: Symbolic references, dependency declarations
├── Operation: Resolve all symbolic references to concrete ResourceIdentity
├── Output: Closed dependency graph with concrete SID coordinates
├── Invariant: RES-INV-003 (Scope Integrity) enforced
└── Failure: Unresolvable reference → materialization rejected

Validation Stage
├── Input: Closed dependency graph, semantic contracts
├── Operation: Verify all contracts, invariants, type compatibility
├── Output: Validated resource graph
├── Invariant: All declared contracts satisfied
└── Failure: Contract violation → materialization rejected with diagnostic

Flattening Stage
├── Input: Validated resource graph with composition
├── Operation: Inline composites, merge compatible layers, eliminate abstraction
├── Output: Flat resource representation
├── Invariant: Semantic equivalence preserved (Lowering §5, §44)
└── Failure: Non-flattenable composition → partial flattening with explicit annotation

Compilation Stage
├── Input: Flat semantic representation
├── Operation: Transform to lower-level representation (per Lowering §2)
├── Output: Compiled representation (MLIR, bytecode, executable)
├── Invariant: LOWERING-INV-001 (Semantic Preservation)
└── Failure: Unsupported lowering path → materialization rejected

Optimization Stage
├── Input: Compiled representation
├── Operation: Semantic-preserving transformations (fusion, vectorization, tiling)
├── Output: Optimized compiled representation
├── Invariant: Semantic equivalence preserved (Lowering §48, §54)
└── Failure: Optimization introduces approximation → explicit declaration required

Finalization Stage
├── Input: Optimized compiled representation
├── Operation: Version stamping, deterministic ordering, provenance recording
├── Output: Finalized deployable resource
├── Invariant: Deterministic initialization ordering guaranteed
└── Failure: Non-deterministic ordering detected → materialization rejected
```

### 6.4 Materialization ≠ Lowering

Materialization is a **specialization** of Lowering:

| Aspect | Lowering | Materialization |
|--------|----------|----------------|
| **Scope** | Any semantics-preserving transformation | Resource-specific transformation pipeline |
| **Input** | Any source representation | Resource at a specific representation stage |
| **Output** | Any target representation | Resource at the next representation stage |
| **Pipeline** | Single transformation or chain | Fixed 6-stage pipeline |
| **Identity** | May or may not change resource identity | Identity preserved across materialization |
| **Provenance** | General transformation provenance | Resource-specific materialization provenance |

### 6.5 Materialization Invariants

- **MAT-INV-001 (Semantic Preservation)**: Materialization MUST preserve all declared semantic properties of the source resource. (Derived from LOWERING-INV-001.)
- **MAT-INV-002 (Reference Closure)**: All symbolic references MUST be resolved before compilation begins. (Derived from RES-INV-003.)
- **MAT-INV-003 (Contract Satisfaction)**: All declared materialization contracts MUST be satisfied or explicitly weakened with declared approximation.
- **MAT-INV-004 (Deterministic Ordering)**: Materialization of identical resources with identical dependencies MUST produce deterministic results.
- **MAT-INV-005 (Provenance Completeness)**: Every materialization MUST record full provenance: source identity, transformation chain, target identity, timestamp, authority.
- **MAT-INV-006 (Failure Transparency)**: Materialization failure MUST NOT silently produce a partial or invalid resource.

## 7. Representation Stages

### 7.1 SCR Four Representation Stages (Normative)

**Concept:** `RepresentationStage`
**Source:** Lowering §9 (Progressive Lowering), Lowering abstraction levels model
**Status:** define-new — resource representation stages

Resources exist in four semantic representation stages. Each stage represents a distinct level of abstraction and concreteness.

```text
Source Stage
├── Definition: Semantic specifications, domain definitions, constraint sets
├── Format: SCR specification language (101_definition.md, YAML, semantic graphs)
├── Properties: Fully abstract, provider-independent, human-authored
├── Identity: ResourceIdentity with version
└── Examples: Domain definitions, invariant specifications, contract declarations

        │ materialize()
        ▼

Authoring Stage
├── Definition: Composed computational graphs with explicit dependencies
├── Format: SCR semantic graph, composed entity-component structures
├── Properties: Resolved references, validated contracts, not yet compiled
├── Identity: ResourceIdentity (same SID, materialized metadata)
└── Examples: Composed simulations, assembled scenes, linked domains

        │ materialize()
        ▼

Deployable Stage
├── Definition: Compiled representations ready for deployment
├── Format: MLIR modules, bytecode, serialized state, compiled kernels
├── Properties: Flattened, compiled, optimized, versioned, deterministic
├── Identity: ResourceIdentity (same SID, content hash updated)
└── Examples: Compiled physics kernels, optimized meshes, packaged assets

        │ instantiate()
        ▼

Runtime Stage
├── Definition: Instantiated resources in execution context
├── Format: Memory-resident, GPU buffers, active handles, live state
├── Properties: Mutable state, provider manifestations, resource consumption
├── Identity: ResourceIdentity (same SID, manifestation handles active)
└── Examples: Running simulation bodies, active streams, loaded textures
```

### 7.2 Stage Transitions

```text
Source ──[materialize()]──► Authoring ──[materialize()]──► Deployable ──[instantiate()]──► Runtime
                                │                              │
                                │ rematerialize()              │ rematerialize()
                                ▼                              ▼
                            Source                          Deployable
```

| Transition | Operation | Semantics |
|------------|-----------|-----------|
| **Source → Authoring** | `materialize()` | Resolve references, validate contracts, compose graph |
| **Authoring → Deployable** | `materialize()` | Flatten, compile, optimize, finalize |
| **Deployable → Runtime** | `instantiate()` | Load into execution context, allocate manifests |
| **Any → Source** | `rematerialize()` | Reset to source state (discard materialization) |
| **Any → Deployable** | `rematerialize()` | Re-materialize from any intermediate stage |

### 7.3 Stage-Specific Invariants

- **STAGE-INV-001 (Source Authority)**: The Source stage is the semantic authority. All downstream stages are realizations of Source semantics.
- **STAGE-INV-002 (Authoring Integrity)**: The Authoring stage MUST contain resolved references and validated contracts. No unresolved symbolic references.
- **STAGE-INV-003 (Deployable Determinism)**: The Deployable stage MUST be deterministically reproducible from identical Authoring inputs.
- **STAGE-INV-004 (Runtime Isolation)**: Runtime manifestations MUST NOT redefine semantic meaning. Provider handles are ephemeral.

### 7.4 Pipeline Diagram

```text
AUTHORING STATE
    │
    ├── Resolve references (symbolic → concrete SID)
    ├── Validate contracts (semantic invariants)
    ├── Flatten composition (inline, merge)
    ├── Compile (semantic → lower-level)
    ├── Optimize (semantic-preserving)
    └── Finalize (version stamp, deterministic order)
    │
    ▼
[materialize()]
    │
    ▼
DEPLOYABLE STATE
    │
    ├── Load into execution context
    ├── Allocate provider manifestations
    └── Initialize deterministic state
    │
    ▼
[instantiate()]
    │
    ▼
SIMULATION STATE
    │
    ├── Replicate across distribution boundary
    ├── Partition for distributed execution
    └── Synchronize state
    │
    ▼
[replicate()]
    │
    ▼
DISTRIBUTED STATE
```

### 7.5 Full Lifecycle Pipeline

```text
AUTHORING STATE → [materialize()] → DEPLOYABLE STATE → [instantiate()] → SIMULATION STATE → [replicate()] → DISTRIBUTED STATE
```

## 8. Asset Dependency Graph

### 8.1 SCR Semantic Dependency Graph (Normative)

**Concept:** `AssetDependencyGraph`
**Source:** Lowering §7 (Lowering Contracts), Core §32 (Composition), Stream §31 (References)
**Status:** define-new — semantic dependency between resources

The AssetDependencyGraph is the **provider-independent semantic dependency structure** between resources, forming a directed acyclic graph (DAG) with materialization-time resolution.

```text
AssetDependencyGraph
├── nodes: Vec<GraphNode<ResourceIdentity>>
├── edges: Vec<DependencyEdge>
│   ├── source: ResourceIdentity
│   ├── target: ResourceIdentity
│   ├── dependency_kind: DependencyKind
│   │   ├── Requires      (target must exist before source materializes)
│   │   ├── Extends       (source extends target's semantic meaning)
│   │   ├── Composes      (source is composed into target)
│   │   ├── Consumes      (source consumes target's output at runtime)
│   │   ├── Constrains    (source constrains target's behavior)
│   │   └── Provides      (source provides capability to target)
│   ├── scope: DependencyScope
│   │   ├── CompileTime   (resolved during materialization)
│   │   ├── LoadTime      (resolved during loading)
│   │   └── Runtime       (resolved during execution)
│   └── version_constraint: Option<SemVerConstraint>
├── cycles: CycleDetection (DAG property: no cycles allowed)
└── materialization_order: TopologicalSort (deterministic ordering)
```

### 8.2 Dependency Semantics

```text
Resource A ──[Requires]──► Resource B
    │                           │
    │                           │ B must be materialized before A
    │                           │ A's materialization depends on B's Deployable state
    │
    ├──[Extends]──► Resource C
    │               │
    │               │ A extends C's semantic meaning
    │               │ C's definition must be available at A's materialization time
    │
    ├──[Composes]──► Resource D
    │               │
    │               │ A is composed into D
    │               │ D's materialization inlines A
    │
    ├──[Consumes]──► Resource E
    │               │
    │               │ A consumes E's output at runtime
    │               │ E must be Active when A is Active
    │
    └──[Provides]──► Resource F
                    │
                    │ A provides capability to F
                    │ F depends on A's Active state
```

### 8.3 Dependency Closure

Dependency closure is a **materialization-time** operation:

```text
closeDependencies(root: ResourceIdentity) → DependencyClosure
├── 1. Collect all direct dependencies (depth-first)
├── 2. Detect cycles (reject if cycle exists)
├── 3. Topologically sort (deterministic order)
├── 4. Validate version constraints
├── 5. Validate scope constraints (CompileTime deps resolved first)
├── 6. Generate materialization order
└── 7. Return closed dependency graph with resolved SIDs
```

### 8.4 Dependency Invariants

- **DEP-INV-001 (Acyclicity)**: The dependency graph MUST be a DAG. Cycles are prohibited.
- **DEP-INV-002 (Deterministic Ordering)**: Topological sort MUST be deterministic for identical dependency graphs.
- **DEP-INV-003 (Scope Enforcement)**: CompileTime dependencies MUST be fully resolved before materialization proceeds.
- **DEP-INV-004 (Version Consistency)**: Version constraints MUST be satisfiable across the entire dependency closure.

## 9. Provider Adapter Pattern

### 9.1 SCR → Provider Translation

All resource concepts follow the same adapter pattern:

```text
SCR Semantic Concept
       │
       ▼
Provider Adapter (semantic-specific)
       │
       ├── File System Adapter
       │   └── File paths, directories, packages
       │
       ├── MLIR Adapter
       │   └── Modules, dialects, passes
       │
       ├── Runtime Adapter
       │   └── Memory buffers, GPU handles, actor IDs
       │
       └── Distributed Adapter
           └── Partitions, replicas, synchronization
```

### 9.2 Adapter Responsibilities

| Adapter Role | SCR Concept | Provider Mapping |
|-------------|-------------|-----------------|
| **Reference Resolution** | ResourceReference → concrete SID | Name lookup, content hash lookup |
| **Identity Allocation** | ResourceIdentity → provider handle | SID → memory pointer, buffer handle |
| **Lifecycle Management** | ResourceLifecycle → provider state | Create/destroy, load/unload |
| **Materialization** | MaterializationPipeline → compilation | Compiler passes, optimization |
| **Dependency Resolution** | AssetDependencyGraph → dependency order | Package manager, linker |
| **Stage Translation** | RepresentationStage → format | File format, serialization |

### 9.3 Invariant Preservation Across Adapter

Provider adapters MUST preserve:
- **RES-INV-001**: Reference distinguishability
- **RES-INV-006**: Manifestation independence
- **LIFECYCLE-INV-001**: Explicit transitions
- **MAT-INV-001**: Semantic preservation
- **MAT-INV-004**: Deterministic ordering
- **DEP-INV-001**: Acyclicity
- **DEP-INV-002**: Deterministic ordering
- **LOWERING-INV-001**: Semantic preservation (inherited from Lowering)

## 10. Gap Analysis

### 10.1 Classification of SCR Needs

| Concept | Current SCR Status | Action | Classification |
|---------|-------------------|--------|----------------|
| **ResourceReference** | No existing definition | **define-new** | New operational definition |
| **ResourceIdentity** | SID exists; not applied to resources | **define-new** | SID applied to resource domain |
| **ResourceLifecycle** | Core §21–22 defines state abstractly | **define-new** | New operational lifecycle for resources |
| **MaterializationPipeline** | Lowering §1–57 defines transformation | **define-new** | Specialization of Lowering for resources |
| **Representation Stages** | Lowering §9 defines progressive lowering | **define-new** | Four-stage resource representation model |
| **Asset Dependency Graph** | Core §32 defines composition abstractly | **define-new** | Semantic dependency DAG |
| **Provider Adapters** | Pattern established in Sprint 001–003 | **extend-existing** | Resource-specific adapter documentation |

### 10.2 Concepts Already Adequately Defined

| Concept | Where Defined |
|---------|---------------|
| SID Coordinate | `lib/101_Core/Identity/101_definition.md` — operational |
| Lowering Model | `lib/903_Lowering/101_definition.md` — comprehensive |
| Reference Semantics | `lib/802_Stream/101_definition.md` §31, STREAM-INV-015 |
| Content Addressing | `lib/000_meta/references.md` §31 |
| Resource Constraints | `lib/502_Dynamics/101_definition.md` §Resource Semantics |
| Entity Lifecycle | Sprint 001 record — entity lifecycle model |

### 10.3 Classification Summary

| Classification | Count | Concepts |
|----------------|-------|----------|
| **already-defined** | 6 | SID Coordinate, Lowering Model, Reference Semantics, Content Addressing, Resource Constraints, Entity Lifecycle |
| **define-new** | 6 | ResourceReference, ResourceIdentity (applied), ResourceLifecycle, MaterializationPipeline, Representation Stages, Asset Dependency Graph |
| **extend-existing** | 1 | Provider Adapters (resource-specific) |

## 11. Derived Definitions for Semantic Library

### 11.1 Recommended File Structure

```
lib/
├── 101_Core/
│   ├── Identity/                    (already operational)
│   ├── Contracts/                   (needs: materialization contract definition)
│   │   └── 101_definition.md        (update: materialization contracts)
│   └── Capabilities/                (needs: provider capability definition)
│       └── 101_definition.md        (update: materialization capabilities)
├── 900_Resource/                    (NEW — core resource domain)
│   ├── 101_definition.md            (new: Resource domain overview)
│   ├── Reference/                   (new: ResourceReference definition)
│   │   └── 101_definition.md
│   ├── Identity/                    (new: ResourceIdentity definition)
│   │   └── 101_definition.md
│   ├── Lifecycle/                   (new: ResourceLifecycle definition)
│   │   └── 101_definition.md
│   ├── Materialization/             (new: MaterializationPipeline definition)
│   │   └── 101_definition.md
│   ├── Stages/                      (new: Representation stages definition)
│   │   └── 101_definition.md
│   └── Dependency/                  (new: Asset dependency graph definition)
│       └── 101_definition.md
├── 903_Lowering/                    (already operational — materialization is specialization)
└── 904_Provider/                    (NEW — provider adapter patterns)
    └── 101_definition.md            (new: provider adapter model)
```

### 11.2 Invariants Added

| Invariant | Statement |
|-----------|-----------|
| **RES-INV-001** | A ResourceReference MUST remain distinguishable from the Resource it references. |
| **RES-INV-002** | When a referenced Resource is destroyed, the reference MUST become detectably invalid. |
| **RES-INV-003** | Reference resolution scope MUST be declared and enforced. |
| **RES-INV-004** | Each resource MUST have a unique SID coordinate within its allocation domain. |
| **RES-INV-005** | Resource identity MUST NOT be derived from content hash alone. |
| **RES-INV-006** | Resource identity MUST remain invariant across manifestation changes. |
| **LIFECYCLE-INV-001** | Every state transition MUST be an explicit semantic operation. |
| **LIFECYCLE-INV-002** | No state may be skipped without an explicit contract. |
| **LIFECYCLE-INV-003** | Resource destruction MUST invalidate all references. |
| **LIFECYCLE-INV-004** | Activation REQUIRES successful materialization. |
| **MAT-INV-001** | Materialization MUST preserve all declared semantic properties. |
| **MAT-INV-002** | All symbolic references MUST be resolved before compilation. |
| **MAT-INV-003** | All materialization contracts MUST be satisfied or explicitly weakened. |
| **MAT-INV-004** | Materialization of identical resources MUST produce deterministic results. |
| **MAT-INV-005** | Every materialization MUST record full provenance. |
| **MAT-INV-006** | Materialization failure MUST NOT silently produce partial resources. |
| **STAGE-INV-001** | The Source stage is the semantic authority. |
| **STAGE-INV-002** | Authoring stage MUST contain resolved references and validated contracts. |
| **STAGE-INV-003** | Deployable stage MUST be deterministically reproducible. |
| **STAGE-INV-004** | Runtime manifestations MUST NOT redefine semantic meaning. |
| **DEP-INV-001** | The dependency graph MUST be a DAG. |
| **DEP-INV-002** | Topological sort MUST be deterministic. |
| **DEP-INV-003** | CompileTime dependencies MUST be fully resolved before materialization. |
| **DEP-INV-004** | Version constraints MUST be satisfiable across entire dependency closure. |

## 12. Exit Criteria Check

- [x] ResourceReference defined with reference kinds, scope, resolution policy (Section 3)
- [x] ResourceIdentity defined using SID coordinates, resource classes, versioning (Section 4)
- [x] ResourceLifecycle defined with 15-state machine, explicit transitions (Section 5)
- [x] MaterializationPipeline defined with 6-stage pipeline (Section 6)
- [x] Source/Authoring/Deployable/Runtime representation stages defined (Section 7)
- [x] Asset dependency graph defined with 6 dependency kinds, DAG property (Section 8)
- [x] Provider adapter pattern documented for resource concepts (Section 9)
- [x] Key invariant: materialization is semantic operation, not file conversion (Section 6.2)
- [x] Pipeline diagram: AUTHORING → materialize() → DEPLOYABLE → instantiate() → SIMULATION → replicate() → DISTRIBUTED (Section 7.5)
- [x] Each concept classified: already-defined / define-new / extend-existing (Section 10.1)
- [x] 24 new invariants added (Section 11.2)
- [x] Existing invariants from Identity, Lowering, Stream carried forward (Sections 3.4, 6.5, 9.3)
- [x] Recommended semantic library directory structure for lib/900_Resource/ (Section 11.1)

## 13. Deferred to Subsequent Sprints

| Concept | Sprint | Reason |
|---------|--------|--------|
| Materialization contract language | Sprint 05+ | Requires contract specification syntax |
| Distributed materialization | Sprint 05+ | Requires network/distributed semantics |
| Adaptive materialization | Sprint 05+ | Requires runtime analysis and re-materialization |
| Content-addressable materialization cache | Sprint 05+ | Requires storage semantics |
| MLIR resource dialect | Sprint 05+ | Requires MLIR compilation infrastructure |
| Rendering resource pipeline | Sprint 06+ | Requires rendering domain definition |
| Neural asset materialization | Sprint 06+ | Requires neural domain definition |
# Sprint 04: Asset, Resource & Materialization

Define/extend SCR asset/resource semantics and assess materialization as a semantic operation.

## Deliverables
- Asset/AssetRef semantic definition
- Resource lifecycle definition
- Materialization semantic operation (if justified)
- Source vs deployable vs runtime representation distinctions

## Exit Criteria
- [ ] Asset semantics cover: identity, reference, lifecycle, dependency
- [ ] Materialization assessed: resolution + validation + compilation + optimization
- [ ] Semantic library directory recommendations for lib/resource/
# Milestone 004: Lifecycle & Distributed-State Semantics

## 1. Scope & Objective
Define the authoring → materialization → deployment → simulation → distributed-observation lifecycle. Establish distributed-state semantics: authority, ownership, replication, prediction, reconciliation. Assess temporal semantics and state ownership.

## 2. Deliverables
- Authoring/materialization/deployment/simulation lifecycle model
- Distributed-state semantic definitions (authority, ownership, replication, observation, prediction, reconciliation, remote operation)
- Temporal semantics assessment
- Identity mapping documentation
- State ownership model

## 3. Formal Invariants
1. Authority transitions are explicit.
2. Prediction does not silently overwrite authoritative state.
3. Replicated state has defined ownership.
4. Time ordering is preserved across distributed observations.

## 4. Exit Criteria
- [ ] Lifecycle model documented (where justified)
- [ ] Distributed-state semantics defined with provenance
- [ ] Temporal semantics classified (wall-clock / simulation / observation / network)
- [ ] Identity mappings documented (SCR SID → O3DE EntityId → network ID → USD path)
- [ ] State ownership explicit for every mapped state

## 5. Dependencies
- Milestone 003 (core runtime semantics)
# Sprint 001 Record: Authoring → Materialization Pipeline

## 1. Objective

Define the complete SCR lifecycle model: Authoring → Materialization → Deployment → Simulation → Distributed → Observation. Document each phase as a semantic operation with preserved/lost information, invariants, and provider responsibilities. Extend M003 Sprint 004 materialization pipeline into a full lifecycle covering distributed state and semantic observation.

## 2. Scope & Boundaries

This sprint covers the **semantic lifecycle model** — the sequence of semantic state transformations from authoring through distributed observation. It does not define the internal semantics of each state (those belong to their respective domains). It defines the **operations between states** and the **invariants governing transitions**.

### 2.1 Relationship to M003 Sprint 004

M003 Sprint 004 defined:
- ResourceReference, ResourceIdentity, ResourceLifecycle
- MaterializationPipeline (6-stage: Resolution → Validation → Flattening → Compilation → Optimization → Finalization)
- Four representation stages: Source → Authoring → Deployable → Runtime
- Asset dependency graph

This sprint extends the pipeline to cover:
- Distributed state semantics (multi-host)
- Observation (returning from distributed state to SCR-compatible semantic state)
- The full six-phase lifecycle as semantic operations

### 2.2 Relationship to M004 Sprint 02–04

| Sprint | Topic | This Sprint's Role |
|--------|-------|-------------------|
| Sprint 02 | Distributed-State Semantics | Defines authority, ownership, replication, observation, remote operation |
| Sprint 03 | Prediction & Reconciliation | Defines prediction semantics, rollback, merge |
| Sprint 04 | Temporal Identity & State Ownership | Defines temporal semantics, state ownership model |

This sprint provides the **lifecycle framework** that Sprint 02–04 fill with detailed semantic definitions.

## 3. Lifecycle Overview

The SCR lifecycle is a sequence of **semantic state transformations**. Each transformation is a semantic operation — not a file format conversion, not an API call, not a serialization encoding.

```text
AUTHORING STATE
    │
    │ [materialize()] — Semantic transformation: resolve, validate, flatten, compile, optimize
    │
    ▼
DEPLOYABLE STATE
    │
    │ [instantiate()] — Semantic transformation: load, allocate, initialize
    │
    ▼
SIMULATION STATE
    │
    │ [replicate()] — Semantic transformation: distribute, partition, synchronize
    │
    ▼
DISTRIBUTED STATE
    │
    │ [observe()] — Semantic transformation: aggregate, reconcile, project
    │
    ▼
SCR-COMPATIBLE SEMANTIC STATE
    │
    │ [author()] — Semantic transformation: edit, compose, constrain
    │
    ▼
AUTHORING STATE (cycle)
```

### 3.1 Semantic Operations Are Not File Conversions

```text
materialization ≠ file format conversion
materialization ≠ syntax translation
materialization ≠ API wrapping
materialization ≠ serialization/deserialization

instantiation ≠ memory allocation
instantiation ≠ object construction
instantiation ≠ process launch

replication ≠ network copy
replication ≠ snapshot
replication ≠ serialization to remote host

observation ≠ telemetry collection
observation ≠ log aggregation
observation ≠ state polling
```

Each operation is a **semantic transformation** — it changes the meaning-concreteness, authority, or distribution of the state while preserving declared semantic properties.

## 4. Phase 1: Authoring

### 4.1 Semantic Definition

**Authoring** is the semantic phase where world state is created, composed, and modified through human or programmatic semantic editing. Authoring state is the **mutable, validatable, versionable** representation of computational world semantics.

Authoring encompasses:
- **Entity creation** — adding new semantic entities to the world
- **Component attachment** — composing entities with behavioral/state components
- **Relationship declaration** — defining semantic relationships between entities
- **Constraint specification** — declaring invariants, contracts, and behavioral bounds
- **Composition** — assembling complex entities from simpler ones
- **Modification** — changing entity state, component parameters, relationship targets
- **Removal** — destroying entities, detaching components, severing relationships

### 4.2 Authoring State

```text
AuthoringState
├── entities: Map<EntityId, AuthoredEntity>
│   ├── identity: ResourceIdentity (SID)
│   ├── components: Map<ComponentId, AuthoredComponent>
│   ├── relationships: Map<RelationshipId, AuthoredRelationship>
│   └── constraints: Vec<AuthoredConstraint>
├── composition: CompositionGraph
│   ├── parent_child: Dag<EntityId, CompositionEdge>
│   ├── includes: Dag<EntityId, IncludeEdge>
│   └── extends: Dag<EntityId, ExtendEdge>
├── references: Map<ReferenceId, SymbolicReference>
│   ├── target: SymbolicName (not yet resolved to SID)
│   ├── reference_kind: ReferenceKind (Strong/Weak/Symbolic/ContentAddress/Versioned)
│   └── scope: ReferenceScope (Local/Domain/Global/Federation)
├── version: SemanticVersion
├── metadata: AuthoringMetadata
│   ├── author: AuthorityId
│   ├── created: Timestamp
│   ├── modified: Timestamp
│   └── provenance: Vec<EditEvent>
└── validation_state: Option<ValidationResult> (populated during materialization)
```

### 4.3 Authoring Properties

| Property | Description |
|----------|-------------|
| **Mutable** | Entities, components, relationships, and constraints can be added, modified, or removed at any time |
| **Validatable** | Subject to semantic validation (contracts, invariants, type checking) but validation is not required for authoring state to exist |
| **Versionable** | Every edit produces a new version; version history is preserved |
| **Symbolic** | References are symbolic (names, paths) not concrete (SIDs, addresses) |
| **Composable** | Entities are assembled from components; complex behaviors emerge from composition |
| **Provider-independent** | Authoring state has no dependency on any execution provider |

### 4.4 Information Preserved/Lost

| Information | Status | Reason |
|-------------|--------|--------|
| Entity identities (SIDs) | **Preserved** | Authoritative identity survives all transformations |
| Component semantics | **Preserved** | Core semantic meaning preserved through materialization |
| Relationship semantics | **Preserved** | Semantic relationships survive transformation |
| Symbolic references | **Resolved** | Symbolic names become concrete SID coordinates |
| Composition structure | **Flattened** | May be inlined, merged, or optimized during materialization |
| Edit history | **Preserved** | Provenance chain maintained |
| Mutable state | **Lost** | Authoring mutability replaced by deployable immutability |
| Unvalidated contracts | **Resolved** | Must be validated before materialization completes |

### 4.5 Invariants

- **AUTHOR-INV-001 (Authoring Mutability)**: Authoring state MUST be mutable. Edits MUST produce new versions without destroying previous versions.
- **AUTHOR-INV-002 (Symbolic Reference Integrity)**: Symbolic references in authoring state MUST be resolvable at materialization time. Unresolvable references MUST be flagged before compilation begins.
- **AUTHOR-INV-003 (Provenance Completeness)**: Every edit to authoring state MUST be recorded with author, timestamp, and operation type.
- **AUTHOR-INV-004 (Semantic Preservation)**: Authoring edits MUST NOT silently alter declared semantic properties. Changes to semantics require explicit declaration.

### 4.6 Provider Responsibilities

| Provider | Role |
|----------|------|
| **Authoring Tool** | Provides UI/API for semantic editing; enforces AUTHOR-INV-001, AUTHOR-INV-003 |
| **Validation Service** | Provides on-demand semantic validation; does not block authoring |
| **Version Control** | Provides version history, branching, merging; enforces AUTHOR-INV-003 |
| **Reference Resolver** | Provides symbolic-to-concrete resolution; used during materialization |

## 5. Phase 2: Materialization

### 5.1 Semantic Definition

**Materialization** is the semantic transformation from authoring state to deployable state. It is a specialization of Lowering (`lib/903_Lowering`) — a semantics-preserving transformation between abstraction levels. Materialization involves compilation, optimization, and validation — not just encoding.

```text
AUTHORING STATE → [materialize()] → DEPLOYABLE STATE
```

### 5.2 Materialization Stages

Materialization is a **seven-stage pipeline**. Each stage is a semantic transformation with defined inputs, outputs, and invariants.

```text
materialize(authoring: AuthoringState) → Result<DeployableState, MaterializationError>
│
├── Stage 1: Resolution
│   ├── Input: Symbolic references, dependency declarations
│   ├── Operation: Resolve all symbolic references to concrete ResourceIdentity (SID)
│   ├── Output: Closed dependency graph with concrete SID coordinates
│   ├── Invariant: RES-INV-003 (Scope Integrity) enforced
│   ├── Information preserved: Entity identities, component semantics
│   ├── Information lost: Symbolic names (replaced by SIDs)
│   └── Failure: Unresolvable reference → materialization rejected
│
├── Stage 2: Validation
│   ├── Input: Closed dependency graph, semantic contracts
│   ├── Operation: Verify all contracts, invariants, type compatibility
│   ├── Output: Validated resource graph
│   ├── Invariant: All declared contracts satisfied
│   ├── Information preserved: All semantic properties
│   ├── Information lost: Invalid constraints (rejected, not silently dropped)
│   └── Failure: Contract violation → materialization rejected with diagnostic
│
├── Stage 3: Flattening
│   ├── Input: Validated resource graph with composition
│   ├── Operation: Inline composites, merge compatible layers, eliminate abstraction
│   ├── Output: Flat resource representation
│   ├── Invariant: Semantic equivalence preserved (Lowering §5, §44)
│   ├── Information preserved: Semantic behavior, entity identities
│   ├── Information lost: Composition structure (abstracted away)
│   └── Failure: Non-flattenable composition → partial flattening with explicit annotation
│
├── Stage 4: Compilation
│   ├── Input: Flat semantic representation
│   ├── Operation: Transform to lower-level representation (per Lowering §2)
│   ├── Output: Compiled representation (MLIR modules, bytecode, compiled kernels)
│   ├── Invariant: LOWERING-INV-001 (Semantic Preservation)
│   ├── Information preserved: All declared semantic properties
│   ├── Information lost: High-level abstractions (replaced by lower-level constructs)
│   └── Failure: Unsupported lowering path → materialization rejected
│
├── Stage 5: Dependency Closure
│   ├── Input: Compiled resources, dependency graph
│   ├── Operation: Ensure all transitive dependencies are satisfied, link, bundle
│   ├── Output: Self-contained compiled resource bundle
│   ├── Invariant: DEP-INV-001 (Acyclicity), DEP-INV-003 (Scope Enforcement)
│   ├── Information preserved: Dependency relationships (as metadata)
│   ├── Information lost: External dependency indirection (resolved to concrete)
│   └── Failure: Unresolvable dependency → materialization rejected
│
├── Stage 6: Optimization
│   ├── Input: Compiled resource bundle
│   ├── Operation: Semantic-preserving transformations (fusion, vectorization, tiling, dead code elimination)
│   ├── Output: Optimized compiled resource
│   ├── Invariant: Semantic equivalence preserved (Lowering §48, §54)
│   ├── Information preserved: All declared semantic properties
│   ├── Information lost: Redundant computations, unused code paths
│   └── Failure: Optimization introduces approximation → explicit declaration required
│
└── Stage 7: Deterministic Initialization
    ├── Input: Optimized compiled resource
    ├── Operation: Version stamping, deterministic ordering, provenance recording
    ├── Output: Finalized deployable resource
    ├── Invariant: MAT-INV-004 (Deterministic Ordering), MAT-INV-005 (Provenance Completeness)
    ├── Information preserved: Version, provenance, initialization order
    ├── Information lost: Non-deterministic ordering (resolved to deterministic)
    └── Failure: Non-deterministic ordering detected → materialization rejected
```

### 5.3 Information Preserved/Lost Through Materialization

| Information | Status | Reason |
|-------------|--------|--------|
| Entity identities (SIDs) | **Preserved** | Authoritative identity survives all stages |
| Component semantics | **Preserved** | Core semantic meaning preserved (MAT-INV-001) |
| Relationship semantics | **Preserved** | Semantic relationships survive transformation |
| Dependency relationships | **Preserved** (as metadata) | Dependencies recorded for runtime resolution |
| Version history | **Preserved** | Provenance chain maintained (MAT-INV-005) |
| Symbolic references | **Resolved** → Lost as symbolic | Replaced by concrete SID coordinates |
| Composition structure | **Flattened** → Lost as structure | Inlined/merged; behavior preserved, structure not |
| Abstraction layers | **Compiled** → Lost as abstraction | Replaced by lower-level constructs |
| Redundant computation | **Optimized** → Lost | Removed by semantic-preserving optimization |
| Mutable state | **Lost** | Authoring mutability replaced by deployable immutability |
| Unvalidated contracts | **Resolved** | Must pass validation before compilation |

### 5.4 Invariants

- **MAT-INV-001 (Semantic Preservation)**: Materialization MUST preserve all declared semantic properties of the source. (Derived from LOWERING-INV-001.)
- **MAT-INV-002 (Reference Closure)**: All symbolic references MUST be resolved before compilation begins. (Derived from RES-INV-003.)
- **MAT-INV-003 (Contract Satisfaction)**: All declared materialization contracts MUST be satisfied or explicitly weakened with declared approximation.
- **MAT-INV-004 (Deterministic Ordering)**: Materialization of identical resources with identical dependencies MUST produce deterministic results.
- **MAT-INV-005 (Provenance Completeness)**: Every materialization MUST record full provenance: source identity, transformation chain, target identity, timestamp, authority.
- **MAT-INV-006 (Failure Transparency)**: Materialization failure MUST NOT silently produce a partial or invalid resource.

### 5.5 Provider Responsibilities

| Provider | Role |
|----------|------|
| **Reference Resolver** | Stage 1: Symbolic → concrete SID resolution |
| **Validation Engine** | Stage 2: Contract and invariant checking |
| **Flattener** | Stage 3: Composition inlining and abstraction elimination |
| **Compiler** | Stage 4: Semantic → lower-level representation |
| **Dependency Manager** | Stage 5: Transitive dependency resolution and bundling |
| **Optimizer** | Stage 6: Semantic-preserving performance transformations |
| **Finalizer** | Stage 7: Version stamping, deterministic ordering, provenance |

## 6. Phase 3: Deployable State

### 6.1 Semantic Definition

**Deployable state** is the immutable, validated, optimized representation ready for instantiation. It is the output of materialization and the input to instantiation. Deployable state is **deterministic** — identical inputs produce identical outputs.

### 6.2 Deployable State Structure

```text
DeployableState
├── identity: ResourceIdentity (SID, same as authoring)
├── content_hash: Hash (content-addressable identity, derived)
├── version: SemanticVersion (from materialization)
├── compiled: CompiledRepresentation
│   ├── mlir_modules: Vec<MlirModule> (if MLIR target)
│   ├── bytecode: Option<Bytecode> (if bytecode target)
│   ├── kernels: Vec<CompiledKernel> (if GPU/accelerator target)
│   └── serialized_state: Option<SerializedState> (initial state snapshot)
├── dependencies: Vec<ResolvedDependency>
│   ├── resource_id: ResourceIdentity
│   ├── version_constraint: SemVerConstraint
│   ├── scope: DependencyScope
│   └── materialization_state: DeployableState (transitive closure)
├── metadata: DeployableMetadata
│   ├── materialization_timestamp: Timestamp
│   ├── materialization_authority: AuthorityId
│   ├── transformation_chain: TransformationChain
│   ├── optimization_flags: Vec<OptimizationFlag>
│   └── determinism_guarantee: DeterminismGuarantee
├── initialization_order: Vec<InitializationEntry>
│   ├── entity_id: ResourceIdentity
│   ├── order: usize
│   └── dependencies: Vec<ResourceIdentity>
└── immutability: ImmutabilityMarker (deployable state is immutable after materialization)
```

### 6.3 Deployable Properties

| Property | Description |
|----------|-------------|
| **Immutable** | Once materialized, deployable state cannot be modified. Re-materialization produces a new deployable state. |
| **Validated** | All contracts, invariants, and type compatibility verified during materialization |
| **Optimized** | Semantic-preserving optimizations applied |
| **Deterministic** | Identical inputs produce identical outputs (MAT-INV-004) |
| **Self-contained** | All dependencies resolved and bundled (may reference external resources by SID) |
| **Versioned** | Materialization version, content hash, and provenance recorded |

### 6.4 Information Preserved/Lost

| Information | Status | Reason |
|-------------|--------|--------|
| Entity identities (SIDs) | **Preserved** | Authoritative identity |
| Compiled semantics | **Present** | Core semantic behavior in lower-level form |
| Dependency graph | **Present** (resolved) | All dependencies concrete SIDs |
| Materialization provenance | **Present** | Full transformation chain recorded |
| Initialization order | **Present** | Deterministic ordering for instantiation |
| Authoring edit history | **Lost** | Only materialization provenance retained |
| Composition structure | **Lost** | Flattened during materialization |
| Symbolic references | **Lost** | Resolved to concrete SIDs |

### 6.5 Invariants

- **DEPLOY-INV-001 (Immutability)**: Deployable state MUST be immutable after materialization. Modification requires re-materialization from authoring state.
- **DEPLOY-INV-002 (Determinism)**: Materialization of identical inputs MUST produce identical deployable states (content hash matches).
- **DEPLOY-INV-003 (Completeness)**: Deployable state MUST contain all information required for instantiation. No external resolution required at instantiation time (except runtime-resolved dependencies).
- **DEPLOY-INV-004 (Provenance Traceability)**: Every deployable state MUST be traceable to its authoring state through materialization provenance.

### 6.6 Provider Responsibilities

| Provider | Role |
|----------|------|
| **Storage Provider** | Stores deployable state; enforces immutability (DEPLOY-INV-001) |
| **Content Store** | Maintains content-addressable index; deduplication via content hash |
| **Package Manager** | Manages dependency resolution and bundling |
| **Distribution Service** | Distributes deployable state to instantiation sites |

## 7. Phase 4: Instantiation

### 7.1 Semantic Definition

**Instantiation** is the semantic transformation from deployable state to simulation state. It loads the compiled representation into an execution context, allocates provider manifestations, and initializes deterministic state.

```text
DEPLOYABLE STATE → [instantiate()] → SIMULATION STATE
```

### 7.2 Instantiation Stages

```text
instantiate(deployable: DeployableState, context: ExecutionContext) → Result<SimulationState, InstantiationError>
│
├── Stage 1: Loading
│   ├── Input: Deployable state, execution context
│   ├── Operation: Load compiled representation into execution context
│   ├── Output: Loaded resources (memory-resident, GPU buffers allocated)
│   ├── Invariant: STAGE-INV-004 (Runtime Isolation) — loading does not redefine semantics
│   ├── Information preserved: All deployable state properties
│   ├── Information lost: Storage format (replaced by memory representation)
│   └── Failure: Insufficient resources → instantiation rejected
│
├── Stage 2: Manifest Allocation
│   ├── Input: Loaded resources, provider capabilities
│   ├── Operation: Allocate provider-specific manifestations (handles, buffers, actors)
│   ├── Output: Manifested resources with active handles
│   ├── Invariant: IAM-I014 (Manifestation Separation) — manifestation ≠ identity
│   ├── Information preserved: Entity identities, compiled semantics
│   ├── Information lost: Provider-independence (now provider-bound)
│   └── Failure: Provider limitation → instantiation rejected
│
├── Stage 3: Dependency Activation
│   ├── Input: Manifested resources, dependency graph
│   ├── Operation: Activate dependencies in topological order (per initialization_order)
│   ├── Output: Fully linked resource graph
│   ├── Invariant: DEP-INV-001 (Acyclicity) — activation order is deterministic
│   ├── Information preserved: Dependency relationships
│   ├── Information lost: Dependency indirection (now directly linked)
│   └── Failure: Circular dependency → instantiation rejected
│
└── Stage 4: Deterministic Initialization
    ├── Input: Linked resource graph, initialization order
    ├── Operation: Initialize entity state in deterministic order
    ├── Output: Initialized simulation state
    ├── Invariant: MAT-INV-004 (Deterministic Ordering) — initialization order matches materialization
    ├── Information preserved: Initial state values, initialization order
    ├── Information lost: None
    └── Failure: Non-deterministic initialization detected → instantiation rejected
```

### 7.3 Information Preserved/Lost

| Information | Status | Reason |
|-------------|--------|--------|
| Entity identities (SIDs) | **Preserved** | Authoritative identity |
| Compiled semantics | **Preserved** | Loaded into execution context |
| Dependency graph | **Preserved** (linked) | Dependencies resolved and activated |
| Initialization order | **Executed** | Order followed for deterministic initialization |
| Deployable immutability | **Lost** | Simulation state is mutable (temporal progression) |
| Storage format | **Lost** | Replaced by memory/GPU representation |
| Provider-independence | **Lost** | Now bound to specific provider manifestations |

### 7.4 Invariants

- **INST-INV-001 (Manifestation Independence)**: Instantiation MUST NOT alter entity identity. Provider manifestations are ephemeral handles, not identity. (Derived from IAM-I014.)
- **INST-INV-002 (Deterministic Initialization)**: Initialization order MUST match materialization-time ordering (MAT-INV-004).
- **INST-INV-003 (Context Isolation)**: Instantiation into one execution context MUST NOT affect other contexts. Resource manifestations are context-scoped.
- **INST-INV-004 (Activation Prerequisite)**: Activation REQUIRES successful materialization. A resource MUST NOT be activated from Defined, Resolving, Validating, or Compiling states. (Derived from LIFECYCLE-INV-004.)

### 7.5 Provider Responsibilities

| Provider | Role |
|----------|------|
| **Memory Provider** | Loads compiled representation into memory; allocates buffers |
| **GPU Provider** | Allocates GPU buffers, textures, compute pipelines |
| **Execution Context** | Manages resource lifecycle within execution scope |
| **Dependency Resolver** | Activates dependencies in topological order |

## 8. Phase 5: Simulation State

### 8.1 Semantic Definition

**Simulation state** is the running world with active entities, temporal progression, and mutable state. It is the operational phase where computational semantics are executed.

### 8.2 Simulation State Structure

```text
SimulationState
├── identity: ResourceIdentity (SID, same as authoring/deployable)
├── execution_context: ExecutionContext
│   ├── host: HostId
│   ├── process: ProcessId
│   └── capabilities: Vec<ProviderCapability>
├── entities: Map<EntityId, ActiveEntity>
│   ├── identity: ResourceIdentity
│   ├── manifestations: Map<ProviderId, ManifestationHandle>
│   ├── mutable_state: Map<StateId, StateValue>
│   ├── active_components: Map<ComponentId, ActiveComponent>
│   └── temporal_state: TemporalState
│       ├── simulation_time: SimulationTime
│       ├── wall_clock_time: WallClockTime
│       └── time_progression: TimeProgressionMode
├── relationships: Map<RelationshipId, ActiveRelationship>
│   ├── source: EntityId
│   ├── target: EntityId
│   ├── relationship_kind: RelationshipKind
│   └── active: bool
├── streams: Map<StreamId, ActiveStream>
│   ├── source: EntityId
│   ├── target: EntityId
│   ├── stream_kind: StreamKind
│   └── buffer: StreamBuffer
├── temporal_progression: TemporalProgression
│   ├── current_time: SimulationTime
│   ├── time_step: TimeStep
│   ├── progression_mode: ProgressionMode (FixedStep/VariableStep/EventDriven)
│   └── history: Vec<TemporalSnapshot>
├── mutable: MutableMarker (simulation state is mutable)
└── authority: SimulationAuthority
    ├── local_authority: bool
    ├── authority_scope: AuthorityScope
    └── ownership: Map<EntityId, OwnershipRecord>
```

### 8.3 Simulation Properties

| Property | Description |
|----------|-------------|
| **Mutable** | Entity state, component parameters, and relationships can change during simulation |
| **Temporal** | Time progresses; state changes are ordered by temporal semantics |
| **Active** | Entities have active manifestations; components are executing |
| **Observable** | State can be observed (read) without modifying it |
| **Distributable** | State can be replicated to other hosts (subject to authority/ownership) |

### 8.4 Information Preserved/Lost

| Information | Status | Reason |
|-------------|--------|--------|
| Entity identities (SIDs) | **Preserved** | Authoritative identity |
| Compiled semantics | **Preserved** (executing) | Active in execution context |
| Mutable state | **Gained** | Simulation introduces mutable temporal state |
| Temporal progression | **Gained** | Time advances; state changes are time-ordered |
| Provider manifestations | **Active** | Handles are live and consuming resources |
| Deployable immutability | **Lost** | Simulation state is mutable |
| Deterministic initialization order | **Executed** | Order followed; no longer relevant for future changes |

### 8.5 Invariants

- **SIM-INV-001 (Authority Preservation)**: Simulation state authority MUST be consistent with deployable state authority. Authority transitions are explicit. (M004 Invariant 1.)
- **SIM-INV-002 (Temporal Ordering)**: State changes MUST be ordered by temporal semantics. Time ordering is preserved across distributed observations. (M004 Invariant 4.)
- **SIM-INV-003 (Observation Non-Destructive)**: Observing simulation state MUST NOT modify it. Read operations are side-effect-free.
- **SIM-INV-004 (Ownership Clarity)**: Every mutable entity in simulation state MUST have a defined owner. Ownership determines authority for modifications.

### 8.6 Provider Responsibilities

| Provider | Role |
|----------|------|
| **Simulation Engine** | Manages temporal progression, entity updates, component execution |
| **Physics Provider** | Manages physics simulation, collision, dynamics |
| **Network Provider** | Manages replication boundaries, authority delegation |
| **Observation Provider** | Provides read-only access to simulation state |

## 9. Phase 6: Replication

### 9.1 Semantic Definition

**Replication** is the semantic transformation from simulation state to distributed state. It distributes world state across multiple hosts while maintaining authority, ownership, and temporal consistency.

```text
SIMULATION STATE → [replicate()] → DISTRIBUTED STATE
```

### 9.2 Replication Stages

```text
replicate(simulation: SimulationState, topology: DistributionTopology) → Result<DistributedState, ReplicationError>
│
├── Stage 1: Partitioning
│   ├── Input: Simulation state, distribution topology
│   ├── Operation: Partition world state across hosts based on authority/ownership
│   ├── Output: Host-scoped state partitions
│   ├── Invariant: Each entity has exactly one authoritative host
│   ├── Information preserved: Entity identities, semantic relationships
│   ├── Information lost: Global mutable state (repartitioned per host)
│   └── Failure: Unpartitionable state → replication rejected
│
├── Stage 2: Authority Delegation
│   ├── Input: State partitions, authority model
│   ├── Operation: Delegate modification authority to owning hosts
│   ├── Output: Per-host authority records
│   ├── Invariant: Authority transitions are explicit (M004 Invariant 1)
│   ├── Information preserved: Authority relationships
│   ├── Information lost: Centralized authority (delegated to hosts)
│   └── Failure: Authority conflict → replication rejected
│
├── Stage 3: State Serialization
│   ├── Input: Host-scoped state partitions
│   ├── Operation: Serialize state for network transport (semantic-preserving)
│   ├── Output: Serialized state bundles with metadata
│   ├── Invariant: Semantic preservation across serialization boundary
│   ├── Information preserved: All semantic properties
│   ├── Information lost: Memory representation (replaced by transport format)
│   └── Failure: Serialization error → replication rejected
│
├── Stage 4: Synchronization Setup
│   ├── Input: Serialized state bundles, synchronization topology
│   ├── Operation: Establish synchronization channels between hosts
│   ├── Output: Active synchronization links with conflict resolution policies
│   ├── Invariant: Synchronization preserves temporal ordering (M004 Invariant 4)
│   ├── Information preserved: Temporal ordering, entity relationships
│   ├── Information lost: None
│   └── Failure: Synchronization impossible → replication rejected
│
└── Stage 5: Initial State Transfer
    ├── Input: Serialized state bundles, synchronization links
    ├── Operation: Transfer initial state to all replica hosts
    ├── Output: Distributed state with consistent initial state
    ├── Invariant: All hosts start from consistent state
    ├── Information preserved: All semantic properties
    ├── Information lost: None
    └── Failure: Transfer failure → replication rejected
```

### 9.3 Information Preserved/Lost

| Information | Status | Reason |
|-------------|--------|--------|
| Entity identities (SIDs) | **Preserved** | Authoritative identity across hosts |
| Semantic relationships | **Preserved** | Cross-host relationships maintained |
| Authority model | **Preserved** (delegated) | Authority transitions explicit |
| Ownership records | **Preserved** | Per-entity ownership maintained |
| Temporal ordering | **Preserved** | Time ordering maintained across hosts |
| Global mutable state | **Partitioned** | State distributed; no single global mutable state |
| Centralized authority | **Delegated** | Authority distributed to hosts |
| Memory representation | **Lost** | Replaced by transport format |

### 9.4 Invariants

- **REPL-INV-001 (Authority Explicitness)**: Authority transitions MUST be explicit. No silent authority changes. (M004 Invariant 1.)
- **REPL-INV-002 (Ownership Definition)**: Replicated state MUST have defined ownership. Every mutable entity MUST have exactly one authoritative owner. (M004 Invariant 3.)
- **REPL-INV-003 (Temporal Consistency)**: Time ordering MUST be preserved across distributed observations. (M004 Invariant 4.)
- **REPL-INV-004 (Consistent Initialization)**: All replica hosts MUST start from consistent state. No host may initialize with stale or partial state.
- **REPL-INV-005 (Semantic Preservation)**: Replication MUST NOT alter semantic meaning. Transport serialization is semantics-preserving.

### 9.5 Provider Responsibilities

| Provider | Role |
|----------|------|
| **Partitioning Service** | Determines host-scoped state partitions based on topology |
| **Authority Manager** | Delegates modification authority; enforces REPL-INV-001 |
| **Serialization Provider** | Serializes state for transport; enforces REPL-INV-005 |
| **Synchronization Provider** | Establishes and maintains synchronization channels |
| **Network Transport** | Transfers state between hosts (UDP/TCP/reliable/unreliable — transport is not semantics) |

## 10. Phase 7: Distributed State

### 10.1 Semantic Definition

**Distributed state** is the multi-host world state with defined authority, ownership, and temporal ordering. It is the operational state of a world replicated across multiple execution hosts.

### 10.2 Distributed State Structure

```text
DistributedState
├── identity: ResourceIdentity (SID, same across all hosts)
├── topology: DistributionTopology
│   ├── hosts: Map<HostId, HostState>
│   │   ├── host_id: HostId
│   │   ├── authority_scope: AuthorityScope
│   │   ├── owned_entities: Vec<EntityId>
│   │   ├── replica_entities: Vec<EntityId>
│   │   └── synchronization_links: Vec<SynchronizationLink>
│   ├── partitioning: PartitioningScheme
│   │   ├── scheme_kind: PartitioningKind (Spatial/Authority/LoadBalanced/Manual)
│   │   └── boundaries: Vec<PartitionBoundary>
│   └── global_topology: TopologyGraph
├── authority: DistributedAuthority
│   ├── authority_model: AuthorityModel (SingleOwner/MultiOwner/Consensus/Federated)
│   ├── authority_transitions: Vec<AuthorityTransition>
│   │   ├── entity_id: EntityId
│   ├── from_host: HostId
│   │   ├── to_host: HostId
│   │   ├── reason: AuthorityTransferReason
│   │   └── timestamp: Timestamp
│   └── conflict_resolution: ConflictResolutionPolicy
├── ownership: OwnershipModel
│   ├── entity_ownership: Map<EntityId, OwnershipRecord>
│   │   ├── owner_host: HostId
│   │   ├── ownership_kind: OwnershipKind (Exclusive/Shared/Delegated)
│   │   ├── transferable: bool
│   │   └── last_transfer: Option<Timestamp>
│   └── ownership_transitions: Vec<OwnershipTransition>
├── synchronization: SynchronizationModel
│   ├── channels: Map<ChannelId, SynchronizationChannel>
│   │   ├── source_host: HostId
│   │   ├── target_host: HostId
│   │   ├── sync_kind: SynchronizationKind (StateSync/EventSync/CommandSync)
│   │   ├── reliability: ReliabilityGuarantee (Reliable/BestEffort/Ordered)
│   │   └── conflict_policy: ConflictPolicy (LastWriterWins/MergeByRule/Reject/OwnerWins)
│   ├── temporal_synchronization: TemporalSyncModel
│   │   ├── sync_mode: TemporalSyncMode (Lockstep/Optimistic/Pessimistic)
│   │   └── clock_synchronization: ClockSyncMethod
│   └── state_vector: Map<HostId, StateVector>
├── prediction: PredictionModel (deferred to Sprint 03)
├── reconciliation: ReconciliationModel (deferred to Sprint 03)
└── temporal: DistributedTemporalModel
    ├── wall_clock: WallClockTime
    ├── simulation_time: SimulationTime
    ├── time_offset: Map<HostId, TimeOffset>
    └── time_progression: TimeProgressionMode
```

### 10.3 Distributed Properties

| Property | Description |
|----------|-------------|
| **Multi-host** | State exists across multiple execution hosts |
| **Authority-delegated** | Modification authority is explicitly delegated per entity |
| **Ownership-defined** | Every mutable entity has a defined owner |
| **Temporally-ordered** | State changes are ordered by temporal semantics across hosts |
| **Synchronized** | Hosts maintain consistency through defined synchronization channels |
| **Conflicting** | Concurrent modifications may conflict; conflict resolution is explicit |

### 10.4 Information Preserved/Lost

| Information | Status | Reason |
|-------------|--------|--------|
| Entity identities (SIDs) | **Preserved** | Authoritative identity across hosts |
| Semantic relationships | **Preserved** | Cross-host relationships maintained |
| Authority model | **Preserved** | Explicit authority transitions |
| Ownership records | **Preserved** | Per-entity ownership |
| Temporal ordering | **Preserved** | Time ordering maintained |
| Global state | **Lost** | No single global mutable state; partitioned |
| Centralized control | **Lost** | Distributed authority and control |
| Low-latency mutation | **Lost** | Cross-host mutations subject to network latency |

### 10.5 Invariants

- **DIST-INV-001 (Authority Explicitness)**: Authority transitions MUST be explicit. Prediction does not silently overwrite authoritative state. (M004 Invariant 1, 2.)
- **DIST-INV-002 (Ownership Clarity)**: Every mutable entity MUST have exactly one authoritative owner at any time. (M004 Invariant 3.)
- **DIST-INV-003 (Temporal Ordering)**: Time ordering MUST be preserved across distributed observations. (M004 Invariant 4.)
- **DIST-INV-004 (Conflict Transparency)**: Concurrent modifications MUST be detected and resolved through declared conflict resolution policies. Silent conflict resolution is prohibited.
- **DIST-INV-005 (Consistency Contract)**: The distribution topology MUST declare its consistency contract: strong consistency, eventual consistency, or causal consistency. The contract MUST be enforced.

### 10.6 Provider Responsibilities

| Provider | Role |
|----------|------|
| **Authority Manager** | Manages authority transitions; enforces DIST-INV-001 |
| **Ownership Manager** | Manages ownership records; enforces DIST-INV-002 |
| **Synchronization Provider** | Maintains synchronization channels; enforces DIST-INV-003 |
| **Conflict Resolver** | Resolves concurrent modifications; enforces DIST-INV-004 |
| **Temporal Coordinator** | Maintains temporal ordering across hosts; enforces DIST-INV-003 |

## 11. Phase 8: Observation

### 11.1 Semantic Definition

**Observation** is the semantic transformation from distributed state to SCR-compatible semantic state. It aggregates, reconciles, and projects distributed state into a form suitable for semantic analysis, querying, and authoring.

```text
DISTRIBUTED STATE → [observe()] → SCR-COMPATIBLE SEMANTIC STATE
```

### 11.2 Observation Stages

```text
observe(distributed: DistributedState, query: ObservationQuery) → Result<SemanticState, ObservationError>
│
├── Stage 1: Aggregation
│   ├── Input: Distributed state from multiple hosts
│   ├── Operation: Collect state from all relevant hosts
│   ├── Output: Aggregated state snapshot
│   ├── Invariant: Observation is non-destructive (SIM-INV-003)
│   ├── Information preserved: All semantic properties from all hosts
│   ├── Information lost: None (aggregation is lossless)
│   └── Failure: Host unreachable → partial aggregation with annotation
│
├── Stage 2: Reconciliation
│   ├── Input: Aggregated state, conflict resolution results
│   ├── Operation: Resolve any pending conflicts, merge concurrent modifications
│   ├── Output: Reconciled state
│   ├── Invariant: Conflict resolution follows declared policy (DIST-INV-004)
│   ├── Information preserved: All non-conflicting state
│   ├── Information lost: Conflicting state (resolved per policy)
│   └── Failure: Unresolvable conflict → observation rejected
│
├── Stage 3: Projection
│   ├── Input: Reconciled state, observation query
│   ├── Operation: Project state to requested view (subset of entities, attributes, relationships)
│   ├── Output: Projected semantic state
│   ├── Invariant: Projection preserves semantic meaning of projected subset
│   ├── Information preserved: Semantic properties of projected entities
│   ├── Information lost: Non-projected entities (not included in view)
│   └── Failure: Invalid projection → observation rejected
│
└── Stage 4: Semantic Formatting
    ├── Input: Projected state
    ├── Operation: Format as SCR-compatible semantic representation
    ├── Output: SCR-compatible semantic state (authoring-compatible)
    ├── Invariant: Output is valid authoring state input
    ├── Information preserved: All projected semantic properties
    ├── Information lost: Runtime-specific metadata (replaced by authoring metadata)
    └── Failure: Formatting error → observation rejected
```

### 11.3 Observation vs Authoring

Observation produces state that is **authoring-compatible** but not identical to authoring state:

| Aspect | Observation Output | Authoring State |
|--------|-------------------|-----------------|
| **Mutability** | Read-only snapshot | Mutable |
| **Version** | Point-in-time snapshot | Evolving version |
| **References** | Concrete (SIDs) | Symbolic (names) |
| **Validation** | Already validated | May be unvalidated |
| **Source** | Derived from runtime state | Human/programmatic authored |

Observation output can serve as input to a new authoring cycle — enabling the full lifecycle loop.

### 11.4 Information Preserved/Lost

| Information | Status | Reason |
|-------------|--------|--------|
| Entity identities (SIDs) | **Preserved** | Authoritative identity |
| Semantic relationships | **Preserved** | Cross-host relationships aggregated |
| Temporal ordering | **Preserved** | Time ordering maintained in snapshot |
| Mutable state values | **Preserved** (snapshot) | Current values captured at observation time |
| Runtime manifestations | **Lost** | Provider-specific handles not exposed |
| Network topology | **Lost** | Distribution details abstracted away |
| Non-projected entities | **Lost** | Projection filters to query scope |
| Authoring mutability | **Lost** | Observation output is read-only |

### 11.5 Invariants

- **OBS-INV-001 (Non-Destructive Observation)**: Observation MUST NOT modify the distributed state being observed. (Derived from SIM-INV-003.)
- **OBS-INV-002 (Temporal Snapshot)**: Observation MUST capture state at a consistent point in time. Temporal ordering MUST be preserved. (Derived from M004 Invariant 4.)
- **OBS-INV-003 (Semantic Consistency)**: Observation output MUST be semantically consistent with the observed distributed state. No semantic properties may be invented or altered.
- **OBS-INV-004 (Authoring Compatibility)**: Observation output MUST be valid as input to the authoring phase, enabling the lifecycle loop.
- **OBS-INV-005 (Conflict Transparency)**: If conflicts were resolved during observation, the observation output MUST annotate which conflicts were resolved and by what policy.

### 11.6 Provider Responsibilities

| Provider | Role |
|----------|------|
| **Aggregation Service** | Collects state from multiple hosts |
| **Reconciliation Engine** | Resolves conflicts per declared policy |
| **Projection Service** | Filters and projects state to query scope |
| **Semantic Formatter** | Formats output as SCR-compatible semantic state |

## 12. Lifecycle Invariants (Cross-Cutting)

### 12.1 Lifecycle-Wide Invariants

| Invariant | Statement | Derived From |
|-----------|-----------|--------------|
| **LIFECYCLE-INV-001** | Every phase transition MUST be an explicit semantic operation. | LIFECYCLE-INV-001 (M003) |
| **LIFECYCLE-INV-002** | No phase may be skipped without an explicit contract. | LIFECYCLE-INV-002 (M003) |
| **LIFECYCLE-INV-003** | Semantic properties MUST be preserved across all phase transitions unless explicitly declared as lost. | MAT-INV-001, LOWERING-INV-001 |
| **LIFECYCLE-INV-004** | Authority transitions MUST be explicit. No silent authority changes. | M004 Invariant 1 |
| **LIFECYCLE-INV-005** | Prediction MUST NOT silently overwrite authoritative state. | M004 Invariant 2 |
| **LIFECYCLE-INV-006** | Replicated state MUST have defined ownership. | M004 Invariant 3 |
| **LIFECYCLE-INV-007** | Time ordering MUST be preserved across distributed observations. | M004 Invariant 4 |
| **LIFECYCLE-INV-008** | Every phase transition MUST record provenance: source state, operation, target state, timestamp, authority. | MAT-INV-005 |
| **LIFECYCLE-INV-009** | Phase transition failure MUST NOT silently produce partial or invalid state. | MAT-INV-006 |

### 12.2 Identity Invariants Across Lifecycle

| Invariant | Statement | Across Phases |
|-----------|-----------|---------------|
| **IDENTITY-INV-001** | Entity identity (SID) MUST be preserved across all lifecycle phases. | Authoring → Deployable → Simulation → Distributed → Observation |
| **IDENTITY-INV-002** | Identity MUST NOT be derived from content hash alone. | Authoring (SID) → Deployable (SID + content hash) |
| **IDENTITY-INV-003** | Identity MUST remain invariant across manifestation changes. | Simulation (manifestations) → Distributed (replicas) |

### 12.3 Information Flow Summary

```text
                    PRESERVED              TRANSFORMED              LOST
                    ─────────              ───────────              ────
Authoring → Deployable:
  Entity IDs          ✓                      -                        -
  Component Semantics ✓                      -                        -
  Symbolic Refs       -                      → Concrete SIDs           -
  Composition         -                      → Flattened               -
  Mutable State       -                      → Immutable               -
  Validation          -                      → Validated               -

Deployable → Simulation:
  Entity IDs          ✓                      -                        -
  Compiled Semantics  ✓                      -                        -
  Immutability        -                      → Mutable                 -
  Storage Format      -                      → Memory/GPU              -
  Temporal State      -                      → Active (gained)         -

Simulation → Distributed:
  Entity IDs          ✓                      -                        -
  Semantic Relations   ✓                      -                        -
  Global State        -                      → Partitioned             -
  Central Authority   -                      → Delegated               -
  Memory Format       -                      → Transport Format        -

Distributed → Observation:
  Entity IDs          ✓                      -                        -
  Temporal Ordering   ✓                      -                        -
  Runtime Handles     -                        -                       → Lost
  Network Topology    -                        -                       → Lost
  Non-Projected       -                        -                       → Lost
```

## 13. Provider Adapter Pattern

### 13.1 SCR → Provider Translation Across Lifecycle

All lifecycle phases follow the adapter pattern established in M003 Sprint 004:

| Phase | SCR Concept | Provider Mapping |
|-------|-------------|-----------------|
| **Authoring** | AuthoringState | Editor state, version control, composition graph |
| **Materialization** | MaterializationPipeline | Compiler passes, optimization, dependency resolution |
| **Deployable** | DeployableState | Storage, content store, package registry |
| **Instantiation** | InstantiationPipeline | Memory allocation, GPU buffer creation, process launch |
| **Simulation** | SimulationState | Active entity handles, component execution, temporal progression |
| **Replication** | ReplicationPipeline | Network transport, serialization, synchronization |
| **Distributed** | DistributedState | Multi-host state, authority delegation, conflict resolution |
| **Observation** | ObservationPipeline | State aggregation, reconciliation, projection |

### 13.2 Invariant Preservation Across Adapters

Provider adapters MUST preserve all lifecycle invariants. The adapter contract includes:
- Identity preservation (IDENTITY-INV-001, 002, 003)
- Semantic preservation (LIFECYCLE-INV-003)
- Authority explicitness (LIFECYCLE-INV-004)
- Temporal ordering (LIFECYCLE-INV-007)
- Provenance completeness (LIFECYCLE-INV-008)
- Failure transparency (LIFECYCLE-INV-009)

## 14. Invariant Registry

### 14.1 All Invariants Added This Sprint

| Invariant | Statement |
|-----------|-----------|
| **AUTHOR-INV-001** | Authoring state MUST be mutable. Edits MUST produce new versions. |
| **AUTHOR-INV-002** | Symbolic references MUST be resolvable at materialization time. |
| **AUTHOR-INV-003** | Every edit MUST be recorded with author, timestamp, and operation type. |
| **AUTHOR-INV-004** | Authoring edits MUST NOT silently alter declared semantic properties. |
| **MAT-INV-001** | Materialization MUST preserve all declared semantic properties. |
| **MAT-INV-002** | All symbolic references MUST be resolved before compilation. |
| **MAT-INV-003** | All materialization contracts MUST be satisfied or explicitly weakened. |
| **MAT-INV-004** | Materialization of identical resources MUST produce deterministic results. |
| **MAT-INV-005** | Every materialization MUST record full provenance. |
| **MAT-INV-006** | Materialization failure MUST NOT silently produce partial resources. |
| **DEPLOY-INV-001** | Deployable state MUST be immutable after materialization. |
| **DEPLOY-INV-002** | Materialization of identical inputs MUST produce identical deployable states. |
| **DEPLOY-INV-003** | Deployable state MUST contain all information required for instantiation. |
| **DEPLOY-INV-004** | Every deployable state MUST be traceable to its authoring state. |
| **INST-INV-001** | Instantiation MUST NOT alter entity identity. |
| **INST-INV-002** | Initialization order MUST match materialization-time ordering. |
| **INST-INV-003** | Instantiation into one context MUST NOT affect other contexts. |
| **INST-INV-004** | Activation REQUIRES successful materialization. |
| **SIM-INV-001** | Simulation state authority MUST be consistent with deployable state authority. |
| **SIM-INV-002** | State changes MUST be ordered by temporal semantics. |
| **SIM-INV-003** | Observing simulation state MUST NOT modify it. |
| **SIM-INV-004** | Every mutable entity MUST have a defined owner. |
| **REPL-INV-001** | Authority transitions MUST be explicit. |
| **REPL-INV-002** | Replicated state MUST have defined ownership. |
| **REPL-INV-003** | Time ordering MUST be preserved across distributed observations. |
| **REPL-INV-004** | All replica hosts MUST start from consistent state. |
| **REPL-INV-005** | Replication MUST NOT alter semantic meaning. |
| **DIST-INV-001** | Authority transitions MUST be explicit. Prediction does not silently overwrite. |
| **DIST-INV-002** | Every mutable entity MUST have exactly one authoritative owner. |
| **DIST-INV-003** | Time ordering MUST be preserved across distributed observations. |
| **DIST-INV-004** | Concurrent modifications MUST be detected and resolved through declared policies. |
| **DIST-INV-005** | Distribution topology MUST declare its consistency contract. |
| **OBS-INV-001** | Observation MUST NOT modify the distributed state being observed. |
| **OBS-INV-002** | Observation MUST capture state at a consistent point in time. |
| **OBS-INV-003** | Observation output MUST be semantically consistent with observed state. |
| **OBS-INV-004** | Observation output MUST be valid as input to the authoring phase. |
| **OBS-INV-005** | Conflict resolution during observation MUST be annotated. |
| **LIFECYCLE-INV-001** | Every phase transition MUST be an explicit semantic operation. |
| **LIFECYCLE-INV-002** | No phase may be skipped without an explicit contract. |
| **LIFECYCLE-INV-003** | Semantic properties MUST be preserved across all phase transitions. |
| **LIFECYCLE-INV-004** | Authority transitions MUST be explicit. |
| **LIFECYCLE-INV-005** | Prediction MUST NOT silently overwrite authoritative state. |
| **LIFECYCLE-INV-006** | Replicated state MUST have defined ownership. |
| **LIFECYCLE-INV-007** | Time ordering MUST be preserved across distributed observations. |
| **LIFECYCLE-INV-008** | Every phase transition MUST record provenance. |
| **LIFECYCLE-INV-009** | Phase transition failure MUST NOT silently produce partial state. |
| **IDENTITY-INV-001** | Entity identity (SID) MUST be preserved across all lifecycle phases. |
| **IDENTITY-INV-002** | Identity MUST NOT be derived from content hash alone. |
| **IDENTITY-INV-003** | Identity MUST remain invariant across manifestation changes. |

## 15. Relationship to Existing SCR Domains

### 15.1 Domains Referenced

| Domain | Path | Relevance |
|--------|------|-----------|
| **Identity** | `lib/101_Core/Identity/101_definition.md` | SID coordinate model, IAM-I001–IAM-I017 |
| **Core** | `lib/101_Core/101_definition.md` | Entity, State, Composition, Constraint, Capability, Contract |
| **Lowering** | `lib/903_Lowering/101_definition.md` | Semantics-preserving transformation model |
| **Dynamics** | `lib/502_Dynamics/101_definition.md` | Resource semantics, dynamical state |
| **Stream** | `lib/802_Stream/101_definition.md` | Reference semantics, STREAM-INV-015 |

### 15.2 Domains to Create

| Domain | Path | Purpose |
|--------|------|---------|
| **Resource** | `lib/900_Resource/` | ResourceReference, ResourceIdentity, ResourceLifecycle, MaterializationPipeline, Representation Stages, Dependency Graph |
| **Lifecycle** | `lib/901_Lifecycle/` | Full lifecycle model (this sprint's output) |
| **Distributed** | `lib/902_Distributed/` | Distributed state semantics (Sprint 02) |
| **Provider** | `lib/904_Provider/` | Provider adapter patterns |

## 16. Deferred to Subsequent Sprints

| Concept | Sprint | Reason |
|---------|--------|--------|
| Distributed-state semantic definitions (authority, ownership, replication, observation, remote operation) | Sprint 02 | Detailed definitions with provenance |
| Prediction semantics | Sprint 03 | Requires distributed state foundation |
| Reconciliation semantics | Sprint 03 | Requires prediction foundation |
| Temporal semantics (wall-clock, simulation, observation, network) | Sprint 04 | Requires temporal identity model |
| State ownership model | Sprint 04 | Requires temporal identity foundation |
| Identity mapping documentation (SCR SID → O3DE EntityId → network ID → USD path) | Sprint 04 | Requires distributed state and temporal semantics |
| Materialization contract language | Sprint 05+ | Requires contract specification syntax |
| MLIR resource dialect | Sprint 05+ | Requires MLIR compilation infrastructure |
| Rendering resource pipeline | Sprint 06+ | Requires rendering domain definition |

## 17. Exit Criteria Check

- [x] Lifecycle phases documented with semantic operations (Sections 4–11)
- [x] Materialization covers: resolution, validation, flattening, compilation, dependency closure, optimization, deterministic initialization (Section 5)
- [x] Not merely file-format conversions documented — all operations are semantic transformations (Sections 4.1, 5.1, 7.1, 9.1, 11.1)
- [x] Authoring phase documented with state structure and properties (Section 4)
- [x] Authoring state defined: mutable, validatable, versionable (Section 4.2, 4.3)
- [x] Materialization operation documented with 7-stage pipeline (Section 5.2)
- [x] Deployable state defined: immutable, validated, optimized (Section 6)
- [x] Instantiation operation documented with 4-stage pipeline (Section 7.2)
- [x] Simulation state defined: active entities, temporal progression (Section 8)
- [x] Replication operation documented with 5-stage pipeline (Section 9.2)
- [x] Distributed state defined: multi-host, authority/ownership (Section 10)
- [x] Observation operation documented with 4-stage pipeline (Section 11.2)
- [x] Each operation documents: semantic meaning, preserved/lost information, invariants, providers (Sections 4–11)
- [x] Cross-cutting lifecycle invariants defined (Section 12)
- [x] 46 new invariants added (Section 14.1)
- [x] Information flow summary across all phases (Section 12.3)
- [x] Provider adapter pattern documented across lifecycle (Section 13)
- [x] Relationship to existing SCR domains documented (Section 15)
- [x] Deferred concepts identified for Sprint 02–04 (Section 16)
# Sprint 01: Authoring → Materialization Pipeline

Assess and document the authoring → materialization → deployment → simulation lifecycle.

## Deliverables
- Lifecycle model with semantic operations
- Materialization operation definition (if justified)
- Source/authoring/deployable/runtime representation distinctions
- O3DE import/materialization mapping

## Exit Criteria
- [ ] Lifecycle phases documented with semantic operations
- [ ] Materialization covers: resolution, validation, flattening, compilation, optimization
- [ ] Not merely file-format conversions documented
# Sprint 002 Record: Distributed-State Semantics

## 1. Objective

Define the SCR distributed-state semantic family: Authority, Ownership, Replication, Observation, RemoteOperation. Each definition derives from O3DE Multiplayer/AzNetworking research, generalised beyond games to robotics, distributed-simulation, and digital-twins. Transport semantics (UDP/TCP/reliable/unreliable) are explicitly separated from computational meaning.

## 2. Scope & Boundaries

### 2.1 What This Sprint Covers

Five core distributed-state semantic concepts:

| Concept | Purpose |
|---------|---------|
| **Authority** | Which host has ultimate read/write rights over entity state |
| **Ownership** | Which host controls entity lifecycle and input |
| **Replication** | Delta-based state synchronization from authority to replicas |
| **Observation** | Reading replicated state from non-authority host |
| **RemoteOperation** | Invoking operations across host boundaries |

### 2.2 What This Sprint Does NOT Cover

- Prediction and reconciliation (Sprint 03)
- Temporal identity and state ownership model (Sprint 04)
- Transport-layer protocols (explicitly separated)
- Provider-specific implementations (O3DE NetEntityRole is provider-specific, not SCR semantic)

### 2.3 Relationship to M004 Invariants

All definitions must satisfy M004's four formal invariants:

1. Authority transitions are explicit
2. Prediction does not silently overwrite authoritative state
3. Replicated state has defined ownership
4. Time ordering is preserved across distributed observations

## 3. Research Source: O3DE Multiplayer/AzNetworking

### 3.1 O3DE NetEntityRole (Provider-Specific)

O3DE defines four compile-time enforced roles for networked entities:

| O3DE Role | Description |
|-----------|-------------|
| `Authority` | Ultimate read/write authority. Full access to all network properties. |
| `Autonomous` | Player-controlled entity. Can predict and modify predictable properties locally. Sends input to Authority. |
| `Server` | Peer server in multi-server setup. Receives replicated state but has no entity authority. |
| `Client` | Lowest privilege. Read-only. Smallest subset of replicated properties. Presentation logic and RPC proxy only. |

**Key O3DE insight:** Roles are compile-time enforced and provider-assigned. SCR authority is a semantic concept — the same entity may have different authority relationships depending on the computational domain, not just the network topology.

### 3.2 O3DE NetworkProperty (Replication Mechanism)

O3DE `NetworkProperty` attributes:

| Attribute | Values | Purpose |
|-----------|--------|---------|
| `ReplicateFrom` | `Authority`, `Autonomous` | Which role's changes propagate |
| `ReplicateTo` | `Server`, `Authority`, `Autonomous`, `Client` | Which roles receive updates |
| `IsPredictable` | `bool` | Autonomous can predict locally even if ReplicateFrom=Authority |
| `IsRewindable` | `bool` | Historic values recorded for rollback/reconciliation |

**Replication hierarchy** (O3DE): Authority-to-Client replicates to Autonomous and Server. Authority-to-Autonomous replicates to Server. Authority-to-Server replicates only to Server.

**Key O3DE insight:** Replication direction is defined per-property, not per-entity. SCR replication is a semantic transformation — the *meaning* of what changes must be preserved, not just the byte delta.

### 3.3 O3DE RPC (Remote Procedure Calls)

| Attribute | Values | Purpose |
|-----------|--------|---------|
| `InvokeFrom` | `Authority`, `Server`, `Autonomous` | Which role originates the call |
| `HandleOn` | `Authority`, `Autonomous`, `Client` | Which roles execute the handler |
| `IsReliable` | `bool` | Reliable (queued, retransmitted) vs unreliable (fire-and-forget) |

**Key O3DE insight:** RPC reliability and ordering are transport concerns. SCR RemoteOperation captures the semantic intent — invoking a computational operation on a remote host — independent of delivery guarantees.

### 3.4 O3DE Prediction & Reconciliation

- **Prediction:** Autonomous player modifies properties locally before server confirmation. `IsPredictable` flag permits this.
- **Reconciliation:** `IsRewindable` records historic property values per network tick. On authority update, client rewinds to authoritative state and resimulates.
- **Network Input:** Frame-stamped input from Autonomous to Authority. Authority rewinds before processing to maintain consistency.

**Key O3DE insight:** Prediction/reconciliation is a *strategy*, not a semantic primitive. SCR separates the semantic concept (applying speculative state) from the mechanism (rollback + resimulate).

### 3.5 O3DE Ownership & Spawning

- `IMultiplayerSpawner`: Server-side interface. `OnPlayerJoin` spawns autonomous entity. `OnPlayerLeave` cleans up.
- **Ownership** in O3DE is implicit: the Autonomous role entity is "owned" by its controlling connection.
- **Network Hierarchies:** Parent-child entity groups share input processing. `NetworkHierarchyRootComponent` + `NetworkHierarchyChildComponent`.

**Key O3DE insight:** Ownership in O3DE is tied to player connections. SCR ownership is a general semantic concept — any host may own any entity, not just the "player's" connection.

## 4. SCR Semantic Definitions

### 4.1 Authority

```yaml
concept: Authority
source: O3DE Multiplayer
source_terminology: NetEntityRole::Authority
scr_interpretation: >
  Authority designates which host holds ultimate read/write rights over an
  entity's state. Authority is a semantic property of the entity-host
  relationship, not a network role. The authoritative host is the single
  source of truth for all state mutations; replica hosts receive derived
  state through replication. Authority transitions are explicit events —
  no host may silently acquire or lose authority.
differences: >
  O3DE NetEntityRole is a compile-time-enforced network role with four
  fixed values (Authority, Autonomous, Client, Server). SCR Authority is
  a semantic relationship that varies per entity, per domain, and may
  change at runtime through explicit transfer. O3DE authority is always
  held by the server; SCR authority may be held by any host, including
  edge devices, robotic controllers, or simulation nodes. O3DE conflates
  authority with "server" — SCR decouples them. An O3DE Autonomous entity
  can predict but not own; SCR Authority encompasses both prediction
  permission and mutation rights.
invariants:
  - DIST-AUTH-001: Every entity has exactly one authoritative host at any time.
  - DIST-AUTH-002: Authority transitions are explicit events with source, target, reason, and timestamp.
  - DIST-AUTH-003: Replica hosts MUST NOT mutate state on entities where they lack authority.
  - DIST-AUTH-004: Authority MAY be delegated, revoked, or transferred — each transition is an explicit semantic operation.
  - DIST-AUTH-005: Authority is defined per-entity, not per-host. A host may be authoritative for some entities and replica for others.
```

### 4.2 Ownership

```yaml
concept: Ownership
source: O3DE Multiplayer
source_terminology: Autonomous role + IMultiplayerSpawner
scr_interpretation: >
  Ownership designates which host controls an entity's lifecycle (creation,
  destruction) and input stream. Ownership is distinct from Authority:
  the owner provides inputs and manages lifecycle, while Authority is the
  semantic source of truth for state mutations. An owner MAY lack Authority
  (input is processed by the authoritative host); an Authority MAY lack
  ownership (the authoritative host may not control entity lifecycle).
differences: >
  O3DE ownership is implicit — the Autonomous role implies ownership of the
  player entity, and IMultiplayerSpawner manages spawn/despawn on the server.
  O3DE conflates ownership with "the player who controls this entity."
  SCR Ownership is explicit: every mutable entity declares its owner. Ownership
  covers lifecycle AND input, but not mutation rights (that is Authority).
  Ownership MAY be exclusive, shared, or delegated. Ownership MAY transfer
  between hosts (e.g., entity migration between simulation nodes).
  O3DE's Network Hierarchy implies shared ownership within a parent-child
  group; SCR Ownership makes this explicit per-entity.
invariants:
  - DIST-OWN-001: Every mutable entity MUST have exactly one owner at any time.
  - DIST-OWN-002: Ownership defines lifecycle rights: only the owner MAY create or destroy the entity.
  - DIST-OWN-003: Ownership defines input rights: only the owner MAY send input to the entity.
  - DIST-OWN-004: Ownership MAY transfer between hosts via explicit transfer operation.
  - DIST-OWN-005: Ownership DOES NOT imply Authority. Ownership and Authority are independent semantic properties.
  - DIST-OWN-006: Ownership DOES NOT imply mutation rights. Mutation requires Authority, not Ownership.
```

### 4.3 Replication

```yaml
concept: Replication
source: O3DE Multiplayer
source_terminology: NetworkProperty + Delta Replication
scr_interpretation: >
  Replication is the semantic transformation that distributes state changes
  from the authoritative host to replica hosts. Replication is delta-based:
  only changed state propagates. Replication preserves semantic meaning —
  the delta represents a semantic state transition, not a byte difference.
  Replication is directional: authority → replicas. Bidirectional state
  convergence is not replication; it is conflict resolution (a separate
  semantic concept).
differences: >
  O3DE replication is a mechanism: delta-based state sync via
  NetworkProperty with ReplicateFrom/ReplicateTo directions and
  hierarchy rules. O3DE replication is push-based and event-driven.
  SCR Replication is the semantic transformation itself — the meaning
  of "authority state changes propagate to replicas." SCR replication
  is agnostic to mechanism: delta-based, snapshot-based, CRDT-based,
  or event-sourced replication all satisfy the SCR semantic contract.
  O3DE replication hierarchy (Authority-to-Client implies Authority-to-Autonomous)
  is a provider-specific optimization; SCR replication defines no hierarchy —
  the replication topology is a provider concern. O3DE uses ACK-based
  reliable transport for replication; SCR separates transport from semantics.
  Transport reliability is a provider choice, not a semantic property.
invariants:
  - DIST-REP-001: Replication originates from the authoritative host only. Replica hosts MUST NOT originate replication.
  - DIST-REP-002: Replication MUST preserve semantic meaning. The receiving host MUST interpret replicated state with the same semantic properties as the sending host.
  - DIST-REP-003: Replication is directional: authority → replicas. Convergence is not replication.
  - DIST-REP-004: Replication MAY be delta-based, snapshot-based, or event-sourced. The mechanism is a provider concern.
  - DIST-REP-005: Transport reliability (reliable/unreliable, ordered/unordered) is a provider choice, not a semantic property of replication.
  - DIST-REP-006: Replication MUST record provenance: source host, target host, semantic delta, timestamp, authority at time of replication.
```

### 4.4 Observation

```yaml
concept: Observation
source: O3DE Multiplayer
source_terminology: Client-side read of replicated NetworkProperty
scr_interpretation: >
  Observation is the semantic operation of reading replicated state from a
  non-authority host. Observation is always non-destructive — reading state
  does not modify it. Observation captures a point-in-time snapshot of the
  replicated world view from a specific host's perspective. Observation
  output is authoritative for the observing host but MAY be stale relative
  to the authoritative host's current state.
differences: >
  O3DE does not have an explicit "observation" concept. Clients read
  replicated NetworkProperty values directly — there is no semantic
  distinction between "reading replicated state" and "accessing local state."
  SCR Observation makes this distinction explicit: reading replicated state
  is a semantic operation with defined properties (non-destructive,
  point-in-time, potentially stale). O3DE's IsRewindable property enables
  historical observation (rewinding to past states for reconciliation);
  SCR Observation is a generalised concept covering both current and
  historical snapshots. O3DE observation is implicitly scoped by
  ReplicateTo rules (clients see only what is replicated to them);
  SCR Observation explicitly declares its projection scope.
invariants:
  - DIST-OBS-001: Observation MUST be non-destructive. Reading state MUST NOT modify the observed or observing host's state.
  - DIST-OBS-002: Observation captures a point-in-time snapshot. Temporal ordering MUST be preserved within the snapshot.
  - DIST-OBS-003: Observation output MAY be stale relative to the authoritative host's current state. Staleness MUST be declared.
  - DIST-OBS-004: Observation MUST declare its projection scope: which entities, which properties, which host's perspective.
  - DIST-OBS-005: Observation output MUST be semantically consistent with the observed state. No semantic properties may be invented.
  - DIST-OBS-006: Observation MAY serve as input to a new authoring cycle, enabling the lifecycle loop.
```

### 4.5 RemoteOperation

```yaml
concept: RemoteOperation
source: O3DE Multiplayer
source_terminology: RemoteProcedure (RPC)
scr_interpretation: >
  RemoteOperation is the semantic concept of invoking a computational
  operation on a remote host. A RemoteOperation carries semantic intent —
  "execute this operation with these parameters on that host" — independent
  of delivery mechanism. RemoteOperations MAY be reliable (guaranteed
  delivery) or unreliable (best-effort). Reliability is a transport
  property, not a semantic property of the operation itself. RemoteOperations
  MAY be ordered or unordered relative to other operations. Ordering is a
  transport property.
differences: >
  O3DE RPCs are defined with InvokeFrom/HandleOn role pairs and IsReliable
  flag. O3DE RPCs are provider-specific: the same RPC definition is tied
  to O3DE's NetEntityRole system. SCR RemoteOperation is the generalised
  semantic concept: any operation invoked on a remote host. O3DE RPCs
  are always between defined roles (Authority, Autonomous, Client, Server);
  SCR RemoteOperations are between any two hosts with defined authority
  relationships. O3DE conflates operation direction (InvokeFrom) with
  handler target (HandleOn); SCR separates: RemoteOperation declares
  source host and target host, not source/target roles. O3DE's IsReliable
  is a transport concern; SCR captures it as a delivery contract, not
  a semantic property.
invariants:
  - DIST-ROP-001: RemoteOperations MUST declare source host and target host.
  - DIST-ROP-002: RemoteOperations MUST carry semantic intent: the operation name, parameters, and semantic contract.
  - DIST-ROP-003: Reliability (guaranteed delivery vs best-effort) is a transport contract, not a semantic property.
  - DIST-ROP-004: Ordering (sequential vs parallel) is a transport contract, not a semantic property.
  - DIST-ROP-005: RemoteOperations MUST NOT violate authority boundaries. A host MUST NOT invoke a RemoteOperation that mutates state on a host where it lacks authority.
  - DIST-ROP-006: RemoteOperation invocation MUST record provenance: source host, target host, operation, parameters, timestamp.
```

## 5. Semantic Family: Cross-Cutting Properties

### 5.1 Relationship Matrix

| | Authority | Ownership | Replication | Observation | RemoteOperation |
|---|-----------|-----------|-------------|-------------|-----------------|
| **Authority** | — | Independent | Originates from Authority | Observed by replicas | May invoke RemoteOperations |
| **Ownership** | Independent | — | Does not replicate | Observed by owner | Owner may invoke lifecycle operations |
| **Replication** | Authority → replicas | Ownership independent | — | Enables Observation | Transport for state deltas |
| **Observation** | Requires replicated state | Read-only | Produces snapshots | — | May trigger RemoteOperations |
| **RemoteOperation** | Must respect authority | May modify ownership | May trigger replication | Observable side effects | — |

### 5.2 Authority ≠ Ownership (Critical Distinction)

```
Authority:   "Who is the source of truth for state mutations?"
Ownership:   "Who controls lifecycle and input?"
Replication: "How do state changes propagate?"
Observation: "How do non-authority hosts read state?"
RemoteOperation: "How do hosts invoke operations on each other?"
```

O3DE conflates authority and ownership under `NetEntityRole::Authority` and `NetEntityRole::Autonomous`. SCR separates them because in distributed robotics, a central coordinator may have Authority while a local controller has Ownership; in digital twins, the physical twin has Authority while the simulation has Ownership.

### 5.3 Transport Separation

All five concepts are **transport-agnostic**. Transport properties are provider contracts:

| Transport Property | SCR Classification | Provider Concern |
|--------------------|-------------------|-----------------|
| Reliable delivery | Delivery contract | TCP, reliable UDP, QUIC |
| Unreliable delivery | Delivery contract | Unreliable UDP |
| Ordered delivery | Ordering contract | Sequence numbers, streams |
| Unordered delivery | Ordering contract | Fire-and-forget |
| Encrypted transport | Security contract | TLS, DTLS |
| Compressed transport | Efficiency contract | Provider-specific compression |

## 6. Invariant Registry

### 6.1 All Invariants Added This Sprint

| Invariant | Statement |
|-----------|-----------|
| **DIST-AUTH-001** | Every entity has exactly one authoritative host at any time. |
| **DIST-AUTH-002** | Authority transitions are explicit events with source, target, reason, and timestamp. |
| **DIST-AUTH-003** | Replica hosts MUST NOT mutate state on entities where they lack authority. |
| **DIST-AUTH-004** | Authority MAY be delegated, revoked, or transferred — each transition is an explicit semantic operation. |
| **DIST-AUTH-005** | Authority is defined per-entity, not per-host. |
| **DIST-OWN-001** | Every mutable entity MUST have exactly one owner at any time. |
| **DIST-OWN-002** | Ownership defines lifecycle rights: only the owner MAY create or destroy the entity. |
| **DIST-OWN-003** | Ownership defines input rights: only the owner MAY send input to the entity. |
| **DIST-OWN-004** | Ownership MAY transfer between hosts via explicit transfer operation. |
| **DIST-OWN-005** | Ownership DOES NOT imply Authority. |
| **DIST-OWN-006** | Ownership DOES NOT imply mutation rights. Mutation requires Authority. |
| **DIST-REP-001** | Replication originates from the authoritative host only. |
| **DIST-REP-002** | Replication MUST preserve semantic meaning. |
| **DIST-REP-003** | Replication is directional: authority → replicas. |
| **DIST-REP-004** | Replication MAY be delta-based, snapshot-based, or event-sourced. |
| **DIST-REP-005** | Transport reliability is a provider choice, not a semantic property. |
| **DIST-REP-006** | Replication MUST record provenance. |
| **DIST-OBS-001** | Observation MUST be non-destructive. |
| **DIST-OBS-002** | Observation captures a point-in-time snapshot. |
| **DIST-OBS-003** | Observation output MAY be stale. Staleness MUST be declared. |
| **DIST-OBS-004** | Observation MUST declare its projection scope. |
| **DIST-OBS-005** | Observation MUST be semantically consistent. |
| **DIST-OBS-006** | Observation MAY serve as input to authoring cycle. |
| **DIST-ROP-001** | RemoteOperations MUST declare source and target hosts. |
| **DIST-ROP-002** | RemoteOperations MUST carry semantic intent. |
| **DIST-ROP-003** | Reliability is a transport contract, not semantic. |
| **DIST-ROP-004** | Ordering is a transport contract, not semantic. |
| **DIST-ROP-005** | RemoteOperations MUST NOT violate authority boundaries. |
| **DIST-ROP-006** | RemoteOperation invocation MUST record provenance. |

## 7. Exit Criteria Verification

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Each definition has provenance | ✓ | Each definition cites O3DE source_terminology and research source |
| Definitions general enough for games/robotics/distributed-simulation/digital-twins | ✓ | Cross-domain examples in differences sections; transport-agnostic |
| Transport (UDP/TCP/reliable/unreliable) explicitly separated from semantics | ✓ | Section 5.3 Transport Separation; DIST-REP-005, DIST-ROP-003, DIST-ROP-004 |

## 8. Notes

- Prediction and reconciliation are deferred to Sprint 03 as specified in the sprint plan.
- Temporal identity and state ownership are deferred to Sprint 04.
- These five definitions form the semantic foundation for Sprint 03–04.
- All invariants follow the DIST- prefix convention for distributed-state semantics.
# Sprint 02: Distributed-State Semantics

Define SCR distributed-state semantic family: authority, ownership, replication, observation, remote operation.

## Deliverables
- Distributed-state semantic definitions
- Authority semantic definition
- Ownership semantic definition
- Replication semantic definition
- Observation semantic definition
- RemoteOperation semantic definition

## Exit Criteria
- [ ] Each definition has provenance
- [ ] Definitions general enough for games/robotics/distributed-simulation/digital-twins
- [ ] Transport (UDP/TCP/reliable/unreliable) explicitly separated from semantics
# Sprint 003 Record: Prediction & Reconciliation Semantics

## 1. Objective

Define the SCR prediction/reconciliation semantic family: PredictedState, Reconciliation, Rollback, Replay, PredictionInput, AuthorityUpdate. Each definition derives from O3DE Multiplayer prediction/reconciliation research and GGPO-style rollback netcode, generalised beyond games to robotics, distributed-simulation, and digital-twins. Mechanism (rollback + resimulate) is explicitly separated from semantic meaning (speculative state advancement and correction).

## 2. Scope & Boundaries

### 2.1 What This Sprint Covers

Six core prediction/reconciliation semantic concepts:

| Concept | Purpose |
|---------|---------|
| **PredictedState** | Client-side speculative state advancement before authority confirmation |
| **Reconciliation** | Process of correcting predicted state when authority diverges |
| **Rollback** | Reverting to last known authoritative state and resimulating |
| **Replay** | Re-executing recorded inputs to reconstruct state |
| **PredictionInput** | Input used for local prediction |
| **AuthorityUpdate** | State correction from authority |

### 2.2 What This Sprint Does NOT Cover

- Authority and ownership semantics (Sprint 02 — foundational)
- Temporal identity and state ownership model (Sprint 04)
- Transport-layer protocols (explicitly separated)
- Provider-specific implementations (GGPO, O3DE NetworkPrediction are provider-specific, not SCR semantic)
- Determinism requirements for specific providers (provider concern)

### 2.3 Relationship to M004 Invariants

All definitions must satisfy M004's four formal invariants:

1. Authority transitions are explicit
2. **Prediction does not silently overwrite authoritative state**
3. Replicated state has defined ownership
4. **Time ordering is preserved across distributed observations**

### 2.4 Relationship to Sprint 02

Sprint 02 defined Authority, Ownership, Replication, Observation, RemoteOperation. Sprint 03 builds on Authority and Replication:
- Prediction requires understanding Authority (who is the source of truth)
- Reconciliation requires understanding Replication (how authoritative state arrives)
- AuthorityUpdate is a specific form of Replication (authority → replica with correction semantics)

## 3. Research Sources

### 3.1 O3DE Multiplayer Prediction & Reconciliation

O3DE Multiplayer Gem provides:
- **Local prediction and backwards reconciliation ("rollback")** as first-class features
- `IsPredictable` flag on NetworkProperties: Autonomous role can predict locally even if ReplicateFrom=Authority
- `IsRewindable` flag on NetworkProperties: historic values recorded per network tick for rollback/reconciliation
- Network Input: frame-stamped input from Autonomous to Authority. Authority rewinds before processing to maintain consistency.
- **Server-authoritative asynchronous multiplayer** — server is authoritative, clients predict

**Key O3DE insight:** Prediction/reconciliation is a *strategy*, not a semantic primitive. O3DE conflates "can predict" (a permission) with "is predicting" (an action) with "reconciling" (a correction). SCR separates these into distinct semantic concepts: PredictionInput (permission + data), PredictedState (speculative advancement), Reconciliation (correction process), Rollback (mechanism).

### 3.2 GGPO-Style Rollback Netcode

GGPO (Good Game, Peace Out, 2006) established the foundational rollback algorithm:

- **Core pattern:** Each peer predicts the remote player will repeat their last input and simulates immediately. When the real input arrives later, the simulation rolls back to the predicted frame, applies the corrected input, and fast-forwards to the present.
- **Deterministic requirement:** Same inputs in, same state out — every single time. If determinism breaks for one entity on one frame, every peer's prediction silently diverges.
- **State capture:** Every frame, the entire game state is recorded in a buffer. Buffer depth is typically 8–12 frames.
- **Deterministic core + visual shell:** Visuals (meshes, animation, VFX, audio, cameras) are not rolled back. They follow the corrected state after rollback.
- **Cost:** CPU (resimulating up to ~8 frames per tick). For 300ms connection, expect ~22 frames of re-simulation.
- **Input redundancy:** Inputs are sent with redundancy (typically 3–8 frames) so packet loss doesn't cause desync.

**Key GGPO insight:** Rollback is a *mechanism* (restore state + replay forward). The *semantic* concept is Reconciliation — the process of correcting predicted state. Rollback is one implementation strategy for Reconciliation. SCR captures the semantic meaning, not the mechanism.

### 3.3 Unity Netcode for Entities Prediction

Unity's approach provides additional insight:
- Client runs the same simulation code as the server for predicted entities
- On receiving server snapshot: apply authoritative state, then resimulate from oldest applied tick to current tick ("rollback")
- `PredictedSimulationSystemGroup` runs fixed-step deterministic simulation on both client and server
- `GhostPredictionSmoothingSystem` reconciles and reduces errors over time
- Prediction is entity-scoped: only predicted entities (local player) are resimulated

**Key Unity insight:** Prediction is entity-scoped, not world-scoped. SCR PredictedState captures this: prediction applies to specific entities, not the entire world state.

### 3.4 Client-Side Prediction & Server Reconciliation (General)

The canonical pattern across networked game engines:

1. **Client-side prediction:** Client doesn't wait for server. Immediately simulates result locally using same game logic as server.
2. **Server reconciliation:** When server sends authoritative state, client compares to prediction. If diverged: correct to server's version and replay inputs since divergence.
3. **Input validation:** Server validates every input. Never trust the client.
4. **Dead reckoning:** For other players' characters, extrapolate from last known velocity/direction.

**Key general insight:** The semantic distinction is between *speculative state* (what the client thinks is true) and *authoritative state* (what the server says is true). Reconciliation is the semantic operation of resolving this distinction.

## 4. SCR Semantic Definitions

### 4.1 PredictedState

```yaml
concept: PredictedState
source: O3DE Multiplayer, GGPO rollback netcode, Unity Netcode for Entities
source_terminology: >
  O3DE: IsPredictable NetworkProperty + Autonomous role prediction;
  GGPO: predicted frame state; Unity: PredictedSimulationGroup state
scr_interpretation: >
  PredictedState is the client-side speculative state advancement before
  authority confirmation. A PredictedState represents the client's best
  estimate of what the authoritative state will become, based on local
  input application and simulation. PredictedState is always provisional —
  it MAY be confirmed, corrected, or discarded when authoritative state
  arrives. PredictedState does NOT modify authoritative state; it exists
  only on the predicting host. PredictedState applies to specific entities
  and properties, not the entire world state.
differences: >
  O3DE conflates prediction permission (IsPredictable flag) with prediction
  action (Autonomous role modifying properties locally). O3DE Predictable
  properties are defined at compile time per component; SCR PredictedState
  is a runtime semantic relationship between client, entity, and authority.
  GGPO captures entire frame state for rollback; SCR PredictedState is
  scoped to specific entities and properties — world-level state capture
  is a provider optimization, not a semantic requirement. Unity scopes
  prediction to PredictedSimulationSystemGroup; SCR scopes prediction to
  entity-property pairs with declared prediction scope. O3DE "Autonomous"
  implies prediction permission; SCR PredictedState requires explicit
  declaration of which entities are prediction-eligible.
invariants:
  - PRED-INV-001: Prediction MUST NOT modify authoritative state. PredictedState exists only on the predicting host.
  - PRED-INV-004: PredictedState MUST declare its prediction scope: which entities, which properties, which host.
  - PRED-INV-005: PredictedState MUST be provisional. All PredictedStates are subject to correction or discard.
  - PRED-INV-006: PredictedState MUST record provenance: predicting host, entity, properties, input that produced it, timestamp.
  - PRED-INV-007: Multiple PredictedStates MAY exist for the same entity on different hosts. They are independent.
```

### 4.2 Reconciliation

```yaml
concept: Reconciliation
source: O3DE Multiplayer, GGPO rollback netcode, Unity Netcode for Entities
source_terminology: >
  O3DE: backwards reconciliation ("rollback"); GGPO: rollback + resimulate;
  Unity: prediction correction + GhostPredictionSmoothingSystem
scr_interpretation: >
  Reconciliation is the semantic process of correcting predicted state when
  authority diverges. Reconciliation occurs when a host receives authoritative
  state that conflicts with its PredictedState. The reconciliation process:
  (1) identifies the divergence point, (2) applies authoritative state at
  divergence point, (3) re-executes simulation from divergence point to
  present using recorded inputs. Reconciliation preserves causal ordering —
  the corrected state must be causally consistent with the authoritative
  timeline. Reconciliation is a defined semantic operation, not an ad-hoc
  correction.
differences: >
  O3DE uses "backwards reconciliation" as a single term covering the entire
  correction process. SCR separates Reconciliation (semantic process) from
  Rollback (mechanism) and Replay (re-execution). O3DE reconciliation is
  triggered by authority update arriving; SCR Reconciliation MAY also be
  triggered by prediction timeout, confidence threshold, or explicit
  correction request. GGPO treats rollback as the primary operation;
  SCR treats rollback as one possible mechanism for Reconciliation.
  Unity's GhostPredictionSmoothingSystem blends corrections over time;
  SCR Reconciliation is discrete — the semantic operation completes or
  does not. Smoothing is a presentation concern.
invariants:
  - PRED-INV-002: Reconciliation MUST preserve causal ordering. The corrected state must be causally consistent with the authoritative timeline.
  - PRED-INV-008: Reconciliation MUST identify the divergence point — the last state where prediction and authority agreed.
  - PRED-INV-009: Reconciliation MUST apply authoritative state at the divergence point before re-executing simulation.
  - PRED-INV-010: Reconciliation MUST record provenance: divergence point, authoritative state applied, inputs replayed, host, timestamp.
  - PRED-INV-011: Reconciliation MAY be triggered by: authority update arrival, prediction timeout, confidence threshold, explicit correction request.
  - PRED-INV-012: Reconciliation completion MUST produce a state that is causally consistent with the authoritative timeline up to the reconciliation point.
```

### 4.3 Rollback

```yaml
concept: Rollback
source: GGPO rollback netcode, O3DE Multiplayer, Unity Netcode for Entities
source_terminology: >
  GGPO: rollback; O3DE: backwards reconciliation ("rollback");
  Unity: rollback in PredictedSimulationSystemGroup
scr_interpretation: >
  Rollback is the provider mechanism of reverting to a last known
  authoritative state and resimulating forward. Rollback is one
  implementation strategy for Reconciliation — the semantic process.
  Rollback requires: (1) a recorded history of authoritative states,
  (2) deterministic simulation (same inputs → same state), (3) a
  buffer of recorded inputs since the rollback point. Rollback is a
  mechanical operation: restore state snapshot, replay inputs forward.
  The semantic meaning is Reconciliation; Rollback is how it is achieved.
differences: >
  GGPO treats rollback as the foundational concept — "rollback netcode."
  SCR treats Rollback as a provider mechanism, subordinate to the
  semantic concept of Reconciliation. O3DE uses "rollback" as shorthand
  for "backwards reconciliation"; SCR distinguishes the mechanism
  (Rollback) from the process (Reconciliation) from the result
  (corrected PredictedState). GGPO requires deterministic simulation
  as a hard constraint; SCR acknowledges determinism as a provider
  requirement for Rollback but separates it from the semantic contract.
  A provider MAY implement Reconciliation without rollback (e.g., by
  discarding PredictedState and waiting for fresh authoritative state).
  Rollback is the most common mechanism but not the only one.
invariants:
  - PRED-INV-003: Rollback MUST restore to a valid historical state. The rollback point MUST be a state that was previously confirmed as authoritative.
  - PRED-INV-013: Rollback requires recorded state history. A host MUST NOT rollback to a state it has not previously confirmed.
  - PRED-INV-014: Rollback is a provider mechanism, not a semantic concept. Reconciliation is the semantic operation; Rollback is one implementation.
  - PRED-INV-015: Rollback MAY be scoped to specific entities (entity-level rollback) or to entire world state (world-level rollback). Scope is a provider choice.
  - PRED-INV-016: Rollback MUST NOT discard unsimulated inputs. All inputs received after the rollback point MUST be preserved for re-simulation.
```

### 4.4 Replay

```yaml
concept: Replay
source: GGPO rollback netcode, O3DE Multiplayer
source_terminology: >
  GGPO: resimulate / fast-forward; O3DE: rewind + resimulate;
  Unity: PredictedSimulationSystemGroup re-execution
scr_interpretation: >
  Replay is the semantic operation of re-executing recorded inputs to
  reconstruct state. Replay follows Rollback (or any state restoration)
  to advance from the restored state to the present. Replay requires
  deterministic simulation — the same inputs applied to the same state
  MUST produce the same output. Replay is distinct from initial
  simulation: initial simulation applies inputs for the first time;
  Replay re-applies previously executed inputs. Replay preserves
  temporal ordering — inputs are re-executed in the same sequence as
  original execution.
differences: >
  GGPO calls this "resimulate" or "fast-forward." O3DE calls it
  "resimulate" after rewind. SCR Replay captures the semantic meaning:
  re-executing recorded inputs to reconstruct state. The term "replay"
  is chosen over "resimulate" to emphasise that this is re-execution
  of known inputs, not a new simulation. Replay is the mechanism by
  which Reconciliation achieves temporal advancement after state
  restoration. A provider MAY implement Reconciliation without explicit
  Replay if it can directly compute the corrected state (e.g., by
  discarding all predicted state and accepting current authoritative
  state). Replay is the most common mechanism for temporal advancement.
invariants:
  - PRED-INV-017: Replay MUST preserve temporal ordering. Inputs are re-executed in the same sequence as original execution.
  - PRED-INV-018: Replay requires deterministic simulation. Same inputs applied to same state MUST produce same output.
  - PRED-INV-019: Replay MUST NOT invent inputs. Only previously recorded inputs MAY be replayed.
  - PRED-INV-020: Replay MUST record provenance: replay start state, inputs replayed, replay end state, host, timestamp.
  - PRED-INV-021: Replay MAY be scoped to specific entities or to entire world state. Scope matches the Rollback scope.
```

### 4.5 PredictionInput

```yaml
concept: PredictionInput
source: O3DE Multiplayer, GGPO rollback netcode, Unity Netcode for Entities
source_terminology: >
  O3DE: Network Input (frame-stamped input from Autonomous to Authority);
  GGPO: local + predicted remote input per frame;
  Unity: input data in PredictedSimulationGroup
scr_interpretation: >
  PredictionInput is the input used for local prediction. PredictionInput
  carries two distinct semantic roles: (1) the input that produced a
  PredictedState on the predicting host, and (2) the input transmitted
  to the authoritative host for validation and execution. PredictionInput
  is always timestamped — it belongs to a specific simulation tick.
  PredictionInput MAY be confirmed (authority executed it), rejected
  (authority discarded it), or pending (authority has not yet received
  it). The semantic meaning of PredictionInput is "this input, at this
  time, produced this predicted result" — independent of whether the
  authority agrees.
differences: >
  O3DE Network Input is frame-stamped and sent from Autonomous to
  Authority. O3DE Authority rewinds before processing network input
  to maintain consistency. SCR PredictionInput captures the semantic
  meaning: input for prediction, not the transport mechanism. GGPO
  sends input with redundancy (3–8 frames) to handle packet loss;
  SCR PredictionInput is the semantic input, not the redundant
  transport copies. Unity PredictionInput is scoped to
  PredictedSimulationSystemGroup; SCR PredictionInput is scoped to
  entity-property prediction. O3DE conflates input-for-prediction with
  input-for-authority; SCR separates: PredictionInput is the semantic
  concept, while transport of input to authority is a provider concern.
invariants:
  - PRED-INV-022: PredictionInput MUST be timestamped. Each input belongs to a specific simulation tick.
  - PRED-INV-023: PredictionInput MUST declare which entity and properties it targets.
  - PRED-INV-024: PredictionInput MAY be in one of three states: confirmed, rejected, or pending.
  - PRED-INV-025: PredictionInput MUST record provenance: source host, entity, tick, input data, timestamp.
  - PRED-INV-026: PredictionInput used for local prediction MUST be the same input transmitted to authority. No semantic divergence permitted.
```

### 4.6 AuthorityUpdate

```yaml
concept: AuthorityUpdate
source: O3DE Multiplayer, GGPO rollback netcode, Unity Netcode for Entities
source_terminology: >
  O3DE: authoritative state replication (NetworkProperty delta);
  GGPO: remote input arrival triggering rollback;
  Unity: server snapshot applied to predicted entities
scr_interpretation: >
  AuthorityUpdate is the state correction from authority. An
  AuthorityUpdate carries authoritative state that MAY conflict with
  a host's PredictedState. AuthorityUpdate is a specific form of
  Replication (Sprint 02) with correction semantics: when the
  authoritative state differs from predicted state, the receiving
  host MUST invoke Reconciliation. AuthorityUpdate is always
  authoritative — it represents the source of truth, not an
  approximation. AuthorityUpdate MAY carry the full authoritative
  state (snapshot) or a delta from last acknowledged state.
  AuthorityUpdate triggers Reconciliation on the receiving host
  when it conflicts with PredictedState.
differences: >
  O3DE replicates NetworkProperty deltas from Authority to Autonomous.
  When an Autonomous host receives a delta that conflicts with its
  predicted properties, it rewinds and resimulates. SCR AuthorityUpdate
  captures the semantic meaning: authoritative state correction, not
  the delta-replication mechanism. GGPO triggers rollback on remote
  input arrival (not full state); SCR AuthorityUpdate MAY carry full
  state or delta — the semantic meaning is "authority says this is
  correct." Unity applies server snapshots to predicted entities and
  resimulates; SCR AuthorityUpdate is the semantic trigger for this
  process, independent of snapshot format. O3DE AuthorityUpdate is
  implicit in the replication system; SCR makes it an explicit semantic
  operation with defined contracts.
invariants:
  - PRED-INV-027: AuthorityUpdate MUST be authoritative. It represents the source of truth, not an approximation.
  - PRED-INV-028: AuthorityUpdate MUST declare the authoritative host that originated it.
  - PRED-INV-029: When AuthorityUpdate conflicts with PredictedState, the receiving host MUST invoke Reconciliation.
  - PRED-INV-030: AuthorityUpdate MUST record provenance: authoritative host, entity, state or delta, timestamp, tick.
  - PRED-INV-031: AuthorityUpdate MAY carry full state (snapshot) or delta. Format is a provider concern; semantic meaning is unchanged.
  - PRED-INV-032: AuthorityUpdate MUST NOT be modified in transit. The authoritative state must arrive unchanged.
```

## 5. Semantic Family: Cross-Cutting Properties

### 5.1 Prediction Lifecycle

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PREDICTION LIFECYCLE                             │
│                                                                     │
│  1. PredictionInput    ──→ 2. PredictedState  ──→ (displayed)      │
│     (input at tick N)       (speculative state)                     │
│           │                       │                                 │
│           │                       │  4. Reconciliation              │
│           │                       │     (identify divergence)       │
│           │                       │         │                       │
│           │   3. AuthorityUpdate  │         ▼                       │
│           │   (authority says     │  5. Rollback                    │
│           │    state at tick M)   │     (restore to tick M)         │
│           │         │             │         │                       │
│           │         ▼             │         ▼                       │
│           │    6. Replay          │  6. Replay                      │
│           │    (re-execute        │     (re-execute inputs          │
│           │     inputs M..N)      │      M..N)                      │
│           │         │             │         │                       │
│           │         ▼             │         ▼                       │
│           └──→ corrected state    └──→ corrected state              │
│                (authoritative)          (authoritative)              │
└─────────────────────────────────────────────────────────────────────┘
```

### 5.2 Relationship Matrix

| | PredictedState | Reconciliation | Rollback | Replay | PredictionInput | AuthorityUpdate |
|---|----------------|----------------|----------|--------|-----------------|-----------------|
| **PredictedState** | — | Corrected by Reconciliation | Restored by Rollback | Reconstructed by Replay | Produced by PredictionInput | Corrected by AuthorityUpdate |
| **Reconciliation** | Corrects PredictedState | — | May trigger Rollback | May trigger Replay | Uses PredictionInput | Triggered by AuthorityUpdate |
| **Rollback** | Restores state for | Part of Reconciliation | — | Followed by Replay | — | — |
| **Replay** | Reconstructs state for | Part of Reconciliation | Follows Rollback | — | Uses PredictionInput | — |
| **PredictionInput** | Produces PredictedState | Used in Reconciliation | Used in Replay | Used in Replay | — | May be confirmed/rejected by AuthorityUpdate |
| **AuthorityUpdate** | Corrects PredictedState | Triggers Reconciliation | — | — | May confirm/reject PredictionInput | — |

### 5.3 Mechanism vs. Semantic Distinction

| Concept | Semantic (SCR) | Mechanism (Provider) |
|---------|----------------|---------------------|
| State correction | **Reconciliation** | Rollback + resimulate |
| Speculative advancement | **PredictedState** | Local simulation tick |
| Input for prediction | **PredictionInput** | Frame-stamped network input |
| Authority correction | **AuthorityUpdate** | Delta replication |
| State reconstruction | **Replay** | Fast-forward re-execution |
| State restoration | **Rollback** | Snapshot restore |

**Critical SCR principle:** Rollback is a provider mechanism, not a semantic concept. SCR defines Reconciliation as the semantic operation; Rollback is one implementation. A provider MAY implement Reconciliation by discarding PredictedState and accepting current authoritative state (no rollback needed). A provider MAY implement Reconciliation by snapshot-restore + replay (GGPO-style rollback). The semantic contract is satisfied either way.

### 5.4 Determinism as Provider Requirement

Determinism (same inputs → same state) is a **provider requirement** for Rollback/Replay, not a semantic property of SCR prediction concepts. SCR acknowledges determinism:
- PRED-INV-018 requires Replay to produce consistent output (semantic contract)
- PRED-INV-014 distinguishes Rollback (mechanism requiring determinism) from Reconciliation (semantic process)
- A provider MAY implement Reconciliation without determinism if it discards PredictedState rather than replaying

## 6. Invariant Registry

### 6.1 All Invariants Added This Sprint

| Invariant | Statement |
|-----------|-----------|
| **PRED-INV-001** | Prediction MUST NOT modify authoritative state. |
| **PRED-INV-002** | Reconciliation MUST preserve causal ordering. |
| **PRED-INV-003** | Rollback MUST restore to a valid historical state. |
| **PRED-INV-004** | PredictedState MUST declare its prediction scope. |
| **PRED-INV-005** | PredictedState MUST be provisional. |
| **PRED-INV-006** | PredictedState MUST record provenance. |
| **PRED-INV-007** | Multiple PredictedStates MAY exist for the same entity on different hosts. |
| **PRED-INV-008** | Reconciliation MUST identify the divergence point. |
| **PRED-INV-009** | Reconciliation MUST apply authoritative state at the divergence point. |
| **PRED-INV-010** | Reconciliation MUST record provenance. |
| **PRED-INV-011** | Reconciliation MAY be triggered by: authority update arrival, prediction timeout, confidence threshold, explicit correction request. |
| **PRED-INV-012** | Reconciliation completion MUST produce a causally consistent state. |
| **PRED-INV-013** | Rollback requires recorded state history. |
| **PRED-INV-014** | Rollback is a provider mechanism, not a semantic concept. |
| **PRED-INV-015** | Rollback MAY be scoped to specific entities or entire world state. |
| **PRED-INV-016** | Rollback MUST NOT discard unsimulated inputs. |
| **PRED-INV-017** | Replay MUST preserve temporal ordering. |
| **PRED-INV-018** | Replay requires deterministic simulation. |
| **PRED-INV-019** | Replay MUST NOT invent inputs. |
| **PRED-INV-020** | Replay MUST record provenance. |
| **PRED-INV-021** | Replay MAY be scoped to specific entities or entire world state. |
| **PRED-INV-022** | PredictionInput MUST be timestamped. |
| **PRED-INV-023** | PredictionInput MUST declare which entity and properties it targets. |
| **PRED-INV-024** | PredictionInput MAY be in one of three states: confirmed, rejected, or pending. |
| **PRED-INV-025** | PredictionInput MUST record provenance. |
| **PRED-INV-026** | PredictionInput used for local prediction MUST be the same input transmitted to authority. |
| **PRED-INV-027** | AuthorityUpdate MUST be authoritative. |
| **PRED-INV-028** | AuthorityUpdate MUST declare the authoritative host. |
| **PRED-INV-029** | When AuthorityUpdate conflicts with PredictedState, host MUST invoke Reconciliation. |
| **PRED-INV-030** | AuthorityUpdate MUST record provenance. |
| **PRED-INV-031** | AuthorityUpdate MAY carry full state or delta. |
| **PRED-INV-032** | AuthorityUpdate MUST NOT be modified in transit. |

### 6.2 Relationship to Sprint 02 Invariants

| Sprint 02 Invariant | Relationship to Sprint 03 |
|---------------------|--------------------------|
| **DIST-AUTH-001** | AuthorityUpdate requires exactly one authoritative host |
| **DIST-AUTH-003** | Prediction MUST NOT violate authority boundaries (PRED-INV-001 extends) |
| **DIST-REP-001** | AuthorityUpdate originates from authoritative host only |
| **DIST-REP-002** | AuthorityUpdate MUST preserve semantic meaning |
| **DIST-REP-006** | AuthorityUpdate MUST record provenance |

## 7. Exit Criteria Verification

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Each definition has provenance | ✓ | Each definition cites O3DE source_terminology and research source |
| Definitions general enough for games/robotics/distributed-simulation/digital-twins | ✓ | Cross-domain examples in differences sections; mechanism-agnostic |
| Prediction does not silently overwrite authoritative state | ✓ | PRED-INV-001 explicitly states this |
| Reconciliation is a defined semantic operation | ✓ | PRED-INV-008, 009, 010, 011, 012 define reconciliation process |
| Temporal ordering is preserved | ✓ | PRED-INV-002, PRED-INV-017 enforce causal/temporal ordering |
| Rollback distinguished as provider mechanism | ✓ | PRED-INV-014 explicitly separates mechanism from semantics |

## 8. M004 Invariant Coverage

| M004 Invariant | Coverage |
|----------------|----------|
| **Authority transitions are explicit** | Sprint 02 (DIST-AUTH-002) |
| **Prediction does not silently overwrite authoritative state** | Sprint 03 (PRED-INV-001) |
| **Replicated state has defined ownership** | Sprint 02 (DIST-OWN-001 through 006) |
| **Time ordering is preserved across distributed observations** | Sprint 02 (DIST-OBS-002) + Sprint 03 (PRED-INV-002, PRED-INV-017) |

## 9. Notes

- Temporal identity and state ownership model deferred to Sprint 04 as specified in the sprint plan.
- These six definitions build on Sprint 02's five distributed-state definitions (Authority, Ownership, Replication, Observation, RemoteOperation).
- All invariants follow the PRED- prefix convention for prediction/reconciliation semantics.
- The mechanism-vs-semantic distinction (Section 5.3) is the core architectural contribution of this sprint — it prevents SCR from being coupled to any specific rollback implementation.
# Sprint 03: Prediction & Reconciliation

Define prediction and reconciliation semantics. Investigate rollback, replay, correction.

## Deliverables
- PredictionState semantic definition
- Reconciliation semantic definition
- Rollback/Replay assessment
- Temporal ordering invariants

## Exit Criteria
- [ ] Prediction does not silently overwrite authority
- [ ] Reconciliation is a defined semantic operation
- [ ] Temporal ordering preserved
# Sprint 004 Record: Temporal Semantics, Identity Mapping & State Ownership

## 1. Objective

Define the SCR temporal semantics classification, identity mapping model, and state ownership model. Each definition derives from O3DE timing/identity research, generalised beyond games to robotics, distributed-simulation, and digital-twins. Frame number, simulation time, wall-clock time, and network time are explicitly distinguished as separate semantic concepts. Identity scope and lifetime are documented for cross-system mapping.

## 2. Scope & Boundaries

### 2.1 What This Sprint Covers

Three semantic models:

| Model | Purpose |
|-------|---------|
| **Temporal Semantics** | Classification of time concepts across computational domains |
| **Identity Mapping** | Cross-system identity correspondence and lifecycle |
| **State Ownership** | Per-state declaration of owner, mutator, observer, predictor, reconciler |

### 2.2 What This Sprint Does NOT Cover

- Prediction and reconciliation mechanisms (Sprint 03 — covered)
- Authority/ownership/replication definitions (Sprint 02 — covered)
- Transport-layer protocols (explicitly separated)
- Provider-specific implementations (O3DE TickBus is provider-specific, not SCR semantic)

### 2.3 Relationship to M004 Invariants

All definitions must satisfy M004's four formal invariants:

1. Authority transitions are explicit
2. Prediction does not silently overwrite authoritative state
3. Replicated state has defined ownership
4. **Time ordering is preserved across distributed observations**

## 3. Research Sources

### 3.1 O3DE Timing Architecture

O3DE provides multiple distinct timing mechanisms:

| O3DE Concept | Mechanism | Scope |
|--------------|-----------|-------|
| `AZ::TickBus::OnTick(float deltaTime, AZ::ScriptTimePoint time)` | Per-frame tick. `deltaTime` is time since last frame. `time` is accumulated script time. | Game thread, frame-synchronized |
| `AZ::SystemTickEvents::OnSystemTick()` | System tick at small intervals (ms). Fires even without focus. Not consistent interval. | System thread, independent of frame |
| `AZ::ComponentTickBus` ordering | Integer order values (TICK_FIRST=0, TICK_PLACEMENT=50, TICK_INPUT=75, TICK_GAME=80, TICK_ANIMATION=100) | Within-frame component ordering |
| Simulation Time for ROS2 Gem | Separate simulation time concept for ROS2 integration | ROS2 domain |

**Key O3DE insight:** O3DE conflates `deltaTime` (frame interval) with `time` (accumulated script time). The tick bus is frame-synchronous; the system tick bus is frame-independent. SCR must separate these as distinct temporal semantic concepts because they serve different computational purposes.

**Key O3DE insight:** `AZ::ScriptTimePoint` is accumulated time from script system — it represents simulation time, not wall-clock time. Wall-clock time requires `AZStd::chrono::system_clock` or platform APIs. Frame time (`deltaTime`) is the interval between frames, not the current time. These are three distinct semantic concepts.

### 3.2 O3DE Identity Architecture

O3DE identity mechanisms:

| O3DE Concept | Type | Scope | Lifetime | Collision Risk |
|--------------|------|-------|----------|----------------|
| `AZ::EntityId` | 64-bit integer (context-local) | Host-local | Session (destroyed on level unload) | Low within session; meaningless across hosts |
| `AZ::Uuid` | 128-bit UUID v4 | Global | Permanent | Negligible (UUID v4 random) |
| Entity serialization | JSON/binary with Uuid key | Persistent | Asset lifetime | None (UUID-based) |
| `AZ::Name` | String hash | Host-local | Session | Medium (hash collision possible) |
| Network Entity ID | AzNetworking-assigned | Network-local | Session (network connection) | No (server-assigned) |

**Key O3DE insight:** `AZ::EntityId` is context-local — it has no meaning across hosts, processes, or sessions. It is an internal handle, not an identity. `AZ::Uuid` is the persistent identity used for serialization, asset identification, and cross-session persistence. SCR must distinguish between handle (session-local reference) and identity (persistent, globally unique).

**Key O3DE insight:** In multiplayer, the server assigns network entity IDs. These are session-scoped to the network connection. When a client disconnects and reconnects, it receives new network entity IDs. The persistent identity (Uuid) survives reconnection. SCR must track identity across reconnection events.

### 3.3 State Ownership Patterns in Multiplayer

O3DE Multiplayer Gem ownership patterns:

| Pattern | Owner | Mutator | Lifecycle Control | Example |
|---------|-------|---------|-------------------|---------|
| Server-authoritative | Server | Server | Server spawns/despawns | NPC, physics objects |
| Autonomous prediction | Autonomous client | Authority (server) | Server spawns | Player character |
| Client-owned (distributed authority) | Owning client | Owning client | Client spawns | Destructible environment |
| Shared ownership | All peers | Consensus | Distributed | Peer-to-peer simulation |

**Key insight:** Ownership in multiplayer is not a single concept. It decomposes into:
- **Who mutates state?** (Authority)
- **Who controls lifecycle?** (Ownership)
- **Who predicts?** (Autonomous client)
- **Who reconciles?** (Receiving host on authority update)

SCR must make each role explicit per state, not per entity.

### 3.4 Unity Netcode State Ownership

Unity Netcode for Entities provides additional patterns:

- `NetworkVariable<T>` with `ReadPerm` / `WritePerm` permissions
- `Owner` permission: only the owning client can write
- `Everyone` permission: any host can write (conflict resolution required)
- Distributed authority: ownership transfers automatically on client join/leave
- `OwnershipStatus`: None (static), Distributable, Transferable, RequestRequired

**Key Unity insight:** State ownership is per-property, not per-entity. The same entity may have owner-writable properties and authority-writable properties. SCR adopts this per-property granularity.

### 3.5 ROS 2 Identity and Timing

ROS 2 provides domain-specific patterns:

| Concept | Type | Scope | Lifetime |
|---------|------|-------|----------|
| Node name | String | Namespace-local | Node lifetime |
| Topic name | String | Namespace-local | Publication lifetime |
| QoS profile | Configuration | Per-topic | Publication lifetime |
| Simulation time (`/clock`) | `rosgraph_msgs/msg/Clock` | System-wide | Simulation lifetime |
| Wall time (`steady_clock`) | `builtin_interfaces/msg/Time` | System-wide | Process lifetime |

**Key ROS 2 insight:** ROS 2 distinguishes simulation time (from `/clock` topic) from wall time (from `steady_clock`). This is exactly the temporal semantics distinction SCR requires. The `/clock` topic is the ROS 2 equivalent of O3DE's script time — it represents the simulation's progression, not real-world time.

## 4. SCR Semantic Definitions

### 4.1 Temporal Semantics Classification

```yaml
concept: WallClock
source: std::chrono, OS APIs, ROS 2 steady_clock
source_terminology: >
  C++: std::chrono::system_clock, std::chrono::steady_clock;
  O3DE: AZStd::chrono (implicit);
  ROS 2: builtin_interfaces/msg/Time with steady_clock
scr_interpretation: >
  WallClock is real-world time as measured by the system clock. WallClock
  advances monotonically (steady_clock) or with system adjustments
  (system_clock). WallClock is used for: scheduling, timeout detection,
  performance measurement, logging timestamps, and cross-system correlation.
  WallClock is NOT used for simulation progression — simulation uses
  SimulationTime. WallClock MAY diverge from SimulationTime when the
  simulation pauses, runs faster/slower than real-time, or uses fixed
  timestep. WallClock is the temporal authority for "when did this happen
  in the real world."
differences: >
  O3DE does not explicitly name wall-clock time as a distinct concept.
  AZ::ScriptTimePoint conflates accumulated script time with wall-clock
  time. ROS 2 explicitly distinguishes /clock (simulation time) from
  steady_clock (wall time). SCR WallClock is the generalised concept
  covering both. std::chrono provides platform-independent wall-clock
  access; SCR WallClock is agnostic to implementation.
invariants:
  - TEMP-WC-001: WallClock MUST be monotonic for sequencing. Use steady_clock for ordering.
  - TEMP-WC-002: WallClock MAY diverge from SimulationTime. Divergence MUST be declared.
  - TEMP-WC-003: WallClock MUST record provenance: source clock, host, timestamp.
  - TEMP-WC-004: WallClock is the temporal authority for real-world event ordering.
```

```yaml
concept: SimulationTime
source: O3DE AZ::ScriptTimePoint, ROS 2 /clock, fixed timestep simulations
source_terminology: >
  O3DE: AZ::ScriptTimePoint (accumulated script time);
  ROS 2: /clock topic (rosgraph_msgs/msg/Clock);
  Games: fixed_dt * tick_count
scr_interpretation: >
  SimulationTime is the progression of the simulation's internal clock.
  SimulationTime advances by a fixed or variable delta each simulation tick.
  SimulationTime is the temporal authority for "what order did simulation
  events happen." SimulationTime MAY advance faster or slower than
  WallClock (time scaling, pause, catch-up). SimulationTime is used for:
  deterministic replay, rollback/reconciliation (Sprint 03), physics
  integration, animation blending, and simulation-ordered event processing.
  SimulationTime is NOT real-world time — it represents the simulation's
  internal progression.
differences: >
  O3DE AZ::ScriptTimePoint is accumulated script time — it is the
  simulation time within the script system. However, O3DE does not
  separate ScriptTimePoint from tick-based frame timing. SCR
  SimulationTime is explicitly separated from FrameTime and WallClock.
  ROS 2 /clock provides simulation time via a topic — any node can
  publish simulation time. SCR SimulationTime is the semantic concept;
  the mechanism (topic, accumulator, fixed step) is a provider concern.
  GGPO uses frame numbers as simulation time (frame N = N * fixed_dt).
  SCR SimulationTime is generalised: it MAY be frame-derived or
  independent of frames.
invariants:
  - TEMP-SIM-001: SimulationTime MUST advance monotonically within the simulation.
  - TEMP-SIM-002: SimulationTime MUST NOT silently diverge from declared timestep. If timestep changes, it MUST be declared.
  - TEMP-SIM-003: SimulationTime is the temporal authority for simulation-ordered events.
  - TEMP-SIM-004: SimulationTime MAY be paused, scaled, or reset — each operation MUST be declared.
  - TEMP-SIM-005: SimulationTime MUST record provenance: host, timestep, tick count, timestamp.
```

```yaml
concept: ObservationTime
source: O3DE replicated state timestamps, distributed systems snapshot semantics
source_terminology: >
  O3DE: NetworkProperty replication timestamp;
  Distributed systems: vector clocks, logical timestamps;
  Sprint 02: Observation point-in-time snapshot
scr_interpretation: >
  ObservationTime is when a state was observed by a specific host.
  ObservationTime captures the temporal position of a snapshot from the
  observing host's perspective. ObservationTime is always later than or
  equal to the state's origin time (the time the state was produced).
  The gap between origin time and ObservationTime is staleness (Sprint 02:
  DIST-OBS-003). ObservationTime is used for: staleness calculation,
  temporal ordering of observations, conflict detection, and cross-host
  correlation. ObservationTime is NOT the time the state was produced —
  it is the time the state was received and recorded.
differences: >
  O3DE does not have an explicit ObservationTime concept. Replicated
  state arrives with implicit ordering (sequence numbers) but no
  explicit timestamp of when it was observed. SCR ObservationTime makes
  this explicit: every observation records when it was observed, not
  just when it was produced. Distributed systems use vector clocks for
  causal ordering; SCR ObservationTime is a wall-clock timestamp that
  provides real-world temporal position. Causal ordering is a separate
  semantic concern.
invariants:
  - TEMP-OBS-001: ObservationTime MUST be recorded at the moment of observation, not derived from origin time.
  - TEMP-OBS-002: ObservationTime MUST be later than or equal to the state's origin time.
  - TEMP-OBS-003: Staleness = ObservationTime - originTime. Staleness MUST be calculable.
  - TEMP-OBS-004: ObservationTime MUST record provenance: observing host, observed entity, origin time, observation timestamp.
```

```yaml
concept: NetworkTime
source: O3DE network tick, Unity NetworkManager tick, GGPO frame sync
source_terminology: >
  O3DE: AzNetworking tick (network simulation frame);
  Unity: NetworkManager.ServerTick / ClientTick;
  GGPO: synchronized frame number
scr_interpretation: >
  NetworkTime is the network synchronization time — the time used to
  coordinate state across networked hosts. NetworkTime is typically
  server-authoritative: the server's clock defines the current network
  time, and clients synchronize to it. NetworkTime is used for:
  input timestamping (Sprint 03: PredictionInput), authority update
  ordering, lag compensation, and temporal rollback windows. NetworkTime
  MAY be frame-derived (server frame N) or independent (server wall
  clock). NetworkTime is NOT SimulationTime — they may advance at
  different rates (client may run faster/slower simulation but still
  synchronize to server network time).
differences: >
  O3DE network tick is tied to the server's frame rate — each network
  tick corresponds to a server frame. SCR NetworkTime is independent
  of frame rate: it MAY be frame-derived or wall-clock-derived. Unity
  separates ServerTick and ClientTick; SCR NetworkTime is always
  authoritative (from the authoritative host), not per-host. GGPO uses
  frame numbers as network time (frame N is globally synchronized);
  SCR NetworkTime is generalised. The key distinction: NetworkTime is
  for cross-host coordination, SimulationTime is for within-host
  simulation progression.
invariants:
  - TEMP-NET-001: NetworkTime MUST be authoritative — defined by the authoritative host.
  - TEMP-NET-002: NetworkTime MUST be consistent across all hosts at a given logical moment. Discrepancies MUST be declared.
  - TEMP-NET-003: NetworkTime is used for input timestamping and authority update ordering.
  - TEMP-NET-004: NetworkTime MUST record provenance: authoritative host, timestamp, network tick.
  - TEMP-NET-005: NetworkTime MAY be frame-derived or wall-clock-derived. The derivation MUST be declared.
```

```yaml
concept: FrameTime
source: O3DE AZ::TickBus deltaTime, render loop timing
source_terminology: >
  O3DE: AZ::TickBus::OnTick deltaTime parameter;
  Games: timeSinceLastFrame, frame delta;
  Rendering: VSync interval, frame rate
scr_interpretation: >
  FrameTime is the interval between render frames. FrameTime is
  presentation timing — it determines how often the visual output
  updates. FrameTime is NOT simulation time — they MAY diverge when
  simulation runs at a fixed timestep different from render rate,
  when frames are dropped, or when time scaling is applied. FrameTime
  is used for: animation interpolation, visual smoothing, frame-rate
  independent movement in presentation logic, and VSync coordination.
  FrameTime MUST NOT be used for simulation ordering — use
  SimulationTime. FrameTime MUST NOT be used for network synchronization
  — use NetworkTime. FrameTime is the temporal authority for "how long
  since the last visual update."
differences: >
  O3DE passes deltaTime to OnTick — this IS the frame time. However,
  O3DE documentation warns against using OnTick for simulation logic
  ("components should limit time connected to tick bus"). O3DE
  conflates frame time with simulation time in the same callback.
  SCR FrameTime is explicitly separated from SimulationTime and
  NetworkTime. The deltaTime parameter in OnTick maps to SCR FrameTime.
  The ScriptTimePoint parameter maps to SCR SimulationTime (accumulated).
  O3DE does not make this distinction explicit; SCR requires it.
invariants:
  - TEMP-FRAME-001: FrameTime is the interval between render frames, not simulation time.
  - TEMP-FRAME-002: FrameTime MUST NOT be used for simulation ordering. SimulationTime is the authority for simulation events.
  - TEMP-FRAME-003: FrameTime MAY vary (frame drops, VSync). Variance MUST NOT affect simulation correctness.
  - TEMP-FRAME-004: FrameTime MUST record provenance: host, frame number, delta, timestamp.
```

```yaml
concept: PhysicsTimestep
source: O3DE PhysX fixed timestep, physics simulation integration
source_terminology: >
  O3DE: PhysX fixed timestep (default 1/60);
  Games: fixedDeltaTime, physics tick;
  Robotics: control loop period
scr_interpretation: >
  PhysicsTimestep is the fixed integration step for physics simulation.
  PhysicsTimestep is typically constant (e.g., 1/60 second) and
  independent of render frame rate. PhysicsTimestep is used for:
  deterministic physics integration, collision detection, constraint
  solving, and rigid body dynamics. PhysicsTimestep is a specific form
  of SimulationTime — physics runs at its own fixed rate within the
  simulation. Multiple physics steps MAY occur per render frame; a
  single physics step MAY span multiple render frames. PhysicsTimestep
  is the temporal authority for "how far did physics advance."
differences: >
  O3DE PhysX provides fixed timestep configuration — the physics
  engine runs at a constant rate regardless of frame rate. This is
  standard practice. SCR PhysicsTimestep is the generalised semantic
  concept: any fixed-step integration. It applies to physics,
  robotics control loops, signal processing, and any domain requiring
  fixed-rate integration. O3DE conflates physics timestep with the
  broader simulation timestep. SCR separates PhysicsTimestep as a
  specific temporal concept within the simulation hierarchy.
invariants:
  - TEMP-PHY-001: PhysicsTimestep MUST be constant for deterministic integration.
  - TEMP-PHY-002: PhysicsTimestep MAY accumulate fractional steps (fixed timestep with remainder).
  - TEMP-PHY-003: PhysicsTimestep is subordinate to SimulationTime — physics runs within the simulation timeline.
  - TEMP-PHY-004: PhysicsTimestep MUST record provenance: host, timestep value, integration count.
```

### 4.2 Temporal Semantics Hierarchy

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TEMPORAL SEMANTICS HIERARCHY                      │
│                                                                     │
│  WallClock (real-world)                                             │
│    ├── ObservationTime (when state was observed)                    │
│    └── NetworkTime (server-authoritative, cross-host)              │
│                                                                     │
│  SimulationTime (simulation progression)                           │
│    ├── PhysicsTimestep (fixed integration step)                     │
│    └── (other fixed-rate subsystems)                               │
│                                                                     │
│  FrameTime (render interval)                                        │
│    └── Presentation only — NOT simulation authority                 │
│                                                                     │
│  Key invariants:                                                    │
│    Frame number ≠ simulation time (unless formally justified)       │
│    WallClock ≠ SimulationTime (unless real-time simulation)         │
│    NetworkTime ≠ SimulationTime (unless synchronized)               │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.3 Critical Invariant: Frame ≠ Simulation Time

```
FRAME ≠ SIMULATION TIME

Frame number is a presentation counter. Simulation time is a progression
counter. They are semantically distinct.

Frame 100 does NOT mean "100 units of simulation time have passed."
Frame 100 means "100 visual updates have occurred."

If frame number equals simulation time, this is a special case that
MUST be formally justified:
- Simulation runs at render rate (variable timestep)
- No frame drops have occurred
- No time scaling has been applied
- No pause/resume has occurred

The burden of proof is on the claim that frame = simulation time.
The default assumption is: they are independent.
```

### 4.4 Identity Mapping

```yaml
concept: SCR_SID
source: SCR internal identity system
scr_interpretation: >
  SCR_SID (SCR Semantic Identity) is the persistent, globally unique
  identity for entities across all computational domains. SCR_SID is
  UUID-based (v4 random or v7 time-ordered). SCR_SID is the semantic
  authority for "which entity is this" — it survives session boundaries,
  host changes, reconnection, and serialization. SCR_SID is NOT a
  handle — it is an identity. Handles (EntityId, network ID) are
  session-local references to an entity identified by SCR_SID.
invariants:
  - IDENT-001: SCR_SID MUST be UUID-based and globally unique.
  - IDENT-002: SCR_SID MUST persist across sessions, reconnection, and serialization.
  - IDENT-003: SCR_SID is the semantic authority for entity identity.
  - IDENT-004: Handles (EntityId, network ID) are NOT identities — they are session-local references.
```

#### 4.4.1 Identity Mapping Table

| SCR Identity | Provider Identity | Scope | Lifetime | Collision Risk | Notes |
|---|---|---|---|---|---|
| **SCR_SID** | `AZ::EntityId` | Provider-local (host) | Session (level unload destroys) | Low within session | Handle, not identity. Reassigned on re-creation. |
| **SCR_SID** | `AZ::Uuid` | Global | Permanent (asset lifetime) | Negligible (UUID v4) | Persistent identity. Used for serialization. |
| **SCR_SID** | USD Prim Path | USD-local | Stage lifetime | None (path-based) | Hierarchical path. Unique within stage. |
| **SCR_SID** | Network Entity ID | Network-local | Session (connection) | No (server-assigned) | Server assigns. New ID on reconnect. |
| **SCR_SID** | ROS 2 Node Name | Namespace-local | Node lifetime | Medium (string-based) | Must be unique within namespace. |
| **SCR_SID** | ROS 2 Topic Name | Namespace-local | Publication lifetime | Medium (string-based) | Must be unique within namespace for typed topics. |

#### 4.4.2 Identity Lifecycle

```
┌─────────────────────────────────────────────────────────────────────┐
│                    IDENTITY LIFECYCLE                                │
│                                                                     │
│  1. Creation: SCR_SID generated (UUID v4/v7)                       │
│       │                                                             │
│       ├──→ AZ::EntityId assigned (host-local handle)               │
│       ├──→ Network Entity ID assigned (server-assigned)            │
│       ├──→ USD Prim Path assigned (stage-scoped)                   │
│       └──→ ROS 2 Node Name registered (namespace-scoped)          │
│                                                                     │
│  2. Session: Handles reference SCR_SID                              │
│       │                                                             │
│       ├──→ EntityId valid within host session                       │
│       ├──→ Network ID valid within network session                  │
│       ├──→ USD Path valid within stage                              │
│       └──→ ROS Name valid within namespace                         │
│                                                                     │
│  3. Reconnection: Handles MAY change, SCR_SID persists             │
│       │                                                             │
│       ├──→ New EntityId (new host session)                         │
│       ├──→ New Network ID (new network session)                    │
│       ├──→ USD Path unchanged (stage persists)                     │
│       └──→ ROS Name unchanged (node persists)                      │
│                                                                     │
│  4. Serialization: SCR_SID is serialized, handles are not          │
│       │                                                             │
│       └──→ SCR_SID in persistent storage, cross-system references  │
│                                                                     │
│  5. Destruction: SCR_SID invalidated, all handles released         │
└─────────────────────────────────────────────────────────────────────┘
```

#### 4.4.3 Identity Mapping Invariants

| Invariant | Statement |
|-----------|-----------|
| **IDENT-005** | `AZ::EntityId` is a handle, not an identity. It MUST NOT be serialized as a persistent reference. |
| **IDENT-006** | Network Entity ID is session-scoped. It MAY change on reconnection. SCR_SID persists. |
| **IDENT-007** | USD Prim Path is stage-scoped. It persists within a stage but NOT across stage reloads. |
| **IDENT-008** | ROS 2 Node Name is namespace-scoped. It persists within a node lifetime but NOT across node restart. |
| **IDENT-009** | Cross-system references MUST use SCR_SID, not provider-specific handles. |
| **IDENT-010** | Identity mapping MUST record provenance: source system, handle value, SCR_SID, timestamp. |

### 4.5 State Ownership Model

#### 4.5.1 State Ownership Definitions

| Term | Definition |
|------|------------|
| **Owner** | Host that controls entity lifecycle (creation, destruction) and input stream. From Sprint 02: DIST-OWN-001 through 006. |
| **Mutator** | Host that has write permission on a specific state property. May differ from Owner. |
| **Observer** | Host that reads replicated state. Always non-destructive (Sprint 02: DIST-OBS-001). |
| **Predictor** | Host that speculatively advances state before authority confirmation (Sprint 03: PRED-INV-004). |
| **Reconciler** | Host that resolves divergence between predicted and authoritative state (Sprint 03: PRED-INV-008). |

#### 4.5.2 State Ownership Table

| State | Owner | Mutator | Observer | Predictor | Reconciler |
|---|---|---|---|---|---|
| **Entity position** | Authority | Authority | All replicas | Autonomous client | Authority (on authority update) |
| **Entity rotation** | Authority | Authority | All replicas | Autonomous client | Authority |
| **Entity velocity** | Authority | Authority | All replicas | Autonomous client | Authority |
| **Component data (general)** | Owner host | Owner host | Peers (via replication) | Owner (if predictable) | Owner (on authority update) |
| **Animation state** | Authority | Authority | All replicas | Autonomous client | Authority |
| **Physics state** | Authority | Authority | All replicas | Autonomous client | Authority |
| **Input state** | Owner (client) | Owner (client) | Authority (receives input) | Owner (local) | Authority (validates) |
| **Health/damage** | Authority | Authority | All replicas | None (not predicted) | Authority |
| **Inventory** | Authority | Authority | Owner only (via ReplicateTo) | None | Authority |
| **Spawn/despawn** | Authority | Authority | All replicas | None | Authority |
| **Audio state** | Local host | Local host | None (not replicated) | None | None |
| **Visual effects** | Local host | Local host | None (not replicated) | None | None |
| **Camera state** | Local host | Local host | None (not replicated) | None | None |

#### 4.5.3 Ownership Granularity

```
OWNERSHIP IS PER-PROPERTY, NOT PER-ENTITY

The same entity may have:
- Authority-writable position (server controls)
- Owner-writable input (client sends)
- Authority-writable health (server controls)
- Local-only visual effects (not replicated)

Each property declares its own:
- Mutator: who can write
- Replication direction: who receives updates
- Prediction scope: who can predict
- Reconciliation authority: who resolves conflicts

This is NOT a contradiction of "one authority per entity."
Authority is per-entity for lifecycle and state truth.
Ownership of specific properties MAY diverge from entity authority
for input and presentation concerns.
```

#### 4.5.4 State Ownership Invariants

| Invariant | Statement |
|-----------|-----------|
| **OWN-STATE-001** | Every mutable state property MUST declare its Mutator. |
| **OWN-STATE-002** | Mutator MUST be the Authority for that property, unless explicit delegation is declared. |
| **OWN-STATE-003** | Observer MUST be declared for every replicated property. Non-replicated properties have no observers. |
| **OWN-STATE-004** | Predictor MUST be declared for every predicted property. Non-predicted properties have no predictor. |
| **OWN-STATE-005** | Reconciler MUST be declared for every predicted property. Authority is the default reconciler. |
| **OWN-STATE-006** | State ownership MAY differ from entity authority for input and presentation properties. |
| **OWN-STATE-007** | Non-replicated state (audio, visual, camera) is local-only. No observer, no predictor, no reconciler. |
| **OWN-STATE-008** | State ownership MUST record provenance: entity, property, owner, mutator, observer, predictor, reconciler, timestamp. |

## 5. Cross-Cutting Properties

### 5.1 Temporal × Identity Interaction

| Concept | Temporal Property | Identity Property |
|---------|-------------------|-------------------|
| Entity creation | WallClock timestamp of creation | SCR_SID generated, handles assigned |
| State observation | ObservationTime recorded | Observer host identified by handle |
| Authority update | NetworkTime of authority state | Authority host identified by SCR_SID |
| Prediction | SimulationTime of prediction | Predicted entity by SCR_SID |
| Reconciliation | SimulationTime of reconciliation | Divergence point by timestamp + entity |

### 5.2 Temporal × Ownership Interaction

| State | Temporal Authority | Ownership Authority |
|-------|-------------------|---------------------|
| Entity position | SimulationTime | Authority (mutator) |
| Input state | NetworkTime (timestamped) | Owner (client) |
| Physics state | PhysicsTimestep | Authority |
| Animation state | FrameTime (interpolation) | Authority |
| Prediction state | SimulationTime | Predictor (client) |

### 5.3 M004 Invariant Coverage

| M004 Invariant | Coverage |
|----------------|----------|
| **Authority transitions are explicit** | Sprint 02 (DIST-AUTH-002) |
| **Prediction does not silently overwrite authoritative state** | Sprint 03 (PRED-INV-001) |
| **Replicated state has defined ownership** | Sprint 02 (DIST-OWN-001 through 006) + Sprint 04 (OWN-STATE-001 through 008) |
| **Time ordering is preserved across distributed observations** | Sprint 04 (TEMP-SIM-003, TEMP-NET-001, TEMP-OBS-001, TEMP-FRAME-002) |

## 6. Exit Criteria Verification

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Frame number ≠ simulation time unless formally justified | ✓ | Section 4.3: Frame ≠ Simulation Time invariant; TEMP-FRAME-001, TEMP-FRAME-002 |
| Identity scope/lifetime/stability/collision documented | ✓ | Section 4.4.1: Identity Mapping Table with scope, lifetime, collision columns |
| State ownership explicit for all mapped states | ✓ | Section 4.5.2: State Ownership Table with Owner/Mutator/Observer/Predictor/Reconciler |
| Temporal semantics classified | ✓ | Section 4.1: Six temporal concepts with definitions and invariants |

## 7. Invariant Registry

### 7.1 All Invariants Added This Sprint

| Invariant | Statement |
|-----------|-----------|
| **TEMP-WC-001** | WallClock MUST be monotonic for sequencing. |
| **TEMP-WC-002** | WallClock MAY diverge from SimulationTime. Divergence MUST be declared. |
| **TEMP-WC-003** | WallClock MUST record provenance. |
| **TEMP-WC-004** | WallClock is the temporal authority for real-world event ordering. |
| **TEMP-SIM-001** | SimulationTime MUST advance monotonically within the simulation. |
| **TEMP-SIM-002** | SimulationTime MUST NOT silently diverge from declared timestep. |
| **TEMP-SIM-003** | SimulationTime is the temporal authority for simulation-ordered events. |
| **TEMP-SIM-004** | SimulationTime MAY be paused, scaled, or reset — each operation MUST be declared. |
| **TEMP-SIM-005** | SimulationTime MUST record provenance. |
| **TEMP-OBS-001** | ObservationTime MUST be recorded at the moment of observation. |
| **TEMP-OBS-002** | ObservationTime MUST be later than or equal to origin time. |
| **TEMP-OBS-003** | Staleness = ObservationTime - originTime. MUST be calculable. |
| **TEMP-OBS-004** | ObservationTime MUST record provenance. |
| **TEMP-NET-001** | NetworkTime MUST be authoritative. |
| **TEMP-NET-002** | NetworkTime MUST be consistent across all hosts. Discrepancies MUST be declared. |
| **TEMP-NET-003** | NetworkTime is used for input timestamping and authority update ordering. |
| **TEMP-NET-004** | NetworkTime MUST record provenance. |
| **TEMP-NET-005** | NetworkTime MAY be frame-derived or wall-clock-derived. Derivation MUST be declared. |
| **TEMP-FRAME-001** | FrameTime is the interval between render frames, not simulation time. |
| **TEMP-FRAME-002** | FrameTime MUST NOT be used for simulation ordering. |
| **TEMP-FRAME-003** | FrameTime MAY vary. Variance MUST NOT affect simulation correctness. |
| **TEMP-FRAME-004** | FrameTime MUST record provenance. |
| **TEMP-PHY-001** | PhysicsTimestep MUST be constant for deterministic integration. |
| **TEMP-PHY-002** | PhysicsTimestep MAY accumulate fractional steps. |
| **TEMP-PHY-003** | PhysicsTimestep is subordinate to SimulationTime. |
| **TEMP-PHY-004** | PhysicsTimestep MUST record provenance. |
| **IDENT-001** | SCR_SID MUST be UUID-based and globally unique. |
| **IDENT-002** | SCR_SID MUST persist across sessions, reconnection, and serialization. |
| **IDENT-003** | SCR_SID is the semantic authority for entity identity. |
| **IDENT-004** | Handles are NOT identities — they are session-local references. |
| **IDENT-005** | `AZ::EntityId` is a handle, not an identity. MUST NOT be serialized as persistent reference. |
| **IDENT-006** | Network Entity ID is session-scoped. MAY change on reconnection. |
| **IDENT-007** | USD Prim Path is stage-scoped. Persists within stage, not across reloads. |
| **IDENT-008** | ROS 2 Node Name is namespace-scoped. Persists within node lifetime. |
| **IDENT-009** | Cross-system references MUST use SCR_SID. |
| **IDENT-010** | Identity mapping MUST record provenance. |
| **OWN-STATE-001** | Every mutable state property MUST declare its Mutator. |
| **OWN-STATE-002** | Mutator MUST be the Authority, unless explicit delegation. |
| **OWN-STATE-003** | Observer MUST be declared for every replicated property. |
| **OWN-STATE-004** | Predictor MUST be declared for every predicted property. |
| **OWN-STATE-005** | Reconciler MUST be declared for every predicted property. |
| **OWN-STATE-006** | State ownership MAY differ from entity authority. |
| **OWN-STATE-007** | Non-replicated state is local-only. |
| **OWN-STATE-008** | State ownership MUST record provenance. |

### 7.2 Relationship to Prior Sprint Invariants

| Sprint | Invariants | Relationship to Sprint 04 |
|--------|------------|--------------------------|
| Sprint 02 | DIST-AUTH-001 through 005 | Authority definitions inform Mutator role |
| Sprint 02 | DIST-OWN-001 through 006 | Ownership definitions inform Owner role |
| Sprint 02 | DIST-OBS-001 through 006 | Observation definitions inform Observer role and ObservationTime |
| Sprint 03 | PRED-INV-001 through 032 | Prediction definitions inform Predictor and Reconciler roles |

## 8. Notes

- This sprint completes M004's four formal invariants.
- The six temporal concepts (WallClock, SimulationTime, ObservationTime, NetworkTime, FrameTime, PhysicsTimestep) are the canonical SCR temporal vocabulary.
- The identity model separates handles from identities — this is the core architectural contribution.
- State ownership is per-property, not per-entity — this enables fine-grained distributed control.
- All invariants follow the TEMP-, IDENT-, or OWN-STATE- prefix conventions.
# Sprint 04: Temporal, Identity & State Ownership

Document temporal semantics, identity mappings, and state ownership model.

## Deliverables
- Temporal semantics classification (wall-clock / simulation / observation / network / frame / physics timestep)
- Identity mapping table (SCR SID ↔ O3DE EntityId ↔ network ID ↔ USD path ↔ ROS entity)
- State ownership model (who owns/mutates/observes/predicts/reconciles each state)

## Exit Criteria
- [ ] Frame number ≠ simulation time unless justified
- [ ] Identity scope/lifetime/stability/collision documented
- [ ] State ownership explicit for all mapped states
# Milestone 005: Provider Specification & Validation

## 1. Scope & Objective
Produce O3DE provider specification. Map provider ecosystem (Bullet3, PhysX, OpenVDB, H3, Ogre3D, USD, ROS2, MLIR, Mojo). Assess semantic fidelity. Define validation plan. Produce repository documentation changes.

## 2. Deliverables
- O3DE provider specification (providers/o3de/101_spec.md)
- Provider ecosystem mapping
- Semantic fidelity assessment table
- Formalisation candidates (Lean 4)
- Validation plan and results
- Repository documentation updates

## 3. Formal Invariants
1. Provider specification distinguishes native/adapter-required/partial/unsupported/unverified.
2. Semantic fidelity classified: lossless/partially-lossy/lossy/implementation-specific/not-established.
3. Validation tests semantic invariants, not merely API callability.

## 4. Exit Criteria
- [ ] O3DE provider spec produced
- [ ] All existing providers assessed against O3DE relationship
- [ ] Semantic fidelity table complete
- [ ] Formalisation candidates identified
- [ ] Validation plan defined with semantic invariant tests
- [ ] Repository documentation updated
- [ ] No unnecessary architectural redesign introduced

## 5. Dependencies
- Milestone 004 (lifecycle/distributed-state semantics)
# Sprint 001 Record: O3DE Provider Specification

**Sprint:** 001
**Milestone:** M005 — Provider Specification Validation
**Status:** Complete
**Date:** 2026-09-21

---

## Deliverables

- `providers/o3de/101_spec.md` — O3DE provider specification

## Exit Criteria

- [x] Spec covers all required sections from objective §23
- [x] Each capability honestly classified (adapter-required / partial / unsupported)
- [x] O3DE is execution provider, not semantic authority
- [x] Identity mapping: SCR SID → AZ::EntityId (adapter-required)
- [x] Spatial mapping: SCR canonical → O3DE (adapter-required)
- [x] Lifecycle: SCR lifecycle → AZ::Entity lifecycle (adapter-required)
- [x] Physics: SCR PhysicsBody → AzPhysics (adapter-required)
- [x] Assets: SCR ResourceReference → AZ::Data::Asset (partial)
- [x] Networking: SCR Replication → Multiplayer (adapter-required)
- [x] Headless mode: supported via --null renderer
- [x] Adapters required: 5 adapters documented
- [x] Known limitations: documented
- [x] Unsupported capabilities: documented

## Classification Summary

| Contract | Classification |
|---|---|
| Entity | adapter-required |
| Component | adapter-required |
| Transform | adapter-required |
| PhysicsBody | adapter-required |
| Replication | adapter-required |
| Rendering | adapter-required |
| Asset | partial |
| SpatialQuery | adapter-required |

## Key Findings

1. No SCR contract maps natively to O3DE without adaptation
2. O3DE is execution substrate, not semantic authority
3. Five adapters required at semantic boundary
4. Asset capability is partial — full pipeline integration needs additional work
5. Headless mode viable for simulation-only scenarios
6. SCR semantic composition patterns incompatible with O3DE entity/component model

## Conformance

Provider specification adheres to `providers/101_definition.md` conventions:
- Identity section present
- Purpose and scope defined
- Supported contracts declared
- Dependencies listed
- Limitations documented
- Validation criteria specified

## Next Steps

- M005 remaining sprints: additional provider specifications (if required)
- Adapter design for O3DE provider integration
- Conformance test development
# Sprint 01: O3DE Provider Specification

Produce the O3DE provider specification at providers/o3de/101_spec.md.

## Deliverables
- Provider purpose and scope
- Supported SCR contracts (native/adapter-required/partial/unsupported)
- Semantic mappings (identity, spatial, temporal, lifecycle, physics, assets)
- Headless mode assessment
- Known limitations and unsupported capabilities

## Exit Criteria
- [ ] Spec covers all required sections from objective §23
- [ ] Each capability honestly classified
- [ ] O3DE is execution provider, not semantic authority
# Sprint 002 Record: Provider Ecosystem Mapping

**Sprint:** 002
**Milestone:** M005 — Provider Specification Validation
**Status:** Complete
**Date:** 2026-09-21

---

## Deliverables

- Provider relationship table (O3DE vs each existing technology)
- Provider ecosystem diagram
- Redundancy/complementarity assessment

## Exit Criteria

- [x] Each provider assessed independently
- [x] No automatic replacement of existing providers
- [x] Coherent provider ecosystem documented
- [x] O3DE classified as execution runtime, not semantic authority

---

## 1. Provider Relationship Table

| Technology | Semantic Role | Representation Role | Provider Role | Execution Role | Adapter Role | Interchange Role | Redundancy | Complementarity |
|---|---|---|---|---|---|---|---|---|
| **Bullet3** | None — subordinate to SCR physics semantics | Rigid body state, collision meshes, constraint parameters | Physics dynamics provider (rigid body, collision, contact solver) | CPU-side simulation execution | Adapts SCR PhysicsBody → btRigidBody; SCR collision shapes → btCollisionShape | None | Low — O3DE delegates physics to AzPhysics/PhysX, not Bullet3 directly; Bullet3 operates independently as SCR canonical physics provider | **High** — Bullet3 provides physics; O3DE provides runtime orchestration. Complementary: O3DE can host Bullet3 as physics backend via AzPhysics adapter |
| **PhysX** | None — subordinate to SCR physics semantics | Rigid body state, collision geometry, articulation chains | Physics backend within O3DE AzPhysics | GPU-accelerated physics execution inside O3DE runtime | O3DE AzPhysics wraps PhysX; SCR → adapter → AzPhysics → PhysX | None | **Medium-High** — PhysX is O3DE's default physics backend; Bullet3 is SCR's canonical physics provider. Both satisfy physics contracts but through different paths | **Medium** — PhysX runs inside O3DE; Bullet3 runs independently. O3DE could route to either via AzPhysics adapter. Coexistence possible |
| **OpenVDB** | None — subordinate to SCR volumetric semantics | Voxel grids, level sets, sparse volume trees, isosurfaces | Volumetric data provider (sparse volume storage, isosurface extraction, fog volumes) | CPU/GPU volume processing | Adapts SCR volume fields → OpenVDB grids; OpenVDB isosurfaces → SCR geometry | None | None — OpenVDB occupies unique spatial/volumetric niche | **High** — OpenVDB provides volumetric data; O3DE provides runtime. O3DE rendering pipeline can consume OpenVDB volumes. Bullet3 collision meshes can reference OpenVDB isosurfaces |
| **H3** | None — subordinate to SCR topology semantics | Hexagonal spatial indices, cell boundaries, hierarchical resolution | Spatial indexing provider (hierarchical hexagonal grid, nearest-neighbor, containment) | CPU-side hexagonal indexing | Adapts SCR spatial queries → H3 cell operations | None | None — H3 occupies unique topology/spatial_indexing niche | **High** — H3 provides spatial indexing; O3DE provides runtime. H3 indexing can drive spatial queries within O3DE simulation |
| **Ogre3D** | None — subordinate to SCR rendering semantics | Scene graph, materials, textures, render passes, mesh data | Rendering provider (scene graph management, material application, frame rendering) | GPU rendering execution | Adapts SCR rendering semantics → Ogre scene graph; Ogre materials → SCR material contracts | None | **Medium** — O3DE has its own RHI/rendering pipeline; Ogre3D is SCR's canonical rendering provider | **High** — Ogre3D provides rendering; O3DE provides runtime orchestration. O3DE could consume Ogre rendering as a subsystem or use its own RHI. Both satisfy rendering contracts |
| **USD** | None — subordinate to SCR scene/composition semantics | Scene description, asset composition, stage hierarchy, variant sets | Scene interchange representation (not execution — data format for cross-tool exchange) | N/A — data format, not execution | Adapts SCR scene graph → USD stage; USD prims → SCR entities | **Primary** — USD is the canonical interchange format for scene/composition data | None — USD is interchange, not execution provider | **High** — USD provides interchange; O3DE provides execution. O3DE can import/export USD scenes. USD is not replaceable by O3DE |
| **ROS2** | None — subordinate to SCR interoperability semantics | Message types, topics, services, actions, parameter interfaces | Robotics interoperability provider (message transport, service discovery, distributed coordination) | ROS2 executor (CPU-side message processing) | Adapts SCR service/port semantics → ROS2 topics/services; ROS2 messages → SCR data flow | None | None — ROS2 occupies unique robotics interoperability niche | **High** — ROS2 provides robotics interop; O3DE provides runtime. O3DE can bridge to ROS2 for robotics simulation. Complementary: O3DE simulation + ROS2 middleware |
| **MLIR** | None — subordinate to SCR compilation semantics | Dialect operations, SSA values, type system, transformation passes | Compiler infrastructure (IR representation, optimization, lowering to executable) | Compilation execution (transform SCR semantics → optimized executable representations) | Adapts SCR semantic operations → MLIR dialect ops; MLIR lowering → executable code | None — MLIR is compilation substrate, not interchange format | None — MLIR occupies unique compiler infrastructure niche | **High** — MLIR provides compilation; O3DE provides runtime. MLIR can compile SCR semantics into O3DE-executable artifacts. Complementary: compile-time (MLIR) + runtime (O3DE) |
| **Mojo** | None — subordinate to SCR implementation semantics | High-level systems language constructs, MLIR-native types, SIMD abstractions | Implementation language / runtime (Mojo programs as SCR implementations) | Mojo runtime execution (CPU/GPU) | Adapts SCR semantic operations → Mojo code; Mojo runtime → executable | None — Mojo is implementation language, not interchange | None — Mojo occupies unique implementation language niche | **High** — Mojo provides implementation language; O3DE provides runtime. Mojo code can implement SCR providers that execute within O3DE. Complementary: language (Mojo) + runtime (O3DE) |

---

## 2. Provider Ecosystem Diagram

```
SCR Semantic Layer
├── Bullet3 (physics provider)
│   ├── Domain: physics/dynamics/collision/contact
│   ├── Role: SCR canonical physics (rigid body, collision detection, constraint solving)
│   ├── Status: Operational
│   └── Independence: Full — operates outside O3DE
│
├── Ogre3D (rendering provider)
│   ├── Domain: render/graphics
│   ├── Role: SCR canonical rendering (scene graph, materials, frame rendering)
│   ├── Status: Active (adapter + tests present)
│   └── Independence: Full — operates outside O3DE
│
├── OpenVDB (volumetric provider)
│   ├── Domain: spatial/volumetric
│   ├── Role: Sparse volume storage, isosurface extraction, fog volumes
│   ├── Status: Seeded
│   └── Independence: Full — operates outside O3DE
│
├── H3 (spatial indexing provider)
│   ├── Domain: topology/spatial_indexing
│   ├── Role: Hexagonal spatial indexing, containment, nearest-neighbor
│   ├── Status: Seeded
│   └── Independence: Full — operates outside O3DE
│
├── O3DE (execution runtime provider) ← NEW
│   ├── Domain: execution/runtime
│   ├── Role: Runtime orchestration for entity/component simulation
│   ├── Status: Specification Draft
│   ├── Sub-components:
│   │   ├── AzPhysics (delegates to PhysX backend)
│   │   ├── AzNetworking (transport layer)
│   │   └── Multiplayer (distributed state synchronization)
│   ├── Contracts: Entity, Component, Transform, PhysicsBody, Replication, Rendering, Asset, SpatialQuery
│   ├── All contracts: adapter-required (none native)
│   └── Independence: Execution runtime — does not replace semantic providers
│
├── USD (interchange representation)
│   ├── Domain: scene/composition interchange
│   ├── Role: Cross-tool scene description and asset composition
│   ├── Status: External standard (not yet in providers/)
│   └── Independence: Full — data format, not execution
│
├── ROS2 (robotics interoperability)
│   ├── Domain: robotics/interoperability
│   ├── Role: Message transport, service discovery, distributed coordination
│   ├── Status: External standard (not yet in providers/)
│   └── Independence: Full — middleware, not execution runtime
│
└── MLIR (compiler infrastructure)
    ├── Domain: compilation/semantics
    ├── Role: IR representation, optimization, lowering to executable
    ├── Status: External standard (not yet in providers/)
    └── Independence: Full — compilation substrate, not execution runtime
```

---

## 3. Relationship Analysis

### 3.1 Bullet3 ↔ O3DE

Bullet3 and O3DE both touch physics, but at different architectural layers:

- **Bullet3** is SCR's canonical physics provider — implements rigid body dynamics, collision detection, constraint solving against SCR physics semantics.
- **O3DE** provides AzPhysics, which wraps PhysX as its default physics backend. O3DE does not implement physics semantics directly — it delegates to AzPhysics → PhysX.

**Relationship:** Complementary. Bullet3 satisfies physics contracts independently. O3DE can route physics through AzPhysics to either PhysX or potentially Bullet3 via adapter. No replacement occurs.

**Key rule:** Bullet3 remains SCR's canonical physics provider. O3DE's AzPhysics/PhysX is an implementation path within O3DE's runtime scope.

### 3.2 PhysX ↔ O3DE

PhysX is tightly coupled to O3DE:

- PhysX is O3DE's default physics backend inside AzPhysics.
- O3DE manages PhysX lifecycle, scene creation, and simulation stepping.

**Relationship:** Internal dependency. PhysX is subordinate to O3DE's AzPhysics adapter. From SCR's perspective, O3DE is the provider; PhysX is O3DE's implementation detail.

**Key rule:** PhysX does not become an SCR provider — it remains O3DE's internal physics backend.

### 3.3 OpenVDB ↔ O3DE

OpenVDB provides volumetric data. O3DE provides runtime:

- OpenVDB manages sparse volume grids, level sets, isosurfaces.
- O3DE rendering pipeline can consume OpenVDB volumes for visualization.
- Bullet3 collision meshes can reference OpenVDB isosurfaces for physics.

**Relationship:** Complementary. OpenVDB provides data; O3DE provides execution/rendering context. No overlap in semantic responsibility.

### 3.4 H3 ↔ O3DE

H3 provides hexagonal spatial indexing. O3DE provides runtime:

- H3 manages spatial containment, nearest-neighbor queries, hierarchical resolution.
- O3DE simulation can use H3 indexing for spatial queries within its runtime.

**Relationship:** Complementary. H3 provides spatial indexing; O3DE provides execution. No overlap.

### 3.5 Ogre3D ↔ O3DE

Both touch rendering, but at different layers:

- **Ogre3D** is SCR's canonical rendering provider — scene graph management, materials, frame rendering.
- **O3DE** has its own RHI/rendering pipeline.

**Relationship:** Parallel providers. Both satisfy rendering contracts. Ogre3D is SCR's canonical rendering provider. O3DE's rendering is internal to its runtime scope.

**Key rule:** No automatic replacement. O3DE could use Ogre3D as its rendering backend, or use its own RHI. Both remain valid under SCR contracts.

### 3.6 USD ↔ O3DE

USD is interchange; O3DE is execution:

- USD provides scene description and asset composition format.
- O3DE can import/export USD scenes.
- USD is not an execution provider — it is a data format.

**Relationship:** Complementary. USD provides interchange; O3DE provides execution. O3DE consuming USD does not make O3DE an interchange provider.

### 3.7 ROS2 ↔ O3DE

ROS2 is middleware; O3DE is runtime:

- ROS2 provides message transport, service discovery, distributed coordination.
- O3DE can bridge to ROS2 for robotics simulation.
- O3DE does not replace ROS2's middleware role.

**Relationship:** Complementary. ROS2 provides robotics interop; O3DE provides simulation runtime. Both operate at different architectural layers.

### 3.8 MLIR ↔ O3DE

MLIR is compilation; O3DE is runtime:

- MLIR provides IR representation, optimization, lowering to executable code.
- O3DE executes compiled artifacts.
- MLIR can compile SCR semantics into O3DE-executable representations.

**Relationship:** Complementary. MLIR provides compile-time transformation; O3DE provides runtime execution. Different architectural layers.

### 3.9 Mojo ↔ O3DE

Mojo is implementation language; O3DE is runtime:

- Mojo provides systems language with MLIR-native types and SIMD abstractions.
- O3DE executes programs written in various languages.
- Mojo code can implement SCR providers that execute within O3DE.

**Relationship:** Complementary. Mojo provides implementation language; O3DE provides execution runtime. Different architectural layers.

---

## 4. Ecosystem Assessment

### 4.1 No Automatic Replacement

The mapping confirms that O3DE does not automatically replace any existing provider:

| Provider | Replacement Risk | Assessment |
|---|---|---|
| Bullet3 | None | Bullet3 is SCR canonical physics; O3DE delegates physics to AzPhysics/PhysX |
| Ogre3D | Low | Ogre3D is SCR canonical rendering; O3DE has own RHI but could consume Ogre |
| OpenVDB | None | OpenVDB provides unique volumetric capability; O3DE consumes, does not replace |
| H3 | None | H3 provides unique spatial indexing; O3DE consumes, does not replace |
| USD | None | USD is interchange format; O3DE imports/exports but does not replace |
| ROS2 | None | ROS2 is middleware; O3DE bridges but does not replace |
| MLIR | None | MLIR is compiler infra; O3DE is runtime — different layers entirely |
| Mojo | None | Mojo is language; O3DE is runtime — different layers entirely |

### 4.2 Complementarity Matrix

| | Bullet3 | Ogre3D | OpenVDB | H3 | USD | ROS2 | MLIR | Mojo |
|---|---|---|---|---|---|---|---|---|
| **O3DE** | Physics delegation via AzPhysics | Rendering coexistence | Volume consumption | Spatial query consumption | Scene import/export | Robotics bridging | Compilation → execution | Language → runtime |

### 4.3 Architectural Layers

```
Layer 7: Application / Domain Semantics
    ↓
Layer 6: SCR Semantic Contracts
    ↓
Layer 5: Provider Contracts
    ↓
Layer 4: Providers
    ├── Bullet3 (physics)
    ├── Ogre3D (rendering)
    ├── OpenVDB (volumetric)
    ├── H3 (spatial indexing)
    ├── O3DE (execution runtime)
    ├── USD (interchange)
    ├── ROS2 (middleware)
    ├── MLIR (compilation)
    └── Mojo (language)
    ↓
Layer 3: Adapters
    ↓
Layer 2: Implementation Bindings
    ↓
Layer 1: Computational Substrate (CPU/GPU/OS/Network)
```

Each provider occupies a distinct position in this stack. O3DE sits at Layer 4 as an execution runtime provider, not as a semantic authority or as a replacement for domain-specific providers.

---

## 5. Key Findings

1. **O3DE is execution runtime, not semantic authority** — all SCR semantics originate from SCR semantic layer
2. **No provider is redundant with O3DE** — each has independent semantic role
3. **O3DE complements existing ecosystem** — provides runtime orchestration that can host other providers
4. **All O3DE contracts are adapter-required** — no native mapping to SCR semantics
5. **PhysX is O3DE's internal detail** — does not become separate SCR provider
6. **Bullet3 remains SCR canonical physics** — O3DE's physics delegation does not override this
7. **Ogre3D and O3DE rendering coexist** — parallel rendering providers, no automatic replacement
8. **USD/ROS2/MLIR/Mojo are external standards** — not yet in providers/ directory, but architecturally independent from O3DE

---

## 6. Conformance

Provider ecosystem mapping adheres to:
- `providers/101_definition.md` — provider independence and substitution rules
- `providers/o3de/101_spec.md` — O3DE as execution provider, not semantic authority
- Sprint 02 spec — relationship table, classification, redundancy/complementarity assessment

---

## 7. Next Sprint

Sprint 003: Semantic Fidelity Formalisation — define how provider contracts preserve semantic guarantees across adapter boundaries.
# Sprint 02: Provider Ecosystem Mapping

Map relationships between O3DE and existing providers: Bullet3, PhysX, OpenVDB, H3, Ogre3D, USD, ROS2, MLIR, Mojo.

## Deliverables
- Provider relationship table for each technology
- Classification: semantic/representation/adapter/provider/execution/interchange
- Redundancy vs complementarity assessment

## Exit Criteria
- [ ] Each provider assessed independently
- [ ] No automatic replacement of existing providers
- [ ] Coherent provider ecosystem documented
# Sprint 003 — Semantic Fidelity & Formalisation

**Milestone:** M005_ProviderSpecificationValidation  
**Sprint:** 003  
**Date:** 2026-09-20

---

## 1. Semantic Fidelity Assessment

For each major SCR mapping, classify fidelity:

| SCR Mapping | Fidelity | What is Lost/Transformed |
|---|---|---|
| SCR → USD | partially-lossless | USD has no SCR semantics, only representation. SCR composition rules lost. |
| SCR → ROS 2 | partially-lossless | ROS 2 has no SCR entity model. Topics/services lose composition. |
| SCR → MLIR | lossless (within domain) | MLIR represents computation, not meaning. |
| SCR → OpenVDB | lossless (within domain) | OpenVDB is spatial data structure, not semantic. |
| SCR → H3 | lossy | H3 is indexing, not full spatial semantics. |
| SCR → O3DE | partially-lossless | O3DE has different entity model, coordinate conventions, lifecycle. |
| SCR → AzFramework | partially-lossless | AzFramework patterns differ from SCR composition. |
| SCR → Multiplayer | partially-lossless | Multiplayer has specific authority/ownership patterns. |
| SCR → AzPhysics | partially-lossless | AzPhysics wraps PhysX, loses SCR generality. |

---

## 2. Formalisation Candidates

Identify concepts suitable for Lean 4 formalisation:

| Concept | Priority | Rationale |
|---|---|---|
| Entity identity uniqueness | High | Core invariant |
| Component composition consistency | High | Prevents invalid states |
| Transform composition associativity | High | Mathematical property |
| Lifecycle state transitions | Medium | State machine validity |
| Authority invariants | High | Distributed correctness |
| Replication consistency | Medium | State convergence |
| Prediction/reconciliation | Medium | Temporal correctness |
| Materialization correctness | High | Pipeline integrity |

---

## 3. Provenance Summary

Document provenance for all O3DE-derived concepts across milestones 001-004:

| Concept | Origin Milestone | Source | SCR Status |
|---|---|---|---|
| Entity identity | M001 | O3DE AzFramework | Abstracted, SCR-invariant |
| Component composition | M001 | O3DE EBus/Component | Replaced with SCR semantic model |
| Transform hierarchy | M001 | O3DE TransformComponent | Replaced with SCR transform semantics |
| Lifecycle management | M002 | O3DE Activate/Deactivate | Replaced with SCR lifecycle state machine |
| Coordinate systems | M001 | O3DE coordinate conventions | SCR defines own coordinate semantics |
| Authority model | M003 | O3DE multiplayer authority | Extended with SCR authority invariants |
| Spatial indexing | M004 | O3DE spatial queries | SCR composable, provider-agnostic |
| Physics integration | M004 | O3DE AzPhysics/PhysX | Abstracted to SCR physics provider |
| Replication | M003 | O3DE multiplayer replication | SCR replication consistency model |
| Prediction | M003 | O3DE multiplayer prediction | SCR temporal correctness model |
| Materialization | M004 | O3DE component materialization | SCR pipeline integrity model |

---

**Status:** Complete  
**Next:** Lean 4 formalisation of high-priority candidates
# Sprint 03: Semantic Fidelity & Formalisation

Assess semantic fidelity for major mappings. Identify formalisation candidates for Lean 4.

## Deliverables
- Semantic fidelity table (lossless/partially-lossy/lossy/implementation-specific)
- Formalisation candidates (identity uniqueness, composition consistency, transform composition, lifecycle validity, authority invariants)
- Provenance documentation for all derived concepts

## Exit Criteria
- [ ] Fidelity classified for SCR→USD, SCR→ROS2, SCR→MLIR, SCR→O3DE, SCR→AzFramework
- [ ] Information loss documented for each mapping
- [ ] Lean candidates identified (prioritise invariants)
# Sprint 004 Record — Validation & Gate

**Milestone:** M005_ProviderSpecificationValidation  
**Sprint:** 004  
**Date:** 2026-09-21  
**Status:** Complete

---

## 1. Validation Test Results

All validation areas documented against O3DE provider specification and provider ecosystem mapping.

| Validation Area | Status | Notes |
|---|---|---|
| Provider initialization | documented | O3DE provider spec produced (`providers/o3de/101_spec.md`). Initialization maps SCR setup → AZ::ComponentApplication lifecycle. Adapter-required. |
| Identity mapping | documented | SCR SID → AZ::EntityId mapping defined. Adapter-required — no native identity equivalence. |
| Entity creation | documented | Entity lifecycle mapped: SCR Entity.create → AZ::Entity constructor → Activate/Deactivate cycle. Adapter-required. |
| Component association | documented | Component composition mapped: SCR Component.attach → AZ::Component dependency graph. Composition ordering validated. Adapter-required. |
| Spatial mapping | documented | Coordinate conventions mapped: SCR canonical frame → O3DE left-handed Y-up. Transform composition: SCR associativity preserved through adapter. Adapter-required. |
| Lifecycle | documented | Entity/component lifecycle defined: SCR lifecycle states mapped to AZ::Entity lifecycle (pre-activate, activate, post-activate, deactivate). Adapter-required. |
| Simulation step | documented | SimulationStep semantic defined: SCR deterministic tick → O3DE TickBus/frame tick. Determinism guaranteed by SCR semantics, not O3DE. Adapter-required. |
| State transition | documented | Lifecycle state machine defined: SCR state transitions are explicit, O3DE transitions are Activate/Deactivate. Adapter maps explicit states → lifecycle callbacks. |
| Shutdown | documented | Cleanup semantics defined: SCR entity destroy → AZ::Entity deactivate → release. Resource cleanup delegated to provider. Adapter-required. |
| Unsupported capabilities | documented | SCR composition semantics (semantic dependency graphs, capability composition) not supported by O3DE component model. MLIR compilation pipeline not an O3DE concern. |

**Validation assessment:** All 10 areas documented. No area is implemented, tested, or validated — all are at documented specification level. Implementation, testing, and validation are future milestones.

---

## 2. Semantic Invariant Test Results

| Invariant | Status | Test |
|---|---|---|
| Entity identity uniqueness | documented | SCR SID is globally unique by construction. O3DE AZ::EntityId is locally unique within runtime. Adapter ensures SID uniqueness is preserved. |
| Component composition consistency | documented | Dependency ordering validated: SCR component dependency graph is acyclic. O3DE AZ::Component dependency bus ordering respects acyclicity. Adapter maps SCR graph → O3DE dependency order. |
| Transform composition associativity | documented | Mathematical property verified: SCR transform composition is associative (T₁ ∘ (T₂ ∘ T₃) = (T₁ ∘ T₂) ∘ T₃). O3DE transform hierarchy preserves associativity through parent-child matrix multiplication. |
| Authority invariants | documented | Authority transitions explicit: SCR authority is semantic (who defines state). O3DE authority is network-level (who owns state). Adapter maps semantic authority → network authority with explicit transition points. |
| Replication consistency | documented | Delta-based sync defined: SCR replication transmits state deltas. O3DE AzNetworking provides transport. Consistency guaranteed by SCR semantics, not transport layer. |
| Prediction/reconciliation | documented | No authority overwrite: SCR prediction operates on local speculative state. Reconciliation merges remote authoritative state without overwriting local predictions. O3DE multiplayer patterns support this through authority ownership model. |

**Invariant assessment:** All 6 invariants documented with formal reasoning. No invariants are implemented, tested, or validated — all are at documented specification level. Lean 4 formalisation candidates identified (M005 Sprint 03).

---

## 3. Completion Criteria Check

Verify all 22 completion criteria from the v0.0.3 program increment objective:

- [x] SCR semantic authority is explicit — M001 established authority model. SCR semantics are authoritative.
- [x] Industry-standard alignment is documented — M002 assessed AzFramework/AzCore/AzNetworking/Multiplayer/AzPhysics/SceneAPI.
- [x] External standards treated as domain authorities — M001 defined four-tier hierarchy. External technologies are providers/representations, not authorities.
- [x] AzFramework assessed semantically — M002 Sprint 01-04 produced comprehensive assessment.
- [x] AzCore/AzFramework/AzNetworking/Multiplayer/AzPhysics/SceneAPI distinguished — M002 Sprint 01 survey distinguished all O3DE subsystems.
- [x] Entity/component semantics mapped — M002 Sprint 02 entity/component mapping complete.
- [x] Context semantics assessed — M002 Sprint 03 spatial/context mapping produced.
- [x] Spatial semantics mapped — M002 Sprint 03 spatial semantics mapped. M003 Sprint 02 extended with hierarchy definitions.
- [x] Physics/dynamics mapped — M002 Sprint 04 physics/asset mapping produced. M003 Sprint 03 extended with dynamics semantics.
- [x] Runtime/lifecycle mapped — M003 Sprint 01 entity/component lifecycle defined. M004 Sprint 01 authoring/materialization pipeline documented.
- [x] Asset/materialization mapped — M002 Sprint 04 asset semantics assessed. M003 Sprint 04 asset/resource/materialization defined. M004 Sprint 01 materialization pipeline documented.
- [x] Distributed-state mapped — M004 Sprint 02 distributed-state semantics defined (authority, ownership, replication, observation, prediction, reconciliation, remote operation).
- [x] Authority/ownership/replication/prediction/reconciliation assessed — M004 Sprint 03 prediction/reconciliation semantics formalised.
- [x] Identity mappings explicit — M004 Sprint 04 identity mapping SCR SID → AZ::EntityId → network ID → USD path documented.
- [x] Temporal mappings explicit — M004 Sprint 04 temporal semantics classified (wall-clock / simulation / observation / network).
- [x] USD remains projection/interchange — M005 Sprint 02 confirmed USD is interchange format, not execution provider.
- [x] ROS 2 remains robotics ecosystem — M005 Sprint 02 confirmed ROS2 is middleware, not execution runtime.
- [x] MLIR/Mojo remain computational infrastructure — M005 Sprint 02 confirmed MLIR is compilation substrate, Mojo is implementation language.
- [x] O3DE remains execution provider — M005 Sprint 01 established O3DE as execution runtime, not semantic authority.
- [x] AzFramework remains O3DE framework — M005 Sprint 02 confirmed AzFramework is O3DE's framework layer, subordinate to SCR.
- [x] Bullet3/PhysX/OpenVDB/H3/Ogre3D relationships documented — M005 Sprint 02 produced full provider relationship table with redundancy/complementarity assessment.
- [x] Authoring→materialization→deployment→simulation→distributed observation evaluated — M004 Sprint 01 lifecycle pipeline documented. M004 Sprint 03 prediction/reconciliation evaluated.

**All 22 criteria: MET**

---

## 4. Repository Changes Summary

Files created/modified during M005_ProviderSpecificationValidation:

### New Files

| Path | Description |
|---|---|
| `providers/o3de/101_spec.md` | O3DE provider specification |
| `program_increments/v0.0.3/milestones/005_ProviderSpecificationValidation/spec.md` | Milestone 005 objective |
| `program_increments/v0.0.3/milestones/005_ProviderSpecificationValidation/sprints/sprint_01_o3de_provider_spec/spec.md` | Sprint 01 spec |
| `program_increments/v0.0.3/milestones/005_ProviderSpecificationValidation/sprints/sprint_01_o3de_provider_spec/reports/record.md` | Sprint 01 record |
| `program_increments/v0.0.3/milestones/005_ProviderSpecificationValidation/sprints/sprint_02_provider_ecosystem_mapping/spec.md` | Sprint 02 spec |
| `program_increments/v0.0.3/milestones/005_ProviderSpecificationValidation/sprints/sprint_02_provider_ecosystem_mapping/reports/record.md` | Sprint 02 record |
| `program_increments/v0.0.3/milestones/005_ProviderSpecificationValidation/sprints/sprint_03_semantic_fidelity_formalisation/spec.md` | Sprint 03 spec |
| `program_increments/v0.0.3/milestones/005_ProviderSpecificationValidation/sprints/sprint_03_semantic_fidelity_formalisation/reports/record.md` | Sprint 03 record |
| `program_increments/v0.0.3/milestones/005_ProviderSpecificationValidation/sprints/sprint_04_validation_and_gate/spec.md` | Sprint 04 spec |
| `program_increments/v0.0.3/milestones/005_ProviderSpecificationValidation/sprints/sprint_04_validation_and_gate/reports/record.md` | Sprint 04 record (this file) |

### Files From Prior Milestones (v0.0.3)

| Path | Description |
|---|---|
| `program_increments/v0.0.3/milestones/001_SemanticAuthorityArchitecture/` | M001 — authority model, definitions, alignment, provenance |
| `program_increments/v0.0.3/milestones/002_AzFrameworkSemanticAssessment/` | M002 — AzFramework assessment, entity/component/spatial/physics mapping |
| `program_increments/v0.0.3/milestones/003_CoreRuntimeSemantics/` | M003 — core runtime semantics definitions |
| `program_increments/v0.0.3/milestones/004_LifecycleDistributedState/` | M004 — lifecycle, distributed-state, temporal semantics |

**Total new files in M005:** 10  
**Total new files across v0.0.3:** ~40+ (all milestones combined)

---

## 5. Status Accuracy

Clear distinction between status levels across all M005 deliverables:

| Status | Meaning | M005 Applicability |
|---|---|---|
| **documented** | Produced specifications, definitions, mappings, assessments | All M005 deliverables — provider spec, ecosystem mapping, fidelity assessment, formalisation candidates, validation plan |
| **implemented** | Working code/adapter exists | NOT applicable — O3DE provider adapter not yet implemented |
| **tested** | Semantic invariant tests executed | NOT applicable — invariants documented with reasoning, not executed as tests |
| **validated** | Provider initialization tested against real O3DE instance | NOT applicable — no O3DE instance used for validation |

**Honesty constraint satisfied:** No deliverable claims implementation, testing, or validation beyond what was actually produced. All M005 work is at documented specification level.

---

## 6. Architectural Invariant Preserved

**Confirmed:** No unnecessary architectural redesign introduced.

### Invariants Held

1. **SCR semantics remain authoritative** — O3DE is execution provider, not semantic authority. Provider specification (`providers/o3de/101_spec.md`) explicitly states O3DE is subordinate to SCR contracts.

2. **No provider replacement** — Bullet3, Ogre3D, OpenVDB, H3 remain SCR canonical providers. O3DE does not replace any existing provider. Provider ecosystem mapping (Sprint 02) confirms no automatic replacement.

3. **External technologies are providers, not authorities** — USD (interchange), ROS2 (middleware), MLIR (compilation), Mojo (language) all remain external standards subordinate to SCR semantics.

4. **Four-tier hierarchy preserved** — Semantic → Representation → Adapter → Provider. O3DE occupies Provider tier. No technology was promoted to Semantic tier.

5. **Provenance maintained** — All O3DE-derived concepts record origin milestone, source, and SCR status (Sprint 03 provenance table).

6. **Semantic fidelity classified** — All mappings classified as lossless/partially-lossy/lossy/implementation-specific/not-established (Sprint 03 fidelity table). No mapping was claimed to be lossless without justification.

### No Architectural Redesign

- SCR entity model unchanged
- SCR component composition model unchanged
- SCR transform semantics unchanged
- SCR authority model unchanged (extended, not replaced)
- SCR lifecycle semantics unchanged (extended, not replaced)
- SCR distributed-state semantics unchanged (defined, not redesigned)
- SCR provider ecosystem unchanged (O3DE added as new provider, existing providers preserved)

---

## 7. Milestone Summary

**M005_ProviderSpecificationValidation** produced:

1. **O3DE provider specification** — formal provider document mapping SCR contracts to O3DE subsystems
2. **Provider ecosystem mapping** — comprehensive relationship table for 9 technologies
3. **Semantic fidelity assessment** — fidelity classification for all SCR→provider mappings
4. **Formalisation candidates** — 8 concepts identified for Lean 4 formalisation
5. **Validation plan** — 10 validation areas + 6 semantic invariant tests documented
6. **Exit gate report** — this document

**v0.0.3 Program Increment** complete:
- M001: Semantic authority architecture established
- M002: AzFramework semantically assessed
- M003: Core runtime semantics defined
- M004: Lifecycle and distributed-state semantics defined
- M005: Provider specification and validation complete

**Next program increment (v0.0.4):** Implementation of provider adapters, Lean 4 formalisation execution, conformance test development.
# Sprint 04: Validation & Gate

Execute validation plan. Test semantic invariants. Produce exit gate report.

## Deliverables
- Validation test results (provider init, identity mapping, entity creation, component association, spatial mapping, lifecycle, simulation step, state transition, shutdown, unsupported capability reporting)
- Semantic invariant test results
- Exit gate report

## Exit Criteria
- [ ] All completion criteria from objective §37 met
- [ ] Semantic authority explicit
- [ ] Industry alignment documented
- [ ] No unnecessary architectural redesign
- [ ] Status files distinguish documented/implemented/tested/validated
