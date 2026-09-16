# SCR Semantic Library — 202 Math / Quaternion

**Document:** `lib/202_Math/Quaternion/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Quaternion  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Quaternion Domain** defines the four-dimensional normed division algebra $\mathbb{H}$ extending complex numbers, widely used for spatial rotations in $SO(3)$.

---

## 2. Fundamental Distinction

> **Quaternions form a non-commutative division ring where $i^2 = j^2 = k^2 = ijk = -1$.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **QAT-INV-001 (Hamilton Fundamental Formula):** $i^2 = j^2 = k^2 = ijk = -1$ MUST hold exactly.
* **QAT-INV-002 (Non-Commutativity):** Quaternion multiplication is associative but non-commutative ($ij = k$, $ji = -k$).
* **QAT-INV-003 (Unit Norm Rotation):** Unit quaternions ($\|q\| = 1$) represent spatial rotations in $SO(3)$ without gimbal lock.
