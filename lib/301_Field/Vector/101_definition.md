# SCR Semantic Library — 301 Field / Vector

**Document:** `lib/301_Field/Vector/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Vector  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Vector Field Subdomain** defines the semantic structure defining fields whose values at every domain point are elements of a vector space 𝕍, transforming contravariantly under coordinate frame changes.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Vector`, representing velocity fields, force fields, and gradient vector fields.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-VEC-001 (Contravariant Transformation):** Vector field components MUST transform contravariantly under change of spatial coordinates.
* **FLD-VEC-002 (Dimension Uniformity):** Every point in the field domain MUST evaluate to a vector of the declared dimensionality.
* **FLD-VEC-003 (Inner Product Preserving):** Evaluation of vector field dot products MUST conform to `202_Math/Vector` inner product axioms.
