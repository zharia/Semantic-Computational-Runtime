#ifndef CAVE_SIMULATION_FRAMEWORK_HPP
#define CAVE_SIMULATION_FRAMEWORK_HPP

#include <string>
#include <vector>
#include <memory>
#include <functional>
#include <chrono>
#include <map>
#include <iostream>

#include <Ogre.h>
#include <OgreApplicationContext.h>
#include <OgreCamera.h>
#include <OgreSceneManager.h>
#include <OgreRenderWindow.h>
#include <OgreViewport.h>

#include "spatial_semantics.hpp"
#include "semantic_materials.hpp"

namespace SCR::Simulation {

// ─── Scene Metadata ──────────────────────────────────────────────────────────
struct SceneMetadata {
    std::string id;
    std::string title;
    std::string subtitle;
    std::string category;
    std::string description;
    std::string semantic_contract;
    std::string author;
    std::string version;
    std::vector<std::string> feature_tags;
};

// ─── Loading Feedback & Progress Context ─────────────────────────────────────
struct LoadingTaskUpdate {
    float progress;               // 0.0 to 1.0
    std::string current_stage;    // High level phase (e.g. "Synthesizing Stratovolcano Geomorphology")
    std::string detail_message;   // Detailed subsystem status (e.g. "OpenVDB Isosurface polygonization: 18,261 vertices")
    std::string subsystem;        // Subsystem name (e.g. "VDB_MESHER", "OCEAN_GERSTNER", "VOLCANO_BINGHAM")
    uint64_t items_processed;
    uint64_t total_items;
    std::chrono::high_resolution_clock::time_point timestamp;
};

using ProgressCallback = std::function<void(const LoadingTaskUpdate&)>;

class LoadingContext {
public:
    ProgressCallback callback;
    std::vector<std::string> log_history;
    float current_progress = 0.0f;
    std::string stage_title = "Initializing";

    LoadingContext(ProgressCallback cb = nullptr) : callback(cb) {}

    void update(float progress, const std::string& stage, const std::string& detail = "",
                const std::string& subsystem = "CORE", uint64_t current = 0, uint64_t total = 0) {
        current_progress = std::max(0.0f, std::min(1.0f, progress));
        stage_title = stage;
        std::string log_entry = "[" + subsystem + "] " + stage + (detail.empty() ? "" : (" — " + detail));
        log_history.push_back(log_entry);

        if (callback) {
            LoadingTaskUpdate update_info;
            update_info.progress = current_progress;
            update_info.current_stage = stage;
            update_info.detail_message = detail;
            update_info.subsystem = subsystem;
            update_info.items_processed = current;
            update_info.total_items = total;
            update_info.timestamp = std::chrono::high_resolution_clock::now();
            callback(update_info);
        }
    }
};

// ─── User Input State ────────────────────────────────────────────────────────
struct UserInputState {
    bool move_forward  = false;
    bool move_backward = false;
    bool move_left     = false;
    bool move_right    = false;
    bool move_up       = false;
    bool move_down     = false;
    bool sprint        = false;
    bool jump          = false;
    bool action_primary   = false;
    bool action_secondary = false;
    bool show_hud         = false;
    float mouse_dx     = 0.0f;
    float mouse_dy     = 0.0f;
    int selected_hotbar_slot = 1;
};

// ─── Simulation Scene Interface ──────────────────────────────────────────────
class ISimulationScene {
public:
    virtual ~ISimulationScene() = default;

    virtual SceneMetadata getMetadata() const = 0;

    /**
     * Heavy procedural synthesis / asset loading phase.
     * Periodic updates to ctx allow real-time feedback on the loading screen.
     */
    virtual void prepare(LoadingContext& ctx) = 0;

    /**
     * Initializes Ogre scene graph, lighting, materials, and GPU buffers.
     */
    virtual void initScene(
        Ogre::SceneManager* scnMgr,
        Ogre::Camera* cam,
        Ogre::RenderWindow* win
    ) = 0;

    /**
     * Per-frame physics, kinematics, and simulation step.
     */
    virtual void update(
        float dt,
        const UserInputState& input
    ) = 0;

    /**
     * Renders simulation-specific in-game HUD overlay directly into 2D overlay mesh.
     */
    virtual void renderHUD(
        Ogre::ManualObject* hudObj,
        Ogre::Viewport* vp,
        float screen_alpha = 1.0f
    ) = 0;

    /**
     * Handles keypress events specific to this simulation.
     */
    virtual bool handleKeyPress(int key, bool down) { (void)key; (void)down; return false; }

    /**
     * Releases all scene graph objects, nodes, lights, and materials.
     */
    virtual void cleanup(Ogre::SceneManager* scnMgr) = 0;
};

// ─── Simulation Registry ─────────────────────────────────────────────────────
class SimulationRegistry {
public:
    using SceneFactory = std::function<std::unique_ptr<ISimulationScene>()>;

    struct RegisteredEntry {
        SceneMetadata metadata;
        SceneFactory factory;
    };

    static SimulationRegistry& instance() {
        static SimulationRegistry reg;
        return reg;
    }

    void registerScene(const SceneMetadata& meta, SceneFactory factory) {
        scenes.push_back({meta, factory});
        scene_map[meta.id] = (int)scenes.size() - 1;
    }

    const std::vector<RegisteredEntry>& getScenes() const { return scenes; }

    std::unique_ptr<ISimulationScene> createScene(int index) const {
        if (index >= 0 && index < (int)scenes.size()) {
            return scenes[index].factory();
        }
        return nullptr;
    }

    std::unique_ptr<ISimulationScene> createScene(const std::string& id) const {
        auto it = scene_map.find(id);
        if (it != scene_map.end()) {
            return createScene(it->second);
        }
        return nullptr;
    }

    int getIndexById(const std::string& id) const {
        auto it = scene_map.find(id);
        return it != scene_map.end() ? it->second : -1;
    }

private:
    std::vector<RegisteredEntry> scenes;
    std::map<std::string, int> scene_map;
};

} // namespace SCR::Simulation

#endif // CAVE_SIMULATION_FRAMEWORK_HPP
