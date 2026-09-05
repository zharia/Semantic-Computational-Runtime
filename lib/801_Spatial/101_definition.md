---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-SPATIAL
name: Spatial

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-DATA

authority: SCR
domain: semantic-library
------------------------

# SCR Spatial

## Definition

Spatial is the semantic computational domain concerned with the representation, organisation, interpretation, navigation, querying, transformation, and computation of entities and information according to spatial relationships.

Spatial semantics describe **where things are, how they relate spatially, how spatial context is established, and how spatial structure participates in computation**.

Spatial is broader than Geometry.

Geometry defines spatial form, measurement, shape, and geometric relationships.

Topology defines connectivity, continuity, incidence, and structural properties.

Spatial defines the computational semantics through which entities, information, fields, environments, and processes are situated within spatial contexts and related through concepts such as position, neighbourhood, distance, direction, region, locality, proximity, containment, navigation, and spatial reference.

Spatial may operate over:

* physical space
* abstract mathematical space
* simulated space
* computational space
* geographic space
* network space
* discrete space
* continuous space
* multidimensional space
* hierarchical space
* distributed space.

Spatial semantics do not require physical embodiment.

---

# Semantic Model

A spatial context can be represented conceptually as:

```text id="9n6v6n"
S = (D, P, R, C, M, T, N, Q, X, Pᵣ)
```

where:

* `D` = spatial domain
* `P` = positions
* `R` = spatial relationships
* `C` = coordinate/reference systems
* `M` = metrics and measurements
* `T` = topology and connectivity
* `N` = neighbourhood and locality
* `Q` = spatial queries
* `X` = spatial transformations
* `Pᵣ` = provenance and reference semantics.

These are semantic concepts rather than prescribed data structures.

---

# Spatial Primacy

Spatial computation concerns the relationship between information and spatial context.

A spatially meaningful entity is therefore not merely assigned coordinates.

Its spatial semantics may include:

* position
* extent
* orientation
* reference frame
* neighbourhood
* containment
* adjacency
* accessibility
* distance
* direction
* connectivity
* locality
* scale
* resolution
* temporal validity.

Consequently:

```text id="n3x4nt"
Information
    │
    ▼
Spatial Context
    │
    ├── Position
    ├── Extent
    ├── Neighbourhood
    ├── Distance
    ├── Direction
    ├── Region
    └── Connectivity
          │
          ▼
     Spatial Computation
```

---

# Scope

SCR Spatial encompasses, but is not limited to:

* spatial domains
* positions
* locations
* coordinates
* coordinate systems
* reference frames
* orientation
* direction
* distance
* proximity
* neighbourhoods
* locality
* regions
* extents
* boundaries
* containment
* adjacency
* connectivity
* spatial topology
* spatial geometry
* spatial indexing
* spatial queries
* spatial predicates
* spatial joins
* spatial partitioning
* spatial decomposition
* spatial aggregation
* spatial interpolation
* spatial transformation
* spatial projection
* spatial navigation
* pathfinding
* routing
* geofencing
* grids
* hierarchical spatial structures
* voxels
* cells
* spatial meshes
* spatial graphs
* spatial fields
* spatial distributions
* spatial density
* spatial gradients
* spatial reference systems
* local coordinate systems
* global coordinate systems
* geospatial computation
* simulated worlds
* computational spaces
* spatial environments
* spatial streams
* spatial deltas
* spatial state
* spatial provenance
* spatial uncertainty.

---

# 1. Spatial Domain

A spatial domain defines the space in which spatial entities, relationships, and computations have meaning.

A spatial domain may be:

* one-dimensional
* two-dimensional
* three-dimensional
* higher-dimensional
* continuous
* discrete
* bounded
* unbounded
* finite
* infinite
* Euclidean
* non-Euclidean
* geographic
* abstract
* simulated
* hierarchical
* network-based.

The dimensionality and structural properties of a spatial domain MUST be explicit.

---

# 2. Position

Position describes the spatial location of an entity relative to a declared spatial reference.

Position MUST NOT be interpreted without its reference system.

The same coordinate tuple may represent different spatial positions under different coordinate systems.

Therefore:

```text id="h3svxw"
Coordinate Value
      +
Reference System
      ↓
Spatial Position
```

---

# 3. Coordinates

Coordinates provide values used to identify positions within a declared spatial reference system.

