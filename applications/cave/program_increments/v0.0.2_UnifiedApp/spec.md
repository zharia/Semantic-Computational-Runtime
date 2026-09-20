# v0.0.2 — Unified Simulation Framework

**Date:** 2026-09-19
**Status:** PLANNED
**Scope:** Consolidate all cave/island applications into a single framework with scene selection, shared subsystems, and full feature parity.

---

## 1. Current State

### 1.1 Application Inventory

| App | File | Lines | Uses Framework | IPC | Loading Screen | Scenes |
|-----|------|-------|----------------|-----|----------------|--------|
| SCR Simulation Hub | `simulation_main.cpp` | 908 | YES — ISimulationScene, SimulationRegistry, ConcurrentSystemCoordinator | YES (Unix socket) | YES (OrganicLoadingScreen) | 4 scenes via registry |
| Voxel Cave Explorer | `voxel_cave_app.cpp` | ~600 | NO — monolithic | NO | NO | N/A |
| Volcanic Island Explorer | `volcanic_island_app.cpp` | 1600 | NO — monolithic | NO | NO (has ImGui infra) | N/A |

### 1.2 Scene Implementations

| Scene | File | Uses Coordinator | Systems Registered |
|-------|------|------------------|-------------------|
| VolcanicIslandScene | `scene_volcanic_island.hpp` | YES | GeologySystem, HydrologySystem, AtmosphereSystem, EcologySystem, InteractionSystem, PhysicsDynamicsSystem |
| KarstCaveScene | `scene_karst_cave.hpp` | NO (manual FPS) | NONE |
| OceanLabScene | `scene_ocean_lab.hpp` | NO (manual FPS) | NONE |
| AtmosphericLabScene | `scene_atmospheric_lab.hpp` | NO (manual FPS) | NONE |

### 1.3 Gap Summary

| Category | VolcanicIslandScene Gaps | KarstCaveScene Gaps | OceanLabScene Gaps | AtmosphericLabScene Gaps |
|----------|------------------------|--------------------|--------------------|------------------------|
| Physics & Controller | 10 missing | 18 missing | 18 missing | 18 missing |
| Voxel Editing | 5 missing | 12 missing | 12 missing | 12 missing |
| Materials & Rendering | 3 missing | 10 missing | 10 missing | 10 missing |
| HUD | 5 missing | 6 missing | 6 missing | 6 missing |
| VDB Chunk Streaming | 2 missing | N/A | N/A | N/A |
| ImGui | 2 missing | 2 missing | 2 missing | 2 missing |
| Logging | 4 missing | 4 missing | 4 missing | 4 missing |
| **Total** | **31 missing** | **52 missing** | **52 missing** | **52 missing** |

---

## 2. Target Architecture

### 2.1 Directory Structure

```
lib/simulation/                          ← NEW: shared simulation library
├── simulation_framework.hpp             ← ISimulationScene, SimulationRegistry, UserInputState, LoadingContext
├── simulation_systems.hpp               ← ISimulationSystem, ConcurrentSystemCoordinator, all systems
├── simulation_config.hpp                ← NEW: centralized constants
├── sim_ipc_server.hpp                   ← Unix socket IPC
├── simulation_events.hpp                ← EventBus, ISimulationEvent
├── rendering_pipeline.hpp               ← RenderSnapshot, ModularRenderPipeline
├── loading_screen_effects.hpp           ← OrganicLoadingScreen
├── island_biome_types.hpp               ← shared biome enums
├── spatial_partitions.hpp               ← spatial query types
├── voxel_types.hpp                      ← NEW: voxel constants, MaterialRegistry
├── material_library.hpp                 ← NEW: shared OGRE material creation
├── logging.hpp                          ← NEW: persistent file logging
└── screenshot.hpp                       ← NEW: screenshot utility

applications/cave/
├── src/
│   └── simulation_main.cpp              ← Single entry point (all apps converge here)
├── include/
│   ├── scene_volcanic_island.hpp        ← ISimulationScene impl
│   ├── scene_karst_cave.hpp             ← ISimulationScene impl
│   ├── scene_ocean_lab.hpp              ← ISimulationScene impl
│   ├── scene_atmospheric_lab.hpp        ← ISimulationScene impl
│   └── (domain-specific headers only)
├── run_simulation_hub.sh                ← Single launcher script
```

**Deleted:**
- `voxel_cave_app.cpp` — replaced by KarstCaveScene
- `volcanic_island_app.cpp` — replaced by VolcanicIslandScene
- `run_volcanic_island.sh` — no longer needed
- `run_cave_explorer.sh` — no longer needed

### 2.2 Subsystem Architecture

