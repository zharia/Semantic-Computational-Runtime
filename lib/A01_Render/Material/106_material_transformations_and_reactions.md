---
document: 106_material_transformations_and_reactions
document_type: normative_semantic_specification
schema_version: 1.0.0
id: SCR-LIB-MATERIAL-TRANSFORMATIONS
name: Universal Material Transformations, Reactions & Kinematics
version: 1.1.0
status: operational
created: 2026-09-16
updated: 2026-09-16
parent: SCR-LIB-RENDER-MATERIAL
authority: SCR
domain: semantic-library
---

# Universal Material Transformations, Reactions & Kinematics

**Path:** `lib/A01_Render/Material/106_material_transformations_and_reactions.md`  
**Associated Data:** [`material_reactions.json`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/material_reactions.json)  
**Governing Calculus:** [`docs/107_SEMANTIC_TRANSITION_CALCULUS.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/107_SEMANTIC_TRANSITION_CALCULUS.md)  
**Normative Catalog:** [`lib/A01_Render/Material/105_unified_materials_catalog.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/105_unified_materials_catalog.md)  

---

## 1. Architectural Scope & STC Foundation

Materials in the Semantic Computational Runtime are dynamic participants in the **Semantic Transition Calculus (STC)**.
Transformations between material states obey formal typed transition operators:

$$\tau_{\text{react}}: \mathcal{S}_{\text{mat}} \times \mathcal{C}_{\text{adj}} \xrightarrow{K} \mathcal{S}'_{\text{mat}}$$

where:
* $\mathcal{S}_{\text{mat}}$ is the current material state (constitutive tensors, optical BSDF closures, temperature, hydration).
* $\mathcal{C}_{\text{adj}}$ is the topological neighborhood context defined via [`lib/303_Topology/Adjacency`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/303_Topology/Adjacency).
* $K$ represents invariant conservation constraints (mass conservation, enthalpy dissipation, energy conservation).

---

## 2. Canonical Reaction Matrix (27 Universal Reactions)

