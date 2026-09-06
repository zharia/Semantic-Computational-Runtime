---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-GEOMETRY
name: Geometry

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-DATA

authority: SCR
domain: semantic-library
---

# SCR Geometry

## 1. Definition

**Geometry** is the semantic computational domain concerned with spatial form, position, extent, measurement, geometric relationships, and transformations of spatial structures.

Geometry defines what spatial structures mean independently of their representation, storage format, rendering system, numerical library, coordinate array, mesh format, or execution substrate.

Geometry encompasses both abstract and concrete spatial structures.

Examples include:

* points;
* positions;
* vectors;
* directions;
* curves;
* surfaces;
* solids;
* volumes;
* regions;
* shapes;
* boundaries;
* coordinate systems;
* transformations;
* distances;
* angles;
* intersections;
* containment;
* proximity;
* geometric constraints;
* spatial measurements;
* geometric constructions.

The fundamental distinction is:

```text
Geometry ≠ Mesh
Geometry ≠ Polygon File
Geometry ≠ Vertex Buffer
Geometry ≠ CAD Format
Geometry ≠ Renderable Object
Geometry ≠ Coordinate Array
```

These may be representations or implementations of geometric semantics.

---

# 2. Semantic Principle

The central principle of Geometry is:

> **Geometry describes spatial form and spatial relationships independently of how that form is represented or executed.**

A geometric object therefore has semantic identity beyond its representation.

For example:

```text
Circle
 ├── analytic representation
 ├── polygonal approximation
 ├── spline representation
 ├── implicit representation
 ├── mesh representation
 └── GPU representation
```

These may represent the same geometric object under an appropriate equivalence contract.

---

# 3. Scope

The Geometry domain encompasses:

* points;
* positions;
* vectors;
* directions;
* coordinates;
* coordinate systems;
* frames;
* distances;
* angles;
* curves;
* surfaces;
* solids;
* volumes;
* regions;
* boundaries;
* shapes;
* primitives;
* composite geometries;
* geometric collections;
* transformations;
* projections;
* intersections;
* unions;
* differences;
* containment;
* adjacency;
* proximity;
* measurements;
* predicates;
* constraints;
* tessellation;
* approximation;
* interpolation;
* parameterisation;
* implicit geometry;
* explicit geometry;
* procedural geometry;
* constructive geometry;
* geometric topology interfaces;
* spatial indexing;
* geometric queries;
* geometric streams;
* geometric deltas;
* geometric provenance.

---

# 4. Semantic Model

A geometric object may be described conceptually as:

```text
Geometry
├── Spatial Domain
├── Dimension
├── Coordinate Semantics
├── Metric Semantics
├── Shape / Form
├── Boundary
├── Reference Frame
├── Constraints
└── Provenance
```

The exact mathematical representation is not normative.

A geometry MAY be represented through:

* analytic equations;
* parametric functions;
* implicit functions;
* point sets;
* curves;
* polygons;
* meshes;
* voxels;
* signed distance fields;
* constructive solid geometry;
* procedural generators;
* splines;
* sampled representations.

The representation MUST NOT silently redefine the semantic geometry.

---

# 5. Spatial Dimension

Geometry MAY exist in different dimensions.

Examples include:

```text
0D → Point
1D → Curve
2D → Surface / Region
3D → Solid / Volume
nD → Higher-dimensional structure
```

Dimension is semantic information.

A 2D representation embedded in 3D space is not necessarily a 3D geometric object.

---

# 6. Points and Positions

A point represents a spatial location without necessarily possessing extent.

A position represents the location of an entity relative to a specified spatial reference.

Points MAY be represented using:

* Cartesian coordinates;
* geographic coordinates;
* local coordinates;
* parametric coordinates;
* manifold coordinates;
* graph-associated positions.

Coordinates are representations of position.

They are not themselves the semantic identity of the position.

---

# 7. Vectors and Directions

A vector represents a directed spatial quantity.

Vectors may express:

* displacement;
* direction;
* velocity;
* force;
* orientation-related quantities;
* geometric derivatives.

A direction represents orientation independent of magnitude where applicable.

Geometry MUST distinguish vectors from points.

```text
Point + Vector → Point
```

does not imply:

```text
Point = Vector
```

---

# 8. Coordinate Systems

A geometry MAY be associated with a coordinate reference system.

Examples include:

