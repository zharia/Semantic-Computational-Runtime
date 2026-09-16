# SCR Semantic Library — 902 Interfaces / Transformable

**Document:** `lib/902_Interfaces/Transformable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Transformable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Transformable Interface** defines the semantic interface permitting an entity to undergo coordinate, topological, representation, or algebraic transformation.

---

## 2. Fundamental Distinction

> **Transformable is not matrix multiplication; it is a morphism between semantic spaces preserving structural invariants.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **TRF-INV-001 (Morphism Soundness):** A transformation MUST preserve declared structural invariants between domain and codomain.
* **TRF-INV-002 (Invertibility Declaration):** If a transformation is invertible, the inverse mapping and condition number MUST be specified.
* **TRF-INV-003 (Provenance Tracking):** Transformed entities MUST record the transformation applied in their provenance lineage.
