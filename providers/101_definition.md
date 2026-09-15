# SCR Providers

**Path:** `providers/101_definition.md`
**Version:** 0.0.1
**Status:** Normative Definition

---

## 1. Purpose

The `providers` subsystem defines the boundary through which concrete computational implementations participate in the Semantic Computational Runtime (SCR).

Providers connect SCR semantic capabilities to concrete:

* libraries;
* frameworks;
* engines;
* runtimes;
* databases;
* services;
* protocols;
* hardware;
* accelerators;
* external systems;
* executable implementations.

The Provider subsystem MUST preserve the separation between:

> **semantic meaning and concrete implementation.**

The Provider subsystem MUST NOT become a second semantic library.

---

# 2. Fundamental Principle

SCR follows:

> **Do not build a kernel when a good kernel already exists. Build the semantic bridge that allows it to participate in SCR.**

When a suitable external implementation exists, SCR SHOULD integrate it through the Provider architecture rather than reimplementing the underlying capability.

When no suitable implementation exists, SCR MAY implement the capability itself.

Such an implementation MUST nevertheless participate through the same Provider architecture where provider substitution is meaningful.

---

# 3. Definition

A **Provider** is a concrete implementation or external capability source that satisfies one or more declared SCR semantic capabilities or contracts.

Formally:

```text
Provider
    realizes
        Semantic Capability
            under
                Provider Contract
```

A Provider is therefore an **implementation role**, not necessarily a software package, executable, process, library, or service.

---

# 4. Provider Role

The term Provider describes the role an implementation plays relative to SCR.

A Provider MAY be:

* a library;
* an engine;
* a framework;
* a runtime;
* a native executable;
* a WASM runtime;
* a database;
* a remote service;
* a hardware device;
* a compiler;
* an accelerator;
* an operating-system facility;
* an SCR-native implementation.

The packaging of a Provider does not determine its semantic identity.

---

# 5. Provider Architecture

The Provider subsystem participates in the following architecture:

```text
┌─────────────────────────────────────────────┐
│              SCR SEMANTIC LAYER             │
│                                             │
│ Entity  State  Field  Operation  Capability │
│ Service Port   Transformation   Interface   │
└──────────────────────┬──────────────────────┘
                       │
                Provider Contract
                       │
┌──────────────────────▼──────────────────────┐
│             IMPLEMENTATION LAYER             │
│                                             │
│ Implementation                              │
│ ImplementationBinding                       │
│ ExecutableArtifact                          │
│ ExecutionContract                           │
│ EntryPoint                                  │
└──────────────────────┬──────────────────────┘
                       │
                    Adapter
                       │
┌──────────────────────▼──────────────────────┐
│                PROVIDER                     │
│                                             │
│ Library / Engine / Runtime / Service /      │
│ Database / Device / Framework / System     │
└──────────────────────┬──────────────────────┘
                       │
                  Execution Runtime
                       │
┌──────────────────────▼──────────────────────┐
│           COMPUTATIONAL SYSTEM              │
│                                             │
│ CPU / GPU / OS / Network / Device / Cloud  │
└─────────────────────────────────────────────┘
```

---

# 6. Provider Semantic Boundary

The Provider boundary separates:

```text
SCR meaning
```

from:

```text
implementation mechanism
```

A Provider MUST implement against the semantic contract presented to it.

The Provider MUST NOT require the SCR semantic layer to adopt its internal ontology merely to use its functionality.

---

# 7. Provider and Semantic Library

The SCR semantic library defines:

* entities;
* relations;
* fields;
* state;
* transformations;
* operations;
* capabilities;
* contracts;
* domain semantics;
* execution semantics.

Providers implement those semantics.

Providers MUST NOT define the meaning of fundamental SCR semantic concepts.

For example:

```text
lib/physics/
```

may define:

```text
Dynamics
Body
Force
Constraint
Motion
```

while:

