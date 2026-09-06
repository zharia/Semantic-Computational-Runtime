# Numeric Execution

**Document:** `docs/NUMERIC_EXECUTION.md`
**Version:** 1.0.0
**Status:** Foundational / Normative Implementation Guidance
**Scope:** MLIR, compiler, provider, runtime, storage, transport, and hardware realisation of SCR Numeric Semantics

---

# 1. Purpose

This document defines how the numeric semantics established by:

```text
005_NUMERIC_SEMANTICS.md
```

are realised through the SCR execution architecture.

It covers:

* MLIR representation;
* numeric attributes and metadata;
* numeric operations;
* normalization;
* quantization;
* dequantization;
* representation conversion;
* precision propagation;
* error propagation;
* compiler analysis;
* compiler transformations;
* memory representation;
* storage representation;
* transport representation;
* provider selection;
* hardware-aware execution;
* mixed precision;
* runtime adaptation;
* validation and testing.

This document defines **execution mechanisms**.

It does not redefine the semantic meaning of numerical quantities.

The governing relationship is:

```text
005_NUMERIC_SEMANTICS.md
        ↓
Semantic Requirements
        ↓
This Document
        ↓
MLIR Representation
        ↓
Compiler Analysis / Transformation
        ↓
Provider
        ↓
Runtime
        ↓
Hardware
```

---

# 2. Architectural Rule

SCR shall not create a second numeric representation system outside MLIR.

The execution architecture shall use:

* MLIR builtin types;
* MLIR dialect types;
* MLIR attributes;
* MLIR operations;
* MLIR interfaces;
* MLIR traits;
* MLIR analyses;
* MLIR passes;
* MLIR conversion infrastructure;
* MLIR lowering infrastructure.

SCR-specific mechanisms shall extend MLIR rather than establish a parallel compiler architecture.

---

# 3. Execution Principle

The implementation objective is:

> **Represent the semantic numeric requirements in MLIR sufficiently for the compiler and runtime to select an efficient physical representation without changing semantic meaning.**

The implementation must therefore preserve the distinction:

```text
Semantic Numeric Type
        ↓
MLIR Semantic Representation
        ↓
Physical Numeric Representation
        ↓
Machine Representation
```

A physical type such as `f32` or `i8` is not itself the semantic type.

---

# 4. Numeric Execution Model

The complete execution model is:

```text
Semantic Value
      ↓
Semantic Numeric Requirements
      ↓
MLIR Representation
      ↓
Numeric Analysis
      ↓
Range Analysis
      ↓
Precision Analysis
      ↓
Error Analysis
      ↓
Representation Candidates
      ↓
Cost Analysis
      ↓
Representation Selection
      ↓
MLIR Transformation
      ↓
Provider Lowering
      ↓
Hardware Execution
```

The selected representation must satisfy semantic constraints before performance considerations are applied.

---

# 5. Canonical Computational Representation

SCR establishes `f32` as the default canonical general-purpose real-valued computational representation.

The implementation should therefore use `f32` as the default when:

* no stronger precision requirement exists;
* no lower-precision representation has been proven sufficient;
* no provider-specific optimisation justifies another representation.

This is a **default**, not an unconditional physical representation requirement.

The compiler may select:

```text
f64
f32
f16
bf16
integer
fixed-point
```

or another representation when semantic requirements permit it.

---

# 6. MLIR Type Mapping

The initial implementation should prefer MLIR builtin types wherever they are sufficient.

Examples include:

```text
f64
f32
f16
bf16

i64
i32
i16
i8

index
complex<T>
```

SCR shall not introduce a wrapper type merely to rename an existing MLIR numeric type.

A SCR-specific type is justified only where additional semantic information is required that cannot appropriately be represented through existing MLIR mechanisms.

---

# 7. Semantic Numeric Metadata

Semantic numeric requirements should be represented through MLIR attributes and, where appropriate, dialect-specific attributes.

Potential metadata includes:

```text
domain
range
units
normalization
precision requirement
error budget
quantization parameters
rounding mode
saturation mode
zero point
scale
offset
validity
determinism
```

Conceptually:

```text
NumericSemanticsAttr {
    domain
    range
    units
    precision
    error_budget
    representation_constraints
}
```

This is a conceptual model.

The concrete implementation should use the smallest appropriate MLIR mechanism.

---

# 8. Prefer Existing MLIR Mechanisms

Before introducing an SCR-specific mechanism, implementation must evaluate:

1. MLIR builtin type;
2. MLIR builtin attribute;
3. existing MLIR dialect;
4. existing MLIR interface;
5. existing MLIR trait;
6. MLIR analysis;
7. MLIR pattern rewrite;
8. MLIR conversion framework;
9. MLIR pass infrastructure;
10. SCR dialect extension.

The following are prohibited:

```text
SCR Numeric IR
SCR Numeric AST
SCR Numeric SSA
SCR Numeric Graph
parallel numeric type system
```

---

# 9. Semantic Representation of Ranges

