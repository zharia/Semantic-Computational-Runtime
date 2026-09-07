# Manifestation Engine — Lifecycle and Supervision

## 1. Lifecycle

The Engine SHOULD model at least:

`Discovered → Validated → Prepared → Active → Suspended → Resumed → Released`

with exceptional states:

`Failed`, `Recovering`, `Degraded`, `Quarantined`.

## 2. Preparation

Preparation may include provider selection, compilation, allocation, data materialization and communication setup.

Preparation MUST NOT mutate semantic state unless the contract explicitly permits preparation effects.

## 3. Activation

Activation makes a manifestation eligible for execution.

## 4. Suspension

Suspension releases or parks physical resources while preserving sufficient state for semantic resumption where supported.

## 5. Supervision

The supervisor monitors:

- health;
- liveness;
- resource use;
- provider failures;
- contract violations;
- queue/backpressure state;
- security events.

## 6. Recovery

Recovery policy MUST classify whether state can be resumed, reconstructed, replayed, compensated or must be abandoned.

## 7. Migration

Migration MAY move a semantic workload between manifestations/providers. Semantic identity and required state MUST remain stable.

## 8. Termination

Termination releases physical resources. Semantic state survives unless destruction is part of the requested operation.

## 9. Restart

Restart MUST distinguish process restart from semantic state restart. A provider process can die while semantic state remains valid and recoverable.
