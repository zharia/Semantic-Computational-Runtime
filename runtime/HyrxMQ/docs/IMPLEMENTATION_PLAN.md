# Implementation Plan

## Programme rule

Do not build HyrxMQ as an AMQP server and later attempt to extract Hyrx.

Build Hyrx first, then project AMQP onto it.

Every phase follows:

**IMPLEMENT → UNIT TEST → INTEGRATION TEST → COMPATIBILITY TEST → BENCHMARK → DOCUMENT → REVIEW → EXIT GATE**

A phase cannot pass its exit gate with "works on my machine" evidence.

---

## Phase 0 — Foundation

### Deliver

- repository structure
- Mojo toolchain baseline
- GNU/Linux baseline
- systemd development service
- CI
- formatting/linting policy
- test harness
- benchmark harness
- documentation framework
- decision log
- compatibility matrix skeleton

### Exit gate

- clean checkout builds
- tests execute
- systemd starts a development service
- health endpoint/command works
- CI is reproducible

---

## Phase 1 — Hyrx Core Value and Memory Substrate

### Deliver

- message
- envelope
- endpoint identity
- buffer/view
- ownership transfer
- pools/slabs
- bounded queues
- lifecycle instrumentation

### Tests

- ownership correctness
- lifetime correctness
- pool exhaustion
- concurrent stress
- leak detection
- copy-count instrumentation

### Exit gate

Core works with no networking and no AMQP dependency.

---

## Phase 2 — Core Routing and Delivery

### Deliver

- publishers
- queues
- consumers
- routing
- dispatch
- acknowledgements
- cancellation
- backpressure

### Exit gate

A direct in-process producer can publish, route, deliver, acknowledge, and release a message correctly.

---

## Phase 3 — Embedded API and Baseline Performance

### Deliver

- stable embedded API
- synchronous/asynchronous usage model as appropriate
- direct transport
- benchmark suite

### Required benchmark

Measure direct:

```text
publish → route → deliver → consume
```

with multiple payload sizes and concurrency levels.

### Exit gate

Baseline latency/throughput and resource metrics are reproducible.

---

## Phase 4 — Local Transports

### Deliver

- Unix domain socket transport
- transport abstraction hardening
- shared-memory prototype only if justified

### Exit gate

Transport conformance tests prove semantic equivalence for supported features.

A shared-memory implementation is optional until benchmark evidence justifies it.

---

## Phase 5 — Hyrx Network Transport

### Deliver

- TCP transport
- connection lifecycle
- framing
- flow control
- reconnect/failure semantics
- optional QUIC investigation

### Exit gate

Independent Hyrx processes can communicate reliably over TCP.

---

## Phase 6 — AMQP 0-9-1 Protocol Adapter

### Deliver

- frame codec
- method/state engine
- channel management
- content headers/body
- negotiation
- heartbeats
- errors
- AMQP-to-Hyrx translation

### Exit gate

A real AMQP client can connect and perform the minimum supported publish/consume path.

---

## Phase 7 — HyrxMQ Minimal Vertical Slice

### Deliver

- standalone executable
- systemd service
- AMQP TCP listener
- exchange
- queue
- binding
- publish
- consume
- ack
- management health/status

### Exit gate

Clean-machine installation followed by real client publish → consume succeeds.

---

## Phase 8 — RabbitMQ Compatibility

### Deliver

- QoS/prefetch
- confirms
- nack/reject
- mandatory publish
- cancellation
- TTL
- DLX
- priorities
- alternate exchanges
- exchange-to-exchange
- transactions if selected
- authentication/vhosts/authorization

### Exit gate

Compatibility matrix has automated tests for every claimed feature and differential tests against a pinned RabbitMQ version.

---

## Phase 9 — Performance Engine

### Deliver

- profiler integration
- hot-path telemetry
- buffer pooling
- batching
- sharding
- routing optimization
- codec specialization
- I/O experiments
- CPU/NUMA experiments

### Exit gate

Every accepted optimization has benchmark evidence and no semantic regression.

---

## Phase 10 — Persistence

### Deliver

- WAL
- segments
- indexing
- checkpoints
- recovery
- durability modes
- crash consistency

### Exit gate

Forced termination/restart recovers expected state across all supported durability modes.

---

## Phase 11 — Security

### Deliver

- TLS
- SASL
- authentication
- vhosts
- authorization
- secure defaults
- hostile-input protection

### Exit gate

Security test suite passes and malformed/untrusted clients cannot crash or corrupt the broker.

---

## Phase 12 — Management API and CLI

### Deliver

- versioned API
- OpenAPI specification
- CLI
- JSON output
- administrative auditing

### Exit gate

Normal administrative workflows can be completed without accessing internal implementation details.

---

## Phase 13 — UI and Observability

### Deliver

- dashboard
- topology
- queues
- exchanges
- bindings
- consumers
- connections
- users/permissions
- metrics
- diagnostics
- storage view

### Exit gate

An administrator can operate, inspect, diagnose, and safely modify the broker through documented workflows.

---

## Phase 14 — Hardening and Qualification

### Deliver

- fuzzing
- stress
- soak
- fault injection
- resource exhaustion
- storage fault tests
- connection storm tests
- concurrency tests
- security review

### Exit gate

No unresolved release-blocking defects.

---

## Phase 15 — Performance Qualification

### Deliver

A reproducible benchmark report comparing:

- Hyrx Core direct
- local transports
- Hyrx-native network
- HyrxMQ AMQP
- RabbitMQ reference

### Exit gate

Performance claims in documentation are backed by reproducible measurements.

---

## Phase 16 — Release Candidate

Freeze:

- compatibility matrix
- public APIs
- management API
- configuration
- persistence format
- systemd behavior
- security defaults
- documentation

### Final acceptance

A clean GNU/Linux machine must be able to:

1. install HyrxMQ
2. start it under systemd
3. configure it
4. connect with a standard AMQP client
5. publish
6. consume
7. acknowledge
8. inspect it through management API/CLI/UI
9. observe metrics
10. restart it
11. recover durable state
12. pass all automated tests
