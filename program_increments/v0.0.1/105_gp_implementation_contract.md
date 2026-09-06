# 105 — Golden Path Implementation & Verification Contract

**Document:** `105_gp_implementation_contract.md`
**Version:** 1.0.0
**Status:** Draft
**Program Increment:** `v0.0.1`
**Created:** 2026-09-06
**Normative:** Yes

---

## 1. Purpose

This document defines the implementation and verification contract for the Semantic Computational Runtime (SCR) Golden Path.

It exists to bridge the architectural requirements established by:

> `104_golden-path.md — Golden Path: Verified Executable Computational Trunk`

and the concrete implementation of those requirements in the SCR repository.

This document does **not** define a programming language, runtime API, MLIR dialect, renderer, provider implementation, or domain-specific simulation model.

Instead, it defines the constraints under which such implementations may be constructed.

The central requirement is:

> **Implementation must be derived from semantic meaning and its verified contracts rather than becoming an independent source of semantic authority.**

The implementation hierarchy is therefore:

```text
Semantic Meaning
        ↓
Semantic Specification
        ↓
Formal Semantic Model
        ↓
Lean Verification
        ↓
Executable Semantic Implementation
        ↓
Reference Executor
        ↓
SCR Representation
        ↓
MLIR
        ↓
Lowering
        ↓
Provider
        ↓
Runtime
        ↓
Execution Substrate
        ↓
Semantic State
        ↓
Observation / Manifestation
```

The implementation must preserve semantic authority throughout this progression.

---

# 2. Authority

SCR has multiple implementation and verification artifacts, but they do not possess equal semantic authority.

The authority ordering is:

```text
Normative Semantic Specification
        ↓
Formal Semantic Model
        ↓
Verified Semantic Properties
        ↓
Executable Semantic Implementation
        ↓
Reference Executor
        ↓
Intermediate Representations
        ↓
Runtime Representations
        ↓
Physical Execution
        ↓
Observation / Manifestation
```

The following rules apply.

### GP-IC-001 — Specification Authority

Normative SCR specifications define intended SCR semantics.

Implementation artifacts MUST NOT silently redefine normative semantics.

If implementation and specification disagree, the discrepancy MUST be explicitly classified as one of:

1. implementation defect;
2. specification defect;
3. unresolved semantic question;
4. intentional implementation restriction.

The discrepancy MUST NOT be resolved merely by treating the implementation as authoritative.

---

### GP-IC-002 — Formal Authority

Where a semantic property has been formalised in Lean, the formal model provides the mechanically checked statement of that property.

Lean verification MUST NOT be treated as documentation only.

A theorem counts as verified only when the Lean project successfully checks it.

---

### GP-IC-003 — Implementation Authority

Mojo is the primary preferred implementation language for SCR runtime and semantic implementation work.

Mojo implementations MUST implement previously defined semantic contracts.

Mojo code MUST NOT become the sole source from which fundamental SCR semantics are inferred.

---

### GP-IC-004 — Representation Authority

MLIR is an executable representation and transformation substrate.

MLIR MUST NOT become the semantic authority for concepts that have not first been defined semantically.

An MLIR operation, type, attribute, or dialect MUST NOT introduce an otherwise undefined semantic concept merely because it is convenient to implement.

---

### GP-IC-005 — Runtime Authority

Runtime state is an execution manifestation of semantic state.

Runtime implementation details MUST NOT silently redefine authoritative semantic state.

---

# 3. Relationship to the Golden Path

The Golden Path establishes **what must be demonstrated**.

This document establishes **the implementation constraints under which that demonstration is constructed**.

The relationship is:

```text
104_golden-path.md
    │
    │ defines required conformance
    ↓
105_gp_implementation_contract.md
    │
    │ defines implementation constraints
    ↓
Formal Semantic Model
    │
    ↓
Lean Verification
    │
    ↓
Mojo Implementation
    │
    ↓
Reference Executor
    │
    ↓
MLIR Representation
    │
    ↓
Lowering / Provider / Runtime
    │
    ↓
Execution
```

