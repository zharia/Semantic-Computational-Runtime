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

Every completion claim must distinguish:

- `PROVEN`
- `PARTIALLY PROVEN`
- `NOT PROVEN`
- `BLOCKED`

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
