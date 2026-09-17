---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-RENDER-MATERIAL-PROPERTY
name: Property
version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-RENDER-MATERIAL
authority: SCR
domain: semantic-library
---

# Property — Optical Material Properties

**Path:** `lib/A01_Render/Material/Property/101_definition.md`  
**Version:** 0.1.0  
**Status:** Normative Specification  
**Parent Subdomain:** [`lib/A01_Render/Material`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material)

---

## 1. Definition

Defines physical optical constants, complex indices of refraction (n, k), Abbe numbers, dispersion coefficients, and parameter unit dimensions.

---

## 2. Core Concepts

* **Semantic Representation:** First-class mathematical entity within the SCR Material hierarchy.
* **Composition:** Fully composable with parent Material closures and shading networks.
* **Target Independence:** Evaluates independently of target GPU languages, OSL, or raster engines.
* **Hypergraph Projection:** Projects into the canonical hypergraph $\mathcal{H} = (E, R, I, \rho)$ as discrete Elements and Incidence roles.

---

## 3. Normative Invariants

### PROPERTY-INV-001: Dimension Integrity

> **Material parameters MUST declare unambiguous measurement units (e.g., nanometers, microns, dimensionless ratios).**

### MATERIAL-PROPERTY-INV-002: Determinism
> Evaluation of `Property` structures produces bitwise identical results given identical inputs and coordinates.

---

## 4. Conformance & Conformance Tests

Any provider implementing `Property` semantics MUST satisfy the declared invariants under automated verification tests.
