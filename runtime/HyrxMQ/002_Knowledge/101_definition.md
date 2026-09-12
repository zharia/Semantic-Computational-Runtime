---
title: HyrxMQ Project Knowledge Base
domain: sdp.knowledge.hyrxmq
document: 101_definition
document_type: sdp_knowledge_definition
schema_version: 0.1.0
id: SDP-KB-HYRXMQ
name: HyrxMQ Project Knowledge Base
version: 0.1.0
status: adopted
created: 2026-09-12
updated: 2026-09-12
parent: SDP-PROJ-HYRXMQ
authority: SCR
sdp_conformance: SDP-001K
---

# HyrxMQ Project Knowledge Base

## Purpose

The Project Knowledge Base collects evidence-linked statements about HyrxMQ that
already existed at adoption time. It adopts existing knowledge by reference; it
does not create new claims.

## Scope

- Architectural and dependency facts.
- Test, gate, security, and performance evidence.
- Recorded limitations and `NOT PROVEN` items.

Outside scope:

- New measurements or claims not already present in the repository.
- SDP semantic history beyond the adoption event.

## Key Concepts

- **Knowledge record** — an adopted, evidence-linked statement.
- **Classification** — the epistemic label of a record (fact result, conjecture,
  unresolved question).
- **Evidence** — the existing repository material a record cites.
- **Adoption by reference** — pointing at source material instead of copying it.

## Classification Labels

Per SDP-001K §11, each record is labelled as one of: established definition;
formal result; derived consequence; counterexample; analogy; conjecture;
unresolved question.

## Records

Machine-readable records live in `knowledge.yaml`. Each record carries an id, a
statement, a classification, a source citation, and a status.

## Invariants

- A record MUST cite existing repository material as its source.
- A record MUST NOT upgrade an `UNKNOWN` or `NOT PROVEN` item to a positive claim.
- Records are descriptive. They do not redefine semantic contracts.

## Relationships

- `SDP-KB-HYRXMQ` REFERENCES `SDP-PROJ-HYRXMQ`
- `SDP-KB-HYRXMQ` DERIVES_FROM `SDP-ADOPT-HYRXMQ-0001`

## Change History

| Version | Date | Change |
|---|---|---|
| 0.1.0 | 2026-09-12 | Initial knowledge base under SDP-ADOPT-HYRXMQ-0001. |
