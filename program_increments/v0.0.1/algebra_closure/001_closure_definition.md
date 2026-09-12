# 001 — Definition of Semantic Algebra Closure

## Closure criterion

The SCR semantic algebra is closed iff every semantically meaningful transition that SCR claims to support can be represented without introducing an undefined primitive, ambiguous operator, implicit implementation assumption, or untyped semantic side channel.

For every semantic primitive `X`, the closure record must contain:

- canonical definition;
- semantic type;
- domain;
- codomain;
- invariants;
- identity conditions;
- composition rules;
- validity conditions;
- failure/undefinedness conditions;
- temporal behaviour;
- contextual dependence;
- observation rules;
- equivalence rules;
- representation independence;
- interaction laws;
- Lean encoding;
- counterexample coverage.

## Strong closure condition

For any proposed behaviour `B`, one of the following must hold:

1. `B` is derivable from existing primitives and laws; or
2. `B` requires a new primitive, and that primitive is explicitly introduced, justified, typed, tested, and formalised.

There must be no third category:

> "The implementation will handle it somehow."

## Completeness versus consistency

Closure requires both:

### Consistency

No accepted definitions produce contradictory semantics.

### Expressive completeness

No required semantic behaviour falls outside the algebra.

The phase must actively search for both failures.

## Ambiguity classes

The following are closure failures:

- same term has multiple semantic definitions;
- semantic and physical meanings are conflated;
- domain/codomain is implicit;
- success and failure are observationally indistinguishable when they should differ;
- time behaviour is unspecified;
- context dependence is unspecified;
- nondeterminism is implicit;
- partiality is implicit;
- composition is undefined;
- equivalence is undefined;
- identity persistence is undefined;
- concurrency interaction is undefined;
- representation substitution has no law;
- manifestation is treated as semantic authority.

## Closure proof obligation

The final closure report must contain an inventory showing every primitive and every required semantic interaction has been classified as:

- proven;
- formally defined and machine-checked;
- derived;
- intentionally excluded with justification.

"Deferred" is not an accepted closure state for a core algebra question.
