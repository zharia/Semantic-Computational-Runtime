# Sprint 002 Record: Spatial Hierarchy & Transform Semantics

## 1. Objective

Define SCR semantic Transform (position + orientation + scale), parent/child hierarchy composition, coordinate system conventions with inter-system mappings, and spatial relationship semantics. Ground definitions in existing `lib/801_Spatial` and `lib/302_Geometry` definitions. Preserve invariant: **semantic transform ≠ representation transform**. SCR defines meaning; providers encode.

## 2. Existing SCR Library Assessment

### 2.1 Domains With Substantive Definitions

| Domain | Path | Status | Relevance |
|--------|------|--------|-----------|
| **Spatial** | `lib/801_Spatial/101_definition.md` | Operational (0.1.0) | Authoritative spatial domain definition. 1372 lines. 41 invariants (SPATIAL-INV-001–018). Defines position, orientation, distance, proximity, neighbourhood, region, containment, adjacency, connectivity, spatial relationships, coordinate systems, reference frames, spatial transformations, navigation, pathfinding, geofencing. Normative authority for all spatial semantics. |
| **Geometry Transform** | `lib/302_Geometry/Transform/101_definition.md` | Operational (0.1.0) | Affine, rigid-body, projective transformations. Grounded in mathematics. Invariants: Identity (INV-001), Dimensional Integrity (INV-002), Coordinate Integrity (INV-003), Transformation Integrity (INV-006), Representation Independence (INV-013). |
| **Geometry Translation** | `lib/302_Geometry/Translation/101_definition.md` | Operational (0.1.0) | Uniform vector displacement. Affine vs Linear separation: points ≠ vectors. |
| **Geometry Rotation** | `lib/302_Geometry/Rotation/101_definition.md` | Operational (0.1.0) | Orientation transformation via rotation matrices or unit quaternions. |
| **Geometry Scale** | `lib/302_Geometry/Scale/101_definition.md` | Operational (0.1.0) | Isotropic or anisotropic metric scaling. |
| **Geometry CoordinateSystems** | `lib/302_Geometry/CoordinateSystems/101_definition.md` | Operational (0.1.0) | Cartesian, spherical, cylindrical, curvilinear, barycentric coordinate frames. |

### 2.2 Domains That Are Placeholder Stubs

| Domain | Path | Implication |
|--------|------|-------------|
| **Core Transforms** | `lib/101_Core/Transforms/101_definition.md` | Empty stub. SCR-level transform semantics not yet defined. This sprint's primary deliverable. |
| **Position** | `lib/801_Spatial/Position/101_definition.md` | Empty stub. Spatial position concept deferred to sprint deliverable. |
| **Orientation** | `lib/801_Spatial/Orientation/101_definition.md` | Empty stub. Orientation concept deferred to sprint deliverable. |
| **Transformations** | `lib/801_Spatial/Transformations/101_definition.md` | Empty stub. Spatial transformation concept deferred to sprint deliverable. |
| **CoordinateSystems** | `lib/801_Spatial/CoordinateSystems/101_definition.md` | Empty stub. Coordinate system definitions deferred to sprint deliverable. |
| **ReferenceFrames** | `lib/801_Spatial/ReferenceFrames/101_definition.md` | Empty stub. Reference frame definitions deferred to sprint deliverable. |
| **Coordinates** | `lib/801_Spatial/Coordinates/101_definition.md` | Empty stub. Coordinate value types deferred to sprint deliverable. |
| **Distance** | `lib/801_Spatial/Distance/101_definition.md` | Empty stub. Distance metrics deferred to sprint deliverable. |
| **Direction** | `lib/801_Spatial/Direction/101_definition.md` | Empty stub. Direction semantics deferred to sprint deliverable. |
| **Proximity** | `lib/801_Spatial/Proximity/101_definition.md` | Empty stub. Proximity semantics deferred to sprint deliverable. |
| **Neighbourhood** | `lib/801_Spatial/Neighbourhood/101_definition.md` | Empty stub. Neighbourhood semantics deferred to sprint deliverable. |
| **Region** | `lib/801_Spatial/Region/101_definition.md` | Empty stub. Region semantics deferred to sprint deliverable. |
| **H3** | `lib/801_Spatial/H3/101_definition.md` | Empty stub. H3 hexagonal indexing deferred to sprint deliverable. |

