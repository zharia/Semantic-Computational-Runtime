# v0.0.4 Milestones & Sprints

**Spec:** `spec.md` (15 phases, 62 sections)
**Baseline:** v0.0.3 — commit `034a9c0`
**Target:** Production Ready

---

## Milestone 1: Semantic Correctness & Resource Governance

**Gate:** A (Correctness) + B (Resource Safety)
**Status:** IN PROGRESS

### Sprint 1.1 — Baseline Verification
- [x] Record current commit (`034a9c0`)
- [x] Run existing test suite (54/54 pass)
- [x] Record benchmark baseline (stress suite built)
- [x] Record current documentation state

### Sprint 1.2 — Resource Limits Enforcement
- [ ] Max message size validation at publish (reject before allocation)
- [ ] Max connections enforcement in listener
- [ ] Connection idle timeout
- [ ] Max queues/exchanges/consumers/channels bounds
- [ ] Config keys for all new limits

### Sprint 1.3 — Backpressure & Admission Control
- [ ] Memory admission control (validate before allocate)
- [ ] Backpressure propagation (fast producer / slow consumer)
- [ ] Bounded unacked delivery enforcement

### Sprint 1.4 — Correctness Test Matrix
- [ ] Routing matrix test (all exchange types × edge cases)
- [ ] Ownership lifecycle test
- [ ] Delivery tag correctness test
- [ ] Queue semantics test (capacity, TTL, DLX, purge)

**Exit:** Gate A + Gate B pass

---

## Milestone 2: Security & Multi-Tenant Isolation

**Gate:** C (Security)
**Status:** NOT STARTED

### Sprint 2.1 — Authentication Hardening
- [ ] SASL PLAIN credential validation (existing table, proper error)
- [ ] Connection.close 403 on auth failure
- [ ] Repeated auth failure handling

### Sprint 2.2 — Vhost Namespace Isolation
- [ ] Vhost-scoped exchange/queue routing
- [ ] Cross-vhost access denial
- [ ] Per-vhost resource limits

### Sprint 2.3 — Authorization ACLs
- [ ] Connect permission
- [ ] Exchange declare/delete permission
- [ ] Queue declare/delete permission
- [ ] Publish permission
- [ ] Consume permission
- [ ] Bind/unbind permission

### Sprint 2.4 — TLS Trust Validation
- [ ] Certificate chain validation
- [ ] Hostname validation
- [ ] Expired/revoked certificate handling
- [ ] Self-signed certificate behavior

**Exit:** Gate C pass

---

## Milestone 3: Persistence & Failure Durability

**Gate:** D (Durability)
**Status:** PARTIAL (WAL + recovery exists)

### Sprint 3.1 — WAL Hardening
- [ ] WAL compaction (tombstone reclaim)
- [ ] Segment rotation
- [ ] Disk-full behavior
- [ ] Corrupted record handling

### Sprint 3.2 — Real Process-Kill Testing
- [ ] SIGKILL harness (kill during publish)
- [ ] SIGKILL during flush
- [ ] SIGKILL during recovery
- [ ] State comparison after recovery

### Sprint 3.3 — Persistence Failure Matrix
- [ ] Missing segment handling
- [ ] Truncated segment handling
- [ ] Permission failure
- [ ] Read-only filesystem

**Exit:** Gate D pass

---

## Milestone 4: Transport & Protocol Resilience

**Gate:** Part of Gate G (Robustness)
**Status:** PARTIAL (TCP/TLS/UDS/WSS exist)

### Sprint 4.1 — Network Failure Tests
- [ ] Abrupt disconnect test
- [ ] Half-open connection test
- [ ] Partial frame test
- [ ] Oversized frame test

### Sprint 4.2 — Protocol-State Resilience
- [ ] Wrong method in wrong state
- [ ] Wrong channel
- [ ] Malformed frame handling
- [ ] Premature close
- [ ] Duplicate operation

**Exit:** All transport tests pass

---

## Milestone 5: Fuzzing & Adversarial Testing

**Gate:** Part of Gate G
**Status:** MINIMAL (frame fuzz exists)

### Sprint 5.1 — Coverage-Guided Fuzzing
- [ ] Frame decoding fuzzer
- [ ] Field table fuzzer
- [ ] AMQP state transition fuzzer
- [ ] Persistent corpus

