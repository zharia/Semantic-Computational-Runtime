#include <iostream>
#include <memory>
#include <chrono>
#include <string>

#include <Ogre.h>
#include <OgreApplicationContext.h>
#include <OgreInput.h>
#include <OgreRTShaderSystem.h>
#include <OgreCamera.h>
#include <OgreViewport.h>
#include <OgreSceneManager.h>
#include <OgreRenderWindow.h>
#include <OgreManualObject.h>

#include <Overlay/OgreImGuiOverlay.h>
#include <Overlay/OgreOverlayManager.h>

#include "simulation/simulation_framework.hpp"
#include "simulation/simulation_systems.hpp"
#include "render/ogre/loading_screen_effects.hpp"
#include "cel_shading_system.hpp"
#include "simulation/island_biome_types.hpp"
#include "simulation/spatial_partitions.hpp"
#include "simulation/sim_ipc_server_legacy.hpp"
#include "scene_volcanic_island.hpp"
#include "scene_karst_cave.hpp"
#include "scene_ocean_lab.hpp"
#include "scene_atmospheric_lab.hpp"

using namespace Ogre;
using namespace OgreBites;
using namespace SCR;
using namespace SCR::Island;
using namespace SCR::Spatial;
using namespace SCR::Simulation;
// using namespace SCR::IPC; — SimIPCServer is at global scope

class SCRSimulationHubApp : public ApplicationContext, public InputListener {
public:
    SceneManager* scnMgr = nullptr;
    Camera* cam = nullptr;
    SceneNode* camNode = nullptr;

    std::unique_ptr<ISimulationScene> current_scene;
    int current_scene_index = 0;

    OrganicLoadingScreen loading_screen;
    ManualObject* loadingMeshObj = nullptr;
    SceneNode* loadingNode = nullptr;
    ManualObject* hudMeshObj = nullptr;
    SceneNode* hudNode = nullptr;

    UserInputState input_state;
    bool scene_selector_open = false;
    bool imgui_initialized = false;
    Ogre::ImGuiOverlay* imgui_overlay = nullptr;
    float global_time = 0.0f;
    float hud_fade_alpha = 0.0f;
    std::chrono::high_resolution_clock::time_point last_frame_time;

    SimIPCServer ipc_server;

    SCRSimulationHubApp() : ApplicationContext("SCR-Simulation-Hub") {}

    void setup() override {
        ApplicationContext::setup();
        addInputListener(this);
        setWindowGrab(true);

        Root* root = getRoot();
        scnMgr = root->createSceneManager();

        auto* sg = RTShader::ShaderGenerator::getSingletonPtr();
        if (sg) sg->addSceneManager(scnMgr);

        // Register All Modular Simulation Scenes
        auto& reg = SimulationRegistry::instance();
        reg.registerScene(
            VolcanicIslandScene().getMetadata(),
            []() { return std::make_unique<VolcanicIslandScene>(); }
        );
        reg.registerScene(
            KarstCaveScene().getMetadata(),
            []() { return std::make_unique<KarstCaveScene>(); }
        );
        reg.registerScene(
            OceanLabScene().getMetadata(),
            []() { return std::make_unique<OceanLabScene>(); }
        );
        reg.registerScene(
            AtmosphericLabScene().getMetadata(),
            []() { return std::make_unique<AtmosphericLabScene>(); }
        );

        // Setup Shared Camera & Viewport
        cam = scnMgr->createCamera("MainCam");
        cam->setAutoAspectRatio(true);
        camNode = scnMgr->getRootSceneNode()->createChildSceneNode("MainCamNode");
        camNode->attachObject(cam);

        auto* vp = getRenderWindow()->addViewport(cam);
        vp->setBackgroundColour(ColourValue(0.03f, 0.04f, 0.06f));

        setupMaterials();

        // Setup 2D Loading Screen Overlay Object
        loadingMeshObj = scnMgr->createManualObject("LoadingScreenMeshObj");
        loadingMeshObj->setDynamic(true);
        loadingMeshObj->setRenderQueueGroup(RENDER_QUEUE_OVERLAY);
        loadingMeshObj->setUseIdentityProjection(true);
        loadingMeshObj->setUseIdentityView(true);
        loadingMeshObj->setBoundingBox(AxisAlignedBox::BOX_INFINITE);
        loadingNode = scnMgr->getRootSceneNode()->createChildSceneNode("LoadingScreenNode");
        loadingNode->attachObject(loadingMeshObj);

        // Setup 2D Simulation Vector HUD Overlay Object
        hudMeshObj = scnMgr->createManualObject("SimulationHUDMeshObj");
        hudMeshObj->setDynamic(true);
        hudMeshObj->setRenderQueueGroup(RENDER_QUEUE_OVERLAY);
        hudMeshObj->setUseIdentityProjection(true);
        hudMeshObj->setUseIdentityView(true);
        hudMeshObj->setBoundingBox(AxisAlignedBox::BOX_INFINITE);
        hudNode = scnMgr->getRootSceneNode()->createChildSceneNode("SimulationHUDNode");
        hudNode->attachObject(hudMeshObj);

        std::cout << "\n================================================================================" << std::endl;
        std::cout << " SCR Unified Simulation Hub & Semantic Runtime Framework" << std::endl;
        std::cout << " Version 3.2.0 — Modular Simulation Registry Active" << std::endl;
        std::cout << "================================================================================" << std::endl;
        std::cout << "Available Simulations:" << std::endl;
        const auto& scenes = reg.getScenes();
        for (size_t i = 0; i < scenes.size(); ++i) {
            std::cout << "  [" << (i + 1) << "] " << scenes[i].metadata.title
                      << " (" << scenes[i].metadata.category << ")" << std::endl;
        }
        std::cout << "================================================================================\n" << std::endl;

        last_frame_time = std::chrono::high_resolution_clock::now();

        // Initialize ImGui Overlay
        auto* ovl_mgr = Ogre::OverlayManager::getSingletonPtr();
        if (ovl_mgr) {
            imgui_overlay = new Ogre::ImGuiOverlay();
            imgui_overlay->setZOrder(300);
            imgui_overlay->show();
            ovl_mgr->addOverlay(imgui_overlay);
            imgui_initialized = true;
            ImGui::GetIO().MouseDrawCursor = true;
        }

        // Start Remote IPC Command Server
        const char* custom_sock = std::getenv("SCR_SIM_SOCK");
        std::string sock_path = custom_sock ? custom_sock : "/tmp/scr_sim_hub.sock";
        ipc_server.start(sock_path);

        // Load Default Simulation (Volcanic Island)
        loadSimulationScene(0);
        setWindowGrab(true);
    }