* Cartesian;
* polar;
* cylindrical;
* spherical;
* geographic;
* projected;
* local;
* body-relative;
* world-relative;
* manifold coordinates.

Coordinate reference systems SHOULD use established OGC/EPSG standards where applicable.

Coordinate transformation MUST be represented as a semantic transformation.

---

# 9. Reference Frames

A reference frame establishes how a geometry is interpreted relative to another spatial frame.

Examples:

```text
World Frame
    ↓
Region Frame
    ↓
Object Frame
    ↓
Component Frame
```

Reference-frame transformations may involve:

* translation;
* rotation;
* scaling;
* reflection;
* affine transformation;
* projective transformation;
* nonlinear transformation.

Reference frames MUST remain distinct from physical memory layouts or rendering coordinate conventions.

---

# 10. Curves

A curve represents a one-dimensional geometric structure.

Curves MAY be:

* parametric;
* implicit;
* explicit;
* piecewise;
* spline-based;
* procedural;
* sampled;
* approximate.

Examples include:

* lines;
* line segments;
* arcs;
* Bézier curves;
* splines;
* trajectories;
* paths.

A curve MAY serve as:

* geometry;
* a boundary;
* a trajectory;
* a path;
* a constraint;
* an input to morphology.

---

# 11. Surfaces

A surface represents a two-dimensional geometric structure embedded in an appropriate spatial space.

Surfaces MAY be:

* planar;
* parametric;
* implicit;
* spline-based;
* triangulated;
* procedural;
* sampled.

Examples include:

* terrain;
* membranes;
* object surfaces;
* mathematical manifolds;
* boundaries.

A surface representation MUST preserve its declared geometric semantics.

---

# 12. Solids and Volumes

A solid represents a bounded three-dimensional region or volumetric geometric structure.

Volume MAY be a geometric measurement or an attribute of a solid.

A volumetric geometry may be represented through:

* boundary representations;
* implicit functions;
* voxelisation;
* signed distance fields;
* constructive geometry;
* volumetric samples.

The representation does not define the semantic solid.

---

# 13. Regions

A geometric region represents a spatially bounded or semantically defined portion of a geometric domain.

Regions MAY be:

* open;
* closed;
* bounded;
* unbounded;
* disconnected;
* nested;
* overlapping.

Regions are important for:

* fields;
* simulation;
* spatial queries;
* rendering;
* morphology;
* partitioning;
* agent environments.

---

# 14. Boundaries

A boundary describes the geometric separation between a region and its exterior or between distinct geometric domains.

Boundary semantics may be:

* closed;
* open;
* manifold;
* non-manifold;
* periodic;
* constrained;
* dynamic.

Boundary semantics are distinct from the representation of the boundary.

---

# 15. Geometric Primitives

SCR MAY provide semantic primitives such as:

* point;
* line;
* ray;
* segment;
* circle;
* sphere;
* plane;
* box;
* polygon;
* polyline;
* cylinder;
* cone;
* torus;
* simplex.

These are semantic primitives.

Their concrete representation is implementation-defined.

---

# 16. Composite Geometry

Geometries MAY be composed.

```text
Geometry A
     +
Geometry B
     ↓
Composite Geometry
```

Composition MAY produce:

* collections;
* unions;
* assemblies;
* hierarchical objects;
* constructive geometry;
* compound spatial structures.

Composite geometry MUST preserve the identity and relationship of constituent structures where semantically required.

---

# 17. Constructive Geometry

Geometry MAY be generated through operations such as:

```text
Union
Intersection
Difference
Complement
Transform
Extrude
Revolve
Offset
Sweep
```

Constructive operations are semantic transformations.

For example:

```text
A ∪ B
A ∩ B
A \ B
```

are geometric meanings, not merely API calls.

---

# 18. Geometric Predicates

Geometry supports semantic predicates including:

* equals;
* intersects;
* contains;
* within;
* overlaps;
* touches;
* disjoint;
* crosses;
* adjacent;
* near.

Predicates MUST have explicit semantic definitions.

Approximate geometric predicates MUST declare their tolerance or approximation contract.

---

# 19. Distance and Measurement

Geometry MAY define measurements including:

* distance;
* length;
* area;
* volume;
* angle;
* curvature;
* diameter;
* perimeter;
* centroid;
* surface area.

Measurements MUST carry appropriate units and semantic context.

UCUM SHOULD be used for units where applicable.

