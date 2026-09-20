# Sprint 002 Record: Provider Ecosystem Mapping

**Sprint:** 002
**Milestone:** M005 — Provider Specification Validation
**Status:** Complete
**Date:** 2026-09-21

---

## Deliverables

- Provider relationship table (O3DE vs each existing technology)
- Provider ecosystem diagram
- Redundancy/complementarity assessment

## Exit Criteria

- [x] Each provider assessed independently
- [x] No automatic replacement of existing providers
- [x] Coherent provider ecosystem documented
- [x] O3DE classified as execution runtime, not semantic authority

---

## 1. Provider Relationship Table

| Technology | Semantic Role | Representation Role | Provider Role | Execution Role | Adapter Role | Interchange Role | Redundancy | Complementarity |
|---|---|---|---|---|---|---|---|---|
| **Bullet3** | None — subordinate to SCR physics semantics | Rigid body state, collision meshes, constraint parameters | Physics dynamics provider (rigid body, collision, contact solver) | CPU-side simulation execution | Adapts SCR PhysicsBody → btRigidBody; SCR collision shapes → btCollisionShape | None | Low — O3DE delegates physics to AzPhysics/PhysX, not Bullet3 directly; Bullet3 operates independently as SCR canonical physics provider | **High** — Bullet3 provides physics; O3DE provides runtime orchestration. Complementary: O3DE can host Bullet3 as physics backend via AzPhysics adapter |
| **PhysX** | None — subordinate to SCR physics semantics | Rigid body state, collision geometry, articulation chains | Physics backend within O3DE AzPhysics | GPU-accelerated physics execution inside O3DE runtime | O3DE AzPhysics wraps PhysX; SCR → adapter → AzPhysics → PhysX | None | **Medium-High** — PhysX is O3DE's default physics backend; Bullet3 is SCR's canonical physics provider. Both satisfy physics contracts but through different paths | **Medium** — PhysX runs inside O3DE; Bullet3 runs independently. O3DE could route to either via AzPhysics adapter. Coexistence possible |
| **OpenVDB** | None — subordinate to SCR volumetric semantics | Voxel grids, level sets, sparse volume trees, isosurfaces | Volumetric data provider (sparse volume storage, isosurface extraction, fog volumes) | CPU/GPU volume processing | Adapts SCR volume fields → OpenVDB grids; OpenVDB isosurfaces → SCR geometry | None | None — OpenVDB occupies unique spatial/volumetric niche | **High** — OpenVDB provides volumetric data; O3DE provides runtime. O3DE rendering pipeline can consume OpenVDB volumes. Bullet3 collision meshes can reference OpenVDB isosurfaces |
| **H3** | None — subordinate to SCR topology semantics | Hexagonal spatial indices, cell boundaries, hierarchical resolution | Spatial indexing provider (hierarchical hexagonal grid, nearest-neighbor, containment) | CPU-side hexagonal indexing | Adapts SCR spatial queries → H3 cell operations | None | None — H3 occupies unique topology/spatial_indexing niche | **High** — H3 provides spatial indexing; O3DE provides runtime. H3 indexing can drive spatial queries within O3DE simulation |
| **Ogre3D** | None — subordinate to SCR rendering semantics | Scene graph, materials, textures, render passes, mesh data | Rendering provider (scene graph management, material application, frame rendering) | GPU rendering execution | Adapts SCR rendering semantics → Ogre scene graph; Ogre materials → SCR material contracts | None | **Medium** — O3DE has its own RHI/rendering pipeline; Ogre3D is SCR's canonical rendering provider | **High** — Ogre3D provides rendering; O3DE provides runtime orchestration. O3DE could consume Ogre rendering as a subsystem or use its own RHI. Both satisfy rendering contracts |
| **USD** | None — subordinate to SCR scene/composition semantics | Scene description, asset composition, stage hierarchy, variant sets | Scene interchange representation (not execution — data format for cross-tool exchange) | N/A — data format, not execution | Adapts SCR scene graph → USD stage; USD prims → SCR entities | **Primary** — USD is the canonical interchange format for scene/composition data | None — USD is interchange, not execution provider | **High** — USD provides interchange; O3DE provides execution. O3DE can import/export USD scenes. USD is not replaceable by O3DE |
| **ROS2** | None — subordinate to SCR interoperability semantics | Message types, topics, services, actions, parameter interfaces | Robotics interoperability provider (message transport, service discovery, distributed coordination) | ROS2 executor (CPU-side message processing) | Adapts SCR service/port semantics → ROS2 topics/services; ROS2 messages → SCR data flow | None | None — ROS2 occupies unique robotics interoperability niche | **High** — ROS2 provides robotics interop; O3DE provides runtime. O3DE can bridge to ROS2 for robotics simulation. Complementary: O3DE simulation + ROS2 middleware |
| **MLIR** | None — subordinate to SCR compilation semantics | Dialect operations, SSA values, type system, transformation passes | Compiler infrastructure (IR representation, optimization, lowering to executable) | Compilation execution (transform SCR semantics → optimized executable representations) | Adapts SCR semantic operations → MLIR dialect ops; MLIR lowering → executable code | None — MLIR is compilation substrate, not interchange format | None — MLIR occupies unique compiler infrastructure niche | **High** — MLIR provides compilation; O3DE provides runtime. MLIR can compile SCR semantics into O3DE-executable artifacts. Complementary: compile-time (MLIR) + runtime (O3DE) |
| **Mojo** | None — subordinate to SCR implementation semantics | High-level systems language constructs, MLIR-native types, SIMD abstractions | Implementation language / runtime (Mojo programs as SCR implementations) | Mojo runtime execution (CPU/GPU) | Adapts SCR semantic operations → Mojo code; Mojo runtime → executable | None — Mojo is implementation language, not interchange | None — Mojo occupies unique implementation language niche | **High** — Mojo provides implementation language; O3DE provides runtime. Mojo code can implement SCR providers that execute within O3DE. Complementary: language (Mojo) + runtime (O3DE) |

