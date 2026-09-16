# SCR Semantic Library — 202 Math / Optimization

**Document:** `lib/202_Math/Optimization/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Optimization  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Optimization Domain** defines the mathematical theory and algorithms for finding the minima or maxima of objective functions subject to constraints.

---

## 2. Fundamental Distinction

> **Optimization is not gradient descent heuristic tuning; it is the mathematical characterization of extrema over constrained manifolds.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **OPT-INV-001 (Feasibility):** Optimal solutions MUST strictly satisfy all active equality and inequality constraints.
* **OPT-INV-002 (First-Order Optimality):** At unconstrained local minima, the gradient $\nabla f(x^*)$ MUST equal zero.
* **OPT-INV-003 (Convexity Guarantees):** Convex optimization problems MUST guarantee that local minima are global minima.
