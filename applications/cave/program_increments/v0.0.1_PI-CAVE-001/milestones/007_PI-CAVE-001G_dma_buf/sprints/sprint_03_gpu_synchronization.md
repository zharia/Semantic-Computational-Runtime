# Sprint 03: GPU Buffer Synchronization & Fencing

**Parent Milestone:** [Milestone 007: PI-CAVE-001G Zero-Copy DMA-BUF](../spec.md)  
**Derived from:** `spec.md` (Sections 21, 54)  
**Governing Documents:** [`docs/105_NUMERIC_EXECUTION.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/105_NUMERIC_EXECUTION.md)  
**Status:** Planned  

---

## 1. Mission

Implement explicit GPU synchronization using Linux `sync_file` file descriptors (`dma_fence`) and EGL fence objects (`EGLSyncKHR`), guaranteeing that the compositor never samples an incomplete client buffer and the client never overwrites a buffer currently in use.

---

## 2. Technical Specifications

### 2.1 Explicit Synchronization Protocol
1. **Acquire Fence (Client $\to$ Compositor):**
   - The Wayland client passes an acquire fence FD with the buffer commit.
   - Compositor creates an `EGLSyncKHR` object (`EGL_SYNC_NATIVE_FENCE_ANDROID`) from the FD.
   - Instructs GPU OpenGL pipeline to wait: `glWaitSync(sync, 0, GL_TIMEOUT_IGNORED)`.
2. **Release Fence (Compositor $\to$ Client):**
   - Compositor dispatches rendering commands that sample the buffer texture.
   - Compositor inserts an `EGLSyncKHR` into the command stream.
   - Extracts release fence FD and passes it back to the client via `linux_dmabuf_feedback` or buffer release events.

---

## 3. Verification & Testing Tasks

1. **Race Condition Stress Test:** Render a client application updating at 144 FPS into a 60 FPS compositor display; verify zero tearing or partial frame sampling.
2. **Fence Timeout Handling:** Simulate a GPU hung task where the acquire fence never signals; verify that the compositor drops the frame after a 100ms timeout without hanging the desktop.
3. **Fence File Descriptor Cleanup:** Verify that fence FDs are closed immediately after GPU consumption.
