# SCR Semantic Library — 802 Stream / Source

**Document:** `lib/802_Stream/Source/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Source  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Source** is a semantic intake or origin boundary through which semantic elements are made available to a Stream.

A Source defines:
* The schema and semantic typing of elements emitted.
* The temporal clock or reference governing occurrence times.
* The availability semantics under which elements become accessible.
* The provenance attribution anchoring emitted elements.

---

## 2. Fundamental Distinction

> **A Source is not an I/O socket, network reader, Kafka topic consumer, file reader, or sensor hardware driver.**

A realization adapter may bind a physical sensor or socket to a Stream Source, but the Source semantically represents the origin contract of elements into the Stream domain.

---

## 3. Subdomain Invariants

* **SRC-INV-001 (Semantic Emittance):** Every element emitted by a Source MUST have a well-defined semantic identity and type.
* **SRC-INV-002 (Occurrence Attribution):** A Source MUST preserve the distinction between an element's real-world occurrence time and its ingestion/emission time.
* **SRC-INV-003 (Transport Subordination):** Failure or disconnection of an underlying transport MUST NOT alter the semantic definition of the Source contract.
