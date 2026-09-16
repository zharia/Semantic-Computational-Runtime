# dmabuf Provider Contract

**Provider:** dmabuf  
**Domain:** system  
**Subdomain:** gpu  
**Version:** 0.1.0  
**Status:** Normative Contract  
**Governing Documents:** [`docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md), [`applications/cave/.../007_PI-CAVE-001G_dma_buf/spec.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/applications/cave/program_increments/v0.0.1_PI-CAVE-001/milestones/007_PI-CAVE-001G_dma_buf/spec.md)  

---

## 1. Contract Overview

This contract establishes the normative interface for Linux DMA-BUF ingestion into EGL/OpenGL contexts. It defines error handling for invalid file descriptors, stride mismatch checks, DRM format FourCC validation, and fence synchronization.

---

## 2. Operations & C ABI Interface

* `dmabuf_import_egl_image(int prime_fd, int width, int height, int stride, uint32_t drm_fourcc) -> DmaBufHandle`
* `dmabuf_bind_gl_texture_2d(DmaBufHandle handle, uint32_t gl_texture_id) -> int`
* `dmabuf_wait_fence(int fence_fd, uint64_t timeout_ns) -> int`
* `dmabuf_destroy_handle(DmaBufHandle handle) -> void`

---

## 3. Invariants & Guarantees

1. **Zero CPU Copy:** Ingestion into GPU texture format must not call `memcpy` or read pixel memory into userspace buffers.
2. **FD Ownership:** The caller retains or explicitly transfers ownership of the PRIME file descriptor according to Linux DRM conventions.
3. **Format Support:** Supports standard DRM formats including `DRM_FORMAT_ARGB8888` and `DRM_FORMAT_XRGB8888`.

---

## 4. Return Codes

* `DMABUF_SUCCESS = 0`
* `DMABUF_ERR_INVALID_FD = -1`
* `DMABUF_ERR_UNSUPPORTED_FORMAT = -2`
* `DMABUF_ERR_IMPORT_FAILED = -3`
* `DMABUF_ERR_FENCE_TIMEOUT = -4`
