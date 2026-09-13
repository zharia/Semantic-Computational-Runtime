# Application hyrxmq-web

## Purpose

HyrxMQ web interface: a browser-based management console for the HyrxMQ broker.
Provides a web UI for monitoring, configuration, and message inspection.

## Scope

Inside the Application:
- Web server surface (HTTP/TLS)
- API endpoints for broker status, queue monitoring, message publishing
- Administration UI
- Configuration editor
- Real-time metrics visualization

Outside the Application:
- The HyrxMQ broker itself (hyrxmq)
- The Hyrx engine (hyrx)
- Simulation, agent, or game concepts

## Identity

| Field | Value |
|---|---|
| SDP id | `SDP-APP-HYRXMQ-WEB` |
| Name | `hyrxmq-web` |
| Type | Application |
| Parent | `SDP-PROJ-HYRXMQ` |
| Source root | `runtime/HyrxMQ/src/hyrxmq-web` |
| Version source | `src/hyrxmq-web/version.mojo` → `0.1.0-dev` |

Classification: **Application** — buildable web interface with entry point.

## Entry Points

| Entry | Artifact | Behaviour |
|---|---|---|
| `src/hyrxmq-web/main.mojo` | `build/hyrxmq-web` | Web server entry point; serves HTTP UI and API |

Build task: manual (not in pixi.toml — served as static binary or container image).

## Key Concepts

- **Web UI** — browser management console for broker state
- **API** — RESTful endpoints for status/control
- **TLS** — optional HTTPS termination
- **Metrics** — Prometheus-compatible export from broker status
- **Self-check** — in-process health probe

## Dependencies

- `SDP-APP-HYRX` — Hyrx engine (embedded API, journal)
- `SDP-APP-HYRXMQ` — HyrxMQ broker (AMQP service)
- `vendor/flare` — transport (for any WebSocket transport)
- OpenSSL (conda-forge) — TLS if HTTPS enabled

Dependency direction: `hyrxmq-web` depends on `hyrx` and `hyrxmq`; neither `hyrx/` nor `hyrxmq/` may import `hyrxmq-web`.

## Invariants

- INV-SDP-HYRXMQ-WEB-001: HyrxMQ web UI must not bind to a port already in use by hyrxmq-listen (port conflict avoidance). (`docs/ARCHITECTURE.md:118-120`)
- INV-SDP-HYRXMQ-WEB-002: Web UI TLS cert/key must match broker TLS config if TLS is enabled shared termination. (`docs/ARCHITECTURE.md:61-83`)
- INV-SDP-HYRXMQ-WEB-003: Web UI must not redefine Hyrx or HyrxMQ semantics; it only presents a view. (`docs/ARCHITECTURE.md:118-120`)

## Relationships

- `SDP-PROJ-HYRXMQ` CONTAINS `SDP-APP-HYRXMQ-WEB`
- `SDP-APP-HYRXMQ-WEB` DEPENDS_ON `SDP-APP-HYRX`
- `SDP-APP-HYRXMQ-WEB` DEPENDS_ON `SDP-APP-HYRXMQ`
- `SDP-APP-HYRXMQ-WEB` REFERENCES `docs/HYRXMQ_PRODUCT.md`

## Unknowns

- `UNK-HYRXMQ-xxx` — Web UI routing semantics (to be resolved in later increment)

## Change History

| Version | Date | Change |
|---|---|---|
| 0.1.0 | 2026-09-12 | Initial application identity under SDP-ADOPT-HYRXMQ-0001. |