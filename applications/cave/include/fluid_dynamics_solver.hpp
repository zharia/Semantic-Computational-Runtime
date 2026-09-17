/**
 * SCR Application / Fluid Dynamics Solver Adapter
 * ─────────────────────────────────────────────────────────────────────────────
 * Bridges the SCR Fluid Dynamics Provider (SCR-PRV-PHYSICS-FLUID) to the
 * real-time procedural volcano and hydrothermal simulations in CAVE.
 */

#ifndef CAVE_FLUID_DYNAMICS_SOLVER_HPP
#define CAVE_FLUID_DYNAMICS_SOLVER_HPP

#include "../../../providers/physics/fluid/adapter/fluid_c_api.h"
#include "spatial_semantics.hpp"
#include "procedural_island.hpp"

#include <vector>
#include <cmath>
#include <iostream>

namespace SCR::Fluid {

class FluidDynamicsSolver {
private:
    FluidSolverHandle handle = nullptr;
    FluidDomainConfig config;
    FluidProperties   fluid_props;
    ThermalProperties thermal_props;
    float accumulated_time = 0.0f;

public:
    FluidDynamicsSolver() {
        config.min_x = -200.0f;
        config.max_x =  200.0f;
        config.min_z = -200.0f;
        config.max_z =  200.0f;
        config.base_elevation = 9.0f;
        config.resolution_x = 128;
        config.resolution_z = 128;

        handle = fluid_solver_create(&config);

        // Basaltic Magma / Lava Fluid Dynamics Properties
        fluid_props.density           = 2750.0f; // kg/m^3
        fluid_props.yield_stress      = 1400.0f; // Pa (Bingham plastic threshold)
        fluid_props.plastic_viscosity = 320.0f;  // Pa·s (Thick viscous molten silicate)
        fluid_props.flow_index        = 1.0f;
        fluid_props.bed_friction      = 0.05f;
        fluid_solver_set_fluid_properties(handle, &fluid_props);

        // High-Temperature Magmatic Thermodynamics
        thermal_props.ambient_temp_k      = 295.0f;  // 22°C ambient
        thermal_props.initial_temp_k      = 1450.0f; // ~1177°C glowing yellow incandescent
        thermal_props.solidus_temp_k      = 1050.0f; // ~777°C crust formation threshold
        thermal_props.specific_heat       = 1250.0f; // J/(kg·K)
        thermal_props.thermal_diffusivity = 1.2e-6f; // m^2/s
        thermal_props.emissivity          = 0.94f;   // High blackbody emissivity
        thermal_props.convection_coeff    = 28.0f;   // W/(m^2·K)
        fluid_solver_set_thermal_properties(handle, &thermal_props);
    }

    ~FluidDynamicsSolver() {
        if (handle) {
            fluid_solver_destroy(handle);
            handle = nullptr;
        }
    }

    // Disable copy, enable move
    FluidDynamicsSolver(const FluidDynamicsSolver&) = delete;
    FluidDynamicsSolver& operator=(const FluidDynamicsSolver&) = delete;
    FluidDynamicsSolver(FluidDynamicsSolver&& other) noexcept : handle(other.handle) {
        other.handle = nullptr;
    }
    FluidDynamicsSolver& operator=(FluidDynamicsSolver&& other) noexcept {
        if (this != &other) {
            if (handle) fluid_solver_destroy(handle);
            handle = other.handle;
            other.handle = nullptr;
        }
        return *this;
    }

    /**
     * Initializes the volcanic lava channel from caldera vent to ocean delta.
     */
    void initVolcanicChannel(const Island::VoxelIsland& island) {
        if (!handle) return;

        const int NUM_WAYPOINTS = 24;
        float start_x = island.center_x;
        float start_z = island.center_z - 2.0f;
        float end_x   = island.center_x + 2.0f;
        float end_z   = island.center_z - island.island_radius * 0.72f;

        for (int i = 0; i <= NUM_WAYPOINTS; ++i) {
            float t = float(i) / float(NUM_WAYPOINTS);
            // Sinuous meandering gravity channel
            float wx = (1.0f - t) * start_x + t * end_x + std::sin(t * 7.5f) * 3.2f + std::cos(t * 3.8f) * 1.6f;
            float wz = (1.0f - t) * start_z + t * end_z;
            float wy = island.getIslandHeight(wx, wz) + 0.12f;

            // Temperature gradient down the mountain: hotter at caldera vent
            float vent_temp = (1.0f - t * 0.35f) * thermal_props.initial_temp_k;
            float discharge = (t < 0.15f) ? 4.0f : (t > 0.85f) ? 3.5f : 2.2f;

            fluid_solver_add_inflow(handle, wx, wy, wz, discharge, vent_temp);
        }
    }

    /**
     * Step fluid dynamics physics.
     */
    void step(float dt, const Island::VoxelIsland& island) {
        if (!handle) return;
        accumulated_time += dt;

        // Update terrain elevations
        uint32_t count = 0;
        fluid_solver_get_node_count(handle, &count);
        for (uint32_t i = 0; i < count; ++i) {
            FluidNodeData data;
            if (fluid_solver_get_node_data(handle, i, &data) == FLUID_SUCCESS) {
                float h = island.getIslandHeight(data.x, data.z);
                fluid_solver_set_terrain_height(handle, data.x, data.z, h);
            }
        }

        fluid_solver_step(handle, dt);
    }

    uint32_t getNodeCount() const {
        if (!handle) return 0;
        uint32_t count = 0;
        fluid_solver_get_node_count(handle, &count);
        return count;
    }

    bool getNodeData(uint32_t index, FluidNodeData& out_data) const {
        if (!handle) return false;
        return fluid_solver_get_node_data(handle, index, &out_data) == FLUID_SUCCESS;
    }

    FluidSample samplePoint(float x, float z) const {
        FluidSample sample;
        if (handle) {
            fluid_solver_sample_point(handle, x, z, &sample);
        }
        return sample;
    }

    float getLavaFlowSpeed() const {
        if (!handle) return 0.85f;
        uint32_t count = 0;
        fluid_solver_get_node_count(handle, &count);
        if (count == 0) return 0.85f;

        float total_speed = 0.0f;
        for (uint32_t i = 0; i < count; ++i) {
            FluidNodeData d;
            if (fluid_solver_get_node_data(handle, i, &d) == FLUID_SUCCESS) {
                total_speed += d.velocity_mag;
            }
        }
        return std::max(0.4f, total_speed / float(count));
    }
};

} // namespace SCR::Fluid

#endif // CAVE_FLUID_DYNAMICS_SOLVER_HPP
