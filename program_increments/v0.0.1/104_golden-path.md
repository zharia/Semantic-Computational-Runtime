---

document: golden_path_specification
document_type: normative_implementation_specification
schema_version: 1.0.0

id: SCR-PI-0001-GOLDEN-PATH
name: Semantic Computational Runtime v0.0.1 Golden Path

version: 0.0.1
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-PI-0001

authority: SCR
domain: implementation
----------------------

# SCR v0.0.1 Golden Path Specification

## 1. Purpose

This specification defines the minimum end-to-end implementation required for Semantic Computational Runtime (SCR) v0.0.1.

The Golden Path is the smallest complete vertical slice through the SCR architecture that demonstrates:

```text
Semantic Definition
        ↓
Semantic Model
        ↓
Domain IR
        ↓
MLIR
        ↓
Transformation / Lowering
        ↓
CPU Execution
        ↓
Simulation State
        ↓
Render State
        ↓
Rendering
        ↓
Visible Result
```

The Golden Path is intentionally narrow.

It is not intended to implement the complete SCR semantic library.

Its purpose is to establish a working computational trunk from which subsequent semantic domains, providers, transformations, execution substrates, and runtime capabilities can be developed.

---

# 2. Golden Path Principle

> **v0.0.1 is complete when SCR can express, compile, execute, advance, and render a minimal semantic simulation without the application depending directly on the implementation details of the compiler, provider, or renderer.**

The first successful workload is therefore not the goal in itself.

The goal is proving the architectural path.

---

# 3. Success Criterion

The canonical v0.0.1 demonstration MUST be capable of performing:

```text
Create semantic simulation
        ↓
Represent simulation as SCR IR
        ↓
Verify IR
        ↓
Lower IR
        ↓
Execute on CPU
        ↓
Advance simulation state
        ↓
Project state into render state
        ↓
Submit render state to renderer
        ↓
Display evolving simulation
```

The final result MUST be visually observable.

The minimum demonstration SHOULD consist of moving particles or equivalent simple geometric objects.

---

# 4. Scope

The Golden Path includes:

* Core semantic state;
* basic mathematical values;
* simple dynamics;
* simulation lifecycle;
* semantic IR;
* MLIR integration;
* minimal lowering;
* CPU execution;
* simulation time;
* render state;
* rendering abstraction;
* rendering provider;
* VSG/Vulkan implementation;
* end-to-end example;
* automated validation;
* manual visual validation.

The Golden Path does NOT require complete implementations of all SCR domains.

---

# 5. Explicit Non-Goals

The following MUST NOT block v0.0.1:

* GPU simulation;
* CUDA;
* distributed simulation;
* AMQP runtime;
* distributed messaging;
* neural computation;
* learning;
* adaptation;
* evolution;
* ecology;
* advanced physics;
* collision detection;
* complex morphology;
* sophisticated topology;
* H3;
* BVH;
* KD-tree;
* spatial databases;
* GQL execution;
* persistence;
* CRDTs;
* distributed consistency;
* adaptive provider selection;
* automatic hardware scheduling;
* sophisticated optimization;
* provider discovery;
* heterogeneous multi-device execution.

These remain future expansion paths.

---

# 6. Golden Workload

The canonical workload is a minimal particle simulation.

Each particle MUST have, at minimum:

```text
Particle
 ├── position
 └── velocity
```

An optional acceleration MAY be included.

The initial implementation SHOULD use a simple deterministic integration rule:

```text
position' = position + velocity × dt
```

If acceleration is implemented:

```text
velocity' = velocity + acceleration × dt
position' = position + velocity' × dt
```

The exact integration algorithm is intentionally simple.

The purpose is to exercise semantic state evolution rather than physics.

---

# 7. Why Particles

Particles provide a minimal workload that simultaneously exercises:

* entities;
* state;
* vectors;
* arithmetic;
* time;
* dynamics;
* simulation;
* spatial information;
* transformation;
* rendering;
* repeated execution.

They also provide an immediate visual verification mechanism.

The particle system MUST NOT be treated as the definition of SCR's simulation model.

It is a reference workload.

---

# 8. Architectural Path

