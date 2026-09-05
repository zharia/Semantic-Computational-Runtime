---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-PROVIDERS
name: Providers

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-CORE

authority: SCR
domain: semantic-library
------------------------

# SCR Providers

## Definition

Providers is the cross-cutting semantic domain concerned with realizing declared semantic capabilities, interfaces, operations, and computational contracts through concrete implementations.

A Provider is an implementation authority for **how** a declared semantic capability is realized.

A Provider is NOT the authority for **what the capability means**.

The fundamental distinction is:

```text
Semantic Definition
        │
        ▼
     Interface
        │
        ▼
    Capability
        │
        ▼
     Provider
        │
        ▼
 Implementation
        │
        ▼
 Execution Substrate
```

Providers therefore form the bridge between SCR's semantic model and concrete computational realization.

---

# Semantic Model

A provider can be represented conceptually as:

```text
P = (I, C, R, A, T, K, E, G, V, X)
```

where:

* `I` = provider identity
* `C` = capabilities
* `R` = interfaces realized
* `A` = assumptions and requirements
* `T` = supported targets
* `K` = constraints
* `E` = execution semantics
* `G` = guarantees
* `V` = version and provenance
* `X` = external dependencies.

A provider declares what it can realize and under which conditions.

---

# Provider Primacy Rule

Providers MUST remain subordinate to semantic definitions.

```text
Semantic Meaning
      │
      ▼
Contract / Interface
      │
      ▼
Provider
      │
      ▼
Implementation
```

The reverse relationship is prohibited:

```text
Implementation
      ✕
      ↓
Semantic Meaning
```

An implementation MUST NOT redefine the meaning of the semantic operation it implements.

---

# Scope

SCR Providers encompasses:

* provider identity
* provider registration
* capability realization
* interface realization
* implementation selection
* provider discovery
* provider compatibility
* provider ranking
* provider negotiation
* provider lifecycle
* provider versioning
* provider dependencies
* provider constraints
* target hardware
* target runtime
* external libraries
* CPU providers
* GPU providers
* accelerator providers
* distributed providers
* numerical providers
* geometry providers
* physics providers
* spatial providers
* neural providers
* rendering providers
* messaging providers
* storage providers
* runtime providers
* fallback providers
* composite providers
* remote providers
* provider adapters
* provider isolation
* provider provenance
* provider telemetry
* provider equivalence
* provider validation.

---

# 1. Provider Identity

Every provider MUST have a stable identity.

Provider identity MUST be independent of:

* process identity
* machine identity
* filesystem path
* loaded library address
* container identity
* deployment instance.

A provider MAY have multiple runtime instances.

---

# 2. Provider Instance

A Provider describes an implementation capability.

A Provider Instance represents an actual runtime realization.

```text
Provider
   │
   ├── Instance A
   ├── Instance B
   └── Instance C
```

Provider identity and instance identity MUST remain distinct.

---

# 3. Capability Realization

A provider MAY realize one or more semantic capabilities.

For example:

```text
Provider
   ├── Spatial
   ├── Parallelizable
   ├── Vectorizable
   └── Deterministic
```

The provider MUST only advertise capabilities it can substantiate.

---

# 4. Interface Realization

A provider MAY implement one or more SCR interfaces.

```text
Interface
    │
    ├── Provider A
    ├── Provider B
    └── Provider C
```

Multiple providers MAY satisfy the same interface.

A provider MAY satisfy multiple interfaces.

---

# 5. Provider Contract

A provider MUST declare or expose the relevant:

* supported interfaces
* capabilities
* input constraints
* output guarantees
* state semantics
* effect semantics
* error semantics
* resource requirements
* target constraints
* precision characteristics
* determinism
* performance characteristics.

---

# 6. Provider Requirements

A provider MAY require:

* CPU features
* GPU features
* accelerator features
* runtime services
* libraries
* operating-system facilities
* memory capacity
* network access
* storage
* numerical precision
* external services.

Requirements MUST be distinguishable from capabilities.

