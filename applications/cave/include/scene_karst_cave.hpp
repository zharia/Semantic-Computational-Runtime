#ifndef CAVE_SCENE_KARST_CAVE_HPP
#define CAVE_SCENE_KARST_CAVE_HPP

#include <memory>
#include <sstream>

#include "simulation/simulation_framework.hpp"
#include "simulation_subjects.hpp"
#include "simulation/simulation_events.hpp"
#include "simulation/simulation_systems.hpp"
#include "simulation/player_controller.hpp"
#include "simulation/voxel_editing.hpp"
#include "render/ogre/material_setup.hpp"
#include "render/ogre/fog_subsystem.hpp"
#include "simulation/dynamic_chunk.hpp"
#include "procedural_cave.hpp"
#include "vdb_cave_mesher.hpp"

namespace SCR::Simulation {

// ── Cave-specific composite systems wrapping subsystems ─────────────────────

class PlayerControllerSystem : public ISimulationSystem {
public:
    std::string getName() const override { return "PlayerControllerSystem"; }

    PlayerControllerSystem() {
        addSubSystem(std::make_shared<PlayerControllerSubSystem>());
    }
};

class VoxelEditSystem : public ISimulationSystem {
public:
    std::string getName() const override { return "VoxelEditSystem"; }

    VoxelEditSystem() {
        addSubSystem(std::make_shared<VoxelEditingSubSystem>());
    }
};

class MaterialSystem : public ISimulationSystem {
public:
    std::string getName() const override { return "MaterialSystem"; }

    MaterialSystem() {
        addSubSystem(std::make_shared<MaterialSetupSubSystem>());
    }
};

class FogSystem : public ISimulationSystem {
public:
    std::string getName() const override { return "FogSystem"; }

    FogSystem() {
        addSubSystem(std::make_shared<FogSubSystem>());
    }
};

// ── Karst Cave Scene ────────────────────────────────────────────────────────

class KarstCaveScene : public ISimulationScene {
public:
    // Core Infrastructure
    SubjectRegistry subjects;
    EventBus events;
    ConcurrentSystemCoordinator coordinator;

    // Subjects
    std::shared_ptr<PlayerSubject> player_subject;

    // Cave Domain
    std::unique_ptr<Cave::VoxelCave> cave;

    // Ogre Handles (cave mesh + headlamp managed manually)
    Ogre::SceneNode* caveNode = nullptr;
    Ogre::ManualObject* caveMesh = nullptr;
    Ogre::Light* headlamp = nullptr;
    Ogre::Light* ambientLight = nullptr;
    Ogre::Camera* camera = nullptr;

    KarstCaveScene()
        : coordinator(subjects, events) {
        // Instantiate Subject Objects
        player_subject = std::make_shared<PlayerSubject>();

        // Register Subjects
        subjects.registerSubject(player_subject);

        // Register Systems
        coordinator.registerSystem(std::make_shared<PlayerControllerSystem>());
        coordinator.registerSystem(std::make_shared<VoxelEditSystem>());
        coordinator.registerSystem(std::make_shared<MaterialSystem>());
        coordinator.registerSystem(std::make_shared<FogSystem>());
        coordinator.registerSystem(std::make_shared<DynamicChunkSystem>());
    }

    SceneMetadata getMetadata() const override {
        return {
            "karst_cave",
            "Subterranean Karst Cave & Speleothem Explorer",
            "Procedural 3D Wormhole Cavities & Marching Cubes",
            "Speleology & Subsurface Topology",
            "Procedural subterranean limestone cave network featuring interconnected chambers, stalactite/stalagmite speleothems, underground water tables, and dynamic headlamp illumination.",
            "SCR-DOM-003 (Topology/Cavity) & SCR-DOM-008 (Render/Lighting)",
            "SCR Core Architecture Team",
            "3.1.0",
            {"Concurrent-Systems", "Subject-Objects", "Event-Bus", "Marching-Cubes", "Speleothems", "Subterranean", "Bioluminescence", "Volumetric-Light"}
        };
    }

