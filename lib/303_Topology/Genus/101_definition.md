---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-GENUS
name: Topology Genus

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: Genus

## Summary

Topological genus classifying oriented surfaces by the number of handles — a fundamental topological invariant.

---

## 1. Semantic Definition

The **genus** g of a connected orientable closed surface is the number of handles:

```
Sphere       → g = 0  (χ = 2)
Torus        → g = 1  (χ = 0)
Double Torus → g = 2  (χ = -2)
```

The relationship to Euler characteristic: `χ = 2 - 2g`.

## 2. Genus as Topological Invariant

Genus is:

- a topological property, not a geometric one;
- preserved under homeomorphism;
- independent of size, shape, or metric;
- invariant under continuous deformation.

## 3. Non-Orientable Genus

For non-orientable surfaces, the **crosscap number** (non-orientable genus) k satisfies:

```
χ = 2 - k
```

Examples: real projective plane (k=1), Klein bottle (k=2).

## 4. Higher-Dimensional Genus

For higher-dimensional manifolds, genus generalises through Betti numbers and homology. The interpretation depends on the dimensional context.

## 5. SCR Semantics

SCR implementations MUST distinguish genus (topological) from polygon count, mesh resolution, or any geometric property.

## 6. Invariants

- **TOPOLOGY-INV-007**: Genus MUST be preserved by topology-preserving operations.
- **TOPOLOGY-INV-015**: Genus is metric-independent.

---

# Definition Authority

This document defines the normative semantic meaning of the **Genus** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **Genus is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
