# SCR Spatial Semantics

**Document:** `114_SPATIAL_SEMANTICS.md`
**Status:** Draft
**Authority:** Semantic Computational Runtime (SCR)
**Domain:** `spatial`
**Normative Language:** MUST, MUST NOT, SHOULD, SHOULD NOT, MAY

---

## 1. Purpose

This specification defines the semantic model of **space** within the Semantic Computational Runtime (SCR).

SCR treats space as a semantic structure in which entities, fields, computational processes, resources, state, relationships, and transformations MAY be located, related, partitioned, moved, and transformed.

This specification establishes the semantic distinction between:

* spatial identity;
* spatial coordinates;
* reference frames;
* spatial geometry;
* spatial regions;
* spatial partitions;
* spatial locality;
* spatial neighbourhood;
* spatial containment;
* spatial resolution;
* spatial state;
* spatial transforms; and
* computational use of spatial structure.

This specification is deliberately independent of any particular spatial representation, indexing system, geometry library, rendering system, simulation engine, or computational provider.

In particular:

> **A spatial partition is not a coordinate system.**

A partitioning mechanism MAY use coordinates to determine membership, but partition identity, hierarchy, locality, and ownership are distinct semantic concepts.

---

# 2. Scope

This specification governs the semantics of spatial structure within SCR.

It applies to:

* computational spaces;
* semantic fields;
* spatial data;
* simulation domains;
* geometric objects;
* volumetric fields;
* surfaces;
* environments;
* agents located within space;
* spatially distributed computation;
* spatial partitioning;
* spatial scheduling;
* spatial routing;
* spatial resource locality;
* spatial state;
* spatial transformations; and
* providers implementing spatial capabilities.

It does not prescribe:

* a universal coordinate system;
* a particular dimensionality;
* a particular metric;
* a particular spatial indexing algorithm;
* a particular partitioning algorithm;
* a particular storage representation;
* a particular execution architecture;
* a particular geometry library;
* a particular rendering system.

---

# 3. Design Principle

SCR separates the semantic concept of space from its representation.

A spatial system MAY therefore contain distinct representations for:

```text
Geometry
    ↓
Coordinate / Reference Space

Partition
    ↓
Computational Locality

State
    ↓
Spatially manifested information

Execution
    ↓
Physical computational resources
```

These representations MAY correspond to one another without being identical.

The canonical semantic relationship is:

```text
Semantic Space
│
├── Reference Space
│     └── coordinates / transforms
│
├── Partition Space
│     └── computational locality
│
├── State Space
│     └── manifested spatial state
│
└── Execution Space
      └── computational resources
```

A provider MAY implement more than one of these capabilities, but the semantic distinctions MUST remain preserved.

---

# 4. Fundamental Principle: Space Is Not Representation

SCR MUST NOT define spatial meaning in terms of a particular representation.

For example:

```text
H3 cell ≠ spatial coordinate

OpenVDB voxel ≠ spatial location

GPU memory address ≠ spatial identity

mesh vertex ≠ spatial entity

array index ≠ physical position
```

Each MAY participate in representing spatial information, but none is intrinsically equivalent to the semantic concept of space.

A provider implementation MUST NOT cause its internal representation to become an implicit semantic requirement of SCR.

---

# 5. Spatial Space

A **Spatial Space** is a semantic domain in which spatial positions, regions, relationships, or state MAY be defined.

A Spatial Space MUST have sufficient information to establish:

1. its identity;
2. its dimensionality or spatial structure;
3. its reference semantics;
4. its applicable spatial relationships;
5. its transformation rules, where transformations are supported.

A Spatial Space MAY be:

* one-dimensional;
* two-dimensional;
* three-dimensional;
* four-dimensional;
* higher-dimensional;
* discrete;
* continuous;
* hybrid;
* finite;
* infinite;
* bounded;
* unbounded;
* static;
* dynamic.

Dimensionality MUST NOT be inferred solely from the implementation provider.

---

# 6. Spatial Reference Frame

A **Spatial Reference Frame** defines the interpretation of coordinates or spatial measurements within a Spatial Space.

A reference frame establishes the meaning of:

* origin;
* axes or basis;
* orientation;
* units;
* scale;
* dimensionality;
* coordinate interpretation;
* applicable transformations.

Two coordinates with identical numerical values in different reference frames MUST NOT be assumed to identify the same spatial location.

A reference frame MAY be:

* local;
* global;
* relative;
* hierarchical;
* object-relative;
* machine-relative;
* world-relative;
* temporal;
* dynamically transformed.

---

# 7. Spatial Coordinate

A **Spatial Coordinate** is a representation of a position relative to a Spatial Reference Frame.

A coordinate MAY be:

* integer;
* floating-point;
* fixed-point;
* symbolic;
* parametric;
* discrete;
* continuous;
* multidimensional.

A coordinate is a representation of location, not necessarily an identity.

Two distinct entities MAY occupy the same coordinate.

One entity MAY possess multiple coordinates in different reference frames.

Therefore:

```text
Coordinate ≠ Identity
```

and:

```text
Coordinate ≠ Partition
```

---

# 8. Spatial Location

A **Spatial Location** is the semantic identification of where an entity, state, event, or region exists within a Spatial Space.

A Spatial Location MAY be represented by:

* a coordinate;
* a region;
* a partition;
* a geometric construct;
* a symbolic location;
* a hierarchical spatial address;
* a combination of the above.

A Spatial Location MUST NOT require a specific representation.

A location MAY be exact or approximate.

A location MAY possess an associated uncertainty or tolerance.

---

# 9. Spatial Region

A **Spatial Region** is a semantic subset of a Spatial Space.

A region MAY be:

* point-like;
* linear;
* planar;
* volumetric;
* hyperspatial;
* disconnected;
* sparse;
* continuous;
* discrete;
* bounded;
* unbounded.

Regions MAY overlap.

Regions MAY contain other regions.

Regions MAY be represented independently of coordinates.

---

# 10. Spatial Boundary

A **Spatial Boundary** defines the semantic extent separating a region from its complement or from another region.

A boundary MAY be:

* explicit;
* implicit;
* geometric;
* topological;
* computational;
* approximate.

A boundary MAY have zero thickness or non-zero thickness.

Boundary semantics MUST NOT be inferred from storage representation.

---

# 11. Spatial Containment

Spatial containment expresses the relationship:

$$
A \supseteq B
$$

where spatial object or region `A` contains spatial object or region `B`.

Containment MAY be:

* strict;
* inclusive;
* hierarchical;
* computational;
* geometric;
* semantic.

Containment MUST be distinguishable from identity.

For example:

```text
World contains Region
Region contains Partition
Partition contains State
State contains Entity
```

does not imply:

```text
World = Region = Partition = State = Entity
```

---

# 12. Spatial Partition

A **Spatial Partition** is a semantic subdivision of a Spatial Space into computationally or logically distinguishable domains.

A partition exists to establish locality, ownership, routing, scheduling, organisation, or other computationally meaningful subdivision.

A partition MAY correspond to a geometric region, but it does not have to be a coordinate representation.

Therefore:

> **A Spatial Partition identifies a domain of locality; it does not define the coordinate system of that domain.**

A partition MAY have:

* an identity;
* a parent;
* zero or more children;
* neighbours;
* boundaries;
* spatial extent;
* computational ownership;
* resource affinity;
* state;
* workload;
* capacity;
* locality relationships.

A partition MAY exist without being fully materialised as a geometric object.

---

# 13. Partition Identity

Every persistent or addressable Spatial Partition MUST have a stable semantic identity.

Partition identity MUST be independent of:

* physical machine location;
* memory address;
* storage address;
* provider-specific object address.

A partition MAY additionally possess provider-specific identifiers.

For example:

```text
Semantic Partition ID
        │
        ├── H3 index
        ├── provider-local ID
        └── execution owner
```

The provider identifier MUST NOT replace the semantic partition identity where the partition is exposed through SCR semantics.

---

# 14. Partition Hierarchy

Spatial Partitions MAY form a hierarchy.

A hierarchy MAY express:

```text
Space
  ↓
Partition
  ↓
Subpartition
  ↓
Subpartition
```

