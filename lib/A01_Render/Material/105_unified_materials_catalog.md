---
document: 105_unified_materials_catalog
document_type: normative_semantic_catalog
schema_version: 1.0.0
id: SCR-LIB-RENDER-UNIFIED-MATERIALS
name: Unified Universal Materials Catalog
version: 1.1.0
status: operational
created: 2026-09-16
updated: 2026-09-16
parent: SCR-LIB-RENDER-MATERIAL
authority: SCR
domain: semantic-library
---

# Unified Universal Materials Catalog

**Path:** `lib/A01_Render/Material/105_unified_materials_catalog.md`  
**Associated Data:** [`materials_catalog.json`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/materials_catalog.json)  
**Physical Specification:** [`lib/501_Physics/Material/101_definition.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/501_Physics/Material/101_definition.md)  
**Render Specification:** [`lib/A01_Render/Material/101_definition.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/101_definition.md)  

---

## 1. Architectural Scope & Semantic Primacy

Per **Rule 1** (*Semantics are authoritative*), **Rule 2** (*Implementation does not define meaning*), and **Rule 18** (*External technologies remain subordinate to SCR contracts*), this catalog establishes the **canonical unified inventory of universal materials** shared across foundational sandbox games (Minecraft, Terraria) and physical/optical simulation engines.

Materials are selected for **broad focus, universal appeal, cross-engine utility, and foundational physical/optical significance**, filtering out single-game proprietary/fantasy lore in favor of universal geological, metallurgic, crystalline, botanical, fluidic, and synthetic archetypes.

Each material establishes a rigorous **Dual-Contract**: 
1. **Physical Constitutive Contract (`SCR-LIB-PHYSICS-MATERIAL`)**: Mass density ($ho$), Mohs hardness, elastic moduli ($E, 
u$), friction ($\mu$), restitution ($e$), blast resistance ($J$), thermal properties ($k, c_p$), and kinematic gravity susceptibility.
2. **Optical Appearance Contract (`SCR-LIB-RENDER-MATERIAL`)**: Surface BSDF distribution model, base albedo color, microfacet roughness ($lpha$), metallic parameter ($m$), index of refraction ($n$), transmittance ($	au$), and emission ($L_e$).

---

## 2. Summary Matrix (96 Universal Materials)

| Identifier | Name | Category | Density ($	ext{kg/m}^3$) | Hardness (Mohs) | Blast Res. ($J$) | Optical BSDF | Albedo RGB | IOR ($n$) |
|:---|:---|:---|:---:|:---:|:---:|:---|:---:|:---:|
| `soil.dirt` | **Dirt / Loam** | `geological_soil` | 1450.0 | 1.5 | 500.0 | `burley_diffuse` | `[0.34, 0.23, 0.15]` | 1.45 |
| `soil.mud` | **Mud** | `geological_soil` | 1750.0 | 1.0 | 400.0 | `dielectric_specular_coated_diffuse` | `[0.22, 0.18, 0.14]` | 1.34 |
| `soil.clay` | **Clay** | `geological_soil` | 1600.0 | 2.0 | 600.0 | `burley_diffuse` | `[0.62, 0.65, 0.70]` | 1.52 |
| `soil.sand` | **Sand** | `geological_soil` | 1600.0 | 2.5 | 500.0 | `burley_diffuse` | `[0.86, 0.78, 0.56]` | 1.54 |
| `soil.gravel` | **Gravel** | `geological_soil` | 1800.0 | 3.5 | 600.0 | `burley_diffuse` | `[0.55, 0.53, 0.52]` | 1.53 |
| `rock.stone` | **Stone / Natural Rock** | `geological_lithic` | 2650.0 | 5.5 | 6000.0 | `burley_diffuse` | `[0.50, 0.50, 0.50]` | 1.54 |
| `rock.cobblestone` | **Cobblestone / Fractured Lithic** | `geological_lithic` | 2400.0 | 5.0 | 5500.0 | `burley_diffuse_with_displacement` | `[0.42, 0.42, 0.42]` | 1.53 |
| `rock.granite` | **Granite** | `geological_lithic` | 2700.0 | 6.0 | 6500.0 | `burley_diffuse` | `[0.60, 0.42, 0.36]` | 1.55 |
| `rock.diorite` | **Diorite** | `geological_lithic` | 2850.0 | 6.0 | 6500.0 | `burley_diffuse` | `[0.72, 0.72, 0.72]` | 1.55 |
| `rock.andesite` | **Andesite** | `geological_lithic` | 2600.0 | 5.5 | 6000.0 | `burley_diffuse` | `[0.52, 0.52, 0.52]` | 1.54 |
| `rock.basalt` | **Basalt** | `geological_lithic` | 2900.0 | 6.0 | 7000.0 | `burley_diffuse` | `[0.25, 0.25, 0.27]` | 1.58 |
| `rock.obsidian` | **Obsidian** | `geological_lithic` | 2600.0 | 7.0 | 12000.0 | `dielectric_specular` | `[0.08, 0.06, 0.12]` | 1.5 |
| `rock.sandstone` | **Sandstone** | `geological_lithic` | 2200.0 | 4.5 | 4000.0 | `burley_diffuse` | `[0.82, 0.74, 0.52]` | 1.52 |
| `rock.marble` | **Marble** | `geological_lithic` | 2700.0 | 4.0 | 5000.0 | `subsurface_scattering_dielectric` | `[0.92, 0.92, 0.90]` | 1.53 |
| `rock.slate` | **Slate / Deepslate** | `geological_lithic` | 2800.0 | 6.0 | 7500.0 | `burley_diffuse` | `[0.28, 0.28, 0.30]` | 1.55 |
| `ore.coal` | **Coal / Carbon Solid** | `ore_and_metal` | 1350.0 | 2.5 | 3000.0 | `burley_diffuse` | `[0.12, 0.12, 0.12]` | 1.8 |
| `metal.iron` | **Iron** | `ore_and_metal` | 7874.0 | 4.5 | 10000.0 | `conductor_fresnel_ggx` | `[0.77, 0.78, 0.78]` | 2.95 |
| `metal.copper` | **Copper** | `ore_and_metal` | 8960.0 | 3.0 | 9000.0 | `conductor_fresnel_ggx` | `[0.95, 0.64, 0.54]` | 0.27 |
| `metal.gold` | **Gold** | `ore_and_metal` | 19300.0 | 2.5 | 8000.0 | `conductor_fresnel_ggx` | `[1.00, 0.77, 0.34]` | 0.18 |
| `metal.silver` | **Silver** | `ore_and_metal` | 10490.0 | 2.5 | 8500.0 | `conductor_fresnel_ggx` | `[0.97, 0.96, 0.95]` | 0.14 |
| `metal.tin` | **Tin** | `ore_and_metal` | 7310.0 | 1.5 | 7000.0 | `conductor_fresnel_ggx` | `[0.85, 0.85, 0.84]` | 1.8 |
| `metal.lead` | **Lead** | `ore_and_metal` | 11340.0 | 1.5 | 8000.0 | `conductor_fresnel_ggx` | `[0.45, 0.46, 0.48]` | 2.05 |
| `metal.platinum` | **Platinum** | `ore_and_metal` | 21450.0 | 4.5 | 11000.0 | `conductor_fresnel_ggx` | `[0.82, 0.84, 0.86]` | 2.3 |
| `metal.steel` | **Steel / Refined Ferrous Alloy** | `ore_and_metal` | 7850.0 | 6.5 | 12000.0 | `conductor_fresnel_ggx` | `[0.75, 0.77, 0.80]` | 2.8 |
| `gem.quartz` | **Quartz** | `gemstone_silicate` | 2650.0 | 7.0 | 5000.0 | `dielectric_specular` | `[0.94, 0.94, 0.94]` | 1.544 |
| `gem.diamond` | **Diamond** | `gemstone_silicate` | 3515.0 | 10.0 | 15000.0 | `dielectric_specular` | `[0.70, 0.92, 0.95]` | 2.418 |
| `gem.emerald` | **Emerald** | `gemstone_silicate` | 2760.0 | 7.8 | 6000.0 | `dielectric_specular` | `[0.10, 0.80, 0.35]` | 1.58 |
| `gem.ruby` | **Ruby** | `gemstone_silicate` | 4020.0 | 9.0 | 9000.0 | `dielectric_specular` | `[0.88, 0.12, 0.22]` | 1.77 |
| `gem.sapphire` | **Sapphire** | `gemstone_silicate` | 3980.0 | 9.0 | 9000.0 | `dielectric_specular` | `[0.10, 0.25, 0.85]` | 1.77 |
| `gem.amethyst` | **Amethyst** | `gemstone_silicate` | 2650.0 | 7.0 | 5000.0 | `dielectric_specular` | `[0.60, 0.25, 0.80]` | 1.54 |
| `wood.hardwood` | **Hardwood / Oak** | `organic_botanical` | 720.0 | 3.0 | 2000.0 | `burley_diffuse_anisotropic` | `[0.65, 0.45, 0.28]` | 1.53 |
| `wood.softwood` | **Softwood / Pine & Boreal** | `organic_botanical` | 510.0 | 2.5 | 1800.0 | `burley_diffuse_anisotropic` | `[0.45, 0.32, 0.20]` | 1.52 |
| `wood.birch` | **Birch** | `organic_botanical` | 670.0 | 3.0 | 2000.0 | `burley_diffuse_anisotropic` | `[0.85, 0.82, 0.75]` | 1.53 |
| `botanical.bamboo` | **Bamboo** | `organic_botanical` | 600.0 | 3.5 | 1500.0 | `dielectric_specular_coated_diffuse` | `[0.38, 0.62, 0.22]` | 1.51 |
| `botanical.foliage` | **Foliage / Plant Canopy** | `organic_botanical` | 250.0 | 0.5 | 200.0 | `two_sided_thin_surface_translucent` | `[0.24, 0.52, 0.18]` | 1.42 |
| `organic.bone` | **Bone / Osseous Tissue** | `organic_botanical` | 1900.0 | 4.0 | 4000.0 | `subsurface_scattering_dielectric` | `[0.88, 0.86, 0.78]` | 1.55 |
| `organic.fiber` | **Silk / Fibers / Webbing** | `organic_botanical` | 1300.0 | 1.0 | 400.0 | `microfiber_sheen` | `[0.88, 0.88, 0.88]` | 1.54 |
| `fluid.water` | **Water** | `fluid_multiphase` | 1000.0 | 0.0 | 50000.0 | `dielectric_refractive_volume` | `[0.82, 0.90, 0.95]` | 1.333 |
| `fluid.lava` | **Lava / Magma** | `fluid_multiphase` | 2800.0 | 0.0 | 40000.0 | `emissive_blackbody_fluid` | `[1.00, 0.40, 0.05]` | 1.52 |
| `fluid.honey` | **Honey** | `fluid_multiphase` | 1420.0 | 0.0 | 2000.0 | `dielectric_refractive_volume` | `[0.95, 0.68, 0.15]` | 1.49 |
| `synthetic.glass` | **Glass** | `synthetic_masonry` | 2500.0 | 5.5 | 1500.0 | `dielectric_specular` | `[0.95, 0.98, 0.99]` | 1.52 |
| `synthetic.brick` | **Brick / Fired Ceramic** | `synthetic_masonry` | 1900.0 | 5.0 | 6000.0 | `burley_diffuse` | `[0.65, 0.28, 0.20]` | 1.53 |
| `synthetic.concrete` | **Concrete / Mortar** | `synthetic_masonry` | 2400.0 | 6.0 | 9000.0 | `burley_diffuse` | `[0.65, 0.65, 0.65]` | 1.54 |
| `synthetic.terracotta` | **Terracotta / Hardened Clay** | `synthetic_masonry` | 2000.0 | 4.5 | 5000.0 | `burley_diffuse` | `[0.72, 0.44, 0.32]` | 1.52 |
| `synthetic.asphalt` | **Asphalt / Bitumen Roadway** | `synthetic_masonry` | 2300.0 | 3.0 | 4500.0 | `burley_diffuse` | `[0.18, 0.18, 0.18]` | 1.53 |
| `cryo.ice` | **Ice / Glacial Ice** | `cryogenic_volatile` | 917.0 | 1.5 | 600.0 | `dielectric_specular` | `[0.85, 0.92, 0.98]` | 1.31 |
| `cryo.packed_ice` | **Compacted Glacial Firn / Packed Ice** | `cryogenic_volatile` | 900.0 | 2.0 | 1200.0 | `subsurface_scattering_dielectric` | `[0.78, 0.88, 0.96]` | 1.315 |
| `cryo.blue_ice` | **High-Density Blue Glacial Ice** | `cryogenic_volatile` | 917.0 | 2.5 | 1800.0 | `subsurface_scattering_dielectric` | `[0.55, 0.75, 0.98]` | 1.32 |
| `cryo.snow` | **Consolidated Snow Pack** | `cryogenic_volatile` | 350.0 | 0.5 | 250.0 | `burley_diffuse` | `[0.98, 0.98, 0.98]` | 1.3 |
| `cryo.powder_snow` | **Unconsolidated Powder Snow** | `cryogenic_volatile` | 100.0 | 0.1 | 50.0 | `burley_diffuse` | `[0.99, 0.99, 1.00]` | 1.25 |
| `cryo.permafrost` | **Frozen Lithic Cryosol / Permafrost** | `cryogenic_volatile` | 1950.0 | 4.5 | 4500.0 | `burley_diffuse` | `[0.45, 0.42, 0.40]` | 1.48 |
| `rock.limestone` | **Limestone / Carbonate Rock** | `geological_lithic` | 2550.0 | 3.0 | 4500.0 | `burley_diffuse` | `[0.78, 0.74, 0.68]` | 1.57 |
| `rock.calcite` | **Calcite Crystalline Carbonate** | `geological_lithic` | 2710.0 | 3.0 | 4000.0 | `subsurface_scattering_dielectric` | `[0.92, 0.90, 0.88]` | 1.658 |
| `rock.tuff` | **Volcanic Tuff** | `geological_lithic` | 2100.0 | 4.5 | 5000.0 | `burley_diffuse` | `[0.42, 0.40, 0.38]` | 1.52 |
| `rock.pumice` | **Vesicular Pumice** | `geological_lithic` | 650.0 | 5.5 | 2500.0 | `burley_diffuse` | `[0.70, 0.68, 0.64]` | 1.5 |
| `soil.peat` | **Peat / Organic Turf** | `geological_soil` | 1100.0 | 1.0 | 400.0 | `burley_diffuse` | `[0.24, 0.16, 0.10]` | 1.46 |
| `soil.podzol` | **Podzol / Forest Humus Soil** | `geological_soil` | 1350.0 | 1.5 | 500.0 | `burley_diffuse` | `[0.30, 0.22, 0.16]` | 1.48 |
| `mineral.salt` | **Halite / Rock Salt** | `mineral_silicate` | 2160.0 | 2.5 | 2500.0 | `dielectric_specular` | `[0.96, 0.96, 0.97]` | 1.544 |
| `mineral.sulfur` | **Sulfur / Brimstone** | `mineral_silicate` | 2070.0 | 2.0 | 2000.0 | `burley_diffuse` | `[0.92, 0.82, 0.15]` | 1.95 |
| `mineral.gypsum` | **Gypsum / Hydrous Calcium Sulfate** | `mineral_silicate` | 2310.0 | 2.0 | 2200.0 | `burley_diffuse` | `[0.90, 0.88, 0.86]` | 1.52 |
| `mineral.ash` | **Combustion / Volcanic Ash** | `mineral_silicate` | 750.0 | 1.0 | 150.0 | `burley_diffuse` | `[0.35, 0.35, 0.35]` | 1.5 |
| `ore.iron_ore` | **Banded Iron Formation / Hematite Ore** | `ore_and_metal` | 4800.0 | 5.5 | 7500.0 | `burley_diffuse` | `[0.45, 0.35, 0.32]` | 2.2 |
| `ore.copper_ore` | **Copper Ore / Malachite-Quartz Matrix** | `ore_and_metal` | 4100.0 | 4.0 | 6500.0 | `burley_diffuse` | `[0.32, 0.55, 0.48]` | 1.85 |
| `ore.bauxite` | **Bauxite / Aluminum Hydroxide Ore** | `ore_and_metal` | 2450.0 | 2.5 | 4000.0 | `burley_diffuse` | `[0.72, 0.48, 0.36]` | 1.6 |
| `ore.gold_ore` | **Native Gold Quartz Matrix** | `ore_and_metal` | 3200.0 | 6.5 | 7000.0 | `burley_diffuse` | `[0.65, 0.62, 0.52]` | 1.58 |
| `metal.bronze` | **Bronze Alloy (Cu0.88Sn0.12)** | `ore_and_metal` | 8800.0 | 4.0 | 10000.0 | `conductor_fresnel_ggx` | `[0.90, 0.68, 0.42]` | 0.55 |
| `metal.brass` | **Brass Alloy (Cu0.70Zn0.30)** | `ore_and_metal` | 8500.0 | 3.5 | 9500.0 | `conductor_fresnel_ggx` | `[0.95, 0.78, 0.35]` | 0.42 |
| `metal.aluminum` | **Aluminum / Pure Light Metal** | `ore_and_metal` | 2700.0 | 2.75 | 9000.0 | `conductor_fresnel_ggx` | `[0.91, 0.92, 0.92]` | 1.44 |
| `metal.titanium` | **Titanium / Refractory Transition Metal** | `ore_and_metal` | 4506.0 | 6.0 | 14000.0 | `conductor_fresnel_ggx` | `[0.76, 0.73, 0.69]` | 2.7 |
| `metal.zinc` | **Zinc / Galvanic Metal** | `ore_and_metal` | 7140.0 | 2.5 | 7500.0 | `conductor_fresnel_ggx` | `[0.82, 0.84, 0.86]` | 1.9 |
| `metal.tungsten` | **Tungsten / Heavy Wolfram** | `ore_and_metal` | 19300.0 | 7.5 | 16000.0 | `conductor_fresnel_ggx` | `[0.72, 0.74, 0.76]` | 3.4 |
| `gem.lapis_lazuli` | **Lazurite / Ultramarine Silicate** | `gemstone_silicate` | 2800.0 | 5.5 | 4500.0 | `burley_diffuse` | `[0.08, 0.16, 0.58]` | 1.5 |
| `gem.topaz` | **Topaz / Aluminum Fluorosilicate** | `gemstone_silicate` | 3530.0 | 8.0 | 8000.0 | `dielectric_specular` | `[0.98, 0.82, 0.28]` | 1.62 |
| `gem.jade` | **Jade / Nephrite & Jadeite Aggregate** | `gemstone_silicate` | 3300.0 | 6.5 | 11000.0 | `subsurface_scattering_dielectric` | `[0.22, 0.65, 0.42]` | 1.66 |
| `gem.amber` | **Amber / Fossilized Tree Resin** | `gemstone_silicate` | 1080.0 | 2.2 | 800.0 | `dielectric_specular` | `[0.96, 0.62, 0.12]` | 1.54 |
| `mineral.phosphor` | **Phosphorescent / Luminescent Crystal** | `gemstone_silicate` | 2600.0 | 4.5 | 3000.0 | `emissive_blackbody_fluid` | `[0.95, 0.90, 0.45]` | 1.65 |
| `organic.leather` | **Tanned Leather / Animal Dermis** | `organic_botanical` | 850.0 | 1.5 | 1200.0 | `burley_diffuse` | `[0.42, 0.26, 0.16]` | 1.5 |
| `organic.chitin` | **Chitin / Arthropod Exoskeleton** | `organic_botanical` | 1400.0 | 3.5 | 3500.0 | `dielectric_specular_coated_diffuse` | `[0.28, 0.22, 0.18]` | 1.56 |
| `organic.rubber` | **Natural Rubber / Polyisoprene Elastomer** | `organic_botanical` | 950.0 | 1.0 | 2500.0 | `burley_diffuse` | `[0.15, 0.15, 0.15]` | 1.52 |
| `organic.wax` | **Hydrocarbon Wax / Beeswax & Tallow** | `organic_botanical` | 960.0 | 0.5 | 300.0 | `subsurface_scattering_dielectric` | `[0.92, 0.82, 0.55]` | 1.44 |
| `wood.charcoal` | **Pyrolyzed Biomass Carbon / Charcoal** | `organic_botanical` | 450.0 | 2.0 | 1000.0 | `burley_diffuse` | `[0.05, 0.05, 0.05]` | 1.75 |
| `botanical.moss` | **Bryophyte Ground Mat / Moss** | `organic_botanical` | 400.0 | 0.5 | 300.0 | `burley_diffuse` | `[0.28, 0.48, 0.18]` | 1.45 |
| `botanical.mycelium` | **Fungal Hyphal Matrix / Mycelium** | `organic_botanical` | 1250.0 | 1.0 | 450.0 | `burley_diffuse` | `[0.45, 0.38, 0.42]` | 1.48 |
| `botanical.cactus` | **Xerophyte Cactus Stem** | `organic_botanical` | 850.0 | 2.0 | 500.0 | `dielectric_specular_coated_diffuse` | `[0.22, 0.52, 0.18]` | 1.5 |
| `fluid.oil` | **Crude Petroleum / Liquid Hydrocarbon** | `fluid_multiphase` | 850.0 | 0.0 | 10000.0 | `dielectric_specular_coated_diffuse` | `[0.05, 0.04, 0.03]` | 1.48 |
| `fluid.acid` | **Mineral Acid / Corrosive Hydronium Solution** | `fluid_multiphase` | 1250.0 | 0.0 | 20000.0 | `dielectric_refractive_volume` | `[0.45, 0.95, 0.25]` | 1.38 |
| `gas.steam` | **Water Vapor / Steam** | `fluid_multiphase` | 0.6 | 0.0 | 100000.0 | `two_sided_thin_surface_translucent` | `[0.95, 0.95, 0.98]` | 1.00028 |
| `gas.air` | **Ambient Atmospheric Gas** | `fluid_multiphase` | 1.225 | 0.0 | 100000.0 | `dielectric_refractive_volume` | `[1.00, 1.00, 1.00]` | 1.000293 |
| `gas.smoke` | **Particulate Combustion Aerosol** | `fluid_multiphase` | 0.95 | 0.0 | 100000.0 | `burley_diffuse` | `[0.18, 0.18, 0.18]` | 1.0003 |
| `gas.methane` | **Volatile Methane / Natural Gas** | `fluid_multiphase` | 0.668 | 0.0 | 100000.0 | `dielectric_refractive_volume` | `[0.98, 0.98, 1.00]` | 1.00044 |
| `granular.concrete_powder` | **Dry Concrete Precursor Powder** | `synthetic_masonry` | 1600.0 | 1.5 | 400.0 | `burley_diffuse` | `[0.62, 0.62, 0.62]` | 1.53 |
| `synthetic.mortar` | **Hydraulic Masonry Mortar** | `synthetic_masonry` | 2000.0 | 4.5 | 5000.0 | `burley_diffuse` | `[0.72, 0.70, 0.66]` | 1.53 |
| `synthetic.aerogel` | **Silica Aerogel / Solid Smoke** | `synthetic_masonry` | 100.0 | 1.0 | 300.0 | `subsurface_scattering_dielectric` | `[0.75, 0.88, 0.98]` | 1.02 |
| `synthetic.plastic` | **Thermoplastic Polymer / Polycarbonate** | `synthetic_masonry` | 1200.0 | 3.0 | 3000.0 | `dielectric_specular_coated_diffuse` | `[0.85, 0.85, 0.85]` | 1.58 |
| `synthetic.silicon` | **Elemental Silicon / Polycrystalline Wafer** | `synthetic_masonry` | 2330.0 | 6.5 | 6000.0 | `conductor_fresnel_ggx` | `[0.55, 0.62, 0.68]` | 3.88 |
| `synthetic.explosive` | **Chemical High Explosive (TNT / Energetic Solid)** | `synthetic_masonry` | 1650.0 | 1.5 | 50.0 | `burley_diffuse` | `[0.78, 0.22, 0.15]` | 1.55 |