### 2.3 Assessment Summary

The `lib/801_Spatial/101_definition.md` is the normative authority — comprehensive (1372 lines, 41 invariants) but abstract. It defines *what* spatial semantics mean without prescribing *how* subdomains compose. The `lib/302_Geometry` subdomains (Transform, Translation, Rotation, Scale, CoordinateSystems) are mathematically grounded but represent geometric primitives, not semantic spatial meaning.

**Critical gap:** No operational definition exists for:
- Semantic Transform as a composite of position + orientation + scale
- Parent/child hierarchy composition and transform accumulation
- Coordinate system conventions and inter-system mappings
- Spatial relationship semantics (containment, adjacency, proximity, visibility)

M003 Sprint 02 must fill this gap.

## 3. Semantic Transform

### 3.1 SCR Semantic Transform (Normative)

**Concept:** `SemanticTransform`
**Source:** Spatial §5 (Orientation and Direction), Spatial §20 (Spatial Transformation), Geometry Transform, Geometry Translation, Geometry Rotation, Geometry Scale
**Status:** define-new — no existing composite transform definition

A SemanticTransform represents the **provider-independent spatial pose** of an entity within a declared reference frame. It is the composite of:

```text
SemanticTransform = Position + Orientation + Scale
```

| Component | Type | Meaning | Grounded In |
|-----------|------|---------|-------------|
| **Position** | Point (affine space) | Spatial location relative to reference frame origin | Geometry Translation, Spatial §2 (Position) |
| **Orientation** | Unit Quaternion (preferred), Rotation Matrix (alternative) | Angular configuration relative to reference frame axes | Geometry Rotation, Spatial §5 (Orientation) |
| **Scale** | Vector3D (uniform or non-uniform) | Metric scaling relative to reference frame units | Geometry Scale |

### 3.2 Semantic Transform ≠ Representation Transform

| Aspect | Semantic Transform | Representation Transform |
|--------|-------------------|------------------------|
| **Authority** | SCR — defines meaning | Provider — encodes meaning |
| **Existence** | Meaningful whether or not a provider exists | Depends on provider runtime |
| **Multiplicity** | Single semantic meaning | May have multiple provider representations |
| **Identity** | Has semantic identity (SID-scoped) | Provider-local handle, ephemeral |
| **Invariance** | Provider-independent | Provider-specific layout, format, endianness |

Example:
```
SCR Semantic: Position(1.0, 2.0, 3.0), Orientation(quat(0, 0, 0, 1)), Scale(1, 1, 1)
    ↓ O3DE Provider
AZ::Transform (matrix storage, O3DE coordinate system, Y-up convention)
    ↓ ROS 2 Provider
geometry_msgs::msg::Transform (column-major matrix, ROS 2 convention, X-forward)
```

Same semantic meaning, two provider representations. Neither provider redefines the semantic meaning.

### 3.3 Transform Composition

SemanticTransforms compose hierarchically:

```text
SemanticTransform_world = SemanticTransform_parent * SemanticTransform_local
```

Composition follows affine group laws (per Geometry INV-006):
1. Scale accumulates multiplicatively (child scale × parent scale)
2. Orientation accumulates multiplicatively (child quaternion × parent quaternion)
3. Position accumulates via affine combination (parent orientation rotates child position, then adds parent position)

```text
scale_world = scale_parent ⊙ scale_local
orientation_world = orientation_parent × orientation_local
position_world = position_parent + orientation_parent.rotate(position_local ⊙ scale_parent)
```

### 3.4 Determinism

SemanticTransform composition is deterministic. Equivalent inputs under equivalent reference frames MUST produce equivalent outputs (per Spatial INV-039).

### 3.5 Provenance

```yaml
concept: SemanticTransform
source: O3DE
source_terminology: AZ::Transform (matrix4x4)
scr_interpretation: Provider-independent composite pose: position (Point3D) + orientation (Quaternion) + scale (Vector3D). Composable hierarchically via affine group laws.
differences: O3DE uses 4x4 matrix exclusively. SCR separates into semantic components. O3DE uses右手坐标系 Y-up; SCR canonical is +Z forward, +Y up, +X right. No matrix representation in semantic layer.
```

