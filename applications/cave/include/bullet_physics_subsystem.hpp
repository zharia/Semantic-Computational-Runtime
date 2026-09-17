#ifndef CAVE_BULLET_PHYSICS_SUBSYSTEM_HPP
#define CAVE_BULLET_PHYSICS_SUBSYSTEM_HPP

#include <vector>
#include <map>
#include <memory>
#include <iostream>
#include <cmath>

#include <Ogre.h>

#include "simulation_framework.hpp"
#include "simulation_subjects.hpp"
#include "simulation_events.hpp"
#include "procedural_island.hpp"
#include "../../../providers/physics/bullet3/adapter/bullet_adapter.hpp"

namespace SCR::Simulation {

struct SpawnedRigidBodyInfo {
    uint32_t body_id = 0;
    std::string type = "sphere";
    float radius = 0.6f;
    float half_x = 0.5f;
    float half_y = 0.5f;
    float half_z = 0.5f;
    Ogre::SceneNode* scene_node = nullptr;
    Ogre::ManualObject* mesh_obj = nullptr;
};

class BulletPhysicsSubSystem : public ISimulationSubSystem {
public:
    SCRBulletWorldHandle bullet_world = nullptr;
    SCRColliderId terrain_collider_id = 0;

    std::map<uint32_t, SpawnedRigidBodyInfo> dynamic_bodies;
    Ogre::SceneNode* physicsRootNode = nullptr;

    std::string getName() const override { return "BulletPhysicsSubSystem"; }

    BulletPhysicsSubSystem() {
        SCRVec3 gravity = { 0.0f, -9.81f, 0.0f };
        bullet_world = scr_bullet_world_create(gravity);
    }

    ~BulletPhysicsSubSystem() override {
        cleanupWorld();
    }

    void cleanupWorld() {
        if (bullet_world) {
            scr_bullet_world_destroy(bullet_world);
            bullet_world = nullptr;
        }
    }

    Ogre::SceneManager* sceneMgr = nullptr;

    void initialize(SystemContext& ctx) override {
        sceneMgr = ctx.sceneMgr;
        if (ctx.sceneMgr) {
            if (ctx.sceneMgr->hasSceneNode("BulletPhysicsRootNode")) {
                ctx.sceneMgr->destroySceneNode("BulletPhysicsRootNode");
            }
            physicsRootNode = ctx.sceneMgr->getRootSceneNode()->createChildSceneNode("BulletPhysicsRootNode");
        }
    }

    void prepare(LoadingContext& ctx, SystemContext& sysCtx) override {
        ctx.update(0.85f, "Building Bullet3 Static Mesh Collider", "OpenVDB Isosurface triangle mesh", "BULLET_BVH");
        auto island_sub = sysCtx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
        if (island_sub && island_sub->voxel_island) {
            buildTerrainMeshCollider(*island_sub->voxel_island);
        }
    }

    void buildTerrainMeshCollider(const Island::VoxelIsland& island) {
        if (!bullet_world) return;

        if (terrain_collider_id > 0) {
            scr_bullet_remove_collider(bullet_world, terrain_collider_id);
            terrain_collider_id = 0;
        }

        // Build continuous high-resolution terrain mesh grid spanning island bounds
        const int grid_res = 80;
        const float world_min = 0.0f;
        const float world_max = 320.0f;
        const float step = (world_max - world_min) / float(grid_res - 1);

        std::vector<float> vertices;
        vertices.reserve(grid_res * grid_res * 3);

        for (int gz = 0; gz < grid_res; ++gz) {
            float wz = world_min + gz * step;
            for (int gx = 0; gx < grid_res; ++gx) {
                float wx = world_min + gx * step;
                float wy = island.getIslandHeight(wx, wz);
                vertices.push_back(wx);
                vertices.push_back(wy);
                vertices.push_back(wz);
            }
        }

        std::vector<uint32_t> indices;
        indices.reserve((grid_res - 1) * (grid_res - 1) * 6);

        for (int gz = 0; gz < grid_res - 1; ++gz) {
            for (int gx = 0; gx < grid_res - 1; ++gx) {
                uint32_t i0 = gz * grid_res + gx;
                uint32_t i1 = gz * grid_res + (gx + 1);
                uint32_t i2 = (gz + 1) * grid_res + gx;
                uint32_t i3 = (gz + 1) * grid_res + (gx + 1);

                // Triangle 1
                indices.push_back(i0);
                indices.push_back(i2);
                indices.push_back(i1);

                // Triangle 2
                indices.push_back(i1);
                indices.push_back(i2);
                indices.push_back(i3);
            }
        }

        int res = scr_bullet_create_triangle_mesh_collider(
            bullet_world,
            vertices.data(),
            vertices.size() / 3,
            indices.data(),
            indices.size(),
            &terrain_collider_id
        );

        if (res == BULLET_SUCCESS) {
            std::cout << "[Bullet3] Constructed Static Terrain Collider (" 
                      << vertices.size() / 3 << " vertices, " 
                      << indices.size() / 3 << " triangles, ID: " << terrain_collider_id << ")" << std::endl;
        } else {
            std::cerr << "[Bullet3] Failed to build terrain collider: error " << res << std::endl;
        }
    }

