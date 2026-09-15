# Milestone 004: PI-CAVE-001D — Desktop Semantic Ontology

**Parent RoadMap:** [milestones/README.md](../README.md)  
**Target Area:** `applications/cave/program_increments/v0.0.1_PI-CAVE-001/milestones/004_PI-CAVE-001D_desktop_ontology/`  
**Derived from:** `spec.md` (Sections 10, 45, 46, 47, 62, 82)  
**Governing Documents:** [`docs/103_SEMANTIC_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/103_SEMANTIC_MODEL.md), [`docs/118_LIBRARY_DOMAIN_AND_SUBDOMAIN_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/118_LIBRARY_DOMAIN_AND_SUBDOMAIN_MODEL.md)  
**Status:** Planned  

---

## 1. Objective

Implement the domain-specific **Desktop Semantic Ontology** for Cave: formalize `Desktop`, `Workspace`, `Application`, `Surface`, and `Buffer` as first-class semantic entities, define their lifecycle and ownership relationships, enforce Cave-specific invariants (`CAVE-INV-001` through `CAVE-INV-020`), and expose the high-level Desktop Application API.

---

## 2. Compliance with Authoritative Architecture

1. **Entity Primacy ([`docs/103_SEMANTIC_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/103_SEMANTIC_MODEL.md)):**
   Desktop elements are semantic entities with persistent identities, not temporary GUI widgets or ephemeral Wayland protocol states.
2. **State Ownership ([`docs/102_ARCHITECTURE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/102_ARCHITECTURE.md)):**
   SCR is authoritative for window position, focus state, active workspace, and semantic surface hierarchy. Louvre/Wayland merely reports requests from clients.
3. **Decoupled Buffer Model:**
   A `Buffer` entity encapsulates pixel format, dimensions, stride, and content hash. The underlying GPU memory descriptor (DMA-BUF handle) is a manifestation record in $M$, not the semantic buffer itself.

---

## 3. Sprint Breakdown

```text
004_PI-CAVE-001D_desktop_ontology/
├── spec.md
└── sprints/
    ├── sprint_01_desktop_and_workspace.md       # Desktop root container and Workspace entities
    ├── sprint_02_surface_and_application.md     # Surface and Application entities & relations
    ├── sprint_03_buffer_entity_and_ownership.md # Buffer semantic abstraction & state ownership
    └── sprint_04_desktop_invariants_and_api.md  # CAVE-INV-001..020 & Desktop Application API
```

### [Sprint 01: Desktop & Workspace Semantic Entities](sprints/sprint_01_desktop_and_workspace.md)
- Implement `DesktopEntity`: The root spatial container and environmental field coordinator.
- Implement `WorkspaceEntity`: Spatial partition grouping related application surfaces.
- Implement workspace switching and active workspace focus semantics.

### [Sprint 02: Surface & Application Entities](sprints/sprint_02_surface_and_application.md)
- Implement `SurfaceEntity`: Represents 2D renderable interactive surface quad with input capabilities.
- Implement `ApplicationEntity`: Represents the client process or semantic application agent.
- Implement application-to-surface multi-window relationship modeling.

### [Sprint 03: Buffer Semantic Entity & State Ownership](sprints/sprint_03_buffer_entity_and_ownership.md)
- Implement `BufferEntity`: Pixel metadata, DRM format fourcc, dimension, content hash.
- Formalize buffer attachment transitions: `Surface.attach_buffer(buf_ref)`.
- Define explicit state ownership rules between client, compositor, and runtime.

### [Sprint 04: Cave Invariant Suite & Application API](sprints/sprint_04_desktop_invariants_and_api.md)
- Formalize and implement `CAVE-INV-001` through `CAVE-INV-020`.
- Implement high-level programmatic Desktop API: `create_surface()`, `move_surface()`, `focus_surface()`, `destroy_surface()`.

---

## 4. Milestone Exit Criteria

1. Complete Mojo implementations of Desktop, Workspace, Application, Surface, and Buffer.
2. Invariants `CAVE-INV-001` through `CAVE-INV-020` automated and verified.
3. Desktop Application API tested with mock clients with 100% test passage.
