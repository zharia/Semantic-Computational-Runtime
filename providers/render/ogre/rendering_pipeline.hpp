#ifndef CAVE_RENDERING_PIPELINE_HPP
#define CAVE_RENDERING_PIPELINE_HPP

#include <Ogre.h>
#include <OgreSceneManager.h>
#include <OgreCamera.h>
#include <OgreRenderWindow.h>
#include <OgreViewport.h>

#include "simulation/spatial_semantics.hpp"
#include "simulation_subjects.hpp"

#include <vector>
#include <memory>
#include <string>
#include <chrono>
#include <iostream>

namespace SCR::Render {

/**
 * Rendering View Context provided to every Render Stage during pipeline execution.
 */
struct RenderViewContext {
    Ogre::SceneManager* sceneMgr = nullptr;
    Ogre::Camera* camera = nullptr;
    Ogre::RenderWindow* window = nullptr;
    Ogre::Viewport* viewport = nullptr;
    
    Spatial::Point3D camera_pos = { 0.0f, 0.0f, 0.0f };
    Spatial::Vector3D camera_forward = { 0.0f, 0.0f, -1.0f };
    Spatial::Vector3D sun_dir = { 0.0f, 1.0f, 0.0f };
    Spatial::Vector3D moon_dir = { 0.0f, -1.0f, 0.0f };
    
    float time_of_day_hours = 12.0f;
    float delta_time = 0.016f;
    float global_time = 0.0f;
    float interpolation_alpha = 1.0f;
    bool under_water = false;
};

/**
 * Lightweight Snapshot extracted from the Simulation Domain for decoupled rendering.
 */
struct RenderSnapshot {
    uint64_t simulation_tick = 0;
    float simulated_time = 0.0f;
    
    // Player / Camera State
    Spatial::Point3D player_pos = { 0.0f, 0.0f, 0.0f };
    float player_yaw = 0.0f;
    float player_pitch = 0.0f;
    float player_smooth_eye_y = 0.0f;
    bool player_in_water = false;
    
    // Atmosphere State
    float time_of_day = 12.0f;
    float sun_azimuth = 0.0f;
    float sun_elevation = 1.0f;
    float cloud_density = 0.85f;
    
    // Island / Terrain State
    std::shared_ptr<Island::VoxelIsland> voxel_island;
    
    // Telemetry
    size_t active_boids_count = 0;
    size_t active_rigid_bodies_count = 0;
};

/**
 * Interface for modular Render Pipeline Stages.
 */
class IRenderStage {
public:
    virtual ~IRenderStage() = default;
    virtual std::string getName() const = 0;
    virtual int getPriority() const { return 100; } // Lower executes earlier
    
    virtual void initialize(RenderViewContext& ctx) { (void)ctx; }
    virtual void execute(RenderViewContext& ctx, const RenderSnapshot& snapshot) = 0;
    virtual void cleanup(Ogre::SceneManager* scnMgr) { (void)scnMgr; }
};

/**
 * Interface for the Rendering Pipeline.
 */
class IRenderingPipeline {
public:
    virtual ~IRenderingPipeline() = default;
    virtual void addStage(std::shared_ptr<IRenderStage> stage) = 0;
    virtual void initialize(Ogre::SceneManager* scnMgr, Ogre::Camera* cam, Ogre::RenderWindow* win) = 0;
    virtual void renderFrame(const RenderSnapshot& snapshot, float dt, float global_time, float interp_alpha) = 0;
    virtual void cleanup(Ogre::SceneManager* scnMgr) = 0;
};

/**
 * Modular Production Render Pipeline.
 */
class ModularRenderPipeline : public IRenderingPipeline {
public:
    ModularRenderPipeline() = default;
    
    void addStage(std::shared_ptr<IRenderStage> stage) override {
        if (!stage) return;
        stages_.push_back(stage);
        // Sort stages by priority
        std::sort(stages_.begin(), stages_.end(), [](const auto& a, const auto& b) {
            return a->getPriority() < b->getPriority();
        });
    }

    template<typename T>
    std::shared_ptr<T> getStage() const {
        for (const auto& s : stages_) {
            if (auto typed = std::dynamic_pointer_cast<T>(s)) return typed;
        }
        return nullptr;
    }

    void initialize(Ogre::SceneManager* scnMgr, Ogre::Camera* cam, Ogre::RenderWindow* win) override {
        context_.sceneMgr = scnMgr;
        context_.camera = cam;
        context_.window = win;
        if (win && win->getNumViewports() > 0) {
            context_.viewport = win->getViewport(0);
        }

        for (auto& stage : stages_) {
            stage->initialize(context_);
        }
    }

