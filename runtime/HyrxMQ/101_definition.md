---
title: HyrxMQ
domain: sdp.project.hyrxmq
document: 101_definition
document_type: sdp_project_definition
schema_version: 0.1.0
id: SDP-PROJ-HYRXMQ
name: HyrxMQ
version: 0.1.0
status: adopted
created: 2026-09-12
updated: 2026-09-12
parent: null
authority: SCR
sdp_conformance: SDP-001K
---

# HyrxMQ — SDP Project Definition

## Purpose

HyrxMQ is the semantic **Project** that owns the governed development of the
Hyrx messaging engine and the HyrxMQ broker product. This definition establishes
the Project identity, its member Applications, and the relationships between
them.

## Scope

Inside this Project:

- Application `hyrx` — the Hyrx messaging engine and embedded API.
- Application `hyrxmq` — the standalone AMQP 0-9-1 broker product.
- Application `hyrxmq-web` — the browser-based management console for HyrxMQ.

The source topology, specifications, tests, evidence, and knowledge that
already exist under this directory.

Outside this Project:

- The Semantic Computational Runtime semantic library (`lib/`).
- Any simulation, agent, creature, or game ontology.
- RabbitMQ, Erlang/OTP, and any other external broker.

## Identity

| Field | Value |
|---|---|
| SDP id | `SDP-PROJ-HYRXMQ` |
| Name | HyrxMQ |
| Type | Project |
| Root | `runtime/HyrxMQ` |
| Canonical version | `0.1.0-dev` (pixi workspace) |
| Current increment | `v0.0.3` |

Capitalisation is normative: product `HyrxMQ`; technology/substrate `Hyrx`;
executable/service `hyrxmq`. See `docs/PROJECT.md:5-9` and `docs/NAMING.md:5-7`.

## Adoption and Provenance

This Project is **adopted**, not newly bootstrapped. Establishing this definition
is the genesis-equivalent event `SDP-ADOPT-HYRXMQ-0001` (see `001_Adoption/`).
The event records the existing baseline. It does **not** rewrite history and does
**not** claim the Project was newly created.

- First commit touching this path: `6739fef` (2026-09-07) "Added HyrxMQ Project spec".
- Commits under this path at adoption time: 86.
- Baseline commit at adoption: `98bcf9c` (2026-09-11).
- Upstream/fork lineage: not recorded in the repository. Status `UNKNOWN`.

## Semantic Classification

Per SDP-001K §31, Project and Application are derived constructs above the
kernel; they are not kernel primitives. This Project is therefore a governed
grouping, not a new semantic primitive.

## Project → Application Relationships

| Relationship | Target | Consistency |
|---|---|---|
| CONTAINS | `SDP-APP-HYRX` (`src/hyrx`) | provisionally consistent — see caveat |
| CONTAINS | `SDP-APP-HYRXMQ` (`src/hyrxmq`) | consistent |
| CONTAINS | `SDP-APP-HYRXMQ-WEB` (`src/hyrxmq-web`) | consistent |

`src/hyrx` is documented as the Hyrx engine/core and as an embeddable library
(`docs/PROJECT.md:13`, `docs/ARCHITECTURE.md:5-28`, `docs/CORE_ENGINE.md:7-15`).
It also ships a seed executable (`src/hyrx/main.mojo`). Classifying it as an
**Application** is consistent only if "Application" means "buildable unit with an
entry point". As a semantic role, `hyrx` is more precisely a library/component
that also produces a seed artifact. Recorded as `UNK-HYRXMQ-001`. No
implementation change is implied.

`src/hyrxmq` is documented as the standalone broker product and service
(`docs/PROJECT.md:13`, `README.md:63-65`, `docs/HYRXMQ_PRODUCT.md:5`). Its
classification as an Application is consistent.

## Core Concepts

- **Project** — a governed grouping of Applications, specifications, tests, and
  evidence with one identity and one development history.
- **Application** — a buildable member of a Project with at least one executable
  entry point, its own identity, and a declared dependency direction.
- **Component / Library** — a reusable member without an independent operational
  lifecycle. `hyrx` has both Application and Component characteristics.
- **Adoption** — establishment of a baseline for an already-existing Project,
  distinct from bootstrap.
- **Knowledge record** — an adopted, evidence-linked statement about the Project.

## Invariants

- INV-SDP-HYRXMQ-001: Hyrx must remain independent of HyrxMQ and of any
  simulation. (`docs/ARCHITECTURE.md:118-120`, `README.md:67`)
- INV-SDP-HYRXMQ-002: Dependency direction is one-way, `hyrxmq` → `hyrx`.
  (`src/hyrxmq/__init__.mojo:7`)
- INV-SDP-HYRXMQ-003: This definition must not redefine implementation semantics;
  existing specifications remain authoritative for behaviour.

## Application Identities

| SDP id | `SDP-APP-HYRX` |
| Name | `hyrx` |
| Type | Application |
| Parent | `SDP-PROJ-HYRXMQ` |
| Source root | `runtime/HyrxMQ/src/hyrx` |

| SDP id | `SDP-APP-HYRXMQ` |
| Name | `hyrxmq` |
| Type | Application |
| Parent | `SDP-PROJ-HYRXMQ` |
| Source root | `runtime/HyrxMQ/src/hyrxmq` |

| SDP id | `SDP-APP-HYRXMQ-WEB` |
| Name | `hyrxmq-web` |
| Type | Application |
| Parent | `SDP-PROJ-HYRXMQ` |
| Source root | `runtime/HyrxMQ/src/hyrxmq-web` |

## Relationships

- `SDP-PROJ-HYRXMQ` CONTAINS `SDP-APP-HYRX`
- `SDP-PROJ-HYRXMQ` CONTAINS `SDP-APP-HYRXMQ`
- `SDP-APP-HYRXMQ` DEPENDS_ON `SDP-APP-HYRX`
- `SDP-ADOPT-HYRXMQ-0001` REFERENCES `SDP-PROJ-HYRXMQ`
- `SDP-KB-HYRXMQ` REFERENCES `SDP-PROJ-HYRXMQ`

## Knowledge

Adopted project knowledge is recorded in `002_Knowledge/`. Existing
specifications, tests, and evidence are adopted by reference, not copied or
restated as new truth.

## Unknowns and Open Questions

- `UNK-HYRXMQ-001` — Application vs Component classification of `hyrx`.
- `UNK-HYRXMQ-002` — Upstream/fork lineage not recorded.
- `UNK-HYRXMQ-003` — No SDP identity/relationship conventions existed before this
  adoption; the scheme used here is provisional.
- `UNK-HYRXMQ-004` — Provenance mismatch: engineering docs cite commits
  `4ec2a06`/`01e60b6`, the benchmark record cites `c6fb4cc`, HEAD is `98bcf9c`.
- `UNK-HYRXMQ-005` — `src/hyrx` lacks a top-level `__init__.mojo` while its
  subpackages and `src/hyrxmq` have one.
- `UNK-HYRXMQ-006` — no declared pixi build targets for `hyrxmq` binaries.
- `UNK-HYRXMQ-007` — LSP reports `'main()' is not supported within packages`
  for both `src/hyrxmq/main.mojo` and `src/hyrxmq/main_listen.mojo` because
  `src/hyrxmq/__init__.mojo` makes the directory a package.

## Change History

| Version | Date | Change |
|---|---|---|
| 0.1.0 | 2026-09-12 | Initial adoption/baseline definition (SDP-ADOPT-HYRXMQ-0001). |
