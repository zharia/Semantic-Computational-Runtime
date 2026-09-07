# Manifestation Engine — Validation and Conformance

## 1. Validation layers

Validation MUST occur at multiple levels.

### Semantic validation
Does the graph define a valid semantic computation?

### Capability validation
Can the required capabilities be satisfied?

### Provider validation
Does the provider satisfy the capability contract?

### Manifestation validation
Is the selected physical realization valid for the current context?

### Execution validation
Did the execution produce the required semantic result?

### Operational validation
Were lifecycle, resource, security and observability requirements satisfied?

## 2. Core conformance suite

The Engine SHOULD test:

1. provider substitution;
2. data remapping;
3. messaging remapping;
4. CPU/GPU substitution;
5. restart;
6. provider failure;
7. resource exhaustion;
8. cancellation;
9. retry/idempotency;
10. deterministic replay;
11. provenance;
12. authorization denial;
13. isolation;
14. migration;
15. consistency conflicts.

## 3. Semantic equivalence

Every optimization or provider substitution that changes physical realization MUST be checked against the relevant semantic contract.

## 4. Negative tests

The suite MUST include cases where:

- capability is missing;
- provider is unauthorized;
- provider lies about capability;
- resource limits are exceeded;
- data manifestation is stale;
- transport ordering is insufficient;
- a retry would duplicate an effect;
- semantic constraints are violated.

## 5. Traceability

Every normative invariant SHOULD map to at least one automated test or a documented reason why automated testing is not yet possible.

## 6. Differential execution

The Reference Executor should serve as a baseline for semantic computations where applicable.

## 7. Performance validation

Performance MUST NOT be treated as evidence of semantic correctness. Benchmarking is separate from conformance.

## 8. Security validation

Security testing MUST include unauthorized capability requests, provider escape attempts, cross-context access and resource exhaustion.

## 9. Conformance statement

A release SHOULD publish:

- supported capability contracts;
- provider matrix;
- known limitations;
- semantic equivalence evidence;
- test results;
- unresolved deviations.
