#ifndef CAVE_SCENE_ATMOSPHERIC_LAB_HPP
#define CAVE_SCENE_ATMOSPHERIC_LAB_HPP

#include <memory>
#include "simulation_framework.hpp"
#include "volumetric_clouds.hpp"
#include "procedural_island.hpp"

namespace SCR::Simulation {

class AtmosphericLabScene : public ISimulationScene {
public:
    std::unique_ptr<Sky::VolumetricAtmosphere> sky_system;
    std::unique_ptr<Island::VoxelIsland> dummy_island;

    Spatial::Point3D player_pos{0.0f, 25.0f, 0.0f};
    float player_yaw = 0.0f;
    float player_pitch = 0.35f;

    Ogre::SceneNode* skyNode = nullptr;
    Ogre::ManualObject* skyMesh = nullptr;
    Ogre::Light* sunLight = nullptr;
    Ogre::Camera* camera = nullptr;

    AtmosphericLabScene() = default;

    SceneMetadata getMetadata() const override {
        return {
            "atmospheric_lab",
            "RDR2 Multi-Tier Volumetric Atmosphere Laboratory",
            "Multi-Layer Rayleigh/Mie Scattering & Cloud Dynamics",
            "Atmospheric Physics & Optical Meteorology",
            "Meteorological laboratory implementing multi-layer Rayleigh molecular scattering, Mie aerosol dispersion, planetary solar arcs, and 3-tier volumetric cumulus/cirrus cloud dynamics inspired by Red Dead Redemption 2.",
            "SCR-DOM-005 (Physics/Atmosphere) & SCR-DOM-008 (Render/Sky)",
            "SCR Celestial Dynamics Team",
            "1.8.0",
            {"RDR2-Sky", "Rayleigh-Scattering", "Mie-Scattering", "Cumulus-Congestus", "Solar-Orbit"}
        };
    }

    void prepare(LoadingContext& ctx) override {
        ctx.update(0.20f, "Computing Rayleigh & Mie Phase Scattering Functions", "Wavelength-dependent atmospheric transmittance", "ATMOSPHERE");
        dummy_island = std::make_unique<Island::VoxelIsland>(96, 32, 96);

        ctx.update(0.60f, "Synthesizing 3-Tier Multi-Octave Cloud Strata", "Low Cumulus (800m), Congestus (1800m), High Cirrus (5000m)", "CLOUDS");
        sky_system = std::make_unique<Sky::VolumetricAtmosphere>();

        ctx.update(1.0f, "Celestial Skybox Calibrated", "Binding 2400m geodesic celestial dome", "GPU_STREAM");
    }

    void initScene(Ogre::SceneManager* scnMgr, Ogre::Camera* cam, Ogre::RenderWindow* win) override {
        (void)win;
        camera = cam;
        cam->setNearClipDistance(0.05f);
        cam->setFarClipDistance(12000.0f);

        sunLight = scnMgr->createLight("CelestialSun");
        sunLight->setType(Ogre::Light::LT_DIRECTIONAL);
        sunLight->setDiffuseColour(Ogre::ColourValue(1.f, .92f, .80f));
        auto* sunNode = scnMgr->getRootSceneNode()->createChildSceneNode("CelestialSunNode");
        sunNode->setDirection(Ogre::Vector3(-.4f, -1.f, -.6f).normalisedCopy());
        sunNode->attachObject(sunLight);

        skyMesh = scnMgr->createManualObject("SkyMeshObj");
        skyMesh->setDynamic(true);
        skyMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_SKIES_EARLY);
        sky_system->updateSkyDomeMesh(skyMesh, 0.0f, *dummy_island, player_pos);
        skyNode = scnMgr->getRootSceneNode()->createChildSceneNode("SkyNode");
        skyNode->attachObject(skyMesh);
    }

    void update(float dt, const UserInputState& input) override {
        player_yaw   += input.mouse_dx;
        player_pitch += input.mouse_dy;
        player_pitch  = std::max(-1.48f, std::min(1.48f, player_pitch));

        Spatial::Vector3D fwd(-std::sin(player_yaw), 0, -std::cos(player_yaw));
        Spatial::Vector3D right(std::cos(player_yaw), 0, -std::sin(player_yaw));
        Spatial::Vector3D mv(0, 0, 0);

        if (input.move_forward)  mv += fwd;
        if (input.move_backward) mv -= fwd;
        if (input.move_right)    mv += right;
        if (input.move_left)     mv -= right;
        if (input.move_up)       mv += Spatial::Vector3D(0, 1, 0);
        if (input.move_down)     mv -= Spatial::Vector3D(0, 1, 0);

        float spd = input.sprint ? 24.0f : 10.0f;
        if (mv.lengthSq() > 1e-4f) {
            player_pos += mv.normalized() * (spd * dt);
        }

        if (camera && camera->getParentSceneNode()) {
            camera->getParentSceneNode()->setPosition(player_pos.x, player_pos.y, player_pos.z);
            Ogre::Quaternion qYaw(Ogre::Radian(player_yaw), Ogre::Vector3::UNIT_Y);
            Ogre::Quaternion qPitch(Ogre::Radian(player_pitch), Ogre::Vector3::UNIT_X);
            camera->getParentSceneNode()->setOrientation(qYaw * qPitch);
        }

        if (sky_system && skyMesh) {
            sky_system->updateSkyDomeMesh(skyMesh, dt, *dummy_island, player_pos);
        }
    }

    void renderHUD(Ogre::ManualObject* hudObj, Ogre::Viewport* vp, float screen_alpha = 1.0f) override {
        (void)hudObj; (void)vp; (void)screen_alpha;
    }

    void cleanup(Ogre::SceneManager* scnMgr) override {
        if (skyMesh)  { scnMgr->destroyManualObject(skyMesh); skyMesh = nullptr; }
        if (skyNode)  { scnMgr->destroySceneNode(skyNode); skyNode = nullptr; }
        if (sunLight) { scnMgr->destroyLight(sunLight); sunLight = nullptr; }
    }
};

} // namespace SCR::Simulation

#endif // CAVE_SCENE_ATMOSPHERIC_LAB_HPP
