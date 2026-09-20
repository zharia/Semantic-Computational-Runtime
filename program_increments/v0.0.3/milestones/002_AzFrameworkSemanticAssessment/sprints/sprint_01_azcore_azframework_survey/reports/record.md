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
