# SCR Repository Alignment and MLIR-First Architecture Correction

## Mission

You are operating on the **Semantic Computational Runtime (SCR)** repository.

Your task is to perform a **repository-wide architectural alignment pass** to eliminate ambiguity, contradiction, and terminology that could cause SCR to evolve a second intermediate representation alongside MLIR.

This is a foundational architectural correction.

The governing architectural decision is:

> **SCR does not create or maintain a separate intermediate representation.**
>
> **MLIR is the representation and compilation substrate of SCR.**
>
> SCR defines computational semantics through MLIR dialects, types, operations, attributes, interfaces, traits, verification, analyses, transformations, passes, and lowering mechanisms.
>
> SCR must exploit MLIR's capabilities fully before introducing any additional representation mechanism.

Do not merely change a few phrases in the README.

Inspect the repository as an architectural system and bring **documentation, specifications, directory terminology, examples, agent instructions, implementation conventions, tests, and control-plane metadata** into alignment.

The final repository must communicate one coherent architecture to a human developer, an implementation agent, and a future contributor.

---

# 1. Non-Negotiable Architectural Principle

The following is now a constitutional rule of SCR:

> **There is no separate SCR IR.**

The canonical semantic representation of SCR is:

```text
MLIR
├── SCR dialects
├── SCR types
├── SCR attributes
├── SCR operations
├── SCR interfaces
├── SCR traits
├── SCR verification
├── SCR analyses
├── SCR transformations
└── SCR lowering
```

SCR adds **semantic meaning and computational contracts to MLIR**.

It does not add another IR between application semantics and MLIR.

The correct conceptual relationship is:

```text
Application
    ↓
Semantic Model
    ↓
SCR Semantic MLIR
    ↓
MLIR Infrastructure
    ↓
Analysis / Transformation
    ↓
Lowering
    ↓
Provider
    ↓
Execution
```

Where:

```text
SCR Semantic MLIR
    =
MLIR
+
SCR Dialects
+
SCR Interfaces
+
SCR Types
+
SCR Attributes
+
SCR Semantics
+
SCR Verification
+
SCR Analyses
+
SCR Transformations
```

Do **not** interpret "Semantic MLIR" as another IR.

It is simply the MLIR representation of SCR semantics.

---

# 2. Explicitly Prohibited Architecture

The following architecture must NOT be implemented:

```text
Application
    ↓
SCR Semantic Model
    ↓
SCR Semantic IR
    ↓
MLIR
    ↓
LLVM
```

Nor:

```text
Application
    ↓
Domain IR
    ↓
Semantic IR
    ↓
MLIR
```

Nor:

```text
Application
    ↓
Domain AST
    ↓
SCR IR
    ↓
MLIR
```

Nor any equivalent architecture where SCR maintains a persistent, independently specified, independently typed, independently verified intermediate representation that duplicates MLIR concepts.

Do not create:

* `scr-ir`
* `semantic-ir`
* `domain-ir`
* `computational-ir`
* `semantic_graph_ir`
* a custom SSA representation
* a custom operation graph
* a custom type system
* a custom region/control-flow representation
* a custom dataflow IR
* a JSON IR that becomes canonical
* a Rust struct hierarchy that becomes the canonical semantic representation
* a second compiler IR hidden behind APIs

unless an explicitly approved future architecture decision changes this rule.

---

# 3. Important Distinction: Semantic Model vs Representation

SCR still absolutely has a **semantic model**.

Do not remove that concept.

The distinction is:

```text
Semantic Model
    ↓
describes what SCR means
    ↓
MLIR representation
    ↓
represents that meaning computationally
```

The semantic model is an **ontology, contract system, vocabulary, and specification**.

It is not an alternative runtime IR.

For example:

```text
Entity
Property
Value
Relationship
State
Operation
Transformation
Capability
Constraint
Effect
Observation
Event
Process
Representation
Provider
Execution
```

are semantic concepts.

They must not automatically become a second in-memory IR hierarchy.

Where these concepts require executable representation, they should be represented using appropriate MLIR constructs:

* dialects
* operations
* types
* attributes
* regions
* blocks
* SSA values
* symbols
* interfaces
* traits
* verification
* dialect conversion
* analysis infrastructure
* transformation infrastructure

---

