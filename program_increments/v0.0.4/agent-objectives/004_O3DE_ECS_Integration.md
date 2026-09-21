# Development Agent Instruction

## 004 — O3DE Entity Component System Integration

**Program Increment:** v0.0.4

**Predecessor:** v0.0.3/003 (Reference Implementation)

**Objective type:** Provider integration

---

# 1. Mission

Integrate SCR semantic contracts with O3DE's Entity Component System (ECS), moving beyond AzCore math to exercise real O3DE entity lifecycle, component queries, and transform propagation.

The preceding objective, v0.0.3/003, established a reference implementation with real O3DE AzCore math integration. This objective extends that work to use O3DE's full ECS framework.

---

# 2. Governing Principles

## 2.1 SCR is the semantic authority

SCR defines the semantic contracts. O3DE is the execution provider.

The implementation must preserve the distinction between SCR semantic definitions and O3DE execution behavior.

## 2.2 Integrate rather than replace

Do not create replacement abstractions when existing O3DE components can be used.

Do not create a parallel entity system. Use O3DE's AzFramework::Entity.

## 2.3 Evidence before claims

Every result must be supported by executable tests against actual O3DE ECS.

A successful compile does not establish ECS integration.

---

# 3. Scope

## 3.1 Required O3DE Components

| Component | O3DE Type | Purpose |
|-----------|-----------|---------|
| Entity | AzFramework::Entity | SCR entity lifecycle |
| Transform | AZ::TransformComponent | Spatial state |
| Tick | AZ::TickComponent | Lifecycle events |
| TransformBus | AZ::TransformBus | Transform queries |

## 3.2 Required Behavior

1. Create O3DE entity from SCR SID
2. Attach TransformComponent with SCR SimilarityTransform
3. Activate entity (SCR Created → Active)
4. Query transform via TransformBus
5. Deactivate entity (SCR Active → Destroyed)
6. Verify SID preserved across lifecycle

## 3.3 Exclusions

- Full game engine (no rendering, physics, audio)
- Multi-entity scenes
- Prefab instantiation
- Asset processing
- Network replication

---

# 4. Implementation Requirements

## 4.1 SID → Entity Mapping

```
SCR SID → AzFramework::EntityId
```

Use a registry similar to v0.0.3/003 but store O3DE EntityId.

## 4.2 Transform Mapping

```
SCR SimilarityTransform → AZ::TransformComponent::SetTransform
```

Use the coordinate conversion from v0.0.3/003 (scr_o3de_provider.cpp).

## 4.3 Lifecycle Mapping

```
SCR Created → Entity::Init + Entity::Activate
SCR Active → Entity::Activate
SCR Suspended → Entity::Deactivate
SCR Destroyed → Entity::~Entity
```

## 4.4 Observation Mapping

```
AZ::TransformBus::GetTransform → SCR SimilarityTransform
```

---

# 5. Testing

## 5.1 Required Tests

| Test | What it exercises |
|------|-------------------|
| Entity creation | SID → EntityId mapping |
| Transform attachment | SimilarityTransform → TransformComponent |
| Lifecycle transitions | Created → Active → Destroyed |
| Transform query | TransformBus → SCR observation |
| Identity preservation | SID preserved across lifecycle |
| Failure: duplicate SID | Error handling for duplicate creation |
| Failure: invalid transform | Error handling for degenerate transform |
| Conformance: round-trip | SCR → O3DE → SCR preserves state |

## 5.2 Build Command

```bash
g++ -std=c++17 -msse4.1 -fpermissive -w -o test_o3de_ecs \
    scr_o3de_ecs.cpp test_o3de_ecs.cpp \
    -I/opt/O3DE/26.05/Code/Framework/AzCore \
    -I/opt/O3DE/26.05/Code/Framework/AzCore/Platform/Linux \
    -I/opt/O3DE/26.05/Code/Framework/AzFramework \
    -I/opt/O3DE/26.05/Code/Framework/AzFramework/Platform/Linux \
    -L/opt/O3DE/26.05/bin/Linux/profile/Default \
    -lAzCore -lAzFramework \
    -Wl,-rpath,/opt/O3DE/26.05/bin/Linux/profile/Default
```

---

# 6. Deliverables

1. `scr_o3de_ecs.h` — O3DE ECS provider header
2. `scr_o3de_ecs.cpp` — O3DE ECS provider implementation
3. `test_o3de_ecs.cpp` — Tests (minimum 10)
4. Updated final report

---

# 7. Acceptance Criteria

- [ ] O3DE ECS provider implemented using AzFramework::Entity
- [ ] TransformComponent used for spatial state
- [ ] Entity lifecycle mapped to SCR states
- [ ] TransformBus used for observation queries
- [ ] Minimum 10 tests passing
- [ ] All existing 138 tests still pass
- [ ] Documentation updated
