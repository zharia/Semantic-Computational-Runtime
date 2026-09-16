# SCR Semantic Library — 802 Stream / Window

**Document:** `lib/802_Stream/Window/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Window  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Window** is A bounded segmentation of an unbounded or bounded stream across temporal, count, spatial, or session dimensions for computation and aggregation.

---

## 2. Fundamental Distinction

> **A Window is not an in-memory array or ring buffer; it is a semantic assignment relation partitioning stream elements into bounded sets.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **WIN-INV-001 (Assignment Determinism):** Element assignment to windows (tumbling, sliding, session) MUST be deterministic relative to the chosen clock and key.
* **WIN-INV-002 (Trigger Separation):** Window assignment MUST remain semantically distinct from window evaluation triggers and late-arrival policies.
* **WIN-INV-003 (Completeness Boundary):** A Window MUST define when its contents are deemed complete (via watermark or closure).
