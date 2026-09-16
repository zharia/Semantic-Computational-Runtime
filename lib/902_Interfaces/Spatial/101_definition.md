# SCR Semantic Library — 902 Interfaces / Spatial

**Document:** `lib/902_Interfaces/Spatial/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Spatial  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Spatial Interface** defines the semantic interface embedding computational entities within an explicit continuous or discrete spatial coordinate space.

---

## 2. Fundamental Distinction

> **Spatial is not a Vec3 struct; it is an embedding in a defined metric space $(M, d)$ with coordinate reference systems.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **SPT-INV-001 (Metric Reference Explicitness):** Spatial coordinates MUST declare their metric, dimensionality, and coordinate frame.
* **SPT-INV-002 (Transformation Covariance):** Spatial operations MUST transform covariantly under coordinate frame changes.
* **SPT-INV-003 (Distance Function Soundness):** Distance evaluations MUST satisfy metric space axioms (triangle inequality, identity).
