# SCR Semantic Library — 301 Field / Laplacian

**Document:** `lib/301_Field/Laplacian/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Laplacian  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Laplacian Field Subdomain** defines the second-order differential operator $\nabla^2 = \nabla \cdot \nabla$ measuring the difference between the field value at a point and the average of values in its infinitesimal neighborhood.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Calculus` and harmonic analysis.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-LAP-001 (Composition Soundness):** $\nabla^2 \phi$ MUST equal $\nabla \cdot (\nabla \phi)$ for scalar fields.
* **FLD-LAP-002 (Harmonic Functions):** Harmonic fields satisfying $\nabla^2 \phi = 0$ MUST satisfy the mean value property and maximum principle.
* **FLD-LAP-003 (Negative Semi-Definite):** The Laplacian operator with homogeneous Dirichlet boundaries MUST be self-adjoint and negative semi-definite.
