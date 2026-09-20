# SCR Simulation–Presentation IPC Architecture

**Status:** Proposed; ready for repository review  
**Scope:** SCR runtime architecture  
**Reference platform:** Linux  
**Reference local transport:** Hyrx over AF_UNIX  
**Reference renderer:** OGRE 1.x + Vulkan  
**Reference simulation providers:** CUDA, OpenVDB/NanoVDB, Bullet3D

## 1. Purpose

Separate authoritative simulation from presentation while allowing them to execute in independent processes. The boundary is semantic and transport-independent; AF_UNIX, Hyrx, shared memory, DMA-BUF and GPU interop are providers.

```text
Authoritative World
      |
Simulation Runtime
      |
Semantic Projection
      |
Hyrx / AF_UNIX  <---- control + semantic metadata
      |
      +---- memfd/shared memory <---- large CPU-visible payloads
      |
      +---- exported OS/GPU handles <---- eligible GPU resources
      |
Presentation Runtime
      |
RenderWorld
      |
OGRE / Vulkan / Wayland
```

## 2. Normative vocabulary

**World:** authoritative simulation state and semantic relationships.  
**RenderWorld:** disposable, derived presentation projection.  
**Projection:** a read-only transformation from a committed World state and observer requirements to one or more render representations.  
**Representation:** a semantic description of data needed by a consumer; not an OGRE/Vulkan object.  
**Provider:** concrete implementation of a semantic interface.  
**Generation:** monotonic identity for a committed state or resource version within its defined scope.

The terms **MUST**, **MUST NOT**, **SHOULD**, and **MAY** express requirements.

## 3. Process ownership

### Simulation process owns
- authoritative entities, transforms and physical/material state;
- fluid and rigid-body state;
- spatial topology and simulation domains;
- simulation clock, ticks and commit sequence;
- causal/dynamical state and simulation versions.

### Presentation process owns
- observers, cameras and viewports;
- RenderWorld and local render caches;
- render geometry, materials and GPU resources;
- visibility, LOD, render scheduling and screen-space effects;
- OGRE/Vulkan/Wayland-specific state.

The renderer MUST NOT directly mutate authoritative simulation state. Requests to change simulation state must pass through an explicit simulation command/API with authorization, validation and commit semantics.

## 4. World → Projection → RenderWorld

```text
World(version, generation)
        |
        v
Projection(world, observer, view, time, capabilities, subscription)
        |
        v
RenderWorld(source version/generation, projection version)
```

Projection is read-only with respect to World. It may filter, aggregate, interpolate compatible committed states, simplify, decimate, cull or select LOD. Such operations MUST NOT alter authoritative semantics.

One World may serve multiple observers, renderers, recorders or analysis clients.

## 5. Logical traffic planes

Implementations MAY multiplex these planes over one connection or use multiple channels.

### 5.1 Control
Reliable request/response: `HELLO`, `CAPABILITIES`, `NEGOTIATE`, `AUTHENTICATE`, `SUBSCRIBE`, `UNSUBSCRIBE`, `SNAPSHOT_REQUEST`, `SET_TIME`, `PAUSE`, `RESUME`, `QUERY`, `ACK`, `ERROR`, `GOODBYE`.

### 5.2 Semantic state
State and lifecycle: `WORLD_RESET`, `STATE_COMMITTED`, `ENTITY_CREATED`, `ENTITY_UPDATED`, `ENTITY_REMOVED`, `FIELD_UPDATED`, `DOMAIN_CREATED`, `DOMAIN_UPDATED`, `DOMAIN_REMOVED`, `RESOURCE_INVALIDATED`.

### 5.3 Resource
Resource metadata and lifecycle: `RESOURCE_OFFER`, `RESOURCE_ACCEPT`, `RESOURCE_RELEASE`, `RESOURCE_INVALIDATED`. Large payloads SHOULD be transferred out-of-band through shared memory or OS/GPU resource handles.

Message names are proposed protocol vocabulary, not existing Hyrx wire opcodes.

## 6. Transport boundary

SCR defines message meaning and state semantics independently of Hyrx. The initial Linux provider may use Hyrx over AF_UNIX. A future provider may use TCP, RDMA or another transport without changing semantic contracts.

