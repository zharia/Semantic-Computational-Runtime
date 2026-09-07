# Observability

## Principle

Observability must not become a hidden hot-path tax.

## Metrics

Expose at least:

- messages published
- messages routed
- messages delivered
- messages acknowledged
- redeliveries
- rejects/nacks
- confirms
- queue depth
- consumer count
- connection count
- channel count
- bytes in/out
- routing latency
- delivery latency
- persistence latency
- errors
- dropped/rejected messages
- resource usage

## Histograms

Latency histograms should support:

- p50
- p95
- p99
- p99.9

where measurement cost is acceptable.

## Tracing

Tracing should be optional and sampling-aware.

Never make verbose tracing the default for high-throughput production workloads.

## Diagnostics

Provide controlled diagnostic snapshots for:

- topology
- connections
- queues
- consumers
- resource pressure
- persistence
- scheduler
- transport
