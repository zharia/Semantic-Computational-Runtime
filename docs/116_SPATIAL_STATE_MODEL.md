# SCR Spatial State Model

**Status:** Draft
**Document:** `docs/116_SPATIAL_STATE_MODEL.md`
**Version:** 0.1.0
**Authority:** Normative SCR Architecture Specification
**Depends on:**

* `docs/101_SEMANTIC_FIELD.md`
* `docs/106_SEMANTIC_MACHINE_MODEL.md`
* `docs/107_SEMANTIC_TRANSITION_CALCULUS.md`
* `docs/114_SPATIAL_SEMANTICS.md`
* `docs/115_SPATIAL_PARTITIONING_MODEL.md`

---

## 1. Purpose

This specification defines the **Spatial State Model** of the Semantic Computational Runtime (SCR).

The Spatial State Model defines how semantic state is:

* associated with spatial locations and regions;
* associated with spatial partitions;
* represented at different resolutions;
* materialised and dematerialised;
* stored and accessed;
* distributed and replicated;
* migrated;
* transformed between representations;
* associated with computational execution;
* updated through semantic transitions;
* maintained consistently across physical providers.

The purpose of this specification is to establish a provider-independent semantic model for spatial state.

Providers such as OpenVDB, databases, GPU memory, distributed storage systems, tensor stores, sparse arrays, and custom spatial indexes MAY implement the model.

They MUST NOT define the SCR semantic ontology.

The fundamental principle is:

> **Spatial state is semantic state associated with spatial structure; its representation, storage, materialisation, and physical residency are implementation concerns.**

---

# 2. Scope

This specification covers:

1. Spatial state.
2. Spatial state ownership.
3. Spatial state association.
4. Spatial state residency.
5. Spatial state materialisation.
6. Spatial state representation.
7. Spatial state resolution.
8. Spatial state density.
9. Spatial state locality.
10. Spatial state partitioning.
11. Spatial state migration.
12. Spatial state replication.
13. Spatial state consistency.
14. Spatial state transformation.
15. Spatial state refinement and coarsening.
16. Spatial state composition.
17. Spatial state invalidation.
18. Spatial state lifecycle.
19. Spatial state access.
20. Spatial state provider independence.
21. Spatial state relationship to Semantic Fields.
22. Spatial state relationship to computational partitions.
23. Spatial state relationship to execution resources.

This specification does **not** define:

* a universal coordinate system;
* a specific spatial data structure;
* a particular storage engine;
* a particular database;
* a particular memory architecture;
* a specific volumetric representation;
* a specific rendering representation;
* a specific physics representation.

---

# 3. Foundational Principle

SCR distinguishes four fundamentally different concepts:

```text
Coordinate
    ↓
describes where something is represented

Partition
    ↓
describes computational locality

State
    ↓
describes what semantic information is manifested

Execution Resource
    ↓
describes where computation is physically performed
```

Therefore:

```text
Coordinate ≠ Partition ≠ State ≠ Execution Resource
```

These concepts MAY be related.

They MUST NOT be conflated.

A physical provider MAY implement several of them simultaneously, but its implementation MUST preserve the semantic distinction.

For example, an OpenVDB tree MAY simultaneously provide:

* sparse state storage;
* spatial indexing;
* locality;
* hierarchical subdivision;
* efficient access.

That does not make OpenVDB's index space the SCR coordinate system.

Likewise, an H3 cell MAY identify a computational partition without becoming the SCR spatial coordinate system.

---

# 4. Definition of Spatial State

A **Spatial State** is semantic information associated with a spatial domain.

Formally:

$$
S = (I, D, R, A, V, T)
$$

where:

* \(I\) = state identity;
* \(D\) = spatial domain;
* \(R\) = representation;
* \(A\) = association;
* \(V\) = semantic value;
* \(T\) = temporal validity.

A state therefore has both:

1. semantic content; and
2. spatial association.

A spatial state is not merely an array indexed by coordinates.

It is a semantic object whose values have meaning within a spatial domain.

---

# 5. Spatial Domain

A **Spatial Domain** identifies the region over which a state is defined.

A domain MAY be:

* a point;
* a volume;
* a surface;
* a line;
* a cell;
* a region;
* a partition;
* a hierarchy;
* a set of disconnected regions;
* an unbounded domain;
* a dynamically changing domain.

A spatial domain is independent of its representation.

For example:

```text
Semantic Domain
      │
      ├── continuous volume
      │
      ├── OpenVDB sparse tree
      │
      ├── dense tensor
      │
      ├── mesh
      │
      └── GPU buffer
```

These MAY represent the same semantic domain at different levels of representation.

---

# 6. State Association

A state MAY be associated with:

* a spatial coordinate;
* a spatial region;
* a spatial partition;
* multiple partitions;
* a spatial hierarchy;
* a computational field;
* an execution space;
* another state object.

State association MUST be explicit.

For example:

$$
A(s,x)
$$

