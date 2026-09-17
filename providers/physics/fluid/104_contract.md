# Fluid Dynamics Provider Contract

**Provider:** fluid  
**Domain:** physics  
**Subdomain:** fluid  
**Version:** 0.1.0  
**Status:** Normative Contract  
**Governing Documents:** [`docs/architecture/103_provider_contracts.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/architecture/103_provider_contracts.md), [`providers/physics/fluid/101_definition.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/providers/physics/fluid/101_definition.md)

---

## 1. Contract Overview

This document specifies the concrete Provider Contract implemented by the `fluid` provider for the `physics/fluid` capability domain. It defines multi-node fluid simulation, non-Newtonian Bingham rheology, thermal energy transport, and boundary interactions.

---

## 2. Semantic Capabilities

* `[physics, fluid, solver_lifecycle]` — Initialization, parameterization, and destruction of fluid solvers.
* `[physics, fluid, non_newtonian_rheology]` — Bingham-plastic yield stress ($\tau_y$), apparent viscosity ($\mu_{\text{eff}}$), and shear rate calculations.
* `[physics, fluid, thermal_thermodynamics]` — Radiative cooling ($\epsilon \sigma T^4$), convection, and solidus crust formation.
* `[physics, fluid, terrain_interaction]` — Slope gravity advection, bed friction, and aquatic quenching.

---

## 3. Operations & C-ABI Signatures

```c
FluidSolverHandle fluid_solver_create(const FluidDomainConfig* config);
void              fluid_solver_destroy(FluidSolverHandle solver);

int fluid_solver_set_fluid_properties(FluidSolverHandle solver, const FluidProperties* props);
int fluid_solver_set_thermal_properties(FluidSolverHandle solver, const ThermalProperties* props);

int fluid_solver_add_inflow(FluidSolverHandle solver, float x, float y, float z, float discharge_rate, float temp_k);
int fluid_solver_step(FluidSolverHandle solver, float dt);

int fluid_solver_sample_point(FluidSolverHandle solver, float x, float y, float z, FluidSample* out_sample);
int fluid_solver_get_node_count(FluidSolverHandle solver, uint32_t* out_count);
int fluid_solver_get_node_data(FluidSolverHandle solver, uint32_t index, FluidNodeData* out_data);
```

---

## 4. Preconditions & Invariants

1. **Precondition (Positive Timestep):** `dt > 0.0f`.
2. **Precondition (Positive Density & Viscosity):** Density $\rho > 0.0f$, plastic viscosity $\mu_p \ge 0.0f$, yield stress $\tau_y \ge 0.0f$.
3. **Invariant (Thermal Positivity):** Temperature must strictly satisfy $T \ge T_{\text{ambient}} > 0.0\,\text{K}$.
4. **Invariant (Plug Flow Limit):** When shear stress $\tau \le \tau_y$, the shear rate $\dot{\gamma} = 0$, yielding rigid plug transport.

---

## 5. Failure Semantics & Error Codes

* `FLUID_SUCCESS = 0`
* `FLUID_ERR_NULL_HANDLE = -1`
* `FLUID_ERR_INVALID_ARGUMENT = -2`
* `FLUID_ERR_OUT_OF_BOUNDS = -3`
* `FLUID_ERR_NUMERICAL_INSTABILITY = -4`
