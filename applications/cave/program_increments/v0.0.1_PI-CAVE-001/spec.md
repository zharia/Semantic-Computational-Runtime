# PI-CAVE-001

## Semantic Spatial Desktop — Minimum Viable Proof of Concept

**Program Increment:** PI-CAVE-001
**Project:** Cave
**Parent System:** Semantic Computational Runtime (SCR)
**Status:** Normative Implementation Specification
**Version:** 0.0.1
**Target:** Proof of Concept
**Priority:** Critical
**Implementation Strategy:** Semantic-first, provider-backed, end-to-end
**Primary Language:** Mojo / MLIR
**Provider Languages:** C/C++/Rust as required by selected providers
**Initial Platform:** Linux / Wayland / OpenGL
**Initial Spatial Provider:** OpenVDB
**Initial Rendering Provider:** OGRE + OpenGL
**Initial Compositor/Protocol Provider:** Louvre + Wayland
**Initial GPU Buffer Path:** DMA-BUF
**Optional GPU Volume Representation:** NanoVDB
**Messaging:** SCR/HyrxMQ or AMQP-compatible transport where required
**Execution:** SCR Reference Executor + EGS

---

## Milestone Architecture & Implementation Index

This specification has been decomposed into 11 formal milestones and 37 sprints strictly complying with [`docs/*.md`](../../docs/).  
Master Roadmap & Compliance Matrix: **[`milestones/README.md`](milestones/README.md)**

| Milestone | Code | Domain | Spec | Sprints |
| :--- | :--- | :--- | :--- | :--- |
| **001** | `PI-CAVE-001A` | Semantic Foundation | [`spec.md`](milestones/001_PI-CAVE-001A_semantic_foundation/spec.md) | 3 sprints |
| **002** | `PI-CAVE-001B` | Semantic Hypergraph | [`spec.md`](milestones/002_PI-CAVE-001B_hypergraph/spec.md) | 4 sprints |
| **003** | `PI-CAVE-001C` | Spatial Semantics & Frames | [`spec.md`](milestones/003_PI-CAVE-001C_spatial/spec.md) | 3 sprints |
| **004** | `PI-CAVE-001D` | Desktop Ontology | [`spec.md`](milestones/004_PI-CAVE-001D_desktop_ontology/spec.md) | 4 sprints |
| **005** | `PI-CAVE-001E` | Wayland & Louvre Adapter | [`spec.md`](milestones/005_PI-CAVE-001E_wayland_louvre/spec.md) | 3 sprints |
| **006** | `PI-CAVE-001F` | OGRE & OpenGL Rendering | [`spec.md`](milestones/006_PI-CAVE-001F_rendering/spec.md) | 3 sprints |
| **007** | `PI-CAVE-001G` | DMA-BUF Zero-Copy Pipeline | [`spec.md`](milestones/007_PI-CAVE-001G_dma_buf/spec.md) | 3 sprints |
| **008** | `PI-CAVE-001H` | OpenVDB Spatial Fields | [`spec.md`](milestones/008_PI-CAVE-001H_openvdb/spec.md) | 3 sprints |
| **009** | `PI-CAVE-001I` | Semantic Effect Pipeline | [`spec.md`](milestones/009_PI-CAVE-001I_effect/spec.md) | 4 sprints |
| **010** | `PI-CAVE-001J` | EGS & Reference Executor | [`spec.md`](milestones/010_PI-CAVE-001J_egs_executor/spec.md) | 3 sprints |
| **011** | `PI-CAVE-001K` | End-to-End Proof & Acceptance | [`spec.md`](milestones/011_PI-CAVE-001K_end_to_end/spec.md) | 4 sprints |

---

# 1. Executive Summary

PI-CAVE-001 establishes the minimum complete implementation required to demonstrate that SCR can act as a **semantic computational substrate for a spatial desktop environment**.

The increment is successful only when a real Wayland client produces a real surface whose semantic identity is represented inside SCR, whose spatial state is represented semantically, whose visual manifestation is rendered through OGRE/OpenGL, whose client buffer can traverse the Wayland/DMA-BUF path without an unnecessary CPU pixel-copy path, and whose semantic object remains identifiable while its provider manifestations change.

The proof of concept must additionally demonstrate that a spatial effect can be represented as a **semantic field transformation**, rather than merely as a rendering trick.

The minimum effect pipeline is:

```text
Wayland Client
      │
      ▼
    Louvre
      │
      ▼
 Wayland Surface
      │
      ▼
 DMA-BUF / Native GPU Resource
      │
      ▼
 SCR Semantic Surface
      │
      ├───────────────┐
      │               │
      ▼               ▼
Spatial State      Field State
      │               │
      └──────┬────────┘
             ▼
      Semantic Effect
             │
             ▼
      OpenVDB Field
             │
       ┌─────┴─────┐
       ▼           ▼
    Level Set   Density/
       │        Velocity
       │           │
       └─────┬─────┘
             ▼
       Render Manifestation
             │
             ▼
       OGRE / OpenGL
             │
             ▼
          Display
```

This PI does **not** attempt to implement a complete semantic desktop, a production compositor, a complete physics engine, a complete rendering engine, or a general-purpose volumetric simulation system.

It establishes the architectural path through which those systems can subsequently be built.

---

# 2. Strategic Objective

The objective is to prove the following proposition:

> **A desktop can be represented as a semantic computational field whose objects, relationships, spatial state, physical manifestations, effects and provider resources are distinct but composable representations of one underlying semantic state.**

The PI therefore tests whether SCR can successfully bridge:

1. semantic identity;
2. semantic topology;
3. spatial state;
4. application/client state;
5. Wayland protocol state;
6. GPU resource state;
7. rendering state;
8. sparse volumetric field state;
9. effect state;
10. lifecycle state;
11. temporal state;
12. physical manifestation.

The POC must demonstrate that these layers remain distinguishable.

---

# 3. Architectural Thesis

Cave is not fundamentally a compositor.

Cave is a **semantic spatial computer whose first physical manifestation is a Wayland desktop**.

The desktop is therefore modelled as a semantic field.

A simplified semantic representation is:

```text
Desktop
 ├── Workspace
 │    ├── Surface
 │    │    ├── Buffer
 │    │    └── Application
 │    │
 │    └── Surface
 │
 ├── Input Field
 ├── Spatial Field
 ├── Rendering Field
 └── Effect Field
```

These are semantic structures.

Louvre, Wayland, DMA-BUF, OGRE, OpenGL, OpenVDB and NanoVDB are providers and manifestations.

They are not the semantic ontology.

---

# 4. Normative Architectural Principles

## 4.1 Semantic Authority

SCR is authoritative for:

* semantic identity;
* semantic object relationships;
* semantic references;
* semantic state;
* semantic spatial relationships;
* semantic transformations;
* semantic lifecycle;
* semantic provenance;
* semantic effect definitions;
* semantic field relationships;
* provider-independent meaning.

Providers are authoritative only for their own implementation state.

---

## 4.2 Provider Independence

No Cave semantic definition may require:

* Louvre;
* Wayland;
* OGRE;
* OpenGL;
* DMA-BUF;
* OpenVDB;
* NanoVDB;
* Linux DRM;
* a specific GPU;
* a specific compositor API

to retain its meaning.

Removing a provider must not invalidate the semantic definition.

This follows the SCR provider architecture: SCR defines computational meaning while providers perform computation and manifestation.

---

## 4.3 Physical Manifestation Is Not Semantic Identity

The following are distinct:

```text
Semantic Surface
Wayland wl_surface
GPU texture
DMA-BUF
OGRE texture
OpenGL texture
NanoVDB grid
OpenVDB grid
memory allocation
file
provider handle
```

They may participate in relationships such as:

```text
SemanticSurface
    └── manifests-as ──► WaylandSurface

WaylandSurface
    └── backed-by ─────► DMABUF

DMABUF
    └── imported-as ───► GLTexture

GLTexture
    └── represented-by ► OgreTexture
```

Changing one manifestation must not silently change the identity of the semantic object.

---

# 5. Scope

PI-CAVE-001 contains the following mandatory capabilities.

## 5.1 Core Semantic Capabilities

* semantic identity;
* semantic references;
* semantic objects;
* relations;
* incidences;
* lifecycle;
* provenance;
* state;
* transformation;
* spatial state.

## 5.2 Hypergraph Capabilities

The POC must use the SCR hypergraph semantic model.

Minimum model:

```text
H = (E, R, I, ρ)
```

where:

* `E` = semantic elements;
* `R` = semantic relations;
* `I` = incidences;
* `ρ` = optional role/direction information.

Incidences are first-class.

The following must be representable:

```text
Surface ──input──────► RenderOperation
Surface ──buffer─────► Buffer
Surface ──parent─────► Workspace
Surface ──manifest───► GPUTexture
Effect  ──field──────► DensityField
Effect  ──velocity───► VelocityField
```

---

# 6. Graph and Hypergraph Requirement

Ordinary graph semantics are insufficient as the fundamental representation.

A relation may have:

* zero participants;
* one participant;
* two participants;
* many participants.

Therefore:

```text
Relation(R)
Incidence(R, A)
Incidence(R, B)
Incidence(R, C)
```

must not be reduced semantically to pairwise edges.

Ordinary graphs may subsequently be produced as projections.

Examples:

```text
Hypergraph
    ↓
Incidence Graph
    ↓
BGL

Hypergraph
    ↓
Sparse Matrix
    ↓
GraphBLAS
```

These are representations/projections.

They are not replacements for the semantic hypergraph.

---

# 7. Nullary Relations

A nullary relation is valid.

For:

```text
|I(R)| = 0
```

the relation remains a valid semantic object.

This is required because Cave may represent:

* zero-argument operations;
* constants;
* semantic facts;
* pending relations;
* lifecycle events;
* effects awaiting attachment.

Removing the final incidence from a relation does not destroy the relation.

---

# 8. Lifecycle Semantics

Cave must distinguish:

```text
detach
delete
invalidate
destroy
reclaim
```

These are not interchangeable.

For example:

```text
SemanticSurface
    │
    ├── Wayland manifestation
    ├── GPU manifestation
    └── Render manifestation
```

Destroying the GPU texture does not destroy the semantic surface.

A provider resource may be:

```text
created
bound
active
replaced
invalidated
destroyed
reclaimed
```

while the semantic object remains alive.

---

# 9. Reference Semantics

A semantic reference is not:

* a pointer;
* an array offset;
* a provider index;
* a GPU handle;
* a memory address;
* a Wayland object pointer.

A semantic reference identifies the semantic object.

References must survive:

* provider relocation;
* representation changes;
* serialization;
* manifestation replacement;
* topology mutation.

A reference to a deleted semantic object must never silently resolve to a different object.

---

# 10. Cave Semantic Ontology

The minimum ontology consists of the following concepts.

## 10.1 Desktop

```text
Desktop
```

Represents the semantic desktop environment.

Properties:

* identity;
* state;
* workspaces;
* surfaces;
* spatial field;
* input field;
* rendering field;
* effect field.

---

## 10.2 Workspace

```text
Workspace
```

Represents a semantic spatial subdivision.

Properties:

* identity;
* parent desktop;
* spatial extent;
* coordinate frame;
* surfaces;
* state.

---

## 10.3 Surface

```text
Surface
```

Represents a semantic visible application surface.

Properties:

* identity;
* application;
* geometry;
* transform;
* visibility;
* state;
* buffer;
* parent;
* provider manifestations.

---

## 10.4 Application

Represents the semantic application/client.

Properties:

* identity;
* process;
* client connection;
* surfaces;
* capabilities;
* provenance.

---

## 10.5 Buffer

Represents semantic image data.

It is not synonymous with:

* DMA-BUF;
* GL texture;
* CPU buffer;
* file;
* Wayland buffer.

---

# 11. Spatial Semantics

Minimum spatial concepts:

```text
CoordinateSpace
ReferenceFrame
Position
Orientation
Scale
Transform
Bounds
Region
```

A transform is a semantic object.

Minimum required transform:

```text
T : local-space → parent-space
```

Composition must support:

```text
Tworld = Tparent ∘ Tlocal
```

The implementation may use matrices internally, but matrix representation is not the semantic definition.

---

# 12. Spatial Hierarchy

Minimum hierarchy:

```text
Desktop
   │
   ▼
Workspace
   │
   ▼
Surface
   │
   ▼
Content
```

Each object must have:

* local coordinate space;
* parent relationship;
* transform;
* derived world transform.

The semantic model must permit a surface to move without changing its identity.

---

# 13. Inverse Spatial Mapping

Cave must demonstrate:

```text
world → local
```

inverse transformation.

This is required for interaction.

For a pointer coordinate:

```text
Pworld
```

the system must calculate:

```text
Plocal = T^-1(Pworld)
```

where the inverse is valid.

This must be demonstrated for at least one transformed surface.

---

# 14. Rendering Semantics

Rendering is a manifestation of semantic state.

The semantic render model must contain at minimum:

```text
RenderObject
Geometry
Material
Texture
Transform
Camera
RenderTarget
```

However, these are semantic concepts.

OGRE objects are provider manifestations.

Example:

```text
SemanticSurface
       │
       ▼
SemanticRenderObject
       │
       ▼
OGRE Entity / Texture / SceneNode
       │
       ▼
OpenGL
```

---

# 15. OGRE Provider

OGRE is the initial rendering provider.

The adapter must translate:

```text
SCR semantic render state
        ↓
OGRE scene state
```

The adapter must not expose OGRE-specific concepts as required SCR semantics.

Provider state must remain distinguishable from semantic state.

---

# 16. OpenGL Provider

OpenGL is the initial physical rendering backend.

The minimum POC requires:

* OpenGL context;
* texture import;
* texture binding;
* framebuffer/render target;
* draw operation;
* presentation.

OpenGL handles must never become semantic identity.

---

# 17. Wayland Provider

Wayland provides:

* client protocol;
* surfaces;
* buffers;
* input events;
* lifecycle events.

Wayland protocol objects remain provider objects.

Cave semantic objects are separate.

---

# 18. Louvre Provider

Louvre provides the initial compositor/protocol implementation.

The provider adapter must translate:

```text
Louvre state
    ↓
SCR semantic events/state
```

and:

```text
SCR semantic state
    ↓
Louvre operations
```

The semantic model must not become a mirror of Louvre's internal class hierarchy.

---

# 19. DMA-BUF Provider

The POC must use a DMA-BUF-capable buffer path where the selected client/provider path supports it.

Linux DMA-BUF exists specifically to allow buffers to be exchanged between subsystems without requiring ownership to remain with a single subsystem; Wayland's Linux DMA-BUF protocol defines the buffer import path and synchronization requirements.

The POC must record:

```text
buffer identity
format
dimensions
stride
modifier if applicable
file descriptor/provider handle
producer
consumer
synchronization state
lifetime
```

The FD itself is not semantic identity.

---

# 20. Zero-Copy Requirement

