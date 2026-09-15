# SCR Core Library Specification

**Document:** `lib/101_Core/101_spec.md`
**Status:** Normative
**Version:** 0.0.1
**Domain:** Core
**Library ID:** `SCR.Core`
**Specification Class:** Semantic Library Specification

---

## 1. Purpose

The SCR Core library defines the foundational semantic capabilities upon which the remainder of the Semantic Computational Runtime is constructed.

Core provides concepts and mechanisms that are sufficiently fundamental to be shared across multiple SCR domains.

Core is not a collection of application utilities.

It defines the minimum semantic substrate required for SCR to represent, identify, structure, verify, transform, and execute semantic computation.

The Core library must therefore remain:

* domain-independent where possible;
* semantically precise;
* composable;
* verifiable;
* representation-independent at the semantic level;
* suitable for MLIR representation;
* accessible through an idiomatic Mojo API.

---

# 2. Architectural Position

Core occupies the foundational position in the SCR semantic library.

```text
SCR
│
├── Core
│    ├── Identity
│    ├── Value
│    ├── Type
│    ├── Object
│    ├── Relation
│    ├── Operation
│    ├── State
│    └── ...
│
├── Math
├── Data
├── Tensor
├── Field
├── Graph
├── Geometry
├── Topology
├── Spatial
├── Morphology
├── Physics
├── Dynamics
├── Simulation
├── Agent
├── Neural
├── Render
├── Stream
└── System
```

Higher-level domains may depend upon Core.

Core must not acquire unnecessary dependencies upon higher-level domain concepts.

The dependency direction is therefore principally:

```text
Higher-level domain
        ↓
      Core
```

and not:

```text
Core
  ↓
Higher-level domain
```

unless the dependency is explicitly justified as a genuinely foundational abstraction.

---

# 3. Core Principle

The fundamental architectural principle of Core is:

> **SCR computation operates upon semantic structure, and Core provides the primitives required to represent and transform that structure.**

Core therefore establishes the common vocabulary through which SCR domains can describe:

* entities;
* identity;
* values;
* types;
* relationships;
* operations;
* state;
* references;
* transformations;
* constraints;
* provenance;
* semantic composition.

---

# 4. Semantic Authority

The semantic meaning of Core entities and operations is defined by SCR semantic specifications.

MLIR is the canonical implementation and compiler representation of Core semantics.

Mojo is the canonical user-facing programming interface to Core.

The relationship is:

```text
Core Semantic Specification
          ↓
        MLIR
          ↓
 verification / transformation / lowering
          ↓
      Mojo API
          ↓
       Application
```

Mojo must not establish an independent semantic implementation of Core.

Where a Core capability is exposed to users, the preferred implementation path is:

```text
Semantic definition
        ↓
MLIR implementation
        ↓
Mojo semantic API
```

The detailed project-wide language/API architecture is defined in:

`docs/architecture/101_language_and_api.md`

---

# 5. Scope

Core defines only concepts that satisfy at least one of the following conditions:

1. They are required by multiple SCR domains.
2. They establish a fundamental property of SCR semantic objects.
3. They define a fundamental relationship between semantic objects.
4. They are required for semantic verification or transformation.
5. They define a foundational runtime-independent abstraction.
6. They are required to preserve semantic identity or provenance.
7. They provide a general mechanism that cannot be correctly expressed using an existing Core primitive.

Core should not absorb domain-specific concepts merely because they are convenient to implement there.

---

# 6. Semantic Primitive Rule

SCR strongly prefers reuse of existing semantic primitives.

Before introducing a new Core primitive, the developer must establish:

```text
Can the concept be represented using existing SCR primitives?
            │
       ┌────┴────┐
      Yes        No
       │          │
     Reuse     Define gap
                  │
          determine whether
          the gap is general
                  │
             ┌────┴────┐
            Yes        No
             │          │
       Extend SCR     Domain/
                       application
                       composition
```

A new primitive is justified only where using an existing primitive would introduce semantic distortion, ambiguity, or loss of required properties.

---

# 7. Core Semantic Categories

The Core library is expected to contain foundational categories such as:

```text
Identity
Value
Type
Object
Relation
Operation
State
Reference
Constraint
Provenance
Transformation
```

The exact primitive inventory is implementation-defined by the corresponding sub-library specifications.

A category must not be treated as a primitive merely because it has a convenient implementation representation.

---

# 8. Identity

Identity is a Core semantic concern.

Identity establishes the distinction between:

```text
what an entity is
```

and:

```text
where or how an entity is manifested
```

SCR semantic identity must remain independent of:

* memory addresses;
* process IDs;
* file descriptors;
* runtime handles;
* GPU handles;
* network addresses;
* container IDs;
* implementation-specific object references.

The Identity subsystem defines the authoritative semantic identity model.

