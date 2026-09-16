# SCR Semantic Library — 802 Stream / Flow

**Document:** `lib/802_Stream/Flow/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Flow  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Flow** is The rate, progression, and directional movement of semantic elements across a stream network.

---

## 2. Fundamental Distinction

> **Flow is not network bandwidth or socket throughput; it is the semantic rate of occurrence and availability propagation.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **FLW-INV-001 (Rate Preservation):** Transformations MUST account for changes in flow rate without silent element dropping.
* **FLW-INV-002 (Conservation):** In the absence of filtering or windowing, stream flow across intermediate nodes MUST satisfy semantic element conservation.
* **FLW-INV-003 (Directional Acyclicity):** Flow graphs MUST explicitly declare feedback loops versus forward acyclic propagation.
