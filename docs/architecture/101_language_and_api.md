# SCR Language and Semantic API Architecture

**Document:** `docs/architecture/101_language_and_api.md`
**Status:** Normative
**Version:** 0.0.1
**Scope:** Semantic Computational Runtime (SCR)
**Applies to:** All SCR semantic domains, libraries, runtimes, providers, applications, and user-facing APIs

---

## 1. Purpose

This document defines the relationship between the **SCR semantic model**, its **MLIR implementation**, and the **Mojo programming interface** exposed to SCR users.

SCR is fundamentally a semantic computational system. Its semantic definitions, operations, relationships, constraints, and transformations are expressed through the SCR semantic model and represented canonically in MLIR.

However, SCR is intended to be used as a programming environment by application developers. Users should not be required to construct or manipulate raw MLIR in order to use SCR semantic capabilities.

Therefore:

> **MLIR is the canonical semantic implementation and compiler representation of SCR. Mojo is the canonical user-facing programming language and semantic API of SCR.**

The Mojo interface is a projection of the SCR semantic system into an ergonomic programming language. It is not an independent implementation of the semantic library.

---

# 2. Architectural Principle

SCR maintains a strict separation between:

1. **Semantic definition**
2. **Semantic representation**
3. **Compilation and transformation**
4. **Runtime manifestation**
5. **User-facing programming interface**

The architectural relationship is:

```text
                    SCR Semantic Model
                           │
                           │ defines meaning
                           ▼
                         MLIR
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
         Verification   Lowering     Runtime
              │            │            │
              └────────────┼────────────┘
                           │
                           ▼
                    Mojo Semantic API
                           │
                           ▼
                    SCR Application
```

The arrows represent semantic projection and implementation relationships, not necessarily a single compilation pipeline.

The critical invariant is:

> **Mojo must not become a second semantic implementation of SCR.**

The semantic contract remains authoritative in SCR and its canonical MLIR representation.

---

# 3. Canonical Language Roles

## 3.1 SCR Semantic Model

The SCR semantic model defines what entities, operations, relationships, transformations, constraints, and behaviours mean.

The semantic model is independent of the syntax used by an application developer.

A semantic concept therefore exists before a particular Mojo function, MLIR operation, provider implementation, or runtime manifestation is selected.

---

## 3.2 MLIR

MLIR is the canonical implementation and compiler representation of SCR semantics.

SCR semantic libraries are defined and implemented using MLIR extensions and associated MLIR infrastructure.

MLIR provides the canonical representation through which SCR semantics can be:

* represented;
* verified;
* transformed;
* analysed;
* composed;
* lowered;
* optimized;
* mapped to runtime mechanisms;
* mapped to provider implementations;
* inspected as computational structure.

MLIR is therefore an architectural foundation of SCR rather than merely an intermediate implementation detail.

Where semantic ambiguity exists between a user-facing API and the underlying semantic representation, the semantic contract must be resolved in favour of the SCR semantic model and its canonical MLIR representation.

---

## 3.3 Mojo

Mojo is the standard programming language for SCR users.

SCR users should ordinarily interact with SCR through idiomatic Mojo APIs rather than directly manipulating MLIR.

The purpose of the Mojo layer is to make SCR semantics usable as a normal programming environment while preserving the semantic capabilities of the underlying system.

Mojo therefore provides:

* user-facing types;
* functions;
* constructors;
* operators;
* iteration;
* composition;
* error handling;
* resource management;
* domain-specific abstractions;
* application-level orchestration.

These interfaces must ultimately correspond to SCR semantic operations and structures.

---

# 4. Semantic Authority

The following ordering defines semantic authority within SCR:

```text
SCR Semantic Definition
        ↓
Canonical MLIR Representation
        ↓
Runtime / Provider Manifestation
        ↓
Mojo User Interface
```

This ordering does **not** mean that Mojo is less important than MLIR to users.

It means that the Mojo interface must derive its meaning from SCR rather than independently defining a competing semantic system.

The user experience should therefore be:

```text
Mojo
  ↓
SCR semantic operation
  ↓
MLIR
  ↓
verification / transformation / lowering
  ↓
runtime / provider
```

The user should be able to remain at the Mojo level unless lower-level access is explicitly required.

---

# 5. Mojo API Projection

A Mojo API is a **semantic projection**.

It exposes SCR capabilities using constructs that are natural to Mojo developers.

For example, an underlying semantic operation might conceptually be represented as:

```text
scr.identity.allocate(domain, reservation)
        →
scr.identity.sid
```

