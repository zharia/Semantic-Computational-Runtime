#ifndef CAVE_OGRE_SUBSYSTEMS_HPP
#define CAVE_OGRE_SUBSYSTEMS_HPP

#include <Ogre.h>

#include "simulation/simulation_systems_core.hpp"
#include "render/ogre/rendering_pipeline.hpp"

#include "procedural_island.hpp"
#include "hierarchical_wfc.hpp"
#include "vdb_chunk_manager.hpp"
#include "vdb_island_mesher.hpp"
#include "ocean_simulation.hpp"
#include "volumetric_clouds.hpp"
#include "volcanic_effects.hpp"
#include "procedural_vegetation.hpp"
#include "boid_semantics.hpp"
#include "horizon_planet_parallax.hpp"
#include "wayland_compositor.hpp"
#include "in_world_display.hpp"
#include "nautical_navigation.hpp"
#include "weather_semantics.hpp"

namespace SCR::Simulation {

class OpenVdbTerrainSubSystem : public ISimulationSubSystem {
public:
    std::unique_ptr<VDB::VdbChunkManager> chunk_manager;
    Ogre::SceneNode* islandNode = nullptr;
    Ogre::ManualObject* islandMesh = nullptr;
    bool mesh_dirty = true;
    bool mesh_visible_ = true;
    bool last_secondary_ = false;
    bool voyage_clear_pending_ = false;

    std::string getName() const override { return "OpenVdbTerrainSubSystem"; }

    OpenVdbTerrainSubSystem() {
        chunk_manager = std::make_unique<VDB::VdbChunkManager>();
    }

    void initialize(SystemContext& ctx) override {
        if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()) {
            islandMesh = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->createManualObject("OpenVdbIslandMeshObj");
            islandMesh->setDynamic(true);
            islandMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_MAIN);
            islandNode = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->getRootSceneNode()->createChildSceneNode("OpenVdbIslandNode");
            islandNode->attachObject(islandMesh);
        }
        mesh_dirty = true;
    }

    void prepare(LoadingContext& ctx, SystemContext& sysCtx) override {
        ctx.update(0.18f, "Synthesizing Stratovolcano Geomorphology", "320x64x320 lattice (6,553,600 voxels)", "VOXEL_LATTICE");
        auto island_sub = sysCtx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
        if (island_sub) {
            island_sub->voxel_island = std::make_shared<Island::VoxelIsland>(320, 64, 320);
            island_sub->voxel_island->generateProceduralIsland(island_sub->seed);
            island_sub->peak_height = island_sub->voxel_island->peak_height;
            island_sub->island_radius = island_sub->voxel_island->island_radius;
        }
        mesh_dirty = true;
    }

    void updateSim(float dt, const UserInputState& input, SimContext& ctx) override {
        // M key state tracking (visibility toggle applied in renderSync)
        if (input.action_secondary && !last_secondary_) {
            mesh_visible_ = !mesh_visible_;
        }
        last_secondary_ = input.action_secondary;
    }

    void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) override {
        auto* scnMgr = renderCtx.getSceneManager<Ogre::SceneManager>();
        auto island_sub = simCtx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
        auto player_sub = simCtx.subjects.getFirstSubjectOfType<PlayerSubject>(SubjectType::PLAYER);

        // Apply mesh visibility toggle from updateSim
        if (islandNode) islandNode->setVisible(mesh_visible_);

        // Clear chunks if pending from voyage event
        if (voyage_clear_pending_ && chunk_manager && scnMgr) {
            chunk_manager->clearAllChunks(scnMgr);
            voyage_clear_pending_ = false;
        }

        // Chunk streaming: load/unload chunks around player position
        if (chunk_manager && scnMgr && island_sub && island_sub->voxel_island && player_sub) {
            Ogre::Vector3 cam_pos(player_sub->position.x, player_sub->smooth_eye_y, player_sub->position.z);
            chunk_manager->update(cam_pos, *island_sub->voxel_island, scnMgr, dt);
        }

        if (island_sub && island_sub->voxel_island && islandMesh) {
            if (mesh_dirty) {
                VDB::VdbIslandMesher::buildNaturalIslandMesh(islandMesh, *island_sub->voxel_island);
                mesh_dirty = false;
            }
        }
    }

    void handleEvent(const ISimulationEvent& event, SimContext& ctx) override {
        if (event.getEventType() == EventType::ISLAND_VOYAGE) {
            mesh_dirty = true;
            voyage_clear_pending_ = true;
        }
    }

    void cleanup(RenderContext& renderCtx) override {
        auto* scnMgr = renderCtx.getSceneManager<Ogre::SceneManager>();
        if (chunk_manager) {
            chunk_manager->clearAllChunks(scnMgr);
        }
        if (islandMesh && scnMgr) {
            try { if (scnMgr->hasManualObject(islandMesh->getName())) scnMgr->destroyManualObject(islandMesh); } catch (...) {}
            islandMesh = nullptr;
        }
        if (islandNode && scnMgr) {
            try { if (scnMgr->hasSceneNode(islandNode->getName())) scnMgr->destroySceneNode(islandNode); } catch (...) {}
            islandNode = nullptr;
        }
    }
};

class VolcanoGeothermalSubSystem : public ISimulationSubSystem {
public:
    std::unique_ptr<Volcano::VolcanicLavaFlow> lava_system;
    std::unique_ptr<Volcano::VolcanicSmokePlume> smoke_system;
    Ogre::SceneNode* lavaNode = nullptr;
    Ogre::ManualObject* lavaMesh = nullptr;
    Ogre::SceneNode* smokeNode = nullptr;
    Ogre::ManualObject* smokeMesh = nullptr;
    Ogre::Light* calderaGlow = nullptr;
    Ogre::SceneNode* calderaGlowNode = nullptr;

    std::string getName() const override { return "VolcanoGeothermalSubSystem"; }

    VolcanoGeothermalSubSystem() {
        lava_system = std::make_unique<Volcano::VolcanicLavaFlow>();
        smoke_system = std::make_unique<Volcano::VolcanicSmokePlume>();
    }

