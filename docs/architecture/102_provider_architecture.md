# SCR Provider Architecture

**Path:** `docs/architecture/102_provider_architecture.md`
**Version:** 0.0.1
**Status:** Normative Architecture Draft

---

## 1. Purpose

This document defines the architecture governing how SCR semantic capabilities are connected to concrete implementations, execution technologies, infrastructure, and external systems.

The provider architecture exists to preserve the fundamental SCR separation between:

> **semantic meaning, executable implementation, and infrastructure realization.**

SCR MUST NOT reproduce functionality already adequately provided by an established leading technology merely because SCR requires access to that functionality.

Instead:

> **SCR defines the semantic contract and provides the semantic bridge through which existing implementations participate in SCR.**

Where no suitable implementation exists, SCR MAY implement the missing capability, but the implementation MUST remain behind an appropriate semantic contract so that it can later be replaced.

---

# 2. Fundamental Principle

The provider architecture follows:

> **Do not build a kernel when a good kernel already exists. Build the semantic bridge that allows it to participate in SCR.**

Conversely:

> **When no suitable kernel exists, SCR may create the missing capability, but MUST expose it through a semantic contract so that it can later be replaced.**

The existence of a Provider does not make its ontology part of SCR.

SCR owns:

* semantic meaning;
* semantic contracts;
* invariants;
* composition;
* identity;
* capability requirements;
* relationships;
* execution semantics;
* implementation bindings;
* provider selection semantics.

Providers own:

* specialized implementation;
* optimization;
* hardware interaction;
* external protocols;
* concrete algorithms;
* concrete data structures;
* platform-specific execution.

---

# 3. Architectural Layers

The canonical provider architecture is:

```text
┌──────────────────────────────────────────────┐
│              SCR SEMANTIC LAYER              │
│                                              │
│  Entities  Fields  Services  Operations      │
│  State     Actions  Processes  Capabilities  │
│  Ports     Interfaces  Transformations       │
└───────────────────────┬──────────────────────┘
                        │
                 Semantic Contract
                        │
┌───────────────────────▼──────────────────────┐
│             IMPLEMENTATION LAYER             │
│                                              │
│  Implementation                              │
│  Implementation Binding                      │
│  Execution Contract                          │
│  Entry Point                                 │
│  Executable Artifact                         │
└───────────────────────┬──────────────────────┘
                        │
                 Adapter / Resolver
                        │
┌───────────────────────▼──────────────────────┐
│                 PROVIDER LAYER               │
│                                              │
│  Libraries  Engines  Frameworks  Services    │
│  Databases  GPU APIs  Physics  Rendering     │
└───────────────────────┬──────────────────────┘
                        │
                 Execution Runtime
                        │
┌───────────────────────▼──────────────────────┐
│             COMPUTATIONAL SYSTEM             │
│                                              │
│  CPU  GPU  WASM  OS  Network  Device  Cloud │
└──────────────────────────────────────────────┘
```

These layers MUST NOT be collapsed merely because an implementation happens to be packaged as a single artifact.

---

# 4. Semantic Layer

The semantic layer defines what a capability means.

For example:

```text
OrderService
    └── CreateOrder
```

defines application semantics.

It does not define:

* PostgreSQL;
* CouchDB;
* HTTP;
* Mojo;
* WASM;
* RabbitMQ;
* Kubernetes.

Similarly:

```text
Dynamics
```

does not define:

* Chrono;
* PhysX;
* Newton;
* Bullet.

The semantic layer describes the required capability and its invariants.

---

# 5. Implementation Layer

The implementation layer connects semantic entities to executable realizations.

The fundamental concepts are:

```text
Implementation
ImplementationBinding
ExecutableArtifact
ExecutionContract
EntryPoint
Invocation
ExecutionRequirement
ExecutionEffect
```

For example:

```text
CreateOrder
     │
     ▼
ImplementationBinding
     │
     ├── artifact → order_service.wasm
     ├── entryPoint → create_order
     └── contract → CreateOrderContract
```

The implementation layer is deliberately distinct from the Provider layer.

An implementation MAY use a Provider.

A Provider MAY itself be an executable implementation.

The relationship must not be assumed to be one-to-one.

---

# 6. Provider

> **Provider** — a concrete implementation or external capability source that satisfies a declared SCR semantic capability, Port, execution requirement, or implementation contract.

A Provider may be:

* a library;
* a framework;
* a runtime;
* an engine;
* a database;
* a service;
* a hardware interface;
* a compiler;
* an accelerator;
* a remote system;
* a local executable;
* a WASM runtime;
* a native runtime.

