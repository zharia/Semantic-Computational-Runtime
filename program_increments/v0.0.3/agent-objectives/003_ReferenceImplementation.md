# Development Agent Instruction

## 003 — SCR Semantic Kernel: Reference Implementation and Conformance Gate

**Filename:** `program_increments/v0.0.3/agent-objectives/003_semantic-kernel-reference-implementation.md`

**Repository:** `https://github.com/zharia/Semantic-Computational-Runtime`

**Program Increment:** `v0.0.3`

**Predecessor objective:** `program_increments/v0.0.3/agent-objectives/002_semantic-correction-and-conformance.md`

**Objective type:** Baseline acceptance, reference implementation, and conformance validation.

---

# 1. Mission

Establish an evidence-backed semantic baseline and implement a minimal, executable SCR reference path that demonstrates how canonical SCR semantics are mapped into an execution provider and how resulting observations are verified against the declared contracts.

The preceding objective, `002_semantic-correction-and-conformance.md`, has been completed and its reports committed to the repository.

This objective must use those committed results as its starting point. It must not assume that every correction is correct, complete, implemented, or validated merely because the preceding objective is marked complete.

The work has two primary outcomes:

1. **Baseline acceptance:** Determine which corrected semantic definitions are sufficiently established to support implementation, which remain provisional, and which require further resolution.
2. **Reference execution:** Demonstrate a narrow semantic-to-provider-to-observation path with reproducible conformance evidence.

The purpose is to establish a reliable foundation for subsequent SCR implementation work.

> **Describe → specify → prove/test → validate → implement.**

The implementation must be driven by the repository's canonical semantic definitions, not by assumptions imported from a provider.

---

# 2. Governing Principles

## 2.1 SCR is the semantic authority for SCR contracts

SCR defines the semantic contracts necessary to compose computational meaning.

External standards and providers retain authority over their respective domains.

The implementation must preserve the distinction between:

* SCR semantic definitions;
* external standard semantics;
* provider capabilities and behavior;
* representation formats;
* implementation details;
* observations and test evidence.

## 2.2 Integrate rather than replace

Follow:

> Align → integrate → project → adapt → execute.

Do not create replacement abstractions when existing SCR definitions can be reused.

Do not create a second identity model, transformation model, lifecycle model, or semantic composition framework.

## 2.3 Evidence before claims

Every substantive result must be supported by repository artifacts, executable tests, formal verification, or explicit external conformance evidence.

A successful build does not establish semantic correctness.

A passing test does not establish universal validity.

A provider integration does not establish that SCR owns the provider's semantics.

## 2.4 Minimize scope

Implement the smallest meaningful vertical slice that exercises the relevant canonical contracts.

Do not expand into full multiplayer, general-purpose physics, universal simulation, complete USD pipelines, or broad application frameworks unless repository evidence establishes a direct dependency.

---

# 3. Initial Repository Reconnaissance

Before changing any files, inspect the current repository state.

At minimum inspect:

* root documentation and architecture;
* current `v0.0.3` program increment;
* completed objective `001_O3DE-audit.md`;
* completed objective `002_semantic-correction-and-conformance.md`;
* reports committed by objective 002;
* canonical Core definitions;
* Identity/SID definitions;
* Spatial and Geometry definitions;
* Composition and Contract definitions;
* State and Lifecycle definitions;
* Materialization and Lowering definitions;
* Physics, Dynamics, and Simulation definitions;
* existing reference executors;
* existing provider interfaces and adapters;
* existing test infrastructure;
* existing Lean/mathlib integration;
* current status and library graph artifacts.

Use the repository's actual structure. The list above is a conceptual checklist, not a claim that every named directory or file exists.

Do not invent paths, APIs, modules, test commands, or existing implementation details.

## 3.1 Establish the starting revision

Record:

* repository revision/commit;
* working-tree state;
* relevant objective/report commits;
* language and toolchain versions where available;
* available build/test commands;
* relevant dependency versions.

If the working tree contains uncommitted changes, do not overwrite or discard them.

