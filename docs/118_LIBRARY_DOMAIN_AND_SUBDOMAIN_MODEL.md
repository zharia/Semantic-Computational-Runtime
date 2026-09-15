# SCR Library Domain and Subdomain Model

**Document ID:** `SCR-DOC-LIB-118`
**Status:** Normative Architectural Specification
**Version:** `0.2.0`
**Applies to:** Semantic Computational Runtime (SCR)
**Primary Concern:** Semantic domains, subdomains, formalisation, implementation, providers, validation, and library topology

---

## 1. Purpose

This specification defines how Semantic Computational Runtime (SCR) is extended through semantic domains and subdomains.

It establishes:

* what constitutes a domain;
* what constitutes a subdomain;
* how semantic ownership is established;
* how domains and subdomains are decomposed;
* how specifications, implementations, and providers relate;
* how semantic dependencies are represented;
* how domains progress through their development lifecycle;
* how formalisation and machine-checked proofs, particularly in Lean, participate in that lifecycle;
* how semantic concepts are validated before implementation;
* how domain and subdomain identity is maintained independently of filesystem layout;
* how the SCR library graph records semantic relationships;
* how development agents are expected to extend the library.

The central principle is:

> **SCR grows by semantic refinement, not by accumulation of code.**

---

# 2. Normative Principles

The following principles are normative.

### LIB-P-001 — Semantic Primacy

SCR is organized according to semantic meaning, not implementation technology.

### LIB-P-002 — Specification Primacy

The normative semantic specification is authoritative over implementations, providers, generated artifacts, and formal models.

### LIB-P-003 — Semantic Ownership

Every normative semantic concept SHALL have one authoritative semantic home.

### LIB-P-004 — Explicit Refinement

A subdomain SHALL refine its parent domain rather than silently redefining it.

### LIB-P-005 — Implementation Independence

A semantic domain SHALL NOT be defined by the implementation technology used to realize it.

### LIB-P-006 — Provider Independence

A provider SHALL realize capabilities defined by SCR semantics; it SHALL NOT silently define those semantics.

### LIB-P-007 — Validation Before Implementation

A domain SHALL be semantically described and specified before implementation becomes normative.

### LIB-P-008 — Formalisation by Value

Formalisation SHALL be used where it materially improves confidence, precision, composability, or proof of semantic properties.

### LIB-P-009 — Formalisation Is Conditional

Not every domain or subdomain is required to have a Lean formalisation.

### LIB-P-010 — Machine-Checked Evidence

Where Lean formalisation exists, Lean's type checking and proofs SHALL be treated as verification evidence, not as a replacement for the normative semantic specification.

### LIB-P-011 — No Silent Semantic Redefinition

A formal model SHALL NOT silently establish semantics that contradict or extend the normative specification.

### LIB-P-012 — Counterexample-Driven Development

Semantic development SHALL actively seek counterexamples and failure modes rather than merely demonstrate expected behaviour.

---

# 3. Scope

This specification applies to all SCR library domains and subdomains.

It governs:

```text
Semantic Domains
    │
    ├── Subdomains
    │     └── Nested Subdomains
    │
    ├── Specifications
    │
    ├── Formalisations
    │
    ├── Implementations
    │
    ├── Providers
    │
    └── Validation / Conformance
```

It does not define the internal semantics of individual domains.

Those semantics belong to the domain's own `101_spec.md`.

---

# 4. Fundamental Distinctions

SCR SHALL maintain the following distinctions:

```text
Domain
    ≠
Subdomain
    ≠
Specification
    ≠
Formalisation
    ≠
Implementation
    ≠
Provider
```

Additionally:

```text
Directory Structure
    ≠
Semantic Ontology
```

and:

```text
Semantic Dependency
    ≠
Filesystem Dependency
    ≠
Build Dependency
    ≠
Provider Dependency
```

These distinctions are fundamental.

---

# 5. Semantic Domain

A **domain** is a coherent semantic namespace containing concepts, relationships, transformations, constraints, and invariants belonging to a defined area of SCR semantics.

A domain establishes:

* what concepts it owns;
* what concepts it consumes;
* what concepts it defines;
* what concepts it intentionally excludes;
* what relationships exist between its concepts;
* what invariants constrain them;
* what subdomains refine it;
* what other domains it depends upon;
* what capabilities may be implemented or provided.

A domain is therefore a semantic boundary, not merely a directory.

---

# 6. Domain Scope

Every domain SHALL have an explicitly understood scope.

At minimum, the domain specification SHALL be able to answer:

1. What semantic concepts belong to this domain?
2. What concepts are outside the domain?
3. Which concepts does the domain own?
4. Which concepts does it consume from other domains?
5. Which concepts refine concepts from parent domains?
6. Which relationships are normative?
7. Which invariants are normative?
8. Which transformations are defined?
9. Which concepts are intentionally left to providers or implementations?
10. Which subdomains belong within the domain?

A domain SHALL NOT become a general-purpose container for concepts that merely happen to be used by its implementation.

