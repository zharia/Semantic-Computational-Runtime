# SCR Spatial Partitioning Model

**Document:** `115_SPATIAL_PARTITIONING_MODEL.md`
**Status:** Draft
**Authority:** Semantic Computational Runtime (SCR)
**Domain:** `spatial`
**Normative Language:** MUST, MUST NOT, SHOULD, SHOULD NOT, MAY

---

## 1. Purpose

This specification defines the computational semantics of **Spatial Partitioning** within the Semantic Computational Runtime (SCR).

Spatial Partitioning divides a Spatial Space into semantically addressable computational domains.

The purpose of partitioning is not merely geometric subdivision.

A Spatial Partition MAY establish:

* computational locality;
* workload ownership;
* data residency;
* routing locality;
* scheduling locality;
* resource affinity;
* communication locality;
* caching locality;
* replication domains;
* failure domains;
* adaptive computational granularity.

The central principle is:

> **A Spatial Partition is a computational locality, not a coordinate system.**

A partition MAY be derived from spatial coordinates, geometry, topology, workload, or another spatial property, but its semantic role is to establish a domain within which computation, state, communication, and resources can be organised.

---

# 2. Relationship to Spatial Semantics

This specification extends `114_SPATIAL_SEMANTICS.md`.

The foundational distinction is:

```text
Reference Space
    ↓
coordinates / transforms

Partition Space
    ↓
locality / ownership / routing

State Space
    ↓
spatially manifested information

Execution Space
    ↓
physical computational resources
```

These dimensions are related but MUST remain independently representable.

In particular:

```text
Coordinate ≠ Partition
Partition ≠ State
Partition ≠ Resource
Partition ≠ Execution Process
```

A partition MAY be associated with all of these.

---

# 3. Definition

A **Spatial Partition** is a semantically identifiable subset or locality within a Spatial Space that is used to organise spatial computation, state, communication, or resources.

A partition MUST possess a semantic identity.

A partition MAY possess:

* spatial extent;
* parent;
* children;
* neighbours;
* owner;
* workload;
* capacity;
* state;
* resource affinity;
* execution residency;
* routing identity;
* refinement state.

A partition does not necessarily require an explicitly materialised geometric boundary.

---

# 4. Partitioning Function

A partitioning system defines a mapping from a spatial domain to one or more partitions.

Conceptually:

$$
P : X \rightarrow \Pi
$$

where:

* \(X\) is a Spatial Space;
* \(\Pi\) is the set of Spatial Partitions.

For a location \(x\):

$$
P(x) = p
$$

means that `x` is associated with partition `p` under the applicable partitioning policy.

A partitioning function MAY be:

* deterministic;
* hierarchical;
* adaptive;
* dynamic;
* workload-aware;
* topology-aware;
* resource-aware.

SCR does not require one universal partitioning function.

---

# 5. Partitioning Is Not Coordinates

A partition MAY be selected using coordinates:

$$
coordinate \rightarrow partition
$$

but this MUST NOT imply:

$$
partition = coordinate
$$

A partition identifier MAY be completely independent of coordinate representation.

For example:

```text
Coordinate
    (x,y,z)
        │
        ▼
Partition Function
        │
        ▼
Partition P
        │
        ├── owner
        ├── workload
        └── state
```

The partition identifier therefore represents **computational locality**, not a position.

---

# 6. Partition Identity

Every persistent or addressable partition MUST have a stable identity.

The identity MUST remain distinct from:

* coordinates;
* physical addresses;
* memory addresses;
* network addresses;
* provider-local object identifiers;
* execution process identifiers.

A provider MAY use an implementation-specific identifier internally.

Where exposed through SCR, the provider identifier MUST be associated with the semantic partition identity.

---

# 7. Partition Address

A partition MAY be addressable independently of coordinates.

A partition address MAY contain:

```text
Partition Address
{
    space_id
    partition_id
    hierarchy
    provider_reference
}
```

Provider-specific addressing MAY be included.

A partition address MUST NOT require exposure of the provider's internal representation.

---

# 8. Partition Membership

An entity, state object, workload, or computational field MAY be associated with one or more partitions.

Membership MAY be:

* exclusive;
* overlapping;
* hierarchical;
* replicated;
* transient;
* weighted;
* probabilistic;
* application-defined.

Where exclusive partitioning is declared, a spatial location MUST resolve to no more than one partition at the applicable partition resolution.

Where overlapping partitioning is declared, the runtime MUST preserve the distinction between primary and secondary membership where such distinction is semantically relevant.

---

# 9. Partition Extent

A partition MAY possess an associated spatial extent.

The extent MAY be represented as:

* a region;
* a bounding volume;
* a set of locations;
* a topology;
* an implicit function;
* a provider-defined domain.

The existence of a partition MUST NOT require that its extent be represented explicitly.

A computational partition MAY be defined by a semantic rule rather than a stored geometric object.

---

# 10. Partition Hierarchy

Partitions MAY form a hierarchy.

Conceptually:

```text
Spatial Space
    │
    ├── Partition A
    │     ├── A1
    │     ├── A2
    │     └── A3
    │
    └── Partition B
          ├── B1
          └── B2
```

A hierarchy establishes parent/child relationships.

A child partition MUST represent a refinement or subdivision of the parent's applicable domain.

A parent partition MAY retain semantic existence after refinement.

---

# 11. Parent Relationship

A partition MAY have a parent:

$$
parent(P_c) = P_p
$$

The parent relationship MUST be explicit where hierarchy is exposed.

A parent partition MAY provide inherited:

* configuration;
* ownership;
* locality;
* resource policy;
* routing policy;
* state policy.

Inheritance MUST NOT imply identity equivalence.

---

# 12. Child Relationship

A partition MAY have zero or more children:

$$
children(P) = \{P_1,\ldots,P_n\}
$$

Children MAY be:

* materialised;
* virtual;
* lazy;
* dynamic.

A partition MAY have no children because:

* it is a leaf;
* it has not been refined;
* refinement is unsupported;
* children are not currently materialised.

---

# 13. Partition Refinement

**Partition Refinement** increases the granularity of a partition.

Conceptually:

$$
P \rightarrow \{P_1,P_2,\ldots,P_n\}
$$

Refinement MAY be triggered by:

* workload;
* state density;
* resolution requirements;
* resource constraints;
* communication patterns;
* simulation requirements;
* scheduling policy;
* data locality.

Refinement SHOULD preserve semantic continuity between the parent and children.

---

# 14. Refinement Does Not Imply State Duplication

Refining a partition MUST NOT automatically imply that all state is copied into every child.

Instead, the runtime MAY:

```text
Parent State
    │
    ├── subdivide
    │
    ├── redistribute
    │
    ├── lazily materialise
    │
    └── retain at parent level
```

The applicable state model determines the correct behaviour.

---

# 15. Partition Coarsening

**Partition Coarsening** decreases partition granularity.

Conceptually:

$$
\{P_1,\ldots,P_n\} \rightarrow P
$$

Coarsening MAY occur when:

* workload decreases;
* state becomes sparse;
* resources are consolidated;
* communication patterns change;
* fine resolution is no longer required.

Coarsening MUST NOT silently discard semantic state.

State aggregation MUST follow the applicable state semantics.

---

# 16. Partition Lifecycle

A partition MAY pass through the following lifecycle:

```text
Undefined
   ↓
Declared
   ↓
Available
   ↓
Materialised
   ↓
Active
   ↓
Inactive
   ↓
Dematerialised
   ↓
Retired
```

Not every implementation MUST expose all states.

Semantic existence and physical materialisation MUST remain distinguishable.

A partition MAY remain semantically defined while having no active computational representation.

---

# 17. Partition Activation

A partition MAY be activated when computation or state requires it.

Activation MAY involve:

* resource allocation;
* state materialisation;
* process creation;
* memory allocation;
* routing registration;
* neighbour registration.

Activation MUST NOT inherently change partition identity.

---

# 18. Partition Deactivation

A partition MAY be deactivated when no active computation requires it.

Deactivation MAY release:

* CPU resources;
* GPU resources;
* memory;
* caches;
* message consumers;
* materialised state.

Deactivation MUST NOT inherently constitute partition deletion.

---

# 19. Partition Retirement

A partition MAY be retired.

Retirement means the partition is no longer available for active computation under its current semantic lifecycle.

Retirement MUST preserve sufficient historical identity where required by:

* provenance;
* references;
* audit;
* state history;
* reproducibility.

---

# 20. Spatial Locality

Spatial locality defines relationships between partitions based on their spatial or topological relationship.

A locality relation MAY include:

```text
adjacent
near
contains
contained-by
overlaps
intersects
same-region
same-parent
same-resource-domain
```

A runtime MAY use locality to optimise execution.

---

# 21. Neighbourhood

Each partition MAY expose a neighbourhood:

$$
N(P) = \{P_1,P_2,\ldots,P_n\}
$$

Neighbourhood MAY be defined by:

* geometric adjacency;
* distance;
* topology;
* hierarchy;
* communication cost;
* application semantics.

Neighbourhood MUST be distinguishable from arbitrary graph connectivity.

A system MAY create a computational graph from neighbourhood relationships, but the resulting graph is a derived representation.

