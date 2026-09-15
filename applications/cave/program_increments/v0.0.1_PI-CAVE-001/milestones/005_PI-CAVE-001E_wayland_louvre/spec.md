# Milestone 005: PI-CAVE-001E — Wayland & Louvre Provider Integration

**Parent RoadMap:** [milestones/README.md](../README.md)  
**Target Area:** `applications/cave/program_increments/v0.0.1_PI-CAVE-001/milestones/005_PI-CAVE-001E_wayland_louvre/`  
**Derived from:** `spec.md` (Sections 17, 18, 39, 64, 65, 68)  
**Governing Documents:** [`docs/102_ARCHITECTURE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/102_ARCHITECTURE.md), [`docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md)  
**Status:** Planned  

---

## 1. Objective

Integrate the **Louvre C++ compositor library** and standard **Wayland protocols** as a subordinate provider in SCR. Ingest real Wayland client connections (e.g., foot, alacritty, or weston-terminal), map Wayland surface protocol events directly into SCR semantic surface lifecycle transitions, and establish robust fault isolation at the provider adapter boundary.

---

## 2. Compliance with Authoritative Architecture

1. **Provider Subordination ([`docs/102_ARCHITECTURE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/102_ARCHITECTURE.md)):**
   Louvre and Wayland are providers, NOT the desktop authority. A Wayland protocol event (e.g. `xdg_toplevel.set_title`) is a request dispatched to the semantic field; the semantic state transition alone is authoritative.
2. **Provider Independence ([`docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md)):**
   If Louvre or the Wayland socket is disconnected, all SCR `SurfaceEntity` and `DesktopEntity` models remain intact and observable.
3. **Fault Isolation:**
   A client crash or malformed Wayland protocol message is caught at the provider adapter and converted into a semantic notification; it must never crash the SCR runtime or corrupt the hypergraph.

---

## 3. Sprint Breakdown

```text
005_PI-CAVE-001E_wayland_louvre/
├── spec.md
└── sprints/
    ├── sprint_01_louvre_bootstrap.md            # Louvre C++ compositor initialization & socket binding
    ├── sprint_02_wayland_protocol_mapping.md    # wl_surface, xdg_shell mapping to semantic lifecycle
    └── sprint_03_adapter_boundary_and_faults.md # Provider adapter contract, error handling & crash resilience
```

### [Sprint 01: Louvre Compositor Bootstrap & Configuration](sprints/sprint_01_louvre_bootstrap.md)
- Initialize Louvre C++ engine (`LLouvre`), configure display backends, and bind `$WAYLAND_DISPLAY`.
- Expose essential protocol globals: `wl_compositor`, `wl_subcompositor`, `xdg_wm_base`, `wl_seat`, `wl_output`.
- Verify client connection handshakes.

### [Sprint 02: Wayland Protocol Mapping & Surface Lifecycle](sprints/sprint_02_wayland_protocol_mapping.md)
- Map `LSurface` events to SCR `SurfaceEntity` transitions:
  - `LSurface::create` $\to$ `SemanticObject.transition_to(CREATED)`
  - `LSurface::map` $\to$ `SemanticObject.transition_to(ACTIVE)`
  - `LSurface::unmap` $\to$ `SemanticObject.transition_to(DETACHED)`
  - `LSurface::destroy` $\to$ `SemanticObject.transition_to(RETIRED)`
- Map pointer and keyboard events from Louvre input devices to SCR semantic input streams.

### [Sprint 03: Provider Adapter Boundary & Fault Isolation](sprints/sprint_03_adapter_boundary_and_faults.md)
- Build the bidirectional C++/Mojo FFI Provider Adapter.
- Handle client disconnections, protocol violations, and compositor restarts cleanly.
- Verify that killing a Wayland client retires the corresponding semantic surface without affecting sibling surfaces.

---

## 4. Milestone Exit Criteria

1. Louvre initializes successfully on Linux and accepts real Wayland client connections.
2. Wayland surface events produce corresponding deterministic semantic state updates in the SCR hypergraph.
3. Client crashes are isolated and handled with 100% clean recovery in tests.