    void initialize(SystemContext& ctx) override {
        if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()) {
            if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->hasLight("CalderaGlowLight")) {
                ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->destroyLight("CalderaGlowLight");
            }
            if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->hasSceneNode("CalderaGlowNode")) {
                ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->destroySceneNode("CalderaGlowNode");
            }
            calderaGlow = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->createLight("CalderaGlowLight");
            calderaGlow->setType(Ogre::Light::LT_POINT);
            calderaGlow->setDiffuseColour(1.0f, 0.35f, 0.05f);
            calderaGlow->setSpecularColour(1.0f, 0.45f, 0.1f);
            calderaGlow->setAttenuation(120.0f, 1.0f, 0.045f, 0.0075f);
            calderaGlowNode = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->getRootSceneNode()->createChildSceneNode("CalderaGlowNode");
            calderaGlowNode->setPosition(160.0f, 62.0f, 160.0f);
            calderaGlowNode->attachObject(calderaGlow);

            if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->hasManualObject("LavaFlowMeshObj")) {
                ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->destroyManualObject("LavaFlowMeshObj");
            }
            if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->hasSceneNode("LavaFlowNode")) {
                ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->destroySceneNode("LavaFlowNode");
            }
            lavaMesh = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->createManualObject("LavaFlowMeshObj");
            lavaMesh->setDynamic(true);
            lavaMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_6);
            lavaNode = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->getRootSceneNode()->createChildSceneNode("LavaFlowNode");
            lavaNode->attachObject(lavaMesh);

            if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->hasManualObject("SmokePlumeMeshObj")) {
                ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->destroyManualObject("SmokePlumeMeshObj");
            }
            if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->hasSceneNode("SmokePlumeNode")) {
                ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->destroySceneNode("SmokePlumeNode");
            }
            smokeMesh = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->createManualObject("SmokePlumeMeshObj");
            smokeMesh->setDynamic(true);
            smokeMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_8);
            smokeNode = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->getRootSceneNode()->createChildSceneNode("SmokePlumeNode");
            smokeNode->attachObject(smokeMesh);
        }
    }

    void prepare(LoadingContext& ctx, SystemContext& sysCtx) override {
        ctx.update(0.62f, "Braiding Bingham Plastic Molten Lava River", "Caldera summit vent to ocean surf spline", "VOLCANO_MAGMA");
        auto island_sub = sysCtx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
        if (island_sub && island_sub->voxel_island) {
            if (lava_system) lava_system->initRiverPath(*island_sub->voxel_island);
            if (smoke_system) smoke_system->initPlume(*island_sub->voxel_island);
        }
        ctx.update(0.78f, "Pre-warming Convective Ash & Smoke Chimney", "54 buoyant vortex billow puffs", "SMOKE_PLUME");
    }

    void updateSim(float dt, const UserInputState& input, SimContext& ctx) override {
        (void)dt; (void)input; (void)ctx;
    }

    void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) override {
        auto island_sub = simCtx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
        bool is_volcano = (island_sub && island_sub->active_biome == Island::IslandBiomeType::VOLCANO);

        if (lavaNode) lavaNode->setVisible(is_volcano);
        if (smokeNode) smokeNode->setVisible(is_volcano);
        if (calderaGlow) calderaGlow->setVisible(is_volcano);

        if (is_volcano && island_sub && island_sub->voxel_island) {
            if (lava_system && lavaMesh) lava_system->updateLavaMesh(lavaMesh, dt, *island_sub->voxel_island);
            if (smoke_system && smokeMesh) {
                smoke_system->updateSmokeMesh(smokeMesh, dt, *island_sub->voxel_island);
            }
        }
    }

    void handleEvent(const ISimulationEvent& event, SimContext& ctx) override {
        if (event.getEventType() == EventType::ISLAND_VOYAGE) {
            auto island_sub = ctx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
            if (lava_system && island_sub && island_sub->voxel_island) {
                lava_system->initRiverPath(*island_sub->voxel_island);
            }
            if (smoke_system && island_sub && island_sub->voxel_island) {
                smoke_system->initPlume(*island_sub->voxel_island);
            }
        }
    }

    void cleanup(RenderContext& renderCtx) override {
        auto* scnMgr = renderCtx.getSceneManager<Ogre::SceneManager>();
        if (lavaMesh && scnMgr) {
            try { if (scnMgr->hasManualObject(lavaMesh->getName())) scnMgr->destroyManualObject(lavaMesh); } catch (...) {}
            lavaMesh = nullptr;
        }
        if (lavaNode && scnMgr) {
            try { if (scnMgr->hasSceneNode(lavaNode->getName())) scnMgr->destroySceneNode(lavaNode); } catch (...) {}
            lavaNode = nullptr;
        }
        if (smokeMesh && scnMgr) {
            try { if (scnMgr->hasManualObject(smokeMesh->getName())) scnMgr->destroyManualObject(smokeMesh); } catch (...) {}
            smokeMesh = nullptr;
        }
        if (smokeNode && scnMgr) {
            try { if (scnMgr->hasSceneNode(smokeNode->getName())) scnMgr->destroySceneNode(smokeNode); } catch (...) {}
            smokeNode = nullptr;
        }
        if (calderaGlow && scnMgr) {
            try { if (scnMgr->hasLight(calderaGlow->getName())) scnMgr->destroyLight(calderaGlow); } catch (...) {}
            calderaGlow = nullptr;
        }
        if (calderaGlowNode && scnMgr) {
            try { if (scnMgr->hasSceneNode(calderaGlowNode->getName())) scnMgr->destroySceneNode(calderaGlowNode); } catch (...) {}
            calderaGlowNode = nullptr;
        }
    }
};

class GeologySystem : public ISimulationSystem {
public:
    std::string getName() const override { return "GeologySystem"; }

    GeologySystem() {
        addSubSystem(std::make_shared<OpenVdbTerrainSubSystem>());
        addSubSystem(std::make_shared<VolcanoGeothermalSubSystem>());
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// 2. HYDROLOGY SYSTEM & SUBSYSTEMS
// ═══════════════════════════════════════════════════════════════════════════════

class GerstnerOceanSubSystem : public ISimulationSubSystem {
public:
    std::unique_ptr<Ocean::SeaOfThievesWater> ocean_system;
    Ogre::SceneNode* oceanNode = nullptr;
    Ogre::ManualObject* oceanMesh = nullptr;
    bool ocean_visible_ = true;
    bool last_secondary_ = false;

    std::string getName() const override { return "GerstnerOceanSubSystem"; }

    GerstnerOceanSubSystem() {
        ocean_system = std::make_unique<Ocean::SeaOfThievesWater>();
    }

    void initialize(SystemContext& ctx) override {
        if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()) {
            oceanMesh = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->createManualObject("OceanMeshObj");
            oceanMesh->setDynamic(true);
            oceanMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_6);
            oceanNode = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->getRootSceneNode()->createChildSceneNode("OceanNode");
            oceanNode->attachObject(oceanMesh);
        }
    }

    void prepare(LoadingContext& ctx, SystemContext& sysCtx) override {
        ctx.update(0.85f, "Calibrating Multi-Spectral Ocean Gerstner Swells", "Sea of Thieves 8-octave water shader", "OCEAN_WAVES");
        (void)sysCtx;
    }

    void updateSim(float dt, const UserInputState& input, SimContext& ctx) override {
        // L key state tracking (visibility toggle applied in renderSync)
        if (input.action_secondary && !last_secondary_) {
            ocean_visible_ = !ocean_visible_;
        }
        last_secondary_ = input.action_secondary;

        auto atmo_sub = ctx.subjects.getFirstSubjectOfType<AtmosphereSubject>(SubjectType::ATMOSPHERE);
        if (ocean_system && atmo_sub) {
            ocean_system->applyWeather(atmo_sub->wind_speed, atmo_sub->barometric_pressure_hpa, atmo_sub->precipitation_rate_mm_h);
        }
    }

