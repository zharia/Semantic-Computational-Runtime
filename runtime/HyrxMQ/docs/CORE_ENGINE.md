# Hyrx Core Engine

## Purpose

Hyrx Core is the minimal generic messaging substrate.

It should be possible to unit-test the core without:

- sockets
- systemd
- AMQP
- TLS
- disk
- a browser
- a simulation

## Core concepts

### Message

A message contains payload plus generic metadata required for routing/delivery.

The representation must support:

- immutable/read-only payload views
- ownership transfer
- optional zero-copy references
- metadata without forcing payload copies
- transport-independent identity where required

> Current state (milestone 0003): the engine does **not** do zero-copy.
> `Router.publish` COPIES the payload per destination (twice per byte), and fan-
> out discards `message_id`/headers on the copy (defect D1). See
> `MEMORY_MODEL.md` (defects D1/D2) and the §21 copy investigation in
> `.../0003_phase-1-7-audit/reports/benchmarks.md`. Zero-copy and shared
> references are targets, not present behavior.

### Endpoint

A logical destination/source identity.

The implementation may map semantic addresses to compact internal identifiers for performance.

### Queue

A delivery buffer with explicit ordering, capacity, ownership, and acknowledgement semantics.

### Consumer

A registered delivery target with lifecycle, demand/QoS, and backpressure state.

### Route

A deterministic mapping from publication metadata to one or more delivery targets.

### Envelope

The transport-independent representation of a message plus routing/delivery metadata.

## Hot-path objective

A direct local message path should ideally resemble:

```text
create/acquire
    -> route
    -> enqueue or handoff
    -> dispatch
    -> consume
    -> release
```

The implementation must measure:

- allocations
- copies
- cache misses
- synchronization
- scheduler wakeups
- system calls
- branches
- queue contention

## Public API principle

The public Hyrx API should expose semantic operations, not internal data structures.

Do not make callers depend on slab layouts, queue internals, or protocol frames.

## Determinism

Where ordering is promised, it must be explicit.

Where concurrent ordering is unspecified, documentation must say so.

## Resource limits

Core APIs must support bounded resources and explicit failure/backpressure rather than uncontrolled allocation.
