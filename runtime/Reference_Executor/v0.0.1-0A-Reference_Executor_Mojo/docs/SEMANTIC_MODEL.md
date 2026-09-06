# Bootstrap Semantic Model

The bootstrap field is:

\[
F_0 = (E,R,T,S,K)
\]

where:

- E = entities
- R = relationships
- T = transformations
- S = execution state
- K = constraints

Observations and traces are execution manifestations of this model.

## Semantic identity

An entity has an explicit identifier.

## State

State is the collection of semantic property values attached to entities plus the topology represented by relationships.

## Transformation

A transformation is an intentional transition from one semantic state to another.

## Constraint

A constraint determines whether a candidate state may be committed.

## Observation

An observation exposes semantic state without changing it.

## Trace

A trace records the semantic transition for reproducibility and conformance analysis.

This is intentionally smaller than the complete SCR Semantic Field model. 0A exists to make the minimum executable semantics concrete while the full library is built.
