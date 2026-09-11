# Semantic Invariants — Hyrx Core

**Version:** 1.0.0
**Date:** 2026-09-11
**Status:** SPECIFIED + PARTIALLY PROVEN

---

## Governing principle

Every invariant below is either:
- **PROVEN** — reproducible executable evidence exists
- **TESTED** — test exists and passes, broader proof may be required
- **IMPLEMENTED** — code exists, basic validation passed
- **SPECIFIED ONLY** — documented here, no implementation evidence
- **NOT PROVEN** — claim may exist but evidence is insufficient

---

## 1. Message identity (M-series)

### M1: A message has a canonical identity

**Statement:** Every message carries a `MessageID` (opaque UInt64) assigned at creation.

**Implementation:** `src/hyrx/core/message.mojo:45-57` — `MessageID` struct with `to_uint64()` and equality.

**Tests:** `tests/phase1/message_test.mojo`

**Status:** PROVEN

---

### M2: Routing does not change message identity

**Statement:** When a message is routed through an exchange, the `MessageID` in each per-destination envelope matches the source message's identifier.

**Implementation:** `src/hyrx/core/router.mojo:954-955` — `msg.message_id()` copied into each destination envelope.

**Tests:** `tests/phase2/routing_matrix_test.mojo::test_metadata_fidelity_preserved_on_fanout`

**Status:** PROVEN

---

### M3: Fan-out does not silently mutate message identity

**Statement:** When one message fans out to N destinations, each destination's envelope carries the original `MessageID`. No destination receives a zeroed or generated ID.

**Implementation:** Router.publish builds `Envelope(msg.message_id(), ...)` per destination (router.mojo:954-955). Single-dest move path preserves the original Message unchanged.

**Tests:** `tests/phase2/routing_matrix_test.mojo::test_metadata_fidelity_preserved_on_fanout`, `test_metadata_fidelity_single_destination_move`

**Status:** PROVEN

---

### M4: Payload identity is preserved through routing

**Statement:** The payload bytes delivered to a consumer are byte-identical to the bytes published, modulo the deliberate copy per destination.

**Implementation:** `Buffer.from_buffer_copy` (buffer.mojo:82-101) performs exact-length copy. `unsafe_memcpy` path when batch flag is ON.

**Tests:** `tests/phase2/routing_matrix_test.mojo`, `tests/phase8/byte_path_test.mojo`

**Status:** PROVEN

---

### M5: Message metadata survives routing and delivery

**Statement:** routing_key and headers are preserved in every per-destination envelope through fan-out.

**Implementation:** Router.publish copies `msg.routing_key()` and `msg.headers()` into each destination Envelope (router.mojo:954-955). Queue exposes `read_routing_key`/`read_headers` read-back.

**Tests:** `tests/phase2/routing_matrix_test.mojo::test_metadata_fidelity_preserved_on_fanout`, `test_metadata_fidelity_single_destination_move`

**Status:** PROVEN

---

## 2. Envelope and delivery identity (D-series)

### D1: A delivery is distinguishable from the underlying message

**Statement:** A `Delivery` is a lightweight claim token (UInt64 tag) that references, but does not contain, the message.

**Implementation:** `src/hyrx/core/queue.mojo:85-98` — Delivery carries only `_delivery_tag`. Message remains owned by Queue.

**Tests:** `tests/phase2/queue_test.mojo`, `tests/phase2/consumer_test.mojo`

**Status:** PROVEN

---

### D2: Every delivery has a defined lifecycle

**Statement:** A delivery progresses through: enqueue → dequeue (tag assigned) → consume (tag returned) → read_payload → acknowledge OR reject. State transitions are explicit.

**Implementation:** Queue tracks messages in `_inbox` → `_outbox` → `_unacked[tag]`. Acknowledge removes from `_unacked`; reject moves back to `_inbox`.

**Tests:** `tests/phase2/queue_test.mojo`, `tests/phase2/consumer_test.mojo`, `tests/phase2/routing_matrix_test.mojo`

**Status:** PROVEN

---

### D3: Acknowledgement refers to a specific delivery

**Statement:** `acknowledge(consumer_id, delivery_tag)` operates on exactly one delivery identified by its tag.

**Implementation:** `Queue.acknowledge(delivery_tag)` (queue.mojo:343-349) pops one entry from `_unacked[delivery_tag]`.

**Tests:** `tests/phase2/queue_test.mojo`, `tests/phase2/consumer_test.mojo`

**Status:** PROVEN

---

