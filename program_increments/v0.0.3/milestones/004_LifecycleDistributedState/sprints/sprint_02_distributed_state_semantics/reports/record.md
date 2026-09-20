# Sprint 002 Record: Distributed-State Semantics

## 1. Objective

Define the SCR distributed-state semantic family: Authority, Ownership, Replication, Observation, RemoteOperation. Each definition derives from O3DE Multiplayer/AzNetworking research, generalised beyond games to robotics, distributed-simulation, and digital-twins. Transport semantics (UDP/TCP/reliable/unreliable) are explicitly separated from computational meaning.

## 2. Scope & Boundaries

### 2.1 What This Sprint Covers

Five core distributed-state semantic concepts:

| Concept | Purpose |
|---------|---------|
| **Authority** | Which host has ultimate read/write rights over entity state |
| **Ownership** | Which host controls entity lifecycle and input |
| **Replication** | Delta-based state synchronization from authority to replicas |
| **Observation** | Reading replicated state from non-authority host |
| **RemoteOperation** | Invoking operations across host boundaries |

### 2.2 What This Sprint Does NOT Cover

- Prediction and reconciliation (Sprint 03)
- Temporal identity and state ownership model (Sprint 04)
- Transport-layer protocols (explicitly separated)
- Provider-specific implementations (O3DE NetEntityRole is provider-specific, not SCR semantic)

### 2.3 Relationship to M004 Invariants

All definitions must satisfy M004's four formal invariants:

1. Authority transitions are explicit
2. Prediction does not silently overwrite authoritative state
3. Replicated state has defined ownership
4. Time ordering is preserved across distributed observations

## 3. Research Source: O3DE Multiplayer/AzNetworking

### 3.1 O3DE NetEntityRole (Provider-Specific)

O3DE defines four compile-time enforced roles for networked entities:

| O3DE Role | Description |
|-----------|-------------|
| `Authority` | Ultimate read/write authority. Full access to all network properties. |
| `Autonomous` | Player-controlled entity. Can predict and modify predictable properties locally. Sends input to Authority. |
| `Server` | Peer server in multi-server setup. Receives replicated state but has no entity authority. |
| `Client` | Lowest privilege. Read-only. Smallest subset of replicated properties. Presentation logic and RPC proxy only. |

**Key O3DE insight:** Roles are compile-time enforced and provider-assigned. SCR authority is a semantic concept — the same entity may have different authority relationships depending on the computational domain, not just the network topology.

### 3.2 O3DE NetworkProperty (Replication Mechanism)

O3DE `NetworkProperty` attributes:

| Attribute | Values | Purpose |
|-----------|--------|---------|
| `ReplicateFrom` | `Authority`, `Autonomous` | Which role's changes propagate |
| `ReplicateTo` | `Server`, `Authority`, `Autonomous`, `Client` | Which roles receive updates |
| `IsPredictable` | `bool` | Autonomous can predict locally even if ReplicateFrom=Authority |
| `IsRewindable` | `bool` | Historic values recorded for rollback/reconciliation |

**Replication hierarchy** (O3DE): Authority-to-Client replicates to Autonomous and Server. Authority-to-Autonomous replicates to Server. Authority-to-Server replicates only to Server.

**Key O3DE insight:** Replication direction is defined per-property, not per-entity. SCR replication is a semantic transformation — the *meaning* of what changes must be preserved, not just the byte delta.

### 3.3 O3DE RPC (Remote Procedure Calls)

| Attribute | Values | Purpose |
|-----------|--------|---------|
| `InvokeFrom` | `Authority`, `Server`, `Autonomous` | Which role originates the call |
| `HandleOn` | `Authority`, `Autonomous`, `Client` | Which roles execute the handler |
| `IsReliable` | `bool` | Reliable (queued, retransmitted) vs unreliable (fire-and-forget) |

**Key O3DE insight:** RPC reliability and ordering are transport concerns. SCR RemoteOperation captures the semantic intent — invoking a computational operation on a remote host — independent of delivery guarantees.

