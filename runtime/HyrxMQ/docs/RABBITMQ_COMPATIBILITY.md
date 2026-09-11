# RabbitMQ Compatibility

## Compatibility is an evidence claim

"RabbitMQ compatible" means a published compatibility matrix backed by automated tests and real client interoperability.

It does not mean identical implementation.

It is never used as an unqualified present-tense claim.

## Current status (v0.0.2 baseline audit, 2026-09-11)

- **Level A (wire interoperability): PROVEN.** pika 1.4.4 successfully completes
  AMQP 0-9-1 connection negotiation (header → start → start-ok → tune → tune-ok
  → open → open-ok) against HyrxMQ. Evidence:
  - `benchmarks/perf/results.json` — full publish→basic_get loop via pika
  - `scripts/interop/pika_negotiation.py` — handshake gate steps PASS
  - `scripts/interop/pika_content.py` — publish→consume→ack and publish→basic_get→ack

- **Level B (semantic interoperability): PARTIALLY PROVEN.**
  - Exchange.declare, queue.declare, queue.bind, basic.publish, basic.deliver,
    basic.get, basic.ack, basic.nack/reject — all demonstrated via pika.
  - Fan-out, routing key matching, delivery tags — demonstrated in benchmarks.
  - NOT YET TESTED: QoS/prefetch via pika, publisher confirms, mandatory publish,
    TTL, dead-letter exchange, priority, alternate exchange, exchange-to-exchange.

- **Level C (extension interoperability): NOT TESTED.**

- **Level D (operational interoperability): NOT TESTED.**

The AMQP adapter is `IMPLEMENTED` at the frame/method level and
`FUNCTIONALLY PROVEN` via real pika client against HyrxMQ and via
differential testing against RabbitMQ 4.3.5 (the reference baseline
`pika_lifecycle.py` captures correct behavior: 18/18 steps PASS against
RabbitMQ).

## Compatibility levels

### Level A — wire interoperability

A real AMQP 0-9-1 client can connect, negotiate, and exchange messages.

### Level B — semantic interoperability

Supported broker behavior matches RabbitMQ/AMQP expectations.

### Level C — extension interoperability

Selected RabbitMQ AMQP extensions work.

### Level D — operational interoperability

Common clients, frameworks, management workflows, and migration scenarios work.

## Matrix

Maintain a machine-readable compatibility matrix covering at least:

- connection negotiation
- channels
- exchanges
- queues
- bindings
- publish
- consume
- ack
- reject/nack
- prefetch/QoS
- confirms
- transactions
- TTL
- dead lettering
- priorities
- alternate exchanges
- exchange-to-exchange bindings
- exclusive queues
- auto-delete
- mandatory publishing
- consumer cancellation
- heartbeats
- authentication
- vhosts
- authorization
- TLS
- error behavior
- recovery after disconnect

Each item must be marked:

- supported
- partially supported
- intentionally unsupported
- not yet tested

## Differential testing

For equivalent workloads, execute against:

1. HyrxMQ
2. a pinned RabbitMQ reference version

Compare:

- successful operations
- returned errors
- delivery counts
- ordering
- acknowledgement behavior
- queue state
- routing
- redelivery
- confirms
- timing only as an informational metric, not correctness

The RabbitMQ version used for comparison must be recorded.

## No false compatibility

If a feature is not implemented, the documentation must say so.

Compatibility claims must identify version and test coverage.
