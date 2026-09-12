# 009 — Observation and Equivalence

## Observation

Candidate:

`observe(S, q, C) -> (S, O)`

The observation must not mutate authoritative state unless the semantic contract explicitly defines a mutating observation.

## Observation classes

Investigate:

- direct observation;
- projected observation;
- derived observation;
- historical observation;
- contextual observation;
- partial observation.

Only promote distinctions to primitives if formal counterexamples require them.

## Observation consistency

Define whether observation is:

- instantaneous;
- versioned;
- causally consistent;
- snapshot-consistent;
- eventually consistent.

## Equality versus equivalence

Separate:

`=`

from:

`≡`

and contextual/observational equivalence.

Candidate relations:

- identity equality;
- structural equality;
- semantic equivalence;
- behavioural equivalence;
- observational equivalence;
- contextual equivalence;
- representation equivalence.

## Equivalence laws

For each accepted equivalence relation, prove the required:

- reflexivity;
- symmetry;
- transitivity.

For substitutive equivalence, prove congruence under the applicable operators.

## Contextual equivalence

Define:

`x ≡_C y`

where required.

Determine whether context is explicit in the equivalence relation.

## Representation equivalence

Two physical states may be equivalent if they produce equivalent semantic observations/outcomes under the specified contract.

This must become a formal bridge to implementation correctness.
