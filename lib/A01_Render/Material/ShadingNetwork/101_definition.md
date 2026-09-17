---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-RENDER-MATERIAL-SHADINGNETWORK
name: ShadingNetwork
version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-RENDER-MATERIAL
authority: SCR
domain: semantic-library
---

# ShadingNetwork — Dataflow Shading Network

**Path:** `lib/A01_Render/Material/ShadingNetwork/101_definition.md`  
**Version:** 0.1.0  
**Status:** Normative Specification  
**Parent Subdomain:** [`lib/A01_Render/Material`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material)

---

## 1. Definition

Defines directed acyclic dataflow networks composed of computational nodes, typed input/output ports, parameters, and tokens computing procedural values, texture samples, and closure trees.

---

## 2. Core Concepts

* **Semantic Representation:** First-class mathematical entity within the SCR Material hierarchy.
* **Composition:** Fully composable with parent Material closures and shading networks.
* **Target Independence:** Evaluates independently of target GPU languages, OSL, or raster engines.
* **Hypergraph Projection:** Projects into the canonical hypergraph $\mathcal{H} = (E, R, I, \rho)$ as discrete Elements and Incidence roles.

---

## 3. Normative Invariants

### SHADINGNET-INV-001: Directed Acyclicity

> **Shading networks MUST be strictly acyclic DAGs without self-referential or cyclic dependency edges.**

### MATERIAL-SHADINGNETWORK-INV-002: Determinism
> Evaluation of `ShadingNetwork` structures produces bitwise identical results given identical inputs and coordinates.

---

## 4. Conformance & Conformance Tests

Any provider implementing `ShadingNetwork` semantics MUST satisfy the declared invariants under automated verification tests.
