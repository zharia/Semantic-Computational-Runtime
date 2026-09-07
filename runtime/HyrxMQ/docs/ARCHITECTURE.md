# Architecture

## 1. Architectural layers

### Layer 0 — Hyrx Core

The generic messaging engine:

- message/envelope model
- endpoint identity
- routing
- queues
- consumers
- delivery
- acknowledgement
- backpressure
- scheduling
- ownership
- lifecycle
- instrumentation

No network and no AMQP requirement.

### Layer 1 — Hyrx Embedded

A direct API for applications embedding Hyrx in-process.

This is the cheapest path.

### Layer 2 — Hyrx Local

Local inter-process transports:

- Unix domain sockets
- shared memory, if justified by measured results
- other Linux-native mechanisms where justified

### Layer 3 — Hyrx Network

Hyrx-native network transport(s), initially TCP and potentially QUIC.

### Layer 4 — Protocol adapters

AMQP 0-9-1 is an external adapter.

The adapter translates wire-level protocol operations into Hyrx semantic operations.

### Layer 5 — HyrxMQ

Standalone product assembly:

- Hyrx Core
- network listener(s)
- AMQP adapter
- persistence
- security
- management
- observability
- systemd integration

## 2. Critical separation

The internal engine must not use AMQP frames as its canonical message representation.

Conceptually:

```text
AMQP frame
   |
protocol decoder
   |
canonical Hyrx operation/message
   |
Hyrx routing engine
   |
canonical delivery
   |
protocol encoder
   |
AMQP frame
```

A direct Hyrx producer can bypass the protocol layer entirely.

## 3. Data plane and control plane

Data plane:

- publish
- route
- enqueue
- deliver
- acknowledge
- flow control

Control plane:

- configuration
- topology administration
- users
- permissions
- diagnostics
- metrics
- lifecycle

The control plane must not add work to the hot message path.

## 4. Ownership

Prefer ownership transfer over copying.

Message buffers should have explicit ownership states and well-defined transitions.

Mojo ownership/lifetime facilities are a primary design tool, not something to work around casually.

## 5. Product boundary

HyrxMQ may depend on Hyrx.

Hyrx must not depend on HyrxMQ.

This permits:

- embedded Hyrx without HyrxMQ
- HyrxMQ as a standalone broker
- other products built on Hyrx later

## 6. Architectural anti-patterns

Do not:

- embed simulation concepts in Hyrx
- make AMQP the internal message representation
- make TCP mandatory for Hyrx
- require HyrxMQ for embedded use
- introduce distributed consensus into the single-node core
- optimize before measuring
- sacrifice semantics for benchmark numbers
- add dependencies merely because a conventional broker uses them