The corresponding Mojo interface should expose an idiomatic abstraction such as:

```mojo
let identity = domain.allocate()
```

The exact syntax is determined by the Mojo implementation and the SCR API design.

The important architectural rule is:

> **The Mojo API may simplify, compose, or reorganize the presentation of semantic operations without changing their meaning.**

A single Mojo operation may therefore correspond to:

* one MLIR operation;
* several MLIR operations;
* a verified MLIR region;
* an MLIR transformation;
* a runtime operation;
* or a semantic composition of existing SCR primitives.

The mapping does not have to be one-to-one.

---

# 6. No Parallel Semantic Library

SCR must not develop two independent semantic implementations:

```text
             SCR Semantics
               /      \
              /        \
          MLIR          Mojo
        implementation  implementation
```

This architecture is prohibited.

Instead:

```text
             SCR Semantics
                   │
                 MLIR
                   │
          ┌────────┴────────┐
          │                 │
       Runtime          Mojo API
       / Providers          │
                            │
                       Applications
```

The Mojo layer may contain implementation code necessary to provide an ergonomic interface, but that code must not silently establish an alternative semantic definition.

Where functionality can be represented directly through SCR/MLIR semantics, the Mojo API should use that representation.

---

# 7. Semantic API Requirements

Every user-facing semantic capability should be evaluated against the following requirements.

## 7.1 Semantic Definition

The underlying concept must have a defined meaning within SCR.

---

## 7.2 Canonical MLIR Representation

The capability must have an appropriate canonical MLIR representation where it constitutes SCR semantic functionality.

---

## 7.3 Verification

The semantic operation should be subject to the appropriate SCR verification mechanisms.

Verification may occur at:

* construction;
* compilation;
* MLIR verification;
* lowering;
* runtime;
* or multiple stages.

---

## 7.4 Mojo Projection

Where the capability is intended for application developers, it should have an idiomatic Mojo interface.

The interface should expose the semantic abstraction rather than unnecessarily exposing implementation details.

---

## 7.5 Testing

The Mojo API must be tested at the user-facing level.

Testing should verify both:

```text
Mojo behaviour
```

and:

```text
underlying SCR semantic behaviour
```

where appropriate.

A Mojo test passing by itself is not sufficient evidence that the underlying SCR semantic implementation is correct.

---

# 8. API Design Principles

## 8.1 Idiomatic Mojo

SCR APIs should feel like Mojo APIs.

They should not merely expose mechanically generated wrappers around MLIR operations.

Poor abstraction:

```mojo
scr_mlir_op_identity_allocate(
    domain_id,
    reservation_id,
    authority_generation,
    region_start,
    region_end
)
```

Preferred abstraction:

```mojo
let identity = domain.allocate()
```

The second interface may internally produce a substantially more complex MLIR representation.

The complexity belongs behind the semantic API boundary unless the user explicitly requires lower-level control.

---

## 8.2 Semantic Types

Where appropriate, semantic concepts should have explicit Mojo types.

For example:

```mojo
var domain: IdentityDomain
var identity: SemanticID
var reservation: IdentityReservation
```

These types should correspond to meaningful SCR semantic concepts.

They should not merely be opaque wrappers around implementation handles unless the concept itself is intentionally opaque.

---

## 8.3 Semantic Operations

Functions should expose meaningful transformations of semantic state.

For example:

```mojo
let sid = domain.allocate()
let entity = identity.bind(sid)
```

rather than exposing internal implementation machinery such as:

```mojo
let handle = mlir_value(...)
```

The latter may exist as a lower-level interface where required, but it is not the preferred application interface.

---

## 8.4 Composition

Mojo APIs should support composition of SCR semantic structures.

The user should be able to construct increasingly complex semantic programs from smaller semantic operations.

This is consistent with the SCR principle that computation is a transformation of semantic structure within a field.

---

# 9. Relationship to the Semantic Graph

SCR represents computational structure as semantic relationships.

Consequently, the Mojo API must not obscure the fact that user programs ultimately construct and transform semantic graph structures.

Conceptually:

```text
Mojo source
     │
     ▼
semantic objects
     │
     ▼
semantic relationships
     │
     ▼
semantic graph / field
     │
     ▼
MLIR
     │
     ▼
runtime manifestation
```

A convenient Mojo abstraction may hide graph construction from the user, but the resulting semantics must remain representable within the SCR graph model.

The abstraction is therefore a convenience of expression, not a replacement ontology.

---

# 10. Lifting MLIR Functions into Mojo

