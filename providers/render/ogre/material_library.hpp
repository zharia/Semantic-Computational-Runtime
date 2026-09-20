#pragma once
/**
 * SCR Material Library — OGRE material setup for voxel materials
 * ─────────────────────────────────────────────────────────────────────────────
 * Creates and caches Ogre::MaterialInstance for each VoxelTypeCode.
 * Handles alpha-blended transparency and fresnel reflection.
 */

#include <OGRE/Ogre.h>
#include <unordered_map>
#include "simulation/semantic_materials.hpp"

namespace SCR::Material {

class MaterialLibrary {
public:
    MaterialLibrary(Ogre::SceneManager* scene_mgr) : scene_mgr_(scene_mgr) {}

    void initialize() {
        for (const auto& [code, contract] : Material::get_all_contracts()) {
            create_material(contract);
        }
    }

    Ogre::MaterialPtr get(uint16_t code) const {
        auto it = materials_.find(code);
        return it != materials_.end() ? it->second : Ogre::MaterialPtr();
    }

    void set_water_surface_fresnel(float power, float scale, float fresnel) {
        if (water_material_) {
            auto params = water_material_->getTechnique(0)->getPass(0)->getFragmentProgramParameters();
            if (params->_findNamedConstantDefinition("uFresnelPower")) {
                params->setNamedConstant("uFresnelPower", power);
            }
            if (params->_findNamedConstantDefinition("uFresnelScale")) {
                params->setNamedConstant("uFresnelScale", scale);
            }
            if (params->_findNamedConstantDefinition("uFresnelBias")) {
                params->setNamedConstant("uFresnelBias", fresnel);
            }
        }
    }

    void set_water_deep_color(float r, float g, float b) {
        if (water_material_) {
            auto params = water_material_->getTechnique(0)->getPass(0)->getFragmentProgramParameters();
            if (params->_findNamedConstantDefinition("uDeepColor")) {
                params->setNamedConstant("uDeepColor", Ogre::Vector3(r, g, b));
            }
        }
    }

    void set_water_shallow_color(float r, float g, float b) {
        if (water_material_) {
            auto params = water_material_->getTechnique(0)->getPass(0)->getFragmentProgramParameters();
            if (params->_findNamedConstantDefinition("uShallowColor")) {
                params->setNamedConstant("uShallowColor", Ogre::Vector3(r, g, b));
            }
        }
    }

    void set_water_normal_texture(const std::string& tex_name) {
        if (water_material_) {
            auto pass = water_material_->getTechnique(0)->getPass(0);
            auto tu = pass->getTextureUnitState(1);
            if (tu) {
                tu->setTextureName(tex_name);
            }
        }
    }

    void set_water_foam_threshold(float threshold) {
        if (water_material_) {
            auto params = water_material_->getTechnique(0)->getPass(0)->getFragmentProgramParameters();
            if (params->_findNamedConstantDefinition("uFoamThreshold")) {
                params->setNamedConstant("uFoamThreshold", threshold);
            }
        }
    }

private:
    Ogre::SceneManager* scene_mgr_;
    std::unordered_map<uint16_t, Ogre::MaterialPtr> materials_;
    Ogre::MaterialPtr water_material_;

    void create_material(const Material::MaterialContract& contract) {
        std::string mat_name = "voxel/" + contract.id;
        auto mat = Ogre::MaterialManager::getSingleton().create(
            mat_name, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);

        auto tech = mat->createTechnique();
        auto pass = tech->createPass();

        pass->setAmbient(Ogre::ColourValue(
            contract.albedo.r * 0.3f,
            contract.albedo.g * 0.3f,
            contract.albedo.b * 0.3f));
        pass->setDiffuse(Ogre::ColourValue(
            contract.albedo.r,
            contract.albedo.g,
            contract.albedo.b,
            contract.is_transparent ? 0.7f : 1.0f));

        if (contract.emission.r > 0.0f || contract.emission.g > 0.0f || contract.emission.b > 0.0f) {
            pass->setSelfIllumination(Ogre::ColourValue(
                contract.emission.r,
                contract.emission.g,
                contract.emission.b));
        }

        if (contract.is_transparent) {
            pass->setSceneBlending(Ogre::SBT_TRANSPARENT_ALPHA);
            pass->setDepthWriteEnabled(false);
        }

        if (contract.id == "water") {
            water_material_ = mat;
        }

        materials_[contract.code] = mat;
    }
};

} // namespace SCR::Material
