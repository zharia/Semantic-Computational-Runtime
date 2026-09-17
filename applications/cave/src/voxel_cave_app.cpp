#include <Ogre.h>
#include <OgreApplicationContext.h>
#include <OgreInput.h>
#include <OgreRTShaderSystem.h>

#include "../include/spatial_semantics.hpp"
#include "../include/semantic_materials.hpp"
#include "../include/procedural_cave.hpp"
#include "../include/fps_controller.hpp"
#include "../include/vdb_cave_mesher.hpp"

#include <iostream>
#include <iomanip>
#include <memory>
#include <chrono>

using namespace Ogre;
using namespace OgreBites;

enum MeshMode {
    MESH_SMOOTH_OPENVDB = 0,
    MESH_VOXEL_BLOCKS = 1
};

class VoxelCaveApp : public ApplicationContext, public InputListener {
private:
    std::unique_ptr<SCR::Cave::VoxelCave> cave;
    std::unique_ptr<SCR::Controller::FPSController> player;

    SceneManager* scnMgr = nullptr;
    Camera* cam = nullptr;
    SceneNode* camNode = nullptr;
    Light* headlamp = nullptr;
    ManualObject* caveManualObj = nullptr;
    SceneNode* caveNode = nullptr;

    // Movement & Interaction Key States
    bool key_w = false;
    bool key_s = false;
    bool key_a = false;
    bool key_d = false;
    bool key_space = false;
    bool key_shift = false;

    // Mesh representation mode
    MeshMode current_mesh_mode = MESH_SMOOTH_OPENVDB;

    // Active material selected for placement (Hotbar)
    uint16_t active_place_material = SCR::Material::MAT_GRANITE;

    // HUD and metrics
    float hud_timer = 0.0f;
    int frame_count = 0;
    float fps_accum = 0.0f;

public:
    VoxelCaveApp() : ApplicationContext("SCR_VoxelCaveExplorer") {}

    NativeWindowPair createWindow(const String& name, uint32_t w = 0, uint32_t h = 0, NameValuePairList miscParams = NameValuePairList()) override {
        uint32_t target_w = (w > 0) ? w : 1600;
        uint32_t target_h = (h > 0) ? h : 900;
        miscParams["title"] = "SCR Voxel Cave Explorer (OpenVDB + OGRE 3D)";
        return ApplicationContext::createWindow(name, target_w, target_h, miscParams);
    }

