# SCR Semantic Library — 202 Math / Calculus

**Document:** `lib/202_Math/Calculus/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Calculus  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Calculus Domain** defines the mathematical study of continuous change, encompassing differential calculus (rates of change, slopes) and integral calculus (accumulation, areas).

---

## 2. Fundamental Distinction

> **Calculus is not numerical loops; it is the formal mathematical framework of limits, continuity, derivatives, integrals, and differential forms.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **CAL-INV-001 (Fundamental Theorem):** Differentiation and integration MUST satisfy the Fundamental Theorem of Calculus: $\int_a^b f'(x)dx = f(b) - f(a)$.
* **CAL-INV-002 (Continuity Requirement):** Operations requiring continuity or differentiability MUST enforce domain validity.
* **CAL-INV-003 (Linearity):** Differentiation and integration MUST be strictly linear operators.
