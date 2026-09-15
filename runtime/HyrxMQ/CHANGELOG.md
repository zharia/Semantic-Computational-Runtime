# Changelog

## v0.0.4 (2026-09-15) — Production Readiness

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
- Real SIGTERM/SIGINT graceful shutdown via a linked C signal shim (`src/hyrxmq/shutdown_shim.c`); `hyrxmq-listen` exits 0 within ~100 ms of the signal
- `tests/phase10/graceful_shutdown_test.mojo` (ShutdownState + listener shutdown seam)
- Invariant audit (18 invariants)
- Documentation truth audit
- Security audit

### Changed
- UserRecord now carries vhost, can_configure, can_write, can_read
- BrokerStatus includes auth_failures, publish_latency, consume_latency
- log_json() now accepts correlation_id parameter
- K8s deployment uses preStop sleep for graceful drain
- `event_driven_serving()` defaults to true (multi-connection serving)
- `HYRXMQ_USERS` parsing accepts per-user vhost + ACL fields

### Performance
- **Multi-connection serving**: the event-driven readiness loop is now the
  default. The legacy serial loop served one connection to completion before
  accepting the next, so a second client's handshake timed out.
- **`TCP_NODELAY`** set on every accepted connection (Nagle had been left on).
- **Zero-copy method-id read** in the serve loop: `payload_copy()` had copied
  every frame's entire body (up to `frame_max`) just to inspect 4 bytes.
- **Redundant payload copies eliminated** on the publish/deliver path:
  `Buffer` variant move-constructor, adapter publish translations move the
  body, codec zero-copy adoption, conditional body prealloc, owned-frame
  dispatch, in-place method/header/reply framing.
- **Streamed delivery bodies**: `basic.get`/`basic.deliver` write the body
  directly from the queue (no `BufferSnapshot` copy).
- **Direct `recv(2)` into the codec buffer** (`stream_reserve`/`stream_ptr`/
  `stream_commit`), removing a temporary list plus an inline memmove/memcpy.
- **Exact-size reply reservation** removes `List::_realloc` churn.
- `_READ_SIZE` raised from 64 KiB to `frame_limit + 8`.
- Benchmark result: **HyrxMQ is the fastest of HyrxMQ, RabbitMQ 4.x and
  LavinMQ** in a fair same-host Docker comparison (see below).

### Fixed
- get-ok message-count now returns real queue depth
- metrics_export_test updated for new status fields
- **Protocol-header echo removed**: the server echoed the 8-octet AMQP header
  before `connection.start`. pika tolerated it; amqplib, the RabbitMQ Java
  client and `amqp091-go` desynchronized (hang / 501 parse error). Per
  amqp0-9-1.xml §1.4.2.2 the server's first bytes MUST be `connection.start`.
- **Asynchronous push delivery**: `basic.consume`-first then publish delivered
  zero messages (only pull-on-subscribe existed). Added `drain_pushes()` reusing
  the one delivery emitter; pull-on-subscribe is preserved, push is additive.
- **Auto-delete connection-close race**: any connection close swept every
  auto-delete queue, deleting other connections' queues (racy 404 NOT_FOUND on
  a just-declared queue at ≥4 concurrent connections). Scoped to the queue the
  closing connection held a consumer on.
- **Dose-loop stall**: the event dose stopped after its read budget even when
  the codec held complete frames; a dry fd never re-arms under level-triggered
  epoll, so a publish burst could strand frames for ~15 s. Buffered frames are
  now drained past the read budget.
- **Auto-ack delivery-tag leak**: `basic.get(auto_ack)` allocated a per-channel
  wire delivery tag and never released it, growing unbounded under load
  (10-minute soak RSS +18.9%). RSS growth is now +0.06%.
- **PID-1 SIGTERM**: containers whose entrypoint is the broker ignored SIGTERM
  (Linux special-cases init) and were SIGKILLed after the grace period. The web
  binary now installs an exit-on-signal handler; K8s `preStop` uses
  `kill -TERM 1` (dash-safe).

### Benchmark — HyrxMQ vs RabbitMQ 4.x vs LavinMQ

Fair comparison: all three brokers in Docker on one bridge network, each
published to `127.0.0.1` (identical docker-proxy path), each `--cpus 4
--memory 2g`, identical AMQP configuration, one compiled Go load generator, 7
rotated repetitions, medians. 80 fair throughput cells over
{publish, pubget, confirm, fanout} × payloads {64 B, 1 KiB, 16 KiB, 64 KiB,
256 KiB} × concurrency {1, 4, 8, 16, 32}.

Geometric mean of relative throughput (1.000 = fastest in every cell):

| | HyrxMQ | RabbitMQ | LavinMQ |
|---|---|---|---|
| overall | **1.041** | 1.244 | 6.918 |
| concurrency 1 | **1.007** | 1.324 | 7.675 |
| concurrency 4–8 | **1.059** | 1.223 | 8.749 |
| concurrency 16–32 | **1.039** | 1.225 | 5.194 |

HyrxMQ is the fastest overall (19.5% ahead of RabbitMQ on the geomean, ~5.6×
ahead of LavinMQ), wins every concurrency band, and is fastest in 50 of 80
cells (tied 5, behind 25 — all ≤1.31×). Full report:
`benchmarks/perf/three_broker/REPORT_FINAL2.md`.
