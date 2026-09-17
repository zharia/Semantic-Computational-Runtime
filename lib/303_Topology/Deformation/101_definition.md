---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-DEFORMATION
name: Topology Deformation

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: Deformation

## Summary

Topological deformation — continuous deformations, homotopies, and deformation retracts between spaces and maps.

---

## 1. Semantic Definition

A **deformation** is a continuous family of maps transforming one topological structure into another while potentially preserving specified topological invariants.

A homotopy H: X × [0,1] → Y between maps f and g is a continuous deformation where:

```
H(x, 0) = f(x)
H(x, 1) = g(x)
```

## 2. Topology-Preserving Deformation

A deformation is **topology-preserving** if it does not change the relevant topological invariants. Examples:

- continuous deformation of a rubber sheet (homeomorphism);
- isotopy (deformation through embeddings);
- ambient isotopy (deformation of surrounding space).

## 3. Topology-Changing Deformation

A deformation is **topology-changing** if it alters invariants such as:

- connected component count;
- genus;
- Euler characteristic;
- homology groups.

Topology-changing deformations MUST be explicitly labelled.

## 4. Deformation Retract

A subspace A ⊆ X is a **deformation retract** if there exists a continuous map r: X → A with r|_A = id_A and a homotopy from the inclusion to r.

## 5. Invariants

- **TOPOLOGY-INV-008**: Transformation integrity — declare what the transformation preserves or changes.
- **TOPOLOGY-INV-011**: State integrity MUST hold after deformation.

---

# Definition Authority

This document defines the normative semantic meaning of the **Deformation** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **Deformation is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
