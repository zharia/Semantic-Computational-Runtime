---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-CORE-IR
name: Intermediate Representation

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-CORE

authority: SCR
domain: semantic-library
classification: intermediate-representation
---

# SCR Intermediate Representation

## 1. Definition

The Intermediate Representation (IR) domain defines the computational representation of semantic structures at an abstraction level suitable for analysis, transformation, verification, composition, and progressive lowering toward execution.

An IR is a **representation of semantic meaning for computation**.

It is not itself the semantic definition of the represented domain.

The IR therefore occupies the boundary between:

```text
Semantic Definition
        │
        ▼
Semantic Model
        │
        ▼
Intermediate Representation
        │
        ▼
Transformation
        │
        ▼
Lowering
        │
        ▼
Provider / Execution
```

The IR domain defines the structures necessary to express a semantic domain computationally while preserving the semantic properties required by its contract.

---

# 2. Purpose

The purpose of the IR domain is to provide a formal computational representation through which semantic concepts can be:

* constructed;
* inspected;
* validated;
* analyzed;
* transformed;
* composed;
* decomposed;
* optimized;
* specialized;
* lowered;
* mapped to providers;
* compiled;
* executed.

The IR provides the bridge between semantic specification and executable computation.

---

# 3. Fundamental Principle

> **IR represents meaning; it does not define meaning.**

The normative meaning of a concept MUST originate from its semantic domain definition.

The IR MUST represent that meaning faithfully enough to support the operations required by the domain.

An implementation detail MUST NOT silently become a semantic requirement merely because it appears in the IR.

---

# 4. Semantic Position

The IR domain is subordinate to the semantic domain whose concepts it represents.

For Core:

```text
SCR Core
   │
   ├── Semantic Model
   │
   └── IR
        │
        ├── Types
        ├── Attributes
        ├── Operations
        ├── Regions
        ├── Interfaces
        ├── Traits
        └── Verification
```

For a specialized domain:

```text
Domain Definition
       │
       ▼
Domain Semantic Model
       │
       ▼
SCR Semantic MLIR
       │
       ▼
905_Transforms
       │
       ▼
903_Lowering
       │
       ▼
904_Providers
```

The IR MUST NOT become an independent semantic authority.

---

# 5. Scope

The IR domain includes the semantic representation of:

* IR entities;
* IR types;
* IR values;
* IR attributes;
* IR operations;
* IR regions;
* IR blocks;
* IR control-flow relationships;
* IR data-flow relationships;
* IR symbols;
* IR references;
* IR properties;
* IR interfaces;
* IR traits;
* IR constraints;
* IR verification;
* IR effects;
* IR dependencies;
* IR invariants;
* IR metadata;
* IR provenance;
* IR versioning;
* IR construction;
* IR transformation boundaries;
* IR legality;
* IR representation equivalence.

The exact constructs required by a particular semantic domain are determined by that domain's definition.

---

# 6. IR Semantic Model

An IR can be conceptually represented as:

```text
IR = (T, V, A, O, R, B, D, C, I, P, Vfy)
```

where:

* `T` = types;
* `V` = values;
* `A` = attributes;
* `O` = operations;
* `R` = regions;
* `B` = blocks;
* `D` = data/control dependencies;
* `C` = constraints;
* `I` = interfaces and capabilities;
* `P` = properties and provenance;
* `Vfy` = verification rules.

This is a conceptual model.

It does not prescribe a particular implementation technology.

---

# 7. Relationship to Semantic Definition

The semantic definition answers:

> What does this concept mean?

The IR answers:

> How can this meaning be represented as computational structure?

Therefore:

```text
101_definition.md
        │
        │ defines
        ▼
Semantic Meaning
        │
        │ represented by
        ▼
IR
```

The IR MUST NOT introduce semantic behavior that is absent from the domain definition unless that behavior is explicitly identified as an implementation-level property.

---

