---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-LOWERING
name: Lowering

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-CORE

authority: SCR
domain: semantic-library
------------------------

# SCR Lowering

## Definition

Lowering is the semantic computational domain concerned with transforming a computational representation from a higher semantic level into a lower-level representation while preserving the declared meaning, behaviour, constraints, and guarantees of the source computation.

Lowering is therefore a **semantics-preserving transformation process**.

The essential distinction is:

```text
Higher-Level Semantics
        │
        │ lowering
        ▼
Lower-Level Representation
        │
        ▼
Executable Realization
```

Lowering does not mean merely:

* generating machine code;
* converting one file format into another;
* translating syntax;
* replacing one API with another;
* invoking a compiler backend.

A lowering transformation MUST establish how the semantics of the source are represented and realized at the target level.

---

# Semantic Model

A lowering transformation can be represented conceptually as:

```text
L = (S, T, M, C, P, G, E, R)
```

where:

* `S` = source semantic representation
* `T` = target representation
* `M` = semantic mapping
* `C` = transformation conditions
* `P` = preservation obligations
* `G` = resulting guarantees
* `E` = effects of transformation
* `R` = provenance and traceability.

A lowering operation MUST define the relationship between source and target semantics.

---

# Lowering Primacy

The semantic meaning of the source MUST remain authoritative.

```text
Source Semantics
      │
      ▼
Lowering Transformation
      │
      ▼
Target Representation
```

The target representation MUST NOT silently redefine the source semantics.

If a target cannot represent some aspect of the source semantics exactly, the lowering MUST:

* reject the transformation;
* preserve the information through an explicit mechanism;
* introduce an explicitly declared approximation;
* or produce a target with explicitly weakened guarantees.

Silent semantic loss is prohibited.

---

# Scope

SCR Lowering encompasses:

* semantic lowering
* representation lowering
* abstraction reduction
* dialect conversion
* operation conversion
* type conversion
* data representation conversion
* memory lowering
* control-flow lowering
* tensor lowering
* vector lowering
* parallelization
* tiling
* bufferization
* hardware-specific lowering
* accelerator lowering
* runtime lowering
* external-library lowering
* distributed lowering
* communication lowering
* serialization-oriented lowering
* provider lowering
* ABI lowering
* executable lowering
* legalization
* target selection
* lowering pipelines
* lowering legality
* lowering compatibility
* semantic preservation
* approximation
* specialization
* provenance.

---

# 1. Abstraction Levels

SCR lowering operates across abstraction levels.

Conceptually:

```text
Semantic Domain
      ↓
Semantic Operation
      ↓
Semantic IR
      ↓
MLIR Dialect
      ↓
MLIR Lower-Level Dialect
      ↓
LLVM / GPU / SPIR-V / Runtime
      ↓
Native Execution
```

The number of levels is not fixed.

A lowering pipeline MAY contain:

* one transformation;
* multiple transformations;
* alternative branches;
* target-specific paths;
* conditional transformations.

---

# 2. Lowering Direction

Lowering normally moves toward a representation with fewer semantic abstractions and more explicit implementation detail.

For example:

```text
Physics
   ↓
Dynamics
   ↓
Numerical Representation
   ↓
Linalg
   ↓
SCF
   ↓
LLVM
```

However, SCR MUST distinguish lowering from arbitrary transformation.

A transformation is lowering only when it intentionally moves computation toward a lower implementation abstraction.

---

# 3. Lowering Versus Transformation

Transformation is the broader concept.

```text
Transformation
├── Lowering
├── Raising
├── Canonicalization
├── Optimization
├── Specialization
├── Fusion
├── Decomposition
└── Representation Conversion
```

Not every transformation is lowering.

Lowering is specifically concerned with moving toward a lower realization level.

---

# 4. Semantic Preservation

Every lowering MUST identify which semantic properties are preserved.

These may include:

* value semantics
* type semantics
* shape
* dimensionality
* units
* topology
* geometry
* temporal behaviour
* state transitions
* ordering
* determinism
* stochasticity
* side effects
* errors
* resource constraints
* provenance.

