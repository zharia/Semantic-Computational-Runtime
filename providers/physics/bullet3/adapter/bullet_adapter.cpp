#include "bullet_adapter.hpp"

#include <btBulletDynamicsCommon.h>
#include <BulletCollision/CollisionShapes/btBvhTriangleMeshShape.h>
#include <BulletCollision/CollisionShapes/btTriangleIndexVertexArray.h>

#include <iostream>
#include <vector>
#include <map>
#include <memory>
#include <cmath>

struct MeshDataResource {
    std::vector<btScalar> vertices;
    std::vector<int> indices;
    std::unique_ptr<btTriangleIndexVertexArray> index_vertex_array;
    std::unique_ptr<btBvhTriangleMeshShape> mesh_shape;
    std::unique_ptr<btRigidBody> rigid_body;
    std::unique_ptr<btDefaultMotionState> motion_state;
};

struct BulletAdapterWorld {
    std::unique_ptr<btDefaultCollisionConfiguration> collision_config;
    std::unique_ptr<btCollisionDispatcher> dispatcher;
    std::unique_ptr<btBroadphaseInterface> broadphase;
    std::unique_ptr<btSequentialImpulseConstraintSolver> solver;
    std::unique_ptr<btDiscreteDynamicsWorld> dynamics_world;

    uint32_t next_body_id = 1;
    uint32_t next_collider_id = 1;

    struct RigidBodyEntry {
        uint32_t id;
        std::unique_ptr<btCollisionShape> shape;
        std::unique_ptr<btDefaultMotionState> motion_state;
        std::unique_ptr<btRigidBody> body;
    };

    std::map<uint32_t, RigidBodyEntry> bodies;
    std::map<uint32_t, MeshDataResource> mesh_colliders;
};

SCRBulletWorldHandle scr_bullet_world_create(SCRVec3 gravity) {
    auto* world = new BulletAdapterWorld();

    world->collision_config = std::make_unique<btDefaultCollisionConfiguration>();
    world->dispatcher = std::make_unique<btCollisionDispatcher>(world->collision_config.get());
    world->broadphase = std::make_unique<btDbvtBroadphase>();
    world->solver = std::make_unique<btSequentialImpulseConstraintSolver>();

    world->dynamics_world = std::make_unique<btDiscreteDynamicsWorld>(
        world->dispatcher.get(),
        world->broadphase.get(),
        world->solver.get(),
        world->collision_config.get()
    );

    world->dynamics_world->setGravity(btVector3(gravity.x, gravity.y, gravity.z));
    return static_cast<SCRBulletWorldHandle>(world);
}

void scr_bullet_world_destroy(SCRBulletWorldHandle handle) {
    if (!handle) return;
    auto* world = static_cast<BulletAdapterWorld*>(handle);

    // Remove all rigid bodies from simulation world
    for (auto& pair : world->bodies) {
        if (pair.second.body && world->dynamics_world) {
            world->dynamics_world->removeRigidBody(pair.second.body.get());
        }
    }
    world->bodies.clear();

    // Remove all static mesh colliders
    for (auto& pair : world->mesh_colliders) {
        if (pair.second.rigid_body && world->dynamics_world) {
            world->dynamics_world->removeRigidBody(pair.second.rigid_body.get());
        }
    }
    world->mesh_colliders.clear();

    delete world;
}

int scr_bullet_world_step(SCRBulletWorldHandle handle, float dt, int max_substeps, float fixed_timestep) {
    if (!handle) return BULLET_ERR_NULL_HANDLE;
    if (dt <= 0.0f) return BULLET_ERR_INVALID_PARAM;

    auto* world = static_cast<BulletAdapterWorld*>(handle);
    world->dynamics_world->stepSimulation(dt, max_substeps, fixed_timestep);
    return BULLET_SUCCESS;
}

