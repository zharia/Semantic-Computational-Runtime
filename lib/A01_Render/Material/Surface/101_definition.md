---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-RENDER-MATERIAL-SURFACE
name: Surface
version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-RENDER-MATERIAL
authority: SCR
domain: semantic-library
---

# Surface — Physical Surface Appearance

**Path:** `lib/A01_Render/Material/Surface/101_definition.md`  
**Version:** 0.1.0  
**Status:** Normative Specification  
**Parent Subdomain:** [`lib/A01_Render/Material`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material)

---

## 1. Definition

Defines physical surface parameters and microgeometry properties, including base albedo, surface roughness (isotropic and anisotropic), metallic factor, normal perturbation, and clearcoat.

---

## 2. Core Concepts

* **Semantic Representation:** First-class mathematical entity within the SCR Material hierarchy.
* **Composition:** Fully composable with parent Material closures and shading networks.
* **Target Independence:** Evaluates independently of target GPU languages, OSL, or raster engines.
* **Hypergraph Projection:** Projects into the canonical hypergraph $\mathcal{H} = (E, R, I, \rho)$ as discrete Elements and Incidence roles.

---

## 3. Normative Invariants

### SURFACE-INV-001: Normalized Roughness

> **Roughness parameters MUST be constrained to [0.0, 1.0] where 0 represents an optically smooth specular surface and 1 represents maximal microfacet dispersion.**

### MATERIAL-SURFACE-INV-002: Determinism
> Evaluation of `Surface` structures produces bitwise identical results given identical inputs and coordinates.

---

## 4. Conformance & Conformance Tests

Any provider implementing `Surface` semantics MUST satisfy the declared invariants under automated verification tests.