means:

> state \(s\) is semantically associated with spatial location \(x\).

Likewise:

$$
A(s,p)
$$

means:

> state \(s\) is associated with partition \(p\).

Association does not imply ownership.

Association does not imply physical storage.

Association does not imply execution residency.

---

# 7. State Identity

Every independently addressable semantic state object MUST have an identity.

State identity is distinct from:

* coordinate;
* partition identity;
* physical address;
* memory address;
* storage key;
* provider object identifier;
* process identifier.

A state identity MAY remain stable while its representation changes.

For example:

```text
State S42

representation:
    OpenVDB
        ↓
    GPU sparse tensor
        ↓
    distributed tensor
        ↓
    compressed archive
```

The representation may change without changing the semantic identity of the state.

---

# 8. State Representation

A **State Representation** is a concrete encoding of semantic state.

Examples include:

* scalar;
* vector;
* tensor;
* sparse tensor;
* dense array;
* mesh;
* voxel field;
* point cloud;
* graph;
* hypergraph;
* compressed representation;
* procedural representation;
* symbolic representation;
* GPU-resident buffer;
* distributed representation.

Representation is not ontology.

The semantic state:

$$
S
$$

MAY have multiple representations:

$$
R_1(S), R_2(S), \ldots, R_n(S)
$$

provided that the representations preserve the required semantic invariants.

---

# 9. Canonical Semantic State

Where multiple representations exist, SCR MUST distinguish between:

1. **semantic state**;
2. **canonical representation**, where required;
3. **provider representation**.

The semantic state is authoritative.

A provider representation is an implementation of that state.

A provider MAY become authoritative for a particular operational state only through an explicit SCR-defined authority mechanism.

Provider storage MUST NOT silently redefine semantic meaning.

---

# 10. State Residency

**State Residency** identifies where a representation of state is currently materialised.

Residency MAY occur in:

* CPU memory;
* GPU memory;
* persistent storage;
* distributed storage;
* network-attached memory;
* provider-managed storage;
* cache;
* device-local memory;
* remote execution space.

Residency is not identity.

For example:

```text
Semantic State S42
        │
        ├── CPU representation
        ├── GPU representation
        └── persistent representation
```

All MAY refer to the same semantic state.

---

# 11. State Materialisation

**Materialisation** is the process by which semantic state becomes represented in an operational representation.

$$
M : S \rightarrow R
$$

where:

* \(S\) = semantic state;
* \(R\) = representation.

Materialisation MAY be:

* eager;
* lazy;
* partial;
* demand-driven;
* cached;
* replicated;
* distributed;
* transient.

Materialisation MUST preserve semantic state invariants.

---

# 12. State Dematerialisation

**Dematerialisation** removes an operational representation while preserving semantic state where the state remains semantically valid.

$$
D : R \rightarrow S
$$

Dematerialisation MUST NOT imply semantic deletion.

For example:

```text
Semantic State
     │
     ├── CPU representation
     ├── GPU representation
     └── persistent representation
                 ↓
          dematerialise GPU
                 ↓
Semantic State remains valid
```

Physical absence is therefore not equivalent to semantic absence.

---

# 13. State Deletion

Semantic deletion is distinct from dematerialisation.

A state is deleted only when its semantic existence is explicitly terminated.

Therefore:

```text
dematerialise ≠ delete
evict ≠ delete
unload ≠ delete
disconnect ≠ delete
migration ≠ delete
```

A provider MUST NOT interpret cache eviction or physical deallocation as semantic deletion unless explicitly authorised.

---

# 14. State Resolution

**State Resolution** describes the spatial granularity at which state is represented.

Resolution MAY be:

* continuous;
* discrete;
* uniform;
* adaptive;
* hierarchical;
* multi-resolution;
* provider-specific.

For a representation \(R\), resolution is a property of the representation and its relationship to the semantic domain.

A provider's native resolution MUST NOT automatically become SCR's universal spatial resolution.

---

# 15. State Density

**State Density** describes the amount or concentration of meaningful state associated with a spatial region.

Density MAY describe:

* number of state elements;
* information density;
* computational density;
* update frequency;
* semantic complexity;
* data volume;
* physical occupancy;
* dependency density.

Density MAY be used to trigger:

* refinement;
* partitioning;
* caching;
* migration;
* replication;
* resource allocation;
* execution placement.

Density MUST NOT be confused with spatial geometry.

---

# 16. Sparse State

SCR MUST support sparse state.

A sparse representation represents only portions of a semantic domain for which state is materially represented.

Sparse state does not imply that unrepresented regions have no semantic meaning.

The distinction is:

```text
undefined
    ≠
known empty
    ≠
zero-valued
    ≠
not materialised
    ≠
not resident
    ≠
deleted
```

These states MUST be semantically distinguishable where required by the domain.

---

# 17. Null and Empty State

SCR MUST define explicit semantics for empty spatial state.

At minimum, implementations MUST distinguish:

1. no state exists;
2. state exists and is empty;
3. state exists with a defined null value;
4. state exists but is not currently materialised;
5. state exists but representation is unavailable;
6. state has been deleted.

A provider MUST NOT collapse these states merely because its native representation does not distinguish them.

---

# 18. State Continuity

Spatial state MAY be continuous or discrete.

A representation MUST declare its semantic interpretation.

For example:

```text
continuous field
        ↓
sampled representation
        ↓
discrete storage
```

does not imply:

```text
continuous state = discrete coordinates
```

The transformation between representations MUST be explicit.

Interpolation, aggregation, sampling, quantisation, and reconstruction are semantic transformations and MUST NOT be treated as transparent representation changes when they alter semantic information.

---

# 19. State Transformation

A transformation between state representations is a semantic operation.

Examples:

* sampling;
* interpolation;
* aggregation;
* refinement;
* coarsening;
* projection;
* voxelisation;
* meshing;
* compression;
* decompression;
* coordinate transformation;
* type conversion;
* precision conversion.

A transformation:

$$
T : R_1 \rightarrow R_2
$$

MUST specify whether it is:

* lossless;
* approximately lossless;
* lossy;
* reversible;
* irreversible;
* deterministic;
* nondeterministic;
* semantics-preserving;
* semantics-changing.

---

# 20. State Refinement

State refinement increases the representational resolution or semantic granularity of state.

For example:

$$
S_R \rightarrow \{S_1,S_2,\ldots,S_n\}
$$

A refinement operation MUST preserve the semantic meaning of the original state within the declared transformation semantics.

Refinement MAY be triggered by:

* increased spatial resolution requirements;
* simulation dynamics;
* local state density;
* computational workload;
* rendering requirements;
* physical phenomena;
* numerical stability;
* agent activity.

---

# 21. State Coarsening

State coarsening reduces representation resolution or combines multiple state elements.

$$
\{S_1,S_2,\ldots,S_n\} \rightarrow S_R
$$

Coarsening MUST explicitly define the aggregation semantics.

Examples include:

* average;
* sum;
* minimum;
* maximum;
* representative value;
* probabilistic distribution;
* conservation-preserving aggregation.

Coarsening MUST NOT silently discard semantically significant state.

---

# 22. Conservation

Where a domain declares conserved quantities, state transformations MUST preserve those quantities according to the domain's semantic laws.

For example:

```text
mass
energy
charge
momentum
probability
resource quantity
```

may require conservation across:

* refinement;
* coarsening;
* migration;
* replication;
* representation conversion.

Conservation rules belong to the relevant semantic domain.

The spatial state model provides the mechanism for enforcing them but does not define domain-specific physical laws.

---

# 23. State and Partition

Spatial state and spatial partition are related but independent.

A partition identifies computational locality:

$$
p \in \Pi
$$

State identifies semantic information:

$$
s \in S
$$

A state MAY:

* reside in one partition;
* span multiple partitions;
* be replicated across partitions;
* migrate between partitions;
* be independent of partition materialisation.

Therefore:

$$
State \neq Partition
$$

Partitioning answers:

> Where should computation and state locality be organised?

State answers:

> What semantic information exists or is manifested?

---

# 24. State Residency in Partitions

A state MAY have a residency relation:

$$
R(s,p)
$$

meaning:

> a representation of state \(s\) is resident in partition \(p\).

Residency does not imply exclusive ownership.

For example:

```text
State S42
   │
   ├── resident in P1
   ├── replicated in P2
   └── cached in P3
```

The semantic state remains one state even when multiple representations exist.

---

# 25. State Ownership

Ownership identifies the authority responsible for maintaining a state.

Ownership is distinct from:

* residency;
* representation;
* execution;
* caching;
* replication.

For example:

```text
Owner:        P1
Primary:      GPU0
Replica:      GPU1
Cache:        CPU
Execution:    CPU2
```

These MAY all differ.

Ownership semantics MUST be explicit.

---

# 26. State Authority

An implementation MUST identify the authority for state where multiple representations exist.

Authority MAY be:

* a partition;
* a semantic field;
* a state manager;
* a provider;
* a distributed consensus mechanism;
* an application-defined authority.

The existence of multiple physical copies MUST NOT create ambiguous semantic authority.

---

# 27. State Replication

State MAY be replicated.

Replication creates multiple representations of one semantic state:

$$
S \rightarrow \{R_1(S),R_2(S),...,R_n(S)\}
$$

Replication MAY be:

* synchronous;
* asynchronous;
* eventual;
* versioned;
* snapshot-based;
* read-only;
* writable.

The replication model MUST define:

* authority;
* version;
* consistency;
* update propagation;
* conflict handling;
* failure behaviour.

---

# 28. State Consistency

SCR MUST distinguish semantic consistency from physical consistency.

Two representations MAY temporarily differ while belonging to the same semantic state if the declared consistency model permits it.

