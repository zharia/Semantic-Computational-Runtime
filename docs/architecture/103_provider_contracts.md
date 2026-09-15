# SCR Normative Provider Contracts

**Path:** `docs/architecture/103_provider_contracts.md`
**Version:** 0.0.1
**Status:** Normative Specification

---

## 1. Purpose

This specification defines the normative contract model governing Providers within the Semantic Computational Runtime (SCR).

It establishes the requirements by which a concrete Provider may claim to implement an SCR semantic capability, Port, Operation, execution requirement, or other semantic contract.

The purpose of the Provider Contract is to establish a stable semantic boundary between:

```text
SCR Semantic Meaning
        │
        ▼
Normative Provider Contract
        │
        ▼
Concrete Provider
```

The Provider Contract defines **what a Provider MUST mean and guarantee**.

It does not prescribe:

* implementation language;
* algorithm;
* internal data structures;
* executable format;
* runtime;
* hardware;
* deployment topology;
* provider-specific ontology.

---

# 2. Relationship to Provider Architecture

This specification is subordinate to and implements the architecture defined by:

```text
docs/architecture/102_provider_architecture.md
```

The Provider Architecture defines:

* Provider;
* Adapter;
* Implementation;
* Implementation Binding;
* Executable Artifact;
* Execution Runtime;
* Provider selection;
* Provider substitution;
* Provider isolation.

This specification defines the normative contract through which those architectural relationships are enforced.

The fundamental relationship is:

```text
Semantic Capability
        │
        ▼
Provider Contract
        │
        ▼
Implementation Binding
        │
        ▼
Provider
        │
        ▼
Execution Runtime
```

---

# 3. Fundamental Definition

A **Normative Provider Contract** is a machine-interpretable semantic specification defining the obligations, guarantees, admissible inputs, outputs, state transitions, effects, failures, resource requirements, and conformance requirements applicable to a Provider.

Formally:

```text
ProviderContract =
    Identity
  + Capability
  + Interface
  + Preconditions
  + Postconditions
  + State
  + Effects
  + FailureSemantics
  + ResourceRequirements
  + Fidelity
  + ExecutionSemantics
  + Lifecycle
  + Authority
  + Provenance
  + Conformance
```

A Provider claiming conformance MUST satisfy the applicable normative obligations.

---

# 4. Contract Authority

The Provider Contract is the authoritative semantic boundary between SCR and the Provider.

The Provider implementation MUST NOT redefine the meaning of the semantic capability it claims to provide.

Where a Provider's internal model differs from SCR's semantic model:

```text
SCR semantics
    │
    ▼
Contract
    │
    ▼
Provider translation
```

The Provider MUST adapt its implementation to the contract rather than requiring SCR semantics to adopt the Provider's internal ontology.

---

# 5. Contract Independence

A Provider Contract MUST be independent of the Provider implementation.

A contract MUST NOT require:

* a particular programming language;
* a particular library;
* a particular framework;
* a particular database;
* a particular operating system;
* a particular hardware architecture;
* a particular executable format.

For example:

```text
Physics.Dynamics
```

MAY be implemented by:

```text
Chrono
PhysX
MuJoCo
custom implementation
```

without changing the semantic contract.

---

# 6. Contract Identity

Every normative Provider Contract MUST have an SCR identity.

The identity MUST be distinct from:

* Provider identity;
* Provider version;
* executable artifact identity;
* runtime identity.

Example:

```text
Contract:
    scr.physics.dynamics

Version:
    0.0.1

Providers:
    chrono
    physx
    mujoco
```

The Provider MUST identify the contract versions against which it claims conformance.

---

# 7. Contract Version

Provider Contracts MUST be versioned independently of Providers.

A Provider MAY implement multiple contract versions.

A Provider MAY implement a newer Provider version while continuing to satisfy an older semantic contract.

Example:

```text
Contract:
    scr.physics.dynamics v1

Provider:
    Chrono v9
```

Provider version changes MUST NOT automatically imply semantic contract changes.

---

# 8. Contract Scope

A Provider Contract MUST identify the semantic scope it governs.

Scope MAY include:

* capability;
* operation;
* service;
* port;
* interface;
* execution requirement;
* data transformation;
* runtime capability;
* infrastructure capability.

A contract MUST NOT define unrelated semantic responsibilities.

---

# 9. Capability Contract

The Provider Contract MUST identify the semantic capability being provided.

```text
Provider
    └── satisfies
            └── Capability
```

The capability definition MUST describe semantic meaning rather than implementation mechanics.

The contract SHOULD define:

* capability identity;
* capability purpose;
* semantic inputs;
* semantic outputs;
* supported operations;
* invariants;
* constraints;
* required state;
* produced state.

---

# 10. Interface Contract

The Provider Contract MUST define the semantic interface through which the capability is accessed.

An interface MAY contain:

* Operations;
* Ports;
* Events;
* Commands;
* Observations;
* state transitions.

The interface MUST describe semantic relationships rather than programming-language syntax.

For example:

```text
Dynamics
├── initialize
├── step
├── observe
├── applyAction
└── reset
```

does not imply a particular class, function, RPC, or ABI.

---

# 11. Operation Contract

Each normative operation MUST define, where applicable:

```text
Operation
├── Identity
├── Inputs
├── Outputs
├── Preconditions
├── Postconditions
├── State Effects
├── Events
├── Failures
└── Resource Requirements
```

An operation MUST have a deterministic semantic interpretation even if its implementation is nondeterministic.

---

# 12. Input Contract

The Provider Contract MUST define the semantic requirements for each input.

These MAY include:

* identity;
* semantic type;
* cardinality;
* value domain;
* units;
* precision;
* dimensionality;
* topology;
* spatial reference;
* temporal reference;
* permitted range;
* required relationships;
* authority requirements.

Provider-specific representations MUST NOT become normative input semantics.

For example:

```text
Vector3<float>
```

may be an implementation representation.

The contract instead defines:

```text
Position
    dimensionality = 3
    referenceFrame = World
    unit = metre
```

where those properties are semantically required.

---

# 13. Output Contract

The Provider Contract MUST define the semantic guarantees associated with outputs.

These MAY include:

* semantic identity;
* type;
* value;
* units;
* precision;
* dimensionality;
* temporal position;
* spatial reference;
* completeness;
* provenance;
* uncertainty;
* validity.

Additional provider-specific outputs MAY be exposed but MUST NOT alter the semantics of normative outputs.

---

# 14. Preconditions

A Provider MUST define all conditions that must hold before an operation may execute successfully.

Examples:

```text
Simulation must be initialized.
Target Entity must exist.
Required capability must be authorized.
Input state must satisfy constraint X.
```

A Provider MUST NOT silently reinterpret a violated semantic precondition as successful execution.

---

# 15. Postconditions

A successful operation MUST satisfy its declared postconditions.

Postconditions MAY describe:

* resulting state;
* created entities;
* removed entities;
* modified properties;
* generated events;
* produced observations;
* persisted state;
* execution effects.

Postconditions are semantic guarantees and MUST NOT depend upon the Provider's internal representation.

---

# 16. State Contract

Where a Provider operates on mutable state, the contract MUST define the relevant state semantics.

The contract SHOULD distinguish:

```text
Required State
Mutable State
Immutable State
Derived State
Persistent State
Transient State
```

An operation MAY be represented as:

```text
Stateₙ
   +
Input
   +
Context
   ↓
Operation
   ↓
Stateₙ₊₁
   +
Output
   +
Effects
```

The Provider MUST preserve all normative state invariants.

---

# 17. State Transition Contract

Where state transitions are normative, the contract MUST define:

* source state;
* transition trigger;
* permitted transition;
* resulting state;
* transition effects;
* invalid transitions.

A Provider MUST NOT introduce semantic state transitions that contradict the contract.

---

# 18. Effect Contract

The Provider Contract MUST identify externally meaningful effects.

Effects MAY include:

* state mutation;
* entity creation;
* entity deletion;
* message emission;
* resource allocation;
* persistence;
* external interaction;
* process creation;
* temporal advancement.

Effects MUST be distinguished from implementation-internal side effects.

---

# 19. Event Contract

Where an operation produces an Event, the contract MUST define its semantic meaning.

