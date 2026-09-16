# SCR Semantic Library — 202 Math / Functions

**Document:** `lib/202_Math/Functions/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Functions  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Functions Domain** defines formal mathematical mappings $f: X \to Y$ relating elements of a domain $X$ to a codomain $Y$ under well-defined semantic rules.

---

## 2. Fundamental Distinction

> **A mathematical function is not a subprogram routine; it is a single-valued relation assigning exactly one codomain element to each domain element.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **FNC-INV-001 (Domain Well-Definedness):** A function MUST be evaluated strictly within its defined domain.
* **FNC-INV-002 (Determinism of Mapping):** Identical domain elements MUST map to identical codomain elements.
* **FNC-INV-003 (Bijectivity Explicitness):** Where injectivity, surjectivity, or bijectivity is claimed, it MUST be mathematically sound.