The minimum rendering path should be:

```text
Client
  ↓
DMA-BUF
  ↓
Louvre
  ↓
GPU import
  ↓
OpenGL texture
  ↓
OGRE
  ↓
display
```

No CPU-side pixel copy should occur in the normal path.

If hardware/provider limitations prevent this path, the implementation must explicitly report the fallback rather than silently claiming zero-copy.

---

# 21. Synchronization

The POC must explicitly represent ownership/synchronization state.

Minimum states:

```text
Produced
Available
Acquired
Rendering
Presented
Released
```

Provider synchronization mechanisms may include DMA-BUF fencing or Linux DRM synchronization mechanisms.

Synchronization is provider state.

SCR records the semantic consequence:

```text
buffer available for semantic consumer
```

rather than exposing kernel synchronization primitives as semantic ontology.

---

# 22. OpenVDB Provider

OpenVDB is a **first-class Cave provider**.

It must not be relegated to an optional graphics effect.

OpenVDB is particularly appropriate because its sparse hierarchical representation supports volumetric data, time-varying fields, level sets, filtering, CSG, sampling, voxelization, advection and vector-field operations.

The semantic layer therefore defines:

```text
Volume
ScalarField
VectorField
DensityField
VelocityField
TemperatureField
DistanceField
LevelSet
SpatialField
```

OpenVDB provides implementations.

---

# 23. OpenVDB Semantic Mapping

Minimum mapping:

| SCR Concept   | OpenVDB Representation         |
| ------------- | ------------------------------ |
| ScalarField   | scalar VDB grid                |
| VectorField   | vector VDB grid                |
| DensityField  | fog-volume style grid          |
| VelocityField | vector/staggered field         |
| DistanceField | SDF                            |
| LevelSet      | level-set grid                 |
| Volume        | VDB grid                       |
| SpatialField  | VDB spatially transformed grid |
| Region        | active voxel topology / mask   |
| Transform     | VDB grid transform             |

OpenVDB itself distinguishes data storage from spatial interpretation through grid coordinates and transforms, which aligns strongly with the SCR separation between representation and semantic meaning.

---

# 24. OpenVDB Effects

The minimum POC must implement one real effect through semantic fields.

Required demonstration:

```text
Surface
   │
   ▼
Effect Event
   │
   ▼
Velocity Field
   │
   ▼
Density Field
   │
   ▼
OpenVDB
   │
   ▼
Volumetric Manifestation
   │
   ▼
Renderer
```

The exact effect may be:

* smoke;
* wake;
* expanding distortion field;
* volumetric pulse;
* fluid-like displacement;
* particle-to-volume effect.

Smoke is the preferred first implementation because it naturally exercises density + velocity + advection.

---

# 25. Minimum Smoke/Field Effect

Required semantic objects:

```text
Emitter
VelocityField
DensityField
EffectState
TimeStep
VolumeManifestation
```

At each simulation step:

```text
Emitter
    ↓
source density
    ↓
velocity field
    ↓
advection
    ↓
density field
    ↓
render representation
```

The implementation may use simplified physics.

The POC does not require a physically accurate Navier–Stokes solver.

It must demonstrate that the effect exists as a semantic field transformation.

---

# 26. Physics Provider Strategy

Physics must not be conflated into a single provider.

## OpenVDB

Responsible for:

* spatial fields;
* scalar fields;
* vector fields;
* density;
* velocity;
* distance fields;
* level sets;
* sparse volumetric state;
* advection;
* field operations;
* volumetric effects.

## Chrono

Responsible where required for:

* rigid bodies;
* multibody dynamics;
* constraints;
* mechanical contact;
* articulated systems.

The SCR physics domain sits above both.

---

# 27. Minimum Physics POC

The POC requires only a **field-based physical effect**.

It does not require full rigid-body physics.

Minimum acceptable implementation:

```text
Effect Source
     ↓
Velocity Field
     ↓
Advection
     ↓
Density / Distance Field
     ↓
Rendered Manifestation
```

An optional second milestone may add:

```text
RigidBody
     ↓
Chrono
     ↓
Transform
     ↓
SCR Spatial State
```

but this is not required to declare PI-CAVE-001 complete.

---

# 28. NanoVDB

NanoVDB is an optional but strongly preferred POC component.

It provides a compact GPU-oriented representation of sparse VDB data and has been designed for applications such as GPU rendering and collision detection. Current official documentation lists interoperability with CUDA, OpenGL, Vulkan and other graphics APIs.

NanoVDB must be treated as a **representation/provider**, not a separate semantic domain.

Preferred path:

```text
OpenVDB
   ↓
NanoVDB
   ↓
GPU
   ↓
OGRE/OpenGL
```

The semantic field remains unchanged.

---

# 29. Temporal Semantics

Every effect state must have a semantic time.

Minimum:

```text
t
Δt
step
state
previous-state
next-state
```

An effect transition is:

```text
S(t + Δt) = F(S(t), Δt, inputs)
```

The function `F` must be represented semantically as a transformation.

This provides the first bridge toward SCR's broader temporal computational model.

---

# 30. Semantic Hypergraph Representation of a Frame

A representative frame should be expressible approximately as:

```text
Desktop
  ├──contains──► Workspace
  │                 │
  │                 ├──contains──► Surface A
  │                 └──contains──► Surface B
  │
  ├──has-input-field──► InputField
  │
  ├──has-spatial-field──► SpatialField
  │
  └──has-render-field──► RenderField
```

A surface:

```text
Surface A
  ├──owned-by────► Application
  ├──uses───────► Buffer
  ├──located-in─► Workspace
  ├──transformed-by─► Transform
  ├──rendered-as─► RenderObject
  └──manifested-as─► GPUResource
```

An effect:

```text
Effect
  ├──source──────► Surface
  ├──writes──────► DensityField
  ├──uses────────► VelocityField
  ├──advances-by─► TimeStep
  └──manifests-as► Volume
```

---

# 31. Hypergraph Provider

The POC must use the SCR hypergraph abstraction.

Candidate provider qualification order:

1. oxgraph;
2. Rust `hypergraph`;
3. another qualified external provider;
4. minimal internal reference provider.

The selection must be made through the SCR provider qualification process.

The semantic implementation must not become coupled to provider-specific node/edge structures.

---

# 32. Provider Capability Model

The provider interface must be capability-based.

Minimum capabilities:

```text
HypergraphTopology
HypergraphIncidence
HypergraphIdentity
HypergraphTraversal
HypergraphMutation
HypergraphProjection
```

Optional:

```text
HypergraphPersistence
HypergraphParallel
HypergraphStreaming
HypergraphQuery
```

Cave requests capabilities.

Cave does not request:

```text
"oxgraph"
```

as its semantic requirement.

---

# 33. Semantic Machine

Cave must instantiate the SCR Semantic Machine Model.

Minimum computational spaces:

```text
Cave Process
   │
   ├── Wayland Space
   ├── Rendering Space
   ├── Semantic Space
   └── Effect Space
```

The actual operating-system/container structure may differ.

The important requirement is that the semantic model can represent:

* computational space;
* resources;
* execution context;
* process;
* provider;
* field;
* location;
* capability.

---

# 34. Executable Semantic Hypergraph

The POC must contain at least one executable semantic graph segment.

Example:

```text
WaylandEvent
      │
      ▼
SurfaceStateUpdate
      │
      ▼
SpatialTransform
      │
      ▼
RenderState
      │
      ▼
OGREManifestation
```

Effect path:

```text
PointerEvent
      │
      ▼
EffectInput
      │
      ▼
VelocityFieldUpdate
      │
      ▼
OpenVDBAdvection
      │
      ▼
DensityField
      │
      ▼
RenderVolume
```

These are executable semantic transformations.

---

# 35. EGS Responsibilities

EGS resolves:

```text
semantic capability
        ↓
provider capability
        ↓
provider instance
        ↓
execution binding
```

For example:

```text
Capability:
    SparseScalarField

Provider:
    OpenVDB

Capability:
    GPUVolumeRead

Provider:
    NanoVDB

Capability:
    RenderScene

Provider:
    OGRE

Capability:
    WaylandSurfaceManagement

Provider:
    Louvre
```

EGS must not hard-code the semantic model around provider names.

---

# 36. Reference Executor

The Reference Executor provides the initial execution implementation.

It must support:

* semantic graph loading;
* semantic node/function resolution;
* input binding;
* output binding;
* provider invocation;
* state transition;
* result propagation;
* error propagation;
* provenance recording.

The executor does not need to be maximally optimized.

Correctness is more important than performance for this PI.

---

# 37. MLIR

MLIR is the canonical implementation representation.

The PI must implement semantic operations in MLIR where appropriate.

Example conceptual operation:

```text
%surface = cave.surface.create
%transform = cave.spatial.transform
%field = cave.field.create
%effect = cave.effect.apply
```

The precise dialect syntax is implementation-defined by the SCR dialect architecture.

The important rule is:

> MLIR is canonical; Mojo is the user-facing API.

---

# 38. Mojo

Mojo provides the ergonomic Cave/SCR application interface.

A minimal conceptual API should allow:

```mojo
desktop = Desktop.create()
workspace = desktop.workspace()
surface = workspace.surface(...)
surface.transform(...)
effect = surface.effect(...)
effect.apply(...)
```

The exact API is determined during implementation.

Mojo must not become a second semantic implementation.

---

# 39. Provider Adapter Boundary

Every provider requires an explicit adapter boundary.

Minimum adapters:

```text
SCR ↔ Hypergraph Provider
SCR ↔ Louvre
SCR ↔ Wayland
SCR ↔ DMA-BUF
SCR ↔ OGRE
SCR ↔ OpenGL
SCR ↔ OpenVDB
SCR ↔ NanoVDB
```

Adapters perform:

* representation conversion;
* lifecycle binding;
* resource mapping;
* capability exposure;
* error translation;
* synchronization translation;
* provenance recording.

Adapters must not redefine semantic meaning.

---

# 40. Identity Model

Every semantic object requires:

```text
semantic_id
content_id
version
```

where applicable.

Provider handles are additional:

```text
provider_id
provider_handle
provider_generation
```

These must never replace semantic identity.

---

# 41. Content Identity

For immutable or content-addressable state, content identity should be derived from canonical semantic representation.

It must not be derived from:

* memory address;
* provider object pointer;
* GPU handle;
* process-local index.

For mutable objects:

```text
semantic identity remains stable
content identity may change
version increments
```

---

# 42. Provenance

Every provider manifestation should record provenance sufficient to answer:

```text
What semantic object produced this?
Which provider created it?
Which provider version created it?
Which semantic state was used?
Which transformation produced it?
When was it created?
What replaced it?
```

Minimum provenance:

```text
semantic_object_id
provider_id
provider_version
operation_id
input_ids
output_ids
timestamp
version
```

---

# 43. Error Model

Errors must distinguish:

```text
SemanticError
ProviderError
ResourceError
SynchronizationError
CapabilityError
LifecycleError
ValidationError
ExecutionError
```

Provider-specific errors must not become semantic concepts unless promoted through the provider promotion process.

---

# 44. Conformance Invariants

The following invariants are mandatory.

## HYPERGRAPH-I001

Semantic element identity is provider-independent.

## HYPERGRAPH-I002

Relation identity is provider-independent.

## HYPERGRAPH-I003

Incidence identity is provider-independent.

## HYPERGRAPH-I004

Relation cardinality is unrestricted unless a domain contract explicitly constrains it.

## HYPERGRAPH-I005

Multiple relations may have identical participant sets.

## HYPERGRAPH-I006

Incidence role may distinguish otherwise identical topology.

## HYPERGRAPH-I007

Unary relations are valid.

## HYPERGRAPH-I008

Self-incidence is explicitly defined.

## HYPERGRAPH-I009

Nullary relations are valid.

## HYPERGRAPH-I010

Topology representation does not determine semantic identity.

## HYPERGRAPH-I011

Removing an incidence does not imply deleting the relation.

## HYPERGRAPH-I012

Deleting an element does not silently delete unrelated semantic objects.

## HYPERGRAPH-I013

Semantic references do not silently retarget.

## HYPERGRAPH-I014

Provider handles are not semantic identity.

## HYPERGRAPH-I015

Topology mutation does not imply identity mutation.

## HYPERGRAPH-I016

Provider manifestation lifecycle is independent of semantic object lifecycle.

## HYPERGRAPH-I017

Provider relocation does not alter semantic identity.

## HYPERGRAPH-I018

Serialization does not alter semantic identity.

## HYPERGRAPH-I019

Provider replacement does not alter semantic identity.

## HYPERGRAPH-I020

Semantic equality is independent of provider representation.

## HYPERGRAPH-I021

Physical resource destruction does not imply semantic object destruction.

## HYPERGRAPH-I022

A provider may fail to represent a semantic state only through an explicit capability limitation or adapter representation.

---

# 45. Cave-Specific Invariants

## CAVE-I001 — Surface Identity

A surface retains identity across buffer replacement.

## CAVE-I002 — Surface Spatial Identity

Moving a surface does not change its identity.

## CAVE-I003 — Render Identity

Replacing an OGRE/OpenGL resource does not change the semantic render object identity.

## CAVE-I004 — GPU Independence

GPU resource handles are never semantic identifiers.

## CAVE-I005 — Wayland Independence

Wayland object identity is not semantic Cave identity.

## CAVE-I006 — Provider Independence

Replacing a rendering provider does not change semantic surface meaning.

## CAVE-I007 — Effect Independence

Replacing the effect implementation does not change the semantic effect identity.

## CAVE-I008 — Field Identity

A density field may change values/topology without changing its semantic identity unless explicitly destroyed.

## CAVE-I009 — Time

Two states of the same semantic object at different times remain instances of the same semantic identity.

## CAVE-I010 — Inverse Mapping

Spatial input can be mapped from world coordinates to local coordinates using semantic transforms.

## CAVE-I011 — Manifestation

A semantic object may have zero, one or many provider manifestations.

---

# 46. Minimum Domain Library

The following semantic libraries must exist or be extended.

```text
lib/
  101_Core/
  201_Data/
  202_Math/
  203_Graph/
  204_Geometry/
  205_Topology/
  206_Spatial/
  207_Morphology/
  208_Physics/
  209_Dynamics/
  210_Field/
  211_Render/
  212_Stream/
  213_System/
  214_Agent/
```

Actual numbering must follow the repository's existing taxonomy if different.

Do not create duplicate domains merely to satisfy this list.

---

# 47. Domain Responsibilities

## Core

Identity, object, reference, lifecycle, state, provenance.

## Data

Values, buffers, images, metadata, serialization.

## Math

Scalars, vectors, matrices, transforms and numerical semantics.

## Graph

Hypergraph semantics and graph projections.

## Geometry

Geometric forms and spatial extents.

## Topology

Connectivity, containment, adjacency and neighbourhood.

## Spatial