A state representation MUST therefore be associated with a version or validity relation where necessary.

For example:

$$
R_1(S,v_7)
$$

and

$$
R_2(S,v_6)
$$

may coexist under an explicitly declared asynchronous replication model.

A provider MUST NOT silently present stale state as current authoritative state.

---

# 29. State Versioning

State SHOULD support version identity where mutation or replication requires historical distinction.

A state version MAY identify:

* semantic state transition;
* snapshot;
* provider representation;
* replication epoch;
* temporal validity interval.

Version identity is distinct from state identity.

For example:

```text
State S42
   ├── v1
   ├── v2
   ├── v3
   └── v4
```

State identity remains `S42`.

---

# 30. Temporal State

Spatial state MAY be time-dependent.

A temporal spatial state may be represented as:

$$
S(x,t)
$$

or, more generally:

$$
S(D,T)
$$

where \(D\) is spatial domain and \(T\) is temporal validity.

Temporal state MAY support:

* snapshots;
* continuous evolution;
* event histories;
* trajectories;
* simulation frames;
* temporal interpolation;
* rollback;
* branching.

The temporal semantics of a domain MUST be defined separately from the spatial representation.

---

# 31. State Transition

Spatial state changes through semantic transitions.

A transition MAY be represented as:

$$
S_t \xrightarrow{\tau} S_{t+1}
$$

where \(\tau\) is a valid Semantic Transition.

The transition MAY modify:

* values;
* spatial association;
* resolution;
* representation;
* partition residency;
* ownership;
* replication;
* materialisation.

The transition MUST preserve all applicable semantic invariants.

---

# 32. Spatial State Movement

State movement occurs when a representation or authoritative state changes physical residency.

Examples:

```text
CPU → GPU
GPU → CPU
Node A → Node B
Partition P1 → Partition P2
Disk → memory
Memory → persistent storage
```

Movement MUST distinguish:

1. movement of representation;
2. movement of semantic authority;
3. movement of partition residency;
4. movement of execution;
5. movement of spatial association.

These operations MUST NOT be conflated.

---

# 33. State Migration

**State Migration** moves state residency between computational partitions or execution spaces.

Migration MUST preserve semantic identity unless the operation explicitly creates a new state.

For example:

$$
R(s,p_1) \rightarrow R(s,p_2)
$$

does not imply:

$$
s_1 \neq s_2
$$

The state remains the same semantic object.

Migration MAY require:

* serialisation;
* transfer;
* reconstruction;
* cache invalidation;
* ownership transfer;
* synchronization;
* provider transformation.

---

# 34. Spatial Relocation vs State Migration

Spatial relocation and state migration are distinct.

A state MAY move physically without changing its semantic location.

Conversely, a state MAY change semantic spatial location while remaining physically resident in the same memory.

Therefore:

```text
physical movement ≠ spatial movement
spatial movement ≠ physical movement
```

This distinction is essential for distributed simulation and spatial computing.

---

# 35. State and Execution

Execution consumes or transforms state.

An execution resource MAY:

* read state;
* write state;
* transform state;
* materialise state;
* dematerialise state;
* migrate state;
* replicate state.

Execution resource identity MUST remain distinct from state identity.

For example:

```text
State S42
     ↓
Execution E7
     ↓
State S43
```

does not imply that `E7` is part of either state's identity.

---

# 36. State and Semantic Fields

Spatial state is a manifestation of semantic information within a Semantic Field.

A Semantic Field MAY contain:

* spatial state;
* topology;
* relationships;
* executable structures;
* metadata;
* constraints;
* transitions.

Spatial state MUST therefore remain compatible with the broader Semantic Field model.

The spatial state model does not replace the Semantic Field.

It specialises the representation of state whose semantics include spatial association.

---

# 37. State and Hypergraphs

Spatial state MAY participate in the SCR executable semantic hypergraph.

For example:

```text
State
  │
  ├── associated-with → Spatial Region
  ├── resident-in → Partition
  ├── represented-by → Provider Object
  ├── transformed-by → Function
  └── consumed-by → Process
```

These relationships MAY be represented as semantic hypergraph relations.

The hypergraph representation does not replace the spatial state model.

Spatial semantics remain authoritative.

---

# 38. State Locality

State locality describes the degree to which related state is spatially or computationally colocated.

Locality MAY be measured using:

* spatial distance;
* partition adjacency;
* memory proximity;
* communication latency;
* bandwidth;
* access frequency;
* dependency density;
* execution affinity.

State locality MAY influence scheduling and partitioning.

It MUST NOT redefine spatial semantics.

---

# 39. Data Locality

SCR SHOULD prefer computation placement that reduces unnecessary state movement.

Where appropriate:

$$
Cost =
C_{compute}
+
C_{movement}
+
C_{communication}
+
C_{memory}
+
C_{synchronisation}
$$

may be minimised by moving computation toward state rather than moving state toward computation.

This is an optimisation principle.