---

## 3. Normative Semantics by Category


### 1. Geological Soils & Unconsolidated Media
#### `soil.dirt` — Dirt / Loam
* **Description:** Unconsolidated organic-mineral soil aggregate with moisture retention.
* **Archetypal Provenance:** Minecraft (Dirt), Terraria (Dirt Block), Universal Sandbox/CAD

**Physical Constitutive Parameters:**
- Density ($ho$): `1450.0 kg/m^3`
- Mohs Hardness: `1.5`
- Young's Modulus ($E$): `0.05 GPa` | Poisson's Ratio ($
u$): `0.35`
- Coulomb Friction ($\mu$): `0.65` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `500.0 J`
- Thermal Conductivity ($k$): `0.25 W/(m·K)` | Specific Heat ($c_p$): `800.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_OREN_NAYAR`)
- Base Albedo (Linear sRGB): `[0.34, 0.23, 0.15]`
- Microfacet Roughness ($lpha$): `0.92` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.45` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `soil.mud` — Mud
* **Description:** Water-saturated cohesive clay-silt matrix with low shear strength.
* **Archetypal Provenance:** Minecraft (Mud), Terraria (Mud Block), Universal Hydrology/Soil

**Physical Constitutive Parameters:**
- Density ($ho$): `1750.0 kg/m^3`
- Mohs Hardness: `1.0`
- Young's Modulus ($E$): `0.01 GPa` | Poisson's Ratio ($
u$): `0.45`
- Coulomb Friction ($\mu$): `0.3` | Restitution ($e$): `0.01`
- Blast Fracture Threshold: `400.0 J`
- Thermal Conductivity ($k$): `0.6 W/(m·K)` | Specific Heat ($c_p$): `1800.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular_coated_diffuse` (Closure: `BSDF_COATED_DIFFUSE`)
- Base Albedo (Linear sRGB): `[0.22, 0.18, 0.14]`
- Microfacet Roughness ($lpha$): `0.35` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.34` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `water_sheen_over_soil`

---
#### `soil.clay` — Clay
* **Description:** Hydrous aluminium phyllosilicate mineral aggregate with plastic deformation when wet.
* **Archetypal Provenance:** Minecraft (Clay), Terraria (Clay Block), Universal Ceramic/Sediment

**Physical Constitutive Parameters:**
- Density ($ho$): `1600.0 kg/m^3`
- Mohs Hardness: `2.0`
- Young's Modulus ($E$): `0.1 GPa` | Poisson's Ratio ($
u$): `0.4`
- Coulomb Friction ($\mu$): `0.55` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `600.0 J`
- Thermal Conductivity ($k$): `0.45 W/(m·K)` | Specific Heat ($c_p$): `920.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.62, 0.65, 0.70]`
- Microfacet Roughness ($lpha$): `0.85` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.52` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `soil.sand` — Sand
* **Description:** Granular aggregate of weathered quartz particles subject to angle of repose and kinematic collapse.
* **Archetypal Provenance:** Minecraft (Sand), Terraria (Sand Block), Universal Granular Physics

**Physical Constitutive Parameters:**
- Density ($ho$): `1600.0 kg/m^3`
- Mohs Hardness: `2.5`
- Young's Modulus ($E$): `0.08 GPa` | Poisson's Ratio ($
u$): `0.3`
- Coulomb Friction ($\mu$): `0.55` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `500.0 J`
- Thermal Conductivity ($k$): `0.27 W/(m·K)` | Specific Heat ($c_p$): `830.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `True` | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_DISCRETE_GRANULAR`)
- Base Albedo (Linear sRGB): `[0.86, 0.78, 0.56]`
- Microfacet Roughness ($lpha$): `0.95` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.54` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `soil.gravel` — Gravel
* **Description:** Unconsolidated rock fragments and pebbles exhibiting kinematic gravity and high permeability.
* **Archetypal Provenance:** Minecraft (Gravel), Terraria (Gravel), Universal Civil/Sediment

