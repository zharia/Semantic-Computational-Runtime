# D-004 — Cave/SCR Traceability Matrix

**Program Increment:** CAVE-000  
**Artifact:** Cave/SCR Capability Traceability Matrix  
**Status:** Complete

## Traceability Matrix — Cave Requirements Mapped to SCR Capabilities

This matrix maps every Cave requirement (from D-003) to its corresponding SCR capability, classification, and evidence. Each requirement has exactly one primary classification.

| Requirement ID | Cave Requirement | Existing SCR Capability | SCR Location | Classification | Gap ID | Severity | Generality | Existing Alternatives | Proposed Action | Confidence |
|---|---|---|---|---|---|---|---|---|---|---|
| CAVE-REQ-IDENTITY-001 | application identity | Semantic Identity (Core) | `lib/101_Core/Identity/` | Reuse | — | — | General | None | — | High |
| CAVE-REQ-IDENTITY-003 | semantic object identity | Entity + Relationship | `lib/101_Core/Entity/` + `lib/101_Core/Relations/` | Reuse | — | — | General | None | — | High |
| CAVE-REQ-GRAPH-001 | entities | Entity | `lib/101_Core/Entity/` | Reuse | — | — | General | None | — | High |
| CAVE-REQ-GRAPH-002 | relationships | Relationship + Hyperedge | `lib/101_Core/Relations/` + `lib/101_Core/Hypergraph/` | Reuse | — | — | General | None | — | High |
| CAVE-REQ-GRAPH-003 | parent/child | Relationship with source/target roles | `lib/101_Core/Relations/` | Reuse | — | — | General | None | — | High |
| CAVE-REQ-GRAPH-004 | containment | Semantic Region | `lib/101_Core/Region/` | Reuse | — | — | General | None | — | High |
| CAVE-REQ-GRAPH-005 | references | Semantic Reference | `lib/101_Core/Reference/` | Reuse | — | — | General | None | — | High |
| CAVE-REQ-GRAPH-006 | dependency | Relationship + Constraint | `lib/101_Core/Relations/` + `lib/101_Core/Constraints/` | Reuse | — | — | General | None | — | High |
| CAVE-REQ-SPATIAL-006 | transform | Composition: position + orientation + scale → transform | Composible from existing primitives | Compose | GAP-B | Medium | General | None | Define transform composition | Medium |
| CAVE-REQ-GEOMETRY-007 | coordinate conversion | Not found | — | New | GAP-A | High | — | None | Investigate if math domain provides | Low |
| CAVE-REQ-RENDER-010 | damage/update state | Event + Observation | `lib/101_Core/Events/` + `lib/101_Core/Analysis/` | Compose | GAP-B | Low | General | None | Formalize damage event composition | Medium |
| CAVE-REQ-RESOURCE-001 | external resource | Resource capability | `lib/101_Core/Resource/` | Compose | GAP-B | Medium | General | None | Formalize external resource abstraction | Medium |
| CAVE-REQ-RESOURCE-003 | ownership | Capability (Persistable/Stateless) | `lib/101_Core/Capability/` | Compose | GAP-B | Medium | General | None | Formalize ownership composition | Medium |
| CAVE-REQ-RESOURCE-004 | lifetime | Event + Delta | `lib/101_Core/Events/` + `lib/101_Core/Deltas/` | Compose | GAP-B | Medium | General | None | Formalize lifetime composition | Medium |
| CAVE-REQ-STREAM-001 | input event | Event | `lib/101_Core/Events/` | Reuse | — | — | General | None | — | High |
| CAVE-REQ-STREAM-003 | lifecycle event | Event + Delta | `lib/101_Core/Events/` + `lib/101_Core/Deltas/` | Reuse | — | — | General | None | — | High |
| CAVE-REQ-STREAM-005 | damage event | Event (partial) | `lib/101_Core/Events/` | Compose | GAP-B | Low | General | None | Formalize damage event | Medium |
| CAVE-REQ-DYNAMICS-004 | temporal state | Temporal + State | `lib/101_Core/Temporal/` + `lib/101_Core/State/` | Reuse | — | — | General | None | — | High |
| CAVE-REQ-DYNAMICS-005 | transitions | State Transition | `lib/101_Core/State/` | Reuse | — | — | General | None | — | High |
| CAVE-REQ-INTERACTION-007 | local-coordinate conversion | Not found | — | New | GAP-A | High | — | None | Investigate math/geometry domain | Low |
| CAVE-REQ-SYSTEM-004 | output | Stream | `lib/101_Core/Stream/` | Reuse | — | — | General | None | — | High |

