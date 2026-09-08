# Quality Gates

Every phase follows:

```text
IMPLEMENT
  ↓
UNIT TEST
  ↓
INTEGRATION TEST
  ↓
COMPATIBILITY TEST
  ↓
BENCHMARK
  ↓
DOCUMENT
  ↓
REVIEW
  ↓
EXIT GATE
```

Not every stage is applicable to every phase, but the agent must explicitly mark
non-applicable stages.

## Evidence rule

Every completion claim must distinguish, per audit §27 (these are distinct
states — do not collapse them):

- `IMPLEMENTED` — the code exists.
- `TESTED` — a runtime-checked test exercises it (a bare `assert` that cannot
  fail a build does **not** count).
- `FUNCTIONALLY PROVEN` — round-trips through our own codec / our own test
  client are self-consistent in-repo; does **not** imply wire-spec conformance.
- `BENCHMARKED` — measured with actual runs on the recorded environment.
- `INTEROPERABILITY PROVEN` — a real third-party client completes the protocol
  (handshake included) against a pinned reference.
- `NOT PROVEN` — evidence absent or the path is blocked.
- `PARTIALLY PROVEN` / `BLOCKED` — partial evidence, or a documented stop.

A round-trip through our own codec is at most `FUNCTIONALLY PROVEN`; only a
real client reaching the methods makes it `INTEROPERABILITY PROVEN`. Do not use
`complete`/`PROVEN` where only `IMPLEMENTED` or `FUNCTIONALLY PROVEN` holds.

## Phase 0 gate

### Architecture
- [ ] Core/product boundary documented.
- [ ] Transport independence documented.
- [ ] AMQP boundary documented.
- [ ] Simulation independence documented.

### Toolchain
- [ ] GNU/Linux baseline captured.
- [ ] Mojo version captured.
- [ ] Minimal program compiles.
- [ ] Minimal executable runs.
- [ ] Formatting command verified.

### Repository
- [ ] Required directories exist.
- [ ] Dependency policy exists.
- [ ] Deterministic seed exists.
- [ ] Benchmark schema exists.
- [ ] CI seed exists.
- [ ] systemd packaging seed exists.

### Evidence
- [ ] No unsupported claims.
- [ ] Unknowns recorded.
- [ ] Exit report generated.

Phase 0 must not be promoted merely because the scaffold exists.
