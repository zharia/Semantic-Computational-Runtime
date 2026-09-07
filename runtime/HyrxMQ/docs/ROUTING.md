# Routing

## Goal

Routing should be fast, deterministic, and semantically compatible with supported AMQP behavior.

## Internal routing model

The internal routing engine should be independent of AMQP method frames.

It may use compact IDs and specialized indexes.

## Required routing concepts

- direct routing
- topic-style routing as required by AMQP exchange types
- fanout
- headers
- bindings
- routing keys
- alternate exchanges
- exchange-to-exchange bindings where supported

## Optimization candidates

- immutable routing snapshots
- compact IDs
- precomputed binding indexes
- specialized matchers
- copy-on-write topology updates
- batching
- cache-aware structures

## Correctness requirement

A routing optimization is unacceptable if it changes:

- matching semantics
- ordering
- duplication behavior
- mandatory return behavior
- alternate exchange behavior
- failure handling

## Routing benchmark suite

Measure:

- one binding
- many bindings
- no match
- one match
- many matches
- wildcard-heavy topic routing
- headers-heavy routing
- topology mutation under load
- hot exchange
- many exchanges
