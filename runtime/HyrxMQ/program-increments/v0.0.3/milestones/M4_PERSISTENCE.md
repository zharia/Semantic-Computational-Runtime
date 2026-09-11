# Milestone M4 — Persistence Crash Validation

**Priority:** 4
**Gate:** PERSISTENCE GATE
**Depends on:** M0

---

## Objective

Validate all persistence claims with crash tests, corruption injection, and multi-queue scenarios.

## Tasks

### T4.1 — Crash-at-controlled-point tests
- [ ] Design test harness: fork process, inject crash at specific point, replay journal
- [ ] Test: crash after WAL write_enqueue, before queue entry → message recovered
- [ ] Test: crash after WAL write_ack, before tombstone → message re-delivered
- [ ] Test: crash during WAL write → partial record truncated, good records recovered
- [ ] Test: crash after WAL write_remove → message not resurrected

### T4.2 — Clean shutdown + restart
- [ ] Test: publish messages, clean shutdown, restart → all messages recovered
- [ ] Test: publish + ack, clean shutdown, restart → acked messages not re-delivered
- [ ] Test: declare durable queue, clean shutdown, restart → queue recovered with correct config

### T4.3 — Multi-queue persistence
- [ ] Test: two durable queues, publish to both, crash → both recovered
- [ ] Test: durable queue + non-durable queue, crash → only durable recovered
- [ ] Test: durable queue with bindings, crash → bindings recovered

### T4.4 — I/O failure simulation
- [ ] Extend FakeOps to support error injection
- [ ] Test: disk full on WAL write → error propagated, no corruption
- [ ] Test: permission failure on WAL open → error propagated
- [ ] Test: read failure on replay → error propagated

### T4.5 — WAL journal integrity
- [ ] Test: journal with zero records → clean recovery (empty state)
- [ ] Test: journal with one record → clean recovery
- [ ] Test: journal with N records → all N recovered
- [ ] Test: journal with torn final record → truncated, good records recovered
- [ ] Test: journal replay is idempotent (replay twice, same result)

## Completion criteria

- All crash tests pass
- All corruption tests pass
- All multi-queue tests pass
- All I/O failure tests pass
- Full test suite PASS
- All persistence claims from v0.0.2 Gate 4 verified