    void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) override {
        // Apply ocean visibility toggle from updateSim
        if (oceanNode) oceanNode->setVisible(ocean_visible_);

        auto player_sub = simCtx.subjects.getFirstSubjectOfType<PlayerSubject>(SubjectType::PLAYER);
        auto island_sub = simCtx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
        auto atmo_sub = simCtx.subjects.getFirstSubjectOfType<AtmosphereSubject>(SubjectType::ATMOSPHERE);
        if (ocean_system && oceanMesh && player_sub && island_sub && island_sub->voxel_island) {
            Spatial::Vector3D sun_dir = Spatial::Vector3D(0.4f, 1.0f, 0.6f).normalized();
            if (atmo_sub) {
                float tod = atmo_sub->time_of_day_hours;
                float sun_angle = ((tod - 6.0f) / 24.0f) * 6.2831853f;
                sun_dir = Spatial::Vector3D(
                    std::cos(sun_angle) * 0.85f,
                    std::sin(sun_angle),
                    std::cos(sun_angle) * 0.45f
                ).normalized();
            }
            ocean_system->updateOceanMesh(
                oceanMesh,
                dt,
                *island_sub->voxel_island,
                player_sub->position,
                sun_dir
            );
        }
    }

    void cleanup(RenderContext& renderCtx) override {
        auto* scnMgr = renderCtx.getSceneManager<Ogre::SceneManager>();
        if (oceanMesh && scnMgr) {
            try { if (scnMgr->hasManualObject(oceanMesh->getName())) scnMgr->destroyManualObject(oceanMesh); } catch (...) {}
            oceanMesh = nullptr;
        }
        if (oceanNode && scnMgr) {
            try { if (scnMgr->hasSceneNode(oceanNode->getName())) scnMgr->destroySceneNode(oceanNode); } catch (...) {}
            oceanNode = nullptr;
        }
    }
};

class HydrologySystem : public ISimulationSystem {
public:
    std::string getName() const override { return "HydrologySystem"; }

    HydrologySystem() {
        addSubSystem(std::make_shared<GerstnerOceanSubSystem>());
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// 3. ATMOSPHERE SYSTEM & SUBSYSTEMS
// ═══════════════════════════════════════════════════════════════════════════════

class VolumetricAtmosphereSubSystem : public ISimulationSubSystem {
public:
    std::shared_ptr<Sky::VolumetricAtmosphere> sky_system;
    Ogre::SceneNode* skyNode = nullptr;
    Ogre::ManualObject* skyMesh = nullptr;
    Ogre::Light* sunLight = nullptr;
    Ogre::SceneNode* sunLightNode = nullptr;
    bool last_primary_ = false;

    std::string getName() const override { return "VolumetricAtmosphereSubSystem"; }

    void initialize(SystemContext& ctx) override {
        if (!sky_system) sky_system = std::make_shared<Sky::VolumetricAtmosphere>();
        sky_system->setTimeOfDay(14.0f); // 2 PM daytime

        if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()) {
            ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->setAmbientLight(Ogre::ColourValue(0.32f, 0.38f, 0.46f));
            ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->setFog(Ogre::FOG_NONE);

            if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->hasLight("SunLight")) {
                ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->destroyLight("SunLight");
            }
            if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->hasSceneNode("SunLightNode")) {
                ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->destroySceneNode("SunLightNode");
            }
            sunLight = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->createLight("SunLight");
            sunLight->setType(Ogre::Light::LT_DIRECTIONAL);
            sunLight->setDiffuseColour(Ogre::ColourValue(1.0f, 0.95f, 0.82f));
            sunLight->setSpecularColour(Ogre::ColourValue(1.0f, 0.98f, 0.90f));
            sunLightNode = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->getRootSceneNode()->createChildSceneNode("SunLightNode");
            sunLightNode->setDirection(Ogre::Vector3(-0.4f, -1.0f, -0.6f).normalisedCopy());
            sunLightNode->attachObject(sunLight);

            if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->hasManualObject("SkyMeshObj")) {
                ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->destroyManualObject("SkyMeshObj");
            }
            if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->hasSceneNode("SkyNode")) {
                ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->destroySceneNode("SkyNode");
            }
            skyMesh = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->createManualObject("SkyMeshObj");
            skyMesh->setDynamic(true);
            skyMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_SKIES_EARLY);
            skyNode = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->getRootSceneNode()->createChildSceneNode("SkyNode");
            skyNode->attachObject(skyMesh);
        }
    }

    void prepare(LoadingContext& ctx, SystemContext& sysCtx) override {
        ctx.update(0.92f, "Compiling Red Dead Redemption Volumetric Sky Dome", "3-layer cumulus, cirrus, stratocumulus", "VOLUMETRIC_SKY");
        (void)sysCtx;
    }

    void updateSim(float dt, const UserInputState& input, SimContext& ctx) override {
        (void)dt;
        // T key = noon, Y key = sunset, U key = midnight
        if (input.action_primary && !last_primary_) {
            if (sky_system) {
                float current = sky_system->time_of_day_hours;
                // T=12 (noon), Y=18 (sunset), U=0 (midnight) — cycle through
                if (current < 10.0f) sky_system->setTimeOfDay(12.0f);
                else if (current < 16.0f) sky_system->setTimeOfDay(18.0f);
                else sky_system->setTimeOfDay(0.0f);
            }
        }
        last_primary_ = input.action_primary;

        if (sky_system) {
            auto atmo_sub = ctx.subjects.getFirstSubjectOfType<AtmosphereSubject>(SubjectType::ATMOSPHERE);
            if (atmo_sub) {
                atmo_sub->time_of_day_hours = sky_system->time_of_day_hours;
            }
        }
    }

    void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) override {
        auto* scnMgr = renderCtx.getSceneManager<Ogre::SceneManager>();
        auto* window = renderCtx.getWindow<Ogre::RenderWindow>();
        auto player_sub = simCtx.subjects.getFirstSubjectOfType<PlayerSubject>(SubjectType::PLAYER);
        auto island_sub = simCtx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
        if (sky_system && skyMesh && player_sub && island_sub && island_sub->voxel_island) {
            bool is_underwater = (player_sub->smooth_eye_y < island_sub->voxel_island->sea_level);

            if (is_underwater) {
                if (scnMgr) {
                    scnMgr->setFog(Ogre::FOG_EXP2, Ogre::ColourValue(0.02f, 0.18f, 0.32f), 0.040f);
                    scnMgr->setAmbientLight(Ogre::ColourValue(0.12f, 0.45f, 0.60f));
                }
                if (window && window->getNumViewports() > 0) {
                    window->getViewport(0)->setBackgroundColour(Ogre::ColourValue(0.015f, 0.16f, 0.28f));
                }
                if (skyNode) skyNode->setVisible(false);
                if (sunLight) sunLight->setDiffuseColour(Ogre::ColourValue(0.15f, 0.55f, 0.70f));
            } else {
                if (scnMgr) {
                    scnMgr->setFog(Ogre::FOG_NONE);
                    scnMgr->setAmbientLight(sky_system->ambient_sky_color);
                }
                if (window && window->getNumViewports() > 0) {
                    window->getViewport(0)->setBackgroundColour(sky_system->zenith_color);
                }
                if (skyNode) skyNode->setVisible(true);
                if (sunLight) {
                    sunLight->setDiffuseColour(sky_system->sun_color);
                    sunLight->setSpecularColour(sky_system->sun_color);
                }
                if (sunLightNode) {
                    Ogre::Vector3 dir(-sky_system->sun_direction.x, -sky_system->sun_direction.y, -sky_system->sun_direction.z);
                    if (dir.squaredLength() > 1e-4f) {
                        sunLightNode->setDirection(dir.normalisedCopy());
                    }
                }
                sky_system->updateSkyDomeMesh(skyMesh, dt, *island_sub->voxel_island, player_sub->position);
            }
        }
    }

    void cleanup(RenderContext& renderCtx) override {
        auto* scnMgr = renderCtx.getSceneManager<Ogre::SceneManager>();
        if (skyMesh && scnMgr) {
            try { if (scnMgr->hasManualObject(skyMesh->getName())) scnMgr->destroyManualObject(skyMesh); } catch (...) {}
            skyMesh = nullptr;
        }
        if (skyNode && scnMgr) {
            try { if (scnMgr->hasSceneNode(skyNode->getName())) scnMgr->destroySceneNode(skyNode); } catch (...) {}
            skyNode = nullptr;
        }
        if (sunLight && scnMgr) {
            try { if (scnMgr->hasLight(sunLight->getName())) scnMgr->destroyLight(sunLight); } catch (...) {}
            sunLight = nullptr;
        }
        if (sunLightNode && scnMgr) {
            try { if (scnMgr->hasSceneNode(sunLightNode->getName())) scnMgr->destroySceneNode(sunLightNode); } catch (...) {}
            sunLightNode = nullptr;
        }
    }
};

