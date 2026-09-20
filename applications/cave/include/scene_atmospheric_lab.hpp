#ifndef CAVE_SCENE_ATMOSPHERIC_LAB_HPP
#define CAVE_SCENE_ATMOSPHERIC_LAB_HPP

#include <memory>
#include "simulation/simulation_framework.hpp"
#include "simulation_subjects.hpp"
#include "simulation/simulation_events.hpp"
#include "simulation/simulation_systems.hpp"
#include "simulation/player_controller.hpp"
#include "render/ogre/fog_subsystem.hpp"
#include "volumetric_clouds.hpp"
#include "procedural_island.hpp"

namespace SCR::Simulation {

class AtmosphericPlayerSystem : public ISimulationSystem {
public:
    std::string getName() const override { return "AtmosphericPlayerSystem"; }

    AtmosphericPlayerSystem() {
        addSubSystem(std::make_shared<PlayerControllerSubSystem>());
    }
};

class AtmosphericFogSystem : public ISimulationSystem {
public:
    std::string getName() const override { return "AtmosphericFogSystem"; }

    AtmosphericFogSystem() {
        addSubSystem(std::make_shared<FogSubSystem>());
    }
};

/**
 * AtmosphericLabScene — Refactored to Modular Concurrent Systems.
 * Subjects: PlayerSubject, AtmosphereSubject.
 * Systems: AtmosphericPlayerSystem, AtmosphericFogSystem.
 * Concurrency: ConcurrentSystemCoordinator dispatches async steps on worker threads.
 */
class AtmosphericLabScene : public ISimulationScene {
public:
    // Core Infrastructure
    SubjectRegistry subjects;
    EventBus events;
    ConcurrentSystemCoordinator coordinator;

    // Subjects
    std::shared_ptr<PlayerSubject> player_subject;
    std::shared_ptr<AtmosphereSubject> atmo_subject;

    // Scene Objects
    std::unique_ptr<Sky::VolumetricAtmosphere> sky_system;
    std::unique_ptr<Island::VoxelIsland> dummy_island;

    Ogre::SceneNode* skyNode = nullptr;
    Ogre::ManualObject* skyMesh = nullptr;
    Ogre::Light* sunLight = nullptr;
    Ogre::Camera* camera = nullptr;

    AtmosphericLabScene()
        : coordinator(subjects, events) {
        // Instantiate Subject Objects
        player_subject = std::make_shared<PlayerSubject>();
        atmo_subject = std::make_shared<AtmosphereSubject>();

        // Register Subjects in SubjectRegistry
        subjects.registerSubject(player_subject);
        subjects.registerSubject(atmo_subject);

        // Register Systems in ConcurrentSystemCoordinator
        coordinator.registerSystem(std::make_shared<AtmosphericPlayerSystem>());
        coordinator.registerSystem(std::make_shared<AtmosphericFogSystem>());
    }

    SceneMetadata getMetadata() const override {
        return {
            "atmospheric_lab",
            "RDR2 Multi-Tier Volumetric Atmosphere Laboratory",
            "Multi-Layer Rayleigh/Mie Scattering & Cloud Dynamics",
            "Atmospheric Physics & Optical Meteorology",
            "Multi-layer Rayleigh molecular scattering, Mie aerosol dispersion, planetary solar arcs, and 3-tier volumetric cumulus/cirrus cloud dynamics via concurrent Systems and Sub-Systems.",
            "SCR-DOM-005 (Physics/Atmosphere) & SCR-DOM-008 (Render/Sky)",
            "SCR Celestial Dynamics Team",
            "2.0.0",
            {"Concurrent-Systems", "Subject-Objects", "Event-Bus", "RDR2-Sky", "Rayleigh-Scattering", "Mie-Scattering", "Cumulus-Congestus", "Solar-Orbit"}
        };
    }

    void prepare(LoadingContext& ctx) override {
        ctx.update(0.20f, "Computing Rayleigh & Mie Phase Scattering Functions", "Wavelength-dependent atmospheric transmittance", "ATMOSPHERE");
        dummy_island = std::make_unique<Island::VoxelIsland>(96, 32, 96);

        ctx.update(0.60f, "Synthesizing 3-Tier Multi-Octave Cloud Strata", "Low Cumulus (800m), Congestus (1800m), High Cirrus (5000m)", "CLOUDS");
        sky_system = std::make_unique<Sky::VolumetricAtmosphere>();

        ctx.update(1.0f, "Celestial Skybox Calibrated", "Binding 2400m geodesic celestial dome", "GPU_STREAM");
    }

    void attachRenderer(RenderContext& ctx) override {
        auto* scnMgr = ctx.getSceneManager<Ogre::SceneManager>();
        auto* cam = ctx.getCamera<Ogre::Camera>();
        auto* win = ctx.getWindow<Ogre::RenderWindow>();

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
        sky_system->updateSkyDomeMesh(skyMesh, 0.0f, *dummy_island, player_subject->position);
        skyNode = scnMgr->getRootSceneNode()->createChildSceneNode("SkyNode");
        skyNode->attachObject(skyMesh);

        RenderContext renderCtx;
        renderCtx.native_scene_manager = scnMgr;
        renderCtx.native_camera = cam;
        renderCtx.native_window = win;
        coordinator.setRenderContext(renderCtx);
        coordinator.initialize();
    }

    void update(float dt, const UserInputState& input) override {
        // Execute concurrent simulation tick
        coordinator.stepSimulation(dt, input);

        // Render synchronization pipeline
        coordinator.renderPipeline(dt);

        // Update sky dome mesh
        if (sky_system && skyMesh && player_subject) {
            sky_system->updateSkyDomeMesh(skyMesh, dt, *dummy_island, player_subject->position);
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

        if (skyMesh)  { scnMgr->destroyManualObject(skyMesh); skyMesh = nullptr; }
        if (skyNode)  { scnMgr->destroySceneNode(skyNode); skyNode = nullptr; }
        if (sunLight) { scnMgr->destroyLight(sunLight); sunLight = nullptr; }
    }
};

} // namespace SCR::Simulation

#endif // CAVE_SCENE_ATMOSPHERIC_LAB_HPP