---

# 7. Provider Capabilities

A provider's capabilities describe what it can realize.

Capabilities MAY include:

* computation
* vectorization
* parallelism
* differentiation
* integration
* optimization
* rendering
* streaming
* distribution
* persistence
* messaging
* spatial computation
* geometry
* physics
* neural computation.

Capabilities MUST have semantic definitions independent of the provider.

---

# 8. Provider Constraints

Providers MAY impose constraints.

Examples include:

* supported data types
* dimensions
* maximum tensor sizes
* supported topology
* supported geometry
* memory limits
* precision limits
* hardware requirements
* concurrency limits.

Constraints MUST be explicit where they affect provider applicability.

---

# 9. Provider Selection

SCR MAY select among multiple providers.

Conceptually:

```text
Semantic Operation
       │
       ▼
     Analysis
       │
       ▼
Capability Requirements
       │
       ▼
Provider Candidates
       │
       ▼
Provider Selection
       │
       ▼
Lowering / Execution
```

Provider selection is a runtime/compiler concern.

Applications SHOULD NOT need to hard-code a provider merely to express semantic intent.

---

# 10. Provider Discovery

Providers MAY be discovered through:

* static registration
* runtime registration
* semantic metadata
* capability queries
* hardware discovery
* service discovery
* remote discovery.

Discovery MUST expose sufficient information to determine compatibility.

---

# 11. Provider Compatibility

A provider is compatible with a requested operation when:

1. it satisfies the required interface;
2. it provides the required capabilities;
3. its constraints are satisfiable;
4. its guarantees satisfy the requested contract;
5. its target requirements are available;
6. its resource requirements can be met.

Syntactic API compatibility alone is insufficient.

---

# 12. Provider Ranking

When multiple compatible providers exist, SCR MAY rank them.

Ranking MAY consider:

* correctness guarantees
* semantic equivalence
* precision
* performance
* latency
* throughput
* resource consumption
* energy
* locality
* hardware affinity
* availability
* reliability
* cost
* provenance
* security.

Ranking MUST NOT select an incompatible provider merely because it is faster.

---

# 13. Semantic Suitability

Provider selection MUST prioritize semantic validity.

Conceptually:

```text
Correctness
    ↓
Compatibility
    ↓
Capability
    ↓
Constraints
    ↓
Resource Suitability
    ↓
Performance
    ↓
Cost
```

The precise ordering MAY vary by declared policy, but semantic correctness MUST remain a hard requirement unless an explicitly approximate contract permits otherwise.

---

# 14. Provider Equivalence

Two providers MAY be semantically equivalent for a declared operation.

Equivalence MAY concern:

* exact results
* observational behaviour
* numerical tolerance
* statistical behaviour
* state transitions
* topology
* geometry
* temporal behaviour.

Provider equivalence MUST be established under an explicit equivalence relation.

---

# 15. Approximate Providers

A provider MAY implement an approximate version of a semantic operation.

The provider MUST expose:

* approximation characteristics
* error bounds where known
* assumptions
* affected guarantees
* precision
* confidence where applicable.

Approximate providers MUST NOT masquerade as exact providers.

---

# 16. Deterministic Providers

A provider MAY guarantee deterministic execution.

The guarantee MUST specify relevant conditions, such as:

* identical inputs
* identical state
* identical configuration
* identical provider version
* identical hardware assumptions.

---

# 17. Stochastic Providers

A provider MAY intentionally implement stochastic computation.

It SHOULD expose:

* random source
* distribution semantics
* reproducibility
* seed behaviour where applicable
* statistical guarantees.

Stochastic semantics MUST remain distinct from accidental nondeterminism.

---

# 18. Provider State

Providers MAY be:

* stateless
* stateful
* session-based
* resource-bound
* transactional.

Provider state MUST NOT be confused with the semantic state of the computation being provided.

---

# 19. Provider Effects

Providers MAY introduce effects required to realize an operation.

Examples:

* allocation
* device transfer
* network communication
* persistence
* messaging
* logging
* telemetry.

Material effects MUST be observable through the provider contract.

---

# 20. Provider Errors

Providers MAY fail for implementation or environmental reasons.

Errors MAY include:

* unsupported operation
* unsupported type
* unavailable hardware
* resource exhaustion
* external-library failure
* communication failure
* timeout
* device failure
* numerical failure.

Provider errors MUST be distinguishable from semantic invalidity where possible.

---

# 21. Provider Fallback

SCR MAY define fallback providers.

```text
Primary Provider
       │
       ├── success ──► result
       │
       └── unavailable
                │
                ▼
        Fallback Provider
```

Fallback MUST only occur when the fallback satisfies the required semantic contract.

---

# 22. Provider Chains

Providers MAY compose into chains.

```text
Provider A
    ↓
Provider B
    ↓
Provider C
```

For example:

```text
Semantic Operation
       ↓
Provider Adapter
       ↓
Numerical Provider
       ↓
GPU Provider
       ↓
Hardware Runtime
```

The resulting chain MUST preserve the original contract.

---

# 23. Composite Providers

A provider MAY itself be composed of other providers.

```text
Composite Provider
   ├── Geometry Provider
   ├── Field Provider
   ├── Physics Provider
   └── Numerical Provider
```

The composite provider MAY expose a higher-level interface.

Its semantic guarantees MUST account for the guarantees of its components.

---

# 24. Provider Adapters

Adapters MAY allow a provider to satisfy an interface through a translation layer.

```text
Interface
    │
    ▼
Adapter
    │
    ▼
External Library
```

Adapters MUST preserve semantics where they claim compatibility.

---

# 25. External Libraries

External libraries MAY serve as providers.

Examples include:

* numerical libraries
* geometry libraries
* physics engines
* neural runtimes
* rendering engines
* database engines.

External libraries MUST remain replaceable implementation mechanisms.

Their APIs MUST NOT become the normative SCR semantic model.

---

# 26. Hardware Providers

Hardware MAY be exposed through providers.

Examples include:

* CPU
* GPU
* NPU
* TPU
* FPGA
* DSP
* specialized accelerators.

Hardware providers expose execution capabilities.

Hardware architecture MUST NOT redefine application semantics.

---

# 27. CPU Providers

CPU providers MAY expose:

* scalar computation
* vector computation
* threading
* SIMD
* native instructions
* memory operations.

CPU-specific optimizations MUST remain implementation details unless explicitly exposed as capabilities.

---

# 28. GPU Providers

GPU providers MAY expose:

* kernels
* device memory
* parallel execution
* texture operations
* synchronization
* graphics/compute capabilities.

GPU providers MUST expose hardware-specific limitations when they affect compatibility.

---

# 29. Accelerator Providers

Accelerator providers MAY expose specialized computational capabilities.

Examples include:

* matrix acceleration
* neural inference
* signal processing
* cryptographic operations
* domain-specific kernels.

---

# 30. Distributed Providers

Distributed providers MAY realize computation across:

* processes
* machines
* clusters
* cloud resources
* edge resources.

They MUST expose relevant:

* partitioning
* communication
* consistency
* failure
* latency
* availability semantics.

---

# 31. Numerical Providers

Numerical providers MAY implement:

* arithmetic
* linear algebra
* differential equations
* integration
* optimization
* interpolation
* transforms.

Numerical providers MUST expose relevant precision and stability characteristics.

---

# 32. Geometry Providers

Geometry providers MAY implement:

* intersection
* collision
* distance
* tessellation
* triangulation
* proximity
* constructive geometry.

Geometry semantics remain defined by `SCR-LIB-GEOMETRY`.

---

# 33. Physics Providers

Physics providers MAY implement:

* mechanics
* rigid bodies
* soft bodies
* fluids
* electromagnetics
* thermodynamics.

Physics providers realize physical models.

They do not define what a physical law means within SCR.

---

# 34. Neural Providers

