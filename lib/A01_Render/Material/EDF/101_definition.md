---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-RENDER-MATERIAL-EDF
name: EDF
version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-RENDER-MATERIAL
authority: SCR
domain: semantic-library
---

# EDF — Emission Distribution Function

**Path:** `lib/A01_Render/Material/EDF/101_definition.md`  
**Version:** 0.1.0  
**Status:** Normative Specification  
**Parent Subdomain:** [`lib/A01_Render/Material`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material)

---

## 1. Definition

Defines directional radiance emission from surfaces and boundaries, governing uniform Lambertian emission, directional conical spotlights, and measured goniometric light profiles.

---

## 2. Core Concepts

* **Semantic Representation:** First-class mathematical entity within the SCR Material hierarchy.
* **Composition:** Fully composable with parent Material closures and shading networks.
* **Target Independence:** Evaluates independently of target GPU languages, OSL, or raster engines.
* **Hypergraph Projection:** Projects into the canonical hypergraph $\mathcal{H} = (E, R, I, \rho)$ as discrete Elements and Incidence roles.

---

## 3. Normative Invariants

### EDF-INV-001: Non-Negative Emission

> **Emitted radiance L_e(p, wo) MUST evaluate to non-negative values across all directions and wavelengths.**

### MATERIAL-EDF-INV-002: Determinism
> Evaluation of `EDF` structures produces bitwise identical results given identical inputs and coordinates.

---

## 4. Conformance & Conformance Tests

Any provider implementing `EDF` semantics MUST satisfy the declared invariants under automated verification tests.