# 8. Relationship to Domain SCR Semantic MLIR

Every semantic domain MAY define a domain-specific SCR Semantic MLIR.

For example:

```text
301_Field/IR
302_Geometry/IR
303_Topology/IR
401_Morphology/IR
501_Physics/IR
502_Dynamics/IR
503_Simulation/IR
```

A domain-specific MLIR dialect SHOULD contain only concepts necessary to computationally represent that domain.

A domain-specific MLIR dialect MAY reuse:

* Core IR concepts;
* other domain-specific MLIR dialects;
* MLIR builtin concepts;
* established MLIR dialects;
* shared interfaces.

A domain-specific MLIR dialect MUST NOT duplicate an existing semantic concept merely because a separate implementation representation is convenient.

---

# 9. IR Does Not Imply a Dialect

An SCR semantic domain MUST NOT be required to have exactly one MLIR dialect.

A domain-specific MLIR dialect MAY be realized through:

1. an SCR-specific MLIR dialect;
2. several cooperating MLIR dialects;
3. existing MLIR dialects;
4. a combination of SCR and existing dialects;
5. another MLIR representation where appropriate.

Conceptually:

```text
             SCR Semantic MLIR
                │
       ┌────────┼────────┐
       ▼        ▼        ▼
   SCR Dialect Existing  Composite
                Dialects   IR
```

The semantic domain determines the required representation.

MLIR provides a possible realization mechanism.

---

# 10. MLIR Relationship

SCR is built on MLIR.

MLIR provides extensible mechanisms for representing operations, attributes, types, regions, dialects, interfaces, and related computational structures.

SCR SHOULD therefore use MLIR mechanisms wherever they satisfy SCR's semantic requirements.

The relationship is:

```text
SCR Semantic MLIR
       │
       ▼
MLIR
       │
       ├── SCR Dialects
       ├── Existing MLIR Dialects
       └── Composed Dialects
```

MLIR remains the compiler infrastructure.

SCR remains authoritative over its semantic contracts.

---

# 11. Types

IR types represent semantic categories of values or entities at the IR level.

A type MAY encode:

* semantic kind;
* shape;
* dimensionality;
* domain;
* constraints;
* units;
* precision;
* ownership;
* effects;
* capabilities;
* representation properties.

An IR type MUST NOT be treated as merely a programming-language type.

For example:

```text
!scr.field
```

may represent a semantic Field type even though its implementation may ultimately lower to:

```text
tensor
memref
llvm.struct
gpu.buffer
```

The lower-level representation MUST NOT redefine the semantic meaning of the Field.

MLIR provides an extensible type system for such domain-specific abstractions.

---

# 12. Values

IR values represent computational values flowing between IR constructs.

Values MAY represent:

* semantic data;
* intermediate results;
* references;
* state;
* handles;
* resources;
* tokens;
* control information.

The meaning of a value is determined by its type and the semantics of the operations producing and consuming it.

---

# 13. Attributes

IR attributes represent statically known or structurally associated information.

Attributes MAY describe:

* configuration;
* constants;
* metadata;
* symbolic parameters;
* constraints;
* semantic properties;
* operation parameters;
* domain-specific declarations.

An attribute MUST NOT be used to encode information that should instead be represented as a runtime value.

MLIR explicitly distinguishes attributes from runtime SSA values and provides extensible dialect attributes.

---

# 14. Operations

An IR operation represents a semantic computational action at the IR abstraction level.

An operation SHOULD define:

* operands;
* results;
* attributes;
* properties;
* regions where applicable;
* effects;
* constraints;
* verification rules;
* interfaces;
* traits;
* semantic description.

For example:

```text
field.evaluate
field.interpolate
field.integrate
```

could represent operations within a Field IR.

The operation name alone is insufficient to define its semantics.

Its semantic contract remains anchored in the corresponding domain definition.

MLIR provides operation definitions, operands, results, attributes, properties, traits, and constraints as first-class IR constructs.