### Sprint 5.2 — Stateful Protocol Fuzzing
- [ ] Sequence generator (CONNECT→OPEN→CHANNEL→DECLARE→PUBLISH→CONSUME→ACK→CLOSE)
- [ ] Mutation strategies (ordering, duplication, omission, malformed values)
- [ ] Crash/deadlock/leak detection

**Exit:** No crashes under 1M fuzz iterations

---

## Milestone 6: Operationalisation

**Gate:** E (Operational Readiness)
**Status:** PARTIAL (health/status endpoints exist)

### Sprint 6.1 — Health Endpoints
- [ ] Separate liveness vs readiness
- [ ] Kubernetes probe compatibility
- [ ] Recovery state detection

### Sprint 6.2 — Metrics & Observability
- [ ] Prometheus /metrics endpoint
- [ ] Latency histograms (p50/p95/p99/p99.9)
- [ ] Connection metrics
- [ ] Queue depth metrics

### Sprint 6.3 — Structured Logging
- [ ] Connection ID, channel, vhost, identity
- [ ] Error category, severity, timestamp
- [ ] Sensitive data redaction

### Sprint 6.4 — Signal Handling & Graceful Shutdown
- [ ] SIGTERM handler
- [ ] SIGINT handler
- [ ] Shutdown sequence (stop admission → drain → persist → close → exit)

**Exit:** Gate E pass

---

## Milestone 7: Kubernetes Composability

**Gate:** Part of Gate E
**Status:** NOT STARTED

### Sprint 7.1 — Kubernetes Manifests
- [ ] Deployment/StatefulSet manifest
- [ ] Service manifest
- [ ] ConfigMap template
- [ ] Secret template

### Sprint 7.2 — Lifecycle Validation
- [ ] Pod startup test
- [ ] Readiness transition test
- [ ] Graceful termination test
- [ ] Resource limits test

**Exit:** K8s manifests deployable

---

## Milestone 8: AMQP Interoperability

**Gate:** F (Interoperability)
**Status:** Pika-only

### Sprint 8.1 — Multi-Client Testing
- [ ] Python (Pika) — existing
- [ ] Node.js (amqplib)
- [ ] Go (amqp091-go)
- [ ] Java (RabbitMQ client)

### Sprint 8.2 — Protocol Matrix
- [ ] Publisher confirms
- [ ] QoS / prefetch
- [ ] Mandatory publish / basic.return
- [ ] Heartbeat
- [ ] Reconnect

**Exit:** Gate F pass

---

## Milestone 9: Performance & Soak Certification

**Gate:** Part of Gate G
**Status:** BENCHMARK BUILT

### Sprint 9.1 — Performance Certification
- [ ] Full benchmark suite execution
- [ ] Throughput, p50/p95/p99/p99.9
- [ ] CPU/memory per message
- [ ] TLS overhead measurement

### Sprint 9.2 — Soak Testing
- [ ] 1-hour continuous operation
- [ ] Memory leak detection
- [ ] Descriptor leak detection
- [ ] Latency degradation monitoring

### Sprint 9.3 — Regression Gate
- [ ] Benchmark threshold establishment
- [ ] CI gate integration

**Exit:** Performance baseline established

---

## Milestone 10: Audit & Release

**Gate:** H (Release Reproducibility)
**Status:** NOT STARTED

### Sprint 10.1 — Invariant Audit
- [ ] Routing authority invariant
- [ ] Ownership invariant
- [ ] Delivery state invariant
- [ ] Resource bounds invariant
- [ ] Persistence invariant
- [ ] Security invariant

### Sprint 10.2 — Documentation Truth Audit
- [ ] All claims verified against implementation
- [ ] All known limitations documented
- [ ] All unsupported claims removed

### Sprint 10.3 — Release Engineering
- [ ] Clean checkout test
- [ ] Reproducible build
- [ ] Complete test suite pass
- [ ] Release artifact
- [ ] Release notes
- [ ] Changelog

**Exit:** Gate H pass → PRODUCTION READY

---

## Execution Order

```
M1 (Correctness + Resources)
  ↓
M2 (Security)
  ↓
M6 (Operationalisation) ← parallel with M3-M5
  ↓
M3 (Persistence) ← parallel with M4-M5
  ↓
M4 (Transport) ← parallel with M5
  ↓
M5 (Fuzzing)
  ↓
M7 (Kubernetes)
  ↓
M8 (Interoperability)
  ↓
M9 (Performance + Soak)
  ↓
M10 (Audit + Release)
  ↓
PRODUCTION READY
```