A child partition MUST have a well-defined relationship to its parent.

A partition hierarchy MAY support:

* refinement;
* coarsening;
* subdivision;
* aggregation;
* ownership inheritance;
* resource inheritance;
* locality inheritance.

A hierarchy MUST NOT be assumed to imply a particular geometric subdivision algorithm.

---

# 15. Partition Refinement

**Partition Refinement** creates one or more more-specific partitions from an existing partition.

Conceptually:

$$
P \rightarrow \{P_1,P_2,\ldots,P_n\}
$$

Refinement MAY occur because of:

* increased computational demand;
* increased spatial resolution;
* increased state density;
* load balancing;
* resource allocation;
* routing requirements;
* simulation requirements;
* data locality;
* semantic requirements.

Refinement MUST preserve the semantic relationship between the parent and resulting child partitions.

---

# 16. Partition Coarsening

**Partition Coarsening** combines or collapses partitions into a less granular representation.

Conceptually:

$$
\{P_1,P_2,\ldots,P_n\} \rightarrow P
$$

Coarsening MAY occur because:

* computational demand has decreased;
* state has become inactive;
* resources are being consolidated;
* spatial resolution is no longer required;
* data is being compressed;
* locality requirements have changed.

Coarsening MUST NOT silently destroy semantic state.

Any information loss MUST be explicitly defined by the applicable state or transformation semantics.

---

# 17. Spatial Locality

**Spatial Locality** expresses the degree to which two spatial objects, regions, partitions, or states are related by spatial proximity or topology.

Locality is a semantic relationship rather than necessarily a numerical distance.

Locality MAY be based upon:

* distance;
* adjacency;
* containment;
* overlap;
* shared boundary;
* topology;
* communication cost;
* data movement cost;
* execution cost;
* provider-defined locality metrics.

A runtime MAY use locality to determine:

* scheduling;
* resource placement;
* routing;
* caching;
* replication;
* communication paths;
* data residency;
* workload migration.

---

# 18. Spatial Neighbourhood

A **Spatial Neighbourhood** is the set or relation of spatial objects considered locally related to a specified object.

A neighbourhood MAY be defined by:

* adjacency;
* radius;
* topology;
* hierarchy;
* distance;
* application semantics;
* resource locality.

Neighbourhood semantics MUST be independent of any specific indexing implementation.

A provider MAY implement neighbourhood queries efficiently using a spatial index.

---

# 19. Spatial Distance

A Spatial Space MAY define one or more distance or separation functions.

A distance function:

$$
d(a,b)
$$

MAY describe:

* geometric distance;
* topological separation;
* computational cost;
* communication cost;
* semantic separation.

Geometric distance and computational distance MUST NOT be assumed to be equivalent.

For example, two spatial partitions may be geometrically adjacent while being physically expensive to communicate between.

Conversely, spatially distant objects MAY have low communication cost if they share an execution resource.

---

# 20. Spatial Resolution

**Spatial Resolution** defines the granularity at which spatial structure or state is represented.

Resolution MAY apply independently to:

* coordinates;
* geometry;
* partitions;
* state;
* rendering;
* simulation;
* computation.

A partition MAY have one resolution while its state has another.

For example:

```text
Partition resolution
        ↓
coarse locality

State resolution
        ↓
fine volumetric representation
```

Therefore:

> **Partition resolution and state resolution are independent semantic properties.**

---

# 21. Spatial State

**Spatial State** is information whose semantic interpretation is associated with a Spatial Space, Spatial Location, Spatial Region, or Spatial Partition.

Spatial State MAY include:

* scalar fields;
* vector fields;
* tensors;
* geometry;
* occupancy;
* density;
* temperature;
* velocity;
* agents;
* resources;
* environmental state;
* simulation state;
* computational state.

Spatial State MAY be:

* sparse;
* dense;
* discrete;
* continuous;
* volumetric;
* surface-based;
* point-based;
* symbolic.

The representation of Spatial State MUST remain separable from its semantic meaning.

---

# 22. Spatial State Materialisation

A Spatial State MAY exist semantically without being fully materialised in a particular computational representation.

