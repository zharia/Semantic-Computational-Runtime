# D-005 — Provider Capability Matrices

**Program Increment:** CAVE-000  
**Artifact:** Provider Capability Matrix  
**Status:** Complete

## Provider: OGRE

### Overview
OGRE (Open Graphics Rendering Engine) is a rendering provider. Per CAVE-000 §197: "OGRE is a rendering provider, not Cave's semantic model." OGRE manifests SCR state into visual output; it does not define semantic meaning.

### OGRE Capability Matrix

| Semantic Capability | SCR Representation | OGRE Manifestation | Provider Status | Missing Implementation | Ownership Model | Lifecycle | Synchronization |
|---|---|---|---|---|---|---|---|
| Scene graph | SCR `Entity` + `Relationship` hypergraph | OGRE SceneNode tree + Entity attachments | Not implemented | All scene graph manifestation | SCR owns semantic graph; OGRE renders it | OGRE SceneNode lifecycle: create → attach → update → detach → destroy | GPU resource sync on transform changes |
| Spatial object | SCR `Entity` with transform composition | OGRE `SceneNode` with position/orientation/scale | Not implemented | All spatial object manifestation | SCR defines transform; OGRE applies to Node | Node-specific lifecycle tied to render frame | Sync on manual update or frame-triggered |
| Transform (position + orientation + scale) | Composible from SCR Identity + Value types | OGRE `SceneNode::setPosition()` / `setOrientation()` / `setScale()` | Not implemented | Transform composition formalization | SCR computes transform matrix; OGRE extracts components | Per-frame update required | GPU barrier on buffer swap |
| Geometry (mesh, surface) | Not an SCR semantic primitive | OGRE `Mesh`, `SubMesh`, `Material` | Not implemented | All geometry manifestation | SCR provides semantic geometry; OGRE renders mesh representation | Mesh loading → scene attach → per-frame render | GPU buffer sync on material change |
| Camera | Not an SCR semantic primitive | OGRE `Camera`, `ViewPort` | Not implemented | All camera manifestation | SCR defines semantic camera; OGRE provides rendering camera | Camera setup → render loop → present | Sync on render frame start |
| Material | Not an SCR semantic primitive | OGRE `Material`, `Technique`, `Pass`, `Shader` | Not implemented | All material manifestation | SCR provides semantic material properties; OGRE renders material | Material reload → per-frame effect | GPU shader sync on uniform update |
| Texture | Not an SCR semantic primitive | OGRE `Texture`, `Texture2D`, `CubeMap` | Not implemented | All texture manifestation | SCR provides semantic texture properties; OGRE renders texture image | Texture upload → per-frame sample | GPU texture bind sync |
| Shader | Not an SCR semantic primitive | OGRE `Shader`, `Program` | Not implemented | All shader manifestation | SCR provides semantic shader properties; OGRE compiles/executes | Shader compile → per-frame bind | GPU pipeline sync |
| Light | Not an SCR semantic primitive | OGRE `Light`, `DirectionalLight`, `PointLight`, `SpotLight` | Not implemented | All light manifestation | SCR defines light semantic properties; OGRE renders light | Light setup → per-frame update | GPU shadow/sync on transform |
| Render target | Not an SCR semantic primitive | OGRE `RenderTarget`, `FrameBuffer`, `Texture` | Not implemented | All render target manifestation | SCR defines render target semantics; OGRE provides surface | Target creation → render → present → destroy | GPU framebuffer sync |
| Frame/render lifecycle | SCR `Event` + `Observation` | OGRE render loop: prepare → render → present → swap | Not implemented | Full lifecycle integration | SCR defines event sequence; OGRE provides visual loop | Loop iterations → present → swapbuffers | GPU swapchain sync |
| External GPU resource | SCR `Resource` capability (partial) | OGRE GPU resource borrowing/import | Not implemented | GPU resource interop | SCR owns resource semantics; OGRE borrows native handle | Resource borrow → use → return | GPU sync on resource transition |
| Frame damage state | SCR `Event` (partial) | OGRE damaged rect regions | Not implemented | Damage state manifestation | SCR tracks damaged regions; OGRE renders repairs | Per-damage-region → repair → present | GPU render target sync |

### OGRE Summary

- **Provider status**: Not implemented — all 17 semantic capabilities missing
- **Missing implementation**: Every OGRE-specific object (SceneNode, Mesh, Material, Texture, Shader, Light, Camera, RenderTarget) would need to be mapped from SCR semantics
- **Ownership model**: SCR owns the semantic graph; OGRE owns the rendering manifestation. Boundary preserved per §13: "SCR external resource → provider binding → Louvre LTexture / native GPU resource" pattern preferred over SCR-specific texture/geometry primitives
- **Lifecycle**: OGRE's SceneNode/Entity lifecycle must not become authoritative over SCR semantic state per §190-191 (GP-INV-009, GP-INV-012)
- **Key principle** (CAVE-000 §199): "OGRE is a rendering provider, not Cave's semantic model." No OGRE-specific semantic primitives should be created.

### Provider: Louvre

### Overview
Louvre is a compositor/system provider. Per CAVE-000 §201: "Louvre is a compositor/system provider, not Cave's semantic model." Louvre provides Wayland/compositor infrastructure; it does not define semantic meaning.

### Louvre Capability Matrix