## 3.2 Produce a baseline inventory

For every contract needed by the reference implementation, record:

| Field                      | Required content                                       |
| -------------------------- | ------------------------------------------------------ |
| Concept                    | Semantic concept under consideration                   |
| Canonical source           | Actual repository path                                 |
| Status                     | Current documented/verified/implemented status         |
| Dependencies               | Relevant definitions and interfaces                    |
| Evidence                   | Proofs, tests, implementation, or validation artifacts |
| Open issues                | Remaining contradictions or assumptions                |
| Implementation suitability | Ready, conditionally ready, or blocked                 |

Do not copy the status of objective 002 into this inventory without independently checking its evidence.

---

# 4. Baseline Acceptance Gate

Before implementing the vertical slice, determine which semantic contracts are sufficiently stable to use.

This is a focused acceptance review, not a repeat of the entire preceding audit.

## 4.1 Required contract areas

Review the committed results concerning:

1. SID and identity mapping;
2. coordinate frames and units;
3. transformation semantics;
4. entity/component composition;
5. lifecycle;
6. context and scope;
7. ownership and authority;
8. manifestation and observation;
9. materialization and lowering;
10. provider boundaries.

Physics and distributed-state semantics must be reviewed to the extent that they are dependencies of the selected slice. Do not implement those domains merely because they are listed here.

## 4.2 Acceptance classification

Classify each relevant contract as one of:

* **Accepted:** Sufficiently defined and evidenced for the proposed use.
* **Conditionally accepted:** Usable under explicit assumptions or restrictions.
* **Provisional:** Proposed or documented but insufficiently established.
* **Blocked:** Contradictory, underspecified, or lacking a necessary dependency.
* **Not applicable:** Not required by this vertical slice.

For each classification, provide the canonical source and supporting evidence.

## 4.3 Critical blockers

The following must not be silently assumed:

* identity preservation across manifestation;
* coordinate conversion correctness;
* transformation composition correctness;
* the lifecycle semantics actually required by the selected executable object;
* provider capability and unsupported-operation behavior;
* the meaning of observations returned by the provider.

If a critical contract is blocked, resolve it within this objective only if the resolution is narrow and justified.

Otherwise, isolate the affected functionality behind an explicit provisional interface and document the limitation. Do not claim end-to-end conformance for a path whose critical contract is unresolved.

## 4.4 Baseline report

Create or update the appropriate milestone artifact following repository conventions.

It must state:

* what was inspected;
* what is accepted;
* what is conditionally accepted;
* what remains provisional or blocked;
* what the vertical slice will exercise;
* what is deliberately excluded;
* the evidence supporting these decisions.

---

# 5. Define the Vertical Slice

Implement one narrow, meaningful semantic execution path.

The intended conceptual path is:

```text
SCR semantic definition
        ↓
SCR reference semantic model
        ↓
provider adapter
        ↓
provider manifestation
        ↓
provider execution
        ↓
provider observation
        ↓
SCR observation mapping
        ↓
conformance verification
```

This is a target architecture for the slice, not a requirement to create a separate software module for every box.

Reuse existing SCR modules and abstractions wherever possible.

## 5.1 Minimum behavior

The reference path must demonstrate, to the extent supported by the accepted baseline:

1. Define or load a semantic object using canonical SCR definitions.
2. Assign or resolve its canonical SID.
3. Establish the required semantic state and transformation.
4. Validate preconditions for execution.
5. Map the semantic object into a provider representation.
6. Record the provider manifestation and its relationship to the SID.
7. Execute one bounded operation.
8. Obtain a provider observation.
9. Map the observation back into SCR semantics.
10. Verify applicable invariants.
11. Report unsupported operations and failures explicitly.

The operation should be selected based on existing repository capabilities.

Do not invent a new domain or semantic contract solely to make the demonstration easier.

## 5.2 Reference operation

Select the smallest useful operation that demonstrates actual execution.

Possible candidates include:

* creating and transforming a simple entity;
* applying a defined state transition;
* performing a bounded spatial operation;
* executing a minimal provider-backed simulation step.

