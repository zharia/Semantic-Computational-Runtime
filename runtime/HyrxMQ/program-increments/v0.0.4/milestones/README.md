# v0.0.4 Milestones & Sprints

**Spec:** `spec.md` (15 phases, 62 sections)
**Baseline:** v0.0.3 — commit `034a9c0`
**Target:** Production Ready
**Release checklist:** `reports/RELEASE_CHECKLIST.md`

---

## Milestone 1: Semantic Correctness & Resource Governance

**Gate:** A (Correctness) + B (Resource Safety)
**Status:** PARTIAL (limits declared; memory admission + `max_unacked` delivery + channel bound are config-only)

### Sprint 1.1 — Baseline Verification
- [x] Record current commit (`034a9c0`)
- [x] Run existing test suite (54/54 pass at baseline)
- [x] Record benchmark baseline (stress suite built)
- [x] Record current documentation state

### Sprint 1.2 — Resource Limits Enforcement
- [x] Max message size validation at publish (reject before allocation)
- [x] Max connections enforcement in listener
- [x] Connection idle timeout
- [x] Max queues/exchanges bounds (enforced)
- [ ] Max channels-per-connection bound (config key only)
- [x] Config keys for all new limits

### Sprint 1.3 — Backpressure & Admission Control
- [ ] Memory admission control (validate before allocate) — config only
- [ ] Backpressure propagation (fast producer / slow consumer) — not wired
- [ ] Bounded unacked delivery enforcement — config contract only

### Sprint 1.4 — Correctness Test Matrix
- [x] Routing matrix test (all exchange types × edge cases)
- [x] Ownership lifecycle test
- [x] Delivery tag correctness test
- [x] Queue semantics test (capacity, TTL, DLX, purge)
- (consolidated as `tests/phase10/correctness_matrix_test.mojo`)

**Exit:** Gate A pass; Gate B partial (see above)

---

## Milestone 2: Security & Multi-Tenant Isolation

**Gate:** C (Security)
**Status:** PARTIAL (auth/vhost/ACL/TLS done; auth-failure rate limiting + dedicated ACL test remain)

### Sprint 2.1 — Authentication Hardening
- [x] SASL PLAIN credential validation (existing table, proper error)
- [x] Connection.close 403 on auth failure
- [ ] Repeated auth failure handling (rate limiting)
- [ ] Auth failure audit logging (counter exposed only)

### Sprint 2.2 — Vhost Namespace Isolation
- [x] Vhost-scoped exchange/queue routing
- [x] Cross-vhost access denial
- [ ] Per-vhost resource limits

### Sprint 2.3 — Authorization ACLs
- [x] Connect permission
- [x] Exchange declare/delete permission
- [x] Queue declare/delete permission
- [x] Publish permission
- [x] Consume permission
- [x] Bind/unbind permission
- (code-verified, invariant R16; no dedicated test)

### Sprint 2.4 — TLS Trust Validation
- [x] Certificate chain validation (`tls_verify_peer`)
- [ ] Hostname validation
- [ ] Expired/revoked certificate handling
- [x] Self-signed certificate behavior (`tls_allow_self_signed`, `tls_ca_path`)

**Exit:** Gate C partial

---

## Milestone 3: Persistence & Failure Durability

**Gate:** D (Durability)
**Status:** COMPLETE (core) — segment rotation + permission/RO-fs cases remain

### Sprint 3.1 — WAL Hardening
- [x] WAL compaction (tombstone reclaim, idempotent)
- [ ] Segment rotation
- [x] Disk-full behavior (disk-failure harness + test)
- [x] Corrupted record handling (`wal_hardening_test.mojo`)

### Sprint 3.2 — Real Process-Kill Testing
- [x] SIGKILL harness (kill during publish → restart → verify)
- [ ] SIGKILL during flush
- [ ] SIGKILL during recovery
- [x] State comparison after recovery

### Sprint 3.3 — Persistence Failure Matrix
- [x] Missing segment handling
- [x] Truncated segment handling
- [ ] Permission failure
- [ ] Read-only filesystem

**Exit:** Gate D pass (core); gaps above

---

## Milestone 4: Transport & Protocol Resilience

**Gate:** Part of Gate G (Robustness)
**Status:** COMPLETE (core) — half-open + wrong-method-in-state remain

### Sprint 4.1 — Network Failure Tests
- [x] Abrupt disconnect test
- [ ] Half-open connection test
- [x] Partial frame test
- [x] Oversized frame test
- [x] Malformed / empty frame

### Sprint 4.2 — Protocol-State Resilience
- [ ] Wrong method in wrong state
- [x] Wrong channel
- [x] Malformed frame handling
- [x] Premature close
- [x] Duplicate operation
- [x] Connection idle timeout