Hyrx is not the authority for World state. It transports messages and resource references.

## 7. Resource indirection

A resource offer should identify:

```text
resource_id
semantic_id
content_id
resource_generation
representation_type
format
dimensions / layout
memory_domain
access_mode
synchronization_contract
lifetime / lease
handle_type
```

Actual file descriptors or provider handles are transferred through the platform mechanism, not serialized as ordinary integers and treated as globally meaningful. Handle validity is scoped to a session and resource contract.

Do not send process-local pointers across the socket. Do not assume a CUDA pointer is valid in another process or in Vulkan.

## 8. Large-resource path

Preferred when supported and verified:

```text
simulation GPU resource
   -> provider-specific export
   -> OS handle + synchronization metadata over AF_UNIX
   -> renderer imports resource
```

Fallback:

```text
simulation GPU
   -> staging/readback
   -> memfd/shared memory
   -> renderer mapping/upload
```

The GPU provider owns CUDA/Vulkan interop details, format compatibility, synchronization, device identity and fallback. A successful handle transfer alone does not prove safe import or synchronization.

## 9. Resource lifecycle and generations

Resource handles MUST have explicit ownership, lifetime and generation. A consumer MUST NOT use a released, invalidated or mismatched-generation resource.

The renderer MAY continue rendering the last valid resource while a newer generation is prepared, provided it identifies the displayed source generation and does not present it as current.

## 10. Clock and commit model

Simulation owns authoritative time. Each committed state identifies:

- `simulation_tick`;
- `simulation_time`;
- `world_version`;
- `state_generation`;
- `determinism_epoch`.

A commit is an atomic visibility boundary: external consumers see a self-consistent committed state, not partially updated numerical buffers. Exact numeric encodings and clock units are specified in the protocol schema before implementation.

The renderer may request an exact recorded generation/time, or latest-available state. Rendering/interpolation MUST NOT advance simulation.

## 11. Snapshot and delta recovery

A client establishes a session, negotiates capabilities, subscribes, then obtains a consistent snapshot and subsequent deltas.

```text
CONNECT -> HELLO -> NEGOTIATE -> SUBSCRIBE
        -> SNAPSHOT_REQUEST -> SNAPSHOT
        -> ordered updates
```

The snapshot MUST declare its world version and generation. The server must define the snapshot/delta cut so updates are neither lost nor applied twice across the boundary.

If a client detects a generation gap, incompatible version or invalidated resource, it MUST request resynchronization or an explicitly supported repair operation. It MUST NOT silently apply deltas to an unknown base.

## 12. Spatial subscriptions

Subscriptions MAY constrain:
- observer and spatial region;
- semantic classes/filters;
- requested representations;
- temporal policy;
- LOD or resource budget.

SCR's hierarchical spatial model can support coarse-to-fine subscription. Parent/child inheritance, boundary inclusion, moving observers and subscription update atomicity must be defined by the projection specification.

The simulation need not stream the entire continental/oceanic World to a local renderer.

## 13. Fluid and sparse-volume projection

Fluid solvers remain simulation-side. A semantic fluid state may produce multiple derived representations:

```text
fluid state
  +-- surface -> surface representation
  +-- spray/foam -> particle representation
  +-- density/temperature -> volume representation
  +-- velocity -> motion-vector or visualization representation
```

OpenVDB/NanoVDB are representation/provider choices, not the IPC contract. NanoVDB may be useful for GPU-oriented sparse access; the projection must not assume every consumer supports it.

## 14. Backpressure and freshness

Simulation progress MUST NOT be paced by renderer frame rate unless an explicit coupled execution mode is selected.

Classify traffic:
- **authoritative events:** reliable; never silently dropped;
- **state deltas:** ordered and recoverable;
- **replaceable render resources:** may be coalesced or superseded;
- **advisory hints:** may be dropped.

Queues MUST be bounded. Define per-class overflow behavior, cancellation, resource cleanup and stale-frame policy. “Latest state” is valid only where intermediate states are not required by the consumer.

## 15. Observer and screen-space effects

A camera is represented at the semantic boundary as an Observer with position, orientation, projection/view parameters, viewport and visibility requirements. Concrete OGRE camera objects remain local.

