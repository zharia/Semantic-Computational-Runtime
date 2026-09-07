# Manifestation Engine — Failure and Recovery

## 1. Failure taxonomy

Failures SHOULD be classified as:

- invalid semantic definition;
- violated precondition;
- missing capability;
- authorization denial;
- provider unavailable;
- provider contract violation;
- resource exhaustion;
- timeout/deadline;
- transport failure;
- data freshness/conflict failure;
- physical execution failure;
- cancellation;
- internal Engine failure;
- unrecoverable state corruption.

## 2. Failure propagation

A physical failure MUST be translated into a semantic execution outcome when it can affect semantic correctness.

## 3. Retry

Retries are valid only when the operation is idempotent or when the Engine has a mechanism to preserve semantic effect identity.

## 4. Compensation

For non-atomic external effects, compensation may be required. Compensation semantics MUST be explicit; rollback cannot be assumed for arbitrary physical effects.

## 5. Partial completion

Distributed execution may produce partial physical effects. The Engine MUST report whether semantic state is committed, partially committed, rolled back, compensated or unknown.

## 6. Unknown outcome

An ambiguous physical outcome MUST remain distinguishable from failure. For example, a timed-out network request may have succeeded remotely.

## 7. Recovery strategies

Potential strategies:

- retry;
- replay;
- resume from checkpoint;
- failover provider;
- migrate manifestation;
- compensate;
- quarantine;
- require operator intervention.

## 8. Recovery safety

Recovery MUST preserve semantic identity, effect identity and applicable ordering/consistency guarantees.
