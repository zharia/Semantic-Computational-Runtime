# Phase 0 — Repository and Toolchain

## Purpose

Establish the engineering substrate for Hyrx before implementing messaging
semantics.

## Required outcomes

### Repository
- stable repository layout;
- documented architecture boundaries;
- deterministic configuration seed;
- explicit dependency policy;
- executable development scripts.

### Toolchain
- GNU/Linux environment identified;
- approved Mojo toolchain identified;
- compiler invocation verified;
- formatting invocation verified;
- sanitizer/debug options investigated;
- build/test commands recorded.

### Quality infrastructure
- repository checks;
- minimal executable test;
- CI seed;
- benchmark result schema;
- deterministic seed/configuration;
- systemd packaging seed;
- documentation skeleton.

## Phase 0 must NOT

- implement AMQP;
- introduce network code;
- define queues/exchanges;
- implement routing;
- add persistence;
- add simulation-specific abstractions;
- introduce clustering;
- optimize without a benchmark.

## Verification sequence

```text
fresh checkout
    ↓
environment inspection
    ↓
structure validation
    ↓
Mojo version capture
    ↓
seed compilation
    ↓
seed test execution
    ↓
format validation
    ↓
CI validation
    ↓
documentation/review
    ↓
Phase 0 exit gate
```

## Exit gate

Phase 0 can be promoted only when:

- all required repository files exist;
- the selected Mojo environment is explicitly recorded;
- the minimal program compiles and runs;
- the minimal test executes;
- formatting succeeds;
- CI succeeds in the supported environment;
- no unexplained dependency has been introduced;
- architecture invariants are accepted;
- known unknowns are recorded;
- no Phase 1 functionality has leaked into Phase 0.

A missing tool is not a pass. Record `NOT PROVEN`.
