---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-RENDER-MATERIAL-BSDF
name: BSDF
version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-RENDER-MATERIAL
authority: SCR
domain: semantic-library
---

# BSDF — Bidirectional Scattering Distribution Function

**Path:** `lib/A01_Render/Material/BSDF/101_definition.md`  
**Version:** 0.1.0  
**Status:** Normative Specification  
**Parent Subdomain:** [`lib/A01_Render/Material`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material)

---

## 1. Definition

Defines physical surface reflectance and transmittance distributions over spherical incident and exitant directions, including diffuse Lambertian/Burley, dielectric Fresnel, microfacet GGX/Beckmann conductor models, and sheen.

---

## 2. Core Concepts

* **Semantic Representation:** First-class mathematical entity within the SCR Material hierarchy.
* **Composition:** Fully composable with parent Material closures and shading networks.
* **Target Independence:** Evaluates independently of target GPU languages, OSL, or raster engines.
* **Hypergraph Projection:** Projects into the canonical hypergraph $\mathcal{H} = (E, R, I, \rho)$ as discrete Elements and Incidence roles.

---

## 3. Normative Invariants

### BSDF-INV-001: Reciprocity and Energy Conservation

> **A conforming BSDF model MUST satisfy Helmholtz reciprocity f_r(wi, wo) = f_r(wo, wi) for non-magnetic media and must not scatter more flux than is incident (integral <= 1).**

### MATERIAL-BSDF-INV-002: Determinism
> Evaluation of `BSDF` structures produces bitwise identical results given identical inputs and coordinates.

---

## 4. Conformance & Conformance Tests

Any provider implementing `BSDF` semantics MUST satisfy the declared invariants under automated verification tests.
