# Fuzzing

## Targets

1. frame decoder
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
