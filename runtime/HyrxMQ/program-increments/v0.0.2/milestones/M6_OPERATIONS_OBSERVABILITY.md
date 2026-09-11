# Milestone M6 — Operations and Observability + Gate 6

**Priority:** 6
**Spec sections:** 25, 26, 27, 28
**Gate:** GATE_06_OPERATIONS
**Depends on:** M1

---

## Objective

Consolidate the product layer. Separate control plane from data plane. Establish authoritative observability. Test operational failures. Pass Gate 6.

## Tasks

### T6.1 — Control plane / data plane separation
Verify and document:
- [ ] Data plane: publish, route, enqueue, deliver, ack, flow control
- [ ] Control plane: configuration, topology, users, permissions, metrics, diagnostics, lifecycle
- [ ] No management functionality introduces unnecessary hot-path dependencies

### T6.2 — Authoritative observability
Expose diagnostic information for:
- [ ] connections, channels, queues, exchanges, bindings, consumers
- [ ] message rates, delivery rates, ack rates
- [ ] queue depth, in-flight deliveries
- [ ] errors, resource exhaustion
- [ ] latency, memory, CPU
- [ ] persistence, recovery

Metrics must have clearly defined semantics. Do not expose ambiguous metrics.

### T6.3 — Operational failure testing
Test:
- [ ] startup failure
- [ ] configuration failure
- [ ] port binding failure
- [ ] permission failure
- [ ] storage failure
- [ ] shutdown
- [ ] restart
- [ ] crash
- [ ] recovery
- [ ] resource exhaustion
- [ ] client disconnect
- [ ] network failure

Systemd integration tested, not merely documented.

### T6.4 — Gate 6 assessment
- [ ] Produce `docs/engineering/GATE_06_OPERATIONS.md`
- [ ] Distinguish: development operation, alpha operation, production operation
- [ ] Do not call something production-ready because systemd can launch it

## Completion criteria

- [ ] Control plane / data plane separation documented and verified
- [ ] Observability metrics exposed with defined semantics
- [ ] Operational failure tests pass
- [ ] `GATE_06_OPERATIONS.md` produced
- [ ] No regression in M1-M5 invariants

---

## Progress Report

```markdown
### Progress Report — M6 Operations & Observability + Gate 6

**Date:** [completion date]
**Commit:** [git revision]
**Status:** [COMPLETE | PARTIAL | BLOCKED]
**Gate verdict:** [PASS | FAIL | BLOCKED | NOT PROVEN]

**WHAT CHANGED:**
- [files created/modified]

**CONTROL PLANE / DATA PLANE:**
- [separation verified: YES/NO]

**OBSERVABILITY:**
- [metrics exposed, semantics defined]

**OPERATIONAL FAILURE TESTS:**
- [scenarios tested, pass/fail counts]

**OPERATIONAL MATURITY LEVEL:**
- [development / alpha / production]

**KNOWN GAPS:**
- [untested operational scenarios, ambiguous metrics]

**REGRESSION CHECK:**
- [M1 invariants: PASS/FAIL]
- [M2 ownership: PASS/FAIL]
- [M3 AMQP: PASS/FAIL]
- [M4 persistence: PASS/FAIL]
- [M5 security: PASS/FAIL]
- [full test suite: PASS/FAIL]

**READY FOR NEXT MILESTONE?**
- [YES / NO — with reason]
```