class HorizonParallaxSubSystem : public ISimulationSubSystem {
public:
    std::shared_ptr<Sky::VolumetricAtmosphere> sky_system;
    std::unique_ptr<Atmosphere::HorizonPlanetParallaxSystem> parallax_system;
    Ogre::SceneNode* parallaxNode = nullptr;
    Ogre::ManualObject* parallaxMesh = nullptr;

    std::string getName() const override { return "HorizonParallaxSubSystem"; }

    HorizonParallaxSubSystem() {
        parallax_system = std::make_unique<Atmosphere::HorizonPlanetParallaxSystem>();
    }

    void initialize(SystemContext& ctx) override {
        if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()) {
            parallaxMesh = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->createManualObject("ParallaxMeshObj");
            parallaxMesh->setDynamic(true);
            parallaxMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_1);
            parallaxNode = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->getRootSceneNode()->createChildSceneNode("ParallaxNode");
            parallaxNode->attachObject(parallaxMesh);
        }
    }

    void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) override {
        auto player_sub = simCtx.subjects.getFirstSubjectOfType<PlayerSubject>(SubjectType::PLAYER);
        auto island_sub = simCtx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
        static Sky::VolumetricAtmosphere fallback_sky;
        const auto& sky = sky_system ? *sky_system : fallback_sky;
        if (parallax_system && parallaxMesh && player_sub && island_sub && island_sub->voxel_island) {
            parallax_system->updateParallaxMesh(
                parallaxMesh,
                dt,
                sky,
                player_sub->position,
                island_sub->voxel_island->center_x,
                island_sub->voxel_island->center_z
            );
        }
    }

    void cleanup(RenderContext& renderCtx) override {
        auto* scnMgr = renderCtx.getSceneManager<Ogre::SceneManager>();
        if (parallaxMesh && scnMgr) {
            try { if (scnMgr->hasManualObject(parallaxMesh->getName())) scnMgr->destroyManualObject(parallaxMesh); } catch (...) {}
            parallaxMesh = nullptr;
        }
        if (parallaxNode && scnMgr) {
            try { if (scnMgr->hasSceneNode(parallaxNode->getName())) scnMgr->destroySceneNode(parallaxNode); } catch (...) {}
            parallaxNode = nullptr;
        }
    }
};

class DynamicWeatherSubSystem : public ISimulationSubSystem {
public:
    std::shared_ptr<Weather::DynamicWeatherSystem> weather_system;
    std::shared_ptr<Sky::VolumetricAtmosphere> sky_system;
    Ogre::SceneNode* precipNode = nullptr;
    Ogre::ManualObject* precipMesh = nullptr;

    std::string getName() const override { return "DynamicWeatherSubSystem"; }

    DynamicWeatherSubSystem() {
        weather_system = std::make_shared<Weather::DynamicWeatherSystem>();
    }

    void initialize(SystemContext& ctx) override {
        if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()) {
            precipMesh = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->createManualObject("PrecipitationMeshObj");
            precipMesh->setDynamic(true);
            precipMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_MAIN + 2);
            precipNode = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->getRootSceneNode()->createChildSceneNode("PrecipitationNode");
            precipNode->attachObject(precipMesh);
        }
    }

    void updateSim(float dt, const UserInputState& input, SimContext& ctx) override {
        (void)input;
        auto player_sub = ctx.subjects.getFirstSubjectOfType<PlayerSubject>(SubjectType::PLAYER);
        auto atmo_sub = ctx.subjects.getFirstSubjectOfType<AtmosphereSubject>(SubjectType::ATMOSPHERE);
        Ogre::Vector3 cam_pos = player_sub ? Ogre::Vector3(player_sub->position.x, player_sub->smooth_eye_y, player_sub->position.z) : Ogre::Vector3(160, 20, 160);
        float tod = atmo_sub ? atmo_sub->time_of_day_hours : 12.0f;

        if (weather_system) {
            weather_system->update(dt, cam_pos, tod);

            // Synchronize state with AtmosphereSubject
            if (atmo_sub) {
                atmo_sub->weather_condition = weather_system->current_state.condition_name;
                atmo_sub->barometric_pressure_hpa = weather_system->current_state.pressure_sea_level_hpa;
                atmo_sub->ambient_temperature_c = weather_system->current_state.temperature_c;
                atmo_sub->relative_humidity = weather_system->current_state.relative_humidity;
                atmo_sub->precipitation_rate_mm_h = weather_system->current_state.precipitation_rate;
                atmo_sub->aerosol_density = weather_system->current_state.aerosol_density;
                atmo_sub->volcanic_ash_fraction = weather_system->current_state.volcanic_ash_fraction;
                atmo_sub->lightning_intensity = weather_system->current_state.lightning_intensity;
                atmo_sub->cloud_coverage = weather_system->current_state.cloud_coverage;
                atmo_sub->cloud_density_multiplier = weather_system->current_state.cloud_optical_depth;
                atmo_sub->wind_speed = std::sqrt(weather_system->current_state.wind_velocity.x * weather_system->current_state.wind_velocity.x + weather_system->current_state.wind_velocity.z * weather_system->current_state.wind_velocity.z);
                atmo_sub->wind_direction_radians = std::atan2(weather_system->current_state.wind_velocity.z, weather_system->current_state.wind_velocity.x);
                atmo_sub->fog_density = weather_system->current_state.fog_density;
            }

            // Apply Weather to Sky Atmosphere
            if (sky_system) {
                sky_system->applyWeather(
                    weather_system->current_state.cloud_coverage * 1.8f,
                    weather_system->current_state.cloud_optical_depth,
                    weather_system->current_state.wind_velocity,
                    weather_system->current_state.sky_tint,
                    weather_system->current_state.ambient_light_scale,
                    weather_system->current_state.lightning_intensity
                );
            }
        }
    }

    void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) override {
        (void)dt;
        auto player_sub = simCtx.subjects.getFirstSubjectOfType<PlayerSubject>(SubjectType::PLAYER);
        Ogre::Vector3 cam_pos = player_sub ? Ogre::Vector3(player_sub->position.x, player_sub->smooth_eye_y, player_sub->position.z) : Ogre::Vector3(160, 20, 160);
        if (weather_system && precipMesh) {
            weather_system->renderPrecipitation(precipMesh, cam_pos);
        }
    }

    void cleanup(RenderContext& renderCtx) override {
        auto* scnMgr = renderCtx.getSceneManager<Ogre::SceneManager>();
        if (precipMesh && scnMgr) {
            try { if (scnMgr->hasManualObject(precipMesh->getName())) scnMgr->destroyManualObject(precipMesh); } catch (...) {}
            precipMesh = nullptr;
        }
        if (precipNode && scnMgr) {
            try { if (scnMgr->hasSceneNode(precipNode->getName())) scnMgr->destroySceneNode(precipNode); } catch (...) {}
            precipNode = nullptr;
        }
    }
};