Screen-space displacement mapping, SSR, SSAO, motion blur and temporal reconstruction belong to presentation. They consume render buffers and camera/frame history and MUST NOT mutate World.

## 16. Failure isolation

- Renderer crash/disconnect MUST NOT invalidate simulation.
- Renderer reconnects through negotiation, subscription and snapshot recovery.
- Simulation restart changes/invalidates the session and state epoch; clients must detect this and reconstruct.
- The renderer may retain a clearly marked last-valid frame while simulation is unavailable.
- Resource leases and disconnect cleanup must prevent leaked mappings/handles.

## 17. Offline and multi-client operation

The same semantic projection supports headless simulation, recorded snapshots, offline rendering, analysis clients and multiple renderers. Each client has an independent subscription/projection and capability set.

Replay must distinguish authoritative recorded state from recomputed simulation. Deterministic replay requires a separately specified determinism contract; merely recording snapshots does not prove bitwise deterministic recomputation.

## 18. Identity and security

SCR SIDs identify semantic entities and resources. Process-local pointers and OGRE handles are never semantic identity. OS credentials authenticate local peers at the transport layer; SCR authorization determines which semantic operations and subscriptions are permitted.

Do not treat a client-supplied SID as proof of authority. Validate message sizes, schema/version, capabilities, resource descriptors and access rights. Define socket path permissions and stale-socket handling.

## 19. Capability negotiation

Negotiate protocol/schema versions and supported representations, encodings, compression, resource mechanisms, memory domains, formats and GPU interop capabilities.

The projection selects only capabilities actually negotiated. Capability claims are not proof that a particular resource import will succeed; resource import requires explicit accept/failure handling.

## 20. Proposed invariants

- **INV-001 Authority:** only simulation commits authoritative state.
- **INV-002 Read-only projection:** projection cannot mutate World.
- **INV-003 Semantic protocol:** wire contracts do not expose OGRE/Vulkan commands.
- **INV-004 Provider independence:** semantic contracts do not depend on Hyrx/AF_UNIX.
- **INV-005 No pointer identity:** process-local pointers never cross as identity.
- **INV-006 Generation safety:** snapshots, deltas and resources identify source generations.
- **INV-007 Consistent snapshot cut:** snapshot plus following deltas has no gap or duplicate application.
- **INV-008 Recovery:** incompatible state requires explicit resynchronization.
- **INV-009 Timing authority:** simulation owns authoritative time.
- **INV-010 Spatial selectivity:** clients can request bounded semantic regions.
- **INV-011 Disposable RenderWorld:** RenderWorld can be discarded and regenerated.
- **INV-012 Failure isolation:** renderer failure does not require simulation restart.
- **INV-013 Explicit resource lifetime:** imported resources have validated lifetime and synchronization.
- **INV-014 Backpressure safety:** bounded queues and explicit overflow policies.
- **INV-015 Provider isolation:** CUDA, Vulkan, OGRE, Bullet, OpenVDB, NanoVDB and Hyrx remain behind interfaces.

## 21. Verification requirements

The reference executor must test without OGRE/CUDA/Bullet:
1. handshake and version mismatch;
2. capability negotiation;
3. snapshot/delta cut consistency;
4. ordering, duplicate and gap handling;
5. resynchronization;
6. subscription create/update/remove;
7. spatial filtering;
8. bounded-queue backpressure;
9. resource offer/accept/release/invalidation;
10. disconnect cleanup;
11. renderer restart;
12. simulation epoch restart;
13. multiple clients;
14. malformed/oversized messages;
15. unauthorized operations;
16. offline snapshot replay.

Provider tests separately cover memfd/FD passing, GPU import/export, synchronization, device mismatch and CPU fallback.

## 22. Golden path

1. Start simulation and establish World.
2. Start Hyrx local transport provider.
3. Start presentation client.
4. Negotiate protocol and capabilities.
5. Establish observer and spatial subscription.
6. Obtain consistent snapshot.
7. Build RenderWorld.
8. Consume ordered state changes and accepted resources.
9. Render independently of simulation cadence.
10. Disconnect/restart renderer and recover from snapshot.
11. Verify simulation continues throughout renderer failure.
