# 002 — Semantic Primitive Inventory

## Candidate core inventory

The closure phase must audit and either accept, merge, derive, or reject each of these concepts:

### Ontological primitives

- Identity
- Entity
- Value
- Relationship
- State
- Context

### Computational primitives

- Transformation
- Transition
- Constraint
- Applicability
- Admissibility
- Outcome
- Observation

### Structural/meta-semantic primitives

- Equivalence
- Causality
- Ordering
- Independence
- Composition
- Provenance
- History/version
- Semantic space

### Continuity/manifestation concepts

- Persistence
- Migration
- Replication
- Representation
- Manifestation

## Required classification

Each term must be classified as exactly one of:

- primitive;
- derived concept;
- relation;
- operator;
- predicate;
- type constructor;
- meta-property;
- manifestation concept.

If two terms are semantically equivalent, they must be unified or one explicitly declared an alias.

If two terms appear equivalent but differ in scope, the difference must be stated formally.

## Required audit

Search the complete repository for all uses of each term.

For each use, determine:

- intended meaning;
- type;
- layer;
- whether it matches the canonical definition.

The closure phase must identify terminology drift between:

- seed;
- docs;
- Lean;
- STC;
- SMM;
- Golden Path;
- Reference Executor;
- Mojo;
- MLIR;
- runtime;
- EGS.

## Candidate reductions to investigate

The following are hypotheses, not assumptions:

- Entity may be the concrete semantic participant while EntityDefinition is schema.
- Transition may be the semantic event/result relation while Transformation may denote the rule/operator.
- Outcome may be a typed semantic result rather than an exceptional control mechanism.
- Applicability may be a predicate/relation independent of outcome.
- Observation may be a semantic projection.
- Semantic Field may be a structured state/context topology rather than a primitive independent of its contents.
- Provenance may be a semantic/meta-semantic relation rather than part of core state.

Every such hypothesis must be formally tested.
