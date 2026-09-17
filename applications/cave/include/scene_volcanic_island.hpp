#ifndef CAVE_SCENE_VOLCANIC_ISLAND_HPP
#define CAVE_SCENE_VOLCANIC_ISLAND_HPP

#include <memory>
#include <sstream>
#include <iostream>

#include "simulation_framework.hpp"
#include "simulation_subjects.hpp"
#include "simulation_events.hpp"
#include "simulation_systems.hpp"
#include "bullet_physics_subsystem.hpp"
#include "island_hud.hpp"

namespace SCR::Simulation {

class PhysicsDynamicsSystem : public ISimulationSystem {
public:
    std::string getName() const override { return "PhysicsDynamicsSystem"; }

    PhysicsDynamicsSystem() {
        addSubSystem(std::make_shared<BulletPhysicsSubSystem>());
    }
};

/**
 * VolcanicIslandScene Refactored to Modular Concurrent Systems & Sub-Systems.
 * - Subjects: PlayerSubject, IslandSubject, AtmosphereSubject, HydrologySubject, VolcanoSubject, EcologySubject, WaylandDisplaySubject.
 * - Systems: GeologySystem, HydrologySystem, AtmosphereSystem, EcologySystem, InteractionSystem, PhysicsDynamicsSystem.
 * - Concurrency: ConcurrentSystemCoordinator dispatches async physics/kinematics/noise steps on worker threads.
 * - Events: EventBus handles decoupled messaging with subject tracking.
 */
class VolcanicIslandScene : public ISimulationScene {
public:
    // Core Infrastructure
    SubjectRegistry subjects;
    EventBus events;
    ConcurrentSystemCoordinator coordinator;

    // Subjects
    std::shared_ptr<PlayerSubject> player_subject;
    std::shared_ptr<IslandSubject> island_subject;
    std::shared_ptr<AtmosphereSubject> atmo_subject;
    std::shared_ptr<HydrologySubject> hydro_subject;
    std::shared_ptr<VolcanoSubject> volcano_subject;
    std::shared_ptr<EcologySubject> ecology_subject;
    std::shared_ptr<WaylandDisplaySubject> wayland_subject;

    // HUD & Interaction State
    HUD::IslandHUD hud;
    uint16_t active_hotbar_mat = Material::MAT_BASALT;
    bool ray_hit = false;
    uint16_t ray_mat_code = Material::MAT_AIR;
    float ray_distance = 0.0f;
    bool screen_focused = false;
    float screen_u = 0.5f;
    float screen_v = 0.5f;
    Spatial::PartitionType active_partition = Spatial::PartitionType::CALDERA_SUMMIT;

    VolcanicIslandScene()
        : coordinator(subjects, events) {
        // Instantiate Subject Objects
        player_subject = std::make_shared<PlayerSubject>();
        island_subject = std::make_shared<IslandSubject>();
        atmo_subject = std::make_shared<AtmosphereSubject>();
        hydro_subject = std::make_shared<HydrologySubject>();
        volcano_subject = std::make_shared<VolcanoSubject>();
        ecology_subject = std::make_shared<EcologySubject>();
        wayland_subject = std::make_shared<WaylandDisplaySubject>();

        // Register Subjects in SubjectRegistry
        subjects.registerSubject(player_subject);
        subjects.registerSubject(island_subject);
        subjects.registerSubject(atmo_subject);
        subjects.registerSubject(hydro_subject);
        subjects.registerSubject(volcano_subject);
        subjects.registerSubject(ecology_subject);
        subjects.registerSubject(wayland_subject);

        // Register Systems in ConcurrentSystemCoordinator
        coordinator.registerSystem(std::make_shared<GeologySystem>());
        coordinator.registerSystem(std::make_shared<HydrologySystem>());
        coordinator.registerSystem(std::make_shared<AtmosphereSystem>());
        coordinator.registerSystem(std::make_shared<EcologySystem>());
        coordinator.registerSystem(std::make_shared<InteractionSystem>());
        coordinator.registerSystem(std::make_shared<PhysicsDynamicsSystem>());

        // Subscribe to IslandVoyageEvent to update partition tracking
        events.subscribe<IslandVoyageEvent>([this](const IslandVoyageEvent& evt) {
            std::cout << "[Scene] Received IslandVoyageEvent: transition from biome " 
                      << (int)evt.previous_biome << " to " << (int)evt.new_biome << std::endl;
        });

        // Subscribe to PlayerJumpedEvent for sound / visual telemetry
        events.subscribe<PlayerJumpedEvent>([](const PlayerJumpedEvent& evt) {
            std::cout << "[Kinematics] Player performed Jump #" << evt.jump_index 
                      << " at (" << evt.jump_location.x << ", " << evt.jump_location.y << ", " << evt.jump_location.z << ")" << std::endl;
        });
    }