A numerical value without its associated measurement semantics is not sufficient to define a geometric quantity.

---

# 20. Metric Semantics

Geometry MAY operate over metric spaces.

A metric determines how spatial separation is measured.

Different geometries MAY use different metrics.

For example:

```text
Euclidean
Manhattan
Geodesic
Network
Projective
Application-specific
```

Metric semantics MUST be explicit where they affect computation.

Changing the metric MAY change geometric meaning.

---

# 21. Geodesic Geometry

For geometries defined on curved or constrained spaces, shortest paths and distances MAY be geodesic rather than Euclidean.

This is particularly relevant to:

* geographic environments;
* manifolds;
* terrain;
* planetary surfaces;
* constrained navigation;
* spatial simulation.

Geometry MUST NOT assume Euclidean space unless explicitly specified.

---

# 22. Transformations

A geometric transformation maps one geometry into another.

```text
Geometry₁
    ↓
Transformation
    ↓
Geometry₂
```

Transformations may include:

* translation;
* rotation;
* scaling;
* reflection;
* affine transformation;
* projection;
* deformation;
* warping;
* coordinate transformation;
* dimensional transformation.

Transformations MUST preserve required semantic invariants.

---

# 23. Deformation

A deformation changes geometric form while preserving or intentionally changing specified properties.

Examples:

```text
Rigid transformation
Elastic deformation
Procedural deformation
Field-driven deformation
Physics-driven deformation
Morphological deformation
```

A deformation MUST declare which properties it preserves.

---

# 24. Geometry and Fields

Fields and Geometry have a bidirectional relationship.

A field may be defined over geometry:

```text
Geometry
    ↓
Field Domain
    ↓
Field
```

A field may also generate geometry:

```text
Field
  ↓
Iso-value
  ↓
Surface
```

or:

```text
Density Field
     ↓
Threshold
     ↓
Volume
```

or:

```text
Vector Field
     ↓
Streamline
     ↓
Curve Geometry
```

Thus:

> **Geometry provides spatial form; Fields provide distributed information over spatial or abstract domains.**

Neither domain subsumes the other.

---

# 25. Geometry and Graphs

Graphs represent relationships.

Geometry represents spatial form.

They may be combined:

```text
Graph
 ├── Node → Position
 └── Edge → Geometric Path
```

or:

```text
Geometry
    ↓
Spatial Adjacency
    ↓
Graph
```

This allows the same semantic environment to support:

* navigation;
* spatial networks;
* routing;
* simulation;
* rendering;
* geometric analysis.

A graph derived from geometry does not become identical to the geometry.

---

# 26. Geometry and Topology

Geometry and topology are strongly related but distinct.

Geometry captures properties involving:

* distance;
* angle;
* measurement;
* metric;
* shape;
* coordinates.

Topology captures properties such as:

* connectivity;
* continuity;
* adjacency;
* neighbourhood;
* holes;
* invariant structure under permitted transformations.

Therefore:

```text
Geometry
   ↕
Topology
```

must be treated as complementary semantic domains.

A geometric transformation MAY preserve topology while changing metric properties.

---

# 27. Geometry and Morphology

Morphology concerns structural form as a semantic object.

Geometry provides one of the principal representations and constraints through which morphology can manifest.

For example:

```text
Pattern
  ↓
Morphological Structure
  ↓
Geometric Form
```

and:

```text
Geometric Form
  ↓
Structural Analysis
  ↓
Morphological Pattern
```

Geometry therefore participates in the bidirectional relationship between pattern and morphology without defining morphology itself.

---

# 28. Geometry and Physics

Physics may impose geometric constraints such as:

* collision;
* contact;
* position;
* trajectory;
* boundary;
* volume;
* deformation;
* spatial conservation.

Geometry provides spatial structure.

Physics provides laws and constraints governing physical behaviour.

---

# 29. Geometry and Dynamics

Geometry may itself evolve:

```text
Gₜ
 ↓
Dynamics
 ↓
Gₜ₊₁
```

Examples include:

* moving objects;
* deforming surfaces;
* growing structures;
* fluid boundaries;
* evolving terrain;
* biological morphology.

Geometric state changes SHOULD be represented as semantic transformations or deltas.

---

# 30. Geometry and Agents

Agents may possess or interact with geometry representing:

* body shape;
* position;
* orientation;
* collision boundary;
* sensor volume;
* navigation space;
* interaction region.