Coordinate systems, transforms, frames, positions and orientation.

## Morphology

Shape, regions, bounds, dilation, erosion and structural change.

## Physics

Fields, physical quantities and physical relationships.

## Dynamics

Time, state transitions and evolution.

## Field

Semantic computational/spatial fields.

## Render

Semantic rendering structures.

## Stream

Events, frames, buffers and temporal data flows.

## System

Processes, resources, devices, execution contexts and capabilities.

## Agent

Applications, users, clients and interaction.

---

# 48. Minimum Formalization

Lean formalization is encouraged.

It is not necessary to formally prove every provider API.

The first formalization target is the semantic invariants.

Minimum recommended Lean definitions:

```text
Element
Relation
Incidence
Hypergraph
Reference
Identity
Lifecycle
Transform
Composition
```

Minimum proofs:

```text
P001 identity stability
P002 reference non-retargeting
P003 nullary relation validity
P004 incidence deletion
P005 relation persistence after final incidence removal
P006 transform composition
P007 provider representation independence
P008 manifestation independence
```

Formalization is a verification aid.

It does not replace executable conformance tests.

---

# 49. Test Architecture

Required:

```text
tests/
  hypergraph/
    semantic/
    conformance/
    pathological/

  cave/
    semantic/
    spatial/
    lifecycle/
    rendering/
    provider/
    effects/
    integration/
    e2e/
```

---

# 50. Hypergraph Tests

Minimum:

```text
HGT-C001 Element identity
HGT-C002 Relation identity
HGT-C003 Incidence identity
HGT-C004 Arbitrary cardinality
HGT-C005 Duplicate participant sets
HGT-C006 Directed/role-bearing incidence
HGT-C007 Self-incidence
HGT-C008 Unary relation
HGT-C009 Nullary relation
HGT-C010 Traversal
HGT-C011 Mutation
HGT-C012 Stable identity
HGT-C013 Graph projection
HGT-C014 Incidence projection
HGT-C015 Provider-independent identity
HGT-C016 Provider-independent equality
HGT-C017 Provenance
HGT-C018 Concurrency
HGT-C019 Serialization
HGT-C020 Representation independence
```

---

# 51. Spatial Tests

Minimum:

```text
SPATIAL-C001 local → parent transform
SPATIAL-C002 transform composition
SPATIAL-C003 world transform
SPATIAL-C004 inverse transform
SPATIAL-C005 transformed pointer mapping
SPATIAL-C006 hierarchy mutation
SPATIAL-C007 identity stability during movement
```

---

# 52. Lifecycle Tests

Minimum:

```text
LIFE-C001 semantic creation
LIFE-C002 provider manifestation
LIFE-C003 manifestation replacement
LIFE-C004 manifestation destruction
LIFE-C005 semantic persistence
LIFE-C006 reference stability
LIFE-C007 no silent retargeting
LIFE-C008 final incidence removal
LIFE-C009 provider failure
LIFE-C010 resource reclamation
```

---

# 53. Rendering Tests

Minimum:

```text
RENDER-C001 semantic render object
RENDER-C002 OGRE manifestation
RENDER-C003 OpenGL resource binding
RENDER-C004 resource replacement
RENDER-C005 texture lifecycle
RENDER-C006 frame presentation
RENDER-C007 semantic/provider separation
```

---

# 54. DMA-BUF Tests

Minimum:

```text
DMABUF-C001 buffer discovery
DMABUF-C002 metadata preservation
DMABUF-C003 import
DMABUF-C004 GPU binding
DMABUF-C005 synchronization
DMABUF-C006 release
DMABUF-C007 resource replacement
DMABUF-C008 no CPU-copy assertion
```

The no-copy assertion must be based on instrumentation/path tracing rather than assumption.

---

# 55. OpenVDB Tests

Minimum:

```text
VDB-C001 create scalar field
VDB-C002 create vector field
VDB-C003 create density field
VDB-C004 create velocity field
VDB-C005 spatial transform
VDB-C006 sparse update
VDB-C007 level set
VDB-C008 mesh → volume
VDB-C009 volume → render representation
VDB-C010 advection
VDB-C011 morphology
VDB-C012 field identity stability
VDB-C013 provider replacement
```

OpenVDB's documented functionality includes mesh/particle conversion, level-set operations, morphological operations, vector calculus, advection and sparse volumetric processing, making these appropriate provider capabilities rather than functionality Cave should independently recreate.

---

# 56. Effect Tests

Minimum:

```text
EFFECT-C001 effect identity
EFFECT-C002 source binding
EFFECT-C003 field creation
EFFECT-C004 field update
EFFECT-C005 time evolution
EFFECT-C006 render manifestation
EFFECT-C007 provider-independent semantic state
```

---

# 57. End-to-End Test

The mandatory E2E test is:

```text
Launch Cave
    ↓
Launch test Wayland client
    ↓
Client creates surface
    ↓
Cave creates semantic Surface
    ↓
Client commits buffer
    ↓
Buffer becomes semantic Buffer
    ↓
DMA-BUF imported where available
    ↓
Render manifestation created
    ↓
Surface visible
    ↓
Surface moved
    ↓
Surface transformed
    ↓
Pointer interaction
    ↓
Pointer mapped into surface-local coordinates
    ↓
Effect activated
    ↓
OpenVDB field created
    ↓
Field evolves
    ↓
Effect rendered
    ↓
GPU/render manifestation replaced
    ↓
Semantic Surface remains same identity
    ↓
Client closes
    ↓
Provider resources destroyed
    ↓
Semantic lifecycle completes correctly
```

---

# 58. Mandatory Demonstration Scenario

The POC must provide one reproducible scenario.

## Scenario: Semantic Spatial Surface

1. Start Cave.
2. Start compositor.
3. Start test Wayland client.
4. Display a visible surface.
5. Record semantic surface ID.
6. Move surface.
7. Rotate or otherwise transform surface.
8. Verify semantic ID remains unchanged.
9. Move pointer across transformed surface.
10. Demonstrate inverse spatial mapping.
11. Trigger a visual effect.
12. Create a velocity field.
13. Create density field.
14. Advance field state.
15. Render the effect.
16. Replace underlying GPU/render resource.
17. Verify semantic surface ID unchanged.
18. Destroy client.
19. Verify provider resources destroyed.
20. Verify lifecycle/provenance records.

---

# 59. Visual Demonstration

The POC should visibly demonstrate:

```text
┌──────────────────────────────────────────────┐
│                  Cave Desktop                │
│                                              │
│      ┌────────────────────┐                 │
│      │                    │                 │
│      │   Wayland Client   │                 │
│      │                    │                 │
│      └────────────────────┘                 │
│             ╲                                │
│              ╲ volumetric effect            │
│               ≋≋≋≋≋                         │
│                ≋≋≋                          │
│                                              │
│ Workspace / semantic spatial field           │
└──────────────────────────────────────────────┘
```

The effect should be generated from semantic field state.

It should not be a hard-coded post-processing shader.

---

# 60. Performance Requirements

This PI is not a benchmark release.

Correctness takes precedence.

However, the implementation must avoid intentionally pathological architecture.

Required:

* no mandatory CPU pixel-copy pipeline;
* no serializing every frame through JSON;
* no rebuilding the entire semantic graph every frame;
* no recreation of semantic identity every frame;
* no unnecessary conversion between equivalent provider representations;
* field updates should operate incrementally where practical.

---

# 61. Frame Architecture

The implementation should distinguish:

```text
Persistent Semantic State
```

from:

```text
Per-frame Derived State
```

Persistent:

```text
Surface identity
Workspace identity
Application identity
Effect identity
Field identity
```

Derived:

```text
world transform
render transform
GPU resource binding
frame data
temporary render objects
```

---

# 62. State Ownership

Ownership must be explicit.

### SCR owns

* semantic objects;
* semantic identity;
* semantic relationships;
* semantic state;
* provenance;
* capability requirements.

### Louvre owns

* Wayland protocol state;
* protocol resources.

### GPU provider owns

* GPU resource allocation;
* driver state;
* synchronization primitives.

### OGRE owns

* render-provider structures.

### OpenVDB owns

* VDB storage and algorithms.

### NanoVDB owns

* GPU-friendly sparse volume representation.

---

# 63. Resource Mapping

The mapping should look like:

```text
Semantic Object
      │
      ▼
Manifestation Relation
      │
      ▼
Provider Resource
```

not:

```text
Semantic Object = Provider Resource
```

A semantic surface may therefore have:

```text
Manifestation #1 → GLTexture 42
Manifestation #2 → GLTexture 57
```

over its lifetime.

---

# 64. Replacement Semantics

Resource replacement must be explicitly supported.

Example:

```text
Surface S
   │
   ├──manifests-as──► Texture A
   │
   └──later─────────► Texture B
```

The semantic object remains:

```text
S
```

The manifestation relation changes.

---

# 65. Provider Failure

If OpenVDB fails:

```text
DensityField
```

does not cease to exist semantically.

Possible state:

```text
DensityField
  state = provider-unavailable
```

EGS may:

* select another provider;
* defer execution;
* use fallback;
* report capability failure.

---

# 66. Capability Resolution

Provider resolution must operate approximately as:

```text
Requirement:
    "SparseVectorField"

      ↓

EGS

      ↓

Provider capability registry

      ↓

OpenVDB

      ↓

Adapter

      ↓

Provider operation
```

Applications must not contain provider-specific selection logic unless explicitly operating at an infrastructure boundary.

---

# 67. Configuration

The POC must have a declarative provider configuration.

Conceptually:

```yaml
providers:
  hypergraph:
    provider: ...
  compositor:
    provider: louvre
  rendering:
    provider: ogre
  graphics:
    provider: opengl
  volume:
    provider: openvdb
  gpu_volume:
    provider: nanovdb
```

The actual configuration format should follow SCR's existing configuration conventions.

---

# 68. Provider Metadata

Every provider must declare:

```text
provider identity
version
capabilities
dependencies
platform
license
resource requirements
health
status
```

Provider identity must remain separate from semantic object identity.

---

# 69. Repository Structure

The implementation should result in a structure approximately like:

```text
cave/
├── README.md
├── 101_definition.md
├── 102_status.yaml
├── 103_library.graph.json
│
├── docs/
│   ├── architecture/
│   │   ├── 101_cave_architecture.md
│   │   ├── 102_cave_provider_architecture.md
│   │   └── 103_cave_execution_model.md
│   │
│   └── pi/
│       └── PI-CAVE-001.md
│
├── lib/
│   ├── core/
│   ├── desktop/
│   ├── workspace/
│   ├── surface/
│   ├── spatial/
│   ├── field/
│   ├── effect/
│   ├── render/
│   └── interaction/
│
├── providers/
│   ├── wayland/
│   ├── louvre/
│   ├── dmabuf/
│   ├── ogre/
│   ├── opengl/
│   ├── openvdb/
│   └── nanovdb/
│
├── runtime/
│   ├── graph/
│   ├── executor/
│   └── egs/
│
├── tests/
│   ├── semantic/
│   ├── conformance/
│   ├── provider/
│   ├── spatial/
│   ├── lifecycle/
│   ├── effects/
│   └── e2e/
│
└── examples/
    └── semantic_desktop/
```

The actual SCR repository structure must take precedence where existing conventions differ.

---

# 70. Documentation Requirements

Every new semantic library directory must provide:

```text
101_spec.md
102_status.yaml
103_library.graph.json
```

Every provider must document:

```text
provider identity
capabilities
semantic mappings
resource mappings
lifecycle mappings
limitations
known divergences
tests
```

---

# 71. Specification Requirements

The semantic specification for each domain must contain:

1. Purpose
2. Scope
3. Semantic definitions
4. Relationships
5. State model
6. Lifecycle
7. Identity
8. References
9. Transformations
10. Invariants
11. Provider boundary
12. Representation independence
13. Formalization status
14. Conformance tests
15. Implementation status

---

# 72. Formalization Classification

Every semantic statement should be classified internally as:

```text
Definition
Invariant
Derived Property
Implementation Constraint
Provider Capability
Conjecture
```

The specification must not accidentally elevate an implementation constraint into semantic law.

---

# 73. Semantic vs Representation Separation

Example:

### Semantic

```text
DensityField
```

### Representation

```text
OpenVDB FloatGrid
```

### GPU representation

```text
NanoVDB Grid<float>
```

### Render representation

```text
3D texture / volume representation
```

All four may represent the same semantic field.

---

# 74. Mesh Interchange

The POC does not require a full asset pipeline.

However, the architecture must leave room for:

```text
glTF
OBJ
USD
Alembic
OpenVDB
```

The important distinction is:

```text
Interchange Representation
        ≠
Semantic Object
```

glTF, for example, should eventually be handled by an interchange provider and mapped into semantic geometry/render structures.

It must not become the semantic geometry model.

---

# 75. OpenVDB Interchange

OpenVDB should also serve as an interchange boundary for volumetric data.

The semantic system may map:

```text
Mesh
  ↓
Voxelization
  ↓
DistanceField
  ↓
LevelSet
  ↓
FogVolume
```

OpenVDB explicitly supports mesh/particle conversion, level-set processing, CSG, morphological operations and volumetric transforms, making this a natural provider pipeline.

---

# 76. Effect Architecture

Effects should be represented as transformations:

```text
Effect:
    Inputs
    State
    Transformation
    Outputs
```

Example:

```text
PointerPosition
      +
SurfaceGeometry
      +
VelocityField
      +
Time
      ↓
     Effect
      ↓
DensityField
```

The renderer consumes the resulting field.

---

# 77. Why This Matters

This establishes a crucial architectural distinction:

### Conventional graphics

```text
Event
  ↓
Shader
  ↓
Pixels
```

### Cave

```text
Event
  ↓
Semantic State
  ↓
Field Transformation
  ↓
Physical Field
  ↓
Manifestation
  ↓
Pixels
```

This is the minimum meaningful demonstration of Cave as an SCR application rather than an alternative compositor implementation.

---

# 78. Minimum Effect Algorithm

The initial implementation may use:

```text
density += source
velocity += force
density = advect(density, velocity, dt)
density = decay(density, dt)
```

The exact numerical method is implementation-defined.

The semantic contract is:

```text
Density(t + dt)
    =
F(
    Density(t),
    Velocity(t),
    Sources(t),
    dt
)
```

---

# 79. Spatial Effect

The first effect should preferably be attached to a surface.

For example:

```text
Pointer enters Surface
       ↓
Impulse
       ↓
Velocity field
       ↓
Density field
       ↓
Volume
       ↓
Rendered effect
```

This demonstrates interaction → semantics → field computation → rendering.

---

# 80. Optional Level-Set Effect

If implementation effort permits, the preferred second effect is:

```text
Surface Geometry
      ↓
OpenVDB SDF
      ↓
Level Set
      ↓
Offset / Morphology
      ↓
Rendered contour / volume
```

This demonstrates that a surface can participate simultaneously in:

```text
Geometry
Spatial
Morphology
Physics
Render
```

without changing its semantic identity.

---

# 81. Optional Collision Effect

A third optional demonstration:

```text
Surface
   ↓
SDF
   ↓
Velocity Field
   ↓
Collision Constraint
   ↓
Updated Field
```

NanoVDB is particularly appropriate for read-oriented sparse GPU access such as rendering and collision-style operations.

---

# 82. Application API

The final POC application should be able to express approximately:

```text
create desktop
create workspace
attach client
create surface
bind buffer
set transform
present
create effect
create field
advance field
render
destroy manifestation
replace manifestation
destroy client
```

The application should not need to directly manipulate:

```text
GL texture handles
OGRE SceneNode pointers
VDB tree internals
Wayland object pointers
DMA-BUF FDs
```

unless explicitly entering a provider escape hatch.

---

# 83. Provider Escape Hatch

Provider-specific operations are allowed when necessary.

They must be marked as:

```text
provider-specific
non-portable
non-semantic
```

An escape hatch must never silently become part of the semantic contract.

---

# 84. Completion Levels

## Level 0 — Documentation

Specifications exist.

## Level 1 — Semantic

Semantic objects and hypergraph model work without providers.

## Level 2 — Provider

Provider adapters function individually.

## Level 3 — Integrated

Wayland + SCR + OGRE + OpenVDB function together.

## Level 4 — Physical

Real client, real GPU resource, real display.

## Level 5 — Demonstration

Spatial effect executes and renders.

## Level 6 — Conformance

Identity/lifecycle/provider-independence tests pass.

PI-CAVE-001 requires **Level 6**.

---

# 85. Definition of Done

The PI is complete only when all of the following are true.

### Semantic

* [ ] Desktop exists semantically.
* [ ] Workspace exists semantically.
* [ ] Application exists semantically.
* [ ] Surface exists semantically.
* [ ] Buffer exists semantically.
* [ ] Spatial transforms exist semantically.
* [ ] Effect exists semantically.
* [ ] Field exists semantically.
* [ ] Identity is stable.

### Hypergraph

* [ ] Hypergraph model implemented.
* [ ] Incidences are first-class.
* [ ] Nullary relations work.
* [ ] Lifecycle semantics work.
* [ ] Provider independence tests pass.

### Wayland

* [ ] Real Wayland client connects.
* [ ] Surface creation captured.
* [ ] Buffer commit captured.
* [ ] Surface destruction captured.

### Louvre

* [ ] Louvre adapter operates.
* [ ] Semantic events produced.
* [ ] Semantic state can drive provider state.

### GPU

* [ ] DMA-BUF path works where supported.
* [ ] GPU resource imported.
* [ ] OpenGL renders it.
* [ ] No CPU pixel-copy is required in the normal path.
* [ ] Synchronization is correct.

### OGRE

* [ ] Semantic render object produces OGRE manifestation.
* [ ] Transform is propagated.
* [ ] Texture is displayed.

### Spatial

* [ ] Surface movement works.
* [ ] Surface transformation works.
* [ ] World/local transformation works.
* [ ] Pointer inverse transformation works.

### OpenVDB

* [ ] Scalar field works.
* [ ] Vector field works.
* [ ] Density field works.
* [ ] Velocity field works.
* [ ] Field transformation works.
* [ ] At least one effect uses OpenVDB.

### Effect

* [ ] Effect is represented semantically.
* [ ] Effect changes field state.
* [ ] Field state changes over time.
* [ ] Result is rendered.

### Lifecycle

* [ ] GPU resource replacement works.
* [ ] Semantic identity survives replacement.
* [ ] Provider resource destruction works.
* [ ] Semantic lifecycle completes correctly.

### Verification

* [ ] Automated semantic tests pass.
* [ ] Provider conformance tests pass.
* [ ] E2E test passes.
* [ ] Provenance is recorded.
* [ ] Formalization status is documented.
* [ ] No known semantic/provider boundary violation remains.

---

# 86. Acceptance Test

The following scenario is the authoritative acceptance test.

```text
AT-CAVE-001
```

### Given

A Linux system capable of running the selected Wayland/Louvre/OpenGL stack.

### When

1. Cave starts.
2. Louvre starts.
3. A test Wayland client connects.
4. The client creates a surface.
5. The client submits a buffer.
6. Cave creates a semantic Surface.
7. The surface is rendered.
8. The surface is translated and rotated.
9. Pointer input is received.
10. Pointer coordinates are mapped into local surface coordinates.
11. An effect is triggered.
12. A velocity field is created.
13. A density field is created.
14. OpenVDB advances the field.
15. The effect is rendered.
16. The render manifestation is replaced.
17. The client disconnects.

### Then

All of the following must hold:

```text
Surface semantic identity unchanged
        AND
Surface spatial identity unchanged
        AND
Effect semantic identity valid
        AND
Field semantic identity valid
        AND
Provider manifestations correctly tracked
        AND
No silent reference retargeting
        AND
No lifecycle confusion
        AND
Rendered output visible
        AND
E2E provenance complete
```

---

# 87. Failure Criteria

The PI fails if any of the following occur.

1. A provider object becomes the semantic identity.
2. Recreating a GPU resource creates a new semantic surface.
3. Destroying a GPU resource destroys a semantic surface without explicit semantic destruction.
4. Wayland protocol state becomes the Cave ontology.
5. OGRE types become required semantic types.
6. OpenVDB grid identity becomes semantic field identity.
7. Hypergraph semantics collapse relations into ordinary edges.
8. Nullary relations are rejected.
9. Removing the last incidence deletes a relation.
10. References silently retarget.
11. The effect exists only as a shader with no semantic field state.
12. The implementation requires a CPU pixel copy where the selected provider path supports direct GPU import.
13. OpenVDB is wrapped merely as a rendering utility rather than a semantic field provider.
14. Provider replacement requires changing semantic definitions.
15. The entire semantic graph is reconstructed every frame as an implementation shortcut.
16. The system cannot demonstrate lifecycle separation.

---

# 88. Non-Goals

The following are explicitly outside PI-CAVE-001:

* production compositor completeness;
* multi-GPU scheduling;
* full Wayland protocol coverage;
* complete desktop shell;
* full window manager policy;
* full physics engine;
* physically accurate fluid simulation;
* complete volumetric renderer;
* Vulkan-first rendering;
* distributed rendering;
* production-grade asset management;
* full glTF implementation;
* full OpenUSD integration;
* complete user authentication;
* complete desktop accessibility;
* complete input device support;
* GPU cluster execution.

These may become future PIs.

---

# 89. Recommended Implementation Order

## PI-CAVE-001A — Semantic Foundation

Implement:

```text
Identity
Object
Reference
Lifecycle
State
Provenance
```

---

## PI-CAVE-001B — Hypergraph

Implement:

```text
Element
Relation
Incidence
Role
Reference
Mutation
Traversal
```

Then establish conformance.

---

## PI-CAVE-001C — Spatial

Implement:

```text
CoordinateSpace
ReferenceFrame
Transform
Position
Orientation
Bounds
```

Then inverse mapping.

---

## PI-CAVE-001D — Desktop Ontology

Implement:

```text
Desktop
Workspace
Application
Surface
Buffer
```

---

## PI-CAVE-001E — Wayland/Louvre

Connect:

```text
Wayland
Louvre
SCR
```

and establish semantic surface lifecycle.

---

## PI-CAVE-001F — Rendering

Connect:

```text
SCR
 ↓
OGRE
 ↓
OpenGL
```

