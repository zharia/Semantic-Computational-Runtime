# SCR Semantic Library — 202 Math / Arithmetic

**Document:** `lib/202_Math/Arithmetic/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Arithmetic  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Arithmetic Domain** defines the elementary theory of numbers and the basic operations of addition, subtraction, multiplication, and division.

---

## 2. Fundamental Distinction

> **Arithmetic is not CPU ALU instructions; it is the semantic theory of numerical operations over integers, rationals, and reals.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **ARI-INV-001 (Division by Zero Prohibited):** Division by zero MUST be represented as an undefined mathematical state rather than silent corruption.
* **ARI-INV-002 (Exactness Preservation):** Arithmetic over integers and rationals MUST support exact representation without precision loss.
* **ARI-INV-003 (Order of Operations):** Precedence and associativity of arithmetic operations MUST be universally consistent.