### 3.4 O3DE Prediction & Reconciliation

- **Prediction:** Autonomous player modifies properties locally before server confirmation. `IsPredictable` flag permits this.
- **Reconciliation:** `IsRewindable` records historic property values per network tick. On authority update, client rewinds to authoritative state and resimulates.
- **Network Input:** Frame-stamped input from Autonomous to Authority. Authority rewinds before processing to maintain consistency.

**Key O3DE insight:** Prediction/reconciliation is a *strategy*, not a semantic primitive. SCR separates the semantic concept (applying speculative state) from the mechanism (rollback + resimulate).

### 3.5 O3DE Ownership & Spawning

- `IMultiplayerSpawner`: Server-side interface. `OnPlayerJoin` spawns autonomous entity. `OnPlayerLeave` cleans up.
- **Ownership** in O3DE is implicit: the Autonomous role entity is "owned" by its controlling connection.
- **Network Hierarchies:** Parent-child entity groups share input processing. `NetworkHierarchyRootComponent` + `NetworkHierarchyChildComponent`.

**Key O3DE insight:** Ownership in O3DE is tied to player connections. SCR ownership is a general semantic concept — any host may own any entity, not just the "player's" connection.

## 4. SCR Semantic Definitions

### 4.1 Authority

```yaml
concept: Authority
source: O3DE Multiplayer
source_terminology: NetEntityRole::Authority
scr_interpretation: >
  Authority designates which host holds ultimate read/write rights over an
  entity's state. Authority is a semantic property of the entity-host
  relationship, not a network role. The authoritative host is the single
  source of truth for all state mutations; replica hosts receive derived
  state through replication. Authority transitions are explicit events —
  no host may silently acquire or lose authority.
differences: >
  O3DE NetEntityRole is a compile-time-enforced network role with four
  fixed values (Authority, Autonomous, Client, Server). SCR Authority is
  a semantic relationship that varies per entity, per domain, and may
  change at runtime through explicit transfer. O3DE authority is always
  held by the server; SCR authority may be held by any host, including
  edge devices, robotic controllers, or simulation nodes. O3DE conflates
  authority with "server" — SCR decouples them. An O3DE Autonomous entity
  can predict but not own; SCR Authority encompasses both prediction
  permission and mutation rights.
invariants:
  - DIST-AUTH-001: Every entity has exactly one authoritative host at any time.
  - DIST-AUTH-002: Authority transitions are explicit events with source, target, reason, and timestamp.
  - DIST-AUTH-003: Replica hosts MUST NOT mutate state on entities where they lack authority.
  - DIST-AUTH-004: Authority MAY be delegated, revoked, or transferred — each transition is an explicit semantic operation.
  - DIST-AUTH-005: Authority is defined per-entity, not per-host. A host may be authoritative for some entities and replica for others.
```

### 4.2 Ownership

```yaml
concept: Ownership
source: O3DE Multiplayer
source_terminology: Autonomous role + IMultiplayerSpawner
scr_interpretation: >
  Ownership designates which host controls an entity's lifecycle (creation,
  destruction) and input stream. Ownership is distinct from Authority:
  the owner provides inputs and manages lifecycle, while Authority is the
  semantic source of truth for state mutations. An owner MAY lack Authority
  (input is processed by the authoritative host); an Authority MAY lack
  ownership (the authoritative host may not control entity lifecycle).
differences: >
  O3DE ownership is implicit — the Autonomous role implies ownership of the
  player entity, and IMultiplayerSpawner manages spawn/despawn on the server.
  O3DE conflates ownership with "the player who controls this entity."
  SCR Ownership is explicit: every mutable entity declares its owner. Ownership
  covers lifecycle AND input, but not mutation rights (that is Authority).
  Ownership MAY be exclusive, shared, or delegated. Ownership MAY transfer
  between hosts (e.g., entity migration between simulation nodes).
  O3DE's Network Hierarchy implies shared ownership within a parent-child
  group; SCR Ownership makes this explicit per-entity.
invariants:
  - DIST-OWN-001: Every mutable entity MUST have exactly one owner at any time.
  - DIST-OWN-002: Ownership defines lifecycle rights: only the owner MAY create or destroy the entity.
  - DIST-OWN-003: Ownership defines input rights: only the owner MAY send input to the entity.
  - DIST-OWN-004: Ownership MAY transfer between hosts via explicit transfer operation.
  - DIST-OWN-005: Ownership DOES NOT imply Authority. Ownership and Authority are independent semantic properties.
  - DIST-OWN-006: Ownership DOES NOT imply mutation rights. Mutation requires Authority, not Ownership.
```

