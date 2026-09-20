#include <iostream>
#include <cassert>
#include <vector>
#include <cmath>

#include "spatial_semantics.hpp"
#include "simulation_framework.hpp"
#include "simulation_subjects.hpp"
#include "simulation_events.hpp"
#include "simulation_engine.hpp"
#include "render/ogre/rendering_pipeline.hpp"

using namespace SCR::Simulation;
using namespace SCR::Render;

// Mock simulation worker
class MockPhysicsWorker : public IPureSimulationWorker {
public:
    int tick_count = 0;
    float accumulated_time = 0.0f;

    std::string getName() const override { return "MockPhysicsWorker"; }

    void tick(float dt, const UserInputState& input, PureSimulationContext& simCtx) override {
        (void)input; (void)simCtx;
        tick_count++;
        accumulated_time += dt;

        if (auto player = simCtx.subjects.getFirstSubjectOfType<PlayerSubject>(SubjectType::PLAYER)) {
            player->position.x += 1.0f * dt;
            player->position.z += 2.0f * dt;
        }
    }
};

class MockRenderStageA : public IRenderStage {
public:
    int exec_count = 0;
    std::string getName() const override { return "MockRenderStageA"; }
    int getPriority() const override { return 10; }

    void execute(RenderViewContext& ctx, const RenderSnapshot& snapshot) override {
        (void)ctx; (void)snapshot;
        exec_count++;
    }
};

class MockRenderStageB : public IRenderStage {
public:
    int exec_count = 0;
    std::string getName() const override { return "MockRenderStageB"; }
    int getPriority() const override { return 20; }

    void execute(RenderViewContext& ctx, const RenderSnapshot& snapshot) override {
        (void)ctx; (void)snapshot;
        exec_count++;
    }
};

int main() {
    std::cout << "=================================================================\n";
    std::cout << "  RUNNING PURE SIMULATION & RENDERING PIPELINE SEPARATION TESTS  \n";
    std::cout << "=================================================================\n";

    SubjectRegistry subjects;
    EventBus events;

    auto player = std::make_shared<PlayerSubject>();
    player->position = SCR::Spatial::Point3D(10.0f, 5.0f, 10.0f);
    subjects.registerSubject(player);

    auto atmo = std::make_shared<AtmosphereSubject>();
    atmo->time_of_day_hours = 14.5f;
    subjects.registerSubject(atmo);

    // ── Test 1: FixedTimestepSimulationLoop ─────────────────────────────────────
    std::cout << "[Test 1] Testing FixedTimestepSimulationLoop Determinism...\n";
    FixedTimestepSimulationLoop loop(subjects, events, { 1.0f / 60.0f, 0.20f, 8 });
    auto mock_worker = std::make_shared<MockPhysicsWorker>();
    loop.addWorker(mock_worker);

    UserInputState input;
    // Step exactly 1.0 second (should execute exactly 60 steps)
    for (int i = 0; i < 60; ++i) {
        loop.stepFixed(1.0f / 60.0f, input);
    }

    assert(mock_worker->tick_count == 60);
    assert(loop.getTotalTicks() == 60);
    assert(std::abs(loop.getSimulatedTime() - 1.0f) < 1e-4f);
    assert(std::abs(player->position.x - 11.0f) < 1e-3f);
    assert(std::abs(player->position.z - 12.0f) < 1e-3f);
    std::cout << "  ✅ Fixed-timestep simulation tick count & kinematics verified (60 ticks).\n";

    // ── Test 2: Variable Frame Advance & Accumulator ────────────────────────────
    std::cout << "[Test 2] Testing Variable Frame Advance & Accumulator Sub-stepping...\n";
    // Advance 0.051s (at 60Hz dt=0.016667s, this safely triggers 3 fixed steps)
    int steps = loop.advanceTime(0.051f, input);
    assert(steps == 3);
    assert(mock_worker->tick_count == 63);
    float alpha = loop.getInterpolationAlpha();
    assert(alpha >= 0.0f && alpha <= 1.0f);
    std::cout << "  ✅ Sub-stepping executed " << steps << " steps, alpha: " << alpha << "\n";

    // ── Test 3: Render Snapshot Extraction ─────────────────────────────────────
    std::cout << "[Test 3] Testing RenderDataExtractor Snapshot Generation...\n";
    RenderSnapshot snapshot = RenderDataExtractor::extractSnapshot(loop.getContext());
    assert(snapshot.simulation_tick == 63);
    assert(std::abs(snapshot.player_pos.x - player->position.x) < 1e-5f);
    assert(std::abs(snapshot.time_of_day - 14.5f) < 1e-5f);
    std::cout << "  ✅ Snapshot extracted with tick=" << snapshot.simulation_tick 
              << ", pos=(" << snapshot.player_pos.x << ", " << snapshot.player_pos.y << ", " << snapshot.player_pos.z << ")\n";

    // ── Test 4: Headless Render Pipeline Execution ─────────────────────────────
    std::cout << "[Test 4] Testing HeadlessRenderPipeline Execution...\n";
    HeadlessRenderPipeline pipeline;
    auto stage_a = std::make_shared<MockRenderStageA>();
    auto stage_b = std::make_shared<MockRenderStageB>();
    pipeline.addStage(stage_a);
    pipeline.addStage(stage_b);
    pipeline.initialize(nullptr, nullptr, nullptr);
    assert(pipeline.isInitialized());

    for (int f = 0; f < 10; ++f) {
        pipeline.renderFrame(snapshot, 0.016f, f * 0.016f, alpha);
    }

    assert(pipeline.recorded_frames.size() == 10);
    assert(pipeline.recorded_frames[9].frame_index == 9);
    assert(pipeline.recorded_frames[9].executed_stages == 2);
    std::cout << "  ✅ Pipeline executed 10 headless frames across 2 stages.\n";

    std::cout << "=================================================================\n";
    std::cout << "  ALL SIMULATION & RENDERING SEPARATION TESTS PASSED (100%)\n";
    std::cout << "=================================================================\n";
    return 0;
}
