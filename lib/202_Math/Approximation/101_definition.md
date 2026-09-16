# SCR Semantic Library — 202 Math / Approximation

**Document:** `lib/202_Math/Approximation/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Approximation  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Approximation Domain** defines the semantic domain governing inexact representations, asymptotic expansions, Taylor series, Chebyshev approximations, and bounded error bounds.

---

## 2. Fundamental Distinction

> **Approximation is not floating-point rounding error; it is an intentional mathematical mapping from an exact mathematical entity to a simpler or computable surrogate with explicit error bounds.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **APP-INV-001 (Error Bound Explicitness):** Approximations MUST declare strict upper bounds on absolute or relative error.
* **APP-INV-002 (Convergence Domain):** The domain of convergence over which the approximation is valid MUST be explicitly stated.
* **APP-INV-003 (No Masking):** Approximations MUST NOT masquerade as exact mathematical entities.
