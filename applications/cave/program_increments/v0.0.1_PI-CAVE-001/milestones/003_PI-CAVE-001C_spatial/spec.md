# Milestone 003: PI-CAVE-001C — Spatial Semantics & Inverse Mapping

**Parent RoadMap:** [milestones/README.md](../README.md)  
**Target Area:** `applications/cave/program_increments/v0.0.1_PI-CAVE-001/milestones/003_PI-CAVE-001C_spatial/`  
**Derived from:** `spec.md` (Sections 11, 12, 13, 51, 79)  
**Governing Documents:** [`docs/114_SPATIAL_SEMANTICS.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/114_SPATIAL_SEMANTICS.md), [`docs/115_SPATIAL_PARTITIONING_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/115_SPATIAL_PARTITIONING_MODEL.md), [`docs/116_SPATIAL_STATE_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/116_SPATIAL_STATE_MODEL.md)  
**Status:** Planned  

---

## 1. Objective

Implement **Spatial Semantics** for the Cave desktop, establishing mathematical representations for coordinate spaces, reference frames, 3D affine/rigid transformations, bounding volumes, hierarchical spatial trees, and inverse spatial mapping for viewport pointer ray hit testing.

---

## 2. Compliance with Authoritative Architecture

1. **Spatial Semantics ([`docs/114_SPATIAL_SEMANTICS.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/114_SPATIAL_SEMANTICS.md)):**
   Space is an explicit semantic construct, not implicit pixel coordinates. All geometric positions are defined relative to an explicit `ReferenceFrame`.
2. **Spatial Hierarchy ([`docs/116_SPATIAL_STATE_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/116_SPATIAL_STATE_MODEL.md)):**
   Spatial state forms a directed tree of reference frames. Local transforms compose to yield authoritative world transforms.
3. **Inverse Spatial Mapping ([`docs/114_SPATIAL_SEMANTICS.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/114_SPATIAL_SEMANTICS.md) §4.3):**
   Interaction (mouse clicks, pointer movement, touch) is calculated by casting a ray from the viewport/camera coordinate space back through the inverted spatial transform tree to determine the exact $(u, v)$ coordinate on the target semantic surface.

---

## 3. Sprint Breakdown

```text
003_PI-CAVE-001C_spatial/
├── spec.md
└── sprints/
    ├── sprint_01_spatial_primitives_and_frames.md    # Coordinate spaces, reference frames, 3D transforms
    ├── sprint_02_spatial_hierarchy.md                # Parent-child frame tree, local-to-world composition
    └── sprint_03_inverse_spatial_mapping.md          # Viewport ray to surface (u,v) inverse hit testing
```

### [Sprint 01: Spatial Primitives & Reference Frames](sprints/sprint_01_spatial_primitives_and_frames.md)
- Implement `CoordinateSpace` (3D Euclidean, units in millimeters/meters).
- Implement `Transform3D` (4x4 matrix and dual quaternion representations).
- Implement `Point3D`, `Vector3D`, `Quaternion`, and `BoundingBox3D`.
- Implement `ReferenceFrame` carrying local transform and origin reference.

### [Sprint 02: Spatial Hierarchy & Composition](sprints/sprint_02_spatial_hierarchy.md)
- Implement hierarchical spatial tree: Desktop Frame $\to$ Workspace Frame $\to$ Surface Frame.
- Implement forward kinematics: `get_world_transform(frame_id)` by composing ancestors:
  $$T_{\text{world}} = T_{\text{root}} \circ T_1 \circ T_2 \circ \cdots \circ T_{\text{local}}$$
- Implement dirty-flag caching to avoid redundant matrix multiplications during frame traversal.

### [Sprint 03: Inverse Spatial Mapping & Hit Testing](sprints/sprint_03_inverse_spatial_mapping.md)
- Implement `Ray3D` construct (origin, direction).
- Implement Ray-to-Surface quad intersection testing:
  $$\text{Ray}(t) = P_0 + t \cdot \vec{d}$$
- Map 3D world intersection point to normalized 2D surface local coordinates: $(x, y, z) \mapsto (u, v) \in [0, 1] \times [0, 1]$.
- Verify hit testing under translated, rotated, and scaled surface transforms.

---

## 4. Milestone Exit Criteria

1. Complete Mojo implementation of spatial primitives and reference frames.
2. Verified spatial hierarchy transform composition with dirty-flag optimization.
3. Automated inverse spatial mapping tests pass across arbitrary 3D orientations.
4. Conformance to `docs/114_SPATIAL_SEMANTICS.md` verified.