---

# 22. Locality Graph

A partitioning system MAY expose a graph:

$$
G = (V,E)
$$

where:

* \(V\) represents partitions;
* \(E\) represents locality relationships.

Edges MAY be weighted by:

* geometric distance;
* estimated communication cost;
* bandwidth;
* latency;
* workload;
* state dependency;
* execution affinity.

The locality graph MAY be used by:

* schedulers;
* routers;
* load balancers;
* simulators;
* communication systems.

The graph is a representation of partition relationships and does not replace partition identity.

---

# 23. Partition Ownership

A partition MAY have an owner.

Ownership MAY refer to:

* a process;
* a Semantic Machine;
* a node;
* a container;
* a GPU;
* a CPU;
* a service;
* another computational entity.

Conceptually:

$$
Owner(P) = E
$$

Ownership MAY change without changing partition identity.

---

# 24. Ownership Versus Containment

Ownership MUST remain distinct from spatial containment.

For example:

```text
Spatial Region R
    contains
Partition P

Machine M
    owns
Partition P
```

This does not imply:

```text
Machine M
    geometrically contains
Partition P
```

The distinction is essential when computational resources are distributed.

---

# 25. Resource Affinity

A partition MAY declare or derive affinity toward one or more execution resources.

Affinity MAY be based on:

* current state residency;
* historical workload;
* hardware capabilities;
* memory capacity;
* GPU availability;
* communication topology;
* energy cost;
* latency;
* bandwidth.

Affinity is a preference or constraint, not necessarily ownership.

---

# 26. Execution Mapping

A runtime MAY define:

$$
M : \Pi \rightarrow R
$$

where:

* \(\Pi\) is the partition set;
* \(R\) is the set of Execution Spaces.

This establishes where partition computation is currently realised.

The mapping MAY be:

* one-to-one;
* many-to-one;
* one-to-many;
* dynamic.

A partition MAY be distributed across multiple execution resources.

---

# 27. Spatial Load

A partition MAY have associated computational load.

Conceptually:

$$
Load(P)
$$

Load MAY include:

* operation count;
* execution time;
* memory consumption;
* state volume;
* message rate;
* communication volume;
* GPU utilisation;
* CPU utilisation;
* energy consumption.

Load measurements SHOULD be time-aware.

---

# 28. Adaptive Partitioning

A runtime MAY adapt partition granularity according to workload.

A simple conceptual policy is:

$$
Load(P) > T_{high}
\Rightarrow
Refine(P)
$$

and:

$$
Load(P) < T_{low}
\Rightarrow
Coarsen(P)
$$

where:

$$
T_{low} < T_{high}
$$

may be used to prevent oscillation.

SCR does not prescribe a particular adaptive partitioning algorithm.

---

# 29. Partition Balancing

A partitioning system MAY seek to distribute computational load across execution resources.

The balancing objective MAY be:

$$
minimise
\left(
ComputationCost +
CommunicationCost +
MovementCost +
ResourceCost
\right)
$$

subject to:

$$
Capacity(R_i) \ge Load(P_i)
$$

and applicable semantic constraints.

A scheduler SHOULD consider communication and data movement rather than treating computational capacity as the sole optimisation criterion.

---

# 30. Spatial Locality as a Scheduling Primitive

Spatial locality MAY directly influence scheduling.

Given partitions:

$$
P_1,P_2,\ldots,P_n
$$

a scheduler MAY prefer assigning spatially related partitions to the same or nearby execution resources.

Conceptually:

```text
Spatial locality
      ↓
Partition locality
      ↓
Data locality
      ↓
Execution locality
      ↓
Communication locality
```

This MAY reduce:

* memory transfers;
* network traffic;
* synchronisation;
* cache misses;
* state replication;
* message latency.

Spatial proximity MUST NOT be assumed to guarantee physical execution proximity.

---

# 31. Spatial Data Locality

A partition MAY have state associated with it.

A scheduler SHOULD consider the cost of moving that state when selecting an execution resource.

Conceptually:

$$
Cost(R,P)
=
ComputeCost
+
DataMovementCost
+
CommunicationCost
$$

This permits the runtime to prefer:

```text
Move computation to data
```

over:

```text
Move data to computation
```

where beneficial.

---

# 32. Partition Migration

A partition MAY migrate between Execution Spaces.

Conceptually:

$$
(P,R_1) \rightarrow (P,R_2)
$$

Migration MAY involve:

1. stopping or quiescing computation;
2. transferring state;
3. establishing destination resources;
4. transferring ownership;
5. updating routing;
6. resuming computation.

The semantic partition identity MUST remain stable unless an explicit transformation specifies otherwise.

