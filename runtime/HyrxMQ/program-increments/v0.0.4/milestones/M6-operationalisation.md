# M6: Operationalisation

**Gate:** E (Operational Readiness)
**Status:** COMPLETE — health/readiness separate, Prometheus metrics, structured
logging with correlation IDs, and real signal-driven graceful shutdown.
**Spec:** Sections 38-44

## Sprint 6.1 — Health Endpoints ✅
- [x] `/health` liveness endpoint (served by `src/hyrxmq_web/hyrxmq_web.mojo`)
- [x] `/ready` readiness endpoint (503 when not ready / during shutdown)
- [x] Separate liveness vs readiness semantics
- [x] Recovery/shutdown state reflected in `/ready` (degrades to 503)

## Sprint 6.2 — Metrics & Observability ✅
- [x] Prometheus format (status.mojo:to_prometheus)
- [x] Latency histograms (9-bucket, publish/consume; p50/p95/p99/p99.9)
- [x] `/metrics` HTTP endpoint (web module)
- [x] Connection/queue/exchange counters (incl. `hyrxmq_auth_failures`, queue depth)
- Tested: `tests/phase10/metrics_export_test.mojo`

## Sprint 6.3 — Structured Logging ✅ (redaction gap)
- [x] JSON record rendering + escaping (logging.mojo)
- [x] Connection ID, channel, vhost, identity via correlation IDs
- [x] Error category, severity, timestamp
- [ ] Sensitive data redaction — **NOT DONE**: no credential/secret scrubbing pass.
- Tested: `tests/phase10/logging_test.mojo`

## Sprint 6.4 — Signal Handling & Graceful Shutdown ✅
- [x] SIGTERM handler (linked C shim `src/hyrxmq/shutdown_shim.c`)
- [x] SIGINT handler
- [x] Shutdown sequence: stop admission → drain → persist → close → exit
- [x] Health endpoint reflects shutdown state (503)
- Tested: `tests/phase10/graceful_shutdown_test.mojo`; `hyrxmq-listen` exits 0
  within ~100 ms of signal.

## Exit Criteria
- [x] Liveness/readiness separate
- [x] /metrics endpoint working
- [x] Graceful shutdown on SIGTERM
- [ ] Log redaction