# Semantic Computational Runtime

## Core Semantic Invariants

**Document:** `SCR-SEMANTIC-INVARIANTS`
**Status:** Foundational Specification
**Version:** 1.0
**Scope:** Core Semantic Model

---

# 1. Purpose

This document defines the invariants that govern the meaning of the Semantic Computational Runtime (SCR).

These invariants are more fundamental than individual APIs, dialects, implementations, providers, optimizations, or execution targets.

An implementation is considered conformant to SCR only if it preserves these invariants wherever they are applicable.

The central principle is:

> **Implementation freedom must never come at the cost of semantic integrity.**

---

# 2. What Is an Invariant?

An invariant is a property that must remain true across a transformation or change of realization.

For example:

```text
Semantic Program
      │
      ▼
Optimization
      │
      ▼
Representation Change
      │
      ▼
Provider Selection
      │
      ▼
Hardware Lowering
```

may change:

```text
representation
algorithm
memory layout
execution device
provider
parallelization
schedule
```

but must preserve the semantic invariants.

Therefore:

```text
Meaning
  ──────────────────────────────────────►
  must remain invariant
```

while:

```text
Implementation
  ──────────────────────────────────────►
  may change
```

---

# 3. Invariant Hierarchy

SCR invariants are organized into six categories:

```text
I.   Meaning
II.  Structure
III. Composition
IV.  Transformation
V.   Realization
VI.  Execution
```

The hierarchy is:

```text
                    SEMANTIC MEANING
                           │
                    ┌──────┴──────┐
                    ▼             ▼
                STRUCTURE     COMPOSITION
                    │             │
                    └──────┬──────┘
                           ▼
                     TRANSFORMATION
                           │
                           ▼
                       REALIZATION
                           │
                           ▼
                       EXECUTION
```

Higher-level invariants constrain everything below them.

---

# 4. I — Meaning Invariants

## SI-001 — Semantic Primacy

**Statement**

The semantic meaning of a construct is authoritative over its representation, implementation, provider, or execution target.

```text
Meaning > Representation > Implementation
```

A provider must implement a semantic contract.

It must not redefine that contract.

### Consequence

The following are not semantic authorities:

* library APIs;
* data structures;
* hardware APIs;
* programming-language syntax;
* provider-specific behavior.

---

# 5. SI-002 — Meaning Independence

A semantic concept must be definable without requiring knowledge of a particular implementation technology.

Valid:

```text
physics.integrate
```

Invalid as a semantic definition:

```text
physics.integrate_using_chrono()
```

The latter is an implementation choice.

---

# 6. SI-003 — Identity Preservation

A semantic entity retains its identity across valid changes of representation.

```text
Entity A
   │
   ├── mesh
   ├── voxel
   ├── implicit
   └── particle
```

These may all represent the same semantic entity.

Changing representation must not implicitly create a new semantic identity.

---

# 7. SI-004 — Type Meaning Preservation

A transformation must not silently change the semantic type of a value.

For example:

```text
Length
```

cannot silently become:

```text
Time
```

merely because both happen to be represented as floating-point numbers.

Physical dimensions, semantic types and constraints are part of meaning.

---

# 8. SI-005 — Dimensional Consistency

Where dimensional semantics apply, valid operations must preserve dimensional correctness.

For example:

```text
velocity = distance / time
```

is valid.

```text
velocity = distance + time
```

is not.

Dimensional correctness should be verified mechanically whenever possible.

---

# 9. SI-006 — Constraint Preservation

A valid semantic transformation must preserve all constraints that are part of the semantic contract.

Examples:

```text
mass > 0
topology valid
coordinate systems compatible
conservation law satisfied
state transition valid
```

An optimization cannot remove a constraint merely because it makes execution easier.

---

# 10. SI-007 — Contract Preservation

Every valid implementation of a semantic operation must satisfy its semantic contract.

If:

```text
A
```

is a semantic operation with contract:

```text
C
```

then every valid provider must implement:

```text
Provider(A) ⊨ C
```

Provider-specific extensions may exist, but they cannot invalidate the common contract.

