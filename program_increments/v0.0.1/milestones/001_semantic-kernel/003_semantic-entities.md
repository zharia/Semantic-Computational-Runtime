# SCR Development Instruction — Semantic Entity Model & Kernel Stabilisation

Repository:

`https://github.com/zharia/Semantic-Computational-Runtime`

## Mission

Continue development from the completed `reports/002` milestone.

The previous milestone successfully established:

```text id="c3p8w1"
Normative Semantic Specifications
        ↓
Lean Formal Semantic Kernel
        ↓
Mojo Semantic Kernel
        ↓
Reference Executor
        ↓
Semantic Equivalence
```

The next milestone is **Semantic Kernel Stabilisation and the First Canonical Entity Definition Model**.

The immediate goal is to move from a collection of working semantic witnesses such as:

```text
Counter
Thing
Message
```

to a genuinely general SCR mechanism for defining semantic entities.

The milestone should establish:

```text id="m4c7p2"
Semantic Entity Definition
        ↓
Semantic Entity Instance
        ↓
Semantic State
        ↓
Relationships
        ↓
Transformations
        ↓
Constraints / Context
        ↓
Observation
```

The milestone must remain **semantic-first**.

Do not begin by designing an MLIR dialect.

Do not begin lowering.

Do not begin building the CPU provider.

Do not expand the runtime.

The objective is to make the semantic model sufficiently coherent that the representation boundary can subsequently be designed from evidence.

---

# 1. Inspect the current repository before changing anything

Start by inspecting the actual current repository state.

Do not assume the previous report is perfectly accurate.

Inspect:

```text id="9c0z7k"
seed/
docs/
lib/
formal/
runtime/
program_increments/v0.0.1/
program_increments/v0.0.1/reports/001/
program_increments/v0.0.1/reports/002/
```

Specifically inspect:

* current normative semantic specifications;
* `104_golden-path.md`;
* `105_gp_implementation_contract.md`;
* `106_semantic_kernel_contract.md`;
* `reports/002/gate0_reconciliation.md`;
* `reports/002/verification_report_milestone.md`;
* current Lean semantic kernel;
* current Mojo `lib/scr_kernel/`;
* Reference Executor;
* current tests;
* current entity examples;
* current Context implementation;
* current Observation implementation;
* current SemanticField implementation.

The repository itself is authoritative evidence of implementation state.

---

# 2. Preserve the successful work from milestone 002

Do not rewrite working infrastructure merely for stylistic reasons.

Before changing anything, establish the current baseline.

Run the existing verification suite.

At minimum:

```bash
lake build SCRFormal
```

and the current Mojo/Reference Executor test suite.

Record the baseline.

All existing passing behaviour should remain passing unless a genuine semantic inconsistency is discovered.

If a correction changes expected behaviour, document why the previous behaviour was semantically incorrect.

---

# 3. Resolve the Observation non-interference weakness

The previous report identified a weakness in the Lean theorem currently described as establishing observation non-interference.

The existing property is effectively reflexive:

```text id="r8f0xq"
obs.source = obs.source
```

That is not sufficient evidence that an observation leaves authoritative semantic state unchanged.

Do not simply rename or restate the existing theorem.

Determine what the normative specification actually requires.

Then formalise the correct semantic property.

The intended distinction is:

```text id="y3x1vd"
observe(S)
    =
    (Observation, S)
```

conceptually, where the authoritative semantic state remains unchanged.

If the semantic model represents observation differently, follow the actual model rather than forcing this notation.

The property must establish **non-interference with authoritative semantic state**, not merely equality of an object with itself.

Add meaningful Lean verification.

Add corresponding executable tests.

The resulting theorem/property should be traceable to the normative semantic specification.

Do not invent stronger guarantees than the specification requires.

---

# 4. Make Context semantically operative

The previous report identified another important gap:

`SemanticContext` exists, but `SemanticField.execute()` does not meaningfully consume it.

This must now be resolved.

The semantic transformation model is:

```text id="y0e8p3"
F_(t+1) = T(F_t, C_t)
```

Therefore Context cannot merely exist as unused metadata if Context is part of the semantic contract.

Determine exactly what the current specifications require Context to mean.

Then make the smallest change necessary so that:

```text id="2z3g5m"
Transformation
      │
      ├── semantic state
      ├── semantic context
      └── constraints
              │
              ▼
         new semantic state
```

is represented honestly in the executable kernel.

Do not turn Context into:

* process environment;
* global variables;
* configuration dumping ground;
* dependency injection framework;
* arbitrary dictionary of runtime values.

Context must remain **semantic context**.

If the current kernel does not yet have enough semantic content to make Context materially observable, implement the minimum coherent mechanism and demonstrate it with tests.

