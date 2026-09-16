# SCR Semantic Library — 902 Interfaces / Optimizable

**Document:** `lib/902_Interfaces/Optimizable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Optimizable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Optimizable Interface** defines the semantic interface exposing objective functions, decision variables, and constraint spaces for mathematical optimization.

---

## 2. Fundamental Distinction

> **Optimizable is not a gradient descent loop; it is the mathematical problem formulation $\min f(x)$ subject to $g(x) \le 0$.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **OPT-INV-001 (Feasibility Verification):** Constraints MUST be explicitly testable for candidate solution points.
* **OPT-INV-002 (Objective Monotonicity):** Optimization steps MUST certify non-deterioration of the declared objective function.
* **OPT-INV-003 (Optimality Criteria):** Convergence conditions (KKT, duality gap, tolerance) MUST be declared.