### D4: Duplicate acknowledgement has deterministic semantics

**Statement:** Acknowledging an already-acknowledged or unknown delivery_tag returns False and has no side effect.

**Implementation:** `Queue.acknowledge` returns False for unknown tags (queue.mojo:348-349). Router.acknowledge returns False (router.mojo:1094-1095).

**Tests:** `tests/phase2/queue_test.mojo`

**Status:** PROVEN

---

### D5: Delivery cancellation/rejection has defined semantics

**Statement:** `reject(delivery_tag)` requeues the message to the tail of the inbox, preserving its payload and incrementing delivery_count on next dequeue.

**Implementation:** Queue.reject (queue.mojo:368-375) moves message from `_unacked` to `_inbox`. Queue.dequeue increments `delivery_count`.

**Tests:** `tests/phase2/queue_test.mojo`, `tests/phase2/routing_matrix_test.mojo`

**Status:** PROVEN (note: requeue-to-tail differs from RabbitMQ requeue-to-head — see D9)

---

## 3. Routing (R-series)

### R1: Routing is deterministic for a fixed topology and input

**Statement:** Given the same exchange bindings and routing key, `Exchange.match()` returns the same destination set every time.

**Implementation:** `Exchange.match` (exchange.mojo:264-301) is a pure function of bindings and routing key. No randomness, no time dependence.

**Tests:** `tests/phase2/routing_matrix_test.mojo` — all routing scenarios

**Status:** PROVEN

---

### R2: Routing does not silently lose metadata

**Statement:** Routing preserves message_id, routing_key, and headers in every per-destination envelope.

**Implementation:** Same as M2/M3/M5. Router.publish copies all envelope fields.

**Tests:** `tests/phase2/routing_matrix_test.mojo::test_metadata_fidelity_*`

**Status:** PROVEN

---

### R3: Routing does not introduce unintended duplication

**Statement:** A queue bound by multiple matching bindings receives exactly one copy per publish (destination-set semantics).

**Implementation:** `_already_present` check in `Exchange.match` (exchange.mojo:121-126) deduplicates. `_router_dedup_append` in Router (router.mojo:42-50) further guards.

**Tests:** `tests/phase2/routing_matrix_test.mojo::test_multiple_matching_bindings_same_queue_one_copy`, `test_direct_same_queue_multiple_keys`

**Status:** PROVEN

---

### R4: Binding changes have defined visibility semantics

**Statement:** Binding/unbinding takes effect immediately for subsequent publishes. In-flight routing is not affected.

**Implementation:** Exchange.add_binding / remove_binding mutate the binding list synchronously. Router is single-threaded.

**Tests:** `tests/phase2/routing_matrix_test.mojo::test_unbind_removes_destination`

**Status:** PROVEN

---

### R5: Topology mutation cannot corrupt in-flight routing

**Statement:** Since Router is single-threaded, topology mutations (declare/delete/bind/unbind) cannot interleave with publish/consume.

**Implementation:** Single-threaded event loop. No concurrent access to Router state.

**Tests:** Implicitly proven by single-threaded architecture. No multi-threaded corruption tests exist.

**Status:** IMPLEMENTED (architecturally guaranteed, not explicitly tested with concurrent mutation)

---

### R6: Headers exchange matching follows explicit x-match semantics

**Statement:** A headers exchange delivers a message to a bound queue only when the
binding's header arguments match the message headers. `x-match="all"` (default)
requires every binding header to equal the message header; `x-match="any"`
requires at least one. A missing message header never matches.

**Implementation:** `_headers_match` in `src/hyrx/core/exchange.mojo`; binding
arguments carried as `HeaderArgs` (keys/values); Router passes `msg.headers()` to
`Exchange.match`.

**Tests:** `tests/phase2/exchange_test.mojo` (x-match=all, x-match=any, partial
match, no match, default, extra headers).

**Status:** PROVEN (v0.0.3; D10 resolved)

---

## 4. Queue semantics (Q-series)

### Q1: Queue state transitions are deterministic

**Statement:** Given the same sequence of enqueue/dequeue/ack/reject operations, a Queue reaches the same state every time.

**Implementation:** Queue is a deterministic state machine: `_inbox`, `_outbox`, `_unacked`, `_next_delivery_tag`.

**Tests:** `tests/phase2/queue_test.mojo`

**Status:** PROVEN

---

### Q2: Enqueue/dequeue semantics are explicit

