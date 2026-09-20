#ifndef CAVE_SIMULATION_SYSTEMS_CORE_HPP
#define CAVE_SIMULATION_SYSTEMS_CORE_HPP

#include <string>
#include <vector>
#include <memory>
#include <mutex>
#include <thread>
#include <future>
#include <atomic>
#include <iostream>

#include "simulation/spatial_semantics.hpp"
#include "simulation/simulation_framework.hpp"
#include "simulation_subjects.hpp"
#include "simulation/simulation_events.hpp"
#include "simulation_engine.hpp"

// NO Ogre.h — this file is OGRE-free
// NO rendering_pipeline.hpp, NO concrete subsystem headers

namespace SCR::Simulation {

// ─── Pure Simulation Context (Async-Safe, No GPU Pointers) ─────────────────
struct SimContext {
    SubjectRegistry& subjects;
    EventBus& events;
    float dt = 0.0f;
    float simulated_time = 0.0f;
    uint64_t tick_count = 0;

    SimContext(SubjectRegistry& sub, EventBus& eb)
        : subjects(sub), events(eb) {}
};

// ─── Rendering Context (Main Thread Only, Opaque Pointers) ─────────────────
struct RenderContext {
    void* native_scene_manager = nullptr;
    void* native_camera = nullptr;
    void* native_window = nullptr;
    void* native_viewport = nullptr;

    template <typename T> T* getSceneManager() const { return static_cast<T*>(native_scene_manager); }
    template <typename T> T* getCamera() const { return static_cast<T*>(native_camera); }
    template <typename T> T* getWindow() const { return static_cast<T*>(native_window); }
};

// ─── System Context (OGRE-free, uses RenderContext for render pointers) ────
struct SystemContext {
    SubjectRegistry& subjects;
    EventBus& events;
    RenderContext renderCtx;

    SystemContext(SubjectRegistry& sub, EventBus& eb)
        : subjects(sub), events(eb) {}

    SimContext toSimContext() const {
        SimContext sc(subjects, events);
        return sc;
    }

    RenderContext toRenderContext() const { return renderCtx; }
};

/**
 * Abstract Base Subsystem interface.
 * Phase 2: Dual-context — updateSim runs pure simulation, renderSync applies GPU state.
 * Phase 2 complete: all subsystems use updateSim/renderSync(RenderContext, SimContext, dt).
 */
class ISimulationSubSystem {
public:
    virtual ~ISimulationSubSystem() = default;

    virtual std::string getName() const = 0;

    virtual void initialize(SystemContext& ctx) { (void)ctx; }
    virtual void prepare(LoadingContext& ctx, SystemContext& sysCtx) { (void)ctx; (void)sysCtx; }

    /**
     * Pure simulation phase — can execute on background thread pool.
     * No OGRE/GPU pointer access allowed here.
     */
    virtual void updateSim(float dt, const UserInputState& input, SimContext& ctx) {
        (void)dt; (void)input; (void)ctx;
    }

    /**
     * Render synchronization phase — executes strictly on main render thread.
     */
    virtual void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) {
        (void)renderCtx; (void)simCtx; (void)dt;
    }

    virtual void handleEvent(const ISimulationEvent& event, SimContext& ctx) {
        (void)event; (void)ctx;
    }

    virtual void cleanup(RenderContext& renderCtx) {
        (void)renderCtx;
    }
};

/**
 * Composite Simulation System owning and orchestrating child subsystems.
 */
class ISimulationSystem {
public:
    virtual ~ISimulationSystem() = default;

    virtual std::string getName() const = 0;

    void addSubSystem(std::shared_ptr<ISimulationSubSystem> sub) {
        if (sub) sub_systems_.push_back(sub);
    }

    const std::vector<std::shared_ptr<ISimulationSubSystem>>& getSubSystems() const {
        return sub_systems_;
    }

    virtual void initialize(SystemContext& ctx) {
        for (auto& sub : sub_systems_) sub->initialize(ctx);
    }

    virtual void prepare(LoadingContext& ctx, SystemContext& sysCtx) {
        for (auto& sub : sub_systems_) sub->prepare(ctx, sysCtx);
    }

