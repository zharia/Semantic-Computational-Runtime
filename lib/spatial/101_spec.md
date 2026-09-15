# SCR Spatial Library Specification

**Library:** `lib/spatial`
**Specification:** `101_spec.md`
**Version:** `0.1.0`
**Status:** Draft
**Domain:** Spatial
**Authority:** SCR Spatial Domain Specification

---

## 1. Purpose

The `spatial` library provides the canonical SCR semantic interface for spatial computation.

It defines the library-level representation of concepts established by:

* `docs/114_SPATIAL_SEMANTICS.md`
* `docs/115_SPATIAL_PARTITIONING_MODEL.md`
* `docs/116_SPATIAL_STATE_MODEL.md`

The library provides semantic types, capabilities, operations, relations, and conformance requirements for spatial computation.

The library MUST remain independent of any particular spatial provider.

Providers such as:

* H3;
* OpenVDB;
* CGAL;
* GPU memory;
* tensor runtimes;
* databases;
* custom spatial indexes;

MAY implement capabilities exposed by this library.

They MUST NOT redefine the semantics of the library.

---

# 2. Domain Definition

The SCR Spatial domain represents semantic relationships between:

* spatial spaces;
* reference frames;
* coordinates;
* locations;
* regions;
* boundaries;
* partitions;
* state;
* locality;
* residency;
* ownership;
* transformations;
* execution.

The domain exists to answer three fundamental questions:

```text
Where is semantic structure?
        ↓
How is computational locality organised?
        ↓
What state is manifested there?
```

These questions MUST remain semantically distinct.

---

# 3. Architectural Position

The spatial library is a semantic domain within SCR.

```text
Semantic Field
      │
      ↓
Spatial Domain
      │
      ├── Spatial Semantics
      ├── Spatial Partitioning
      ├── Spatial State
      ├── Spatial Relations
      ├── Spatial Transformations
      └── Spatial Capabilities
```

The library does not own:

* execution;
* storage;
* transport;
* scheduling;
* rendering;
* physics;
* numerical implementation.

Those concerns MAY consume or provide spatial capabilities.

---

# 4. Normative Authority

The semantic authority hierarchy is:

```text
Semantic Field
    ↓
SCR Domain Semantics
    ↓
Spatial Semantic Specifications
    ↓
lib/spatial API
    ↓
Provider Implementations
```

The following documents are authoritative for this library:

1. `docs/114_SPATIAL_SEMANTICS.md`
2. `docs/115_SPATIAL_PARTITIONING_MODEL.md`
3. `docs/116_SPATIAL_STATE_MODEL.md`

If an implementation convenience conflicts with these documents, the implementation MUST change.

---

# 5. Fundamental Invariants

The library MUST preserve:

```text
Coordinate ≠ Location
Location ≠ Partition
Partition ≠ State
State ≠ Representation
Representation ≠ Residency
Residency ≠ Execution Resource
```

The implementation MAY combine these concepts internally for efficiency.

The public semantic interface MUST NOT collapse them.

---

# 6. Core Semantic Types

The library SHOULD provide semantic types corresponding to the following concepts.

## 6.1 SpatialSpace

Represents a semantic spatial domain.

Conceptually:

```text
SpatialSpace
```

A `SpatialSpace` defines the universe in which spatial locations and regions have meaning.

---

## 6.2 ReferenceFrame

Defines the interpretation of spatial coordinates.

Conceptually:

```text
ReferenceFrame
```

A reference frame MAY define:

* dimensionality;
* units;
* origin;
* orientation;
* coordinate interpretation;
* transformation relationships.

A reference frame MUST NOT be assumed to be universal.

---

## 6.3 Coordinate

Represents a coordinate within a declared reference frame.

Conceptually:

```text
Coordinate
    frame
    components
```

A coordinate without a reference frame SHOULD be considered semantically incomplete unless the surrounding type establishes the frame.

---

## 6.4 Location

Represents a semantic spatial position.

A location MAY be represented by a coordinate but is not equivalent to the coordinate representation.

Conceptually:

```text
Location
    space
    reference_frame
    coordinate
```

---

## 6.5 Region

Represents a spatial domain containing zero or more locations.

A region MAY be:

* continuous;
* discrete;
* bounded;
* unbounded;
* connected;
* disconnected;
* static;
* dynamic.

---

## 6.6 Boundary

Represents the semantic boundary of a region.

A boundary MUST remain distinct from the region it bounds.

---

## 6.7 Partition

Represents a computational locality within a spatial domain.

A partition has semantic identity independent of:

* coordinates;
* physical addresses;
* network addresses;
* execution processes;
* provider objects.

---

## 6.8 PartitionHierarchy

Represents parent/child relationships between partitions.

The hierarchy MAY support:

* refinement;
* coarsening;
* dynamic subdivision;
* lazy materialisation.

---

## 6.9 SpatialState

Represents semantic state associated with spatial structure.

Conceptually:

```text
SpatialState
    identity
    domain
    association
    representation
    resolution
    partition
    authority
    residency
    temporal_validity
```

Not all attributes need to be physically materialised.

---

## 6.10 StateRepresentation

Represents a concrete encoding of semantic state.

Examples:

```text
DenseTensor
SparseTensor
VoxelField
Mesh
PointCloud
ProviderObject
GPUBuffer
```

These are representations, not semantic spatial ontologies.

---

## 6.11 StateResidency

Identifies where a state representation is physically materialised.

Examples:

```text
CPU
GPU
Storage
RemoteNode
Cache
Provider
```

Residency MUST remain separate from state identity.

---

## 6.12 SpatialTransform

Represents a semantic transformation between spatial representations.

Examples:

```text
ReferenceFrame A → ReferenceFrame B
SCR Coordinate → Provider Coordinate
World → Local
Continuous → Discrete
```

A transform MUST identify its source and target semantics.

---

## 6.13 SpatialRelation

Represents a semantic relationship between spatial objects.

Examples:

```text
contains
contained_by
adjacent_to
overlaps
intersects
near
disjoint_from
within
```

---

# 7. Partition Types

The library SHOULD support explicit partition semantics.

## 7.1 PartitionIdentity

Stable semantic identity for a partition.

It MUST NOT be derived solely from:

* provider object ID;
* process ID;
* machine address;
* memory address.

---

## 7.2 PartitionAddress

A partition address MAY contain:

```text
space_id
partition_id
hierarchy_path
provider_reference
```

Provider-specific components MUST remain explicitly identified as provider references.

---

## 7.3 PartitionMembership

Represents association between state/location/region and partition.

Conceptually:

```text
membership(object, partition)
```

Membership MAY be:

* exclusive;
* overlapping;
* replicated;
* weighted;
* transient;
* hierarchical.

---

## 7.4 PartitionNeighbourhood

Represents locality relationships between partitions.

A neighbourhood MAY be geometric or computational.

For example:

```text
P1 adjacent P2
P1 communicates cheaply with P2
P1 shares state dependencies with P2
```

These relationships MUST be distinguishable where required.

---

# 8. State Types

The library SHOULD expose explicit state lifecycle concepts.

```text
StateIdentity
StateVersion
StateDomain
StateRepresentation
StateResidency
StateAuthority
StateProvenance
StateValidity
```

The implementation MUST distinguish:

```text
undefined
empty
null
unmaterialised
unavailable
materialised
resident
invalid
deleted
```

where the domain requires those distinctions.

---

# 9. Capability Model

The library SHOULD expose capabilities rather than implementation types.

Suggested capabilities:

```text
SpatialCoordinateCapability
SpatialTransformCapability
SpatialRegionCapability
SpatialRelationCapability

SpatialPartitionCapability
SpatialHierarchyCapability
SpatialLocalityCapability

SpatialStateCapability
SpatialStateReadCapability
SpatialStateWriteCapability
SpatialStateTransformCapability
SpatialStateMigrationCapability
SpatialStateReplicationCapability

SpatialMaterialisationCapability
SpatialResidencyCapability
```

A provider MAY implement one or more capabilities.

---

# 10. Provider Model

A provider is an implementation of one or more spatial capabilities.

Conceptually:

```text
Spatial Capability
       │
       ↓
Provider
       │
       ├── H3
       ├── OpenVDB
       ├── CGAL
       ├── Tensor Runtime
       └── Custom Provider
```