```
ConcurrentSystemCoordinator
├── GeologySystem
│   ├── OpenVdbTerrainSubSystem          ← EXISTING
│   ├── VolcanoGeothermalSubSystem       ← EXISTING
│   └── DynamicChunkSubSystem            ← NEW (from volcanic_island_app chunk streaming)
├── HydrologySystem
│   └── GerstnerOceanSubSystem           ← EXISTING (upgrade: L key cycling)
├── AtmosphereSystem
│   ├── VolumetricAtmosphereSubSystem    ← EXISTING (upgrade: C/K keys, [/] time)
│   ├── HorizonParallaxSubSystem         ← EXISTING
│   ├── DynamicWeatherSubSystem          ← EXISTING
│   └── FogSubSystem                     ← NEW (from both monoliths)
├── EcologySystem
│   ├── ProceduralFloraSubSystem         ← EXISTING
│   └── BoidFaunaSubSystem               ← EXISTING (upgrade: continuous night pulse)
├── InteractionSystem
│   ├── PlayerControllerSubSystem        ← NEW (from IslandPlayer + FPSController)
│   ├── VoxelEditingSubSystem            ← NEW (from both monoliths)
│   ├── HudRendererSubSystem             ← NEW (from both monoliths)
│   ├── WaylandCompositorSubSystem       ← EXISTING (upgrade: mouse button forwarding)
│   └── NauticalVoyageSubSystem          ← EXISTING
├── PhysicsDynamicsSystem
│   └── BulletPhysicsSubSystem           ← EXISTING
├── RenderingSystem                      ← NEW composite
│   ├── MaterialSetupSubSystem           ← NEW (from both monoliths)
│   └── CelShadingSubSystem              ← NEW (from volcanic_island_app)
└── (optional) UtilitySystem
    └── AutoScreenshotSubSystem          ← NEW (from volcanic_island_app)
```

---

## 3. Phase 1: Extract Shared Library

### 3.1 Move Framework Headers

Move 8 files from `applications/cave/include/` to `lib/simulation/`:

| # | File | Contents |
|---|------|----------|
| 1 | `simulation_framework.hpp` | ISimulationScene, SimulationRegistry, UserInputState, LoadingContext, SceneMetadata |
| 2 | `simulation_systems.hpp` | ISimulationSystem, ISimulationSubSystem, ConcurrentSystemCoordinator, SystemContext, all composite systems |
| 3 | `sim_ipc_server.hpp` | SimIPCServer (AF_UNIX socket) |
| 4 | `simulation_events.hpp` | EventBus, ISimulationEvent, typed events |
| 5 | `rendering_pipeline.hpp` | RenderSnapshot, RenderViewContext, IRenderStage, ModularRenderPipeline, HeadlessRenderPipeline, RenderDataExtractor |
| 6 | `loading_screen_effects.hpp` | OrganicLoadingScreen |
| 7 | `island_biome_types.hpp` | Biome enums, terrain types |
| 8 | `spatial_partitions.hpp` | Spatial query types |

### 3.2 Create New Shared Types

| # | File | Contents |
|---|------|----------|
| 9 | `simulation_config.hpp` | `namespace SCR::Config` — all simulation constants (see §4.1) |
| 10 | `voxel_types.hpp` | `namespace SCR::Voxel` — MAT_AIR..MAT_WATER, MaterialProperties, MaterialRegistry |
| 11 | `material_library.hpp` | `namespace SCR::MaterialLib` — `createAll(SceneManager*)` creates all shared OGRE materials |
| 12 | `logging.hpp` | `namespace SCR::SimLog` — `init()`, `line()`, `fatal()`, session headers |
| 13 | `screenshot.hpp` | `namespace SCR::SimScreenshot` — `take()`, `autoCycle()` |

### 3.3 Update Includes

Update all `#include` paths across:
- 4 scene `.hpp` files
- `simulation_main.cpp`
- `run_simulation_hub.sh` (add `-I lib/simulation`)

### 3.4 Verification

- Clean build with no linker errors
- Binary launches and shows scene selection menu (after Phase 3)

---

## 4. Shared Types Specification

### 4.1 `simulation_config.hpp`

