# Semantic Computational Runtime

## Project Background, Origin and Rationale

**Document:** SCR-BACKGROUND
**Status:** Foundational Project Documentation
**Audience:** Developers, researchers, architects, AI agents, contributors
**Project:** Semantic Computational Runtime (SCR)

---

# 1. Executive Summary

The Semantic Computational Runtime (SCR) emerged from a long-running attempt to construct a computational environment capable of representing and executing increasingly complex simulations, information systems, physical models, spatial structures, neural computation and interacting agents.

The original problem appeared to be a simulation-engineering problem.

It gradually became clear that the deeper problem was different:

> **Modern computational systems are fragmented by implementation technology rather than organised around computational meaning.**

A developer who wants to construct a sophisticated computational system may simultaneously need to understand:

* numerical libraries
* physics engines
* geometry libraries
* graph libraries
* spatial indexing systems
* tensor frameworks
* neural-network libraries
* rendering engines
* GPU APIs
* CPU vectorisation
* messaging systems
* distributed execution
* memory-management systems
* storage systems
* scheduling systems
* hardware-specific optimisations

Each subsystem has its own abstractions, data models, APIs and execution assumptions.

The result is an enormous integration burden.

SCR exists to attack this problem at a more fundamental level.

Rather than asking developers to learn and compose hundreds of implementation APIs, SCR seeks to provide a **common semantic computational language** in which concepts such as:

```text
Field
Graph
Geometry
Morphology
Force
Dynamics
Agent
Perception
Neural Model
Control
Simulation
Render
Stream
```

can be expressed as composable computational abstractions.

The system then determines how those abstractions are represented, transformed, implemented and executed.

This led naturally to MLIR.

Rather than building another compiler or another intermediate representation, SCR uses MLIR as its foundational infrastructure and extends it with a general-purpose ecosystem of computational semantic dialects, interfaces, transformations, analyses and providers.

The resulting project can be understood as:

> **A common language runtime for computational semantics.**

---

# 2. Where the Project Came From

SCR did not originate as an attempt to design a generic compiler framework.

It evolved from work on a much more concrete problem: constructing a sophisticated simulation environment capable of representing a world containing information, physical processes, spatial structures, morphology, agents, rendering, streaming and adaptive computation.

As the architecture developed, several recurring problems became apparent.

---

# 3. The Simulation Problem

A sufficiently ambitious simulation is not a single algorithm.

It is a composition of fundamentally different computational domains.

A realistic computational world may involve:

```text
information
    ↓
fields
    ↓
spatial relationships
    ↓
geometry
    ↓
topology
    ↓
morphology
    ↓
physics
    ↓
dynamics
    ↓
agents
    ↓
perception
    ↓
neural computation
    ↓
decision/control
    ↓
rendering
    ↓
streaming
```

These domains are deeply interconnected.

For example, a simulated agent may:

1. occupy a spatial position;
2. observe a field;
3. perceive geometry;
4. construct an internal representation;
5. perform neural inference;
6. select an action;
7. invoke a control system;
8. apply a physical force;
9. alter a dynamical state;
10. modify morphology;
11. produce a new visual representation;
12. emit telemetry.

The computational chain crosses many traditional software boundaries.

The question therefore became:

> Why should these domains have to be implemented as completely separate computational universes?

---

# 4. The Integration Problem

Existing libraries are exceptionally good at solving individual problems.

Examples include:

* physics engines
* linear algebra libraries
* computational geometry libraries
* voxel libraries
* spatial indexing systems
* rendering systems
* neural computation frameworks
* messaging systems
* GPU runtimes

The problem is not that these systems are inadequate.

The problem is that they generally expose **implementation-level abstractions**.

One system might represent a body as a particular C++ object.

Another might represent geometry as a particular mesh structure.

Another might represent a field as a particular tensor.

Another might represent a spatial index using a particular tree.

Another might represent rendering using a particular scene graph.

The developer is responsible for connecting these incompatible representations.

This creates an integration graph that grows rapidly with system complexity.

---

# 5. The Deeper Observation

The project eventually reached a more fundamental observation:

> Many apparently unrelated computational systems share common semantic structures.

Consider:

```text
physics.body
agent
neural.layer
render.object
```

They are obviously different concepts.

But they may all have:

```text
identity
state
properties
relationships
transformation
observation
composition
```

Similarly:

```text
physics.dynamics
agent.behaviour
neural.recurrence
simulation.process
```

all involve some notion of:

```text
state
→
transition
→
new state
```

Likewise:

```text
geometry
morphology
field
graph
topology
```

all represent structured information over some domain.

And:

```text
neural network
physics system
agent population
simulation
stream pipeline
```

are all compositions of computational transformations.

This suggested that the missing abstraction was not another domain-specific library.

It was a **semantic layer beneath the domains**.

---

# 6. From APIs to Semantics

The critical conceptual shift was:

```text
OLD MODEL

Application
   ↓
Library API
   ↓
Implementation
   ↓
Hardware
```

SCR seeks to establish:

```text
NEW MODEL

Application
   ↓
Semantic abstraction
   ↓
Semantic interfaces
   ↓
Semantic composition
   ↓
Compiler transformations
   ↓
Provider selection
   ↓
Hardware-specific implementation
```

The application therefore expresses intent rather than implementation.

For example:

```text
dynamics.integrate
```

does not mean:

```text
call Chrono
```

It means:

> Perform a valid integration of this dynamical system according to its declared semantics and constraints.

The compiler/runtime can then determine whether the best implementation is:

```text
Chrono
native numerical kernel
GPU kernel
generated MLIR
LLVM
specialised solver
another provider
```

---

# 7. Why Existing Libraries Are Still Important

SCR does not attempt to replace existing computational libraries.

Quite the opposite.

The existing open-source ecosystem represents an enormous body of mature engineering.

The objective is to make those systems **providers of semantic capabilities**.

Conceptually:

```text
                Semantic Capability
                        │
          ┌─────────────┼─────────────┐
          │             │             │
       Provider A    Provider B    Provider C
          │             │             │
        CPU          GPU          Accelerator
```

For example:

```text
physics.integrate
```

could potentially be implemented by:

```text
Chrono
custom solver
GPU kernel
generated solver
```

while remaining the same semantic operation from the application's perspective.

This transforms existing libraries from competing application-level abstractions into interchangeable implementation resources.

---

# 8. Why MLIR Became Central

At this point the project encountered a second problem.

A semantic layer requires a representation capable of expressing:

* types
* operations
* relationships
* regions
* transformations
* constraints
* interfaces
* analyses
* multiple abstraction levels
* progressive lowering
* hardware-specific specialisation

Building such infrastructure independently would effectively mean constructing another compiler framework.

MLIR already provides precisely the extensibility mechanism required.

MLIR supports:

* custom dialects
* custom operations
* custom types
* attributes
* interfaces
* verification
* rewriting
* canonicalisation
* dialect conversion
* transformation infrastructure
* multiple abstraction levels
* LLVM/GPU/vector and other lowering paths

Therefore the project made a fundamental architectural decision:

> **Do not build a second IR. Extend MLIR.**

The Semantic Library is consequently an MLIR extension ecosystem.

---

# 9. Semantic MLIR

The project originally distinguished between a "Semantic IR" and MLIR.

That distinction is no longer necessary.

The semantic representation **is MLIR**.

More precisely:

```text
Semantic Library
       ↓
Semantic MLIR dialects
       ↓
MLIR infrastructure
       ↓
MLIR transformations
       ↓
MLIR lowerings
       ↓
Executable representations
```

SCR therefore does not introduce a separate compiler architecture alongside MLIR.

It uses MLIR's dialect system to construct a higher-level computational semantic universe.

---

# 10. The Semantic Library

The Semantic Library is the core intellectual product of SCR.

It defines a vocabulary of computational meaning.

The initial semantic domains include:

```text
Core
Math
Data
Field
Graph
Geometry
Topology
Spatial
Morphology
Physics
Dynamics
Simulation
Neural
Learning
Optimization
Agent
Control
Perception
Render
Stream
```

These are not intended to become isolated libraries.

They form a connected semantic system.

---

# 11. Progressive Abstraction

The library is intentionally constructed from lower-level abstractions toward higher-level concepts.

The conceptual hierarchy is:

```text
L0 — Mathematical semantics
       ↓
L1 — Computational semantics
       ↓
L2 — Structural semantics
       ↓
L3 — Domain semantics
       ↓
L4 — Composite models
       ↓
L5 — System semantics
```

For example:

```text
vector
  ↓
field
  ↓
physical field
  ↓
dynamical system
  ↓
simulation
  ↓
agent-environment system
```