**Statement:** `enqueue` moves a message into `_inbox`. `dequeue` transfers from `_outbox` to `_unacked`, returning a Delivery token. When `_outbox` is empty, `_inbox` is reversed into `_outbox` (two-stack FIFO).

**Implementation:** Queue.enqueue (queue.mojo:143-158), Queue.dequeue (queue.mojo:196-234).

**Tests:** `tests/phase2/queue_test.mojo`

**Status:** PROVEN

---

### Q3: Queue limits are enforced

**Statement:** `QueueConfig._capacity` bounds total messages (inbox + outbox + unacked). `QueueConfig._max_length` enforces x-max-length with drop-head trimming.

**Implementation:** Queue.enqueue checks `_total_count() >= _config._capacity` (queue.mojo:151). `_trim_to_max` enforces x-max-length (queue.mojo:249-269).

**Tests:** `tests/phase2/bounded_resource_test.mojo`

**Status:** PROVEN for queue depth and x-max-length. NOT ENFORCED for message size, unacked total, consumer count, queue count, exchange count (see resource boundedness section).

---

### Q4: Queue exhaustion has defined behaviour

**Statement:** When a queue is at capacity, `enqueue` returns False and the message is NOT enqueued. The caller (Router) destroys the message copy.

**Implementation:** Queue.enqueue returns False at capacity (queue.mojo:151-152). Router.publish destroys the copy (router.mojo:952-953, 976-977).

**Tests:** `tests/phase2/bounded_resource_test.mojo`

**Status:** PROVEN

---

### Q5: Consumer lifecycle cannot corrupt queue state

**Statement:** Registering or unregistering a consumer does not modify queue contents. Unregistering requeues unacked messages.

**Implementation:** Router.register_consumer / unregister_consumer modify `_consumers` and `_queue_consumers` indexes only. unregister_consumer calls `Queue.requeue_unacked()` (queue.mojo:542-558).

**Tests:** `tests/phase2/consumer_test.mojo`, `tests/phase2/bounded_resource_test.mojo::test_unregister_leaves_unacked_message_owned_by_queue`

**Status:** PROVEN

---

## 5. Consumer/delivery semantics (C-series)

### C1: Consumers have explicit lifecycle states

**Statement:** A consumer transitions through: register → active (can_deliver) → at prefetch limit → unregister. State is tracked by `_active_deliveries` count.

**Implementation:** Consumer struct (consumer.mojo:10-61) with `record_delivery()`, `record_ack()`, `can_deliver()`.

**Tests:** `tests/phase2/consumer_test.mojo`

**Status:** PROVEN

---

### C2: Delivery ownership is explicit

**Statement:** On `dequeue`, the message moves from Queue's outbox to its `_unacked` map, keyed by delivery_tag. The consumer receives only a Delivery token (tag).

**Implementation:** Queue.dequeue (queue.mojo:228-234) moves message to `_unacked[tag]`, returns `Delivery(tag)`.

**Tests:** `tests/phase2/queue_test.mojo`, `tests/phase2/consumer_test.mojo`

**Status:** PROVEN

---

### C3: Disconnect semantics are defined

**Statement:** When a consumer is unregistered (disconnect), its unacked messages are requeued into the inbox, becoming deliverable again.

**Implementation:** Router.unregister_consumer calls Queue.requeue_unacked (router.mojo:1048). Messages move from `_unacked` back to `_inbox`.

**Tests:** `tests/phase2/bounded_resource_test.mojo::test_unregister_leaves_unacked_message_owned_by_queue`

**Status:** PROVEN

---

### C4: Unacknowledged delivery behaviour is defined

**Statement:** Unacknowledged messages remain in the queue's `_unacked` map indefinitely until the consumer acks, rejects, or disconnects (which requeues them).

**Implementation:** Messages in `_unacked` persist until explicit resolution. No automatic timeout.

**Tests:** `tests/phase2/consumer_test.mojo` (prefetch limits), `tests/phase2/bounded_resource_test.mojo`

**Status:** PROVEN

---

### C5: Consumer cancellation cannot lose or duplicate messages unexpectedly

**Statement:** Cancelling a consumer requeues all its unacked messages. No messages are lost or duplicated.

**Implementation:** Queue.requeue_unacked (queue.mojo:542-558) moves every unacked message back to inbox. `drain_messages` (queue.mojo:522-540) is used only for queue deletion.

**Tests:** `tests/phase2/bounded_resource_test.mojo::test_unregister_leaves_unacked_message_owned_by_queue`

**Status:** PROVEN

---

