# SCR Development Instruction — Semantic Entity Compilation Milestone

Repository:

`https://github.com/zharia/Semantic-Computational-Runtime`

## Mission

Continue development from the completed `reports/003` milestone.

The objective of this milestone is to cross the next major architectural boundary:

> **Take a genuinely defined SCR Entity Definition and carry it from semantic specification through Lean verification, Mojo implementation, semantic equivalence, and into a canonical computational representation that can be inspected and verified.**

This should be the first **substantial end-to-end semantic compilation milestone** of SCR.

The desired outcome is no longer merely:

```text
Entity is defined.
```

It is:

```text
Semantic Entity Definition
        ↓
Semantic Entity Instance
        ↓
Semantic State
        ↓
Semantic Transformation
        ↓
Lean Verification
        ↓
Mojo Semantic Implementation
        ↓
Reference Executor
        ↓
Semantic Equivalence
        ↓
Canonical SCR Representation
        ↓
MLIR
        ↓
Representation Verification
```

The milestone should produce an actual, inspectable artifact demonstrating that semantic meaning can survive this transition.

However:

> **Do not invent a custom SCR MLIR dialect merely to make the demonstration possible.**

The representation must be derived from the semantic requirements.

---

# 1. Begin with repository inspection

Inspect the current repository before modifying anything.

Pay particular attention to:

```text id="x7r3qm"
seed/
docs/
lib/
formal/
runtime/
program_increments/v0.0.1/
program_increments/v0.0.1/reports/003/
```

Inspect:

* normative semantic specifications;
* `104_golden-path.md`;
* `105_gp_implementation_contract.md`;
* `106_semantic_kernel_contract.md`;
* all `reports/003` material;
* current Lean model;
* current Mojo semantic kernel;
* Reference Executor;
* existing tests;
* Entity Definition implementation;
* Entity Instance implementation;
* Context;
* Observation;
* SemanticField;
* numeric semantics;
* any existing MLIR experiments.

Do not assume the reports perfectly describe the current repository.

Verify the actual implementation.

---

# 2. Establish and record the baseline

Before making changes, run the current verification suite.

At minimum:

```bash
lake build SCRFormal
```

Run the complete current Mojo/Reference Executor test suite.

Record:

* Lean result;
* Mojo test count;
* Reference Executor test count;
* equivalence test count;
* current Entity Definition tests;
* current repository state.

Do not proceed while the baseline is unexplained.

---

# 3. Correct any remaining verification-status ambiguity

Review the previous reports for overclaiming.

In particular, preserve the distinction between:

```text
Existing Kernel Equivalence
```

and:

```text
Entity Model Equivalence
```

Do not claim Reference Executor equivalence for functionality that the Reference Executor does not actually implement.

If necessary, update the previous report or record the corrected status in the new milestone report.

Verification claims must correspond to actual evidence.

---

# 4. Freeze the minimum semantic Entity Definition contract

Before building representation, determine what the minimum canonical Entity Definition actually means.

Do not expand it into a complete ontology or general-purpose schema language.

The current model may contain something similar to:

```text id="5myf8d"
EntityDefinition
├── type_id
└── value_schema
```

Determine whether this is sufficient for the first semantic compilation demonstration.

If it is sufficient, retain it.

If it is not sufficient, extend it only as far as necessary.

The definition must support at least the conceptual distinction:

```text id="9j1xw2"
Entity Definition
        │
        │ instantiates
        ▼
Entity Instance
        │
        ├── Identity
        └── State
```

Do not allow `Counter`, `Thing`, or `Message` to accidentally become fundamental SCR ontology.

They remain witnesses unless the normative specification explicitly establishes otherwise.

---

# 5. Define one canonical Entity Definition as the milestone witness

Select one extremely simple but semantically meaningful entity definition.

Prefer something like:

```text id="r7k3v1"
Counter
```

or an equally minimal generic entity.

But the important artifact is not the Counter itself.

The important artifact is:

```text id="w3q8hz"
CounterDefinition
        ↓
CounterInstance
        ↓
Identity
        ↓
State
        ↓
Transformation
        ↓
Observation
```

The witness must demonstrate the **general entity machinery**.

It must not introduce domain-specific assumptions into SCR.

---

# 6. Establish a canonical semantic program