SCR semantic library functions implemented in MLIR should be made available to Mojo users where those functions constitute user-facing semantic functionality.

This process is referred to in SCR as **lifting** or **semantic API projection**.

The lift should preserve:

* semantic identity;
* input meaning;
* output meaning;
* type constraints;
* preconditions;
* postconditions;
* error semantics;
* ownership semantics;
* lifetime semantics;
* determinism guarantees;
* relevant execution semantics.

The Mojo function may provide a substantially more convenient interface, but it must not change the underlying contract.

---

# 11. Abstraction Levels

SCR should support multiple levels of interaction.

## Level 1 — Application API

Normal users should primarily use Mojo.

```text
Mojo application
```

This is the preferred level.

---

## Level 2 — Semantic API

Advanced users may interact directly with richer SCR semantic abstractions.

```text
Mojo
  ↓
SCR semantic objects / fields / graphs
```

---

## Level 3 — MLIR

Compiler, library, infrastructure, and advanced systems developers may interact directly with SCR MLIR.

```text
SCR MLIR
```

This level is appropriate for:

* semantic library development;
* compiler transformations;
* verification;
* lowering;
* optimization;
* provider integration;
* runtime development;
* advanced metaprogramming;
* diagnostics.

---

## Level 4 — Runtime / Provider

Implementation developers may work directly with runtime and provider mechanisms.

```text
runtime
provider
hardware
```

These layers must remain subordinate to the semantic model.

---

# 12. Escape Hatches

The existence of a high-level Mojo API must not prevent legitimate access to lower layers.

SCR may expose controlled escape hatches for advanced users.

For example:

```text
Mojo
  ↓
SCR API
  ↓
SCR semantic object
  ↓
MLIR
```

An advanced developer may intentionally cross the abstraction boundary.

Such access must be explicit.

It must not make raw MLIR the normal application programming model.

---

# 13. Error and Verification Semantics

Errors exposed through Mojo should correspond to meaningful SCR semantic failures where possible.

For example:

```mojo
domain.allocate()
```

may fail because:

* the domain is exhausted;
* the authority is revoked;
* the reservation is invalid;
* the requested allocation lies outside the delegated region;
* a transaction conflicts with current state.

The Mojo interface should expose these as meaningful semantic errors rather than leaking arbitrary compiler or runtime implementation failures.

Where an MLIR verification failure is surfaced to the user, SCR should provide an appropriate diagnostic representation.

---

# 14. Ownership and Lifetime

Mojo interfaces must preserve the ownership and lifetime semantics of underlying SCR objects.

This is particularly important for:

* semantic fields;
* graph nodes;
* buffers;
* tensors;
* spatial objects;
* runtime resources;
* provider resources;
* external resources.

A convenient Mojo API must not imply ownership where the underlying resource is borrowed.

Likewise, a Mojo object must not outlive the semantic or runtime object on which its validity depends unless SCR explicitly defines such persistence.

---

# 15. Identity and Semantic Handles

Semantic identity must not be confused with implementation handles.

For example:

```text
SemanticID
    ↓
SCR semantic object
    ↓
runtime representation
    ↓
implementation handle
```

A Mojo API may provide an ergonomic object representing a semantic entity, but the object itself is not necessarily the canonical semantic identity.

This distinction is particularly important for SCR Identity.

A runtime object may move, be recreated, or change implementation representation without changing its semantic identity.

---

# 16. Domain-Level Application

This architecture applies to every SCR semantic domain.

Examples include:

```text
core
math
data
tensor
field
graph
geometry
topology
spatial
morphology
physics
dynamics
simulation
agent
neural
render
stream
system
identity
```

For each domain, the intended progression is:

```text
Semantic definition
        ↓
Specification
        ↓
MLIR implementation
        ↓
Verification
        ↓
Runtime/provider integration where required
        ↓
Mojo semantic API
        ↓
Mojo tests
        ↓
End-to-end validation
```

A domain should not be considered complete merely because its MLIR implementation exists if that functionality is intended to be consumed by normal SCR application developers.

---

# 17. Application Development Model

An SCR application should normally look conceptually like:

```text
Mojo Application
       │
       ▼
SCR Mojo API
       │
       ▼
SCR Semantic Model
       │
       ▼
SCR MLIR
       │
       ├── verification
       ├── transformation
       ├── lowering
       │
       ▼
SCR Runtime / EGS
       │
       ├── providers
       ├── computation
       ├── storage
       ├── messaging
       └── manifestation
```

The application developer should not need to understand every implementation layer in order to use the system.

However, the architecture must remain inspectable and traversable for developers who need to work at lower levels.