```text
providers/chrono/
```

may provide an implementation of those concepts.

Chrono does not therefore become the definition of `Dynamics`.

---

# 8. Provider and Provider Contract

Every conforming Provider MUST identify the Provider Contract or Contracts it satisfies.

The relationship is:

```text
Provider
    │
    └── conformsTo
            │
            ▼
      Provider Contract
```

The normative Provider Contract architecture is defined by:

```text
docs/architecture/103_provider_contracts.md
```

A Provider MUST NOT claim semantic compatibility merely because its API resembles an SCR interface.

---

# 9. Provider and Capability

A Provider MAY implement one or many semantic capabilities.

Likewise, a semantic capability MAY be implemented by one or many Providers.

Therefore:

```text
Capability ↔ Provider
```

is generally many-to-many.

Example:

```text
Chrono
├── Dynamics
├── Collision
├── Constraint
└── Simulation
```

and:

```text
Dynamics
├── Chrono
├── PhysX
├── MuJoCo
└── SCR Reference Provider
```

---

# 10. Provider and Service

A Service is a semantic/application concept.

A Provider is an implementation role.

Therefore:

```text
Service ≠ Provider
```

A Service MAY be implemented by a Provider.

For example:

```text
TradingService
    │
    ▼
MarketDataPort
    │
    ▼
MarketDataAdapter
    │
    ▼
Luno Provider
```

The Service remains semantically meaningful if the Provider changes.

---

# 11. Provider and Adapter

An Adapter translates between a semantic contract and a Provider interface.

```text
Semantic Port
      │
      ▼
   Adapter
      │
      ▼
   Provider
```

An Adapter MUST preserve the semantic guarantees of the relevant Provider Contract.

Provider-specific representations MAY exist inside the Adapter.

They MUST NOT leak through the semantic boundary unless explicitly permitted by the contract.

---

# 12. Provider and Implementation

An Implementation is an executable realization of a semantic element.

A Provider is a capability source or implementation role.

The relationship MAY therefore be:

```text
Implementation
      │
      └── suppliedBy
              │
              ▼
           Provider
```

However, an Implementation MAY itself function as a Provider.

These concepts MUST NOT be assumed to be identical.

---

# 13. Provider and Executable Artifact

An Executable Artifact is a concrete executable representation.

Examples:

```text
native binary
WASM module
shared library
GPU binary
container image
compiled MLIR artifact
```

An artifact is not inherently a Provider.

For example:

```text
order_service.wasm
```

is an artifact.

The runtime executing that artifact may be a Provider.

---

# 14. Provider and Runtime

An Execution Runtime executes artifacts.

Examples:

```text
WASM runtime
JVM
CLR
native process runtime
GPU runtime
container runtime
```

A runtime MAY itself be represented as a Provider.

However:

```text
Provider ≠ Runtime
```

is the default architectural distinction.

---

# 15. Provider and EGS

The Executable Graph Server (EGS) is responsible for resolving and orchestrating Provider-backed implementations.

EGS MAY:

* discover Providers;
* discover Provider Contracts;
* evaluate capabilities;
* resolve dependencies;
* select Providers;
* establish Implementation Bindings;
* allocate execution Spaces;
* instantiate Providers;
* monitor lifecycle;
* perform substitution;
* handle Provider failure.

EGS MUST NOT redefine the semantic meaning of a capability.

---

# 16. Provider Discovery

Providers SHOULD expose machine-readable metadata sufficient for EGS to determine:

```text
Provider identity
Provider version
Supported contracts
Contract versions
Capabilities
Operations
Fidelity
Determinism
Resource requirements
Platform requirements
Security requirements
Lifecycle
Dependencies
Limitations
Provenance
```

Discovery metadata is descriptive.

It does not replace behavioural conformance.

---

# 17. Provider Identity

Provider identity MUST be distinct from semantic identity.

For example:

```text
Semantic Capability:
    scr.physics.dynamics

Providers:
    scr.provider.chrono
    scr.provider.physx
    scr.provider.mujoco
```

Provider identity identifies the implementation source.

Semantic identity identifies what the capability means.

---

# 18. Provider Version

Providers MUST expose an implementation version.

Provider versioning MUST remain distinct from:

```text
semantic version
provider contract version
artifact version
runtime version
```

For example:

```text
Capability:
    scr.physics.dynamics

Contract:
    v1

Provider:
    Chrono

Provider Version:
    9.x
```

---

# 19. Provider Provenance

Provider metadata SHOULD identify provenance including:

* Provider identity;
* Provider version;
* source identity;
* artifact identity;
* build identity;
* dependency versions;
* runtime;
* configuration;
* platform;
* execution environment.

Provenance is particularly important for:

* reproducibility;
* verification;
* validation;
* auditing;
* replay;
* scientific computation;
* security.

---

# 20. Provider Capabilities

A Provider MUST declare the capabilities it claims to provide.

A capability declaration MUST reference an SCR semantic capability or Provider Contract.

A Provider MUST NOT invent an alternative semantic identity merely because its internal API uses different terminology.

---

# 21. Provider Fidelity

Providers MAY declare fidelity characteristics including:

```text
exact
deterministic
approximate
statistical
learned
heuristic
reduced-order
real-time
high-fidelity
```

Where fidelity affects semantic validity, it MUST be represented in the Provider Contract.

Provider metadata MUST NOT claim a stronger guarantee than the implementation can satisfy.

---

# 22. Provider Determinism

Providers SHOULD declare whether execution is:

```text
deterministic
conditionally_deterministic
nondeterministic
```

Conditional determinism MAY depend upon:

* seed;
* hardware;
* Provider version;
* configuration;
* concurrency;
* precision;
* execution mode.

---

# 23. Provider Resource Requirements

Providers SHOULD declare required computational resources.

Examples include:

```text
CPU
memory
GPU
accelerator
storage
network
device
instruction set
shared memory
```

Resource requirements MUST remain distinguishable from semantic meaning.

EGS MAY use them when selecting and placing Providers.

---

# 24. Provider Platform Requirements

Providers MAY declare requirements such as:

```text
architecture
operating system
accelerator
runtime
driver
instruction set
ABI
container environment
```

Platform requirements are implementation requirements.

They MUST NOT become semantic requirements unless the platform itself has semantic significance.

---

# 25. Provider Lifecycle

Providers SHOULD expose lifecycle state.

A Provider MAY support:

```text
Created
Initialized
Configured
Ready
Running
Paused
Degraded
Stopping
Stopped
Failed
Terminated
```

Supported transitions MUST be compatible with the relevant Provider Contract.

---

# 26. Provider Health

Providers SHOULD expose sufficient health information for EGS to determine:

* available;
* ready;
* degraded;
* unavailable;
* failed.

Health information MAY influence Provider selection.

Health state MUST NOT be confused with semantic capability.

A Provider may be semantically capable while temporarily unavailable.

---

# 27. Provider Failure

Provider failure MUST be distinguishable from semantic rejection where required.

For example:

```text
ProviderUnavailable
```

is different from:

```text
OperationRejected
```

which is different from:

```text
ConstraintViolation
```

Provider integrations MUST preserve the failure semantics required by their Provider Contracts.

---

# 28. Provider Security

Providers MAY require:

* authentication;
* authorization;
* isolation;
* signed artifacts;
* trusted execution;
* encrypted communication;
* secure storage;
* capability restrictions.

Security requirements SHOULD be represented using SCR authority and security semantics.

A Provider MUST NOT bypass SCR authority merely because it is trusted infrastructure.

---

# 29. Provider Trust

EGS MAY evaluate Provider trust using:

* cryptographic identity;
* provenance;
* signatures;
* deployment policy;
* certification;
* isolation;
* operational history;
* administrator policy.

