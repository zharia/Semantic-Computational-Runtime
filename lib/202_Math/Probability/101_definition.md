# SCR Semantic Library — 202 Math / Probability

**Document:** `lib/202_Math/Probability/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Probability  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Probability Domain** defines the mathematical branch dealing with uncertainty, random events, probability measures, distributions, and stochastic variables.

---

## 2. Fundamental Distinction

> **Probability is not random numbers; it is a Kolmogorov probability space $(\Omega, \mathcal{F}, P)$.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **PRB-INV-001 (Kolmogorov Axiom 1 (Non-negativity)):** $P(E) \ge 0$ for all events $E \in \mathcal{F}$.
* **PRB-INV-002 (Kolmogorov Axiom 2 (Unitarity)):** $P(\Omega) = 1.0$ exactly.
* **PRB-INV-003 (Kolmogorov Axiom 3 (Additivity)):** For mutually exclusive events, $P(\bigcup_i E_i) = \sum_i P(E_i)$.
