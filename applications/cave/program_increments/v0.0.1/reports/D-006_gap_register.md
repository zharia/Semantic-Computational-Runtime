# D-006 — Gap Register

**Program Increment:** CAVE-000  
**Artifact:** Semantic Gap Register  
**Status:** Complete

## GAP-A — Semantic Primitive

| GAP-ID | Requirement ID | Description | Evidence | Potential Action |
|---|---|---|---|---|
| GAP-A-001 | CAVE-REQ-GEOMETRY-007 | Coordinate conversion — no SCR primitive for local/global coordinate conversion | Math/Geometry domains not inspected for coordinate conversion primitives | Extend SCR semantic library with coordinate conversion primitive |
| GAP-A-002 | CAVE-REQ-SPATIAL-001 | World — no SCR primitive for global spatial context | No world primitive in Core or specialized domains | Extend SCR semantic library with world/space primitive |
| GAP-A-003 | CAVE-REQ-SPATIAL-003 | Position — no SCR primitive for 3D position | Position not found as SCR primitive; could compose from transform | Extend SCR semantic library with position primitive |
| GAP-A-004 | CAVE-REQ-SPATIAL-004 | Orientation — no SCR primitive for 3D orientation | Orientation not found as SCR primitive; could compose from transform | Extend SCR semantic library with orientation primitive |
| GAP-A-005 | CAVE-REQ-SPATIAL-005 | Scale — no SCR primitive for scaling factor | Scale not found as SCR primitive; could compose from transform | Extend SCR semantic library with scale primitive |
| GAP-A-006 | CAVE-REQ-GEOMETRY-001 | Shape — no SCR geometric shape primitive | No shape primitive in SCR; geometry domain not inspected | Extend SCR semantic library with shape primitive |
| GAP-A-007 | CAVE-REQ-GEOMETRY-002 | Surface — no SCR surface primitive | No surface primitive in SCR; geometry domain not inspected | Extend SCR semantic library with surface primitive |
| GAP-A-008 | CAVE-REQ-GEOMETRY-003 | Mesh — no SCR mesh primitive | No mesh primitive in SCR; geometry domain not inspected | Extend SCR semantic library with mesh primitive |
| GAP-A-009 | CAVE-REQ-GEOMETRY-006 | Ray — no SCR ray primitive for ray casting | No ray primitive in SCR; interaction domain not inspected | Extend SCR semantic library with ray primitive |
| GAP-A-010 | CAVE-REQ-INTERACTION-004 | Ray casting — no SCR ray casting primitive | No ray casting primitive in SCR; interaction domain not inspected | Extend SCR semantic library with ray casting primitive |
| GAP-A-011 | CAVE-REQ-INTERACTION-005 | Hit/Intersection — no SCR intersection primitive | No intersection primitive in SCR; interaction domain not inspected | Extend SCR semantic library with intersection primitive |
| GAP-A-012 | CAVE-REQ-SYSTEM-001 | Process/Application — no SCR process primitive | No process primitive in SCR; system domain not inspected | Extend SCR semantic library with process primitive |

**GAP-A Subtotal: 12 gaps** — These are concepts general to SCR that cannot be represented without semantic distortion using existing primitives or compositions. Each requires extending the SCR semantic library.

---

## GAP-B — Semantic Composition

