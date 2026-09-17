---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-RENDER-MATERIAL-VOLUME
name: Volume
version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-RENDER-MATERIAL
authority: SCR
domain: semantic-library
---

# Volume — Participating Media

**Path:** `lib/A01_Render/Material/Volume/101_definition.md`  
**Version:** 0.1.0  
**Status:** Normative Specification  
**Parent Subdomain:** [`lib/A01_Render/Material`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material)

---

## 1. Definition

Defines bulk optical properties of volumetric media, including extinction coefficients, single-scattering albedo, interior index of refraction, and heterogeneous density field couplings.

---

## 2. Core Concepts

* **Semantic Representation:** First-class mathematical entity within the SCR Material hierarchy.
* **Composition:** Fully composable with parent Material closures and shading networks.
* **Target Independence:** Evaluates independently of target GPU languages, OSL, or raster engines.
* **Hypergraph Projection:** Projects into the canonical hypergraph $\mathcal{H} = (E, R, I, \rho)$ as discrete Elements and Incidence roles.

---

## 3. Normative Invariants

### VOLUME-INV-001: Extinction Consistency

> **Total extinction sigma_t MUST equal the exact sum of absorption sigma_a and scattering sigma_s.**

### MATERIAL-VOLUME-INV-002: Determinism
> Evaluation of `Volume` structures produces bitwise identical results given identical inputs and coordinates.

---

## 4. Conformance & Conformance Tests

Any provider implementing `Volume` semantics MUST satisfy the declared invariants under automated verification tests.
