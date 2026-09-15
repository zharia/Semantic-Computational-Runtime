# SCR Math Library Specification

**Document:** `lib/202_Math/101_spec.md`
**Status:** Normative
**Version:** 0.0.1
**Domain:** Math
**Library ID:** `SCR.Math`
**Specification Class:** Semantic Library Specification

---

# 1. Purpose

The SCR Math library defines the foundational mathematical semantics used throughout the Semantic Computational Runtime.

Math provides the semantic abstractions required to represent and transform mathematical quantities, structures, relationships, and operations.

The purpose of the Math library is not merely to provide arithmetic functions.

It establishes a common mathematical semantic layer upon which higher SCR domains may build.

These include:

* Data;
* Tensor;
* Field;
* Geometry;
* Topology;
* Spatial;
* Physics;
* Dynamics;
* Simulation;
* Neural;
* System.

The fundamental distinction is:

```text
Mathematical Meaning
        ≠
Numerical Representation
        ≠
Hardware Arithmetic
```

Math defines the first.

Lower layers determine how that mathematics is represented and executed.

---

# 2. Architectural Position

Math depends upon Core and Data where required.

```text
SCR
│
├── 101_Core
│
├── 201_Data
│
├── 202_Math
│
├── 203_Tensor
├── 204_Field
├── 205_Graph
├── ...
```

The primary dependency relationship is:

```text
Math
 ├── Core
 └── Data
```

Higher-level mathematical domains may depend upon Math.

For example:

```text
Tensor
   ↓
Math

Physics
   ↓
Math

Geometry
   ↓
Math
```

Math must not unnecessarily depend upon those higher-level domains.

---

# 3. Fundamental Principle

The fundamental principle of SCR Math is:

> **Mathematical objects and transformations are semantic structures whose meaning must remain independent of their numerical or physical representation.**

Thus:

```text
Real Number
    ≠
IEEE-754 Float
```

and:

```text
Vector
    ≠
Array of Floats
```

and:

```text
Matrix
    ≠
Contiguous Memory Buffer
```

A particular representation may implement a mathematical object, but it does not define the object's mathematical meaning.

---

# 4. Mathematical Semantics

Math provides semantic definitions for mathematical structures and operations.

These may include:

```text
Scalar
Number
Quantity
Constant
Vector
Matrix
Set
Relation
Function
Sequence
Series
Polynomial
Expression
Equation
Transformation
```

The precise inventory evolves through individual Math subdomain specifications.

A mathematical primitive must be introduced only when its semantic distinction is necessary.

---

# 5. Mathematical Object Model

A mathematical object may be described by:

```text id="2r8a0m"
Identity
Type
Domain
Codomain
Value
Structure
Dimensions
Constraints
Operations
Relationships
```

Not every mathematical object has every property.

For example:

```text
scalar
```

may have a value and type without explicit dimensional structure.

A:

```text
function
```

may instead have:

```text
domain
codomain
mapping
constraints
```

The semantic object model must preserve these distinctions.

---

# 6. Number Semantics

Math must distinguish mathematical number systems from machine representations.

Relevant mathematical structures include:

```text
Natural numbers
Integers
Rational numbers
Real numbers
Complex numbers
```

Other structures may be introduced where justified.

A machine representation such as:

```text
UInt8
Int64
Float32
Float64
```

is a representation of a mathematical domain or approximation thereof.

It must not automatically be treated as identical to the mathematical domain.

---

# 7. Numeric Semantics

SCR implementations must explicitly define numerical semantics.

Where an operation is approximate, the approximation must not be silently represented as exact mathematics.

For example:

```text
real-valued semantic quantity
        ↓
Float32 representation
```

implies a representation boundary.

Relevant properties may include:

* precision;
* range;
* rounding;
* overflow;
* underflow;
* NaN;
* infinity;
* signed zero;
* approximation error.

These properties belong to the numerical representation contract where applicable.

---

# 8. SCR Numeric Normalization

Where SCR establishes normalized numerical domains, those semantics must be explicitly represented.

The established SCR normalized numeric convention is:

```text
[-1, +1]
```

where applicable.

Normalization is not universally imposed upon all mathematical quantities.

It is a semantic convention for numerical domains where normalized representation is appropriate.

A value represented within `[-1,+1]` must not automatically be assumed to be dimensionless or physically normalized.

---

# 9. Scalars