static int create_dynamic_body(BulletAdapterWorld* world,
                               std::unique_ptr<btCollisionShape> shape,
                               float mass,
                               SCRVec3 pos,
                               float restitution,
                               float friction,
                               SCRRigidBodyId* out_id) {
    if (!world || !out_id) return BULLET_ERR_INVALID_PARAM;

    btTransform start_transform;
    start_transform.setIdentity();
    start_transform.setOrigin(btVector3(pos.x, pos.y, pos.z));

    btVector3 local_inertia(0, 0, 0);
    if (mass > 0.0f) {
        shape->calculateLocalInertia(mass, local_inertia);
    }

    auto motion_state = std::make_unique<btDefaultMotionState>(start_transform);
    btRigidBody::btRigidBodyConstructionInfo rb_info(mass, motion_state.get(), shape.get(), local_inertia);
    rb_info.m_restitution = restitution;
    rb_info.m_friction = friction;
    rb_info.m_rollingFriction = 0.1f;
    rb_info.m_spinningFriction = 0.1f;

    auto body = std::make_unique<btRigidBody>(rb_info);
    body->setActivationState(DISABLE_DEACTIVATION);

    uint32_t body_id = world->next_body_id++;
    body->setUserIndex(static_cast<int>(body_id));

    world->dynamics_world->addRigidBody(body.get());

    BulletAdapterWorld::RigidBodyEntry entry;
    entry.id = body_id;
    entry.shape = std::move(shape);
    entry.motion_state = std::move(motion_state);
    entry.body = std::move(body);

    world->bodies[body_id] = std::move(entry);
    *out_id = body_id;
    return BULLET_SUCCESS;
}

int scr_bullet_create_sphere(SCRBulletWorldHandle handle, float radius, float mass, SCRVec3 pos, float restitution, float friction, SCRRigidBodyId* out_id) {
    if (!handle) return BULLET_ERR_NULL_HANDLE;
    if (radius <= 0.0f) return BULLET_ERR_INVALID_PARAM;
    auto* world = static_cast<BulletAdapterWorld*>(handle);
    return create_dynamic_body(world, std::make_unique<btSphereShape>(radius), mass, pos, restitution, friction, out_id);
}

int scr_bullet_create_box(SCRBulletWorldHandle handle, SCRVec3 half_extents, float mass, SCRVec3 pos, float restitution, float friction, SCRRigidBodyId* out_id) {
    if (!handle) return BULLET_ERR_NULL_HANDLE;
    if (half_extents.x <= 0.0f || half_extents.y <= 0.0f || half_extents.z <= 0.0f) return BULLET_ERR_INVALID_PARAM;
    auto* world = static_cast<BulletAdapterWorld*>(handle);
    return create_dynamic_body(world, std::make_unique<btBoxShape>(btVector3(half_extents.x, half_extents.y, half_extents.z)), mass, pos, restitution, friction, out_id);
}

int scr_bullet_create_capsule(SCRBulletWorldHandle handle, float radius, float height, float mass, SCRVec3 pos, float restitution, float friction, SCRRigidBodyId* out_id) {
    if (!handle) return BULLET_ERR_NULL_HANDLE;
    if (radius <= 0.0f || height <= 0.0f) return BULLET_ERR_INVALID_PARAM;
    auto* world = static_cast<BulletAdapterWorld*>(handle);
    return create_dynamic_body(world, std::make_unique<btCapsuleShape>(radius, height), mass, pos, restitution, friction, out_id);
}

