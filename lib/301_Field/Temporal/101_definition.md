# SCR Semantic Library — 301 Field / Temporal

**Document:** `lib/301_Field/Temporal/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Temporal  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Temporal Field Subdomain** defines fields whose values vary over a one-dimensional ordered temporal domain $t \in T$.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Calculus` and `802_Stream/Temporal`.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-TMP-001 (Monotonic Time Dimension):** Temporal field coordinates MUST advance monotonically according to an explicit clock.
* **FLD-TMP-002 (Causal Independence):** Evaluation at time $t$ MUST NOT depend on future states $t' > t$ unless explicitly retrocausal.
* **FLD-TMP-003 (Time Derivative Existence):** Time-varying fields declaring dynamics MUST define their temporal derivative $\partial\phi/\partial t$.