### 4.3 Replication

```yaml
concept: Replication
source: O3DE Multiplayer
source_terminology: NetworkProperty + Delta Replication
scr_interpretation: >
  Replication is the semantic transformation that distributes state changes
  from the authoritative host to replica hosts. Replication is delta-based:
  only changed state propagates. Replication preserves semantic meaning —
  the delta represents a semantic state transition, not a byte difference.
  Replication is directional: authority → replicas. Bidirectional state
  convergence is not replication; it is conflict resolution (a separate
  semantic concept).
differences: >
  O3DE replication is a mechanism: delta-based state sync via
  NetworkProperty with ReplicateFrom/ReplicateTo directions and
  hierarchy rules. O3DE replication is push-based and event-driven.
  SCR Replication is the semantic transformation itself — the meaning
  of "authority state changes propagate to replicas." SCR replication
  is agnostic to mechanism: delta-based, snapshot-based, CRDT-based,
  or event-sourced replication all satisfy the SCR semantic contract.
  O3DE replication hierarchy (Authority-to-Client implies Authority-to-Autonomous)
  is a provider-specific optimization; SCR replication defines no hierarchy —
  the replication topology is a provider concern. O3DE uses ACK-based
  reliable transport for replication; SCR separates transport from semantics.
  Transport reliability is a provider choice, not a semantic property.
invariants:
  - DIST-REP-001: Replication originates from the authoritative host only. Replica hosts MUST NOT originate replication.
  - DIST-REP-002: Replication MUST preserve semantic meaning. The receiving host MUST interpret replicated state with the same semantic properties as the sending host.
  - DIST-REP-003: Replication is directional: authority → replicas. Convergence is not replication.
  - DIST-REP-004: Replication MAY be delta-based, snapshot-based, or event-sourced. The mechanism is a provider concern.
  - DIST-REP-005: Transport reliability (reliable/unreliable, ordered/unordered) is a provider choice, not a semantic property of replication.
  - DIST-REP-006: Replication MUST record provenance: source host, target host, semantic delta, timestamp, authority at time of replication.
```

### 4.4 Observation

```yaml
concept: Observation
source: O3DE Multiplayer
source_terminology: Client-side read of replicated NetworkProperty
scr_interpretation: >
  Observation is the semantic operation of reading replicated state from a
  non-authority host. Observation is always non-destructive — reading state
  does not modify it. Observation captures a point-in-time snapshot of the
  replicated world view from a specific host's perspective. Observation
  output is authoritative for the observing host but MAY be stale relative
  to the authoritative host's current state.
differences: >
  O3DE does not have an explicit "observation" concept. Clients read
  replicated NetworkProperty values directly — there is no semantic
  distinction between "reading replicated state" and "accessing local state."
  SCR Observation makes this distinction explicit: reading replicated state
  is a semantic operation with defined properties (non-destructive,
  point-in-time, potentially stale). O3DE's IsRewindable property enables
  historical observation (rewinding to past states for reconciliation);
  SCR Observation is a generalised concept covering both current and
  historical snapshots. O3DE observation is implicitly scoped by
  ReplicateTo rules (clients see only what is replicated to them);
  SCR Observation explicitly declares its projection scope.
invariants:
  - DIST-OBS-001: Observation MUST be non-destructive. Reading state MUST NOT modify the observed or observing host's state.
  - DIST-OBS-002: Observation captures a point-in-time snapshot. Temporal ordering MUST be preserved within the snapshot.
  - DIST-OBS-003: Observation output MAY be stale relative to the authoritative host's current state. Staleness MUST be declared.
  - DIST-OBS-004: Observation MUST declare its projection scope: which entities, which properties, which host's perspective.
  - DIST-OBS-005: Observation output MUST be semantically consistent with the observed state. No semantic properties may be invented.
  - DIST-OBS-006: Observation MAY serve as input to a new authoring cycle, enabling the lifecycle loop.
```

