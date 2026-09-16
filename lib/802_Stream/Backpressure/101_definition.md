# SCR Semantic Library — 802 Stream / Backpressure

**Document:** `lib/802_Stream/Backpressure/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Backpressure  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Backpressure** is The semantic propagation of downstream consumption limits back to upstream producers to preserve system stability.

---

## 2. Fundamental Distinction

> **Backpressure is not TCP window scaling or reactive streams Java interfaces; it is the semantic coordination of production and consumption rates.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **BKP-INV-001 (Safety):** Upstream producers MUST honor backpressure signals to prevent silent data corruption or uncontrolled memory growth.
* **BKP-INV-002 (Loss Declaration):** If backpressure results in element shedding, dropped elements MUST be recorded under Loss semantics.
* **BKP-INV-003 (Causal Preservation):** Throttling caused by backpressure MUST NOT violate causal order across independent streams.