```cpp
namespace SCR::Config {
    // Physics
    constexpr float GRAVITY = -10.0f;
    constexpr float GRAVITY_APEX_MULT = 0.65f;      // Reduced gravity at jump apex
    constexpr float GRAVITY_ASCENT_MULT = 0.90f;    // Reduced gravity during ascent
    constexpr float GRAVITY_DESCENT_MULT = 1.55f;   // Increased gravity during descent
    constexpr float GRAVITY_KINETIC_MULT = 1.25f;   // Fast-fall multiplier
    constexpr float TERMINAL_VELOCITY = -28.0f;

    // Jump
    constexpr float JUMP_VELOCITY = 7.5f;
    constexpr float DOUBLE_JUMP_VELOCITY = 6.5f;
    constexpr float COYOTE_TIME = 0.18f;             // Grace period after leaving ground
    constexpr float JUMP_BUFFER = 0.15f;             // Pre-buffer for early press

    // Movement
    constexpr float WALK_SPEED = 6.0f;
    constexpr float SPRINT_SPEED = 8.5f;
    constexpr float WATER_SPEED_MULT = 0.65f;
    constexpr float GROUND_ACCEL = 16.0f;
    constexpr float GROUND_FRICTION = 8.5f;
    constexpr float AIR_ACCEL = 8.0f;
    constexpr float AIR_SPEED_CAP = 1.5f;

    // Collision
    constexpr float STEP_HEIGHT = 0.35f;
    constexpr float EYE_HEIGHT = 1.5f;
    constexpr float PLAYER_HEIGHT = 1.8f;
    constexpr float PLAYER_RADIUS = 0.3f;

    // Camera
    constexpr float MOUSE_SENSITIVITY = 0.0028f;
    constexpr float PITCH_LIMIT = 1.48f;             // Radians
    constexpr float NEAR_CLIP = 0.05f;
    constexpr float FAR_CLIP_ISLAND = 12000.0f;
    constexpr float FAR_CLIP_CAVE = 300.0f;

    // Rendering
    constexpr float HEAD_BOB_AMPLITUDE = 0.03f;
    constexpr float HEAD_BOB_FREQUENCY = 8.0f;
    constexpr float CAMERA_SHAKE_DECAY = 3.0f;
    constexpr float BREATHING_AMPLITUDE = 0.003f;
    constexpr float BREATHING_FREQUENCY = 0.8f;

    // HUD
    constexpr float HUD_UPDATE_RATE = 20.0f;         // Hz
    constexpr float HUD_DISSOLVE_SPEED = 14.0f;

    // Timing
    constexpr float PHYSICS_TICK_RATE = 60.0f;
    constexpr float MAX_FRAME_DT = 0.05f;            // Cap at 50ms
}
```

### 4.2 `voxel_types.hpp`

```cpp
namespace SCR::Voxel {
    enum MaterialCode : uint8_t {
        MAT_AIR = 0,
        MAT_BEDROCK = 1,
        MAT_GRANITE = 2,
        MAT_LIMESTONE = 3,
        MAT_BASALT = 4,
        MAT_OBSIDIAN = 5,
        MAT_GOLD = 6,
        MAT_IRON = 7,
        MAT_QUARTZ = 8,
        MAT_WATER = 9,
        MAT_SAND = 10,
        MAT_FOLIAGE = 11,
        MAT_BAMBOO = 12,
        MAT_SULFUR = 13,
        MAT_ASH = 14,
        MAT_LAVA = 15,
    };

    struct MaterialProperties {
        const char* name;
        float density;          // kg/m3
        float hardness;         // Mohs 0-10
        float youngs_modulus;   // GPa
        uint32_t albedo_color;  // IM_COL32 format
    };

    class MaterialRegistry {
        std::unordered_map<MaterialCode, MaterialProperties> registry_;
    public:
        MaterialRegistry();
        const MaterialProperties& get(MaterialCode code) const;
        bool isSolid(MaterialCode code) const;
        bool isLiquid(MaterialCode code) const;
    };
}
```

### 4.3 `material_library.hpp`

```cpp
namespace SCR::MaterialLib {
    struct SharedMaterials {
        Ogre::MaterialPtr voxel_vertex_color;    // Gouraud, specular 0.2, shininess 16
        Ogre::MaterialPtr smooth_cave;            // Phong, specular 0.35, shininess 32
        Ogre::MaterialPtr sky_dome;
        Ogre::MaterialPtr ocean;
        Ogre::MaterialPtr lava;
        Ogre::MaterialPtr smoke;
        Ogre::MaterialPtr boid;
        Ogre::MaterialPtr vegetation;
        Ogre::MaterialPtr hud_vector;
        // Cel shading
        bool cel_shading_enabled;
    };

    SharedMaterials createAll(Ogre::SceneManager* scnMgr, bool cel_shading = false);
    void setupFog(Ogre::SceneManager* scnMgr, Ogre::ColourValue color, float density);
    void setupCelShading(Ogre::SceneManager* scnMgr);
}
```

### 4.4 `logging.hpp`

```cpp
namespace SCR::SimLog {
    void init(const std::string& log_path);
    void line(const std::string& msg);
    void fatal(const std::string& msg);
    void sessionHeader();  // Writes timestamp, PID, session start
    void shutdown();
}
```

