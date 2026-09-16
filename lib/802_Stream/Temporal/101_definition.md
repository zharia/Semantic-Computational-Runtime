# SCR Semantic Library — 802 Stream / Temporal

**Document:** `lib/802_Stream/Temporal/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Temporal  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Temporal** is The multi-clock semantic framework governing time, durations, delays, watermarks, and progress in stream processing.

---

## 2. Fundamental Distinction

> **Temporal semantics is not system wall-clock time (`gettimeofday()`); it encompasses Event Time, Ingestion Time, Processing Time, and logical/simulated clocks.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **TMP-INV-001 (Multi-Clock Distinction):** Event Time, Ingestion Time, and Processing Time MUST be explicitly differentiated.
* **TMP-INV-002 (Watermark Monotonicity):** Watermarks denoting temporal progress MUST advance monotonically within a given clock domain.
* **TMP-INV-003 (Skew Explicitness):** Temporal skew between distributed observers MUST be explicitly represented rather than assumed zero.
