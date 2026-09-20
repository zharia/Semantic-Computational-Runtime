# Sprint 004 Record: Temporal Semantics, Identity Mapping & State Ownership

## 1. Objective

Define the SCR temporal semantics classification, identity mapping model, and state ownership model. Each definition derives from O3DE timing/identity research, generalised beyond games to robotics, distributed-simulation, and digital-twins. Frame number, simulation time, wall-clock time, and network time are explicitly distinguished as separate semantic concepts. Identity scope and lifetime are documented for cross-system mapping.

## 2. Scope & Boundaries

### 2.1 What This Sprint Covers

Three semantic models:

| Model | Purpose |
|-------|---------|
| **Temporal Semantics** | Classification of time concepts across computational domains |
| **Identity Mapping** | Cross-system identity correspondence and lifecycle |
| **State Ownership** | Per-state declaration of owner, mutator, observer, predictor, reconciler |

### 2.2 What This Sprint Does NOT Cover

- Prediction and reconciliation mechanisms (Sprint 03 — covered)
- Authority/ownership/replication definitions (Sprint 02 — covered)
- Transport-layer protocols (explicitly separated)
- Provider-specific implementations (O3DE TickBus is provider-specific, not SCR semantic)

### 2.3 Relationship to M004 Invariants

All definitions must satisfy M004's four formal invariants:

1. Authority transitions are explicit
2. Prediction does not silently overwrite authoritative state
3. Replicated state has defined ownership
4. **Time ordering is preserved across distributed observations**

## 3. Research Sources

### 3.1 O3DE Timing Architecture

O3DE provides multiple distinct timing mechanisms:

| O3DE Concept | Mechanism | Scope |
|--------------|-----------|-------|
| `AZ::TickBus::OnTick(float deltaTime, AZ::ScriptTimePoint time)` | Per-frame tick. `deltaTime` is time since last frame. `time` is accumulated script time. | Game thread, frame-synchronized |
| `AZ::SystemTickEvents::OnSystemTick()` | System tick at small intervals (ms). Fires even without focus. Not consistent interval. | System thread, independent of frame |
| `AZ::ComponentTickBus` ordering | Integer order values (TICK_FIRST=0, TICK_PLACEMENT=50, TICK_INPUT=75, TICK_GAME=80, TICK_ANIMATION=100) | Within-frame component ordering |
| Simulation Time for ROS2 Gem | Separate simulation time concept for ROS2 integration | ROS2 domain |

**Key O3DE insight:** O3DE conflates `deltaTime` (frame interval) with `time` (accumulated script time). The tick bus is frame-synchronous; the system tick bus is frame-independent. SCR must separate these as distinct temporal semantic concepts because they serve different computational purposes.

**Key O3DE insight:** `AZ::ScriptTimePoint` is accumulated time from script system — it represents simulation time, not wall-clock time. Wall-clock time requires `AZStd::chrono::system_clock` or platform APIs. Frame time (`deltaTime`) is the interval between frames, not the current time. These are three distinct semantic concepts.

### 3.2 O3DE Identity Architecture

O3DE identity mechanisms:

| O3DE Concept | Type | Scope | Lifetime | Collision Risk |
|--------------|------|-------|----------|----------------|
| `AZ::EntityId` | 64-bit integer (context-local) | Host-local | Session (destroyed on level unload) | Low within session; meaningless across hosts |
| `AZ::Uuid` | 128-bit UUID v4 | Global | Permanent | Negligible (UUID v4 random) |
| Entity serialization | JSON/binary with Uuid key | Persistent | Asset lifetime | None (UUID-based) |
| `AZ::Name` | String hash | Host-local | Session | Medium (hash collision possible) |
| Network Entity ID | AzNetworking-assigned | Network-local | Session (network connection) | No (server-assigned) |

**Key O3DE insight:** `AZ::EntityId` is context-local — it has no meaning across hosts, processes, or sessions. It is an internal handle, not an identity. `AZ::Uuid` is the persistent identity used for serialization, asset identification, and cross-session persistence. SCR must distinguish between handle (session-local reference) and identity (persistent, globally unique).

**Key O3DE insight:** In multiplayer, the server assigns network entity IDs. These are session-scoped to the network connection. When a client disconnects and reconnects, it receives new network entity IDs. The persistent identity (Uuid) survives reconnection. SCR must track identity across reconnection events.