    void setup() override {
        ApplicationContext::setup();
        addInputListener(this);

        if (getRenderWindow()) {
            getRenderWindow()->resize(1600, 900);
        }

        Root* root = getRoot();
        scnMgr = root->createSceneManager();

        // Register SceneManager with RTShaderSystem
        auto* shadergen = RTShader::ShaderGenerator::getSingletonPtr();
        if (shadergen) {
            shadergen->addSceneManager(scnMgr);
        }

        // 1. Configure Lighting Environment & Ambient Cavern Atmosphere
        scnMgr->setAmbientLight(ColourValue(0.18f, 0.20f, 0.26f));
        scnMgr->setFog(FOG_EXP2, ColourValue(0.04f, 0.04f, 0.06f), 0.035f);

        // 2. Procedural Cave Generation using Semantic Materials
        std::cout << "\n================================================================================" << std::endl;
        std::cout << " SCR Voxel Cave Explorer — OpenVDB Natural Isosurface & Spatial Semantics" << std::endl;
        std::cout << "================================================================================" << std::endl;
        
        cave = std::make_unique<SCR::Cave::VoxelCave>(48, 24, 48);
        std::cout << "Generating procedural subterranean cave (" 
                  << cave->dim_x << "x" << cave->dim_y << "x" << cave->dim_z 
                  << " = " << (cave->dim_x * cave->dim_y * cave->dim_z) << " voxels)..." << std::endl;
        cave->generateProceduralCave(1337);

        // 3. Find Spawn Position & Setup FPS Controller
        auto spawn_pos = cave->findSpawnPosition();
        player = std::make_unique<SCR::Controller::FPSController>(spawn_pos);
        std::cout << "Player spawned at: (" << spawn_pos.x << ", " << spawn_pos.y << ", " << spawn_pos.z << ")" << std::endl;

        // 4. Create Camera and Attach to Player
        cam = scnMgr->createCamera("PlayerCam");
        cam->setNearClipDistance(0.1f);
        cam->setFarClipDistance(500.0f);
        cam->setAutoAspectRatio(true);

        camNode = scnMgr->getRootSceneNode()->createChildSceneNode("PlayerCamNode");
        camNode->attachObject(cam);
        updateCameraPose();

        auto* vp = getRenderWindow()->addViewport(cam);
        vp->setBackgroundColour(ColourValue(0.04f, 0.04f, 0.06f));

        // 5. Dynamic Flashlight / Headlamp attached to Player Camera
        headlamp = scnMgr->createLight("PlayerHeadlamp");
        headlamp->setType(Light::LT_SPOTLIGHT);
        headlamp->setDiffuseColour(ColourValue(1.0f, 0.95f, 0.85f));
        headlamp->setSpecularColour(ColourValue(1.0f, 1.0f, 1.0f));
        headlamp->setSpotlightRange(Degree(25), Degree(50));
        headlamp->setAttenuation(45.0f, 1.0f, 0.09f, 0.032f);
        camNode->attachObject(headlamp);

        // 6. Volcanic Magma Chamber Lighting
        auto* lavaLight = scnMgr->createLight("LavaGlow");
        lavaLight->setType(Light::LT_POINT);
        lavaLight->setDiffuseColour(ColourValue(1.0f, 0.35f, 0.05f));
        lavaLight->setSpecularColour(ColourValue(1.0f, 0.20f, 0.0f));
        lavaLight->setAttenuation(30.0f, 1.0f, 0.14f, 0.07f);
        auto* lavaNode = scnMgr->getRootSceneNode()->createChildSceneNode("LavaLightNode");
        lavaNode->setPosition(11.0f, 3.5f, 11.0f);
        lavaNode->attachObject(lavaLight);

        // 7. Setup Materials in OGRE Material Manager
        setupMaterials();

        // 8. Build Cave Mesh (Default: OpenVDB Natural Smooth Isosurface)
        rebuildCaveMesh();

        // 9. Capture Mouse Pointer for FPS controls
        setWindowGrab(true);

        std::cout << "\n[Controls]:" << std::endl;
        std::cout << "  - WASD        : Move forward / backward / strafe" << std::endl;
        std::cout << "  - Mouse       : 3D Look (Yaw / Pitch)" << std::endl;
        std::cout << "  - SPACE       : Jump / Swim upwards in water" << std::endl;
        std::cout << "  - LSHIFT      : Sprint" << std::endl;
        std::cout << "  - Left Click  : Mine / Excavate targeted voxel" << std::endl;
        std::cout << "  - Right Click : Place selected semantic material block" << std::endl;
        std::cout << "  - 1..9        : Select material (Granite, Limestone, Basalt, Obsidian, Gold, Iron, Quartz, Water, Lava)" << std::endl;
        std::cout << "  - M           : Toggle Mesh Mode (OpenVDB Natural Smooth <-> Voxel Blocks)" << std::endl;
        std::cout << "  - T           : Trigger STC Thermodynamic Reaction step (lava-water quenching)" << std::endl;
        std::cout << "  - R           : Regenerate procedural cave with randomized seed" << std::endl;
        std::cout << "  - ESC         : Release cursor / Exit" << std::endl;
        std::cout << "================================================================================\n" << std::endl;
    }

