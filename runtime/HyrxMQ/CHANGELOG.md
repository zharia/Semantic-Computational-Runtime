# Changelog

## v0.0.4 (2026-09-14) — Production Readiness

### Added
- Resource governance: max_message_size, max_queues, max_exchanges, max_channels_per_connection, idle_timeout_secs, max_memory_bytes
- Per-user vhost and ACLs (configure/write/read) with enforcement on all AMQP operations
- Auth failure counter in status and Prometheus metrics
- WAL compaction (idempotent compact() method)
- Connection idle timeout in event-driven loop
- Server-initiated heartbeats via poll loop
- Backpressure: max_unacked per-connection enforcement
- Coverage-guided AMQP fuzz harness (20k iterations)
- In-process soak test with latency percentiles
- AMQP wire-level interop test (56 assertions)
- Latency histograms (9-bucket, publish/consume, Prometheus format)
- Structured logging with correlation IDs
- K8s manifests (Deployment, Service, ConfigMap, Secret, Namespace)
- K8s lifecycle hooks (preStop drain, startup/liveness/readiness probes)
- TLS certificate validation config (tls_verify_peer, tls_allow_self_signed)
- Vhost routing boundary (name-prefix isolation)
- Network failure resilience tests (10 scenarios)
- SIGKILL test plan documentation
- Invariant audit (18 invariants)
- Documentation truth audit
- Security audit

### Changed
- UserRecord now carries vhost, can_configure, can_write, can_read
- BrokerStatus includes auth_failures, publish_latency, consume_latency
- log_json() now accepts correlation_id parameter
- K8s deployment uses preStop sleep for graceful drain

### Fixed
- get-ok message-count now returns real queue depth
- metrics_export_test updated for new status fields
