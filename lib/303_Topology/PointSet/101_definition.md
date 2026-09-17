---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-POINTSET
name: Topology PointSet

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: PointSet

## Summary

Point-set topology — the foundational framework for topological spaces, open sets, and continuous maps.

---

## 1. Semantic Definition

**Point-set topology** (general topology) is the foundational discipline establishing the abstract framework of topological spaces, continuous maps, and topological properties.

A **topological space** is a pair (X, τ) where:

- X is a set (the underlying set);
- τ is a collection of subsets of X (the open sets) satisfying:
  - ∅ ∈ τ and X ∈ τ;
  - arbitrary unions of members of τ are in τ;
  - finite intersections of members of τ are in τ.

## 2. Topological Space Examples

```
Discrete topology     → every subset is open
Indiscrete topology   → only ∅ and X are open
Metric topology       → open balls generate the topology
Product topology      → product of topological spaces
Subspace topology     → subspace inherits open sets
Quotient topology     → quotient by equivalence relation
```

## 3. Separation Axioms

Topological spaces are classified by separation axioms (T0, T1, T2/Hausdorff, T3, T4). These constrain how distinct points may be separated by open sets.

## 4. Compactness

A topological space is **compact** if every open cover has a finite subcover. Compact spaces have strong closure properties important for analysis and optimisation.

## 5. Invariants

- **TOPOLOGY-INV-001**: Topological spaces MUST have declared topology (open-set system or equivalent).
- **TOPOLOGY-INV-014**: Representation Independence — the space is not its data representation.

---

# Definition Authority

This document defines the normative semantic meaning of the **PointSet** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **PointSet is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
