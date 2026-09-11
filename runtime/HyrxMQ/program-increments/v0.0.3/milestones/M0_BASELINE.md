# Milestone M0 — Baseline + Stale Assessment Correction

**Priority:** 0
**Gate:** — (baseline only)
**Depends on:** v0.0.2 completion

---

## Objective

Correct v0.0.2 assessment errors where features were listed as NOT IMPLEMENTED but are actually implemented. Establish clean baseline for v0.0.3.

## Tasks

### T0.1 — Correct v0.0.2 FINAL_ENGINEERING_ASSESSMENT.md
- [ ] Channel.close / connection.close-ok: already IMPLEMENTED (amqp_service.mojo:27-34)
- [ ] Publisher confirms: already IMPLEMENTED (amqp_service.mojo:43-53)
- [ ] Transactions: already IMPLEMENTED (amqp_service.mojo:54-61)
- [ ] TTL/DLX via AMQP: already IMPLEMENTED (amqp_service.mojo:72-93)
- [ ] Prefetch/QoS via AMQP: already IMPLEMENTED (basic.qos imported)
- [ ] basic.nack: already IMPLEMENTED (imported)
- [ ] Default exchange routing: already IMPLEMENTED (amqp_service.mojo:91-92)

### T0.2 — Update v0.0.2 progress reports
- [ ] Note corrections in M7_PROGRESS.md

### T0.3 — Establish v0.0.3 baseline
- [ ] Run full test suite: pixi run test
- [ ] Confirm 47/0 PASS
- [ ] Produce CURRENT_STATE.md for v0.0.3

### T0.4 — Create v0.0.3 milestone files
- [ ] M1_correctness.md
- [ ] M2_security.md
- [ ] M3_operations.md
- [ ] M4_persistence.md
- [ ] M5_final_integration.md

## Completion criteria

- v0.0.2 assessment corrected
- Test suite PASS
- v0.0.3 milestones defined
