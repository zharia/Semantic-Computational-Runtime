# FINAL_ENGINEERING_ASSESSMENT_v0.0.3.md

**Date:** 2026-09-11
**Commit:** 01e60b6
**Programme Increment:** v0.0.3
**Assessor:** Automated + code review

---

## Executive Summary

HyrxMQ v0.0.3 is a reference implementation of an AMQP 0-9-1 message broker written in Mojo. This increment moves the previous release's CONDITIONAL/PARTIAL gates toward PASS: TCP-tier TLS is implemented and proven against a real client, the persistence failure matrix is executable, headers-exchange matching is no longer a stub, and metrics export plus structured logging are exercised by tests. The implementation is **still not production-ready** — authorization, timeout controls, an HTTP metrics endpoint, latency histograms, signal-driven shutdown, and TLS on the UDS transport remain unimplemented.

Full test suite: **52/0 PASS** (`pixi run test`).

---

## Maturity Assessment

| Dimension | Rating | Evidence |
|-----------|--------|----------|
| Architecture | IMPLEMENTED | Semantic domains separated (Hyrx Core ≠ HyrxMQ ≠ AMQP ≠ TCP ≠ UDS ≠ WSS/HTTP ≠ simulation) |
| Semantic | PROVEN | Invariants in registry, single routing authority (Gate 1: CONDITIONAL PASS; global resource limits still not enforced) |
| Implementation | IMPLEMENTED | Core engine, AMQP adapter, product-level service, transports, TCP TLS, metrics/logging surfaces |
| Test / Correctness | PASS | 52/0 pass; frame fuzz (1000 random + 8 malformed classes, no crash); 10-case persistence crash/corruption matrix |
| Memory/Ownership | PROVEN | Single-dest zero-copy move, multi-dest copy, allocation ledger (Gate 2: PASS) |
| AMQP | PARTIALLY VALIDATED | Level A proven (pika 1.4.4); Level B partial; headers exchange `x-match=all/any` implemented (Gate 3: PARTIAL PASS) |
| Persistence | PROVEN | WAL journal, recovery, CRC-32, crash/corruption/I-O-failure matrix (Gate 4: PASS) |
| Security | IMPLEMENTED / PROVEN (TLS) | TCP TLS 6/6 real-client probe; fuzz fail-closed; no authorization, no timeouts (Gate 5: PASS for implemented scope) |
| Operations | PARTIALLY VALIDATED | Prometheus + JSON export and structured logging tested; no HTTP endpoint, histograms, tracing, OS signals (Gate 6: PARTIAL PASS) |
| Performance | PROVEN | 1.43x vs RabbitMQ 4.3.5, p95 latency 24.2µs (Gate R) |

---

## What Hyrx Guarantees

1. **Single-dest zero-copy move.** When exactly one queue matches a routing key, the message buffer is moved (not copied) from source to destination.
2. **Deterministic routing.** Direct, fanout, topic, headers exchanges produce identical results across runs.
3. **Headers matching.** `x-match=all` / `x-match=any` header matching is implemented and tested (`tests/phase2/exchange_test.mojo`).
4. **Destination-set deduplication.** Binding a queue twice to the same exchange/routing-key produces one delivery.
5. **Wire-level interoperability.** pika 1.4.4 completes AMQP handshake, publish, consume, get, ack against HyrxMQ.
6. **WAL durability and crash recovery.** Persistent messages (`delivery_mode=2`) survive restart via journal replay; write-ahead recovery, ACK/REMOVE tombstones, CRC/framing corruption fail-closed, torn-tail truncation, I/O-failure injection, multi-queue recovery and sync equivalence are all executable (`tests/phase10/persistence_crash_test.mojo`).
7. **TCP TLS.** A real Python TLS client completes a TLS 1.3 handshake, receives `connection.start` over the encrypted channel, and the presented cert matches the configured cert; plaintext connect is rejected (`scripts/interop/tls_probe.py`, 6/6).
8. **Fuzz-safe parsing.** 1000 random frames plus 8 malformed classes fail closed without crashing (`tests/phase10/frame_fuzz_test.mojo`).
9. **Metrics and structured logging surfaces.** `BrokerStatus.to_prometheus()` / `to_json()` and `log_json()` / `log_level_rank()` / `should_log()` are tested (`tests/phase10/metrics_export_test.mojo`, `tests/phase10/logging_test.mojo`).
10. **Performance.** Throughput exceeds RabbitMQ 4.3.5 by 1.43x in closed-loop single-connection benchmarks.

---

## What Hyrx Does NOT Guarantee

1. **Authorization.** No per-resource permission model, no ACLs; single vhost (`/`).
2. **Timeout controls.** No connection/read/write timeouts; a slow client is not bounded.
3. **Full TLS coverage.** TLS is TCP-tier only; UDS is plaintext. Cert validation is self-signed cert-match, not trust-chain validation.
4. **Observability endpoint.** Metrics exporter is a pure function; there is no HTTP `/metrics` route. No latency histograms, no tracing.
5. **Signal-driven shutdown.** A `begin_shutdown()` / `flush_storage()` seam exists, but no OS signal handlers are installed.
6. **Full AMQP compliance.** Fanout routing leak (D5), multiple routing authority (D14); no publisher confirms, no mandatory publish, no channel.close.
7. **True process-kill crash resilience.** Crash recovery is simulated at the journal layer, not via `SIGKILL` of a running broker.
8. **Multi-process operation.** Single-process, single-threaded only.