| Identifier | Reaction Name | Category | Primary Reactant | Trigger / Adjacency | Primary Outcome | Byproduct |
|:---|:---|:---|:---|:---|:---|:---|
| `reaction.lava_water_quench` | **Lava Quenching / Solidification** | `thermal_phase_change` | `fluid.lava` | `fluid.water` | `rock.obsidian` | `fluid.steam` |
| `reaction.sand_vitrification` | **Sand Vitrification (Glass Synthesis)** | `thermal_phase_change` | `soil.sand` | `1973.0` | `synthetic.glass` | `gas.co2` |
| `reaction.clay_pyrolysis` | **Clay Ceramic Sintering** | `thermal_sintering` | `soil.clay` | `1173.0` | `synthetic.terracotta` | `vapor.water` |
| `reaction.concrete_hydration` | **Concrete Hydraulic Setting** | `hydration_reaction` | `granular.concrete_powder` | `fluid.water` | `synthetic.concrete` | `None` |
| `reaction.dirt_hydration` | **Soil Hydration (Mud Formation)** | `hydration_reaction` | `soil.dirt` | `fluid.water` | `soil.mud` | `None` |
| `reaction.iron_smelting` | **Ferrous Carbothermic Reduction** | `metallurgical_reduction` | `ore.iron_ore` | `1523.0` | `metal.iron` | `gas.co2` |
| `reaction.wood_combustion` | **Cellulose Pyrolysis & Combustion** | `chemical_oxidation` | `['wood.hardwood', 'wood.softwood', 'wood.birch', 'botanical.foliage', 'organic.fiber']` | `Trigger` | `mineral.ash` | `gas.smoke` |
| `reaction.granular_gravity_collapse` | **Granular Mohr-Coulomb Collapse** | `kinematic_transition` | `['soil.sand', 'soil.gravel']` | `Trigger` | `kinematic_entity_fall(velocity=-9.81 m/s^2)` | `None` |
| `reaction.water_freezing` | **Water Freezing Phase Change** | `thermal_phase_change` | `fluid.water` | `273.15` | `cryo.ice` | `None` |
| `reaction.ice_melting` | **Ice Thermal Fusion (Melting)** | `thermal_phase_change` | `cryo.ice` | `273.15` | `fluid.water` | `None` |
| `reaction.snow_compaction` | **Snow Overburden Compaction / Sintering** | `mechanical_compaction` | `cryo.snow` | `Trigger` | `cryo.packed_ice` | `None` |
| `reaction.ice_salt_depression` | **Colligative Freezing Point Depression (Salt Brine)** | `chemical_colligative` | `cryo.ice` | `mineral.salt` | `fluid.water` | `None` |
| `reaction.acid_carbonate_dissolution` | **Acid Carbonate Dissolution (Effervescence)** | `chemical_solvation` | `rock.limestone` | `fluid.acid` | `fluid.water` | `gas.co2` |
| `reaction.salt_hydration_dissolution` | **Halite Aqueous Dissolution** | `chemical_dissolution` | `mineral.salt` | `fluid.water` | `fluid.water` | `None` |
| `reaction.pozzolanic_cementation` | **Pozzolanic Hydraulic Reaction** | `hydration_reaction` | `mineral.ash` | `rock.calcite` | `synthetic.concrete` | `None` |
| `reaction.bronze_alloying` | **Pyrometallurgical Bronze Alloying** | `metallurgical_alloying` | `metal.copper` | `1356.0` | `metal.bronze` | `None` |
| `reaction.copper_patination` | **Copper Atmospheric Patination** | `chemical_passivation` | `metal.copper` | `Trigger` | `metal.copper` | `None` |
| `reaction.ferrous_oxidation` | **Ferrous Hydrated Rusting** | `chemical_corrosion` | `metal.iron` | `Trigger` | `soil.dirt` | `None` |
| `reaction.piezoelectric_excitation` | **Piezoelectric Electromechanical Transduction** | `electromechanical_coupling` | `gem.quartz` | `Trigger` | `gem.quartz` | `None` |
| `reaction.phosphorescent_decay` | **Phosphorescent Radiance Temporal Decay** | `optical_radiative_transfer` | `mineral.phosphor` | `Trigger` | `mineral.phosphor` | `None` |
| `reaction.biomass_slow_pyrolysis` | **Anoxic Biomass Charcoal Pyrolysis** | `chemical_pyrolysis` | `wood.hardwood` | `673.0` | `wood.charcoal` | `gas.smoke` |
| `reaction.mycelial_decomposition` | **Mycelial Colonization & Detritus Decomposition** | `biological_spread` | `botanical.mycelium` | `soil.dirt` | `botanical.mycelium` | `None` |
| `reaction.fluid_density_stratification` | **Gravitational Multiphase Oil-Water Stratification** | `fluid_stratification` | `fluid.oil` | `fluid.water` | `fluid.oil` | `fluid.water` |
| `reaction.hydrocarbon_combustion` | **Liquid Petroleum Hydrocarbon Combustion** | `chemical_oxidation` | `fluid.oil` | `Trigger` | `gas.smoke` | `gas.co2` |
| `reaction.steam_condensation` | **Steam Thermal Condensation** | `thermal_phase_change` | `gas.steam` | `373.15` | `fluid.water` | `None` |
| `reaction.concrete_powder_hydration` | **Concrete Powder Hydraulic Setting** | `hydration_reaction` | `granular.concrete_powder` | `fluid.water` | `synthetic.concrete` | `None` |
| `reaction.detonation_shockwave` | **High Explosive Chapman-Jouguet Detonation** | `explosive_detonation` | `synthetic.explosive` | `Trigger` | `gas.smoke` | `thermal.shockwave` |

---

## 3. Detailed Reaction Specifications

### `reaction.lava_water_quench` — Lava Quenching / Solidification
* **Category:** `thermal_phase_change`
* **Description:** Rapid thermal quenching of molten lava by water across a topological face adjacency.
* **Preconditions:** `{"primary": "fluid.lava", "adjacent": "fluid.water", "adjacency_type": "face_sharing_6_neighborhood"}`
* **Transformations:**
  - **Condition:** `primary.is_source_block == True` $\to$ Outcome: `rock.obsidian` (Byproduct: `fluid.steam`)
  - **Condition:** `primary.is_source_block == False` $\to$ Outcome: `rock.cobblestone` (Byproduct: `fluid.steam`)
