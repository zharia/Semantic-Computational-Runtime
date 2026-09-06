# 005 — Numeric Semantics

**Document:** `005_NUMERIC_SEMANTICS.md`
**Version:** 1.0.0
**Status:** Foundational / Normative
**Scope:** Entire Semantic Computational Runtime (SCR)

---

# 1. Purpose

This document defines the normative numeric semantics of the Semantic Computational Runtime (SCR).

Numeric representation is a foundational property of SCR rather than an implementation detail belonging to individual domains or providers.

SCR operates across computational domains including signal processing, fields, geometry, morphology, dynamics, simulation, neural computation, optimisation, rendering, streaming, messaging, and other numerical workloads. These domains must therefore share a common numerical semantic foundation.

The purpose of this standard is to establish that foundation.

The central objective is:

> **SCR shall represent numerical meaning independently of physical numeric representation and shall optimise representation and computation globally according to semantic requirements, precision requirements, error tolerance, resource constraints, and execution conditions.**

This standard therefore governs:

* numeric semantic types;
* numeric domains;
* normalization;
* canonical representations;
* precision;
* storage representation;
* computation representation;
* transport representation;
* quantization;
* dequantization;
* rounding;
* saturation;
* invalid values;
* numerical error;
* error budgets;
* representation conversion;
* precision propagation;
* cross-domain interoperability;
* compiler/runtime optimisation.

---

# 2. Foundational Principle

The fundamental SCR numeric principle is:

> **Meaning precedes representation.**

A numerical value is not semantically defined by whether it happens to be stored as `f64`, `f32`, `f16`, `bf16`, `i32`, `i16`, `i8`, or another physical representation.

The semantic definition of a value consists of its meaning and the constraints necessary to preserve that meaning.

Therefore:

```text
Semantic Numeric Type
        ≠
Physical Numeric Representation
```

For example:

```text
NormalizedSignalAmplitude
```

may be represented as:

```text
f64
f32
f16
i16
i8
```

without becoming five different semantic types.

The representation is an implementation choice constrained by the semantic requirements.

---

# 3. Scope of Numeric Semantics

Numeric semantics apply across the complete SCR computational architecture.

They therefore operate across:

```text
Semantic Model
      ↓
Semantic MLIR
      ↓
MLIR Analysis
      ↓
MLIR Transformation
      ↓
Lowering
      ↓
Provider
      ↓
Runtime
      ↓
Execution
      ↓
Storage / Transport / Rendering
```

Numeric semantics are not confined to:

* signal processing;
* numerical libraries;
* storage;
* compiler lowering;
* individual providers.

They are a cross-cutting semantic concern.

Every SCR domain that represents numerical quantities must conform to this standard.

---

# 4. No Numeric Representation Layer Outside MLIR

SCR shall not introduce a separate numeric IR or independent numeric type system alongside MLIR.

Numeric semantics shall be represented through appropriate MLIR mechanisms, including where applicable:

* MLIR types;
* dialect types;
* attributes;
* operations;
* interfaces;
* traits;
* constraints;
* analyses;
* transformations;
* canonicalisation;
* verification;
* lowering.

SCR-specific semantic concepts may be introduced where required, but they must use MLIR's representation and extensibility mechanisms.

There shall be no parallel:

```text
SCR Numeric IR
SCR Numeric AST
SCR Numeric Type Graph
SCR Numeric SSA
```

or equivalent shadow representation.

---

# 5. Semantic Numeric Type

A **Semantic Numeric Type** describes the meaning and numerical requirements of a quantity independently of its physical representation.

A semantic numeric type may specify:

```text
Meaning
Domain
Units
Range
Canonical domain
Precision requirement
Accuracy requirement
Error tolerance
Validity constraints
Ordering requirements
Monotonicity requirements
Determinism requirements
Quantization requirements
```

Conceptually:

```text
SemanticNumericType {
    meaning
    domain
    units
    range
    canonical_domain
    precision_requirement
    error_budget
    validity_constraints
    representation_constraints
}
```

This conceptual structure does not require a corresponding runtime object or independent IR.

It describes the semantic information that SCR must be able to represent through MLIR.

---

# 6. Semantic Type ≠ Storage Type ≠ Execution Type

SCR shall explicitly distinguish:

```text
Semantic Type
Storage Representation
Transport Representation
Computation Representation
Execution Representation
```

These representations may differ.

For example:

```text
SignalAmplitude
    semantic domain: [-1,+1]
    error tolerance: ε
```

may be realised as:

```text
Storage:
    i8

Transport:
    i8

CPU computation:
    f32

GPU computation:
    f16

Accumulation:
    f32
```

This is valid provided the transformations preserve the declared semantic requirements.

---

# 7. Canonical Numeric Representation

