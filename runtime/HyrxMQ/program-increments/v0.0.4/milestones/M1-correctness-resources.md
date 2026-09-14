# M1: Semantic Correctness & Resource Governance

**Gate:** A (Correctness) + B (Resource Safety)
**Spec:** Sections 7-19

## Sprint 1.1 — Baseline Verification ✅
- [x] Commit `034a9c0` recorded
- [x] 54/54 tests pass (1 expected self-test)
- [x] Stress benchmark suite built
- [x] WASM module built (17KB, 23 exports)
- [x] Docker packaging verified

## Sprint 1.2 — Resource Limits Enforcement

### 1.2.1 Max Message Size Validation
**File:** `src/hyrxmq/amqp_service.mojo`
- Add `max_message_size` to `HyrxMQConfig`
- Validate in `handle_basic_publish` BEFORE accumulating body frames
- Reject with `PRECONDITION_FAILED` (406) if body_size exceeds limit
- Default: 128 MiB (RabbitMQ default)

### 1.2.2 Max Connections Enforcement
**File:** `src/hyrxmq/listener.mojo`
- Track active connection count in `AMQPService`
- Reject new connections with `connection.close` 501 (TOO_MANY_CONNECTIONS) when at limit
- Config: `max_connections` (already exists, enforce it)

### 1.2.3 Connection Idle Timeout
**File:** `src/hyrxmq/listener.mojo`
- Track last activity timestamp per connection
- Close connections idle beyond `idle_timeout_secs` (config key, default 300)
- Heartbeat frames count as activity

### 1.2.4 Queue/Exchange/Consumer/Channel Bounds
**File:** `src/hyrxmq/amqp_service.mojo`
- Add config keys: `max_queues`, `max_exchanges`, `max_channels_per_connection`
- Enforce at declare time with appropriate error codes

## Sprint 1.3 — Backpressure & Admission Control

### 1.3.1 Memory Admission Control
**File:** `src/hyrx/core/router.mojo`
- Track total bytes enqueued across all queues
- Reject publishes when `memory_high_watermark` exceeded
- Config: `max_memory_bytes` (default: 512 MiB)

### 1.3.2 Bounded Unacked Delivery
- Already bounded by prefetch; verify enforcement
- Add `max_unacked_per_connection` config

## Sprint 1.4 — Correctness Test Matrix
**Dir:** `tests/phase1/`
- [x] `buffer_test.mojo` ✓
- [x] `message_test.mojo` ✓
- [x] `buffer_pool_test.mojo` ✓
- [ ] `routing_authority_test.mojo` — verify single routing path
- [ ] `ownership_lifecycle_test.mojo` — message ownership through all operations
- [ ] `delivery_tag_test.mojo` — tag correctness across ack/nack/reject
- [ ] `queue_semantics_test.mojo` — capacity, TTL, DLX, purge, max-length

## Exit Criteria
- [ ] All 54 existing tests pass
- [ ] New resource-limit tests pass
- [ ] Max message size enforced
- [ ] Max connections enforced
- [ ] Queue/exchange bounds enforced
