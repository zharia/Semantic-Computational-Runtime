# Invariant Audit — HyrxMQ v0.0.4

## Source files audited

| File | Lines | Role |
|------|-------|------|
| `src/hyrx/core/router.mojo` | 1188+ | Single routing authority |
| `src/hyrx/core/queue.mojo` | 572 | Bounded FIFO with delivery tracking |
| `src/hyrxmq/amqp_service.mojo` | 3282 | Frame dispatch, content reassembly, auth |
| `src/hyrxmq/listener.mojo` | 1200+ | Connection lifecycle, transport glue |

---

## R1 — Single Routing Authority

**Invariant:** One `Router` instance owns all exchanges, queues, and consumers. No other component routes messages.

**Enforced:** `router.mojo:53` — `struct Router` owns `_exchanges`, `_queues`, `_consumers`. `amqp_service.mojo:898-901` — `AMQPService` holds one `_broker: HyrxMQBroker` which wraps one `Router`. All publish/consume paths go through the broker.

**Tested:** `tests/phase2/router_test.mojo`, `tests/phase2/routing_matrix_test.mojo`

**Status:** HOLD

---

## R2 — Pool Outlives Queues (R6)

**Invariant:** `_pool: BufferPool` is declared FIRST in Router so Mojo's reverse-order field deinit tears it down AFTER `_queues`, preventing stranded pooled buffers.

**Enforced:** `router.mojo:56-61` — comment + field order. `_pool` at line 61, `_queues` at line 64.

**Tested:** `tests/phase2/pool_reclaim_test.mojo`

**Status:** HOLD

---

## R3 — Payload Isolation on Fan-Out

**Invariant:** Each fan-out destination receives an independently copied payload buffer. No payload bytes are shared between destination queues.

**Enforced:** `router.mojo:979-994` — per-destination copy via `_fill_destination` (line 983). `router.mojo:1002-1015` — `_fill_destination` acquires a fresh buffer or calls `payload_copy`.

**Tested:** `tests/phase2/router_test.mojo` (fan-out assertions)

**Status:** HOLD

---

## R4 — Exchange Chain Depth Cap

**Invariant:** Exchange→exchange chain hops are bounded to `_MAX_CHAIN_DEPTH() = 16`. Deeper chains are silently not further routed (fail closed).

**Enforced:** `router.mojo:38-39` — constant definition. `router.mojo:915` — `depth < _MAX_CHAIN_DEPTH()` gate in the BFS expansion loop.

**Tested:** `tests/phase2/routing_matrix_test.mojo` (E2E binding tests)

**Gap:** No test exercises the 16-hop boundary. A test with 17 chained exchanges would confirm the cap.

---

## R5 — Recovery Flag Suppresses Journal Writes

**Invariant:** During `recover()`, no journal write may fire (the `_recovering` flag gates every `_journalize_*` hook).

**Enforced:** `router.mojo:217` — `self._recovering = True` before replay. `router.mojo:147,170` — `_journalize_enqueue` and `_journalize_tombstone` check `self._recovering` and return early. `router.mojo:290` — flag reset after materialization.

**Tested:** `tests/phase8/storage_test.mojo` (recovery path)

**Status:** HOLD

---

## R6 — Capacity Enforcement

**Invariant:** `Queue.enqueue` returns `False` when `_total_count() >= _capacity`. `Queue.has_capacity` is the non-consuming preflight for the single-destination move path.

**Enforced:** `queue.mojo:143-158` — `enqueue` checks `_total_count() >= _config._capacity` (line 151). `queue.mojo:160-176` — `has_capacity` preflight. `queue.mojo:178-187` — `enqueue_prechecked` (used only after preflight).

**Tested:** `tests/phase2/queue_test.mojo` (capacity + backpressure), `tests/phase2/bounded_resource_test.mojo`

**Status:** HOLD

---

## R7 — x-max-Length Trim (Drop-Head)

**Invariant:** After every enqueue, if `_total_count() > _max_length`, oldest messages are dropped (outbox first, then inbox). With `overflow='reject-publish'`, `has_capacity` refuses BEFORE enqueue.