---

# 7. Semantic Ownership

Every normative concept SHALL have one authoritative semantic owner.

Define:

```text
SemanticOwner : Concept → Domain
```

The owner is responsible for the normative definition of the concept.

Other domains MAY:

* consume the concept;
* constrain it;
* compose it;
* refine it;
* reference it;
* implement it;
* provide capabilities associated with it.

They SHALL NOT silently redefine it.

### Example

If `spatial.coordinate` is owned by the spatial domain:

```text
spatial
└── coordinate
```

another domain MAY reference:

```text
spatial.coordinate
```

but SHALL NOT create a competing definition of "coordinate" merely because its implementation requires one.

---

# 8. Subdomains

A **subdomain** is a semantic refinement contained within another domain.

For:

```text
D_parent
    └── D_child
```

the child inherits the applicable semantic environment of the parent.

The child MAY:

* specialize concepts;
* introduce additional concepts;
* introduce additional invariants;
* restrict valid states;
* refine transformations;
* define additional relationships;
* decompose the parent domain further.

The child SHALL NOT violate applicable parent semantics.

Conceptually:

```text
Spec(child) ⊨ Spec(parent)
```

for all parent semantics applicable to the child.

This does not require literal logical implication in every case; it expresses the normative requirement that specialization preserve applicable parent meaning.

---

# 9. Domain Hierarchy

Semantic containment MAY be represented hierarchically:

```text
spatial
├── coordinate
├── partition
│   ├── local
│   └── distributed
├── state
└── topology
```

The hierarchy expresses semantic containment.

It does not necessarily express:

* execution dependency;
* implementation dependency;
* provider dependency;
* build dependency;
* runtime dependency.

Those relationships SHALL be represented independently.

---

# 10. Domain Identity

Domain identity SHALL be independent of filesystem location.

A domain SHOULD have a stable semantic identifier such as:

```text
core
math
graph
graph.hypergraph
spatial
spatial.partition
spatial.partition.distributed
```

The identifier is a semantic identity, not merely a directory name.

Filesystem organization SHOULD normally correspond to semantic hierarchy, but the semantic identifier remains authoritative.

---

# 11. Canonical Library Structure

Each domain SHALL use the following baseline structure:

```text
lib/<domain>/
├── README.md
├── 101_spec.md
├── 102_status.yaml
└── 103_library.graph.json
```

Subdomains SHALL recursively use the same structure:

```text
lib/<domain>/<subdomain>/
├── README.md
├── 101_spec.md
├── 102_status.yaml
└── 103_library.graph.json
```

Additional artifacts MAY be added where justified.

Examples:

```text
104_conformance.md
105_formal_model.md
formal/
tests/
examples/
```

Additional files SHALL NOT replace the canonical files.

---

# 12. Canonical Domain Artifacts

## 12.1 `README.md`

Human-facing introduction.

It SHOULD explain:

* what the domain means;
* why it exists;
* what problems it addresses;
* its major concepts;
* its relationship to neighbouring domains;
* its current maturity;
* links to specifications and formalisation.

`README.md` SHALL NOT be the normative semantic authority.

---

## 12.2 `101_spec.md`

The normative semantic specification.

This document SHALL define:

* semantic concepts;
* relationships;
* transformations;
* constraints;
* invariants;
* lifecycle semantics;
* identity semantics;
* reference semantics;
* deletion semantics where applicable;
* observable behaviour;
* domain boundaries;
* dependencies;
* conformance requirements where appropriate.

If there is a conflict between `README.md` and `101_spec.md`, `101_spec.md` prevails.

---

## 12.3 `102_status.yaml`

Machine-readable development state.

It SHALL record, where applicable:

```yaml
domain:
  id:
  name:
  version:
  maturity:

formalisation:
  status:
  language:
  model:
  proof_level:
  coverage:

implementation:
  status:
  languages:
  implementations:

validation:
  status:
  tests:
  invariants:
  counterexamples:

providers:
  status:
  providers:

dependencies:
  semantic:
  formal:
  implementation:
  provider:
```

The exact schema MAY evolve independently.

The information SHALL remain truthful.

---

## 12.4 `103_library.graph.json`

Machine-readable semantic topology.

It SHOULD represent:

* domain identity;
* parent domain;
* subdomains;
* semantic dependencies;
* concept ownership;
* concept references;
* formalisation relationships;
* implementations;
* providers;
* validation artifacts;
* conformance relationships.

The graph SHALL describe semantic relationships rather than merely reproducing filesystem structure.

---

# 13. Formalisation

Formalisation is the process of expressing selected SCR semantics in a mathematically precise, machine-checkable representation.

Lean is the preferred formalisation environment where practical.

However:

> **SCR does not require every domain or subdomain to be formally specified in Lean.**

Formalisation is encouraged when it provides meaningful additional assurance.

---

# 14. Lean Formalisation

Lean SHOULD be used where formal reasoning materially improves confidence in SCR semantics.

