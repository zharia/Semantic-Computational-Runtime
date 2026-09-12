# 012 — Values, Numeric Semantics and Representation

## Value

A value is semantic before it is encoded.

Define:

- type;
- domain;
- unit;
- dimension;
- precision;
- accuracy;
- admissible error;
- range;
- special values;
- rounding;
- determinism.

## Numeric representation

Machine types such as:

- i32;
- i64;
- f32;
- f64;

are representations unless the semantic contract explicitly makes representation part of meaning.

## Conversion

Define semantic conversion separately from bit-level casting.

## Quantisation

Determine whether quantisation is:

- representation;
- semantic transformation;
- approximation;
- constraint violation.

## Determinism

Define semantic determinism independently of implementation determinism.

For reductions, define whether order is semantic.

## Representation independence

Let:

`pi : IState -> S`

be a semantic projection where appropriate.

The closure phase must establish when:

`pi(I1) ≡ pi(I2)`

and when implementation transformations preserve:

`pi(TI(I)) ≡ TS(pi(I))`.

## Strings and identity

A string representation must not automatically be treated as semantic identity.

## Numeric time

A machine `index` or integer is not automatically SemanticTime.