**Materialisation** is the creation of an executable or directly accessible representation of semantic spatial state.

Conceptually:

```text
Semantic Spatial State
        ↓
Materialisation
        ↓
Provider Representation
```

A runtime MAY materialise state because:

* computation requires it;
* an observer requires it;
* a renderer requires it;
* a neighbouring process requires it;
* a resource becomes available.

---

# 23. Spatial State Dematerialisation

A runtime MAY remove or collapse a materialised representation while retaining its semantic state.

Conceptually:

```text
Materialised State
        ↓
Dematerialisation
        ↓
Semantic State
```

Dematerialisation MUST NOT imply semantic deletion unless deletion is explicitly requested or defined by the applicable state semantics.

This distinction permits sparse, demand-driven computational spaces.

---

# 24. Spatial State Residency

A materialised Spatial State MAY possess **residency** within an Execution Space.

Residency describes where the computational representation currently exists.

Examples include:

```text
CPU memory
GPU memory
node-local memory
distributed memory
persistent storage
remote execution domain
```

Residency MUST NOT alter semantic identity.

Moving state between execution resources MUST therefore be representable as a change in manifestation or residency rather than necessarily as a change in semantic identity.

---

# 25. Spatial and Computational Locality

Spatial locality MAY be used to establish computational locality.

A runtime MAY map:

$$
SpatialPartition \rightarrow ExecutionSpace
$$

This mapping MAY determine:

* processor affinity;
* GPU affinity;
* memory affinity;
* data residency;
* message routing;
* scheduling;
* caching;
* replication;
* workload placement.

The mapping is a runtime policy, not necessarily a property of the underlying geometry.

---

# 26. Spatial Ownership

A Spatial Partition MAY possess an owner.

Ownership MAY identify:

* an execution process;
* a computational resource;
* a Semantic Machine;
* a node;
* a container;
* a semantic agent;
* another partition.

Ownership is distinct from containment.

For example:

```text
Partition P
    geometric parent = Region R
    execution owner = Machine M
```

The machine does not thereby geometrically contain the partition.

---

# 27. Spatial Migration

A Spatial Partition or its materialised state MAY migrate between Execution Spaces.

Migration MAY occur because of:

* load balancing;
* resource failure;
* locality optimisation;
* capacity changes;
* scheduling;
* topology changes.

Migration MUST preserve semantic identity unless the applicable operation explicitly defines identity transformation.

Conceptually:

$$
(P,R_1) \rightarrow (P,R_2)
$$

where:

* `P` remains the same semantic partition;
* `R₁` is the previous execution resource;
* `R₂` is the new execution resource.

---

# 28. Spatial Routing

Spatial information MAY be used as a routing key.

A routing function MAY take the form:

$$
R(x) \rightarrow E
$$

where:

* `x` is a spatial location, region, partition, or spatially associated entity;
* `E` is an execution or communication endpoint.

Routing MAY use:

* partition identity;
* neighbourhood;
* ownership;
* locality;
* load;
* data residency;
* resource availability.

Spatial routing MUST NOT require that the routing index itself be the canonical coordinate representation.

---

# 29. Spatial Transform

A **Spatial Transform** defines a mapping between Spatial Reference Frames.

Conceptually:

$$
T : S_A \rightarrow S_B
$$

A transform MAY represent:

* translation;
* rotation;
* scale;
* affine transformation;
* nonlinear transformation;
* projection;
* hierarchical transformation;
* temporal transformation.

Transforms MAY be composed where mathematically valid.

A transform MUST explicitly identify the source and destination reference frames.

---

# 30. Spatial Identity Versus Spatial Position

SCR MUST distinguish:

```text
Entity Identity
```

from:

```text
Spatial Position
```

An entity MAY move while retaining its identity.

Therefore:

$$
Identity(E_t) = Identity(E_{t+1})
$$

while:

$$
Location(E_t) \neq Location(E_{t+1})
$$

Similarly, a semantic entity MAY retain its identity while:

* changing partition;
* changing execution resource;
* changing representation;
* changing coordinate frame;
* changing state residency.

---

# 31. Spatial Representation Independence

A semantic spatial object MUST be representable by one or more providers without changing its semantic identity.