Particularly suitable subjects include:

* foundational semantic primitives;
* hypergraphs;
* relations;
* references;
* identity;
* deletion;
* transition semantics;
* algebraic structures;
* topology;
* geometry;
* spatial partitioning;
* authority and delegation;
* concurrency;
* consistency;
* security properties;
* invariants;
* conservation laws;
* foundational domain composition.

Lean formalisation is especially valuable when a domain establishes semantics consumed by many downstream domains.

---

# 15. Formalisation Is Not Mandatory

A domain MAY remain without Lean formalisation when:

* its semantics are sufficiently simple;
* executable tests provide adequate validation;
* the domain is primarily implementation-oriented;
* the formal proof burden exceeds the value obtained;
* suitable mathematical structure has not yet been identified;
* the domain is still exploratory.

Absence of Lean formalisation SHALL NOT by itself indicate that the domain is invalid or immature.

It indicates that machine-checked mathematical assurance has not yet been established.

---

# 16. Formalisation Levels

SCR defines the following conceptual formalisation maturity levels:

```text
none
described
axiomatized
modeled
proved
verified
```

### 16.1 `none`

No formalisation exists.

### 16.2 `described`

The domain has identified what would need to be formalised but has not yet encoded it.

### 16.3 `axiomatized`

Key concepts, relationships, assumptions, or axioms have been represented in Lean.

### 16.4 `modeled`

A coherent mathematical model exists and successfully type-checks.

### 16.5 `proved`

Important semantic propositions or invariants have machine-checked proofs.

### 16.6 `verified`

The formal model has been demonstrated to correspond sufficiently to the normative specification and, where claimed, to implementation or conformance behaviour.

These levels are maturity indicators, not claims that higher levels are always better.

---

# 17. Relationship Between Specification and Lean

The normative relationship is:

```text
101_spec.md
     │
     ▼
Formalisation
     │
     ├── model
     ├── definitions
     ├── propositions
     └── proofs
```

The Lean model SHALL formalise the semantics expressed by the specification.

It SHALL NOT silently redefine them.

If Lean reveals an inconsistency, ambiguity, contradiction, or missing case in the specification, the preferred resolution is:

```text
Specification defect
        ↓
101_spec.md revision
        ↓
Formalisation revision
        ↓
Proof restoration
```

rather than silently treating the Lean interpretation as the new semantic authority.

---

# 18. Lean as Semantic Evidence

Lean proofs SHALL be treated as machine-checkable evidence.

For example:

```lean
theorem identity_preserved_after_partition_refinement :
  ...
```

may establish a theorem corresponding to an invariant in `101_spec.md`.

The specification remains authoritative regarding what the invariant means.

The Lean theorem establishes that the formal model satisfies the stated property under its assumptions.

Therefore:

```text
Specification
    defines meaning

Lean
    checks formal consequences
```

rather than:

```text
Lean
    defines meaning
```

---

# 19. Formalisation Traceability

Where Lean formalisation exists, the relationship between normative concepts and formal definitions SHOULD be traceable.

For example:

```text
101_spec.md
    LIB-HG-INV-004
        │
        ▼
Lean definition/theorem
    Hypergraph.identity_preserved
        │
        ▼
Proof
    identity_preserved_after_transition
```

Formal artefacts SHOULD identify the relevant specification concepts where practical.

Conversely, the specification SHOULD identify significant formalisation coverage where available.

---

# 20. Formal Dependencies

Formalised domains MAY depend on formalised foundations from other domains.

Define:

```text
FormalDependsOn : Domain × Domain → Prop
```

For example:

```text
hypergraph
    └── formally depends on
        relation
```

A downstream formalisation SHOULD reuse established definitions and theorems rather than recreate semantically equivalent structures independently.

This is especially important for foundational concepts.

The objective is a reusable proof ecosystem:

```text
core
 └── relation
      └── graph
           └── hypergraph
                └── executable-hypergraph
```

where downstream domains can inherit mathematical guarantees from upstream domains.

---

# 21. Formal Refinement

Where a child domain has a Lean formalisation, the formal model SHOULD preserve the applicable formal semantics of its parent.

Conceptually:

```text
Formal(child) ⊑ Formal(parent)
```

where `⊑` represents semantic refinement rather than simple syntactic inheritance.

A child formalisation SHALL NOT silently contradict an established parent theorem.

If the child requires a stronger assumption, that assumption SHALL be explicit.

---

# 22. Formalisation and Counterexamples

Formalisation SHALL be used not merely to prove expected properties but also to expose incorrect assumptions.

The development process SHOULD actively seek:

* contradictory axioms;
* uninhabited models;
* overly strong assumptions;
* missing cases;
* invalid compositions;
* unintended equivalences;
* identity collisions;
* illegal transitions;
* impossible states;
* countermodels.

A theorem that is easy to prove because the model is over-constrained is not considered useful evidence.

Therefore:

> **Proof validity does not imply model validity.**

The model itself must remain subject to semantic and counterexample-based scrutiny.