int scr_bullet_create_triangle_mesh_collider(SCRBulletWorldHandle handle,
                                             const float* vertices,
                                             size_t num_vertices,
                                             const uint32_t* indices,
                                             size_t num_indices,
                                             SCRColliderId* out_id) {
    if (!handle || !vertices || !indices || num_vertices == 0 || num_indices < 3 || !out_id) {
        return BULLET_ERR_INVALID_PARAM;
    }

    auto* world = static_cast<BulletAdapterWorld*>(handle);
    uint32_t col_id = world->next_collider_id++;

    MeshDataResource res;
    res.vertices.resize(num_vertices * 3);
    for (size_t i = 0; i < num_vertices * 3; ++i) {
        res.vertices[i] = static_cast<btScalar>(vertices[i]);
    }

    res.indices.resize(num_indices);
    for (size_t i = 0; i < num_indices; ++i) {
        res.indices[i] = static_cast<int>(indices[i]);
    }

    int num_triangles = static_cast<int>(num_indices / 3);
    res.index_vertex_array = std::make_unique<btTriangleIndexVertexArray>(
        num_triangles,
        res.indices.data(),
        3 * sizeof(int),
        static_cast<int>(num_vertices),
        res.vertices.data(),
        3 * sizeof(btScalar)
    );

    res.mesh_shape = std::make_unique<btBvhTriangleMeshShape>(res.index_vertex_array.get(), true);

    btTransform start_transform;
    start_transform.setIdentity();

    res.motion_state = std::make_unique<btDefaultMotionState>(start_transform);
    btRigidBody::btRigidBodyConstructionInfo rb_info(0.0f, res.motion_state.get(), res.mesh_shape.get(), btVector3(0, 0, 0));
    rb_info.m_restitution = 0.2f;
    rb_info.m_friction = 0.8f;

    res.rigid_body = std::make_unique<btRigidBody>(rb_info);
    res.rigid_body->setUserIndex(-static_cast<int>(col_id));

    world->dynamics_world->addRigidBody(res.rigid_body.get());
    world->mesh_colliders[col_id] = std::move(res);

    *out_id = col_id;
    return BULLET_SUCCESS;
}

int scr_bullet_remove_collider(SCRBulletWorldHandle handle, SCRColliderId collider_id) {
    if (!handle) return BULLET_ERR_NULL_HANDLE;
    auto* world = static_cast<BulletAdapterWorld*>(handle);
    auto it = world->mesh_colliders.find(collider_id);
    if (it == world->mesh_colliders.end()) return BULLET_ERR_BODY_NOT_FOUND;

    world->dynamics_world->removeRigidBody(it->second.rigid_body.get());
    world->mesh_colliders.erase(it);
    return BULLET_SUCCESS;
}

int scr_bullet_body_get_transform(SCRBulletWorldHandle handle, SCRRigidBodyId body_id, SCRVec3* out_pos, SCRQuat* out_rot) {
    if (!handle) return BULLET_ERR_NULL_HANDLE;
    auto* world = static_cast<BulletAdapterWorld*>(handle);
    auto it = world->bodies.find(body_id);
    if (it == world->bodies.end()) return BULLET_ERR_BODY_NOT_FOUND;

    btTransform trans;
    it->second.body->getMotionState()->getWorldTransform(trans);

    if (out_pos) {
        btVector3 origin = trans.getOrigin();
        out_pos->x = origin.x();
        out_pos->y = origin.y();
        out_pos->z = origin.z();
    }
    if (out_rot) {
        btQuaternion rot = trans.getRotation();
        out_rot->x = rot.x();
        out_rot->y = rot.y();
        out_rot->z = rot.z();
        out_rot->w = rot.w();
    }
    return BULLET_SUCCESS;
}

int scr_bullet_body_get_velocity(SCRBulletWorldHandle handle, SCRRigidBodyId body_id, SCRVec3* out_linear, SCRVec3* out_angular) {
    if (!handle) return BULLET_ERR_NULL_HANDLE;
    auto* world = static_cast<BulletAdapterWorld*>(handle);
    auto it = world->bodies.find(body_id);
    if (it == world->bodies.end()) return BULLET_ERR_BODY_NOT_FOUND;

    if (out_linear) {
        btVector3 v = it->second.body->getLinearVelocity();
        out_linear->x = v.x();
        out_linear->y = v.y();
        out_linear->z = v.z();
    }
    if (out_angular) {
        btVector3 w = it->second.body->getAngularVelocity();
        out_angular->x = w.x();
        out_angular->y = w.y();
        out_angular->z = w.z();
    }
    return BULLET_SUCCESS;
}

