---
sprint: sprint_01_cryogenic_and_volatile_phases
document_type: normative_sprint_specification
milestone: 001_MaterialLibraryExpansion
schema_version: 1.0.0
id: SCR-PI-002-M001-S01
name: Cryogenic & Volatile Media
status: ready
created: 2026-09-16
authority: SCR
---

# Sprint 01: Cryogenic & Volatile Phases

**Path:** `program_increments/v0.0.2/milestones/001_MaterialLibraryExpansion/sprints/sprint_01_cryogenic_and_volatile_phases/spec.md`  
**Parent Milestone:** [001_MaterialLibraryExpansion](../../README.md)  
**Parent Specification:** [spec.md](../../spec.md)  

---

## 1. Sprint Objective

Incorporate low-temperature aqueous solid states, glaciological dynamics, and thermal phase transitions into the universal materials catalog. These materials provide foundational mechanics for environmental temperature coupling, slippery friction dynamics, and granular snow hazards.

---

## 2. Normative Material Catalog Additions

### 2.1 `cryo.ice` — Standard / Glacial Ice
* **Description:** Hexagonal crystalline solid phase of water ($I_h$) with low kinetic friction and brittle fracture under impact.
* **Archetypal Provenance:** Minecraft (Ice), Terraria (Ice Block), Universal Cryology/Glaciology

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `917.0 kg/m^3`
- Mohs Hardness: `1.5`
- Young's Modulus ($E$): `9.3 GPa` | Poisson's Ratio ($\nu$): `0.33`
- Coulomb Friction ($\mu$): `0.05` (Low friction slipperiness) | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `600.0 J`
- Thermal Conductivity ($k$): `2.22 W/(m·K)` | Specific Heat ($c_p$): `2090.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `273.15 K`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `silk_touch_pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[0.85, 0.92, 0.98]`
- Microfacet Roughness ($\alpha$): `0.08` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.31` | Transmittance ($\tau$): `0.92`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `translucent_dielectric`

---

### 2.2 `cryo.packed_ice` — Compacted Glacial Firn / Packed Ice
* **Description:** Sintered and compressed granular ice crystals depleted of air pores, preventing rapid thermal melting.
* **Archetypal Provenance:** Minecraft (Packed Ice), Universal Glaciology

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `900.0 kg/m^3`
- Mohs Hardness: `2.0`
- Young's Modulus ($E$): `8.8 GPa` | Poisson's Ratio ($\nu$): `0.32`
- Coulomb Friction ($\mu$): `0.03` | Restitution ($e$): `0.25`
- Blast Fracture Threshold: `1200.0 J`
- Thermal Conductivity ($k$): `2.1 W/(m·K)` | Specific Heat ($c_p$): `2100.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `273.15 K` (High latent heat requirement)
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `subsurface_scattering_dielectric` (Closure: `BSDF_BSSRDF_DIPOLE`)
- Base Albedo (Linear sRGB): `[0.78, 0.88, 0.96]`
- Microfacet Roughness ($\alpha$): `0.15` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.315` | Transmittance ($\tau$): `0.45`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `subsurface_dielectric`

---

### 2.3 `cryo.blue_ice` — High-Density Blue Glacial Ice
* **Description:** Extremely compressed basal glacial ice with structural bubble exclusion, maximum light wavelength absorption in red, and minimal surface friction.
* **Archetypal Provenance:** Minecraft (Blue Ice), CAD Cryology

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `917.0 kg/m^3`
- Mohs Hardness: `2.5`
- Young's Modulus ($E$): `9.5 GPa` | Poisson's Ratio ($\nu$): `0.31`
- Coulomb Friction ($\mu$): `0.01` (Super-slippery transport medium) | Restitution ($e$): `0.3`
- Blast Fracture Threshold: `1800.0 J`
- Thermal Conductivity ($k$): `2.3 W/(m·K)` | Specific Heat ($c_p$): `2050.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `273.15 K`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `subsurface_scattering_dielectric` (Closure: `BSDF_BSSRDF_DIPOLE`)
- Base Albedo (Linear sRGB): `[0.55, 0.75, 0.98]`
- Microfacet Roughness ($\alpha$): `0.05` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.32` | Transmittance ($\tau$): `0.6`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `subsurface_dielectric`

---