The term Provider therefore describes a **role in the SCR architecture**, not a particular packaging format.

---

# 7. Provider ≠ Service

An SCR Service and a Provider are fundamentally different.

A Service expresses application behaviour.

A Provider supplies an implementation.

For example:

```text
Application
    │
    └── TradingService
            │
            └── MarketDataPort
                    │
                    └── MarketDataAdapter
                            │
                            └── Luno Provider
```

The Service remains meaningful if Luno is replaced.

---

# 8. Provider ≠ Adapter

An Adapter translates between a semantic contract and an implementation.

A Provider supplies the implementation.

```text
Semantic Port
     │
     ▼
Adapter
     │
     ▼
Provider
```

For example:

```text
MarketDataPort
     │
     ▼
LunoAdapter
     │
     ▼
Luno API
```

The Luno API is the Provider-side system.

The Adapter translates it into SCR semantics.

---

# 9. Provider ≠ Executable Artifact

An Executable Artifact is a representation of executable implementation.

A Provider is a capability source.

For example:

```text
CreateOrder
    │
    ▼
ImplementationBinding
    │
    ▼
order.wasm
```

The WASM file is an Executable Artifact.

The WASM runtime that executes it may be a Provider.

Likewise:

```text
Mojo source
   ↓
MLIR
   ↓
native executable
```

contains implementation artifacts but does not itself define a Provider relationship.

---

# 10. Provider ≠ Execution Runtime

An Execution Runtime is responsible for executing an artifact.

Examples:

* WASM runtime;
* native OS process runtime;
* JVM;
* CLR;
* GPU runtime;
* container runtime.

A Provider MAY supply or depend upon a Runtime.

These concepts MUST remain separable.

---

# 11. Canonical Provider Relationship

The general model is:

```text
Semantic Capability
        │
        ▼
Semantic Contract
        │
        ▼
Implementation Binding
        │
        ▼
Executable / Adapter
        │
        ▼
Provider
        │
        ▼
Execution Runtime
        │
        ▼
Computational Resource
```

Not every implementation requires every layer to be separately represented.

The architecture describes semantic responsibilities, not mandatory packaging.

---

# 12. Canonical Does Not Mean Exclusive

A canonical Provider is the preferred or reference implementation for a capability.

Canonical MUST NOT mean:

* only implementation;
* mandatory implementation;
* permanent implementation;
* ontology authority.

Alternative Providers MAY exist where they satisfy the same semantic contract.

Example:

```text
Physics.Dynamics
│
├── Chrono Provider
├── Newton Provider
└── Alternative Provider
```

SCR semantics remain above all of them.

---

# 13. Provider Selection

EGS is responsible for resolving semantic requirements to suitable implementations and Providers.

Selection MAY consider:

* capability;
* semantic compatibility;
* version;
* fidelity;
* performance;
* platform;
* processor architecture;
* GPU availability;
* locality;
* execution Space;
* resource requirements;
* security;
* trust;
* license;
* lifecycle;
* determinism;
* numerical precision;
* provider health;
* implementation availability.

Selection MUST preserve semantic contracts and declared invariants.

---

# 14. Provider Capability Declaration

A Provider SHOULD expose machine-readable information describing:

* identity;
* version;
* capabilities;
* supported semantic contracts;
* supported artifact formats;
* platform requirements;
* architecture requirements;
* resource requirements;
* fidelity;
* precision;
* lifecycle;
* security characteristics;
* dependencies;
* limitations.

A Provider MUST NOT be considered semantically compatible solely because it exposes a similarly named API.

Compatibility is determined against the SCR semantic contract.

---

# 15. Provider Identity

Provider identity MUST be distinct from semantic identity.

A semantic capability may remain:

```text
scr.physics.dynamics
```

while implementations may be:

```text
provider.chrono
provider.newton
provider.physx
```

The Provider's identity does not replace the identity of the semantic capability.

---

# 16. Provider Provenance

SCR SHOULD maintain provenance describing:

* Provider identity;
* Provider version;
* implementation version;
* artifact identity;
* build identity;
* configuration;
* runtime;
* execution environment;
* relevant capabilities;
* semantic contract version.

This supports:

* reproducibility;
* auditing;
* debugging;
* verification;
* validation;
* replay;
* scientific provenance;
* deployment management.

---

# 17. Provider Substitution

Provider substitution MUST preserve semantic invariants.

It does NOT require:

* identical implementation;
* identical numerical output;
* identical performance;
* identical memory use;
* identical execution topology.

For example, two physics Providers may produce slightly different numerical trajectories while both satisfying the same semantic dynamics contract within defined fidelity bounds.

