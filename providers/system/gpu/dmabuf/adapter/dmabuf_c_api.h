#ifndef SCR_PROVIDERS_DMABUF_C_API_H
#define SCR_PROVIDERS_DMABUF_C_API_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define DMABUF_SUCCESS                  0
#define DMABUF_ERR_INVALID_FD         (-1)
#define DMABUF_ERR_UNSUPPORTED_FORMAT (-2)
#define DMABUF_ERR_IMPORT_FAILED      (-3)
#define DMABUF_ERR_FENCE_TIMEOUT      (-4)

/* Standard Linux DRM FourCC format codes */
#define DRM_FORMAT_XRGB8888 0x34325258
#define DRM_FORMAT_ARGB8888 0x34325241

typedef void* DmaBufHandle;

/**
 * Import a Linux DMA-BUF PRIME file descriptor into an EGLImage handle.
 */
DmaBufHandle dmabuf_import_egl_image(int prime_fd, int width, int height, int stride, uint32_t drm_fourcc);

/**
 * Bind imported EGLImage to an active OpenGL 2D texture ID (glEGLImageTargetTexture2DOES).
 */
int dmabuf_bind_gl_texture_2d(DmaBufHandle handle, uint32_t gl_texture_id);

/**
 * Block on dma_fence fd until signaled or timeout.
 */
int dmabuf_wait_fence(int fence_fd, uint64_t timeout_ns);

/**
 * Release imported EGLImage and close internal handles.
 */
void dmabuf_destroy_handle(DmaBufHandle handle);

#ifdef __cplusplus
}
#endif

#endif /* SCR_PROVIDERS_DMABUF_C_API_H */
