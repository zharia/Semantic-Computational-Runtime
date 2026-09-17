---
document: 101_definition
document_type: normative_provider_definition
schema_version: 1.0.0

id: SCR-PRV-PHYSICS-BULLET3
name: Bullet3 Physics Provider

version: 0.1.0
status: operational

created: 2026-09-17
updated: 2026-09-17

domain: physics
subdomain: dynamics, collision, contact
authority: SCR
---

# Bullet3 Physics Provider

## Summary
Execution provider adapting the Bullet3 Open-Source Physics Engine (3.25) to satisfy SCR contracts for Collision Detection, Narrowphase GJK/EPA, Raycasting, Multi-Body Dynamics, and Impact Impulse resolution.

---

## 1. Provider Identity & Authority
- **Provider ID**: `bullet3`
- **External Dependency**: Bullet Physics SDK (`libBulletDynamics`, `libBulletCollision`, `libLinearMath`)
- **Authority**: Subordinate to SCR Normative Specifications in `lib/501_Physics/`. Implementation details in Bullet3 do not redefine SCR computational semantics.

## 2. Capabilities Implemented
- `[physics, collision, broadphase_dbvt]` — Dynamic Bounding Volume Tree AABB hierarchical partitioning.
- `[physics, collision, narrowphase_gjk_epa]` — GJK distance and EPA penetration depth evaluation.
- `[physics, collision, static_mesh]` — BVH triangle mesh shapes (`btBvhTriangleMeshShape`) for OpenVDB isosurfaces and terrain.
- `[physics, collision, raycast]` — Line-of-sight and continuous collision swept raycasting.
- `[physics, dynamics, rigid_body]` — 6-DOF rigid body integration with mass, inertia tensors, forces, and torques.
- `[physics, contact, sequential_impulse]` — Projected Gauss-Seidel constraint solver for restitution and Coulomb friction.

## 3. Invariant Compliance
- **PHYSICS-INV-001 (Semantic Primacy)**: SCR coordinate spaces and units (SI: meters, kilograms, seconds) are preserved across the adapter boundary.
- **PHYSICS-INV-006 (Conservation Integrity)**: Symplectic Euler integration guarantees energy bounding and momentum conservation.