Trust is a property of the Provider and execution context.

Trust MUST NOT automatically become semantic capability.

---

# 30. Provider Dependencies

Providers MAY depend on:

* other Providers;
* runtimes;
* libraries;
* operating-system capabilities;
* devices;
* network services;
* computational Spaces.

Dependencies SHOULD be declared.

Provider dependencies MUST NOT create undeclared semantic coupling.

---

# 31. Provider Composition

Providers MAY be composed.

Example:

```text
Simulation
│
├── Physics Provider
│   └── Chrono
│
├── Spatial Provider
│   └── H3
│
├── Geometry Provider
│   └── CGAL
│
├── Volume Provider
│   └── OpenVDB
│
└── Rendering Provider
    └── Vulkan
```

Composition MUST preserve the semantic contracts presented to the consuming application or domain.

---

# 32. Provider Substitution

A Provider SHOULD be replaceable by another Provider when both satisfy the same required semantic contract.

Substitution MAY change:

* algorithm;
* numerical implementation;
* performance;
* resource consumption;
* artifact format;
* runtime;
* internal state representation.

Substitution MUST NOT change the semantic meaning of the consuming graph.

---

# 33. Provider Substitution Requirements

Before substitution, EGS SHOULD verify:

```text
Capability compatibility
Contract compatibility
Contract version
Fidelity
Resource requirements
Platform requirements
Security
Authority
Lifecycle
Availability
```

Only then should the alternative Provider be considered eligible.

---

# 34. Canonical Providers

A Provider MAY be designated **canonical**.

Canonical means:

> preferred or reference implementation for SCR integration.

Canonical MUST NOT mean:

* exclusive;
* permanent;
* semantically authoritative;
* mandatory for all deployments.

SCR MUST remain semantically independent of the canonical Provider.

---

# 35. Reference Providers

SCR MAY maintain reference Providers to establish:

* executable examples;
* conformance;
* regression testing;
* baseline performance;
* semantic validation;
* development bootstrap.

A Reference Provider MUST NOT automatically become the semantic definition of the capability.

---

# 36. Provider Promotion

A Provider concept MUST NOT automatically be promoted into SCR semantic ontology.

Promotion requires the semantic promotion test.

The concept SHOULD demonstrate:

1. independent semantic meaning;
2. implementation independence;
3. cross-provider relevance;
4. stable invariants;
5. value to semantic composition.

Provider API convenience is not sufficient.

---

# 37. Provider Leakage

Provider-specific ontology MUST remain outside normative SCR semantics.

The following are examples of Provider-specific concepts:

```text
PhysXActor
QWidget
GtkWidget
ReactComponent
RabbitMQChannel
CouchDBDocument
VkImage
CUDAStream
```

Such types MUST NOT become mandatory semantic dependencies merely because a Provider exposes them.

---

# 38. Provider Integration Boundary

A Provider integration SHOULD follow:

```text
SCR Semantic Capability
        │
        ▼
Provider Contract
        │
        ▼
Provider Adapter
        │
        ▼
Provider Implementation
        │
        ▼
Provider Runtime
```

The integration MAY collapse layers where implementation details do not require independent representation.

The semantic boundary MUST remain intact.

---

# 39. Provider Directory Structure

A Provider implementation SHOULD follow a structure similar to:

```text
providers/
└── <provider>/
    ├── 101_definition.md
    ├── 102_status.yaml
    ├── 103_provider.graph.json
    ├── 104_contract.md
    ├── adapter/
    ├── implementation/
    ├── tests/
    └── ...
```

The exact structure MAY vary according to the Provider.

The numbered documentation convention SHOULD remain consistent with SCR repository conventions.

---

# 40. Provider Definition

Every Provider SHOULD define:

```text
Identity
Purpose
Provider Type
Supported Capabilities
Supported Contracts
Dependencies
Requirements
Fidelity
Lifecycle
Security
Provenance
Limitations
Conformance
```