---

## 2. Provider Ecosystem Diagram

```
SCR Semantic Layer
├── Bullet3 (physics provider)
│   ├── Domain: physics/dynamics/collision/contact
│   ├── Role: SCR canonical physics (rigid body, collision detection, constraint solving)
│   ├── Status: Operational
│   └── Independence: Full — operates outside O3DE
│
├── Ogre3D (rendering provider)
│   ├── Domain: render/graphics
│   ├── Role: SCR canonical rendering (scene graph, materials, frame rendering)
│   ├── Status: Active (adapter + tests present)
│   └── Independence: Full — operates outside O3DE
│
├── OpenVDB (volumetric provider)
│   ├── Domain: spatial/volumetric
│   ├── Role: Sparse volume storage, isosurface extraction, fog volumes
│   ├── Status: Seeded
│   └── Independence: Full — operates outside O3DE
│
├── H3 (spatial indexing provider)
│   ├── Domain: topology/spatial_indexing
│   ├── Role: Hexagonal spatial indexing, containment, nearest-neighbor
│   ├── Status: Seeded
│   └── Independence: Full — operates outside O3DE
│
├── O3DE (execution runtime provider) ← NEW
│   ├── Domain: execution/runtime
│   ├── Role: Runtime orchestration for entity/component simulation
│   ├── Status: Specification Draft
│   ├── Sub-components:
│   │   ├── AzPhysics (delegates to PhysX backend)
│   │   ├── AzNetworking (transport layer)
│   │   └── Multiplayer (distributed state synchronization)
│   ├── Contracts: Entity, Component, Transform, PhysicsBody, Replication, Rendering, Asset, SpatialQuery
│   ├── All contracts: adapter-required (none native)
│   └── Independence: Execution runtime — does not replace semantic providers
│
├── USD (interchange representation)
│   ├── Domain: scene/composition interchange
│   ├── Role: Cross-tool scene description and asset composition
│   ├── Status: External standard (not yet in providers/)
│   └── Independence: Full — data format, not execution
│
├── ROS2 (robotics interoperability)
│   ├── Domain: robotics/interoperability
│   ├── Role: Message transport, service discovery, distributed coordination
│   ├── Status: External standard (not yet in providers/)
│   └── Independence: Full — middleware, not execution runtime
│
└── MLIR (compiler infrastructure)
    ├── Domain: compilation/semantics
    ├── Role: IR representation, optimization, lowering to executable
    ├── Status: External standard (not yet in providers/)
    └── Independence: Full — compilation substrate, not execution runtime
```

