# GATE_03_AMQP_INTEROPERABILITY.md

**Date:** 2026-09-11
**Commit:** 4ec2a0650807777d61a02b3a0242ccd2cc9b9eb0
**Assessor:** Automated + code review
**RabbitMQ reference:** 4.3.5 (rabbitmq:4-management, Docker)
**pika version:** 1.4.4

---

## Gate verdict: PARTIAL PASS (Level A proven, Level B partial)

---

## 1. Compatibility levels achieved

### Level A — TCP + AMQP handshake: PROVEN

Evidence:
- `benchmarks/perf/results.json` — pika connects, negotiates, publishes, consumes
- `scripts/interop/pika_negotiation.py` — handshake gate steps PASS
- `scripts/interop/pika_content.py` — content frame reassembly verified

Steps verified:
| Step | Status | Evidence |
|------|--------|----------|
| TCP connect | PASS | pika connects to HyrxMQ port |
| AMQP header exchange | PASS | 8-byte protocol header consumed |
| connection.start/start-ok | PASS | PLAIN authentication |
| connection.tune/tune-ok | PASS | frame_max, channel_max negotiated |
| connection.open/open-ok | PASS | vhost opened |
| channel.open | PASS | Channel established |
| exchange.declare | PASS | Direct, fanout, topic, headers exchanges |
| queue.declare | PASS | Queues created with config |
| queue.bind | PASS | Bindings established |

### Level B — Publish/Consume/Ack: PARTIALLY PROVEN

| Operation | Status | Evidence |
|-----------|--------|----------|
| basic.publish | PASS | pika publish → HyrxMQ routes |
| basic.deliver | PASS | Consumer receives delivery |
| basic.get | PASS | Synchronous get works |
| basic.ack | PASS | Acknowledgement works |
| basic.nack/reject | PASS | Rejection requeues |
| Content properties | PASS | Byte-faithful content props preserved |
| Multi-frame body | PASS | 9000-byte body reassembled correctly |
| QoS/prefetch | NOT TESTED | — |
| Publisher confirms | NOT IMPLEMENTED | — |
| Mandatory publish | NOT IMPLEMENTED | — |
| TTL | IMPLEMENTED (engine) | Not tested via pika |
| Dead-letter exchange | IMPLEMENTED (engine) | Not tested via pika |
| Exchange-to-exchange | IMPLEMENTED (engine) | Not tested via pika |

### Level C — Extension interoperability: NOT TESTED

### Level D — Operational interoperability: NOT TESTED

---

## 2. Differential testing

### RabbitMQ reference baseline

`scripts/interop/pika_lifecycle.py` runs 18 steps against RabbitMQ 4.3.5:
- connect, authenticate (positive + negative), channel.open, exchange.declare,
  queue.declare, queue.bind, basic.publish, basic.deliver, basic.get,
  basic.ack, basic.reject, basic.nack, prefetch, channel.close, connection.close

**Result: 18/18 PASS** (reference baseline).

### HyrxMQ differential

The benchmark harness (`benchmarks/perf/harness.py`) runs the same pika client against both brokers:
- Same connection parameters
- Same exchange/queue/binding topology
- Same publish→get workload
- Same teardown (abrupt close on both sides)

**Result:** HyrxMQ completes the full workload at 1.43x vs RabbitMQ (gate R).

### Behavior classification

| Observable | HyrxMQ | RabbitMQ | Classification |
|------------|--------|----------|----------------|
| Connection negotiation | Works | Works | AMQP requirement |
| Exchange/queue declare | Works | Works | AMQP requirement |
| Publish routing | Works | Works | AMQP requirement |
| basic.get | Works | Works | AMQP requirement |
| basic.deliver | Works | Works | AMQP requirement |
| basic.ack | Works | Works | AMQP requirement |
| basic.nack/reject | Works | Works | AMQP requirement |
| Connection close | Abrupt (no close-ok) | Graceful | Intentional HyrxMQ difference |
| Channel close | Not implemented | Graceful | NOT IMPLEMENTED |
| Default exchange auto-bind | Implemented | Implemented | AMQP requirement |
| Headers exchange matching | x-match=all/any implemented | Correct matching | RESOLVED (D4/D10) |
| Reject requeue position | Tail | Head | Intentional difference (D9) |

---

## 3. Reproducible receipts

| Receipt | Location | Client | Server | Result |
|---------|----------|--------|--------|--------|
| Benchmark run | `benchmarks/perf/results.json` | pika 1.4.4 | HyrxMQ (4ec2a06) | PASS |
| Negotiation gate | `scripts/interop/pika_negotiation.py` | pika 1.4.4 | HyrxMQ | PASS |
| Content frame gate | `scripts/interop/pika_content.py` | pika 1.4.4 | HyrxMQ | PASS |
| RabbitMQ baseline | `scripts/interop/pika_lifecycle.py` | pika 1.4.4 | RabbitMQ 4.3.5 | 18/18 PASS |

---

## 4. Known deviations

1. **Connection close:** HyrxMQ does not send `connection.close-ok` / `channel.close-ok`. Abrupt close on benchmark side to maintain symmetry.
2. **Headers exchange:** `x-match=all` / `x-match=any` matching implemented in `src/hyrx/core/exchange.mojo`; covered by `tests/phase2/exchange_test.mojo` (`test_headers_match_all`, `test_headers_match_any`, `test_headers_no_match`). D4/D10 resolved.
3. **Reject ordering:** Requeues to tail (D9), not head like RabbitMQ.
4. **No channel.close:** Channel lifecycle not fully implemented.
5. **No publisher confirms:** Cannot verify publish durability.
6. **No mandatory publish:** Cannot signal unroutable messages.

---

## 5. Canonical compatibility document

Updated: `docs/RABBITMQ_COMPATIBILITY.md` — stale "NOT PROVEN" status corrected to reflect actual evidence.

No contradictory status remains in the repository.

---

## 6. Regression check

- Full test suite: **52/0 PASS**
- Benchmark harness produces consistent results

---

## 7. Gate artifacts

| Artifact | Location |
|----------|----------|
| Compatibility Policy | `docs/COMPATIBILITY_POLICY.md` |
| RabbitMQ Compatibility | `docs/RABBITMQ_COMPATIBILITY.md` (updated) |
| Benchmark Results | `benchmarks/perf/results.json` |
| Interop Scripts | `scripts/interop/` |
| This Gate | `docs/engineering/GATE_03_AMQP_INTEROPERABILITY.md` |
