// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "../adapter/cuda_c_api.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

static void test_cuda_device_and_memory(void) {
    printf("[Test 1] CUDA Device Query & Memory Roundtrip... ");
    int dev_count = 0;
    int rc = cuda_device_get_count(&dev_count);
    assert(rc == CUDA_SUCCESS);
    assert(dev_count >= 1);

    size_t num_floats = 256;
    size_t bytes = num_floats * sizeof(float);

    float* host_src = (float*)malloc(bytes);
    float* host_dst = (float*)malloc(bytes);
    for (size_t i = 0; i < num_floats; ++i) {
        host_src[i] = (float)i * 1.5f;
        host_dst[i] = 0.0f;
    }

    CudaDevicePtr dev_ptr = NULL;
    rc = cuda_device_alloc(bytes, &dev_ptr);
    assert(rc == CUDA_SUCCESS);
    assert(dev_ptr != NULL);

    rc = cuda_memcpy_host_to_device(dev_ptr, host_src, bytes);
    assert(rc == CUDA_SUCCESS);

    rc = cuda_memcpy_device_to_host(host_dst, dev_ptr, bytes);
    assert(rc == CUDA_SUCCESS);

    for (size_t i = 0; i < num_floats; ++i) {
        assert(host_dst[i] == host_src[i]);
    }

    rc = cuda_device_free(dev_ptr);
    assert(rc == CUDA_SUCCESS);

    free(host_src);
    free(host_dst);
    printf("PASSED (%zu bytes transferred)\n", bytes);
}

static void test_cuda_stream_lifecycle(void) {
    printf("[Test 2] CUDA Stream Creation & Synchronization... ");
    CudaStreamHandle stream = NULL;
    int rc = cuda_stream_create(&stream);
    assert(rc == CUDA_SUCCESS);
    assert(stream != NULL);

    rc = cuda_stream_synchronize(stream);
    assert(rc == CUDA_SUCCESS);

    rc = cuda_stream_destroy(stream);
    assert(rc == CUDA_SUCCESS);
    printf("PASSED\n");
}

static void test_cuda_error_handling(void) {
    printf("[Test 3] CUDA Precondition and Error Handling... ");
    int rc = cuda_device_get_count(NULL);
    assert(rc == CUDA_ERR_NULL_POINTER);

    CudaDevicePtr ptr = NULL;
    rc = cuda_device_alloc(0, &ptr);
    assert(rc == CUDA_ERR_INVALID_HANDLE);

    rc = cuda_device_free(NULL);
    assert(rc == CUDA_ERR_NULL_POINTER);

    printf("PASSED\n");
}

int main(void) {
    printf("=====================================\n");
    printf(" Running CUDA Provider Contract Tests\n");
    printf("=====================================\n");
    test_cuda_device_and_memory();
    test_cuda_stream_lifecycle();
    test_cuda_error_handling();
    printf("\nAll CUDA Contract Tests PASSED successfully.\n\n");
    return 0;
}
