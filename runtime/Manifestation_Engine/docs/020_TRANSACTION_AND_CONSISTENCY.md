# Manifestation Engine — Transaction and Consistency Model

## 1. Purpose

Physical manifestation may involve multiple resources with different atomicity and durability properties. The Engine therefore needs explicit transaction and consistency semantics.

## 2. Semantic transaction

A semantic transaction is a contract governing a set of state transitions and effects.

It is not necessarily identical to a database transaction.

## 3. Atomicity

Atomicity is valid only where all affected manifestations can support the required atomic boundary or where a compensating protocol establishes an equivalent semantic guarantee.

## 4. Consistency

Consistency requirements may include:

- serializability;
- causal consistency;
- monotonicity;
- eventual consistency;
- snapshot semantics;
- application-specific invariants.

The semantic contract determines which is required.

## 5. Isolation

Isolation is distinct from security isolation. It concerns visibility and interference among concurrent semantic operations.

## 6. Durability

Durability is a semantic guarantee only when required by the contract. Otherwise it is a manifestation property.

## 7. Distributed transactions

The Engine MUST NOT assume a global transaction mechanism across arbitrary providers. It may instead use idempotency, compensation, sagas, version checks or explicit partial-commit semantics.

## 8. Conflict

Conflicts MUST be detected and exposed when concurrent manifestations violate semantic invariants.

## 9. Commit

Commit is the point at which semantic state transitions and declared effects become authoritative according to the contract.