**Enforced:** `queue.mojo:249-269` — `_trim_to_max` runs after `enqueue`/`enqueue_prechecked`. `queue.mojo:172-175` — `has_capacity` returns `False` when `_overflow_reject` and over cap.

**Tested:** `tests/phase2/queue_test.mojo` (x-max-length trimming)

**Status:** HOLD

---

## R8 — TTL Evaluated at Delivery Only

**Invariant:** x-message-ttl expiry is checked in `dequeue()` only (no timer subsystem). Expired messages are moved to `_swept` for the Router to dead-letter or release.

**Enforced:** `queue.mojo:207-223` — `dequeue` with `_ttl_ms > 0` branch, `monotonic() - msg.enqueue_ns() >= ttl_ns`.

**Tested:** `tests/phase2/queue_test.mojo` (TTL path), `tests/phase7/amqp_service_test.mojo`

**Gap:** Timerless design is honest PARTIAL — no proactive expiry. Covered only by delivery-time evaluation.

---

## R9 — Content Reassembly Ceiling

**Invariant:** A single in-flight publish per connection is bounded by `MAX_PENDING_BODY() = 8 MiB`. The codec also refuses single frames over `frame_max`.

**Enforced:** `amqp_service.mojo:228-229` — `MAX_PENDING_BODY() = 8 * 1024 * 1024`. `amqp_service.mojo:2858-2871` — body size checked against both `_max_message_size` and `MAX_PENDING_BODY()`. `amqp_service.mojo:2907` — overflow check on each BODY frame.

**Tested:** `tests/phase7/content_reassembly_test.mojo`

**Status:** HOLD

---

## R10 — SASL PLAIN Auth Validation

**Invariant:** Every connection.start-ok is validated against the configured users table. Mismatch → 403 ACCESS_REFUSED connection.close BEFORE any further serving.

**Enforced:** `amqp_service.mojo:1481-1524` — mechanism check (`"PLAIN"` only), username/password match against `_users`. `amqp_service.mojo:1505-1524` — `_auth_failures` counter, reply-code 403.

**Tested:** `tests/phase7/connection_negotiation_test.mojo`, `tests/phase7/amqp_service_test.mojo`

**Status:** HOLD

---

## R11 — Connection Lifecycle Phases

**Invariant:** Every connection progresses HEADER → HANDSHAKING → READY. Business methods are served in READY; the handshake frames are consumed in HEADER/HANDSHAKING.

**Enforced:** `listener.mojo:82-94` — `PHASE_HEADER/HANDSHAKING/READY`. `listener.mojo:544-545` — header-phase guard. `listener.mojo:654-658` — open-ok detection moves to READY.

**Tested:** `tests/phase7/connection_negotiation_test.mojo`

**Status:** HOLD

---

## R12 — max_connections Enforcement at Accept

**Invariant:** When `_active >= _max_connections`, the accepted socket is closed immediately (fail closed). The refused count is incremented.

**Enforced:** `listener.mojo:354-369` — `register` checks `_active >= _max_connections`, closes, increments `_refused`, returns -1.

**Tested:** `tests/phase2/bounded_resource_test.mojo`

**Status:** HOLD

---

## R13 — Per-Channel Delivery-Tag Namespace

**Invariant:** Wire delivery tags are per-(connection, channel), monotonic, never reused. A redelivery gets a FRESH wire tag. `basic.ack/nack` resolve through `_ChanTagMap` to engine consumer+tag.

**Enforced:** `amqp_service.mojo:724-744` — `_ChanTagMap` struct. `amqp_service.mojo:1036-1063` — `_chan_alloc_tag`. `amqp_service.mojo:1065-1116` — `_chan_take` / `_chan_take_through`.

**Tested:** `tests/phase7/amqp_service_test.mojo` (tag mapping)

**Status:** HOLD

---

## R14 — Channel Close Drops In-Flight State

**Invariant:** On channel.close, the channel's delivery-tag namespace, confirm state, and tx staging all die. Half-reassembled publishes are dropped fail-closed.

