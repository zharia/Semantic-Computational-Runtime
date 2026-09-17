---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-RENDER-MATERIAL
name: Material
version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-RENDER
authority: SCR
domain: semantic-library
---

# SCR Material & Appearance Semantics

**Path:** `lib/A01_Render/Material/101_definition.md`  
**Version:** 0.1.0  
**Status:** Normative Specification  
**Parent:** [`lib/A01_Render`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render)

---

## 1. Executive Summary & Purpose

The `Material` domain provides the authoritative semantic computational definition of **materials, appearance, optical response functions, shading networks, and look development** within the Semantic Computational Runtime (SCR).

A Material is not a monolithic shader file, an execution kernel, or an XML document. Rather:

> **A Material is a declarative semantic specification governing how renderable entities (surfaces, volumes, boundaries, particles) interact with light and energy to produce perceptual manifestations.**

Per **Rule 1** (*"Semantics are authoritative"*), **Rule 2** (*"Implementation does not define meaning"*), and **Rule 18** (*"External technologies remain subordinate to SCR contracts"*), Material semantics are independent of:
* Specific shading languages (OSL, GLSL, HLSL, MSL, MDL, WGSL);
* Interchange formats (MaterialX, USD Shading, glTF);
* Hardware rasterization techniques or ray-tracing engines.

---

## 2. Mathematical Formulation

### 2.1 The Surface Scattering Integral (BSDF)
At any point $p$ on a surface with surface normal $n$, the outbound radiance $L_o(p, \omega_o)$ in direction $\omega_o$ is governed by:

$$L_o(p, \omega_o) = L_e(p, \omega_o) + \int_{\mathcal{S}^2} f_r(p, \omega_i, \omega_o) \, L_i(p, \omega_i) \, |\omega_i \cdot n| \, d\omega_i$$

where:
* $L_e(p, \omega_o)$ is the emitted radiance defined by the **Emission Distribution Function (EDF)**;
* $L_i(p, \omega_i)$ is the incident radiance arriving from direction $\omega_i$;
* $f_r(p, \omega_i, \omega_o)$ is the **Bidirectional Scattering Distribution Function (BSDF)**, combining reflection ($f_{\text{BRDF}}$) and transmission ($f_{\text{BTDF}}$);
* $|\omega_i \cdot n|$ is the geometric cosine foreshortening factor over the sphere $\mathcal{S}^2$.

### 2.2 Volumetric Radiative Transfer (VDF)
For participating media within a volume $V$, radiance evolution along path distance $s$ is governed by:

$$\frac{d L(p, \omega)}{ds} = -\sigma_t(p) L(p, \omega) + \sigma_a(p) L_e(p, \omega) + \sigma_s(p) \int_{\mathcal{S}^2} p_m(p, \omega_i, \omega) L(p, \omega_i) \, d\omega_i$$

where:
* $\sigma_a(p)$ is the absorption coefficient;
* $\sigma_s(p)$ is the scattering coefficient;
* $\sigma_t(p) = \sigma_a(p) + \sigma_s(p)$ is the total extinction coefficient;
* $p_m(p, \omega_i, \omega)$ is the phase function characterized by the **Volume Distribution Function (VDF)**.

---

## 3. Core Semantic Concepts

### 3.1 Shading Closures
SCR models distribution functions as first-class symbolic **shading closures**:
1. **BSDF Closure:** Evaluates surface scattering.
2. **EDF Closure:** Evaluates surface light emission.
3. **VDF Closure:** Evaluates volumetric scattering and phase distributions.
4. **Closure Combinators:**
   * **Sum ($\oplus$):** $C = C_1 + C_2$ (composite scattering).
   * **Scale ($\otimes$):** $C = w \cdot C_1$ (wavelength/albedo modulation, $w \in [0, 1]$).
   * **Mix ($\odot$):** $C = (1 - \alpha) C_1 + \alpha C_2$.
   * **Layer ($\Downarrow$):** Vertical dielectric-over-base layering enforcing Fresnel energy conservation:
     $$C = C_{\text{coat}} + (1 - F_{\text{coat}}) C_{\text{base}}$$

### 3.2 Shading Networks
A Shading Network is a declarative directed acyclic graph (DAG) where:
* **Nodes:** Represent pure mathematical transforms, procedural patterns, noise generators, coordinate frame projections, or closure evaluations.
* **Input Ports:** Strongly typed parameters receiving upstream values or constant values.
* **Output Ports:** Strongly typed values produced by the node.
* **Data Types:** `Boolean`, `Integer`, `Float`, `Color3`, `Color4`, `Vector2`, `Vector3`, `Vector4`, `Matrix3x3`, `Matrix4x4`, `String`, `Closure`.

### 3.3 Physical Material Model
A complete Physical Material aggregates:
* **Surface Shader:** A tree of BSDF and EDF closures bound to surface evaluation.
* **Volume Shader:** A VDF closure and absorption/scattering fields bound to interior evaluation.
* **Displacement Shader:** A scalar or vector field providing geometric relief $p' = p + d(p) \cdot n$.

### 3.4 Look Development & Assignment
* **Look:** A named, decoupled assignment state associating Materials with geometric entities and collections.
* **Property Overrides:** Context-dependent parameter overrides (e.g. weathering, wetness, damage state) applied without altering underlying material graph topology.

---

## 4. Canonical Hypergraph Projection ($\mathcal{H} = (E, R, I, \rho)$)

