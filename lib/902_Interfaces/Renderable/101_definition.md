# SCR Semantic Library — 902 Interfaces / Renderable

**Document:** `lib/902_Interfaces/Renderable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Renderable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Renderable Interface** defines the semantic boundary projecting computational entities into perceptual, visual, acoustic, or haptic sensory representations.

---

## 2. Fundamental Distinction

> **Renderable is not OpenGL draw calls; it is the semantic projection from high-dimensional computational entities to human perceptual fields.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **RND-INV-001 (Perceptual Mapping):** The projection from domain entity to visual/sensory representation MUST be explicit.
* **RND-INV-002 (Resolution Invariance):** Underlying semantics MUST remain invariant under changes in render resolution or LOD.
* **RND-INV-003 (Material/Geometry Separation):** Intrinsic spatial geometry MUST remain distinguishable from surface shading/rendering attributes.