    void setupMaterials() {
        auto matMgr = MaterialManager::getSingletonPtr();

        // Voxel Block Material
        if (!matMgr->getByName("VoxelVertexColorMat")) {
            MaterialPtr blockMat = matMgr->create("VoxelVertexColorMat", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* pass = blockMat->getTechnique(0)->getPass(0);
            pass->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT);
            pass->setSpecular(0.2f, 0.2f, 0.2f, 1.0f);
            pass->setShininess(16.0f);
            pass->setShadingMode(SO_GOURAUD);
        }

        // Smooth OpenVDB Isosurface Material
        if (!matMgr->getByName("SCR/SmoothCaveMaterial")) {
            MaterialPtr smoothMat = matMgr->create("SCR/SmoothCaveMaterial", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* pass = smoothMat->getTechnique(0)->getPass(0);
            pass->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT);
            pass->setSpecular(0.35f, 0.35f, 0.35f, 1.0f);
            pass->setShininess(32.0f);
            pass->setShadingMode(SO_PHONG);
        }
    }

    void rebuildCaveMesh() {
        if (caveManualObj) {
            scnMgr->destroyManualObject(caveManualObj);
            caveManualObj = nullptr;
        }
        if (caveNode) {
            scnMgr->destroySceneNode(caveNode);
            caveNode = nullptr;
        }

        caveManualObj = scnMgr->createManualObject("CaveMeshObj");
        caveManualObj->setDynamic(true);

        if (current_mesh_mode == MESH_SMOOTH_OPENVDB) {
            std::cout << "[MeshMode] Generating Natural Smooth Cave via OpenVDB volumeToMesh..." << std::endl;
            SCR::VDB::VdbCaveMesher::buildNaturalCaveMesh(caveManualObj, *cave, 0.0f, 0.02f);
        } else {
            std::cout << "[MeshMode] Generating Discrete Culled Voxel Block Mesh..." << std::endl;
            buildDiscreteVoxelMesh();
        }

        caveNode = scnMgr->getRootSceneNode()->createChildSceneNode("CaveNode");
        caveNode->attachObject(caveManualObj);
    }

    void buildDiscreteVoxelMesh() {
        caveManualObj->clear();
        caveManualObj->begin("VoxelVertexColorMat", RenderOperation::OT_TRIANGLE_LIST);

        const auto& reg = SCR::Material::MaterialRegistry::instance();
        size_t vert_count = 0;

        auto addFace = [&](float x, float y, float z, int dir, const SCR::Material::ColorRGB& col) {
            Vector3 v[4];
            Vector3 norm;

            switch (dir) {
                case 0: // +X
                    v[0] = Vector3(x+1, y,   z);   v[1] = Vector3(x+1, y+1, z);
                    v[2] = Vector3(x+1, y+1, z+1); v[3] = Vector3(x+1, y,   z+1);
                    norm = Vector3::UNIT_X;
                    break;
                case 1: // -X
                    v[0] = Vector3(x, y,   z+1); v[1] = Vector3(x, y+1, z+1);
                    v[2] = Vector3(x, y+1, z);   v[3] = Vector3(x, y,   z);
                    norm = Vector3::NEGATIVE_UNIT_X;
                    break;
                case 2: // +Y (Top)
                    v[0] = Vector3(x,   y+1, z);   v[1] = Vector3(x,   y+1, z+1);
                    v[2] = Vector3(x+1, y+1, z+1); v[3] = Vector3(x+1, y+1, z);
                    norm = Vector3::UNIT_Y;
                    break;
                case 3: // -Y (Bottom)
                    v[0] = Vector3(x,   y, z+1); v[1] = Vector3(x,   y, z);
                    v[2] = Vector3(x+1, y, z);   v[3] = Vector3(x+1, y, z+1);
                    norm = Vector3::NEGATIVE_UNIT_Y;
                    break;
                case 4: // +Z
                    v[0] = Vector3(x+1, y,   z+1); v[1] = Vector3(x+1, y+1, z+1);
                    v[2] = Vector3(x,   y+1, z+1); v[3] = Vector3(x,   y,   z+1);
                    norm = Vector3::UNIT_Z;
                    break;
                case 5: // -Z
                    v[0] = Vector3(x,   y,   z); v[1] = Vector3(x,   y+1, z);
                    v[2] = Vector3(x+1, y+1, z); v[3] = Vector3(x+1, y,   z);
                    norm = Vector3::NEGATIVE_UNIT_Z;
                    break;
            }

            for (int i = 0; i < 4; ++i) {
                caveManualObj->position(v[i]);
                caveManualObj->normal(norm);
                caveManualObj->colour(col.r, col.g, col.b, col.a);
            }

            caveManualObj->triangle(vert_count,     vert_count + 1, vert_count + 2);
            caveManualObj->triangle(vert_count + 2, vert_count + 3, vert_count);
            vert_count += 4;
        };

        for (int x = 0; x < cave->dim_x; ++x) {
            for (int y = 0; y < cave->dim_y; ++y) {
                for (int z = 0; z < cave->dim_z; ++z) {
                    uint16_t mat_code = cave->getVoxel(x, y, z);
                    if (mat_code == SCR::Material::MAT_AIR) continue;

                    const auto& mat = reg.get(mat_code);

                    if (!cave->isSolid(x + 1, y, z)) addFace(x, y, z, 0, mat.albedo);
                    if (!cave->isSolid(x - 1, y, z)) addFace(x, y, z, 1, mat.albedo);
                    if (!cave->isSolid(x, y + 1, z)) addFace(x, y, z, 2, mat.albedo);
                    if (!cave->isSolid(x, y - 1, z)) addFace(x, y, z, 3, mat.albedo);
                    if (!cave->isSolid(x, y, z + 1)) addFace(x, y, z, 4, mat.albedo);
                    if (!cave->isSolid(x, y, z - 1)) addFace(x, y, z, 5, mat.albedo);
                }
            }
        }

        caveManualObj->end();
        std::cout << "[OGRE] Voxel block mesh generated: " << vert_count / 4 << " visible quads.\n";
    }