---

# 18. Library Structure

Where practical, a semantic library should separate its implementation concerns along the following lines:

```text
<domain>/
├── 101_spec.md
├── 102_status.yaml
├── 103_library.graph.json
│
├── 01_definition/
├── 02_mlir/
├── 03_verification/
├── 04_runtime/
├── 05_mojo/
└── 06_tests/
```

The exact directory structure is governed by the existing SCR repository conventions.

The important architectural distinction is:

```text
MLIR
    = canonical semantic implementation

Mojo
    = canonical user-facing semantic interface
```

The Mojo directory must therefore not become a second semantic library.

---

# 19. Generated and Hand-Written Interfaces

SCR may use generated Mojo bindings where appropriate.

Generated interfaces are acceptable when they preserve semantic correctness and provide an adequate user experience.

However, mechanically generated bindings are not automatically considered a satisfactory user-facing API.

Where necessary, a hand-written Mojo abstraction should sit above generated bindings:

```text
SCR MLIR
   ↓
generated binding
   ↓
idiomatic Mojo abstraction
   ↓
application
```

The abstraction should be introduced when the direct representation would expose unnecessary compiler, IR, or runtime details.

---

# 20. API Stability

The semantic contract and the user-facing API have related but distinct stability requirements.

Changes to an internal MLIR representation do not necessarily require a change to the Mojo API.

Conversely, a change to the Mojo API should not redefine the underlying semantic model merely for syntactic convenience.

Where compatibility matters:

```text
Semantic Contract
        ↓
MLIR representation
        ↓
Mojo API
```

may evolve at different rates while preserving the semantic contract.

---

# 21. Implementation Completion Criterion

A user-facing SCR capability is considered **implemented** only when the applicable stages have been completed.

At minimum:

```text
[ ] Semantic definition exists
[ ] Semantic specification exists
[ ] MLIR implementation exists
[ ] MLIR verification exists
[ ] Tests exist
[ ] Mojo API exists
[ ] Mojo API is idiomatic
[ ] Mojo tests exist
[ ] Runtime/provider integration exists where required
[ ] End-to-end validation exists where required
```

Not every semantic primitive necessarily requires every stage.

For example, an internal compiler-only operation may not require a public Mojo interface.

The determination must be explicit in the relevant domain specification and status documentation.

---

# 22. Architectural Invariants

The following invariants are normative.

### API-I001 — Semantic Authority

SCR semantic meaning is defined by the SCR semantic model and represented canonically in MLIR.

### API-I002 — Mojo as User Language

Mojo is the standard user-facing programming language of SCR.

### API-I003 — No Semantic Duplication

Mojo must not establish an independent semantic implementation of SCR.

### API-I004 — Semantic Preservation

A Mojo semantic API must preserve the meaning of the underlying SCR operation.

### API-I005 — Idiomatic Interface

User-facing SCR functionality should be exposed through idiomatic Mojo abstractions rather than raw MLIR mechanics.

### API-I006 — Lower-Layer Accessibility

Advanced users and SCR developers must retain controlled access to semantic and MLIR layers.

### API-I007 — Implementation Independence

The Mojo API should not unnecessarily expose internal MLIR representation details.

### API-I008 — Explicit Runtime Boundary

Runtime and provider mechanisms are manifestations of SCR semantics and must not silently redefine them.

### API-I009 — Identity Separation

Semantic identity must remain distinct from implementation handles and runtime manifestations.

### API-I010 — Verifiable Projection

The relationship between a Mojo API and its underlying semantic implementation must be testable and, where practical, mechanically verifiable.

---

# 23. Design Test

When introducing a new SCR capability, developers should ask:

### Question 1

**What is the semantic concept?**

If the answer is unclear, the API is premature.

### Question 2

**How is the concept represented in SCR MLIR?**

If no representation exists, determine whether the semantic library requires extension.

### Question 3

**How is the concept verified?**

Identify compile-time, semantic, runtime, or provider-level verification.

### Question 4

**Does the capability need a public Mojo interface?**

Not every internal compiler mechanism does.

### Question 5

**What should the user experience look like?**

Design the Mojo interface from the semantic abstraction, not from the MLIR syntax.

### Question 6

**Does the Mojo interface introduce new meaning?**

If yes, determine whether that meaning belongs in SCR semantics rather than the Mojo API.

### Question 7

**Can the Mojo operation be traced back to the semantic representation?**

If not, investigate whether the abstraction has crossed the semantic boundary incorrectly.

---

# 24. Example: Identity

