# ADR-0001 — Phase 0 Scope

## Status

Accepted seed decision.

## Decision

Phase 0 establishes repository, toolchain, quality, determinism, benchmarking,
documentation, and deployment groundwork only.

## Rationale

Hyrx is intended to be a native messaging engine rather than an AMQP server
retrofit. The project therefore needs a stable engineering substrate before
semantic implementation begins.

## Consequences

Positive:
- prevents protocol implementation from becoming the architecture;
- enables reproducible experiments;
- makes ownership/performance assumptions explicit;
- reduces speculative dependencies.

Negative:
- Phase 0 produces little visible broker functionality.

That trade-off is intentional.