The semantic layer MUST depend on capabilities rather than provider names.

---

# 11. H3 Provider Contract

An H3 provider MAY implement:

```text
SpatialPartitionCapability
SpatialHierarchyCapability
SpatialLocalityCapability
SpatialNeighbourhoodCapability
```

H3 MAY provide:

* hierarchical partitions;
* parent/child relationships;
* neighbour relationships;
* partition lookup;
* spatial locality;
* partition routing.

H3 MUST NOT define:

```text
SCR Coordinate
SCR ReferenceFrame
SCR SpatialState
SCR SpatialIdentity
```

An H3 index MUST be represented as a provider partition reference.

---

# 12. OpenVDB Provider Contract

An OpenVDB provider MAY implement:

```text
SpatialStateCapability
SpatialStateReadCapability
SpatialStateWriteCapability
SpatialStateTransformCapability
SpatialHierarchyCapability
SpatialMaterialisationCapability
```

OpenVDB MAY provide:

* sparse volumetric state;
* hierarchical storage;
* voxel access;
* sparse topology;
* spatial transforms;
* state materialisation.

OpenVDB's native coordinate system MUST remain a provider representation.

It MUST NOT automatically become an SCR reference frame.

---

# 13. Coordinate Semantics

Coordinates MUST carry sufficient semantic information to interpret their values.

At minimum, an implementation SHOULD be able to determine:

```text
space
reference_frame
dimensionality
components
units
```

A provider MAY use a different internal coordinate representation.

The provider MUST expose the mapping to the SCR semantic representation where required.

---

# 14. Coordinate Transform

The library SHOULD expose an operation equivalent to:

```text
transform_coordinate(
    coordinate,
    source_frame,
    target_frame
)
```

The transformation MUST specify:

* source frame;
* target frame;
* dimensionality;
* units;
* transformation semantics;
* precision;
* validity.

Transformations MUST NOT silently alter semantic identity.

---

# 15. Region Operations

The library SHOULD support:

```text
contains(region, location)
intersects(region_a, region_b)
overlaps(region_a, region_b)
adjacent(region_a, region_b)
distance(region_a, region_b)
boundary(region)
```

Operations MUST be defined against semantic spatial objects rather than provider objects.

---

# 16. Partition Operations

The library SHOULD support:

```text
locate(location)
partition(region)
membership(object, partition)
parent(partition)
children(partition)
neighbours(partition)
refine(partition)
coarsen(partition)
```

The actual implementation MAY delegate these operations to a provider.

---

# 17. Partition Refinement

Conceptually:

```text
refine(P) → {P1, P2, ..., Pn}
```

Refinement MUST preserve:

* parent identity;
* hierarchy integrity;
* membership semantics;
* state associations.

Refinement MUST NOT silently delete state.

---

# 18. Partition Coarsening

Conceptually:

```text
coarsen({P1, P2, ..., Pn}) → P
```

Coarsening MUST preserve semantic state.

Where state cannot be represented exactly at the coarser level, the implementation MUST use an explicitly declared aggregation or preservation strategy.

---

# 19. State Operations

The library SHOULD provide semantic operations equivalent to:

```text
declare_state()
associate_state()
read_state()
write_state()
materialise_state()
dematerialise_state()
transform_state()
refine_state()
coarsen_state()
replicate_state()
migrate_state()
invalidate_state()
retire_state()
```

Each operation MUST define semantic preconditions and postconditions.

---

# 20. State Access

The preferred semantic access pattern is:

```text
read_state(
    state,
    domain,
    resolution,
    consistency
)
```

rather than exposing provider-specific access primitives directly.

The provider MAY satisfy the request using any valid representation.

---

# 21. Partial State Access

The library SHOULD support requests for a subset of state.

Example:

```text
State:       S42
Region:      R17
Resolution:  adaptive
Version:     v12
Consistency: authoritative
```

The provider MAY return:

* an existing representation;
* a transformed representation;
* a materialised subset;
* a stream;
* a state reference.

---

# 22. State Materialisation

The library SHOULD expose:

```text
materialise_state(
    state,
    representation,
    residency
)
```

Materialisation MUST preserve semantic identity.

Example:

```text
S42
 ↓
OpenVDB representation
 ↓
GPU residency
```