The Golden Path therefore does not require a particular internal implementation.

It requires preservation of semantic meaning across implementation boundaries.

---

# 4. Core Implementation Principle

SCR SHALL be implemented according to the following principle:

> **Engineer outward from the Semantic Field.**

The Semantic Field is the architectural origin.

Lower-level mechanisms are derived from the semantic requirements imposed by the field.

The implementation process therefore proceeds conceptually as:

```text
Semantic Field
    ↓
Entities
    ↓
Relationships
    ↓
Values
    ↓
State
    ↓
Transformations
    ↓
Constraints
    ↓
Context
    ↓
Topology
    ↓
Execution Requirements
    ↓
Representation
    ↓
Physical Manifestation
```

The reverse process MUST NOT be used as the primary architectural method.

In particular:

```text
CPU
↓
memory layout
↓
pointer structure
↓
object model
↓
"semantic" abstraction
```

is not an acceptable derivation of SCR architecture.

---

# 5. Semantic Field Boundary

The Semantic Field is the foundational semantic abstraction of SCR.

The field is conceptually represented as:

```text
F = (E, R, T, C, S, K, M)
```

where:

* `E` = entities;
* `R` = relationships;
* `T` = transformations;
* `C` = context;
* `S` = state;
* `K` = constraints;
* `M` = physical manifestations.

This representation is conceptual and MUST NOT be interpreted as requiring a particular data structure.

For example, the Semantic Field MAY be manifested through:

* structured values;
* arrays;
* tensors;
* graphs;
* hypergraphs;
* records;
* regions;
* distributed structures;
* memory layouts;
* serialized structures;
* device-resident state.

None of these representations is itself the Semantic Field.

---

# 6. Semantic Kernel

The Golden Path implementation SHALL begin with the smallest semantic kernel capable of demonstrating the required architecture.

The kernel MUST be intentionally minimal.

It SHOULD establish the existence of:

1. semantic identity;
2. semantic entities;
3. semantic values;
4. semantic state;
5. semantic relationships;
6. semantic transformations;
7. semantic contracts;
8. semantic constraints;
9. explicit temporal state;
10. observation of semantic state.

The kernel MUST NOT be expanded merely because additional implementation mechanisms are available.

Every new primitive MUST have a semantic justification.

---

# 7. Semantic Identity

Semantic identity MUST be independent of implementation identity.

A semantic entity is not identified merely by:

* memory address;
* pointer;
* array index;
* object address;
* allocation identifier;
* process-local identifier;
* GPU handle;
* database row;
* serialized offset.

Such identifiers MAY be manifestations of identity, but they are not automatically semantic identity.

The implementation MUST permit semantic identity to survive representation changes where the semantic contract requires persistence.

For example:

```text
Semantic Entity
      │
      ├── dense representation
      │
      ├── sparse representation
      │
      ├── serialized representation
      │
      ├── local representation
      │
      └── remote representation
```

may represent the same semantic entity.

---

# 8. Semantic Values

Values MUST be treated as semantic values before being treated as machine representations.

A machine type such as:

```text
i32
i64
f32
f64
```

is a representation choice.

It is not, by itself, a complete semantic definition.

A semantic numeric value MAY additionally require:

* domain;
* unit;
* dimensionality;
* precision;
* accuracy;
* admissible error;
* range;
* overflow semantics;
* special-value semantics;
* rounding semantics;
* determinism requirements;
* representation constraints.

Therefore:

```text
semantic value
    ↓
numeric contract
    ↓
representation
```

is preferred over:

```text
f32
    ↓
semantic meaning
```

An implementation MAY select `f32`, `f64`, integer, fixed-point, arbitrary precision, SIMD, tensor, or another representation when that representation satisfies the semantic contract.

---

# 9. State

Semantic state is authoritative over runtime representation.

For the Golden Path, a minimal state model MAY be represented conceptually as:

```text
SimulationState
├── simulation_time
└── particles
    ├── identity
    ├── position
    └── velocity
```