## 4. Hierarchy

### 4.1 Parent/Child Composition (Normative)

**Concept:** `SpatialHierarchy`
**Source:** Spatial §17 (Hierarchical Spatial Structures), Core §32 (Composition)
**Status:** define-new

An entity hierarchy is a directed acyclic graph (DAG) where:

- Each node is an Entity with a SemanticTransform
- Each edge is a parent/child relationship with a local SemanticTransform
- The root has a world-frame SemanticTransform (typically identity)

```text
World (root)
├── Entity A (local transform: T_A)
│   ├── Entity B (local transform: T_B)
│   │   └── Entity C (local transform: T_C)
│   └── Entity D (local transform: T_D)
└── Entity E (local transform: T_E)
```

### 4.2 Transform Accumulation

World transform is computed by accumulating from root to leaf:

```text
T_world(C) = T_world(A) × T_local(B) × T_local(C)
```

Accumulation is **right-to-left**: parent transform applied first, then child local transform.

### 4.3 Local vs World

| Frame | Meaning | Use |
|-------|---------|-----|
| **Local** | Transform relative to parent entity | Authoring, entity-level queries |
| **World** | Transform accumulated from root | Rendering, physics, spatial queries |

Both frames are always available. Conversion is deterministic and invertible:

```text
T_local = T_parent⁻¹ × T_world
T_world = T_parent × T_local
```

### 4.4 Hierarchy Invariants

- **No cycles:** Parent/Child graph is a DAG (per Graph semantics).
- **Single parent:** Each entity has at most one parent (tree, not general DAG).
- **Identity preserved:** Entity identity (SID) is invariant under hierarchy changes.
- **Transform separation:** Local transform is independent of world transform. Changing parent does not mutate local transform.

### 4.5 Provenance

```yaml
concept: SpatialHierarchy
source: O3DE
source_terminology: AZ::TransformBus, AZ::EntityId hierarchy (parent-child via Transform component)
scr_interpretation: DAG of entities with composable local-to-world transforms. Single parent. Transform accumulation follows affine group laws.
differences: O3DE uses flat parent-child via AZ::ParentEntityId. SCR defines as first-class semantic concept. No bus-based query. O3DE has no explicit local/world distinction (matrix computed lazily). SCR makes both frames explicit.
```

## 5. Coordinate Systems

### 5.1 Canonical Convention (Normative)

**Concept:** `CoordinateConvention`
**Source:** Spatial §4 (Reference Frames), Spatial §3 (Coordinates), Geometry CoordinateSystems
**Status:** define-new

SCR canonical coordinate convention:

```text
+Z = Forward (north, depth, primary axis)
+Y = Up (vertical, against gravity)
+X = Right (lateral)
```

Right-handed coordinate system. Units: metres (SI). Quaternions: Hamilton convention (scalar-first or vector-first — declared explicitly).

### 5.2 Coordinate Convention Mapping Table

| Convention | Forward | Up | Right | Handedness | Used By |
|------------|---------|----|-------|------------|---------|
| **SCR** | +Z | +Y | +X | Right | SCR canonical |
| **O3DE** | +Y | +Z | +X | Right | O3DE (Open 3D Engine) |
| **USD** | +Y | +Z | +X | Right | USD (Universal Scene Description) |
| **ROS 2** | +X | +Z | -Y | Right | ROS 2 (Robot Operating System) |
| **H3** | N/A | N/A | N/A | N/A | H3 (hexagonal hierarchical spatial index — cell-based, no Cartesian axes) |
| **OpenGL** | -Z | +Y | +X | Right | OpenGL, glTF |
| **Vulkan** | +Z | +Y | +X | Right | Vulkan (NDC) |
| **Unity** | +Z | +Y | +X | Left | Unity Engine |
| **Unreal** | +X | +Z | +Y | Right | Unreal Engine |

### 5.3 Inter-System Transform Mappings