Agent geometry MUST remain distinct from agent semantics.

An agent is not merely its geometry.

---

# 31. Geometry and Rendering

Rendering consumes or transforms geometric semantics into a perceptual representation.

```text
Semantic Geometry
       ↓
Render Geometry
       ↓
Render Commands
       ↓
Renderer
```

Rendering MUST NOT define the semantic geometry.

A mesh used by a renderer is one possible representation of geometric meaning.

---

# 32. Geometric Approximation

A geometry MAY be approximated.

Examples:

```text
Analytic Surface
      ↓
Tessellation
      ↓
Triangle Mesh
```

or:

```text
Curve
 ↓
Polyline Approximation
```

Approximation MUST specify relevant error bounds or equivalence criteria where semantic correctness depends upon them.

A lower-resolution approximation MUST NOT automatically be treated as identical to the source geometry.

---

# 33. Tessellation

Tessellation transforms continuous or higher-level geometry into a discrete representation.

```text
Geometry
   ↓
Tessellation
   ↓
Discrete Geometry
```

Tessellation parameters MAY include:

* resolution;
* tolerance;
* topology preservation;
* quality;
* curvature sensitivity;
* adaptive subdivision.

Tessellation is a representation transformation, not necessarily a semantic transformation.

---

# 34. Spatial Indexing

Geometry MAY support spatial indexing for efficient queries.

Indexes may support:

* containment;
* intersection;
* nearest-neighbour;
* range queries;
* collision queries;
* spatial joins.

Indexes are execution aids.

They MUST NOT define geometric semantics.

---

# 35. Geometric Queries

Queries MAY operate over:

* position;
* proximity;
* intersection;
* containment;
* spatial relationships;
* geometric properties;
* regions;
* paths.

A query result MAY be:

* a geometry;
* a region;
* a set;
* a relationship;
* a measurement;
* a graph;
* a field;
* an event.

---

# 36. Streaming Geometry

Geometry MAY evolve through streams.

```text
Geometry State
     ↓
Geometric Delta
     ↓
Stream
     ↓
New Geometry State
```

Streaming geometry may represent:

* moving objects;
* sensor geometry;
* dynamic environments;
* real-time simulation;
* procedural generation;
* rendering updates.

Transport remains independent of geometry semantics.

---

# 37. Geometric Deltas

A geometric delta describes a semantic change to geometric state.

Examples include:

* object translation;
* vertex changes;
* topology changes;
* boundary changes;
* shape deformation;
* region creation;
* region deletion.

Deltas MAY support incremental computation and rendering.

---

# 38. Provenance

Geometric provenance SHOULD preserve:

* source geometry;
* generating transformation;
* coordinate reference;
* approximation;
* tessellation;
* measurement;
* observation;
* procedural generator;
* responsible operation.

Derived geometry SHOULD retain lineage where required.

---

# 39. Uncertainty

Geometry MAY contain uncertainty relating to:

* measured position;
* boundary location;
* sensor resolution;
* reconstruction;
* approximation;
* coordinate transformation.

Uncertainty MUST remain distinct from geometric absence or undefinedness.

---

# 40. Semantic Hypergraph Integration

Geometry is represented as a first-class semantic object in the SCR Semantic Hypergraph.

Examples:

```text
Geometry
 ├── LOCATED_IN → SpatialRegion
 ├── USES → CoordinateSystem
 ├── HAS_BOUNDARY → Geometry
 ├── DERIVED_FROM → Field
 ├── CONSTRAINS → Agent
 ├── REPRESENTS → Morphology
 ├── TRANSFORMED_BY → Transformation
 ├── INTERSECTS → Geometry
 └── RENDERED_BY → Rendering
```

Higher-order relationships MAY be represented as hyperedges.

---

# 41. Representation Independence

Possible geometric representations include:

* analytic expressions;
* coordinate sequences;
* polygons;
* meshes;
* point clouds;
* voxels;
* signed distance fields;
* implicit functions;
* procedural descriptions;
* CAD representations;
* GPU buffers.

No representation is intrinsically authoritative.

A representation MAY be selected based upon:

* precision;
* performance;
* memory;
* interoperability;
* hardware;
* rendering;
* simulation requirements.

---

# 42. Provider Independence

Geometry MAY be implemented through:

* Rust;
* C++;
* Python;
* computational geometry libraries;
* CAD kernels;
* GPU kernels;
* SIMD implementations;
* spatial databases;
* external geometry engines.

