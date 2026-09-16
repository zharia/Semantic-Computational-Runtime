#include "../adapter/dmabuf_c_api.h"
#include <assert.h>
#include <stdio.h>
#include <unistd.h>

void test_dmabuf_import() {
    printf("[Test 1] DMA-BUF Import with valid parameters... ");
    // Fake synthetic PRIME fd (stdout fd 1 used as non-negative handle placeholder)
    DmaBufHandle handle = dmabuf_import_egl_image(1, 1920, 1080, 7680, DRM_FORMAT_ARGB8888);
    assert(handle != NULL);

    int res = dmabuf_bind_gl_texture_2d(handle, 42);
    assert(res == DMABUF_SUCCESS);

    dmabuf_destroy_handle(handle);
    printf("PASSED\n");
}

void test_dmabuf_validation_failures() {
    printf("[Test 2] DMA-BUF Parameter Validation Failures... ");
    // Negative FD must fail
    assert(dmabuf_import_egl_image(-1, 1920, 1080, 7680, DRM_FORMAT_ARGB8888) == NULL);

    // Invalid dimensions must fail
    assert(dmabuf_import_egl_image(1, 0, 1080, 7680, DRM_FORMAT_ARGB8888) == NULL);

    // Unsupported FourCC format must fail
    assert(dmabuf_import_egl_image(1, 1920, 1080, 7680, 0x12345678) == NULL);

    // Null handle bind must fail
    assert(dmabuf_bind_gl_texture_2d(NULL, 1) == DMABUF_ERR_INVALID_FD);
    printf("PASSED\n");
}

int main() {
    printf("========================================\n");
    printf(" Running DMA-BUF Provider Contract Tests\n");
    printf("========================================\n");

    test_dmabuf_import();
    test_dmabuf_validation_failures();

    printf("\nAll DMA-BUF Contract Tests PASSED successfully.\n");
    return 0;
}