The complete Golden Path MUST follow this conceptual architecture:

```text
Application
     │
     ▼
Semantic Simulation
     │
     ▼
Simulation State
     │
     ▼
Domain IR
     │
     ▼
MLIR
     │
     ▼
Transform / Lowering
     │
     ▼
CPU Execution
     │
     ▼
Updated Simulation State
     │
     ▼
Render Projection
     │
     ▼
Render State
     │
     ▼
Rendering API
     │
     ▼
VSG Adapter
     │
     ▼
Vulkan
     │
     ▼
Display
```

No stage may silently collapse the semantic boundaries represented by this architecture.

---

# 9. Golden Path Layers

The implementation SHALL contain the following logical layers.

## 9.1 Semantic Layer

Defines:

* simulation;
* state;
* particle;
* position;
* velocity;
* time;
* step.

## 9.2 IR Layer

Represents those concepts computationally.

## 9.3 Compiler Layer

Transforms and lowers the IR.

## 9.4 Execution Layer

Executes the lowered computation.

## 9.5 Render Projection Layer

Converts simulation state into render state.

## 9.6 Rendering Layer

Displays render state.

---

# 10. Core Requirements

The Golden Path MUST use SCR Core concepts for:

* identity;
* values;
* entities;
* state;
* operations;
* references;
* time;
* provenance where applicable.

The implementation MUST NOT replace semantic concepts with implementation-specific structs without an explicit semantic boundary.

For example:

```text
Semantic Particle
       ↓
Runtime Representation
```

is valid.

Defining the particle solely as:

```rust
struct Particle { ... }
```

and treating that Rust structure as the semantic definition is not.

---

# 11. Mathematical Requirements

The Golden Path requires only minimal mathematical semantics.

Required:

* scalar values;
* vector values;
* addition;
* multiplication;
* subtraction where needed;
* time interval;
* position;
* velocity.

The implementation SHOULD reuse existing MLIR arithmetic facilities wherever appropriate rather than defining redundant SCR arithmetic operations.

MLIR already provides arithmetic and mathematical dialects among its standard dialect ecosystem.

---

# 12. Dynamics Requirements

The Dynamics implementation MUST provide a semantic state-transition operation.

Conceptually:

```text
advance(state, dt) → state'
```

The operation MUST:

* consume a valid simulation state;
* consume an explicit time increment;
* produce a new or updated semantic state;
* preserve declared state invariants;
* be deterministic for the v0.0.1 workload.

Dynamics MUST NOT depend on rendering.

---

# 13. Simulation Requirements

The Simulation domain MUST provide:

```text
Simulation
SimulationState
SimulationClock
SimulationStep
```

The simulation MUST distinguish:

```text
simulation time
```

from:

```text
wall-clock / frame time
```

The initial runtime MAY use frame duration as the simulation timestep.

However, the semantic representation MUST preserve the distinction.

---

# 14. Simulation Lifecycle

The Golden Path runtime MUST support:

```text
initialize
    ↓
instantiate
    ↓
step
    ↓
observe
    ↓
render
    ↓
repeat
    ↓
shutdown
```

The minimum lifecycle is:

```text
create
step
observe
destroy
```

---

# 15. State Model

Simulation state MUST be explicit.

Conceptually:

```text
SimulationState
 ├── simulation_time
 └── particles
      ├── position
      └── velocity
```

The runtime MUST NOT treat the renderer's state as the simulation's authoritative state.

The renderer observes or receives a projection of simulation state.

---

# 16. State Authority

The authoritative state hierarchy is:

```text
Semantic Simulation State
          │
          ▼
Runtime Representation
          │
          ▼
Render Projection
          │
          ▼
Renderer State
```

The renderer MUST NOT modify authoritative simulation state directly.

If interaction is later introduced, input MUST become an explicit semantic event, operation, or control action.

---

# 17. Semantic IR Requirements

The Golden Path requires a minimal SCR simulation IR.

The initial IR SHOULD be deliberately small.

Conceptually:

```text
scr.simulation
scr.state
scr.step
scr.render
```

Arithmetic SHOULD be expressed using existing MLIR facilities where practical.

