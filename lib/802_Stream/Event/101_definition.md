# SCR Semantic Library — 802 Stream / Event

**Document:** `lib/802_Stream/Event/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Event  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Event** is A semantic element denoting an instantaneous occurrence or state transition at a specific point in the temporal or causal domain.

---

## 2. Fundamental Distinction

> **An Event is not a GUI callback, hardware interrupt, or logging statement; it is the semantic fact of an occurrence within the modeled world.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **EVT-INV-001 (Instantaneity):** An Event MUST be associated with a point occurrence rather than an interval of ongoing duration.
* **EVT-INV-002 (Occurrence Distinction):** The occurrence of an event MUST remain distinct from its notification, observation, or processing.
* **EVT-INV-003 (Immutability):** Once an event has occurred, the semantic fact of its occurrence cannot be modified.
