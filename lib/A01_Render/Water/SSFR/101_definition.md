---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-RENDER-WATER-SSFR
name: Screen-Space Fluid Rendering Pipeline
version: 1.0.0
status: operational

created: 2026-09-17
updated: 2026-09-17

parent: SCR-LIB-RENDER-WATER
authority: SCR
domain: semantic-library
---

# SCR Render: Screen-Space Fluid Rendering (SSFR)

## Summary

Screen-Space Fluid Rendering (SSFR) transforms discrete 3D fluid particles into a continuous, optically realistic liquid surface entirely in screen space without constructing explicit 3D boundary meshes (Marching Cubes).

---

## 1. Pipeline Stages (Canonical SSFR Architecture)

### 1.1 Particle Depth & Thickness Generation (Point-Sprites)

Each fluid particle with position $\mathbf{p} \in \mathbb{R}^3$ and world-space radius $r$ is rasterized as a camera-facing point sprite.
Inside the sprite fragment shader:
$$\mathbf{r}_{\text{norm}} = (x_{\text{tex}}, y_{\text{tex}}) \in [-1, 1]^2$$
$$\Delta z = \sqrt{1.0 - x_{\text{tex}}^2 - y_{\text{tex}}^2} \quad \text{for } x_{\text{tex}}^2 + y_{\text{tex}}^2 \le 1.0$$
$$\text{Depth}_{\text{sphere}} = \text{Depth}_{\text{center}} - r \cdot \Delta z$$
$$\text{Thickness} += 2.0 \cdot r \cdot \Delta z$$

### 1.2 Depth-Aware Bilateral Smoothing Filter

To coalesce individual particle spheres into a continuous liquid manifold while preserving sharp physical silhouettes and boundary steps, a separable 2D bilateral filter is applied:
$$I_{\text{smooth}}(\mathbf{x}) = \frac{\sum_{\mathbf{y} \in \Omega} I(\mathbf{y}) \cdot G_{\sigma_s}(\|\mathbf{x} - \mathbf{y}\|) \cdot G_{\sigma_r}(|I(\mathbf{x}) - I(\mathbf{y})|)}{\sum_{\mathbf{y} \in \Omega} G_{\sigma_s}(\|\mathbf{x} - \mathbf{y}\|) \cdot G_{\sigma_r}(|I(\mathbf{x}) - I(\mathbf{y})|)}$$
where $G_{\sigma_s}$ is spatial Gaussian kernel and $G_{\sigma_r}$ is range depth-difference kernel.

### 1.3 Surface Normal Reconstruction from Depth Gradient

Given smoothed view-space position $\mathbf{P}(u, v) = \text{ReconstructViewPos}(u, v, z(u, v))$:
$$\frac{\partial \mathbf{P}}{\partial u} \approx \mathbf{P}(u + 1, v) - \mathbf{P}(u - 1, v)$$
$$\frac{\partial \mathbf{P}}{\partial v} \approx \mathbf{P}(u, v + 1) - \mathbf{P}(u, v - 1)$$
$$\mathbf{N} = \frac{\frac{\partial \mathbf{P}}{\partial u} \times \frac{\partial \mathbf{P}}{\partial v}}{\left\|\frac{\partial \mathbf{P}}{\partial u} \times \frac{\partial \mathbf{P}}{\partial v}\right\|}$$

### 1.4 Optical Extinction (Beer-Lambert Absorption Law)

Transmitted radiance through water depth $d$:
$$I_{\text{transmitted}}(\lambda) = I_{\text{background}}(\lambda) \cdot \exp(-\boldsymbol{\sigma}_a(\lambda) \cdot d)$$
where $\boldsymbol{\sigma}_a = (\sigma_r, \sigma_g, \sigma_b)$ is the wavelength-dependent spectral absorption coefficient (e.g. higher absorption in red wavelengths yielding deep blue/cyan hues).

### 1.5 Fresnel Reflectance & Screen-Space Refraction/Reflection

$$F(\mathbf{V}, \mathbf{N}) = F_0 + (1 - F_0) (1 - \max(0, \mathbf{V} \cdot \mathbf{N}))^5 \quad (F_0 = 0.02)$$
$$\mathbf{I}_{\text{final}} = F \cdot \mathbf{I}_{\text{reflection}} + (1 - F) \cdot \mathbf{I}_{\text{refraction}}$$