---

# 23. Specification–Validation–Formalisation Loop

The canonical development loop is:

```text
Describe
   ↓
Specify
   ↓
Validate
   ↓
Formalize
   ↓
Prove / Falsify
   ↓
Refine Specification
   ↓
Implement
   ↓
Verify
   ↓
Integrate
```

This is iterative.

Formalisation may expose defects requiring the specification to return to an earlier stage.

Implementation tests may similarly expose defects in the formal model.

The process is therefore not strictly linear.

---

# 24. Domain Lifecycle

A domain SHOULD progress through the following conceptual lifecycle:

```text
seed
  ↓
described
  ↓
scoped
  ↓
specified
  ↓
validated
  ↓
formalized
  ↓
implemented
  ↓
verified
  ↓
stabilized
```

Formalisation is deliberately located between semantic validation and mature implementation, but may occur earlier for foundational domains.

---

# 25. Domain Creation Procedure

When creating a new domain:

### Step 1 — Search

Determine whether the semantic concept already exists.

### Step 2 — Identify Ownership

Determine the authoritative semantic domain.

### Step 3 — Establish Scope

Determine whether the proposed concept is:

* a new domain;
* a subdomain;
* an extension of an existing concept;
* a cross-domain concern;
* an implementation;
* a provider capability.

### Step 4 — Assign Identity

Create a stable semantic identifier.

### Step 5 — Describe

Create the human-readable domain description.

### Step 6 — Specify

Create `101_spec.md`.

### Step 7 — Validate

Create semantic tests, invariants, negative cases, and counterexamples.

### Step 8 — Formalize Where Valuable

Determine whether Lean formalisation is appropriate.

### Step 9 — Prove

Where formalised, establish important propositions and invariants.

### Step 10 — Implement

Implement the specified semantics.

### Step 11 — Verify

Compare implementation behaviour against semantic specification and formal guarantees.

### Step 12 — Record Status

Update `102_status.yaml`.

### Step 13 — Update Library Graph

Update `103_library.graph.json`.

### Step 14 — Integrate

Connect the domain to dependent domains and providers.

---

# 26. Subdomain Creation Procedure

A subdomain SHALL follow the same process but additionally establish its relationship to its parent.

```text
Parent Domain
      │
      ▼
Child Scope
      │
      ▼
Semantic Refinement
      │
      ▼
Validation
      │
      ▼
Formalisation
      │
      ▼
Implementation
```

The child SHALL explicitly identify:

* parent domain;
* inherited concepts;
* refined concepts;
* new concepts;
* strengthened invariants;
* additional constraints;
* semantic dependencies.

---

# 27. Provider Boundary

Providers SHALL realize capabilities.

Examples include:

```text
H3
OpenVDB
CGAL
Chrono
Vulkan
CUDA
BLAS
```

A provider MAY provide:

* algorithms;
* storage;
* indexing;
* execution;
* rendering;
* numerical computation;
* spatial structures;
* hardware acceleration.

A provider SHALL NOT become the semantic definition merely because SCR uses it.

For example:

```text
SCR Spatial Semantics
        │
        ├── H3 provider
        ├── OpenVDB provider
        └── other providers
```

not:

```text
H3
  └── defines SCR spatial semantics
```

Provider substitution SHOULD remain possible where semantic equivalence permits it.

---

# 28. Implementation Boundary

An implementation realizes a semantic specification.

Define conceptually:

```text
Implements : Implementation × Specification → Prop
```

An implementation MAY use:

* Mojo;
* MLIR;
* Rust;
* C++;
* GPU kernels;
* external libraries;
* operating-system facilities;
* hardware acceleration.

The implementation technology SHALL NOT alter the normative semantic meaning without corresponding specification change.

---

# 29. Semantic Dependencies

Define:

```text
DependsOn : Domain × Domain → Prop
```

Semantic dependencies SHALL be explicit.

A dependency means that the meaning of one domain relies upon concepts established by another.

Example:

```text
executable.hypergraph
        ↓
hypergraph
        ↓
relation
```

A filesystem relationship does not automatically imply semantic dependency.

---

# 30. Dependency Classes

SCR SHALL distinguish at least:

```text
Semantic Dependency
Formal Dependency
Implementation Dependency
Build Dependency
Provider Dependency
```

For example:

```text
Domain A
  ├── semantically depends on B
  ├── formally depends on C
  ├── implemented using D
  ├── builds using E
  └── optionally uses provider F
```

These relationships SHALL NOT be conflated.

---

# 31. Cross-Domain Composition

A domain MAY compose concepts from several domains.

For example:

```text
spatial
    +
graph
    +
dynamics
    +
execution
```

may produce a higher-level computational domain.

The composed domain SHALL reference canonical concepts rather than duplicate them.

---

# 32. Cross-Cutting Concerns

Some semantics span multiple domains.

Examples include:

* identity;
* provenance;
* authorization;
* lifecycle;
* observability;
* versioning;
* validation.

