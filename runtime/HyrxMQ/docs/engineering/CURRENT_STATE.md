# CURRENT_STATE.md — v0.0.3

**Date:** 2026-09-11
**Commit:** 4ec2a0650807777d61a02b3a0242ccd2cc9b9eb0
**Toolchain:** Mojo >=1.0.0,<2 (pixi env, conda-forge + Modular channels)
**Test suite:** 52/0 PASS (phase0-phase10 + integration)
**External proofs:** pika 1.4.4 interop; `scripts/interop/tls_probe.py` 6/6 PASS
**Repository:** semantic_computational_runtime/runtime/HyrxMQ

---

## 1. Architecture summary

The codebase implements a layered messaging engine with explicit architectural separation:

| Layer | Description | Status |
|-------|-------------|--------|
| Hyrx Core | Message/envelope model, routing, queues, consumers, delivery, ack | IMPLEMENTED |
| Hyrx Embedded | In-process API (HyrxEngine) | IMPLEMENTED |
| Hyrx Transport | TCP (+ optional TLS), UDS, WSS, HTTP admin, flow control, framing | IMPLEMENTED |
| HyrxMQ AMQP | AMQP 0-9-1 adapter, frame codec, connection state, field tables | IMPLEMENTED |
| HyrxMQ Product | Broker, config, listener, service, status, logging | IMPLEMENTED |
| Persistence | Write-ahead journal (disabled/memory/file tiers), recovery | PROVEN (crash/corruption tested) |

---

## 2. Source tree inventory

### 2.1 Hyrx Core (`src/hyrx/core/`)

| File | Lines | Purpose | Status |
|------|-------|---------|--------|
| `message.mojo` | 236 | Message, Envelope, MessageID, ContentProps | PROVEN (tested) |
| `buffer.mojo` | 189 | Buffer with ownership, copy, snapshot, pool tagging | PROVEN (tested) |
| `buffer_snapshot.mojo` | ~60 | Owned byte snapshot (renamed from BufferView) | PROVEN (tested) |
| `buffer_pool.mojo` | 131 | Size-classed buffer reuse pool | IMPLEMENTED (off by default, no perf win) |
| `queue.mojo` | 572 | Bounded FIFO with delivery tracking, ack/reject, TTL, x-max-length, DLX | PROVEN (tested) |
| `exchange.mojo` | ~360 | Direct/fanout/topic/headers exchange matching (headers x-match=all/any), E2E bindings | PROVEN (tested) |
| `router.mojo` | ~1300 | Central routing engine, fan-out, journal, recovery | PROVEN (tested) |
| `consumer.mojo` | 61 | Consumer registration, prefetch tracking | PROVEN (tested) |
| `storage.mojo` | 1518 | WAL journal, CRC-32 framing, MemoryStorage, FileStorage, RecoveryBuilder | PROVEN (tested) |
| `feature_flags.mojo` | ~30 | `contiguous_batch_enabled()` flag | IMPLEMENTED |
| `pool_stats.mojo` | ~20 | Pool allocation statistics | IMPLEMENTED |

### 2.2 Hyrx Embedded (`src/hyrx/embedded/`)

| File | Purpose | Status |
|------|---------|--------|
| `api.mojo` | HyrxEngine — single routing authority, owns Router | PROVEN (tested) |

### 2.3 Hyrx Transport (`src/hyrx/transport/`)

| File | Purpose | Status |
|------|---------|--------|
| `tcp.mojo` | TCP transport (vendored flare), optional OpenSSL TLS wrapping | PROVEN (tested + external probe) |
| `uds.mojo` | Unix domain sockets, abstract namespace | PROVEN (tested) |
| `wss.mojo` | WebSocket Secure transport | IMPLEMENTED (tested) |
| `http_admin.mojo` | HTTP admin endpoint | IMPLEMENTED |
| `flow_control.mojo` | Backpressure/flow control | IMPLEMENTED |
| `framing.mojo` | Transport framing | IMPLEMENTED |
| `poll.mojo` | Event polling | IMPLEMENTED |
| `transport.mojo` | Transport abstraction | IMPLEMENTED |

### 2.4 HyrxMQ AMQP (`src/hyrx/amqp/`)

| File | Purpose | Status |
|------|---------|--------|
| `adapter.mojo` | AMQP-to-Hyrx translation layer | PROVEN (tested) |
| `frame_codec.mojo` | AMQP 0-9-1 frame codec with cursor-based parsing | PROVEN (tested) |
| `connection_state.mojo` | AMQP connection state machine | PROVEN (tested) |
| `field_table.mojo` | AMQP field table encoding/decoding | PROVEN (tested) |
| `constants.mojo` | AMQP protocol constants | PROVEN (tested) |

### 2.5 HyrxMQ Product (`src/hyrxmq/`)