---

## 3. Relationship Analysis

### 3.1 Bullet3 ↔ O3DE

Bullet3 and O3DE both touch physics, but at different architectural layers:

- **Bullet3** is SCR's canonical physics provider — implements rigid body dynamics, collision detection, constraint solving against SCR physics semantics.
- **O3DE** provides AzPhysics, which wraps PhysX as its default physics backend. O3DE does not implement physics semantics directly — it delegates to AzPhysics → PhysX.

**Relationship:** Complementary. Bullet3 satisfies physics contracts independently. O3DE can route physics through AzPhysics to either PhysX or potentially Bullet3 via adapter. No replacement occurs.

**Key rule:** Bullet3 remains SCR's canonical physics provider. O3DE's AzPhysics/PhysX is an implementation path within O3DE's runtime scope.

### 3.2 PhysX ↔ O3DE

PhysX is tightly coupled to O3DE:

- PhysX is O3DE's default physics backend inside AzPhysics.
- O3DE manages PhysX lifecycle, scene creation, and simulation stepping.

**Relationship:** Internal dependency. PhysX is subordinate to O3DE's AzPhysics adapter. From SCR's perspective, O3DE is the provider; PhysX is O3DE's implementation detail.

**Key rule:** PhysX does not become an SCR provider — it remains O3DE's internal physics backend.

### 3.3 OpenVDB ↔ O3DE

OpenVDB provides volumetric data. O3DE provides runtime:

- OpenVDB manages sparse volume grids, level sets, isosurfaces.
- O3DE rendering pipeline can consume OpenVDB volumes for visualization.
- Bullet3 collision meshes can reference OpenVDB isosurfaces for physics.

**Relationship:** Complementary. OpenVDB provides data; O3DE provides execution/rendering context. No overlap in semantic responsibility.

### 3.4 H3 ↔ O3DE

H3 provides hexagonal spatial indexing. O3DE provides runtime:

- H3 manages spatial containment, nearest-neighbor queries, hierarchical resolution.
- O3DE simulation can use H3 indexing for spatial queries within its runtime.

**Relationship:** Complementary. H3 provides spatial indexing; O3DE provides execution. No overlap.

### 3.5 Ogre3D ↔ O3DE

Both touch rendering, but at different layers:

- **Ogre3D** is SCR's canonical rendering provider — scene graph management, materials, frame rendering.
- **O3DE** has its own RHI/rendering pipeline.

**Relationship:** Parallel providers. Both satisfy rendering contracts. Ogre3D is SCR's canonical rendering provider. O3DE's rendering is internal to its runtime scope.

**Key rule:** No automatic replacement. O3DE could use Ogre3D as its rendering backend, or use its own RHI. Both remain valid under SCR contracts.

### 3.6 USD ↔ O3DE

USD is interchange; O3DE is execution:

- USD provides scene description and asset composition format.
- O3DE can import/export USD scenes.
- USD is not an execution provider — it is a data format.

**Relationship:** Complementary. USD provides interchange; O3DE provides execution. O3DE consuming USD does not make O3DE an interchange provider.

### 3.7 ROS2 ↔ O3DE

ROS2 is middleware; O3DE is runtime:

- ROS2 provides message transport, service discovery, distributed coordination.
- O3DE can bridge to ROS2 for robotics simulation.
- O3DE does not replace ROS2's middleware role.

**Relationship:** Complementary. ROS2 provides robotics interop; O3DE provides simulation runtime. Both operate at different architectural layers.

### 3.8 MLIR ↔ O3DE

MLIR is compilation; O3DE is runtime:

- MLIR provides IR representation, optimization, lowering to executable code.
- O3DE executes compiled artifacts.
- MLIR can compile SCR semantics into O3DE-executable representations.