---

# 15. Regions

An IR region represents a structured computational region associated with an operation or semantic construct.

Regions MAY express:

* nested computation;
* control flow;
* scopes;
* transformations;
* reductions;
* callbacks;
* bodies;
* structured algorithms.

A region MUST only be used where its structural semantics are meaningful.

---

# 16. Blocks

Blocks represent ordered computational regions within an IR region.

Blocks MAY express:

* sequences;
* control-flow destinations;
* computation boundaries;
* dominance relationships;
* structured execution.

The use of blocks MUST preserve the semantic control/data dependencies required by the domain.

---

# 17. Data Flow

IR SHOULD make meaningful data dependencies explicit.

Conceptually:

```text
Value A ──► Operation X ──► Value B
                         │
                         ▼
                     Operation Y
```

Data flow MUST NOT be confused with:

* physical memory layout;
* network transport;
* execution scheduling;
* storage location.

Those may be derived later.

---

# 18. Control Flow

Where a domain requires control flow, the IR MAY represent:

* sequencing;
* branching;
* looping;
* conditional execution;
* structured regions;
* asynchronous dependencies.

Control flow is a computational representation.

It MUST NOT automatically be interpreted as the semantic model of the represented domain.

---

# 19. Symbols and References

IR MAY provide symbolic references to:

* functions;
* operations;
* entities;
* regions;
* types;
* external resources;
* semantic identities.

A symbolic reference MUST preserve its intended semantic scope.

Semantic identity and IR symbol identity MUST remain distinguishable.

---

# 20. Properties

IR properties represent inherent information associated with an IR construct.

Properties MAY be used where information is intrinsic to an operation or other IR entity rather than merely discardable metadata.

Where MLIR properties are used, their semantics MUST remain subordinate to the SCR operation contract. MLIR supports operation properties as first-class inherent data.

---

# 21. Interfaces

Interfaces provide generic capabilities through which transformations and analyses can reason about IR constructs without requiring knowledge of every concrete operation.

SCR SHOULD use interfaces for capabilities such as:

```text
Composable
Deterministic
Differentiable
Dynamical
Integrable
Learnable
Observable
Optimizable
Parallelizable
Renderable
Spatial
Stateful
Stateless
Stochastic
Streamable
Temporal
Transformable
Vectorizable
```

Reusable cross-domain semantic interfaces belong under:

```text
902_Interfaces/
```

A domain's `IR/Interfaces/` SHOULD contain only:

* IR-specific interface definitions;
* domain-specific interface implementations;
* IR-level adapters.

MLIR interfaces are explicitly intended to decouple transformations and analyses from knowledge of individual concrete operations or dialects.

---

# 22. Traits

Traits describe reusable structural or behavioral properties of IR constructs.

Traits MAY encode:

* structural constraints;
* side effects;
* shape relationships;
* terminator requirements;
* region properties;
* operand/result relationships.

Traits SHOULD be used where a property is shared across multiple operations.

A trait MUST NOT be used as a substitute for a semantic domain definition.

---

# 23. Verification

Every IR MUST provide verification sufficient to establish that an IR instance satisfies its declared structural and semantic constraints.

Verification MAY include:

* type correctness;
* operand/result compatibility;
* attribute validity;
* region validity;
* structural constraints;
* semantic invariants;
* capability requirements;
* resource requirements;
* representation constraints.

Verification SHOULD fail as early as practical.

An IR that cannot satisfy its own declared invariants MUST be rejected.

---

# 24. Semantic Verification

IR verification has two distinct responsibilities:

### Structural Verification

Determines whether the IR is structurally well formed.

### Semantic Verification

Determines whether the IR expresses a valid instance of the semantic domain.

These MUST NOT be conflated.

```text
IR
 │
 ├── Structural Verification
 │
 └── Semantic Verification
```

---

# 25. IR Legality

