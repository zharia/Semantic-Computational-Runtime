# 004 — Operator and Outcome Algebra

## Required distinction

The closure phase must explicitly distinguish:

```text
Applicability
    ↓
Admissibility
    ↓
Transformation attempt
    ↓
Outcome
    ↓
Observation
```

These must not collapse into a single function returning a state.

## Candidate outcome algebra

Investigate:

```text
Outcome(S) =
    Success(S')
  | Failure(F)
  | Rejected(R)
  | Inapplicable(A)
  | Undefined(U)
```

Do not add constructors merely because they sound useful.

For every candidate constructor, construct a pair of cases that are:

- semantically distinct;
- observationally distinguishable;
- not representable by existing constructors.

If no such pair exists, the constructor may be derived rather than primitive.

## Failure semantics

The algebra must distinguish at least where required:

```text
successful no-op
constraint failure
invalid input
inapplicability
execution interruption
```

For each distinction define:

- state effect;
- time effect;
- context effect;
- observation;
- compositional behaviour.

## Partiality

Determine whether SCR uses:

- total functions returning outcomes;
- partial functions;
- relations;
- set-valued transitions.

The chosen model must represent nondeterminism without hidden implementation semantics.

## Nondeterminism

Candidate:

`T : Input -> Set Outcome`

or an equivalent typed relational model.

If nondeterminism is represented by sets, define:

- membership;
- admissibility;
- selection;
- observation;
- refinement;
- equivalence.

## Composition

For transformations `T1` and `T2`, define when:

`T2 ∘ T1`

exists and what happens when `T1` fails.

Failure propagation must be explicit.

## Applicability

Determine whether applicability is:

- a predicate;
- a relation;
- a set-valued condition;
- part of outcome;
- or a distinct semantic relation.

Formal counterexamples must decide this.
