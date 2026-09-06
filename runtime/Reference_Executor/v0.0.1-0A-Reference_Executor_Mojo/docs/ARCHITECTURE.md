# 0A Reference Semantic Executor Architecture

## Purpose

The Reference Semantic Executor is the smallest useful executable realization of the SCR semantic execution model.

It establishes:

\[
S_t \xrightarrow{T} S_{t+1}
\]

where a semantic transformation is applied to a candidate state, validated, and either committed or rejected.

## Semantic components

### Semantic Field

The field contains semantic entities, relationships and constraints.

### Entity

An entity has:

- semantic identity
- semantic kind
- named semantic properties

Entity identity is independent of physical memory location and container position.

### Value

The bootstrap value domain is intentionally small:

- Int
- Float64
- Bool
- String

These are implementation representations of a provisional semantic value model, not the final SCR numeric/type system.

### Relationship

A relationship connects semantic entities through a named relation.

### Constraint

A constraint expresses an invariant over semantic state.

### Transformation

A transformation is an explicit state transition.

### Observation

An observation reads semantic state without mutating it.

### Execution trace

Every committed transformation records:

- logical step
- operation
- target
- property
- previous value
- resulting value

## Transactional semantics

Execution uses candidate-state semantics:

```text
committed state
      │
      ▼
candidate copy
      │
      ▼
transformation
      │
      ▼
constraint validation
   ┌──┴──┐
 fail   pass
  │       │
  │       ▼
  │     commit
  │
 rollback
```

A failed transformation therefore cannot partially mutate committed state.

## Mojo ownership

The implementation intentionally uses Mojo 1.0's explicit value semantics.

SCR entities and fields contain collections and therefore are **explicitly copyable**, not implicitly copyable.

Copies use `.copy()`.

Moves use `^`.

This is important: accidental implicit copying would hide potentially significant semantic/runtime costs. Mojo 1.0 explicitly distinguishes `Copyable` from `ImplicitlyCopyable`.

## Logical time

Logical execution time advances only when a state-changing transformation commits.

Observations do not advance logical time.

## Determinism

Given the same initial field and same transformation sequence, the reference executor must produce the same:

- committed state
- logical step
- observations
- trace

## Representation independence

The semantic model is not defined by:

- Mojo struct layout
- Dict layout
- List allocation
- memory address
- object address
- hash-table position

These are implementation mechanisms.
