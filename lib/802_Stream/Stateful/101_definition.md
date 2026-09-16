# SCR Semantic Library — 802 Stream / Stateful

**Document:** `lib/802_Stream/Stateful/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Stateful  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Stateful** is Stream processing where the output of an operator depends on both the incoming element and an accumulated historical state.

---

## 2. Fundamental Distinction

> **Stateful processing is not a global static variable; it is an explicitly scoped, lifecycle-managed state store.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **STF-INV-001 (State Scoping):** Accumulated state MUST be explicitly scoped by key, window, or stream session.
* **STF-INV-002 (Checkpointability):** Stateful operators MUST support serialization of their internal state for recovery.
* **STF-INV-003 (Deterministic Transition):** State transitions given the same prior state and input element MUST be deterministic.