This structure is a witness workload, not the definition of SCR.

The important requirement is that state possesses semantic identity and participates in defined transformations.

---

# 10. Transformations

A transformation SHALL be defined semantically before it is implemented physically.

For the canonical Golden Path workload:

```text
position' = position + velocity × dt
```

and:

```text
advance(state, dt) → state'
```

provide the semantic transformation.

The implementation MAY represent this through:

* scalar operations;
* vector operations;
* arrays;
* tensors;
* loops;
* SIMD;
* generated code;
* MLIR;
* LLVM;
* another provider mechanism.

The representation MUST preserve the semantic contract.

---

# 11. Time

Time MUST be represented as explicit semantic state wherever temporal behaviour is part of the computation.

The following concepts MUST remain distinct:

```text
semantic time
wall-clock time
frame time
processing time
scheduling time
latency
```

For the Golden Path, simulation time is semantic state.

A representation such as `f32` or `f64` MAY be selected for implementation only when consistent with the applicable numeric and temporal contract.

Temporal constraints MUST originate in semantic specification or formal semantic modelling.

They MUST NOT be invented solely as implementation-level verifier rules.

---

# 12. Constraints

Semantic constraints MUST be defined at the semantic level before being enforced at lower levels.

For example, if a transformation requires:

```text
dt > 0
```

then the requirement SHOULD first exist as a semantic temporal constraint.

A lower-level verifier MAY subsequently enforce that constraint when doing so is sound and appropriate.

The implementation MUST NOT create a new semantic invariant merely because a particular representation makes such an invariant convenient.

---

# 13. Lean Verification Boundary

Lean is the formal verification boundary of the Golden Path.

Lean SHOULD be used to establish properties such as:

* identity preservation;
* state transition properties;
* algebraic correctness;
* invariant preservation;
* dimensional or numeric constraints where formalised;
* determinism;
* transformation correctness;
* equivalence of defined semantic formulations;
* admissible representation transformations.

The purpose of Lean is **not** to implement a second SCR runtime.

The Lean layer SHOULD therefore remain focused on:

```text
definitions
+
properties
+
proofs
+
invariants
+
refinement claims
```

rather than duplicating runtime mechanisms.

---

# 14. Verification Must Execute

The existence of Lean source code is not evidence of verification.

A verification claim is valid only when:

1. the relevant Lean source is part of the repository;
2. the relevant theorem or property is actually referenced;
3. Lean successfully elaborates and checks it;
4. the result is reproducible.

Documentation claiming that a property is "formally verified" without successful Lean checking MUST NOT be treated as verification evidence.

---

# 15. Mojo Implementation Boundary

Mojo is the primary preferred implementation language for SCR.

The Mojo implementation SHOULD be the principal executable realisation of the semantic model.

The implementation sequence SHOULD be:

```text
Semantic Contract
        ↓
Formal Model
        ↓
Verified Properties
        ↓
Mojo Implementation
```

Mojo implementation MUST NOT be treated as a separate semantic design exercise.

Where implementation decisions are necessary, they MUST be evaluated against the semantic contract.

---

# 16. Reference Executor

The Reference Executor provides an executable semantic oracle for the Golden Path.

Its purpose is to establish expected behaviour independently enough from the optimised execution path that semantic equivalence can be tested.

The Reference Executor SHOULD prioritise:

* clarity;
* determinism;
* inspectability;
* semantic fidelity;
* straightforward correspondence with the semantic model.

It SHOULD NOT optimise prematurely for:

* hardware-specific performance;
* memory layout;
* SIMD;
* accelerator execution;
* distributed execution.

The Reference Executor is not the production runtime.

It is a semantic reference against which executable implementations can be compared.

---

# 17. Mojo and Reference Executor Relationship

The primary implementation and Reference Executor MUST NOT silently become two independent semantic definitions.

The intended relationship is:

```text
Semantic Contract
      │
      ├──────────────→ Reference Executor
      │
      └──────────────→ Mojo Implementation
                              │
                              ↓
                         MLIR / Runtime
```