---

# 5. Exact Lowering

An exact lowering preserves the relevant source semantics without approximation.

Conceptually:

```text
Semantics(S) ≡ Semantics(T)
```

under the declared equivalence relation.

Exactness MUST be evaluated relative to a declared semantic contract.

---

# 6. Approximate Lowering

A lowering MAY intentionally introduce approximation.

Examples include:

* reduced precision
* discretization
* numerical approximation
* quantization
* reduced-order models
* approximate geometry
* approximate topology
* probabilistic approximation.

Approximation MUST be explicit.

The resulting contract MUST identify:

* approximation type
* error bounds where known
* assumptions
* affected semantics
* confidence or guarantees.

---

# 7. Lowering Contracts

A lowering transformation MUST have a contract describing:

* source requirements
* target requirements
* legal inputs
* produced outputs
* preservation guarantees
* approximation
* resource requirements
* failure conditions.

---

# 8. Lowering Legality

A lowering is legal only when its source satisfies the transformation's requirements.

Legality MAY depend upon:

* operation types
* capabilities
* data layout
* topology
* shape
* dimensions
* memory model
* target architecture
* numerical constraints
* available providers.

Legality MUST be analyzable where practical.

---

# 9. Progressive Lowering

SCR SHOULD support progressive lowering.

```text
Semantic Operation
       ↓
Canonical Representation
       ↓
Target-Independent IR
       ↓
Target-Aware IR
       ↓
Hardware-Specific IR
       ↓
Executable Representation
```

Each stage SHOULD retain sufficient provenance to identify its source.

---

# 10. MLIR Relationship

SCR Lowering is implemented substantially through MLIR transformations where appropriate.

MLIR provides dialects, conversion infrastructure, transformations, interfaces, and other compiler mechanisms that make multi-level lowering possible.

However:

> **MLIR is the transformation substrate; SCR defines the semantic meaning being preserved.**

SCR MUST NOT treat the existence of an MLIR representation as proof that semantic preservation has occurred.

---

# 11. Dialect Lowering

An SCR semantic domain MAY be represented by an MLIR dialect.

That dialect MAY lower to:

* another SCR dialect;
* standard MLIR dialects;
* LLVM;
* GPU;
* SPIR-V;
* runtime operations;
* external-library operations.

Dialect conversion MUST preserve the relevant SCR semantics.

---

# 12. Type Lowering

Types MAY be lowered from semantic types to more explicit representations.

Examples:

```text
Semantic Quantity
       ↓
Numeric Value + Unit Metadata
```

```text
Semantic Field
       ↓
Tensor / MemRef / Buffer
```

```text
Semantic Geometry
       ↓
Explicit Coordinate / Mesh Representation
```

Type lowering MUST preserve semantics required by downstream operations.

---

# 13. Data Lowering

Data structures MAY be transformed into lower-level representations.

Examples include:

* collections → buffers
* records → structures
* sparse data → indexed storage
* fields → sampled buffers
* graphs → explicit adjacency structures
* tensors → memory layouts.

The physical representation MUST NOT become the semantic authority.

---

# 14. Memory Lowering

Memory lowering transforms abstract data ownership and access semantics into explicit memory operations.

It MAY introduce:

* buffers
* allocations
* deallocations
* copies
* views
* aliases
* synchronization.

Memory lowering MUST preserve ownership, lifetime, aliasing, and mutation semantics where those are part of the source contract.

---

# 15. Bufferization

Bufferization converts value-oriented or tensor-oriented representations into explicit mutable storage where required.

Bufferization MUST preserve:

* shape
* element semantics
* indexing semantics
* aliasing guarantees
* mutation semantics
* lifetime requirements.

---

# 16. Control-Flow Lowering

Higher-level operations MAY lower into explicit control flow.

Examples:

```text
Semantic Iteration
       ↓
SCF
       ↓
CF
       ↓
LLVM
```

