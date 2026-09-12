# 019 — Implementation Freeze

## Rule

During semantic algebra closure, implementation expansion is frozen.

The purpose is to prevent semantic ambiguity from being encoded downstream.

## Permitted implementation changes

Only changes necessary to:

- support formal semantic counterexamples;
- expose existing semantic contradictions;
- validate formal definitions;
- maintain existing verification infrastructure;
- prevent repository drift.

## Prohibited expansion

Do not begin:

- new runtime subsystems;
- EGS implementation;
- provider implementations;
- distributed execution;
- GPU execution;
- production scheduling;
- persistence engines;
- Hyrx integration;
- optimisation work.

## Exception

A minimal executable witness may be created if it is necessary to falsify or validate a semantic proposition.

Such a witness must not become normative implementation architecture.

## Exit condition

Implementation work may resume only after:

1. semantic algebra closure gate passes;
2. Lean formalisation passes;
3. counterexample suite passes;
4. terminology audit passes;
5. closure manifest is generated;
6. repository documentation is reconciled;
7. an explicit downstream implementation mapping is derived from the closed algebra.

## Principle

Implementation should become a consequence of the algebra.

It must not become the source of the algebra.
