# Testing Strategy

## Phase 0

Phase 0 proves repository/toolchain integrity.

Required tests:

- repository structure;
- deterministic seed configuration;
- minimal Mojo executable;
- formatting;
- CI bootstrap;
- script failure behavior.

## Later test classes

```text
unit
component
integration
protocol conformance
RabbitMQ differential
fuzz
stress
concurrency
fault injection
persistence recovery
soak
security
performance
management
systemd/operations
```

## Failure policy

The following are release blockers unless explicitly accepted:

- data corruption;
- unintended message loss;
- incorrect acknowledgement semantics;
- protocol-state corruption;
- crash on malformed input;
- uncontrolled memory growth;
- resource exhaustion without defined behavior;
- undocumented compatibility gap;
- false performance claim;
- systemd startup/recovery failure.

## Test evidence

Tests must record:

- command;
- source revision;
- environment;
- expected result;
- actual result;
- artifact/log location;
- pass/fail;
- known limitations.
