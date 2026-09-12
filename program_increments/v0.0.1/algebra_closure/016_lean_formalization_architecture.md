# 016 — Lean Formalisation Architecture

## Purpose

Lean is the formal authority for the accepted semantic algebra.

Lean must not become a second runtime.

## Required layering

Candidate target:

```text
SCR.Semantics
├── Identity
├── Entity
├── Value
├── Relationship
├── State
├── Context
├── Constraint
├── Applicability
├── Transformation
├── Outcome
├── Observation
├── Equivalence
├── Time
├── Causality
├── Concurrency
├── Space
├── Persistence
└── Representation
```

The actual namespace/module structure may differ if justified.

## One semantic definition

Where possible, there should be one canonical Lean definition for each semantic primitive.

Avoid duplicate definitions that differ only by module history.

## Theorem classes

At minimum:

- well-formedness;
- identity preservation;
- representation independence;
- observation purity;
- constraint semantics;
- outcome semantics;
- composition;
- temporal laws;
- causality laws;
- concurrency/independence;
- equivalence;
- persistence;
- migration;
- replication;
- manifestation refinement.

## Computational counterexamples

Counterexamples must compile and remain as executable/formal regression witnesses.

## Extraction

Do not prematurely generate runtime code from Lean.

The purpose is semantic verification and executable specification, not replacing Mojo.

## Formal coverage

The closure gate must report:

- primitive definitions;
- laws;
- theorems;
- counterexamples;
- unresolved conjectures.

No core concept may be marked "formalised" merely because a similarly named structure exists.