This is important because higher-level abstractions should emerge from lower-level contracts rather than becoming isolated special cases.

---

# 12. Interfaces Are the Glue

The most important architectural mechanism for connecting domains is not inheritance.

It is semantic capability.

An object may satisfy interfaces such as:

```text
Composable
Spatial
Temporal
Stateful
Dynamical
Differentiable
Parallelizable
Vectorizable
Streamable
Renderable
Optimizable
Learnable
Observable
Controllable
Deterministic
Stochastic
Morphological
```

This allows concepts from different domains to interact without requiring them to belong to the same ontology.

For example:

```text
physics.body
```

and:

```text
agent
```

may both be:

```text
Spatial
Stateful
Observable
Transformable
```

without one being a subtype of the other.

This is one of the central design principles of the project.

---

# 13. Composition Rather Than Monolithic Abstractions

SCR favours composition over enormous domain-specific objects.

Instead of defining:

```text
UniversalSimulationObject
```

the system should allow:

```text
state
+
spatial
+
dynamics
+
perception
+
control
+
rendering
```

to compose into a useful higher-level object.

This makes the system extensible.

New concepts can be constructed from existing semantic capabilities rather than requiring the entire framework to be modified.

---

# 14. Higher-Order Semantics

The project goes beyond simply defining nouns.

It must also define computational verbs.

Examples include:

```text
compose
transform
map
reduce
sample
integrate
differentiate
propagate
evolve
observe
optimise
control
render
stream
```

These operations should themselves be composable.

For example:

```text
field.sample
    →
neural.transform
    →
control.policy
    →
dynamics.integrate
```

can form a larger computational operation.

Eventually, the compiler may recognise and specialise such compositions.

---

# 15. Morphology as an Important Example

Morphology illustrates why the semantic approach matters.

A traditional system may treat morphology as geometry or mesh manipulation.

SCR instead treats morphology as semantic structure:

```text
shape
form
structure
boundary
feature
composition
deformation
growth
fracture
generation
representation
correspondence
```

The same semantic morphology may then be represented as:

```text
mesh
voxel field
implicit surface
particle system
parametric structure
collision geometry
finite-element structure
render geometry
```

depending on what consumes it.

Thus:

```text
semantic morphology
```

is distinct from:

```text
morphological representation
```

This distinction is fundamental throughout SCR.

---

# 16. Representation Independence

A recurring principle throughout the project is:

> Semantic meaning should survive changes in representation.

For example:

```text
field
```

should not inherently mean:

```text
dense CPU array
```

and:

```text
geometry
```

should not inherently mean:

```text
triangle mesh
```

and:

```text
tensor
```

should not inherently mean:

```text
contiguous host memory
```

Representations are implementation choices constrained by semantics.

This gives the compiler freedom to choose representations appropriate to:

* workload
* precision
* locality
* memory
* hardware
* provider
* execution strategy

---

# 17. Hardware Abstraction

Another major motivation for SCR is hardware fragmentation.

Modern computational systems may execute across:

```text
CPU
GPU
NPU
FPGA
accelerator
distributed nodes
specialised devices
```

Traditional application architectures often force developers to explicitly target these environments.

SCR seeks to reverse this relationship.

The developer describes semantic computation.

The compiler/runtime determines an appropriate execution strategy.

Conceptually:

```text
Semantic Program
       ↓
Analysis
       ↓
Cost Model
       ↓
Representation Selection
       ↓
Provider Selection
       ↓
Hardware Mapping
       ↓
Kernel Generation / Compilation
       ↓
Execution
```

The objective is not merely maximum hardware utilisation.

It is maximum **useful computation** subject to:

```text
correctness
latency
memory
bandwidth
parallelism
synchronisation
power
thermal constraints
resource contention
```

---

# 18. Why the Runtime Exists

MLIR solves compilation and representation problems.

It does not by itself constitute the complete execution environment envisioned by SCR.

SCR therefore includes a runtime responsible for:

* executing compiled artifacts
* resource management
* provider management
* execution scheduling
* hardware discovery
* runtime capability selection
* data movement
* orchestration
* telemetry
* dynamic specialisation
* potentially JIT/recompilation

This creates the complete conceptual stack:

```text
Semantic Library
       ↓
Semantic MLIR
       ↓
Compiler
       ↓
Providers
       ↓
Runtime
       ↓
Hardware
```