Range information should be represented explicitly where known.

Examples:

```text
[-1,+1]
[0,1]
[0,+∞)
(-∞,+∞)
```

Range information may be:

* static;
* symbolic;
* inferred;
* conservatively bounded;
* dynamically constrained.

Range analysis should preserve uncertainty rather than inventing false precision.

---

# 10. Normalization Operations

Normalization should be represented as explicit semantic operations when it is computationally relevant.

Conceptually:

```text
scr.numeric.normalize
```

may express:

```text
source domain
target domain
normalization parameters
```

For example:

```text
[a,b] → [-1,+1]
```

may be represented by an operation carrying:

```text
source_min = a
source_max = b
target_min = -1
target_max = +1
```

The operation should remain amenable to:

* constant folding;
* fusion;
* canonicalisation;
* elimination;
* algebraic simplification.

---

# 11. Quantization Operations

Quantization shall be represented explicitly where it is semantically relevant.

Conceptually:

```text
scr.numeric.quantize
```

shall express:

```text
source domain
target representation
scale
offset
zero point
rounding
saturation
error characteristics
```

For example:

```text
[-1,+1] → i8
```

shall not be represented merely as an opaque cast.

The compiler must be able to determine that information has been intentionally discarded.

---

# 12. Dequantization Operations

The inverse operation shall likewise remain visible:

```text
scr.numeric.dequantize
```

or an equivalent MLIR representation.

The compiler may subsequently fuse or eliminate the operation.

The semantic transformation must remain recoverable during analysis.

---

# 13. Numeric Casts

Ordinary lossless casts may use appropriate MLIR conversion mechanisms.

Examples:

```text
i16 → i32
f32 → f64
```

Lossy casts require stronger semantic visibility.

Examples:

```text
f32 → f16
f32 → i16
f32 → i8
```

These should not be represented merely as implementation-level casts when doing so hides semantic loss.

---

# 14. Saturating Conversion

Where a conversion is semantically defined as saturating, the implementation shall use or lower to a representation that preserves saturation semantics.

The compiler must distinguish:

```text
saturating conversion
```

from:

```text
wrapping conversion
```

These are not interchangeable.

---

# 15. Rounding Representation

Rounding mode shall be represented explicitly where it affects semantic behaviour.

Supported modes should include:

```text
nearest-even
nearest-away
toward-zero
floor
ceil
stochastic
```

The default is:

```text
nearest-even
```

The compiler may fold a rounding operation only when the transformation preserves its semantics.

---

# 16. Invalid Value Handling

Conversions involving:

```text
NaN
+∞
-∞
```

must obey the semantic policy declared by the source operation or numeric type.

The default platform behaviour is:

```text
NaN → invalid
+∞ → positive saturation
-∞ → negative saturation
```

Provider-specific behaviour must not silently override this policy.

---

# 17. Precision Requirements

Precision requirements should be represented independently of physical type where possible.

For example:

```text
required precision:
    f32-equivalent
```

is conceptually different from:

```text
physical representation:
    f32
```

A computation may require `f32` precision while permitting:

```text
storage = i8
```

or:

```text
operand representation = f16
accumulation = f32
```

---

# 18. Error Budget Representation

Where a computation has an explicit tolerance, it should be represented as semantic metadata.

Conceptually:

```text
ErrorBudgetAttr {
    max_absolute_error
    max_relative_error
    accumulated_error
    metric
}
```

The compiler may then use this information to determine whether reduced precision is admissible.

---

# 19. Range Analysis

Numeric representation optimisation depends heavily on range analysis.

The compiler should determine, where possible:

```text
minimum
maximum
zero-crossing
sign
monotonicity
boundedness
```

For example:

```text
x ∈ [-1,+1]
```

provides much stronger quantization opportunities than:

```text
x ∈ (-∞,+∞)
```

Range information may be derived from:

* constants;
* operation semantics;
* attributes;
* control flow;
* domain constraints;
* known mathematical properties;
* upstream ranges.

---

# 20. Precision Analysis

Precision analysis should determine the minimum representation precision required by an operation and its downstream consumers.

Conceptually:

```text
Consumer Requirements
        ↑
Operation Requirements
        ↑
Input Requirements
```

The compiler should avoid promoting values beyond what the computational graph requires.

---

# 21. Error Propagation

When operations introduce numerical error, the compiler should track its effect where practical.

For:

```text
A → B → C
```

the analysis may determine:

```text
εA
εB
εC
```

and estimate:

```text
εtotal
```

according to the mathematical semantics of the operations involved.

A representation reduction is admissible only when:

```text
εtotal ≤ permitted_error
```

or when an equivalent domain-specific condition holds.

---

# 22. Representation Selection

Representation selection should be treated as a compiler optimisation problem.

Candidates may include:

```text
f64
f32
f16
bf16
i32
i16
i8
fixed-point
packed representations
```

The compiler should consider:

```text
semantic validity
range
precision
error
memory
bandwidth
conversion cost
provider capability
hardware capability
```

