# Semantic Computational Runtime (SCR) — Cave & Spatial Simulation Hub

## Overview

The **Semantic Computational Runtime (SCR)** is an MLIR-based computational architecture designed to execute heterogeneous, domain-specific semantic models across diverse execution substrates (CPU, GPU, accelerators, distributed nodes).

The **Cave & Spatial Simulation Hub** (`applications/cave`) is the reference simulation application for SCR. It serves as a unified multi-domain environment synthesizing:
- **Volumetric OpenVDB Karst Geology & Terrain:** High-resolution volumetric SDF isosurface polygonization and dynamic chunk streaming.
- **Atmospheric Optics & Celestial Mechanics:** Diurnal solar/lunar scattering cycles, multi-deck cloud synthesis, and distance fog.
- **Hydrology & Fluid Mechanics:** Gerstner wave ocean modeling, SPH particle water dynamics, and Bingham plastic volcanic lava rheology.
- **Autonomous Ecology:** Flocking boid fauna, dynamic firefly illumination, and Hierarchical Wave Function Collapse (WFC) biome placement.
- **In-World Compositor Integration:** Embedded Wayland client rendering directly into 3D spatial surfaces.

---

## Architectural Principle: Invariant Separation of Concerns

A fundamental governing rule of SCR is:
> **Never allow implementation convenience to silently redefine computational semantics.**  
> *(AGENTS.md Rule 1: "Semantics are authoritative" & Rule 6: "Providers implement contracts; they do not own them")*

To guarantee portability, determinism, and backend flexibility, the application strictly separates **Computational Simulation** from **Rendering & Presentation**.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       COMPUTATIONAL SIMULATION                          │
│                                                                         │
│  - Spatial Semantics (Point3D, Vector3D, Ray3D, LatticeCoord3D)         │
│  - Semantic Materials & STC Reactions                                  │
│  - SubjectRegistry (Player, Island, Atmosphere, Hydrology, Ecology)     │
│  - Deterministic Fixed-Timestep Update Loop                             │
│  - Bullet Physics & SPH Kinematics                                      │
│                                                                         │
│  * 100% headless-capable, GPU-independent, window-agnostic              │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     │ produces immutable
                                     │ RenderSnapshot
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       PRESENTATION & RENDERING                          │
│                                                                         │
│  - Rendering Substrate Adapter (OGRE 14.6 / Vulkan / Headless)          │
│  - GPU Hardware Buffer Streaming (ManualObject Mesh Generation)         │
│  - GLSL Cel-Shading & Post-Processing Pipelines                         │
│  - Tactical Vector HUD Overlay & Dear ImGui Scene Selector              │
│  - Native Window & Display Server Integration (X11 / Wayland)           │
│                                                                         │
│  * Downstream consumer of simulation state; cannot mutate semantics     │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Core Domains & Layer Roles

### 1. The Simulation Layer (`lib/simulation/`)
- **Semantic Domain Contracts:** Canonical definitions of space (`spatial_semantics.hpp`), voxel types (`voxel_types.hpp`), and physical/material properties (`semantic_materials.hpp`).
- **Domain Subjects:** State holders (`PlayerSubject`, `IslandSubject`, `AtmosphereSubject`, `HydrologySubject`, `VolcanoSubject`, `EcologySubject`) decoupled from any graphical library.
- **System Coordinator:** `ConcurrentSystemCoordinator` dispatches asynchronous physics, kinematic, and procedural steps across background worker threads.
- **Headless Execution:** Designed to step deterministically in pure CPU test suites, CI/CD validation pipelines, and remote computational nodes without requiring graphics hardware or windowing systems.

### 2. The Rendering Layer (`providers/render/` & Presentation Adapters)
- **Subordinate to Contracts:** The graphics engine (currently Ogre3D 14.6) is an execution substrate provider. It does not dictate the coordinates, physics, or rules of the world.
- **Mesh Synthesis & Streaming:** Translates domain state (such as OpenVDB grids, boid vectors, and ocean wave equations) into GPU vertex buffers via `IRenderStage` pipelines.
- **Render Snapshot Bridge:** The rendering loop reads an immutable `RenderSnapshot` extracted from the simulation state, ensuring thread-safe decoupling between simulation ticks and presentation frame rates.

---

## Simulation Scenes

The simulation hub registers four modular simulation environments:

1. **Volcanic Island (`VolcanicIslandScene`):** Volumetric caldera peak, lava flows, Gerstner ocean water, vegetation ecosystems, and boid fauna.
2. **Karst Cave (`KarstCaveScene`):** Subterranean limestone cave network featuring DDA mining/placing, spatial transitions, and underground water reservoirs.
3. **Ocean Lab (`OceanLabScene`):** Dedicated hydrodynamics laboratory evaluating sea states, foam synthesis, buoyancy mechanics, and optical water absorption.
4. **Atmospheric Lab (`AtmosphericLabScene`):** Meteorological proving ground featuring multi-layer cloud decks, diurnal time-of-day cycling, and atmospheric light extinction.

---

## Build and Execution

Launch the unified simulation hub:
```bash
./applications/cave/run_simulation_hub.sh
```

### Controls & Shortcuts
- **`Tab`**: Toggle ImGui Simulation Scene Selector menu.
- **`Ctrl + 1..4`**: Quick-switch directly between simulation scenes.
- **`Ctrl + R`**: Reload current simulation scene.
- **`W / A / S / D / Space / Shift`**: Locomotion, jumping, and sprinting.
- **`Left Click`**: Primary action (mine voxel / interact).
- **`Right Click`**: Secondary action (place voxel / toggle display).
- **`F12` / `P`**: Capture timestamped high-resolution screenshot.
- **`Esc`**: Exit simulation runtime.