An Event MAY contain:

```text
Identity
Type
Source
Target
Temporal Position
Payload
Context
Causation
Correlation
```

Provider-specific callback mechanisms MUST NOT be normative event semantics.

For example:

```text
Qt signal
RabbitMQ callback
C++ callback
Mojo closure
```

are implementation mechanisms.

The semantic Event exists independently of those mechanisms.

---

# 20. Observation Contract

Where a Provider produces an Observation, the contract MUST distinguish the observation from the implementation mechanism that generated it.

For example:

```text
Camera Provider
     ↓
Observation
```

The contract defines the semantic Observation.

It does not require:

```text
OpenCV
Vulkan
CUDA
ROS
```

or another particular implementation.

---

# 21. Action Contract

Where a Provider accepts an Action, the contract MUST define:

* action identity;
* target;
* parameters;
* authority;
* preconditions;
* expected effects;
* failure semantics.

An Action MUST NOT be conflated with the Provider's implementation function.

---

# 22. Failure Contract

Provider failure MUST have defined semantic meaning.

A normative contract SHOULD distinguish at least:

```text
InvalidInput
UnsupportedCapability
UnavailableResource
ExecutionFailure
ConstraintViolation
Timeout
AuthorizationFailure
ProviderUnavailable
ContractViolation
```

The exact taxonomy MAY be extended by domain contracts.

However, implementations MUST NOT collapse semantically distinct failures merely because their underlying runtime exposes a single exception type.

---

# 23. Failure vs Semantic Rejection

The contract MUST distinguish:

```text
Provider failed to execute
```

from:

```text
Provider executed and rejected the requested operation
```

and:

```text
Operation executed successfully but produced a domain-level failure state.
```

These distinctions MUST remain observable where required by the semantic contract.

---

# 24. Resource Contract

The Provider Contract MAY define resource requirements.

These MAY include:

* CPU;
* memory;
* GPU;
* accelerator;
* storage;
* network;
* bandwidth;
* device access;
* instruction-set requirements;
* shared-memory requirements;
* locality;
* concurrency.

Resource requirements describe execution requirements.

They MUST NOT become part of the semantic meaning unless the resource itself is semantically relevant.

---

# 25. Fidelity Contract

Providers MAY differ in fidelity.

The Provider Contract MUST identify fidelity requirements where fidelity affects semantic validity.

Possible fidelity classifications include:

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

A Provider MUST NOT claim a fidelity level it cannot satisfy.

---

# 26. Numerical Contract

Where numerical computation is semantically relevant, the contract SHOULD specify:

* precision;
* permitted error;
* tolerance;
* numerical stability requirements;
* convergence requirements;
* rounding requirements;
* deterministic requirements.

Numerical equivalence MUST NOT be assumed merely because two Providers implement the same capability.

---

# 27. Determinism Contract

The contract MUST explicitly declare determinism where relevant.

Possible declarations include:

```text
deterministic
conditionally_deterministic
nondeterministic
```

Conditional determinism MAY depend upon:

* seed;
* hardware;
* provider version;
* execution mode;
* concurrency;
* precision;
* configuration.

---

# 28. Temporal Contract

Providers operating over time MUST define temporal semantics where relevant.

These MAY include:

* continuous time;
* discrete time;
* timestep;
* temporal ordering;
* causality;
* clock source;
* temporal resolution;
* synchronization;
* monotonicity.

A Provider MUST NOT silently substitute a different temporal model.

---

# 29. Spatial Contract

Providers operating in spatial domains MUST define relevant spatial semantics.

These MAY include:

* dimensionality;
* coordinate system;
* reference frame;
* units;
* topology;
* boundary conditions;
* spatial resolution;
* locality.

Provider-specific spatial representations MUST remain implementation details unless explicitly promoted into SCR semantics.

---

# 30. Concurrency Contract

Where concurrency affects semantic behaviour, the Provider Contract MUST define the relevant guarantees.

These MAY include:

```text
single-threaded
thread-safe
reentrant
parallel
actor-isolated
distributed
```

Ordering MAY be:

```text
ordered
partially_ordered
unordered
```

Concurrency semantics MUST NOT be inferred from implementation technology.

