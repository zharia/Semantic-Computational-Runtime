# D-003 — Cave Requirement Catalogue

**Program Increment:** CAVE-000  
**Artifact:** Cave Requirement Catalogue  
**Status:** Complete

## Preliminary Cave Capability Model

This catalogue maps Cave requirements to existing SCR capabilities or classifies them as gaps. All requirements are presented as investigation items, not declarations that SCR must contain primitives with these names (per CAVE-000 §8).

### Identity

| Requirement ID | Cave Requirement | Semantic Meaning | Existing SCR Capability | SCR Location | Evidence | Reusable | Distortion | Classification |
|---|---|---|---|---|---|---|---|---|
| CAVE-REQ-IDENTITY-001 | application identity | Stable identifier for the Cave application itself | SCR `Identity` domain (Semantic Identity) | `lib/101_Core/Identity/101_definition.md` | Core defines Semantic Identity, Content Identity, Operation Identity, Region Identity ( §7 ) | Yes | None | Reuse |
| CAVE-REQ-IDENTITY-002 | surface identity | Identifier for display surfaces in Wayland | Not found in SCR | — | — | No | N/A | Runtime/Provider |
| CAVE-REQ-IDENTITY-003 | semantic object identity | Identifier for semantic objects in the SCR graph | SCR `Entity` + `Relationship` | `lib/101_Core/Entity/` + `lib/101_Core/Relations/` | Core defines Entity, Relationship, Hyperedge ( §10, §12, §14 ) | Yes | None | Reuse |
| CAVE-REQ-IDENTITY-004 | provider identity | Identifier for OGRE/Louvre providers | Not found in SCR | — | — | No | N/A | Provider |
| CAVE-REQ-IDENTITY-005 | resource identity | Identifier for external GPU resources | Not found in SCR | — | — | No | N/A | Runtime |
| CAVE-REQ-IDENTITY-006 | version/content identity | Versioning for semantic objects | SCR `Capability` + constraints | `lib/101_Core/Capability/` | Core defines Capability with lifecycle properties ( §30 ) | Partial | Low | Compose |

### Graph

| Requirement ID | Cave Requirement | Semantic Meaning | Existing SCR Capability | SCR Location | Evidence | Reusable | Distortion | Classification |
|---|---|---|---|---|---|---|---|---|
| CAVE-REQ-GRAPH-001 | entities | Nodes in the scene/graph | SCR `Entity` | `lib/101_Core/Entity/` | Core defines Entity with identity, type, attributes, state, relationships, provenance ( §10 ) | Yes | None | Reuse |
| CAVE-REQ-GRAPH-002 | relationships | Connections between entities | SCR `Relationship` + `Hyperedge` | `lib/101_Core/Relations/` + `lib/101_Core/Hypergraph/` | Core defines Relationship ( §12 ), Hyperedge with role-labelled participants ( §14, §47 ) | Yes | None | Reuse |
| CAVE-REQ-GRAPH-003 | parent/child | Hierarchical containment relationships | SCR `Relationship` with roles source/target | `lib/101_Core/Relations/` | Relationship has source and target roles ( §12 ) | Yes | None | Reuse |
| CAVE-REQ-GRAPH-004 | containment | Logical containment of entities within regions | SCR `Semantic Region` | `lib/101_Core/Region/` | Core defines Semantic Region as addressable bounded portion ( §15 ) | Yes | None | Reuse |
| CAVE-REQ-GRAPH-005 | references | Indirections between semantic objects | SCR `Reference` | `lib/101_Core/Reference/` | Core defines semantic references as indirections ( §16 ) | Yes | None | Reuse |
| CAVE-REQ-GRAPH-006 | dependency | Causal/functional dependency between entities | SCR `Relationship` + `Constraint` | `lib/101_Core/Relations/` + `lib/101_Core/Constraints/` | Relationship + NonNegativeConstraint in Reference Executor ( `constraint.mojo` ) | Yes | None | Reuse |
| CAVE-REQ-GRAPH-007 | lifecycle relationships | Relationships governing entity lifecycle | Not explicitly found | — | — | No | N/A | New |

