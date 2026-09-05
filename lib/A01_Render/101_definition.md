---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-RENDER
name: Render

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-CORE

authority: SCR
domain: semantic-library
------------------------

# SCR Render

## Definition

Render is the semantic computational domain concerned with transforming computationally meaningful state, structure, geometry, fields, materials, illumination, viewpoints, and related information into a perceptual or visual manifestation.

Rendering is therefore a **computational transformation**, not merely an output device operation.

The fundamental relationship is:

```text
Semantic World / State
        │
        ▼
   Render Semantics
        │
        ▼
   Render Representation
        │
        ▼
 Render Execution
        │
        ▼
Perceptual Manifestation
```

Rendering does not define the underlying world.

It defines how declared computational information is transformed into a particular perceptual manifestation.

---

# Semantic Model

A rendering computation can be represented conceptually as:

```text
R = (W, G, M, L, C, V, P, O, T, S)
```

where:

* `W` = semantic world or renderable state
* `G` = geometry and spatial structure
* `M` = material and appearance semantics
* `L` = illumination semantics
* `C` = camera and viewpoint
* `V` = visibility and occlusion
* `P` = perceptual projection
* `O` = output representation
* `T` = temporal state
* `S` = rendering strategy.

Not every rendering operation requires every component.

---

# Rendering Primacy

Rendering MUST remain subordinate to the semantic state being rendered.

```text
Semantic State
      │
      ▼
Rendering Semantics
      │
      ▼
Rendering Provider
      │
      ▼
Backend
      │
      ▼
Hardware
```

A renderer MUST NOT silently redefine:

* object identity
* geometry
* physical state
* topology
* morphology
* field values
* simulation state.

Rendering is an observation or manifestation of semantic state.

It is not automatically the state itself.

---

# Scope

SCR Render encompasses:

* renderable objects
* scenes
* scene graphs
* semantic geometry
* meshes
* materials
* textures
* lighting
* illumination
* cameras
* views
* projections
* visibility
* occlusion
* shadows
* rasterization
* ray tracing
* path tracing
* volume rendering
* particle rendering
* voxel rendering
* animation
* transforms
* frames
* render passes
* render targets
* GPU rendering
* compute rendering
* render pipelines
* rendering resources
* image generation
* temporal rendering
* streaming rendering
* progressive rendering
* level of detail
* culling
* spatial acceleration
* perceptual output
* rendering state
* render commands
* render streams
* render deltas
* provenance.

---

# 1. Renderable Semantic State

A renderable entity is semantic state that can be transformed into a manifestation.

Renderable state MAY originate from:

* geometry
* topology
* morphology
* fields
* particles
* agents
* simulation
* physics
* dynamics
* neural computation
* arbitrary semantic graphs.

Renderable state MUST retain its semantic identity independently of its rendered representation.

---

# 2. Scene

A Scene is a semantic organization of renderable entities and their relationships.

A scene MAY contain:

* objects
* geometry
* lights
* cameras
* materials
* environments
* fields
* volumes
* particles
* effects
* semantic relationships.

A scene is not necessarily a traditional graphics scene graph.

It may be derived from the Semantic Hypergraph.

---

# 3. Scene Graph

A Scene Graph is a representation of relationships between renderable entities.

It MAY encode:

* hierarchy
* containment
* transforms
* visibility
* dependencies
* rendering order
* resources.

A scene graph is a representation.

The underlying semantic relationships remain authoritative.

---

# 4. Object

A renderable Object represents a semantic entity that participates in rendering.

An object MAY possess:

* identity
* geometry
* morphology
* material
* transform
* visibility
* animation
* metadata
* semantic relationships.

Object identity MUST remain independent of rendering implementation.

---

# 5. Geometry

Render geometry describes spatial form used for manifestation.

Geometry MAY be:

* explicit
* implicit
* parametric
* procedural
* volumetric
* particle-based
* mesh-based
* field-derived.

Rendering geometry is a manifestation of `SCR-LIB-GEOMETRY`.

It MUST NOT redefine geometric semantics.

---

# 6. Topology

Rendering MAY depend upon topology.

Examples include:

* surface connectivity
* mesh adjacency
* boundaries
* manifoldness.

Topology MUST remain distinct from rendering representation.

---

# 7. Morphology

Morphology MAY determine renderable form.

For example:

```text
Pattern
   ↓
Morphology
   ↓
Geometry
   ↓
Render
```

