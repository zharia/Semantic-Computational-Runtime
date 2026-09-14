# M5: Fuzzing & Adversarial Testing

**Gate:** Part of Gate G
**Status:** PARTIAL — frame and stateful protocol fuzzers with deterministic
corpus are done; no dedicated field-table fuzz target and the 1M-iteration exit
bar was not reached (25k total).
**Spec:** Sections 32-37

## Sprint 5.1 — Coverage-Guided Fuzzing
- [x] Frame decoding fuzzer — `tests/phase10/frame_fuzz_test.mojo`,
  `tests/phase10/amqp_fuzz_test.mojo` (10000 codec + 10000 service = 20k)
- [ ] Field table fuzzer — **NOT DONE**: no dedicated target; field tables are
  exercised only indirectly (empty-props header frames + codec/service round-trips).
- [x] AMQP state transition fuzzer — `tests/phase10/stateful_fuzz_test.mojo`
- [x] Persistent / deterministic corpus — glibc LCG, reproducible seeds,
  crash-signature dedup

## Sprint 5.2 — Stateful Protocol Fuzzing
- [x] Sequence generator (CONNECT→OPEN→CHANNEL→DECLARE→PUBLISH→CONSUME→ACK→CLOSE)
- [x] Mutation strategies (bit_flip, byte_replace, truncate, duplicate, ordering)
- [x] Crash / deadlock / leak detection (process-survival assertions; 0 crashes)

## Exit Criteria
- [x] No crashes under 20k frame + 5000 stateful iterations
- [ ] No crashes under 1M fuzz iterations — not run (exit bar unmet)