The Reference Executor and Mojo implementation therefore share semantic authority from the same contract.

They do not derive authority from one another merely because one happens to execute first.

---

# 18. MLIR Boundary

MLIR is an intermediate and executable representation technology within SCR.

It is not assumed to require a custom SCR dialect.

The default policy is:

> **Use existing MLIR capabilities wherever they preserve the required semantic contract.**

Existing mechanisms SHOULD be preferred where sufficient, including appropriate combinations of:

* `arith`;
* `scf`;
* `func`;
* `memref`;
* `tensor`;
* `math`;
* `llvm`;
* and other suitable MLIR infrastructure.

The exact dialect set is an implementation decision constrained by the semantic contract.

---

# 19. No Custom SCR Dialect Assumption

The Golden Path MUST NOT assume the existence of a custom SCR MLIR dialect.

In particular, the implementation MUST NOT begin by defining operations such as:

```text
scr.create_particle
scr.create_state
scr.step
scr.get_time
scr.get_particles
```

merely because those names correspond to semantic concepts.

Such operations may eventually be justified.

They are not architecturally required merely because they are convenient.

---

# 20. Custom MLIR Construct Decision Rule

A custom SCR MLIR operation, type, attribute, or dialect MAY be introduced only when an actual implementation requirement demonstrates that existing MLIR mechanisms are insufficient.

The following decision process MUST be applied.

### Step 1 — Identify the semantic concept

State precisely what semantic concept requires representation.

### Step 2 — Identify the semantic property

State what property must survive representation.

### Step 3 — Test existing MLIR representations

Determine whether existing MLIR types, attributes, operations, regions, dialects, metadata, or combinations thereof can represent the requirement.

### Step 4 — Establish insufficiency

Demonstrate why existing mechanisms cannot preserve the required:

* semantic identity;
* relationship;
* transformation;
* contract;
* invariant;
* provenance;
* verification boundary;
* lowering boundary.

### Step 5 — Define the minimum construct

If a custom construct is necessary, define the smallest construct capable of preserving the requirement.

### Step 6 — Define verification

Specify which properties the construct must verify.

### Step 7 — Define lowering

Specify how the construct is progressively lowered.

### Step 8 — Define provider semantics

Specify how the construct becomes executable provider behaviour.

### Step 9 — Demonstrate end-to-end necessity

Demonstrate that removing the custom construct would materially weaken semantic fidelity, verification, inspectability, or execution correctness.

Only then SHOULD the custom construct be accepted.

---

# 21. Custom Dialect Prohibition

A custom SCR MLIR dialect MUST NOT be introduced merely to:

* make the IR look more SCR-like;
* encode domain terminology;
* provide aesthetically pleasing operation names;
* reproduce the semantic graph syntactically;
* duplicate the Mojo implementation;
* replace ordinary MLIR operations without semantic necessity;
* establish ownership over concepts already adequately represented;
* create an assumed future abstraction before an implementation requirement exists.

The existence of a semantic concept does not automatically imply the need for a dedicated MLIR operation.

---

# 22. Progressive Lowering

SCR representations MUST be progressively lowerable.

Conceptually:

```text
Semantic Structure
        ↓
SCR Semantic Representation
        ↓
MLIR
        ↓
Lower-Level MLIR
        ↓
LLVM / Target Representation
        ↓
Provider
        ↓
Runtime
        ↓
Execution Substrate
```

Each lowering step MUST preserve the semantic contract relevant to that boundary.

A lower representation MUST NOT silently discard semantic information required by later stages.

If information is intentionally erased because it is no longer required for execution, that erasure SHOULD be justified by the applicable contract.

---

# 23. Representation Independence

Semantic meaning MUST remain independent of physical representation.

The following transformations MAY be valid:

```text
dense → sparse
local → remote
scalar → SIMD
array → tensor
high precision → lower precision
uncompressed → compressed
CPU → accelerator
memory → persistent storage
```