---

# 33. State Migration

State associated with a partition MAY migrate independently of the partition.

Therefore:

```text
Partition P
    ↓
State S
```

does not require:

```text
Migration(P) = Migration(S)
```

State MAY be:

* replicated;
* migrated;
* cached;
* remotely referenced;
* lazily materialised.

---

# 34. Partition Replication

A partition MAY have multiple physical execution representations.

Conceptually:

```text
Semantic Partition P
       │
       ├── representation → Node A
       ├── representation → Node B
       └── representation → GPU C
```

Replication MUST preserve semantic identity.

The runtime MUST define consistency semantics where multiple active representations can mutate shared state.

---

# 35. Failure Domains

Spatial partitions MAY correspond to failure domains.

For example:

```text
Partition
    ↓
Execution Domain
    ↓
Failure Boundary
```

A partition MAY be intentionally placed so that failure of one resource does not affect unrelated partitions.

Failure-domain semantics SHOULD remain separate from geometric partition semantics.

---

# 36. Routing Domains

A partition MAY serve as a routing domain.

Messages associated with a spatial location MAY be resolved to a partition and subsequently to an execution endpoint.

Conceptually:

$$
Location
\rightarrow
Partition
\rightarrow
Owner
\rightarrow
Endpoint
$$

A routing system MUST distinguish:

```text
Semantic destination
```

from:

```text
Physical endpoint
```

---

# 37. Spatial Message Affinity

Messages MAY declare spatial affinity.

A message MAY contain or derive:

```text
spatial location
partition
neighbourhood
state reference
execution affinity
```

A router MAY use this information to minimise communication cost.

A message MUST NOT require a physical network address merely because it possesses spatial semantics.

---

# 38. Partition and Messaging

A messaging system MAY treat a partition as:

* a routing key;
* a queue domain;
* a consumer affinity domain;
* a stream partition;
* a message locality boundary.

These are implementation mappings.

The semantic partition remains independent of the messaging provider.

---

# 39. Partition and Hypergraph

A Spatial Partition MAY be represented as a node or region within an SCR Hypergraph.

For example:

```text
Partition P
    │
    ├── owns → State S
    ├── executes → Computation C
    ├── neighbour → Partition Q
    ├── hosted-by → Machine M
    └── routes → Endpoint E
```

The hypergraph MAY therefore represent relationships between:

* spatial partitions;
* state;
* computation;
* resources;
* messages;
* machines.

The hypergraph representation does not replace the underlying spatial semantics.

---

# 40. Partitioning and Semantic Fields

A Semantic Field MAY be partitioned spatially.

Conceptually:

```text
Semantic Field F
       │
       ├── Partition P1
       ├── Partition P2
       ├── Partition P3
       └── Partition P4
```

Each partition MAY contain a local portion of the field.

The field MAY also have relationships spanning multiple partitions.

Cross-partition operations MUST explicitly account for the required state and communication dependencies.

---

# 41. Partition Boundaries

A partition boundary MAY define a computational boundary.

Crossing a partition boundary MAY incur:

* communication;
* synchronisation;
* state transfer;
* scheduling;
* consistency costs.

A boundary does not inherently imply physical separation.

Two partitions may exist on the same processor.

Conversely, a single partition may span multiple physical machines.

---

# 42. Partition Cost

A runtime MAY associate costs with partition relationships.

For partitions \(P_i\) and \(P_j\):

$$
C(P_i,P_j)
$$

MAY represent:

* communication cost;
* state movement cost;
* synchronisation cost;
* execution cost;
* latency;
* energy.

This enables topology-aware scheduling and routing.

---

# 43. Partition Affinity Graph

A runtime MAY maintain an affinity graph:

```text
Partition A
   │
   ├── affinity → Partition B
   ├── affinity → Partition C
   └── low-affinity → Partition D
```

Affinity MAY be derived from:

* communication frequency;
* shared state;
* spatial neighbourhood;
* execution history;
* workload;
* dependency structure.

This graph MAY be used to optimise resource placement.

---

# 44. Partition Refinement and Resource Scaling

Spatial refinement MAY provide a mechanism for increasing computational parallelism.

Conceptually:

```text
        Partition P
             │
       computational load
             │
             ▼
        refinement
       /     |     \
     P1     P2     P3
     │      │      │
    GPU0   GPU1   GPU2
```

The resulting parallelism is an execution policy.

Refinement itself remains a semantic spatial operation.

---

# 45. Partition Coarsening and Resource Reclamation

Conversely:

```text
P1     P2     P3
 \      |      /
  \     |     /
   \    |    /
      P
      │
  resource release
```

Coarsening MAY permit:

* resource consolidation;
* memory reclamation;
* reduction in message endpoints;
* lower scheduling overhead.

Semantic state MUST remain preserved according to the applicable state model.

---

# 46. Lazy Partitions

A partition MAY exist semantically without an active physical representation.

This allows:

```text
Partition declared
       ↓
No resources allocated
       ↓
Work arrives
       ↓
Partition activated
```

Lazy partition materialisation SHOULD be supported where the provider permits it.

---

# 47. Sparse Partitioning

A Spatial Space MAY contain a very large theoretical partition domain while only a sparse subset is active.

For example:

```text
Global Space
│
├── Partition A      active
├── Partition B      inactive
├── Partition C      active
├── Partition D      undefined
└── ...
```

The runtime MUST NOT require materialisation of every possible partition.

This permits planetary-scale or otherwise extremely large computational spaces.

---

# 48. Partition Provider Abstraction

A partition provider SHOULD expose semantic operations equivalent to:

```text
partition.create()
partition.resolve()
partition.parent()
partition.children()
partition.neighbours()
partition.contains()
partition.overlaps()
partition.refine()
partition.coarsen()
partition.extent()
partition.locality()
partition.owner()
partition.load()
```

Providers MAY add additional operations.

Provider-specific operations MUST NOT alter the semantics of the core operations.

---

# 49. Partition Query Model

SCR MAY support queries such as:

```text
find partition containing location X

find partitions neighbouring P

find children of P

find parent of P

find partitions intersecting region R

find partitions owning state S

find partitions associated with resource R

find overloaded partitions

find partitions requiring refinement
```

Queries SHOULD operate on semantic concepts.

Provider-specific indexes SHOULD optimise their execution.

---

# 50. Provider Independence

SCR MUST remain capable of replacing a partition provider without changing the semantic model.

Possible providers MAY include:

```text
hierarchical hexagonal index
octree
quadtree
kd-tree
adaptive mesh
geospatial index
graph partitioner
hypergraph partitioner
application-defined partitioner
```

No provider is normative unless separately specified.

---

# 51. H3 as a Partition Provider

H3 is an example of a suitable partition provider.

When used by SCR in this role:

```text
H3 Cell
    ↓
Spatial Partition Identity
```

H3 MAY provide:

* hierarchical partitioning;
* parent/child relationships;
* neighbourhood;
* locality;
* partition lookup;
* spatial indexing;
* partition refinement.

The H3 cell MUST NOT become the SCR coordinate system merely because H3 is used as the partition provider.

H3's own coordinate and indexing mechanisms remain implementation details of the provider unless explicitly exposed through another semantic capability.

---

# 52. OpenVDB and Partitioning

OpenVDB is not intrinsically a partitioning provider under this model.

OpenVDB MAY represent Spatial State associated with a partition.

For example:

```text
Spatial Partition P
        │
        └── Spatial State
                │
                └── OpenVDB representation
```

An implementation MAY use OpenVDB's sparse tree structure internally for additional subdivision or storage locality.

Such internal subdivision MUST NOT automatically become SCR Spatial Partitions.

---

# 53. Partition-to-State Mapping

A partition MAY own, contain, reference, or otherwise associate with one or more Spatial State objects.

Conceptually:

$$
A(P,S)
$$

where `A` represents the applicable association.

The association MAY be:

* exclusive;
* shared;
* replicated;
* partial;
* lazy;
* derived.

A state object MAY span partition boundaries.

---

# 54. Cross-Partition State

A state field MAY cross partition boundaries.

For example:

```text
Partition A | Partition B
             |
        continuous field
```

The runtime MUST distinguish:

```text
state continuity
```

from:

```text
partition continuity
```

A partition boundary does not imply that the underlying semantic field is discontinuous.

---

# 55. Cross-Partition Computation

A computation MAY depend upon state in multiple partitions.

Conceptually:

$$
C(P_1,P_2,\ldots,P_n)
$$

The runtime SHOULD minimise unnecessary communication between those partitions.

This MAY be achieved through:

* co-location;
* replication;
* caching;
* locality-aware scheduling;
* message routing;
* partition refinement.

---

# 56. Partition-Aware Scheduling

A scheduler MAY use the following information:

```text
Partition identity
Spatial locality
Neighbourhood
Workload
State residency
Resource affinity
Communication cost
Resource capacity
Failure domain
```

to select execution resources.

A scheduler SHOULD treat movement as a cost where applicable.

---

# 57. Movement Cost

Partition movement and state movement MAY have different costs.

Conceptually:

$$
MovementCost =
PartitionCost +
StateCost +
CommunicationCost +
ReinitialisationCost
$$