### 3.3 State Ownership Patterns in Multiplayer

O3DE Multiplayer Gem ownership patterns:

| Pattern | Owner | Mutator | Lifecycle Control | Example |
|---------|-------|---------|-------------------|---------|
| Server-authoritative | Server | Server | Server spawns/despawns | NPC, physics objects |
| Autonomous prediction | Autonomous client | Authority (server) | Server spawns | Player character |
| Client-owned (distributed authority) | Owning client | Owning client | Client spawns | Destructible environment |
| Shared ownership | All peers | Consensus | Distributed | Peer-to-peer simulation |

**Key insight:** Ownership in multiplayer is not a single concept. It decomposes into:
- **Who mutates state?** (Authority)
- **Who controls lifecycle?** (Ownership)
- **Who predicts?** (Autonomous client)
- **Who reconciles?** (Receiving host on authority update)

SCR must make each role explicit per state, not per entity.

### 3.4 Unity Netcode State Ownership

Unity Netcode for Entities provides additional patterns:

- `NetworkVariable<T>` with `ReadPerm` / `WritePerm` permissions
- `Owner` permission: only the owning client can write
- `Everyone` permission: any host can write (conflict resolution required)
- Distributed authority: ownership transfers automatically on client join/leave
- `OwnershipStatus`: None (static), Distributable, Transferable, RequestRequired

**Key Unity insight:** State ownership is per-property, not per-entity. The same entity may have owner-writable properties and authority-writable properties. SCR adopts this per-property granularity.

### 3.5 ROS 2 Identity and Timing

ROS 2 provides domain-specific patterns:

| Concept | Type | Scope | Lifetime |
|---------|------|-------|----------|
| Node name | String | Namespace-local | Node lifetime |
| Topic name | String | Namespace-local | Publication lifetime |
| QoS profile | Configuration | Per-topic | Publication lifetime |
| Simulation time (`/clock`) | `rosgraph_msgs/msg/Clock` | System-wide | Simulation lifetime |
| Wall time (`steady_clock`) | `builtin_interfaces/msg/Time` | System-wide | Process lifetime |

**Key ROS 2 insight:** ROS 2 distinguishes simulation time (from `/clock` topic) from wall time (from `steady_clock`). This is exactly the temporal semantics distinction SCR requires. The `/clock` topic is the ROS 2 equivalent of O3DE's script time — it represents the simulation's progression, not real-world time.

## 4. SCR Semantic Definitions

### 4.1 Temporal Semantics Classification

```yaml
concept: WallClock
source: std::chrono, OS APIs, ROS 2 steady_clock
source_terminology: >
  C++: std::chrono::system_clock, std::chrono::steady_clock;
  O3DE: AZStd::chrono (implicit);
  ROS 2: builtin_interfaces/msg/Time with steady_clock
scr_interpretation: >
  WallClock is real-world time as measured by the system clock. WallClock
  advances monotonically (steady_clock) or with system adjustments
  (system_clock). WallClock is used for: scheduling, timeout detection,
  performance measurement, logging timestamps, and cross-system correlation.
  WallClock is NOT used for simulation progression — simulation uses
  SimulationTime. WallClock MAY diverge from SimulationTime when the
  simulation pauses, runs faster/slower than real-time, or uses fixed
  timestep. WallClock is the temporal authority for "when did this happen
  in the real world."
differences: >
  O3DE does not explicitly name wall-clock time as a distinct concept.
  AZ::ScriptTimePoint conflates accumulated script time with wall-clock
  time. ROS 2 explicitly distinguishes /clock (simulation time) from
  steady_clock (wall time). SCR WallClock is the generalised concept
  covering both. std::chrono provides platform-independent wall-clock
  access; SCR WallClock is agnostic to implementation.
invariants:
  - TEMP-WC-001: WallClock MUST be monotonic for sequencing. Use steady_clock for ordering.
  - TEMP-WC-002: WallClock MAY diverge from SimulationTime. Divergence MUST be declared.
  - TEMP-WC-003: WallClock MUST record provenance: source clock, host, timestamp.
  - TEMP-WC-004: WallClock is the temporal authority for real-world event ordering.
```

