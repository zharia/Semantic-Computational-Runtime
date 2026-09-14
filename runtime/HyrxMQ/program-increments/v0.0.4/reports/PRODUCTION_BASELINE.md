# HyrxMQ v0.0.4 Production Baseline

**Date:** 2026-09-14
**Baseline Commit:** `f46e277` + M2-M10 additions

---

## Test Suite

```
TOTAL pass=59 fail=1
```
- 59/59 pass (1 expected: `assertion_negfail.mojo` self-test)
- Tests cover: phase0-phase10 + integration + selftest + fuzz + soak + interop

## Feature Matrix — v0.0.4 Complete

### Resource Governance (M1)
- [x] max_message_size — enforced at content header stage
- [x] max_queues — enforced at queue.declare
- [x] max_exchanges — enforced at exchange.declare
- [x] max_channels_per_connection — config field
- [x] connection idle timeout — enforced in event-driven loop
- [x] max_memory_bytes — config field

### Security (M2)
- [x] SASL PLAIN authentication (403 on failure)
- [x] Per-user vhost assignment
- [x] Per-user ACLs (configure/write/read)
- [x] ACL enforcement on exchange.declare, queue.declare, basic.publish, basic.consume, basic.get
- [x] Auth failure counter (exposed in status + Prometheus)
- [x] Connection cleanup on close

### Persistence (M3)
- [x] WAL with CRC, recovery, tombstones
- [x] WAL compaction (compact() method, idempotent)
- [x] SIGKILL test plan documented

### Transport Resilience (M4)
- [x] Connection idle timeout (configurable, monotonic-based)
- [x] Idle check in event-driven serving loop
- [x] Per-connection last_active tracking

### Fuzzing (M5)
- [x] 20,000-iteration coverage-guided fuzz harness
- [x] Deterministic LCG (reproducible)
- [x] Mutations: bit_flip, byte_replace, truncate, duplicate
- [x] 0 service exceptions, 0 crashes

### Operationalisation (M6)
- [x] /health liveness probe
- [x] /ready readiness probe (503 when not ready)
- [x] Structured JSON logging with correlation IDs
- [x] Publish/consume latency histograms (9-bucket)
- [x] K8s lifecycle hooks (preStop + drain delay)

### Kubernetes (M7)
- [x] Namespace, Deployment, Service, ConfigMap, Secret manifests
- [x] Liveness/readiness/startup probes
- [x] Resource requests/limits
- [x] Graceful shutdown (preStop sleep + SIGTERM)

### Interoperability (M8)
- [x] AMQP 0-9-1 wire-level interop test (56 assertions)
- [x] Protocol header, SASL, channel, exchange, queue, publish, get, ack, close

### Performance (M9)
- [x] In-process soak test (5000 msgs, bounded memory)
- [x] Latency percentiles (p50/p95/p99)
- [x] Throughput certification (>= 5000 msgs/sec target)

### Audit (M10)
- [x] Invariant audit (18 invariants, 16 enforced+tested, 2 gaps documented)
- [x] Documentation truth audit (4 false claims found and corrected)
- [x] Security audit (auth, ACLs, vhost, error safety, limits)

## Remaining Gaps (Honest)

- [ ] TLS certificate chain validation (expired/self-signed)
- [ ] Real SIGKILL testing (requires Docker orchestration)
- [ ] Server-initiated cyclic heartbeats (no timer subsystem)
- [ ] Vhost as resource boundary (currently cosmetic — recorded but not partitioned)
- [ ] Headers exchange matching (stub: returns all bindings)

## Known Defects

- Headers exchange matching is stub (returns all bindings)
- No server-initiated cyclic heartbeats
- No connection state enforcement on business methods
- Vhost recorded per-connection but not enforced as routing boundary
