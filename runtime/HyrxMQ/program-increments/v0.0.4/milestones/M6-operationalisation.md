# M6: Operationalisation

**Gate:** E (Operational Readiness)
**Spec:** Sections 38-44

## Sprint 6.1 — Health Endpoints
- [x] `/health` endpoint (existing)
- [x] `/ready` endpoint (existing)
- [ ] Separate liveness vs readiness semantics
- [ ] Recovery state detection

## Sprint 6.2 — Metrics & Observability
- [x] Prometheus format (status.mojo:to_prometheus)
- [ ] Latency histograms (p50/p95/p99/p99.9)
- [ ] `/metrics` HTTP endpoint
- [ ] Connection/queue/exchange counters

## Sprint 6.3 — Structured Logging
- [x] Basic logging (logging.mojo)
- [ ] Connection ID, channel, vhost, identity in logs
- [ ] Error category, severity, timestamp
- [ ] Sensitive data redaction

## Sprint 6.4 — Signal Handling & Graceful Shutdown
- [ ] SIGTERM handler
- [ ] SIGINT handler
- [ ] Shutdown sequence: stop admission → drain → persist → close → exit
- [ ] Health endpoint reflects shutdown state

## Exit Criteria
- [ ] Liveness/readiness separate
- [ ] /metrics endpoint working
- [ ] Graceful shutdown on SIGTERM