It MUST NOT become a semantic requirement that binds the architecture to a particular hardware topology.

---

# 40. State Caching

A provider MAY cache state.

A cache is not automatically authoritative.

Caching semantics MUST define:

* source;
* version;
* validity;
* expiration;
* invalidation;
* consistency model.

Cache eviction MUST NOT imply semantic deletion.

---

# 41. State Invalidation

State representation MAY become invalid because of:

* source mutation;
* version change;
* provider failure;
* transformation failure;
* ownership transfer;
* expiration;
* corruption;
* explicit invalidation.

Invalidation of a representation does not necessarily invalidate semantic state.

For example:

```text
GPU representation invalid
        ↓
semantic state remains valid
        ↓
re-materialise from authoritative source
```

---

# 42. State Failure

SCR MUST distinguish:

1. semantic state failure;
2. representation failure;
3. provider failure;
4. execution failure;
5. partition failure;
6. residency failure.

A physical provider failure MUST NOT automatically imply semantic state loss if another valid representation or recovery mechanism exists.

---

# 43. State Recovery

State recovery MAY use:

* replicas;
* snapshots;
* persistent storage;
* event history;
* deterministic recomputation;
* semantic transitions;
* provider reconstruction.

Recovery MUST preserve semantic identity and applicable invariants.

---

# 44. Multi-Resolution State

SCR SHOULD support multiple simultaneous representations of the same semantic state at different resolutions.

For example:

```text
State S42
   │
   ├── coarse representation
   ├── medium representation
   └── high-resolution representation
```

Each representation MUST declare its relationship to the semantic state.

A coarse representation MUST NOT silently replace a higher-resolution authoritative state if information would be lost.

---

# 45. Adaptive Spatial State

Spatial state MAY adapt its representation according to workload or semantic requirements.

Possible triggers include:

* local activity;
* simulation dynamics;
* rendering requirements;
* agent density;
* information density;
* computational demand;
* memory constraints;
* execution locality;
* physical phenomena.

Adaptive representation MUST preserve semantic invariants.

---

# 46. State and H3

H3 MAY be used by an SCR provider to associate state with hierarchical spatial partitions.

For example:

```text
SCR Spatial State
       │
       ↓
H3 Partition
       │
       ↓
State Residency
```

H3 MAY provide:

* hierarchical partition identity;
* spatial locality;
* neighbour relationships;
* parent/child relationships;
* partition lookup;
* partition refinement;
* partition routing.

H3 MUST NOT become the SCR semantic coordinate system.

An H3 index identifies a provider partition.

It does not by itself define the semantic meaning of a spatial coordinate.

---

# 47. State and OpenVDB

OpenVDB is a natural provider for sparse spatial state.

It MAY provide:

* sparse volumetric representation;
* hierarchical storage;
* sparse state access;
* voxel-oriented representation;
* spatial transforms;
* efficient neighbourhood access.

OpenVDB's index coordinates are provider coordinates.

They MUST NOT automatically become SCR canonical coordinates.

An SCR OpenVDB provider MUST expose the transformation between the SCR spatial reference frame and the OpenVDB representation.

Conceptually:

```text
SCR Spatial Reference Frame
            │
            │ transform
            ↓
OpenVDB Index / World Representation
            │
            ↓
OpenVDB State
```

---

# 48. H3 and OpenVDB Together

H3 and OpenVDB MAY be combined without conflating their roles.

For example:

```text
                    SCR Spatial State
                           │
             ┌─────────────┴─────────────┐
             │                           │
       Spatial Partition            State Representation
             │                           │
            H3                        OpenVDB
             │                           │
       computational              sparse volumetric
         locality                       state
```

This allows:

* H3 to answer **which computational locality?**
* OpenVDB to answer **what sparse spatial state is materialised?**

Neither provider becomes the SCR spatial ontology.

---

# 49. Multiple State Providers

SCR MUST permit multiple state providers to represent compatible semantic state.

Examples include:

* OpenVDB;
* dense tensors;
* sparse tensors;
* databases;
* object stores;
* GPU memory;
* CPU memory;
* distributed arrays;
* meshes;
* point clouds;
* custom providers.

Provider substitution MUST NOT require modification of the semantic model.

If two providers satisfy the same declared semantic capability, the semantic computation SHOULD remain unchanged.

---

# 50. Provider Mapping

A provider mapping is a relation:

$$
M : S \rightarrow R_p
$$

where:

* \(S\) = semantic state;
* \(R_p\) = provider representation.

The mapping MUST specify:

* semantic identity;
* representation type;
* spatial reference frame;
* resolution;
* precision;
* validity;
* ownership;
* residency;
* version;
* transformation semantics.

---

# 51. Provider Capability

Providers SHOULD declare capabilities rather than define ontology.

Example:

```text
provider:
    OpenVDB

capabilities:
    sparse_spatial_state
    hierarchical_storage
    volumetric_access
    spatial_transform
```

