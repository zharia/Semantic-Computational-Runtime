# 0A Reference Conformance Contract

A future SCR execution provider should be tested against these semantic expectations.

## Identity

Entity identity remains stable across transformations.

## Relationships

Relationships remain unchanged unless a transformation explicitly changes topology.

## Transformation

A successful state transformation:

1. operates on candidate state;
2. validates the candidate;
3. commits the candidate;
4. advances logical time exactly once;
5. records a trace event.

## Rollback

A failed transformation:

- raises an error;
- does not change committed semantic state;
- does not advance logical time;
- does not append a successful transformation trace event.

## Observation

Observation:

- reads committed semantic state;
- does not mutate state;
- does not advance logical time.

## Determinism

Repeated executions from equivalent initial fields using equivalent transformations produce equivalent semantic outcomes.

## Future providers

Native, Wasm, GPU, distributed and specialized providers should consume this conformance contract rather than independently defining semantic behaviour.