The objective is not maximum precision.

The objective is the **lowest-cost representation that satisfies semantic requirements**.

---

# 23. Cost Model

The numeric representation cost model should account for:

```text
bytes/value
memory footprint
memory bandwidth
cache pressure
conversion cost
vector width
SIMD utilisation
GPU throughput
accelerator throughput
host/device transfer
network transfer
serialization
power
```

Where reliable hardware information exists, the provider/runtime may supply cost estimates.

---

# 24. Conversion Cost

Conversions should be treated as computational costs.

The compiler should consider:

```text
f32 → f16
f16 → f32
f32 → i8
i8 → f32
```

as potentially non-free operations.

The optimal representation is therefore not necessarily the one with the smallest storage footprint if conversion overhead dominates.

---

# 25. Conversion Elimination

The compiler should eliminate unnecessary representation conversions.

Example:

```text
f32
 ↓
f16
 ↓
f32
```

should normally become:

```text
f32
```

unless the intermediate representation provides a measurable semantic or execution advantage.

Similarly:

```text
normalize
 ↓
quantize
 ↓
dequantize
```

may be simplified where the intermediate representation is not externally observable.

---

# 26. Conversion Fusion

Where possible, operations should be fused.

For example:

```text
normalize
 ↓
quantize
```

may be lowered directly into an appropriately scaled quantization operation.

Likewise:

```text
dequantize
 ↓
linear transform
```

may be fused into a single kernel.

Fusion must preserve:

* range;
* rounding;
* saturation;
* error;
* determinism.

---

# 27. Precision Promotion

Promotion should occur when required by:

* operation semantics;
* error budget;
* accumulation stability;
* downstream consumers;
* provider requirements.

Promotion should occur as late as practical and remain at the minimum required precision.

Example:

```text
i8 storage
   ↓
f32 computation
```

is preferable to converting an entire dataset to `f32` before the computation if only a subset requires promotion.

---

# 28. Precision Reduction

Precision reduction may occur when:

```text
required precision ≤ available precision
```

and:

```text
resulting error ≤ permitted error
```

Potential reductions include:

```text
f64 → f32
f32 → f16
f32 → bf16
f32 → i16
f32 → i8
```

Precision reduction shall be treated as a semantic transformation, not an arbitrary compiler cast.

---

# 29. Mixed Precision

SCR should support mixed-precision computation.

For example:

```text
operands:
    f16

accumulation:
    f32

output:
    f16
```

or:

```text
storage:
    i8

compute:
    f32

output:
    i8
```

Mixed precision is valid when the semantic error budget and operation requirements are satisfied.

---

# 30. Accumulation Precision

Reduction and accumulation operations should be analysed separately from operand precision.

For example:

```text
i8 × i8
```

does not imply:

```text
i8 accumulation
```

A provider may instead execute:

```text
i8 operands
    ↓
widen
    ↓
i32/f32 accumulation
```

depending on the semantic and numerical requirements.

Accumulation precision should be explicitly representable where it materially affects correctness.

---

# 31. SIMD and Vectorisation

Numeric representation should be selected with vector execution in mind.

The compiler should consider:

```text
elements/vector
vector register width
packing density
load/store bandwidth
conversion throughput
```

Reduced-width representations may improve vector density.

For example:

```text
f32:
    fewer elements/vector

f16:
    approximately twice the element density

i8:
    approximately four times the element density
```

Actual performance depends on hardware capabilities and must be determined through provider/hardware information.

---

# 32. GPU and Accelerator Execution

The representation selected for GPU or accelerator execution may differ from CPU representation.

Examples include:

```text
CPU:
    f32

GPU:
    f16

Storage:
    i8
```

The compiler should avoid unnecessary host/device conversions.

Where an accelerator natively supports a reduced-precision representation while satisfying semantic requirements, that representation should be considered strongly.

---

# 33. Memory Layout

Numeric representation optimisation must be considered together with memory layout.

Relevant factors include:

```text
AoS
SoA
AoSoA
contiguous arrays
strides
alignment
packing
tiling
sparsity
cache locality
```

Reducing element width without improving locality may not produce the expected performance benefit.

Conversely, a smaller representation may enable an entire working set to fit within a higher-level cache.

---

# 34. Working-Set Optimisation

Representation selection should consider the complete working set rather than individual buffers.

For example:

```text
10 GB × f32
```

may become:

```text
2.5 GB × i8
```

where semantic constraints permit.

This may change:

```text
cache residency
memory traffic
NUMA traffic
GPU residency
page movement
```

and therefore alter the optimal execution strategy.

---

# 35. Storage Representation

Persistent storage should use the minimum representation that preserves the declared semantic requirements.

The storage representation may differ from computation representation.

Example:

```text
persistent:
    i8

loaded:
    i8

compute:
    f32

persist:
    i8
```

The conversion should occur at explicit semantic boundaries.

---

# 36. Transport Representation

Network and messaging systems may use a representation different from both storage and computation.

For example:

```text
semantic signal:
    [-1,+1]

storage:
    i8

transport:
    i8

consumer compute:
    f32
```

Transport representation should be selected according to:

```text
error budget
bandwidth
latency
serialization cost
provider support
```

---

# 37. Zero-Copy and Representation Stability

The runtime should prefer representation stability when it avoids copies or conversions.

If two adjacent computational stages can operate on the same representation, the runtime should avoid conversion even if another representation is theoretically more compact.

The optimisation objective is global.

Smaller representation is not automatically better.

---

# 38. Representation Regions

Where beneficial, the compiler/runtime may establish regions of the computational graph that operate in a common representation.

For example:

```text
          i8
           │
      ┌────┴────┐
      │         │
      ▼         ▼
   Filter     Feature
      │         │
      └────┬────┘
           ▼
          f32
```

This can reduce repeated conversions.

Representation regions should be selected according to semantic and execution constraints.

---

# 39. Domain Boundaries

Cross-domain boundaries should not automatically trigger numeric conversion.

For example:

```text
Signal → Field
```

does not imply:

```text
i8 → f32
```

unless the receiving semantic operation requires it.

Domain interoperability should be based on semantic compatibility.

---

# 40. Provider Selection

Provider selection should include numeric capability.

A provider may advertise:

```text
supported representations
native precision
accumulation precision
quantization support
vector width
conversion cost
```

Conceptually:

```text
Semantic Requirement
        ↓
Numeric Requirements
        ↓
Provider Capabilities
        ↓
Hardware Capabilities
        ↓
Provider Selection
```

---

# 41. Provider Numeric Contracts

Providers shall declare their numeric capabilities.

Examples:

```text
supports_f32
supports_f16
supports_bf16
supports_i8
supports_i16
supports_saturating_quantization
supports_vectorized_f16
supports_mixed_precision
supports_f32_accumulation
```

Provider capability descriptions must not redefine semantic meaning.

---

# 42. Hardware Capability Discovery

Hardware information may include:

```text
native scalar types
SIMD widths
GPU formats
tensor formats
conversion throughput
memory bandwidth
cache sizes
accelerator availability
```

The runtime may use this information for representation selection.

Hardware discovery must remain separate from semantic definitions.

---

# 43. Runtime Adaptation

The runtime may adapt representation when:

```text
semantic constraints remain satisfied
```

and:

```text
execution efficiency improves.
```

For example, under memory pressure:

```text
f32 → f16
```

may be considered.

Under a precision-sensitive phase:

```text
f16 → f32
```

may be required.

Such changes should be explicit in runtime state and observable through telemetry where appropriate.

---

# 44. Runtime Telemetry

Numeric execution telemetry should be capable of reporting:

```text
representation used
conversion count
conversion volume
memory footprint
memory bandwidth
quantization operations
dequantization operations
precision promotions
precision reductions
provider
hardware
execution time
```

This permits the runtime to determine whether numeric optimisation is actually producing system-level benefit.

---

# 45. Avoiding Conversion Churn

A primary runtime optimisation target shall be conversion churn.

Bad:

```text
f32 → f16 → f32 → i8 → f32 → f16
```

without semantic necessity.

The compiler/runtime should seek:

```text
f32
```

or:

```text
f16
```

or:

```text
i8
```

across an appropriately sized execution region.

---

# 46. Quantization Boundaries

Quantization should normally occur at meaningful boundaries such as:

```text
storage
transport
memory pressure boundary
accelerator boundary
provider boundary
domain boundary
external API boundary
```

However, quantization may occur internally when it provides a verified computational advantage.

The compiler should not introduce quantization solely because a target type exists.

---

# 47. Dequantization Boundaries

Dequantization should occur only when required by:

* computation precision;
* provider capability;
* downstream semantic requirements;
* algorithmic stability.

If a downstream computation can operate directly on the quantized representation, dequantization should be avoided.

---

# 48. Example: Quantized Signal Pipeline

A signal pipeline may be represented conceptually as:

```text
Sensor
  │
  │ i16
  ▼
Storage
  │
  │ i16
  ▼
Filter
  │
  │ f32
  ▼
FFT
  │
  │ f32
  ▼
Feature Extraction
  │
  │ f16
  ▼
Classifier
  │
  │ i8
  ▼
Transport
```

The semantic signal remains unchanged.

Only the execution representations change.

---

# 49. Example: Large Normalized Field

Consider:

```text
10,000,000,000 values
domain = [0,1]
error ≤ 0.005
```

The compiler may determine that an 8-bit representation is sufficient.

The field may therefore remain quantized during:

```text
storage
memory residency
transport
```

and be promoted only at a computational boundary that requires greater precision.

The representation decision is derived from semantic requirements.

---

# 50. Example: Mixed-Precision Simulation

A simulation may use:

```text
position:
    f32

velocity:
    f32

mass:
    f16

force:
    f16

integration:
    f32 accumulation

persistent state:
    f16
```

The compiler should preserve higher precision only where required.

