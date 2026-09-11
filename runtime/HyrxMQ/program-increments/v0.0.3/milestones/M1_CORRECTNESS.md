# Milestone M1 — Correctness Defects + Crash Tests

**Priority:** 1
**Gate:** CORRECTNESS GATE
**Depends on:** M0

---

## Objective

Resolve all open correctness defects (D14, D4/D10, D5, D11, D15) and add crash/corruption tests for persistence.

## Tasks

### T1.1 — Fix D14: Multiple routing authority
- [ ] Identify the fanout routing leak (D5) that causes messages to appear in direct/topic exchanges
- [ ] Ensure Router is the sole routing authority — all exchange.match() results flow through Router
- [ ] Add test: fanout-published message does NOT appear in direct/topic queues
- [ ] Verify single-dest zero-copy path still works after fix

### T1.2 — Fix D4/D10: Headers exchange stub
- [ ] Implement full headers matching (x-match argument: "all" vs "any")
- [ ] Support matching on header presence, value equality, and value comparison
- [ ] Add test: headers exchange with x-match=all matches only when ALL headers match
- [ ] Add test: headers exchange with x-match=any matches when ANY header matches
- [ ] Add test: headers exchange with no matching headers delivers to zero queues

### T1.3 — Fix D5: Fanout routing leak
- [ ] Trace the code path where fanout messages leak into direct/topic
- [ ] Ensure exchange type check is correct (not string comparison)
- [ ] Add test: publish to fanout exchange, verify only fanout-bound queues receive

### T1.4 — Fix D11: Dead QueueConfig._durable field
- [ ] Remove QueueConfig._durable if truly dead
- [ ] Or wire it through if needed for persistence
- [ ] Verify durable flag still works via AMQP queue.declare

### T1.5 — Fix D15: Dead AMQPFrameCodec._compact
- [ ] Remove dead code
- [ ] Verify no callers depend on it

### T1.6 — Crash-at-controlled-point tests
- [ ] Design fork+kill test harness
- [ ] Test: crash after WAL write, before queue entry → message recovered on replay
- [ ] Test: crash during WAL write → partial record detected, truncated
- [ ] Test: crash after ack journal write, before tombstone → message re-delivered
- [ ] Test: clean shutdown → valid journal, clean recovery

### T1.7 — Corruption injection tests
- [ ] Corrupt a WAL record body → CRC-32 rejection
- [ ] Corrupt a WAL record header → framing error
- [ ] Corrupt middle of multi-record journal → good records before corruption replayed

## Completion criteria

- All defects resolved (D14, D4, D5, D11, D15)
- Crash tests pass
- Corruption tests pass
- Full test suite PASS
- No regressions in existing invariants