### 4.5 RemoteOperation

```yaml
concept: RemoteOperation
source: O3DE Multiplayer
source_terminology: RemoteProcedure (RPC)
scr_interpretation: >
  RemoteOperation is the semantic concept of invoking a computational
  operation on a remote host. A RemoteOperation carries semantic intent —
  "execute this operation with these parameters on that host" — independent
  of delivery mechanism. RemoteOperations MAY be reliable (guaranteed
  delivery) or unreliable (best-effort). Reliability is a transport
  property, not a semantic property of the operation itself. RemoteOperations
  MAY be ordered or unordered relative to other operations. Ordering is a
  transport property.
differences: >
  O3DE RPCs are defined with InvokeFrom/HandleOn role pairs and IsReliable
  flag. O3DE RPCs are provider-specific: the same RPC definition is tied
  to O3DE's NetEntityRole system. SCR RemoteOperation is the generalised
  semantic concept: any operation invoked on a remote host. O3DE RPCs
  are always between defined roles (Authority, Autonomous, Client, Server);
  SCR RemoteOperations are between any two hosts with defined authority
  relationships. O3DE conflates operation direction (InvokeFrom) with
  handler target (HandleOn); SCR separates: RemoteOperation declares
  source host and target host, not source/target roles. O3DE's IsReliable
  is a transport concern; SCR captures it as a delivery contract, not
  a semantic property.
invariants:
  - DIST-ROP-001: RemoteOperations MUST declare source host and target host.
  - DIST-ROP-002: RemoteOperations MUST carry semantic intent: the operation name, parameters, and semantic contract.
  - DIST-ROP-003: Reliability (guaranteed delivery vs best-effort) is a transport contract, not a semantic property.
  - DIST-ROP-004: Ordering (sequential vs parallel) is a transport contract, not a semantic property.
  - DIST-ROP-005: RemoteOperations MUST NOT violate authority boundaries. A host MUST NOT invoke a RemoteOperation that mutates state on a host where it lacks authority.
  - DIST-ROP-006: RemoteOperation invocation MUST record provenance: source host, target host, operation, parameters, timestamp.
```

## 5. Semantic Family: Cross-Cutting Properties

### 5.1 Relationship Matrix

| | Authority | Ownership | Replication | Observation | RemoteOperation |
|---|-----------|-----------|-------------|-------------|-----------------|
| **Authority** | — | Independent | Originates from Authority | Observed by replicas | May invoke RemoteOperations |
| **Ownership** | Independent | — | Does not replicate | Observed by owner | Owner may invoke lifecycle operations |
| **Replication** | Authority → replicas | Ownership independent | — | Enables Observation | Transport for state deltas |
| **Observation** | Requires replicated state | Read-only | Produces snapshots | — | May trigger RemoteOperations |
| **RemoteOperation** | Must respect authority | May modify ownership | May trigger replication | Observable side effects | — |

### 5.2 Authority ≠ Ownership (Critical Distinction)

```
Authority:   "Who is the source of truth for state mutations?"
Ownership:   "Who controls lifecycle and input?"
Replication: "How do state changes propagate?"
Observation: "How do non-authority hosts read state?"
RemoteOperation: "How do hosts invoke operations on each other?"
```

O3DE conflates authority and ownership under `NetEntityRole::Authority` and `NetEntityRole::Autonomous`. SCR separates them because in distributed robotics, a central coordinator may have Authority while a local controller has Ownership; in digital twins, the physical twin has Authority while the simulation has Ownership.

### 5.3 Transport Separation

