# DEVELOPMENT AGENT INSTRUCTION
# SCR — SEMANTIC ALGEBRA CLOSURE PHASE

## EXECUTIVE DIRECTIVE

STOP BROAD IMPLEMENTATION EXPANSION.

The next phase of Semantic Computational Runtime development is **not runtime implementation**.

The next phase is:

> **Close, test, falsify, reconcile, and formally verify the complete SCR semantic algebra before downstream implementation continues.**

The reason is architectural:

> **Any semantic ambiguity left unresolved at the abstract level will become implementation ambiguity later.**

We will not allow that.

Your task is to take the current repository as it exists, inspect the complete semantic/formal corpus, and produce a **closed semantic algebra** from which future implementation can be derived.

---

# 1. ABSOLUTE AUTHORITY RULE

You are NOT authorised to decide that the algebra is complete based on intuition, documentation volume, test count, or implementation success.

Completion is determined by a fail-closed acceptance gate.

You MUST NOT:

- declare semantic closure because the model looks coherent;
- declare a definition complete because Lean accepts its current implementation;
- defer unresolved core questions;
- mark core questions as "future work";
- call an unresolved ambiguity "implementation-defined";
- invent implementation semantics;
- weaken acceptance criteria;
- delete failing counterexamples;
- redefine a concept solely to make a theorem pass;
- introduce a new primitive merely because implementation is inconvenient.

If the algebra is incomplete:

**continue working.**

If a definition is wrong:

**falsify it, revise it, and re-run the complete verification process.**

If two existing definitions conflict:

**resolve the conflict at the semantic level before proceeding.**

---

# 2. WHAT YOU ARE CLOSING

The closure scope includes the complete core semantic algebra:

```text
Identity
Entity
Entity Definition
Value
Relationship
State
Context
Constraint
Applicability
Admissibility
Transformation
Transition
Outcome
Failure
Observation
Equivalence
Time
Ordering
Causality
Concurrency
Independence
Composition
Semantic Space
Persistence
Migration
Replication
Representation
Refinement
Manifestation
Provenance
```

This is the initial inventory, NOT an assumption that every item is a primitive.

For every item determine whether it is:

- primitive;
- derived;
- relation;
- operator;
- predicate;
- type constructor;
- meta-property;
- manifestation concept.

You MUST merge, eliminate, or split terms where formal analysis demonstrates that the current vocabulary is wrong.

---

# 3. INSPECT THE ENTIRE REPOSITORY FIRST

Before changing anything:

1. Inspect the repository tree.
2. Read all current semantic specifications.
3. Read the current SMM documents.
4. Read all STC documents.
5. Read the formal ontology merge.
6. Read the current Lean source.
7. Read the current semantic kernel.
8. Read the Reference Executor.
9. Read Golden Path specifications.
10. Read numeric semantics.
11. Read representation-boundary analysis.
12. Read Milestone 005.
13. Search the entire repository for every core semantic term.
14. Identify duplicate or contradictory definitions.
15. Record the current state before modification.

Do not assume the repository still exactly matches historical descriptions.

The repository itself is authoritative evidence about its current state.

---

# 4. CREATE A SEMANTIC INVENTORY BEFORE REFACTORING

Create a machine-readable and human-readable inventory.

For every core term record:

```text
ID
Term
Canonical candidate definition
Classification
Domain
Codomain
Arity
Layer
Current definitions found
Existing Lean symbol
Existing documentation
Existing tests
Known counterexamples
Dependencies
Open ambiguity
Required law
Closure status
```

No semantic term may disappear silently.

If an existing concept is renamed or merged, preserve its history.

---

# 5. ESTABLISH ONE CANONICAL SEMANTIC AUTHORITY

The final architecture MUST have:

```text
ONE semantic definition
        ↓
ONE formal interpretation
        ↓
DERIVED implementation mappings
```

Do not permit:

```text
documentation definition
Lean definition
Mojo definition
MLIR definition
runtime definition
```

to independently evolve.

The semantic definition is authoritative.

Implementation must conform.

---

# 6. CLOSE THE ALGEBRA, NOT JUST THE DATA STRUCTURES

Do not stop after defining records such as:

```text
Entity
State
Transformation
Constraint
```

The actual objective is to define the **operators and laws between them**.

For every operation determine:

- input;
- output;
- preconditions;
- postconditions;
- invariants;
- failure;
- undefinedness;
- nondeterminism;
- context;
- time;
- causality;
- observation;
- equivalence;
- composition.

A record definition without its laws is not semantic closure.

---

# 7. CLOSE APPLICABILITY / ADMISSIBILITY / TRANSFORMATION / OUTCOME