    void updateCameraPose() {
        if (!player || !camNode) return;
        auto eye = player->getEyePosition();
        camNode->setPosition(eye.x, eye.y, eye.z);

        auto q = player->getEyeOrientation();
        camNode->setOrientation(Quaternion(q.w, q.x, q.y, q.z));
    }

    bool keyPressed(const KeyboardEvent& evt) override {
        if (evt.keysym.sym == 'w' || evt.keysym.sym == 'W' || evt.keysym.sym == SDLK_UP) key_w = true;
        if (evt.keysym.sym == 's' || evt.keysym.sym == 'S' || evt.keysym.sym == SDLK_DOWN) key_s = true;
        if (evt.keysym.sym == 'a' || evt.keysym.sym == 'A' || evt.keysym.sym == SDLK_LEFT) key_a = true;
        if (evt.keysym.sym == 'd' || evt.keysym.sym == 'D' || evt.keysym.sym == SDLK_RIGHT) key_d = true;
        if (evt.keysym.sym == SDLK_SPACE) key_space = true;
        if (evt.keysym.sym == SDLK_LSHIFT) key_shift = true;

        // Toggle Mesh Mode: OpenVDB Smooth Isosurface <-> Voxel Blocks
        if (evt.keysym.sym == 'm' || evt.keysym.sym == 'M') {
            current_mesh_mode = (current_mesh_mode == MESH_SMOOTH_OPENVDB) ? MESH_VOXEL_BLOCKS : MESH_SMOOTH_OPENVDB;
            std::cout << "\n[Mesh Toggle] Switched representation to: " 
                      << (current_mesh_mode == MESH_SMOOTH_OPENVDB ? "OpenVDB Natural Smooth Isosurface" : "Voxel Blocks") << std::endl;
            rebuildCaveMesh();
        }

        // Trigger STC Reaction Step
        if (evt.keysym.sym == 't' || evt.keysym.sym == 'T') {
            int reactions = cave->stepSTCReactions();
            std::cout << "\n[STC Transition] Evaluated 6-neighborhoods: " << reactions << " thermodynamic phase changes completed.\n";
            if (reactions > 0) rebuildCaveMesh();
        }

        // Regenerate procedural cave
        if (evt.keysym.sym == 'r' || evt.keysym.sym == 'R') {
            std::cout << "\nRegenerating cave with randomized seed..." << std::endl;
            cave->generateProceduralCave((unsigned int)std::chrono::system_clock::now().time_since_epoch().count());
            rebuildCaveMesh();
            player->position = cave->findSpawnPosition();
            player->velocity = SCR::Spatial::Vector3D(0, 0, 0);
        }

        // Hotbar material selection (1-9)
        if (evt.keysym.sym == '1') active_place_material = SCR::Material::MAT_GRANITE;
        if (evt.keysym.sym == '2') active_place_material = SCR::Material::MAT_LIMESTONE;
        if (evt.keysym.sym == '3') active_place_material = SCR::Material::MAT_BASALT;
        if (evt.keysym.sym == '4') active_place_material = SCR::Material::MAT_OBSIDIAN;
        if (evt.keysym.sym == '5') active_place_material = SCR::Material::MAT_GOLD_ORE;
        if (evt.keysym.sym == '6') active_place_material = SCR::Material::MAT_IRON_ORE;
        if (evt.keysym.sym == '7') active_place_material = SCR::Material::MAT_QUARTZ;
        if (evt.keysym.sym == '8') active_place_material = SCR::Material::MAT_WATER;
        // Manual Head-Shake test key
        if (evt.keysym.sym == 'h' || evt.keysym.sym == 'H') {
            player->triggerHeadShake(0.16f);
            std::cout << "\n[Micro-Movement] Head-shake triggered." << std::endl;
        }

        if (evt.keysym.sym == SDLK_ESCAPE) {
            getRoot()->queueEndRendering();
        }

        return true;
    }

