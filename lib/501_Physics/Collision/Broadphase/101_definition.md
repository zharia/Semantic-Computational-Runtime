---
document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-PHYSICS-COLLISION-BROADPHASE
name: Physics Collision Broadphase

version: 0.1.0
status: operational

created: 2026-09-17
updated: 2026-09-17

parent: SCR-LIB-PHYSICS-COLLISION
authority: SCR
domain: semantic-library
---

# SCR Physics: Collision Broadphase

## Summary
Spatial partitioning, hierarchical bounding volume tree indexing, and conservative pair generation to reduce pairwise proximity checks from $O(N^2)$ to $O(N \log N)$ or $O(N)$.

---

## 1. Semantic Definition
**Broadphase Collision Detection** is the spatial filtering stage of physical collision queries. It maps geometry in configuration space $\mathbb{R}^3$ to spatial acceleration structures—such as Dynamic Bounding Volume Trees (DBVT), Axis-Aligned Bounding Box (AABB) hierarchies, or Sweep-and-Prune (SAP) intervals.

Broadphase operations MUST guarantee **conservative completeness**: no two bodies that intersect in Euclidean space may be omitted from the set of candidate overlapping pairs $\mathcal{P}_{\text{candidates}}$.

$$\forall A, B \in \mathcal{B}: \quad (A \cap B \neq \emptyset) \implies ((A, B) \in \mathcal{P}_{\text{candidates}})$$

## 2. Invariants & Normative Rules
- **BROADPHASE-INV-001 (Conservative Non-Exclusion)**: False negatives are strictly prohibited. Every true geometric intersection must produce an active overlapping pair.
- **BROADPHASE-INV-002 (Quantized Margin Consistency)**: Bounding volumes must expand by a positive collision margin $\delta > 0$ to accommodate continuous velocity bounds between discrete timesteps.
- **BROADPHASE-INV-003 (Layer Filtering Semantics)**: Collision group and mask bitfields represent strict Boolean filtering logic $\text{Mask}_A \wedge \text{Group}_B \neq 0$.

## 3. Relationships
- **Parent**: `lib/501_Physics/Collision`
- **lib/302_Geometry/BoundingVolume**: Provides bounding boxes (AABB), bounding spheres, and oriented bounding boxes (OBB).
- **lib/203_Graph/Hypergraph**: Encodes the dynamic spatial adjacency hypergraph of interacting body pairs.