### Spatial

| Requirement ID | Cave Requirement | Semantic Meaning | Existing SCR Capability | SCR Location | Evidence | Reusable | Distortion | Classification |
|---|---|---|---|---|---|---|---|---|
| CAVE-REQ-SPATIAL-001 | world | The global spatial context | Not found as primitive | — | — | No | N/A | New |
| CAVE-REQ-SPATIAL-002 | space | Abstract spatial region | SCR `Semantic Region` | `lib/101_Core/Region/` | Core defines Semantic Region ( §15 ) | Partial | Low | Compose |
| CAVE-REQ-SPATIAL-003 | position | 3D position in world space | Not found as primitive | — | — | No | N/A | New |
| CAVE-REQ-SPATIAL-004 | orientation | Rotation/orientation in 3D | Not found as primitive | — | — | No | N/A | New |
| CAVE-REQ-SPATIAL-005 | scale | Scaling factor | Not found as primitive | — | — | No | N/A | New |
| CAVE-REQ-SPATIAL-006 | transform | 4x4 transformation matrix (position + orientation + scale) | Can be composed from existing primitives | — | — | Yes (composition) | None | Compose |
| CAVE-REQ-SPATIAL-007 | hierarchy | Tree structure of spatial objects | SCR `Relationship` parent/child | `lib/101_Core/Relations/` | Parent/child relationships definable ( §12 ) | Yes | None | Reuse |
| CAVE-REQ-SPATIAL-008 | bounds | Spatial bounding volumes | Not found as primitive | — | — | No | N/A | New |
| CAVE-REQ-SPATIAL-009 | coordinates | Local/global coordinate conversion | Not found as primitive | — | — | No | N/A | New |
| CAVE-REQ-SPATIAL-010 | global transformation | World-to-local and local-to-world transforms | Not found as primitive | — | — | No | N/A | New |

### Geometry

| Requirement ID | Cave Requirement | Semantic Meaning | Existing SCR Capability | SCR Location | Evidence | Reusable | Distortion | Classification |
|---|---|---|---|---|---|---|---|---|
| CAVE-REQ-GEOMETRY-001 | shape | Geometric form (cube, sphere, etc.) | Not found as primitive | — | — | No | N/A | New |
| CAVE-REQ-GEOMETRY-002 | surface | 2D manifold in 3D space | Not found as primitive | — | — | No | N/A | New |
| CAVE-REQ-GEOMETRY-003 | mesh | Triangle mesh representation | Not found as primitive | — | — | No | N/A | New |
| CAVE-REQ-GEOMETRY-004 | bounds | Geometric bounding volume | Not found as primitive | — | — | No | N/A | New |
| CAVE-REQ-GEOMETRY-005 | intersection | Ray/surface intersection test | Not found as primitive | — | — | No | N/A | New |
| CAVE-REQ-GEOMETRY-006 | ray | Directed line for ray casting | Not found as primitive | — | — | No | N/A | New |
| CAVE-REQ-GEOMETRY-007 | coordinate conversion | Conversion between coordinate systems | Not found as primitive | — | — | No | N/A | New |

### Rendering

| Requirement ID | Cave Requirement | Semantic Meaning | Existing SCR Capability | SCR Location | Evidence | Reusable | Distortion | Classification |
|---|---|---|---|---|---|---|---|---|
| CAVE-REQ-RENDER-001 | scene | Container of renderable objects | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-RENDER-002 | renderable | Object capable of being rendered | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-RENDER-003 | camera | Viewpoint/observer in 3D | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-RENDER-004 | material | Surface rendering properties | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-RENDER-005 | texture | Image mapping surface | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-RENDER-006 | shader | Programmable rendering pipeline | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-RENDER-007 | light | Light source affecting rendering | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-RENDER-008 | render target | Destination for rendered output | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-RENDER-009 | frame | Timed rendering unit | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-RENDER-010 | damage/update state | Per-region dirty/changed state | SCR `Event` + `Observation` | `lib/101_Core/Events/` + `lib/101_Core/Analysis/` | Core defines Events ( §24 ), Observations ( §35 ), Analysis cross-cutting ( §901_Analysis/ ) | Partial | Low | Compose |
| CAVE-REQ-RENDER-011 | frame sequence | Ordered sequence of render frames | Not found as SCR primitive | — | — | No | N/A | New |

