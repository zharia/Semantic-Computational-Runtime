---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-GEOMETRY-ROTATION
name: Geometry Rotation

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-GEOMETRY
authority: SCR
domain: semantic-library
---

# SCR Geometry — Rotation

## 1. Definition

**Rotation** is the normative geometric subdomain within `SCR-LIB-GEOMETRY` responsible for:
> Orientation transformation about a point, axis, or frame using rotation matrices or unit quaternions.

In accordance with the foundational governing principle:
```text
Geometry Semantic Meaning ≠ Representation ≠ Storage Format ≠ Renderer ≠ Hardware Execution
```

---

## 2. Invariants

This subdomain enforces the following normative domain invariants:
- **GEOMETRY-INV-001 (Identity)**: Entities possess immutable semantic identities independent of coordinate representation.
- **GEOMETRY-INV-002 (Dimensional Integrity)**: Dimension is preserved under non-dimensional transformations.
- **GEOMETRY-INV-003 (Coordinate Integrity)**: Transformations preserve declared reference coordinate semantics.
- **GEOMETRY-INV-006 (Transformation Integrity)**: Spatial operations satisfy declared geometric group laws.
- **GEOMETRY-INV-013 (Representation Independence)**: Meaning does not depend on physical array or mesh layout.

---

## 3. Semantic Contracts

1. **Explicit Mathematical Grounding**: Grounded in `SCR-LIB-MATHEMATICS` (vector spaces, affine spaces, metric spaces).
2. **Affine vs Linear Separation**: Points (locations) and vectors (displacements) remain semantically and operationally distinct.
3. **Hypergraph Projection**: Semantic geometric relationships project into the canonical hypergraph `SCR-LIB-HYPERGRAPH`.
4. **Technology Independence**: External libraries (CGAL, libigl, OpenCASCADE) act strictly as subordinate providers under SCR contracts.

---

## 4. Derived & Subordinate Relationships

- **Upstream Dependencies**: `SCR-LIB-GEOMETRY`, `SCR-LIB-MATHEMATICS`, `SCR-LIB-CORE` (Identity).
- **Downstream Beneficiaries**: `SCR-LIB-FIELDS`, `SCR-LIB-SPATIAL`, `SCR-LIB-RENDER`, `SCR-LIB-PHYSICS`.
