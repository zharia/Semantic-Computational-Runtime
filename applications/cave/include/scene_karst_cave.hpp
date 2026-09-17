#ifndef CAVE_SCENE_KARST_CAVE_HPP
#define CAVE_SCENE_KARST_CAVE_HPP

#include <memory>
#include <sstream>

#include "simulation_framework.hpp"
#include "procedural_cave.hpp"
#include "vdb_cave_mesher.hpp"
#include "fps_controller.hpp"

namespace SCR::Simulation {

class KarstCaveScene : public ISimulationScene {
public:
    std::unique_ptr<Cave::VoxelCave> cave;

    Spatial::Point3D player_pos{32.0f, 16.0f, 32.0f};
    Spatial::Vector3D player_vel{0,0,0};
    float player_yaw = 0.0f;
    float player_pitch = 0.0f;
    float walk_speed = 4.5f;
    float sprint_speed = 8.5f;

    Ogre::SceneNode* caveNode = nullptr;
    Ogre::ManualObject* caveMesh = nullptr;
    Ogre::Light* headlamp = nullptr;
    Ogre::Light* ambientLight = nullptr;
    Ogre::Camera* camera = nullptr;

    KarstCaveScene() = default;

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
            {"Marching-Cubes", "Speleothems", "Subterranean", "Bioluminescence", "Volumetric-Light"}
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
                player_pos = Spatial::Point3D(32.5f, (float)y, 32.5f);
                break;
            }
        }

        ctx.update(1.0f, "Subterranean Network Ready", "Committing isosurface geometry", "GPU_STREAM");
    }

    void initScene(Ogre::SceneManager* scnMgr, Ogre::Camera* cam, Ogre::RenderWindow* win) override {
        (void)win;
        camera = cam;
        cam->setNearClipDistance(0.05f);
        cam->setFarClipDistance(300.0f);

        scnMgr->setAmbientLight(Ogre::ColourValue(0.02f, 0.03f, 0.05f));

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
        player_yaw   += input.mouse_dx;
        player_pitch += input.mouse_dy;
        player_pitch  = std::max(-1.45f, std::min(1.45f, player_pitch));

        Spatial::Vector3D fwd(-std::sin(player_yaw), 0, -std::cos(player_yaw));
        Spatial::Vector3D right(std::cos(player_yaw), 0, -std::sin(player_yaw));
        Spatial::Vector3D mv(0, 0, 0);

        if (input.move_forward)  mv += fwd;
        if (input.move_backward) mv -= fwd;
        if (input.move_right)    mv += right;
        if (input.move_left)     mv -= right;
        if (input.move_up)       mv += Spatial::Vector3D(0, 1, 0);
        if (input.move_down)     mv -= Spatial::Vector3D(0, 1, 0);

        float spd = input.sprint ? sprint_speed : walk_speed;
        if (mv.lengthSq() > 1e-4f) {
            mv = mv.normalized() * spd;
            player_pos.x += mv.x * dt;
            player_pos.y += mv.y * dt;
            player_pos.z += mv.z * dt;
        }

        if (camera && camera->getParentSceneNode()) {
            camera->getParentSceneNode()->setPosition(player_pos.x, player_pos.y + 1.5f, player_pos.z);
            Ogre::Quaternion qYaw(Ogre::Radian(player_yaw), Ogre::Vector3::UNIT_Y);
            Ogre::Quaternion qPitch(Ogre::Radian(player_pitch), Ogre::Vector3::UNIT_X);
            camera->getParentSceneNode()->setOrientation(qYaw * qPitch);
        }
    }

    void renderHUD(Ogre::ManualObject* hudObj, Ogre::Viewport* vp, float screen_alpha = 1.0f) override {
        (void)hudObj;
        (void)vp;
        (void)screen_alpha;
    }

    void cleanup(Ogre::SceneManager* scnMgr) override {
        if (caveMesh) { scnMgr->destroyManualObject(caveMesh); caveMesh = nullptr; }
        if (caveNode) { scnMgr->destroySceneNode(caveNode); caveNode = nullptr; }
        if (headlamp) { scnMgr->destroyLight(headlamp); headlamp = nullptr; }
    }
};

} // namespace SCR::Simulation

#endif // CAVE_SCENE_KARST_CAVE_HPP
