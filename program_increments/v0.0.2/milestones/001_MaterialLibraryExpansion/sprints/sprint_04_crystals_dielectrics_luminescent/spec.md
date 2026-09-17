---
sprint: sprint_04_crystals_dielectrics_luminescent
document_type: normative_sprint_specification
milestone: 001_MaterialLibraryExpansion
schema_version: 1.0.0
id: SCR-PI-002-M001-S04
name: Luminescent, Dielectric & Piezoelectric Crystals
status: ready
created: 2026-09-16
authority: SCR
---

# Sprint 04: Luminescent, Dielectric & Piezoelectric Crystals

**Path:** `program_increments/v0.0.2/milestones/001_MaterialLibraryExpansion/sprints/sprint_04_crystals_dielectrics_luminescent/spec.md`  
**Parent Milestone:** [001_MaterialLibraryExpansion](../../README.md)  
**Parent Specification:** [spec.md](../../spec.md)  

---

## 1. Sprint Objective

Expand the crystal and gemstone taxonomy to include non-linear electro-optical crystals, luminescent radiative emitters, high-toughness silicates, and natural dielectric resins. Establish coupling between mechanical stress, electrostatic charge, and emitted radiance.

---

## 2. Normative Material Catalog Additions

### 2.1 `gem.lapis_lazuli` — Lazurite / Ultramarine Silicate
* **Description:** Deep-blue feldspathoid sodium calcium aluminosilicate containing sulfur ions producing historic ultramarine pigmentation.
* **Archetypal Provenance:** Minecraft (Lapis Lazuli), Universal Historic Pigment/Mineralogy

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `2800.0 kg/m^3`
- Mohs Hardness: `5.5`
- Young's Modulus ($E$): `55.0 GPa` | Poisson's Ratio ($\nu$): `0.25`
- Coulomb Friction ($\mu$): `0.6` | Restitution ($e$): `0.25`
- Blast Fracture Threshold: `4500.0 J`
- Thermal Conductivity ($k$): `2.1 W/(m·K)` | Specific Heat ($c_p$): `800.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `stone_pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.08, 0.16, 0.58]` (Rich ultramarine)
- Microfacet Roughness ($\alpha$): `0.65` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.50` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.2 `gem.topaz` — Topaz / Aluminum Fluorosilicate
* **Description:** Nesosilicate mineral of aluminum and fluorine ($Al_2SiO_4(F,OH)_2$); Mohs standard 8.0 with high optical dispersion.
* **Archetypal Provenance:** Terraria (Topaz), Universal Gemology/Optics

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `3530.0 kg/m^3`
- Mohs Hardness: `8.0`
- Young's Modulus ($E$): `260.0 GPa` | Poisson's Ratio ($\nu$): `0.24`
- Coulomb Friction ($\mu$): `0.25` | Restitution ($e$): `0.65`
- Blast Fracture Threshold: `8000.0 J`
- Thermal Conductivity ($k$): `12.0 W/(m·K)` | Specific Heat ($c_p$): `780.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_DISPERSIVE`)
- Base Albedo (Linear sRGB): `[0.98, 0.82, 0.28]` (Golden amber hue)
- Microfacet Roughness ($\alpha$): `0.03` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.62` | Transmittance ($\tau$): `0.9`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `colored_refractive`

---

### 2.3 `gem.jade` — Jade / Nephrite & Jadeite Aggregate
* **Description:** Interlocking microcrystalline pyroxene/amphibole mineral fibers offering unprecedented impact resistance and fracture toughness.
* **Archetypal Provenance:** Universal Tough Mineral/Statuary

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `3300.0 kg/m^3`
- Mohs Hardness: `6.5`
- Young's Modulus ($E$): `160.0 GPa` | Poisson's Ratio ($\nu$): `0.26`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.5`
- Blast Fracture Threshold: `11000.0 J` (Extreme fracture toughness)
- Thermal Conductivity ($k$): `3.5 W/(m·K)` | Specific Heat ($c_p$): `820.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `subsurface_scattering_dielectric` (Closure: `BSDF_BSSRDF_DIPOLE`)
- Base Albedo (Linear sRGB): `[0.22, 0.65, 0.42]`
- Microfacet Roughness ($\alpha$): `0.2` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.66` | Transmittance ($\tau$): `0.2`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `subsurface_dielectric`

---

### 2.4 `gem.amber` — Amber / Fossilized Tree Resin
* **Description:** Amorphous biogenic macromolecular polymer formed from fossilized plant resin; natural electrostatic charging medium.
* **Archetypal Provenance:** Terraria (Amber), Universal Paleontology/Dielectrics

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `1080.0 kg/m^3` (Lightweight solid)
- Mohs Hardness: `2.2`
- Young's Modulus ($E$): `3.5 GPa` | Poisson's Ratio ($\nu$): `0.38`
- Coulomb Friction ($\mu$): `0.45` | Restitution ($e$): `0.3`
- Blast Fracture Threshold: `800.0 J`
- Thermal Conductivity ($k$): `0.18 W/(m·K)` | Specific Heat ($c_p$): `1300.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `573.0 K`
- Kinematic Gravity: `False` | Flammable: `True`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[0.96, 0.62, 0.12]`
- Microfacet Roughness ($\alpha$): `0.08` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.54` | Transmittance ($\tau$): `0.85`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `colored_refractive`

---

### 2.5 `mineral.phosphor` — Phosphorescent / Luminescent Crystal
* **Description:** Doped alkaline-earth aluminate or zinc sulfide crystal capable of storing photon energy and emitting sustained visible radiance.
* **Archetypal Provenance:** Minecraft (Glowstone/Shroomlight), Universal Solid-State Radiance

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `2600.0 kg/m^3`
- Mohs Hardness: `4.5`
- Young's Modulus ($E$): `35.0 GPa` | Poisson's Ratio ($\nu$): `0.24`
- Coulomb Friction ($\mu$): `0.5` | Restitution ($e$): `0.3`
- Blast Fracture Threshold: `3000.0 J`
- Thermal Conductivity ($k$): `1.2 W/(m·K)` | Specific Heat ($c_p$): `750.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `emissive_blackbody_fluid` (Closure: `BSDF_PLUS_EDF_EMISSIVE`)
- Base Albedo (Linear sRGB): `[0.95, 0.90, 0.45]`
- Microfacet Roughness ($\alpha$): `0.3` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.65` | Transmittance ($\tau$): `0.3`
- Radiative Emission ($L_e$): `12000.0 cd/m^2` (Active light source)
- Hypergraph Layering Topology: `diffuse_plus_blackbody_edf`

---

## 3. Semantic Transition Calculus (STC) Reactions

### `reaction.piezoelectric_excitation`
* **Category:** `electromechanical_coupling`
* **Operator:** $\tau_{\text{piezo}}: \text{gem.quartz} \times \sigma_{\text{mech}} \to \Delta V_{\text{elec}}$
* **Preconditions:** Dynamic mechanical compression impulse $> 500\text{ kPa}$.
* **Outcome:** Transient local voltage generation across boundary vertices.
* **Invariants:** Mechanical-to-electrical energy conservation.

### `reaction.phosphorescent_decay`
* **Category:** `optical_radiative_transfer`
* **Operator:** $\tau_{\text{decay}}: \text{mineral.phosphor} \xrightarrow{\Delta t} L_e(t) = L_{e,0} \cdot e^{-t/\tau_{\text{rad}}}$
* **Preconditions:** Absence of incident optical excitation source.
* **Outcome:** Gradual decay of emitted surface radiance.
* **Invariants:** Radiative energy conservation.