SCR shall establish a default canonical computational representation for general real-valued numerical computation.

## 7.1 Canonical Default

The default canonical computational representation shall be:

```text
f32
```

unless a semantic domain explicitly requires another representation.

This does not mean that every value must physically exist as `f32`.

It means that `f32` is the default reference point for general SCR numerical computation.

Providers and compiler transformations may use another representation where semantic and execution constraints permit it.

---

# 8. Precision Classes

SCR shall recognise the following primary floating-point precision classes.

## 8.1 `f64`

`f64` is the high-precision floating-point class.

It is appropriate for:

* precision-sensitive algorithms;
* high-accuracy accumulation;
* numerical reference implementations;
* long-duration numerical integration;
* high-dynamic-range calculations;
* precision-sensitive geometry;
* validation;
* algorithms whose error requirements exceed `f32`.

`f64` shall not be the default merely because it provides greater precision.

Its use must be justified by semantic or computational requirements.

---

## 8.2 `f32`

`f32` is the canonical general-purpose floating-point computation class.

It is the default for:

* normalized signals;
* fields;
* general simulation state;
* spatial data;
* rendering data;
* general numerical computation;
* many machine-learning workloads;
* general-purpose CPU/GPU numerical execution.

---

## 8.3 `f16`

`f16` is a reduced-precision floating-point representation.

It is appropriate where:

* the semantic error budget permits reduced precision;
* bandwidth reduction is beneficial;
* memory pressure is significant;
* accelerator execution benefits from reduced precision;
* vector throughput is improved;
* storage density is important.

`f16` shall not be assumed semantically equivalent to `f32` merely because both represent floating-point values.

---

## 8.4 `bf16`

`bf16` is a reduced-precision floating-point representation primarily suited to execution environments where its range and hardware characteristics are advantageous.

It is particularly applicable to:

* machine learning;
* accelerator computation;
* reduced-bandwidth computation;
* high-throughput numerical workloads.

Its use must respect its precision characteristics.

---

# 9. Integer Representation Classes

Integer representations may be used for:

* quantized numerical values;
* discrete quantities;
* counts;
* indices;
* identifiers;
* encoded values;
* compact signals;
* storage;
* transport;
* embedded processing.

SCR shall distinguish integer values that are intrinsically discrete from integers used to encode continuous semantic quantities.

For example:

```text
ParticleCount<i32>
```

and:

```text
SignalAmplitude<i16>
```

are semantically different even though both use an integer representation.

---

# 10. Canonical Normalized Domains

SCR shall support explicit normalized numeric domains.

The primary normalized real-valued domains are:

```text
[-1,+1]
[0,1]
```

These domains are semantic domains, not floating-point formats.

---

## 10.1 Symmetric Normalized Domain

The domain:

```text
[-1,+1]
```

shall be the canonical normalized domain for quantities whose natural semantics are symmetric around zero.

Typical examples include:

* signal amplitude;
* signed displacement;
* signed activation values;
* normalized vector components;
* bipolar control values;
* directional scalar quantities.

---

## 10.2 Positive Normalized Domain

The domain:

```text
[0,1]
```

shall be the canonical normalized domain for quantities whose semantic range is non-negative and naturally bounded.

Typical examples include:

* probabilities;
* normalized weights;
* normalized luminance;
* occupancy;
* fractional quantities;
* blend factors;
* confidence values.

---

# 11. Normalization

Normalization is the semantic transformation of a value from one domain into a canonical numerical domain.

Conceptually:

```text
Physical / Domain Value
        ↓
Normalization
        ↓
Canonical Numeric Domain
```

For a source interval:

```text
[a,b]
```

the canonical normalized value is:

```text
x_norm = (x-a)/(b-a)
```

for `[0,1]`.

For `[-1,+1]`:

```text
x_norm = 2(x-a)/(b-a)-1
```

Normalization shall preserve the intended ordering and semantic relationship unless the semantic definition explicitly states otherwise.

---

# 12. Normalization Is Not Quantization

SCR shall distinguish:

### Normalization

A semantic transformation of domain.

```text
physical value → normalized value
```

### Quantization

A mapping from a continuous or higher-precision numerical domain into a finite representation.

```text
normalized value → discrete representation
```

### Encoding

A representation-specific mapping into an external storage or transport format.

```text
numeric representation → encoded format
```

The conceptual pipeline is:

```text
Semantic Value
      ↓
Normalization
      ↓
Canonical Numeric Domain
      ↓
Quantization
      ↓
Numeric Representation
      ↓
Encoding
      ↓
Storage / Transport
```

These operations shall not be conflated.

---

# 13. Canonical Quantization

Quantization shall be explicit and mathematically defined.

For a normalized value:

```text
x ∈ [-1,+1]
```

and an unsigned integer representation with `N` bits:

```text
q = round((x+1)/2 × (2^N-1))
```

The inverse transformation is:

```text
x̂ = 2q/(2^N-1)-1
```

For a normalized positive value:

```text
x ∈ [0,1]
```

the canonical quantization is:

```text
q = round(x × (2^N-1))
```

with inverse:

```text
x̂ = q/(2^N-1)
```

The exact quantization parameters shall remain part of the semantic representation.

---

# 14. Symmetric Signed Quantization

For signed integer representations, SCR shall prefer symmetric ranges around zero.

For an `N`-bit signed representation, the canonical symmetric normalized integer domain shall be:

```text
-(2^(N-1)-1) ... +(2^(N-1)-1)
```

Therefore:

```text
i8:
    -127 ... +127

i16:
    -32767 ... +32767

i32:
    -2147483647 ... +2147483647
```

The remaining most-negative two's-complement value may be reserved or treated according to an explicitly declared representation policy.

This avoids introducing an unintended asymmetry into a semantic domain that is explicitly symmetric.

---

# 15. Quantization Metadata

Quantized representations shall be semantically describable.

The relevant metadata may include:

```text
source domain
target representation
minimum
maximum
scale
offset
zero point
rounding mode
saturation mode
error bound
validity range
```

Conceptually:

```text
QuantizationSpec {
    source_domain
    target_type
    scale
    offset
    zero_point
    rounding
    saturation
    error_bound
}
```

This is semantic metadata, not an independent IR.

---

# 16. Rounding

The default deterministic rounding mode shall be:

```text
round-to-nearest, ties-to-even
```

SCR may support:

* nearest-even;
* nearest-away;
* toward-zero;
* floor;
* ceiling;
* stochastic rounding.

Any non-default rounding behaviour shall be explicit.

Stochastic rounding shall be considered non-deterministic unless the semantic execution context explicitly provides deterministic random state.

---

# 17. Saturation

Narrowing numeric conversions shall default to saturation rather than wraparound.

For example:

```text
1.4 → i8
```

under symmetric normalized semantics shall saturate at the maximum representable value.

Similarly:

```text
-1.4 → i8
```

shall saturate at the minimum representable semantic value.

Integer wraparound shall only occur where explicitly requested by the semantic operation.

---

# 18. Invalid Floating-Point Values

SCR shall define explicit handling for:

```text
NaN
+∞
-∞
```

during conversion to bounded or quantized representations.

The default policy shall be:

```text
NaN → invalid
+∞ → positive saturation
-∞ → negative saturation
```

An operation may define another policy where its semantic domain requires it.

Silent implementation-defined handling is prohibited for normative SCR numeric transformations.

---

# 19. Error

Every lossy numerical transformation introduces an approximation.

SCR shall distinguish at minimum:

```text
absolute error
relative error
quantization error
accumulated error
representation error
```

Where appropriate, domain-specific metrics may also be used.

For a source value `x` and reconstructed value `x̂`:

```text
absolute error:

ε_abs = |x-x̂|
```

For non-zero values:

```text
relative error:

ε_rel = |x-x̂|/|x|
```

The appropriate metric depends on the semantic domain.

---

# 20. Error Budgets

A semantic numerical computation may declare an acceptable error budget.

Conceptually:

```text
ErrorBudget {
    maximum_absolute_error
    maximum_relative_error
    accumulated_error
    domain_metric
}
```

A representation or transformation is semantically admissible only when its error remains within the applicable budget.

Therefore:

```text
representation selection
```

shall be capable of being constrained by:

```text
acceptable_error ≤ declared_error_budget
```

This enables compiler and runtime decisions to be made on semantic grounds.

---

# 21. Precision Is a Semantic Constraint

SCR shall treat precision as more than a property of physical representation.

The semantic definition of a computation may specify:

* minimum precision;
* required accuracy;
* acceptable error;
* accumulation precision;
* intermediate precision;
* output precision.

Therefore:

> **Precision is a semantic constraint that may influence compilation, representation selection, provider selection, scheduling, and execution.**

---

# 22. Storage, Transport, and Computation Precision

SCR shall allow different representations for different stages of a computation.

For example:

```text
Storage:
    i8

Transport:
    i8

Computation:
    f32

Accumulation:
    f32

Output:
    i8
```

This is preferable to indiscriminately converting all values to a single precision.

The compiler and runtime should minimise unnecessary conversions.

---

# 23. Representation Conversion

Representation conversion shall be explicit at the semantic level even when the compiler later eliminates or fuses the physical conversion.

Conversions include:

```text
f64 → f32
f32 → f16
f32 → bf16
f32 → i16
f32 → i8
i8 → f32
i16 → f32
```

