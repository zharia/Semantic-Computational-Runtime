# M1: Semantic Correctness & Resource Governance

**Gate:** A (Correctness) + B (Resource Safety)
**Status:** PARTIAL — limits declared and most enforced; memory admission and
per-connection `max_unacked` delivery wiring are config-only (see notes).
**Spec:** Sections 7-19

## Sprint 1.1 — Baseline Verification ✅
- [x] Commit `034a9c0` recorded
- [x] 54/54 tests pass at baseline (1 expected self-test)
- [x] Stress benchmark suite built
- [x] WASM module built (17KB, 23 exports)
- [x] Docker packaging verified

## Sprint 1.2 — Resource Limits Enforcement ✅
**Status:** DONE — keys in `src/hyrxmq/config.mojo`; enforced in
`amqp_service.mojo` / `listener.mojo`.

### 1.2.1 Max Message Size Validation ✅
**File:** `src/hyrxmq/amqp_service.mojo`
- [x] Add `max_message_size` to `HyrxMQConfig`
- [x] Validate in `handle_basic_publish` BEFORE accumulating body frames
- [x] Reject with `PRECONDITION_FAILED` (406) if body_size exceeds limit
- [x] Default: 128 MiB (RabbitMQ default)
- Enforced at content-header stage (`amqp_service.mojo:2858`); invariant R17.

### 1.2.2 Max Connections Enforcement ✅
**File:** `src/hyrxmq/listener.mojo`
- [x] Track active connection count in `AMQPService`
- [x] Reject new connections with `connection.close` 501 (TOO_MANY_CONNECTIONS) when at limit
- [x] Config: `max_connections` (enforced at accept, fails closed)
- Enforced at `register` (`listener.mojo:354`); invariant R12.

### 1.2.3 Connection Idle Timeout ✅
**File:** `src/hyrxmq/listener.mojo`
- [x] Track last activity timestamp per connection
- [x] Close connections idle beyond `idle_timeout_secs` (config key, default 300)
- [x] Heartbeat frames count as activity

### 1.2.4 Queue/Exchange/Consumer/Channel Bounds
**File:** `src/hyrxmq/amqp_service.mojo`
- [x] Add config keys: `max_queues`, `max_exchanges`, `max_channels_per_connection`
- [x] `max_queues` enforced at declare time (`amqp_service.mojo:1882`); R18
- [x] `max_exchanges` enforced at declare time (`amqp_service.mojo:1670`); R18
- [ ] `max_channels_per_connection` enforced — **NOT DONE**: key exists and
  validates, but no per-connection channel-count ceiling is enforced yet.

## Sprint 1.3 — Backpressure & Admission Control
**Status:** PARTIAL — config contract only.

### 1.3.1 Memory Admission Control
**File:** `src/hyrx/core/router.mojo`
- [x] Config: `max_memory_bytes` (default 512 MiB), declared + validated
- [ ] Track total bytes enqueued across all queues — **NOT DONE**
- [ ] Reject publishes when `memory_high_watermark` exceeded — **NOT DONE**:
  `max_memory_bytes` is a config field only; no admission gate reads it.

### 1.3.2 Bounded Unacked Delivery
- [x] Already bounded by prefetch; verified (`tests/phase2`)
- [x] Add `max_unacked` config (default 1000), declared + validated
- [ ] Per-connection `max_unacked` delivery-path enforcement — **NOT DONE**:
  `amqp_service.mojo:1043` stores `_max_unacked` but never reads it; delivery
  wiring deliberately deferred (`tests/phase10/backpressure_test.mojo`).

## Sprint 1.4 — Correctness Test Matrix ✅
**Dir:** `tests/phase10/` — consolidated into one in-process matrix,
`correctness_matrix_test.mojo` (the four original `tests/phase1/` files were
folded into it).
- [x] routing matrix (all exchange types × edge cases) ✓
- [x] ownership lifecycle through all operations ✓
- [x] delivery tag correctness across ack/nack/reject ✓
- [x] queue semantics (capacity, TTL, DLX, purge, max-length) ✓

## Exit Criteria
- [x] All existing tests pass (68/69; 1 expected self-test)
- [x] New resource-limit tests pass (`correctness_matrix_test.mojo`, `backpressure_test.mojo`)
- [x] Max message size enforced
- [x] Max connections enforced
- [x] Queue/exchange bounds enforced
- [ ] Channel bound, memory admission and `max_unacked` delivery enforcement (config-only)