Rendering MAY also produce perceptual information from morphology:

```text
Render
   ↓
Perceptual Observation
   ↓
Morphological Analysis
   ↓
Pattern
```

This establishes a potentially bidirectional computational relationship between rendering and morphology.

---

# 8. Fields

Fields MAY participate directly in rendering.

Examples include:

* density
* temperature
* pressure
* colour
* velocity
* opacity
* illumination
* procedural scalar fields.

Fields MAY be rendered directly or transformed into geometry or material properties.

---

# 9. Materials

Material semantics describe how a surface, volume, or other renderable entity interacts with illumination.

Material properties MAY include:

* reflectance
* transmission
* absorption
* emission
* scattering
* roughness
* index of refraction
* colour
* procedural properties.

Material semantics MUST remain independent of a particular shader language.

---

# 10. Illumination

Illumination describes the semantic interaction between light, materials, geometry, and environment.

Illumination MAY include:

* direct lighting
* indirect lighting
* emission
* reflection
* refraction
* scattering
* absorption.

Different rendering strategies MAY approximate the same illumination semantics differently.

---

# 11. Light

A Light is a semantic source or contributor of illumination.

Lights MAY be:

* point
* directional
* area
* environmental
* volumetric
* procedural
* field-derived.

The implementation of a light is provider-specific.

---

# 12. Camera

A Camera defines a semantic observation configuration.

It MAY specify:

* position
* orientation
* projection
* field of view
* clipping
* focus
* depth
* sensor characteristics.

A camera is an observation model, not merely a graphics API object.

---

# 13. View

A View represents a particular rendering observation of semantic state.

Multiple views MAY exist simultaneously.

```text
Semantic World
   ├── View A
   ├── View B
   └── View C
```

Different views MUST NOT imply different underlying semantic state unless explicitly specified.

---

# 14. Projection

Projection transforms spatial or semantic information into a view-dependent representation.

Examples include:

* perspective
* orthographic
* panoramic
* fisheye
* projective
* non-Euclidean or domain-specific projections.

Projection semantics MUST be explicit.

---

# 15. Visibility

Visibility determines which semantic entities or portions of entities contribute to a manifestation.

Visibility MAY depend upon:

* viewpoint
* geometry
* occlusion
* transparency
* distance
* culling rules
* semantic visibility.

Visibility is an observation property, not a deletion of the underlying object.

---

# 16. Occlusion

Occlusion describes the masking of one manifestation by another relative to an observation configuration.

Occlusion MUST NOT imply that the underlying occluded entity ceases to exist.

---

# 17. Shadows

Shadows are rendering phenomena resulting from illumination, geometry, and visibility.

Shadow representation MAY vary by rendering strategy.

---

# 18. Rasterization

Rasterization transforms geometric primitives into discrete image samples.

Conceptually:

```text
Geometry
   ↓
Projection
   ↓
Primitive Coverage
   ↓
Fragments
   ↓
Pixel / Sample Output
```

Rasterization is one rendering strategy.

It is not the definition of rendering.

---

# 19. Ray Tracing

Ray tracing evaluates visibility and interaction by tracing rays through a scene.

It MAY model:

* intersections
* reflection
* transmission
* shadows
* visibility.

Ray tracing is a provider or execution strategy for rendering semantics.

---

# 20. Path Tracing

Path tracing is a stochastic rendering strategy for estimating light transport.

Its stochastic nature MUST be explicit.

Rendering semantics MAY define the desired result while permitting different sampling strategies.

---

# 21. Volume Rendering

Volume rendering transforms volumetric fields into perceptual manifestations.

Examples include:

* density fields
* temperature fields
* pressure fields
* medical volumes
* atmospheric fields.

Volume rendering directly demonstrates the relationship between Fields and Render.

---

# 22. Particle Rendering

Particles MAY represent:

* physical particles
* agents
* field samples
* simulation entities
* procedural elements.

Particle rendering MUST preserve the distinction between the semantic particle and its visual manifestation.

---

# 23. Voxel Rendering

Voxel representations MAY be used to render spatially discrete fields or structures.

Voxelization is a representation or transformation.

It MUST NOT redefine the underlying geometry, topology, or field semantics.

---

# 24. Compute Rendering

Rendering MAY be implemented through general-purpose compute operations.

Examples include:

* compute shaders
* tensor operations
* neural rendering
* procedural generation
* simulation-derived rendering.