The SCR IR MUST represent semantic concepts that cannot be adequately expressed by existing lower-level dialects.

---

# 18. No Premature IR Expansion

The implementation MUST NOT create a large SCR dialect simply because the architecture permits one.

Every custom operation MUST answer:

1. What semantic concept does it represent?
2. Why can an existing MLIR operation not represent it?
3. At what abstraction level does it belong?
4. What semantic contract does it preserve?
5. What is its intended lowering path?

If those questions cannot be answered, the operation SHOULD NOT be introduced.

---

# 19. MLIR Integration

SCR MUST use MLIR as the compiler infrastructure.

The Golden Path SHOULD use existing MLIR dialects wherever appropriate.

Potential lower-level dialects include:

```text
arith
scf
func
memref
tensor
math
llvm
```

The exact set MUST be determined by the minimum viable lowering path.

MLIR permits multiple dialects to coexist in a module and provides mechanisms for converting between them.

---

# 20. IR Verification

Every Golden Path program MUST pass IR verification before lowering.

Verification MUST include:

* valid operation structure;
* valid operands;
* valid results;
* valid types;
* valid regions where applicable;
* semantic constraints;
* simulation-state constraints.

An invalid IR MUST NOT be passed silently to execution.

---

# 21. Transformation Pipeline

The initial pipeline SHOULD be:

```text
SCR Simulation IR
       │
       ▼
Canonicalization
       │
       ▼
SCR Lowering
       │
       ▼
Existing MLIR Dialects
       │
       ▼
LLVM-Compatible MLIR
       │
       ▼
LLVM IR / Native Execution
```

MLIR's pass infrastructure provides the basic mechanism for transformation and optimization pipelines.

---

# 22. Lowering

The first lowering path MUST target CPU execution.

Conceptually:

```text
SCR Simulation
       ↓
SCR Dynamics
       ↓
arith / scf / func / memref
       ↓
LLVM
       ↓
CPU
```

The exact intermediate sequence MAY differ.

The architectural requirement is:

> A semantic simulation MUST be lowered progressively rather than implemented directly as a renderer-specific or CPU-specific program.

---

# 23. Dialect Conversion

Where SCR-specific operations must be converted to lower-level MLIR operations, the implementation SHOULD use MLIR Dialect Conversion.

MLIR provides conversion targets, rewrite patterns, optional type conversion, and full/partial conversion modes.

The Golden Path SHOULD prefer full conversion at the final boundary so that no unresolved SCR execution operations remain before CPU execution.

---

# 24. CPU Provider

v0.0.1 MUST provide a CPU execution path.

The CPU provider is the first executable realization of SCR semantics.

It MUST:

* accept compiled computation;
* instantiate runtime state;
* execute simulation steps;
* expose resulting state;
* preserve deterministic semantics for the reference workload.

The CPU provider MUST NOT become the semantic authority.

---

# 25. Execution API

The minimum conceptual runtime API is:

```text
compile(program)
instantiate(compiled_program)
step(instance, dt)
observe(instance)
destroy(instance)
```

Exact Rust naming MAY differ.

The semantic lifecycle MUST remain equivalent.

---

# 26. Execution Independence

The application MUST NOT directly invoke:

* LLVM APIs;
* MLIR pass internals;
* CPU-specific kernels;
* renderer-specific execution;
* VSG APIs.

The application interacts with the SCR runtime.

The runtime chooses the execution implementation.

---

# 27. Render Projection

Simulation state MUST be projected into render state.

Conceptually:

```text
SimulationState
      │
      ▼
RenderProjection
      │
      ▼
RenderState
```

The projection MAY be implemented as a direct transformation in v0.0.1.

The boundary MUST nevertheless exist.

---

# 28. Render State

The minimum RenderState SHOULD support:

```text
RenderObject
 ├── transform
 ├── geometry
 └── appearance
```

For the particle workload, geometry MAY be represented as:

* points;
* billboards;
* simple primitives.

The renderer MUST NOT require the simulation to know which representation is used.

---

# 29. Rendering API

The minimum rendering abstraction SHOULD support:

```text
initialize
create/update render resources
update render state
render frame
present
shutdown
```

The rendering API MUST remain independent of VSG.

---

# 30. VSG Adapter

The initial rendering provider MAY use VulkanSceneGraph.

The architecture MUST be:

```text
SCR Render State
       ↓
SCR Rendering API
       ↓
VSG Adapter
       ↓
VulkanSceneGraph
       ↓
Vulkan
```

VSG-specific types MUST NOT leak into semantic simulation APIs.

---

# 31. Rendering Is Not Simulation

Rendering MUST be treated as an observer/consumer of simulation state.

The renderer MAY maintain:

* GPU resources;
* scene graph state;
* camera state;
* render caches;
* frame resources.

These MUST NOT become the authoritative simulation state.

---

# 32. Runtime Loop

The Golden Path application MUST implement the following loop:

```text
initialize
    │
    ▼
compile
    │
    ▼
instantiate
    │
    ▼
┌──────────────────────────┐
│                          │
│  obtain frame delta      │
│          │               │
│          ▼               │
│  simulation.step(dt)     │
│          │               │
│          ▼               │
│  observe state           │
│          │               │
│          ▼               │
│  project render state    │
│          │               │
│          ▼               │
│  renderer.update()       │
│          │               │
│          ▼               │
│  renderer.render()       │
│          │               │
│          ▼               │
│  present                 │
│                          │
└────────────┬─────────────┘
             │
             └──── repeat
```

---

# 33. Frame Timing

The runtime MUST obtain a frame delta.

The initial implementation MAY use:

```text
dt = current_wall_time - previous_wall_time
```

The simulation MUST receive `dt` explicitly.

The renderer MUST NOT implicitly determine simulation time.

---

# 34. Determinism

The reference simulation MUST be deterministic given:

```text
initial state
simulation inputs
simulation timestep sequence
implementation semantics
```

The Golden Path MUST provide a test that executes the same initial state and timestep sequence twice and verifies equivalent resulting state.

---

# 35. Golden Workload Configuration

The reference workload SHOULD use approximately:

```text
particle_count = 100
initial_position = deterministic
initial_velocity = deterministic
```

The exact values are not architecturally significant.

The workload MUST remain small enough to debug easily.

---

# 36. Visual Requirement

The Golden Path MUST produce a visible application window.

The window MUST display the simulation.

The simulation MUST visibly change over time.

For the reference particle workload:

```text
Frame N
   • • • •
    • • •

Frame N+1
    • • • •
     • • •

Frame N+2
      • • • •
       • • •
```

The visual result is a manual end-to-end acceptance test.

---

# 37. Reference Application

The canonical application SHOULD live under:

```text
examples/
└── golden_path/
```

It SHOULD be executable through a simple command such as:

```text
cargo run --example golden_path
```

or the repository's equivalent build/run mechanism.

The developer experience MUST prioritize:

> Build → Run → Window appears.

---

# 38. Recommended Repository Structure

The Golden Path SHOULD touch the following areas:

```text
lib/
├── 000_meta/
├── 101_Core/
├── 201_Data/
├── 202_Math/
├── 502_Dynamics/
├── 503_Simulation/
├── 801_Spatial/
├── 902_Interfaces/
├── 903_Lowering/
├── 904_Providers/
├── 905_Transforms/
└── A01_Render/

compiler/
runtime/
providers/
examples/
tests/
```

The exact repository structure MAY evolve.

The semantic boundaries MUST remain.

---

# 39. Minimal Domain Surface

The following domains are REQUIRED for the first vertical slice:

```text
Core
Data
Math
Dynamics
Simulation
Spatial
Render
```

The following cross-cutting domains are REQUIRED:

```text
Interfaces
Transforms
Lowering
Providers
```

Other semantic domains MAY remain specification-only.

---

# 40. Minimal Interface Set

The Golden Path SHOULD implement only the following cross-domain capabilities:

```text
Stateful
Temporal
Spatial
Renderable
Deterministic
```

Additional interfaces MUST NOT be implemented merely for completeness.

---

# 41. Minimal Transform Set

The Golden Path SHOULD require only:

```text
Canonicalization
Representation
Lowering
```

More advanced transformations such as:

```text
Fusion
Tiling
Vectorization
Parallelization
Distribution
Specialization
Hardware
```

are deferred unless required by the actual implementation.

---

# 42. Minimal Provider Set

Only two providers are required:

```text
CPU
Rendering
```

The rendering provider MAY internally contain:

```text
VSG
Vulkan
```

but those are implementation details.

---

# 43. Testing Strategy

Testing MUST follow the semantic abstraction hierarchy.

```text
Specification Tests
        ↓
Core Unit Tests
        ↓
Domain Tests
        ↓
IR Tests
        ↓
Lowering Tests
        ↓
Execution Tests
        ↓
Integration Test
        ↓
Visual Smoke Test
```

---

# 44. Specification Tests

Tests MUST establish that the Golden Path semantics are explicitly represented.

Examples:

```text
particle has position
particle has velocity
simulation has time
step changes state
render state derives from simulation state
```

---

# 45. IR Tests

IR tests MUST verify:

* valid simulation IR parses;
* valid simulation IR verifies;
* invalid IR is rejected;
* `scr.step` has valid operands/results;
* required semantic information is present;
* lowering inputs are legal.

MLIR's tooling and pass infrastructure should be used rather than duplicating equivalent compiler functionality.

---

# 46. Lowering Tests

At minimum:

```text
SCR Simulation IR
        ↓
Lowered MLIR
```

MUST be tested.

The test MUST establish that:

* SCR operations are converted;
* resulting operations are legal;
* required types are converted;
* no unsupported SCR execution operations remain.

---

# 47. Execution Tests

The CPU provider MUST be tested against known state transitions.

Example:

```text
position = (0, 0)
velocity = (1, 0)
dt = 1

expected position = (1, 0)
```

Then:

```text
dt = 2

expected position = (3, 0)
```

The test MUST verify semantic results rather than internal implementation details.

---

# 48. End-to-End Test

A complete automated test SHOULD perform:

```text
construct semantic simulation
        ↓
compile
        ↓
verify
        ↓
lower
        ↓
execute
        ↓
observe
        ↓
compare expected state
```

The test SHOULD run without opening a graphical window.

---

# 49. Visual Smoke Test

A separate manual or automated graphical test MUST verify:

```text
application launches
window opens
simulation runs
objects are visible
objects move
application exits cleanly
```

The visual test is not a substitute for semantic tests.

---

# 50. Error Handling

The Golden Path MUST distinguish at minimum:

```text
SemanticError
IRError
VerificationError
LoweringError
ExecutionError
RenderingError
```

Errors SHOULD preserve provenance sufficient to identify the failing stage.

---

# 51. Provenance

The runtime SHOULD be able to associate:

```text
Semantic Operation
       ↓
IR Operation
       ↓
Transformation
       ↓
Lowered Operation
       ↓
Execution
```

at least during development/debug builds.

This is important because v0.0.1 is intended to validate the architecture rather than merely produce a visual result.

---

# 52. Observability

The Golden Path SHOULD expose enough information to diagnose:

* semantic program construction;
* generated IR;
* verification;
* transformation;
* lowering;
* execution;
* simulation time;
* frame time;
* render state.

A debug mode SHOULD allow intermediate IR to be emitted.

---

# 53. Required Developer Artifacts

The implementation SHOULD produce:

```text
golden_path.mlir
```

or an equivalent inspectable IR artifact.

Developers SHOULD be able to inspect:

```text
semantic IR
↓
lowered IR
↓
LLVM-compatible representation
```

without requiring the graphical application.

---

# 54. MLIR Tooling

The implementation SHOULD integrate with standard MLIR tools where practical.

At minimum, development should support:

```text
parse
verify
print
run passes
inspect IR
```

The existing `mlir-opt` workflow is particularly appropriate for this stage because it exercises parsing, verification, pass execution, and IR inspection without requiring the full runtime.

---

# 55. Compiler Boundary

The compiler MUST expose a conceptual API:

```text
Semantic Program
       ↓
Compiler
       ↓
Compiled Program
```

The compiler MAY internally use:

* MLIR contexts;
* dialect registration;
* pass managers;
* conversion targets;
* rewrite patterns;
* LLVM translation.

These details MUST NOT leak into the semantic application API.

---

# 56. Runtime Boundary

The runtime MUST expose:

```text
Compiled Program
       ↓
Runtime Instance
       ↓
State Evolution
```

The runtime MAY internally select:

* CPU;
* JIT;
* native execution;
* future GPU;
* future distributed providers.

The v0.0.1 implementation only needs CPU.

---

# 57. Rendering Boundary

The rendering subsystem MUST expose:

```text
Render State
       ↓
Renderer
```

The renderer MUST NOT require the application to know:

* Vulkan;
* VSG;
* command buffers;
* descriptor sets;
* pipelines;
* GPU memory;
* swapchains.

Those belong to the rendering implementation.

---

# 58. Golden Path Data Flow

The complete data flow MUST be approximately:

```text
Semantic Program
      │
      ▼
Simulation Definition
      │
      ▼
Initial State
      │
      ▼
Simulation IR
      │
      ▼
MLIR
      │
      ▼
Lowered Program
      │
      ▼
CPU Execution
      │
      ▼
Simulation State
      │
      ▼
Render Projection
      │
      ▼
Render State
      │
      ▼
Renderer
      │
      ▼
Frame
```

---

# 59. Golden Path Control Flow

The complete control flow MUST be:

```text
compile
   │
   ▼
instantiate
   │
   ▼
initialize renderer
   │
   ▼
run
   │
   ├── acquire dt
   ├── step simulation
   ├── observe state
   ├── project render state
   ├── update renderer
   ├── render
   └── present
   │
   ▼
shutdown
```

---

# 60. Architectural Invariants

### GP-INV-001 — Semantic Primacy

Semantic definitions remain authoritative.

### GP-INV-002 — IR Representation

IR represents semantics but does not redefine them.

### GP-INV-003 — Compiler Separation

Compilation remains separate from application semantics.

### GP-INV-004 — Execution Separation

Execution provider remains separate from semantic definition.

### GP-INV-005 — Simulation Authority

Simulation state is authoritative over render state.

### GP-INV-006 — Rendering Separation

Rendering does not define simulation semantics.

### GP-INV-007 — Explicit Time

Simulation time is explicitly represented.

### GP-INV-008 — Determinism

The reference workload is deterministic.

### GP-INV-009 — Progressive Lowering

Higher-level semantics are lowered progressively.

### GP-INV-010 — Provider Independence

The semantic workload does not depend on CPU-specific implementation.

### GP-INV-011 — Renderer Independence

The semantic workload does not depend on VSG or Vulkan.

### GP-INV-012 — Domain Separation

Domains retain their semantic boundaries.

### GP-INV-013 — Existing Infrastructure Reuse

Existing MLIR infrastructure is preferred over redundant SCR implementations.

### GP-INV-014 — Inspectability

Intermediate representations remain inspectable.

### GP-INV-015 — End-to-End Traceability

The major stages of the Golden Path remain traceable.

---

# 61. Definition of Done

SCR v0.0.1 Golden Path is COMPLETE when all of the following are true:

## Semantic

* [ ] Particle semantics are defined.
* [ ] Simulation semantics are defined.
* [ ] State semantics are explicit.
* [ ] Time semantics are explicit.
* [ ] Dynamics step is defined.

## IR

* [ ] Simulation can be represented in SCR IR.
* [ ] IR verifies.
* [ ] IR can be inspected.
* [ ] Required SCR operations are defined.
* [ ] Existing MLIR dialects are reused where appropriate.

## Compilation

* [ ] SCR IR can be transformed.
* [ ] SCR operations can be lowered.
* [ ] Lowered IR is legal.
* [ ] LLVM-compatible representation can be produced.

## Execution

* [ ] CPU provider executes the program.
* [ ] Simulation state advances.
* [ ] Deterministic execution test passes.
* [ ] Runtime can observe resulting state.

## Rendering

* [ ] Simulation state can become render state.
* [ ] Renderer accepts render state.
* [ ] VSG provider works.
* [ ] Vulkan window opens.
* [ ] Particles are visible.
* [ ] Particles move.

