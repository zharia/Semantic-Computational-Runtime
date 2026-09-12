# 000 — Scope and Authority

## Status

Normative closure-phase instruction.

## Objective

The next SCR phase shall close the semantic algebra at the abstract and conceptual levels before further runtime implementation expansion.

The governing principle is:

> **No semantic ambiguity may be delegated downstream to implementation.**

The phase must determine the smallest coherent algebra sufficient to express SCR's intended computational semantics while preserving separation between:

1. semantic ontology;
2. formal semantics;
3. implementation representation;
4. physical manifestation.

## Authority order

When definitions conflict, resolve them in this order:

1. explicitly accepted SCR semantic principles;
2. the closed semantic algebra produced by this phase;
3. machine-checked Lean formalisation of that algebra;
4. normative SCR specifications;
5. reference semantics;
6. implementation;
7. provider/runtime behaviour;
8. examples and prose.

Implementation convenience is never semantic authority.

## Explicit non-goals

This phase does not implement:

- EGS;
- providers;
- GPU execution;
- distributed runtime;
- production scheduling;
- storage engines;
- AMQP;
- rendering;
- performance optimisation.

Those systems may be used as **counterexamples or boundary requirements**, but they must not determine the core algebra.

## Closure boundary

The closure phase covers:

- identity;
- entities;
- values;
- relationships;
- state;
- context;
- constraints;
- applicability;
- admissibility;
- transformations;
- transitions;
- outcomes;
- failure;
- observation;
- equivalence;
- time;
- ordering;
- causality;
- concurrency;
- independence;
- composition;
- persistence;
- migration;
- replication;
- semantic space;
- representation;
- manifestation.

The phase must also identify any missing primitive discovered by formal counterexample.

## Required outcome

A single canonical semantic vocabulary and algebra must emerge.

Every core term must be:

- defined exactly once;
- classified;
- typed;
- composable;
- formally representable;
- tested against counterexamples;
- assigned explicit laws;
- connected to its observation/equivalence semantics.
