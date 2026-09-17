---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-RENDER-MATERIAL-VDF
name: VDF
version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-RENDER-MATERIAL
authority: SCR
domain: semantic-library
---

# VDF — Volume Distribution Function

**Path:** `lib/A01_Render/Material/VDF/101_definition.md`  
**Version:** 0.1.0  
**Status:** Normative Specification  
**Parent Subdomain:** [`lib/A01_Render/Material`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material)

---

## 1. Definition

Defines volumetric scattering, absorption, and phase functions in participating media, including isotropic phase functions, Henyey-Greenstein anisotropic scattering, and Rayleigh scattering.

---

## 2. Core Concepts

* **Semantic Representation:** First-class mathematical entity within the SCR Material hierarchy.
* **Composition:** Fully composable with parent Material closures and shading networks.
* **Target Independence:** Evaluates independently of target GPU languages, OSL, or raster engines.
* **Hypergraph Projection:** Projects into the canonical hypergraph $\mathcal{H} = (E, R, I, \rho)$ as discrete Elements and Incidence roles.

---

## 3. Normative Invariants

### VDF-INV-001: Phase Normalization

> **Phase functions p_m(wi, wo) MUST integrate to 1 over the full unit sphere S^2.**

### MATERIAL-VDF-INV-002: Determinism
> Evaluation of `VDF` structures produces bitwise identical results given identical inputs and coordinates.

---

## 4. Conformance & Conformance Tests

Any provider implementing `VDF` semantics MUST satisfy the declared invariants under automated verification tests.