A scalar is a mathematical quantity with no vectorial or higher-order structure within the applicable mathematical space.

Examples include:

```text
3
-0.5
π
i
```

depending upon the mathematical domain.

A scalar's mathematical type and numerical representation remain distinct.

---

# 10. Quantities

A quantity represents a value associated with a defined mathematical or physical dimension.

Math may provide the generic mathematical foundation for quantities.

Physical units and dimensional analysis may be refined by Physics or another appropriate domain.

The architecture must preserve:

```text
numeric value
      ≠
quantity
      ≠
physical measurement
```

unless a domain specification explicitly establishes their equivalence.

---

# 11. Vectors

A vector is a mathematical object belonging to a vector space or equivalent structure.

A vector must not be defined merely as an array.

Conceptually:

```text id="ml0q8r"
v ∈ V
```

where `V` is the applicable vector space.

Relevant semantic properties may include:

* dimensionality;
* scalar field;
* basis;
* components;
* addition;
* scalar multiplication;
* equality;
* norm where defined;
* inner product where defined.

Representation may be:

```text
array
SIMD register
GPU buffer
sparse structure
distributed object
```

without changing the mathematical object.

---

# 12. Matrices

A matrix is a structured mathematical object representing a rectangular array or linear transformation according to its semantic definition.

A matrix must not be equated with its memory layout.

For example:

```text
row-major
column-major
tiled
sparse
distributed
```

are representations.

Mathematical matrix semantics include, where applicable:

* dimensions;
* elements;
* addition;
* multiplication;
* transpose;
* determinant;
* inverse;
* decomposition.

The applicability of each operation depends upon the matrix's mathematical properties.

---

# 13. Tensors

Tensor semantics belong primarily to the Tensor domain.

Math may provide mathematical foundations required by Tensor, including:

* scalar algebra;
* vector spaces;
* multilinear operations;
* transformations.

Math must not duplicate the Tensor semantic model.

The intended relationship is:

```text
Math
  ↓
Tensor
```

---

# 14. Sets

Sets are mathematical structures based on membership.

Conceptually:

```text
x ∈ S
```

Set semantics include:

* membership;
* union;
* intersection;
* difference;
* inclusion;
* cardinality where defined.

Data collections may implement set-like structures, but:

```text
Data Set
    ≠
Mathematical Set
```

unless the semantic contract explicitly identifies them.

---

# 15. Relations

Math provides general mathematical relation semantics.

A relation establishes a correspondence between elements of mathematical domains.

Conceptually:

```text
R ⊆ A × B
```

Relations may be:

* unary;
* binary;
* n-ary;
* directed;
* symmetric;
* reflexive;
* transitive;
* equivalence relations.

Graph and topology domains may build richer computational representations upon these mathematical semantics.

---

# 16. Functions

A mathematical function represents a mapping:

```text id="gub9gk"
f : A → B
```

A function has:

* domain;
* codomain;
* mapping;
* applicable constraints.

The implementation of a function may be computational.

The semantic function itself is not equivalent to a function pointer, closure object, or machine-code address.

This distinction is fundamental to SCR.

---

# 17. Function Graphs

SCR treats computational functions as semantic structures.

A function can therefore be represented as:

```text id="w2m2jp"
Inputs
   ↓
Transformation
   ↓
Outputs
```

Its complete semantic structure may include:

```text id="2u5z3j"
inputs
outputs
constraints
dependencies
effects
relationships
implementation
```

Consequently:

> **A function signature and its input/output relationship are themselves graphable semantic structures.**

The Graph and Core domains provide the appropriate structural mechanisms.

---

# 18. Expressions

An expression represents a mathematical construction from one or more operands.

For example:

```text
a + b
```

may be represented semantically as:

```text id="8j98c7"
      +
     / \
    a   b
```

An expression may therefore be represented as a semantic graph.

Expression evaluation is distinct from expression representation.

---

# 19. Operators

Operators represent mathematical transformations.

Examples include:

```text
+
-
*
/
^
√
log
exp
sin
cos
```

Operators must have explicitly defined domains and applicable constraints.

For example, division requires a non-zero divisor under ordinary field semantics.

The operator itself is semantic.

Its implementation may vary.

---

# 20. Algebraic Structures

Math should provide common algebraic structures where they are required by multiple SCR domains.

Potential structures include:

```text
Magma
Semigroup
Monoid
Group
Ring
Field
Vector Space
```