These are candidates, not prescribed implementations.

The selected operation must:

* exercise real canonical SCR contracts;
* have a clearly defined expected result;
* be executable in the available environment;
* have a meaningful failure path;
* support reproducible testing.

Document why it was selected.

## 5.3 Reference implementation language

Use the repository's established implementation language and conventions.

Mojo is the preferred implementation language for SCR, but inspect the current codebase and actual toolchain before deciding how the reference implementation should be integrated.

Do not rewrite existing modules or introduce a second runtime merely to satisfy a language preference.

Where the reference implementation necessarily uses another language or provider API, document the boundary and rationale.

---

# 6. Identity and Manifestation

The reference path must preserve the distinction between SCR identity and provider identity.

## 6.1 SID

Use the canonical SID model established in the repository.

Do not invent a new SID format or identity authority.

## 6.2 Provider identifiers

Where the provider requires its own identifier, represent it as a provider-specific identifier associated with the SCR manifestation.

Do not treat provider identifiers as interchangeable with SID.

## 6.3 Required identity evidence

Demonstrate:

* creation or resolution of the SCR SID;
* association with the provider manifestation;
* lookup or mapping in the reverse direction;
* behavior when the provider identifier is invalid, missing, stale, or unavailable, where applicable.

Specify whether the operation preserves SID and why.

Do not assume that equal identifiers imply equal state or synchronization.

## 6.4 Identity failure handling

The implementation must not silently:

* substitute a new SID;
* merge distinct semantic identities;
* accept an ambiguous reverse mapping;
* claim successful restoration when the identity relationship cannot be established.

Document the actual failure behavior.

---

# 7. Coordinate and Transform Conformance

Exercise the corrected coordinate and transformation contracts where the selected operation uses spatial state.

Do not duplicate the preceding objective's mathematical work. Reuse its accepted definitions and formal artifacts.

## 7.1 Required behavior

The implementation must use explicit:

* source and destination frames;
* units;
* coordinate conversion;
* transformation representation;
* provider mapping;
* numerical tolerance.

## 7.2 Required tests

Where applicable, include tests for:

* identity transform;
* composition;
* inverse;
* frame conversion;
* unit conversion;
* round-trip provider mapping;
* supported orientation representation;
* unsupported transform cases.

Do not assert closure, group laws, or exact reversibility outside the accepted transformation model.

## 7.3 Numerical behavior

Specify:

* precision;
* comparison method;
* tolerance;
* expected numerical error;
* whether the test expects exact or approximate equality.

If a provider uses different precision or representation, document the conversion and expected loss.

A passing round-trip test establishes only the tested domain and tolerance.

---

# 8. Entity, Composition and Lifecycle

Use the accepted SCR entity and composition semantics.

Do not import O3DE lifecycle restrictions into SCR unless the selected execution profile explicitly requires them.

## 8.1 Composition

Use existing composition and capability contracts.

Do not assume:

* one component per type;
* components cannot have identity;
* all components require executable behavior;
* all composition dependencies require a total order.

Any required cardinality or dependency ordering must be explicit in the applicable contract.

## 8.2 Lifecycle

Use only the lifecycle profile necessary for the selected executable path.

Document:

* applicable states;
* permitted transitions;
* transition preconditions;
* transition results;
* failure behavior;
* provider-specific mapping.

Do not claim that the selected lifecycle is universal to all SCR semantic entities.

## 8.3 Tests

Test valid and invalid transitions relevant to the selected path.

Where a provider has a different lifecycle, test the adapter's declared mapping rather than assuming equivalence.

---

# 9. Provider Adapter

The provider adapter is the critical integration boundary.

Its purpose is to map SCR contracts into provider capabilities while preserving explicit semantic meaning.

## 9.1 Adapter responsibilities

The adapter should, as required by the selected slice:

* accept a canonical SCR semantic input;
* check required capabilities and preconditions;
* map the input into provider-specific representation;
* establish manifestation identity;
* invoke provider operations;
* translate provider results and errors;
* map observations into SCR semantics;
* report unsupported or lossy mappings.

