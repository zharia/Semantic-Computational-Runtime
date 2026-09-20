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
