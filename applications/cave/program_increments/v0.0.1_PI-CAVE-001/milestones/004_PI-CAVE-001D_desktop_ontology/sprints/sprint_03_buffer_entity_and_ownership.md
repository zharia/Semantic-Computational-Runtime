# Sprint 03: Buffer Semantic Entity & State Ownership

**Parent Milestone:** [Milestone 004: PI-CAVE-001D Desktop Ontology](../spec.md)  
**Derived from:** `spec.md` (Sections 10.5, 62)  
**Governing Documents:** [`docs/102_ARCHITECTURE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/102_ARCHITECTURE.md), [`docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md)  
**Status:** Planned  

---

## 1. Mission

Implement `BufferEntity` in Mojo, abstracting pixel memory layout from physical GPU descriptors, and define unambiguous state ownership boundaries between client applications, compositors, and the SCR runtime.

---

## 2. Technical Specifications & Data Models

### 2.1 Buffer Entity
```mojo
@value
enum PixelFormat:
    case ARGB8888
    case XRGB8888
    case RGBA8888
    case NV12

struct BufferEntity:
    var id: SemanticId
    var surface_id: SemanticId
    var format: PixelFormat
    var width: Int
    var height: Int
    var stride: Int
    var content_id: ContentId   # SHA-256 hash of pixel contents
    var is_released: Bool
```

### 2.2 State Ownership Contract (§62)
* **Client Ownership:** The client application owns the buffer during CPU/GPU rendering prior to dispatching `wl_surface.attach`.
* **Compositor Ownership:** Upon attachment and commit, the buffer passes into compositor ownership for display composition.
* **SCR Runtime Authority:** SCR owns the semantic representation: buffer dimensions, format, and attachment history.
* **Buffer Release Semantics:** Once the compositor finishes sampling the buffer (or a newer buffer is committed), a release event is dispatched to the client, transferring buffer reuse rights back to the application.

---

## 3. Verification & Invariants

1. **Dimensional Consistency:** Buffer dimensions $(W, H)$ must match the target surface dimensions or trigger an explicit surface resize event.
2. **Buffer Release Invariant:** A buffer marked `is_released == True` cannot be sampled for future frame compositions without a re-attach event.
3. **Manifestation Separation:** Changing the underlying GPU texture or DMA-BUF file descriptor preserves the `BufferEntity` semantic identity.
