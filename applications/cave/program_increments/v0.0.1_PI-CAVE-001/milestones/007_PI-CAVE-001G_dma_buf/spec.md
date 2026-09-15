# Milestone 007: PI-CAVE-001G — Zero-Copy DMA-BUF GPU Path

**Parent RoadMap:** [milestones/README.md](../README.md)  
**Target Area:** `applications/cave/program_increments/v0.0.1_PI-CAVE-001/milestones/007_PI-CAVE-001G_dma_buf/`  
**Derived from:** `spec.md` (Sections 19, 20, 21, 54)  
**Governing Documents:** [`docs/102_ARCHITECTURE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/102_ARCHITECTURE.md), [`docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md)  
**Status:** Planned  

---

## 1. Objective

Implement the **Linux DMA-BUF zero-copy buffer sharing pipeline** across Wayland clients, the Louvre compositor, and the OGRE/OpenGL rendering provider. Ingest client-rendered GPU buffer file descriptors via `EGLImageKHR`, bind them directly to OpenGL 2D texture targets, verify zero host CPU memory copying in the steady-state render path, and manage GPU buffer synchronization via explicit synchronization fences (`dma_fence` / `EGLSyncKHR`).

---

## 2. Compliance with Authoritative Architecture

1. **Zero-Copy Mandate ([`docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md)):**
   Client graphics buffers must not traverse the host CPU memory bus. The buffer file descriptor passes directly between the Wayland client and the GPU rendering context.
2. **Manifestation Traceability:**
   The DMA-BUF file descriptor, EGLImage, and OpenGL texture ID are physical manifestation records in $M$. The SCR `BufferEntity` retains stable semantic identity across buffer swaps.
3. **Explicit Synchronization ([`docs/105_NUMERIC_EXECUTION.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/105_NUMERIC_EXECUTION.md)):**
   Buffer sharing across processes requires explicit fence synchronization to guarantee deterministic ordering without tearing or race conditions.

---

## 3. Sprint Breakdown

```text
007_PI-CAVE-001G_dma_buf/
├── spec.md
└── sprints/
    ├── sprint_01_dmabuf_import_and_eglimage.md   # Linux DMA-BUF import via EGLImageKHR to GL texture
    ├── sprint_02_zero_copy_verification.md       # Instrumentation & verification of zero CPU copies
    └── sprint_03_gpu_synchronization.md          # dma_fence and EGLSyncKHR synchronization
```

### [Sprint 01: DMA-BUF Import & EGLImage Creation](sprints/sprint_01_dmabuf_import_and_eglimage.md)
- Ingest `linux_dmabuf` file descriptors from Louvre `LBuffer`.
- Create `EGLImageKHR` via `eglCreateImageKHR` with `EGL_LINUX_DMA_BUF_EXT`.
- Bind `EGLImage` to OpenGL texture target `GL_TEXTURE_2D` using `glEGLImageTargetTexture2DOES`.

### [Sprint 02: Zero-Copy Execution Path Verification](sprints/sprint_02_zero_copy_verification.md)
- Instrument memory traffic using kernel ftrace/perf (`kfree_skb`, `page_faults`, CPU cache misses).
- Assert that steady-state frame rendering executes with **0 bytes of CPU-mediated pixel memcpy**.

### [Sprint 03: GPU Buffer Synchronization & Fencing](sprints/sprint_03_gpu_synchronization.md)
- Import Linux synchronization file descriptors (`sync_file`).
- Create `EGLSyncKHR` objects before sampling to prevent compositor reading before client finishes drawing.
- Signal buffer release fences back to the client upon frame rendering completion.

---

## 4. Milestone Exit Criteria

1. Wayland client rendering via Mesa GL/Vulkan displays in Cave via DMA-BUF import.
2. Automated performance checks confirm zero CPU-to-GPU memory copies during steady-state rendering.
3. Zero tearing or synchronization artifacts under 60 FPS continuous client rendering.
