---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-ADJACENCY
name: Topology Adjacency

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: Adjacency

## Summary

Local structural neighbourhood relationship between topological elements sharing a boundary, face, edge, or vertex without requiring a metric.

---

## 1. Semantic Definition

**Adjacency** is the topological relationship between two elements that share a boundary, face, edge, or vertex within a topological structure. Adjacency is a first-class semantic concept, not merely an implementation convenience.

Adjacency is:

- **not** geometric proximity — elements may be metrically distant yet topologically adjacent;
- **not** graph edge existence — though a graph may encode adjacency;
- **not** array neighbour indexing — storage layout does not define adjacency.

## 2. Adjacency Types

Adjacency MAY be:

- **vertex-vertex**: two vertices sharing an edge;
- **edge-edge**: two edges sharing a vertex;
- **face-face**: two faces sharing an edge or vertex;
- **volume-volume**: two volumes sharing a face, edge, or vertex;
- **cell-cell**: two cells sharing a boundary element in a cell complex.

The adjacency type MUST be declared explicitly.

## 3. Directed vs Undirected Adjacency

Adjacency MAY be directed (asymmetric) or undirected (symmetric). The direction semantics MUST be declared.

## 4. Higher-Order Adjacency

Adjacency MAY exist in higher-dimensional structures through shared k-faces.

## 5. Invariants

- **TOPOLOGY-INV-001**: Adjacency relationships MUST be semantically consistent with the declared topological structure.
- **TOPOLOGY-INV-004**: Boundary integrity underpins adjacency semantics.

## 6. Relationship to Incidence

Adjacency and incidence are distinct:

```
Adjacency  → same-dimension elements sharing a lower-dimensional boundary
Incidence  → cross-dimension element membership (vertex incident to edge)
```

## 7. Computational & Physical Manifestations

Adjacency serves as the topological carrier for dynamic simulation and material reactions:

- **Voxel Spatial Complexes (`lib/401_Morphology/Voxel`)**:
  - *Face-Sharing (von Neumann 6-neighborhood)*: Carrier for direct conductive heat transfer, fluid flow advection, and rapid thermal quenching (e.g. lava/water contact).
  - *Edge/Corner-Sharing (Moore 26-neighborhood)*: Carrier for percolative fluid seepage, moisture migration, and combustion propagation.
- **Material Reactive Boundaries (`lib/A01_Render/Material/106_material_transformations_and_reactions.md`)**:
  - Boundary phase transitions $\tau_{\text{react}}$ are triggered exclusively across declared topological adjacencies preserving local mass and energy invariants.
- **Hierarchical Sparse Trees (`providers/spatial/volumetric/openvdb`)**:
  - Accelerated neighbor lookup and active voxel topology without dense storage layout bias.

---

# Definition Authority

This document defines the normative semantic meaning of the **Adjacency** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **Adjacency is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