The conversion semantics shall include sufficient information to determine:

* whether the transformation is lossless;
* whether it is lossy;
* its error bound;
* its rounding policy;
* its saturation policy;
* its computational cost where relevant.

---

# 24. Compiler Visibility

Numeric transformations must remain visible to the compiler.

SCR shall not hide essential numeric transformations inside opaque provider implementations when doing so prevents semantic analysis.

The compiler must be able to reason about:

```text
normalization
quantization
dequantization
precision conversion
range conversion
saturation
rounding
error
```

This allows:

* conversion elimination;
* conversion fusion;
* representation propagation;
* precision propagation;
* kernel specialisation;
* memory optimisation;
* bandwidth optimisation;
* provider selection.

---

# 25. Conversion Elimination

The compiler should eliminate unnecessary conversions wherever semantic equivalence permits.

For example:

```text
f32
 ↓
i8
 ↓
f32
```

shall not be introduced merely because two providers expose different API-level types if the intermediate representation can preserve the original representation.

Similarly:

```text
f32 → f16 → f32
```

should be avoided when the reduced-precision representation provides no semantic or execution benefit.

---

# 26. Precision Propagation

SCR shall support the concept of precision propagation across computational graphs.

Given:

```text
A → B → C → D
```

the compiler may determine:

```text
A precision requirement
B error contribution
C error contribution
D tolerance
```

and derive whether reduced precision is admissible.

Conceptually:

```text
Required Output Accuracy
        ↑
Error Propagation
        ↑
Operation Requirements
        ↑
Representation Selection
```

The implementation mechanism shall use MLIR analysis and transformation infrastructure.

---

# 27. Global Optimisation

Numeric representation shall be optimised across the computational graph rather than independently within each domain.

The optimisation objective may include:

```text
memory footprint
memory bandwidth
cache pressure
GPU memory
CPU/GPU transfer
network bandwidth
storage requirements
vector throughput
accelerator throughput
latency
power
thermal constraints
```

subject to:

```text
semantic correctness
precision requirements
error budgets
validity constraints
determinism requirements
```

The preferred representation is therefore not necessarily the highest precision representation.

It is the representation that satisfies the semantic requirements at the lowest appropriate computational and resource cost.

---

# 28. Numeric Representation as a Resource

Numeric representation shall be treated as an execution resource.

Changing representation can alter:

```text
memory consumption
cache residency
memory bandwidth
communication volume
GPU occupancy
vector width
storage capacity
serialization cost
power consumption
```

Consequently, precision and representation decisions may affect the global execution plan.

For large datasets, reducing representation width may produce substantial system-level improvements.

For example:

```text
10,000,000,000 values

f32:
    40 GB

f16:
    20 GB

i8:
    10 GB
```

These differences may propagate into cache behaviour, transfer requirements, memory pressure, and execution throughput.

---

# 29. Domain Independence

Individual SCR domains shall not independently define incompatible numeric conventions when a common semantic convention already exists.

Domains may define domain-specific requirements such as:

```text
SignalAmplitude:
    [-1,+1]

Probability:
    [0,1]

Temperature:
    physical units

Time:
    physical units

Angle:
    radians

Count:
    integer
```

However, normalization, quantization, precision, conversion, rounding, saturation, and error semantics shall derive from this common standard.

Domain-specific conventions must not silently override the platform-wide numeric model.

---

# 30. Units

Normalization shall not be confused with unit conversion.

For example:

```text
metres → millimetres
```

is a unit transformation.

```text
[a,b] → [0,1]
```

is normalization.

```text
f32 → i8
```

is representation conversion or quantization.

These operations may compose but shall remain semantically distinguishable.

Conceptually:

```text
Physical Quantity
      ↓
Unit Transformation
      ↓
Domain Transformation
      ↓
Normalization
      ↓
Canonical Numeric Domain
      ↓
Quantization
      ↓
Representation
```

---

# 31. Dimensionless Normalized Values

A normalized value shall be considered dimensionless only when the normalization operation removes the relevant physical scale according to a declared semantic transformation.

For example:

```text
temperature → normalized_temperature
```

does not make the original physical temperature dimensionless in the semantic model.

The normalized representation is a derived dimensionless representation.

The source semantic quantity remains recoverable where the normalization transformation is reversible.

---

# 32. Reversibility

Numeric transformations shall declare or permit analysis of their reversibility.

A transformation may be:

```text
lossless
approximately reversible
lossy
non-reversible
```

Quantization is generally approximately reversible or lossy.

Normalization may be exactly reversible when its parameters are retained.

Loss of information shall never be hidden behind an apparently lossless type conversion.

---

# 33. Canonical Signal Processing Policy

Because signal processing is a significant SCR workload, the following convention is established.

