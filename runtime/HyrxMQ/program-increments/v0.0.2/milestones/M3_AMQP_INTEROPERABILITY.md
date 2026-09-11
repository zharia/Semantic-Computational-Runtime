# Milestone M3 — AMQP/RabbitMQ Interoperability + Gate 3

**Priority:** 3
**Spec sections:** 12, 13, 14, 15, 16
**Gate:** GATE_03_AMQP_INTEROPERABILITY
**Depends on:** M1

---

## Objective

Resolve all contradictory compatibility claims, build an AMQP interoperability corpus with real external clients, create RabbitMQ differential testing, produce reproducible receipts, and pass Gate 3.

## Tasks

### T3.1 — Canonical compatibility statement
- [ ] Resolve all contradictory compatibility claims in repository
- [ ] Produce ONE canonical current statement of interoperability status
- [ ] No contradictory status remains elsewhere in repository

### T3.2 — AMQP interoperability corpus (core)
Test with real external clients (pika, RabbitMQ, other AMQP tooling):
- [ ] connection
- [ ] connection negotiation
- [ ] channel creation
- [ ] exchange declaration
- [ ] queue declaration
- [ ] binding
- [ ] publish
- [ ] consume
- [ ] ack
- [ ] nack
- [ ] reject
- [ ] close
- [ ] reconnect

### T3.3 — AMQP interoperability corpus (extended)
Progressively test:
- [ ] QoS/prefetch
- [ ] publisher confirms
- [ ] mandatory publish
- [ ] TTL
- [ ] dead-letter exchange
- [ ] priority
- [ ] alternate exchange
- [ ] exchange-to-exchange
- [ ] authentication
- [ ] virtual hosts
- [ ] authorization

Only mark features as compatible when actual evidence exists.

### T3.4 — RabbitMQ differential testing
Run equivalent workloads against RabbitMQ and HyrxMQ, capture and compare:
- [ ] routing, delivery, ordering
- [ ] acknowledgement, errors
- [ ] connection behaviour, channel behaviour
- [ ] resource limits, recovery

Classify each difference:
- Hyrx bug
- RabbitMQ-specific behaviour
- AMQP requirement
- undefined/implementation-specific behaviour
- intentional Hyrx semantic difference
- unknown

Do not automatically reproduce RabbitMQ behaviour if it violates Hyrx semantic architecture.

### T3.5 — Interoperability receipts
Every compatibility milestone produces a reproducible receipt:
- [ ] environment, client, server, commit, configuration
- [ ] test, result, logs, observed protocol sequence
- [ ] pass/fail, known deviations
- [ ] Statements must be objectively verifiable

### T3.6 — Gate 3 assessment
- [ ] Produce `docs/engineering/GATE_03_AMQP_INTEROPERABILITY.md`
- [ ] Level A: TCP + AMQP handshake — proven/not proven
- [ ] Level B: publish — proven/not proven
- [ ] Level C: consume — proven/not proven
- [ ] Level D: acknowledgement/recovery — proven/not proven
- [ ] Level E: broader RabbitMQ behavioural compatibility — proven/not proven
- [ ] Do not claim higher level when only lower level is proven
- [ ] Update canonical compatibility document

## Completion criteria

- [ ] One canonical compatibility statement exists
- [ ] Core AMQP corpus tests pass with external clients
- [ ] Differential testing performed and classified
- [ ] Reproducible receipts for each compatibility claim
- [ ] `GATE_03_AMQP_INTEROPERABILITY.md` produced
- [ ] No regression in M1/M2 invariants

---

## Progress Report

```markdown
### Progress Report — M3 AMQP Interoperability + Gate 3

**Date:** [completion date]
**Commit:** [git revision]
**Status:** [COMPLETE | PARTIAL | BLOCKED]
**Gate verdict:** [PASS | FAIL | BLOCKED | NOT PROVEN]
**Interoperability level achieved:** [A | B | C | D | E]

**WHAT CHANGED:**
- [files created/modified]

**CORE AMQP TESTS:**
- [pass/total count]

**EXTENDED AMQP TESTS:**
- [pass/total count]

**DIFFERENTIAL TESTING:**
- [scenarios tested, differences classified]

**EXTERNAL CLIENTS USED:**
- [pika, RabbitMQ version, other tooling]

**RECEIPTS PRODUCED:**
- [count, locations]

**KNOWN DEVIATIONS:**
- [list with classification]

**REGRESSION CHECK:**
- [M1 invariants: PASS/FAIL]
- [M2 ownership: PASS/FAIL]
- [full test suite: PASS/FAIL]

**READY FOR NEXT MILESTONE?**
- [YES / NO — with reason]
```