Therefore:

> **Semantic equivalence is not implementation equivalence.**

---

# 18. Provider Fidelity

Providers MAY declare fidelity characteristics.

Examples include:

* exact;
* deterministic;
* approximate;
* statistical;
* learned;
* heuristic;
* real-time;
* high-fidelity;
* reduced-order.

The semantic contract SHOULD define which fidelity properties are required.

Provider selection MAY use those requirements.

---

# 19. Provider Capability vs Implementation Capability

A Provider may implement several semantic capabilities.

For example:

```text
Chrono
├── Dynamics
├── Collision
├── Constraint
└── PhysicsSimulation
```

Conversely, one semantic capability may be composed from several Providers.

Therefore:

```text
Semantic Capability ↔ Provider
```

is not necessarily one-to-one.

---

# 20. Provider Composition

Providers MAY be composed.

For example:

```text
Simulation
│
├── Physics → Chrono
├── Spatial → H3
├── Geometry → CGAL
├── Volume → OpenVDB
├── Rendering → Vulkan
└── Messaging → AMQP
```

The Application or semantic domain sees the composed semantic capabilities.

EGS resolves the implementation topology.

---

# 21. Provider Isolation

Provider-specific concepts MUST remain behind semantic boundaries.

For example, SCR semantic Application code MUST NOT require:

```text
QWidget
GtkWidget
ReactComponent
SceneNode
PhysXActor
CouchDBDocument
RabbitMQChannel
```

as semantic types.

Instead:

```text
Application Component
     ↓
Semantic Contract
     ↓
Provider Adapter
     ↓
Provider Object
```

Provider concepts may exist in provider implementations and adapters.

---

# 22. Provider Leakage

Provider leakage occurs when a provider-specific concept becomes necessary to understand or construct a semantic SCR concept.

Examples of prohibited leakage include:

```text
SCR Service extends QWidget
SCR Entity contains PhysXActor
SCR Operation requires RabbitMQChannel
SCR State contains CouchDBDocument
SCR Application requires ReactComponent
```

Such designs are non-conforming.

---

# 23. Provider Promotion

A Provider concept MAY be promoted into SCR semantics only when it satisfies the SCR semantic promotion test.

The concept MUST demonstrate that:

1. it represents a genuine semantic concept;
2. the concept exists independently of the Provider;
3. the concept occurs across multiple implementations or domains;
4. the concept has independent invariants;
5. it materially improves semantic composition;
6. removing it would make SCR materially less expressive.

The Provider MUST NOT be promoted merely because its API is convenient.

---

# 24. Provider Availability Assessment

Before implementing a capability in SCR, assess:

### 24.1 Does a suitable capability already exist?

If no, SCR MAY implement the capability.

### 24.2 Is there a leading Provider?

If yes, prefer integration.

### 24.3 Is the Provider semantically compatible?

If yes, define or reuse the semantic bridge.

### 24.4 Does the Provider's ontology map cleanly?

If yes, integrate.

### 24.5 Does the Provider expose essential semantics that SCR cannot otherwise obtain?

If yes, evaluate the required semantic contract.

### 24.6 Would adopting the Provider force its ontology into SCR?

If yes, do not make it foundational without further analysis.

---

# 25. Provider Selection Rule

The default SCR strategy is:

> **Prefer integration over reimplementation when a mature, suitable, leading implementation exists.**

Exceptions include:

* unsuitable license;
* incompatible architecture;
* insufficient semantics;
* unacceptable performance;
* unacceptable security;
* missing capability;
* inability to expose required semantics;
* strategic requirement for a core SCR capability;
* absence of a suitable Provider.

Even when SCR implements a capability itself, it SHOULD preserve a semantic contract allowing future Provider substitution.

---

# 26. Application Providers

Application Providers implement application-level manifestations or execution mechanisms.

Examples include:

* MojoFlow;
* Qt;
* GTK;
* Web;
* CLI;
* OGRE;
* XR frameworks;
* AI/agent interfaces.

The Application semantic layer defines:

```text
Application
Module
Service
Controller
Port
Interface
Component
Event
Command
Action
```

The Provider implements or manifests them.

---

# 27. MojoFlow

MojoFlow MAY serve as an Application Provider.

Its potential responsibilities include:

* application lifecycle;
* application modules;
* service implementation;
* UI manifestation;
* event handling;
* application infrastructure.

However:

> **MojoFlow MUST NOT become the authority for SCR Application semantics.**

SCR MUST remain capable of expressing an Application without MojoFlow.

---

# 28. WASM Providers

WASM introduces an important distinction.

A WASM module is normally an Executable Artifact.

