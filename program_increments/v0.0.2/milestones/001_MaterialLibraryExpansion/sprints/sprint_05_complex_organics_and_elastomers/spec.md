---
sprint: sprint_05_complex_organics_and_elastomers
document_type: normative_sprint_specification
milestone: 001_MaterialLibraryExpansion
schema_version: 1.0.0
id: SCR-PI-002-M001-S05
name: Complex Organics, Elastomers & Biomaterials
status: ready
created: 2026-09-16
authority: SCR
---

# Sprint 05: Complex Organics, Elastomers & Biomaterials

**Path:** `program_increments/v0.0.2/milestones/001_MaterialLibraryExpansion/sprints/sprint_05_complex_organics_and_elastomers/spec.md`  
**Parent Milestone:** [001_MaterialLibraryExpansion](../../README.md)  
**Parent Specification:** [spec.md](../../spec.md)  

---

## 1. Sprint Objective

Expand the biological, organic, and polymer taxons with natural elastomers, structural animal proteins, hydrophobic waxes, pyrolyzed carbons, and vegetative ground covers. Formalize hyperelastic deformation, viscoelastic collision response, biological decomposition, and hydrophobic barrier behavior.

---

## 2. Normative Material Catalog Additions

### 2.1 `organic.leather` — Tanned Leather / Animal Dermis
* **Description:** Cross-linked fibrous collagen matrix yielding flexibility, high tear resistance, and wind/water barrier properties.
* **Archetypal Provenance:** Minecraft (Leather), Terraria (Leather), Universal Biopolymers

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `850.0 kg/m^3`
- Mohs Hardness: `1.5`
- Young's Modulus ($E$): `0.05 GPa` | Poisson's Ratio ($\nu$): `0.4`
- Coulomb Friction ($\mu$): `0.55` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `1200.0 J`
- Thermal Conductivity ($k$): `0.15 W/(m·K)` | Specific Heat ($c_p$): `1500.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `True`
- Optimal Harvest Tool: `shears`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.42, 0.26, 0.16]`
- Microfacet Roughness ($\alpha$): `0.6` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.50` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.2 `organic.chitin` — Chitin / Arthropod Exoskeleton
* **Description:** Long-chain polymer of N-acetylglucosamine forming rigid, tough, lightweight protective armor in invertebrates.
* **Archetypal Provenance:** Universal Biopolymer Architecture

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `1400.0 kg/m^3`
- Mohs Hardness: `3.5`
- Young's Modulus ($E$): `15.0 GPa` | Poisson's Ratio ($\nu$): `0.3`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.45`
- Blast Fracture Threshold: `3500.0 J`
- Thermal Conductivity ($k$): `0.25 W/(m·K)` | Specific Heat ($c_p$): `1200.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `True`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `dielectric_specular_coated_diffuse` (Closure: `BSDF_COATED_DIFFUSE`)
- Base Albedo (Linear sRGB): `[0.28, 0.22, 0.18]`
- Microfacet Roughness ($\alpha$): `0.35` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.56` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `glossy_dielectric`

---

