---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-PHYSICS-COLLISION-IMPACT
name: Physics Collision Impact

version: 0.1.0
status: operational

created: 2026-09-17
updated: 2026-09-17

parent: SCR-LIB-PHYSICS-COLLISION
authority: SCR
domain: semantic-library
---

# SCR Physics: Collision Impact & Impulsive Dynamics

## Summary
Impulsive momentum transfer, restitution rebound, Coulomb friction limits, and kinetic energy dissipation during collision between colliding bodies.

---

## 1. Physical Formulation

When two bodies $A$ and $B$ collide at contact point $\vec{r}$, the relative contact velocity is:
$$\vec{v}_{\text{rel}} = (\vec{v}_A + \vec{\omega}_A \times \vec{r}_A) - (\vec{v}_B + \vec{\omega}_B \times \vec{r}_B)$$

### Normal Impulse (Restitution)
The normal velocity component $v_n = \vec{v}_{\text{rel}} \cdot \hat{n}$. The normal impulse magnitude $J_n$ satisfies:
$$J_n = \frac{-(1 + e) v_n}{m_A^{-1} + m_B^{-1} + (\mathbf{I}_A^{-1}(\vec{r}_A \times \hat{n}) \times \vec{r}_A + \mathbf{I}_B^{-1}(\vec{r}_B \times \hat{n}) \times \vec{r}_B) \cdot \hat{n}}$$
where $e \in [0, 1]$ is the combined coefficient of restitution:
$$e = \sqrt{e_A \cdot e_B}$$

### Tangential Friction Impulse
Frictional impulse $\vec{J}_t$ lies in the contact plane orthogonal to $\hat{n}$ and is bounded by the Coulomb friction cone:
$$\|\vec{J}_t\| \le \mu J_n$$
where $\mu = \sqrt{\mu_A \cdot \mu_B}$ is the combined friction coefficient.

## 2. Invariants & Normative Rules
- **IMPACT-INV-001 (Energy Conservation Upper Bound)**: Kinetic energy cannot be generated during collision: $E_k(t^+) \le E_k(t^-)$.
- **IMPACT-INV-002 (Non-Negative Normal Impulse)**: Normal impulse must be non-adhesive: $J_n \ge 0$.
- **IMPACT-INV-003 (Coulomb Complementarity)**: Tangential friction strictly opposes relative sliding velocity direction: $\vec{J}_t \parallel -\vec{v}_{\text{rel}, t}$.

## 3. Relationships
- **Parent**: `lib/501_Physics/Collision`
- **lib/501_Physics/Momentum**: Linear and angular momentum conservation $\Delta \vec{p} = \vec{J}$, $\Delta \vec{L} = \vec{r} \times \vec{J}$.
- **lib/501_Physics/Friction**: Static, dynamic, and rolling resistance laws.