---

# 11. SI-008 — Information Semantics

A transformation must not claim lossless equivalence when information has been discarded.

For example:

```text
Field
   ↓ sampling
Samples
```

is not automatically equivalent to the original field.

The transformation must declare whether it is:

```text
lossless
lossy
approximate
bounded-error
projective
aggregating
```

---

# 12. SI-009 — Explicit Approximation

Approximation must be explicit.

A system must not silently replace:

```text
exact computation
```

with:

```text
approximate computation
```

without the semantic contract permitting it.

Where possible, approximation should specify:

```text
error bounds
precision
confidence
validity range
```

---

# 13. II — Structural Invariants

## SI-010 — Explicit Structure

Semantic relationships must be representable explicitly when they affect meaning.

Examples:

```text
body interacts-with body
agent observes field
controller controls system
geometry belongs-to object
state evolves-under dynamics
```

Important relationships must not exist solely as undocumented implementation assumptions.

---

# 14. SI-011 — Relationship Integrity

If a relationship is part of semantic meaning, valid transformations must preserve that relationship or explicitly transform it into another semantically valid relationship.

For example:

```text
A adjacent-to B
```

cannot simply disappear during representation conversion if adjacency is semantically required.

---

# 15. SI-012 — State Integrity

A stateful semantic object must maintain a valid state representation across transitions.

```text
S₀ → S₁ → S₂ → ...
```

Every valid transition must satisfy the object's state contract.

---

# 16. SI-013 — State Transition Integrity

A state transition must preserve the semantics of the transition law.

If:

```text
S₁ = f(S₀)
```

then optimization may change how `f` is computed, but not what transition `f` represents.

---

# 17. SI-014 — Context Integrity

Semantic interpretation must preserve relevant context.

Context may include:

```text
space
time
coordinate system
reference frame
environment
scenario
state
observer
```

An operation must not silently discard context required for correct interpretation.

---

# 18. SI-015 — Spatial Integrity

Spatial semantics must preserve applicable spatial relationships.

Examples:

```text
distance
orientation
adjacency
containment
intersection
neighbourhood
coordinate frame
```

Changing spatial representation must not silently change these relationships.

---

# 19. SI-016 — Temporal Integrity

Temporal semantics must be preserved.

This includes distinctions between:

```text
continuous
discrete
event-driven
periodic
logical
wall-clock
simulation time
```

A compiler must not treat temporal semantics as interchangeable merely because the implementation can represent them using the same numeric type.

---

# 20. SI-017 — Topological Integrity

Where topology is part of a semantic contract, transformations must preserve the required topological properties.

Examples:

```text
connectivity
boundary
orientation
manifoldness
adjacency
genus
```

A geometric optimization that changes topology is therefore not automatically semantics-preserving.

---

# 21. SI-018 — Morphological Integrity

Where morphology is part of the semantic model, representation changes must preserve the declared morphological properties.

For example:

```text
shape
structure
branching
volume
surface
deformation
```

must remain consistent with the contract.

A mesh, voxel and implicit representation are interchangeable only to the extent that they preserve the required morphology.

---

# 22. III — Composition Invariants

## SI-019 — Compositionality

Valid semantic operations must be composable whenever their contracts are compatible.

If:

```text
A → B
```

and:

```text
B → C
```

are valid, SCR should be able to represent:

```text
A → B → C
```

as a semantic composition.

---

# 23. SI-020 — Composition Closure

Where a composition is semantically valid, the composition itself is a valid semantic object.

```text
A
+
B
+
C
   ↓
Composition(A,B,C)
```

The composition may subsequently be:

* analyzed;
* transformed;
* optimized;
* represented;
* provided;
* executed.

This is essential to higher-order semantics.

---

# 24. SI-021 — Higher-Order Closure

A composition may itself become an operation.

For example:

```text
sample
→ interact
→ integrate
→ transition
```

may become:

```text
agent.propagate
```

and:

```text
agent.propagate
+
population
```

may become:

```text
population.evolve
```

There is no fixed limit to semantic composition depth.