**Enforced:** `amqp_service.mojo:1588-1602` — `CHANNEL_CLOSE` handler calls `_mark_channel_closed` + `_chan_drop`. `amqp_service.mojo:1118-1131` — `_chan_drop` removes maps, confirms, tx. `amqp_service.mojo:2563-2565` — pending publish cleared if on the closed channel.

**Tested:** `tests/phase7/protocol_completeness_t4_test.mojo`

**Status:** HOLD

---

## R15 — Exclusive Queue Ownership

**Invariant:** An exclusive queue is owned by the declaring connection. Other connections get 405 RESOURCE_LOCKED. Auto-deletes on owner close.

**Enforced:** `amqp_service.mojo:1799-1817` — ownership check in `queue.declare` (existing queue). `amqp_service.mojo:2705-2740` — `_queue_access_error` checks owner for consume/get. `amqp_service.mojo:2637-2653` — `_cleanup_connection` deletes exclusive queues.

**Tested:** `tests/phase7/amqp_service_test.mojo` (exclusive queue tests)

**Status:** HOLD

---

## R16 — ACL Permission Checks

**Invariant:** exchange.declare → configure; queue.declare → configure; basic.publish → write; basic.consume/basic.get → read.

**Enforced:**
- `amqp_service.mojo:1622-1629` — exchange.declare → configure check
- `amqp_service.mojo:1754-1761` — queue.declare → configure check
- `amqp_service.mojo:2012-2019` — basic.publish → write check
- `amqp_service.mojo:2086-2093` — basic.consume → read check
- `amqp_service.mojo:2133-2140` — basic.get → read check

**Tested:** No explicit ACL test found in the test suite. Auth tests cover SASL, not per-operation ACL.

**Gap:** ACL enforcement is code-verified but lacks a dedicated test.

---

## R17 — max_message_size Enforcement

**Invariant:** A declared body size exceeding `_max_message_size` is rejected (fail-closed, publish dropped).

**Enforced:** `amqp_service.mojo:2858-2864` — `_on_content_header` checks `size > self._max_message_size`.

**Tested:** `tests/phase7/content_reassembly_test.mojo` (size-bound tests)

**Status:** HOLD

---

## R18 — max_queues / max_exchanges Enforcement

**Invariant:** New queue/exchange declarations beyond the configured ceiling are refused with 406 PRECONDITION_FAILED "resource_limit".

**Enforced:**
- `amqp_service.mojo:1670-1679` — max_exchanges check in exchange.declare
- `amqp_service.mojo:1882-1891` — max_queues check in queue.declare

**Tested:** No dedicated test found for resource limits.

**Gap:** Resource limit enforcement is code-verified but lacks explicit test coverage.

---

## Summary

| # | Invariant | Status | Tested | Gap |
|---|-----------|--------|--------|-----|
| R1 | Single routing authority | HOLD | ✅ | — |
| R2 | Pool outlives queues | HOLD | ✅ | — |
| R3 | Payload isolation fan-out | HOLD | ✅ | — |
| R4 | Chain depth cap (16) | HOLD | ⚠️ | No boundary test |
| R5 | Recovery flag suppresses writes | HOLD | ✅ | — |
| R6 | Capacity enforcement | HOLD | ✅ | — |
| R7 | x-max-length trim | HOLD | ✅ | — |
| R8 | TTL at delivery only | HOLD | ✅ | Honest PARTIAL |
| R9 | Content reassembly ceiling | HOLD | ✅ | — |
| R10 | SASL PLAIN auth | HOLD | ✅ | — |
| R11 | Connection lifecycle phases | HOLD | ✅ | — |
| R12 | max_connections accept gate | HOLD | ✅ | — |
| R13 | Per-channel tag namespace | HOLD | ✅ | — |
| R14 | Channel close drops state | HOLD | ✅ | — |
| R15 | Exclusive queue ownership | HOLD | ✅ | — |
| R16 | ACL permission checks | CODE-VERIFIED | ❌ | No dedicated test |
| R17 | max_message_size | HOLD | ✅ | — |
| R18 | max_queues/max_exchanges | CODE-VERIFIED | ❌ | No dedicated test |

**16/18 invariants fully enforced and tested. 2 invariants enforced in code but lack test coverage (R16, R18). 1 invariant has a boundary gap (R4).**
