#include "../adapter/openvdb_c_api.h"
#include <cassert>
#include <iostream>
#include <cmath>

void test_scalar_sparse_allocation() {
    std::cout << "[Test 1] Scalar Sparse Allocation... ";
    VdbGridHandle grid = vdb_grid_create_scalar(0.0f);
    assert(grid != nullptr);
    assert(vdb_grid_active_voxel_count(grid) == 0);

    // Populate a single voxel
    int res = vdb_grid_set_voxel_scalar(grid, 10, 20, 30, 42.0f);
    assert(res == VDB_SUCCESS);
    assert(vdb_grid_active_voxel_count(grid) == 1);

    // Verify roundtrip
    float val = vdb_grid_get_voxel_scalar(grid, 10, 20, 30);
    assert(std::fabs(val - 42.0f) < 1e-5f);

    // Unset voxel reads background
    float bg = vdb_grid_get_voxel_scalar(grid, 0, 0, 0);
    assert(std::fabs(bg - 0.0f) < 1e-5f);

    vdb_grid_destroy(grid);
    std::cout << "PASSED\n";
}

void test_vector_field() {
    std::cout << "[Test 2] Vector Field Evaluation... ";
    VdbGridHandle vgrid = vdb_grid_create_vector();
    assert(vgrid != nullptr);

    int res = vdb_grid_set_voxel_vector(vgrid, 5, 5, 5, 1.0f, -2.5f, 3.2f);
    assert(res == VDB_SUCCESS);
    assert(vdb_grid_active_voxel_count(vgrid) == 1);

    float out_v[3] = {0.0f, 0.0f, 0.0f};
    res = vdb_grid_get_voxel_vector(vgrid, 5, 5, 5, out_v);
    assert(res == VDB_SUCCESS);
    assert(std::fabs(out_v[0] - 1.0f) < 1e-5f);
    assert(std::fabs(out_v[1] - (-2.5f)) < 1e-5f);
    assert(std::fabs(out_v[2] - 3.2f) < 1e-5f);

    vdb_grid_destroy(vgrid);
    std::cout << "PASSED\n";
}

void test_field_advection() {
    std::cout << "[Test 3] Field Advection Step... ";
    VdbGridHandle dgrid = vdb_grid_create_scalar(0.0f);
    VdbGridHandle vgrid = vdb_grid_create_vector();

    // Source density at (10, 10, 10)
    vdb_grid_set_voxel_scalar(dgrid, 10, 10, 10, 1.0f);
    vdb_grid_set_voxel_scalar(dgrid, 11, 10, 10, 1.0f);

    // Uniform velocity in X: vx = 2.0
    vdb_grid_set_voxel_vector(vgrid, 10, 10, 10, 2.0f, 0.0f, 0.0f);
    vdb_grid_set_voxel_vector(vgrid, 11, 10, 10, 2.0f, 0.0f, 0.0f);

    // Advect forward by dt = 0.5 (should shift density towards x = 11)
    int res = vdb_grid_advect(dgrid, vgrid, 0.5f);
    assert(res == VDB_SUCCESS);

    vdb_grid_destroy(dgrid);
    vdb_grid_destroy(vgrid);
    std::cout << "PASSED\n";
}

void test_error_handling() {
    std::cout << "[Test 4] Error Handling and Robustness... ";
    // Invalid handle checks
    assert(vdb_grid_set_voxel_scalar(nullptr, 0, 0, 0, 1.0f) == VDB_ERR_INVALID_HANDLE);
    assert(vdb_grid_active_voxel_count(nullptr) == 0);

    // Type mismatch check
    VdbGridHandle vgrid = vdb_grid_create_vector();
    assert(vdb_grid_set_voxel_scalar(vgrid, 0, 0, 0, 1.0f) == VDB_ERR_TYPE_MISMATCH);
    vdb_grid_destroy(vgrid);
    std::cout << "PASSED\n";
}

int main() {
    std::cout << "========================================\n";
    std::cout << " Running OpenVDB Provider Contract Tests\n";
    std::cout << "========================================\n";

    vdb_runtime_initialize();
    test_scalar_sparse_allocation();
    test_vector_field();
    test_field_advection();
    test_error_handling();
    vdb_runtime_shutdown();

    std::cout << "\nAll OpenVDB Contract Tests PASSED successfully.\n";
    return 0;
}
