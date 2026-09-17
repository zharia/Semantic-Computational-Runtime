---
sprint: sprint_07_composites_synthetics_energetics
document_type: normative_sprint_specification
milestone: 001_MaterialLibraryExpansion
schema_version: 1.0.0
id: SCR-PI-002-M001-S07
name: Structural Composites, Synthetics & Detonation Energetics
status: ready
created: 2026-09-16
authority: SCR
---

# Sprint 07: Composites, Structural Synthetics & Detonation Energetics

**Path:** `program_increments/v0.0.2/milestones/001_MaterialLibraryExpansion/sprints/sprint_07_composites_synthetics_energetics/spec.md`  
**Parent Milestone:** [001_MaterialLibraryExpansion](../../README.md)  
**Parent Specification:** [spec.md](../../spec.md)  

---

## 1. Sprint Objective

Expand the synthetic solids and masonry domain with dry concrete precursors, mortar binders, ultra-insulating aerogels, engineering plastics, semiconductor silicon, and high-energy chemical explosives. Formalize rapid exothermic detonation shockwaves and Chapman-Jouguet blast kinematics.

---

## 2. Normative Material Catalog Additions

### 2.1 `granular.concrete_powder` — Dry Concrete Precursor Powder
* **Description:** Granular aggregate of pulverized Portland cement clinker and graded silica sand; subject to kinematic gravity until hydraulic hydration.
* **Archetypal Provenance:** Minecraft (Concrete Powder), Universal Construction Masonry

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `1600.0 kg/m^3`
- Mohs Hardness: `1.5`
- Young's Modulus ($E$): `0.08 GPa` | Poisson's Ratio ($\nu$): `0.3`
- Coulomb Friction ($\mu$): `0.55` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `400.0 J`
- Thermal Conductivity ($k$): `0.3 W/(m·K)` | Specific Heat ($c_p$): `850.0 J/(kg·K)`
- Kinematic Gravity: `True` (Falling block) | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.62, 0.62, 0.62]`
- Microfacet Roughness ($\alpha$): `0.95` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.53` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.2 `synthetic.mortar` — Hydraulic Masonry Mortar
* **Description:** Workable cementitious binder paste used to bind building stones, bricks, and concrete masonry units together.
* **Archetypal Provenance:** Universal Masonry/Civil Engineering

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `2000.0 kg/m^3`
- Mohs Hardness: `4.5`
- Young's Modulus ($E$): `18.0 GPa` | Poisson's Ratio ($\nu$): `0.22`
- Coulomb Friction ($\mu$): `0.7` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `5000.0 J`
- Thermal Conductivity ($k$): `1.1 W/(m·K)` | Specific Heat ($c_p$): `840.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.72, 0.70, 0.66]`
- Microfacet Roughness ($\alpha$): `0.85` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.53` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.3 `synthetic.aerogel` — Silica Aerogel / Solid Smoke
* **Description:** Ultra-low-density mesoporous synthetic solid derived from gel extraction; lowest thermal conductivity and high Rayleigh scattering translucency.
* **Archetypal Provenance:** Universal Extreme Thermal Insulation/CAD

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `100.0 kg/m^3` (Ultralight solid)
- Mohs Hardness: `1.0`
- Young's Modulus ($E$): `0.01 GPa` | Poisson's Ratio ($\nu$): `0.2`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `300.0 J` (Brittle under shear)
- Thermal Conductivity ($k$): `0.015 W/(m·K)` (Extreme thermal insulator) | Specific Heat ($c_p$): `1000.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `shears`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `subsurface_scattering_dielectric` (Closure: `BSDF_BSSRDF_DIPOLE`)
- Base Albedo (Linear sRGB): `[0.75, 0.88, 0.98]` (Opalescent Rayleigh blue)
- Microfacet Roughness ($\alpha$): `0.05` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.02` | Transmittance ($\tau$): `0.85`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `subsurface_dielectric`

---

### 2.4 `synthetic.plastic` — Thermoplastic Polymer / Polycarbonate
* **Description:** Synthetic organic polymer capable of plastic flow when heated and rigid impact durability when cooled.
* **Archetypal Provenance:** Universal Modern Manufacturing/CAD

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `1200.0 kg/m^3`
- Mohs Hardness: `3.0`
- Young's Modulus ($E$): `3.0 GPa` | Poisson's Ratio ($\nu$): `0.38`
- Coulomb Friction ($\mu$): `0.35` | Restitution ($e$): `0.4`
- Blast Fracture Threshold: `3000.0 J`
- Thermal Conductivity ($k$): `0.2 W/(m·K)` | Specific Heat ($c_p$): `1300.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `420.0 K`
- Kinematic Gravity: `False` | Flammable: `True`
- Optimal Harvest Tool: `axe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `dielectric_specular_coated_diffuse` (Closure: `BSDF_COATED_DIFFUSE`)
- Base Albedo (Linear sRGB): `[0.85, 0.85, 0.85]`
- Microfacet Roughness ($\alpha$): `0.15` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.58` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `coated_diffuse`

