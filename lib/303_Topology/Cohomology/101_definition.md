---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-COHOMOLOGY
name: Topology Cohomology

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: Cohomology

## Summary

Cohomological structures dual to homology, providing algebraic tools for topological obstruction theory and characteristic classes.

---

## 1. Semantic Definition

**Cohomology** is the dual algebraic structure to homology. Where homology measures topological cycles, cohomology measures the extent to which cycles bound cochains.

Cohomology groups Hⁿ(X; G) are computed from the cochain complex:

```
0 → C⁰(X; G) → C¹(X; G) → C²(X; G) → ...
```

where the coboundary operator δ: Cⁿ → Cⁿ⁺¹ satisfies δ∘δ = 0.

## 2. Cohomology Products

Cohomology possesses a ring structure via the cup product:

```
⌣: Hᵖ(X; R) ⊗ Hq(X; R) → Hᵖ⁺q(X; R)
```

This ring structure contains information not present in homology.

## 3. Applications

Cohomology supports:

- de Rham cohomology for differential forms;
- Čech cohomology for sheaves;
- obstruction theory;
- characteristic classes;
- Poincaré duality.

## 4. Invariants

- **TOPOLOGY-INV-006**: Equivalence claims MUST identify whether homeomorphism, homotopy equivalence, or another relation is used.
- **TOPOLOGY-INV-007**: Cohomological invariants MUST be preserved under declared transformations.

---

# Definition Authority

This document defines the normative semantic meaning of the **Cohomology** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **Cohomology is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
