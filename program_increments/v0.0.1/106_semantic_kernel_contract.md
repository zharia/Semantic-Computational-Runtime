# 106 — Semantic Kernel Contract

**Document:** `106_semantic_kernel_contract.md`
**Version:** 1.0.0
**Status:** Draft
**Program Increment:** `v0.0.1`
**Created:** 2026-09-06
**Normative:** Yes

---

# 1. Purpose

This document defines the minimum semantic kernel required for the Semantic Computational Runtime (SCR) Golden Path.

The purpose of the Semantic Kernel is to establish the smallest coherent set of semantic primitives and relationships from which executable SCR computation can be constructed.

The Semantic Kernel is intentionally small.

It is not intended to define the complete SCR architecture.

It does not define:

* a programming language;
* an object-oriented runtime;
* a memory model;
* a custom MLIR dialect;
* a scheduler;
* a renderer;
* a database;
* a distributed execution model;
* a physical resource model;
* a particular storage representation.

Instead, it defines the semantic foundation upon which those mechanisms may subsequently be built.

The governing principle is:

> **Engineer outward from the Semantic Field.**

The Semantic Kernel therefore establishes semantic structure before implementation representation.

---

# 2. Relationship to Previous Documents

This document is subordinate to the normative SCR semantic specifications and implements the requirements established by:

```text
104_golden-path.md
105_gp_implementation_contract.md
```

The relationship is:

```text
Semantic Specifications
        ↓
104 — Golden Path
        ↓
105 — Implementation & Verification Contract
        ↓
106 — Semantic Kernel Contract
        ↓
Lean Formalisation
        ↓
Mojo Implementation
        ↓
Reference Executor
        ↓
MLIR / Runtime
```

`104` defines what the Golden Path must demonstrate.

`105` defines how implementation must be constrained.

`106` defines the minimum semantic structure that the implementation must establish.

---

# 3. Semantic Kernel Principle

The Semantic Kernel SHALL be understood as the smallest semantic substrate capable of expressing:

1. identity;
2. entities;
3. values;
4. relationships;
5. state;
6. transformations;
7. constraints;
8. context;
9. observation.

These primitives are not necessarily separate runtime objects.

They are semantic categories.

An implementation MAY represent multiple semantic categories using one physical structure provided that their semantic distinctions remain recoverable where required by the contract.

---

# 4. Semantic Field

The Semantic Kernel exists within the Semantic Field.

The Semantic Field is conceptually represented as:

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

For the Semantic Kernel, `M` is intentionally treated as a downstream concern.

The kernel establishes the semantic components:

```text
E
R
T
C
S
K
```

before selecting their physical manifestation.

The tuple representation is conceptual.

It MUST NOT be interpreted as requiring a tuple, struct, class, graph, hypergraph, database, or other specific implementation.

---

# 5. Semantic Kernel Graph

The minimum conceptual relationship structure is:

```text
Semantic Field
│
├── Entity
│   └── Identity
│
├── Value
│
├── Relationship
│
├── State
│
├── Transformation
│
├── Constraint
│
├── Context
│
└── Observation
```

The primary relationships are:

```text
Entity
 ├── has Identity
 ├── participates in Relationship
 ├── has State
 └── may be observed

Transformation
 ├── consumes semantic State
 ├── produces semantic State
 ├── operates within Context
 └── is constrained by Constraint

Value
 ├── participates in State
 └── participates in Relationship

Observation
 ├── reads semantic State
 └── produces an observation
```

These relationships constitute the minimum semantic topology required for the kernel.

---

# 6. Kernel Invariants

The following invariants are normative.

## SK-INV-001 — Semantic Primacy

Semantic meaning MUST be defined independently of physical representation.

---

## SK-INV-002 — Identity Independence

Semantic identity MUST NOT depend inherently upon memory address, pointer, allocation, array position, process identifier, or other physical implementation identity.

---

## SK-INV-003 — Representation Independence

A semantic entity MAY have multiple physical representations without thereby becoming multiple semantic entities.

---

## SK-INV-004 — Relationship Primacy

