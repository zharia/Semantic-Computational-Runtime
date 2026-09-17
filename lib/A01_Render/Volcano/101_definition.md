# SCR-LIB-RENDER-VOLCANO — Volcanic Magma Flows & Caldera Smoke Plume Contract

**Status:** Authoritative  
**Domain:** `SCR::Render::Volcano`  
**Governing Principle:** *Physically-derived multi-phase volcanic thermodynamics and optical emission.*

---

## 1. Scope & Semantic Authority

This specification defines normative optical, kinematic, and thermodynamic representations for:
1. **Molten Lava Cascades & Rivers (`VolcanicLavaFlow`)**: High-temperature non-Newtonian Bingham fluid flow ($T \sim 1100\text{K}-1400\text{K}$), crust solidification, incandescent fractures, and dynamic thermal emission.
2. **Convective Caldera Smoke & Ash Plumes (`VolcanicSmokePlume`)**: Buoyant thermal updrafts, expanding turbulent billows, vortex curl advection, and atmospheric ash dispersion.

---

## 2. Mathematical Formulations

### 2.1 Incandescent Magma Blackbody Radiance & Crust Formation
Lava luminance and color temperature are modeled by Planckian emission with crust factor $C(u, v, t) \in [0, 1]$:

$$L(\mathbf{x}, t) = (1 - C(\mathbf{x}, t)) \cdot \mathbf{E}_{\text{core}} + C(\mathbf{x}, t) \cdot \mathbf{E}_{\text{crust}}$$

Where:
* $\mathbf{E}_{\text{core}} = (1.0, 0.72, 0.12)$ (Incandescent bright gold-white molten core)
* $\mathbf{E}_{\text{crust}} = (0.12, 0.04, 0.02)$ (Dark cooled basaltic crust with deep red glowing seams)
* Crust tearing pattern $C(\mathbf{x}, t)$ is synthesized via multi-frequency domain-warped Perlin-Worley shear flow:
  $$\mathbf{u}' = \mathbf{u} + \mathbf{v}_{\text{flow}} \cdot t + \nabla \times \psi(\mathbf{u})$$

### 2.2 Caldera Smoke Plume Kinematics
The buoyant thermal plume rises from caldera crater radius $R_0$ at elevation $z_0$:

$$w(z) = w_0 \cdot \left(\frac{z - z_0}{H_{\text{ref}}}\right)^{-1/3}$$
$$R(z) = R_0 + \alpha \cdot (z - z_0) + \beta \cdot \sin(\omega t + k z)$$

Where:
* $w_0 \approx 8.5\text{ m/s}$ (Initial caldera ejection velocity)
* $\alpha \approx 0.28$ (Turbulent entrainment expansion rate)
* Billow density optical extinction:
  $$\rho(\mathbf{x}, t) = \rho_0 \cdot \exp\left(-\frac{\|\mathbf{x}_{\perp} - \mathbf{c}(z, t)\|^2}{2 R(z)^2}\right) \cdot \text{FBM}(\mathbf{x} - \mathbf{v}_{\text{wind}} t)$$
