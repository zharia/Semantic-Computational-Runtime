# M4: Transport & Protocol Resilience

**Gate:** Part of Gate G (Robustness)
**Status:** COMPLETE (core) — malformed/oversized/truncated/partial input, wrong
channel, premature close, reconnect and idle timeout covered; half-open and
wrong-method-in-wrong-state remain.
**Spec:** Sections 32-37

## Sprint 4.1 — Network Failure Tests
**Dir:** `tests/phase10/network_failure_test.mojo` (8 scenarios)
- [x] Abrupt disconnect test (header-only then disconnect, scenario 7)
- [ ] Half-open connection test — **NOT DONE**: no TCP half-open injection.
- [x] Partial frame test (partial method frame then teardown, scenario 6)
- [x] Oversized frame test (declared body far beyond ceiling, scenario 2)
- [x] Malformed frame test (garbage after protocol header, scenario 1)
- [x] Empty frame test (scenario 5)
- [x] Reconnect after failure (scenario 8)

## Sprint 4.2 — Protocol-State Resilience
- [ ] Wrong method in wrong state — **NOT DONE**: state-machine guard is
  exercised indirectly (R11) but no adversarial out-of-order method test.
- [x] Wrong channel (scenario 3)
- [x] Malformed frame handling (fail-closed, no crash)
- [x] Premature close (connection.close right after handshake, scenario 4)
- [x] Duplicate operation — `tests/phase10/stateful_fuzz_test.mojo` duplicate mutation
- [x] Connection idle timeout (enforced in event loop; `idle_timeout_secs`)

## Exit Criteria
- [x] All implemented transport tests pass
- [x] No crash under hostile/malformed input
- [ ] Half-open and out-of-sequence method coverage