Compute rendering remains rendering when its semantic purpose is manifestation.

---

# 25. Neural Rendering

Neural computation MAY participate in rendering.

Examples include:

* learned appearance
* neural scene representations
* image synthesis
* learned reconstruction
* differentiable rendering.

Neural implementation does not change the underlying rendering semantics.

---

# 26. Differentiable Rendering

A rendering operation MAY expose derivatives with respect to:

* geometry
* camera parameters
* materials
* illumination
* scene parameters.

Differentiability MUST be explicit.

---

# 27. Animation

Animation represents temporal change in renderable state.

Animation MAY be driven by:

* dynamics
* simulation
* agents
* procedural rules
* interpolation
* learning
* evolution
* external streams.

Rendering MUST remain an observer/manifestation of the relevant state.

---

# 28. Frame

A Frame represents a particular temporal rendering result or render state.

A frame MAY correspond to:

* simulation time
* event time
* wall-clock time
* animation time.

These time domains MUST remain distinguishable.

---

# 29. Temporal Rendering

Rendering MAY be continuous, discrete, event-driven, or asynchronous.

Temporal rendering MAY support:

* motion blur
* temporal accumulation
* interpolation
* reprojection
* temporal filtering
* frame prediction.

Temporal approximations MUST be explicit.

---

# 30. Render Pass

A Render Pass represents a semantically defined stage of rendering.

A pass MAY:

* consume render state
* transform render state
* produce intermediate state
* produce output
* contribute to a final manifestation.

Render passes MAY be composed.

---

# 31. Render Pipeline

A Render Pipeline is an ordered or partially ordered composition of rendering operations.

```text
Scene
  ↓
Culling
  ↓
Geometry Processing
  ↓
Visibility
  ↓
Shading
  ↓
Composition
  ↓
Output
```

The pipeline is an execution representation.

The semantic rendering operation remains authoritative.

---

# 32. Render Target

A Render Target describes the destination representation of rendering.

It MAY be:

* image
* framebuffer
* texture
* display
* video stream
* encoded media
* remote surface.

The render target is a manifestation boundary.

---

# 33. Image

An image is a representation of rendering output.

An image MUST NOT be assumed to contain all semantic information of the underlying world.

Rendering may therefore be many-to-one:

```text
Semantic State A ─┐
Semantic State B ─┼──► Same Image
Semantic State C ─┘
```

This distinction is essential for perception and inverse rendering.

---

# 34. Perceptual Manifestation

Rendering produces a manifestation relative to:

* observer
* viewpoint
* display
* projection
* environment
* rendering configuration.

The manifestation is therefore context-dependent.

---

# 35. Rendering and Perception

Rendering and Perception form complementary processes:

```text
Semantic World
      │
      ▼
    Render
      │
      ▼
 Observation
      │
      ▼
  Perception
      │
      ▼
 Interpretation
```

The inverse relationship may also be used:

```text
Observation
     ↓
Perception
     ↓
Inference
     ↓
Semantic Representation
```

Rendering does not guarantee that the perceptual result uniquely determines the source state.

---

# 36. Rendering and Simulation

Simulation may provide the state that rendering manifests.

```text
Simulation State
       ↓
     Render
       ↓
     Frame
```

Rendering MUST NOT modify simulation truth merely because it produces a visual representation.

---

# 37. Rendering and Agents

Agents MAY:

* generate renderable state
* observe rendered environments
* receive rendered observations
* control cameras
* interact with visual manifestations.

An agent's perception of a rendered world is not equivalent to the complete semantic world state.

---

# 38. Rendering and Fields

Fields may be rendered directly.

```text
Field
  ↓
Evaluation
  ↓
Projection
  ↓
Manifestation
```

Rendering MAY also produce derived fields such as:

* depth
* normals
* motion
* visibility
* irradiance.

---

# 39. Rendering and Geometry

Geometry provides spatial form.

Rendering determines how that form is manifested under an observation and illumination model.

```text
Geometry
    +
Materials
    +
Lights
    +
Camera
    ↓
Render
```

---

# 40. Rendering and Topology

Topology MAY constrain valid rendering representations.

However, rendering MUST NOT silently alter topological meaning.

A tessellation MAY change representation while preserving the relevant topology.

---

# 41. Rendering and Morphology

Morphology provides semantic structure and form.

Rendering transforms that structure into manifestation.