---

# 5. Resolve Entity vs Entity Type vs Entity Instance

This is a critical architectural task.

The previous report calls:

```text
Counter
Thing
Message
```

"canonical entities."

Determine whether these are actually:

* semantic entities;
* entity definitions;
* entity types;
* entity instances;
* witness structures;
* test fixtures.

Do not assume the terminology is correct.

Establish explicit semantics for the distinction between:

```text id="w2j6tc"
Entity Definition
        │
        ▼
Entity Type
        │
        ▼
Entity Instance
        │
        ▼
Identity
        │
        ▼
State
```

or whatever structure the existing semantic specifications actually require.

Do not introduce an unnecessary type-system hierarchy.

The purpose is to prevent test fixtures such as `Counter` or `Thing` from accidentally becoming part of SCR's fundamental ontology.

---

# 6. Define the canonical Entity Definition model

This is the principal objective of the milestone.

Establish the smallest coherent semantic concept capable of describing what an SCR entity is.

A candidate conceptual structure is:

```text id="p7k9m2"
EntityDefinition
├── semantic identity / type identity
├── value schema
├── state schema
├── relationship schema
├── constraints
├── transformation capabilities
├── context requirements
├── temporal requirements
└── observation contract
```

However:

**Do not implement this exact structure blindly.**

Derive the actual structure from the normative specifications and existing semantic kernel.

The resulting model must answer:

1. What defines an entity?
2. What distinguishes one entity definition from another?
3. What makes an instance an instance of a definition?
4. What establishes identity?
5. What state belongs to the entity?
6. What relationships can it participate in?
7. What transformations may act upon it?
8. What constraints govern it?
9. What context does it require?
10. What can be observed?
11. Which of these are intrinsic semantic properties and which are runtime manifestations?

---

# 7. Keep Entity Definition separate from Entity Instance

Do not collapse these concepts.

Conceptually establish:

```text id="g4v8xs"
EntityDefinition
       │
       │ instantiates
       ▼
EntityInstance
       │
       ├── Identity
       └── State
```

An entity definition describes semantic structure.

An entity instance represents a particular semantic participant.

For example, it should ultimately be possible to express something conceptually like:

```text id="q8m1za"
Definition:
    Counter

Instances:
    counter-A
    counter-B
    counter-C
```

without making `Counter` itself the semantic identity of every instance.

Likewise:

```text id="h2f6nv"
Definition:
    Person

Instances:
    entity-1
    entity-2
```

should be conceptually possible without introducing any Person-specific implementation into the SCR kernel.

Do not implement Person unless needed as a test.

---

# 8. Preserve Identity Independence

Identity must remain independent from:

* entity definition;
* memory address;
* array index;
* Mojo object identity;
* process;
* machine;
* representation;
* serialization format.

Verify that an entity can change representation without changing semantic identity.

Where possible, create a property test demonstrating:

```text id="0t5g8s"
same semantic entity
        ↓
different representation
        ↓
same semantic identity
```

Do not confuse identity with type identity.

---

# 9. Extend the Lean model around Entity Definition

Once the semantic distinction has been established, formalise it in Lean.

Do not build a huge dependent type system merely because Lean allows it.

The minimum useful formalisation should establish properties such as:

* entity definition validity;
* entity instance validity;
* instance/definition compatibility;
* identity validity;
* state validity;
* relationship validity;
* constraint validity;
* transformation applicability;
* observation validity.

Where appropriate, prove:

```text id="p4r8cz"
valid instance
⇒
instance conforms to definition
```

and:

```text id="k6z1ya"
representation change
⇒
semantic identity preserved
```

Use the actual semantic contracts to determine exact theorem statements.

Run:

```bash
lake build SCRFormal
```

and ensure the formal kernel remains coherent.

---

# 10. Extend the Mojo implementation minimally

Implement the Entity Definition model in Mojo only after the semantic model is settled.

The Mojo implementation should expose the smallest executable representation necessary.

Do not build:

* a general-purpose ORM;
* reflection framework;
* object system;
* schema registry;
* database;
* serializer;
* runtime scheduler.

The Mojo implementation should be a manifestation of the semantic model.

The distinction should remain visible:

```text id="e8r4mz"
Semantic Entity Definition
        ↓
Mojo representation
```

rather than:

```text id="q2n9bc"
Mojo struct
        ↓
therefore semantic entity
```

---

# 11. Extend Reference Executor support

The Reference Executor must remain the semantic execution oracle.

Add only the operations required to exercise the new Entity Definition model.

For example, conceptually:

```text id="w8x4jc"
define_entity(...)
instantiate_entity(...)
validate_entity(...)
observe_entity(...)
```