### 4.5 `screenshot.hpp`

```cpp
namespace SCR::SimScreenshot {
    void take(Ogre::RenderWindow* win, const std::string& path);

    struct ScreenshotJob {
        int frame_delay;           // Frames to wait before capture
        float time_of_day;         // Set time before capture
        int biome_partition;       // Warp to partition before capture (-1 = no warp)
        std::string filename;
    };

    // Call each frame; handles timing and sequencing
    void autoCycleUpdate(float global_time, int frame_count,
                         const std::vector<ScreenshotJob>& jobs,
                         Ogre::RenderWindow* win);
}
```

---

## 5. Phase 2: New Subsystems

### 5.1 `PlayerControllerSubSystem` (ISimulationSubSystem)

**Source:** `volcanic_island_app.cpp` L69-567 (IslandPlayer), `voxel_cave_app.cpp` FPSController

**Responsibility:** All player physics, movement, camera control, collision detection.

**Data owned:**
```cpp
struct PlayerSubject {
    Spatial::Point3D position;
    Spatial::Vector3D velocity;
    Spatial::Vector3D acceleration;
    float yaw, pitch, roll;
    float eye_height = 1.5f;
    float smooth_eye_y = 0.0f;
    bool on_ground = false;
    bool in_water = false;
    int jump_count = 0;
    float coyote_timer = 0.0f;
    float jump_buffer_timer = 0.0f;
    float slide_timer = 0.0f;
    bool is_sliding = false;
    float landing_impact_dip = 0.0f;
    float head_shake_intensity = 0.0f;
    float head_shake_phase = 0.0f;
    float breathing_phase = 0.0f;
    float bob_phase = 0.0f;
    float target_roll = 0.0f;
    float prev_jump_input = false;
    bool can_double_jump = true;
    // Spring state for eye height
    float spring_displacement = 0.0f;
    float spring_velocity = 0.0f;
};
```

**Methods:**
- `initialize(SystemContext&)` — set initial position from terrain height
- `updateAsync(float dt, const UserInputState& input, SystemContext& ctx)` — physics tick:
  - Gravity with variable multipliers (apex/ascent/descent/kinetic)
  - Jump: buffer check → coyote check → velocity set → double jump tracking
  - Horizontal: ground accel/friction model OR air strafing (Source-style)
  - Per-axis AABB collision with step-height auto-climb
  - Depenetration recovery (iterative push-up)
  - Water buoyancy (depth-based drag, reduced gravity)
  - Slide state machine (sprint+crouch, timer, downhill slope gravity)
  - Eye-in-mesh guard (iterative eye_height reduction)
  - DDA voxel raycast from eye (for interaction targeting)
  - Landing spring oscillator (2nd-order critically damped)
- `renderSync(SystemContext& ctx, float dt)` — camera sync:
  - Compute eye position (player_pos + smooth_eye_y + head bob + breathing)
  - Apply roll tilt (lateral strafe + mouse turn)
  - Apply camera shake (5-frequency damped oscillation)
  - Set camera position + orientation from yaw/pitch/roll quaternions

**Dependencies:** `VoxelEditingSubSystem` (for voxel queries), `OpenVdbTerrainSubSystem` (for ground height)

### 5.2 `VoxelEditingSubSystem` (ISimulationSubSystem)

**Source:** `voxel_cave_app.cpp` mining/place logic, `volcanic_island_app.cpp` editing

**Responsibility:** Voxel modification, hotbar, STC reactions, mesh rebuild, world regeneration.

**Data owned:**
```cpp
struct VoxelEditState {
    int selected_hotbar_slot = 1;
    bool mesh_dirty = false;
    enum MeshMode { MESH_SMOOTH_OPENVDB, MESH_VOXEL_BLOCKS } mesh_mode = MESH_SMOOTH_OPENVDB;
};
```

**Methods:**
- `initialize(SystemContext&)` — set up VoxelCave/VoxelIsland reference
- `updateAsync(float dt, const UserInputState& input, SystemContext& ctx)`:
  - Process `action_primary` (LMB mine): DDA raycast → head-shake trigger → setVoxel(AIR) → mark mesh_dirty
  - Process `action_secondary` (RMB place): DDA raycast → inBounds check → setVoxel(hotbar_material) → mark mesh_dirty
  - Process hotbar selection (1-9 keys)
  - Process mesh mode toggle (M key)
  - Process STC reactions (T key)
  - Process regeneration (R key): new seed → regenerate → re-solve WFC → mark all dirty
- `renderSync(SystemContext& ctx, float dt)`:
  - If mesh_dirty: rebuild cave/island mesh (OpenVDB smooth OR voxel blocks)
  - Update ManualObject vertex buffers

