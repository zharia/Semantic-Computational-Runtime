# SCR Semantic Library — 902 Interfaces / Observable

**Document:** `lib/902_Interfaces/Observable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Observable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Observable Interface** defines the semantic boundary through which internal states, metrics, signals, and events can be passively inspected without perturbing execution.

---

## 2. Fundamental Distinction

> **Observability is not print debugging or Prometheus metrics; it is the semantic mapping from internal state to observable output manifolds.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **OBS-INV-001 (Observer Non-Interference):** Observation MUST NOT perturb the primary computational state or trajectory.
* **OBS-INV-002 (State Observability):** The observable projection MUST declare what subspace of internal state is reconstructible.
* **OBS-INV-003 (Temporal Coherence):** Observed values MUST be timestamped relative to a coherent clock domain.
