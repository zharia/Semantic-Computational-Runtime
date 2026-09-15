# HyrxMQ — AMQP 0-9-1 broker (Mojo)

**HyrxMQ** is a reference implementation of an AMQP 0-9-1 message broker written in
Mojo, built on the Hyrx messaging core. It began as a Phase 0 toolchain seed and now
implements a production-hardened broker vertical slice.

## Current status (v0.0.4)

- **Test suite:** 77 pass / 1 fail (`pixi run test`; the failure is the
  deliberate `assertion_negfail` negative self-test)
- **External interop:** pika 1.4.4, Node `amqplib`, RabbitMQ Java client and
  Go `amqp091-go` all complete handshake/publish/consume/get/ack
  (`MULTI_INTEROP=PASS`)
- **TCP TLS:** proven (TLS 1.3 handshake + AMQP-over-TLS)
- **Persistence:** WAL journal + recovery + compaction, validated by
  SIGKILL, disk-failure, corruption and 1-hour soak tests
- **Performance:** fastest of HyrxMQ, RabbitMQ 4.x and LavinMQ in a fair
  same-host Docker comparison — overall geomean 1.041 vs 1.244 vs 6.918;
  fastest in 50 of 80 throughput cells
- **Kubernetes:** manifests validated live on kind (probes, rollout,
  graceful termination exit 0)

Canonical engineering state: `CHANGELOG.md`, `RELEASE_NOTES.md` and
`program-increments/v0.0.4/reports/V0.0.4_SIGNOFF.md`.

## Roadmap

Outstanding work for the next increment is tracked in
[`program-increments/v0.0.5/ROADMAP.md`](program-increments/v0.0.5/ROADMAP.md):
WAL segment rotation, kill-during-flush/recovery, EACCES/EROFS injection, live
TLS certificate-chain rejection, the 2×-missed-heartbeat close, multi-consumer
per connection, multi-core serving (`SO_REUSEPORT`), the remaining
ownership-bound performance cells, and multi-tier concurrency.

## What HyrxMQ implements

- AMQP 0-9-1: connection/channel lifecycle, exchange/queue declare+bind, publish,
  consume, get, ack/nack/reject (incl. bulk + requeue), QoS/prefetch, publisher
  confirms, transactions, TTL, dead-letter, x-max-length, x-expires,
  exchange-to-exchange, headers exchange matching (x-match all/any), `frame_max`
  / `channel_max` negotiation
- Security: SASL PLAIN, per-user vhost + ACLs (configure/write/read), auth
  failure rate limiting, TLS policy guard, `HYRXMQ_USERS` configuration
- Transports: TCP (+ optional TLS), UDS (incl. abstract namespace), WSS
- Persistence: disabled / memory WAL / file WAL tiers with recovery + compaction
- Operations: Prometheus/JSON metrics, latency histograms, structured JSON
  logging with correlation IDs, `/health` + `/ready`, graceful shutdown seam
- Resource governance: message/queue/exchange/channel/connection/memory limits,
  connection idle timeout, per-connection backpressure

## What HyrxMQ does NOT implement

- WAL segment rotation (single-log WAL)
- Server 2×-missed-heartbeat disconnect
- Multiple consumers on a single connection
- Live rejection of expired / self-signed TLS chains (policy guard only)
- Concurrent transport tiers in one process (UDS *or* TCP at a time)
- Distributed clustering (explicit non-goal; Kubernetes is the orchestration substrate)

## Quick start

```sh
pixi run test              # 77 pass / 1 fail (deliberate negative self-test)
pixi run hyrxmq-listen     # build the broker binary
pixi run hyrxmq-web        # build the web dashboard + embedded broker
bash benchmarks/perf/three_broker/run_three_broker.sh   # three-broker benchmark
```

## Repository shape

```text
.
├── README.md
├── docs/               # design, engineering gates, semantic invariants
│   └── engineering/    # CURRENT_STATE, GATE_01..06, final assessments
├── src/hyrx/           # Hyrx core, transports, AMQP adapter
├── src/hyrxmq/         # broker product (config, listener, service, status)
├── src/hyrxmq_web/     # web dashboard + embedded broker
├── tests/phase0..10/    # phase test suites
├── tests/integration/   # end-to-end transport tests
├── benchmarks/          # performance harness + three-broker comparison
├── scripts/interop/     # external client proofs (pika, Node, Java, Go, TLS)
├── k8s/                 # Kubernetes manifests
└── program-increments/  # v0.0.1-alpha .. v0.0.4 programmes; v0.0.5 roadmap
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
