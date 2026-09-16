# SCR Semantic Library — 802 Stream / Queue

**Document:** `lib/802_Stream/Queue/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Queue  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Queue** is A realization structure providing ordered, FIFO, or priority-based staging for stream elements.

---

## 2. Fundamental Distinction

> **A Queue is not Stream; a Queue is a mechanical ordering device used to realize a stream.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **QUE-INV-001 (Discipline Explicitness):** The queuing discipline (FIFO, LIFO, Priority) MUST be explicitly defined.
* **QUE-INV-002 (Queue-Stream Distinction):** Dequeuing an element does not destroy its historical participation in the stream.
* **QUE-INV-003 (Non-Redefinition):** Queue parameters (capacity, memory layout) MUST NOT alter the stream's semantic definition.
