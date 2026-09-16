# SCR Semantic Library — 202 Math / Dual

**Document:** `lib/202_Math/Dual/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Dual  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Dual Domain** defines the algebra of dual numbers $a + b\epsilon$ where $\epsilon \neq 0$ and $\epsilon^2 = 0$, providing hypercomplex foundations for kinematics and exact forward differentiation.

---

## 2. Fundamental Distinction

> **Dual numbers are an associative unital algebra extending the reals with an infinitesimal nilpotent element.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **DUL-INV-001 (Nilpotency):** The dual unit $\epsilon$ MUST satisfy $\epsilon^2 = 0$ exactly.
* **DUL-INV-002 (Taylor Truncation Identity):** For any analytic function $f$, $f(a + b\epsilon) = f(a) + b f'(a)\epsilon$ MUST hold identically.
* **DUL-INV-003 (Ring Structure):** Dual numbers MUST form a commutative ring with identity.