**Physical Constitutive Parameters:**
- Density ($ho$): `1800.0 kg/m^3`
- Mohs Hardness: `3.5`
- Young's Modulus ($E$): `0.15 GPa` | Poisson's Ratio ($
u$): `0.28`
- Coulomb Friction ($\mu$): `0.6` | Restitution ($e$): `0.15`
- Blast Fracture Threshold: `600.0 J`
- Thermal Conductivity ($k$): `0.38 W/(m·K)` | Specific Heat ($c_p$): `840.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `True` | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_DISCRETE_GRANULAR`)
- Base Albedo (Linear sRGB): `[0.55, 0.53, 0.52]`
- Microfacet Roughness ($lpha$): `0.9` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.53` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `soil.peat` — Peat / Organic Turf
* **Description:** Partially decayed accumulation of vegetable matter and sphagnum moss; natural carbonaceous fuel precursor.
* **Archetypal Provenance:** Universal Fuel/Wetland Geology

**Physical Constitutive Parameters:**
- Density ($ho$): `1100.0 kg/m^3`
- Mohs Hardness: `1.0`
- Young's Modulus ($E$): `0.02 GPa` | Poisson's Ratio ($
u$): `0.38`
- Coulomb Friction ($\mu$): `0.7` | Restitution ($e$): `0.02`
- Blast Fracture Threshold: `400.0 J`
- Thermal Conductivity ($k$): `0.22 W/(m·K)` | Specific Heat ($c_p$): `1800.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `shovel`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.24, 0.16, 0.10]`
- Microfacet Roughness ($lpha$): `0.95` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.46` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `soil.podzol` — Podzol / Forest Humus Soil
* **Description:** Highly leached boreal soil characterized by a bleached eluvial horizon beneath organic humus.
* **Archetypal Provenance:** Minecraft (Podzol), Universal Soil Pedology

**Physical Constitutive Parameters:**
- Density ($ho$): `1350.0 kg/m^3`
- Mohs Hardness: `1.5`
- Young's Modulus ($E$): `0.04 GPa` | Poisson's Ratio ($
u$): `0.35`
- Coulomb Friction ($\mu$): `0.65` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `500.0 J`
- Thermal Conductivity ($k$): `0.28 W/(m·K)` | Specific Heat ($c_p$): `950.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.30, 0.22, 0.16]`
- Microfacet Roughness ($lpha$): `0.9` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.48` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 2. Geological Lithics & Hard Rock
#### `rock.stone` — Stone / Natural Rock
* **Description:** Intact silicate/carbonate continental crust with compressive strength and brittle fracture.
* **Archetypal Provenance:** Minecraft (Stone), Terraria (Stone Block), Universal Geological/CAD

**Physical Constitutive Parameters:**
- Density ($ho$): `2650.0 kg/m^3`
- Mohs Hardness: `5.5`
- Young's Modulus ($E$): `50.0 GPa` | Poisson's Ratio ($
u$): `0.22`
- Coulomb Friction ($\mu$): `0.7` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `6000.0 J`
- Thermal Conductivity ($k$): `2.2 W/(m·K)` | Specific Heat ($c_p$): `790.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.50, 0.50, 0.50]`
- Microfacet Roughness ($lpha$): `0.8` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.54` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `rock.cobblestone` — Cobblestone / Fractured Lithic
* **Description:** Quarried and fractured aggregate stone assembled with frictional interlocking.
* **Archetypal Provenance:** Minecraft (Cobblestone), Terraria (Cobblestone), Universal Architectural

**Physical Constitutive Parameters:**
- Density ($ho$): `2400.0 kg/m^3`
- Mohs Hardness: `5.0`
- Young's Modulus ($E$): `35.0 GPa` | Poisson's Ratio ($
u$): `0.25`
- Coulomb Friction ($\mu$): `0.75` | Restitution ($e$): `0.15`
- Blast Fracture Threshold: `5500.0 J`
- Thermal Conductivity ($k$): `1.8 W/(m·K)` | Specific Heat ($c_p$): `800.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse_with_displacement` (Closure: `BSDF_MICROFACET_ROUGH`)
- Base Albedo (Linear sRGB): `[0.42, 0.42, 0.42]`
- Microfacet Roughness ($lpha$): `0.88` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.53` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `diffuse_plus_mortar_edges`

---
#### `rock.granite` — Granite
* **Description:** Felsic coarse-grained intrusive igneous rock containing quartz and feldspar.
* **Archetypal Provenance:** Minecraft (Granite), Terraria (Granite Block), Universal Lithic/Engineering

**Physical Constitutive Parameters:**
- Density ($ho$): `2700.0 kg/m^3`
- Mohs Hardness: `6.0`
- Young's Modulus ($E$): `60.0 GPa` | Poisson's Ratio ($
u$): `0.2`
- Coulomb Friction ($\mu$): `0.7` | Restitution ($e$): `0.22`
- Blast Fracture Threshold: `6500.0 J`
- Thermal Conductivity ($k$): `2.8 W/(m·K)` | Specific Heat ($c_p$): `820.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.60, 0.42, 0.36]`
- Microfacet Roughness ($lpha$): `0.65` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.55` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `rock.diorite` — Diorite
* **Description:** Intermediate intrusive igneous rock dominated by plagioclase feldspar and hornblende.
* **Archetypal Provenance:** Minecraft (Diorite), Universal Lithic/Geological

**Physical Constitutive Parameters:**
- Density ($ho$): `2850.0 kg/m^3`
- Mohs Hardness: `6.0`
- Young's Modulus ($E$): `65.0 GPa` | Poisson's Ratio ($
u$): `0.22`
- Coulomb Friction ($\mu$): `0.68` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `6500.0 J`
- Thermal Conductivity ($k$): `2.5 W/(m·K)` | Specific Heat ($c_p$): `810.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.72, 0.72, 0.72]`
- Microfacet Roughness ($lpha$): `0.7` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.55` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `rock.andesite` — Andesite
* **Description:** Extrusive volcanic intermediate rock with fine-grained crystalline groundmass.
* **Archetypal Provenance:** Minecraft (Andesite), Universal Lithic/Geological

**Physical Constitutive Parameters:**
- Density ($ho$): `2600.0 kg/m^3`
- Mohs Hardness: `5.5`
- Young's Modulus ($E$): `45.0 GPa` | Poisson's Ratio ($
u$): `0.23`
- Coulomb Friction ($\mu$): `0.68` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `6000.0 J`
- Thermal Conductivity ($k$): `2.1 W/(m·K)` | Specific Heat ($c_p$): `820.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.52, 0.52, 0.52]`
- Microfacet Roughness ($lpha$): `0.78` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.54` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `rock.basalt` — Basalt
* **Description:** Aphanitic mafic volcanic rock forming columnar joints with high compressive strength.
* **Archetypal Provenance:** Minecraft (Basalt), Terraria (Basalt / Underworld Lithic), Universal Volcanology

**Physical Constitutive Parameters:**
- Density ($ho$): `2900.0 kg/m^3`
- Mohs Hardness: `6.0`
- Young's Modulus ($E$): `70.0 GPa` | Poisson's Ratio ($
u$): `0.23`
- Coulomb Friction ($\mu$): `0.72` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `7000.0 J`
- Thermal Conductivity ($k$): `2.0 W/(m·K)` | Specific Heat ($c_p$): `840.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.25, 0.25, 0.27]`
- Microfacet Roughness ($lpha$): `0.75` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.58` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `rock.obsidian` — Obsidian
* **Description:** Extrusive volcanic glass formed by rapid quenching of felsic lava; extremely high blast resistance.
* **Archetypal Provenance:** Minecraft (Obsidian), Terraria (Obsidian), Universal Geological/Volcanology

**Physical Constitutive Parameters:**
- Density ($ho$): `2600.0 kg/m^3`
- Mohs Hardness: `7.0`
- Young's Modulus ($E$): `80.0 GPa` | Poisson's Ratio ($
u$): `0.18`
- Coulomb Friction ($\mu$): `0.5` | Restitution ($e$): `0.4`
- Blast Fracture Threshold: `12000.0 J`
- Thermal Conductivity ($k$): `1.3 W/(m·K)` | Specific Heat ($c_p$): `820.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `diamond_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_MICROFACET`)
- Base Albedo (Linear sRGB): `[0.08, 0.06, 0.12]`
- Microfacet Roughness ($lpha$): `0.12` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.5` | Transmittance ($	au$): `0.02`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `glossy_dielectric`

---
#### `rock.sandstone` — Sandstone
* **Description:** Sedimentary clastic rock composed of mineral particles and cemented silica grains.
* **Archetypal Provenance:** Minecraft (Sandstone), Terraria (Sandstone Block), Universal Architectural/Geology

**Physical Constitutive Parameters:**
- Density ($ho$): `2200.0 kg/m^3`
- Mohs Hardness: `4.5`
- Young's Modulus ($E$): `25.0 GPa` | Poisson's Ratio ($
u$): `0.26`
- Coulomb Friction ($\mu$): `0.65` | Restitution ($e$): `0.15`
- Blast Fracture Threshold: `4000.0 J`
- Thermal Conductivity ($k$): `1.7 W/(m·K)` | Specific Heat ($c_p$): `920.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.82, 0.74, 0.52]`
- Microfacet Roughness ($lpha$): `0.85` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.52` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `rock.marble` — Marble
* **Description:** Metamorphosed recrystallized carbonate rock with fine polish and subsurface light scattering.
* **Archetypal Provenance:** Terraria (Marble Block), Minecraft (Calcite/Quartz Lithic), Universal Architectural/Statuary

**Physical Constitutive Parameters:**
- Density ($ho$): `2700.0 kg/m^3`
- Mohs Hardness: `4.0`
- Young's Modulus ($E$): `55.0 GPa` | Poisson's Ratio ($
u$): `0.28`
- Coulomb Friction ($\mu$): `0.55` | Restitution ($e$): `0.25`
- Blast Fracture Threshold: `5000.0 J`
- Thermal Conductivity ($k$): `2.8 W/(m·K)` | Specific Heat ($c_p$): `880.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `subsurface_scattering_dielectric` (Closure: `BSDF_BSSRDF_DIPOLE`)
- Base Albedo (Linear sRGB): `[0.92, 0.92, 0.90]`
- Microfacet Roughness ($lpha$): `0.3` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.53` | Transmittance ($	au$): `0.15`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `subsurface_dielectric`

---
#### `rock.slate` — Slate / Deepslate
* **Description:** Fine-grained foliated metamorphic rock characterized by high density and planar cleavage.
* **Archetypal Provenance:** Minecraft (Deepslate), Terraria (Slate/Shale), Universal Metamorphic Geology

**Physical Constitutive Parameters:**
- Density ($ho$): `2800.0 kg/m^3`
- Mohs Hardness: `6.0`
- Young's Modulus ($E$): `65.0 GPa` | Poisson's Ratio ($
u$): `0.21`
- Coulomb Friction ($\mu$): `0.7` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `7500.0 J`
- Thermal Conductivity ($k$): `2.0 W/(m·K)` | Specific Heat ($c_p$): `760.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.28, 0.28, 0.30]`
- Microfacet Roughness ($lpha$): `0.72` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.55` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `rock.limestone` — Limestone / Carbonate Rock
* **Description:** Sedimentary carbonate rock composed largely of calcite and aragonite; precursor to quicklime and cement.
* **Archetypal Provenance:** Universal Civil/Geological Engineering

**Physical Constitutive Parameters:**
- Density ($ho$): `2550.0 kg/m^3`
- Mohs Hardness: `3.0`
- Young's Modulus ($E$): `45.0 GPa` | Poisson's Ratio ($
u$): `0.28`
- Coulomb Friction ($\mu$): `0.65` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `4500.0 J`
- Thermal Conductivity ($k$): `2.0 W/(m·K)` | Specific Heat ($c_p$): `880.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.78, 0.74, 0.68]`
- Microfacet Roughness ($lpha$): `0.82` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.57` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `rock.calcite` — Calcite Crystalline Carbonate
* **Description:** Trigonal polymorph of calcium carbonate exhibiting strong optical birefringence and rhombohedral cleavage.
* **Archetypal Provenance:** Minecraft (Calcite), Universal Optical Crystallography

**Physical Constitutive Parameters:**
- Density ($ho$): `2710.0 kg/m^3`
- Mohs Hardness: `3.0`
- Young's Modulus ($E$): `60.0 GPa` | Poisson's Ratio ($
u$): `0.3`
- Coulomb Friction ($\mu$): `0.55` | Restitution ($e$): `0.35`
- Blast Fracture Threshold: `4000.0 J`
- Thermal Conductivity ($k$): `2.2 W/(m·K)` | Specific Heat ($c_p$): `850.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `subsurface_scattering_dielectric` (Closure: `BSDF_BSSRDF_DIPOLE`)
- Base Albedo (Linear sRGB): `[0.92, 0.90, 0.88]`
- Microfacet Roughness ($lpha$): `0.35` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.658` | Transmittance ($	au$): `0.1`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `subsurface_dielectric`

---
#### `rock.tuff` — Volcanic Tuff
* **Description:** Pyroclastic consolidated volcanic rock formed from consolidated ash, shards, and lithic fragments.
* **Archetypal Provenance:** Minecraft (Tuff), Universal Volcanic Masonry

**Physical Constitutive Parameters:**
- Density ($ho$): `2100.0 kg/m^3`
- Mohs Hardness: `4.5`
- Young's Modulus ($E$): `30.0 GPa` | Poisson's Ratio ($
u$): `0.25`
- Coulomb Friction ($\mu$): `0.7` | Restitution ($e$): `0.15`
- Blast Fracture Threshold: `5000.0 J`
- Thermal Conductivity ($k$): `1.5 W/(m·K)` | Specific Heat ($c_p$): `840.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.42, 0.40, 0.38]`
- Microfacet Roughness ($lpha$): `0.9` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.52` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `rock.pumice` — Vesicular Pumice
* **Description:** Highly porous vesicular volcanic glass with density lower than water, granting buoyant flotation.
* **Archetypal Provenance:** Universal Geophysics/Hydraulic Buoyancy

**Physical Constitutive Parameters:**
- Density ($ho$): `650.0 kg/m^3`
- Mohs Hardness: `5.5`
- Young's Modulus ($E$): `15.0 GPa` | Poisson's Ratio ($
u$): `0.18`
- Coulomb Friction ($\mu$): `0.85` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `2500.0 J`
- Thermal Conductivity ($k$): `0.35 W/(m·K)` | Specific Heat ($c_p$): `800.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.70, 0.68, 0.64]`
- Microfacet Roughness ($lpha$): `0.92` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.5` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 3. Ores, Native Metals & Alloys
#### `ore.coal` — Coal / Carbon Solid
* **Description:** Combustible black sedimentary rock composed primarily of carbon with associated hydrocarbons.
* **Archetypal Provenance:** Minecraft (Coal Ore), Terraria (Coal / Black Mineral), Universal Metallurgy/Energy