Morphology MAY therefore be rendered through:

* geometry
* fields
* topology
* particles
* volumes
* procedural representations.

---

# 42. Rendering and Physics

Physics MAY determine:

* object state
* illumination
* material behaviour
* deformation
* fluid state
* particle state.

Rendering observes or manifests these states.

A visual approximation MUST NOT be mistaken for physical truth.

---

# 43. Rendering and Dynamics

Dynamics determine how renderable state evolves.

Rendering samples or manifests that evolution.

```text
Dynamics
   ↓
State(t)
   ↓
Render
   ↓
Frame(t)
```

---

# 44. Rendering and Streams

Rendering MAY consume streams of semantic state.

```text
State Stream
     ↓
Render Stream
     ↓
Frame Stream
```

A render stream MAY be:

* live
* buffered
* distributed
* progressive
* event-driven.

---

# 45. Streaming Rendering

Streaming rendering treats rendering as an ongoing computational process rather than a sequence of isolated final images.

It MAY support:

* incremental updates
* frame deltas
* progressive refinement
* partial rendering
* asynchronous presentation.

---

# 46. Render Deltas

A render delta describes a change in render-relevant state.

Examples include:

* object added
* object removed
* geometry changed
* transform changed
* material changed
* light changed
* camera changed.

Render deltas SHOULD be derived from semantic state changes where possible.

---

# 47. Progressive Rendering

Rendering MAY progressively refine a manifestation.

```text
Initial State
     ↓
Coarse Result
     ↓
Refinement
     ↓
Improved Result
     ↓
Converged Result
```

Progressive rendering MUST expose its convergence or quality semantics where relevant.

---

# 48. Level of Detail

Rendering MAY use different levels of detail.

LOD selection MAY depend upon:

* distance
* screen size
* resource availability
* performance
* perceptual importance.

LOD MUST preserve required semantic properties.

---

# 49. Culling

Rendering MAY omit computation for entities that cannot contribute materially to the current manifestation.

Culling MAY include:

* frustum culling
* occlusion culling
* distance culling
* semantic culling.

Culling is an optimization and MUST preserve the declared output contract.

---

# 50. Spatial Acceleration

Rendering MAY use spatial structures such as:

* BVH
* KD-tree
* octree
* grid
* spatial index.

These structures are execution aids.

They do not replace semantic geometry or topology.

---

# 51. Render Resources

Rendering MAY consume:

* memory
* GPU resources
* textures
* buffers
* acceleration structures
* compute resources
* network bandwidth.

Resource requirements SHOULD be exposed through interfaces and provider contracts.

---

# 52. Render Commands

Render Commands are concrete or semi-concrete instructions describing how a rendering provider should realize a rendering operation.

Commands are representations.

They are not semantic truth.

---

# 53. Render IR

SCR MAY represent rendering through an intermediate representation.

A Render IR MAY contain:

* renderable objects
* resources
* passes
* commands
* dependencies
* synchronization
* target information.

Render IR MUST remain traceable to semantic rendering operations.

---

# 54. GPU Relationship

GPU execution is one possible rendering substrate.

```text
Render Semantics
      ↓
Render IR
      ↓
GPU Lowering
      ↓
GPU Provider
      ↓
Graphics / Compute API
      ↓
GPU
```

GPU execution MUST remain an implementation choice.

---

# 55. External Rendering Providers

SCR MAY use external rendering systems.

For example:

```text
SCR Render
    ↓
Renderer Interface
    ↓
External Renderer
```

External renderer APIs MUST remain provider-level mechanisms.

They MUST NOT redefine SCR rendering semantics.

---

# 56. Renderer Architecture

A renderer SHOULD be separable into:

```text
Semantic Render Model
        │
        ▼
Render State
        │
        ▼
Render Commands
        │
        ▼
Provider
        │
        ▼
Backend
        │
        ▼
Hardware
```

This allows multiple renderer implementations to realize the same semantic model.

---

# 57. Provider Independence

Valid providers MAY include:

* CPU renderer
* GPU renderer
* Vulkan renderer
* OpenGL renderer
* software renderer
* ray tracer
* path tracer
* remote renderer
* neural renderer.

No provider is intrinsically authoritative.

---

# 58. Render Equivalence

Two renderings MAY be equivalent under a declared equivalence relation.

Equivalence MAY concern:

* exact pixels
* perceptual similarity
* physical correctness
* geometric correctness
* temporal behaviour
* statistical convergence.

The equivalence relation MUST be explicit.

---

# 59. Rendering Approximation

Rendering commonly involves approximation.

Examples include:

* sampling
* discretization
* LOD
* shadow approximation
* temporal reconstruction
* denoising
* rasterization
* numerical integration.

Approximation MUST be distinguishable from exact semantic rendering.

---

# 60. Provenance

Rendering SHOULD preserve provenance describing:

* semantic source
* scene state
* camera
* renderer
* provider
* backend
* hardware
* configuration
* time
* approximation
* random state where relevant.

This supports reproducibility and analysis.

---

# Expected Subdomains

```text
render/
├── render-core
├── Animation
├── Camera
├── Compute
├── Frame
├── Geometry
├── GPU
├── IR
├── Light
├── Lighting
├── Material
├── Mesh
├── Object
├── Occlusion
├── Output
├── Particle
├── PathTracing
├── Pipeline
├── Projection
├── Raster
├── RayTracing
├── RenderPass
├── RenderTarget
├── Resource
├── Scene
├── SceneGraph
├── Shadow
├── Stream
├── Texture
├── Transform
├── Vector
├── View
├── Visibility
├── Volume
└── Voxel
```

---

# Invariants

### RENDER-INV-001 — Semantic Primacy

Rendering MUST remain subordinate to the semantic state being rendered.

### RENDER-INV-002 — Identity Preservation

Rendering MUST NOT destroy or redefine semantic identity.

### RENDER-INV-003 — Representation Independence

Rendering semantics MUST remain independent of a particular graphics representation.

### RENDER-INV-004 — Provider Independence

No rendering provider is intrinsically authoritative.

### RENDER-INV-005 — View Dependence

Rendering results MUST be understood relative to their observation configuration.

### RENDER-INV-006 — State Separation

Rendered manifestation MUST remain distinguishable from underlying semantic state.

### RENDER-INV-007 — Geometry Integrity

Rendering MUST preserve declared geometric semantics.

### RENDER-INV-008 — Topology Integrity

Rendering MUST preserve relevant topological guarantees.

### RENDER-INV-009 — Morphological Integrity

Rendering MUST preserve relevant morphological semantics.

### RENDER-INV-010 — Temporal Integrity

Rendering MUST preserve declared temporal semantics.

### RENDER-INV-011 — Approximation Transparency

Rendering approximations MUST be explicit.

### RENDER-INV-012 — Determinism Transparency

Rendering nondeterminism or stochasticity MUST be explicit.

### RENDER-INV-013 — Resource Transparency

Material rendering resource requirements MUST be identifiable.

### RENDER-INV-014 — Provenance

Material rendering results SHOULD retain provenance.

### RENDER-INV-015 — Output Integrity

A rendered output MUST satisfy its declared output contract.

### RENDER-INV-016 — Stream Integrity

Streaming rendering MUST preserve declared stream semantics.

### RENDER-INV-017 — Provider Substitutability

Compatible rendering providers SHOULD be substitutable under the declared equivalence relation.

### RENDER-INV-018 — Perceptual Distinction

A rendered manifestation MUST NOT be assumed to contain all information present in the underlying semantic state.

---

# Architectural Rules

1. Render MUST compose with Core.
2. Render MUST compose with Data.
3. Render MUST compose with Fields.
4. Render MUST compose with Geometry.
5. Render MUST compose with Topology.
6. Render MUST compose with Morphology.
7. Render MUST compose with Physics.
8. Render MUST compose with Dynamics.
9. Render MUST compose with Simulation.
10. Render MUST compose with Agents.
11. Render MUST compose with Neural.
12. Render MUST compose with Perception.
13. Render MUST compose with Interfaces.
14. Render MUST compose with Providers.
15. Render MUST compose with Lowering.
16. Render MUST compose with Stream.
17. Render MUST preserve semantic identity.
18. Render MUST remain provider-independent.
19. Render MUST support multiple rendering strategies.
20. Render MUST distinguish semantic state from manifestation.
21. Render MUST support view-dependent computation.
22. Render MUST support temporal rendering.
23. Render MUST support streaming rendering.
24. Render MUST support incremental rendering.
25. Render SHOULD support progressive refinement.
26. Render SHOULD support differentiable rendering.
27. Render SHOULD support distributed rendering.
28. Render SHOULD support hardware-aware rendering.
29. Render SHOULD support multiple representations.
30. Rendering optimizations MUST preserve declared output semantics.
31. Rendering approximations MUST be explicit.
32. Render providers MUST NOT become semantic authorities.
33. Render commands MUST remain representations rather than semantic truth.
34. Render IR MUST remain traceable to semantic rendering operations.
35. GPU execution MUST remain an implementation choice.
36. External rendering systems MUST remain providers.

