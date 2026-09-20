# v0.0.3 — Isolated Simulation Architecture (Renderer Decoupling)

**Program Increment:** PI-CAVE-003  
**Date:** 2026-09-19  
**Status:** PROPOSED  
**Governing Rule:** AGENTS.md Rule 1 ("Semantics are authoritative") & Rule 6 ("Providers implement contracts; they do not own them")

---

## 1. Problem Statement & Motivation

The Semantic Computational Runtime (SCR) defines an invariant separation of concerns:
```
Semantic Meaning → Contract → Representation → Transformation → Lowering → Provider → Runtime → Execution Substrate
```

Currently, **the rendering provider (OGRE 14.6) leaks directly into the simulation contract layer (`lib/simulation/`)**:
1. `ISimulationScene` interface enforces `Ogre::SceneManager*`, `Ogre::Camera*`, `Ogre::RenderWindow*`, and `Ogre::ManualObject*` in its pure-virtual contracts.
2. `SystemContext` binds `Ogre::SceneManager*`, `Ogre::Camera*`, and `Ogre::RenderWindow*` alongside `SubjectRegistry` and `EventBus`, passing GPU pointers into `updateAsync()` background worker threads.
3. Simulation kinematic/raycast logic (`player_controller.hpp`, `voxel_editing.hpp`, `dynamic_chunk.hpp`) uses `Ogre::Vector3` and `Ogre::Camera` instead of SCR-native `SCR::Spatial::Vector3D` and `SCR::Spatial::Ray3D`.
4. Domain metadata (`spatial_partitions.hpp`, `island_biome_types.hpp`) depends on `Ogre::ColourValue` rather than `SCR::Material::ColorRGB`.
5. Pure simulation loops cannot be executed headless, tested via CI/CD, or targeted to alternative backends (Vulkan, WebGPU, headless MLIR verification runners) without pulling in the entire OGRE shared library dependency tree and windowing server.

---

## 2. Architectural Objectives

1. **Zero-Leak Simulation Layer:** `lib/simulation/` must compile with `-DHEADLESS_SIMULATION` without referencing any OGRE symbols, headers, or linking against `libOgreMain.so`.
2. **Contract Separation:**
   - **Simulation Contract (`SimContext`):** Carries strictly `SubjectRegistry&`, `EventBus&`, `delta_time`, and simulation metadata.
   - **Rendering Contract (`RenderContext` / `RenderViewContext`):** Encapsulates the graphics engine state, viewports, camera matrices, and hardware buffers.
3. **Bridge via `RenderSnapshot`:** The simulation computes domain state and updates `SubjectRegistry`. A pure state extraction phase produces an immutable `RenderSnapshot` consumed by rendering passes.
4. **Abstract Opaque Handle / Strategy for Scene Life-Cycle:** `ISimulationScene` operates on abstract runtime lifecycle events without exposing raw GPU pointers in top-level virtual methods.

---

## 3. Structural Decomposition

### 3.1 Namespace & Layer Division

