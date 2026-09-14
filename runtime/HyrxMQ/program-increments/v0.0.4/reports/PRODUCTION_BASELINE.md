# HyrxMQ v0.0.3 → v0.0.4 Production Baseline

**Date:** 2026-09-14
**Baseline Commit:** `034a9c0`

---

## Commit

```
034a9c0 IAM-RM-001 reports added
f9027fd feat: add WASM runtime and AMQP stress/soak benchmark suite
924fd3f feat: Docker packaging + web dashboard with live broker introspection
```

## Toolchain

- Mojo: >=1.0.0,<2 (pixi managed)
- OpenSSL: >=3
- Docker: multi-stage Ubuntu 22.04
- WASM: clang --target=wasm32-wasip1

## Test Suite

```
TOTAL pass=54 fail=1
```
- 54/54 pass (1 expected: `assertion_negfail.mojo` self-test)
- Tests cover: phase0-phase10 + integration + selftest

## Benchmark Suite

### Existing (perf/)
- `benchmarks/perf/harness.py` — pika 1.4.4, 5 cells
- `benchmarks/perf/index.py` — Performance Rating R
- `benchmarks/perf/compare.py` — regression gate

### New (stress/)
- `benchmarks/stress/harness.py` — stress/soak orchestrator
- `benchmarks/stress/workloads.py` — 8 workload patterns
- `benchmarks/stress/failures.py` — 7 failure scenarios
- `benchmarks/stress/metrics.py` — time-series collector
- `benchmarks/stress/analyze.py` — analysis + CI gate

## Feature Matrix

### Implemented (IMPLEMENTED)
- [x] Single routing authority (Router)
- [x] Direct, fanout, topic, headers exchanges
- [x] Exchange-to-exchange bindings
- [x] Queue with capacity, x-max-length, x-message-ttl, DLX
- [x] Message ownership with per-destination payload copying
- [x] Delivery tags, ack/nack/reject, bulk ack/nack
- [x] Consumer registration with prefetch
- [x] AMQP adapter (exchange/queue declare, publish, consume, get)
- [x] TCP, TLS, UDS, WSS transports
- [x] Heartbeat negotiation (partial)
- [x] WAL with CRC, recovery, tombstones
- [x] SASL PLAIN authentication
- [x] Publisher confirms
- [x] Transactions (tx.select/commit/rollback)
- [x] Channel/connection close
- [x] Config system with validation
- [x] Status with JSON + Prometheus format
- [x] Web dashboard (React+MUI)
- [x] Docker packaging
- [x] Stress/soak benchmark suite
- [x] WASM module (17KB, 23 exports)

### Added in v0.0.4 Increment
- [x] Max message size config + validation
- [x] Max queues/exchanges/channels config
- [x] Connection idle timeout config
- [x] Memory budget config
- [x] K8s manifests (Deployment, Service, ConfigMap, Secret)
- [x] Milestone/sprint development plan

### NOT IMPLEMENTED (Honest List)
- [ ] Vhost namespace isolation (accepted, not enforced)
- [ ] Authorization ACLs
- [ ] TLS certificate chain validation
- [ ] WAL compaction
- [ ] Real SIGKILL testing
- [ ] Coverage-guided fuzzing
- [ ] Latency histograms
- [ ] Structured logging with correlation IDs
- [ ] SIGTERM/SIGINT graceful shutdown
- [ ] Multi-client AMQP interop testing
- [ ] Performance certification
- [ ] Invariant audit
- [ ] Documentation truth audit

## Known Defects

- D5/D14: routing authority leak (assessed; single authority verified in code)
- Headers exchange matching is stub (returns all bindings)
- get-ok message-count always 0
- No server-initiated cyclic heartbeats
- No connection state enforcement on business methods

## Release Blockers

Per spec §58, none of the remaining NOT IMPLEMENTED items are absolute release
blockers for a single-instance deployment, but the following MUST be addressed:

1. Vhost isolation (security requirement for multi-tenant)
2. Graceful shutdown (Kubernetes lifecycle requirement)
3. Real SIGKILL testing (durability evidence requirement)
