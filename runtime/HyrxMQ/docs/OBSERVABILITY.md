# Observability

## Principle

Observability must not become a hidden hot-path tax.

## Implementation status (v0.0.3)

| Surface | Status | Evidence |
|---------|--------|----------|
| Prometheus text export | IMPLEMENTED | `BrokerStatus.to_prometheus()` (`src/hyrxmq/status.mojo`) |
| JSON status export | IMPLEMENTED | `BrokerStatus.to_json()` |
| Structured JSON logging | IMPLEMENTED | `src/hyrxmq/logging.mojo` (`log_json`, `log_level_rank`, `should_log`) |
| Graceful shutdown seam | IMPLEMENTED | `AMQPListener.begin_shutdown()` / `flush_storage()` |
| HTTP `/metrics` endpoint | NOT IMPLEMENTED | formatter exists; no HTTP server wired |
| Histograms (p50/p95/p99) | NOT IMPLEMENTED | — |
| Tracing | NOT IMPLEMENTED | — |
| OS signal handling | NOT IMPLEMENTED | process-level (systemd) |

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
