# SCR Semantic Library — 301 Field / Solvers

**Document:** `lib/301_Field/Solvers/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Solvers  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Solvers Field Subdomain** defines computational engines solving partial and ordinary differential equations governing field evolution (Poisson, Navier-Stokes, Helmholtz, Wave).

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Numerical` and `202_Math/Differential`.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-SLV-001 (Residual Boundedness):** Solver convergence MUST certify that the equation residual $\|L\phi - f\|$ is within declared tolerance.
* **FLD-SLV-002 (Conservation Laws):** Solvers MUST conserve physical quantities declared conservative by the field equation.
* **FLD-SLV-003 (Stability Certification):** Numerical solvers MUST declare stability bounds (e.g. CFL, von Neumann stability).