The runtime SHOULD avoid unnecessary movement where the cost exceeds the benefit.

This is particularly important where state is large or strongly resident in specialised hardware.

---

# 58. Spatial Partition as an Execution Abstraction

A Spatial Partition MAY serve as an intermediate abstraction between semantic computation and physical execution.

```text
Semantic Computation
        │
        ▼
Spatial Partition
        │
        ▼
Scheduling Policy
        │
        ▼
Execution Resource
```

This permits the semantic computation to remain independent of the current execution topology.

---

# 59. Partition Ownership Transfer

Ownership MAY be transferred:

$$
Owner(P): R_1 \rightarrow R_2
$$

The transfer MUST preserve:

* partition identity;
* semantic relationships;
* applicable state;
* routing semantics;
* ownership consistency.

A transfer MAY require temporary coordination between source and destination.

---

# 60. Partition Consistency

A partition MUST have a well-defined authoritative state where mutable partition metadata is distributed.

The runtime MUST avoid simultaneous conflicting ownership unless the partition model explicitly supports multi-owner or replicated semantics.

---

# 61. Partition Provenance

Partition creation, refinement, coarsening, migration, and retirement SHOULD be traceable where provenance is required.

A partition MAY therefore have:

```text
created_from
refined_from
coarsened_from
migrated_from
owned_by
retired_from
```

This supports:

* reproducibility;
* auditing;
* debugging;
* simulation history;
* deterministic reconstruction.

---

# 62. Partition and Determinism

Where deterministic execution is required, partition assignment MUST be deterministic under the declared partitioning policy.

Dynamic load balancing MAY produce different physical partition ownership without changing semantic computation if the system permits execution nondeterminism.

---

# 63. Partition and Fault Recovery

A runtime SHOULD be capable of reconstructing partition execution from semantic state and partition identity where required.

A failure of an execution resource SHOULD NOT inherently imply deletion of the semantic partition.

For example:

```text
GPU 3 fails
   ↓
Partition P remains semantically valid
   ↓
P migrates to GPU 7
```

---

# 64. Partition and Replication

Replication MAY occur at several levels:

```text
Partition
State
Execution
Message stream
```

These levels MUST remain distinct.

Replicating a partition's state does not inherently create a second semantic partition.

---

# 65. Partition and Caching

A runtime MAY cache partition metadata or spatial state.

Caches MUST NOT become the semantic authority merely because they contain a local representation.

Cache invalidation MUST preserve the authoritative semantic state.

---

# 66. Partition Security Boundary

A partition MAY also serve as a security or policy boundary.

For example:

```text
Partition
    ↓
access policy
    ↓
resource policy
    ↓
state visibility
```

Spatial partitioning MUST NOT inherently imply security isolation.

Security semantics MUST be explicitly declared by the applicable security or policy domain.

---

# 67. Partition Policy

A partition MAY carry policy concerning:

* scheduling;
* ownership;
* replication;
* materialisation;
* state retention;
* resource affinity;
* communication;
* security;
* failure handling.

Policies MAY be inherited from parent partitions.

Explicit child policy SHOULD override inherited policy where permitted.

---

# 68. Partition Policy and Semantics

Policies MUST remain distinguishable from partition identity and geometry.

Changing a scheduling policy MUST NOT inherently change:

* partition identity;
* spatial extent;
* semantic state.

---

# 69. Partition Lifecycle and State Lifecycle

Partition lifecycle and Spatial State lifecycle MUST remain independent.

For example:

```text
Partition exists
State absent

Partition exists
State materialised

Partition inactive
State persisted

Partition retired
State retained elsewhere
```

This permits independent management of semantic space and manifested state.

---

# 70. Partition Granularity

Partition granularity SHOULD be selected according to the computational problem rather than dictated by coordinate precision.

A partition MAY be:

* larger than the finest spatial state;
* smaller than a geometric object;
* unrelated to rendering resolution;
* unrelated to simulation timestep;
* unrelated to storage block size.

Partition granularity is fundamentally a **computational topology decision**.

---

# 71. Multiple Partitionings

The same Spatial Space MAY possess multiple independent partitionings.

For example:

```text
Spatial Space
│
├── Partitioning A
│     └── simulation locality
│
├── Partitioning B
│     └── rendering locality
│
├── Partitioning C
│     └── storage locality
│
└── Partitioning D
      └── execution locality
```

This is an important capability.

A single spatial coordinate system MUST NOT require one universal partition topology.

---

# 72. Partition Translation

A system MAY map one partitioning onto another.

Conceptually:

$$
P_A(x) \rightarrow P_B(x)
$$

This permits:

* simulation partitions;
* storage partitions;
* rendering partitions;
* execution partitions;

to coexist.

Mappings MAY be one-to-one, one-to-many, many-to-one, or many-to-many.

---

# 73. Partition Overlay

Multiple partition systems MAY overlay the same Spatial Space.

For example:

```text
Reference Space
      │
      ├── H3 locality partition
      ├── VDB storage region
      ├── GPU execution partition
      └── simulation domain partition
```

The runtime MUST preserve the distinction between these partitioning systems.

---

# 74. Canonical Computational Model

The complete computational model is:

```text
                         SPATIAL SPACE
                              │
                       Reference Frame
                              │
                         Location x
                              │
                              ▼
                     Partition Function
                              │
                              ▼
                    Spatial Partition P
                    /        |         \
                   /         |          \
                  ▼          ▼           ▼
             Locality     Workload     State
                  │          │           │
                  └────┬─────┴───────────┘
                       │
                       ▼
                  Scheduler
                       │
                Resource Mapping
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
         CPU          GPU          Node
                       │
                       ▼
                  Computation
```

The partition is therefore the **semantic hinge** between spatial organisation and computational execution.

---

# 75. Formal Relationships

The core relationships can be expressed as:

### Spatial membership

$$
M(x,p)
$$

where `x` belongs to partition `p`.

### Parent relationship

$$
Parent(p_c)=p_p
$$

### Neighbourhood

$$
N(p)=\{p_1,\ldots,p_n\}
$$

### Ownership

$$
Owner(p)=r
$$

### Execution mapping

$$
Exec(p)=r
$$

### Workload

$$
Load(p,t)
$$

### Refinement

$$
Refine(p)\rightarrow\{p_1,\ldots,p_n\}
$$

### Coarsening

$$
Coarsen(\{p_1,\ldots,p_n\})\rightarrow p
$$

### Routing

$$
Route(x)\rightarrow p\rightarrow r
$$

### State association

$$
State(p)\rightarrow\{s_1,\ldots,s_n\}
$$

These relationships form the minimum conceptual vocabulary for spatially partitioned computation.

---

# 76. Normative Invariants

The following invariants are mandatory.

### SP-001 — Partition Identity

Every persistent or addressable partition MUST possess a semantic identity.

### SP-002 — Coordinate Independence

Partition identity MUST NOT be equivalent to coordinate identity.

### SP-003 — Provider Independence

The semantic partition model MUST NOT require a particular partitioning provider.

### SP-004 — Geometry Independence

A partition MUST remain semantically valid even when its geometric representation changes.

### SP-005 — State Independence

Partition identity MUST remain distinct from Spatial State identity.

### SP-006 — Execution Independence

Partition identity MUST remain distinct from execution resource identity.

### SP-007 — Ownership Independence

Ownership MAY change without changing partition identity.

### SP-008 — Migration Preservation

Migration MUST preserve partition identity unless an explicit semantic transformation occurs.

### SP-009 — Refinement Integrity

Refinement MUST preserve the semantic relationship between parent and child partitions.

### SP-010 — Coarsening Integrity

Coarsening MUST preserve applicable semantic state.

### SP-011 — Locality Independence

Spatial locality MUST NOT be assumed to equal physical execution locality.

### SP-012 — Routing Separation

Semantic routing destinations MUST remain distinct from physical transport endpoints.

### SP-013 — Materialisation Independence

Semantic partition existence MUST remain distinct from physical materialisation.

### SP-014 — Multiple Partitionings

SCR MUST permit multiple independent partitionings over the same Spatial Space.

### SP-015 — Provider Substitutability

A compliant partition provider MAY be replaced without changing the semantic definition of Spatial Partition.

### SP-016 — Explicit Membership

Partition membership MUST be semantically resolvable where membership is required by an operation.

### SP-017 — Hierarchy Integrity

Parent/child relationships MUST remain valid across refinement and coarsening.

### SP-018 — State Residency Separation

State residency MUST remain distinguishable from partition ownership.

### SP-019 — Workload Independence

Workload MUST be treated as a property or observation of a partition, not as its identity.

### SP-020 — Resource-Aware Locality

A runtime MAY optimise spatial computation according to physical resource locality, but MUST NOT redefine spatial locality as physical locality.

---

# 77. Non-Goals

This specification does not define:

* a specific spatial index;
* a specific coordinate system;
* a specific scheduler;
* a specific load balancer;
* a specific messaging protocol;
* a specific storage format;
* a specific geometry representation;
* a specific GPU architecture;
* a specific distributed computing protocol.

Those are provider or domain concerns.

---

# 78. Example Provider Composition

A valid implementation MAY use:

```text
                 SCR Spatial Space
                        │
             canonical reference frame
                        │
                        ▼
                H3 Partitioning
                        │
             computational locality
                        │
               ┌────────┴────────┐
               │                 │
               ▼                 ▼
          OpenVDB State      Other State
               │
               └────────┬────────┘
                        │
                        ▼
                 Resource Scheduler
                        │
              ┌─────────┼─────────┐
              ▼         ▼         ▼
            CPU       GPU       Node
                        │
                        ▼
                      Hyrx
```

In this arrangement:

* H3 partitions the computational domain;
* OpenVDB represents sparse volumetric state;
* the scheduler maps partitions to resources;
* Hyrx provides message/data movement;
* EGS provides execution and service orchestration.

None of these providers defines the underlying semantics of Spatial Space.

---

# 79. Example Adaptive Workload

Consider a spatial partition `P`.

Initially:

```text
P
│
└── GPU 0
```

Workload increases:

```text
Load(P) > threshold
```

The runtime refines:

```text
        P
     /  |  \
   P1  P2  P3
```

It then maps:

```text
P1 → GPU 0
P2 → GPU 1
P3 → GPU 2
```

Neighbour relationships remain available:

```text
P1 ↔ P2
P2 ↔ P3
```

Messages may therefore preferentially follow those locality relationships.

Later, workload falls:

```text
Load(P1), Load(P2), Load(P3) < threshold
```

The runtime coarsens:

```text
P1 P2 P3
   ↓
   P
```

The semantic spatial domain remains intact throughout.

---

# 80. Example Spatial Routing

Given:

```text
Location x
```

the runtime may resolve:

```text
x
 ↓
Partition P
 ↓
Owner R
 ↓
Execution Endpoint E
```

A message can therefore be addressed semantically:

```text
destination:
    spatial location x
```

rather than physically:

```text
destination:
    node-17:queue-382
```

The physical endpoint MAY change while the semantic destination remains stable.

---

# 81. Example Locality-Aware Placement

Suppose:

```text
P1 ↔ P2
P2 ↔ P3
```

and communication intensity is:

```text
C(P1,P2) = high
C(P2,P3) = high
C(P1,P3) = low
```

A scheduler MAY prefer:

```text
P1 → GPU 0
P2 → GPU 0
P3 → GPU 1
```

rather than:

```text
P1 → GPU 0
P2 → GPU 1
P3 → GPU 2
```

even if raw GPU capacity is identical.

The optimisation objective is reduced communication and state movement.

---

# 82. Example Multiple Partitionings

A single Spatial Space MAY simultaneously have:

```text
Partitioning A
    H3
    → geographic locality

Partitioning B
    OpenVDB tiles
    → state locality

Partitioning C
    GPU domains
    → execution locality

Partitioning D
    semantic graph regions
    → dependency locality
```

These partitionings MAY overlap.

No partitioning is inherently the universal partitioning of the Space.

---

# 83. Architectural Principle

The principal architectural rule is:

> **Partitioning is the topology of computational locality.**

It answers:

> **Which things should be considered together for the purposes of computation, state, routing, scheduling, and resource placement?**

It does not answer:

> **What are the coordinates of the universe?**

That question belongs to Spatial Reference Semantics.

---

# 84. Summary

SCR Spatial Partitioning provides an abstraction between spatial structure and physical computation.

The fundamental relationship is:

$$
\boxed{
Location
\rightarrow
Partition
\rightarrow
Locality
\rightarrow
Resource
}
$$

while state remains independently represented:

$$
\boxed{
Partition
\leftrightarrow
Spatial\ State
}
$$

and execution remains independently mapped:

$$
\boxed{
Partition
\rightarrow
Execution\ Space
}
$$

This permits a runtime to use hierarchical spatial indexes, sparse volumetric structures, distributed schedulers, messaging fabrics, GPUs, CPUs, and other execution providers without conflating their representations.

The resulting architecture permits:

* hierarchical spatial partitioning;
* adaptive computational granularity;
* locality-aware scheduling;
* spatial routing;
* data-aware resource placement;
* workload balancing;
* state residency;
* partition migration;
* multiple concurrent partitionings;
* sparse and lazy computational domains.

The core semantic distinction is therefore:

$$
\boxed{
\text{Spatial Partition}
=
\text{Computational Locality}
}
$$

not:

$$
\boxed{
\text{Spatial Partition}
=
\text{Coordinate System}
}
$$

A partition is where computation is **organised**.

A coordinate is where something is **located**.

State is what is **manifested**.

An execution resource is where computation is **physically realised**.

SCR preserves these distinctions so that each dimension can evolve, optimise, and be replaced independently.
