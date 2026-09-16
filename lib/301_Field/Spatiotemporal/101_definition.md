# SCR Semantic Library — 301 Field / Spatiotemporal

**Document:** `lib/301_Field/Spatiotemporal/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Spatiotemporal  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Spatiotemporal Field Subdomain** defines unified fields $\phi(x, t)$ defined over product domains $\Omega \times T$ of space and time.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `801_Spatial`, `802_Stream`, and `202_Math` multidimensional analysis.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-STP-001 (Product Space Decomposition):** Evaluation MUST support spatial slicing at fixed $t$ and temporal tracing at fixed $x$.
* **FLD-STP-002 (Relativistic / Galilean Invariance):** Spatiotemporal transformations MUST preserve declared physical relativity invariants.
* **FLD-STP-003 (Mixed Derivatives):** Mixed partial derivatives $\frac{\partial^2 \phi}{\partial t \partial x_i} = \frac{\partial^2 \phi}{\partial x_i \partial t}$ MUST hold for $C^2$ fields.
