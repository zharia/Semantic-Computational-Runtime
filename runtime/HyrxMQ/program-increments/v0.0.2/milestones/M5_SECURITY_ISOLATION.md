# Milestone M5 — Security and Isolation + Gate 5

**Priority:** 5
**Spec sections:** 21, 22, 23, 24
**Gate:** GATE_05_SECURITY_ISOLATION
**Depends on:** M1

---

## Objective

Audit security specification against implementation, define security semantic boundary, implement hostile-input testing, and pass Gate 5.

## Tasks

### T5.1 — Security audit matrix
Create matrix of capability vs. evidence:

| Capability         | Specified | Implemented | Tested | Proven |
| ------------------ | --------: | ----------: | -----: | -----: |
| TLS                |           |             |        |        |
| authentication     |           |             |        |        |
| SASL               |           |             |        |        |
| vhosts             |           |             |        |        |
| authorization      |           |             |        |        |
| resource limits    |           |             |        |        |
| frame limits       |           |             |        |        |
| message limits     |           |             |        |        |
| timeout protection |           |             |        |        |
| hostile input      |           |             |        |        |
| systemd hardening  |           |             |        |        |

Do not count architecture documents as implementation.

### T5.2 — Security semantic boundary
Model: Principal → Authentication → Authorization → Virtual host/resource boundary → Operation

Verify no authenticated principal can improperly:
- [ ] observe another principal's data
- [ ] mutate another principal's topology
- [ ] consume unauthorized queues
- [ ] publish to unauthorized exchanges
- [ ] bypass resource limits

Add adversarial tests.

### T5.3 — Hostile-input testing
Investigate and test:
- [ ] oversized frames
- [ ] oversized messages
- [ ] invalid frame sequences
- [ ] invalid method sequences
- [ ] malformed headers
- [ ] invalid UTF-8 where relevant
- [ ] connection exhaustion
- [ ] channel exhaustion
- [ ] queue exhaustion
- [ ] consumer exhaustion
- [ ] rapid connect/disconnect
- [ ] partial frames
- [ ] truncated frames
- [ ] unexpected EOF
- [ ] invalid authentication
- [ ] authorization failures
- [ ] resource exhaustion

Establish: does hostile input leave the system in a valid semantic state?

### T5.4 — Gate 5 assessment
- [ ] Produce `docs/engineering/GATE_05_SECURITY_ISOLATION.md`
- [ ] No production-security claim without executable evidence
- [ ] Security matrix fully populated
- [ ] Adversarial tests pass

## Completion criteria

- [ ] Security audit matrix produced and populated
- [ ] Security semantic boundary verified with adversarial tests
- [ ] Hostile-input tests implemented and passing
- [ ] `GATE_05_SECURITY_ISOLATION.md` produced
- [ ] No regression in M1-M4 invariants

---

## Progress Report

```markdown
### Progress Report — M5 Security & Isolation + Gate 5

**Date:** [completion date]
**Commit:** [git revision]
**Status:** [COMPLETE | PARTIAL | BLOCKED]
**Gate verdict:** [PASS | FAIL | BLOCKED | NOT PROVEN]

**WHAT CHANGED:**
- [files created/modified]

**SECURITY MATRIX:**
- [capabilities: specified / implemented / tested / proven counts]

**ADVERSARIAL TESTS:**
- [boundary violations tested, results]

**HOSTILE INPUT TESTS:**
- [scenarios tested, pass/fail counts]

**HOSTILE INPUT STATE VALIDATION:**
- [does system remain valid after hostile input: YES/NO/partial]

**KNOWN GAPS:**
- [untested security capabilities]

**REGRESSION CHECK:**
- [M1 invariants: PASS/FAIL]
- [M2 ownership: PASS/FAIL]
- [M3 AMQP: PASS/FAIL]
- [M4 persistence: PASS/FAIL]
- [full test suite: PASS/FAIL]

**READY FOR NEXT MILESTONE?**
- [YES / NO — with reason]
```
