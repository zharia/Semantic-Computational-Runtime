# SCR Semantic Library — 301 Field / Transformation

**Document:** `lib/301_Field/Transformation/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Transformation  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Transformation Field Subdomain** defines pullback, pushforward, and coordinate transformations of fields under spatial diffeomorphisms $y = \Phi(x)$.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Differential` and differential geometry.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-TRF-001 (Pullback Invariant):** For scalar fields, the pullback $\Phi^*\phi = \phi \circ \Phi$ MUST preserve scalar values.
* **FLD-TRF-002 (Jacobian Scaling for Densities):** Volume density fields MUST scale by the determinant of the Jacobian $\det(J_\Phi)$.
* **FLD-TRF-003 (Invertibility):** Diffeomorphic transformations MUST declare their inverse mapping $\Phi^{-1}$.
