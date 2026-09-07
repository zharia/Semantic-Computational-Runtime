# Hyrx Architecture Invariants

These invariants are binding unless superseded by an explicit architecture
decision record.

## INV-001 — Native Hyrx core

Hyrx Core is implemented natively in Mojo.

## INV-002 — In-process first

The canonical low-cost execution path is in-process.

## INV-003 — Transport independence

Messaging semantics do not depend on a specific transport.

## INV-004 — AMQP is a boundary

AMQP 0-9-1 is an interoperability boundary, not the canonical internal
representation.

## INV-005 — Hyrx Core precedes HyrxMQ

HyrxMQ is assembled from Hyrx Core; Core must not depend on the standalone
product.

## INV-006 — Simulation independence

Hyrx must not know what a simulation, creature, agent, world, or domain-specific
consumer is.

## INV-007 — Single-node scope

Initial HyrxMQ architecture is single-node. Distributed consensus is not a
hidden requirement.

## INV-008 — Semantics before transport

Transport optimizations must not alter messaging semantics.

## INV-009 — Evidence before optimization

Performance claims require reproducible measurements.

## INV-010 — Bounded resources

No production path may rely on accidental unbounded memory, queue, connection,
consumer, confirmation, or transaction growth.

## INV-011 — Ownership is explicit

Message/buffer ownership and lifetime are architecture-level concerns, not
implementation details to defer.

## INV-012 — Management is off the hot path

Management/control functionality must not become a dependency of the hot
message path.

## INV-013 — Compatibility is evidence-based

RabbitMQ interoperability is claimed only for behaviors actually tested.

## INV-014 — Linux is intentional

GNU/Linux/systemd is the target platform. Portability must not distort the
primary architecture.

## INV-015 — No premature abstraction

Abstractions are justified by demonstrated requirements, not by anticipated
features alone.
