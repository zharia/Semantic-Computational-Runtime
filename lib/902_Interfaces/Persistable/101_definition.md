# SCR Semantic Library — 902 Interfaces / Persistable

**Document:** `lib/902_Interfaces/Persistable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Persistable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Persistable Interface** defines the semantic interface guaranteeing that state can be serialized to non-volatile storage and restored with identity and integrity intact.

---

## 2. Fundamental Distinction

> **Persistable is not an SQL database or file write; it is the semantic survival of state across computational session lifecycles.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **PST-INV-001 (Restoration Fidelity):** Restoring a persisted snapshot MUST yield semantic equivalence with the snapshot point.
* **PST-INV-002 (Durable Versioning):** Persisted artifacts MUST record schema versions to enable migration or compatibility checking.
* **PST-INV-003 (Crash Consistency):** Atomic persistence points MUST be well-defined to prevent partial-state corruption.