For normalized real-valued signals:

```text
canonical domain:
    [-1,+1]

canonical computation:
    f32

high-precision computation:
    f64

reduced floating representation:
    f16 / bf16 where admissible

quantized signed representation:
    i16 / i8

default rounding:
    nearest-even

default narrowing:
    saturation
```

The exact representation remains subject to the signal's semantic error requirements.

---

# 34. Canonical Positive Signal / Feature Policy

For non-negative normalized signals or features:

```text
canonical domain:
    [0,1]

canonical computation:
    f32
```

Typical examples include:

* probability;
* normalized intensity;
* confidence;
* blend factor;
* fractional occupancy;
* normalised weights.

Quantization shall follow the standard positive-domain quantization rules.

---

# 35. Accumulation Precision

The precision used for accumulation may exceed the precision used for storage or individual operands.

For example:

```text
i8 operands
    ↓
f32 accumulation
    ↓
i8 result
```

or:

```text
f16 operands
    ↓
f32 accumulation
    ↓
f16 result
```

The accumulation representation shall be selected according to numerical stability and error requirements.

Operand precision must therefore not automatically determine accumulation precision.

---

# 36. Determinism

Where an SCR computation is declared deterministic, numeric transformations shall preserve deterministic behaviour subject to the declared execution model.

This includes consideration of:

* rounding;
* reduction ordering;
* floating-point contraction;
* stochastic rounding;
* parallel accumulation;
* provider-specific numerical behaviour.

Numerically equivalent results are not automatically deterministic results.

Where exact reproducibility is required, the semantic contract must explicitly declare the required reproducibility level.

---

# 37. Provider Responsibilities

Providers shall implement the semantic numeric contract rather than redefine it.

A provider may choose:

```text
f32
f16
bf16
i8
i16
f64
```

or another supported representation where the semantic requirements permit it.

Providers shall not silently:

* change normalization domains;
* change quantization rules;
* change rounding policy;
* introduce wrapping;
* discard required precision;
* violate declared error budgets.

Provider-specific optimisations must remain semantically valid.

---

# 38. Runtime Responsibilities

The runtime may select representations dynamically according to:

```text
semantic requirements
precision requirements
error budgets
hardware capabilities
memory pressure
bandwidth
latency
throughput
topology
power
thermal conditions
provider capabilities
```

The runtime should prefer representation choices that reduce unnecessary:

```text
memory
copies
conversions
transfers
serialization
deserialization
```

while preserving semantic correctness.

---

# 39. Hardware Awareness

Numeric semantics are hardware-independent but hardware-aware.

The system may reason about:

* native floating-point widths;
* SIMD widths;
* tensor units;
* GPU execution formats;
* accelerator capabilities;
* memory bandwidth;
* cache hierarchy;
* vectorisation;
* conversion throughput;
* transfer costs.

Hardware characteristics may influence representation selection but shall not redefine semantic meaning.

---

# 40. Interoperability

External systems may use different numerical conventions.

When interfacing with an external system, SCR shall explicitly describe the transformation between:

```text
SCR Semantic Numeric Type
```

and:

```text
External Numeric Representation
```

This may require:

```text
unit conversion
normalization
range conversion
quantization
encoding
decoding
precision conversion
```

The external system's convention shall not silently become the SCR semantic convention.

---

# 41. Serialization and Transport

Serialized and transported representations shall be treated as representations rather than semantic definitions.

For example:

```text
SignalAmplitude
```

may be serialized as:

```text
PCM16
```

without making PCM16 the semantic definition of `SignalAmplitude`.

Transport optimisation may select:

```text
i8
i16
f16
f32
```

according to the declared semantic requirements and communication constraints.

---

# 42. Memory Optimisation

SCR shall consider numerical representation as a first-class memory optimisation mechanism.

For large arrays, fields, tensors, graphs, particle populations, signals, and simulation state, representation width can dominate total resource consumption.

The compiler and runtime should therefore consider:

```text
value cardinality
range
precision
error tolerance
access pattern
lifetime
locality
consumer requirements
```

when selecting representations.

---

# 43. Representation Lifetime

Different phases of an object's lifetime may use different representations.

For example:

```text
Persistent State:
    i8

Loaded State:
    i8

Compute:
    f32

Intermediate:
    f16

Accumulation:
    f32

Output:
    i8
```

The semantic identity remains constant.

Representation may therefore be changed as part of lifecycle optimisation.

---

# 44. Semantic Compatibility

Two numerical representations are semantically compatible when they can represent the required semantic domain and satisfy the applicable precision and error constraints.

Compatibility is therefore not equivalent to:

```text
same bit width
same numeric primitive
same language type
```

Instead:

