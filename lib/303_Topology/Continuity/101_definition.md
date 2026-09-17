---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-CONTINUITY
name: Topology Continuity

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: Continuity

## Summary

Topological continuity of maps between topological spaces — preservation of neighbourhood structure under function application.

---

## 1. Semantic Definition

A map f: X → Y between topological spaces is **continuous** if the preimage of every open set in Y is open in X.

Continuity is:

- a property of maps, not merely of individual values;
- independent of metric: no distance function is required;
- fundamental to homeomorphism, homotopy, and manifold theory.

## 2. Continuity Conditions

```
Continuous Map     → preimage of open sets are open
Homeomorphism      → continuous bijection with continuous inverse
Homotopy           → continuous family of maps parameterised by [0,1]
```

## 3. Continuity and Computation

Computational continuity contracts must declare:

- which topology is used on the domain;
- which topology is used on the codomain;
- what it means for a numerical approximation to satisfy continuity.

## 4. Invariants

- **TOPOLOGY-INV-005**: Operations claiming continuity MUST satisfy their declared continuity contract.
- **TOPOLOGY-INV-008**: Transformation integrity requires declaring whether the transformation is continuous.

---

# Definition Authority

This document defines the normative semantic meaning of the **Continuity** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **Continuity is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