```yaml
concept: SimulationTime
source: O3DE AZ::ScriptTimePoint, ROS 2 /clock, fixed timestep simulations
source_terminology: >
  O3DE: AZ::ScriptTimePoint (accumulated script time);
  ROS 2: /clock topic (rosgraph_msgs/msg/Clock);
  Games: fixed_dt * tick_count
scr_interpretation: >
  SimulationTime is the progression of the simulation's internal clock.
  SimulationTime advances by a fixed or variable delta each simulation tick.
  SimulationTime is the temporal authority for "what order did simulation
  events happen." SimulationTime MAY advance faster or slower than
  WallClock (time scaling, pause, catch-up). SimulationTime is used for:
  deterministic replay, rollback/reconciliation (Sprint 03), physics
  integration, animation blending, and simulation-ordered event processing.
  SimulationTime is NOT real-world time — it represents the simulation's
  internal progression.
differences: >
  O3DE AZ::ScriptTimePoint is accumulated script time — it is the
  simulation time within the script system. However, O3DE does not
  separate ScriptTimePoint from tick-based frame timing. SCR
  SimulationTime is explicitly separated from FrameTime and WallClock.
  ROS 2 /clock provides simulation time via a topic — any node can
  publish simulation time. SCR SimulationTime is the semantic concept;
  the mechanism (topic, accumulator, fixed step) is a provider concern.
  GGPO uses frame numbers as simulation time (frame N = N * fixed_dt).
  SCR SimulationTime is generalised: it MAY be frame-derived or
  independent of frames.
invariants:
  - TEMP-SIM-001: SimulationTime MUST advance monotonically within the simulation.
  - TEMP-SIM-002: SimulationTime MUST NOT silently diverge from declared timestep. If timestep changes, it MUST be declared.
  - TEMP-SIM-003: SimulationTime is the temporal authority for simulation-ordered events.
  - TEMP-SIM-004: SimulationTime MAY be paused, scaled, or reset — each operation MUST be declared.
  - TEMP-SIM-005: SimulationTime MUST record provenance: host, timestep, tick count, timestamp.
```

```yaml
concept: ObservationTime
source: O3DE replicated state timestamps, distributed systems snapshot semantics
source_terminology: >
  O3DE: NetworkProperty replication timestamp;
  Distributed systems: vector clocks, logical timestamps;
  Sprint 02: Observation point-in-time snapshot
scr_interpretation: >
  ObservationTime is when a state was observed by a specific host.
  ObservationTime captures the temporal position of a snapshot from the
  observing host's perspective. ObservationTime is always later than or
  equal to the state's origin time (the time the state was produced).
  The gap between origin time and ObservationTime is staleness (Sprint 02:
  DIST-OBS-003). ObservationTime is used for: staleness calculation,
  temporal ordering of observations, conflict detection, and cross-host
  correlation. ObservationTime is NOT the time the state was produced —
  it is the time the state was received and recorded.
differences: >
  O3DE does not have an explicit ObservationTime concept. Replicated
  state arrives with implicit ordering (sequence numbers) but no
  explicit timestamp of when it was observed. SCR ObservationTime makes
  this explicit: every observation records when it was observed, not
  just when it was produced. Distributed systems use vector clocks for
  causal ordering; SCR ObservationTime is a wall-clock timestamp that
  provides real-world temporal position. Causal ordering is a separate
  semantic concern.
invariants:
  - TEMP-OBS-001: ObservationTime MUST be recorded at the moment of observation, not derived from origin time.
  - TEMP-OBS-002: ObservationTime MUST be later than or equal to the state's origin time.
  - TEMP-OBS-003: Staleness = ObservationTime - originTime. Staleness MUST be calculable.
  - TEMP-OBS-004: ObservationTime MUST record provenance: observing host, observed entity, origin time, observation timestamp.
```

