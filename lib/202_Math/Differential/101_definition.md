# SCR Semantic Library — 202 Math / Differential

**Document:** `lib/202_Math/Differential/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Differential  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Differential Domain** defines differential forms, exterior algebra, differential equations, and infinitesimal transformations on smooth manifolds.

---

## 2. Fundamental Distinction

> **Differentials are not $\Delta x$ float differences; they are linear maps from tangent spaces to the real field.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **DIF-INV-001 (Exterior Derivative Nilpotency):** The exterior derivative MUST satisfy $d(d\omega) = 0$ ($d^2 = 0$).
* **DIF-INV-002 (Stokes' Theorem):** Integration of differential forms MUST satisfy $\int_{\partial \Omega} \omega = \int_\Omega d\omega$.
* **DIF-INV-003 (Smoothness Contract):** Differential structures MUST declare their differentiability class $C^k$.
