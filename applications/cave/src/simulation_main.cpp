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

#include "simulation_framework.hpp"
#include "loading_screen_effects.hpp"
#include "cel_shading_system.hpp"
#include "scene_volcanic_island.hpp"
#include "scene_karst_cave.hpp"
#include "scene_ocean_lab.hpp"
#include "scene_atmospheric_lab.hpp"

using namespace Ogre;
using namespace OgreBites;
using namespace SCR::Simulation;

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
    float global_time = 0.0f;
    float hud_fade_alpha = 0.0f;
    std::chrono::high_resolution_clock::time_point last_frame_time;

    SCRSimulationHubApp() : ApplicationContext("SCR-Simulation-Hub") {}

    void setup() override {
        ApplicationContext::setup();
        addInputListener(this);

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
            p->setCullingMode(CULL_NONE);
            p->setLightingEnabled(false);
            p->setShadingMode(SO_FLAT);
            p->setFog(true, FOG_NONE);
        }

        if (!mm->getByName("SCR/OceanWaterMaterial")) {
            MaterialPtr m = mm->create("SCR/OceanWaterMaterial", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p = m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT);
            p->setSceneBlending(SBT_TRANSPARENT_ALPHA);
            p->setDepthWriteEnabled(false);
            p->setCullingMode(CULL_NONE);
            p->setLightingEnabled(false);
            p->setShadingMode(SO_GOURAUD);
            p->setFog(true, FOG_NONE);
        }

        if (!mm->getByName("SCR/VegetationMaterial")) {
            MaterialPtr m = mm->create("SCR/VegetationMaterial", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p = m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT);
            p->setSpecular(0.2f, 0.35f, 0.15f, 1.0f);
            p->setShininess(16.f);
            p->setShadingMode(SO_PHONG);
            p->setCullingMode(CULL_NONE);
        }

        if (!mm->getByName("SCR/BoidSpeciesMaterial")) {
            MaterialPtr m = mm->create("SCR/BoidSpeciesMaterial", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Pass* p = m->getTechnique(0)->getPass(0);
            p->setVertexColourTracking(TVC_DIFFUSE | TVC_AMBIENT);
            p->setSpecular(0.6f, 0.6f, 0.6f, 1.0f);
            p->setShininess(32.f);
            p->setShadingMode(SO_PHONG);
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
            current_scene->cleanup(scnMgr);
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
        current_scene->initScene(scnMgr, cam, getRenderWindow());

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

        // Update Active Simulation Scene
        if (current_scene) {
            current_scene->update(dt, input_state);
            float target_hud_alpha = (input_state.show_hud ? 1.0f : 0.0f) * loading_screen.alpha_in_game_hud;
            hud_fade_alpha += (target_hud_alpha - hud_fade_alpha) * std::min(1.0f, dt * 14.0f);
            if (hud_fade_alpha < 0.005f && !input_state.show_hud) hud_fade_alpha = 0.0f;
            current_scene->renderHUD(hudMeshObj, getRenderWindow()->getViewport(0), hud_fade_alpha);
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

        // Tactical Vector HUD Toggle (Hold ALT)
        static constexpr int KEY_LALT = (1 << 30) | 0xE2;
        static constexpr int KEY_RALT = (1 << 30) | 0xE6;
        if (key == KEY_LALT || key == KEY_RALT || (evt.keysym.mod & KMOD_ALT)) {
            input_state.show_hud = true;
        }

        // Simulation Switcher Shortcuts: Keys 1..4
        if (key >= '1' && key <= '4') {
            int target_idx = key - '1';
            if (target_idx != current_scene_index) {
                loadSimulationScene(target_idx);
                return true;
            }
        }

        // Reload current simulation
        if (key == SDLK_F5 || key == 'r' || key == 'R') {
            loadSimulationScene(current_scene_index);
            return true;
        }

        // Locomotion Keys
        if (key == 'w' || key == 'W' || key == SDLK_UP)    input_state.move_forward  = true;
        if (key == 's' || key == 'S' || key == SDLK_DOWN)  input_state.move_backward = true;
        if (key == 'a' || key == 'A' || key == SDLK_LEFT)  input_state.move_left     = true;
        if (key == 'd' || key == 'D' || key == SDLK_RIGHT) input_state.move_right    = true;
        if (key == SDLK_LSHIFT)                                              input_state.sprint        = true;
        if (key == SDLK_SPACE || key == ' ' || key == 32)                   input_state.jump          = true;

        if (current_scene) {
            current_scene->handleKeyPress(key, true);
        }

        return true;
    }

    bool keyReleased(const KeyboardEvent& evt) override {
        Keycode key = evt.keysym.sym;
        static constexpr int KEY_LALT = (1 << 30) | 0xE2;
        static constexpr int KEY_RALT = (1 << 30) | 0xE6;

        if (key == KEY_LALT || key == KEY_RALT) {
            input_state.show_hud = false;
        }

        if (key == 'w' || key == 'W' || key == SDLK_UP)                     input_state.move_forward  = false;
        if (key == 's' || key == 'S' || key == SDLK_DOWN)                   input_state.move_backward = false;
        if (key == 'a' || key == 'A' || key == SDLK_LEFT)                   input_state.move_left     = false;
        if (key == 'd' || key == 'D' || key == SDLK_RIGHT)                  input_state.move_right    = false;
        if (key == SDLK_LSHIFT)                                              input_state.sprint        = false;
        if (key == SDLK_SPACE || key == ' ' || key == 32)                   input_state.jump          = false;

        if (current_scene) {
            current_scene->handleKeyPress(key, false);
        }

        return true;
    }

    bool mouseMoved(const MouseMotionEvent& evt) override {
        input_state.mouse_dx = -float(evt.xrel) * 0.0022f;
        input_state.mouse_dy = -float(evt.yrel) * 0.0022f;
        return true;
    }

    bool mousePressed(const MouseButtonEvent& evt) override {
        if (evt.button == BUTTON_LEFT)  input_state.action_primary = true;
        if (evt.button == BUTTON_RIGHT) input_state.action_secondary = true;
        return true;
    }

    bool mouseReleased(const MouseButtonEvent& evt) override {
        if (evt.button == BUTTON_LEFT)  input_state.action_primary = false;
        if (evt.button == BUTTON_RIGHT) input_state.action_secondary = false;
        return true;
    }

    void shutdown() override {
        removeInputListener(this);
        if (current_scene && scnMgr) {
            current_scene->cleanup(scnMgr);
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
