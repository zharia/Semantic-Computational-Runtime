---
title: hyrxmq
domain: sdp.application.hyrxmq
document: 101_definition
document_type: sdp_application_definition
schema_version: 0.1.0
id: SDP-APP-HYRXMQ
name: hyrxmq
version: 0.1.0
status: adopted
created: 2026-09-12
updated: 2026-09-12
parent: SDP-PROJ-HYRXMQ
authority: SCR
sdp_conformance: SDP-001K
---

# Application hyrxmq

## Purpose

HyrxMQ is the standalone AMQP 0-9-1 broker product built on the Hyrx engine. It
is independently deployable and usable by unrelated applications on an
unrelated host.

## Scope

Inside the Application:

- Broker assembly — exchange, queue, binding, routing, delivery.
- AMQP 0-9-1 service layer — connection/channel lifecycle, methods, confirms,
  transactions, TTL, dead-letter, headers matching.
- Listener — TCP, UDS, WSS; optional TLS; admin HTTP.
- Configuration, structured logging, status, metrics.
- Product lifecycle — process entry points, systemd unit, container image.

Outside the Application:

- The messaging engine itself (`hyrx`), which it consumes.
- Simulation, agent, or game concepts.

## Identity

| Field | Value |
|---|---|
| SDP id | `SDP-APP-HYRXMQ` |
| Name | `hyrxmq` |
| Type | Application |
| Parent | `SDP-PROJ-HYRXMQ` |
| Source root | `runtime/HyrxMQ/src/hyrxmq` |

Note: the Project is `HyrxMQ`; the Application is the executable/service
identifier `hyrxmq`. Capitalisation is normative (`docs/NAMING.md:5-7`).

## Entry Points

| Entry | Artifact | Behaviour |
|---|---|---|
| `src/hyrxmq/main.mojo` | `build/hyrxmq` | Non-hanging in-process self-check; exits 0. |
| `src/hyrxmq/main_listen.mojo` | `build/hyrxmq-listen` | Real accept loop. Systemd `ExecStart=/usr/local/bin/hyrxmq-listen`; container `ENTRYPOINT ["/app/hyrxmq-listen"]`. |

Build from source: `mojo build -I src -I vendor/flare src/hyrxmq/main.mojo -o build/hyrxmq`
and: `mojo build -I src -I vendor/flare src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen`.

## Key Concepts

- **Broker** — the assembly that owns exchanges, queues, bindings, and routing.
- **Service** — the long-running operational lifecycle (the `-listen` binary).
- **Self-check** — the non-hanging in-process proof path.
- **Listener** — the transport accept surface (TCP, UDS, WSS).
- **Product** — the independently deployable packaging of Hyrx.

## Dependencies

- `SDP-APP-HYRX` — engine, embedded API, transport, AMQP codec, storage.
- One-way only: `hyrxmq` → `hyrx`. No reverse dependency, no cycle.

## Invariants

- INV-SDP-HYRXMQ-APP-001: HyrxMQ may depend on Hyrx; Hyrx must not depend on
  HyrxMQ. (`docs/ARCHITECTURE.md:118-120`)
- INV-SDP-HYRXMQ-APP-002: The product must not redefine Hyrx semantics; AMQP is
  a boundary adapter, not an internal canonical representation.
  (`docs/ARCHITECTURE.md:61-83`, `docs/HYRXMQ_PRODUCT.md:19-23`)
- INV-SDP-HYRXMQ-APP-003: Not production-ready while ACLs, timeouts, and HTTP
  metrics are absent. (`docs/engineering/CURRENT_STATE.md:242`)

## Relationships

- `SDP-PROJ-HYRXMQ` CONTAINS `SDP-APP-HYRXMQ`
- `SDP-APP-HYRXMQ` DEPENDS_ON `SDP-APP-HYRX`
- `SDP-APP-HYRXMQ` REFERENCES `docs/HYRXMQ_PRODUCT.md`
- `SDP-APP-HYRXMQ` REFERENCES `docs/PROTOCOL.md`

## Unknowns

- `UNK-HYRXMQ-006` — no declared pixi build targets for `hyrxmq` binaries.

## Change History

| Version | Date | Change |
|---|---|---|
| 0.1.0 | 2026-09-12 | Initial application identity under SDP-ADOPT-HYRXMQ-0001. |
