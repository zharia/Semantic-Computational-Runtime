// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "cuda_c_api.h"

#include <stdlib.h>
#include <string.h>

#if defined(__has_include)
#if __has_include(<cuda_runtime.h>)
#include <cuda_runtime.h>
#define SCR_HAS_NATIVE_CUDA 1
#else
#define SCR_HAS_NATIVE_CUDA 0
#endif
#else
#define SCR_HAS_NATIVE_CUDA 0
#endif

#if !SCR_HAS_NATIVE_CUDA
struct FallbackStream {
    int active;
};
#endif

int cuda_device_get_count(int* out_count) {
    if (!out_count) return CUDA_ERR_NULL_POINTER;
#if SCR_HAS_NATIVE_CUDA
    cudaError_t err = cudaGetDeviceCount(out_count);
    return (err == cudaSuccess) ? CUDA_SUCCESS : CUDA_ERR_INVALID_DEVICE;
#else
    *out_count = 1; // 1 virtual accelerator device in reference mode
    return CUDA_SUCCESS;
#endif
}

int cuda_device_alloc(size_t bytes, CudaDevicePtr* out_dev_ptr) {
    if (!out_dev_ptr) return CUDA_ERR_NULL_POINTER;
    if (bytes == 0) return CUDA_ERR_INVALID_HANDLE;

#if SCR_HAS_NATIVE_CUDA
    cudaError_t err = cudaMalloc(out_dev_ptr, bytes);
    return (err == cudaSuccess) ? CUDA_SUCCESS : CUDA_ERR_OUT_OF_MEMORY;
#else
    void* ptr = malloc(bytes);
    if (!ptr) return CUDA_ERR_OUT_OF_MEMORY;
    *out_dev_ptr = ptr;
    return CUDA_SUCCESS;
#endif
}

int cuda_device_free(CudaDevicePtr dev_ptr) {
    if (!dev_ptr) return CUDA_ERR_NULL_POINTER;
#if SCR_HAS_NATIVE_CUDA
    cudaError_t err = cudaFree(dev_ptr);
    return (err == cudaSuccess) ? CUDA_SUCCESS : CUDA_ERR_INVALID_HANDLE;
#else
    free(dev_ptr);
    return CUDA_SUCCESS;
#endif
}

int cuda_memcpy_host_to_device(CudaDevicePtr dst, const void* src, size_t bytes) {
    if (!dst || !src) return CUDA_ERR_NULL_POINTER;
#if SCR_HAS_NATIVE_CUDA
    cudaError_t err = cudaMemcpy(dst, src, bytes, cudaMemcpyHostToDevice);
    return (err == cudaSuccess) ? CUDA_SUCCESS : CUDA_ERR_EXECUTION_FAILED;
#else
    memcpy(dst, src, bytes);
    return CUDA_SUCCESS;
#endif
}

int cuda_memcpy_device_to_host(void* dst, const CudaDevicePtr src, size_t bytes) {
    if (!dst || !src) return CUDA_ERR_NULL_POINTER;
#if SCR_HAS_NATIVE_CUDA
    cudaError_t err = cudaMemcpy(dst, src, bytes, cudaMemcpyDeviceToHost);
    return (err == cudaSuccess) ? CUDA_SUCCESS : CUDA_ERR_EXECUTION_FAILED;
#else
    memcpy(dst, src, bytes);
    return CUDA_SUCCESS;
#endif
}

int cuda_stream_create(CudaStreamHandle* out_stream) {
    if (!out_stream) return CUDA_ERR_NULL_POINTER;
#if SCR_HAS_NATIVE_CUDA
    cudaStream_t s;
    cudaError_t err = cudaStreamCreate(&s);
    if (err != cudaSuccess) return CUDA_ERR_EXECUTION_FAILED;
    *out_stream = (CudaStreamHandle)s;
    return CUDA_SUCCESS;
#else
    struct FallbackStream* s = (struct FallbackStream*)malloc(sizeof(struct FallbackStream));
    if (!s) return CUDA_ERR_OUT_OF_MEMORY;
    s->active = 1;
    *out_stream = (CudaStreamHandle)s;
    return CUDA_SUCCESS;
#endif
}

int cuda_stream_synchronize(CudaStreamHandle stream) {
    if (!stream) return CUDA_ERR_NULL_POINTER;
#if SCR_HAS_NATIVE_CUDA
    cudaError_t err = cudaStreamSynchronize((cudaStream_t)stream);
    return (err == cudaSuccess) ? CUDA_SUCCESS : CUDA_ERR_EXECUTION_FAILED;
#else
    // Reference stream completes synchronously
    return CUDA_SUCCESS;
#endif
}

int cuda_stream_destroy(CudaStreamHandle stream) {
    if (!stream) return CUDA_ERR_NULL_POINTER;
#if SCR_HAS_NATIVE_CUDA
    cudaError_t err = cudaStreamDestroy((cudaStream_t)stream);
    return (err == cudaSuccess) ? CUDA_SUCCESS : CUDA_ERR_INVALID_HANDLE;
#else
    free(stream);
    return CUDA_SUCCESS;
#endif
}
