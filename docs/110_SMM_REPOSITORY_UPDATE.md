# SMM Repository Update Plan

**Document ID:** SCR-DOC-PLAN-110  
**Status:** Implementation instruction  
**Version:** 0.1.0

---

## 1. Objective

Integrate the new Semantic Machine Model and Semantic Transition Calculus into SCR without creating a second semantic ontology or an infrastructure-first runtime model.

---

## 2. Add These Documents

Add:

```text
docs/106_SEMANTIC_MACHINE_MODEL.md
docs/107_SEMANTIC_TRANSITION_CALCULUS.md
docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md
docs/109_SMM_LIBRARY_CROSSWALK.md
docs/110_SMM_REPOSITORY_UPDATE.md
docs/111_SMM_TERMINOLOGY_AND_DECISIONS.md
```

Also apply the README changes in:

```text
docs/README_UPDATE.md
```

---

## 3. Do Not Add These

Do NOT add:

```text
lib/???_SemanticMachine/
lib/???_ComputationalSpace/
lib/???_ExecutionContext/
lib/???_Processor/
lib/???_Scheduler/
lib/???_Storage/
lib/???_Executor/
lib/???_ManifestationEngine/
```

Do NOT create Mojo modules merely to mirror the SMM tuple.

Do NOT create a custom `scr.*` MLIR dialect.

---

## 4. Existing Documentation That Must Be Reconciled

### Root README

Update terminology so that:

- the Semantic Field remains foundational;
- SMM is described as an abstract machine model;
- the old implication that SCR is simply a conventional runtime/VM is avoided;
- Reference Executor is described as a canonical realization/oracle;
- EGS is described as the operational execution environment;
- physical manifestation is explicitly separated from semantic meaning.

The existing statement:

> SCR is not fundamentally a conventional virtual machine

should remain.

It should be supplemented with the more precise statement:

> SCR defines an implementation-independent abstract machine boundary, but is not reducible to the conventional VM architectures represented by JVM or CLR.

---

## 5. Core Definition

Do not immediately rewrite `lib/101_Core/101_definition.md`.

First formalize STC against the existing definitions.

Potential updates should be minimal and evidence-driven.

The first candidate areas are:

- State;
- Transition;
- Outcome/Error;
- Observation;
- Equivalence.

Do not duplicate concepts.

---

## 6. Reference Executor

Review the Reference Executor against STC.

It should be characterized as:

```text
canonical executable realization
            ↓
       semantic oracle
```

It should not be renamed to Semantic Machine.

Tests should eventually state conformance in STC terms.

---

## 7. Existing Equivalence Tests

Existing semantic equivalence and differential tests should be reinterpreted as early witnesses for:

\[
Obs(I)\equiv Obs(RE)
\]

The current tests are evidence, not proof of the complete SMM.

Do not overclaim the current milestone as a complete proof of SMM conformance.

---

## 8. Lean Formalization

Create a new formalization area only after inspecting the existing `SCRFormal` structure.

Preferred conceptual module:

```text
SCRFormal/
└── SemanticMachine/
    ├── State.lean
    ├── Context.lean
    ├── Transformation.lean
    ├── Constraint.lean
    ├── Outcome.lean
    ├── Transition.lean
    ├── Observation.lean
    ├── Equivalence.lean
    ├── Composition.lean
    ├── Concurrency.lean
    ├── Temporal.lean
    └── Conformance.lean
```

This is a provisional organization only.

If the existing formal model already provides these concepts, extend it instead of creating duplicates.

---

## 9. Formalization Order

Implement in this order:

1. inspect current formal State;
2. inspect current formal Transformation;
3. inspect current formal Constraint;
4. inspect current formal Context;
5. inspect current formal Observation;
6. inspect current formal Equivalence;
7. define Outcome only if missing;
8. define Applicability;
9. define Admissibility;
10. define Transition instantiation;
11. define transition outcome relation;
12. define composition;
13. define independence/conflict;
14. define temporal/causal relations;
15. define conformance.

Do not start with EGS or provider integration.

---

## 10. Mojo Work

No new runtime ontology is required immediately.

The existing semantic kernel should be tested against the calculus.

Only add implementation structures where a formal semantic requirement cannot be represented by existing structures.

---

## 11. EGS Work

EGS documentation should be added only at the operational architecture level.

EGS should:

- host executable graphs;
- establish execution contexts;
- resolve capabilities;
- select providers;
- coordinate physical execution;
- expose observations and realization failures.

EGS should not define SMM semantics.

---

## 12. Provider Work

No provider API change is required merely because SMM has been formalized.

Provider contracts should eventually expose:

- semantic capability;
- compatibility;
- constraints;
- realization status;
- provenance;
- failure classification.

Provider identity must remain replaceable.

---

## 13. Test Requirements

Add tests for:

### Semantic validity

A transformation can be valid without an available provider.

### Realization failure

A valid transformation can fail because a provider is unavailable.

### Physical failure

A valid selected provider can fail during execution.

### Provider substitution

Two providers satisfying the same semantic capability produce equivalent observations.

### Representation substitution

Two representations preserve semantic equivalence.

### Schedule substitution

Different physical schedules preserve semantic observation where no semantic order is required.

### Reference Executor

The Reference Executor agrees with other conforming implementations at the semantic observation boundary.

---

## 14. Agent Instruction

Any coding agent working on this change MUST obey:

> Treat `106_SEMANTIC_MACHINE_MODEL.md` and `107_SEMANTIC_TRANSITION_CALCULUS.md` as architectural specifications under review, not permission to create infrastructure components.
>
> Reuse existing semantic definitions before adding types.
>
> Do not infer semantic primitives from runtime components.
>
> Do not create providers, processors, schedulers, storage layers, executors, namespaces, or manifestation engines as SMM primitives.
>
> If a new primitive appears necessary, first produce a counterexample showing that the existing semantic vocabulary and STC cannot express the case.
>
> No implementation change is accepted solely because it makes the architecture look more complete.

---

## 15. Exit Criteria

The update is complete only when:

- documentation is internally consistent;
- the README reflects the new architecture;
- STC is mapped against existing Core semantics;
- no duplicate ontology has been introduced;
- Lean formalization has begun;
- at least one existing executable witness is expressed in STC terms;
- the Reference Executor remains an implementation;
- EGS remains a realization environment;
- provider substitution remains semantically transparent.

---

## 16. Explicit Non-Goal

This update does not attempt to finish the entire SCR runtime.

It establishes the correct semantic boundary from which later runtime architecture can be derived.