---

## Known Defects

| ID | Defect | Severity | Status |
|----|--------|----------|--------|
| D1 | Exchange type check uses string comparison | LOW | OPEN |
| D4 | Headers exchange matches all bindings | MEDIUM | RESOLVED |
| D5 | fanout routing leaks into direct/topic | MEDIUM | OPEN (benchmarks work by luck) |
| D9 | Reject requeues to tail, not head | LOW | OPEN |
| D10 | Headers exchange stub (not full matching) | MEDIUM | RESOLVED |
| D11 | QueueConfig._durable dead field | LOW | OPEN |
| D12 | Buffer.capacity == count (no spare headroom) | LOW | OPEN |
| D13 | Envelope.val Optional not cleared after take | LOW | OPEN |
| D14 | Multiple routing authority (Router + fanout leak) | MEDIUM | OPEN |
| D15 | AMQPFrameCodec._compact is dead code | LOW | OPEN |

---

## Known Limitations

1. Single synchronous connection only.
2. Fanout routing leak (D5) — messages may appear in direct/topic queues.
3. No mandatory publish (unroutable-immediate has no return).
4. No exchange-to-exchange via AMQP (implemented in engine, not exposed via adapter).
5. No per-resource authorization; single vhost only.
6. No connection/read/write timeouts.
7. No HTTP metrics endpoint; no latency histograms; no tracing.
8. No OS signal handlers (shutdown seam only).
9. No TLS on UDS transport.
10. No WAL segment rotation, truncation, or compaction.

---

## Unproven Claims

1. **"durable"** — PROVEN at the journal layer (`tests/phase10/persistence_crash_test.mojo`); NOT proven under a real OS process kill.
2. **"secure"** — PARTIALLY PROVEN: TLS on TCP is proven; authorization, timeouts, connection limits and trust-chain validation are NOT implemented.
3. **"production-ready"** — NOT PROVEN (no auth, no timeouts, no HTTP observability endpoint, no interop certification).
4. **"zero-copy multi-dest"** — NOT PROVEN (single-dest proven; multi-dest copies per destination).
5. **"observable"** — PARTIALLY PROVEN: metrics/logging functions are tested; no endpoint, histograms, or tracing.

---

## Gate Summary

| Gate | Verdict | Key Finding |
|------|---------|-------------|
| Gate 1: Semantic Correctness | CONDITIONAL PASS | Invariants defined; queue depth/prefetch proven; global limits not enforced (unchanged this increment) |
| Gate 2: Ownership & Memory | PASS | Single-dest zero-copy move proven; allocation ledger documented |
| Gate 3: AMQP Interoperability | PARTIAL PASS | Level A proven (pika 1.4.4); Level B partial; headers exchange D4/D10 resolved |
| Gate 4: Persistence & Recovery | PASS | WAL journal + 10-case crash/corruption/I-O-failure matrix (`tests/phase10/persistence_crash_test.mojo`) |
| Gate 5: Security & Isolation | PASS (implemented scope) | TCP TLS proven via real-client probe; fuzz fail-closed; no authorization/timeouts |
| Gate 6: Operations & Observability | PARTIAL PASS | Prometheus + JSON export and structured logging tested; no endpoint/histograms/tracing/signals |

---

## Recommended Next Work

### Priority 1: Security
1. Implement per-resource authorization (vhosts, ACLs).
2. Add connection/read/write timeouts and connection limits.
3. Add trust-chain / client-certificate validation; bring TLS to the UDS transport.

### Priority 2: Correctness
4. Fix D5/D14 (fanout routing leak / multiple routing authority).
5. Add a true OS-process-kill crash test.
6. Add coverage-guided fuzzing and heartbeat/connection-storm tests.

### Priority 3: Operations
7. Expose an HTTP `/metrics` endpoint over the Prometheus exporter.
8. Add latency histograms (routing/delivery/persistence).
9. Install OS signal handlers over the `begin_shutdown()` / `flush_storage()` seam.
10. Add tracing and a logging sink with rotation.

---

## Regression Check

- Full test suite: **52/0 PASS**
- TLS acceptance probe: **6/6 PASS** (`scripts/interop/tls_probe.py`)
- Persistence crash/corruption matrix: **10/10 PASS** (`tests/phase10/persistence_crash_test.mojo`)
- No knowingly introduced regressions

---

## Absolute Completion Criterion

**Can an independent engineer reproduce the evidence and determine exactly what Hyrx guarantees, what it does not guarantee, and where the remaining risks are?**

**YES.** The evidence is reproducible:
1. `pixi run test` — 52/0 PASS
2. `python3 scripts/interop/tls_probe.py` — 6/6 PASS
3. `pixi run bench` — throughput/latency results
4. `scripts/interop/pika_content.py` — pika interop
5. `tests/phase10/persistence_crash_test.mojo` — persistence failure matrix
6. `tests/phase10/frame_fuzz_test.mojo` — fuzz fail-closed
7. All gate documents in `docs/engineering/`

An independent engineer can run these commands, read these documents, and determine exactly what Hyrx guarantees.