A cross-cutting concern SHALL have one canonical semantic definition where practical.

Domains SHALL reference that definition rather than independently defining competing versions.

---

# 33. Identity and Reference Semantics

Identity, reference, deletion, and lifecycle semantics SHALL be treated as semantic concerns.

They SHALL NOT be defined merely by:

* pointer behaviour;
* memory addresses;
* database IDs;
* filenames;
* process IDs;
* provider-local identifiers.

Where a domain uses identifiers, it SHALL specify:

* identity;
* allocation;
* reference;
* validity;
* aliasing;
* lifecycle;
* deletion;
* reuse;
* provenance.

These semantics MAY be formally verified where the complexity and consequences justify it.

---

# 34. Versioning

Semantic versioning SHALL be distinguished from implementation versioning.

For example:

```text
Semantic specification:
    spatial.partition 0.2.0

Implementation:
    provider-openvdb 1.7.3
```

A provider version change does not automatically constitute a semantic version change.

Conversely, a semantic change MAY require implementation changes across multiple providers.

---

# 35. Formal Versioning

Formal models SHALL be versioned independently where necessary.

For example:

```text
Specification:
    0.3.0

Lean model:
    0.3.0-formal.2

Implementation:
    1.8.4
```

Formalisation changes SHALL identify whether they represent:

* proof-only changes;
* model corrections;
* strengthened assumptions;
* semantic discoveries;
* specification changes.

A proof repair caused by an implementation detail SHOULD NOT be represented as a semantic change unless semantics actually changed.

---

# 36. Validation Requirements

Every domain SHALL have some form of semantic validation.

Validation SHOULD include:

### Positive Tests

Demonstrate valid behaviour.

### Negative Tests

Demonstrate rejection of invalid behaviour.

### Invariant Tests

Demonstrate preservation of required properties.

### Counterexamples

Attempt to violate assumptions.

### Integration Tests

Demonstrate composition with dependent domains.

### Formal Proofs

Where Lean formalisation exists, prove selected mathematical properties.

### Conformance Tests

Where appropriate, demonstrate that an implementation conforms to the specification.

---

# 37. Formal Proof Coverage

Formalisation does not require every proposition to be proven.

A domain MAY selectively formalise:

```text
Foundational Definitions
        +
Critical Invariants
        +
High-Risk Properties
        +
Composition Laws
```

rather than attempting complete formalisation.

The status SHALL make the coverage clear.

For example:

```yaml
formalisation:
  status: proved
  language: lean
  coverage:
    definitions: 80%
    invariants: 100%
    composition: 60%
    implementation_correspondence: 0%
```

Exact quantitative metrics are optional; the underlying coverage SHALL remain honest.

---

# 38. Proof Obligations

When a domain is formally specified, its important invariants SHOULD become explicit proof obligations.

For example:

```text
Specification invariant
        ↓
Proposition
        ↓
Lean theorem
        ↓
Machine-checked proof
```

Proof obligations SHOULD preferentially target properties that are:

* foundational;
* difficult to test exhaustively;
* safety-critical;
* security-sensitive;
* algebraically compositional;
* reused by downstream domains.

---

# 39. Formal Model Failure

A Lean model MAY fail because:

1. the specification is inconsistent;
2. the formalisation is incorrect;
3. assumptions are insufficient;
4. the theorem is false;
5. the implementation semantics differ;
6. the intended property is underspecified.

These possibilities SHALL be distinguished.

A failed proof SHALL NOT automatically be "fixed" by adding arbitrary axioms.

Additional axioms SHALL require explicit semantic justification.

---

# 40. Axiom Discipline

Axioms introduced into formal models SHALL be documented.

Where practical:

```text
Axiom
  ↓
Purpose
  ↓
Specification basis
  ↓
Dependencies
  ↓
Consequences
```

Unnecessary axioms SHOULD be eliminated.

SCR SHOULD prefer definitions and derived theorems over unexplained axiomatic assumptions.

---

# 41. Library Graph Formalisation Relationships

`103_library.graph.json` SHOULD represent relationships such as:

```text
formalizes
proves
formally-depends-on
refines
conforms-to
implements
provided-by
consumes
owns
```

Example:

```text
domain: spatial.partition
    formalized-by:
        formal/spatial_partition.lean

    proves:
        partition_refinement_preserves_membership

    formally-depends-on:
        spatial
```

---

# 42. Recommended Formal Directory

Where formalisation becomes substantial, the following structure is RECOMMENDED:

```text
lib/<domain>/
├── README.md
├── 101_spec.md
├── 102_status.yaml
├── 103_library.graph.json
├── 105_formal_model.md
├── formal/
│   ├── Basic.lean
│   ├── Definitions.lean
│   ├── Properties.lean
│   └── Theorems.lean
└── tests/
```

`105_formal_model.md` SHOULD explain the correspondence between the prose specification and the Lean model.

---

# 43. Formalisation Toolchain

Lean is the preferred formalisation environment for SCR mathematical semantics.