Relationships between semantic entities are semantic structure.

They MUST NOT be reduced conceptually to implementation pointers merely because pointers may be used as one manifestation.

---

## SK-INV-005 — Transformation Primacy

A computation is fundamentally a transformation of semantic state.

---

## SK-INV-006 — State Authority

Authoritative semantic state is distinct from runtime, renderer, storage, or transport state.

---

## SK-INV-007 — Constraint Preservation

A valid transformation MUST preserve the semantic constraints applicable to it.

---

## SK-INV-008 — Context Dependence

A semantic transformation MAY depend upon context.

Context MUST therefore be representable independently of incidental implementation state.

---

## SK-INV-009 — Observation Independence

Observation MUST NOT mutate authoritative semantic state unless the semantic contract explicitly defines observation as state-transforming.

---

## SK-INV-010 — Temporal Explicitness

Where computation is temporal, semantic time MUST be represented explicitly.

---

## SK-INV-011 — Implementation Derivation

Executable implementation MUST be derived from semantic contracts rather than independently defining equivalent semantics.

---

## SK-INV-012 — Formal Verification Boundary

Where a kernel property is formally specified, its verification MUST be mechanically checked by the formal system.

---

# 7. Semantic Entity

An **Entity** is a semantically identifiable participant in the Semantic Field.

An entity may represent:

* an object;
* an actor;
* a process;
* a resource;
* a region;
* a value-bearing structure;
* a simulated object;
* a logical component;
* another semantically distinguishable participant.

An entity is not defined by its physical representation.

The minimum semantic requirement is that an entity possess or participate in an identity relation sufficient to distinguish it where required.

Conceptually:

```text
Entity
  │
  └── Identity
```

---

# 8. Semantic Identity

Identity establishes persistence of semantic reference.

An identity MUST remain conceptually distinct from physical location.

The following are not inherently semantic identities:

```text
memory address
pointer
array index
object address
GPU handle
database row identifier
file offset
process-local allocation
```

Any of these MAY serve as an implementation representation of identity when the semantic contract permits it.

Identity MUST survive representation changes where persistence is semantically required.

Conceptually:

```text
Identity
   │
   ├── Representation A
   ├── Representation B
   ├── Representation C
   └── Representation D
```

without requiring:

```text
Representation A ≠ Representation B
```

at the semantic level.

---

# 9. Semantic Value

A **Value** is a semantic quantity participating in the field.

A value may represent:

* a number;
* a vector;
* a tensor;
* a symbolic value;
* a temporal quantity;
* a spatial quantity;
* a categorical value;
* a structured value;
* another semantically defined quantity.

A machine representation does not by itself establish semantic meaning.

For numeric values, semantic definition MAY include:

* domain;
* units;
* dimensionality;
* precision;
* accuracy;
* admissible error;
* range;
* overflow behaviour;
* special-value semantics;
* rounding;
* determinism.

Therefore:

```text
Semantic Value
      ↓
Value Contract
      ↓
Physical Representation
```

is the required conceptual direction.

Not:

```text
f32
 ↓
"meaning"
```

---

# 10. Semantic Relationship

A **Relationship** establishes semantic structure between entities, values, state, transformations, or other semantic elements.

Examples include:

```text
Entity A ──related-to──> Entity B

Entity ──has-value──> Value

Entity ──participates-in──> Transformation

State ──constrained-by──> Constraint
```

Relationships MUST be semantically distinguishable where their meaning affects computation.

The physical manifestation of a relationship MAY be:

* pointer;
* index;
* reference;
* table;
* edge;
* adjacency structure;
* message;
* identifier;
* memory offset;
* another mechanism.

The manifestation does not define the relationship's meaning.

---

# 11. Semantic State

A **State** is the authoritative semantic condition of some part of the Semantic Field at a particular semantic point.

A state MAY contain:

* entities;
* values;
* relationships;
* temporal information;
* contextual information;
* domain-specific structures.

A state transformation is conceptually:

```text
Sₜ ──Transformation──> Sₜ₊₁
```

