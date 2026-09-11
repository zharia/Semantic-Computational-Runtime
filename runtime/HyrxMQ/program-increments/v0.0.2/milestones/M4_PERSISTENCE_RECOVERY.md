# Milestone M4 — Persistence and Crash Recovery + Gate 4

**Priority:** 4
**Spec sections:** 17, 18, 19, 20
**Gate:** GATE_04_PERSISTENCE
**Depends on:** M1

---

## Objective

Treat persistence as a semantic correctness problem. Define durability model, document state-transition model, implement crash/recovery testing, and pass Gate 4.

## Tasks

### T4.1 — Durability model
- [ ] Define durability modes: volatile, memory-backed, recoverable, durable, crash-consistent
- [ ] Define exactly what each mode promises
- [ ] Document which mode applies to which components

### T4.2 — Persistence state-transition model
Document externally observable state transitions before persistence:
```
publish → journal → enqueue → deliver → ack
```
- [ ] Determine durability point for each operation
- [ ] Define behaviour when process terminates at each point:
  - before/during/after journal write
  - before/after enqueue
  - before/after delivery
  - before/after ack

### T4.3 — Crash/recovery testing
Build automated recovery tests:
```
start → publish known workload → terminate at controlled point → restart → recover → inspect state → compare expected semantic state
```
Test:
- [ ] incomplete records
- [ ] truncated records
- [ ] repeated records
- [ ] invalid records
- [ ] corruption
- [ ] clean shutdown
- [ ] abrupt process termination
- [ ] multiple queues
- [ ] outstanding deliveries
- [ ] acknowledgements
- [ ] topology state

Do not declare persistence reliable because data survives normal restart.

### T4.4 — Gate 4 assessment
- [ ] Produce `docs/engineering/GATE_04_PERSISTENCE.md`
- [ ] Documented durability semantics
- [ ] Journal/storage invariants defined
- [ ] Recovery tests implemented and passing
- [ ] Crash tests implemented and passing
- [ ] Corruption handling tested
- [ ] Deterministic recovery behaviour verified
- [ ] Evidence-backed durability claims

## Completion criteria

- [ ] Durability model documented
- [ ] State-transition model documented with durability points
- [ ] Crash/recovery tests pass for all listed scenarios
- [ ] `GATE_04_PERSISTENCE.md` produced
- [ ] No regression in M1/M2/M3 invariants

---

## Progress Report

```markdown
### Progress Report — M4 Persistence & Recovery + Gate 4

**Date:** [completion date]
**Commit:** [git revision]
**Status:** [COMPLETE | PARTIAL | BLOCKED]
**Gate verdict:** [PASS | FAIL | BLOCKED | NOT PROVEN]

**WHAT CHANGED:**
- [files created/modified]

**DURABILITY MODES DEFINED:**
- [volatile / memory-backed / recoverable / durable / crash-consistent]

**STATE-TRANSITION MODEL:**
- [stages documented, durability points identified]

**CRASH/RECOVERY TESTS:**
- [scenarios tested, pass/fail counts]

**CORRUPTION HANDLING:**
- [tested scenarios, behaviour]

**KNOWN GAPS:**
- [untested termination points, missing corruption tests]

**REGRESSION CHECK:**
- [M1 invariants: PASS/FAIL]
- [M2 ownership: PASS/FAIL]
- [M3 AMQP: PASS/FAIL]
- [full test suite: PASS/FAIL]

**READY FOR NEXT MILESTONE?**
- [YES / NO — with reason]
```