---

# Completeness Criteria

An implementation of SCR Render is semantically complete only when it can represent:

* renderable state
* scenes
* scene graphs
* objects
* geometry
* topology
* morphology
* fields
* materials
* illumination
* lights
* cameras
* views
* projections
* visibility
* occlusion
* shadows
* rasterization
* ray tracing
* path tracing
* volume rendering
* particle rendering
* voxel rendering
* compute rendering
* neural rendering
* differentiable rendering
* animation
* frames
* temporal rendering
* render passes
* render pipelines
* render targets
* images
* perceptual manifestations
* streaming
* render deltas
* progressive rendering
* level of detail
* culling
* spatial acceleration
* render resources
* render commands
* Render IR
* GPU execution
* external rendering providers
* provider independence
* render equivalence
* approximation
* provenance.

---

# Testing Requirements

### Specification Tests

Validate rendering semantics against this definition.

### Geometry Tests

Verify geometric correctness of rendered representations.

### Topology Tests

Verify preservation of relevant topological properties.

### Morphology Tests

Verify that rendered manifestations preserve declared morphological properties.

### Material Tests

Validate material semantics.

### Lighting Tests

Validate illumination behaviour.

### Camera Tests

Validate projection and view semantics.

### Visibility Tests

Validate visibility and occlusion.

### Rasterization Tests

Validate raster output under declared conditions.

### Ray-Tracing Tests

Validate ray intersection and visibility semantics.

### Path-Tracing Tests

Validate stochastic convergence and declared approximation.

### Volume Tests

Validate field-to-image transformations.

### Particle Tests

Validate particle manifestations.

### Temporal Tests

Validate frame and time semantics.

### Stream Tests

Validate streaming and incremental rendering.

### Equivalence Tests

Compare multiple providers under declared equivalence relations.

### Approximation Tests

Validate declared rendering approximations.

### Determinism Tests

Validate deterministic rendering where required.

### Performance Tests

Measure rendering performance independently from semantic correctness.

### Provenance Tests

Verify render provenance.

### Provider Tests

Validate renderer providers against SCR Render interfaces.

### Lowering Tests

Validate semantic preservation through Render → Render IR → backend lowering.

---

# Open Semantic Questions

1. What is the minimal universal semantic model for rendering?
2. How should perceptual equivalence be formally defined?
3. How should physical correctness differ from perceptual correctness?
4. How should rendering uncertainty be represented?
5. How should differentiable rendering expose gradients?
6. How should temporal rendering semantics be represented?
7. How should progressive rendering expose convergence?
8. How should render deltas relate to semantic state deltas?
9. How should rendering integrate with the Semantic Hypergraph?
10. How should semantic scenes differ from implementation-specific scene graphs?
11. How should procedural geometry be represented in Render?
12. How should neural rendering interact with Neural and Perception?
13. How should distributed rendering expose consistency?
14. How should renderer providers declare perceptual guarantees?
15. How should multiple simultaneous views share computation?
16. How should rendering integrate with adaptive provider selection?
17. How should render-resource constraints influence lowering?
18. How should perceptual quality become a semantic contract?

These questions MUST NOT be resolved implicitly by implementation.

---

# Definition History

## 0.1.0

Initial normative semantic definition.

Establishes Render as the semantic computational domain responsible for transforming computational state and structure into perceptual manifestations while remaining independent of any particular renderer, graphics API, representation, or hardware substrate.

---

# Definition Authority

This document is the normative semantic authority for `SCR-LIB-RENDER`.

Renderers, graphics APIs, scene graph implementations, GPU backends, ray tracers, rasterizers, path tracers, neural rendering systems, and other rendering providers MUST conform to the semantic contracts established here.

---

# Definition Principle

> **Rendering is computation that makes semantic state perceptually manifest. The image, frame, mesh, buffer, shader, renderer, graphics API, and GPU are representations or execution mechanisms; none of them is the semantic reality being rendered.**
> :::writing_end::