The Provider definition describes the integration.

It MUST NOT redefine the semantic domain.

---

# 41. Provider Status

Each Provider SHOULD maintain machine-readable status information.

Status SHOULD include:

```text
development state
contract conformance
supported versions
platform status
known limitations
test status
provider health
```

Status MUST remain separate from normative semantic definitions.

---

# 42. Provider Graph

A Provider MAY expose a machine-readable graph describing its relationships.

The graph SHOULD represent relationships such as:

```text
Provider
    supports Capability

Provider
    conformsTo Contract

Provider
    dependsOn Provider

Provider
    requires Resource

Provider
    executesWith Runtime

Provider
    implements Implementation
```

The Provider graph MUST NOT duplicate the entire SCR semantic ontology.

---

# 43. Provider Testing

Provider integrations MUST be tested at the semantic boundary.

Tests SHOULD include:

```text
Contract conformance
Capability discovery
Input validation
Output validation
State transitions
Failure semantics
Lifecycle
Authority
Fidelity
Determinism
Resource requirements
Provider substitution
```

Provider-internal unit tests MAY supplement semantic tests.

They MUST NOT replace them.

---

# 44. Provider Conformance

A Provider is conforming when:

1. it identifies its Provider Contract;
2. it declares its supported capabilities;
3. it satisfies mandatory contract requirements;
4. it passes required conformance tests;
5. it exposes required provenance;
6. it respects authority requirements;
7. it does not leak prohibited provider ontology into semantic contracts.

---

# 45. Provider Non-Conformance

A Provider MUST be considered non-conforming if it:

* violates a mandatory contract;
* falsely declares a capability;
* produces invalid semantic outputs;
* violates required state invariants;
* violates authority requirements;
* silently changes units or coordinate systems;
* violates declared fidelity;
* violates declared determinism;
* introduces undeclared semantic effects;
* requires provider-specific ontology in SCR semantic code.

---

# 46. Provider Availability Assessment

Before creating or adopting a Provider, SCR SHOULD assess:

### Capability

Does an implementation already exist?

### Maturity

Is there a mature and maintained implementation?

### Semantic Compatibility

Can its capabilities be expressed cleanly through SCR semantics?

### Architecture

Can it be isolated behind a Provider Contract?

### Performance

Does integration provide sufficient benefit?

### Licensing

Is its licensing compatible with SCR requirements?

### Security

Can it be trusted and isolated appropriately?

### Substitution

Can another implementation eventually replace it?

---

# 47. Provider Selection Principle

The default decision hierarchy is:

```text
Suitable leading Provider exists
        │
        ▼
Integrate it

No suitable Provider
        │
        ▼
Evaluate alternative Providers

No suitable Provider
        │
        ▼
SCR may implement capability

SCR implementation
        │
        ▼
Expose through Provider Contract
```

SCR SHOULD NOT duplicate mature functionality without a material architectural justification.

---

# 48. SCR-Native Providers

SCR MAY provide native implementations where necessary.

Examples may include capabilities fundamental to SCR itself.

Possible candidates include:

* semantic hypergraph;
* semantic identity;
* core relation machinery;
* semantic execution contracts;
* EGS;
* core messaging integration;
* foundational semantic state.

SCR-native Providers remain Providers at the implementation boundary even though they are maintained by SCR.

---

# 49. Application Providers

Application manifestations MAY be Providers.

Examples include:

```text
MojoFlow
Web
CLI
OGRE
Qt
GTK
XR
Agent Interface
```

These Providers implement or manifest Application semantics.

The Application semantic library MUST remain independent of them.

---

# 50. WASM Providers

WASM introduces two distinct roles:

```text
WASM Module
    = Executable Artifact

WASM Runtime
    = Execution Provider
```

A Provider MAY therefore use WASM as its execution mechanism without making WASM part of the semantic Application model.

