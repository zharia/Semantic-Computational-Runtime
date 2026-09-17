---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-ORIENTATION
name: Topology Orientation

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: Orientation

## Summary

Topological orientation of manifolds and complexes — consistent choice of direction across the structure.

---

## 1. Semantic Definition

**Orientation** is a consistent choice of local ordering of the elements of a topological structure — determining "which way is up" in a well-defined global sense.

A topological space is **orientable** if such a consistent global choice exists.

## 2. Orientability Examples

```
Sphere S²           → orientable
Torus T²            → orientable
Klein Bottle        → non-orientable
Real Projective Plane → non-orientable
Möbius Strip        → non-orientable (manifold with boundary)
```

## 3. Orientation and Manifolds

For an orientable n-manifold:

- each chart is oriented;
- transition maps have positive Jacobian determinant.

## 4. Orientation in Meshes

For a triangle mesh, orientation means:

- vertices of each face listed in consistent winding order;
- adjacent faces share edges with opposite orientation.

A mesh may be represented as having consistent winding order in its data structure while the topological orientability depends on the underlying space.

## 5. Applications

Orientation matters for:

- surface normals and rendering;
- integration of differential forms;
- Poincaré duality;
- physical simulation (pressure, flux);
- de Rham cohomology.

## 6. Invariants

- **TOPOLOGY-INV-007**: Orientability MUST be preserved by topology-preserving operations that claim to do so.
- **TOPOLOGY-INV-015**: Orientability is a topological property, not a metric one.

---

# Definition Authority

This document defines the normative semantic meaning of the **Orientation** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **Orientation is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
