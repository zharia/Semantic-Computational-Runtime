# Research: Semantic Hypergraphs

SCR's semantic architecture naturally motivates a typed, attributed, temporal, role-labelled hypergraph.

This is a research direction rather than a claim of a finished graph engine.

## Why a hypergraph?

Ordinary graphs model pairwise relationships well.

Computational semantics often requires relationships involving:

- multiple participants;
- roles;
- regions;
- operations;
- events;
- state;
- provenance;
- temporal relationships;
- causal relationships.

A hypergraph can represent these structures directly.

## Proposed semantic foundation

A useful conceptual foundation is:

> An identity-addressed, typed semantic hypergraph whose state is constructed from immutable graph fragments and an ordered or causally related stream of semantic operations.

## Identity classes

The architecture distinguishes concepts such as:

- semantic identity;
- graph-region identity;
- content identity;
- operation identity.

References should not require direct embedding of arbitrary physical storage addresses.

## Operations and deltas

Operations are first-class semantic objects.

Deltas may represent state differences or optimized mutation batches.

A conceptual progression is:

```text
Semantic Delta
      ↓
Graph Delta
      ↓
Representation Delta
      ↓
Storage Delta
```

Each lower layer can optimize realization without redefining the semantic operation.

## Streams and messaging

A semantic stream can carry operations or graph-state transitions.

AMQP can provide a transport/provider mechanism.

It should not become the semantic definition of the stream.

## Queries and interoperability

A query language such as GQL may serve as a query/projection interface.

RDF and JSON-LD can provide interoperability projections where appropriate.

These mechanisms are representations and interfaces, not necessarily the semantic authority.

## Open questions

Research includes:

- graph-state semantics;
- ordering;
- causal consistency;
- incremental recomputation;
- subscriptions;
- references;
- snapshots;
- persistence;
- query semantics;
- distributed mutation;
- provenance;
- checkpointing.

CRDT semantics should be introduced only when their semantic requirements are properly defined rather than assumed by the storage mechanism.
