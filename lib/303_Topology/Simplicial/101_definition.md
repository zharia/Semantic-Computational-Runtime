---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-SIMPLICIAL
name: Topology Simplicial

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: Simplicial

## Summary

Simplicial topology — simplices, simplicial complexes, and simplicial homology as combinatorial topological structures.

---

## 1. Semantic Definition

A **simplex** of dimension n (n-simplex) is the convex hull of (n+1) affinely independent points:

```
0-simplex → vertex
1-simplex → edge
2-simplex → triangle
3-simplex → tetrahedron
n-simplex → generalisation
```

A **simplicial complex** K is a collection of simplices satisfying:

- every face of a simplex in K is in K;
- the intersection of any two simplices in K is a face of both.

## 2. Abstract Simplicial Complexes

An **abstract simplicial complex** is a purely combinatorial object (set system closed under taking subsets) with no reference to geometric embedding.

Topology is determined by the combinatorial structure, not the geometry.

## 3. Simplicial Homology

The simplicial chain complex:

```
... → Cₙ(K) → Cₙ₋₁(K) → ... → C₀(K) → 0
```

provides simplicial homology groups Hₙ(K).

## 4. Applications

Simplicial complexes arise in:

- computational topology;
- persistent homology (via Vietoris–Rips, Čech filtrations);
- discrete Morse theory;
- geometric and algebraic topology.

## 5. Invariants

- **TOPOLOGY-INV-003**: Incidence integrity across simplices.
- **TOPOLOGY-INV-007**: Simplicial homology invariants MUST be preserved under claimed invariant-preserving operations.

---

# Definition Authority

This document defines the normative semantic meaning of the **Simplicial** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **Simplicial is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