    void setupMaterials() {
        auto mm = MaterialManager::getSingletonPtr();

        // Loading Screen Shader / Material
        if (!mm->getByName("SCR/LoadingScreenMaterial")) {
            MaterialPtr m = mm->create("SCR/LoadingScreenMaterial", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p = m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT);
            p->setSceneBlending(SBT_TRANSPARENT_ALPHA);
            p->setDepthWriteEnabled(false);
            p->setDepthCheckEnabled(false);
            p->setLightingEnabled(false);
            p->setCullingMode(CULL_NONE);
            p->setShadingMode(SO_FLAT);
            p->setFog(true, FOG_NONE);
        }

        // Vector HUD Shader / Material
        if (!mm->getByName("SCR/HUDMaterial")) {
            MaterialPtr m = mm->create("SCR/HUDMaterial", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p = m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT);
            p->setSceneBlending(SBT_TRANSPARENT_ALPHA);
            p->setDepthWriteEnabled(false);
            p->setDepthCheckEnabled(false);
            p->setLightingEnabled(false);
            p->setCullingMode(CULL_NONE);
            p->setShadingMode(SO_FLAT);
            p->setFog(true, FOG_NONE);
        }

        // Shared 3D Simulation Materials
        auto make = [&](const std::string& name, bool transp = false) {
            if (mm->getByName(name)) return;
            MaterialPtr m = mm->create(name, ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p = m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT);
            p->setSpecular(0.4f, 0.4f, 0.4f, 1.0f);
            p->setShininess(32.0f);
            p->setShadingMode(SO_PHONG);
            p->setCullingMode(CULL_NONE);
            if (transp) {
                p->setSceneBlending(SBT_TRANSPARENT_ALPHA);
                p->setDepthWriteEnabled(false);
            }
        };

        make("SCR/VolcanicIslandMaterial");
        make("SCR/DiscreteBlockMaterial");
        make("SCR/BasaltRockMaterial");
        make("SCR/VolcanicBoulderMaterial");
        make("SCR/VegetationMaterial");

        // Initialize Cel / Toon Shading System with 4-Tier Diffuse Bands, Specular Hot-Spots & Fresnel Rim
        SCR::Render::CelShadingSystem::initializeCelShading(false);

        if (!mm->getByName("SCR/VolumetricSkyDomeMaterial")) {
            MaterialPtr m = mm->create("SCR/VolumetricSkyDomeMaterial", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p = m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT);
            p->setLightingEnabled(false);
            p->setDepthWriteEnabled(false);
            p->setDepthCheckEnabled(false);
            p->setCullingMode(CULL_NONE);
            p->setShadingMode(SO_GOURAUD);
            p->setFog(true, FOG_NONE);
        }

        if (!mm->getByName("SCR/VolcanicLavaMaterial")) {
            MaterialPtr m = mm->create("SCR/VolcanicLavaMaterial", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p = m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT);
            p->setSelfIllumination(0.35f, 0.12f, 0.02f);
            p->setSpecular(0.6f, 0.4f, 0.1f, 1.0f);
            p->setShininess(32.f);
            p->setCullingMode(CULL_NONE);
            p->setShadingMode(SO_PHONG);
            p->setFog(true, FOG_NONE);
        }

        if (!mm->getByName("SCR/VolcanicSmokeMaterial")) {
            MaterialPtr m = mm->create("SCR/VolcanicSmokeMaterial", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p = m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT);
            p->setSceneBlending(SBT_TRANSPARENT_ALPHA);
            p->setDepthWriteEnabled(false);
            p->setDepthCheckEnabled(true);
            p->setCullingMode(CULL_NONE);
            p->setLightingEnabled(false);
            p->setShadingMode(SO_GOURAUD);
            p->setFog(true, FOG_NONE);
        }

        if (!mm->getByName("SCR/OceanWaterMaterial")) {
            MaterialPtr m = mm->create("SCR/OceanWaterMaterial", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p = m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT);
            p->setSceneBlending(SBT_TRANSPARENT_ALPHA);
            p->setDepthWriteEnabled(false);
            p->setDepthCheckEnabled(true);
            p->setCullingMode(CULL_NONE);
            p->setLightingEnabled(false);
            p->setShadingMode(SO_GOURAUD);
            p->setFog(true, FOG_NONE);
        }

        if (!mm->getByName("SCR/WeatherPrecipitationMaterial")) {
            MaterialPtr m = mm->create("SCR/WeatherPrecipitationMaterial", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p = m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT);
            p->setSceneBlending(SBT_TRANSPARENT_ALPHA);
            p->setDepthWriteEnabled(false);
            p->setDepthCheckEnabled(true);
            p->setCullingMode(CULL_NONE);
            p->setLightingEnabled(false);
            p->setShadingMode(SO_FLAT);
            p->setFog(true, FOG_NONE);
        }

        if (!mm->getByName("SCR/BoidSpeciesMaterial")) {
            MaterialPtr m = mm->create("SCR/BoidSpeciesMaterial", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p = m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT | TVC_EMISSIVE);
            p->setAmbient(0.4f, 0.4f, 0.4f);
            p->setSpecular(0.6f, 0.6f, 0.6f, 1.0f);
            p->setShininess(32.f);
            p->setShadingMode(SO_GOURAUD);
            p->setCullingMode(CULL_NONE);
        }

        if (!mm->getByName("SCR/HorizonParallaxMaterial")) {
            MaterialPtr m = mm->create("SCR/HorizonParallaxMaterial", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p = m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT);
            p->setSceneBlending(SBT_TRANSPARENT_ALPHA);
            p->setDepthWriteEnabled(false);
            p->setDepthCheckEnabled(true);
            p->setCullingMode(CULL_NONE);
            p->setLightingEnabled(false);
            p->setShadingMode(SO_GOURAUD);
            p->setFog(true, FOG_NONE);
        }
    }