For example, the same Spatial State MAY be represented using:

```text
dense tensor
sparse tensor
voxel grid
OpenVDB
mesh
point cloud
GPU structure
procedural function
compressed representation
```

The provider is a realisation of semantic capability.

Provider replacement MUST NOT require semantic reinterpretation of the object merely because its representation changed.

---

# 32. Partition Provider Independence

SCR MUST NOT require a particular spatial partitioning system.

A Spatial Partition provider MAY implement partitioning using:

* hierarchical grids;
* hexagonal grids;
* octrees;
* quadtrees;
* kd-trees;
* geospatial indexing;
* graph partitioning;
* hypergraph partitioning;
* adaptive meshes;
* application-specific structures.

The provider MUST expose the semantic partition capabilities defined by SCR.

---

# 33. State Provider Independence

SCR MUST NOT require a particular Spatial State representation.

A Spatial State provider MAY implement:

* sparse voxel fields;
* dense arrays;
* tensors;
* meshes;
* implicit fields;
* point sets;
* procedural fields;
* GPU-native structures;
* external simulation structures.

Provider-specific capabilities MAY extend the semantic model but MUST NOT redefine its core semantics.

---

# 34. Spatial Partition and State Are Orthogonal

A Spatial Partition and Spatial State MUST remain semantically distinguishable.

A partition MAY exist without materialised state.

A state MAY span multiple partitions.

A partition MAY contain multiple independent state fields.

A single state field MAY be partitioned differently for different computational purposes.

Therefore:

```text
Partition
    ≠
State
```

and:

```text
Partitioning(State)
```

is an operation or relationship, not an identity equivalence.

---

# 35. Spatial Partition and Coordinate System Are Orthogonal

A partition provider MAY derive partition membership from coordinates.

However:

```text
coordinate → partition
```

does not imply:

```text
partition → coordinate system
```

A Spatial Space MAY therefore use:

```text
Canonical coordinate system A
+
Partition provider B
+
State provider C
+
Execution topology D
```

without semantic conflict.

This separation is normative.

---

# 36. Hierarchical Spatial Computation

SCR MAY represent computation hierarchically according to spatial locality.

A computational hierarchy MAY be:

```text
Global Space
    ↓
Spatial Partition
    ↓
Subpartition
    ↓
Spatial State
    ↓
Computational Field
    ↓
Operation
```

A runtime MAY increase or decrease computational granularity dynamically.

This permits:

* adaptive simulation;
* spatial load balancing;
* demand-driven computation;
* resource-aware scheduling;
* locality-aware routing;
* distributed spatial execution.

---

# 37. Spatial Workload

A **Spatial Workload** is computational demand associated with a spatial region, partition, state, or locality.

Workload MAY be measured in terms of:

* operations;
* execution time;
* memory;
* data volume;
* communication volume;
* energy;
* GPU occupancy;
* CPU utilisation;
* queue depth;
* state-change rate.

Workload MAY be used to trigger partition refinement or migration.

Conceptually:

$$
Load(P) > Threshold
\Rightarrow
Refine(P)
$$

and:

$$
Load(P) \ll Threshold
\Rightarrow
Coarsen(P)
$$

These are runtime policies rather than mandatory behaviours.

---

# 38. Spatial Locality as a Resource Primitive

Spatial locality MAY be used as a first-class computational resource constraint.

A scheduler SHOULD prefer execution placement that reduces unnecessary:

* state movement;
* communication;
* synchronisation;
* cache invalidation;
* memory transfer;
* network transfer.

This MAY produce the optimisation chain:

```text
Spatial Locality
      ↓
Partition Locality
      ↓
Data Locality
      ↓
Execution Locality
      ↓
Communication Locality
      ↓
Reduced Movement
```

Spatial proximity alone MUST NOT guarantee physical resource proximity.

The scheduler MUST distinguish semantic spatial locality from physical execution locality.

---

# 39. Spatial Neighbour Communication

Neighbouring partitions MAY exchange state or computation directly.

A runtime MAY optimise communication according to:

```text
Partition A
    ↕
Neighbour relationship
    ↕
Partition B
```

