# SCR Semantic Library — 802 Stream / Operator

**Document:** `lib/802_Stream/Operator/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Operator  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Operator** is A discrete unit of computation or transformation applied to one or more streams to produce one or more streams.

---

## 2. Fundamental Distinction

> **An Operator is not a thread, coroutine, or function pointer; it is a semantic transformation contract specifying inputs, outputs, statefulness, and determinism.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **OPR-INV-001 (Contract Explicitness):** Every Operator MUST define its input and output stream contracts and type schemas.
* **OPR-INV-002 (Purity Classification):** An Operator MUST declare whether it is pure stateless, deterministic stateful, or side-effecting.
* **OPR-INV-003 (Failure Isolation):** Operator failure MUST be semantically isolated and classified rather than causing undefined stream state.