**Physical Constitutive Parameters:**
- Density ($ho$): `1350.0 kg/m^3`
- Mohs Hardness: `2.5`
- Young's Modulus ($E$): `4.0 GPa` | Poisson's Ratio ($
u$): `0.3`
- Coulomb Friction ($\mu$): `0.6` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `3000.0 J`
- Thermal Conductivity ($k$): `0.26 W/(m·K)` | Specific Heat ($c_p$): `1260.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.12, 0.12, 0.12]`
- Microfacet Roughness ($lpha$): `0.9` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.8` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `metal.iron` — Iron
* **Description:** High-tensile ferromagnetic transition metal forming foundational structural tools and armaments.
* **Archetypal Provenance:** Minecraft (Iron), Terraria (Iron), Universal Structural Metallurgy

**Physical Constitutive Parameters:**
- Density ($ho$): `7874.0 kg/m^3`
- Mohs Hardness: `4.5`
- Young's Modulus ($E$): `211.0 GPa` | Poisson's Ratio ($
u$): `0.29`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.45`
- Blast Fracture Threshold: `10000.0 J`
- Thermal Conductivity ($k$): `80.0 W/(m·K)` | Specific Heat ($c_p$): `450.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `stone_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.77, 0.78, 0.78]`
- Microfacet Roughness ($lpha$): `0.35` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `2.95` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---
#### `metal.copper` — Copper
* **Description:** Ductile, malleable metal with high thermal and electrical conductivity, prone to verdigris patina.
* **Archetypal Provenance:** Minecraft (Copper), Terraria (Copper), Universal Electrical/Engineering

**Physical Constitutive Parameters:**
- Density ($ho$): `8960.0 kg/m^3`
- Mohs Hardness: `3.0`
- Young's Modulus ($E$): `110.0 GPa` | Poisson's Ratio ($
u$): `0.34`
- Coulomb Friction ($\mu$): `0.35` | Restitution ($e$): `0.4`
- Blast Fracture Threshold: `9000.0 J`
- Thermal Conductivity ($k$): `401.0 W/(m·K)` | Specific Heat ($c_p$): `385.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `stone_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.95, 0.64, 0.54]`
- Microfacet Roughness ($lpha$): `0.25` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `0.27` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---
#### `metal.gold` — Gold
* **Description:** Noble transition metal with high density, resistance to corrosion, and intense yellow spectral reflectance.
* **Archetypal Provenance:** Minecraft (Gold), Terraria (Gold), Universal Precious Metals

**Physical Constitutive Parameters:**
- Density ($ho$): `19300.0 kg/m^3`
- Mohs Hardness: `2.5`
- Young's Modulus ($E$): `78.0 GPa` | Poisson's Ratio ($
u$): `0.44`
- Coulomb Friction ($\mu$): `0.3` | Restitution ($e$): `0.3`
- Blast Fracture Threshold: `8000.0 J`
- Thermal Conductivity ($k$): `314.0 W/(m·K)` | Specific Heat ($c_p$): `129.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `iron_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[1.00, 0.77, 0.34]`
- Microfacet Roughness ($lpha$): `0.18` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `0.18` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---
#### `metal.silver` — Silver
* **Description:** Precious metal exhibiting highest electrical and optical conductivity and highest reflectivity in visible spectrum.
* **Archetypal Provenance:** Terraria (Silver), Universal Precious Metals/Optics

**Physical Constitutive Parameters:**
- Density ($ho$): `10490.0 kg/m^3`
- Mohs Hardness: `2.5`
- Young's Modulus ($E$): `83.0 GPa` | Poisson's Ratio ($
u$): `0.37`
- Coulomb Friction ($\mu$): `0.35` | Restitution ($e$): `0.35`
- Blast Fracture Threshold: `8500.0 J`
- Thermal Conductivity ($k$): `429.0 W/(m·K)` | Specific Heat ($c_p$): `235.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `iron_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.97, 0.96, 0.95]`
- Microfacet Roughness ($lpha$): `0.12` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `0.14` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---
#### `metal.tin` — Tin
* **Description:** Malleable post-transition metal with low melting point, used to produce bronze alloys.
* **Archetypal Provenance:** Terraria (Tin), Universal Metallurgy/Bronze Age

**Physical Constitutive Parameters:**
- Density ($ho$): `7310.0 kg/m^3`
- Mohs Hardness: `1.5`
- Young's Modulus ($E$): `50.0 GPa` | Poisson's Ratio ($
u$): `0.36`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.25`
- Blast Fracture Threshold: `7000.0 J`
- Thermal Conductivity ($k$): `66.8 W/(m·K)` | Specific Heat ($c_p$): `228.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.85, 0.85, 0.84]`
- Microfacet Roughness ($lpha$): `0.3` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `1.8` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---
#### `metal.lead` — Lead
* **Description:** Dense, soft, corrosion-resistant heavy metal with radiation shielding and radiation damping capabilities.
* **Archetypal Provenance:** Terraria (Lead), Universal Metallurgy/Nuclear Shielding

**Physical Constitutive Parameters:**
- Density ($ho$): `11340.0 kg/m^3`
- Mohs Hardness: `1.5`
- Young's Modulus ($E$): `16.0 GPa` | Poisson's Ratio ($
u$): `0.44`
- Coulomb Friction ($\mu$): `0.45` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `8000.0 J`
- Thermal Conductivity ($k$): `35.3 W/(m·K)` | Specific Heat ($c_p$): `129.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.45, 0.46, 0.48]`
- Microfacet Roughness ($lpha$): `0.4` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `2.05` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---
#### `metal.platinum` — Platinum
* **Description:** Extremely dense, malleable noble metal with outstanding catalytic properties and corrosion immunity.
* **Archetypal Provenance:** Terraria (Platinum), Universal Metallurgy/Precious Metal

**Physical Constitutive Parameters:**
- Density ($ho$): `21450.0 kg/m^3`
- Mohs Hardness: `4.5`
- Young's Modulus ($E$): `168.0 GPa` | Poisson's Ratio ($
u$): `0.38`
- Coulomb Friction ($\mu$): `0.35` | Restitution ($e$): `0.35`
- Blast Fracture Threshold: `11000.0 J`
- Thermal Conductivity ($k$): `71.6 W/(m·K)` | Specific Heat ($c_p$): `133.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.82, 0.84, 0.86]`
- Microfacet Roughness ($lpha$): `0.15` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `2.3` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---
#### `metal.steel` — Steel / Refined Ferrous Alloy
* **Description:** Alloy of iron and carbon providing maximum structural tensile strength and fatigue resistance.
* **Archetypal Provenance:** Minecraft (Industrial/Modded), Terraria (Late Pre-Hardmode), Universal Structural Engineering

**Physical Constitutive Parameters:**
- Density ($ho$): `7850.0 kg/m^3`
- Mohs Hardness: `6.5`
- Young's Modulus ($E$): `200.0 GPa` | Poisson's Ratio ($
u$): `0.3`
- Coulomb Friction ($\mu$): `0.38` | Restitution ($e$): `0.5`
- Blast Fracture Threshold: `12000.0 J`
- Thermal Conductivity ($k$): `50.0 W/(m·K)` | Specific Heat ($c_p$): `490.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.75, 0.77, 0.80]`
- Microfacet Roughness ($lpha$): `0.2` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `2.8` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---
#### `ore.iron_ore` — Banded Iron Formation / Hematite Ore
* **Description:** Sedimentary rock matrix containing high concentrations of hematite and magnetite oxides.
* **Archetypal Provenance:** Minecraft (Iron Ore), Terraria (Iron Ore), Universal Metallurgy

**Physical Constitutive Parameters:**
- Density ($ho$): `4800.0 kg/m^3`
- Mohs Hardness: `5.5`
- Young's Modulus ($E$): `110.0 GPa` | Poisson's Ratio ($
u$): `0.26`
- Coulomb Friction ($\mu$): `0.65` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `7500.0 J`
- Thermal Conductivity ($k$): `4.5 W/(m·K)` | Specific Heat ($c_p$): `650.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `stone_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.45, 0.35, 0.32]`
- Microfacet Roughness ($lpha$): `0.8` | Metallic Fraction ($m$): `0.1`
- Index of Refraction ($n$): `2.2` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `ore.copper_ore` — Copper Ore / Malachite-Quartz Matrix
* **Description:** Mineral aggregate containing copper sulfides and carbonates embedded in silicate host rock.
* **Archetypal Provenance:** Minecraft (Copper Ore), Terraria (Copper Ore), Universal Metallurgy

**Physical Constitutive Parameters:**
- Density ($ho$): `4100.0 kg/m^3`
- Mohs Hardness: `4.0`
- Young's Modulus ($E$): `85.0 GPa` | Poisson's Ratio ($
u$): `0.28`
- Coulomb Friction ($\mu$): `0.6` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `6500.0 J`
- Thermal Conductivity ($k$): `6.0 W/(m·K)` | Specific Heat ($c_p$): `600.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `stone_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.32, 0.55, 0.48]`
- Microfacet Roughness ($lpha$): `0.75` | Metallic Fraction ($m$): `0.1`
- Index of Refraction ($n$): `1.85` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `ore.bauxite` — Bauxite / Aluminum Hydroxide Ore
* **Description:** Sedimentary rock with high aluminum content consisting mostly of gibbsite, boehmite, and diaspore.
* **Archetypal Provenance:** Universal Industrial Metallurgy/CAD

**Physical Constitutive Parameters:**
- Density ($ho$): `2450.0 kg/m^3`
- Mohs Hardness: `2.5`
- Young's Modulus ($E$): `40.0 GPa` | Poisson's Ratio ($
u$): `0.3`
- Coulomb Friction ($\mu$): `0.6` | Restitution ($e$): `0.15`
- Blast Fracture Threshold: `4000.0 J`
- Thermal Conductivity ($k$): `1.2 W/(m·K)` | Specific Heat ($c_p$): `900.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.72, 0.48, 0.36]`
- Microfacet Roughness ($lpha$): `0.9` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.6` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `ore.gold_ore` — Native Gold Quartz Matrix
* **Description:** Hydrothermal vein quartz hosting micro- and macroscopic inclusions of native elemental gold.
* **Archetypal Provenance:** Minecraft (Gold Ore), Terraria (Gold Ore), Universal Precious Geology

**Physical Constitutive Parameters:**
- Density ($ho$): `3200.0 kg/m^3`
- Mohs Hardness: `6.5`
- Young's Modulus ($E$): `85.0 GPa` | Poisson's Ratio ($
u$): `0.2`
- Coulomb Friction ($\mu$): `0.55` | Restitution ($e$): `0.3`
- Blast Fracture Threshold: `7000.0 J`
- Thermal Conductivity ($k$): `3.5 W/(m·K)` | Specific Heat ($c_p$): `700.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `iron_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.65, 0.62, 0.52]`
- Microfacet Roughness ($lpha$): `0.65` | Metallic Fraction ($m$): `0.15`
- Index of Refraction ($n$): `1.58` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `metal.bronze` — Bronze Alloy (Cu0.88Sn0.12)
* **Description:** Classical structural alloy of copper and tin offering superior hardness and corrosion resistance.
* **Archetypal Provenance:** Universal Historical Metallurgy/CAD

**Physical Constitutive Parameters:**
- Density ($ho$): `8800.0 kg/m^3`
- Mohs Hardness: `4.0`
- Young's Modulus ($E$): `115.0 GPa` | Poisson's Ratio ($
u$): `0.34`
- Coulomb Friction ($\mu$): `0.36` | Restitution ($e$): `0.45`
- Blast Fracture Threshold: `10000.0 J`
- Thermal Conductivity ($k$): `60.0 W/(m·K)` | Specific Heat ($c_p$): `380.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.90, 0.68, 0.42]`
- Microfacet Roughness ($lpha$): `0.22` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `0.55` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---
#### `metal.brass` — Brass Alloy (Cu0.70Zn0.30)
* **Description:** Malleable acoustic copper-zinc alloy characterized by low friction against other metals and bright golden luster.
* **Archetypal Provenance:** Universal Instrument/Machine Tool Metallurgy

**Physical Constitutive Parameters:**
- Density ($ho$): `8500.0 kg/m^3`
- Mohs Hardness: `3.5`
- Young's Modulus ($E$): `105.0 GPa` | Poisson's Ratio ($
u$): `0.35`
- Coulomb Friction ($\mu$): `0.32` | Restitution ($e$): `0.48`
- Blast Fracture Threshold: `9500.0 J`
- Thermal Conductivity ($k$): `115.0 W/(m·K)` | Specific Heat ($c_p$): `380.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.95, 0.78, 0.35]`
- Microfacet Roughness ($lpha$): `0.18` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `0.42` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---
#### `metal.aluminum` — Aluminum / Pure Light Metal
* **Description:** Low-density post-transition metal with high specific strength and self-passivating alumina oxide layer.
* **Archetypal Provenance:** Universal Modern Aerospace/CAD

**Physical Constitutive Parameters:**
- Density ($ho$): `2700.0 kg/m^3`
- Mohs Hardness: `2.75`
- Young's Modulus ($E$): `70.0 GPa` | Poisson's Ratio ($
u$): `0.35`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.55`
- Blast Fracture Threshold: `9000.0 J`
- Thermal Conductivity ($k$): `237.0 W/(m·K)` | Specific Heat ($c_p$): `900.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.91, 0.92, 0.92]`
- Microfacet Roughness ($lpha$): `0.16` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `1.44` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---
#### `metal.titanium` — Titanium / Refractory Transition Metal
* **Description:** Lustrous transition metal with low density, extreme tensile strength, and high corrosion resistance.
* **Archetypal Provenance:** Terraria (Titanium), Universal Extreme Engineering