But do not assume these exact operations are required.

Derive the actual operation set from the semantic contract.

The Reference Executor should remain intentionally simple.

It should not become a second production runtime.

---

# 12. Establish Mojo ↔ Reference Executor equivalence for the Entity model

Extend the existing semantic equivalence framework.

At minimum demonstrate equivalence for:

```text id="r5j7qw"
Entity Definition
Entity Instance
Identity
State
Relationship
Observation
```

where those concepts are executable.

The test structure should remain conceptually:

```text id="b0q6vz"
                    Semantic Input
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
      Reference Executor       Mojo Kernel
              │                     │
              ▼                     ▼
       Semantic Result       Semantic Result
              │                     │
              └──────────┬──────────┘
                         ▼
                Semantic Comparison
```

Comparison must occur at the semantic level.

Do not require identical internal representations.

---

# 13. Add entity-centric property testing

Expand the property suite.

At minimum cover:

### Entity Definition

* valid definitions are accepted;
* invalid definitions are rejected;
* definitions have stable semantic identity.

### Entity Instance

* instances must conform to their definition;
* invalid instances are rejected;
* identity is independent from definition identity.

### State

* instance state conforms to its definition;
* invalid state is rejected;
* failed transformations do not partially corrupt authoritative state.

### Relationships

* valid relationship endpoints exist;
* relationship constraints are respected;
* relationship identity remains semantic.

### Observation

* observation returns information about semantic state;
* observation does not mutate authoritative state;
* observation does not accidentally advance semantic time.

### Context

* context-dependent transformations actually consume semantic context where required;
* changing relevant context can produce a different valid semantic result;
* irrelevant context does not silently alter semantics.

### Determinism

Where specified:

```text id="q4x7fd"
same entity definition
+
same entity state
+
same semantic context
+
same transformation
=
same semantic result
```

Do not assert determinism where the specification does not require it.

---

# 14. Use simple witnesses, not domain ontology

Use the existing:

```text
Counter
Thing
Message
```

only where useful.

Their role should now be clarified.

For example, a test may conceptually demonstrate:

```text id="h8z2pm"
CounterDefinition
       │
       ├── CounterInstance A
       └── CounterInstance B
```

and:

```text id="n5r1vd"
ThingDefinition
       │
       └── ThingInstance
              │
              └── LINKS
                   │
                   ▼
              MessageInstance
```

But these are **witnesses for the semantic machinery**, not necessarily canonical SCR ontology.

Do not encode domain-specific assumptions into the kernel.

---

# 15. Produce a representation-boundary analysis

This milestone must end with a short architectural analysis answering:

> What semantic information must survive the boundary from the verified semantic kernel into a computational representation?

Analyze at minimum:

```text
Identity
Entity Definition
Entity Instance
Value
State
Relationship
Transformation
Constraint
Context
Time
Observation
Provenance
```

For each, determine:

* must semantic identity survive?
* must type/definition information survive?
* must relationships survive?
* must constraints survive?
* must transformation boundaries survive?
* can the information be represented using existing MLIR mechanisms?
* does the semantic kernel require a first-class representation?
* can attributes, SSA values, regions, standard dialects, or metadata preserve the required contract?
* is any custom operation actually necessary?

Do not implement MLIR yet.

This is an **analysis**, not a dialect specification.

The conclusion may legitimately be:

> Existing MLIR mechanisms appear sufficient.

That is a successful outcome.

Alternatively, it may identify a concrete semantic requirement that requires a custom representation.

If so, document exactly why.

---

# 16. Do not create an SCR MLIR dialect in this milestone

This is an explicit prohibition.

Do not create:

```text
scr.create_entity
scr.create_definition
scr.create_state
scr.create_relationship
scr.step
```

or equivalent custom operations merely because they seem intuitive.

Do not create:

* TableGen dialect definitions;
* custom MLIR C++;
* custom lowering passes;
* SCR compiler infrastructure.

The representation decision must emerge from the semantic requirements established in this milestone.

---

# 17. Update the verification report

Create the next milestone report under:

```text
program_increments/v0.0.1/reports/003/
```

Use appropriate filenames based on the repository's existing conventions.

The report must document:

### Specification

* resolved terminology;
* Entity Definition semantics;
* Entity Instance semantics;
* Context semantics;
* Observation semantics.

### Lean

* definitions added;
* properties added;
* proofs completed;
* build results.

### Mojo

* implementation added;
* implementation boundaries;
* tests.

### Reference Executor

* capabilities added;
* tests.

### Equivalence

* comparisons performed;
* results.

### Entity Model

Show the first canonical entity-definition mechanism.

### Representation Analysis

