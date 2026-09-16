# SCR Semantic Library — 902 Interfaces / Serializable

**Document:** `lib/902_Interfaces/Serializable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Serializable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Serializable Interface** defines the semantic capability encoding an entity into a sequence of bytes preserving complete semantic structure, types, and values.

---

## 2. Fundamental Distinction

> **Serializable is not JSON.stringify(); it is an encoding isomorphism between an in-memory semantic entity and a linear representation.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **SER-INV-001 (Isomorphic Round-Trip):** Decode(Encode(X)) MUST be semantically identical to X.
* **SER-INV-002 (Type Schema Integrity):** Serialized payloads MUST embed or link to their authoritative semantic schema.
* **SER-INV-003 (Endian/Architecture Neutrality):** Serialization encodings MUST NOT depend on host CPU endianness or word width.
