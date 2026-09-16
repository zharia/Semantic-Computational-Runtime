# SCR Semantic Library — 802 Stream / Scheduling

**Document:** `lib/802_Stream/Scheduling/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Scheduling  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Scheduling** is The temporal and computational assignment of stream operators and element batches to execution resources.

---

## 2. Fundamental Distinction

> **Scheduling is not an OS thread scheduler; it is the realization plan allocating compute units to stream DAG nodes.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **SCH-INV-001 (Semantic Invariance):** Scheduling choices (push, pull, work-stealing) MUST NOT alter stream computation results.
* **SCH-INV-002 (Fairness and Liveness):** Schedulers MUST guarantee that no active stream branch suffers starvation indefinitely.
* **SCH-INV-003 (Subordination):** Scheduler optimization MUST remain subordinate to stream ordering and synchronization contracts.