## 6. Resource boundedness

### Connections
- **Limit:** None enforced in core. Transport-level only.
- **Status:** NOT ENFORCED

### Channels
- **Limit:** None enforced in core. Consumer count per connection is unlimited.
- **Status:** NOT ENFORCHED

### Queues
- **Limit:** No global queue count limit.
- **Status:** NOT ENFORCED

### Consumers
- **Limit:** No global consumer count limit.
- **Status:** NOT ENFORCED

### Messages
- **Limit:** Queue capacity enforced. No message size limit.
- **Status:** PARTIALLY VALIDATED (queue depth yes, message size no)

### Payload size
- **Limit:** None enforced.
- **Status:** NOT ENFORCED

### Frame size
- **Limit:** AMQP frame codec has max frame size check.
- **Status:** IMPLEMENTED

### Queue depth
- **Limit:** `QueueConfig._capacity` enforced. x-max-length enforced with drop-head.
- **Status:** PROVEN

### In-flight deliveries
- **Limit:** Per-consumer `_prefetch` enforced. No global in-flight limit.
- **Status:** PARTIALLY VALIDATED

### Memory
- **Limit:** Bounded by queue count × capacity × max message size. BufferPool adds bound when enabled.
- **Status:** PARTIALLY VALIDATED

### CPU/event-loop work
- **Limit:** Single-threaded. No explicit work budget.
- **Status:** IMPLEMENTED (architectural)

---

## 7. Storage integrity (P-series)

### P1: Journal corruption is fail-closed

**Statement:** A record whose CRC-32 does not match, or whose framing is invalid,
is rejected. Replay never fabricates state from corrupt bytes.

**Implementation:** `MessageJournal.replay` (`src/hyrx/core/storage.mojo`) validates
CRC-32 per record and stops at a torn/invalid tail, truncating back to the last
good record.

**Tests:** `tests/phase10/persistence_crash_test.mojo` (body-byte flip → 0 records,
framing corruption → 0 records, torn tail → truncate + idempotent re-replay).

**Status:** PROVEN

---

### P2: Write-ahead ordering precedes enqueue

**Statement:** For a durable destination, the MSG record is appended to the journal
before the message enters the queue, so a crash between the two still recovers the
message.

**Implementation:** `Router.publish` → `_journalize_enqueue` before `enqueue_prechecked`
(`src/hyrx/core/router.mojo`).

**Tests:** `tests/phase10/persistence_crash_test.mojo::test_write_ahead_recovers_unrouted_msg`.

**Status:** PROVEN

---

## 8. Transport integrity (T-series)

### T1: TLS transport confidentiality is opt-in and explicit

**Statement:** TLS on the TCP transport is disabled unless explicitly configured
(`tls_enabled` + cert/key paths). When enabled, a client must complete an OpenSSL
TLS handshake before any AMQP negotiation.

**Implementation:** `TCPListener.set_tls_config` + `TCPConnection` TLS I/O
(`src/hyrx/transport/tcp.mojo`); config invariants in `src/hyrxmq/config.mojo`.

**Tests:** `scripts/interop/tls_probe.py` (TLS 1.3 handshake, AMQP-over-TLS,
plaintext rejected); `tests/phase10/tcp_tls_test.mojo` (config + plaintext-unchanged).

**Status:** PROVEN

---

## 9. Known gaps and open invariants

| ID | Gap | Impact |
|----|-----|--------|
| G1 | No message size limit | Unbounded memory per message |
| G2 | No global consumer/queue/exchange count limits | Resource exhaustion possible |
| G3 | Headers exchange matching is a stub | **RESOLVED** — x-match=all/any (R6) |
| G4 | No mandatory publish / basic.return | **RESOLVED** — mandatory basic.return implemented |
| G5 | Error model inconsistent (raise vs None/False) | Difficult to build reliable error handling |
| G6 | read_payload with unknown tag returns empty snapshot | Indistinguishable from zero-byte payload |
| G7 | delete_queue returns empty list despite docstring promise | API contract mismatch |
| G8 | reject requeues to tail (not head like RabbitMQ) | Ordering difference from AMQP standard |
| G9 | No crash/recovery validation | **RESOLVED** — crash/corruption tests (P1/P2) |
| G10 | No external AMQP client interop | **RESOLVED** — pika 1.4.4 interop proven (Gate 3) |
| G11 | No authorization (ACLs/vhosts) | All authenticated users have full access |
| G12 | No connection/I/O timeouts | Slow client can hold the single serving slot |