---

# 19. Why the Project Is Not "Another Simulation Engine"

Simulation remains an important reference workload.

It is particularly valuable because simulation exercises almost every difficult aspect of the architecture:

```text
mathematics
fields
graphs
geometry
topology
spatial computation
morphology
physics
dynamics
agents
neural computation
control
rendering
streaming
distributed execution
```

If SCR can represent and execute sophisticated simulations through its semantic abstractions, that provides strong evidence that the abstraction system is genuinely general.

But simulation is not the ultimate boundary of the project.

The architecture is deliberately generalised beyond simulation.

---

# 20. The Broader Vision

The long-term objective is a computational ecosystem in which many disciplines can share semantic infrastructure.

Potential users include:

* scientists
* physicists
* computational biologists
* mathematicians
* engineers
* ML researchers
* data scientists
* simulation developers
* robotics researchers
* graphics developers
* computational artists
* educators
* students

The same underlying computational semantics may support radically different applications.

For example:

```text
robotics
simulation
neural inference
scientific computing
digital twins
procedural generation
physics
computational biology
spatial analytics
visualisation
```

without requiring each application ecosystem to reinvent the same underlying abstractions.

---

# 21. The "Common Language Runtime" Analogy

A useful conceptual analogy is the Common Language Runtime (CLR).

The analogy is:

```text
Traditional managed ecosystem       SCR

Languages                           Rust / Python / C++ / Julia / ...
Intermediate language               Semantic MLIR
Runtime                             Semantic Runtime
Base Class Library                  Semantic Library
JIT / AOT                            Semantic compilation
Native interop                       Providers
Native libraries                     Existing ecosystem
Hardware                             CPU / GPU / accelerators
```

But SCR goes one level deeper.

The CLR primarily abstracts **software execution**.

SCR seeks to abstract **computational meaning**.

The developer should therefore be able to say:

```text
"integrate this dynamical system"
```

rather than:

```text
"invoke this API in this numerical library using this memory layout
and execute it using this hardware backend."
```

---

# 22. Relationship to the Existing Open-Source Ecosystem

SCR is intended to be complementary to existing projects.

It should not attempt to replace:

```text
LLVM
MLIR
Chrono
Eigen
CGAL
OpenVDB
H3
VSG
CUDA
HIP
SYCL
```

or similar systems.

Instead, those systems become potential layers beneath SCR.

The architectural relationship is:

```text
SCR Semantic Contract
        ↓
SCR Provider Interface
        ↓
Existing Technology
        ↓
Hardware
```

This is deliberately an ecosystem strategy rather than a reinvention strategy.

---

# 23. Why the Project Requires Strong Standards

The more general the system becomes, the more dangerous uncontrolled abstraction becomes.

A library containing hundreds of concepts can easily become another fragmented ecosystem.

SCR therefore treats:

```text
interfaces
contracts
invariants
verification
naming
composition
representation independence
provider independence
```

as first-class architectural concerns.

The Semantic Library must not merely become a large collection of dialects.

It must become a **coherent semantic system**.

---

# 24. Why Parallel Development Changes the Architecture

The library is large enough that implementation will necessarily be distributed across multiple developers and potentially multiple AI agents.

This introduces another architectural requirement.

An agent implementing Physics cannot make assumptions that silently constrain Dynamics.

An agent implementing Morphology cannot assume Geometry is always represented as meshes.

An agent implementing Neural cannot assume tensors live in CPU memory.

An agent implementing Rendering cannot assume a particular scene representation.

Therefore the project requires explicit contracts between domains.

The interfaces are consequently not documentation conveniences.

They are the mechanism that makes parallel development possible.

---

# 25. Progressive Convergence

The project should evolve through progressive abstraction.

Early implementations may be imperfect.

That is acceptable.

What matters is that they preserve the semantic boundary.

For example:

```text
Phase 1

physics.integrate
    ↓
simple CPU implementation
```

can later become:

```text
Phase 2

physics.integrate
    ↓
provider selection
    ├── native solver
    ├── Chrono
    └── generated solver
```

and eventually:

```text
Phase 3

physics.integrate
    ↓
analysis
    ↓
specialisation
    ↓
provider selection
    ↓
hardware mapping
```

The semantic API does not need to change.

Implementation sophistication can increase beneath it.

---

# 26. The Semantic Graph

