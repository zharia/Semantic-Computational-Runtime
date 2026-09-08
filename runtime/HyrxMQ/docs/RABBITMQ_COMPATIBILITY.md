# RabbitMQ Compatibility

## Compatibility is an evidence claim

"RabbitMQ compatible" means a published compatibility matrix backed by automated tests and real client interoperability.

It does not mean identical implementation.

It is never used as an unqualified present-tense claim.

## Current status (milestone 0003 audit)

No compatibility level below is met today:

- **Level A (wire interoperability): NOT PROVEN / BLOCKED.** A real AMQP client
  (pika) connects at TCP but cannot complete the handshake — HyrxMQ does not
  consume the 8-octet protocol header and never originates
  `connection.start`/`tune`. See
  `program-increments/v0.0.1-alpha/milestones/0003_phase-1-7-audit/reports/interop_rabbitmq.md`.
- **Levels B–D: NOT TESTED** — unreachable until Level A negotiation exists.
- The AMQP **adapter** is `IMPLEMENTED` at the frame/method level and
  `FUNCTIONALLY PROVEN` only against our own codec and our own test client;
  the reference RabbitMQ baseline (`pika_lifecycle.py`, 18/18 vs RabbitMQ 4.3.5)
  captures the correct-behavior column, but the HyrxMQ differential column is
  `BLOCKED` at negotiation.

The release blockers to unblock Level A are listed in
`.../reports/confidence_matrix.md`.

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