---

# 31. Lifecycle Contract

A Provider Contract MUST define lifecycle requirements where lifecycle affects capability availability.

Possible states include:

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

A contract MAY define only the subset applicable to its Provider.

Permitted lifecycle transitions MUST be explicit.

---

# 32. Authority Contract

Where a Provider operation requires authorization, the contract MUST define the required SCR capability or authority.

For example:

```text
Operation:
    Storage.Write

Requires:
    Capability(Storage.Write)
```

Provider implementations MUST NOT infer authorization from:

```text
visible
enabled
reachable
authenticated
```

unless explicitly defined by the relevant authority model.

---

# 33. Security Contract

The Provider Contract MAY define security requirements including:

* authenticated identity;
* authorization;
* isolation;
* encryption;
* signed artifacts;
* trusted execution;
* provenance;
* secret handling;
* capability restrictions.

Security requirements MUST be expressed in terms compatible with SCR security semantics.

---

# 34. Provenance Contract

Where provenance matters, the Provider MUST expose sufficient information to establish:

```text
Semantic Contract
        ↓
Provider
        ↓
Provider Version
        ↓
Implementation
        ↓
Artifact
        ↓
Runtime
        ↓
Execution Context
```

Provenance MAY be required for:

* reproducibility;
* audit;
* scientific validation;
* replay;
* debugging;
* compliance;
* security.

---

# 35. Implementation Binding

A Provider Contract MUST remain distinct from an Implementation Binding.

```text
Provider Contract
       │
       ▼
Implementation Binding
       │
       ├── Artifact
       ├── EntryPoint
       └── Execution Contract
```

The contract defines semantic obligations.

The binding defines how a particular implementation satisfies them.

---

# 36. Adapter Contract

Where an Adapter is required, the Adapter MUST preserve the semantics of the Provider Contract.

```text
SCR Contract
     │
     ▼
Adapter
     │
     ▼
External Provider
```

The Adapter MUST NOT silently alter:

* identity;
* state;
* ordering;
* units;
* authority;
* failure semantics;
* temporal semantics;
* spatial semantics.

Any transformation MUST be explicitly defined.

---

# 37. Provider Composition

Multiple Providers MAY jointly satisfy a Provider Contract.

For example:

```text
Simulation
├── Physics Provider
├── Spatial Provider
├── Geometry Provider
└── Numerical Provider
```

Composition MUST preserve the normative contract at the boundary.

Internal composition is not required to be visible to the semantic consumer.

---

# 38. Provider Substitution

A Provider MAY be substituted when the replacement:

1. satisfies the same contract;
2. supports the required contract version;
3. satisfies required capability constraints;
4. satisfies fidelity requirements;
5. satisfies resource requirements;
6. satisfies authority requirements;
7. preserves applicable semantic invariants.

Provider substitution MUST NOT require changes to semantic consumers solely because implementation details differ.

---

# 39. Semantic Equivalence

Two Providers are semantically equivalent when both satisfy the same normative contract and its applicable invariants.

Semantic equivalence does NOT require:

* identical algorithms;
* identical internal state representation;
* identical numerical results;
* identical performance;
* identical artifact format;
* identical resource consumption.

Where numerical or behavioural tolerance matters, that tolerance MUST be part of the contract.

---

# 40. Provider Capability Declaration

A conforming Provider SHOULD expose machine-readable metadata containing:

```text
providerIdentity
providerVersion
contractIdentity
contractVersion
capabilities
operations
fidelity
determinism
resourceRequirements
platformRequirements
securityRequirements
lifecycle
dependencies
limitations
provenance
```

Metadata is declarative.

It does not replace behavioural conformance testing.

---

# 41. Conformance

A Provider conforms to a Provider Contract only if:

1. it declares the contract;
2. it implements all mandatory operations;
3. it satisfies mandatory preconditions and postconditions;
4. it preserves required state invariants;
5. it implements required failure semantics;
6. it satisfies required authority constraints;
7. it satisfies applicable fidelity requirements;
8. it satisfies lifecycle requirements;
9. it satisfies required resource constraints;
10. it passes the contract conformance tests.

A Provider MUST NOT claim conformance solely because it exposes an apparently compatible API.