    void renderFrame(const RenderSnapshot& snapshot, float dt, float global_time, float interp_alpha) override {
        if (!context_.sceneMgr || !context_.camera) return;

        // 1. Prepare View Context
        auto real_pos = context_.camera->getRealPosition();
        auto real_dir = context_.camera->getRealDirection();
        context_.camera_pos = Spatial::Point3D(real_pos.x, real_pos.y, real_pos.z);
        context_.camera_forward = Spatial::Vector3D(real_dir.x, real_dir.y, real_dir.z);
        context_.delta_time = dt;
        context_.global_time = global_time;
        context_.interpolation_alpha = interp_alpha;
        context_.time_of_day_hours = snapshot.time_of_day;
        context_.under_water = snapshot.player_in_water;

        // Compute Diurnal Light Vectors
        float solar_angle = (snapshot.time_of_day / 24.0f) * 6.2831853f - 1.5707963f;
        context_.sun_dir = Spatial::Vector3D(std::cos(solar_angle) * 0.85f, std::sin(solar_angle), 0.35f).normalized();
        context_.moon_dir = Spatial::Vector3D(-context_.sun_dir.x, -context_.sun_dir.y, -context_.sun_dir.z).normalized();

        // 2. Sequential Execution of Render Stages
        for (auto& stage : stages_) {
            stage->execute(context_, snapshot);
        }
    }

    void cleanup(Ogre::SceneManager* scnMgr) override {
        for (auto& stage : stages_) {
            stage->cleanup(scnMgr);
        }
        stages_.clear();
    }

    RenderViewContext& getViewContext() { return context_; }

private:
    RenderViewContext context_;
    std::vector<std::shared_ptr<IRenderStage>> stages_;
};

/**
 * Headless Render Pipeline for automated unit testing and CI benchmarking.
 */
class HeadlessRenderPipeline : public IRenderingPipeline {
public:
    struct FrameTelemetry {
        uint64_t frame_index = 0;
        size_t executed_stages = 0;
        float frame_dt = 0.0f;
        float global_time = 0.0f;
    };

    std::vector<FrameTelemetry> recorded_frames;

    void addStage(std::shared_ptr<IRenderStage> stage) override {
        if (stage) stages_.push_back(stage);
    }

    void initialize(Ogre::SceneManager* scnMgr, Ogre::Camera* cam, Ogre::RenderWindow* win) override {
        (void)scnMgr; (void)cam; (void)win;
        initialized_ = true;
    }

    void renderFrame(const RenderSnapshot& snapshot, float dt, float global_time, float interp_alpha) override {
        (void)snapshot; (void)interp_alpha;
        FrameTelemetry telem;
        telem.frame_index = frame_counter_++;
        telem.executed_stages = stages_.size();
        telem.frame_dt = dt;
        telem.global_time = global_time;
        recorded_frames.push_back(telem);
    }

    void cleanup(Ogre::SceneManager* scnMgr) override {
        (void)scnMgr;
        stages_.clear();
        initialized_ = false;
    }

    bool isInitialized() const { return initialized_; }

private:
    bool initialized_ = false;
    uint64_t frame_counter_ = 0;
    std::vector<std::shared_ptr<IRenderStage>> stages_;
};

/**
 * State Extractor helper bridging SubjectRegistry to RenderSnapshot.
 */
class RenderDataExtractor {
public:
    static RenderSnapshot extractSnapshot(const Simulation::PureSimulationContext& simCtx) {
        RenderSnapshot snap;
        snap.simulation_tick = simCtx.tick_count;
        snap.simulated_time = simCtx.current_time;

        if (auto player = simCtx.subjects.getFirstSubjectOfType<Simulation::PlayerSubject>(Simulation::SubjectType::PLAYER)) {
            snap.player_pos = player->position;
            snap.player_yaw = player->yaw;
            snap.player_pitch = player->pitch;
            snap.player_smooth_eye_y = player->smooth_eye_y;
            snap.player_in_water = player->in_water;
        }

        if (auto atmo = simCtx.subjects.getFirstSubjectOfType<Simulation::AtmosphereSubject>(Simulation::SubjectType::ATMOSPHERE)) {
            snap.time_of_day = atmo->time_of_day_hours;
            float solar_ang = (atmo->time_of_day_hours / 24.0f) * 6.2831853f - 1.5707963f;
            snap.sun_azimuth = 0.45f;
            snap.sun_elevation = std::sin(solar_ang);
            snap.cloud_density = atmo->cloud_coverage;
        }

        if (auto island = simCtx.subjects.getFirstSubjectOfType<Simulation::IslandSubject>(Simulation::SubjectType::ISLAND)) {
            snap.voxel_island = island->voxel_island;
        }

        if (auto eco = simCtx.subjects.getFirstSubjectOfType<Simulation::EcologySubject>(Simulation::SubjectType::ECOLOGY)) {
            snap.active_boids_count = eco->palm_count + eco->tree_count + eco->bush_count;
        }

        return snap;
    }
};

} // namespace SCR::Render

#endif // CAVE_RENDERING_PIPELINE_HPP
