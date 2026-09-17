---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-PHYSICS-FLUID-SPH
name: Smoothed Particle Hydrodynamics Fluid Physics
version: 1.0.0
status: operational

created: 2026-09-17
updated: 2026-09-17

parent: SCR-LIB-PHYSICS-FLUID
authority: SCR
domain: semantic-library
---

# SCR Physics: Smoothed Particle Hydrodynamics (SPH)

## Summary

Smoothed Particle Hydrodynamics (SPH) is a mesh-free Lagrangian computational method for simulating continuum fluid dynamics (Navier-Stokes equations) using localized kernel approximations.

---

## 1. Governing Mathematical Equations

### 1.1 Particle Density Interpolation (Poly6 Kernel)

Given smoothing radius $h$ and particle mass $m$:
$$W_{\text{poly6}}(\mathbf{r}, h) = \frac{315}{64\pi h^9} (h^2 - r^2)^3 \quad \text{for } 0 \le r \le h$$

Density at particle $i$:
$$\rho_i = \sum_{j} m_j W_{\text{poly6}}(\mathbf{r}_i - \mathbf{r}_j, h)$$

### 1.2 Tait Equation of State (EOS) for Pressure

To enforce near-incompressibility with stable explicit time stepping:
$$P_i = B \left( \left(\frac{\rho_i}{\rho_0}\right)^\gamma - 1 \right)$$
where $\rho_0$ is the reference rest density (e.g., $1000\,\text{kg/m}^3$), $\gamma = 7$, and $B = \frac{\rho_0 c_s^2}{\gamma}$ is the bulk modulus based on artificial speed of sound $c_s$.

### 1.3 Pressure Gradient Force (Spiky Kernel)

To prevent particle clustering under high compression:
$$\nabla W_{\text{spiky}}(\mathbf{r}, h) = -\frac{45}{\pi h^6} (h - r)^2 \frac{\mathbf{r}}{r} \quad \text{for } 0 \le r \le h$$

Symmetric pressure force on particle $i$:
$$\mathbf{F}_i^{\text{pressure}} = -m_i \sum_{j} m_j \left( \frac{P_i}{\rho_i^2} + \frac{P_j}{\rho_j^2} \right) \nabla W_{\text{spiky}}(\mathbf{r}_i - \mathbf{r}_j, h)$$

### 1.4 Viscosity Force (Laplacian Kernel)

$$\nabla^2 W_{\text{visc}}(\mathbf{r}, h) = \frac{45}{\pi h^6} (h - r) \quad \text{for } 0 \le r \le h$$

Viscous dissipation force on particle $i$:
$$\mathbf{F}_i^{\text{viscosity}} = \mu m_i \sum_{j} m_j \frac{\mathbf{v}_j - \mathbf{v}_i}{\rho_j} \nabla^2 W_{\text{visc}}(\mathbf{r}_i - \mathbf{r}_j, h)$$
where $\mu$ is dynamic viscosity.

### 1.5 Spatial Acceleration (Uniform Grid Hashing)

Neighbor search operates in $O(N)$ expected time via spatial hashing:
$$\text{CellIndex}(\mathbf{r}) = \left( \lfloor x/h \rfloor, \lfloor y/h \rfloor, \lfloor z/h \rfloor \right)$$
$$\text{Hash}(\mathbf{c}) = (c_x \cdot p_1 \oplus c_y \cdot p_2 \oplus c_z \cdot p_3) \pmod M$$
Sorted via Bitonic Radix Sort on GPU/CPU for contiguous memory cache traversal.

---

## 2. Invariant Conformance

- **PHYSICS-INV-001 (Semantic Primacy)**: Physical SPH semantics remain invariant across CPU/GPU implementations.
- **PHYSICS-INV-006 (Conservation)**: Linear and angular momentum are strictly conserved via symmetric kernel pairings.
- **PHYSICS-INV-014 (Dimensional Integrity)**: All quantities ($m$ [kg], $\rho$ [kg/m³], $P$ [Pa], $\mu$ [Pa·s]) conform to SI units.