The implementation MUST distinguish semantic state from incidental execution state.

Examples of incidental state include:

* allocator state;
* thread-local state;
* cache contents;
* renderer state;
* temporary buffers;
* machine registers;
* scheduler state.

These MAY contribute to execution but are not thereby semantic state.

---

# 12. State Transition

The fundamental computational operation of the kernel is state transformation.

Conceptually:

```text
Fₜ₊₁ = T(Fₜ, Cₜ)
```

where:

* `Fₜ` is the semantic field at time `t`;
* `T` is a semantic transformation;
* `Cₜ` is relevant context;
* `Fₜ₊₁` is the resulting semantic field.

For a restricted subsystem:

```text
Sₜ₊₁ = T(Sₜ, Cₜ)
```

may be sufficient.

The implementation MUST preserve the distinction between:

```text
semantic input
semantic transformation
semantic output
```

and:

```text
physical input
machine instructions
physical output
```

---

# 13. Semantic Transformation

A **Transformation** is a semantically defined operation that maps one valid semantic state into another.

A transformation has at minimum:

```text
input state
output state
applicable context
applicable constraints
```

Conceptually:

```text
T : (State, Context) → State
```

A transformation MAY additionally possess:

* parameters;
* preconditions;
* postconditions;
* invariants;
* temporal properties;
* provenance;
* determinism requirements;
* admissible error.

A physical implementation of a transformation MUST preserve the semantic contract.

---

# 14. Semantic Contract

A **Semantic Contract** specifies the obligations associated with a semantic entity, value, state, relationship, or transformation.

A contract MAY contain:

```text
Identity
Preconditions
Postconditions
Invariants
Constraints
Value requirements
Temporal requirements
Determinism requirements
Observation requirements
```

A transformation MUST NOT be considered semantically complete merely because an implementation can execute it.

Its contract must define what execution means.

---

# 15. Constraint

A **Constraint** limits the valid semantic configurations, transformations, or representations of the field.

Examples include:

```text
dt > 0

position ∈ SpatialDomain

velocity has compatible dimensions

identity remains persistent

state satisfies invariant I

numeric error ≤ ε
```

Constraints MUST be expressed semantically before being enforced physically.

A lower layer MAY enforce a constraint when that enforcement is sound with respect to the semantic definition.

---

# 16. Context

A **Context** is semantic information relevant to interpretation or transformation.

Context MAY include:

* temporal context;
* spatial context;
* environmental state;
* execution-independent configuration;
* domain state;
* relationships;
* constraints;
* provenance.

Context MUST NOT be conflated automatically with:

* process environment;
* operating-system environment variables;
* thread-local state;
* runtime configuration;
* global variables.

Those mechanisms MAY manifest contextual information but do not define semantic context by themselves.

---

# 17. Time

Time is a semantic dimension whenever temporal behaviour is part of the computation.

The kernel MUST distinguish semantic time from:

```text
wall-clock time
frame time
processing time
scheduling time
latency
```

For temporal computation, a semantic state MAY contain:

```text
simulation_time
```

or another semantically defined temporal quantity.

A machine representation such as `f32` or `f64` is a representation choice.

It does not define the semantic meaning of time.

---

# 18. Observation

An **Observation** is a semantic read of state.

Conceptually:

```text
State
  │
  └──→ Observation
```

Observation MUST preserve the distinction between:

```text
authoritative semantic state
```

and:

```text
observed representation
```

An observation MAY produce:

* structured data;
* a snapshot;
* a trace;
* a stream;
* metrics;
* a render state;
* another projection.

Observation MUST NOT mutate authoritative state unless explicitly specified as part of the semantic model.

---

# 19. Manifestation Boundary

The Semantic Kernel terminates conceptually before physical manifestation.

The progression is:

```text
Semantic Meaning
      ↓
Semantic Structure
      ↓
Semantic Transformation
      ↓
Semantic State
      ↓
Observation
      ↓
Physical Manifestation
```

Examples of manifestation include:

* memory layout;
* MLIR;
* LLVM;
* CPU execution;
* GPU resources;
* storage;
* network messages;
* rendered geometry.

The kernel MUST NOT depend semantically upon any particular manifestation.

---

# 20. Minimal Executable Kernel

The minimum executable kernel SHOULD be capable of representing the following:

```text
Entity
Identity
Value
Relationship
State
Transformation
Constraint
Context
Observation
```

A minimal transformation SHOULD be expressible as:

```text
transform(state, context) → state'
```

A minimal observation SHOULD be expressible as:

```text
observe(state) → observation
```

The kernel does not require a universal runtime object for each of these categories.

---

# 21. Canonical Witness

The v0.0.1 Golden Path uses a particle simulation as its canonical witness.

Conceptually:

```text
Particle
├── identity
├── position
└── velocity
```

and:

```text
SimulationState
├── simulation_time
└── particles
```

with transformation:

```text
position' = position + velocity × dt
```

and operation:

```text
advance(state, dt) → state'
```

This witness exercises:

* identity;
* entities;
* values;
* relationships;
* state;
* transformation;
* constraints;
* time;
* observation.

It does not define the Semantic Kernel.

---

# 22. Formalisation Requirements

The Semantic Kernel MUST be suitable for formalisation in Lean.

The initial Lean model SHOULD establish at least:

1. semantic identity;
2. entities;
3. values;
4. state;
5. relationships;
6. transformations;
7. constraints;
8. observation;
9. state transition;
10. relevant invariants.

The formalisation SHOULD remain abstract enough that it does not prematurely encode:

* Mojo implementation details;
* memory layout;
* MLIR syntax;
* LLVM details;
* CPU architecture;
* renderer implementation.

The Lean model is a formal semantic model, not a physical runtime model.

---

# 23. Formal Properties

The initial formal verification target SHOULD include properties of the form:

```text
Identity preservation
State validity
Constraint preservation
Transformation validity
Observation non-interference
Temporal consistency
Determinism where specified
```

The exact theorem statements SHALL be derived from the authoritative semantic definitions.

The implementation MUST NOT invent theorem statements merely to make the existing implementation easier to prove.

---

# 24. Executable Implementation Requirements

The Mojo implementation MUST provide an executable manifestation of the Semantic Kernel.

The implementation SHOULD expose concepts corresponding to:

```text
Entity
Identity
Value
State
Transformation
Observation
```

but the exact Mojo API is intentionally unspecified by this document.

The implementation MAY use:

* structs;
* traits;
* functions;
* generics;
* collections;
* arrays;
* tensors;
* other appropriate Mojo mechanisms.

No specific implementation mechanism is normative.

---

# 25. Reference Executor Requirements

The Reference Executor MUST provide a simple executable interpretation of the semantic kernel sufficient to validate canonical transformations.

It SHOULD prioritise semantic clarity over performance.

The Reference Executor SHOULD make semantic state inspectable.

It SHOULD permit comparison such as:

```text
Reference State
      ↕
Mojo State
```

using semantic equivalence rather than physical representation equality.

---

# 26. Equivalence Boundary

The kernel establishes three distinct notions:

### Semantic Equality

Two structures represent the same semantic state.

### Representation Equality

Two structures have the same physical representation.

### Execution Equality

Two executions exhibit equivalent semantic behaviour.

These notions MUST NOT be conflated.

For example:

```text
Representation A ≠ Representation B
```

does not imply:

```text
Semantic State A ≠ Semantic State B
```

The Golden Path primarily requires semantic equivalence.

---

# 27. Numeric Semantics

Numeric representations are subordinate to semantic numeric contracts.

For example:

```text
f32
f64
i32
i64
```

MAY be selected as physical representations.

They MUST NOT automatically define:

* unit;
* dimensionality;
* accuracy;
* admissible error;
* deterministic semantics;
* overflow behaviour.

If numeric representation affects semantic correctness, the relevant property MUST be included in the semantic contract and, where appropriate, formal verification.

---

# 28. Determinism

If a transformation is specified as deterministic, equivalent executions MUST satisfy the applicable semantic determinism contract.