| File | Purpose | Status |
|------|---------|--------|
| `broker.mojo` | Broker orchestration | PROVEN (tested) |
| `amqp_service.mojo` | AMQP service (full protocol handler) | PROVEN (tested) |
| `config.mojo` | Configuration parsing | PROVEN (tested) |
| `listener.mojo` | Network listener | PROVEN (tested) |
| `main_listen.mojo` | Main listen entry point | IMPLEMENTED |
| `main.mojo` | Main entry point | IMPLEMENTED |
| `status.mojo` | Health status + Prometheus/JSON metrics export | PROVEN (tested) |
| `logging.mojo` | Structured JSON logging (log_json, level ranking) | PROVEN (tested) |

---

## 3. Test inventory

### 3.1 By phase

| Phase | Files | Area | Status |
|-------|-------|------|--------|
| phase0 | 1 | Bootstrap | ALL PASS |
| phase1 | 3 | Buffer, BufferPool, Message | ALL PASS |
| phase2 | 7 | Queue, Exchange, Router, Consumer, Routing Matrix, Bounded Resources, Pool Reclaim | ALL PASS |
| phase3 | 2 | Embedded API, Latency Histogram | ALL PASS |
| phase4 | 2 | Transport, UDS | ALL PASS |
| phase5 | 3 | Flow Control, Framing, TCP | ALL PASS |
| phase6 | 6 | Adapter, AMQP Constants, Connection State, Field Table, Frame Codec (2) | ALL PASS |
| phase7 | 9 | AMQP Service, Broker, Config (2), Connection Negotiation, Content Reassembly, Main Smoke, Protocol Completeness, Status Health | ALL PASS |
| phase8 | 5 | Append Body Frame Identity, Byte Path, Codec Compaction, Storage, Transport Byte Path | ALL PASS |
| phase9 | 1 | WSS | ALL PASS |
| phase10 | 5 | TCP TLS (config + plaintext), Frame Fuzz, Metrics Export, Logging, Persistence Crash | ALL PASS |
| integration | 8 | AMQP-over-TCP, Broker TCP E2E, Broker UDS E2E, Flare Smoke, Listener Hostile, Socket Behavior, Socket Negative, UDS Abstract | ALL PASS |

### 3.2 Test gaps (areas with no dedicated tests)

| Area | Gap |
|------|-----|
| `tests/unit/` | Empty — no unit test directory populated |
| `tests/protocol/` | Empty |
| `tests/interop/` | Empty — external interop scripts live in `scripts/interop/` (pika, TLS probe) |
| `tests/performance/` | Empty — benchmarks exist in `benchmarks/` but not in test suite |
| `tests/fuzz/` | Empty; systematic fuzz now in `tests/phase10/frame_fuzz_test.mojo` |
| Headers exchange matching | **RESOLVED** — x-match=all/any implemented + tested |
| Publisher confirms | IMPLEMENTED (confirm.select) but not covered by a phase10 test |
| QoS/prefetch multi-consumer fairness | Not tested (single shared cursor) |
| TLS on TCP | PROVEN via external `scripts/interop/tls_probe.py` |
| TLS on UDS | NOT IMPLEMENTED |
| Authorization (ACLs/vhosts) | NOT IMPLEMENTED |
| Connection/I/O timeouts | NOT IMPLEMENTED |
| Hostile input (fuzz) | phase10 frame fuzz added (1000 random + 8 classes) |
| x-message-ttl | Implemented in queue; tested in routing_matrix |
| x-max-length | Implemented in queue; tested in bounded_resource |
| Dead-letter exchange | Implemented; tested in routing_matrix |
| exchange-to-exchange | Implemented; tested in routing_matrix |

---

## 4. Documented defects (from MEMORY_MODEL.md audit)

| ID | Description | Status |
|----|-------------|--------|
| D1 | Fan-out discarded message_id/headers | FIXED (increment 0004) |
| D2 | Double payload copy per destination | FIXED (increment 0004) |
| D3 | enqueue at capacity destroys caller's message | OPEN (design gap) |
| D4 | Unroutable publishes destroyed silently, no basic.return | FIXED — mandatory basic.return implemented (amqp_service `_execute_publish`) |
| D5 | read_payload with unknown tag returns empty snapshot | OPEN (design gap) |
| D6 | Inconsistent error model (raise vs None/False) | OPEN |
| D7 | delete_queue docstring promises unacked list but returns empty | OPEN |
| D8 | unregister_consumer strands unacked messages | FIXED (requeue) |
| D9 | reject requeues to TAIL (not head like RabbitMQ) | OPEN (needs decision) |
| D10 | Headers exchange stub matches all | **FIXED (v0.0.3)** — x-match=all/any |
| D11 | QueueConfig._durable dead field | NOT A DEFECT — used in Router journal gating |
| D12 | BufferPool not wired into message path | FIXED (wired, tested, measured, disabled by default) |

---

## 5. Maturity assessment

