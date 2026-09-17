/**
 * SCR Fluid Dynamics & Rheology Provider — Conformance Test Suite
 * ─────────────────────────────────────────────────────────────────────────────
 * Validates:
 * 1. Provider lifecycle & configuration
 * 2. Navier-Stokes slope gravity advection & velocity updates
 * 3. Bingham-plastic non-Newtonian yield stress & apparent viscosity
 * 4. Stefan-Boltzmann radiative cooling and thermal energy dissipation
 * 5. Crust formation below solidus temperature
 */

#include "../adapter/fluid_c_api.h"

#include <cassert>
#include <iostream>
#include <cmath>

void test_provider_lifecycle() {
    FluidDomainConfig cfg = { -100.0f, 100.0f, -100.0f, 100.0f, 0.0f, 64, 64 };
    FluidSolverHandle solver = fluid_solver_create(&cfg);
    assert(solver != nullptr);

    FluidProperties fp = { 2700.0f, 1500.0f, 300.0f, 1.0f, 0.05f };
    assert(fluid_solver_set_fluid_properties(solver, &fp) == FLUID_SUCCESS);

    ThermalProperties tp = { 295.0f, 1400.0f, 1050.0f, 1200.0f, 1e-6f, 0.9f, 20.0f };
    assert(fluid_solver_set_thermal_properties(solver, &tp) == FLUID_SUCCESS);

    fluid_solver_destroy(solver);
    std::cout << "  [PASS] Fluid Provider Lifecycle & Configuration" << std::endl;
}

void test_fluid_momentum_and_bingham_rheology() {
    FluidDomainConfig cfg = { -100.0f, 100.0f, -100.0f, 100.0f, 0.0f, 64, 64 };
    FluidSolverHandle solver = fluid_solver_create(&cfg);
    assert(solver != nullptr);

    // Setup an inclined downhill path (caldera at y=30, sea at y=10)
    assert(fluid_solver_add_inflow(solver, 0.0f, 30.0f, 0.0f, 2.0f, 1450.0f) == FLUID_SUCCESS);
    assert(fluid_solver_add_inflow(solver, 0.0f, 20.0f, 20.0f, 2.0f, 1400.0f) == FLUID_SUCCESS);
    assert(fluid_solver_add_inflow(solver, 0.0f, 10.0f, 40.0f, 2.0f, 1300.0f) == FLUID_SUCCESS);

    uint32_t node_count = 0;
    assert(fluid_solver_get_node_count(solver, &node_count) == FLUID_SUCCESS);
    assert(node_count == 3);

    // Run simulation step
    for (int step = 0; step < 50; ++step) {
        assert(fluid_solver_step(solver, 0.05f) == FLUID_SUCCESS);
    }

    FluidSample sample;
    assert(fluid_solver_sample_point(solver, 0.0f, 20.0f, &sample) == FLUID_SUCCESS);

    // Downhill flow should have accelerated
    assert(sample.speed > 0.0f);
    assert(sample.apparent_viscosity > 0.0f);
    assert(sample.temperature_k > 295.0f);

    fluid_solver_destroy(solver);
    std::cout << "  [PASS] Fluid Momentum & Bingham Plastic Rheology" << std::endl;
}

void test_thermal_dissipation_and_crust_formation() {
    FluidDomainConfig cfg = { -100.0f, 100.0f, -100.0f, 100.0f, 0.0f, 64, 64 };
    FluidSolverHandle solver = fluid_solver_create(&cfg);

    // Add node at 1040 K (below solidus 1050 K to verify crust growth)
    assert(fluid_solver_add_inflow(solver, 10.0f, 5.0f, 10.0f, 1.0f, 1040.0f) == FLUID_SUCCESS);

    // Advance time by 10 seconds
    for (int i = 0; i < 100; ++i) {
        fluid_solver_step(solver, 0.1f);
    }

    FluidNodeData data;
    assert(fluid_solver_get_node_data(solver, 0, &data) == FLUID_SUCCESS);

    // Temperature should have decreased and crust should have formed
    assert(data.temperature_k < 1040.0f);
    assert(data.crust_fraction > 0.0f);

    fluid_solver_destroy(solver);
    std::cout << "  [PASS] Thermal Radiative Dissipation & Crust Formation" << std::endl;
}

int main() {
    std::cout << "============================================================" << std::endl;
    std::cout << " Running Fluid Dynamics & Rheology Provider Conformance Test" << std::endl;
    std::cout << "============================================================" << std::endl;

    test_provider_lifecycle();
    test_fluid_momentum_and_bingham_rheology();
    test_thermal_dissipation_and_crust_formation();

    std::cout << std::endl;
    std::cout << "ALL FLUID PROVIDER CONFORMANCE TESTS PASSED!" << std::endl;
    return 0;
}
