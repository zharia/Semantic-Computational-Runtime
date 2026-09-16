# SCR Semantic Library — 301 Field / Operators

**Document:** `lib/301_Field/Operators/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Operators  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Operators Field Subdomain** defines formal linear and non-linear mappings $L: \mathcal{F}_1 \to \mathcal{F}_2$ between field spaces.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Functions` and functional analysis.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-OPR-001 (Domain/Codomain Typing):** Operators MUST declare their input field space and output field space.
* **FLD-OPR-002 (Linearity Verification):** Linear operators MUST satisfy $L(a f + b g) = a L(f) + b L(g)$.
* **FLD-OPR-003 (Self-Adjointness):** Operators claiming self-adjointness MUST satisfy $\langle L f, g \rangle = \langle f, L g \rangle$.
