# SCR Semantic Library — 902 Interfaces / Streamable

**Document:** `lib/902_Interfaces/Streamable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Streamable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Streamable Interface** defines the semantic interface exposing data or state as an ordered, causal, or temporal sequence of elements emitted over time.

---

## 2. Fundamental Distinction

> **Streamable is not an iterator; it is participation in the SCR Stream domain with explicit watermarks, occurrences, and lifecycle.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **STR-INV-001 (Stream Domain Conformance):** Streamable entities MUST conform to `SCR-LIB-STREAM` normative contracts.
* **STR-INV-002 (Backpressure Accommodation):** A streamable source MUST respond safely to consumer rate-limiting signals.
* **STR-INV-003 (Element Identity Preservation):** Elements emitted into a stream MUST preserve their semantic identity.
