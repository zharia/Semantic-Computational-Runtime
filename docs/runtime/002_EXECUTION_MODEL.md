# Semantic Execution Model

## 1. Execution as field evolution

SCR execution is the controlled evolution of semantic state and topology.

\[
\mathcal{F}_t \xrightarrow{T} \mathcal{F}_{t+1}
\]

A program is a semantic substructure selecting transformations and constraints within the field.

## 2. Execution stages

```text
Discover
 → Validate
 → Plan
 → Select representation
 → Select providers
 → Schedule
 → Execute
 → Observe
 → Commit/evolve field
```

These stages are logical; an implementation may fuse them.

## 3. Scheduling

Scheduling is a resource realisation problem constrained by semantic dependencies, ordering requirements, isolation, deadlines, locality and determinism.

## 4. State

State is semantic when changes affect subsequent valid transformations or observations. Caches and other physical state remain non-semantic unless exposed by contract.

## 5. Transactions

Where required, field transformations MAY use transactional, speculative, staged or rollback-capable execution.

## 6. Observation

Observation projects semantic state into an observable representation. Observability MUST be explicit where it influences correctness.