Provider adapters MUST apply explicit coordinate transforms when mapping between SCR and provider conventions:

**SCR → O3DE:**
```text
x_o3de = x_scr
y_o3de = z_scr
z_o3de = y_scr
```

**SCR → ROS 2:**
```text
x_ros = z_scr
y_ros = -x_scr
z_ros = y_scr
```

**SCR → USD:**
```text
x_usd = x_scr
y_usd = z_scr
z_usd = y_scr
```

**O3DE → ROS 2:**
```text
x_ros = y_o3de
y_ros = -x_o3de
z_ros = z_o3de
```

### 5.4 Reference Frame Explicitness

Per Spatial INV-002 (Reference Explicitness), all coordinate values MUST be interpreted within an explicit or inferable reference frame. When coordinates cross a system boundary (SCR ↔ provider), the mapping MUST be declared and applied.

### 5.5 H3 Special Case

H3 uses hexagonal hierarchical cells rather than Cartesian coordinates. H3 cells have:
- No intrinsic forward/up/right axes
- Resolution levels (0–15) defining cell area
- Cell centres that can be converted to lat/lon (geodetic)

SCR treats H3 as a discrete spatial index, not a coordinate system. H3 cells are spatial regions, not coordinate frames.

### 5.6 Provenance

```yaml
concept: CoordinateConvention
source: Multi-system
source_terminology: Varies per system
scr_interpretation: Canonical +Z-forward, +Y-up, +X-right. Right-handed. Provider adapters apply explicit axis swaps and handedness checks when crossing boundaries.
differences: SCR canonical differs from O3DE (+Y forward, +Z up), ROS 2 (+X forward, +Z up, -Y right), USD (+Y forward, +Z up). Each provider adapter applies explicit mapping.
```

## 6. Spatial Relationships

### 6.1 Relationship Categories (Normative)

**Concept:** `SpatialRelationship`
**Source:** Spatial §11 (Spatial Relationships), Spatial §6 (Extent and Region), Spatial §7 (Neighbourhood)
**Status:** define-new — extends abstract Spatial definition

Spatial relationships describe how entities relate spatially. They are first-class semantic relationships within the SCR Semantic Hypergraph.

### 6.2 Containment

**Concept:** `Containment`
**Source:** Spatial §6 (Extent and Region), Spatial §33 (Semantic Hypergraph Integration)
**Status:** define-new

Containment describes entity A being spatially inside region/entity B.

| Type | Meaning | Example |
|------|---------|---------|
| **Strict containment** | A entirely within B boundary | Room inside building |
| **Boundary containment** | A shares boundary with B | Furniture against wall |
| **Partial containment** | A overlaps B but is not entirely within | Intersection zone |

Containment relationships are transitive: if A contains B and B contains C, then A contains C.

Containment MUST be distinguishable from mere semantic grouping (Spatial §6, INV-018).

### 6.3 Adjacency

**Concept:** `Adjacency`
**Source:** Spatial §11 (Spatial Relationships), Spatial §7 (Neighbourhood)
**Status:** define-new

Adjacency describes entities that share a boundary or are immediate neighbours without gap.

| Type | Meaning | Example |
|------|---------|---------|
| **Boundary adjacency** | Shared boundary segment | Wall between rooms |
| **Vertex adjacency** | Shared vertex only | Two polygons meeting at corner |
| **Edge adjacency** | Shared edge | Adjacent cells in grid |

Adjacency is symmetric: if A is adjacent to B, then B is adjacent to A.

Adjacency composes with Topology (connectivity, incidence).

### 6.4 Proximity

**Concept:** `Proximity`
**Source:** Spatial §10 (Proximity), Spatial §9 (Distance)
**Status:** define-new

Proximity describes spatial closeness according to a declared metric or threshold.

| Type | Meaning | Metric |
|------|---------|--------|
| **Distance proximity** | Within declared distance threshold | Euclidean, Manhattan, geodetic |
| **Topological proximity** | Within declared connectivity hops | Graph distance |
| **Semantic proximity** | Within declared semantic region | Domain-specific |

Proximity is NOT equivalent to distance (Spatial §10). Two entities may be close by distance but semantically distant (e.g., separated by a wall).