### 2.4 `cryo.snow` — Consolidated Snow Pack
* **Description:** Sintered ice crystal matrix with high porosity, high solar albedo, and insulating thermal resistance.
* **Archetypal Provenance:** Minecraft (Snow Block), Terraria (Snow Block), Universal Meteorology

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `350.0 kg/m^3`
- Mohs Hardness: `0.5`
- Young's Modulus ($E$): `0.05 GPa` | Poisson's Ratio ($\nu$): `0.25`
- Coulomb Friction ($\mu$): `0.2` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `250.0 J`
- Thermal Conductivity ($k$): `0.15 W/(m·K)` (High thermal insulation) | Specific Heat ($c_p$): `2090.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `273.15 K`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.98, 0.98, 0.98]` (Extreme albedo)
- Microfacet Roughness ($\alpha$): `0.95` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.30` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.5 `cryo.powder_snow` — Unconsolidated Powder Snow
* **Description:** Loose, high-porosity dendritic snow crystals unable to support mechanical loads, producing sinking and hypothermic thermal damping.
* **Archetypal Provenance:** Minecraft (Powder Snow), Universal Avalanche Mechanics

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `100.0 kg/m^3`
- Mohs Hardness: `0.1`
- Young's Modulus ($E$): `0.001 GPa` | Poisson's Ratio ($\nu$): `0.1`
- Coulomb Friction ($\mu$): `0.85` (Entanglement drag) | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `50.0 J`
- Thermal Conductivity ($k$): `0.06 W/(m·K)` | Specific Heat ($c_p$): `2090.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `273.15 K`
- Kinematic Gravity: `True` | Flammable: `False`
- Optimal Harvest Tool: `bucket`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.99, 0.99, 1.0]`
- Microfacet Roughness ($\alpha$): `0.98` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.25` | Transmittance ($\tau$): `0.1`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.6 `cryo.permafrost` — Frozen Lithic Cryosol / Permafrost
* **Description:** Soil, gravel, or fractured rock permanently cemented by ground ice at temperatures below 273.15 K.
* **Archetypal Provenance:** CAD Geotechnical/Cryopedology

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `1950.0 kg/m^3`
- Mohs Hardness: `4.5`
- Young's Modulus ($E$): `25.0 GPa` | Poisson's Ratio ($\nu$): `0.28`
- Coulomb Friction ($\mu$): `0.5` | Restitution ($e$): `0.15`
- Blast Fracture Threshold: `4500.0 J`
- Thermal Conductivity ($k$): `2.5 W/(m·K)` | Specific Heat ($c_p$): `1200.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `273.15 K`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.45, 0.42, 0.40]`
- Microfacet Roughness ($\alpha$): `0.85` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.48` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

## 3. Semantic Transition Calculus (STC) Reactions

### `reaction.water_freezing`
* **Category:** `thermal_phase_change`
* **Operator:** $\tau_{\text{freeze}}: \text{fluid.water} \xrightarrow{T \le 273.15\text{ K}} \text{cryo.ice}$
* **Preconditions:** `temperature <= 273.15 K`, latent heat of fusion $\Delta H_f = 334.0\text{ kJ/kg}$ dissipated.
* **Outcome:** `cryo.ice`
* **Invariants:** Mass conservation ($\rho_{\text{ice}} V_{\text{ice}} = \rho_{\text{water}} V_{\text{water}}$ yielding volumetric expansion factor $1.09$).

### `reaction.ice_melting`
* **Category:** `thermal_phase_change`
* **Operator:** $\tau_{\text{melt}}: \text{cryo.ice} \xrightarrow{T > 273.15\text{ K}} \text{fluid.water}$
* **Preconditions:** `temperature > 273.15 K`, heat influx absorbed.
* **Outcome:** `fluid.water`
* **Invariants:** Mass conservation.

### `reaction.snow_compaction`
* **Category:** `mechanical_compaction`
* **Operator:** $\tau_{\text{compact}}: \text{cryo.snow} \xrightarrow{P_{\text{overburden}} > 10.0\text{ kPa}} \text{cryo.packed_ice}$
* **Preconditions:** Cumulative vertical load over time.
* **Outcome:** `cryo.packed_ice`
* **Invariants:** Mass conservation via pore space collapse.

### `reaction.ice_salt_depression`
* **Category:** `chemical_colligative`
* **Operator:** $\tau_{\text{salt\_depress}}: \text{cryo.ice} + \text{mineral.salt} \xrightarrow{T \ge 252.0\text{ K}} \text{fluid.brine}$
* **Preconditions:** `cryo.ice` adjacent to `mineral.salt` across $\mathcal{N}_6$.
* **Outcome:** `fluid.water` (with dissolved solute state).
* **Invariants:** Total mass conservation.
