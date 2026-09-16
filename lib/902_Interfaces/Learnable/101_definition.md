# SCR Semantic Library — 902 Interfaces / Learnable

**Document:** `lib/902_Interfaces/Learnable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Learnable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Learnable Interface** defines the semantic interface exposing parameter adaptation, optimization objectives, loss evaluation, and update rules from observed data.

---

## 2. Fundamental Distinction

> **Learnable is not a neural network training loop; it is the formal adaptation contract parameterizing behavioral improvement.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **LRN-INV-001 (Parameter Explicitness):** Learnable parameters and their structural constraints MUST be explicitly exposed.
* **LRN-INV-002 (Loss Association):** Parameter updates MUST be guided by declared objective or loss functions.
* **LRN-INV-003 (Convergence Stability):** Update step invariants MUST bound parameter divergence during adaptation.
