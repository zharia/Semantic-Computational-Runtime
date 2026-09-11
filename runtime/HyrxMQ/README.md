# HyrxMQ — AMQP 0-9-1 broker (Mojo)

**HyrxMQ** is a reference implementation of an AMQP 0-9-1 message broker written in
Mojo, built on the Hyrx messaging core. It began as a Phase 0 toolchain seed and now
implements a working broker vertical slice.

## Current status (v0.0.3)

- **Test suite:** 52/0 PASS (`pixi run test`)
- **External interop:** pika 1.4.4 completes AMQP handshake/publish/consume/get/ack
- **TCP TLS:** proven (TLS 1.3 handshake + AMQP-over-TLS; `scripts/interop/tls_probe.py`)
- **Persistence:** WAL journal + recovery, validated by crash/corruption/IO-failure tests
- **Performance:** ~1.43x RabbitMQ 4.3.5 in the closed-loop benchmark

Canonical engineering state:
`docs/engineering/CURRENT_STATE.md` and
`docs/engineering/FINAL_ENGINEERING_ASSESSMENT_v0.0.3.md`.

Programme increments: `program-increments/v0.0.2/` and `program-increments/v0.0.3/`.

## What HyrxMQ implements

- AMQP 0-9-1: connection/channel lifecycle, exchange/queue declare+bind, publish,
  consume, get, ack/nack/reject, QoS, publisher confirms, transactions, TTL,
  dead-letter, x-max-length, exchange-to-exchange, headers exchange matching
- Transports: TCP (+ optional TLS), UDS (incl. abstract namespace), WSS
- Persistence: disabled / memory WAL / file WAL tiers with recovery
- Operations: Prometheus/JSON metrics, structured JSON logging, shutdown seam

## What HyrxMQ does NOT implement

- Per-resource authorization (ACLs / multiple vhosts)
- Connection / I/O timeouts and connection limits
- HTTP `/metrics` endpoint, latency histograms, tracing
- TLS on UDS; async push-after-subscribe; server cyclic heartbeats
- Distributed clustering; WAL compaction

## Quick start

```sh
pixi run test        # 52/0 PASS
pixi run bench-direct
```

## Repository shape

```text
.
├── README.md
├── docs/               # design, engineering gates, semantic invariants
│   └── engineering/    # CURRENT_STATE, GATE_01..06, final assessments
├── src/hyrx/           # Hyrx core, transports, AMQP adapter
├── src/hyrxmq/         # broker product (config, listener, service, status)
├── tests/phase0..10/    # phase test suites
├── tests/integration/   # end-to-end transport tests
├── benchmarks/          # performance harness
├── scripts/interop/     # external client proofs (pika, TLS)
└── program-increments/  # v0.0.1-alpha, v0.0.2, v0.0.3 programmes
```

## Naming

- **Hyrx** — native messaging technology/core.
- **HyrxMQ** — standalone broker product/runtime.
- `hyrxmq` — standalone service/binary naming.

Hyrx Core must remain independent of HyrxMQ and independent of any simulation.

## Evidence rule

If a toolchain feature, API, protocol behavior, optimization, or compatibility
claim has not been demonstrated in the current environment, record it as
`NOT PROVEN`.

Do not replace missing evidence with assumptions.