**Physical Constitutive Parameters:**
- Density ($ho$): `4506.0 kg/m^3`
- Mohs Hardness: `6.0`
- Young's Modulus ($E$): `116.0 GPa` | Poisson's Ratio ($
u$): `0.32`
- Coulomb Friction ($\mu$): `0.36` | Restitution ($e$): `0.6`
- Blast Fracture Threshold: `14000.0 J`
- Thermal Conductivity ($k$): `21.9 W/(m·K)` | Specific Heat ($c_p$): `523.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `diamond_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.76, 0.73, 0.69]`
- Microfacet Roughness ($lpha$): `0.22` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `2.7` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---
#### `metal.zinc` — Zinc / Galvanic Metal
* **Description:** Diamagnetic metal with sacrificial anode galvanic properties and moderate melting point (692.68 K).
* **Archetypal Provenance:** Universal Industrial Metallurgy/Chemistry

**Physical Constitutive Parameters:**
- Density ($ho$): `7140.0 kg/m^3`
- Mohs Hardness: `2.5`
- Young's Modulus ($E$): `108.0 GPa` | Poisson's Ratio ($
u$): `0.25`
- Coulomb Friction ($\mu$): `0.42` | Restitution ($e$): `0.35`
- Blast Fracture Threshold: `7500.0 J`
- Thermal Conductivity ($k$): `116.0 W/(m·K)` | Specific Heat ($c_p$): `388.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.82, 0.84, 0.86]`
- Microfacet Roughness ($lpha$): `0.28` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `1.9` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---
#### `metal.tungsten` — Tungsten / Heavy Wolfram
* **Description:** Ultra-dense transition metal possessing the highest melting point (3695 K) and high tensile strength.
* **Archetypal Provenance:** Terraria (Tungsten), Universal High-Energy Physics/CAD

**Physical Constitutive Parameters:**
- Density ($ho$): `19300.0 kg/m^3`
- Mohs Hardness: `7.5`
- Young's Modulus ($E$): `411.0 GPa` | Poisson's Ratio ($
u$): `0.28`
- Coulomb Friction ($\mu$): `0.3` | Restitution ($e$): `0.65`
- Blast Fracture Threshold: `16000.0 J`
- Thermal Conductivity ($k$): `173.0 W/(m·K)` | Specific Heat ($c_p$): `132.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `diamond_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.72, 0.74, 0.76]`
- Microfacet Roughness ($lpha$): `0.18` | Metallic Fraction ($m$): `1.0`
- Index of Refraction ($n$): `3.4` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---

### 4. Gemstones, Crystals & Refractives
#### `gem.quartz` — Quartz
* **Description:** Crystalline silicon dioxide exhibiting piezoelectricity, glassy luster, and high optical clarity.
* **Archetypal Provenance:** Minecraft (Nether/Overworld Quartz), Terraria (Quartz/Gems), Universal Electronics/Optics

**Physical Constitutive Parameters:**
- Density ($ho$): `2650.0 kg/m^3`
- Mohs Hardness: `7.0`
- Young's Modulus ($E$): `95.0 GPa` | Poisson's Ratio ($
u$): `0.17`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.55`
- Blast Fracture Threshold: `5000.0 J`
- Thermal Conductivity ($k$): `1.4 W/(m·K)` | Specific Heat ($c_p$): `730.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[0.94, 0.94, 0.94]`
- Microfacet Roughness ($lpha$): `0.08` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.544` | Transmittance ($	au$): `0.9`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `refractive_dielectric`

---
#### `gem.diamond` — Diamond
* **Description:** Allotrope of carbon in face-centered cubic lattice; highest hardness, thermal conductivity, and refractive brilliance.
* **Archetypal Provenance:** Minecraft (Diamond), Terraria (Diamond), Universal Cutting Tools/Optics

**Physical Constitutive Parameters:**
- Density ($ho$): `3515.0 kg/m^3`
- Mohs Hardness: `10.0`
- Young's Modulus ($E$): `1220.0 GPa` | Poisson's Ratio ($
u$): `0.07`
- Coulomb Friction ($\mu$): `0.1` | Restitution ($e$): `0.85`
- Blast Fracture Threshold: `15000.0 J`
- Thermal Conductivity ($k$): `2200.0 W/(m·K)` | Specific Heat ($c_p$): `509.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `iron_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_DISPERSIVE`)
- Base Albedo (Linear sRGB): `[0.70, 0.92, 0.95]`
- Microfacet Roughness ($lpha$): `0.02` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `2.418` | Transmittance ($	au$): `0.95`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `high_index_refractive`

---
#### `gem.emerald` — Emerald
* **Description:** Chromium-bearing cyclosilicate beryl crystal with characteristic rich green vitreous luster.
* **Archetypal Provenance:** Minecraft (Emerald), Terraria (Emerald), Universal Mineralogy/Economy

**Physical Constitutive Parameters:**
- Density ($ho$): `2760.0 kg/m^3`
- Mohs Hardness: `7.8`
- Young's Modulus ($E$): `200.0 GPa` | Poisson's Ratio ($
u$): `0.2`
- Coulomb Friction ($\mu$): `0.35` | Restitution ($e$): `0.6`
- Blast Fracture Threshold: `6000.0 J`
- Thermal Conductivity ($k$): `4.0 W/(m·K)` | Specific Heat ($c_p$): `700.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `iron_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[0.10, 0.80, 0.35]`
- Microfacet Roughness ($lpha$): `0.05` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.58` | Transmittance ($	au$): `0.85`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `colored_refractive`

---
#### `gem.ruby` — Ruby
* **Description:** Chromium-doped aluminium oxide corundum crystal exhibiting deep crimson red transmission and high durability.
* **Archetypal Provenance:** Terraria (Ruby), Minecraft (Redstone crystal analogue), Universal Mineralogy/Laser Optics

**Physical Constitutive Parameters:**
- Density ($ho$): `4020.0 kg/m^3`
- Mohs Hardness: `9.0`
- Young's Modulus ($E$): `400.0 GPa` | Poisson's Ratio ($
u$): `0.28`
- Coulomb Friction ($\mu$): `0.25` | Restitution ($e$): `0.7`
- Blast Fracture Threshold: `9000.0 J`
- Thermal Conductivity ($k$): `35.0 W/(m·K)` | Specific Heat ($c_p$): `750.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[0.88, 0.12, 0.22]`
- Microfacet Roughness ($lpha$): `0.04` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.77` | Transmittance ($	au$): `0.85`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `colored_refractive`

---
#### `gem.sapphire` — Sapphire
* **Description:** Corundum crystal colored by trace iron and titanium, used in scratch-resistant optical windows and instrumentation.
* **Archetypal Provenance:** Terraria (Sapphire), Universal Optics/Mineralogy

**Physical Constitutive Parameters:**
- Density ($ho$): `3980.0 kg/m^3`
- Mohs Hardness: `9.0`
- Young's Modulus ($E$): `400.0 GPa` | Poisson's Ratio ($
u$): `0.28`
- Coulomb Friction ($\mu$): `0.25` | Restitution ($e$): `0.7`
- Blast Fracture Threshold: `9000.0 J`
- Thermal Conductivity ($k$): `35.0 W/(m·K)` | Specific Heat ($c_p$): `750.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[0.10, 0.25, 0.85]`
- Microfacet Roughness ($lpha$): `0.04` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.77` | Transmittance ($	au$): `0.85`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `colored_refractive`

---
#### `gem.amethyst` — Amethyst
* **Description:** Violet variety of quartz irradiated with ferric iron impurities, producing geometric geode cluster formations.
* **Archetypal Provenance:** Minecraft (Amethyst), Terraria (Amethyst), Universal Mineralogy/Decor

**Physical Constitutive Parameters:**
- Density ($ho$): `2650.0 kg/m^3`
- Mohs Hardness: `7.0`
- Young's Modulus ($E$): `90.0 GPa` | Poisson's Ratio ($
u$): `0.17`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.55`
- Blast Fracture Threshold: `5000.0 J`
- Thermal Conductivity ($k$): `1.4 W/(m·K)` | Specific Heat ($c_p$): `730.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `iron_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[0.60, 0.25, 0.80]`
- Microfacet Roughness ($lpha$): `0.06` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.54` | Transmittance ($	au$): `0.8`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `colored_refractive`

---
#### `gem.lapis_lazuli` — Lazurite / Ultramarine Silicate
* **Description:** Deep-blue feldspathoid sodium calcium aluminosilicate containing sulfur ions producing historic ultramarine pigment.
* **Archetypal Provenance:** Minecraft (Lapis Lazuli), Universal Historic Pigment/Mineralogy

**Physical Constitutive Parameters:**
- Density ($ho$): `2800.0 kg/m^3`
- Mohs Hardness: `5.5`
- Young's Modulus ($E$): `55.0 GPa` | Poisson's Ratio ($
u$): `0.25`
- Coulomb Friction ($\mu$): `0.6` | Restitution ($e$): `0.25`
- Blast Fracture Threshold: `4500.0 J`
- Thermal Conductivity ($k$): `2.1 W/(m·K)` | Specific Heat ($c_p$): `800.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `stone_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.08, 0.16, 0.58]`
- Microfacet Roughness ($lpha$): `0.65` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.5` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `gem.topaz` — Topaz / Aluminum Fluorosilicate
* **Description:** Nesosilicate mineral of aluminum and fluorine; Mohs standard 8.0 with high optical dispersion.
* **Archetypal Provenance:** Terraria (Topaz), Universal Gemology/Optics

**Physical Constitutive Parameters:**
- Density ($ho$): `3530.0 kg/m^3`
- Mohs Hardness: `8.0`
- Young's Modulus ($E$): `260.0 GPa` | Poisson's Ratio ($
u$): `0.24`
- Coulomb Friction ($\mu$): `0.25` | Restitution ($e$): `0.65`
- Blast Fracture Threshold: `8000.0 J`
- Thermal Conductivity ($k$): `12.0 W/(m·K)` | Specific Heat ($c_p$): `780.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_DISPERSIVE`)
- Base Albedo (Linear sRGB): `[0.98, 0.82, 0.28]`
- Microfacet Roughness ($lpha$): `0.03` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.62` | Transmittance ($	au$): `0.9`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `colored_refractive`

---
#### `gem.jade` — Jade / Nephrite & Jadeite Aggregate
* **Description:** Interlocking microcrystalline pyroxene/amphibole mineral fibers offering unprecedented impact fracture toughness.
* **Archetypal Provenance:** Universal Tough Mineral/Statuary

**Physical Constitutive Parameters:**
- Density ($ho$): `3300.0 kg/m^3`
- Mohs Hardness: `6.5`
- Young's Modulus ($E$): `160.0 GPa` | Poisson's Ratio ($
u$): `0.26`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.5`
- Blast Fracture Threshold: `11000.0 J`
- Thermal Conductivity ($k$): `3.5 W/(m·K)` | Specific Heat ($c_p$): `820.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `subsurface_scattering_dielectric` (Closure: `BSDF_BSSRDF_DIPOLE`)
- Base Albedo (Linear sRGB): `[0.22, 0.65, 0.42]`
- Microfacet Roughness ($lpha$): `0.2` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.66` | Transmittance ($	au$): `0.2`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `subsurface_dielectric`

---
#### `gem.amber` — Amber / Fossilized Tree Resin
* **Description:** Amorphous biogenic macromolecular polymer formed from fossilized plant resin; natural electrostatic charging medium.
* **Archetypal Provenance:** Terraria (Amber), Universal Paleontology/Dielectrics

