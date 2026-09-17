---
sprint: sprint_02_sediments_minerals_carbonates
document_type: normative_sprint_specification
milestone: 001_MaterialLibraryExpansion
schema_version: 1.0.0
id: SCR-PI-002-M001-S02
name: Earth Sediments, Porous Minerals, Carbonates & Solutes
status: ready
created: 2026-09-16
authority: SCR
---

# Sprint 02: Earth Sediments, Carbonates & Soluble Minerals

**Path:** `program_increments/v0.0.2/milestones/001_MaterialLibraryExpansion/sprints/sprint_02_sediments_minerals_carbonates/spec.md`  
**Parent Milestone:** [001_MaterialLibraryExpansion](../../README.md)  
**Parent Specification:** [spec.md](../../spec.md)  

---

## 1. Sprint Objective

Expand the geological and mineral branch with carbonate formations, volcanic vesicular stones, soluble ionic crystals, reactive non-metals, and organic soils. These materials govern chemical dissolution, mineral hydration, buoyancy phenomena, and binder synthesis.

---

## 2. Normative Material Catalog Additions

### 2.1 `rock.limestone` — Limestone / Carbonate Rock
* **Description:** Sedimentary carbonate rock composed largely of calcite and aragonite; primary precursor to quicklime and cement.
* **Archetypal Provenance:** Universal Civil/Geological Engineering

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `2550.0 kg/m^3`
- Mohs Hardness: `3.0`
- Young's Modulus ($E$): `45.0 GPa` | Poisson's Ratio ($\nu$): `0.28`
- Coulomb Friction ($\mu$): `0.65` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `4500.0 J`
- Thermal Conductivity ($k$): `2.0 W/(m·K)` | Specific Heat ($c_p$): `880.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.78, 0.74, 0.68]`
- Microfacet Roughness ($\alpha$): `0.82` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.57` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.2 `rock.calcite` — Calcite Crystalline Carbonate
* **Description:** Trigonal polymorph of calcium carbonate exhibiting strong optical birefringence and rhombohedral cleavage.
* **Archetypal Provenance:** Minecraft (Calcite), Universal Optical Crystallography

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `2710.0 kg/m^3`
- Mohs Hardness: `3.0`
- Young's Modulus ($E$): `60.0 GPa` | Poisson's Ratio ($\nu$): `0.30`
- Coulomb Friction ($\mu$): `0.55` | Restitution ($e$): `0.35`
- Blast Fracture Threshold: `4000.0 J`
- Thermal Conductivity ($k$): `2.2 W/(m·K)` | Specific Heat ($c_p$): `850.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `subsurface_scattering_dielectric` (Closure: `BSDF_BSSRDF_DIPOLE`)
- Base Albedo (Linear sRGB): `[0.92, 0.90, 0.88]`
- Microfacet Roughness ($\alpha$): `0.35` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.658` (Ordinary ray birefringence) | Transmittance ($\tau$): `0.1`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `subsurface_dielectric`

---

### 2.3 `rock.tuff` — Volcanic Tuff
* **Description:** Pyroclastic consolidated volcanic rock formed from consolidated ash, shards, and lithic fragments.
* **Archetypal Provenance:** Minecraft (Tuff), Universal Volcanic Masonry

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `2100.0 kg/m^3`
- Mohs Hardness: `4.5`
- Young's Modulus ($E$): `30.0 GPa` | Poisson's Ratio ($\nu$): `0.25`
- Coulomb Friction ($\mu$): `0.7` | Restitution ($e$): `0.15`
- Blast Fracture Threshold: `5000.0 J`
- Thermal Conductivity ($k$): `1.5 W/(m·K)` | Specific Heat ($c_p$): `840.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.42, 0.40, 0.38]`
- Microfacet Roughness ($\alpha$): `0.9` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.52` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.4 `rock.pumice` — Vesicular Pumice
* **Description:** Highly porous vesicular volcanic glass with closed and open void cavities, resulting in bulk density below water.
* **Archetypal Provenance:** Universal Geophysics/Hydraulic Buoyancy

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `650.0 kg/m^3` (Buoyant on water)
- Mohs Hardness: `5.5`
- Young's Modulus ($E$): `15.0 GPa` | Poisson's Ratio ($\nu$): `0.18`
- Coulomb Friction ($\mu$): `0.85` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `2500.0 J`
- Thermal Conductivity ($k$): `0.35 W/(m·K)` (High vesicular insulation) | Specific Heat ($c_p$): `800.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.70, 0.68, 0.64]`
- Microfacet Roughness ($\alpha$): `0.92` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.50` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.5 `soil.peat` — Peat / Organic Turf
* **Description:** Partially decayed accumulation of vegetable matter and sphagnum moss; natural carbonaceous fossil precursor.
* **Archetypal Provenance:** Universal Fuel/Wetland Geology

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `1100.0 kg/m^3`
- Mohs Hardness: `1.0`
- Young's Modulus ($E$): `0.02 GPa` | Poisson's Ratio ($\nu$): `0.38`
- Coulomb Friction ($\mu$): `0.7` | Restitution ($e$): `0.02`
- Blast Fracture Threshold: `400.0 J`
- Thermal Conductivity ($k$): `0.22 W/(m·K)` | Specific Heat ($c_p$): `1800.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `True` (Low smolder rate)
- Optimal Harvest Tool: `shovel`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.24, 0.16, 0.10]`
- Microfacet Roughness ($\alpha$): `0.95` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.46` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.6 `soil.podzol` — Podzol / Forest Humus Soil
* **Description:** Highly leached boreal soil characterized by a bleached eluvial horizon beneath an organic humus top layer.
* **Archetypal Provenance:** Minecraft (Podzol), Universal Soil Pedology

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `1350.0 kg/m^3`
- Mohs Hardness: `1.5`
- Young's Modulus ($E$): `0.04 GPa` | Poisson's Ratio ($\nu$): `0.35`
- Coulomb Friction ($\mu$): `0.65` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `500.0 J`
- Thermal Conductivity ($k$): `0.28 W/(m·K)` | Specific Heat ($c_p$): `950.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.30, 0.22, 0.16]`
- Microfacet Roughness ($\alpha$): `0.9` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.48` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.7 `mineral.salt` — Halite / Rock Salt
* **Description:** Isometric ionic crystal composed of sodium chloride ($NaCl$); highly soluble in water, depresses ice melting point.
* **Archetypal Provenance:** Universal Chemical/Culinary Mineralogy

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `2160.0 kg/m^3`
- Mohs Hardness: `2.5`
- Young's Modulus ($E$): `40.0 GPa` | Poisson's Ratio ($\nu$): `0.25`
- Coulomb Friction ($\mu$): `0.5` | Restitution ($e$): `0.4`
- Blast Fracture Threshold: `2500.0 J`
- Thermal Conductivity ($k$): `6.5 W/(m·K)` | Specific Heat ($c_p$): `880.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[0.96, 0.96, 0.97]`
- Microfacet Roughness ($\alpha$): `0.12` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.544` | Transmittance ($\tau$): `0.85`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `refractive_dielectric`

