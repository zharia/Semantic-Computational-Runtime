---
sprint: sprint_03_raw_ores_transition_metals_alloys
document_type: normative_sprint_specification
milestone: 001_MaterialLibraryExpansion
schema_version: 1.0.0
id: SCR-PI-002-M001-S03
name: Raw Ores, Transition Metals & Advanced Alloys
status: ready
created: 2026-09-16
authority: SCR
---

# Sprint 03: Raw Ores, Transition Metals & Advanced Alloys

**Path:** `program_increments/v0.0.2/milestones/001_MaterialLibraryExpansion/sprints/sprint_03_raw_ores_transition_metals_alloys/spec.md`  
**Parent Milestone:** [001_MaterialLibraryExpansion](../../README.md)  
**Parent Specification:** [spec.md](../../spec.md)  

---

## 1. Sprint Objective

Fill the critical architectural gap between unrefined geological mineral ores and extracted pure metals/structural alloys. Establish high-temperature pyrometallurgical carbothermic reductions, metallurgical alloying mixtures, and chemical surface oxidation/patination dynamics.

---

## 2. Normative Material Catalog Additions

### 2.1 `ore.iron_ore` — Banded Iron Formation / Hematite Ore
* **Description:** Sedimentary or igneous rock matrix containing high concentrations of hematite ($Fe_2O_3$) and magnetite ($Fe_3O_4$).
* **Archetypal Provenance:** Minecraft (Iron Ore), Terraria (Iron Ore), Universal Metallurgy

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `4800.0 kg/m^3`
- Mohs Hardness: `5.5`
- Young's Modulus ($E$): `110.0 GPa` | Poisson's Ratio ($\nu$): `0.26`
- Coulomb Friction ($\mu$): `0.65` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `7500.0 J`
- Thermal Conductivity ($k$): `4.5 W/(m·K)` | Specific Heat ($c_p$): `650.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `stone_pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.45, 0.35, 0.32]`
- Microfacet Roughness ($\alpha$): `0.8` | Metallic Fraction ($m$): `0.1`
- Index of Refraction ($n$): `2.2` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.2 `ore.copper_ore` — Copper Ore / Malachite-Quartz Matrix
* **Description:** Mineral aggregate containing copper sulfides (chalcopyrite) and carbonates (malachite) embedded in silicate host rock.
* **Archetypal Provenance:** Minecraft (Copper Ore), Terraria (Copper Ore), Universal Metallurgy

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `4100.0 kg/m^3`
- Mohs Hardness: `4.0`
- Young's Modulus ($E$): `85.0 GPa` | Poisson's Ratio ($\nu$): `0.28`
- Coulomb Friction ($\mu$): `0.6` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `6500.0 J`
- Thermal Conductivity ($k$): `6.0 W/(m·K)` | Specific Heat ($c_p$): `600.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `stone_pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.32, 0.55, 0.48]`
- Microfacet Roughness ($\alpha$): `0.75` | Metallic Fraction ($m$): `0.1`
- Index of Refraction ($n$): `1.85` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.3 `ore.bauxite` — Bauxite / Aluminum Ore
* **Description:** Sedimentary rock with high aluminum content consisting mostly of gibbsite, boehmite, and diaspore.
* **Archetypal Provenance:** Universal Industrial Metallurgy/CAD

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `2450.0 kg/m^3`
- Mohs Hardness: `2.5`
- Young's Modulus ($E$): `40.0 GPa` | Poisson's Ratio ($\nu$): `0.3`
- Coulomb Friction ($\mu$): `0.6` | Restitution ($e$): `0.15`
- Blast Fracture Threshold: `4000.0 J`
- Thermal Conductivity ($k$): `1.2 W/(m·K)` | Specific Heat ($c_p$): `900.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.72, 0.48, 0.36]`
- Microfacet Roughness ($\alpha$): `0.9` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.60` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.4 `ore.gold_ore` — Native Gold Quartz Matrix
* **Description:** Hydrothermal vein quartz hosting micro- and macroscopic inclusions of native elemental gold.
* **Archetypal Provenance:** Minecraft (Gold Ore), Terraria (Gold Ore), Universal Precious Geology

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `3200.0 kg/m^3`
- Mohs Hardness: `6.5`
- Young's Modulus ($E$): `85.0 GPa` | Poisson's Ratio ($\nu$): `0.2`
- Coulomb Friction ($\mu$): `0.55` | Restitution ($e$): `0.3`
- Blast Fracture Threshold: `7000.0 J`
- Thermal Conductivity ($k$): `3.5 W/(m·K)` | Specific Heat ($c_p$): `700.0 J/(kg·K)`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `iron_pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.65, 0.62, 0.52]`
- Microfacet Roughness ($\alpha$): `0.65` | Metallic Fraction ($m$): `0.15`
- Index of Refraction ($n$): `1.58` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2.5 `metal.bronze` — Bronze Alloy ($Cu_{0.88}Sn_{0.12}$)
* **Description:** Classical structural alloy of copper and tin offering superior hardness, castability, and corrosion resistance compared to pure copper.
* **Archetypal Provenance:** Universal Historical Metallurgy/CAD

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `8800.0 kg/m^3`
- Mohs Hardness: `4.0`
- Young's Modulus ($E$): `115.0 GPa` | Poisson's Ratio ($\nu$): `0.34`
- Coulomb Friction ($\mu$): `0.36` | Restitution ($e$): `0.45`
- Blast Fracture Threshold: `10000.0 J`
- Thermal Conductivity ($k$): `60.0 W/(m·K)` | Specific Heat ($c_p$): `380.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `1223.0 K`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.90, 0.68, 0.42]`
- Microfacet Roughness ($\alpha$): `0.22` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `0.55` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---

### 2.6 `metal.brass` — Brass Alloy ($Cu_{0.70}Zn_{0.30}$)
* **Description:** Malleable acoustic copper-zinc alloy characterized by low friction against other metals and bright golden luster.
* **Archetypal Provenance:** Universal Instrument/Machine Tool Metallurgy

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `8500.0 kg/m^3`
- Mohs Hardness: `3.5`
- Young's Modulus ($E$): `105.0 GPa` | Poisson's Ratio ($\nu$): `0.35`
- Coulomb Friction ($\mu$): `0.32` | Restitution ($e$): `0.48`
- Blast Fracture Threshold: `9500.0 J`
- Thermal Conductivity ($k$): `115.0 W/(m·K)` | Specific Heat ($c_p$): `380.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `1173.0 K`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.95, 0.78, 0.35]`
- Microfacet Roughness ($\alpha$): `0.18` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `0.42` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---

### 2.7 `metal.aluminum` — Aluminum / Pure Light Metal
* **Description:** Low-density post-transition metal with high specific strength, excellent thermal conductivity, and self-passivating alumina oxide layer.
* **Archetypal Provenance:** Universal Modern Aerospace/CAD

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `2700.0 kg/m^3` (Lightweight structural metal)
- Mohs Hardness: `2.75`
- Young's Modulus ($E$): `70.0 GPa` | Poisson's Ratio ($\nu$): `0.35`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.55`
- Blast Fracture Threshold: `9000.0 J`
- Thermal Conductivity ($k$): `237.0 W/(m·K)` | Specific Heat ($c_p$): `900.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `933.47 K`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.91, 0.92, 0.92]`
- Microfacet Roughness ($\alpha$): `0.16` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `1.44` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---