An SCR Identity implementation may internally contain a number of semantic operations:

```text
identity.domain
identity.authority
identity.reservation
identity.allocate
identity.bind
identity.provenance
```

The MLIR representation may expose these operations explicitly.

The user-facing Mojo API may instead provide:

```mojo
let domain = identity.create_domain(...)
let reservation = domain.reserve(...)
let sid = reservation.commit()
```

The Mojo interface does not need to expose every underlying MLIR operation.

Nevertheless, each operation must retain its SCR-defined semantic meaning.

The abstraction is therefore:

```text
Mojo expression
      ↓
semantic operation
      ↓
MLIR
      ↓
verification
      ↓
runtime manifestation
```

not:

```text
Mojo implementation
      ↓
independent identity system
```

---

# 25. Example: Computational Function

An SCR function may conceptually be represented as a graph:

```text
Inputs
  ↓
Transformation
  ↓
Outputs
```

Its MLIR representation may contain the complete semantic structure required to represent and transform that graph.

The Mojo user should be able to write an ordinary function-like abstraction:

```mojo
fn transform(input: Value) -> Value:
    ...
```

while SCR retains the ability to represent the resulting computation as semantic graph structure.

Thus:

> **Mojo provides the familiar programming expression; SCR provides the semantic computational model.**

---

# 26. Relationship to EGS

The Executable Graph Server (EGS) operates below the application-facing Mojo layer.

Conceptually:

```text
Mojo Application
       ↓
SCR Semantic API
       ↓
SCR MLIR
       ↓
EGS
       ↓
Providers / Runtime / Infrastructure
```

EGS manifests executable graph structures and associated infrastructure.

The Mojo API should therefore not require application developers to understand EGS internals for ordinary programming.

At the same time, advanced applications may expose or control EGS-level semantics where required.

---

# 27. Relationship to Providers

Providers such as rendering, geometry, numerical, storage, hardware, or simulation implementations are manifestations of SCR semantics.

A Mojo API should preferentially expose the SCR semantic abstraction rather than a provider-specific API.

For example:

```text
SCR spatial object
       ↓
provider selection
       ↓
CGAL / H3 / OpenVDB / Vulkan / etc.
```

rather than:

```text
Mojo application
       ↓
provider-specific implementation
```

Provider-specific interfaces may exist where provider-specific capabilities are intentionally exposed.

Such interfaces must be explicitly identified as provider-specific rather than being confused with the canonical SCR semantic API.

---

# 28. Principle of Least Semantic Exposure

The Mojo interface should expose sufficient semantic power for the user to construct the intended computation without requiring unnecessary knowledge of internal implementation layers.

This does not mean that SCR should hide its semantics.

Rather:

> **Complexity should be represented by the system, not unnecessarily imposed upon the application programmer.**

A good SCR Mojo API should therefore allow a developer to express sophisticated semantic computation in ordinary Mojo while retaining the full semantic structure required by SCR underneath.

---

# 29. Long-Term Direction

The intended long-term relationship is:

```text
                     SCR
                      │
             Semantic Foundation
                      │
                    MLIR
                      │
       ┌──────────────┼──────────────┐
       │              │              │
    Compiler        Runtime       Analysis
       │              │              │
       └──────────────┼──────────────┘
                      │
                 Mojo API
                      │
              ┌───────┴───────┐
              │               │
        Application      Advanced User
```

SCR should make it possible for developers to work naturally in Mojo while retaining the deeper properties of a semantic computational system.

The user should experience SCR as a programming language and runtime.

The system itself should retain the richer representation of:

* semantic fields;
* graphs;
* topology;
* spatial relationships;
* computation;
* identity;
* state;
* transformations;
* runtime manifestation.

Mojo is therefore the **human programming surface** of SCR, while MLIR is the **canonical computational representation** through which SCR semantics become executable.

---

# 30. Summary Principle

The architecture can be reduced to one rule:

> **Define semantics once, represent them canonically in MLIR, and lift those semantics into an idiomatic Mojo programming interface.**

Or, operationally:

```text
Define
  ↓
Specify
  ↓
Implement in MLIR
  ↓
Verify
  ↓
Lift into Mojo
  ↓
Test
  ↓
Manifest
  ↓
Validate
```

Mojo is not an alternative to the SCR semantic library.

**Mojo is how SCR users access the semantic library.**

MLIR is not merely hidden implementation detail.

**MLIR is the canonical representation through which SCR semantics are implemented, verified, transformed, and lowered.**

The two layers therefore serve different purposes while remaining one semantic system.
