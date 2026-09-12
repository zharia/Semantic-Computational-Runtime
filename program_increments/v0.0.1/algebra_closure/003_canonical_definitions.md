# 003 — Candidate Canonical Definitions

## Purpose

This document provides candidate definitions to be formally challenged. It is not permission to accept them without proof.

## Semantic Field

Candidate:

`F = (E, R, T, C, S, K, M)`

where:

- `E` entities;
- `R` relationships;
- `T` transformations;
- `C` context;
- `S` authoritative semantic state;
- `K` constraints;
- `M` manifestations.

Closure work must determine whether `M` belongs in the semantic field itself or is better represented as a projection/manifestation relation.

## Entity

Candidate:

An entity is a semantically identifiable participant with persistent identity within an explicitly defined semantic scope.

An entity is not its representation, address, process, object instance, memory region, or provider.

## Identity

Candidate:

Identity is a semantic persistence relation that determines when references at different states denote the same semantic entity.

Identity must not be defined merely as a string identifier.

## Value

Candidate:

A value is a semantically typed quantity whose machine representation is subordinate to its semantic contract.

## Relationship

Candidate:

A relationship is a semantic relation between entities/semantic objects, optionally typed and contextualised.

A pointer is not a relationship.

## State

Candidate:

State is the authoritative semantic condition against which valid transformations and observations are interpreted.

Implementation state may contain additional information.

## Context

Candidate:

Context is semantic information relevant to interpreting applicability, transformation, constraint, observation, or equivalence.

OS/process environment is not automatically semantic context.

## Constraint

Candidate:

A constraint is a predicate/relation restricting valid semantic configurations, transformations, or outcomes.

Closure must distinguish:

- invalid state;
- inapplicable transformation;
- rejected transformation;
- failed transformation.

## Transformation

Candidate:

A transformation is a semantic rule describing possible change from one valid semantic condition to another under context and constraints.

It must not be conflated with physical mutation.

## Outcome

Candidate:

An outcome is the semantic result of attempting a transformation.

A minimal candidate:

`Outcome(S) = Success(S') | Failure(F)`

The closure phase must determine whether additional outcome constructors are required.

## Observation

Candidate:

Observation is a semantic projection/read of authoritative state and context that does not mutate authoritative semantic state unless explicitly specified.

## Equivalence

Candidate:

Equivalence is context-sensitive where required and determines when two semantic states, behaviours, observations, or representations may substitute for one another under a stated contract.

## Representation

Candidate:

A representation is a physical or formal encoding of semantic structure.

Representation identity is not semantic identity.

## Manifestation

Candidate:

Manifestation is the physical realization/projection of semantic structure or behaviour.

Manifestation does not become semantic authority merely because it executes.
