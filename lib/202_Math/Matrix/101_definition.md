# SCR Semantic Library — 202 Math / Matrix

**Document:** `lib/202_Math/Matrix/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Matrix  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Matrix Domain** defines rectangular arrays of numbers, symbols, or expressions arranged in rows and columns representing linear transformations and systems of equations.

---

## 2. Fundamental Distinction

> **A matrix is not a 2D float array in row-major order; it is a representation of a linear map $T: V \to W$ relative to chosen bases.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **MTX-INV-001 (Dimension Conformance):** Multiplication $A \cdot B$ is valid if and only if cols(A) == rows(B).
* **MTX-INV-002 (Determinant Multiplicativity):** For square matrices, $\det(AB) = \det(A)\det(B)$ MUST hold.
* **MTX-INV-003 (Transpose Distribution):** The transpose of a product MUST satisfy $(AB)^T = B^T A^T$.
