#ifndef CAVE_SCENE_VOLCANIC_ISLAND_HPP
#define CAVE_SCENE_VOLCANIC_ISLAND_HPP

#include <memory>
#include <sstream>

#include "simulation_framework.hpp"
#include "procedural_island.hpp"
#include "hierarchical_wfc.hpp"
#include "vdb_island_mesher.hpp"
#include "ocean_simulation.hpp"
#include "volumetric_clouds.hpp"
#include "volcanic_effects.hpp"
#include "procedural_vegetation.hpp"
#include "boid_semantics.hpp"
#include "horizon_planet_parallax.hpp"
#include "island_hud.hpp"

namespace SCR::Simulation {

class VolcanicIslandScene : public ISimulationScene {
public:
    // Core Domain State
    std::unique_ptr<Island::VoxelIsland> island;
    std::unique_ptr<WFC::HierarchicalSolver> wfc_solver;
    std::unique_ptr<Ocean::SeaOfThievesWater> ocean_system;
    std::unique_ptr<Sky::VolumetricAtmosphere> sky_system;
    std::unique_ptr<Atmosphere::HorizonPlanetParallaxSystem> parallax_system;
    std::unique_ptr<Volcano::VolcanicLavaFlow> lava_system;
    std::unique_ptr<Volcano::VolcanicSmokePlume> smoke_system;
    std::unique_ptr<Vegetation::IslandVegetationSystem> veg_system;
    std::unique_ptr<Boids::MultiSpeciesBoidSystem> boid_system;

    // Player Kinematics
    Spatial::Point3D player_pos;
    Spatial::Vector3D player_vel{0,0,0};
    float player_yaw = 0.0f;
    float player_pitch = 0.14f;
    float smooth_eye_y = 10.0f;
    bool on_ground = false;

    // Speeds & Jump Dynamics (Scaled by 1/2)
    const float walk_speed           = 4.25f;
    const float sprint_speed         = 8.0f;
    const float jump_velocity        = 5.8f;
    const float double_jump_velocity = 5.4f;
    const float double_jump_thrust   = 3.4f;
    const float gravity              = -10.0f;
    int jump_count = 0;
    const int max_jumps = 2;
    float coyote_timer = 0.0f;
    float jump_buffer = 0.0f;
    bool prev_jump_input = false;
    bool in_water = false;

    // Scene Graph
    Ogre::SceneNode* islandNode = nullptr;
    Ogre::ManualObject* islandMesh = nullptr;

    Ogre::SceneNode* oceanNode = nullptr;
    Ogre::ManualObject* oceanMesh = nullptr;

    Ogre::SceneNode* skyNode = nullptr;
    Ogre::ManualObject* skyMesh = nullptr;

    Ogre::SceneNode* parallaxNode = nullptr;
    Ogre::ManualObject* parallaxMesh = nullptr;

    Ogre::SceneNode* lavaNode = nullptr;
    Ogre::ManualObject* lavaMesh = nullptr;

    Ogre::SceneNode* smokeNode = nullptr;
    Ogre::ManualObject* smokeMesh = nullptr;

    Ogre::SceneNode* vegNode = nullptr;
    Ogre::ManualObject* vegMesh = nullptr;

    Ogre::SceneNode* boidNode = nullptr;
    Ogre::ManualObject* boidMesh = nullptr;

    static constexpr size_t NUM_FIREFLY_LIGHTS = 6;
    std::vector<Ogre::Light*>     firefly_lights;
    std::vector<Ogre::SceneNode*> firefly_nodes;

    Ogre::Light* sunLight = nullptr;
    Ogre::Light* caldGlow = nullptr;
    Ogre::Camera* camera = nullptr;
    Ogre::SceneManager* sceneMgr = nullptr;

    HUD::IslandHUD hud;

    VolcanicIslandScene() = default;

    SceneMetadata getMetadata() const override {
        return {
            "volcanic_island",
            "Volcanic Island & OpenVDB Natural Isosurface",
            "OpenVDB Geomorphology, Molten Magma River & Caldera Plume",
            "Volcanology & Computational Geomorphology",
            "Active stratovolcano with Bingham plastic lava river, buoyant convective ash chimney, Sea of Thieves multi-spectral ocean swells, and Red Dead Redemption 2 multi-tier volumetric atmosphere dome.",
            "SCR-DOM-008 (Render/Volcano) & SCR-DOM-004 (Topology/Isosurface)",
            "SCR Core Architecture Team",
            "3.2.0",
            {"OpenVDB", "Bingham-Fluid", "Convective-Plume", "Gerstner-Ocean", "RDR2-Atmosphere", "WFC-Biomes"}
        };
    }