Proximity thresholds MAY be dynamic (changing with context, time, or scale).

### 6.5 Visibility

**Concept:** `Visibility`
**Source:** Spatial §11 (Spatial Relationships), Spatial §7 (Neighbourhood) — visibility as neighbourhood criterion
**Status:** define-new

Visibility describes whether entity A has line-of-sight to entity B.

| Type | Meaning | Considerations |
|------|---------|---------------|
| **Geometric visibility** | Unobstructed ray between A and B | Ray-casting against geometry |
| **Semantic visibility** | Within declared visibility region | Region-based predicate |
| **Probabilistic visibility** | Visibility under uncertainty | Sensor model, occlusion probability |

Visibility is directional: A may be visible from B while B is not visible from A (asymmetric occlusion).

Visibility composes with Perception and Rendering semantics.

### 6.6 Relationship Hypergraph Projection

All spatial relationships project into the Semantic Hypergraph:

```text
Entity A
    │
    ├── contained-in ─────► Region B
    ├── adjacent-to ──────► Entity C
    ├── within-distance ──► Entity D (d=5.0m)
    └── visible-from ─────► Entity E
```

Higher-order relationships are representable when required (Spatial §33).

### 6.7 Provenance

```yaml
concept: SpatialRelationship
source: O3DE
source_terminology: AZ::ShapeComponentNotifications, AZ::ObstructionestingBus, AZ::VisibilityBus
scr_interpretation: First-class semantic relationships in Hypergraph. Four primary types: containment, adjacency, proximity, visibility. Provider-independent.
differences: O3DE implements spatial queries as bus calls to shape/obstruction components. SCR defines as semantic relationships independent of query mechanism. O3DE has no unified spatial relationship model; SCR provides one.
```

## 7. Gap Analysis

### 7.1 Classification of SCR Needs

| Concept | Current SCR Status | Action | Classification |
|---------|-------------------|--------|----------------|
| **SemanticTransform** | No composite definition. Geometry Transform, Translation, Rotation, Scale are separate subdomains. | **define-new** | New composite concept unifying Geometry primitives into semantic pose |
| **SpatialHierarchy** | Spatial §17 defines hierarchical structures abstractly. No parent/child composition rules. | **define-new** | New hierarchy composition semantics |
| **LocalToWorld** | No definition. | **define-new** | Transform accumulation algorithm |
| **CoordinateConvention** | Spatial §3, §4 define coordinates/frames abstractly. No concrete canonical convention. | **define-new** | SCR canonical + Z-forward, +Y-up, +X-right |
| **CoordinateMapping** | No inter-system mapping definitions. | **define-new** | SCR ↔ O3DE, ROS 2, USD mappings |
| **Containment** | Spatial §6 defines regions/containment abstractly. | **define-new** | Operational containment relationship |
| **Adjacency** | Spatial §11 mentions adjacency. No definition. | **define-new** | Operational adjacency relationship |
| **Proximity** | Spatial §10 defines proximity abstractly. | **define-new** | Operational proximity relationship |
| **Visibility** | Spatial §7 mentions visibility as neighbourhood criterion. No definition. | **define-new** | Operational visibility relationship |
| **Position** | Spatial §2 defines position abstractly. `lib/801_Spatial/Position/` is stub. | **needs-extension** | Operational position within SemanticTransform |
| **Orientation** | Spatial §5 defines orientation abstractly. `lib/801_Spatial/Orientation/` is stub. | **needs-extension** | Operational orientation within SemanticTransform |
| **H3** | `lib/801_Spatial/H3/` is stub. | **deferred** | H3 is provider indexing, not core spatial semantics |

### 7.2 Concepts Already Adequately Defined

| Concept | Where Defined |
|---------|---------------|
| Position (abstract) | Spatial §2 — adequate as foundation |
| Orientation (abstract) | Spatial §5 — adequate as foundation |
| Distance (abstract) | Spatial §9 — adequate as foundation |
| Spatial Relationships (abstract) | Spatial §11 — adequate as foundation |
| Coordinate Systems (abstract) | Spatial §3–4 — adequate as foundation |
| Geometry Transform | `lib/302_Geometry/Transform/` — operational |
| Geometry Translation | `lib/302_Geometry/Translation/` — operational |
| Geometry Rotation | `lib/302_Geometry/Rotation/` — operational |
| Geometry Scale | `lib/302_Geometry/Scale/` — operational |

