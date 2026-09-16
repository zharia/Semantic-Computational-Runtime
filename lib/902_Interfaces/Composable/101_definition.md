# SCR Semantic Library — 902 Interfaces / Composable

**Document:** `lib/902_Interfaces/Composable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Composable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Composable Interface** defines the semantic interaction contract through which computational constructs expose explicit algebraic, pipeline, or topological composition guarantees.

---

## 2. Fundamental Distinction

> **Composition is not function pointer chaining or class inheritance; it is the semantic preservation of component invariants, preconditions, and postconditions under combination.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **CMP-INV-001 (Preservation of Invariants):** The composition of interfaces A and B MUST preserve all invariants declared by A and B.
* **CMP-INV-002 (Associativity of Sequential Composition):** Where sequential composition is defined, (A ∘ B) ∘ C MUST be semantically equivalent to A ∘ (B ∘ C).
* **CMP-INV-003 (Contract Soundness):** A composite interface MUST NOT declare guarantees stronger than the combined guarantees of its components.