    SceneMetadata getMetadata() const override {
        return {
            "volcanic_island",
            "Volcanic Island & OpenVDB Natural Isosurface (Concurrent Systems)",
            "OpenVDB Geomorphology, Molten Magma River & Caldera Plume",
            "Volcanology & Computational Geomorphology",
            "Active stratovolcano with Bingham plastic lava river, buoyant convective ash chimney, Sea of Thieves multi-spectral ocean swells, and Red Dead Redemption 2 multi-tier volumetric atmosphere dome executed via concurrent Systems and Sub-Systems.",
            "SCR-DOM-008 (Render/Volcano) & SCR-DOM-004 (Topology/Isosurface)",
            "SCR Core Architecture Team",
            "3.3.0",
            {"Concurrent-Systems", "Subject-Objects", "Event-Bus", "OpenVDB", "Bingham-Fluid", "Gerstner-Ocean", "RDR2-Atmosphere", "WFC-Biomes"}
        };
    }

    void prepare(LoadingContext& ctx) override {
        ctx.update(0.05f, "Ingesting Semantic Material Registry", "101 materials registered", "MATERIAL_REGISTRY");
        (void)Material::MaterialRegistry::instance();

        // Prepare systems
        coordinator.prepare(ctx);

        // Position player at scenic spawn location
        if (island_subject && island_subject->voxel_island) {
            Spatial::Point3D spawn_pos = island_subject->voxel_island->findBeachSpawnPosition();
            if (player_subject) {
                player_subject->position = spawn_pos;
                player_subject->smooth_eye_y = spawn_pos.y + player_subject->eye_height;
                float dx = island_subject->voxel_island->center_x - spawn_pos.x;
                float dz = island_subject->voxel_island->center_z - spawn_pos.z;
                player_subject->yaw = std::atan2(dx, -dz);
                player_subject->pitch = -0.05f;
            }
        }

        ctx.update(1.0f, "Simulation Scene Ready", "Committing GPU vertex buffers", "GPU_STREAM");
    }

    void initScene(Ogre::SceneManager* scnMgr, Ogre::Camera* cam, Ogre::RenderWindow* win) override {
        cam->setNearClipDistance(0.05f);
        cam->setFarClipDistance(12000.0f);

        coordinator.setOgreContext(scnMgr, cam, win);
        coordinator.initialize();
    }

