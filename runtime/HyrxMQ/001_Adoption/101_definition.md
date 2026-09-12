---
title: HyrxMQ Adoption Baseline
domain: sdp.adoption.hyrxmq
document: 101_definition
document_type: sdp_adoption_record
schema_version: 0.1.0
id: SDP-ADOPT-HYRXMQ-0001
name: HyrxMQ Adoption Baseline
version: 0.1.0
status: adopted
created: 2026-09-12
updated: 2026-09-12
parent: SDP-PROJ-HYRXMQ
authority: SCR
sdp_conformance: SDP-001K
---

# SDP-ADOPT-HYRXMQ-0001 — HyrxMQ Adoption / Baseline Establishment

## Purpose

This record establishes the genesis-equivalent adoption event for Project
`SDP-PROJ-HYRXMQ`. It identifies the existing baseline, lists the adopted
material by reference, and preserves provenance without rewriting history.

## Scope

- The baseline commit and development provenance at adoption time.
- The catalogue of adopted specifications, tests, evidence, and licensing.
- What this event does **not** assert (production readiness, kernel freeze).

Outside this record:

- New measurements, new claims, or new implementation work.
- SDP semantic history beyond the adoption event.

## Event

This is the genesis-equivalent event for Project `SDP-PROJ-HYRXMQ`.

| Field | Value |
|---|---|
| Event id | `SDP-ADOPT-HYRXMQ-0001` |
| Event type | `adoption` (not `bootstrap`) |
| Causal parents | none (genesis) |
| Subject | `SDP-PROJ-HYRXMQ` |
| Occurred | 2026-09-12 |
| Baseline commit | `98bcf9c` (2026-09-11) |
| Replay target | `SDP-PROJ-HYRXMQ@baseline` |
| Effect | Establishes the Project/Application identities and adopts existing material |

Per SDP-001K §15, genesis is not epistemically privileged; it establishes a
recognised baseline. This event adopts an already-existing implementation. It
does **not** claim the Project was newly bootstrapped and does **not** rewrite
history.

## Key Concepts

- **Adoption** — establishing a baseline for an existing Project.
- **Bootstrap** — establishing a new Project; not performed here.
- **Genesis event** — the first recorded event; here the adoption event.
- **Baseline** — the identified state a replay reconstructs.
- **Provenance** — the recorded origin of adopted material.

## Adopted Material (by reference, not copied)

| Category | Location | Notes |
|---|---|---|
| Project specification | `docs/PROJECT.md` | Project definition and boundaries |
| Normative requirements | `docs/REQUIREMENTS.md` | `RQ-<DOMAIN>-NNN` identifiers |
| Architecture | `docs/ARCHITECTURE.md` | Layers 0–5, invariants |
| Architecture invariants | `docs/ARCHITECTURE_INVARIANTS.md` | INV-001..INV-012 |
| Core engine spec | `docs/CORE_ENGINE.md` | Core concepts and invariants |
| Implementation plan | `docs/IMPLEMENTATION_PLAN.md` | Phases 0–16, exit gates |
| Protocol | `docs/PROTOCOL.md`, `docs/RABBITMQ_COMPATIBILITY.md` | AMQP 0-9-1 |
| Testing | `docs/TESTING.md`, `docs/QUALITY_GATES.md` | Test strategy, gates |
| Invariant registry | `docs/invariants/registry.yaml` | 35 entries |
| Engineering state | `docs/engineering/CURRENT_STATE.md`, `FINAL_ENGINEERING_ASSESSMENT_v0.0.3.md` | Evidence |
| Decisions | `docs/decisions/0001..0005` | ADRs |
| Development history | `program-increments/v0.0.1-alpha`, `v0.0.2`, `v0.0.3` | Increments/milestones |
| Tests | `tests/phase0..phase10`, `tests/integration` | Executable evidence |
| Benchmarks | `benchmarks/`, `docs/PERFORMANCE.md` | Performance evidence |
| Licensing | `LICENSE`, `vendor/flare/LICENSE` | Apache-2.0; flare MIT |

## Provenance

- Repository history for this path begins at `6739fef` (2026-09-07) "Added
  HyrxMQ Project spec"; seed commit `c929002`.
- 86 commits under this path at adoption time; newest `98bcf9c`.
- Engineering documents cite commits `4ec2a06` and `01e60b6`; the benchmark
  record cites `c6fb4cc`; HEAD is `98bcf9c`. Mismatch recorded as
  `UNK-HYRXMQ-004`.
- No upstream/fork lineage recorded (`UNK-HYRXMQ-002`).
- **SDP scheme conventions are provisional** (`UNK-HYRXMQ-003`); this adoption
  uses the version 0.1.0 schema, future adopters may use different versions.
- **Front-matter convention mismatch** documented: `lib/` domains use
  `document:`/`id:`/`name:`, while SDP project definitions use `title:`/`domain:`.
  Validator expects `title`+`domain` (D-007). Adoption bridges both conventions.

## What This Event Does Not Assert

- It does not assert production readiness. Production readiness is explicitly
  `NOT PROVEN` (`docs/engineering/CURRENT_STATE.md:242`).
- It does not assert completeness of tests, security, or performance evidence.
- It does not freeze the SDP kernel. SDP remains at Concept/Countermodel/Algebra
  stage (SDP-001K §14); no K₅ schema or Lean kernel is created here.
- **It does not claim the SDP scheme is final** (D-006: no provisional-scheme
  escape hatch exists; conventions may evolve across adoptions).

## What This Event Does Not Assert

- It does not assert production readiness. Production readiness is explicitly
  `NOT PROVEN` (`docs/engineering/CURRENT_STATE.md:242`).
- It does not assert completeness of tests, security, or performance evidence.
- It does not freeze the SDP kernel. SDP remains at Concept/Countermodel/Algebra
  stage (SDP-001K §14); no K₅ schema or Lean kernel is created here.

## Relationships

- `SDP-ADOPT-HYRXMQ-0001` REFERENCES `SDP-PROJ-HYRXMQ`
- `SDP-KB-HYRXMQ` DERIVES_FROM `SDP-ADOPT-HYRXMQ-0001`

## Change History

| Version | Date | Change |
|---|---|---|
| 0.1.0 | 2026-09-12 | Initial adoption baseline event. |
