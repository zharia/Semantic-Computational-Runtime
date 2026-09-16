# SCR Semantic Library — 202 Math / IR

**Document:** `lib/202_Math/IR/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / IR  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **IR Domain** defines the intermediate representation layer expressing mathematical semantics within MLIR dialects (`math`, `arith`, `complex`, `linalg`).

---

## 2. Fundamental Distinction

> **Math IR is not an arbitrary compiler IR; it is the MLIR-first representation lowering mathematical constructs to target substrates.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **MIR-INV-001 (MLIR Primacy):** Mathematical lowering MUST leverage standard MLIR dialects rather than creating shadow representations.
* **MIR-INV-002 (Semantic Equivalence):** Lowering to MLIR MUST preserve all mathematical domain invariants.
* **MIR-INV-003 (Precision Integrity):** Lowering transformations MUST respect declared numeric precision contracts.