---

# 51. Mojo Providers

Mojo MAY act as:

* implementation language;
* Provider implementation;
* runtime;
* library;
* compiler/toolchain component.

These roles MUST remain architecturally distinguishable.

A semantic Provider Contract MUST NOT depend on Mojo-specific syntax or APIs unless the contract itself is explicitly a Mojo infrastructure contract.

---

# 52. MLIR Providers

MLIR MAY be used to represent and transform Provider implementations.

SCR MAY define MLIR dialects for:

* semantic capabilities;
* Provider Contracts;
* implementation bindings;
* execution requirements;
* Provider declarations.

MLIR remains an implementation substrate.

It does not become the definition of Provider semantics merely because Providers are represented using MLIR.

---

# 53. Provider and Semantic Machine Model

Providers execute within Semantic Machine Spaces.

For example:

```text
Provider
    │
    ▼
Execution Space
    │
    ├── Process
    ├── Memory
    ├── Storage
    ├── Network
    └── Processor / Accelerator
```

Provider resource requirements MAY be resolved against the Semantic Machine Model.

Provider implementation details MUST NOT redefine the Semantic Machine Model.

---

# 54. Provider and Fields

A Provider MAY operate within or upon a Semantic Field.

The relationship MAY include:

```text
Field
    uses Provider

Provider
    transforms Field

Provider
    observes Field

Provider
    manifests Field
```

The exact semantics are defined by the relevant domain contract.

Provider implementation state MUST remain distinct from semantic Field state.

---

# 55. Provider and Hypergraphs

From the SCR perspective, Provider participation MUST ultimately be representable within the canonical SCR hypergraph.

Provider relationships MAY include:

```text
Provider
    satisfies
        Contract

Provider
    realizes
        Capability

Provider
    implements
        Operation

Provider
    requires
        Resource

Provider
    dependsOn
        Provider

Provider
    executesWith
        Runtime
```

No separate Provider-specific graph model is required merely to represent these relationships.

---

# 56. Provider Graph Boundary

The Provider graph is an integration graph.

It MUST NOT become a competing semantic graph.

The canonical SCR representation remains the SCR hypergraph.

---

# 57. Provider Contract Location

Normative Provider Contract architecture is defined at:

```text
docs/architecture/103_provider_contracts.md
```

Domain-specific semantic definitions remain under:

```text
lib/<domain>/
```

Provider-specific implementations belong under:

```text
providers/
```

This separation is normative.

---

# 58. Repository Ownership

The repository SHOULD therefore distinguish:

```text
lib/
    Semantic meaning

docs/architecture/
    Architectural rules

providers/
    Concrete integrations

runtime/
    Runtime systems and executable infrastructure
```

A Provider MUST NOT place its implementation-specific ontology into `lib/` merely because the implementation is important to SCR.

---

# 59. Provider Lifecycle

The expected Provider development lifecycle is:

```text
Identify capability
       ↓
Assess existing implementations
       ↓
Define / identify semantic contract
       ↓
Select Provider
       ↓
Define Provider integration
       ↓
Implement Adapter / Binding
       ↓
Conformance tests
       ↓
Validate
       ↓
Register with EGS
       ↓
Deploy
       ↓
Monitor
```

This lifecycle SHOULD be followed for new Provider integrations.

---

# 60. Provider Development Principle

Provider development follows:

> **Describe → Contract → Bind → Implement → Test → Validate → Register → Execute**

Implementation SHOULD NOT precede semantic contract definition where the capability is new to SCR.

---

# 61. Provider Architectural Invariants

The following invariants are normative.

### PR-001 — Semantic Independence

Providers MUST remain independent of SCR semantic definitions beyond the contracts they implement.

### PR-002 — Contract Declaration

Every conforming Provider MUST declare its supported Provider Contracts.

### PR-003 — Capability Declaration

Providers MUST declare the semantic capabilities they provide.