    bool keyReleased(const KeyboardEvent& evt) override {
        if (evt.keysym.sym == 'w' || evt.keysym.sym == 'W' || evt.keysym.sym == SDLK_UP) key_w = false;
        if (evt.keysym.sym == 's' || evt.keysym.sym == 'S' || evt.keysym.sym == SDLK_DOWN) key_s = false;
        if (evt.keysym.sym == 'a' || evt.keysym.sym == 'A' || evt.keysym.sym == SDLK_LEFT) key_a = false;
        if (evt.keysym.sym == 'd' || evt.keysym.sym == 'D' || evt.keysym.sym == SDLK_RIGHT) key_d = false;
        if (evt.keysym.sym == SDLK_SPACE) key_space = false;
        if (evt.keysym.sym == SDLK_LSHIFT) key_shift = false;
        return true;
    }

    bool mouseMoved(const MouseMotionEvent& evt) override {
        if (player) {
            const float sensitivity = 0.0028f;
            player->rotate(-evt.xrel * sensitivity, -evt.yrel * sensitivity);
        }
        return true;
    }

    bool mousePressed(const MouseButtonEvent& evt) override {
        if (!player || !cave) return true;

        const auto& reg = SCR::Material::MaterialRegistry::instance();
        auto hit = player->castRay(*cave, 10.0f);

        if (evt.button == BUTTON_LEFT) {
            // Mine / Excavate targeted voxel
            if (hit.hit && hit.material_code != SCR::Material::MAT_BEDROCK) {
                player->triggerHeadShake(0.12f); // Tactile impact recoil head-shake
                cave->setVoxel(hit.voxel_x, hit.voxel_y, hit.voxel_z, SCR::Material::MAT_AIR);
                std::cout << "\n[Excavation] Mined " << reg.get(hit.material_code).name 
                          << " at (" << hit.voxel_x << ", " << hit.voxel_y << ", " << hit.voxel_z << ")\n";
                rebuildCaveMesh();
            }
        } else if (evt.button == BUTTON_RIGHT) {
            // Place active material block
            if (hit.hit) {
                int px = hit.place_coord.x;
                int py = hit.place_coord.y;
                int pz = hit.place_coord.z;
                if (cave->inBounds(px, py, pz) && cave->getVoxel(px, py, pz) == SCR::Material::MAT_AIR) {
                    cave->setVoxel(px, py, pz, active_place_material);
                    std::cout << "\n[Construction] Placed " << reg.get(active_place_material).name 
                              << " at (" << px << ", " << py << ", " << pz << ")\n";
                    rebuildCaveMesh();
                }
            }
        }

        return true;
    }