This MAY be realised through:

* local memory;
* shared memory;
* inter-process messaging;
* node-local transport;
* network transport;
* GPU peer-to-peer transport;
* distributed messaging.

The transport mechanism MUST remain separate from the semantic neighbour relationship.

---

# 40. Spatial Events

Spatial events MAY be generated when spatial relationships change.

Examples include:

```text
EntityEnteredRegion
EntityExitedRegion
PartitionRefined
PartitionCoarsened
PartitionMigrated
StateMaterialised
StateDematerialised
NeighbourhoodChanged
BoundaryChanged
SpatialTransformChanged
```

Events SHOULD carry semantic spatial identifiers rather than relying exclusively on provider-specific addresses.

---

# 41. Temporal Spatial State

Spatial State MAY vary with time.

A temporal spatial state can be represented conceptually as:

$$
S(x,t)
$$

where:

* `x` is spatial location;
* `t` is temporal position.

The temporal dimension MUST remain conceptually distinct from spatial dimensionality unless the applicable semantic model explicitly defines a spacetime representation.

A Spatial State MAY therefore contain:

```text
Spatial dimension
+
Temporal dimension
```

without requiring a particular 4D implementation.

---

# 42. Dynamic Spatial Topology

Spatial relationships MAY change over time.

Therefore:

* partitions MAY change;
* ownership MAY change;
* neighbourhoods MAY change;
* boundaries MAY change;
* reference frames MAY change;
* spatial state MAY change.

A runtime MUST NOT assume that spatial topology is immutable unless the applicable Spatial Space declares it immutable.

---

# 43. Spatial Consistency

A Spatial System MUST maintain semantic consistency between:

```text
Identity
Reference Frame
Location
Partition
State
Residency
Ownership
Execution
```

where these relationships are exposed.

For example, if state is declared resident in a partition, the runtime MUST be able to establish the semantic relationship between that state and the partition.

Provider-specific caching or replication MAY create multiple physical representations, but they MUST NOT create ambiguous semantic ownership.

---

# 44. Replication

Spatial State MAY be replicated across multiple Execution Spaces.

Replication MUST NOT imply multiple semantic identities.

Conceptually:

```text
Semantic State S
       │
       ├── representation A → GPU 1
       ├── representation B → GPU 2
       └── representation C → storage
```

Consistency requirements between replicas MUST be explicitly defined by the applicable state semantics.

---

# 45. Canonical Spatial Model

The canonical SCR spatial relationship is:

```text
                         Spatial Space
                              │
              ┌───────────────┼────────────────┐
              │               │                │
              ▼               ▼                ▼
        Reference Space   Partition Space   State Space
              │               │                │
       coordinates        locality /        spatial state
       transforms         ownership
              │               │                │
              └───────────────┼────────────────┘
                              │
                              ▼
                       Execution Space
                              │
                       resource / process
```

These are related semantic structures.

They MUST NOT be collapsed into one representation.

---

# 46. Provider Mapping

A concrete implementation MAY map the semantic model to external providers.

For example:

```text
SCR Semantic Capability
        │
        ├── Spatial Reference Provider
        │
        ├── Spatial Partition Provider
        │
        ├── Spatial State Provider
        │
        └── Spatial Execution Provider
```

A provider MAY implement:

```text
Spatial Partition
        ↓
H3

Spatial State
        ↓
OpenVDB
```

Such a mapping is valid because:

```text
H3 = partition implementation
OpenVDB = state implementation
```

Neither becomes the definition of SCR space.

---

# 47. H3 Provider Boundary

An H3 provider MAY implement the Spatial Partition capability.

Its responsibilities MAY include:

* partition identity;
* hierarchical partition relationships;
* parent/child relationships;
* neighbourhood;
* locality;
* partition lookup;
* partition refinement;
* partition coarsening;
* spatial-to-partition mapping;
* partition-to-spatial-region mapping.

The H3 provider MUST NOT define H3 cells as SCR coordinates.

H3 identifiers are partition identifiers when used in this role.

---

# 48. OpenVDB Provider Boundary

An OpenVDB provider MAY implement Spatial State and volumetric spatial representation.

