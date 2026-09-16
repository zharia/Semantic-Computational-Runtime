# SCR Semantic Library — 902 Interfaces / Distributable

**Document:** `lib/902_Interfaces/Distributable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Distributable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Distributable Interface** defines the semantic boundary permitting computation, state, or communication to be partitioned, scheduled, and synchronized across distributed execution nodes.

---

## 2. Fundamental Distinction

> **Distributability is not a cluster manager or MPI rank; it is the capability of decomposing computation without altering semantic correctness.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **DST-INV-001 (Partition Independence):** Partitioning of a distributable operation MUST preserve equivalence with centralized evaluation.
* **DST-INV-002 (Consistency Model):** The consistency model (strict serializability, eventual consistency, causal) MUST be declared.
* **DST-INV-003 (Fault Boundary):** Node failure and partial disconnection semantics MUST be explicitly defined.
