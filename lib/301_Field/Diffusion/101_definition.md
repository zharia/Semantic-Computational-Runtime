# SCR Semantic Library — 301 Field / Diffusion

**Document:** `lib/301_Field/Diffusion/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Diffusion  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Diffusion Field Subdomain** defines the spontaneous net transport of matter, energy, or field concentration down a gradient, governed by parabolic PDE $\partial\phi/\partial t = D \nabla^2 \phi$.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Calculus` and parabolic differential equations.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-DIF-001 (Entropy / Smoothing Invariant):** Diffusion MUST non-strictly decrease total field variance/energy over time: $\frac{d}{dt} \int |\nabla \phi|^2 dV \le 0$.
* **FLD-DIF-002 (Non-Negativity Preservation):** Diffusion of a non-negative concentration field MUST NOT produce negative values.
* **FLD-DIF-003 (Maximum Principle):** The extrema of the diffused field must occur at the initial time or domain boundary.
