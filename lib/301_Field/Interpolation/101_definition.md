# SCR Semantic Library — 301 Field / Interpolation

**Document:** `lib/301_Field/Interpolation/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Interpolation  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Interpolation Field Subdomain** defines the mathematical reconstruction of continuous field values from discrete sample nodes using basis functions.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Interpolation`.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-ITP-001 (Exact Node Value Preservation):** Interpolation at an exact node coordinate $x_i$ MUST return $y_i$ without error.
* **FLD-ITP-002 (Order of Accuracy):** Interpolation schemes MUST declare their asymptotic convergence order $O(h^p)$.
* **FLD-ITP-003 (Continuity Order):** Interpolants MUST declare their continuity class ($C^0, C^1, C^2$).
