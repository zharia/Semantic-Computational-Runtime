# SCR Semantic Library — 301 Field / Composition

**Document:** `lib/301_Field/Composition/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Field / Composition  
**Parent:** `lib/301_Field/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Composition Field Subdomain** defines the algebraic composition of field values or operators: $(f \circ g)(x) = f(g(x))$.

---

## 2. Mathematical Foundation & Relationship to 202_Math

> **Grounded in `202_Math/Functions`.**

In accordance with `FIELD-INV-001` and `MATH-INV-001`, mathematical meaning is authoritative over field representations. Grids, arrays, textures, and GPU kernels remain subordinate realization mechanisms.

---

## 3. Subdomain Invariants

* **FLD-CMP-001 (Codomain-Domain Compatibility):** Composition $f \circ g$ is valid if and only if $\text{Range}(g) \subseteq \text{Domain}(f)$.
* **FLD-CMP-002 (Associativity):** Field composition MUST be associative: $(f \circ g) \circ h = f \circ (g \circ h)$.
* **FLD-CMP-003 (Chain Rule for Gradients):** $\nabla(f \circ g) = (Df \circ g) \cdot \nabla g$ MUST hold for differentiable fields.
