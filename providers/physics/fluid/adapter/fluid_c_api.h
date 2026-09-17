/**
 * SCR Fluid Dynamics & Rheology Provider — C ABI Interface
 * ─────────────────────────────────────────────────────────────────────────────
 * Normative Header: providers/physics/fluid/adapter/fluid_c_api.h
 */

#ifndef SCR_FLUID_C_API_H
#define SCR_FLUID_C_API_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Error Codes
#define FLUID_SUCCESS                     0
#define FLUID_ERR_NULL_HANDLE            -1
#define FLUID_ERR_INVALID_ARGUMENT       -2
#define FLUID_ERR_OUT_OF_BOUNDS          -3
#define FLUID_ERR_NUMERICAL_INSTABILITY  -4

// Opaque Solver Handle
typedef void* FluidSolverHandle;

// Fluid Domain Configuration
typedef struct {
    float min_x, max_x;
    float min_z, max_z;
    float base_elevation;
    uint32_t resolution_x;
    uint32_t resolution_z;
} FluidDomainConfig;

// Non-Newtonian Rheology Properties
typedef struct {
    float density;             // kg/m^3 (e.g. 2700 for basaltic lava, 1000 for water)
    float yield_stress;        // Pa (tau_y, e.g. 1500 for lava, 0 for Newtonian water)
    float plastic_viscosity;   // Pa·s (mu_p, e.g. 250 for lava, 0.001 for water)
    float flow_index;          // Herschel-Bulkley exponent (1.0 = Bingham)
    float bed_friction;        // Dimensionless Manning roughness / basal drag
} FluidProperties;

// Thermal and Phase-Change Properties
typedef struct {
    float ambient_temp_k;      // K (e.g. 295 K)
    float initial_temp_k;      // K (e.g. 1450 K for molten lava)
    float solidus_temp_k;      // K (temperature below which crust solidifies, e.g. 1050 K)
    float specific_heat;       // J/(kg·K)
    float thermal_diffusivity; // m^2/s
    float emissivity;          // Stefan-Boltzmann surface emissivity (0..1, e.g. 0.92)
    float convection_coeff;    // W/(m^2·K)
} ThermalProperties;

// Sample point query result
typedef struct {
    float x, y, z;
    float velocity_x;
    float velocity_y;
    float velocity_z;
    float speed;
    float depth;
    float temperature_k;
    float apparent_viscosity;
    float crust_thickness;     // 0.0 = fully molten, 1.0 = fully solidified crust
    float shear_rate;
} FluidSample;

// Node data for mesh synthesis
typedef struct {
    float x, y, z;
    float vx, vy, vz;
    float depth;
    float width;
    float temperature_k;
    float crust_fraction;
    float velocity_mag;
} FluidNodeData;

// API Functions
FluidSolverHandle fluid_solver_create(const FluidDomainConfig* config);
void              fluid_solver_destroy(FluidSolverHandle solver);

int fluid_solver_set_fluid_properties(FluidSolverHandle solver, const FluidProperties* props);
int fluid_solver_set_thermal_properties(FluidSolverHandle solver, const ThermalProperties* props);

int fluid_solver_add_inflow(FluidSolverHandle solver, float x, float y, float z, float discharge_rate, float temp_k);
int fluid_solver_set_terrain_height(FluidSolverHandle solver, float x, float z, float elevation);
int fluid_solver_step(FluidSolverHandle solver, float dt);

int fluid_solver_sample_point(FluidSolverHandle solver, float x, float z, FluidSample* out_sample);
int fluid_solver_get_node_count(FluidSolverHandle solver, uint32_t* out_count);
int fluid_solver_get_node_data(FluidSolverHandle solver, uint32_t index, FluidNodeData* out_data);

#ifdef __cplusplus
}
#endif

#endif // SCR_FLUID_C_API_H
