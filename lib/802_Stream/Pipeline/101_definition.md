# SCR Semantic Library — 802 Stream / Pipeline

**Document:** `lib/802_Stream/Pipeline/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Pipeline  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Pipeline** is A composed, directed sequence or graph of stream processing stages transforming source streams into sink streams.

---

## 2. Fundamental Distinction

> **A Pipeline is not a Unix shell pipe or task queue runner; it is a formal semantic composition of stream transformations.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **PIP-INV-001 (Stage Isolation):** Pipeline stages MUST communicate strictly via defined stream contracts without hidden state leakage.
* **PIP-INV-002 (End-to-End Provenance):** A Pipeline MUST preserve element provenance from input source to output sink.
* **PIP-INV-003 (Composability):** Sub-pipelines MUST be composable into larger pipelines while preserving semantic equivalence.
