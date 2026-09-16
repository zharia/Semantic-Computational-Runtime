# SCR Semantic Library — 802 Stream / Split

**Document:** `lib/802_Stream/Split/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Split  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Split** is The demultiplexing or partitioning of a single stream into multiple output streams based on predicate routing or sharding keys.

---

## 2. Fundamental Distinction

> **Split is not a hardware bus tap or pub/sub broker; it is a semantic demultiplexing contract.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **SPL-INV-001 (Partition Exhaustiveness):** Routing rules MUST define handling for elements matching zero, one, or multiple branches.
* **SPL-INV-002 (Branch Independence):** Backpressure or stall in one split branch MUST NOT silently corrupt ordering in sibling branches.
* **SPL-INV-003 (Identity Preservation):** Elements routed to output branches MUST retain their semantic identity and provenance.