---

# 25. SI-022 — Contract Compatibility

Two operations may compose only when their contracts are compatible.

Compatibility may involve:

```text
type
dimension
space
time
capability
constraint
effect
representation
```

The compiler must detect incompatible compositions rather than relying on runtime failure where static verification is possible.

---

# 26. SI-023 — Capability Compatibility

Composition should depend on capabilities rather than implementation inheritance.

For example:

```text
Operation A requires Differentiable
```

may accept any implementation satisfying:

```text
Differentiable
```

regardless of its provider or representation.

---

# 27. SI-024 — No Accidental Coupling

A semantic composition must not require unrelated implementation details.

For example:

```text
physics → rendering
```

should not require:

```text
physics → VulkanSceneGraph API
```

unless that dependency is explicitly part of a provider implementation.

---

# 28. SI-025 — Abstraction Closure

A semantic abstraction may contain arbitrary valid semantic compositions without losing semantic validity.

This permits:

```text
operation
→ composition
→ higher-order operation
→ domain model
→ system
```

without requiring a different semantic mechanism at each level.

---

# 29. IV — Transformation Invariants

## SI-026 — Semantic Preservation

Every semantics-preserving transformation must preserve the semantic contract of the input.

```text
P ≡ T(P)
```

where `≡` denotes the applicable semantic equivalence relation.

---

# 30. SI-027 — Transformation Transparency

A transformation must not silently introduce semantic behavior that was not permitted by the original contract.

Examples:

```text
fusion
tiling
vectorization
parallelization
```

may change execution strategy.

They must not silently change observable semantics.

---

# 31. SI-028 — Representation Independence

A semantic operation must not depend on a particular representation unless that representation is explicitly part of its contract.

Therefore:

```text
Field
```

does not inherently mean:

```text
dense array
```

and:

```text
Morphology
```

does not inherently mean:

```text
mesh
```

---

# 32. SI-029 — Representation Substitutability

Two representations may substitute for one another when they satisfy the same required semantic contract.

```text
Representation A
        │
        │ satisfies contract C
        ▼
Representation B
        │
        │ satisfies contract C
        ▼
Substitutable
```

The compiler may therefore select representations based upon execution requirements.

---

# 33. SI-030 — Refinement Preservation

Refining a semantic construct must preserve its original meaning.

```text
A
↓ refinement
A₁ + A₂ + A₃
```

must collectively implement the semantics of `A`.

---

# 34. SI-031 — Abstraction Preservation

Abstracting a composition into a higher-order semantic operation must preserve the semantics of the composition.

```text
A → B → C
```

may become:

```text
D
```

only if:

```text
D ≡ A → B → C
```

under the applicable contract.

---

# 35. SI-032 — Canonicalization Preservation

Canonicalization may alter representation but must not alter semantic meaning.

Canonicalization exists to make equivalent structures easier to recognize and optimize.

---

# 36. SI-033 — Fusion Preservation

Operation fusion must preserve the observable semantic behavior of the unfused operations.

```text
A → B
```

may become:

```text
fused(A,B)
```

only when the fused operation satisfies the same contract.

---

# 37. SI-034 — Parallelization Preservation

An operation may be parallelized only when its dependencies and effects permit the transformation.

Parallel execution must preserve applicable:

```text
ordering
state
determinism
data dependencies
side effects
```

---

# 38. SI-035 — Distribution Preservation

Distributed execution must preserve the semantic contract of the original computation.

Partitioning a semantic object does not change its identity or meaning.

```text
Object
  ↓
Partition
  ├── P₁
  ├── P₂
  └── P₃
```

The partitions collectively represent the original semantic object.

---

# 39. SI-036 — Optimization Preservation

An optimization is valid only if it preserves the applicable semantic equivalence relation.

Performance improvement alone is not sufficient.

```text
faster ≠ correct
```

Correctness is established against semantic meaning.

---

# 40. SI-037 — Differentiation Semantics

Where an operation declares differentiability, transformations involving differentiation must preserve the declared mathematical semantics.