    uint32_t spawnDynamicSphere(float radius, float mass, SCRVec3 pos, SCRVec3 initial_vel = {0,0,0}, float restitution = 0.6f, float friction = 0.5f) {
        if (!bullet_world) return 0;
        uint32_t body_id = 0;
        int res = scr_bullet_create_sphere(bullet_world, radius, mass, pos, restitution, friction, &body_id);
        if (res != BULLET_SUCCESS || body_id == 0) return 0;

        if (initial_vel.x != 0.0f || initial_vel.y != 0.0f || initial_vel.z != 0.0f) {
            scr_bullet_body_set_velocity(bullet_world, body_id, initial_vel, { 0, 0, 0 });
        }

        SpawnedRigidBodyInfo info;
        info.body_id = body_id;
        info.type = "sphere";
        info.radius = radius;

        if (sceneMgr && physicsRootNode) {
            std::string mesh_name = "BulletSphereMesh_" + std::to_string(body_id);
            std::string node_name = "BulletSphereNode_" + std::to_string(body_id);

            info.mesh_obj = sceneMgr->createManualObject(mesh_name);
            info.mesh_obj->setRenderQueueGroup(Ogre::RENDER_QUEUE_MAIN);
            createSphereMesh(info.mesh_obj, radius, Ogre::ColourValue(0.24f, 0.22f, 0.26f));
            info.scene_node = physicsRootNode->createChildSceneNode(node_name);
            info.scene_node->attachObject(info.mesh_obj);
            info.scene_node->setPosition(pos.x, pos.y, pos.z);
        }

        dynamic_bodies[body_id] = info;
        std::cout << "[Bullet3] Spawned dynamic sphere (ID: " << body_id << ", Radius: " << radius << "m, Mass: " << mass << "kg) at (" << pos.x << ", " << pos.y << ", " << pos.z << ")" << std::endl;
        return body_id;
    }

    uint32_t spawnDynamicSphere(SystemContext& ctx, float radius, float mass, SCRVec3 pos, SCRVec3 initial_vel, float restitution = 0.6f, float friction = 0.5f) {
        if (ctx.sceneMgr) sceneMgr = ctx.sceneMgr;
        return spawnDynamicSphere(radius, mass, pos, initial_vel, restitution, friction);
    }

    uint32_t spawnDynamicBox(SCRVec3 half_extents, float mass, SCRVec3 pos, SCRVec3 initial_vel = {0,0,0}, float restitution = 0.4f, float friction = 0.6f) {
        if (!bullet_world) return 0;
        uint32_t body_id = 0;
        int res = scr_bullet_create_box(bullet_world, half_extents, mass, pos, restitution, friction, &body_id);
        if (res != BULLET_SUCCESS || body_id == 0) return 0;

        if (initial_vel.x != 0.0f || initial_vel.y != 0.0f || initial_vel.z != 0.0f) {
            scr_bullet_body_set_velocity(bullet_world, body_id, initial_vel, { 0, 0, 0 });
        }

        SpawnedRigidBodyInfo info;
        info.body_id = body_id;
        info.type = "box";
        info.half_x = half_extents.x;
        info.half_y = half_extents.y;
        info.half_z = half_extents.z;

        if (sceneMgr && physicsRootNode) {
            std::string mesh_name = "BulletBoxMesh_" + std::to_string(body_id);
            std::string node_name = "BulletBoxNode_" + std::to_string(body_id);

            info.mesh_obj = sceneMgr->createManualObject(mesh_name);
            info.mesh_obj->setRenderQueueGroup(Ogre::RENDER_QUEUE_MAIN);
            createBoxMesh(info.mesh_obj, half_extents, Ogre::ColourValue(0.55f, 0.38f, 0.20f));
            info.scene_node = physicsRootNode->createChildSceneNode(node_name);
            info.scene_node->attachObject(info.mesh_obj);
            info.scene_node->setPosition(pos.x, pos.y, pos.z);
        }

        dynamic_bodies[body_id] = info;
        std::cout << "[Bullet3] Spawned dynamic box (ID: " << body_id << ", Mass: " << mass << "kg) at (" << pos.x << ", " << pos.y << ", " << pos.z << ")" << std::endl;
        return body_id;
    }

