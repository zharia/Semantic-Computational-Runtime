# Development Agent Instruction — STC Graph-Relational Refinement

## Mission

Perform a semantic refinement increment in the Semantic Computational Runtime repository. **Do not start STC-002.**

Determine whether the Semantic Transition Calculus should be based on a typed graph relation from semantic input to semantic output:

\[
I\xrightarrow{\tau}O
\]

with general relational form:

\[
R_\tau\subseteq I_\tau\times O_\tau.
\]

This is a hypothesis to falsify, not an architecture to impose.

## Inspect first

Read the actual repository before editing:

- `docs/101_BACKGROUND.md`
- `docs/102_ARCHITECTURE.md`
- `docs/103_SEMANTIC_MODEL.md`
- `docs/104_SEMANTIC_INVARIANTS.md`
- `docs/106_SEMANTIC_MACHINE_MODEL.md`
- `docs/107_SEMANTIC_TRANSITION_CALCULUS.md`
- `docs/109_SMM_LIBRARY_CROSSWALK.md`
- `docs/110_SMM_REPOSITORY_UPDATE.md`
- `docs/111_SMM_TERMINOLOGY_AND_DECISIONS.md`
- `SCRFormal/SCR/Basic.lean`
- `State.lean`
- `Relationship.lean`
- `Transformation.lean`
- `Equivalence.lean`
- `Invariants.lean`
- `STC.lean`
- `STCCounterexamples.lean`
- `STCExamples.lean`

Do not infer semantics from names.

## Hard constraints

Do not:
- begin STC-002;
- add abstractions just to make Lean compile;
- create a parallel ontology;
- redefine existing State, Transformation, Delta, Relationship, Hypergraph, Observation or Equivalence without a counterexample;
- introduce runtime, scheduler, processor, thread, process, storage, provider, EGS, MLIR or Mojo semantics;
- equate physical resource contention with semantic dependency;
- assume `ResultState`, `OutcomeOf`, `Footprint`, or `causalDependent := ¬ independent` are permanent.

If a proposed abstraction can be eliminated, eliminate it.

## Formal work

Create `SCRFormal/SCR/STCGraphCounterexamples.lean`.

Implement and document at least these counterexamples:

1. identical outcome / different successor state;
2. equivalent outcomes / distinguishable successor state;
3. distinguishable outcomes / equivalent successor state;
4. different transformations / same endpoints;
5. representation difference / semantic equivalence;
6. nondeterministic branching;
7. admissible partial input;
8. semantic failure with state change;
9. no-op;
10. relational composition;
11. associativity;
12. conditional branching;
13. independent edges;
14. non-commuting edges;
15. causal dependency without physical ordering;
16. temporal ordering without causality;
17. causality without wall-clock ordering;
18. state observation;
19. edge observation;
20. provenance.

Do not weaken a counterexample because the current ontology cannot express it. That inability is part of the evidence.

## Key investigations

### ResultState

Compare:
- STC-001 `OutcomeOf + ResultState`;
- a transition-result relation;
- a typed input-to-output graph relation.

Determine the minimum expressive model.

### OutcomeOf

Determine whether outcome is genuinely primitive or a projection over transition results.

### Delta

Audit the existing Core Delta concept. Determine whether it is the semantic edge, edge payload, endpoint difference, derived structure, or another construct.

### Determinism

Compare outcome, successor-state, endpoint, transition-result, and observational determinism.

### Partiality/failure

Determine whether they are missing edges, typed consequences, incomplete transitions, or derived classifications.

### Composition

Test relational graph composition and semantic associativity.

### Observation/equivalence

Test observations of outcomes, states, edges, endpoints and paths. Keep observation context-indexed.

### Independence/causality

Separate semantic independence, read/write/influence/observation footprint, causal dependency, conflict and temporal ordering. Do not define causality as merely non-independence without a counterexample-driven justification.

## Documentation

Create `docs/112_STC_GRAPH_RELATIONAL_REFINEMENT.md`.

Update `docs/107_SEMANTIC_TRANSITION_CALCULUS.md` minimally:
- retain valid STC-001 results;
- mark the graph-relational transition hypothesis as unresolved;
- mark STC-002 as blocked;
- do not silently redefine the kernel.

Update `docs/109_SMM_LIBRARY_CROSSWALK.md` to reflect provisional/open status.

Do not modify SMM unless an actual contradiction is demonstrated.

## Classification

Every nontrivial finding must be classified as:

- DEFINITION
- DERIVED
- ASSUMPTION
- COUNTEREXAMPLE
- REFINEMENT
- OPEN
- REJECTED

## Primitive elimination

For every candidate primitive document:
- existing authority;
- claimed missing distinction;
- minimal counterexample;
- whether the distinction is expressible without the primitive;
- conclusion.

## Validation

Run:

`lake build SCRFormal`

Run all existing STC examples/counterexamples and the new graph counterexamples.

A green build is necessary but not sufficient.

## Final report

Report:
1. STC-001 assumptions;
2. graph hypothesis;
3. ontology audit;
4. counterexample results;
5. ResultState analysis;
6. OutcomeOf analysis;
7. Delta analysis;
8. determinism/nondeterminism;
9. partiality/failure;
10. composition/associativity;
11. observation/equivalence;
12. footprint/independence;
13. causality/temporal semantics;
14. primitive-elimination matrix;
15. surviving model;
16. rejected models;
17. remaining gaps;
18. proposed minimum STC-002 kernel;
19. explicit gate decision.

## Completion condition

STC-002 must remain blocked until the minimum semantic transition structure has been established by counterexample-driven analysis.

The objective is to discover which model survives falsification. A successful result may remove abstractions introduced by STC-001.