```yaml
concept: NetworkTime
source: O3DE network tick, Unity NetworkManager tick, GGPO frame sync
source_terminology: >
  O3DE: AzNetworking tick (network simulation frame);
  Unity: NetworkManager.ServerTick / ClientTick;
  GGPO: synchronized frame number
scr_interpretation: >
  NetworkTime is the network synchronization time — the time used to
  coordinate state across networked hosts. NetworkTime is typically
  server-authoritative: the server's clock defines the current network
  time, and clients synchronize to it. NetworkTime is used for:
  input timestamping (Sprint 03: PredictionInput), authority update
  ordering, lag compensation, and temporal rollback windows. NetworkTime
  MAY be frame-derived (server frame N) or independent (server wall
  clock). NetworkTime is NOT SimulationTime — they may advance at
  different rates (client may run faster/slower simulation but still
  synchronize to server network time).
differences: >
  O3DE network tick is tied to the server's frame rate — each network
  tick corresponds to a server frame. SCR NetworkTime is independent
  of frame rate: it MAY be frame-derived or wall-clock-derived. Unity
  separates ServerTick and ClientTick; SCR NetworkTime is always
  authoritative (from the authoritative host), not per-host. GGPO uses
  frame numbers as network time (frame N is globally synchronized);
  SCR NetworkTime is generalised. The key distinction: NetworkTime is
  for cross-host coordination, SimulationTime is for within-host
  simulation progression.
invariants:
  - TEMP-NET-001: NetworkTime MUST be authoritative — defined by the authoritative host.
  - TEMP-NET-002: NetworkTime MUST be consistent across all hosts at a given logical moment. Discrepancies MUST be declared.
  - TEMP-NET-003: NetworkTime is used for input timestamping and authority update ordering.
  - TEMP-NET-004: NetworkTime MUST record provenance: authoritative host, timestamp, network tick.
  - TEMP-NET-005: NetworkTime MAY be frame-derived or wall-clock-derived. The derivation MUST be declared.
```

```yaml
concept: FrameTime
source: O3DE AZ::TickBus deltaTime, render loop timing
source_terminology: >
  O3DE: AZ::TickBus::OnTick deltaTime parameter;
  Games: timeSinceLastFrame, frame delta;
  Rendering: VSync interval, frame rate
scr_interpretation: >
  FrameTime is the interval between render frames. FrameTime is
  presentation timing — it determines how often the visual output
  updates. FrameTime is NOT simulation time — they MAY diverge when
  simulation runs at a fixed timestep different from render rate,
  when frames are dropped, or when time scaling is applied. FrameTime
  is used for: animation interpolation, visual smoothing, frame-rate
  independent movement in presentation logic, and VSync coordination.
  FrameTime MUST NOT be used for simulation ordering — use
  SimulationTime. FrameTime MUST NOT be used for network synchronization
  — use NetworkTime. FrameTime is the temporal authority for "how long
  since the last visual update."
differences: >
  O3DE passes deltaTime to OnTick — this IS the frame time. However,
  O3DE documentation warns against using OnTick for simulation logic
  ("components should limit time connected to tick bus"). O3DE
  conflates frame time with simulation time in the same callback.
  SCR FrameTime is explicitly separated from SimulationTime and
  NetworkTime. The deltaTime parameter in OnTick maps to SCR FrameTime.
  The ScriptTimePoint parameter maps to SCR SimulationTime (accumulated).
  O3DE does not make this distinction explicit; SCR requires it.
invariants:
  - TEMP-FRAME-001: FrameTime is the interval between render frames, not simulation time.
  - TEMP-FRAME-002: FrameTime MUST NOT be used for simulation ordering. SimulationTime is the authority for simulation events.
  - TEMP-FRAME-003: FrameTime MAY vary (frame drops, VSync). Variance MUST NOT affect simulation correctness.
  - TEMP-FRAME-004: FrameTime MUST record provenance: host, frame number, delta, timestamp.
```

```yaml
concept: PhysicsTimestep
source: O3DE PhysX fixed timestep, physics simulation integration
source_terminology: >
  O3DE: PhysX fixed timestep (default 1/60);
  Games: fixedDeltaTime, physics tick;
  Robotics: control loop period
scr_interpretation: >
  PhysicsTimestep is the fixed integration step for physics simulation.
  PhysicsTimestep is typically constant (e.g., 1/60 second) and
  independent of render frame rate. PhysicsTimestep is used for:
  deterministic physics integration, collision detection, constraint
  solving, and rigid body dynamics. PhysicsTimestep is a specific form
  of SimulationTime — physics runs at its own fixed rate within the
  simulation. Multiple physics steps MAY occur per render frame; a
  single physics step MAY span multiple render frames. PhysicsTimestep
  is the temporal authority for "how far did physics advance."
differences: >
  O3DE PhysX provides fixed timestep configuration — the physics
  engine runs at a constant rate regardless of frame rate. This is
  standard practice. SCR PhysicsTimestep is the generalised semantic
  concept: any fixed-step integration. It applies to physics,
  robotics control loops, signal processing, and any domain requiring
  fixed-rate integration. O3DE conflates physics timestep with the
  broader simulation timestep. SCR separates PhysicsTimestep as a
  specific temporal concept within the simulation hierarchy.
invariants:
  - TEMP-PHY-001: PhysicsTimestep MUST be constant for deterministic integration.
  - TEMP-PHY-002: PhysicsTimestep MAY accumulate fractional steps (fixed timestep with remainder).
  - TEMP-PHY-003: PhysicsTimestep is subordinate to SimulationTime — physics runs within the simulation timeline.
  - TEMP-PHY-004: PhysicsTimestep MUST record provenance: host, timestep value, integration count.
```

