#ifndef CAVE_SIMULATION_ENGINE_HPP
#define CAVE_SIMULATION_ENGINE_HPP

#include "simulation/spatial_semantics.hpp"
#include "simulation/simulation_framework.hpp"
#include "simulation/simulation_events.hpp"
#include "simulation_subjects.hpp"

#include <vector>
#include <memory>
#include <functional>
#include <chrono>
#include <algorithm>
#include <iostream>

namespace SCR::Simulation {

/**
 * Pure computational simulation context free of GPU and rendering dependencies.
 */
struct PureSimulationContext {
    SubjectRegistry& subjects;
    EventBus& events;
    float current_time = 0.0f;
    uint64_t tick_count = 0;

    PureSimulationContext(SubjectRegistry& subReg, EventBus& eBus)
        : subjects(subReg), events(eBus) {}
};

/**
 * Interface for pure simulation worker systems.
 */
class IPureSimulationWorker {
public:
    virtual ~IPureSimulationWorker() = default;
    virtual std::string getName() const = 0;
    virtual void prepare(LoadingContext& ctx, PureSimulationContext& simCtx) {
        (void)ctx; (void)simCtx;
    }
    virtual void tick(float dt, const UserInputState& input, PureSimulationContext& simCtx) = 0;
    virtual void handleEvent(const ISimulationEvent& event, PureSimulationContext& simCtx) {
        (void)event; (void)simCtx;
    }
};

/**
 * Deterministic Fixed-Timestep Simulation Loop Orchestrator.
 * 
 * Supports:
 * - Deterministic fixed physics/kinematic updates (e.g. 60Hz / 120Hz).
 * - Sub-frame temporal alpha calculation for smooth render interpolation.
 * - Standalone headless execution for test suites and high-speed benchmarks.
 */
class FixedTimestepSimulationLoop {
public:
    struct Config {
        float fixed_dt = 1.0f / 60.0f; // 60Hz deterministic fixed step
        float max_frame_dt = 0.20f;     // Clamps spiral-of-death during large hitches
        int max_sub_steps = 8;          // Maximum simulation ticks per render frame

        Config() = default;
        Config(float fdt, float mfdt = 0.20f, int mss = 8)
            : fixed_dt(fdt), max_frame_dt(mfdt), max_sub_steps(mss) {}
    };

    FixedTimestepSimulationLoop(SubjectRegistry& subReg, EventBus& eBus, Config cfg)
        : config_(cfg), context_(subReg, eBus) {}

    FixedTimestepSimulationLoop(SubjectRegistry& subReg, EventBus& eBus)
        : config_(), context_(subReg, eBus) {}

    void setFixedTimestep(float dt) {
        if (dt > 0.0001f) config_.fixed_dt = dt;
    }

    float getFixedTimestep() const { return config_.fixed_dt; }
    float getAccumulator() const { return accumulator_; }
    float getInterpolationAlpha() const { return std::min(1.0f, std::max(0.0f, accumulator_ / config_.fixed_dt)); }
    uint64_t getTotalTicks() const { return total_ticks_; }
    float getSimulatedTime() const { return simulated_time_; }

    void addWorker(std::shared_ptr<IPureSimulationWorker> worker) {
        if (worker) workers_.push_back(worker);
    }

    template<typename T>
    std::shared_ptr<T> getWorker() const {
        for (const auto& w : workers_) {
            if (auto typed = std::dynamic_pointer_cast<T>(w)) return typed;
        }
        return nullptr;
    }

    void prepare(LoadingContext& ctx) {
        for (auto& w : workers_) {
            w->prepare(ctx, context_);
        }
    }

    /**
     * Executes one exact fixed-time simulation step.
     */
    void stepFixed(float fixed_dt, const UserInputState& input) {
        for (auto& w : workers_) {
            w->tick(fixed_dt, input, context_);
        }

        context_.events.drainQueuedEvents();
        simulated_time_ += fixed_dt;
        total_ticks_++;
        context_.tick_count = total_ticks_;
        context_.current_time = simulated_time_;
    }

    /**
     * Advances the simulation loop by a variable elapsed time (dt),
     * executing one or more fixed-timestep ticks as needed.
     * Returns the number of fixed simulation steps executed.
     */
    int advanceTime(float dt, const UserInputState& input) {
        float clamped_dt = std::min(dt, config_.max_frame_dt);
        accumulator_ += clamped_dt;

        int steps_executed = 0;
        while (accumulator_ >= config_.fixed_dt && steps_executed < config_.max_sub_steps) {
            stepFixed(config_.fixed_dt, input);
            accumulator_ -= config_.fixed_dt;
            steps_executed++;
        }

        // Clamp remainder if overloaded to prevent perpetual delay
        if (accumulator_ > config_.fixed_dt * float(config_.max_sub_steps)) {
            accumulator_ = 0.0f;
        }

        return steps_executed;
    }

    void handleEvent(const ISimulationEvent& event) {
        for (auto& w : workers_) {
            w->handleEvent(event, context_);
        }
    }

    PureSimulationContext& getContext() { return context_; }

private:
    Config config_;
    PureSimulationContext context_;
    std::vector<std::shared_ptr<IPureSimulationWorker>> workers_;
    float accumulator_ = 0.0f;
    float simulated_time_ = 0.0f;
    uint64_t total_ticks_ = 0;
};

} // namespace SCR::Simulation

#endif // CAVE_SIMULATION_ENGINE_HPP
