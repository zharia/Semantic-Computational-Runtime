---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-PHYSICS-MATERIAL
name: Physics Material

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-PHYSICS
authority: SCR
domain: semantic-library
---

# SCR Physics: Material

## Summary

Constitutive properties (density, Young's modulus, Poisson ratio, viscosity, conductivity) of physical media.

---

## 1. Semantic Definition

**Material** is a first-class subdomain of SCR Physics (`SCR-LIB-PHYSICS`). It defines constitutive properties (density, Young's modulus, Poisson ratio, viscosity, conductivity) of physical media.

Physics defines physical meaning independently of transient numerical solvers, graphics engines, or hardware acceleration substrates.

## 2. Invariant Conformance

All operations within `Material` MUST adhere to the normative invariants of `SCR-LIB-PHYSICS`:

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
- **lib/A01_Render/Material**: Supplies complementary optical appearance contracts and shading closures for universal materials cataloged in [`105_unified_materials_catalog.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/105_unified_materials_catalog.md) and [`materials_catalog.json`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/materials_catalog.json).
- **docs/architecture/106_unified_materials_ontology.md**: Establishes the authoritative [`Universal Materials Ontology`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/architecture/106_unified_materials_ontology.md).

---

# Definition Authority

This document establishes the normative semantic meaning of `Material` in SCR Physics. Numerical engines, solvers, and simulation runtimes are subordinate to the contracts specified herein.