This distinction MUST be formally resolved:

```text
Applicability
    ↓
Admissibility
    ↓
Transformation attempt
    ↓
Outcome
    ↓
Observation
```

Determine whether each is:

- predicate;
- relation;
- function;
- set-valued relation;
- typed result.

Do not assume the answer.

Use counterexamples.

At minimum construct witnesses for:

- applicable + success;
- applicable + failure;
- inapplicable;
- invalid;
- successful no-op;
- nondeterministic outcome.

Determine whether these are semantically distinct.

---

# 8. CLOSE FAILURE SEMANTICS

Failure must never be represented implicitly.

At minimum test:

```text
successful no-op
constraint failure
inapplicability
invalid input
```

For each determine:

```text
state
semantic time
context
identity
relationships
observation
outcome
composability
```

If two cases are semantically distinct, they MUST be distinguishable in the algebra.

The previous Milestone 005 problem is the model for what must not happen:

```text
failure
    ↓
unchanged state
```

must not silently collapse into:

```text
successful no-op
    ↓
unchanged state
```

unless the semantic model proves them equivalent.

---

# 9. CLOSE NONDETERMINISM

Determine whether SCR transformations are:

- deterministic;
- nondeterministic;
- probabilistic;
- partially defined.

If nondeterminism exists, formally define the set/space of outcomes.

Determine:

- admissible outcome;
- actual outcome;
- observation;
- equivalence;
- refinement.

Do not let implementation scheduling accidentally define semantic nondeterminism.

---

# 10. CLOSE STATE

Define:

- authoritative semantic state;
- state identity;
- state equality;
- state equivalence;
- state version;
- state history;
- state snapshot;
- state transition.

Determine whether state is:

```text
S
```

or:

```text
S(C)
```

or another typed structure.

Do not assume the existing tuple is final.

---

# 11. CLOSE CONTEXT

Define exactly what context means.

Distinguish:

```text
semantic context
physical environment
runtime environment
execution context
provider context
```

Determine whether context:

- is immutable;
- changes;
- is inherited;
- is scoped;
- affects applicability;
- affects transformation;
- affects equivalence.

No hidden environmental dependency is permitted.

---

# 12. CLOSE CONSTRAINTS

Define constraints mathematically.

Determine:

- state constraints;
- transformation constraints;
- value constraints;
- relationship constraints;
- temporal constraints;
- representation constraints.

Determine composition and failure semantics.

A constraint must not become an implementation exception merely because Mojo has exceptions.

---

# 13. CLOSE TIME

Do NOT assume the existing semantic step counter is sufficient.

Formally investigate:

```text
Semantic Time
Logical Order
Causal Order
Wall Clock
Processing Time
Scheduling Time
Latency
Frame Time
Event Time
Duration
```

For each classify:

- semantic;
- derived;
- contextual;
- physical.

Determine:

- ordering;
- simultaneity;
- concurrency;
- rollback;
- replay;
- failure;
- observation.

A physical timestamp must not become semantic time by accident.

---

# 14. CLOSE CAUSALITY

Define causal dependency independently of physical scheduling.

Determine:

- transitivity;
- acyclicity;
- partial ordering;
- contextual dependence;
- state dependence.

Test footprint-based causality aggressively.

Do not promote an implementation heuristic to a semantic law without proof.

---

# 15. CLOSE CONCURRENCY

Define:

- independence;
- interference;
- conflict;
- commutativity;
- serialisability;
- concurrency;
- merge.

Formally test:

```text
T1(T2(S)) ≡ T2(T1(S))
```

and identify exact preconditions.

Do not equate parallel CPU execution with semantic concurrency.

---

# 16. CLOSE IDENTITY

Identity must survive:

- representation changes;
- provider substitution;
- migration;
- persistence;
- replication;

where the semantic contract requires it.

Investigate:

- creation;
- destruction;
- reconstruction;
- splitting;
- merging;
- aliasing.

A UUID/string may be an implementation representation of identity, but is not automatically the semantic definition.

---

# 17. CLOSE RELATIONSHIPS

Define relationship structure and laws.

Determine:

- direction;
- type;
- context;
- temporal validity;
- composition;
- transformation effects.

Do not claim a relationship participates computationally if it is only declarative metadata.

---

# 18. CLOSE OBSERVATION

Formalise:

```text
observe(S, q, C)
```

or the final equivalent.

Prove when observation preserves authoritative state.

Define observation equivalence and consistency.

Determine whether historical/projected/partial observations are primitive or derived.

---

# 19. CLOSE EQUIVALENCE

This is mandatory.