The runtime may maintain compact persistent state while using higher precision during numerically sensitive operations.

---

# 51. Example: Rendering

A semantic value may follow:

```text
Simulation:
    f32

Render Projection:
    f16

GPU Buffer:
    f16

Display:
    hardware-native format
```

The renderer must not force the simulation state to adopt the rendering representation.

Rendering is a consumer of semantic state.

---

# 52. Example: Messaging

A semantic signal may be transmitted as:

```text
semantic domain:
    [-1,+1]

computation:
    f32

transport:
    i8
```

The transport representation must carry sufficient metadata to reconstruct the intended semantic quantity within the declared error budget.

---

# 53. Serialization Metadata

When a serialized representation is not self-describing through an external standard, SCR serialization should preserve sufficient metadata to reconstruct:

```text
domain
range
scale
offset
zero point
precision
rounding
saturation
units
```

Metadata overhead must itself be considered in large-scale systems.

Repeated metadata should be factored out where possible.

---

# 54. Block and Tensor Quantization

For large arrays, per-value quantization metadata is generally undesirable.

SCR should support the conceptual distinction between:

```text
per-value
per-channel
per-vector
per-tensor
per-block
per-region
```

quantization parameters.

The appropriate granularity should be selected according to:

```text
error
compression
metadata overhead
vectorisation
memory locality
execution cost
```

---

# 55. Quantization Granularity

Smaller quantization regions can provide better numerical fidelity but increase metadata and conversion complexity.

Larger regions reduce metadata but may require larger ranges and therefore reduce effective precision.

The compiler/runtime should treat granularity as an optimisation parameter.

---

# 56. Memory-Bandwidth Optimisation

Where a workload is bandwidth-bound, reducing representation width may be more valuable than reducing arithmetic cost.

The runtime should therefore distinguish:

```text
compute-bound
memory-bound
bandwidth-bound
latency-bound
transfer-bound
```

workloads.

Numeric representation may then be selected accordingly.

---

# 57. Arithmetic Intensity

Representation optimisation should consider arithmetic intensity.

For example, reducing operand size may:

* reduce memory traffic;
* increase cache residency;
* improve vector density;

while leaving arithmetic complexity unchanged.

The runtime should therefore evaluate numerical representation together with the computational structure of the kernel.

---

# 58. Precision-Sensitive Algorithms

Some algorithms cannot safely use reduced precision merely because their inputs have bounded ranges.

Examples may include:

* long-running numerical integration;
* ill-conditioned matrix operations;
* cancellation-sensitive calculations;
* iterative optimisation;
* high-order geometry;
* chaotic dynamical systems;
* precision-sensitive reductions.

Such algorithms must declare their precision requirements semantically.

The compiler shall respect those requirements.

---

# 59. Stable Computation

An algorithm's required computational precision may exceed the precision required for its stored state.

For example:

```text
state:
    f16

computation:
    f32

accumulation:
    f64
```

may be valid where the semantic contract permits reconstruction of state within the required error budget.

Precision analysis must therefore consider the numerical stability of the operation rather than merely input and output types.

---

# 60. Determinism

Numeric execution must preserve declared determinism requirements.

Potential sources of non-determinism include:

```text
parallel reduction order
stochastic rounding
hardware-specific fused operations
provider-specific kernels
approximate math
```

A provider may only use such optimisations when they satisfy the declared semantic contract.

---

# 61. Fast-Math and Approximate Operations

Approximate numerical operations may be used where permitted by the semantic error budget.

For example:

```text
approximate reciprocal
approximate transcendental
fused operations
reassociation
```

may be valid where their numerical error remains within the applicable tolerance.

Approximation must not silently override an exactness requirement.

---

# 62. Compiler Pass Structure

A future SCR numeric optimisation pipeline may conceptually contain:

```text
Numeric Semantic Verification
        ↓
Range Analysis
        ↓
Precision Analysis
        ↓
Error Analysis
        ↓
Representation Analysis
        ↓
Cost Analysis
        ↓
Representation Selection
        ↓
Conversion Insertion
        ↓
Conversion Elimination
        ↓
Fusion
        ↓
Lowering
```

These should be implemented using MLIR's pass and analysis infrastructure.

This is a conceptual pipeline, not a requirement that every stage become a separate pass.

---

# 63. Verification

The compiler should verify:

```text
range validity
precision requirements
quantization parameters
rounding mode
saturation mode
error budget
representation compatibility
provider capability
```

Invalid combinations should fail verification rather than produce silently incorrect numerical behaviour.

---

# 64. Example Verification Rules

Examples include:

```text
quantization range must be non-empty
scale must be valid
zero point must be representable
rounding mode must be supported
required precision must not exceed selected representation
estimated error must not exceed permitted error
provider must support selected representation
```

Where exact static verification is impossible, runtime checks may be required.

---

# 65. Testing Strategy

Numeric execution must be tested at multiple levels.

### Semantic tests

Verify:

```text
normalization
quantization
dequantization
rounding
saturation
error bounds
```

### Compiler tests

Verify:

```text
representation propagation
precision reduction
precision promotion
conversion elimination
conversion fusion
lowering
```

### Provider tests

Verify:

```text
native representation
provider conversion
provider precision
provider error
provider determinism
```

### Runtime tests

Verify:

```text
provider selection
representation selection
memory optimisation
conversion minimisation
adaptive precision
```

### End-to-end tests

Verify complete semantic pipelines.

---

# 66. Reference Implementations

Every important lossy numerical transformation should have a simple reference implementation.

The reference implementation should prioritise:

```text
correctness
clarity
determinism
```

over performance.

Optimised providers can then be validated against the reference semantics.

---

# 67. Numerical Differential Testing

Providers should be testable against reference implementations.

For a semantic operation:

```text
reference(x)
provider(x)
```

the result should satisfy the declared error contract:

```text
error(reference, provider) ≤ permitted_error
```

where exact equality is not required.

---

# 68. Property-Based Testing

Where appropriate, numerical transformations should be tested using generated values across:

```text
minimum
maximum
zero
near-zero
mid-range
boundary
overflow
underflow
NaN
infinity
```

and representative distributions.

Quantization tests should specifically exercise values near representable boundaries.

---

# 69. Boundary Testing

Particular attention must be paid to:

```text
-1
+1
0
minimum integer
maximum integer
midpoint
quantization thresholds
```

For symmetric quantization:

```text
-1 → minimum
 0 → zero
+1 → maximum
```

must hold according to the declared representation contract.

---

# 70. Performance Measurement

Numeric optimisation must be measured rather than assumed.

Measurements should include:

```text
memory footprint
memory bandwidth
conversion volume
execution time
throughput
latency
cache behaviour
GPU occupancy
transfer volume
power where available
```

A smaller representation is not automatically a faster representation.

---

# 71. Whole-System Optimisation

Numeric execution shall be evaluated at the system level.

A local optimisation:

```text
f32 → i8
```

may be globally harmful if it creates:

```text
i8 → f32
```

immediately afterward.

Conversely, retaining `f32` may be optimal when it allows a large computational region to remain conversion-free.

Therefore:

> **Numeric optimisation must consider the computational graph and execution topology rather than isolated operations.**

---

# 72. Interaction With Adaptive Topology

If SCR changes computational topology dynamically, numeric representation may also change.

For example:

```text
local execution:
    f32

remote execution:
    i8 transport

accelerator:
    f16

persistent state:
    i8
```

The topology and representation decisions may therefore be jointly optimised.

---

# 73. Interaction With Messaging

Messaging providers should expose numeric representation capabilities.

The runtime should be able to determine:

```text
message payload representation
serialization cost
compression
bandwidth
conversion cost
```

A message should not be converted to a generic representation merely because the messaging subsystem is unaware of its semantic numeric type.

---

# 74. Interaction With Rendering

Rendering providers should consume the lowest-cost representation compatible with the rendering contract.

For example:

```text
simulation:
    f32

render projection:
    f16

GPU buffer:
    f16
```

may be preferable to:

```text
simulation:
    f32

render projection:
    f32

GPU buffer:
    f32
```

where visual fidelity is unaffected.

---

# 75. Interaction With Morphology

Morphological structures may contain numerical fields such as:

```text
position
scale
curvature
density
distance
normal
weight
confidence
```

Each should have an independently defined semantic numeric requirement.

The morphology system must not force all values into one representation merely for implementation convenience.

---

# 76. Interaction With Fields

Fields are particularly suitable for numeric representation optimisation because they may contain billions of values.

Field representations should support:

```text
domain
range
precision
error
quantization
storage format
compute format
```

The field provider should allow representation selection to be driven by semantic requirements.

---

# 77. Interaction With Simulation

Simulation state should distinguish:

```text
persistent state
working state
intermediate state
accumulation state
render state
```

Each may use a different representation.

The simulation engine should not assume that all state is stored and computed at the same precision.

---

# 78. Interaction With Neural Computation

Neural computation is a natural mixed-precision workload.

SCR should support combinations such as:

```text
weights:
    i8 / f16

activations:
    f16

accumulation:
    f32

master parameters:
    f32
```

The semantic model must determine whether the resulting approximation is acceptable.

---

# 79. Interaction With Streaming

Streaming pipelines should minimise representation transitions between adjacent stages.

A stream may maintain a representation for an entire processing region:

```text
source
  ↓
i16
  ↓
filter
  ↓
transform
  ↓
feature
  ↓
i16
```

with promotion only at boundaries that require it.

---

# 80. Interaction With Storage

Storage providers should support compact representations where semantic requirements permit them.

Storage compression and numeric quantization are related but distinct:

```text
quantization:
    changes numeric representation

compression:
    encodes representation more compactly
```

The semantic layer must remain independent of both.

---

# 81. Interaction With External Libraries

External numerical libraries may have their own numeric conventions.

