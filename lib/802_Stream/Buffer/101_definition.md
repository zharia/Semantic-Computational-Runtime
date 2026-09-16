# SCR Semantic Library — 802 Stream / Buffer

**Document:** `lib/802_Stream/Buffer/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Buffer  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Buffer** is An intermediate realization storage holding stream elements to absorb jitter, rate mismatch, or facilitate batching.

---

## 2. Fundamental Distinction

> **A Buffer is not stream semantics; it is an execution mechanism whose overflow or underflow policies must be defined.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **BUF-INV-001 (Execution Subordination):** Buffering MUST NOT redefine the ordering, causality, or identity of contained elements.
* **BUF-INV-002 (Eviction Policy):** Buffers with finite capacity MUST declare an explicit overflow policy (Reject, DropOldest, Block).
* **BUF-INV-003 (Transparency):** In the absence of eviction, buffering MUST be completely transparent to downstream consumers.