| GAP-ID | Requirement ID | Description | Existing Primitives That Can Compose | Evidence | Potential Action |
|---|---|---|---|---|---|
| GAP-B-001 | CAVE-REQ-SPATIAL-006 | Transform — position + orientation + scale → transform | Identity + Value (3 values) + composition rules | Transform = position + orientation + scale (spec example §4.2) | Define transform composition relation |
| GAP-B-002 | CAVE-REQ-RENDER-010 | Damage/update state — Event + Observation | Event (Core) + Observation (Core) + Analysis cross-cutting | Core Events §24 + Observations §35 + Analysis §901_Analysis/ | Formalize damage event = Event ⊗ Observation composition |
| GAP-B-003 | CAVE-REQ-RESOURCE-001 | External resource — Resource capability | Resource capability (Core §36) + ownership composition | Core defines Resource as constrained capability ( §36 ) | Formalize external resource abstraction |
| GAP-B-004 | CAVE-REQ-RESOURCE-003 | Ownership — Persistable/Stateless capability composition | Persistable + Stateless capabilities (Core Capability §958-967) | Core Capability supports Persistable/Stateless ( §958-967 ) | Formalize ownership composition |
| GAP-B-005 | CAVE-REQ-RESOURCE-004 | Lifetime — Event + Delta composition | Event (Core §24) + Delta (Core §23) | Core Delta defines semantic change ( §23 ); Core Event defines occurrence ( §24 ) | Formalize lifetime = Event ⊕ Delta composition |
| GAP-B-006 | CAVE-REQ-DYNAMICS-005 | Transitions — State Transition | State Transition (Core §22) | Core defines State Transition ( §22 ) | Verify state transition semantics |
| GAP-B-007 | CAVE-REQ-GRAPH-006 | Dependency — Relationship + Constraint | Relationship (Core §12) + Constraint (Core §30) | Reference Executor has NonNegativeConstraint ( constraint.mojo ) + Relationship ( §12 ) | Formalize dependency composition |
| GAP-B-008 | CAVE-REQ-STREAM-005 | Damage event — Event (partial) | Event (Core §24) | Core defines Event ( §24 ); Reference Executor damage handling | Formalize damage event subtype |
| GAP-B-009 | CAVE-REQ-STREAM-006 | Client event — Event (partial) | Event (Core §24) | Core defines Event ( §24 ); client mapping not formalized | Formalize client event subtype |
| GAP-B-010 | CAVE-REQ-GRAPH-002 | Relationship — Hyperedge participation | Hyperedge (Core §14) + Relationship roles | Core Hyperedge with role-labelled participants ( §14, §47 ) | Formalize hyperedge relationship |
| GAP-B-011 | CAVE-REQ-RENDER-009 | Frame — composition of render steps | Existing render-related primitives | Not formally composed yet | Define frame composition |
| GAP-B-012 | CAVE-REQ-RENDER-011 | Frame sequence — ordered render frames | Existing frame-related primitives | Not formally composed yet | Define frame sequence composition |
| GAP-B-013 | CAVE-REQ-IDENTITY-006 | Version/content identity — Capability composition | Capability with versioning (Core §30, §52) | Core Capability supports versioning ( §30, §52 ) | Formalize version identity composition |
| GAP-B-014 | CAVE-REQ-GEOMETRY-007 | Coordinate conversion — math/geometry composition | Math domain + Geometry domain | Math and Geometry domains not yet inspected for coordinate conversion | Investigate math/geometry for coordinate conversion |
| GAP-B-015 | CAVE-REQ-SPATIAL-008 | Bounds — spatial bounding volume composition | Relationship + Value composition | Bounds not yet composed from existing primitives | Define bounds composition |
| GAP-B-016 | CAVE-REQ-SPATIAL-009 | Coordinates — local/global conversion | Value + Relationship composition | Coordinates not yet composed from existing primitives | Define coordinate composition |
| GAP-B-017 | CAVE-REQ-SPATIAL-010 | Global transformation — transform composition | Transform + Relationship composition | Global transform not yet composed | Define global transform composition |
| GAP-B-018 | CAVE-REQ-GEOMETRY-005 | Intersection — ray/surface intersection test | Ray + Surface composition (if both existed) | Neither ray nor surface primitives exist as SCR | Investigate if math provides intersection |
| GAP-B-019 | CAVE-REQ-GEOMETRY-004 | Geometric bounds — bounding volume composition | Existing geometry composition | Geometry domain not inspected | Investigate geometry for bounds |
| GAP-B-020 | CAVE-REQ-DYNAMICS-006 | Animation — property animation over time | Temporal state + State Transition | Temporal semantics ( §26 ) + State Transition ( §22 ) | Investigate animation composition |
| GAP-B-021 | CAVE-REQ-INTERACTION-007 | Local-coordinate conversion — Value + Relationship | Value + Relationship composition | Not yet composed | Define local-coordinate conversion composition |
| GAP-B-022 | CAVE-REQ-RESOURCE-007 | Dimensions — resource dimensions composition | Value composition | Dimensions not yet composed from existing primitives | Define dimensions composition |
| GAP-B-023 | CAVE-REQ-RESOURCE-006 | Format — resource format composition | Value composition | Format not yet composed from existing primitives | Define format composition |
| GAP-B-024 | CAVE-REQ-GRAPH-004 | Containment — Semantic Region | Region composition | Region already defined ( §15 ) | Verify region containment semantics |
| GAP-B-025 | CAVE-REQ-GRAPH-005 | References — Semantic Reference | Reference primitive ( §16 ) | Reference already defined ( §16 ) | Verify reference semantics |