### PR-004 — Provider Identity

Provider identity MUST remain distinct from semantic capability identity.

### PR-005 — Provider Version

Provider version MUST remain distinct from contract version.

### PR-006 — Provider Isolation

Provider-specific ontology MUST NOT leak into normative semantic definitions.

### PR-007 — Contract Conformance

Provider compatibility MUST be determined by contract conformance, not API similarity.

### PR-008 — Substitution

Providers SHOULD be substitutable when the same contract permits substitution.

### PR-009 — Provenance

Provider provenance MUST be available where required for verification, validation, security, or reproducibility.

### PR-010 — Authority

Providers MUST respect SCR authority requirements.

### PR-011 — Resource Separation

Provider resource requirements MUST remain distinguishable from semantic meaning.

### PR-012 — EGS Resolution

Provider selection and manifestation MUST be performed through the SCR execution architecture.

### PR-013 — Canonical Independence

Canonical Providers MUST NOT become semantic authorities.

### PR-014 — Provider Graph

Provider relationships MUST be representable through the canonical SCR hypergraph.

### PR-015 — No Duplicate Semantic Graph

Providers MUST NOT introduce an alternative authoritative graph model.

### PR-016 — Contract-First

New Provider integrations SHOULD define their semantic contract before implementation.

### PR-017 — Conformance Testing

Providers MUST be tested against their normative contracts.

### PR-018 — Provider Replacement

SCR SHOULD preserve the ability to replace Providers without changing semantic consumers.

---

# 62. Canonical Provider Model

The canonical model is:

```text
Provider
│
├── Identity
├── Version
│
├── Capabilities
│
├── Contracts
│
├── Implementations
├── Bindings
│
├── Dependencies
├── Resources
├── Platforms
│
├── Fidelity
├── Determinism
│
├── Lifecycle
├── Security
├── Trust
│
├── Provenance
├── Limitations
│
└── Conformance
```

These properties describe the Provider as an implementation participant.

They do not define the semantic meaning of the capabilities it provides.

---

# 63. Canonical Provider Relationship

The complete SCR relationship is:

```text
Semantic Domain
       │
       ▼
Semantic Capability
       │
       ▼
Normative Provider Contract
       │
       ▼
Implementation Binding
       │
       ▼
Adapter
       │
       ▼
Provider
       │
       ▼
Execution Runtime
       │
       ▼
Semantic Machine Space
       │
       ▼
Physical / Computational Resources
```

The layers MAY be physically combined.

Their semantic responsibilities MUST remain distinguishable.

---

# 64. Final Architectural Rule

The Provider subsystem exists to allow SCR to use the world's computational infrastructure without making that infrastructure the foundation of SCR's semantic model.

Therefore:

> **SCR defines meaning.**

> **Provider Contracts define obligations.**

> **Implementations realize those obligations.**

> **Adapters translate between semantic and external representations.**

> **Providers supply concrete capabilities.**

> **Runtimes execute artifacts.**

> **EGS resolves and orchestrates execution.**

And the governing rule remains:

> **Do not build a kernel when a good kernel already exists. Build the semantic bridge that allows it to participate in SCR.**

> **When no suitable kernel exists, SCR may build it—but it remains behind the same semantic boundary and therefore remains replaceable.**

---

# 65. Definition Summary

A Provider is not part of SCR because SCR depends upon its implementation.

A Provider participates in SCR because it satisfies a semantic contract.

The Provider subsystem therefore exists to make the following transformation possible:

```text
                    SEMANTIC WORLD
                         │
                         ▼
                  SCR Capability
                         │
                         ▼
                Provider Contract
                         │
                         ▼
                Provider Binding
                         │
                         ▼
                  Concrete Provider
                         │
                         ▼
                 Concrete Execution
```

The semantic model remains authoritative throughout.

The Provider is replaceable.

The contract is stable.

The hypergraph remains canonical.