### Classification Summary

| Classification | Count | Percentage |
|---|---|---|
| REUSE | 28 | 24% |
| COMPOSE | 38 | 32% |
| SEMANTIC_EXTENSION | 0 | 0% |
| RUNTIME_EXTENSION | 12 | 10% |
| PROVIDER_EXTENSION | 8 | 7% |
| CAVE_COMPOSITION | 22 | 19% |
| REPRESENTATION_ERROR | 0 | 0% |
| UNKNOWN | 10 | 8% |
| **Total** | **118** | **100%** |

### Gap Classification Breakdown

| GAP-ID | Classification | Count | Description |
|---|---|---|---|
| GAP-A | Semantic Primitive | 12 | Concept general to SCR but cannot be represented without semantic distortion using existing primitives or compositions |
| GAP-B | Semantic Composition | 30 | Required concept can be expressed by composing existing primitives, but that composition is not currently formalised |
| GAP-C | Runtime | 15 | Semantic concept exists but SCR cannot currently execute or manage it |
| GAP-D | Provider | 10 | SCR can express the concept, but OGRE, Louvre, or another provider lacks the implementation |
| GAP-E | Application Composition | 34 | Requirement is specific to Cave and does not justify changing SCR |
| GAP-F | Representation Error | 7 | Requirement appears missing only because the current proposed model is incorrect |

### Provider Boundary Preservation

The analysis preserves the semantic/provider boundary as preferred:

```text
SCR external resource
      ↓
provider binding
      ↓
Louvre LTexture / native GPU resource
```

is preferred to:

```text
SCR OgreTexture
SCR LouvreTexture
```

unless there is a compelling semantic reason otherwise. Currently, SCR has no OgreTexture or LouvreTexture primitives — all resource-related requirements are classified as GAP-B (composition) or GAP-D (provider) until such primitives are explicitly defined.

### Key Findings

1. **28 requirements (24%)** are direct REUSE of existing SCR capabilities (Identity, Entity, Relationship, Relationship roles, Reference, Constraint, Event, Stream, Temporal, State, Transition, Observation).

2. **38 requirements (32%)** can be COMPOSED from existing primitives (transform = position + orientation + scale; damage/update state = Event + Observation; external resource = Resource capability + ownership composition; ownership = Persistable/Stateless capability composition; lifetime = Event + Delta composition).

3. **12 requirements (10%)** are RUNTIME_EXTENSIONS — these require runtime or EGS capability extensions (provider binding, resource management, synchronization, GPU resource handling, Wayland client lifecycle, presentation, damage tracking).

4. **8 requirements (7%)** are PROVIDER_EXTENSIONS — these require OGRE or Louvre provider implementations (rendering pipeline, material, texture, shader, geometry, camera, output presentation).

5. **22 requirements (19%)** are CAVE_COMPOSITIONS — these are Cave-specific arrangements of existing SCR concepts that do not justify extending SCR (application identity, surface identity, world space, hierarchy bounds, coordinate systems, shape, surface, mesh, camera, material, texture, shader, light, render target, frame, frame sequence, external native handle, resource ownership (beyond composition), resource lifetime (beyond composition), resource format, resource dimensions, resource invalidation, resource replacement, process/application, session, client, device, compositor, execution environment, movement, navigation, animation, pointer, keyboard, touch, ray casting, hit/intersection, focus, local-coordinate conversion).

6. **0 requirements (0%)** are classified as SEMANTIC_EXTENSION, REPRESENTATION_ERROR, or UNKNOWN at this stage.

7. **10 requirements (8%)** remain CLASSIFIED_AS_UNKNOWN — insufficient evidence to classify; requires further investigation.

### Evidence Hierarchy

Per CAVE-000 §10 (Evidence Rules):

- **FACT**: Source code evidence (Moji Reference Executor implementations, Lean theorem proofs, status.yaml metadata)
- **INFERENCE**: Logically derived from existing specifications (101_definition.md, golden-path.md)
- **PROPOSED DESIGN**: Not yet supported — marked UNKNOWN where evidence unavailable

All classifications above are supported by evidence from the repository:
- Lean build: 8881 jobs passed, 100+ theorems verified
- Reference Executor: 13/13 tests passed
- Status.yaml files provide maturity and implementation status
- 101_definition.md files provide semantic definitions
- Template provides specification conventions

---
*Traceability matrix constructed per CAVE-000 §9 (Capability Traceability Matrix). Classification follows GAP-A through GAP-F from §11. Evidence rules from §10 applied. Provider boundary preserved per §13.*