```
┌────────────────────────────────────────────────────────────────────────┐
│                        DOMAIN CONTRACTS (Pure)                         │
│   lib/simulation/spatial_semantics.hpp   (Vector3D, Point3D, Ray3D)    │
│   lib/simulation/semantic_materials.hpp  (ColorRGB, MaterialRegistry)  │
│   lib/simulation/voxel_types.hpp         (VoxelTypeCode, Voxels)       │
│   lib/simulation/simulation_config.hpp   (Physics, Kinematics consts)  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                       SIMULATION ENGINE (Pure)                         │
│   lib/simulation/simulation_subjects.hpp (Player, Island, Atmosphere)   │
│   lib/simulation/simulation_events.hpp   (EventBus, Domain Events)     │
│   lib/simulation/pure_sim_context.hpp    (PureSimContext, SimLoop)     │
│   lib/simulation/player_controller.hpp   (AABB, DDA, Kinematics)       │
│   lib/simulation/voxel_editing.hpp       (DDA Raymarching, STC)        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ produces RenderSnapshot
┌───────────────────────────────────▼────────────────────────────────────┐
│                    RENDERING ADAPTER (Ogre / Vulkan)                   │
│   providers/render/ogre/ogre_render_bridge.hpp                         │
│   providers/render/ogre/ogre_mesh_mesher.hpp (ManualObject conversions)│
│   lib/simulation/rendering_pipeline.hpp       (IRenderStage, Snapshot) │
│   applications/cave/include/island_hud.hpp    (HUD Rasterizer)         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Work Breakdown & Phased Execution

### Phase 1: Pure Domain Type Migration (Zero Sim-Layer OGRE Math Types)
- **Goal:** Eliminate `Ogre::Vector3`, `Ogre::ColourValue`, `Ogre::Ray`, and `Ogre::Quaternion` from `lib/simulation/`.
- **Modifications:**
  - `spatial_partitions.hpp`: Replace `Ogre::ColourValue` with `SCR::Material::ColorRGB`.
  - `island_biome_types.hpp`: Replace `Ogre::ColourValue` with `SCR::Material::ColorRGB`.
  - `player_controller.hpp`: Replace all `Ogre::Vector3` math with `SCR::Spatial::Vector3D` and `SCR::Spatial::Point3D`. Pass camera rotation angles as primitive yaw/pitch floats instead of manipulating `Ogre::Camera*`.
  - `voxel_editing.hpp`: Replace `Ogre::Ray` with `SCR::Spatial::Ray3D`. Remove head-shake camera node mutation (emit `HeadShakeEvent` onto `EventBus` instead).
  - `dynamic_chunk.hpp`: Replace `Ogre::Vector3` with `SCR::Spatial::Point3D`.
  - Relocate rendering-only helpers (`material_setup.hpp`, `material_library.hpp`, `screenshot.hpp`, `loading_screen_effects.hpp`) into a dedicated rendering adapter directory or guard with clear separation.

### Phase 2: Dual Context Isolation (`SimContext` vs `RenderContext`)
- **Goal:** Split `SystemContext` in `simulation_systems.hpp` so background workers never see GPU pointers.
- **Modifications:**
  ```cpp
  // Pure Simulation Execution Context (Async Safe)
  struct SimContext {
      SubjectRegistry& subjects;
      EventBus& events;
      float dt = 0.0f;
      float simulated_time = 0.0f;
      uint64_t tick_count = 0;
  };

  // Rendering Execution Context (Main Thread Only)
  struct RenderContext {
      void* native_scene_manager = nullptr;
      void* native_camera = nullptr;
      void* native_window = nullptr;
      void* native_viewport = nullptr;
      
      // Strongly typed accessor in rendering provider:
      template <typename T> T* getSceneManager() const { return static_cast<T*>(native_scene_manager); }
      template <typename T> T* getCamera() const { return static_cast<T*>(native_camera); }
      template <typename T> T* getWindow() const { return static_cast<T*>(native_window); }
  };
  ```
- **Subsystem Contract Rewrite:**
  ```cpp
  class ISimulationSubSystem {
  public:
      virtual ~ISimulationSubSystem() = default;
      virtual std::string getName() const = 0;

      // Pure Simulation Phase (Can execute on background thread pool)
      virtual void updateSim(float dt, const UserInputState& input, SimContext& ctx) = 0;

      // Render Synchronization Phase (Executes strictly on main render thread)
      virtual void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) {}
      
      virtual void handleEvent(const ISimulationEvent& event, SimContext& ctx) {}
  };
  ```

### Phase 3: `ISimulationScene` Protocol Decoupling
- **Goal:** Allow scenes to be instantiated, ticked, and inspected in a headless test harness without loading graphics drivers.
- **Modifications in `simulation_framework.hpp`:**
  ```cpp
  class ISimulationScene {
  public:
      virtual ~ISimulationScene() = default;
      virtual SceneMetadata getMetadata() const = 0;

      // Pure Simulation Preparation
      virtual void prepare(LoadingContext& ctx) = 0;

      // Graphics Substrate Hook (opaque or generic interface)
      virtual void attachRenderer(RenderContext& ctx) = 0;
      virtual void detachRenderer(RenderContext& ctx) = 0;

      // Pure Logic Tick
      virtual void update(float dt, const UserInputState& input) = 0;

      // Presentation Overlay Hook
      virtual void renderPresentation(RenderContext& ctx, float screen_alpha) = 0;

      virtual bool handleKeyPress(int key, bool down, bool is_alt_down = false, bool is_ctrl_down = false) {
          return false;
      }
  };
  ```

### Phase 4: Headless Simulation Runner & Verification Target
- **Goal:** Prove the decoupling by creating a headless CLI test suite binary `scr_sim_headless`.
- **Acceptance:**
  - `scr_sim_headless` runs 10,000 steps of `VolcanicIslandScene`, `KarstCaveScene`, `OceanLabScene`, and `AtmosphericLabScene` without X11, Wayland, or OpenGL/Vulkan contexts.
  - Generates zero graphics API calls while verifying complete physics, WFC generation, SPH particle kinematics, and STC reaction steps.

---

## 5. Acceptance Criteria

- [ ] `lib/simulation/` contains zero `#include <Ogre*.h>`.
- [ ] `lib/simulation/` compiles to a standalone static library (`libscr_simulation_core.a`) without linking OGRE.
- [ ] All spatial and color types in `lib/simulation/` use `SCR::Spatial` and `SCR::Material`.
- [ ] `ConcurrentSystemCoordinator` dispatches pure simulation workers (`SimContext`) with zero GPU pointer access.
- [ ] Headless test runner binary `applications/cave/scr_sim_headless` runs all 4 scenes deterministically in CI.
- [ ] Production graphical binary `scr_simulation_hub` retains 100% visual, interactive, and functional parity.
