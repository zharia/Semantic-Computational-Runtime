// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "../adapter/chrono_c_api.h"

#include <iostream>
#include <cassert>
#include <cmath>

static void test_chrono_free_fall() {
    std::cout << "[Test 1] Chrono Free Fall Under Gravity... ";
    ChronoSystemHandle sys = chrono_system_create();
    assert(sys != nullptr);

    // Standard gravity: 0, -9.81, 0
    ChronoBodyId body_id = 0;
    ChronoVec3 initial_pos = { 0.0, 100.0, 0.0 };
    int rc = chrono_body_create(sys, 2.0, 1.0, 1.0, 1.0, initial_pos, &body_id);
    assert(rc == CHRONO_SUCCESS);
    assert(body_id != 0);

    // Step system for 1.0 second (100 steps of 0.01s)
    double dt = 0.01;
    for (int i = 0; i < 100; ++i) {
        rc = chrono_system_step(sys, dt);
        assert(rc == CHRONO_SUCCESS);
    }

    ChronoVec3 current_pos = { 0.0, 0.0, 0.0 };
    rc = chrono_body_get_position(sys, body_id, &current_pos);
    assert(rc == CHRONO_SUCCESS);

    ChronoVec3 current_vel = { 0.0, 0.0, 0.0 };
    rc = chrono_body_get_velocity(sys, body_id, &current_vel);
    assert(rc == CHRONO_SUCCESS);

    // Under symplectic Euler: v = -9.81 * 1.0 = -9.81 m/s
    assert(std::abs(current_vel.y - (-9.81)) < 0.1);
    // Distance fallen roughly 0.5 * 9.81 * 1^2 ~= 4.9m, so pos.y ~= 95.1m
    assert(current_pos.y < 100.0);
    assert(current_pos.y > 90.0);

    chrono_system_destroy(sys);
    std::cout << "PASSED (Final pos.y: " << current_pos.y << ", vel.y: " << current_vel.y << ")\n";
}

static void test_chrono_applied_force() {
    std::cout << "[Test 2] Chrono Force Application & Acceleration... ";
    ChronoSystemHandle sys = chrono_system_create();
    assert(sys != nullptr);

    // Turn off gravity for pure force test
    chrono_system_set_gravity(sys, 0.0, 0.0, 0.0);

    ChronoBodyId body_id = 0;
    ChronoVec3 initial_pos = { 0.0, 0.0, 0.0 };
    int rc = chrono_body_create(sys, 5.0, 1.0, 1.0, 1.0, initial_pos, &body_id); // 5 kg
    assert(rc == CHRONO_SUCCESS);

    // Apply 50 N in x direction: a = F/m = 50 / 5 = 10 m/s^2
    ChronoVec3 force = { 50.0, 0.0, 0.0 };
    rc = chrono_body_apply_force(sys, body_id, force);
    assert(rc == CHRONO_SUCCESS);

    // Step 0.5s
    rc = chrono_system_step(sys, 0.5);
    assert(rc == CHRONO_SUCCESS);

    ChronoVec3 vel = { 0.0, 0.0, 0.0 };
    rc = chrono_body_get_velocity(sys, body_id, &vel);
    assert(rc == CHRONO_SUCCESS);
    // vel.x = a * dt = 10 * 0.5 = 5.0 m/s
    assert(std::abs(vel.x - 5.0) < 1e-5);

    chrono_system_destroy(sys);
    std::cout << "PASSED (vel.x: " << vel.x << " m/s)\n";
}

static void test_chrono_error_handling() {
    std::cout << "[Test 3] Chrono Preconditions and Error Handling... ";
    ChronoBodyId id = 0;
    int rc = chrono_body_create(nullptr, 1.0, 1.0, 1.0, 1.0, {0,0,0}, &id);
    assert(rc == CHRONO_ERR_NULL_HANDLE);

    ChronoSystemHandle sys = chrono_system_create();
    rc = chrono_body_create(sys, -10.0, 1.0, 1.0, 1.0, {0,0,0}, &id); // negative mass
    assert(rc == CHRONO_ERR_INVALID_PARAMETER);

    rc = chrono_system_step(sys, -0.1); // negative dt
    assert(rc == CHRONO_ERR_INVALID_PARAMETER);

    ChronoVec3 pos;
    rc = chrono_body_get_position(sys, 9999, &pos); // body does not exist
    assert(rc == CHRONO_ERR_BODY_NOT_FOUND);

    chrono_system_destroy(sys);
    std::cout << "PASSED\n";
}

int main() {
    std::cout << "========================================\n";
    std::cout << " Running Chrono Provider Contract Tests\n";
    std::cout << "========================================\n";
    test_chrono_free_fall();
    test_chrono_applied_force();
    test_chrono_error_handling();
    std::cout << "\nAll Chrono Contract Tests PASSED successfully.\n\n";
    return 0;
}