However, the architecture SHALL NOT make the semantic model dependent upon Lean.

Other formal methods MAY be introduced where appropriate.

The fundamental requirement is:

```text
Machine-checkable formal reasoning
```

rather than:

```text
Mandatory use of one tool
```

Lean is the preferred mechanism because it provides a mature environment for:

* dependent type theory;
* algebraic reasoning;
* theorem proving;
* constructive mathematics;
* reusable libraries;
* machine-checked proofs.

---

# 44. Formalisation and MLIR

MLIR SHALL NOT be treated as the formal semantic proof system.

MLIR represents and transforms executable structures.

Lean formalisation addresses mathematical semantics and properties.

Therefore:

```text
SCR Semantics
      │
      ├── Lean
      │     └── formal reasoning
      │
      └── MLIR
            └── executable representation/lowering
```

These are complementary.

---

# 45. Formalisation and Mojo

Mojo SHALL remain an implementation language.

Mojo implementations MAY be tested against properties established by Lean.

However:

```text
Lean theorem
    ≠
Mojo implementation proof
```

unless an explicit correspondence has been established.

An implementation SHALL NOT claim formal verification merely because its conceptual algorithm resembles a Lean model.

---

# 46. Domain Status

Every domain SHALL communicate its current maturity.

Recommended status:

```text
seed
described
scoped
specified
validated
formalized
implemented
verified
stable
deprecated
retired
```

Formalisation state SHOULD be represented independently:

```text
formalisation:
  status: none | described | axiomatized | modeled | proved | verified
```

This prevents semantic maturity from being confused with formal maturity.

---

# 47. No Orphan Concepts

A semantic concept SHALL NOT exist without an identifiable owner.

The library SHOULD detect:

```text
concept
    └── no owner
```

as an architectural defect.

Similarly, duplicate semantic ownership SHALL be detected:

```text
concept X
 ├── owner A
 └── owner B
```

unless the distinction is explicitly justified as different concepts.

---

# 48. No Hidden Redefinition

A domain SHALL NOT redefine a concept imported from another domain under the same semantic identity.

For example:

```text
spatial.coordinate
```

must not acquire different meanings in:

```text
physics
render
simulation
```

Those domains may introduce:

```text
physics.coordinate
render.coordinate
```

only if these are genuinely distinct semantic concepts.

Otherwise they SHALL reference the canonical spatial concept.

---

# 49. Provider Substitution

Where multiple providers satisfy the same semantic capability:

```text
Capability
 ├── Provider A
 ├── Provider B
 └── Provider C
```

the provider boundary SHOULD permit substitution without semantic change.

This is a major architectural advantage of keeping providers below semantic specifications.

---

# 50. Semantic Boundary Integrity

A domain SHALL NOT acquire semantics merely because an implementation happens to require them.

The correct direction is:

```text
Semantic Requirement
       ↓
Specification
       ↓
Formalisation / Validation
       ↓
Implementation
       ↓
Provider
```

not:

```text
Provider
       ↓
Implementation
       ↓
Accidental Semantics
       ↓
Retroactive Specification
```

Implementation-first ontology is therefore prohibited for normative SCR semantics.

---

# 51. Invariants

The following invariants are normative.

### LIB-001 — Unique Semantic Ownership

Every normative concept has one authoritative semantic owner.

### LIB-002 — No Duplicate Definition

The same semantic concept is not independently defined in multiple domains.

### LIB-003 — Child Refinement

A subdomain preserves applicable parent semantics.

### LIB-004 — Stable Identity

Domain identity is independent of implementation or filesystem location.

### LIB-005 — Explicit Dependency

Semantic dependencies are explicitly represented.

### LIB-006 — Provider Independence

Provider identity does not define semantic identity.

### LIB-007 — Implementation Independence

Implementation technology does not define semantic meaning.

### LIB-008 — Graph Consistency

The library graph agrees with declared domain relationships.

### LIB-009 — Truthful Status

Status metadata accurately reflects domain maturity.

### LIB-010 — Specification Primacy

The normative specification remains authoritative.

### LIB-011 — No Orphan Concepts

Every normative concept has an owner.

### LIB-012 — No Hidden Redefinition

Imported concepts are not silently redefined.

### LIB-013 — Dependency Separation

Semantic, formal, implementation, build, and provider dependencies remain distinguishable.

### LIB-014 — Refinement Validity

Subdomains preserve applicable parent invariants.

### LIB-015 — Version Integrity

Semantic and implementation versions remain distinct.

### LIB-016 — Negative Semantics

Invalid states and operations are explicitly considered.

### LIB-017 — Conformance Integrity

Conformance claims are supported by evidence.

### LIB-018 — Migration Integrity

Changes to domain structure preserve semantic identity and traceability.

### LIB-019 — Concept Traceability

Important concepts can be traced from specification to validation and implementation.

### LIB-020 — Provider Substitutability

Provider replacement does not silently alter semantics.

### LIB-021 — No Implementation-First Ontology