    void loadSimulationScene(int index) {
        auto& reg = SimulationRegistry::instance();
        if (index < 0 || index >= (int)reg.getScenes().size()) return;

        // Clean up previous scene if active
        if (current_scene) {
            RenderContext detachCtx;
            detachCtx.native_scene_manager = scnMgr;
            current_scene->detachRenderer(detachCtx);
            current_scene.reset();
        }

        current_scene_index = index;
        current_scene = reg.createScene(index);
        if (!current_scene) return;

        SceneMetadata meta = current_scene->getMetadata();
        std::cout << "[Hub] Loading Simulation: " << meta.title << " (" << meta.id << ")..." << std::endl;

        // Initialize Loading Screen Overlay
        loading_screen.startLoading(meta);

        // Execute procedural generation with feedback callback
        LoadingContext ctx([this](const LoadingTaskUpdate& update) {
            loading_screen.updateTaskProgress(update);
            std::cout << "  [" << update.subsystem << "] " << update.current_stage
                      << (update.detail_message.empty() ? "" : (" — " + update.detail_message))
                      << " (" << int(update.progress * 100.0f) << "%)" << std::endl;
        });

        current_scene->prepare(ctx);

        // Initialize GPU resources in SceneGraph
        RenderContext renderCtx;
        renderCtx.native_scene_manager = scnMgr;
        renderCtx.native_camera = cam;
        renderCtx.native_window = getRenderWindow();
        current_scene->attachRenderer(renderCtx);

        loading_screen.finishLoading();
    }

    void takeScreenshot(const std::string& filename = "applications/cave/island_screenshot.png") {
        auto* win = getRenderWindow();
        if (win) {
            win->update();
            win->writeContentsToFile(filename);
            std::cout << "[Screenshot] Captured: " << filename << std::endl;
        }
    }