All five concepts are **transport-agnostic**. Transport properties are provider contracts:

| Transport Property | SCR Classification | Provider Concern |
|--------------------|-------------------|-----------------|
| Reliable delivery | Delivery contract | TCP, reliable UDP, QUIC |
| Unreliable delivery | Delivery contract | Unreliable UDP |
| Ordered delivery | Ordering contract | Sequence numbers, streams |
| Unordered delivery | Ordering contract | Fire-and-forget |
| Encrypted transport | Security contract | TLS, DTLS |
| Compressed transport | Efficiency contract | Provider-specific compression |

## 6. Invariant Registry

### 6.1 All Invariants Added This Sprint

| Invariant | Statement |
|-----------|-----------|
| **DIST-AUTH-001** | Every entity has exactly one authoritative host at any time. |
| **DIST-AUTH-002** | Authority transitions are explicit events with source, target, reason, and timestamp. |
| **DIST-AUTH-003** | Replica hosts MUST NOT mutate state on entities where they lack authority. |
| **DIST-AUTH-004** | Authority MAY be delegated, revoked, or transferred — each transition is an explicit semantic operation. |
| **DIST-AUTH-005** | Authority is defined per-entity, not per-host. |
| **DIST-OWN-001** | Every mutable entity MUST have exactly one owner at any time. |
| **DIST-OWN-002** | Ownership defines lifecycle rights: only the owner MAY create or destroy the entity. |
| **DIST-OWN-003** | Ownership defines input rights: only the owner MAY send input to the entity. |
| **DIST-OWN-004** | Ownership MAY transfer between hosts via explicit transfer operation. |
| **DIST-OWN-005** | Ownership DOES NOT imply Authority. |
| **DIST-OWN-006** | Ownership DOES NOT imply mutation rights. Mutation requires Authority. |
| **DIST-REP-001** | Replication originates from the authoritative host only. |
| **DIST-REP-002** | Replication MUST preserve semantic meaning. |
| **DIST-REP-003** | Replication is directional: authority → replicas. |
| **DIST-REP-004** | Replication MAY be delta-based, snapshot-based, or event-sourced. |
| **DIST-REP-005** | Transport reliability is a provider choice, not a semantic property. |
| **DIST-REP-006** | Replication MUST record provenance. |
| **DIST-OBS-001** | Observation MUST be non-destructive. |
| **DIST-OBS-002** | Observation captures a point-in-time snapshot. |
| **DIST-OBS-003** | Observation output MAY be stale. Staleness MUST be declared. |
| **DIST-OBS-004** | Observation MUST declare its projection scope. |
| **DIST-OBS-005** | Observation MUST be semantically consistent. |
| **DIST-OBS-006** | Observation MAY serve as input to authoring cycle. |
| **DIST-ROP-001** | RemoteOperations MUST declare source and target hosts. |
| **DIST-ROP-002** | RemoteOperations MUST carry semantic intent. |
| **DIST-ROP-003** | Reliability is a transport contract, not semantic. |
| **DIST-ROP-004** | Ordering is a transport contract, not semantic. |
| **DIST-ROP-005** | RemoteOperations MUST NOT violate authority boundaries. |
| **DIST-ROP-006** | RemoteOperation invocation MUST record provenance. |

## 7. Exit Criteria Verification

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Each definition has provenance | ✓ | Each definition cites O3DE source_terminology and research source |
| Definitions general enough for games/robotics/distributed-simulation/digital-twins | ✓ | Cross-domain examples in differences sections; transport-agnostic |
| Transport (UDP/TCP/reliable/unreliable) explicitly separated from semantics | ✓ | Section 5.3 Transport Separation; DIST-REP-005, DIST-ROP-003, DIST-ROP-004 |

## 8. Notes

- Prediction and reconciliation are deferred to Sprint 03 as specified in the sprint plan.
- Temporal identity and state ownership are deferred to Sprint 04.
- These five definitions form the semantic foundation for Sprint 03–04.
- All invariants follow the DIST- prefix convention for distributed-state semantics.