# 4. Repository-Wide Audit Required

Before modifying files, inspect the complete repository.

At minimum inspect:

```text
README.md
AGENTS.md
001_INTRODUCTION.md
002_GETTING_STARTED.md
003_PROJECT_MANDATE.md

docs/
public-documentation/

program_increments/
program_increments/v0.0.1/

lib/

scripts/
flake.nix
```

Also inspect:

* Rust source
* build configuration
* MLIR integration
* CMake configuration
* Cargo configuration
* test infrastructure
* examples
* generated documentation
* agent instructions
* status files
* library graph metadata
* semantic definitions
* golden-path documentation
* implementation TODOs
* comments
* naming conventions

Search globally for terminology such as:

```text
IR
Semantic IR
Domain IR
SCR IR
Intermediate Representation
intermediate representation
semantic representation
domain representation
semantic model
domain model
MLIR
dialect
lowering
representation
```

Do not assume that only documentation contains the problem.

---

# 5. Classify Every Occurrence

Every occurrence of "IR" or "representation" must be classified.

Use these categories:

### A. MLIR itself

Valid.

Examples:

```text
MLIR
MLIR module
MLIR operation
MLIR type
MLIR attribute
MLIR region
MLIR dialect
MLIR IR
```

### B. SCR semantic representation expressed in MLIR

Valid.

Preferred terminology:

```text
SCR Semantic MLIR
SCR dialect representation
semantic MLIR representation
MLIR representation of SCR semantics
```

### C. Semantic Model

Valid.

This means the conceptual/ontological specification of SCR.

### D. Domain Model

Valid when discussing conceptual domain meaning.

### E. Domain IR

Usually invalid.

Replace with the appropriate SCR MLIR dialect terminology.

### F. Semantic IR

Usually invalid if it means a second IR.

Replace with:

```text
Semantic MLIR
SCR semantic representation
MLIR representation of semantics
SCR dialect representation
```

If the phrase occurs in a historical discussion, rewrite it so the historical meaning is unambiguous.

### G. Custom IR data structures

Potential architectural violation.

Investigate rather than blindly rename.

---

# 6. Terminology Standard

Establish and use the following vocabulary consistently.

## 6.1 Semantic Model

Definition:

> The conceptual and formal model describing computational meaning independently of any particular implementation.

Examples:

```text
Entity
Relationship
State
Operation
Constraint
Capability
Effect
Observation
Transformation
Provider
Execution
```

The semantic model is specification-level.

It is not a second IR.

---

## 6.2 Semantic MLIR

Definition:

> MLIR containing SCR dialects and constructs that represent SCR computational semantics.

Use:

```text
Semantic MLIR
SCR Semantic MLIR
MLIR representation of SCR semantics
```

Avoid:

```text
SCR Semantic IR
SCR IR
Semantic IR
Domain IR
```

when those imply an additional IR.

---

## 6.3 SCR Dialect

Definition:

> An MLIR dialect defining a coherent semantic domain or computational capability within SCR.

Examples:

```text
scr.core
scr.math
scr.field
scr.graph
scr.geometry
scr.topology
scr.morphology
scr.physics
scr.dynamics
scr.simulation
scr.agent
scr.neural
scr.perception
scr.control
scr.optimization
scr.learning
scr.render
scr.stream
```

The exact namespace may differ according to existing repository conventions, but all dialects must remain MLIR dialects.

---

## 6.4 Semantic Interface

An MLIR interface expressing a capability or semantic contract.

Examples:

```text
Composable
Transformable
Spatial
Temporal
Stateful
Stateless
Dynamical
Differentiable
Integrable
Parallelizable
Vectorizable
Tileable
Reducible
Streamable
Renderable
Distributable
Observable
Controllable
Optimizable
Learnable
Morphological
```

These must leverage MLIR's interface mechanisms where applicable.

---

## 6.5 Representation

Representation means how semantic content is encoded or materialized.

Examples:

```text
dense tensor
sparse tensor
memref
mesh
voxel structure
implicit representation
particle representation
GPU buffer
CPU data structure
render resource
stream representation
```

Representation is not automatically semantic meaning.

---

# 7. Correct Architectural Pipeline

Replace ambiguous pipelines such as:

```text
Semantic Model
    ↓
Domain IR
    ↓
MLIR
```