Implementation artefacts do not silently create normative semantics.

### LIB-022 — Semantic Boundary Integrity

Domain boundaries remain explicit.

### LIB-023 — Formalisation Integrity

Formal models correspond to the normative specification.

### LIB-024 — No Silent Formal Redefinition

Lean models do not silently redefine SCR semantics.

### LIB-025 — Proof Evidence Integrity

A proof claim identifies the proposition and assumptions under which it holds.

### LIB-026 — Formal Dependency Integrity

Formal dependencies are explicitly represented.

### LIB-027 — Refinement Proof Integrity

A formal child model does not contradict applicable formally established parent semantics.

### LIB-028 — Axiom Transparency

Formal axioms are explicitly documented and justified.

### LIB-029 — Countermodel Integrity

Formalisation is subject to counterexample and consistency analysis.

### LIB-030 — Formalisation Proportionality

Formalisation effort is proportionate to semantic importance and risk.

---

# 52. Required Formal Relations

The library model SHALL conceptually support:

```text
SemanticOwner : Concept → Domain

DependsOn : Domain × Domain → Prop

FormalDependsOn : Domain × Domain → Prop

Provides : Provider × Capability → Prop

Implements : Implementation × Specification → Prop

Formalizes : FormalModel × Specification → Prop

Proves : FormalModel × Proposition → Prop

Refines : Specification × Specification → Prop

FormalRefines : FormalModel × FormalModel → Prop

ConformsTo : Implementation × Specification → Prop
```

These relationships MAY be represented differently in implementation, but their semantics SHALL remain distinguishable.

---

# 53. Formal Domain Model

A domain MAY be modeled abstractly as:

```text
D = ⟨I,S,C,R,O,K,V,F,P⟩
```

where:

```text
I = identity
S = semantic concepts/state
C = context
R = relationships
O = operations/transformations
K = constraints/invariants
V = validation model
F = formalisation model
P = provider/realization mappings
```

Not every domain requires all components to be populated.

In particular:

```text
F = ∅
```

is valid for a domain that has no Lean formalisation.

---

# 54. Subdomain Refinement

A subdomain:

```text
D_s ≼ D
```

means that `D_s` is a semantic refinement of `D`.

This requires:

1. parent meaning remains applicable;
2. parent invariants remain satisfied;
3. additional constraints are explicit;
4. new concepts do not silently redefine parent concepts;
5. identity remains stable;
6. dependencies remain explicit.

Where formal models exist:

```text
F_s ⊑ F
```

SHOULD express corresponding formal refinement.

---

# 55. Formalisation Selection Criteria

A domain SHOULD be considered for Lean formalisation when one or more apply:

```text
High semantic centrality
High downstream dependency
High consequence of error
Mathematical structure
Security significance
Concurrency significance
Identity significance
Complex invariants
Difficult exhaustive testing
Strong compositional properties
Potential theorem reuse
```

A domain MAY reasonably remain informal where these factors are absent.

---

# 56. Formalisation Priority

A practical priority order is:

```text
1. Foundational semantics
2. Core invariants
3. Cross-domain contracts
4. High-risk semantics
5. Reusable mathematical structures
6. Complex transformations
7. Provider-specific properties
8. Low-risk implementation details
```

This avoids spending enormous formalisation effort on low-value implementation details while foundational semantics remain unproven.

---

# 57. Reference Development Agent Contract

Development agents extending SCR SHALL follow this sequence:

```text
1. Inspect the library graph.
2. Search for existing semantic concepts.
3. Identify the semantic owner.
4. Inspect parent-domain specifications.
5. Inspect related formal models.
6. Inspect existing invariants.
7. Inspect tests and counterexamples.
8. Inspect providers.
9. Determine whether the proposal is:
       domain
       subdomain
       concept
       implementation
       provider
       cross-cutting concern
10. Update the specification.
11. Add validation.
12. Determine formalisation suitability.
13. Add/update Lean model where justified.
14. Establish relevant proofs.
15. Implement.
16. Update status.
17. Update the library graph.
18. Validate the complete change.
```

An agent SHALL NOT begin by creating implementation code when the semantic ownership is unresolved.

---

# 58. Formalisation Agent Requirements

Where Lean formalisation is appropriate, a development agent SHOULD:

1. identify the relevant normative specification;
2. identify its formal dependencies;
3. reuse existing definitions;
4. avoid duplicate mathematical structures;
5. state assumptions explicitly;
6. avoid unnecessary axioms;
7. prove critical invariants;
8. attempt countermodels where practical;
9. record proof coverage;
10. update the domain status;
11. update the library graph;
12. identify any specification defects discovered during formalisation.

---

# 59. Completion Contract

A domain extension SHALL NOT be considered complete merely because implementation code exists.

The minimum completion chain is:

```text
Specification
      ↓
Validation
      ↓
Formalisation decision
      ↓
Implementation
      ↓
Verification
      ↓
Status
      ↓
Library Graph
```

Where formalisation is justified:

```text
Specification
      ↓
Validation
      ↓
Lean Formalisation
      ↓
Proof
      ↓
Implementation
      ↓
Verification
```

---

# 60. Conformance

Mature domains MAY introduce:

```text
104_conformance.md
```

This document SHOULD define:

* mandatory semantic behaviour;
* required invariants;
* required tests;
* implementation obligations;
* provider obligations;
* formal proof requirements where applicable.

Conformance SHALL remain distinct from implementation.

---

# 61. Formal Model Documentation

Domains with substantial Lean formalisation SHOULD introduce:

```text
105_formal_model.md
```

This document SHOULD explain:

* what has been formalised;
* what has not;
* correspondence between specification and Lean;
* formal assumptions;
* axioms;
* theorem coverage;
* proof dependencies;
* known limitations;
* correspondence to implementation.

---

# 62. Validation Tooling

SCR tooling SHOULD eventually support commands conceptually equivalent to:

```text
scr domain list

scr domain show <id>

scr domain validate <id>

scr domain graph <id>

scr domain dependencies <id>

scr domain consumers <id>

scr domain providers <id>

scr domain status <id>

scr domain conformance <id>

scr domain formal <id>

scr domain proofs <id>

scr concept owner <id>

scr concept consumers <id>
```

These commands are architectural goals rather than requirements for immediate implementation.

---

# 63. Formalisation Reporting

A project progress report SHOULD distinguish:

```text
Semantic maturity
Implementation maturity
Validation maturity
Formalisation maturity
Proof maturity
Conformance maturity
```

For example:

```text
Spatial Partition
    semantic:       specified
    validation:     validated
    formalisation:  modeled
    proofs:         proved
    implementation: implemented
    conformance:    partial
```

This prevents an implemented domain from being incorrectly described as formally verified.

---

# 64. Formalisation and Semantic Confidence

SCR SHALL avoid equating:

```text
formalised = correct
```

Instead:

```text
formalised
    means
    a formal model exists

proved
    means
    selected properties have machine-checked proofs

verified
    means
    correspondence and assurance claims have been established
```

Formalisation increases confidence but does not eliminate the need for semantic scrutiny.

---

# 65. Required Counterexamples

Each significant domain SHOULD identify at least some counterexamples to naïve interpretations.

Examples:

```text
"same representation" ≠ "same semantic object"

"same location" ≠ "same identity"

"same provider" ≠ "same semantic capability"

"implemented" ≠ "specified"

"type-checks" ≠ "semantically correct"

"proved" ≠ "correctly modeled"

"child domain" ≠ "independent semantics"
```

These counterexamples SHALL inform validation and, where useful, formal modelling.

---

# 66. Semantic Traceability

For significant concepts, SCR SHOULD support the trace:

```text
Concept
  ↓
Specification
  ↓
Invariant
  ↓
Validation Test
  ↓
Lean Proposition
  ↓
Lean Proof
  ↓
Implementation
  ↓
Conformance Test
```

Not every concept will have every stage.

The traceability graph should make the absence explicit rather than implying coverage.

---

# 67. Architectural Principle

The SCR library therefore forms a layered semantic development system:

```text
                 ┌───────────────────────┐
                 │      Semantics        │
                 │     101_spec.md       │
                 └───────────┬───────────┘
                             │
                 ┌───────────▼───────────┐
                 │      Validation       │
                 │ tests / invariants /  │
                 │    counterexamples    │
                 └───────────┬───────────┘
                             │
                 ┌───────────▼───────────┐
                 │      Formalisation    │
                 │ Lean models / proofs  │
                 └───────────┬───────────┘
                             │
                 ┌───────────▼───────────┐
                 │     Implementation    │
                 │     Mojo / MLIR /     │
                 │       other code      │
                 └───────────┬───────────┘
                             │
                 ┌───────────▼───────────┐
                 │       Providers       │
                 │ H3 / VDB / Vulkan /   │
                 │ CUDA / etc.           │
                 └───────────────────────┘
```

The direction is intentional.

---

# 68. Final Architectural Principle

The SCR library SHALL grow through controlled semantic refinement.

The governing relationship is:

```text
Meaning
   ↓
Specification
   ↓
Validation
   ↓
Formalisation where valuable
   ↓
Proof where possible
   ↓
Implementation
   ↓
Provider realization
```

Not:

```text
Code
   ↓
Accidental behaviour
   ↓
Retroactive semantics
```

Lean provides SCR with a mechanism for turning important semantic claims into machine-checked mathematical evidence.

It is therefore a **first-class component of the formalisation process**, but not a mandatory requirement for every domain.

The ultimate objective is not to maximize the amount of Lean code.

The objective is to maximize **semantic precision, composability, falsifiability, and trustworthy execution**.

> **SCR grows by semantic refinement.
> Specifications define the meaning.
> Validation challenges the meaning.
> Lean proves selected consequences of the meaning.
> Implementations realize the meaning.
> Providers supply the mechanisms.
> The library graph preserves the relationships.**