Neural providers MAY implement:

* inference
* training
* tensor computation
* attention
* convolution
* recurrent computation
* accelerator execution.

Neural semantics remain defined by `SCR-LIB-NEURAL`.

---

# 35. Spatial Providers

Spatial providers MAY implement:

* spatial indexes
* coordinate transformations
* H3
* KD-trees
* BVHs
* navigation
* proximity.

Spatial representations remain subordinate to spatial semantics.

---

# 36. Rendering Providers

Rendering providers MAY implement:

* rasterization
* ray tracing
* path tracing
* scene management
* GPU rendering
* display output.

A rendering provider is an implementation of rendering semantics.

For example, SCR may eventually use:

```text
Semantic Render
      ↓
Rust Renderer Interface
      ↓
C++ Adapter
      ↓
VulkanSceneGraph
      ↓
Vulkan
      ↓
GPU
```

The provider chain is an implementation path, not the semantic definition of rendering.

---

# 37. Messaging Providers

Messaging providers MAY implement semantic messaging through transport systems such as AMQP.

Transport semantics and SCR message semantics MUST remain distinct.

---

# 38. Storage Providers

Storage providers MAY realize persistence through:

* filesystems
* databases
* object stores
* graph stores
* distributed stores.

Storage MUST NOT redefine the semantic identity or structure of stored objects.

---

# 39. Runtime Providers

Runtime providers MAY provide:

* scheduling
* execution
* memory management
* synchronization
* task management
* distributed execution.

Runtime providers operate beneath semantic execution requirements.

---

# 40. Provider Registration

Providers SHOULD expose metadata sufficient for registration.

Registration MAY include:

* provider identity
* version
* capabilities
* interfaces
* dependencies
* targets
* constraints
* provenance
* security requirements.

---

# 41. Provider Lifecycle

Providers may progress through:

```text
Discovered
   ↓
Registered
   ↓
Validated
   ↓
Available
   ↓
Selected
   ↓
Executing
   ↓
Observed
   ↓
Retired
```

Lifecycle state MUST remain distinct from provider identity.

---

# 42. Provider Versioning

Provider versions MUST identify implementation changes that may affect:

* semantics
* precision
* performance
* compatibility
* resource requirements
* dependencies.

A provider MUST NOT claim semantic compatibility merely because its API version is compatible.

---

# 43. Provider Provenance

Provider executions SHOULD record:

* provider identity
* provider version
* implementation
* dependencies
* hardware
* runtime
* configuration
* lowering path
* relevant analysis
* execution context.

This supports reproducibility and semantic traceability.

---

# 44. Provider Telemetry

Providers MAY emit telemetry concerning:

* latency
* throughput
* memory
* resource usage
* failures
* queueing
* device utilization
* numerical diagnostics.

Telemetry MUST remain distinguishable from semantic output.

---

# 45. Adaptive Provider Selection

SCR MAY dynamically change providers.

```text
Semantic Operation
       ↓
Provider A
       ↓
Telemetry
       ↓
Analysis
       ↓
Provider B
```

Provider migration MUST preserve the semantic contract.

This enables hardware-aware and runtime-adaptive execution.

---

# 46. Provider Selection and Analysis

SCR Analysis MAY determine:

* provider compatibility
* capability satisfaction
* resource suitability
* numerical suitability
* performance expectations
* equivalence
* risk.

Provider selection SHOULD be analysis-driven where appropriate.

---

# 47. Provider Selection and Lowering

Provider selection and lowering are related but distinct.

```text
Analysis
   ↓
Provider Selection
   ↓
Lowering Strategy
   ↓
Lowered Representation
   ↓
Provider Execution
```

A provider may offer several lowering paths.

A lowering may target several providers.

---

# 48. Provider Selection and Interfaces

Interfaces define what a provider must satisfy.

Providers define concrete realizations.

```text
Interface
    │
    ├──────────────┐
    ▼              ▼
Provider A      Provider B
```

This separation is fundamental to provider substitutability.

---