    void prepare(LoadingContext& ctx) override {
        ctx.update(0.05f, "Ingesting Semantic Material Registry", "101 materials registered", "MATERIAL_REGISTRY");
        (void)Material::MaterialRegistry::instance();

        ctx.update(0.18f, "Synthesizing Stratovolcano Geomorphology", "320x64x320 lattice (6,553,600 voxels)", "VOXEL_LATTICE");
        island = std::make_unique<Island::VoxelIsland>(320, 64, 320);
        island->generateProceduralIsland(1337);

        ctx.update(0.42f, "Propagating WFC Biome Constraints", "Hierarchical 6-biome constraint solver", "WFC_SOLVER");
        wfc_solver = std::make_unique<WFC::HierarchicalSolver>(island->dim_x, island->dim_z, 8);
        wfc_solver->solveBiomes(
            island->center_x, island->center_z,
            island->island_radius, island->caldera_radius,
            [&](int x,int z){
                float dx=float(x)-island->center_x, dz=float(z)-island->center_z;
                float r=std::sqrt(dx*dx+dz*dz);
                float th=std::atan2(dz,dx);
                float ad=std::abs(th-Island::VoxelIsland::RIVER_ANGLE);
                if(ad>3.14159f) ad=6.28318f-ad;
                return r<island->island_radius*.95f && r*ad<4.5f;
            }, 1337);
        wfc_solver->solveFeatures(
            [&](float x,float z){ return island->noise_flora.noise(x*.28f,0.f,z*.28f); }, 1337);

        ctx.update(0.62f, "Braiding Bingham Plastic Molten Lava River", "Caldera summit vent to ocean surf spline", "VOLCANO_MAGMA");
        lava_system = std::make_unique<Volcano::VolcanicLavaFlow>();
        lava_system->initRiverPath(*island);

        ctx.update(0.78f, "Pre-warming Convective Ash & Smoke Chimney", "54 buoyant vortex billow puffs", "SMOKE_PLUME");
        smoke_system = std::make_unique<Volcano::VolcanicSmokePlume>();
        smoke_system->initPlume(*island);

        ctx.update(0.85f, "Synthesizing Algorithmic Flora Ecosystem", "Coconut palms, canopy trees & slope bushes", "VEGETATION");
        veg_system = std::make_unique<Vegetation::IslandVegetationSystem>();
        veg_system->populateIsland(*island, *wfc_solver);

        ctx.update(0.88f, "Instantiating Multi-Species Semantic Boids (2D-4D)", "Tropic terns, reef tangs, ember moths & 4D luminaries", "BOIDS");
        boid_system = std::make_unique<Boids::MultiSpeciesBoidSystem>();
        boid_system->initialize(*island);

        ctx.update(0.92f, "Calibrating Multi-Harmonic Ocean & Atmosphere", "6-octave Gerstner waves & geodesic dome", "OCEAN_SKY");
        ocean_system = std::make_unique<Ocean::SeaOfThievesWater>(island->sea_level);
        sky_system = std::make_unique<Sky::VolumetricAtmosphere>();
        parallax_system = std::make_unique<Atmosphere::HorizonPlanetParallaxSystem>();

        // Player initial position on scenic southern beach dune
        player_pos = island->findBeachSpawnPosition();
        smooth_eye_y = player_pos.y + 0.80f;
        float dx = island->center_x - player_pos.x;
        float dz = island->center_z - player_pos.z;
        player_yaw = std::atan2(-dx, -dz);

        ctx.update(1.0f, "Simulation Scene Ready", "Committing GPU vertex buffers", "GPU_STREAM");
    }

