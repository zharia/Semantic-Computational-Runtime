# Concurrency Model

## Goals

- high throughput
- low tail latency
- predictable contention
- minimal global synchronization
- clear ownership

## Initial principle

Prefer ownership/sharding over global locks.

Potential partitioning dimensions:

- connection
- channel
- queue
- exchange
- routing shard
- CPU/core

The exact partitioning must be benchmark-driven.

## Scheduler

The scheduler must distinguish:

- I/O readiness
- routing work
- queue work
- consumer dispatch
- persistence work
- control-plane work

Avoid allowing management or persistence operations to unexpectedly block the hot path.

## Ordering

Ordering guarantees must be defined per scope.

Potential scopes:

- publisher stream
- channel
- queue
- consumer

Concurrency must never accidentally weaken a documented guarantee.

## Backpressure

Backpressure must propagate rather than merely moving unbounded buffers deeper into the system.

Potential signals:

- queue capacity
- consumer demand
- memory pressure
- persistence pressure
- connection flow control

## NUMA

NUMA-aware placement may be added after baseline profiling.

Do not add topology complexity without evidence.
