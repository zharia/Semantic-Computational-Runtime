# louvre Provider Contract

**Provider:** louvre  
**Domain:** system  
**Subdomain:** compositor  
**Version:** 0.1.0  
**Status:** Normative Contract  
**Governing Documents:** [`docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md), [`applications/cave/.../005_PI-CAVE-001E_wayland_louvre/spec.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/applications/cave/program_increments/v0.0.1_PI-CAVE-001/milestones/005_PI-CAVE-001E_wayland_louvre/spec.md)  

---

## 1. Contract Overview

This contract establishes the normative protocol boundary for the Louvre Wayland Compositor adapter. It defines the C ABI for initializing the Wayland event loop, binding surface creation and commit callbacks, and forwarding inverse-mapped spatial pointer coordinates $(u, v) \in [0, 1]^2$ back to client applications.

---

## 2. Operations & C ABI Interface

* `louvre_compositor_create(const char* socket_name, void* user_data) -> LouvreContextHandle`
* `louvre_set_surface_create_cb(LouvreContextHandle ctx, void (*cb)(void* user_data, uint64_t surface_id, const char* title))`
* `louvre_set_surface_commit_cb(LouvreContextHandle ctx, void (*cb)(void* user_data, uint64_t surface_id, int buffer_fd, int w, int h, int stride))`
* `louvre_set_surface_destroy_cb(LouvreContextHandle ctx, void (*cb)(void* user_data, uint64_t surface_id))`
* `louvre_dispatch_pointer_motion(LouvreContextHandle ctx, uint64_t surface_id, double local_u, double local_v)`
* `louvre_dispatch_pointer_button(LouvreContextHandle ctx, uint64_t surface_id, uint32_t button, uint32_t state)`
* `louvre_compositor_poll_events(LouvreContextHandle ctx, int timeout_ms) -> int`
* `louvre_compositor_destroy(LouvreContextHandle ctx) -> void`

---

## 3. Invariants & Guarantees

1. **Callback Atomicity:** Surface callbacks are invoked synchronously during `louvre_compositor_poll_events` on the host runner thread.
2. **Normalized Coordinates:** Pointer motion requires normalized $(u, v) \in [0, 1]^2$, which the provider scales to client pixel coordinates before dispatching `wl_pointer.motion`.
3. **Graceful Fault Boundary:** If a Wayland client disconnects abruptly or sends malformed protocol messages, Louvre must issue a destroy callback without aborting the compositor process.

---

## 4. Return Codes

* `LOUVRE_SUCCESS = 0`
* `LOUVRE_ERR_INVALID_HANDLE = -1`
* `LOUVRE_ERR_SOCKET_FAILED = -2`
* `LOUVRE_ERR_CLIENT_DISCONNECTED = -3`