A WASM runtime is an Execution Provider.

Therefore:

```text
Semantic Operation
       │
       ▼
Implementation Binding
       │
       ▼
WASM Artifact
       │
       ▼
WASM Runtime Provider
       │
       ▼
Execution Space
```

WASM itself is not the semantic Application model.

---

# 29. Mojo Providers and Implementations

Mojo may appear at several layers.

### Implementation

A Service may be implemented in Mojo.

### Runtime

A Mojo execution environment may provide runtime functionality.

### Provider

A Mojo library may implement a semantic capability.

### Compiler

Mojo/MLIR tooling may transform implementation source into executable artifacts.

These roles MUST NOT be conflated.

---

# 30. MLIR Provider Boundary

MLIR is an important SCR implementation substrate.

SCR semantic dialects may describe:

* application structure;
* semantic operations;
* implementation bindings;
* execution contracts;
* provider requirements.

MLIR compilation infrastructure may lower those descriptions into executable implementations.

The existence of an MLIR representation MUST NOT cause SCR to define a complete programming language.

---

# 31. Execution Runtime Providers

Execution runtimes may include:

* native process runtimes;
* WASM runtimes;
* JVM;
* CLR;
* GPU runtimes;
* container runtimes;
* embedded runtimes;
* remote execution systems.

An execution runtime is selected according to the requirements of the Implementation Artifact and Execution Contract.

---

# 32. Providers and the Semantic Machine Model

The Semantic Machine Model defines computational Spaces containing executable Fields and Processes.

Providers execute within those Spaces.

For example:

```text
Application
    │
    ▼
Implementation
    │
    ▼
EGS
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

The Provider determines how its capability uses the available computational resources.

---

# 33. Provider Resource Requirements

Providers SHOULD declare resource requirements.

Examples:

```text
CPU cores
GPU memory
system memory
storage
network bandwidth
device access
shared memory
special instruction sets
```

EGS MAY use these requirements during implementation selection and placement.

---

# 34. Provider Lifecycle

Providers SHOULD expose lifecycle information sufficient for EGS to determine:

* availability;
* initialization;
* readiness;
* health;
* suspension;
* degradation;
* failure;
* shutdown.

Provider lifecycle MUST integrate with the canonical SCR lifecycle model.

---

# 35. Provider Failure

Provider failure MUST be distinguishable from semantic failure.

For example:

```text
Provider unavailable
```

is different from:

```text
Operation rejected by semantic policy
```

and from:

```text
Operation executed and produced semantic failure
```

These distinctions are important for recovery and observability.

---

# 36. Provider Observability

Providers SHOULD expose semantic runtime information sufficient for:

* health monitoring;
* diagnostics;
* resource usage;
* performance measurement;
* failure reporting;
* provenance;
* execution tracing.

Observability information MUST NOT require provider-specific concepts to leak into the semantic Application ontology.

---

# 37. Provider Security

Providers MAY require:

* credentials;
* capabilities;
* permissions;
* isolated execution;
* trusted execution;
* signed artifacts;
* verified provenance.

Security requirements MUST be expressed through SCR authority and capability semantics where possible.

A Provider MUST NOT bypass application authority merely because it is trusted infrastructure.

---

# 38. Provider Trust

EGS MAY assign or evaluate Provider trust based upon:

* provenance;
* identity;
* signatures;
* deployment policy;
* certification;
* runtime isolation;
* execution history;
* administrator policy.

Trust is a property of an implementation/provider relationship.

It does not automatically become semantic capability.

---

# 39. Provider Versioning

Provider version MUST remain distinct from semantic contract version.

For example:

```text
Semantic Contract:
    scr.physics.dynamics v1

Provider:
    Chrono 9.x
```

A new Provider version MAY satisfy the same semantic contract.

Conversely, a semantic contract revision MAY require changes to the Provider implementation.

---

# 40. Provider Conformance

A Provider conforms to SCR when:

1. it declares the semantic capabilities it implements;
2. its implementation satisfies the relevant semantic contracts;
3. required invariants are preserved;
4. required inputs and outputs are supported;
5. required lifecycle semantics are supported;
6. required authority semantics are respected;
7. implementation provenance is available where required;
8. Provider-specific semantics remain isolated.

Conformance is evaluated against the semantic contract, not API similarity.

---

# 41. Semantic Equivalence

Two Providers are semantically equivalent when they satisfy the same semantic contract within its declared invariants and fidelity requirements.

Semantic equivalence does not imply:

* identical algorithms;
* identical data structures;
* identical numerical output;
* identical performance;
* identical artifact format.

This allows Providers to evolve independently.

---

# 42. Provider Substitution Test

A Provider architecture is valid if the following substitution is possible:

```text
Semantic Capability
        │
        ├── Provider A
        │
        └── Provider B
