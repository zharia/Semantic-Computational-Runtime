# Sprint 02: Wayland Protocol Mapping & Surface Lifecycle

**Parent Milestone:** [Milestone 005: PI-CAVE-001E Wayland & Louvre Provider](../spec.md)  
**Derived from:** `spec.md` (Sections 17, 18)  
**Governing Documents:** [`docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md)  
**Status:** Planned  

---

## 1. Mission

Implement the protocol event translation layer that ingests Wayland surface, window management, and input events from Louvre and maps them deterministically into SCR semantic surface lifecycle transitions and input streams.

---

## 2. Technical Specifications

### 2.1 Event Translation Pipeline
```text
Wayland Client wl_surface
        │ (wl_surface.commit)
        ▼
Louvre LSurface
        │ (C++ Callback)
        ▼
Cave Wayland Adapter
        │ (FFI Handoff)
        ▼
SCR Semantic Transition:
  τ_surface_commit(surface_id, buffer_id, damage_rect)
```

### 2.2 Event Mapping Matrix
| Wayland Protocol Event | Louvre Event | SCR Semantic Transition | State Impact |
|---|---|---|---|
| `wl_compositor.create_surface` | `onSurfaceCreated` | `AllocateSurface(app_id)` | Surface entity enters `CREATED` |
| `xdg_toplevel.set_title` | `LSurface::onTitleChange` | `UpdateSurfaceTitle(title)` | Attribute updated; version incremented |
| `wl_surface.attach + commit` | `LSurface::onBufferCommit` | `AttachBuffer(buf_id)` | Buffer linked to surface |
| Surface becomes visible | `onSurfaceMapped` | `ActivateSurface()` | Surface transitions to `ACTIVE` |
| Surface hidden / minimized | `onSurfaceUnmapped` | `SuspendSurface()` | Surface transitions to `ATTACHED` |
| `wl_surface.destroy` | `onSurfaceDestroyed` | `RetireSurface()` | Surface transitions to `RETIRED` |

### 2.3 Input Event Translation
* Pointer motion, button press, and keypress events are normalized and dispatched into the active `WorkspaceEntity`'s input queue for inverse spatial hit testing.

---

## 3. Verification & Testing Tasks

1. **Lifecycle Transition Conformance:** Verify that client window map/unmap/close actions drive exact corresponding SCR lifecycle states.
2. **Title Synchronization:** Assert that changing client window title updates the semantic attribute and triggers a state version increment.
3. **Multi-Surface Coordination:** Run multiple Wayland clients concurrently; verify that event queues remain isolated and deterministic.
