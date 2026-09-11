# Fuzzing

## Implementation status (v0.0.3)

`tests/phase10/frame_fuzz_test.mojo` exercises target (1) the frame decoder with a
deterministic xorshift64 corpus (1000 random byte sequences) plus 8 targeted
malformed inputs (empty, truncated header/body, huge declared length, bad frame
type, truncated method args, zero-length). Every malformed input either raises a
catchable error or yields a safe result — no crash, no fabricated frame, and the
buffered bytes stay within `frame_limit() + 8`.

Targets (2)-(8) are not yet fuzzed.

## Targets

1. frame decoder — **FUZZED** (phase10)
2. AMQP field decoder
3. AMQP method state machine
4. routing key/parser logic
5. configuration parser
6. management API
7. persistence record decoder
8. transport framing

## Requirements

Fuzzers must be:

- deterministic/reproducible where possible
- timeout-bounded
- memory-bounded
- crash-detecting
- corpus-preserving

Any crash, hang, assertion failure, memory safety failure, or state corruption is a release blocker until triaged.
