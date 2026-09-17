---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-PHYSICS-COLLISION-RAYCAST
name: Physics Collision Raycast

version: 0.1.0
status: operational

created: 2026-09-17
updated: 2026-09-17

parent: SCR-LIB-PHYSICS-COLLISION
authority: SCR
domain: semantic-library
---

# SCR Physics: Collision Raycast & Convex Sweep

## Summary
Continuous linear trajectory queries against the physical collision world, resolving earliest intersection parameter $t \in [0, 1]$, world-space intersection point $\vec{x}_{\text{hit}}$, and outward surface normal $\hat{n}_{\text{hit}}$.

---

## 1. Mathematical Formulation
A ray query is parameterized by origin $\vec{x}_0$ and destination $\vec{x}_1$:
$$\vec{r}(t) = \vec{x}_0 + t(\vec{x}_1 - \vec{x}_0), \quad t \in [0, 1]$$

The query evaluates the infimum parameter value $t^*$:
$$t^* = \inf \{ t \in [0, 1] \mid \vec{r}(t) \cap \mathcal{B} \neq \emptyset \}$$

If $t^* \le 1$, the intersection coordinates and outward surface normal are returned:
$$\vec{x}_{\text{hit}} = \vec{r}(t^*), \quad \hat{n}_{\text{hit}} = \nabla \Phi_{\mathcal{B}}(\vec{x}_{\text{hit}})$$

## 2. Invariants & Normative Rules
- **RAYCAST-INV-001 (Earliest Hit Monotonicity)**: In closest-hit raycasting, $t^*$ must be the strictly minimal valid parameter along the ray segment.
- **RAYCAST-INV-002 (Unit Normal Normalization)**: The returned surface normal must be normalized: $\|\hat{n}_{\text{hit}}\| = 1.0 \pm 10^{-5}$.
- **RAYCAST-INV-003 (Fraction Boundedness)**: $t^*$ must strictly satisfy $0.0 \le t^* \le 1.0$.

## 3. Relationships
- **Parent**: `lib/501_Physics/Collision`
- **lib/603_Perception/RaySensor**: Sensor domain representation for lidar, rangefinders, and line-of-sight perception.
- **lib/605_Interaction/Cursor**: Screen-to-world ray picking and physical tool selection.
