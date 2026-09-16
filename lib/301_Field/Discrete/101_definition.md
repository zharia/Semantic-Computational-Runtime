# SCR Semantic Library — 301 Field / Discrete

**Document:** `lib/301_Field/Discrete/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Discrete  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Discrete Field Subdomain** defines the semantic classification of fields defined at discrete sample locations, lattice nodes, mesh vertices, or voxel centers.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Approximation` and `202_Math/Interpolation`.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-DSC-001 (Sample Topology Explicitness):** Discrete fields MUST declare their node topology (regular Cartesian grid, rectilinear, curvilinear, unstructured simplex).
* **FLD-DSC-002 (Interpolation Coupling):** Evaluation between discrete nodes MUST explicitly declare its interpolation semantics.
* **FLD-DSC-003 (Resolution Transparency):** Grid spacing $\Delta x$ and sample resolution MUST be explicitly parameterized.