class AtmosphereSystem : public ISimulationSystem {
public:
    std::shared_ptr<VolumetricAtmosphereSubSystem> sky_sub;
    std::shared_ptr<HorizonParallaxSubSystem> parallax_sub;
    std::shared_ptr<DynamicWeatherSubSystem> weather_sub;

    std::string getName() const override { return "AtmosphereSystem"; }

    AtmosphereSystem() {
        sky_sub = std::make_shared<VolumetricAtmosphereSubSystem>();
        parallax_sub = std::make_shared<HorizonParallaxSubSystem>();
        weather_sub = std::make_shared<DynamicWeatherSubSystem>();

        parallax_sub->sky_system = sky_sub->sky_system;
        weather_sub->sky_system = sky_sub->sky_system;

        addSubSystem(sky_sub);
        addSubSystem(parallax_sub);
        addSubSystem(weather_sub);
    }

    std::shared_ptr<Weather::DynamicWeatherSystem> getWeatherSystem() const {
        return weather_sub ? weather_sub->weather_system : nullptr;
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// 4. ECOLOGY SYSTEM & SUBSYSTEMS
// ═══════════════════════════════════════════════════════════════════════════════

class ProceduralFloraSubSystem : public ISimulationSubSystem {
public:
    std::unique_ptr<WFC::HierarchicalSolver> wfc_solver;
    std::unique_ptr<Vegetation::IslandVegetationSystem> veg_system;
    Ogre::SceneNode* vegNode = nullptr;
    Ogre::ManualObject* vegMesh = nullptr;

    std::string getName() const override { return "ProceduralFloraSubSystem"; }

    ProceduralFloraSubSystem() {
        veg_system = std::make_unique<Vegetation::IslandVegetationSystem>();
    }

    void initialize(SystemContext& ctx) override {
        if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()) {
            vegMesh = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->createManualObject("VegetationMeshObj");
            vegMesh->setDynamic(true);
            vegMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_MAIN);
            vegNode = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->getRootSceneNode()->createChildSceneNode("VegetationNode");
            vegNode->attachObject(vegMesh);
        }
    }

    void prepare(LoadingContext& ctx, SystemContext& sysCtx) override {
        ctx.update(0.42f, "Propagating WFC Biome Constraints", "Hierarchical 6-biome constraint solver", "WFC_SOLVER");
        auto island_sub = sysCtx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
        if (island_sub && island_sub->voxel_island) {
            wfc_solver = std::make_unique<WFC::HierarchicalSolver>(island_sub->voxel_island->dim_x, island_sub->voxel_island->dim_z, 8);
            wfc_solver->solveBiomes(
                island_sub->voxel_island->center_x, island_sub->voxel_island->center_z,
                island_sub->voxel_island->island_radius, island_sub->voxel_island->caldera_radius,
                [&](int x,int z){
                    float dx=float(x)-island_sub->voxel_island->center_x, dz=float(z)-island_sub->voxel_island->center_z;
                    float r=std::sqrt(dx*dx+dz*dz);
                    float th=std::atan2(dz,dx);
                    float ad=std::abs(th-Island::VoxelIsland::RIVER_ANGLE);
                    if(ad>3.14159f) ad=6.28318f-ad;
                    return r<island_sub->voxel_island->island_radius*.95f && r*ad<4.5f;
                }, island_sub->seed);
            wfc_solver->solveFeatures(
                [&](float x,float z){ return island_sub->voxel_island->noise_flora.noise(x*.28f,0.f,z*.28f); }, island_sub->seed);

            ctx.update(0.96f, "Synthesizing Weber-Penn Flora Instances", "Synthesizing botanical mesh buffers", "FLORA_WFC");
            if (veg_system) {
                veg_system->populateIsland(*island_sub->voxel_island, *wfc_solver);
            }
        }
    }

    void updateSim(float dt, const UserInputState& input, SimContext& ctx) override {
        (void)dt; (void)input;
        auto atmo_sub = ctx.subjects.getFirstSubjectOfType<AtmosphereSubject>(SubjectType::ATMOSPHERE);
        if (veg_system && atmo_sub) {
            float rad = atmo_sub->wind_direction_radians;
            veg_system->wind_dir = Spatial::Vector3D(std::cos(rad), 0.0f, std::sin(rad));
            veg_system->wind_speed = std::max(0.8f, atmo_sub->wind_speed * 0.45f);
            veg_system->wind_strength = 0.35f + std::min(0.65f, atmo_sub->wind_speed * 0.04f);
        }
    }

