# SCR Semantic Library — 802 Stream / Channel

**Document:** `lib/802_Stream/Channel/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Channel  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Channel** is A semantic point-to-point or multi-point conduit connecting a stream producer to stream consumers with defined delivery contracts.

---

## 2. Fundamental Distinction

> **A Channel is not a POSIX pipe, TCP connection, or Go channel; it is a typed communication contract.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **CHN-INV-001 (Capacity Decoupling):** A Channel's semantic contract MUST define behavior under saturation (backpressure, drop, error).
* **CHN-INV-002 (Type Conformance):** All elements transmitted over a channel MUST conform to the channel's declared schema.
* **CHN-INV-003 (Closure Signaling):** Channel completion or termination MUST be explicitly communicated to all consumers.
