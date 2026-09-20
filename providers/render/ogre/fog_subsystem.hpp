#pragma once
/**
 * SCR FogSubSystem — Dynamic distance fog
 * ─────────────────────────────────────────────────────────────────────────────
 * Configurable fog with time-of-day color blending.
 */

#include "simulation/simulation_systems.hpp"
#include "simulation/simulation_config.hpp"

namespace SCR::Simulation {

class FogSubSystem : public ISimulationSubSystem {
public:
    std::string getName() const override { return "Fog"; }

    void initialize(SystemContext& ctx) override {
        auto* scnMgr = ctx.renderCtx.getSceneManager<Ogre::SceneManager>();
        if (!scnMgr) return;
        scnMgr->setFog(Ogre::FOG_LINEAR, fog_color_, density_, fog_start_, fog_end_);
    }

    void set_fog_color(const Ogre::ColourValue& c) { fog_color_ = c; }
    void set_fog_range(float start, float end) { fog_start_ = start; fog_end_ = end; }
    void set_density(float d) { density_ = d; }

    void update_fog(Ogre::SceneManager* mgr) {
        if (!mgr) return;
        mgr->setFog(Ogre::FOG_LINEAR, fog_color_, density_, fog_start_, fog_end_);
    }

private:
    Ogre::ColourValue fog_color_ = Ogre::ColourValue(0.6f, 0.7f, 0.85f);
    float fog_start_ = 80.0f;
    float fog_end_ = 500.0f;
    float density_ = 0.002f;
};

} // namespace SCR::Simulation
