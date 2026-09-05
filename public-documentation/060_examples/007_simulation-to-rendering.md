# Example: Simulation to Rendering

SCR deliberately separates simulation semantics from rendering.

## Simulation

A simulation can be expressed as:

```text
State(t)
   ↓
Dynamics
   ↓
State(t + Δt)
```

The state and dynamics define the computation.

## Rendering

Rendering can consume an interpretation of that state:

```text
Simulation State
      ↓
Morphology / Spatial Interpretation
      ↓
Render State
      ↓
Rendering
```

Rendering is therefore an observation mechanism rather than the definition of the simulation.

## One possible implementation path

An implementation could eventually resemble:

```text
Rust Semantic Runtime
        ↓
Information Field / Dynamics / Morphology
        ↓
Render State
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

This is an implementation path, not semantic authority.

## Consequences

The same simulation semantics could potentially support:

- headless execution;
- multiple renderers;
- remote visualization;
- recorded observations;
- replay;
- analysis;
- perception pipelines.

## The important boundary

A renderer may choose a particular visual representation.

It must not silently redefine the simulated state merely because that representation is convenient.

This separation also allows rendering to become an active computational participant when observations feed perception, control, or further dynamics.
