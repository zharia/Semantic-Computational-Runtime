# SCR-LIB-RENDER-WATER: Multi-Spectral Ocean Water & Dynamic Foam Semantics

**Document ID:** `SCR-LIB-RENDER-WATER-101`  
**Semantic Domain:** `lib/A01_Render/Water`  
**Version:** 1.0.0  
**Authority:** Authoritative Specification  

---

## 1. Domain Purpose & Scope

Specifies the optical and morphological rendering contracts for dynamic stylized/photorealistic ocean water (Sea of Thieves aesthetic):
1. **Multi-Spectral Color Gradients**: Deep ocean abyss, tropical mid-depth cerulean, sunlit aquamarine crests.
2. **Subsurface Scattering (SSS)**: Solar light penetration and scattering through thin wave peaks and forward-facing swells.
3. **Dual-Zone Dynamic Foam**:
   - **Wave Crest Whitecaps**: Jacobian / elevation-driven crest turbulence.
   - **Shoreline Edge Foam**: Bathymetric depth-falloff contact foam along island beaches.
4. **Schlick-Fresnel Reflectance & Specular Glint**: High grazing-angle reflectance, sun specular glints with micro-facet roughness.

---

## 2. Color Palette & Optical Parameters (Sea of Thieves Tropical Aesthetic)

| Optical Component | sRGB Hex | Normalized Linear RGB | Physical Interpretation |
|---|---|---|---|
| `DEEP_ABYSS` | `#021a30` | `(0.008, 0.098, 0.188)` | Light extinction in ocean abyss (>15m) |
| `MID_CERULEAN` | `#056e8c` | `(0.020, 0.431, 0.549)` | Forward Rayleigh scattering at medium depth (3-10m) |
| `SHALLOW_TURQUOISE` | `#14c7b8` | `(0.078, 0.780, 0.722)` | Sand-floor reflected tropical shallows (<3m) |
| `SSS_SUNLIT_CYAN` | `#3af5db` | `(0.227, 0.961, 0.859)` | Subsurface forward scattering in thin wave crests |
| `FOAM_WHITECAP` | `#f0faff` | `(0.941, 0.980, 1.000)` | Aerated bubble foam on wave crests and shorelines |

### 2.1 Fresnel Reflectance Formulation

$$F(V, N) = F_0 + (1 - F_0) (1 - \max(0, \mathbf{V} \cdot \mathbf{N}))^5$$
where $F_0 = 0.02$ (water IOR $\eta = 1.333$).

### 2.2 Subsurface Scattering Formulation

$$I_{\text{SSS}} = \max(0, \mathbf{L} \cdot (-\mathbf{V}))^4 \cdot \text{clamp}\left(\frac{y - y_{\text{sea}}}{A_{\text{max}}}, 0, 1\right) \cdot \mathbf{C}_{\text{SSS}}$$
where $\mathbf{L}$ is light direction, $\mathbf{V}$ is view vector, and $y - y_{\text{sea}}$ is the wave elevation above resting sea level.

---

## 3. Shoreline & Bathymetric Depth Foam

Given terrain surface height $y_{\text{terrain}}(x, z)$ and wave height $y_{\text{water}}(x, z, t)$:
$$\Delta y = y_{\text{water}}(x, z, t) - y_{\text{terrain}}(x, z)$$
$$\text{Foam}_{\text{shore}} = \text{clamp}\left(1.0 - \frac{\Delta y}{d_{\text{foam}}}, 0, 1\right)^2 \cdot (0.6 + 0.4 \sin(6.0 \cdot \Delta y - 4.0 t))$$
where $d_{\text{foam}} = 1.8\text{m}$.
