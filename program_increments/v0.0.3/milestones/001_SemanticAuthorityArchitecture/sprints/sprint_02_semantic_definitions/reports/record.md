# Sprint 002 Record: Semantic Definitions

## 1. Concept Hierarchy

SCR distinguishes six concept types:

### Semantic Definition
What something means. Authoritative meaning independent of representation.
Examples: Entity, Component, Transform, Authority, SimulationStep

### Semantic Function
A transformation or operation over semantic structures.
Examples: instantiate(entity), attach(component, entity), simulate(world, Δt), replicate(state)

### Representation
A concrete encoding of semantic information.
Examples: USD, MLIR, OpenVDB, H3, ROS 2 messages, O3DE serialized assets, network packets

### Projection
Mapping semantic information into or from a representation.

| Projection Type | Description |
|----------------|-------------|
| Lossless | All semantic information preserved |
| Partially lossless | Some semantic information preserved |
| Lossy | Significant semantic information lost |
| Unidirectional | Semantic → Representation only |
| Bidirectional | Semantic ↔ Representation round-trip |
| Implementation-specific | Projection varies by implementation |

**Critical rule:** Representation equality does not imply semantic equality.

### Adapter
A mechanism translating SCR contracts into a provider or external-system interface.

```
SCR Entity → O3DE adapter → AzFramework Entity
SCR PhysicsBody → Bullet adapter → btRigidBody
```

### Execution Provider
A system that executes semantic operations.
Examples: O3DE, Bullet, PhysX, CPU, GPU, specialist simulation engines

## 2. Relationship Diagram

```
Semantic Meaning → Semantic Operation → Projection → Representation → Adapter → Provider Execution → Observation → SCR-compatible state
```

## 3. Verification

- All six concept types defined with examples
- Projection classification covers all common cases
- Adapter pattern clearly distinguished from provider
- Semantic equality ≠ representation equality stated explicitly
