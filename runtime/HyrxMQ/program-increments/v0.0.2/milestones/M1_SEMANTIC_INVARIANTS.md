# Milestone M1 — Semantic Invariant Model + Gate 1

**Priority:** 1
**Spec sections:** 3, 4, 5, 6
**Gate:** GATE_01_SEMANTIC_CORRECTNESS

---

## Objective

Create canonical specification for Hyrx Core's semantic invariants, turn them into executable evidence, build a machine-readable registry, and pass Gate 1.

## Tasks

### T1.1 — Semantic invariants specification
- [ ] Create `runtime/HyrxMQ/docs/SEMANTIC_INVARIANTS.md`
- [ ] Use existing naming conventions; do not invent new structure

### T1.2 — Message identity invariants
Define and test:
- [ ] M1: A message has a canonical identity
- [ ] M2: Routing does not change message identity
- [ ] M3: Fan-out does not silently mutate message identity
- [ ] M4: Payload identity is preserved through routing
- [ ] M5: Message metadata survives routing and delivery

If architecture deliberately defines different semantics, document those rather than imposing above.

### T1.3 — Envelope and delivery identity
Define and test:
- [ ] D1: A delivery is distinguishable from the underlying message
- [ ] D2: Every delivery has a defined lifecycle
- [ ] D3: Acknowledgement refers to a specific delivery
- [ ] D4: Duplicate acknowledgement has deterministic semantics
- [ ] D5: Delivery cancellation/rejection has defined semantics

### T1.4 — Routing invariants
Define and test:
- [ ] R1: Routing is deterministic for a fixed topology and input
- [ ] R2: Routing does not silently lose metadata
- [ ] R3: Routing does not introduce unintended duplication
- [ ] R4: Binding changes have defined visibility semantics
- [ ] R5: Topology mutation cannot corrupt in-flight routing

### T1.5 — Queue semantics
Define and test:
- [ ] Q1: Queue state transitions are deterministic
- [ ] Q2: Enqueue/dequeue semantics are explicit
- [ ] Q3: Queue limits are enforced
- [ ] Q4: Queue exhaustion has defined behaviour
- [ ] Q5: Consumer lifecycle cannot corrupt queue state

### T1.6 — Consumer/delivery semantics
Define and test:
- [ ] C1: Consumers have explicit lifecycle states
- [ ] C2: Delivery ownership is explicit
- [ ] C3: Disconnect semantics are defined
- [ ] C4: Unacknowledged delivery behaviour is defined
- [ ] C5: Consumer cancellation cannot lose or duplicate messages unexpectedly

### T1.7 — Resource boundedness
Establish invariants for:
- [ ] connections, channels, queues, consumers, messages
- [ ] payload size, frame size, queue depth, in-flight deliveries
- [ ] memory, CPU/event-loop work

Core principle: bounded external input → bounded internal work → bounded resource consumption.
Where boundedness is intentionally relaxed, document why.

### T1.8 — Invariant tests
- [ ] Organize tests: `tests/semantic/`, `tests/routing/`, `tests/delivery/`, `tests/ownership/`, `tests/lifecycle/`, `tests/resources/`
- [ ] Each test: PRECONDITION → ACTION → OBSERVATION → EXPECTED INVARIANT → RESULT
- [ ] Happy path AND failure path tests
- [ ] Negative tests: duplicate ack, ack after cancellation, consumer disconnect during delivery, queue exhaustion, malformed delivery state, routing to zero destinations, fan-out to multiple, topology mutation during delivery, repeated publish/consume, shutdown during active work

### T1.9 — Invariant/evidence registry
- [ ] Create `runtime/HyrxMQ/docs/invariants/registry.yaml`
- [ ] Each entry: id, category, statement, implementation, tests, status, evidence, known_limitations
- [ ] Statuses: specified, implemented, tested, provisionally-proven, proven, failed, blocked, not-applicable
- [ ] Never mark "proven" without reproducible executable evidence

### T1.10 — Gate 1 assessment
- [ ] Produce `docs/engineering/GATE_01_SEMANTIC_CORRECTNESS.md`
- [ ] Audit core implementation against invariants
- [ ] Record known violations explicitly
- [ ] Resolve or mark ambiguous semantics as unresolved
- [ ] No documentation claims exceed implementation evidence
- [ ] Gate verdict per major invariant group: PASS, FAIL, BLOCKED, NOT PROVEN

## Completion criteria

- [ ] `SEMANTIC_INVARIANTS.md` exists with all invariant groups
- [ ] Tests exist for applicable invariants (happy + failure paths)
- [ ] `registry.yaml` populated with all invariants and current status
- [ ] `GATE_01_SEMANTIC_CORRECTNESS.md` produced
- [ ] Full existing test suite + new tests pass with no regressions

---

## Progress Report

```markdown
### Progress Report — M1 Semantic Invariants + Gate 1

**Date:** [completion date]
**Commit:** [git revision]
**Status:** [COMPLETE | PARTIAL | BLOCKED]
**Gate verdict:** [PASS | FAIL | BLOCKED | NOT PROVEN]

**WHAT CHANGED:**
- [files created/modified]

**INVARIANTS SPECIFIED:**
- [count by category: M1-M5, D1-D5, R1-R5, Q1-Q5, C1-C5, resource boundedness]

**INVARIANTS TESTED:**
- [count of invariants with executable tests]

**INVARIANTS PROVEN:**
- [count with reproducible evidence]

**INVARIANTS FAILED/BLOCKED:**
- [list with reasons]

**WHAT WAS TESTED:**
- [test suites run, results]

**KNOWN GAPS:**
- [untested invariants, ambiguous semantics]

**RISKS/BLOCKERS:**
- [issues for downstream milestones]

**REGRESSION CHECK:**
- [full test suite pass/fail]

**READY FOR NEXT MILESTONE?**
- [YES / NO — with reason]
```
