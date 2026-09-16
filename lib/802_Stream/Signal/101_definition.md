# SCR Semantic Library — 802 Stream / Signal

**Document:** `lib/802_Stream/Signal/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Signal  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Signal** is A continuous or discretely sampled time-varying value representing a physical, virtual, or computational phenomenon.

---

## 2. Fundamental Distinction

> **A Signal is not an analog voltage, PCM audio buffer, or raw sensor reading; it is a continuous or discrete mapping from a domain to a value space.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **SIG-INV-001 (Continuity Semantics):** A Signal MUST explicitly declare whether its underlying phenomenon is continuous or discrete.
* **SIG-INV-002 (Sampling Preservation):** Sampled representations of a continuous signal MUST retain their sampling rate, interpolation, and uncertainty bounds.
* **SIG-INV-003 (Dimension Explicitness):** The domain of a signal (temporal, spatial, frequency) MUST be explicitly defined.
