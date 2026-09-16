# SCR Semantic Library — 202 Math / Tensor

**Document:** `lib/202_Math/Tensor/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Tensor  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Tensor Domain** defines multilinear geometric objects describing linear relations between geometric vectors, scalars, and other tensors with explicit transformation rules.

---

## 2. Fundamental Distinction

> **A tensor is not an n-dimensional NumPy array; it is a multilinear map that transforms covariantly and contravariantly under change of basis.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **TNS-INV-001 (Transformation Covariance):** Tensor components MUST transform according to their covariant and contravariant rank under coordinate changes.
* **TNS-INV-002 (Rank Integrity):** The rank and shape of a tensor MUST be preserved across invariant operations.
* **TNS-INV-003 (Contraction Consistency):** Tensor contraction MUST be invariant under basis changes.