Coordinate semantics may include:

* dimensionality
* axis definitions
* units
* orientation
* origin
* scale
* reference frame
* coordinate epoch where applicable.

Coordinate representation MUST remain distinct from spatial position semantics.

---

# 4. Reference Frames

A reference frame establishes the semantic context in which spatial quantities are interpreted.

Reference frames may be:

* global
* local
* relative
* hierarchical
* moving
* rotating
* inertial
* non-inertial
* object-relative
* environment-relative.

Transformations between reference frames MUST preserve the declared spatial semantics.

---

# 5. Orientation and Direction

Spatial orientation describes the directional configuration of an entity relative to a reference frame.

Direction describes a spatial relation or vectorial orientation between spatial entities or positions.

Orientation and direction are related to Geometry but are also meaningful as spatial context.

---

# 6. Extent and Region

A spatial region identifies an area, volume, subset, or other bounded or unbounded portion of a spatial domain.

A region may be:

* geometric
* topological
* logical
* semantic
* administrative
* ecological
* computational
* hierarchical
* dynamic.

Spatial regions may be nested:

```text id="y5f0s2"
World
 ├── Continent
 │    ├── Country
 │    │    ├── Region
 │    │    └── Region
 │    └── Country
 └── Continent
```

Spatial containment MUST be distinguishable from mere semantic grouping.

---

# 7. Neighbourhood

A neighbourhood defines which entities or positions are considered spatially related within a declared spatial context.

Neighbourhood may be based upon:

* distance
* topology
* connectivity
* direction
* shared boundary
* grid adjacency
* graph adjacency
* visibility
* accessibility
* semantic criteria.

Neighbourhood is contextual and MUST NOT be assumed to mean simple Euclidean proximity.

---

# 8. Locality

Locality describes the degree to which computation, information, interaction, or structure is spatially concentrated.

Locality may be:

* geometric
* topological
* computational
* informational
* temporal-spatial
* memory-oriented.

Locality is particularly important for:

* parallel computation
* distributed execution
* spatial indexing
* field computation
* simulation
* rendering
* agent interaction.

---

# 9. Distance

Distance defines a spatial measurement or relation between entities, positions, or regions under a declared metric.

Metrics may be:

* Euclidean
* Manhattan
* geodesic
* graph-based
* domain-specific
* weighted
* anisotropic
* learned
* probabilistic.

A distance value MUST retain the semantics of the metric from which it was derived.

---

# 10. Proximity

Proximity describes spatial closeness according to a declared spatial relation or threshold.

Proximity may depend on:

* distance
* topology
* accessibility
* direction
* scale
* uncertainty
* temporal validity.

Proximity is not necessarily equivalent to distance.

---

# 11. Spatial Relationships

Spatial relationships describe how entities relate spatially.

Examples include:

* near
* far
* inside
* contains
* overlaps
* intersects
* adjacent
* disconnected
* above
* below
* left
* right
* north
* south
* east
* west
* aligned
* oriented toward
* accessible from
* visible from.

Spatial relationships may be first-class semantic relationships within the Semantic Hypergraph.

---

# 12. Spatial Topology

Spatial semantics may depend upon topological properties.

Spatial topology composes with SCR Topology to represent:

* connectivity
* adjacency
* incidence
* boundaries
* components
* neighbourhood
* continuity.

Spatial MUST NOT duplicate or redefine foundational topological semantics.

---

# 13. Spatial Geometry

Spatial computation may use Geometry for:

* shape
* position
* extent
* distance
* intersection
* containment
* transformation
* projection
* measurement.

Spatial provides contextual and relational semantics around those geometric objects.

The distinction is:

```text id="sjz5l3"
Geometry
  =
what spatial form and measurement mean

Spatial
  =
how entities and information are situated and related
within spatial contexts
```

---

# 14. Spatial Indexing

Spatial indexes provide computational structures for efficiently locating or querying spatial information.

Possible structures include:

* R-trees
* KD-trees
* BVHs
* quadtrees
* octrees
* grids
* hierarchical cells
* spatial hashes
* H3
* other domain-specific indexes.

Indexes are implementations of spatial query capability.

They are not semantic authorities over spatial relationships.

---

# 15. Spatial Query

Spatial queries select, relate, or transform information according to spatial predicates.

