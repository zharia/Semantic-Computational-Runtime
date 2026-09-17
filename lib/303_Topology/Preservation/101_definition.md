---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-PRESERVATION
name: Topology Preservation

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: Preservation

## Summary

Topology-preserving operations and transformations that maintain declared topological invariants across state transitions.

---

## 1. Semantic Definition

A **topology-preserving** operation is one that does not change the relevant topological invariants of a structure.

A transformation T is topology-preserving with respect to invariant set I if:

```
∀ inv ∈ I: inv(T(X)) = inv(X)
```

## 2. Declaring Preservation

Operations MUST declare:

- which topology they are preserving;
- which invariants are guaranteed to be preserved;
- the class of transformations used.

Undeclared preservation is not asserted.

## 3. Examples of Topology-Preserving Operations

- continuous deformation (homeomorphism);
- rigid transformation (isometry);
- topology-preserving mesh simplification;
- re-parameterisation of a surface;
- orientation-preserving homeomorphism.

## 4. Contrast: Topology-Changing Operations

Operations that intentionally change topology MUST be explicitly labelled:

```
Merge components     → topology change (reduces β₀)
Create hole          → topology change (increases β₁)
Split component      → topology change (increases β₀)
```

## 5. Invariants

- **TOPOLOGY-INV-007**: Invariant Integrity — claimed preserved invariants MUST be preserved.
- **TOPOLOGY-INV-008**: Transformation Integrity — transformations MUST satisfy their declared semantic effects.
- **TOPOLOGY-INV-011**: State Integrity MUST hold after preservation operations.

---

# Definition Authority

This document defines the normative semantic meaning of the **Preservation** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **Preservation is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