### 2.8 `metal.titanium` — Titanium / Refractory Transition Metal
* **Description:** Lustrous transition metal with silver color, low density, extreme tensile strength, and exceptional corrosion resistance.
* **Archetypal Provenance:** Terraria (Titanium), Universal Extreme Engineering

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `4506.0 kg/m^3`
- Mohs Hardness: `6.0`
- Young's Modulus ($E$): `116.0 GPa` | Poisson's Ratio ($\nu$): `0.32`
- Coulomb Friction ($\mu$): `0.36` | Restitution ($e$): `0.6`
- Blast Fracture Threshold: `14000.0 J`
- Thermal Conductivity ($k$): `21.9 W/(m·K)` | Specific Heat ($c_p$): `523.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `1941.0 K`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `diamond_pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.76, 0.73, 0.69]`
- Microfacet Roughness ($\alpha$): `0.22` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `2.7` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---

### 2.9 `metal.zinc` — Zinc / Galvanic Metal
* **Description:** Diamagnetic metal with moderate reactivity, sacrificial anode galvanic properties, and moderate melting point ($692.68\text{ K}$).
* **Archetypal Provenance:** Universal Industrial Metallurgy/Chemistry

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `7140.0 kg/m^3`
- Mohs Hardness: `2.5`
- Young's Modulus ($E$): `108.0 GPa` | Poisson's Ratio ($\nu$): `0.25`
- Coulomb Friction ($\mu$): `0.42` | Restitution ($e$): `0.35`
- Blast Fracture Threshold: `7500.0 J`
- Thermal Conductivity ($k$): `116.0 W/(m·K)` | Specific Heat ($c_p$): `388.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `692.68 K`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.82, 0.84, 0.86]`
- Microfacet Roughness ($\alpha$): `0.28` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `1.9` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---

### 2.10 `metal.tungsten` — Tungsten / Heavy Wolfram
* **Description:** Ultra-dense transition metal possessing the highest melting point ($3695\text{ K}$) and highest tensile strength at high temperatures.
* **Archetypal Provenance:** Terraria (Tungsten), Universal High-Energy Physics/CAD

**Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$):**
- Density ($\rho$): `19300.0 kg/m^3`
- Mohs Hardness: `7.5`
- Young's Modulus ($E$): `411.0 GPa` | Poisson's Ratio ($\nu$): `0.28`
- Coulomb Friction ($\mu$): `0.3` | Restitution ($e$): `0.65`
- Blast Fracture Threshold: `16000.0 J`
- Thermal Conductivity ($k$): `173.0 W/(m·K)` | Specific Heat ($c_p$): `132.0 J/(kg·K)`
- Melting Temperature ($T_{\text{melt}}$): `3695.0 K`
- Kinematic Gravity: `False` | Flammable: `False`
- Optimal Harvest Tool: `diamond_pickaxe`

**Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$):**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.72, 0.74, 0.76]`
- Microfacet Roughness ($\alpha$): `0.18` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `3.4` | Transmittance ($\tau$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---

## 3. Semantic Transition Calculus (STC) Reactions

### `reaction.bronze_alloying`
* **Category:** `metallurgical_alloying`
* **Operator:** $\tau_{\text{alloy}}: 0.88\,\text{metal.copper} + 0.12\,\text{metal.tin} \xrightarrow{T \ge 1356.0\text{ K}} 1.0\,\text{metal.bronze}$
* **Preconditions:** Co-located molten phases in crucible/vessel.
* **Outcome:** `metal.bronze`
* **Invariants:** Total mass conservation.

### `reaction.copper_patination`
* **Category:** `chemical_passivation`
* **Operator:** $\tau_{\text{patina}}: \text{metal.copper} + \text{gas.air} + \text{fluid.water} \xrightarrow{\Delta t} \text{metal.copper.oxidized}$
* **Preconditions:** Exposure to moist atmospheric gases across multiple simulation ticks.
* **Outcome:** Optical albedo transition to verdigris green `[0.35, 0.65, 0.55]` and roughness increase $\alpha \to 0.85$.
* **Invariants:** Surface boundary mass conservation.

### `reaction.ferrous_oxidation`
* **Category:** `chemical_corrosion`
* **Operator:** $\tau_{\text{rust}}: 4\,\text{metal.iron} + 3\,\text{gas.oxygen} + 6\,\text{fluid.water} \to 4\,\text{mineral.rust}$
* **Preconditions:** Moisture contact and air exposure over extended temporal delta.
* **Outcome:** Degradation of elastic modulus $E \to 20.0\text{ GPa}$, blast threshold collapse to $1200.0\text{ J}$.
* **Invariants:** Iron elemental stoichiometric conservation.