    uint32_t spawnDynamicBox(SystemContext& ctx, SCRVec3 half_extents, float mass, SCRVec3 pos, SCRVec3 initial_vel, float restitution = 0.4f, float friction = 0.6f) {
        if (ctx.sceneMgr) sceneMgr = ctx.sceneMgr;
        return spawnDynamicBox(half_extents, mass, pos, initial_vel, restitution, friction);
    }

    bool raycast(SCRVec3 from, SCRVec3 to, SCRRigidRaycastHit* out_hit) {
        if (!bullet_world || !out_hit) return false;
        int res = scr_bullet_raycast(bullet_world, from, to, out_hit);
        return (res == BULLET_SUCCESS && out_hit->hit);
    }

    bool getBodyState(uint32_t body_id, SCRVec3* out_pos, SCRQuat* out_rot, SCRVec3* out_lin_vel, SCRVec3* out_ang_vel) {
        if (!bullet_world) return false;
        if (out_pos && out_rot) {
            if (scr_bullet_body_get_transform(bullet_world, body_id, out_pos, out_rot) != BULLET_SUCCESS) return false;
        }
        if (out_lin_vel && out_ang_vel) {
            if (scr_bullet_body_get_velocity(bullet_world, body_id, out_lin_vel, out_ang_vel) != BULLET_SUCCESS) return false;
        }
        return true;
    }

    std::vector<uint32_t> getAllBodyIds() const {
        std::vector<uint32_t> ids;
        for (const auto& pair : dynamic_bodies) {
            ids.push_back(pair.first);
        }
        return ids;
    }

    size_t getDynamicBodyCount() const {
        return dynamic_bodies.size();
    }

    void updateAsync(float dt, const UserInputState& input, SystemContext& ctx) override {
        (void)input;
        if (!bullet_world || dt <= 0.0f) return;

        float sea_level = 8.0f;
        auto hydro_sub = ctx.subjects.getFirstSubjectOfType<HydrologySubject>(SubjectType::OCEAN);
        if (hydro_sub) sea_level = hydro_sub->sea_level;

        // Apply hydrodynamic Archimedes buoyancy & viscous damping to submerged dynamic bodies
        for (const auto& pair : dynamic_bodies) {
            uint32_t bid = pair.first;
            SCRVec3 pos = {0,0,0};
            SCRQuat rot = {0,0,0,1};
            SCRVec3 lin_vel = {0,0,0};
            SCRVec3 ang_vel = {0,0,0};

            if (scr_bullet_body_get_transform(bullet_world, bid, &pos, &rot) == BULLET_SUCCESS &&
                scr_bullet_body_get_velocity(bullet_world, bid, &lin_vel, &ang_vel) == BULLET_SUCCESS) {
                if (pos.y < sea_level + 0.5f) {
                    float immersion = std::min(1.0f, std::max(0.0f, (sea_level + 0.5f - pos.y) / 1.5f));
                    // Upward buoyancy acceleration to balance gravity
                    float buoyancy_accel = 16.0f * immersion;
                    float drag_y = -lin_vel.y * 3.5f * immersion;
                    float drag_x = -lin_vel.x * 2.0f * immersion;
                    float drag_z = -lin_vel.z * 2.0f * immersion;

                    SCRVec3 impulse = {
                        drag_x * dt,
                        (buoyancy_accel + drag_y) * dt,
                        drag_z * dt
                    };
                    SCRVec3 rel_pos = {0, 0, 0};
                    scr_bullet_body_apply_impulse(bullet_world, bid, impulse, rel_pos);
                }
            }
        }

        scr_bullet_world_step(bullet_world, dt, 10, 1.0f / 120.0f);
    }

    void renderSync(SystemContext& ctx, float dt) override {
        (void)ctx; (void)dt;
        if (!bullet_world) return;

        // Synchronize dynamic rigid body transforms to Ogre Scene Nodes
        for (auto& pair : dynamic_bodies) {
            auto& info = pair.second;
            if (info.scene_node) {
                SCRVec3 pos = { 0, 0, 0 };
                SCRQuat rot = { 0, 0, 0, 1 };
                if (scr_bullet_body_get_transform(bullet_world, info.body_id, &pos, &rot) == BULLET_SUCCESS) {
                    info.scene_node->setPosition(pos.x, pos.y, pos.z);
                    info.scene_node->setOrientation(Ogre::Quaternion(rot.w, rot.x, rot.y, rot.z));
                }
            }
        }
    }

    void handleEvent(const ISimulationEvent& event, SystemContext& ctx) override {
        if (event.getEventType() == EventType::ISLAND_VOYAGE) {
            auto island_sub = ctx.subjects.getFirstSubjectOfType<IslandSubject>(SubjectType::ISLAND);
            if (island_sub && island_sub->voxel_island) {
                buildTerrainMeshCollider(*island_sub->voxel_island);
            }
        }
    }