Automatic differentiation is therefore a semantic transformation, not merely a framework feature.

---

# 41. V — Realization Invariants

## SI-038 — Provider Independence

The semantic model must remain independent of any particular provider.

Providers are replaceable implementations of semantic contracts.

```text
Semantic Operation
       │
 ┌─────┼─────┐
 ▼     ▼     ▼
 P₁    P₂    P₃
```

---

# 42. SI-039 — Provider Substitutability

Providers satisfying the same semantic contract must be substitutable within the contract's permitted equivalence class.

Differences may exist in:

```text
performance
precision
resource usage
parallelism
numerical error
```

but these differences must be explicitly represented where they affect semantic guarantees.

---

# 43. SI-040 — Hardware Independence

Semantic programs must not require knowledge of concrete execution hardware unless hardware-specific behavior is explicitly part of the semantic contract.

Applications should express:

```text
intent
requirements
constraints
capabilities
```

rather than:

```text
GPU kernel launch
CPU thread count
memory address
```

---

# 44. SI-041 — Hardware Capability Matching

Hardware selection must be based on compatibility between:

```text
semantic requirements
```

and:

```text
execution capabilities
```

not on hard-coded application assumptions.

---

# 45. SI-042 — Execution Strategy Independence

A semantic program must not depend on one fixed execution strategy.

Valid implementations may use:

```text
serial
parallel
vectorized
tiled
GPU
distributed
asynchronous
streaming
```

where the semantic contract permits them.

---

# 46. SI-043 — Memory Representation Independence

Logical semantic data must remain distinct from physical memory layout.

The compiler may choose:

```text
AoS
SoA
tiled
packed
sparse
dense
device-local
distributed
```

without changing semantic meaning.

---

# 47. SI-044 — Resource Independence

Semantic meaning must not depend on accidental availability of a particular resource.

If a preferred provider or device is unavailable, another valid realization may be selected.

---

# 48. VI — Execution Invariants

## SI-045 — Execution Correctness

Execution must satisfy the semantic contract of the compiled program.

A successful kernel launch is not evidence of semantic correctness.

Correctness is defined against the semantic model.

---

# 49. SI-046 — Observable Equivalence

Where two implementations claim semantic equivalence, their observable results must satisfy the applicable equivalence relation.

Observability may include:

```text
output values
state transitions
events
relationships
side effects
rendered results
stream contents
```

---

# 50. SI-047 — Determinism Preservation

If an operation declares deterministic semantics, an implementation must preserve those semantics within the declared numerical or observational tolerance.

If nondeterminism is permitted, it must be explicitly declared.

---

# 51. SI-048 — Stochastic Semantics

Stochastic operations must preserve their declared probability semantics.

If reproducibility is required, the relevant random seed/state must be represented explicitly.

---

# 52. SI-049 — Temporal Execution Correctness

Real-time or temporal contracts must preserve required temporal guarantees.

Examples:

```text
deadline
latency bound
ordering
sampling frequency
simulation timestep
```

Performance optimization cannot violate a declared temporal contract.

---

# 53. SI-050 — Failure Semantics

Failure must not silently become successful semantic execution.

Provider failures, resource failures and semantic failures must remain distinguishable.

For example:

```text
invalid physics state
```

is different from:

```text
GPU unavailable
```

and different from:

```text
network provider failure
```

---

# 54. SI-051 — Observability

Where execution telemetry is exposed as semantic/runtime information, it must accurately describe the execution that occurred.

Examples:

```text
execution time
memory usage
device
kernel
data transfer
queue latency
```

Telemetry must not be confused with semantic output.

---

# 55. SI-052 — Feedback Safety

Runtime feedback may change:

```text
provider
representation
schedule
device
kernel
partitioning
```

but must not alter semantic intent without an explicit semantic transformation.

---

# 56. Cross-Cutting Invariants

## SI-053 — No Hidden Semantic State

Semantically relevant state must not exist solely inside an opaque provider if the state affects observable semantics.

If the state affects meaning, it must be representable at the semantic level.

---

# 57. SI-054 — Explicit Side Effects

