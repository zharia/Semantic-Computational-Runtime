#include "../adapter/bullet_adapter.hpp"
#include <iostream>
#include <cassert>
#include <cmath>

int main() {
    std::cout << "[Test] Initializing Bullet3 Physics Contract Test Suite..." << std::endl;

    // 1. World Lifecycle
    SCRVec3 gravity = { 0.0f, -9.81f, 0.0f };
    SCRBulletWorldHandle world = scr_bullet_world_create(gravity);
    assert(world != nullptr);
    std::cout << "  [PASS] World created with gravity (0, -9.81, 0)" << std::endl;

    // 2. Dynamic Sphere Creation & Gravity Fall
    SCRRigidBodyId sphere_id = 0;
    SCRVec3 start_pos = { 0.0f, 10.0f, 0.0f };
    int res = scr_bullet_create_sphere(world, 0.5f, 2.0f, start_pos, 0.5f, 0.5f, &sphere_id);
    assert(res == BULLET_SUCCESS);
    assert(sphere_id > 0);
    std::cout << "  [PASS] Dynamic sphere created (ID: " << sphere_id << ") at y=10.0m" << std::endl;

    // 3. Static Ground Box Collider
    SCRRigidBodyId ground_id = 0;
    SCRVec3 ground_half = { 50.0f, 1.0f, 50.0f };
    SCRVec3 ground_pos = { 0.0f, -1.0f, 0.0f };
    res = scr_bullet_create_box(world, ground_half, 0.0f, ground_pos, 0.5f, 0.5f, &ground_id);
    assert(res == BULLET_SUCCESS);
    std::cout << "  [PASS] Static ground plane created at y=-1.0m" << std::endl;

    // 4. Time Step & Collision Impact
    for (int i = 0; i < 300; ++i) {
        scr_bullet_world_step(world, 1.0f / 60.0f, 10, 1.0f / 240.0f);
    }

    SCRVec3 current_pos = { 0, 0, 0 };
    SCRQuat current_rot = { 0, 0, 0, 1 };
    scr_bullet_body_get_transform(world, sphere_id, &current_pos, &current_rot);
    std::cout << "  [Info] Sphere settled at y=" << current_pos.y << "m" << std::endl;

    // The sphere with radius 0.5 resting on ground with top surface at y=0.0m must have y ~ 0.5m
    assert(current_pos.y >= 0.45f && current_pos.y <= 0.55f);
    std::cout << "  [PASS] Non-penetration invariant verified: Sphere rested on ground at y=" << current_pos.y << "m" << std::endl;

    // 5. Raycast Query
    SCRRigidRaycastHit hit;
    SCRVec3 ray_from = { 0.0f, 20.0f, 0.0f };
    SCRVec3 ray_to = { 0.0f, -10.0f, 0.0f };
    res = scr_bullet_raycast(world, ray_from, ray_to, &hit);
    assert(res == BULLET_SUCCESS);
    assert(hit.hit == 1);
    std::cout << "  [PASS] Raycast hit at point (" << hit.point.x << ", " << hit.point.y << ", " << hit.point.z << ") normal ("
              << hit.normal.x << ", " << hit.normal.y << ", " << hit.normal.z << ")" << std::endl;
    assert(std::abs(hit.point.y - 1.0f) < 0.1f); // hit top of sphere at y ~ 1.0m

    // 6. Cleanup
    scr_bullet_world_destroy(world);
    std::cout << "  [PASS] World destroyed successfully." << std::endl;

    std::cout << "\n✅ ALL BULLET3 PROVIDER CONTRACT TESTS PASSED!\n" << std::endl;
    return 0;
}
