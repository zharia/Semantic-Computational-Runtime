# SCR Semantic Library — 202 Math / Random

**Document:** `lib/202_Math/Random/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Random  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Random Domain** defines mathematical pseudo-random and quasi-random number generators, sampling distributions, and entropy sources.

---

## 2. Fundamental Distinction

> **Randomness in SCR is a reproducible, seedable mathematical stream drawn from explicit distributions.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **RND-INV-001 (Seed Reproducibility):** Given identical seeds and generator state, pseudorandom sequences MUST be bitwise reproducible.
* **RND-INV-002 (Distribution Conformance):** Sampled streams MUST pass statistical goodness-of-fit tests for their declared distribution.
* **RND-INV-003 (State Independence):** Separate PRNG instances MUST advance independently without hidden cross-talk.