* **Enforced Invariant Conservations:** `mass_conservation, enthalpy_dissipation`

### `reaction.sand_vitrification` — Sand Vitrification (Glass Synthesis)
* **Category:** `thermal_phase_change`
* **Description:** Endothermic thermal fusion of quartz sand grains into amorphous glass solid.
* **Preconditions:** `{"primary": "soil.sand", "thermal_threshold_k": 1973.0, "flux_agent": "optional_soda_ash"}`
* **Transformations:**
  - **Condition:** `temperature >= 1973.0 K` $\to$ Outcome: `synthetic.glass` (Byproduct: `gas.co2`)
* **Enforced Invariant Conservations:** `silica_mass_conservation`

### `reaction.clay_pyrolysis` — Clay Ceramic Sintering
* **Category:** `thermal_sintering`
* **Description:** Dehydroxylation and crystalline sintering of hydrous phyllosilicate clay into durable ceramic brick/terracotta.
* **Preconditions:** `{"primary": "soil.clay", "thermal_threshold_k": 1173.0}`
* **Transformations:**
  - **Condition:** `temperature in [1173.0, 1373.0] K` $\to$ Outcome: `synthetic.terracotta` (Byproduct: `vapor.water`)
  - **Condition:** `temperature > 1373.0 K` $\to$ Outcome: `synthetic.brick` (Byproduct: `vapor.water`)
* **Enforced Invariant Conservations:** `alumina_silicate_conservation`

### `reaction.concrete_hydration` — Concrete Hydraulic Setting
* **Category:** `hydration_reaction`
* **Description:** Hydraulic exothermic reaction between Portland clinker phases and water creating interlocking calcium silicate hydrate crystals.
* **Preconditions:** `{"primary": "granular.concrete_powder", "adjacent": "fluid.water", "adjacency_type": "moisture_contact"}`
* **Transformations:**
  - **Condition:** `water_contact == True` $\to$ Outcome: `synthetic.concrete` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `aggregate_mass_conservation`

### `reaction.dirt_hydration` — Soil Hydration (Mud Formation)
* **Category:** `hydration_reaction`
* **Description:** Saturation of organic loam soil by liquid water, collapsing shear modulus and producing cohesive mud.
* **Preconditions:** `{"primary": "soil.dirt", "adjacent": "fluid.water", "adjacency_type": "percolation_contact"}`
* **Transformations:**
  - **Condition:** `saturation_fraction >= 0.85` $\to$ Outcome: `soil.mud` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `mineral_mass_conservation, fluid_volume_conservation`

### `reaction.iron_smelting` — Ferrous Carbothermic Reduction
* **Category:** `metallurgical_reduction`
* **Description:** High-temperature reduction of iron oxides via elemental carbon, yielding structural metallic iron.
* **Preconditions:** `{"primary": "ore.iron_ore", "reducing_agent": "ore.coal", "thermal_threshold_k": 1523.0}`
* **Transformations:**
  - **Condition:** `temperature >= 1523.0 K and carbon_present == True` $\to$ Outcome: `metal.iron` (Byproduct: `gas.co2`)
* **Enforced Invariant Conservations:** `elemental_iron_conservation`

### `reaction.wood_combustion` — Cellulose Pyrolysis & Combustion
* **Category:** `chemical_oxidation`
* **Description:** Exothermic oxidation of botanical cellulose, lignins, and resins yielding blackbody radiant heat and carbon residue.
* **Preconditions:** `{"primary": ["wood.hardwood", "wood.softwood", "wood.birch", "botanical.foliage", "organic.fiber"], "oxidizer": "gas.oxygen", "ignition_energy_j": 500.0}`
* **Transformations:**
  - **Condition:** `combustion_complete == True` $\to$ Outcome: `mineral.ash` (Byproduct: `gas.smoke`)
* **Enforced Invariant Conservations:** `total_energy_conservation`

### `reaction.granular_gravity_collapse` — Granular Mohr-Coulomb Collapse
* **Category:** `kinematic_transition`
* **Description:** Downwards vertical transposition of granular media when adjacent supportive voxels are absent.
* **Preconditions:** `{"primary": ["soil.sand", "soil.gravel"], "downward_adjacency": "air_or_fluid_void"}`
* **Transformations:**
  - **Condition:** `voxel(x, y-1, z).occupancy == False` $\to$ Outcome: `kinematic_entity_fall(velocity=-9.81 m/s^2)` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `momentum_conservation, voxel_mass_conservation`