**Dependencies:** `PlayerControllerSubSystem` (for raycast origin/direction), `OpenVdbTerrainSubSystem` (for terrain data), `ProceduralFloraSubSystem` (for WFC re-solve on regen)

### 5.3 `MaterialSetupSubSystem` (ISimulationSubSystem)

**Source:** `voxel_cave_app.cpp` setupMaterials, `volcanic_island_app.cpp` setupMaterials

**Responsibility:** Create all OGRE materials needed by the scene.

**Methods:**
- `initialize(SystemContext&)`:
  - Call `MaterialLibrary::createAll(sceneMgr, cel_shading_enabled)`
  - Create scene-specific materials (e.g., cave headlamp spotlight material)
  - Set up fog via `MaterialLibrary::setupFog()`
  - Set viewport background color

### 5.4 `FogSubSystem` (ISimulationSubSystem)

**Source:** `voxel_cave_app.cpp` fog, `volcanic_island_app.cpp` fog

**Responsibility:** Dynamic fog management, day/night interpolation, underwater mode.

**Methods:**
- `updateAsync(float dt, ...)` — compute target fog color/density from time-of-day + weather
- `renderSync(SystemContext& ctx, float dt)` — apply fog to SceneManager

### 5.5 `DynamicChunkSubSystem` (ISimulationSubSystem)

**Source:** `volcanic_island_app.cpp` L1530-1532

**Responsibility:** Per-frame VDB chunk streaming based on player position.

**Methods:**
- `updateAsync(float dt, ...)` — update chunk priorities from player position
- `renderSync(SystemContext& ctx, float dt)` — upload completed chunks to GPU

### 5.6 `HudRendererSubSystem` (ISimulationSubSystem)

**Source:** `volcanic_island_app.cpp` HUD logic, `voxel_cave_app.cpp` console HUD

**Responsibility:** All HUD rendering: vector HUD, FPS display, material inspector, minimap, compass, hotbar.

**Methods:**
- `updateAsync(float dt, ...)` — throttle to 20Hz, gather telemetry data
- `renderSync(SystemContext& ctx, float dt)`:
  - Calculate real FPS (averaged 0.25s window)
  - Update HUD data: player position, footing material, crosshair hit info, mesh mode, hotbar
  - Render via `IslandHUD::renderVectorHUD()` or `IslandHUD::renderCaveHUD()`
  - Apply HUD alpha dissolve (ALT hold, spring fade)
  - Update ManualObject vertex buffers

### 5.7 `CelShadingSubSystem` (ISimulationSubSystem)

**Source:** `volcanic_island_app.cpp` L894

**Responsibility:** Initialize and manage cel shading post-processing.

**Methods:**
- `initialize(SystemContext&)` — call `CelShadingSystem::initializeCelShading(false)`

### 5.8 `AutoScreenshotSubSystem` (ISimulationSubSystem)

**Source:** `volcanic_island_app.cpp` L1535-1557

**Responsibility:** Automated biome-cycling screenshot capture for documentation.

**Methods:**
- `initialize(SystemContext&)` — set up screenshot job queue
- `updateAsync(float dt, ...)` — check frame count, trigger captures with biome warps and time-of-day changes

---

## 6. Phase 2: Existing System Upgrades

### 6.1 `PlayerKinematicsSubSystem` → Replace with `PlayerControllerSubSystem`

The existing `PlayerKinematicsSubSystem` is a simplified version. Replace it entirely with the new `PlayerControllerSubSystem` (§5.1) which contains the full physics from both monoliths.

### 6.2 `OpenVdbTerrainSubSystem` Upgrade

Add:
- Dynamic chunk streaming (call `chunk_manager->update(playerPos)` each frame)
- Mesh mode toggle: `MESH_SMOOTH_OPENVDB` ↔ `MESH_VOXEL_BLOCKS`
- Mesh rebuild on voxel edit (destroy old ManualObject, recreate)
- `buildDiscreteIslandMesh()` for voxel block mode

### 6.3 `VolumetricAtmosphereSubSystem` Upgrade

Add:
- `C` key: cycle cloud preset (RDR2 Cumulus → Sunset → Ash Storm → Clear)
- `K` key: reverse cycle
- `[` key: time -0.5h
- `]` key: time +0.5h
- (Keep existing F5/F6/F7 bindings too)

### 6.4 `BoidFaunaSubSystem` Upgrade

Add:
- Continuous night-intensity pulse for firefly lights (sinusoidal, not binary on/off)

### 6.5 `WaylandCompositorSubSystem` Upgrade

Add:
- Mouse button forwarding (mousePressed/mouseReleased → sendButton)

### 6.6 `GerstnerOceanSubSystem` Upgrade

