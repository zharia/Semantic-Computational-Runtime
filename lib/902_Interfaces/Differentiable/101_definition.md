# SCR Semantic Library — 902 Interfaces / Differentiable

**Document:** `lib/902_Interfaces/Differentiable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Differentiable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Differentiable Interface** defines the semantic capability exposing formal derivative, gradient, Jacobian, or VJP/JVP pullback operations over continuous computational spaces.

---

## 2. Fundamental Distinction

> **Differentiability is not PyTorch autograd or reverse-mode tape; it is the mathematical property of admitting tangent and cotangent linear transformations.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **DIF-INV-001 (Derivative Consistency):** Reverse-mode (VJP) and forward-mode (JVP) evaluations MUST be numerically consistent within declared tolerances.
* **DIF-INV-002 (Smoothness Domain):** The domain over which differentiability holds (continuous, piecewise smooth) MUST be explicitly bounded.
* **DIF-INV-003 (Higher-Order Preservation):** Higher-order derivative orders supported MUST be declared in the interface contract.