An IR representation is legal when it satisfies the constraints applicable to its abstraction level.

Legality MAY depend on:

* domain;
* operation;
* type;
* capabilities;
* transformation stage;
* target;
* provider;
* lowering requirements.

Legality MUST be explicit.

A transformation MUST NOT assume that an IR is legal merely because it can be parsed.

---

# 26. IR Invariants

Each domain-specific MLIR dialect MUST define its own domain-specific invariants.

The following Core IR invariants apply universally.

### IR-INV-001 — Semantic Anchoring

Every semantically meaningful IR construct MUST correspond to a defined semantic concept.

### IR-INV-002 — Semantic Primacy

The semantic definition remains authoritative over the IR.

### IR-INV-003 — Representation Independence

The meaning of an IR construct MUST NOT depend on its physical encoding.

### IR-INV-004 — Type Integrity

IR values MUST conform to their declared types.

### IR-INV-005 — Operation Integrity

Operations MUST satisfy their declared operand, result, attribute, property, region, and effect constraints.

### IR-INV-006 — Region Integrity

Regions MUST satisfy their declared structural and semantic requirements.

### IR-INV-007 — Reference Integrity

References MUST resolve according to their declared semantics.

### IR-INV-008 — Interface Integrity

Interface implementations MUST satisfy the contracts of the capabilities they claim to implement.

### IR-INV-009 — Verification Integrity

An IR MUST NOT be considered valid merely because it can be constructed.

### IR-INV-010 — Transformation Preservation

Valid transformations MUST preserve all semantic properties declared as invariant.

### IR-INV-011 — Lowering Preservation

Lowering MUST preserve the semantics required by the source contract.

### IR-INV-012 — Provider Independence

The IR MUST NOT encode unnecessary assumptions about a particular provider.

### IR-INV-013 — Hardware Independence

The Semantic MLIR MUST NOT require a particular hardware substrate unless the semantic contract explicitly requires one.

### IR-INV-014 — Explicit Effects

Semantically relevant side effects MUST be represented explicitly.

### IR-INV-015 — Determinism Explicitness

Deterministic, nondeterministic, and stochastic behavior MUST remain distinguishable.

### IR-INV-016 — Provenance Preservation

Required provenance MUST survive IR transformations.

### IR-INV-017 — Domain Boundary

An IR MUST NOT silently introduce semantics belonging to another domain.

### IR-INV-018 — Abstraction Integrity

An IR MUST remain at the abstraction level for which it is defined until an explicit transformation or lowering changes that level.

---

# 27. IR and Transformations

The IR is an input and output of transformations.

```text
IR₁
 │
 ▼
Transformation
 │
 ▼
IR₂
```

Transformations MAY:

* canonicalize;
* simplify;
* fuse;
* decompose;
* specialize;
* distribute;
* parallelize;
* tile;
* vectorize;
* differentiate;
* compose;
* decompose;
* change representation.

These transformation categories are represented in:

```text
905_Transforms/
```

The IR directory SHOULD define the structures upon which transformations operate.

It SHOULD NOT contain the general transformation framework itself.

---

# 28. IR and Lowering

Lowering is a specialized class of transformation that moves computation toward a lower abstraction or execution representation.

```text
High-Level SCR Semantic MLIR
        │
        ▼
    Lowering
        │
        ▼
MLIR Lower-Level Dialect
        │
        ▼
Target Representation
```

Lowering belongs primarily under:

```text
903_Lowering/
```

The distinction is:

```text
IR
    = representation

Transformation
    = change in representation or structure

Lowering
    = transformation toward a lower execution abstraction

Provider
    = realization mechanism
```

---

# 29. IR and Providers

Providers realize semantic computations.

The relationship is:

```text
Semantic Definition
        │
        ▼
SCR Semantic MLIR
        │
        ▼
Lowering / Transformation
        │
        ▼
Provider
        │
        ▼
Execution
```

Providers MUST NOT be embedded into the semantic meaning of the IR.

