#pragma once
/**
 * SCR HudRendererSubSystem — In-world HUD display
 * ─────────────────────────────────────────────────────────────────────────────
 * Renders health, stamina, compass, minimap on in-world quad.
 */

#include "simulation/simulation_systems_core.hpp"
#include "simulation_config.hpp"

namespace SCR::Simulation {

class HudRendererSubSystem : public ISimulationSubSystem {
public:
    std::string getName() const override { return "HudRenderer"; }

    void initialize(SystemContext& ctx) override {
        // Create in-world HUD quad
    }

    void updateSim(float dt, const UserInputState& input, SimContext& ctx) override {
        // Update HUD data: FPS, position, biome, etc.
    }

    void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) override {
        // Update GPU buffers for HUD quad
    }

private:
    float hud_update_timer_ = 0.0f;
};

} // namespace SCR::Simulation
