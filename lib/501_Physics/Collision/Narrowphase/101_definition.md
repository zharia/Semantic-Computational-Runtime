---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-PHYSICS-COLLISION-NARROWPHASE
name: Physics Collision Narrowphase

version: 0.1.0
status: operational

created: 2026-09-17
updated: 2026-09-17

parent: SCR-LIB-PHYSICS-COLLISION
authority: SCR
domain: semantic-library
---

# SCR Physics: Collision Narrowphase

## Summary
Exact geometrical distance determination, contact manifold generation, separating axis evaluation, and deep penetration resolution between candidate pairs of physical bodies.

---

## 1. Semantic Definition
**Narrowphase Collision Detection** evaluates the exact distance, contact points, contact normal vector $\hat{n}$, and penetration depth $d$ between pairs of geometric bodies $A$ and $B$.

For convex shapes, the interaction is characterized by the Minkowski Difference $A \ominus B = \{a - b \mid a \in A, b \in B\}$:
- Disjoint: The origin $\mathbf{0} \notin (A \ominus B)$. Minimum distance evaluated via the **Gilbert-Johnson-Keerthi (GJK)** algorithm using support mappings $S_A(v) = \arg\max_{a \in A} (a \cdot v)$.
- Intersecting: The origin $\mathbf{0} \in (A \ominus B)$. Penetration vector and minimal translational distance (MTD) evaluated via the **Expanding Polytope Algorithm (EPA)**.

## 2. Invariants & Normative Rules
- **NARROWPHASE-INV-001 (Separating Plane Normal)**: The contact normal $\hat{n}$ must point outward from body $B$ into body $A$, satisfying $\|\hat{n}\| = 1.0$.
- **NARROWPHASE-INV-002 (Minimal Translational Vector)**: For penetrating bodies ($d < 0$), moving body $A$ by $-d \cdot \hat{n}$ places $A$ and $B$ in osculating contact without penetration.
- **NARROWPHASE-INV-003 (Contact Manifold Persistency)**: Contact points are maintained in a 4-point persistent manifold to ensure stable multi-point stacking and resting contact without numerical jitter.

## 3. Relationships
- **Parent**: `lib/501_Physics/Collision`
- **lib/501_Physics/Contact**: Consumes narrowphase contact manifolds to build physical non-penetration constraints.
- **lib/302_Geometry/ConvexHull**: Supplies support mapping functions $S(v)$ across polyhedral and implicit primitives.
