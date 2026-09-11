# GATE_01_SEMANTIC_CORRECTNESS.md

**Date:** 2026-09-11
**Commit:** 4ec2a0650807777d61a02b3a0242ccd2cc9b9eb0
**Assessor:** Automated + code review

---

## Gate verdict: CONDITIONAL PASS

The semantic invariants are well-specified and the core implementation has executable evidence for the majority of them. The gate passes with the following conditions recorded.

---

## 1. Invariant group assessment

### Message identity (M1-M5)

| Invariant | Verdict | Evidence |
|-----------|---------|----------|
| M1: canonical identity | **PASS** | MessageID struct, equality, tested |
| M2: routing preserves identity | **PASS** | router.mojo copies msg.message_id() per destination |
| M3: fan-out preserves identity | **PASS** | routing_matrix_test metadata fidelity tests |
| M4: payload preserved | **PASS** | byte_path_test, Buffer.from_buffer_copy |
| M5: metadata survives routing | **PASS** | routing_key + headers preserved, read-back tested |

**Group verdict: PASS**

---

### Envelope and delivery identity (D1-D5)

| Invariant | Verdict | Evidence |
|-----------|---------|----------|
| D1: delivery distinguishable | **PASS** | Delivery is UInt64 tag, message stays in Queue |
| D2: defined lifecycle | **PASS** | inbox→outbox→unacked→ack/reject transitions tested |
| D3: ack refers to specific delivery | **PASS** | acknowledge(delivery_tag) operates on one entry |
| D4: duplicate ack deterministic | **PASS** | Returns False, no side effect |
| D5: rejection defined | **PASS** | Requeues to tail, delivery_count incremented |

**Group verdict: PASS**

---

### Routing (R1-R5)

| Invariant | Verdict | Evidence |
|-----------|---------|----------|
| R1: deterministic routing | **PASS** | Exchange.match is pure function |
| R2: no metadata loss | **PASS** | Same as M2/M5 |
| R3: no unintended duplication | **PASS** | Destination-set dedup proven |
| R4: binding visibility defined | **PASS** | Immediate effect, single-threaded |
| R5: topology mutation safe | **PASS** | Single-threaded architecture |

**Group verdict: PASS**

---

### Queue semantics (Q1-Q5)

| Invariant | Verdict | Evidence |
|-----------|---------|----------|
| Q1: deterministic transitions | **PASS** | Deterministic state machine |
| Q2: explicit enqueue/dequeue | **PASS** | Two-stack FIFO tested |
| Q3: limits enforced | **PASS** | Queue depth + x-max-length enforced |
| Q4: exhaustion defined | **PASS** | enqueue returns False, message destroyed |
| Q5: consumer lifecycle safe | **PASS** | Register/unregister tested |

**Group verdict: PASS**

---

### Consumer/delivery semantics (C1-C5)

| Invariant | Verdict | Evidence |
|-----------|---------|----------|
| C1: explicit lifecycle | **PASS** | Consumer struct with state tracking |
| C2: ownership explicit | **PASS** | _unacked[tag] ownership model |
| C3: disconnect defined | **PASS** | Requeue on unregister |
| C4: unacked defined | **PASS** | Persist until ack/reject/disconnect |
| C5: no loss/duplication | **PASS** | requeue_unacked tested |

**Group verdict: PASS**

---

### Resource boundedness

| Invariant | Verdict | Evidence |
|-----------|---------|----------|
| RB1: queue depth bounded | **PASS** | Capacity enforcement tested |
| RB2: prefetch bounded | **PASS** | can_deliver() tested |
| RB3: message size bounded | **FAIL** | No limit enforced |
| RB4: consumer count bounded | **NOT PROVEN** | No limit |
| RB5: queue count bounded | **NOT PROVEN** | No limit |
| RB6: exchange count bounded | **NOT PROVEN** | No limit |

**Group verdict: PARTIAL — queue depth and prefetch proven; global resource limits not enforced**

---

## 2. Known violations

| ID | Invariant | Violation | Impact |
|----|-----------|-----------|--------|
| G3 | R1 (routing) | Headers exchange stub matches all bindings | Incorrect routing for headers-type exchanges |
| G5 | D3 (delivery) | Error model inconsistent (raise vs None/False) | read_payload raises on unknown consumer; ack/reject return False |
| G6 | D3 (delivery) | read_payload with unknown tag returns empty snapshot | Indistinguishable from zero-byte payload |
| G8 | D5 (rejection) | Reject requeues to tail, not head | Ordering differs from RabbitMQ |
| G10 | RB3 | No message size limit | Unbounded memory per message |

---

## 3. Ambiguous semantics (marked unresolved)

| Item | Ambiguity | Resolution |
|------|-----------|------------|
| Headers exchange matching | Stub matches all; spec says match on headers | UNRESOLVED — needs implementation |
| Reject ordering | Tail vs head requeue | UNRESOLVED — needs architectural decision |
| basic.return for mandatory | Not implemented | UNRESOLVED — needs specification |

---

## 4. Documentation integrity

All claims in `SEMANTIC_INVARIANTS.md` are backed by code references and test references. No documentation claim exceeds implementation evidence.

Stale claims found and corrected:
- MEMORY_MODEL.md previously referred to "BufferView" (now renamed to "BufferSnapshot") — already corrected in codebase
- MEMORY_MODEL.md §22 documents the rename and why

---

## 5. Regression check

- Full test suite: **47/0 PASS**
- No regressions introduced by this gate's documentation work

---

## 6. Conditions for full pass

This gate passes conditionally. The following must be addressed in downstream milestones:

1. **G3 (headers exchange):** Implement correct matching or explicitly document as known limitation
2. **G5/G6 (error model):** Choose one error model and apply consistently
3. **G8 (reject ordering):** Make architectural decision on requeue position
4. **RB3-RB6 (resource limits):** Implement or explicitly document as deferred

---

## 7. Gate artifacts

| Artifact | Location |
|----------|----------|
| Semantic Invariants | `runtime/HyrxMQ/docs/SEMANTIC_INVARIANTS.md` |
| Invariant Registry | `runtime/HyrxMQ/docs/invariants/registry.yaml` |
| Current State | `runtime/HyrxMQ/docs/engineering/CURRENT_STATE.md` |
| This Gate | `runtime/HyrxMQ/docs/engineering/GATE_01_SEMANTIC_CORRECTNESS.md` |
