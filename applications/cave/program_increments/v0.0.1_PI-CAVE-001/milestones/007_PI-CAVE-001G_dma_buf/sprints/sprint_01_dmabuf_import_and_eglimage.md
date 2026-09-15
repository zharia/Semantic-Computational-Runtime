# Sprint 01: DMA-BUF Import & EGLImage Creation

**Parent Milestone:** [Milestone 007: PI-CAVE-001G Zero-Copy DMA-BUF](../spec.md)  
**Derived from:** `spec.md` (Section 19)  
**Governing Documents:** [`docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md)  
**Status:** Planned  

---

## 1. Mission

Implement the low-level Linux DMA-BUF import pipeline, converting kernel buffer file descriptors received from Wayland clients into `EGLImageKHR` handles and binding them to OpenGL 2D texture targets.

---

## 2. Technical Specifications

### 2.1 EGL DMA-BUF Import Implementation
```cpp
// providers/render/opengl/src/cave_dmabuf_importer.cpp
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GL/gl.h>
#include <GL/glext.h>

GLuint importDmabufToTexture(EGLDisplay dpy, const DmaBufParams &params) {
    EGLint attribs[] = {
        EGL_WIDTH, params.width,
        EGL_HEIGHT, params.height,
        EGL_LINUX_DRM_FOURCC_EXT, params.fourcc_format,
        EGL_DMA_BUF_PLANE0_FD_EXT, params.fd[0],
        EGL_DMA_BUF_PLANE0_OFFSET_EXT, params.offset[0],
        EGL_DMA_BUF_PLANE0_PITCH_EXT, params.stride[0],
        EGL_DMA_BUF_PLANE0_MODIFIER_LO_EXT, (EGLint)(params.modifier & 0xFFFFFFFF),
        EGL_DMA_BUF_PLANE0_MODIFIER_HI_EXT, (EGLint)(params.modifier >> 32),
        EGL_NONE
    };

    EGLImageKHR image = eglCreateImageKHR(
        dpy, EGL_NO_CONTEXT, EGL_LINUX_DMA_BUF_EXT, (EGLClientBuffer)nullptr, attribs
    );
    if (image == EGL_NO_IMAGE_KHR) {
        throw std::runtime_error("Failed to import DMA-BUF as EGLImage");
    }

    GLuint textureId;
    glGenTextures(1, &textureId);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, image);

    return textureId;
}
```

---

## 3. Verification & Testing Tasks

1. **DRM FourCC Format Handling:** Test import of `DRM_FORMAT_ARGB8888` and `DRM_FORMAT_XRGB8888`.
2. **Descriptor Lifecycle:** Ensure imported file descriptors are closed or duplicated properly without FD leakage.
3. **Texture Rendering:** Bind imported texture to an OGRE material; verify that client-rendered content displays on the surface quad.