---

### 2.5 `synthetic.silicon` — Elemental Silicon / Polycrystalline Wafer
* **Description:** Tetravalent metalloid semiconductor forming foundational substrates for integrated microelectronics and photovoltaic cells.
* **Archetypal Provenance:** Universal Electronics/Semiconductors

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `2330.0 kg/m^3`
- Mohs Hardness: `6.5`
- Young's Modulus ($E$): `130.0 GPa` | Poisson's Ratio ($\nu$): `0.28`
- Coulomb Friction ($\mu$): `0.3` | Restitution ($e$): `0.55`
- Blast Fracture Threshold: `6000.0 J`
- Thermal Conductivity ($k$): `149.0 W/(m·K)` | Specific Heat ($c_p$): `700.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `1687.0 K`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.55, 0.62, 0.68]`
- Microfacet Roughness ($\alpha$): `0.08` | Metallic Fraction ($m$): `0.85`
- Index of Refraction ($n$): `3.88` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---

### 2.6 `synthetic.explosive` — Chemical High Explosive (TNT / Energetic Solid)
* **Description:** Stable chemical solid containing coordinated nitro-groups; undergoes rapid deflagration-to-detonation transition producing supersonic shockwave impulse.
* **Archetypal Provenance:** Minecraft (TNT), Terraria (Explosives), Universal Demolition Physics

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `1650.0 kg/m^3`
- Mohs Hardness: `1.5`
- Young's Modulus ($E$): `8.0 GPa` | Poisson's Ratio ($\nu$): `0.3`
- Coulomb Friction ($\mu$): `0.5` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `50.0 J` (Highly sensitive to blast cascade)
- Thermal Conductivity ($k$): `0.22 W/(m·K)` | Specific Heat ($c_p$): `1400.0 J/(kg·K)`
- Detonation Velocity ($D_{\text{det}}$): `6900.0 m/s` | Explosive Energy ($Q_{\text{exp}}$): `4.184 MJ/kg`
- Kinematic Gravity: `False` | Flammable: `True`
- Optimal Harvest Tool: `shears`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.78, 0.22, 0.15]`
- Microfacet Roughness ($\alpha$): `0.8` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.55` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

## 3. Semantic Transition Calculus (STC) Reactions

### `reaction.detonation_shockwave`
* **Category:** `explosive_detonation`
* **Operator:** $\tau_{\text{detonate}}: \text{synthetic.explosive} \xrightarrow{\text{trigger}} \mathcal{W}_{\text{shock}}(\Delta P, r) + \text{gas.smoke}$
* **Preconditions:** Thermal ignition energy $> 100\text{ J}$ or mechanical detonation shock.
* **Outcome:** Spherical impulse wave $\Delta P(r) = \frac{E_{\text{blast}}}{4\pi r^2}$; all voxels with $J_{\text{blast}} < \Delta P(r)$ undergo instantaneous fracture cavity removal.
* **Invariants:** Total energy conservation ($E_{\text{blast}} = m_{\text{TNT}} \cdot Q_{\text{exp}}$).

### `reaction.concrete_powder_hydration`
* **Category:** `hydration_reaction`
* **Operator:** $\tau_{\text{concrete}}: \text{granular.concrete\_powder} + \text{fluid.water} \to \text{synthetic.concrete}$
* **Preconditions:** Face contact $\mathcal{N}_6$ with liquid water.
* **Outcome:** Phase transformation into solid `synthetic.concrete`, extinguishing falling block kinematics.
* **Invariants:** Mineral mass conservation.