### 2.3 `organic.rubber` — Natural Rubber / Polyisoprene Elastomer
* **Description:** Hyperelastic hydrocarbon polymer exhibiting extreme reversible strain elongation, high restitution, and nearly incompressible Poisson ratio ($\nu \approx 0.49$).
* **Archetypal Provenance:** Minecraft (Slime/Bounce analogue), Universal Polymer Mechanics

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `950.0 kg/m^3`
- Mohs Hardness: `1.0`
- Young's Modulus ($E$): `0.005 GPa` | Poisson's Ratio ($\nu$): `0.49` (Nearly incompressible)
- Coulomb Friction ($\mu$): `0.9` (High traction) | Restitution ($e$): `0.85` (Extreme bounce)
- Blast Fracture Threshold: `2500.0 J`
- Thermal Conductivity ($k$): `0.13 W/(m·K)` | Specific Heat ($c_p$): `1900.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `True`
- Optimal Harvest Tool: `shears`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.15, 0.15, 0.15]`
- Microfacet Roughness ($\alpha$): `0.8` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.52` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.4 `organic.wax` — Hydrocarbon Wax / Beeswax & Tallow
* **Description:** Lipid ester mixture solid at room temperature with low melting point ($335\text{ K}$), used as hydrophobic coating and sealant.
* **Archetypal Provenance:** Minecraft (Honeycomb/Wax), Universal Chemical Sealing

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `960.0 kg/m^3`
- Mohs Hardness: `0.5`
- Young's Modulus ($E$): `0.02 GPa` | Poisson's Ratio ($\nu$): `0.42`
- Coulomb Friction ($\mu$): `0.2` (Slick low friction) | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `300.0 J`
- Thermal Conductivity ($k$): `0.25 W/(m·K)` | Specific Heat ($c_p$): `2400.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `335.0 K`
- Kinematic Gravity: `False` | Flammable: `True`
- Optimal Harvest Tool: `shears`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `subsurface_scattering_dielectric` (Closure: `BSDF_BSSRDF_DIPOLE`)
- Base Albedo (Linear sRGB): `[0.92, 0.82, 0.55]`
- Microfacet Roughness ($\alpha$): `0.3` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.44` | Transmittance ($\tau$): `0.3`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `subsurface_dielectric`

---

### 2.5 `wood.charcoal` — Pyrolyzed Biomass Carbon / Charcoal
* **Description:** Porous black carbon residue derived from thermal pyrolysis of hardwood in low-oxygen conditions; clean-burning high-energy fuel.
* **Archetypal Provenance:** Minecraft (Charcoal), Universal Metallurgy/Fuel

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `450.0 kg/m^3` (Lightweight porous carbon)
- Mohs Hardness: `2.0`
- Young's Modulus ($E$): `2.5 GPa` | Poisson's Ratio ($\nu$): `0.2`
- Coulomb Friction ($\mu$): `0.6` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `1000.0 J`
- Thermal Conductivity ($k$): `0.08 W/(m·K)` | Specific Heat ($c_p$): `1000.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `True`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.05, 0.05, 0.05]`
- Microfacet Roughness ($\alpha$): `0.95` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.75` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.6 `botanical.moss` — Bryophyte Ground Mat / Moss
* **Description:** Dense non-vascular photosynthetic plant carpet exhibiting high capillary moisture absorption and spongy impact damping.
* **Archetypal Provenance:** Minecraft (Moss Block), Terraria (Moss), Universal Botany/Ecology

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `400.0 kg/m^3`
- Mohs Hardness: `0.5`
- Young's Modulus ($E$): `0.005 GPa` | Poisson's Ratio ($\nu$): `0.35`
- Coulomb Friction ($\mu$): `0.75` | Restitution ($e$): `0.02`
- Blast Fracture Threshold: `300.0 J`
- Thermal Conductivity ($k$): `0.1 W/(m·K)` | Specific Heat ($c_p$): `2200.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `True`
- Optimal Harvest Tool: `shears`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.28, 0.48, 0.18]`
- Microfacet Roughness ($\alpha$): `0.92` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.45` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.7 `botanical.mycelium` — Fungal Hyphal Matrix / Mycelium
* **Description:** Vegetative fungal colony composed of branched tubular hyphae capable of decomposing organic detritus and soil conversion.
* **Archetypal Provenance:** Minecraft (Mycelium), Terraria (Glowing Mushroom), Universal Mycology

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `1250.0 kg/m^3`
- Mohs Hardness: `1.0`
- Young's Modulus ($E$): `0.02 GPa` | Poisson's Ratio ($\nu$): `0.38`
- Coulomb Friction ($\mu$): `0.65` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `450.0 J`
- Thermal Conductivity ($k$): `0.25 W/(m·K)` | Specific Heat ($c_p$): `1600.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.45, 0.38, 0.42]`
- Microfacet Roughness ($\alpha$): `0.88` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.48` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `200.0 cd/m^2` (Subtle bioluminescence)
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.8 `botanical.cactus` — Xerophyte Cactus Stem
* **Description:** Succulent plant stem with thickened fleshy parenchyma storing water, enclosed in tough waxy cuticle with rigid spines.
* **Archetypal Provenance:** Minecraft (Cactus), Terraria (Cactus), Universal Arid Botany

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `850.0 kg/m^3`
- Mohs Hardness: `2.0`
- Young's Modulus ($E$): `0.1 GPa` | Poisson's Ratio ($\nu$): `0.35`
- Coulomb Friction ($\mu$): `0.6` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `500.0 J`
- Thermal Conductivity ($k$): `0.35 W/(m·K)` | Specific Heat ($c_p$): `3500.0 J/(kg·K)` (High water mass)
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `axe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `dielectric_specular_coated_diffuse` (Closure: `BSDF_COATED_DIFFUSE`)
- Base Albedo (Linear sRGB): `[0.22, 0.52, 0.18]`
- Microfacet Roughness ($\alpha$): `0.45` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.50` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `coated_diffuse`

---

## 3. Semantic Transition Calculus (STC) Reactions

### `reaction.biomass_slow_pyrolysis`
* **Category:** `chemical_pyrolysis`
* **Operator:** $\tau_{\text{charcoal}}: \text{wood.hardwood} \xrightarrow{T \ge 673.0\text{ K},\; O_2 \to 0} \text{wood.charcoal} + \text{gas.smoke}$
* **Preconditions:** Anoxic thermal heating above $673\text{ K}$.
* **Outcome:** Carbonization into porous `wood.charcoal` with syngas/smoke volatilization.
* **Invariants:** Total elemental carbon and energy conservation.

### `reaction.mycelial_decomposition`
* **Category:** `biological_conversion`
* **Operator:** $\tau_{\text{mycelial\_spread}}: \text{botanical.mycelium} \times \text{soil.dirt} \xrightarrow{\Delta t} 2\,\text{botanical.mycelium}$
* **Preconditions:** Moisture contact and adjacency $\mathcal{N}_6$.
* **Outcome:** Biological colonized conversion of adjacent loam soil.
* **Invariants:** Mineral substrate conservation.
