# HyrxMQ

**HyrxMQ is the standalone broker product built on Hyrx, a native Mojo messaging engine designed around low-cost message routing and delivery.**

Hyrx is deliberately independent of any simulation, game, agent framework, semantic-world model, or other application. A simulation may use Hyrx extensively—including as the messaging fabric connecting components of individual agents—but that is a deployment/use case, not an architectural dependency.

HyrxMQ packages the same core technology as a self-contained GNU/Linux/systemd service with AMQP 0-9-1 interoperability, persistence, security, management, observability, and operational tooling.

## North-star architecture

```text
Applications / simulations / agents / services
                    |
               Hyrx API
                    |
          +---------v----------+
          |        Hyrx        |
          | native messaging   |
          | routing + delivery |
          +----+----------+----+
               |          |
          direct/local   transport
               |          |
               |     TCP / TLS / QUIC /
               |     Unix / shared memory
               |          |
               +-----+----+
                     |
               +-----v------+
               |   HyrxMQ   |
               | standalone |
               | AMQP 0-9-1 |
               +------------+
```

The core design principle is:

> **Preserve messaging semantics; minimize the physical work required to realize them.**

AMQP is an interoperability boundary, not the internal representation of every message. Transport is an implementation strategy, not part of the messaging semantics.

## Hard architectural invariants

1. Hyrx is independently buildable, testable, versioned, documented, and deployable.
2. Hyrx SHALL NOT depend on simulation-specific concepts.
3. Hyrx SHALL support direct in-process messaging without requiring a network socket.
4. Hyrx SHALL have transport-independent internal messaging semantics.
5. HyrxMQ SHALL be independently deployable on GNU/Linux with systemd.
6. HyrxMQ SHALL provide AMQP 0-9-1 compatibility as an external interoperability surface.
7. RabbitMQ compatibility SHALL be measured, not assumed.
8. Performance claims SHALL be benchmark-backed and reproducible.
9. Correctness SHALL take precedence over optimization.
10. No optimization SHALL be accepted without evidence that it improves a defined workload without violating semantics or maintainability.
11. Simulation code SHALL remain outside the Hyrx repository/core architecture unless an explicitly generic reusable facility is identified.
12. Hyrx remains single-node initially; distributed consensus and clustering are not hidden requirements.

## Why build this?

Hyrx explores a different point in the messaging design space: a native systems-oriented messaging engine whose cheapest path is local/in-process communication, while still being capable of projecting the same semantic model onto local IPC and network transports.

HyrxMQ then provides a conventional broker surface for applications that need an independently deployable AMQP 0-9-1 server.

The project is not a reimplementation of RabbitMQ internals. RabbitMQ compatibility is a protocol/semantic interoperability goal. Hyrx uses its own architecture.

## Scope

### Core Hyrx

- native Mojo messaging primitives
- messages/envelopes
- endpoints and addressing
- routing
- queues and consumers
- acknowledgement/delivery semantics
- ownership and lifetime management
- scheduling and dispatch
- backpressure
- transport abstraction
- direct in-process transport
- local IPC transports where justified
- Hyrx-native network transports where justified
- instrumentation and benchmark hooks

### HyrxMQ

- AMQP 0-9-1
- TCP baseline transport
- TLS
- SASL authentication
- vhosts and authorization
- exchanges, queues, bindings
- publish/consume
- acknowledgements and negative acknowledgements
- publisher confirms
- QoS/prefetch
- flow control/backpressure
- TTL/dead-lettering/queue limits/priorities where compatibility profile supports them
- persistence and recovery
- management API
- CLI
- browser management UI
- metrics and diagnostics
- GNU/Linux/systemd packaging and operation

### Explicitly out of initial scope

- clustering
- distributed consensus
- federation
- shovel
- distributed queues
- AMQP 1.0
- MQTT
- STOMP
- RabbitMQ plugin compatibility
- Erlang/OTP compatibility
- GPU-dependent broker execution
- simulation-specific APIs in Hyrx Core

## Repository contract

```text
./README.md
./docs/
./public/
```

The root README is the authoritative project orientation. `docs/` is the engineering specification. `public/` contains user-facing explanatory documentation.

See `docs/INDEX.md` for the documentation map.

## Development philosophy

Build from the inside out:

1. native message representation
2. ownership and lifetime
3. routing and delivery
4. direct in-process execution
5. transport abstraction
6. local/network transports
7. AMQP adapter
8. HyrxMQ product surface
9. persistence/security/management
10. qualification and release

Do **not** build an AMQP server first and attempt to extract an embedded engine later.

## Quality standard

Every implementation phase must pass:

**IMPLEMENT → UNIT TEST → INTEGRATION TEST → COMPATIBILITY TEST → BENCHMARK → DOCUMENT → REVIEW → EXIT GATE**

No phase is complete merely because the code compiles.

## Status

This repository specification defines the intended architecture and implementation programme. Implementation decisions that depend on measured Mojo/Linux behavior must be validated experimentally and recorded in the decision log.

## Primary references

- RabbitMQ AMQP 0-9-1 protocol documentation: https://www.rabbitmq.com/amqp-0-9-1-protocol
- RabbitMQ AMQP concepts: https://www.rabbitmq.com/tutorials/amqp-concepts
- Mojo documentation: https://mojolang.org/docs/
- Linux epoll: https://man7.org/linux/man-pages/man7/epoll.7.html
- Linux io_uring: https://man7.org/linux/man-pages/man7/io_uring.7.html
