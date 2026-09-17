# Milestone 001 Specification: Universal Material Library & Semantic Interaction Expansion

**Document:** `program_increments/v0.0.2/milestones/001_MaterialLibraryExpansion/spec.md`  
**Milestone ID:** `SCR-PI-002-M001-SPEC`  
**Version:** 1.0.0  
**Status:** Normative Specification  
**Authority:** SCR Architecture Board  
**Target Domain:** Semantic Library (`lib/A01_Render/Material`, `lib/501_Physics/Material`, `lib/303_Topology/Adjacency`)  

---

## 1. Scope & Semantic Foundation

This specification governs the expansion of universal materials and their dynamic computational interactions under Program Increment `v0.0.2`.

Per **Rule 1** (*Semantics are authoritative*), **Rule 2** (*Implementation does not define meaning*), and **Rule 10** (*Specify before implementing when semantic behavior is new*), every material is a first-class declarative entity within the SCR Semantic Field.

### 1.1 The Dual-Contract Formalism

Every material $\mathcal{M}$ is defined as a tuple:

$$\mathcal{M} = \langle \mathcal{C}_{\text{phys}}, \mathcal{C}_{\text{opt}}, \mathcal{C}_{\text{kin}} \rangle$$

#### Physical Constitutive Contract ($\mathcal{C}_{\text{phys}}$)
$$\mathcal{C}_{\text{phys}} = \langle \rho, H_{\text{mohs}}, E, \nu, \mu, e, J_{\text{blast}}, k, c_p, g_{\text{kin}}, T_{\text{flam}}, T_{\text{melt}}, \mathcal{T}_{\text{tool}} \rangle$$
- $\rho \in \mathbb{R}^+$: Mass density ($\text{kg/m}^3$).
- $H_{\text{mohs}} \in [0.0, 10.0]$: Mohs scratch hardness.
- $E \in \mathbb{R}^+$: Young's elastic modulus ($\text{GPa}$).
- $\nu \in (-1.0, 0.5]$: Poisson's ratio (dimensionless).
- $\mu \in [0.0, \infty)$: Static/Coulomb coefficient of friction.
- $e \in [0.0, 1.0]$: Coefficient of restitution (elastic resilience).
- $J_{\text{blast}} \in \mathbb{R}^+$: Blast fracture threshold energy ($\text{J}$).
- $k \in \mathbb{R}^+$: Thermal conductivity ($\text{W/(m}\cdot\text{K)}$).
- $c_p \in \mathbb{R}^+$: Specific isobaric heat capacity ($\text{J/(kg}\cdot\text{K)}$).
- $g_{\text{kin}} \in \{\text{true}, \text{false}\}$: Susceptibility to kinematic gravitational collapse if unsupported.
- $T_{\text{flam}} \in \{\text{true}, \text{false}\}$: Flammability flag under thermal ignition.
- $T_{\text{melt}} \in \mathbb{R}^+ \cup \{\infty\}$: Thermodynamic melting/phase-change temperature ($\text{K}$).
- $\mathcal{T}_{\text{tool}} \in \text{ToolClass}$: Optimal harvest tool archetype (`shovel`, `pickaxe`, `axe`, `shears`, `bucket`, `none`).

#### Optical Appearance Contract ($\mathcal{C}_{\text{opt}}$)
$$\mathcal{C}_{\text{opt}} = \langle \mathcal{B}, \mathbf{a}_{\text{srgb}}, \alpha, m, n, \kappa, \tau, L_e, \mathcal{T}_{\text{layer}} \rangle$$
- $\mathcal{B} \in \text{BSDFModel}$: Canonical scattering model (`burley_diffuse`, `conductor_fresnel_ggx`, `dielectric_specular`, `subsurface_scattering_dielectric`, `microfiber_sheen`, `two_sided_thin_surface_translucent`, `dielectric_refractive_volume`, `emissive_blackbody_fluid`).
- $\mathbf{a}_{\text{srgb}} \in [0.0, 1.0]^3$: Linear sRGB base albedo reflectance triple.
- $\alpha \in [0.0, 1.0]$: Microfacet distribution roughness parameter.
- $m \in [0.0, 1.0]$: Metallic parameter (conductor vs. dielectric blend).
- $n \in [1.0, \infty)$: Real refractive index.
- $\kappa \in [0.0, \infty)$: Imaginary extinction coefficient for conductors (Fresnel $k$).
- $\tau \in [0.0, 1.0]$: Spectral volume transmittance.
- $L_e \in \mathbb{R}^{\ge 0}$: Radiative blackbody/phosphorescent emission ($\text{cd/m}^2$).
- $\mathcal{T}_{\text{layer}} \in \text{LayerTopology}$: Hypergraph layering topology (`single_diffuse`, `homogeneous_metal`, `refractive_dielectric`, `coated_diffuse`, `subsurface_dielectric`).

