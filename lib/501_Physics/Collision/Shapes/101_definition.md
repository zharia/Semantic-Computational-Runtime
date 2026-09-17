---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-PHYSICS-COLLISION-SHAPES
name: Physics Collision Shapes

version: 0.1.0
status: operational

created: 2026-09-17
updated: 2026-09-17

parent: SCR-LIB-PHYSICS-COLLISION
authority: SCR
domain: semantic-library
---

# SCR Physics: Collision Shapes

## Summary
Geometric taxonomy and representation of collision volumes: Convex Implicit Primitives, Polyhedral Convex Hulls, Compound Shape Trees, and Concave Triangle Meshes (including OpenVDB voxel isosurfaces).

---

## 1. Shape Taxonomy

1. **Convex Implicit Primitives**:
   - **Sphere**: Defined by radius $r > 0$. Uniform support mapping $S(v) = r \frac{v}{\|v\|}$.
   - **Box**: Defined by half-extents $(h_x, h_y, h_z)$. Support $S(v) = (\text{sgn}(v_x)h_x, \text{sgn}(v_y)h_y, \text{sgn}(v_z)h_z)$.
   - **Capsule**: Defined by cylinder height $h$ and hemispherical cap radius $r$.
   - **Cylinder / Cone**: Rotational geometric primitives with analytical support mappings.
2. **Convex Polyhedral Hulls**:
   - Closed point cloud bounding geometry represented via convex vertex hull $\{v_1, \dots, v_k\}$.
3. **Compound Shapes**:
   - Hierarchical collection of child collision shapes with local rigid transforms $T_i \in \text{SE}(3)$.
4. **Concave Triangle Meshes & Voxel Isosurfaces**:
   - Static polygon meshes indexed by Bounding Volume Hierarchies (`btBvhTriangleMeshShape`), representing OpenVDB isosurfaces, caves, and terrain bathymetry.

## 2. Invariants & Normative Rules
- **SHAPES-INV-001 (Positive Volume)**: All dynamic collision shapes must enclose positive volume $V > 0$ to ensure well-defined inertia tensors.
- **SHAPES-INV-002 (Inertia Consistency)**: Principal moments of inertia $I_{xx}, I_{yy}, I_{zz}$ must strictly satisfy triangle inequalities $I_{xx} + I_{yy} \ge I_{zz}$.
- **SHAPES-INV-003 (Concave Mesh Staticity)**: Concave triangle mesh shapes are restricted to static or kinematic bodies unless decomposed into approximate convex hulls (HACD/V-HACD).

## 3. Relationships
- **Parent**: `lib/501_Physics/Collision`
- **lib/302_Geometry/Mesh**: Supplies triangle soup and indexed vertex-face buffers.
- **lib/301_Field/Voxel**: Provides OpenVDB distance fields and level sets for isosurface polygonization.
