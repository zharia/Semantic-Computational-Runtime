# SCR Semantic Library — 902 Interfaces / Reducible

**Document:** `lib/902_Interfaces/Reducible/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Reducible  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Reducible Interface** defines the semantic interface defining algebraic aggregation over collections or streams through associative binary operations.

---

## 2. Fundamental Distinction

> **Reducible is not a foldl loop; it is an algebraic monoid or semigroup structure $(S, \oplus, e)$.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **RED-INV-001 (Associativity):** The reduction operator $\oplus$ MUST satisfy $(a \oplus b) \oplus c = a \oplus (b \oplus c)$.
* **RED-INV-002 (Identity Element):** Where a monoid is claimed, $a \oplus e = e \oplus a = a$ MUST hold.
* **RED-INV-003 (Tree Reducibility):** Associativity MUST permit hierarchical or parallel tree reductions with invariant results.
