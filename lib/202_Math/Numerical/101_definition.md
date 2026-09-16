# SCR Semantic Library — 202 Math / Numerical

**Document:** `lib/202_Math/Numerical/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Numerical  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Numerical Domain** defines algorithms for solving mathematical problems with real numbers, floating-point analysis, error propagation, and stability.

---

## 2. Fundamental Distinction

> **Numerical methods are not approximate hacks; they are rigorous algorithms with proven convergence rates, condition numbers, and backward stability.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **NUM-INV-001 (Stability Declaration):** Numerical algorithms MUST declare their stability characteristics and condition number bounds.
* **NUM-INV-002 (Error Classification):** Truncation error and roundoff error MUST be mathematically distinguishable.
* **NUM-INV-003 (Convergence Guarantee):** Iterative methods MUST declare verifiable termination and convergence criteria.
