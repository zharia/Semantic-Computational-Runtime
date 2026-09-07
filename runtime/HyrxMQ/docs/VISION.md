# Vision

## The question

What does a messaging engine look like if it is designed from first principles for extremely low-cost local message routing, while retaining the ability to project the same semantics onto IPC and network transports?

Hyrx is an answer to that question.

## Core idea

Messaging semantics should not be dictated by the most expensive transport.

A local message should not need to become a network packet simply because the system also supports network clients.

Likewise, an AMQP client should not need to know how the internal engine represents a message.

## Semantic continuity

The intended progression is:

```text
direct in-process
      |
      v
local IPC
      |
      v
Hyrx-native network
      |
      v
AMQP 0-9-1 interoperability
```

The application-level messaging model can remain conceptually stable while the physical transport changes.

## Simulation as a proving workload

Large agent simulations are an important motivating workload because they can generate enormous numbers of small, latency-sensitive messages between components.

But the simulation is not the architecture.

Hyrx must be equally suitable for:

- services
- actor-like systems
- agent systems
- workflow engines
- telemetry pipelines
- local application components
- distributed applications
- ordinary AMQP clients

## Long-term possibility

A future simulation could represent each creature as a messaging domain containing endpoints such as:

```text
creature/017/perception
creature/017/cognition
creature/017/memory
creature/017/motor
```

Hyrx does not need to understand the word "creature". It only needs to provide the generic endpoint/routing machinery.

This permits future topology changes without changing the messaging substrate.

## Design maxim

> Make the semantic operation cheap first. Add transport cost only when transport is actually required.
