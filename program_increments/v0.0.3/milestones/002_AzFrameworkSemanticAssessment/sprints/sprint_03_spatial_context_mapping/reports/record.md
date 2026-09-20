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