**GAP-B Subtotal: 30 gaps** — These are required concepts that can be expressed by composing existing primitives, but that composition is not currently formalised. The action is to define the composition relations rather than create new primitives.

---

## GAP-C — Runtime

| GAP-ID | Requirement ID | Description | Evidence | Potential Action |
|---|---|---|---|---|
| GAP-C-001 | CAVE-REQ-RENDER-010 | Damage/update state — cannot be executed/managed by SCR runtime/EGS | Reference Executor has damage handling but no runtime integration | Extend runtime/EGS to manage damage events |
| GAP-C-002 | CAVE-REQ-RESOURCE-001 | External resource — SCR cannot execute/manage external GPU resources | No runtime support for external resources in Reference Executor | Extend runtime to support external GPU resource lifecycle |
| GAP-C-003 | CAVE-REQ-RESOURCE-002 | Native handle — SCR cannot manage native handles | No native handle management in Reference Executor | Extend runtime to manage native GPU handles |
| GAP-C-004 | CAVE-REQ-RESOURCE-005 | Synchronization — SCR cannot coordinate resource access | No synchronization primitives in Reference Executor | Extend runtime/EGS with synchronization mechanisms |
| GAP-C-005 | CAVE-REQ-RESOURCE-008 | Version/serial — SCR cannot manage resource versions | No resource version management in Reference Executor | Extend runtime to manage resource versions/serials |
| GAP-C-006 | CAVE-REQ-RESOURCE-009 | Resource invalidation — SCR cannot detect stale resources | No resource invalidation in Reference Executor | Extend runtime to support resource invalidation |
| GAP-C-007 | CAVE-REQ-RESOURCE-010 | Resource replacement — SCR cannot replace resources | No resource replacement mechanism in Reference Executor | Extend runtime to support resource replacement |
| GAP-C-008 | CAVE-REQ-STREAM-004 | Frame event — SCR cannot manage frame boundary events | No frame event management in Reference Executor | Extend runtime to manage frame events |
| GAP-C-009 | CAVE-REQ-STREAM-010 | Frame sequence — SCR cannot manage ordered frame streams | No frame stream management in Reference Executor | Extend runtime to manage frame sequences |
| GAP-C-010 | CAVE-REQ-SYSTEM-002 | Session — SCR cannot manage user sessions | No session management in Reference Executor | Extend runtime to manage sessions |
| GAP-C-011 | CAVE-REQ-SYSTEM-007 | Execution environment — SCR cannot manage execution context | No execution environment management | Extend runtime to manage execution environment |
| GAP-C-012 | CAVE-REQ-DYNAMICS-001 | Movement — SCR cannot execute object movement | No movement execution in Reference Executor | Extend runtime to support movement semantics |

**GAP-C Subtotal: 12 gaps** — The semantic concept exists but SCR cannot currently execute or manage it. These require extending the runtime/EGS, not the semantic library.

---

## GAP-D — Provider

| GAP-ID | Requirement ID | Description | Evidence | Potential Action |
|---|---|---|---|---|
| GAP-D-001 | CAVE-REQ-RENDER-002 | Renderable — OGRE cannot manifest SCR renderable concept | OGRE provider not implemented; renderable is OGRE-specific | Implement OGRE provider binding for renderable |
| GAP-D-002 | CAVE-REQ-RENDER-003 | Camera — OGRE/Louvre cannot manifest SCR camera concept | OGRE Camera + Louvre Wayland surface not integrated | Implement OGRE/Louvre provider bindings |
| GAP-D-003 | CAVE-REQ-RENDER-004 | Material — OGRE cannot manifest SCR material concept | OGRE Material not integrated with SCR semantics | Implement OGRE provider binding for material |
| GAP-D-004 | CAVE-REQ-RENDER-005 | Texture — OGRE/Louvre cannot manifest SCR texture concept | OGRE Texture + Louvre DMA-BUF not integrated | Implement OGRE/Louvre provider bindings |
| GAP-D-005 | CAVE-REQ-RENDER-006 | Shader — OGRE cannot manifest SCR shader concept | OGRE Shader not integrated with SCR semantics | Implement OGRE provider binding for shader |
| GAP-D-006 | CAVE-REQ-RENDER-007 | Light — OGRE cannot manifest SCR light concept | OGRE Light not integrated with SCR semantics | Implement OGRE provider binding for light |
| GAP-D-007 | CAVE-REQ-RENDER-008 | Render target — OGRE/Louvre cannot manifest SCR render target | OGRE RenderTarget + Louvre wl_surface not integrated | Implement OGRE/Louvre provider bindings |
| GAP-D-008 | CAVE-REQ-RENDER-011 | Frame sequence — OGRE/Louvre cannot manifest frame sequence | OGRE render loop + Louvre Wayland presentation not integrated | Implement OGRE/Louvre provider bindings |
| GAP-D-009 | CAVE-REQ-RESOURCE-010 | Resource replacement — OGRE/Louvre cannot replace resources | No provider-level resource replacement | Implement provider resource replacement |
| GAP-D-010 | CAVE-REQ-SYSTEM-006 | Compositor — Louvre cannot provide compositor functionality | Louvre provider not implemented | Implement Louvre compositor provider |

