# Benchmarking

## Philosophy

Benchmark the architecture, not marketing claims.

## Performance dimensions

Measure:

- throughput messages/sec
- throughput bytes/sec
- p50/p95/p99/p99.9 latency
- CPU/message
- allocations/message
- bytes copied/message
- memory/message
- syscalls/message
- context switches
- scheduler wakeups
- queue contention
- routing cost
- protocol decode/encode cost
- persistence cost
- recovery time

## Benchmark classes

### Core

Direct in-process publish → consume.

### Local

Hyrx-to-Hyrx over:

- direct
- Unix domain sockets
- shared memory if implemented

### Network

Hyrx-native TCP/QUIC.

### Compatibility

AMQP 0-9-1 over TCP/TLS.

### Durable

Each persistence mode separately.

## Methodology

Record:

- exact build
- CPU
- OS/kernel
- runtime configuration
- message size
- topology
- producer/consumer count
- concurrency
- persistence mode
- transport
- warm-up period
- sample count
- measurement tool/version

Avoid reporting a single number as "performance".

## RabbitMQ comparison

Use identical hardware and comparable semantics.

Report both:

- throughput
- latency distribution
- resource consumption

Never tune HyrxMQ to an artificial benchmark that removes required semantics.