The exact supported structure hierarchy must be established through implementation specifications and should not be duplicated across dependent domains.

An algebraic structure is defined by its operations and laws, not merely by the data type used to store its elements.

---

# 21. Algebraic Laws

Where an algebraic structure requires laws, those laws are semantic invariants.

For example, an additive group requires applicable properties such as:

```text
closure
associativity
identity
inverse
```

The implementation should distinguish:

```text
operation exists
```

from:

```text
operation satisfies the required algebraic law
```

This distinction is important for generic mathematical programming.

---

# 22. Constants

Mathematical constants are semantic objects.

Examples include:

```text
π
e
φ
i
```

A constant's representation may be approximate.

For example:

```text
π
```

is not semantically equivalent to a particular finite floating-point approximation.

The approximation is a representation.

---

# 23. Precision and Approximation

Math must explicitly distinguish exact and approximate operations.

Conceptually:

```text
Exact Mathematics
       ↓
Representation
       ↓
Approximation
```

An implementation may use approximate arithmetic while preserving an explicitly defined error model.

Where error bounds matter, they must be part of the operation's semantic contract.

---

# 24. Equality

Mathematical equality and machine equality must not be assumed to be identical.

Possible relationships include:

```text
exact equality
approximate equality
structural equality
semantic equivalence
representation equality
```

For floating-point representations, numerical equality may require explicit tolerance or equivalence semantics.

The applicable equality relation must be defined by the mathematical type or operation.

---

# 25. Ordering

Ordering relations include, where applicable:

```text
<
≤
=
≥
>
```

Ordering requires an applicable mathematical structure.

Complex numbers, for example, do not acquire a canonical total ordering merely because their implementation permits comparison.

Implementation convenience must not introduce mathematical semantics.

---

# 26. Dimensions

Mathematical objects may have dimensions.

Dimensions may refer to:

* vector-space dimensionality;
* matrix dimensions;
* tensor rank/shape;
* coordinate dimensions.

These concepts must remain distinct.

For example:

```text
matrix shape
    ≠
physical dimension
    ≠
vector-space dimension
```

The appropriate domain owns the detailed semantics.

---

# 27. Coordinate Systems

Math provides mathematical foundations for coordinate transformations.

Coordinate-system semantics may be refined by Geometry and Spatial.

The architecture must distinguish:

```text
mathematical space
      ≠
coordinate representation
      ≠
physical location
```

A coordinate transformation changes representation of an object without necessarily changing the underlying mathematical entity.

---

# 28. Transformations

A mathematical transformation maps one mathematical structure into another.

Conceptually:

```text id="e6l47t"
X
│
│ T
▼
Y
```

Examples include:

```text
translation
rotation
scaling
projection
reflection
linear transformation
nonlinear transformation
```

Geometry and Spatial may specialize these transformations.

Math provides the general mathematical semantics.

---

# 29. Composition

Mathematical operations should support composition where their domains and codomains permit it.

For functions:

```text
f : A → B
g : B → C

g ∘ f : A → C
```

Composition is fundamental to SCR because semantic computation is itself compositional.

A composition should preserve the semantic constraints of its constituent operations.

---

# 30. Inverses

Where a mathematical operation defines an inverse, the inverse must be represented semantically.

An implementation must not assume invertibility merely because a numerical algorithm produces a result.

For example:

```text
A⁻¹
```

exists only under the applicable mathematical conditions.

Verification should establish those conditions where practical.

---

# 31. Limits and Undefined Operations

Mathematical domains contain operations that may be undefined for particular inputs.

Examples include:

```text
division by zero
logarithm of invalid argument
square root outside applicable domain
singular matrix inverse
```

SCR must represent these as semantic domain constraints rather than relying solely upon hardware behaviour.

---

# 32. Numerical Exceptions

Hardware numerical behaviour may include:

```text
NaN
∞
overflow
underflow
rounding
```

These are representation/runtime phenomena unless the mathematical type explicitly includes them.

A mathematical real-number operation should not silently acquire IEEE-754 exceptional semantics merely because Float32 is used for its implementation.

---

# 33. Mathematical Domains

A mathematical operation must define its applicable domain.

Conceptually:

```text
operation
   │
   ├── domain
   ├── codomain
   ├── constraints
   └── transformation
```

This information is important for:

* verification;
* generic programming;
* compiler optimization;
* error reporting;
* symbolic transformation.

