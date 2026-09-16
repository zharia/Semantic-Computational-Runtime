# SCR Semantic Library — 902 Interfaces / Vectorizable

**Document:** `lib/902_Interfaces/Vectorizable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Vectorizable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Vectorizable Interface** defines the semantic contract guaranteeing that operations can be evaluated across SIMD, SIMT, or tensor vector lanes concurrently without cross-lane dependencies.

---

## 2. Fundamental Distinction

> **Vectorizable is not AVX-512 instructions; it is data-parallel semantic independence across uniform coordinate arrays.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **VEC-INV-001 (Uniform Control Flow):** Vectorized operations MUST execute without divergent per-lane conditional dependencies.
* **VEC-INV-002 (Alignment & Stride):** Memory access patterns for vectorized data MUST declare contiguous or uniform striding.
* **VEC-INV-003 (Lane Independence):** Evaluation in lane $k$ MUST NOT depend on the result of lane $j$ within the same vector step.