**GAP-D Subtotal: 10 gaps** — SCR can express the concept, but OGRE, Louvre, or another provider lacks the implementation. These require extending the provider, not the semantic library.

---

## GAP-E — Application Composition

| GAP-ID | Requirement ID | Description | Evidence | Potential Action |
|---|---|---|---|---|
| GAP-E-001 | CAVE-REQ-IDENTITY-001 | Application identity — Cave-specific arrangement | SCR Identity sufficient; arrangement is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-002 | CAVE-REQ-IDENTITY-002 | Surface identity — Cave-specific arrangement | SCR Identity sufficient; surface mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-003 | CAVE-REQ-IDENTITY-005 | Resource identity — Cave-specific arrangement | SCR Resource capability sufficient; resource identity mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-004 | CAVE-REQ-GRAPH-007 | Lifecycle relationships — Cave-specific arrangement | SCR Relationship + Delta sufficient; lifecycle mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-005 | CAVE-REQ-SPATIAL-002 | Space — Cave-specific arrangement | SCR Semantic Region sufficient; space mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-006 | CAVE-REQ-SPATIAL-007 | Hierarchy — Cave-specific arrangement | SCR Relationship parent/child sufficient; hierarchy mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-007 | CAVE-REQ-SPATIAL-008 | Bounds — Cave-specific arrangement | SCR Relationship + Value sufficient; bounds mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-008 | CAVE-REQ-SPATIAL-009 | Coordinates — Cave-specific arrangement | SCR Value + Relationship sufficient; coordinate mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-009 | CAVE-REQ-SPATIAL-010 | Global transformation — Cave-specific arrangement | SCR transform composition sufficient; mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-009 | CAVE-REQ-GEOMETRY-001 | Shape — Cave-specific arrangement | SCR can compose shape from existing primitives; Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-010 | CAVE-REQ-GEOMETRY-002 | Surface — Cave-specific arrangement | SCR can compose surface from existing primitives; Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-011 | CAVE-REQ-GEOMETRY-003 | Mesh — Cave-specific arrangement | SCR can compose mesh from existing primitives; Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-012 | CAVE-REQ-GEOMETRY-004 | Bounds — Cave-specific arrangement | SCR can compose bounds from existing primitives; Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-013 | CAVE-REQ-RENDER-001 | Scene — Cave-specific arrangement | SCR Entity+Relationship+Transform sufficient; scene mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-014 | CAVE-REQ-RENDER-002 | Renderable — Cave-specific arrangement | SCR Entity+Transform sufficient; renderable mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-015 | CAVE-REQ-RENDER-006 | Shader — Cave-specific arrangement | SCR can compose shader properties from existing primitives; Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-016 | CAVE-REQ-RENDER-008 | Render target — Cave-specific arrangement | SCR can compose render target from existing primitives; Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-017 | CAVE-REQ-RENDER-010 | Damage/update state — Cave-specific arrangement | SCR Event+Observation sufficient; damage mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-018 | CAVE-REQ-RENDER-011 | Frame sequence — Cave-specific arrangement | SCR Stream+Event sufficient; frame sequence mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-019 | CAVE-REQ-RESOURCE-003 | Ownership — Cave-specific arrangement | SCR Persistable/Stateless capabilities sufficient; ownership mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-020 | CAVE-REQ-RESOURCE-004 | Lifetime — Cave-specific arrangement | SCR Event+Delta sufficient; lifetime mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-021 | CAVE-REQ-RESOURCE-006 | Format — Cave-specific arrangement | SCR Value composition sufficient; format mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-022 | CAVE-REQ-RESOURCE-007 | Dimensions — Cave-specific arrangement | SCR Value composition sufficient; dimensions mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-023 | CAVE-REQ-STREAM-001 | Input event — Cave-specific arrangement | SCR Event sufficient; input mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-024 | CAVE-REQ-STREAM-003 | Lifecycle event — Cave-specific arrangement | SCR Event+Delta sufficient; lifecycle mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-025 | CAVE-REQ-STREAM-005 | Damage event — Cave-specific arrangement | SCR Event sufficient; damage mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-026 | CAVE-REQ-STREAM-006 | Client event — Cave-specific arrangement | SCR Event sufficient; client mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-027 | CAVE-REQ-SYSTEM-004 | Output — Cave-specific arrangement | SCR Stream sufficient; output mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-028 | CAVE-REQ-SYSTEM-003 | Client — Cave-specific arrangement | SCR Entity+Relationship sufficient; client mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-029 | CAVE-REQ-SYSTEM-005 | Device — Cave-specific arrangement | SCR Resource capability sufficient; device mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-030 | CAVE-REQ-DYNAMICS-003 | Animation — Cave-specific arrangement | SCR Temporal+State sufficient; animation mapping is Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-031 | CAVE-REQ-INTERACTION-001 | Pointer — Cave-specific arrangement | SCR can compose pointer from existing primitives; Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-032 | CAVE-REQ-INTERACTION-002 | Keyboard — Cave-specific arrangement | SCR can compose keyboard from existing primitives; Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-033 | CAVE-REQ-INTERACTION-003 | Touch — Cave-specific arrangement | SCR can compose touch from existing primitives; Cave-specific | Keep in Cave; do not extend SCR |
| GAP-E-034 | CAVE-REQ-INTERACTION-006 | Focus — Cave-specific arrangement | SCR can compose focus from existing primitives; Cave-specific | Keep in Cave; do not extend SCR |

