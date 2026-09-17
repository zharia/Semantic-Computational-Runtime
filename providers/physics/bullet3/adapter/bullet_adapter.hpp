#ifndef SCR_PROVIDERS_PHYSICS_BULLET3_ADAPTER_HPP
#define SCR_PROVIDERS_PHYSICS_BULLET3_ADAPTER_HPP

#include <cstdint>
#include <cstddef>
#include <memory>
#include <vector>
#include <map>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* SCRBulletWorldHandle;
typedef uint32_t SCRRigidBodyId;
typedef uint32_t SCRColliderId;

typedef struct {
    float x, y, z;
} SCRVec3;

typedef struct {
    float x, y, z, w;
} SCRQuat;

typedef struct {
    int hit;
    float fraction;
    SCRVec3 point;
    SCRVec3 normal;
    uint32_t body_id;
} SCRRigidRaycastHit;

// Error codes
#define BULLET_SUCCESS 0
#define BULLET_ERR_NULL_HANDLE -1
#define BULLET_ERR_INVALID_PARAM -2
#define BULLET_ERR_BODY_NOT_FOUND -3
#define BULLET_ERR_MESH_FAILED -4

SCRBulletWorldHandle scr_bullet_world_create(SCRVec3 gravity);
void                 scr_bullet_world_destroy(SCRBulletWorldHandle world);
int                  scr_bullet_world_step(SCRBulletWorldHandle world, float dt, int max_substeps, float fixed_timestep);

int scr_bullet_create_sphere(SCRBulletWorldHandle world, float radius, float mass, SCRVec3 pos, float restitution, float friction, SCRRigidBodyId* out_id);
int scr_bullet_create_box(SCRBulletWorldHandle world, SCRVec3 half_extents, float mass, SCRVec3 pos, float restitution, float friction, SCRRigidBodyId* out_id);
int scr_bullet_create_capsule(SCRBulletWorldHandle world, float radius, float height, float mass, SCRVec3 pos, float restitution, float friction, SCRRigidBodyId* out_id);

int scr_bullet_create_triangle_mesh_collider(SCRBulletWorldHandle world, const float* vertices, size_t num_vertices, const uint32_t* indices, size_t num_indices, SCRColliderId* out_id);
int scr_bullet_remove_collider(SCRBulletWorldHandle world, SCRColliderId collider_id);

int scr_bullet_body_get_transform(SCRBulletWorldHandle world, SCRRigidBodyId body_id, SCRVec3* out_pos, SCRQuat* out_rot);
int scr_bullet_body_get_velocity(SCRBulletWorldHandle world, SCRRigidBodyId body_id, SCRVec3* out_linear, SCRVec3* out_angular);
int scr_bullet_body_set_velocity(SCRBulletWorldHandle world, SCRRigidBodyId body_id, SCRVec3 linear_vel, SCRVec3 angular_vel);
int scr_bullet_body_apply_impulse(SCRBulletWorldHandle world, SCRRigidBodyId body_id, SCRVec3 impulse, SCRVec3 rel_pos);
int scr_bullet_body_remove(SCRBulletWorldHandle world, SCRRigidBodyId body_id);

int scr_bullet_raycast(SCRBulletWorldHandle world, SCRVec3 from, SCRVec3 to, SCRRigidRaycastHit* out_hit);
int scr_bullet_get_active_body_count(SCRBulletWorldHandle world, uint32_t* out_count);

#ifdef __cplusplus
}
#endif

#endif // SCR_PROVIDERS_PHYSICS_BULLET3_ADAPTER_HPP