Separate:

```text =
≡
≡context
≡observation
≡representation
≡behaviour
```

For every accepted equivalence relation prove required properties.

Determine substitutability.

This will ultimately define whether different physical manifestations are the same SCR computation.

---

# 20. CLOSE REPRESENTATION INDEPENDENCE

Formalise the semantic projection:

```text
π : IState → S
```

or the final equivalent.

Then establish the refinement relationship between:

```text
semantic transformation
```

and:

```text
implementation transformation
```

Do not let `memref`, `index`, pointer, function symbol, process, GPU buffer, etc. acquire semantic meaning without an explicit contract.

---

# 21. CLOSE SPACE

Define:

```text
semantic space
computational space
physical space
```

and their relationships.

Define:

- location;
- containment;
- adjacency;
- movement;
- migration;
- locality;
- topology.

Do not equate semantic location with memory address.

---

# 22. CLOSE PERSISTENCE / MIGRATION / REPLICATION

Define semantic continuity across:

- persistence;
- restore;
- migration;
- replication;
- recovery;
- replay.

Determine identity/state/time/relationship preservation.

Do not let storage format define semantic state.

---

# 23. CLOSE NUMERIC AND VALUE SEMANTICS

Integrate the existing numeric semantics into the core algebra.

Define:

- units;
- dimensions;
- precision;
- accuracy;
- error;
- range;
- rounding;
- special values;
- determinism;
- conversion;
- quantisation.

Prove representation independence where applicable.

---

# 24. CLOSE MANIFESTATION

Explicitly formalise:

```text
Semantic Meaning
≠
Formal Representation
≠
Implementation Representation
≠
Physical Manifestation
```

Define:

- refinement;
- projection;
- provider conformance;
- compiler correctness;
- manifestation equivalence.

Metadata preservation and executable semantic equivalence MUST remain separate claims.

---

# 25. FORMAL COUNTEREXAMPLE PROGRAM

For every major candidate law:

1. formalise it;
2. attempt to falsify it;
3. classify counterexamples;
4. revise if necessary;
5. retain the counterexample as a regression witness;
6. prove the corrected law.

Counterexamples are not failures of the project.

They are evidence that the formal method is working.

Do not delete counterexamples because they invalidate a convenient definition.

---

# 26. LEAN REQUIREMENT

Use the existing unified `SCRFormal` project.

Do NOT create another Lean project.

Do NOT duplicate ontology definitions.

The final Lean model must contain canonical definitions for the accepted core algebra.

Every normative law must have:

- theorem/property;
- assumptions;
- counterexample coverage where appropriate.

Every rejected formulation must have either:

- a counterexample; or
- a formal reason for rejection.

---

# 27. STC / SMM / SEMANTIC FIELD RELATIONSHIP

Explicitly resolve the relationship among:

```text
Semantic Field
Semantic Machine Model
Semantic Transition Calculus
```

They must not become competing semantic authorities.

The final documentation must explain whether they are:

- ontology;
- machine model;
- calculus;
- projection;
- refinement;
- derived formal views.

One semantic meaning must exist underneath them.

---

# 28. GOLDEN PATH MUST BECOME A DERIVED PATH

The Golden Path must begin conceptually with:

```text
Closed Semantic Algebra
    ↓
Formal Semantic Model
    ↓
Reference Semantics
    ↓
Representation
    ↓
Implementation
    ↓
Manifestation
```

It must not introduce primitives absent from the algebra.

---

# 29. IMPLEMENTATION FREEZE

During this phase do NOT expand:

- EGS;
- providers;
- runtime;
- distributed execution;
- GPU execution;
- production workloads;
- Hyrx integration;
- rendering;
- performance optimisation.

Minimal executable witnesses are permitted only to test semantic hypotheses.

The witness is not permission to establish downstream architecture.

---

# 30. MACHINE-CHECKABLE CLOSURE MANIFEST

Create:

```text
program_increments/v0.0.1/algebra_closure/closure_manifest.yaml
```

It must contain every closure criterion.

Each entry:

```yaml
id:
category:
term:
definition:
classification:
domain:
codomain:
laws:
lean_definition:
lean_evidence:
counterexamples:
documentation:
status:
```

Allowed status values:

```text
OPEN
UNDER_ANALYSIS
FALSIFIED
REVISED
PROVEN
DERIVED
EXCLUDED
```

There must be no `DEFERRED` status for core algebra.

Final closure permits only:

```text
PROVEN
DERIVED
EXCLUDED
```

and `EXCLUDED` requires explicit formal justification.

---

# 31. AUTOMATED ACCEPTANCE GATE

