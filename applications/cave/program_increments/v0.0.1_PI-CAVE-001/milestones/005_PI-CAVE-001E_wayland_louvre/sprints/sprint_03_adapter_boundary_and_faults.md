# Sprint 03: Provider Adapter Boundary & Fault Isolation

**Parent Milestone:** [Milestone 005: PI-CAVE-001E Wayland & Louvre Provider](../spec.md)  
**Derived from:** `spec.md` (Sections 39, 64, 65, 68)  
**Governing Documents:** [`docs/102_ARCHITECTURE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/102_ARCHITECTURE.md) §6, [`docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md)  
**Status:** Planned  

---

## 1. Mission

Implement the bidirectional Provider Adapter interface between the C++ Louvre compositor and the Mojo SCR runtime, enforcing strict error containment so that client faults, crashes, or protocol violations never compromise the SCR core state.

---

## 2. Technical Specifications

### 2.1 Provider Adapter FFI Interface
```cpp
// providers/wayland/louvre/src/cave_wayland_adapter.h
extern "C" {
    typedef struct {
        uint64_t surface_id;
        int32_t width;
        int32_t height;
        uint32_t format;
        int32_t dmabuf_fd;
    } CaveSurfaceCommitDTO;

    // Callbacks from Louvre C++ into Mojo SCR Runtime
    typedef void (*OnSurfaceEventCallback)(uint64_t surface_id, int event_type, const void *payload);
    
    // Commands from Mojo SCR Runtime into Louvre C++
    void cave_louvre_send_configure(uint64_t surface_id, int width, int height);
    void cave_louvre_send_pointer_event(uint64_t surface_id, double local_u, double local_v, uint32_t button, int state);
    void cave_louvre_close_surface(uint64_t surface_id);
}
```

### 2.2 Fault Isolation & Recovery (§65)
* **Client Segmentation Fault:** When a client application crashes abruptly:
  - Louvre catches `SIGPIPE` / socket disconnection.
  - The adapter dispatches `RetireSurface(surface_id)` to SCR.
  - SCR removes the surface from active rendering and marks its buffer `RETIRED`.
  - The compositor and remaining application surfaces continue execution uninterrupted.
* **Compositor Recovery:** If Louvre experiences an unexpected internal error, the adapter captures the fault, serializes the current hypergraph state, and restarts the compositor without losing semantic desktop state.

---

## 3. Verification & Testing Tasks

1. **Client Crash Test:** Spawn a client and force-kill it with `SIGKILL`; assert that SCR cleanly retires the surface within 50ms and remains healthy.
2. **Malformed Protocol Message Injection:** Send invalid Wayland requests; verify that Louvre rejects the client while SCR state remains uncorrupted.
3. **Provider Hot-Replacement Simulation:** Disconnect the Wayland provider, verify that semantic entities remain intact, and reconnect a fresh provider instance.
