---
title: hyrx
domain: sdp.application.hyrx
document: 101_definition
document_type: sdp_application_definition
schema_version: 0.1.0
id: SDP-APP-HYRX
name: hyrx
version: 0.1.0
status: adopted
created: 2026-09-12
updated: 2026-09-12
parent: SDP-PROJ-HYRXMQ
authority: SCR
sdp_conformance: SDP-001K
---

# Application hyrx

## Purpose

Hyrx is the native Mojo messaging engine: a self-contained core for low-cost
message routing and delivery, usable in-process without networking or AMQP.

## Scope

Inside the Application:

- Layer 0 Hyrx Core — Message, Queue, Exchange, Consumer, Route, Envelope.
- Layer 1 Hyrx Embedded — in-process API (`src/hyrx/embedded/api.mojo`).
- Layer 2/3 transports — UDS, TCP, WSS, poll, flow control, HTTP admin.
- Layer 4 AMQP 0-9-1 adapter — codec, frames, field tables, connection state.
- A Phase 0 seed executable.

Outside the Application:

- The broker product, configuration, listener, and service lifecycle (`hyrxmq`).
- Any simulation, agent, or game ontology.

## Identity

| Field | Value |
|---|---|
| SDP id | `SDP-APP-HYRX` |
| Name | `hyrx` |
| Type | Application |
| Parent | `SDP-PROJ-HYRXMQ` |
| Source root | `runtime/HyrxMQ/src/hyrx` |
| Version source | `src/hyrx/version.mojo` → `0.1.0-dev` |

## Classification and Caveat

Documented primary role: **engine / embeddable library** (`docs/PROJECT.md:13`,
`docs/CORE_ENGINE.md:7-15`, `docs/ARCHITECTURE.md:5-28`). It also produces a seed
executable. It is classified here as an **Application** because it has an entry
point and a build target, and the `__init__.mojo` at `src/hyrx/__init__.mojo:1`
now provides the product-layer marker that `hyrxmq` depends on. The more
precise role is Component/Library with a seed artifact, but Application
classification is consistent given the entry point + `__init__.mojo`.

**Resolution**: `UNK-HYRXMQ-005` is **resolved** — `__init__.mojo` added at
`src/hyrx/__init__.mojo:1`. Classification remains `Application` with the
caveat described above.

## Entry Points

| Entry | Artifact | Behaviour |
|---|---|---|
| `src/hyrx/main.mojo` | `build/hyrx` | Prints `Hyrx Phase 0 seed` / `status=bootstrap`; no messaging. |

Build task: `pixi run build` (only build target in `pixi.toml`).

## Key Concepts

- **Engine** — the routing and delivery core.
- **Embedded API** — the in-process surface a host application binds to.
- **Transport** — an interchangeable channel; not a semantic dependency.
- **Protocol adapter** — AMQP translation at the boundary; not the internal
  canonical representation.
- **Seed artifact** — the non-messaging Phase 0 executable.

## Exposed Capabilities

The embedded API (`src/hyrx/embedded/api.mojo`) exposes `HyrxConfig`,
`HyrxStats`, `HyrxEngine`, journal attach/recover, topology declaration and
binding, publish/consume/ack/reject/nack, queue and exchange management, and
readouts. This is the surface a host application embeds.

## Dependencies

- Vendored `flare` submodule (`vendor/flare`, MIT) — transports.
- OpenSSL (conda-forge) — TLS tier.
- Standard library only otherwise.

Dependency direction: `hyrx` MUST NOT depend on `hyrxmq` or on any simulation.
(`docs/PROJECT.md:17-27`, `src/hyrxmq/__init__.mojo:7`)

## Invariants

- INV-SDP-HYRX-001: Hyrx SHALL NOT require a simulation, agent ontology, game
  engine, semantic-world model, RabbitMQ, Erlang/OTP, internal AMQP framing, or
  network for in-process use. (`docs/PROJECT.md:17-27`)
- INV-SDP-HYRX-002: Nothing in `hyrx` may import `hyrxmq`.
- INV-SDP-HYRX-003: Hyrx Core must be unit-testable without sockets, systemd,
  AMQP, TLS, disk, or a browser. (`docs/CORE_ENGINE.md:7-15`)

## Relationships

- `SDP-PROJ-HYRXMQ` CONTAINS `SDP-APP-HYRX`
- `SDP-APP-HYRXMQ` DEPENDS_ON `SDP-APP-HYRX`
- `SDP-APP-HYRX` REFERENCES `docs/CORE_ENGINE.md`
- `SDP-APP-HYRX` REFERENCES `docs/ARCHITECTURE.md`

## Unknowns

- `UNK-HYRXMQ-001` — Application vs Component classification (resolved as Application
  with caveat per Classification and Caveat section; see UNK-005 resolution).

## Change History

| Version | Date | Change |
|---|---|---|
| 0.1.0 | 2026-09-12 | Initial application identity under SDP-ADOPT-HYRXMQ-0001. |
