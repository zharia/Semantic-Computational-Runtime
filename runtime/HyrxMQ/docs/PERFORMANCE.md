# Performance Architecture

## Primary objective

Minimize the physical work required for a valid messaging operation.

## Likely dominant costs

1. network/kernel boundary
2. scheduler wakeups
3. memory movement
4. protocol parsing/serialization
5. synchronization/contention
6. persistence
7. actual routing logic

The ranking must be measured rather than assumed.

## Optimization priorities

### First

- ownership transfer
- buffer reuse
- cache locality
- batching
- sharding
- lock avoidance
- bounded queues

### Then

- protocol codec specialization
- SIMD
- CPU affinity
- NUMA placement
- Linux I/O tuning
- transport-specific optimizations

### Experimental

- shared memory
- io_uring variants
- busy polling
- kernel-assisted zero-copy paths
- QUIC

Every experimental optimization needs an A/B benchmark.

> Current state (milestone 0006): per-byte copy loops replaced with `unsafe_memcpy`
> block copies. 16 KB gap closed (1.24x vs RabbitMQ). 65 KB / 128 KB improved
> ~2x but not at parity (TCP/kernel-level, not application copy loops). Flag
> default ON. In-process codec throughput: ~290 MiB/s at 64 KiB payload.

## I/O

Evaluate epoll and io_uring rather than assuming one is universally superior.

Linux provides epoll for scalable file-descriptor event notification and io_uring as an asynchronous I/O interface. The architecture should allow the reactor implementation to evolve independently of Hyrx semantics.

## Latency classes

Track separately:

- L0 protocol/codec
- L1 Hyrx routing
- L2 scheduling
- L3 transport
- L4 persistence

## Performance invariant

No optimization may silently change:

- delivery semantics
- ordering guarantees
- acknowledgement behavior
- backpressure
- durability guarantees
- error behavior
