#ifndef CAVE_SCENE_OCEAN_LAB_HPP
#define CAVE_SCENE_OCEAN_LAB_HPP

#include <memory>
#include "simulation_framework.hpp"
#include "ocean_simulation.hpp"
#include "volumetric_clouds.hpp"
#include "procedural_island.hpp"

namespace SCR::Simulation {

class OceanLabScene : public ISimulationScene {
public:
    std::unique_ptr<Ocean::SeaOfThievesWater> ocean_system;
    std::unique_ptr<Sky::VolumetricAtmosphere> sky_system;
    std::unique_ptr<Island::VoxelIsland> dummy_island;

    Spatial::Point3D player_pos{0.0f, 14.0f, -45.0f};
    float player_yaw = 0.0f;
    float player_pitch = -0.15f;

    Ogre::SceneNode* oceanNode = nullptr;
    Ogre::ManualObject* oceanMesh = nullptr;
    Ogre::SceneNode* skyNode = nullptr;
    Ogre::ManualObject* skyMesh = nullptr;
    Ogre::Light* sunLight = nullptr;
    Ogre::Camera* camera = nullptr;

    OceanLabScene() = default;

    SceneMetadata getMetadata() const override {
        return {
            "ocean_lab",
            "Multi-Spectral Hydrodynamic Ocean Laboratory",
            "Sea of Thieves Multi-Harmonic Gerstner Wave Dynamics",
            "Fluid Dynamics & Optical Wave Optics",
            "Hydrodynamic laboratory simulating 6-octave trochoidal Gerstner swell superposition, wave crest Jacobian compression, Subsurface Scattering (SSS) optical depth radiance, and dynamic shoreline foam.",
            "SCR-DOM-005 (Physics/Fluid) & SCR-DOM-008 (Render/Optics)",
            "SCR Hydrodynamics Team",
            "2.4.0",
            {"Gerstner-Waves", "SSS-Optics", "Jacobian-Foam", "Trochoidal-Swells", "Bathymetry"}
        };
    }

    void prepare(LoadingContext& ctx) override {
        ctx.update(0.15f, "Configuring Trochoidal Wave Spectra", "6-harmonic directional dispersion", "GERSTNER");
        dummy_island = std::make_unique<Island::VoxelIsland>(96, 32, 96);
        ocean_system = std::make_unique<Ocean::SeaOfThievesWater>(9.0f);

        ctx.update(0.55f, "Initializing SSS Optical Scattering Pipeline", "Multi-spectral RGB depth attenuation", "OPTICS");
        sky_system = std::make_unique<Sky::VolumetricAtmosphere>();

        ctx.update(1.0f, "Hydrodynamic Rig Ready", "Streaming wave vertices to GPU", "GPU_STREAM");
    }

    void initScene(Ogre::SceneManager* scnMgr, Ogre::Camera* cam, Ogre::RenderWindow* win) override {
        (void)win;
        camera = cam;
        cam->setNearClipDistance(0.05f);
        cam->setFarClipDistance(12000.0f);

        sunLight = scnMgr->createLight("OceanSun");
        sunLight->setType(Ogre::Light::LT_DIRECTIONAL);
        sunLight->setDiffuseColour(Ogre::ColourValue(1.f, .95f, .85f));
        auto* sunNode = scnMgr->getRootSceneNode()->createChildSceneNode("OceanSunNode");
        sunNode->setDirection(Ogre::Vector3(-.3f, -1.f, -.5f).normalisedCopy());
        sunNode->attachObject(sunLight);

        skyMesh = scnMgr->createManualObject("SkyMeshObj");
        skyMesh->setDynamic(true);
        skyMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_SKIES_EARLY);
        sky_system->updateSkyDomeMesh(skyMesh, 0.0f, *dummy_island, player_pos);
        skyNode = scnMgr->getRootSceneNode()->createChildSceneNode("SkyNode");
        skyNode->attachObject(skyMesh);

        oceanMesh = scnMgr->createManualObject("OceanMeshObj");
        oceanMesh->setDynamic(true);
        oceanMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_6);
        Spatial::Vector3D sun_dir(0.3f, 1.0f, 0.5f);
        ocean_system->updateOceanMesh(oceanMesh, 0.0f, *dummy_island, player_pos, sun_dir.normalized());
        oceanNode = scnMgr->getRootSceneNode()->createChildSceneNode("OceanNode");
        oceanNode->attachObject(oceanMesh);
    }

    void update(float dt, const UserInputState& input) override {
        player_yaw   += input.mouse_dx;
        player_pitch += input.mouse_dy;

        Spatial::Vector3D fwd(-std::sin(player_yaw), 0, -std::cos(player_yaw));
        Spatial::Vector3D right(std::cos(player_yaw), 0, -std::sin(player_yaw));
        Spatial::Vector3D mv(0, 0, 0);

        if (input.move_forward)  mv += fwd;
        if (input.move_backward) mv -= fwd;
        if (input.move_right)    mv += right;
        if (input.move_left)     mv -= right;
        if (input.move_up)       mv += Spatial::Vector3D(0, 1, 0);
        if (input.move_down)     mv -= Spatial::Vector3D(0, 1, 0);

        float spd = input.sprint ? 18.0f : 8.0f;
        if (mv.lengthSq() > 1e-4f) {
            player_pos += mv.normalized() * (spd * dt);
        }

        if (camera && camera->getParentSceneNode()) {
            camera->getParentSceneNode()->setPosition(player_pos.x, player_pos.y, player_pos.z);
            Ogre::Quaternion qYaw(Ogre::Radian(player_yaw), Ogre::Vector3::UNIT_Y);
            Ogre::Quaternion qPitch(Ogre::Radian(player_pitch), Ogre::Vector3::UNIT_X);
            camera->getParentSceneNode()->setOrientation(qYaw * qPitch);
        }

        if (ocean_system && oceanMesh) {
            Spatial::Vector3D sun_dir(0.3f, 1.0f, 0.5f);
            ocean_system->updateOceanMesh(oceanMesh, dt, *dummy_island, player_pos, sun_dir.normalized());
        }
        if (sky_system && skyMesh) {
            sky_system->updateSkyDomeMesh(skyMesh, dt, *dummy_island, player_pos);
        }
    }

    void renderHUD(Ogre::ManualObject* hudObj, Ogre::Viewport* vp, float screen_alpha = 1.0f) override {
        (void)hudObj; (void)vp; (void)screen_alpha;
    }

    void cleanup(Ogre::SceneManager* scnMgr) override {
        if (oceanMesh) { scnMgr->destroyManualObject(oceanMesh); oceanMesh = nullptr; }
        if (oceanNode) { scnMgr->destroySceneNode(oceanNode); oceanNode = nullptr; }
        if (skyMesh)   { scnMgr->destroyManualObject(skyMesh); skyMesh = nullptr; }
        if (skyNode)   { scnMgr->destroySceneNode(skyNode); skyNode = nullptr; }
        if (sunLight)  { scnMgr->destroyLight(sunLight); sunLight = nullptr; }
    }
};

} // namespace SCR::Simulation

#endif // CAVE_SCENE_OCEAN_LAB_HPP
