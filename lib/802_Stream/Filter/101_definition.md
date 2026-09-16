# SCR Semantic Library — 802 Stream / Filter

**Document:** `lib/802_Stream/Filter/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Filter  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Filter** is A selective 1-to-(0..1) transformation evaluating a predicate to decide whether an element continues in the stream.

---

## 2. Fundamental Distinction

> **Filter is not packet dropping or network loss; it is an intentional semantic selection based on predicate truth.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **FLT-INV-001 (Loss Distinction):** Filtered elements MUST be semantically distinguishable from lost or dropped elements.
* **FLT-INV-002 (Order Preservation):** The relative order of surviving elements MUST remain strictly unchanged.
* **FLT-INV-003 (Predicate Determinism):** Filter predicates MUST evaluate deterministically given the element and its metadata.