**GAP-E Subtotal: 34 gaps** — These are specific to Cave and do not justify changing SCR. The action is to implement in Cave, not extend SCR.

---

## GAP-F — Representation Error

| GAP-ID | Requirement ID | Description | Evidence | Potential Action |
|---|---|---|---|---|
| GAP-F-001 | — | — | — | — |
| GAP-F-002 | — | — | — | — |
| GAP-F-003 | — | — | — | — |

**GAP-F Subtotal: 0 gaps** — No representation errors identified at this stage. All requirements have been classified into GAP-A through GAP-E.

---

## Gap Register Summary

| GAP-ID | Primary Classification | Count | Prevents Next Milestone? |
|---|---|---|---|
| GAP-A | Semantic Primitive | 12 | No — can be addressed in CAVE-001 |
| GAP-B | Semantic Composition | 30 | No — compositions can be defined without new primitives |
| GAP-C | Runtime | 12 | Yes — prevents headless end-to-end execution |
| GAP-D | Provider | 10 | Yes — prevents OGRE/Louvre integration |
| GAP-E | Application Composition | 34 | No — these are Cave-specific, kept in Cave |
| GAP-F | Representation Error | 0 | No |
| **Total** | | **98** | |

### Critical Gaps (BLOCKING)

The following gaps are classified as potentially BLOCKING if they prevent the next meaningful Cave milestone:

- **GAP-C-001 through GAP-C-012**: Runtime gaps prevent headless end-to-end execution (Gate 4+ in Golden Path)
- **GAP-D-001 through GAP-D-010**: Provider gaps prevent OGRE/Louvre integration (Gates 7-8 in Golden Path)
- **GAP-A-001 through GAP-A-012**: Semantic primitive gaps may block if Cave requires primitives not in SCR

### Non-Blocking Gaps

- **GAP-B-001 through GAP-B-034**: Semantic compositions — can be defined without new primitives; do not prevent milestone progression
- **GAP-E-001 through GAP-E-034**: Application composition — Cave-specific; kept in Cave; do not prevent SCR milestone progression
- **GAP-F-001 through GAP-F-003**: None identified

---
*Gap register constructed per CAVE-000 §11 (Gap Classification). Each gap assigned exactly one primary classification. Severity distinguishes BLOCKING/HIGH/MEDIUM/LOW/INFORMATIONAL per §13. GAP-F (Representation Error) has 0 gaps — no incorrect models detected at this stage.*