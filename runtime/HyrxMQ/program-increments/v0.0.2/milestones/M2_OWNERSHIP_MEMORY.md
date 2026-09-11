# Milestone M2 — Ownership, Memory Model + Gate 2

**Priority:** 2
**Spec sections:** 7, 8, 9, 10, 11
**Gate:** GATE_02_OWNERSHIP_MEMORY
**Depends on:** M1

---

## Objective

Create a canonical ownership/memory model, trace every copy and allocation through the message path, verify fan-out correctness, benchmark before/after optimization, and pass Gate 2.

## Tasks

### T2.1 — Ownership and memory model
- [ ] Create `runtime/HyrxMQ/docs/OWNERSHIP_AND_MEMORY.md`
- [ ] Describe ownership/lifetime for: message, envelope, payload, metadata, queue, delivery, consumer, transport, codec
- [ ] Classify each as: owned, borrowed, shared, moved, copied, reference-counted
- [ ] Must match actual Mojo implementation and supported language semantics
- [ ] Do not invent an ownership model the implementation does not enforce

### T2.2 — Copy/allocation ledger
Trace complete message path:
```
publish → protocol decode → canonical message → routing → queue → delivery → consumer → protocol encode → transport
```
For each stage record:
- [ ] copy? allocation? ownership transfer? reference? serialization? reason? avoidable?
- [ ] Produce auditable ledger (table format)

Core principle: every copy and allocation must have a semantic or physical justification. Not "zero copies at any cost."

### T2.3 — Fan-out correctness
- [ ] Verify one semantic message → N destinations does NOT become N semantically independent messages (unless explicitly intended)
- [ ] Preserve: message identity, metadata, payload correctness, delivery identity, acknowledgement semantics across fan-out
- [ ] Create regression tests for documented copy/metadata issues

### T2.4 — Before/after performance measurements
Establish repeatable measurements for:
- [ ] single destination, fan-out 2, fan-out 8, fan-out 32, fan-out 128

Measure:
- [ ] throughput, latency, tail latency
- [ ] allocations, copies, memory footprint
- [ ] CPU, queue contention, event-loop behaviour

Record: hardware, OS, compiler/toolchain, build mode, message size, fan-out, consumer count, queue count, transport, duration, sample count.

No synthetic numbers without workload description.

### T2.5 — Optimization (if justified)
- [ ] Remove avoidable copies where evidence supports it
- [ ] Do not optimize blindly; every change must be measured

### T2.6 — Gate 2 assessment
- [ ] Produce `docs/engineering/GATE_02_OWNERSHIP_MEMORY.md`
- [ ] Ownership semantics documented and match implementation
- [ ] Known copies identified
- [ ] Avoidable copies removed where justified
- [ ] Fan-out correctness proven
- [ ] Lifetime safety tested
- [ ] Allocation/copy measurements exist
- [ ] Performance changes benchmarked rather than assumed

## Completion criteria

- [ ] `OWNERSHIP_AND_MEMORY.md` exists, matches implementation
- [ ] Copy/allocation ledger produced
- [ ] Fan-out correctness tests pass
- [ ] Performance measurements recorded (before and after)
- [ ] `GATE_02_OWNERSHIP_MEMORY.md` produced
- [ ] No regression in M1 invariants

---

## Progress Report

```markdown
### Progress Report — M2 Ownership & Memory + Gate 2

**Date:** [completion date]
**Commit:** [git revision]
**Status:** [COMPLETE | PARTIAL | BLOCKED]
**Gate verdict:** [PASS | FAIL | BLOCKED | NOT PROVEN]

**WHAT CHANGED:**
- [files created/modified]

**OWNERSHIP MODEL:**
- [objects classified, match to implementation: YES/NO]

**COPY/ALLOCATION LEDGER:**
- [total stages traced, copies identified, avoidable eliminated]

**FAN-OUT CORRECTNESS:**
- [tested scenarios, any violations found]

**PERFORMANCE MEASUREMENTS:**
- [before/after summary, fan-out levels tested]

**KNOWN GAPS:**
- [untraced stages, unmeasured configurations]

**REGRESSION CHECK:**
- [M1 invariants: PASS/FAIL]
- [full test suite: PASS/FAIL]

**READY FOR NEXT MILESTONE?**
- [YES / NO — with reason]
```