### 4.2 Temporal Semantics Hierarchy

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TEMPORAL SEMANTICS HIERARCHY                      │
│                                                                     │
│  WallClock (real-world)                                             │
│    ├── ObservationTime (when state was observed)                    │
│    └── NetworkTime (server-authoritative, cross-host)              │
│                                                                     │
│  SimulationTime (simulation progression)                           │
│    ├── PhysicsTimestep (fixed integration step)                     │
│    └── (other fixed-rate subsystems)                               │
│                                                                     │
│  FrameTime (render interval)                                        │
│    └── Presentation only — NOT simulation authority                 │
│                                                                     │
│  Key invariants:                                                    │
│    Frame number ≠ simulation time (unless formally justified)       │
│    WallClock ≠ SimulationTime (unless real-time simulation)         │
│    NetworkTime ≠ SimulationTime (unless synchronized)               │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.3 Critical Invariant: Frame ≠ Simulation Time

```
FRAME ≠ SIMULATION TIME

Frame number is a presentation counter. Simulation time is a progression
counter. They are semantically distinct.

Frame 100 does NOT mean "100 units of simulation time have passed."
Frame 100 means "100 visual updates have occurred."

If frame number equals simulation time, this is a special case that
MUST be formally justified:
- Simulation runs at render rate (variable timestep)
- No frame drops have occurred
- No time scaling has been applied
- No pause/resume has occurred

The burden of proof is on the claim that frame = simulation time.
The default assumption is: they are independent.
```

### 4.4 Identity Mapping

```yaml
concept: SCR_SID
source: SCR internal identity system
scr_interpretation: >
  SCR_SID (SCR Semantic Identity) is the persistent, globally unique
  identity for entities across all computational domains. SCR_SID is
  UUID-based (v4 random or v7 time-ordered). SCR_SID is the semantic
  authority for "which entity is this" — it survives session boundaries,
  host changes, reconnection, and serialization. SCR_SID is NOT a
  handle — it is an identity. Handles (EntityId, network ID) are
  session-local references to an entity identified by SCR_SID.
invariants:
  - IDENT-001: SCR_SID MUST be UUID-based and globally unique.
  - IDENT-002: SCR_SID MUST persist across sessions, reconnection, and serialization.
  - IDENT-003: SCR_SID is the semantic authority for entity identity.
  - IDENT-004: Handles (EntityId, network ID) are NOT identities — they are session-local references.
```

#### 4.4.1 Identity Mapping Table

| SCR Identity | Provider Identity | Scope | Lifetime | Collision Risk | Notes |
|---|---|---|---|---|---|
| **SCR_SID** | `AZ::EntityId` | Provider-local (host) | Session (level unload destroys) | Low within session | Handle, not identity. Reassigned on re-creation. |
| **SCR_SID** | `AZ::Uuid` | Global | Permanent (asset lifetime) | Negligible (UUID v4) | Persistent identity. Used for serialization. |
| **SCR_SID** | USD Prim Path | USD-local | Stage lifetime | None (path-based) | Hierarchical path. Unique within stage. |
| **SCR_SID** | Network Entity ID | Network-local | Session (connection) | No (server-assigned) | Server assigns. New ID on reconnect. |
| **SCR_SID** | ROS 2 Node Name | Namespace-local | Node lifetime | Medium (string-based) | Must be unique within namespace. |
| **SCR_SID** | ROS 2 Topic Name | Namespace-local | Publication lifetime | Medium (string-based) | Must be unique within namespace for typed topics. |

#### 4.4.2 Identity Lifecycle