---

## 2. The Semantic Transition Calculus (STC) for Reactions

Material interactions are formalized as typed transition operators:

$$\tau_{\text{react}}: \mathcal{S}_{\text{mat}} \times \mathcal{C}_{\text{adj}} \xrightarrow{K} \mathcal{S}'_{\text{mat}} + \mathcal{S}_{\text{byproduct}}$$

where:
1. **$\mathcal{S}_{\text{mat}}$**: Primary material state undergoing transition.
2. **$\mathcal{C}_{\text{adj}}$**: Topological neighborhood context defined across discrete connectivity graphs:
   - $\mathcal{N}_6$: Face-sharing von Neumann neighborhood (direct thermal contact, fluid conduction, quenching).
   - $\mathcal{N}_{26}$: Moore neighborhood (percolative moisture diffusion, flame front propagation).
   - $\mathcal{N}_{\text{down}}$: Downward directional adjacency $z-1$ (kinematic gravity evaluation).
3. **$K$**: Non-negotiable physical conservation constraints:
   - **Mass Conservation**: $\sum \rho_i V_i = \sum \rho'_j V'_j$.
   - **Enthalpy Balance**: Latent heat absorption or dissipation must be accounted for across phase transitions.
   - **Chemical Stoichiometric Conservation**: Atomic species (Fe, Cu, C, Si, O) cannot be created or destroyed.

---

## 3. Master Taxa Expansion Plan

The expansion increases the catalog from 40 materials to 90+ materials across 8 distinct taxonomic branches:

1. **`cryo.*` (Cryogenic & Volatile Phases)**: Ice, packed ice, blue ice, snow, powder snow, permafrost.
2. **`rock.*` & `mineral.*` (Earth Sediments, Carbonates & Soluble Salts)**: Limestone, calcite, tuff, pumice, peat, podzol, halite, sulfur, gypsum, ash.
3. **`ore.*` & `metal.*` (Raw Ores, Transition Metals & Foundational Alloys)**: Raw iron/copper/bauxite/gold ores, bronze, brass, aluminum, titanium, zinc, tungsten.
4. **`gem.*` & `mineral.phosphor` (Luminescent, Dielectric & Piezoelectric Crystals)**: Lapis lazuli, topaz, jade, amber, phosphorescent crystals.
5. **`organic.*` & `botanical.*` (Complex Biomaterials, Elastomers & Organics)**: Leather, chitin, natural rubber, wax, charcoal, moss, mycelium, cactus.
6. **`fluid.*` & `gas.*` (Reactive Fluids, Solutes & Atmospheric Gases)**: Petroleum oil, mineral acid, steam, air, smoke, methane.
7. **`synthetic.*` & `granular.*` (Structural Composites, Synthetics & Energetics)**: Concrete powder, mortar, aerogel, plastic, silicon, high explosives.
8. **`reaction.*` (Semantic Transition Calculus Reactions)**: 25+ new formal transition rules encompassing phase changes, oxidation, smelting, blast dynamics, and fluid stratification.

---

## 4. Conformance & Verification Requirements

Every sprint implementation must fulfill the following verification rules:
- **Rule V1 (Schema Validity)**: Every new material entry must pass JSONSchema validation with zero missing fields.
- **Rule V2 (Thermodynamic Physical Validity)**:
  - Densities must be positive: $\rho > 0$.
  - Poisson's ratio must satisfy $-1.0 < \nu \le 0.5$.
  - Mohs hardness must satisfy $0.0 \le H_{\text{mohs}} \le 10.0$.
  - Albedo components must satisfy $a_r, a_g, a_b \in [0.0, 1.0]$.
  - Microfacet roughness must satisfy $\alpha \in [0.0, 1.0]$.
- **Rule V3 (Reaction Conservations)**: Every reaction defined in `material_reactions.json` must declare explicit conservation invariants (`mass_conservation`, `stoichiometric_species_conservation`, `enthalpy_conservation`).
