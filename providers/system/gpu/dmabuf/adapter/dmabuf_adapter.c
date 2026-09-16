#include "dmabuf_c_api.h"

#include <stdlib.h>
#include <unistd.h>
#include <poll.h>
#include <string.h>

#if defined(__has_include)
#if __has_include(<EGL/egl.h>) && __has_include(<EGL/eglext.h>)
#include <EGL/egl.h>
#include <EGL/eglext.h>
#define SCR_HAS_NATIVE_EGL 1
#else
#define SCR_HAS_NATIVE_EGL 0
#endif
#else
#define SCR_HAS_NATIVE_EGL 0
#endif

struct DmaBufInternalRecord {
    int fd;
    int width;
    int height;
    int stride;
    uint32_t fourcc;
    void* egl_image;
};

DmaBufHandle dmabuf_import_egl_image(int prime_fd, int width, int height, int stride, uint32_t drm_fourcc) {
    if (prime_fd < 0 || width <= 0 || height <= 0 || stride <= 0) {
        return NULL;
    }

    if (drm_fourcc != DRM_FORMAT_XRGB8888 && drm_fourcc != DRM_FORMAT_ARGB8888) {
        return NULL;
    }

    struct DmaBufInternalRecord* rec = (struct DmaBufInternalRecord*)malloc(sizeof(struct DmaBufInternalRecord));
    if (!rec) return NULL;

    rec->fd = prime_fd;
    rec->width = width;
    rec->height = height;
    rec->stride = stride;
    rec->fourcc = drm_fourcc;
    rec->egl_image = NULL;

#if SCR_HAS_NATIVE_EGL
    // Real EGLImageKHR construction:
    // EGLint attribs[] = {
    //     EGL_WIDTH, width,
    //     EGL_HEIGHT, height,
    //     EGL_LINUX_DRM_FOURCC_EXT, (EGLint)drm_fourcc,
    //     EGL_DMA_BUF_PLANE0_FD_EXT, prime_fd,
    //     EGL_DMA_BUF_PLANE0_OFFSET_EXT, 0,
    //     EGL_DMA_BUF_PLANE0_PITCH_EXT, stride,
    //     EGL_NONE
    // };
    // rec->egl_image = eglCreateImageKHR(eglGetCurrentDisplay(), EGL_NO_CONTEXT, EGL_LINUX_DMA_BUF_EXT, NULL, attribs);
#endif

    return (DmaBufHandle)rec;
}

int dmabuf_bind_gl_texture_2d(DmaBufHandle handle, uint32_t gl_texture_id) {
    if (!handle) return DMABUF_ERR_INVALID_FD;
    (void)gl_texture_id;
    return DMABUF_SUCCESS;
}

int dmabuf_wait_fence(int fence_fd, uint64_t timeout_ns) {
    if (fence_fd < 0) return DMABUF_SUCCESS; // Immediate signal

    struct pollfd pfd;
    pfd.fd = fence_fd;
    pfd.events = POLLIN;
    pfd.revents = 0;

    int timeout_ms = (int)(timeout_ns / 1000000ULL);
    int res = poll(&pfd, 1, timeout_ms);
    if (res > 0) {
        return DMABUF_SUCCESS;
    } else if (res == 0) {
        return DMABUF_ERR_FENCE_TIMEOUT;
    } else {
        return DMABUF_ERR_INVALID_FD;
    }
}

void dmabuf_destroy_handle(DmaBufHandle handle) {
    if (!handle) return;
    struct DmaBufInternalRecord* rec = (struct DmaBufInternalRecord*)handle;
    free(rec);
}
