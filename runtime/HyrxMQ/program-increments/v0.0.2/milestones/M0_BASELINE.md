# Milestone M0 — Establish Current Baseline

**Priority:** 0 (must complete before any other milestone)
**Spec sections:** 1, 2
**Gate:** None (prerequisite)

---

## Objective

Inspect the complete current Hyrx/HyrxMQ tree and produce an honest snapshot of reality before any substantive work begins.

## Non-negotiable architectural principles (Section 1)

Preserve existing architectural separation:

```text
Hyrx Core ≠ HyrxMQ ≠ AMQP ≠ TCP ≠ UDS ≠ WSS/HTTP ≠ simulation
```

- Hyrx Core = semantic messaging substrate
- HyrxMQ = one product/runtime manifestation
- AMQP = adapter/protocol surface, not canonical internal representation
- Transport = physical execution mechanism, not semantic messaging model

Hyrx Core must NOT introduce dependencies into AMQP, TCP, filesystem, systemd, TLS, HTTP, WSS, RabbitMQ, or simulation unless an existing architectural specification explicitly requires it.

If a conflict arises, stop and document before implementing.

## Tasks

### T0.1 — Full repository inspection
- [ ] Read complete current Hyrx/HyrxMQ tree
- [ ] Read current architecture and core specifications
- [ ] Read current programme increments and milestone records
- [ ] Inspect all current tests
- [ ] Inspect current AMQP compatibility material
- [ ] Inspect current performance measurements
- [ ] Inspect persistence implementation and tests
- [ ] Inspect current security implementation vs. security specification
- [ ] Inspect management/control-plane implementation

### T0.2 — Validation and toolchain
- [ ] Run existing validation suite
- [ ] Establish compiler/toolchain version used by repository
- [ ] Record current git revision/commit being evaluated

### T0.3 — Baseline report
- [ ] Create `docs/engineering/CURRENT_STATE.md`
- [ ] Distinguish: IMPLEMENTED, TESTED, PROVEN, PARTIALLY VALIDATED, SPECIFIED ONLY, NOT IMPLEMENTED, NOT PROVEN
- [ ] Do not use ambiguous terms like "supported" without identified evidence

## Completion criteria

- [ ] Baseline report produced at `docs/engineering/CURRENT_STATE.md`
- [ ] All sections above checked and classified with honest evidence
- [ ] No claim exceeds the evidence supporting it
- [ ] All other milestones validated against this baseline before beginning

---

## Progress Report

Upon completion of this milestone, produce a progress report with the following structure. Fill in each field with honest, evidence-backed content.

```markdown
### Progress Report — M0 Baseline

**Date:** [completion date]
**Commit:** [git revision]
**Status:** [COMPLETE | PARTIAL | BLOCKED]

**WHAT CHANGED:**
- [list of files created/modified]

**WHAT WAS TESTED:**
- [validation suite run, toolchain verified]

**OBSERVATIONS:**
- [key findings about current state]

**INVARIANTS ESTABLISHED:**
- [what this milestone establishes, or "none — assessment only"]

**KNOWN GAPS:**
- [what could not be verified, what is missing]

**RISKS/BLOCKERS:**
- [issues discovered that may affect downstream milestones]

**READY FOR NEXT MILESTONE?**
- [YES / NO — with reason]
```
