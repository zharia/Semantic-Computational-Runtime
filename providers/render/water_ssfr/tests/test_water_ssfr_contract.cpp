#include "water_ssfr_c_api.h"
#include <iostream>
#include <cassert>
#include <cmath>
#include <vector>

int main() {
    std::cout << "[TEST] Starting SCR Water SSFR & SPH Provider Contract Test...\n";

    WaterSSFRConfig config = {};
    config.domain_min_x = -10.0f; config.domain_max_x = 10.0f;
    config.domain_min_y = 0.0f;   config.domain_max_y = 20.0f;
    config.domain_min_z = -10.0f; config.domain_max_z = 10.0f;
    config.particle_radius = 0.15f;
    config.smoothing_radius = 0.40f;
    config.rest_density = 1000.0f;
    config.stiffness = 1500.0f;
    config.viscosity = 0.05f;
    config.surface_tension = 0.01f;
    config.gravity_y = -9.81f;
    config.max_particles = 1000;

    WaterSSFRHandle handle = scr_water_ssfr_create(&config);
    assert(handle != nullptr);
    std::cout << "  ✓ SPH/SSFR Solver handle created.\n";

    // Add a block of fluid particles
    for (int x = -2; x <= 2; ++x) {
        for (int y = 5; y <= 9; ++y) {
            for (int z = -2; z <= 2; ++z) {
                int res = scr_water_ssfr_add_particle(handle, x * 0.2f, y * 0.2f + 5.0f, z * 0.2f, 0, 0, 0);
                assert(res == WATER_SSFR_SUCCESS);
            }
        }
    }

    uint32_t count = 0;
    scr_water_ssfr_get_particle_count(handle, &count);
    std::cout << "  ✓ Added " << count << " SPH particles.\n";
    assert(count == 5 * 5 * 5);

    // Step simulation
    for (int step = 0; step < 20; ++step) {
        int res = scr_water_ssfr_step_simulation(handle, 0.016f);
        assert(res == WATER_SSFR_SUCCESS);
    }
    std::cout << "  ✓ Stepped SPH simulation for 20 frames.\n";

    // Verify particle state
    WaterParticleData pdata;
    int res = scr_water_ssfr_get_particle_data(handle, 0, &pdata);
    assert(res == WATER_SSFR_SUCCESS);
    std::cout << "  ✓ Particle 0 Pos: (" << pdata.x << ", " << pdata.y << ", " << pdata.z 
              << ") Density: " << pdata.density << " Pressure: " << pdata.pressure << "\n";
    assert(pdata.density > 0.0f);

    // Test Depth Rasterization & Bilateral Filtering
    CameraViewProjection cam = {};
    cam.eye_x = 0.0f; cam.eye_y = 6.0f; cam.eye_z = -5.0f;
    cam.forward_x = 0.0f; cam.forward_y = 0.0f; cam.forward_z = 1.0f;
    cam.up_x = 0.0f; cam.up_y = 1.0f; cam.up_z = 0.0f;
    cam.fov_y_rad = 1.047f; // 60 deg
    cam.aspect_ratio = 16.0f / 9.0f;
    cam.near_clip = 0.1f;
    cam.far_clip = 100.0f;

    const uint32_t W = 64;
    const uint32_t H = 64;
    std::vector<float> depth_buf(W * H, 1e9f);
    std::vector<float> smooth_depth(W * H, 1e9f);

    res = scr_water_ssfr_rasterize_depth(handle, &cam, W, H, depth_buf.data());
    assert(res == WATER_SSFR_SUCCESS);
    std::cout << "  ✓ Depth buffer rasterized (" << W << "x" << H << ").\n";

    res = scr_water_ssfr_bilateral_filter(handle, depth_buf.data(), smooth_depth.data(), W, H, 3, 2.0f, 0.5f);
    assert(res == WATER_SSFR_SUCCESS);
    std::cout << "  ✓ Bilateral edge-preserving depth filter evaluated.\n";

    float nx = 0, ny = 0, nz = 0;
    res = scr_water_ssfr_reconstruct_normal(handle, smooth_depth.data(), W, H, W / 2, H / 2, &nx, &ny, &nz);
    assert(res == WATER_SSFR_SUCCESS);
    std::cout << "  ✓ Reconstructed normal at center: (" << nx << ", " << ny << ", " << nz << ")\n";

    scr_water_ssfr_destroy(handle);
    std::cout << "  ✓ Handle destroyed cleanly.\n";
    std::cout << "[PASS] Water SSFR & SPH Contract Tests Passed!\n";
    return 0;
}