Create an executable closure gate.

It must fail if:

- any core term is OPEN;
- any core term is UNDER_ANALYSIS;
- any required definition lacks Lean representation;
- any required law lacks evidence;
- any unresolved terminology collision exists;
- any active document contains a conflicting definition;
- any required counterexample is missing;
- Lean fails;
- formal regression tests fail;
- closure manifest contains prohibited statuses.

The gate must return non-zero on failure.

No human checkbox can override it.

---

# 32. DOCUMENTATION RECONCILIATION

Search and reconcile all active documents.

There must be no contradictory active definitions of:

- Transformation;
- Transition;
- Outcome;
- Constraint;
- Semantic Time;
- State;
- Identity;
- Entity;
- Relationship;
- Context;
- Observation;
- Equivalence;
- Semantic Space;
- Manifestation.

Superseded documents must be explicitly marked.

Do not silently leave contradictory historical specifications active.

---

# 33. REQUIRED FINAL ARTIFACTS

At minimum produce:

```text
algebra_closure/
    README.md
    closure_manifest.yaml
    primitive_inventory.md
    canonical_algebra.md
    algebraic_laws.md
    counterexample_catalog.md
    terminology.md
    closure_report.md
    acceptance_results.txt
```

plus the formal Lean implementation and regression witnesses.

The exact filenames may follow repository conventions, but the semantic content is mandatory.

---

# 34. FINAL ACCEPTANCE

The phase is COMPLETE only when:

```text
[ ] Complete primitive inventory exists.
[ ] Every core term has one canonical definition.
[ ] Every core term has classification.
[ ] Every operator has domain/codomain.
[ ] Applicability is closed.
[ ] Admissibility is closed.
[ ] Transformation is closed.
[ ] Transition is closed.
[ ] Outcome is closed.
[ ] Failure is closed.
[ ] Nondeterminism is closed.
[ ] Partiality is closed.
[ ] State is closed.
[ ] Context is closed.
[ ] Constraints are closed.
[ ] Identity is closed.
[ ] Entity is closed.
[ ] Relationships are closed.
[ ] Observation is closed.
[ ] Equivalence is closed.
[ ] Semantic time is closed.
[ ] Ordering is closed.
[ ] Causality is closed.
[ ] Concurrency is closed.
[ ] Independence is closed.
[ ] Composition is closed.
[ ] Semantic space is closed.
[ ] Persistence is closed.
[ ] Migration is closed.
[ ] Replication is closed.
[ ] Representation independence is closed.
[ ] Manifestation boundary is closed.
[ ] Provenance semantics are closed.
[ ] STC/SMM/Semantic Field relationship is closed.
[ ] Golden Path is derived from the closed algebra.
[ ] Every normative definition exists in Lean.
[ ] Every normative law is formally verified.
[ ] Counterexample corpus exists.
[ ] Historical counterexamples are retained.
[ ] No unresolved core ambiguity exists.
[ ] No contradictory active definition exists.
[ ] Automated closure gate passes.
[ ] Closure gate passes on a clean final state.
[ ] Final report is generated from actual evidence.
[ ] Closure gate passes again after report generation.
```

If ANY item is false:

**DO NOT REPORT COMPLETE.**

Continue.

---

# 35. FINAL RESPONSE

When and only when the gate passes, report:

```text
SCR Semantic Algebra Closure: COMPLETE

Primitive inventory: PASS
Canonical definitions: PASS
Operator algebra: PASS
Outcome algebra: PASS
State/context/constraints: PASS
Temporal algebra: PASS
Causality/concurrency: PASS
Identity/entity/relationship: PASS
Observation/equivalence: PASS
Space/SMM: PASS
Persistence/migration/replication: PASS
Value/numeric semantics: PASS
Representation/manifestation boundary: PASS
STC/SMM/Semantic Field reconciliation: PASS
Lean formalisation: PASS
Counterexample corpus: PASS
Terminology reconciliation: PASS
Automated closure gate: PASS
Clean-state rerun: PASS
Post-report rerun: PASS

Semantic implementation freeze remains in force until explicitly lifted.
Commit: <actual commit hash>
```

Do not report a percentage.

Do not report "mostly complete".

Do not report "remaining minor issues".

Do not report "future work" for a core algebra closure issue.

Either the algebra is closed or it is not.

---

# 36. GOVERNING PRINCIPLE

The entire phase is governed by one rule:

> **Engineer outward from the Semantic Field, but do not engineer outward until the semantics from which you are engineering are closed.**

The runtime must ultimately be a consequence of the algebra.

The algebra must not become a description of whatever the runtime happened to implement.