| Dimension | Rating | Evidence |
|-----------|--------|----------|
| Architecture | IMPLEMENTED | Layered separation exists and is tested; E2E path works |
| Semantic invariants | PROVEN | Documented in SEMANTIC_INVARIANTS.md (25 invariants) + registry |
| Message identity | PROVEN | message_id, routing_key, headers preserved through fan-out (routing_matrix_test) |
| Delivery identity | PROVEN | Delivery tag is unique per dequeue; ack/reject operate on specific tags |
| Routing | PROVEN | Direct/fanout/topic/headers/E2E deterministic; destination-set dedup proven |
| Queue semantics | PROVEN | FIFO, capacity enforcement, TTL, x-max-length, DLX all tested |
| Consumer lifecycle | PROVEN | Register/unregister, prefetch, requeue-on-disconnect tested |
| Resource boundedness | PARTIALLY VALIDATED | Queue depth + prefetch enforced; message size, unacked total, consumers, queues: NOT enforced |
| Ownership/copy model | PROVEN | Documented in MEMORY_MODEL.md; single-dest zero-copy move proven |
| AMQP wire compatibility | PARTIALLY VALIDATED | Level A proven via pika 1.4.4; Level B partial |
| Persistence | PROVEN | WAL journal, recovery, CRC-32; crash/corruption/multi-queue/IO-failure tests pass |
| Security | IMPLEMENTED | TLS 1.3 proven (external probe); SASL PLAIN; fuzz tests; no ACLs/timeouts |
| Operations | PARTIALLY VALIDATED | Prometheus/JSON metrics, structured logging, shutdown seam; no HTTP endpoint/histograms |
| Performance | PROVEN | Benchmark suite exists; 1.43x vs RabbitMQ at gate R |

---

## 6. Key architectural properties

### Ownership model (from MEMORY_MODEL.md audit)
- Message owns Envelope + Buffer (value semantics, move on transfer)
- Fan-out: independent owned copies per destination (no shared payload)
- Single-dest path: zero-copy move of source Message
- BufferSnapshot: owned copy (not a view despite earlier naming)
- BufferPool: wired into Router, origin-tagged, disabled by default
- Acknowledge: destroys message, reclaims payload to pool
- Reject: requeues to tail (D9), no re-copy

### Storage model
- Pluggable: disabled (default), memory WAL, file WAL
- Journal framing: u32 length + u16 type + body + u32 CRC-32
- Record types: DECLARE_QUEUE, DECLARE_EXCHANGE, BIND, DELETE_QUEUE, PURGE, MSG, ACK, REDELIVER, REMOVE, DELETE_EXCHANGE
- Recovery: ordered replay, tombstone resolution, materialization into Router
- FileSystemOps trait: single filesystem seam, redirectable

### Transport
- TCP via vendored flare (no extra deps on Linux)
- Optional OpenSSL TLS on TCP (config + env driven; proven via external probe)
- UDS including abstract namespace (`@name` paths)
- WSS (WebSocket Secure)
- HTTP admin endpoint

---

## 7. What is NOT implemented

- Authorization / vhost ACLs / per-resource permissions
- Connection / read / write timeouts
- Connection count limits beyond single synchronous serving
- HTTP `/metrics` endpoint (formatter exists; no HTTP server wired)
- Latency histograms, tracing
- TLS on UDS transport
- Async push-after-subscribe delivery (deliveries ride the consume reply)
- Server cyclic heartbeats + 2x-missed close (ping-pong reply only)
- channel.flow
- Unacked message limit enforcement
- Message size limit enforcement
- Consumer/queue/exchange count limits
- Systemd hardening (documented, not tested)
- Distributed clustering
- WAL compaction / segment rotation

---

## 8. Performance baseline

From benchmark suite (documented in MEMORY_MODEL.md):
- Gate R (Hyrx/RabbitMQ ratio): 1.430 (CI 1.4205–1.435)
- Every Hyrx cell/size ≥ parity vs RabbitMQ (min 1.13x docker@65K)
- 128 KB TCP: 1.21x vs RabbitMQ
- Native closed-loop floor: 17.25 µs/msg @ 64B
- BufferPool: NO throughput win (0.79–1.00x vs direct), disabled by default

---

## 9. Claims vs evidence

| Claim | Status |
|-------|--------|
| "AMQP 0-9-1 frame codec" | PROVEN — byte-exact at all sizes including multi-frame |
| "routing is deterministic" | PROVEN — routing_matrix_test covers all combinations |
| "fan-out preserves identity" | PROVEN — metadata_fidelity tests |
| "bounded queue capacity" | PROVEN — bounded_resource_test |
| "crash-consistent WAL" | PROVEN — crash/corruption/multi-queue/IO-failure tests (phase10) |
| "zero-copy single-dest" | PROVEN — single-eligible-queue move path |
| "pool reuse" | IMPLEMENTED — wired, tested, no perf win |
| "TLS" | PROVEN — TLS 1.3 handshake + AMQP-over-TLS (external probe) |
| "production-ready" | NOT PROVEN — no ACLs, no timeouts, no HTTP metrics |
| "AMQP compatible" | PARTIALLY VALIDATED — Level A proven via pika 1.4.4, Level B partial |
| "durable" | PROVEN — journal + recovery + crash/corruption validation |