    void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) override {
        if (veg_system && vegMesh) {
            veg_system->updateVegetationMesh(vegMesh, dt);
        }
    }

    void handleEvent(const ISimulationEvent& event, SimContext& ctx) override {
        if (event.getEventType() == EventType::ISLAND_VOYAGE) {
            auto island_sub = ctx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
            if (island_sub && island_sub->voxel_island && wfc_solver && veg_system && vegMesh) {
                wfc_solver->solveBiomes(
                    island_sub->voxel_island->center_x, island_sub->voxel_island->center_z,
                    island_sub->voxel_island->island_radius, island_sub->voxel_island->caldera_radius,
                    [&](int x,int z){
                        float dx=float(x)-island_sub->voxel_island->center_x, dz=float(z)-island_sub->voxel_island->center_z;
                        float r=std::sqrt(dx*dx+dz*dz);
                        float th=std::atan2(dz,dx);
                        float ad=std::abs(th-Island::VoxelIsland::RIVER_ANGLE);
                        if(ad>3.14159f) ad=6.28318f-ad;
                        return r<island_sub->voxel_island->island_radius*.95f && r*ad<4.5f;
                    }, island_sub->seed);
                veg_system->populateIsland(*island_sub->voxel_island, *wfc_solver);
                veg_system->updateVegetationMesh(vegMesh, 0.0f);
            }
        }
    }

    void cleanup(RenderContext& renderCtx) override {
        auto* scnMgr = renderCtx.getSceneManager<Ogre::SceneManager>();
        if (vegMesh && scnMgr) {
            try { if (scnMgr->hasManualObject(vegMesh->getName())) scnMgr->destroyManualObject(vegMesh); } catch (...) {}
            vegMesh = nullptr;
        }
        if (vegNode && scnMgr) {
            try { if (scnMgr->hasSceneNode(vegNode->getName())) scnMgr->destroySceneNode(vegNode); } catch (...) {}
            vegNode = nullptr;
        }
    }
};

class BoidFaunaSubSystem : public ISimulationSubSystem {
public:
    std::unique_ptr<Boids::MultiSpeciesBoidSystem> boid_system;
    Ogre::SceneNode* boidNode = nullptr;
    Ogre::ManualObject* boidMesh = nullptr;
    std::vector<Ogre::Light*> firefly_lights;
    std::vector<Ogre::SceneNode*> firefly_nodes;
    float pulse_time_ = 0.0f;

    std::string getName() const override { return "BoidFaunaSubSystem"; }

    BoidFaunaSubSystem() {
        boid_system = std::make_unique<Boids::MultiSpeciesBoidSystem>();
    }

    void initialize(SystemContext& ctx) override {
        if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()) {
            boidMesh = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->createManualObject("BoidMeshObj");
            boidMesh->setDynamic(true);
            boidMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_MAIN);
            boidNode = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->getRootSceneNode()->createChildSceneNode("BoidNode");
            boidNode->attachObject(boidMesh);

            for (size_t i = 0; i < 6; ++i) {
                std::string l_name = "FireflyLight_" + std::to_string(i);
                std::string n_name = "FireflyNode_" + std::to_string(i);
                auto* light = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->createLight(l_name);
                light->setType(Ogre::Light::LT_POINT);
                light->setDiffuseColour(0.45f, 1.0f, 0.25f);
                light->setSpecularColour(0.6f, 1.0f, 0.4f);
                light->setAttenuation(18.0f, 1.0f, 0.14f, 0.07f);

                auto* node = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->getRootSceneNode()->createChildSceneNode(n_name);
                node->attachObject(light);
                firefly_lights.push_back(light);
                firefly_nodes.push_back(node);
            }
        }
    }

    void prepare(LoadingContext& ctx, SystemContext& sysCtx) override {
        ctx.update(0.98f, "Initializing 4D Boid Ecosystem", "Avian gulls, jungle parrots, marine fish", "BOID_FAUNA");
        auto island_sub = sysCtx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
        if (boid_system && island_sub && island_sub->voxel_island) {
            boid_system->initialize(*island_sub->voxel_island);
        }
    }

    void updateSim(float dt, const UserInputState& input, SimContext& ctx) override {
        (void)input;
        auto island_sub = ctx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
        auto atmo_sub = ctx.subjects.getFirstSubjectOfType<AtmosphereSubject>(SubjectType::ATMOSPHERE);
        if (boid_system && island_sub && island_sub->voxel_island) {
            if (atmo_sub) {
                boid_system->setWeatherStormIntensity(atmo_sub->precipitation_rate_mm_h / 40.0f + atmo_sub->volcanic_ash_fraction * 0.5f);
            }
            boid_system->update(dt, *island_sub->voxel_island);
        }
    }

    void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) override {
        auto island_sub = simCtx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
        auto atmo_sub = simCtx.subjects.getFirstSubjectOfType<AtmosphereSubject>(SubjectType::ATMOSPHERE);
        if (boid_system && boidMesh && island_sub && island_sub->voxel_island) {
            boid_system->updateBoidMesh(boidMesh, dt, *island_sub->voxel_island);

            // Update fireflies with continuous pulse animation
            float tod = atmo_sub ? atmo_sub->time_of_day_hours : 12.0f;
            bool is_night = (tod < 6.0f || tod > 18.5f);
            float night_factor = 0.0f;
            if (is_night) {
                // Smooth fade in/out at dawn/dusk
                if (tod < 6.0f) night_factor = std::min(1.0f, (6.0f - tod) / 2.0f);
                else night_factor = std::min(1.0f, (tod - 18.5f) / 2.0f);
            }
            pulse_time_ += dt;

            auto firefly_positions = boid_system->getFireflyLightPositions(firefly_lights.size());
            for (size_t i = 0; i < firefly_lights.size(); ++i) {
                // Per-light sinusoidal pulse with offset phase
                float phase = pulse_time_ * 2.5f + i * 1.7f;
                float pulse = 0.35f + 0.65f * (0.5f + 0.5f * std::sin(phase));
                float intensity = night_factor * pulse;

                firefly_lights[i]->setVisible(intensity > 0.01f);
                firefly_lights[i]->setDiffuseColour(
                    0.45f * intensity, 1.0f * intensity, 0.25f * intensity);
                if (i < firefly_positions.size()) {
                    firefly_nodes[i]->setPosition(firefly_positions[i]);
                }
            }
        }
    }

    void handleEvent(const ISimulationEvent& event, SimContext& ctx) override {
        if (event.getEventType() == EventType::ISLAND_VOYAGE) {
            auto island_sub = ctx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
            if (boid_system && island_sub && island_sub->voxel_island && boidMesh) {
                boid_system->initialize(*island_sub->voxel_island);
                boid_system->updateBoidMesh(boidMesh, 0.0f, *island_sub->voxel_island);
            }
        }
    }

    void cleanup(RenderContext& renderCtx) override {
        auto* scnMgr = renderCtx.getSceneManager<Ogre::SceneManager>();
        if (boidMesh && scnMgr) {
            try { if (scnMgr->hasManualObject(boidMesh->getName())) scnMgr->destroyManualObject(boidMesh); } catch (...) {}
            boidMesh = nullptr;
        }
        if (boidNode && scnMgr) {
            try { if (scnMgr->hasSceneNode(boidNode->getName())) scnMgr->destroySceneNode(boidNode); } catch (...) {}
            boidNode = nullptr;
        }
        for (auto* light : firefly_lights) {
            try { if (scnMgr && scnMgr->hasLight(light->getName())) scnMgr->destroyLight(light); } catch (...) {}
        }
        firefly_lights.clear();
        for (auto* node : firefly_nodes) {
            try { if (scnMgr && scnMgr->hasSceneNode(node->getName())) scnMgr->destroySceneNode(node); } catch (...) {}
        }
        firefly_nodes.clear();
    }
};