provided the applicable semantic contract permits them.

Representation transformation is therefore itself a semantic concern when it affects correctness, precision, determinism, identity, or admissible error.

---

# 24. Provider Boundary

A provider is a physical realisation mechanism.

Provider selection MUST occur after semantic requirements are established.

A provider MAY implement a semantic operation through:

* CPU execution;
* SIMD;
* GPU;
* accelerator;
* remote execution;
* specialised hardware;
* another execution substrate.

The provider MUST satisfy the semantic contract supplied to it.

The provider MUST NOT redefine the meaning of the operation.

---

# 25. Runtime Boundary

The runtime is responsible for physical execution and resource manifestation.

Runtime responsibilities MAY include:

* execution;
* scheduling;
* resource management;
* allocation;
* representation management;
* communication;
* persistence;
* provider interaction;
* runtime state;
* observation;
* lifecycle management.

These mechanisms are manifestations of semantic requirements.

They are not the source of those requirements.

---

# 26. Observation

Observation is a first-class boundary.

Observation MUST NOT mutate authoritative semantic state merely because an observer requires a particular representation.

Conceptually:

```text
Semantic State
      │
      ├────→ Observation
      │
      └────→ Manifestation
```

rather than:

```text
Semantic State
      ↓
Renderer State
      ↓
"authoritative" state
```

The semantic state remains authoritative.

---

# 27. Rendering

Rendering is a manifestation of semantic state.

Rendering MUST NOT become the source of simulation semantics.

The rendering layer MAY transform semantic state into:

* geometry;
* visual state;
* scene state;
* GPU resources;
* raster output;
* other perceptual representations.

These are manifestations.

The renderer MUST NOT redefine authoritative semantic state.

---

# 28. Golden Path Evidence

Every Golden Path implementation MUST produce sufficient evidence to demonstrate traversal of the computational trunk.

The implementation SHOULD expose inspectable artifacts corresponding conceptually to:

```text
golden_path.semantic
golden_path.formal
golden_path.reference
golden_path.mlir
golden_path.lowered
golden_path.state
golden_path.observation
```

The exact file formats are implementation details.

The purpose is traceability.

An evaluator SHOULD be able to determine:

```text
Where did this semantic concept originate?
        ↓
Which contract defines it?
        ↓
Which Lean property verifies it?
        ↓
Which implementation realises it?
        ↓
Which representation carries it?
        ↓
How was it lowered?
        ↓
Which provider executed it?
        ↓
What semantic state resulted?
        ↓
How was that state observed?
```

---

# 29. Testing Contract

Testing MUST occur at multiple levels.

The minimum hierarchy is:

```text
Semantic Specification Tests
        ↓
Core Unit Tests
        ↓
Property / Invariant Tests
        ↓
Reference Executor Tests
        ↓
Implementation Equivalence Tests
        ↓
Representation Tests
        ↓
MLIR Tests
        ↓
Verification Tests
        ↓
Transformation Tests
        ↓
Lowering Tests
        ↓
Provider Tests
        ↓
Execution Tests
        ↓
Headless E2E
        ↓
Manifestation / Rendering
```

No lower-level test replaces a higher-level semantic test.

In particular:

> A visually correct rendering does not establish semantic correctness.

---

# 30. Reference Equivalence

The primary executable implementation SHOULD be compared against the Reference Executor for canonical workloads.

The comparison SHOULD establish equivalence at the semantic level rather than requiring identical physical representations.

For example, the following MAY differ:

```text
memory layout
instruction sequence
temporary values
container representation
execution order
internal allocation
```

while the semantic result remains equivalent.

Equivalence criteria MUST therefore be defined at the semantic contract level.

---

# 31. Determinism

Where a computation is specified as deterministic, determinism MUST be treated as a semantic property.

The implementation MUST account for sources of nondeterminism such as:

* reduction order;
* floating-point behaviour;
* parallel execution;
* scheduling;
* provider-specific operations;
* uninitialised state;
* unspecified ordering;
* random number generation.

