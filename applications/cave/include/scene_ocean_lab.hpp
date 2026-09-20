#ifndef CAVE_SCENE_OCEAN_LAB_HPP
#define CAVE_SCENE_OCEAN_LAB_HPP

#include <memory>
#include "simulation/simulation_framework.hpp"
#include "simulation_subjects.hpp"
#include "simulation/simulation_events.hpp"
#include "simulation/simulation_systems.hpp"
#include "simulation/player_controller.hpp"
#include "render/ogre/fog_subsystem.hpp"
#include "ocean_simulation.hpp"
#include "volumetric_clouds.hpp"
#include "procedural_island.hpp"

namespace SCR::Simulation {

class OceanPlayerSystem : public ISimulationSystem {
public:
    std::string getName() const override { return "OceanPlayerSystem"; }
    OceanPlayerSystem() {
        addSubSystem(std::make_shared<PlayerControllerSubSystem>());
    }
};

class OceanFogSystem : public ISimulationSystem {
public:
    std::string getName() const override { return "OceanFogSystem"; }
    OceanFogSystem() {
        addSubSystem(std::make_shared<FogSubSystem>());
    }
};

class OceanLabScene : public ISimulationScene {
public:
    SubjectRegistry subjects;
    EventBus events;
    ConcurrentSystemCoordinator coordinator;

    std::shared_ptr<PlayerSubject> player_subject;

    std::unique_ptr<Ocean::SeaOfThievesWater> ocean_system;
    std::unique_ptr<Sky::VolumetricAtmosphere> sky_system;
    std::unique_ptr<Island::VoxelIsland> dummy_island;

    Ogre::SceneNode* oceanNode = nullptr;
    Ogre::ManualObject* oceanMesh = nullptr;
    Ogre::SceneNode* skyNode = nullptr;
    Ogre::ManualObject* skyMesh = nullptr;
    Ogre::Light* sunLight = nullptr;
    Ogre::Camera* camera = nullptr;

    OceanLabScene()
        : coordinator(subjects, events) {
        player_subject = std::make_shared<PlayerSubject>();
        player_subject->position = Spatial::Point3D(0.0f, 14.0f, -45.0f);
        subjects.registerSubject(player_subject);

        coordinator.registerSystem(std::make_shared<OceanPlayerSystem>());
        coordinator.registerSystem(std::make_shared<OceanFogSystem>());
    }

    SceneMetadata getMetadata() const override {
        return {
            "ocean_lab",
            "Multi-Spectral Hydrodynamic Ocean Laboratory",
            "Sea of Thieves Multi-Harmonic Gerstner Wave Dynamics",
            "Fluid Dynamics & Optical Wave Optics",
            "Hydrodynamic laboratory simulating 6-octave trochoidal Gerstner swell superposition, wave crest Jacobian compression, Subsurface Scattering (SSS) optical depth radiance, and dynamic shoreline foam.",
            "SCR-DOM-005 (Physics/Fluid) & SCR-DOM-008 (Render/Optics)",
            "SCR Hydrodynamics Team",
            "3.0.0",
            {"Concurrent-Systems", "Gerstner-Waves", "SSS-Optics", "Jacobian-Foam", "Trochoidal-Swells", "Bathymetry"}
        };
    }

    void prepare(LoadingContext& ctx) override {
        ctx.update(0.15f, "Configuring Trochoidal Wave Spectra", "6-harmonic directional dispersion", "GERSTNER");
        dummy_island = std::make_unique<Island::VoxelIsland>(96, 32, 96);
        ocean_system = std::make_unique<Ocean::SeaOfThievesWater>(9.0f);

        ctx.update(0.55f, "Initializing SSS Optical Scattering Pipeline", "Multi-spectral RGB depth attenuation", "OPTICS");
        sky_system = std::make_unique<Sky::VolumetricAtmosphere>();

        coordinator.prepare(ctx);

        ctx.update(1.0f, "Hydrodynamic Rig Ready", "Streaming wave vertices to GPU", "GPU_STREAM");
    }

