# HyrxMQ v0.0.3 — Full Production Readiness

## Mission

Turn every CONDITIONAL/PARTIAL gate from v0.0.2 into PASS. Fix correctness defects, harden security, add observability, validate persistence crash resilience.

Stop proving HyrxMQ can exist. Prove it can be trusted.

## Programme Increments from v0.0.2

v0.0.2 established:
- Semantic invariants (25 defined, 31 registry entries)
- Ownership/memory model (single-dest zero-copy proven)
- AMQP interoperability (Level A proven via pika 1.4.4)
- Persistence (WAL journal + recovery implemented)

v0.0.2 left:
- 10 open defects (D1-D15)
- No TLS, no authorization, no fuzz testing
- No metrics, no structured logging, no graceful shutdown
- No crash-at-controlled-point tests

## Non-negotiable principles

Same as v0.0.2:
- Semantic domains separated (Hyrx Core ≠ HyrxMQ ≠ AMQP ≠ TCP ≠ UDS)
- Single routing authority (Router inside HyrxEngine)
- MLIR-first policy
- Never allow implementation convenience to redefine computational semantics

## Milestones

| Milestone | Scope | Gate |
|-----------|-------|------|
| M0 | Baseline + stale assessment correction | — |
| M1 | Correctness defects (D14, D4, D5, D11, D15) + crash tests | Correctness Gate |
| M2 | Security: TLS + authorization + fuzz tests | Security Gate |
| M3 | Operations: metrics + logging + graceful shutdown | Operations Gate |
| M4 | Persistence: crash tests + corruption injection | Persistence Gate |
| M5 | Final integration + programme report | Final Assessment |

## Completion criteria

- All v0.0.2 defects resolved
- All gates PASS (no CONDITIONAL/PARTIAL)
- Full test suite PASS
- Documentation claims match implementation evidence
- Independent engineer can reproduce all evidence