    void initScene(Ogre::SceneManager* scnMgr, Ogre::Camera* cam, Ogre::RenderWindow* win) override {
        sceneMgr = scnMgr;
        camera = cam;
        cam->setNearClipDistance(0.05f);
        cam->setFarClipDistance(12000.0f);

        // Lighting
        sunLight = scnMgr->createLight("VolcanoSun");
        sunLight->setType(Ogre::Light::LT_DIRECTIONAL);
        sunLight->setDiffuseColour(Ogre::ColourValue(1.f, .95f, .82f));
        sunLight->setSpecularColour(Ogre::ColourValue(1.f, .98f, .90f));
        auto* sunNode = scnMgr->getRootSceneNode()->createChildSceneNode("SunNode");
        sunNode->setDirection(Ogre::Vector3(-.4f, -1.f, -.6f).normalisedCopy());
        sunNode->attachObject(sunLight);

        caldGlow = scnMgr->createLight("CalderaGlow");
        caldGlow->setType(Ogre::Light::LT_POINT);
        caldGlow->setDiffuseColour(Ogre::ColourValue(1.f, .32f, .05f));
        caldGlow->setAttenuation(80.f, 1.f, .035f, .015f);
        auto* cgNode = scnMgr->getRootSceneNode()->createChildSceneNode("CalderaGlowNode");
        cgNode->setPosition(island->center_x, island->peak_height + 3.f, island->center_z);
        cgNode->attachObject(caldGlow);

        // Nocturnal Bioluminescent Firefly Point Lights
        firefly_lights.clear();
        firefly_nodes.clear();
        for(size_t i = 0; i < NUM_FIREFLY_LIGHTS; ++i) {
            std::string name = "HubFireflyLight_" + std::to_string(i);
            Ogre::Light* fl = scnMgr->createLight(name);
            fl->setType(Ogre::Light::LT_POINT);
            fl->setDiffuseColour(Ogre::ColourValue(0.25f, 1.0f, 0.40f));
            fl->setSpecularColour(Ogre::ColourValue(1.0f, 0.95f, 0.35f));
            fl->setAttenuation(32.0f, 1.0f, 0.09f, 0.04f);
            fl->setVisible(false);

            Ogre::SceneNode* fn = scnMgr->getRootSceneNode()->createChildSceneNode(name + "Node");
            fn->attachObject(fl);
            firefly_lights.push_back(fl);
            firefly_nodes.push_back(fn);
        }

        // Sky Dome
        skyMesh = scnMgr->createManualObject("SkyMeshObj");
        skyMesh->setDynamic(true);
        skyMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_SKIES_EARLY);
        sky_system->updateSkyDomeMesh(skyMesh, 0.0f, *island, player_pos);
        skyNode = scnMgr->getRootSceneNode()->createChildSceneNode("SkyNode");
        skyNode->attachObject(skyMesh);

        // Horizon Mountains, Sea-Mist Ribbon & Low-Poly Drifting Clouds Parallax
        parallaxMesh = scnMgr->createManualObject("ParallaxMeshObj");
        parallaxMesh->setDynamic(true);
        parallaxMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_SKIES_EARLY + 1);
        parallax_system->updateParallaxMesh(parallaxMesh, 0.0f, *sky_system, player_pos, island->center_x, island->center_z);
        parallaxNode = scnMgr->getRootSceneNode()->createChildSceneNode("ParallaxNode");
        parallaxNode->attachObject(parallaxMesh);

        // OpenVDB Island Mesh
        islandMesh = scnMgr->createManualObject("IslandMeshObj");
        islandMesh->setDynamic(true);
        VDB::VdbIslandMesher::buildNaturalIslandMesh(islandMesh, *island, 0.0f, 0.025f);
        islandNode = scnMgr->getRootSceneNode()->createChildSceneNode("IslandNode");
        islandNode->attachObject(islandMesh);

        // Procedural Flora / Vegetation Mesh
        vegMesh = scnMgr->createManualObject("VegetationMeshObj");
        vegMesh->setDynamic(true);
        veg_system->updateVegetationMesh(vegMesh, 0.0f);
        vegNode = scnMgr->getRootSceneNode()->createChildSceneNode("VegetationNode");
        vegNode->attachObject(vegMesh);

        // Procedural Multi-Species Boids Mesh (2D-4D)
        boidMesh = scnMgr->createManualObject("BoidMeshObj");
        boidMesh->setDynamic(true);
        boid_system->updateBoidMesh(boidMesh, 0.0f, *island);
        boidNode = scnMgr->getRootSceneNode()->createChildSceneNode("BoidNode");
        boidNode->attachObject(boidMesh);