### `reaction.water_freezing` — Water Freezing Phase Change
* **Category:** `thermal_phase_change`
* **Description:** Isobaric crystallization of liquid water into solid ice below 273.15 K with 9% volumetric expansion.
* **Preconditions:** `{"primary": "fluid.water", "thermal_threshold_k": 273.15, "latent_heat_release_j_kg": 334000.0}`
* **Transformations:**
  - **Condition:** `temperature <= 273.15 K` $\to$ Outcome: `cryo.ice` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `mass_conservation, enthalpy_dissipation`

### `reaction.ice_melting` — Ice Thermal Fusion (Melting)
* **Category:** `thermal_phase_change`
* **Description:** Endothermic phase transition of solid ice into liquid water above 273.15 K.
* **Preconditions:** `{"primary": "cryo.ice", "thermal_threshold_k": 273.15}`
* **Transformations:**
  - **Condition:** `temperature > 273.15 K` $\to$ Outcome: `fluid.water` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `mass_conservation, enthalpy_absorption`

### `reaction.snow_compaction` — Snow Overburden Compaction / Sintering
* **Category:** `mechanical_compaction`
* **Description:** Pore space collapse and grain sintering of snow crystals under compressive overburden pressure.
* **Preconditions:** `{"primary": "cryo.snow", "overburden_pressure_kpa": 10.0}`
* **Transformations:**
  - **Condition:** `pressure >= 10.0 kPa` $\to$ Outcome: `cryo.packed_ice` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `mass_conservation`

### `reaction.ice_salt_depression` — Colligative Freezing Point Depression (Salt Brine)
* **Category:** `chemical_colligative`
* **Description:** Thermodynamic depression of the freezing point of ice via contact with soluble halite salt.
* **Preconditions:** `{"primary": "cryo.ice", "adjacent": "mineral.salt", "adjacency_type": "face_sharing_6_neighborhood"}`
* **Transformations:**
  - **Condition:** `temperature >= 252.0 K` $\to$ Outcome: `fluid.water` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `total_solute_mass_conservation`

### `reaction.acid_carbonate_dissolution` — Acid Carbonate Dissolution (Effervescence)
* **Category:** `chemical_solvation`
* **Description:** Chemical dissolution of limestone by acid releasing carbon dioxide gas and voiding solid cavity.
* **Preconditions:** `{"primary": "rock.limestone", "adjacent": "fluid.acid", "adjacency_type": "face_sharing_6_neighborhood"}`
* **Transformations:**
  - **Condition:** `acid_contact == True` $\to$ Outcome: `fluid.water` (Byproduct: `gas.co2`)
* **Enforced Invariant Conservations:** `stoichiometric_mass_conservation`

### `reaction.salt_hydration_dissolution` — Halite Aqueous Dissolution
* **Category:** `chemical_dissolution`
* **Description:** Dissolution of halite into liquid water creating dissolved ionic brine.
* **Preconditions:** `{"primary": "mineral.salt", "adjacent": "fluid.water", "adjacency_type": "face_sharing_6_neighborhood"}`
* **Transformations:**
  - **Condition:** `water_contact == True` $\to$ Outcome: `fluid.water` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `solute_mass_conservation`

### `reaction.pozzolanic_cementation` — Pozzolanic Hydraulic Reaction
* **Category:** `hydration_reaction`
* **Description:** Reaction between siliceous volcanic ash and calcium hydroxide forming hydraulic concrete.
* **Preconditions:** `{"primary": "mineral.ash", "adjacent": "rock.calcite", "hydration_agent": "fluid.water"}`
* **Transformations:**
  - **Condition:** `curing_time_elapsed == True` $\to$ Outcome: `synthetic.concrete` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `mass_conservation`

