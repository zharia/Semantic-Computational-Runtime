# SCR Semantic Library — 202 Math / Integral

**Document:** `lib/202_Math/Integral/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Integral  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Integral Domain** defines the theory of integration, Lebesgue measures, line integrals, surface integrals, and numerical quadrature.

---

## 2. Fundamental Distinction

> **Integration is not a Riemann sum loop; it is a measure-theoretic functional mapping integrable functions to scalar quantities.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **INT-INV-001 (Additivity):** For disjoint domains $A \cap B = \emptyset$, $\int_{A \cup B} f = \int_A f + \int_B f$ MUST hold.
* **INT-INV-002 (Monotonicity):** If $f \le g$ on domain $\Omega$, then $\int_\Omega f \le \int_\Omega g$ MUST hold.
* **INT-INV-003 (Boundedness):** Integrals over bounded functions on finite measures MUST yield finite values.