If exact equality is not semantically required, an admissible equivalence relation or error bound MUST be defined.

---

# 32. Verification Matrix

The Golden Path implementation SHOULD maintain a verification matrix of the following conceptual form:

| Semantic Claim           | Specification | Lean | Mojo | Reference | MLIR | Runtime | E2E |
| ------------------------ | ------------- | ---- | ---- | --------- | ---- | ------- | --- |
| Identity persistence     | ✓             | ✓    | ✓    | ✓         | ✓    | ✓       | ✓   |
| State transition         | ✓             | ✓    | ✓    | ✓         | ✓    | ✓       | ✓   |
| Time semantics           | ✓             | ✓    | ✓    | ✓         | ✓    | ✓       | ✓   |
| Numeric semantics        | ✓             | ✓    | ✓    | ✓         | ✓    | ✓       | ✓   |
| Invariant preservation   | ✓             | ✓    | ✓    | ✓         | ✓    | ✓       | ✓   |
| Observation independence | ✓             | ✓    | ✓    | ✓         | ✓    | ✓       | ✓   |
| Determinism              | ✓             | ✓    | ✓    | ✓         | ✓    | ✓       | ✓   |

A row need not be marked complete until the relevant evidence exists.

The matrix SHOULD distinguish:

```text
specified
formalised
verified
implemented
tested
executed
observed
```

These states MUST NOT be conflated.

---

# 33. Development Gates

The following gates define the recommended implementation progression.

## Gate 0 — Specification Reconciliation

Required:

* Golden Path reconciled;
* relevant semantic specifications identified;
* contradictions resolved or explicitly recorded;
* implementation scope established.

---

## Gate 1 — Formal Semantic Kernel

Required:

* core semantic definitions exist;
* relevant invariants are formalised;
* Lean checks successfully;
* formal claims are reproducible.

---

## Gate 2 — Mojo Semantic Kernel

Required:

* primary implementation exists;
* implementation corresponds to semantic contracts;
* core unit tests pass;
* implementation does not silently introduce semantic alternatives.

---

## Gate 3 — Reference Equivalence

Required:

* Reference Executor exists for the canonical workload;
* Mojo implementation is compared against it;
* semantic equivalence criteria are explicit;
* comparison succeeds.

---

## Gate 4 — SCR Representation

Required:

* semantic concepts have an executable representation;
* representation preserves required identity, state, relationships, transformations, and contracts;
* unnecessary custom representation is avoided.

---

## Gate 5 — MLIR Realisation

Required:

* representation can be expressed through appropriate MLIR mechanisms;
* custom constructs are justified if required;
* verification occurs before execution;
* lowering preserves the semantic contract.

---

## Gate 6 — CPU Provider

Required:

* CPU execution is established;
* provider boundary is explicit;
* execution results preserve semantic expectations.

---

## Gate 7 — Level A Golden Path

Required:

```text
semantic definition
→ contract
→ formal model
→ verification
→ implementation
→ reference comparison
→ representation
→ MLIR
→ lowering
→ provider
→ runtime
→ execution
→ observation
```

The path MUST execute headlessly.

---

## Gate 8 — Level B Manifestation

Required:

```text
semantic state
→ observation
→ manifestation
```

A reference rendering or equivalent manifestation MUST be demonstrated without making the renderer authoritative over semantic state.

---

# 34. Failure Classification

When a Golden Path stage fails, the failure MUST be classified rather than hidden through implementation changes.

Possible classifications include:

### Semantic Failure

The semantic specification is incomplete, contradictory, or incorrect.

### Formal Failure

The intended property cannot be established in the formal model.

### Implementation Failure

The implementation violates an established semantic contract.

### Representation Failure

The selected representation cannot preserve required semantic information.

### Verification Failure

The implementation or representation cannot satisfy required verification conditions.

### Lowering Failure

A transformation fails to preserve required semantics.

### Provider Failure

A provider cannot satisfy its execution contract.

### Runtime Failure

Runtime behaviour violates the provider or semantic execution contract.

