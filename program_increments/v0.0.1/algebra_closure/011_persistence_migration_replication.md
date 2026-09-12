# 011 — Persistence, Migration and Replication

## Persistence

Define:

`persist(S) -> P`

and:

`restore(P) -> S'`

Then define the required semantic preservation law.

## Persistence is not identity

A serialized representation is not the semantic entity.

## Migration

Define:

`migrate(S, A, B) -> S'`

where A/B represent semantic or physical execution contexts as appropriate.

Determine required invariants:

- identity;
- state;
- relationships;
- context;
- constraints;
- time;
- provenance;
- equivalence.

## Replication

Define:

`replicate(S) -> {S_i}`

and determine:

- replica identity;
- shared identity;
- consistency;
- divergence;
- convergence;
- causal history.

## Recovery

Define whether recovery is:

- restore;
- replay;
- reconstruction;
- re-execution.

These must not be conflated.

## Semantic continuity

Define when persistence/migration/replication preserves semantic continuity.

## Provider independence

A semantic state must remain semantically meaningful independently of the storage/runtime/provider chosen to manifest it.
