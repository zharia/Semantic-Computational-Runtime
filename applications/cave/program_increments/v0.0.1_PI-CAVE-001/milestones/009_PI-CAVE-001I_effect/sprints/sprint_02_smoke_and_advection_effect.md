# Sprint 02: Minimum Smoke & Advection Field Effect

**Parent Milestone:** [Milestone 009: PI-CAVE-001I Semantic Field Effects](../spec.md)  
**Derived from:** `spec.md` (Sections 25, 78)  
**Governing Documents:** [`docs/117_FIELD_PARTITIONING_AND_DISTRIBUTED_EXECUTION.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/117_FIELD_PARTITIONING_AND_DISTRIBUTED_EXECUTION.md)  
**Status:** Planned  

---

## 1. Mission

Implement the core algorithmic pipeline for the minimum smoke effect in C++/OpenVDB: inject velocity vectors along moving window edges, inject smoke density, and execute semi-Lagrangian advection and dissipation across sparse OpenVDB grids.

---

## 2. Technical Specifications & Algorithm

### 2.1 Velocity & Density Injection
For each moving surface quad during frame $\Delta t$:
1. Calculate window linear velocity: $\vec{v}_{\text{win}} = \frac{\vec{p}_t - \vec{p}_{t-1}}{\Delta t}$.
2. If $\|\vec{v}_{\text{win}}\| > v_{\text{threshold}}$:
   - Identify trailing edge of the quad opposite to direction of motion.
   - Rasterize voxels along trailing edge into `openvdb::Vec3SGrid` setting velocity $=\vec{v}_{\text{win}}$.
   - Rasterize voxels into `openvdb::FloatGrid` setting density $\rho = \min(1.0, \|\vec{v}_{\text{win}}\| \times 0.5)$.

### 2.2 Semi-Lagrangian Advection
On each frame step:
$$\rho(\vec{x}, t + \Delta t) = \rho(\vec{x} - \vec{v}(\vec{x}) \cdot \Delta t, t) \times (1.0 - \text{decay\_rate} \times \Delta t)$$
* Trace velocity backwards in index space.
* Trilinearly sample previous density at backtraced point.
* Apply linear dissipation to gradually extinguish lingering density.

---

## 3. Verification & Testing Tasks

1. **Stationary Window Test:** Stationary window must inject zero velocity and zero density.
2. **Impulse Dissipation Benchmark:** Move window rapidly across screen, then stop; verify that active voxel count returns to zero within 3.0 seconds.
3. **Advection Performance Benchmark:** Advection step on $< 100,000$ active voxels must execute in $< 5\text{ms}$ on CPU.