Providers implement geometric semantics.

They do not define them.

Provider substitution requires an appropriate semantic equivalence contract.

---

# 43. Capabilities

Geometry MAY expose capabilities including:

* `Transformable`
* `Measurable`
* `Queryable`
* `Intersectable`
* `Containable`
* `Composable`
* `Tessellatable`
* `Interpolatable`
* `Deformable`
* `Renderable`
* `Spatial`
* `Topological`
* `Temporal`
* `Streamable`
* `Incremental`
* `Parallelizable`
* `Distributable`
* `Procedural`

Capabilities describe semantic or computational properties.

---

# 44. Semantic Equivalence

Two geometric representations MAY be semantically equivalent when they preserve the required:

* shape;
* position;
* dimension;
* topology;
* coordinate semantics;
* metric semantics;
* boundaries;
* constraints;
* precision;
* approximation bounds.

Numerical similarity alone is insufficient to establish geometric equivalence.

---

# 45. Performance Semantics

Geometric computation MAY expose:

* dimensionality;
* complexity;
* resolution;
* representation size;
* spatial locality;
* tessellation density;
* query complexity;
* parallelism;
* GPU suitability;
* update frequency.

These properties MAY guide runtime execution.

They MUST NOT redefine geometric meaning.

---

# 46. MLIR Relationship

Geometry MAY be represented and transformed through MLIR.

MLIR may provide:

* semantic operation representation;
* transformation;
* optimisation;
* lowering;
* hardware mapping;
* specialised execution.

MLIR does not define geometry semantics.

```text
Geometry Semantics
       ↓
Semantic Operations
       ↓
MLIR
       ↓
Lowering
       ↓
Execution
```

---

# 47. Runtime Semantics

The SCR runtime MAY:

1. resolve geometric identities;
2. inspect geometric capabilities;
3. determine representation requirements;
4. select providers;
5. select representations;
6. compile or specialise geometric operations;
7. execute geometric computation;
8. generate geometric state;
9. generate deltas or streams;
10. record provenance;
11. optimise execution;
12. reassess execution strategy.

Runtime decisions MUST preserve semantic contracts.

---

# 48. Standards and Interoperability

SCR SHOULD reuse established standards where applicable.

Potential standards include:

* OGC geometry standards;
* EPSG coordinate reference identifiers;
* WKT;
* WKB;
* GeoJSON;
* GML;
* glTF for suitable 3D representation;
* URI/IRI for identity;
* RFC 3339 / ISO 8601 for temporal semantics;
* UCUM for measurements and units.

These provide interoperability.

They do not become the semantic authority of SCR Geometry.

---

# 49. Expected Subdomains

The following structure is illustrative:

```text
geometry/
├── geometry-core
├── point
├── position
├── vector
├── direction
├── coordinate
├── reference-frame
├── metric
├── distance
├── angle
├── curve
├── surface
├── solid
├── volume
├── region
├── boundary
├── primitive
├── composite
├── constructive
├── predicate
├── measurement
├── transformation
├── deformation
├── projection
├── parameterisation
├── interpolation
├── approximation
├── tessellation
├── spatial-index
├── query
├── stream
├── delta
├── provenance
├── uncertainty
├── equivalence
├── capability
└── provider
```

This is a semantic classification and does not prescribe a filesystem hierarchy.

---

# 50. Architectural Rules

### GEOMETRY-RULE-001 — Semantic Primacy

Geometric meaning is normative.

### GEOMETRY-RULE-002 — Representation Independence

A particular geometric representation MUST NOT define geometry semantics.

### GEOMETRY-RULE-003 — Coordinate Explicitness

Coordinate reference semantics MUST be explicit where relevant.

### GEOMETRY-RULE-004 — Metric Explicitness

Metric assumptions MUST be explicit where they affect computation.

### GEOMETRY-RULE-005 — Dimensional Integrity

Geometric dimension MUST remain semantically explicit.

### GEOMETRY-RULE-006 — Transformation Contracts

Geometric transformations MUST declare their semantic effects.

### GEOMETRY-RULE-007 — Approximation Transparency

Geometric approximations MUST expose relevant error or equivalence contracts.

### GEOMETRY-RULE-008 — Topological Awareness

Operations affecting topology MUST explicitly declare their topological effects.

### GEOMETRY-RULE-009 — Provenance Preservation