    void update(float dt, const UserInputState& input) override {
        // Execute concurrent simulation tick & GPU render synchronization
        coordinator.update(dt, input);

        // Perform raycast for player interaction
        if (island_subject && island_subject->voxel_island && player_subject) {
            float ray_ox = player_subject->position.x;
            float ray_oy = player_subject->smooth_eye_y;
            float ray_oz = player_subject->position.z;

            float dir_x = -std::sin(player_subject->yaw) * std::cos(player_subject->pitch);
            float dir_y =  std::sin(player_subject->pitch);
            float dir_z = -std::cos(player_subject->yaw) * std::cos(player_subject->pitch);

            ray_hit = false;
            float t = 0.5f;
            while (t < 18.0f) {
                float sx = ray_ox + dir_x * t;
                float sy = ray_oy + dir_y * t;
                float sz = ray_oz + dir_z * t;

                int vx = (int)std::floor(sx);
                int vy = (int)std::floor(sy);
                int vz = (int)std::floor(sz);

                if (island_subject->voxel_island->inBounds(vx, vy, vz)) {
                    uint16_t mat = island_subject->voxel_island->getVoxel(vx, vy, vz);
                    if (mat != Material::MAT_AIR && mat != Material::MAT_WATER) {
                        ray_hit = true;
                        ray_mat_code = mat;
                        ray_distance = t;
                        break;
                    }
                }
                t += 0.35f;
            }
        }

        // Update Wayland in-world terminal focus and pointer motion
        auto interact_sys = coordinator.getSystem<InteractionSystem>();
        if (interact_sys && player_subject) {
            for (auto& sub : interact_sys->getSubSystems()) {
                if (auto comp_sub = std::dynamic_pointer_cast<WaylandCompositorSubSystem>(sub)) {
                    Ogre::Vector3 ray_orig(player_subject->position.x, player_subject->smooth_eye_y, player_subject->position.z);
                    float dir_x = -std::sin(player_subject->yaw) * std::cos(player_subject->pitch);
                    float dir_y =  std::sin(player_subject->pitch);
                    float dir_z = -std::cos(player_subject->yaw) * std::cos(player_subject->pitch);
                    Ogre::Ray center_ray(ray_orig, Ogre::Vector3(dir_x, dir_y, dir_z).normalisedCopy());
                    
                    float dist = 0.0f;
                    screen_focused = comp_sub->waylandDisplay.raycast(center_ray, screen_u, screen_v, dist);
                    if (screen_focused) {
                        auto* surf = Wayland::WaylandCompositor::get().getPrimarySurface();
                        if (surf) {
                            int px = int(screen_u * surf->configured_width);
                            int py = int(screen_v * surf->configured_height);
                            Wayland::WaylandCompositor::get().sendPointerMotion(surf->id, px, py);
                        }
                    }
                }
            }
        }
    }

    void warpToIsland(Island::IslandBiomeType biome) {
        auto interact_sys = coordinator.getSystem<InteractionSystem>();
        if (interact_sys) {
            for (auto& sub : interact_sys->getSubSystems()) {
                if (auto voyage_sub = std::dynamic_pointer_cast<NauticalVoyageSubSystem>(sub)) {
                    voyage_sub->setSailForBiome(biome, coordinator.getContext());
                    return;
                }
            }
        }
    }

    void warpToPartition(Spatial::PartitionType type) {
        if (!island_subject || !island_subject->voxel_island || !player_subject) return;
        const auto& island = *island_subject->voxel_island;
        switch (type) {
            case Spatial::PartitionType::CALDERA_SUMMIT:
                player_subject->position = Spatial::Point3D(island.center_x, island.peak_height + 2.0f, island.center_z);
                break;
            case Spatial::PartitionType::RAINFOREST_CANOPY:
                player_subject->position = Spatial::Point3D(island.center_x + 90.0f, island.getIslandHeight(island.center_x + 90.0f, island.center_z + 90.0f) + 1.2f, island.center_z + 90.0f);
                break;
            case Spatial::PartitionType::BASALT_CLIFFS:
                player_subject->position = Spatial::Point3D(island.center_x - 90.0f, island.getIslandHeight(island.center_x - 90.0f, island.center_z - 90.0f) + 1.2f, island.center_z - 90.0f);
                break;
            case Spatial::PartitionType::CORAL_LAGOON:
                player_subject->position = Spatial::Point3D(island.center_x + 85.0f, island.sea_level + 0.5f, island.center_z - 85.0f);
                break;
            case Spatial::PartitionType::SUBTERRANEAN_LAVA_TUBES:
                player_subject->position = Spatial::Point3D(island.center_x, 4.0f, island.center_z);
                break;
            case Spatial::PartitionType::DEEP_OCEAN_ABYSS:
                player_subject->position = Spatial::Point3D(island.center_x + 240.0f, island.sea_level + 0.5f, island.center_z + 240.0f);
                break;
            default:
                break;
        }
        player_subject->velocity = Spatial::Vector3D(0, 0, 0);
        player_subject->smooth_eye_y = player_subject->position.y + player_subject->eye_height;
        active_partition = type;
        std::cout << "[Partition] Traveled to: " 
                  << Spatial::SpatialPartitionRegistry::getDescriptor(type).name 
                  << " (" << player_subject->position.x << ", " << player_subject->position.y << ", " << player_subject->position.z << ")" << std::endl;
    }