with:

```text
Semantic Model
    ↓
SCR Semantic MLIR
    ↓
MLIR infrastructure
```

The complete architecture should be expressed as:

```text
Application
    ↓
Semantic Model
    ↓
SCR Semantic MLIR
    ↓
MLIR Analysis / Verification / Transformation
    ↓
SCR / MLIR Lowering
    ↓
Provider Selection
    ↓
Provider Implementation
    ↓
Execution
    ↓
Observation
```

Where appropriate:

```text
Semantic Model
      │
      ▼
SCR Dialects
      │
      ▼
MLIR
      │
      ├── Analysis
      ├── Verification
      ├── Canonicalization
      ├── Transformation
      ├── Optimization
      ├── Bufferization
      ├── Tiling
      ├── Vectorization
      ├── Parallelization
      ├── GPU lowering
      ├── Async lowering
      └── Dialect conversion
      │
      ▼
Lowered MLIR
      │
      ▼
LLVM / GPU / SPIR-V / external ABI / provider
      │
      ▼
Execution
```

---

# 8. MLIR-First Rule

Before creating any SCR-specific infrastructure, the implementation must ask:

> **Can MLIR already represent or solve this?**

The answer must be "yes" wherever possible.

Prefer existing MLIR mechanisms for:

* SSA
* values
* types
* attributes
* operations
* regions
* blocks
* symbols
* modules
* verification
* interfaces
* traits
* pattern rewriting
* canonicalization
* dialect conversion
* analyses
* pass infrastructure
* transformation infrastructure
* dataflow
* control flow
* memory effects
* side-effect modelling
* bufferization
* tensor semantics
* vectorization
* GPU lowering
* async execution
* function calls
* external symbols
* LLVM lowering
* SPIR-V lowering
* serialization/parsing
* textual IR
* bytecode where appropriate

Do not duplicate these facilities.

---

# 9. "MLIR Before New Abstraction" Decision Procedure

Whenever an implementation requires a new abstraction, apply this sequence:

### Step 1 — Is it already an MLIR concept?

If yes:

**Use MLIR directly.**

### Step 2 — Can it be expressed using an existing MLIR dialect?

If yes:

**Use or compose existing MLIR dialects.**

### Step 3 — Can an SCR dialect express it?

If yes:

**Create/extend an SCR dialect.**

### Step 4 — Can an MLIR interface/trait/attribute express the required capability?

If yes:

**Use an MLIR interface, trait, or attribute.**

### Step 5 — Can an MLIR analysis/pass/transformation express it?

If yes:

**Implement it as MLIR compiler infrastructure.**

### Step 6 — Is the requirement genuinely semantic and missing from MLIR?

Only then:

**Extend SCR's MLIR dialect/interface ecosystem.**

### Step 7 — Is an entirely new representation still being proposed?

Stop.

The agent must document:

1. why MLIR is insufficient;
2. which MLIR facilities were evaluated;
3. why an SCR dialect/interface/pass cannot solve the problem;
4. why the proposed representation is not duplicating MLIR;
5. what architectural authority explicitly permits it.

Without that justification, do not implement it.

---

# 10. Semantic Graph Does Not Mean Custom IR

SCR has a semantic graph.

Do not confuse this with a second IR.

The semantic graph is a **conceptual semantic model** describing:

* entities
* relationships
* dependencies
* capabilities
* constraints
* state
* transformations
* observations
* provenance
* execution requirements

When computationally represented, it should use MLIR constructs wherever possible.

For example:

```text
Semantic Graph
      ↓
MLIR operations / values / regions / symbols / attributes
```

not:

```text
Semantic Graph
      ↓
Custom Graph IR
      ↓
MLIR
```

Likewise, the Library Architecture Graph is a **control-plane metadata graph**, not an execution IR.

---

# 11. JSON/YAML Files Must Not Become a Hidden IR

SCR currently uses files such as:

```text
101_definition.md
102_status.yaml
103_library.graph.json
```

Preserve their intended roles.

### `101_definition.md`

Normative semantic definition.

It defines meaning.

It is not executable IR.

### `102_status.yaml`

Engineering status.

It describes implementation state.

It is not IR.

### `103_library.graph.json`

Derived library architecture/control-plane graph.

