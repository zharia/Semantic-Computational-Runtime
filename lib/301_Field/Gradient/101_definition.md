# SCR Semantic Library — 301 Field / Gradient

**Document:** `lib/301_Field/Gradient/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Gradient  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Gradient Field Subdomain** defines the differential vector operator mapping a differentiable scalar field $\phi$ to a vector field $\nabla \phi$ pointing in the direction of greatest rate of increase.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Calculus` and `202_Math/Differential`, representing the exterior derivative $d\phi$ converted to a vector via the metric.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-GRD-001 (Orthogonality to Level Sets):** The gradient $\nabla \phi$ MUST be orthogonal to the tangent space of the level set $\phi(x) = c$.
* **FLD-GRD-002 (Magnitude as Directional Maximum):** The norm $\|\nabla \phi\|$ MUST equal the maximum directional derivative of $\phi$ at that point.
* **FLD-GRD-003 (Curl-Free Invariant):** For any twice continuously differentiable scalar field, $\nabla \times (\nabla \phi) = \vec{0}$ MUST hold identically.
