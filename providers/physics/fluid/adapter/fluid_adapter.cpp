/**
 * SCR Fluid Dynamics & Rheology Provider — Native C++ Adapter Implementation
 * ─────────────────────────────────────────────────────────────────────────────
 * Implements Navier-Stokes fluid momentum, Bingham-plastic yield stress,
 * thermal energy advection, Stefan-Boltzmann radiative dissipation,
 * and solidus crust phase change mechanics.
 */

#include "fluid_c_api.h"

#include <vector>
#include <cmath>
#include <algorithm>
#include <memory>
#include <cstring>

namespace {

const float STEFAN_BOLTZMANN = 5.670374419e-8f; // W/(m^2·K^4)
const float GRAVITY = 9.80665f;                 // m/s^2

struct InternalFluidNode {
    float x, y, z;
    float terrain_elevation;
    float depth;
    float width;
    float vx, vy, vz;
    float temperature_k;
    float crust_thickness; // 0.0 (molten) .. 1.0 (crusted)
    float discharge_inflow;
};

struct FluidSolverInternal {
    FluidDomainConfig config;
    FluidProperties   fluid_props;
    ThermalProperties thermal_props;

    std::vector<InternalFluidNode> nodes;
    float current_time = 0.0f;

    FluidSolverInternal(const FluidDomainConfig& cfg) : config(cfg) {
        // Default physical properties for basaltic volcanic lava
        fluid_props.density           = 2700.0f;  // kg/m^3
        fluid_props.yield_stress      = 1200.0f;  // Pa
        fluid_props.plastic_viscosity = 350.0f;   // Pa·s
        fluid_props.flow_index        = 1.0f;     // Bingham plastic
        fluid_props.bed_friction      = 0.045f;

        thermal_props.ambient_temp_k      = 295.0f;
        thermal_props.initial_temp_k      = 1450.0f;
        thermal_props.solidus_temp_k      = 1050.0f;
        thermal_props.specific_heat       = 1200.0f; // J/(kg·K)
        thermal_props.thermal_diffusivity = 1.2e-6f;
        thermal_props.emissivity          = 0.92f;
        thermal_props.convection_coeff    = 25.0f;
    }
};

} // namespace