    bool frameRenderingQueued(const FrameEvent& evt) override {
        float dt = evt.timeSinceLastFrame;
        dt = std::min(dt, 0.05f);
        global_time += dt;

        // Update Loading Screen Animation & Dissolve Clock
        loading_screen.update(dt);
        if (!loading_screen.isDone()) {
            loading_screen.renderLoadingMesh(loadingMeshObj, getRenderWindow());
        } else {
            if (loadingMeshObj) loadingMeshObj->clear();
        }

        // Process Remote IPC Commands Synchronously on Render Thread
        ipc_server.processQueuedCommands([this](const std::string& method, const nlohmann::json& params, bool& success, std::string& error_msg) -> nlohmann::json {
            nlohmann::json res = nlohmann::json::object();
            if (method == "get_state") {
                res["global_time"] = global_time;
                res["loading_done"] = loading_screen.isDone();
                res["loading_alpha"] = loading_screen.alpha_in_game_hud;
                res["scene_index"] = current_scene_index;
                if (current_scene) {
                    auto meta = current_scene->getMetadata();
                    res["scene_id"] = meta.id;
                    res["scene_title"] = meta.title;
                }
                if (cam) {
                    auto pos = cam->getRealPosition();
                    res["camera"] = {
                        {"x", pos.x}, {"y", pos.y}, {"z", pos.z}
                    };
                }
                auto* vol_scene = dynamic_cast<SCR::Simulation::VolcanicIslandScene*>(current_scene.get());
                if (vol_scene) {
                    if (vol_scene->player_subject) {
                        float spd = std::sqrt(vol_scene->player_subject->velocity.x * vol_scene->player_subject->velocity.x +
                                              vol_scene->player_subject->velocity.z * vol_scene->player_subject->velocity.z);
                        res["player"] = {
                            {"x", vol_scene->player_subject->position.x},
                            {"y", vol_scene->player_subject->position.y},
                            {"z", vol_scene->player_subject->position.z},
                            {"vx", vol_scene->player_subject->velocity.x},
                            {"vy", vol_scene->player_subject->velocity.y},
                            {"vz", vol_scene->player_subject->velocity.z},
                            {"speed", spd},
                            {"on_ground", vol_scene->player_subject->on_ground},
                            {"smooth_eye_y", vol_scene->player_subject->smooth_eye_y},
                            {"yaw", vol_scene->player_subject->yaw},
                            {"pitch", vol_scene->player_subject->pitch},
                            {"in_water", vol_scene->player_subject->in_water}
                        };
                    }
                    if (vol_scene->island_subject) {
                        res["biome"] = (int)vol_scene->island_subject->active_biome;
                        res["seed"] = vol_scene->island_subject->seed;
                    }
                    if (vol_scene->atmo_subject) {
                        res["time_of_day"] = vol_scene->atmo_subject->time_of_day_hours;
                    }
                    res["partition"] = (int)vol_scene->active_partition;
                }
                return res;
            } else if (method == "set_camera" || method == "teleport") {
                auto* vol_scene = dynamic_cast<SCR::Simulation::VolcanicIslandScene*>(current_scene.get());
                if (vol_scene && vol_scene->player_subject) {
                    if (params.contains("x")) vol_scene->player_subject->position.x = params["x"].get<float>();
                    if (params.contains("y")) vol_scene->player_subject->position.y = params["y"].get<float>();
                    if (params.contains("z")) vol_scene->player_subject->position.z = params["z"].get<float>();
                    if (vol_scene->island_subject && vol_scene->island_subject->voxel_island) {
                        float gh = vol_scene->island_subject->voxel_island->getIslandHeight(
                            vol_scene->player_subject->position.x, vol_scene->player_subject->position.z
                        );
                        bool snap = params.value("snap_to_ground", false) || (vol_scene->player_subject->position.y <= gh + 1.5f);
                        if (snap || vol_scene->player_subject->position.y < gh) {
                            vol_scene->player_subject->position.y = gh;
                            vol_scene->player_subject->on_ground = true;
                            vol_scene->player_subject->coyote_timer = 0.2f;
                            vol_scene->player_subject->jump_count = 0;
                        } else {
                            vol_scene->player_subject->on_ground = false;
                        }
                        vol_scene->player_subject->in_water = (vol_scene->player_subject->position.y < vol_scene->island_subject->voxel_island->sea_level);
                    }
                    vol_scene->player_subject->smooth_eye_y = vol_scene->player_subject->position.y + vol_scene->player_subject->eye_height;
                    vol_scene->player_subject->velocity = Spatial::Vector3D(0, 0, 0);
                    if (params.contains("yaw")) vol_scene->player_subject->yaw = params["yaw"].get<float>();
                    if (params.contains("pitch")) vol_scene->player_subject->pitch = params["pitch"].get<float>();
                    res["player_x"] = vol_scene->player_subject->position.x;
                    res["player_y"] = vol_scene->player_subject->position.y;
                    res["player_z"] = vol_scene->player_subject->position.z;
                    res["yaw"] = vol_scene->player_subject->yaw;
                    res["pitch"] = vol_scene->player_subject->pitch;
                }
                return res;
            } else if (method == "set_biome") {
                auto* vol_scene = dynamic_cast<SCR::Simulation::VolcanicIslandScene*>(current_scene.get());
                if (!vol_scene) {
                    success = false;
                    error_msg = "Current scene is not VolcanicIslandScene";
                    return res;
                }
                Island::IslandBiomeType target_biome = Island::IslandBiomeType::VOLCANO;
                if (params.is_number_integer()) {
                    target_biome = (Island::IslandBiomeType)params.get<int>();
                } else if (params.is_object() && params.contains("biome")) {
                    if (params["biome"].is_number()) {
                        target_biome = (Island::IslandBiomeType)params["biome"].get<int>();
                    } else if (params["biome"].is_string()) {
                        std::string bname = params["biome"].get<std::string>();
                        if (bname == "volcano" || bname == "VOLCANO") target_biome = Island::IslandBiomeType::VOLCANO;
                        else if (bname == "jungle" || bname == "JUNGLE") target_biome = Island::IslandBiomeType::JUNGLE;
                        else if (bname == "desert" || bname == "DESERT") target_biome = Island::IslandBiomeType::DESERT;
                        else if (bname == "ice" || bname == "glacial" || bname == "GLACIAL_ICE") target_biome = Island::IslandBiomeType::GLACIAL_ICE;
                        else if (bname == "archipelago" || bname == "coral" || bname == "CORAL_ARCHIPELAGO") target_biome = Island::IslandBiomeType::CORAL_ARCHIPELAGO;
                    }
                }
                vol_scene->warpToIsland(target_biome);
                res["biome"] = (int)target_biome;
                return res;
            } else if (method == "set_partition") {
                auto* vol_scene = dynamic_cast<SCR::Simulation::VolcanicIslandScene*>(current_scene.get());
                if (!vol_scene) {
                    success = false;
                    error_msg = "Current scene is not VolcanicIslandScene";
                    return res;
                }
                Spatial::PartitionType ptype = Spatial::PartitionType::CALDERA_SUMMIT;
                if (params.contains("partition")) {
                    if (params["partition"].is_number()) {
                        ptype = (Spatial::PartitionType)params["partition"].get<int>();
                    } else if (params["partition"].is_string()) {
                        std::string pname = params["partition"].get<std::string>();
                        if (pname == "caldera" || pname == "caldera_summit") ptype = Spatial::PartitionType::CALDERA_SUMMIT;
                        else if (pname == "canopy" || pname == "rainforest") ptype = Spatial::PartitionType::RAINFOREST_CANOPY;
                        else if (pname == "cliffs" || pname == "basalt_cliffs") ptype = Spatial::PartitionType::BASALT_CLIFFS;
                        else if (pname == "lagoon" || pname == "coral_lagoon") ptype = Spatial::PartitionType::CORAL_LAGOON;
                        else if (pname == "tubes" || pname == "lava_tubes") ptype = Spatial::PartitionType::SUBTERRANEAN_LAVA_TUBES;
                        else if (pname == "abyss" || pname == "deep_ocean") ptype = Spatial::PartitionType::DEEP_OCEAN_ABYSS;
                    }
                }
                vol_scene->warpToPartition(ptype);
                res["partition"] = (int)ptype;
                return res;
            } else if (method == "set_time") {
                float tod = params.value("time_of_day", 12.0f);
                auto* vol_scene = dynamic_cast<SCR::Simulation::VolcanicIslandScene*>(current_scene.get());
                if (vol_scene) {
                    if (vol_scene->atmo_subject) vol_scene->atmo_subject->time_of_day_hours = tod;
                    auto atmo_sys = vol_scene->coordinator.getSystem<AtmosphereSystem>();
                    if (atmo_sys) {
                        for (auto& sub : atmo_sys->getSubSystems()) {
                            if (auto sky_sub = std::dynamic_pointer_cast<VolumetricAtmosphereSubSystem>(sub)) {
                                if (sky_sub->sky_system) {
                                    sky_sub->sky_system->setTimeOfDay(tod);
                                }
                            }
                        }
                    }
                }
                res["time_of_day"] = tod;
                return res;
            } else if (method == "inject_input") {
                if (params.contains("move_forward")) input_state.move_forward = params["move_forward"].get<bool>();
                if (params.contains("move_backward")) input_state.move_backward = params["move_backward"].get<bool>();
                if (params.contains("move_left")) input_state.move_left = params["move_left"].get<bool>();
                if (params.contains("move_right")) input_state.move_right = params["move_right"].get<bool>();
                if (params.contains("jump")) input_state.jump = params["jump"].get<bool>();
                if (params.contains("crouch")) input_state.crouch = params["crouch"].get<bool>();
                if (params.contains("sprint")) input_state.sprint = params["sprint"].get<bool>();
                if (params.contains("show_hud")) input_state.show_hud = params["show_hud"].get<bool>();
                if (params.contains("mouse_dx")) input_state.mouse_dx += params["mouse_dx"].get<float>();
                if (params.contains("mouse_dy")) input_state.mouse_dy += params["mouse_dy"].get<float>();
                res["input_applied"] = true;
                return res;
            } else if (method == "capture_screenshot") {
                std::string path = params.value("filename", "applications/cave/island_screenshot.png");
                takeScreenshot(path);
                res["filename"] = path;
                res["captured"] = true;
                return res;
            } else if (method == "load_scene") {
                int target_idx = -1;
                if (params.contains("index")) {
                    target_idx = params["index"].get<int>();
                } else if (params.contains("id")) {
                    target_idx = SimulationRegistry::instance().getIndexById(params["id"].get<std::string>());
                }
                if (target_idx >= 0) {
                    loadSimulationScene(target_idx);
                    res["scene_index"] = current_scene_index;
                } else {
                    success = false;
                    error_msg = "Invalid scene index or id";
                }
                return res;
            } else if (method == "spawn_rigid_body") {
                auto* vol_scene = dynamic_cast<SCR::Simulation::VolcanicIslandScene*>(current_scene.get());
                if (!vol_scene) {
                    success = false;
                    error_msg = "Current scene does not support physics";
                    return res;
                }
                auto phys_sub = vol_scene->getPhysicsSubsystem();
                if (!phys_sub) {
                    success = false;
                    error_msg = "Physics dynamics subsystem not active";
                    return res;
                }
                std::string body_type = params.value("type", "sphere");
                float mass = params.value("mass", 50.0f);
                float restitution = params.value("restitution", 0.6f);
                float friction = params.value("friction", 0.5f);
                SCRVec3 pos = { 160.0f, 120.0f, 160.0f };
                if (params.contains("position") && params["position"].is_array() && params["position"].size() >= 3) {
                    pos.x = params["position"][0].get<float>();
                    pos.y = params["position"][1].get<float>();
                    pos.z = params["position"][2].get<float>();
                }
                SCRVec3 vel = { 0.0f, 0.0f, 0.0f };
                if (params.contains("initial_velocity") && params["initial_velocity"].is_array() && params["initial_velocity"].size() >= 3) {
                    vel.x = params["initial_velocity"][0].get<float>();
                    vel.y = params["initial_velocity"][1].get<float>();
                    vel.z = params["initial_velocity"][2].get<float>();
                }

                uint32_t body_id = 0;
                if (body_type == "box") {
                    SCRVec3 half_ext = { 0.5f, 0.5f, 0.5f };
                    if (params.contains("half_extents") && params["half_extents"].is_array() && params["half_extents"].size() >= 3) {
                        half_ext.x = params["half_extents"][0].get<float>();
                        half_ext.y = params["half_extents"][1].get<float>();
                        half_ext.z = params["half_extents"][2].get<float>();
                    }
                    body_id = phys_sub->spawnDynamicBox(half_ext, mass, pos, vel, restitution, friction);
                } else {
                    float radius = params.value("radius", 0.8f);
                    body_id = phys_sub->spawnDynamicSphere(radius, mass, pos, vel, restitution, friction);
                }
                res["body_id"] = body_id;
                res["type"] = body_type;
                res["spawned"] = (body_id > 0);
                return res;
            } else if (method == "raycast") {
                auto* vol_scene = dynamic_cast<SCR::Simulation::VolcanicIslandScene*>(current_scene.get());
                if (!vol_scene) {
                    success = false;
                    error_msg = "Current scene does not support physics";
                    return res;
                }
                auto phys_sub = vol_scene->getPhysicsSubsystem();
                if (!phys_sub) {
                    success = false;
                    error_msg = "Physics dynamics subsystem not active";
                    return res;
                }
                SCRVec3 from = { 160.0f, 200.0f, 160.0f };
                SCRVec3 to = { 160.0f, 0.0f, 160.0f };
                if (params.contains("from") && params["from"].is_array() && params["from"].size() >= 3) {
                    from.x = params["from"][0].get<float>();
                    from.y = params["from"][1].get<float>();
                    from.z = params["from"][2].get<float>();
                }
                if (params.contains("to") && params["to"].is_array() && params["to"].size() >= 3) {
                    to.x = params["to"][0].get<float>();
                    to.y = params["to"][1].get<float>();
                    to.z = params["to"][2].get<float>();
                }
                SCRRigidRaycastHit hit;
                bool has_hit = phys_sub->raycast(from, to, &hit);
                res["has_hit"] = has_hit;
                res["hit"] = has_hit;
                if (has_hit) {
                    res["hit_fraction"] = hit.fraction;
                    res["fraction"] = hit.fraction;
                    res["hit_point"] = nlohmann::json::array({ hit.point.x, hit.point.y, hit.point.z });
                    res["point"] = nlohmann::json::array({ hit.point.x, hit.point.y, hit.point.z });
                    res["hit_normal"] = nlohmann::json::array({ hit.normal.x, hit.normal.y, hit.normal.z });
                    res["normal"] = nlohmann::json::array({ hit.normal.x, hit.normal.y, hit.normal.z });
                    res["hit_collider_id"] = hit.body_id;
                }
                return res;
            } else if (method == "get_physics_state") {
                auto* vol_scene = dynamic_cast<SCR::Simulation::VolcanicIslandScene*>(current_scene.get());
                if (!vol_scene) {
                    success = false;
                    error_msg = "Current scene does not support physics";
                    return res;
                }
                auto phys_sub = vol_scene->getPhysicsSubsystem();
                if (!phys_sub) {
                    res["active"] = false;
                    res["body_count"] = 0;
                    return res;
                }
                res["active"] = true;
                res["body_count"] = phys_sub->getDynamicBodyCount();
                auto body_ids = phys_sub->getAllBodyIds();
                nlohmann::json bodies_array = nlohmann::json::array();
                for (uint32_t bid : body_ids) {
                    SCRVec3 pos = {0,0,0};
                    SCRQuat rot = {0,0,0,1};
                    SCRVec3 lin_vel = {0,0,0};
                    SCRVec3 ang_vel = {0,0,0};
                    if (phys_sub->getBodyState(bid, &pos, &rot, &lin_vel, &ang_vel)) {
                        bodies_array.push_back({
                            {"body_id", bid},
                            {"position", {pos.x, pos.y, pos.z}},
                            {"rotation", {rot.x, rot.y, rot.z, rot.w}},
                            {"linear_velocity", {lin_vel.x, lin_vel.y, lin_vel.z}},
                            {"angular_velocity", {ang_vel.x, ang_vel.y, ang_vel.z}}
                        });
                    }
                }
                res["bodies"] = bodies_array;
                return res;
            } else if (method == "get_weather") {
                auto* vol_scene = dynamic_cast<SCR::Simulation::VolcanicIslandScene*>(current_scene.get());
                if (!vol_scene) {
                    success = false;
                    error_msg = "Current scene does not support weather subsystem";
                    return res;
                }
                auto w_sys = vol_scene->getWeatherSubsystem();
                if (!w_sys) {
                    success = false;
                    error_msg = "Weather subsystem not active";
                    return res;
                }
                const auto& ws = w_sys->current_state;
                res["condition_id"] = (uint32_t)ws.condition_id;
                res["condition"] = ws.condition_name;
                res["condition_name"] = ws.condition_name;
                res["barometric_pressure_hpa"] = ws.pressure_sea_level_hpa;
                res["pressure_hpa"] = ws.pressure_sea_level_hpa;
                res["temperature_celsius"] = ws.temperature_c;
                res["temperature_c"] = ws.temperature_c;
                res["humidity_relative"] = ws.relative_humidity;
                res["relative_humidity"] = ws.relative_humidity;
                res["precipitation_intensity"] = ws.precipitation_rate;
                res["precipitation_rate_mm_h"] = ws.precipitation_rate;
                res["precipitation_type"] = (ws.volcanic_ash_fraction > 0.5f) ? "volcanic_ash" : (ws.precipitation_rate > 0.0f ? "rain" : "none");
                res["optical_depth"] = ws.cloud_optical_depth;
                res["cloud_optical_depth"] = ws.cloud_optical_depth;
                res["cloud_coverage"] = ws.cloud_coverage;
                res["aerosol_density"] = ws.aerosol_density;
                res["volcanic_ash_fraction"] = ws.volcanic_ash_fraction;
                res["lightning_intensity"] = ws.lightning_intensity;
                res["wind_speed_mps"] = std::sqrt(ws.wind_velocity.x * ws.wind_velocity.x + ws.wind_velocity.z * ws.wind_velocity.z);
                res["wind_velocity"] = { ws.wind_velocity.x, ws.wind_velocity.y, ws.wind_velocity.z };
                res["transition_progress"] = w_sys->transition_progress;
                return res;
            } else if (method == "set_weather") {
                auto* vol_scene = dynamic_cast<SCR::Simulation::VolcanicIslandScene*>(current_scene.get());
                if (!vol_scene) {
                    success = false;
                    error_msg = "Current scene does not support weather subsystem";
                    return res;
                }
                auto w_sys = vol_scene->getWeatherSubsystem();
                if (!w_sys) {
                    success = false;
                    error_msg = "Weather subsystem not active";
                    return res;
                }
                float duration = params.value("duration", params.value("transition_duration", 3.0f));
                if (params.contains("condition_id")) {
                    uint32_t cid = params["condition_id"].get<uint32_t>();
                    w_sys->setWeather(static_cast<SCR::Weather::WeatherConditionType>(cid), duration);
                } else if (params.contains("profile_id")) {
                    uint32_t cid = params["profile_id"].get<uint32_t>();
                    w_sys->setWeather(static_cast<SCR::Weather::WeatherConditionType>(cid), duration);
                } else if (params.contains("condition") && params["condition"].is_string()) {
                    w_sys->setWeatherByName(params["condition"].get<std::string>(), duration);
                } else if (params.contains("condition_name") && params["condition_name"].is_string()) {
                    w_sys->setWeatherByName(params["condition_name"].get<std::string>(), duration);
                }
                res["target_condition"] = w_sys->target_profile.name;
                res["duration"] = duration;
                return res;
            } else if (method == "get_weather_profiles") {
                auto profiles = SCR::Weather::WeatherRegistry::instance().getAllProfiles();
                nlohmann::json prof_arr = nlohmann::json::array();
                for (const auto& pair : profiles) {
                    prof_arr.push_back({
                        {"id", (uint32_t)pair.second.id},
                        {"condition", pair.second.name},
                        {"name", pair.second.name},
                        {"pressure_hpa", pair.second.target_pressure_hpa},
                        {"temperature_c", pair.second.target_temperature_c},
                        {"humidity", pair.second.target_humidity},
                        {"precipitation_rate", pair.second.precipitation_rate},
                        {"cloud_coverage", pair.second.cloud_coverage}
                    });
                }
                res["profiles"] = prof_arr;
                return res;
            } else if (method == "quit") {
                getRoot()->queueEndRendering();
                res["quitting"] = true;
                return res;
            } else {
                success = false;
                error_msg = "Unknown method: " + method;
                return res;
            }
        });

        // Update Active Simulation Scene
        if (current_scene) {
            current_scene->update(dt, input_state);
            float target_hud_alpha = (input_state.show_hud ? 1.0f : 0.0f) * loading_screen.alpha_in_game_hud;
            hud_fade_alpha += (target_hud_alpha - hud_fade_alpha) * std::min(1.0f, dt * 14.0f);
            if (hud_fade_alpha < 0.005f && !input_state.show_hud) hud_fade_alpha = 0.0f;
            RenderContext presCtx;
            presCtx.native_scene_manager = scnMgr;
            presCtx.native_camera = cam;
            presCtx.native_window = getRenderWindow();
            presCtx.native_viewport = getRenderWindow()->getViewport(0);
            current_scene->renderPresentation(presCtx, hud_fade_alpha);
        }

        // ImGui Scene Selection Menu
        if (imgui_initialized && imgui_overlay) {
            imgui_overlay->NewFrame();
            if (scene_selector_open) {
                ImGui::SetNextWindowSize(ImVec2(320, 0), ImGuiCond_FirstUseEver);
                ImGui::Begin("Scene Selector", &scene_selector_open);
                ImGui::Text("SCR Simulation Hub");
                ImGui::Separator();
                const auto& scenes = SimulationRegistry::instance().getScenes();
                for (size_t i = 0; i < scenes.size(); ++i) {
                    bool is_active = ((int)i == current_scene_index);
                    if (is_active) ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.3f, 0.6f, 0.3f, 1.0f));
                    char label[64];
                    snprintf(label, sizeof(label), "[%zu] %s##%zu", i + 1, scenes[i].metadata.title.c_str(), i);
                    if (ImGui::Button(label, ImVec2(-1, 0))) {
                        loadSimulationScene((int)i);
                    }
                    if (is_active) ImGui::PopStyleColor();
                    ImGui::SameLine();
                    ImGui::TextDisabled("(%s)", scenes[i].metadata.category.c_str());
                }
                ImGui::Separator();
                ImGui::Text("Ctrl+1..4: Quick Switch");
                ImGui::Text("Tab: Toggle Menu");
                ImGui::End();
            }
        }

        // Reset per-frame mouse deltas
        input_state.mouse_dx = 0.0f;
        input_state.mouse_dy = 0.0f;

        static bool screenshot_taken = false;
        if (!screenshot_taken && global_time > 1.5f && loading_screen.alpha_in_game_hud >= 0.95f) {
            screenshot_taken = true;
            takeScreenshot("applications/cave/island_screenshot.png");
        }

        return true;
    }

    // ─── Input Handlers ──────────────────────────────────────────────────────
    bool keyPressed(const KeyboardEvent& evt) override {
        Keycode key = evt.keysym.sym;

        if (key == SDLK_ESCAPE) {
            getRoot()->queueEndRendering();
            return true;
        }
        if (key == SDLK_F12 || key == 'p' || key == 'P') {
            takeScreenshot();
            return true;
        }
        if (key == 9) {
            scene_selector_open = !scene_selector_open;
            return true;
        }

        static constexpr int KEY_LALT = (1 << 30) | 0xE2;
        static constexpr int KEY_RALT = (1 << 30) | 0xE6;
        static constexpr int KEY_LCTRL = (1 << 30) | 0xE0;
        static constexpr int KEY_RCTRL = (1 << 30) | 0xE4;

        bool is_alt = (key == KEY_LALT || key == KEY_RALT || (evt.keysym.mod & OgreBites::KMOD_ALT) != 0);
        bool is_ctrl = (key == KEY_LCTRL || key == KEY_RCTRL || (evt.keysym.mod & OgreBites::KMOD_CTRL) != 0);

        // Tactical Vector HUD Toggle (Hold ALT or TAB)
        if (key == 9 || key == '\t' || is_alt) {
            input_state.show_hud = true;
        }

        // Simulation Switcher Shortcuts: Ctrl + 1..4
        if (is_ctrl && key >= '1' && key <= '4') {
            int target_idx = key - '1';
            if (target_idx != current_scene_index) {
                loadSimulationScene(target_idx);
                return true;
            }
        }

        // Reload current simulation: Ctrl + R
        if (is_ctrl && (key == 'r' || key == 'R')) {
            loadSimulationScene(current_scene_index);
            return true;
        }

        // Locomotion Keys
        if (key == 'w' || key == 'W' || key == OgreBites::SDLK_UP)    input_state.move_forward  = true;
        if (key == 's' || key == 'S' || key == OgreBites::SDLK_DOWN)  input_state.move_backward = true;
        if (key == 'a' || key == 'A' || key == OgreBites::SDLK_LEFT)  input_state.move_left     = true;
        if (key == 'd' || key == 'D' || key == OgreBites::SDLK_RIGHT) input_state.move_right    = true;
        if (key == OgreBites::SDLK_LSHIFT)                             input_state.sprint        = true;
        if (key == OgreBites::SDLK_SPACE || key == ' ' || key == 32)  input_state.jump          = true;

        if (current_scene) {
            current_scene->handleKeyPress(key, true, is_alt, is_ctrl);
        }

        return true;
    }

    bool keyReleased(const KeyboardEvent& evt) override {
        Keycode key = evt.keysym.sym;
        static constexpr int KEY_LALT = (1 << 30) | 0xE2;
        static constexpr int KEY_RALT = (1 << 30) | 0xE6;
        static constexpr int KEY_LCTRL = (1 << 30) | 0xE0;
        static constexpr int KEY_RCTRL = (1 << 30) | 0xE4;

        bool is_alt = (key == KEY_LALT || key == KEY_RALT || (evt.keysym.mod & OgreBites::KMOD_ALT) != 0);
        bool is_ctrl = (key == KEY_LCTRL || key == KEY_RCTRL || (evt.keysym.mod & OgreBites::KMOD_CTRL) != 0);

        if (key == 9 || key == '\t' || key == KEY_LALT || key == KEY_RALT) {
            input_state.show_hud = false;
        }

        if (key == 'w' || key == 'W' || key == OgreBites::SDLK_UP)                     input_state.move_forward  = false;
        if (key == 's' || key == 'S' || key == OgreBites::SDLK_DOWN)                   input_state.move_backward = false;
        if (key == 'a' || key == 'A' || key == OgreBites::SDLK_LEFT)                   input_state.move_left     = false;
        if (key == 'd' || key == 'D' || key == OgreBites::SDLK_RIGHT)                  input_state.move_right    = false;
        if (key == OgreBites::SDLK_LSHIFT)                                              input_state.sprint        = false;
        if (key == OgreBites::SDLK_SPACE || key == ' ' || key == 32)                   input_state.jump          = false;

        if (current_scene) {
            current_scene->handleKeyPress(key, false, is_alt, is_ctrl);
        }

        return true;
    }

    bool mouseMoved(const MouseMotionEvent& evt) override {
        input_state.mouse_dx += -float(evt.xrel) * 0.0028f;
        input_state.mouse_dy += -float(evt.yrel) * 0.0028f;
        return true;
    }

    bool mousePressed(const MouseButtonEvent& evt) override {
        if (evt.button == BUTTON_LEFT)  input_state.action_primary = true;
        if (evt.button == BUTTON_RIGHT) input_state.action_secondary = true;

        if (current_scene) {
            auto* vol_scene = dynamic_cast<SCR::Simulation::VolcanicIslandScene*>(current_scene.get());
            if (vol_scene && vol_scene->screen_focused) {
                SCR::Wayland::WaylandCompositor::get().sendPointerButton(
                    0, (evt.button == BUTTON_LEFT) ? 0x110 : 0x111, true
                );
            }
        }
        return true;
    }

    bool mouseReleased(const MouseButtonEvent& evt) override {
        if (evt.button == BUTTON_LEFT)  input_state.action_primary = false;
        if (evt.button == BUTTON_RIGHT) input_state.action_secondary = false;

        if (current_scene) {
            auto* vol_scene = dynamic_cast<SCR::Simulation::VolcanicIslandScene*>(current_scene.get());
            if (vol_scene && vol_scene->screen_focused) {
                SCR::Wayland::WaylandCompositor::get().sendPointerButton(
                    0, (evt.button == BUTTON_LEFT) ? 0x110 : 0x111, false
                );
            }
        }
        return true;
    }

    void shutdown() override {
        ipc_server.stop();
        removeInputListener(this);
        if (current_scene && scnMgr) {
            RenderContext detachCtx;
            detachCtx.native_scene_manager = scnMgr;
            current_scene->detachRenderer(detachCtx);
            current_scene.reset();
        }

        auto* sg = RTShader::ShaderGenerator::getSingletonPtr();
        if (sg && scnMgr) sg->removeSceneManager(scnMgr);
        ApplicationContext::shutdown();
    }
};

int main(int argc, char* argv[]) {
    setenv("SDL_VIDEODRIVER", "x11", 1);
    try {
        SCRSimulationHubApp app;
        app.initApp();
        app.getRoot()->startRendering();
        app.closeApp();
    } catch (const std::exception& e) {
        std::cerr << "[FATAL] " << e.what() << std::endl;
        return 1;
    }
    return 0;
}