---

## PI-CAVE-001G — DMA-BUF

Implement:

```text
Buffer
 ↓
DMA-BUF
 ↓
GPU
```

and verify synchronization.

---

## PI-CAVE-001H — OpenVDB

Implement:

```text
SpatialField
ScalarField
VectorField
DensityField
VelocityField
DistanceField
LevelSet
```

with OpenVDB.

---

## PI-CAVE-001I — Effect

Implement:

```text
Event
 ↓
Effect
 ↓
VelocityField
 ↓
DensityField
 ↓
OpenVDB
 ↓
Render
```

---

## PI-CAVE-001J — EGS/Executor

Connect:

```text
Semantic Graph
 ↓
EGS
 ↓
Provider Resolution
 ↓
Reference Executor
 ↓
Providers
```

---

## PI-CAVE-001K — End-to-End

Execute:

```text
Wayland client
 ↓
Louvre
 ↓
SCR
 ↓
Semantic Hypergraph
 ↓
OGRE/OpenGL
 ↓
OpenVDB
 ↓
Effect
 ↓
Display
```

---

# 90. Development Method

Every implementation item follows:

```text
Describe
   ↓
Specify
   ↓
Formalize where useful
   ↓
Test
   ↓
Implement
   ↓
Validate
   ↓
Integrate
```

No provider implementation should be accepted solely because an API call works.

The semantic contract must be tested first.

---

# 91. Agent Implementation Rule

Development agents must not begin by implementing provider wrappers indiscriminately.

For every requested capability they must determine:

```text
1. Is this already defined by SCR?
2. Which SCR domain owns the semantic meaning?
3. Is the requirement semantic or representational?
4. Does an established provider already implement it?
5. What provider capability is required?
6. What adapter is required?
7. What invariant must be tested?
8. What semantic state must survive provider replacement?
```

Only then should implementation begin.

---

# 92. Provider Selection Rule

The provider selection hierarchy is:

```text
Existing mature provider
        ↓
Adapter
        ↓
SCR semantic contract
```

not:

```text
Provider API
        ↓
SCR ontology
```

Where no appropriate provider exists:

```text
Semantic requirement
        ↓
Reference implementation
        ↓
Provider contract
```

The reference implementation remains replaceable.

---

# 93. OpenVDB Selection Rule

OpenVDB should be preferred whenever the requirement is fundamentally about:

* sparse volumetric state;
* level sets;
* signed distance fields;
* fog/density volumes;
* vector fields;
* volumetric morphology;
* voxelization;
* volume sampling;
* field advection;
* sparse spatial computation.

OpenVDB should **not** be used merely because a data structure happens to contain three-dimensional data.

For example:

```text
Surface transform
```

belongs to Spatial.

It should not become an OpenVDB grid merely because the surface has coordinates.

---

# 94. NanoVDB Selection Rule

NanoVDB should be used when:

```text
semantic field
      ↓
GPU-oriented sparse representation
```

is required.

It should not replace OpenVDB as the primary mutable CPU-side field implementation.

Its current documented design emphasizes compact GPU/CPU-friendly sparse access and rendering/collision use cases, with substantially less functionality than full OpenVDB.

---

# 95. Physics Boundary

Physics must not become:

```text
OpenVDB = Physics
```

or:

```text
Chrono = Physics
```

Instead:

```text
SCR Physics
      │
      ├── field physics
      │       ↓
      │    OpenVDB
      │
      └── rigid/multibody physics
              ↓
            Chrono
```

The semantic physics model is above both.

---

# 96. Rendering Boundary

Likewise:

```text
SCR Render
     │
     ├── scene
     ├── material
     ├── texture
     ├── volume
     └── presentation
           │
           ▼
        Provider
           │
      ┌────┴─────┐
      ▼          ▼
    OGRE       OpenGL
```

---

# 97. Effect Boundary

Effects are neither purely rendering nor purely physics.

They are:

```text
Semantic Transformation
```

which may consume and produce:

```text
Spatial state
Geometry
Fields
Physics state
Temporal state
Interaction state
Render state
```

This allows the same effect architecture to later support:

* smoke;
* fire;
* fluid;
* cloth;
* particles;
* spatial distortion;
* visual energy fields;
* interaction ripples;
* environmental simulation.

---

# 98. Expected Result

At completion, Cave should demonstrate something materially different from a conventional Wayland compositor.

A user should be able to:

1. open an application;
2. see its surface;
3. move/transform it;
4. interact with it;
5. trigger a field-based effect;
6. see the effect evolve;
7. observe that the semantic surface remains the same object despite provider-level changes.

The architecture should make the following statement demonstrable rather than theoretical:

> **The desktop is a semantic computational field, and its visible screen is one physical manifestation of that field.**

---

# 99. Future Extension Points

PI-CAVE-001 must leave clean extension points for:

```text
Vulkan
NanoVDB GPU execution
Chrono rigid-body physics
particle fields
fluid simulation
cloth
OpenVDB mesh conversion
glTF
OpenUSD
multi-monitor spatial fields
3D desktop spaces
XR
distributed semantic fields
GPU-resident HyrxMQ
remote semantic surfaces
temporal replay
semantic debugging
formal verification
```

None of these should be implemented prematurely.

---

# 100. PI Deliverables

The PI produces:

### Semantic specifications

```text
Desktop
Workspace
Application
Surface
Buffer
Spatial
Field
Effect
Render
Interaction
```

### Hypergraph

```text
semantic model
provider adapter
conformance suite
```

### Providers

```text
Wayland
Louvre
DMA-BUF
OGRE
OpenGL
OpenVDB
NanoVDB where practical
```

### Runtime

```text
EGS
Reference Executor
provider resolution
semantic graph execution
```

### Verification

```text
semantic tests
provider tests
lifecycle tests
spatial tests
effect tests
E2E test
Lean formalization where practical
```

### Demonstration

```text
real Wayland client
real rendered surface
real spatial transformation
real pointer inverse mapping
real OpenVDB field effect
real provider manifestation lifecycle
```

---

# 101. Final Acceptance Principle

The PI must not be judged by the number of APIs implemented.

It must be judged by whether the following abstraction survives the complete execution path:

```text
                    SEMANTIC WORLD
                         │
                 Semantic Hypergraph
                         │
             ┌───────────┴───────────┐
             │                       │
        Spatial State            Field State
             │                       │
             │                  OpenVDB
             │                       │
             │                  NanoVDB
             │                       │
             └───────────┬───────────┘
                         │
                  EGS / Executor
                         │
             ┌───────────┼───────────┐
             │           │           │
          Louvre       OGRE       Providers
             │           │
          Wayland     OpenGL
             │           │
          DMA-BUF      GPU
             │           │
             └───────────┴───────────┘
                         │
                       Display
```

The physical system may change.

The semantic system must remain coherent.

That is the proof.

---

# 102. Program Increment Completion Statement

PI-CAVE-001 is complete when the Cave implementation demonstrates, with automated evidence, that:

> A real Wayland application can become a semantic SCR object, participate in an executable semantic hypergraph, acquire semantic spatial state, be manifested through real Wayland/GPU/rendering providers, participate in a semantic field transformation implemented through OpenVDB, be rendered to a real display, undergo provider resource replacement and lifecycle transitions, and retain stable semantic identity throughout the process.

This is the **minimum viable proof of the SCR architecture in a physically manifested spatial computer**.

It is deliberately small enough to implement, but architecturally strong enough that success constitutes evidence for the SCR model rather than merely evidence that several existing libraries can be connected together.