    bool handleKeyPress(int key, bool down, bool is_alt_down = false, bool is_ctrl_down = false) override {
        if (screen_focused) {
            Wayland::WaylandCompositor::get().sendKey(key, down);
        }

        if (down) {
            // ── 1. Alt + Number: Sea of Thieves Archipelago Island Voyages ──
            if (is_alt_down) {
                if (key == '1') { warpToIsland(Island::IslandBiomeType::VOLCANO); return true; }
                if (key == '2') { warpToIsland(Island::IslandBiomeType::JUNGLE); return true; }
                if (key == '3') { warpToIsland(Island::IslandBiomeType::DESERT); return true; }
                if (key == '4') { warpToIsland(Island::IslandBiomeType::GLACIAL_ICE); return true; }
                if (key == '5') { warpToIsland(Island::IslandBiomeType::CORAL_ARCHIPELAGO); return true; }
                if (key == '6') { warpToPartition(Spatial::PartitionType::DEEP_OCEAN_ABYSS); return true; }
            }

            // ── 2. Primary Function Keys (F1..F12) ─────────────────────────
            if (key == OgreBites::SDLK_F1) {
                std::cout << "[Wayland] Toggling Wayland Terminal Emulator (F1)..." << std::endl;
                auto interact_sys = coordinator.getSystem<InteractionSystem>();
                if (interact_sys && player_subject) {
                    for (auto& sub : interact_sys->getSubSystems()) {
                        if (auto comp_sub = std::dynamic_pointer_cast<WaylandCompositorSubSystem>(sub)) {
                            comp_sub->waylandDisplay.is_visible = !comp_sub->waylandDisplay.is_visible;
                            if (comp_sub->waylandDisplay.is_visible) {
                                Ogre::Vector3 eye(player_subject->position.x, player_subject->smooth_eye_y, player_subject->position.z);
                                float fwd_x = -std::sin(player_subject->yaw) * std::cos(player_subject->pitch);
                                float fwd_y =  std::sin(player_subject->pitch);
                                float fwd_z = -std::cos(player_subject->yaw) * std::cos(player_subject->pitch);
                                comp_sub->waylandDisplay.summonInFrontOf(eye, Ogre::Vector3(fwd_x, fwd_y, fwd_z), 2.5f);
                                Wayland::WaylandCompositor::get().launchTerminal();
                            } else {
                                if (comp_sub->displayMesh) comp_sub->displayMesh->clear();
                            }
                            if (comp_sub->displayNode) comp_sub->displayNode->setVisible(comp_sub->waylandDisplay.is_visible);
                        }
                    }
                }
                return true;
            }
            if (key == OgreBites::SDLK_F2) {
                std::cout << "[Wayland] Launching Wayland Interactive Demo (F2)..." << std::endl;
                auto interact_sys = coordinator.getSystem<InteractionSystem>();
                if (interact_sys && player_subject) {
                    for (auto& sub : interact_sys->getSubSystems()) {
                        if (auto comp_sub = std::dynamic_pointer_cast<WaylandCompositorSubSystem>(sub)) {
                            comp_sub->waylandDisplay.is_visible = true;
                            Ogre::Vector3 eye(player_subject->position.x, player_subject->smooth_eye_y, player_subject->position.z);
                            float fwd_x = -std::sin(player_subject->yaw) * std::cos(player_subject->pitch);
                            float fwd_y =  std::sin(player_subject->pitch);
                            float fwd_z = -std::cos(player_subject->yaw) * std::cos(player_subject->pitch);
                            comp_sub->waylandDisplay.summonInFrontOf(eye, Ogre::Vector3(fwd_x, fwd_y, fwd_z), 2.5f);
                            if (comp_sub->displayNode) comp_sub->displayNode->setVisible(true);
                        }
                    }
                }
                Wayland::WaylandCompositor::get().launchDemo();
                return true;
            }
            if (key == OgreBites::SDLK_F3) {
                std::cout << "[Wayland] Launching Wayland Text Editor (F3)..." << std::endl;
                auto interact_sys = coordinator.getSystem<InteractionSystem>();
                if (interact_sys && player_subject) {
                    for (auto& sub : interact_sys->getSubSystems()) {
                        if (auto comp_sub = std::dynamic_pointer_cast<WaylandCompositorSubSystem>(sub)) {
                            comp_sub->waylandDisplay.is_visible = true;
                            Ogre::Vector3 eye(player_subject->position.x, player_subject->smooth_eye_y, player_subject->position.z);
                            float fwd_x = -std::sin(player_subject->yaw) * std::cos(player_subject->pitch);
                            float fwd_y =  std::sin(player_subject->pitch);
                            float fwd_z = -std::cos(player_subject->yaw) * std::cos(player_subject->pitch);
                            comp_sub->waylandDisplay.summonInFrontOf(eye, Ogre::Vector3(fwd_x, fwd_y, fwd_z), 2.5f);
                            if (comp_sub->displayNode) comp_sub->displayNode->setVisible(true);
                        }
                    }
                }
                Wayland::WaylandCompositor::get().launchEditor();
                return true;
            }
            if (key == OgreBites::SDLK_F4) {
                std::cout << "[Wayland] Closing Active Wayland Clients (F4)..." << std::endl;
                auto interact_sys = coordinator.getSystem<InteractionSystem>();
                if (interact_sys) {
                    for (auto& sub : interact_sys->getSubSystems()) {
                        if (auto comp_sub = std::dynamic_pointer_cast<WaylandCompositorSubSystem>(sub)) {
                            comp_sub->waylandDisplay.is_visible = false;
                            if (comp_sub->displayMesh) comp_sub->displayMesh->clear();
                            if (comp_sub->displayNode) comp_sub->displayNode->setVisible(false);
                        }
                    }
                }
                Wayland::WaylandCompositor::get().closeClients();
                return true;
            }
            if (key == OgreBites::SDLK_F5) {
                auto atmo_sys = coordinator.getSystem<AtmosphereSystem>();
                if (atmo_sys) {
                    for (auto& sub : atmo_sys->getSubSystems()) {
                        if (auto sky_sub = std::dynamic_pointer_cast<VolumetricAtmosphereSubSystem>(sub)) {
                            if (sky_sub->sky_system) {
                                sky_sub->sky_system->cyclePreset();
                                std::cout << "[Sky] Volumetric Clouds Preset (F5) -> " << sky_sub->sky_system->getPresetName() << std::endl;
                            }
                        }
                    }
                }
                return true;
            }
            if (key == OgreBites::SDLK_F6) {
                auto atmo_sys = coordinator.getSystem<AtmosphereSystem>();
                if (atmo_sys) {
                    for (auto& sub : atmo_sys->getSubSystems()) {
                        if (auto sky_sub = std::dynamic_pointer_cast<VolumetricAtmosphereSubSystem>(sub)) {
                            if (sky_sub->sky_system) {
                                sky_sub->sky_system->setTimeOfDay(sky_sub->sky_system->time_of_day_hours + 1.0f);
                                std::cout << "[Sky] Time of Day (F6) -> " << sky_sub->sky_system->time_of_day_hours << "h" << std::endl;
                            }
                        }
                    }
                }
                return true;
            }
            if (key == OgreBites::SDLK_F7) {
                auto atmo_sys = coordinator.getSystem<AtmosphereSystem>();
                if (atmo_sys) {
                    for (auto& sub : atmo_sys->getSubSystems()) {
                        if (auto sky_sub = std::dynamic_pointer_cast<VolumetricAtmosphereSubSystem>(sub)) {
                            if (sky_sub->sky_system) {
                                sky_sub->sky_system->setTimeOfDay(sky_sub->sky_system->time_of_day_hours - 1.0f);
                                std::cout << "[Sky] Time of Day (F7) -> " << sky_sub->sky_system->time_of_day_hours << "h" << std::endl;
                            }
                        }
                    }
                }
                return true;
            }
            if (key == OgreBites::SDLK_F8) {
                std::cout << "[Storage] Saving World Partition & OpenVDB State to Disk (F8)..." << std::endl;
                auto geo_sys = coordinator.getSystem<GeologySystem>();
                if (geo_sys && player_subject && atmo_subject) {
                    for (auto& sub : geo_sys->getSubSystems()) {
                        if (auto terrain_sub = std::dynamic_pointer_cast<OpenVdbTerrainSubSystem>(sub)) {
                            if (terrain_sub->chunk_manager) {
                                terrain_sub->chunk_manager->saveWorld(
                                    Ogre::Vector3(player_subject->position.x, player_subject->position.y, player_subject->position.z),
                                    atmo_subject->time_of_day_hours,
                                    1337
                                );
                            }
                        }
                    }
                }
                return true;
            }
            if (key == OgreBites::SDLK_F9) {
                std::cout << "[Terrain] Regenerating Procedural Island via System Coordinator (F9)..." << std::endl;
                if (island_subject && island_subject->voxel_island) {
                    unsigned new_seed = (unsigned)std::chrono::system_clock::now().time_since_epoch().count();
                    island_subject->seed = new_seed;
                    island_subject->voxel_island->generateProceduralIsland(new_seed);
                    events.publishSync(IslandVoyageEvent(island_subject->active_biome, island_subject->active_biome, new_seed, player_subject->position));
                }
                return true;
            }
            if (key == OgreBites::SDLK_F10) {
                std::cout << "[Mesh] OpenVDB Natural Smooth Isosurface Mode (F10)" << std::endl;
                return true;
            }
            if (is_ctrl_down) {
                auto w_sys = getWeatherSubsystem();
                if (w_sys) {
                    if (key == '1') { w_sys->setWeather(Weather::WeatherConditionType::CLEAR_TROPICAL, 3.0f); return true; }
                    if (key == '2') { w_sys->setWeather(Weather::WeatherConditionType::OVERCAST_STRATUS, 3.0f); return true; }
                    if (key == '3') { w_sys->setWeather(Weather::WeatherConditionType::TROPICAL_MONSOON, 3.0f); return true; }
                    if (key == '4') { w_sys->setWeather(Weather::WeatherConditionType::VOLCANIC_ASH_TEMPEST, 3.0f); return true; }
                    if (key == '5') { w_sys->setWeather(Weather::WeatherConditionType::MARINE_FOG, 3.0f); return true; }
                    if (key == '6') { w_sys->setWeather(Weather::WeatherConditionType::GOLDEN_HAZE, 3.0f); return true; }
                }
            }

            if (key == OgreBites::SDLK_F12) {
                auto w_sys = getWeatherSubsystem();
                if (w_sys) {
                    w_sys->cycleNextWeather();
                    std::cout << "[Weather] Cycled Weather Condition (F12) -> " << w_sys->target_profile.name << std::endl;
                }
                return true;
            }

            if (key == OgreBites::SDLK_F11) {
                auto hydro_sys = coordinator.getSystem<HydrologySystem>();
                if (hydro_sys) {
                    for (auto& sub : hydro_sys->getSubSystems()) {
                        if (auto ocean_sub = std::dynamic_pointer_cast<GerstnerOceanSubSystem>(sub)) {
                            if (ocean_sub->ocean_system) {
                                ocean_sub->ocean_system->cycleLiquidMethod();
                                std::cout << "[Ocean] Cycle Liquid Wave Shader (F11)" << std::endl;
                            }
                        }
                    }
                }
                return true;
            }
        }

        // Hotbar material selection
        if (!is_alt_down && !is_ctrl_down) {
            if (key == '1') active_hotbar_mat = Material::MAT_BASALT;
            if (key == '2') active_hotbar_mat = Material::MAT_SAND;
            if (key == '3') active_hotbar_mat = Material::MAT_FOLIAGE;
            if (key == '4') active_hotbar_mat = Material::MAT_BAMBOO;
            if (key == '5') active_hotbar_mat = Material::MAT_OBSIDIAN;
            if (key == '6') active_hotbar_mat = Material::MAT_SULFUR;
            if (key == '7') active_hotbar_mat = Material::MAT_ASH;
            if (key == '8') active_hotbar_mat = Material::MAT_LAVA;
            if (key == '9') active_hotbar_mat = Material::MAT_WATER;
        }

        return true;
    }

