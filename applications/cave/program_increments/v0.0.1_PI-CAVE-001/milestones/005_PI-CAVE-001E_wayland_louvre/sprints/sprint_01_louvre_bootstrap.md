# Sprint 01: Louvre Compositor Bootstrap & Configuration

**Parent Milestone:** [Milestone 005: PI-CAVE-001E Wayland & Louvre Provider](../spec.md)  
**Derived from:** `spec.md` (Sections 18, 67)  
**Governing Documents:** [`docs/102_ARCHITECTURE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/102_ARCHITECTURE.md)  
**Status:** Planned  

---

## 1. Mission

Bootstrap the Louvre C++ compositor engine, establish the Linux display backend (DRM/KMS or nested X11/Wayland host window for development), bind the Wayland display socket, and advertise mandatory core protocol globals.

---

## 2. Technical Specifications

### 2.1 Louvre Compositor Wrapper Architecture
```cpp
// providers/wayland/louvre/src/cave_louvre_compositor.h
#include <Louvre/LLauncher.h>
#include <Louvre/LCompositor.h>

class CaveCompositor : public Louvre::LCompositor {
public:
    CaveCompositor();
    void onAnticipatedEvent();
    // Lifecycle hooks
    void onSurfaceCreated(Louvre::LSurface *surface);
    void onSurfaceDestroyed(Louvre::LSurface *surface);
    void onSurfaceMapped(Louvre::LSurface *surface);
    void onSurfaceUnmapped(Louvre::LSurface *surface);
};
```

### 2.2 Protocol Globals Configuration
* `wl_compositor` (version 4)
* `wl_subcompositor` (version 1)
* `xdg_wm_base` (version 3)
* `wl_seat` (version 7: pointer, keyboard capabilities)
* `wl_output` (version 3: physical geometry, refresh rate, scale)
* `zwp_linux_dmabuf_v1` (version 3: hardware buffer export/import)

---

## 3. Verification & Testing Tasks

1. **Socket Initialization:** Verify that `cave-wayland-0` socket is created and permissions allow non-root client connections.
2. **Handshake Test:** Run a standard Wayland test client (e.g. `wayland-info` or `weston-simple-shm`); verify protocol handshake negotiation.
3. **Clean Teardown:** Verify that shutting down the compositor releases all socket file descriptors and memory without leaks.
