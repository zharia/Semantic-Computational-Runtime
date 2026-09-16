# SCR Semantic Library — 902 Interfaces / Stateful

**Document:** `lib/902_Interfaces/Stateful/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Stateful  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Stateful Interface** defines the semantic interface exposing internal memory where future outputs depend upon the history of previous operations and inputs.

---

## 2. Fundamental Distinction

> **Stateful is not class instance variables; it is a formal state transition system $(S, s_0, \delta)$ with explicit state boundaries.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **STF-INV-001 (State Space Explicitness):** The allowable state space $S$ and initial state $s_0$ MUST be formally declared.
* **STF-INV-002 (Transition Determinism):** State transition $\delta(s, i) \to s'$ MUST be deterministic given identical inputs.
* **STF-INV-003 (Snapshot Accessibility):** Stateful entities MUST permit inspecting or checkpointing their current state.