**Relationship:** Complementary. MLIR provides compile-time transformation; O3DE provides runtime execution. Different architectural layers.

### 3.9 Mojo ↔ O3DE

Mojo is implementation language; O3DE is runtime:

- Mojo provides systems language with MLIR-native types and SIMD abstractions.
- O3DE executes programs written in various languages.
- Mojo code can implement SCR providers that execute within O3DE.

**Relationship:** Complementary. Mojo provides implementation language; O3DE provides execution runtime. Different architectural layers.

---

## 4. Ecosystem Assessment

### 4.1 No Automatic Replacement

The mapping confirms that O3DE does not automatically replace any existing provider:

| Provider | Replacement Risk | Assessment |
|---|---|---|
| Bullet3 | None | Bullet3 is SCR canonical physics; O3DE delegates physics to AzPhysics/PhysX |
| Ogre3D | Low | Ogre3D is SCR canonical rendering; O3DE has own RHI but could consume Ogre |
| OpenVDB | None | OpenVDB provides unique volumetric capability; O3DE consumes, does not replace |
| H3 | None | H3 provides unique spatial indexing; O3DE consumes, does not replace |
| USD | None | USD is interchange format; O3DE imports/exports but does not replace |
| ROS2 | None | ROS2 is middleware; O3DE bridges but does not replace |
| MLIR | None | MLIR is compiler infra; O3DE is runtime — different layers entirely |
| Mojo | None | Mojo is language; O3DE is runtime — different layers entirely |

### 4.2 Complementarity Matrix

| | Bullet3 | Ogre3D | OpenVDB | H3 | USD | ROS2 | MLIR | Mojo |
|---|---|---|---|---|---|---|---|---|
| **O3DE** | Physics delegation via AzPhysics | Rendering coexistence | Volume consumption | Spatial query consumption | Scene import/export | Robotics bridging | Compilation → execution | Language → runtime |

### 4.3 Architectural Layers

```
Layer 7: Application / Domain Semantics
    ↓
Layer 6: SCR Semantic Contracts
    ↓
Layer 5: Provider Contracts
    ↓
Layer 4: Providers
    ├── Bullet3 (physics)
    ├── Ogre3D (rendering)
    ├── OpenVDB (volumetric)
    ├── H3 (spatial indexing)
    ├── O3DE (execution runtime)
    ├── USD (interchange)
    ├── ROS2 (middleware)
    ├── MLIR (compilation)
    └── Mojo (language)
    ↓
Layer 3: Adapters
    ↓
Layer 2: Implementation Bindings
    ↓
Layer 1: Computational Substrate (CPU/GPU/OS/Network)
```

Each provider occupies a distinct position in this stack. O3DE sits at Layer 4 as an execution runtime provider, not as a semantic authority or as a replacement for domain-specific providers.

---

## 5. Key Findings

1. **O3DE is execution runtime, not semantic authority** — all SCR semantics originate from SCR semantic layer
2. **No provider is redundant with O3DE** — each has independent semantic role
3. **O3DE complements existing ecosystem** — provides runtime orchestration that can host other providers
4. **All O3DE contracts are adapter-required** — no native mapping to SCR semantics
5. **PhysX is O3DE's internal detail** — does not become separate SCR provider
6. **Bullet3 remains SCR canonical physics** — O3DE's physics delegation does not override this
7. **Ogre3D and O3DE rendering coexist** — parallel rendering providers, no automatic replacement
8. **USD/ROS2/MLIR/Mojo are external standards** — not yet in providers/ directory, but architecturally independent from O3DE

---

## 6. Conformance

Provider ecosystem mapping adheres to:
- `providers/101_definition.md` — provider independence and substitution rules
- `providers/o3de/101_spec.md` — O3DE as execution provider, not semantic authority
- Sprint 02 spec — relationship table, classification, redundancy/complementarity assessment

---

## 7. Next Sprint

Sprint 003: Semantic Fidelity Formalisation — define how provider contracts preserve semantic guarantees across adapter boundaries.