**Exit:** Implemented transport tests pass

---

## Milestone 5: Fuzzing & Adversarial Testing

**Gate:** Part of Gate G
**Status:** PARTIAL — no field-table target; 1M-iteration bar unmet (25k run)

### Sprint 5.1 — Coverage-Guided Fuzzing
- [x] Frame decoding fuzzer (20k)
- [ ] Field table fuzzer
- [x] AMQP state transition fuzzer
- [x] Persistent/deterministic corpus (LCG)

### Sprint 5.2 — Stateful Protocol Fuzzing
- [x] Sequence generator (CONNECT→…→CLOSE)
- [x] Mutation strategies (bit_flip, byte_replace, truncate, duplicate)
- [x] Crash/deadlock/leak detection

**Exit:** No crashes to 25k iterations (1M unmet)

---

## Milestone 6: Operationalisation

**Gate:** E (Operational Readiness)
**Status:** COMPLETE (log-redaction gap)

### Sprint 6.1 — Health Endpoints
- [x] Separate liveness vs readiness
- [x] Kubernetes probe compatibility
- [x] Recovery/shutdown state detection

### Sprint 6.2 — Metrics & Observability
- [x] Prometheus /metrics endpoint
- [x] Latency histograms (p50/p95/p99/p99.9)
- [x] Connection metrics
- [x] Queue depth metrics

### Sprint 6.3 — Structured Logging
- [x] Connection ID, channel, vhost, identity (correlation IDs)
- [x] Error category, severity, timestamp
- [ ] Sensitive data redaction

### Sprint 6.4 — Signal Handling & Graceful Shutdown
- [x] SIGTERM handler
- [x] SIGINT handler
- [x] Shutdown sequence (stop admission → drain → persist → close → exit)

**Exit:** Gate E pass

---

## Milestone 7: Kubernetes Composability

**Gate:** Part of Gate E
**Status:** PARTIAL — manifests present; no StatefulSet, no live-cluster run

### Sprint 7.1 — Kubernetes Manifests
- [x] Deployment manifest
- [ ] StatefulSet manifest
- [x] Service manifest
- [x] ConfigMap template
- [x] Secret template

### Sprint 7.2 — Lifecycle Validation
- [ ] Pod startup test
- [ ] Readiness transition test
- [ ] Graceful termination test (on-cluster)
- [x] Resource limits (manifest)
- [ ] Persistent volume remount test

**Exit:** Manifests structurally valid; deployable not yet proven

---

## Milestone 8: AMQP Interoperability

**Gate:** F (Interoperability)
**Status:** PARTIAL — Python/Node/Java done; Go unavailable

### Sprint 8.1 — Multi-Client Testing
- [x] Python (Pika) — existing
- [x] Node.js (amqplib)
- [ ] Go (amqp091-go) — no toolchain
- [x] Java (RabbitMQ client)

### Sprint 8.2 — Protocol Matrix
- [x] Publisher confirms
- [x] QoS / prefetch
- [x] Mandatory publish / basic.return
- [x] Heartbeat
- [x] Reconnect

**Exit:** Gate F partial

---

## Milestone 9: Performance & Soak Certification

**Gate:** Part of Gate G
**Status:** PARTIAL — certification PASS; 1-hour soak + CI gate remain

### Sprint 9.1 — Performance Certification
- [x] Full benchmark suite execution
- [x] Throughput, p50/p95/p99/p99.9
- [x] CPU/memory per message
- [x] TLS overhead measurement

### Sprint 9.2 — Soak Testing
- [ ] 1-hour continuous operation
- [x] Memory leak detection
- [x] Descriptor leak detection
- [x] Latency degradation monitoring

### Sprint 9.3 — Regression Gate
- [x] Benchmark threshold establishment
- [ ] CI gate integration

**Exit:** Performance baseline established

---

## Milestone 10: Audit & Release

**Gate:** H (Release Reproducibility)
**Status:** COMPLETE

### Sprint 10.1 — Invariant Audit
- [x] Routing authority invariant
- [x] Ownership invariant
- [x] Delivery state invariant
- [x] Resource bounds invariant
- [x] Persistence invariant
- [x] Security invariant

### Sprint 10.2 — Documentation Truth Audit
- [x] All claims verified against implementation
- [x] All known limitations documented
- [x] All unsupported claims removed

### Sprint 10.3 — Release Engineering
- [x] Clean checkout test
- [x] Reproducible build
- [x] Complete test suite pass (68/69; 1 expected)
- [x] Release artifact
- [x] Release notes
- [x] Changelog

**Exit:** Gate H pass → production-ready artifact

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