Control-flow lowering MUST preserve:

* ordering
* termination
* branching semantics
* effects
* state transitions.

---

# 17. Parallel Lowering

Parallel semantics MAY be lowered into:

* explicit parallel loops
* task graphs
* vector operations
* GPU kernels
* distributed operations.

Parallel lowering MUST preserve declared race, ordering, determinism, reduction, and synchronization semantics.

---

# 18. Vector Lowering

Vectorizable semantics MAY be lowered into explicit vector operations.

Vectorization MUST preserve:

* element correspondence
* ordering where required
* numerical semantics
* masking semantics
* boundary behaviour.

---

# 19. Tiling

Tiling transforms computation into explicit spatial or temporal partitions.

```text
Large Computation
       ↓
     Tiles
   /   |   \
  ▼    ▼    ▼
Tile Tile Tile
```

Tiling MUST preserve the semantics of the untiled computation subject to declared boundary and ordering conditions.

---

# 20. Fusion

Fusion combines compatible operations into a lower-level composite representation.

Fusion MUST preserve:

* dependency ordering
* observable effects
* numerical semantics
* state transitions
* synchronization requirements.

Fusion MUST NOT be considered semantics-preserving merely because it improves performance.

---

# 21. Specialization

Lowering MAY specialize computation based on known information.

Examples include:

* known dimensions
* fixed topology
* constant parameters
* known hardware
* known precision
* known capability sets.

Specialization MUST record assumptions that affect validity.

---

# 22. Hardware-Aware Lowering

SCR lowering MAY use target hardware characteristics.

These may include:

* CPU instruction sets
* SIMD width
* GPU architecture
* accelerator capabilities
* memory hierarchy
* bandwidth
* topology
* distributed resources.

Hardware awareness MUST affect realization rather than semantic meaning.

---

# 23. CPU Lowering

CPU lowering MAY produce:

* scalar operations
* vector operations
* threaded operations
* native calls
* LLVM IR.

The selected CPU implementation is a provider realization, not a semantic definition.

---

# 24. GPU Lowering

GPU lowering MAY produce:

* GPU kernels
* device memory operations
* launch configuration
* synchronization
* GPU-specific representations.

GPU-specific semantics MUST remain subordinate to the source semantic contract.

---

# 25. Accelerator Lowering

Other accelerators MAY be targeted when appropriate.

Examples include:

* NPUs
* TPUs
* DSPs
* FPGAs
* custom accelerators.

SCR MUST treat accelerator support as an execution capability.

---

# 26. External Library Lowering

A semantic operation MAY lower into an external library invocation.

For example:

```text
Semantic Matrix Operation
        ↓
Lowering
        ↓
BLAS Provider
```

or:

```text
Semantic Geometry Operation
        ↓
Lowering
        ↓
Geometry Provider
```

External libraries MUST remain providers.

They MUST NOT become semantic authorities.

---

# 27. Runtime Lowering

Some operations MAY lower into runtime services rather than direct machine instructions.

Examples include:

* scheduling
* messaging
* memory management
* distributed execution
* synchronization
* resource acquisition.

Runtime lowering MUST preserve semantic execution requirements.

---

# 28. Distributed Lowering

A computation MAY lower into distributed execution.

```text
Semantic Computation
        ↓
Partition
   ┌────┼────┐
   ▼    ▼    ▼
 Node Node Node
   └────┼────┘
        ▼
   Semantic Result
```

Distributed lowering MUST explicitly address:

* partitioning
* communication
* ordering
* consistency
* synchronization
* failures
* aggregation.

---

# 29. Messaging Lowering

Messaging semantics MAY lower into a messaging provider.

SCR may use AMQP-oriented execution models where appropriate.

AMQP is a transport/execution mechanism.

It MUST NOT redefine SCR message semantics.

---

# 30. Stream Lowering

Semantic streams MAY lower into:

* channels
* queues
* event processors
* streaming runtimes
* distributed streams.

Stream lowering MUST preserve declared:

* ordering
* temporal semantics
* delivery semantics
* backpressure
* state
* error behaviour.

---

# 31. Rendering Lowering

Renderable semantics MAY lower through progressively concrete representations:

```text
Semantic Scene
      ↓
Render State
      ↓
Render Commands
      ↓
Renderer API
      ↓
Backend
      ↓
GPU
```

A renderer is therefore a provider of a semantic rendering interface.

Rendering lowering MUST NOT redefine the semantic scene.

---

# 32. Geometry Lowering

Geometry MAY lower through multiple representations.

For example:

```text
Semantic Geometry
       ↓
Implicit Representation
       ↓
Mesh
       ↓
GPU Buffer
```

or:

```text
Semantic Geometry
       ↓
Parametric Representation
       ↓
Tessellation
       ↓
Mesh
```

Different lowering paths MAY represent the same geometry.

---

# 33. Field Lowering

Fields MAY lower into:

* analytic functions
* sampled arrays
* tensors
* sparse structures
* grids
* textures
* distributed partitions.

The representation MUST preserve field domain and value semantics.

---

# 34. Graph Lowering

Graphs MAY lower into:

* adjacency structures
* compressed sparse representations
* hyperedge tables
* tensors
* traversal structures
* distributed graph partitions.

Higher-order relationships MUST NOT be reduced to pairwise relationships when doing so loses semantic information.

---

# 35. Morphology Lowering

Morphology MAY lower into:

* graph structures
* topology
* geometry
* fields
* meshes
* voxels
* particles
* procedural representations.

Because morphology is inherently multi-representational, multiple lowering paths MAY be valid.

---

# 36. Physics and Dynamics Lowering

Physical and dynamical semantics MAY lower through:

```text
Physics
   ↓
Dynamics
   ↓
Numerical Model
   ↓
Discretization
   ↓
Solver
   ↓
Executable Kernel
```

Each stage MUST preserve the declared model semantics within its stated approximation.

---

# 37. Simulation Lowering

Simulation semantics MAY lower into explicit:

* state storage
* clocks
* event queues
* stepping loops
* integrators
* solvers
* scheduling
* distributed execution.

Simulation lowering MUST preserve the distinction between:

* model time
* simulation time
* wall time.

---

# 38. Agent Lowering

Agent semantics MAY lower into explicit:

* state machines
* decision functions
* policies
* perception pipelines
* control loops
* communication operations.

The implementation mechanism MUST NOT determine whether an entity is semantically an agent.

---

# 39. Neural Lowering

Neural semantics MAY lower into:

* tensor operations
* graph operations
* convolution kernels
* attention operations
* vector operations
* accelerator kernels.

Neural lowering MUST preserve declared model semantics and numerical guarantees.

---

# 40. Lowering Pipelines

A lowering pipeline is an ordered or conditionally ordered set of transformations.

```text
Pipeline:
    A
    ↓
    B
    ↓
    C
    ↓
    D
```

A pipeline MUST have:

* defined stages
* legality conditions
* ordering constraints
* preservation obligations
* failure semantics
* provenance.

---

# 41. Alternative Lowering Paths

SCR MAY have multiple valid lowering paths.

```text
                 ┌──► CPU
Semantic Model ──┼──► GPU
                 ├──► Accelerator
                 └──► Distributed
```

Path selection MAY depend upon:

* capabilities
* hardware
* resource availability
* performance
* precision
* topology
* provider availability.

The semantic result MUST remain governed by the source contract.

---

# 42. Lowering Selection

SCR Analysis MAY determine which lowering path is appropriate.

Selection MAY consider:

* legality
* capabilities
* compatibility
* resource requirements
* cost
* performance
* hardware
* provider availability.

Lowering selection is therefore distinct from lowering itself.

---

# 43. Lowering Failure

A lowering MUST fail explicitly when its semantic requirements cannot be satisfied.

Failure MUST NOT silently produce an invalid representation.

Possible outcomes include:

```text
Success
Approximate Success
Deferred
Unsupported
Invalid
Resource-Constrained
Semantically Incompatible
```

---

# 44. Lowering Provenance

Every significant lowering transformation SHOULD preserve provenance identifying:

* source
* target
* transformation
* implementation
* version
* assumptions
* parameters
* timestamp
* analysis results.

This enables traceability through the compilation pipeline.

---

# 45. Reversibility

Some lowerings MAY be reversible.

Others are inherently lossy.

A lowering MUST NOT claim reversibility unless sufficient information exists to reconstruct the relevant source semantics.

---

# 46. Raising

Raising is the inverse conceptual direction:

```text
Low-Level Representation
        ↓
      Raising
        ↓
Higher-Level Representation
```

Raising is not necessarily the exact inverse of lowering.

SCR MUST distinguish raising from reconstruction or inference.

---

# 47. Canonicalization

Canonicalization may occur before, during, or after lowering.

Canonicalization seeks equivalent representations with normalized structure.

It MUST NOT be confused with lowering.

---

# 48. Lowering and Optimization

Optimization MAY occur during lowering.

However:

```text
Lowering ≠ Optimization
```

A lowering can be semantics-preserving without optimizing.

An optimization can occur without changing abstraction level.

Combined transformations MUST maintain both contracts independently.

---

# 49. Lowering and Representation

Representation changes may occur during lowering.

However:

```text
Representation
      ≠
Semantics
```

The target representation MUST remain a realization of the source semantics.

---

# 50. Lowering and Providers

Providers MAY expose lowering targets.

For example:

```text
Semantic Operation
       ↓
Provider Capability
       ↓
Lowering
       ↓
Provider Implementation
```

Provider-specific lowering MUST remain replaceable.

---

# 51. Lowering and Interfaces

Lowering SHOULD operate through semantic interfaces where possible.

An MLIR transformation may query interfaces rather than depend upon concrete operations or dialects. This is one of MLIR's core mechanisms for keeping analyses and transformations generic across dialects.

SCR extends this principle semantically:

> Lowering should depend on declared capabilities and contracts rather than implementation identity.

---

# 52. Lowering and Analysis

Analysis SHOULD precede or guide lowering where necessary.

Analysis may determine:

* legality
* capabilities
* dependencies
* costs
* numerical stability
* parallelism
* locality
* resource requirements
* target suitability.

---

# 53. Lowering and Adaptive Execution

Lowering MAY be selected or regenerated dynamically.

For example:

```text
Semantic Operation
       ↓
Analysis
       ↓
Available Hardware
       ↓
Provider Selection
       ↓
Lowering
       ↓
Execution
       ↓
Telemetry
       ↓
Re-analysis
```

This enables adaptive execution without changing application semantics.

---

# 54. Lowering and Semantic Equivalence

Different lowering paths MAY produce representations that are semantically equivalent.

```text
          Semantic Operation
              /        \
             /          \
            ▼            ▼
        Lowering A    Lowering B
            │            │
            ▼            ▼
        Representation A
        Representation B

              │
              ▼
       Semantic Equivalence
```

Equivalence MUST be established under an explicit semantic relation.

---

# 55. Lowering and Numerical Semantics

Numerical lowering MUST distinguish:

* exact semantics
* finite precision
* rounding
* approximation
* stability
* error propagation.

A change in numerical semantics MUST be explicit.

---

# 56. Lowering and Determinism

Lowering MUST preserve determinism when the source contract requires it.

Introducing:

* parallel reduction
* asynchronous execution
* stochastic algorithms
* nondeterministic scheduling

MUST NOT silently invalidate a deterministic interface.

---

# 57. Lowering and Concurrency

Lowering MAY introduce concurrency.

It MUST preserve source ordering and synchronization requirements where those are semantically observable.

---

# 58. Lowering and Resource Semantics

Lowering MAY change resource requirements.

The transformation MUST expose material changes in:

* memory
* compute
* communication
* latency
* energy
* storage.

---

# 59. Security and Isolation

