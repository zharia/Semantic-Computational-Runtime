# SCR Semantic Library — 301 Field / Spatial

**Document:** `lib/301_Field/Spatial/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Spatial  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Spatial Field Subdomain** defines fields whose underlying domain is embedded within a physical or abstract spatial metric space $(M, d)$ defined in `801_Spatial`.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `801_Spatial` and `202_Math/Vector`.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-SPT-001 (Metric Invariance):** Spatial distance between domain points MUST satisfy metric space axioms.
* **FLD-SPT-002 (Reference Frame Tracking):** Spatial fields MUST explicitly reference their spatial coordinate system and datum.
* **FLD-SPT-003 (Boundary Boundedness):** Spatial domains MUST declare finite or infinite boundary bounding hulls.