Create the smallest complete semantic computation involving the Entity Definition.

For example, conceptually:

```text id="s1j9vc"
define Counter
instantiate Counter
initialise state
apply transformation
observe result
```

The exact operations must be derived from the existing semantic model.

The semantic program must have:

* an Entity Definition;
* an Entity Instance;
* identity;
* state;
* at least one transformation;
* relevant constraints;
* relevant context;
* an observation.

The semantic result must be unambiguous.

This becomes the **canonical compilation witness**.

---

# 7. Verify the semantic program in Lean

Formalise enough of the canonical witness to establish that it is valid.

The Lean model should verify:

```text id="q5m7ps"
valid Entity Definition
        +
valid Entity Instance
        +
valid initial State
        +
valid Context
        +
valid Transformation
        +
satisfied Constraints
        ↓
valid resulting State
```

Where applicable, establish:

* definition/instance conformance;
* identity validity;
* state validity;
* transformation validity;
* constraint preservation;
* context validity;
* observation non-interference;
* determinism where specified.

Do not formalise implementation details.

Do not encode Mojo or MLIR concepts into the semantic model.

Run:

```bash
lake build SCRFormal
```

and record the result.

---

# 8. Make the Mojo implementation execute the canonical semantic program

The Mojo semantic kernel must execute the same semantic program.

The implementation must preserve:

* Entity Definition;
* Entity Instance;
* Identity;
* State;
* Transformation;
* Context;
* Observation.

The semantic program should be executable without requiring MLIR.

This establishes the separation:

```text
Semantic Program
       ↓
Mojo Semantic Implementation
```

before:

```text
Semantic Program
       ↓
MLIR
```

Do not make MLIR a prerequisite for semantic correctness.

---

# 9. Extend Reference Executor support

The Reference Executor must execute the canonical semantic witness.

If necessary, extend it minimally.

Do not turn it into a production runtime.

It remains the semantic oracle.

The Reference Executor and Mojo implementation should receive equivalent semantic input.

---

# 10. Establish full semantic equivalence for the witness

Create an explicit test demonstrating:

```text id="f2v6qa"
                 Canonical Semantic Program
                            │
                 ┌──────────┴──────────┐
                 ▼                     ▼
        Reference Executor        Mojo Kernel
                 │                     │
                 ▼                     ▼
          Semantic State A       Semantic State B
                 │                     │
                 └──────────┬──────────┘
                            ▼
                    Semantic Equality
```

The test must compare semantic meaning.

Do not compare:

* memory layout;
* struct layout;
* pointer identity;
* object identity;
* machine representation;
* execution trace unless explicitly semantic.

This equivalence test is a critical milestone artifact.

---

# 11. Perform a rigorous representation analysis

Now determine how the canonical semantic program should be represented computationally.

Analyze at minimum:

```text id="j5z9xw"
Entity Definition
Entity Instance
Identity
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

For each concept determine:

1. What semantic information must survive?
2. What information is merely implementation detail?
3. Can existing MLIR mechanisms represent it?
4. If yes, how?
5. If not, exactly what semantic property is lost?
6. Can attributes, types, SSA values, regions, functions, standard dialects, or metadata preserve it?
7. Does the information need to participate in transformation verification?
8. Does it need to survive lowering?
9. Does it need runtime visibility?

Do not conflate semantic representation with machine representation.

---

# 12. Pay particular attention to the following representation traps

The previous representation analysis contained several hypotheses that must now be tested rather than assumed.

## String

Do not assume:

```text
semantic String = LLVM pointer
```

or:

```text
semantic String = generic machine value
```

Define the semantic requirement first.

Then determine an appropriate representation.

## Time

Do not automatically use:

```text
index
```

as semantic time merely because MLIR has an index type.

Semantic time must retain its semantic contract.

## State

Do not automatically assume:

```text
semantic state = memref
```

A memref may be a useful physical representation, but it is not automatically semantic state.

## Transformation

Do not automatically create:

```text
scr.increment
scr.set
scr.emit
```

because the current witness uses these operations.

Determine whether the semantic concept is actually:

```text
Transformation
```

and whether standard MLIR functions, regions, SSA values, attributes, and verification can represent the required semantics.

---

# 13. Build the first canonical SCR representation

Once the representation analysis is complete, implement the **smallest representation that preserves the canonical semantic witness**.

Prefer existing MLIR mechanisms.

Potential mechanisms may include:

```text id="f9r2qb"
func
arith
scf
memref
tensor
math
builtin types
attributes
regions
SSA values
```

but do not use any of these merely because they exist.

Choose them based on semantic requirements.

The representation must preserve the information required by the semantic contract.

---

# 14. The canonical representation must be inspectable

Produce an artifact that a developer can inspect.

For example:

```text id="e5c8qw"
golden_path.semantic
golden_path.mlir
```

or whatever filenames fit the existing repository conventions.

The MLIR artifact should be readable by a human.

It should be possible to identify:

* the entity;
* its relevant semantic identity/type information;
* state;
* transformation;
* relevant constraints/context;
* observation boundary.

Do not hide the semantic model entirely behind opaque generated code.

---

# 15. Establish representation verification

The milestone is not complete merely because MLIR parses.

Demonstrate that the representation preserves the semantic contract.

At minimum verify:

```text id="k9v4za"
Semantic Entity Definition
        ↓