```text
Semantic Compatibility =
    Domain Compatibility
    +
    Range Compatibility
    +
    Precision Compatibility
    +
    Error Compatibility
    +
    Validity Compatibility
```

---

# 45. Numeric Capability

Numeric capabilities may be exposed through MLIR interfaces or equivalent SCR semantic mechanisms.

Potential capabilities include:

```text
Quantizable
Dequantizable
Normalizable
Denormalizable
PrecisionReducible
PrecisionExtensible
Saturating
Deterministic
Approximate
Lossless
Lossy
AccumulationSafe
Vectorizable
Packable
```

These capabilities describe what transformations are semantically permissible.

They shall not constitute a separate type or IR system.

---

# 46. Compiler Optimisation Opportunities

The numeric semantic model should enable compiler transformations including:

```text
constant folding
normalization fusion
quantization fusion
dequantization fusion
conversion elimination
precision reduction
precision promotion
range propagation
error propagation
representation propagation
kernel specialisation
vectorisation
packing
layout optimisation
memory reduction
transfer reduction
```

These transformations should be expressed through MLIR's analysis and transformation mechanisms.

---

# 47. Example: Signal Pipeline

Consider:

```text
Sensor
  ↓
Signal
  ↓
Filter
  ↓
FFT
  ↓
Feature Extraction
  ↓
Classifier
```

A naive implementation might perform:

```text
i16
 ↓
f32
 ↓
f32
 ↓
f32
 ↓
f32
 ↓
i8
```

SCR should instead be able to reason about:

```text
Sensor:
    i16 storage

Filter:
    f32 computation

FFT:
    f32 computation

Feature:
    f16 sufficient

Classifier:
    i8 sufficient
```

and minimise unnecessary conversions.

---

# 48. Example: Large Field

Consider a field containing:

```text
10 billion values
```

with semantic requirements:

```text
domain = [0,1]
maximum error = 0.005
```

The system may determine that `i8` is sufficient.

The field can therefore remain quantized during:

```text
storage
transport
memory residency
```

and be promoted only where a downstream computation requires greater precision.

The decision is based on the semantic error budget rather than an arbitrary platform-wide preference for `f32`.

---

# 49. Example: Mixed-Precision Dynamics

A simulation may specify:

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

The semantic types remain distinct from their representations.

The provider may therefore exploit reduced memory bandwidth while preserving the precision required by the integration algorithm.

---

# 50. Numeric Semantics Across Architectural Layers

Numeric semantics shall remain coherent across all SCR layers.

```text
Semantic Layer
    ↓
defines meaning, range, precision, error

MLIR Layer
    ↓
represents and analyses numeric semantics

Transformation Layer
    ↓
optimises representation

Provider Layer
    ↓
realises representation

Runtime Layer
    ↓
selects execution strategy

Hardware
    ↓
executes representation
```

No lower layer may silently redefine the numeric semantics established by a higher layer.

---

# 51. Forbidden Patterns

The following are prohibited unless explicitly justified by a semantic requirement:

### Everything-as-`f64`

Using `f64` everywhere merely because it is convenient.

### Everything-as-`f32`

Using `f32` everywhere merely because it is the default.

### Hidden Conversion

Performing implicit representation conversions inside providers without compiler visibility.

### Hidden Normalization

Having individual domains independently normalise the same semantic quantity using incompatible conventions.

### Hidden Quantization

Quantizing data without declaring the quantization parameters or error characteristics.

### Implicit Wrapping

Allowing narrowing conversion to wrap instead of saturate.

### Domain-Specific Numeric Silos

Creating incompatible numeric conventions in different SCR domains.

### Representation Leakage

Allowing a storage or provider representation to become part of semantic identity.

### Numeric Shadow Type System

Creating a parallel SCR type system outside MLIR.

---

# 52. Required Domain Definition Behaviour

Every SCR domain definition that introduces a numerical quantity shall identify, where applicable:

```text
semantic meaning
units
domain
range
normalization
canonical computation precision
acceptable error
representation constraints
quantization behaviour
validity constraints
```

The domain shall inherit platform-wide numeric rules unless it explicitly specifies a justified semantic exception.

---

# 53. Exception Policy

A domain may require numeric behaviour that differs from the platform defaults.

Examples include:

* exact integer arithmetic;
* arbitrary precision;
* fixed-point arithmetic;
* complex arithmetic;
* interval arithmetic;
* symbolic values;
* specialised numeric formats;
* domain-specific quantization.

Such requirements must be expressed semantically.

They must not result in an independent numeric architecture.

The implementation must use appropriate MLIR mechanisms and remain compatible with the overall SCR numeric model.

---

# 54. Arbitrary Precision

Arbitrary-precision arithmetic may be supported where semantically required.

It shall be treated as a computational capability rather than the default representation.