A provider MAY impose additional requirements on a particular lowering path.

---

# 30. IR and Hardware

IR SHOULD remain hardware-independent at semantic levels where hardware independence is part of the domain contract.

Hardware-specific representations MAY appear at lower IR levels.

For example:

```text
Field IR
   ↓
Tensor IR
   ↓
Linalg
   ↓
GPU
   ↓
LLVM
   ↓
Machine
```

The existence of a GPU-specific lowering MUST NOT imply that the original Field semantics are GPU-specific.

---

# 31. Progressive Abstraction

SCR Semantic MLIR is explicitly multi-level.

A concept MAY progress through:

```text
Semantic Concept
       ↓
SCR Semantic MLIR
       ↓
Generic Computational IR
       ↓
Target-Oriented IR
       ↓
Hardware IR
       ↓
Executable Representation
```

Different levels MAY coexist.

An IR level SHOULD preserve as much semantic information as practical until that information is no longer required.

---

# 32. Information Preservation

Lower-level representations often contain less semantic information than higher-level representations.

Therefore:

```text
High-Level IR
      │
      │ lowering
      ▼
Low-Level IR
```

MUST NOT be assumed reversible.

Where information is discarded, the transformation SHOULD make that loss explicit.

Where reversibility is required, sufficient metadata or provenance MUST be retained.

---

# 33. Canonicalization

An IR MAY have canonical forms.

Canonicalization MAY improve:

* equivalence checking;
* transformation;
* caching;
* comparison;
* reproducibility;
* optimization.

Canonicalization MUST NOT change semantic meaning.

Canonicalization transformations belong under:

```text
905_Transforms/Canonicalization/
```

unless the canonical form is intrinsic to the IR definition itself.

---

# 34. Composition

IRs MAY compose across domains.

For example:

```text
Field IR
    │
    ├── Geometry IR
    │
    ├── Topology IR
    │
    └── Dynamics IR
```

Cross-domain composition MUST use explicit contracts and interfaces.

A domain MUST NOT absorb another domain's semantics merely because its IR requires information from that domain.

---

# 35. Cross-Domain Interfaces

Cross-domain capabilities SHOULD be expressed through shared interfaces rather than duplicated domain-specific mechanisms.

For example:

```text
Field
   │
   └── implements Spatial

Geometry
   │
   └── implements Transformable

Dynamics
   │
   └── implements Dynamical

Simulation
   │
   └── implements Stateful
```

This permits generic transformations and analyses to operate across domains.

---

# 36. IR Documentation

Each IR construct SHOULD document:

* semantic purpose;
* relationship to the domain definition;
* operands;
* results;
* attributes;
* properties;
* regions;
* effects;
* constraints;
* invariants;
* interfaces;
* traits;
* verification;
* examples;
* lowering expectations.

MLIR's dialect infrastructure supports structured documentation for dialects and operations and can generate documentation from declarative definitions.

---

# 37. Expected IR Directory Structure

A domain MLIR dialect directory SHOULD follow a structure similar to:

```text
IR/
├── README.md
├── Types/
├── Attributes/
├── Operations/
├── Interfaces/
├── Traits/
├── Verification/
├── Dialect/
└── examples/
```

Not every domain requires every directory.

Empty structural directories MUST NOT be created merely to satisfy the template.

---

# 38. Dialect Directory

Where a domain defines an SCR-specific MLIR dialect, `Dialect/` MAY contain:

* dialect definition;
* registration;
* namespace;
* dialect-wide interfaces;
* dialect-wide verification;
* dialect documentation.

MLIR dialects are the standard mechanism for grouping and extending operations, types, and attributes.

A domain MAY instead reuse an existing MLIR dialect.

---

# 39. Types Directory

`Types/` defines domain-specific SCR Semantic MLIR types.

Examples:

```text
!scr.field
!scr.geometry
!scr.topology
!scr.agent
```

