# ADR-0004 — Performance Evidence

## Status

Accepted seed decision.

## Decision

No arbitrary throughput or latency target is declared before a reproducible
baseline exists.

## Required sequence

```text
correct direct path
    ↓
measure
    ↓
identify bottleneck
    ↓
optimize
    ↓
measure again
    ↓
retain only justified optimization
```

This prevents benchmark-driven architecture from becoming detached from actual
messaging semantics.