---

# 34. Symbolic Mathematics

Where practical, Math may represent mathematical expressions symbolically.

For example:

```text id="fym2ce"
f(x) = x² + 2x + 1
```

may be represented as semantic structure rather than immediately evaluated.

Symbolic and numerical representations should remain distinct.

```text
Symbolic Expression
       ≠
Numerical Result
```

The same semantic expression may have multiple evaluation strategies.

---

# 35. Numerical Mathematics

Numerical implementations provide approximations to mathematical operations.

They must identify relevant properties including, where applicable:

* precision;
* error;
* stability;
* convergence;
* conditioning;
* deterministic behaviour.

A numerical implementation must not silently claim exact mathematical semantics where those semantics cannot be guaranteed.

---

# 36. Algorithms

Math algorithms are implementations of mathematical transformations.

Examples may include:

```text
sorting
search
factorization
linear algebra
root finding
integration
differentiation
optimization
```

An algorithm is not itself a mathematical primitive merely because it computes a mathematical result.

Where appropriate:

```text
Mathematical Operation
        ↓
Algorithm
        ↓
Implementation
```

must remain distinguishable.

---

# 37. Determinism

A mathematically deterministic operation must have a deterministic semantic result for equivalent inputs.

An implementation may use:

* parallel execution;
* GPU execution;
* distributed computation;
* approximation;

provided the semantic contract remains satisfied.

If numerical nondeterminism is possible, it must be explicitly documented.

---

# 38. Parallel Mathematics

Mathematical operations may be parallelizable.

Parallelizability is an execution property, not necessarily a mathematical property.

For example:

```text
vector addition
```

has mathematical semantics independent of whether it executes:

```text
single core
SIMD
GPU
distributed system
```

The implementation should expose parallelism without changing the mathematical abstraction.

---

# 39. Numerical Stability

Numerical stability is an implementation property associated with approximating mathematical operations.

Where stability affects correctness guarantees, the relevant stability properties must be represented in the implementation contract.

The semantic operation remains the mathematical transformation.

---

# 40. Math and Data

Data provides general information-bearing structures.

Math provides mathematical meaning.

```text id="p8khc9"
Data
  ↓
representation of mathematical information

Math
  ↓
mathematical semantics
```

A numerical array is therefore Data.

Its interpretation as a vector, matrix, or tensor is Math/Tensor semantics.

---

# 41. Math and Tensor

Tensor depends upon mathematical structures defined by Math.

```text id="n3i2l5"
Math
  ↓
vector spaces / algebra / operations
  ↓
Tensor
```

Tensor must not duplicate foundational mathematical definitions already established here.

---

# 42. Math and Geometry

Geometry depends upon mathematical structures for:

* spaces;
* coordinates;
* vectors;
* transformations;
* distances;
* angles;
* algebraic structures.

The Geometry domain defines geometric ontology and operations.

Math defines their mathematical foundations.

---

# 43. Math and Physics

Physics uses mathematical structures to describe physical systems.

The architecture should preserve:

```text id="7p7s9k"
Mathematical quantity
        ≠
Physical quantity
```

Math defines the mathematical object.

Physics assigns physical meaning.

---

# 44. Math and Dynamics

Dynamics builds mathematical descriptions of change over time.

Math provides:

* functions;
* transformations;
* differential structures where implemented;
* vectors;
* matrices;
* numerical methods.

Dynamics defines the semantic interpretation of those structures as evolving systems.

---

# 45. Math and Neural

Neural computation may use:

```text
vectors
matrices
functions
optimization
probability
statistics
```

Math provides the mathematical foundations.

Neural defines the domain-specific semantic interpretation.

---

# 46. Representation Independence

The following distinctions are normative:

```text id="0xovp9"
Mathematical Object
       ≠
MLIR Value
       ≠
Mojo Value
       ≠
Memory Layout
       ≠
Hardware Register
```

A particular representation may implement the object.

It does not define its mathematical meaning.

---

# 47. MLIR Implementation

Math semantic primitives must be represented through SCR MLIR where they constitute compiler-visible SCR semantics.

MLIR representations may include:

* mathematical types;
* operations;
* attributes;
* expressions;
* constraints;
* algebraic properties;
* transformations.

MLIR verification should enforce applicable mathematical constraints.

Compiler lowering may replace one numerical representation with another where semantic guarantees are preserved.

---

# 48. Mojo API