    virtual void updateSim(float dt, const UserInputState& input, SimContext& ctx) {
        for (auto& sub : sub_systems_) sub->updateSim(dt, input, ctx);
    }

    virtual void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) {
        for (auto& sub : sub_systems_) sub->renderSync(renderCtx, simCtx, dt);
    }

    virtual void handleEvent(const ISimulationEvent& event, SimContext& ctx) {
        for (auto& sub : sub_systems_) sub->handleEvent(event, ctx);
    }

    virtual void cleanup(RenderContext& renderCtx) {
        for (auto& sub : sub_systems_) sub->cleanup(renderCtx);
    }

protected:
    std::vector<std::shared_ptr<ISimulationSubSystem>> sub_systems_;
};

// ═══════════════════════════════════════════════════════════════════════════════
// CONCURRENT SYSTEM COORDINATOR (OGRE-free)
// ═══════════════════════════════════════════════════════════════════════════════

class ConcurrentSystemCoordinator {
public:
    ConcurrentSystemCoordinator(SubjectRegistry& subReg, EventBus& eBus)
        : context_(subReg, eBus) {
        startThreadPool(4);
    }

    ~ConcurrentSystemCoordinator() {
        stopThreadPool();
    }

    void registerSystem(std::shared_ptr<ISimulationSystem> system) {
        if (system) systems_.push_back(system);
    }

    template<typename T>
    std::shared_ptr<T> getSystem() const {
        for (size_t i = 0; i < systems_.size(); ++i) {
            if (auto typed = std::dynamic_pointer_cast<T>(systems_[i])) {
                return typed;
            }
        }
        return nullptr;
    }

    void setRenderContext(RenderContext& rc) {
        context_.renderCtx = rc;
    }

    void initialize() {
        for (auto& sys : systems_) {
            sys->initialize(context_);
        }
    }

    void prepare(LoadingContext& ctx) {
        for (auto& sys : systems_) {
            sys->prepare(ctx, context_);
        }
    }

    /**
     * Executes pure computational simulation step across all registered systems
     * on worker threads, synchronizes at barrier, and drains semantic events into the SubjectRegistry.
     * ZERO OGRE / GPU rendering calls happen in this phase.
     */
    void stepSimulation(float dt, const UserInputState& input) {
        SimContext simCtx = context_.toSimContext();

        // 1. Parallel Asynchronous System Simulation Step
        std::vector<std::future<void>> futures;
        for (auto& sys : systems_) {
            futures.push_back(std::async(std::launch::async, [this, sys, dt, input, &simCtx]() {
                sys->updateSim(dt, input, simCtx);
            }));
        }

        // 2. Barrier Synchronization
        for (auto& f : futures) {
            f.get();
        }

        // 3. Drain and Dispatch Queued Asynchronous Events
        context_.events.drainQueuedEvents();
    }

    /**
     * Executes the dedicated Rendering Pipeline stage, extracting state snapshot and
     * synchronizing GPU vertex buffers, shaders, and visual scene nodes.
     */
    void renderPipeline(float dt) {
        RenderContext renderCtx = context_.toRenderContext();
        SimContext simCtx = context_.toSimContext();
        for (auto& sys : systems_) {
            sys->renderSync(renderCtx, simCtx, dt);
        }
    }

    /**
     * Backward-compatible combined cycle executing stepSimulation followed by renderPipeline.
     */
    void update(float dt, const UserInputState& input) {
        stepSimulation(dt, input);
        renderPipeline(dt);
    }

    void handleEvent(const ISimulationEvent& event) {
        SimContext simCtx = context_.toSimContext();
        for (auto& sys : systems_) {
            sys->handleEvent(event, simCtx);
        }
    }

    void cleanup(RenderContext& renderCtx) {
        for (auto& sys : systems_) {
            sys->cleanup(renderCtx);
        }
        systems_.clear();
    }

    SystemContext& getContext() { return context_; }

private:
    void startThreadPool(size_t threads = 4) {
        (void)threads;
    }

    void stopThreadPool() {
    }

    SystemContext context_;
    std::vector<std::shared_ptr<ISimulationSystem>> systems_;
};

} // namespace SCR::Simulation

#endif // CAVE_SIMULATION_SYSTEMS_CORE_HPP