The current Identity architecture defines identity spaces, allocation domains, authorities, historical allocation, cryptographic provenance, semantic binding, manifestations, and transaction identity as distinct concepts.

These concepts must not be collapsed into a single identifier representation.

In particular:

```text
Semantic Identity
        ≠
Runtime Handle
        ≠
Physical Location
        ≠
Manifestation
```

The detailed Identity specification governs these semantics.

---

# 9. Values

A value represents semantic information that can participate in computation or semantic relationships.

A value may be:

* scalar;
* aggregate;
* structured;
* symbolic;
* spatial;
* temporal;
* graph-derived;
* domain-specific.

Core defines the common semantic properties of values.

Domain libraries define specialized value semantics.

A Core value must not unnecessarily encode domain-specific ontology.

---

# 10. Types

Types describe constraints and semantic structure associated with values and operations.

A type may constrain:

* admissible values;
* structure;
* operations;
* relationships;
* representation;
* ownership;
* lifetime;
* dimensionality;
* validity.

SCR types must be treated as semantic constructs rather than merely compiler annotations.

Where a type carries semantic meaning, that meaning must remain available to the SCR semantic system.

---

# 11. Objects

A semantic object is an identifiable entity participating in the SCR semantic model.

An object may possess:

```text
Identity
State
Properties
Relations
Capabilities
Manifestations
```

An object is not necessarily equivalent to a language-level class instance.

The Mojo representation of an object may differ from its canonical semantic representation.

---

# 12. Relations

Relations are first-class semantic structures.

A relation establishes a meaningful connection between semantic entities.

Conceptually:

```text
Entity A
   │
   │ Relation
   ▼
Entity B
```

Relations may carry semantic properties including:

* direction;
* multiplicity;
* ordering;
* strength;
* validity;
* provenance;
* temporal extent;
* spatial extent;
* constraints.

Higher-level graph and topology libraries may specialize relation semantics.

Core defines only the general relational foundation.

---

# 13. Operations

An operation represents a semantic transformation.

At the abstract level:

```text
Input Semantic State
        ↓
     Operation
        ↓
Output Semantic State
```

An operation may transform:

* values;
* objects;
* relations;
* fields;
* graph structure;
* state;
* computational resources.

An operation's inputs and outputs are themselves semantic structures.

Therefore:

> **A function signature is itself part of the semantic graph.**

A function is not merely an opaque executable pointer.

Its:

```text
inputs
outputs
constraints
dependencies
effects
relationships
```

must be representable where required by the SCR semantic model.

---

# 14. State

State represents the semantic condition of an entity, field, computation, or system at a particular point.

State may include:

* values;
* relationships;
* configuration;
* lifecycle;
* validity;
* availability;
* provenance;
* temporal position.

State transitions are semantic transformations.

Core must distinguish:

```text
State
```

from:

```text
Manifestation of State
```

A runtime representation may change without necessarily changing the canonical semantic state.

---

# 15. References

A reference identifies or points to another semantic structure without necessarily establishing ownership.

References must preserve the distinction between:

```text
identity
reference
ownership
manifestation
```

A reference may be implemented differently at different runtime levels.

For example:

```text
SemanticID
    ↓
semantic reference
    ↓
runtime handle
```

The runtime handle is not itself the semantic reference.

---

# 16. Constraints

Constraints express conditions that must hold for a semantic structure or transformation to be valid.

Examples include:

```text
type constraints
range constraints
identity constraints
topological constraints
spatial constraints
state constraints
ownership constraints
lifetime constraints
```

Constraints should be represented at the earliest layer at which they can be meaningfully verified.

Where possible:

```text
Specification
      ↓
MLIR verification
      ↓
Runtime validation
```

should progressively enforce the same semantic contract.

---

# 17. Provenance

Core provides the foundational concept of semantic provenance.

Provenance records how a semantic entity, allocation, transformation, or relationship derives from authoritative prior state.

Provenance is distinct from identity.

```text
Identity
    = which entity

Provenance
    = how its validity/authority can be established
```

Cryptographic mechanisms may implement provenance, but cryptography itself is not automatically the semantic definition of provenance.

---

# 18. Transformations

A transformation changes semantic structure while preserving the invariants applicable to that transformation.

Conceptually:

```text
S₁
 │
 │ T
 ▼
S₂
```

where `T` is a semantic transformation.

Transformations may occur at:

* compile time;
* graph construction;
* optimization;
* runtime;
* provider manifestation.

A transformation must not silently change semantic identity unless identity mutation is explicitly part of the operation's semantics.

---

# 19. Fields and Graphs

Core provides only the foundational concepts necessary for higher-level semantic fields and graphs.

The semantic graph model belongs principally to the Graph and Field domains.