A domain requiring arbitrary precision must identify why the canonical precision classes are insufficient.

Arbitrary precision must not become the default merely because it avoids numerical analysis.

---

# 55. Fixed-Point Arithmetic

Fixed-point representations may be used where appropriate for:

* embedded execution;
* deterministic hardware;
* specialised accelerators;
* signal processing;
* constrained environments.

The fixed-point scale, range, precision, rounding, and saturation behaviour must be explicit.

Fixed-point shall remain a representation of a semantic numeric quantity rather than becoming its semantic definition.

---

# 56. Complex Numbers

Complex numerical quantities shall be represented as semantic types whose real and imaginary components obey the applicable precision and error requirements.

The precision of the components shall not be inferred merely from the physical storage format.

For example:

```text
ComplexSignal<f32>
```

represents a complex semantic quantity whose components use the declared numerical precision.

---

# 57. Boolean and Discrete Quantities

Boolean values and discrete categorical values shall not be treated as quantized floating-point values merely because they may be physically packed.

For example:

```text
Boolean
```

is semantically distinct from:

```text
Probability ∈ [0,1]
```

even if both ultimately occupy one byte.

---

# 58. Numeric Identity

Numeric representation changes shall not change semantic identity.

For example:

```text
SignalAmplitude<f32>
```

and:

```text
SignalAmplitude<i8>
```

refer to the same semantic quantity when the representation transformation is valid.

Identity belongs to the semantic object, not the storage format.

---

# 59. Information Preservation

Transformations shall preserve all information required by downstream semantics.

A transformation may discard information only when:

```text
the discarded information is outside the declared semantic requirement
```

and:

```text
the resulting error remains within the applicable budget.
```

This establishes a general rule:

> **Information may be discarded intentionally; it must never be discarded accidentally.**

---

# 60. Global Optimisation Principle

SCR shall optimise numerical representation at the level of the computational system rather than isolated operations.

The optimisation process should consider:

```text
semantic requirements
        ↓
precision requirements
        ↓
error budgets
        ↓
representation options
        ↓
memory cost
        ↓
bandwidth cost
        ↓
conversion cost
        ↓
provider capabilities
        ↓
hardware characteristics
        ↓
global execution plan
```

This is a system-level optimisation problem.

---

# 61. Canonical Representation Policy

The following defaults are normative:

| Semantic concern                       | SCR default                   |
| -------------------------------------- | ----------------------------- |
| General real computation               | `f32`                         |
| High precision                         | `f64`                         |
| Reduced floating precision             | `f16`                         |
| Accelerator-oriented reduced precision | `bf16`                        |
| Signed quantization                    | `i16` / `i8`                  |
| Symmetric normalized domain            | `[-1,+1]`                     |
| Positive normalized domain             | `[0,1]`                       |
| Default rounding                       | nearest-even                  |
| Default narrowing                      | saturating                    |
| Signed normalized zero                 | exactly `0`                   |
| Semantic type                          | independent of representation |
| Quantization                           | explicit                      |
| Dequantization                         | explicit                      |
| Error                                  | semantically describable      |
| Representation conversion              | compiler-visible              |
| Storage precision                      | context-dependent             |
| Transport precision                    | context-dependent             |
| Execution precision                    | context-dependent             |
| Accumulation precision                 | operation-dependent           |

These are defaults, not a requirement that every value use the same representation.

---

# 62. Fundamental Invariants

The following invariants are normative.

### NUM-001 — Semantic Primacy

Numeric meaning shall be defined independently of physical representation.

### NUM-002 — Representation Independence

Changing numeric representation shall not inherently change semantic identity.

### NUM-003 — Canonical Computation

`f32` is the default canonical general-purpose real computation representation unless a stronger requirement exists.

### NUM-004 — Explicit Normalization

Normalization shall be semantically explicit.

### NUM-005 — Explicit Quantization

Quantization shall be semantically explicit.

### NUM-006 — Explicit Loss

Lossy numerical transformations shall be identifiable and bounded.

### NUM-007 — Saturating Narrowing

Narrowing shall saturate by default rather than wrap.

### NUM-008 — Deterministic Rounding

Nearest-even shall be the default deterministic rounding mode.

### NUM-009 — Error Awareness

Numerical transformations shall be analysable in terms of applicable error.

### NUM-010 — Precision Awareness

Precision requirements may constrain compilation and execution.

### NUM-011 — Conversion Visibility

Representation conversions shall remain visible to semantic analysis.

### NUM-012 — No Numeric Shadow IR

SCR shall not create an independent numeric IR or type system outside MLIR.

### NUM-013 — Global Optimisation

Numeric representation shall be optimised across computational graphs where possible.

### NUM-014 — Domain Consistency

