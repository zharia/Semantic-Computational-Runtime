# SCR Semantic Library — 301 Field / Advection

**Document:** `lib/301_Field/Advection/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Advection  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Advection Field Subdomain** defines the transport of a field quantity $\phi$ along the flow trajectories of a velocity field $\vec{u}$, described by the material derivative $D\phi/Dt = \partial\phi/\partial t + \vec{u} \cdot \nabla\phi$.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Calculus` and Lagrangian/Eulerian continuum dynamics.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-ADV-001 (Characteristic Tracing):** Along flow streamlines $dx/dt = \vec{u}(x, t)$, field values MUST remain conserved in the absence of source terms.
* **FLD-ADV-002 (Bounded Variation):** Advection of monotone profiles MUST NOT introduce spurious non-physical oscillations.
* **FLD-ADV-003 (CFL Condition):** Discrete advection schemes MUST declare their Courant-Friedrichs-Lewy stability limits.