    void attachRenderer(RenderContext& ctx) override {
        auto* scnMgr = ctx.getSceneManager<Ogre::SceneManager>();
        auto* cam = ctx.getCamera<Ogre::Camera>();
        auto* win = ctx.getWindow<Ogre::RenderWindow>();

        camera = cam;
        cam->setNearClipDistance(Config::NEAR_CLIP);
        cam->setFarClipDistance(Config::FAR_CLIP_ISLAND);

        RenderContext renderCtx;
        renderCtx.native_scene_manager = scnMgr;
        renderCtx.native_camera = cam;
        renderCtx.native_window = win;
        coordinator.setRenderContext(renderCtx);
        coordinator.initialize();

        sunLight = scnMgr->createLight("OceanSun");
        sunLight->setType(Ogre::Light::LT_DIRECTIONAL);
        sunLight->setDiffuseColour(Ogre::ColourValue(1.f, .95f, .85f));
        auto* sunNode = scnMgr->getRootSceneNode()->createChildSceneNode("OceanSunNode");
        sunNode->setDirection(Ogre::Vector3(-.3f, -1.f, -.5f).normalisedCopy());
        sunNode->attachObject(sunLight);

        skyMesh = scnMgr->createManualObject("SkyMeshObj");
        skyMesh->setDynamic(true);
        skyMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_SKIES_EARLY);
        skyNode = scnMgr->getRootSceneNode()->createChildSceneNode("SkyNode");
        skyNode->attachObject(skyMesh);

        oceanMesh = scnMgr->createManualObject("OceanMeshObj");
        oceanMesh->setDynamic(true);
        oceanMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_6);
        oceanNode = scnMgr->getRootSceneNode()->createChildSceneNode("OceanNode");
        oceanNode->attachObject(oceanMesh);
    }

    void update(float dt, const UserInputState& input) override {
        coordinator.stepSimulation(dt, input);
        coordinator.renderPipeline(dt);

        Spatial::Point3D pos = player_subject->position;

        if (ocean_system && oceanMesh) {
            Spatial::Vector3D sun_dir(0.3f, 1.0f, 0.5f);
            ocean_system->updateOceanMesh(oceanMesh, dt, *dummy_island, pos, sun_dir.normalized());
        }
        if (sky_system && skyMesh) {
            sky_system->updateSkyDomeMesh(skyMesh, dt, *dummy_island, pos);
        }

        if (camera && camera->getParentSceneNode()) {
            camera->getParentSceneNode()->setPosition(pos.x, pos.y, pos.z);
            Ogre::Quaternion qYaw(Ogre::Radian(player_subject->yaw), Ogre::Vector3::UNIT_Y);
            Ogre::Quaternion qPitch(Ogre::Radian(player_subject->pitch), Ogre::Vector3::UNIT_X);
            camera->getParentSceneNode()->setOrientation(qYaw * qPitch);
        }
    }

    void renderPresentation(RenderContext& ctx, float screen_alpha = 1.0f) override {
        (void)ctx; (void)screen_alpha;
    }

    void detachRenderer(RenderContext& ctx) override {
        auto* scnMgr = ctx.getSceneManager<Ogre::SceneManager>();
        coordinator.cleanup(ctx);
        subjects.clear();
        events.clear();
        if (oceanMesh) { scnMgr->destroyManualObject(oceanMesh); oceanMesh = nullptr; }
        if (oceanNode) { scnMgr->destroySceneNode(oceanNode); oceanNode = nullptr; }
        if (skyMesh)   { scnMgr->destroyManualObject(skyMesh); skyMesh = nullptr; }
        if (skyNode)   { scnMgr->destroySceneNode(skyNode); skyNode = nullptr; }
        if (sunLight)  { scnMgr->destroyLight(sunLight); sunLight = nullptr; }
    }
};

} // namespace SCR::Simulation

#endif // CAVE_SCENE_OCEAN_LAB_HPP
