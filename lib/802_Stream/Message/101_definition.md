# SCR Semantic Library — 802 Stream / Message

**Document:** `lib/802_Stream/Message/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Message  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Message** is A discrete, self-contained semantic unit of communication or observation encapsulated for transmission across stream boundaries.

---

## 2. Fundamental Distinction

> **A Message is not an AMQP frame, byte payload, or socket packet; it is a semantic package with structured headers, payload typing, and provenance.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **MSG-INV-001 (Payload Independence):** A Message's semantic payload MUST remain independent of the wire serialization format.
* **MSG-INV-002 (Header Provenance):** Message metadata MUST preserve origin, correlation, and causality attributes across hops.
* **MSG-INV-003 (Boundary Integrity):** A Message MUST represent a discrete semantic boundary without partial-message interpretation.