---

### 2.8 `mineral.sulfur` — Sulfur / Brimstone
* **Description:** Bright yellow orthorhombic non-metallic crystal with low melting point ($388.36\text{ K}$), combustible with blue flame.
* **Archetypal Provenance:** Universal Energetics/Chemical Precursors

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `2070.0 kg/m^3`
- Mohs Hardness: `2.0`
- Young's Modulus ($E$): `15.0 GPa` | Poisson's Ratio ($\nu$): `0.3`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `2000.0 J`
- Thermal Conductivity ($k$): `0.205 W/(m·K)` | Specific Heat ($c_p$): `710.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `388.36 K`
- Kinematic Gravity: `False` | Flammable: `True` (Ignition $T > 500\text{ K}$)
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.92, 0.82, 0.15]`
- Microfacet Roughness ($\alpha$): `0.6` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.95` | Transmittance ($\tau$): `0.05`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.9 `mineral.gypsum` — Gypsum / Hydrous Calcium Sulfate
* **Description:** Soft sulfate mineral ($CaSO_4 \cdot 2H_2O$) capable of thermal calcination into plaster of Paris.
* **Archetypal Provenance:** Universal Civil/Masonry Mineralogy

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `2310.0 kg/m^3`
- Mohs Hardness: `2.0`
- Young's Modulus ($E$): `12.0 GPa` | Poisson's Ratio ($\nu$): `0.33`
- Coulomb Friction ($\mu$): `0.45` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `2200.0 J`
- Thermal Conductivity ($k$): `0.17 W/(m·K)` | Specific Heat ($c_p$): `1090.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.90, 0.88, 0.86]`
- Microfacet Roughness ($\alpha$): `0.55` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.52` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.10 `mineral.ash` — Combustion / Volcanic Ash
* **Description:** Fine particulate mineral residue of pulverized volcanic rock or completed vegetative pyrolysis; pozzolanic binder additive.
* **Archetypal Provenance:** Universal Geology/Civil Cement

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `750.0 kg/m^3`
- Mohs Hardness: `1.0`
- Young's Modulus ($E$): `0.01 GPa` | Poisson's Ratio ($\nu$): `0.25`
- Coulomb Friction ($\mu$): `0.5` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `150.0 J`
- Thermal Conductivity ($k$): `0.12 W/(m·K)` | Specific Heat ($c_p$): `800.0 J/(kg·K)`
- Kinematic Gravity: `True` | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.35, 0.35, 0.35]`
- Microfacet Roughness ($\alpha$): `0.98` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.50` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

## 3. Semantic Transition Calculus (STC) Reactions

### `reaction.acid_carbonate_dissolution`
* **Category:** `chemical_solvation`
* **Operator:** $\tau_{\text{dissolve}}: \text{rock.limestone} + \text{fluid.acid} \to \text{fluid.water} + \text{gas.co2}$
* **Preconditions:** Face adjacency $\mathcal{N}_6$ contact with low pH fluid.
* **Outcome:** Voxel voiding/solution cavity with effervescent gas release.
* **Invariants:** Stoichiometric mass conservation: $CaCO_3 + 2H^+ \to Ca^{2+} + H_2O + CO_2$.

### `reaction.salt_hydration_dissolution`
* **Category:** `chemical_dissolution`
* **Operator:** $\tau_{\text{salt\_sol}}: \text{mineral.salt} + \text{fluid.water} \to \text{fluid.brine}$
* **Preconditions:** Water moisture contact.
* **Outcome:** Solute assimilation into water volume.
* **Invariants:** Mass conservation ($\sum m = m_{\text{water}} + m_{\text{salt}}$).

### `reaction.pozzolanic_cementation`
* **Category:** `hydration_reaction`
* **Operator:** $\tau_{\text{pozzolan}}: \text{mineral.ash} + \text{rock.calcite} + \text{fluid.water} \to \text{synthetic.concrete}$
* **Preconditions:** Moisture contact over curing time.
* **Outcome:** Interlocking calcium silicate aluminate hydrate solid.
* **Invariants:** Mass conservation.