**Physical Constitutive Parameters:**
- Density ($ho$): `1080.0 kg/m^3`
- Mohs Hardness: `2.2`
- Young's Modulus ($E$): `3.5 GPa` | Poisson's Ratio ($
u$): `0.38`
- Coulomb Friction ($\mu$): `0.45` | Restitution ($e$): `0.3`
- Blast Fracture Threshold: `800.0 J`
- Thermal Conductivity ($k$): `0.18 W/(m·K)` | Specific Heat ($c_p$): `1300.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[0.96, 0.62, 0.12]`
- Microfacet Roughness ($lpha$): `0.08` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.54` | Transmittance ($	au$): `0.85`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `colored_refractive`

---
#### `mineral.phosphor` — Phosphorescent / Luminescent Crystal
* **Description:** Doped alkaline-earth aluminate crystal capable of storing photon energy and emitting sustained visible radiance.
* **Archetypal Provenance:** Minecraft (Glowstone/Shroomlight), Universal Solid-State Radiance

**Physical Constitutive Parameters:**
- Density ($ho$): `2600.0 kg/m^3`
- Mohs Hardness: `4.5`
- Young's Modulus ($E$): `35.0 GPa` | Poisson's Ratio ($
u$): `0.24`
- Coulomb Friction ($\mu$): `0.5` | Restitution ($e$): `0.3`
- Blast Fracture Threshold: `3000.0 J`
- Thermal Conductivity ($k$): `1.2 W/(m·K)` | Specific Heat ($c_p$): `750.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `emissive_blackbody_fluid` (Closure: `BSDF_PLUS_EDF_EMISSIVE`)
- Base Albedo (Linear sRGB): `[0.95, 0.90, 0.45]`
- Microfacet Roughness ($lpha$): `0.3` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.65` | Transmittance ($	au$): `0.3`
- Radiative Emission ($L_e$): `12000.0 cd/m^2`
- Hypergraph Layering Topology: `diffuse_plus_blackbody_edf`

---

### 5. Organics, Woods & Botanical Media
#### `wood.hardwood` — Hardwood / Oak
* **Description:** Dense fibrous angiosperm cellular wood matrix offering structural load-bearing capacity.
* **Archetypal Provenance:** Minecraft (Oak Wood), Terraria (Wood), Universal Forestry/Carpentry

**Physical Constitutive Parameters:**
- Density ($ho$): `720.0 kg/m^3`
- Mohs Hardness: `3.0`
- Young's Modulus ($E$): `12.0 GPa` | Poisson's Ratio ($
u$): `0.35`
- Coulomb Friction ($\mu$): `0.6` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `2000.0 J`
- Thermal Conductivity ($k$): `0.17 W/(m·K)` | Specific Heat ($c_p$): `2000.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `axe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse_anisotropic` (Closure: `BSDF_ANISOTROPIC_ROUGH`)
- Base Albedo (Linear sRGB): `[0.65, 0.45, 0.28]`
- Microfacet Roughness ($lpha$): `0.68` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.53` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `anisotropic_grain`

---
#### `wood.softwood` — Softwood / Pine & Boreal
* **Description:** Lighter gymnosperm coniferous wood rich in resins, easily worked for framing and cellulose pulp.
* **Archetypal Provenance:** Minecraft (Spruce Wood), Terraria (Boreal Wood), Universal Construction Timber

**Physical Constitutive Parameters:**
- Density ($ho$): `510.0 kg/m^3`
- Mohs Hardness: `2.5`
- Young's Modulus ($E$): `9.0 GPa` | Poisson's Ratio ($
u$): `0.38`
- Coulomb Friction ($\mu$): `0.58` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `1800.0 J`
- Thermal Conductivity ($k$): `0.13 W/(m·K)` | Specific Heat ($c_p$): `2300.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `axe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse_anisotropic` (Closure: `BSDF_ANISOTROPIC_ROUGH`)
- Base Albedo (Linear sRGB): `[0.45, 0.32, 0.20]`
- Microfacet Roughness ($lpha$): `0.72` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.52` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `anisotropic_grain`

---
#### `wood.birch` — Birch
* **Description:** Fine-grained hardwood with distinctive white betulin-rich outer bark and light internal timber.
* **Archetypal Provenance:** Minecraft (Birch), Universal Botany/Woodworking

**Physical Constitutive Parameters:**
- Density ($ho$): `670.0 kg/m^3`
- Mohs Hardness: `3.0`
- Young's Modulus ($E$): `14.0 GPa` | Poisson's Ratio ($
u$): `0.36`
- Coulomb Friction ($\mu$): `0.58` | Restitution ($e$): `0.22`
- Blast Fracture Threshold: `2000.0 J`
- Thermal Conductivity ($k$): `0.15 W/(m·K)` | Specific Heat ($c_p$): `1900.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `axe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse_anisotropic` (Closure: `BSDF_ANISOTROPIC_ROUGH`)
- Base Albedo (Linear sRGB): `[0.85, 0.82, 0.75]`
- Microfacet Roughness ($lpha$): `0.65` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.53` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `anisotropic_grain`

---
#### `botanical.bamboo` — Bamboo
* **Description:** Fast-growing woody grass characterized by hollow internodal culms and outstanding longitudinal tensile strength.
* **Archetypal Provenance:** Minecraft (Bamboo), Terraria (Bamboo), Universal Sustainable Scaffolding

**Physical Constitutive Parameters:**
- Density ($ho$): `600.0 kg/m^3`
- Mohs Hardness: `3.5`
- Young's Modulus ($E$): `18.0 GPa` | Poisson's Ratio ($
u$): `0.32`
- Coulomb Friction ($\mu$): `0.5` | Restitution ($e$): `0.35`
- Blast Fracture Threshold: `1500.0 J`
- Thermal Conductivity ($k$): `0.16 W/(m·K)` | Specific Heat ($c_p$): `1600.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `axe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular_coated_diffuse` (Closure: `BSDF_COATED_DIFFUSE`)
- Base Albedo (Linear sRGB): `[0.38, 0.62, 0.22]`
- Microfacet Roughness ($lpha$): `0.4` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.51` | Transmittance ($	au$): `0.05`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `waxy_sheen_over_fibers`

---
#### `botanical.foliage` — Foliage / Plant Canopy
* **Description:** Thin photosynthetic leaves exhibiting high optical translucency, subsurface scattering, and low mechanical density.
* **Archetypal Provenance:** Minecraft (Leaves), Terraria (Foliage/Vines), Universal Vegetation/Biosphere

**Physical Constitutive Parameters:**
- Density ($ho$): `250.0 kg/m^3`
- Mohs Hardness: `0.5`
- Young's Modulus ($E$): `0.01 GPa` | Poisson's Ratio ($
u$): `0.4`
- Coulomb Friction ($\mu$): `0.7` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `200.0 J`
- Thermal Conductivity ($k$): `0.08 W/(m·K)` | Specific Heat ($c_p$): `2500.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `shears`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `two_sided_thin_surface_translucent` (Closure: `BSDF_THIN_SURFACE_TRANSLUCENT`)
- Base Albedo (Linear sRGB): `[0.24, 0.52, 0.18]`
- Microfacet Roughness ($lpha$): `0.55` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.42` | Transmittance ($	au$): `0.35`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `chlorophyll_translucent`

---
#### `organic.bone` — Bone / Osseous Tissue
* **Description:** Rigid biological composite of hydroxyapatite minerals and collagen fibers with high compressive strength.
* **Archetypal Provenance:** Minecraft (Bone Block), Terraria (Bone Block), Universal Biomechanics

**Physical Constitutive Parameters:**
- Density ($ho$): `1900.0 kg/m^3`
- Mohs Hardness: `4.0`
- Young's Modulus ($E$): `18.0 GPa` | Poisson's Ratio ($
u$): `0.31`
- Coulomb Friction ($\mu$): `0.55` | Restitution ($e$): `0.3`
- Blast Fracture Threshold: `4000.0 J`
- Thermal Conductivity ($k$): `0.52 W/(m·K)` | Specific Heat ($c_p$): `1250.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `subsurface_scattering_dielectric` (Closure: `BSDF_BSSRDF_DIPOLE`)
- Base Albedo (Linear sRGB): `[0.88, 0.86, 0.78]`
- Microfacet Roughness ($lpha$): `0.45` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.55` | Transmittance ($	au$): `0.08`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `subsurface_dielectric`

---
#### `organic.fiber` — Silk / Fibers / Webbing
* **Description:** Polymer protein fibrils with extreme tensile strength, high elasticity, and dramatic kinematic velocity damping.
* **Archetypal Provenance:** Minecraft (Cobweb/Wool), Terraria (Cobweb/Silk), Universal Textiles/Biopolymers

**Physical Constitutive Parameters:**
- Density ($ho$): `1300.0 kg/m^3`
- Mohs Hardness: `1.0`
- Young's Modulus ($E$): `10.0 GPa` | Poisson's Ratio ($
u$): `0.4`
- Coulomb Friction ($\mu$): `0.95` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `400.0 J`
- Thermal Conductivity ($k$): `0.1 W/(m·K)` | Specific Heat ($c_p$): `1380.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `sword`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `microfiber_sheen` (Closure: `BSDF_SHEEN_CLOTH`)
- Base Albedo (Linear sRGB): `[0.88, 0.88, 0.88]`
- Microfacet Roughness ($lpha$): `0.6` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.54` | Transmittance ($	au$): `0.4`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `dielectric_microfiber`

---
#### `organic.leather` — Tanned Leather / Animal Dermis
* **Description:** Cross-linked fibrous collagen matrix yielding flexibility, high tear resistance, and barrier properties.
* **Archetypal Provenance:** Minecraft (Leather), Terraria (Leather), Universal Biopolymers

**Physical Constitutive Parameters:**
- Density ($ho$): `850.0 kg/m^3`
- Mohs Hardness: `1.5`
- Young's Modulus ($E$): `0.05 GPa` | Poisson's Ratio ($
u$): `0.4`
- Coulomb Friction ($\mu$): `0.55` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `1200.0 J`
- Thermal Conductivity ($k$): `0.15 W/(m·K)` | Specific Heat ($c_p$): `1500.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `shears`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.42, 0.26, 0.16]`
- Microfacet Roughness ($lpha$): `0.6` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.5` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `organic.chitin` — Chitin / Arthropod Exoskeleton
* **Description:** Long-chain polymer of N-acetylglucosamine forming rigid protective invertebrate armor.
* **Archetypal Provenance:** Universal Biopolymer Architecture

**Physical Constitutive Parameters:**
- Density ($ho$): `1400.0 kg/m^3`
- Mohs Hardness: `3.5`
- Young's Modulus ($E$): `15.0 GPa` | Poisson's Ratio ($
u$): `0.3`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.45`
- Blast Fracture Threshold: `3500.0 J`
- Thermal Conductivity ($k$): `0.25 W/(m·K)` | Specific Heat ($c_p$): `1200.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular_coated_diffuse` (Closure: `BSDF_COATED_DIFFUSE`)
- Base Albedo (Linear sRGB): `[0.28, 0.22, 0.18]`
- Microfacet Roughness ($lpha$): `0.35` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.56` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `coated_diffuse`

---
#### `organic.rubber` — Natural Rubber / Polyisoprene Elastomer
* **Description:** Hyperelastic hydrocarbon polymer exhibiting extreme reversible elongation and restitution (0.85).
* **Archetypal Provenance:** Minecraft (Slime/Bounce analogue), Universal Polymer Mechanics

**Physical Constitutive Parameters:**
- Density ($ho$): `950.0 kg/m^3`
- Mohs Hardness: `1.0`
- Young's Modulus ($E$): `0.005 GPa` | Poisson's Ratio ($
u$): `0.49`
- Coulomb Friction ($\mu$): `0.9` | Restitution ($e$): `0.85`
- Blast Fracture Threshold: `2500.0 J`
- Thermal Conductivity ($k$): `0.13 W/(m·K)` | Specific Heat ($c_p$): `1900.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `shears`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.15, 0.15, 0.15]`
- Microfacet Roughness ($lpha$): `0.8` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.52` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `organic.wax` — Hydrocarbon Wax / Beeswax & Tallow
* **Description:** Lipid ester mixture solid at room temperature with low melting point (335 K), used as hydrophobic sealant.
* **Archetypal Provenance:** Minecraft (Honeycomb/Wax), Universal Chemical Sealing

**Physical Constitutive Parameters:**
- Density ($ho$): `960.0 kg/m^3`
- Mohs Hardness: `0.5`
- Young's Modulus ($E$): `0.02 GPa` | Poisson's Ratio ($
u$): `0.42`
- Coulomb Friction ($\mu$): `0.2` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `300.0 J`
- Thermal Conductivity ($k$): `0.25 W/(m·K)` | Specific Heat ($c_p$): `2400.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `shears`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `subsurface_scattering_dielectric` (Closure: `BSDF_BSSRDF_DIPOLE`)
- Base Albedo (Linear sRGB): `[0.92, 0.82, 0.55]`
- Microfacet Roughness ($lpha$): `0.3` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.44` | Transmittance ($	au$): `0.3`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `subsurface_dielectric`

---
#### `wood.charcoal` — Pyrolyzed Biomass Carbon / Charcoal
* **Description:** Porous black carbon residue derived from thermal pyrolysis of hardwood in low-oxygen conditions.
* **Archetypal Provenance:** Minecraft (Charcoal), Universal Metallurgy/Fuel

**Physical Constitutive Parameters:**
- Density ($ho$): `450.0 kg/m^3`
- Mohs Hardness: `2.0`
- Young's Modulus ($E$): `2.5 GPa` | Poisson's Ratio ($
u$): `0.2`
- Coulomb Friction ($\mu$): `0.6` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `1000.0 J`
- Thermal Conductivity ($k$): `0.08 W/(m·K)` | Specific Heat ($c_p$): `1000.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.05, 0.05, 0.05]`
- Microfacet Roughness ($lpha$): `0.95` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.75` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `botanical.moss` — Bryophyte Ground Mat / Moss
* **Description:** Dense non-vascular photosynthetic plant carpet exhibiting high capillary moisture absorption and impact damping.
* **Archetypal Provenance:** Minecraft (Moss Block), Terraria (Moss), Universal Botany/Ecology

**Physical Constitutive Parameters:**
- Density ($ho$): `400.0 kg/m^3`
- Mohs Hardness: `0.5`
- Young's Modulus ($E$): `0.005 GPa` | Poisson's Ratio ($
u$): `0.35`
- Coulomb Friction ($\mu$): `0.75` | Restitution ($e$): `0.02`
- Blast Fracture Threshold: `300.0 J`
- Thermal Conductivity ($k$): `0.1 W/(m·K)` | Specific Heat ($c_p$): `2200.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `shears`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.28, 0.48, 0.18]`
- Microfacet Roughness ($lpha$): `0.92` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.45` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `botanical.mycelium` — Fungal Hyphal Matrix / Mycelium
* **Description:** Vegetative fungal colony composed of branched hyphae capable of decomposing organic detritus with faint luminescence.
* **Archetypal Provenance:** Minecraft (Mycelium), Terraria (Glowing Mushroom), Universal Mycology

**Physical Constitutive Parameters:**
- Density ($ho$): `1250.0 kg/m^3`
- Mohs Hardness: `1.0`
- Young's Modulus ($E$): `0.02 GPa` | Poisson's Ratio ($
u$): `0.38`
- Coulomb Friction ($\mu$): `0.65` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `450.0 J`
- Thermal Conductivity ($k$): `0.25 W/(m·K)` | Specific Heat ($c_p$): `1600.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.45, 0.38, 0.42]`
- Microfacet Roughness ($lpha$): `0.88` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.48` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `200.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `botanical.cactus` — Xerophyte Cactus Stem
* **Description:** Succulent plant stem with thickened fleshy parenchyma storing water enclosed in tough waxy cuticle with spines.
* **Archetypal Provenance:** Minecraft (Cactus), Terraria (Cactus), Universal Arid Botany

**Physical Constitutive Parameters:**
- Density ($ho$): `850.0 kg/m^3`
- Mohs Hardness: `2.0`
- Young's Modulus ($E$): `0.1 GPa` | Poisson's Ratio ($
u$): `0.35`
- Coulomb Friction ($\mu$): `0.6` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `500.0 J`
- Thermal Conductivity ($k$): `0.35 W/(m·K)` | Specific Heat ($c_p$): `3500.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `axe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular_coated_diffuse` (Closure: `BSDF_COATED_DIFFUSE`)
- Base Albedo (Linear sRGB): `[0.22, 0.52, 0.18]`
- Microfacet Roughness ($lpha$): `0.45` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.5` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `coated_diffuse`

---

### 6. Fluids & Multiphase Media
#### `fluid.water` — Water
* **Description:** Transparent Newtonian fluid with density of 1000 kg/m^3, low viscosity, and high specific heat capacity.
* **Archetypal Provenance:** Minecraft (Water), Terraria (Water), Universal Fluid Dynamics/Hydrology

**Physical Constitutive Parameters:**
- Density ($ho$): `1000.0 kg/m^3`
- Mohs Hardness: `0.0`
- Young's Modulus ($E$): `2.2 GPa` | Poisson's Ratio ($
u$): `0.5`
- Coulomb Friction ($\mu$): `0.05` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `50000.0 J`
- Thermal Conductivity ($k$): `0.6 W/(m·K)` | Specific Heat ($c_p$): `4184.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `True` | Flammable: `False`
- Optimal Harvest Tool: `bucket`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_refractive_volume` (Closure: `BSDF_DIELECTRIC_LIQUID`)
- Base Albedo (Linear sRGB): `[0.82, 0.90, 0.95]`
- Microfacet Roughness ($lpha$): `0.01` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.333` | Transmittance ($	au$): `0.98`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `specular_boundary_plus_vdf`

---
#### `fluid.lava` — Lava / Magma
* **Description:** High-temperature molten silicate fluid exhibiting extreme viscosity, thermal emission, and severe destructive contact.
* **Archetypal Provenance:** Minecraft (Lava), Terraria (Lava), Universal Geophysics/Volcanology