It describes relationships among semantic definitions, implementations, tests, providers, etc.

It is not the canonical computational representation.

Make these distinctions explicit wherever necessary.

---

# 12. Rust Structures Must Not Become a Shadow IR

A major risk in implementation is accidentally creating something like:

```rust
struct SemanticOperation { ... }
struct SemanticType { ... }
struct SemanticValue { ... }
struct SemanticGraph { ... }
struct SemanticModule { ... }
```

and then making those structures the real representation while MLIR becomes a later serialization target.

That architecture is prohibited.

Rust structures are permitted for:

* configuration
* APIs
* handles
* builder state
* analysis results
* diagnostics
* metadata
* provider configuration
* runtime state
* transient host-side objects
* interoperability
* ownership/lifetime management

But they must not silently become a second canonical compiler representation.

If a structure represents something that MLIR already represents, prefer an MLIR-backed representation or an explicit handle/view over duplicating the IR.

---

# 13. SCR's Intellectual Contribution Is Semantics

Do not weaken SCR by interpreting this correction as "just use MLIR."

SCR remains responsible for substantial architecture.

SCR defines:

```text
semantic ontology
semantic vocabulary
semantic contracts
semantic invariants
semantic interfaces
domain semantics
capability model
composition model
semantic equivalence
semantic transformations
provider contracts
execution independence
hardware capability semantics
representation independence
domain relationships
semantic verification
```

MLIR supplies the compiler/IR machinery through which those semantics become computationally actionable.

The relationship is:

```text
MLIR = computational substrate

SCR = semantic architecture built on that substrate
```

not:

```text
MLIR = low-level backend
SCR IR = high-level compiler representation
```

That second interpretation is explicitly rejected.

---

# 14. Domain Dialects

Review the semantic library taxonomy.

Each domain must answer:

> Does this domain require a distinct MLIR dialect?

Do not automatically create one dialect per directory.

A directory such as:

```text
lib/401_Morphology/
```

is a semantic library/domain organization.

It does not automatically imply:

```text
scr.morphology
```

unless the domain requires distinct MLIR syntax/semantics.

Likewise, multiple semantic concepts may share a dialect when that produces a coherent semantic boundary.

The agent must avoid "directory → dialect → IR" mechanically.

The correct reasoning is:

```text
Semantic boundary
        ↓
Does MLIR representation require a dialect boundary?
        ↓
If yes → dialect
If no  → reuse existing dialect/interfaces/types
```

---

# 15. Interfaces Are Preferable to Duplication

Where domains share semantic capabilities, prefer MLIR interfaces.

For example:

```text
Physics
Dynamics
Agent
Control
Simulation
```

may all require concepts such as:

```text
Stateful
Dynamical
Temporal
Observable
Controllable
```

Do not duplicate these semantics independently in every domain.

Represent shared capabilities through common SCR interfaces where appropriate.

The same applies to:

```text
Spatial
Temporal
Differentiable
Parallelizable
Streamable
Renderable
Morphological
```

The goal is a semantic ecosystem, not isolated domain silos.

---

# 16. Correct Interpretation of the Layer Model

SCR's progressive semantic abstraction model remains valid.

For example:

```text
L0 — Mathematical primitives
L1 — Computational primitives
L2 — Structural semantics
L3 — Domain capabilities
L4 — Composite domain models
L5 — System semantics
```

These are **semantic abstraction levels**, not IR levels.

Do not implement:

```text
L0 IR
L1 IR
L2 IR
L3 IR
L4 IR
L5 IR
```

as six intermediate representations.

Instead, represent all appropriate levels using MLIR constructs and semantic relationships.

---

# 17. Higher-Order Composition

Preserve the higher-order composition model.

For example:

```text
field.sample
    ↓
interaction
    ↓
dynamics.integrate
    ↓
state.transition
```

may compose into:

```text
agent.propagate
```

which may participate in:

```text
population.evolve
```

These are semantic compositions represented in MLIR.

Do not create a custom composition IR.

Use MLIR:

* regions
* operations
* SSA
* interfaces
* attributes
* transformations
* pattern rewriting
* dialect conversion

where appropriate.

---

# 18. Morphology

Preserve the important bidirectional morphology model:

```text
Pattern
   ↓
Morphological Interpretation
   ↓
Morphological Structure
   ↓
Structural Analysis
   ↓
Pattern
```

Morphology is a semantic domain.

It is not synonymous with:

* mesh generation
* geometry generation
* rendering
* voxelization

and it must not be implemented as a custom "morphology IR."

Morphological semantics should be representable through MLIR while allowing multiple materializations:

```text
Mesh
Voxel
Implicit Surface
Particle
Parametric Form
Procedural Form
Field
Graph
```

Representation remains downstream from semantic meaning.

---

# 19. Golden Path Correction

Review the v0.0.1 Golden Path.

The intended path is:

```text
Core
  ↓
Dynamics
  ↓
Simulation
  ↓
Semantic MLIR
  ↓
MLIR Analysis / Transformation
  ↓
CPU Lowering / Provider
  ↓
Simulation State
  ↓
Render Projection
  ↓
Render State
  ↓
Rendering Provider
  ↓
VSG / Vulkan
  ↓
Visible Result
```

Do not describe this as:

```text
Domain IR
  ↓
MLIR
```

The Golden Path must demonstrate that SCR semantics can be represented directly in MLIR and then transformed/lowered through MLIR.

The particle simulation remains a **vertical architectural proof**, not the architectural definition of SCR.

---

# 20. README Correction

Rewrite the architecture sections of `README.md` so that the canonical pipeline is unambiguous.

The README should make the following distinction explicit:

```text
Semantic Meaning
      ↓
Semantic Model
      ↓
Semantic MLIR
      ↓
MLIR compiler infrastructure
      ↓
Lowering
      ↓
Provider
      ↓
Execution
```

It should explicitly state:

> SCR does not define a second intermediate representation alongside MLIR. SCR semantics are represented directly in MLIR through SCR dialects, interfaces, types, attributes, operations, verification, analyses, transformations, and lowering infrastructure.

Also explicitly state that:

> The semantic model is a specification of meaning; Semantic MLIR is its MLIR representation. They are not two competing intermediate representations.

---

# 21. Project Mandate Correction

Update `003_PROJECT_MANDATE.md`.

The mandate must explicitly establish:

### Architectural law

> SCR is built on MLIR, not beside it.

### Representation law

> There is one compiler representation substrate: MLIR.

### Semantic law

> SCR contributes semantics, contracts, interfaces, domain meaning, verification requirements, transformations, provider contracts, and execution independence.

### Anti-duplication law

> SCR shall not reproduce MLIR's IR, type, SSA, region, operation, interface, pass, transformation, or lowering mechanisms where MLIR already provides suitable facilities.

### Extension law

> New SCR compiler abstractions should first be expressed using existing MLIR mechanisms. New SCR dialects/interfaces/passes are preferred over independent representation systems.

---

# 22. Semantic Model Correction

Update `docs/103_SEMANTIC_MODEL.md`.

The existing statement:

> There is no separate SCR IR. The semantic representation is MLIR + SCR dialects + SCR interfaces + SCR attributes + SCR semantics.

is authoritative.

Promote it to a highly visible architectural rule.

Clarify that:

```text
Semantic Model
```

and:

```text
Semantic MLIR
```

are different concepts:

```text
Semantic Model
    = meaning/specification

Semantic MLIR
    = computational representation of that meaning
```

Do not allow wording elsewhere to contradict this.

---

# 23. Architecture Documentation Correction

Update:

```text
docs/102_ARCHITECTURE.md
```

and any related architecture documents.

The architecture should distinguish:

### Semantic layer

What computation means.

### Representation layer

MLIR representation of those semantics.

### Transformation layer

MLIR/SCR transformations.

### Lowering layer

Transformation into progressively more concrete MLIR dialects or external forms.

### Provider layer

Concrete implementation technologies.

### Runtime layer

Execution orchestration and resource management.

### Hardware/execution layer

CPU/GPU/accelerator/distributed infrastructure.

Use:

```text
Meaning ≠ Representation ≠ Transformation ≠ Lowering ≠ Provider ≠ Runtime ≠ Hardware
```

but ensure "Representation" means the MLIR representation plus eventual concrete/materialized representations, not an additional SCR IR.

---

# 24. Library Documentation Correction

Audit every semantic library directory.

Where documentation currently says:

```text
IR
```