User-facing mathematical capabilities must be exposed through idiomatic Mojo.

For example:

```mojo id="sl2k1g"
let a = Vector(...)
let b = Vector(...)
let c = a + b
```

The user should not normally need to construct the corresponding MLIR operations manually.

The Mojo API is a projection of the Math semantic model.

It is not a separate mathematical implementation.

The project-wide relationship between MLIR and Mojo is defined by:

`docs/architecture/101_language_and_api.md`

---

# 49. Generic Mathematical Programming

Where practical, Math should permit generic algorithms over mathematical structures.

For example, an operation may be expressed against an abstract algebraic requirement rather than a concrete machine type.

Conceptually:

```text id="x7f1je"
Algorithm
   ↓
requires algebraic structure
   ↓
concrete implementation
```

This allows higher-level SCR domains to reuse mathematical algorithms without duplicating semantics.

---

# 50. Typeclass / Trait Semantics

Where Mojo mechanisms support traits or equivalent abstraction mechanisms, mathematical requirements may be represented through them.

However:

> **A Mojo trait is not automatically the semantic definition of a mathematical structure.**

The mathematical contract remains defined by SCR semantics.

Mojo mechanisms provide an implementation and programming interface for that contract.

---

# 51. Algebraic Laws and Verification

Where mathematical laws are computationally verifiable, SCR should support their validation.

Examples include:

```text
a + b = b + a
(a + b) + c = a + (b + c)
a × 1 = a
```

Verification may be:

* symbolic;
* formal;
* exhaustive over finite domains;
* property-based;
* numerical;
* runtime.

The evidence level must be recorded explicitly.

Empirical testing must not automatically be described as formal proof.

---

# 52. Exactness

Math should distinguish at least:

```text
Exact
Approximate
Symbolic
Numerical
```

representations where relevant.

An operation should not silently change exactness semantics.

For example:

```text
exact rational
      ↓
Float32
```

is a semantic representation change that may introduce approximation.

---

# 53. Units and Dimensions

Where units are required, the system must distinguish:

```text
dimension
unit
magnitude
representation
```

For example:

```text
5 metres
```

is not simply the floating-point value:

```text
5.0
```

The dimensional semantics belong to the applicable quantity/unit model.

Math provides the general mathematical foundations without prematurely binding the entire Math domain to a physical-unit system.

---

# 54. Constants and Precision

Constants should expose an appropriate semantic precision.

For example:

```text
π
```

may be represented symbolically or numerically.

A numerical approximation must declare its representation characteristics.

The mathematical constant remains independent of that representation.

---

# 55. Mathematical Integrity

Math transformations must preserve applicable mathematical invariants.

Relevant integrity properties include:

```text
domain validity
type validity
dimensional validity
algebraic validity
structural validity
numerical validity
precision guarantees
```

Where an approximation is unavoidable, the error model must be explicit.

---

# 56. Primitive Reuse

Before introducing a new Math primitive:

```text id="c7l9i0"
Can an existing Core, Data, or Math primitive
represent the requirement without semantic distortion?
```

If yes:

> Reuse it.

If no:

> Identify the semantic gap.

Then determine whether the capability belongs in:

```text
Core
Data
Math
another domain
provider
application composition
```

A new primitive must not be introduced merely to create a convenient implementation type.

---

# 57. Library Development Model

Math development follows:

```text id="8omr86"
Describe
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
Optimize / Lower
   ↓
Validate
```

The stages must remain distinguishable.

In particular:

```text
implemented
    ≠
verified
    ≠
proven
```

---

# 58. Verification Strategy

Math verification should use the strongest appropriate method.

Possible methods include:

```text
formal proof
symbolic verification
property-based testing
exhaustive finite-domain testing
numerical validation
differential testing
reference implementation comparison
```

The verification method must be appropriate to the mathematical claim being made.

---

# 59. Reference Implementations

Where an optimized mathematical implementation exists, a simpler reference implementation may be maintained for validation.

Conceptually:

```text
Reference Mathematics
        ↓
expected semantic result
        ↕
Optimized Implementation
```

A reference implementation is a verification mechanism.

It is not necessarily the canonical runtime implementation.

---

# 60. Provider Independence

Math must not be defined in terms of:

```text
BLAS
CUDA
LLVM
GPU
CPU
```

or any other specific provider.

Providers may implement Math operations.

For example:

```text
SCR Math
   ↓
provider
   ├── BLAS
   ├── CUDA
   └── CPU implementation
```

The provider may optimize execution without redefining the mathematical operation.

---

# 61. Hardware Acceleration

Hardware acceleration is an implementation concern unless explicitly promoted into a semantic requirement.

The same mathematical operation may execute through:

```text
scalar CPU
SIMD
GPU
FPGA
distributed system
```

The semantic result must remain governed by the mathematical contract.

---

# 62. Numerical Representation Boundary

The boundary between mathematical semantics and numerical execution is explicit:

```text id="1knu4a"
Mathematical Operation
        ↓
Numerical Representation
        ↓
Algorithm
        ↓
Hardware Execution
```

Each layer may introduce constraints.

Those constraints must not silently redefine the mathematical operation.

---

# 63. API Traceability

Every public Mojo mathematical operation should be traceable to:

```text id="wqx09h"
Math semantic definition
        ↓
MLIR representation
        ↓
verification
        ↓
Mojo projection
```

This traceability should be maintained through documentation, tests, metadata, or other repository mechanisms as appropriate.

---

# 64. Architectural Invariants

### MATH-I001 — Mathematical Authority

Mathematical meaning is defined by SCR mathematical semantics, not by machine representation.

### MATH-I002 — Representation Independence

Mathematical objects are distinct from their numerical and physical representations.

### MATH-I003 — Domain Validity

Operations must respect their mathematical domains and applicable constraints.

### MATH-I004 — Explicit Approximation

Approximate numerical implementations must not silently claim exact mathematical semantics.

### MATH-I005 — Algebraic Integrity

Operations belonging to an algebraic structure must satisfy the applicable structural laws.

### MATH-I006 — Equality Integrity

Mathematical equality must not be conflated with machine or byte equality.

### MATH-I007 — Ordering Integrity

An ordering must not be introduced merely because a representation supports comparison.

### MATH-I008 — Transformation Integrity

Mathematical transformations must preserve applicable mathematical invariants.

### MATH-I009 — Provider Independence

Mathematical semantics must not depend upon a particular execution provider.

### MATH-I010 — MLIR Canonicality

The canonical compiler representation of SCR mathematical semantics is MLIR.

### MATH-I011 — Mojo Projection

Mojo exposes Math semantics without establishing an independent mathematical model.

### MATH-I012 — Primitive Reuse

Existing semantic primitives must be reused where sufficient.

### MATH-I013 — Explicit Extension

New mathematical primitives require an identified semantic gap.

### MATH-I014 — Verification

Mathematical claims must have explicit verification criteria appropriate to their strength.

### MATH-I015 — Function Semantics

A mathematical function is distinct from its implementation as executable code.

---

# 65. Completion Criteria

A user-facing Math capability is considered complete only when the applicable requirements have been satisfied:

```text
[ ] Mathematical meaning defined
[ ] Specification documented
[ ] Correct domain placement established
[ ] Applicable domain/codomain constraints defined
[ ] MLIR representation implemented
[ ] MLIR verification implemented
[ ] Mathematical invariants identified
[ ] Appropriate verification implemented
[ ] Mojo API implemented where user-facing
[ ] Mojo API is idiomatic
[ ] Mojo tests implemented
[ ] Numerical representation semantics documented where applicable
[ ] Runtime/provider implementation completed where required
[ ] End-to-end validation completed where required
[ ] Status recorded
```

Compiler-internal mathematical mechanisms may omit the public Mojo stage where explicitly justified.

---

# 66. Final Principle

The Math library exists to ensure that mathematical meaning is expressed once and reused throughout SCR.

Its essential architecture is:

```text
                 Mathematical Semantics
                          │
             ┌────────────┼────────────┐
             │            │            │
          Numbers      Functions    Structures
             │            │            │
             └────────────┼────────────┘
                          ▼
                         MLIR
                          │
                verification / lowering
                          │
                          ▼
                     Mojo API
                          │
                          ▼
                   SCR Application
                          │
                          ▼
                Runtime / Provider
```

The governing rule is:

> **Define mathematics semantically, represent it canonically in MLIR, expose it naturally through Mojo, and permit numerical and hardware implementations to vary without changing the mathematical meaning.**

Math provides the mathematical foundation.

Data provides information-bearing structure.

Core provides the foundational semantic primitives.

Higher-level SCR domains compose these capabilities into increasingly rich semantic systems.
