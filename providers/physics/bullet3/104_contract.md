# Bullet3 Physics Provider Contract

**Provider:** bullet3  
**Domain:** physics  
**Subdomains:** collision, dynamics, contact  
**Version:** 0.1.0  
**Status:** Normative Contract  
**Governing Documents:** [`docs/architecture/103_provider_contracts.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/architecture/103_provider_contracts.md), [`providers/physics/bullet3/101_definition.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/providers/physics/bullet3/101_definition.md)

---

## 1. Contract Overview
This document specifies the concrete Provider Contract implemented by the `bullet3` provider. It defines world lifecycle, dynamic rigid body creation, static triangle mesh colliders (OpenVDB terrain), physical raycasting, contact manifolds, and impulse integration.

---

## 2. Semantic Capabilities
* `[physics, world, lifecycle]` — Creation, gravity configuration, and destruction of discrete dynamics worlds.
* `[physics, body, dynamic_create]` — Registration of dynamic rigid bodies (Sphere, Box, Capsule) with mass, inertia, restitution ($e$), and friction ($\mu$).
* `[physics, collision, mesh_create]` — Registration of static concave BVH triangle mesh colliders.
* `[physics, query, raycast]` — Line-of-sight raycasting returning hit state, coordinates $\vec{x}$, normal $\hat{n}$, and fractional parameter $t^*$.
* `[physics, dynamics, step]` — Sub-stepped physics integration with impulse-based constraint resolution.

---

## 3. C-ABI Interface Signatures

```c
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

SCRBulletWorldHandle scr_bullet_world_create(SCRVec3 gravity);
void                 scr_bullet_world_destroy(SCRBulletWorldHandle world);
int                  scr_bullet_world_step(SCRBulletWorldHandle world, float dt, int max_substeps, float fixed_timestep);

int scr_bullet_create_sphere(SCRBulletWorldHandle world, float radius, float mass, SCRVec3 pos, float restitution, float friction, SCRRigidBodyId* out_id);
int scr_bullet_create_box(SCRBulletWorldHandle world, SCRVec3 half_extents, float mass, SCRVec3 pos, float restitution, float friction, SCRRigidBodyId* out_id);
int scr_bullet_create_capsule(SCRBulletWorldHandle world, float radius, float height, float mass, SCRVec3 pos, float restitution, float friction, SCRRigidBodyId* out_id);

int scr_bullet_create_triangle_mesh_collider(SCRBulletWorldHandle world, const float* vertices, size_t num_vertices, const uint32_t* indices, size_t num_indices, SCRColliderId* out_id);

int scr_bullet_body_get_transform(SCRBulletWorldHandle world, SCRRigidBodyId body_id, SCRVec3* out_pos, SCRQuat* out_rot);
int scr_bullet_body_set_velocity(SCRBulletWorldHandle world, SCRRigidBodyId body_id, SCRVec3 linear_vel, SCRVec3 angular_vel);
int scr_bullet_body_apply_impulse(SCRBulletWorldHandle world, SCRRigidBodyId body_id, SCRVec3 impulse, SCRVec3 rel_pos);

int scr_bullet_raycast(SCRBulletWorldHandle world, SCRVec3 from, SCRVec3 to, SCRRigidRaycastHit* out_hit);
int scr_bullet_get_active_body_count(SCRBulletWorldHandle world, uint32_t* out_count);
```

---

## 4. Preconditions & Invariants

1. **Precondition (Positive Mass for Dynamics):** Dynamic bodies require $m > 0$. Static bodies have $m = 0$.
2. **Precondition (Positive Timestep):** `dt > 0.0f`.
3. **Invariant (Non-Penetration):** Rigid bodies at rest do not sink through static collision mesh.
4. **Invariant (Restitution Energy Bound):** Bouncing bodies satisfy $v_{\text{rebound}} \le e \cdot v_{\text{impact}}$.

---

## 5. Failure Semantics & Error Codes
* `BULLET_SUCCESS = 0`
* `BULLET_ERR_NULL_HANDLE = -1`
* `BULLET_ERR_INVALID_PARAM = -2`
* `BULLET_ERR_BODY_NOT_FOUND = -3`
* `BULLET_ERR_MESH_FAILED = -4`
