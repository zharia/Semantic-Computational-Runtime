# 006 — Time, Ordering and Temporality

## Required distinction

SCR must explicitly distinguish semantic temporal concepts from physical clocks:

- semantic time;
- logical step;
- causal order;
- temporal order;
- wall-clock time;
- processing time;
- scheduling time;
- latency;
- frame time;
- event time;
- physical duration.

## Semantic time

Determine whether semantic time is:

- scalar;
- ordered set;
- partially ordered;
- vector;
- interval;
- event-indexed;
- context-dependent.

Do not assume a scalar counter is sufficient.

## Required laws

Determine and prove:

- reflexivity;
- transitivity;
- monotonicity where applicable;
- temporal composition;
- time preservation on failure;
- time progression on successful transformations;
- observation time semantics;
- concurrent event ordering.

## Rollback

Define whether rollback is:

- state restoration;
- temporal reversal;
- new forward state;
- history mutation.

Do not conflate these.

## Replay

Define semantic replay and whether replay must preserve:

- state;
- outcome;
- observations;
- identity;
- causality;
- semantic time.

## Temporal equivalence

Define when two executions with different physical durations are semantically equivalent.

Physical execution time must not silently become semantic time.
