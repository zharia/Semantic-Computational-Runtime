# O3DE Provider Specification

**Path:** `providers/o3de/101_spec.md`
**Version:** 0.0.1
**Status:** Specification Draft

---

## 1. Provider Purpose

O3DE is an execution provider for SCR semantics. It provides a runtime for entity/component simulation, rendering, physics, networking, and asset management.

O3DE does not define SCR semantics. It implements them through AzFramework/AzCore infrastructure.

---

## 2. Provider Scope

O3DE implements SCR semantic operations via AzFramework/AzCore/AzPhysics/AzNetworking.

The provider bridges SCR semantic contracts to O3DE runtime capabilities. All semantic meaning originates from SCR. O3DE provides the execution substrate.

---

## 3. Supported SCR Contracts

| SCR Contract | Capability | Notes |
|---|---|---|
| Entity | adapter-required | SCR SID → AZ::EntityId mapping |
| Component | adapter-required | SCR Component → AZ::Component mapping |
| Transform | adapter-required | SCR Semantic Transform → AZ::Transform |
| PhysicsBody | adapter-required | SCR → adapter → AzPhysics |
| Replication | adapter-required | SCR → adapter → Multiplayer |
| Rendering | adapter-required | SCR → adapter → OGRE3D/O3DE renderer |
| Asset | partial | SCR → adapter → AZ::Data::Asset |
| SpatialQuery | adapter-required | SCR → adapter → AzPhysics raycast/overlap |

No SCR contract maps natively to O3DE without adaptation. All require adapters at the semantic boundary.

---

## 4. Identity Mapping

```
SCR SID (Semantic Identifier)
    → O3DE identity mapping layer
        → AZ::EntityId
```

SCR SIDs are canonical identity. AZ::EntityId is an implementation handle. The identity mapping layer preserves SCR identity semantics while allowing O3DE to use its native entity addressing.

Identity is never derived from AZ::EntityId. SCR SID is always authoritative.

---

## 5. Spatial Mapping

```
SCR canonical:
    +Z forward
    +Y up
    +X right

O3DE:
    +Y forward
    +Z up
    +X right
```

The spatial adapter performs axis permutation between SCR canonical coordinates and O3DE coordinates. Rotation and scale semantics are preserved through the transform.

Spatial semantics are authored in SCR canonical coordinates. The adapter translates at the provider boundary.

---

## 6. Temporal Mapping

```
SCR SimulationTime
    → O3DE AZ::Tick
```

SCR temporal semantics are authoritative. AZ::Tick provides the execution clock. The temporal adapter synchronizes SCR simulation time with O3DE tick-based time advancement.

Delta time accumulation and frame boundaries are handled by the adapter, not the SCR semantic layer.

---

## 7. Lifecycle

```
SCR lifecycle states:
    Construct → Initialize → Activate → Deactivate → Destroy

O3DE entity lifecycle:
    AZ::Entity construction
        → AZ::Entity::Init()
            → AZ::Entity::Activate()
                → AZ::Entity::Deactivate()
                    → AZ::Entity destruct
```

The lifecycle adapter maps SCR semantic lifecycle to O3DE entity lifecycle. SCR lifecycle transitions are authoritative. O3DE lifecycle is the implementation mechanism.

---

## 8. Physics

```
SCR PhysicsBody semantics
    → adapter
        → AzPhysics
            → PhysX backend
```

Physics semantics are authored in SCR. The adapter translates SCR physics representations to AzPhysics bodies. PhysX is the default physics backend in O3DE.

Physics simulation results are translated back through the adapter to SCR semantic state.

---

## 9. Entities/Components

```
SCR Entity/Component semantics
    → adapter
        → AZ::Entity / AZ::Component
```

SCR entities and components are semantic concepts. O3DE entities and components are implementation constructs. The adapter maps between them.

O3DE component types are not SCR semantic types. They are implementation mechanisms.

---

## 10. Assets

```
SCR ResourceReference
    → adapter
        → AZ::Data::Asset
```

Asset capability is **partial**. SCR ResourceReference semantics map to AZ::Data::Asset through an adapter. Full asset pipeline integration (cooking, streaming, dependency resolution) requires additional adapter work.

Not all SCR resource semantics have O3DE equivalents.

---

## 11. Networking

```
SCR Replication semantics
    → adapter
        → Multiplayer / AzNetworking
```

SCR replication semantics are authoritative. O3DE Multiplayer/AzNetworking provides the transport and synchronization mechanism. The adapter translates SCR replication state to network-ready representations.

---

## 12. Headless Mode

Supported. O3DE can run without rendering via `--null` renderer flag.

Headless mode allows physics, entity, component, and networking providers to execute without a rendering pipeline. This is valuable for simulation-only and testing scenarios.

---

## 13. Adapters Required

| Adapter | Purpose |
|---|---|
| Identity adapter | SCR SID ↔ AZ::EntityId bidirectional mapping |
| Spatial adapter | Coordinate convention transform (SCR ↔ O3DE) |
| Physics adapter | SCR PhysicsBody ↔ AzPhysics body mapping |
| Network adapter | SCR Replication ↔ Multiplayer state sync |
| Asset adapter | SCR ResourceReference ↔ AZ::Data::Asset |

All adapters MUST preserve SCR semantic guarantees at the provider boundary.

---

## 14. Dependencies

- AzCore
- AzFramework
- AzPhysics
- AzNetworking
- Multiplayer
- PhysX (physics backend)
- O3DE rendering (RHI)

These are implementation dependencies. They do not become semantic dependencies of SCR.

---

## 15. Known Limitations

- O3DE is not a semantic authority — SCR defines all meaning
- AzFramework patterns may not map 1:1 to SCR semantics
- Some O3DE features have no SCR equivalent
- O3DE entity/component model differs structurally from SCR semantic model
- Coordinate system mismatch requires adapter translation

---

## 16. Unsupported Capabilities

| Capability | Reason |
|---|---|
| SCR semantic composition | O3DE uses different entity/component composition patterns |
| SCR MLIR lowering | O3DE has no MLIR integration |

These capabilities remain outside O3DE provider scope. Alternative providers or SCR-native implementations may address them.

---

## 17. Validation

Provider validation covers:

- Provider initialization sequence
- Identity mapping correctness (SCR SID ↔ AZ::EntityId)
- Entity creation via adapter
- Component association via adapter
- Spatial mapping correctness (coordinate convention transform)
- Lifecycle state transitions
- Simulation step execution
- State transition integrity
- Shutdown sequence

Validation tests operate at the semantic boundary. O3DE-internal behavior is verified through O3DE's own test infrastructure.

---

## 18. Conformance Statement

O3DE provider conforms to SCR Provider Architecture (providers/101_definition.md) when:

1. All adapters preserve SCR semantic guarantees
2. SCR SID remains authoritative identity
3. SCR canonical coordinates remain authoritatively authored
4. O3DE-specific ontology does not leak into SCR semantic layer
5. Provider is substitutable by alternative implementations satisfying same contracts