    bool frameRenderingQueued(const FrameEvent& evt) override {
        if (!player || !cave) return true;

        // 1. Update Physics Kinematics & Collision
        player->update(
            evt.timeSinceLastFrame, 
            key_w, key_s, key_a, key_d, 
            key_space, key_shift, 
            *cave
        );

        // 2. Synchronize Camera Spatial Pose to Player Frame
        updateCameraPose();

        // 3. Real-time DDA Raycast HUD Inspection
        hud_timer += evt.timeSinceLastFrame;
        frame_count++;
        fps_accum += 1.0f / (evt.timeSinceLastFrame > 1e-4f ? evt.timeSinceLastFrame : 1.0f);

        if (hud_timer >= 0.25f) {
            auto hit = player->castRay(*cave, 12.0f);
            const auto& reg = SCR::Material::MaterialRegistry::instance();

            int foot_x = (int)std::floor(player->position.x);
            int foot_y = (int)std::floor(player->position.y - 0.1f);
            int foot_z = (int)std::floor(player->position.z);
            uint16_t foot_mat_code = cave->getVoxel(foot_x, foot_y, foot_z);
            const auto& foot_mat = reg.get(foot_mat_code);
            const auto& active_mat = reg.get(active_place_material);

            float avg_fps = fps_accum / frame_count;
            std::cout << "\r[FPS: " << std::fixed << std::setprecision(0) << avg_fps << "] "
                      << "Pos: (" << std::setprecision(1) << player->position.x << ", " 
                      << player->position.y << ", " << player->position.z << ") "
                      << "| Footing: " << foot_mat.name << " "
                      << "| Mode: " << (current_mesh_mode == MESH_SMOOTH_OPENVDB ? "OpenVDB Natural" : "Voxel Blocks") << " "
                      << "| Hotbar: [" << active_mat.name << "]";

            if (hit.hit) {
                const auto& hit_mat = reg.get(hit.material_code);
                std::cout << " | Crosshair: " << hit_mat.name
                          << " [E:" << (int)hit_mat.youngs_modulus_gpa << "GPa, "
                          << "p:" << (int)hit_mat.density_kg_m3 << "kg/m3] "
                          << "d:" << std::setprecision(1) << hit.distance << "m     ";
            } else {
                std::cout << " | Crosshair: Air (Void)                        ";
            }
            std::cout << std::flush;

            hud_timer = 0.0f;
            frame_count = 0;
            fps_accum = 0.0f;
        }

        return true;
    }

    void shutdown() override {
        auto* shadergen = RTShader::ShaderGenerator::getSingletonPtr();
        if (shadergen && scnMgr) {
            shadergen->removeSceneManager(scnMgr);
        }
        ApplicationContext::shutdown();
    }
};

void logErrorToFile(const std::string& err_type, const std::string& details) {
    std::cerr << "\n================================================================================" << std::endl;
    std::cerr << " [FATAL ERROR] " << err_type << std::endl;
    std::cerr << details << std::endl;
    std::cerr << "================================================================================" << std::endl;

    std::ofstream log("applications/cave/cave_explorer.log", std::ios::app);
    if (log.is_open()) {
        log << "\n[FATAL ERROR " << err_type << "]\n" << details << "\n" << std::endl;
    }
}

int main(int argc, char** argv) {
    // Ensure SDL2 uses X11 for Ogre's X11/EGL render window on Wayland sessions
    setenv("SDL_VIDEODRIVER", "x11", 0);

    try {
        VoxelCaveApp app;
        app.initApp();
        app.getRoot()->startRendering();
        app.closeApp();
    } catch (const Ogre::Exception& e) {
        logErrorToFile("Ogre::Exception", e.getFullDescription());
        return 1;
    } catch (const std::exception& e) {
        logErrorToFile("std::exception", e.what());
        return 1;
    } catch (...) {
        logErrorToFile("UnknownException", "An unknown exception occurred during runtime.");
        return 1;
    }
    return 0;
}
