# SCR Semantic Library — 202 Math / Vector

**Document:** `lib/202_Math/Vector/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Vector  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Vector Domain** defines elements of a vector space $\mathbb{V}$ equipped with vector addition and scalar multiplication, possessing magnitude and direction.

---

## 2. Fundamental Distinction

> **A vector is not a flat float array; it is an element of a vector space that transforms contravariantly under basis changes.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **VEC-INV-001 (Vector Space Axioms):** Vectors MUST satisfy commutativity, associativity, additive identity, inverse, and distributivity of scalar multiplication.
* **VEC-INV-002 (Inner Product Positivity):** Inner products MUST satisfy $\langle v, v \rangle \ge 0$, with equality if and only if $v = 0$.
* **VEC-INV-003 (Triangle Inequality):** The induced norm MUST satisfy $\|u + v\| \le \|u\| + \|v\|$.