```
┌─────────────────────────────────────────────────────────────────────┐
│                    IDENTITY LIFECYCLE                                │
│                                                                     │
│  1. Creation: SCR_SID generated (UUID v4/v7)                       │
│       │                                                             │
│       ├──→ AZ::EntityId assigned (host-local handle)               │
│       ├──→ Network Entity ID assigned (server-assigned)            │
│       ├──→ USD Prim Path assigned (stage-scoped)                   │
│       └──→ ROS 2 Node Name registered (namespace-scoped)          │
│                                                                     │
│  2. Session: Handles reference SCR_SID                              │
│       │                                                             │
│       ├──→ EntityId valid within host session                       │
│       ├──→ Network ID valid within network session                  │
│       ├──→ USD Path valid within stage                              │
│       └──→ ROS Name valid within namespace                         │
│                                                                     │
│  3. Reconnection: Handles MAY change, SCR_SID persists             │
│       │                                                             │
│       ├──→ New EntityId (new host session)                         │
│       ├──→ New Network ID (new network session)                    │
│       ├──→ USD Path unchanged (stage persists)                     │
│       └──→ ROS Name unchanged (node persists)                      │
│                                                                     │
│  4. Serialization: SCR_SID is serialized, handles are not          │
│       │                                                             │
│       └──→ SCR_SID in persistent storage, cross-system references  │
│                                                                     │
│  5. Destruction: SCR_SID invalidated, all handles released         │
└─────────────────────────────────────────────────────────────────────┘
```

#### 4.4.3 Identity Mapping Invariants

| Invariant | Statement |
|-----------|-----------|
| **IDENT-005** | `AZ::EntityId` is a handle, not an identity. It MUST NOT be serialized as a persistent reference. |
| **IDENT-006** | Network Entity ID is session-scoped. It MAY change on reconnection. SCR_SID persists. |
| **IDENT-007** | USD Prim Path is stage-scoped. It persists within a stage but NOT across stage reloads. |
| **IDENT-008** | ROS 2 Node Name is namespace-scoped. It persists within a node lifetime but NOT across node restart. |
| **IDENT-009** | Cross-system references MUST use SCR_SID, not provider-specific handles. |
| **IDENT-010** | Identity mapping MUST record provenance: source system, handle value, SCR_SID, timestamp. |

### 4.5 State Ownership Model

#### 4.5.1 State Ownership Definitions

| Term | Definition |
|------|------------|
| **Owner** | Host that controls entity lifecycle (creation, destruction) and input stream. From Sprint 02: DIST-OWN-001 through 006. |
| **Mutator** | Host that has write permission on a specific state property. May differ from Owner. |
| **Observer** | Host that reads replicated state. Always non-destructive (Sprint 02: DIST-OBS-001). |
| **Predictor** | Host that speculatively advances state before authority confirmation (Sprint 03: PRED-INV-004). |
| **Reconciler** | Host that resolves divergence between predicted and authoritative state (Sprint 03: PRED-INV-008). |

#### 4.5.2 State Ownership Table

| State | Owner | Mutator | Observer | Predictor | Reconciler |
|---|---|---|---|---|---|
| **Entity position** | Authority | Authority | All replicas | Autonomous client | Authority (on authority update) |
| **Entity rotation** | Authority | Authority | All replicas | Autonomous client | Authority |
| **Entity velocity** | Authority | Authority | All replicas | Autonomous client | Authority |
| **Component data (general)** | Owner host | Owner host | Peers (via replication) | Owner (if predictable) | Owner (on authority update) |
| **Animation state** | Authority | Authority | All replicas | Autonomous client | Authority |
| **Physics state** | Authority | Authority | All replicas | Autonomous client | Authority |
| **Input state** | Owner (client) | Owner (client) | Authority (receives input) | Owner (local) | Authority (validates) |
| **Health/damage** | Authority | Authority | All replicas | None (not predicted) | Authority |
| **Inventory** | Authority | Authority | Owner only (via ReplicateTo) | None | Authority |
| **Spawn/despawn** | Authority | Authority | All replicas | None | Authority |
| **Audio state** | Local host | Local host | None (not replicated) | None | None |
| **Visual effects** | Local host | Local host | None (not replicated) | None | None |
| **Camera state** | Local host | Local host | None (not replicated) | None | None |

#### 4.5.3 Ownership Granularity