Examples include:

* entities within a region
* nearest neighbours
* entities within distance `d`
* intersecting geometries
* containing regions
* connected spatial components
* paths between locations
* entities visible from a position.

Spatial queries may compose with ISO GQL and other query mechanisms.

The query language is an interface to spatial semantics, not the spatial model itself.

---

# 16. Spatial Partitioning

Spatial domains may be partitioned into computationally or semantically meaningful regions.

Partitioning may support:

* parallel computation
* distributed execution
* spatial indexing
* simulation decomposition
* streaming
* locality optimisation
* rendering
* caching
* load balancing.

Partition boundaries MUST NOT silently alter spatial semantics.

---

# 17. Hierarchical Spatial Structures

Spatial domains may be represented hierarchically.

Examples include:

```text id="1ey7q6"
World
   ↓
Region
   ↓
Subregion
   ↓
Cell
   ↓
Local Neighbourhood
   ↓
Entity
```

Hierarchical representation may support multiple spatial scales.

Spatial identity MUST remain distinct from representation hierarchy.

---

# 18. Spatial Grids and Discrete Spaces

A continuous spatial domain may be approximated or represented through discrete structures such as:

* grids
* voxels
* cells
* tiles
* hexagonal regions
* graph vertices
* sampled points.

The discrete representation MUST NOT automatically redefine the underlying spatial semantics.

Sampling and resolution are semantic considerations.

---

# 19. Spatial Fields

Fields may be distributed over spatial domains.

Examples include:

* temperature
* pressure
* density
* illumination
* population
* resources
* probability
* information
* risk
* environmental conditions.

Spatial and Field semantics therefore compose bidirectionally:

```text id="p4od5q"
Spatial Domain
      │
      ▼
     Field
      │
      ▼
Spatially Distributed Information
      │
      ▼
Spatial Computation
```

---

# 20. Spatial Transformation

Spatial transformations alter the spatial relationship or reference context of entities.

Examples include:

* translation
* rotation
* scaling
* projection
* coordinate transformation
* deformation
* reprojection
* reference-frame transformation.

Spatial transformations MUST distinguish between:

* changing representation
* changing reference frame
* changing actual spatial state.

---

# 21. Navigation

Navigation computes or represents movement through spatial environments.

Navigation may involve:

* position
* orientation
* paths
* routes
* obstacles
* constraints
* topology
* geometry
* cost
* accessibility
* dynamic environments.

Navigation is semantic computation rather than merely a rendering or user-interface concern.

---

# 22. Pathfinding

Pathfinding identifies or constructs spatial trajectories satisfying declared constraints.

Paths may optimize:

* distance
* time
* energy
* risk
* resource consumption
* accessibility
* safety
* ecological cost
* computational cost.

Pathfinding composes with Graphs, Geometry, Topology, Optimization, Control, and Agents.

---

# 23. Geofencing

A geofence defines a spatial predicate or constraint associated with a region.

Examples include:

* enter region
* leave region
* remain within region
* avoid region
* trigger interaction within region.

Geofences may participate in:

* control
* agents
* simulation
* event generation
* stream processing
* spatial queries.

---

# 24. Spatial Uncertainty

Spatial information may be uncertain because of:

* measurement error
* sensor uncertainty
* incomplete observation
* coordinate uncertainty
* ambiguous reference frames
* probabilistic location
* approximate geometry
* uncertain boundaries.

Spatial uncertainty MUST remain distinguishable from deterministic spatial state.

---

# 25. Spatial and Temporal Coupling

Spatial state may change over time.

Examples include:

* moving entities
* changing boundaries
* evolving environments
* dynamic fields
* moving reference frames
* changing topology.

A spatial entity may therefore be represented as:

```text id="x6kq5h"
Spatial State(t)
       │
       ▼
Spatial Transition
       │
       ▼
Spatial State(t + Δt)
```

Spatial semantics compose directly with Temporal and Dynamics semantics.

---

# 26. Spatial Streams and Deltas

Spatial state may evolve through semantic operations and deltas.

Examples include:

* entity movement
* region changes
* topology changes
* spatial index updates
* environmental changes
* field updates
* navigation events.

Conceptually:

```text id="l3v3cx"
S₀
 │
 ├── Δ₁ movement
 ├── Δ₂ region change
 ├── Δ₃ environment change
 └── Δ₄ topology change
 │
 ▼
S₄
```