Observable side effects must be represented explicitly where they affect ordering or correctness.

Examples:

```text
state mutation
message emission
event generation
external observation
resource interaction
```

This enables valid compiler transformations.

---

# 58. SI-055 — Provenance Preservation

Where provenance is part of a semantic contract, transformations must preserve sufficient provenance information.

For example:

```text
measurement
   ↓
derived field
   ↓
simulation
   ↓
prediction
```

must remain traceable when provenance is required.

---

# 59. SI-056 — Uncertainty Preservation

If uncertainty is part of a semantic value, transformations must preserve or correctly transform the uncertainty representation.

For example:

```text
distribution
```

cannot silently become:

```text
deterministic scalar
```

without an explicit semantic projection.

---

# 60. SI-057 — Precision Awareness

Numerical precision is part of semantics whenever it affects correctness.

The system must distinguish between:

```text
required precision
preferred precision
available precision
```

An implementation may use lower precision only when the semantic contract permits it.

---

# 61. SI-058 — Semantic Monotonicity

Adding implementation information must not invalidate previously established semantic facts.

For example:

```text
Field
```

may later become:

```text
SpatialField
```

and then:

```text
GPUResidentSpatialField
```

without invalidating the original field semantics.

Additional information refines semantics.

It must not contradict them.

---

# 62. SI-059 — Capability Monotonicity

A refinement may add capabilities but must not falsely remove capabilities already guaranteed by the contract.

For example:

```text
Differentiable
```

must not disappear merely because the representation changes.

If differentiation becomes impossible, the transformation must explicitly establish why the semantic contract has changed.

---

# 63. SI-060 — Semantic Locality

A semantic concept should contain only the meaning necessary to describe that concept.

Implementation concerns must not leak upward unnecessarily.

For example:

```text
Field
```

should not intrinsically contain:

```text
CUDA stream
Vulkan descriptor
malloc address
MPI communicator
```

unless those are explicitly part of a lower execution representation.

---

# 64. SI-061 — Domain Integrity

Domain-specific semantics must remain meaningful.

Generalization must not erase domain-specific invariants.

For example:

```text
physics.force
```

must retain physical meaning even though it may implement generic interfaces such as:

```text
VectorValued
Spatial
Transformable
```

Generic interfaces supplement domain semantics.

They do not replace them.

---

# 65. SI-062 — Interface Stability

Interfaces represent semantic contracts and therefore require stronger stability guarantees than ordinary implementation APIs.

Changing an interface may affect:

```text
composition
providers
transformations
lowerings
bindings
```

Interface changes must therefore be treated as semantic changes.

---

# 66. SI-063 — Interface Minimality

A semantic interface should contain only the contract necessary to express the capability.

Do not place unrelated implementation requirements into an interface.

Prefer:

```text
Differentiable
```

over:

```text
DifferentiableAndGPUResidentAndTensorBacked
```

unless those properties genuinely form one semantic capability.

---

# 67. SI-064 — No Duplicate Semantics

Two concepts representing the same semantic meaning must not be introduced merely because they originate in different domains.

If an existing concept is sufficient:

```text
reuse
```

rather than:

```text
duplicate
```

This is essential to preventing semantic fragmentation.

---

# 68. SI-065 — Semantic Generalization

When the same semantic structure appears independently in multiple domains, the system should evaluate whether it belongs in the shared semantic vocabulary.

Examples:

```text
state
transition
observation
composition
transformation
capability
constraint
```

---

# 69. SI-066 — Semantic Specialization

General concepts must be refinable into domain-specific concepts without breaking their underlying semantics.

For example:

```text
State
 ↓
PhysicalState
 ↓
RigidBodyState
```

The specialized concept retains the semantics of the general concept.

---

# 70. SI-067 — No Implementation Leakage

Implementation-specific concepts must not become semantic primitives unless they have independent semantic meaning.

For example:

```text
CUDAKernel
```

is generally an execution concept.

It should not become a fundamental semantic concept merely because CUDA happens to be a provider.

---

# 71. SI-068 — MLIR Consistency

