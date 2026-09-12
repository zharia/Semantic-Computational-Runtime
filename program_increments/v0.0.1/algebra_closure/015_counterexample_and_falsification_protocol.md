# 015 — Counterexample and Falsification Protocol

## Principle

A candidate semantic law is not accepted because it sounds reasonable.

It is subjected to attempted falsification.

## Required process

For every non-trivial definition/law:

1. state the proposition;
2. formalise the proposition;
3. identify hidden assumptions;
4. generate adversarial witnesses;
5. prove it if valid;
6. if false, classify the failure;
7. revise the model;
8. repeat.

## Failure classification

A counterexample must be classified as:

- definition failure;
- missing precondition;
- missing primitive;
- wrong codomain;
- wrong domain;
- invalid composition law;
- invalid equivalence assumption;
- implementation leakage;
- terminology collision;
- genuinely unsupported feature.

## Counterexample families

At minimum test:

- deterministic vs nondeterministic transition;
- success vs no-op;
- failure vs no-op;
- applicable vs inapplicable;
- valid vs invalid;
- concurrent independent transformations;
- conflicting transformations;
- representation substitution;
- identity under migration;
- identity under replication;
- observation under representation change;
- temporal reorder;
- causal reorder;
- persistence/restore;
- relationship creation/removal;
- context change;
- provider substitution;
- semantic versus physical location.

## Counterexample corpus

Every counterexample that changed the semantic model must become a permanent regression witness.

The final algebra must be tested not only by proving accepted laws but by retaining the historical examples that falsified earlier formulations.

## No proof by implementation

An implementation passing a test does not prove a semantic law.

Implementation tests may provide evidence, but semantic laws require formal reasoning at the semantic layer.