    void renderHUD(Ogre::ManualObject* hudObj, Ogre::Viewport* vp, float screen_alpha = 1.0f) override {
        (void)vp;
        if (hudObj && screen_alpha > 0.01f && player_subject && island_subject && island_subject->voxel_island) {
            bool in_water = player_subject->position.y <= island_subject->voxel_island->sea_level + 0.3f;
            const auto& part_desc = Spatial::SpatialPartitionRegistry::getDescriptor(active_partition);
            if (atmo_subject) {
                hud.setWeatherState(
                    atmo_subject->weather_condition,
                    atmo_subject->barometric_pressure_hpa,
                    atmo_subject->ambient_temperature_c,
                    atmo_subject->relative_humidity,
                    atmo_subject->precipitation_rate_mm_h,
                    atmo_subject->wind_speed
                );
            }
            hud.renderVectorHUD(
                hudObj,
                screen_alpha,
                0.016f,
                player_subject->position.x, player_subject->position.y, player_subject->position.z,
                player_subject->yaw, player_subject->pitch,
                in_water,
                ray_hit, ray_mat_code, ray_distance,
                60.0f,
                active_hotbar_mat,
                part_desc.code
            );
        }
    }

    std::shared_ptr<BulletPhysicsSubSystem> getPhysicsSubsystem() {
        auto phys_sys = coordinator.getSystem<PhysicsDynamicsSystem>();
        if (phys_sys) {
            for (auto& sub : phys_sys->getSubSystems()) {
                if (auto bsub = std::dynamic_pointer_cast<BulletPhysicsSubSystem>(sub)) {
                    return bsub;
                }
            }
        }
        return nullptr;
    }

    std::shared_ptr<Weather::DynamicWeatherSystem> getWeatherSubsystem() {
        auto atmo_sys = coordinator.getSystem<AtmosphereSystem>();
        if (atmo_sys) {
            return atmo_sys->getWeatherSystem();
        }
        return nullptr;
    }

    void cleanup(Ogre::SceneManager* scnMgr) override {
        coordinator.cleanup(scnMgr);
        subjects.clear();
        events.clear();
    }
};

} // namespace SCR::Simulation

#endif // CAVE_SCENE_VOLCANIC_ISLAND_HPP
