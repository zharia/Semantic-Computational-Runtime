# SCR Semantic Library — 802 Stream / IR

**Document:** `lib/802_Stream/IR/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / IR  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream IR** is The intermediate representation and compilation layer mapping semantic stream graphs to MLIR dialects and native executable pipelines.

---

## 2. Fundamental Distinction

> **IR is not a custom proprietary compiler IR; it is the MLIR-first representation lowering stream semantics to hardware substrates.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **IR-INV-001 (MLIR Primacy):** Stream IR transformations MUST leverage MLIR dialects (`stream`, `async`, `llvm`) rather than inventing shadow IRs.
* **IR-INV-002 (Semantic Lowering Integrity):** Lowering from semantic stream operations to MLIR MUST preserve all domain invariants.
* **IR-INV-003 (Verification Passes):** Stream MLIR passes MUST include explicit verification of ordering, window, and state constraints.