SCR semantic constructs must use MLIR's semantic mechanisms wherever those mechanisms are applicable.

SCR must not create parallel mechanisms for:

```text
types
operations
regions
interfaces
attributes
verification
rewriting
transformation
serialization
```

unless a concrete architectural requirement demonstrates that MLIR cannot express the required semantics.

---

# 72. SI-069 — Single Semantic Representation

There must be one authoritative semantic representation.

That representation is:

```text
MLIR + SCR semantic dialects
```

Other representations are:

```text
source representations
derived representations
lowered representations
runtime representations
```

They are not competing semantic authorities.

---

# 73. SI-070 — Lowering Is Not Meaning Change

Lowering may reduce semantic information when that information is no longer required by downstream stages.

However, it must not change required observable semantics.

Conceptually:

```text
High-Level SCR Semantic MLIR
        ↓
Lower-Level SCR Semantic MLIR
```

is a change in representation.

It is not a license to change meaning.

---

# 74. SI-071 — Information Preservation Until Necessary

Semantic information should be retained as long as it provides value to:

* verification;
* optimization;
* representation selection;
* scheduling;
* provider selection;
* hardware mapping.

Premature destruction of semantic information is prohibited where it prevents valid downstream reasoning.

---

# 75. SI-072 — Semantic Irreversibility Must Be Explicit

If lowering or transformation permanently discards semantic information, that loss must be explicit.

Examples:

```text
continuous field
→ sampled field

full precision
→ quantized value

3D scene
→ 2D projection
```

The resulting object has different semantic information.

The system must represent that distinction.

---

# 76. SI-073 — Compilation Must Be Semantics-Preserving

The compiler may:

```text
reorder
fuse
split
tile
vectorize
parallelize
specialize
distribute
lower
```

but the resulting computation must satisfy the original semantic contract.

---

# 77. SI-074 — Runtime Must Respect Compilation Contracts

The runtime may adapt execution strategy but may not violate assumptions established by compilation.

If compiled under:

```text
deterministic
```

semantics, runtime scheduling must respect the corresponding guarantees.

If compiled under:

```text
FP64 required
```

the runtime cannot silently dispatch to incompatible precision.

---

# 78. SI-075 — Provider Claims Must Be Verifiable

A provider claiming:

```text
Dynamical
Differentiable
Deterministic
Parallelizable
```

must satisfy the corresponding interface contracts.

Capabilities are claims about behavior, not labels.

---

# 79. SI-076 — Semantic Errors Are First-Class

Invalid semantic programs should be rejected as early as practical.

Examples:

```text
invalid composition
invalid dimensions
invalid topology
missing capability
violated physical constraint
invalid state transition
```

The compiler should prefer detecting these before execution.

---

# 80. SI-077 — Error Preservation

A transformation must not turn a semantically invalid program into a valid-looking program by silently discarding the information that made it invalid.

For example:

```text
invalid dimensions
```

must not disappear merely because both operands are stored as `f64`.

---

# 81. SI-078 — Observational Boundary

Semantic equivalence is defined according to what the relevant consumer is permitted to observe.

For one consumer:

```text
exact floating-point value
```

may matter.

For another:

```text
within tolerance
```

may be sufficient.

For rendering:

```text
visually equivalent
```

may be meaningful.

Therefore equivalence must be contract-specific rather than universally binary.

---

# 82. SI-079 — Consumer-Driven Representation

Representation should be selected according to semantic and execution requirements of consumers.

For example:

```text
Morphology
 ├── Simulation → implicit
 ├── Collision  → BVH
 ├── Rendering  → mesh
 └── Spatial    → voxel/H3
```

One semantic object may therefore have multiple derived representations.

---

# 83. SI-080 — Semantic Single Source of Truth

Derived representations must not become competing authorities for semantic state unless explicitly promoted by a synchronization contract.

Conceptually:

```text
Semantic State
   ├── Representation A
   ├── Representation B
   └── Representation C
```

The representations derive from the semantic state.

They must not silently diverge.

---