# 49. Provider Selection and Capabilities

Provider selection SHOULD operate over declared capabilities rather than implementation names.

For example:

```text
Required:
    Differentiable
    Parallelizable
    GPU-capable
    Deterministic
```

The runtime can then select an appropriate provider without the application naming a particular library.

---

# 50. Provider Selection and Resources

Selection MAY account for:

* available memory
* device locality
* bandwidth
* CPU load
* GPU availability
* network topology
* energy
* cost.

Resource constraints MUST NOT override semantic incompatibility.

---

# 51. Provider Security

Providers may have different trust levels.

SCR SHOULD support provider security metadata describing:

* required authority
* data access
* network access
* device access
* persistence
* isolation.

Untrusted providers SHOULD execute within appropriate isolation boundaries.

---

# 52. Provider Sandboxing

A provider MAY execute inside:

* process isolation
* containers
* WASM
* virtual machines
* hardware isolation.

Sandboxing is an execution mechanism.

It does not alter provider semantics.

---

# 53. Provider Determinism and Reproducibility

Provider reproducibility SHOULD distinguish:

```text
Semantic Determinism
        ≠
Bitwise Reproducibility
```

A provider may produce semantically equivalent results while differing at the bit level because of:

* hardware
* floating-point implementation
* parallel reduction
* numerical libraries.

The applicable equivalence relation MUST be explicit.

---

# 54. Provider Resource Semantics

Provider resource claims SHOULD distinguish:

* guaranteed capacity
* observed capacity
* preferred capacity
* maximum capacity
* minimum capacity.

Resource observations MUST NOT automatically become normative guarantees.

---

# 55. Provider Cost

Providers MAY expose cost information.

Cost may include:

* computational cost
* memory cost
* energy
* network cost
* monetary cost
* latency.

Cost is an analysis and selection attribute, not semantic meaning.

---

# 56. Provider Failure and Recovery

Provider failure MUST NOT automatically imply semantic failure.

SCR MAY recover through:

* retry
* fallback
* migration
* recomputation
* checkpoint restore
* alternative provider.

Recovery MUST preserve the relevant semantic contract.

---

# 57. Provider State Migration

Stateful providers MAY support migration between implementations.

Migration requires an explicit mapping:

```text
Provider A State
       │
       ▼
State Mapping
       │
       ▼
Provider B State
```

Migration MUST preserve declared semantic state.

---

# 58. Provider Persistence

A provider MAY persist implementation state.

Implementation state MUST remain distinguishable from semantic state.

---

# 59. Provider Streaming

Providers MAY realize stream interfaces.

They MUST preserve declared:

* ordering
* timing
* delivery
* backpressure
* state
* error semantics.

---

# 60. Provider Graph Integration

Providers SHOULD be represented as first-class semantic objects within the Semantic Hypergraph.

Conceptually:

```text
Provider
   │
   ├── implements ─────► Interface
   ├── provides ───────► Capability
   ├── requires ───────► Resource
   ├── executes-on ────► Target
   ├── depends-on ─────► Provider
   ├── lowers-from ────► Representation
   └── produces ───────► Result
```

This enables provider discovery and selection through semantic graph queries.

---

# 61. Standards and Interoperability

SCR SHOULD reuse established standards wherever they provide appropriate provider interoperability.

Potential mechanisms include:

* MLIR
* LLVM
* SPIR-V
* Vulkan
* OpenCL
* CUDA-compatible interfaces
* WebAssembly
* ONNX
* OpenGL
* glTF
* AMQP
* standard database interfaces
* established numerical APIs
* established hardware interfaces.

These standards provide implementation interoperability.

They MUST NOT become the normative SCR semantic model.

---

# Expected Subdomains

