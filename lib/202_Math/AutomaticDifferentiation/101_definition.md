# SCR Semantic Library — 202 Math / AutomaticDifferentiation

**Document:** `lib/202_Math/AutomaticDifferentiation/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / AutomaticDifferentiation  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **AutomaticDifferentiation Domain** defines the algorithmic evaluation of exact derivatives of functions specified by computer programs using dual numbers (forward mode) or adjoint computational graphs (reverse mode).

---

## 2. Fundamental Distinction

> **Automatic differentiation is not finite differences; it evaluates analytical derivatives to machine precision by applying the chain rule to elementary operations.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **AD-INV-001 (Exactness to Precision):** Derivatives computed via automatic differentiation MUST NOT introduce discretization truncation error.
* **AD-INV-002 (Chain Rule Invariance):** Composition of differentiable operations MUST strictly satisfy the chain rule $D(f \circ g) = (Df \circ g) \cdot Dg$.
* **AD-INV-003 (Dual Algebra Soundness):** Forward-mode AD MUST evaluate over dual numbers satisfying $\epsilon^2 = 0$.