does not create a new semantic state unless explicitly requested.

---

# 23. State Dematerialisation

The library SHOULD expose:

```text
dematerialise_state(
    state,
    representation
)
```

Dematerialisation MUST NOT imply deletion.

---

# 24. State Migration

The library SHOULD expose:

```text
migrate_state(
    state,
    source_partition,
    target_partition
)
```

Migration MUST preserve state identity.

It MAY involve:

```text
serialisation
transfer
reconstruction
synchronisation
authority transfer
```

depending on the provider.

---

# 25. State Replication

The library SHOULD expose:

```text
replicate_state(
    state,
    target
)
```

Replication MUST preserve attribution to the originating semantic state.

Replication semantics MUST define consistency.

---

# 26. State Transformation

The library SHOULD expose:

```text
transform_state(
    state,
    target_representation
)
```

The transformation MUST declare whether it is:

```text
lossless
lossy
reversible
irreversible
exact
approximate
```

---

# 27. Resolution

Spatial state operations SHOULD permit explicit resolution.

Examples:

```text
exact
coarse
fine
adaptive
native
provider_defined
```

A provider's native resolution MUST NOT silently become the semantic resolution.

---

# 28. Spatial Locality

The library SHOULD expose locality queries such as:

```text
neighbours(location)
neighbours(region)
neighbours(partition)
distance(a, b)
locality(a, b)
```

Locality MAY be based on:

* geometry;
* partition topology;
* communication cost;
* execution affinity;
* data dependency.

The semantic meaning of each locality relation MUST be explicit.

---

# 29. Spatial Distance

Distance MUST be interpreted within a declared spatial reference model.

The library SHOULD support:

```text
distance(a, b)
```

where the implementation resolves the appropriate metric from the associated spatial semantics.

A provider's internal distance function MUST NOT silently define universal SCR distance semantics.

---

# 30. State Residency

The library SHOULD expose:

```text
residency(state)
materialisations(state)
resident_partitions(state)
```

Residency information MUST remain descriptive of physical manifestation.

It MUST NOT alter state identity.

---

# 31. Ownership and Authority

The library SHOULD expose:

```text
owner(state)
authority(state)
```

Ownership and authority MUST be distinct from residency.

A cached representation is not necessarily authoritative.

---

# 32. State Version

The library SHOULD expose:

```text
version(state)
history(state)
provenance(state)
```

Versions MUST remain subordinate to semantic identity.

---

# 33. Spatial State Reference

A state reference SHOULD contain sufficient information to safely resolve state.

Conceptually:

```text
SpatialStateRef {
    state_id
    version
    spatial_association
    representation
    provider
    provider_reference
    validity
}
```

Provider-specific fields MUST remain distinguishable from semantic fields.

---

# 34. Reference Validity

A state reference MAY become invalid due to:

* deletion;
* expiration;
* provider failure;
* version replacement;
* ownership transfer;
* revocation.

Reference invalidation MUST NOT automatically imply state deletion.

---

# 35. Relations

The library SHOULD provide semantic relation identifiers for:

```text
located_in
contains
contained_by

associated_with
represented_by
materialised_as
resident_in

partitioned_by
member_of
parent_of
child_of
adjacent_to

owned_by
authoritative_at

derived_from
transformed_from
replicated_from

depends_on
affects
```

These relations SHOULD be represented as semantic graph/hypergraph relationships where appropriate.

---

# 36. Hypergraph Integration

Spatial objects MUST be representable as semantic graph objects.

For example:

```text
State S42
   ├── associated_with → Region R7
   ├── member_of → Partition P3
   ├── represented_by → VDBObject V91
   ├── resident_in → GPU2
   └── transformed_by → T17
```

The graph representation MUST NOT replace the underlying spatial semantics.

---

# 37. Nullary Relations

Spatial relations MUST follow the SCR-wide nullary relation policy.

A relation with no spatial operands MUST NOT be silently interpreted as a spatial relation merely because it is implemented within the spatial library.

Domain-level nullary relations MUST have explicit semantic definitions.

---

# 38. Deletion and References

Spatial deletion MUST follow SCR reference semantics.

Deleting:

```text
state
partition
region
provider representation
```

are distinct operations.