### Observation Failure

Observation does not faithfully expose the resulting semantic state.

### Manifestation Failure

A renderer or other manifestation does not correctly represent observed semantic state.

This classification prevents failures from being "fixed" by weakening the semantic contract.

---

# 35. Architectural Prohibitions

The Golden Path implementation MUST NOT:

1. define semantics primarily through runtime data structures;
2. define semantics primarily through MLIR operations;
3. treat memory addresses as semantic identity;
4. treat array indices as universal semantic identity;
5. make renderer state authoritative;
6. make provider behaviour define semantic meaning;
7. duplicate the runtime inside Lean;
8. duplicate the semantic model independently inside Mojo;
9. create a custom MLIR dialect without demonstrated necessity;
10. hard-code machine numeric types as semantic definitions;
11. use visual correctness as evidence of computational correctness;
12. treat successful compilation as proof of semantic correctness;
13. treat theorem source existence as evidence of formal verification;
14. silently resolve specification/implementation conflicts in favour of implementation;
15. introduce infrastructure before semantic requirements justify it.

---

# 36. Required Traceability

Every substantive implementation component SHOULD be traceable to a semantic requirement.

Conceptually:

```text
Semantic Requirement
        ↓
Contract
        ↓
Formal Property
        ↓
Implementation
        ↓
Representation
        ↓
Transformation
        ↓
Provider
        ↓
Runtime
        ↓
Test
        ↓
Evidence
```

Conversely, every non-trivial implementation mechanism SHOULD be answerable with:

> **Which semantic requirement caused this mechanism to exist?**

If no satisfactory answer exists, the mechanism SHOULD be reconsidered.

---

# 37. Implementation Decision Procedure

For every proposed SCR implementation abstraction, apply:

### Question 1

Does it have semantic meaning?

If no, it is infrastructure rather than a semantic primitive.

### Question 2

If it has semantic meaning, is that meaning already defined?

If no, define or reconcile the semantic specification before implementing it.

### Question 3

What entities and relationships does it participate in?

### Question 4

What transformations does it permit?

### Question 5

What constraints does it preserve?

### Question 6

What properties require formal verification?

### Question 7

Can existing implementation mechanisms represent it?

### Question 8

Can existing MLIR mechanisms represent it?

### Question 9

If not, why not?

### Question 10

What is the minimum new representation required?

### Question 11

How is it lowered?

### Question 12

How is it executed?

### Question 13

How is its semantic result observed?

### Question 14

What evidence demonstrates that the complete path preserves its meaning?

Only after these questions have been answered SHOULD a new architectural primitive be accepted.

---

# 38. Canonical Golden Path Workload

The v0.0.1 canonical workload is a minimal particle simulation.

Conceptually:

```text
Particle
├── identity
├── position
└── velocity
```

with state:

```text
SimulationState
├── simulation_time
└── particles
    ├── identity
    ├── position
    └── velocity
```

and transformation:

```text
position' = position + velocity × dt
```

represented semantically as:

```text
advance(state, dt) → state'
```

This workload exists to demonstrate the architecture.

It MUST NOT be interpreted as establishing:

* particle simulation as the definition of SCR;
* physics as the definition of SCR;
* vectors as the universal SCR value model;
* a mandatory `Particle` runtime object;
* a mandatory `scr.step` MLIR operation;
* a mandatory memory layout;
* a mandatory renderer.

The workload is a **witness computation** for the Golden Path.

---

# 39. Minimality Requirement

The v0.0.1 implementation SHOULD remain deliberately small.

The purpose of the first Golden Path is to prove:

> **SCR can carry semantic meaning through verified executable transformation into physical execution and back into observable semantic state.**

It is not intended to prove the complete SCR architecture.

Features such as:

* distributed execution;
* GPU execution;
* heterogeneous scheduling;
* adaptive providers;
* neural computation;
* learning;
* sophisticated topology;
* advanced physics;
* spatial databases;
* GQL;
* CRDTs;
* distributed consistency;
* general semantic equivalence;
* sophisticated rendering;