---

# 42. Conformance Levels

A Provider MAY declare:

```text
Full
Partial
Experimental
Reference
```

Where:

### Full

All mandatory contract requirements are satisfied.

### Partial

Some optional or explicitly declared capability subsets are unsupported.

### Experimental

Implementation is incomplete, unstable, or insufficiently validated.

### Reference

Provider is designated as a reference implementation for the contract.

`Reference` does not imply `Full` unless explicitly declared.

---

# 43. Contract Conformance Testing

Every normative Provider Contract SHOULD define a corresponding conformance test suite.

The test suite SHOULD validate:

```text
Identity
Interface
Inputs
Outputs
Preconditions
Postconditions
State
Effects
Events
Failures
Lifecycle
Authority
Fidelity
Determinism
Resource behaviour
Provenance
```

Tests SHOULD operate at the semantic boundary rather than testing Provider internals.

---

# 44. Provider Substitution Test

A Provider Contract SHOULD include a substitution test.

Given:

```text
Capability
    ├── Provider A
    └── Provider B
```

the same semantic consumer SHOULD be able to operate against either Provider without requiring provider-specific semantic changes.

If this is impossible, one of the following is likely true:

1. the contract is incomplete;
2. the abstraction boundary is incorrect;
3. Provider-specific semantics have leaked;
4. the Providers do not actually implement the same capability.

---

# 45. Contract Violation

A Provider MUST be considered non-conforming when it violates a mandatory contract obligation.

Contract violation MAY include:

* invalid output;
* missing required state transition;
* incorrect effect;
* unauthorized effect;
* incorrect temporal semantics;
* incorrect spatial semantics;
* incorrect failure semantics;
* false capability declaration;
* unannounced fidelity reduction;
* violation of required determinism;
* violation of lifecycle guarantees.

EGS MUST be able to distinguish contract violation from ordinary Provider failure where required.

---

# 46. Provider Leakage Rule

Provider-specific concepts MUST NOT appear in normative semantic contracts unless explicitly promoted through the SCR semantic promotion process.

The following are examples of implementation concepts:

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

A semantic contract MUST instead express their semantic role.

For example:

```text
PhysicalEntity
UIComponent
MessageChannel
Document
Image
ExecutionStream
```

where such concepts are actually justified by SCR semantics.

---

# 47. Semantic Promotion Test

A Provider concept may be promoted into SCR semantics only if:

1. it has meaning independent of the Provider;
2. it exists across multiple implementations or domains;
3. it has stable semantic invariants;
4. it improves composition;
5. it can be specified without reference to the originating Provider;
6. its inclusion is justified by SCR's broader semantic model.

Provider convenience is not sufficient justification.

---

# 48. Contract Discovery

EGS SHOULD be able to discover Provider Contracts without loading provider-specific implementation semantics.

Discovery SHOULD permit EGS to determine:

```text
What capability?
Which contract?
Which version?
What requirements?
What fidelity?
What resources?
What platform?
What security?
What lifecycle?
```

before selecting or activating a Provider.

---

# 49. Contract Resolution

Provider resolution follows:

```text
Semantic Requirement
        │
        ▼
Contract
        │
        ▼
Candidate Providers
        │
        ├── capability
        ├── version
        ├── fidelity
        ├── resources
        ├── platform
        ├── authority
        ├── trust
        └── availability
        │
        ▼
Selected Provider
        │
        ▼
Implementation Binding
        │
        ▼
Execution
```

The resolution process MUST operate on semantic requirements rather than provider-specific API names.

---

# 50. Contract Inheritance and Composition

Provider Contracts MAY compose other contracts.

For example:

```text
SimulationContract
    ├── DynamicsContract
    ├── SpatialContract
    ├── TemporalContract
    └── ObservationContract
```

Composition MUST preserve the invariants of all constituent contracts.

A derived contract MUST NOT weaken mandatory requirements of its parent contracts unless the parent explicitly permits such specialization.

---

# 51. Contract Specialization

A Provider Contract MAY specialize a more general contract.

For example:

```text
Storage
   ↓
PersistentStorage
   ↓
TransactionalStorage
```

