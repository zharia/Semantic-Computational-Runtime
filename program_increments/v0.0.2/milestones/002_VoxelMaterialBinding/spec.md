# Milestone 002 Specification: Voxel Material Binding & STC Transition Engine

**Document:** `program_increments/v0.0.2/milestones/002_VoxelMaterialBinding/spec.md`  
**Milestone ID:** `SCR-PI-002-M002-SPEC`  
**Version:** 1.0.0  
**Status:** Normative Specification  
**Authority:** SCR Architectural Board  

---

## 1. Formal Mathematical Model

A discrete spatial voxel field $\mathcal{V}$ is defined over a bounded coordinate domain $\Omega \subset \mathbb{Z}^3$:

$$\mathcal{V}: \mathbf{x} \mapsto \langle \text{id}_{\text{mat}}, \rho, T, \mathbf{v}, \mathcal{S}_{\text{flags}} \rangle$$

where for every voxel coordinate $\mathbf{x} = (x, y, z) \in \Omega$:
1. $\text{id}_{\text{mat}} \in [0, 2^{16}-1]$: Canonical 16-bit discrete material index mapped bijectively to `SCR-LIB-MATERIAL-<ID>`.
2. $\rho \in \mathbb{R}^+$: Effective mass density ($\text{kg/m}^3$), conforming to the material's constitutive density contract.
3. $T \in \mathbb{R}^+$: Thermodynamic local temperature ($\text{K}$).
4. $\mathbf{v} \in \mathbb{R}^3$: Kinematic velocity vector ($\text{m/s}$).
5. $\mathcal{S}_{\text{flags}} \in \{0, 1\}^8$: Bitmask flags for kinematic states (`is_falling_block`, `is_source_fluid`, `is_ignited`, `is_supported`).

---

## 2. Topological Neighborhood Operators

Per [`lib/303_Topology/Adjacency/101_definition.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/303_Topology/Adjacency/101_definition.md), neighborhood adjacency is a topological relation independent of storage format:

1. **Von Neumann 6-Neighborhood ($\mathcal{N}_6(\mathbf{x})$)**:
   $$\mathcal{N}_6(\mathbf{x}) = \{ \mathbf{x} \pm \mathbf{e}_1, \mathbf{x} \pm \mathbf{e}_2, \mathbf{x} \pm \mathbf{e}_3 \}$$
   Governs direct face-sharing fluid flow, thermal conduction quenching, and hydraulic cementation.
2. **Moore 26-Neighborhood ($\mathcal{N}_{26}(\mathbf{x})$)**:
   $$\mathcal{N}_{26}(\mathbf{x}) = \{ \mathbf{x} + \mathbf{d} \mid \mathbf{d} \in \{-1, 0, 1\}^3 \setminus \{\mathbf{0}\} \}$$
   Governs gas diffusion, atmospheric patination, flame propagation, and moisture percolation.
3. **Gravitational Directional Adjacency ($\mathcal{N}_{\text{down}}(\mathbf{x})$)**:
   $$\mathcal{N}_{\text{down}}(\mathbf{x}) = \mathbf{x} - \mathbf{e}_z$$
   Governs discrete Mohr-Coulomb falling block transposition when the downward voxel void condition holds:
   $$\text{id}_{\text{mat}}(\mathcal{N}_{\text{down}}(\mathbf{x})) \in \{\text{air}, \text{gas.*}\}$$

---

## 3. STC Transition Operator Execution Semantics

The transition engine computes synchronous or asynchronous state updates:

$$\mathcal{V}^{t+1}(\mathbf{x}) = \tau_{\text{STC}}\left(\mathcal{V}^t(\mathbf{x}), \{\mathcal{V}^t(\mathbf{x}') \mid \mathbf{x}' \in \mathcal{N}(\mathbf{x})\}\right)$$

Every transition strictly evaluates:
- **Activation condition**: Temperature thresholds ($T \ge T_{\text{threshold}}$), required adjacent reactants, or mechanical stress.
- **Outcome assignment**: Replacement of primary voxel material with target outcome material.
- **Byproduct generation**: Spawning of fluid/gas/thermal byproduct into adjacent vacant voxels.
- **Conservation invariants**:
  $$\sum_{\mathbf{x} \in \text{stencil}} m^{t+1}(\mathbf{x}) = \sum_{\mathbf{x} \in \text{stencil}} m^t(\mathbf{x})$$