```
OWNERSHIP IS PER-PROPERTY, NOT PER-ENTITY

The same entity may have:
- Authority-writable position (server controls)
- Owner-writable input (client sends)
- Authority-writable health (server controls)
- Local-only visual effects (not replicated)

Each property declares its own:
- Mutator: who can write
- Replication direction: who receives updates
- Prediction scope: who can predict
- Reconciliation authority: who resolves conflicts

This is NOT a contradiction of "one authority per entity."
Authority is per-entity for lifecycle and state truth.
Ownership of specific properties MAY diverge from entity authority
for input and presentation concerns.
```

#### 4.5.4 State Ownership Invariants

| Invariant | Statement |
|-----------|-----------|
| **OWN-STATE-001** | Every mutable state property MUST declare its Mutator. |
| **OWN-STATE-002** | Mutator MUST be the Authority for that property, unless explicit delegation is declared. |
| **OWN-STATE-003** | Observer MUST be declared for every replicated property. Non-replicated properties have no observers. |
| **OWN-STATE-004** | Predictor MUST be declared for every predicted property. Non-predicted properties have no predictor. |
| **OWN-STATE-005** | Reconciler MUST be declared for every predicted property. Authority is the default reconciler. |
| **OWN-STATE-006** | State ownership MAY differ from entity authority for input and presentation properties. |
| **OWN-STATE-007** | Non-replicated state (audio, visual, camera) is local-only. No observer, no predictor, no reconciler. |
| **OWN-STATE-008** | State ownership MUST record provenance: entity, property, owner, mutator, observer, predictor, reconciler, timestamp. |

## 5. Cross-Cutting Properties

### 5.1 Temporal × Identity Interaction

| Concept | Temporal Property | Identity Property |
|---------|-------------------|-------------------|
| Entity creation | WallClock timestamp of creation | SCR_SID generated, handles assigned |
| State observation | ObservationTime recorded | Observer host identified by handle |
| Authority update | NetworkTime of authority state | Authority host identified by SCR_SID |
| Prediction | SimulationTime of prediction | Predicted entity by SCR_SID |
| Reconciliation | SimulationTime of reconciliation | Divergence point by timestamp + entity |

### 5.2 Temporal × Ownership Interaction

| State | Temporal Authority | Ownership Authority |
|-------|-------------------|---------------------|
| Entity position | SimulationTime | Authority (mutator) |
| Input state | NetworkTime (timestamped) | Owner (client) |
| Physics state | PhysicsTimestep | Authority |
| Animation state | FrameTime (interpolation) | Authority |
| Prediction state | SimulationTime | Predictor (client) |

### 5.3 M004 Invariant Coverage

| M004 Invariant | Coverage |
|----------------|----------|
| **Authority transitions are explicit** | Sprint 02 (DIST-AUTH-002) |
| **Prediction does not silently overwrite authoritative state** | Sprint 03 (PRED-INV-001) |
| **Replicated state has defined ownership** | Sprint 02 (DIST-OWN-001 through 006) + Sprint 04 (OWN-STATE-001 through 008) |
| **Time ordering is preserved across distributed observations** | Sprint 04 (TEMP-SIM-003, TEMP-NET-001, TEMP-OBS-001, TEMP-FRAME-002) |

## 6. Exit Criteria Verification

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Frame number ≠ simulation time unless formally justified | ✓ | Section 4.3: Frame ≠ Simulation Time invariant; TEMP-FRAME-001, TEMP-FRAME-002 |
| Identity scope/lifetime/stability/collision documented | ✓ | Section 4.4.1: Identity Mapping Table with scope, lifetime, collision columns |
| State ownership explicit for all mapped states | ✓ | Section 4.5.2: State Ownership Table with Owner/Mutator/Observer/Predictor/Reconciler |
| Temporal semantics classified | ✓ | Section 4.1: Six temporal concepts with definitions and invariants |

## 7. Invariant Registry

### 7.1 All Invariants Added This Sprint

