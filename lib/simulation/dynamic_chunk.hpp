#pragma once
/**
 * SCR DynamicChunkSubSystem — VDB chunk streaming
 * ─────────────────────────────────────────────────────────────────────────────
 * Loads/unloads VDB chunks around camera position.
 */

#include "simulation/simulation_systems_core.hpp"
#include "simulation_config.hpp"
#include "simulation/spatial_semantics.hpp"

namespace SCR::Simulation {

class DynamicChunkSubSystem : public ISimulationSubSystem {
public:
    std::string getName() const override { return "DynamicChunk"; }

    void initialize(SystemContext& ctx) override {
        // Initialize chunk manager
    }

    void updateSim(float dt, const UserInputState& input, SimContext& ctx) override {
        auto player_sub = ctx.subjects.getFirstSubjectOfType<PlayerSubject>(SubjectType::PLAYER);
        if (!player_sub) return;

        Spatial::Point3D pos = player_sub->position;
        int cx = static_cast<int>(std::floor(pos.x / 16.0f));
        int cy = static_cast<int>(std::floor(pos.y / 16.0f));
        int cz = static_cast<int>(std::floor(pos.z / 16.0f));

        if (cx != last_cx_ || cy != last_cy_ || cz != last_cz_) {
            last_cx_ = cx;
            last_cy_ = cy;
            last_cz_ = cz;
            // Trigger chunk load/unload
        }
    }

private:
    int last_cx_ = -999, last_cy_ = -999, last_cz_ = -999;
};

class DynamicChunkSystem : public ISimulationSystem {
public:
    std::string getName() const override { return "DynamicChunkSystem"; }

    DynamicChunkSystem() {
        addSubSystem(std::make_shared<DynamicChunkSubSystem>());
    }
};

} // namespace SCR::Simulation
