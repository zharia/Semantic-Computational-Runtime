---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-PHYSICS-BODY
name: Physics Body

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-PHYSICS
authority: SCR
domain: semantic-library
---

# SCR Physics: Body

## Summary

Physical entity possessing mass, spatial bounds, kinematic state, and material constitution.

---

## 1. Semantic Definition

**Body** is a first-class subdomain of SCR Physics (`SCR-LIB-PHYSICS`). It defines physical entity possessing mass, spatial bounds, kinematic state, and material constitution.

Physics defines physical meaning independently of transient numerical solvers, graphics engines, or hardware acceleration substrates.

## 2. Invariant Conformance

All operations within `Body` MUST adhere to the normative invariants of `SCR-LIB-PHYSICS`:

- **PHYSICS-INV-001 (Semantic Primacy)**: Physical meaning is authoritative and independent of solver implementations.
- **PHYSICS-INV-002 (Quantity Integrity)**: Physical quantities retain dimensional consistency, magnitude, and unit semantics.
- **PHYSICS-INV-003 (Law Integrity)**: Physical laws remain distinct from their numerical discretization or engine approximations.
- **PHYSICS-INV-006 (Conservation Integrity)**: Declared conservation relationships must be representable and verifiable independently of integration error.
- **PHYSICS-INV-014 (Dimensional Integrity)**: Equations and relations MUST preserve strict dimensional consistency.
- **PHYSICS-INV-018 (Runtime Independence)**: Physical semantics remain independent of host runtime and hardware substrates.

## 3. Relationships to Other Domains

- **lib/101_Core/Identity**: Supplies canonical `SemanticId` identifiers for physical entities, bodies, and interactions.
- **lib/202_Math**: Provides algebra, calculus, tensors, and numerical analysis infrastructure.
- **lib/203_Graph/Hypergraph**: Provides the canonical hypergraph representation for multi-body interactions and constraint graphs.
- **lib/302_Geometry**: Supplies spatial frames, collision shapes, and coordinate spaces.
- **lib/303_Topology**: Supplies boundary connectivity and continuity invariants.

---

# Definition Authority

This document establishes the normative semantic meaning of `Body` in SCR Physics. Numerical engines, solvers, and simulation runtimes are subordinate to the contracts specified herein.