class EcologySystem : public ISimulationSystem {
public:
    std::string getName() const override { return "EcologySystem"; }

    EcologySystem() {
        addSubSystem(std::make_shared<ProceduralFloraSubSystem>());
        addSubSystem(std::make_shared<BoidFaunaSubSystem>());
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// 5. INTERACTION SYSTEM & SUBSYSTEMS
// ═══════════════════════════════════════════════════════════════════════════════

class PlayerKinematicsSubSystem : public ISimulationSubSystem {
public:
    const float walk_speed           = 4.25f;
    const float sprint_speed         = 8.0f;
    const float jump_velocity        = 5.8f;
    const float double_jump_velocity = 5.4f;
    const float double_jump_thrust   = 3.4f;
    const float gravity              = -10.0f;
    bool prev_jump_input = false;

    std::string getName() const override { return "PlayerKinematicsSubSystem"; }

    void updateSim(float dt, const UserInputState& input, SimContext& ctx) override {
        auto player_sub = ctx.subjects.getFirstSubjectOfType<PlayerSubject>(SubjectType::PLAYER);
        auto island_sub = ctx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
        if (!player_sub || !island_sub || !island_sub->voxel_island) return;

        auto& p = *player_sub;
        const auto& island = *island_sub->voxel_island;

        // 1. Mouse Look Angles
        p.yaw   += input.mouse_dx;
        p.pitch += input.mouse_dy;
        p.pitch = std::max(-1.45f, std::min(1.45f, p.pitch));

        // 2. Movement Direction
        // Check water immersion
        bool in_water = (p.position.y < island.sea_level);
        p.in_water = in_water;

        // 2. Movement Direction (in 3D when swimming!)
        float fwd_x = -std::sin(p.yaw) * (in_water ? std::cos(p.pitch) : 1.0f);
        float fwd_y = in_water ? std::sin(p.pitch) : 0.0f;
        float fwd_z = -std::cos(p.yaw) * (in_water ? std::cos(p.pitch) : 1.0f);
        float rgt_x =  std::cos(p.yaw);
        float rgt_z = -std::sin(p.yaw);

        float speed = input.sprint ? sprint_speed : walk_speed;
        if (in_water) speed *= 0.65f; // Water fluid drag speed reduction

        float move_x = 0.0f, move_y = 0.0f, move_z = 0.0f;

        if (input.move_forward)  { move_x += fwd_x; move_y += fwd_y; move_z += fwd_z; }
        if (input.move_backward) { move_x -= fwd_x; move_y -= fwd_y; move_z -= fwd_z; }
        if (input.move_right)    { move_x += rgt_x; move_z += rgt_z; }
        if (input.move_left)     { move_x -= rgt_x; move_z -= rgt_z; }

        float move_len = std::sqrt(move_x * move_x + move_y * move_y + move_z * move_z);
        if (move_len > 0.001f) {
            move_x = (move_x / move_len) * speed;
            move_y = (move_y / move_len) * speed;
            move_z = (move_z / move_len) * speed;
        }

        // 3. Ground & Height Sampling
        float ground_h = island.getIslandHeight(p.position.x, p.position.z);
        float dist_to_ground = p.position.y - ground_h;
        bool physically_grounded = (dist_to_ground <= 0.15f) && !in_water;

        if (physically_grounded) {
            p.coyote_timer = 0.18f;
            p.jump_count = 0;
            p.on_ground = true;
        } else {
            p.coyote_timer = std::max(0.0f, p.coyote_timer - dt);
            p.on_ground = false;
        }

        // 4. Jump Buffer
        if (input.jump && !prev_jump_input) {
            p.jump_buffer = 0.15f;
        } else {
            p.jump_buffer = std::max(0.0f, p.jump_buffer - dt);
        }

        // 5. Jump / Swim Execution
        if (in_water) {
            // Buoyancy force lifts player towards ocean surface
            float depth = island.sea_level - p.position.y;
            float buoyancy = std::max(-1.0f, std::min(4.5f, (depth - 0.2f) * 6.5f));
            p.velocity.y += (buoyancy + gravity * 0.20f) * dt;
            p.velocity.y *= std::max(0.0f, 1.0f - 1.8f * dt); // Viscous fluid damping

            // Direct Swimming Controls
            if (input.jump) {
                if (p.position.y >= island.sea_level - 0.35f && (input.jump && !prev_jump_input)) {
                    p.velocity.y = jump_velocity; // Surface breach exit leap!
                } else {
                    p.velocity.y = 3.2f; // Continuous swimming ascent
                }
            }
            if (input.crouch) {
                p.velocity.y = -3.0f; // Swimming dive downwards
            }
            if (std::abs(move_y) > 0.1f) {
                p.velocity.y += move_y * 0.6f;
            }
        } else {
            // Standard Ground Jump & Gravity
            if (p.jump_buffer > 0.0f) {
                if (p.coyote_timer > 0.0f || p.on_ground) {
                    p.velocity.y = jump_velocity;
                    p.jump_count = 1;
                    p.coyote_timer = 0.0f;
                    p.jump_buffer = 0.0f;
                    p.on_ground = false;
                    ctx.events.publishAsync(std::make_shared<PlayerJumpedEvent>(1, p.position));
                } else if (p.jump_count == 1) {
                    p.velocity.y = double_jump_velocity;
                    if (move_len > 0.001f) {
                        p.velocity.x += (move_x / speed) * double_jump_thrust;
                        p.velocity.z += (move_z / speed) * double_jump_thrust;
                    }
                    p.jump_count = 2;
                    p.jump_buffer = 0.0f;
                    ctx.events.publishAsync(std::make_shared<PlayerJumpedEvent>(2, p.position));
                }
            }

            p.velocity.y += gravity * dt;
            p.velocity.y = std::max(-28.0f, p.velocity.y);
        }
        prev_jump_input = input.jump;

        // 6. Kinematic Integration
        float h_drag = in_water ? 0.70f : (p.on_ground ? 0.82f : 0.94f);
        p.velocity.x = move_x * (1.0f - h_drag) + p.velocity.x * h_drag;
        p.velocity.z = move_z * (1.0f - h_drag) + p.velocity.z * h_drag;

        Spatial::Point3D old_pos = p.position;
        p.position.x += p.velocity.x * dt;
        p.position.y += p.velocity.y * dt;
        p.position.z += p.velocity.z * dt;

        // 7. Terrain Collision & Step-up
        float new_ground_h = island.getIslandHeight(p.position.x, p.position.z);
        if (p.position.y < new_ground_h) {
            p.position.y = new_ground_h;
            p.velocity.y = std::max(0.0f, p.velocity.y);
            if (!in_water) {
                p.on_ground = true;
                p.jump_count = 0;
                p.coyote_timer = 0.18f;
            }
        }

        // 8. Smooth Eye Level
        float target_eye_y = p.position.y + p.eye_height;
        p.smooth_eye_y += (target_eye_y - p.smooth_eye_y) * std::min(1.0f, dt * 18.0f);
        p.selected_hotbar_slot = input.selected_hotbar_slot;

        // Raise movement event
        ctx.events.publishAsync(std::make_shared<PlayerMovedEvent>(old_pos, p.position, p.velocity, p.on_ground));
    }

    void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) override {
        (void)dt;
        auto player_sub = simCtx.subjects.getFirstSubjectOfType<PlayerSubject>(SubjectType::PLAYER);
        auto* cam = renderCtx.getCamera<Ogre::Camera>();
        if (player_sub && cam) {
            auto* camNode = cam->getParentSceneNode();
            if (camNode) {
                camNode->setPosition(player_sub->position.x, player_sub->smooth_eye_y, player_sub->position.z);
                auto q = Spatial::Quaternion::fromEuler(player_sub->pitch, player_sub->yaw, 0.0f);
                camNode->setOrientation(Ogre::Quaternion(q.w, q.x, q.y, q.z));
            }
        }
    }
};

class WaylandCompositorSubSystem : public ISimulationSubSystem {
public:
    Display::InWorldDisplaySystem waylandDisplay;
    Ogre::SceneNode* displayNode = nullptr;
    Ogre::ManualObject* displayMesh = nullptr;
    bool last_mouse_left_ = false;
    bool last_mouse_right_ = false;
    bool display_visible_ = false;

