# GATE_02_OWNERSHIP_MEMORY.md

**Date:** 2026-09-11
**Commit:** 4ec2a0650807777d61a02b3a0242ccd2cc9b9eb0
**Assessor:** Automated + code review

---

## Gate verdict: PASS

The ownership/memory model is documented, the implementation matches the documentation, known copies are identified with justifications, fan-out correctness is proven, and performance measurements exist.

---

## 1. Ownership model documentation

**Document:** `docs/MEMORY_MODEL.md` (407+ lines)

The ownership model covers:
- Buffer: owned allocation, move semantics, snapshot (owned copy), no borrowed view type
- BufferSnapshot: owned copy (renamed from BufferView after audit proved it was not a view)
- BufferPool: size-classed reuse, origin-tagged, wired into Router, OFF by default
- Message: owns Envelope + Buffer, move-on-transfer
- Envelope: owns MessageID, routing_key, headers (all value semantics)
- Queue: owns all Messages (inbox, outbox, unacked)
- Delivery: lightweight UInt64 claim token only
- Consumer: value type, no heap fields
- Router: owns exchanges, queues, consumers, pool

**Status:** IMPLEMENTED and matches code.

---

## 2. Copy/allocation ledger

**Added to:** `docs/MEMORY_MODEL.md` — "Copy/Allocation Ledger" section

Every stage in the publish→delivery path traced with:
- Copy events and their justifications
- Allocation events
- Ownership transfers
- Reference/borrow events
- Serialization events

**Key findings:**
- Single-destination path: ZERO copies (message moved directly)
- Fan-out path: 1 payload copy per destination (by design — independent ownership)
- Consumer read: 1 payload copy per read_payload call (message stays in queue)
- No avoidable copies on the default path

---

## 3. Fan-out correctness

**Tested:** `tests/phase2/routing_matrix_test.mojo`

| Scenario | Result |
|----------|--------|
| 1 pub → 1 queue (direct) | routed == 1, one claim, payload copied |
| 1 pub → N queues (fanout) | routed == N, N independent owned copies |
| N pub → 1 queue | FIFO preserved |
| N pub → N queues | Full cross product |
| M consumers → 1 queue | Pull-by-call, shared cursor |
| Unroutable publish | routed == 0, source destroyed |
| Duplicate binding same queue | One copy (dedup proven) |
| Metadata fidelity on fan-out | message_id, routing_key, headers preserved |

**Fan-out does NOT create N semantically independent messages** — it creates N owned copies of the same semantic message with preserved identity.

**Status:** PROVEN

---

## 4. Lifetime safety

| Property | Evidence |
|----------|----------|
| Messages move on transfer | `var msg: Message` parameter consumed by publish/enqueue |
| Ack destroys message | `Queue.acknowledge` pops from `_unacked`, message dropped |
| Reject requeues without copy | Message moved from `_unacked` to `_inbox` |
| Consumer unregister requeues | `Queue.requeue_unacked` moves all unacked back |
| Queue delete drains | `Queue.drain_messages` extracts all messages for pool release |
| Pool reclaim on ack | `ack_reclaim` returns payload Buffer to pool |
| Pool outlives queues | Router declares `_pool` before `_queues` (reverse-order deinit) |

**Status:** PROVEN — all death sites identified and tested

---

## 5. Performance measurements

**Evidence:** `benchmarks/perf/`, `program-increments/v0.0.1-alpha/milestones/`

| Metric | Value | Source |
|--------|-------|--------|
| Gate R (Hyrx/RabbitMQ ratio) | 1.430 (CI 1.4205–1.435) | 0010 baseline |
| 128 KB TCP | 1.21x vs RabbitMQ | 0007 fix |
| Native floor | 17.25 µs/msg @ 64B | 0009 measurement |
| BufferPool throughput impact | 0.79-1.00x (no win) | pool_ab.mojo |
| Pool decision | OFF by default | Rule 17 compliance |

**Performance changes are benchmarked, not assumed.**

---

## 6. Known limitations

1. **BufferPool off by default:** No throughput win measured; kept OFF per rule 17
2. **No borrowed-view type:** BufferSnapshot copies bytes; Mojo 1.0 lacks safe async borrowed views
3. **Read_payload copies:** Consumer reads copy payload; unavoidable given queue-ownership model
4. **Fan-out copies:** N copies for N destinations; unavoidable given independent ownership

---

## 7. Regression check

- Full test suite: **47/0 PASS**
- No regressions introduced

---

## 8. Gate artifacts

| Artifact | Location |
|----------|----------|
| Ownership & Memory Model | `runtime/HyrxMQ/docs/MEMORY_MODEL.md` (updated) |
| Copy/Allocation Ledger | Added to MEMORY_MODEL.md |
| This Gate | `runtime/HyrxMQ/docs/engineering/GATE_02_OWNERSHIP_MEMORY.md` |
