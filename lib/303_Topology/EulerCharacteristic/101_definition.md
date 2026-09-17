---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-EULER
name: Topology EulerCharacteristic

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: EulerCharacteristic

## Summary

Euler characteristic as a fundamental topological invariant computed from the alternating sum of cell counts across dimensions.

---

## 1. Semantic Definition

The **Euler characteristic** χ is a fundamental topological invariant defined as the alternating sum of the ranks of homology groups (or cell counts for cell complexes):

```
χ(X) = Σ (-1)ⁿ βₙ
```

where βₙ is the n-th Betti number (rank of n-th homology group Hₙ(X)).

For a finite cell complex:

```
χ = V - E + F - C + ...
```

## 2. Examples

```
Point           → χ = 1
Circle S¹       → χ = 0
Sphere S²       → χ = 2
Torus T²        → χ = 0
Double Torus    → χ = -2
Real Proj. Pl.  → χ = 1
Klein Bottle    → χ = 0
```

## 3. Euler Characteristic as Invariant

The Euler characteristic is preserved under:

- homeomorphism;
- homotopy equivalence;
- topology-preserving simplification.

It changes under topology-changing operations.

## 4. SCR Semantics

SCR MUST treat the Euler characteristic as a semantic topological/mathematical quantity, not as a mesh statistic or rendering property.

## 5. Invariants

- **TOPOLOGY-INV-007**: Euler characteristic MUST be preserved by operations claiming invariant preservation.

---

# Definition Authority

This document defines the normative semantic meaning of the **EulerCharacteristic** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **EulerCharacteristic is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
