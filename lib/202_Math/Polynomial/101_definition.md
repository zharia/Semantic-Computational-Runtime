# SCR Semantic Library — 202 Math / Polynomial

**Document:** `lib/202_Math/Polynomial/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Polynomial  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Polynomial Domain** defines algebraic expressions consisting of variables and coefficients involving only addition, subtraction, multiplication, and non-negative integer exponentiation.

---

## 2. Fundamental Distinction

> **Polynomials form a commutative ring $R[x]$ with unique factorization and root multiplicities.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **POL-INV-001 (Degree Axiom):** The degree of the product of non-zero polynomials over an integral domain MUST equal the sum of their degrees: $\deg(pq) = \deg(p) + \deg(q)$.
* **POL-INV-002 (Fundamental Theorem of Algebra):** A polynomial of degree $n$ over $\mathbb{C}$ has exactly $n$ roots counting multiplicity.
* **POL-INV-003 (Evaluation Soundness):** Polynomial evaluation MUST be invariant under Horner's method vs expanded form.