Add:
- `L` key binding for liquid method cycling

---

## 7. Phase 2: Scene Upgrades

### 7.1 KarstCaveScene Rewrite

Current state: Manual FPS, no coordinator, no systems, no collision, no editing.

Target state:
```cpp
class KarstCaveScene : public ISimulationScene {
    ConcurrentSystemCoordinator coordinator;
    // Systems to register:
    // - MaterialSetupSubSystem (cave materials, headlamp, fog, lava glow)
    // - PlayerControllerSubSystem (full physics with AABB collision in cave)
    // - VoxelEditingSubSystem (mining, placing, STC, regen, mesh toggle)
    // - FogSubSystem (cave fog)
    // - HudRendererSubSystem (material inspector, FPS, position, crosshair)
};
```

Features to port from `voxel_cave_app.cpp`:
- FPSController → PlayerControllerSubSystem (gravity, collision, double jump, head bob, camera shake, raycast)
- Mining (LMB) → VoxelEditingSubSystem
- Placing (RMB) → VoxelEditingSubSystem
- Hotbar (1-8) → VoxelEditingSubSystem
- STC reactions (T) → VoxelEditingSubSystem
- Regeneration (R) → VoxelEditingSubSystem
- Mesh mode toggle (M) → VoxelEditingSubSystem
- Head-shake (H) → PlayerControllerSubSystem
- Materials (VoxelVertexColorMat, SmoothCaveMaterial) → MaterialSetupSubSystem
- Fog → FogSubSystem
- Lava glow light → MaterialSetupSubSystem
- Console HUD → HudRendererSubSystem

### 7.2 OceanLabScene Upgrade

Current state: Manual FPS, minimal ocean demo.

Target state:
```cpp
class OceanLabScene : public ISimulationScene {
    ConcurrentSystemCoordinator coordinator;
    // Systems to register:
    // - MaterialSetupSubSystem (ocean materials, sky materials)
    // - PlayerControllerSubSystem (full physics with water buoyancy)
    // - GerstnerOceanSubSystem (already exists, upgrade with L key)
    // - VolumetricAtmosphereSubSystem (sky dome)
    // - FogSubSystem (ocean fog, underwater mode)
    // - HudRendererSubSystem
};
```

### 7.3 AtmosphericLabScene Upgrade

Current state: Manual FPS, minimal sky demo.

Target state:
```cpp
class AtmosphericLabScene : public ISimulationScene {
    ConcurrentSystemCoordinator coordinator;
    // Systems to register:
    // - MaterialSetupSubSystem (sky materials)
    // - PlayerControllerSubSystem (full physics)
    // - VolumetricAtmosphereSubSystem (cloud presets, time keys)
    // - FogSubSystem
    // - HudRendererSubSystem
};
```

### 7.4 VolcanicIslandScene Upgrade

Current state: Full coordinator, 6 systems.

Add:
- `PlayerControllerSubSystem` (replace existing simplified `PlayerKinematicsSubSystem`)
- `VoxelEditingSubSystem` (mining, placing, STC, regen, mesh toggle)
- `MaterialSetupSubSystem` (all shared materials)
- `DynamicChunkSubSystem` (per-frame chunk streaming)
- `CelShadingSubSystem`
- `HudRendererSubSystem` (FPS calc, dissolve, 20Hz throttle)
- `FogSubSystem`
- `AutoScreenshotSubSystem` (optional)

Upgrade existing:
- `OpenVdbTerrainSubSystem` — add chunk streaming, mesh mode toggle
- `VolumetricAtmosphereSubSystem` — add C/K/[/] keys
- `BoidFaunaSubSystem` — continuous night pulse
- `WaylandCompositorSubSystem` — mouse button forwarding
- `GerstnerOceanSubSystem` — L key

---

## 8. Phase 3: ImGui Scene Selection Menu

### 8.1 ImGui Initialization in `simulation_main.cpp`

Add to `setup()`:
```cpp
// ImGui overlay init
imgui_overlay = initialiseImGui();
if (!imgui_overlay) {
    imgui_overlay = new Ogre::ImGuiOverlay();
    imgui_overlay->setZOrder(300);
    imgui_overlay->show();
    getOverlaySystem()->addOverlay(imgui_overlay);
}
ImGuiIO& io = ImGui::GetIO();
io.DisplaySize = ImVec2(1920.0f, 1080.0f);

// Input chain with ImGui
if (getImGuiInputListener()) {
    input_chain = OgreBites::InputListenerChain({getImGuiInputListener(), this});
    addInputListener(&input_chain);
}
```