## 9.2 Adapter contract

Define the adapter's:

* inputs;
* outputs;
* preconditions;
* postconditions;
* supported capabilities;
* unsupported capabilities;
* error behavior;
* identity mapping;
* transformation mapping;
* observation mapping;
* relevant provenance.

Reuse existing SCR contracts or provider abstractions where available.

## 9.3 Capability honesty

The adapter must not advertise a capability merely because:

* the provider has a similarly named API;
* the adapter compiles;
* a stub exists;
* an operation works for one untested special case.

Capability claims must state their supported scope.

## 9.4 Provider choice

Use O3DE/AzFramework if it is the appropriate available provider for the selected slice.

If O3DE is unavailable, incompatible, or unnecessarily complex for the initial reference path, select an existing suitable provider or reference executor and document why.

Do not introduce a large provider dependency solely to demonstrate an interface.

Do not claim O3DE conformance unless O3DE behavior was actually exercised.

---

# 10. Observation and Semantic Mapping

The reference path must distinguish provider execution state from SCR semantic state.

## 10.1 Observation

Define what the provider observation represents.

Specify whether it is:

* a direct state read;
* a sampled state;
* an event;
* a derived value;
* a partial representation;
* an approximate result.

Do not imply exact state equivalence when the provider returns only an approximation or projection.

## 10.2 Mapping

Define how provider output maps back to SCR.

The mapping must state:

* source provider representation;
* destination SCR semantic representation;
* preserved properties;
* omitted properties;
* approximation or conversion;
* error conditions.

## 10.3 Verification

Compare the observed result against the contract's expected behavior.

Do not compare unrelated representations without an explicit mapping.

Where the result is approximate, use the defined tolerance and explain its basis.

---

# 11. Failure and Unsupported Operations

The reference implementation must demonstrate that unsupported or failed operations are distinguishable from successful execution.

At minimum address:

* invalid semantic input;
* missing required capability;
* invalid provider mapping;
* failed manifestation;
* provider execution failure;
* failed observation;
* invalid reverse mapping;
* conformance violation.

Use the repository's existing error/result conventions.

Do not create a new global error system unless required.

## 11.1 Failure invariants

Where applicable, verify that failure does not silently:

* corrupt the SID-to-manifestation mapping;
* report an operation as successful;
* fabricate an observation;
* discard required provenance;
* mutate unrelated semantic state.

Specify which guarantees are actually provided.

---

# 12. Reusable Conformance Harness

Create or extend a reusable harness for testing the reference path and future provider adapters.

The harness must be driven by semantic contracts, not by provider implementation details.

## 12.1 Required test categories

### Identity

* SID-to-provider mapping;
* reverse mapping;
* identity preservation;
* invalid or ambiguous mapping behavior.

### Coordinates and transforms

Where applicable:

* frame conversion;
* unit conversion;
* composition;
* inverse;
* round-trip;
* precision and tolerance.

### Lifecycle and composition

Where applicable:

* permitted transitions;
* prohibited transitions;
* composition constraints;
* provider mapping behavior.

### Execution

* valid input;
* expected operation;
* observable result;
* precondition enforcement;
* failure behavior.

### Observation

* correct semantic interpretation;
* declared approximation;
* invalid or unavailable observation.

### Provenance

* semantic contract identification;
* provider identity/version;
* mapping version or source;
* relevant test evidence.

## 12.2 Test structure

Each test should identify:

```text
Test ID:
Semantic contract:
Canonical specification:
Preconditions:
Input:
Expected behavior:
Observed behavior:
Tolerance, if applicable:
Result:
Evidence:
```

Follow existing repository test conventions rather than introducing a competing test format.

## 12.3 Property-based tests

Use property-based testing where the property has a meaningful domain and the repository supports it.

Do not generate arbitrary inputs outside the contract's preconditions and then treat the resulting failure as a semantic defect.

## 12.4 Negative tests

Actively challenge the selected contracts.

Attempt to falsify:

* identity preservation;
* transform correctness;
* lifecycle constraints;
* provider mapping assumptions;
* observation equivalence;
* failure atomicity where claimed.

A failing test must trigger investigation, not automatic weakening of the invariant.

---

# 13. Formal Verification

Reuse the repository's existing Lean/mathlib infrastructure where suitable.

## 13.1 Appropriate formal targets

Potential targets include:

* transformation algebra;
* identity mapping properties;
* state-transition invariants;
* composition constraints;
* pure semantic mapping functions.

Only formalize properties that are precise enough to prove and relevant to the selected implementation.

## 13.2 Requirements

For each formal artifact, record:

* corresponding specification;
* theorem or invariant;
* assumptions;
* proof artifact location;
* verification command;
* actual result.

Do not claim that a provider integration is formally verified merely because a pure mathematical model is proven.

Distinguish formal proof of an abstract contract from conformance of an implementation to that contract.

---

# 14. Determinism and Reproducibility

The reference path should be reproducible to the extent supported by its provider and operation.

Distinguish:

* deterministic semantic behavior;
* reproducible test execution;
* reproducible artifact generation;
* bitwise-identical output.

Do not claim bitwise determinism unless demonstrated.

For any nondeterministic provider behavior:

* identify the source of nondeterminism;
* specify the observable contract;
* define acceptable tolerance or equivalence;
* document how tests account for it.

Record relevant environment and dependency versions.

---

# 15. Implementation Boundaries

Keep the reference implementation intentionally small.

Do not implement the following as part of this objective unless a direct dependency is demonstrated and approved by the existing architecture:

* full EGS;
* general-purpose distributed execution;
* multiplayer networking;
* prediction and reconciliation;
* universal physics abstraction;
* full USD authoring/materialization pipeline;
* universe-scale spatial hierarchy;
* GPU-resident simulation;
* broad UI/application framework;
* generalized provider discovery system.

The goal is to prove a semantic execution path, not to implement every planned SCR subsystem.

If a necessary dependency is missing, record it and determine whether a minimal interface or existing reference implementation can support the slice without distorting the architecture.

---

# 16. Documentation and Repository Integration

Follow the repository's existing conventions for specifications, implementation, tests, and milestone artifacts.

Do not create a parallel documentation hierarchy.

Where the repository uses files such as:

```text
101_definition.md
101_spec.md
102_status.yaml
103_library.graph.json
```

update the appropriate existing artifacts.

Do not assume every affected directory must contain every file type.

## 16.1 Required documentation

Document:

* the accepted semantic baseline;
* the chosen vertical slice;
* the architecture and execution path;
* the provider adapter contract;
* identity and manifestation mapping;
* observation semantics;
* failure behavior;
* conformance tests;
* formal artifacts;
* known limitations;
* unresolved questions.

## 16.2 Provenance

Every adopted external semantic or provider mapping must record its source and relevant version where available.

Distinguish what SCR adopts from what remains provider-specific.

## 16.3 Dependency graph

Update the library graph or equivalent artifact only where the new implementation creates or changes actual dependencies.

Do not add speculative dependency edges.

---

# 17. Status and Evidence

Update the appropriate status artifacts based on the actual work performed.

Use the repository's established status schema.

Maintain the distinction between:

* proposed;
* documented;
* formally specified;
* formally verified;
* implemented;
* tested;
* validated.

For each completed item, include a direct evidence reference where the repository supports it.

Do not mark a contract validated merely because the reference implementation uses it.

Do not mark an adapter generally conformant based on one successful operation.

State the exact conformance scope.

---

# 18. Required Deliverables

## Deliverable A — Baseline Acceptance Report

Record:

* repository revision;
* relevant files inspected;
* accepted and blocked contracts;
* evidence supporting each decision;
* unresolved issues;
* selected vertical slice;
* excluded work.

## Deliverable B — Reference Implementation

Implement the smallest meaningful end-to-end semantic execution path supported by the repository.

The implementation must use canonical SCR contracts and an explicit provider/reference-executor boundary.

