# SCR Semantic Library — 802 Stream / Transport

**Document:** `lib/802_Stream/Transport/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Transport  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Transport** is The physical or inter-process communication medium carrying stream elements between separate execution nodes.

---

## 2. Fundamental Distinction

> **Transport is not Stream; TCP, UDP, QUIC, PCIe, Shared Memory, and RDMA are physical transport realizations.**

The semantic structure remains authoritative; realization details, physical formats, and implementation frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **TRP-INV-001 (Transport Independence):** Stream semantic definitions MUST be completely valid over any conforming transport.
* **TRP-INV-002 (Transport Error Translation):** Physical transport errors (disconnections, corrupt packets) MUST be mapped to typed Stream failures.
* **TRP-INV-003 (No Authority):** Transport protocols MUST NOT dictate stream ordering, element identity, or semantic types.