    void prepare(LoadingContext& ctx) override {
        ctx.update(0.10f, "Ingesting Speleological Material Catalog", "Limestone, Speleothem, Quartz, Water", "MATERIALS");
        (void)Material::MaterialRegistry::instance();

        ctx.update(0.35f, "Carving 3D Procedural Wormhole Cavities", "64x32x64 3D voxel lattice", "CAVE_CARVER");
        cave = std::make_unique<Cave::VoxelCave>(64, 32, 64, 1.0f);
        cave->generateProceduralCave(2026);

        ctx.update(0.70f, "Generating Stalactites & Stalagmite Speleothems", "Dripstone accretion algorithms", "SPELEOTHEMS");

        // Locate viable player spawn within an open chamber
        for (int y = 14; y < 24; ++y) {
            if (!cave->isSolid(32, y, 32) && !cave->isSolid(32, y + 1, 32)) {
                player_subject->position = Spatial::Point3D(32.5f, (float)y, 32.5f);
                player_subject->smooth_eye_y = (float)y + player_subject->eye_height;
                break;
            }
        }

        ctx.update(1.0f, "Subterranean Network Ready", "Committing isosurface geometry", "GPU_STREAM");
    }

    void attachRenderer(RenderContext& ctx) override {
        auto* scnMgr = ctx.getSceneManager<Ogre::SceneManager>();
        auto* cam = ctx.getCamera<Ogre::Camera>();
        auto* win = ctx.getWindow<Ogre::RenderWindow>();

        camera = cam;
        cam->setNearClipDistance(Config::NEAR_CLIP);
        cam->setFarClipDistance(Config::FAR_CLIP_CAVE);

        scnMgr->setAmbientLight(Ogre::ColourValue(0.02f, 0.03f, 0.05f));

        // Initialize coordinator with Ogre context and systems
        RenderContext renderCtx;
        renderCtx.native_scene_manager = scnMgr;
        renderCtx.native_camera = cam;
        renderCtx.native_window = win;
        coordinator.setRenderContext(renderCtx);
        coordinator.initialize();

        // Player Headlamp (Spotlight)
        headlamp = scnMgr->createLight("CaveHeadlamp");
        headlamp->setType(Ogre::Light::LT_SPOTLIGHT);
        headlamp->setDiffuseColour(Ogre::ColourValue(1.0f, 0.92f, 0.82f));
        headlamp->setSpecularColour(Ogre::ColourValue(1.0f, 1.0f, 1.0f));
        headlamp->setSpotlightRange(Ogre::Degree(32), Ogre::Degree(65));
        headlamp->setAttenuation(45.0f, 1.0f, 0.08f, 0.03f);

        if (cam->getParentSceneNode()) {
            cam->getParentSceneNode()->attachObject(headlamp);
        }

        // Cave Isosurface Mesh
        caveMesh = scnMgr->createManualObject("CaveMeshObj");
        caveMesh->setDynamic(true);
        VDB::VdbCaveMesher::buildNaturalCaveMesh(caveMesh, *cave, 0.0f, 0.02f);
        caveNode = scnMgr->getRootSceneNode()->createChildSceneNode("CaveNode");
        caveNode->attachObject(caveMesh);
    }

    void update(float dt, const UserInputState& input) override {
        coordinator.stepSimulation(dt, input);
        coordinator.renderPipeline(dt);
    }

    void renderPresentation(RenderContext& ctx, float screen_alpha = 1.0f) override {
        (void)ctx;
        (void)screen_alpha;
    }

    void detachRenderer(RenderContext& ctx) override {
        auto* scnMgr = ctx.getSceneManager<Ogre::SceneManager>();
        coordinator.cleanup(ctx);
        subjects.clear();
        events.clear();

        if (caveMesh) { scnMgr->destroyManualObject(caveMesh); caveMesh = nullptr; }
        if (caveNode) { scnMgr->destroySceneNode(caveNode); caveNode = nullptr; }
        if (headlamp) { scnMgr->destroyLight(headlamp); headlamp = nullptr; }
    }
};

} // namespace SCR::Simulation

#endif // CAVE_SCENE_KARST_CAVE_HPP