Types MUST represent semantic distinctions that matter at the IR level.

---

# 40. Attributes Directory

`Attributes/` defines domain-specific compile-time or structural metadata.

Examples may include:

```text
#scr.coordinate_system
#scr.boundary_condition
#scr.integration_method
```

Attributes MUST NOT be used merely because they are convenient places to put arbitrary metadata.

---

# 41. Operations Directory

`Operations/` defines the computational vocabulary of the domain-specific MLIR dialect.

For example:

```text
field.evaluate
field.sample
field.interpolate
field.integrate
field.transform
```

Operations SHOULD correspond to semantic operations defined by the domain.

---

# 42. Interfaces Directory

`Interfaces/` under a domain MLIR dialect SHOULD contain only MLIR-specific interfaces.

Shared semantic capabilities belong under:

```text
902_Interfaces/
```

This prevents each domain from independently redefining concepts such as:

```text
Differentiable
Streamable
Parallelizable
Spatial
Dynamical
```

---

# 43. Traits Directory

`Traits/` contains reusable structural or behavioral properties of IR constructs.

Traits SHOULD be reused where multiple operations share a formally defined property.

---

# 44. Verification Directory

`Verification/` contains:

* verifier definitions;
* structural validation;
* semantic validation;
* invariant checks;
* legality checks.

Verification MUST be testable independently from optimization or lowering.

---

# 45. Examples

Examples MAY demonstrate:

* valid IR;
* invalid IR;
* semantic composition;
* transformations;
* verification;
* lowering.

Examples MUST NOT become normative semantic definitions.

---

# 46. Serialization

The IR MAY be serialized.

Serialization mechanisms MAY include:

* MLIR textual form;
* MLIR bytecode;
* JSON;
* JSON-LD;
* CBOR;
* custom representations.

Serialization is not itself the IR.

The Semantic MLIR MUST remain conceptually independent of its serialization.

---

# 47. Parsing and Printing

An IR MAY define parsers and printers.

These are representation mechanisms.

The parser MUST construct valid IR or reject invalid input.

The printer SHOULD preserve all information required to reconstruct the Semantic MLIR subject to declared canonicalization or normalization rules.

---

# 48. Versioning

IR versions MUST be associated with the semantic version of the domain where changes affect semantic representation.

Changes SHOULD distinguish:

* additive representation changes;
* compatible representation changes;
* semantic changes;
* breaking representation changes;
* breaking semantic changes.

A change to the textual syntax alone MUST NOT automatically constitute a semantic version change.

---

# 49. Compatibility

IR compatibility MAY be:

* source compatible;
* binary compatible;
* parser compatible;
* semantic compatible;
* transformation compatible;
* lowering compatible.

These forms MUST NOT be conflated.

Two IR versions may be semantically equivalent while being syntactically incompatible.

---

# 50. Testing Requirements

IR implementations MUST be tested at multiple levels.

### IR Construction

Valid constructs can be created.

### IR Verification

Invalid constructs are rejected.

### IR Parsing

Valid representations can be parsed.

### IR Printing

Valid representations can be emitted.

### Semantic Preservation

IR operations preserve declared meaning.

### Transformation

Valid transformations produce valid IR.

### Lowering

Lowering preserves required semantics.

### Composition

Cross-domain MLIR dialect composition satisfies declared contracts.

### Equivalence

Equivalent IR structures can be identified where an equivalence relation exists.

---

# 51. Function-Level Requirements

An IR implementation SHOULD eventually provide capabilities corresponding to:

```text
ir.create
ir.parse
ir.print
ir.verify
ir.validate
ir.clone
ir.compare
ir.canonicalize
ir.transform
ir.compose
ir.decompose
ir.specialize
ir.lower
ir.query
ir.inspect
ir.trace
ir.provenance
```

Domain-specific IRs SHOULD additionally provide functions appropriate to their semantic domain.