Canonical Representation
```

preserves:

* identity;
* entity-definition identity;
* state structure;
* transformation boundary;
* relevant constraints;
* relevant context;
* observation semantics.

Where exact representation equivalence is impossible or inappropriate, define and test semantic correspondence.

Distinguish:

```text
semantic equivalence
representation equivalence
execution equivalence
```

---

# 16. Execute the represented computation if reasonably possible

If existing MLIR tooling and the current architecture permit it without creating a large compiler subsystem, lower and execute the canonical representation.

The desired progression is:

```text id="p7x2nv"
Semantic Program
      ↓
Lean-verified semantics
      ↓
Mojo implementation
      ↓
Reference Executor
      ↓
Canonical MLIR
      ↓
MLIR verification
      ↓
Lowering
      ↓
Execution
      ↓
Observation
```

If complete lowering/execution cannot reasonably be achieved within this milestone, do not fabricate it.

Instead produce:

```text
verified canonical MLIR representation
```

and document precisely what remains.

Do not build a large lowering framework merely to satisfy a milestone checkbox.

---

# 17. Do not create a custom SCR dialect unless forced by evidence

This remains an explicit architectural constraint.

Do not introduce:

```text
scr.entity
scr.entity_type
scr.state
scr.relationship
scr.set
scr.increment
scr.emit
scr.observe
```

simply because they are convenient.

A custom operation/type is justified only if you can demonstrate:

```text
existing MLIR representation
        ↓
semantic information is lost
        ↓