The SCR semantic layer determines whether those capabilities satisfy a requested operation.

---

# 52. State Access

State access MUST be expressed semantically.

Conceptually:

$$
Read(S,D)
$$

requests state \(S\) over domain \(D\).

The runtime MAY satisfy this using:

* local memory;
* cache;
* OpenVDB;
* GPU memory;
* remote node;
* replicated state;
* recomputation.

The access mechanism MUST remain separate from the semantic request.

---

# 53. Partial State Access

SCR SHOULD support partial access to spatial state.

A request MAY specify:

* region;
* partition;
* resolution;
* time;
* representation;
* precision;
* consistency requirement.

For example:

```text
Read:
    State = S42
    Region = R17
    Resolution = adaptive
    Time = t42
    Consistency = authoritative
```

The provider MAY satisfy the request using any valid representation.

---

# 54. State Streaming

Spatial state MAY be streamed.

Streaming MAY occur:

* spatially;
* temporally;
* partition-by-partition;
* resolution-by-resolution;
* incrementally;
* event-driven.

A state stream is a sequence of semantic state observations or transitions.

Transport infrastructure MUST NOT become part of spatial semantics.

---

# 55. State Delta

State updates MAY be represented as deltas.

$$
\Delta S = S_{t+1} - S_t
$$

A delta MUST have declared semantics.

A delta MAY describe:

* value changes;
* additions;
* removals;
* movement;
* topology changes;
* representation changes.

A delta is not itself necessarily a complete state.

---

# 56. State Provenance

Spatial state SHOULD maintain provenance where required.

Provenance MAY include:

* source;
* transformation;
* provider;
* version;
* timestamp;
* semantic transition;
* execution identity;
* partition history.

Provenance is particularly important when multiple providers and transformations participate in state evolution.

---

# 57. State Lineage

State lineage identifies the relationship between state versions and transformations.

For example:

```text
S0
 │
 ├── transform A → S1
 │
 ├── transform B → S2
 │
 └── refinement → S3
```

Lineage MAY support:

* debugging;
* reproducibility;
* rollback;
* validation;
* provenance;
* simulation analysis.

---

# 58. State Consistency Across Partitions

When state spans multiple partitions, consistency MUST be explicitly defined.

Possible models include:

* strict consistency;
* causal consistency;
* eventual consistency;
* snapshot consistency;
* domain-specific consistency.

The spatial partitioning model determines locality.

The state model determines the consistency of state across that locality.

These are separate concerns.

---

# 59. State Transfer and Messaging

State movement MAY use SCR messaging infrastructure.

Messages SHOULD carry:

* state identity;
* version;
* semantic type;
* spatial association;
* partition association;
* representation metadata;
* provider metadata;
* transformation requirements;
* payload or payload reference.

The transport system MUST NOT redefine state semantics.

This permits providers such as HyrxMQ to transport references to large or GPU-resident state without requiring the semantic layer to understand the physical transport implementation.

---

# 60. Reference-Based State

SCR MAY represent state through references rather than copying state payloads.

For example:

```text
Semantic State
      │
      ↓
State Reference
      │
      ├── provider
      ├── location
      ├── version
      ├── representation
      └── access capability
```

A reference is not the state itself.

Reference validity MUST be explicitly defined.

---

# 61. State and Identity

State identity MUST remain stable across:

* provider changes;
* representation changes;
* partition migration;
* execution migration;
* caching;
* replication;
* materialisation changes.

Identity MAY change only through explicit semantic identity operations.

---

# 62. State and Spatial Identity

Spatial identity and state identity are distinct.

A state MAY remain associated with the same spatial region while its representation changes.

A state MAY move to a different spatial region while retaining state identity.

Therefore:

$$
StateIdentity \neq SpatialIdentity
$$

This distinction is required for simulations, moving agents, transported physical quantities, and dynamic spatial systems.

---

# 63. State and Spatial Topology

Spatial state MAY affect topology.

For example:

* state density may trigger partition refinement;
* state occupancy may create regions;
* state transitions may alter connectivity;
* state may create or destroy relationships.

However, state-dependent topology MUST be represented as an explicit semantic relationship.

The implementation MUST NOT infer permanent ontology from transient provider state.

---

# 64. State-Driven Partitioning

Spatial state MAY drive partition adaptation.

For example:

```text
high state density
        ↓
partition refinement
        ↓
increased computational locality
        ↓
resource allocation
```

Conversely:

```text
low state density
        ↓
partition coarsening
        ↓
reduced computational overhead
```

The state model supplies the signal.

The partitioning model defines the partition operation.

---

# 65. State Materialisation and Partition Materialisation

These are independent operations.

A partition MAY exist semantically without its state being materialised.

State MAY be materialised without the partition being actively executing.

Therefore:

```text
partition exists
    ≠
state materialised
    ≠
state resident
    ≠
computation executing
```

This distinction is fundamental to lazy and distributed computation.

