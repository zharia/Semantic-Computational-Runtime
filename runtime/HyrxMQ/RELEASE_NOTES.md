# HyrxMQ v0.0.4 — Production Readiness

## What's New
HyrxMQ v0.0.4 completes the production hardening increment. The broker now handles adversarial conditions, resource exhaustion, and Kubernetes lifecycle management.

## Key Features
- **Security**: Per-user vhost isolation and ACLs
- **Resource Governance**: Configurable limits on messages, queues, connections, memory
- **Observability**: Latency histograms, structured logging, Prometheus metrics
- **Resilience**: WAL compaction, idle timeout, backpressure, fuzz testing
- **Kubernetes**: Production-ready manifests with proper lifecycle hooks
- **Throughput**: fastest of HyrxMQ, RabbitMQ 4.x and LavinMQ in a fair
  same-host benchmark (see below)

## Performance

HyrxMQ is **19.5% ahead of RabbitMQ and ~5.6× ahead of LavinMQ** on the overall
geometric-mean throughput of a fair three-broker Docker comparison (same host,
same network path, equal CPU/memory caps, one compiled Go client, 7 rotated
repetitions, medians, 80 cells). HyrxMQ wins every concurrency band and is
fastest in 50 of 80 cells. Peak rates observed: publish 64 B at 32 connections
~676,000 msg/s; publish 1 KiB ~592,000 msg/s; `basic.get` at 16 KiB
~24,700 msg/s.

Representative cells (median msg/s):

| workload | payload | conc | HyrxMQ | RabbitMQ | LavinMQ |
|---|---|---|---|---|---|
| publish | 64 B | 32 | **676,490** | 440,475 | 631,592 |
| publish | 1 KiB | 32 | **592,326** | 358,896 | 569,011 |
| publish | 256 KiB | 32 | **10,832** | 6,856 | 3,381 |
| pubget | 16 KiB | 32 | **24,710** | 20,748 | 1,011 |
| confirm | 1 KiB | 32 | **25,637** | 21,397 | 1,295 |

Full methodology and all 85 cells: `benchmarks/perf/three_broker/REPORT_FINAL2.md`.
This is a single-host, single-client, three-image result; it is not a universal
ranking.

## Reliability

The benchmark and Kubernetes lifecycle testing surfaced and fixed real defects:
serial one-connection serving, an AMQP protocol-header echo that broke non-pika
clients, missing asynchronous push delivery for `basic.consume`, an auto-delete
connection-close race, an intermittent ~15 s frame-stall, an auto-ack
delivery-tag memory leak, and PID-1 SIGTERM handling. See `CHANGELOG.md`.


## Configuration
All new limits have safe defaults. Key environment variables:
- HYRXMQ_MAX_MESSAGE_SIZE (default: 128MB)
- HYRXMQ_MAX_QUEUES (default: 65535)
- HYRXMQ_MAX_EXCHANGES (default: 65535)
- HYRXMQ_IDLE_TIMEOUT_SECS (default: 300)
- HYRXMQ_MAX_MEMORY_BYTES (default: 512MB)

## Upgrading from v0.0.3
- No breaking changes to AMQP protocol behavior
- New config keys are optional (safe defaults)
- ACLs default to full permissions (backward compatible)