int scr_bullet_body_set_velocity(SCRBulletWorldHandle handle, SCRRigidBodyId body_id, SCRVec3 linear_vel, SCRVec3 angular_vel) {
    if (!handle) return BULLET_ERR_NULL_HANDLE;
    auto* world = static_cast<BulletAdapterWorld*>(handle);
    auto it = world->bodies.find(body_id);
    if (it == world->bodies.end()) return BULLET_ERR_BODY_NOT_FOUND;

    it->second.body->setLinearVelocity(btVector3(linear_vel.x, linear_vel.y, linear_vel.z));
    it->second.body->setAngularVelocity(btVector3(angular_vel.x, angular_vel.y, angular_vel.z));
    it->second.body->activate(true);
    return BULLET_SUCCESS;
}

int scr_bullet_body_apply_impulse(SCRBulletWorldHandle handle, SCRRigidBodyId body_id, SCRVec3 impulse, SCRVec3 rel_pos) {
    if (!handle) return BULLET_ERR_NULL_HANDLE;
    auto* world = static_cast<BulletAdapterWorld*>(handle);
    auto it = world->bodies.find(body_id);
    if (it == world->bodies.end()) return BULLET_ERR_BODY_NOT_FOUND;

    it->second.body->applyImpulse(
        btVector3(impulse.x, impulse.y, impulse.z),
        btVector3(rel_pos.x, rel_pos.y, rel_pos.z)
    );
    it->second.body->activate(true);
    return BULLET_SUCCESS;
}

int scr_bullet_body_remove(SCRBulletWorldHandle handle, SCRRigidBodyId body_id) {
    if (!handle) return BULLET_ERR_NULL_HANDLE;
    auto* world = static_cast<BulletAdapterWorld*>(handle);
    auto it = world->bodies.find(body_id);
    if (it == world->bodies.end()) return BULLET_ERR_BODY_NOT_FOUND;

    world->dynamics_world->removeRigidBody(it->second.body.get());
    world->bodies.erase(it);
    return BULLET_SUCCESS;
}

int scr_bullet_raycast(SCRBulletWorldHandle handle, SCRVec3 from, SCRVec3 to, SCRRigidRaycastHit* out_hit) {
    if (!handle || !out_hit) return BULLET_ERR_INVALID_PARAM;
    auto* world = static_cast<BulletAdapterWorld*>(handle);

    btVector3 bt_from(from.x, from.y, from.z);
    btVector3 bt_to(to.x, to.y, to.z);

    btCollisionWorld::ClosestRayResultCallback ray_cb(bt_from, bt_to);
    world->dynamics_world->rayTest(bt_from, bt_to, ray_cb);

    if (ray_cb.hasHit()) {
        out_hit->hit = 1;
        out_hit->fraction = ray_cb.m_closestHitFraction;
        out_hit->point = { ray_cb.m_hitPointWorld.x(), ray_cb.m_hitPointWorld.y(), ray_cb.m_hitPointWorld.z() };
        out_hit->normal = { ray_cb.m_hitNormalWorld.x(), ray_cb.m_hitNormalWorld.y(), ray_cb.m_hitNormalWorld.z() };
        out_hit->body_id = static_cast<uint32_t>(ray_cb.m_collisionObject->getUserIndex());
    } else {
        out_hit->hit = 0;
        out_hit->fraction = 1.0f;
        out_hit->point = { 0, 0, 0 };
        out_hit->normal = { 0, 1.0f, 0 };
        out_hit->body_id = 0;
    }
    return BULLET_SUCCESS;
}

int scr_bullet_get_active_body_count(SCRBulletWorldHandle handle, uint32_t* out_count) {
    if (!handle || !out_count) return BULLET_ERR_INVALID_PARAM;
    auto* world = static_cast<BulletAdapterWorld*>(handle);
    *out_count = static_cast<uint32_t>(world->bodies.size());
    return BULLET_SUCCESS;
}
