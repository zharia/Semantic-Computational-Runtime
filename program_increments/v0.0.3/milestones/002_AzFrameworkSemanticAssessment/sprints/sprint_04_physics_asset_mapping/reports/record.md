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

