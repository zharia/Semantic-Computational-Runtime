# Quality Gates

## Gate Q0 — Build Integrity

Required:

- clean build
- no unexplained compiler warnings
- deterministic dependency resolution
- CI green

## Gate Q1 — Core Correctness

Required:

- unit tests
- ownership/lifetime tests
- concurrency tests
- resource-bound tests

## Gate Q2 — Semantic Correctness

Required:

- routing tests
- delivery tests
- acknowledgement tests
- ordering tests
- backpressure tests

## Gate Q3 — Transport Conformance

Every transport must pass the applicable semantic conformance suite.

## Gate Q4 — Protocol Conformance

Every implemented AMQP method/state transition has positive and negative tests.

## Gate Q5 — Compatibility

No compatibility claim without automated evidence and real client tests.

## Gate Q6 — Persistence

Crash/recovery suite passes.

## Gate Q7 — Security

Fuzzing and hostile-input tests pass; no known release-blocking vulnerability.

## Gate Q8 — Performance

Benchmark results are reproducible and show no unacceptable regression.

## Gate Q9 — Operational

systemd, configuration, health, management API, CLI, UI, logs, and metrics work together.

## Gate Q10 — Release

All mandatory requirements satisfied; all known exceptions documented; no hidden scope.

## Automatic release blockers

- data corruption
- message loss contrary to documented semantics
- incorrect acknowledgement behavior
- protocol state corruption
- crash from malformed input
- uncontrolled memory growth
- unreproducible benchmark claims
- undocumented compatibility gaps
- systemd startup/recovery failure