determine whether it actually means:

1. semantic specification;
2. MLIR dialect;
3. MLIR operation/type definitions;
4. runtime representation;
5. domain data model;
6. external representation.

Rename terminology accordingly.

Do not blindly replace every occurrence of "IR".

The objective is semantic precision, not search-and-replace.

---

# 25. Agent Governance Correction

Update `AGENTS.md`.

This is particularly important because future coding agents will read it.

Add an explicit section:

# MLIR-First Representation Policy

It must state that:

1. MLIR is the canonical compiler IR.
2. SCR does not maintain a parallel IR.
3. Semantic concepts are represented through MLIR.
4. New abstractions must first be evaluated against MLIR.
5. New SCR dialects/interfaces are preferred to new representations.
6. Rust structures must not become a shadow IR.
7. JSON/YAML artifacts must not become a canonical execution IR.
8. Agents must stop and request architectural review if a second IR appears necessary.
9. Documentation terminology must never imply a second IR.
10. Any proposed deviation requires explicit architectural approval.

This instruction is especially important because autonomous agents can easily infer architecture from terminology.

---

# 26. Control-Plane Graph Correction

Inspect:

```text
103_library.graph.json
```

and the mechanism that generates or maintains it.

Ensure it represents the **Library Architecture Graph**, not an execution IR.

Its conceptual role is:

```text
semantic definitions
    ↕
domains
    ↕
interfaces
    ↕
implementations
    ↕
providers
    ↕
tests
    ↕
documentation
```

It is metadata/control-plane information.

It must not become an alternate computational representation.

---

# 27. Implementation Architecture

If implementation code already exists, inspect it for signs of a shadow IR.

Look for:

```text
enum Operation
struct Operation
enum Type
struct Type
struct Value
struct Module
struct Region
struct Block
struct Graph
struct SSA
struct IRNode
struct IROp
struct SemanticOp
struct SemanticValue
```

Do not delete legitimate runtime/API abstractions automatically.

Determine whether each is:

* an MLIR wrapper;
* an API abstraction;
* runtime state;
* analysis output;
* provider state;
* configuration;
* or an actual duplicate IR.

If it is a duplicate IR, refactor it toward MLIR.

---

# 28. Tests

Add architectural tests or static checks where practical.

At minimum establish checks that detect prohibited terminology in normative architecture documents.

Examples of terms requiring review:

```text
SCR IR
Semantic IR
Domain IR
Custom IR
Intermediate Representation
```

Do not simply ban the word "IR".

MLIR itself is an IR.

The checks should detect **ambiguous uses**, not legitimate MLIR terminology.

Also add tests that verify the Golden Path operates through MLIR rather than a custom intermediate representation.

---

# 29. Documentation Consistency Test

Create a documentation consistency check if practical.

The objective is to prevent future documents from reintroducing the ambiguity.

A future document must not describe:

```text
Semantic Model → SCR IR → MLIR
```

without an explicit architectural exception.

Preferred terminology:

```text
Semantic Model → Semantic MLIR
```

or:

```text
Semantic Model → SCR MLIR Dialects
```

---

# 30. Provider Architecture

Preserve provider independence.

The correct model is:

```text
SCR Semantic MLIR
       ↓
Analysis
       ↓
Transformation
       ↓
Lowering
       ↓
Provider Contract
       ↓
Provider
       ↓
External Technology
```

Examples may include:

```text
LLVM
Eigen
CGAL
H3
OpenVDB
Chrono
VulkanSceneGraph
CUDA
ROCm
```

These are implementation resources.

They are not semantic authorities.

Do not allow provider APIs to leak upward into semantic definitions.

---

# 31. Hardware Architecture

The correction must not accidentally weaken SCR's hardware independence.

SCR may reason about:

```text
CPU
GPU
accelerators
vector width
cache
NUMA
memory bandwidth
occupancy
latency
throughput
interconnect
power
thermal constraints
memory pressure
```

but those are execution capabilities/resources.

They are not reasons to create another IR.

Hardware-aware compilation should continue to operate through MLIR analysis, transformation, lowering, and provider selection.

---

# 32. Rendering Architecture

Preserve rendering as a first-class computational domain.

The intended path remains conceptually:

```text
Semantic Runtime
    ↓
Render State
    ↓
Render Commands
    ↓
Rust Renderer API
    ↓
C++ Adapter
    ↓
VulkanSceneGraph
    ↓
Vulkan
    ↓
GPU
```

Do not insert a custom render IR unless it is demonstrably required by the actual MLIR/SCR architecture and is explicitly approved.

A render dialect, where useful, is still MLIR.

---

# 33. Messaging and Stream Architecture

Preserve stream and messaging semantics.

AMQP-oriented semantics may include:

```text
exchange
queue
routing
publication
subscription
delivery
acknowledgement
ordering
durability
backpressure
```

These should be semantic constructs.

If represented computationally, they should use MLIR/SCR mechanisms rather than a separate messaging IR.

Likewise:

```text
Source
Sink
Channel
Message
Event
Signal
Flow
Pipeline
Map
Filter
Reduce
Join
Merge
Split
Window
Buffer
Queue
```

remain semantic concepts/dialect constructs, not a separate Stream IR.

---

# 34. Do Not Overcorrect

This task is **not** a mandate to collapse all SCR semantics into existing generic MLIR dialects.

SCR is still allowed and expected to define new MLIR dialects where domain-specific semantics genuinely require them.

The rule is:

```text
No second IR
```

not:

```text
No SCR dialects
```

Similarly:

```text
No duplicate compiler substrate
```

does not mean:

```text
No SCR compiler infrastructure
```

SCR may provide:

* dialects
* interfaces
* traits
* attributes
* verification
* analyses
* transformations
* canonicalization patterns
* lowering passes
* provider interfaces
* runtime integration
* semantic tooling

provided these operate within the MLIR architecture.

---

# 35. Required Architectural Terminology Table

Create or update a canonical terminology section containing approximately:

| Term                       | Meaning                                                         |
| -------------------------- | --------------------------------------------------------------- |
| Semantic Model             | Conceptual specification of computational meaning               |
| Semantic MLIR              | MLIR representation of SCR semantics                            |
| SCR Dialect                | MLIR dialect defining SCR/domain semantics                      |
| SCR Interface              | MLIR interface expressing a semantic capability/contract        |
| Operation                  | MLIR operation carrying semantic computation                    |
| Type                       | MLIR/SCR semantic type                                          |
| Attribute                  | MLIR/SCR semantic metadata                                      |
| Analysis                   | Analysis over MLIR/SCR semantics                                |
| Transformation             | Semantics-preserving or explicitly semantic MLIR transformation |
| Lowering                   | Progressive transformation toward concrete execution            |
| Provider                   | Concrete implementation of a semantic contract                  |
| Runtime                    | Execution orchestration and resource management                 |
| Representation             | Concrete or MLIR representation of semantic information         |
| Semantic Graph             | Conceptual relationship structure; not a second IR              |
| Library Architecture Graph | Control-plane metadata graph; not an execution IR               |

This table should become the terminology authority for the repository.

---

# 36. Required Architectural Diagram

Add a canonical diagram showing:

```text
                    ┌─────────────────────┐
                    │    Application      │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │   Semantic Model    │
                    │  Meaning / Contract │
                    └──────────┬──────────┘
                               │
                               ▼
              ┌────────────────────────────────┐
              │         Semantic MLIR           │
              │                                │
              │ SCR Dialects                   │
              │ SCR Types                      │
              │ SCR Operations                 │
              │ SCR Attributes                 │
              │ SCR Interfaces                 │
              │ SCR Traits                     │
              │ Semantic Verification          │
              └───────────────┬────────────────┘
                              │
                              ▼
              ┌────────────────────────────────┐
              │         MLIR Infrastructure     │
              │                                │
              │ Analysis                       │
              │ Canonicalization               │
              │ Transformation                 │
              │ Dialect Conversion             │
              │ Bufferization                  │
              │ Vectorization                  │
              │ Parallelization                │
              │ GPU / Async / LLVM lowering    │
              └───────────────┬────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │      Provider       │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Execution Substrate │
                    │ CPU / GPU / etc.    │
                    └─────────────────────┘
```

Make the absence of a second IR visually obvious.

---

# 37. Acceptance Criteria

The task is complete only when all of the following are true.

## Architectural

