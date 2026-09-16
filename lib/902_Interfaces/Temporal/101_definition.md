# SCR Semantic Library — 902 Interfaces / Temporal

**Document:** `lib/902_Interfaces/Temporal/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Temporal  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Temporal Interface** defines the semantic interface governing time-indexed behavior, duration, delays, clocks, and temporal validity intervals.

---

## 2. Fundamental Distinction

> **Temporal is not time.now(); it is the explicit association of computational entities with time coordinates across multi-clock domains.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **TMP-INV-001 (Clock Domain Explicitness):** Temporal references MUST identify their reference clock (Event, Ingestion, Processing, Simulated).
* **TMP-INV-002 (Duration Dimensionality):** Time intervals and durations MUST declare their physical or discrete units.
* **TMP-INV-003 (Temporal Ordering Soundness):** Past, present, and future horizons MUST obey causal precedence.