---

# 66. State Lifecycle

A state representation MAY follow:

```text
undefined
    ↓
declared
    ↓
available
    ↓
materialised
    ↓
resident
    ↓
active
    ↓
updated
    ↓
replicated
    ↓
migrated
    ↓
inactive
    ↓
dematerialised
    ↓
retired
```

Semantic state and representation lifecycle MUST remain distinguishable.

A representation MAY disappear while semantic state remains valid.

---

# 67. State Retirement

A state is retired when its semantic existence is intentionally terminated.

Retirement MUST be distinct from:

* cache eviction;
* dematerialisation;
* provider failure;
* partition shutdown;
* process termination;
* network disconnection.

Retirement SHOULD preserve provenance where required.

---

# 68. State Integrity

Spatial state integrity requires that:

1. identity remains valid;
2. spatial association remains valid;
3. representation metadata remains correct;
4. transformations are declared;
5. versions are coherent;
6. provider mappings are valid;
7. applicable conservation laws are preserved;
8. ownership is unambiguous;
9. authority is identifiable;
10. invalid representations are not presented as valid state.

---

# 69. Formal State Model

An abstract SCR spatial state MAY be represented as:

$$
S =
(I,
D,
A,
R,
V,
Q,
P,
O,
H,
T)
$$

where:

* \(I\) = identity;
* \(D\) = domain;
* \(A\) = spatial association;
* \(R\) = representation;
* \(V\) = semantic value;
* \(Q\) = resolution/quality;
* \(P\) = partition association;
* \(O\) = ownership/authority;
* \(H\) = residency/materialisation state;
* \(T\) = temporal validity.

Not every implementation must materialise every component physically.

The semantic model remains conceptually complete.

---

# 70. State Operations

The following abstract operations SHOULD be supported:

```text
declare_state
associate_state
materialise_state
dematerialise_state
read_state
write_state
transform_state
refine_state
coarsen_state
replicate_state
invalidate_state
migrate_state
retire_state
restore_state
snapshot_state
restore_snapshot
```

Each operation MUST define its semantic preconditions and postconditions.

---

# 71. Semantic State Operation Invariants

Operations MUST satisfy:

$$
Identity_{before} = Identity_{after}
$$

unless identity change is explicitly intended.

For state movement:

$$
State_{before} \equiv State_{after}
$$

subject to declared transformation semantics.

For representation change:

$$
Meaning(R_1) \equiv Meaning(R_2)
$$

when the operation is declared semantics-preserving.

For lossy transformation:

$$
Meaning(R_1) \not\equiv Meaning(R_2)
$$

MUST be explicitly acknowledged.

---

# 72. Provider Independence

The following substitutions SHOULD be possible without changing semantic application logic:

```text
OpenVDB
   ↕
alternative sparse volumetric provider

CPU memory
   ↕
GPU memory

local storage
   ↕
distributed storage

dense tensor
   ↕
sparse tensor
```

provided that the provider satisfies the same declared semantic capability.

---

# 73. Spatial State Invariants

The following invariants are normative.

### SS-001 — State Identity

Spatial state MUST have a semantic identity independent of representation and residency.

### SS-002 — Representation Independence

Semantic state MUST NOT be defined by its provider representation.

### SS-003 — Residency Independence

State identity MUST NOT depend on physical residency.

### SS-004 — Materialisation Independence

Dematerialisation MUST NOT imply semantic deletion.

### SS-005 — Deletion Explicitness

Semantic deletion MUST be explicit.

### SS-006 — Coordinate Independence

Provider coordinates MUST NOT automatically become SCR canonical coordinates.

### SS-007 — Partition Independence

State identity MUST remain independent of partition identity.

### SS-008 — Ownership Independence

Ownership MUST remain distinct from residency.

### SS-009 — Authority Explicitness

Where multiple representations exist, semantic authority MUST be identifiable.

### SS-010 — Replication Integrity

Replicas MUST remain attributable to the same semantic state or explicitly declared derived state.

### SS-011 — Version Integrity

Where versions are required, stale or invalid representations MUST NOT be presented as authoritative current state.

### SS-012 — Transformation Explicitness

Lossy or semantics-changing transformations MUST be explicitly declared.

### SS-013 — Resolution Explicitness

Representation resolution MUST be explicit and MUST NOT silently redefine semantic spatial resolution.

### SS-014 — Empty-State Distinction

Undefined, empty, null, unmaterialised, unavailable, and deleted state MUST remain distinguishable where semantically relevant.

### SS-015 — Migration Preservation

Migration MUST preserve semantic identity unless explicitly defined otherwise.

### SS-016 — Spatial Association

Spatial association MUST be explicit and independent of provider storage layout.

### SS-017 — Provider Substitutability

Providers satisfying equivalent semantic capabilities SHOULD be substitutable without semantic application changes.

### SS-018 — Conservation

Declared domain conservation laws MUST be preserved across applicable state transformations.

