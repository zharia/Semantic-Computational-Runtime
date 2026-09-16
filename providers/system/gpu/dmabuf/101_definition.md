# dmabuf Provider

**Provider ID:** dmabuf  
**Domain:** system  
**Subdomain:** gpu  
**Version:** 0.1.0  
**Status:** Normative Definition  

---

## 1. Purpose

This directory defines the SCR integration of the **Linux DMA-BUF** subsystem as a Provider for the `system/gpu` capability domain.

DMA-BUF provides the kernel-mediated, zero-copy buffer-sharing mechanism that allows Wayland clients to pass hardware buffer file descriptors (PRIME fds) directly to OpenGL/EGL textures (`EGLImageKHR`) without CPU memory copying.

---

## 2. Zero-Copy Mandate & Provider Role

Under [`docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md) and [`applications/cave/.../007_PI-CAVE-001G_dma_buf/spec.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/applications/cave/program_increments/v0.0.1_PI-CAVE-001/milestones/007_PI-CAVE-001G_dma_buf/spec.md):
* The steady-state frame loop must enforce 0 CPU pixel copies.
* File descriptors are imported into GPU memory handles and synchronized via explicit fences (`dma_fence`, `EGLSyncKHR`).

---

## 3. Capabilities Provided

* `[system, gpu, dmabuf_import]`
* `[system, gpu, egl_image_bind]`
* `[system, gpu, zero_copy_verify]`
* `[system, gpu, fence_synchronization]`
