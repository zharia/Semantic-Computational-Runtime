# SCR Semantic Library — 202 Math / Complex

**Document:** `lib/202_Math/Complex/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Complex  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Complex Domain** defines the field of complex numbers $\mathbb{C} = \{a + bi \mid a,b \in \mathbb{R}, i^2 = -1\}$ and holomorphic functions defined over the complex plane.

---

## 2. Fundamental Distinction

> **Complex numbers are not a struct of two floats; they form an algebraically closed field satisfying the fundamental theorem of algebra.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **CPX-INV-001 (Imaginary Unit Axiom):** The imaginary unit MUST satisfy $i^2 = -1$ exactly.
* **CPX-INV-002 (Field Axioms):** Complex addition and multiplication MUST satisfy all mathematical field axioms.
* **CPX-INV-003 (Conjugate Symmetry):** Complex conjugation MUST satisfy $\overline{z_1 z_2} = \overline{z_1} \cdot \overline{z_2}$ and $z \overline{z} = |z|^2$.
