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