# 84. The Fundamental Invariant

All previous invariants reduce to one central principle:

> **Any valid change in representation, implementation, provider, optimization, compilation strategy, or execution resource must preserve the semantic contract unless the change is explicitly defined as a semantic transformation.**

Formally:

```text
                         SEMANTIC CONTRACT
                               │
             ┌─────────────────┼─────────────────┐
             ▼                 ▼                 ▼
       Representation      Provider          Hardware
             │                 │                 │
             └─────────────────┼─────────────────┘
                               ▼
                         Implementation
                               │
                               ▼
                           Execution
```

All paths must remain constrained by the semantic contract.

---

# 85. Invariant Priority

When invariants conflict, priority is:

```text
1. Semantic correctness
2. Contract correctness
3. Type / dimensional correctness
4. Structural correctness
5. Composition correctness
6. Transformation correctness
7. Numerical guarantees
8. Resource constraints
9. Performance
10. Implementation convenience
```

Performance never outranks semantic correctness.

Implementation convenience never outranks semantic correctness.

---

# 86. Optimization Principle

The compiler is free to optimize aggressively **inside the semantic boundary**.

Therefore:

```text
semantic correctness
        +
implementation freedom
        =
optimization freedom
```

The stronger the semantic contracts, the more freedom the compiler has to optimize safely.

Weak semantics force conservative implementations.

Strong semantics enable aggressive transformations.

---

# 87. Agent Development Rule

Any agent modifying SCR must classify its change against these invariants.

Before implementation, the agent must identify:

```text
Affected semantic concepts
Affected interfaces
Affected invariants
Affected contracts
Affected compositions
Affected transformations
```

A change that violates an invariant must either:

1. be rejected; or
2. explicitly propose a change to the invariant itself.

Agents must not silently weaken semantic guarantees.

---

# 88. Implementation Review Questions

Every semantic implementation should be reviewable through these questions:

### Meaning

What does this construct mean independently of implementation?

### Identity

What remains the same when representation changes?

### Contract

What must always be true?

### Capability

What can this construct participate in?

### Composition

What can it compose with?

### Representation

Which representations are valid?

### Provider

Which implementations may provide it?

### Transformation

Which transformations preserve its meaning?

### Equivalence

When can two implementations be considered equivalent?

### Verification

Which invariants can be checked mechanically?

### Execution

What execution strategies are valid?

---

# 89. Minimum Invariant Set

The following constitute the **irreducible core** of SCR.

If the project needs an absolute minimum set to govern early development, these should be non-negotiable:

```text
SI-001  Semantic Primacy
SI-003  Identity Preservation
SI-006  Constraint Preservation
SI-007  Contract Preservation
SI-019  Compositionality
SI-020  Composition Closure
SI-022  Contract Compatibility
SI-026  Semantic Preservation
SI-028  Representation Independence
SI-038  Provider Independence
SI-040  Hardware Independence
SI-046  Observable Equivalence
SI-068  MLIR Consistency
SI-069  Single Semantic Representation
SI-073  Compilation Must Be Semantics-Preserving
SI-075  Provider Claims Must Be Verifiable
SI-080  Semantic Single Source of Truth
```

These should be treated as the **constitutional invariants** of the project.

---

# 90. Constitutional Principle

The Semantic Computational Runtime can be understood as having a constitution:

```text
                 SEMANTIC MEANING
                       │
                       │
             ┌─────────▼─────────┐
             │ SEMANTIC CONTRACT │
             └─────────┬─────────┘
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
     Composition   Transformation  Realization
          │            │            │
          └────────────┼────────────┘
                       ▼
                    Execution
```

Everything below the semantic contract is negotiable.

The semantic contract is not.

---

# 91. Final Definition

The core semantic invariant of SCR is:

> **A computational meaning, once established by a valid semantic contract, must survive every valid composition, refinement, abstraction, representation change, optimization, provider substitution, lowering, scheduling decision and hardware mapping, unless an explicit semantic transformation changes that meaning under a declared contract.**

That is the foundation on which the entire Semantic Library can safely grow.