**Physical Constitutive Parameters:**
- Density ($ho$): `2800.0 kg/m^3`
- Mohs Hardness: `0.0`
- Young's Modulus ($E$): `5.0 GPa` | Poisson's Ratio ($
u$): `0.5`
- Coulomb Friction ($\mu$): `0.2` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `40000.0 J`
- Thermal Conductivity ($k$): `2.5 W/(m·K)` | Specific Heat ($c_p$): `1200.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `True` | Flammable: `False`
- Optimal Harvest Tool: `bucket`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `emissive_blackbody_fluid` (Closure: `BSDF_PLUS_EDF_EMISSIVE`)
- Base Albedo (Linear sRGB): `[1.00, 0.40, 0.05]`
- Microfacet Roughness ($lpha$): `0.25` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.52` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `25000.0 cd/m^2`
- Hypergraph Layering Topology: `diffuse_plus_blackbody_edf`

---
#### `fluid.honey` — Honey
* **Description:** Supersaturated viscous non-Newtonian sugar fluid exhibiting significant velocity retardation and adhesion.
* **Archetypal Provenance:** Minecraft (Honey Block/Fluid), Terraria (Honey), Universal Fluid Rheology

**Physical Constitutive Parameters:**
- Density ($ho$): `1420.0 kg/m^3`
- Mohs Hardness: `0.0`
- Young's Modulus ($E$): `0.1 GPa` | Poisson's Ratio ($
u$): `0.49`
- Coulomb Friction ($\mu$): `0.9` | Restitution ($e$): `0.01`
- Blast Fracture Threshold: `2000.0 J`
- Thermal Conductivity ($k$): `0.38 W/(m·K)` | Specific Heat ($c_p$): `2520.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `True` | Flammable: `False`
- Optimal Harvest Tool: `bucket`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_refractive_volume` (Closure: `BSDF_DIELECTRIC_LIQUID`)
- Base Albedo (Linear sRGB): `[0.95, 0.68, 0.15]`
- Microfacet Roughness ($lpha$): `0.08` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.49` | Transmittance ($	au$): `0.85`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `specular_boundary_plus_vdf`

---
#### `fluid.oil` — Crude Petroleum / Liquid Hydrocarbon
* **Description:** Viscous liquid mixture of hydrocarbons exhibiting density lower than water (850 kg/m^3) and flammability.
* **Archetypal Provenance:** Universal Energy/Fluid Mechanics

**Physical Constitutive Parameters:**
- Density ($ho$): `850.0 kg/m^3`
- Mohs Hardness: `0.0`
- Young's Modulus ($E$): `1.2 GPa` | Poisson's Ratio ($
u$): `0.5`
- Coulomb Friction ($\mu$): `0.02` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `10000.0 J`
- Thermal Conductivity ($k$): `0.14 W/(m·K)` | Specific Heat ($c_p$): `2000.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `True` | Flammable: `True`
- Optimal Harvest Tool: `bucket`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular_coated_diffuse` (Closure: `BSDF_COATED_DIFFUSE`)
- Base Albedo (Linear sRGB): `[0.05, 0.04, 0.03]`
- Microfacet Roughness ($lpha$): `0.05` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.48` | Transmittance ($	au$): `0.01`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `specular_boundary_plus_vdf`

---
#### `fluid.acid` — Mineral Acid / Corrosive Hydronium Solution
* **Description:** Highly reactive aqueous hydronium solvent capable of rapidly etching and dissolving metals and carbonates.
* **Archetypal Provenance:** Universal Industrial Chemistry/Hazard

**Physical Constitutive Parameters:**
- Density ($ho$): `1250.0 kg/m^3`
- Mohs Hardness: `0.0`
- Young's Modulus ($E$): `2.4 GPa` | Poisson's Ratio ($
u$): `0.5`
- Coulomb Friction ($\mu$): `0.05` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `20000.0 J`
- Thermal Conductivity ($k$): `0.55 W/(m·K)` | Specific Heat ($c_p$): `3500.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `True` | Flammable: `False`
- Optimal Harvest Tool: `bucket`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_refractive_volume` (Closure: `BSDF_DIELECTRIC_LIQUID`)
- Base Albedo (Linear sRGB): `[0.45, 0.95, 0.25]`
- Microfacet Roughness ($lpha$): `0.01` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.38` | Transmittance ($	au$): `0.9`
- Radiative Emission ($L_e$): `50.0 cd/m^2`
- Hypergraph Layering Topology: `specular_boundary_plus_vdf`

---
#### `gas.steam` — Water Vapor / Steam
* **Description:** Gaseous phase of water formed by vaporization above 373.15 K with positive upward convective buoyancy.
* **Archetypal Provenance:** Universal Thermodynamics/Fluid Power

**Physical Constitutive Parameters:**
- Density ($ho$): `0.6 kg/m^3`
- Mohs Hardness: `0.0`
- Young's Modulus ($E$): `0.0001 GPa` | Poisson's Ratio ($
u$): `0.5`
- Coulomb Friction ($\mu$): `0.0` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `100000.0 J`
- Thermal Conductivity ($k$): `0.025 W/(m·K)` | Specific Heat ($c_p$): `2080.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `none`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `two_sided_thin_surface_translucent` (Closure: `BSDF_THIN_SURFACE_TRANSLUCENT`)
- Base Albedo (Linear sRGB): `[0.95, 0.95, 0.98]`
- Microfacet Roughness ($lpha$): `0.85` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.00028` | Transmittance ($	au$): `0.85`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `pure_participating_volume`

---
#### `gas.air` — Ambient Atmospheric Gas
* **Description:** Standard terrestrial gas mixture (78% N2, 21% O2); baseline drag and diffusion medium.
* **Archetypal Provenance:** Universal Atmosphere/Aero Mechanics

**Physical Constitutive Parameters:**
- Density ($ho$): `1.225 kg/m^3`
- Mohs Hardness: `0.0`
- Young's Modulus ($E$): `0.0001 GPa` | Poisson's Ratio ($
u$): `0.5`
- Coulomb Friction ($\mu$): `0.0` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `100000.0 J`
- Thermal Conductivity ($k$): `0.026 W/(m·K)` | Specific Heat ($c_p$): `1005.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `none`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_refractive_volume` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[1.00, 1.00, 1.00]`
- Microfacet Roughness ($lpha$): `0.0` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.000293` | Transmittance ($	au$): `1.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `pure_dielectric`

---
#### `gas.smoke` — Particulate Combustion Aerosol
* **Description:** Colloidal suspension of airborne solid soot carbon particles and liquid droplets obscuring light.
* **Archetypal Provenance:** Universal Fire Dynamics/Radiative Obscuration

**Physical Constitutive Parameters:**
- Density ($ho$): `0.95 kg/m^3`
- Mohs Hardness: `0.0`
- Young's Modulus ($E$): `0.0001 GPa` | Poisson's Ratio ($
u$): `0.5`
- Coulomb Friction ($\mu$): `0.0` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `100000.0 J`
- Thermal Conductivity ($k$): `0.028 W/(m·K)` | Specific Heat ($c_p$): `1050.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `none`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.18, 0.18, 0.18]`
- Microfacet Roughness ($lpha$): `0.95` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.0003` | Transmittance ($	au$): `0.2`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `pure_participating_volume`

---
#### `gas.methane` — Volatile Methane / Natural Gas
* **Description:** Light, colorless, flammable gaseous hydrocarbon (CH4) forming explosive mixtures with oxygen.
* **Archetypal Provenance:** Universal Gas/Hazardous Energetics

**Physical Constitutive Parameters:**
- Density ($ho$): `0.668 kg/m^3`
- Mohs Hardness: `0.0`
- Young's Modulus ($E$): `0.0001 GPa` | Poisson's Ratio ($
u$): `0.5`
- Coulomb Friction ($\mu$): `0.0` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `100000.0 J`
- Thermal Conductivity ($k$): `0.034 W/(m·K)` | Specific Heat ($c_p$): `2220.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `none`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_refractive_volume` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[0.98, 0.98, 1.00]`
- Microfacet Roughness ($lpha$): `0.0` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.00044` | Transmittance ($	au$): `1.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `pure_dielectric`

---

### 7. Architectural Ceramics & Synthetic Solids
#### `synthetic.glass` — Glass
* **Description:** Amorphous non-crystalline inorganic silicate solid with high transparency and brittle fracture.
* **Archetypal Provenance:** Minecraft (Glass), Terraria (Glass), Universal Architecture/Optics

**Physical Constitutive Parameters:**
- Density ($ho$): `2500.0 kg/m^3`
- Mohs Hardness: `5.5`
- Young's Modulus ($E$): `70.0 GPa` | Poisson's Ratio ($
u$): `0.22`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.65`
- Blast Fracture Threshold: `1500.0 J`
- Thermal Conductivity ($k$): `1.05 W/(m·K)` | Specific Heat ($c_p$): `840.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `silk_touch_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[0.95, 0.98, 0.99]`
- Microfacet Roughness ($lpha$): `0.01` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.52` | Transmittance ($	au$): `0.98`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `pure_dielectric`

---
#### `synthetic.brick` — Brick / Fired Ceramic
* **Description:** Fired clay masonry block offering high fire resistance, compressive strength, and thermal mass.
* **Archetypal Provenance:** Minecraft (Bricks), Terraria (Red Brick), Universal Civil Masonry

**Physical Constitutive Parameters:**
- Density ($ho$): `1900.0 kg/m^3`
- Mohs Hardness: `5.0`
- Young's Modulus ($E$): `20.0 GPa` | Poisson's Ratio ($
u$): `0.2`
- Coulomb Friction ($\mu$): `0.7` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `6000.0 J`
- Thermal Conductivity ($k$): `0.75 W/(m·K)` | Specific Heat ($c_p$): `840.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.65, 0.28, 0.20]`
- Microfacet Roughness ($lpha$): `0.85` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.53` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `synthetic.concrete` — Concrete / Mortar
* **Description:** Composite structural solid formed from hydration of Portland cement binder and graded mineral aggregate.
* **Archetypal Provenance:** Minecraft (Concrete), Universal Modern Construction

**Physical Constitutive Parameters:**
- Density ($ho$): `2400.0 kg/m^3`
- Mohs Hardness: `6.0`
- Young's Modulus ($E$): `30.0 GPa` | Poisson's Ratio ($
u$): `0.2`
- Coulomb Friction ($\mu$): `0.65` | Restitution ($e$): `0.15`
- Blast Fracture Threshold: `9000.0 J`
- Thermal Conductivity ($k$): `1.7 W/(m·K)` | Specific Heat ($c_p$): `880.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.65, 0.65, 0.65]`
- Microfacet Roughness ($lpha$): `0.88` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.54` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `synthetic.terracotta` — Terracotta / Hardened Clay
* **Description:** Earthenware glazed or baked clay matrix with earthy chromatic pigmentation and high thermal durability.
* **Archetypal Provenance:** Minecraft (Terracotta), Terraria (Clay/Tile), Universal Architectural Ceramics

**Physical Constitutive Parameters:**
- Density ($ho$): `2000.0 kg/m^3`
- Mohs Hardness: `4.5`
- Young's Modulus ($E$): `22.0 GPa` | Poisson's Ratio ($
u$): `0.22`
- Coulomb Friction ($\mu$): `0.65` | Restitution ($e$): `0.25`
- Blast Fracture Threshold: `5000.0 J`
- Thermal Conductivity ($k$): `1.0 W/(m·K)` | Specific Heat ($c_p$): `900.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.72, 0.44, 0.32]`
- Microfacet Roughness ($lpha$): `0.8` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.52` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `synthetic.asphalt` — Asphalt / Bitumen Roadway
* **Description:** Viscoelastic bituminous composite yielding high tire traction and high velocity conveyance.
* **Archetypal Provenance:** Terraria (Asphalt Block - accelerates movement), Universal Civil Infrastructure

**Physical Constitutive Parameters:**
- Density ($ho$): `2300.0 kg/m^3`
- Mohs Hardness: `3.0`
- Young's Modulus ($E$): `4.0 GPa` | Poisson's Ratio ($
u$): `0.35`
- Coulomb Friction ($\mu$): `0.85` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `4500.0 J`
- Thermal Conductivity ($k$): `0.75 W/(m·K)` | Specific Heat ($c_p$): `920.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.18, 0.18, 0.18]`
- Microfacet Roughness ($lpha$): `0.9` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.53` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `granular.concrete_powder` — Dry Concrete Precursor Powder
* **Description:** Granular aggregate of pulverized Portland cement clinker and silica sand; subject to gravity until hydrated.
* **Archetypal Provenance:** Minecraft (Concrete Powder), Universal Construction Masonry

**Physical Constitutive Parameters:**
- Density ($ho$): `1600.0 kg/m^3`
- Mohs Hardness: `1.5`
- Young's Modulus ($E$): `0.08 GPa` | Poisson's Ratio ($
u$): `0.3`
- Coulomb Friction ($\mu$): `0.55` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `400.0 J`
- Thermal Conductivity ($k$): `0.3 W/(m·K)` | Specific Heat ($c_p$): `850.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `True` | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.62, 0.62, 0.62]`
- Microfacet Roughness ($lpha$): `0.95` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.53` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `synthetic.mortar` — Hydraulic Masonry Mortar
* **Description:** Workable cementitious binder paste used to bind stones and concrete blocks into monolithic masonry.
* **Archetypal Provenance:** Universal Masonry/Civil Engineering