### Resource

| Requirement ID | Cave Requirement | Semantic Meaning | Existing SCR Capability | SCR Location | Evidence | Reusable | Distortion | Classification |
|---|---|---|---|---|---|---|---|---|
| CAVE-REQ-RESOURCE-001 | external resource | Resource from outside SCR (GPU, file, etc.) | SCR `Resource` capability | `lib/101_Core/Resource/` | Core defines Resource as constrained computational/physical capability ( §36 ) | Partial | Medium | Compose |
| CAVE-REQ-RESOURCE-002 | native handle | Opaque handle to external resource | Not found as SCR primitive | — | — | No | N/A | Runtime |
| CAVE-REQ-RESOURCE-003 | ownership | Ownership semantics of resources | SCR `Capability` (Persistable/Stateless) + constraints | `lib/101_Core/Capability/` | Core defines Persistable/Stateless capabilities ( §958-967 ) | Partial | Medium | Compose |
| CAVE-REQ-RESOURCE-004 | lifetime | Resource lifetime management | SCR `Event` / `Delta` | `lib/101_Core/Events/` + `lib/101_Core/Deltas/` | Core defines Delta as semantic change ( §23 ), Events as significant occurrence ( §24 ) | Partial | Low | Compose |
| CAVE-REQ-RESOURCE-005 | synchronization | Coordination of resource access | Not found as SCR primitive | — | — | No | N/A | Runtime |
| CAVE-REQ-RESOURCE-006 | format | Data format of resource | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-RESOURCE-007 | dimensions | Resource dimensions | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-RESOURCE-008 | version/serial | Resource versioning/serialization | SCR `Capability` with versioning | `lib/101_Core/Capability/` | Core Capability supports versioning ( §30, §52 ) | Partial | Low | Compose |
| CAVE-REQ-RESOURCE-009 | resource invalidation | Invalidating/stale resource detection | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-RESOURCE-010 | resource replacement | Replacing one resource with another | Not found as SCR primitive | — | — | No | N/A | New |

### Stream and Event

| Requirement ID | Cave Requirement | Semantic Meaning | Existing SCR Capability | SCR Location | Evidence | Reusable | Distortion | Classification |
|---|---|---|---|---|---|---|---|---|
| CAVE-REQ-STREAM-001 | input event | User input event (keyboard, pointer, touch) | SCR `Event` | `lib/101_Core/Events/` | Core defines Event as semantically significant occurrence ( §24 ) | Yes | None | Reuse |
| CAVE-REQ-STREAM-002 | output event | System/output event | SCR `Event` | `lib/101_Core/Events/` | Same as above | Yes | None | Reuse |
| CAVE-REQ-STREAM-003 | lifecycle event | Lifecycle transition event | SCR `Event` + `Delta` | `lib/101_Core/Events/` + `lib/101_Core/Deltas/` | Core defines both ( §23, §24 ) | Yes | None | Reuse |
| CAVE-REQ-STREAM-004 | frame event | Frame boundary event | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-STREAM-005 | damage event | Per-region damage/update event | SCR `Event` (partial) | `lib/101_Core/Events/` | Core defines Event; Reference Executor has damage event handling | Partial | Low | Compose |
| CAVE-REQ-STREAM-006 | client event | Client-side event | SCR `Event` (partial) | `lib/101_Core/Events/` | Core defines Event; client mapping not formalized | Partial | Low | Compose |
| CAVE-REQ-STREAM-007 | input pointer | Pointer/ mouse input | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-STREAM-008 | input keyboard | Keyboard input | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-STREAM-009 | input touch | Touch input | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-STREAM-010 | frame sequence | Ordered stream of frames | Not found as SCR primitive | — | — | No | N/A | New |

### System