However, Core objects, relations, operations, identity, and state must be representable as participants in that model.

Conceptually:

```text
Core semantic primitives
          ↓
Semantic Graph
          ↓
Semantic Field
          ↓
Computation
```

Core therefore establishes the vocabulary, while Graph and Field establish richer structural semantics.

---

# 20. Representation Independence

Semantic meaning must remain distinct from physical representation.

For example:

```text
Semantic Object
      ≠
MLIR Value
      ≠
Mojo Object
      ≠
Runtime Object
      ≠
Memory Address
```

These may correspond to one another, but they are not inherently identical.

This distinction is mandatory for:

* migration;
* persistence;
* distributed execution;
* compilation;
* optimization;
* provider substitution;
* runtime reconstruction.

---

# 21. MLIR Implementation

Core semantic operations must be represented through SCR's MLIR infrastructure.

MLIR implementations must provide, as applicable:

* semantic operations;
* semantic types;
* attributes;
* regions;
* verification;
* transformation interfaces;
* lowering;
* diagnostics;
* serialization where required.

The MLIR layer is canonical.

A Mojo implementation must not bypass the semantic MLIR layer merely because a direct runtime implementation appears simpler, unless the operation is explicitly designated as a non-semantic implementation facility.

---

# 22. Mojo API

Core capabilities intended for application developers must be exposed through idiomatic Mojo interfaces.

The preferred relationship is:

```text
Core MLIR
    ↓
Mojo semantic API
```

rather than:

```text
Core MLIR
    ↓
mechanically exposed compiler API
```

A Mojo API should expose semantic abstractions.

For example:

```mojo
let sid = domain.allocate()
```

is preferred over exposing the internal sequence of MLIR operations required to perform allocation.

The Mojo API may combine multiple semantic operations where doing so produces a more useful and coherent user abstraction.

---

# 23. Mojo API Non-Duplication

Mojo code may contain:

* wrappers;
* adapters;
* convenience functions;
* builders;
* ergonomic abstractions;
* validation helpers;
* resource-management code;
* application-facing composition.

It must not independently redefine the semantics of Core.

Where a Mojo implementation appears to require semantic behaviour not represented by Core/MLIR, the developer must determine whether:

1. the capability is already expressible;
2. a Core semantic gap exists;
3. the capability belongs in a higher-level domain;
4. the behaviour is merely an API convenience.

---

# 24. Runtime Boundary

Core semantics must remain independent of a particular runtime manifestation.

A semantic object may be manifested as:

```text
process
thread
memory object
container
file
network resource
GPU resource
provider object
remote object
```

without changing its semantic identity merely because its manifestation changes.

Runtime-specific behaviour belongs in the appropriate runtime or provider subsystem.

---

# 25. Provider Independence

Core must not depend upon a particular external provider merely to establish foundational semantics.

For example, Core should not define a semantic object in terms of:

```text
LLVM object
CUDA object
Vulkan object
Linux process
container runtime
```

unless the provider-specific concept itself is the subject of a higher-level provider integration.

Providers implement or manifest semantic capabilities.

They do not redefine Core semantics.

---

# 26. Verification Model

Core follows the SCR verification principle:

> **Describe → Specify → Test → Validate**

The preferred development sequence is:

```text
Semantic description
        ↓
Formal specification
        ↓
MLIR implementation
        ↓
Verification
        ↓
Mojo interface
        ↓
Mojo tests
        ↓
Runtime validation
```

Evidence must distinguish:

```text
Implemented
Verified
Tested
Validated
Proven
```

These terms must not be treated as interchangeable.

---

# 27. Invariants

Core implementations must establish explicit invariants.

Each invariant should have:

* stable identifier;
* semantic statement;
* scope;
* preconditions;
* expected postconditions;
* verification method;
* test coverage;
* known limitations.

Core invariants should be defined in the relevant sub-library specifications rather than duplicated throughout the repository.

---

# 28. Dependency Discipline

Core dependencies must be minimized.

A proposed dependency must be evaluated against:

1. Is the dependency genuinely foundational?
2. Does it introduce domain-specific semantics?
3. Can the concept be represented using existing Core primitives?
4. Does the dependency constrain alternative implementations?
5. Does it create a dependency cycle?
6. Does it unnecessarily couple semantic definition to manifestation?

Core should prefer abstractions over providers.

---

# 29. API and ABI Considerations

Semantic compatibility and implementation compatibility are distinct.

A change to an internal MLIR representation does not automatically constitute a semantic breaking change.

Likewise, a Mojo API change may be syntactically breaking while preserving the underlying semantic model.

Changes should therefore be classified according to:

```text
Semantic compatibility
MLIR compatibility
Mojo source compatibility
Runtime compatibility
Provider compatibility
```

where applicable.

---

# 30. Core Library Structure