### `reaction.bronze_alloying` — Pyrometallurgical Bronze Alloying
* **Category:** `metallurgical_alloying`
* **Description:** Fusion of molten copper and molten tin in 88:12 mass proportion to synthesize structural bronze.
* **Preconditions:** `{"primary": "metal.copper", "secondary": "metal.tin", "thermal_threshold_k": 1356.0}`
* **Transformations:**
  - **Condition:** `temperature >= 1356.0 K` $\to$ Outcome: `metal.bronze` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `alloy_mass_conservation`

### `reaction.copper_patination` — Copper Atmospheric Patination
* **Category:** `chemical_passivation`
* **Description:** Gradual oxidation and carbonation of metallic copper forming green verdigris surface protective layer.
* **Preconditions:** `{"primary": "metal.copper", "adjacent_atmosphere": "gas.air", "humidity_present": true}`
* **Transformations:**
  - **Condition:** `exposure_ticks >= 10000` $\to$ Outcome: `metal.copper` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `surface_boundary_conservation`

### `reaction.ferrous_oxidation` — Ferrous Hydrated Rusting
* **Category:** `chemical_corrosion`
* **Description:** Corrosion of elemental iron by oxygen and water forming porous, structurally weak iron oxide.
* **Preconditions:** `{"primary": "metal.iron", "adjacent_oxidizer": "gas.air", "adjacent_electrolyte": "fluid.water"}`
* **Transformations:**
  - **Condition:** `corrosion_complete == True` $\to$ Outcome: `soil.dirt` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `iron_stoichiometric_conservation`

### `reaction.piezoelectric_excitation` — Piezoelectric Electromechanical Transduction
* **Category:** `electromechanical_coupling`
* **Description:** Conversion of high transient mechanical stress into electrical potential difference.
* **Preconditions:** `{"primary": "gem.quartz", "mechanical_stress_threshold_kpa": 500.0}`
* **Transformations:**
  - **Condition:** `stress >= 500.0 kPa` $\to$ Outcome: `gem.quartz` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `mechanical_to_electrical_energy`

### `reaction.phosphorescent_decay` — Phosphorescent Radiance Temporal Decay
* **Category:** `optical_radiative_transfer`
* **Description:** Exponential temporal decay of stored optical photon energy in phosphors in the absence of excitation.
* **Preconditions:** `{"primary": "mineral.phosphor", "pump_light_present": false}`
* **Transformations:**
  - **Condition:** `elapsed_time > 0` $\to$ Outcome: `mineral.phosphor` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `radiative_energy_conservation`

### `reaction.biomass_slow_pyrolysis` — Anoxic Biomass Charcoal Pyrolysis
* **Category:** `chemical_pyrolysis`
* **Description:** Thermal decomposition of dense hardwood in anoxic environment producing charcoal.
* **Preconditions:** `{"primary": "wood.hardwood", "thermal_threshold_k": 673.0, "anoxic_atmosphere": true}`
* **Transformations:**
  - **Condition:** `temperature >= 673.0 K` $\to$ Outcome: `wood.charcoal` (Byproduct: `gas.smoke`)
* **Enforced Invariant Conservations:** `carbon_elemental_conservation, energy_conservation`

### `reaction.mycelial_decomposition` — Mycelial Colonization & Detritus Decomposition
* **Category:** `biological_spread`
* **Description:** Colonization of adjacent loam soil by fungal mycelial network.
* **Preconditions:** `{"primary": "botanical.mycelium", "adjacent": "soil.dirt", "adjacency_type": "face_sharing_6_neighborhood"}`
* **Transformations:**
  - **Condition:** `moisture_present == True` $\to$ Outcome: `botanical.mycelium` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `mineral_substrate_conservation`

### `reaction.fluid_density_stratification` — Gravitational Multiphase Oil-Water Stratification
* **Category:** `fluid_stratification`
* **Description:** Gravitational phase separation of immiscible oil and water where oil floats above water.
* **Preconditions:** `{"primary": "fluid.oil", "adjacent": "fluid.water", "adjacency_type": "vertical_column_contact"}`
* **Transformations:**
  - **Condition:** `gravity_vector == [0, -1, 0]` $\to$ Outcome: `fluid.oil` (Byproduct: `fluid.water`)
* **Enforced Invariant Conservations:** `immiscible_volume_conservation`