Spatial changes MAY be emitted as semantic streams.

---

# 27. Relationship to Agents

Agents often require spatial context for:

* perception
* movement
* interaction
* navigation
* action
* proximity
* resource access.

However, Spatial does not require Agents.

Spatial computation applies equally to non-agent systems.

---

# 28. Relationship to Ecology

Ecological systems frequently depend on:

* spatial distribution
* neighbourhood
* habitat
* resource location
* migration
* territory
* proximity
* environmental gradients.

Spatial therefore provides foundational semantics for spatial Ecology.

---

# 29. Relationship to Morphology

Morphology describes meaningful form and organisation.

Spatial describes where morphological structures exist and how they relate spatially.

Morphological structures may therefore be:

* positioned
* oriented
* distributed
* clustered
* fragmented
* connected
* nested
* transformed.

---

# 30. Relationship to Physics

Physics provides laws governing physical spatial relationships.

Spatial provides the spatial context in which physical entities and fields are situated.

Spatial MUST NOT redefine physical laws.

---

# 31. Relationship to Rendering

Rendering consumes spatial information to produce visual or other perceptual manifestations.

Rendering MUST NOT redefine spatial state merely because a particular rendering representation is convenient.

Spatial truth and rendered appearance remain distinct.

---

# 32. Relationship to Simulation

Simulation may use Spatial to construct simulated environments and spatial state.

Examples include:

* worlds
* terrain
* navigation spaces
* agent locations
* environmental fields
* spatial interactions
* spatial constraints.

Simulation realizes spatial models computationally.

It does not define their semantic meaning.

---

# 33. Semantic Hypergraph Integration

Spatial entities and relationships MUST be representable within the SCR Semantic Hypergraph.

Examples include:

```text id="8mkwm3"
Entity A
    │
    ├── located-in ─────► Region X
    ├── near ───────────► Entity B
    ├── moving-toward ──► Entity C
    └── constrained-by ─► Region Y
```

Higher-order spatial relationships MUST be representable when required.

Spatial regions MAY themselves be addressable graph regions.

---

# 34. Representation Independence

Spatial semantics MUST remain independent of:

* coordinate arrays
* meshes
* grids
* databases
* GIS systems
* spatial indexes
* files
* serialization formats
* rendering engines
* simulation engines
* memory layouts
* hardware.

A single spatial object MAY have multiple simultaneous representations.

---

# 35. Provider Independence

External spatial systems are providers or implementation mechanisms.

Examples include:

* spatial databases
* GIS libraries
* spatial-index libraries
* geometry libraries
* navigation engines
* geospatial systems
* H3 implementations
* KD-tree implementations
* R-tree implementations.

Provider implementations MUST conform to SCR spatial contracts.

They MUST NOT redefine SCR spatial semantics.

---

# 36. MLIR Representation

SCR Spatial MAY be represented through MLIR types, operations, attributes, interfaces, and transformations.

MLIR provides compilation infrastructure rather than spatial authority.

Spatial operations MAY lower through:

```text id="4j7v2j"
Spatial Semantic Operation
        ↓
Spatial IR
        ↓
Generic MLIR
        ↓
Specialized Lowering
        ↓
CPU / GPU / Distributed / Provider
```

---

# 37. Runtime Semantics

The runtime MAY:

1. identify spatial operations;
2. inspect spatial capabilities;
3. analyse spatial locality;
4. analyse reference systems;
5. select spatial algorithms;
6. select providers;
7. partition spatial workloads;
8. specialize execution;
9. execute spatial operations;
10. emit spatial state changes;
11. update provenance;
12. adapt execution according to runtime conditions.

Runtime optimisation MUST preserve spatial semantics.

---

# 38. Performance Semantics

Spatial computation may exploit:

* locality
* partitioning
* tiling
* spatial indexing
* hierarchical decomposition
* vectorization
* parallel execution
* GPU execution
* distributed execution
* caching
* incremental updates.

Optimisation MUST NOT change declared spatial meaning.

---

# 39. Determinism

Where a spatial operation is declared deterministic, equivalent inputs under equivalent spatial contexts MUST produce semantically equivalent results.

Where approximation or stochasticity is declared, that behaviour MUST remain explicit.

---