Document what information must cross the eventual representation boundary.

### Gate Status

Report honestly.

At minimum:

```text id="q3j8vm"
Gate 0 — Specification Reconciliation
Gate 1 — Formal Semantic Kernel
Gate 2 — Mojo Semantic Kernel
Gate 3 — Semantic Equivalence
Gate 4 — Entity Definition Model
Gate 5 — Representation Boundary Analysis
```

Use:

```text
PASS
PARTIAL
NOT STARTED
BLOCKED
```

with evidence.

Do not mark a gate PASS because the code compiles.

---

# 18. Milestone acceptance criteria

This milestone is complete only when:

## Semantic Model

* [ ] Entity Definition is explicitly defined.
* [ ] Entity Instance is explicitly defined.
* [ ] Entity Definition and Entity Instance are not conflated.
* [ ] Identity semantics remain independent.
* [ ] State semantics remain authoritative.
* [ ] Relationship semantics remain explicit.
* [ ] Context is semantically meaningful.
* [ ] Observation semantics are explicit.

## Lean

* [ ] Entity Definition is formalised.
* [ ] Entity Instance validity is formalised.
* [ ] Definition/instance compatibility is formalised.
* [ ] Observation non-interference is genuinely verified.
* [ ] Context-dependent semantics are represented appropriately.
* [ ] Required invariants are proved.
* [ ] `lake build SCRFormal` passes.

## Mojo

* [ ] Entity Definition exists as a semantic implementation.
* [ ] Entity Instance exists as a semantic implementation.
* [ ] Identity is independently represented.
* [ ] Context participates meaningfully where required.
* [ ] Observation preserves authoritative state.
* [ ] Existing kernel tests continue to pass.

## Reference Executor

* [ ] Entity Definition behaviour is executable.
* [ ] Entity Instance behaviour is executable.
* [ ] Relevant semantic operations are covered.

## Equivalence

* [ ] Mojo ↔ Reference Executor equivalence exists for the new kernel behaviour.
* [ ] Comparisons are semantic rather than representation-based.

## Representation

* [ ] Representation requirements have been analysed.
* [ ] Existing MLIR mechanisms have been evaluated.
* [ ] A custom SCR dialect has NOT been introduced without demonstrated necessity.

## Documentation

* [ ] `reports/003/` contains an accurate milestone report.
* [ ] Verification status reflects actual evidence.
* [ ] No implementation has silently introduced new semantic concepts.

---

# 19. Definition of success

The milestone should leave the repository in a state where we can honestly express something conceptually equivalent to:

```text id="c5m9xa"
SCR Semantic Field
        │
        ├── Entity Definition
        │       │
        │       └── Entity Instance
        │               │
        │               ├── Identity
        │               └── State
        │
        ├── Relationships
        │
        ├── Transformations
        │
        ├── Constraints
        │
        ├── Context
        │
        └── Observation
```

and demonstrate that this structure exists consistently across:

```text id="v1n6re"
Normative Specification
        ↓
Lean
        ↓
Mojo
        ↓
Reference Executor
        ↓
Semantic Equivalence
        ↓
Tests
```

The first real SCR entity model should therefore no longer be merely:

```text
Counter
Thing
Message
```

It should be the **machinery that makes those things definable as semantic entities**.

That distinction is the purpose of this milestone.

---

# 20. Stop condition

At the end of this milestone, stop before implementing MLIR unless the representation analysis has produced a concrete, evidence-backed requirement.

Do not continue automatically into compiler construction.

Report the recommended next milestone based on the actual evidence.

The likely next progression is:

```text id="z7w3kp"
Semantic Entity Model
        ↓
Representation Boundary
        ↓
SCR Representation
        ↓
MLIR Mapping
        ↓
Lowering
        ↓
Provider
        ↓
Runtime
```

but this sequence must remain evidence-driven.

---

# Governing principles

Throughout the implementation, preserve these principles:

> **Engineer outward from the Semantic Field.**

> **Semantic meaning is authoritative.**

> **Implementation is a manifestation of semantics, not the source of semantics.**

> **Identity is not representation.**

> **Relationship is not pointer.**

> **State is not incidental runtime memory.**

> **Observation is not mutation.**

> **Context is semantic, not merely configuration.**

> **A test witness is not automatically part of the SCR ontology.**

> **Lean verifies semantic claims; Mojo implements them.**

> **The Reference Executor provides executable semantic reference behaviour.**

> **Semantic equivalence is stronger than matching implementation structure.**

> **Do not invent an MLIR dialect before demonstrating that one is necessary.**

Most importantly:

> **The goal is not to build more code. The goal is to make the semantic model sufficiently precise that the code has less freedom to be wrong.**