## Deliverable C — Provider Adapter Specification

Document the adapter's semantic contract, capability scope, identity mapping, transformation mapping, observation mapping, and failure behavior.

## Deliverable D — Conformance Harness

Add or extend reusable tests that exercise the semantic-to-provider path.

## Deliverable E — Formal Artifacts

Add or extend Lean proofs or other appropriate formal artifacts for relevant mathematical claims.

Do not manufacture formal work where it is not appropriate.

## Deliverable F — Evidence and Status Updates

Update the appropriate status and library graph artifacts with actual evidence.

## Deliverable G — Final Implementation Report

Provide a concise but complete account of:

* what changed;
* what was implemented;
* what was tested;
* what was formally verified;
* what was validated;
* what remains unresolved;
* what should be implemented next.

---

# 19. Acceptance Criteria

The objective is complete only when the following criteria are satisfied or explicitly documented as blocked with evidence and rationale.

### AC-01 — Baseline inspected

The agent has inspected the committed results of objective 002 and identified the canonical definitions required by the selected slice.

### AC-02 — Baseline decisions evidenced

Accepted, conditional, provisional, blocked, and not-applicable contracts are explicitly classified.

### AC-03 — No duplicated semantic model

The implementation reuses canonical SCR identity, transformation, composition, state, and lifecycle definitions where applicable.

### AC-04 — Real execution path

The reference implementation performs a real bounded operation through an actual provider or existing executable reference implementation.

A mock-only demonstration does not satisfy this criterion.

### AC-05 — Identity mapping

The SID-to-provider relationship is explicit and tested.

### AC-06 — Transformation correctness

Where spatial state is involved, the implementation uses the accepted coordinate and transform contracts and tests the relevant mappings.

### AC-07 — Lifecycle correctness

The implementation uses the applicable lifecycle profile and tests relevant transitions without asserting universality.

### AC-08 — Explicit provider boundary

Provider-specific semantics, limitations, and capabilities are documented.

### AC-09 — Observation mapping

Provider observations are mapped into SCR semantics under an explicit contract.

### AC-10 — Failure behavior

Unsupported and failed operations are distinguishable from successful execution and do not silently violate declared invariants.

### AC-11 — Reusable conformance tests

The harness can exercise the reference path and is structured for future provider adapters.

### AC-12 — Negative testing

Relevant assumptions and invariants have been actively challenged.

### AC-13 — Formal claims are supported

Applicable mathematical claims have proofs or are explicitly marked unverified.

### AC-14 — Status is truthful

Implementation, test, proof, and validation statuses are evidence-backed.

### AC-15 — Scope is controlled

The work does not expand into unrelated subsystems or introduce duplicate architectures.

### AC-16 — Reproducibility

The implementation and tests have documented execution commands and environment requirements.

### AC-17 — Remaining work is explicit

All known limitations and unresolved dependencies are recorded.

---

# 20. Explicit Prohibitions

The development agent MUST NOT:

1. assume objective 002's completion proves all its claims;
2. skip repository inspection;
3. invent paths, APIs, or current implementation details;
4. duplicate canonical SCR definitions;
5. import O3DE restrictions wholesale;
6. treat provider IDs as SID;
7. conflate identity with state equivalence;
8. conflate ownership with authority;
9. assume provider observations are exact SCR state;
10. claim general provider conformance from a narrow test;
11. claim formal verification without a proof artifact;
12. claim validation without conformance evidence;
13. weaken invariants merely to make tests pass;
14. create mock-only evidence and present it as real execution;
15. introduce unnecessary dependencies;
16. perform unrelated refactoring;
17. implement distributed or simulation subsystems without demonstrated need;
18. silently discard existing uncommitted work;
19. report commands or tests as successful if they were not executed;
20. hide unresolved issues behind optimistic status labels.

---

# 21. Working Sequence

Execute the work in this order.

## Phase 1 — Repository Archaeology

Inspect the current repository and committed objective-002 results.

Produce the baseline inventory.

## Phase 2 — Baseline Acceptance

