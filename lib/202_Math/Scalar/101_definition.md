# SCR Semantic Library — 202 Math / Scalar

**Document:** `lib/202_Math/Scalar/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Scalar  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Scalar Domain** defines one-dimensional mathematical quantities that can be described by a single real, complex, rational, or integer value, invariant under coordinate rotation.

---

## 2. Fundamental Distinction

> **A scalar is not an IEEE 754 float variable; it is a 0-tensor invariant under coordinate transformations.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **SCL-INV-001 (Rotational Invariance):** A scalar quantity MUST remain invariant under coordinate frame transformations.
* **SCL-INV-002 (Total Ordering of Reals):** Real scalars MUST obey total ordering (trichotomy).
* **SCL-INV-003 (Field Operations):** Scalars participating in a field MUST support addition, subtraction, multiplication, and non-zero division.