The Core library should follow the SCR library convention:

```text
lib/101_Core/
├── 101_spec.md
├── 102_status.yaml
├── 103_library.graph.json
└── ...
```

Subdomains should use the established SCR versioned specification structure.

For example:

```text
lib/101_Core/Identity/
├── 101_spec.md
├── 102_status.yaml
├── 103_library.graph.json
├── ...
```

The exact implementation hierarchy is governed by the repository's current conventions.

---

# 31. Implementation Classification

Every Core capability should be classified as appropriate:

```text
Semantic Primitive
Semantic Composition
Compiler Mechanism
Runtime Mechanism
Provider Integration
Mojo API
Test / Verification Infrastructure
```

This classification prevents implementation mechanisms from being mistaken for semantic primitives.

---

# 32. Core API Design Test

Before accepting a new Core API, developers should be able to answer:

### 1. What semantic concept does it expose?

### 2. Why does that concept belong in Core?

### 3. Can an existing Core primitive express it?

### 4. What is its canonical MLIR representation?

### 5. How is it verified?

### 6. What is its Mojo representation?

### 7. Does the Mojo API preserve the semantic contract?

### 8. Does it introduce provider or runtime coupling?

### 9. Can the semantic entity survive manifestation changes?

### 10. What invariant proves that the implementation is correct?

If these questions cannot be answered, the capability is not yet sufficiently specified for Core.

---

# 33. Completion Criteria

A Core capability is considered complete only when its applicable requirements have been satisfied.

At minimum:

```text
[ ] Semantic meaning defined
[ ] Specification documented
[ ] Appropriate Core placement established
[ ] MLIR representation implemented
[ ] MLIR verification implemented
[ ] Required invariants identified
[ ] Tests implemented
[ ] Mojo API implemented where user-facing
[ ] Mojo API is idiomatic
[ ] Mojo tests implemented where user-facing
[ ] Runtime integration implemented where required
[ ] Provider integration implemented where required
[ ] End-to-end validation completed where required
[ ] Status recorded
```

An implementation must not be marked complete merely because code exists.

---

# 34. Core Architectural Invariants

The following invariants apply to the Core library.

### CORE-I001 — Foundationality

Core contains only semantics required as foundational capabilities by SCR.

### CORE-I002 — Semantic Authority

Core semantics are defined by SCR specifications and represented canonically through MLIR.

### CORE-I003 — Mojo Projection

Mojo exposes Core semantics to users without establishing an independent semantic implementation.

### CORE-I004 — Representation Independence

Semantic identity and meaning are independent of physical implementation representation.

### CORE-I005 — Runtime Independence

Core semantics must not depend upon a particular runtime manifestation unless explicitly specified.

### CORE-I006 — Provider Independence

Core semantics must not be defined in terms of a particular provider.

### CORE-I007 — Primitive Reuse

Existing semantic primitives must be reused where they can represent a new requirement without semantic distortion.

### CORE-I008 — Explicit Extension

A new primitive requires an identified semantic gap and justification.

### CORE-I009 — Verifiability

Core semantic capabilities must have explicit verification criteria.

### CORE-I010 — Identity Separation

Semantic identity must remain distinct from runtime handles, physical locations, and manifestations.

### CORE-I011 — Transformation Integrity

Semantic transformations must preserve all applicable invariants unless their semantics explicitly specify otherwise.

### CORE-I012 — API Traceability

User-facing Mojo operations must be traceable to their underlying SCR semantic representation.

---

# 35. Relationship to Other Specifications

This document establishes the Core-level architectural contract.

The following documents govern more specific concerns:

```text
docs/architecture/101_language_and_api.md
    ↓
Project-wide MLIR / Mojo architecture

lib/101_Core/Identity/101_spec.md
    ↓
Identity semantics

lib/101_Core/<subdomain>/101_spec.md
    ↓
Specific Core semantic domain
```

More specific specifications may refine this document but must not contradict its architectural invariants.

---

# 36. Final Principle

SCR Core exists to establish the smallest coherent semantic foundation upon which the remainder of SCR can be built.

Its implementation should therefore continuously preserve the following relationship:

```text
              SCR Semantics
                   │
                   ▼
                  Core
                   │
                   ▼
                 MLIR
                   │
          ┌────────┴────────┐
          ▼                 ▼
      Verification       Lowering
          │                 │
          └────────┬────────┘
                   ▼
              Mojo API
                   │
                   ▼
             SCR Programs
```

The fundamental rule is:

> **Define the semantic primitive once. Represent it canonically in MLIR. Expose it naturally through Mojo. Manifest it through the runtime and providers without changing its meaning.**

Core is successful when higher-level SCR domains can build upon it without redefining foundational semantics, while application developers can use those semantics naturally through Mojo.