### 7.3 Classification Summary

| Classification | Count | Concepts |
|----------------|-------|----------|
| **already-defined** | 9 | Position (abstract), Orientation (abstract), Distance (abstract), Spatial Relationships (abstract), Coordinate Systems (abstract), Geometry Transform, Translation, Rotation, Scale |
| **needs-extension** | 2 | Position (operational), Orientation (operational) |
| **define-new** | 10 | SemanticTransform, SpatialHierarchy, LocalToWorld, CoordinateConvention, CoordinateMapping, Containment, Adjacency, Proximity, Visibility, and composite SemanticTransform |
| **deferred** | 1 | H3 (provider indexing, not core semantics) |

## 8. Derived Definitions for Semantic Library

### 8.1 Recommended File Structure

```
lib/101_Core/
├── Transforms/           (needs: SemanticTransform definition)
└── ...other domains...

lib/801_Spatial/
├── Position/             (needs: operational position definition)
├── Orientation/          (needs: operational orientation definition)
├── Transformations/      (needs: SemanticTransform composite definition)
├── CoordinateSystems/    (needs: canonical convention, mapping definitions)
├── ReferenceFrames/      (needs: local/world frame distinction)
├── Hierarchy/            (new: parent/child composition rules)
├── Containment/          (new: containment relationship)
├── Adjacency/            (new: adjacency relationship)
├── Proximity/            (needs: operational proximity definition)
├── Visibility/           (new: visibility relationship)
└── ...existing domains...
```

### 8.2 Invariants Added

| Invariant | Statement |
|-----------|-----------|
| **SPATIAL-INV-019 (Transform Composite Integrity)** | A SemanticTransform MUST be decomposable into position, orientation, and scale components without loss of semantic meaning. |
| **SPATIAL-INV-020 (Hierarchy Transform Accumulation)** | World transform MUST be computable from local transforms via deterministic accumulation along the parent chain. |
| **SPATIAL-INV-021 (Coordinate Explicitness)** | All coordinate values MUST declare their coordinate convention. Cross-boundary transfers MUST apply explicit mapping. |
| **SPATIAL-INV-022 (Containment Transitivity)** | Containment relationships MUST be transitive. |
| **SPATIAL-INV-023 (Adjacency Symmetry)** | Adjacency relationships MUST be symmetric. |
| **SPATIAL-INV-024 (Visibility Asymmetry)** | Visibility relationships MAY be asymmetric due to occlusion. |

## 9. Exit Criteria Check

- [x] Semantic transform distinguished from representation transform (Section 3.2)
- [x] Coordinate conventions documented with mappings to O3DE, USD, ROS 2, H3 (Section 5.2)
- [x] Hierarchy composition rules defined (Section 4)
- [x] Parent/child transform accumulation documented (Section 4.2)
- [x] Spatial relationships defined: containment, adjacency, proximity, visibility (Section 6)
- [x] SCR canonical convention declared: +Z forward, +Y up, +X right (Section 5.1)
- [x] Provenance documented for all O3DE-derived concepts (Sections 3.5, 4.5, 5.6, 6.7)
- [x] Each concept classified: already-defined / needs-extension / define-new (Section 7.1)

## 10. Deferred to Subsequent Sprints

| Concept | Sprint | Reason |
|---------|--------|--------|
| H3 operational definition | Sprint 03+ | Provider indexing; not core spatial semantics |
| Tick / Temporal Transform | Sprint 03 (Physics & Dynamics) | Interacts with dynamics and time-varying transforms |
| EntityTemplate / EntitySpawn | Sprint 04 (Asset/Resource/Materialization) | Tied to serialization and instantiation pipelines |
| Field-Spatial Composition | Sprint 03+ | Spatial fields compose with dynamics |
| Navigation / Pathfinding | Sprint 03+ | Higher-level spatial computation |