Providers integrating them must translate between:

```text
SCR numeric semantics
```

and:

```text
external library representation
```

without allowing the external library's representation to become SCR's semantic convention.

---

# 82. Provider Adaptation

If a provider only supports:

```text
f32
```

while the semantic value is stored as:

```text
i8
```

the provider may introduce a conversion boundary.

However, the compiler/runtime should determine whether that conversion can be:

* fused;
* amortised;
* avoided;
* moved;
* performed lazily.

Provider limitations should therefore influence optimisation rather than dictate semantic representation.

---

# 83. Numeric Memory Pools

Runtime memory pools should be representation-aware.

For example:

```text
i8 pool
i16 pool
f16 pool
f32 pool
f64 pool
```

may be maintained where this improves allocation and locality.

Memory allocation metadata must remain implementation metadata, not semantic identity.

---

# 84. Alignment and Packing

Representation selection must consider alignment requirements.

Packed `i8` data may reduce memory footprint but introduce:

* alignment constraints;
* unpacking costs;
* vectorisation constraints.

The runtime must therefore optimise packing and alignment jointly.

---

# 85. Sparse Representations

Sparse numerical structures should distinguish:

```text
semantic sparsity
```

from:

```text
physical sparse encoding
```

A semantic field containing mostly zero values may be physically represented sparsely without changing its semantic type.

Numeric precision and sparsity optimisation may be combined.

---

# 86. Blocked and Tiled Execution

For large numerical structures, representation selection should be compatible with tiled execution.

For example:

```text
global field:
    semantic f32 requirement

tiles:
    f16 where error permits
```

may be possible if precision requirements vary spatially.

Such adaptive representations require explicit semantic justification.

---

# 87. Dynamic Precision

Some computations may require precision to change over time.

Examples include:

```text
early simulation:
    f16

sensitive phase:
    f32

convergence:
    f64
```

Dynamic precision changes are valid only when the semantic contract permits them.

The runtime should be able to trigger such changes based on declared requirements and observed conditions.

---

# 88. Precision as a Runtime Resource

The runtime should be able to treat precision as a controllable resource.

Under resource pressure it may evaluate:

```text
Can precision be reduced?
Can storage be compressed?
Can transport be quantized?
Can computation remain stable?
```

The answer must be derived from semantic constraints rather than arbitrary heuristics alone.

---

# 89. Numeric Execution Telemetry and Feedback

Telemetry may feed back into future representation decisions.

For example:

```text
Observed:
    memory-bound workload
    low quantization error
    high conversion cost

Decision:
    retain quantized representation longer
```

or:

```text
Observed:
    numerical instability

Decision:
    promote computation precision
```

This supports adaptive execution while preserving semantic correctness.

---

# 90. Security and Robustness

Numeric conversions must not introduce unexpected:

```text
overflow
underflow
wraparound
NaN propagation
infinite values
loss of sign
range violations
```

Inputs crossing trust boundaries should be validated where necessary.

Malformed numeric representations must not silently produce semantically valid values.

---

# 91. Compatibility With Serialization Standards

Where external standards define their own numeric representations, SCR should provide explicit adapters.

Examples may include:

```text
PCM
image formats
tensor formats
scientific data formats
network encodings
hardware buffer formats
```

The adapter is responsible for preserving the SCR numeric contract.

---

# 92. Implementation Priority

Implementation should proceed in stages.

### Stage 1

Implement:

```text
f32
f64
f16
i32
i16
i8
```

and basic numeric metadata.

### Stage 2

Implement:

```text
normalization
quantization
dequantization
saturation
rounding
```

### Stage 3

Implement:

```text
range analysis
precision analysis
conversion elimination
```

### Stage 4

Implement:

```text
error propagation
precision reduction
mixed precision
```

### Stage 5

Implement:

```text
cost-based representation selection
provider integration
hardware-aware optimisation
```

### Stage 6

Implement:

```text
adaptive runtime representation
telemetry-driven precision
dynamic optimisation
```

The implementation should remain incremental.

---

# 93. Minimum Viable Numeric Execution

The first vertical implementation should prove:

```text
Semantic Numeric Definition
        ↓
MLIR Representation
        ↓
f32 Computation
        ↓
Quantization
        ↓
i8 Representation
        ↓
Dequantization
        ↓
f32
        ↓
Semantic Verification
```

The implementation should demonstrate that:

* normalization is explicit;
* quantization is explicit;
* representation conversion is compiler-visible;
* error is bounded;
* round-trip behaviour is verified.

---

# 94. Required Golden Tests

The minimum golden tests should include:

```text
[-1,+1] → i8
[0,1] → i8
[-1,+1] → i16
[0,1] → i16
f32 → f16
f32 → bf16
```

and their corresponding reconstruction/error tests.

Boundary values must be included.

---

# 95. Architectural Invariants

### EXEC-NUM-001 — MLIR Representation

Numeric execution shall use MLIR as its representation substrate.

### EXEC-NUM-002 — No Numeric Shadow IR

