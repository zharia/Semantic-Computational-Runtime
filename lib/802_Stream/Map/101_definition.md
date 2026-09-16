# SCR Semantic Library — 802 Stream / Map

**Document:** `lib/802_Stream/Map/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Map  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Map** is A 1-to-1 element-wise stateless transformation applying a function to each element of a stream independently.

---

## 2. Fundamental Distinction

> **Map is not a CPU loop or vector instruction; it is a point-wise semantic projection across stream elements.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **MAP-INV-001 (Cardinality Preservation):** Map MUST preserve a 1:1 correspondence between input elements and output elements.
* **MAP-INV-002 (Order Invariance):** Map MUST preserve the relative ordering and temporal timestamps of elements.
* **MAP-INV-003 (Statelessness):** Map evaluation MUST NOT depend on prior or future elements in the stream.