**Physical Constitutive Parameters:**
- Density ($ho$): `2000.0 kg/m^3`
- Mohs Hardness: `4.5`
- Young's Modulus ($E$): `18.0 GPa` | Poisson's Ratio ($
u$): `0.22`
- Coulomb Friction ($\mu$): `0.7` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `5000.0 J`
- Thermal Conductivity ($k$): `1.1 W/(m·K)` | Specific Heat ($c_p$): `840.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.72, 0.70, 0.66]`
- Microfacet Roughness ($lpha$): `0.85` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.53` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `synthetic.aerogel` — Silica Aerogel / Solid Smoke
* **Description:** Ultra-low-density mesoporous synthetic solid with lowest thermal conductivity and Rayleigh opalescence.
* **Archetypal Provenance:** Universal Extreme Thermal Insulation/CAD

**Physical Constitutive Parameters:**
- Density ($ho$): `100.0 kg/m^3`
- Mohs Hardness: `1.0`
- Young's Modulus ($E$): `0.01 GPa` | Poisson's Ratio ($
u$): `0.2`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `300.0 J`
- Thermal Conductivity ($k$): `0.015 W/(m·K)` | Specific Heat ($c_p$): `1000.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `shears`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `subsurface_scattering_dielectric` (Closure: `BSDF_BSSRDF_DIPOLE`)
- Base Albedo (Linear sRGB): `[0.75, 0.88, 0.98]`
- Microfacet Roughness ($lpha$): `0.05` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.02` | Transmittance ($	au$): `0.85`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `subsurface_dielectric`

---
#### `synthetic.plastic` — Thermoplastic Polymer / Polycarbonate
* **Description:** Synthetic organic polymer capable of plastic flow when heated and rigid impact durability when cooled.
* **Archetypal Provenance:** Universal Modern Manufacturing/CAD

**Physical Constitutive Parameters:**
- Density ($ho$): `1200.0 kg/m^3`
- Mohs Hardness: `3.0`
- Young's Modulus ($E$): `3.0 GPa` | Poisson's Ratio ($
u$): `0.38`
- Coulomb Friction ($\mu$): `0.35` | Restitution ($e$): `0.4`
- Blast Fracture Threshold: `3000.0 J`
- Thermal Conductivity ($k$): `0.2 W/(m·K)` | Specific Heat ($c_p$): `1300.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `axe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular_coated_diffuse` (Closure: `BSDF_COATED_DIFFUSE`)
- Base Albedo (Linear sRGB): `[0.85, 0.85, 0.85]`
- Microfacet Roughness ($lpha$): `0.15` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.58` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `coated_diffuse`

---
#### `synthetic.silicon` — Elemental Silicon / Polycrystalline Wafer
* **Description:** Tetravalent metalloid semiconductor forming foundational substrates for microelectronics and logic cells.
* **Archetypal Provenance:** Universal Electronics/Semiconductors

**Physical Constitutive Parameters:**
- Density ($ho$): `2330.0 kg/m^3`
- Mohs Hardness: `6.5`
- Young's Modulus ($E$): `130.0 GPa` | Poisson's Ratio ($
u$): `0.28`
- Coulomb Friction ($\mu$): `0.3` | Restitution ($e$): `0.55`
- Blast Fracture Threshold: `6000.0 J`
- Thermal Conductivity ($k$): `149.0 W/(m·K)` | Specific Heat ($c_p$): `700.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `conductor_fresnel_ggx` (Closure: `BSDF_CONDUCTOR_GGX`)
- Base Albedo (Linear sRGB): `[0.55, 0.62, 0.68]`
- Microfacet Roughness ($lpha$): `0.08` | Metallic Fraction ($m$): `0.85`
- Index of Refraction ($n$): `3.88` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `homogeneous_metal`

---
#### `synthetic.explosive` — Chemical High Explosive (TNT / Energetic Solid)
* **Description:** Stable chemical solid containing nitro-groups; undergoes rapid detonation producing supersonic shockwaves.
* **Archetypal Provenance:** Minecraft (TNT), Terraria (Explosives), Universal Demolition Physics

**Physical Constitutive Parameters:**
- Density ($ho$): `1650.0 kg/m^3`
- Mohs Hardness: `1.5`
- Young's Modulus ($E$): `8.0 GPa` | Poisson's Ratio ($
u$): `0.3`
- Coulomb Friction ($\mu$): `0.5` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `50.0 J`
- Thermal Conductivity ($k$): `0.22 W/(m·K)` | Specific Heat ($c_p$): `1400.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `shears`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.78, 0.22, 0.15]`
- Microfacet Roughness ($lpha$): `0.8` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.55` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 8. Cryogenic & Volatile Phases
#### `cryo.ice` — Ice / Glacial Ice
* **Description:** Hexagonal crystalline solid phase of water (Ih) with low kinetic friction and brittle fracture under impact.
* **Archetypal Provenance:** Minecraft (Ice), Terraria (Ice Block), Universal Cryology/Glaciology

**Physical Constitutive Parameters:**
- Density ($ho$): `917.0 kg/m^3`
- Mohs Hardness: `1.5`
- Young's Modulus ($E$): `9.3 GPa` | Poisson's Ratio ($
u$): `0.33`
- Coulomb Friction ($\mu$): `0.05` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `600.0 J`
- Thermal Conductivity ($k$): `2.22 W/(m·K)` | Specific Heat ($c_p$): `2090.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `silk_touch_pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[0.85, 0.92, 0.98]`
- Microfacet Roughness ($lpha$): `0.08` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.31` | Transmittance ($	au$): `0.92`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `translucent_dielectric`

---
#### `cryo.packed_ice` — Compacted Glacial Firn / Packed Ice
* **Description:** Sintered and compressed granular ice crystals depleted of air pores, preventing rapid thermal melting.
* **Archetypal Provenance:** Minecraft (Packed Ice), Universal Glaciology

**Physical Constitutive Parameters:**
- Density ($ho$): `900.0 kg/m^3`
- Mohs Hardness: `2.0`
- Young's Modulus ($E$): `8.8 GPa` | Poisson's Ratio ($
u$): `0.32`
- Coulomb Friction ($\mu$): `0.03` | Restitution ($e$): `0.25`
- Blast Fracture Threshold: `1200.0 J`
- Thermal Conductivity ($k$): `2.1 W/(m·K)` | Specific Heat ($c_p$): `2100.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `subsurface_scattering_dielectric` (Closure: `BSDF_BSSRDF_DIPOLE`)
- Base Albedo (Linear sRGB): `[0.78, 0.88, 0.96]`
- Microfacet Roughness ($lpha$): `0.15` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.315` | Transmittance ($	au$): `0.45`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `subsurface_dielectric`

---
#### `cryo.blue_ice` — High-Density Blue Glacial Ice
* **Description:** Extremely compressed basal glacial ice with structural bubble exclusion and minimal surface friction.
* **Archetypal Provenance:** Minecraft (Blue Ice), CAD Cryology

**Physical Constitutive Parameters:**
- Density ($ho$): `917.0 kg/m^3`
- Mohs Hardness: `2.5`
- Young's Modulus ($E$): `9.5 GPa` | Poisson's Ratio ($
u$): `0.31`
- Coulomb Friction ($\mu$): `0.01` | Restitution ($e$): `0.3`
- Blast Fracture Threshold: `1800.0 J`
- Thermal Conductivity ($k$): `2.3 W/(m·K)` | Specific Heat ($c_p$): `2050.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `subsurface_scattering_dielectric` (Closure: `BSDF_BSSRDF_DIPOLE`)
- Base Albedo (Linear sRGB): `[0.55, 0.75, 0.98]`
- Microfacet Roughness ($lpha$): `0.05` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.32` | Transmittance ($	au$): `0.6`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `subsurface_dielectric`

---
#### `cryo.snow` — Consolidated Snow Pack
* **Description:** Sintered ice crystal matrix with high porosity, high solar albedo, and insulating thermal resistance.
* **Archetypal Provenance:** Minecraft (Snow Block), Terraria (Snow Block), Universal Meteorology

**Physical Constitutive Parameters:**
- Density ($ho$): `350.0 kg/m^3`
- Mohs Hardness: `0.5`
- Young's Modulus ($E$): `0.05 GPa` | Poisson's Ratio ($
u$): `0.25`
- Coulomb Friction ($\mu$): `0.2` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `250.0 J`
- Thermal Conductivity ($k$): `0.15 W/(m·K)` | Specific Heat ($c_p$): `2090.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.98, 0.98, 0.98]`
- Microfacet Roughness ($lpha$): `0.95` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.3` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `cryo.powder_snow` — Unconsolidated Powder Snow
* **Description:** Loose, high-porosity dendritic snow crystals unable to support mechanical loads, producing sinking.
* **Archetypal Provenance:** Minecraft (Powder Snow), Universal Avalanche Mechanics

**Physical Constitutive Parameters:**
- Density ($ho$): `100.0 kg/m^3`
- Mohs Hardness: `0.1`
- Young's Modulus ($E$): `0.001 GPa` | Poisson's Ratio ($
u$): `0.1`
- Coulomb Friction ($\mu$): `0.85` | Restitution ($e$): `0.0`
- Blast Fracture Threshold: `50.0 J`
- Thermal Conductivity ($k$): `0.06 W/(m·K)` | Specific Heat ($c_p$): `2090.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `True` | Flammable: `False`
- Optimal Harvest Tool: `bucket`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.99, 0.99, 1.00]`
- Microfacet Roughness ($lpha$): `0.98` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.25` | Transmittance ($	au$): `0.1`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `cryo.permafrost` — Frozen Lithic Cryosol / Permafrost
* **Description:** Soil, gravel, or fractured rock permanently cemented by ground ice at temperatures below 273.15 K.
* **Archetypal Provenance:** CAD Geotechnical/Cryopedology

**Physical Constitutive Parameters:**
- Density ($ho$): `1950.0 kg/m^3`
- Mohs Hardness: `4.5`
- Young's Modulus ($E$): `25.0 GPa` | Poisson's Ratio ($
u$): `0.28`
- Coulomb Friction ($\mu$): `0.5` | Restitution ($e$): `0.15`
- Blast Fracture Threshold: `4500.0 J`
- Thermal Conductivity ($k$): `2.5 W/(m·K)` | Specific Heat ($c_p$): `1200.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.45, 0.42, 0.40]`
- Microfacet Roughness ($lpha$): `0.85` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.48` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---

### 9. Sediments, Carbonates & Soluble Minerals
#### `mineral.salt` — Halite / Rock Salt
* **Description:** Isometric ionic crystal composed of sodium chloride (NaCl); highly soluble in water, depresses ice melting point.
* **Archetypal Provenance:** Universal Chemical/Culinary Mineralogy

**Physical Constitutive Parameters:**
- Density ($ho$): `2160.0 kg/m^3`
- Mohs Hardness: `2.5`
- Young's Modulus ($E$): `40.0 GPa` | Poisson's Ratio ($
u$): `0.25`
- Coulomb Friction ($\mu$): `0.5` | Restitution ($e$): `0.4`
- Blast Fracture Threshold: `2500.0 J`
- Thermal Conductivity ($k$): `6.5 W/(m·K)` | Specific Heat ($c_p$): `880.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `dielectric_specular` (Closure: `BSDF_DIELECTRIC_TRANSMISSIVE`)
- Base Albedo (Linear sRGB): `[0.96, 0.96, 0.97]`
- Microfacet Roughness ($lpha$): `0.12` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.544` | Transmittance ($	au$): `0.85`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `refractive_dielectric`

---
#### `mineral.sulfur` — Sulfur / Brimstone
* **Description:** Bright yellow orthorhombic non-metallic crystal with low melting point (388.36 K), combustible with blue flame.
* **Archetypal Provenance:** Universal Energetics/Chemical Precursors

**Physical Constitutive Parameters:**
- Density ($ho$): `2070.0 kg/m^3`
- Mohs Hardness: `2.0`
- Young's Modulus ($E$): `15.0 GPa` | Poisson's Ratio ($
u$): `0.3`
- Coulomb Friction ($\mu$): `0.4` | Restitution ($e$): `0.2`
- Blast Fracture Threshold: `2000.0 J`
- Thermal Conductivity ($k$): `0.205 W/(m·K)` | Specific Heat ($c_p$): `710.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `True`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.92, 0.82, 0.15]`
- Microfacet Roughness ($lpha$): `0.6` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.95` | Transmittance ($	au$): `0.05`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `mineral.gypsum` — Gypsum / Hydrous Calcium Sulfate
* **Description:** Soft sulfate mineral capable of thermal calcination into plaster of Paris.
* **Archetypal Provenance:** Universal Civil/Masonry Mineralogy

**Physical Constitutive Parameters:**
- Density ($ho$): `2310.0 kg/m^3`
- Mohs Hardness: `2.0`
- Young's Modulus ($E$): `12.0 GPa` | Poisson's Ratio ($
u$): `0.33`
- Coulomb Friction ($\mu$): `0.45` | Restitution ($e$): `0.1`
- Blast Fracture Threshold: `2200.0 J`
- Thermal Conductivity ($k$): `0.17 W/(m·K)` | Specific Heat ($c_p$): `1090.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `False` | Flammable: `False`
- Optimal Harvest Tool: `pickaxe`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.90, 0.88, 0.86]`
- Microfacet Roughness ($lpha$): `0.55` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.52` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---
#### `mineral.ash` — Combustion / Volcanic Ash
* **Description:** Fine particulate mineral residue of pulverized volcanic rock or completed vegetative pyrolysis.
* **Archetypal Provenance:** Universal Geology/Civil Cement

**Physical Constitutive Parameters:**
- Density ($ho$): `750.0 kg/m^3`
- Mohs Hardness: `1.0`
- Young's Modulus ($E$): `0.01 GPa` | Poisson's Ratio ($
u$): `0.25`
- Coulomb Friction ($\mu$): `0.5` | Restitution ($e$): `0.05`
- Blast Fracture Threshold: `150.0 J`
- Thermal Conductivity ($k$): `0.12 W/(m·K)` | Specific Heat ($c_p$): `800.0 J/(kg·K)`
- Kinematic Gravity (Falling Block): `True` | Flammable: `False`
- Optimal Harvest Tool: `shovel`

**Optical Appearance & Closure Parameters:**
- BSDF Model: `burley_diffuse` (Closure: `BSDF_BURLEY`)
- Base Albedo (Linear sRGB): `[0.35, 0.35, 0.35]`
- Microfacet Roughness ($lpha$): `0.98` | Metallic Fraction ($m$): `0.0`
- Index of Refraction ($n$): `1.5` | Transmittance ($	au$): `0.0`
- Radiative Emission ($L_e$): `0.0 cd/m^2`
- Hypergraph Layering Topology: `single_diffuse`

---


## 4. Hypergraph Projection ($\mathcal{H} = (E, R, I, ho)$)

Every material instance in this catalog projects into SCR's canonical hypergraph:
1. **Entity Element ($e_{\text{mat}} \in E$)**: Uniquely identified by `SCR-LIB-MATERIAL-<ID>`.
2. **Physical State Element ($e_{\text{phys}} \in E$)**: Encapsulates constitutive tensors and fracture thresholds.
3. **Optical State Element ($e_{\text{opt}} \in E$)**: Encapsulates BSDF/EDF/VDF shading closures and parameter buffers.
4. **Constitutive-Optical Duality Hyperedge ($r_{\text{dual}} \in R$)**: Multi-way hyperedge binding $(e_{\text{mat}}, e_{\text{phys}}, e_{\text{opt}})$ preserving energy conservation across mechanical work, thermal dissipation, and emitted radiance.