```text
providers/
├── provider-core
├── Identity
├── Registration
├── Discovery
├── Capability
├── Interface
├── Compatibility
├── Selection
├── Ranking
├── Negotiation
├── Fallback
├── Composite
├── Adapter
├── External
├── CPU
├── GPU
├── Accelerator
├── Distributed
├── Numerical
├── Geometry
├── Physics
├── Spatial
├── Neural
├── Rendering
├── Messaging
├── Storage
├── Runtime
├── Remote
├── State
├── Resource
├── Security
├── Isolation
├── Version
├── Provenance
├── Telemetry
├── Validation
└── Lifecycle
```

---

# Invariants

### PROVIDER-INV-001 — Semantic Subordination

Providers MUST remain subordinate to semantic definitions.

### PROVIDER-INV-002 — Capability Integrity

Providers MUST only advertise capabilities they can satisfy.

### PROVIDER-INV-003 — Interface Integrity

Providers MUST conform to the interfaces they claim to implement.

### PROVIDER-INV-004 — Implementation Independence

Semantic definitions MUST NOT depend upon provider implementations.

### PROVIDER-INV-005 — Replaceability

Compatible providers SHOULD be replaceable where semantic equivalence permits.

### PROVIDER-INV-006 — Compatibility

Provider selection MUST satisfy all mandatory semantic compatibility conditions.

### PROVIDER-INV-007 — Constraint Transparency

Material provider constraints MUST be explicit.

### PROVIDER-INV-008 — Approximation Transparency

Approximate providers MUST explicitly declare approximation.

### PROVIDER-INV-009 — Error Transparency

Material provider failure modes MUST remain observable.

### PROVIDER-INV-010 — Effect Transparency

Material provider effects MUST remain semantically visible.

### PROVIDER-INV-011 — State Integrity

Provider state MUST remain distinguishable from semantic state.

### PROVIDER-INV-012 — Provenance

Provider execution MUST remain traceable where reproducibility or correctness requires it.

### PROVIDER-INV-013 — Version Integrity

Provider version changes affecting semantic guarantees MUST be identifiable.

### PROVIDER-INV-014 — Resource Transparency

Material resource characteristics MUST be available to analysis and selection.

### PROVIDER-INV-015 — Hardware Independence

Hardware-specific implementation MUST NOT redefine semantic meaning.

### PROVIDER-INV-016 — External Independence

External libraries MUST remain implementation providers rather than semantic authorities.

### PROVIDER-INV-017 — Security Integrity

Provider execution MUST respect declared security and isolation requirements.

### PROVIDER-INV-018 — Selection Correctness

Provider selection MUST NOT sacrifice mandatory semantic correctness for performance or cost.

---

# Architectural Rules

1. Providers MUST implement declared semantic interfaces.
2. Providers MUST expose declared capabilities.
3. Providers MUST remain independent of semantic authority.
4. Providers MUST integrate with Analysis.
5. Providers MUST integrate with Interfaces.
6. Providers MUST integrate with Lowering.
7. Providers MUST integrate with Transforms.
8. Providers MAY integrate with Runtime.
9. Providers MAY integrate with hardware-specific execution.
10. Providers MAY wrap external libraries.
11. Providers MAY be composed.
12. Providers MAY be distributed.
13. Providers MAY be remote.
14. Providers MAY be dynamically selected.
15. Providers MAY be dynamically replaced.
16. Provider selection MUST be capability-driven.
17. Provider selection MUST be contract-driven.
18. Provider selection MUST consider resource constraints.
19. Provider selection MUST preserve semantic correctness.
20. Provider failure MUST remain distinguishable from semantic failure.
21. Provider state MUST remain distinct from semantic state.
22. Provider telemetry MUST remain distinct from semantic output.
23. Provider provenance SHOULD be retained.
24. Provider versions MUST be explicit.
25. Provider approximations MUST be explicit.
26. Provider security requirements MUST be explicit.
27. Provider hardware dependencies MUST remain implementation-level concerns.
28. External libraries MUST NOT define SCR semantics.
29. Provider APIs MUST NOT become mandatory semantic dependencies.
30. Provider implementations MUST remain replaceable where compatibility permits.
31. Provider chains MUST preserve the originating semantic contract.
32. Provider adapters MUST preserve semantics where compatibility is claimed.
33. Provider migration MUST preserve semantic state where supported.
34. Provider discovery SHOULD operate through the Semantic Hypergraph.
35. Provider selection SHOULD be adaptive where useful.