# 40. Errors and Failure Semantics

Spatial operations may fail because of:

* invalid coordinates
* incompatible reference systems
* undefined transformations
* invalid geometry
* invalid topology
* unsupported dimensions
* unavailable spatial index
* numerical failure
* provider failure
* insufficient computational resources.

Errors MUST distinguish semantic invalidity from implementation failure.

---

# 41. Standards and Interoperability

SCR Spatial SHOULD reuse established standards wherever applicable.

Relevant standards include:

* URI / IRI
* ISO 8601
* RFC 3339
* UCUM
* OGC standards
* EPSG coordinate reference systems
* GeoJSON
* WKT
* WKB
* H3
* established geospatial and spatial-indexing standards.

Standards provide interoperability.

SCR remains authoritative over SCR Spatial semantics.

---

# Expected Subdomains

```text id="w1nqv5"
spatial/
├── spatial-core
├── domain
├── position
├── location
├── coordinate
├── coordinates
├── coordinate-system
├── reference-frame
├── orientation
├── direction
├── distance
├── metric
├── proximity
├── neighbourhood
├── locality
├── region
├── extent
├── boundary
├── containment
├── adjacency
├── connectivity
├── topology
├── geometry
├── index
├── spatial-index
├── partitioning
├── hierarchy
├── grid
├── voxel
├── cell
├── tile
├── field
├── distribution
├── density
├── gradient
├── query
├── predicate
├── join
├── transformation
├── projection
├── navigation
├── pathfinding
├── routing
├── geofencing
├── visibility
├── accessibility
├── uncertainty
├── temporal
├── dynamic
├── stream
├── delta
├── provenance
├── capability
├── equivalence
└── provider
```

---

# Invariants

### SPATIAL-INV-001 — Semantic Primacy

Spatial semantics are normative and MUST NOT be silently redefined by implementation.

### SPATIAL-INV-002 — Reference Explicitness

Coordinates MUST be interpreted within an explicit or inferable declared spatial reference context.

### SPATIAL-INV-003 — Dimensionality

Spatial dimensionality MUST be semantically explicit.

### SPATIAL-INV-004 — Position Distinction

Position MUST remain distinguishable from its coordinate representation.

### SPATIAL-INV-005 — Relationship Integrity

Spatial relationships MUST preserve their declared semantics.

### SPATIAL-INV-006 — Metric Integrity

Distance and proximity semantics MUST retain the metric or relation from which they derive.

### SPATIAL-INV-007 — Topology Independence

Spatial semantics MUST NOT redefine foundational topology.

### SPATIAL-INV-008 — Geometry Independence

Spatial semantics MUST NOT redefine foundational geometry.

### SPATIAL-INV-009 — Locality Preservation

Optimisations exploiting spatial locality MUST preserve spatial semantics.

### SPATIAL-INV-010 — Scale Awareness

Spatial computations MAY operate across multiple spatial scales.

### SPATIAL-INV-011 — Temporal Explicitness

Dynamic spatial state MUST remain distinguishable from static spatial representation.

### SPATIAL-INV-012 — Transformation Integrity

Spatial transformations MUST explicitly identify their source and target spatial contexts.

### SPATIAL-INV-013 — Representation Independence

No spatial representation is inherently authoritative.

### SPATIAL-INV-014 — Index Independence

A spatial index is an implementation mechanism, not spatial truth.

### SPATIAL-INV-015 — Uncertainty Preservation

Declared spatial uncertainty MUST NOT be silently discarded.

### SPATIAL-INV-016 — Provenance Preservation

Spatial transformations and derived results SHOULD preserve relevant provenance.

### SPATIAL-INV-017 — Provider Independence

External spatial providers MUST NOT become semantic authorities.

### SPATIAL-INV-018 — Semantic Equivalence

Representation equality MUST NOT be treated as spatial semantic equivalence.

---

# Architectural Rules