    void cleanup(Ogre::SceneManager* scnMgr) override {
        if (scnMgr) {
            for (auto& pair : dynamic_bodies) {
                auto& info = pair.second;
                if (info.mesh_obj && scnMgr->hasManualObject(info.mesh_obj->getName())) {
                    scnMgr->destroyManualObject(info.mesh_obj);
                }
                if (info.scene_node && scnMgr->hasSceneNode(info.scene_node->getName())) {
                    scnMgr->destroySceneNode(info.scene_node);
                }
            }
            if (physicsRootNode && scnMgr->hasSceneNode(physicsRootNode->getName())) {
                scnMgr->destroySceneNode(physicsRootNode);
                physicsRootNode = nullptr;
            }
        }
        dynamic_bodies.clear();
        cleanupWorld();
        sceneMgr = nullptr;
    }

private:
    void createSphereMesh(Ogre::ManualObject* mesh, float r, Ogre::ColourValue col) {
        mesh->clear();
        mesh->begin("SCR/BasaltRockMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);
        const int rings = 12;
        const int segments = 16;
        for (int i = 0; i <= rings; ++i) {
            float theta = i * M_PI / rings;
            float sinTheta = std::sin(theta);
            float cosTheta = std::cos(theta);
            for (int j = 0; j <= segments; ++j) {
                float phi = j * 2.0f * M_PI / segments;
                float sinPhi = std::sin(phi);
                float cosPhi = std::cos(phi);
                float x = r * sinTheta * cosPhi;
                float y = r * cosTheta;
                float z = r * sinTheta * sinPhi;
                mesh->position(x, y, z);
                mesh->normal(x / r, y / r, z / r);
                mesh->colour(col.r * (0.8f + 0.2f * sinTheta), col.g * (0.8f + 0.2f * sinTheta), col.b * (0.8f + 0.2f * sinTheta));
                mesh->textureCoord(float(j) / segments, float(i) / rings);
            }
        }
        for (int i = 0; i < rings; ++i) {
            for (int j = 0; j < segments; ++j) {
                uint32_t first = (i * (segments + 1)) + j;
                uint32_t second = first + segments + 1;
                mesh->triangle(first, second, first + 1);
                mesh->triangle(second, second + 1, first + 1);
            }
        }
        mesh->end();
    }

    void createBoxMesh(Ogre::ManualObject* mesh, SCRVec3 h, Ogre::ColourValue col) {
        mesh->clear();
        mesh->begin("SCR/BasaltRockMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);
        // 8 box vertices
        mesh->position(-h.x, -h.y,  h.z); mesh->normal(0, 0, 1); mesh->colour(col); mesh->textureCoord(0,0);
        mesh->position( h.x, -h.y,  h.z); mesh->normal(0, 0, 1); mesh->colour(col); mesh->textureCoord(1,0);
        mesh->position( h.x,  h.y,  h.z); mesh->normal(0, 0, 1); mesh->colour(col); mesh->textureCoord(1,1);
        mesh->position(-h.x,  h.y,  h.z); mesh->normal(0, 0, 1); mesh->colour(col); mesh->textureCoord(0,1);

        mesh->position( h.x, -h.y, -h.z); mesh->normal(0, 0, -1); mesh->colour(col); mesh->textureCoord(0,0);
        mesh->position(-h.x, -h.y, -h.z); mesh->normal(0, 0, -1); mesh->colour(col); mesh->textureCoord(1,0);
        mesh->position(-h.x,  h.y, -h.z); mesh->normal(0, 0, -1); mesh->colour(col); mesh->textureCoord(1,1);
        mesh->position( h.x,  h.y, -h.z); mesh->normal(0, 0, -1); mesh->colour(col); mesh->textureCoord(0,1);

        // Indices for 6 faces (12 triangles)
        // Front
        mesh->triangle(0, 1, 2); mesh->triangle(2, 3, 0);
        // Back
        mesh->triangle(4, 5, 6); mesh->triangle(6, 7, 4);
        // Top
        mesh->triangle(3, 2, 7); mesh->triangle(7, 6, 3);
        // Bottom
        mesh->triangle(5, 4, 1); mesh->triangle(1, 0, 5);
        // Right
        mesh->triangle(1, 4, 7); mesh->triangle(7, 2, 1);
        // Left
        mesh->triangle(5, 0, 3); mesh->triangle(3, 6, 5);
        mesh->end();
    }
};

} // namespace SCR::Simulation

#endif // CAVE_BULLET_PHYSICS_SUBSYSTEM_HPP