These names are conceptual requirements rather than mandatory API names.

---

# 52. Performance Semantics

IR representations MAY expose information relevant to:

* complexity;
* locality;
* parallelism;
* memory;
* vectorization;
* tiling;
* distribution;
* scheduling;
* accelerator suitability.

Performance metadata MUST remain distinguishable from semantic meaning.

An optimization opportunity MUST NOT be mistaken for a semantic requirement.

---

# 53. Determinism

The IR MUST preserve determinism semantics where determinism is part of the domain contract.

For example:

```text
deterministic operation
stochastic operation
nondeterministic operation
```

MUST remain distinguishable.

A transformation MUST NOT introduce nondeterminism without the applicable semantic contract permitting it.

---

# 54. Provenance

IR transformations SHOULD preserve provenance sufficient to determine:

* source semantic object;
* source operation;
* transformation;
* lowering;
* provider;
* version;
* execution context where required.

This permits:

```text
IR
 ↓
Transformation
 ↓
IR
```

to remain traceable.

---

# 55. Errors

IR-specific errors SHOULD distinguish:

* malformed IR;
* invalid type;
* invalid operation;
* invalid attribute;
* invalid region;
* failed verification;
* unresolved reference;
* illegal transformation;
* unsupported lowering;
* incompatible provider.

IR errors MUST NOT silently replace domain-level semantic errors.

---

# 56. Security and Isolation

IR processing MUST treat externally supplied IR as untrusted unless its provenance and trust level establish otherwise.

Implementations SHOULD consider:

* malformed input;
* resource exhaustion;
* excessive nesting;
* pathological transformations;
* unsafe external references;
* unauthorized provider invocation.

Security mechanisms remain implementation concerns unless explicitly declared as semantic requirements.

---

# 57. Standards and Interoperability

SCR SHOULD reuse established IR and compiler standards wherever practical.

MLIR is the primary compiler IR infrastructure for SCR.

Existing MLIR dialects SHOULD be reused when they provide sufficient semantic expressiveness.

SCR SHOULD avoid creating custom dialect constructs where an existing MLIR abstraction accurately represents the required semantics.

However, SCR MUST NOT distort semantic meaning merely to fit an existing dialect.

---

# 58. Relationship to `905_Transforms`

`905_Transforms` defines transformations operating on IR.

```text
IR
 │
 ▼
905_Transforms
 │
 ▼
IR
```

The IR defines what can be represented.

Transforms define how representations may be changed.

---

# 59. Relationship to `903_Lowering`

`903_Lowering` defines lowering paths from higher-level representations toward lower-level representations and execution targets.

```text
SCR Semantic MLIR
    │
    ▼
903_Lowering
    │
    ▼
MLIR Target Dialect
```

Lowering MUST preserve the semantic guarantees required by the source IR.

---

# 60. Relationship to `904_Providers`

Providers implement or execute computations represented by IR.

```text
IR
 │
 ▼
Lowering
 │
 ▼
Provider
```

A provider is never the semantic definition of the IR.

---

# 61. Relationship to `902_Interfaces`

`902_Interfaces` defines reusable semantic capabilities across domains.

SCR Semantic MLIRs MAY implement those interfaces.

```text
902_Interfaces
      │
      ▼
SCR Semantic MLIR
```

The interface contract MUST remain independent of the implementation mechanism used by the IR.

---

# 62. Relationship to Analysis

IR is an important input to:

```text
901_Analysis/
```

Analysis MAY determine:

* capability;
* compatibility;
* complexity;
* control flow;
* cost;
* dataflow;
* dependency;
* determinism;
* differentiability;
* equivalence;
* locality;
* memory;
* parallelism;
* representation;
* resource requirements;
* scheduling;
* semantics;
* topology.

Analysis MUST inspect Semantic MLIR properties rather than relying solely on implementation details.

---

# 63. SCR Semantic MLIR Completeness Criteria