```

without requiring the semantic Application to understand the internal ontology of either Provider.

If Provider B requires modification of semantic concepts solely because its internal model differs, the semantic contract is insufficient or the abstraction boundary is incorrect.

---

# 43. Provider Test

Every proposed Provider integration SHOULD answer:

### Semantic

* What SCR semantic capability does it provide?
* What semantic contract does it satisfy?
* What invariants does it preserve?

### Architectural

* Is it a Provider, Adapter, Runtime, Artifact, or some combination?
* Where does its boundary lie?
* Does it introduce a new semantic concept?

### Technical

* What resources does it require?
* What platforms does it support?
* What execution model does it use?

### Substitution

* Can another implementation satisfy the same contract?

### Leakage

* Does its ontology leak into SCR semantics?

### Provenance

* Can its implementation and version be identified?

---

# 44. Reference Provider Principle

Where a Provider is selected as canonical, the designation means:

> **reference implementation for SCR integration and conformance**

not:

> **permanent architectural dependency.**

SCR MUST retain semantic independence from the canonical Provider.

---

# 45. Providers and Core SCR Capabilities

Some functionality is sufficiently fundamental that SCR may implement it directly.

Examples may include:

* semantic hypergraph infrastructure;
* SCR identity;
* semantic relation machinery;
* semantic execution contracts;
* EGS;
* canonical messaging integration;
* core semantic state machinery.

Even in these cases, the implementation SHOULD be exposed through semantic contracts where substitution is meaningful.

---

# 46. When SCR Should Implement

SCR SHOULD implement a capability directly when:

1. no suitable Provider exists;
2. existing Providers cannot express the required semantics;
3. the capability is intrinsically part of SCR's semantic/runtime role;
4. existing implementations introduce unacceptable architectural coupling;
5. the capability is required to establish SCR's foundational invariants.

SCR SHOULD NOT implement a capability merely because doing so is convenient.

---

# 47. Provider Architecture and Heterogeneous Domains

The provider model allows SCR to combine heterogeneous computational systems.

For example:

```text
Application
│
├── Physics
│   └── Chrono
│
├── Spatial
│   └── H3
│
├── Geometry
│   └── CGAL
│
├── Volume
│   └── OpenVDB
│
├── Rendering
│   └── Vulkan
│
├── Messaging
│   └── AMQP
│
├── Neural
│   └── CUDA / model runtime
│
└── Application
    └── MojoFlow / Web / CLI / OGRE
```

SCR composes their semantic capabilities without requiring a common implementation ontology.

---

# 48. Provider Architecture and Application Architecture

The Application domain uses the provider architecture as follows:

```text
Application
│
├── Module
│   └── Service
│       └── Operation
│           └── ImplementationBinding
│
├── Controller
│   └── Port
│       └── Adapter
│           └── Provider
│
└── Interface
    └── Manifestation Provider
```

An Application Service MAY therefore be:

* implemented locally;
* implemented in Mojo;
* compiled to WASM;
* implemented natively;
* provided remotely;
* backed by another SCR Service;
* composed from several Providers.

---

# 49. The Semantic Gateway Principle

SCR acts as a **semantic gateway over computational kernels and application infrastructure**.

The gateway provides:

* semantic normalization;
* identity;
* contracts;
* composition;
* capability discovery;
* dependency resolution;
* implementation binding;
* execution orchestration;
* provenance;
* verification;
* provider substitution.

The underlying Providers provide specialized computation.

Therefore:

> **SCR's primary value is composition, not duplication.**

---

# 50. Final Architectural Rule

The SCR Provider Architecture is governed by the following rule:

> **SCR defines semantic meaning and contracts. Implementation Bindings connect that meaning to executable artifacts. Adapters translate between semantic contracts and external systems. Providers supply specialized implementations. Execution Runtimes execute artifacts. EGS resolves and orchestrates the resulting executable graph.**

Or, more compactly:

```text id="w3v7xj"
SEMANTICS
    ↓
CONTRACT
    ↓
IMPLEMENTATION BINDING
    ↓
ADAPTER / RESOLVER
    ↓
PROVIDER
    ↓
RUNTIME
    ↓
COMPUTATION
```

And the governing principle remains:

> **Do not build a kernel when a good kernel already exists. Build the semantic bridge that allows it to participate in SCR.**

> **When no suitable kernel exists, SCR may build it—but it must remain behind a semantic contract so that the kernel can eventually be replaced.**
