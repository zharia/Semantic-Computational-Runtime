---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-RENDER-MATERIAL-DISPLACEMENT
name: Displacement
version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-RENDER-MATERIAL
authority: SCR
domain: semantic-library
---

# Displacement — Geometric Surface Relief

**Path:** `lib/A01_Render/Material/Displacement/101_definition.md`  
**Version:** 0.1.0  
**Status:** Normative Specification  
**Parent Subdomain:** [`lib/A01_Render/Material`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material)

---

## 1. Definition

Defines scalar and vector displacement fields evaluated at render time to modulate surface geometric boundaries, including heightfield offset and tangent-space vector displacement.

---

## 2. Core Concepts

* **Semantic Representation:** First-class mathematical entity within the SCR Material hierarchy.
* **Composition:** Fully composable with parent Material closures and shading networks.
* **Target Independence:** Evaluates independently of target GPU languages, OSL, or raster engines.
* **Hypergraph Projection:** Projects into the canonical hypergraph $\mathcal{H} = (E, R, I, \rho)$ as discrete Elements and Incidence roles.

---

## 3. Normative Invariants

### DISPLACEMENT-INV-001: Bound Preservation

> **Displacement shaders MUST declare finite upper and lower bounds to preserve ray-tracing bounding volume hierarchy acceleration.**

### MATERIAL-DISPLACEMENT-INV-002: Determinism
> Evaluation of `Displacement` structures produces bitwise identical results given identical inputs and coordinates.

---

## 4. Conformance & Conformance Tests

Any provider implementing `Displacement` semantics MUST satisfy the declared invariants under automated verification tests.
