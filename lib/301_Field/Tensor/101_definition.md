# SCR Semantic Library — 301 Field / Tensor

**Document:** `lib/301_Field/Tensor/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Tensor  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Tensor Field Subdomain** defines the semantic structure defining fields whose values at every domain point are tensors of rank (r, s), transforming multilinearly under basis changes.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Tensor`, representing stress tensors, strain rate tensors, metric tensors, and diffusion tensors.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-TNS-001 (Multilinear Covariance):** Tensor field components MUST transform according to their covariant and contravariant rank.
* **FLD-TNS-002 (Symmetry Preservation):** Symmetric or anti-symmetric tensor fields MUST preserve their algebraic symmetry under coordinate transformations.
* **FLD-TNS-003 (Trace and Contraction Invariance):** Contraction of tensor fields MUST yield basis-independent lower-rank fields.