## Integration

* [ ] Golden Path example runs end-to-end.
* [ ] Automated end-to-end test passes.
* [ ] Visual smoke test passes.
* [ ] No semantic layer directly depends on VSG.
* [ ] No semantic layer directly depends on LLVM.
* [ ] No application code directly depends on MLIR internals.

---

# 62. Golden Path Demonstration

The canonical demonstration MUST be:

```text
$ cargo run --example golden_path
```

or the equivalent repository command.

Expected result:

```text
SCR Golden Path
────────────────────────────────

Semantic program:
    particle simulation

Compiler:
    SCR → MLIR → CPU

Runtime:
    simulation running

Renderer:
    VSG / Vulkan

[ graphical window ]

    •       •
       •
  •          •
       •  •
          •
```

The particles MUST move continuously until the application exits.

---

# 63. First Expansion After v0.0.1

Once the Golden Path is complete, expansion SHOULD proceed from the working trunk rather than creating parallel architectures.

Recommended sequence:

```text
v0.0.1
Simple particles
    │
    ▼
v0.0.2
Fields
    │
    ▼
v0.0.3
Geometry / topology
    │
    ▼
v0.0.4
Physics
    │
    ▼
v0.0.5
Agents
    │
    ▼
v0.0.6
GPU execution
    │
    ▼
v0.0.7
Streams / messaging
    │
    ▼
v0.0.8
Neural / perception
    │
    ▼
v0.0.9
Learning / adaptation
    │
    ▼
v0.1.0
Distributed / heterogeneous execution
```

These version numbers are planning labels, not commitments.

---

# 64. Expansion Rule

Every subsequent feature SHOULD be added by extending the existing Golden Path.

For example:

```text
Field
  ↓
Field IR
  ↓
Dynamics
  ↓
Simulation
  ↓
Render
```

rather than creating a separate execution architecture for Fields.

Likewise:

```text
GPU
```

should eventually replace or supplement:

```text
CPU Provider
```

rather than requiring a separate semantic application.

---

# 65. Golden Path as Architectural Test

The Golden Path is itself an architectural conformance test.

A proposed new subsystem SHOULD be evaluated by asking:

1. Can it express its semantics independently?
2. Can it enter the semantic IR?
3. Can it participate in the existing transformation model?
4. Can it be lowered?
5. Can it execute through a provider?
6. Can it participate in simulation state?
7. Can it produce or consume render state where appropriate?
8. Does it preserve the existing semantic boundaries?

If the answer requires bypassing the Golden Path architecture, the proposed subsystem MUST be reviewed before implementation.

---

# 66. What v0.0.1 Proves

A successful Golden Path proves that SCR can:

```text
describe computation semantically
            ↓
represent that computation
            ↓
compile it
            ↓
execute it
            ↓
evolve state
            ↓
project state
            ↓
render the result
```

This establishes the first complete SCR computational loop.

It demonstrates that:

> **The semantic library is not merely documentation.**

It can become an executable computational language.

---

# 67. What v0.0.1 Does Not Prove

A successful Golden Path does NOT claim that SCR already supports:

* arbitrary semantic domains;
* automatic provider selection;
* hardware-independent performance;
* distributed execution;
* semantic equivalence across arbitrary implementations;
* generalized adaptive execution;
* complete semantic hypergraph execution;
* universal simulation;
* automatic lowering of arbitrary semantics.

Those remain future engineering and research objectives.

---

# 68. Final Principle

The v0.0.1 Golden Path exists to prove one proposition:

> **A computation can begin as semantic meaning, become executable computational structure through SCR and MLIR, evolve state through a runtime, and produce a visible manifestation without the semantic model becoming coupled to its compiler, execution provider, or renderer.**

The particle simulation is merely the smallest useful witness of that proposition.

The implementation should therefore optimize for:

```text
semantic integrity
+
architectural separation
+
inspectability
+
end-to-end execution
+
visible proof
```

rather than breadth.

**The first milestone is not a complete computational universe.**

It is proving that the universe has a working trunk.
