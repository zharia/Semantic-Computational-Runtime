---
document: 101_definition
document_type: provider_specification
schema_version: 1.0.0

id: SCR-PROVIDER-RENDER-WATER-SSFR
name: Water SSFR & SPH Canonical Provider
version: 1.0.0
status: operational

created: 2026-09-17
updated: 2026-09-17

parent: SCR-LIB-RENDER-WATER-SSFR
authority: SCR
domain: provider
---

# SCR Provider: Canonical SPH & Screen-Space Fluid Rendering

## 1. Provider Identity

Implements the high-performance SPH physics and Screen-Space Fluid Rendering pipeline based on the architecture of `talvinckb/OpenGL-Water-Simulation`.

## 2. Capabilities

1. **Particle System**: SPH density/pressure/viscosity solver with Tait equation of state and spatial hash neighbor searching.
2. **Screen-Space Depth Generation**: Point-sprite camera depth rasterization with spherical cap reconstruction.
3. **Bilateral Filtering**: 2D edge-preserving spatial/range depth smoothing.
4. **Surface Normal Reconstruction**: Direct gradient calculation $\mathbf{N} = (-\partial z/\partial x, -\partial z/\partial y, 1) / \|\dots\|$.
5. **Optical Extinction**: Multi-spectral Beer-Lambert depth absorption, Schlick-Fresnel reflection, and specular lighting.