Its responsibilities MAY include:

* sparse volumetric state;
* voxel indexing;
* state sampling;
* sparse allocation;
* materialisation;
* state residency;
* volumetric transforms;
* state access.

OpenVDB coordinates MUST NOT automatically become SCR semantic coordinates.

The provider MUST expose the appropriate transformation between its index space and the applicable SCR Spatial Reference Frame.

---

# 49. Composition of Partition and State Providers

A Spatial Partition provider and Spatial State provider MAY be composed.

For example:

```text
SCR Spatial Space
       │
       ├── H3 Partition
       │      │
       │      └── computational locality
       │
       └── OpenVDB State
              │
              └── sparse volumetric manifestation
```

The semantic relationship is:

$$
SpatialLocation
\rightarrow
SpatialPartition
\rightarrow
SpatialState
$$

where applicable.

This does not imply:

$$
H3Coordinate = VDBCoordinate
$$

Instead:

$$
H3
\leftrightarrow
SCR\ Spatial\ Reference
\leftrightarrow
OpenVDB
$$

through explicitly defined transformations and mappings.

---

# 50. Spatial Addressing

SCR MAY define a compound spatial address containing multiple semantic components.

Conceptually:

```text
SpatialAddress
{
    space_id
    reference_frame
    location
    partition
    state_reference
}
```

A provider MAY add implementation-specific fields.

A Spatial Address MUST NOT be interpreted as a universal coordinate encoding.

Its purpose is to provide sufficient information to resolve semantic spatial state.

---

# 51. Spatial Resolution and Materialisation

A runtime MAY materialise spatial state only to the resolution required by current computation.

For example:

```text
Coarse spatial knowledge
        ↓
Partition identified
        ↓
Computation requested
        ↓
Fine state materialised
        ↓
Computation performed
        ↓
State retained or dematerialised
```

This enables demand-driven spatial computation.

The existence of a partition MUST NOT imply that all possible state within the partition has been materialised.

---

# 52. Spatial Resource Allocation

A runtime MAY allocate resources according to spatial partitions.

For example:

```text
Partition A → CPU 0
Partition B → GPU 0
Partition C → GPU 1
Partition D → Node 4
```

The allocation MAY change dynamically.

Resource allocation MUST remain distinct from spatial identity.

A change in resource allocation MUST NOT inherently constitute a change in spatial identity.

---

# 53. Spatial Scheduling

A scheduler MAY use:

$$
f(
partition,
locality,
workload,
state\ residency,
resource\ capacity,
communication\ cost
)
$$

to determine execution placement.

This permits spatially aware scheduling without requiring the semantic spatial model to prescribe a scheduler.

---

# 54. Spatial Routing and Messaging

Spatial partitions MAY be used as routing domains for SCR messaging systems.

A message MAY identify:

```text
semantic destination
spatial location
spatial partition
execution locality
state residency
```

A messaging provider MAY resolve these attributes into a physical transport route.

The semantic destination MUST remain distinguishable from the physical transport endpoint.

---

# 55. Invariants

The following invariants are normative.

### S-001 — Representation Independence

Spatial semantics MUST NOT depend on a specific spatial representation.

### S-002 — Coordinate Independence

A Spatial Partition MUST NOT be defined as a coordinate system.

### S-003 — Partition Independence

SCR MUST NOT require a particular partitioning algorithm.

### S-004 — State Independence

SCR MUST NOT require a particular spatial state representation.

### S-005 — Identity Preservation

Changing spatial representation, partition ownership, or execution residency MUST NOT inherently change semantic identity.

### S-006 — Explicit Transformation

Conversions between reference frames MUST be represented by explicit or semantically defined transformations.

### S-007 — Partition/State Separation

Spatial Partition and Spatial State MUST remain distinct semantic concepts.

### S-008 — Geometry/Partition Separation

Geometric representation and computational partitioning MUST remain independently replaceable.

### S-009 — Locality Independence

Spatial locality MUST NOT be assumed to imply physical execution locality.

### S-010 — Provider Transparency

A provider MUST implement semantic capabilities without redefining their semantic meaning.

### S-011 — Materialisation Transparency

