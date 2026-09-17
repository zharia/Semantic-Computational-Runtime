# Fluid Dynamics & Rheology Provider (`SCR-PRV-PHYSICS-FLUID`)

**Path:** `providers/physics/fluid/101_definition.md`  
**Domain:** `physics`  
**Subdomain:** `fluid`  
**Status:** Normative Specification  
**Version:** 0.1.0  

---

## 1. Domain Identity & Scope

The **Fluid Dynamics & Rheology Provider** implements execution substrates and numerical simulation solvers for fluid mechanics across the SCR runtime. It supports both Newtonian and non-Newtonian multiphase fluids, covering incompressible Navier-Stokes flow, shallow-water hydrodynamic advection, Bingham-plastic yield stress behavior, thermal energy conservation, radiative dissipation, and boundary phase changes.

---

## 2. Theoretical & Physical Foundations

### 2.1 Navier-Stokes Conservation Equations
For an incompressible fluid continuum with density $\rho$, velocity field $\mathbf{u}$, pressure $p$, and dynamic stress tensor $\boldsymbol{\tau}$:
$$\nabla \cdot \mathbf{u} = 0 \quad \text{(Mass Conservation / Incompressibility)}$$
$$\rho \left( \frac{\partial \mathbf{u}}{\partial t} + (\mathbf{u} \cdot \nabla) \mathbf{u} \right) = -\nabla p + \nabla \cdot \boldsymbol{\tau} + \rho \mathbf{g} \quad \text{(Momentum Conservation)}$$

### 2.2 Non-Newtonian Bingham-Plastic Rheology
High-viscosity geomaterials such as molten silicate magma and lava exhibit Bingham-plastic rheology with yield stress $\tau_y$:
$$\begin{cases}
\dot{\gamma} = 0 & \text{for } \|\boldsymbol{\tau}\| \le \tau_y \quad \text{(Rigid Plug Flow)} \\
\boldsymbol{\tau} = \left( \frac{\tau_y}{\dot{\gamma}} + \mu_p \right) \dot{\boldsymbol{\gamma}} & \text{for } \|\boldsymbol{\tau}\| > \tau_y \quad \text{(Viscous Shear Flow)}
\end{cases}$$
where $\mu_p$ is plastic viscosity and $\dot{\gamma} = \|\dot{\boldsymbol{\gamma}}\|$ is the second invariant of the strain rate tensor.

### 2.3 Thermal Energy Advection & Stefan-Boltzmann Dissipation
Temperature evolution $T(\mathbf{x}, t)$ incorporates conduction, advection, and radiative/convective heat loss:
$$\rho c_p \left( \frac{\partial T}{\partial t} + \mathbf{u} \cdot \nabla T \right) = k \nabla^2 T - \dot{q}_{\text{rad}} - \dot{q}_{\text{conv}}$$
$$\dot{q}_{\text{rad}} = \epsilon \sigma (T^4 - T_{\text{ambient}}^4)$$
$$\dot{q}_{\text{conv}} = h_{\text{conv}} (T - T_{\text{ambient}})$$

When temperature falls below the solidus threshold $T_{\text{solidus}}$, the fluid undergoes crust formation and phase change to solid basalt/obsidian.

---

## 3. Normative Architectural Rules

1. **`PRV-FLD-001` (Boundary Protection)**: The provider acts as an execution substrate; semantic fluid contracts remain authoritative and independent of specific discretization schemes (Eulerian grid, SPH particles, or Shallow Water).
2. **`PRV-FLD-002` (Physical Conservation)**: Solvers must enforce conservation of mass and positivity of thermal energy ($T > 0\,\text{K}$).
3. **`PRV-FLD-003` (Rheological Fidelity)**: Non-Newtonian regimes must respect unyielded plug zones when shear stress falls below the critical threshold $\tau_y$.
