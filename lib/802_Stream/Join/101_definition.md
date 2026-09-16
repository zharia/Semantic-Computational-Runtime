# SCR Semantic Library — 802 Stream / Join

**Document:** `lib/802_Stream/Join/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Join  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Join** is The correlation and combination of elements from two or more streams based on shared keys, temporal windows, or causal relations.

---

## 2. Fundamental Distinction

> **Join is not an SQL nested loop; it is a multi-stream semantic correlation across ordered domains.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **JON-INV-001 (Correlation Boundary):** Temporal stream joins MUST define a finite window or buffer over which correlation occurs.
* **JON-INV-002 (Causal Consistency):** Joined elements MUST not violate causal precedence between the contributing streams.
* **JON-INV-003 (Skew Resilience):** Joins MUST tolerate clock skew across streams according to declared watermark bounds.