    std::string getName() const override { return "WaylandCompositorSubSystem"; }

    void initialize(SystemContext& ctx) override {
        // Initialize Wayland Embedded Display Server
        Wayland::WaylandCompositor::get().initialize("wayland-scr-0");

        if (ctx.renderCtx.getSceneManager<Ogre::SceneManager>()) {
            Ogre::Vector3 world_pos(124.0f, 15.0f, 10.0f);
            Ogre::Vector3 look_target(124.0f, 15.0f, 12.0f);
            waylandDisplay.initialize(ctx.renderCtx.getSceneManager<Ogre::SceneManager>(), world_pos, look_target);
            waylandDisplay.is_visible = false;

            displayMesh = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->createManualObject("InWorldDisplayMeshObj");
            displayMesh->setDynamic(true);
            displayNode = ctx.renderCtx.getSceneManager<Ogre::SceneManager>()->getRootSceneNode()->createChildSceneNode("InWorldDisplayNode");
            displayNode->attachObject(displayMesh);
            displayNode->setVisible(false);
        }
    }

    void updateSim(float dt, const UserInputState& input, SimContext& ctx) override {
        (void)dt;
        // Forward mouse buttons to Wayland compositor
        if (display_visible_) {
            if (input.action_primary && !last_mouse_left_) {
                Wayland::WaylandCompositor::get().sendPointerButton(0, 0x110, true);
            } else if (!input.action_primary && last_mouse_left_) {
                Wayland::WaylandCompositor::get().sendPointerButton(0, 0x110, false);
            }
            if (input.action_secondary && !last_mouse_right_) {
                Wayland::WaylandCompositor::get().sendPointerButton(0, 0x111, true);
            } else if (!input.action_secondary && last_mouse_right_) {
                Wayland::WaylandCompositor::get().sendPointerButton(0, 0x111, false);
            }
            last_mouse_left_ = input.action_primary;
            last_mouse_right_ = input.action_secondary;
        }
    }

    void renderSync(RenderContext& renderCtx, const SimContext& simCtx, float dt) override {
        Wayland::WaylandCompositor::get().dispatch(0);
        if (displayMesh) {
            waylandDisplay.update(displayMesh, dt, Wayland::WaylandCompositor::get());
            if (displayNode) {
                display_visible_ = waylandDisplay.is_visible;
                displayNode->setVisible(display_visible_);
            }
        }
    }

    void cleanup(RenderContext& renderCtx) override {
        auto* scnMgr = renderCtx.getSceneManager<Ogre::SceneManager>();
        if (displayMesh && scnMgr) {
            try { if (scnMgr->hasManualObject(displayMesh->getName())) scnMgr->destroyManualObject(displayMesh); } catch (...) {}
            displayMesh = nullptr;
        }
        if (displayNode && scnMgr) {
            try { if (scnMgr->hasSceneNode(displayNode->getName())) scnMgr->destroySceneNode(displayNode); } catch (...) {}
            displayNode = nullptr;
        }
    }
};

class NauticalVoyageSubSystem : public ISimulationSubSystem {
public:
    Navigation::NauticalNavigator nautical_nav;

    std::string getName() const override { return "NauticalVoyageSubSystem"; }

    void setSailForBiome(Island::IslandBiomeType biome, SimContext& ctx) {
        auto island_sub = ctx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
        auto player_sub = ctx.subjects.getFirstSubjectOfType<PlayerSubject>(SubjectType::PLAYER);
        if (!island_sub || !island_sub->voxel_island) return;

        auto prev_biome = island_sub->active_biome;
        island_sub->active_biome = biome;
        island_sub->seed = 1337 + (int)biome * 7919;
        island_sub->voxel_island->setBiome(biome);
        island_sub->voxel_island->generateProceduralIsland(island_sub->seed);
        island_sub->peak_height = island_sub->voxel_island->peak_height;
        island_sub->island_radius = island_sub->voxel_island->island_radius;

        Spatial::Point3D spawn_pos = island_sub->voxel_island->findBeachSpawnPosition();
        if (player_sub) {
            player_sub->position = spawn_pos;
            player_sub->velocity = Spatial::Vector3D(0, 0, 0);
            player_sub->smooth_eye_y = spawn_pos.y + player_sub->eye_height;
            float dx = island_sub->voxel_island->center_x - spawn_pos.x;
            float dz = island_sub->voxel_island->center_z - spawn_pos.z;
            player_sub->yaw = std::atan2(dx, -dz);
            player_sub->pitch = -0.05f;
        }

        const auto& desc = Island::ArchipelagoRegistry::getDescriptor(biome);
        std::cout << "[Archipelago] Arrived at " << desc.name << " (" << spawn_pos.x << ", " << spawn_pos.y << ", " << spawn_pos.z << ")" << std::endl;

        // Broadcast voyage event to all systems
        ctx.events.publishSync(IslandVoyageEvent(prev_biome, biome, island_sub->seed, spawn_pos));
    }
};

class InteractionSystem : public ISimulationSystem {
public:
    std::string getName() const override { return "InteractionSystem"; }

    InteractionSystem() {
        addSubSystem(std::make_shared<PlayerKinematicsSubSystem>());
        addSubSystem(std::make_shared<WaylandCompositorSubSystem>());
        addSubSystem(std::make_shared<NauticalVoyageSubSystem>());
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// 6. CONCURRENT SYSTEM COORDINATOR
// ═══════════════════════════════════════════════════════════════════════════════


} // namespace SCR::Simulation

#endif // CAVE_OGRE_SUBSYSTEMS_HPP