The implementation MUST consider:

* evaluation ordering;
* floating-point behaviour;
* parallel reduction;
* provider substitution;
* random state;
* unspecified ordering;
* concurrency.

Exact bitwise equality is not automatically required if the semantic contract instead specifies an admissible equivalence relation.

---

# 29. Kernel and MLIR

The Semantic Kernel does not define a custom MLIR dialect.

The kernel SHALL first be established semantically and formally.

Only then should its representation in MLIR be considered.

The preferred progression is:

```text
Semantic Kernel
      ↓
Lean Model
      ↓
Mojo Implementation
      ↓
Representation Requirements
      ↓
Existing MLIR
      ↓
Custom MLIR only if necessary
```

The existence of a kernel concept does not imply the existence of a corresponding MLIR operation or type.

---

# 30. Kernel and Runtime

The runtime is downstream from the Semantic Kernel.

The runtime MAY provide mechanisms for:

* allocation;
* execution;
* scheduling;
* resource management;
* provider selection;
* communication;
* persistence;
* observation.

None of these mechanisms defines the semantic kernel.

The runtime MUST consume or manifest semantic requirements rather than silently replacing them.

---

# 31. Kernel Completeness Criterion

The Semantic Kernel is complete for v0.0.1 when the following statement can be demonstrated:

> A semantic entity can possess persistent semantic identity, participate in semantic relationships, contain or reference semantic values, exist within semantic state, participate in a constrained transformation, be interpreted within context and time where required, and produce an observation without requiring dependence upon a particular physical representation.

This is the minimum semantic capability required to proceed into the executable Golden Path.

---

# 32. Kernel Non-Goals

The Semantic Kernel does NOT attempt to define:

* the complete Semantic Field;
* universal domain ontology;
* universal type theory;
* complete graph theory;
* complete topology;
* distributed semantics;
* networking semantics;
* storage semantics;
* rendering semantics;
* hardware abstraction;
* scheduling theory;
* resource allocation algorithms;
* GPU execution;
* accelerator execution;
* machine learning;
* neural computation;
* complete numerical analysis;
* general-purpose programming language semantics.

These may be built outward from the kernel where justified.

---

# 33. Implementation Decision Rule

For any proposed kernel primitive, ask:

### 1. What semantic concept does it represent?

### 2. Is that concept already defined by the normative specification?

### 3. What entities does it relate?

### 4. What state does it participate in?

### 5. What transformations does it enable?

### 6. What constraints apply?

### 7. What properties require formal verification?

### 8. What is the smallest representation capable of expressing it?

### 9. Can it be represented without committing to physical implementation?

### 10. How will its semantic behaviour be tested?

If these questions cannot be answered, the primitive SHOULD NOT yet become part of the kernel.

---

# 34. Dependency Direction

The Semantic Kernel MUST maintain the following dependency direction:

```text
Semantic Field
      ↓
Kernel Semantics
      ↓
Formal Model
      ↓
Implementation
      ↓
Representation
      ↓
Execution
      ↓
Observation
```

The following reverse dependency is prohibited as an architectural foundation:

```text
Hardware
      ↓
Runtime
      ↓
Representation
      ↓
"Semantic Kernel"
```

Physical implementation may constrain what can be efficiently manifested, but those constraints MUST NOT silently redefine semantic meaning.

---

# 35. Verification and Evidence

Each kernel invariant SHOULD eventually have an evidence classification:

```text
Specified
Formalised
Formally Verified
Implemented
Unit Tested
Property Tested
Reference Tested
Executed
Observed
```

These statuses MUST remain distinct.

For example:

```text
Specified + Implemented
```

does not mean:

```text
Formally Verified
```

Likewise:

```text
Formally Verified
```

does not mean:

```text
Physically Executed
```

The Golden Path requires the appropriate evidence at each boundary.

---

# 36. Initial Kernel Verification Matrix

The initial implementation SHOULD maintain a matrix similar to:

| Kernel Concept | Specification | Lean | Mojo | Reference | Execution |
| -------------- | ------------: | ---: | ---: | --------: | --------: |
| Entity         |             ✓ |    ✓ |    ✓ |         ✓ |         ✓ |
| Identity       |             ✓ |    ✓ |    ✓ |         ✓ |         ✓ |
| Value          |             ✓ |    ✓ |    ✓ |         ✓ |         ✓ |
| Relationship   |             ✓ |    ✓ |    ✓ |         ✓ |         ✓ |
| State          |             ✓ |    ✓ |    ✓ |         ✓ |         ✓ |
| Transformation |             ✓ |    ✓ |    ✓ |         ✓ |         ✓ |
| Constraint     |             ✓ |    ✓ |    ✓ |         ✓ |         ✓ |
| Context        |             ✓ |    ✓ |    ✓ |         ✓ |         ✓ |
| Time           |             ✓ |    ✓ |    ✓ |         ✓ |         ✓ |
| Observation    |             ✓ |    ✓ |    ✓ |         ✓ |         ✓ |

A checkmark SHALL mean that actual evidence exists.

It MUST NOT mean merely that the component is planned.

---

# 37. Development Sequence

Implementation of the Semantic Kernel SHOULD proceed in this order:

```text
1. Reconcile existing semantic specifications
        ↓
2. Identify authoritative definitions
        ↓
3. Formalise kernel concepts in Lean
        ↓
4. Prove initial kernel invariants
        ↓
5. Implement kernel in Mojo
        ↓
6. Unit test Mojo implementation
        ↓
7. Implement Reference Executor
        ↓
8. Establish semantic equivalence
        ↓
9. Identify representation requirements
        ↓
10. Establish MLIR representation
        ↓
11. Lower and execute
        ↓
12. Complete Golden Path
```

No MLIR dialect should be introduced merely because it appears at step 10.

The representation must be derived from the actual requirements discovered through steps 1–9.

---

# 38. Exit Criteria

The Semantic Kernel phase is complete when all of the following are true:

### Semantic

* the kernel concepts are explicitly defined;
* relationships between kernel concepts are explicit;
* semantic authority is unambiguous;
* identity is representation-independent;
* semantic state is distinguished from physical execution state.

### Formal

* the kernel is represented in Lean;
* relevant invariants are stated;
* Lean successfully checks the applicable proofs.

### Implementation

* the kernel has an executable Mojo manifestation;
* implementation behaviour is tested;
* implementation does not silently introduce competing semantics.

### Reference

* a Reference Executor exists;
* canonical state can be constructed;
* canonical transformations can be executed;
* semantic results can be inspected.

### Equivalence

* Mojo and Reference Executor results can be compared;
* equivalence is defined semantically;
* canonical equivalence tests pass.

### Architecture

* no unnecessary custom MLIR dialect has been introduced;
* no renderer or runtime component has become semantic authority;
* the kernel remains independent of physical execution substrate.

---

# 39. Relationship to the Golden Path

Once the Semantic Kernel satisfies these criteria, it provides the semantic foundation for the Golden Path:

```text
Semantic Kernel
      ↓
Semantic Contract
      ↓
Formal Verification
      ↓
Mojo Implementation
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
Execution
      ↓
Semantic State
      ↓
Observation
      ↓
Manifestation
```

The Golden Path therefore begins not with MLIR or the runtime.

It begins with a verified semantic kernel.

---

# 40. Final Proposition

The Semantic Kernel establishes the minimum claim required for SCR to proceed from architectural theory to executable implementation:

> **Semantic entities possessing identity, values, relationships, state, transformations, constraints, context, and observations can be defined independently of physical representation, formally reasoned about, implemented, executed, and observed while preserving semantic authority across the implementation boundary.**

This is the foundation from which the remainder of SCR SHALL be engineered outward.

The kernel is deliberately small.

Its purpose is not to contain the whole runtime.

Its purpose is to establish the semantic origin from which the runtime can legitimately be derived.

> **The Semantic Field is primary. The Semantic Kernel is its minimal executable foundation. Everything below it is manifestation.**