required invariant/contract cannot be preserved
```

If that happens, document:

1. semantic concept;
2. missing representation capability;
3. why existing MLIR is insufficient;
4. minimum required custom construct;
5. semantic contract;
6. verification requirements;
7. lowering requirements;
8. runtime meaning.

Only then introduce the minimum custom construct.

---

# 18. Produce a notable milestone artifact

This milestone should leave behind a clear demonstration.

Create an appropriate directory under:

```text
program_increments/v0.0.1/
```

and include whatever artifacts fit the repository's conventions.

At minimum the result should make it possible to inspect:

```text id="z8q3sw"
1. Semantic Entity Definition
2. Semantic Entity Instance
3. Lean formalisation
4. Mojo implementation
5. Reference Executor execution
6. Mojo ↔ Reference equivalence test
7. Canonical semantic program
8. Canonical representation
9. Representation verification
10. Verification report
```

This is intended to be the first artifact that demonstrates SCR as a **semantic compilation architecture**, rather than merely a verified semantic library.

---

# 19. Create the next milestone report

Create:

```text
program_increments/v0.0.1/reports/004/
```

using repository naming conventions.

The report should be titled appropriately around:

> **Semantic Entity Compilation / Canonical Representation**

Document:

### Specification

* final Entity Definition semantics;
* Entity Instance semantics;
* semantic program definition.

### Formal Verification

* Lean definitions;
* theorem/property additions;
* verification results.

### Mojo

* implementation;
* tests;
* semantic behaviour.

### Reference Executor

* implementation;
* execution;
* test results.

### Equivalence

* exact semantic equivalence tests;
* results.

### Representation

* representation requirements;
* chosen representation;
* rejected alternatives;
* rationale.

### MLIR

* canonical artifact;
* dialects used;
* semantic information preserved;
* verification results.

### Execution

If achieved:

* lowering;
* provider;
* execution;
* observation.

If not achieved:

* exact remaining boundary;
* why it remains;
* what is required next.

### Custom Dialect Decision

Explicitly state:

```text
No custom SCR dialect required
```

if standard MLIR was sufficient.

Otherwise document exactly what forced the introduction.

---

# 20. Acceptance criteria

The milestone is complete when all applicable criteria below are satisfied.

## Semantic

* [ ] Entity Definition semantics are explicit.
* [ ] Entity Instance semantics are explicit.
* [ ] Identity remains independent.
* [ ] State remains authoritative.
* [ ] Context is semantically operative.
* [ ] Observation is non-mutating.
* [ ] The canonical semantic program is defined.

## Lean

* [ ] Canonical entity program is represented.
* [ ] Relevant semantic validity is formally established.
* [ ] Required invariants are proved.
* [ ] `lake build SCRFormal` passes.

## Mojo

* [ ] Canonical entity program executes.
* [ ] Entity Definition is represented.
* [ ] Entity Instance is represented.
* [ ] State and transformation are represented.
* [ ] Context and observation behave correctly.

## Reference Executor

* [ ] Canonical semantic program executes.
* [ ] Expected semantic result is established.

## Equivalence

* [ ] Mojo and Reference Executor execute equivalent semantic input.
* [ ] Their semantic results are equivalent.
* [ ] Entity Definition / Entity Instance behaviour is included where applicable.

## Representation

* [ ] Representation requirements are explicitly documented.
* [ ] Canonical representation exists.
* [ ] Semantic information required by the contract survives representation.
* [ ] Representation is inspectable.
* [ ] MLIR verification succeeds.

## Architecture

* [ ] No witness operation has been accidentally promoted to a fundamental SCR semantic primitive.
* [ ] No custom MLIR dialect has been introduced without evidence.
* [ ] Semantic definitions remain independent of MLIR.
* [ ] Physical representation remains subordinate to semantic meaning.

---

# 21. Definition of the milestone's success

The milestone should allow us to demonstrate something materially stronger than before:

```text id="s2p9kw"
              SEMANTIC FIELD
                    │
                    ▼
           ENTITY DEFINITION
                    │
                    ▼
            ENTITY INSTANCE
                    │
             ┌──────┴──────┐
             ▼             ▼
          IDENTITY       STATE
             │             │
             └──────┬──────┘
                    ▼
             TRANSFORMATION
                    │
             CONTEXT + CONSTRAINTS
                    │
                    ▼
              NEW STATE
                    │
                    ▼
               OBSERVATION
                    │
                    ▼
          SEMANTIC RESULT
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
   Reference Executor         Mojo
        │                       │
        └───────────┬───────────┘
                    ▼
           SEMANTIC EQUIVALENCE
                    │
                    ▼
              CANONICAL MLIR
                    │
                    ▼
          REPRESENTATION VERIFIED
```

The final artifact should therefore demonstrate:

> **A semantic entity can be defined, instantiated, transformed, observed, formally constrained, implemented in Mojo, reproduced by the Reference Executor, compared semantically, and represented computationally without making the representation the source of its meaning.**

That is the milestone we are trying to achieve.

---

# 22. Stop condition

Once the canonical semantic representation and its verification are complete, stop and report.

Do not automatically expand into:

* distributed execution;
* GPU;
* rendering;
* persistence;
* networking;
* scheduling;
* advanced simulation;
* custom runtime infrastructure;
* sophisticated entity schemas;
* generalized ontology;
* automatic provider selection.

The next architecture should be derived from what this milestone demonstrates.

---

# Governing rule

Throughout the work:

> **Engineer outward from the Semantic Field.**

> **Do not turn witnesses into ontology.**

> **Do not turn implementation conveniences into semantic primitives.**

> **Do not turn representation mechanisms into semantic definitions.**

> **Do not create custom MLIR constructs without demonstrating a semantic preservation requirement.**

> **Verification must precede expansion.**

And most importantly:

> **The objective is not merely to compile an Entity. The objective is to demonstrate that semantic meaning survives the transition from definition to verified computation to executable representation.**