Lowering MUST preserve declared security and isolation properties.

A transformation MUST NOT introduce unauthorized:

* data access
* resource access
* communication
* persistence
* execution authority.

---

# 60. Standards and Interoperability

SCR SHOULD reuse established standards for target representations and interoperability wherever applicable.

Potential targets include:

* MLIR
* LLVM IR
* SPIR-V
* WebAssembly
* ONNX
* OpenGL/Vulkan representations
* glTF
* standard numerical representations
* standard serialization formats
* standard messaging protocols.

These are target mechanisms.

They are not the semantic definition of SCR lowering.

---

# Expected Subdomains

```text
lowering/
├── lowering-core
├── Analysis
├── Arith
├── Async
├── Bufferization
├── CF
├── External
├── GPU
├── Linalg
├── LLVM
├── Math
├── MemRef
├── Native
├── Runtime
├── SCF
├── SPIRV
├── Standard
├── Tensor
└── Vector
```

---

# Invariants

### LOWERING-INV-001 — Semantic Preservation

Lowering MUST preserve declared source semantics.

### LOWERING-INV-002 — Explicit Approximation

Any semantic approximation MUST be explicitly declared.

### LOWERING-INV-003 — Source Authority

The source semantic contract remains authoritative.

### LOWERING-INV-004 — Target Legality

A target representation MUST satisfy the requirements of the lowering.

### LOWERING-INV-005 — No Silent Loss

Essential semantic information MUST NOT be silently discarded.

### LOWERING-INV-006 — Contract Preservation

Declared guarantees MUST survive lowering unless explicitly weakened.

### LOWERING-INV-007 — Provenance

Significant lowering transformations MUST remain traceable.

### LOWERING-INV-008 — Representation Independence

Target representation MUST NOT redefine semantic meaning.

### LOWERING-INV-009 — Provider Independence

Provider-specific lowering MUST remain replaceable.

### LOWERING-INV-010 — Determinism

Required determinism MUST be preserved.

### LOWERING-INV-011 — State Integrity

State semantics MUST remain valid across lowering.

### LOWERING-INV-012 — Effect Integrity

Observable effects MUST remain semantically valid.

### LOWERING-INV-013 — Error Integrity

Declared error semantics MUST remain meaningful.

### LOWERING-INV-014 — Resource Transparency

Material resource changes MUST be analyzable.

### LOWERING-INV-015 — Version Integrity

Lowering transformations MUST identify relevant version assumptions.

### LOWERING-INV-016 — Pipeline Integrity

Each lowering stage MUST satisfy its declared contract before the next stage relies upon it.

### LOWERING-INV-017 — Equivalence Integrity

Semantic equivalence MUST be established rather than assumed.

### LOWERING-INV-018 — Implementation Independence

SCR semantics MUST remain independent of the target implementation mechanism.

---

# Architectural Rules

1. Lowering MUST be subordinate to semantic definitions.
2. Lowering MUST NOT redefine semantic meaning.
3. Lowering MUST compose with Core.
4. Lowering MUST compose with Analysis.
5. Lowering MUST compose with Interfaces.
6. Lowering MUST compose with Transforms.
7. Lowering MUST compose with Providers.
8. Lowering MUST integrate with MLIR where appropriate.
9. Lowering MUST support multiple target paths.
10. Lowering MUST support explicit semantic preservation.
11. Lowering MUST support explicit approximation.
12. Lowering MUST preserve provenance.
13. Lowering MUST permit target-specific specialization.
14. Lowering MUST permit hardware-aware realization.
15. Lowering MUST NOT make hardware part of application semantics.
16. Lowering MUST NOT make external libraries semantic authorities.
17. Lowering MUST distinguish lowering from optimization.
18. Lowering MUST distinguish lowering from representation conversion.
19. Lowering MUST distinguish lowering from raising.
20. Lowering MUST expose material resource changes.
21. Lowering MUST preserve declared state semantics.
22. Lowering MUST preserve declared effect semantics.
23. Lowering MUST preserve declared error semantics.
24. Lowering MUST preserve required determinism.
25. Lowering MUST permit alternative valid implementations.
26. Lowering SHOULD support analysis-driven path selection.
27. Lowering SHOULD support adaptive execution.
28. Lowering SHOULD support incremental and partial lowering.
29. Lowering SHOULD support distributed execution.
30. Lowering SHOULD support external provider integration.

