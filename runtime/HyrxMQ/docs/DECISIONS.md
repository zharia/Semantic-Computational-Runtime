# Architecture Decision Log

This file records decisions that should not be casually reversed.

## ADR-001 — Hyrx is independent of simulation

**Decision:** Hyrx is a general-purpose messaging system. Simulation is an external consumer.

**Reason:** preserves reuse, independent deployment, and architectural integrity.

## ADR-002 — Hyrx Core precedes HyrxMQ

**Decision:** build the native engine before the AMQP broker product.

**Reason:** prevents AMQP framing and network assumptions from contaminating the core.

## ADR-003 — AMQP is an adapter boundary

**Decision:** AMQP 0-9-1 is represented at the product/protocol boundary, not as the canonical internal message representation.

**Reason:** enables direct and alternative transports.

## ADR-004 — Single-node first

**Decision:** no clustering/distributed consensus in the initial architecture.

**Reason:** performance and correctness can be optimized without premature distributed complexity.

## ADR-005 — GNU/Linux/systemd only

**Decision:** Linux and systemd are normative deployment targets.

**Reason:** permits deliberate exploitation of Linux I/O, scheduling, filesystem, and service-manager capabilities.

## ADR-006 — Transport independence

**Decision:** direct, local, and network transports are implementations of the same semantic substrate.

**Reason:** enables performance optimization without changing application messaging semantics.

## ADR-007 — Compatibility is measured

**Decision:** RabbitMQ compatibility is an evidence-backed matrix, not a branding assertion.

## ADR-008 — Optimization requires measurement

**Decision:** no performance optimization is accepted without A/B or equivalent evidence and semantic regression testing.

## ADR-009 — Flare is a pinned transport provider (decisions/0005)

**Decision:** vendor flare v0.10.0 (submodule, `-I` source build) for TCP/UDS; only `src/hyrx/transport/*` may import it, never `src/hyrx/core`.

**Reason:** real sockets without ABI lock or build-backend; provider stays subordinate to the transport contract.
