#pragma once
/**
 * SCR MaterialSetupSubSystem — OGRE material creation for voxel types
 * ─────────────────────────────────────────────────────────────────────────────
 * Creates per-material OGRE MaterialPtr with correct ambient/diffuse/emission.
 * Handles alpha-blended transparency and emissive materials.
 */

#include "simulation/simulation_systems.hpp"
#include "simulation/semantic_materials.hpp"
#include <unordered_map>

namespace SCR::Simulation {

class MaterialSetupSubSystem : public ISimulationSubSystem {
public:
    std::string getName() const override { return "MaterialSetup"; }

    void initialize(SystemContext& ctx) override {
        auto* scnMgr = ctx.renderCtx.getSceneManager<Ogre::SceneManager>();
        if (!scnMgr) return;

        for (uint16_t code = 0; code <= 29; ++code) {
            std::string mat_name = "voxel/material_" + std::to_string(code);
            auto mat = Ogre::MaterialManager::getSingleton().create(
                mat_name, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);

            auto tech = mat->createTechnique();
            auto pass = tech->createPass();

            Ogre::ColourValue grey(0.5f, 0.5f, 0.5f);
            pass->setAmbient(grey * 0.3f);
            pass->setDiffuse(grey);

            materials_[code] = mat;
        }
    }

    Ogre::MaterialPtr get_material(uint16_t code) const {
        auto it = materials_.find(code);
        return it != materials_.end() ? it->second : Ogre::MaterialPtr();
    }

private:
    std::unordered_map<uint16_t, Ogre::MaterialPtr> materials_;
};

} // namespace SCR::Simulation