* [ ] Repository explicitly states that SCR has no separate IR.
* [ ] MLIR is explicitly established as the canonical compiler representation substrate.
* [ ] Semantic Model is distinguished from Semantic MLIR.
* [ ] SCR dialects are explicitly described as MLIR dialects.
* [ ] SCR interfaces are explicitly described in MLIR terms.
* [ ] No documentation implies `Semantic IR → MLIR`.
* [ ] No documentation implies `Domain IR → MLIR`.
* [ ] No implementation introduces a shadow IR.

## Documentation

* [ ] README aligned.
* [ ] Project Mandate aligned.
* [ ] Architecture documentation aligned.
* [ ] Semantic Model aligned.
* [ ] Semantic Invariants aligned if necessary.
* [ ] AGENTS.md aligned.
* [ ] Golden Path aligned.
* [ ] Public documentation aligned.
* [ ] Library definitions aligned.
* [ ] Examples aligned.

## Implementation

* [ ] Existing code audited for shadow IR structures.
* [ ] MLIR used directly wherever appropriate.
* [ ] Existing MLIR facilities used before introducing SCR-specific machinery.
* [ ] SCR-specific extensions are implemented as MLIR dialect/interface/pass infrastructure where appropriate.
* [ ] No custom SSA/type/region/operation system has been introduced.
* [ ] No JSON/YAML execution IR exists.
* [ ] No Rust shadow IR has become canonical.

## Metadata

* [ ] Library Architecture Graph remains control-plane metadata.
* [ ] Status files remain status information.
* [ ] Definition files remain normative semantic specifications.

## Verification

* [ ] Repository-wide terminology search completed.
* [ ] Ambiguous occurrences reviewed.
* [ ] Documentation consistency checks added where useful.
* [ ] Build/test suite executed.
* [ ] MLIR integration tested.
* [ ] Golden Path checked against the corrected architecture.
* [ ] No unresolved architectural contradiction remains.

---

# 38. Required Agent Report

At completion, provide a concise but technically precise report containing:

## A. Findings

List every significant instance where the repository implied a second IR.

For each:

```text
File
Location
Original terminology
Problem
Correction
```

## B. Architectural Changes

Describe the actual architectural corrections.

## C. MLIR Usage

List which MLIR mechanisms are now explicitly relied upon.

## D. Shadow-IR Audit

State whether any custom representation remains.

For each remaining custom structure, explain why it is **not** an IR.

## E. Documentation Alignment

List every normative document changed.

## F. Verification

Report:

```text
build status
test status
documentation checks
Golden Path status
MLIR integration status
```

## G. Remaining Ambiguities

There must be none.

If any ambiguity remains, explicitly identify it rather than silently proceeding.

---

# 39. Final Architectural Test

Before declaring completion, ask yourself:

> If a new autonomous coding agent were given only this repository, would it reasonably conclude that SCR contains a custom semantic IR that is subsequently lowered into MLIR?

If the answer is even potentially "yes":

**the work is not complete.**

The repository must instead make the following conclusion unavoidable:

> **SCR is an MLIR-based semantic computational environment.**
>
> **SCR defines computational meaning and semantic contracts through MLIR dialects, interfaces, types, attributes, operations, verification, analysis, transformation and lowering.**
>
> **There is no second SCR IR.**
>
> **MLIR is the canonical representation and compilation substrate.**
>
> **The semantic model defines what computation means; Semantic MLIR is how that meaning is represented computationally.**
>
> **Providers determine how the computation ultimately executes.**

---

# 40. Guiding Principle

The final architecture must preserve the project's foundational principle:

> **Never confuse what a computation means with how a computation happens to be implemented.**

And, specifically for this correction:

> **Never create another representation merely because MLIR has not yet been fully leveraged.**

When SCR needs more expressive power, first ask:

```text
Can MLIR represent it?
        ↓
Can an existing MLIR dialect represent it?
        ↓
Can an SCR dialect represent it?
        ↓
Can an MLIR interface/trait/attribute express it?
        ↓
Can an MLIR analysis/pass/transformation express it?
        ↓
Can dialect conversion/lowering express it?
        ↓
Only then consider something genuinely new.
```

The burden of proof is on the new representation, not on MLIR.

**MLIR is the substrate. SCR is the semantic architecture built upon it.**

Bring the entire repository into conformance with that principle.