No independent numeric IR shall be introduced.

### EXEC-NUM-003 — Semantic Visibility

Semantic numeric transformations must remain visible to compiler analysis.

### EXEC-NUM-004 — Representation Independence

Physical representation shall not define semantic identity.

### EXEC-NUM-005 — Error Preservation

Representation changes shall respect declared error budgets.

### EXEC-NUM-006 — Conversion Minimisation

Unnecessary conversions shall be eliminated.

### EXEC-NUM-007 — Global Optimisation

Representation selection shall consider the computational graph as a whole.

### EXEC-NUM-008 — Provider Neutrality

Providers shall implement numeric semantics rather than redefine them.

### EXEC-NUM-009 — Hardware Awareness

Hardware characteristics may influence representation selection.

### EXEC-NUM-010 — Semantic Safety

Performance optimisation shall not violate semantic requirements.

### EXEC-NUM-011 — Explicit Loss

Lossy transformations shall remain identifiable.

### EXEC-NUM-012 — Explicit Policy

Rounding and saturation behaviour shall remain defined.

### EXEC-NUM-013 — Precision Separation

Storage, transport, computation, and accumulation precision may differ.

### EXEC-NUM-014 — Whole-System Cost

Memory, bandwidth, conversion, computation, and transfer costs shall be considered jointly.

### EXEC-NUM-015 — No Domain Numeric Silos

Domains shall use the common SCR numeric semantic model.

---

# 96. Implementation Anti-Patterns

The following implementation patterns are prohibited or strongly discouraged:

```text
everything is f32
everything is f64
implicit quantization
implicit dequantization
provider-hidden conversions
domain-specific scaling conventions
unbounded narrowing
integer wrapping as default conversion
per-domain numeric type systems
representation-driven semantic types
conversion at every domain boundary
```

The existence of a physical type in a provider API is not sufficient justification for changing SCR representation.

---

# 97. Design Principle: Minimise Representation Transitions

A core execution optimisation principle is:

> **A representation transition should occur only when its semantic or execution benefit exceeds its cost.**

This means the runtime should optimise not merely:

```text
representation size
```

but:

```text
representation size
+
conversion cost
+
memory cost
+
bandwidth cost
+
provider cost
+
hardware cost
```

---

# 98. Design Principle: Preserve Semantic Information, Not Bits

SCR does not attempt to preserve every physical bit through every transformation.

It attempts to preserve the information required by the semantic contract.

Therefore:

```text
f32 → i8
```

may be perfectly valid if the resulting approximation satisfies the semantic error budget.

Conversely:

```text
f64 → f32
```

may be invalid if the computation requires the precision lost by the conversion.

The number of bits alone does not determine semantic validity.

---

# 99. Design Principle: Optimise the Whole Graph

Numeric representation optimisation must be performed with awareness of:

```text
upstream producers
downstream consumers
execution topology
provider boundaries
memory locality
transport boundaries
storage boundaries
hardware
```

The optimal representation of an individual operation may not be the optimal representation of the complete computational graph.

---

# 100. Final Execution Model

The intended SCR numeric execution architecture is:

```text
                    SEMANTIC VALUE
                          │
                          ▼
                Numeric Requirements
                          │
             ┌────────────┼────────────┐
             │            │            │
           Range       Precision      Error
             │            │          Budget
             └────────────┼────────────┘
                          ▼
                    MLIR Semantic
                    Representation
                          │
                          ▼
                 Numeric Analysis
                          │
             ┌────────────┼────────────┐
             ▼            ▼            ▼
          Range       Precision       Cost
          Analysis     Analysis      Analysis
             │            │            │
             └────────────┼────────────┘
                          ▼
                Representation Choice
                          │
              ┌───────────┼───────────┐
              ▼           ▼           ▼
             f32         f16          i8
              │           │           │
              └───────────┼───────────┘
                          ▼
                 MLIR Transformation
                          │
                          ▼
                      Provider
                          │
                          ▼
                       Runtime
                          │
                          ▼
                      Hardware
```

The semantic value remains invariant while its physical representation may change.

---

# 101. Final Statement

`005_NUMERIC_SEMANTICS.md` defines **what numerical representation means within SCR**.

This document defines **how that meaning is realised and optimised during execution**.

The governing principle is:

> **SCR shall preserve required numerical semantics while selecting and adapting physical representations to minimise unnecessary memory, bandwidth, computation, conversion, transport, and storage costs.**

The implementation should therefore move numerical optimisation out of individual application components and into the common SCR semantic compilation and execution architecture.

The desired end state is not:

```text
Every component knows how to convert numbers.
```

It is:

```text
Semantic requirements
        ↓
Compiler understands them
        ↓
Runtime understands them
        ↓
Providers expose capabilities
        ↓
System selects optimal representations
        ↓
Applications remain representation-independent
```

Numeric representation is consequently treated as a **global optimisation dimension of SCR**, alongside computational topology, provider selection, memory, communication, scheduling, and hardware execution.
