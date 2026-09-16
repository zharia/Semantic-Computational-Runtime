# SCR Semantic Library — 301 Field / Extrapolation

**Document:** `lib/301_Field/Extrapolation/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Extrapolation  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Extrapolation Field Subdomain** defines the semantic evaluation of a field outside its declared spatial or temporal domain boundaries.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Approximation`.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-EXT-001 (Extrapolation Transparency):** Evaluation outside $\Omega$ MUST declare extrapolation status or error.
* **FLD-EXT-002 (Clamping & Fallback):** Extrapolation policies (Clamped, Zero, Decaying, Error) MUST be deterministically enforced.
* **FLD-EXT-003 (Uncertainty Growth):** Extrapolated values MUST increase declared uncertainty bounds with distance from the domain.