---

# Completeness Criteria

An implementation of SCR Lowering is semantically complete only when it can represent:

* source representations
* target representations
* semantic mappings
* lowering contracts
* legality
* semantic preservation
* approximation
* type lowering
* data lowering
* memory lowering
* bufferization
* control-flow lowering
* parallel lowering
* vector lowering
* tiling
* fusion
* specialization
* CPU lowering
* GPU lowering
* accelerator lowering
* external-library lowering
* runtime lowering
* distributed lowering
* messaging lowering
* stream lowering
* rendering lowering
* geometry lowering
* field lowering
* graph lowering
* morphology lowering
* physics lowering
* dynamics lowering
* simulation lowering
* agent lowering
* neural lowering
* lowering pipelines
* alternative lowering paths
* provider selection
* failure semantics
* provenance
* reversibility
* raising
* canonicalization
* optimization interaction
* equivalence
* numerical semantics
* determinism
* concurrency
* resource semantics
* security
* standards interoperability.

---

# Testing Requirements

### Specification Tests

Validate lowering semantics against the normative definition.

### Legality Tests

Verify that illegal source/target combinations are rejected.

### Preservation Tests

Verify semantic equivalence between source and lowered representation.

### Approximation Tests

Verify declared error bounds and weakened guarantees.

### Type Tests

Verify semantic type preservation.

### State Tests

Verify state transitions remain valid.

### Effect Tests

Verify observable effects remain valid.

### Error Tests

Verify failure semantics survive lowering.

### Numerical Tests

Verify numerical stability and precision requirements.

### Determinism Tests

Verify deterministic source computations remain deterministic where required.

### Backend Tests

Validate CPU, GPU, accelerator, and other targets.

### Provider Tests

Verify external providers satisfy lowering contracts.

### Pipeline Tests

Validate multi-stage lowering.

### Equivalence Tests

Compare independent lowering paths.

### Provenance Tests

Verify transformation provenance remains complete.

### Runtime Tests

Validate lowered representations during actual execution.

---

# Open Semantic Questions

1. What is the formal SCR definition of semantic preservation?
2. How should preservation proofs be represented?
3. What equivalence relations should be standardized?
4. How should approximation contracts be represented?
5. How should lowering legality interact with capability interfaces?
6. How should lowering paths be selected optimally?
7. How should partial lowering be represented?
8. How should dynamic lowering interact with adaptive execution?
9. How should lowering provenance integrate with the Semantic Hypergraph?
10. How should semantic contracts survive aggressive optimization?
11. How should lowering handle intentionally lossy representations?
12. How should distributed lowering express consistency guarantees?
13. How should hardware-specific assumptions be represented?
14. How should lowering interact with formal verification?
15. How should multiple independently lowered representations be reconciled?

These questions MUST NOT be resolved implicitly by implementation.

---

# Definition History

## 0.1.0

Initial normative semantic definition.

Establishes Lowering as the semantic process of moving computation toward progressively more concrete realization levels while preserving declared meaning and explicitly representing approximation, assumptions, and changed guarantees.

---

# Definition Authority

This document is the normative semantic authority for `SCR-LIB-LOWERING`.

MLIR dialects, conversion passes, compiler backends, provider implementations, hardware targets, and runtime mechanisms MUST conform to the semantic lowering contracts established here.

---

# Definition Principle

> **Lowering is the semantics-preserving descent from computational meaning toward executable realization. It may change representation, abstraction, algorithm, memory model, execution strategy, provider, and hardware target, but it MUST NOT silently change what the computation means.**
> :::writing_end::