Derived geometry SHOULD retain required provenance.

### GEOMETRY-RULE-010 — Delta Semantics

Geometric deltas MUST remain distinct from physical memory or rendering updates.

### GEOMETRY-RULE-011 — Provider Independence

External geometry libraries are implementations, not semantic authorities.

### GEOMETRY-RULE-012 — Rendering Separation

Renderable geometry MUST remain distinct from semantic geometry.

### GEOMETRY-RULE-013 — Field Separation

Fields and geometry MUST remain distinct even where one generates the other.

### GEOMETRY-RULE-014 — Hardware Independence

Hardware representations MUST NOT define geometric semantics.

---

# 51. Invariants

### GEOMETRY-INV-001 — Identity

Geometric entities MUST have stable semantic identity where persistence is required.

### GEOMETRY-INV-002 — Dimensional Integrity

Geometric dimension MUST be preserved unless explicitly transformed.

### GEOMETRY-INV-003 — Coordinate Integrity

Coordinate transformations MUST preserve declared reference semantics.

### GEOMETRY-INV-004 — Metric Integrity

Metric assumptions MUST remain explicit and consistent.

### GEOMETRY-INV-005 — Boundary Integrity

Declared boundaries MUST remain semantically valid.

### GEOMETRY-INV-006 — Transformation Integrity

Geometric transformations MUST satisfy their declared contracts.

### GEOMETRY-INV-007 — Topological Integrity

Operations claiming topology preservation MUST preserve relevant topology.

### GEOMETRY-INV-008 — Approximation Integrity

Approximations MUST remain within their declared error bounds.

### GEOMETRY-INV-009 — Composition Integrity

Composite geometry MUST preserve required constituent relationships.

### GEOMETRY-INV-010 — Measurement Integrity

Measurements MUST preserve units and semantic context.

### GEOMETRY-INV-011 — Provenance Integrity

Derived geometry MUST retain required provenance.

### GEOMETRY-INV-012 — Delta Integrity

A geometric delta MUST produce a valid geometric state transition.

### GEOMETRY-INV-013 — Representation Independence

Geometric meaning MUST NOT depend on a physical representation.

### GEOMETRY-INV-014 — Provider Independence

Provider replacement MUST preserve the required semantic contract.

### GEOMETRY-INV-015 — Rendering Independence

Rendering representations MUST NOT redefine semantic geometry.

### GEOMETRY-INV-016 — Spatial Reference Integrity

Spatial reference transformations MUST preserve declared spatial meaning.

### GEOMETRY-INV-017 — No Storage Authority

Storage format MUST NOT define geometric semantics.

### GEOMETRY-INV-018 — No Hardware Authority

Hardware representation MUST NOT define geometric semantics.

---

# 52. Domain Relationships

| Domain       | Relationship      | Meaning                                               |
| ------------ | ----------------- | ----------------------------------------------------- |
| Core         | `SPECIALIZES`     | Geometry specialises foundational spatial structures  |
| Data         | `REFINES`         | Geometry provides structured spatial information      |
| Mathematics  | `USES`            | Mathematical structures define geometric operations   |
| Fields       | `INTERACTS_WITH`  | Fields may be defined over or generate geometry       |
| Graphs       | `INTERACTS_WITH`  | Graphs may encode geometric relationships             |
| Topology     | `INTERACTS_WITH`  | Geometry and topology constrain one another           |
| Morphology   | `INTERACTS_WITH`  | Geometry provides spatial manifestation of morphology |
| Physics      | `SUPPORTS`        | Physics imposes spatial and geometric constraints     |
| Dynamics     | `PARTICIPATES_IN` | Geometry may evolve dynamically                       |
| Agents       | `INTERACTS_WITH`  | Agents possess and interact with geometry             |
| Simulation   | `PARTICIPATES_IN` | Simulations evolve geometric state                    |
| Perception   | `PRODUCES`        | Geometric structures may support perception           |
| Rendering    | `CONSUMED_BY`     | Rendering consumes geometric representations          |
| Stream       | `USES`            | Geometry may evolve through streams                   |
| Messaging    | `TRANSPORTS`      | Messaging may transport geometric events/deltas       |
| Optimisation | `TRANSFORMS`      | Geometric structures may be optimised                 |

---

# 53. Testing Requirements

Geometry implementations MUST be tested at multiple semantic levels.