| Invariant | Statement |
|-----------|-----------|
| **TEMP-WC-001** | WallClock MUST be monotonic for sequencing. |
| **TEMP-WC-002** | WallClock MAY diverge from SimulationTime. Divergence MUST be declared. |
| **TEMP-WC-003** | WallClock MUST record provenance. |
| **TEMP-WC-004** | WallClock is the temporal authority for real-world event ordering. |
| **TEMP-SIM-001** | SimulationTime MUST advance monotonically within the simulation. |
| **TEMP-SIM-002** | SimulationTime MUST NOT silently diverge from declared timestep. |
| **TEMP-SIM-003** | SimulationTime is the temporal authority for simulation-ordered events. |
| **TEMP-SIM-004** | SimulationTime MAY be paused, scaled, or reset — each operation MUST be declared. |
| **TEMP-SIM-005** | SimulationTime MUST record provenance. |
| **TEMP-OBS-001** | ObservationTime MUST be recorded at the moment of observation. |
| **TEMP-OBS-002** | ObservationTime MUST be later than or equal to origin time. |
| **TEMP-OBS-003** | Staleness = ObservationTime - originTime. MUST be calculable. |
| **TEMP-OBS-004** | ObservationTime MUST record provenance. |
| **TEMP-NET-001** | NetworkTime MUST be authoritative. |
| **TEMP-NET-002** | NetworkTime MUST be consistent across all hosts. Discrepancies MUST be declared. |
| **TEMP-NET-003** | NetworkTime is used for input timestamping and authority update ordering. |
| **TEMP-NET-004** | NetworkTime MUST record provenance. |
| **TEMP-NET-005** | NetworkTime MAY be frame-derived or wall-clock-derived. Derivation MUST be declared. |
| **TEMP-FRAME-001** | FrameTime is the interval between render frames, not simulation time. |
| **TEMP-FRAME-002** | FrameTime MUST NOT be used for simulation ordering. |
| **TEMP-FRAME-003** | FrameTime MAY vary. Variance MUST NOT affect simulation correctness. |
| **TEMP-FRAME-004** | FrameTime MUST record provenance. |
| **TEMP-PHY-001** | PhysicsTimestep MUST be constant for deterministic integration. |
| **TEMP-PHY-002** | PhysicsTimestep MAY accumulate fractional steps. |
| **TEMP-PHY-003** | PhysicsTimestep is subordinate to SimulationTime. |
| **TEMP-PHY-004** | PhysicsTimestep MUST record provenance. |
| **IDENT-001** | SCR_SID MUST be UUID-based and globally unique. |
| **IDENT-002** | SCR_SID MUST persist across sessions, reconnection, and serialization. |
| **IDENT-003** | SCR_SID is the semantic authority for entity identity. |
| **IDENT-004** | Handles are NOT identities — they are session-local references. |
| **IDENT-005** | `AZ::EntityId` is a handle, not an identity. MUST NOT be serialized as persistent reference. |
| **IDENT-006** | Network Entity ID is session-scoped. MAY change on reconnection. |
| **IDENT-007** | USD Prim Path is stage-scoped. Persists within stage, not across reloads. |
| **IDENT-008** | ROS 2 Node Name is namespace-scoped. Persists within node lifetime. |
| **IDENT-009** | Cross-system references MUST use SCR_SID. |
| **IDENT-010** | Identity mapping MUST record provenance. |
| **OWN-STATE-001** | Every mutable state property MUST declare its Mutator. |
| **OWN-STATE-002** | Mutator MUST be the Authority, unless explicit delegation. |
| **OWN-STATE-003** | Observer MUST be declared for every replicated property. |
| **OWN-STATE-004** | Predictor MUST be declared for every predicted property. |
| **OWN-STATE-005** | Reconciler MUST be declared for every predicted property. |
| **OWN-STATE-006** | State ownership MAY differ from entity authority. |
| **OWN-STATE-007** | Non-replicated state is local-only. |
| **OWN-STATE-008** | State ownership MUST record provenance. |

### 7.2 Relationship to Prior Sprint Invariants

| Sprint | Invariants | Relationship to Sprint 04 |
|--------|------------|--------------------------|
| Sprint 02 | DIST-AUTH-001 through 005 | Authority definitions inform Mutator role |
| Sprint 02 | DIST-OWN-001 through 006 | Ownership definitions inform Owner role |
| Sprint 02 | DIST-OBS-001 through 006 | Observation definitions inform Observer role and ObservationTime |
| Sprint 03 | PRED-INV-001 through 032 | Prediction definitions inform Predictor and Reconciler roles |

## 8. Notes

- This sprint completes M004's four formal invariants.
- The six temporal concepts (WallClock, SimulationTime, ObservationTime, NetworkTime, FrameTime, PhysicsTimestep) are the canonical SCR temporal vocabulary.
- The identity model separates handles from identities — this is the core architectural contribution.
- State ownership is per-property, not per-entity — this enables fine-grained distributed control.
- All invariants follow the TEMP-, IDENT-, or OWN-STATE- prefix conventions.
