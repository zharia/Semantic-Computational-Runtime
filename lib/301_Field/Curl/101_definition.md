# SCR Semantic Library — 301 Field / Curl

**Document:** `lib/301_Field/Curl/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Curl  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Curl Field Subdomain** defines the differential vector operator mapping a 3D vector field $\vec{v}$ to another 3D vector field $\nabla \times \vec{v}$ representing infinitesimal rotation or circulation.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Calculus` and Stokes' Theorem.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-CRL-001 (Circulation Equivalence):** Surface integral of curl MUST equal the boundary line integral: $\int_S (\nabla \times \vec{v}) \cdot d\vec{A} = \oint_{\partial S} \vec{v} \cdot d\vec{r}$.
* **FLD-CRL-002 (Divergence of Curl is Zero):** For any twice continuously differentiable vector field, $\nabla \cdot (\nabla \times \vec{v}) = 0$ MUST hold identically.
* **FLD-CRL-003 (Irrotational Fields):** Conservative vector fields with a scalar potential $\vec{v} = \nabla \phi$ MUST satisfy $\nabla \times \vec{v} = \vec{0}$.