Every Material and Shading Network projects deterministically into SCR's canonical hypergraph:
* **Nodes $\to$ Elements:** Each shading node and closure generator is an `Element` $e \in E$.
* **Data Connections $\to$ Relations:** Each dataflow edge is a binary directed `Relation` $r \in R$.
* **Input/Output Ports $\to$ Incidences:**
  * Input port: `Incidence` with `Role = SINK`, `Direction = INCOMING`.
  * Output port: `Incidence` with `Role = SOURCE`, `Direction = OUTGOING`.
* **Closure Layering $\to$ High-Order Hyperedges:** Multi-way relations linking top closure, base closure, and layer energy invariants.
* **Material Binding $\to$ Multi-Entity Hyperedge:** Associating the surface closure, volume closure, displacement field, and target geometric boundary.

---

## 5. Subdomain Decomposition

The `Material` domain is decomposed into 12 normative subdomains:

1. [`BSDF`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/BSDF): Bidirectional Scattering Distribution Functions (diffuse, dielectric, conductor, microfacet).
2. [`EDF`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/EDF): Emission Distribution Functions (diffuse emission, spotlights, directional).
3. [`VDF`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/VDF): Volume Distribution Functions (absorption, Henyey-Greenstein phase functions).
4. [`Closure`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/Closure): First-class shading closures and composition algebra.
5. [`ShadingNetwork`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/ShadingNetwork): Dataflow DAGs, nodes, typed ports, and evaluation order.
6. [`Surface`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/Surface): Physical surface parameters (albedo, roughness, metallic, normal, clearcoat).
7. [`Volume`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/Volume): Participating media parameters (extinction, single-scattering albedo).
8. [`Displacement`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/Displacement): Geometric surface displacement and height fields.
9. [`Look`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/Look): Target-independent look assignment, collections, and variant sets.
10. [`Pattern`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/Pattern): Procedural textures, noise functions, coordinate projections.
11. [`Layering`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/Layering): Vertical material layering and energy conservation.
12. [`Property`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/Property): Optical constants, refractive index ($n, k$), and parameter bindings.

### 5.1 Normative Material Catalogs & Ontologies
- [`105_unified_materials_catalog.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/105_unified_materials_catalog.md): Authoritative catalog of universal materials distilled from voxel sandbox systems (Minecraft, Terraria) and physical/optical simulation engines.
- [`materials_catalog.json`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/materials_catalog.json): Machine-readable dual-contract parameters for simulation and rendering runtimes.
- [`docs/architecture/106_unified_materials_ontology.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/architecture/106_unified_materials_ontology.md): Architecture ontology defining the constitutive stress-strain tensors, Mohr-Coulomb granular failure, Fresnel conductor responses, and hypergraph projection.

---

## 6. The 18 Normative Invariants

* **`MATERIAL-INV-001` (Semantic Primacy):** Material semantics are authoritative over all shading languages, compilers, and interchange representations.
* **`MATERIAL-INV-002` (Energy Conservation):** Total reflected, transmitted, and absorbed energy across all wavelengths cannot exceed incident energy ($\int_{\mathcal{S}^2} f_r \le 1.0$).
* **`MATERIAL-INV-003` (Helmholtz Reciprocity):** Physically plausible non-magnetic surface reflection satisfies $f_r(\omega_i, \omega_o) = f_r(\omega_o, \omega_i)$.
* **`MATERIAL-INV-004` (Closure Decoupling):** Shading closures declare optical responses independently of illumination integration algorithms.
* **`MATERIAL-INV-005` (Type Safety):** All node graph dataflow connections require strict type compatibility or explicit type conversion.
* **`MATERIAL-INV-006` (Acyclicity):** Shading networks must form directed acyclic graphs; feedback loops are forbidden.
* **`MATERIAL-INV-007` (Layering Attenuation):** Layering a dielectric coat over a base material MUST attenuate base illumination by the Fresnel transmission factor $(1 - F_{\text{coat}})$.
* **`MATERIAL-INV-008` (Representation Independence):** A material specification remains valid whether serialized as MaterialX, USD Shading, JSON, or in-memory graph.
* **`MATERIAL-INV-009` (Target Neutrality):** Shading definitions must not encode target hardware architecture or language keywords.
* **`MATERIAL-INV-010` (Displacement Conservatism):** Surface displacement must not introduce self-intersecting manifold topology or unbounded geometric divergence.
* **`MATERIAL-INV-011` (Unit Homogeneity):** Optical properties must declare physical measurement units and reference coordinate systems.
* **`MATERIAL-INV-012` (Color Space Traceability):** Color values must declare reference color space (e.g., ACEScg, Rec.709, Linear sRGB).
* **`MATERIAL-INV-013` (Deterministic Evaluation):** For identical input parameters and incident coordinates, material evaluation produces bitwise identical results.
* **`MATERIAL-INV-014` (Identity Invariant):** Material entities, nodes, and assignments must possess valid canonical SCR semantic identifiers.
* **`MATERIAL-INV-015` (Provider Subordination):** External material engines (MaterialX, MDL) act as execution or translation providers, never semantic authorities.
* **`MATERIAL-INV-016` (Look Decoupling):** Look assignments and variant overrides must not mutate the topological structure of base material graphs.
* **`MATERIAL-INV-017` (Continuum Consistency):** Volume and surface properties evaluate consistently across continuous and discrete representations.
* **`MATERIAL-INV-018` (Hypergraph Projectability):** Every material graph must project into the SCR canonical hypergraph without information loss.