Materialisation and dematerialisation MUST NOT inherently constitute semantic creation or deletion.

### S-012 — Migration Preservation

Moving a semantic spatial object between execution resources MUST preserve identity unless an explicit semantic transformation occurs.

### S-013 — Hierarchical Integrity

Partition refinement and coarsening MUST preserve valid parent/child semantics.

### S-014 — State Integrity

State migration, replication, materialisation, and dematerialisation MUST preserve the declared semantic state invariants.

### S-015 — Spatial Address Explicitness

A compound spatial address MUST distinguish coordinate, partition, state, and execution information where those dimensions are present.

---

# 56. Non-Goals

This specification does not define:

* GIS semantics;
* cartographic projections;
* Earth-specific geometry;
* H3 semantics;
* OpenVDB semantics;
* rendering semantics;
* physics;
* collision detection;
* fluid simulation;
* mesh topology;
* GPU memory architecture;
* network transport;
* scheduling algorithms;
* load-balancing algorithms.

Those MAY be defined by domain specifications or providers.

---

# 57. Relationship to Other SCR Domains

Spatial Semantics provides foundational concepts for:

```text
geometry
topology
field
graph
simulation
dynamics
physics
agent
render
stream
system
```

Other domains MAY specialise Spatial Semantics.

For example:

```text
Geometry
    → geometric shape and measurement

Topology
    → spatial connectivity and adjacency

Field
    → values distributed over space

Simulation
    → spatial state evolution

Dynamics
    → spatial state transition

Agent
    → entities occupying or traversing space

Render
    → spatial state manifestation for observation
```

These domains MUST NOT redefine the foundational distinctions established here.

---

# 58. Reference Conceptual Model

The complete conceptual relationship is:

```text
                         SEMANTIC SPACE
                              │
              ┌───────────────┼────────────────┐
              │               │                │
              ▼               ▼                ▼
       REFERENCE SPACE   PARTITION SPACE   STATE SPACE
              │               │                │
              │               │                │
       coordinates        locality          state
       transforms         ownership         fields
       geometry           routing           materialisation
              │               │                │
              └───────────────┼────────────────┘
                              │
                              ▼
                       EXECUTION SPACE
                              │
                       resources / machines
                              │
                 ┌────────────┼────────────┐
                 │            │            │
                CPU          GPU         Node
                 │            │            │
                 └────────────┼────────────┘
                              │
                         Messaging /
                          computation
```

The semantic flow is therefore:

$$
\boxed{
Space
\rightarrow
Reference
\rightarrow
Partition
\rightarrow
State
\rightarrow
Execution
}
$$

but these are **related dimensions, not successive representations of the same object**.

---

# 59. Architectural Principle

The central architectural principle of SCR Spatial Semantics is:

> **Space describes where semantic structure exists. Reference frames describe how location is represented. Partitions describe computational locality. State describes what is manifested there. Execution spaces describe where computation is physically realised.**

These dimensions MAY be composed, transformed, replicated, migrated, and optimised independently.

A high-performance implementation SHOULD exploit these separations rather than collapse them.

---

# 60. Summary

SCR defines spatial computation as a composition of independent but related semantic structures:

```text
                 SPACE
                   │
        ┌──────────┼──────────┐
        │          │          │
   REFERENCE   PARTITION     STATE
        │          │          │
   coordinates   locality   manifestation
   transforms    routing    volumetric /
                 ownership  field / data
        │          │          │
        └──────────┼──────────┘
                   │
               EXECUTION
                   │
             physical resources
```

The fundamental distinction is:

$$
\boxed{
\text{Coordinate} \neq
\text{Partition} \neq
\text{State} \neq
\text{Execution Resource}
}
$$

A spatial computation MAY nevertheless establish mappings between them:

$$
Location
\rightarrow
Partition
\rightarrow
State
\rightarrow
Execution
$$

This permits SCR to use specialised providers such as hierarchical spatial indexes, sparse volumetric representations, computational graphs, GPU memory systems, and distributed messaging fabrics without allowing any one implementation to become the ontology of space itself.

**Spatial semantics are therefore defined by relationships, not by representation.**