Add to `frameRenderingQueued()`:
```cpp
ImGuiIO& io = ImGui::GetIO();
if (getRenderWindow()) {
    io.DisplaySize = ImVec2(float(getRenderWindow()->getWidth()), float(getRenderWindow()->getHeight()));
}
io.DeltaTime = dt;
```

### 8.2 Scene Selection Menu

New members:
```cpp
bool menu_open = true;         // Show menu on launch
int selected_scene = -1;       // -1 = no scene loaded
```

New method `renderSceneMenu()`:
```cpp
void renderSceneMenu() {
    auto& scenes = SimulationRegistry::instance().getScenes();
    ImGuiIO& io = ImGui::GetIO();
    float w = io.DisplaySize.x, h = io.DisplaySize.y;

    ImGui::SetNextWindowPos(ImVec2(w/2, h/2), ImGuiCond_Always, ImVec2(0.5f, 0.5f));
    ImGui::SetNextWindowSize(ImVec2(600, 400), ImGuiCond_FirstUseEver);
    ImGui::Begin("SCR Simulation Hub", &menu_open,
                 ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoCollapse);

    ImGui::Text("Select a simulation to run:");
    ImGui::Separator();

    for (size_t i = 0; i < scenes.size(); i++) {
        auto& entry = scenes[i];
        ImGui::PushID(i);

        // Scene card
        if (ImGui::Selectable(entry.metadata.title.c_str(),
                              selected_scene == (int)i,
                              ImGuiSelectableFlags_AllowDoubleClick,
                              ImVec2(0, 60))) {
            loadSimulationScene(i);
            menu_open = false;
        }
        // Subtitle + category
        ImGui::SameLine();
        ImGui::TextDisabled("%s | %s", entry.metadata.subtitle.c_str(),
                           entry.metadata.category.c_str());
        // Description (wrapped)
        ImGui::Indent(20);
        ImGui::TextWrapped("%s", entry.metadata.description.c_str());
        ImGui::Unindent(20);
        // Feature tags
        for (auto& tag : entry.metadata.feature_tags) {
            ImGui::SameLine();
            ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "[%s]", tag.c_str());
        }

        ImGui::Separator();
        ImGui::PopID();
    }

    ImGui::End();
}
```

Modified `frameRenderingQueued()`:
```cpp
bool frameRenderingQueued(const FrameEvent& evt) override {
    float dt = std::min(evt.timeSinceLastFrame, Config::MAX_FRAME_DT);
    global_time += dt;

    // ImGui frame sync
    ImGuiIO& io = ImGui::GetIO();
    if (getRenderWindow()) {
        io.DisplaySize = ImVec2(float(getRenderWindow()->getWidth()),
                               float(getRenderWindow()->getHeight()));
    }
    io.DeltaTime = dt;

    // Update loading screen
    loading_screen.update(dt);
    if (!loading_screen.isDone()) {
        loading_screen.renderLoadingMesh(loadingMeshObj, getRenderWindow());
    } else {
        if (loadingMeshObj) loadingMeshObj->clear();
    }

    // Process IPC
    ipc_server.processQueuedCommands(...);

    if (menu_open) {
        renderSceneMenu();
        // Still render active scene behind menu if one is loaded
        if (current_scene) {
            current_scene->update(dt, input_state);
            current_scene->renderHUD(hudMeshObj, getRenderWindow()->getViewport(0), hud_fade_alpha);
        }
        return true;
    }

    // Normal simulation loop
    if (current_scene) {
        current_scene->update(dt, input_state);
        float target_hud_alpha = (input_state.show_hud ? 1.0f : 0.0f) * loading_screen.alpha_in_game_hud;
        hud_fade_alpha += (target_hud_alpha - hud_fade_alpha) * std::min(1.0f, dt * Config::HUD_DISSOLVE_SPEED);
        current_scene->renderHUD(hudMeshObj, getRenderWindow()->getViewport(0), hud_fade_alpha);
    }

    input_state.mouse_dx = 0;
    input_state.mouse_dy = 0;
    return true;
}
```

Menu toggle: `Tab` key in `keyPressed()`:
```cpp
case SDLK_TAB:
    menu_open = !menu_open;
    return true;
```

---

## 9. Phase 4: Cleanup

### 9.1 Delete Files

| File | Reason |
|------|--------|
| `applications/cave/src/voxel_cave_app.cpp` | Replaced by KarstCaveScene |
| `applications/cave/src/volcanic_island_app.cpp` | Replaced by VolcanicIslandScene |
| `applications/cave/run_volcanic_island.sh` | No longer needed |
| `applications/cave/run_cave_explorer.sh` | No longer needed |

### 9.2 Update Build Scripts

`run_simulation_hub.sh`:
- Single entry point for all simulations
- Include paths updated for `lib/simulation/`
- All nix store paths verified correct

### 9.3 Validation