## Specification Tests

Verify:

* dimensional semantics;
* coordinate semantics;
* metric semantics;
* geometric identity;
* transformation contracts;
* topology-preservation contracts;
* approximation contracts.

## Unit Tests

Verify:

* primitives;
* transformations;
* predicates;
* measurements;
* intersections;
* containment;
* composition;
* tessellation.

## Domain Tests

Verify:

* points;
* curves;
* surfaces;
* solids;
* regions;
* composite geometry;
* procedural geometry.

## Composition Tests

Verify interaction with:

* fields;
* graphs;
* topology;
* morphology;
* physics;
* dynamics;
* agents;
* rendering.

## Representation Tests

Verify semantic equivalence across different geometric representations.

## Runtime Tests

Verify:

* provider selection;
* representation selection;
* geometric execution;
* incremental updates;
* streaming;
* provenance.

---

# 54. Validation Requirements

A geometry implementation is semantically valid only if:

1. dimensional semantics are defined;
2. coordinate semantics are defined where required;
3. metric semantics are defined where required;
4. spatial boundaries are represented where required;
5. geometric transformations satisfy their contracts;
6. topology-affecting operations declare their effects;
7. approximations satisfy declared bounds;
8. measurements preserve units;
9. provenance is retained where required;
10. deltas produce valid state transitions;
11. representations do not redefine geometric meaning;
12. provider substitutions preserve semantic equivalence.

---

# 55. Completeness Criteria

The Geometry domain is considered semantically complete for an intended capability when:

* geometric primitives are expressible;
* composite geometry is expressible;
* coordinate systems are expressible;
* reference frames are expressible;
* metric semantics are expressible;
* measurements are expressible;
* geometric predicates are expressible;
* transformations are expressible;
* deformation is expressible where required;
* approximation is expressible;
* topology-affecting operations are explicit;
* geometric state evolution is expressible;
* deltas and streams are expressible;
* provenance is expressible;
* interoperability projections are possible;
* semantic loss during projection is detectable;
* composition with Fields, Graphs, Topology, Morphology, Physics, Dynamics, Agents, and Rendering is possible.

---

# 56. Open Semantic Questions

The following remain intentionally open:

1. Formal geometric object algebra.
2. Formal geometry equivalence.
3. Exact tolerance semantics.
4. Higher-dimensional geometry.
5. Non-Euclidean geometry.
6. Geometry over arbitrary manifolds.
7. Formal geometry/topology correspondence.
8. Dynamic geometry semantics.
9. Geometry/field duality.
10. Procedural geometry semantics.
11. Geometry/morphology transformation algebra.
12. Distributed geometric computation.
13. Incremental geometric computation.
14. Formal spatial-index contracts.
15. Geometric uncertainty propagation.
16. Differentiable geometry.
17. Geometry-aware MLIR representation.
18. Hardware-specific geometric optimisation.
19. Exact semantics of geometric compression.
20. Cross-domain geometric equivalence.

These MUST NOT be prematurely resolved by the requirements of any particular geometry engine or file format.

---

# 57. Definition History

### Version 0.1.0

Initial normative semantic definition.

Establishes:

* geometry as semantic spatial structure;
* points, vectors, curves, surfaces, solids, and regions;
* coordinate and reference-frame semantics;
* metrics and measurements;
* transformations and deformation;
* constructive geometry;
* geometric predicates;
* approximation and tessellation;
* fields/graphs/topology/morphology relationships;
* dynamic and streaming geometry;
* provenance and uncertainty;
* representation and provider independence.

---

# 58. Definition Authority

This document defines the normative semantic meaning of the SCR Geometry domain.

Implementations, geometry engines, storage formats, serialization mechanisms, compiler representations, rendering systems, hardware targets, and external libraries MUST conform to this definition where they claim to implement SCR Geometry semantics.

---

# 59. Definition Principle

> **Geometry defines spatial form, position, measurement, and geometric relationships as semantic computational objects, independently of the representation, algorithm, renderer, storage mechanism, or hardware used to realize them.**

The fundamental distinction is:

```text
Spatial Meaning
      ↓
Geometric Semantics
      ↓
Representation
      ↓
Implementation
      ↓
Execution
      ↓
Physical Manifestation
```

The representation may change.

The implementation may change.

The execution substrate may change.

The geometric semantic identity MUST remain stable unless an explicitly defined geometric transformation changes it.
