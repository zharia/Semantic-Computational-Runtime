---
sprint: sprint_06_fluids_solutes_atmospheric_gases
document_type: normative_sprint_specification
milestone: 001_MaterialLibraryExpansion
schema_version: 1.0.0
id: SCR-PI-002-M001-S06
name: Reactive Fluids, Solutes & Atmospheric Gases
status: ready
created: 2026-09-16
authority: SCR
---

# Sprint 06: Reactive Fluids, Solutes & Atmospheric Gases

**Path:** `program_increments/v0.0.2/milestones/001_MaterialLibraryExpansion/sprints/sprint_06_fluids_solutes_atmospheric_gases/spec.md`  
**Parent Milestone:** [001_MaterialLibraryExpansion](../../README.md)  
**Parent Specification:** [spec.md](../../spec.md)  

---

## 1. Sprint Objective

Expand the fluidic and multiphase media domain with liquid hydrocarbons, chemical solvents, atmospheric gases, and particulate aerosols. Establish multiphase density stratification (immiscibility), gas expansion dynamics, and combustion stoichiometry.

---

## 2. Normative Material Catalog Additions

### 2.1 `fluid.oil` — Crude Petroleum / Liquid Hydrocarbon
* **Description:** Viscous liquid mixture of hydrocarbons exhibiting density lower than water ($850\text{ kg/m}^3$), insolubility in water, and high flammability.
* **Archetypal Provenance:** Universal Energy/Fluid Mechanics

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `850.0 kg/m^3` (Buoyant on water)
- Mohs Hardness: `0.0`
- Dynamic Viscosity ($\eta$): `0.05 Pa·s`
- Young's Modulus ($E$): `1.2 GPa` | Poisson's Ratio ($\nu$): `0.5`
- Coulomb Friction ($\mu$): `0.02` (Extreme lubricant) | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `10000.0 J`
- Thermal Conductivity ($k$): `0.14 W/(m·K)` | Specific Heat ($c_p$): `2000.0 J/(kg·K)`
- Kinematic Gravity: `True` | Flammable: `True`
- Optimal Harvest Tool: `bucket`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `dielectric_specular_coated_diffuse` (Closure: `BSDF_COATED_DIFFUSE`)
- Base Albedo (Linear sRGB): `[0.05, 0.04, 0.03]`
- Microfacet Roughness ($\alpha$): `0.05` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.48` | Transmittance ($\tau$): `0.01`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `specular_boundary_plus_vdf`

---

### 2.2 `fluid.acid` — Mineral Acid / Corrosive Hydronium Solution
* **Description:** Highly reactive aqueous hydronium solvent capable of rapidly etching and dissolving metals, carbonates, and biological tissues.
* **Archetypal Provenance:** Universal Industrial Chemistry/Hazard

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `1250.0 kg/m^3`
- Mohs Hardness: `0.0`
- Dynamic Viscosity ($\eta$): `0.002 Pa·s`
- Young's Modulus ($E$): `2.4 GPa` | Poisson's Ratio ($\nu$): `0.5`
- Coulomb Friction ($\mu$): `0.05` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `20000.0 J`
- Thermal Conductivity ($k$): `0.55 W/(m·K)` | Specific Heat ($c_p$): `3500.0 J/(kg·K)`
- Kinematic Gravity: `True` | Flammable: `False`
- Optimal Harvest Tool: `glass_vessel`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `dielectric_refractive_volume` (Closure: `BSDF_DIELECTRIC_LIQUID`)
- Base Albedo (Linear sRGB): `[0.45, 0.95, 0.25]` (Translucent toxic green)
- Microfacet Roughness ($\alpha$): `0.01` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.38` | Transmittance ($\tau$): `0.9`
- Radiative Emission ($L_e$): `50.0 cd/m^2` (Faint luminescence)
- Hypergraph Layering Topology: `specular_boundary_plus_vdf`

---

