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
