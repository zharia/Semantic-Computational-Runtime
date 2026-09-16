# SCR Semantic Library — 802 Stream / Reduce

**Document:** `lib/802_Stream/Reduce/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Reduce  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Reduce** is An aggregation transformation combining multiple stream elements over a window or running accumulation into summary elements.

---

## 2. Fundamental Distinction

> **Reduce is not an in-memory accumulator variable; it is a formal algebraic reduction over a stream monoid or semigroup.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **RED-INV-001 (Algebraic Explicitness):** The reduction operator (associative, commutative) MUST be explicitly defined.
* **RED-INV-002 (Boundary Association):** Reductions MUST be bounded by an explicit window, partition, or trigger condition.
* **RED-INV-003 (State Checkpointing):** Running reductions MUST support deterministic state checkpointing and restoration.