extern "C" {

FluidSolverHandle fluid_solver_create(const FluidDomainConfig* config) {
    if (!config) return nullptr;
    auto* solver = new (std::nothrow) FluidSolverInternal(*config);
    return static_cast<FluidSolverHandle>(solver);
}

void fluid_solver_destroy(FluidSolverHandle handle) {
    if (!handle) return;
    delete static_cast<FluidSolverInternal*>(handle);
}

int fluid_solver_set_fluid_properties(FluidSolverHandle handle, const FluidProperties* props) {
    if (!handle || !props) return FLUID_ERR_NULL_HANDLE;
    if (props->density <= 0.0f || props->plastic_viscosity < 0.0f || props->yield_stress < 0.0f) {
        return FLUID_ERR_INVALID_ARGUMENT;
    }
    auto* solver = static_cast<FluidSolverInternal*>(handle);
    solver->fluid_props = *props;
    return FLUID_SUCCESS;
}

int fluid_solver_set_thermal_properties(FluidSolverHandle handle, const ThermalProperties* props) {
    if (!handle || !props) return FLUID_ERR_NULL_HANDLE;
    if (props->ambient_temp_k <= 0.0f || props->initial_temp_k <= 0.0f || props->solidus_temp_k <= 0.0f) {
        return FLUID_ERR_INVALID_ARGUMENT;
    }
    auto* solver = static_cast<FluidSolverInternal*>(handle);
    solver->thermal_props = *props;
    return FLUID_SUCCESS;
}

int fluid_solver_add_inflow(FluidSolverHandle handle, float x, float y, float z, float discharge_rate, float temp_k) {
    if (!handle) return FLUID_ERR_NULL_HANDLE;
    auto* solver = static_cast<FluidSolverInternal*>(handle);

    InternalFluidNode node;
    node.x = x;
    node.y = y;
    node.z = z;
    node.terrain_elevation = y;
    node.depth = std::max(0.5f, std::min(4.0f, discharge_rate * 0.8f));
    node.width = 4.5f;
    node.vx = 0.0f;
    node.vy = 0.0f;
    node.vz = 0.0f;
    node.temperature_k = temp_k > 0.0f ? temp_k : solver->thermal_props.initial_temp_k;
    node.crust_thickness = 0.0f;
    node.discharge_inflow = discharge_rate;

    solver->nodes.push_back(node);
    return FLUID_SUCCESS;
}

int fluid_solver_set_terrain_height(FluidSolverHandle handle, float x, float z, float elevation) {
    if (!handle) return FLUID_ERR_NULL_HANDLE;
    auto* solver = static_cast<FluidSolverInternal*>(handle);

    // Update nearest node's terrain height
    for (auto& n : solver->nodes) {
        float dx = n.x - x;
        float dz = n.z - z;
        if (dx * dx + dz * dz < 4.0f) {
            n.terrain_elevation = elevation;
            n.y = elevation + n.depth;
        }
    }
    return FLUID_SUCCESS;
}

int fluid_solver_step(FluidSolverHandle handle, float dt) {
    if (!handle) return FLUID_ERR_NULL_HANDLE;
    if (dt <= 0.0f) return FLUID_ERR_INVALID_ARGUMENT;

    auto* solver = static_cast<FluidSolverInternal*>(handle);
    solver->current_time += dt;

    const size_t N = solver->nodes.size();
    if (N == 0) return FLUID_SUCCESS;

    const auto& fp = solver->fluid_props;
    const auto& tp = solver->thermal_props;

    // 1. Solve Hydrodynamic Momentum & Non-Newtonian Rheology along Stream
    for (size_t i = 0; i < N; ++i) {
        auto& curr = solver->nodes[i];

        // Downhill Slope Vector
        float slope_x = 0.0f;
        float slope_z = 0.0f;
        float dh = 0.0f;

        if (i + 1 < N) {
            float dx = solver->nodes[i + 1].x - curr.x;
            float dz = solver->nodes[i + 1].z - curr.z;
            float dist = std::max(0.1f, std::sqrt(dx * dx + dz * dz));
            dh = curr.y - solver->nodes[i + 1].y; // Positive if descending
            slope_x = (dx / dist) * (dh / dist);
            slope_z = (dz / dist) * (dh / dist);
        } else if (i > 0) {
            float dx = curr.x - solver->nodes[i - 1].x;
            float dz = curr.z - solver->nodes[i - 1].z;
            float dist = std::max(0.1f, std::sqrt(dx * dx + dz * dz));
            dh = solver->nodes[i - 1].y - curr.y;
            slope_x = (dx / dist) * (dh / dist);
            slope_z = (dz / dist) * (dh / dist);
        }

        // Driving Gravity Acceleration parallel to slope
        float grav_acc_x = GRAVITY * slope_x;
        float grav_acc_z = GRAVITY * slope_z;

        // Effective Viscosity via Bingham Plastic Model:
        // mu_eff = mu_p + tau_y / (gamma_dot + epsilon)
        float cur_speed = std::sqrt(curr.vx * curr.vx + curr.vz * curr.vz);
        float shear_rate = std::max(0.01f, cur_speed / std::max(0.2f, curr.depth));
        
        // Temperature dependence: Viscosity increases exponentially as lava cools (Arrhenius)
        float temp_ratio = std::max(0.5f, std::min(2.0f, tp.initial_temp_k / std::max(300.0f, curr.temperature_k)));
        float thermal_visc_factor = std::pow(temp_ratio, 3.5f);
        
        float yield_stress_eff = fp.yield_stress * thermal_visc_factor;
        float apparent_viscosity = fp.plastic_viscosity * thermal_visc_factor + (yield_stress_eff / shear_rate);

        // Bed friction / Viscous resistance: a_visc = -(apparent_viscosity / (rho * depth^2)) * v
        float drag_coeff = (apparent_viscosity / (fp.density * std::max(0.1f, curr.depth * curr.depth))) + fp.bed_friction;
        
        // Velocity update with implicit damping for stability
        float new_vx = (curr.vx + grav_acc_x * dt) / (1.0f + drag_coeff * dt);
        float new_vz = (curr.vz + grav_acc_z * dt) / (1.0f + drag_coeff * dt);

        // Bingham Yield Criterion: If shear stress < tau_y, flow becomes plug flow or arrests
        float driving_shear = fp.density * GRAVITY * curr.depth * std::abs(dh);
        if (driving_shear < yield_stress_eff && cur_speed < 0.05f) {
            new_vx *= 0.85f;
            new_vz *= 0.85f;
        }

        curr.vx = new_vx;
        curr.vz = new_vz;

        // 2. Thermal Energy Conservation
        // Radiative heat flux: q_rad = eps * sigma * (T^4 - T_amb^4)
        float T4 = std::pow(curr.temperature_k, 4.0f);
        float T_amb4 = std::pow(tp.ambient_temp_k, 4.0f);
        float q_rad = tp.emissivity * STEFAN_BOLTZMANN * (T4 - T_amb4);

        // Convective heat flux: q_conv = h * (T - T_amb)
        float q_conv = tp.convection_coeff * (curr.temperature_k - tp.ambient_temp_k);

        // Net rate of cooling (K/s)
        float heat_loss_rate = (q_rad + q_conv) / (fp.density * tp.specific_heat * std::max(0.1f, curr.depth));
        curr.temperature_k = std::max(tp.ambient_temp_k, curr.temperature_k - heat_loss_rate * dt);

        // 3. Crust Formation Mechanics (Phase Change at T < T_solidus)
        if (curr.temperature_k < tp.solidus_temp_k) {
            float cool_depth = (tp.solidus_temp_k - curr.temperature_k) / (tp.solidus_temp_k - tp.ambient_temp_k);
            curr.crust_thickness = std::min(1.0f, curr.crust_thickness + cool_depth * dt * 0.08f);
        } else {
            // Remelting if hot influx occurs
            curr.crust_thickness = std::max(0.0f, curr.crust_thickness - dt * 0.05f);
        }
    }

    return FLUID_SUCCESS;
}

int fluid_solver_sample_point(FluidSolverHandle handle, float x, float z, FluidSample* out_sample) {
    if (!handle || !out_sample) return FLUID_ERR_NULL_HANDLE;
    auto* solver = static_cast<FluidSolverInternal*>(handle);

    if (solver->nodes.empty()) {
        std::memset(out_sample, 0, sizeof(FluidSample));
        return FLUID_SUCCESS;
    }

    // Find closest node
    float best_dist_sq = 1e9f;
    size_t best_idx = 0;
    for (size_t i = 0; i < solver->nodes.size(); ++i) {
        float dx = solver->nodes[i].x - x;
        float dz = solver->nodes[i].z - z;
        float dist_sq = dx * dx + dz * dz;
        if (dist_sq < best_dist_sq) {
            best_dist_sq = dist_sq;
            best_idx = i;
        }
    }

    const auto& node = solver->nodes[best_idx];
    out_sample->x = node.x;
    out_sample->y = node.y;
    out_sample->z = node.z;
    out_sample->velocity_x = node.vx;
    out_sample->velocity_y = node.vy;
    out_sample->velocity_z = node.vz;
    out_sample->speed = std::sqrt(node.vx * node.vx + node.vz * node.vz);
    out_sample->depth = node.depth;
    out_sample->temperature_k = node.temperature_k;
    out_sample->crust_thickness = node.crust_thickness;
    out_sample->shear_rate = out_sample->speed / std::max(0.1f, node.depth);

    float shear = std::max(0.01f, out_sample->shear_rate);
    out_sample->apparent_viscosity = solver->fluid_props.plastic_viscosity + (solver->fluid_props.yield_stress / shear);

    return FLUID_SUCCESS;
}

int fluid_solver_get_node_count(FluidSolverHandle handle, uint32_t* out_count) {
    if (!handle || !out_count) return FLUID_ERR_NULL_HANDLE;
    auto* solver = static_cast<FluidSolverInternal*>(handle);
    *out_count = static_cast<uint32_t>(solver->nodes.size());
    return FLUID_SUCCESS;
}

int fluid_solver_get_node_data(FluidSolverHandle handle, uint32_t index, FluidNodeData* out_data) {
    if (!handle || !out_data) return FLUID_ERR_NULL_HANDLE;
    auto* solver = static_cast<FluidSolverInternal*>(handle);
    if (index >= solver->nodes.size()) return FLUID_ERR_OUT_OF_BOUNDS;

    const auto& n = solver->nodes[index];
    out_data->x = n.x;
    out_data->y = n.y;
    out_data->z = n.z;
    out_data->vx = n.vx;
    out_data->vy = n.vy;
    out_data->vz = n.vz;
    out_data->depth = n.depth;
    out_data->width = n.width;
    out_data->temperature_k = n.temperature_k;
    out_data->crust_fraction = n.crust_thickness;
    out_data->velocity_mag = std::sqrt(n.vx * n.vx + n.vz * n.vz);

    return FLUID_SUCCESS;
}

} // extern "C"