Specialization MUST preserve the semantics of the more general contract.

A specialized Provider MAY provide stronger guarantees.

It MUST NOT silently provide weaker guarantees while claiming full conformance to the parent contract.

---

# 52. Contract Extensions

Optional extensions MAY be declared.

Extensions MUST be distinguishable from mandatory contract requirements.

Example:

```text
scr.rendering.v1
    required:
        Render

    optional:
        RayTracing
        HDR
        TemporalUpscaling
```

A Provider supporting an extension MUST declare it explicitly.

Semantic consumers MUST NOT assume optional extensions exist unless they require them.

---

# 53. Contract and EGS

EGS is responsible for using Provider Contracts during executable graph manifestation.

EGS MAY:

* discover contracts;
* evaluate requirements;
* select Providers;
* bind implementations;
* place execution;
* monitor lifecycle;
* perform substitution;
* reject non-conforming Providers.

EGS MUST NOT redefine the semantics of the contract.

EGS is the resolver and orchestrator, not the semantic authority.

---

# 54. Contract and Semantic Machine Model

Provider Contracts interact with the Semantic Machine Model through execution requirements.

For example:

```text
Provider Contract
    │
    └── requires:
            GPU
            memory ≥ X
            architecture = Y
```

EGS resolves these requirements against available Semantic Machine Spaces.

The Provider Contract therefore describes what computational environment is required without making the environment itself part of the Provider's semantic capability.

---

# 55. Contract and WASM

A WASM module is normally an Executable Artifact.

A WASM runtime is an Execution Provider.

The Provider Contract therefore sits above both:

```text
Semantic Capability
        │
        ▼
Provider Contract
        │
        ▼
Implementation Binding
        │
        ▼
WASM Artifact
        │
        ▼
WASM Runtime Provider
```

The contract MUST NOT depend on WASM unless WASM itself is semantically relevant to the capability.

---

# 56. Contract and Mojo

Mojo MAY implement a Provider or a Provider-backed executable artifact.

The Provider Contract MUST remain language-independent.

For example:

```text
Semantic Operation
        │
        ▼
Provider Contract
        │
        ▼
Mojo Implementation
```

is valid.

But:

```text
Provider Contract requires Mojo class X
```

is not a language-independent semantic contract and is therefore non-conforming unless the contract itself explicitly concerns Mojo infrastructure.

---

# 57. Contract and MLIR

MLIR MAY represent:

* semantic contract declarations;
* capability requirements;
* implementation bindings;
* execution contracts;
* Provider metadata.

The Provider Contract is nevertheless a semantic specification.

An MLIR representation is an implementation representation of that specification.

MLIR MUST NOT become the semantic authority merely because it is used to encode the contract.

---

# 58. Application Provider Contracts

Application Providers MUST use the same Provider Contract model.

For example:

```text
Application
    │
    ▼
Application Provider Contract
    │
    ├── MojoFlow
    ├── Web
    ├── CLI
    ├── OGRE
    └── Agent Interface
```

The Application semantic model therefore remains independent of its manifestation mechanism.

---

# 59. Domain Provider Contracts

Individual SCR domains SHOULD define their concrete Provider Contracts under their respective semantic domains.

Examples:

```text
Physics
    └── Provider Contract

Rendering
    └── Provider Contract

Neural
    └── Provider Contract

Storage
    └── Provider Contract

Messaging
    └── Provider Contract
```

These contracts MUST conform to this architectural specification.

The domain contract defines domain semantics.

This specification defines the common Provider Contract machinery.

---

# 60. Contract Location

The architectural Provider Contract specification is located at:

```text
docs/architecture/103_provider_contracts.md
```

Domain-specific contracts belong with the domain that owns their semantics.

Provider implementation documentation belongs with the Provider integration or implementation.

This prevents the architecture directory from becoming a substitute for the semantic library.

---

# 61. Documentation Relationship

The intended hierarchy is:

```text
docs/architecture/
│
├── 102_provider_architecture.md
│       │
│       └── Defines Provider architecture
│
└── 103_provider_contracts.md
        │
        └── Defines normative Provider Contract machinery
```

Then:

```text
lib/<domain>/
    └── semantic domain definitions
            │
            ▼
Provider Contract
            │
            ▼
Provider integration
            │
            ▼
Implementation
```

The semantic library defines **what the domain means**.

The Provider Contract defines **what an implementation must guarantee**.

The Provider integration defines **how a particular implementation participates**.

---

# 62. Architectural Invariants

The following invariants are normative.

### PC-001 — Contract Identity

Every normative Provider Contract MUST have an identity.

### PC-002 — Contract Version

Every normative Provider Contract MUST have a version.

### PC-003 — Semantic Independence

Provider Contracts MUST be independent of Provider implementation technology.

### PC-004 — Provider Declaration

A conforming Provider MUST declare the contracts it claims to satisfy.

### PC-005 — Behavioural Conformance

Conformance MUST include behaviour, not merely interface compatibility.

### PC-006 — Input Validity

Providers MUST enforce normative input constraints.

### PC-007 — Output Validity

Providers MUST satisfy normative output guarantees.

### PC-008 — State Integrity

Providers MUST preserve normative state invariants.

### PC-009 — Effect Integrity

Providers MUST preserve normative semantic effects.

### PC-010 — Failure Semantics

Providers MUST preserve normative failure semantics.

### PC-011 — Authority

Providers MUST respect normative authority requirements.

### PC-012 — Fidelity

Providers MUST NOT falsely claim required fidelity.

### PC-013 — Provider Isolation

Provider-specific ontology MUST NOT leak into normative semantic contracts.

### PC-014 — Substitution

Conforming Providers SHOULD be substitutable where the contract permits substitution.

### PC-015 — Provenance

Providers MUST expose required provenance.

### PC-016 — Lifecycle

Providers MUST satisfy required lifecycle semantics.

### PC-017 — Resource Declaration

Required execution resources MUST be declared.

### PC-018 — Contract Testing

Normative Provider Contracts MUST be testable.

### PC-019 — EGS Resolution

Provider selection MUST operate through semantic requirements and contracts.

### PC-020 — Semantic Authority

Providers MUST NOT become the semantic authority for SCR.

---

# 63. Canonical Provider Contract Model

The canonical abstract model is:

```text
ProviderContract
│
├── Identity
│   ├── SID
│   └── Version
│
├── Capability
│
├── Interface
│   └── Operations
│
├── Inputs
├── Outputs
│
├── Preconditions
├── Postconditions
│
├── State
│   └── StateTransitions
│
├── Effects
├── Events
├── Observations
├── Actions
│
├── FailureSemantics
│
├── ResourceRequirements
├── Fidelity
├── NumericalSemantics
├── Determinism
├── TemporalSemantics
├── SpatialSemantics
├── Concurrency
│
├── Lifecycle
├── Authority
├── Security
│
├── Provenance
├── Dependencies
├── Limitations
│
└── Conformance
```

Not every Provider Contract requires every element.

Mandatory elements are determined by the capability being specified.

---

# 64. Canonical Execution Relationship

The complete relationship is:

```text
Semantic Meaning
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
       ├───────────────┐
       ▼               ▼
Executable Artifact   Adapter
       │               │
       ▼               ▼
Execution Runtime   Provider
       │               │
       └───────┬───────┘
               ▼
       Semantic Execution
```

The Provider Contract is therefore the point at which **semantic guarantees become enforceable against concrete computation**.

---

# 65. Architectural Principle

The Provider Contract model exists to enforce the following SCR principle:

> **Do not build a kernel when a good kernel already exists. Build the semantic bridge that allows it to participate in SCR.**

And:

> **When no suitable kernel exists, SCR may implement the missing capability, but the implementation MUST remain behind a normative semantic contract so that it can be replaced.**

Therefore:

> **SCR owns meaning. Contracts own guarantees. Providers own implementation. EGS owns resolution and manifestation. Runtimes own execution.**

---

# 66. Final Rule

The normative Provider Contract is the stable boundary between SCR semantic computation and concrete computational infrastructure.

A Provider is not authoritative because it is powerful, mature, fast, canonical, or deeply integrated.

It is conformant only because it satisfies a contract.

Therefore:

> **The contract, not the Provider, is the stable architectural boundary.**
