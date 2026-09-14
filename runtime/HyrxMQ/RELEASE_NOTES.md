# HyrxMQ v0.0.4 — Production Readiness

## What's New
HyrxMQ v0.0.4 completes the production hardening increment. The broker now handles adversarial conditions, resource exhaustion, and Kubernetes lifecycle management.

## Key Features
- **Security**: Per-user vhost isolation and ACLs
- **Resource Governance**: Configurable limits on messages, queues, connections, memory
- **Observability**: Latency histograms, structured logging, Prometheus metrics
- **Resilience**: WAL compaction, idle timeout, backpressure, fuzz testing
- **Kubernetes**: Production-ready manifests with proper lifecycle hooks

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
