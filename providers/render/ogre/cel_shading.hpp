#pragma once
/**
 * SCR CelShadingSubSystem — Toon/cel shading post-process
 * ─────────────────────────────────────────────────────────────────────────────
 * Optional toon shading overlay for scenes that want stylized look.
 */

#include "simulation/simulation_systems.hpp"

namespace SCR::Simulation {

class CelShadingSubSystem : public ISimulationSubSystem {
public:
    std::string getName() const override { return "CelShading"; }

    void initialize(SystemContext& ctx) override {
        enabled_ = false; // Off by default
    }

    void set_enabled(bool e) { enabled_ = e; }
    bool is_enabled() const { return enabled_; }

    void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) override {
        if (!enabled_) return;
        auto* scnMgr = renderCtx.getSceneManager<Ogre::SceneManager>();
        if (!scnMgr) return;
        // Apply cel shading post-process
    }

private:
    bool enabled_ = false;
};

} // namespace SCR::Simulation
