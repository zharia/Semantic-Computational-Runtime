# 007 — Causality, Concurrency and Independence

## Causality

Define the causal relation:

`a -> b`

and determine whether it is:

- transitive;
- acyclic;
- antisymmetric;
- contextual;
- state-dependent.

Do not assume temporal order implies causality.

## Independence

Define semantic independence separately from:

- physical parallelism;
- process isolation;
- memory separation;
- scheduling independence.

Candidate:

Two transformations are independent if execution of one does not alter the semantic validity/outcome of the other under the stated context.

This must be formally refined.

## Commutativity

For applicable transformations:

`T1(T2(S)) ≡ T2(T1(S))`

is a possible commutativity law.

Determine exact preconditions.

## Conflict

Define when two transformations conflict.

Possible categories:

- state conflict;
- constraint conflict;
- identity conflict;
- relationship conflict;
- temporal conflict;
- resource conflict.

Physical resource contention must not automatically become semantic conflict.

## Concurrency

Define concurrency independently of implementation threads.

Determine:

- concurrent transformations;
- partially ordered transformations;
- serialisable transformations;
- commutative transformations;
- mergeable transformations;
- irreconcilable transformations.

## Merge

If merge exists, define:

`merge(S1,S2) -> S3`

and its validity/equivalence laws.

## Causal footprint

Treat footprint-based causality as a hypothesis until formally justified.

Counterexamples must test whether identical footprint overlap is sufficient, necessary, neither, or context-dependent.
