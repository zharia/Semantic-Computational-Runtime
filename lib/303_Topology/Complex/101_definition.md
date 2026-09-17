---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-COMPLEX
name: Topology Complex

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: Complex

## Summary

Topological complexes — simplicial, cell, cubical — as discrete computational representations of topological spaces.

---

## 1. Semantic Definition

A **topological complex** is a discrete combinatorial structure composed of building blocks (simplices, cells, cubes) that collectively represent a topological space.

Complexes provide computational handles for:

- topological computation;
- homology and cohomology;
- discrete geometry;
- computational topology.

## 2. Types of Complexes

```
Simplicial Complex  → built from simplices (vertices, edges, triangles, tetrahedra)
Cell Complex        → built from cells via attaching maps
Cubical Complex     → built from cubes and their faces
Delta Complex       → simplicial complex with relaxed glueing rules
```

## 3. Complex Semantics

A complex:

- is a representation of topological structure, not the definition;
- MUST maintain closure under face maps;
- MUST be combinatorially consistent;
- MUST NOT redefine topological semantics through its data structure.

## 4. Invariants

- **TOPOLOGY-INV-003**: Incidence integrity across complex elements.
- **TOPOLOGY-INV-007**: Operations claiming invariant preservation MUST preserve the specified invariants.
- **TOPOLOGY-INV-014**: Topological meaning MUST NOT depend on the choice of complex representation.

---

# Definition Authority

This document defines the normative semantic meaning of the **Complex** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **Complex is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