### `reaction.hydrocarbon_combustion` — Liquid Petroleum Hydrocarbon Combustion
* **Category:** `chemical_oxidation`
* **Description:** Rapid exothermic oxidation of liquid petroleum with radiant thermal flame and soot byproduct.
* **Preconditions:** `{"primary": "fluid.oil", "ignition_energy_j": 200.0, "adjacent_oxidizer": "gas.air"}`
* **Transformations:**
  - **Condition:** `ignition == True` $\to$ Outcome: `gas.smoke` (Byproduct: `gas.co2`)
* **Enforced Invariant Conservations:** `total_energy_conservation, species_mass_conservation`

### `reaction.steam_condensation` — Steam Thermal Condensation
* **Category:** `thermal_phase_change`
* **Description:** Phase transition of gaseous steam into liquid water upon cooling below 373.15 K.
* **Preconditions:** `{"primary": "gas.steam", "thermal_threshold_k": 373.15}`
* **Transformations:**
  - **Condition:** `temperature < 373.15 K` $\to$ Outcome: `fluid.water` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `water_mass_conservation`

### `reaction.concrete_powder_hydration` — Concrete Powder Hydraulic Setting
* **Category:** `hydration_reaction`
* **Description:** Hydraulic setting of dry concrete powder upon water contact into monolithic structural concrete.
* **Preconditions:** `{"primary": "granular.concrete_powder", "adjacent": "fluid.water", "adjacency_type": "face_sharing_6_neighborhood"}`
* **Transformations:**
  - **Condition:** `water_contact == True` $\to$ Outcome: `synthetic.concrete` (Byproduct: `None`)
* **Enforced Invariant Conservations:** `mineral_mass_conservation`

### `reaction.detonation_shockwave` — High Explosive Chapman-Jouguet Detonation
* **Category:** `explosive_detonation`
* **Description:** Supersonic detonation shockwave generation fracturing all adjacent voxels exceeding blast resistance.
* **Preconditions:** `{"primary": "synthetic.explosive", "detonation_energy_threshold_j": 50.0}`
* **Transformations:**
  - **Condition:** `detonation_triggered == True` $\to$ Outcome: `gas.smoke` (Byproduct: `thermal.shockwave`)
* **Enforced Invariant Conservations:** `detonation_energy_conservation`



## 4. Tool & Mechanical Harvest Affinities

Harvesting and excavation in voxel simulation obey mechanical work dissipation:
$$t_{\text{harvest}} = \frac{\text{density} \times \text{Mohs Hardness}}{\text{Tool Power} \times \text{Affinity Multiplier}}$$

| Tool Class | Name | Targeted Materials | Affinity Multiplier | Work Expended ($J/m^3$) |
|:---|:---|:---|:---:|:---:|
| `shovel` | **Excavation Spades & Shovels** | `soil.*, cryo.snow, granular.*` | 4.0x | 150.0 J |
| `pickaxe` | **Mining Pickaxes & Drills** | `rock.*, ore.*, metal.*, gem.*` | 5.0x | 850.0 J |
| `axe` | **Felling Axes & Saws** | `wood.*, botanical.cactus` | 4.5x | 320.0 J |
| `shears` | **Shears & Cutting Blades** | `botanical.foliage, organic.fiber, organic.leather, synthetic.aerogel` | 6.0x | 50.0 J |
| `bucket` | **Containment Vessels (Buckets)** | `fluid.*, cryo.powder_snow` | 1.0x | 20.0 J |

---

## 5. Topological Adjacency & Voxel Grid Integration

1. **Face-Sharing 6-Neighborhood (von Neumann)**: High-speed fluid flow, direct thermal quenching (`reaction.lava_water_quench`), freezing-point depression (`reaction.ice_salt_depression`), and concrete setting (`reaction.concrete_powder_hydration`) require shared 2D face contact.
2. **Moore 26-Neighborhood**: Atmospheric patination (`reaction.copper_patination`), rusting (`reaction.ferrous_oxidation`), and percolative hydration expand across corner- and edge-adjacent voxels.
3. **Downwards Gravity Adjacency**: Evaluates $z - 1$ (or $y - 1$ depending on coordinate convention) to enforce discrete kinematic falling entity instantiation for granular soils and falling block media (`soil.sand`, `soil.gravel`, `granular.concrete_powder`, `cryo.powder_snow`).