---

# Completeness Criteria

An implementation of SCR Providers is semantically complete only when it can represent:

* provider identity
* provider instances
* capabilities
* interfaces
* provider contracts
* requirements
* constraints
* compatibility
* discovery
* selection
* ranking
* negotiation
* equivalence
* approximation
* determinism
* stochasticity
* state
* effects
* errors
* fallback
* provider chains
* composite providers
* adapters
* external libraries
* CPU providers
* GPU providers
* accelerator providers
* distributed providers
* numerical providers
* geometry providers
* physics providers
* spatial providers
* neural providers
* rendering providers
* messaging providers
* storage providers
* runtime providers
* remote providers
* registration
* lifecycle
* versioning
* provenance
* telemetry
* adaptive selection
* resource semantics
* security
* isolation
* state migration
* streaming
* Semantic Hypergraph integration.

---

# Testing Requirements

### Specification Tests

Validate provider semantics against this definition.

### Capability Tests

Verify that advertised capabilities are actually supported.

### Interface Conformance Tests

Verify provider implementations against their declared interfaces.

### Compatibility Tests

Verify provider selection against semantic contracts.

### Equivalence Tests

Verify claims that different providers are semantically equivalent.

### Approximation Tests

Verify declared approximation guarantees.

### Determinism Tests

Verify declared deterministic behaviour.

### Resource Tests

Verify resource requirements and constraints.

### Error Tests

Verify provider failure semantics.

### State Tests

Verify provider state and migration semantics.

### Adapter Tests

Verify semantic preservation across provider adapters.

### External Library Tests

Verify that external library wrappers conform to SCR semantics.

### Hardware Tests

Verify CPU, GPU, accelerator, and distributed provider behaviour.

### Fallback Tests

Verify that fallback providers preserve the required contract.

### Selection Tests

Verify analysis-driven provider selection.

### Provenance Tests

Verify provider execution provenance.

### Security Tests

Verify isolation and authority requirements.

### Runtime Tests

Verify dynamic provider selection and replacement.

---

# Open Semantic Questions

1. What is the formal representation of a provider capability?
2. How should provider suitability be ranked?
3. How should provider equivalence be formally established?
4. How should approximate providers participate in selection?
5. How should provider reputation or historical performance affect selection?
6. How should runtime telemetry influence provider selection?
7. How should providers advertise dynamic capabilities?
8. How should state migration be formally represented?
9. How should provider chains expose their aggregate contract?
10. How should composite providers propagate failures?
11. How should remote providers express availability?
12. How should provider security requirements integrate with runtime policy?
13. How should provider costs be represented?
14. How should provider selection be made reproducible?
15. How should semantic provider discovery integrate with ISO GQL?
16. How should provider selection interact with adaptive execution?
17. How should external libraries expose semantic guarantees that exceed their native APIs?
18. How should provider implementations prove semantic conformance?

These questions MUST NOT be resolved implicitly by implementation.

---

# Definition History

## 0.1.0

Initial normative semantic definition.

Establishes Providers as the implementation-realization domain through which SCR semantic capabilities and interfaces are realized by concrete algorithms, libraries, runtimes, hardware, and distributed execution mechanisms.

---

# Definition Authority

This document is the normative semantic authority for `SCR-LIB-PROVIDERS`.

Provider implementations, external libraries, hardware integrations, runtime adapters, and execution services MUST conform to the semantic contracts defined by SCR rather than redefining those contracts.

---

# Definition Principle

> **A provider realizes computational meaning; it does not define computational meaning.**
>
> **SCR defines what a computation means. Interfaces define what may be relied upon. Providers determine how that meaning is realized on an available computational substrate.**
> :::writing_end:::

The next existing root after `Providers` is **`Render`**.