1. Spatial MUST compose with Core.
2. Spatial MUST compose with Data.
3. Spatial MUST compose with Mathematics.
4. Spatial MUST compose with Graphs.
5. Spatial MUST compose with Fields.
6. Spatial MUST compose with Geometry.
7. Spatial MUST compose with Topology.
8. Spatial MUST compose with Morphology.
9. Spatial MUST compose with Physics.
10. Spatial MUST compose with Dynamics.
11. Spatial MUST compose with Simulation.
12. Spatial MUST compose with Agents.
13. Spatial MUST compose with Perception.
14. Spatial MUST compose with Control.
15. Spatial MUST compose with Optimization.
16. Spatial MUST compose with Learning.
17. Spatial MUST compose with Adaptation.
18. Spatial MUST compose with Evolution.
19. Spatial MUST compose with Ecology.
20. Spatial MUST support semantic regions.
21. Spatial MUST support spatial relationships.
22. Spatial MUST support spatial queries.
23. Spatial MUST support spatial transformations.
24. Spatial MUST support spatial state and deltas.
25. Spatial MUST support spatial streams.
26. Spatial MUST remain independent of storage.
27. Spatial MUST remain independent of rendering.
28. Spatial MUST remain independent of any particular spatial-index implementation.
29. Spatial MUST remain independent of any particular GIS or simulation engine.
30. Spatial semantics MUST be expressible independently of physical manifestation.

---

# Completeness Criteria

An implementation of SCR Spatial is semantically complete only when it can represent:

* spatial domains
* positions
* coordinates
* reference frames
* orientations
* directions
* regions
* extents
* boundaries
* neighbourhoods
* locality
* distance
* proximity
* spatial relationships
* spatial topology
* spatial geometry
* spatial indexes
* spatial queries
* spatial partitioning
* hierarchical spatial structures
* spatial transformations
* navigation
* pathfinding
* spatial fields
* spatial uncertainty
* dynamic spatial state
* spatial deltas
* spatial streams
* provenance
* semantic equivalence
* capability requirements.

---

# Testing Requirements

SCR Spatial implementations SHOULD include:

### Specification Tests

Tests validating conformance to this definition.

### Unit Tests

Tests for individual spatial primitives and operations.

### Domain Tests

Tests for positions, coordinates, regions, neighbourhoods, distances, relationships, transformations, and queries.

### Reference-System Tests

Tests validating coordinate and reference-frame semantics.

### Geometry Composition Tests

Tests combining Spatial with Geometry.

### Topology Composition Tests

Tests combining Spatial with Topology.

### Field Composition Tests

Tests combining Spatial with Fields.

### Graph Composition Tests

Tests combining Spatial with Graphs and the Semantic Hypergraph.

### Dynamic Tests

Tests validating spatial state changes over time.

### Stream Tests

Tests validating spatial events and deltas.

### Provider Tests

Tests validating external spatial implementations against SCR Spatial contracts.

### Performance Tests

Tests validating locality, partitioning, indexing, parallelisation, and distributed execution without semantic divergence.

---

# Open Semantic Questions

1. How should spatial reference contexts be represented in the Semantic Hypergraph?
2. How should dynamic reference frames interact with Dynamics and Physics?
3. How should spatial scale transitions be represented semantically?
4. How should uncertain positions compose with deterministic geometry?
5. How should spatial predicates compose across heterogeneous spatial domains?
6. How should network-space and geometric-space semantics be unified without conflation?
7. How should spatial locality be exposed as a runtime capability?
8. How should spatial partition boundaries interact with distributed execution?
9. How should spatial streams represent continuous movement efficiently while preserving semantic deltas?
10. How should spatial topology changes be represented alongside spatial state?
11. How should multiple simultaneous spatial reference systems be represented?
12. How should spatial semantics interact with ecological niches and environments?
13. How should spatial perception differ from spatial state estimation?
14. How should spatial queries compose with general ISO GQL semantics?
15. How should spatial equivalence be defined for approximate or discretized representations?

These questions MUST NOT be resolved implicitly by implementation.

---

# Definition History

## 0.1.0

Initial normative semantic definition.

Establishes Spatial as the semantic domain for positioning, spatial relationships, locality, regions, navigation, spatial computation, and spatial context.

---

# Definition Authority

This document is the normative semantic authority for `SCR-LIB-SPATIAL`.

Implementation details, spatial indexes, GIS systems, geometry libraries, navigation engines, serialization formats, and runtime strategies MUST conform to this definition rather than redefine it.

---

# Definition Principle

> **Spatial defines where meaningful entities and information exist, how they are situated and related within spatial contexts, and how those relationships participate in computation, independently of the representation, indexing mechanism, storage system, renderer, simulation engine, or hardware used to realize them.**