Classify the relevant semantic contracts and identify critical blockers.

## Phase 3 — Slice Selection

Select one bounded operation that exercises canonical SCR semantics and can run in the available environment.

Document the rationale and scope.

## Phase 4 — Contract Definition

Define the exact execution path, adapter contract, identity mapping, observation mapping, and failure behavior.

Reuse existing specifications.

## Phase 5 — Reference Implementation

Implement the minimal end-to-end path.

Avoid speculative abstractions.

## Phase 6 — Conformance Harness

Create or extend tests corresponding to the declared contracts.

## Phase 7 — Formal Verification

Prove suitable mathematical properties and link proofs to the corresponding specifications.

## Phase 8 — Adversarial Testing

Challenge identity, mapping, transformation, lifecycle, observation, and failure assumptions as applicable.

## Phase 9 — Documentation and Status

Update canonical documentation, status, provenance, and dependency artifacts.

## Phase 10 — Final Audit

Search for contradictory or overstated claims introduced by this objective.

Confirm that:

* the implementation matches the declared contract;
* tests correspond to actual semantic claims;
* provider-specific behavior remains correctly scoped;
* statuses reflect evidence;
* limitations remain visible.

---

# 22. Final Report Format

Use the repository's established reporting conventions. The report must cover the following sections:

```text
# SCR Semantic Kernel Reference Implementation and Conformance Report

## 1. Executive Summary

## 2. Repository Revision and Initial State

## 3. Baseline Acceptance
### 3.1 Accepted Contracts
### 3.2 Conditionally Accepted Contracts
### 3.3 Provisional or Blocked Contracts
### 3.4 Non-Applicable Contracts

## 4. Vertical Slice Selection
### 4.1 Rationale
### 4.2 Scope
### 4.3 Exclusions

## 5. Architecture and Execution Path

## 6. Reference Implementation

## 7. Provider Adapter
### 7.1 Capability Scope
### 7.2 Identity Mapping
### 7.3 Transformation Mapping
### 7.4 Observation Mapping
### 7.5 Failure Behavior

## 8. Conformance Harness

## 9. Test Results
### 9.1 Positive Tests
### 9.2 Negative Tests
### 9.3 Property Tests
### 9.4 Limitations

## 10. Formal Verification

## 11. Provider Validation

## 12. Evidence Matrix

## 13. Files Changed

## 14. Dependencies and Environment

## 15. Commands Executed

## 16. Unresolved Issues

## 17. Recommended Next Objective
```

The evidence matrix should include:

| Contract | Specified | Formally verified | Implemented | Tested | Validated | Evidence |
| -------- | --------- | ----------------- | ----------- | ------ | --------- | -------- |

Use the repository's actual status conventions where they differ.

---

# 23. Definition of Done

This objective is complete when the repository contains:

1. an evidence-backed acceptance assessment of the relevant semantic baseline;
2. a bounded, executable reference path using canonical SCR contracts;
3. an explicit provider boundary;
4. a reusable conformance harness;
5. reproducible test results;
6. formal artifacts for suitable mathematical claims;
7. accurate status and provenance records;
8. a clear record of remaining limitations and dependencies.

The objective is not complete merely because:

* code has been written;
* the project compiles;
* a mock returns the expected result;
* documentation has been updated;
* tests pass without demonstrating the intended semantic contract.

The objective must establish what has actually been demonstrated—and what has not.

---

# 24. Final Architectural Principle

The reference implementation should demonstrate the following relationship:

```text
Canonical SCR semantics
        ↓
Explicit semantic contract
        ↓
Reference execution model
        ↓
Provider mapping
        ↓
Provider execution
        ↓
Observation mapping
        ↓
Conformance evidence
```

The purpose is not to prove that SCR can replace its providers.

The purpose is to demonstrate that SCR can preserve and verify declared semantic meaning across a real execution boundary.

**Build the smallest real slice. Reuse the established semantics. Make every mapping explicit. Test the contracts. Report the evidence honestly.**

Do not expand the runtime until the reference path demonstrates that the semantic architecture works.
