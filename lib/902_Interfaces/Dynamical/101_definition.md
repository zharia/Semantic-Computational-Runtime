# SCR Semantic Library — 902 Interfaces / Dynamical

**Document:** `lib/902_Interfaces/Dynamical/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Dynamical  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Dynamical Interface** defines the semantic interface representing time-varying state evolution governed by differential, difference, or discrete transition dynamics.

---

## 2. Fundamental Distinction

> **Dynamical is not a while loop with a delta_t variable; it is the formal representation of state trajectory evolution $dx/dt = f(x, u, t)$.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **DYN-INV-001 (Trajectory Continuity):** State evolution MUST satisfy declared continuity or discrete step guarantees.
* **DYN-INV-002 (Conservation Laws):** Dynamical systems declaring physical conservation (energy, momentum) MUST preserve invariants under integration.
* **DYN-INV-003 (Time Invariance Declaration):** Autonomous vs non-autonomous (explicit time dependency) MUST be declared.