### 2.3 `gas.steam` — Water Vapor / Steam
* **Description:** Gaseous phase of water formed by vaporization above $373.15\text{ K}$; exhibits positive upward buoyancy and high thermal enthalpy.
* **Archetypal Provenance:** Universal Thermodynamics/Fluid Power

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `0.6 kg/m^3` (Upward convective buoyancy)
- Mohs Hardness: `0.0`
- Young's Modulus ($E$): `0.0001 GPa` | Poisson's Ratio ($\nu$): `0.5`
- Coulomb Friction ($\mu$): `0.0` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `100000.0 J`
- Thermal Conductivity ($k$): `0.025 W/(m·K)` | Specific Heat ($c_p$): `2080.0 J/(kg·K)`
- Kinematic Gravity: `False` (Convective ascent) | Flammable: `False`
- Optimal Harvest Tool: `none`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `two_sided_thin_surface_translucent` (Closure: `BSDF_THIN_SURFACE_TRANSLUCENT`)
- Base Albedo (Linear sRGB): `[0.95, 0.95, 0.98]`
- Microfacet Roughness ($\alpha$): `0.85` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.00028` | Transmittance ($\tau$): `0.85`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `pure_participating_volume`

---

### 2.4 `gas.air` — Ambient Atmospheric Gas
* **Description:** Standard terrestrial gas mixture ($78\% N_2, 21\% O_2, 1\% Ar$); baseline fluidic drag medium for projectiles and convective diffusion.
* **Archetypal Provenance:** Universal Atmosphere/Aero Mechanics

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `1.225 kg/m^3` (Standard atmosphere)
- Mohs Hardness: `0.0`
- Young's Modulus ($E$): `0.0001 GPa` | Poisson's Ratio ($\nu$): `0.5`
- Coulomb Friction ($\mu$): `0.0` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `100000.0 J`
- Thermal Conductivity ($k$): `0.026 W/(m·K)` | Specific Heat ($c_p$): `1005.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `none`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `dielectric_refractive_volume` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[1.0, 1.0, 1.0]`
- Microfacet Roughness ($\alpha$): `0.0` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.000293` | Transmittance ($\tau$): `1.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `pure_dielectric`

---

### 2.5 `gas.smoke` — Particulate Combustion Aerosol
* **Description:** Colloidal suspension of airborne solid soot carbon particles and liquid droplets obscuring optical transmission.
* **Archetypal Provenance:** Universal Fire Dynamics/Radiative Obscuration

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `0.95 kg/m^3` (Thermal buoyant plume)
- Mohs Hardness: `0.0`
- Young's Modulus ($E$): `0.0001 GPa` | Poisson's Ratio ($\nu$): `0.5`
- Coulomb Friction ($\mu$): `0.0` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `100000.0 J`
- Thermal Conductivity ($k$): `0.028 W/(m·K)` | Specific Heat ($c_p$): `1050.0 J/(kg·K)`
- Kinematic Gravity: `False` (Convective ascent) | Flammable: `False`
- Optimal Harvest Tool: `none`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.18, 0.18, 0.18]`
- Microfacet Roughness ($\alpha$): `0.95` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.0003` | Transmittance ($\tau$): `0.2`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `pure_participating_volume`

---

### 2.6 `gas.methane` — Volatile Methane / Natural Gas
* **Description:** Light, colorless, flammable gaseous hydrocarbon ($CH_4$) forming explosive combustible mixtures with oxygen.
* **Archetypal Provenance:** Universal Gas/Hazardous Energetics

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `0.668 kg/m^3` (Highly buoyant)
- Mohs Hardness: `0.0`
- Young's Modulus ($E$): `0.0001 GPa` | Poisson's Ratio ($\nu$): `0.5`
- Coulomb Friction ($\mu$): `0.0` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `100000.0 J`
- Thermal Conductivity ($k$): `0.034 W/(m·K)` | Specific Heat ($c_p$): `2220.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `True`
- Optimal Harvest Tool: `none`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `dielectric_refractive_volume` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[0.98, 0.98, 1.0]`
- Microfacet Roughness ($\alpha$): `0.0` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.00044` | Transmittance ($\tau$): `1.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `pure_dielectric`

---

## 3. Semantic Transition Calculus (STC) Reactions

### `reaction.fluid_density_stratification`
* **Category:** `fluid_stratification`
* **Operator:** $\tau_{\text{stratify}}: \text{fluid.oil} + \text{fluid.water} \xrightarrow{\mathbf{g}} \text{fluid.oil}_{z+1} + \text{fluid.water}_{z}$
* **Preconditions:** Co-occupancy in adjacent vertical column voxels under gravitational vector $\mathbf{g}$.
* **Outcome:** Immiscible layer separation; oil floats stably over water without mutual dissolution.
* **Invariants:** Fluid volume conservation.

### `reaction.hydrocarbon_combustion`
* **Category:** `chemical_oxidation`
* **Operator:** $\tau_{\text{burn\_oil}}: \text{fluid.oil} + 2\,\text{gas.oxygen} \xrightarrow{\text{ignition}} \text{thermal.energy} + \text{gas.smoke} + \text{gas.co2}$
* **Preconditions:** Thermal ignition threshold $E_{\text{ign}} > 200\text{ J}$.
* **Outcome:** High radiative emission $L_e \approx 40000\text{ cd/m}^2$, intense smoke emission.
* **Invariants:** Energy and atomic mass conservation.

### `reaction.steam_condensation`
* **Category:** `thermal_phase_change`
* **Operator:** $\tau_{\text{condense}}: \text{gas.steam} \xrightarrow{T \le 373.15\text{ K}} \text{fluid.water}$
* **Preconditions:** Enthalpy dissipation to adjacent cold boundary voxels.
* **Outcome:** Phase transition back to liquid `fluid.water`.
* **Invariants:** Mass conservation ($\rho_w V_w = \rho_s V_s$).
