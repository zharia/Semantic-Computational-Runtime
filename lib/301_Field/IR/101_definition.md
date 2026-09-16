# SCR Semantic Library — 301 Field / IR

**Document:** `lib/301_Field/IR/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / IR  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **IR Field Subdomain** defines the intermediate representation layer compiling field operations to MLIR dialects (`math`, `linalg`, `affine`, `gpu`).

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/IR` and MLIR compiler infrastructure.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-IR-001 (MLIR Primacy):** Field IR lowering MUST target established MLIR dialects rather than creating custom shadow IRs.
* **FLD-IR-002 (Operator Fusion Integrity):** Lowering passes fusing field operators MUST preserve mathematical semantics.
* **FLD-IR-003 (Verification Passes):** Field MLIR passes MUST include explicit verification of boundary and domain constraints.
