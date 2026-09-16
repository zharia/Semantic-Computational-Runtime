# SCR Semantic Library — 802 Stream / Merge

**Document:** `lib/802_Stream/Merge/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Merge  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Merge** is The combination of two or more streams of identical or compatible element types into a single unified stream.

---

## 2. Fundamental Distinction

> **Merge is not an interleaved multiplexer or network hub; it is a union of stream elements under a specified ordering strategy.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **MRG-INV-001 (Ordering Strategy):** A Merge MUST declare its ordering policy (e.g., event-time order, arrival order, round-robin).
* **MRG-INV-002 (Source Attribution):** Merged elements MUST retain provenance identifying their contributing source stream.
* **MRG-INV-003 (Completeness Conservation):** No element from any input stream may be silently discarded during a merge.
