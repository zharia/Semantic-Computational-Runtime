# SCR Semantic Library — 902 Interfaces / Integrable

**Document:** `lib/902_Interfaces/Integrable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Integrable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Integrable Interface** defines the semantic capability admitting numerical or analytical integration over temporal, spatial, manifold, or measure-theoretic domains.

---

## 2. Fundamental Distinction

> **Integrable is not Runge-Kutta 4 in C; it is the mathematical guarantee that a field or rate function admits measure-preserving accumulation.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **INT-INV-001 (Measure Definition):** The domain measure (Lebesgue, surface area, volume) MUST be explicitly defined.
* **INT-INV-002 (Order of Accuracy):** Numerical integrators satisfying the interface MUST declare minimum convergence orders.
* **INT-INV-003 (Symplectic Preservation):** Hamiltonian systems MUST require symplectic integration to conserve phase space volume.