| Semantic Capability | SCR Representation | Louvre Manifestation | Provider Status | Missing Implementation | Ownership Model | Lifecycle | Synchronization |
|---|---|---|---|---|---|---|---|
| Wayland client lifecycle | SCR `Event` + `Stream` | Wayland client protocol: create → setup → tear down | Not implemented | All Wayland client lifecycle | SCR defines client lifecycle semantics; Louvre provides Wayland binding | Client creation → setup → event loop → tear down | Protocol round-trip sync on buffer swap |
| Surface | SCR `Entity` + `Relationship` | XDG-surface / wl_surface | Not implemented | All surface manifestation | SCR defines surface semantics; Louvre provides Wayland surface | Surface creation → configure → destroy | Protocol sync on configure event |
| Buffer | SCR `Resource` capability | wl_buffer / DMA-BUF | Not implemented | All buffer manifestation | SCR defines buffer semantics; Louvre provides DMA-BUF import | Buffer import → attach → release | GPU mem import sync on format change |
| DMA-BUF | SCR `External GPU resource` (partial) | DMA-BUF file descriptor import | Not implemented | GPU resource interop | SCR owns resource semantics; Linux kernel manages DMA-BUF | Import → use → put | GPU sync on dma-buf sync_file |
| GPU resource | SCR `Resource` capability | Native GPU handle (EGLImage, GL texture) | Not implemented | GPU resource bridging | SCR owns resource semantics; provider provides native handle | Resource borrow → use → return | GPU sync on resource state |
| Synchronization | SCR `Capability` (partial) | wl_surface.damage, frame callbacks, async | Not implemented | All synchronization | SCR defines sync semantics; Louvre provides Wayland sync primitives | Fence → signal → wait | Protocol sync on frame done |
| Input | SCR `Event` (partial) | wl_keyboard, wl_pointer, wl_touch | Not implemented | All input manifestation | SCR defines event semantics; Louvre provides Wayland input binding | Event → dispatch → consume | Protocol round-trip sync |
| Presentation | SCR `Observation` + `Stream` | wl_surface.commit, frame callback | Not implemented | All presentation manifestation | SCR defines presentation semantics; Louvre provides Wayland presentation | Commit → frame callback → present | Protocol sync on commit done |
| Damage | SCR `Event` (partial) | wl_surface.damage rectangle | Not implemented | Damage tracking | SCR tracks damaged region; Louvre repairs region | Damage → repair → commit | GPU sync on damage region |
| Session | SCR `Entity` + lifecycle | XDG-session / wl_registry | Not implemented | Session management | SCR defines session semantics; Louvre provides Wayland registry | Session → global setup → tear down | Protocol sync on global registry |
| KMS | Not directly SCR | Kernel Mode Setting integration | Not implemented | KMS integration | SCR defines KMS semantics; Louvre provides KMS binding | Mode set → page flip → page flip event | GPU crtc sync on mode set |
| Render projection | SCR `Transformation` + `Spatial` | Viewport projection, camera transform | Not implemented | Render projection | SCR defines projection semantics; Louvre provides viewport | Projection setup → render → present | GPU viewport sync |

### Louvre Summary

- **Provider status**: Not implemented — all 12+ semantic capabilities missing
- **Missing implementation**: Every Louvre-specific object (wl_surface, wl_buffer, wl_buffer, DMA-BUF, Wayland protocols) would need to be mapped from SCR semantics
- **Ownership model**: SCR owns the semantic state; Louvre owns the Wayland/compositor manifestation. Boundary preserved per §13 pattern
- **Lifecycle**: Louvre's Wayland protocol lifecycle must not become authoritative over SCR semantic state per §190-191
- **Key principle** (CAVE-000 §201): "Louvre is a compositor/system provider, not Cave's semantic model." No Louvre-specific semantic primitives should be created.

### Provider Boundary Analysis

Per CAVE-000 §13 (Provider Mapping), the analysis must preserve the semantic/provider boundary:

**Preferred pattern** (from §13, p.602-610):

```text
SCR external resource
      ↓
provider binding
      ↓
Louvre LTexture / native GPU resource
```

**Anti-pattern** (from §13, p.612-617):

```text
SCR OgreTexture
SCR LouvreTexture
```

Currently, SCR has no `OgreTexture` or `LouvreTexture` primitives. All resource-related requirements are classified as:
- GAP-B (semantic composition): e.g., "external resource = Resource capability + ownership composition"
- GAP-D (provider): e.g., "OGRE lacks GPU resource interop implementation"
- GAP-E (application composition): e.g., "Cave-specific arrangement of SCR concepts"

No SCR-specific provider-type primitives should be created until the composition/gap analysis justifies them.

### Key Provider Findings

1. **OGRE**: 17 capabilities all missing; classified as GAP-D (Provider) — OGRE lacks implementation, not SCR semantics
2. **Louvre**: 12+ capabilities all missing; classified as GAP-D (Provider) — Louvre lacks implementation, not SCR semantics
3. **No SCR provider-specific primitives** exist or should be created during CAVE-000
4. **Ownership boundary** preserved: SCR defines semantic concepts; providers define manifestations
5. **Composition path**: Many Cave requirements can be expressed by composing SCR primitives, then mapped to provider bindings in a later increment
6. **GPU resource analysis** (CAVE-000 §14): Whether SCR can represent externally owned GPU resource — currently classified as GAP-B (composition) until explicit GPU resource primitive is justified

---
*Provider capability matrices constructed per CAVE-000 §13 (Provider Mapping). Provider boundary preserved per §13 pp.602-617. Analysis follows GP-INV-009 (Provider Independence) and GP-INV-017 (Renderer Independence).*