# SCR Semantic Library — 301 Field / Sampling

**Document:** `lib/301_Field/Sampling/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Sampling  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Sampling Field Subdomain** defines the selection of discrete sample points in the field domain and assignment of integration quadrature weights.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Integral` and `202_Math/Numerical`.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-SMP-001 (Measure Preservation):** Quadrature sample weights $\sum w_i$ MUST equal the total measure of the sampled domain $\text{Vol}(\Omega)$.
* **FLD-SMP-002 (Nyquist Limit Conformance):** Sampling frequency MUST satisfy Shannon-Nyquist bounds for band-limited fields.
* **FLD-SMP-003 (Point Uniqueness):** Sampling sets MUST not contain duplicate coordinates with conflicting weights.