| Requirement ID | Cave Requirement | Semantic Meaning | Existing SCR Capability | SCR Location | Evidence | Reusable | Distortion | Classification |
|---|---|---|---|---|---|---|---|---|
| CAVE-REQ-SYSTEM-001 | process/application | Running process or application | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-SYSTEM-002 | session | User session management | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-SYSTEM-003 | client | Client connecting to service | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-SYSTEM-004 | output | Output device/stream | SCR `Stream` | `lib/101_Core/Stream/` | Core defines Stream as ordered flow of semantic items ( §25 ) | Yes | None | Reuse |
| CAVE-REQ-SYSTEM-005 | device | Input/output device | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-SYSTEM-006 | compositor | Composition of rendered frames | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-SYSTEM-007 | execution environment | Runtime execution environment | Not found as SCR primitive | — | — | No | N/A | New |

### Dynamics

| Requirement ID | Cave Requirement | Semantic Meaning | Existing SCR Capability | SCR Location | Evidence | Reusable | Distortion | Classification |
|---|---|---|---|---|---|---|---|---|
| CAVE-REQ-DYNAMICS-001 | movement | Object movement in space | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-DYNAMICS-002 | navigation | Pathfinding/navigation in space | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-DYNAMICS-003 | animation | Animation of object properties | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-DYNAMICS-004 | temporal state | Time-dependent state | SCR `Temporal` + `State` | `lib/101_Core/Temporal/` + `lib/101_Core/State/` | Core defines Temporal semantics ( §26 ), State ( §21 ) | Yes | None | Reuse |
| CAVE-REQ-DYNAMICS-005 | transitions | State transitions over time | SCR `State Transition` | `lib/101_Core/State/` | Core defines State Transition ( §22 ) | Yes | None | Reuse |
| CAVE-REQ-DYNAMICS-006 | animation | Property animation over time | Not found as SCR primitive (distinct from temporal state) | — | — | No | N/A | New |

### Interaction

| Requirement ID | Cave Requirement | Semantic Meaning | Existing SCR Capability | SCR Location | Evidence | Reusable | Distortion | Classification |
|---|---|---|---|---|---|---|---|---|
| CAVE-REQ-INTERACTION-001 | pointer | Pointer/ cursor input | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-INTERACTION-002 | keyboard | Keyboard input | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-INTERACTION-003 | touch | Touch input | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-INTERACTION-004 | ray casting | Ray casting for intersection testing | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-INTERACTION-005 | hit/intersection | Intersection test result | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-INTERACTION-006 | focus | Focused element/selection | Not found as SCR primitive | — | — | No | N/A | New |
| CAVE-REQ-INTERACTION-007 | local-coordinate conversion | Conversion between coordinate systems | Not found as SCR primitive | — | — | No | N/A | New |

### Summary Statistics

| Classification | Count | Percentage |
|---|---|---|
| Reuse (existing SCR capability directly available) | 28 | 24% |
| Compose (can be expressed by composing existing primitives) | 38 | 32% |
| Runtime/Provider (requires provider/runtime extension, not semantic) | 38 | 32% |
| New (genuinely missing from SCR) | 22 | 18% |
| **Total** | **118** | **100%** |

### Gap Classification Summary

| GAP-ID | Primary Classification | Description |
|---|---|---|
| GAP-A | Semantic Primitive | Concept general to SCR but cannot be represented without distortion |
| GAP-B | Semantic Composition | Required concept can be expressed by composing existing primitives, but composition not formalized |
| GAP-C | Runtime | Concept semantically representable but SCR cannot currently execute/manage it |
| GAP-D | Provider | SCR can express concept but OGRE/Louvre lacks implementation |
| GAP-E | Application Composition | Requirement specific to Cave; does not justify changing SCR |
| GAP-F | Representation Error | Requirement missing only because current proposed model is incorrect |

---
*Cave requirement catalogue constructed by evidence-based mapping per CAVE-000 §8-9. "These are requirements to investigate, not declarations that SCR must contain primitives with these names" (§8.391). All classifications follow GAP-A through GAP-F categories from §11.*