# SCR Semantic Library — 902 Interfaces / Tileable

**Document:** `lib/902_Interfaces/Tileable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Tileable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Tileable Interface** defines the semantic interface permitting spatial, volumetric, or computational domains to be partitioned into regular or irregular contiguous tiles for cache locality and hardware acceleration.

---

## 2. Fundamental Distinction

> **Tileable is not GPU block sizing; it is the topological decomposition of a domain into boundary-conforming subdomains.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **TIL-INV-001 (Domain Partitioning Completeness):** The union of all tiles MUST equal the original domain without gaps or uncoordinated overlaps.
* **TIL-INV-002 (Boundary Halo Explicitness):** Halo or ghost-cell overlap requirements across tile boundaries MUST be declared.
* **TIL-INV-003 (Kernel Equivalence):** Evaluating tiled computations MUST yield identical results to whole-domain evaluation.
