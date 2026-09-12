# 008 — Identity, Entity and Relationship Algebra

## Identity

Identity must be defined as a semantic relation across states.

Investigate:

- creation;
- persistence;
- destruction;
- reconstruction;
- migration;
- replication;
- splitting;
- merging;
- aliasing.

Do not equate identity with a UUID/string unless the semantic model proves that this is sufficient.

## Entity

Define whether an entity is:

- primitive;
- typed semantic object;
- identity-bearing participant;
- graph node;
- state-bearing object.

Resolve Entity versus EntityDefinition formally.

## Relationship

Define:

`R(source, target, kind, context, validity)`

as appropriate.

Determine whether relationships can be:

- directed;
- symmetric;
- reflexive;
- transitive;
- temporal;
- contextual;
- weighted;
- typed.

Do not add algebraic properties without proof.

## Relationship transformation

Define how transformations may:

- create;
- remove;
- alter;
- preserve;
- invalidate relationships.

## Identity preservation law

A transformation that changes representation must not change semantic identity unless explicitly specified.

## Identity under migration

Define whether:

`identity(S) = identity(migrate(S,A,B))`

and prove the intended law.

## Identity under replication

Define whether replicas:

- share identity;
- represent related states;
- are distinct semantic entities.

This must be explicit before distributed implementation.