SCR domains shall use common numeric semantics unless a justified semantic exception exists.

### NUM-015 — Provider Neutrality

Providers shall implement rather than redefine numeric semantics.

### NUM-016 — Hardware Independence

Hardware characteristics may influence representation selection but shall not define semantic meaning.

### NUM-017 — Information Preservation

Required semantic information shall survive numerical transformations.

### NUM-018 — Explicit Invalidity

NaN, infinity, overflow, underflow, and invalid values shall have explicit semantics where relevant.

### NUM-019 — Semantic Compatibility

Numeric compatibility shall be determined by semantic requirements rather than physical type equality.

### NUM-020 — Whole-System Optimisation

Numeric representation decisions shall consider the computational system as a whole.

---

# 63. Relationship to SCR Architecture

This standard is subordinate to the fundamental architectural principles established in `004_ARCHITECTURE.md` while providing normative detail for numerical semantics.

The relationship is:

```text
003_PROJECT_MANDATE.md
        ↓
004_ARCHITECTURE.md
        ↓
005_NUMERIC_SEMANTICS.md
        ↓
Domain Semantic Definitions
        ↓
MLIR Representation
        ↓
Providers
        ↓
Runtime
```

`004_ARCHITECTURE.md` establishes that SCR has no independent IR.

This document applies that principle specifically to numerical semantics.

---

# 64. Relationship to the Semantic Library

The semantic library shall use this standard as its common numerical foundation.

Individual definitions should therefore avoid repeatedly specifying:

```text
f32 conversion rules
i8 scaling rules
rounding rules
saturation rules
normalization formulas
```

when the platform standard already establishes them.

Definitions should instead specify the semantic requirements that differ.

For example:

```text
SignalAmplitude
    domain: [-1,+1]
    tolerance: ±0.001
```

rather than embedding an entire implementation-specific conversion scheme.

---

# 65. Relationship to Runtime Optimisation

The runtime may dynamically change numerical representation where:

```text
semantic correctness is preserved
```

and:

```text
resource or execution efficiency improves.
```

This may include:

```text
f32 → f16
f32 → i16
f32 → i8
i8 → f32
```

at appropriate computational boundaries.

The runtime should prefer to keep values in their existing representation when no semantic or execution benefit exists in converting them.

---

# 66. Relationship to MLIR

Numeric semantics shall ultimately be represented and manipulated through MLIR.

Potential mechanisms include:

```text
MLIR builtin numeric types
SCR dialect types
SCR attributes
MLIR interfaces
MLIR traits
quantization operations
conversion operations
analysis passes
canonicalisation
lowering passes
```

The precise implementation is an architectural and engineering concern.

The semantic contract defined here is normative independently of its implementation.

---

# 67. Future Extensions

This standard may be extended to cover:

* mixed-precision automatic differentiation;
* interval arithmetic;
* uncertainty propagation;
* probabilistic numeric types;
* uncertainty-aware quantization;
* learned quantization;
* adaptive precision;
* dynamic error budgets;
* energy-aware precision selection;
* hardware-specific numeric formats;
* compressed numerical representations;
* sparse numerical encodings.

Such extensions must preserve the fundamental principles established here.

In particular, they must not introduce an independent numeric IR or undermine representation independence.

---

# 68. Design Objective

The ultimate purpose of this standard is not merely numerical consistency.

It is **system-wide computational efficiency without semantic compromise**.

SCR should be capable of determining:

```text
What does this value mean?
        ↓
What range does it require?
        ↓
What precision does it require?
        ↓
What error can it tolerate?
        ↓
Where must high precision be used?
        ↓
Where can precision be reduced?
        ↓
Where can quantization occur?
        ↓
Where can conversion be avoided?
        ↓
What representation minimises resource consumption?
        ↓
Which provider can execute it efficiently?
        ↓
Which hardware representation is optimal?
```

The objective is therefore:

> **Preserve the required semantics while minimising unnecessary numerical precision, memory, bandwidth, conversion, and computational cost.**

---

# 69. Final Constitutional Statement

The following statement is normative:

> **SCR numeric semantics define the meaning, domain, range, precision requirements, validity constraints, and acceptable error of numerical quantities independently of their physical representation. Numeric representations are implementation resources selected and transformed according to semantic requirements and execution conditions.**

And:

> **SCR shall optimise numerical representation globally across computational graphs and architectural boundaries, rather than requiring individual domains, applications, or providers to independently perform redundant normalization, quantization, conversion, and precision management.**

And finally:

> **There is no separate SCR numeric IR. Numerical semantics are represented, analysed, transformed, and lowered through MLIR and its extensibility mechanisms.**

This establishes numeric representation as a **first-class semantic concern of the SCR platform**, rather than an implementation convention.
