# SCR Semantic Library — 902 Interfaces / Deterministic

**Document:** `lib/902_Interfaces/Deterministic/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Deterministic  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Deterministic Interface** defines the semantic guarantee that identical sequences of inputs and initial states produce strictly identical outputs, state transitions, and observable behaviors.

---

## 2. Fundamental Distinction

> **Determinism is not single-threaded execution; it is semantic reproducibility across execution substrates, schedulers, and environments.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **DET-INV-001 (Reproducibility):** Given identical inputs and initial state, evaluation MUST produce identical outputs.
* **DET-INV-002 (Substrate Independence):** Determinism MUST hold across conforming compilers, providers, and hardware targets.
* **DET-INV-003 (Side-Effect Freedom):** Deterministic operations MUST NOT perform uncoordinated external side effects.