A provider object deletion MUST NOT silently delete its associated semantic state.

Dangling references MUST be detectable.

Where deletion invalidates a reference, the invalidation MUST be semantically observable.

---

# 39. Error Semantics

Spatial operations SHOULD distinguish:

```text
InvalidCoordinate
InvalidReferenceFrame
InvalidTransform
UnknownLocation
UnknownPartition
InvalidMembership
StateUnavailable
StateUnmaterialised
StateInvalid
StateDeleted
ProviderUnavailable
RepresentationUnsupported
ResolutionUnsupported
ConsistencyUnsupported
TransformationInvalid
```

Provider-specific errors MAY be mapped into these semantic categories.

---

# 40. Conformance

An implementation conforms to the SCR Spatial Library if:

1. it preserves the spatial semantic invariants;
2. provider representations remain subordinate to semantic objects;
3. coordinate and partition semantics remain distinct;
4. partition and state semantics remain distinct;
5. materialisation and deletion remain distinct;
6. residency and identity remain distinct;
7. provider transformations are explicit;
8. state identity survives valid representation changes;
9. spatial references remain valid and attributable;
10. applicable state transformations preserve declared invariants.

---

# 41. Provider Conformance

A provider claiming a spatial capability MUST declare:

```text
provider_identity
capabilities
supported_dimensions
supported_reference_frames
supported_resolutions
supported_state_types
supported_operations
supported_consistency_models
supported_transformations
```

The provider MUST declare limitations rather than silently approximating unsupported semantics.

---

# 42. Conformance Testing

Spatial providers SHOULD be tested against semantic behaviour rather than implementation details.

Tests SHOULD verify:

```text
coordinate round-trip
reference-frame transformation
partition identity
partition refinement
partition coarsening
state identity
state materialisation
state dematerialisation
state migration
state replication
state versioning
state deletion
provider substitution
```

Where possible:

```text
Reference Executor
        ↓
semantic result
        ↓
provider implementation
        ↓
observed result
        ↓
differential verification
```

---

# 43. Reference Executor

The Reference Executor is the semantic oracle for spatial operations where practical.

Provider implementations MUST be evaluated by observable semantic behaviour.

The provider is not required to reproduce the internal implementation of the Reference Executor.

It is required to produce conformant observable semantics.

---

# 44. Provider Substitution Test

Given:

```text
Provider A
Provider B
```

implementing the same capability:

```text
SpatialStateCapability
```

the same semantic operation SHOULD produce equivalent semantic results.

Formally:

$$
Obs(A(op,S)) \equiv Obs(B(op,S))
$$

subject to declared:

* precision;
* resolution;
* consistency;
* approximation;
* ordering;
* provider-specific constraints.

---

# 45. Precision

Precision MUST be treated as representation metadata.

Providers MAY use:

* integer;
* fixed-point;
* float16;
* float32;
* float64;
* arbitrary precision.

The semantic layer MUST define acceptable precision requirements where precision affects correctness.

---

# 46. Determinism

Spatial operations SHOULD declare determinism.

An operation MAY be:

```text
deterministic
nondeterministic
implementation-defined
```

If nondeterminism affects semantic state, it MUST be represented explicitly.

---

# 47. Performance

Performance optimisation MUST NOT alter semantic meaning.

Providers MAY optimise using:

* spatial indexing;
* caching;
* SIMD;
* GPU execution;
* sparse structures;
* partition locality;
* asynchronous execution;
* replication.

The semantic API remains authoritative.

---

# 48. Implementation Guidance

The implementation SHOULD be organised conceptually around:

```text
lib/spatial/
    README.md
    101_spec.md
    102_status.yaml
    103_library.graph.json
```

Implementation modules MAY then be organised around:

```text
coordinate
reference
location
region
relation
transform
partition
state
residency
provider
capability
```

The exact source layout is implementation-defined.

---

# 49. Dependency Rules

The spatial library MAY depend upon lower-level SCR domains.

It MUST NOT require a specific provider merely to define its semantic types.

For example:

```text
spatial → H3
```

is architecturally undesirable as a foundational dependency.

Instead:

```text
spatial
   ↑
provider interface
   ↑
H3 provider
```

is preferred.

Likewise:

```text
spatial
   ↑
state provider interface
   ↑
OpenVDB provider
```

---

# 50. Recommended Provider Layer

A conforming architecture SHOULD separate:

```text
lib/spatial
       │
       ├── semantic interfaces
       │
       ↓
provider contracts
       │
       ├── H3 adapter
       ├── OpenVDB adapter
       ├── CGAL adapter
       └── future providers
```

Provider adapters SHOULD perform translation between provider-native representations and SCR semantic objects.

---

# 51. Canonical Spatial Boundary

The boundary between semantic and provider layers is:

```text
SCR Semantic Spatial Model
────────────────────────────────
Provider Capability Interface
────────────────────────────────
Provider Adapter
────────────────────────────────
Provider Native Representation
```

Nothing below the semantic boundary may silently redefine concepts above it.

---

# 52. Minimum Viable Implementation

The initial implementation SHOULD prioritise:

### Phase 1 — Semantic Types

Implement:

```text
SpatialSpace
ReferenceFrame
Coordinate
Location
Region
Partition
SpatialState
```

### Phase 2 — Relations

Implement:

```text
contains
located_in
associated_with
member_of
resident_in
represented_by
```

### Phase 3 — Transformations

Implement:

```text
coordinate_transform
state_transform
```

### Phase 4 — Partition Operations

Implement:

```text
partition
membership
parent
children
neighbours
refine
coarsen
```

### Phase 5 — State Operations

Implement:

```text
read
write
materialise
dematerialise
migrate
replicate
```

### Phase 6 — Providers

Integrate:

```text
H3
OpenVDB
```

through provider adapters rather than embedding them into the semantic model.

---

# 53. Initial Provider Mapping

The initial provider architecture SHOULD be:

```text
                    SCR Spatial
                         │
              ┌──────────┴──────────┐
              │                     │
       Partition Provider      State Provider
              │                     │
             H3                  OpenVDB
```

H3:

```text
partition
hierarchy
locality
neighbourhood
routing
```

OpenVDB:

```text
sparse state
volumetric representation
state hierarchy
materialisation
spatial access
```

This division is a recommended initial implementation, not a restriction on future providers.

---

# 54. Non-Goals

The spatial library MUST NOT become:

* an H3 wrapper;
* an OpenVDB wrapper;
* a GIS framework;
* a universal physics engine;
* a rendering engine;
* a mesh library;
* a database abstraction;
* a GPU memory manager.

It is the semantic spatial layer from which such integrations can be constructed.

---

# 55. Design Test

A useful architectural test is:

> If H3, OpenVDB, GPUs, and all current spatial providers disappeared tomorrow, could the SCR Spatial domain still be defined coherently?

The answer MUST be yes.

A second test is:

> If a new provider implemented the same semantic capabilities, could it be integrated without changing the spatial ontology?

The answer SHOULD be yes.

A third test is:

> Can a semantic spatial state exist without being physically materialised?

The answer MUST be yes.

A fourth test is:

> Can computation move without changing spatial state identity?

The answer MUST be yes.

---

# 56. Core Principle

The SCR Spatial Library exists to make spatial semantics executable without making implementation topology into ontology.

Its governing principle is:

> **Define spatial meaning once; allow representation, partitioning, materialisation, residency, and execution to vary independently.**

The canonical semantic relationship is:

```text
Semantic Space
      │
      ↓
Spatial Location / Region
      │
      ├───────────────┐
      ↓               ↓
  Partition          State
      │               │
      ↓               ↓
 Computational    Semantic
   Locality       Information
      │               │
      └───────┬───────┘
              ↓
       Provider Mapping
              │
              ↓
        Materialisation
              │
              ↓
       Physical Resources
```

The library therefore implements the principle:

$$
\boxed{
Semantic\ Spatial\ Structure
\neq
Provider\ Representation
}
$$

and, more specifically:

$$
\boxed{
Coordinate
\neq
Partition
\neq
State
\neq
Representation
\neq
Residency
\neq
Execution
}
$$

This separation is the foundation upon which SCR can support hierarchical spatial computation, sparse volumetric state, adaptive partitioning, distributed execution, simulation, rendering, and spatially aware AI without allowing any individual implementation technology to become the semantic definition of space.