### SS-019 — Failure Separation

Provider or residency failure MUST NOT automatically imply semantic state failure.

### SS-020 — Authority Preservation

Replication, caching, and migration MUST NOT create ambiguous semantic authority.

### SS-021 — State/Partition Separation

State MUST remain distinct from computational partitioning.

### SS-022 — State/Execution Separation

State MUST remain distinct from execution resource identity.

### SS-023 — Physical/Semantic Separation

Physical movement MUST NOT automatically imply semantic spatial movement.

### SS-024 — Explicit Reference Semantics

State references MUST identify the state, representation, version, and validity required to use them safely.

### SS-025 — Provenance

Where required for correctness or reproducibility, state transformations MUST preserve provenance.

---

# 74. Relationship to the Spatial Model

The three spatial specifications form a deliberate separation of concerns:

```text
114 Spatial Semantics
        │
        ├── What does space mean?
        │
        ↓
115 Spatial Partitioning Model
        │
        ├── How is computational locality organised?
        │
        ↓
116 Spatial State Model
        │
        └── What semantic information is manifested there?
```

Together:

```text
                    Spatial Semantics
                           │
             ┌─────────────┴─────────────┐
             │                           │
        Partitioning                   State
             │                           │
       computational               semantic
         locality                  information
             │                           │
             └─────────────┬─────────────┘
                           │
                     Execution Mapping
                           │
                           ↓
                    Physical Resources
```

This separation MUST be preserved.

---

# 75. Relationship to Semantic Machine Model

The Semantic Machine Model defines computational spaces and execution environments.

Spatial state may reside within those spaces.

For example:

```text
Semantic Machine
      │
      ├── computational space
      │       │
      │       ├── partition
      │       │      │
      │       │      └── spatial state
      │       │
      │       └── process
      │
      └── storage space
```

The machine model defines the computational environment.

The spatial state model defines the semantic state residing within or associated with that environment.

Neither model should absorb the other.

---

# 76. Relationship to Semantic Transition Calculus

Spatial state changes are semantic transitions.

Examples:

```text
state creation
state update
state movement
state refinement
state coarsening
state replication
state deletion
```

The Semantic Transition Calculus SHOULD provide the formal transition semantics.

This document defines the state objects and invariants upon which those transitions operate.

---

# 77. Relationship to EGS

The Executable Graph Server (EGS) may manifest spatial state providers.

From the SCR graph perspective:

```text
State
Partition
Provider
Function
Execution
Message
```

are semantic objects and relationships.

EGS determines how those objects are physically manifested.

A provider MUST NOT expose implementation-specific ontology as if it were SCR semantic truth.

---

# 78. Reference Architecture

A conforming implementation MAY resemble:

```text
                  Semantic Field
                        │
                        ↓
                Spatial State Model
                        │
          ┌─────────────┼─────────────┐
          │             │             │
      State ID      Spatial       Partition
                    Association    Association
          │             │             │
          └─────────────┼─────────────┘
                        ↓
                State Representation
                        │
             ┌──────────┼──────────┐
             │          │          │
          OpenVDB     Tensor      Custom
             │          │          │
             └──────────┼──────────┘
                        ↓
                   Materialisation
                        │
             ┌──────────┼──────────┐
             │          │          │
            CPU        GPU      Storage
             │          │          │
             └──────────┼──────────┘
                        ↓
                  Execution Space
```

This architecture is illustrative rather than prescriptive.

---

# 79. Design Principle

The central design principle of the Spatial State Model is:

> **Semantic state describes what exists; spatial semantics describe where it is associated; partitioning describes where computation is organised; providers describe how the state is represented; execution resources describe where computation physically occurs.**

These layers MUST remain separable.

---

# 80. Summary

SCR Spatial State provides the semantic bridge between spatial structure and executable computation.

It establishes that:

```text
State
    is not
Representation

Representation
    is not
Residency

Residency
    is not
Partition

Partition
    is not
Coordinate

Coordinate
    is not
Execution Resource
```

Instead:

```text
                 Semantic State
                      │
          ┌───────────┼───────────┐
          ↓           ↓           ↓
       Spatial     Partition   Temporal
      Association  Association Validity
          │           │
          ↓           ↓
    Representation  Locality
          │           │
          ↓           ↓
     Materialisation Execution Mapping
          │           │
          └──────┬────┘
                 ↓
          Physical Providers
```

The resulting model allows SCR to treat spatial computation as a first-class semantic domain while remaining independent of H3, OpenVDB, GPUs, CPUs, distributed storage, or any other particular implementation.

**Core invariant:**

$$
\boxed{
Semantic\ State
\neq
Representation
\neq
Residency
\neq
Partition
\neq
Coordinate
\neq
Execution
}
$$

**Core principle:**

> **Spatial state is semantic information associated with spatial structure. Its representation, materialisation, residency, partitioning, and execution are manifestations of that state, not definitions of what the state means.**