- Clean build from scratch (remove binary + generated files)
- Binary launches with scene selection menu
- All 4 scenes loadable and functional
- IPC socket functional
- No compiler warnings from app code (OGRE upstream warnings acceptable)
- No linker errors

---

## 10. Implementation Order

| Step | Phase | Description | Estimated Complexity |
|------|-------|-------------|---------------------|
| 1 | 1 | Create `lib/simulation/` directory | Trivial |
| 2 | 1 | Move 8 framework headers | Low |
| 3 | 1 | Create `simulation_config.hpp` | Low |
| 4 | 1 | Create `voxel_types.hpp` | Medium |
| 5 | 1 | Create `material_library.hpp` | Medium |
| 6 | 1 | Create `logging.hpp` | Low |
| 7 | 1 | Create `screenshot.hpp` | Low |
| 8 | 1 | Update all `#include` paths | Medium |
| 9 | 2 | Create `PlayerControllerSubSystem` | **High** — largest piece, ~500 lines from IslandPlayer |
| 10 | 2 | Create `VoxelEditingSubSystem` | High — mining, placing, STC, regen |
| 11 | 2 | Create `MaterialSetupSubSystem` | Medium — material creation |
| 12 | 2 | Create `FogSubSystem` | Low |
| 13 | 2 | Create `DynamicChunkSubSystem` | Low |
| 14 | 2 | Create `HudRendererSubSystem` | Medium |
| 15 | 2 | Create `CelShadingSubSystem` | Low |
| 16 | 2 | Create `AutoScreenshotSubSystem` | Low |
| 17 | 2 | Upgrade `OpenVdbTerrainSubSystem` | Medium — chunk streaming + mesh toggle |
| 18 | 2 | Upgrade `VolumetricAtmosphereSubSystem` | Low — key bindings |
| 19 | 2 | Upgrade `BoidFaunaSubSystem` | Low — continuous pulse |
| 20 | 2 | Upgrade `WaylandCompositorSubSystem` | Low — mouse buttons |
| 21 | 2 | Upgrade `GerstnerOceanSubSystem` | Low — L key |
| 22 | 3 | Rewrite `KarstCaveScene` | High — add coordinator + 5 systems |
| 23 | 3 | Upgrade `OceanLabScene` | Medium — add coordinator + 5 systems |
| 24 | 3 | Upgrade `AtmosphericLabScene` | Medium — add coordinator + 5 systems |
| 25 | 3 | Upgrade `VolcanicIslandScene` | Medium — add new systems |
| 26 | 3 | Add ImGui menu to `simulation_main.cpp` | Medium |
| 27 | 4 | Delete monoliths + update build | Low |

---

## 11. Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| `PlayerControllerSubSystem` collision detection is complex (per-axis AABB, step-climb, depenetration) | High — core gameplay | Port directly from tested monolith code. Unit test collision with known scenarios. |
| KarstCaveScene rewrite breaks cave generation | Medium | Verify VoxelCave API unchanged. Keep seed 2026 for regression. |
| ConcurrentSystemCoordinator threading introduces race conditions | Medium | Scenes that don't need concurrency can run `update()` (combined) instead of separate `stepSimulation()`+`renderPipeline()`. |
| ImGui overlay conflicts with OGRE ManualObject HUD | Low | ImGui z-order 300 renders above ManualObject overlays. |
| Material library creates materials not needed by all scenes | Low | Create all materials once; unused ones have minimal memory cost. |
| Deleting monoliths loses reference code | Low | Git history preserves all old code. Spec document captures all features. |

---

## 12. Acceptance Criteria

- [ ] Single binary `scr_simulation_hub` builds cleanly with zero app-code warnings
- [ ] Scene selection menu appears on launch (ImGui)
- [ ] All 4 scenes loadable from menu
- [ ] `Tab` key toggles menu at runtime
- [ ] `Ctrl+1..4` quick-switch still works
- [ ] KarstCaveScene has: collision, mining, placing, hotbar, STC, regen, mesh toggle, fog, materials, HUD
- [ ] OceanLabScene has: full physics with buoyancy, ocean rendering, fog, HUD
- [ ] AtmosphericLabScene has: full physics, cloud presets, time-of-day keys, fog, HUD
- [ ] VolcanicIslandScene has: all existing features + chunk streaming + cel shading + FPS calc + dissolve
- [ ] IPC server functional on `/tmp/scr_sim_hub.sock`
- [ ] Loading screen appears during scene load
- [ ] Clean from-scratch build succeeds
- [ ] `voxel_cave_app.cpp` and `volcanic_island_app.cpp` deleted
- [ ] `run_volcanic_island.sh` and `run_cave_explorer.sh` deleted