One of the deepest architectural ideas behind SCR is that the system is fundamentally a graph of semantic relationships.

The syntax used by a particular programming language is secondary.

The important structure is:

```text
entities
+
properties
+
relationships
+
capabilities
+
operations
+
transformations
+
constraints
```

The compiler can then reason about this structure.

This makes it possible to perform transformations that are difficult when computation is represented only as conventional application code.

---

# 27. Semantic Compilation

The ultimate compiler model is therefore:

```text
Developer Intent
      ↓
Semantic Construction
      ↓
Semantic MLIR
      ↓
Semantic Analysis
      ↓
Composition
      ↓
Canonicalisation
      ↓
Optimisation
      ↓
Representation Selection
      ↓
Provider Selection
      ↓
Hardware Specialisation
      ↓
Executable Program
```

The system should preserve high-level semantic information for as long as possible.

Lowering should happen progressively.

This is important because high-level semantics contain information that may be lost by premature lowering.

---

# 28. The Fundamental Separation

SCR is built around three distinct questions:

### Meaning

> What does this computation represent?

### Implementation

> How can this computation be performed?

### Execution

> Where and under what conditions should it run?

These correspond approximately to:

```text
Semantic Library
        ↓
Providers / Compiler
        ↓
Runtime / Hardware
```

Confusing these layers is one of the principal failure modes the architecture is designed to prevent.

---

# 29. What Success Looks Like

The project succeeds if a developer can construct something conceptually like:

```text
world
    .field(velocity)
    .sample(agent.position)
    .observe()
    .infer(model)
    .decide(policy)
    .control(action)
    .integrate(dynamics)
    .update(morphology)
    .render(scene)
    .stream(telemetry)
```

without needing to explicitly orchestrate:

```text
tensor libraries
physics APIs
geometry APIs
spatial indexes
rendering APIs
GPU APIs
memory layouts
thread pools
messaging systems
hardware-specific kernels
```

The semantic compiler/runtime becomes responsible for bridging those layers.

---

# 30. What SCR Is Ultimately Trying to Build

SCR is ultimately an attempt to create:

> **An open computational semantic ecosystem in which complex computation can be expressed in terms of meaning rather than implementation, composed across domains, transformed by a compiler, and executed efficiently across heterogeneous hardware.**

MLIR provides the extensible foundation.

The Semantic Library provides the vocabulary.

Interfaces provide interoperability.

Composition provides expressive power.

Analysis provides understanding.

Transformations provide optimisation.

Providers provide implementations.

The runtime provides execution.

Hardware provides resources.

---

# 31. Architectural North Star

The complete conceptual architecture is:

```text
                         APPLICATIONS
                              │
                  Rust / Python / C++ / ...
                              │
                              ▼
                    SEMANTIC LIBRARY
                              │
             ┌────────────────┼────────────────┐
             │                │                │
         SEMANTICS       INTERFACES       COMPOSITION
             │                │                │
             └────────────────┼────────────────┘
                              ▼
                        SEMANTIC MLIR
                              │
               ┌──────────────┼──────────────┐
               │              │              │
           ANALYSIS       TRANSFORMS    SPECIALISATION
               │              │              │
               └──────────────┼──────────────┘
                              ▼
                           LOWERING
                              │
                ┌─────────────┼─────────────┐
                │             │             │
             PROVIDERS       CPU           GPU
                │             │             │
                └─────────────┼─────────────┘
                              ▼
                           RUNTIME
                              │
                              ▼
                           HARDWARE
```

---

# 32. Final Rationale

The project exists because the current computational ecosystem has become extraordinarily powerful but increasingly fragmented.

The problem is no longer a lack of algorithms or libraries.

The problem is the **semantic distance between them**.

Physics knows about bodies.

Geometry knows about shapes.

Topology knows about connectivity.

Fields know about distributed values.

Neural systems know about learned transformations.

Agents know about behaviour.

Control systems know about feedback.

Renderers know about visual representation.

Streaming systems know about temporal information flow.

Hardware knows about execution.

Yet these systems increasingly need to operate together.

SCR attempts to provide the missing layer between them.

Not another application framework.

Not another physics engine.

Not another neural framework.

Not another rendering engine.

Not another compiler.

Rather:

> **A common semantic substrate through which heterogeneous computational disciplines can describe, compose, transform and execute computation as a unified computational system.**

That is the reason the Semantic Computational Runtime exists.