MUST NOT be introduced merely to make the Golden Path appear more complete.

---

# 40. Repository Placement

The intended v0.0.1 relationship is:

```text
program_increments/
└── v0.0.1/
    ├── 101_...
    ├── 102_...
    ├── 103_...
    ├── 104_golden-path.md
    └── 105_gp_implementation_contract.md
```

This document is an implementation contract.

It is not a replacement for:

* normative semantic specifications;
* formal Lean definitions;
* Mojo source;
* MLIR technical specifications;
* runtime specifications;
* provider specifications.

Those documents remain responsible for their respective levels.

---

# 41. Relationship to Future MLIR Specifications

If SCR eventually requires custom MLIR constructs, those constructs SHOULD be specified separately from this document.

A future document MAY define, for example:

```text
106_MLIR_SEMANTIC_BOUNDARY.md
```

or an equivalent MLIR-specific specification.

Such a document MUST be based on demonstrated implementation requirements.

It MUST NOT retroactively justify a dialect whose constructs were invented before those requirements were established.

The preferred evolution is therefore:

```text
Golden Path
    ↓
Implementation
    ↓
Verified requirement
    ↓
Representation pressure
    ↓
MLIR analysis
    ↓
Custom construct if necessary
    ↓
Formal specification
```

rather than:

```text
Custom dialect
    ↓
find somewhere to use it
```

---

# 42. Definition of Done

The Golden Path implementation contract is satisfied for v0.0.1 when:

### Semantic

* semantic meaning is defined independently of implementation;
* semantic state is explicit;
* identity is semantically defined;
* transformations are semantically defined;
* relevant constraints are defined;
* temporal semantics are explicit.

### Formal

* applicable properties are formalised;
* Lean successfully checks the relevant proofs;
* verification is reproducible.

### Implementation

* Mojo provides the primary implementation;
* implementation follows semantic contracts;
* unit tests pass;
* property/invariant tests pass.

### Reference

* Reference Executor exists;
* canonical workload executes;
* Mojo implementation is semantically compared against the reference;
* equivalence succeeds.

### Representation

* semantic structures are represented without unnecessary coupling;
* numeric representations remain subordinate to numeric semantics;
* representation independence is preserved.

### MLIR

* MLIR representation exists where required;
* existing MLIR capabilities are preferred;
* any custom constructs are explicitly justified;
* verification occurs before execution;
* lowering preserves semantic contracts.

### Execution

* CPU provider executes the workload;
* runtime lifecycle is demonstrated;
* semantic state is produced.

### Observation

* semantic state can be observed;
* observation does not mutate authoritative state;
* provenance is available.

### Manifestation

* the reference workload can be manifested/rendered;
* manifestation remains downstream of semantic state.

### Evidence

* the complete path is reproducible;
* failures are classified;
* implementation artefacts are traceable to semantic requirements.

---

# 43. Final Architectural Proposition

The Golden Path implementation exists to demonstrate one fundamental proposition:

> **A computation can begin as semantic meaning, be specified as a semantic contract, formally verified, implemented in Mojo, represented and transformed through MLIR where appropriate, lowered to a physical provider, executed by the runtime, produce authoritative semantic state, and finally be observed or manifested without any lower-level representation becoming the source of semantic authority.**

The implementation therefore follows:

```text
Meaning
  ↓
Specification
  ↓
Formalisation
  ↓
Verification
  ↓
Implementation
  ↓
Reference
  ↓
Representation
  ↓
MLIR
  ↓
Lowering
  ↓
Provider
  ↓
Runtime
  ↓
Execution
  ↓
Semantic State
  ↓
Observation
  ↓
Manifestation
```

The architectural invariant throughout the path is:

> **Semantic meaning remains primary; every lower layer is a verified or contract-bound manifestation of that meaning.**

The Golden Path is therefore not a particular dialect, runtime API, object model, memory model, or execution mechanism.

It is a **verified computational trunk** through which semantic structure becomes executable physical reality.

---
