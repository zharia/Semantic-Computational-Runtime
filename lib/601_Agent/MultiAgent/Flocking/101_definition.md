# Semantic Domain: Multi-Dimensional Flocking & Swarm Semantics

**Domain ID:** `SCR-DOM-AGENT-FLOCKING`  
**Classification:** `Agent / MultiAgent / Flocking`  
**Version:** `1.0.0`  
**Authority:** Normative Architecture Specification

---

## 1. Mathematical Formalism

A Boid Flocking System is defined as an ensemble of $M$ autonomous agents operating on an $N$-dimensional Euclidean spatial manifold $\mathcal{M} \subseteq \mathbb{R}^N$ ($N \in \{2, 3, 4\}$):

$$\mathcal{B} = \{ b_i = (\mathbf{x}_i, \mathbf{v}_i, \mathbf{a}_i, \sigma_i, \mu_i) \mid i \in [1, M] \}$$

Where:
- $\mathbf{x}_i \in \mathbb{R}^N$: Spatial coordinate in $N$-dimensional space.
- $\mathbf{v}_i \in \mathbb{R}^N$: Kinematic velocity vector subject to $[\lVert\mathbf{v}_i\rVert_{\text{min}}, \lVert\mathbf{v}_i\rVert_{\text{max}}]$.
- $\mathbf{a}_i \in \mathbb{R}^N$: Net steering acceleration bounded by $\lVert\mathbf{a}_i\rVert \le a_{\text{max}}$.
- $\sigma_i \in \mathcal{S}$: Species archetype defining physiological, perceptual, and morphological constants.
- $\mu_i \in \mathcal{M}_{\text{mode}}$: Dynamic behavioral state (`CRUISING`, `FORAGING`, `SWARMING`, `PANIC_SCATTER`, `HYPER_SLICING`).

---

## 2. Extended $N$-Dimensional Generalized Reynolds Force Vectors

For each agent $b_i$, the total steering acceleration $\mathbf{a}_i(t)$ is computed by aggregating generalized vector fields over perceptual hyper-spheres $B_N(\mathbf{x}_i, r)$:

$$\mathbf{a}_i = \sum_{k} w_k \cdot \mathbf{F}_k(\mathbf{x}_i, \mathbf{v}_i, \mathcal{N}_i)$$

### 2.1 Separation Force ($\mathbf{F}_{\text{sep}} \in \mathbb{R}^N$)
Prevents crowding and spatial collisions with inverse-distance power scaling:
$$\mathbf{F}_{\text{sep}}(b_i) = \sum_{j \in \mathcal{N}_{\text{sep}}(i)} \frac{\mathbf{x}_i - \mathbf{x}_j}{\lVert\mathbf{x}_i - \mathbf{x}_j\rVert^2}$$

### 2.2 Alignment Force ($\mathbf{F}_{\text{ali}} \in \mathbb{R}^N$)
Matches velocity orientation with local neighborhood consensus:
$$\mathbf{F}_{\text{ali}}(b_i) = \frac{1}{|\mathcal{N}_{\text{ali}}(i)|} \sum_{j \in \mathcal{N}_{\text{ali}}(i)} \mathbf{v}_j - \mathbf{v}_i$$

### 2.3 Cohesion Force ($\mathbf{F}_{\text{coh}} \in \mathbb{R}^N$)
Steers towards the center of mass of neighboring flock members:
$$\mathbf{F}_{\text{coh}}(b_i) = \left( \frac{1}{|\mathcal{N}_{\text{coh}}(i)|} \sum_{j \in \mathcal{N}_{\text{coh}}(i)} \mathbf{x}_j \right) - \mathbf{x}_i$$

### 2.4 Environmental Habitat Attractor ($\mathbf{F}_{\text{env}} \in \mathbb{R}^N$)
Attracts species towards their ecological affinity centroid (e.g. coral lagoon, thermal updraft column, coastal dune):
$$\mathbf{F}_{\text{env}}(b_i) = \mathbf{C}_{\text{habitat}} - \mathbf{x}_i$$

### 2.5 Obstacle & Hazard Avoidance ($\mathbf{F}_{\text{obs}} \in \mathbb{R}^N$)
Repels agents from physical boundaries, terrain sdf gradients $\nabla \Phi(\mathbf{x})$, and dangerous thermal zones (molten lava flows):
$$\mathbf{F}_{\text{obs}}(b_i) = \mathbf{n}_{\text{boundary}} \cdot \exp\left( -\frac{d_{\text{surface}}}{\lambda} \right)$$

---

## 3. Dimensional Projection Semantics ($\mathbb{R}^4 \to \mathbb{R}^3$)

For 4-dimensional hyper-boids ($N=4$), positions $\mathbf{x} = (x, y, z, w)^T$ are projected into physical 3D render space via dynamic hyperplane slicing:
$$\pi_{4 \to 3}(\mathbf{x}, t) = \begin{pmatrix} x \\ y \\ z \end{pmatrix}, \quad \text{Visibility Weight } \alpha = \exp\left( -\frac{(w - w_0(t))^2}{2 \sigma_w^2} \right)$$
Where $w_0(t) = A_w \sin(\omega_w t)$ represents the slicing manifold translation through the 4th spatial dimension.

---

## 4. Species Taxonomy

| Species Archetype | Dimension | Physical Medium | Primary Flocking Dynamics |
| :--- | :--- | :--- | :--- |
| **Coastal Tropic Tern** | $\mathbb{R}^3$ | Aerial Atmosphere | Soaring thermals, high alignment, periodic diving attacks |
| **Coral Reef Tang** | $\mathbb{R}^3$ | Pelagic Ocean | Tight synchronous schooling, shallow reef containment |
| **Volcanic Ember Moth** | $\mathbb{R}^3$ | Ash & Magma Chimney | Toroidal vortex swarming, thermal updraft affinity |
| **Shoreline Sandpiper** | $\mathbb{R}^2$ / $\mathbb{R}^{2.5}$ | Beach Sand Dune | Planar herd foraging, surf line retreat/advance |
| **Hyperspatial Luminary** | $\mathbb{R}^4$ | 4D Manifold | Hypersphere cohesion, 4-vector alignment, phase pulsing |
