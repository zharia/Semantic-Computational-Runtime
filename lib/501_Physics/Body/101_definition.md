# Physics Body (`SCR-PHYS-BODY`)

**Path:** `lib/501_Physics/Body/101_definition.md`  
**Parent Domain:** [`lib/501_Physics/101_definition.md`](../101_definition.md)  
**Version:** `0.1.0`  
**Status:** Normative Draft (corrected v0.0.3)  
**Authority:** SCR Architectural Group

---

## 1. Definition

A Physics Body is a semantic entity that participates in physical simulation through mass, inertia, forces, and collisions.

### v0.0.3 Correction: Body Types

Body types describe **behavioral profiles**, not lifecycle states.

| Type | Behavioral Property | NOT Lifecycle State |
|------|--------------------|--------------------|
| **Static** | Immobility constraint (provider-specific) | Not "permanent" or "fixed forever" |
| **Kinematic** | Externally driven motion, no dynamics | Not "infinite mass" |
| **Dynamic** | Full dynamics (mass, inertia, forces) | Not "always moving" |

### Static Body

A static body has an **immobility constraint**: it does not respond to forces or collisions.

- Static does NOT mean permanent. A static body can be created and destroyed.
- Static does NOT mean immovable. It means the physics engine treats it as immovable for simulation purposes.
- Static bodies can participate in collision detection (as obstacles, floors, walls).

### Kinematic Body

A kinematic body has **externally driven motion**: it moves according to prescribed velocity/position, not forces.

- Kinematic does NOT mean infinite mass. It means the body is not simulated with dynamics.
- Kinematic bodies can push dynamic bodies.
- Kinematic bodies do not respond to forces or collisions from dynamic bodies.

### Dynamic Body

A dynamic body has **full dynamics**: mass, inertia, forces, torques, and collision response.

- Dynamic bodies respond to forces and collisions.
- Dynamic bodies have configurable mass and inertia.
- Dynamic bodies can be controlled by forces, impulses, or constraints.

---

## 2. Additional Body Types

| Type | Description |
|------|-------------|
| **Constrained** | Body with joints/constraints limiting DOF |
| **Scripted** | Body whose motion is scripted (not physics-driven) |
| **Trigger** | Body that detects overlaps but has no collision response |
| **Sensor** | Body that observes but does not participate in dynamics |

---

## 3. Invariants

- **`BODY-INV-001` (Type Separation)**: Body type is a behavioral property, not a lifecycle state.
- **`BODY-INV-002` (Provider Mapping)**: Static/kinematic/dynamic are mapped to provider-specific implementations.
- **`BODY-INV-003` (Semantic Authority)**: SCR defines the behavioral contract; providers implement the mechanics.

---

## Evidence Status

Documented: true
Formally Specified: true
Formally Verified: false
Implemented: false
Tested: false
Validated: false