        // Lava Flow Mesh
        lavaMesh = scnMgr->createManualObject("LavaMeshObj");
        lavaMesh->setDynamic(true);
        lava_system->updateLavaMesh(lavaMesh, 0.0f, *island);
        lavaNode = scnMgr->getRootSceneNode()->createChildSceneNode("LavaNode");
        lavaNode->attachObject(lavaMesh);

        // Smoke Plume Mesh
        smokeMesh = scnMgr->createManualObject("SmokeMeshObj");
        smokeMesh->setDynamic(true);
        smokeMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_MAIN + 1);
        smoke_system->updateSmokeMesh(smokeMesh, 0.0f, *island);
        smokeNode = scnMgr->getRootSceneNode()->createChildSceneNode("SmokeNode");
        smokeNode->attachObject(smokeMesh);

        // Ocean Mesh
        oceanMesh = scnMgr->createManualObject("OceanMeshObj");
        oceanMesh->setDynamic(true);
        oceanMesh->setRenderQueueGroup(Ogre::RENDER_QUEUE_6);
        Spatial::Vector3D sun_dir(0.4f, 1.0f, 0.6f);
        sun_dir = sun_dir.normalized();
        ocean_system->updateOceanMesh(oceanMesh, 0.0f, *island, player_pos, sun_dir);
        oceanNode = scnMgr->getRootSceneNode()->createChildSceneNode("OceanNode");
        oceanNode->attachObject(oceanMesh);

        // HUD Initialization
        hud.init(scnMgr, *island, *wfc_solver);
    }

    // Ray Hit & Hotbar state
    bool ray_hit = false;
    uint16_t ray_mat_code = Material::MAT_AIR;
    float ray_distance = 0.0f;
    uint16_t active_hotbar_mat = Material::MAT_BASALT;

    void update(float dt, const UserInputState& input) override {
        // Look rotation
        player_yaw   += input.mouse_dx;
        player_pitch += input.mouse_dy;
        player_pitch  = std::max(-1.48f, std::min(1.48f, player_pitch));

        // Jump Edge & Buffering Detection
        bool jump_edge = input.jump && !prev_jump_input;
        prev_jump_input = input.jump;

        if (jump_edge) {
            jump_buffer = 0.18f;
        } else if (jump_buffer > 0.0f) {
            jump_buffer -= dt;
        }

        // Horizontal Locomotion Wish Direction
        Spatial::Vector3D fwd(-std::sin(player_yaw), 0, -std::cos(player_yaw));
        Spatial::Vector3D right(std::cos(player_yaw), 0, -std::sin(player_yaw));
        Spatial::Vector3D wish_dir(0, 0, 0);

        if (input.move_forward)  wish_dir += fwd;
        if (input.move_backward) wish_dir -= fwd;
        if (input.move_right)    wish_dir += right;
        if (input.move_left)     wish_dir -= right;

        bool has_wish_input = wish_dir.lengthSq() > 1e-4f;
        if (has_wish_input) {
            wish_dir = wish_dir.normalized();
        }

        float target_speed = input.sprint ? sprint_speed : walk_speed;
        
        // Ground Elevation & Water Detection
        float ground_h = island->getIslandHeight(player_pos.x, player_pos.z);
        float sea_h = float(island->sea_level);
        in_water = (player_pos.y < sea_h + 0.35f) && (ground_h < sea_h);

        if (in_water) target_speed *= 0.70f;

        // Horizontal Velocity Integration
        if (on_ground) {
            coyote_timer = 0.18f;
            jump_count = 0;
            if (has_wish_input) {
                Spatial::Vector3D target_vel = wish_dir * target_speed;
                float blend = std::min(1.0f, 15.0f * dt);
                player_vel.x += (target_vel.x - player_vel.x) * blend;
                player_vel.z += (target_vel.z - player_vel.z) * blend;
            } else {
                float friction = std::max(0.0f, 1.0f - 8.0f * dt);
                player_vel.x *= friction;
                player_vel.z *= friction;
            }
        } else {
            // Airborne: Responsive Air Strafe
            coyote_timer = std::max(0.0f, coyote_timer - dt);
            if (has_wish_input) {
                float current_proj = player_vel.x * wish_dir.x + player_vel.z * wish_dir.z;
                float add_speed = std::max(0.0f, target_speed - current_proj);
                float accel = std::min(add_speed, 6.0f * target_speed * dt);
                player_vel.x += wish_dir.x * accel;
                player_vel.z += wish_dir.z * accel;
            }
            float air_drag = std::max(0.0f, 1.0f - 0.2f * dt);
            player_vel.x *= air_drag;
            player_vel.z *= air_drag;
        }

        // Horizontal Step Climbing & Collision
        float nx = player_pos.x + player_vel.x * dt;
        if (nx >= 2.0f && nx <= island->dim_x - 2.0f) {
            float gx = island->getIslandHeight(nx, player_pos.z);
            if ((gx - ground_h) <= 0.90f) { player_pos.x = nx; ground_h = gx; }
            else { player_vel.x = 0.0f; }
        }
        float nz = player_pos.z + player_vel.z * dt;
        if (nz >= 2.0f && nz <= island->dim_z - 2.0f) {
            float gz = island->getIslandHeight(player_pos.x, nz);
            if ((gz - ground_h) <= 0.90f) { player_pos.z = nz; ground_h = gz; }
            else { player_vel.z = 0.0f; }
        }

        // ── Vertical Dynamics, Jumping, Double-Jumping & Swimming ─────────────
        if (in_water) {
            jump_count = 0;
            coyote_timer = 0.18f;
            on_ground = false;
            player_vel.y *= 0.88f;

            float depth = sea_h - player_pos.y;
            float buoyancy = std::max(-1.0f, std::min(4.0f, (depth - 0.15f) * 6.0f));
            player_vel.y += buoyancy * dt;

            if (input.jump) {
                // In-water upward propulsion or surface water leap
                if (player_pos.y >= sea_h - 0.2f && jump_edge) {
                    player_vel.y = jump_velocity; // Surface water exit leap!
                    jump_count = 1;
                    jump_buffer = 0.0f;
                } else {
                    player_vel.y = 2.75f; // Swimming ascent (scaled)
                }
            }

            player_pos.y += player_vel.y * dt;
            if (player_pos.y < ground_h) {
                player_pos.y = ground_h;
                player_vel.y = 0.0f;
                on_ground = true;
            }
        } else {
            // Jump Triggering: Primary Jump (Grounded / Coyote) vs Double Jump
            if (jump_buffer > 0.0f) {
                if (on_ground || coyote_timer > 0.0f) {
                    // Primary Jump
                    player_vel.y = jump_velocity;
                    on_ground = false;
                    coyote_timer = 0.0f;
                    jump_buffer = 0.0f;
                    jump_count = 1;
                    player_pos.y += 0.04f;
                } else if (jump_count < max_jumps) {
                    // Kinetic Double Jump in Mid-Air
                    player_vel.y = double_jump_velocity;
                    jump_count = 2;
                    jump_buffer = 0.0f;

                    // Directional mid-air kinetic burst
                    Spatial::Vector3D boost = has_wish_input ? wish_dir : fwd;
                    player_vel.x += boost.x * double_jump_thrust;
                    player_vel.z += boost.z * double_jump_thrust;
                }
            }

            if (!on_ground) {
                // Natural Trajectory Curve with Apex Float & Kinetic Descent (Scaled)
                float eff_gravity = gravity;
                if (std::abs(player_vel.y) < 1.6f) {
                    eff_gravity = gravity * 0.65f; // Apex float / natural crest hang-time
                } else if (player_vel.y > 1.6f) {
                    eff_gravity = input.jump ? (gravity * 0.90f) : (gravity * 1.55f); // Variable jump ascent
                } else {
                    eff_gravity = gravity * 1.25f; // Kinetic, weighted downward descent
                }

                player_vel.y += eff_gravity * dt;
                player_vel.y = std::max(player_vel.y, -18.0f);
                player_pos.y += player_vel.y * dt;

                if (player_pos.y <= ground_h) {
                    player_pos.y = ground_h;
                    player_vel.y = 0.0f;
                    on_ground = true;
                    jump_count = 0;
                    coyote_timer = 0.18f;
                }
            } else {
                float h_diff = ground_h - player_pos.y;
                if (h_diff > -0.45f && h_diff <= 0.45f) {
                    player_pos.y = ground_h;
                    player_vel.y = 0.0f;
                    on_ground = true;
                } else if (h_diff < -0.45f) {
                    on_ground = false; // Stepped off ledge into free fall
                }
            }
        }

        // Exponential continuous elevation damping for head-level (0.80m eye height)
        float target_eye = player_pos.y + 0.80f;
        smooth_eye_y += (target_eye - smooth_eye_y) * std::min(1.0f, dt * 18.0f);

        // Update Camera in Scene Graph
        if (camera && camera->getParentSceneNode()) {
            camera->getParentSceneNode()->setPosition(player_pos.x, smooth_eye_y, player_pos.z);
            Ogre::Quaternion qYaw(Ogre::Radian(player_yaw), Ogre::Vector3::UNIT_Y);
            Ogre::Quaternion qPitch(Ogre::Radian(player_pitch), Ogre::Vector3::UNIT_X);
            camera->getParentSceneNode()->setOrientation(qYaw * qPitch);
        }

        // Fast Raycast from eye for reticle target & material inspection
        Spatial::Vector3D ray_dir(
            -std::sin(player_yaw) * std::cos(player_pitch),
            std::sin(player_pitch),
            -std::cos(player_yaw) * std::cos(player_pitch)
        );
        ray_dir = ray_dir.normalized();

        ray_hit = false;
        ray_mat_code = Material::MAT_AIR;
        for (float d = 0.5f; d < 20.0f; d += 0.5f) {
            float rx = player_pos.x + ray_dir.x * d;
            float ry = smooth_eye_y + ray_dir.y * d;
            float rz = player_pos.z + ray_dir.z * d;
            int ix = int(std::floor(rx));
            int iy = int(std::floor(ry));
            int iz = int(std::floor(rz));

            if (island->inBounds(ix, iy, iz)) {
                uint16_t v = island->getVoxel(ix, iy, iz);
                if (v != Material::MAT_AIR) {
                    ray_hit = true;
                    ray_mat_code = v;
                    ray_distance = d;
                    break;
                }
            }
        }

        // Dynamic System Animations
        if (veg_system && vegMesh) {
            veg_system->updateVegetationMesh(vegMesh, dt);
        }
        if (boid_system && boidMesh && island) {
            boid_system->update(dt, *island);
            boid_system->updateBoidMesh(boidMesh, dt, *island);
        }
        if (lava_system && lavaMesh) {
            lava_system->updateLavaMesh(lavaMesh, dt, *island);
        }
        if (smoke_system && smokeMesh) {
            smoke_system->updateSmokeMesh(smokeMesh, dt, *island);
        }
        if (sky_system && skyMesh) {
            sky_system->updateSkyDomeMesh(skyMesh, dt, *island, player_pos);
        }
        if (sunLight && sunLight->getParentSceneNode() && sky_system) {
            float t_night = std::max(0.0f, std::min(1.0f, (0.12f - sky_system->sun_direction.y) / 0.32f));
            float night_factor = t_night * t_night * (3.0f - 2.0f * t_night);

            Spatial::Vector3D primary_dir = ((1.0f - night_factor) * sky_system->sun_direction + night_factor * sky_system->moon_direction).normalized();
            sunLight->getParentSceneNode()->setDirection(Ogre::Vector3(
                -primary_dir.x,
                -primary_dir.y,
                -primary_dir.z
            ).normalisedCopy());
            sunLight->setDiffuseColour(sky_system->sun_color);
            sunLight->setSpecularColour(sky_system->sun_color * 0.85f);
            if (sceneMgr) sceneMgr->setAmbientLight(sky_system->ambient_sky_color);
        }
        if (boid_system && sky_system) {
            float night_intensity = std::max(0.0f, std::min(1.0f, (-sky_system->sun_direction.y + 0.05f) / 0.25f));
            auto firefly_positions = boid_system->getFireflyLightPositions(firefly_lights.size());
            for (size_t i = 0; i < firefly_lights.size(); ++i) {
                if (i < firefly_positions.size() && night_intensity > 0.02f) {
                    firefly_lights[i]->setVisible(true);
                    firefly_nodes[i]->setPosition(firefly_positions[i]);
                    float pulse = 0.70f + 0.30f * std::sin(sky_system->simulation_time * 5.0f + float(i * 1.5f));
                    Ogre::ColourValue col_pulse = Ogre::ColourValue(0.25f, 1.0f, 0.40f) * (night_intensity * pulse);
                    firefly_lights[i]->setDiffuseColour(col_pulse);
                } else if (i < firefly_lights.size()) {
                    firefly_lights[i]->setVisible(false);
                }
            }
        }
        if (ocean_system && oceanMesh && sky_system) {
            float t_night = std::max(0.0f, std::min(1.0f, (0.12f - sky_system->sun_direction.y) / 0.32f));
            float night_factor = t_night * t_night * (3.0f - 2.0f * t_night);
            Spatial::Vector3D active_light_dir = ((1.0f - night_factor) * sky_system->sun_direction + night_factor * sky_system->moon_direction).normalized();
            ocean_system->updateOceanMesh(oceanMesh, dt, *island, player_pos, active_light_dir);
        }
        if (parallax_system && parallaxMesh && sky_system) {
            parallax_system->updateParallaxMesh(parallaxMesh, dt, *sky_system, player_pos, island->center_x, island->center_z);
        }
    }

    bool handleKeyPress(int key, bool down) override {
        if (!down) return false;
        if (key == '1') active_hotbar_mat = Material::MAT_BASALT;
        if (key == '2') active_hotbar_mat = Material::MAT_SAND;
        if (key == '3') active_hotbar_mat = Material::MAT_FOLIAGE;
        if (key == '4') active_hotbar_mat = Material::MAT_BAMBOO;
        if (key == '5') active_hotbar_mat = Material::MAT_OBSIDIAN;
        if (key == '6') active_hotbar_mat = Material::MAT_SULFUR;
        if (key == '7') active_hotbar_mat = Material::MAT_ASH;
        if (key == '8') active_hotbar_mat = Material::MAT_LAVA;
        if (key == '9') active_hotbar_mat = Material::MAT_WATER;

        // Liquid Rendering Method Switcher (NVJOB / Gerstner / Cel / Glass)
        if (key == 'l' || key == 'L') {
            if (ocean_system) {
                ocean_system->cycleLiquidMethod();
            }
        }
        return true;
    }

    void renderHUD(Ogre::ManualObject* hudObj, Ogre::Viewport* vp, float screen_alpha = 1.0f) override {
        (void)vp;
        if (hudObj && screen_alpha > 0.01f) {
            bool in_water = player_pos.y <= island->sea_level + 0.3f;
            hud.renderVectorHUD(
                hudObj,
                screen_alpha,
                0.016f,
                player_pos.x, player_pos.y, player_pos.z,
                player_yaw, player_pitch,
                in_water,
                ray_hit, ray_mat_code, ray_distance,
                60.0f,
                active_hotbar_mat,
                "VOLCANIC_ISLAND"
            );
        }
    }

    void cleanup(Ogre::SceneManager* scnMgr) override {
        if (islandMesh) { scnMgr->destroyManualObject(islandMesh); islandMesh = nullptr; }
        if (islandNode) { scnMgr->destroySceneNode(islandNode); islandNode = nullptr; }
        if (vegMesh)    { scnMgr->destroyManualObject(vegMesh); vegMesh = nullptr; }
        if (vegNode)    { scnMgr->destroySceneNode(vegNode); vegNode = nullptr; }
        if (boidMesh)   { scnMgr->destroyManualObject(boidMesh); boidMesh = nullptr; }
        if (boidNode)   { scnMgr->destroySceneNode(boidNode); boidNode = nullptr; }
        if (oceanMesh)  { scnMgr->destroyManualObject(oceanMesh); oceanMesh = nullptr; }
        if (oceanNode)  { scnMgr->destroySceneNode(oceanNode); oceanNode = nullptr; }
        if (skyMesh)    { scnMgr->destroyManualObject(skyMesh); skyMesh = nullptr; }
        if (skyNode)    { scnMgr->destroySceneNode(skyNode); skyNode = nullptr; }
        if (lavaMesh)   { scnMgr->destroyManualObject(lavaMesh); lavaMesh = nullptr; }
        if (lavaNode)   { scnMgr->destroySceneNode(lavaNode); lavaNode = nullptr; }
        if (smokeMesh)  { scnMgr->destroyManualObject(smokeMesh); smokeMesh = nullptr; }
        if (smokeNode)  { scnMgr->destroySceneNode(smokeNode); smokeNode = nullptr; }
        if (sunLight)   { scnMgr->destroyLight(sunLight); sunLight = nullptr; }
        if (caldGlow)   { scnMgr->destroyLight(caldGlow); caldGlow = nullptr; }
    }
};

} // namespace SCR::Simulation

#endif // CAVE_SCENE_VOLCANIC_ISLAND_HPP