A domain-specific `IR/` is complete enough for implementation when it establishes:

* the purpose of the IR;
* its relationship to the domain definition;
* its abstraction level;
* its semantic boundary;
* types;
* values;
* attributes;
* operations;
* regions where required;
* interfaces;
* traits;
* verification;
* invariants;
* legality;
* representation rules;
* transformation boundaries;
* lowering boundaries;
* provider boundaries;
* provenance;
* versioning;
* compatibility;
* testing requirements.

Not every domain requires every construct.

The domain definition determines applicability.

---

# 64. Architectural Rules

### Rule 1 — Semantic Definition Is Authoritative

The domain `101_definition.md` defines meaning.

### Rule 2 — IR Represents Meaning

IR provides a computational representation of that meaning.

### Rule 3 — IR Is Not Implementation

IR MUST NOT be treated as equivalent to a particular implementation.

### Rule 4 — IR Is Not Storage

IR MUST NOT prescribe persistent storage.

### Rule 5 — IR Is Not Transport

IR MUST NOT prescribe messaging or transport.

### Rule 6 — IR Is Not Lowering

Lowering belongs under `903_Lowering`.

### Rule 7 — IR Is Not General Transformation

General transformations belong under `905_Transforms`.

### Rule 8 — IR Is Not Provider Logic

Provider implementation belongs under `904_Providers`.

### Rule 9 — One Domain Does Not Require One Dialect

A semantic domain MAY map to multiple MLIR dialects.

### Rule 10 — Existing Dialects Should Be Reused

Custom MLIR operations SHOULD only be introduced where existing MLIR abstractions are insufficient.

### Rule 11 — Abstraction Must Be Preserved

Higher-level semantic information SHOULD be retained until it is no longer required.

### Rule 12 — Lowering Must Be Explicit

A change in abstraction level MUST occur through an explicit transformation or lowering.

### Rule 13 — Verification Is Mandatory

IR MUST be validated against its declared invariants.

### Rule 14 — Interfaces Are Contracts

An interface implementation MUST satisfy the semantic capability it claims.

### Rule 15 — Representation Must Not Become Authority

The IR remains a representation of semantic meaning rather than the source of that meaning.

---

# 65. Open Semantic Questions

The following questions remain domain-specific or implementation-specific:

1. Which semantic concepts require dedicated IR types?
2. Which concepts are better represented as attributes?
3. Which concepts require operations?
4. Which operations require regions?
5. Which capabilities should be expressed through shared interfaces?
6. Which domain-specific interfaces are required?
7. Which existing MLIR dialects can be reused?
8. Which concepts require custom dialects?
9. What information must survive lowering?
10. What information may safely be discarded?
11. What constitutes semantic equivalence between two IR representations?
12. Which canonical forms are useful?
13. Which transformations are semantics-preserving?
14. Which transformations intentionally change abstraction?
15. Which verification rules are structural?
16. Which verification rules are semantic?
17. What provenance must survive transformations?
18. Which operations may be executed directly?
19. Which operations require lowering?
20. Which provider capabilities must be exposed to the IR?

---

# 66. Definition Authority

This document defines the normative meaning of the SCR Intermediate Representation abstraction.

For a specific domain, the domain's `101_definition.md` remains authoritative over the meaning being represented.

The domain's `IR/101_definition.md` is authoritative over how that meaning is represented computationally at the IR level.

Therefore:

```text
Domain 101
    ↓
defines meaning

SCR Semantic MLIR 101
    ↓
defines representation

905_Transforms
    ↓
defines transformations

903_Lowering
    ↓
defines lowering

904_Providers
    ↓
defines realization
```

---

# 67. Final Principle

> **SCR Semantic MLIR is the computational language through which semantic meaning becomes representable, analyzable, transformable, and lowerable without becoming dependent on its eventual implementation.**

The IR is therefore neither the semantic domain itself nor the final execution representation.

It is the formal bridge between them.
